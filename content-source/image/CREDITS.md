# Photo game: where the new pairs came from

The 13 original pairs (`handshake`, `laptop-typing`, `meeting-room`, `phone-call`, `server-room`,
`video-call`, `doc-review`, `id-badge`, `wifi-router`, `two-factor-auth`, `fingerprint-scan`,
`suspicious-email`, `usb-drive`) were supplied separately; their sources are not recorded here.

The 8 pairs below were built in October 2026, **real photo first**: a real photo was chosen, then the AI
image was generated to match its scene. Every real photo is **CC0 (public domain dedication)**, so no
credit is required, but the source is listed so it can be checked. Every AI image was generated with
Midjourney (V8, `--style raw`, 3:2) on the project owner's own subscription.

Both halves of each pair were normalised with `scripts/make_photo_pair.py` (same crop, same 960x640 size, same
JPEG quality, metadata removed), so the files themselves give nothing away.

| Pair (id) | Tier | Real photo (CC0) | Midjourney job |
|---|---|---|---|
| `patch-panel` | medium | "Free networking cables image", rawpixel, https://www.rawpixel.com/image/5927889/photo-image-background-public-domain-technology | `1a5fe9f7-86b7-4dba-a43e-defeb36fb818`, variant 0 |
| `phone-desk` | medium | "Notebook phone table" by Markus Spiske, rawpixel, https://www.rawpixel.com/image/432066/free-photo-image-business-phone-cc0 | `f76fe098-0e6a-466a-ab5a-46b9ddce1220`, variant 1 |
| `whiteboard-diagram` | medium | "Whiteboard Webdesign" by Christina Morillo, StockSnap, https://stocksnap.io/photo/whiteboard-webdesign-NUEH6AWK1X | `756afbce-69c7-4c5a-894e-83ce8185e258`, variant 0 |
| `sticky-note` | medium | "Keyboard Office" by Jeffrey Betts, StockSnap, https://stocksnap.io/photo/keyboard-office-T1TZOD06JS | `bb7e5a8c-cf4f-4a59-bf9d-c76160f54afa`, variant 0 |
| `cafe-laptop` | hard | "Laptop Typing" by Kristin Hardwick, StockSnap, https://stocksnap.io/photo/laptop-typing-QMVJ5SY2UG | `336708a8-3420-4f9a-a68e-b47a0b90d798`, variant 2 |
| `two-monitor-desk` | hard | "Apple MacMini aesthetic workspace multi-screens", rawpixel, https://www.rawpixel.com/image/6111720/photo-image-aesthetic-public-domain-logo | `2820118f-4096-4c36-9a38-6a4777470d25`, variant 0 |
| `security-gates` | hard | untitled station fare gates, rawpixel, https://www.rawpixel.com/image/6056165/free-public-domain-cc0-photo | `5d33d829-080e-4a92-af4b-4950e7300789`, variant 1 |
| `waiting-room` | hard | "Hospital Waiting" by Direct Media, StockSnap, https://stocksnap.io/photo/hospital-waiting-SSDEQHS17S | `3b50e84f-7ebf-4ffe-8552-0f63c540da92`, variant 3 |

(Variants are numbered 0-3 left-to-right, top-to-bottom in the 2x2 grid Midjourney shows for a prompt.)

## Prompts

Each was followed by `--ar 3:2 --style raw`.

