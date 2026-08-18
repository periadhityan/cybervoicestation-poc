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
