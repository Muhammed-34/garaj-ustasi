const st = (arr) => arr.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}"${a !== 1 ? ` stop-opacity="${a}"` : ''}/>`).join('');
const rg = (id, stops, cx = 0.38, cy = 0.32, r = 0.75) => `<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}" fx="${cx}" fy="${cy}">${st(stops)}</radialGradient>`;
const lg = (id, stops, x2 = 0, y2 = 1) => `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${st(stops)}</linearGradient>`;

export const CATS = {
  pamuk: { l: '#ffffff', b: '#f3ede6', d: '#c9bdb0', s: null, el: '#d6ecff', e: '#4f97dc', w: '#b3a699' },
  tarcin: { l: '#ffd6a3', b: '#ef9340', d: '#b0591a', s: '#b3561a', el: '#fff2a8', e: '#d9a21e', w: '#ffffff' },
  gece: { l: '#6e666c', b: '#2f2b2f', d: '#131113', s: null, el: '#fff6ad', e: '#e5bd1c', w: '#d9d0d0' },
  boncuk: { l: '#fff6e6', b: '#eed8b2', d: '#c3a276', s: null, el: '#dbf2c4', e: '#62a446', w: '#ffffff' },
  fistik: { l: '#f2d6b3', b: '#c79d70', d: '#8a6641', s: '#86603a', el: '#fff2a8', e: '#c99d1c', w: '#ffffff' },
  limon: { l: '#fff3c0', b: '#f1cb66', d: '#c49b35', s: '#cf9a2a', el: '#dbf2c4', e: '#5a983a', w: '#ffffff' },
  duman: { l: '#d8dee4', b: '#98a1ab', d: '#5f6772', s: null, el: '#fff4b3', e: '#dfb52b', w: '#ffffff' },
  tekir: { l: '#d3cabe', b: '#9b9183', d: '#5e564c', s: '#544a40', el: '#e3f6cc', e: '#5a983a', w: '#ffffff' },
};

