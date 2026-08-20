"""'Which Is Fake? (Video)' -- same pool-sampling pattern as spot_the_fake.py
(audio), for short video clips instead. See that module's docstring for the
sampling rationale, app/content_pool.py for the shared discovery logic, and
app/content/README.md for the shared design rationale and content-sourcing
guidance -- which applies even more strongly to video than audio, since
face-swap/deepfake video of a real, identifiable person is a materially
higher-risk category to produce than a synthetic voice clip alone.

This module only serves a randomly-sampled slice of the content pool and
lets the browser play two clips side by side; it does not generate video
deepfakes.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "video"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY
STATIC_URL_ROOT = f"/static/content/{MODALITY}"

bp = Blueprint("spot_the_fake_video", __name__)


@bp.get("/spot-the-fake-video")
def spot_the_fake_video_page():
    return render_template("spot_the_fake_video.html")


@bp.get("/api/spot-the-fake-video/rounds")
def spot_the_fake_video_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry["difficulty"],
            "subject_label": entry["subject_label"],
            "real_video_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['real_file']}",
            "fake_video_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['fake_file']}",
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
