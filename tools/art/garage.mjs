// Garaj Ustası art: car-part tiles, vehicles for the gallery, garage obstacles and booster icons.
// Every shape is original: no brands, badges, grilles or model names of real vehicles.
const st = (arr) => arr.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}"${a !== 1 ? ` stop-opacity="${a}"` : ''}/>`).join('');
const lg = (id, stops, x2 = 0, y2 = 1) => `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${st(stops)}</linearGradient>`;
const rg = (id, stops, cx = 0.4, cy = 0.35, r = 0.7) => `<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}">${st(stops)}</radialGradient>`;

const BODY_COLORS = {
  red: ['#ff7a5c', '#d23a24'],
  blue: ['#6cc6ff', '#2468c9'],
  green: ['#8fdc6a', '#2f8f3c'],
  yellow: ['#ffe070', '#e8a317'],
  orange: ['#ffb05c', '#e0661c'],
  khaki: ['#b9b57a', '#6f6d3a'],
  cream: ['#fff3d6', '#d9c49a'],
  white: ['#ffffff', '#c9d1da'],
  purple: ['#c39bff', '#6a3fc4'],
  teal: ['#6fe0d0', '#1f9a8c'],
};

export const GARAGE_DEFS = [
  rg('c-tire', [[0, '#4a4f57'], [1, '#1c1f24']]),
  lg('c-chrome', [[0, '#ffffff'], [0.5, '#b9c2cc'], [1, '#7d8894']]),
  lg('c-blue', [[0, '#6fc3ff'], [1, '#1f6fd1']]),
  rg('c-glass', [[0, '#fff9d6'], [1, '#f2c230']]),
  lg('c-red', [[0, '#ff6b5a'], [1, '#c62f22']]),
  lg('c-green', [[0, '#7fdc6a'], [1, '#2f9a3c']]),
  lg('c-window', [[0, '#e8f6ff'], [1, '#9fcbe8']]),
  lg('c-rust', [[0, '#c9793c'], [1, '#7a3e18']]),
  lg('c-steel', [[0, '#d4dbe3'], [1, '#7d8894']], 1, 0),
  lg('c-wood', [[0, '#d9a36a'], [1, '#9a6a3c']]),
  lg('c-cover', [[0, '#9aa3ad'], [1, '#5d6773']]),
  ...Object.entries(BODY_COLORS).map(([name, [top, bottom]]) => lg(`gv-${name}`, [[0, top], [1, bottom]])),
].join('');

