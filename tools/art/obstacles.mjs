// Obstacle art for the match-3 board, drawn in the same 48x48 frame as the tiles.
const st = (arr) => arr.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}"${a !== 1 ? ` stop-opacity="${a}"` : ''}/>`).join('');
const lg = (id, stops, x2 = 0, y2 = 1) => `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${st(stops)}</linearGradient>`;

export const OBSTACLE_DEFS = [
  lg('ob-card', [[0, '#e9bb80'], [1, '#b67d44']]),
  lg('ob-cardTop', [[0, '#f6d4a2'], [1, '#dba566']]),
  lg('ob-tape', [[0, '#e6cf98'], [0.5, '#fbeecb'], [1, '#d6bb7f']], 1, 0),
  lg('ob-tapeH', [[0, '#fbeecb'], [1, '#d6bb7f']]),
  lg('ob-crate', [[0, '#d49a60'], [1, '#8c5a2c']]),
  lg('ob-sack', [[0, '#b9e39a'], [0.55, '#6fb04a'], [1, '#3f7a2a']], 1, 0),
  lg('ob-sackTop', [[0, '#d2efb9'], [1, '#86c262']]),
  lg('ob-sleeper', [[0, '#f7c27f'], [1, '#d9823f']]),
  lg('ob-cushion', [[0, '#e98a8a'], [1, '#b64f55']]),
  lg('ob-metal', [[0, '#eef2f6'], [1, '#8b95a2']], 1, 0),
  lg('ob-gold', [[0, '#ffe27a'], [1, '#d19a1c']]),
  lg('ob-mouse', [[0, '#e1e4e9'], [1, '#9aa2ad']]),
].join('');

// Conveyor belt cell: a dark rubber belt pointing right; "<" belts flip it in the view.
// It is drawn under the tile, which covers the middle, so the direction arrows sit on the
// top and bottom rails where they stay visible.
const beltArrows = (y) => `<path d="M8 ${y - 2.6}l4 2.6-4 2.6M20 ${y - 2.6}l4 2.6-4 2.6M32 ${y - 2.6}l4 2.6-4 2.6" stroke="#f2c94c" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`;
const BELT =
  '<rect x="0" y="0" width="48" height="48" fill="#5b4d46"/>' +
  '<rect x="0" y="0" width="48" height="7" fill="#3a302b"/><rect x="0" y="41" width="48" height="7" fill="#3a302b"/>' +
  '<path d="M6 9v30M18 9v30M30 9v30M42 9v30" stroke="#6f625b" stroke-width="3"/>' +
  beltArrows(3.5) + beltArrows(44.5);

// A little grey mouse sitting sideways; drawn small in a cell corner so the tile under it stays readable.
const MOUSE =
  '<ellipse cx="25" cy="42.5" rx="15" ry="2.6" fill="url(#gs)"/>' +
  '<path d="M37 35q9 0 8-9" stroke="#c99a90" stroke-width="2.4" fill="none" stroke-linecap="round"/>' +
  '<g filter="url(#ds)">' +
  '<ellipse cx="27" cy="31" rx="13" ry="10" fill="url(#ob-mouse)"/>' +
  '<circle cx="16" cy="25" r="8.5" fill="url(#ob-mouse)"/>' +
  '<circle cx="19" cy="13.5" r="7" fill="url(#ob-mouse)"/>' +
  '</g>' +
  '<circle cx="19" cy="13.5" r="4.3" fill="#f2b3a0"/>' +
  '<circle cx="13" cy="23.5" r="2" fill="#2a1a10"/><circle cx="12.4" cy="22.8" r="0.7" fill="#ffffff"/>' +
  '<circle cx="8" cy="27.5" r="1.8" fill="#e0788a"/>' +
  '<path d="M8.5 29l-5.5 .6M9 30.5l-5 3" stroke="#7d838d" stroke-width="0.8" stroke-linecap="round"/>' +
  '<path d="M22 40.5q-2 2-5 2M32 40.5q1 2 4 2" stroke="#8f96a0" stroke-width="2.2" stroke-linecap="round" fill="none"/>';