export const DEFS = [
  '<filter id="ds" x="-25%" y="-25%" width="150%" height="160%"><feDropShadow dx="0" dy="1.6" stdDeviation="1.3" flood-color="#2a1a10" flood-opacity="0.33"/></filter>',
  '<filter id="dsl" x="-20%" y="-20%" width="140%" height="150%"><feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#2a1a10" flood-opacity="0.28"/></filter>',
  rg('gs', [[0, '#2a1a10', 0.35], [1, '#2a1a10', 0]], 0.5, 0.5, 0.5),
  lg('shine', [[0, '#ffffff', 0.9], [1, '#ffffff', 0]]),
  lg('bowlR', [[0, '#8f2418'], [0.35, '#e0503c'], [0.8, '#b8321f'], [1, '#7a1c12']], 1, 0),
  lg('bowlRim', [[0, '#ff8f76'], [1, '#d9442f']]),
  rg('kib', [[0, '#e3ad6e'], [0.55, '#9a5a26'], [1, '#5e3410']]),
  rg('yarn', [[0, '#e6ccff'], [0.45, '#a974e0'], [1, '#6a3ba3']]),
  lg('fishB', [[0, '#86cbff'], [0.5, '#3a8fd6'], [1, '#1d5891']]),
  lg('finB', [[0, '#5aa9ea'], [1, '#1d5891']]),
  rg('pawB', [[0, '#f5c9a2'], [0.55, '#c9875a'], [1, '#855030']]),
  rg('bean', [[0, '#ffd0db'], [0.6, '#f07f9a'], [1, '#c24d6a']]),
  rg('gold', [[0, '#fff5bf'], [0.45, '#f2c230'], [0.8, '#c48f1c'], [1, '#8a6212']]),
  rg('tom', [[0, '#ff9078'], [0.45, '#e8392a'], [0.85, '#b3221a'], [1, '#7d1510']]),
  lg('leaf', [[0, '#86c962'], [1, '#3a6b2c']]),
  lg('pep', [[0, '#a8e070'], [0.5, '#4f9a32'], [1, '#2a621a']], 1, 0),
  rg('egg', [[0, '#ffffff'], [0.5, '#fbf2e0'], [0.9, '#e0c9a4'], [1, '#c9ad82']], 0.4, 0.35),
  rg('oni', [[0, '#ebbbe6'], [0.5, '#a9589f'], [1, '#6a2d65']]),
  lg('chTop', [[0, '#ffeca6'], [1, '#f5c64a']]),
  lg('chSide', [[0, '#f0b83a'], [1, '#c48a18']]),
  rg('earIn', [[0, '#ffd7dd'], [1, '#e48a9b']], 0.5, 0.6, 0.7),
  rg('nose', [[0, '#ffc0ca'], [1, '#d4667b']]),
  rg('blush', [[0, '#ff94ab', 0.55], [1, '#ff94ab', 0]], 0.5, 0.5, 0.5),
  rg('muz', [[0, '#ffffff', 0.75], [1, '#ffffff', 0]], 0.5, 0.45, 0.55),
  rg('f-sil', [[0, '#ece3d8'], [0.55, '#cdbfae'], [1, '#a99886']]),
  lg('iron', [[0, '#5e5856'], [1, '#1c1918']]),
  rg('sauce', [[0, '#ffa062'], [0.6, '#df4f2b'], [1, '#a32e18']], 0.45, 0.4),
  rg('eggW', [[0, '#ffffff'], [0.7, '#fff6e8'], [1, '#e8d9c0']], 0.4, 0.35),
  rg('yolk', [[0, '#ffe391'], [0.6, '#f5a623'], [1, '#cc7508']], 0.35, 0.3),
  rg('tomC', [[0, '#ff806a'], [1, '#b8261b']]),
  lg('cer', [[0, '#cfd4db'], [0.35, '#ffffff'], [0.7, '#e7eaee'], [1, '#aab2bd']], 1, 0),
  lg('cerRim', [[0, '#ffffff'], [1, '#d2d8df']]),
  rg('soup', [[0, '#ffb95e'], [0.6, '#e8862e'], [1, '#bb5e18']], 0.45, 0.4),
  lg('lemon', [[0, '#fff49e'], [1, '#efbd2a']]),
  lg('plate', [[0, '#ffffff'], [1, '#d9d2c7']]),
  rg('plateIn', [[0, '#faf7f1'], [1, '#e3dacb']], 0.45, 0.4),
  lg('cuc', [[0, '#93d466'], [1, '#3b8428']]),
  lg('dome', [[0, '#8f979f'], [0.35, '#f0f3f6'], [0.65, '#c2c8ce'], [1, '#747c85']], 1, 0),
  lg('wood', [[0, '#f3d19c'], [1, '#bd874b']]),
  lg('metal', [[0, '#f4f6f8'], [1, '#8d939b']], 1, 1),
  rg('redGlow', [[0, '#ff5a4a', 0.9], [1, '#ff5a4a', 0]], 0.5, 0.5, 0.5),
  rg('face', [[0, '#ffe2c4'], [0.6, '#f2bb8c'], [1, '#c98a5a']]),
  ...Object.entries(CATS).flatMap(([n, c]) => [
    rg(`f-${n}`, [[0, c.l], [0.55, c.b], [1, c.d]]),
    rg(`i-${n}`, [[0, c.el], [0.65, c.e], [1, '#2a1c10']], 0.45, 0.35),
  ]),
].join('');

