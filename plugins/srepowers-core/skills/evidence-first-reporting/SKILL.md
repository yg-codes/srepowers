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

## Anti-Patterns

Never:

- Present inference as fact
- Claim root cause from one signal
- Say "looks good" without the proving command
- Use exit code alone as proof of system state
- Collapse contradictory evidence into a single confident sentence
- Omit blast radius when reporting a risky or incomplete change

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