// --- Part tiles (48x48). Each part has its own colour family so matches read at a glance. ---
const WHEEL = '<ellipse cx="24" cy="43" rx="15" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><circle cx="24" cy="24" r="17" fill="url(#c-tire)"/><circle cx="24" cy="24" r="10" fill="url(#c-chrome)"/></g><g stroke="#7d8894" stroke-width="2.2" stroke-linecap="round"><path d="M24 16v5M31.6 21.5l-4.8 1.6M28.7 30.5l-2.9-4M19.3 30.5l2.9-4M16.4 21.5l4.8 1.6"/></g><circle cx="24" cy="24" r="3" fill="#5d6773"/><path d="M13 15a14 14 0 0 1 9-6" stroke="#ffffff" stroke-opacity="0.35" stroke-width="2.4" fill="none" stroke-linecap="round"/>';
const PLUG = '<ellipse cx="24" cy="43.5" rx="10" ry="2.2" fill="url(#gs)"/><g filter="url(#ds)"><rect x="19" y="4" width="10" height="6" rx="2" fill="url(#c-chrome)"/><path d="M15 10h18l-2 14H17z" fill="url(#c-blue)"/><path d="M13 24h22v7H13z" fill="url(#c-chrome)"/><path d="M18 31h12v7H18z" fill="#9aa3ad"/><path d="M18 33h12M18 35.5h12" stroke="#6b7480" stroke-width="1"/><path d="M24 38v4h4" stroke="#6b7480" stroke-width="2" fill="none" stroke-linecap="round"/></g><path d="M18.5 12.5l-.8 9" stroke="#ffffff" stroke-opacity="0.7" stroke-width="2.2" stroke-linecap="round"/>';
const LIGHT = '<ellipse cx="24" cy="43" rx="14" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><circle cx="24" cy="23" r="17" fill="url(#c-chrome)"/><circle cx="24" cy="23" r="13" fill="url(#c-glass)"/></g><path d="M11 23h26M24 10v26M15 14l18 18M33 14L15 32" stroke="#e8a317" stroke-width="0.9" opacity="0.45"/><ellipse cx="19" cy="17.5" rx="5" ry="3" fill="#ffffff" opacity="0.85" transform="rotate(-35 19 17.5)"/>';
const STEER = '<ellipse cx="24" cy="43" rx="15" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><circle cx="24" cy="23" r="15" fill="none" stroke="url(#c-red)" stroke-width="6"/><path d="M11 25h26M24 25v12" stroke="url(#c-red)" stroke-width="5" stroke-linecap="round"/><circle cx="24" cy="25" r="5.5" fill="#8f1d14"/></g><circle cx="24" cy="25" r="2" fill="#ffd0c8"/><path d="M13 16a13 13 0 0 1 8-6" stroke="#ffffff" stroke-opacity="0.6" stroke-width="2.2" fill="none" stroke-linecap="round"/>';
const GEAR = '<ellipse cx="24" cy="43" rx="14" ry="2.6" fill="url(#gs)"/><g filter="url(#ds)"><path d="M21 4h6l1 5 4 2 4-3 4 4-3 4 2 4 5 1v6l-5 1-2 4 3 4-4 4-4-3-4 2-1 5h-6l-1-5-4-2-4 3-4-4 3-4-2-4-5-1v-6l5-1 2-4-3-4 4-4 4 3 4-2z" fill="url(#c-green)"/></g><circle cx="24" cy="23" r="6" fill="#1f6b2a"/><circle cx="24" cy="23" r="3" fill="#d8f5cf"/><path d="M14 14a12 12 0 0 1 7-4" stroke="#ffffff" stroke-opacity="0.6" stroke-width="2" fill="none" stroke-linecap="round"/>';

// Tile kinds used by the match-3 core: 1 steering wheel (red), 2 gear (green), 3 headlight (yellow),
// 4 spark plug (blue), 5 tyre (black).
export const PART_TILES = [STEER, GEAR, LIGHT, PLUG, WHEEL];

// --- Booster icons (48x48): wrench clears a row, compressor shuffles, hammer hits one tile. ---
export const BOOSTER_ART = {
  wrench: '<g filter="url(#ds)" transform="rotate(-40 24 24)"><rect x="20" y="16" width="8" height="30" rx="4" fill="url(#c-red)"/><path d="M15 4a10 10 0 0 0 4 17h10a10 10 0 0 0 4-17l-3 7h-12z" fill="url(#c-steel)"/><rect x="21" y="18" width="6" height="6" fill="#9aa3ad"/></g><path d="M16 38l4-4" stroke="#ffffff" stroke-opacity="0.5" stroke-width="2" stroke-linecap="round"/>',
  compressor: '<ellipse cx="24" cy="44" rx="17" ry="2.4" fill="url(#gs)"/><g filter="url(#ds)"><rect x="6" y="18" width="30" height="20" rx="10" fill="url(#c-red)"/><circle cx="14" cy="40" r="4" fill="url(#c-tire)"/><circle cx="30" cy="40" r="4" fill="url(#c-tire)"/><circle cx="28" cy="14" r="7" fill="url(#c-chrome)"/></g><circle cx="28" cy="14" r="4.5" fill="#ffffff"/><path d="M28 14l2.5-2.5" stroke="#c62f22" stroke-width="1.5" stroke-linecap="round"/><path d="M36 26q10 0 8 12" stroke="#2b2f36" stroke-width="2.5" fill="none" stroke-linecap="round"/><path d="M10 24h14" stroke="#ffffff" stroke-opacity="0.5" stroke-width="2.2" stroke-linecap="round"/>',
  hammer: '<g filter="url(#ds)" transform="rotate(35 24 24)"><rect x="21" y="14" width="6" height="32" rx="3" fill="url(#c-wood)"/><path d="M10 6h22c3 0 5 2 5 5v4c0 3-2 5-5 5H10z" fill="url(#c-steel)"/><path d="M37 8l6-3v16l-6-3z" fill="#9aa3ad"/></g><path d="M13 9h16" stroke="#ffffff" stroke-opacity="0.7" stroke-width="2" stroke-linecap="round"/>',
};

