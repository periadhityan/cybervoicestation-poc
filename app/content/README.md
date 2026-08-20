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