// A grey cat peeking out between metal bars. The bars leave the face open (eyes and nose between
// them, ears poking up) and the small padlock hangs on the bottom rail, so the cat reads first.
const CAGE =
  '<ellipse cx="24" cy="45" rx="19" ry="2.4" fill="url(#gs)"/>' +
  '<rect x="5" y="9" width="38" height="34" rx="5" fill="#5a4a42" filter="url(#ds)"/>' +
  '<path d="M13 27.5l1.2-11 8 7zM35 27.5l-1.2-11-8 7z" fill="#bdb4aa"/>' +
  '<path d="M15.2 24.5l.8-5.6 4 3.6zM32.8 24.5l-.8-5.6-4 3.6z" fill="#f2b3a0"/>' +
  '<ellipse cx="24" cy="30.5" rx="11" ry="9" fill="#ddd5cb"/>' +
  '<ellipse cx="21" cy="29.5" rx="1.9" ry="2.5" fill="#2a1a10"/><ellipse cx="27" cy="29.5" rx="1.9" ry="2.5" fill="#2a1a10"/>' +
  '<circle cx="20.4" cy="28.6" r="0.7" fill="#ffffff"/><circle cx="26.4" cy="28.6" r="0.7" fill="#ffffff"/>' +
  '<path d="M23 33h2l-1 1.3z" fill="#d4735d"/><path d="M24 34.3q-1 1.4-2.4 1M24 34.3q1 1.4 2.4 1" stroke="#8c7f74" stroke-width="0.8" fill="none" stroke-linecap="round"/>' +
  '<path d="M11 10v32M17 10v32M31 10v32M37 10v32" stroke="url(#ob-metal)" stroke-width="2.6" stroke-linecap="round"/>' +
  '<rect x="5" y="9" width="38" height="34" rx="5" fill="none" stroke="#9aa4b1" stroke-width="3"/>' +
  '<path d="M5 15h38" stroke="#9aa4b1" stroke-width="2.4"/>' +
  '<path d="M22 41.5v-2a2 2 0 0 1 4 0v2" stroke="#9a6d12" stroke-width="1.5" fill="none"/>' +
  '<rect x="20.5" y="41" width="7" height="5.6" rx="1.4" fill="url(#ob-gold)"/><circle cx="24" cy="43.7" r="0.9" fill="#6b4a12"/>';

// A golden key, drawn in the tile frame because it travels the board like a tile.
const KEY =
  '<ellipse cx="24" cy="43.5" rx="15" ry="2.6" fill="url(#gs)"/>' +
  '<g filter="url(#ds)" transform="rotate(-35 24 24)">' +
  '<circle cx="13.5" cy="24" r="6.4" fill="none" stroke="url(#ob-gold)" stroke-width="5.2"/>' +
  '<rect x="19.5" y="21.4" width="23" height="5.2" rx="2" fill="url(#ob-gold)"/>' +
  '<rect x="33" y="25.5" width="3.8" height="6.5" rx="1" fill="url(#ob-gold)"/><rect x="38.6" y="25.5" width="3.8" height="4.8" rx="1" fill="url(#ob-gold)"/>' +
  '</g>' +
  '<path d="M9.5 19q2.5-3 6.5-2.4" stroke="#fff6d8" stroke-width="1.6" fill="none" stroke-linecap="round" opacity="0.85"/>';

// Tufted outline: the path runs along an inner ellipse and bulges out to the outer one n times,
// which reads as fluff rather than a smooth ball.
const tuft = (cx, cy, rx, ry, n, jag, fill, turn = 0) => {
  const at = (step, scale) => {
    const angle = turn + (step / n) * Math.PI * 2;
    return `${(cx + Math.cos(angle) * rx * scale).toFixed(2)} ${(cy + Math.sin(angle) * ry * scale).toFixed(2)}`;
  };
  let d = `M${at(0, jag)}`;
  for (let k = 0; k < n; k++) d += `Q${at(k + 0.5, 1.12)} ${at(k + 1, jag)}`;
  return `<path d="${d}Z" fill="${fill}"/>`;
};