// --- Vehicles (160x120, the gallery frame). ---
const wheel = (cx, cy, r) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="url(#c-tire)"/><circle cx="${cx}" cy="${cy}" r="${(r * 0.55).toFixed(1)}" fill="url(#c-chrome)"/><circle cx="${cx}" cy="${cy}" r="${(r * 0.18).toFixed(1)}" fill="#5d6773"/>`;
const ground = (rx = 70) => `<ellipse cx="80" cy="110" rx="${rx}" ry="7" fill="url(#gs)"/>`;
const head = (x, y) => `<ellipse cx="${x}" cy="${y}" rx="5" ry="4.5" fill="url(#c-glass)"/>`;
const tail = (x, y) => `<rect x="${x}" y="${y}" width="6" height="6" rx="2" fill="#ff5a4a"/>`;
const shine = (d) => `<path d="${d}" stroke="#ffffff" stroke-opacity="0.45" stroke-width="3" fill="none" stroke-linecap="round"/>`;
const paint = (color) => `url(#gv-${color})`;

const coupe = (c) => ground() +
  `<path d="M12 86c0-10 6-15 16-16l20-3 18-15c5-4 10-5 16-5h22c8 0 13 3 18 9l11 11 14 3c6 1 9 6 9 12v6c0 3-2 5-5 5H17c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M56 66l14-11c3-2 6-3 10-3h8v14z" fill="url(#c-window)"/><path d="M94 52h8c6 0 10 2 14 7l6 7h-28z" fill="url(#c-window)"/>' +
  shine('M24 76h124') + head(146, 80) + tail(12, 78) + '<rect x="96" y="72" width="9" height="2.6" rx="1.3" fill="#ffffff" opacity="0.7"/>' +
  wheel(44, 96, 13) + wheel(122, 96, 13);

const pickup = (c) => ground() +
  `<path d="M10 72h64V46c0-4 3-6 6-6h30c6 0 10 3 13 8l10 16 12 2c5 1 8 5 8 10v14c0 3-2 5-5 5H15c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M84 46h24c4 0 6 2 8 5l7 13H84z" fill="url(#c-window)"/><path d="M10 72h64" stroke="#000000" stroke-opacity="0.25" stroke-width="3"/><path d="M14 66h56" stroke="#000000" stroke-opacity="0.2" stroke-width="3"/>' +
  shine('M18 80h128') + head(148, 78) + tail(10, 76) + wheel(40, 98, 14) + wheel(124, 98, 14);

const van = (c) => ground(72) +
  `<path d="M8 50c0-10 6-16 16-16h94c10 0 16 4 20 12l12 22c2 4 2 8 2 12v16c0 3-2 5-5 5H13c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<rect x="20" y="42" width="24" height="20" rx="3" fill="url(#c-window)"/><rect x="50" y="42" width="24" height="20" rx="3" fill="url(#c-window)"/><rect x="80" y="42" width="24" height="20" rx="3" fill="url(#c-window)"/><path d="M112 42h8c5 0 8 2 10 6l8 16h-26z" fill="url(#c-window)"/>' +
  '<path d="M8 76h150" stroke="#ffffff" stroke-opacity="0.6" stroke-width="5"/>' + head(152, 84) + tail(8, 82) + wheel(40, 100, 13) + wheel(124, 100, 13);

const jeep = (c) => ground() +
  `<path d="M16 60c0-4 3-7 7-7h26l10-17h44c4 0 6 2 7 5l6 19h26c5 0 8 4 8 9v21c0 3-2 5-5 5H21c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M64 41h16v16H56z" fill="url(#c-window)"/><path d="M86 41h16l5 16H86z" fill="url(#c-window)"/>' +
  wheel(12, 74, 10) + '<path d="M22 76h124" stroke="#000000" stroke-opacity="0.2" stroke-width="3"/>' + head(148, 70) + wheel(46, 96, 15) + wheel(122, 96, 15);

const classic = (c) => ground() +
  `<path d="M8 84c0-8 8-12 18-12h6c4-10 12-16 22-16l14-14c4-4 10-6 16-6h14c8 0 14 4 18 10l8 12h8c10 0 20 4 22 14l2 8c0 4-3 6-6 6H14c-4 0-6-2-6-6z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M66 56l10-10c3-3 6-4 10-4h6v14z" fill="url(#c-window)"/><path d="M96 42h6c5 0 9 2 12 6l6 8H96z" fill="url(#c-window)"/>' +
  '<rect x="4" y="88" width="16" height="6" rx="3" fill="url(#c-chrome)"/><rect x="140" y="88" width="16" height="6" rx="3" fill="url(#c-chrome)"/>' +
  shine('M30 74h110') + head(146, 78) + wheel(42, 96, 13) + wheel(120, 96, 13);

const racer = (c) => ground(72) +
  `<path d="M6 88c0-6 4-10 10-10l40-6 20-12c4-2 8-3 12-3h14c6 0 10 2 14 6l16 12 12 2c5 1 8 4 8 8v7c0 3-2 5-5 5H11c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M4 64h22v6H4z" fill="#2b2f36"/><path d="M16 70v8" stroke="#2b2f36" stroke-width="3"/>' +
  '<path d="M78 70l12-8c3-2 6-2 9-2h8c4 0 7 2 10 5l6 5z" fill="url(#c-window)"/>' +
  '<path d="M20 84h130" stroke="#2b2f36" stroke-opacity="0.8" stroke-width="5"/><circle cx="60" cy="80" r="8" fill="#ffffff"/><circle cx="60" cy="80" r="4" fill="#2b2f36"/>' +
  head(150, 82) + wheel(40, 98, 12) + wheel(126, 98, 12);

const towTruck = (c) => ground(74) +
  '<path d="M10 80h84v22H10z" fill="#5d6773" filter="url(#ds)"/><path d="M26 80l20-36h8l-18 36" fill="#7d8894"/><path d="M50 44v26" stroke="#2b2f36" stroke-width="2"/><path d="M50 70a4 4 0 1 1-4 4" stroke="#2b2f36" stroke-width="2.4" fill="none"/>' +
  `<path d="M92 52h30c6 0 10 3 13 8l10 16 6 2c3 1 5 4 5 7v15c0 3-2 5-5 5H90z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M100 58h20c4 0 6 2 8 5l6 11h-34z" fill="url(#c-window)"/><rect x="100" y="44" width="22" height="6" rx="3" fill="#ffb000"/>' +
  head(150, 86) + wheel(34, 102, 11) + wheel(64, 102, 11) + wheel(128, 102, 12);

const fireTruck = (c) => ground(76) +
  `<path d="M6 58h98v-8c0-4 3-6 6-6h20c6 0 10 3 13 8l8 14c2 3 3 6 3 10v26c0 3-2 5-5 5H11c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M10 50h90M10 42h90" stroke="url(#c-chrome)" stroke-width="3"/><path d="M20 42v8M34 42v8M48 42v8M62 42v8M76 42v8M90 42v8" stroke="url(#c-chrome)" stroke-width="2.4"/>' +
  '<path d="M112 50h18c4 0 6 2 8 5l6 11h-32z" fill="url(#c-window)"/><rect x="112" y="36" width="20" height="6" rx="3" fill="#4fc3ff"/>' +
  '<path d="M10 80h140" stroke="#ffffff" stroke-opacity="0.85" stroke-width="5"/><rect x="20" y="62" width="30" height="12" rx="2" fill="#000000" opacity="0.18"/><rect x="58" y="62" width="30" height="12" rx="2" fill="#000000" opacity="0.18"/>' +
  head(152, 88) + wheel(32, 102, 12) + wheel(62, 102, 12) + wheel(130, 102, 12);

const camper = (c) => ground(74) +
  `<path d="M8 48c0-14 10-22 24-22h82c12 0 18 6 22 16l14 30c2 4 2 7 2 11v15c0 3-2 5-5 5H13c-3 0-5-2-5-5z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<rect x="20" y="40" width="34" height="20" rx="4" fill="url(#c-window)"/><rect x="62" y="40" width="22" height="42" rx="3" fill="#ffffff" opacity="0.55"/><circle cx="80" cy="62" r="1.8" fill="#5d6773"/>' +
  '<path d="M116 40h4c6 0 10 3 13 8l9 18h-26z" fill="url(#c-window)"/><path d="M8 74h54M84 74h72" stroke="#e0661c" stroke-width="5"/><path d="M8 82h54M84 82h72" stroke="#ffb05c" stroke-width="3"/>' +
  head(152, 88) + wheel(38, 100, 13) + wheel(126, 100, 13);

const scooter = (c) => ground(62) +
  wheel(36, 96, 14) + wheel(124, 96, 14) +
  `<path d="M26 92c0-14 12-24 30-24h34l12-34h12l-11 46c10 2 18 8 20 18H86c-4-8-10-10-20-10H40c-8 0-12 2-14 4z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M44 66h38c4 0 6-4 4-9H50c-4 0-7 4-6 9z" fill="#2b2f36"/><path d="M100 30h22" stroke="#2b2f36" stroke-width="5" stroke-linecap="round"/>' + head(122, 46) + shine('M40 84c6-8 14-10 26-10');

const crossBike = (c) => ground(64) +
  wheel(34, 94, 17) + wheel(126, 94, 17) +
  '<path d="M34 94l28-30h36l28 30" stroke="#5d6773" stroke-width="6" fill="none" stroke-linejoin="round"/><path d="M104 64l14-28" stroke="#5d6773" stroke-width="5"/>' +
  `<path d="M52 56c6-10 16-12 28-12h14c10 0 14 8 10 16H70z" fill="${paint(c)}" filter="url(#ds)"/><path d="M12 62c8-12 22-14 34-8l-6 8z" fill="${paint(c)}"/><path d="M110 42c10-6 22-4 30 4l-10 4z" fill="${paint(c)}"/>` +
  '<path d="M36 58h28l-4 6H40z" fill="#2b2f36"/><rect x="112" y="30" width="16" height="12" rx="3" fill="#ffffff"/><path d="M108 30h22" stroke="#2b2f36" stroke-width="4" stroke-linecap="round"/>' +
  '<rect x="66" y="64" width="22" height="14" rx="4" fill="url(#c-chrome)"/>';

const sportBike = (c) => ground(66) +
  wheel(34, 94, 15) + wheel(126, 94, 15) +
  '<path d="M34 94l30-24h34l28 24" stroke="#5d6773" stroke-width="5" fill="none"/>' +
  `<path d="M40 70c4-16 20-24 40-24h20c12 0 22 6 30 16l6 12c-12 6-28 8-44 8H56c-8 0-14-4-16-12z" fill="${paint(c)}" filter="url(#ds)"/>` +
  '<path d="M104 50c8 0 16 4 22 12l-16 2z" fill="url(#c-window)"/><path d="M30 60h32l-6 8H34z" fill="#2b2f36"/>' +
  '<path d="M52 76h70" stroke="#ffffff" stroke-opacity="0.7" stroke-width="4"/>' + head(134, 70) + '<rect x="70" y="80" width="18" height="10" rx="3" fill="url(#c-chrome)"/>';

// Gallery order: one vehicle joins every RECIPE_STEP levels. Ids replace the recipe ids level for level.
export const VEHICLES = [
  { id: 'kupa', name: 'Kırmızı Kupa', art: coupe('red') },
  { id: 'skuter', name: 'Mavi Skuter', art: scooter('blue') },
  { id: 'pikap', name: 'Yeşil Pikap', art: pickup('green') },
  { id: 'minibus', name: 'Sarı Minibüs', art: van('yellow') },
  { id: 'kros', name: 'Turuncu Kros Motor', art: crossBike('orange') },
  { id: 'cip', name: 'Haki Cip', art: jeep('khaki') },
  { id: 'klasik', name: 'Krem Klasik', art: classic('cream') },
  { id: 'yaris', name: 'Beyaz Yarış Arabası', art: racer('white') },
  { id: 'cekici', name: 'Turuncu Çekici', art: towTruck('orange') },
  { id: 'hizli', name: 'Mor Hızlı Motor', art: sportBike('purple') },
  { id: 'itfaiye', name: 'İtfaiye Aracı', art: fireTruck('red') },
  { id: 'karavan', name: 'Turkuaz Karavan', art: camper('teal') },
];

// A car still under its grey cover, waiting in the gallery.
export const LOCKED_VEHICLE = ground() +
  '<path d="M14 94c0-24 10-32 30-34l22-18c6-4 12-6 20-6h18c10 0 18 6 24 14l12 12c10 2 16 8 16 18v14z" fill="url(#c-cover)" filter="url(#ds)"/>' +
  '<path d="M40 64c10 8 12 20 10 30M100 42c4 16 2 34-4 52M126 62c-4 10-4 22 0 32" stroke="#4a525c" stroke-width="2" fill="none" opacity="0.6"/>' +
  wheel(44, 98, 10) + wheel(122, 98, 10) +
  '<rect x="70" y="62" width="22" height="18" rx="4" fill="#f2c94c"/><path d="M74 62v-6a7 7 0 0 1 14 0v6" stroke="#f2c94c" stroke-width="4" fill="none"/><circle cx="81" cy="71" r="2.6" fill="#6b4a12"/>';

// --- Board items and obstacles (48x48). Sprite names follow the ones the board view already uses. ---
// The finished car rolls down the board to be delivered.
const READY_CAR =
  '<ellipse cx="24" cy="44" rx="19" ry="2.6" fill="url(#gs)"/>' +
  '<g filter="url(#ds)"><path d="M3 34c0-4 3-6 7-7l7-1 6-6c2-2 4-2 6-2h6c3 0 5 1 7 4l3 4 3 1c2 .5 3 2 3 4v4c0 1-1 2-2 2H5c-1 0-2-1-2-2z" fill="url(#gv-red)"/></g>' +
  '<path d="M19 26l5-4h5v4zM31 22h3c2 0 4 1 5 3l1 1h-9z" fill="url(#c-window)"/>' +
  '<circle cx="13" cy="38" r="5" fill="url(#c-tire)"/><circle cx="13" cy="38" r="2.4" fill="url(#c-chrome)"/><circle cx="37" cy="38" r="5" fill="url(#c-tire)"/><circle cx="37" cy="38" r="2.4" fill="url(#c-chrome)"/>' +
  '<path d="M6 30h36" stroke="#ffffff" stroke-opacity="0.45" stroke-width="1.6"/>' +
  '<path d="M38 5l1.2 3 3 1.2-3 1.2-1.2 3-1.2-3-3-1.2 3-1.2z" fill="#ffd34d"/><path d="M8 11l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8z" fill="#ffd34d"/>';

// A red jerry can: the car game's lives on the map.
const FUEL =
  '<ellipse cx="24" cy="44" rx="14" ry="2.4" fill="url(#gs)"/><g filter="url(#ds)"><path d="M10 12l6-6h18a4 4 0 0 1 4 4v30a3 3 0 0 1-3 3H13a3 3 0 0 1-3-3z" fill="url(#c-red)"/><path d="M14 8h8v-3h-8z" fill="#8f1d14"/></g>' +
  '<path d="M16 18l16 16M32 18L16 34" stroke="#8f1d14" stroke-width="2.5" opacity="0.55"/><rect x="15" y="17" width="18" height="18" rx="2" fill="none" stroke="#8f1d14" stroke-width="1.5" opacity="0.55"/>' +
  '<path d="M14 14v20" stroke="#ffffff" stroke-opacity="0.5" stroke-width="2" stroke-linecap="round"/>';

// A stack of old tyres; more tyres take more hits.
const tyres = (count) => {
  let s = '<ellipse cx="24" cy="45" rx="19" ry="2.6" fill="url(#gs)"/>';
  for (let k = 0; k < count; k++) {
    const y = 38 - k * 7;
    s += `<ellipse cx="24" cy="${y + 2}" rx="19" ry="6.5" fill="#15181c"${k === 0 ? ' filter="url(#ds)"' : ''}/>`;
    s += `<ellipse cx="24" cy="${y}" rx="19" ry="6.5" fill="url(#c-tire)"/>`;
    s += `<path d="M8 ${y}q16 5 32 0" stroke="#5d6773" stroke-width="1.2" fill="none" opacity="0.7"/>`;
  }
  const top = 38 - (count - 1) * 7;
  s += `<ellipse cx="24" cy="${top}" rx="9" ry="3" fill="#0e1013"/>`;
  s += `<path d="M9 ${top - 2}q5-3 10-3.6" stroke="#ffffff" stroke-width="1.5" fill="none" stroke-linecap="round" opacity="0.4"/>`;
  return s;
};

// A rusty oil drum; the two-hit version is dented and flaking.
const drum = (heavy) =>
  '<ellipse cx="24" cy="45" rx="17" ry="2.6" fill="url(#gs)"/>' +
  '<g filter="url(#ds)"><path d="M9 8h30v34c0 2-7 3.5-15 3.5S9 44 9 42z" fill="url(#c-rust)"/></g>' +
  '<ellipse cx="24" cy="8" rx="15" ry="3.6" fill="#d9894a"/><ellipse cx="24" cy="8" rx="11" ry="2.4" fill="#8a4a20"/><circle cx="30" cy="8" r="1.5" fill="#5a2a10"/>' +
  '<path d="M9 19q15 4 30 0M9 32q15 4 30 0" stroke="#7a3e18" stroke-width="2.4" fill="none"/>' +
  (heavy
    ? '<g fill="#4a2410" opacity="0.85"><circle cx="16" cy="25" r="2.6"/><circle cx="31" cy="37" r="2"/><circle cx="29" cy="23" r="1.4"/><circle cx="15" cy="38" r="1.6"/></g><path d="M34 12l-3 5 3 3" stroke="#4a2410" stroke-width="1.6" fill="none"/>'
    : '<circle cx="18" cy="26" r="1.6" fill="#4a2410" opacity="0.7"/>') +
  '<path d="M13 12v28" stroke="#ffffff" stroke-opacity="0.35" stroke-width="2.4" stroke-linecap="round"/>';

// A chain wrapped over the tile with a padlock; the tile shows through between the links.
const link = (x, y, angle) => `<rect x="${x - 6}" y="${y - 3.2}" width="12" height="6.4" rx="3.2" fill="none" stroke="url(#c-steel)" stroke-width="2.6" transform="rotate(${angle} ${x} ${y})"/>`;
const CHAIN =
  '<rect x="3" y="3" width="42" height="42" rx="8" fill="#5d6773" opacity="0.22"/>' +
  [[8, 8], [16, 16], [24, 24], [32, 32], [40, 40]].map(([x, y], n) => link(x, y, n % 2 ? 45 : -45)).join('') +
  [[40, 8], [32, 16], [16, 32], [8, 40]].map(([x, y], n) => link(x, y, n % 2 ? -45 : 45)).join('') +
  '<rect x="18" y="22" width="12" height="10" rx="2.4" fill="url(#ob-gold)" stroke="#9a6d12" stroke-width="1"/><path d="M20.5 22v-3a3.5 3.5 0 0 1 7 0v3" stroke="#9a6d12" stroke-width="2" fill="none"/><circle cx="24" cy="27" r="1.3" fill="#6b4a12"/>';

// A glossy oil puddle under the tile.
const OIL =
  '<rect x="2" y="2" width="44" height="44" rx="8" fill="#e6e0d6" opacity="0.4"/>' +
  '<path d="M8 20c2-10 14-14 22-10 8-2 14 6 12 14 4 8-2 18-12 16-6 6-18 4-20-4-8-2-8-12-2-16z" fill="#2b2622" opacity="0.85"/>' +
  '<path d="M14 18c4-4 10-5 14-3" stroke="#8a7dff" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.55"/>' +
  '<path d="M26 34c4 1 8 0 10-3" stroke="#4fd1c5" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.5"/>' +
  '<circle cx="40" cy="8" r="2.4" fill="#2b2622" opacity="0.8"/><circle cx="6" cy="40" r="1.8" fill="#2b2622" opacity="0.8"/>';

// Garage obstacles keep the sprite names the board view uses: box = tyre stack, crate = rusty drum,
// knot = chain, paw_print = oil puddle, dish = finished car, fuel = lives.
export const GARAGE_OBSTACLES = {
  box_1: tyres(2),
  box_2: tyres(4),
  crate_2: drum(true),
  crate_1: drum(false),
  knot: CHAIN,
  paw_print: OIL,
  dish: READY_CAR,
  fuel: FUEL,
};
