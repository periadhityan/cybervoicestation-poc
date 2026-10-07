# Cyber Awareness station (standalone)

Three quick games in one page: **Spot the Phish** (two emails), **Snapshot or Fake Shot?** (two
photos) and **Reel or Real?** (film plot or real cyber incident). Each game is worth 100 points,
with a "Control Shield" lesson after every answer. The first two show two items and you pick the
real one (7 rounds); Reel or Real? shows one case and you answer Reel or Real (8 cases).

Three **question banks** on the home screen list everything in a game. The **Phish bank** shows every email pair
side by side (tap an email to open it in full, with the page its link opens; "Show answers" marks which is
the phish, the techniques used, and the red flags). The **Photo bank** shows every photo pair (tap to enlarge).
The **Reel or Real bank** lists every case.

No install, no server, no internet. It is plain HTML/CSS/JS.

## Run it
1. Unzip `CyberRoom.zip` (or just open the `site/` folder).
2. Double-click `index.html` (Chrome or Edge recommended).
3. Press **F** for fullscreen.

Prefer one file? Open `CyberRoom.html` instead -- everything (photos, videos, logo) is inside it.

Keys: `1`-`3` pick a game on the home screen; `1` = left item / Reel, `2` = right item / Real during a round;
`Enter`/`Space` = next, `H` = home, `F` = fullscreen, `Shift+S` = staff panel.
Touchscreen: press and hold the small "Cyber Awareness" label (top-left) for 1.5 s for the staff panel.
Only anonymous counters (plays, best score, recently shown rounds) are kept, in the browser's localStorage.

## The visual effects
All in `effects.js`, no extra files:
- **Fireworks** on the score screen at 85% or above (a shield-shaped burst at a perfect 100, with a "Perfect score" badge); **confetti** from 60%.
- **"You got phished"** takes over the screen when a player picks the phishing email. The fake terminal lists what
  *that* fake email would have done (its real domain, link, QR code or attachment). Picking the AI photo gets a milder "Fooled by AI".
  Tap, or press Enter, to skip; it moves on by itself after about 5 seconds. Turn it off per station by deleting `fakeEffect` in `config.js`.
- Sparkles on a correct answer, a flame chip for 3 right in a row, and the score counting up.
- Staff panel: **Animations Off** replaces everything with still versions (use it if anyone is sensitive to motion; it is also
  switched on automatically when the computer asks for reduced motion). **Sound effects** (off by default) adds synthesised
  pops, booms and a fanfare; browsers only allow sound after someone has touched the screen.
- Safety by design: nothing flashes more than twice a second, no full-screen strobe, and the one colour burst when the takeover lands fades once.

## Send it to another computer
Send **`CyberRoom.zip`** (the whole folder, about 5 MB) or the single **`CyberRoom.html`** (about 8 MB).
Nothing else needs installing on the other computer. If email blocks the attachment, share it through
your usual file share or a USB stick instead.

## Change the content (on the computer that has this repo)

**Reel or Real?** has its own files, edited by hand (no build step needed, just refresh):
- `reel-or-real/rounds.js` -- all 39 cases. Keep the same fields; `enabled: false` hides a case.
- **The policy box.** Every Reel or Real answer screen has a box titled "What policy, if implemented, could have
  fixed this?". It shows a dashed **"Policy name goes here"** placeholder until you fill it in. Set a policy
  for one case with `policy_reference` in `rounds.js` (or `policy:` in `add-questions.js`), or one policy for
  all cases with `defaultPolicy` in the Reel or Real station of `config.js`. The wording and placeholder are
  `policyLabel` / `policyPlaceholder` there too.
- `reel-or-real/add-questions.js` -- the easy way to add your own: copy the template at the top,
  fill in 7 fields, save. Mistakes show a "Setup problem" screen naming the case and field.
- The home screen's **Question bank** lists every case; the staff panel shows how many are still draft.

**Spot the Phish and Snapshot or Fake Shot** come from the same content library as the Flask version:
`app/static/content/<email|image>/<easy|medium|hard>/` with `<round-id>-real.<ext>` /
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
  timer, idle reset, theme. Set a station's `defaultPolicy` (or the global one) to show a policy box on that station's answer screens.
- `styles.css` -- colours are the variables at the top (Singtel red `#EE133B`, charcoal `#1E191A`).
- `assets/singtel-logo.svg` -- set `logoSrc: ""` in `config.js` to hide it.

## Before sharing
- **The newer phishing examples name real brands** (Microsoft, DHL, DocuSign, Google, Eventbrite, SingPost, Adobe).
  The text is invented, the links are plain text, and the QR codes only contain a training message, but get
  Comms/Legal sign-off before showing them, as with the Reel or Real cases that name companies.
- **Reel or Real? needs a fact-check.** All 39 cases are still marked `status: "draft"` (written from
  memory, per the original project's notes) and 14 name real companies. Check each Real case against
  its listed source, then set `status: "approved"`. Case R16 (OCBC) is switched off pending Comms/Legal
  clearance -- get clearance for any named-company case before enabling it. R18 and R26 are
  physical-security cases, also switched off because this is a cyber-only station.
- **The deepfake-video game is parked.** Its content is still in `app/static/content/video/` and the Flask app
  still serves it, but the site leaves it out (its clips are placeholder test patterns). To bring it back, add
  `"video"` to `MODALITIES` in `scripts/build_static_site.py` and restore its station block in `config.js`
  (copy it from git history: `git log -p -- site/config.js`).
- **Photo pairs:** the bank is only as good as its notes. Each pair's `notes.json` entry gives its label and
  the "what gave it away" text, so write one whenever you add a pair.
- Emails are written around an invented company ("Meridian Freight Co."), not a real organisation.
- The timer is **Off** by default (reading two emails or watching two clips takes longer than a quick
  quiz); turn it on from the home screen or the staff panel.

Design, game engine and the Reel or Real? game are from the "Reel or Real?" booth project.
