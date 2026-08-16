"""Generate placeholder content POOLS for all three Which Is Fake? games.

Each difficulty tier (easy/medium/hard) gets a pool of several candidate
real/fake pairs, not just one. The Flask routes randomly sample a fresh
subset from each pool on every request (see app/spot_the_fake*.py), so two
consecutive players never see the exact same set of clips in the exact same
order -- someone waiting in line can't shoulder-surf the answers from the
person ahead of them.

Run this once to (re)generate the manifests and placeholder media:
    python scripts/generate_placeholder_content.py

Requires ffmpeg on PATH. Safe to re-run -- it overwrites existing
placeholder files and deletes stale ones from prior runs.

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
CONTENT_DIR = PROJECT_ROOT / "app" / "content"
STATIC_DIR = PROJECT_ROOT / "app" / "static" / "spot_the_fake"

POOL_SIZES = {"easy": 6, "medium": 4, "hard": 3}


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def clean_stale(directory: Path) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    # Removes both the old fixed round-N naming and this script's own
    # tier-N naming, so re-running with different pool sizes doesn't leave
    # orphaned files with no manifest entry.
    patterns = (
        "round-*-real.*", "round-*-fake.*",
        "easy-*-real.*", "easy-*-fake.*",
        "medium-*-real.*", "medium-*-fake.*",
        "hard-*-real.*", "hard-*-fake.*",
    )
    for pattern in patterns:
        for stale in directory.glob(pattern):
            stale.unlink()


# ---------------------------------------------------------------- audio ---

def build_audio() -> None:
    clean_stale(STATIC_DIR)
    tier_gap = {"easy": 380, "medium": 70, "hard": 10}
    tier_base = {"easy": 260, "medium": 380, "hard": 430}

    rounds: dict[str, list[dict]] = {"easy": [], "medium": [], "hard": []}
    for tier, n in POOL_SIZES.items():
        for i in range(1, n + 1):
            real_freq = tier_base[tier] + (i - 1) * 15
            fake_freq = real_freq + tier_gap[tier]
            duration = 4 + (i % 3)
            round_id = f"{tier}-{i}"
            real_file, fake_file = f"{round_id}-real.mp3", f"{round_id}-fake.mp3"

            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"sine=frequency={real_freq}:duration={duration}",
                 "-ar", "44100", str(STATIC_DIR / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"sine=frequency={fake_freq}:duration={duration}",
                 "-ar", "44100", str(STATIC_DIR / fake_file)])

            rounds[tier].append({
                "id": round_id,
                "difficulty": tier,
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "real_audio": real_file,
                "fake_audio": fake_file,
                "reveal_note": (
                    f"Placeholder tones, not speech -- {tier} tier "
                    f"({tier_gap[tier]}Hz gap). Replace before the event -- "
                    "see app/content/README.md."
                ),
            })

    (CONTENT_DIR / "spot_the_fake_manifest.json").write_text(json.dumps(rounds, indent=2) + "\n")
    print(f"audio pool written: {sum(len(v) for v in rounds.values())} pairs")


# ---------------------------------------------------------------- video ---

VIDEO_SOURCES = ["testsrc", "testsrc2", "smptebars", "smptehdbars", "pal75bars", "rgbtestsrc", "yuvtestsrc"]


def build_video() -> None:
    video_dir = STATIC_DIR / "video"
    clean_stale(video_dir)

    rounds: dict[str, list[dict]] = {"easy": [], "medium": [], "hard": []}
    for tier, n in POOL_SIZES.items():
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
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", real_filter, "-pix_fmt", "yuv420p", str(video_dir / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", fake_filter, "-pix_fmt", "yuv420p", str(video_dir / fake_file)])

            rounds[tier].append({
                "id": round_id,
                "difficulty": tier,
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "real_video": real_file,
                "fake_video": fake_file,
                "reveal_note": (
                    f"Placeholder test patterns, not footage -- {tier} tier. "
                    "Replace before the event -- see app/content/README.md."
                ),
            })

    (CONTENT_DIR / "spot_the_fake_video_manifest.json").write_text(json.dumps(rounds, indent=2) + "\n")
    print(f"video pool written: {sum(len(v) for v in rounds.values())} pairs")


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
    image_dir = STATIC_DIR / "image"
    clean_stale(image_dir)

    tier_pairs = {"easy": EASY_COLOR_PAIRS, "medium": MEDIUM_COLOR_PAIRS, "hard": HARD_COLOR_PAIRS}
    rounds: dict[str, list[dict]] = {"easy": [], "medium": [], "hard": []}
    for tier, n in POOL_SIZES.items():
        pairs = tier_pairs[tier]
        for i in range(1, n + 1):
            real_color, fake_color = pairs[(i - 1) % len(pairs)]
            round_id = f"{tier}-{i}"
            real_file, fake_file = f"{round_id}-real.jpg", f"{round_id}-fake.jpg"

            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"color=c={real_color}:s=480x270",
                 "-frames:v", "1", str(image_dir / real_file)])
            run(["ffmpeg", "-y", "-f", "lavfi", "-i", f"color=c={fake_color}:s=480x270",
                 "-frames:v", "1", str(image_dir / fake_file)])

            rounds[tier].append({
                "id": round_id,
                "difficulty": tier,
                "subject_label": f"PLACEHOLDER {tier.upper()} {i} -- replace before event",
                "real_image": real_file,
                "fake_image": fake_file,
                "reveal_note": (
                    f"Placeholder solid-color stills, not photos -- {tier} tier. "
                    "Replace before the event -- see app/content/README.md."
                ),
            })

    (CONTENT_DIR / "spot_the_fake_image_manifest.json").write_text(json.dumps(rounds, indent=2) + "\n")
    print(f"image pool written: {sum(len(v) for v in rounds.values())} pairs")


if __name__ == "__main__":
    build_audio()
    build_video()
    build_image()
    print("Done. Restart the Flask app to pick up the new manifests.")
