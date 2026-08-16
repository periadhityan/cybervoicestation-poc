#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

cat > app/app.py <<'EOF'
from __future__ import annotations

import atexit
import os
import random
import subprocess
import uuid
from pathlib import Path
from urllib.parse import quote

from flask import Flask, Response, jsonify, render_template, request

from cleanup import SessionCleaner
from spot_the_fake import bp as spot_the_fake_bp
from spot_the_fake_image import bp as spot_the_fake_image_bp
from spot_the_fake_video import bp as spot_the_fake_video_bp
from voice_engine import VoiceEngine


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SESSION_ROOT = Path(
    os.environ.get("CYBERVOICE_SESSION_ROOT", PROJECT_ROOT / "runtime" / "sessions")
).resolve()

MAX_UPLOAD_BYTES = 12 * 1024 * 1024

# Keep the demonstration text to a small, fixed, pre-approved pool of
# realistic social-engineering scenarios -- never free text the visitor
# supplies. That keeps this station a training demo, not a general-purpose
# voice-impersonation tool. One scenario is picked at random per session so
# repeat visitors (and people queued behind them) hear something different
# each time. Every scenario closes with a verification reminder, spoken in
# the participant's own cloned voice, to reinforce the lesson.
DEMO_TEXTS = (
    "Hi, it's me. I'm stuck in back-to-back meetings today. I need you to "
    "process an urgent wire transfer for a new vendor before end of day -- "
    "please don't loop in finance on this one. If you ever get a request "
    "like this, stop and verify it through a second channel first.",

    "Hi, this is IT support. We detected unusual sign-in activity and need "
    "to verify it's really you. Can you read me the six-digit code just "
    "texted to your phone? We'll lock this down right away. Remember: real "
    "IT staff will never ask for your one-time code over the phone.",

    "Hey, it's me -- sorry for the random text. I'm in back-to-back "
    "meetings and need a quick favor. Can you grab four hundred dollars in "
    "gift cards for a client gift and send me the codes? I'll pay you back "
    "today. Requests like this should always be confirmed by phone, never "
    "by text alone.",

    "It's me, please don't panic. I've been in an accident and need help "
    "covering an emergency payment right now. Can you send money by wire "
    "transfer to this account before the office closes? Please call me "
    "back on my usual number first -- a real emergency should never "
    "pressure you to skip that.",

    "Hi, quick note about our banking details -- we've switched providers "
    "and updated the account number for upcoming invoices. Please make "
    "sure the next payment goes to the new account I'm sending over. Any "
    "request to change payment details should be verified by phone with a "
    "known contact first.",

    "Hi, this is about my paycheck -- I recently switched banks and need "
    "to update my direct deposit before the next payroll run. Can you "
    "update it to the new account I'm about to send you? Requests to "
    "change payroll details should always go through the official portal, "
    "never a phone call alone.",

    "This is an automated security alert. Suspicious activity was detected "
    "on your account and it will be locked in ten minutes unless you "
    "verify your identity. Please call the number in this message and be "
    "ready to confirm your password. Real security teams will never ask "
    "you to read your password aloud.",
)

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_UPLOAD_BYTES
app.config["JSON_SORT_KEYS"] = False
app.register_blueprint(spot_the_fake_bp)
app.register_blueprint(spot_the_fake_video_bp)
app.register_blueprint(spot_the_fake_image_bp)

cleaner = SessionCleaner(SESSION_ROOT)

# Remove abandoned session folders left by an interrupted previous run.
cleaner.clear_stale_sessions(max_age_seconds=0)

# Model loading can take time. Do it once when the service starts.
engine = VoiceEngine(PROJECT_ROOT)


def normalise_audio(input_path: Path, output_path: Path) -> None:
    """Convert browser recording to a predictable mono PCM WAV."""
    command = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(input_path),
        "-ac",
        "1",
        "-ar",
        "16000",
        "-c:a",
        "pcm_s16le",
        str(output_path),
    ]

    subprocess.run(command, check=True, timeout=30)


@app.get("/")
def home():
    return render_template("home.html")


@app.get("/hear-yourself-hacked")
def index():
    return render_template("index.html", device=engine.device)


@app.get("/health")
def health():
    return jsonify(
        status="ok",
        device=engine.device,
        session_entries=sum(1 for _ in SESSION_ROOT.iterdir()),
    )


