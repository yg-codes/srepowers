---
name: skill-test-runner
description: Use when testing whether a skill actually behaves as written — running a curated fixture against a skill in a sub-agent with mocked tool data and scoring the output against assertions. Also use for "test this skill", "run the fixture", "does this skill work", "did my skill edit break anything". Returns PASS/FAIL with per-assertion detail.
---

# Skill Test Runner

A test harness for skills. Runs one fixture against one skill and reports
pass/fail, with a scored breakdown per assertion.

**Announce at start:** "I'm using the skill-test-runner skill to run
`<fixture>` against `<skill>`."

## Why this exists

`srepowers-core:writing-skills-sre` requires test-driven skill authoring:
*"Wrote the skill before testing? Delete it."* This is the runner that makes
that requirement executable. Without it, "tested" means "read it and it looked
right", which is the failure `verification-gates.md` §1 describes — a check
that cannot fail.

**What a PASS does and does not prove.** It proves the skill's wording produced
the asserted output *for this fixture, in one sub-agent run*. It does not prove
a live run will obey it, and it is not a substitute for the pressure scenarios
in `writing-skills-sre`. Treat it as a regression gate, not a correctness
proof.

## Invocation

```text
skill-test-runner <skill-name> <fixture-path>
skill-test-runner <skill-name> --all
```

- `<skill-name>` — the skill directory name (e.g. `sre-runbook`), resolved
  across `plugins/*/skills/`.
- `<fixture-path>` — a curated fixture YAML, e.g.
  `evals/fixtures/sre-runbook/fixture-restart-service.yaml`.
- `--all` — run every fixture under `evals/fixtures/<skill-name>/` (matching
  `*.yaml` or `fixture-*.json`) through Steps 1–7 each, then emit one aggregate
  table (`Fixture | Score | PASS/FAIL`). **A fixture's failure never skips the
  rest of the batch** — and the aggregate must reconcile N fixtures in to N
  rows out, or say which are missing.

## Fixture shape

```yaml
skill: <skill-name>
trigger: <the prompt that invokes the skill>
tool_responses:                 # every tool call the skill would make, pre-answered
  - tool: bash
    match_on: <short label the skill's intent maps to>
    command: <the command it would have run>
    response: |
      <the mocked output, ending with (exit code: N) for bash>
assertions:
  - type: required_section | numeric_within_tolerance | required_table_column | llm_judge
    ...
golden_output: |
  <reference output — the llm_judge compares substance against this>
```

## Steps

### Step 1 — Load and validate the fixture

Read the fixture. Parse `skill` (verify it matches `<skill-name>`), `trigger`,
`tool_responses`, `assertions`, `golden_output`. Abort with a clear error if
missing or unparseable.

**Refuse raw dumps.** If the filename matches `_raw\.(json|yaml)$` or the
content contains a `RAW DUMP` marker, stop:

> Refusing: `<fixture-path>` looks like an uncurated raw dump, not a curated
> test fixture. See fixture-lint's `uncurated-raw-dump` rule.

An uncurated capture of real tool output can carry real identities or
confidential content verbatim. Do not proceed to Step 2.

Then static-validate before spending an agent run on it:

```bash
python3 ../fixture-lint/scripts/fixture_lint.py <fixture-path>
```

**Abort on exit 1** and report the findings instead of running the test — a
golden that cannot satisfy its own `required_section` assertions will fail no
matter how good the skill is, and burning an agent run to discover that wastes
the run and misattributes the failure. INFO findings are fine to proceed on.

### Step 2 — Load the skill

Read `plugins/*/skills/<skill-name>/SKILL.md`. This is the instruction text
under test.

### Step 3 — Build the test agent prompt

```text
SKILL INSTRUCTIONS:
---
<full SKILL.md content>
---

AVAILABLE DATA (use only this — do not call any real tools or run any commands):
---
[Response for: <match_on>]
<response text>
...
---

INSTRUCTIONS FOR THIS TEST RUN:
- You are being tested. All data you need is provided above under AVAILABLE DATA.
- Do NOT call Bash, kubectl, terraform, any CLI, or any MCP tool. Do NOT read or write any files.
- When the skill instructions say to query for X, find the matching data block above and use it.
- Skip any file-saving, Artifact, or sub-skill invocation steps the skill defines — produce the full output text as your final message instead.
- Follow the skill's reasoning and formatting instructions exactly.
- Produce the complete output the skill would normally produce.
- Date context for this run: treat today as <fixture.date_context>.   # if set

TRIGGER:
<fixture.trigger>
```

