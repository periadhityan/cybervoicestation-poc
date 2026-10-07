#!/usr/bin/env python3
"""Generate the picture assets for the phishing-email game (Spot the Phish).

Writes small SVG files next to the email content:

    app/static/content/email/<tier>/assets/<round-id>-<real|fake>-banner.svg    header banner
    app/static/content/email/<tier>/assets/<round-id>-<real|fake>-landing.svg   "where the link goes" page
    app/static/content/email/<tier>/assets/<round-id>-<real|fake>-qr.svg        QR code
    app/static/content/email/<tier>/assets/<round-id>-fake-invoice.svg          image-only email body

SVG keeps them tiny, crisp at any size, and tracked in git (PNG/JPG under content/ is gitignored).
Nothing here reproduces a real company's logo: banners are plain wordmarks in a rough brand colour.
The "fake" versions are deliberately a little off (blurry, mis-spelt, wrong shade) -- those are tells.

QR codes ALWAYS encode a harmless training message, never a web address. People will scan them with
their phones, and a lookalike domain inside a QR code could lead somewhere real.

Run (needs the `segno` package, only for generating -- not needed to run the game):

    pip install segno
    python3 scripts/make_phish_assets.py
"""

from __future__ import annotations

import io
import sys
from pathlib import Path
from xml.sax.saxutils import escape

try:
    import segno
except ImportError:
    sys.exit("This script needs the 'segno' package: pip install segno")

ROOT = Path(__file__).resolve().parent.parent
EMAIL = ROOT / "app" / "static" / "content" / "email"
FONT = "'Segoe UI', 'Helvetica Neue', Helvetica, Arial, sans-serif"
QR_TEXT = ("TRAINING DEMO: this QR code is a prop. In real life you cannot tell where a QR code leads "
           "until after you scan it. Pause. Think. Report.")


def svg(w: int, h: int, body: str, label: str) -> str:
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-label="{escape(label)}">\n{body}\n</svg>\n')


BLUR = '<filter id="b" x="-2%" y="-2%" width="104%" height="104%"><feGaussianBlur stdDeviation="{s}"/></filter>'


# ---------------------------------------------------------------- banners ---
def banner(word: str, tagline: str, bg: str, fg: str, fake: bool) -> str:
    if fake:
        # slightly wrong shade, blurry, squashed and tilted: how a lifted logo often looks
        body = (f'<defs>{BLUR.format(s=1.4)}</defs>'
                f'<g filter="url(#b)"><rect width="640" height="80" fill="{bg}"/>'
                f'<text x="26" y="52" font-family="{FONT}" font-size="30" font-weight="700" fill="{fg}" '
                f'textLength="250" lengthAdjust="spacingAndGlyphs" transform="rotate(-1.2 26 52)">{escape(word)}</text>'
                f'<text x="616" y="48" text-anchor="end" font-family="{FONT}" font-size="13" fill="{fg}" opacity=".8">{escape(tagline)}</text></g>')
    else:
        body = (f'<rect width="640" height="80" fill="{bg}"/>'
                f'<text x="24" y="51" font-family="{FONT}" font-size="30" font-weight="700" fill="{fg}">{escape(word)}</text>'
                f'<text x="616" y="47" text-anchor="end" font-family="{FONT}" font-size="14" fill="{fg}" opacity=".85">{escape(tagline)}</text>')
    return svg(640, 80, body, f"{word} banner")