@app.post("/api/clone")
def clone_voice():
    consent = request.form.get("consent", "").lower()
    if consent != "yes":
        return jsonify(error="Consent is required before recording."), 400

    if "audio" not in request.files:
        return jsonify(error="No audio recording was supplied."), 400

    session_id = uuid.uuid4().hex
    session_dir = SESSION_ROOT / session_id
    session_dir.mkdir(parents=True, exist_ok=False)

    uploaded = session_dir / "reference.webm"
    reference_wav = session_dir / "reference.wav"

    try:
        request.files["audio"].save(uploaded)

        if uploaded.stat().st_size == 0:
            raise ValueError("The microphone recording was empty")

        normalise_audio(uploaded, reference_wav)

        demo_text = random.choice(DEMO_TEXTS)
        output_path = engine.clone(
            reference_wav=reference_wav,
            text=demo_text,
            session_dir=session_dir,
        )

        # Critical privacy design:
        # copy generated audio into process memory BEFORE deleting the entire
        # participant session directory.
        audio_bytes = output_path.read_bytes()

        if not audio_bytes:
            raise RuntimeError("Generated output was empty")

        # Delete participant recording, processed files, base TTS audio,
        # generated clone, and anything else created in the session workspace.
        cleaner.delete_session(session_dir)

        response = Response(audio_bytes, mimetype="audio/wav")
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
        response.headers["X-Session-Cleaned"] = "true"
        response.headers["X-Demo-Text"] = quote(demo_text)
        return response

    except subprocess.TimeoutExpired:
        return jsonify(error="Audio conversion timed out."), 500
    except Exception as exc:
        app.logger.exception("Voice-cloning session failed")
        return jsonify(error=f"The demo could not complete: {type(exc).__name__}"), 500
    finally:
        # Guarantees cleanup even if upload, FFmpeg, model inference or response
        # preparation fails. If success path already removed it, this is a no-op.
        if session_dir.exists():
            try:
                cleaner.delete_session(session_dir)
            except Exception:
                app.logger.exception("Emergency session cleanup failed")


@app.post("/api/clear-all")
def clear_all():
    """Operator emergency wipe function for all current session files."""
    removed = cleaner.clear_all_sessions()
    return jsonify(status="cleared", entries_removed=removed)


def shutdown_cleanup():
    try:
        cleaner.clear_all_sessions()
    except Exception:
        pass


atexit.register(shutdown_cleanup)


if __name__ == "__main__":
    # CYBERVOICE_BIND defaults to loopback-only for native/local runs.
    # Container deployment sets CYBERVOICE_BIND=0.0.0.0 (see deploy/compose.yaml);
    # the host still only publishes that port to its own loopback interface.
    bind_host = os.environ.get("CYBERVOICE_BIND", "127.0.0.1")
    app.run(host=bind_host, port=8080, debug=False, threaded=False)
EOF

cat > app/static/app.js <<'EOF'
const consent = document.getElementById('consent');
const startBtn = document.getElementById('startBtn');
const recordBtn = document.getElementById('recordBtn');
const stopBtn = document.getElementById('stopBtn');
const finishBtn = document.getElementById('finishBtn');
const errorResetBtn = document.getElementById('errorResetBtn');

const intro = document.getElementById('intro');
const recordingPanel = document.getElementById('recordingPanel');
const processingPanel = document.getElementById('processingPanel');
const resultPanel = document.getElementById('resultPanel');
const errorPanel = document.getElementById('errorPanel');
const errorText = document.getElementById('errorText');
const resultAudio = document.getElementById('resultAudio');
const demoTextCaption = document.getElementById('demoTextCaption');
const timer = document.getElementById('timer');

let recorder = null;
let stream = null;
let chunks = [];
let timerHandle = null;
let startTime = null;
let currentObjectUrl = null;

function showOnly(panel) {
  [intro, recordingPanel, processingPanel, resultPanel, errorPanel]
    .forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function revokeResultUrl() {
  if (currentObjectUrl) {
    URL.revokeObjectURL(currentObjectUrl);
    currentObjectUrl = null;
  }
  resultAudio.removeAttribute('src');
  resultAudio.load();
}

function stopMicrophoneTracks() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
    stream = null;
  }
}

function resetState() {
  stopMicrophoneTracks();
  revokeResultUrl();
  chunks = [];
  recorder = null;
  clearInterval(timerHandle);
  timerHandle = null;
  timer.textContent = '00:00';
  demoTextCaption.textContent = '';
  consent.checked = false;
  startBtn.disabled = true;
  recordBtn.disabled = false;
  stopBtn.disabled = true;
  showOnly(intro);
}

consent.addEventListener('change', () => {
  startBtn.disabled = !consent.checked;
});

startBtn.addEventListener('click', () => {
  if (!consent.checked) return;
  showOnly(recordingPanel);
});

