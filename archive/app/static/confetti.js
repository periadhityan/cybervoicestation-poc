/* Tiny self-contained confetti burst -- no external assets, works fully
   offline/air-gapped. Call window.launchConfetti() to fire it. */
(function () {
  function launchConfetti() {
    const canvas = document.createElement('canvas');
    canvas.className = 'confetti-canvas';
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    document.body.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const colors = ['#22d3ee', '#fb923c', '#f472b6', '#4ade80', '#a78bfa'];

    const pieces = Array.from({ length: 140 }, () => ({
      x: Math.random() * canvas.width,
      y: -20 - Math.random() * canvas.height * 0.4,
      w: 6 + Math.random() * 6,
      h: 10 + Math.random() * 8,
      color: colors[Math.floor(Math.random() * colors.length)],
      speed: 2 + Math.random() * 3,
      drift: (Math.random() - 0.5) * 2,
      rotation: Math.random() * Math.PI,
      spin: (Math.random() - 0.5) * 0.2,
    }));

    let frame = 0;
    const maxFrames = 220;

    function resize() {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    }
    window.addEventListener('resize', resize);

    function tick() {
      frame += 1;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      pieces.forEach((p) => {
        p.y += p.speed;
        p.x += p.drift;
        p.rotation += p.spin;
        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.rotation);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        ctx.restore();
      });
      if (frame < maxFrames) {
        requestAnimationFrame(tick);
      } else {
        window.removeEventListener('resize', resize);
        canvas.remove();
      }
    }
    requestAnimationFrame(tick);
  }

  window.launchConfetti = launchConfetti;
})();
