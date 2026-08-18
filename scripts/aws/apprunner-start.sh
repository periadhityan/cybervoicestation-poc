#!/usr/bin/env bash
# Brings the public site back up before an activity.
# One-time setup: see deploy/aws/config.env.example, and the AWS Deployment
# Guide project doc for how APP_RUNNER_SERVICE_ARN is created in the first place.
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Resuming App Runner service..."
aws apprunner resume-service \
  --region "$AWS_REGION" \
  --service-arn "$APP_RUNNER_SERVICE_ARN" \
  --query 'Service.Status' --output text

echo "Waiting for it to become RUNNING (this can take a minute or two)..."
while true; do
  status=$(aws apprunner describe-service \
    --region "$AWS_REGION" \
    --service-arn "$APP_RUNNER_SERVICE_ARN" \
    --query 'Service.Status' --output text)
  echo "  status: $status"
  [ "$status" = "RUNNING" ] && break
  [ "$status" = "PAUSED" ] && { echo "Still paused -- something didn't take, check the AWS console."; exit 1; }
  sleep 5
done

echo "-- site is live --"
