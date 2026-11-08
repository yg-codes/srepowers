# skill-test-runner

A test harness for skills: runs one curated fixture against one skill in a
fresh sub-agent with mocked tool data, scoring PASS/FAIL with a per-assertion
breakdown. Ships as `srepowers-core:skill-test-runner`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Test-driven skill authoring: `writing-skills-sre` requires tests before shipping
- Regression gate after editing a skill ("did my edit break anything?")
- `--all` batches a skill's whole fixture store into one aggregate table

## How-to

Say "test this skill", "run the fixture", or "does this skill work" — or
invoke `skill-test-runner <skill-name> <fixture-path>` (`--all` for the
whole store). Fixture paths are relative to the repo root; `pyyaml` is
required. Static fixture-lint validation runs first, before any agent run
is spent:

```bash
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py evals/fixtures/<skill>/<fixture>.yaml
```

### Verify

Fixture: `evals/fixtures/skill-test-runner/fixture-failing-assertions.yaml` —
run it with the `srepowers-core:skill-test-runner` skill.

## Reference

| Assertion type | Check |
|----------------|-------|
| `required_section` | Output contains a value (case-insensitive) |
| `numeric_within_tolerance` | Regex-extracted number within `tolerance_pct` of expected |
| `required_table_column` | Markdown table under a section has a matching header column |
| `llm_judge` | Scored 0.0–1.0 against a rubric and golden; passes at threshold |

- `SKILL.md` — 7 runner steps, fixture shape, scoring rules, script-vs-fixture cwd gotcha
- `scripts/extract_packet.py` — packet-file mode for prompts over ~30 KB; keeps golden and assertions out of the agent prompt
- `scripts/test_extract_packet.py` — unit tests for that non-leakage guarantee
- `evals/fixtures/<skill-name>/` — the fixture store, in this repo (not shipped in packaged installs)

---
Last Updated: 2026-09-14