export const TILES = {
  'k-m': '<ellipse cx="24" cy="42" rx="15" ry="3" fill="url(#gs)"/><g filter="url(#ds)"><path d="M7 24h34l-3.5 12.5A5 5 0 0 1 32.7 40H15.3a5 5 0 0 1-4.8-3.5z" fill="url(#bowlR)"/><ellipse cx="24" cy="24" rx="17" ry="5.5" fill="url(#bowlRim)"/><ellipse cx="24" cy="23.6" rx="13.5" ry="3.8" fill="#5a2a18"/><circle cx="18" cy="21.5" r="3.4" fill="url(#kib)"/><circle cx="24.5" cy="19.5" r="3.6" fill="url(#kib)"/><circle cx="30" cy="22" r="3.3" fill="url(#kib)"/><circle cx="21" cy="17.2" r="3" fill="url(#kib)"/><circle cx="27.5" cy="16" r="2.8" fill="url(#kib)"/></g><path d="M11 28c2 4 3 7 5 9" stroke="#ffffff" stroke-opacity="0.45" stroke-width="2" fill="none" stroke-linecap="round"/>',
  'k-y': '<ellipse cx="24" cy="42" rx="13" ry="2.8" fill="url(#gs)"/><circle cx="24" cy="23" r="15" fill="url(#yarn)" filter="url(#ds)"/><path d="M11 17Q24 22 33 34M10 26Q22 26 29 36M19 9Q31 18 29 36" stroke="#5e3196" stroke-width="2.2" fill="none" stroke-linecap="round" opacity="0.8"/><path d="M13 13Q26 16 37 28M29 9Q22 21 25 38" stroke="#dcc2f7" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.85"/><path d="M34 33c4 2 6 6 4 10" stroke="#9b6fc6" stroke-width="2.4" fill="none" stroke-linecap="round"/><ellipse cx="18" cy="15" rx="5" ry="2.6" fill="url(#shine)" transform="rotate(-30 18 15)"/>',
  'k-b': '<ellipse cx="24" cy="41" rx="15" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><path d="M34 23L44 13Q47 23 44 33z" fill="url(#finB)"/><path d="M18 14c3-5 10-6 13-2l-4 5z" fill="url(#finB)"/><path d="M5 23c5-10 17-13 30-6 2 1 2 11 0 12-13 7-25 4-30-6z" fill="url(#fishB)"/><path d="M7 25c6 7 17 8 27 3-9 2-19 1-27-3z" fill="#c4e6ff" opacity="0.6"/><circle cx="13" cy="20.5" r="3.3" fill="#ffffff"/><circle cx="12.4" cy="20.8" r="2.1" fill="#10263f"/><circle cx="11.7" cy="19.9" r="0.9" fill="#ffffff"/><path d="M21 16c2.5 4 2.5 10 0 14" stroke="#174b7c" stroke-width="1.6" fill="none" opacity="0.5"/></g><path d="M10 18c5-5 13-6 20-3" stroke="#ffffff" stroke-opacity="0.65" stroke-width="2" fill="none" stroke-linecap="round"/>',
  'k-p': '<ellipse cx="24" cy="42.5" rx="14" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><path d="M24 22c7 0 12 6 12 11s-5 7-12 7-12-2-12-7 5-11 12-11z" fill="url(#pawB)"/><ellipse cx="10.5" cy="21" rx="4.3" ry="5.3" fill="url(#pawB)"/><ellipse cx="17.5" cy="12.5" rx="4.3" ry="5.3" fill="url(#pawB)"/><ellipse cx="30.5" cy="12.5" rx="4.3" ry="5.3" fill="url(#pawB)"/><ellipse cx="37.5" cy="21" rx="4.3" ry="5.3" fill="url(#pawB)"/></g><ellipse cx="24" cy="32.5" rx="6.5" ry="5" fill="url(#bean)"/><ellipse cx="10.5" cy="21.8" rx="2.3" ry="3" fill="url(#bean)"/><ellipse cx="17.5" cy="13.3" rx="2.3" ry="3" fill="url(#bean)"/><ellipse cx="30.5" cy="13.3" rx="2.3" ry="3" fill="url(#bean)"/><ellipse cx="37.5" cy="21.8" rx="2.3" ry="3" fill="url(#bean)"/><ellipse cx="21" cy="30.5" rx="2.4" ry="1.2" fill="#ffffff" opacity="0.55"/>',
  'k-c': '<ellipse cx="24" cy="42.5" rx="12" ry="2.6" fill="url(#gs)"/><circle cx="24" cy="8" r="3.4" fill="none" stroke="#b8871c" stroke-width="2.2"/><circle cx="24" cy="25" r="14" fill="url(#gold)" filter="url(#ds)"/><path d="M10.5 21.5h27" stroke="#8a6212" stroke-width="2.2" opacity="0.7"/><path d="M10.8 24h26.4" stroke="#fff0a8" stroke-width="1" opacity="0.6"/><circle cx="24" cy="31" r="3" fill="#4a3208"/><path d="M24 33v6" stroke="#4a3208" stroke-width="2.2" stroke-linecap="round"/><ellipse cx="18" cy="16" rx="5" ry="2.8" fill="#ffffff" opacity="0.8" transform="rotate(-35 18 16)"/>',
  't-d': '<ellipse cx="24" cy="42.5" rx="14" ry="2.8" fill="url(#gs)"/><path d="M24 12c9 0 16 6 16 14s-7 14-16 14S8 34 8 26s7-14 16-14z" fill="url(#tom)" filter="url(#ds)"/><path d="M17 21c-2 4-2 9 1 14M31 21c2 4 2 9-1 14" stroke="#8f1d14" stroke-width="1.4" fill="none" opacity="0.3"/><g fill="url(#leaf)"><ellipse cx="18.5" cy="14" rx="5.5" ry="2" transform="rotate(15 18.5 14)"/><ellipse cx="29.5" cy="14" rx="5.5" ry="2" transform="rotate(-15 29.5 14)"/><ellipse cx="21" cy="17" rx="4.5" ry="1.8" transform="rotate(-40 21 17)"/><ellipse cx="27" cy="17" rx="4.5" ry="1.8" transform="rotate(40 27 17)"/></g><path d="M24 14V7" stroke="#3a6b2c" stroke-width="2.4" stroke-linecap="round"/><ellipse cx="16.5" cy="21.5" rx="4.5" ry="2.8" fill="#ffffff" opacity="0.7" transform="rotate(-30 16.5 21.5)"/>',
  't-b': '<ellipse cx="26" cy="42.5" rx="14" ry="2.6" fill="url(#gs)"/><path d="M13 11c-3 9 1 22 18 28 4 1.5 6-1 4.5-3.5C26 29 20 20 19 12z" fill="url(#pep)" filter="url(#ds)"/><path d="M12 12c0-4 4-6 7-4v5c-2-2-5-2-7-1z" fill="#3f6f27"/><path d="M15.5 8c-1-3 1-5 3-5" stroke="#3a6b2c" stroke-width="2.2" fill="none" stroke-linecap="round"/><path d="M15.5 16c0 8 4 14 11.5 19" stroke="#ffffff" stroke-opacity="0.6" stroke-width="2.2" fill="none" stroke-linecap="round"/>',
  't-y': '<ellipse cx="24" cy="43" rx="12" ry="2.6" fill="url(#gs)"/><path d="M24 6c8 0 13.5 12 13.5 20a13.5 13.5 0 0 1-27 0C10.5 18 16 6 24 6z" fill="url(#egg)" filter="url(#ds)"/><ellipse cx="18.5" cy="17" rx="3.2" ry="5.5" fill="#ffffff" opacity="0.9" transform="rotate(20 18.5 17)"/>',
  't-s': '<ellipse cx="24" cy="43" rx="13" ry="2.6" fill="url(#gs)"/><path d="M24 8c2 6 14 10 14 20a14 12.5 0 0 1-28 0c0-10 12-14 14-20z" fill="url(#oni)" filter="url(#ds)"/><path d="M24 11c-5 7-7 15-5 28M24 11c5 7 7 15 5 28M24 11c-9 8-12 16-10 26M24 11c9 8 12 16 10 26" stroke="#4e1f4b" stroke-width="1" fill="none" opacity="0.4"/><path d="M24 8V3" stroke="#c9a56a" stroke-width="2" stroke-linecap="round"/><ellipse cx="18" cy="24" rx="3" ry="6" fill="#ffffff" opacity="0.45" transform="rotate(15 18 24)"/>',
  't-p': '<ellipse cx="24" cy="42.5" rx="17" ry="2.8" fill="url(#gs)"/><g filter="url(#ds)"><path d="M5 26L30 12l13 8L18 34z" fill="url(#chTop)"/><path d="M5 26l13 8v6L5 32z" fill="#d49b27"/><path d="M18 34l25-14v6L18 40z" fill="url(#chSide)"/></g><ellipse cx="24" cy="22.5" rx="2.8" ry="1.6" fill="#c98f1c"/><ellipse cx="15.5" cy="27" rx="2" ry="1.2" fill="#c98f1c"/><ellipse cx="32.5" cy="18.5" rx="1.6" ry="1" fill="#c98f1c"/><ellipse cx="31" cy="31" rx="2" ry="1.4" fill="#a8740f"/><path d="M9 25.5L29 14" stroke="#ffffff" stroke-opacity="0.6" stroke-width="1.6" stroke-linecap="round"/>',
};

