import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFS, catHead } from './m3v2-assets.mjs';

const projectRoot = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
// Godot's SVG importer ignores filters, so filter definitions are dropped instead of silently misrendering.
const gradients = DEFS.replace(/<filter[\s\S]*?<\/filter>/g, '');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
<defs>${gradients}<linearGradient id="icon-bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fde8d0"/><stop offset="1" stop-color="#f2b385"/></linearGradient></defs>
<rect width="512" height="512" rx="112" fill="url(#icon-bg)"/>
<g transform="translate(56 64) scale(4)">${catHead('tekir')}</g>
</svg>
`;

writeFileSync(join(projectRoot, 'icon.svg'), svg);
console.log('icon.svg written');
