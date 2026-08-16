# CyberVoiceStation — "Which Is Fake?" Cyber Room PoC

Three lightweight, self-contained "spot the fake" games for the Cyber Room
station at Cybersecurity Awareness Month 2026: audio, video, and picture.
Each game plays a real clip and an AI-generated one side by side and asks
the participant to guess which is real, then reveals what gave the fake
away. No login, no personal data collected, no participant files stored --
answers and scores exist only in the browser tab.

*(This repo previously also included a live voice-cloning station,
"Hear Yourself Hacked." That's been removed -- this build is just the three
"Which Is Fake?" games.)*

---

## What's in this repo

- A small Flask app (`app/app.py`) serving the homepage hub and the three
  game blueprints (`spot_the_fake.py`, `spot_the_fake_video.py`,
  `spot_the_fake_image.py`).
- Each game samples a random subset of real/fake pairs from its own content
  pool per difficulty tier (easy/medium/hard) on every page load, so two
  participants back to back don't see the exact same rounds.
- Placeholder content ships out of the box (synthetic tones/patterns/colors)
  so the app runs end to end immediately. See
  `app/content/README.md` for the manifest schema, and the project's
  Content Loading Guide for how to source and load real content before the
  event.

There's no model runtime, no GPU/MPS dependency, and no large downloads --
this is just Flask plus static JSON manifests and media files, so setup and
deployment are both fast.

---

## Prerequisites

- Python 3.9+ (any recent 3.x works -- there's no longer a pinned-version
  requirement, since nothing in this app depends on a specific ML library
  build)
- Optional: Docker, if you want the containerized/hardened path instead of
  running natively

---

## Run it natively

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
./scripts/run-native.sh
# open http://127.0.0.1:8080
```

`run-native.sh` creates a local virtualenv (`.venv/`), installs
`requirements-app.txt` into it, and starts the app. That's the whole setup
-- no separate model-download phase, no checkpoints, no upstream repos to
pin.

## Run it with Docker

```bash
# install Docker (Docker Desktop on Mac/Windows, Docker Engine on Linux)
docker compose -f deploy/compose.yaml build
docker compose -f deploy/compose.yaml up
# open http://127.0.0.1:8080
```

The container runs with a read-only root filesystem and dropped Linux
capabilities -- reasonable hardening for a machine left semi-unattended at
a public event, even though there's no participant audio to protect
anymore. This is optional; native is just as fine for a one-day event.

---

## Deploying to a second machine

Because there's no model weights or pinned upstream source to carry over
anymore, moving this to any second machine -- another Mac, a Windows PC, a
mini-PC, whatever's around -- is just:

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
./scripts/run-native.sh
```

or the Docker steps above. No `BUILD_MANIFEST.txt`, no checkpoint
downloads, no upstream commit-pinning, no architecture-specific rebuild
concerns to think through -- `git clone` really is sufficient this time.
The only thing to double check on a brand-new machine is that Python 3.9+
(native path) or Docker (container path) is installed.

---

## Repo layout

```
app/                  Flask backend + templates + static JS/CSS
app/content/           Manifests + README for loading real game content
deploy/               Dockerfile + compose.yaml for the optional container build
scripts/              run-native.sh, verify-offline.sh, generate_placeholder_content.py
requirements-app.txt
```

---

## Loading real content before the event

The three games ship with placeholder content (synthetic tones, geometric
patterns, solid colors) so the app is fully playable today. Swapping in
real real/fake pairs is a matter of dropping media files into
`app/static/spot_the_fake*/` and adding matching entries to the manifest
JSON files -- see `app/content/README.md` for the exact schema and the
project's Content Loading Guide doc for sourcing options per game
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
