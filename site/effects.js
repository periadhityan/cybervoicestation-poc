/* Visual effects for the Cyber Awareness station: fireworks, confetti, sparkles, and the
 * full-screen "You got phished" takeover. Plain JS, no dependencies, works from file://.
 *
 * Photosensitivity: nothing here flashes more than twice a second (WCAG 2.3.1 allows three). The big
 * "flashes" are slow wipes, not strobes, and no effect repeats a bright flash in quick succession.
 * When Animations are switched off (staff panel) or the computer asks for reduced motion, every
 * effect is skipped or replaced by a still version.
 *
 * Public API (window.FX):
 *   FX.fireworks({ perfect })   fireworks on a dark scrim; `perfect` adds a shield-shaped burst
 *   FX.confetti()               two confetti cannons
 *   FX.sparkle(x, y, opts)      a small burst at screen coordinates
 *   FX.takeover(theme, opts)    "phish" or "ai" full-screen takeover; returns a Promise
 *   FX.stop()                   clear everything (called on every screen change)
 *   FX.sfx, FX.soundEnabled     optional synthesised sound (off unless the staff panel turns it on)
 */
(() => {
  'use strict';
  const doc = document, root = doc.documentElement;
  const reduced = () => root.dataset.motion === 'reduced' || (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
  const rnd = (a, b) => a + Math.random() * (b - a);
  const pick = (arr) => arr[(Math.random() * arr.length) | 0];
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  /* ---------------------------------------------------------------- sound (WebAudio, no files) */
  let actx = null;
  const soundOn = () => !!FX.soundEnabled;
  function ac() {
    if (!actx) { try { actx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { return null; } }
    if (actx.state === 'suspended') actx.resume();
    return actx;
  }
  function tone(freq, dur, type = 'sine', vol = 0.12, when = 0, slideTo = null) {
    if (!soundOn()) return;
    const a = ac(); if (!a) return;
    const t = a.currentTime + when, o = a.createOscillator(), g = a.createGain();
    o.type = type; o.frequency.setValueAtTime(freq, t);
    if (slideTo) o.frequency.exponentialRampToValueAtTime(slideTo, t + dur);
    g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(vol, t + 0.012); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g).connect(a.destination); o.start(t); o.stop(t + dur + 0.05);
  }
  function noise(dur, vol = 0.15, when = 0, lowpass = 1800) {
    if (!soundOn()) return;
    const a = ac(); if (!a) return;
    const n = Math.max(1, Math.floor(a.sampleRate * dur)), buf = a.createBuffer(1, n, a.sampleRate), d = buf.getChannelData(0);
    for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
    const src = a.createBufferSource(), f = a.createBiquadFilter(), g = a.createGain(), t = a.currentTime + when;
    src.buffer = buf; f.type = 'lowpass'; f.frequency.value = lowpass; g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    src.connect(f).connect(g).connect(a.destination); src.start(t);
  }
  const sfx = {
    pop() { tone(660, 0.12, 'triangle', 0.09, 0, 1200); },
    launch() { tone(240, 0.55, 'sine', 0.05, 0, 1400); },
    boom() { noise(0.5, 0.18, 0, 1300); tone(110, 0.4, 'sine', 0.14, 0, 40); },
    crackle() { for (let i = 0; i < 7; i++) noise(0.05, 0.07, 0.1 + i * 0.06 + Math.random() * 0.03, 6000); },
    fanfare() { [523, 659, 784, 1047].forEach((f, i) => tone(f, 0.3, 'square', 0.06, i * 0.13)); tone(1047, 0.7, 'square', 0.06, 0.55); },
    phished() { tone(520, 0.8, 'sawtooth', 0.12, 0, 70); tone(260, 0.8, 'square', 0.07, 0.05, 40); noise(0.3, 0.16, 0, 900); [0.95, 1.3, 1.65].forEach((t) => tone(110, 0.2, 'square', 0.09, t)); },
    fooled() { tone(720, 0.4, 'sawtooth', 0.08, 0, 120); noise(0.25, 0.1, 0.05, 2500); },
  };

  /* ---------------------------------------------------------------- canvas engine */
  const PAL = {
    brand: ['#EE133B', '#ff6b81', '#ffffff', '#FFC24A'],
    gold: ['#FFC24A', '#ffe29a', '#ffffff', '#EE133B'],
    cool: ['#22D3EE', '#a78bfa', '#ffffff', '#4ade80'],
    pop: ['#EE133B', '#1E191A', '#FFC24A', '#22D3EE', '#a78bfa', '#4ade80'],
  };
  let canvas = null, ctx = null, raf = 0, last = 0, W = 0, H = 0, DPR = 1;
  let parts = [], rockets = [], flashes = [], confetti = [], timers = [];
  let scrim = 0, scrimTarget = 0;
  const sprites = new Map();

  function sprite(color) {
    if (sprites.has(color)) return sprites.get(color);
    const c = doc.createElement('canvas'); c.width = c.height = 64;
    const g = c.getContext('2d'), grad = g.createRadialGradient(32, 32, 0, 32, 32, 32);
    grad.addColorStop(0, '#fff'); grad.addColorStop(0.18, color); grad.addColorStop(0.5, color + '66'); grad.addColorStop(1, color + '00');
    g.fillStyle = grad; g.fillRect(0, 0, 64, 64);
    sprites.set(color, c); return c;
  }

  function ensureCanvas() {
    if (!canvas) {
      canvas = doc.createElement('canvas');
      canvas.className = 'fx-canvas';
      canvas.setAttribute('aria-hidden', 'true');
      doc.body.appendChild(canvas);
      ctx = canvas.getContext('2d');
      window.addEventListener('resize', size);
    }
    size();
  }
  function size() {
    if (!canvas) return;
    DPR = Math.min(window.devicePixelRatio || 1, 2);
    W = innerWidth; H = innerHeight;
    canvas.width = Math.round(W * DPR); canvas.height = Math.round(H * DPR);
    canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
  }
  const later = (ms, fn) => { const id = setTimeout(fn, ms); timers.push(id); return id; };
  const busy = () => parts.length || rockets.length || flashes.length || confetti.length || scrim > 0.01 || scrimTarget > 0;

  function start() { if (!raf) { last = performance.now(); raf = requestAnimationFrame(frame); } }

  function frame(now) {
    const dt = Math.min(0.05, (now - last) / 1000); last = now;
    scrim += (scrimTarget - scrim) * Math.min(1, dt * 4);
    ctx.clearRect(0, 0, W, H);
    if (scrim > 0.01) { ctx.fillStyle = `rgba(14,9,12,${scrim.toFixed(3)})`; ctx.fillRect(0, 0, W, H); }

    // rockets rise, leave a spark trail, then explode
    for (let i = rockets.length - 1; i >= 0; i--) {
      const r = rockets[i]; r.t += dt;
      const k = Math.min(1, r.t / r.T), e = 1 - Math.pow(1 - k, 2);
      const px = r.x0 + (r.x1 - r.x0) * e, py = r.y0 + (r.y1 - r.y0) * e;
      if (Math.random() < 0.9) parts.push({ x: px, y: py, vx: rnd(-14, 14), vy: rnd(10, 40), life: 0, ttl: rnd(0.35, 0.6), color: '#ffe29a', size: 1.5, grav: 0, drag: 1, add: true, trail: null });
      ctx.globalCompositeOperation = 'lighter';
      ctx.drawImage(sprite('#ffffff'), px - 7, py - 7, 14, 14);
      if (k >= 1) { explode(px, py, r.palette, r.kind); rockets.splice(i, 1); }
    }

    // particles (fireworks are additive; sparkles are drawn normally)
    for (let i = parts.length - 1; i >= 0; i--) {
      const p = parts[i]; p.life += dt;
      if (p.life >= p.ttl) { parts.splice(i, 1); continue; }
      if (p.shape) {
        if (p.life < p.T) { p.x += p.vx * dt; p.y += p.vy * dt; }
        else if (p.life > p.hold) { p.vy += 120 * dt; p.y += p.vy * dt; }
      } else {
        p.vx *= Math.pow(p.drag, dt * 60); p.vy = p.vy * Math.pow(p.drag, dt * 60) + p.grav * dt;
        p.x += p.vx * dt; p.y += p.vy * dt;
      }
      if (p.trail) { p.trail.push(p.x, p.y); if (p.trail.length > 12) p.trail.splice(0, 2); }
      const a = Math.max(0, 1 - Math.pow(p.life / p.ttl, 2.2)) * (p.twinkle ? 0.6 + 0.4 * Math.sin(p.life * 40 + p.x) : 1);
      ctx.globalCompositeOperation = p.add ? 'lighter' : 'source-over';
      ctx.globalAlpha = a;
      if (p.trail && p.trail.length > 4) {
        ctx.strokeStyle = p.color; ctx.lineWidth = Math.max(1, p.size * 0.7); ctx.beginPath();
        ctx.moveTo(p.trail[0], p.trail[1]);
        for (let j = 2; j < p.trail.length; j += 2) ctx.lineTo(p.trail[j], p.trail[j + 1]);
        ctx.stroke();
      }
      const s = p.size * 3;
      ctx.drawImage(sprite(p.color), p.x - s, p.y - s, s * 2, s * 2);
    }
    ctx.globalAlpha = 1;

    // soft flashes at each explosion (a glow, never a full-screen strobe)
    ctx.globalCompositeOperation = 'lighter';
    for (let i = flashes.length - 1; i >= 0; i--) {
      const f = flashes[i]; f.life += dt;
      if (f.life > f.ttl) { flashes.splice(i, 1); continue; }
      const a = (1 - f.life / f.ttl) * 0.45, r = f.r * (0.6 + 0.8 * (f.life / f.ttl));
      const g = ctx.createRadialGradient(f.x, f.y, 0, f.x, f.y, r);
      g.addColorStop(0, `rgba(255,236,200,${a})`); g.addColorStop(1, 'rgba(255,236,200,0)');
      ctx.fillStyle = g; ctx.fillRect(f.x - r, f.y - r, r * 2, r * 2);
    }

    // confetti
    ctx.globalCompositeOperation = 'source-over';
    for (let i = confetti.length - 1; i >= 0; i--) {
      const c = confetti[i]; c.life += dt;
      c.vx *= Math.pow(0.992, dt * 60); c.vy += 520 * dt; c.vy *= Math.pow(0.985, dt * 60);
      c.x += c.vx * dt + Math.sin(c.life * c.fl) * 24 * dt; c.y += c.vy * dt; c.rot += c.vr * dt;
      if (c.y > H + 40 || c.life > c.ttl) { confetti.splice(i, 1); continue; }
      ctx.save(); ctx.translate(c.x, c.y); ctx.rotate(c.rot); ctx.scale(1, Math.cos(c.life * c.fl * 1.3));
      ctx.fillStyle = c.color; ctx.fillRect(-c.w / 2, -c.h / 2, c.w, c.h); ctx.restore();
    }
    ctx.globalCompositeOperation = 'source-over';

    if (busy()) raf = requestAnimationFrame(frame);
    else { raf = 0; ctx.clearRect(0, 0, W, H); }
  }

  function explode(x, y, palette, kind) {
    const base = Math.min(W, H) * rnd(0.3, 0.46);
    flashes.push({ x, y, r: base * 1.1, life: 0, ttl: 0.45 });
    sfx.boom();
    const mk = (angle, speed, extra) => parts.push(Object.assign({
      x, y, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed, life: 0, ttl: rnd(1.2, 1.9),
      color: pick(palette), size: rnd(1.6, 2.6), grav: 90, drag: 0.972, add: true, trail: [], twinkle: Math.random() < 0.35,
    }, extra));
    if (kind === 'ring') {
      const n = 64, c = pick(palette);
      for (let i = 0; i < n; i++) mk((i / n) * Math.PI * 2, base * 1.05, { color: c, ttl: 1.5 });
    } else if (kind === 'double') {
      for (let i = 0; i < 56; i++) mk((i / 56) * Math.PI * 2, base * 1.1, { color: palette[0] });
      for (let i = 0; i < 36; i++) mk((i / 36) * Math.PI * 2 + 0.1, base * 0.55, { color: palette[2] });
    } else if (kind === 'willow') {
      for (let i = 0; i < 90; i++) mk(rnd(0, Math.PI * 2), rnd(0.2, 0.85) * base, { color: '#FFC24A', ttl: rnd(2.2, 3.2), grav: 150, drag: 0.982, size: 1.5 });
      sfx.crackle();
    } else {
      for (let i = 0; i < 110; i++) mk(rnd(0, Math.PI * 2), Math.sqrt(Math.random()) * base * 1.1);
    }
  }

  function rocket(palette) {
    const x0 = rnd(0.14, 0.86) * W;
    rockets.push({ x0, y0: H + 10, x1: x0 + rnd(-90, 90), y1: rnd(0.16, 0.46) * H, t: 0, T: rnd(0.8, 1.15), palette: palette || pick([PAL.brand, PAL.gold, PAL.cool]), kind: pick(['peony', 'peony', 'ring', 'double', 'willow']) });
    sfx.launch();
  }

  // The project's mascot is a shield: on a perfect score the biggest burst draws one, with a tick inside it.
  const SHIELD = [[0, -1], [0.78, -0.78], [0.84, -0.62], [0.84, 0.05], [0.7, 0.45], [0.42, 0.78], [0, 1], [-0.42, 0.78], [-0.7, 0.45], [-0.84, 0.05], [-0.84, -0.62], [-0.78, -0.78], [0, -1]];
  const TICK = [[-0.4, 0.02], [-0.1, 0.34], [0.44, -0.34]];
  function along(poly, n) {
    const total = poly.slice(1).reduce((a, p, i) => a + Math.hypot(p[0] - poly[i][0], p[1] - poly[i][1]), 0);
    const out = [];
    for (let i = 1; i < poly.length; i++) {
      const a = poly[i - 1], b = poly[i], len = Math.hypot(b[0] - a[0], b[1] - a[1]), cnt = Math.max(1, Math.round((len / total) * n));
      for (let j = 0; j < cnt; j++) out.push([a[0] + ((b[0] - a[0]) * j) / cnt, a[1] + ((b[1] - a[1]) * j) / cnt]);
    }
    return out;
  }
  function shieldBurst(cx, cy) {
    const R = Math.min(W, H) * 0.3, T = 1.1;
    flashes.push({ x: cx, y: cy, r: R * 1.6, life: 0, ttl: 0.7 });
    sfx.boom();
    const add = (pts, colors, size) => pts.forEach(([nx, ny]) => parts.push({
      x: cx, y: cy, vx: (nx * R) / T, vy: (ny * R) / T, life: 0, ttl: T + 0.9 + 1.4, T, hold: T + 0.9, shape: true,
      color: pick(colors), size, add: true, trail: [], twinkle: true,
    }));
    add(along(SHIELD, 110), ['#FFC24A', '#ffe29a', '#ffffff'], 2.4);
    add(along(TICK, 34), ['#ffffff', '#4ade80'], 2.8);
  }

  function fireworks({ perfect = false, duration = 9000 } = {}) {
    if (reduced()) return Promise.resolve();
    stop(); ensureCanvas();
    scrimTarget = 0.78; start();
    later(2800, () => { scrimTarget = 0.52; });   // let the score show through once the show is under way
    let t = 300;
    while (t < duration - 1800) { const at = t; later(at, () => rocket()); t += rnd(380, 740) * (1 - 0.45 * (t / duration)); }
    for (let i = 0; i < 9; i++) later(duration - 1900 + i * 180, () => rocket(pick([PAL.brand, PAL.gold])));   // finale salvo
    if (perfect) {
      later(1000, () => shieldBurst(W * 0.5, H * 0.38));
      later(duration - 3400, () => shieldBurst(W * 0.5, H * 0.4));
      sfx.fanfare();
    } else sfx.fanfare();
    return new Promise((res) => later(duration + 2200, () => { scrimTarget = 0; res(); }));
  }

  function confettiBurst() {
    if (reduced()) return;
    ensureCanvas(); start();
    const cannon = (x, dir) => {
      for (let i = 0; i < 90; i++) later(i * 6, () => {
        const ang = -Math.PI / 2 + dir * rnd(0.18, 0.62), sp = rnd(0.55, 1.15) * H * 1.05;
        confetti.push({ x, y: H + 10, vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp, w: rnd(8, 15), h: rnd(5, 9), rot: rnd(0, 6), vr: rnd(-9, 9), color: pick(PAL.pop), life: 0, ttl: 6, fl: rnd(4, 9) });
      });
    };
    cannon(W * 0.04, 1); cannon(W * 0.96, -1);
    sfx.pop();
  }

  function sparkle(x, y, { count = 34, palette = PAL.pop } = {}) {
    if (reduced()) return;
    ensureCanvas(); start();
    for (let i = 0; i < count; i++) {
      const a = rnd(0, Math.PI * 2), s = rnd(120, 520);
      parts.push({ x, y, vx: Math.cos(a) * s, vy: Math.sin(a) * s - 120, life: 0, ttl: rnd(0.7, 1.2), color: pick(palette), size: rnd(2, 3.4), grav: 700, drag: 0.96, add: false, trail: null });
    }
    sfx.pop();
  }

  let cancelTakeover = null;
  function stop() {
    if (cancelTakeover) cancelTakeover();
    timers.forEach(clearTimeout); timers = [];
    parts = []; rockets = []; flashes = []; confetti = []; scrimTarget = 0; scrim = 0;
    if (canvas && ctx) ctx.clearRect(0, 0, W, H);
  }

  /* ---------------------------------------------------------------- the takeover */
  const FISH = `<svg class="takeover__hook" viewBox="0 0 160 430" aria-hidden="true" focusable="false">
    <line x1="80" y1="0" x2="80" y2="214" stroke="#e9e9e9" stroke-width="3"/>
    <g class="takeover__swing">
      <path d="M80 214 v26 a22 22 0 1 1 -22 -22" fill="none" stroke="#e9e9e9" stroke-width="6" stroke-linecap="round"/>
      <g class="takeover__fish">
        <path d="M80 270 C122 270 130 330 80 372 C30 330 38 270 80 270 Z" fill="#EE133B"/>
        <path d="M80 372 L50 428 L110 428 Z" fill="#c20e2b"/>
        <path d="M46 318 L22 334 L48 346 Z M114 318 L138 334 L112 346 Z" fill="#ff6b81"/>
        <path d="M66 288 l12 12 M78 288 l-12 12" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
        <path d="M92 288 l12 12 M104 288 l-12 12" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
        <path d="M66 318 q14 12 28 0" fill="none" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
      </g>
    </g>
  </svg>`;

  function takeover(theme, o = {}) {
    if (doc.querySelector('.takeover')) return Promise.resolve(false);
    const phish = theme === 'phish', still = reduced();
    const lines = o.lines || [];
    const el = doc.createElement('div');
    el.className = `takeover takeover--${theme}${still ? ' takeover--still' : ''}`;
    el.setAttribute('role', 'alertdialog');
    el.setAttribute('aria-label', `${o.title || 'You got phished'}. ${o.sub || ''} This is a training simulation.`);
    el.innerHTML = `
      ${still ? '' : '<canvas class="takeover__rain" aria-hidden="true"></canvas>'}
      <div class="takeover__scan" aria-hidden="true"></div>
      <div class="takeover__vignette" aria-hidden="true"></div>
      ${phish ? FISH : ''}
      <div class="takeover__main">
        <h1 class="takeover__title" data-text="${esc(o.title)}">${o.title}</h1>
        <p class="takeover__sub">${esc(o.sub)}</p>
      </div>
      <ul class="takeover__log" aria-label="What the attacker just got"></ul>
      <p class="takeover__sim">${esc(o.foot || 'Simulation: nothing was sent. Tap anywhere to continue.')}</p>`;
    doc.body.appendChild(el);

    // falling characters behind everything (red for a phish, cyan for AI)
    let rainTimer = 0;
    const rain = el.querySelector('.takeover__rain');
    if (rain) {
      const rc = rain.getContext('2d'), fs = Math.max(14, Math.round(innerHeight / 46));
      rain.width = innerWidth; rain.height = innerHeight;
      const cols = Math.ceil(innerWidth / fs), drops = Array.from({ length: cols }, () => rnd(-30, 0));
      const chars = phish ? '01ABCDEF$#@%&{}<>/\\+=' : '01░▒▓';
      const col = phish ? '255,45,85' : '34,211,238';
      rainTimer = setInterval(() => {
        rc.fillStyle = 'rgba(8,2,5,.16)'; rc.fillRect(0, 0, rain.width, rain.height);
        rc.font = `${fs}px ui-monospace, Menlo, monospace`;
        drops.forEach((d, i) => {
          rc.fillStyle = `rgba(${col},.55)`; rc.fillText(chars[(Math.random() * chars.length) | 0], i * fs, d * fs);
          if (d * fs > rain.height && Math.random() > 0.975) drops[i] = rnd(-12, 0); else drops[i] += 1;
        });
      }, 70);
    }

    // the log "types" itself in, one line at a time
    const log = el.querySelector('.takeover__log');
    const gap = still ? 0 : o.gap || 430, first = still ? 0 : o.firstLine || 900;
    lines.forEach((ln, i) => setTimeout(() => {
      const li = doc.createElement('li'); li.className = ln.cls || ''; li.textContent = '> ' + ln.t; log.appendChild(li);
      if (soundOn() && !still) tone(ln.cls === 'bad' ? 180 : 320, 0.07, 'square', 0.05);
    }, first + i * gap));

    (phish ? sfx.phished : sfx.fooled)();
    return new Promise((resolve) => {
      let done = false;
      const finish = (cancelled) => {
        if (done) return; done = true;
        clearInterval(rainTimer);
        window.removeEventListener('keydown', onKey, true);
        cancelTakeover = null;
        if (cancelled === true) { el.remove(); resolve(false); return; }
        el.classList.add('takeover--out');
        setTimeout(() => { el.remove(); resolve(true); }, still ? 0 : 380);
      };
      cancelTakeover = () => finish(true);
      const onKey = (e) => { e.stopPropagation(); if (['Enter', ' ', 'Escape'].includes(e.key)) { e.preventDefault(); finish(); } };
      window.addEventListener('keydown', onKey, true);
      el.addEventListener('click', () => finish());
      setTimeout(() => finish(), still ? 2600 : o.hold || 4800);
    });
  }

  const FX = { fireworks, confetti: confettiBurst, sparkle, takeover, stop, sfx, soundEnabled: false, reduced };
  window.FX = FX;
})();