export function catHead(n) {
  const c = CATS[n];
  const stripes = c.s ? `<path d="M50 24v12M40 26l3 10M60 26l-3 10" stroke="${c.s}" stroke-width="4.5" stroke-linecap="round" opacity="0.85"/><path d="M12 55h10M13 63l9-2M88 55H78M87 63l-9-2" stroke="${c.s}" stroke-width="3.5" stroke-linecap="round" opacity="0.7"/>` : '';
  const eye = (x) => `<ellipse cx="${x}" cy="55" rx="8" ry="9.5" fill="#1b1410"/><ellipse cx="${x}" cy="55.5" rx="6.8" ry="8.3" fill="url(#i-${n})"/><ellipse cx="${x}" cy="56.5" rx="3" ry="5.5" fill="#120c08"/><circle cx="${x - 3}" cy="51" r="2.8" fill="#ffffff"/><circle cx="${x + 3}" cy="60" r="1.3" fill="#ffffff" opacity="0.85"/>`;
  return `<path d="M16 46C12 30 14 14 20 8c8 4 18 12 24 20z" fill="url(#f-${n})"/><path d="M84 46C88 30 86 14 80 8c-8 4-18 12-24 20z" fill="url(#f-${n})"/><path d="M22 38c-2-9-1-18 2-23 5 3 10 8 14 13z" fill="url(#earIn)"/><path d="M78 38c2-9 1-18-2-23-5 3-10 8-14 13z" fill="url(#earIn)"/><path d="M50 22c24 0 40 15 40 36 0 20-17 32-40 32S10 78 10 58c0-21 16-36 40-36z" fill="url(#f-${n})"/>${stripes}<ellipse cx="50" cy="71" rx="21" ry="13" fill="url(#muz)"/><ellipse cx="23" cy="68" rx="8" ry="5" fill="url(#blush)"/><ellipse cx="77" cy="68" rx="8" ry="5" fill="url(#blush)"/>${eye(34)}${eye(66)}<path d="M45 66h10c0 3-3 5-5 6-2-1-5-3-5-6z" fill="url(#nose)"/><path d="M50 72v3M50 75c-2 3-6 3-8 1M50 75c2 3 6 3 8 1" stroke="#4a3228" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.7"/><path d="M28 70H9M29 75l-16 4M72 70h19M71 75l16 4" stroke="${c.w}" stroke-width="1.3" opacity="0.85" stroke-linecap="round"/><ellipse cx="37" cy="32" rx="12" ry="4.5" fill="#ffffff" opacity="0.35" transform="rotate(-15 37 32)"/>`;
}

