#!/usr/bin/env python3
"""audit-tex.py — mechanical checks the gates rely on. Stdlib only.

Usage:
  python3 scripts/audit-tex.py --citations        # \\cite keys <-> refs.bib entries
  python3 scripts/audit-tex.py --figures          # floats must be referenced
  python3 scripts/audit-tex.py --words            # per-section counts + abstract range
  python3 scripts/audit-tex.py --numbers FILE [--against FILE]
                                                  # numeric/unit/citation multiset diff
                                                  # (humanizer invariant: diff must be empty)
  python3 scripts/audit-tex.py --all              # citations + figures + words

Options: --scope <dir> (default research/manuscript), --json, --abstract-min N (150),
         --abstract-max N (250)
Exit: 0 clean · 1 findings · 2 usage/IO error
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SCOPE = ROOT / "research" / "manuscript"

CITE_RE = re.compile(r"\\[a-zA-Z]*cite[a-zA-Z]*\*?(?:\[[^\]]*\])*\{([^}]*)\}")
REF_RE = re.compile(r"\\(?:ref|autoref|cref|Cref|eqref|pageref)\{([^}]*)\}")
LABEL_RE = re.compile(r"\\label\{([^}]*)\}")
BIB_ENTRY_RE = re.compile(r"@(\w+)\s*\{\s*([^,\s]+)\s*,")
UNIT_RE = re.compile(
    r"(?<![\w.])(\d+(?:\.\d+)?)\s*(%|ms|us|µs|ns|s|min|h|Hz|kHz|MHz|GHz|"
    r"B|KB|MB|GB|TB|KiB|MiB|GiB|W|kW|mW|V|mV|A|mA|dB|mm|cm|m|km|"
    r"px|dpi|fps|FLOPs|GFLOPs|MFLOPs|k|K|M|x)(?![\w])"
)
NUM_RE = re.compile(r"(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])")
CITE_BRACKET_RE = re.compile(r"\[(\d+(?:\s*[-,]\s*\d+)*)\]")
TEX_CMD_RE = re.compile(r"\\[a-zA-Z]+\*?(?:\[[^\]]*\])?(?:\{[^{}]*\})?")
COMMENT_RE = re.compile(r"(?<!\\)%.*$", re.MULTILINE)


def tex_files(scope: Path) -> list[Path]:
    files = sorted(scope.glob("*.tex")) + sorted((scope / "sections").glob("*.tex"))
    return [f for f in files if f.is_file()]


def read(p: Path) -> str:
    try:
        return COMMENT_RE.sub("", p.read_text(encoding="utf-8", errors="replace"))
    except OSError as e:
        print(f"ERROR: cannot read {p}: {e}", file=sys.stderr)
        sys.exit(2)


def rel(p: Path) -> str:
    try:
        return str(p.relative_to(ROOT))
    except ValueError:
        return str(p)


def check_citations(scope: Path, out: dict) -> int:
    cited: dict[str, list[str]] = {}
    for f in tex_files(scope):
        for m in CITE_RE.finditer(read(f)):
            for key in (k.strip() for k in m.group(1).split(",")):
                if key:
                    cited.setdefault(key, []).append(rel(f))

    bib = scope / "refs.bib"
    entries: dict[str, int] = {}
    if bib.exists():
        for m in BIB_ENTRY_RE.finditer(read(bib)):
            if m.group(1).lower() in {"comment", "string", "preamble"}:
                continue
            entries[m.group(2)] = entries.get(m.group(2), 0) + 1

    missing = sorted(k for k in cited if k not in entries)
    unused = sorted(k for k in entries if k not in cited)
    dupes = sorted(k for k, n in entries.items() if n > 1)

    out["citations"] = {
        "cited_keys": len(cited),
        "bib_entries": len(entries),
        "missing_from_bib": missing,
        "unused_in_bib": unused,
        "duplicate_entries": dupes,
        "missing_locations": {k: cited[k] for k in missing},
    }
    findings = 0
    for k in missing:
        print(f"[CRITICAL] citation key '{k}' has no refs.bib entry (cited in {', '.join(cited[k])})")
        findings += 1
    for k in dupes:
        print(f"[MAJOR] duplicate refs.bib entry '{k}'")
        findings += 1
    for k in unused:
        print(f"[MINOR] refs.bib entry '{k}' never cited")
    if entries and not missing:
        print(f"citations OK: {len(cited)} keys cited, {len(entries)} entries, all resolve")
    elif not entries:
        print("[MAJOR] refs.bib missing or has no entries")
        findings += 1
    return findings


def check_figures(scope: Path, out: dict) -> int:
    labels: dict[str, str] = {}
    referenced: set[str] = set()
    for f in tex_files(scope):
        t = read(f)
        for m in LABEL_RE.finditer(t):
            labels[m.group(1)] = rel(f)
        for m in REF_RE.finditer(t):
            for name in m.group(1).split(","):
                referenced.add(name.strip())

    floats = {k: v for k, v in labels.items() if k.startswith(("fig:", "tab:", "alg:"))}
    unreferenced = sorted(k for k in floats if k not in referenced)
    dangling = sorted(r for r in referenced if r.startswith(("fig:", "tab:", "alg:")) and r not in labels)

    out["figures"] = {
        "float_labels": len(floats),
        "unreferenced": unreferenced,
        "dangling_refs": dangling,
    }
    for k in unreferenced:
        print(f"[MAJOR] float '{k}' ({floats[k]}) is never referenced in text")
    for k in dangling:
        print(f"[CRITICAL] \\ref to unknown float '{k}'")
    if not unreferenced and not dangling:
        print(f"floats OK: {len(floats)} float(s), all referenced")
    return len(unreferenced) + len(dangling)


def word_count(text: str) -> int:
    body = TEX_CMD_RE.sub(" ", text)
    body = re.sub(r"[{}$&#_^~\\]", " ", body)
    body = re.sub(r"\s+", " ", body).strip()
    return len(body.split()) if body else 0


def check_words(scope: Path, out: dict, lo: int, hi: int) -> int:
    counts = {}
    for f in tex_files(scope):
        counts[rel(f)] = word_count(read(f))
    out["words"] = counts
    for f, n in counts.items():
        print(f"{n:6d}  {f}")
    findings = 0
    abstract = scope / "sections" / "abstract.tex"
    key = rel(abstract)
    if abstract.exists():
        n = counts.get(key, 0)
        if not lo <= n <= hi:
            print(f"[MAJOR] abstract is {n} words; checklist B3 requires {lo}-{hi}")
            findings += 1
        else:
            print(f"abstract OK: {n} words within {lo}-{hi}")
    return findings


def extract_numbers(text: str) -> Counter:
    body = COMMENT_RE.sub("", text)
    c: Counter = Counter()
    for m in NUM_RE.finditer(body):
        c[f"num:{m.group(1)}"] += 1
    for m in UNIT_RE.finditer(body):
        unit = m.group(2)
        c[f"measure:{m.group(1)} {unit}"] += 1
    for m in CITE_RE.finditer(body):
        for k in (x.strip() for x in m.group(1).split(",")):
            if k:
                c[f"cite:{k}"] += 1
    for m in CITE_BRACKET_RE.finditer(body):
        c[f"bracket:[{m.group(1).replace(' ', '')}]"] += 1
    for m in re.finditer(r"\b10\.\d{4,9}/[-._;()/:A-Za-z0-9]+\b", body):
        c[f"doi:{m.group(0)}"] += 1
    for m in REF_RE.finditer(body):
        c[f"ref:{m.group(1).strip()}"] += 1
    return c


def check_numbers(target: Path, against: Path | None, out: dict) -> int:
    if not target.exists():
        print(f"ERROR: {target} not found", file=sys.stderr)
        sys.exit(2)
    cur = extract_numbers(target.read_text(encoding="utf-8", errors="replace"))
    out["numbers"] = {"file": str(target), "tokens": dict(sorted(cur.items()))}
    if against is None:
        for tok, n in sorted(cur.items()):
            print(f"{n:4d}  {tok}")
        print(f"tokens: {sum(cur.values())} ({len(cur)} distinct)")
        return 0
    if not against.exists():
        print(f"ERROR: --against {against} not found", file=sys.stderr)
        sys.exit(2)
    prev = extract_numbers(against.read_text(encoding="utf-8", errors="replace"))
    removed = prev - cur
    added = cur - prev
    out["numbers"]["against"] = str(against)
    out["numbers"]["diff"] = {
        "removed": dict(sorted(removed.items())),
        "added": dict(sorted(added.items())),
    }
    if not removed and not added:
        print(f"numbers OK: multiset identical to {against.name} ({sum(cur.values())} tokens)")
        return 0
    for tok, n in sorted(removed.items()):
        print(f"[CRITICAL] lost x{n}: {tok}")
    for tok, n in sorted(added.items()):
        print(f"[CRITICAL] introduced x{n}: {tok}")
    print("numbers DIFFER — revert the edit (humanizer/editor must not change numbers, units, citations, DOIs, refs)")
    return 1


def main() -> int:
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--citations", action="store_true")
    ap.add_argument("--figures", action="store_true")
    ap.add_argument("--words", action="store_true")
    ap.add_argument("--numbers", metavar="FILE", default=None)
    ap.add_argument("--against", metavar="FILE", default=None)
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--scope", default=str(DEFAULT_SCOPE))
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--abstract-min", type=int, default=150)
    ap.add_argument("--abstract-max", type=int, default=250)
    a = ap.parse_args()

    scope = Path(a.scope).resolve()
    if not scope.exists():
        print(f"ERROR: scope {scope} not found", file=sys.stderr)
        return 2
    if not any([a.citations, a.figures, a.words, a.numbers, a.all]):
        ap.print_help()
        return 2

    out: dict = {}
    findings = 0
    if a.all or a.citations:
        findings += check_citations(scope, out)
    if a.all or a.figures:
        findings += check_figures(scope, out)
    if a.all or a.words:
        findings += check_words(scope, out, a.abstract_min, a.abstract_max)
    if a.numbers:
        findings += check_numbers(Path(a.numbers), Path(a.against) if a.against else None, out)

    if a.json:
        print(json.dumps({"findings": findings, **out}, indent=2))
    return 0 if findings == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
