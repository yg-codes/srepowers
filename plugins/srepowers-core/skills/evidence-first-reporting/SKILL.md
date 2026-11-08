---
name: evidence-first-reporting
description: Use when reporting infrastructure findings, status updates, investigation results, or handoffs — separates what was observed from what is inferred. Also use for "write a status report", "summarize findings", "what did we find", "report on this investigation", "handoff notes", or when presenting conclusions that need clear evidence trails.
---

# Evidence-First Reporting

## Overview

Infrastructure work fails twice when the reporting is sloppy: first in the system, then in the handoff. This skill makes status updates audit-ready by separating what was observed from what is inferred.

**Core principle:** Observations first, inferences labeled, unknowns preserved.

**Announce at start:** "I'm using the evidence-first-reporting skill to keep observations, inference, and next checks separate."

## When to Use

Use this skill for:

- Incident updates
- Investigation summaries
- Operator handoffs
- Validation summaries after changes
- Read-only reviews where conclusions depend on command output
- Any message that could otherwise overstate certainty

Use it especially when:

- Evidence is partial or fresh data is still pending
- Multiple hypotheses remain plausible
- You are summarizing another agent's work
- A stakeholder needs a precise status without false confidence
- **You are writing up a full health check, resource audit, or cluster review** —
  these read like confident conclusions but rest on inference. Invoking this
  skill is not optional for audit findings; **the `Unknowns` section is the whole
  point** — it forces you to name what you asserted ("likely stranded on node X")
  but never proved, and the exact command that would close each gap. An audit
  report with no `Unknowns` is almost always hiding them.

**Invoke, do not paraphrase.** This is a mandatory gate. When the trigger fires,
call the Skill and use its Output Contract — do not "apply the principles inline"
from memory. Inline imitation reliably drops the `Unknowns` and `Next
Verification` sections, which are exactly the parts that prevent overconfidence.

## Output Contract

Use this structure unless the user explicitly asks for a different format:

```markdown
Status: [observed / inferred / blocked / verified]

Observed:
- [Directly seen output, state, diff, or timestamped fact]

Inference:
- [Interpretation drawn from the observations]

Unknowns:
- [What is not yet proved]

Next Verification:
- [Exact command or check that would reduce uncertainty]

Risk / Blast Radius:
- [What could still be affected]
```

## Rules

- Label direct observation as `Observed`
- Label interpretation as `Inference`
- Keep `Unknowns` explicit instead of hiding them
- Prefer exact commands, diffs, timestamps, and resource names
- Treat stale output as stale; do not present it as current state
- If the claim is "fixed", "healthy", or "complete", route through `verification-before-completion`

## Pre-delivery scan

Three mechanical checks before a report leaves your hands. Each is a defect a
reader cannot fix themselves, and each survives a careful read because the prose
around it looks finished:

- **Every fenced block carries a language tag.** Use `text` when the content is
  generic output. An untagged fence renders inconsistently and breaks the
  copy-paste the reader needs most.
- **No placeholders survive.** `TODO`, `TBD`, `FIXME`, `{{...}}`, lorem ipsum.
  A shipped placeholder reads as a fact nobody checked.
- **Counts are digits, not words.** "3 nodes", never "three nodes" — a single
  numeral form keeps counts greppable and sortable across a report set.
  Ordinals and idioms ("one of the", "second attempt") are not counts.

These apply to the prose you write. Inside a fence or an inline code span, a
bare timestamp or a `<placeholder>` is *content* — quoted command output and
log lines are never findings.

For timestamps, route through `srepowers-core:tzstamp`: dual-stamp as
`2026-03-30 15:43 UTC = 2026-03-31 00:43 JST` rather than writing a bare
local time.

## Attribution Claims: the direct-evidence test

An attribution — "host X sent that traffic", "operator Y made this change", "the
deploy caused the spike", "no data was lost" — is the one claim type where
`Inference` labeling is not enough, because attribution is what gets acted on.
Naming the wrong cause sends the next person to the wrong system.

**A claim is `Observed` only when a logged event shows this exact actor
performing this exact action, in the action's own time window.** Everything
weaker is `Inference` and must be labeled so, even when it is the only
explanation you have.

| Basis for the claim | Classification |
|---|---|
| The actor's own identity appears in the log performing the action | `Observed` |
| Who *recently* used the credential, role, or host — a different window than the action | `Inference` — recent use is not the earlier actor |
| A name pattern (session name, hostname convention, generated identifier) used to name a *person* | `Inference` — a convention is derived and forgeable, not a resolved identity |
| Timing correlation, analogy to a similar past case, "the only actor with access" | `Inference` |
| A negative — "no impact", "nothing was dropped", "read-only" | `Inference`, and it must state its detection-coverage limit |
| Relabeling an earlier `Inference` as `Observed` with no new evidence cited | `Inference` — a relabel is not evidence |

Two rules this imposes on the report:

- **Coverage before naming.** If the action predates the retention window of the
  log you queried, that source has not been exhausted — say so, and name the
  source that *would* cover the window, or record "source unavailable". An
  attribution made outside its own time window is unsupported.
- **No buried caveat.** An `Inference` attribution may not be the headline
  answer with its caveat demoted to a later line. The label travels with the
  claim at the point it is stated.

> **Worked example — recent use is not the actor.** A triage draft led with
> "changed by operator A — high confidence", based on A being the only principal
> to assume the deploy role inside the log's retention window. But the resource
> was created months earlier, before that retention began. Querying the archive
> covering the creation window showed a different session entirely; A's activity
> was a later re-deploy. Confirming who recently used the role is not confirming
> who performed the original action — and even the archive finding is `Observed`
> only for the *session*, not for the human behind it.

## Anti-Patterns

Never:

- Present inference as fact
- Claim root cause from one signal
- Say "looks good" without the proving command
- Use exit code alone as proof of system state
- Collapse contradictory evidence into a single confident sentence
- Omit blast radius when reporting a risky or incomplete change
- Name an actor from correlation, naming convention, or recent unrelated activity
- State a negative ("no impact") without saying what would have detected it

## Examples

### Good

```markdown
Status: inferred

Observed:
- `kubectl --context prod get pods -n api` shows 3/3 pods Running at 14:22 UTC
- `curl -sSf https://api.example.com/healthz` returned 200 at 14:23 UTC

Inference:
- The service appears healthy after the rollout

Unknowns:
- Error budget impact over the last 15 minutes has not been checked

Next Verification:
- `sum(rate(http_requests_total{status=~"5..",service="api"}[15m]))`

Risk / Blast Radius:
- Adjacent consumers have not been re-verified yet
```

### Bad

```markdown
Deployment fixed. Everything is healthy now.
```

## Integration

Pairs with:

- `systematic-troubleshooting` for investigation summaries
- `verification-before-completion` for final claims
- `subagent-driven-operation` for operator and reviewer reports
- `incident-commander` for stakeholder updates
