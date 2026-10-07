#!/usr/bin/env python3
"""Build the standalone Cyber Awareness site in site/ from the shared content library.

The site is plain HTML/CSS/JS that opens by double-clicking site/index.html -- no
server, no install, no network. A page opened from file:// can't list folders or
fetch() local files, so this script does the one thing a server would have done:
it reads the same content library the Flask app uses
(app/static/content/<email|video|image>/<easy|medium|hard>/, using the same
<round-id>-real.<ext> / <round-id>-fake.<ext> + notes.json convention) and writes

    site/content/content.js        every round as plain data (emails are embedded)
    site/content/media/...         copies of the video / image files

Run it again whenever content changes:

    python3 scripts/build_static_site.py                  # refresh site/content
    python3 scripts/build_static_site.py --zip            # + dist/CyberRoom.zip (folder to send)
    python3 scripts/build_static_site.py --single-file    # + dist/CyberRoom.html (one file, media embedded)

Only the Python standard library is needed (ffmpeg, if present, is used to shrink
large photos in the *copies*; originals are never touched).
"""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from urllib.parse import quote, unquote

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "app"
CONTENT_SRC = APP / "static" / "content"
SITE = ROOT / "site"
OUT_CONTENT = SITE / "content"
MEDIA_OUT = OUT_CONTENT / "media"
DIST = ROOT / "dist"

# Which content folders go into the site. The deepfake-video game is parked for now; to bring it back,
# add "video" here AND put its station block back into site/config.js (see git history for the block).
TIERS = ("easy", "medium", "hard")
MODALITIES = ("email", "image")
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".webp"}

# Reuse the Flask app's own pair discovery so both builds always agree on what a
# "complete round" is (an incomplete real/fake pair is skipped).
sys.path.insert(0, str(APP))
from content_pool import discover_tier  # noqa: E402


def read_notes(tier_dir: Path) -> dict:
    path = tier_dir / "notes.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}


