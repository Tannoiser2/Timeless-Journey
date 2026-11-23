// Il taccuino di viaggio sul telefono: si entra nella stanza con il QR code della TV e da qui si gioca.
// Mano, carte giocate, scelte, Diari propri e altrui, Gazzetta, città e punteggio.
// La TV (il gioco Godot) pubblica lo stato in timeless/rooms/<codice>/game; le scelte tornano in acts.
import { creaRete, RADICE, unisci } from './rete.js';
import { sbloccaAudio, suona } from './suoni.js';

const q = new URLSearchParams(location.search);
const app = document.getElementById('app');
const zoom = document.getElementById('zoom');
const G = 'img/g/';
const GENERI = ['Arte', 'Storia', 'Filosofia', 'Scienza'];
const CAT = { V: 'Viaggio', A: 'Amicizia', I: 'Ispirazione', F: 'Festività' };
const COLORI = { rosso: '#d8453b', giallo: '#e9b92d', verde: '#3f9d4c', blu: '#3fa9c9', grigio: '#8b8f96' };
const COL_VG = ['#c8892a', '#b3362b', '#2f6f9e'];
const ROMANI = ['I', 'II', 'III', 'IV', 'V'];
const ESPERIENZE = { duello: 'Duello d’Onore', notte: 'Una Notte da Ricordare', ammirazione: 'Perso nell’Ammirazione', affinita: 'Affinità Elettive' };
const POS_DIARIO = [[0.61, 0.31], [0.74, 0.31], [0.87, 0.31], [0.61, 0.66], [0.74, 0.66], [0.87, 0.66], [0.164, 0.31], [0.366, 0.64]];

let D = null;               // dati del gioco (dati/gioco.json)
let rete = null;
let uid = '';
let codice = (q.get('s') || '').toUpperCase().slice(0, 4);
let nome = '';
try { nome = localStorage.getItem('tj_nome') || ''; } catch (e) { /* ok */ }
let errore = '';
let pk = null;              // ultimo pacchetto della TV
let scheda = 'gioca';
let diarioDi = -1;
let cittaVista = '';
let cartaScelta = -1;
let inviata = -1;
let toccavaAMe = false;

function esc(s) { return String(s ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c])); }
function imgCarta(id) {
  const p = id.split(':');
  if (p[0] === 'a') return `${G}carte/av_${String(p[1]).padStart(2, '0')}.webp`;
  if (p[0] === 'b') return `${G}carte/base_${p[1]}_${D.base[Number(p[2])].img}.webp`;
  return `${G}espansioni/andersen_${p[1]}.webp`;
}
function imgIdea(g) { return `${G}segnalini/idea_${g.toLowerCase()}.webp`; }
function nomeDi(s, p) { return p >= 100 ? s.automi[p - 100].nome : s.giocatori[p].nome; }
function coloreDi(s, p) { return COLORI[p >= 100 ? s.automi[p - 100].colore : s.giocatori[p].colore]; }

// ------------------------------------------------------------------ ingresso
function ingresso() {
  document.body.classList.remove('dentro');
  app.innerHTML = `
    <h1>Timeless Journeys</h1>
    <p class="sotto" style="text-align:center;color:#f1e6cc">Il tuo taccuino di viaggio: il tavolo resta sulla TV</p>
    <div class="box">
      <label for="cod">Codice della stanza</label>
      <input id="cod" class="codice" maxlength="4" autocomplete="off" autocapitalize="characters" value="${esc(codice)}">
      <label for="nom">Il tuo nome</label>
      <input id="nom" maxlength="16" autocomplete="off" value="${esc(nome)}">
      <div class="errore">${esc(errore)}</div>
      <button id="entra" class="forte">Si parte!</button>
    </div>`;
  document.getElementById('entra').onclick = entra;
}