**The golden and the assertions never enter the agent prompt.** An agent that
can see what it is graded on will write to the rubric rather than follow the
skill. `extract_packet.py` is unit-tested for this non-leakage.

### Step 3b — Large fixtures: use a packet file

When SKILL.md plus `tool_responses` would exceed roughly 30 KB pasted inline,
do not build the prompt inline:

```bash
python3 scripts/extract_packet.py <fixture-path>
```

It writes a packet file and prints its path. The Step 4 prompt then becomes:
"Read the file at `<packet-path>` and follow every instruction in it exactly.
Its INSTRUCTIONS and TRIGGER sections govern this run." The golden and
assertions stay with the orchestrator either way.

### Step 4 — Invoke the sub-agent

Spawn an Agent with `description: "Skill test: <skill-name>"` and the Step 3
prompt. Capture the full returned text.

### Step 5 — Evaluate assertions

| Type | Check | Failure message |
|------|-------|-----------------|
| `required_section` | output contains `value` (case-insensitive substring) | `Missing required section: <value>` |
| `numeric_within_tolerance` | extract via `pattern` (one capture group); pass if `abs(actual-expected)/expected <= tolerance_pct/100` | `expected=<e> got=<a>`, or `pattern not found in output` |
| `required_table_column` | a markdown table under `section` has a header matching `column` (case-insensitive) | `Table in '<section>' missing column: <column>` |
| `llm_judge` | score the output 0.0–1.0 against `rubric`, using `golden_output` as reference; pass if `>= pass_threshold` | `LLM judge score: <s> (threshold: <t>)` |

For `llm_judge`, score it yourself — do **not** spawn another sub-agent. Judge
whether the output covers the required topics, reasons soundly, and reaches the
golden's key conclusions. **Match substance, not wording.**

### Step 6 — Report

```text
## Test Result: <PASS|FAIL>
**Skill:** <skill-name>
**Fixture:** <fixture-path>
**Score:** <N>/<total> assertions passed

### Assertion Results
| # | Type | Status | Detail |
|---|------|--------|--------|
| 1 | required_section | PASS | Found: "Command" |
| 2 | llm_judge | FAIL | score=0.60 (threshold=0.75) |

### Captured Output (first 800 chars)
<excerpt>

### Failure Summary
<each failure with its assertion type and detail>
```

The overall PASS/FAIL is the exit state. **A run that ends without a verdict
reads as success** — always emit one explicitly, including when the sub-agent
returned nothing.

### Step 7 — Record the result

Append the outcome to the run log the caller is keeping (a CI summary, a
`skill-iterate` cycle record, or the PR description). Record
`<skill>/<fixture>` → `pass|fail` with the assertion count, so a later reader
can tell a skill that was tested and passed from one that was never run.

## Requirements and limits

**Script paths above are relative to this skill's directory**, matching every
other script-bearing skill. **Fixture paths are relative to the repo root**,
because that is where the store lives. Those two are not the same place, so
pick one cwd and make the other path absolute — do **not** copy a
`scripts/…` command and a bare `evals/fixtures/…` argument into one line:

```bash
# From the repo root — prefix the script, keep the fixture path bare:
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py \
  evals/fixtures/<skill>/<fixture>.yaml

# From this skill's directory — keep the script bare, make the fixture absolute:
python3 ../fixture-lint/scripts/fixture_lint.py "$(git rev-parse --show-toplevel)/evals/fixtures/<skill>/<fixture>.yaml"
```

Mixing them fails loudly (`WARN file-unreadable`, exit 1) rather than silently,
but it wastes a cycle. The repo-root form is the one to prefer in a fixture's
recorded `command:` field.

**`pyyaml` is required** (`pip install pyyaml`) — fixtures are YAML and both
scripts call `safe_load`. CI installs it; a local or packaged run without it
fails at import with `ModuleNotFoundError: No module named 'yaml'`.

**The fixture store lives in the repo** at `evals/fixtures/`. A packaged
plugin install ships skills without it, so pass explicit fixture paths there.

- One fixture exercises one path. Green on the store is not coverage.
- `llm_judge` is a judgment call and will vary run to run near its threshold.
  Set `pass_threshold` where a clearly-wrong output fails, not where a
  stylistic difference does.
- Mocked tool data cannot catch a skill that names a tool or flag that does not
  exist — the mocks answer whatever the skill asks. Pair with a real run.

Related: [[fixture-lint]] validates a fixture before it runs;
[[skill-iterate]] loops this runner until green;
`srepowers-core:writing-skills-sre` owns skill authoring itself.
