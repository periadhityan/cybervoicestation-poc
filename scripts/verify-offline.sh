#!/usr/bin/env bash
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Checking local service...\n'
curl -fsS http://127.0.0.1:8080/health
printf '\n'

printf 'Checking session workspace...\n'
SESSION="$PROJECT/runtime/sessions"
if [ -d "$SESSION" ] && find "$SESSION" -mindepth 1 -print -quit | grep -q .; then
  echo "FAIL: session workspace is not empty"
  exit 1
else
  echo "PASS: no participant session files found"
fi

printf 'Checking internet reachability...\n'
if curl -fsS --max-time 3 https://example.com >/dev/null 2>&1; then
  echo "WARNING: internet is reachable. This is not an air-gapped test."
  exit 2
else
  echo "PASS: example internet probe failed as expected"
fi
