# Real or Fake? -- Cyber Awareness station (standalone)

Three quick "which one is real?" games in one page: **Spot the Phish** (two emails),
**Deepfake or Real Take?** (two videos) and **Snapshot or Fake Shot?** (two photos). Each game
is up to 7 rounds worth 100 points, with a "Control Shield" lesson after every answer.

No install, no server, no internet. It is plain HTML/CSS/JS.

## Run it
1. Unzip `CyberRoom.zip` (or just open the `site/` folder).
2. Double-click `index.html` (Chrome or Edge recommended).
3. Press **F** for fullscreen.

Prefer one file? Open `CyberRoom.html` instead -- everything (photos, videos, logo) is inside it.

Keys: `1`/`2`/`3` pick a game on the home screen; `1` = left item, `2` = right item during a round;
`Enter`/`Space` = next, `H` = home, `F` = fullscreen, `Shift+S` = staff panel.
Touchscreen: press and hold the small "Cyber Awareness" label (top-left) for 1.5 s for the staff panel.
Only anonymous counters (plays, best score, recently shown rounds) are kept, in the browser's localStorage.

## Send it to another computer
Send **`CyberRoom.zip`** (the whole folder, about 5 MB) or the single **`CyberRoom.html`** (about 8 MB).
Nothing else needs installing on the other computer. If email blocks the attachment, share it through
your usual file share or a USB stick instead.

## Change the content (on the computer that has this repo)
The rounds come from the same content library as the Flask version:
`app/static/content/<email|video|image>/<easy|medium|hard>/` with `<round-id>-real.<ext>` /
`<round-id>-fake.<ext>` pairs and an optional `notes.json` (see `app/content/README.md`).
Then rebuild:

```bash
python3 scripts/build_static_site.py                 # refresh site/content/
python3 scripts/build_static_site.py --zip           # also dist/CyberRoom.zip
python3 scripts/build_static_site.py --single-file   # also dist/CyberRoom.html
```

Only Python 3 is needed, and only on the computer that builds. Photos wider than 1600 px are shrunk in
the *copy* that goes into the site (needs `ffmpeg`; originals are never changed).
`site/content/` is generated -- don't edit it by hand.

For email rounds, `notes.json` can also carry a per-round `"what_you_can_do"` line that replaces the
game's default tip on the answer screen.

## Change the wording, scoring or look
- `config.js` -- titles, subtitles, the three game cards, the lesson text, scoring, ratings, default
  timer, idle reset, theme. Set `defaultPolicy` to show "The policy that protects us" on every answer screen.
- `styles.css` -- colours are the variables at the top (Singtel red `#EE133B`, charcoal `#1E191A`).
- `assets/singtel-logo.svg` -- set `logoSrc: ""` in `config.js` to hide it.

## Before sharing
- **Video rounds are still placeholders** (test patterns). The staff panel and the build script both say so.
  Replace them with real real/fake pairs and rebuild.
- Emails are written around an invented company ("Meridian Freight Co."), not a real organisation.
- The timer is **Off** by default (reading two emails or watching two clips takes longer than a quick
  quiz); turn it on from the home screen or the staff panel.

Design and game engine adapted from the "Reel or Real?" booth project.
