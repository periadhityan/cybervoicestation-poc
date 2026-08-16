# "Which Is Fake?" content manifests

Three independent games, one per modality, each with its own manifest:

| Game | Manifest | Static folder |
|---|---|---|
| Audio | `spot_the_fake_manifest.json` | `app/static/spot_the_fake/` |
| Video | `spot_the_fake_video_manifest.json` | `app/static/spot_the_fake/video/` |
| Picture | `spot_the_fake_image_manifest.json` | `app/static/spot_the_fake/image/` |

## Pool-based manifest schema

Each manifest is a **pool per difficulty tier**, not a fixed list of rounds:

```json
{
  "easy": [ { ...round... }, { ...round... }, ... ],
  "medium": [ { ...round... }, ... ],
  "hard": [ { ...round... }, ... ]
}
```

Each round object (field names vary slightly per modality -- see the
existing entries for the exact keys):

```json
{
  "id": "unique-slug",
  "difficulty": "easy | medium | hard",
  "subject_label": "What the participant sees for this round",
  "real_<audio|video|image>": "filename",
  "fake_<audio|video|image>": "filename",
  "reveal_note": "Shown after they guess -- what gave the fake away."
}
```

On every page load, the Flask route (`app/spot_the_fake*.py`) randomly
samples 4 easy + 2 medium + 1 hard pair from each pool (see
`SELECT_COUNTS` in each module) and always serves them in that tier order.
**The pools need at least that many entries per tier to have any real
variety** -- the whole point is that two players in a row, or the same
player hitting "Play Again," see a different set of clips, so nobody can
memorize the previous player's answers by watching or overhearing them.
More entries per pool = less repetition. The shipped placeholder pools have
6 easy / 4 medium / 3 hard candidates per game as a starting point --
expand them freely, the sampling logic doesn't care how large the pools
get.

The placeholder rounds shipped in each manifest are synthetic test content
(tones for audio, test-pattern clips for video, solid-color stills for
images) -- not real speech, footage, or photos of anyone. They exist only to
prove each game's plumbing (including the sampling) works end to end.
**Replace them with real rounds before the event.**

## How to source the real rounds

Two safe paths were discussed for this, and both avoid generating
unlicensed synthetic media of real, named people without consent:

1. **Consenting internal volunteers (recommended, especially for audio).**
   For the audio game, reuse the same consented cloning pipeline this app
   is built on (`app/voice_engine.py` -- see `scripts/compare_speakers.py`
   for a template on calling it outside the browser flow). A volunteer
   explicitly agrees ahead of time to have a short "fake" clip generated of
   themselves, paired with a genuine recording of them saying something
   else. This tends to land harder than a stranger/celebrity would, since
   it shows that even someone the participant actually knows can be
   convincingly faked.

2. **Licensed content from your security awareness vendor.** The vendor
   running the deepfake/social-engineering/AI-phishing webinar likely
   already has example real/fake pairs -- across audio, video, and image --
   built for exactly this kind of game as part of their commercial
   offering. Worth asking before building or sourcing anything from
   scratch, especially for video.

Avoid generating deepfaked audio, video, or images of real, named public
figures (celebrities, executives at other companies, etc.) without their
consent -- unlike a volunteer's own likeness used with their own informed
consent, that crosses into unauthorized synthetic media of an identifiable
person, with real legal/publicity-rights exposure if it were ever used
outside this internal training context.

**Video specifically is a higher-risk category than audio or stills.**
Face-swap/deepfake video of a real person is both more convincing and more
damaging if it were ever leaked or misused than a short voice clip, and the
consent/publicity-rights exposure is correspondingly higher. This app does
not include any video- or image-generation capability -- it only plays back
whatever real/fake pairs you supply through the manifest. Actually producing
convincing deepfake video is also a substantially heavier technical lift
than the voice cloning built here (face-reenactment/lip-sync models,
GPU-heavy training) and isn't something built into this repo. If you want a
video round, source it from your vendor or through a carefully consented,
professionally produced volunteer session -- don't try to generate it
in-house with this codebase.

## Regenerating the placeholder content

```bash
cd ~/Repos/CyberVoiceStation
python scripts/generate_placeholder_content.py
```

This regenerates all three manifests and their placeholder media from
scratch (6 easy / 4 medium / 3 hard pairs each, by default -- edit
`POOL_SIZES` in the script to change that). Safe to re-run any time; it
deletes stale placeholder files from previous runs first. See the script's
docstring for how each tier's placeholder pairs are constructed (frequency
gap for audio, pattern similarity for video, color similarity for images).

To add a real round instead of a placeholder one: drop the real/fake media
file into the relevant static folder, then add a matching entry to the
correct tier array in the manifest by hand -- the generator script only
touches its own placeholder entries, so hand-added real entries are safe
from being overwritten by a future placeholder-regeneration run **as long
as you don't re-run the generator with settings that would collide with
your filenames** (stick to real content filenames that don't start with
`easy-`, `medium-`, `hard-`, or `round-` to be safe).
