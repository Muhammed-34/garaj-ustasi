// Recipe book dishes, drawn in the same 160x120 frame and gradients as the approved design's dishes.
import { DISH } from './m3v2-assets.mjs';

const st = (arr) => arr.map(([o, c]) => `<stop offset="${o}" stop-color="${c}"/>`).join('');
const lg = (id, stops, x2 = 0, y2 = 1) => `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${st(stops)}</linearGradient>`;

export const DISH_DEFS = [
  lg('rc-omelet', [[0, '#ffe486'], [1, '#eeaa2a']]),
  lg('rc-dough', [[0, '#f8dca4'], [1, '#d49650']]),
  lg('rc-pepper', [[0, '#9fd970'], [1, '#3b8327']], 1, 0),
  lg('rc-eggplant', [[0, '#9563b0'], [1, '#3a1c4d']]),
  lg('rc-cheese', [[0, '#fffcea'], [1, '#ece0b4']]),
  lg('rc-meat', [[0, '#b0603a'], [1, '#5e2a14']]),
].join('');

const shadow = (rx = 68) => `<ellipse cx="80" cy="106" rx="${rx}" ry="8" fill="url(#gs)"/>`;
const plate = shadow(70) + '<ellipse cx="80" cy="76" rx="70" ry="30" fill="url(#plate)"/><ellipse cx="80" cy="74" rx="54" ry="22" fill="url(#plateIn)"/>';
const bowl = shadow(58) + '<path d="M18 56h124c-2 30-28 48-62 48S20 86 18 56z" fill="url(#cer)"/><path d="M24 74c14 12 34 16 56 16s42-4 56-16" stroke="#3f6fb0" stroke-width="3" fill="none" opacity="0.75"/><ellipse cx="80" cy="56" rx="62" ry="16" fill="url(#cerRim)"/>';
const herbs = (points) => points.map(([x, y, r = 0]) => `<ellipse cx="${x}" cy="${y}" rx="5" ry="2.2" fill="url(#leaf)" transform="rotate(${r} ${x} ${y})"/>`).join('');
const egg = (x, y, s = 1) => `<ellipse cx="${x}" cy="${y}" rx="${14 * s}" ry="${9 * s}" fill="url(#eggW)"/><circle cx="${x}" cy="${y}" r="${6 * s}" fill="url(#yolk)"/><circle cx="${x - 2 * s}" cy="${y - 2 * s}" r="${1.8 * s}" fill="#ffffff" opacity="0.8"/>`;
const tomato = (x, y, r = 8) => `<circle cx="${x}" cy="${y}" r="${r}" fill="url(#tomC)"/><circle cx="${x}" cy="${y}" r="${r * 0.55}" fill="none" stroke="#ffd1c4" stroke-width="1.4" opacity="0.8"/>`;

const omlet = plate +
  '<path d="M36 78c4-22 30-30 56-26 20 3 34 14 32 26-2 10-22 16-46 16S33 90 36 78z" fill="url(#rc-omelet)"/>' +
  '<path d="M42 80c20-8 50-10 78-2" stroke="#d6921a" stroke-width="3" fill="none" opacity="0.7"/>' +
  '<path d="M66 84c1 7 7 8 8 1M90 83c1 6 6 7 7 0" fill="#fff3b0" stroke="#f1d27a" stroke-width="1.5"/>' +
  herbs([[60, 66, -20], [98, 64, 15], [80, 72, 5]]) +
  '<path d="M48 66c8-8 20-12 32-12" stroke="#ffffff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.6"/>';

