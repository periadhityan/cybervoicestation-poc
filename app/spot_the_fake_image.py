"""'Which Is Fake? (Picture)' -- same pattern as spot_the_fake.py (audio),
for still images instead. See that module's docstring and
app/content/README.md for the shared design rationale and content-sourcing
guidance.

This module only serves a content manifest and lets the browser display two
images side by side; it does not generate deepfake images.
"""

from __future__ import annotations

import json
from pathlib import Path

from flask import Blueprint, jsonify, render_template

CONTENT_DIR = Path(__file__).resolve().parent / "content"
MANIFEST_PATH = CONTENT_DIR / "spot_the_fake_image_manifest.json"
STATIC_SUBDIR = "spot_the_fake/image"

bp = Blueprint("spot_the_fake_image", __name__)


def _load_rounds() -> list[dict]:
    if not MANIFEST_PATH.exists():
        return []
    with MANIFEST_PATH.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    return data.get("rounds", [])


@bp.get("/spot-the-fake-image")
def spot_the_fake_image_page():
    return render_template("spot_the_fake_image.html")


@bp.get("/api/spot-the-fake-image/rounds")
def spot_the_fake_image_rounds():
    rounds = _load_rounds()
    payload = [
        {
            "id": entry["id"],
            "subject_label": entry.get("subject_label", "Unknown"),
            "real_image_url": f"/static/{STATIC_SUBDIR}/{entry['real_image']}",
            "fake_image_url": f"/static/{STATIC_SUBDIR}/{entry['fake_image']}",
            "reveal_note": entry.get("reveal_note", ""),
        }
        for entry in rounds
    ]
    return jsonify(rounds=payload)
