#!/usr/bin/env node
/**
 * ieee-research-copilot — install the agent pack into a folder with no wrapper directory.
 *
 *   npx ieee-research-copilot                  # install into the current folder
 *   npx ieee-research-copilot init ./my-paper  # install into ./my-paper
 *   npx ieee-research-copilot update           # refresh agents/scripts, keep research/ state
 *   npx github:piyushkghosh/ieee-research-copilot init
 */
import { cpSync, existsSync, readdirSync, statSync, chmodSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const PKG_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PACK_ENTRIES = ['.github', 'scripts', 'research', 'README.md'];
const USER_OWNED = ['research/inputs', 'research/literature', 'research/datasets', 'research/experiments', 'research/figures'];

const argv = process.argv.slice(2);
const flags = new Set(argv.filter((a) => a.startsWith('-')));
const positional = argv.filter((a) => !a.startsWith('-'));
let command = positional[0] && !positional[0].startsWith('.') && !positional[0].includes('/') ? positional[0] : 'init';
if (command !== 'init' && command !== 'update') command = 'init';
const rest = positional[0] === command ? positional.slice(1) : positional;
const target = resolve(rest[0] || '.');

const FORCE = flags.has('--force') || flags.has('-f');
const QUIET = flags.has('--quiet') || flags.has('-q');
const NO_PREFLIGHT = flags.has('--no-preflight');

const say = (m) => { if (!QUIET) console.log(m); };
const fail = (m) => { console.error(m); process.exit(1); };

if (flags.has('--help') || flags.has('-h')) {
  console.log(`ieee-research-copilot — install the IEEE paper copilot pack

Usage
  npx ieee-research-copilot [init] [dir] [--force] [--no-preflight]
  npx ieee-research-copilot update [dir] [--quiet]

Installs .github/ scripts/ research/ and README.md directly into the target folder
(no nested ieee-research-copilot/ directory), which is what VS Code needs to load
the custom agents and skills.

Options
  --force, -f      overwrite existing files
  --no-preflight   skip the toolchain detection run
  --quiet, -q      minimal output
  --help, -h       this text

Next
  code <dir>  →  Copilot Chat  →  agent "research-orchestrator"  →  /paper-start`);
  process.exit(0);
}

if (existsSync(join(target, '.github', 'agents'))) {
  if (command === 'init' && !FORCE) {
    fail(`refusing to overwrite: ${target} already contains .github/agents
Use \`npx ieee-research-copilot update\` to refresh agents and scripts, or --force to replace everything.`);
  }
}

mkdirSync(target, { recursive: true });

let copied = 0;
let skipped = 0;
for (const entry of PACK_ENTRIES) {
  const src = join(PKG_ROOT, entry);
  if (!existsSync(src)) continue;
  const dest = join(target, entry);
  if (statSync(src).isDirectory()) {
    cpSync(src, dest, {
      recursive: true,
      force: FORCE || command === 'update',
      errorOnExist: false,
      filter: (s) => {
        const rel = s.slice(PKG_ROOT.length + 1).replaceAll('\\', '/');
        if (command !== 'update') return true;
        // update never clobbers the author's own research material or state
        return !USER_OWNED.some((u) => rel === u || rel.startsWith(u + '/'));
      },
    });
  } else {
    cpSync(src, dest, { force: FORCE || command === 'update' });
  }
}

// node_modules leftovers are never wanted in the installed pack
const junk = join(target, 'node_modules');
if (existsSync(join(target, 'package.json')) && existsSync(junk)) {
  // leave it alone; the target may be a real project
}

// make the helper scripts executable where the platform supports it
if (process.platform !== 'win32') {
  for (const s of readdirSync(join(target, 'scripts'))) {
    if (s.endsWith('.sh') || s.endsWith('.py') || s.endsWith('.mjs')) {
      try { chmodSync(join(target, 'scripts', s), 0o755); } catch {}
    }
  }
}

say(`installed into ${target}`);
say('  .github/agents  → 32 custom agents');
say('  .github/skills  → 6 skills');
say('  scripts/        → preflight, bootstrap, build, audit, selftest');

if (existsSync(join(target, 'research', 'inputs', 'README.md'))) {
  say('  research/inputs → put your PDFs in research/inputs/papers/');
}

if (!NO_PREFLIGHT) {
  say('');
  say('next: run the toolchain check');
  say(`  cd ${target}`);
  say('  node scripts/preflight.mjs   (or: bash scripts/preflight.sh)');
}

say('');
say('then:');
say(`  code ${target}`);
say('  Copilot Chat  →  agent "research-orchestrator"  →  /paper-start');
