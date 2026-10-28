---
description: "Autonomous run: intake with sensible defaults, then drive every story to passing with at most one question. Lowest-token path."
agent: research-orchestrator
---
Run the paper autonomously. Follow `.github/skills/paper-ralph/SKILL.md`.

1. Read `research/.state/{toolkit,project,plan,loop}.md` and `research/inputs/*`. Existing values are authoritative — never re-ask them.
2. Emit **one** opening line, no question: "Running autonomously: defaults will be assumed and marked in project.md; I stop only for data, credentials, or venue rules." Skip it if the user already said "don't ask me" or similar.
3. Intake without interviewing: derive title from `topic.md`/`papers/`; treat supplied methodology as authoritative or mark it `PROPOSED`; generate diagram titles from the methodology; use `refs.txt`/DOI search with every hit verified; default template = IEEEtran conference unless a template exists. Record assumptions as `ASSUMED (auto)`.
4. Ensure `research/.state/ralph.json` exists (create from `plan.md` if missing, default story set from the skill). Then loop: `node scripts/ralph-status.mjs --next` → dispatch owner → run acceptance check → mark pass → one progress line. Repeat.
5. Do not ask "continue?". Do not summarise between stories.
6. Final message only: stories passed/total, gate verdicts, assumptions made, unresolved items, output path (`research/manuscript/build/main.pdf` or the Markdown path), and the exact next command.

If a story fails three rounds, stop and report that story, the failure text, and what only the user can provide.