# ---------------------------------------------------------------- landing pages ---
def landing(url: str, lock: bool, brand: str, accent: str, title: str, fields: list[tuple[str, str, bool]],
            button: str, fake: bool = False, urgent: str = "", note: str = "") -> str:
    W, H = 960, 560
    parts = [f'<rect width="{W}" height="{H}" fill="#dfe3e8"/>',
             f'<rect x="10" y="10" width="{W-20}" height="{H-20}" rx="12" fill="#fff" stroke="#b8bec6"/>',
             f'<rect x="10" y="10" width="{W-20}" height="86" rx="12" fill="#eef0f3"/>',
             '<circle cx="36" cy="34" r="6" fill="#ff5f57"/><circle cx="56" cy="34" r="6" fill="#febc2e"/><circle cx="76" cy="34" r="6" fill="#28c840"/>']
    # address bar: padlock + (not secure) + the real destination, in full
    bar_col = "#1b5e20" if lock else "#b3261e"
    status = "" if lock else "Not secure  "
    parts.append(f'<rect x="100" y="52" width="{W-130}" height="34" rx="17" fill="#fff" stroke="#c6cbd2"/>')
    if lock:
        parts.append('<rect x="120" y="64" width="12" height="10" rx="2" fill="#1b5e20"/>'
                     '<path d="M122 64v-3a4 4 0 0 1 8 0v3" fill="none" stroke="#1b5e20" stroke-width="2"/>')
    else:
        parts.append('<circle cx="126" cy="69" r="7" fill="none" stroke="#b3261e" stroke-width="2"/><rect x="125" y="64" width="2" height="6" fill="#b3261e"/><rect x="125" y="72" width="2" height="2" fill="#b3261e"/>')
    parts.append(f'<text x="146" y="74" font-family="{FONT}" font-size="16" fill="{bar_col}" font-weight="600">{status}</text>')
    off = 146 + (88 if not lock else 0)
    parts.append(f'<text x="{off}" y="74" font-family="{FONT}" font-size="16" fill="#202124">{escape(url)}</text>')
    page_bg = "#f3f4f6"
    parts.append(f'<rect x="10" y="96" width="{W-20}" height="{H-106}" fill="{page_bg}"/>')
    y = 118
    if urgent:
        parts.append(f'<rect x="10" y="96" width="{W-20}" height="34" fill="#c62828"/>'
                     f'<text x="{W/2}" y="119" text-anchor="middle" font-family="{FONT}" font-size="15" font-weight="700" fill="#fff">{escape(urgent)}</text>')
        y = 150
    card_w = 420
    cx = (W - card_w) / 2
    card_h = 70 + 62 * len(fields) + 80
    parts.append(f'<rect x="{cx}" y="{y}" width="{card_w}" height="{card_h}" rx="6" fill="#fff" stroke="#d5d9de"/>')
    word = f'<text x="{cx+28}" y="{y+42}" font-family="{FONT}" font-size="24" font-weight="700" fill="{accent}"'
    if fake:
        word += ' transform="rotate(-1 %d %d)"' % (cx + 28, y + 42)
    parts.append(word + f'>{escape(brand)}</text>')
    parts.append(f'<text x="{cx+28}" y="{y+76}" font-family="{FONT}" font-size="19" font-weight="600" fill="#202124">{escape(title)}</text>')
    fy = y + 96
    for label, value, masked in fields:
        parts.append(f'<text x="{cx+28}" y="{fy+4}" font-family="{FONT}" font-size="12" fill="#5f6368">{escape(label)}</text>')
        parts.append(f'<rect x="{cx+28}" y="{fy+10}" width="{card_w-56}" height="34" rx="3" fill="#fff" stroke="#8a9099"/>')
        shown = "•" * max(len(value), 8) if masked else value
        parts.append(f'<text x="{cx+38}" y="{fy+33}" font-family="{FONT}" font-size="15" fill="#202124">{escape(shown)}</text>')
        fy += 58
    parts.append(f'<rect x="{cx+28}" y="{fy+4}" width="{card_w-56}" height="38" rx="3" fill="{accent}"/>'
                 f'<text x="{W/2}" y="{fy+29}" text-anchor="middle" font-family="{FONT}" font-size="15" font-weight="700" fill="#fff">{escape(button)}</text>')
    if note:
        parts.append(f'<text x="{cx+28}" y="{fy+66}" font-family="{FONT}" font-size="12" fill="#5f6368">{escape(note)}</text>')
    return svg(W, H, "\n".join(parts), f"Web page the link opens: {brand}, {url}")


# ---------------------------------------------------------------- qr ---
def qr() -> str:
    buf = io.BytesIO()
    segno.make(QR_TEXT, error="m").save(buf, kind="svg", scale=5, border=2, dark="#111111", light="#ffffff",
                                         xmldecl=False, svgns=True, nl=False)
    return buf.getvalue().decode("utf-8") + "\n"


