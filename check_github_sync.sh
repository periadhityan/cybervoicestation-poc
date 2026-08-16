#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

echo "== remote =="
git remote -v

echo
echo "== branch =="
git branch --show-current

echo
echo "== working tree status (should be empty) =="
git status --short

echo
echo "== last 15 commits =="
git log --oneline -15

echo
echo "== ahead/behind origin =="
git fetch origin --quiet
git status -sb | head -1

echo
echo "== pushing anything pending, just in case =="
git push

echo
echo "-- done. If 'working tree status' printed nothing and the branch line"
echo "   above said your branch is up to date with 'origin/main', the repo"
echo "   on GitHub matches this machine exactly. --"