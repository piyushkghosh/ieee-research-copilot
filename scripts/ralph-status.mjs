#!/usr/bin/env node
// ralph-status.mjs — progress check for research/.state/ralph.json
//   node scripts/ralph-status.mjs          table + summary
//   node scripts/ralph-status.mjs --next   print the next open story id
//   node scripts/ralph-status.mjs --json   machine readable
// Exit: 0 = all stories pass, 1 = stories remain, 2 = bad/missing state.
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const FILE = join(ROOT, 'research/.state/ralph.json');
const mode = process.argv[2] || '';

if (!existsSync(FILE)) {
  console.error(`ralph: no state file at ${FILE} — create it from .github/skills/paper-ralph/SKILL.md`);
  process.exit(2);
}
let state;
try { state = JSON.parse(readFileSync(FILE, 'utf8')); }
catch (e) { console.error(`ralph: cannot parse ${FILE}: ${e.message}`); process.exit(2); }

const stories = Array.isArray(state.stories) ? state.stories : [];
const done = stories.filter((s) => s.passes);
const open = stories.filter((s) => !s.passes);

if (mode === '--json') {
  console.log(JSON.stringify({ total: stories.length, passed: done.length, remaining: open.length, next: open[0] ?? null }, null, 2));
  process.exit(open.length ? 1 : 0);
}
if (mode === '--next') {
  if (!open.length) { console.log('ralph: all stories pass'); process.exit(0); }
  const s = open[0];
  console.log(`STORY ${s.id}: ${s.title}`);
  console.log(`OWNER: ${s.owner}`);
  console.log(`ACCEPTANCE: ${s.acceptance}`);
  console.log(`ROUNDS: ${s.rounds ?? 0}`);
  if (s.notes) console.log(`NOTES: ${s.notes}`);
  process.exit(1);
}

console.log(`goal: ${state.goal || '(unset)'}   autonomy: ${state.autonomy !== false}`);
for (const s of stories) {
  const mark = s.passes ? 'PASS' : `open r${s.rounds ?? 0}`;
  console.log(`${String(s.id).padStart(2)}  ${mark.padEnd(7)} ${s.title}  [${s.owner}]`);
}
console.log('---');
console.log(`${done.length}/${stories.length} stories pass, ${open.length} remaining`);
process.exit(open.length ? 1 : 0);
