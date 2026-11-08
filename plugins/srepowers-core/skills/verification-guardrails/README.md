# verification-guardrails

Mechanical enforcement of verification discipline: a PreToolUse hook
(`block-lying-gates`) that blocks shell idioms making a verification gate
lie — on every Bash call, whether or not the advisory skill was remembered.
Ships as `srepowers-core:verification-guardrails`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Stop gates that cannot fail (`comm … && echo PASS`, `$?` after a pipe) from reporting PASS on a broken condition
- Stop gates that cannot pass (unprivileged `sudo` globs, exact-substring greps) from reporting FAIL on a healthy system
- Opt in to the Stop hook (`block-unsourced-claims`) that blocks final messages asserting system state with no tool call behind them
- Audit or extend the rule set when a new lying idiom shows up in your runbooks

## How-to

Ships bundled and active on install — no settings to edit. A matching
command is denied (exit 2) with the reason **and the prescribed fix** on
stderr. To enable the opt-in Stop guard, wire `hooks/block-unsourced-claims`
into your `settings.json` `Stop` array (exact snippet in SKILL.md).

| Blocked (exit 2) | Prescribed fix |
|------------------|----------------|
| `comm -13 a b && echo PASS` | capture and test the diff: `NEW=$(comm -13 a b); [ -z "$NEW" ] && echo PASS` |
| `cmd \| tee f; echo $?` | `rc=${PIPESTATUS[0]}` |
| `sudo ls /boot/loader/entries/*` | glob inside `sudo bash -c 'shopt -s nullglob; …'`, assert it iterated |
| `grep -v 'Error (1)'` (denylists its own failure) | allowlist the success value: `grep -qE 'Error \(0\)'` |
| `systemctl is-active X \| grep -q active` (matches `activating`) | `systemctl is-active --quiet X` |

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo. The guards also carry their own test matrices:
`tests/hooks/test-block-lying-gates.sh` (48 checks) and
`tests/hooks/test-block-unsourced-claims.py` (37 cases).

## Reference

- `SKILL.md` — every blocked pattern with its fix, prose-containment rules,
  the deliberately-not-blocked list, Stop-hook enablement, how to adjust the
  `rules` array, and limitations (marketplace staleness, `jq` requirement,
  Windows Stop-hook gap)

---
Last Updated: 2026-09-14