async function entra() {
  sbloccaAudio();
  const ic = document.getElementById('cod');
  const inn = document.getElementById('nom');
  if (ic) codice = ic.value.trim().toUpperCase();
  if (inn) nome = inn.value.trim().slice(0, 16);
  if (codice.length !== 4) { errore = 'Il codice ha 4 lettere'; ingresso(); return; }
  if (!nome) { errore = 'Scrivi il tuo nome'; ingresso(); return; }
  try { localStorage.setItem('tj_nome', nome); } catch (e) { /* ok */ }
  app.innerHTML = '<h1>Timeless Journeys</h1><div class="box"><p>Entro nella stanza...</p></div>';
  try {
    if (!D) D = await (await fetch('dati/gioco.json')).json();
    if (!rete) { rete = creaRete(); uid = await rete.init(); }
    const h = await rete.get(`${RADICE}/${codice}/host`);
    if (!h) { errore = `La stanza ${codice} non esiste`; ingresso(); return; }
    await rete.set(`${RADICE}/${codice}/seats/${uid}`, { uid, name: nome });
    rete.on(`${RADICE}/${codice}/game`, (v) => {
      const j = unisci(v);
      if (!j) return;
      try { pk = JSON.parse(j); } catch (e) { return; }
      disegna();
    });
    try { if ('wakeLock' in navigator) await navigator.wakeLock.request('screen'); } catch (e) { /* ok */ }
    if (!pk) app.innerHTML = `<h1>Timeless Journeys</h1><div class="box"><h2>Stanza ${esc(codice)}</h2>
      <p>Sei dentro, ${esc(nome)}. Il viaggio comincia quando sulla TV si preme «Inizia».</p></div>`;
  } catch (e) {
    console.error(e);
    errore = 'Non riesco a collegarmi: ' + (e?.message || e);
    ingresso();
  }
}

function manda(id) {
  if (!pk) return;
  const s = pk.s;
  const io = s.giocatori.findIndex((g) => g.uid === uid);
  inviata = pk.n;
  cartaScelta = -1;
  rete.push(`${RADICE}/${codice}/acts`, { s: uid, k: 'm', v: JSON.stringify({ id, p: io, n: pk.n }) });
  disegna();
}

// ------------------------------------------------------------------ disegno
function disegna() {
  if (!pk || !D) return;
  if (!pk.tel) {
    app.innerHTML = `<h1>Timeless Journeys</h1><div class="box"><h2>Partita online</h2>
      <p>Questa partita si gioca con il gioco completo: aprilo sul computer o sul tablet e scegli «Entra in una partita online». Il telefono serve per le partite TV e telefoni.</p></div>`;
    return;
  }
  document.body.classList.add('dentro');
  const s = pk.s;
  const io = s.giocatori.findIndex((g) => g.uid === uid);
  const chi = s.attesa && s.attesa.chi !== undefined ? Number(s.attesa.chi) : -1;
  const tocca = io >= 0 && chi === io && inviata !== pk.n && !s.fine;
  if (tocca && !toccavaAMe) {
    suona('tocca');
    try { navigator.vibrate?.([200, 80, 200]); } catch (e) { /* ok */ }
    scheda = 'gioca';
  }
  toccavaAMe = tocca;
  if (diarioDi < 0 || diarioDi >= s.giocatori.length) diarioDi = Math.max(0, io);

  let corpo = '';
  if (scheda === 'gioca') corpo = gioca(s, io, tocca);
  else if (scheda === 'diari') corpo = diari(s, io);
  else if (scheda === 'gazzetta') corpo = gazzetta(s);
  else if (scheda === 'citta') corpo = citta(s, io);
  else corpo = punti(s);

  const schede = [['gioca', tocca ? 'Tocca a te' : 'Gioca'], ['diari', 'Diari'], ['gazzetta', 'Gazzetta'], ['citta', 'Città'], ['punti', 'Punti']];
  app.innerHTML = testa(s, io, chi, tocca) + corpo +
    `<nav class="schede">${schede.map(([k, t]) => `<button data-sch="${k}" class="${k === scheda ? 'su' : ''} ${k === 'gioca' && tocca && scheda !== 'gioca' ? 'avviso' : ''}">${t}</button>`).join('')}</nav>`;
  collega(s, io);
}

