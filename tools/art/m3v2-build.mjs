import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { make } from './m3v2-screens.mjs';
import { DEFS } from './m3v2-assets.mjs';

const OUT = process.argv[2];

const dc = (body, bg) => `<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&amp;family=Nunito:wght@600;700;800&amp;display=swap">
  <style>
    body { margin: 0; background: ${bg}; }
    a { color: #d9542f; } a:hover { color: #a83a1c; }
  </style>
</helmet>
${body}
</x-dc>
</body>
</html>
`;

for (const s of make('dc').screens) writeFileSync(join(OUT, s.file), dc(s.html, s.bg));

const pos = [[0, 0], [490, 0], [980, 0], [0, 1004], [490, 1004], [980, 1004]];
const canvas = {
  artboards: make('dc').screens.map((s, i) => ({ file: s.file, x: pos[i][0], y: pos[i][1], w: 390, h: 844, title: s.label })),
  annotations: [
    { id: 'kedi-dongu', x: 1470, y: 0, w: 320, text: 'KEDİ BARINAĞI\nDöngü: bölümü oyna → hedefleri topla → yeni kedi kurtar → ona isim ver → barınakta gör.\nGüçlendiriciler: Lazer satırı temizler, Kedi nanesi tahtayı karıştırır, Pençe tek taş kırar.\nParlayan iki taş ipucu: yer değiştirince 3 balık yan yana gelir.\nBarınak sahnesinde en fazla 8 kedi görünür; tüm kediler Albüm ekranında.' },
    { id: 'mutfak-dongu', x: 1470, y: 1004, w: 320, text: 'TARİF MUTFAĞI\nDöngü: sipariş gelir → malzemeleri eşleştir → yemek hazır → tarif defterine eklenir → lokanta büyür.\nHedef tarifin kendisi: Menemen = 8 domates + 6 biber + 4 yumurta.\nGüçlendiriciler: Oklava satırı temizler, Kepçe karıştırır, Bıçak tek taş kırar.' },
  ],
  launch: { view: 'canvas' },
};
writeFileSync(join(OUT, 'canvas.json'), JSON.stringify(canvas, null, 2));

const widget = (only, name) => {
  const { screens, used } = make('w', only);
  const styles = new Map();
  const classify = (html) => html.replace(/ style="([^"]*)"/g, (_, s) => {
    if (!styles.has(s)) styles.set(s, `z${name}${styles.size}`);
    return ` class="${styles.get(s)}"`;
  });
  const figs = screens.map((s) => `<figure><div class="ph"><div>${classify(s.html)}</div></div><figcaption>${s.label}</figcaption></figure>`).join('');
  const symbols = [...used].map(([id, [inner, vb]]) => `<symbol id="${id}" viewBox="${vb}">${inner}</symbol>`).join('');
  const css = [...styles].map(([s, c]) => `.${c}{${s}}`).join('\n');
  const html = `<style>
.m3 .sr-only{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0 0 0 0);white-space:nowrap}
.m3 .wrap{display:flex;flex-wrap:wrap;gap:12px}
.m3 figure{margin:0}
.m3 .ph{--s:.52;width:calc(390px*var(--s));height:calc(844px*var(--s));overflow:hidden;border-radius:12px;box-shadow:0 0 0 1px rgba(0,0,0,.14)}
.m3 .ph>div{width:390px;height:844px;transform:scale(var(--s));transform-origin:0 0}
.m3 figcaption{font:13px system-ui,sans-serif;margin-top:6px;color:var(--text-secondary)}
${css}
</style>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&family=Nunito:wght@600;700;800&display=swap">
<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>${DEFS}${symbols}</defs></svg>
<div class="m3"><h2 class="sr-only">${name.startsWith('kedi') ? 'Kedi Barınağı temalı Match 3 ekran taslakları' : 'Tarif Mutfağı temalı Match 3 ekran taslakları'}</h2><div class="wrap">${figs}</div></div>`;
  writeFileSync(join(OUT, `onizleme-${name}.html`), html);
  return html.length;
};
console.log('kedi1', widget([0, 2], 'kedi1'), 'kedi2', widget([1], 'kedi2'), 'mutfak', widget([3, 4, 5], 'mutfak'));
