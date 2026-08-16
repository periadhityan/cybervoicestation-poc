"""'Which Is Fake?' -- a lightweight second Cyber Room station.

Plays back a real recording and a synthetic/deepfaked one side by side and
asks the participant to guess which is real, then reveals the answer with a
short explanation of what gave the fake away.

The manifest (app/content/spot_the_fake_manifest.json) holds a POOL of
candidate pairs per difficulty tier (easy/medium/hard), not a fixed list.
Every request to /api/spot-the-fake/rounds randomly samples a fresh subset
from each pool -- so the next player in line sees a different set of clips
than the player before them, and can't just memorize the previous player's
answers. The tier order (easy, then medium, then hard) is always preserved;
only which specific pairs get used within each tier varies.

See scripts/generate_placeholder_content.py for how the shipped placeholder
pools were generated, and app/content/README.md for how to fill the pools
in with real content.

Deliberately stateless otherwise: no participant identity or per-visitor
progress is tracked server-side. Answer-checking happens entirely
client-side once the round data is fetched, matching this app's existing
minimal-server-state design (see app/cleanup.py's philosophy for the
voice-cloning station).
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from flask import Blueprint, jsonify, render_template

CONTENT_DIR = Path(__file__).resolve().parent / "content"
MANIFEST_PATH = CONTENT_DIR / "spot_the_fake_manifest.json"
STATIC_SUBDIR = "spot_the_fake"

# How many pairs to sample from each tier's pool per game, in play order.
SELECT_COUNTS = [("easy", 4), ("medium", 2), ("hard", 1)]

bp = Blueprint("spot_the_fake", __name__)


def _load_pools() -> dict[str, list[dict]]:
    if not MANIFEST_PATH.exists():
        return {}
    with MANIFEST_PATH.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def _pick_rounds() -> list[dict]:
    pools = _load_pools()
    selected: list[dict] = []
    for tier, count in SELECT_COUNTS:
        pool = pools.get(tier, [])
        selected.extend(random.sample(pool, min(count, len(pool))))
    return selected


@bp.get("/spot-the-fake")
def spot_the_fake_page():
    return render_template("spot_the_fake.html")


@bp.get("/api/spot-the-fake/rounds")
def spot_the_fake_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry.get("difficulty", ""),
            "subject_label": entry.get("subject_label", "Unknown"),
            "real_audio_url": f"/static/{STATIC_SUBDIR}/{entry['real_audio']}",
            "fake_audio_url": f"/static/{STATIC_SUBDIR}/{entry['fake_audio']}",
            "reveal_note": entry.get("reveal_note", ""),
        }
        for entry in _pick_rounds()
    ]
    return jsonify(rounds=payload)
