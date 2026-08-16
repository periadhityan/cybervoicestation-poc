#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

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

.privacy, blockquote {
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

.consent-row {
  display: flex;
  gap: 14px;
  font-size: 18px;
  align-items: flex-start;
}

.consent-row input {
  width: 24px;
  height: 24px;
  accent-color: var(--accent-cyan);
}

#timer {
  font-size: 64px;
  font-variant-numeric: tabular-nums;
  margin: 24px 0;
  color: var(--accent-pink);
  font-weight: 800;
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
  grid-template-columns: repeat(2, 1fr);
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
EOF

cat > app/templates/home.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cybersecurity Awareness Month 2026</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <main class="shell">
    <section class="card" id="homeIntro">
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

cat > app/templates/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Hear Yourself Hacked</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <main class="shell">
    <section class="card" id="intro">
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH</p>
      <h1>🎙️ Hear Yourself Hacked</h1>
      <p class="lead">Could an attacker convincingly sound like you?</p>

      <div class="privacy">
        <strong>Local demo.</strong>
        Your recording is processed on this device for this demonstration and
        is deleted after the generated audio has been prepared.
      </div>

      <label class="consent-row">
        <input id="consent" type="checkbox">
        <span>I consent to my voice being temporarily processed for this demonstration.</span>
      </label>

      <button id="startBtn" disabled>START EXPERIENCE</button>
    </section>

    <section class="card hidden" id="recordingPanel">
      <p class="eyebrow">STEP 1</p>
      <h2>Read this naturally</h2>
      <blockquote>
        This is a short recording for a cybersecurity awareness demonstration.
        Artificial intelligence can learn characteristics of a person's voice
        from a surprisingly small amount of audio.
      </blockquote>
      <div id="timer">00:00</div>
      <button id="recordBtn">START RECORDING</button>
      <button id="stopBtn" disabled>STOP & GENERATE</button>
    </section>

    <section class="card hidden" id="processingPanel">
      <p class="eyebrow">STEP 2</p>
      <h2>Creating the demonstration…</h2>
      <p>This processing is happening locally.</p>
      <div class="spinner"></div>
    </section>

    <section class="card hidden" id="resultPanel">
      <p class="eyebrow">STEP 3</p>
      <h2>That voice was generated.</h2>
      <audio id="resultAudio" controls autoplay></audio>

      <div class="lesson">
        <h3>Voice is not proof of identity.</h3>
        <p><strong>PAUSE.</strong> Do not let urgency control the decision.</p>
        <p><strong>THINK.</strong> Does the request make sense?</p>
        <p><strong>REPORT.</strong> If the request is suspicious, use the Phish Alert button or the appropriate trusted reporting channel.</p>
      </div>

      <p id="cleanupStatus">Session files have been cleared from the application workspace.</p>
      <button id="finishBtn">FINISH</button>
    </section>

    <section class="card hidden error" id="errorPanel">
      <h2>Demo could not complete</h2>
      <p id="errorText"></p>
      <button id="errorResetBtn">RESET</button>
    </section>
  </main>

  <footer>
    Engine device: {{ device }} &middot; <a href="/">&larr; All Activities</a>
  </footer>

  <script src="/static/app.js"></script>
</body>
</html>
EOF

cat > app/templates/spot_the_fake.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Which Is Fake? (Audio)</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <main class="shell">
    <section class="card" id="intro">
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH</p>
      <h1>🎧 Which Is Fake? (Audio)</h1>
      <p class="lead">Two short clips. One is real. One was generated.</p>

      <div class="privacy">
        No personal data is collected to play. Your score exists only in
        this browser tab and is not saved anywhere.
      </div>

      <button id="startBtn">START GAME</button>
      <p id="noRoundsNote" class="hidden">
        No rounds are configured yet -- check back once the game content has
        been added.
      </p>
    </section>

    <section class="card hidden" id="roundPanel">
      <p class="eyebrow"><span id="roundProgress"></span> &middot; SCORE <span id="scoreLine">0/0</span></p>
      <h2 id="subjectLabel"></h2>

      <div class="clip-grid">
        <div class="clip-choice">
          <p class="clip-name">CLIP A</p>
          <audio id="clipA" controls></audio>
          <button class="guess-btn" data-slot="A">THIS ONE IS REAL</button>
        </div>
        <div class="clip-choice">
          <p class="clip-name">CLIP B</p>
          <audio id="clipB" controls></audio>
          <button class="guess-btn" data-slot="B">THIS ONE IS REAL</button>
        </div>
      </div>

      <div class="hidden" id="feedback">
        <p id="feedbackVerdict"></p>
        <p id="feedbackNote"></p>
        <button id="nextBtn">NEXT ROUND</button>
      </div>
    </section>

    <section class="card hidden" id="resultPanel">
      <p class="eyebrow">GAME OVER</p>
      <h2 id="finalScore"></h2>

      <div class="tips">
        <h3>What Often Gives a Deepfake Away</h3>
        <p>Common tells in synthetic audio -- treat these as a caution, not a guarantee:</p>
        <ul>
          <li>Unnaturally even pacing, with none of the small pauses, restarts, or "um"s of natural speech.</li>
          <li>A flat or mismatched emotional tone -- urgency in the words, but calm in the delivery.</li>
          <li>Missing background sound: no breathing, no room noise, no mouth or lip sounds.</li>
          <li>A slightly metallic, warbly, or inconsistent audio quality within the same clip.</li>
          <li>Odd emphasis on the wrong word, or stiff transitions between sentences.</li>
        </ul>
        <p>As these tools improve, some fakes will sound completely convincing. That's exactly why the rule is <strong>PAUSE, THINK, REPORT</strong> -- not "listen closely enough."</p>
      </div>

      <div class="lesson">
        <h3>Voice is not proof of identity.</h3>
        <p><strong>PAUSE.</strong> Do not let urgency control the decision.</p>
        <p><strong>THINK.</strong> Does the request make sense?</p>
        <p><strong>REPORT.</strong> If the request is suspicious, use the Phish Alert button or the appropriate trusted reporting channel.</p>
      </div>

      <button id="playAgainBtn">PLAY AGAIN</button>
    </section>
  </main>

  <footer>
    <a href="/">&larr; All Activities</a>
  </footer>

  <script src="/static/spot_the_fake.js"></script>
</body>
</html>
EOF

cat > app/templates/spot_the_fake_video.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Which Is Fake? (Video)</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <main class="shell">
    <section class="card" id="intro">
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH</p>
      <h1>🎬 Which Is Fake? (Video)</h1>
      <p class="lead">Two short clips. One is real. One was generated.</p>

      <div class="privacy">
        No personal data is collected to play. Your score exists only in
        this browser tab and is not saved anywhere.
      </div>

      <button id="startBtn">START GAME</button>
      <p id="noRoundsNote" class="hidden">
        No rounds are configured yet -- check back once the game content has
        been added.
      </p>
    </section>

    <section class="card hidden" id="roundPanel">
      <p class="eyebrow"><span id="roundProgress"></span> &middot; SCORE <span id="scoreLine">0/0</span></p>
      <h2 id="subjectLabel"></h2>

      <div class="clip-grid">
        <div class="clip-choice">
          <p class="clip-name">CLIP A</p>
          <div class="clip-media" id="clipAMedia"></div>
          <button class="guess-btn" data-slot="A">THIS ONE IS REAL</button>
        </div>
        <div class="clip-choice">
          <p class="clip-name">CLIP B</p>
          <div class="clip-media" id="clipBMedia"></div>
          <button class="guess-btn" data-slot="B">THIS ONE IS REAL</button>
        </div>
      </div>

      <div class="hidden" id="feedback">
        <p id="feedbackVerdict"></p>
        <p id="feedbackNote"></p>
        <button id="nextBtn">NEXT ROUND</button>
      </div>
    </section>

    <section class="card hidden" id="resultPanel">
      <p class="eyebrow">GAME OVER</p>
      <h2 id="finalScore"></h2>

      <div class="tips">
        <h3>What Often Gives a Deepfake Video Away</h3>
        <p>Common tells in synthetic/manipulated video -- treat these as a caution, not a guarantee:</p>
        <ul>
          <li>Blinking that's too rare, too regular, or missing entirely.</li>
          <li>Lighting or shadows on the face that don't match the rest of the scene.</li>
          <li>Blurring, warping, or flickering around the edges of the face, hairline, or ears.</li>
          <li>Lip movements slightly out of sync with the audio.</li>
          <li>Unnatural or absent head/body movement while the face keeps changing expression.</li>
        </ul>
        <p>As these tools improve, some fakes will look completely convincing. That's exactly why the rule is <strong>PAUSE, THINK, REPORT</strong> -- not "look closely enough."</p>
      </div>

      <div class="lesson">
        <h3>Seeing is not proof of identity.</h3>
        <p><strong>PAUSE.</strong> Do not let urgency control the decision.</p>
        <p><strong>THINK.</strong> Does the request make sense?</p>
        <p><strong>REPORT.</strong> If the request is suspicious, use the Phish Alert button or the appropriate trusted reporting channel.</p>
      </div>

      <button id="playAgainBtn">PLAY AGAIN</button>
    </section>
  </main>

  <footer>
    <a href="/">&larr; All Activities</a>
  </footer>

  <script src="/static/spot_the_fake_video.js"></script>
</body>
</html>
EOF

cat > app/templates/spot_the_fake_image.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Which Is Fake? (Picture)</title>
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <main class="shell">
    <section class="card" id="intro">
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH</p>
      <h1>🖼️ Which Is Fake? (Picture)</h1>
      <p class="lead">Two photos. One is real. One was generated.</p>

      <div class="privacy">
        No personal data is collected to play. Your score exists only in
        this browser tab and is not saved anywhere.
      </div>

      <button id="startBtn">START GAME</button>
      <p id="noRoundsNote" class="hidden">
        No rounds are configured yet -- check back once the game content has
        been added.
      </p>
    </section>

    <section class="card hidden" id="roundPanel">
      <p class="eyebrow"><span id="roundProgress"></span> &middot; SCORE <span id="scoreLine">0/0</span></p>
      <h2 id="subjectLabel"></h2>

      <div class="clip-grid">
        <div class="clip-choice">
          <p class="clip-name">PHOTO A</p>
          <div class="clip-media" id="clipAMedia"></div>
          <button class="guess-btn" data-slot="A">THIS ONE IS REAL</button>
        </div>
        <div class="clip-choice">
          <p class="clip-name">PHOTO B</p>
          <div class="clip-media" id="clipBMedia"></div>
          <button class="guess-btn" data-slot="B">THIS ONE IS REAL</button>
        </div>
      </div>

      <div class="hidden" id="feedback">
        <p id="feedbackVerdict"></p>
        <p id="feedbackNote"></p>
        <button id="nextBtn">NEXT ROUND</button>
      </div>
    </section>

    <section class="card hidden" id="resultPanel">
      <p class="eyebrow">GAME OVER</p>
      <h2 id="finalScore"></h2>

      <div class="tips">
        <h3>What Often Gives a Deepfake Photo Away</h3>
        <p>Common tells in AI-generated or manipulated images -- treat these as a caution, not a guarantee:</p>
        <ul>
          <li>Hands, ears, teeth, or glasses that look slightly wrong, asymmetric, or malformed.</li>
          <li>Skin that's unnaturally smooth, or hair that blurs strangely into the background.</li>
          <li>Reflections, shadows, or lighting that don't match the rest of the scene.</li>
          <li>Backgrounds with warped text, odd patterns, or objects that don't quite make sense.</li>
          <li>An overall quality mismatch between the subject and the background.</li>
        </ul>
        <p>As these tools improve, some fakes will look completely convincing. That's exactly why the rule is <strong>PAUSE, THINK, REPORT</strong> -- not "look closely enough."</p>
      </div>

      <div class="lesson">
        <h3>Seeing is not proof of identity.</h3>
        <p><strong>PAUSE.</strong> Do not let urgency control the decision.</p>
        <p><strong>THINK.</strong> Does the request make sense?</p>
        <p><strong>REPORT.</strong> If the request is suspicious, use the Phish Alert button or the appropriate trusted reporting channel.</p>
      </div>

      <button id="playAgainBtn">PLAY AGAIN</button>
    </section>
  </main>

  <footer>
    <a href="/">&larr; All Activities</a>
  </footer>

  <script src="/static/spot_the_fake_image.js"></script>
</body>
</html>
EOF

echo "-- files written --"
git status --short
git add app/static/style.css app/templates/home.html app/templates/index.html app/templates/spot_the_fake.html app/templates/spot_the_fake_video.html app/templates/spot_the_fake_image.html
git commit -m "Colorful cartoony visual redesign: security-themed gradient background, accent-colored cards/buttons, station emoji icons"
git push
echo "-- done, hard-refresh your browser (Cmd+Shift+R) to see it --"