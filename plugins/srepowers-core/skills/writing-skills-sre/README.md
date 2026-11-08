# writing-skills-sre

Create or edit SREPowers skills as test-driven work: watch an agent fail
without the skill, write the minimal skill that fixes that specific failure,
then close the rationalization loopholes it finds. Ships as
`srepowers-core:writing-skills-sre`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- Write a new operational skill (runbook, incident, verification, discipline gate) through the RED-GREEN-REFACTOR loop
- Edit an existing skill without regressing it — the Iron Law applies to edits too: no skill without a failing test first
- Bulletproof a discipline skill against rationalization (excuse tables, red-flag lists, no-nuance rules)
- Wire a finished skill into the repo: command wrapper, both skill symlinks, catalog row, validator pass

## How-to

Ask — "write a new skill", "add a skill", "update a skill", "test this
skill" — or invoke `srepowers-core:writing-skills-sre`. Baseline first: run
pressure scenarios without the skill, capture the verbatim rationalizations,
and write guidance only for failures you observed.

Micro-test wording (fresh-context samples plus a no-guidance control, 5+
reps) before spending full pressure runs; the full methodology is in
`testing-skills-with-subagents.md`.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | The full method: baseline testing, description-quality rules, Skill Discovery Optimization, guidance-form selection, rationalization tables, repo wiring checklist |
| `testing-skills-with-subagents.md` | Pressure-scenario construction, pressure types, micro-testing methodology, meta-testing |
| `anthropic-best-practices.md` | Upstream skill-authoring guidance the plugin extends |
| `graphviz-conventions.dot` | Flowchart style conventions (decision diamonds, never commands in nodes), written as a graph |
| `render-graphs.js` | Renders a skill's `.dot` diagrams to SVG: `./render-graphs.js <skill-dir> [--combine]` |

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `writing-skills`, recast from software development to
infrastructure operations. Extends the upstream skill — superpowers must be installed for the extension to resolve. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
