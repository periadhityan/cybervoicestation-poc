#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

echo "-- removing voice-cloning ('Hear Yourself Hacked') files --"
git rm -f --ignore-unmatch \
  app/voice_engine.py \
  app/cleanup.py \
  app/templates/index.html \
  app/static/app.js \
  scripts/compare_speakers.py \
  scripts/clear-sessions.sh \
  deploy/prewarm.py \
  BUILD_MANIFEST.template.txt

echo "-- removing model/session directories --"
rm -rf checkpoints_v2 upstream runtime
git add -A

echo "-- rewriting app/app.py --"
cat > app/app.py <<'EOF'
from __future__ import annotations

import os

from flask import Flask, jsonify, render_template

from spot_the_fake import bp as spot_the_fake_bp
from spot_the_fake_image import bp as spot_the_fake_image_bp
from spot_the_fake_video import bp as spot_the_fake_video_bp


app = Flask(__name__)
app.config["JSON_SORT_KEYS"] = False
app.register_blueprint(spot_the_fake_bp)
app.register_blueprint(spot_the_fake_video_bp)
app.register_blueprint(spot_the_fake_image_bp)


@app.get("/")
def home():
    return render_template("home.html")


@app.get("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # CYBERVOICE_BIND defaults to loopback-only for native/local runs.
    # Container deployment sets CYBERVOICE_BIND=0.0.0.0 (see deploy/compose.yaml);
    # the host still only publishes that port to its own loopback interface.
    bind_host = os.environ.get("CYBERVOICE_BIND", "127.0.0.1")
    app.run(host=bind_host, port=8080, debug=False, threaded=False)
EOF

echo "-- rewriting app/templates/home.html --"
cat > app/templates/home.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cybersecurity Awareness Month 2026</title>
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <div class="floaty-icons" aria-hidden="true">
    <span class="floaty-icon" style="left:6%; animation-duration:18s; animation-delay:0s;">🔒</span>
    <span class="floaty-icon" style="left:18%; animation-duration:22s; animation-delay:3s;">🛡️</span>
    <span class="floaty-icon" style="left:32%; animation-duration:16s; animation-delay:6s;">🐛</span>
    <span class="floaty-icon" style="left:48%; animation-duration:24s; animation-delay:1s;">🔍</span>
    <span class="floaty-icon" style="left:64%; animation-duration:19s; animation-delay:8s;">🔑</span>
    <span class="floaty-icon" style="left:78%; animation-duration:21s; animation-delay:4s;">📧</span>
    <span class="floaty-icon" style="left:90%; animation-duration:17s; animation-delay:10s;">🛡️</span>
  </div>

  <main class="shell">
    <section class="card" id="homeIntro">
      <svg class="mascot" viewBox="0 0 120 140" width="88" height="102" aria-hidden="true" focusable="false">
        <defs>
          <linearGradient id="shieldGrad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stop-color="#22d3ee"/>
            <stop offset="100%" stop-color="#a78bfa"/>
          </linearGradient>
        </defs>
        <path d="M60 4 L112 22 V64 C112 100 88 124 60 136 C32 124 8 100 8 64 V22 Z" fill="url(#shieldGrad)" stroke="#1a1442" stroke-width="4"/>
        <circle cx="42" cy="58" r="7" fill="#1a1442"/>
        <circle cx="78" cy="58" r="7" fill="#1a1442"/>
        <path d="M40 84 Q60 100 80 84" stroke="#1a1442" stroke-width="5" fill="none" stroke-linecap="round"/>
      </svg>
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH 2026</p>
      <h1>🛡️ Pause. Think. Report.</h1>
      <p class="lead">
        Modern attackers don't need to hack a system when they can
        convincingly fake a person. This Cyber Room walks through what that
        actually looks and sounds like -- and why urgency alone should
        never be enough to act on a request.
      </p>
      <p class="lead">
        Try each station below. None of them collect your name or employee
        ID, and no score or answer is saved anywhere once you leave the page.
      </p>
    </section>

    <div class="hub-grid">
      <a class="hub-card accent-pink" href="/spot-the-fake">
        <p class="eyebrow">STATION 1</p>
        <h2>🎧 Which Is Fake? (Audio)</h2>
        <p>Listen to two short clips. Guess which one is the real recording.</p>
      </a>

      <a class="hub-card accent-orange" href="/spot-the-fake-video">
        <p class="eyebrow">STATION 2</p>
        <h2>🎬 Which Is Fake? (Video)</h2>
        <p>Watch two short clips. Guess which one is the real footage.</p>
      </a>

      <a class="hub-card accent-green" href="/spot-the-fake-image">
        <p class="eyebrow">STATION 3</p>
        <h2>🖼️ Which Is Fake? (Picture)</h2>
        <p>Compare two photos. Guess which one is the real photo.</p>
      </a>
    </div>
  </main>

  <footer>
    Cybersecurity Awareness Month 2026 &middot; Pause. Think. Report.
  </footer>
</body>
</html>
EOF

echo "-- rewriting app/static/style.css --"
cat > app/static/style.css <<'EOF'
:root {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  --bg-deep: #1a1442;
  --bg-mid: #2d1b69;
  --accent-cyan: #22d3ee;
  --accent-orange: #fb923c;
  --accent-pink: #f472b6;
  --accent-green: #4ade80;
  --accent-purple: #a78bfa;
  --card-bg: rgba(30, 23, 70, 0.72);
  --card-border: rgba(255, 255, 255, 0.14);
  color: #f5f3ff;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  position: relative;
  overflow-x: hidden;
  background:
    radial-gradient(circle at 15% 20%, rgba(34, 211, 238, 0.22), transparent 40%),
    radial-gradient(circle at 85% 15%, rgba(244, 114, 182, 0.2), transparent 40%),
    radial-gradient(circle at 20% 85%, rgba(74, 222, 128, 0.16), transparent 45%),
    radial-gradient(circle at 90% 80%, rgba(251, 146, 60, 0.16), transparent 45%),
    linear-gradient(160deg, #1a1442 0%, #2d1b69 55%, #1e1b4b 100%);
  background-attachment: fixed;
}

body::before {
  content: "";
  position: fixed;
  inset: 0;
  z-index: -1;
  opacity: 0.4;
  background-image: radial-gradient(circle, rgba(255, 255, 255, 0.09) 1px, transparent 1px);
  background-size: 28px 28px;
  pointer-events: none;
}

.shell {
  width: min(1000px, 92vw);
  margin: 40px auto;
  position: relative;
  z-index: 1;
}

.card {
  padding: 48px;
  border: 2px solid var(--card-border);
  border-radius: 28px;
  background: var(--card-bg);
  backdrop-filter: blur(8px);
  box-shadow: 0 20px 60px rgba(8, 5, 30, 0.45);
}

.hidden { display: none; }

.eyebrow {
  letter-spacing: .16em;
  font-size: 14px;
  font-weight: 800;
  color: var(--accent-cyan);
}

h1 { font-size: clamp(44px, 7.5vw, 84px); margin: 12px 0; line-height: 1.06; }
h2 { font-size: clamp(30px, 5vw, 56px); }
.lead { font-size: 22px; opacity: .92; line-height: 1.4; }

button {
  margin-top: 24px;
  padding: 18px 30px;
  border: 0;
  border-radius: 999px;
  font-size: 18px;
  font-weight: 800;
  letter-spacing: .01em;
  cursor: pointer;
  color: #1a1442;
  background: linear-gradient(120deg, var(--accent-cyan), var(--accent-purple));
  box-shadow: 0 10px 26px rgba(34, 211, 238, 0.35);
  transition: transform .15s ease, box-shadow .15s ease;
}

button:hover:not(:disabled) {
  transform: translateY(-2px) scale(1.02);
  box-shadow: 0 14px 32px rgba(34, 211, 238, 0.45);
}

button:active:not(:disabled) {
  transform: translateY(0) scale(0.97);
}

button:disabled { opacity: .35; cursor: not-allowed; box-shadow: none; transform: none; }

.privacy {
  margin: 28px 0;
  padding: 24px;
  border-radius: 18px;
  background: rgba(34, 211, 238, 0.12);
  border: 1px solid rgba(34, 211, 238, 0.3);
  font-size: 20px;
  line-height: 1.5;
}

.lesson {
  margin: 28px 0;
  padding: 24px;
  border-radius: 18px;
  background: rgba(74, 222, 128, 0.12);
  border: 1px solid rgba(74, 222, 128, 0.32);
  font-size: 20px;
  line-height: 1.5;
}

.tips {
  margin: 28px 0;
  padding: 24px;
  border-radius: 18px;
  background: rgba(251, 146, 60, 0.12);
  border: 1px solid rgba(251, 146, 60, 0.32);
  font-size: 20px;
  line-height: 1.5;
}

.tips ul {
  margin: 12px 0;
  padding-left: 22px;
}

.tips li {
  margin: 10px 0;
}

audio { width: 100%; margin: 24px 0; border-radius: 12px; }

footer {
  text-align: center;
  padding: 24px;
  opacity: .8;
  font-size: 13px;
}

footer a {
  color: var(--accent-cyan);
  opacity: 1;
  font-weight: 700;
  text-decoration: none;
}

footer a:hover { text-decoration: underline; }

/* --- Home hub --- */

.hub-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  margin-top: 28px;
}

.hub-card {
  --accent: var(--accent-cyan);
  display: block;
  padding: 32px;
  border: 2px solid var(--card-border);
  border-radius: 24px;
  background: var(--card-bg);
  text-decoration: none;
  color: inherit;
  transition: border-color .15s ease, transform .15s ease, box-shadow .15s ease;
}

.hub-card:hover {
  border-color: var(--accent);
  transform: translateY(-4px) scale(1.01);
  box-shadow: 0 16px 36px rgba(8, 5, 30, 0.4);
}

.hub-card .eyebrow { color: var(--accent); }

.hub-card h2 {
  font-size: clamp(24px, 3vw, 32px);
  margin: 8px 0 12px;
}

.hub-card p:last-child {
  font-size: 16px;
  opacity: .85;
  margin: 0;
}

.hub-card.accent-cyan { --accent: var(--accent-cyan); }
.hub-card.accent-orange { --accent: var(--accent-orange); }
.hub-card.accent-pink { --accent: var(--accent-pink); }
.hub-card.accent-green { --accent: var(--accent-green); }

@media (max-width: 900px) {
  .hub-grid {
    grid-template-columns: 1fr 1fr;
  }
}

@media (max-width: 640px) {
  .hub-grid {
    grid-template-columns: 1fr;
  }
}

/* --- Which Is Fake? game --- */

.clip-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin: 28px 0;
}

