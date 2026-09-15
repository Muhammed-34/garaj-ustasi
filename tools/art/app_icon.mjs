import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Resvg } from '@resvg/resvg-js';
import { DEFS } from './m3v2-assets.mjs';
import { GARAGE_DEFS, VEHICLES } from './garage.mjs';

// App icon ("Sahne"): the red coupe on the lift in front of the blue garage wall, like the title screen. Rendered
// to PNG with resvg, because Godot's SVG importer drops the drop-shadow filters. Android also gets adaptive layers:
// the garage and lift are the background and the car the foreground, kept inside the centre every mask shows.
const projectRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

// Where the car sits for a given size; the lift in the background is placed under its wheels.
function carBox(s, scale) {
  const w = s * scale;
  const h = w * 0.75;
  const top = s * 0.5 - h / 2;
  // The vehicle art's wheels touch the ground at 109/120 of its height.
  return { w, h, top, ground: top + (h * 109) / 120 };
}

function room(s, scale) {
  const { w, ground } = carBox(s, scale);
  let body = `<rect width="${s}" height="${s}" fill="#5b7fa6"/>`;
  for (let y = s * 0.07; y < s * 0.7; y += s * 0.086) body += `<rect y="${y}" width="${s}" height="${s * 0.008}" fill="#4c6d92"/>`;
  body += `<rect y="${s * 0.7}" width="${s}" height="${s * 0.3}" fill="#8b949e"/><rect y="${s * 0.7}" width="${s}" height="${s * 0.022}" fill="#6b7480"/>`;
  body += `<ellipse cx="${s / 2}" cy="${s * 0.9}" rx="${w * 0.52}" ry="${s * 0.03}" fill="#3a3f47" opacity="0.45"/>`;
  for (const f of [-0.38, 0.38]) body += `<rect x="${s / 2 + f * w - s * 0.025}" y="${ground}" width="${s * 0.05}" height="${s * 0.9 - ground}" fill="#ffd166"/>`;
  body += `<rect x="${s / 2 - w * 0.52}" y="${ground - s * 0.01}" width="${w * 1.04}" height="${s * 0.045}" rx="${s * 0.01}" fill="#e8a317"/>`;
  return body;
}

function hero(s, scale) {
  const { w, h, top } = carBox(s, scale);
  return `<svg x="${(s - w) / 2}" y="${top}" width="${w}" height="${h}" viewBox="0 0 160 120">${VEHICLES[0].art}</svg>`;
}

function render(size, body, file) {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}"><defs>${DEFS}${GARAGE_DEFS}</defs>${body}</svg>`;
  writeFileSync(join(projectRoot, file), new Resvg(svg, { fitTo: { mode: 'width', value: size }, font: { loadSystemFonts: false } }).render().asPng());
}

render(512, room(512, 0.8) + hero(512, 0.8), 'icon.png');
render(432, room(432, 0.62), 'icon_background.png');
render(432, hero(432, 0.62), 'icon_foreground.png');
console.log('icon.png, icon_background.png and icon_foreground.png written');
