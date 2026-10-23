# Cyber Awareness station (standalone)

Three quick games in one page: **Spot the Phish** (two emails), **Snapshot or Fake Shot?** (two
photos) and **Reel or Real?** (film plot or real cyber incident). Each game is worth 100 points,
with a "Control Shield" lesson after every answer. The first two show two items and you pick the
real one (7 rounds); Reel or Real? shows one case and you answer Reel or Real (8 cases).

Spot the Phish has **26 pairs (8 easy, 9 medium, 9 hard)**, in four kinds: emails on a desktop, emails as they look in a phone's mail
app (links show as coloured text with no address, so you have to know where to look), **text messages** (smishing), and **QR codes out in the world**
(car park stickers, table codes, Wi-Fi cards). Every game is built to mix them: the game
scores hundreds of random line-ups and keeps one with all four kinds, no more than 3 of one kind, and pairs the player
hasn't just seen (in a 1,000-game simulation, every game had at least one text, one QR, one phone email and one desktop email, and a pair the player had just seen came up about 2.5 times per game, which is the cost of a small bank). After you answer, the fake is shown again with its **3-4 red flags
numbered on the email itself**. Three **question banks** on the home screen list everything in a game. The **Phish bank** shows every email pair
side by side (tap an email to open it in full, with the page its link opens; "Show answers" marks which is
the phish, the techniques used, and the red flags). The **Photo bank** shows every photo pair (tap to enlarge).
The **Reel or Real bank** lists every case.

No install, no server, no internet. It is plain HTML/CSS/JS.

## Run it
1. Unzip `Cyberroom.zip` (or just open the `Cyberroom/` folder).
2. Double-click `index.html` (Chrome or Edge recommended).
3. Press **F** for fullscreen.

Prefer one file? Open `Cyberroom.html` instead -- everything (photos, videos, logo) is inside it.

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
- **Reel or Real is a night at the pictures**: every case is a cinema ticket (barcode, screen, row and seat), the answers are
  the Reel and Real stubs, and the verdict is stamped "Based on a true story" or "Pure fiction". Guessing "film" for a real incident
  plays **"Stranger than fiction"** with the real case typed out. A perfect run opens red velvet curtains and shows **"Best picture"**.
  The ratings are Best Director, Box Office Hit, Straight to Streaming and Cut From The Final Edit (all editable in `config.js`;
  the station's `cinema: true` switches the look on).
- Sparkles on a correct answer, a flame chip for 3 right in a row, and the score counting up.
- Staff panel: **Animations Off** replaces everything with still versions (use it if anyone is sensitive to motion; it is also
  switched on automatically when the computer asks for reduced motion). **Sound effects** (off by default) adds synthesised
  pops, booms and a fanfare; browsers only allow sound after someone has touched the screen.
- Safety by design: nothing flashes more than twice a second, no full-screen strobe, and the one colour burst when the takeover lands fades once.

## Send it to another computer
Send **`Cyberroom.zip`** (the whole folder, about 5 MB) or the single **`Cyberroom.html`** (about 7 MB).
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

**Spot the Phish and Snapshot or Fake Shot** are built from `content-source/` (next to this folder, not inside it):
`content-source/<email|image>/<easy|medium|hard>/` with `<round-id>-real.<ext>` /
`<round-id>-fake.<ext>` pairs and an optional `notes.json` (see `content-source/README.md`).
Then rebuild:

```bash
python3 tools/build_static_site.py                 # refresh Cyberroom/content/
python3 tools/build_static_site.py --zip           # also dist/Cyberroom.zip
python3 tools/build_static_site.py --single-file   # also dist/Cyberroom.html
```

Only Python 3 is needed, and only on the computer that builds. Photos wider than 1600 px are shrunk in
the *copy* that goes into the site (needs `ffmpeg`; originals are never changed).
`Cyberroom/content/` is generated -- don't edit it by hand.

For email rounds, `notes.json` can also carry a per-round `"what_you_can_do"` line that replaces the
game's default tip on the answer screen.

## Change the wording, scoring or look
- `config.js` -- titles, subtitles, the three game cards, the lesson text, scoring, ratings, default
  timer, idle reset, theme. Set a station's `defaultPolicy` (or the global one) to show a policy box on that station's answer screens.
- `styles.css` -- colours are the variables at the top (Singtel red `#EE133B`, charcoal `#1E191A`).
- `assets/singtel-logo.svg` -- set `logoSrc: ""` in `config.js` to hide it.

## Before sharing
- **Most phishing pairs name real brands** (Microsoft, Amazon, PayPal, Apple, DBS, OCBC, Singtel, IRAS, CPF, Maersk
  and more). The real emails use each brand's genuine sender *domain* (the part after the @; the part before it
  is illustrative), the fakes use lookalike domains, the text is invented, links are plain text, and QR codes only
  contain a training message. This build is meant for internal use; get Comms/Legal sign-off before showing it
  anywhere public, as with the Reel or Real cases that name companies.
- **Reel or Real? needs a fact-check.** All 39 cases are still marked `status: "draft"` (written from
  memory, per the original project's notes) and 14 name real companies. Check each Real case against
  its listed source, then set `status: "approved"`. Case R16 (OCBC) is switched off pending Comms/Legal
  clearance -- get clearance for any named-company case before enabling it. R18 and R26 are
  physical-security cases, also switched off because this is a cyber-only station.
- **The deepfake-video game is parked.** Its placeholder clips are in `archive/app/static/content/video/`. To bring it
  back, copy them to `content-source/video/`, add `"video"` to `MODALITIES` in `tools/build_static_site.py` and restore
  its station block in `config.js` (copy it from git history: `git log -p -- site/config.js`).
- **Photo pairs:** the bank is only as good as its notes. Each pair's `notes.json` entry gives its label and
  the "what gave it away" text, so write one whenever you add a pair.
- Emails are written around an invented company ("Meridian Freight Co."), not a real organisation.
- The timer is **Off** by default (reading two emails or watching two clips takes longer than a quick
  quiz); turn it on from the home screen or the staff panel.

Design, game engine and the Reel or Real? game are from the "Reel or Real?" booth project.
