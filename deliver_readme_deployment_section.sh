#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

cat > README.md <<'EOF'
# CyberVoiceStation — "Hear Yourself Hacked" PoC

Local, air-gapped voice-cloning proof of concept for the Cyber Room station at
Cybersecurity Awareness Month 2026. A participant records a short voice
sample, hears a synthetic version of their own voice deliver a fixed
social-engineering awareness script, and the entire workspace is deleted at
the end of the session. No cloud API, no participant ID, no retained audio.

Full technical rationale, privacy design and troubleshooting live in the
build guide this repo was scaffolded from:
`Cyber_Room_Local_Voice_Cloning_PoC_Build_Guide_2026-08-07.md` (project docs).
This README is the condensed, actionable version of that guide.

**This repo ships the application code, deploy config, and scripts already
written. What you still need to do on your own Mac is install the runtime,
pull the two upstream voice-model repos, and download the model
checkpoints — none of that can be committed to git (see "What's deliberately
not in this repo" below).**

---

## Time estimate

This is dominated by downloads and dependency builds, not typing code — the
app code is already done for you in this repo.

| Phase | First time | Notes |
|---|---|---|
| Mac prep (Xcode CLT, Homebrew, conda, ffmpeg) | 20–40 min | Mostly install wait |
| Python env + clone/install OpenVoice & MeloTTS | 30–45 min | `pip install -e .` resolves a lot of deps |
| Download OpenVoice V2 checkpoints | 15–30 min | Depends on connection speed |
| First import test + model cache pre-warm | 15–20 min | Downloads Silero VAD etc. on first run |
| First native run + functional test | 20–30 min | Get one clone generated end-to-end |
| Privacy/cleanup tests (success + forced failure + emergency wipe) | 20–30 min | Section 24 of the build guide |
| Multiple warm-up sessions + reboot + air-gap test | 45–60 min | Proves offline operation |
| **Subtotal — working, privacy-tested native PoC** | **~3–4.5 hours** | Realistic for one focused sitting |
| Docker Desktop install + container build | 30–60 min | `python:3.9-slim` + torch build is the slow part |
| Container tmpfs/network verification | 15–20 min | |
| UAT with several test voices + latency measurements | 45–90 min | Section 46 of the build guide |
| **Full validated PoC incl. container + UAT** | **~1.5–2 extra hours**, so **~5–7 hours total** | Can be split across 2 sessions |

Budget a full day if you want to also rehearse the management demo
(Section 40) and fill in the UAT/privacy checklists (Sections 43–44).

---

## Prerequisites (do this on the M5 MacBook, not in any cloud environment)

- Apple Silicon Mac (`uname -m` → `arm64`)
- Xcode Command Line Tools
- Homebrew
- Internet connection for the initial build (the whole point is that normal
  *operation* afterward doesn't need one)

---

## Step-by-step build

### Phase 0 — Prepare the Mac
```bash
xcode-select --install
# install Homebrew from https://brew.sh if not already installed
brew update
brew install git ffmpeg miniforge
git --version && ffmpeg -version && conda --version
```

### Phase 1 — Get this repo onto the Mac and create the Python env
```bash
git clone <your-new-GitHub-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
conda create -n cybervoice python=3.9.25 -y
conda activate cybervoice
python -m pip install --upgrade pip setuptools wheel
```

### Phase 2 — Pull and pin the two upstream voice-model repos
These are *not* vendored in this repo (see below) — clone them fresh so you
control and record the exact commit:
```bash
cd upstream
git clone https://github.com/myshell-ai/OpenVoice.git
cd OpenVoice && python -m pip install -e .
echo "OpenVoice commit: $(git rev-parse HEAD)" >> ~/CyberVoiceStation/BUILD_MANIFEST.txt
cd ../..

cd upstream
git clone https://github.com/myshell-ai/MeloTTS.git
cd MeloTTS && python -m pip install -e .
python -m unidic download
echo "MeloTTS commit: $(git rev-parse HEAD)" >> ~/CyberVoiceStation/BUILD_MANIFEST.txt
cd ../..
```

### Phase 3 — App dependencies
```bash
python -m pip install -r requirements-app.txt
```

### Phase 4 — Download OpenVoice V2 checkpoints
Follow the checkpoint link in the official OpenVoice usage guide
(`https://github.com/myshell-ai/OpenVoice/blob/main/docs/USAGE.md`) and
extract into `checkpoints_v2/` so you end up with `checkpoints_v2/converter/`
(`config.json`, `checkpoint.pth`) and `checkpoints_v2/base_speakers/ses/`.

### Phase 5 — Pre-warm caches while still online
```bash
python - <<'PY'
import torch
from melo.api import TTS
from openvoice.api import ToneColorConverter
print("torch:", torch.__version__)
print("MPS available:", torch.backends.mps.is_available())
PY
python -m pip freeze > requirements-lock.txt
```

### Phase 6 — Run it natively
```bash
./scripts/run-native.sh
# open http://127.0.0.1:8080
```
Record your own voice, generate, listen, press FINISH, then confirm
`runtime/sessions/` is empty.

### Phase 7 — Prove the privacy/cleanup design
Run the invalid-audio test, the forced-failure test, and the emergency wipe
test (build guide Section 24). Each should leave `runtime/sessions/` empty.

### Phase 8 — Air-gap proof
Warm up 3+ full sessions, restart the process, reboot the Mac, turn Wi-Fi
off, verify `curl https://example.com` fails, then run `./scripts/run-native.sh`
again and generate a clone completely offline. Run `./scripts/verify-offline.sh`
to check this automatically.

### Phase 9 — Containerize for portability
```bash
# install Docker Desktop for Apple Silicon first
docker compose -f deploy/compose.yaml build --no-cache
docker compose -f deploy/compose.yaml up
# open http://127.0.0.1:8080
```
`/session` is a RAM-backed `tmpfs` inside the container — verify with
`docker compose -f deploy/compose.yaml exec cybervoice sh -c "mount | grep /session"`.

### Phase 10 — UAT and sign-off
Work through the checklists in the build guide (Sections 43–44) before
letting anyone else use the station, and get Privacy/Legal sign-off on the
consent wording per the campaign project's open decisions list.

---

## What's deliberately not in this repo

| Excluded | Why |
|---|---|
| `upstream/OpenVoice/`, `upstream/MeloTTS/` | Cloned fresh per Phase 2 so you pin and record the exact commit yourself, rather than vendoring someone else's moving `main` branch |
| `checkpoints_v2/**` (model weights) | Large binaries; download per Phase 4 |
| `runtime/sessions/**` | This is where **participant audio** would briefly live — it must never be committed |
| `requirements-lock.txt`, `BUILD_MANIFEST.txt`, `SHA256SUMS.txt` | Build evidence that's specific to *your* machine and build date — regenerate each time per `BUILD_MANIFEST.template.txt` |

---

## Deploying to other hardware

Once the native + container build above is validated on this Mac, here's how
to run the same app somewhere else. The gap called out in the table above —
`checkpoints_v2/`, `upstream/OpenVoice/`, `upstream/MeloTTS/`, and
`BUILD_MANIFEST.txt` not being in git — applies on *any* second machine, so
every path below deals with it one way or another.

### Option 1 — A dedicated mini-PC (Docker appliance)

For a permanent, hardened, unattended kiosk: RAM-backed `tmpfs` for
`/session`, read-only root filesystem, dropped capabilities. Condensed
version (full walkthrough — OS install, kiosk browser autostart, hardware
UAT checklist — is in the project's Mini-PC Setup Guide doc):

```bash
# On the mini-PC (Ubuntu Server LTS recommended), after installing Docker Engine:
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation

# Bring BUILD_MANIFEST.txt over from the Mac (scp/USB) first, then pin the
# same commits it recorded:
mkdir -p upstream && cd upstream
git clone https://github.com/myshell-ai/OpenVoice.git
cd OpenVoice && git checkout <commit from BUILD_MANIFEST.txt> && cd ..
git clone https://github.com/myshell-ai/MeloTTS.git
cd MeloTTS && git checkout <commit from BUILD_MANIFEST.txt> && cd ../..

# Re-download checkpoints_v2/ per Phase 4 above, then:
cd ~/CyberVoiceStation
docker compose -f deploy/compose.yaml build --no-cache
docker compose -f deploy/compose.yaml up -d
```

A mini-PC is almost certainly **x86-64** while this Mac is **ARM64** — the
image has to be built **on the mini-PC itself**, not copied over. Docker
images aren't portable across CPU architectures; the Dockerfile is portable
source, not a portable prebuilt image.

### Option 2 — A second Apple Silicon Mac

Same chip family as this Mac, so this is the easiest transfer of the two.

**Native** (gets the same MPS acceleration as this Mac): repeat Phases 0-6
above on the second Mac, but instead of re-downloading `checkpoints_v2/`
from scratch, copy the folder over directly (AirDrop/USB/scp), along with
`BUILD_MANIFEST.txt`, and check out OpenVoice/MeloTTS to the exact commits
it records before installing them.

**Docker, transferring the already-built image (fastest option overall)** —
because both Macs are ARM64, no rebuild is needed and the checkpoint/upstream
gap doesn't even come up, since the image already has everything baked in:

```bash
# on this Mac:
docker images | grep cybervoice     # confirm the exact image name/tag
docker save deploy-cybervoice:latest -o cybervoice-image.tar
# AirDrop/USB/scp cybervoice-image.tar to the second Mac (a few GB, budget time)

# on the second Mac:
docker load -i cybervoice-image.tar
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
docker compose -f deploy/compose.yaml up -d
```

Run a quick health check and one full clone session afterward regardless of
which option you use — different physical machines can behave differently
even on matching hardware/architecture.

---

## Repo layout
```
app/                  Flask backend, voice engine, cleanup logic, UI
deploy/               Dockerfile + compose.yaml for the portable container build
scripts/              run-native.sh, clear-sessions.sh, verify-offline.sh
checkpoints_v2/       (empty placeholder — you populate this, Phase 4)
upstream/             (empty placeholder — you clone into this, Phase 2)
runtime/sessions/     (empty placeholder — participant session dirs live here transiently)
requirements-app.txt
BUILD_MANIFEST.template.txt
```

---

## Privacy design in one paragraph

Every participant gets a random UUID session directory. Nothing is written
outside it. On success, generated audio is copied into memory, the response
is sent to the browser with `Cache-Control: no-store`, and the whole session
directory is deleted — the same deletion runs again in a `finally` block if
anything failed earlier. Startup clears any abandoned sessions; the operator
can also trigger `/api/clear-all` manually. Production/container mode adds
`network_mode`-style isolation and a RAM-backed `tmpfs` for `/session` so
audio never touches durable storage. See Appendix D of the build guide for
the full risk/control mapping.

---

## Pushing this to GitHub

This repo has already been `git init`'d and committed for you. To publish it:

```bash
# 1. Create an empty repo on GitHub first (no README/license/gitignore — this repo already has them)
#    via https://github.com/new, or with the GitHub CLI:
gh repo create <your-username>/cybervoicestation-poc --private --source=. --remote=origin

# 2. If you created it on the website instead, just add the remote and push:
git remote add origin git@github.com:<your-username>/cybervoicestation-poc.git
git branch -M main
git push -u origin main
```

After that, `git clone <that-repo-URL> ~/CyberVoiceStation` on the M5
MacBook is your Phase 1 step above.
EOF

echo "-- README.md written --"
git status --short
git add README.md
git commit -m "Add mini-PC and second-Mac deployment instructions to README"
git push
echo "-- done --"