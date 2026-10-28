#!/usr/bin/env node
/**
 * preflight.mjs — detect what this machine can actually do.
 * Machine-agnostic: never assumes TeX, python, a browser, or this repo's history.
 *
 * Usage: node scripts/preflight.mjs [--json] [--quiet]
 * Writes: research/.state/toolkit.md   (human + agent readable)
 * Exit:   0 always (reporting tool, not a gate). Read the MODE line.
 */
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, writeFileSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import os from 'node:os';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const argv = new Set(process.argv.slice(2));
const JSON_OUT = argv.has('--json');
const QUIET = argv.has('--quiet');

const run = (cmd, args = [], opts = {}) => {
  const r = spawnSync(cmd, args, { encoding: 'utf8', timeout: opts.timeout ?? 15000, ...opts });
  return {
    ok: r.status === 0,
    status: r.status,
    out: ((r.stdout || '') + (r.stderr || '')).trim(),
  };
};
const has = (cmd) => !run(process.platform === 'win32' ? 'where' : 'command', ['-v', cmd]).status;

const probe = (label, cmd, args = [], versionRe = null) => {
  if (!has(cmd)) return { label, cmd, present: false, version: null };
  const r = run(cmd, args);
  let version = r.out.split('\n')[0]?.trim() || null;
  if (versionRe && r.out) {
    const m = r.out.match(versionRe);
    if (m) version = m[1];
  }
  return { label, cmd, present: true, version, ok: r.ok };
};

const kpse = (name) => {
  // project-local texmf first (no admin rights path), then the system tree
  const candidates = [
    join(ROOT, 'texmf', 'tex', 'latex', 'local', name),
    join(ROOT, 'texmf', 'bibtex', 'bst', name),
  ];
  for (const c of candidates) if (existsSync(c)) return { present: true, path: c + ' (project texmf)' };
  if (!has('kpsewhich')) return { present: false, path: null };
  const r = run('kpsewhich', [name], { env: { ...process.env, TEXMFHOME: join(ROOT, 'texmf') } });
  return { present: r.ok && r.out.length > 0, path: r.out || null };
};

const py = (code) => {
  for (const cmd of ['python3', 'python']) {
    if (!has(cmd)) continue;
    const r = run(cmd, ['-c', code]);
    if (r.ok) return { ok: true, out: r.out };
  }
  return { ok: false, out: '' };
};

// ---------- tools ----------
const tools = {
  node: { label: 'Node.js', present: true, version: process.version },
  npm: probe('npm', 'npm', ['--version']),
  npx: probe('npx', 'npx', ['--version']),
  git: probe('git', 'git', ['--version'], /git version (\S+)/),
  python3: probe('Python 3', 'python3', ['--version'], /Python (\S+)/),
  pip3: probe('pip', 'pip3', ['--version'], /pip (\S+)/),
  pdflatex: probe('pdflatex', 'pdflatex', ['-v'], /pdfTeX ([\d.]+-\S+)/),
  xelatex: probe('xelatex', 'xelatex', ['-v'], /XeTeX ([\d.]+)/),
  lualatex: probe('lualatex', 'lualatex', ['-v'], /LuaHBTeX ([\d.]+)/),
  latexmk: probe('latexmk', 'latexmk', ['-v'], /Latexmk, John Collins, (\S+)/),
  bibtex: probe('bibtex', 'bibtex', ['-v'], /BibTeX ([\d.]+)/),
  biber: probe('biber', 'biber', ['--version'], /biber version: (\S+)/),
  gs: probe('ghostscript', 'gs', ['--version']),
  pdftotext: probe('pdftotext', 'pdftotext', ['-v'], /pdftotext version (\S+)/),
  pdfinfo: probe('pdfinfo', 'pdfinfo', ['-v'], /pdfinfo version (\S+)/),
  pdffonts: probe('pdffonts', 'pdffonts', ['-v'], /pdffonts version (\S+)/),
  pdftoppm: probe('pdftoppm', 'pdftoppm', ['-v'], /pdftoppm version (\S+)/),
  convert: probe('ImageMagick convert', 'convert', ['--version'], /ImageMagick (\S+)/),
  magick: probe('ImageMagick magick', 'magick', ['--version'], /ImageMagick (\S+)/),
  firefox: probe('Firefox', 'firefox', ['--version'], /Mozilla Firefox (\S+)/),
  chromium: probe('Chromium', 'chromium', ['--version'], /Chromium (\S+)/),
  chrome: probe('Google Chrome', 'google-chrome', ['--version'], /Google Chrome (\S+)/),
  inkscape: probe('Inkscape', 'inkscape', ['--version'], /Inkscape (\S+)/),
  rsvg: probe('rsvg-convert', 'rsvg-convert', ['--version'], /rsvg-convert version (\S+)/),
  pandoc: probe('pandoc', 'pandoc', ['--version'], /pandoc(?:\.exe)? (\S+)/),
  qpdf: probe('qpdf', 'qpdf', ['--version'], /qpdf version (\S+)/),
};

