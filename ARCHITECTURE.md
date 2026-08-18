# Architecture, Deployment & Security

Technical reference for how this app is built, how it runs in each
environment it's deployed to, and what the security model actually is.
`README.md` is the quick-start; this is the full picture, current as of the
AWS public deployment going live.

---

## 1. What the app is

A small Flask app serving three independent "Which Is Fake?" quiz games —
audio, video, picture — plus a shared campaign homepage. Each game shows a
real clip and an AI-generated one side by side, the participant guesses
which is real, and the app reveals the answer with a short explanation of
what gave the fake away.

There is no model runtime anywhere in this app. It's Flask, server-rendered
Jinja templates, vanilla JS/CSS, and static JSON manifests plus media files.
(An earlier version of this app also included a live voice-cloning station.
That's been removed entirely — see `README.md`'s note on this. Nothing in
this document describes that removed feature.)

---

## 2. Application structure

```
app/
  app.py                    Flask app, routing, the passcode gate
  spot_the_fake.py          Blueprint: /spot-the-fake (audio)
  spot_the_fake_video.py    Blueprint: /spot-the-fake-video
  spot_the_fake_image.py    Blueprint: /spot-the-fake-image
  content/
    *_manifest.json         Pool-based content: real/fake pairs per difficulty tier
    README.md                Manifest schema + content-sourcing guardrails
  static/                   CSS, JS (per-game logic + confetti), favicon
  templates/                Jinja templates, one per page + login.html
```

### 2.1 How a game works

Each of the three blueprints follows the same pattern:

1. `GET /spot-the-fake*` renders the game's template.
2. `GET /api/spot-the-fake*/rounds` reads that game's manifest JSON — a
   pool of candidate real/fake pairs per difficulty tier (`easy`/`medium`/
   `hard`) — and randomly samples a fixed count per tier (`SELECT_COUNTS =
   [("easy", 4), ("medium", 2), ("hard", 1)]`), always served in that tier
   order. This means two participants back to back (or the same participant
   hitting "Play Again") see a different set of rounds each time, so
   answers can't be memorized by watching someone else play.
3. All scoring, round progression, and the reveal happen **client-side** in
   the page's JS once the round data is fetched. The server is otherwise
   stateless per request — no session, no participant identity, no score
   ever stored server-side (aside from the login gate's session flag, see
   §4).

### 2.2 Content model

Manifests are plain JSON, one file per game, structured as a pool per
difficulty tier. Placeholder content (synthetic tones, geometric patterns,
solid colors) ships by default so the app is fully playable with zero setup.
Swapping in real content is a matter of dropping media files into
`app/static/spot_the_fake*/` and adding matching manifest entries — see
`app/content/README.md` for the exact schema and sourcing guardrails
(notably: no deepfakes of real, named public figures without consent — see
that file for the reasoning and the safe alternatives).

---

## 3. Deployment topologies

This app runs in three distinct shapes, all from the same codebase, chosen
per `deploy/*` config rather than per branch:

| | Local / native | Mini-PC (Docker) | AWS (public) |
|---|---|---|---|
| Entry point | `scripts/run-native.sh` | `deploy/compose.yaml` | `deploy/aws/compose.aws.yaml` |
| Reachable from | `127.0.0.1` only | `127.0.0.1` only | the public internet |
| TLS | none (loopback) | none (loopback) | Caddy, automatic Let's Encrypt |
| Passcode gate | off (`SITE_PASSCODE` unset) | off | **on** |
| Use case | development, content-loading iteration | in-person kiosk booth | staff access from anywhere, on your own schedule |

### 3.1 Local / native

`scripts/run-native.sh` creates a `.venv/`, installs `requirements-app.txt`
(just Flask), and runs `python app.py`, binding to `127.0.0.1:8080` by
default (`CYBERVOICE_BIND` env var overrides this). This is the fast
iteration loop — restarting picks up manifest/media changes immediately, no
rebuild step. This is also the default in-person kiosk booth path: bring a
laptop, run this, point a kiosk browser at `127.0.0.1:8080`.

### 3.2 Mini-PC / Docker (local only)

`deploy/compose.yaml` builds `deploy/Dockerfile` (plain `python:3.12-slim`
+ Flask, nothing else) and publishes the container's port **only to
`127.0.0.1`** on the host (`ports: ["127.0.0.1:8080:8080"]`). The container
runs `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges` — hardening
appropriate for a machine left semi-unattended at a physical booth, even
though there's no sensitive data involved anymore. This compose file has no
public-network path by design; it is not the file used for the AWS
deployment.

### 3.3 AWS (public, current live deployment)

