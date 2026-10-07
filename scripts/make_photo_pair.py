#!/usr/bin/env python3
"""Turn one real photo and one AI image into a photo-game pair that gives nothing away.

    python3 scripts/make_photo_pair.py --id sticky-note --tier medium \\
        --real ~/Downloads/real.jpg --fake ~/Downloads/midjourney.png

Both images get exactly the same treatment so that only what is *in* the picture can
tell them apart: the same 3:2 crop, the same pixel size, the same JPEG quality, and no
metadata (camera EXIF or AI-generator tags would be a giveaway). The result is written to

    app/static/content/image/<tier>/<id>-real.jpg
    app/static/content/image/<tier>/<id>-fake.jpg

after which `python3 scripts/build_static_site.py` picks the pair up. Write the pair's
label and "what gave it away" text in that tier's notes.json.

Needs Pillow (pip install pillow). Originals are never modified.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
CONTENT = ROOT / "app" / "static" / "content" / "image"
RATIO = 3 / 2


def prepare(src: Path, width: int, anchor: str) -> Image.Image:
    """Open, honour orientation, crop to 3:2 (keeping `anchor`), resize to width x width*2/3."""
    img = ImageOps.exif_transpose(Image.open(src)).convert("RGB")
    w, h = img.size
    if w / h > RATIO:                      # too wide: trim the sides
        new_w = round(h * RATIO)
        left = (w - new_w) // 2
        box = (left, 0, left + new_w, h)
    else:                                  # too tall: trim top/bottom
        new_h = round(w / RATIO)
        top = {"top": 0, "center": (h - new_h) // 2, "bottom": h - new_h}[anchor]
        box = (0, top, w, top + new_h)
    return img.crop(box).resize((width, round(width / RATIO)), Image.LANCZOS)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--id", required=True, help="round id, e.g. sticky-note (letters, numbers, hyphens)")
    p.add_argument("--tier", required=True, choices=["easy", "medium", "hard"])
    p.add_argument("--real", required=True, type=Path, help="the real photo")
    p.add_argument("--fake", required=True, type=Path, help="the AI-generated image")
    p.add_argument("--width", type=int, default=960, help="output width in px for BOTH images (default 960)")
    p.add_argument("--real-anchor", default="center", choices=["top", "center", "bottom"], help="which part of a tall real photo to keep")
    p.add_argument("--fake-anchor", default="center", choices=["top", "center", "bottom"], help="which part of a tall AI image to keep")
    p.add_argument("--quality", type=int, default=88)
    args = p.parse_args()

    for path in (args.real.expanduser(), args.fake.expanduser()):
        if not path.is_file():
            print(f"error: {path} not found", file=sys.stderr)
            return 1

    out = CONTENT / args.tier
    out.mkdir(parents=True, exist_ok=True)
    for kind, src, anchor in (("real", args.real, args.real_anchor), ("fake", args.fake, args.fake_anchor)):
        img = prepare(src.expanduser(), args.width, anchor)
        dst = out / f"{args.id}-{kind}.jpg"
        img.save(dst, "JPEG", quality=args.quality, optimize=True, progressive=True)  # no exif= argument: metadata is dropped
        print(f"wrote {dst.relative_to(ROOT)}  {img.size[0]}x{img.size[1]}  {dst.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main())
