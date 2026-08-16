"""Build-time cache warm-up.

Runs during `docker build` (while network access is still available) so the
runtime container can start with HF_HUB_OFFLINE=1 / TRANSFORMERS_OFFLINE=1
and never touch the network. Mirrors VoiceEngine.__init__ + VoiceEngine.clone
in app/voice_engine.py exactly, using the TTS engine's own output as the
"reference" clip so no external audio input is needed at build time.
"""

from pathlib import Path

import torch
from melo.api import TTS
from openvoice import se_extractor
from openvoice.api import ToneColorConverter

CHECKPOINTS = Path("/opt/cybervoice/checkpoints_v2")
DEVICE = "cpu"  # build environment; runtime picks mps/cuda/cpu itself

converter_dir = CHECKPOINTS / "converter"
converter = ToneColorConverter(str(converter_dir / "config.json"), device=DEVICE)
converter.load_ckpt(str(converter_dir / "checkpoint.pth"))

tts = TTS(language="EN", device=DEVICE)
speaker_ids = tts.hps.data.spk2id
preferred = ["EN-Default", "EN-US", "EN-AU", "EN_INDIA", "EN-BR"]
base_speaker_key = next(
    (key for key in preferred if key in speaker_ids),
    next(iter(speaker_ids.keys())),
)
base_speaker_id = speaker_ids[base_speaker_key]

ses_dir = CHECKPOINTS / "base_speakers" / "ses"
source_se_path = next(
    (
        ses_dir / name
        for name in (
            f"{base_speaker_key}.pth",
            f"{base_speaker_key.lower()}.pth",
            f"{base_speaker_key.lower().replace('_', '-')}.pth",
        )
        if (ses_dir / name).exists()
    ),
    None,
)
if source_se_path is None:
    available = sorted(p.name for p in ses_dir.glob("*.pth"))
    raise FileNotFoundError(
        f"Could not match base speaker {base_speaker_key!r} to a source "
        f"embedding. Available: {available}"
    )
source_se = torch.load(str(source_se_path), map_location=torch.device(DEVICE))

tmp_dir = Path("/tmp/prewarm")
tmp_dir.mkdir(parents=True, exist_ok=True)
ref_wav = tmp_dir / "ref.wav"
out_wav = tmp_dir / "out.wav"

tts.tts_to_file(
    "This is a build time cache warm up clip used to pre load every model "
    "resource this application needs before the container ever starts. In "
    "production this station lets a participant record their own voice and "
    "hear a synthetic version deliver a short social engineering awareness "
    "script, entirely offline, with no data retained after each session "
    "ends. This warm up phase never touches a real voice recording, and "
    "exists only so the image already holds every cached model file it "
    "needs by the time it runs for the first time.",
    base_speaker_id,
    str(ref_wav),
    speed=1.0,
)

target_se, _ = se_extractor.get_se(
    str(ref_wav),
    converter,
    target_dir=str(tmp_dir),
    vad=True,
)

converter.convert(
    audio_src_path=str(ref_wav),
    src_se=source_se,
    tgt_se=target_se,
    output_path=str(out_wav),
    message="PrewarmCache",
)

assert out_wav.exists() and out_wav.stat().st_size > 0, "prewarm did not produce output audio"
print("prewarm complete:", out_wav)
