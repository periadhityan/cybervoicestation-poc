# Content source for Cyberroom

The questions for **Spot the Phish** and **Snapshot or Fake Shot?** live here as plain files. There is no list to
edit by hand: put files in the right folder, run the build, and the game picks them up. (Reel or Real keeps its cases in
`Cyberroom/reel-or-real/rounds.js` and `add-questions.js`.)

```
content-source/
  email/
    easy/     round-id-real.json  round-id-fake.json  notes.json  assets/*.svg
    medium/   ...
    hard/     ...
  image/
    easy/     round-id-real.jpg   round-id-fake.jpg   notes.json
    medium/   ...
    hard/     ...
```

After any change, rebuild the site (this regenerates `Cyberroom/content/content.js` and copies the photos in):

```bash
python3 tools/build_static_site.py                 # refresh Cyberroom/content/
python3 tools/build_static_site.py --zip           # also dist/Cyberroom.zip
python3 tools/build_static_site.py --single-file   # also dist/Cyberroom.html
```

## Adding a pair

Put two files in the right `<email|image>/<easy|medium|hard>/` folder, named `<round-id>-real.<ext>` and
`<round-id>-fake.<ext>` (`json` for email, `jpg` or `png` for photos). The id can be anything filesystem-safe as long as
it matches on both files. A pair with only one file is skipped. For photos, `tools/make_photo_pair.py` resizes and
names a real photo and its AI twin for you. Photos are not kept in git (the big originals stay on your machine);
notes, emails and the SVG pictures are.

## notes.json

One per tier folder. Only the ids you want to describe need an entry:

```json
{
  "round-id": {
    "subject_label": "What the player sees above the pair",
    "reveal_note": "What gave the fake away (one or two sentences)",
    "what_you_can_do": "The tip on the answer screen",
    "techniques": ["Urgency", "Lookalike domain"],
    "red_flags": ["short sentences for the Phish bank"]
  }
}
```

`techniques` and `red_flags` are used by the Phish bank (emails only). `what_you_can_do` replaces the station's generic tip.

## The email format

Each email is a JSON file. Fields:

```json
{
  "from_name": "Meridian IT Help Desk",
  "from_email": "support@meridian-it-helpdesk.com",
  "to": "j.alvarez@meridianfreight.com",
  "subject": "URGENT: Your password expires in 24 hours",
  "date": "Mon, Sep 1, 2026 8:42 AM",
  "body": "Dear Employee,\n\nOur records indicate ...",
  "link_text": "Verify My Password Now",
  "link_url": "http://meridian-it-helpdesk-secure.com/verify?id=8827",
  "attachment_name": "Invoice_DS-88213.pdf.exe",
  "banner": "assets/it-password-reset-fake-banner.svg",
  "images": [{"src": "assets/invoice-image-fake-invoice.svg", "alt": "Image of an invoice notice"}],
  "qr": {"src": "assets/singpost-locker-fake-qr.svg", "caption": "Scan to pay $2.40", "alt": "A QR code"},
  "landing": {"src": "assets/ms365-signin-fake-landing.svg", "alt": "The fake sign-in page the link opens"}
}
```

`from_name`, `from_email`, and `subject` are required (`body` may be empty for an image-only email). `to`,
`date`, `link_text`/`link_url` (a pair -- include both or neither), `attachment_name`, and the
picture fields below are all optional and simply don't render if omitted. The
game deliberately shows the link's real destination next to it (as a
"Link goes to:" line, since hover tooltips don't work on a touchscreen
kiosk) -- that mismatch between link text and destination is one of the
core phishing tells this game teaches, so make it count in your fake
rounds' `link_url`.

**Phone view and red flags.** Add `"format": "mobile"` to *both* emails of a pair to show them as they look in a phone's
mail app: the sender address is shown under the name, links show as coloured text with no address,
and the screen is narrow. Add a `flags` list to the *fake* email to number its giveaways on the answer screen:
`{ "on": "from_email", "mark": "micros0ft-support-center.com", "text": "Not microsoft.com (zero for o)" }`. `on` is the
field (`from_name`, `from_email`, `subject`, `body`, `link_text`, `link_url`, `attachment_name`, or a picture:
`banner`, `qr`, `images`); `mark` is the exact words to highlight (omit it to flag the whole field or picture). **Keep it to
3-4 flags, each `text` at most 30 characters so it stays on one line**; the build warns if not.

**Text messages and QR signs.** Two more `"format"` values turn a pair into something that is not an email.
`"sms"`: `from_name` is the sender the phone shows (a name like `DBS`, or a number), `date` is `"Today 9:41 AM"`, and `body` is the
text with its link written out in full; `subject` is just a preview for the bank. `"qr"`: a sign, sticker or card in the real world.
`from_name` is where it is, `subject` the headline, `body` the small print, `printed_url` the line printed under the code,
`scan_url` where the QR really leads (shown on the answer screen for the fake), `qr` the picture and caption, and `sticker`
(`1` or `2` for a more obvious one) draws it stuck over another sign. Flags on these use `from_name`, `subject`, `body`,
`printed_url` or `qr` for `on`. The game calls them messages and signs instead of emails, and a "Which kind is it?"
mix is chosen automatically.

**The picture fields.** `banner` is a header image shown at the top of the message; `images` are inline
pictures (an image-only phishing email has an empty `body` and one image); `qr` is a QR code with a caption;
`landing` is a screenshot of the page the link opens -- it's not shown in a round, only in the Phish bank's
full-email viewer under "Where the link goes". Paths are relative to the email's tier folder
(`content-source/email/<tier>/assets/`). Keep the real and fake emails of a pair similar in length, or the
longer one will force the text smaller (the build is checked so every pair fits on screen).

**`notes.json` for emails** takes the usual `subject_label` and `reveal_note`, plus:
`techniques` (short tags such as "Urgency", "QR code", shown in the Phish bank), `red_flags` (a list of the
fake's giveaways, also shown in the bank) and `what_you_can_do` (the tip on the answer screen).

**Making the pictures.** `tools/make_phish_assets.py` generates all of the SVG assets (needs
`pip install segno`; only for generating, not for running the game). Nothing in them reproduces a real logo --
banners are plain wordmarks, and the "fake" ones are deliberately blurry or mis-spelt. **QR codes always
encode a harmless training message, never a web address**: people will scan them with their phones.

**Content and real brands.** A handful of pairs use an invented company ("Meridian Freight Co."). Most of the rest (Microsoft, Amazon, PayPal, Apple, DBS, ...) imitate real brands' *genuine
sender domains* for the real emails, and sloppy lookalike domains for the phishing ones -- as awareness
training does -- but all the text is invented, the links are plain text and never clickable, and no
real person is named. Because they name real companies, **get Comms/Legal sign-off before showing them
publicly**, the same as for any named-company case. Replace them with invented companies if you prefer.


## How many pairs you need

A game uses 4 easy, 2 medium and 1 hard pair. The more pairs in each tier, the less often a player sees a repeat. The game
also remembers what a player has just seen and mixes the four kinds (desktop email, phone email, text message, QR sign)
in every game. See `Cyberroom/README.md` for the full picture.
