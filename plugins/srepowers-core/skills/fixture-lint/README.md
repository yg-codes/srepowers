# fixture-lint

Static linter for skill-test fixture YAMLs. Catches — before an agent run
is wasted on them — a golden that can't pass its own assertions,
unparseable YAML, missing or empty required keys, vacuous assertions, and
bad judge thresholds. Read-only; it changes nothing. Ships as
`srepowers-core:fixture-lint`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- Check a fixture before running `srepowers-core:skill-test-runner` on it
  (the runner calls this linter itself at its Step 1 and aborts on WARN)
- "Why does my fixture always fail" — find a golden that fails its own
  `required_section` assertions
- Periodic hygiene pass over the whole fixture store (a zero-file scan
  exits 2, never clean)

## How-to

Say "check this fixture" or "lint the fixtures" — or run the script
directly from the repo root (needs `pyyaml`):

```bash
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py \
  evals/fixtures/<skill>/<fixture>.yaml
# whole store (default)
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py
```

### Verify

Fixture: `evals/fixtures/fixture-lint/fixture-golden-mismatch.yaml`, run
via the `srepowers-core:skill-test-runner` skill. The linter's own unit
tests: `python3 -B plugins/srepowers-core/skills/fixture-lint/scripts/test_fixture_lint.py`.

## Reference

| Exit code | Meaning |
|-----------|---------|
| 0 | Clean — no WARN findings |
| 1 | At least one WARN finding |
| 2 | Scan matched zero files (wrong cwd, empty store) |

- `scripts/fixture_lint.py` — the linter; WARN = would fail or lie in the runner
- `scripts/test_fixture_lint.py` — unit tests for the linter
- `SKILL.md` — full rule catalog, path/cwd contract, linter limits

---
Last Updated: 2026-09-14
