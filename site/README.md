# Cyber Awareness station (standalone)

Four quick games in one page: **Spot the Phish** (two emails), **Deepfake or Real Take?** (two
videos), **Snapshot or Fake Shot?** (two photos) and **Reel or Real?** (film plot or real cyber
incident). Each game is worth 100 points, with a "Control Shield" lesson after every answer.
The first three show two items and you pick the real one (7 rounds); Reel or Real? shows one
case and you answer Reel or Real (8 cases).

No install, no server, no internet. It is plain HTML/CSS/JS.

## Run it
1. Unzip `CyberRoom.zip` (or just open the `site/` folder).
2. Double-click `index.html` (Chrome or Edge recommended).
3. Press **F** for fullscreen.

Prefer one file? Open `CyberRoom.html` instead -- everything (photos, videos, logo) is inside it.

Keys: `1`-`4` pick a game on the home screen; `1` = left item / Reel, `2` = right item / Real during a round;
`Enter`/`Space` = next, `H` = home, `F` = fullscreen, `Shift+S` = staff panel.
Touchscreen: press and hold the small "Cyber Awareness" label (top-left) for 1.5 s for the staff panel.
Only anonymous counters (plays, best score, recently shown rounds) are kept, in the browser's localStorage.

## Send it to another computer
Send **`CyberRoom.zip`** (the whole folder, about 5 MB) or the single **`CyberRoom.html`** (about 8 MB).
Nothing else needs installing on the other computer. If email blocks the attachment, share it through
your usual file share or a USB stick instead.

## Change the content (on the computer that has this repo)

**Reel or Real?** has its own files, edited by hand (no build step needed, just refresh):
- `reel-or-real/rounds.js` -- all 39 cases. Keep the same fields; `enabled: false` hides a case.
- `reel-or-real/add-questions.js` -- the easy way to add your own: copy the template at the top,
  fill in 7 fields, save. Mistakes show a "Setup problem" screen naming the case and field.
- The home screen's **Question bank** lists every case; the staff panel shows how many are still draft.

**The other three games** come from the same content library as the Flask version:
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
- `config.js` -- titles, subtitles, the four game cards, the lesson text, scoring, ratings, default
  timer, idle reset, theme. Set `defaultPolicy` to show "The policy that protects us" on every answer screen.
- `styles.css` -- colours are the variables at the top (Singtel red `#EE133B`, charcoal `#1E191A`).
- `assets/singtel-logo.svg` -- set `logoSrc: ""` in `config.js` to hide it.

## Before sharing
- **Reel or Real? needs a fact-check.** All 39 cases are still marked `status: "draft"` (written from
  memory, per the original project's notes) and 14 name real companies. Check each Real case against
  its listed source, then set `status: "approved"`. Case R16 (OCBC) is switched off pending Comms/Legal
  clearance -- get clearance for any named-company case before enabling it. R18 and R26 are
  physical-security cases, also switched off because this is a cyber-only station.
- **Video rounds are still placeholders** (test patterns). The staff panel and the build script both say so.
  Replace them with real real/fake pairs and rebuild.
- Emails are written around an invented company ("Meridian Freight Co."), not a real organisation.
- The timer is **Off** by default (reading two emails or watching two clips takes longer than a quick
  quiz); turn it on from the home screen or the staff panel.

Design, game engine and the Reel or Real? game are from the "Reel or Real?" booth project.