// ---------- TeX assets (searched in system tree AND project texmf) ----------
const texAssets = {
  'IEEEtran.cls': kpse('IEEEtran.cls'),
  'IEEEtran.bst': kpse('IEEEtran.bst'),
  'algorithm2e.sty': kpse('algorithm2e.sty'),
  'algpseudocode.sty': kpse('algpseudocode.sty'),
  'algorithmic.sty': kpse('algorithmic.sty'),
  'siunitx.sty': kpse('siunitx.sty'),
  'pgfplots.sty': kpse('pgfplots.sty'),
  'tikz.sty': kpse('tikz.sty'),
  'booktabs.sty': kpse('booktabs.sty'),
  'subcaption.sty': kpse('subcaption.sty'),
  'microtype.sty': kpse('microtype.sty'),
  'cite.sty': kpse('cite.sty'),
  'balance.sty': kpse('balance.sty'),
  'stfloats.sty': kpse('stfloats.sty'),
};

// ---------- python capability ----------
const cairosvg = py('import cairosvg, sys; sys.stdout.write(getattr(cairosvg, "__version__", "ok"))');
const matplotlib = py('import matplotlib; import sys; sys.stdout.write(matplotlib.__version__)');
const numpy = py('import numpy, sys; sys.stdout.write(numpy.__version__)');

const texEngine = ['pdflatex', 'xelatex', 'lualatex'].find((e) => tools[e].present) || null;
const hasLatexmk = tools.latexmk.present;
const hasBib = tools.bibtex.present || tools.biber.present;
const hasIeeeClass = texAssets['IEEEtran.cls'].present;
const canCompile = Boolean(texEngine && (hasLatexmk || true) && hasIeeeClass);
const svgConverter = cairosvg.ok
  ? 'cairosvg'
  : tools.rsvg.present
    ? 'rsvg-convert'
    : tools.inkscape.present
      ? 'inkscape'
      : tools.convert.present || tools.magick.present
        ? 'imagemagick'
        : null;
const browser = ['firefox', 'chromium', 'chrome'].find((b) => tools[b].present) || null;

const CAPS = {
  compile: canCompile,
  pdf_inspection: tools.pdfinfo.present && tools.pdftotext.present,
  svg_to_pdf: Boolean(svgConverter),
  html_render: Boolean(browser),
  plots: texAssets['pgfplots.sty'].present ? 'pgfplots' : null,
  plots_python: matplotlib.ok ? 'matplotlib' : null,
  bibtex: tools.bibtex.present,
  biber: tools.biber.present,
};

const MODE = canCompile ? 'full-tex' : 'degraded-markdown';
const reason = canCompile
  ? 'TeX engine and IEEEtran.cls both resolved.'
  : !texEngine
    ? 'No TeX engine (pdflatex/xelatex/lualatex) on PATH.'
    : !hasIeeeClass
      ? 'TeX engine present but IEEEtran.cls not found (run scripts/bootstrap.sh to fetch it into ./texmf).'
      : 'Unknown — see missing list.';

// ---------- remedies (exact, no sudo) ----------
const fix = [];
if (!texEngine) {
  fix.push({
    item: 'TeX engine',
    commands: {
      linux: ['# Debian/Ubuntu (needs admin): sudo apt install texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended',
        '# no sudo alternative: https://tug.org/texlive/quickinstall.html into ~/texlive'],
      darwin: ['brew install --cask mactex-no-gui'],
      win32: ['winget install MiKTeX.MiKTeX', '# or: choco install miktex'],
    },
  });
}
if (!hasIeeeClass && texEngine) {
  fix.push({
    item: 'IEEEtran.cls / IEEEtran.bst',
    commands: {
      all: ['bash scripts/bootstrap.sh --tex-only   # fetches from CTAN into ./texmf, no admin rights'],
    },
  });
}
if (!cairosvg.ok) {
  fix.push({
    item: 'cairosvg (SVG→PDF)',
    commands: { all: ['pip3 install --user cairosvg', '# fallback: rsvg-convert / inkscape / firefox --headless --print-to-pdf'] },
  });
}
if (!tools.git.present) fix.push({ item: 'git', commands: { all: ['install git — required to fetch diagram-design and humanizer'] } });
if (!browser) fix.push({ item: 'headless browser', commands: { all: ['optional: used only for HTML→PDF figure fallback'] } });

