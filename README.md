# CyberVoiceStation — "Which Is Fake?" Cyber Room PoC

Three lightweight, self-contained "spot the fake" games for the Cyber Room
station at Cybersecurity Awareness Month 2026: audio, video, and picture.
Each game plays a real clip and an AI-generated one side by side and asks
the participant to guess which is real, then reveals what gave the fake
away. No participant data collected, no files stored -- answers and scores
exist only in the browser tab.

*(This repo previously also included a live voice-cloning station, "Hear
Yourself Hacked." That's been removed -- this build is just the three
"Which Is Fake?" games.)*

For the full architecture, deployment topology, and security model, see
**[ARCHITECTURE.md](./ARCHITECTURE.md)**. This README is just the quick
start.

---

## What's in this repo

- A small Flask app (`app/app.py`) serving the homepage hub and the three
  game blueprints (`spot_the_fake.py`, `spot_the_fake_video.py`,
  `spot_the_fake_image.py`).
- Each game samples a random subset of real/fake pairs from its own content
  pool per difficulty tier (easy/medium/hard) on every page load, so two
  participants back to back don't see the exact same rounds.
- Placeholder content (synthetic tones/patterns/colors) is one command away
  (`python scripts/generate_placeholder_content.py`) so the app is fully
  playable with zero real content sourced yet -- game media itself isn't
  committed to git (see `.gitignore`), only the code that generates or loads
  it, so run that once after cloning. Content is just files dropped into
  folders (`app/static/content/<modality>/<difficulty>/`) -- no manifest to
  maintain. See `app/content/README.md` for the full convention and how to
  load real content before the event.
- Content can be served from local folders (default, simplest) or from a
  private S3 bucket via presigned URLs (`CONTENT_BACKEND=s3`, AWS
  deployment only) -- worth it once the content library is large enough
  that git and Docker rebuilds get annoying. See `app/content/README.md`
  and the S3 Content Storage project doc.
- An optional shared-passcode gate (`SITE_PASSCODE` env var) for when this
  is deployed somewhere publicly reachable -- off by default, so local dev
  and the in-person kiosk path are never accidentally gated.

There's no model runtime, no GPU/MPS dependency, and no large downloads --
this is just Flask plus static media files discovered by folder convention,
so setup and deployment are both fast.

---

## Prerequisites

- Python 3.9+ (any recent 3.x works)
- Optional: Docker, if you want the containerized/hardened path instead of
  running natively
- Optional: `ffmpeg` on your PATH, only needed to (re)generate placeholder
  content via `scripts/generate_placeholder_content.py` -- not needed to run
  the app itself, and not needed once you've loaded real content

---

## Run it natively

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
python scripts/generate_placeholder_content.py   # first time only -- game media isn't tracked in git
./scripts/run-native.sh
# open http://127.0.0.1:8080
```

`run-native.sh` creates a local virtualenv (`.venv/`), installs
`requirements-app.txt` into it, and starts the app. No model downloads, no
checkpoints, no upstream repos to pin. This is the fastest loop for
content-loading work too -- content is discovered fresh on every request,
so dropping new files into `app/static/content/` shows up immediately, no
restart needed at all.

## Run it natively on Windows

Same app, no WSL or bash required -- just Python 3.9+ from
[python.org](https://www.python.org/downloads/windows/) (check **"Add
python.exe to PATH"** during setup).

```bat
git clone <your-repo-URL> C:\CyberVoiceStation
cd C:\CyberVoiceStation
python scripts\generate_placeholder_content.py   :: first time only -- needs ffmpeg on PATH, see note below
scripts\run-native.bat
:: open http://127.0.0.1:8080
```

Double-clicking `scripts\run-native.bat` in Explorer works too. It creates
the same `.venv\` virtualenv, installs `requirements-app.txt`, and starts
the app -- keep the console window open while it's running, closing it
stops the server.

Prefer PowerShell? `scripts\run-native.ps1` does the same thing. If
PowerShell blocks it with a "running scripts is disabled" error (the
default execution policy), run it as:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-native.ps1
```

That only bypasses the policy for this one run, not machine-wide.

`generate_placeholder_content.py` needs `ffmpeg` on PATH (only for
regenerating placeholder content -- not needed to run the app itself, or
once real content is loaded). On Windows, either `winget install
ffmpeg` (Windows 10 2020+ / 11) or download a build from
[gyan.dev](https://www.gyan.dev/ffmpeg/builds/) and add its `bin\` folder
to PATH.

## Run it with Docker (local only)

```bash
docker compose -f deploy/compose.yaml build
docker compose -f deploy/compose.yaml up
# open http://127.0.0.1:8080
```

Published to `127.0.0.1` only -- this is the in-person kiosk / mini-PC path,
not a public deployment. Runs with a read-only root filesystem and dropped
Linux capabilities.

## Deploying publicly on AWS

This app is also deployed live on AWS (EC2 + Caddy for automatic HTTPS +
Route 53), gated behind a shared passcode, with a simple start/stop workflow
so it only runs (and costs money) while it's actually needed. That's a
separate compose file (`deploy/aws/compose.aws.yaml`) and a distinct setup
process -- see **[ARCHITECTURE.md §3.3 and §5](./ARCHITECTURE.md#3-deployment-topologies)**
for the architecture, and the AWS Public Deployment Guide project doc for
the full step-by-step.

Day-to-day, once it's set up once:

```bash
./scripts/aws/start.sh    # before an activity
./scripts/aws/stop.sh     # after
```

---

## Deploying to a second local machine

Because there's no model weights or pinned upstream source to carry over,
moving the local/native or mini-PC path to any second machine -- another
Mac, a Windows PC, a mini-PC, whatever's around -- is just:

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
./scripts/run-native.sh
```

(`scripts\run-native.bat` or `scripts\run-native.ps1` on Windows -- see
"Run it natively on Windows" above) or the Docker steps above. `git clone`
really is sufficient -- the only thing to check on a new machine is that
Python 3.9+ (native) or Docker (container) is installed.

---

## Repo layout

```
app/                  Flask backend + templates + static JS/CSS
app/content/           README for loading real game content (folder convention)
app/static/content/    Real/fake media, discovered by folder convention -- no manifest
deploy/               Dockerfile + compose.yaml (local) + aws/ (public deployment)
scripts/              run-native.sh/.bat/.ps1, verify-offline.sh, generate_placeholder_content.py, aws/ (start/stop)
requirements-app.txt
README.md             This file
ARCHITECTURE.md       Full architecture, deployment, and security reference
```

---

## Loading real content before the event

The three games ship with placeholder content (synthetic tones, geometric
patterns, solid colors) so the app is fully playable today. Swapping in
real real/fake pairs is just dropping two files into the right
`app/static/content/<audio|video|image>/<easy|medium|hard>/` folder, named
`<round-id>-real.<ext>` and `<round-id>-fake.<ext>` -- no manifest to edit,
no restart needed. See `app/content/README.md` for the full convention
(including the optional `notes.json` for custom labels) and the Content
Loading Guide project doc for a phased, week-by-week sourcing plan per game
(audio/video/picture).

---

## Pushing this to GitHub

```bash
gh repo create <your-username>/cybervoicestation-poc --private --source=. --remote=origin
# or, if the repo already exists on GitHub:
git remote add origin git@github.com:<your-username>/cybervoicestation-poc.git
git branch -M main
git push -u origin main
```