function testa(s, io, chi, tocca) {
  const r = `Round ${ROMANI[Math.min(5, s.round) - 1]}`;
  let stato = '';
  if (s.fine) stato = 'Il Grand Tour è finito: guarda i Punti';
  else if (tocca) stato = 'Tocca a te!';
  else if (chi >= 0) stato = `Tocca a ${esc(s.giocatori[chi].nome)}${s.giocatori[chi].tipo === 'ia' ? ' (computer)' : ''}`;
  if (io < 0) {
    return `<div class="testa"><div class="riga"><span class="nome">Spettatore</span><span>${r}</span></div><div class="stato">${stato}</div></div>`;
  }
  const g = s.giocatori[io];
  const ris = [[`${G}segnalini/moneta1.webp`, g.monete]].concat(GENERI.map((x) => [imgIdea(x), g.idee[x]]),
    [[`${G}segnalini/lettera_${g.colore}.webp`, g.lettere], [`${G}segnalini/caffe_${g.colore}.webp`, g.caffe]]);
  return `<div class="testa">
    <div class="riga"><span class="pallino" style="background:${COLORI[g.colore]}"></span><span class="nome">${esc(g.nome)}</span>
      <span>${r}</span><span class="pv">${g.pv} PV</span></div>
    <div class="risorse">${ris.map(([im, n]) => `<span><img src="${im}" alt="">${n}</span>`).join('')}
      <span>a ${esc(g.pos.startsWith('c') && g.pos.length <= 3 ? 'in campagna' : g.pos)}</span></div>
    <div class="stato">${stato}</div></div>`;
}

function cartaHtml(id, extra = '', cls = '', eti = '') {
  return `<div class="carta ${cls}" ${extra}><img src="${imgCarta(id)}" alt="" loading="lazy">${eti ? `<div class="eti">${esc(eti)}</div>` : ''}</div>`;
}

function gioca(s, io, tocca) {
  if (io < 0) return '<div class="box"><p>La partita è iniziata senza un posto per te: puoi seguirla da qui.</p></div>';
  const g = s.giocatori[io];
  let h = '';
  if (tocca) {
    const tipo = s.attesa.tipo;
    h += `<div class="box tocca"><h2>Tocca a te</h2><p>${esc(pk.t || 'Scegli.')}</p>`;
    if (tipo === 'turno') {
      if (cartaScelta >= 0 && cartaScelta < g.mano.length) {
        const id = g.mano[cartaScelta];
        const su = pk.o.find((o) => o.id === `su:${cartaScelta}`);
        h += `<div style="display:flex;gap:10px;align-items:flex-start"><div style="width:42%">${cartaHtml(id, 'data-zoom="1"')}</div>
          <div style="flex:1"><p>${esc(su ? su.testo : '')}</p>
          <button class="forte" data-o="su:${cartaScelta}">Gioca scoperta</button>
          <button class="centro" data-o="giu:${cartaScelta}">Gioca coperta</button>
          <button class="centro" data-annulla="1">Scegli un’altra carta</button></div></div>`;
      } else {
        h += '<p class="sotto">Tocca una carta della tua mano qui sotto.</p>';
      }
    }
    // le altre scelte
    const altre = pk.o.filter((o) => !(tipo === 'turno' && (o.id.startsWith('su:') || o.id.startsWith('giu:'))));
    for (const o of altre) {
      let im = '';
      if (o.carta) im = `<img src="${imgCarta(o.carta)}" alt="">`;
      else if (o.tessera) im = `<img src="${G}tessere/espl_${o.tessera}.webp" alt="">`;
      else if (o.idea) im = `<img src="${imgIdea(o.idea)}" alt="" style="width:40px">`;
      else if (o.esperienza) im = `<img src="${G}segnalini/esp_${g.colore}_${o.esperienza}.webp" alt="" style="width:44px">`;
      h += `<button data-o="${esc(o.id)}" class="${o.id === 'salta' || o.id === 'fine' ? 'centro' : ''}">${im ? `<span class="opz-img">${im}<span>${esc(o.testo)}</span></span>` : esc(o.testo)}</button>`;
    }
    h += '</div>';
  } else if (inviata === pk.n && s.attesa && Number(s.attesa.chi) === io) {
    h += '<div class="box"><p>Scelta inviata, aspetto la TV...</p></div>';
  }
  // carte giocate e mano
  const giocabili = tocca && s.attesa.tipo === 'turno';
  h += `<div class="box"><h3>Giocate in questo round (${g.area.length}/5)</h3>`;
  if (g.area.length) {
    h += `<div class="carte piccole">${g.area.map((a) => a.giu
      ? `<div class="carta coperta" data-zimg="${imgCarta(a.id)}"><img src="${G}carte/retro.webp" alt=""></div>`
      : cartaHtml(a.id, `data-zimg="${imgCarta(a.id)}"`, '', CAT[cats(a.id)[0]])).join('')}</div>`;
  } else h += '<p class="sotto">Ancora nessuna.</p>';
  const catGiocate = new Set();
  for (const a of g.area) (a.giu ? ['coperta'] : cats(a.id)).forEach((c) => catGiocate.add(c));
  h += `<p class="sotto">Categorie diverse: ${catGiocate.size} (Mercato: ${catGiocate.size >= 4 ? 'qualsiasi livello' : catGiocate.size === 3 ? 'fino al livello II' : catGiocate.size === 2 ? 'livello I' : 'nessuna carta'})</p></div>`;
  h += `<div class="box"><h3>In mano (${g.mano.length})</h3><div class="carte">${g.mano.map((id, i) => cartaHtml(id,
    giocabili ? `data-scegli="${i}"` : `data-zimg="${imgCarta(id)}"`, `${giocabili ? 'giocabile' : ''} ${i === cartaScelta ? 'scelta' : ''}`)).join('')}</div></div>`;
  return h;
}

