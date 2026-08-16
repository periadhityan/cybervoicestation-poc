"""'Which Is Fake? (Video)' -- same pattern as spot_the_fake.py (audio), for
short video clips instead. See that module's docstring and
app/content/README.md for the shared design rationale and content-sourcing
guidance -- which applies even more strongly to video than audio, since
face-swap/deepfake video of a real, identifiable person is a materially
higher-risk category to produce than voice cloning alone.

This module only serves a content manifest and lets the browser play two
clips side by side; it does not generate video deepfakes.
"""

from __future__ import annotations

import json
from pathlib import Path

from flask import Blueprint, jsonify, render_template

CONTENT_DIR = Path(__file__).resolve().parent / "content"
MANIFEST_PATH = CONTENT_DIR / "spot_the_fake_video_manifest.json"
STATIC_SUBDIR = "spot_the_fake/video"

bp = Blueprint("spot_the_fake_video", __name__)


def _load_rounds() -> list[dict]:
    if not MANIFEST_PATH.exists():
        return []
    with MANIFEST_PATH.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    return data.get("rounds", [])


@bp.get("/spot-the-fake-video")
def spot_the_fake_video_page():
    return render_template("spot_the_fake_video.html")


@bp.get("/api/spot-the-fake-video/rounds")
def spot_the_fake_video_rounds():
    rounds = _load_rounds()
    payload = [
        {
            "id": entry["id"],
            "subject_label": entry.get("subject_label", "Unknown"),
            "real_video_url": f"/static/{STATIC_SUBDIR}/{entry['real_video']}",
            "fake_video_url": f"/static/{STATIC_SUBDIR}/{entry['fake_video']}",
            "reveal_note": entry.get("reveal_note", ""),
        }
        for entry in rounds
    ]
    return jsonify(rounds=payload)
