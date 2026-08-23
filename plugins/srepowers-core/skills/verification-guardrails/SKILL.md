---
name: verification-guardrails
description: Use when you want mechanical, non-bypassable enforcement of verification discipline — a PreToolUse hook that blocks shell idioms making a gate lie (comm && echo PASS, $? after a pipe, unprivileged globs under sudo, denylisted errors, unmatchable greps), plus an opt-in Stop hook that blocks final messages asserting system state with no read behind them. Also use to understand, test, or adjust either guard.
---

# Verification Guardrails

## Overview

Two hooks that enforce verification discipline mechanically, rather than hoping
the model remembers it. Unlike `srepowers-core:verification-before-completion`
and `srepowers-core:evidence-first-reporting` (*advisory* skills the model
chooses to invoke), `block-lying-gates` runs on **every** Bash tool call whether
or not the model remembered to check.

**Core principle:** a check that cannot fail is worse than no check. It
manufactures confidence at the exact moment an operator decides whether to
cross an irreversible step.

These exist because the prose did not self-apply. The `PIPESTATUS` rule was
written into a runbook template's own conventions section and violated three
steps later *in the same file*. The reporting rule was already written down
when an agent told an operator "the apply never ran" — it had run 20 minutes
earlier; the operator found out when a service broke.

**Announce at start:** "The verification-guardrails hook is active — shell
idioms that make a gate lie are blocked mechanically."

## Relationship to the advisory skills

| | `verification-before-completion` | `verification-guardrails` |
|---|---|---|
| Kind | Advisory skill | PreToolUse hook (+ opt-in Stop hook) |
| Fires | When the model invokes it | Every Bash call, automatically |
| Scope | Whether the work is really done | Whether the *check itself* can lie |
| Bypassable by the model | Yes | No |

Use them together: the advisory skills decide *what* to verify;
`verification-guardrails` guarantees the command you verify **with** is not one
of the known-lying forms.

## Both directions are failures

A gate has two ways to lie, and they are equally damaging:

| | What it does | Why it is damaging |
|---|---|---|
| **Cannot fail** | Reports `PASS` while the condition is broken | Confidence exactly when an irreversible step is being decided |
| **Cannot pass** | Reports `FAIL` on a healthy system | Trains the operator to override the gate guarding that step |

Most guidance defends only against the first. Roughly half the recorded
defects behind this hook were the second — so both are blocked.

## What it blocks (and what it allows)

Every blocked pattern is paired below with the correct form it prescribes. The
allow-column is load-bearing: each pattern is one character away from banning
its own advice, and the test suite asserts every row.

| Blocked (exit 2) | Allowed (exit 0) — the prescribed fix |
|---|---|
| `comm -13 a b && echo PASS` — `comm` exits 0 while printing differences | `NEW=$(comm -13 a b); [ -z "$NEW" ] && echo PASS \|\| echo FAIL` |
| `cmd \| tee f; echo $?` — `$?` is the *last* command's status | `cmd \| tee f; rc=${PIPESTATUS[0]}` |
| `sudo ls /boot/loader/entries/*` — glob expands in the *unprivileged* shell | `sudo bash -c 'shopt -s nullglob; …'` + assert it iterated |
| `grep -v 'Error (1)'` in a gate — denylists the failure it exists to catch | allowlist the success value: `grep -qE 'Error \(0\)'` |
| `grep -q "/uat/"` — a repo pointer *ends* at the token, so this never matches | anchor at end-of-line: `grep -c "/uat$"` |
| `grep -q "Return-Code: Success"` — real output is column-aligned | `grep -qE "Return-Code *: *Success"` |
| `systemctl is-active X \| grep -q active` — matches `activating` | `systemctl is-active --quiet X`, or compare exactly |

**Deliberately not blocked**, because the false-positive cost exceeds the
benefit: `cmd | head` generally (truncating for volume is fine — only the
`$?`-after-pipe form lies), `${VAR:-default}` generally (most uses are display
fallbacks), and `grep -c` without `|| true` (depends on `set -e` being active,
which the hook cannot see from a command string).

Three patterns assume RHEL/dnf/systemd (repo pointer, `Return-Code`,
`is-active`). They are kept because each matches a specific *lying form* rather
than a tool — on a non-RHEL host they simply never fire.

## How it ships

`block-lying-gates` is **bundled and active on install**. There is no settings
file to edit — but "on install" is load-bearing: the guard travels with the
plugin, so a stale or absent marketplace has no guard. See Limitations.

- Script: `plugins/srepowers-core/hooks/block-lying-gates` (extensionless,
  dispatched cross-platform via `run-hook.cmd`, same wrapper as the SessionStart
  and git-guardrails hooks).
- Wiring: a second `PreToolUse` entry on the `Bash` matcher, alongside
  `block-dangerous-git`, in all three hook configs —
  `plugins/srepowers-core/hooks/hooks.json` (Claude Code),
  `plugins/srepowers-core/hooks.json` (Codex, after plugin install), and the
  repo-dev `.codex/hooks.json`.
