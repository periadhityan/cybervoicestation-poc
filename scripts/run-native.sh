#!/usr/bin/env bash
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT/app"

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate cybervoice

# Clean abandoned session files before the service launches.
rm -rf "$PROJECT/runtime/sessions"/*

exec python app.py