# ---------------------------------------------------------------- image-only invoice ---
def invoice() -> str:
    rows = "".join(
        f'<rect x="40" y="{150+i*34}" width="520" height="1" fill="#cfd4da"/>'
        f'<text x="48" y="{174+i*34}" font-family="{FONT}" font-size="14" fill="#333">{escape(a)}</text>'
        f'<text x="552" y="{174+i*34}" text-anchor="end" font-family="{FONT}" font-size="14" fill="#333">{escape(b)}</text>'
        for i, (a, b) in enumerate([("Creative Cloud All Apps (annual)", "$788.00"), ("Stock credits x 10", "$ 49.90"), ("Tax", "$ 0.00")]))
    body = (f'<defs>{BLUR.format(s=0.9)}</defs><g filter="url(#b)">'
            '<rect width="600" height="440" fill="#fff"/><rect width="600" height="64" fill="#FA0F00"/>'
            f'<text x="30" y="42" font-family="{FONT}" font-size="26" font-weight="700" fill="#fff" textLength="130" lengthAdjust="spacingAndGlyphs">Adobe</text>'
            f'<text x="570" y="40" text-anchor="end" font-family="{FONT}" font-size="14" fill="#fff">Billing Center</text>'
            f'<text x="40" y="104" font-family="{FONT}" font-size="22" font-weight="700" fill="#202124">INVOICE IN-48213</text>'
            f'<text x="40" y="128" font-family="{FONT}" font-size="14" fill="#c62828" font-weight="700">PAYMENT FAILED - SERVICE WILL BE STOPPED</text>'
            + rows +
            f'<text x="552" y="290" text-anchor="end" font-family="{FONT}" font-size="18" font-weight="700" fill="#202124">Total due: $837.90</text>'
            '<rect x="150" y="320" width="300" height="48" rx="4" fill="#c62828"/>'
            f'<text x="300" y="351" text-anchor="middle" font-family="{FONT}" font-size="16" font-weight="700" fill="#fff">UPDATE PAYMENT METHOD</text>'
            f'<text x="300" y="404" text-anchor="middle" font-family="{FONT}" font-size="11" fill="#777">Adobe Systems Billing Dept. This message was sent to you becuase your account is overdue.</text></g>')
    return svg(600, 440, body, "Image of an invoice notice with an Update Payment Method button")


# ---------------------------------------------------------------- the pairs ---
MS, DHL, GOOG, EVB, SGP, ADB = "#0F6CBD", "#FFCC00", "#1A73E8", "#F05537", "#E1251B", "#FA0F00"

ASSETS: dict[str, dict[str, str]] = {}   # tier/filename -> svg text


def add(tier: str, name: str, content: str) -> None:
    ASSETS[f"{tier}/{name}"] = content


# 1  Microsoft 365 sign-in alert (easy): urgency, lookalike domain, credential harvesting, blurry logo
add("easy", "ms365-signin-real-banner.svg", banner("Microsoft", "Account security", MS, "#ffffff", False))
add("easy", "ms365-signin-fake-banner.svg", banner("Micros0ft", "SECURITY DEPT.", "#1A5FA8", "#f2f2f2", True))
add("easy", "ms365-signin-real-landing.svg", landing("https://login.microsoftonline.com/common/oauth2/authorize", True, "Microsoft", MS, "Sign in",
     [("Email, phone, or Skype", "j.alvarez@meridianfreight.com", False)], "Next", False, note="Can't access your account?"))
add("easy", "ms365-signin-fake-landing.svg", landing("http://micros0ft-support-center.com/verify/login.php?user=8827", False, "Micros0ft", "#2b6cb0", "Verify your identity !",
     [("Email", "j.alvarez@meridianfreight.com", False), ("Password", "", True), ("Phone number", "", False), ("Recovery email", "", False)], "VERIFY NOW", True,
     urgent="Your account will be DELETED in 09:42"))

# 2  DocuSign (medium): urgency, impersonated colleague, credential harvesting
add("medium", "docusign-review-real-landing.svg", landing("https://account.docusign.com/", True, "DocuSign", "#4C00FF", "Log in",
     [("Email", "j.alvarez@meridianfreight.com", False)], "Continue"))
add("medium", "docusign-review-fake-landing.svg", landing("http://docusign-secure-view.co/doc/view?id=88213", False, "DocuSign", "#4C00FF", "Sign in with your work email to view document",
     [("Work email", "j.alvarez@meridianfreight.com", False), ("Email password", "", True)], "VIEW DOCUMENT", True, urgent="Document access expires in 01:58:12"))

# 3  DHL redelivery (easy): urgency, payment harvesting, lookalike domain
add("easy", "dhl-redelivery-real-banner.svg", banner("DHL EXPRESS", "Excellence. Simply delivered.", DHL, "#D40511", False))
add("easy", "dhl-redelivery-fake-banner.svg", banner("DHI EXPRESS", "Delivery Service", "#FFD21F", "#C8101B", True))
add("easy", "dhl-redelivery-real-landing.svg", landing("https://www.dhl.com/sg-en/home/tracking.html?tracking-id=4821339055", True, "DHL", "#D40511", "Track a shipment",
     [("Tracking number", "4821 3390 55", False)], "Track"))
