FROM python:3.9.25-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    CYBERVOICE_SESSION_ROOT=/session

RUN apt-get update && apt-get install -y --no-install-recommends \
      ffmpeg \
      git \
      build-essential \
      pkg-config \
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

# --- OpenVoice's own setup.py hard-depends on faster-whisper==0.9.0, which
# hard-pins av==10.*, which will NOT build from source against any ffmpeg
# newer than the one it was written for. Letting pip resolve dependencies
# normally for `-e OpenVoice` / `-e MeloTTS` triggers that build every time,
# no matter what order a *later* pinned `av` install is placed in -- pip
# resolves OpenVoice's own declared constraint first. The reliable fix is to
# stop asking pip to resolve anything: install the exact frozen set that
# already proved to work on the native macOS build (requirements-lock.txt)
# with --no-deps, then install OpenVoice/MeloTTS themselves with --no-deps
# too, since every real dependency they need is already satisfied by the
# lock file. This is a straight reproduction of a known-good environment,
# not a fresh resolve.
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install --no-deps -r /opt/cybervoice/requirements-lock-reference.txt \
    && python -m pip install -e /opt/cybervoice/upstream/OpenVoice --no-deps \
    && python -m pip install -e /opt/cybervoice/upstream/MeloTTS --no-deps

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
