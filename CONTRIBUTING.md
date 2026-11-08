# Contributing to SREPowers

SREPowers is an SRE-focused **companion** to
[superpowers](https://github.com/obra/superpowers) — same workflow spine and
plugin format, recast for infrastructure operations — not a fork of it. Most
skills are original work; ported skills carry upstream attribution under the
upstream MIT licences (see README → Provenance). Where superpowers optimizes
for software development, SREPowers optimizes for
infrastructure operations: verification before claims, explicit blast radius,
stated rollback paths, and evidence-backed reporting.

## Table of Contents

- [Before You Start](#before-you-start)
- [Repository Invariants](#repository-invariants)
- [Adding a Skill](#adding-a-skill)
- [Editing a Skill](#editing-a-skill)
- [Tracking Upstream](#tracking-upstream)
- [Testing](#testing)
- [Versioning and Release](#versioning-and-release)
- [What Does Not Belong Here](#what-does-not-belong-here)

## Before You Start

Read `plugins/srepowers-core/skills/writing-skills-sre/SKILL.md`. It is the
meta-skill governing how every other skill in this repo is authored, and it is
binding: **no skill without a failing test first**, for new skills *and* edits.

Skills are not prose. They shape agent behavior in production. A wording change
to a Red Flags table or a rationalization list is a behavior change and needs
eval evidence, not an opinion.

## Repository Invariants

`scripts/validate-repo.py` enforces these in CI. Every change must keep them
green:

| Invariant | Why |
|---|---|
| All 22 version sites across 13 manifests carry an identical version | A split version breaks marketplace installs |
| Per plugin, `skills/` dir names == `commands/*.md` names | Every skill needs an invocable command wrapper |
| Each skill's frontmatter `name:` == its directory name | The router resolves skills by name |
| `.agents/skills/` and `.codex/skills/` mirror the canonical set, no broken links | Codex discovers skills through the mirrors |
| README per-plugin counts match on-disk counts | The README is the catalog users read |
| `skill-catalog.md` rows and header counts match on-disk skills | `using-srepowers` routes from it — a missing row makes a skill invisible |

**Frontmatter fields.** `name` and `description` are the standard pair and the
only ones the router reads. One documented exception: a skill adapted from
external work carries `license:` naming the upstream licence, because stripping
attribution from a vendored skill is not ours to do. The ported set (superpowers
spine, mattpocock swe chain + `wait-what`/`wizard`, the `handoff` three-source
port, the ponytail family, `ops-brief`, `humanizer`, and `pr` under Apache-2.0)
is the current instance. Do not add other fields.

**Adding one skill touches six places.** See below.

## Adding a Skill

```
plugins/<plugin>/skills/<name>/SKILL.md      # the skill
plugins/<plugin>/commands/<name>.md          # the command wrapper
.agents/skills/<name>       -> symlink       # ../../plugins/<plugin>/skills/<name>
.codex/skills/<name>        -> symlink       # ../../plugins/<plugin>/skills/<name>
README.md                                    # bump the plugin's skill count
plugins/srepowers-core/skills/using-srepowers/references/skill-catalog.md
                                             # add a row + bump the header count
```

Also add a test. Two routes, pick per the Iron Law (`writing-skills-sre`):

- **A fixture** under `evals/fixtures/<name>/` — the stronger evidence: it
  exercises the skill against mocked tool data via
  `srepowers-core:skill-test-runner`, and `fixture-lint` (CI) checks the
  fixture itself. See the fixtures in `evals/fixtures/` for shape, and
  `fixture-lint`'s "What it cannot check about a golden" before writing one.
- **A shell test** under `tests/claude-code/test-<name>.sh` — wording-presence
  checks; lighter, still required by convention for skills predating fixtures.

Pick the right plugin:

| Plugin | Scope |
|---|---|
| `srepowers-core` | Workflow spine, mandatory gates, incident response |
| `srepowers-infra` | Infrastructure administration |

Then:

```bash
python3 scripts/validate-repo.py
```

## Editing a Skill

The Iron Law applies to edits. Establish the baseline failure first — run the
scenario **without** your change and document what the agent actually does —
then write the minimum guidance that closes it, then re-test.

Do not modify carefully-tuned content (Red Flags tables, rationalization tables,
calibration language) without eval evidence across multiple sessions showing the
change is an improvement.

## Tracking Upstream

**Unlike upstream, SREPowers welcomes port-and-adapt contributions.**
superpowers rejects them because it is the origin; SREPowers adapts upstream
work on purpose, and staying current with upstream is a goal.

When porting from superpowers:

- **Recast, don't copy.** Development framing (tests, functions, refactoring)
  becomes operational framing (verification, resources, rollback). A verbatim
  copy that still says "run the test suite" is a bad port.
- **Preserve SREPowers-specific additions.** Several skills are deliberately
  ahead of upstream. Check `git log` before replacing a section.
- **Do not regress the deliberate divergences.** In particular: the Codex
  `SessionStart` matcher is `startup|clear|compact` with no `resume`, and every
  packaged Codex plugin manifest declares `"hooks": {}`. `tests/codex/` asserts
  both. Read the README section on Codex hooks hygiene before touching either.
- **Note the upstream commit** in your PR description so the next sync knows
  what has already landed.

**Survey the origin, not a mirror.** Some upstreams vendor copies of each
other's skills, and a vendored copy can sit several fixes behind the repo that
authors it. The `srepowers-swe:ponytail*` family reached this repo through one
such copy, which predated an upstream narrowing of the `ponytail:` marker rule —
so the skill shipped for three releases telling the agent to mark code its own
fixture said should go unmarked. When two upstreams carry the same skill, diff
against the one that authors it, and record which that is.

## Testing

```bash
python3 scripts/validate-repo.py          # packaging, skills, catalog, mirrors, versions
bash scripts/lint-shell.sh --strict       # shellcheck + shfmt + syntax
for t in tests/hooks/test-*.sh; do bash "$t"; done   # hook behavior matrices
for t in tests/hooks/test-*.py; do python3 "$t"; done # hook python suites (globbed, as CI runs them)
for t in plugins/*/skills/*/scripts/test_*.py; do python3 -B "$t"; done  # skill-script suites
python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py  # the fixture store
bash tests/shell-lint/test-lint-shell.sh  # the linter itself
bash tests/codex/run-skill-tests.sh       # Codex manifest/hook invariants
bash tests/claude-code/run-skill-tests.sh # per-skill behavior suite (needs `claude`)
```

The skill-script and fixture-store steps need `pyyaml` (`pip install pyyaml`);
CI installs it. The `tests/claude-code/` suite dispatches real model calls and
is slow; the rest run offline in seconds. CI runs everything except the
model-dependent suite — all of it globbed, so a newly added suite is picked up
without editing the workflow.

See [docs/testing.md](docs/testing.md) for the full layout.

## Versioning and Release

Versions live in 22 sites across 13 manifests. Never edit them by hand:

```bash
python3 scripts/validate-repo.py --show-versions   # audit current state
python3 scripts/validate-repo.py --bump 5.8.0      # set all, then validate
```

Semantics: **patch** for fixes, **minor** for new skills or features, **major**
for a breaking change to the workflow spine or packaging layout.

Record the change in [RELEASE-NOTES.md](RELEASE-NOTES.md), newest first.

## What Does Not Belong Here

- **Site-specific configuration.** Hostnames, IPs, credentials, internal URLs,
  and company-specific procedures belong in your own private plugin. SREPowers
  ships general-purpose SRE discipline.
- **Third-party service integrations** that promote a specific vendor.
- **A runtime dependency in the core workflow.** Optional companions (the
  brainstorm visual companion needs Node) must stay opt-in and must never be a
  prerequisite for designing or executing an operation.
- **AI-instruction files.** `CLAUDE.md` and `AGENTS.md` are gitignored on
  purpose — they are local context, not shipped content.

## Reporting Issues

Use the templates in `.github/ISSUE_TEMPLATE/`. If the behavior also reproduces
in upstream superpowers, file it there too so both projects benefit.
