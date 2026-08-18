#!/usr/bin/env bash
# Takes the public site down when it's not needed, so it stops incurring
# App Runner compute charges. The service definition (image, env vars, custom
# domain mapping) is preserved while paused -- apprunner-start.sh brings it
# straight back without redoing any setup.
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Pausing App Runner service..."
aws apprunner pause-service \
  --region "$AWS_REGION" \
  --service-arn "$APP_RUNNER_SERVICE_ARN" \
  --query 'Service.Status' --output text

echo "-- site is paused, no compute charges while it's down --"
