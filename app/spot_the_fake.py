"""'Which Is Fake?' -- a lightweight second Cyber Room station.

Plays back a real recording and a synthetic/deepfaked one side by side and
asks the participant to guess which is real, then reveals the answer with a
short explanation of what gave the fake away.

Deliberately stateless: no participant identity or per-visitor progress is
tracked server-side. The manifest (app/content/spot_the_fake_manifest.json)
is the only content source; see app/content/README.md for how to fill it in
with real rounds. Answer-checking happens entirely client-side once the
round data is fetched, matching this app's existing minimal-server-state
design (see app/cleanup.py's philosophy for the voice-cloning station).
"""

from __future__ import annotations

import json
from pathlib import Path

from flask import Blueprint, jsonify, render_template

CONTENT_DIR = Path(__file__).resolve().parent / "content"
MANIFEST_PATH = CONTENT_DIR / "spot_the_fake_manifest.json"
STATIC_SUBDIR = "spot_the_fake"

bp = Blueprint("spot_the_fake", __name__)


def _load_rounds() -> list[dict]:
    if not MANIFEST_PATH.exists():
        return []
    with MANIFEST_PATH.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    return data.get("rounds", [])


@bp.get("/spot-the-fake")
def spot_the_fake_page():
    return render_template("spot_the_fake.html")


@bp.get("/api/spot-the-fake/rounds")
def spot_the_fake_rounds():
    rounds = _load_rounds()
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry.get("difficulty", ""),
            "subject_label": entry.get("subject_label", "Unknown"),
            "real_audio_url": f"/static/{STATIC_SUBDIR}/{entry['real_audio']}",
            "fake_audio_url": f"/static/{STATIC_SUBDIR}/{entry['fake_audio']}",
            "reveal_note": entry.get("reveal_note", ""),
        }
        for entry in rounds
    ]
    return jsonify(rounds=payload)
