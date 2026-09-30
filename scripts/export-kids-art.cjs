#!/usr/bin/env node
/**
 * Exports the Fire TV app's kids-mode drawing library (src/kidsArt.ts)
 * to JSON: { id: innerSvgMarkup }. The app renders these to PNG assets —
 * see render-kids-art.cjs + scripts/art-renderer.html.
 */
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const tvRepo = path.resolve(process.env.TV_REPO || '../fifirecipes-amazonfire');
const jiti = require(path.join(tvRepo, 'node_modules/jiti/lib/jiti.cjs'))(__filename);

const { ART } = jiti(path.join(tvRepo, 'src/kidsArt.ts'));
if (!ART || typeof ART !== 'object') throw new Error('ART export not found in kidsArt.ts');

const outDir = path.join(repoRoot, 'scripts', 'out');
fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'kids-art.json'), JSON.stringify(ART));
console.log(`exported ${Object.keys(ART).length} kids art entries`);
