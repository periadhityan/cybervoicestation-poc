#!/usr/bin/env bash
set -euo pipefail

# This script lives at native/mac/ -- go up two levels to reach the project
# root (native/mac/ -> native/ -> project root), where app/ and
# requirements-app.txt actually live. The app itself isn't duplicated here;
# this is just the Mac/Linux entry point into the one shared copy.
PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Create/reuse a plain virtualenv -- no conda, no pinned Python build needed
# now that this app is just Flask + static content, not a model runtime.
if [ ! -d "$PROJECT/.venv" ]; then
  python3 -m venv "$PROJECT/.venv"
fi

source "$PROJECT/.venv/bin/activate"
python -m pip install --quiet --upgrade pip
python -m pip install --quiet -r "$PROJECT/requirements-app.txt"

cd "$PROJECT/app"
exec python app.py
