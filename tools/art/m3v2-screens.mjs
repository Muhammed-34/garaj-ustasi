import { DEFS, TILES, catHead, catSit, SIL, DISH, STAR_ON, STAR_OFF, ICON } from './m3v2-assets.mjs';

const FH = "'Fredoka', 'Nunito', 'Trebuchet MS', sans-serif";
const FB = "'Nunito', 'Trebuchet MS', system-ui, sans-serif";

const K = {
  bg: 'linear-gradient(180deg, #fde8d0 0%, #f6d2ae 100%)', ink: '#5a3a28', muted: '#9a7a64', b1: '#ffa47f', b2: '#e8613b', b3: '#b8452a',
  frame: 'linear-gradient(180deg, #d49a62 0%, #a86d3c 100%)', frameEdge: '#74461f',
  cells: ['linear-gradient(180deg, #fffaf2 0%, #f3e2cb 100%)', 'linear-gradient(180deg, #fbefdf 0%, #ecd6ba 100%)'],
  track: '#eadbc9', bubble: 'radial-gradient(circle at 35% 30%, #ffffff 0%, #f3e6d6 70%, #e3cdb4 100%)', bubbleEdge: '#c9ab8c',
};
const M = {
  bg: 'repeating-linear-gradient(0deg, rgba(90, 70, 50, 0.05) 0 2px, transparent 2px 30px), repeating-linear-gradient(90deg, rgba(90, 70, 50, 0.05) 0 2px, transparent 2px 60px), linear-gradient(180deg, #fbf6ee 0%, #eee2d0 100%)',
  ink: '#4a3222', muted: '#8f7a66', b1: '#ff8a6a', b2: '#d63c2a', b3: '#9e2618',
  frame: 'linear-gradient(180deg, #7a4f30 0%, #4e311c 100%)', frameEdge: '#2e1c10',
  cells: ['linear-gradient(145deg, #ffffff 0%, #ebe5da 100%)', 'linear-gradient(145deg, #f6f1e8 0%, #e2d9cb 100%)'],
  track: '#e6d9c8', bubble: 'radial-gradient(circle at 35% 30%, #ffffff 0%, #f1ebe2 70%, #ddd1c1 100%)', bubbleEdge: '#c3b3a0',
};

const KEDI_ROWS = ['m b y m p c b', 'y p b c m y m', 'c m p y b b p', 'p y c b m c y', 'b c m p y m b', 'm y b c p y c', 'y p m b c p m'];
const MUTFAK_ROWS = [...KEDI_ROWS].reverse();

