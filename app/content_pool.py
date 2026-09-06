"""Shared content discovery for all three "Which Is Fake?" games.

Two interchangeable backends, chosen by the CONTENT_BACKEND env var:

  local (default)   Content lives under app/static/content/<modality>/<difficulty>/
                     as plain real/fake file pairs on disk, served as normal
                     Flask static files. Zero setup -- this is what local/native
                     and mini-PC deployments use.

  s3                 Content lives in an S3 bucket under the same
                     content/<modality>/<difficulty>/ key structure. Rounds are
                     served as short-lived presigned URLs generated per request,
                     so the bucket itself stays private -- nothing is ever
                     publicly readable, and access is gated by the same
                     passcode gate that protects the rest of the site (the
                     presigned URL is only ever handed out in response to an
                     already-authenticated /api/.../rounds request). This is
                     what the AWS deployment uses once CONTENT_BACKEND=s3 is
                     set (see deploy/aws and the S3 Content Storage guide).

Either way, adding a round is the same two-file convention:

    <round-id>-real.<ext>
    <round-id>-fake.<ext>

with an optional notes.json in the same tier folder/prefix supplying a
nicer subject_label and a specific reveal_note per round-id; anything not
listed there gets a sensible auto-generated default.

    {
      "round-id": {
        "subject_label": "What the participant sees above the clips",
        "reveal_note": "Shown after they guess -- what gave the fake away"
      }
    }

Callers (the three game blueprints) only ever call pick_rounds() and don't
need to know or care which backend is active -- every entry it returns
already has a ready-to-use real_url / fake_url.

See app/content/README.md for the full guide.
"""

from __future__ import annotations

import json
import os
import random
import re
import time
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
    "email": "Check the sender's actual address, where any link really goes, and whether urgency is being used to rush you -- these are the tells that separate a phishing email from the real thing.",
}

CONTENT_BACKEND = os.environ.get("CONTENT_BACKEND", "local").strip().lower()


def _humanize(round_id: str) -> str:
    words = re.sub(r"[-_]+", " ", round_id).strip()
    return (words[:1].upper() + words[1:]) if words else "Round"


def pick_rounds(content_root: Path, modality: str) -> list[dict]:
    """Sample SELECT_COUNTS rounds per tier, tier order preserved.

    content_root is only used by the local backend (ignored for s3, which
    has no notion of a local path -- see CONTENT_S3_BUCKET/CONTENT_S3_PREFIX
    below instead).
    """
    if CONTENT_BACKEND == "s3":
        return _pick_rounds_s3(modality)
    return _pick_rounds_local(content_root, modality)


# ------------------------------------------------------------- local ---