export function catSit(n) {
  const c = CATS[n];
  return `<ellipse cx="50" cy="126" rx="38" ry="5" fill="url(#gs)"/><path d="M74 118c16-2 22-14 18-28" stroke="${c.d}" stroke-width="9" fill="none" stroke-linecap="round"/><path d="M74 118c16-2 22-14 18-28" stroke="${c.b}" stroke-width="6" fill="none" stroke-linecap="round"/><path d="M20 124c-4-30 8-56 30-56s34 26 30 56z" fill="url(#f-${n})"/><ellipse cx="50" cy="100" rx="14" ry="20" fill="url(#muz)"/><ellipse cx="38" cy="122" rx="9" ry="6" fill="url(#f-${n})"/><ellipse cx="62" cy="122" rx="9" ry="6" fill="url(#f-${n})"/><g transform="translate(6 -4) scale(0.88)">${catHead(n)}</g>`;
}

export const SIL = '<path d="M16 46C12 30 14 14 20 8c8 4 18 12 24 20z" fill="url(#f-sil)"/><path d="M84 46C88 30 86 14 80 8c-8 4-18 12-24 20z" fill="url(#f-sil)"/><path d="M50 22c24 0 40 15 40 36 0 20-17 32-40 32S10 78 10 58c0-21 16-36 40-36z" fill="url(#f-sil)"/><text x="50" y="70" text-anchor="middle" font-family="Fredoka, Nunito, sans-serif" font-weight="700" font-size="36" fill="#ffffff" opacity="0.9">?</text>';