function cats(id) {
  const p = id.split(':');
  if (p[0] === 'a') return [D.avanzate[p[1]].cat];
  if (p[0] === 'b') return [D.base[Number(p[2])].cat];
  const a = D.andersen[Number(p[1])];
  return a.cats || [a.cat];
}

function diari(s, io) {
  let h = '<div class="box"><div class="chips">' + s.giocatori.map((g, i) =>
    `<button class="chip ${i === diarioDi ? 'su' : ''}" data-dg="${i}"><span class="pallino" style="background:${COLORI[g.colore]}"></span>${esc(g.nome)}${i === io ? ' (tu)' : ''}</button>`).join('') + '</div>';
  const g = s.giocatori[diarioDi];
  const scelte = diarioDi === io && pk.o ? pk.o.filter((o) => o.diario !== undefined) : [];
  for (let di = 0; di < 2; di++) {
    const d = g.diari[di];
    h += `<div class="diario"><img src="${G}diari/${d.id}.webp" alt="">`;
    d.slot.forEach((v, k) => {
      const [x, y] = POS_DIARIO[k];
      let im = '';
      if (v) {
        if (v.startsWith('t:')) im = `<img src="${G}tessere/espl_${v.slice(2)}.webp" alt="">`;
        else if (v.startsWith('a:')) im = `<img src="${G}tessere/amico_${v.slice(2)}.webp" alt="" style="width:70%;margin:auto">`;
        else im = `<img src="${imgIdea(v)}" alt="">`;
      }
      const o = scelte.find((z) => z.diario === di && z.slot === k);
      const w = v && v.startsWith('t:') ? 14 : 11;
      if (im || o) h += `<div class="slot ${o ? 'libero' : ''}" style="left:${x * 100}%;top:${y * 100}%;width:${w}%" ${o ? `data-o="${esc(o.id)}"` : ''}>${im || '&nbsp;'}</div>`;
    });
    h += '</div>';
  }
  if (scelte.length) h += '<p class="sotto">Tocca uno spazio evidenziato per scrivere nel Diario.</p>';
  h += `<h3>Idee</h3><div class="risorse">${GENERI.map((x) => `<span><img src="${imgIdea(x)}" alt="">${g.idee[x]} ${x}</span>`).join('')}</div>`;
  h += `<h3>Tessere Esplorazione (${g.tessere.length})</h3><div class="tessere">${g.tessere.map((t) =>
    `<img src="${G}tessere/espl_${t.id}.webp" class="${t.usata ? 'usata' : ''}" alt="" data-zimg="${G}tessere/espl_${t.id}.webp">`).join('') || '<span class="sotto">nessuna</span>'}</div>`;
  if (g.tessere.length) h += '<p class="sotto">Le tessere scure sono già state attivate.</p>';
  h += `<h3>Amici (${g.amici.length})</h3><div class="tessere">${g.amici.map((a) =>
    `<img src="${G}tessere/amico_${a.citta}_${a.lato || 0}.webp" alt="" style="width:44px;height:72px;object-fit:contain">`).join('') || '<span class="sotto">nessuno</span>'}</div>`;
  if (g.dipinti && g.dipinti.length) h += `<h3>Dipinti di Le Brun</h3><div class="tessere">${g.dipinti.map((t) => `<img src="${G}tessere/lebrun_${t}.webp" alt="">`).join('')}</div>`;
  const esp = {};
  for (const e of g.esp) esp[e] = (esp[e] || 0) + 1;
  h += `<h3>Esperienze ancora da usare</h3><p>${Object.entries(esp).map(([k, n]) => `${ESPERIENZE[k]}${n > 1 ? ' x' + n : ''}`).join(', ') || 'nessuna'}</p>`;
  h += `<h3>In mano</h3><p>${g.mano.length} carte; giocate nel round: ${g.area.length}</p>`;
  return h + '</div>';
}

