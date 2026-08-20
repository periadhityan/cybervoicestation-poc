"""Shared folder-based content discovery for all three "Which Is Fake?"
games.

Content lives at app/static/content/<modality>/<difficulty>/ as plain
real/fake file pairs -- no manifest JSON to hand-edit. To add a round: drop
two files in the right tier folder, named:

    <round-id>-real.<ext>
    <round-id>-fake.<ext>

That's it -- the pair is picked up automatically on the next request. An
optional notes.json in the same folder can supply a nicer subject_label and
a specific reveal_note per round-id; anything not listed there gets a
sensible auto-generated default, so dropping files in with no notes.json at
all still works immediately.

    {
      "round-id": {
        "subject_label": "What the participant sees above the clips",
        "reveal_note": "Shown after they guess -- what gave the fake away"
      }
    }

See app/content/README.md for the full guide.
"""

from __future__ import annotations

import json
import random
import re
from pathlib import Path

PAIR_RE = re.compile(r"^(?P<id>.+)-(?P<kind>real|fake)\.(?P<ext>[A-Za-z0-9]+)$")

# How many rounds to sample from each tier's pool per game, in play order.
# The pools need at least this many entries per tier for real variety --
# more entries = less repetition between players.
SELECT_COUNTS = [("easy", 4), ("medium", 2), ("hard", 1)]

DEFAULT_REVEAL_NOTES = {
    "audio": "Listen again -- pacing, tone, or background noise often gives a synthetic clip away.",
    "video": "Watch again -- lighting, blinking, or lip-sync often gives a synthetic clip away.",
    "image": "Look again -- lighting, hands, or background detail often gives a synthetic image away.",
}


def _humanize(round_id: str) -> str:
    words = re.sub(r"[-_]+", " ", round_id).strip()
    return (words[:1].upper() + words[1:]) if words else "Round"


def _load_notes(tier_dir: Path) -> dict:
    notes_path = tier_dir / "notes.json"
    if not notes_path.exists():
        return {}
    try:
        return json.loads(notes_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def discover_tier(tier_dir: Path, modality: str) -> list[dict]:
    """Scan one difficulty folder for <id>-real.* / <id>-fake.* pairs.

    Incomplete pairs (only a real or only a fake file present) are silently
    skipped rather than raising -- a content-loading session is often
    mid-way through adding a pair, and a half-added round shouldn't break
    the whole tier.
    """
    if not tier_dir.exists():
        return []

    notes = _load_notes(tier_dir)
    found: dict[str, dict[str, str]] = {}
    for f in sorted(tier_dir.iterdir()):
        if not f.is_file():
            continue
        match = PAIR_RE.match(f.name)
        if not match:
            continue
        found.setdefault(match["id"], {})[match["kind"]] = f.name

    pairs = []
    for round_id, files in found.items():
        if "real" not in files or "fake" not in files:
            continue
        meta = notes.get(round_id, {})
        pairs.append({
            "id": round_id,
            "subject_label": meta.get("subject_label", _humanize(round_id)),
            "reveal_note": meta.get("reveal_note", DEFAULT_REVEAL_NOTES[modality]),
            "real_file": files["real"],
            "fake_file": files["fake"],
        })
    return pairs


def pick_rounds(content_root: Path, modality: str) -> list[dict]:
    """Sample SELECT_COUNTS rounds per tier from content_root, tier order preserved."""
    selected: list[dict] = []
    for tier, count in SELECT_COUNTS:
        pool = discover_tier(content_root / tier, modality)
        sample = random.sample(pool, min(count, len(pool)))
        selected.extend({**entry, "difficulty": tier} for entry in sample)
    return selected
