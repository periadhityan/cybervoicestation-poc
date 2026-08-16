#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

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
        Try each station below. None of them collect your name, employee
        ID, or keep anything you record or upload after your session ends.
      </p>
    </section>

    <div class="hub-grid">
      <a class="hub-card accent-cyan" href="/hear-yourself-hacked">
        <p class="eyebrow">STATION 1</p>
        <h2>🎙️ Hear Yourself Hacked</h2>
        <p>Clone your own voice locally and hear how convincing an AI-generated version of it can sound.</p>
      </a>

      <a class="hub-card accent-pink" href="/spot-the-fake">
        <p class="eyebrow">STATION 2</p>
        <h2>🎧 Which Is Fake? (Audio)</h2>
        <p>Listen to two short clips. Guess which one is the real recording.</p>
      </a>

      <a class="hub-card accent-orange" href="/spot-the-fake-video">
        <p class="eyebrow">STATION 3</p>
        <h2>🎬 Which Is Fake? (Video)</h2>
        <p>Watch two short clips. Guess which one is the real footage.</p>
      </a>

      <a class="hub-card accent-green" href="/spot-the-fake-image">
        <p class="eyebrow">STATION 4</p>
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

python3 - <<'PYEOF'
import re
path = "app/static/style.css"
with open(path, "r", encoding="utf-8") as fh:
    css = fh.read()

pattern = re.compile(
    r"\.countdown-banner \{.*?\n\}\n\n",
    re.DOTALL,
)
new_css, count = pattern.subn("", css, count=1)
if count != 1:
    raise SystemExit("Expected to find exactly one .countdown-banner block, found %d -- aborting, please check app/static/style.css by hand." % count)

with open(path, "w", encoding="utf-8") as fh:
    fh.write(new_css)

print("Removed .countdown-banner rule from style.css")
PYEOF

echo "-- files written --"
git status --short
git add app/templates/home.html app/static/style.css
git commit -m "Drop homepage kickoff countdown banner"
git push
echo "-- done, hard-refresh your browser (Cmd+Shift+R) to see it --"