#!/usr/bin/env node
/**
 * Schema rules that `theme:check` does not enforce, but Shopify refuses an upload
 * for. Both of the ones below have already cost a rejected upload on this theme:
 *
 *   Invalid block 'product': setting with id="nudge" step invalid.
 *   Range settings must have at most 101 steps
 *
 *   Invalid schema: setting with id="lede" default can't be blank
 *
 * Checks, per settings array:
 *   - range: min < max, step > 0, and (max - min) / step <= 100
 *   - no blank `default` (omit the key instead — `"default": ""` is itself invalid)
 *   - no duplicate setting ids
 *
 * Exits 1 with the file, block and id of anything it finds.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { join, relative } from 'node:path';

const ROOT = new URL('..', import.meta.url).pathname;
const THEME = join(ROOT, 'hemp-custom');
const MAX_STEPS = 100;

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    return entry.isDirectory() ? walk(path) : [path];
  });
}

let checked = 0;
const failures = [];

function report(file, where, message) {
  failures.push(`${file}  ${where}  ${message}`);
}

function inspect(settings, where, file) {
  if (!Array.isArray(settings)) return;

  const seen = new Set();

  for (const setting of settings) {
    if (!setting || typeof setting !== 'object') continue;
    checked += 1;

    if (setting.id && seen.has(setting.id)) {
      report(file, where, `duplicate id="${setting.id}"`);
    }
    if (setting.id) seen.add(setting.id);

    if (Object.prototype.hasOwnProperty.call(setting, 'default') && setting.default === '') {
      report(file, where, `id="${setting.id}" has a blank default — omit the key instead`);
    }

    if (setting.type === 'range') {
      const step = setting.step === undefined ? 1 : Number(setting.step);
      const min = Number(setting.min);
      const max = Number(setting.max);
      const steps = Math.round((max - min) / step);

      if (!(step > 0)) {
        report(file, where, `range id="${setting.id}" step must be greater than 0`);
      } else if (!(min < max)) {
        report(file, where, `range id="${setting.id}" min must be less than max`);
      } else if (steps > MAX_STEPS) {
        report(
          file,
          where,
          `range id="${setting.id}" min=${min} max=${max} step=${step} -> ${steps} steps (max ${MAX_STEPS}); widen the step or narrow the range`
        );
      }
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
      report(shown, 'schema', `does not parse — ${error.message}`);
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
  console.log(`\n${failures.length} problem(s). Shopify will refuse the upload until these are fixed.`);
  process.exit(1);
}

console.log(`${checked} settings checked — range steps, blank defaults and duplicate ids all clear.`);
