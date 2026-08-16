# "Which Is Fake?" content manifests

Three independent games, one per modality, each with its own manifest:

| Game | Manifest | Static folder |
|---|---|---|
| Audio | `spot_the_fake_manifest.json` | `app/static/spot_the_fake/` |
| Video | `spot_the_fake_video_manifest.json` | `app/static/spot_the_fake/video/` |
| Picture | `spot_the_fake_image_manifest.json` | `app/static/spot_the_fake/image/` |

Each round needs (field names vary slightly per modality -- see the
existing entries for the exact keys):

```json
{
  "id": "unique-slug",
  "subject_label": "What the participant sees for this round",
  "real_<audio|video|image>": "filename",
  "fake_<audio|video|image>": "filename",
  "reveal_note": "Shown after they guess -- what gave the fake away."
}
```

The placeholder rounds shipped in each manifest are synthetic test content
(tones for audio, test-pattern clips for video, solid-color stills for
images) -- not real speech, footage, or photos of anyone. They exist only to
prove each game's plumbing works end to end. **Replace them with real
rounds before the event.**

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

**Audio** (synthetic tones):
```bash
cd ~/Repos/CyberVoiceStation
ffmpeg -f lavfi -i "sine=frequency=300:duration=4" -ar 44100 app/static/spot_the_fake/round-N-real.mp3
ffmpeg -f lavfi -i "sine=frequency=600:duration=4" -ar 44100 app/static/spot_the_fake/round-N-fake.mp3
```

**Video** (synthetic test patterns, no audio track):
```bash
mkdir -p app/static/spot_the_fake/video
ffmpeg -f lavfi -i "testsrc=size=480x270:duration=4:rate=24" -pix_fmt yuv420p app/static/spot_the_fake/video/round-N-real.mp4
ffmpeg -f lavfi -i "smptebars=size=480x270:duration=4:rate=24" -pix_fmt yuv420p app/static/spot_the_fake/video/round-N-fake.mp4
```

**Picture** (solid-color stills):
```bash
mkdir -p app/static/spot_the_fake/image
ffmpeg -f lavfi -i "color=c=0x2a6f97:s=480x270" -frames:v 1 app/static/spot_the_fake/image/round-N-real.jpg
ffmpeg -f lavfi -i "color=c=0xa63d40:s=480x270" -frames:v 1 app/static/spot_the_fake/image/round-N-fake.jpg
```

Then add a matching entry to the relevant manifest.