// A pile of shed tabby fur: three matte tufted layers from dark to light, with stray hairs.
const FUR =
  '<ellipse cx="24" cy="44.5" rx="19" ry="2.6" fill="url(#gs)"/>' +
  `<g filter="url(#ds)">${tuft(24, 28, 19, 15, 15, 0.8, '#8f7f71')}</g>` +
  tuft(24, 27, 15, 11.5, 12, 0.78, '#bcad9f', 0.25) +
  tuft(23, 25, 9, 6.5, 9, 0.74, '#e4dbd0', 0.5) +
  // Short loose hairs lying along the edge; kept few and asymmetric so the pile never reads as a creature.
  '<path d="M7.5 23q-2.5-1.5-3-4M39.5 21.5q2.5-2 4.5-1.5M27 11.5q2-2.2 4.5-2M11 37.5q-2.5 1.5-4.5.5" stroke="#8f7f71" stroke-width="0.9" fill="none" stroke-linecap="round" opacity="0.85"/>' +
  '<path d="M14 28.5l2.2-.8M31.5 33l2 .9M28.5 20.5l2-1M19.5 35l1.8.6" stroke="#9d8e80" stroke-width="0.8" stroke-linecap="round"/>';

// A "z" letter drawn as a path (resvg loads no fonts), outlined in white so it reads over any tile.
const z = (x, y, s) => {
  const d = `M${x} ${y}h${s}l-${s} ${s}h${s}`;
  return `<path d="${d}" stroke="#ffffff" stroke-width="${(s * 0.55).toFixed(2)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>` +
    `<path d="${d}" stroke="#4d6fcf" stroke-width="${(s * 0.28).toFixed(2)}" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`;
};

const SLEEPING_EYES = '<path d="M10.6 27.3q1.8 1.6 3.6 0M16.8 27.3q1.8 1.6 3.6 0" stroke="#4a2e16" stroke-width="1.3" fill="none" stroke-linecap="round"/>';
const WAKING_EYES =
  '<path d="M10.6 26.6h3.6M16.8 26.6h3.6" stroke="#4a2e16" stroke-width="1.1" stroke-linecap="round"/>' +
  '<ellipse cx="12.4" cy="27.5" rx="1.5" ry="0.95" fill="#2a1a10"/><ellipse cx="18.6" cy="27.5" rx="1.5" ry="0.95" fill="#2a1a10"/>';

// A ginger cat curled up on a cushion; fewer z's as it wakes.
const sleeperBase = (eyes) =>
  '<ellipse cx="24" cy="45" rx="20" ry="2.4" fill="url(#gs)"/>' +
  '<ellipse cx="24" cy="37" rx="21" ry="8.5" fill="url(#ob-cushion)" filter="url(#ds)"/>' +
  '<ellipse cx="24" cy="35" rx="17" ry="5.5" fill="#f3a3a3" opacity="0.55"/>' +
  '<ellipse cx="26" cy="30" rx="15.5" ry="10" fill="url(#ob-sleeper)"/>' +
  '<path d="M20 22.5q2 4 0 8M26 21q2.4 4.5 0 9.5M32 22q2 4 0 8" stroke="#c46a2c" stroke-width="1.8" fill="none" stroke-linecap="round" opacity="0.7"/>' +
  '<path d="M40 31q3 9-10 9.5-11 .5-19-3" stroke="#c46a2c" stroke-width="5" fill="none" stroke-linecap="round"/>' +
  '<path d="M40 31q3 9-10 9.5-11 .5-19-3" stroke="#f7c27f" stroke-width="2.2" fill="none" stroke-linecap="round"/>' +
  '<path d="M7.5 22l1.2-8 6 5zM17 18.2l5.8-4.6 1 8z" fill="#d9823f"/>' +
  '<path d="M9.3 20.5l.6-3.8 2.8 2.4zM18.8 18.4l2.8-2.2.5 3.8z" fill="#f2b3a0"/>' +
  '<circle cx="15.5" cy="27" r="9" fill="url(#ob-sleeper)"/>' +
  eyes +
  '<path d="M14.6 30.2h1.8l-.9 1.1z" fill="#d4735d"/>' +
  '<path d="M3.5 29.5l5 .6M3.9 32.5l4.8-.9" stroke="#ffffff" stroke-width="0.7" stroke-linecap="round" opacity="0.85"/>';

