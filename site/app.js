/* Cyber Awareness station. Plain JS, no dependencies, works from file://.
 * Game engine adapted from the "Reel or Real?" booth project. Two kinds of station:
 *   - "pair" (default): two items, A and B, and the player picks which one is real.
 *   - "single" (Reel or Real?): one case, and the player answers Reel or Real. */
(() => {
  'use strict';

  /* ------------------------------------------------------------------ helpers */
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  // Placeholders such as "[POLICY / STANDARD NAME]" must never reach the screen.
  const clean = (v) => { if (typeof v !== 'string') return ''; const t = v.trim(); return !t || t.startsWith('[') ? '' : t; };
  const shuffle = (a) => { a = a.slice(); for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; } return a; };
  const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);
  const today = () => new Date().toLocaleDateString('en-CA');
  const stage = $('#stage');
  const sr = $('#sr');

  /* ------------------------------------------------------------------ icons */
  const svg = (inner, cls = '') => `<svg class="${cls}" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" focusable="false">${inner}</svg>`;
  const ICON = {
    mail: svg('<rect x="5" y="10" width="38" height="28" rx="4"/><path d="M6 14l18 14 18-14"/>', 'ico'),
    video: svg('<rect x="5" y="10" width="38" height="28" rx="5"/><path d="M20 18l11 6-11 6z" fill="currentColor"/>', 'ico'),
    image: svg('<rect x="5" y="9" width="38" height="30" rx="4"/><circle cx="17" cy="19" r="3.5"/><path d="M7 35l11-10 8 7 6-6 11 10"/>', 'ico'),
    // Film reel: the spokes group spins while the Reel tile is hovered.
    film: svg('<path d="M24 42h20"/><circle cx="24" cy="24" r="18"/><g class="reel-spin"><circle cx="24" cy="14" r="4"/><circle cx="33.5" cy="20.9" r="4"/><circle cx="29.9" cy="32.1" r="4"/><circle cx="18.1" cy="32.1" r="4"/><circle cx="14.5" cy="20.9" r="4"/><circle cx="24" cy="24" r="1.5" fill="currentColor"/></g>', 'ico'),
    file: svg('<path d="M6 15a3 3 0 0 1 3-3h10l4 5h16a3 3 0 0 1 3 3v17a3 3 0 0 1-3 3H9a3 3 0 0 1-3-3z"/><path d="M13 26h14M13 33h8" stroke-width="4"/>', 'ico'),
    shield: svg('<path d="M24 5l15 5.5V22c0 9-6 15.5-15 20C15 37.500 9 31 9 22V10.500z"/><path d="M17 24l5 5 9-10"/>'),
    check: svg('<circle cx="24" cy="24" r="18"/><path d="M15 25l6 6 12-13"/>'),
    cross: svg('<circle cx="24" cy="24" r="18"/><path d="M17 17l14 14M31 17L17 31"/>'),
    doc: svg('<path d="M12 5h17l9 9v29H12z"/><path d="M29 5v9h9"/><path d="M18 24h14M18 31h14M18 38h8"/>', 'doc'),
    clock: svg('<circle cx="24" cy="24" r="18"/><path d="M24 13v11l7 5"/>'),
    arrow: svg('<path d="M10 24h27M27 14l10 10-10 10"/>'),
    home: svg('<path d="M7 22L24 8l17 14"/><path d="M12 19v20h9V29h6v10h9V19"/>'),
    list: svg('<path d="M18 13h22M18 24h22M18 35h22"/><path d="M9 13v0M9 24v0M9 35v0" stroke-width="5"/>'),
    replay: svg('<path d="M10 24a14 14 0 1 0 5-10.700"/><path d="M10 8v9h9"/>'),
    zoom: svg('<circle cx="21" cy="21" r="12"/><path d="M30 30l11 11M15 21h12M21 15v12"/>'),
  };

  /* ------------------------------------------------------------------ persistence (staff settings + anonymous counters) */
  const KEY = 'cyberRoom.station.v1';
  const load = () => { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch (e) { return {}; } };
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify(P)); } catch (e) { /* storage blocked: carry on */ } };
  const P = load();
  P.settings = P.settings || {};
  P.seen = P.seen && typeof P.seen === 'object' && !Array.isArray(P.seen) ? P.seen : {};
  if (!P.stats || P.stats.day !== today()) P.stats = { day: today(), plays: 0, best: 0, bestOf: 0 };

  const CFG = window.CONFIG || {};
  const S = () => Object.assign({}, CFG, P.settings);
  const stations = () => (Array.isArray(CFG.stations) ? CFG.stations : []);
  const stationCfg = (key) => stations().find((s) => s.key === key);
  const isSingle = (key) => (stationCfg(key) || {}).mode === 'single';
  const DIFFS = ['easy', 'medium', 'hard'];
  const diffOf = (r) => (DIFFS.includes(r.tier) ? r.tier : 'medium');

  /* ------------------------------------------------------------------ Reel or Real: add-questions.js merged into ROUNDS, then normalised */
  const addErrs = [];
  function mergeMyQuestions() {
    const list = window.MY_QUESTIONS;
    if (list == null || !Array.isArray(window.ROUNDS)) return;
    if (!Array.isArray(list)) { addErrs.push('add-questions.js: MY_QUESTIONS must be a list: [ ... ].'); return; }
    list.forEach((q, i) => {
      const tag = `add-questions.js, question ${i + 1}${q && q.title ? ` ("${q.title}")` : ''}`;
      if (!q || typeof q !== 'object') { addErrs.push(`${tag}: is not a { ... } block.`); return; }
      const ans = String(q.answer || '').trim().toUpperCase();
      const missing = ['answer', 'title', 'clues', 'reveal', 'year', 'lesson', 'todo'].filter((k) => q[k] == null || q[k] === '');
      if (missing.length) addErrs.push(`${tag}: missing ${missing.map((k) => `"${k}"`).join(', ')}.`);
      if (q.answer && ans !== 'REEL' && ans !== 'REAL') addErrs.push(`${tag}: answer must be "REEL" or "REAL".`);
      if (q.clues != null && (!Array.isArray(q.clues) || q.clues.length < 3 || q.clues.length > 4)) addErrs.push(`${tag}: needs 3 or 4 clues.`);
      window.ROUNDS.push({
        id: q.id || `ADD-${String(i + 1).padStart(2, '0')}`, added: true,
        enabled: q.off !== true, status: q.status || 'draft',
        mystery_title: q.title, answer: ans, difficulty: q.difficulty || 'medium', audience: ['all'], themes: q.themes || [],
        clue: q.hint || '', evidence: q.clues, reveal_title: q.reveal, year: q.year,
        weakness: q.why || '', control_theme: '', control_shield: q.shield || '',
        what_you_can_do: q.todo, takeaway: q.lesson,
        sources: q.source ? [q.source] : [], sensitivity: 'low', policy_reference: q.policy || null,
      });
    });
  }

  // Reel or Real cases use their own field names; map them onto the fields the engine shares with the other stations.
  const normalizeReel = (r) => ({
    mode: 'single', id: r.id, added: !!r.added,
    tier: DIFFS.includes(r.difficulty) ? r.difficulty : 'medium',
    label: r.mystery_title, clue: r.clue || '', evidence: Array.isArray(r.evidence) ? r.evidence : [],
    answer: r.answer, reveal_title: r.reveal_title, year: r.year, weakness: r.weakness || '',
    takeaway: r.takeaway || '', todo: r.what_you_can_do || '', theme: r.control_theme || '',
    sources: Array.isArray(r.sources) ? r.sources : [], policy: r.policy_reference || null,
    status: r.status, enabled: r.enabled !== false, audience: r.audience || ['all'], themes: r.themes || [],
  });
  let REEL = [];

  /* ------------------------------------------------------------------ pools */
  const reelStationKey = () => (stations().find((s) => s.mode === 'single') || {}).key;
  function poolOf(key) {
    if (isSingle(key)) return REEL.filter((r) => r.enabled && (S().includeTechnical || r.audience.includes('all')));
    return window.CONTENT && Array.isArray(window.CONTENT[key]) ? window.CONTENT[key] : [];
  }
  const isPlaceholder = (r) => /placeholder/i.test(r.label || '');
  // Reel or Real's bank lists every case (even hidden ones, greyed out); a photo bank lists every pair.
  const bankCount = (st) => (st.mode === 'single' ? REEL.length : poolOf(st.key).length);
  function openBank(key) {
    state.bankShow = false;
    state.bankKey = key;
    if (isSingle(key)) return go('bank');
    const rank = (r) => DIFFS.indexOf(diffOf(r));
    state.bankOrder = poolOf(key).slice().sort((a, b) => rank(a) - rank(b) || String(a.label).localeCompare(String(b.label)))
      .map((r) => ({ r, realSide: Math.random() < 0.5 ? 'A' : 'B' }));
    go('pbank');
  }

  /* ------------------------------------------------------------------ validation */
  function validate() {
    const errs = addErrs.slice();
    if (!window.CONFIG) errs.push('config.js is missing or has an error.');
    else if (!stations().length) errs.push('config.js has no "stations" list.');
    if (!window.CONTENT) errs.push('content/content.js is missing. Run: python3 scripts/build_static_site.py');
    if (window.ROUNDS != null) {
      if (!Array.isArray(window.ROUNDS)) errs.push('reel-or-real/rounds.js: ROUNDS must be a list.');
      else {
        const ids = new Set();
        window.ROUNDS.forEach((r, i) => {
          const tag = r && r.id ? r.id : `round #${i + 1}`;
          if (r && r.added) { if (ids.has(r.id)) errs.push(`${tag}: duplicate id.`); ids.add(r.id); return; } // checked in mergeMyQuestions
          ['id', 'mystery_title', 'answer', 'evidence', 'reveal_title', 'year', 'takeaway', 'what_you_can_do'].forEach((k) => { if (r[k] == null || r[k] === '') errs.push(`reel-or-real/rounds.js, ${tag}: missing "${k}".`); });
          if (r.answer !== 'REEL' && r.answer !== 'REAL') errs.push(`${tag}: answer must be "REEL" or "REAL".`);
          if (!Array.isArray(r.evidence) || r.evidence.length < 3 || r.evidence.length > 4) errs.push(`${tag}: needs 3 or 4 evidence bullets.`);
          if (ids.has(r.id)) errs.push(`${tag}: duplicate id.`);
          ids.add(r.id);
        });
      }
    }
    if (!errs.length && !stations().some((s) => poolOf(s.key).length)) errs.push('No rounds are available. Run: python3 scripts/build_static_site.py');
    return errs;
  }

  /* ------------------------------------------------------------------ difficulty mix + points */
  function gameMix(key) {
    const m = (stationCfg(key) || {}).gameMix || S().gameMix || {};
    const o = {};
    DIFFS.forEach((d) => (o[d] = Math.max(0, Number(m[d]) || 0)));
    if (!DIFFS.some((d) => o[d])) Object.assign(o, { easy: 4, medium: 2, hard: 1 });
    return o;
  }
  const gameSize = (key) => DIFFS.reduce((a, d) => a + gameMix(key)[d], 0);
  const basePoints = () => Object.assign({ easy: 10, medium: 15, hard: 20 }, S().points || {});
  const maxScore = () => Number(S().totalScore) || 100;

  // Points per round: weighted by difficulty, scaled so a perfect game is exactly totalScore.
  function computePoints(rounds) {
    const pts = basePoints(), totalPts = maxScore();
    const raw = rounds.map((r) => Math.max(0, Number(pts[diffOf(r)]) || 0));
    const sum = raw.reduce((a, b) => a + b, 0) || 1;
    const exact = raw.map((v) => (v * totalPts) / sum);
    const out = exact.map(Math.floor);
    let left = totalPts - out.reduce((a, b) => a + b, 0);
    exact.map((v, i) => [v - Math.floor(v), i]).sort((a, b) => b[0] - a[0]).forEach(([, i]) => { if (left > 0) { out[i]++; left--; } });
    return out;
  }
  const earned = () => state.results.reduce((a, r, i) => a + (r && r.correct ? state.points[i] || 0 : 0), 0);

  /* ------------------------------------------------------------------ round selection */
  // Pair stations: per tier, prefer rounds this computer hasn't shown recently, then fill from the rest.
  function pickPair(key) {
    const pool = poolOf(key), m = gameMix(key);
    const seen = new Set(P.seen[key] || []);
    const picks = [];
    DIFFS.forEach((d) => {
      const tier = pool.filter((r) => diffOf(r) === d);
      const fresh = shuffle(tier.filter((r) => !seen.has(r.id)));
      const stale = shuffle(tier.filter((r) => seen.has(r.id)));
      picks.push(...fresh.concat(stale).slice(0, m[d]));
    });
    return picks;
  }

  // Which side the real item sits on, never the same side three rounds running.
  function assignSides(n) {
    const out = [];
    for (let i = 0; i < n; i++) {
      let s = Math.random() < 0.5 ? 'A' : 'B';
      if (i >= 2 && out[i - 1] === out[i - 2] && s === out[i - 1]) s = s === 'A' ? 'B' : 'A';
      out.push(s);
    }
    return out;
  }

  // Reel or Real: order a game easy -> medium -> hard where possible, never 3 identical answers in a row.
  function orderedSingle(list) {
    const rank = (r) => DIFFS.indexOf(diffOf(r));
    let best = null, bestInv = Infinity;
    for (let t = 0; t < 120; t++) {
      const o = t < 40 ? shuffle(list).sort((a, b) => rank(a) - rank(b)) : shuffle(list);
      if (o.length > 1 && rank(o[0]) === 2 && !o.every((r) => rank(r) === 2)) continue;
      let ok = true;
      for (let i = 2; ok && i < o.length; i++) if (o[i].answer === o[i - 1].answer && o[i].answer === o[i - 2].answer) ok = false;
      if (!ok) continue;
      let inv = 0;
      for (let i = 0; i < o.length; i++) for (let j = i + 1; j < o.length; j++) if (rank(o[i]) > rank(o[j])) inv++;
      if (inv < bestInv) { best = o; bestInv = inv; if (!inv) break; }
    }
    return best;
  }

  // Reel or Real: a balanced draw. About half Reel / half Real, at most 2 per theme, prefers cases not seen recently.
  function pickSingle(key) {
    const pool = poolOf(key), m = gameMix(key), n = gameSize(key);
    const seen = new Set(P.seen[key] || []);
    let best = null, bestScore = -Infinity;
    for (let a = 0; a < 300; a++) {
      const picks = [];
      let short = false;
      DIFFS.forEach((d) => { const c = shuffle(pool.filter((r) => diffOf(r) === d)).slice(0, m[d]); if (c.length < m[d]) short = true; picks.push(...c); });
      if (short) break;
      const o = orderedSingle(picks);
      if (!o) continue;
      const reel = o.filter((r) => r.answer === 'REEL').length;
      const themes = {};
      o.forEach((r) => { const t = r.themes[0] || r.id; themes[t] = (themes[t] || 0) + 1; });
      let score = Object.keys(themes).length;
      if (Object.values(themes).some((c) => c > 2)) score -= 100;
      score -= Math.max(0, Math.abs(reel - (o.length - reel)) - 1) * 60;
      score -= o.filter((r) => seen.has(r.id)).length * 10;
      if (score > bestScore) { bestScore = score; best = o; }
    }
    return best || shuffle(pool).slice(0, n);
  }

  function buildRounds(key) {
    if (isSingle(key)) return pickSingle(key);
    const picks = pickPair(key);
    const sides = assignSides(picks.length);
    return picks.map((r, i) => ({
      mode: 'pair', id: r.id, tier: r.tier, label: r.label, note: r.note, todo: r.todo || '',
      realSlot: sides[i],
      items: sides[i] === 'A' ? { A: r.real, B: r.fake } : { A: r.fake, B: r.real },
    }));
  }

  /* ------------------------------------------------------------------ media (data: URIs from the single-file build become blob URLs so video can seek) */
  const blobCache = new Map();
  function mediaSrc(src) {
    if (typeof src !== 'string' || !src.startsWith('data:')) return src;
    if (blobCache.has(src)) return blobCache.get(src);
    try {
      const comma = src.indexOf(',');
      const mime = src.slice(5, src.indexOf(';'));
      const bin = atob(src.slice(comma + 1));
      const bytes = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
      const url = URL.createObjectURL(new Blob([bytes], { type: mime }));
      blobCache.set(src, url);
      return url;
    } catch (e) { return src; }
  }
  function hydrateMedia() {
    const r = cur();
    if (r && r.items) $$('[data-media]', stage).forEach((el) => { el.src = mediaSrc(r.items[el.dataset.media]); });
    // Photo bank thumbnails: "<pair index>:<A|B>"; the real photo sits on a random side per pair.
    $$('[data-bank]', stage).forEach((el) => {
      const [i, side] = el.dataset.bank.split(':');
      const e = state.bankOrder[Number(i)];
      if (e) el.src = mediaSrc(e.r[e.realSide === side ? 'real' : 'fake']);
    });
  }
  const bankSrc = (idx, side) => { const e = state.bankOrder[Number(idx)]; return e ? mediaSrc(e.r[e.realSide === side ? 'real' : 'fake']) : ''; }

  /* ------------------------------------------------------------------ state */
  const state = { screen: 'hub', station: null, rounds: [], points: [], idx: 0, results: [], locked: false, deadline: 0, timerId: 0, advanceId: 0, teaserId: 0, lastActive: Date.now(), errors: [], bankShow: false, bankKey: null, bankOrder: [] };
  const cur = () => state.rounds[state.idx];
  const total = () => state.rounds.length;
  const curStation = () => stationCfg(state.station) || {};

  function clearTimers() { ['timerId', 'advanceId', 'teaserId'].forEach((k) => { if (state[k]) { clearInterval(state[k]); clearTimeout(state[k]); state[k] = 0; } }); }
  function go(screen) { clearTimers(); state.screen = screen; render(); }

  function startGame(key) {
    if (!stationCfg(key) || !poolOf(key).length) return;
    state.station = key;
    state.rounds = buildRounds(key);
    if (!state.rounds.length) return;
    state.points = computePoints(state.rounds);
    state.idx = 0; state.results = []; state.locked = false;
    P.seen[key] = [...state.rounds.map((r) => r.id), ...(P.seen[key] || [])].slice(0, Math.max(12, state.rounds.length * 2));
    save();
    go('round');
  }

  function answer(choice) {
    if (state.screen !== 'round' || state.locked) return;
    state.locked = true;
    clearInterval(state.timerId); state.timerId = 0;
    const r = cur();
    const correct = !!choice && choice === (r.mode === 'single' ? r.answer : r.realSlot);
    state.results[state.idx] = { id: r.id, choice: choice || null, correct, timedOut: !choice };
    $$('.pick, .tile', stage).forEach((b) => b.classList.toggle('is-chosen', (b.dataset.pick || b.dataset.choice) === choice));
    const box = $('.pair, .answers', stage); if (box) box.classList.add('is-locked');
    const reduced = document.documentElement.dataset.motion === 'reduced';
    state.advanceId = setTimeout(() => go('reveal'), reduced ? 120 : choice ? 420 : 250);
  }

  function next() {
    if (state.screen !== 'reveal') return;
    if (state.idx + 1 < total()) { state.idx++; state.locked = false; go('round'); } else finish();
  }

  function finish() {
    const score = earned();
    P.stats.plays++;
    if (P.stats.bestOf !== maxScore() || score > P.stats.best) { P.stats.best = score; P.stats.bestOf = maxScore(); }
    save();
    go('final');
  }

  function toHub() { state.station = null; state.rounds = []; state.results = []; state.idx = 0; state.locked = false; state.bankKey = null; state.bankOrder = []; go('hub'); }

  /* ------------------------------------------------------------------ timer */
  function startTimer() {
    const secs = Number(S().timerSeconds) || 0;
    if (!secs) return;
    const R = 40, C = 2 * Math.PI * R;
    state.deadline = performance.now() + secs * 1000;
    const arc = $('.timer__arc'), num = $('.timer__num'), box = $('.timer');
    if (!arc) return;
    arc.style.strokeDasharray = C;
    const update = () => {
      const left = Math.max(0, state.deadline - performance.now());
      arc.style.strokeDashoffset = C * (1 - left / (secs * 1000));
      const sec = Math.ceil(left / 1000);
      if (num.textContent !== String(sec)) num.textContent = sec;
      box.classList.toggle('timer--low', sec <= 5);
      if (left <= 0) answer(null);
    };
    update();
    state.timerId = setInterval(update, 100);
  }

  /* ------------------------------------------------------------------ pieces */
  function pips(showNow) {
    let h = '<div class="pips" role="img" aria-label="Progress">';
    for (let i = 0; i < total(); i++) {
      const r = state.results[i];
      if (r) h += `<span class="pip ${r.correct ? 'pip--ok' : 'pip--miss'}" title="${r.correct ? 'Correct' : 'Missed'}">${r.correct ? ICON.check.replace('stroke-width="3"', 'stroke-width="4"') : ICON.cross}</span>`;
      else h += `<span class="pip ${showNow && i === state.idx ? 'pip--now' : ''}">${i + 1}</span>`;
    }
    return h + '</div>';
  }

  function brand() {
    const s = S();
    // A missing logo file just disappears instead of showing a broken image.
    const logo = clean(s.logoSrc) ? `<img class="logo" src="${esc(s.logoSrc)}" alt="${esc(s.logoAlt || '')}" onerror="this.remove()">` : '';
    const eyebrow = clean(s.eyebrow) ? `<span class="eyebrow">${esc(s.eyebrow)}</span>` : '';
    return `<div class="brandmark" id="brand">${logo}${eyebrow}</div>`;
  }

  function bar(opts = {}) {
    const timer = opts.timer && Number(S().timerSeconds) ? `<div class="timer" aria-hidden="true"><svg viewBox="0 0 100 100"><circle class="timer__track" cx="50" cy="50" r="40"/><circle class="timer__arc" cx="50" cy="50" r="40"/></svg><div class="timer__num">${Number(S().timerSeconds)}</div></div>` : '';
    const score = opts.score ? `<span class="scorechip" aria-label="Score ${earned()} of ${maxScore()}"><span class="mono">Score</span><b>${earned()}</b></span>` : '';
    const home = `<button class="home" data-action="home" aria-label="Home: back to all stations (key H)">${ICON.home}<span>Home</span></button>`;
    const middle = opts.pips === false ? '<div></div>' : pips(opts.now);
    return `<header class="bar"><div class="bar__left">${brand()}${home}</div>${middle}<div class="bar__right">${score}${timer}</div></header>`;
  }

  const timerLabel = () => { const t = Number(S().timerSeconds) || 0; return t ? `${t}s` : 'Off'; };

  const badgesHtml = (r) => {
    const d = diffOf(r), lvl = DIFFS.indexOf(d) + 1;
    const meter = DIFFS.map((_, i) => `<i class="${i < lvl ? 'on' : ''}"></i>`).join('');
    return `<span class="diff diff--${d}"><span class="diff__meter" aria-hidden="true">${meter}</span>${cap(d)}</span><span class="worth">Worth <b>${state.points[state.idx] || 0}</b> points</span>`;
  };

  /* ---- the two things a pair round compares ---- */
  function mailHtml(m) {
    const row = (label, val, cls = '') => `<div class="mail__row ${cls}"><span class="mail__label">${label}</span><span class="mail__val">${val}</span></div>`;
    let head = row('From', `${esc(m.from_name)} &lt;${esc(m.from_email)}&gt;`);
    if (m.to) head += row('To', esc(m.to));
    head += row('Subject', esc(m.subject), 'mail__row--subject');
    if (m.date) head += row('Date', esc(m.date));
    let foot = '';
    if (m.attachment_name) foot += `<span class="mail__attach">📎 ${esc(m.attachment_name)}</span>`;
    if (m.link_text && m.link_url) foot += `<span class="mail__btn">${esc(m.link_text)}</span><p class="mail__url"><span class="mono">Link goes to</span>${esc(m.link_url)}</p>`;
    return `<div class="mail"><div class="mail__head">${head}</div><div class="mail__body">${esc(m.body)}</div>${foot ? `<div class="mail__foot">${foot}</div>` : ''}</div>`;
  }

  function paneHtml(key, noun, slot) {
    if (key === 'email') return `<div class="pane card fit" role="group" aria-label="${noun} ${slot}">${mailHtml(cur().items[slot])}</div>`;
    if (key === 'video') return `<div class="pane pane--media card" role="group" aria-label="${noun} ${slot}"><video data-media="${slot}" controls preload="metadata" playsinline aria-label="${noun} ${slot}"></video></div>`;
    return `<div class="pane pane--media card" role="group" aria-label="${noun} ${slot}"><button class="zoom" data-zoom="${slot}" aria-label="Enlarge ${noun} ${slot}"><img data-media="${slot}" alt="${noun} ${slot}" draggable="false"><span class="zoom__hint">${ICON.zoom} Tap to enlarge</span></button></div>`;
  }

  const emailDomain = (addr) => { const i = String(addr || '').lastIndexOf('@'); return i < 0 ? esc(addr) : `${esc(addr.slice(0, i))}@<b>${esc(addr.slice(i + 1))}</b>`; };

  function miniHtml(key, noun, slot, picked) {
    const r = cur(), item = r.items[slot], real = slot === r.realSlot;
    const tag = real ? '<span class="tag tag--real">Real</span>' : '<span class="tag tag--fake">Fake</span>';
    const pick = picked ? `<p class="mini__pick">${ICON.check} Your pick</p>` : '';
    let body;
    if (key === 'email') {
      body = `<p class="mini__line"><span class="mono">From</span>${emailDomain(item.from_email)}</p>`
        + `<p class="mini__line"><span class="mono">Link goes to</span>${item.link_url ? esc(item.link_url) : 'No link'}</p>`
        + (item.attachment_name ? `<p class="mini__line"><span class="mono">Attachment</span>${esc(item.attachment_name)}</p>` : '');
    } else if (key === 'video') body = `<video class="mini__media" data-media="${slot}" controls preload="metadata" playsinline aria-label="${noun} ${slot}, ${real ? 'real' : 'fake'}"></video>`;
    else body = `<img class="mini__media" data-media="${slot}" alt="${noun} ${slot}, ${real ? 'real' : 'fake'}" draggable="false">`;
    return `<div class="mini mini--${real ? 'real' : 'fake'}"><div class="mini__top"><span class="mini__name">${noun} ${slot}</span>${tag}</div>${pick}${body}</div>`;
  }

  // The "related policy" box: the case's own policy, else defaultPolicy, else nothing.
  function policyHtml(r) {
    const s = S();
    const pol = clean(r.policy) || clean(s.defaultPolicy);
    return pol ? `<div class="policy">${ICON.doc}<div><p class="policy__label">${esc(s.policyLabel || 'The policy that protects us')}</p><p class="policy__text">${esc(pol)}</p></div></div>` : '';
  }

  /* ------------------------------------------------------------------ screens */
  const SCREENS = {
    hub() {
      const s = S();
      const stats = P.stats.plays ? `&nbsp;·&nbsp; Today: ${P.stats.plays} ${P.stats.plays === 1 ? 'play' : 'plays'} &nbsp;·&nbsp; Best score: ${P.stats.best}/${P.stats.bestOf}` : '';
      const m = /^(.*?)\s+or\s+(.*)$/i.exec(s.title || '');
      const words = String(s.title || '').split(' ');
      const last = words.pop();
      const title = m ? `${esc(m[1])}<span class="or"> or </span><span class="fake">${esc(m[2])}</span>` : `${esc(words.join(' '))}${words.length ? ' ' : ''}<span class="fake">${esc(last)}</span>`;
      const cards = stations().map((st, i) => {
        const n = poolOf(st.key).length;
        return `<button class="station" data-action="station" data-station="${esc(st.key)}"${n ? '' : ' disabled'} aria-label="${esc(st.title)}. ${esc(st.sub)}">
          ${ICON[st.icon] || ICON.mail}
          <div class="station__text">
            <p class="mono">Station ${i + 1} &nbsp;·&nbsp; ${esc(st.tag)}</p>
            <h2 class="station__title">${esc(st.title)}</h2>
            <p class="station__sub">${esc(n ? st.sub : 'No rounds loaded yet.')}</p>
          </div>
          <span class="station__go">${n ? `Play ${ICON.arrow}` : 'Coming soon'}</span>
        </button>`;
      }).join('');
      const bank = stations().filter((st) => st.bankLabel && bankCount(st)).map((st) => `<button class="ghost" data-action="bank" data-station="${esc(st.key)}">${ICON.list}<span>${esc(st.bankLabel)}</span><b>${bankCount(st)}</b></button>`).join('');
      return `<section class="screen attract" data-screen="hub">
        ${brand()}
        <h1 class="attract__title" aria-label="${esc(s.title)}">${title}</h1>
        <p class="attract__sub">${esc(s.subtitle)}</p>
        <div class="stations">${cards}</div>
        <p class="teaser" aria-hidden="true" id="teaser"></p>
        <div class="tools">
          <div class="stepper" role="group" aria-label="Timer per round">
            ${ICON.clock}<span class="stepper__label">Timer</span>
            <button data-action="timer-down" aria-label="Less time">−</button>
            <output class="stepper__val" id="timerVal" aria-live="polite">${timerLabel()}</output>
            <button data-action="timer-up" aria-label="More time">+</button>
          </div>
          ${bank}
        </div>
        <p class="attract__stats">${esc(s.tagline || '')}${stats}</p>
      </section>`;
    },

    round() {
      const r = cur(), st = curStation();
      if (r.mode === 'single') return SCREENS.roundSingle(r, st);
      const noun = cap(st.noun || 'item');
      const slot = (side) => `<div class="slot">
          <p class="slot__name mono">${noun} ${side}</p>
          ${paneHtml(state.station, noun, side)}
          <button class="pick" data-pick="${side}" aria-label="${noun} ${side} is the real one (key ${side === 'A' ? 1 : 2})">${ICON.check}<span>This one is real</span><kbd>${side === 'A' ? 1 : 2}</kbd></button>
        </div>`;
      return `<section class="screen" data-screen="round">
        ${bar({ now: true, timer: true, score: true })}
        <div class="round">
          <div class="meta">
            <div class="meta__text">
              <p class="mono">${esc(st.tag)} &nbsp;·&nbsp; Round ${state.idx + 1} of ${total()} &nbsp;·&nbsp; <b>${esc(st.question || '')}</b></p>
              <h1 class="meta__title">${esc(r.label)}</h1>
            </div>
            ${badgesHtml(r)}
          </div>
          <div class="pair" role="group" aria-label="Your answer">${slot('A')}${slot('B')}</div>
        </div>
      </section>`;
    },

    // Reel or Real: one case card with clues, and two big answer tiles.
    roundSingle(r, st) {
      const label = `Case ${state.idx + 1} of ${total()}${clean(r.clue) ? ' &nbsp;·&nbsp; <b>' + esc(r.clue) + '</b>' : ''}`;
      const clues = r.evidence.map((e, i) => `<li style="--i:${i}">${esc(e)}</li>`).join('');
      return `<section class="screen" data-screen="round">
        ${bar({ now: true, timer: true, score: true })}
        <div class="round round--single">
          <article class="case card fit">
            <div class="badges">${badgesHtml(r)}</div>
            <p class="mono">${label}</p>
            <h1 class="case__title">${esc(r.label)}</h1>
            <ul class="clues">${clues}</ul>
          </article>
          <div class="answers" role="group" aria-label="Your answer">
            <button class="tile tile--reel" data-choice="REEL" aria-label="Reel: from a film (key 1)">
              <kbd>1</kbd>${ICON.film}<span class="tile__word">Reel</span><span class="tile__sub">Straight from a film</span>
            </button>
            <button class="tile tile--real" data-choice="REAL" aria-label="Real: it really happened (key 2)">
              <kbd>2</kbd>${ICON.file}<span class="tile__word">Real</span><span class="tile__sub">It really happened</span>
              <span class="redact" aria-hidden="true"><i></i><i></i></span>
              <span class="declass" aria-hidden="true">Declassified</span>
              <span class="scan" aria-hidden="true"></span>
            </button>
          </div>
        </div>
        <p class="hint">${Number(S().timerSeconds) ? 'Movie plot or real incident? Make the call before time runs out.' : 'Movie plot or real incident? Tap your answer.'}</p>
      </section>`;
    },

    reveal() {
      const r = cur(), res = state.results[state.idx] || {}, st = curStation(), s = S();
      const single = r.mode === 'single';
      const noun = cap(st.noun || 'item');
      const won = res.correct ? state.points[state.idx] || 0 : 0;
      const isReal = single && r.answer === 'REAL';
      const what = single ? (isReal ? 'It really happened.' : "It's from a film.") : `${noun} ${r.realSlot} was the real one.`;
      const head = res.timedOut ? `${ICON.clock}<span><b>Time's up!</b> ${what}</span>` : res.correct ? `${ICON.check}<span><b>Correct!</b> ${what}</span>` : `${ICON.cross}<span><b>Not quite!</b> ${what}</span>`;
      const result = `<div class="result ${res.correct ? 'result--ok' : 'result--miss'}" role="status">
            <p class="result__head">${head}</p>
            <p class="result__pts"><b>+${won}</b> points</p>
            <p class="result__total">Score<b>${earned()}<small> / ${maxScore()}</small></b></p>
          </div>`;
      const shield = st.shield || {};
      const takeaway = clean(r.takeaway) || clean(shield.takeaway);
      const todo = clean(r.todo) || clean(shield.todo);
      const policy = policyHtml(r);
      const last = state.idx + 1 >= total();
      let verdict;
      if (single) {
        const src = isReal && s.showSourcesOnReveal && r.sources.filter(clean).length ? `<p class="sources">Source: ${esc(r.sources.filter(clean)[0])}</p>` : '';
        verdict = `<article class="verdict card fit">
            <p class="mono">${isReal ? 'A real incident' : 'From the movies'}</p>
            <div class="stamp ${isReal ? 'stamp--real' : 'stamp--reel'}">${isReal ? 'Real' : 'Reel'}</div>
            <h2 class="verdict__title">${esc(r.reveal_title)} <span class="yr">${esc(r.year)}</span></h2>
            ${clean(r.weakness) ? `<p class="verdict__why"><span class="mono">Why it worked</span>${esc(r.weakness)}</p>` : ''}
            ${src}
          </article>`;
      } else {
        verdict = `<article class="verdict card fit">
            <p class="mono">Which one was the ${esc(st.fakeNoun || 'fake')}?</p>
            <div class="compare">${miniHtml(state.station, noun, 'A', res.choice === 'A')}${miniHtml(state.station, noun, 'B', res.choice === 'B')}</div>
            <p class="verdict__why"><span class="mono">What gave it away</span>${esc(r.note)}</p>
          </article>`;
      }
      return `<section class="screen" data-screen="reveal">
        ${bar({ now: false, timer: false })}
        ${result}
        <div class="reveal${single ? ' reveal--single' : ''}">
          ${verdict}
          <article class="shield card fit">
            <p class="mono">${ICON.shield} Control Shield</p>
            <h2 class="shield__takeaway">${esc(takeaway)}</h2>
            <div class="do"><p class="mono">What you can do</p><p class="do__text">${esc(todo)}</p></div>
          </article>
        </div>
        <footer class="foot${policy ? ' foot--policy' : ''}">
          ${policy}
          <span class="foot__note" id="adv"></span>
          <button class="cta" data-action="next" data-autofocus>${last ? 'See my score' : (single ? 'Next case' : 'Next round')} ${ICON.arrow}</button>
        </footer>
      </section>`;
    },

    final() {
      const s = S(), st = curStation();
      const score = earned(), totalPts = maxScore();
      const right = state.results.filter((r) => r && r.correct).length;
      const ratio = totalPts ? score / totalPts : 0;
      const rating = (st.ratings || s.ratings || []).slice().sort((a, b) => b.min - a.min).find((x) => ratio >= x.min) || { name: '', line: '' };
      const missed = state.results.map((r, i) => (r && !r.correct ? state.rounds[i] : null)).filter(Boolean);
      const pick = shuffle(missed.length ? missed : state.rounds)[0];
      const todo = clean(pick.todo) || clean((st.shield || {}).todo);
      const report = clean(s.reportingLine) ? `<p class="next__report">${esc(s.reportingLine)}</p>` : '';
      return `<section class="screen" data-screen="final">
        ${bar({ now: false, timer: false })}
        <div class="final">
          <article class="score card">
            <p class="mono">${esc(st.title || 'Your score')}</p>
            <p class="score__num">${score}<small>/ ${totalPts}</small></p>
            <p class="score__count">${right} of ${total()} correct</p>
            <h1 class="score__rating">${esc(rating.name)}</h1>
            <p class="score__line">${esc(rating.line)}</p>
          </article>
          <article class="next card fit">
            <p class="mono">${ICON.shield} One thing to do this week</p>
            <div class="do"><p class="mono">${esc(clean(pick.theme) || st.tag || 'Stay safe')}</p><p class="do__text">${esc(todo)}</p></div>
            <p class="next__why">From ${pick.mode === 'single' ? 'case' : 'round'}: ${esc(pick.label)}</p>
            ${report}
          </article>
        </div>
        <footer class="foot">
          <span class="foot__note" id="adv"></span>
          <button class="cta cta--quiet" data-action="home">All stations</button>
          <button class="cta" data-action="again" data-autofocus>${ICON.replay} Play again</button>
        </footer>
      </section>`;
    },

    // Question bank: every Reel or Real case, answers hidden until "Show answers".
    bank() {
      const pts = basePoints(), show = state.bankShow;
      const all = REEL;
      const count = (f) => all.filter(f).length;
      const items = all.map((r, i) => {
        const d = diffOf(r);
        const off = !r.enabled ? 'Hidden' : !r.audience.includes('all') ? 'Technical' : '';
        const ans = r.answer === 'REAL' ? 'Real' : 'Reel';
        return `<li class="qb${off ? ' qb--off' : ''}">
          <div class="qb__top"><span class="qb__num">${i + 1}</span><span class="chip chip--${d}">${cap(d)} · ${pts[d]} pts</span>${off ? `<span class="chip">${off}</span>` : ''}${show ? `<span class="chip chip--${ans.toLowerCase()}">${ans}</span>` : ''}</div>
          <p class="qb__title">${esc(r.label)}</p>
          ${show ? `<p class="qb__ans">${esc(r.reveal_title)} <span>${esc(r.year)}</span></p>` : ''}
        </li>`;
      }).join('');
      return `<section class="screen" data-screen="bank">
        ${bar({ pips: false })}
        <div class="bank">
          <div class="bank__head">
            <div><h1 class="bank__title">Question bank</h1>
              <p class="bank__sum">Reel or Real? &nbsp;·&nbsp; ${all.length} questions &nbsp;·&nbsp; ${count((r) => r.answer === 'REEL')} Reel, ${count((r) => r.answer === 'REAL')} Real &nbsp;·&nbsp; ${DIFFS.map((d) => `${count((r) => diffOf(r) === d)} ${d}`).join(', ')}</p></div>
            <button class="ghost" data-action="bank-toggle" aria-pressed="${show}">${show ? 'Hide answers' : 'Show answers'}</button>
            <button class="cta" data-action="station" data-station="${esc(state.bankKey || reelStationKey())}" data-autofocus>Play ${ICON.arrow}</button>
          </div>
          <ol class="bank__list">${items}</ol>
        </div>
      </section>`;
    },

    // Photo bank: every photo pair, answers hidden until "Show answers".
    pbank() {
      const st = stationCfg(state.bankKey) || {}, pts = basePoints(), show = state.bankShow;
      const noun = cap(st.noun || 'photo');
      const items = state.bankOrder;
      const count = (d) => items.filter((e) => diffOf(e.r) === d).length;
      const cards = items.map(({ r, realSide }, i) => {
        const d = diffOf(r);
        const thumb = (side) => {
          const real = side === realSide;
          return `<button class="qp__thumb" data-bank-zoom="${i}:${side}" aria-label="Enlarge ${noun} ${side}: ${esc(r.label)}">
            <img data-bank="${i}:${side}" alt="${noun} ${side}: ${esc(r.label)}${show ? (real ? ', the real one' : ', the fake') : ''}" loading="lazy" decoding="async" draggable="false">
            <span class="qp__side">${side}</span>${show ? `<span class="tag tag--${real ? 'real' : 'fake'} qp__tag">${real ? 'Real' : 'Fake'}</span>` : ''}
          </button>`;
        };
        return `<li class="qb qp">
          <div class="qb__top"><span class="qb__num">${i + 1}</span><span class="chip chip--${d}">${cap(d)} · ${pts[d]} pts</span></div>
          <p class="qb__title">${esc(r.label)}</p>
          <div class="qp__thumbs">${thumb('A')}${thumb('B')}</div>
          ${show ? `<p class="qp__note"><span class="mono">What gave it away</span>${esc(r.note)}</p>` : ''}
        </li>`;
      }).join('');
      return `<section class="screen" data-screen="pbank">
        ${bar({ pips: false })}
        <div class="bank">
          <div class="bank__head">
            <div><h1 class="bank__title">${esc(st.bankLabel || 'Photo bank')}</h1>
              <p class="bank__sum">${items.length} photo pairs &nbsp;·&nbsp; ${DIFFS.map((d) => `${count(d)} ${d}`).join(', ')} &nbsp;·&nbsp; one of each pair is AI-generated. Tap a photo to enlarge it.</p></div>
            <button class="ghost" data-action="bank-toggle" aria-pressed="${show}">${show ? 'Hide answers' : 'Show answers'}</button>
            <button class="cta" data-action="station" data-station="${esc(state.bankKey)}" data-autofocus>Play ${ICON.arrow}</button>
          </div>
          <ol class="bank__list bank__list--pairs">${cards}</ol>
        </div>
      </section>`;
    },

    error(errs) {
      return `<section class="screen" data-screen="error"><article class="error card"><h1>Setup problem</h1><p class="mono">Fix these, then refresh</p><ul>${errs.map((e) => `<li>${esc(e)}</li>`).join('')}</ul></article></section>`;
    },
  };

  /* ------------------------------------------------------------------ render */
  function applyEnv() {
    const s = S();
    const root = document.documentElement;
    root.dataset.theme = s.theme === 'auto' ? (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light') : (s.theme === 'dark' ? 'dark' : 'light');
    root.dataset.motion = s.reducedMotion ? 'reduced' : 'full';
  }

  // Dense cards (emails, clue lists, lessons) shrink their text a little rather than overflow; a card that
  // still doesn't fit at the floor scrolls instead of clipping.
  function fit() {
    $$('.fit', stage).forEach((el) => {
      let f = 1;
      el.style.setProperty('--fit', f);
      el.removeAttribute('data-scroll');
      let guard = 14;
      while (el.scrollHeight > el.clientHeight + 1 && f - 0.04 >= 0.75 && guard--) { f = +(f - 0.04).toFixed(2); el.style.setProperty('--fit', f); }
      if (el.scrollHeight > el.clientHeight + 1) el.setAttribute('data-scroll', '');
      el.dataset.fit = f;
    });
    // The two items being compared should read at the same size, so share the smaller factor.
    const panes = $$('.pane.fit', stage);
    if (panes.length > 1) {
      const f = Math.min(...panes.map((p) => Number(p.dataset.fit)));
      panes.forEach((p) => { p.style.setProperty('--fit', f); p.dataset.fit = f; });
    }
  }

  function render() {
    applyEnv();
    stage.innerHTML = state.errors.length ? SCREENS.error(state.errors) : SCREENS[state.screen]();
    hydrateMedia();
    fit();
    const focus = $('[data-autofocus]', stage);
    if (focus && document.hasFocus() && !document.body.classList.contains('cursor-hidden')) focus.focus({ preventScroll: true, focusVisible: false });
    onShown();
  }

  function onShown() {
    const s = S();
    state.lastActive = Date.now();
    if (state.screen === 'hub') {
      const labels = shuffle(stations().flatMap((st) => poolOf(st.key)).filter((r) => !isPlaceholder(r)).map((r) => r.label)).slice(0, 12);
      let i = 0;
      const show = () => { const t = $('#teaser'); if (t) { t.innerHTML = `<span>Can you spot it? <b>${esc(labels[i % labels.length])}</b></span>`; i++; } };
      if (labels.length) { show(); state.teaserId = setInterval(show, 4000); }
    }
    if (state.screen === 'round') {
      startTimer();
      const st = curStation(), r = cur();
      sr.textContent = r.mode === 'single'
        ? `Case ${state.idx + 1} of ${total()}: ${r.label}. Reel or Real?`
        : `Round ${state.idx + 1} of ${total()}: ${r.label}. ${st.question || ''}`;
    }
    if (state.screen === 'reveal') {
      const r = cur(), res = state.results[state.idx] || {}, st = curStation();
      const verdict = r.mode === 'single'
        ? `It was ${r.answer === 'REAL' ? 'Real' : 'Reel'}: ${r.reveal_title}, ${r.year}. ${r.takeaway}`
        : `${cap(st.noun || 'item')} ${r.realSlot} was the real one. ${r.note}`;
      sr.textContent = `${res.timedOut ? "Time's up." : res.correct ? `Correct, plus ${state.points[state.idx] || 0} points.` : 'Not quite, 0 points.'} Score ${earned()} of ${maxScore()}. ${verdict}`;
      const secs = Number(s.revealAutoAdvanceSeconds) || 0;
      if (secs) countdown(secs, (left) => `Next in ${left}s`, next);
    }
    if (state.screen === 'final') {
      const secs = Number(s.finalAutoResetSeconds) || 0;
      if (secs) countdown(secs, (left) => `Next player in ${left}s`, toHub);
    }
  }

  function countdown(secs, label, done) {
    let left = secs;
    const paint = () => { const el = $('#adv'); if (el) el.textContent = label(left); };
    paint();
    state.advanceId = setInterval(() => { left--; if (left <= 0) { clearInterval(state.advanceId); state.advanceId = 0; done(); } else paint(); }, 1000);
  }

  /* ------------------------------------------------------------------ photo zoom */
  const lightbox = $('#lightbox');
  let lastFocus = null;
  function openZoom(slot) {
    const r = cur(); if (!r || !r.items) return;
    openZoomSrc(mediaSrc(r.items[slot]), `${cap((curStation().noun) || 'photo')} ${slot}, enlarged`);
  }
  function openZoomSrc(src, alt) {
    if (!src) return;
    const img = $('img', lightbox);
    img.src = src;
    img.alt = alt;
    lastFocus = document.activeElement;
    lightbox.hidden = false;
    const close = $('.lightbox__close', lightbox); if (close) close.focus({ preventScroll: true });
  }
  function closeZoom() { lightbox.hidden = true; if (lastFocus && lastFocus.focus) lastFocus.focus({ preventScroll: true }); }
  lightbox.addEventListener('click', closeZoom);

  /* ------------------------------------------------------------------ input */
  stage.addEventListener('click', (e) => {
    const t = e.target.closest('[data-pick], [data-choice], [data-zoom], [data-bank-zoom], [data-action]');
    if (!t) return;
    if (t.dataset.pick) answer(t.dataset.pick);
    else if (t.dataset.choice) answer(t.dataset.choice);
    else if (t.dataset.zoom) openZoom(t.dataset.zoom);
    else if (t.dataset.bankZoom) { const [i, side] = t.dataset.bankZoom.split(':'); openZoomSrc(bankSrc(i, side), `Photo ${side}, enlarged`); }
    else if (t.dataset.action === 'station') startGame(t.dataset.station);
    else if (t.dataset.action === 'again') startGame(state.station);
    else if (t.dataset.action === 'next') next();
    else if (t.dataset.action === 'home') toHub();
    else if (t.dataset.action === 'bank') openBank(t.dataset.station);
    else if (t.dataset.action === 'bank-toggle') { const y = ($('.bank__list', stage) || {}).scrollTop || 0; state.bankShow = !state.bankShow; render(); const l = $('.bank__list', stage); if (l) l.scrollTop = y; }
    else if (t.dataset.action === 'timer-up' || t.dataset.action === 'timer-down') stepTimer(t.dataset.action === 'timer-up' ? 1 : -1);
  });

  // Home-screen timer: Off, then 5s to 120s. Saved on this computer like the staff settings.
  const TIMER_STEPS = [0, 5, 10, 15, 20, 30, 45, 60, 90, 120];
  function stepTimer(dir) {
    const now = Number(S().timerSeconds) || 0;
    const nextUp = TIMER_STEPS.find((v) => v > now), nextDown = TIMER_STEPS.filter((v) => v < now).pop();
    const v = dir > 0 ? (nextUp == null ? TIMER_STEPS[TIMER_STEPS.length - 1] : nextUp) : (nextDown == null ? 0 : nextDown);
    P.settings.timerSeconds = v;
    save();
    const out = $('#timerVal'); if (out) out.textContent = timerLabel();
  }

  document.addEventListener('keydown', (e) => {
    state.lastActive = Date.now();
    if (!lightbox.hidden) { if (e.key === 'Escape' || e.key === 'Enter' || e.key === ' ') { e.preventDefault(); closeZoom(); } return; }
    if (!$('#staff').hidden) { if (e.key === 'Escape') closeStaff(); return; }
    if (e.shiftKey && (e.key === 'S' || e.key === 's')) { e.preventDefault(); openStaff(); return; }
    if (e.ctrlKey || e.metaKey || e.altKey) return;
    const k = e.key;
    if (k === 'f' || k === 'F') { toggleFullscreen(); return; }
    if ((k === 'h' || k === 'H') && state.screen !== 'hub') { toHub(); return; }
    if (state.errors.length) return;
    if (state.screen === 'hub') { const st = stations()[Number(k) - 1]; if (st) startGame(st.key); return; }
    if (state.screen === 'round') {
      const single = cur().mode === 'single';
      if (k === '1') answer(single ? 'REEL' : 'A'); else if (k === '2') answer(single ? 'REAL' : 'B');
      return;
    }
    if (state.screen === 'bank' || state.screen === 'pbank') return;
    if (k === 'Enter' || k === ' ') {
      const a = document.activeElement;
      if (a && a !== document.body && a !== stage && a.matches('button, video, input')) return; // native control handles it
      const btn = $('[data-autofocus]', stage);
      if (btn) { e.preventDefault(); btn.click(); }
    }
  });

  function toggleFullscreen() {
    try { if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen(); } catch (e) { /* ignore */ }
  }

  // Hide the cursor on idle (touch kiosks / projectors); wake it on movement.
  let cursorTimer = 0;
  const wake = () => { state.lastActive = Date.now(); document.body.classList.remove('cursor-hidden'); clearTimeout(cursorTimer); cursorTimer = setTimeout(() => document.body.classList.add('cursor-hidden'), 3000); };
  ['pointermove', 'pointerdown', 'touchstart', 'wheel'].forEach((ev) => document.addEventListener(ev, wake, { passive: true }));
  // A video that is playing counts as someone being there.
  ['play', 'timeupdate'].forEach((ev) => document.addEventListener(ev, () => { state.lastActive = Date.now(); }, true));
  document.addEventListener('contextmenu', (e) => e.preventDefault());

  // Walk-away reset
  setInterval(() => {
    const secs = Number(S().idleResetSeconds) || 0;
    if (!secs || state.screen === 'hub' || state.errors.length || !$('#staff').hidden || !lightbox.hidden) return;
    if (Date.now() - state.lastActive > secs * 1000) toHub();
  }, 1000);

  /* ------------------------------------------------------------------ staff panel */
  let holdTimer = 0;
  stage.addEventListener('pointerdown', (e) => { if (e.target.closest('#brand')) holdTimer = setTimeout(openStaff, 1500); });
  ['pointerup', 'pointerleave', 'pointercancel'].forEach((ev) => stage.addEventListener(ev, () => clearTimeout(holdTimer)));

  const OPTS = [
    ['timerSeconds', 'Timer per round', [[0, 'Off'], [15, '15s'], [30, '30s'], [45, '45s'], [60, '60s']]],
    ['idleResetSeconds', 'Walk-away reset', [[0, 'Never'], [60, '60s'], [90, '90s'], [180, '3 min']]],
    ['theme', 'Theme', [['light', 'Light'], ['dark', 'Dark'], ['auto', 'Auto']]],
    ['reducedMotion', 'Animations', [[false, 'On'], [true, 'Off']]],
    ['includeTechnical', 'Technical cases', [[false, 'Hide'], [true, 'Include']]],
  ];

  function openStaff() {
    const el = $('#staff');
    const s = S();
    const rows = OPTS.map(([k, label, vals]) => `<div class="staff__row"><span>${label}</span><div class="seg" data-key="${k}">${vals.map(([v, t]) => `<button data-val='${JSON.stringify(v)}' aria-pressed="${!!s[k] === v || s[k] === v}">${t}</button>`).join('')}</div></div>`).join('');
    const pools = stations().map((st) => {
      const pool = poolOf(st.key);
      const ph = pool.filter(isPlaceholder).length;
      const m = gameMix(st.key);
      let line = `${esc(st.tag)}: ${pool.length} rounds (${DIFFS.map((d) => `${pool.filter((r) => diffOf(r) === d).length} ${d}`).join(', ')}); a game uses ${DIFFS.map((d) => `${m[d]} ${d}`).join(', ')}`;
      if (st.mode === 'single') {
        const draft = pool.filter((r) => r.status !== 'approved').length;
        const noSrc = pool.filter((r) => r.answer === 'REAL' && !r.sources.filter(clean).length).length;
        line += `<br>&nbsp;&nbsp;<b>Still draft:</b> ${draft} of ${pool.length}${draft ? ' (fact-check, then set status "approved" in reel-or-real/rounds.js)' : ''}. <b>Real cases without a source:</b> ${noSrc}.`;
      }
      return line + (ph ? ` <b>${ph} still placeholder</b>` : '');
    }).join('<br>');
    el.innerHTML = `<div class="staff__panel">
      <h2>Staff settings</h2><p class="sm">Saved on this computer. Close with Esc.</p>
      ${rows}
      <div class="staff__info"><b>Rounds available</b><br>${pools}<br>
        <b>Scoring:</b> ${maxScore()} points max per game.<br>
        <b>Today:</b> ${P.stats.plays} plays${P.stats.plays ? `, best ${P.stats.best}/${P.stats.bestOf}` : ''}.</div>
      <div class="staff__actions"><button class="primary" data-act="close">Done</button><button data-act="fs">Fullscreen</button><button data-act="reset">Reset today's counters</button><button data-act="home">Back to home screen</button></div>
    </div>`;
    el.hidden = false;
    const first = $('.staff__actions .primary', el); if (first) first.focus();
  }
  function closeStaff() { $('#staff').hidden = true; applyEnv(); state.lastActive = Date.now(); if (state.screen === 'hub') render(); }

  $('#staff').addEventListener('click', (e) => {
    const b = e.target.closest('button'); if (!b) { if (e.target.id === 'staff') closeStaff(); return; }
    if (b.dataset.act === 'close') return closeStaff();
    if (b.dataset.act === 'fs') return toggleFullscreen();
    if (b.dataset.act === 'home') { closeStaff(); return toHub(); }
    if (b.dataset.act === 'reset') { P.stats = { day: today(), plays: 0, best: 0, bestOf: 0 }; P.seen = {}; save(); return openStaff(); }
    const seg = b.closest('.seg'); if (seg) { P.settings[seg.dataset.key] = JSON.parse(b.dataset.val); save(); applyEnv(); openStaff(); }
  });

  /* ------------------------------------------------------------------ boot */
  mergeMyQuestions();
  state.errors = validate();
  if (!state.errors.length) REEL = Array.isArray(window.ROUNDS) ? window.ROUNDS.map(normalizeReel) : [];
  render();
  wake();

  // Small hook for automated testing; harmless in normal use.
  window.CyberRoom = { state, start: startGame, answer, next, go, toHub, settings: S };
})();
