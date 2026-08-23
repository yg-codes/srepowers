# Contributing to SREPowers

SREPowers is an SRE-focused fork of [superpowers](https://github.com/obra/superpowers).
Where superpowers optimizes for software development, SREPowers optimizes for
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
| All 18 version sites across 11 manifests carry an identical version | A split version breaks marketplace installs |
| Per plugin, `skills/` dir names == `commands/*.md` names | Every skill needs an invocable command wrapper |
| Each skill's frontmatter `name:` == its directory name | The router resolves skills by name |
| `.agents/skills/` and `.codex/skills/` mirror the canonical set, no broken links | Codex discovers skills through the mirrors |
| README per-plugin counts match on-disk counts | The README is the catalog users read |

**Adding one skill touches five places.** See below.

## Adding a Skill

```
plugins/<plugin>/skills/<name>/SKILL.md      # the skill
plugins/<plugin>/commands/<name>.md          # the command wrapper
.agents/skills/<name>       -> symlink       # ../../plugins/<plugin>/skills/<name>
.codex/skills/<name>        -> symlink       # ../../plugins/<plugin>/skills/<name>
README.md                                    # bump the plugin's skill count
```

Also add the skill to
`plugins/srepowers-core/skills/using-srepowers/references/skill-catalog.md`, and
add a test under `tests/claude-code/test-<name>.sh`.

Pick the right plugin:

| Plugin | Scope |
|---|---|
| `srepowers-core` | Workflow spine, mandatory gates, incident response |
| `srepowers-domain` | Language, architecture, and security expertise |
| `srepowers-infra` | Infrastructure administration |
| `srepowers-private` | Puppet / Ansible / Hiera operations |

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

**Unlike upstream, SREPowers wants fork-sync contributions.** superpowers
rejects them because it is the origin; SREPowers is the fork, and staying
current with upstream is a goal.

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

## Testing

```bash
python3 scripts/validate-repo.py          # packaging, skills, mirrors, versions
bash scripts/lint-shell.sh --strict       # shellcheck + shfmt + syntax
for t in tests/hooks/test-*.sh; do bash "$t"; done   # hook behavior matrices
python3 tests/hooks/test-block-unsourced-claims.py   # opt-in Stop hook
bash tests/shell-lint/test-lint-shell.sh  # the linter itself
bash tests/codex/run-skill-tests.sh       # Codex manifest/hook invariants
bash tests/claude-code/run-skill-tests.sh # per-skill behavior suite (needs `claude`)
```

The `tests/claude-code/` suite dispatches real model calls and is slow; the rest
run offline in seconds. CI runs everything except the model-dependent suite.

See [docs/testing.md](docs/testing.md) for the full layout.

## Versioning and Release

Versions live in 18 sites across 11 manifests. Never edit them by hand:

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
