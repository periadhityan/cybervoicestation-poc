#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

cat > app/static/favicon.svg <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#22d3ee"/>
      <stop offset="100%" stop-color="#a78bfa"/>
    </linearGradient>
  </defs>
  <path d="M32 2 L58 12 V32 C58 50 46 60 32 62 C18 60 6 50 6 32 V12 Z" fill="url(#g)" stroke="#1a1442" stroke-width="3"/>
  <circle cx="23" cy="30" r="4" fill="#1a1442"/>
  <circle cx="41" cy="30" r="4" fill="#1a1442"/>
  <path d="M22 42 Q32 50 42 42" stroke="#1a1442" stroke-width="3" fill="none" stroke-linecap="round"/>
</svg>
EOF

cat > app/static/confetti.js <<'EOF'
/* Tiny self-contained confetti burst -- no external assets, works fully
   offline/air-gapped. Call window.launchConfetti() to fire it. */
(function () {
  function launchConfetti() {
    const canvas = document.createElement('canvas');
    canvas.className = 'confetti-canvas';
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    document.body.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const colors = ['#22d3ee', '#fb923c', '#f472b6', '#4ade80', '#a78bfa'];

    const pieces = Array.from({ length: 140 }, () => ({
      x: Math.random() * canvas.width,
      y: -20 - Math.random() * canvas.height * 0.4,
      w: 6 + Math.random() * 6,
      h: 10 + Math.random() * 8,
      color: colors[Math.floor(Math.random() * colors.length)],
      speed: 2 + Math.random() * 3,
      drift: (Math.random() - 0.5) * 2,
      rotation: Math.random() * Math.PI,
      spin: (Math.random() - 0.5) * 0.2,
    }));

    let frame = 0;
    const maxFrames = 220;

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', resize);

    function tick() {
      frame += 1;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      pieces.forEach((p) => {
        p.y += p.speed;
        p.x += p.drift;
        p.rotation += p.spin;
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rotation);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        ctx.restore();
      });
      if (frame < maxFrames) {
        requestAnimationFrame(tick);
      } else {
        window.removeEventListener('resize', resize);
        canvas.remove();
      }
    }
    requestAnimationFrame(tick);
  }

  window.launchConfetti = launchConfetti;
})();
EOF

cat >> app/static/style.css <<'EOF'

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

