---
name: git-guardrails
description: Use when you want mechanical, non-bypassable enforcement of git safety rules — a PreToolUse hook that blocks force-push, reset --hard, clean -f, branch -D, checkout ./-f, switch --discard-changes, restore ., worktree remove --force, git add -A/., and --no-verify before they run. Also use to understand, test, or adjust the shipped git guard.
---

# Git Guardrails

## Overview

A **PreToolUse hook** that mechanically blocks destructive git commands before
they execute. Unlike `srepowers-core:safety-validator` (an *advisory* skill the
model chooses to invoke), this guard runs on **every** Bash tool call whether or
not the model remembered to check — it is the enforcement layer, not the advice
layer.

**Core principle:** advice you can skip is not a guardrail. Mechanical
enforcement closes the gap between "I should have validated" and "I did."

**Announce at start:** "The git-guardrails hook is active — destructive git
commands are blocked mechanically."

## Relationship to safety-validator

| | `safety-validator` | `git-guardrails` |
|---|---|---|
| Kind | Advisory skill | PreToolUse hook |
| Fires | When the model invokes it | Every Bash call, automatically |
| Scope | All destructive ops (kubectl, terraform, rm, SQL, PVE, …) | git commands only |
| Bypassable by the model | Yes (can be skipped) | No |

Use them together: `safety-validator` reasons about broad blast radius and
suggests safe alternatives; `git-guardrails` guarantees the specific git
footguns below never slip through.

## What it blocks (and what it allows)

The guard aligns with the SREPowers / user global git guardrails. It blocks the
**irreversible, history-rewriting, and indiscriminate-staging** operations —
and deliberately **allows** the everyday commands the SREPowers workflow needs
(a normal `git push` is how `finishing-operation-branch` ships a branch).

| Blocked (exit 2) | Allowed (exit 0) |
|---|---|
| `git push --force` / `-f` / `--force-with-lease` | `git push`, `git push origin <branch>`, `git push -u` |
| `git reset --hard` | `git reset --soft`, `git reset <path>` |
| `git clean -f` / `-fd` / `-xdf` / `--force` | `git clean -n` (dry-run), `git clean -d` |
| `git branch -D` | `git branch -d` (safe delete), `git branch -a` |
| `git checkout .` / `git checkout -- .` | `git checkout <branch>`, `git checkout -- <file>` |
| `git checkout -f` / `--force` | `git checkout -b <branch>` |
| `git switch --discard-changes` / `-f` / `--force` | `git switch <branch>`, `git switch -c`, `git switch -d` |
| `git restore .` / `git restore --staged .` | `git restore <file>` |
| `git worktree remove --force` / `-f` | `git worktree remove <path>` (refuses if dirty) |
| `git add -A` / `git add .` / `git add --all` | `git add <explicit-file>`, `git add -p` |
| any git command with `--no-verify` | commits/pushes that run the hooks |

Every rule also matches when **global options** sit between `git` and the
subcommand (`git -C <path> reset --hard`, `git -c k=v push -f`,
`git --git-dir=… clean -fd`). A rule's argument span stops at `;`, `&` and
`|`, so `git push origin x && rm -f tmp` is not read as a force-push.

### Mentions are not invocations

Text that only *mentions* a blocked command is allowed. The hook strips
payloads that can never execute before matching:

- quoted arguments of a search (`rg`, `grep`, `egrep`, `fgrep`, `ag`) or of
  `git grep` / `log` / `commit` / `tag` / `notes`, so
  `rg "git reset --hard" docs/` and `git commit -m "never git add -A"` pass;
- heredoc bodies written to a prose file (`.md`, `.markdown`, `.txt`, `.rst`,
  or a `/docs/`, `/memory/`, `/tickets/`, `/runbooks/` path) with no pipe, or
  passed as a message (`git commit -m "$(cat <<'EOF'`, `--body`, `-d`).

Anything that **can** execute is still matched: an `ssh h '…'` or
`bash -c "…"` argument, a double-quoted string containing `$(` or a backtick,
a heredoc fed to a shell, interpreter or script file, or a dangerous command
chained after the search with `;` / `&&`.

### Disposable worktrees

The hook cannot tell a scratch worktree from your real checkout: the working
directory a command runs in is only known at runtime. Instead of resetting
one worktree between experiments, give each scenario its own:

```bash
git worktree add --detach "$W1" origin/<branch>
git -C "$W1" revert --no-edit <sha>...   # on conflict: git -C "$W1" revert --abort
git -C "$W1" diff --stat <base> HEAD
git worktree remove "$W1"                # plain remove; refuses if dirty
```

**Why force-push is blocked but plain push is not:** force-push rewrites remote
history and can destroy a colleague's work; a normal push is the routine, safe
operation the workflow depends on. Blocking all pushes (as some upstream guards
do) would break the toolchain — so this guard blocks only the destructive
variant.

## How it ships

The guard is **bundled with the plugin** and activates on install — there is no
user-settings file to edit and no scope prompt.

- Script: `plugins/srepowers-core/hooks/block-dangerous-git` (extensionless,
  dispatched cross-platform via `run-hook.cmd`, same wrapper as the
  SessionStart hook).
- Wiring: a `PreToolUse` matcher on `Bash` in all three hook configs —
  `plugins/srepowers-core/hooks/hooks.json` (Claude Code),
  `plugins/srepowers-core/hooks.json` (Codex, after plugin install), and the
  repo-dev `.codex/hooks.json`. It shares that matcher with
  `srepowers-core:verification-guardrails`.
- On a blocked command the hook exits `2` and writes a one-line reason to
  stderr; Claude Code's PreToolUse protocol surfaces that as a denial.
- It **fails open**: malformed input, empty stdin, missing `jq`, or a non-git
  command all exit `0`, so a parsing hiccup never wedges every Bash call.

## Testing the guard

Pipe a PreToolUse-shaped JSON event through the script and check the exit code:

```bash
HOOK=plugins/srepowers-core/hooks/block-dangerous-git

# blocked → exit 2, reason on stderr
printf '{"tool_input":{"command":"git push --force origin main"}}' | bash "$HOOK"; echo "exit $?"

# allowed → exit 0, silent
printf '{"tool_input":{"command":"git push origin feat/x"}}' | bash "$HOOK"; echo "exit $?"
```

The full block/allow matrix is asserted in `tests/hooks/test-block-dangerous-git.sh`.

## Adjusting the block set

The blocked patterns live in the `rules` array in the script — each entry is an
extended-regex and a human reason, tab-separated. To add or relax a rule, edit
that array and extend `tests/hooks/test-block-dangerous-git.sh` with the new
block/allow cases. Keep the allowlist honest: every pattern you add must be
tested against the everyday commands it must **not** catch, or you will silently
break the workflow.

## Limitations

- Matches the **command string** with regexes; a sufficiently obfuscated
  command (aliases, variable-built strings, `eval`, a script written to a
  prose-named file and run later) can evade it. It is a safety net, not a
  sandbox.
- **Not covered:** `+refspec` force-pushes (`git push origin +main`),
  `git stash drop` / `clear`, and `git switch -C` / `checkout -B` (resets a
  branch, recoverable from the reflog).
- Guards git only. For destructive non-git operations (kubectl, terraform, rm,
  SQL, PVE), use `srepowers-core:safety-validator`.
- Requires `jq` to parse the event; without `jq` it fails open (allows), so on
  minimal hosts pair it with the advisory skill.
