"""Voice-quality tuning tool.

The production app always uses one fixed base speaker (see
CYBERVOICE_BASE_SPEAKER in voice_engine.py). OpenVoice's tone-color
conversion quality depends partly on how close that base TTS voice's accent
and prosody are to your own -- so it's worth comparing all of them against
the SAME reference recording rather than guessing.

This script extracts your tone-color embedding once from a single reference
WAV, then generates the actual awareness script through every available base
speaker, so you can listen to all the variants and pick a winner without
re-recording through the browser each time (the live app never persists the
raw reference recording, by design -- this script is a standalone dev tool
that never touches the app's session/privacy code path).

Usage:
    conda activate cybervoice
    python scripts/compare_speakers.py path/to/reference.wav

Output lands in runtime/tuning/<speaker-key>.wav
"""

import sys
from pathlib import Path

import torch
from melo.api import TTS
from openvoice import se_extractor
from openvoice.api import ToneColorConverter

PROJECT_ROOT = Path(__file__).resolve().parent.parent
CHECKPOINTS = PROJECT_ROOT / "checkpoints_v2"

# Same fixed awareness script the real app uses -- see app/app.py.
TEXT = (
    "Hi, it's me. I'm tied up in another meeting. I need you to approve "
    "this request urgently. Please verify unusual requests using a trusted "
    "channel before acting."
)


def main():
    if len(sys.argv) != 2:
        print("Usage: python scripts/compare_speakers.py path/to/reference.wav")
        sys.exit(1)

    reference_wav = Path(sys.argv[1]).resolve()
    if not reference_wav.exists():
        print(f"Reference file not found: {reference_wav}")
        sys.exit(1)

    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda:0"
    else:
        device = "cpu"
    print(f"Using device: {device}")

    out_dir = PROJECT_ROOT / "runtime" / "tuning"
    out_dir.mkdir(parents=True, exist_ok=True)

    converter_dir = CHECKPOINTS / "converter"
    converter = ToneColorConverter(str(converter_dir / "config.json"), device=device)
    converter.load_ckpt(str(converter_dir / "checkpoint.pth"))

    tts = TTS(language="EN", device=device)
    speaker_ids = tts.hps.data.spk2id

    print("Extracting tone-color embedding from your reference recording (once)...")
    target_se, _ = se_extractor.get_se(
        str(reference_wav),
        converter,
        target_dir=str(out_dir / "_processed"),
        vad=True,
    )

    ses_dir = CHECKPOINTS / "base_speakers" / "ses"

    for speaker_key, speaker_id in speaker_ids.items():
        candidates = [
            ses_dir / f"{speaker_key}.pth",
            ses_dir / f"{speaker_key.lower()}.pth",
            ses_dir / f"{speaker_key.lower().replace('_', '-')}.pth",
        ]
        source_se_path = next((c for c in candidates if c.exists()), None)
        if source_se_path is None:
            print(f"  [skip] {speaker_key}: no matching source embedding file")
            continue

        print(f"  Generating with base speaker: {speaker_key}")
        source_se = torch.load(str(source_se_path), map_location=torch.device(device))

        base_wav = out_dir / f"_base_{speaker_key}.wav"
        out_wav = out_dir / f"{speaker_key}.wav"

        tts.tts_to_file(TEXT, speaker_id, str(base_wav), speed=1.0)
        converter.convert(
            audio_src_path=str(base_wav),
            src_se=source_se,
            tgt_se=target_se,
            output_path=str(out_wav),
            message="CyberAwarenessDemo",
        )
        base_wav.unlink(missing_ok=True)

    print(f"\nDone. Compare the files in {out_dir}")
    print("Play one with: afplay <path-to-file>.wav")


if __name__ == "__main__":
    main()
