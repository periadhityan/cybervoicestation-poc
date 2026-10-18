# Cyberroom

A cyber-awareness kiosk that runs in a browser with nothing to install: **Spot the Phish**, **Snapshot or Fake Shot?**
and **Reel or Real?**. Open `Cyberroom/index.html` to play.

```
Cyberroom/        the site. Zip this folder (or use dist/) and send it anywhere. Start with Cyberroom/README.md
content-source/   the questions for Spot the Phish and Snapshot or Fake Shot, as plain files (see content-source/README.md)
tools/            the build script and the scripts that make pictures
dist/             Cyberroom.zip and Cyberroom.html, made by the build (not in git)
archive/          the retired Flask / native / AWS version and old docs, kept for reference
```

Rebuild after changing content:

```bash
python3 tools/build_static_site.py --zip --single-file
```