function gazzetta(s) {
  let h = `<div class="box"><h2>La Gazzetta del Viaggiatore (lato ${s.gazzetta})</h2>
    <p class="sotto">Chi incontra un viaggiatore (Conversare nella sua città) mette un segnalino Esperienza nella sua colonna e prende il premio. A fine partita le maggioranze di ogni colonna valgono 5, 3 e 1 PV.</p></div>`;
  pk.vg.forEach((v, col) => {
    h += `<div class="box"><div class="vg"><img src="${G}viaggiatori/${v.id}.webp" style="border-color:${COL_VG[col]}" alt="" data-zimg="${G}viaggiatori/${v.id}.webp">
      <div><h2 style="color:${COL_VG[col]}">${esc(v.nome)}</h2><p class="sotto">${esc(v.chi)}${v.anni ? ', ' + esc(v.anni) : ''}</p>
      <p>${esc(v.testo)}</p><p><b>Incontrarlo:</b> ${esc(v.premio)}</p></div></div>
      <ul class="tappe">${v.citta.map((c, i) => {
    const sp = s.gaz[col][i];
    const chiuso = s.nn < D.gazzetta_min[i][col];
    const extra = sp ? ` - ${esc(nomeDi(s, sp.p))} (${ESPERIENZE[sp.t]})` : chiuso ? ' - spazio chiuso' : '';
    const cl = i + 1 === s.round ? 'ora' : i + 1 < s.round ? 'passato' : '';
    return `<li class="${cl}">Round ${ROMANI[i]}: ${esc(c)}${extra}${i + 1 === s.round ? ' (ora)' : ''}</li>`;
  }).join('')}</ul></div>`;
  });
  return h;
}