const gozleme = shadow(66) +
  '<rect x="16" y="64" width="128" height="38" rx="14" fill="url(#wood)" stroke="#8a5a2e" stroke-width="2"/>' +
  '<path d="M26 84c0-24 24-38 54-38s54 14 54 38z" fill="url(#rc-dough)" stroke="#b9762f" stroke-width="2"/>' +
  '<path d="M30 84h100" stroke="#fffbe8" stroke-width="5" stroke-linecap="round"/>' +
  '<g fill="#b8732e" opacity="0.7"><circle cx="56" cy="64" r="3.2"/><circle cx="84" cy="58" r="2.6"/><circle cx="106" cy="70" r="3"/><circle cx="72" cy="74" r="2.2"/></g>' +
  herbs([[48, 84, 0], [110, 84, 10]]);

const dolma = plate +
  [[50, 76], [80, 70], [110, 76]].map(([x, y]) =>
    `<ellipse cx="${x}" cy="${y + 4}" rx="16" ry="17" fill="url(#rc-pepper)"/>` +
    `<ellipse cx="${x}" cy="${y - 8}" rx="12" ry="5.5" fill="#f3ead6"/>` +
    `<circle cx="${x - 4}" cy="${y - 8}" r="1.5" fill="#c0392b"/><circle cx="${x + 4}" cy="${y - 7}" r="1.3" fill="#3f8a2a"/>` +
    `<path d="M${x - 6} ${y + 2}c0 8 3 13 8 15" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.55"/>`).join('');

const pide = shadow(70) +
  '<path d="M10 72c32-20 108-20 140 0-32 22-108 22-140 0z" fill="url(#rc-dough)" stroke="#b1702c" stroke-width="2"/>' +
  '<path d="M32 72c24-11 72-11 96 0-24 12-72 12-96 0z" fill="url(#rc-cheese)"/>' +
  egg(80, 72, 0.9) +
  '<g fill="#e8c46a"><circle cx="48" cy="72" r="2"/><circle cx="112" cy="71" r="2.4"/><circle cx="60" cy="67" r="1.6"/></g>' +
  herbs([[100, 66, 20], [58, 77, -15]]);

const imam = plate +
  '<path d="M30 76c10-24 72-26 96-4 4 12-10 20-48 20S26 88 30 76z" fill="url(#rc-eggplant)"/>' +
  '<path d="M122 68c8-4 14-2 16 2" stroke="#3f8a2a" stroke-width="5" stroke-linecap="round"/>' +
  '<path d="M44 72c14-11 52-13 70-2-15 9-55 9-70 2z" fill="url(#sauce)"/>' +
  '<ellipse cx="62" cy="70" rx="7" ry="3.5" fill="none" stroke="#f1e2ef" stroke-width="2.4"/><ellipse cx="90" cy="68" rx="6" ry="3" fill="none" stroke="#f1e2ef" stroke-width="2.4"/>' +
  '<ellipse cx="76" cy="73" rx="5" ry="3" fill="url(#tomC)"/><ellipse cx="102" cy="72" rx="4.5" ry="2.8" fill="url(#tomC)"/>' +
  herbs([[70, 66, -10], [96, 64, 20]]) +
  '<path d="M38 80c10 6 24 8 40 8" stroke="#ffffff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.35"/>';

const kahvalti = plate +
  '<rect x="34" y="60" width="30" height="20" rx="3" fill="url(#rc-cheese)" stroke="#e1cf96" stroke-width="1.5"/>' +
  '<path d="M38 64h20" stroke="#ffffff" stroke-width="2" opacity="0.8"/>' +
  tomato(80, 62, 8) + tomato(94, 66, 7) +
  egg(104, 82, 0.75) +
  '<g fill="#2b2522"><ellipse cx="58" cy="86" rx="4.5" ry="3.6"/><ellipse cx="68" cy="89" rx="4.5" ry="3.6"/><ellipse cx="62" cy="80" rx="4" ry="3.2"/></g>' +
  '<g fill="#ffffff" opacity="0.5"><circle cx="57" cy="85" r="1"/><circle cx="67" cy="88" r="1"/></g>' +
  '<rect x="76" y="80" width="12" height="10" rx="3" fill="url(#cuc)"/><rect x="78.5" y="82.5" width="7" height="5" rx="2" fill="#d8f0b5"/>';

