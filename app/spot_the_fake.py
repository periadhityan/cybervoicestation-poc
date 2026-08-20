"""'Which Is Fake?' -- a lightweight second Cyber Room station.

Plays back a real recording and a synthetic/deepfaked one side by side and
asks the participant to guess which is real, then reveals the answer with a
short explanation of what gave the fake away.

Content lives as plain files under app/static/content/audio/<difficulty>/ --
no manifest JSON to hand-edit. See app/content_pool.py for the discovery
logic and app/content/README.md for the full "how to add a round" guide.
Every request to /api/spot-the-fake/rounds randomly samples a fresh subset
from each difficulty tier's pool -- so the next player in line sees a
different set of clips than the player before them, and can't just memorize
the previous player's answers. The tier order (easy, then medium, then
hard) is always preserved; only which specific pairs get used within each
tier varies.

See scripts/generate_placeholder_content.py for how the shipped placeholder
pools were generated.

Deliberately stateless otherwise: no participant identity or per-visitor
progress is tracked server-side. Answer-checking happens entirely
client-side once the round data is fetched.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "audio"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY
STATIC_URL_ROOT = f"/static/content/{MODALITY}"

bp = Blueprint("spot_the_fake", __name__)


@bp.get("/spot-the-fake")
def spot_the_fake_page():
    return render_template("spot_the_fake.html")


@bp.get("/api/spot-the-fake/rounds")
def spot_the_fake_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry["difficulty"],
            "subject_label": entry["subject_label"],
            "real_audio_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['real_file']}",
            "fake_audio_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['fake_file']}",
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