function citta(s, io) {
  if (!cittaVista) cittaVista = io >= 0 && D.citta.includes(s.giocatori[io].pos) ? s.giocatori[io].pos : 'Torino';
  let h = '<div class="box"><div class="chips">' + D.citta.map((c) => `<button class="chip ${c === cittaVista ? 'su' : ''}" data-cv="${c}">${c}</button>`).join('') + '</div>';
  const c = cittaVista;
  const st = s.citta[c];
  const info = pk.ct[c];
  h += `<img class="citta-img" src="${G}citta/${c}.webp" alt="" data-zimg="${G}citta/${c}.webp">`;
  const qui = s.giocatori.filter((g) => g.pos === c).map((g) => g.nome);
  const vg = pk.vg.filter((v) => v.citta[Math.min(5, s.round) - 1] === c).map((v) => v.nome);
  h += `<p><b>Qui adesso:</b> ${qui.length ? esc(qui.join(', ')) : 'nessuno'}${vg.length ? '. Viaggiatori Celebri: ' + esc(vg.join(', ')) : ''}</p>`;
  for (let lato = 0; lato < 2; lato++) {
    const lett = st.lettere[lato].map((p) => nomeDi(s, p));
    h += `<p><b>${esc(info.ab[lato][0])}:</b> ${esc(info.ab[lato][1])}${Number(st.amico) === lato ? ' (tessera Amico)' : ''}${lett.length ? '. Lettere: ' + esc(lett.join(', ')) : ''}</p>`;
  }
  h += `<p><b>Esplorare:</b> una delle ${st.esplora.length} tessere rimaste oppure ${esc(info.esp)}</p>`;
  info.caffe.forEach((t, d) => {
    const occ = st.caffe[d].filter((x) => x !== null).map((p) => nomeDi(s, p));
    h += `<p><b>Caffè ${d + 1}:</b> ${esc(t)}${occ.length ? ' (occupato da ' + esc(occ.join(', ')) + ')' : ''}</p>`;
  });
  if (st.pattuglia) h += `<p><b>Pattuglia Austriaca:</b> blocca qui la prima carta ${CAT[st.pattuglia]}</p>`;
  return h + '</div>';
}

function punti(s) {
  const pt = pk.pt;
  const voci = [['tracciato', 'Tracciato'], ['esplorazioni', 'Tessere'], ['diari', 'Diari'], ['carte', 'Carte Avanzate'], ['esperienze', 'Affinità'],
    ['maggioranze', 'Gazzetta'], ['dipinti', 'Dipinti'], ['pattuglie', 'Pattuglie'], ['totale', 'Totale']];
  let h = `<div class="box"><h2>${s.fine ? 'Punteggio finale' : 'Se la partita finisse adesso'}</h2><div style="overflow-x:auto"><table><tr><th></th>${s.giocatori.map((g) =>
    `<th style="color:${COLORI[g.colore]}">${esc(g.nome)}</th>`).join('')}</tr>`;
  for (const [k, t] of voci) {
    if ((k === 'dipinti' || k === 'pattuglie') && pt.every((x) => !x[k])) continue;
    h += `<tr class="${k === 'totale' ? 'tot' : ''}"><td>${t}</td>${pt.map((x) => `<td>${x[k]}</td>`).join('')}</tr>`;
  }
  h += '</table></div>';
  if (s.fine && s.vincitori) h += `<h2>Vince ${esc(s.vincitori.map((p) => s.giocatori[p].nome).join(' e '))}!</h2>`;
  h += `<h3>Ultime notizie</h3><p class="sotto">${(s.log || []).slice(-8).map(esc).join('<br>')}</p></div>`;
  return h;
}

function collega(s, io) {
  app.querySelectorAll('[data-sch]').forEach((b) => { b.onclick = () => { scheda = b.dataset.sch; window.scrollTo(0, 0); disegna(); }; });
  app.querySelectorAll('[data-o]').forEach((b) => { b.onclick = () => manda(b.dataset.o); });
  app.querySelectorAll('[data-scegli]').forEach((b) => { b.onclick = () => { cartaScelta = Number(b.dataset.scegli); disegna(); window.scrollTo(0, 0); }; });
  app.querySelectorAll('[data-annulla]').forEach((b) => { b.onclick = () => { cartaScelta = -1; disegna(); }; });
  app.querySelectorAll('[data-dg]').forEach((b) => { b.onclick = () => { diarioDi = Number(b.dataset.dg); disegna(); }; });
  app.querySelectorAll('[data-cv]').forEach((b) => { b.onclick = () => { cittaVista = b.dataset.cv; disegna(); }; });
  app.querySelectorAll('[data-zimg]').forEach((b) => { b.onclick = () => ingrandisci(b.dataset.zimg); });
  app.querySelectorAll('[data-zoom]').forEach((b) => { b.onclick = () => ingrandisci(b.querySelector('img').src); });
}

function ingrandisci(src) {
  zoom.innerHTML = `<img src="${src}" alt="">`;
  zoom.hidden = false;
  zoom.onclick = () => { zoom.hidden = true; };
}

if (codice && nome) entra(); else ingresso();
