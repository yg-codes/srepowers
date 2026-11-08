---
name: fixture-lint
description: Use when writing or editing a skill-test fixture YAML, before running skill-test-runner on one, after a fixture's golden failed its own assertions, or for a periodic hygiene pass over the fixture store. Also use for "check this fixture", "lint the fixtures", "why does my fixture always fail". Read-only check; changes nothing.
---

# fixture-lint

Static checker for skill-test fixture YAMLs: parseability, required keys,
assertion completeness, and the golden-vs-assertion invariant — a
`golden_output` must satisfy the fixture's own `required_section` assertions,
matched case-insensitively exactly as [[skill-test-runner]] does.

**Announce at start:** "I'm using the fixture-lint skill to validate the
fixture(s) before a run."

## Why it exists

Two recurring defects, both of which waste an agent run and misattribute the
failure to the skill:

1. **A golden that cannot pass its own assertions.** Someone edits the golden
   for readability and removes the exact string an assertion demands. Every run
   then fails no matter how correct the skill is.
2. **A checker that disagrees with the runner.** An ad-hoc validator matched
   case-sensitively while the runner matches case-insensitively, so it
   false-positived on title-case goldens — a gate that cannot pass.

This linter matches the runner's semantics deliberately. If the two ever
diverge, the linter is wrong.

## Usage

From this skill's directory (the script path is skill-relative, as in every
other script-bearing skill):

```bash
python3 scripts/fixture_lint.py                      # whole store (default)
python3 scripts/fixture_lint.py /abs/path/fixture.yaml   # specific file(s)
python3 scripts/fixture_lint.py /abs/path/dir            # any dir, recursive
```

From the repo root — the form to prefer when a fixture records a `command:`,
since store paths are repo-relative:

```bash
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py \
  evals/fixtures/<skill>/<fixture>.yaml
```

**Do not mix the two.** A skill-relative script path beside a bare
`evals/fixtures/…` argument resolves from no single directory; it fails loudly
(`WARN file-unreadable`, exit 1) rather than silently, but it still wastes a
cycle. Either prefix the script or absolutise the fixture.

Exit 1 if any WARN, 0 otherwise. INFO does not affect the exit code.

The store defaults to `<repo-root>/evals/fixtures`, located by walking up from
the script — so the bare `scripts/fixture_lint.py` form works from anywhere in
a repo clone or a marketplace clone. A packaged **cache** install
(`<plugin>/<version>/skills/…`) has no repo root above it and ships no
fixtures; there, pass an explicit path.

**`pyyaml` is required** (`pip install pyyaml`). CI installs it; without it the
script fails at import with `ModuleNotFoundError: No module named 'yaml'`.

A scan that finds no files **exits 2 with an explicit FAIL**, never a clean
result — see *Reading the output*.

Run its own unit tests with:

```bash
python3 -B scripts/test_fixture_lint.py
```

Directory scans cover `*.yaml` plus, include-only, `fixture-*.json` and any
`*_raw.json` / `*_raw.yaml`. An explicit file path of any format is always
linted.

## Rules

