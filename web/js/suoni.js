// Suoni sintetizzati (niente file audio): carta giocata, monete, fine del viaggio, tocca a te.
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
    case 'carta': rumore(0.12, 0.18, 0, 2500); break;
    case 'moneta': nota(1320, 0.12, 'triangle', 0.12); nota(1760, 0.2, 'triangle', 0.1, 0.06); break;
    case 'arrivo': [523, 659, 784, 1047].forEach((f, i) => nota(f, 0.25, 'triangle', 0.15, i * 0.13)); break;
    case 'tocca': nota(660, 0.15, 'triangle', 0.2); nota(880, 0.25, 'triangle', 0.2, 0.16); break;
    default: nota(440, 0.1);
  }
}
