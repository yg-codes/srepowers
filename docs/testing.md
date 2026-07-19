# Testing SREPowers

SREPowers has two kinds of tests: **offline** checks that validate packaging,
shell hygiene, and hook output, and **model-dependent** checks that dispatch
real sessions to verify skills actually trigger and are followed.

They read different things. The offline checks read **this checkout**. The
model-dependent suite reads the **installed plugin** — a separate clone the
`claude` CLI resolves from your Claude config directory. That distinction
matters whenever you have unmerged work; see `tests/claude-code/` below.

CI runs everything except the model-dependent suite.

## Layout

```
scripts/validate-repo.py         packaging, skills, mirrors, version lockstep
scripts/lint-shell.sh            shellcheck + shfmt + syntax across shell files

tests/hooks/                     SessionStart hook output shapes (offline)
tests/shell-lint/                tests for the linter itself (offline)
tests/codex/                     Codex manifest and hook invariants (offline)
tests/claude-code/               per-skill behavior suite (needs the `claude` CLI;
                                 grades the INSTALLED plugin, not this checkout)
tests/verify-skills.md           manual verification walkthrough
```

## Running Everything

```bash
python3 scripts/validate-repo.py
bash scripts/lint-shell.sh --all --strict
bash tests/hooks/test-session-start.sh
bash tests/shell-lint/test-lint-shell.sh
bash tests/codex/run-skill-tests.sh
bash tests/claude-code/run-skill-tests.sh   # slow, needs `claude` on PATH;
                                            # grades the installed plugin — see below
```

The first five run offline in seconds. The last dispatches real model calls.

## What Each Layer Checks

### `scripts/validate-repo.py`

The packaging gate. It enforces the invariants that a partial change silently
breaks:

- All 18 version sites across 11 manifests carry an identical version
- Per plugin, `skills/` dir names == `commands/*.md` names
- Each skill's frontmatter `name:` matches its directory name
- `.agents/skills/` and `.codex/skills/` mirror the canonical skill set, with no
  broken symlinks
- README per-plugin skill counts match on-disk counts

It also doubles as the version-bump tool:

```bash
python3 scripts/validate-repo.py --show-versions
python3 scripts/validate-repo.py --bump 5.8.0
```

### `scripts/lint-shell.sh`

Runs ShellCheck (`--severity=warning`, following sourced files), then `bash -n`
or `sh -n` per script depending on its shebang.

```bash
bash scripts/lint-shell.sh                  # changed + untracked files
bash scripts/lint-shell.sh --all            # full tracked baseline
bash scripts/lint-shell.sh --strict         # add the optional strict checks
bash scripts/lint-shell.sh --format         # shfmt -w first, then lint
bash scripts/lint-shell.sh path/to/one.sh   # a specific file
```

It detects shell scripts by `.sh` extension **or** shebang, so the extensionless
`plugins/srepowers-core/hooks/session-start` is covered.

### `tests/hooks/`

The SessionStart hook is the bootstrap: it injects `using-srepowers` into every
session. If it breaks, no skill ever auto-triggers, and the failure is silent.

`test-session-start.sh` asserts:

- Claude Code / Codex get the nested `hookSpecificOutput.additionalContext` shape
- Copilot CLI / unknown runtimes get the top-level `additionalContext` shape
- `run-hook.cmd` correctly dispatches to the named script
- The output is valid JSON with no leaked heredoc terminator
- The hook uses `printf`, not `cat <<` — a regression guard for the bash 5.3+
  hang ([upstream #571](https://github.com/obra/superpowers/issues/571))

### `tests/codex/`

Codex packaging invariants that are easy to regress and hard to notice:

- The `SessionStart` matcher is `startup|clear|compact` — **not** `resume`
- Every packaged Codex plugin manifest declares `"hooks": {}`, suppressing
  Codex's auto-discovery of `hooks/hooks.json`

Both are deliberate divergences. Read the README's Codex section before changing
either.

### `tests/claude-code/`

One `test-<skill>.sh` per skill, driving the real `claude` CLI through
`test-helpers.sh` (`run_claude`, `assert_contains`, `assert_order`,
`assert_count`). These verify a skill is discoverable, that its content is
understood, and that ordering constraints hold.

They are slow and cost tokens. Run the specific one you are affecting:

```bash
bash tests/claude-code/test-subagent-driven-operation.sh
```

Because they depend on model output, treat a single failure as a signal to
investigate rather than proof of a regression — re-run before concluding.

**These tests grade the *installed* plugin, not this checkout.** The `claude`
CLI resolves skills from the marketplace copy under
`$CLAUDE_CONFIG_DIR/plugins/marketplaces/srepowers-marketplace`, which is a
separate clone of this repo. Unmerged local work is invisible to them, and a
stale marketplace makes them grade old content — silently, since a stale skill
still answers plausibly.

Before trusting a result, confirm the installed copy matches what you are
testing:

```bash
git -C "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/marketplaces/srepowers-marketplace" \
  log --oneline -1
```

If that SHA is not the commit you want graded, refresh the marketplace
(`/plugin` → Update marketplace) and re-run. Only `scripts/validate-repo.py`
and the offline suites read this checkout directly.

## Testing a Skill You Wrote

The offline suites verify *packaging*. They cannot tell you whether a skill
actually changes behavior. For that, follow
`srepowers-core:writing-skills-sre`:

1. **RED** — run the pressure scenario without the skill; document the failure
   and the rationalizations verbatim
2. **GREEN** — write the minimum guidance that closes it; re-run
3. **REFACTOR** — close new loopholes; re-test

Micro-test wording changes with 5+ reps against a no-guidance control before
spending a full pressure run. See
`plugins/srepowers-core/skills/writing-skills-sre/testing-skills-with-subagents.md`.

## CI

`.github/workflows/validate.yml` runs on every pull request and on pushes to
`main`: repo validation, Codex packaging, the hook test, the linter self-test,
and `lint-shell.sh --all --strict`.

`--all` rather than the default changed-files mode, because a fresh CI checkout
has no useful diff base.