const pan = '<ellipse cx="78" cy="106" rx="66" ry="9" fill="url(#gs)"/><path d="M128 66l28-8c4-1 6 5 2 7l-28 10z" fill="url(#iron)"/><ellipse cx="72" cy="72" rx="64" ry="34" fill="url(#iron)"/><ellipse cx="72" cy="66" rx="61" ry="30" fill="#2a2624"/><ellipse cx="72" cy="68" rx="55" ry="26" fill="url(#sauce)"/><ellipse cx="42" cy="72" rx="6" ry="4" fill="url(#tomC)"/><ellipse cx="62" cy="84" rx="7" ry="4" fill="url(#tomC)"/><ellipse cx="100" cy="60" rx="6" ry="4" fill="url(#tomC)"/><ellipse cx="108" cy="78" rx="6" ry="4" fill="url(#tomC)"/><ellipse cx="80" cy="88" rx="5" ry="3" fill="url(#tomC)"/><ellipse cx="55" cy="61" rx="14" ry="9" fill="url(#eggW)"/><circle cx="55" cy="61" r="6" fill="url(#yolk)"/><circle cx="53" cy="59" r="1.8" fill="#ffffff" opacity="0.8"/><ellipse cx="90" cy="74" rx="14" ry="9" fill="url(#eggW)"/><circle cx="90" cy="74" r="6" fill="url(#yolk)"/><circle cx="88" cy="72" r="1.8" fill="#ffffff" opacity="0.8"/><path d="M34 80l7-3M104 66l7 2M72 92l6-3M78 52l-4 5" stroke="#4e9a32" stroke-width="3.5" stroke-linecap="round"/><circle cx="68" cy="74" r="1.6" fill="#2f7a22"/><circle cx="74" cy="58" r="1.4" fill="#2f7a22"/><circle cx="46" cy="80" r="1.4" fill="#2f7a22"/><path d="M16 60c10-16 40-24 70-22" stroke="#ffffff" stroke-opacity="0.25" stroke-width="3" fill="none" stroke-linecap="round"/>';

