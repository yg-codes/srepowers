---
name: handoff
description: Use when ending a session with work in progress that another session or agent must continue — verifies live repo state, redacts secrets, and captures objective, decisions, open questions, and next actions into a per-task handoff file. Also use for "handoff", "hand off", "continue in a new session", "continuation prompt", "capture context for another agent", "session transfer", "pass this to another agent", or "wrap up for a new session". For recording completed work at session end use session-log; for design-to-plan handoff use writing-operation-plans; for the reporting format inside any handoff use evidence-first-reporting.
license: MIT
---

# Handoff — Session Continuation

Write a self-contained handoff file that lets a fresh session — zero prior
context, possibly a different agent — continue in-flight work without
rediscovering it.

**Announce at start:** "I'm using the handoff skill to capture this work for
continuation."

## What a handoff is — and is not

A handoff **preserves context**. It does not preserve *work* (uncommitted
changes stay uncommitted) and it does not transfer *authority* (approvals,
access, or operator consent do not carry to the receiving session).

| A handoff file | Not a handoff file |
|---|---|
| In-flight task state for a cold reader | A record of completed work (→ `session-log`) |
| Evidence-backed current state + decisions | A design document (→ `writing-operation-plans`) |
| Written into the repo, per task | Task state in `CLAUDE.md`/`AGENTS.md` — instruction memory never holds ephemeral task state |

## Step 1 — Verify live state first

**MUST re-fetch repository state immediately before writing.** State read
earlier in the conversation is a hint, not evidence — a handoff built from
conversation memory exports stale-state risk to the next session.

Run from the target repository with Bash, Git and Python 3 available. The
remote pipeline removes URL user-info, query and fragment before tool output —
query/fragment stripping is unconditional; scp-style `user@host:path` remotes
keep host and path with the user token dropped. Anything it cannot classify
is replaced by a fixed placeholder — the capture itself never aborts, and no
unverifiable URL is ever printed:

```bash
set -euo pipefail
git branch --show-current
git rev-parse --short HEAD
git status --short --untracked-files=all
git diff --stat
git diff --cached --stat
git stash list
git log --oneline -5
git remote -v | python3 -c '
import re
import sys
from urllib.parse import urlsplit, urlunsplit

PLACEHOLDER = "<remote omitted: unsafe to display>"
for line in sys.stdin:
    name, value = line.rstrip("\n").split("\t", 1)
    url, direction = value.rsplit(" ", 1)
    try:
        parts = urlsplit(url)
    except ValueError:
        url = PLACEHOLDER
    else:
        if parts.netloc:
            try:
                parts.port
            except ValueError:
                url = PLACEHOLDER
            else:
                host = parts.netloc.rsplit("@", 1)[-1]
                url = urlunsplit((parts.scheme, host, parts.path, "", ""))
        elif parts.scheme == "" and re.match(r"[^/@:]+@[^/@:]+:", parts.path):
            url = parts.path.split("@", 1)[1]
        elif "@" in parts.path:
            url = PLACEHOLDER
        else:
            url = urlunsplit((parts.scheme, "", parts.path, "", ""))
    print(f"{name}\t{url} {direction}")
'
```

**Untracked files are part of the state.** `git diff` omits them and plain
`git status --short` can collapse directories. Name every untracked file
explicitly using `--untracked-files=all`. Capture staged and unstaged diff
statistics separately; neither includes untracked content.

## Step 2 — Redact before output or writing

**MUST NOT expose secrets in tool output or the handoff file.** Redact inside
the command before its output reaches the conversation—not after reading raw
`git remote -v`. Strip secret-bearing URL components as above; preserve the
repository host/path. Do not dump environment variables or command history.
A handoff file is written to be shared and committed—treat it as publishable.

## Step 3 — Capture from the conversation

If the operator named an aspect ("hand off the debugging work"), capture
**that aspect only** — not the whole session. Otherwise capture the current
task.

| Element | Rule |
|---|---|
| **Objective** | The goal, not the history |
| **Current state** | Done / in progress / blocked — anchored to Step 1 evidence |
| **Decisions** | Each with rationale and, where made, rejected alternatives — the reasoning that would otherwise be lost |
| **Open questions** | State the question; **do not prescribe an answer** — that decision belongs to the operator and the next session |
| **Next steps** | The **first** item is one concrete, executable instruction — a command to run or a file to open, never "continue the work" |
| **Key files** | Paths, with why each matters |
| **Gotchas** | Anything surprising or easy to get wrong |

**Evidence discipline.** Any test/check/health claim must carry the command,
the result, and when it ran — otherwise label it `UNVERIFIED` (claimed in
conversation, no captured evidence). Follow `evidence-first-reporting`:
observations first, inference labeled, unknowns preserved.

## Step 4 — Pin identity and time

