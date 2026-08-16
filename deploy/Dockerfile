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

RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install -e /opt/cybervoice/upstream/OpenVoice \
    && python -m pip install -e /opt/cybervoice/upstream/MeloTTS \
    && python -m pip install -r /opt/cybervoice/requirements-app.txt

RUN mkdir -p /session

WORKDIR /opt/cybervoice/app

EXPOSE 8080

CMD ["python", "app.py"]
