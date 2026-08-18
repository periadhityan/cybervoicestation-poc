#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

echo "-- removing the App Runner scripts (App Runner is closed to new customers, going with EC2 instead) --"
git rm -f --ignore-unmatch scripts/aws/apprunner-start.sh scripts/aws/apprunner-stop.sh

mkdir -p deploy/aws scripts/aws

echo "-- rewriting deploy/aws/config.env.example --"
cat > deploy/aws/config.env.example <<'EOF'
# Copy this file to config.env (same directory) and fill in the real values.
# config.env is gitignored -- these are account-specific, not something to commit.
# See the AWS Public Deployment Guide project doc for how these values are created.

AWS_REGION=ap-southeast-1
INSTANCE_ID=i-xxxxxxxxxxxxxxxxx
EOF

echo "-- adding deploy/aws/Caddyfile --"
cat > deploy/aws/Caddyfile <<'EOF'
# Replace with your actual subdomain before first deploy.
# Caddy handles HTTPS automatically (Let's Encrypt) -- nothing else to configure
# as long as this domain's DNS A record points at the instance's Elastic IP
# and the security group allows inbound 80/443.
cyberroom.periadhityan.com {
	reverse_proxy cybervoice:8080
}
EOF

echo "-- adding deploy/aws/compose.aws.yaml --"
cat > deploy/aws/compose.aws.yaml <<'EOF'
# Compose file for the public AWS deployment specifically. Separate from
# ../compose.yaml (which stays as-is for local/native Docker use, publishing
# only to 127.0.0.1) so that running this one is an explicit, deliberate
# choice -- it's the only compose file in this repo that opens a port to the
# public internet.
#
# Reads SITE_PASSCODE and FLASK_SECRET_KEY from a .env file placed next to
# this file on the EC2 instance (not committed -- see the AWS Public
# Deployment Guide project doc).
services:
  cybervoice:
    build:
      context: ../..
      dockerfile: deploy/Dockerfile
    environment:
      CYBERVOICE_BIND: "0.0.0.0"
      SITE_PASSCODE: "${SITE_PASSCODE}"
      FLASK_SECRET_KEY: "${FLASK_SECRET_KEY}"
    expose:
      - "8080"
    read_only: true
    volumes:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    restart: unless-stopped

  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - cybervoice
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
EOF

echo "-- adding scripts/aws/start.sh --"
cat > scripts/aws/start.sh <<'EOF'
#!/usr/bin/env bash
# Brings the public EC2 instance up before an activity, waits until it's
# reachable, and prints its current public IP (only useful if you're not
# using an Elastic IP -- with an Elastic IP the address never changes).
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Starting instance $INSTANCE_ID..."
aws ec2 start-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" >/dev/null

echo "Waiting for it to reach running state..."
aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

echo "Waiting for status checks to pass (this can take a minute)..."
aws ec2 wait instance-status-ok --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

public_ip=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "-- instance is up, public IP: $public_ip --"
echo "Docker Compose is configured with 'restart: unless-stopped', so the app"
echo "and Caddy containers come back automatically once the instance boots --"
echo "give it a minute, then check https://<your domain> ."
EOF
chmod +x scripts/aws/start.sh

echo "-- adding scripts/aws/stop.sh --"
cat > scripts/aws/stop.sh <<'EOF'
#!/usr/bin/env bash
# Takes the public EC2 instance down when it's not needed. While stopped you
# only pay for the EBS volume (a few cents/month) and the Elastic IP's small
# public-IPv4 hourly charge -- no compute charge at all until you start it
# again. The Elastic IP itself doesn't change, so DNS never needs updating.
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Stopping instance $INSTANCE_ID..."
aws ec2 stop-instances --region "$AWS_REGION" --instance-ids "$INSTANCE_ID" >/dev/null

echo "Waiting for it to fully stop..."
aws ec2 wait instance-stopped --region "$AWS_REGION" --instance-ids "$INSTANCE_ID"

echo "-- instance is stopped, compute charges paused --"
EOF
chmod +x scripts/aws/stop.sh

echo "-- updating .gitignore --"
if ! grep -qxF "deploy/aws/.env" .gitignore 2>/dev/null; then
  printf 'deploy/aws/.env\n' >> .gitignore
fi

echo "-- staging and committing --"
git add -A
git status --short
git commit -m "Swap App Runner scripts for EC2 + Caddy deployment (App Runner closed to new customers)"
git push
echo "-- done --"