- **patch-panel:** photo of a network patch panel in a communications cabinet with neatly connected blue ethernet cables and a network switch, documentary photograph
- **phone-desk:** candid photo of a smartphone lying on an office desk next to a coffee cup, screen showing a text message conversation, natural window light, documentary photograph
- **whiteboard-diagram:** candid photo of a whiteboard in a meeting room with a handwritten network diagram and sticky notes, marker pens in the tray, natural light, documentary photograph
- **sticky-note:** top-down flat lay photo of a yellow sticky note pad with handwriting on the top note, a silver computer keyboard with numeric keypad and a black smartphone on a white desk, soft natural light, documentary photograph
- **cafe-laptop:** candid photo of a person working on a laptop at a cafe table with a cup of coffee, over-the-shoulder view, natural light, documentary photograph
- **two-monitor-desk:** photo of a tidy office desk with two monitors, a keyboard, a mouse, a desk lamp and a notebook, natural light from a window, documentary photograph
- **security-gates:** wide photo of a row of metal security turnstile gates with card readers in a train station concourse, tiled floor, overhead lights, documentary photograph
- **waiting-room:** photo of two people sitting on black chairs in a bright hospital waiting room with large windows, a man in light blue medical scrubs looking at his phone, an older woman in a grey blazer holding a tablet, clean white floor, documentary photograph

## Notes

- The real photos were taken from the sites' 960-1024 px previews (the full-size originals are 4,000-6,000 px
  wide), which is why every new pair is 960x640.
- Some real photos contain incidental brand marks (an Apple monitor, a branded mug). They are ordinary
  stock photographs, not endorsements.
- None of the AI images show real, named people.


## Batch 2 (13 pairs, October 2026): found online, not generated

The 13 pairs below use **ready-made images from the web, with no image generator involved**. The real photo and the
AI image were each picked separately to show the same kind of scene, then both were normalised with
`tools/make_photo_pair.py` (same crop, size and JPEG quality, metadata removed).

- **Real photos:** StockSnap, which publishes its photos under **CC0**, so no credit is required.
- **AI images:** Pixabay, where each is tagged "AI generated" by its uploader and published under the
  **Pixabay Content License** (free for commercial and non-commercial use, no credit required). Which tool made each
  image is not recorded, and nothing was done to them beyond cropping and resizing.
- None of the images show real, named people. Pixabay's licence does not allow implying that a person or brand endorses
  something, so keep these as training material.

| Pair (id) | Tier | Real photo (StockSnap, CC0) | AI image (Pixabay) |
|---|---|---|---|
| `hands-typing` | easy | https://stocksnap.io/photo/typing-working-ARCKFUOEWN | https://pixabay.com/images/id-9083517/ |
| `parcel-handover` | easy | https://stocksnap.io/photo/clipboard-hand-TRKNLIGFAJ | https://pixabay.com/images/id-8988980/ |
| `phone-street` | easy | https://stocksnap.io/photo/man-phone-KNSJXBFYFZ | https://pixabay.com/images/id-8948878/ |
| `woman-laptop` | easy | https://stocksnap.io/photo/woman-working-FTBGHTW6EJ | https://pixabay.com/images/id-8991961/ |
| `cctv-wall` | medium | https://stocksnap.io/photo/concrete-wall-70GQNT6XZM | https://pixabay.com/images/id-8331480/ |
| `empty-meeting-room` | medium | https://stocksnap.io/photo/office-work-FSU5SG0X4U | https://pixabay.com/images/id-8704765/ |
| `booth-laptops` | medium | https://stocksnap.io/photo/meeting-booth-7FLAARLMPI | https://pixabay.com/images/id-9030608/ |
| `woman-train-phone` | medium | https://stocksnap.io/photo/people-woman-K9M8BPV08N | https://pixabay.com/images/id-8523266/ |
| `woman-desk-writing` | medium | https://stocksnap.io/photo/woman-working-VR6GFV0ZO9 | https://pixabay.com/images/id-8779693/ |
| `contractor-cabinet` | hard | https://stocksnap.io/photo/electrician-electricity-3A5FXM89OG | https://pixabay.com/images/id-9143280/ |
| `two-colleagues-talking` | hard | https://stocksnap.io/photo/teamwork-business-TWSAADHX5T | https://pixabay.com/images/id-8582949/ |
| `team-meeting-laptops` | hard | https://stocksnap.io/photo/conferenceroom-meeting-GVUWVKUHZE | https://pixabay.com/images/id-8974303/ |
| `glass-corridor` | hard | https://stocksnap.io/photo/office-interior-NSQTXCLWQ5 | https://pixabay.com/images/id-8983506/ |