export function make(mode, only = [0, 1, 2, 3, 4, 5]) {
  const used = new Map();
  const sym = (id, inner, vb, w, h) => {
    if (mode !== 'w') return `<svg viewBox="${vb}" width="${w}" height="${h}">${inner}</svg>`;
    used.set(id, [inner, vb]);
    return `<svg viewBox="${vb}" width="${w}" height="${h}"><use href="#${id}"></use></svg>`;
  };
  const tile = (k, s = 38) => sym(k, TILES[k], '0 0 48 48', s, s);
  const head = (n, s) => sym(`ch-${n}`, catHead(n), '0 0 100 100', s, s);
  const sit = (n, w) => {
    if (mode === 'w') used.set(`ch-${n}`, [catHead(n), '0 0 100 100']);
    const inner = mode === 'w' ? catSit(n).replace(catHead(n), `<svg viewBox="0 0 100 100" width="100" height="100"><use href="#ch-${n}"></use></svg>`) : catSit(n);
    return sym(`cs-${n}`, inner, '0 0 100 132', w, Math.round(w * 1.32));
  };
  const sil = (s) => sym('sil', SIL, '0 0 100 100', s, s);
  const dish = (k, w) => sym(`d-${k}`, k === 'hazir' ? DISH.steam + DISH.menemen : DISH[k], '0 0 160 120', w, Math.round(w * 0.75));
  const star = (on, s) => sym(on ? 'st1' : 'st0', on ? STAR_ON : STAR_OFF, '0 0 48 48', s, s);
  const icon = (k, s = 36) => sym(`ic-${k}`, ICON[k], '0 0 48 48', s, s);
  const defs = mode === 'w' ? '' : `<svg width="0" height="0" style="position: absolute;" aria-hidden="true"><defs>${DEFS}</defs></svg>`;

  const root = (P, extra = '') => `width: 390px; height: 844px; box-sizing: border-box; padding: 22px 20px 26px; background: ${P.bg}; color: ${P.ink}; font-family: ${FB}; display: flex; flex-direction: column; gap: 16px; position: relative; overflow: hidden;${extra}`;
  const panel = 'background: linear-gradient(180deg, #ffffff 0%, #fff7ee 100%); border-radius: 22px; box-shadow: inset 0 1px 0 #ffffff, 0 8px 20px rgba(120, 70, 30, 0.16);';
  const btn = (P, label, extra = '') => `<div style="height: 58px; border-radius: 29px; background: linear-gradient(180deg, ${P.b1} 0%, ${P.b2} 100%); box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.45), 0 5px 0 ${P.b3}, 0 10px 18px rgba(0, 0, 0, 0.18); color: #ffffff; font-family: ${FH}; font-size: 21px; font-weight: 600; text-shadow: 0 1px 0 rgba(0, 0, 0, 0.25); display: flex; align-items: center; justify-content: center;${extra}">${label}</div>`;
  const header = (P, title, big, small) => `<div style="display: flex; align-items: center; justify-content: space-between;"><div style="font-family: ${FH}; font-size: 34px; font-weight: 600; line-height: 1; text-shadow: 0 2px 0 rgba(255, 255, 255, 0.7);">${title}</div><div style="display: flex; align-items: baseline; gap: 6px; padding: 8px 16px; border-radius: 999px; background: linear-gradient(180deg, #ffffff 0%, #f3e3d0 100%); box-shadow: 0 3px 0 rgba(0, 0, 0, 0.1), 0 6px 12px rgba(0, 0, 0, 0.1);"><span style="font-family: ${FH}; font-size: 22px; font-weight: 600;">${big}</span><span style="font-size: 13px; font-weight: 800; color: ${P.muted};">${small}</span></div></div>`;
  const bar = (P, pct, fill = `linear-gradient(180deg, ${P.b1} 0%, ${P.b2} 100%)`, track = P.track) => `<div style="height: 10px; border-radius: 5px; background: ${track}; box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.18);"><div style="width: ${pct}%; height: 100%; border-radius: 5px; background: ${fill}; box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.4);"></div></div>`;
  const goal = (P, k, label, pct) => `<div style="display: flex; align-items: center; gap: 8px;">${tile(k, 32)}<div style="flex-grow: 1; display: flex; flex-direction: column; gap: 4px;"><div style="font-family: ${FH}; font-size: 16px; font-weight: 600;">${label}</div>${bar(P, pct)}</div></div>`;
  const board = (P, th, rows, map, hint) => {
    let cells = '';
    rows.forEach((row, r) => row.split(' ').forEach((ch, c) => {
      const on = hint.some(([hr, hc]) => hr === r && hc === c);
      cells += `<div style="height: 44px; border-radius: 11px; background: ${P.cells[(r + c) % 2]}; display: flex; align-items: center; justify-content: center; ${on ? 'position: relative; box-shadow: 0 0 0 3px #ffffff, 0 0 14px 5px rgba(255, 196, 60, 0.95);' : 'box-shadow: inset 0 -2px 0 rgba(120, 70, 30, 0.12);'}">${tile(`${th}-${map[ch]}`)}</div>`;
    }));
    return `<div style="flex-shrink: 0; background: ${P.frame}; border-radius: 22px; padding: 8px; box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.35), 0 6px 0 ${P.frameEdge}, 0 14px 24px rgba(0, 0, 0, 0.22); display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 4px;">${cells}</div>`;
  };
  const booster = (P, label, k, n) => `<div style="display: flex; flex-direction: column; align-items: center; gap: 8px;"><div style="position: relative; width: 66px; height: 66px; border-radius: 50%; background: ${P.bubble}; box-shadow: 0 4px 0 ${P.bubbleEdge}, 0 9px 14px rgba(0, 0, 0, 0.18); display: flex; align-items: center; justify-content: center;">${icon(k, 40)}<div style="position: absolute; top: -4px; right: -6px; min-width: 24px; height: 24px; padding: 0 6px; box-sizing: border-box; border-radius: 12px; background: linear-gradient(180deg, #ff7a5c 0%, #d63c2a 100%); border: 2px solid #ffffff; color: #ffffff; font-family: ${FH}; font-size: 13px; font-weight: 600; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.25);">${n}</div></div><div style="font-size: 13px; font-weight: 800;">${label}</div></div>`;
  const rays = (x, y, s) => `<div style="position: absolute; left: ${x}px; top: ${y}px; width: ${s}px; height: ${s}px; background: repeating-conic-gradient(from 0deg at 50% 50%, rgba(255, 255, 255, 0.34) 0deg 9deg, rgba(255, 255, 255, 0) 9deg 18deg); -webkit-mask-image: radial-gradient(circle, #000000 20%, transparent 65%); mask-image: radial-gradient(circle, #000000 20%, transparent 65%);"></div>`;
  const chip = (label, on) => `<div style="height: 44px; padding: 0 20px; border-radius: 22px; display: flex; align-items: center; font-family: ${FH}; font-size: 17px; font-weight: 600; ${on ? `background: linear-gradient(180deg, ${K.b1} 0%, ${K.b2} 100%); color: #ffffff; box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.4), 0 3px 0 ${K.b3};` : 'background: linear-gradient(180deg, #ffffff 0%, #fff3e6 100%); color: #5a3a28; box-shadow: 0 3px 0 #ead3bb;'}">${label}</div>`;

  const kediOyun = () => `<div style="${root(K)}">${defs}
  ${header(K, 'Bölüm 12', '18', 'hamle')}
  <div style="${panel} padding: 14px 16px; display: flex; flex-direction: column; gap: 12px;">
    <div style="display: flex; align-items: center; gap: 12px;"><div style="width: 56px; height: 56px; flex-shrink: 0; border-radius: 50%; background: radial-gradient(circle at 40% 35%, #ffffff 0%, #f1e2cf 100%); box-shadow: inset 0 -2px 4px rgba(120, 70, 30, 0.15); display: flex; align-items: center; justify-content: center;">${sil(46)}</div><div style="display: flex; flex-direction: column; gap: 2px;"><div style="font-family: ${FH}; font-size: 18px; font-weight: 600;">Yeni bir dost yolda</div><div style="font-size: 13px; font-weight: 700; color: ${K.muted};">Hedefleri topla, tekir kedi barınağa gelsin</div></div></div>
    <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">${goal(K, 'k-m', '9 / 15', 60)}${goal(K, 'k-b', '4 / 10', 40)}</div>
  </div>
  ${board(K, 'k', KEDI_ROWS, { m: 'm', y: 'y', b: 'b', p: 'p', c: 'c' }, [[2, 3], [3, 3]])}
  <div style="margin-top: auto; display: flex; justify-content: space-around;">${booster(K, 'Lazer', 'lazer', 2)}${booster(K, 'Kedi nanesi', 'nane', 1)}${booster(K, 'Pençe', 'pence', 3)}</div>
</div>`;

  const kediBarinak = () => {
    const rescued = [['pamuk', 'Pamuk'], ['tarcin', 'Tarçın'], ['gece', 'Gece'], ['boncuk', 'Boncuk'], ['fistik', 'Fıstık'], ['limon', 'Limon'], ['duman', 'Duman']];
    const card = ([k, n]) => `<div style="border-radius: 16px; background: linear-gradient(180deg, #ffffff 0%, #fff4e8 100%); box-shadow: 0 3px 0 #ead3bb, 0 6px 12px rgba(120, 70, 30, 0.12); padding: 6px 4px 8px; display: flex; flex-direction: column; align-items: center; gap: 2px;">${head(k, 54)}<div style="font-size: 13px; font-weight: 800;">${n}</div></div>`;
    const locked = `<div style="border-radius: 16px; background: rgba(255, 255, 255, 0.35); box-shadow: inset 0 0 0 2px rgba(154, 122, 100, 0.3); padding: 6px 4px 8px; display: flex; flex-direction: column; align-items: center; gap: 2px;">${sil(54)}<div style="font-size: 13px; font-weight: 800; color: ${K.muted};">Kilitli</div></div>`;
    const plat = (r, b, w) => `<div style="position: absolute; right: ${r}px; bottom: ${b}px; width: ${w}px; height: 14px; border-radius: 7px; background: linear-gradient(180deg, #c3b0e2 0%, #8d78ba 100%); box-shadow: 0 4px 0 #6c5a96, 0 6px 10px rgba(0, 0, 0, 0.2);"></div>`;
    return `<div style="${root(K)}">${defs}
  ${header(K, 'Barınak', '7 / 24', 'dost')}
  <div style="height: 210px; flex-shrink: 0; border-radius: 22px; overflow: hidden; position: relative; background: repeating-linear-gradient(90deg, rgba(255, 255, 255, 0.16) 0 14px, transparent 14px 28px), linear-gradient(180deg, #f9dcbc 0%, #efc497 100%); box-shadow: inset 0 0 0 3px rgba(255, 255, 255, 0.5), 0 8px 20px rgba(120, 70, 30, 0.18);">
    <div style="position: absolute; left: 22px; top: 14px; width: 106px; height: 88px; box-sizing: border-box; border-radius: 10px; background: linear-gradient(180deg, #a9dcff 0%, #e6f6ff 100%); border: 6px solid #fffaf3; box-shadow: 0 4px 10px rgba(0, 0, 0, 0.15);"></div>
    <div style="position: absolute; left: 73px; top: 14px; width: 4px; height: 88px; background: #fffaf3;"></div>
    <div style="position: absolute; left: 22px; top: 56px; width: 106px; height: 4px; background: #fffaf3;"></div>
    <div style="position: absolute; left: 36px; top: 100px; width: 190px; height: 120px; background: linear-gradient(160deg, rgba(255, 250, 220, 0.55) 0%, rgba(255, 250, 220, 0) 70%); clip-path: polygon(0 0, 45% 0, 100% 100%, 30% 100%);"></div>
    <div style="position: absolute; left: 14px; top: 100px; width: 122px; height: 10px; border-radius: 4px; background: linear-gradient(180deg, #ffffff 0%, #e8d6c0 100%); box-shadow: 0 3px 6px rgba(0, 0, 0, 0.15);"></div>
    <div style="position: absolute; left: 0; right: 0; bottom: 0; height: 58px; background: linear-gradient(180deg, rgba(80, 40, 10, 0) 0%, rgba(80, 40, 10, 0.2) 100%), repeating-linear-gradient(90deg, #d8a26c 0 58px, #c48c55 58px 60px); box-shadow: inset 0 3px 0 rgba(255, 255, 255, 0.3);"></div>
    <div style="position: absolute; left: 128px; bottom: 8px; width: 140px; height: 34px; border-radius: 50%; background: radial-gradient(circle at 50% 40%, #f0a08c 0%, #c65a48 100%); box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);"></div>
    <div style="position: absolute; right: 78px; bottom: 40px; width: 16px; height: 130px; border-radius: 4px; background: repeating-linear-gradient(0deg, #ecd3a4 0 3px, #c9a46a 3px 6px); box-shadow: inset -3px 0 0 rgba(0, 0, 0, 0.12);"></div>
    ${plat(44, 34, 92)}${plat(40, 100, 92)}${plat(88, 158, 70)}
    <div style="position: absolute; left: 50px; top: 43px;">${sit('pamuk', 48)}</div>
    <div style="position: absolute; right: 100px; bottom: 167px;">${sit('tarcin', 46)}</div>
    <div style="position: absolute; right: 52px; bottom: 109px;">${sit('limon', 46)}</div>
    <div style="position: absolute; left: 172px; bottom: 14px;">${sit('gece', 54)}</div>
  </div>
  <div style="display: flex; align-items: baseline; justify-content: space-between;"><div style="font-family: ${FH}; font-size: 20px; font-weight: 600;">Kurtardıkların</div><div style="font-size: 14px; font-weight: 800; color: ${K.b2};">Albüm ›</div></div>
  <div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px;">${rescued.map(card).join('')}${locked.repeat(5)}</div>
  <div style="margin-top: auto; border-radius: 22px; padding: 12px 12px 12px 14px; background: linear-gradient(180deg, #6a4632 0%, #432a1c 100%); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.2), 0 8px 18px rgba(60, 30, 10, 0.3); color: #fff3e6; display: flex; align-items: center; gap: 12px;">
    <div style="width: 56px; height: 56px; flex-shrink: 0; border-radius: 50%; background: rgba(255, 255, 255, 0.12); display: flex; align-items: center; justify-content: center;">${sil(46)}</div>
    <div style="display: flex; flex-direction: column; gap: 2px;"><div style="font-family: ${FH}; font-size: 18px; font-weight: 600;">Sıradaki dost</div><div style="font-size: 13px; font-weight: 700; color: #e6cdb6;">2 bölüm kaldı</div></div>
    ${btn(K, 'Oyna', ' margin-left: auto; height: 50px; padding: 0 28px;')}
  </div>
</div>`;
  };

  const confetti = [[36, 96, '#ff9a7a', '#e2553a', -20], [334, 80, '#8fd0ff', '#3a8fd6', 25], [70, 300, '#ffe38a', '#e0a81c', 40], [318, 280, '#d8b6ff', '#8f5fd0', -35], [140, 36, '#ffc79a', '#d9803a', 12], [246, 44, '#ffe38a', '#e0a81c', -10], [24, 200, '#d8b6ff', '#8f5fd0', 60], [350, 190, '#ff9a7a', '#e2553a', -50]]
    .map(([x, y, a, b, r]) => `<div style="position: absolute; left: ${x}px; top: ${y}px; width: 11px; height: 20px; border-radius: 3px; background: linear-gradient(180deg, ${a} 0%, ${b} 100%); transform: rotate(${r}deg); box-shadow: 0 3px 5px rgba(0, 0, 0, 0.15);"></div>`).join('');

  const kediKurtarildi = () => `<div style="${root({ ...K, bg: 'radial-gradient(circle at 50% 32%, #fff8dc 0%, #ffd9a6 45%, #f2b385 100%)' }, ' align-items: center; text-align: center;')}">${defs}
  ${rays(-60, -40, 510)}${confetti}
  <div style="position: relative; margin-top: 18px;">${sit('tekir', 190)}</div>
  <div style="position: relative; font-family: ${FH}; font-size: 48px; font-weight: 600; line-height: 1; text-shadow: 0 3px 0 rgba(255, 255, 255, 0.7);">Yeni bir dost!</div>
  <div style="position: relative; font-size: 17px; font-weight: 700; color: #8a6450; line-height: 1.4; white-space: pre-line;">Bu tekiri sen kurtardın.
Ona bir isim ver.</div>
  <div style="position: relative; width: 100%; box-sizing: border-box; height: 58px; border-radius: 18px; background: #ffffff; box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.08), 0 0 0 3px #f7c9a8; padding: 0 18px; display: flex; align-items: center; font-family: ${FH}; font-size: 24px; font-weight: 600;">Zeytin<div style="width: 2px; height: 28px; background: ${K.b2}; margin-left: 3px;"></div></div>
  <div style="position: relative; display: flex; gap: 10px; justify-content: center;">${chip('Zeytin', true)}${chip('Paşa', false)}${chip('Mırmır', false)}</div>
  ${btn(K, 'Barınağa götür', ' margin-top: auto; width: 100%; position: relative;')}
</div>`;

  const mutfakOyun = () => `<div style="${root(M)}">${defs}
  ${header(M, 'Bölüm 8', '14', 'hamle')}
  <div style="position: relative; border-radius: 18px; background: linear-gradient(180deg, #fffdf7 0%, #fbf3e4 100%); box-shadow: 0 8px 20px rgba(70, 40, 20, 0.16); padding: 14px 16px; display: flex; flex-direction: column; gap: 10px;">
    <div style="position: absolute; top: -8px; left: 50%; margin-left: -9px; width: 18px; height: 18px; border-radius: 50%; background: radial-gradient(circle at 35% 30%, #ff9a86 0%, #c62a1c 100%); box-shadow: 0 3px 4px rgba(0, 0, 0, 0.3);"></div>
    <div style="display: flex; align-items: center; justify-content: space-between;"><div style="display: flex; flex-direction: column; gap: 2px;"><div style="font-size: 12px; font-weight: 800; letter-spacing: 0.08em; color: ${M.muted};">MASA 3 · SİPARİŞ</div><div style="font-family: ${FH}; font-size: 34px; font-weight: 600; line-height: 1;">Menemen</div></div>${dish('menemen', 88)}</div>
    <div style="border-top: 2px dashed #e5d6c0;"></div>
    <div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px;">${goal(M, 't-d', '6 / 8', 75)}${goal(M, 't-b', '3 / 6', 50)}${goal(M, 't-y', '2 / 4', 50)}</div>
  </div>
  ${board(M, 't', MUTFAK_ROWS, { b: 'd', m: 's', y: 'b', p: 'y', c: 'p' }, [[3, 3], [4, 3]])}
  <div style="margin-top: auto; display: flex; justify-content: space-around;">${booster(M, 'Oklava', 'oklava', 2)}${booster(M, 'Kepçe', 'kepce', 1)}${booster(M, 'Bıçak', 'bicak', 3)}</div>
</div>`;

  const mutfakDefter = () => {
    const open = (d, name, n) => `<div style="border-radius: 20px; background: linear-gradient(180deg, #ffffff 0%, #fbf4ea 100%); box-shadow: 0 4px 0 #e6d6c2, 0 8px 14px rgba(70, 40, 20, 0.1); padding: 8px 8px 10px; display: flex; flex-direction: column; align-items: center; gap: 2px;">${dish(d, 112)}<div style="font-size: 15px; font-weight: 800;">${name}</div><div style="display: flex; gap: 2px;">${[0, 1, 2].map((i) => star(i < n, 20)).join('')}</div></div>`;
    const locked = (name, when) => `<div style="border-radius: 20px; background: rgba(255, 255, 255, 0.45); box-shadow: inset 0 0 0 2px rgba(150, 130, 110, 0.25); padding: 8px 8px 10px; display: flex; flex-direction: column; align-items: center; gap: 2px;">${dish('kilit', 112)}<div style="font-size: 15px; font-weight: 800; color: ${M.muted};">${name}</div><div style="font-size: 12px; font-weight: 800; color: ${M.muted};">${when}</div></div>`;
    return `<div style="${root(M)}">${defs}
  ${header(M, 'Tarif Defteri', '3 / 18', 'tarif')}
  <div style="border-radius: 22px; padding: 14px 16px; background: linear-gradient(180deg, #4d7d5c 0%, #2f5240 100%); box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.25), 0 8px 18px rgba(30, 60, 40, 0.28); color: #f4efe6; display: flex; flex-direction: column; gap: 8px;">
    <div style="display: flex; align-items: center; justify-content: space-between;"><div style="font-family: ${FH}; font-size: 22px; font-weight: 600;">Esnaf Lokantası</div><div style="font-size: 12px; font-weight: 800; padding: 4px 12px; border-radius: 999px; background: linear-gradient(180deg, #ffe38a 0%, #e0a81c 100%); color: #5a3a08; box-shadow: 0 2px 0 #a8740f;">Seviye 2</div></div>
    <div style="font-size: 14px; font-weight: 700; color: #d6e6da;">2 tarif daha: Ev Yemekleri Salonu açılır</div>
    ${bar(M, 60, 'linear-gradient(180deg, #ffe38a 0%, #e0a81c 100%)', 'rgba(0, 0, 0, 0.25)')}
  </div>
  <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 12px;">${open('menemen', 'Menemen', 3)}${open('mercimek', 'Mercimek Çorbası', 2)}${open('coban', 'Çoban Salatası', 1)}${locked('Karnıyarık', "Bölüm 15'te")}${locked('İmam Bayıldı', "Bölüm 22'de")}${locked('Baklava', 'Bayram tarifi')}</div>
  ${btn(M, 'Sıradaki sipariş', ' margin-top: auto;')}
</div>`;
  };

  const mutfakHazir = () => `<div style="${root({ ...M, bg: 'radial-gradient(circle at 50% 30%, #fff9ea 0%, #fbe3c3 50%, #efc9a0 100%)' }, ' align-items: center; text-align: center;')}">${defs}
  ${rays(-60, -60, 510)}
  <div style="position: relative; margin-top: 22px;">${dish('hazir', 280)}</div>
  <div style="position: relative; font-family: ${FH}; font-size: 46px; font-weight: 600; line-height: 1; text-shadow: 0 3px 0 rgba(255, 255, 255, 0.7);">Menemen hazır!</div>
  <div style="position: relative; display: flex; align-items: flex-end; gap: 4px;">${star(true, 50)}<div style="transform: translateY(-10px);">${star(true, 66)}</div>${star(true, 50)}</div>
  <div style="position: relative; width: 100%; box-sizing: border-box; ${panel} padding: 14px; display: flex; align-items: center; gap: 12px; text-align: left;">
    <svg viewBox="0 0 48 48" width="48" height="48"><circle cx="24" cy="24" r="22" fill="url(#face)"/><path d="M6 20c2-12 12-18 20-17 10 1 16 8 16 16-6-6-14-8-22-6-6 2-10 5-14 7z" fill="#5a3a28"/><circle cx="17" cy="26" r="2.3" fill="#2a1a10"/><circle cx="31" cy="26" r="2.3" fill="#2a1a10"/><path d="M17 33c4 4 10 4 14 0" stroke="#8a3a2a" stroke-width="2.2" fill="none" stroke-linecap="round"/><ellipse cx="12" cy="31" rx="3.5" ry="2" fill="url(#blush)"/><ellipse cx="36" cy="31" rx="3.5" ry="2" fill="url(#blush)"/></svg>
    <div style="display: flex; flex-direction: column; gap: 2px;"><div style="font-size: 12px; font-weight: 800; letter-spacing: 0.08em; color: ${M.muted};">MASA 3</div><div style="font-size: 16px; font-weight: 800;">“Tam kıvamında, eline sağlık!”</div></div>
  </div>
  <div style="position: relative; font-size: 14px; font-weight: 800; color: ${M.muted};">Tarif defterine eklendi</div>
  <div style="position: relative; margin-top: auto; width: 100%; display: flex; flex-direction: column; gap: 14px;">${btn(M, 'Sıradaki sipariş')}<div style="height: 50px; border-radius: 25px; background: linear-gradient(180deg, #ffffff 0%, #f3e9dc 100%); box-shadow: 0 4px 0 #d9c7b1; font-family: ${FH}; font-size: 18px; font-weight: 600; display: flex; align-items: center; justify-content: center;">Tarif defteri</div></div>
</div>`;

  const ALL = [
    ['Main.dc.html', 'Kedi · Oyun ekranı', kediOyun, '#f6d2ae'],
    ['KediBarinak.dc.html', 'Kedi · Barınak', kediBarinak, '#f6d2ae'],
    ['KediKurtarildi.dc.html', 'Kedi · Kurtarma anı', kediKurtarildi, '#f2b385'],
    ['MutfakOyun.dc.html', 'Mutfak · Oyun ekranı', mutfakOyun, '#eee2d0'],
    ['MutfakTarifDefteri.dc.html', 'Mutfak · Tarif defteri', mutfakDefter, '#eee2d0'],
    ['MutfakTarifHazir.dc.html', 'Mutfak · Yemek hazır', mutfakHazir, '#efc9a0'],
  ];
  const screens = only.map((i) => { const [file, label, fn, bg] = ALL[i]; return { file, label, html: fn(), bg }; });
  return { screens, used };
}
