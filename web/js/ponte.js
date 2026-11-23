// Ponte tra il gioco (Godot, versione web) e il resto: stanza su Firebase, telefoni, ospiti, salvataggi, suoni, QR code.
// Godot lo usa con JavaScriptBridge.get_interface("FR"). Tutto passa come testo JSON.
import { creaRete, nuovoCodice, RADICE, spezza, unisci } from './rete.js';
import { suona } from './suoni.js';

const coda = [];
const q = new URLSearchParams(location.search);
let rete = null;
let codice = '';
let ospite = false;
let stacca = [];

function base() {
  return location.href.split('?')[0].split('#')[0].replace(/index\.html$/, '');
}
// Una sola accensione della rete, anche se la chiedono in due nello stesso momento
// (due accessi anonimi insieme creerebbero due identità diverse).
let accensione = null;
function pronta() {
  if (!accensione) {
    accensione = (async () => { const r = creaRete(); await r.init(); rete = r; return r; })();
    accensione.catch(() => { accensione = null; });
  }
  return accensione;
}
function staccaTutto() {
  for (const f of stacca) { try { f(); } catch (e) { /* ok */ } }
  stacca = [];
}

window.FR = {
  codice() { return codice; },
  parametri() { return JSON.stringify(Object.fromEntries(q)); },
  preleva() {
    if (!coda.length) return '[]';
    const s = JSON.stringify(coda);
    coda.length = 0;
    return s;
  },
  // chi ospita: apre una stanza nuova (o riprende la sua)
  async avvia(riprendi) {
    try {
      await pronta();
      staccaTutto();
      ospite = false;
      let c = '';
      if (riprendi) {
        const h = await rete.get(`${RADICE}/${riprendi}/host`);
        if (h === rete.uid) c = riprendi;
      }
      if (!c) {
        for (let i = 0; i < 30 && !c; i++) {
          const k = nuovoCodice();
          const h = await rete.get(`${RADICE}/${k}/host`);
          if (!h) c = k;
        }
        await rete.set(`${RADICE}/${c}/host`, rete.uid);
        await rete.set(`${RADICE}/${c}/created`, Date.now());
      }
      codice = c;
      const url = base() + '?stanza=' + c + (q.get('rete') === 'locale' ? '&rete=locale' : '');
      coda.push({ e: 'stanza', codice: c, url, uid: rete.uid });
      await rete.set(`${RADICE}/${c}/status`, 'aperta');
      stacca.push(rete.onFigli(`${RADICE}/${c}/seats`, {
        aggiunto: (k, v) => coda.push({ e: 'entra', uid: k, nome: v?.name || '' }),
        cambiato: (k, v) => coda.push({ e: 'entra', uid: k, nome: v?.name || '' }),
        tolto: (k) => coda.push({ e: 'esce', uid: k }),
      }));
      // le mosse restano scritte nella stanza: ognuna dice a quale stato risponde, così non si ripetono
      stacca.push(rete.onFigli(`${RADICE}/${c}/acts`, {
        aggiunto: (k, v) => { if (v && v.s) coda.push({ e: 'azione', uid: v.s, p: v.v, k: v.k }); },
      }));
    } catch (e) {
      console.error(e);
      coda.push({ e: 'errore', msg: String(e?.message || e) });
    }
  },
  // ospite: entra nella stanza di un altro con il gioco completo
  async entra(c, nome) {
    try {
      await pronta();
      staccaTutto();
      c = String(c || '').toUpperCase();
      const h = await rete.get(`${RADICE}/${c}/host`);
      if (!h) { coda.push({ e: 'errore', msg: 'la stanza ' + c + ' non esiste' }); return; }
      codice = c;
      ospite = true;
      await rete.set(`${RADICE}/${c}/seats/${rete.uid}`, { uid: rete.uid, name: String(nome || 'Pilota').slice(0, 16) });
      coda.push({ e: 'dentro', codice: c, uid: rete.uid });
      stacca.push(rete.on(`${RADICE}/${c}/game`, (v) => { const j = unisci(v); if (j) coda.push({ e: 'stato', j }); }));
    } catch (e) {
      console.error(e);
      coda.push({ e: 'errore', msg: String(e?.message || e) });
    }
  },
  chiudi() {
    staccaTutto();
    if (rete && codice && ospite) rete.remove(`${RADICE}/${codice}/seats/${rete.uid}`).catch(() => {});
    codice = '';
  },
  stato(j) { if (rete && codice && !ospite) rete.set(`${RADICE}/${codice}/game`, spezza(j)).catch((e) => console.warn(e)); },
  // copia del salvataggio dentro la stanza (solo chi ospita la può scrivere)
  salvaStanza(v) { if (rete && codice && !ospite) rete.set(`${RADICE}/${codice}/labels`, v ? spezza(v) : null).catch((e) => console.warn(e)); },
  azione(k, p) { if (rete && codice) rete.push(`${RADICE}/${codice}/acts`, { s: rete.uid, k, v: p }).catch?.((e) => console.warn(e)); },
  suono(n) { suona(n); },
  schermoIntero() {
    const d = document.documentElement;
    try {
      if (document.fullscreenElement || document.webkitFullscreenElement) (document.exitFullscreen || document.webkitExitFullscreen).call(document);
      else (d.requestFullscreen || d.webkitRequestFullscreen).call(d);
    } catch (e) { /* ok */ }
  },
  chiedi(testo, proposta) { try { return window.prompt(testo, proposta || '') || ''; } catch (e) { return ''; } },
  qr(testo) {
    /* global qrcode */
    try {
      const qq = qrcode(0, 'M');
      qq.addData(testo);
      qq.make();
      const n = qq.getModuleCount();
      let s = '';
      for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) s += qq.isDark(y, x) ? '1' : '0';
      return s;
    } catch (e) { return ''; }
  },
  salva(k, v) { try { if (v) localStorage.setItem(k, v); else localStorage.removeItem(k); } catch (e) { /* ok */ } },
  carica(k) { try { return localStorage.getItem(k) || ''; } catch (e) { return ''; } },
  // copia del salvataggio su Firebase, legata a questo browser
  async salvaRemoto(v) {
    try { await pronta(); await rete.set(`timeless/salvataggi/${rete.uid}`, v ? { stato: v } : null); } catch (e) { console.warn('salvataggio remoto', e); }
  },
  async caricaRemoto() {
    try { await pronta(); const v = await rete.get(`timeless/salvataggi/${rete.uid}`); coda.push({ e: 'salvataggio', j: v?.stato || '' }); } catch (e) { console.warn(e); }
  },
};
