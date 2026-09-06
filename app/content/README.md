# "Which Is Fake?" content

Four independent games, one per modality. Content for all four lives as
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
  email/
    easy/     round-id-real.json  round-id-fake.json  notes.json (optional)
    medium/   ...
    hard/     ...
```

The `email` game (phishing emails) works the same way as the other three,
just with `.json` files describing a mock email instead of a media file --
see "The email game's content format" below for that file's fields.

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
`jpg`/`png` for images, `json` for email -- anything a browser can play,
display, or fetch natively).

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

## The email game's content format

The other three games' `<round-id>-real/fake.<ext>` files are media the
browser plays or displays directly. The email game's are instead
`<round-id>-real.json` / `<round-id>-fake.json` -- content_pool.py's
real/fake pair discovery doesn't care about file extension, so the same
convention applies unmodified; the browser just fetches the JSON file
itself (instead of, say, an `<img>` tag fetching a photo) and renders it as
a mock inbox message. Fields:

```json
{
  "from_name": "Meridian IT Help Desk",
  "from_email": "support@meridian-it-helpdesk.com",
  "to": "j.alvarez@meridianfreight.com",
  "subject": "URGENT: Your password expires in 24 hours",
  "date": "Mon, Sep 1, 2026 8:42 AM",
  "body": "Dear Employee,\n\nOur records indicate ...",
  "link_text": "Verify My Password Now",
  "link_url": "http://meridian-it-helpdesk-secure.com/verify?id=8827",
  "attachment_name": "Invoice_DS-88213.pdf.exe"
}
```

`from_name`, `from_email`, `subject`, and `body` are required. `to`,
`date`, `link_text`/`link_url` (a pair -- include both or neither), and
`attachment_name` are all optional and simply don't render if omitted. The
game deliberately shows the link's real destination next to it (as a
"Link goes to:" line, since hover tooltips don't work on a touchscreen
kiosk) -- that mismatch between link text and destination is one of the
core phishing tells this game teaches, so make it count in your fake
rounds' `link_url`.

Unlike the other three games, this one ships with hand-written example
content by default rather than synthetic placeholders -- text is cheap to
write meaningfully, so there's no need for a generator script here. Feel
free to replace the shipped pairs with your own scenarios (or your
security-awareness vendor's) the same way: add/replace the JSON pairs, no
code change needed. Keep any real company or person out of it the same way
the other games do (see "Sourcing real content safely" below) -- invented
companies and names work just as well for teaching the tells.

## How many pairs you need

On every page load, the Flask route for each game randomly samples **4
easy + 2 medium + 1 hard** pair from whatever's in each tier folder (see
`SELECT_COUNTS` in `app/content_pool.py`), always served in that tier
order. **Each tier folder needs at least that many pairs to have any real
variety** -- the whole point is that two players in a row, or the same
player hitting "Play Again," see a different set of clips, so nobody can
memorize the previous player's answers by watching or overhearing them.
More pairs per tier = less repetition. The shipped placeholder content has
6 easy / 4 medium / 3 hard pairs for audio/video/image, and 4 easy / 3
medium / 2 hard for email, as a starting point -- add more freely, the
sampling logic doesn't care how large a tier folder gets.

## The placeholder content

The audio/video/image pairs shipped out of the box are synthetic test
content (tones for audio, test-pattern clips for video, solid-color stills
for images) -- not real speech, footage, or photos of anyone. They exist
only to prove each game's plumbing (including the random sampling) works
end to end. **Replace them with real rounds before the event.** You can mix
real and placeholder pairs in the same tier folder while you're still
filling it in -- just delete the placeholder pair for a tier once you've
replaced it with enough real ones.

To regenerate a clean set of placeholders at any point (e.g. after
clearing out a tier to start over):

```bash
cd ~/Repos/CyberVoiceStation
python scripts/generate_placeholder_content.py
```

This rebuilds the audio/video/image placeholder content and `notes.json`
files from scratch (it doesn't touch `email/`, which ships hand-written
example content instead of a synthetic placeholder -- see "The email
game's content format" above). It only ever touches its own
`<tier>-<n>-real/fake.*` filenames and its own `notes.json` in each tier
folder, so real content using different round-id names is left alone by a
re-run -- just don't name a real round `easy-1`, `medium-2`, `hard-3`, etc.
(anything that collides with the generator's own naming) if you want it to
survive a re-generation.

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

## Two storage backends: local folders or S3

Everything above describes the **local** backend (`CONTENT_BACKEND=local`,
the default) -- content lives on disk under `app/static/content/`. This is
what local/native and mini-PC deployments always use, and it's the fastest
loop for content-loading work (drop files in, refresh the browser, done).

The AWS deployment can instead run with `CONTENT_BACKEND=s3`, where the
exact same `<round-id>-real/fake.<ext>` + optional `notes.json` convention
applies, just as S3 object keys under `content/<modality>/<difficulty>/`
in a private bucket instead of local folders. Nothing about *how* you name
or organize content changes -- only where it physically lives and how you
get it there:

```bash
./scripts/sync_content_to_s3.sh <bucket-name>
```

uploads whatever's currently in your local `app/static/content/` to the
bucket, mirroring the same folder structure as S3 key prefixes. New or
changed content shows up live within about a minute (a short server-side
cache), with no redeploy, rebuild, or restart of the AWS instance needed --
unlike the local backend baked into the Docker image, S3 content updates
are fully decoupled from the app itself.

**Why you'd want this:** a large, growing content library (lots of video
especially) bloats the git repo permanently, can hit GitHub's 100MB
per-file limit, and makes every content change require a full Docker
rebuild on the instance. S3 sidesteps all three. See the S3 Content Storage
project doc for the one-time setup (bucket, IAM role, enabling
`CONTENT_BACKEND=s3`) and `ARCHITECTURE.md` §2.2/§4.3 for how it works
under the hood -- notably, the bucket is never publicly readable; the app
serves each round's media as a short-lived presigned URL, generated only
after the site's passcode gate has already authenticated the request.

For a modest library (a few dozen pairs per game), the local backend is
simpler and there's no need to bother with S3 at all.