const paw = (x, y, s, fill, opacity) =>
  `<g transform="translate(${x} ${y}) scale(${s})" fill="${fill}" opacity="${opacity}"><path d="M0 2c4 0 7 3.4 7 6.2S4 12.4 0 12.4-7 11-7 8.2 -4 2 0 2z"/><ellipse cx="-7.6" cy="0.6" rx="2.4" ry="3"/><ellipse cx="-3" cy="-4.6" rx="2.4" ry="3"/><ellipse cx="3" cy="-4.6" rx="2.4" ry="3"/><ellipse cx="7.6" cy="0.6" rx="2.4" ry="3"/></g>`;

const boxBase =
  '<ellipse cx="24" cy="45" rx="19" ry="2.4" fill="url(#gs)"/>' +
  '<rect x="4" y="6" width="40" height="38" rx="4" fill="url(#ob-card)" filter="url(#ds)"/>' +
  '<rect x="4" y="6" width="40" height="10" rx="4" fill="url(#ob-cardTop)"/>' +
  '<path d="M4 16h40" stroke="#8f5f30" stroke-width="1.3" opacity="0.55"/>' +
  '<rect x="20" y="6" width="8" height="38" fill="url(#ob-tape)"/>' +
  paw(11.5, 31, 0.62, '#7a4a24', 0.45) +
  '<path d="M8 10.5h9" stroke="#ffffff" stroke-opacity="0.55" stroke-width="1.8" stroke-linecap="round"/>';

const crateBase = (cracked) =>
  '<ellipse cx="24" cy="45" rx="19" ry="2.4" fill="url(#gs)"/>' +
  '<rect x="4" y="6" width="40" height="38" rx="3" fill="url(#ob-crate)" filter="url(#ds)"/>' +
  '<path d="M4 17h40M4 34h40" stroke="#6b3f1c" stroke-width="2.2"/>' +
  '<path d="M6 9h36M6 37h36" stroke="#f0c48c" stroke-width="1.2" opacity="0.5"/>' +
  '<rect x="10" y="19.5" width="28" height="12.5" rx="6.2" fill="#2a1a10"/>' +
  '<path d="M13.5 21.5l2.6-5 3.6 3.6zM34.5 21.5l-2.6-5-3.6 3.6z" fill="#9b9183"/>' +
  '<ellipse cx="19" cy="25.8" rx="3.2" ry="3.6" fill="#e3f6cc"/><ellipse cx="19" cy="26.2" rx="1.4" ry="2.8" fill="#1b1410"/><circle cx="18" cy="24.6" r="0.9" fill="#ffffff"/>' +
  '<ellipse cx="29" cy="25.8" rx="3.2" ry="3.6" fill="#e3f6cc"/><ellipse cx="29" cy="26.2" rx="1.4" ry="2.8" fill="#1b1410"/><circle cx="28" cy="24.6" r="0.9" fill="#ffffff"/>' +
  '<g fill="#4a2e16"><circle cx="7.5" cy="9.5" r="1.2"/><circle cx="40.5" cy="9.5" r="1.2"/><circle cx="7.5" cy="40.5" r="1.2"/><circle cx="40.5" cy="40.5" r="1.2"/></g>' +
  (cracked ? '<path d="M31 6l-3 6 4 3-3 5M9 44l4-6-3-3" stroke="#3a220e" stroke-width="1.6" fill="none" stroke-linejoin="round"/>' : '');