def copy_media(src: Path, dst: Path, max_width: int) -> None:
    """Copy a media file into the site, shrinking oversized photos when ffmpeg is around."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if max_width and src.suffix.lower() in IMAGE_EXTS and shutil.which("ffmpeg"):
        result = subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", str(src),
             "-vf", f"scale='min({max_width},iw)':-2", "-map_metadata", "-1", "-q:v", "3", str(dst)],
            capture_output=True,
        )
        if result.returncode == 0 and 0 < dst.stat().st_size < src.stat().st_size:
            return
    shutil.copy2(src, dst)


def media_url(modality: str, tier: str, filename: str) -> str:
    return f"content/media/{modality}/{tier}/{quote(filename, safe='/')}"


def localise_email_assets(email: dict, tier_dir: Path, tier: str, round_id: str) -> None:
    """Copy the pictures an email refers to (banner, images, qr, landing) into the site and
    point the email at the copies. Paths in the email JSON are relative to its tier folder."""
    def copy(rel: str) -> str:
        src = tier_dir / rel
        if not src.is_file():
            raise FileNotFoundError(f"email {round_id}: {rel} is referenced but {src} does not exist")
        dst = MEDIA_OUT / "email" / tier / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        return media_url("email", tier, rel)

    if email.get("banner"):
        email["banner"] = copy(email["banner"])
    for img in email.get("images") or []:
        img["src"] = copy(img["src"])
    for key in ("qr", "landing"):
        if isinstance(email.get(key), dict) and email[key].get("src"):
            email[key]["src"] = copy(email[key]["src"])


def build_content(max_image_width: int) -> tuple[dict, list[str]]:
    """Return ({modality: [round, ...]}, warnings) and copy the media files."""
    warnings: list[str] = []
    content: dict[str, list[dict]] = {m: [] for m in MODALITIES}

    for modality in MODALITIES:
        for tier in TIERS:
            tier_dir = CONTENT_SRC / modality / tier
            notes = read_notes(tier_dir)
            for pair in discover_tier(tier_dir, modality):
                extra = notes.get(pair["id"], {})
                entry = {
                    "id": f"{modality}/{tier}/{pair['id']}",
                    "tier": tier,
                    "label": pair["subject_label"],
                    "note": pair["reveal_note"],
                }
                if extra.get("what_you_can_do"):
                    entry["todo"] = extra["what_you_can_do"]
                # shown in the question bank (email game)
                for key in ("techniques", "red_flags"):
                    if extra.get(key):
                        entry[key] = extra[key]

                if modality == "email":
                    for kind in ("real", "fake"):
                        entry[kind] = json.loads((tier_dir / pair[f"{kind}_file"]).read_text(encoding="utf-8"))
                        localise_email_assets(entry[kind], tier_dir, tier, pair["id"])
                else:
                    for kind in ("real", "fake"):
                        filename = pair[f"{kind}_file"]
                        copy_media(tier_dir / filename, MEDIA_OUT / modality / tier / filename, max_image_width)
                        entry[kind] = media_url(modality, tier, filename)

                content[modality].append(entry)

        placeholders = sum(1 for r in content[modality] if "placeholder" in r["label"].lower())
        if placeholders:
            warnings.append(f"{modality}: {placeholders} of {len(content[modality])} rounds are still placeholder content -- replace before sharing")

    return content, warnings


def write_content_js(content: dict) -> Path:
    OUT_CONTENT.mkdir(parents=True, exist_ok=True)
    out = OUT_CONTENT / "content.js"
    out.write_text(
        "/* GENERATED by scripts/build_static_site.py -- do not edit by hand; change the\n"
        "   files under app/static/content/ and run the script again. */\n"
        "window.CONTENT = " + json.dumps(content, ensure_ascii=False, indent=1) + ";\n",
        encoding="utf-8",
    )
    return out


def clear_media() -> None:
    target = MEDIA_OUT.resolve()
    if target.parent.parent != SITE.resolve():  # must be exactly <repo>/site/content/media
        raise RuntimeError(f"refusing to clear unexpected path: {target}")
    if target.exists():
        shutil.rmtree(target)


def build_zip() -> Path:
    DIST.mkdir(exist_ok=True)
    out = DIST / "CyberRoom.zip"
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(SITE.rglob("*")):
            if path.is_file() and path.name != ".DS_Store":
                zf.write(path, Path("CyberRoom") / path.relative_to(SITE))
    return out


def data_uri(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return f"data:{mime};base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def embed_media(node):
    """Swap every relative media path in the content tree for a data: URI."""
    if isinstance(node, dict):
        return {k: embed_media(v) for k, v in node.items()}
    if isinstance(node, list):
        return [embed_media(v) for v in node]
    if isinstance(node, str) and node.startswith("content/media/"):
        return data_uri(SITE / unquote(node))
    return node


def inline_script(code: str) -> str:
    return "<script>\n" + code.replace("</script", "<\\/script") + "\n</script>"


def build_single_file(content: dict) -> Path:
    html = (SITE / "index.html").read_text(encoding="utf-8")
    css = (SITE / "styles.css").read_text(encoding="utf-8")
    config = (SITE / "config.js").read_text(encoding="utf-8")
    app = (SITE / "app.js").read_text(encoding="utf-8")
    rounds = (SITE / "reel-or-real" / "rounds.js").read_text(encoding="utf-8")
    my_questions = (SITE / "reel-or-real" / "add-questions.js").read_text(encoding="utf-8")

    logo = SITE / "assets" / "singtel-logo.svg"
    if logo.exists():
        config = config.replace("assets/singtel-logo.svg", data_uri(logo))

    embedded = "window.CONTENT = " + json.dumps(embed_media(content), ensure_ascii=False) + ";"

    replacements = {
        '<link rel="stylesheet" href="styles.css">': "<style>\n" + css + "\n</style>",
        '<script src="config.js"></script>': inline_script(config),
        '<script src="content/content.js"></script>': inline_script(embedded),
        '<script src="reel-or-real/rounds.js"></script>': inline_script(rounds),
        '<script src="reel-or-real/add-questions.js"></script>': inline_script(my_questions),
        '<script src="app.js"></script>': inline_script(app),
    }
    for needle, replacement in replacements.items():
        if needle not in html:
            raise RuntimeError(f"index.html no longer contains {needle!r}; update build_single_file()")
        html = html.replace(needle, replacement)

    DIST.mkdir(exist_ok=True)
    out = DIST / "CyberRoom.html"
    out.write_text(html, encoding="utf-8")
    return out


def human(size: int) -> str:
    return f"{size / 1_000_000:.1f} MB"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--zip", action="store_true", help="also write dist/CyberRoom.zip (the folder to send)")
    parser.add_argument("--single-file", action="store_true", help="also write dist/CyberRoom.html with CSS, JS, logo and media embedded")
    parser.add_argument("--max-image-width", type=int, default=1600,
                        help="shrink photos wider than this in the site copy (needs ffmpeg; 0 = keep originals; default 1600)")
    args = parser.parse_args()

    if not (SITE / "index.html").exists():
        print(f"error: {SITE / 'index.html'} not found", file=sys.stderr)
        return 1

    clear_media()
    content, warnings = build_content(args.max_image_width)
    write_content_js(content)

    print("Content built into site/content/:")
    for modality in MODALITIES:
        counts = {t: sum(1 for r in content[modality] if r["tier"] == t) for t in TIERS}
        print(f"  {modality:6} {len(content[modality]):2} rounds  (easy {counts['easy']}, medium {counts['medium']}, hard {counts['hard']})")
    media_bytes = sum(p.stat().st_size for p in MEDIA_OUT.rglob("*") if p.is_file()) if MEDIA_OUT.exists() else 0
    print(f"  media copied: {human(media_bytes)}")
    if args.max_image_width and not shutil.which("ffmpeg"):
        print("  (ffmpeg not found: photos were copied at full size)")
    for w in warnings:
        print(f"  WARNING: {w}")

    if args.zip:
        out = build_zip()
        print(f"Wrote {out.relative_to(ROOT)} ({human(out.stat().st_size)})")
    if args.single_file:
        out = build_single_file(content)
        print(f"Wrote {out.relative_to(ROOT)} ({human(out.stat().st_size)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