const report = {
  generatedAt: new Date().toISOString(),
  host: { platform: process.platform, arch: process.arch, release: os.release(), cpus: os.cpus().length },
  mode: MODE,
  modeReason: reason,
  capabilities: CAPS,
  tools,
  texAssets,
  python: { cairosvg: cairosvg.out || null, matplotlib: matplotlib.out || null, numpy: numpy.out || null },
  remedies: fix,
  project: { root: ROOT, texmf: join(ROOT, 'texmf') },
};

// ---------- write toolkit.md ----------
const mark = (b) => (b ? 'yes' : '**missing**');
const md = [];
md.push('# Toolchain report');
md.push('');
md.push('<!-- Generated by scripts/preflight.mjs. Re-run instead of editing by hand. -->');
md.push('');
md.push(`- Generated: ${report.generatedAt}`);
md.push(`- Platform: ${report.host.platform}/${report.host.arch} (${report.host.release})`);
md.push(`- **MODE: ${MODE}**`);
md.push(`- Reason: ${reason}`);
md.push('');
md.push('## Capabilities');
for (const [k, val] of Object.entries(CAPS)) md.push(`- ${k}: ${val === false ? '**no**' : val ?? 'n/a'}`);
md.push('');
md.push('## Tools');
md.push('');
md.push('| Tool | Present | Version |');
md.push('|---|---|---|');
for (const [k, t] of Object.entries(tools)) md.push(`| ${t.label || k} | ${mark(t.present)} | ${t.version ? String(t.version).replace(/\|/g, '\\|') : '—'} |`);
md.push('');
md.push('## TeX assets (system or project texmf)');
md.push('');
md.push('| Asset | Present | Path |');
md.push('|---|---|---|');
for (const [k, a] of Object.entries(texAssets)) md.push(`| ${k} | ${mark(a.present)} | ${a.path ? a.path : '—'} |`);
md.push('');
md.push('## Python');
md.push(`- cairosvg: ${report.python.cairosvg || '**missing**'}`);
md.push(`- matplotlib: ${report.python.matplotlib || '**missing or broken** — plots must use pgfplots/TikZ'}`);
md.push(`- numpy: ${report.python.numpy || '**missing**'}`);
md.push('');
md.push('## Remedies (no sudo assumed; ask the user before running)');
if (fix.length === 0) md.push('- none — toolchain complete for this project');
for (const f of fix) {
  md.push('');
  md.push(`### ${f.item}`);
  for (const [plat, cmds] of Object.entries(f.commands)) {
    md.push(`- ${plat}:`);
    for (const c of cmds) md.push(`  - \`${c}\``);
  }
}
md.push('');
md.push('## Rules for agents');
md.push('- Never assume a tool exists; re-read this file at the start of every loop.');
md.push(`- If MODE is \`degraded-markdown\`: write Markdown to \`research/manuscript/\`, skip LaTeX-only gates, mark the compile gate \`SKIPPED (no TeX)\`.`);
md.push('- If MODE is `full-tex`: the compile gate is mandatory before FINAL.');
md.push('- Report missing tools to the user with the exact command; never run sudo, never silently install.');

mkdirSync(join(ROOT, 'research/.state'), { recursive: true });
const out = join(ROOT, 'research/.state/toolkit.md');
writeFileSync(out, md.join('\n') + '\n');

if (JSON_OUT) console.log(JSON.stringify(report, null, 2));
else if (!QUIET) {
  console.log(`MODE: ${MODE} — ${reason}`);
  console.log(`wrote ${out}`);
  const missing = Object.entries(tools).filter(([, t]) => !t.present).map(([, t]) => t.label);
  if (missing.length) console.log(`missing tools: ${missing.join(', ')}`);
}
process.exit(0);