| Rule id | Level | Catches |
|---|---|---|
| `uncurated-raw-dump` | WARN | filename matches `_raw.(json\|yaml)` or content has a `RAW DUMP` marker — an uncurated capture of real tool output, the highest-risk artifact in the store (may carry real identities or confidential content). Other checks are skipped; it is not a fixture yet |
| `file-unreadable` | WARN | file missing or unreadable (OS error, not a YAML problem) |
| `yaml-unparseable` | WARN | not valid YAML — the runner would die on it |
| `not-a-mapping` | WARN | top level is a list or scalar, not the fixture mapping |
| `missing-key` | WARN | no `skill`, `trigger`, `assertions`, or `golden_output` |
| `no-assertions` | WARN | `assertions` is present but empty — the fixture would PASS unconditionally |
| `assertion-not-a-mapping` | WARN | a scalar/list entry in `assertions` — the runner skips it silently, so it asserts nothing |
| `vacuous-required-section` | WARN | `required_section` value is empty or whitespace — matches any output, so it can never fail |
| `bad-numeric-expected` | WARN | `numeric_within_tolerance` `expected` ≤ 0 — the formula divides by it, so 0 is undefined and a negative value inverts the check into one that always passes |
| `not-a-list` | WARN | `assertions` or `tool_responses` present but not a list — entries would be silently skipped |
| `golden-misses-required-section` | WARN | golden lacks a `required_section` value (case-insensitive substring, per runner semantics) — the golden would fail the fixture's own assertion |
| `assertion-missing-keys` | WARN | assertion lacks its type's required keys (`llm_judge` needs rubric + pass_threshold; `required_table_column` needs section + column) |
| `unknown-assertion-type` | WARN | type outside the four the runner defines |
| `bad-pass-threshold` | WARN | `pass_threshold` not a number in (0, 1] |
| `weak-judge-threshold` | WARN | a rubric listing N items and deducting D each scores `1-D` with one missing, but `pass_threshold` sits at or below that — so a golden missing a mandatory item still passes. Silent unless both the deduction and ≥2 items are stated |
| `golden-content-after-footer` | WARN | the rubric requires the output to *end with* a literal, and the golden continues past it — so the golden fails the fixture's own rubric item |
| `golden-misses-rubric-footer` | WARN | the rubric requires the output to *end with* a literal the golden does not contain at all. `golden-misses-required-section` does not cover this — it only inspects `required_section` values, never `llm_judge` literals |
| `tool-response-missing-keys` | WARN | a `tool_responses` entry lacks tool / match_on / response |
| `missing-tool-responses` | INFO | fixture mocks nothing — legal, but a skill that calls tools needs mocks |
| `bash-response-no-exit-code` | INFO | a `tool: bash` mock without an `(exit code: N)` line — store convention, and exit codes are load-bearing for ops skills |
| `paraphrase-brittle-required-section` | INFO | a multi-word `required_section` matched only in golden prose — not on a heading line, not verbatim in any mocked response — so a correct output phrased differently would fail it. Exact commands and flags enforced deliberately are fine; concept phrases belong in the `llm_judge` rubric |

## Reading the output

A clean run prints its **denominator**: `no findings (N fixture(s) checked)`.
Read the N — "0 problems out of 0 examined" is indistinguishable from a healthy
store, which is the §2.8 failure mode this linter is otherwise built to catch.

A scan that matches **zero files exits 2** with an explicit FAIL naming the
path searched, rather than reporting clean. The usual causes are a wrong cwd,
an empty store, or a packaged install that ships no fixtures.

## When to run

After writing or editing any fixture, and before invoking
[[skill-test-runner]] on it. The runner calls this itself at its Step 1 and
aborts on WARN.

WARN fixes are always small (add the missing string to the golden, fill the
key). INFO is a convention nudge, not a gate.

## What it cannot check about a golden

Three rubric defects are mechanical and now caught: the threshold arithmetic
(`weak-judge-threshold`), a golden that runs past a mandated terminal footer
(`golden-content-after-footer`), and one that omits that footer entirely
(`golden-misses-rubric-footer`). **Everything else about whether a golden
satisfies its own rubric needs a judge, not a linter.** Rubric items are
natural-language claims — "no bare timestamp appears anywhere", "it states the
denominator", "findings are ranked biggest-cut-first" — and a static check
cannot decide them.

So these classes stay a human-review matter, and all three shipped once:

- **A golden claiming more than its mocks support** — 9 files scanned when 4
  were read, "one caller" from a definition-only match, a flag called live that
  was never searched.
- **A golden asserting a finding its mocked code cannot exhibit** — an invented
  returns-None path through a function that either returns or raises.
- **A rubric that contradicts the skill under test** — requiring the agent to
  refuse something the trigger explicitly asked for.

The two footer rules are **phrasing-bound**, and knowing the recognized forms
matters because silence is not a pass:

- The *demand* must read "ends with", "terminates with/in", or "final line is",
  followed by a backticked literal **on the same line**. A rubric that only says
  the footer "carries both counts", or that wraps between the phrase and the
  literal, is not matched.
- `weak-judge-threshold` recognizes the deduction as "deduct D for each".
  Phrasings like "deduct D per missing item", "D off for each", or a percentage
  stay silent.

Broadening either pattern trades a miss for false positives, which is the worse
failure for a rule people are meant to trust. But **do not read silence as
approval** — if a rubric states its arithmetic or its terminal footer in other
words, check it by hand.

## Limits

Checks fixture *structure*, never whether the fixture tests anything worth
testing. A fixture whose only assertion is `required_section: "the"` lints
clean and proves nothing.

Related: [[skill-test-runner]] runs the fixture; [[skill-iterate]] loops until
green.
