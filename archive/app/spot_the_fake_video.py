"""'Which Is Fake? (Video)' -- plays a real clip and a synthetic/deepfaked one
side by side and asks the participant to guess which is real, then reveals
the answer with a short explanation of what gave the fake away.

Content is discovered by app/content_pool.py, which abstracts over where
the media actually lives (local folder, or an S3 bucket -- see that
module's docstring and app/content/README.md for the full "how to add a
round" guide). Every request to /api/spot-the-fake-video/rounds randomly
samples a fresh subset from each difficulty tier's pool -- so the next
player in line sees a different set of clips than the player before them,
and can't just memorize the previous player's answers. The tier order
(easy, then medium, then hard) is always preserved; only which specific
pairs get used within each tier varies. The other game blueprints
(spot_the_fake_image.py, spot_the_fake_email.py) follow this same pattern.

app/content/README.md also covers content sourcing, which applies strongly
to video: face-swap/deepfake video of a real, identifiable person is a
materially higher-risk category to produce than a still image.

Deliberately stateless otherwise: no participant identity or per-visitor
progress is tracked server-side. Answer-checking happens entirely
client-side once the round data is fetched. This module only serves a
randomly-sampled slice of the content pool and lets the browser play two
clips side by side; it does not generate video deepfakes.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "video"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY

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
            "real_video_url": entry["real_url"],
            "fake_video_url": entry["fake_url"],
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