recordBtn.addEventListener('click', async () => {
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true
      }
    });

    chunks = [];
    recorder = new MediaRecorder(stream);

    recorder.ondataavailable = event => {
      if (event.data && event.data.size > 0) chunks.push(event.data);
    };

    recorder.start();
    startTime = Date.now();
    recordBtn.disabled = true;
    stopBtn.disabled = false;

    timerHandle = setInterval(() => {
      const seconds = Math.floor((Date.now() - startTime) / 1000);
      const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
      const ss = String(seconds % 60).padStart(2, '0');
      timer.textContent = `${mm}:${ss}`;

      // Hard-stop at 25 seconds. The station does not need long recordings.
      if (seconds >= 25 && recorder && recorder.state === 'recording') {
        stopBtn.click();
      }
    }, 250);
  } catch (err) {
    errorText.textContent = `Microphone access failed: ${err.message}`;
    showOnly(errorPanel);
  }
});

stopBtn.addEventListener('click', async () => {
  if (!recorder || recorder.state !== 'recording') return;

  stopBtn.disabled = true;
  clearInterval(timerHandle);

  const stopped = new Promise(resolve => {
    recorder.onstop = resolve;
  });

  recorder.stop();
  await stopped;
  stopMicrophoneTracks();

  const mimeType = recorder.mimeType || 'audio/webm';
  const recording = new Blob(chunks, { type: mimeType });

  if (recording.size < 1000) {
    errorText.textContent = 'The recording was too short or empty. Please try again.';
    showOnly(errorPanel);
    return;
  }

  showOnly(processingPanel);

  const form = new FormData();
  form.append('consent', 'yes');
  form.append('audio', recording, 'reference.webm');

  try {
    const response = await fetch('/api/clone', {
      method: 'POST',
      body: form,
      cache: 'no-store'
    });

    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      throw new Error(body.error || `Server returned HTTP ${response.status}`);
    }

    const demoTextHeader = response.headers.get('X-Demo-Text');
    const resultBlob = await response.blob();

    // Browser-side result exists only as an object URL for playback.
    currentObjectUrl = URL.createObjectURL(resultBlob);
    resultAudio.src = currentObjectUrl;
    demoTextCaption.textContent = demoTextHeader ? `"${decodeURIComponent(demoTextHeader)}"` : '';
    showOnly(resultPanel);
    resultAudio.play().catch(() => {});
  } catch (err) {
    errorText.textContent = err.message;
    showOnly(errorPanel);
  } finally {
    // Discard the original browser recording chunks as soon as the request ends.
    chunks = [];
    recorder = null;
  }
});

finishBtn.addEventListener('click', async () => {
  revokeResultUrl();

  // Defence in depth: ask backend to clear any abandoned session material.
  try {
    await fetch('/api/clear-all', {
      method: 'POST',
      cache: 'no-store'
    });
  } catch (_) {
    // Normal successful sessions are already deleted server-side.
  }

  resetState();
});

errorResetBtn.addEventListener('click', async () => {
  try {
    await fetch('/api/clear-all', { method: 'POST', cache: 'no-store' });
  } catch (_) {}
  resetState();
});

window.addEventListener('beforeunload', () => {
  stopMicrophoneTracks();
  revokeResultUrl();
});
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
      <p class="demo-caption" id="demoTextCaption"></p>

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

python3 - <<'PYEOF'
path = "app/static/style.css"
with open(path, "r", encoding="utf-8") as fh:
    css = fh.read()

marker = "audio { width: 100%; margin: 24px 0; border-radius: 12px; }\n"
addition = """
.demo-caption {
  margin: 4px 0 24px;
  padding: 14px 18px;
  border-left: 3px solid var(--accent-pink);
  background: rgba(244, 114, 182, 0.08);
  border-radius: 0 12px 12px 0;
  font-style: italic;
  opacity: .9;
  font-size: 15px;
  line-height: 1.5;
}
"""

if ".demo-caption {" in css:
    print("style.css already has .demo-caption -- leaving it untouched")
else:
    if marker not in css:
        raise SystemExit("Could not find the audio{} rule in style.css -- aborting, please check app/static/style.css by hand.")
    css = css.replace(marker, marker + addition, 1)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(css)
    print("Added .demo-caption rule to style.css")
PYEOF

echo "-- files written --"
git status --short
git add app/app.py app/static/app.js app/templates/index.html app/static/style.css
git commit -m "Add 7 varied social-engineering demo scenarios for the voice-cloning station, picked at random per session, with a text caption on the result"
git push
echo "-- done -- restart the Flask process (native or docker compose restart) to pick up app.py changes, then hard-refresh --"