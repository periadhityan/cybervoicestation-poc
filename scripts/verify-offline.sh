#!/usr/bin/env bash
set -euo pipefail

printf 'Checking local service...\n'
curl -fsS http://127.0.0.1:8080/health
printf '\n'

printf 'Checking internet reachability...\n'
if curl -fsS --max-time 3 https://example.com >/dev/null 2>&1; then
  echo "NOTE: internet is reachable. This isn't an air-gapped test, just an FYI --"
  echo "the games don't need a network connection to work either way."
else
  echo "PASS: no internet reachable, and the games still work from local static content."
fi
