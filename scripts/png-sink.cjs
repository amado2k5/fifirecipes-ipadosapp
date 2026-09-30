#!/usr/bin/env node
/**
 * One-shot asset rendering server (dev tool, not shipped).
 *
 *   node scripts/png-sink.cjs
 *
 * Serves a page at http://127.0.0.1:8777/ that the Playwright MCP browser
 * opens. The page rasterises every entry of scripts/out/kids-art.json into
 * a transparent 512x512 PNG and POSTs each back here; the server writes
 * FifiRecipes/Assets.xcassets/KidsArt/<id>.imageset/<id>.png + Contents.json.
 * It also renders the 1024x1024 App Store icon (FiFi emblem on cream) and
 * POSTs it to /icon, written to AppIcon.appiconset/icon-1024.png.
 */
const fs = require('fs');
const http = require('http');
const path = require('path');

const root = path.resolve(__dirname, '..');
const tvRepo = path.resolve(process.env.TV_REPO || '../fifirecipes-amazonfire');
const artJson = path.join(__dirname, 'out', 'kids-art.json');
const logoPath = path.join(tvRepo, 'public', 'logo.webp');
const kidsDir = path.join(root, 'FifiRecipesPad', 'Assets.xcassets', 'KidsArt');
const iconDir = path.join(root, 'FifiRecipesPad', 'Assets.xcassets', 'AppIcon.appiconset');

const PAGE = `<!doctype html><meta charset="utf-8"><body><pre id="log">ready</pre>
<script>
window.__log = (m) => { document.getElementById('log').textContent += '\\n' + m; };

const INK = '#4a3426';
const CRAYON =
  '<filter id="crayon" x="-5%" y="-5%" width="110%" height="110%">' +
  '<feTurbulence type="fractalNoise" baseFrequency="0.04" numOctaves="2" seed="4" result="w"/>' +
  '<feDisplacementMap in="SourceGraphic" in2="w" scale="2.5" xChannelSelector="R" yChannelSelector="G" result="d"/>' +
  '<feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="2" seed="9" result="g"/>' +
  '<feColorMatrix in="g" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.2 2.05" result="p"/>' +
  '<feComposite in="d" in2="p" operator="in"/></filter>';

async function svgPng(inner, size) {
  const svg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="' + size + '" height="' + size + '">' +
    '<defs>' + CRAYON + '</defs>' +
    '<g stroke="' + INK + '" stroke-width="3" stroke-linejoin="round" stroke-linecap="round" filter="url(#crayon)">' +
    inner + '</g></svg>';
  const img = new Image();
  const url = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  await new Promise((res, rej) => { img.onload = res; img.onerror = () => rej(new Error('svg load')); img.src = url; });
  const c = document.createElement('canvas');
  c.width = c.height = size;
  c.getContext('2d').drawImage(img, 0, 0, size, size);
  return c.toDataURL('image/png').split(',')[1];
}

async function post(url, b64) {
  const r = await fetch(url, { method: 'POST', body: b64 });
  if (!r.ok) throw new Error('POST ' + url + ' -> ' + r.status);
}

window.renderAll = async () => {
  const art = await (await fetch('/kids-art.json')).json();
  const ids = Object.keys(art);
  let n = 0;
  for (const id of ids) {
    const b64 = await svgPng(art[id], 512);
    await post('/art/' + encodeURIComponent(id), b64);
    if (++n % 20 === 0) __log('rendered ' + n + '/' + ids.length);
  }
  return n;
};

window.renderIcon = async () => {
  const img = new Image();
  await new Promise((res, rej) => { img.onload = res; img.onerror = () => rej(new Error('logo load')); img.src = '/logo.webp'; });
  const S = 1024;
  const c = document.createElement('canvas');
  c.width = c.height = S;
  const ctx = c.getContext('2d');
  // App icon: opaque warm-cream field (no alpha allowed on the marketing icon).
  const g = ctx.createLinearGradient(0, 0, 0, S);
  g.addColorStop(0, '#fdf4e3');
  g.addColorStop(1, '#f6e9d2');
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, S, S);
  const m = S * 0.09; // emblem margin
  const ar = img.naturalWidth / img.naturalHeight;
  let w = S - m * 2, h = w / ar;
  if (h > S - m * 2) { h = S - m * 2; w = h * ar; }
  ctx.drawImage(img, (S - w) / 2, (S - h) / 2, w, h);
  await post('/icon', c.toDataURL('image/png').split(',')[1]);
  return 'icon saved';
};
</script></body>`;

const server = http.createServer((req, res) => {
  const u = new URL(req.url, 'http://x');
  if (req.method === 'GET' && u.pathname === '/') {
    res.writeHead(200, { 'content-type': 'text/html' });
    return res.end(PAGE);
  }
  if (req.method === 'GET' && u.pathname === '/kids-art.json') {
    res.writeHead(200, { 'content-type': 'application/json' });
    return res.end(fs.readFileSync(artJson));
  }
  if (req.method === 'GET' && u.pathname === '/logo.webp') {
    res.writeHead(200, { 'content-type': 'image/webp' });
    return res.end(fs.readFileSync(logoPath));
  }
  if (req.method === 'POST' && u.pathname.startsWith('/art/')) {
    const id = decodeURIComponent(u.pathname.slice(5));
    if (!/^[a-z0-9-]+$/.test(id)) { res.writeHead(400); return res.end('bad id'); }
    let body = '';
    req.on('data', (d) => (body += d));
    req.on('end', () => {
      const dir = path.join(kidsDir, id + '.imageset');
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, id + '.png'), Buffer.from(body, 'base64'));
      fs.writeFileSync(
        path.join(dir, 'Contents.json'),
        JSON.stringify({
          images: [{ filename: id + '.png', idiom: 'universal', scale: '1x' }],
          info: { author: 'xcode', version: 1 },
          properties: { 'preserves-vector-representation': false },
        }) + '\n',
      );
      res.end('ok');
    });
    return;
  }
  if (req.method === 'POST' && u.pathname === '/icon') {
    let body = '';
    req.on('data', (d) => (body += d));
    req.on('end', () => {
      fs.mkdirSync(iconDir, { recursive: true });
      fs.writeFileSync(path.join(iconDir, 'icon-1024.png'), Buffer.from(body, 'base64'));
      res.end('ok');
    });
    return;
  }
  res.writeHead(404);
  res.end('nope');
});

server.listen(8777, '127.0.0.1', () => console.log('png-sink on http://127.0.0.1:8777'));
