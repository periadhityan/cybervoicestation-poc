/* Cyber Awareness station - settings and wording.
 * Edit this file, then refresh the page. Staff can also change the starred (*)
 * settings on the computer itself: press Shift+S, or press and hold the small
 * "Cyber Awareness" label in the top-left corner for 1.5 seconds.
 *
 * The rounds themselves are NOT here:
 *   - Spot the Phish / Snapshot or Fake Shot: content/content.js, which
 *     scripts/build_static_site.py generates from app/static/content/.
 *   - Reel or Real?: reel-or-real/rounds.js (plus your own in reel-or-real/add-questions.js).
 */
window.CONFIG = {
  title: "Pause. Think. Report.",
  subtitle: "Three quick stations. Can you tell what's real?",
  tagline: "Pause. Think. Report.",
  eyebrow: "Cyber Awareness",          // small label top-left; "" to hide
  logoSrc: "assets/singtel-logo.svg",   // logo shown top-left on every screen; "" to hide
  logoAlt: "Singtel",

  /* Shown on the final screen. Leave "" to hide. */
  reportingLine: "Suspicious? Use the Phish Alert button or your trusted reporting channel.",

  /* Each game: this many rounds of each difficulty, played easy -> hard (a station can set its
   * own gameMix below). If a tier has fewer rounds than this, the game just uses what it has. Points per correct answer
   * are weighted by difficulty and scaled so a perfect game = totalScore. */
  gameMix: { easy: 4, medium: 2, hard: 1 },
  points:  { easy: 10, medium: 15, hard: 20 },
  totalScore: 100,

  timerSeconds: 0,                 // * seconds per round, 0 = no timer (also adjustable on the home screen)
  idleResetSeconds: 90,            // * walk-away reset back to the home screen, 0 = never
  finalAutoResetSeconds: 0,        // final screen returns to home after this many seconds, 0 = stay
  revealAutoAdvanceSeconds: 0,     // 0 = player taps "Next round"

  includeTechnical: false,         // * Reel or Real?: also use cases tagged technical-only
  showSourcesOnReveal: true,       // Reel or Real?: show the source line under Real answers

  /* "Related policy" box on every answer screen. Leave defaultPolicy "" to hide the box. */
  defaultPolicy: "",
  policyLabel: "The policy that protects us",

  theme: "light",                  // * "light" | "dark" | "auto"
  reducedMotion: false,            // * turn off animations

  /* The three stations. Edit the wording freely; keep each `key` as it is
   * (it must match a folder name under app/static/content/). */
  stations: [
    {
      key: "email",
      icon: "mail",
      tag: "Email",
      title: "Spot the Phish",
      sub: "Two emails. One is a phishing attempt.",
      noun: "email",
      fakeNoun: "phishing email",
      question: "Which email is the real one?",
      bankLabel: "Phish bank",         // adds a button on the home screen listing every email pair
      bankKind: "email",
      shield: {
        takeaway: "Looking legitimate is not proof of who sent it.",
        todo: "Check the sender's real address and where the link goes. If it feels rushed or off, report it with the Phish Alert button."
      }
    },
    {
      key: "image",
      icon: "image",
      tag: "Photo",
      title: "Snapshot or Fake Shot?",
      sub: "Two photos. One was generated.",
      noun: "photo",
      fakeNoun: "AI-generated photo",
      question: "Which photo is the real one?",
      bankLabel: "Photo bank",         // adds a button on the home screen that lists every photo pair
      bankKind: "photo",
      shield: {
        takeaway: "A photo is not proof of what happened.",
        todo: "Zoom in on hands, text and reflections. If a photo is part of a request you didn't expect, check it another way first."
      }
    },
    {
      /* mode "single" = one case on screen and two answer tiles (Reel / Real); the others compare two items. */
      key: "reel",
      mode: "single",
      icon: "film",
      tag: "Film or fact",
      title: "Reel or Real?",
      sub: "Film plot or real cyber incident?",
      question: "Film plot or real incident?",
      gameMix: { easy: 5, medium: 2, hard: 1 },
      bankLabel: "Reel or Real bank",
      ratings: [
        { min: 0.85, name: "Reelity Check Master", line: "You can tell the screenplay from the security report. Share what you know with a colleague." },
        { min: 0.60, name: "Threat Spotter",       line: "Sharp instincts. A few plot twists got you; the Control Shields are worth another look." },
        { min: 0.35, name: "Plot Detective",       line: "You're getting warmer. Play again and see which clues tip you off." },
        { min: 0.00, name: "Plot Twist",           line: "The best way to learn is to be surprised. Try another set; the lessons stick." }
      ]
    }
  ],

  ratings: [
    { min: 0.85, name: "Fake-Spotting Pro", line: "You can tell the genuine from the fabricated. Share what you know with a colleague." },
    { min: 0.60, name: "Sharp Eye",         line: "Good instincts. A few fakes slipped past; the Control Shield tips are worth another look." },
    { min: 0.35, name: "Getting Warmer",    line: "You're getting there. Play again and see which tells give the fakes away." },
    { min: 0.00, name: "Fresh Eyes",        line: "Better to be fooled here than at work. Try another round; the tells stick." }
  ]
};