.clip-choice {
  padding: 20px;
  border-radius: 20px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid var(--card-border);
}

.clip-name {
  margin: 0 0 8px;
  font-size: 14px;
  font-weight: 800;
  letter-spacing: .1em;
  color: var(--accent-pink);
}

.clip-media video,
.clip-media img {
  width: 100%;
  border-radius: 14px;
  display: block;
  background: #0b0d12;
}

.clip-media img {
  aspect-ratio: 16 / 9;
  object-fit: cover;
}

.guess-btn {
  width: 100%;
  margin-top: 12px;
  background: linear-gradient(120deg, var(--accent-green), var(--accent-cyan));
  color: #0b1f14;
}

#feedback {
  margin-top: 16px;
  padding: 24px;
  border-radius: 18px;
  background: rgba(167, 139, 250, 0.14);
  border: 1px solid rgba(167, 139, 250, 0.32);
}

#feedbackVerdict {
  font-size: 22px;
  font-weight: 800;
  margin: 0 0 10px;
  color: var(--accent-purple);
}

#noRoundsNote {
  margin-top: 20px;
  opacity: .8;
}

@media (max-width: 640px) {
  .clip-grid {
    grid-template-columns: 1fr;
  }
}

/* --- Motion & polish --- */

@keyframes cardIn {
  from { opacity: 0; transform: translateY(14px) scale(.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.card:not(.hidden) {
  animation: cardIn .45s cubic-bezier(.16, 1, .3, 1);
}

.round-dots {
  display: flex;
  gap: 8px;
  margin-bottom: 10px;
}

.round-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.18);
  transition: background .2s ease, transform .2s ease;
}

.round-dot.done { background: var(--accent-green); }

.round-dot.current {
  background: var(--accent-cyan);
  transform: scale(1.3);
  box-shadow: 0 0 0 4px rgba(34, 211, 238, 0.25);
}

.difficulty-pill {
  display: inline-block;
  margin-left: 10px;
  padding: 3px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 800;
  letter-spacing: .06em;
  vertical-align: middle;
}

.difficulty-pill.pill-easy {
  background: rgba(74, 222, 128, 0.18);
  color: var(--accent-green);
  border: 1px solid rgba(74, 222, 128, 0.4);
}

.difficulty-pill.pill-medium {
  background: rgba(251, 146, 60, 0.18);
  color: var(--accent-orange);
  border: 1px solid rgba(251, 146, 60, 0.4);
}

.difficulty-pill.pill-hard {
  background: rgba(244, 114, 182, 0.18);
  color: var(--accent-pink);
  border: 1px solid rgba(244, 114, 182, 0.4);
}

.confetti-canvas {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: 80;
}

/* --- Homepage mascot & countdown --- */

.mascot {
  display: block;
  margin: 0 auto 4px;
  animation: mascotBounce 3.2s ease-in-out infinite;
  filter: drop-shadow(0 10px 22px rgba(34, 211, 238, .35));
}

@keyframes mascotBounce {
  0%, 100% { transform: translateY(0) rotate(-2deg); }
  50% { transform: translateY(-8px) rotate(2deg); }
}

.floaty-icons {
  position: fixed;
  inset: 0;
  overflow: hidden;
  z-index: 0;
  pointer-events: none;
}

.floaty-icon {
  position: absolute;
  bottom: -60px;
  font-size: 26px;
  opacity: 0;
  animation-name: floatUp;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
}

@keyframes floatUp {
  0% { transform: translateY(0) translateX(0) rotate(0deg); opacity: 0; }
  8% { opacity: .16; }
  92% { opacity: .16; }
  100% { transform: translateY(-125vh) translateX(24px) rotate(24deg); opacity: 0; }
}
EOF

echo "-- rewriting deploy/Dockerfile --"
cat > deploy/Dockerfile <<'EOF'
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/cybervoice

COPY app /opt/cybervoice/app
COPY requirements-app.txt /opt/cybervoice/requirements-app.txt

RUN python -m pip install --upgrade pip \
    && python -m pip install -r /opt/cybervoice/requirements-app.txt

WORKDIR /opt/cybervoice/app

EXPOSE 8080

CMD ["python", "app.py"]
EOF

echo "-- rewriting deploy/compose.yaml --"
cat > deploy/compose.yaml <<'EOF'
services:
  cybervoice:
    build:
      context: ..
      dockerfile: deploy/Dockerfile
    environment:
      CYBERVOICE_BIND: "0.0.0.0"
    ports:
      - "127.0.0.1:8080:8080"
    read_only: true
    volumes:
      - /tmp
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    restart: unless-stopped
EOF

echo "-- rewriting scripts/run-native.sh --"
cat > scripts/run-native.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
EOF
chmod +x scripts/run-native.sh

echo "-- rewriting scripts/verify-offline.sh --"
cat > scripts/verify-offline.sh <<'EOF'
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
EOF
chmod +x scripts/verify-offline.sh

echo "-- rewriting .gitignore --"
cat > .gitignore <<'EOF'
# --- Python ---
__pycache__/
*.pyc
*.pyo
.Python
*.egg-info/
.pytest_cache/

# --- Virtualenv ---
.venv/
venv/
env/

# --- macOS ---
.DS_Store

# --- Docker ---
*.log

# --- Editors ---
.vscode/
.idea/
EOF

echo "-- rewriting README.md --"
cat > README.md <<'EOF'
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
EOF

echo "-- staging and committing --"
git add -A
git status --short
git commit -m "Remove voice-cloning station; keep the three Which Is Fake? games"
git push
echo "-- done --"