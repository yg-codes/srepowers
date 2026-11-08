# brainstorming-operations

Turn an infrastructure idea into an approved design before anything is
executed. Every request is classified up front — read-only probe, bounded
single change, or architectural — and nothing mutating runs until you have
approved the presented design, rollback, and verification. Ships as
`srepowers-core:brainstorming-operations`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Scope a change before touching infrastructure: probe ("is the cert
  expiring"), bounded (one Hiera value, one DNS record), or architectural
  (multi-host, production, quorum/VIP/shared dependency)
- Enforce an approval gate on "too simple to need one" tweaks — a bounded
  design is a few sentences in chat, but the yes comes before execution
- Produce a written, reviewed design doc under `docs/plans/` for large
  work, then hand off to `srepowers-core:writing-operation-plans`
- Show topology options in a browser (opt-in visual companion)

## How-to

Say "let's design this change" or describe the operation — the skill
triggers automatically, announces its classification out loud, and works
that path. Directly: invoke the `srepowers-core:brainstorming-operations`
skill. Architectural work ends in a committed design doc plus a design
review loop, then hands off to `srepowers-core:writing-operation-plans`;
bounded work executes via `srepowers-core:test-driven-operation` after
your explicit yes.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: give it an ambiguous change and confirm it classifies out
loud, presents design + rollback + verification, and stops for approval
before running anything.

## Reference

- `SKILL.md` — look-before-you-ask, the two-shape first message, the
  three paths, one-way upgrade ratchet, approaches as their own message,
  per-path checklists, design-doc structure, red-flag table
- `visual-companion.md` — when/how to drive the browser companion
- `builder-check-prompt.md` — builder-check subagent prompt (the one-round design review)
- `scripts/start-server.sh` / `scripts/stop-server.sh` — start/stop the
  companion server (random port, idle timeout, `--open`)
- `scripts/server.cjs`, `scripts/helper.js`, `scripts/frame-template.html`
  — companion server, client helper, and page frame

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `brainstorming`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-10-26
