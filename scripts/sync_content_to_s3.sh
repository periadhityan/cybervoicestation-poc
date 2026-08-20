#!/usr/bin/env bash
# Uploads app/static/content/ to the S3 bucket used by the AWS deployment's
# CONTENT_BACKEND=s3 mode, mirroring the exact same folder structure
# (content/<modality>/<difficulty>/...) as S3 key prefixes. Run this from
# your Mac after loading real content locally the normal way (see
# app/content/README.md) -- this is the one extra step that gets it onto
# S3 for the live AWS deployment.
#
# Usage:
#   ./scripts/sync_content_to_s3.sh <bucket-name> [--delete]
#
# --delete removes objects in S3 that no longer exist locally, mirroring
# `aws s3 sync --delete`. Omitted by default -- safer to leave stale objects
# in the bucket than to accidentally wipe something -- pass it explicitly
# once you're confident your local app/static/content/ is the source of
# truth.
#
# Requires the AWS CLI configured with credentials that can write to the
# bucket (this runs from your Mac, not the EC2 instance -- the instance
# only ever needs read access, via its IAM role).
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <bucket-name> [--delete]" >&2
  exit 1
fi

BUCKET="$1"
DELETE_FLAG=()
if [ "${2:-}" = "--delete" ]; then
  DELETE_FLAG=(--delete)
  echo "-- --delete passed: objects removed locally will also be removed from S3 --"
fi

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT"

if [ ! -d app/static/content ]; then
  echo "app/static/content not found -- run this from a checkout that has content loaded (or run scripts/generate_placeholder_content.py first)." >&2
  exit 1
fi

echo "-- syncing app/static/content/ -> s3://$BUCKET/content/ --"
aws s3 sync app/static/content "s3://$BUCKET/content" \
  --exclude "*.DS_Store" \
  "${DELETE_FLAG[@]}"

echo "-- done. Live within ~60s (content_pool.py's S3 listing cache) -- no app restart or redeploy needed. --"
