#!/usr/bin/env bash
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Native runtime cleanup.
mkdir -p "$PROJECT/runtime/sessions"
find "$PROJECT/runtime/sessions" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

# Container cleanup, if the service is running.
if command -v docker >/dev/null 2>&1; then
  curl -fsS -X POST http://127.0.0.1:8080/api/clear-all >/dev/null 2>&1 || true
fi

echo "CyberVoice participant session workspace cleared."