export const OBSTACLES = {
  box_1: boxBase,
  box_2:
    boxBase +
    '<rect x="4" y="24" width="40" height="7" fill="url(#ob-tapeH)"/>' +
    '<path d="M4 24h40M4 31h40" stroke="#b99b60" stroke-width="0.8" opacity="0.8"/>',
  crate_2: crateBase(false),
  crate_1: crateBase(true),
  sleeper_3: sleeperBase(SLEEPING_EYES) + z(27, 12, 4) + z(33, 6, 5) + z(40, 1, 6),
  sleeper_2: sleeperBase(SLEEPING_EYES) + z(30, 10, 4.5) + z(37, 4, 5.5),
  sleeper_1: sleeperBase(WAKING_EYES) + z(34, 8, 4.5),
  fur: FUR,
  cage: CAGE,
  key: KEY,
  mouse: MOUSE,
  belt: BELT,
  knot:
    '<path d="M3 13Q24 23 45 11" stroke="#5e3196" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.9"/>' +
    '<path d="M3 13Q24 23 45 11" stroke="#caa6f2" stroke-width="2.2" fill="none" stroke-linecap="round"/>' +
    '<path d="M4 38Q24 27 44 40" stroke="#5e3196" stroke-width="5" fill="none" stroke-linecap="round" opacity="0.9"/>' +
    '<path d="M4 38Q24 27 44 40" stroke="#caa6f2" stroke-width="2.2" fill="none" stroke-linecap="round"/>' +
    '<path d="M12 3Q19 24 10 45M36 3Q29 24 38 45" stroke="#5e3196" stroke-width="4.2" fill="none" stroke-linecap="round" opacity="0.85"/>' +
    '<path d="M12 3Q19 24 10 45M36 3Q29 24 38 45" stroke="#dcc2f7" stroke-width="1.8" fill="none" stroke-linecap="round"/>' +
    '<circle cx="39" cy="9" r="6.5" fill="url(#yarn)" filter="url(#ds)"/>' +
    '<path d="M34 7q5 4 10 1M35 12q4-5 8-7" stroke="#5e3196" stroke-width="1.3" fill="none" opacity="0.8"/>',
  paw_print:
    '<rect x="2" y="2" width="44" height="44" rx="8" fill="#f2b3a0" opacity="0.6"/>' +
    paw(24, 25, 1.45, '#d4735d', 0.7),
  sack:
    '<ellipse cx="24" cy="43.5" rx="15" ry="2.8" fill="url(#gs)"/>' +
    '<g filter="url(#ds)"><path d="M12.5 13c4-2.5 19-2.5 23 0l2 4c3 8 3.6 17 1.8 23-2 3-7.6 4-15.3 4S10.7 43 8.7 40c-1.8-6-1.2-15 1.8-23z" fill="url(#ob-sack)"/>' +
    '<path d="M13 13c3 2 19 2 22 0l-2.5-6.5c-3-1.5-14-1.5-17 0z" fill="url(#ob-sackTop)"/></g>' +
    '<path d="M13.5 13.5c3 2 18 2 21 0" stroke="#c43b2a" stroke-width="2.4" fill="none" stroke-linecap="round"/>' +
    '<circle cx="24" cy="28.5" r="8" fill="#fff6e6"/>' +
    '<path d="M18.6 26l1-5.2 3.8 3zM29.4 26l-1-5.2-3.8 3z" fill="#e8613b"/><circle cx="24" cy="29" r="5.2" fill="#e8613b"/>' +
    '<circle cx="22" cy="28.4" r="1" fill="#ffffff"/><circle cx="26" cy="28.4" r="1" fill="#ffffff"/><path d="M23 31h2" stroke="#ffffff" stroke-width="1" stroke-linecap="round"/>' +
    '<path d="M14.5 19c-1.2 6-1.2 12 0 18" stroke="#ffffff" stroke-opacity="0.5" stroke-width="2" stroke-linecap="round" fill="none"/>',
};
