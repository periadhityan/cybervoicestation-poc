from __future__ import annotations

import atexit
import os
import subprocess
import uuid
from pathlib import Path

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

# Keep the demonstration text fixed. This avoids turning the station into a
# general-purpose voice-impersonation tool.
DEMO_TEXT = (
    "Hi, it's me. I'm tied up in another meeting. "
    "I need you to approve this request urgently. "
    "Please verify unusual requests using a trusted channel before acting."
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

        output_path = engine.clone(
            reference_wav=reference_wav,
            text=DEMO_TEXT,
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
