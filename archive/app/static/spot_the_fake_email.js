const intro = document.getElementById('intro');
const startBtn = document.getElementById('startBtn');
const noRoundsNote = document.getElementById('noRoundsNote');

const roundPanel = document.getElementById('roundPanel');
const roundProgress = document.getElementById('roundProgress');
const roundDots = document.getElementById('roundDots');
const difficultyPill = document.getElementById('difficultyPill');
const scoreLine = document.getElementById('scoreLine');
const subjectLabel = document.getElementById('subjectLabel');
const clipAMedia = document.getElementById('clipAMedia');
const clipBMedia = document.getElementById('clipBMedia');
const guessBtns = document.querySelectorAll('.guess-btn');
const feedback = document.getElementById('feedback');
const feedbackVerdict = document.getElementById('feedbackVerdict');
const feedbackNote = document.getElementById('feedbackNote');
const nextBtn = document.getElementById('nextBtn');

const resultPanel = document.getElementById('resultPanel');
const finalScore = document.getElementById('finalScore');
const playAgainBtn = document.getElementById('playAgainBtn');

let games = [];
let currentIndex = 0;
let score = 0;
let answered = false;

function showOnly(panel) {
  [intro, roundPanel, resultPanel].forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

async function loadRounds() {
  const response = await fetch('/api/spot-the-fake-email/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

async function fetchEmail(url) {
  const response = await fetch(url, { cache: 'no-store' });
  return response.json();
}

async function buildGames(rounds) {
  const games = [];
  for (const round of rounds) {
    const [realEmail, fakeEmail] = await Promise.all([
      fetchEmail(round.real_email_url),
      fetchEmail(round.fake_email_url),
    ]);
    const slots = shuffle([
      { email: realEmail, isReal: true },
      { email: fakeEmail, isReal: false },
    ]);
    games.push({
      id: round.id,
      difficulty: round.difficulty,
      subjectLabel: round.subject_label,
      revealNote: round.reveal_note,
      slotA: slots[0],
      slotB: slots[1],
    });
  }
  return games;
}

function makeRow(label, value) {
  const row = document.createElement('div');
  row.className = 'mail-row';
  const labelEl = document.createElement('span');
  labelEl.className = 'mail-label';
  labelEl.textContent = label;
  const valueEl = document.createElement('span');
  valueEl.className = 'mail-value';
  valueEl.textContent = value;
  row.append(labelEl, valueEl);
  return row;
}

function makeEmailEl(email) {
  const wrap = document.createElement('div');
  wrap.className = 'mail-window';

  const header = document.createElement('div');
  header.className = 'mail-header';
  header.appendChild(makeRow('From:', `${email.from_name} <${email.from_email}>`));
  if (email.to) header.appendChild(makeRow('To:', email.to));
  const subjectRow = makeRow('Subject:', email.subject || '');
  subjectRow.querySelector('.mail-value').classList.add('mail-subject');
  header.appendChild(subjectRow);
  if (email.date) header.appendChild(makeRow('Date:', email.date));
  wrap.appendChild(header);

  const body = document.createElement('div');
  body.className = 'mail-body';
  body.textContent = email.body || '';
  wrap.appendChild(body);

  if (email.attachment_name) {
    const attachment = document.createElement('div');
    attachment.className = 'mail-attachment';
    attachment.textContent = `📎 ${email.attachment_name}`;
    wrap.appendChild(attachment);
  }

  if (email.link_text && email.link_url) {
    const linkRow = document.createElement('div');
    linkRow.className = 'mail-link-row';

    const link = document.createElement('span');
    link.className = 'mail-link';
    link.textContent = email.link_text;
    linkRow.appendChild(link);

    const preview = document.createElement('div');
    preview.className = 'mail-link-preview';
    preview.innerHTML = '<span class="mail-link-preview-label">Link goes to:</span> ';
    const urlSpan = document.createElement('span');
    urlSpan.className = 'mail-link-preview-url';
    urlSpan.textContent = email.link_url;
    preview.appendChild(urlSpan);
    linkRow.appendChild(preview);

    wrap.appendChild(linkRow);
  }

  return wrap;
}

function renderDots() {
  roundDots.innerHTML = '';
  games.forEach((_, i) => {
    const dot = document.createElement('span');
    dot.className = 'round-dot';
    if (i < currentIndex) dot.classList.add('done');
    else if (i === currentIndex) dot.classList.add('current');
    roundDots.appendChild(dot);
  });
}

function renderRound() {
  const game = games[currentIndex];
  answered = false;
  feedback.classList.add('hidden');
  guessBtns.forEach(btn => (btn.disabled = false));

  roundProgress.textContent = `ROUND ${currentIndex + 1} OF ${games.length}`;
  if (game.difficulty) {
    difficultyPill.textContent = game.difficulty.toUpperCase();
    difficultyPill.className = `difficulty-pill pill-${game.difficulty}`;
  } else {
    difficultyPill.classList.add('hidden');
  }
  renderDots();
  scoreLine.textContent = `${score}/${games.length}`;
  subjectLabel.textContent = game.subjectLabel;

  clipAMedia.replaceChildren(makeEmailEl(game.slotA.email));
  clipBMedia.replaceChildren(makeEmailEl(game.slotB.email));
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  guessBtns.forEach(btn => (btn.disabled = true));

  const game = games[currentIndex];
  const guessedSlot = slotLetter === 'A' ? game.slotA : game.slotB;
  const correct = guessedSlot.isReal;
  if (correct) score += 1;

  feedbackVerdict.textContent = correct ? 'Correct -- that was the real email.' : 'Not quite -- that was the phishing email.';
  feedbackNote.textContent = game.revealNote || '';
  feedback.classList.remove('hidden');
  scoreLine.textContent = `${score}/${games.length}`;
}

function nextRound() {
  currentIndex += 1;
  if (currentIndex >= games.length) {
    finalScore.textContent = `You spotted ${score} out of ${games.length} correctly.`;
    showOnly(resultPanel);
    if (games.length && score / games.length >= 0.8 && window.launchConfetti) {
      window.launchConfetti();
    }
    return;
  }
  renderRound();
}

async function startGame() {
  const rounds = await loadRounds();
  if (!rounds.length) {
    noRoundsNote.classList.remove('hidden');
    return;
  }
  games = await buildGames(rounds);
  currentIndex = 0;
  score = 0;
  showOnly(roundPanel);
  renderRound();
}

startBtn.addEventListener('click', startGame);
nextBtn.addEventListener('click', nextRound);
playAgainBtn.addEventListener('click', startGame);
guessBtns.forEach(btn => {
  btn.addEventListener('click', () => handleGuess(btn.dataset.slot));
});
