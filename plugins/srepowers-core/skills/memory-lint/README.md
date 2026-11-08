# memory-lint

Integrity checker for a file-based agent memory store: frontmatter schema,
name-slug uniqueness, two-way `MEMORY.md` index consistency, `[[link]]`
resolution, and PII spans. Reports only — fixing is a deliberate follow-up.
Ships as `srepowers-core:memory-lint`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Catch drift after edits: unindexed files recall can't see, dangling index
  entries, duplicate slugs
- Scan the store for email/name-shaped PII before it travels with every
  later context read
- Hygiene pass before a session that depends on recall being complete

## How-to

Just ask — "check my memories", "lint the memory store", "is MEMORY.md in
sync" — or invoke the `srepowers-core:memory-lint` command. Run the linter:

```bash
python3 plugins/srepowers-core/skills/memory-lint/scripts/memory_lint.py                  # nearest store at/above cwd
python3 plugins/srepowers-core/skills/memory-lint/scripts/memory_lint.py /path/to/memory  # any other store
```

Exit 1 on any WARN, 0 otherwise. Fix WARNs immediately (add an index line,
fill a field); leave INFO `dangling-link` alone — a memory worth writing.

### Verify

The fixture at `evals/fixtures/memory-lint/fixture-store-hygiene.yaml` runs
via `srepowers-core:skill-test-runner`. Unit tests:

```bash
python3 -B plugins/srepowers-core/skills/memory-lint/scripts/test_memory_lint.py
```

## Reference

- `SKILL.md` — full rule catalog (12 rules, WARN/INFO), expected store shape,
  how to read the output, and the limits of a clean run
- `scripts/memory_lint.py` — the linter
- `scripts/test_memory_lint.py` — unit tests

WARN catches broken frontmatter, duplicate slugs, index drift, and possible
PII (email/name-shaped spans). A clean run proves structural soundness only.

---
Last Updated: 2026-09-14
