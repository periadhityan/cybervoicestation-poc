#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

echo "-- removing old JSON-manifest content system --"
git rm -f --ignore-unmatch \
  app/content/spot_the_fake_manifest.json \
  app/content/spot_the_fake_video_manifest.json \
  app/content/spot_the_fake_image_manifest.json

git rm -rf --ignore-unmatch app/static/spot_the_fake
rm -rf app/static/spot_the_fake

echo "-- writing app/content_pool.py --"
cat > app/content_pool.py <<'DELIVER_EOF'
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
DELIVER_EOF

echo "-- writing app/spot_the_fake.py --"
cat > app/spot_the_fake.py <<'DELIVER_EOF'
"""'Which Is Fake?' -- a lightweight second Cyber Room station.

Plays back a real recording and a synthetic/deepfaked one side by side and
asks the participant to guess which is real, then reveals the answer with a
short explanation of what gave the fake away.

Content lives as plain files under app/static/content/audio/<difficulty>/ --
no manifest JSON to hand-edit. See app/content_pool.py for the discovery
logic and app/content/README.md for the full "how to add a round" guide.
Every request to /api/spot-the-fake/rounds randomly samples a fresh subset
from each difficulty tier's pool -- so the next player in line sees a
different set of clips than the player before them, and can't just memorize
the previous player's answers. The tier order (easy, then medium, then
hard) is always preserved; only which specific pairs get used within each
tier varies.

See scripts/generate_placeholder_content.py for how the shipped placeholder
pools were generated.

Deliberately stateless otherwise: no participant identity or per-visitor
progress is tracked server-side. Answer-checking happens entirely
client-side once the round data is fetched.
"""

from __future__ import annotations

from pathlib import Path

from flask import Blueprint, jsonify, render_template

from content_pool import pick_rounds

MODALITY = "audio"
CONTENT_ROOT = Path(__file__).resolve().parent / "static" / "content" / MODALITY
STATIC_URL_ROOT = f"/static/content/{MODALITY}"

bp = Blueprint("spot_the_fake", __name__)


@bp.get("/spot-the-fake")
def spot_the_fake_page():
    return render_template("spot_the_fake.html")


@bp.get("/api/spot-the-fake/rounds")
def spot_the_fake_rounds():
    payload = [
        {
            "id": entry["id"],
            "difficulty": entry["difficulty"],
            "subject_label": entry["subject_label"],
            "real_audio_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['real_file']}",
            "fake_audio_url": f"{STATIC_URL_ROOT}/{entry['difficulty']}/{entry['fake_file']}",
            "reveal_note": entry["reveal_note"],
        }
        for entry in pick_rounds(CONTENT_ROOT, MODALITY)
    ]
    return jsonify(rounds=payload)
DELIVER_EOF

echo "-- writing app/spot_the_fake_image.py --"
cat > app/spot_the_fake_image.py <<'DELIVER_EOF'
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
DELIVER_EOF

echo "-- writing app/spot_the_fake_video.py --"
cat > app/spot_the_fake_video.py <<'DELIVER_EOF'
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
DELIVER_EOF

