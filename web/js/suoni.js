// Suoni sintetizzati (niente file audio): dado, motori, allarme/schianto, atterraggio, tocca a te.
let ctx = null;
export function sbloccaAudio() {
  try { ctx = ctx || new (window.AudioContext || window.webkitAudioContext)(); if (ctx.state === 'suspended') ctx.resume(); } catch (e) { /* ok */ }
}
function nota(freq, dur, tipo = 'sine', vol = 0.15, quando = 0, fine = null) {
  if (!ctx) return;
  const t = ctx.currentTime + quando;
  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = tipo;
  o.frequency.setValueAtTime(freq, t);
  if (fine) o.frequency.exponentialRampToValueAtTime(fine, t + dur);
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  o.connect(g).connect(ctx.destination);
  o.start(t);
  o.stop(t + dur + 0.02);
}
function rumore(dur, vol = 0.2, quando = 0, filtro = 1200) {
  if (!ctx) return;
  const n = Math.floor(ctx.sampleRate * dur);
  const b = ctx.createBuffer(1, n, ctx.sampleRate);
  const d = b.getChannelData(0);
  for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
  const s = ctx.createBufferSource();
  s.buffer = b;
  const f = ctx.createBiquadFilter();
  f.type = 'lowpass';
  f.frequency.value = filtro;
  const g = ctx.createGain();
  g.gain.value = vol;
  s.connect(f).connect(g).connect(ctx.destination);
  s.start(ctx.currentTime + quando);
}
export function suona(n) {
  if (!ctx) return;
  switch (n) {
    case 'dado': for (let i = 0; i < 5; i++) rumore(0.05, 0.25, i * 0.09, 3000); break;
    case 'nero': nota(300, 0.12, 'square', 0.06); break;
    case 'motore': nota(90, 0.8, 'sawtooth', 0.06, 0, 160); rumore(0.8, 0.12, 0, 700); break;
    case 'botto': rumore(0.5, 0.5, 0, 500); nota(90, 0.4, 'square', 0.12, 0, 40); break;
    case 'gomme': nota(900, 0.6, 'sawtooth', 0.07, 0, 500); rumore(0.6, 0.15, 0, 4000); break;
    case 'arrivo': [523, 659, 784, 1047].forEach((f, i) => nota(f, 0.25, 'triangle', 0.15, i * 0.13)); break;
    case 'tocca': nota(660, 0.15, 'triangle', 0.2); nota(880, 0.25, 'triangle', 0.2, 0.16); break;
    default: nota(440, 0.1);
  }
}
