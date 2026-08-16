"""'Which Is Fake? (Picture)' -- same pool-sampling pattern as
spot_the_fake.py (audio), for still images instead. See that module's
docstring for the sampling rationale, and app/content/README.md for the
shared design rationale and content-sourcing guidance.

This module only serves a randomly-sampled slice of a content manifest and
lets the browser display two images side by side; it does not generate
deepfake images.
"""

from __future__ import annotations

import json
import random
from pathlib import Path

from flask import Blueprint, jsonify, render_template

CONTENT_DIR = Path(__file__).resolve().parent / "content"
MANIFEST_PATH = CONTENT_DIR / "spot_the_fake_image_manifest.json"
STATIC_SUBDIR = "spot_the_fake/image"

SELECT_COUNTS = [("easy", 4), ("medium", 2), ("hard", 1)]

bp = Blueprint("spot_the_fake_image", __name__)


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


@bp.get("/spot-the-fake-image")
def spot_the_fake_image_page():
    return render_template("spot_the_fake_image.html")


@bp.get("/api/spot-the-fake-image/rounds")
def spot_the_fake_image_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry.get("difficulty", ""),
            "subject_label": entry.get("subject_label", "Unknown"),
            "real_image_url": f"/static/{STATIC_SUBDIR}/{entry['real_image']}",
            "fake_image_url": f"/static/{STATIC_SUBDIR}/{entry['fake_image']}",
            "reveal_note": entry.get("reveal_note", ""),
        }
        for entry in _pick_rounds()
    ]
    return jsonify(rounds=payload)