The one path that's actually reachable from the public internet, currently
live at `https://cyberroom.periadhityan.com`. See §5 for the full
provisioning walkthrough (also captured in the AWS Public Deployment Guide
project doc); this section is the architecture summary.

```
Internet
   |
   v
Route 53 (A record: cyberroom.periadhityan.com -> Elastic IP)
   |
   v
EC2 instance (t4g.micro, Ubuntu 26.04 LTS, ap-southeast-1)
  Elastic IP: stable across stop/start cycles
  Security group: inbound 22 (SSH, restricted to admin IP), 80, 443 only
   |
   v
Docker Compose (deploy/aws/compose.aws.yaml)
  +-- caddy (caddy:2-alpine)
  |     publishes 80/443 to the instance's network interface
  |     terminates TLS (automatic Let's Encrypt cert + renewal)
  |     reverse-proxies everything to the app container over the
  |     internal compose network -- never exposed to the host or public
  |
  +-- cybervoice (built from deploy/Dockerfile)
        expose: 8080 (internal to the compose network only, no host
        port published -- unreachable except through Caddy)
        SITE_PASSCODE / FLASK_SECRET_KEY injected from deploy/aws/.env
        read_only root fs, cap_drop ALL, no-new-privileges (same
        hardening as the mini-PC path)
```

Key design choice: **`deploy/aws/compose.aws.yaml` is a separate file from
`deploy/compose.yaml`**, not a variant of it. Running the AWS compose file
is the only way anything in this repo opens a port to the public internet
— that's deliberate, so "am I exposing this publicly" is never an implicit
side effect of the wrong flag, it's a distinct, explicitly-named file you
have to choose to run.

**Start/stop, not always-on.** The instance is started before an activity
and stopped after (`scripts/aws/start.sh` / `stop.sh`, wrapping `aws ec2
start-instances` / `stop-instances`), rather than running continuously.
Because the Elastic IP stays associated with the instance across stop/start,
DNS never needs to change between cycles — `start.sh` just waits for the
instance to become reachable and Docker's `restart: unless-stopped` brings
the containers back up on their own. Stopped, the only ongoing cost is a few
cents of EBS storage plus the standard AWS-wide ~$3.60/month public-IPv4
charge on the Elastic IP (applies to any allocated public IP account-wide
since 2024, regardless of instance state) — no compute charge at all until
it's started again.

---

## 4. Security model

### 4.1 Access control: the shared passcode gate

`app/app.py` implements a `before_request` hook (`require_passcode`) that
gates every route except `/login`, `/static/*`, and `/health` behind a
session cookie, when `SITE_PASSCODE` is set:

- **Disabled entirely when `SITE_PASSCODE` is unset** — this is the default
  for local/native and mini-PC deployment, so development and the in-person
  kiosk path are never accidentally gated behind a passcode nobody at the
  booth knows.
- **Comparison is timing-safe** (`hmac.compare_digest`), avoiding a timing
  side-channel on the passcode check.
- **Session cookie** is signed with `FLASK_SECRET_KEY` (falls back to a
  fresh random key per process start if unset — fine for local dev where
  the gate is off anyway; set explicitly in the AWS deployment so sessions
  survive an app restart instead of silently logging everyone out).
- Cookie flags: `HttpOnly` always; `SameSite=Lax`; `Secure` is set
  **exactly when** `SITE_PASSCODE` is set — this doubles as "only require
  HTTPS for the cookie when we're actually in the deployment that has
  HTTPS," so the cookie isn't silently dropped on a plain-HTTP local run.

**What this gate is, and isn't.** It's a light barrier to keep the public
URL from being casually crawled, indexed, or stumbled into — not a
security boundary protecting sensitive data (there isn't any: no PII, no
participant data, all content is either placeholder or non-identity
AI-vs-real material per the content guardrails in `app/content/README.md`).
Known limitations worth being aware of, not currently implemented:

- No rate limiting or lockout on `/login` — a scripted brute-force attempt
  against a short/weak passcode isn't currently slowed down. Mitigate by
  picking a real passphrase, not a short PIN, and treat this as acceptable
  given there's nothing sensitive behind it.
- One shared passcode for everyone, not per-user — anyone with it can share
  it further. Fine for this use case; wouldn't be appropriate if the
  content ever became genuinely sensitive.

### 4.2 Secrets handling

Two secrets exist, both only in the AWS deployment (local/mini-PC don't set
them):

| Secret | Where it lives | Never committed because |
|---|---|---|
| `SITE_PASSCODE` | `deploy/aws/.env` on the EC2 instance | `.env` is gitignored (`deploy/aws/.env`) |
| `FLASK_SECRET_KEY` | same `.env` file | same |
| `INSTANCE_ID` / `AWS_REGION` | `deploy/aws/config.env` on your Mac | not a secret, but account-specific — gitignored so it doesn't leak into a public/shared repo history by habit |