echo "-- writing scripts/generate_placeholder_content.py --"
cat > scripts/generate_placeholder_content.py <<'DELIVER_EOF'
"""Generate placeholder content POOLS for all three Which Is Fake? games.

Each difficulty tier (easy/medium/hard) gets a pool of several candidate
real/fake pairs, not just one. The Flask routes randomly sample a fresh
subset from each pool on every request (see app/spot_the_fake*.py via
app/content_pool.py), so two consecutive players never see the exact same
set of clips in the exact same order -- someone waiting in line can't
shoulder-surf the answers from the person ahead of them.

Content lives as plain files, discovered by folder convention -- no
manifest JSON. This script writes into:

    app/static/content/<audio|video|image>/<easy|medium|hard>/
        <round-id>-real.<ext>
        <round-id>-fake.<ext>
        notes.json          (subject_label + reveal_note per round-id)

Run this once to (re)generate all three pools and their placeholder media:
    python scripts/generate_placeholder_content.py

Requires ffmpeg on PATH. Safe to re-run -- it overwrites existing
placeholder files and deletes stale ones from prior runs. It only ever
touches files matching its own `<tier>-<n>-real/fake.<ext>` naming and its
own `notes.json`, so hand-added real content using different round-id names
is untouched by a re-run.

This only ever produces synthetic placeholder content (tones, test
patterns, solid colors) -- never real speech, footage, or photos of anyone.
Replace pool entries with real content before the event; see
app/content/README.md for how and where to source it safely.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONTENT_ROOT = PROJECT_ROOT / "app" / "static" / "content"

POOL_SIZES = {"easy": 6, "medium": 4, "hard": 3}


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def clean_stale(tier_dir: Path) -> None:
    tier_dir.mkdir(parents=True, exist_ok=True)
    for pattern in ("*-real.*", "*-fake.*"):
        for stale in tier_dir.glob(pattern):
            stale.unlink()
    notes_path = tier_dir / "notes.json"
    if notes_path.exists():
        notes_path.unlink()


def write_notes(tier_dir: Path, notes: dict) -> None:
    (tier_dir / "notes.json").write_text(json.dumps(notes, indent=2) + "\n")


# ---------------------------------------------------------------- audio ---

def build_audio() -> None:
    modality_dir = CONTENT_ROOT / "audio"
    tier_gap = {"easy": 380, "medium": 70, "hard": 10}
    tier_base = {"easy": 260, "medium": 380, "hard": 430}

    total = 0
    for tier, n in POOL_SIZES.items():
        tier_dir = modality_dir / tier
        clean_stale(tier_dir)
        notes = {}
        for i in range(1, n + 1):
            real_freq = tier_base[tier] + (i - 1) * 15
            fake_freq = real_freq + tier_gap[tier]
            duration = 4 + (i % 3)
            round_id = f"{tier}-{i}"
            real_file, fake_file = f"{round_id}-real.mp3", f"{round_id}-fake.mp3"

            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"sine=frequency={real_freq}:duration={duration}",
                 "-ar", "44100", str(tier_dir / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"sine=frequency={fake_freq}:duration={duration}",
                 "-ar", "44100", str(tier_dir / fake_file)])

            notes[round_id] = {
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "reveal_note": (
                    f"Placeholder tones, not speech -- {tier} tier "
                    f"({tier_gap[tier]}Hz gap). Replace before the event -- "
                    "see app/content/README.md."
                ),
            }
        write_notes(tier_dir, notes)
        total += n
    print(f"audio pool written: {total} pairs")


# ---------------------------------------------------------------- video ---

VIDEO_SOURCES = ["testsrc", "testsrc2", "smptebars", "smptehdbars", "pal75bars", "rgbtestsrc", "yuvtestsrc"]


def build_video() -> None:
    modality_dir = CONTENT_ROOT / "video"

    total = 0
    for tier, n in POOL_SIZES.items():
        tier_dir = modality_dir / tier
        clean_stale(tier_dir)
        notes = {}
        for i in range(1, n + 1):
            round_id = f"{tier}-{i}"
            duration = 4 + (i % 3)

            if tier == "easy":
                real_src = VIDEO_SOURCES[i % len(VIDEO_SOURCES)]
                fake_src = VIDEO_SOURCES[(i + 3) % len(VIDEO_SOURCES)]
                real_filter = f"{real_src}=size=480x270:duration={duration}:rate=24"
                fake_filter = f"{fake_src}=size=480x270:duration={duration}:rate=24"
            elif tier == "medium":
                real_filter = f"testsrc=size=480x270:duration={duration}:rate=24"
                fake_filter = f"testsrc2=size=480x270:duration={duration}:rate=24"
            else:  # hard -- same source, a 1fps difference only
                real_filter = f"testsrc=size=480x270:duration={duration}:rate=24"
                fake_filter = f"testsrc=size=480x270:duration={duration}:rate=25"

            real_file, fake_file = f"{round_id}-real.mp4", f"{round_id}-fake.mp4"
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", real_filter, "-pix_fmt", "yuv420p", str(tier_dir / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", fake_filter, "-pix_fmt", "yuv420p", str(tier_dir / fake_file)])

            notes[round_id] = {
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "reveal_note": (
                    f"Placeholder test patterns, not footage -- {tier} tier. "
                    "Replace before the event -- see app/content/README.md."
                ),
            }
        write_notes(tier_dir, notes)
        total += n
    print(f"video pool written: {total} pairs")


# ---------------------------------------------------------------- image ---

EASY_COLOR_PAIRS = [
    ("0x2a6f97", "0xa63d40"), ("0x1b998b", "0xd66853"), ("0x6a4c93", "0xf4a261"),
    ("0x14213d", "0xe07a9e"), ("0x2b2d42", "0xffb703"), ("0x0b132b", "0xef476f"),
]
MEDIUM_COLOR_PAIRS = [
    ("0x2a6f97", "0x2a9797"), ("0x1b998b", "0x1b7f98"), ("0x6a4c93", "0x8a4c93"), ("0x14213d", "0x1d3a5f"),
]
HARD_COLOR_PAIRS = [
    ("0x2a6f97", "0x2a7097"), ("0x1b998b", "0x1b9a8c"), ("0x6a4c93", "0x6b4d94"),
]


def build_image() -> None:
    modality_dir = CONTENT_ROOT / "image"
    tier_pairs = {"easy": EASY_COLOR_PAIRS, "medium": MEDIUM_COLOR_PAIRS, "hard": HARD_COLOR_PAIRS}

    total = 0
    for tier, n in POOL_SIZES.items():
        tier_dir = modality_dir / tier
        clean_stale(tier_dir)
        pairs = tier_pairs[tier]
        notes = {}
        for i in range(1, n + 1):
            real_color, fake_color = pairs[(i - 1) % len(pairs)]
            round_id = f"{tier}-{i}"
            real_file, fake_file = f"{round_id}-real.jpg", f"{round_id}-fake.jpg"

            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"color=c={real_color}:s=480x270",
                 "-frames:v", "1", str(tier_dir / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"color=c={fake_color}:s=480x270",
                 "-frames:v", "1", str(tier_dir / fake_file)])

            notes[round_id] = {
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "reveal_note": (
                    f"Placeholder solid-color stills, not photos -- {tier} tier. "
                    "Replace before the event -- see app/content/README.md."
                ),
            }
        write_notes(tier_dir, notes)
        total += n
    print(f"image pool written: {total} pairs")


if __name__ == "__main__":
    build_audio()
    build_video()
    build_image()
    print("Done. Restart the Flask app to pick up the new content.")
DELIVER_EOF

echo "-- writing app/content/README.md --"
cat > app/content/README.md <<'DELIVER_EOF'
# "Which Is Fake?" content

Three independent games, one per modality. Content for all three lives as
plain files under `app/static/content/`, discovered automatically by
folder convention -- **there is no manifest JSON to hand-edit.**

```
app/static/content/
  audio/
    easy/     round-id-real.mp3   round-id-fake.mp3   notes.json (optional)
    medium/   ...
    hard/     ...
  video/
    easy/     round-id-real.mp4   round-id-fake.mp4   notes.json (optional)
    medium/   ...
    hard/     ...
  image/
    easy/     round-id-real.jpg   round-id-fake.jpg   notes.json (optional)
    medium/   ...
    hard/     ...
```

## Adding a round

Drop two files into the right `<modality>/<difficulty>/` folder, named:

```
<round-id>-real.<ext>
<round-id>-fake.<ext>
```

`<round-id>` can be anything filesystem-safe (letters, numbers, hyphens,
underscores) as long as it's the same on both files -- e.g.
`ceo-voicemail-real.mp3` / `ceo-voicemail-fake.mp3`. `<ext>` can be whatever
format you're using (`mp3`/`wav` for audio, `mp4`/`webm` for video,
`jpg`/`png` for images -- anything a browser can play or display natively).

That's it. The pair is picked up automatically the next time someone loads
the game -- no code change, no JSON to edit, no server restart needed
(Flask discovers the files fresh on every request). If you only add one of
the two files (say you're mid-upload), that round is silently skipped until
its partner shows up -- it won't crash the game or show a broken pair.

## Optional: nicer labels with `notes.json`

By default, a round gets an auto-generated label from its id (e.g.
`ceo-voicemail-real.mp3` becomes the label "Ceo voicemail") and a generic
reveal note for its modality. To supply a proper label and a specific
"what gave it away" explanation instead, add a `notes.json` file in the
same tier folder:

```json
{
  "ceo-voicemail": {
    "subject_label": "CEO voicemail asking for a wire transfer",
    "reveal_note": "The real clip has natural pauses and breath sounds; the fake one is a little too evenly paced."
  },
  "another-round-id": {
    "subject_label": "...",
    "reveal_note": "..."
  }
}
```

Only round-ids you actually want to override need an entry -- anything not
listed just falls back to the auto-generated default, so you can add
`notes.json` entries incrementally as you get to them, or skip it entirely
for a first pass.

## How many pairs you need

On every page load, the Flask route for each game randomly samples **4
easy + 2 medium + 1 hard** pair from whatever's in each tier folder (see
`SELECT_COUNTS` in `app/content_pool.py`), always served in that tier
order. **Each tier folder needs at least that many pairs to have any real
variety** -- the whole point is that two players in a row, or the same
player hitting "Play Again," see a different set of clips, so nobody can
memorize the previous player's answers by watching or overhearing them.
More pairs per tier = less repetition. The shipped placeholder content has
6 easy / 4 medium / 3 hard pairs per game as a starting point -- add more
freely, the sampling logic doesn't care how large a tier folder gets.

## The placeholder content

The pairs shipped out of the box are synthetic test content (tones for
audio, test-pattern clips for video, solid-color stills for images) -- not
real speech, footage, or photos of anyone. They exist only to prove each
game's plumbing (including the random sampling) works end to end.
**Replace them with real rounds before the event.** You can mix real and
placeholder pairs in the same tier folder while you're still filling it in
-- just delete the placeholder pair for a tier once you've replaced it with
enough real ones.

To regenerate a clean set of placeholders at any point (e.g. after
clearing out a tier to start over):

```bash
cd ~/Repos/CyberVoiceStation
python scripts/generate_placeholder_content.py
```

This rebuilds all three modalities' placeholder content and `notes.json`
files from scratch. It only ever touches its own `<tier>-<n>-real/fake.*`
filenames and its own `notes.json` in each tier folder, so real content
using different round-id names is left alone by a re-run -- just don't name
a real round `easy-1`, `medium-2`, `hard-3`, etc. (anything that collides
with the generator's own naming) if you want it to survive a
re-generation.

## Sourcing real content safely

Two safe paths, both of which avoid generating unlicensed synthetic media
of real, named people without consent:

1. **Consenting internal volunteers.** A volunteer explicitly agrees ahead
   of time to have a short "fake" clip made of themselves (or to be filmed/
   photographed for a fake image/video pair), paired with a genuine
   recording, photo, or clip of them. This tends to land harder than a
   stranger would, since it shows that even someone the participant
   actually knows can be convincingly faked.

2. **Licensed content from your security awareness vendor.** The vendor
   running the deepfake/social-engineering/AI-phishing webinar likely
   already has example real/fake pairs -- across audio, video, and image --
   built for exactly this kind of game as part of their commercial
   offering. Worth asking before sourcing anything from scratch, especially
   for video.

Avoid generating deepfaked audio, video, or images of real, named public
figures (celebrities, executives at other companies, etc.) without their
consent -- unlike a volunteer's own likeness used with their own informed
consent, that crosses into unauthorized synthetic media of an identifiable
person, with real legal/publicity-rights exposure if it were ever used
outside this internal training context.

**Video specifically is a higher-risk category than audio or stills.**
Face-swap/deepfake video of a real person is both more convincing and more
damaging if it were ever leaked or misused than a short voice clip or
still image, and the consent/publicity-rights exposure is correspondingly
higher. This app has no built-in generation capability for any modality --
it only plays back whatever real/fake pairs you supply. If you want a video
round, source it from your vendor or through a carefully consented,
professionally produced volunteer session.

See the Content Loading Guide project doc for a phased, week-by-week plan
for sourcing and loading content ahead of the event.
DELIVER_EOF

echo "-- writing ARCHITECTURE.md --"
cat > ARCHITECTURE.md <<'DELIVER_EOF'
# Architecture, Deployment & Security

Technical reference for how this app is built, how it runs in each
environment it's deployed to, and what the security model actually is.
`README.md` is the quick-start; this is the full picture, current as of the
AWS public deployment going live.

---

## 1. What the app is

A small Flask app serving three independent "Which Is Fake?" quiz games —
audio, video, picture — plus a shared campaign homepage. Each game shows a
real clip and an AI-generated one side by side, the participant guesses
which is real, and the app reveals the answer with a short explanation of
what gave the fake away.

There is no model runtime anywhere in this app. It's Flask, server-rendered
Jinja templates, vanilla JS/CSS, and static media files discovered by folder
convention (see §2.2) -- no database, no manifest to maintain.
(An earlier version of this app also included a live voice-cloning station.
That's been removed entirely — see `README.md`'s note on this. Nothing in
this document describes that removed feature.)

---

## 2. Application structure

```
app/
  app.py                    Flask app, routing, the passcode gate
  content_pool.py           Shared folder-based content discovery (all 3 games)
  spot_the_fake.py          Blueprint: /spot-the-fake (audio)
  spot_the_fake_video.py    Blueprint: /spot-the-fake-video
  spot_the_fake_image.py    Blueprint: /spot-the-fake-image
  content/
    README.md               Content folder convention + sourcing guardrails
  static/
    content/                Real/fake media, discovered by folder convention (see §2.2)
    ...                     CSS, JS (per-game logic + confetti), favicon
  templates/                Jinja templates, one per page + login.html
```

### 2.1 How a game works

Each of the three blueprints follows the same pattern:

1. `GET /spot-the-fake*` renders the game's template.
2. `GET /api/spot-the-fake*/rounds` calls `content_pool.pick_rounds()`,
   which scans that game's `app/static/content/<modality>/<difficulty>/`
   folders for real/fake file pairs — a pool of candidates per difficulty
   tier (`easy`/`medium`/`hard`) — and randomly samples a fixed count per
   tier (`SELECT_COUNTS = [("easy", 4), ("medium", 2), ("hard", 1)]`),
   always served in that tier order. This means two participants back to
   back (or the same participant hitting "Play Again") see a different set
   of rounds each time, so answers can't be memorized by watching someone
   else play.
3. All scoring, round progression, and the reveal happen **client-side** in
   the page's JS once the round data is fetched. The server is otherwise
   stateless per request — no session, no participant identity, no score
   ever stored server-side (aside from the login gate's session flag, see
   §4).

### 2.2 Content model

There is no manifest to hand-edit. Content is discovered purely by folder
and filename convention, under `app/static/content/<modality>/<difficulty>/`:

```
<round-id>-real.<ext>
<round-id>-fake.<ext>
notes.json          (optional — per-round subject_label / reveal_note overrides)
```

`app/content_pool.py` (shared by all three blueprints) scans each tier
folder, pairs up files by matching `<round-id>` prefix, and skips any
incomplete pair (only a real or only a fake file present) silently rather
than erroring — a content-loading session is often mid-way through adding a
pair. A round gets a sensible auto-generated label and a modality-generic
reveal note by default; an optional `notes.json` in the same folder
supplies a real label and a specific "what gave it away" note per
round-id, with anything not listed falling back to the default.

Placeholder content (synthetic tones, geometric patterns, solid colors)
ships by default so the app is fully playable with zero setup. Loading real
content is just dropping media file pairs into the right tier folder — no
code change, no JSON to maintain, no restart needed. See
`app/content/README.md` for the full convention and sourcing guardrails
(notably: no deepfakes of real, named public figures without consent — see
that file for the reasoning and the safe alternatives).

---

## 3. Deployment topologies

This app runs in three distinct shapes, all from the same codebase, chosen
per `deploy/*` config rather than per branch:

| | Local / native | Mini-PC (Docker) | AWS (public) |
|---|---|---|---|
| Entry point | `scripts/run-native.sh` | `deploy/compose.yaml` | `deploy/aws/compose.aws.yaml` |
| Reachable from | `127.0.0.1` only | `127.0.0.1` only | the public internet |
| TLS | none (loopback) | none (loopback) | Caddy, automatic Let's Encrypt |
| Passcode gate | off (`SITE_PASSCODE` unset) | off | **on** |
| Use case | development, content-loading iteration | in-person kiosk booth | staff access from anywhere, on your own schedule |

### 3.1 Local / native

`scripts/run-native.sh` creates a `.venv/`, installs `requirements-app.txt`
(just Flask), and runs `python app.py`, binding to `127.0.0.1:8080` by
default (`CYBERVOICE_BIND` env var overrides this). This is the fast
iteration loop — content under `app/static/content/` is discovered fresh on
every request, so dropping in new media picks it up immediately, no restart
or rebuild step needed. This is also the default in-person kiosk booth
path: bring a laptop, run this, point a kiosk browser at `127.0.0.1:8080`.

### 3.2 Mini-PC / Docker (local only)

`deploy/compose.yaml` builds `deploy/Dockerfile` (plain `python:3.12-slim`
+ Flask, nothing else) and publishes the container's port **only to
`127.0.0.1`** on the host (`ports: ["127.0.0.1:8080:8080"]`). The container
runs `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges` — hardening
appropriate for a machine left semi-unattended at a physical booth, even
though there's no sensitive data involved anymore. This compose file has no
public-network path by design; it is not the file used for the AWS
deployment.

### 3.3 AWS (public, current live deployment)

The one path that's actually reachable from the public internet, currently
live at `https://cyberroom.periadhityan.com`. See §5 for the full
provisioning walkthrough (also captured in the AWS Public Deployment Guide
project doc); this section is the architecture summary.

```
Internet
   |
   v
Route 53 (A record: cyberroom.periadhityan.com -> Elastic IP)
   |
   v
EC2 instance (t4g.micro, Ubuntu 26.04 LTS, ap-southeast-1)
  Elastic IP: stable across stop/start cycles
  Security group: inbound 22 (SSH, restricted to admin IP), 80, 443 only
   |
   v
Docker Compose (deploy/aws/compose.aws.yaml)
  +-- caddy (caddy:2-alpine)
  |     publishes 80/443 to the instance's network interface
  |     terminates TLS (automatic Let's Encrypt cert + renewal)
  |     reverse-proxies everything to the app container over the
  |     internal compose network -- never exposed to the host or public
  |
  +-- cybervoice (built from deploy/Dockerfile)
        expose: 8080 (internal to the compose network only, no host
        port published -- unreachable except through Caddy)
        SITE_PASSCODE / FLASK_SECRET_KEY injected from deploy/aws/.env
        read_only root fs, cap_drop ALL, no-new-privileges (same
        hardening as the mini-PC path)
```

Key design choice: **`deploy/aws/compose.aws.yaml` is a separate file from
`deploy/compose.yaml`**, not a variant of it. Running the AWS compose file
is the only way anything in this repo opens a port to the public internet
— that's deliberate, so "am I exposing this publicly" is never an implicit
side effect of the wrong flag, it's a distinct, explicitly-named file you
have to choose to run.

**Start/stop, not always-on.** The instance is started before an activity
and stopped after (`scripts/aws/start.sh` / `stop.sh`, wrapping `aws ec2
start-instances` / `stop-instances`), rather than running continuously.
Because the Elastic IP stays associated with the instance across stop/start,
DNS never needs to change between cycles — `start.sh` just waits for the
instance to become reachable and Docker's `restart: unless-stopped` brings
the containers back up on their own. Stopped, the only ongoing cost is a few
cents of EBS storage plus the standard AWS-wide ~$3.60/month public-IPv4
charge on the Elastic IP (applies to any allocated public IP account-wide
since 2024, regardless of instance state) — no compute charge at all until
it's started again.

---

## 4. Security model

### 4.1 Access control: the shared passcode gate

`app/app.py` implements a `before_request` hook (`require_passcode`) that
gates every route except `/login`, `/static/*`, and `/health` behind a
session cookie, when `SITE_PASSCODE` is set:

- **Disabled entirely when `SITE_PASSCODE` is unset** — this is the default
  for local/native and mini-PC deployment, so development and the in-person
  kiosk path are never accidentally gated behind a passcode nobody at the
  booth knows.
- **Comparison is timing-safe** (`hmac.compare_digest`), avoiding a timing
  side-channel on the passcode check.
- **Session cookie** is signed with `FLASK_SECRET_KEY` (falls back to a
  fresh random key per process start if unset — fine for local dev where
  the gate is off anyway; set explicitly in the AWS deployment so sessions
  survive an app restart instead of silently logging everyone out).
- Cookie flags: `HttpOnly` always; `SameSite=Lax`; `Secure` is set
  **exactly when** `SITE_PASSCODE` is set — this doubles as "only require
  HTTPS for the cookie when we're actually in the deployment that has
  HTTPS," so the cookie isn't silently dropped on a plain-HTTP local run.

**What this gate is, and isn't.** It's a light barrier to keep the public
URL from being casually crawled, indexed, or stumbled into — not a
security boundary protecting sensitive data (there isn't any: no PII, no
participant data, all content is either placeholder or non-identity
AI-vs-real material per the content guardrails in `app/content/README.md`).
Known limitations worth being aware of, not currently implemented:

- No rate limiting or lockout on `/login` — a scripted brute-force attempt
  against a short/weak passcode isn't currently slowed down. Mitigate by
  picking a real passphrase, not a short PIN, and treat this as acceptable
  given there's nothing sensitive behind it.
- One shared passcode for everyone, not per-user — anyone with it can share
  it further. Fine for this use case; wouldn't be appropriate if the
  content ever became genuinely sensitive.

### 4.2 Secrets handling

Two secrets exist, both only in the AWS deployment (local/mini-PC don't set
them):

| Secret | Where it lives | Never committed because |
|---|---|---|
| `SITE_PASSCODE` | `deploy/aws/.env` on the EC2 instance | `.env` is gitignored (`deploy/aws/.env`) |
| `FLASK_SECRET_KEY` | same `.env` file | same |
| `INSTANCE_ID` / `AWS_REGION` | `deploy/aws/config.env` on your Mac | not a secret, but account-specific — gitignored so it doesn't leak into a public/shared repo history by habit |

The repo ships `.example` versions of both (`config.env.example`) with
placeholder values, so the real files are a one-time local copy-and-fill,
never tracked.

### 4.3 Network exposure

- EC2 security group allows inbound **22** (SSH, restricted to the admin's
  IP), **80**, and **443** only. Port 8080 (the app itself) is never opened
  in the security group — it's `expose`d to the Docker Compose network only,
  reachable exclusively through the Caddy container.
- Caddy handles all public-facing TLS termination and automatic certificate
  issuance/renewal (Let's Encrypt, HTTP-01 challenge over port 80).
  Certificates persist in a named Docker volume (`caddy_data`) across
  container restarts, so a start/stop cycle doesn't force re-issuance.
- SSH access uses a dedicated key pair (`Cyberroom.pem`), not password auth.
- The GitHub PAT used to clone the private repo onto the EC2 instance is
  scoped to **Contents: Read-only** on this one repository — it cannot push,
  open PRs, or touch anything outside this repo.

### 4.4 Container hardening

Both the mini-PC and AWS deployments run the app container with:

- `read_only: true` — root filesystem is read-only; only `/tmp` is writable
  (mounted as an anonymous volume).
- `cap_drop: [ALL]` — no Linux capabilities beyond the bare minimum.
- `security_opt: [no-new-privileges:true]` — blocks privilege escalation
  via setuid binaries inside the container.

This is meaningful hardening for a container that's reachable from the
public internet (AWS) or left semi-unattended at a physical booth (mini-PC),
even though the app itself doesn't handle sensitive data.

### 4.5 What's deliberately out of scope

- **No WAF, no rate limiting at the edge, no DDoS protection** beyond
  whatever AWS provides by default at the network level. Acceptable for a
  low-traffic internal training tool with no sensitive data; would need
  revisiting if this were ever repurposed for something higher-stakes.
- **No automated OS patching** on the EC2 instance (no `unattended-upgrades`
  configured) — patch it manually (`sudo apt update && sudo apt upgrade -y`)
  periodically, especially before a start-up after a long stopped period.
- **No monitoring/alerting** (no CloudWatch alarms, no uptime check) — the
  instance being down is only discovered by someone trying to load the site.
  Reasonable given the start/stop-on-demand model already means it's
  *expected* to be down most of the time.

---

## 5. Provisioning the AWS deployment from scratch

Full step-by-step (console screenshots, exact CLI commands, troubleshooting)
lives in the **AWS Public Deployment Guide** project doc. Summary of the
one-time setup, for reference:

1. Push the app code (passcode gate + `deploy/aws/*` already in this repo).
2. Launch an EC2 instance (Ubuntu LTS, arm64, `t4g.micro`), security group
   allowing 22/80/443 only.
3. Allocate + associate an Elastic IP.
4. Point a Route 53 A record at it.
5. SSH in, install Docker Engine.
6. Clone the repo (GitHub PAT, Contents:Read-only), create `deploy/aws/.env`
   with `SITE_PASSCODE` and `FLASK_SECRET_KEY`.
7. `docker compose -f deploy/aws/compose.aws.yaml up -d --build`.
8. Save `deploy/aws/config.env` locally (`INSTANCE_ID`, `AWS_REGION`) so
   `scripts/aws/start.sh` / `stop.sh` work going forward.

Day-to-day, only step 8's two scripts are needed — everything else is
one-time.

---

## 6. Repository layout

```
app/
  app.py                     Flask app + passcode gate
  content_pool.py            Shared folder-based content discovery
  spot_the_fake*.py          Three game blueprints
  content/                   Content README (folder convention + sourcing guardrails)
  static/content/            Real/fake media, one subtree per modality/difficulty
  static/, templates/        Frontend assets

deploy/
  Dockerfile                 Shared image build (all deployment paths)
  compose.yaml                Local/mini-PC -- loopback-only, no public exposure
  aws/
    compose.aws.yaml          AWS -- the only compose file with public ports
    Caddyfile                 Reverse proxy + automatic HTTPS config
    config.env.example        Template for the local start/stop scripts' config

scripts/
  run-native.sh               Local dev / kiosk entry point
  verify-offline.sh           Confirms the app works with no network dependency
  generate_placeholder_content.py   Regenerates the default placeholder content folders
  aws/
    start.sh, stop.sh         Day-to-day EC2 start/stop, wrapping the AWS CLI

requirements-app.txt          Just Flask
README.md                     Quick start
ARCHITECTURE.md               This document
```

---

*Written 18 August 2026, after the AWS deployment went live, to consolidate architecture, deployment, and security documentation that had been spread across several planning docs into one current, authoritative reference.*
DELIVER_EOF

echo "-- writing README.md --"
cat > README.md <<'DELIVER_EOF'
# CyberVoiceStation — "Which Is Fake?" Cyber Room PoC

Three lightweight, self-contained "spot the fake" games for the Cyber Room
station at Cybersecurity Awareness Month 2026: audio, video, and picture.
Each game plays a real clip and an AI-generated one side by side and asks
the participant to guess which is real, then reveals what gave the fake
away. No participant data collected, no files stored -- answers and scores
exist only in the browser tab.

*(This repo previously also included a live voice-cloning station, "Hear
Yourself Hacked." That's been removed -- this build is just the three
"Which Is Fake?" games.)*

For the full architecture, deployment topology, and security model, see
**[ARCHITECTURE.md](./ARCHITECTURE.md)**. This README is just the quick
start.

---

## What's in this repo

- A small Flask app (`app/app.py`) serving the homepage hub and the three
  game blueprints (`spot_the_fake.py`, `spot_the_fake_video.py`,
  `spot_the_fake_image.py`).
- Each game samples a random subset of real/fake pairs from its own content
  pool per difficulty tier (easy/medium/hard) on every page load, so two
  participants back to back don't see the exact same rounds.
- Placeholder content ships out of the box (synthetic tones/patterns/colors)
  so the app runs end to end immediately. Content is just files dropped into
  folders (`app/static/content/<modality>/<difficulty>/`) -- no manifest to
  maintain. See `app/content/README.md` for the full convention and how to
  load real content before the event.
- An optional shared-passcode gate (`SITE_PASSCODE` env var) for when this
  is deployed somewhere publicly reachable -- off by default, so local dev
  and the in-person kiosk path are never accidentally gated.

There's no model runtime, no GPU/MPS dependency, and no large downloads --
this is just Flask plus static media files discovered by folder convention,
so setup and deployment are both fast.

---

## Prerequisites

- Python 3.9+ (any recent 3.x works)
- Optional: Docker, if you want the containerized/hardened path instead of
  running natively
- Optional: `ffmpeg` on your PATH, only needed to (re)generate placeholder
  content via `scripts/generate_placeholder_content.py` -- not needed to run
  the app itself, and not needed once you've loaded real content

---

## Run it natively

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
./scripts/run-native.sh
# open http://127.0.0.1:8080
```

`run-native.sh` creates a local virtualenv (`.venv/`), installs
`requirements-app.txt` into it, and starts the app. No model downloads, no
checkpoints, no upstream repos to pin. This is the fastest loop for
content-loading work too -- content is discovered fresh on every request,
so dropping new files into `app/static/content/` shows up immediately, no
restart needed at all.

## Run it with Docker (local only)

```bash
docker compose -f deploy/compose.yaml build
docker compose -f deploy/compose.yaml up
# open http://127.0.0.1:8080
```

Published to `127.0.0.1` only -- this is the in-person kiosk / mini-PC path,
not a public deployment. Runs with a read-only root filesystem and dropped
Linux capabilities.

## Deploying publicly on AWS

This app is also deployed live on AWS (EC2 + Caddy for automatic HTTPS +
Route 53), gated behind a shared passcode, with a simple start/stop workflow
so it only runs (and costs money) while it's actually needed. That's a
separate compose file (`deploy/aws/compose.aws.yaml`) and a distinct setup
process -- see **[ARCHITECTURE.md §3.3 and §5](./ARCHITECTURE.md#3-deployment-topologies)**
for the architecture, and the AWS Public Deployment Guide project doc for
the full step-by-step.

Day-to-day, once it's set up once:

```bash
./scripts/aws/start.sh    # before an activity
./scripts/aws/stop.sh     # after
```

---

## Deploying to a second local machine

Because there's no model weights or pinned upstream source to carry over,
moving the local/native or mini-PC path to any second machine -- another
Mac, a Windows PC, a mini-PC, whatever's around -- is just:

```bash
git clone <your-repo-URL> ~/CyberVoiceStation
cd ~/CyberVoiceStation
./scripts/run-native.sh
```

or the Docker steps above. `git clone` really is sufficient -- the only
thing to check on a new machine is that Python 3.9+ (native) or Docker
(container) is installed.

---

## Repo layout

```
app/                  Flask backend + templates + static JS/CSS
app/content/           README for loading real game content (folder convention)
app/static/content/    Real/fake media, discovered by folder convention -- no manifest
deploy/               Dockerfile + compose.yaml (local) + aws/ (public deployment)
scripts/              run-native.sh, verify-offline.sh, generate_placeholder_content.py, aws/ (start/stop)
requirements-app.txt
README.md             This file
ARCHITECTURE.md       Full architecture, deployment, and security reference
```

---

## Loading real content before the event

The three games ship with placeholder content (synthetic tones, geometric
patterns, solid colors) so the app is fully playable today. Swapping in
real real/fake pairs is just dropping two files into the right
`app/static/content/<audio|video|image>/<easy|medium|hard>/` folder, named
`<round-id>-real.<ext>` and `<round-id>-fake.<ext>` -- no manifest to edit,
no restart needed. See `app/content/README.md` for the full convention
(including the optional `notes.json` for custom labels) and the Content
Loading Guide project doc for a phased, week-by-week sourcing plan per game
(audio/video/picture).

---

## Pushing this to GitHub

```bash
gh repo create <your-username>/cybervoicestation-poc --private --source=. --remote=origin
# or, if the repo already exists on GitHub:
git remote add origin git@github.com:<your-username>/cybervoicestation-poc.git
git branch -M main
git push -u origin main
```
DELIVER_EOF

echo "-- regenerating placeholder content into the new folder structure --"
echo "   (requires ffmpeg on PATH -- same requirement as before, just a new output layout)"
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found on PATH. Install it (e.g. \`brew install ffmpeg\`) and re-run:"
  echo "  python3 scripts/generate_placeholder_content.py"
  echo "then git add -A, commit, and push manually to finish."
  exit 1
fi
python3 scripts/generate_placeholder_content.py

echo "-- staging, committing, pushing --"
git add -A
git commit -m "Replace JSON-manifest content system with folder-based auto-discovery

Content now lives as plain real/fake file pairs under
app/static/content/<modality>/<difficulty>/, discovered automatically --
no manifest JSON to hand-edit. Adding a round is just dropping two files
in with a shared <round-id>-real/fake.<ext> name; an optional notes.json
per tier folder supplies a custom label and reveal note, with sensible
auto-generated defaults when it is absent."
git push

echo "-- done --"