def _load_notes_local(tier_dir: Path) -> dict:
    notes_path = tier_dir / "notes.json"
    if not notes_path.exists():
        return {}
    try:
        return json.loads(notes_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def discover_tier(tier_dir: Path, modality: str) -> list[dict]:
    """Scan one local difficulty folder for <id>-real.* / <id>-fake.* pairs.

    Incomplete pairs (only a real or only a fake file present) are silently
    skipped rather than raising -- a content-loading session is often
    mid-way through adding a pair, and a half-added round shouldn't break
    the whole tier.
    """
    if not tier_dir.exists():
        return []

    notes = _load_notes_local(tier_dir)
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


def _pick_rounds_local(content_root: Path, modality: str) -> list[dict]:
    selected: list[dict] = []
    for tier, count in SELECT_COUNTS:
        pool = discover_tier(content_root / tier, modality)
        sample = random.sample(pool, min(count, len(pool)))
        for entry in sample:
            selected.append({
                "id": entry["id"],
                "difficulty": tier,
                "subject_label": entry["subject_label"],
                "reveal_note": entry["reveal_note"],
                "real_url": f"/static/content/{modality}/{tier}/{entry['real_file']}",
                "fake_url": f"/static/content/{modality}/{tier}/{entry['fake_file']}",
            })
    return selected


# ---------------------------------------------------------------- s3 ---

CONTENT_S3_BUCKET = os.environ.get("CONTENT_S3_BUCKET", "")
CONTENT_S3_PREFIX = os.environ.get("CONTENT_S3_PREFIX", "content").strip("/")
CONTENT_S3_URL_TTL = int(os.environ.get("CONTENT_S3_URL_TTL", "900"))  # seconds

# Listing a tier's objects on every single request would add real latency
# for no benefit -- content doesn't change mid-event. Cache each tier's
# pairs for a short window instead, so a fresh upload shows up within about
# a minute without needing an app restart, while normal traffic hits the
# cache.
_S3_LIST_CACHE_TTL = 60  # seconds
_s3_client = None
_s3_list_cache: dict[tuple[str, str], tuple[float, list[dict]]] = {}


def _get_s3_client():
    global _s3_client
    if _s3_client is None:
        import boto3  # imported lazily -- only needed when CONTENT_BACKEND=s3
        _s3_client = boto3.client("s3")
    return _s3_client


def _load_notes_s3(client, tier_prefix: str) -> dict:
    try:
        obj = client.get_object(Bucket=CONTENT_S3_BUCKET, Key=f"{tier_prefix}/notes.json")
    except client.exceptions.NoSuchKey:
        return {}
    except Exception:
        # Any other error (bad permissions, transient network issue) --
        # fall back to auto-generated labels rather than 500ing the game.
        return {}
    try:
        return json.loads(obj["Body"].read().decode("utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def discover_tier_s3(modality: str, tier: str) -> list[dict]:
    cache_key = (modality, tier)
    cached = _s3_list_cache.get(cache_key)
    if cached and time.time() - cached[0] < _S3_LIST_CACHE_TTL:
        return cached[1]

    client = _get_s3_client()
    tier_prefix = f"{CONTENT_S3_PREFIX}/{modality}/{tier}"

    found: dict[str, dict[str, str]] = {}
    paginator = client.get_paginator("list_objects_v2")
    for page in paginator.paginate(Bucket=CONTENT_S3_BUCKET, Prefix=tier_prefix + "/"):
        for obj in page.get("Contents", []):
            filename = obj["Key"].rsplit("/", 1)[-1]
            match = PAIR_RE.match(filename)
            if not match:
                continue
            found.setdefault(match["id"], {})[match["kind"]] = obj["Key"]

    notes = _load_notes_s3(client, tier_prefix)
    pairs = []
    for round_id, files in found.items():
        if "real" not in files or "fake" not in files:
            continue
        meta = notes.get(round_id, {})
        pairs.append({
            "id": round_id,
            "subject_label": meta.get("subject_label", _humanize(round_id)),
            "reveal_note": meta.get("reveal_note", DEFAULT_REVEAL_NOTES[modality]),
            "real_key": files["real"],
            "fake_key": files["fake"],
        })

    _s3_list_cache[cache_key] = (time.time(), pairs)
    return pairs


def _presign(client, key: str) -> str:
    return client.generate_presigned_url(
        "get_object",
        Params={"Bucket": CONTENT_S3_BUCKET, "Key": key},
        ExpiresIn=CONTENT_S3_URL_TTL,
    )


def _pick_rounds_s3(modality: str) -> list[dict]:
    if not CONTENT_S3_BUCKET:
        raise RuntimeError(
            "CONTENT_BACKEND=s3 but CONTENT_S3_BUCKET is not set -- check deploy/aws/.env"
        )
    client = _get_s3_client()
    selected: list[dict] = []
    for tier, count in SELECT_COUNTS:
        pool = discover_tier_s3(modality, tier)
        sample = random.sample(pool, min(count, len(pool)))
        for entry in sample:
            selected.append({
                "id": entry["id"],
                "difficulty": tier,
                "subject_label": entry["subject_label"],
                "reveal_note": entry["reveal_note"],
                "real_url": _presign(client, entry["real_key"]),
                "fake_url": _presign(client, entry["fake_key"]),
            })
    return selected