The repo ships `.example` versions of both (`config.env.example`) with
placeholder values, so the real files are a one-time local copy-and-fill,
never tracked.

### 4.3 Network exposure

- EC2 security group allows inbound **22** (SSH, restricted to the admin's
  IP), **80**, and **443** only. Port 8080 (the app itself) is never opened
  in the security group — it's `expose`d to the Docker Compose network only,
  reachable exclusively through the Caddy container.
- Caddy handles all public-facing TLS termination and automatic certificate
  issuance/renewal (Let's Encrypt, HTTP-01 challenge over port 80).
  Certificates persist in a named Docker volume (`caddy_data`) across
  container restarts, so a start/stop cycle doesn't force re-issuance.
- SSH access uses a dedicated key pair (`Cyberroom.pem`), not password auth.
- The GitHub PAT used to clone the private repo onto the EC2 instance is
  scoped to **Contents: Read-only** on this one repository — it cannot push,
  open PRs, or touch anything outside this repo.

### 4.4 Container hardening

Both the mini-PC and AWS deployments run the app container with:

- `read_only: true` — root filesystem is read-only; only `/tmp` is writable
  (mounted as an anonymous volume).
- `cap_drop: [ALL]` — no Linux capabilities beyond the bare minimum.
- `security_opt: [no-new-privileges:true]` — blocks privilege escalation
  via setuid binaries inside the container.

This is meaningful hardening for a container that's reachable from the
public internet (AWS) or left semi-unattended at a physical booth (mini-PC),
even though the app itself doesn't handle sensitive data.

### 4.5 What's deliberately out of scope

- **No WAF, no rate limiting at the edge, no DDoS protection** beyond
  whatever AWS provides by default at the network level. Acceptable for a
  low-traffic internal training tool with no sensitive data; would need
  revisiting if this were ever repurposed for something higher-stakes.
- **No automated OS patching** on the EC2 instance (no `unattended-upgrades`
  configured) — patch it manually (`sudo apt update && sudo apt upgrade -y`)
  periodically, especially before a start-up after a long stopped period.
- **No monitoring/alerting** (no CloudWatch alarms, no uptime check) — the
  instance being down is only discovered by someone trying to load the site.
  Reasonable given the start/stop-on-demand model already means it's
  *expected* to be down most of the time.

---

## 5. Provisioning the AWS deployment from scratch

Full step-by-step (console screenshots, exact CLI commands, troubleshooting)
lives in the **AWS Public Deployment Guide** project doc. Summary of the
one-time setup, for reference:

1. Push the app code (passcode gate + `deploy/aws/*` already in this repo).
2. Launch an EC2 instance (Ubuntu LTS, arm64, `t4g.micro`), security group
   allowing 22/80/443 only.
3. Allocate + associate an Elastic IP.
4. Point a Route 53 A record at it.
5. SSH in, install Docker Engine.
6. Clone the repo (GitHub PAT, Contents:Read-only), create `deploy/aws/.env`
   with `SITE_PASSCODE` and `FLASK_SECRET_KEY`.
7. `docker compose -f deploy/aws/compose.aws.yaml up -d --build`.
8. Save `deploy/aws/config.env` locally (`INSTANCE_ID`, `AWS_REGION`) so
   `scripts/aws/start.sh` / `stop.sh` work going forward.

Day-to-day, only step 8's two scripts are needed — everything else is
one-time.

---

## 6. Repository layout

```
app/
  app.py                     Flask app + passcode gate
  spot_the_fake*.py          Three game blueprints
  content/                   Manifests + content README
  static/, templates/        Frontend assets

deploy/
  Dockerfile                 Shared image build (all deployment paths)
  compose.yaml                Local/mini-PC -- loopback-only, no public exposure
  aws/
    compose.aws.yaml          AWS -- the only compose file with public ports
    Caddyfile                 Reverse proxy + automatic HTTPS config
    config.env.example        Template for the local start/stop scripts' config

scripts/
  run-native.sh               Local dev / kiosk entry point
  verify-offline.sh           Confirms the app works with no network dependency
  generate_placeholder_content.py   Regenerates the default placeholder pools
  aws/
    start.sh, stop.sh         Day-to-day EC2 start/stop, wrapping the AWS CLI

requirements-app.txt          Just Flask
README.md                     Quick start
ARCHITECTURE.md               This document
```

---

*Written 18 August 2026, after the AWS deployment went live, to consolidate architecture, deployment, and security documentation that had been spread across several planning docs into one current, authoritative reference.*