add("easy", "dhl-redelivery-fake-landing.svg", landing("http://dhl-parcel-release.xyz/pay", False, "DHL", "#D40511", "Pay customs fee $1.99 to release parcel",
     [("Name on card", "", False), ("Card number", "", False), ("Expiry / CVV", "", False)], "PAY NOW", True, urgent="Parcel will be RETURNED in 23:59:11"))

# 4  Google Drive share (medium): credential harvesting; the fake page even has a padlock
add("medium", "gdrive-share-real-landing.svg", landing("https://accounts.google.com/v3/signin/identifier", True, "Google", GOOG, "Sign in",
     [("Email or phone", "j.alvarez@meridianfreight.com", False)], "Next", False, note="Use your Google Account"))
add("medium", "gdrive-share-fake-landing.svg", landing("https://goog1e-docs-viewer.com/d/1x9Fq/open", True, "Google", GOOG, "Sign in to view document",
     [("Email", "j.alvarez@meridianfreight.com", False), ("Password", "", True)], "Sign in", True, note="A padlock only means the connection is encrypted, not that the site is genuine."))

# 5  Event ticket (hard): QR code
add("hard", "eventbrite-ticket-real-banner.svg", banner("eventbrite", "Your order", EVB, "#ffffff", False))
add("hard", "eventbrite-ticket-fake-banner.svg", banner("eventbrlte", "Tickets", "#E8603F", "#fff4f0", True))
add("hard", "eventbrite-ticket-real-qr.svg", qr())
add("hard", "eventbrite-ticket-fake-qr.svg", qr())
add("hard", "eventbrite-ticket-real-landing.svg", landing("https://www.eventbrite.com/orders/48213", True, "eventbrite", EVB, "Log in to view your tickets",
     [("Email", "j.alvarez@meridianfreight.com", False)], "Continue"))
add("hard", "eventbrite-ticket-fake-landing.svg", landing("http://eventbrite-entry-pass.top/revalidate?o=48213", False, "eventbrlte", EVB, "Re-validate your ticket",
     [("Email", "j.alvarez@meridianfreight.com", False), ("Password", "", True)], "RE-VALIDATE", True, urgent="Ticket will be cancelled in 14:52"))

# 6  Parcel locker (medium): QR code, payment harvesting
add("medium", "singpost-locker-real-banner.svg", banner("SingPost", "POPStation", SGP, "#ffffff", False))
add("medium", "singpost-locker-fake-banner.svg", banner("SingP0st", "Parcel Notice", "#D82A20", "#fff0ee", True))
add("medium", "singpost-locker-real-qr.svg", qr())
add("medium", "singpost-locker-fake-qr.svg", qr())
add("medium", "singpost-locker-real-landing.svg", landing("https://www.singpost.com/track-items", True, "SingPost", SGP, "Track your item",
     [("Tracking number", "SP48213390SG", False)], "Track"))
add("medium", "singpost-locker-fake-landing.svg", landing("http://singpost-collect.top/pay/2.40", False, "SingPost", SGP, "Pay $2.40 delivery fee",
     [("Name on card", "", False), ("Card number", "", False), ("Expiry / CVV", "", False)], "PAY NOW", True, urgent="Parcel on hold - pay within 11:59:30"))

# 7  Authority (hard): a "CEO" order to log in
add("hard", "compliance-training-real-landing.svg", landing("https://learn.meridianfreight.com/courses/data-protection", True, "Meridian Freight", "#1F4E79", "Sign in with company SSO",
     [("Work email", "j.alvarez@meridianfreight.com", False)], "Continue with SSO"))
add("hard", "compliance-training-fake-landing.svg", landing("http://meridianfreight-hr.com/compliance", False, "Meridian Freight", "#1F4E79", "Compliance Portal - verify login",
     [("Username", "", False), ("Password", "", True)], "LOGIN", True, urgent="MANDATORY - complete today"))

# 8  Image-only invoice (medium)
add("medium", "invoice-image-real-banner.svg", banner("Adobe", "Order receipt", ADB, "#ffffff", False))
add("medium", "invoice-image-fake-invoice.svg", invoice())


def main() -> int:
    for key, content in sorted(ASSETS.items()):
        tier, name = key.split("/", 1)
        out = EMAIL / tier / "assets"
        out.mkdir(parents=True, exist_ok=True)
        (out / name).write_text(content, encoding="utf-8")
    total = sum(len(c) for c in ASSETS.values())
    print(f"wrote {len(ASSETS)} SVG files ({total // 1024} KB) under app/static/content/email/<tier>/assets/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
