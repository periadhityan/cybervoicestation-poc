const consent = document.getElementById('consent');
const startBtn = document.getElementById('startBtn');
const recordBtn = document.getElementById('recordBtn');
const stopBtn = document.getElementById('stopBtn');
const finishBtn = document.getElementById('finishBtn');
const errorResetBtn = document.getElementById('errorResetBtn');

const intro = document.getElementById('intro');
const recordingPanel = document.getElementById('recordingPanel');
const processingPanel = document.getElementById('processingPanel');
const resultPanel = document.getElementById('resultPanel');
const errorPanel = document.getElementById('errorPanel');
const errorText = document.getElementById('errorText');
const resultAudio = document.getElementById('resultAudio');
const demoTextCaption = document.getElementById('demoTextCaption');
const timer = document.getElementById('timer');

let recorder = null;
let stream = null;
let chunks = [];
let timerHandle = null;
let startTime = null;
let currentObjectUrl = null;

function showOnly(panel) {
  [intro, recordingPanel, processingPanel, resultPanel, errorPanel]
    .forEach(p => p.classList.add('hidden'));
  panel.classList.remove('hidden');
}

function revokeResultUrl() {
  if (currentObjectUrl) {
    URL.revokeObjectURL(currentObjectUrl);
    currentObjectUrl = null;
  }
  resultAudio.removeAttribute('src');
  resultAudio.load();
}

function stopMicrophoneTracks() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
    stream = null;
  }
}

function resetState() {
  stopMicrophoneTracks();
  revokeResultUrl();
  chunks = [];
  recorder = null;
  clearInterval(timerHandle);
  timerHandle = null;
  timer.textContent = '00:00';
  demoTextCaption.textContent = '';
  consent.checked = false;
  startBtn.disabled = true;
  recordBtn.disabled = false;
  stopBtn.disabled = true;
  showOnly(intro);
}

consent.addEventListener('change', () => {
  startBtn.disabled = !consent.checked;
});

startBtn.addEventListener('click', () => {
  if (!consent.checked) return;
  showOnly(recordingPanel);
});

recordBtn.addEventListener('click', async () => {
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        channelCount: 1,
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true
      }
    });

    chunks = [];
    recorder = new MediaRecorder(stream);

    recorder.ondataavailable = event => {
      if (event.data && event.data.size > 0) chunks.push(event.data);
    };

    recorder.start();
    startTime = Date.now();
    recordBtn.disabled = true;
    stopBtn.disabled = false;

    timerHandle = setInterval(() => {
      const seconds = Math.floor((Date.now() - startTime) / 1000);
      const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
      const ss = String(seconds % 60).padStart(2, '0');
      timer.textContent = `${mm}:${ss}`;

      // Hard-stop at 25 seconds. The station does not need long recordings.
      if (seconds >= 25 && recorder && recorder.state === 'recording') {
        stopBtn.click();
      }
    }, 250);
  } catch (err) {
    errorText.textContent = `Microphone access failed: ${err.message}`;
    showOnly(errorPanel);
  }
});

stopBtn.addEventListener('click', async () => {
  if (!recorder || recorder.state !== 'recording') return;

  stopBtn.disabled = true;
  clearInterval(timerHandle);

  const stopped = new Promise(resolve => {
    recorder.onstop = resolve;
  });

  recorder.stop();
  await stopped;
  stopMicrophoneTracks();

  const mimeType = recorder.mimeType || 'audio/webm';
  const recording = new Blob(chunks, { type: mimeType });

  if (recording.size < 1000) {
    errorText.textContent = 'The recording was too short or empty. Please try again.';
    showOnly(errorPanel);
    return;
  }

  showOnly(processingPanel);

  const form = new FormData();
  form.append('consent', 'yes');
  form.append('audio', recording, 'reference.webm');

  try {
    const response = await fetch('/api/clone', {
      method: 'POST',
      body: form,
      cache: 'no-store'
    });

    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      throw new Error(body.error || `Server returned HTTP ${response.status}`);
    }

    const demoTextHeader = response.headers.get('X-Demo-Text');
    const resultBlob = await response.blob();

    // Browser-side result exists only as an object URL for playback.
    currentObjectUrl = URL.createObjectURL(resultBlob);
    resultAudio.src = currentObjectUrl;
    demoTextCaption.textContent = demoTextHeader ? `"${decodeURIComponent(demoTextHeader)}"` : '';
    showOnly(resultPanel);
    resultAudio.play().catch(() => {});
  } catch (err) {
    errorText.textContent = err.message;
    showOnly(errorPanel);
  } finally {
    // Discard the original browser recording chunks as soon as the request ends.
    chunks = [];
    recorder = null;
  }
});

finishBtn.addEventListener('click', async () => {
  revokeResultUrl();

  // Defence in depth: ask backend to clear any abandoned session material.
  try {
    await fetch('/api/clear-all', {
      method: 'POST',
      cache: 'no-store'
    });
  } catch (_) {
    // Normal successful sessions are already deleted server-side.
  }

  resetState();
});

errorResetBtn.addEventListener('click', async () => {
  try {
    await fetch('/api/clear-all', { method: 'POST', cache: 'no-store' });
  } catch (_) {}
  resetState();
});

window.addEventListener('beforeunload', () => {
  stopMicrophoneTracks();
  revokeResultUrl();
});
