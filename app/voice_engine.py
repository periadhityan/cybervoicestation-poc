from __future__ import annotations

import os
from pathlib import Path

import torch
from melo.api import TTS
from openvoice import se_extractor
from openvoice.api import ToneColorConverter


class VoiceEngine:
    def __init__(self, project_root: Path):
        self.project_root = project_root.resolve()
        self.checkpoints = self.project_root / "checkpoints_v2"

        if torch.backends.mps.is_available():
            self.device = "mps"
        elif torch.cuda.is_available():
            self.device = "cuda:0"
        else:
            self.device = "cpu"

        converter_dir = self.checkpoints / "converter"
        self.converter = ToneColorConverter(
            str(converter_dir / "config.json"),
            device=self.device,
        )
        self.converter.load_ckpt(str(converter_dir / "checkpoint.pth"))

        # Load the English TTS model once at service startup.
        self.tts = TTS(language="EN", device=self.device)
        self.speaker_ids = self.tts.hps.data.spk2id

        # Prefer EN-Default for a neutral awareness demo.
        preferred = ["EN-Default", "EN-US", "EN-AU", "EN_INDIA", "EN-BR"]
        self.base_speaker_key = next(
            (key for key in preferred if key in self.speaker_ids),
            next(iter(self.speaker_ids.keys())),
        )
        self.base_speaker_id = self.speaker_ids[self.base_speaker_key]

        self.source_se_path = self._find_source_embedding(self.base_speaker_key)
        self.source_se = torch.load(
            str(self.source_se_path),
            map_location=torch.device(self.device),
        )

    def _find_source_embedding(self, speaker_key: str) -> Path:
        ses_dir = self.checkpoints / "base_speakers" / "ses"
        candidates = [
            ses_dir / f"{speaker_key}.pth",
            ses_dir / f"{speaker_key.lower()}.pth",
            ses_dir / f"{speaker_key.lower().replace('_', '-')}.pth",
        ]

        for candidate in candidates:
            if candidate.exists():
                return candidate

        available = sorted(p.name for p in ses_dir.glob("*.pth"))
        raise FileNotFoundError(
            "Could not match the MeloTTS base speaker to an OpenVoice source "
            f"embedding. Requested {speaker_key!r}. Available: {available}"
        )

    def clone(
        self,
        reference_wav: Path,
        text: str,
        session_dir: Path,
    ) -> Path:
        """Generate cloned speech entirely inside the provided session directory."""
        processed_dir = session_dir / "processed"
        processed_dir.mkdir(parents=True, exist_ok=True)

        base_wav = session_dir / "base.wav"
        output_wav = session_dir / "clone.wav"

        target_se = None
        try:
            target_se, _ = se_extractor.get_se(
                str(reference_wav),
                self.converter,
                target_dir=str(processed_dir),
                vad=True,
            )

            self.tts.tts_to_file(
                text,
                self.base_speaker_id,
                str(base_wav),
                speed=1.0,
            )

            self.converter.convert(
                audio_src_path=str(base_wav),
                src_se=self.source_se,
                tgt_se=target_se,
                output_path=str(output_wav),
                message="CyberAwarenessDemo",
            )

            if not output_wav.exists() or output_wav.stat().st_size == 0:
                raise RuntimeError("Voice engine did not produce output audio")

            return output_wav
        finally:
            # Remove Python references to the participant-derived embedding.
            target_se = None
            if self.device.startswith("cuda"):
                torch.cuda.empty_cache()
            # MPS cache cleanup is optional and version-dependent; the session
            # files themselves are deleted by SessionCleaner after response data
            # has been copied into memory.
