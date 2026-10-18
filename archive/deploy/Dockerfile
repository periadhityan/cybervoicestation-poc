FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /opt/cybervoice

COPY app /opt/cybervoice/app
COPY requirements-app.txt /opt/cybervoice/requirements-app.txt

RUN python -m pip install --upgrade pip \
    && python -m pip install -r /opt/cybervoice/requirements-app.txt

WORKDIR /opt/cybervoice/app

EXPOSE 8080

CMD ["python", "app.py"]