.countdown-banner {
  display: inline-block;
  margin: 16px 0 2px;
  padding: 10px 22px;
  border-radius: 999px;
  background: rgba(74, 222, 128, 0.14);
  border: 1px solid rgba(74, 222, 128, 0.35);
  font-weight: 800;
  font-size: 15px;
  letter-spacing: .02em;
  color: #d1fae5;
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
      <div class="countdown-banner" id="countdownBanner"></div>
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

  <script>
    (function () {
      var el = document.getElementById('countdownBanner');
      if (!el) return;
      var target = new Date('2026-10-01T00:00:00');
      var end = new Date('2026-11-01T00:00:00');
      var now = new Date();
      if (now < target) {
        var days = Math.ceil((target - now) / 86400000);
        el.textContent = '🗓️ Cybersecurity Awareness Month kicks off in ' + days + (days === 1 ? ' day!' : ' days!');
      } else if (now < end) {
        el.textContent = '🎉 Cybersecurity Awareness Month is live all October -- go play every station!';
      } else {
        el.textContent = '🛡️ Thanks for taking part in Cybersecurity Awareness Month 2026!';
      }
    })();
  </script>
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
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
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
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
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
      <div class="round-dots" id="roundDots"></div>
      <p class="eyebrow">
        <span id="roundProgress"></span><span class="difficulty-pill hidden" id="difficultyPill"></span>
        &middot; SCORE <span id="scoreLine">0/0</span>
      </p>
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

  <script src="/static/confetti.js"></script>
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
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
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
      <div class="round-dots" id="roundDots"></div>
      <p class="eyebrow">
        <span id="roundProgress"></span><span class="difficulty-pill hidden" id="difficultyPill"></span>
        &middot; SCORE <span id="scoreLine">0/0</span>
      </p>
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

  <script src="/static/confetti.js"></script>
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
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
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
      <div class="round-dots" id="roundDots"></div>
      <p class="eyebrow">
        <span id="roundProgress"></span><span class="difficulty-pill hidden" id="difficultyPill"></span>
        &middot; SCORE <span id="scoreLine">0/0</span>
      </p>
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

  <script src="/static/confetti.js"></script>
  <script src="/static/spot_the_fake_image.js"></script>
</body>
</html>
EOF

cat > app/static/spot_the_fake.js <<'EOF'
const intro = document.getElementById('intro');
const startBtn = document.getElementById('startBtn');
const noRoundsNote = document.getElementById('noRoundsNote');

const roundPanel = document.getElementById('roundPanel');
const roundProgress = document.getElementById('roundProgress');
const roundDots = document.getElementById('roundDots');
const difficultyPill = document.getElementById('difficultyPill');
const scoreLine = document.getElementById('scoreLine');
const subjectLabel = document.getElementById('subjectLabel');
const clipA = document.getElementById('clipA');
const clipB = document.getElementById('clipB');
const guessBtns = document.querySelectorAll('.guess-btn');
const feedback = document.getElementById('feedback');
const feedbackVerdict = document.getElementById('feedbackVerdict');
const feedbackNote = document.getElementById('feedbackNote');
const nextBtn = document.getElementById('nextBtn');

const resultPanel = document.getElementById('resultPanel');
const finalScore = document.getElementById('finalScore');
const playAgainBtn = document.getElementById('playAgainBtn');

let games = [];      // shuffled, per-round randomized slot assignment
let currentIndex = 0;
let score = 0;
let answered = false;

function showOnly(panel) {
  [intro, roundPanel, resultPanel].forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

async function loadRounds() {
  const response = await fetch('/api/spot-the-fake/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

function buildGames(rounds) {
  return rounds.map(round => {
    const slots = shuffle([
      { url: round.real_audio_url, isReal: true },
      { url: round.fake_audio_url, isReal: false },
    ]);
    return {
      id: round.id,
      difficulty: round.difficulty,
      subjectLabel: round.subject_label,
      revealNote: round.reveal_note,
      slotA: slots[0],
      slotB: slots[1],
    };
  });
}

function pauseClips() {
  clipA.pause();
  clipB.pause();
}

function renderDots() {
  roundDots.innerHTML = '';
  games.forEach((_, i) => {
    const dot = document.createElement('span');
    dot.className = 'round-dot';
    if (i < currentIndex) dot.classList.add('done');
    else if (i === currentIndex) dot.classList.add('current');
    roundDots.appendChild(dot);
  });
}

function renderRound() {
  const game = games[currentIndex];
  answered = false;
  feedback.classList.add('hidden');
  guessBtns.forEach(btn => (btn.disabled = false));

  roundProgress.textContent = `ROUND ${currentIndex + 1} OF ${games.length}`;
  if (game.difficulty) {
    difficultyPill.textContent = game.difficulty.toUpperCase();
    difficultyPill.className = `difficulty-pill pill-${game.difficulty}`;
  } else {
    difficultyPill.classList.add('hidden');
  }
  renderDots();
  scoreLine.textContent = `${score}/${games.length}`;
  subjectLabel.textContent = game.subjectLabel;

  clipA.src = game.slotA.url;
  clipB.src = game.slotB.url;
  clipA.load();
  clipB.load();
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  pauseClips();
  guessBtns.forEach(btn => (btn.disabled = true));

  const game = games[currentIndex];
  const guessedSlot = slotLetter === 'A' ? game.slotA : game.slotB;
  const correct = guessedSlot.isReal;
  if (correct) score += 1;

  feedbackVerdict.textContent = correct ? 'Correct -- that was the real one.' : 'Not quite -- that was the fake.';
  feedbackNote.textContent = game.revealNote || '';
  feedback.classList.remove('hidden');
  scoreLine.textContent = `${score}/${games.length}`;
}

function nextRound() {
  currentIndex += 1;
  if (currentIndex >= games.length) {
    pauseClips();
    finalScore.textContent = `You spotted ${score} out of ${games.length} correctly.`;
    showOnly(resultPanel);
    if (games.length && score / games.length >= 0.8 && window.launchConfetti) {
      window.launchConfetti();
    }
    return;
  }
  renderRound();
}

async function startGame() {
  const rounds = await loadRounds();
  if (!rounds.length) {
    noRoundsNote.classList.remove('hidden');
    return;
  }
  games = buildGames(rounds);
  currentIndex = 0;
  score = 0;
  showOnly(roundPanel);
  renderRound();
}

startBtn.addEventListener('click', startGame);
nextBtn.addEventListener('click', nextRound);
playAgainBtn.addEventListener('click', startGame);
guessBtns.forEach(btn => {
  btn.addEventListener('click', () => handleGuess(btn.dataset.slot));
});
EOF

cat > app/static/spot_the_fake_video.js <<'EOF'
const intro = document.getElementById('intro');
const startBtn = document.getElementById('startBtn');
const noRoundsNote = document.getElementById('noRoundsNote');

const roundPanel = document.getElementById('roundPanel');
const roundProgress = document.getElementById('roundProgress');
const roundDots = document.getElementById('roundDots');
const difficultyPill = document.getElementById('difficultyPill');
const scoreLine = document.getElementById('scoreLine');
const subjectLabel = document.getElementById('subjectLabel');
const clipAMedia = document.getElementById('clipAMedia');
const clipBMedia = document.getElementById('clipBMedia');
const guessBtns = document.querySelectorAll('.guess-btn');
const feedback = document.getElementById('feedback');
const feedbackVerdict = document.getElementById('feedbackVerdict');
const feedbackNote = document.getElementById('feedbackNote');
const nextBtn = document.getElementById('nextBtn');

const resultPanel = document.getElementById('resultPanel');
const finalScore = document.getElementById('finalScore');
const playAgainBtn = document.getElementById('playAgainBtn');

let games = [];
let currentIndex = 0;
let score = 0;
let answered = false;

function showOnly(panel) {
  [intro, roundPanel, resultPanel].forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

async function loadRounds() {
  const response = await fetch('/api/spot-the-fake-video/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

function buildGames(rounds) {
  return rounds.map(round => {
    const slots = shuffle([
      { url: round.real_video_url, isReal: true },
      { url: round.fake_video_url, isReal: false },
    ]);
    return {
      id: round.id,
      difficulty: round.difficulty,
      subjectLabel: round.subject_label,
      revealNote: round.reveal_note,
      slotA: slots[0],
      slotB: slots[1],
    };
  });
}

function makeVideoEl(url) {
  const video = document.createElement('video');
  video.src = url;
  video.controls = true;
  video.playsInline = true;
  return video;
}

function pauseClips() {
  [clipAMedia, clipBMedia].forEach(container => {
    const video = container.querySelector('video');
    if (video) video.pause();
  });
}

function renderDots() {
  roundDots.innerHTML = '';
  games.forEach((_, i) => {
    const dot = document.createElement('span');
    dot.className = 'round-dot';
    if (i < currentIndex) dot.classList.add('done');
    else if (i === currentIndex) dot.classList.add('current');
    roundDots.appendChild(dot);
  });
}

function renderRound() {
  const game = games[currentIndex];
  answered = false;
  feedback.classList.add('hidden');
  guessBtns.forEach(btn => (btn.disabled = false));

  roundProgress.textContent = `ROUND ${currentIndex + 1} OF ${games.length}`;
  if (game.difficulty) {
    difficultyPill.textContent = game.difficulty.toUpperCase();
    difficultyPill.className = `difficulty-pill pill-${game.difficulty}`;
  } else {
    difficultyPill.classList.add('hidden');
  }
  renderDots();
  scoreLine.textContent = `${score}/${games.length}`;
  subjectLabel.textContent = game.subjectLabel;

  clipAMedia.replaceChildren(makeVideoEl(game.slotA.url));
  clipBMedia.replaceChildren(makeVideoEl(game.slotB.url));
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  pauseClips();
  guessBtns.forEach(btn => (btn.disabled = true));

  const game = games[currentIndex];
  const guessedSlot = slotLetter === 'A' ? game.slotA : game.slotB;
  const correct = guessedSlot.isReal;
  if (correct) score += 1;

  feedbackVerdict.textContent = correct ? 'Correct -- that was the real one.' : 'Not quite -- that was the fake.';
  feedbackNote.textContent = game.revealNote || '';
  feedback.classList.remove('hidden');
  scoreLine.textContent = `${score}/${games.length}`;
}

function nextRound() {
  currentIndex += 1;
  if (currentIndex >= games.length) {
    pauseClips();
    finalScore.textContent = `You spotted ${score} out of ${games.length} correctly.`;
    showOnly(resultPanel);
    if (games.length && score / games.length >= 0.8 && window.launchConfetti) {
      window.launchConfetti();
    }
    return;
  }
  renderRound();
}

async function startGame() {
  const rounds = await loadRounds();
  if (!rounds.length) {
    noRoundsNote.classList.remove('hidden');
    return;
  }
  games = buildGames(rounds);
  currentIndex = 0;
  score = 0;
  showOnly(roundPanel);
  renderRound();
}

startBtn.addEventListener('click', startGame);
nextBtn.addEventListener('click', nextRound);
playAgainBtn.addEventListener('click', startGame);
guessBtns.forEach(btn => {
  btn.addEventListener('click', () => handleGuess(btn.dataset.slot));
});
EOF

cat > app/static/spot_the_fake_image.js <<'EOF'
const intro = document.getElementById('intro');
const startBtn = document.getElementById('startBtn');
const noRoundsNote = document.getElementById('noRoundsNote');

const roundPanel = document.getElementById('roundPanel');
const roundProgress = document.getElementById('roundProgress');
const roundDots = document.getElementById('roundDots');
const difficultyPill = document.getElementById('difficultyPill');
const scoreLine = document.getElementById('scoreLine');
const subjectLabel = document.getElementById('subjectLabel');
const clipAMedia = document.getElementById('clipAMedia');
const clipBMedia = document.getElementById('clipBMedia');
const guessBtns = document.querySelectorAll('.guess-btn');
const feedback = document.getElementById('feedback');
const feedbackVerdict = document.getElementById('feedbackVerdict');
const feedbackNote = document.getElementById('feedbackNote');
const nextBtn = document.getElementById('nextBtn');

const resultPanel = document.getElementById('resultPanel');
const finalScore = document.getElementById('finalScore');
const playAgainBtn = document.getElementById('playAgainBtn');

let games = [];
let currentIndex = 0;
let score = 0;
let answered = false;

function showOnly(panel) {
  [intro, roundPanel, resultPanel].forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

async function loadRounds() {
  const response = await fetch('/api/spot-the-fake-image/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

function buildGames(rounds) {
  return rounds.map(round => {
    const slots = shuffle([
      { url: round.real_image_url, isReal: true },
      { url: round.fake_image_url, isReal: false },
    ]);
    return {
      id: round.id,
      difficulty: round.difficulty,
      subjectLabel: round.subject_label,
      revealNote: round.reveal_note,
      slotA: slots[0],
      slotB: slots[1],
    };
  });
}

function makeImageEl(url) {
  const img = document.createElement('img');
  img.src = url;
  img.alt = 'Comparison photo';
  return img;
}

function renderDots() {
  roundDots.innerHTML = '';
  games.forEach((_, i) => {
    const dot = document.createElement('span');
    dot.className = 'round-dot';
    if (i < currentIndex) dot.classList.add('done');
    else if (i === currentIndex) dot.classList.add('current');
    roundDots.appendChild(dot);
  });
}

function renderRound() {
  const game = games[currentIndex];
  answered = false;
  feedback.classList.add('hidden');
  guessBtns.forEach(btn => (btn.disabled = false));

  roundProgress.textContent = `ROUND ${currentIndex + 1} OF ${games.length}`;
  if (game.difficulty) {
    difficultyPill.textContent = game.difficulty.toUpperCase();
    difficultyPill.className = `difficulty-pill pill-${game.difficulty}`;
  } else {
    difficultyPill.classList.add('hidden');
  }
  renderDots();
  scoreLine.textContent = `${score}/${games.length}`;
  subjectLabel.textContent = game.subjectLabel;

  clipAMedia.replaceChildren(makeImageEl(game.slotA.url));
  clipBMedia.replaceChildren(makeImageEl(game.slotB.url));
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  guessBtns.forEach(btn => (btn.disabled = true));

  const game = games[currentIndex];
  const guessedSlot = slotLetter === 'A' ? game.slotA : game.slotB;
  const correct = guessedSlot.isReal;
  if (correct) score += 1;

  feedbackVerdict.textContent = correct ? 'Correct -- that was the real one.' : 'Not quite -- that was the fake.';
  feedbackNote.textContent = game.revealNote || '';
  feedback.classList.remove('hidden');
  scoreLine.textContent = `${score}/${games.length}`;
}

function nextRound() {
  currentIndex += 1;
  if (currentIndex >= games.length) {
    finalScore.textContent = `You spotted ${score} out of ${games.length} correctly.`;
    showOnly(resultPanel);
    if (games.length && score / games.length >= 0.8 && window.launchConfetti) {
      window.launchConfetti();
    }
    return;
  }
  renderRound();
}

async function startGame() {
  const rounds = await loadRounds();
  if (!rounds.length) {
    noRoundsNote.classList.remove('hidden');
    return;
  }
  games = buildGames(rounds);
  currentIndex = 0;
  score = 0;
  showOnly(roundPanel);
  renderRound();
}

startBtn.addEventListener('click', startGame);
nextBtn.addEventListener('click', nextRound);
playAgainBtn.addEventListener('click', startGame);
guessBtns.forEach(btn => {
  btn.addEventListener('click', () => handleGuess(btn.dataset.slot));
});
EOF

echo "-- files written --"
git status --short
git add app/static/favicon.svg app/static/confetti.js app/static/style.css \
  app/templates/home.html app/templates/index.html app/templates/spot_the_fake.html \
  app/templates/spot_the_fake_video.html app/templates/spot_the_fake_image.html \
  app/static/spot_the_fake.js app/static/spot_the_fake_video.js app/static/spot_the_fake_image.js
git commit -m "Add motion/polish (confetti, progress dots, difficulty pills, panel transitions, favicon) and homepage mascot + October countdown"
git push
echo "-- done, hard-refresh your browser (Cmd+Shift+R) to see it --"