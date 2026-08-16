FROM python:3.9.25-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CYBERVOICE_SESSION_ROOT=/session

RUN apt-get update && apt-get install -y --no-install-recommends \
      ffmpeg \
      git \
      build-essential \
      libsndfile1 \
      mecab \
      libmecab-dev \
      mecab-ipadic-utf8 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/cybervoice

# In a production reproducible build, copy pinned source trees rather than
# cloning moving 'main' branches during docker build.
COPY upstream/OpenVoice /opt/cybervoice/upstream/OpenVoice
COPY upstream/MeloTTS /opt/cybervoice/upstream/MeloTTS
COPY app /opt/cybervoice/app
COPY checkpoints_v2 /opt/cybervoice/checkpoints_v2
COPY requirements-app.txt /opt/cybervoice/requirements-app.txt
COPY requirements-lock.txt /opt/cybervoice/requirements-lock-reference.txt

# --- Dependency install order matters here. This mirrors the exact sequence
# that was needed to get a working env natively on macOS: pip's resolver
# alone pulls in a broken chain via faster-whisper's pin on av==10.0.0,
# which will NOT build from source against modern ffmpeg headers (and the
# `ffmpeg` apt package doesn't even ship the dev headers needed to try), so
# we sidestep it entirely with a prebuilt `av` wheel plus --no-deps on the
# packages that hard-pin the broken version. numpy is re-pinned last because
# dtw-python otherwise drags it up to a version that breaks pandas/sklearn's
# compiled extensions.
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install "cython<3" \
    && python -m pip install -e /opt/cybervoice/upstream/OpenVoice \
    && python -m pip install -e /opt/cybervoice/upstream/MeloTTS \
    && python -m pip install -r /opt/cybervoice/requirements-app.txt \
    && python -m pip install "av>=12,<14" --only-binary=:all: \
    && python -m pip install faster-whisper==0.9.0 --no-deps \
    && python -m pip install whisper-timestamped==1.14.2 --no-deps \
    && python -m pip install "ctranslate2<4" \
    && python -m pip install "onnxruntime<2,>=1.14" \
    && python -m pip install openai-whisper --no-deps \
    && python -m pip install "dtw-python<1.4" \
    && python -m pip install "numpy==1.22.0"

# MeloTTS's English phonemizer (g2p_en) needs the unidic dictionary plus
# specific NLTK corpora that aren't declared as installable deps anywhere.
RUN python -m unidic download \
    && python -m nltk.downloader averaged_perceptron_tagger_eng \
        averaged_perceptron_tagger punkt punkt_tab cmudict

RUN mkdir -p /session

# --- Pre-warm the model cache into this image layer while we still have
# network access during `docker build`. This exercises the exact same
# lazy-load call sites as a real /api/clone request (TTS instantiation,
# tone-color extraction, watermarked conversion), so every Hugging Face
# resource that gets fetched on first real use -- the per-language BERT
# models MeloTTS loads at TTS() init, the MeloTTS-English weights, and the
# WavMark watermark model used inside converter.convert() -- is already
# cached in the image by the time the container runs. That's what lets the
# container start with HF_HUB_OFFLINE=1 / TRANSFORMERS_OFFLINE=1 (set at
# runtime in compose.yaml, not here) and never touch the network.
COPY deploy/prewarm.py /opt/cybervoice/deploy/prewarm.py
RUN python /opt/cybervoice/deploy/prewarm.py

WORKDIR /opt/cybervoice/app

EXPOSE 8080

CMD ["python", "app.py"]
