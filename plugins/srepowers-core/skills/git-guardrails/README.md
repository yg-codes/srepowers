# git-guardrails

Mechanical, non-bypassable enforcement of git safety rules: a PreToolUse
hook, bundled with the plugin, that blocks destructive git commands —
force-push, `reset --hard`, `clean -f`, `branch -D`, `checkout .` / `-f`,
`switch --discard-changes`, `restore .`, `worktree remove --force`,
`add -A`/`add .`, `--no-verify` — before they execute, on
every Bash call. Ships as `srepowers-core:git-guardrails`. (`SKILL.md`
is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Guarantee the git foot-guns never run, without relying on advisory checks
- Adjust the shipped guard: add or relax a rule in its `rules` array,
  with matching test cases
- Pair with `srepowers-core:safety-validator` for destructive non-git ops

## How-to

Nothing to invoke — the hook activates on plugin install and stays
silent on allowed commands. Probe it manually with a PreToolUse event:

```bash
printf '{"tool_input":{"command":"git push --force origin main"}}' | \
  bash plugins/srepowers-core/hooks/block-dangerous-git   # exit 2, reason on stderr
# a normal push (exit 0, silent) is the negative case — keep it passing
# fails open: malformed input or a missing jq allows the command
```

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (blocked command denied, everyday push allowed). The full
matrix is asserted by `tests/hooks/test-block-dangerous-git.sh`.

## Reference

| Blocked (exit 2) | Allowed (exit 0) |
|------------------|------------------|
| `git push --force` / `-f` / `--force-with-lease` | `git push`, `git push -u` |
| `git reset --hard` | `git reset --soft`, `git reset <path>` |
| `git clean -f` / `-fd` / `-xdf` / `--force` | `git clean -n`, `git clean -d` |
| `git branch -D` | `git branch -d` |
| `git checkout .` / `git restore .` | `git checkout <branch>`, `git restore <file>` |
| `git checkout -f`, `git switch --discard-changes` / `-f` | `git checkout -b`, `git switch -c` / `-d` |
| `git worktree remove --force` | `git worktree remove <path>` |
| `git add -A` / `git add .` | `git add <file>`, `git add -p` |
| any command with `--no-verify` | commits/pushes that run the hooks |

Rules match through global options (`git -C <path> reset --hard`), and
mentions are allowed (`rg "git reset --hard"`, commit messages, heredocs into
`.md`/`.txt`); `SKILL.md` has the exact containment rules.

`SKILL.md` documents the hook wiring, rules-array format, and limitations.

---
Last Updated: 2026-10-21
