"""'Which Is Fake? (Email)' -- same pool-sampling pattern as
spot_the_fake.py (audio), for phishing emails instead of media. See that
module's docstring for the sampling rationale, app/content_pool.py for the
shared discovery logic (local folder or S3, depending on CONTENT_BACKEND),
and app/content/README.md for the shared design rationale and
content-sourcing guidance.

Content pairs are <round-id>-real.json / <round-id>-fake.json instead of
media files -- content_pool.py's real/fake pair discovery works on any file
extension, so the existing folder convention just works unmodified. Each
JSON file describes one mock email (sender, subject, body, link); the
browser fetches it directly (same as it would fetch an <img> or <video>
src) and renders it as a mock inbox message.

This module only serves a randomly-sampled slice of the content pool and
lets the browser render two emails side by side; it does not generate
phishing emails.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "email"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY

bp = Blueprint("spot_the_fake_email", __name__)


@bp.get("/spot-the-fake-email")
def spot_the_fake_email_page():
    return render_template("spot_the_fake_email.html")


@bp.get("/api/spot-the-fake-email/rounds")
def spot_the_fake_email_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry["difficulty"],
            "subject_label": entry["subject_label"],
            "real_email_url": entry["real_url"],
            "fake_email_url": entry["fake_url"],
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