export const DISH = {
  menemen: pan,
  steam: '<path d="M50 30c-7-9 7-13 0-22M78 26c-7-9 7-13 0-22M106 30c-7-9 7-13 0-22" stroke="#b3a595" stroke-width="4" fill="none" stroke-linecap="round" opacity="0.55"/>',
  mercimek: '<ellipse cx="80" cy="106" rx="58" ry="8" fill="url(#gs)"/><path d="M18 56h124c-2 30-28 48-62 48S20 86 18 56z" fill="url(#cer)"/><path d="M24 74c14 12 34 16 56 16s42-4 56-16" stroke="#3f6fb0" stroke-width="3" fill="none" opacity="0.75"/><ellipse cx="80" cy="56" rx="62" ry="16" fill="url(#cerRim)"/><ellipse cx="80" cy="57" rx="54" ry="12" fill="url(#soup)"/><path d="M92 50c10-6 24-4 28 2-8 6-20 7-28-2z" fill="url(#lemon)"/><path d="M95 50c8-3 18-2 22 2" stroke="#fff8c8" stroke-width="1.5" fill="none"/><circle cx="60" cy="55" r="1.6" fill="#a8201a"/><circle cx="70" cy="60" r="1.6" fill="#a8201a"/><circle cx="66" cy="52" r="1.4" fill="#a8201a"/><circle cx="78" cy="58" r="1.4" fill="#a8201a"/><ellipse cx="56" cy="59" rx="5" ry="2.2" fill="url(#leaf)" transform="rotate(-25 56 59)"/><path d="M30 66c4 14 14 24 26 30" stroke="#ffffff" stroke-opacity="0.65" stroke-width="4" fill="none" stroke-linecap="round"/>',
  coban: '<ellipse cx="80" cy="104" rx="70" ry="9" fill="url(#gs)"/><ellipse cx="80" cy="74" rx="70" ry="30" fill="url(#plate)"/><ellipse cx="80" cy="72" rx="52" ry="21" fill="url(#plateIn)"/><rect x="48" y="60" width="16" height="13" rx="3" fill="url(#tomC)"/><rect x="92" y="56" width="16" height="13" rx="3" fill="url(#tomC)"/><rect x="100" y="74" width="15" height="12" rx="3" fill="url(#tomC)"/><rect x="70" y="66" width="16" height="13" rx="3" fill="url(#cuc)"/><rect x="73" y="69" width="10" height="7" rx="2" fill="#d8f0b5"/><rect x="56" y="78" width="15" height="12" rx="3" fill="url(#cuc)"/><rect x="59" y="81" width="9" height="6" rx="2" fill="#d8f0b5"/><ellipse cx="88" cy="84" rx="8" ry="4" fill="none" stroke="#e6c3e4" stroke-width="3"/><circle cx="66" cy="58" r="2" fill="#3f8a2a"/><circle cx="104" cy="70" r="2" fill="#3f8a2a"/><circle cx="84" cy="62" r="1.6" fill="#3f8a2a"/><rect x="50" y="61.5" width="10" height="2.5" rx="1.2" fill="#ffffff" opacity="0.45"/><rect x="94" y="57.5" width="10" height="2.5" rx="1.2" fill="#ffffff" opacity="0.45"/>',
  kilit: '<ellipse cx="80" cy="106" rx="70" ry="8" fill="url(#gs)"/><ellipse cx="80" cy="94" rx="68" ry="13" fill="url(#plate)"/><path d="M22 92c0-36 26-58 58-58s58 22 58 58z" fill="url(#dome)"/><circle cx="80" cy="30" r="7" fill="url(#dome)"/><path d="M40 72c4-18 18-30 34-33" stroke="#ffffff" stroke-opacity="0.7" stroke-width="5" fill="none" stroke-linecap="round"/><circle cx="80" cy="68" r="15" fill="#4e463f" opacity="0.8"/><path d="M74 68v-5a6 6 0 0 1 12 0v5" stroke="#ffffff" stroke-width="2.6" fill="none"/><rect x="72" y="67" width="16" height="12" rx="2.5" fill="#ffffff"/>',
};

