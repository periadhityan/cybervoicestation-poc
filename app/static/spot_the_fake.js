const intro = document.getElementById('intro');
const startBtn = document.getElementById('startBtn');
const noRoundsNote = document.getElementById('noRoundsNote');

const roundPanel = document.getElementById('roundPanel');
const roundProgress = document.getElementById('roundProgress');
const scoreLine = document.getElementById('scoreLine');
const subjectLabel = document.getElementById('subjectLabel');
const clipA = document.getElementById('clipA');
const clipB = document.getElementById('clipB');
const guessBtns = document.querySelectorAll('.guess-btn');
const feedback = document.getElementById('feedback');
const feedbackVerdict = document.getElementById('feedbackVerdict');
const feedbackNote = document.getElementById('feedbackNote');
const nextBtn = document.getElementById('nextBtn');

const resultPanel = document.getElementById('resultPanel');
const finalScore = document.getElementById('finalScore');
const playAgainBtn = document.getElementById('playAgainBtn');

let games = [];      // shuffled, per-round randomized slot assignment
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
  const response = await fetch('/api/spot-the-fake/rounds', { cache: 'no-store' });
  const data = await response.json();
  return data.rounds || [];
}

function buildGames(rounds) {
  return shuffle(rounds.slice()).map(round => {
    const slots = shuffle([
      { url: round.real_audio_url, isReal: true },
      { url: round.fake_audio_url, isReal: false },
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

function pauseClips() {
  clipA.pause();
  clipB.pause();
}

function renderRound() {
  const game = games[currentIndex];
  answered = false;
  feedback.classList.add('hidden');
  guessBtns.forEach(btn => (btn.disabled = false));

  const difficultyTag = game.difficulty ? ` · ${game.difficulty.toUpperCase()}` : '';
  roundProgress.textContent = `ROUND ${currentIndex + 1} OF ${games.length}${difficultyTag}`;
  scoreLine.textContent = `${score}/${games.length}`;
  subjectLabel.textContent = game.subjectLabel;

  clipA.src = game.slotA.url;
  clipB.src = game.slotB.url;
  clipA.load();
  clipB.load();
}

function handleGuess(slotLetter) {
  if (answered) return;
  answered = true;
  pauseClips();
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
    pauseClips();
    finalScore.textContent = `You spotted ${score} out of ${games.length} correctly.`;
    showOnly(resultPanel);
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
