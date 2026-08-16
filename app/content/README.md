# "Which Is Fake?" content manifest

`spot_the_fake_manifest.json` drives the `/spot-the-fake` game. Each round
needs:

```json
{
  "id": "unique-slug",
  "subject_label": "What the participant sees for this round",
  "real_audio": "filename.mp3",
  "fake_audio": "filename.mp3",
  "reveal_note": "Shown after they guess -- what gave the fake away."
}
```

Audio files referenced by `real_audio`/`fake_audio` live in
`app/static/spot_the_fake/` and are served directly to the browser.

The two placeholder rounds shipped here are synthetic tones (via `ffmpeg`
`sine` generator), not speech, and exist only to prove the game's plumbing
works end to end (routing, JSON, audio playback, scoring). **Replace them
with real rounds before the event.**

## How to source the real 5-8 rounds

Two safe paths were discussed for this, and both avoid generating unlicensed
synthetic audio of real, named people without consent:

1. **Consenting internal volunteers (recommended).** Reuse the same
   consented cloning pipeline this whole app is built on
   (`app/voice_engine.py` -- see the standalone
   `scripts/compare_speakers.py` tool for a template on how to call it
   outside the browser flow). A volunteer (leadership, IT/security staff)
   explicitly agrees ahead of time to have a short "fake" clip generated of
   themselves reading an innocuous line, paired with a genuine recording of
   them saying something else. This tends to land harder for the awareness
   message than a stranger/celebrity would, since it demonstrates that even
   someone the participant actually knows can be convincingly faked.

2. **Licensed content from your security awareness vendor.** The vendor
   running the deepfake/social-engineering/AI-phishing webinar likely
   already has example real/fake pairs built for exactly this kind of game
   as part of their commercial offering -- worth asking before building
   anything from scratch.

Avoid generating deepfaked audio of real, named public figures (celebrities,
executives at other companies, etc.) without their consent -- unlike a
volunteer's own voice cloned with their own informed consent, that crosses
into unauthorized synthetic media of an identifiable person, with real
legal/publicity-rights exposure if it were ever used outside this internal
training context.

## Regenerating the placeholder tones

If you need to recreate or extend the placeholders (e.g. to test a 3rd or
4th round before real content exists):

```bash
cd ~/Repos/CyberVoiceStation
mkdir -p app/static/spot_the_fake
ffmpeg -f lavfi -i "sine=frequency=300:duration=4" -ar 44100 app/static/spot_the_fake/round-N-real.mp3
ffmpeg -f lavfi -i "sine=frequency=600:duration=4" -ar 44100 app/static/spot_the_fake/round-N-fake.mp3
```

Then add a matching entry to `spot_the_fake_manifest.json`.
