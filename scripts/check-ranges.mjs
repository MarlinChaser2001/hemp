#!/usr/bin/env node
/**
 * Range settings must have at most 101 steps — `(max - min) / step <= 100`.
 *
 * `theme:check` does not enforce it and passes happily; Shopify refuses the whole
 * upload with
 *
 *   Invalid block 'product': setting with id="nudge" step invalid.
 *   Range settings must have at most 101 steps
 *
 * so this runs over every schema in the theme before a push. Exits 1 if any
 * range is over the limit.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { join, relative } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const THEME = join(ROOT, 'hemp-custom');
const LIMIT = 100; // steps, i.e. 101 positions

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

let checked = 0;
const failures = [];

function inspect(settings, where, file) {
  if (!Array.isArray(settings)) return;
  for (const setting of settings) {
    if (!setting || setting.type !== 'range') continue;
    checked += 1;
    const step = setting.step === undefined ? 1 : Number(setting.step);
    const steps = Math.round((Number(setting.max) - Number(setting.min)) / step);
    if (!Number.isFinite(steps) || steps > LIMIT) {
      failures.push(`${file}  ${where}  id=${setting.id}  min=${setting.min} max=${setting.max} step=${step} -> ${steps} steps (max ${LIMIT})`);
    }
  }
}

for (const file of walk(THEME).filter((f) => /\.(liquid|json)$/.test(f))) {
  const source = readFileSync(file, 'utf8');
  const shown = relative(ROOT, file);
  const schemas = [];

  if (file.endsWith('.liquid')) {
    const match = source.match(/\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}/);
    if (!match) continue;
    try {
      schemas.push(JSON.parse(match[1]));
    } catch (error) {
      console.log(`schema does not parse: ${shown} — ${error.message}`);
      continue;
    }
  } else if (/^hemp-custom\/(sections|blocks)\//.test(relative(THEME, file))) {
    try {
      schemas.push(JSON.parse(source));
    } catch {
      continue;
    }
  }

  for (const schema of schemas) {
    inspect(schema.settings, 'settings', shown);
    for (const block of schema.blocks ?? []) inspect(block.settings, `block:${block.type}`, shown);
  }
}

if (failures.length) {
  console.log(failures.join('\n'));
  console.log(`\n${failures.length} range setting(s) over the limit. Widen the step or narrow min/max.`);
  process.exit(1);
}

console.log(`${checked} range settings, all within ${LIMIT} steps.`);
