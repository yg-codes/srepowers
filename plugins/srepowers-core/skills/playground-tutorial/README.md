# playground-tutorial

Learn SREPowers and the Test-Driven Operation workflow on throwaway local
files — no infrastructure, no production risk. The whole tutorial runs inside
`~/.srepowers-playground`. Ships as `srepowers-core:playground-tutorial`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- First contact with SREPowers before touching real infrastructure
- Walk a complete RED → GREEN → verify → REFACTOR cycle with zero blast radius
- Team training or onboarding a teammate to verification-first habits
- Practice writing verifications that can fail before writing the operation

## How-to

Just ask — "teach me SREPowers", "walk me through TDO safely", "let's
practice TDO" — or invoke the `srepowers-core:playground-tutorial` command.
No prerequisites; this is the starting point.

Example workspace setup:

```bash
mkdir -p "$HOME/.srepowers-playground" && cd "$HOME/.srepowers-playground"
```

The tutorial creates a file that doesn't exist, watches the verification
fail, creates it, watches the same verification pass, then documents — plus
three practice exercises (directory, config file, multi-step). Clean up with
`rm -rf "$HOME/.srepowers-playground"` when done. For real infrastructure,
graduate to `srepowers-core:test-driven-operation`.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - Six tutorial steps with the expected result at each phase
  - Concept-mapping table: tutorial example ↔ real infrastructure equivalent
  - Three practice exercises
  - Common mistakes: skipping RED, verification-too-broad, no cleanup

---
Last Updated: 2026-09-14
