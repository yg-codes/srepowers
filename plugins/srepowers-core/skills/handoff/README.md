# handoff

Captures in-flight work into a self-contained, per-task handoff file so a
fresh session — or a different agent — can continue it cold. Verifies live
repo state before writing, redacts secrets, pins branch/HEAD/timestamp for
staleness detection, and separates observed evidence from conversation
claims. Ships as `srepowers-core:handoff`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Stop mid-task at a context limit or end of day; resume in a fresh session
- Pass work to another agent (Claude Code ↔ pi ↔ Codex) with zero shared context
- Hand over in-flight infrastructure work: environment, applied changes,
  monitoring, backups, rollback, pending approvals
- Keep task state out of `CLAUDE.md`/`AGENTS.md` — instruction memory never
  holds ephemeral state

## How-to

Say "handoff", "hand off this work", or "continue this in a new session".
The skill verifies `git branch`/`HEAD`/`status`/`diff --stat`/`stash list`/
`remote -v` live, redacts credentials from captured URLs, then writes
`docs/handoffs/YYYY-MM-DD-<slug>.md` (or `tickets/<ID>/HANDOFF.md` for
ticketed work). Untracked files are listed explicitly — `git diff` alone
misses them. The receiving session's first act is to re-run the identity
commands and compare before acting.

## Handoff file vs live handover tools

Two different layers that compose; they are not alternatives for the same
job. A live handover tool — e.g. the `pi-intercom` extension's `handover`
action between pi sessions on one machine — transports an auto-generated
summary to a session that acts immediately:

| | This skill | Live handover tool |
|---|---|---|
| Layer | Prose discipline → durable file | Runtime IPC between live sessions |
| Receiver | Any agent, any harness, any time later | A live session on the same machine, acting now |
| Persistence | In-repo file; survives reboots, committable | Message delivered once into the receiver's context |
| Discipline | Verify-first, redaction, identity pinning, `UNVERIFIED` labels | None built in — the auto-summary is unverified recall |

Routing rule of thumb: receiver is **live on this machine and should act
now** → live handover; receiver **doesn't exist yet, is a different tool, or
is later in time** → handoff file.

The strongest pattern is the chain: write the handoff file first, then
deliver its one-line continuation prompt ("read `<path>`, verify the identity
block, proceed") through the live channel — durable artifact + immediate
delivery + redaction discipline. Don't let secrets ride in a live handover's
auto-summary; it has no redaction rule.

Neither mechanism transfers authority: a handoff — file or message —
carries context, not approvals. The `SKILL.md` stays tool-agnostic on
purpose; harness-specific routing like this section belongs in project
docs, not in the portable skill text.

## Verify

Fixture: `evals/fixtures/handoff/fixture-continuation.yaml` — run with
`srepowers-core:skill-test-runner`. It asserts identity pinning, credential
redaction, untracked-file visibility, `UNVERIFIED` labeling of unevidenced
claims, and a concrete first next action.

## Provenance

Consolidated port (5.32.0): [espennilsen/pi](https://github.com/espennilsen/pi)
`handoff` as the foundation (MIT), with aspect-scoping and cold-reader
guardrails from [Codagent-AI/agent-skills](https://github.com/Codagent-AI/agent-skills)
`handoff` (MIT) and the decision-capture format from
[ebaumel/claude-wrapup](https://github.com/ebaumel/claude-wrapup) `wrapup` (MIT).
What was folded and what was refused is recorded in RELEASE-NOTES 5.32.0.