- On a blocked command it exits `2` and writes the reason, the fix, and the
  offending command to stderr; Claude Code's PreToolUse protocol surfaces that
  as a denial. Each message names **the fix**, not just the ban.
- It **fails open**: malformed input, empty stdin, missing `jq`, or a
  non-matching command all exit `0`, so a parsing hiccup never wedges every
  Bash call.

## Enabling the Stop guard (opt-in)

`block-unsourced-claims` ships with the plugin but is **deliberately wired into
no hooks.json**. Enable it yourself by adding this to your `settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "<plugin-root>/hooks/block-unsourced-claims",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

Replace `<plugin-root>` with the installed plugin path (in Claude Code,
`${CLAUDE_PLUGIN_ROOT}` is only expanded inside a plugin's own hooks.json, so a
user settings file needs the literal path). Remove the block to disable it.

**Why opt-in and not bundled — this is deliberate, not an oversight.** A denied
Bash call costs one retry. A Stop-hook false positive prevents the turn from
finishing at all. The blast radius is asymmetric, so the consent model is too.
Do not "fix the inconsistency" by wiring it into hooks.json.

**What it does:** scans the final message for assertions about system state and
blocks the stop when the turn contains no tool call that could have established
them. Two families, both from the record:

- **Negative claims** — "the apply never ran", "no changes were made". A
  negative needs the same evidence as a positive; an interrupted or rejected
  tool call is not proof the work did not run.
- **Perfect-tense mutations** — "I committed", "I've pushed", "I applied".

It is generous by design: **any** of `Bash`, `Read`, `Grep`, `Glob`, `Edit`,
`Write`, or `NotebookEdit` in the turn clears every claim. The goal is catching
the turn where *nothing* was read, not adjudicating whether the right thing was
read. Quoted spans, fenced code, blockquotes, questions, and explicit hedges
("I have not confirmed X") are all exempt — discussing the defect must not trip
the guard that exists because of it.

## Testing the guards

Pipe a PreToolUse-shaped event through the script and check the exit code:

```bash
HOOK=plugins/srepowers-core/hooks/block-lying-gates

# allowed → exit 0, silent
printf '{"tool_input":{"command":"git status"}}' | bash "$HOOK"; echo "exit $?"
```

To test a *blocked* command, build the payload indirectly. Writing a lying
idiom literally into a shell command trips the live hook on the command line
itself, before your test ever runs:

```bash
C=$(printf 'comm -13 a b %s%s echo PASS' '&' '&')
printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$C" | jq -Rs .)" > /tmp/p.json
rc=0; bash "$HOOK" < /tmp/p.json || rc=$?; echo "want 2, got $rc"
```

Full matrices: `tests/hooks/test-block-lying-gates.sh` (38 cases) and
`tests/hooks/test-block-unsourced-claims.py` (37 cases).

## Adjusting the block set

The patterns live in the `rules` array in `block-lying-gates` — each entry is
an extended-regex, a reason, and a fix, tab-separated. The array carries a
`# shellcheck disable=SC2016` directive because the entries are literals that
must reach `grep` and the operator verbatim.

To add or relax a rule, edit that array and extend
`tests/hooks/test-block-lying-gates.sh` with the new block **and** allow cases.
Keep the allowlist honest: every pattern you add must be tested against the
correct form it prescribes, or the guard will end up banning its own advice —
an earlier `.*&&` version of the `comm` rule blocked exactly the
capture-and-test form the rule tells you to write.

## Limitations

- **The guard lives in the installed marketplace, not in your dotfiles — and its
  absence is silent.** A fresh machine, a new `CLAUDE_CONFIG_DIR`, or a
  marketplace clone predating the release that added it has no
  `block-lying-gates` at all, and nothing announces that. Every other limitation
  below degrades a guard that is at least present; this one removes it. Verify:

  ```bash
  M="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/marketplaces/srepowers-marketplace"
  grep -c block-lying-gates "$M/plugins/srepowers-core/hooks/hooks.json"   # want 1
  ```

  A `0` (or a missing path) means unguarded — refresh with `/plugin` → update
  the marketplace, then re-run. Check this after switching `CLAUDE_CONFIG_DIR`;
  each config dir carries its own marketplace clone at its own revision.
- Matches the **command string** with regexes; an obfuscated command (aliases,
  variable-built strings, `eval`) can evade it. A safety net, not a sandbox.
- Requires `jq`; without it the hook fails open (allows), so on minimal hosts
  pair it with the advisory skills.
- The Stop hook needs `python3` and is invoked directly rather than through
  `run-hook.cmd` (that wrapper `exec bash`s its target). **On Windows it will
  not fire.** The bash hook works everywhere via the wrapper.
- The Stop hook reads Claude Code's JSONL transcript format; on a harness that
  writes a different shape it fails open and guards nothing.
- Neither hook can enforce authoring judgement — whether a gate names a service
  this host actually runs, or whether a post-event probe asserts a fact that
  could only be true afterwards. Run a gate once against the live host while
  writing it.