const lahmacun = shadow(70) +
  '<ellipse cx="80" cy="74" rx="66" ry="28" fill="url(#rc-dough)" stroke="#b1702c" stroke-width="2"/>' +
  '<ellipse cx="80" cy="73" rx="57" ry="22" fill="#c4472d"/>' +
  '<g fill="#8e2a18"><circle cx="54" cy="70" r="2.4"/><circle cx="70" cy="80" r="2"/><circle cx="92" cy="66" r="2.6"/><circle cx="108" cy="78" r="2.2"/><circle cx="80" cy="72" r="1.8"/></g>' +
  '<ellipse cx="66" cy="66" rx="6" ry="3" fill="none" stroke="#f5dfe8" stroke-width="2.2"/>' +
  herbs([[86, 80, 10], [60, 78, -25], [100, 70, 30], [76, 64, 0]]) +
  '<path d="M118 58c10-4 20 0 22 6-8 5-18 4-22-6z" fill="url(#lemon)"/>';

const karniyarik = plate +
  '<path d="M30 78c8-22 74-24 98-4 3 11-12 18-50 18S26 88 30 78z" fill="url(#rc-eggplant)"/>' +
  '<path d="M44 74c16-10 50-12 70-2-14 8-54 9-70 2z" fill="url(#rc-meat)"/>' +
  '<g fill="#7a3a1c"><circle cx="58" cy="72" r="2"/><circle cx="74" cy="70" r="2.4"/><circle cx="92" cy="72" r="2"/></g>' +
  tomato(70, 66, 6) + tomato(94, 67, 6) +
  '<path d="M60 60c14-6 30-6 42 0" stroke="url(#rc-pepper)" stroke-width="7" fill="none" stroke-linecap="round"/>' +
  '<path d="M124 70c8-4 14-2 16 2" stroke="#3f8a2a" stroke-width="5" stroke-linecap="round"/>';

const cilbir = bowl +
  '<ellipse cx="80" cy="57" rx="54" ry="12" fill="#fbf7ef"/>' +
  egg(64, 56, 0.85) + egg(96, 57, 0.85) +
  '<path d="M40 58c10-4 20 4 30 0s20-4 30 0 18 2 22-2" stroke="#c0392b" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.85"/>' +
  '<g fill="#b8321f"><circle cx="50" cy="54" r="1.4"/><circle cx="112" cy="60" r="1.4"/><circle cx="80" cy="62" r="1.2"/></g>' +
  herbs([[80, 52, 10]]) +
  '<path d="M30 66c4 14 14 24 26 30" stroke="#ffffff" stroke-opacity="0.6" stroke-width="4" fill="none" stroke-linecap="round"/>';

// Tile kinds: 1 tomato, 2 pepper, 3 egg, 4 onion, 5 cheese.
export const RECIPES = [
  { id: 'menemen', name: 'Menemen', art: DISH.menemen },
  { id: 'coban', name: 'Çoban Salatası', art: DISH.coban },
  { id: 'omlet', name: 'Peynirli Omlet', art: omlet },
  { id: 'mercimek', name: 'Mercimek Çorbası', art: DISH.mercimek },
  { id: 'gozleme', name: 'Gözleme', art: gozleme },
  { id: 'dolma', name: 'Biber Dolması', art: dolma },
  { id: 'pide', name: 'Peynirli Pide', art: pide },
  { id: 'imam', name: 'İmam Bayıldı', art: imam },
  { id: 'kahvalti', name: 'Kahvaltı Tabağı', art: kahvalti },
  { id: 'lahmacun', name: 'Lahmacun', art: lahmacun },
  { id: 'karniyarik', name: 'Karnıyarık', art: karniyarik },
  { id: 'cilbir', name: 'Çılbır', art: cilbir },
];

export const LOCKED_DISH = DISH.kilit;
