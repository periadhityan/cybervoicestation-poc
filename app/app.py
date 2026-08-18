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
