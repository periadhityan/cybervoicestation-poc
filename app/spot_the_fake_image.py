"""'Which Is Fake? (Picture)' -- same pool-sampling pattern as
spot_the_fake.py (audio), for still images instead. See that module's
docstring for the sampling rationale, app/content_pool.py for the shared
discovery logic, and app/content/README.md for the shared design rationale
and content-sourcing guidance.

This module only serves a randomly-sampled slice of the content pool and
lets the browser display two images side by side; it does not generate
deepfake images.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "image"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY
STATIC_URL_ROOT = f"/static/content/{MODALITY}"

bp = Blueprint("spot_the_fake_image", __name__)


@bp.get("/spot-the-fake-image")
def spot_the_fake_image_page():
    return render_template("spot_the_fake_image.html")


@bp.get("/api/spot-the-fake-image/rounds")
def spot_the_fake_image_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry["difficulty"],
            "subject_label": entry["subject_label"],
            "real_image_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['real_file']}",
            "fake_image_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['fake_file']}",
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