The file opens with an identity block, so the receiving session can detect
staleness. Use the literal field label `Expected delta:`; put qualifications
such as "when saved" after its colon:

```markdown
## Identity
Repo: <owner/name> (remote URL, redacted)
Branch: <branch> — HEAD <short SHA>
Written: <date, dual-stamped UTC + local — see tzstamp>
Expected delta: <exact handoff-relative path> newly untracked; captured entries unchanged.
```

**Receiving session's first act:** re-run the identity and working-tree
commands and compare against the captured baseline. Only the exact new
handoff path declared in **Expected delta** is an expected addition. A changed
branch/HEAD, altered baseline entry or any other new path requires re-baselining
before acting; do not ignore untracked files wholesale.

## Operations work — add the ops block

For infrastructure changes, also record:

- **Target environment** (cluster, host group, account)
- **Changes actually applied** — vs planned; unambiguous about which is which
- **Monitoring status** — alerts firing/silenced, with silences' expiries
- **Backup/snapshot references** — what exists, where, from when
- **Rollback steps** — copy-pasteable, or "none exists" said explicitly
- **Pending approvals** — what the next session may NOT do without one

**A handoff preserves context; it neither backs up work nor authorizes
production changes.** The receiving session inherits no approvals.

## Step 5 — Write the file

- Default: `docs/handoffs/YYYY-MM-DD-<slug>.md` in the repo.
- Ticketed work: `tickets/<ID>/HANDOFF.md`, beside the plan file.
- Worktree-scoped work: inside that worktree, never the main checkout.
- Always write inside the target repository or worktree. Repositories under
  `$HOME` are allowed; agent configuration/home storage outside that repository
  is not.
- **Never overwrite** an existing handoff; take a new dated slug.
- Uncommitted changes stay uncommitted. If preservation matters, ask the
  operator about a WIP commit or stash — do not mutate unasked.

Show the written path and the file to the operator. The continuation prompt
is one line: *read `<path>`, verify its identity block against live state,
then proceed.*

## Proportionality

- Quick fix → 10–15 lines, at most 200 words
- Multi-file feature → 30–50 lines, at most 500 words
- Major effort → up to ~80 lines, at most 700 words

Build the required identity/evidence, untracked-file inventory and ops block
first. Use one compact baseline list; reference it elsewhere instead of
repeating the same facts as raw output, a table and prose. Fill the remaining
space with context the receiver cannot cheaply recover.

Before delivery, count the saved file with `wc -w`. **Over the cap: trim before
saving** — state each captured fact once (one baseline list; reference it
elsewhere instead of restating it as raw output, a table and prose), and cut
narrative before preservation detail. Rollback, approval boundaries and the
untracked inventory are never what gets cut; if the required inventory or ops
block alone exceeds the cap, say so in the file rather than omitting it.
Fewer newline characters do not make a shorter handoff.

## Template

```markdown
# Handoff: <task>

## Identity
Repo / Branch / HEAD / Written (dual-stamped) — and the receiving-session
verification instruction.
Expected delta: <exact new handoff-relative path>; other captured entries unchanged.

## Objective
<goal, not history>

## Current State
<done / in progress / blocked, anchored to verified state; UNVERIFIED where
claimed but not evidenced>

## Decisions
- <decision> — <rationale> (rejected: <alternative> — <why>)

## Open Questions
- <question, unanswered>

## Next Steps
1. <one concrete first action — command or file>
2. …

## Key Files
- `<path>` — <why it matters>

## Gotchas
- <non-obvious traps; untracked files at risk from git clean>
```

## Anti-Patterns

| Anti-pattern | Why it fails | Do instead |
|---|---|---|
| Handoff from conversation memory only | Exports stale state to the next session | Verify with live commands first (Step 1) |
| Building state from `git diff` alone | Untracked files invisible; `git clean` destroys them | `git status --short --untracked-files=all`; name each file and capture staged/unstaged stats |
| Running raw `git remote -v` | Credentials reach the conversation before later redaction | Redact before tool output (Steps 1–2) |
| No HEAD SHA or timestamp | Receiver cannot detect staleness | Identity block, dual-stamped (Step 4) |
| "Tests pass" with no command/result/time | Unverifiable claim becomes load-bearing | Command + result + time, or `UNVERIFIED` |
| Task state written to `CLAUDE.md` | Ephemeral state pollutes persistent instruction memory | Handoff file only |
| Storage under `~/.agent-skills/`-style paths | Unversioned, invisible to the receiver, collisions | In-repo, per task, dated slug |
| Stashing/committing to "help" | Unrequested mutation; may destroy intent | Describe; ask the operator |
| Answering open questions in the handoff | Pre-decides what the operator must decide | State the question (Step 3) |
| "Continue the refactor" as first step | Not executable by a cold agent | One concrete command or file action |
