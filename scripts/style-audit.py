#!/usr/bin/env python3
"""Mechanical AI-tell lint for manuscript sections.

This is a LINT, not an AI detector. It counts concrete writing tells that the
blader/humanizer skill removes, so the humanizer pass has a measurable result
instead of an opinion. A low score does not guarantee a detector will pass you;
it means the mechanical tells are gone.

Usage:
  python3 scripts/style-audit.py [--scope DIR] [--max-density 2.0] [--json] [FILES...]

Exit 0 = clean, 1 = findings over the threshold, 2 = usage error.
"""
import argparse
import glob
import json
import os
import re
import sys

# (id, severity, label, regex)
PATTERNS = [
    ("A1", "major", "not-X-but-Y staging", r"\b(?:is|are|was|were|isn't|aren't|wasn't|weren't)\s+(?:not\s+)?(?:just|only|merely|simply)\b[^.;]{0,80}?\b(?:but|it is|it's)\b"),
    ("A2", "minor", "staged run-up", r"\b(?:in order to understand|before we can understand|to appreciate why|it is worth stepping back)\b"),
    ("A3", "minor", "arguing with no one", r"\b(?:some might argue|one might object|critics may say|skeptics would)\b"),
    ("B1", "major", "forced triad", r"\b(\w+),\s+(\w+),\s+and\s+(\w+)\b(?=[^.]{0,40}[.;])"),
    ("B2", "minor", "em-dash connector", r"---|\u2014"),
    ("C1", "major", "AI vocabulary", r"\b(?:delve|delves|delving|tapestry|realm|myriad|pivotal|seamlessly|intricately|testament|beacon|landscape of|crucial role|vital role|plays? a \w+ role)\b"),
    ("C2", "major", "inflated significance", r"\b(?:groundbreaking|revolutionary|unprecedented|game-chang\w+|cutting-edge|paradigm[- ]shift\w*|profound impact)\b"),
    ("C3", "major", "sales language", r"\b(?:powerful|robust(?:ly)? and|cutting[- ]edge|best-in-class|world-class|seamless(?:ly)?)\b"),
    ("C4", "minor", "shallow -ing rider", r",\s+\w+ing\b[^.]{0,60}[.;]"),
    ("C5", "minor", "borrowed authority", r"\b(?:studies have shown|researchers have found|experts agree|it is widely (?:known|believed)|many have noted)\b"),
    ("D1", "critical", "curly quotes", r"[\u201c\u201d\u2018\u2019]"),
    ("D2", "minor", "bold as decoration", r"\\textbf\{"),
    ("E1", "critical", "chatbot residue", r"\b(?:as an AI|I hope this helps|let me know if|here is (?:the|a) (?:revised|draft)|sure,? here)\b"),
    ("E2", "major", "knowledge-limit disclaimer", r"\b(?:as of my knowledge|i (?:do not|don't) have access|my training data)\b"),
    ("E3", "minor", "writing about the document", r"\b(?:this (?:section|paper) will (?:now )?(?:discuss|explore)|in this section, we will)\b"),
    ("F1", "minor", "re-explaining basics", r"\b(?:as everyone knows|it goes without saying|needless to say)\b"),
    ("G1", "minor", "empty transition opener", r"^\s*(?:Moreover|Furthermore|Additionally|Notably|Importantly),"),
]

WORDS = re.compile(r"[A-Za-z][A-Za-z'-]*")


def strip_tex(text):
    """Blank out comments and math so gives do not fire on formulas."""
    text = re.sub(r"(?<!\\)%.*", "", text)
    text = re.sub(r"\$[^$]*\$", " MATH ", text)
    text = re.sub(r"\\\[.*?\\\]", " MATH ", text, flags=re.S)
    text = re.sub(r"\\begin\{(?:equation|align|eqnarray)\*?\}.*?\\end\{(?:equation|align|eqnarray)\*?\}", " MATH ", text, flags=re.S)
    return text


def audit_file(path):
    raw = open(path, encoding="utf-8", errors="replace").read()
    text = strip_tex(raw)
    words = len(WORDS.findall(text)) or 1
    hits = []
    for pid, sev, label, rx in PATTERNS:
        for m in re.finditer(rx, text, flags=re.M | re.I):
            line = text.count("\n", 0, m.start()) + 1
            snippet = " ".join(m.group(0).split())[:60]
            hits.append({"id": pid, "severity": sev, "label": label, "line": line, "text": snippet})
    density = 1000.0 * len(hits) / words
    return {"file": path, "words": words, "hits": hits, "density": round(density, 2)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*")
    ap.add_argument("--scope", default="research/manuscript/sections")
    ap.add_argument("--max-density", type=float, default=2.0,
                    help="max tells per 1000 words (default 2.0)")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    scope = args.scope if os.path.isabs(args.scope) else os.path.join(root, args.scope)
    files = args.files or sorted(glob.glob(os.path.join(scope, "*.tex")))
    files = [f if os.path.isabs(f) else os.path.join(root, f) for f in files]
    files = [f for f in files if os.path.isfile(f)]

    if not files:
        print(f"style-audit: no .tex files under {scope}", file=sys.stderr)
        return 2

    reports = [audit_file(f) for f in files]
    critical = [h for r in reports for h in r["hits"] if h["severity"] == "critical"]
    over = [r for r in reports if r["density"] > args.max_density]

    if args.json:
        print(json.dumps({"reports": reports, "max_density": args.max_density}, indent=2))
    else:
        total = sum(len(r["hits"]) for r in reports)
        print(f"style-audit: {len(reports)} file(s), {total} tell(s), threshold {args.max_density}/1000 words")
        for r in reports:
            flag = "OVER" if r["density"] > args.max_density else "ok"
            print(f"  {os.path.relpath(r['file'], root):58s} {r['density']:5.2f}/1k  {flag}  ({r['words']} words)")
            for h in r["hits"][:8]:
                print(f"    [{h['severity'].upper():8s}] {h['id']} line {h['line']}: {h['label']} — \"{h['text']}\"")

    if critical:
        print(f"\nSTYLE: FAIL — {len(critical)} critical tell(s) (curly quotes / chatbot residue)")
        return 1
    if over:
        names = ", ".join(os.path.basename(r["file"]) for r in over)
        print(f"\nSTYLE: FAIL — density over {args.max_density}/1000 in: {names}")
        return 1
    print("\nSTYLE: PASS — no critical tells, density within threshold")
    return 0


if __name__ == "__main__":
    sys.exit(main())
