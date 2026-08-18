#!/usr/bin/env bash
set -euo pipefail
cd ~/Repos/CyberVoiceStation

mkdir -p deploy/aws scripts/aws

echo "-- rewriting app/app.py (adds the shared-passcode gate) --"
cat > app/app.py <<'EOF'
from __future__ import annotations

import hmac
import os
import secrets

from flask import Flask, jsonify, redirect, render_template, request, session, url_for

from spot_the_fake import bp as spot_the_fake_bp
from spot_the_fake_image import bp as spot_the_fake_image_bp
from spot_the_fake_video import bp as spot_the_fake_video_bp


# SITE_PASSCODE gates the whole site behind a single shared passcode when set
# (intended for the public AWS deployment). Leave it unset for local/native
# development -- the gate is simply disabled and every route is open, same
# as before this feature existed.
SITE_PASSCODE = os.environ.get("SITE_PASSCODE", "")

app = Flask(__name__)
app.config["JSON_SORT_KEYS"] = False
# A real secret is required for session cookies to be trustworthy once the
# passcode gate is in use. Falls back to a fresh random key per process start
# if none is set -- fine for local dev (no gate active anyway); set
# FLASK_SECRET_KEY explicitly wherever SITE_PASSCODE is also set, so sessions
# survive an app restart instead of logging everyone out.
app.secret_key = os.environ.get("FLASK_SECRET_KEY") or secrets.token_hex(32)
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
# Only mark cookies Secure (HTTPS-only) when the gate is actually active --
# that's the signal this is the real deployment sitting behind HTTPS, not a
# plain-HTTP local/native run where a Secure cookie would just never stick.
app.config["SESSION_COOKIE_SECURE"] = bool(SITE_PASSCODE)

app.register_blueprint(spot_the_fake_bp)
app.register_blueprint(spot_the_fake_video_bp)
app.register_blueprint(spot_the_fake_image_bp)

# Endpoints reachable without having entered the passcode.
EXEMPT_ENDPOINTS = {"login", "login_submit", "static", "health"}


@app.before_request
def require_passcode():
    if not SITE_PASSCODE:
        return None  # gate disabled entirely (local/native dev)
    if request.endpoint in EXEMPT_ENDPOINTS:
        return None
    if session.get("authed"):
        return None
    return redirect(url_for("login", next=request.path))


@app.get("/login")
def login():
    return render_template("login.html", error=False)


@app.post("/login")
def login_submit():
    submitted = request.form.get("passcode", "")
    if hmac.compare_digest(submitted, SITE_PASSCODE):
        session["authed"] = True
        next_path = request.form.get("next") or "/"
        # Only ever redirect to a local path -- never follow an external URL.
        if not next_path.startswith("/"):
            next_path = "/"
        return redirect(next_path)
    return render_template("login.html", error=True), 401


@app.get("/")
def home():
    return render_template("home.html")


