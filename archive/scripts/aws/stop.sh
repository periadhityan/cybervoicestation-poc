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
