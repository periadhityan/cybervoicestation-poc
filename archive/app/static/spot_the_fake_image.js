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
  const response = await fetch('/api/spot-the-fake-image/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

function buildGames(rounds) {
  return rounds.map(round => {
    const slots = shuffle([
      { url: round.real_image_url, isReal: true },
      { url: round.fake_image_url, isReal: false },
    ]);
    return {
      id: round.id,
      difficulty: round.difficulty,
      subjectLabel: round.subject_label,
      revealNote: round.reveal_note,
      slotA: slots[0],
      slotB: slots[1],
    };
  });
}

function makeImageEl(url) {
  const img = document.createElement('img');
  img.src = url;
  img.alt = 'Comparison photo';
  return img;
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

  clipAMedia.replaceChildren(makeImageEl(game.slotA.url));
  clipBMedia.replaceChildren(makeImageEl(game.slotB.url));
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  guessBtns.forEach(btn => (btn.disabled = true));

  const game = games[currentIndex];
  const guessedSlot = slotLetter === 'A' ? game.slotA : game.slotB;
  const correct = guessedSlot.isReal;
  if (correct) score += 1;

  feedbackVerdict.textContent = correct ? 'Correct -- that was the real one.' : 'Not quite -- that was the fake.';
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
  games = buildGames(rounds);
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