@app.get("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    # CYBERVOICE_BIND defaults to loopback-only for native/local runs.
    # Container deployment sets CYBERVOICE_BIND=0.0.0.0 (see deploy/compose.yaml);
    # the host still only publishes that port to its own loopback interface.
    bind_host = os.environ.get("CYBERVOICE_BIND", "127.0.0.1")
    app.run(host=bind_host, port=8080, debug=False, threaded=False)
EOF

echo "-- adding app/templates/login.html --"
cat > app/templates/login.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Cybersecurity Awareness Month 2026</title>
  <link rel="icon" type="image/svg+xml" href="/static/favicon.svg">
  <link rel="stylesheet" href="/static/style.css">
</head>
<body>
  <div class="floaty-icons" aria-hidden="true">
    <span class="floaty-icon" style="left:10%; animation-duration:19s; animation-delay:1s;">🔒</span>
    <span class="floaty-icon" style="left:35%; animation-duration:23s; animation-delay:5s;">🛡️</span>
    <span class="floaty-icon" style="left:60%; animation-duration:17s; animation-delay:9s;">🔑</span>
    <span class="floaty-icon" style="left:85%; animation-duration:21s; animation-delay:3s;">🔍</span>
  </div>

  <main class="shell">
    <section class="card" id="loginCard">
      <p class="eyebrow">CYBERSECURITY AWARENESS MONTH 2026</p>
      <h1>🔒 Enter Passcode</h1>
      <p class="lead">This activity is shared internally for Cybersecurity Awareness Month. Enter the passcode you were given to continue.</p>

      {% if error %}
      <div class="tips">
        <p>That passcode didn't match. Double-check it and try again.</p>
      </div>
      {% endif %}

      <form method="post" action="/login">
        <input type="hidden" name="next" value="{{ request.args.get('next', '/') }}">
        <label for="passcode" class="eyebrow" style="display:block; margin-bottom:8px;">PASSCODE</label>
        <input
          type="password"
          id="passcode"
          name="passcode"
          autocomplete="off"
          autofocus
          required
          style="width:100%; padding:16px 18px; font-size:18px; border-radius:14px; border:2px solid var(--card-border); background:rgba(255,255,255,0.06); color:#f5f3ff;">
        <button type="submit">CONTINUE</button>
      </form>
    </section>
  </main>

  <footer>
    Cybersecurity Awareness Month 2026 &middot; Pause. Think. Report.
  </footer>
</body>
</html>
EOF

echo "-- adding deploy/aws/config.env.example --"
cat > deploy/aws/config.env.example <<'EOF'
# Copy this file to config.env (same directory) and fill in the real values.
# config.env is gitignored -- these are account-specific, not something to commit.

AWS_REGION=ap-southeast-1
APP_RUNNER_SERVICE_ARN=arn:aws:apprunner:REGION:ACCOUNT_ID:service/cyberroom/SERVICE_ID
EOF

echo "-- adding scripts/aws/apprunner-start.sh --"
cat > scripts/aws/apprunner-start.sh <<'EOF'
#!/usr/bin/env bash
# Brings the public site back up before an activity.
# One-time setup: see deploy/aws/config.env.example, and the AWS Deployment
# Guide project doc for how APP_RUNNER_SERVICE_ARN is created in the first place.
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Resuming App Runner service..."
aws apprunner resume-service \
  --region "$AWS_REGION" \
  --service-arn "$APP_RUNNER_SERVICE_ARN" \
  --query 'Service.Status' --output text

echo "Waiting for it to become RUNNING (this can take a minute or two)..."
while true; do
  status=$(aws apprunner describe-service \
    --region "$AWS_REGION" \
    --service-arn "$APP_RUNNER_SERVICE_ARN" \
    --query 'Service.Status' --output text)
  echo "  status: $status"
  [ "$status" = "RUNNING" ] && break
  [ "$status" = "PAUSED" ] && { echo "Still paused -- something didn't take, check the AWS console."; exit 1; }
  sleep 5
done

echo "-- site is live --"
EOF
chmod +x scripts/aws/apprunner-start.sh

echo "-- adding scripts/aws/apprunner-stop.sh --"
cat > scripts/aws/apprunner-stop.sh <<'EOF'
#!/usr/bin/env bash
# Takes the public site down when it's not needed, so it stops incurring
# App Runner compute charges. The service definition (image, env vars, custom
# domain mapping) is preserved while paused -- apprunner-start.sh brings it
# straight back without redoing any setup.
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG="$PROJECT/deploy/aws/config.env"

if [ ! -f "$CONFIG" ]; then
  echo "Missing $CONFIG -- copy deploy/aws/config.env.example to config.env and fill in the real values first." >&2
  exit 1
fi
source "$CONFIG"

echo "Pausing App Runner service..."
aws apprunner pause-service \
  --region "$AWS_REGION" \
  --service-arn "$APP_RUNNER_SERVICE_ARN" \
  --query 'Service.Status' --output text

echo "-- site is paused, no compute charges while it's down --"
EOF
chmod +x scripts/aws/apprunner-stop.sh

echo "-- updating .gitignore --"
if ! grep -qxF "deploy/aws/config.env" .gitignore 2>/dev/null; then
  printf '\n# --- AWS deployment config (account-specific, not for git) ---\ndeploy/aws/config.env\n' >> .gitignore
fi

echo "-- staging and committing --"
git add -A
git status --short
git commit -m "Add shared-passcode gate and AWS App Runner start/stop scripts"
git push
echo "-- done --"