export const STAR_ON = '<path d="M24 3l6.2 12.6 13.9 2-10 9.8 2.4 13.8L24 34.7 11.5 41.2l2.4-13.8-10-9.8 13.9-2z" fill="url(#gold)" stroke="#a8740f" stroke-width="1.5" stroke-linejoin="round"/><path d="M16 17l5-1" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round" opacity="0.8"/>';
export const STAR_OFF = '<path d="M24 3l6.2 12.6 13.9 2-10 9.8 2.4 13.8L24 34.7 11.5 41.2l2.4-13.8-10-9.8 13.9-2z" fill="#e4dacd" stroke="#cbbdab" stroke-width="1.5" stroke-linejoin="round"/>';

export const ICON = {
  lazer: '<path d="M8 40L26 22" stroke="#9aa1a9" stroke-width="8" stroke-linecap="round"/><path d="M8 40L26 22" stroke="#e9ecef" stroke-width="4" stroke-linecap="round"/><circle cx="15" cy="33" r="2.2" fill="#e8392a"/><path d="M29 19l8-8" stroke="#ff3b2f" stroke-width="2.2" stroke-linecap="round" opacity="0.85"/><circle cx="40" cy="8" r="7" fill="url(#redGlow)"/><circle cx="40" cy="8" r="2.8" fill="#ff5a4a"/>',
  nane: '<path d="M24 43C10 36 8 20 18 7c10 10 12 25 6 36z" fill="url(#leaf)"/><path d="M24 43c8-6 18-8 20-21-10-2-18 4-20 21z" fill="url(#leaf)"/><path d="M24 43C22 30 19 18 18 7M24 43c4-8 10-14 20-21" stroke="#2a5520" stroke-width="1.3" fill="none" opacity="0.6"/><ellipse cx="15" cy="21" rx="2" ry="6" fill="#ffffff" opacity="0.4" transform="rotate(-15 15 21)"/>',
  pence: '<path d="M10 6c8 10 8 26 1 38 2-13 2-26-1-38z" fill="#f5eee6" stroke="#8a7a6a" stroke-width="1.6" stroke-linejoin="round"/><path d="M22 4c8 11 8 28 1 41 2-14 2-28-1-41z" fill="#f5eee6" stroke="#8a7a6a" stroke-width="1.6" stroke-linejoin="round"/><path d="M34 6c8 10 8 26 1 38 2-13 2-26-1-38z" fill="#f5eee6" stroke="#8a7a6a" stroke-width="1.6" stroke-linejoin="round"/>',
  oklava: '<g transform="rotate(-40 24 24)"><rect x="0" y="21" width="9" height="6" rx="3" fill="#7a5130"/><rect x="39" y="21" width="9" height="6" rx="3" fill="#7a5130"/><rect x="6" y="17" width="36" height="14" rx="7" fill="url(#wood)" stroke="#8a5a2e" stroke-width="1.2"/><rect x="10" y="19" width="28" height="3" rx="1.5" fill="#ffffff" opacity="0.45"/></g>',
  kepce: '<path d="M36 4L22 26" stroke="#9aa1a9" stroke-width="5" stroke-linecap="round"/><path d="M36 4L22 26" stroke="#eef1f4" stroke-width="2" stroke-linecap="round"/><path d="M5 26h28c0 9-6 16-14 16S5 35 5 26z" fill="url(#metal)" stroke="#7d848c" stroke-width="1.2"/><ellipse cx="19" cy="26" rx="14" ry="3.6" fill="#6e767e"/>',
  bicak: '<path d="M15 32L41 6c4 9 1 19-12 28z" fill="url(#metal)" stroke="#7d848c" stroke-width="1.2" stroke-linejoin="round"/><path d="M18 31L40 9" stroke="#ffffff" stroke-width="1.4" opacity="0.8"/><path d="M15 32l-9 9" stroke="#6b4524" stroke-width="7" stroke-linecap="round"/><path d="M13 34l-6 6" stroke="#a36f45" stroke-width="2" stroke-linecap="round"/>',
};
