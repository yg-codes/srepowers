---
name: verification-before-completion
description: Use when about to claim infrastructure work is complete, fixed, verified, or healthy - before any commit, PR, or status update
---

# Verification Before Completion

## Overview

Claiming infrastructure work is complete without verification causes incidents, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Infrastructure Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Deployment succeeded | `kubectl rollout status` shows all ready | Helm exit 0, "should be up" |
| Service is healthy | Health endpoint returns 200 + correct response | Pod is Running |
| Config applied | `kubectl get cm/secret -o yaml` shows new value | `kubectl apply` exit 0 |
| Certificate valid | `openssl s_client` or cert expiry checked | Secret created |
| Migration complete | Row count / schema verified | Migration job exit 0 |
| Pipeline passed | CI job logs show green + artifacts | Job queued or "triggered" |
| Bug fixed | Original symptom reproduced and no longer fails | Code changed |
| Rollback complete | Service responding correctly at previous version | Old image tag applied |
| Resource deleted | `kubectl get` returns NotFound | Delete command exit 0 |
| Agent completed task | VCS diff shows expected changes | Agent reports "success" |

## Red Flags — STOP

- Using "should", "probably", "seems to", "looks like"
- Expressing satisfaction before verification ("Done!", "Fixed!", "Deployed!", "All good!")
- About to commit/push/PR/merge without verification
- Trusting agent success reports without independent check
- Relying on command exit code alone (exit 0 ≠ correct result)
- Thinking "just this once" during an incident
- Tired at end of incident and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Helm exited 0, it's deployed" | Run `kubectl rollout status` |
| "I'm confident it's fixed" | Confidence ≠ evidence. Run the check. |
| "Pod is Running" | Running ≠ healthy. Check health endpoint. |
| "Agent said success" | Verify independently with kubectl/git diff |
| "I'm tired, incident is over" | Exhaustion ≠ excuse. One more command. |
| "Partial check is enough" | Partial proves nothing. Run the full check. |
| "It worked in staging" | Staging ≠ production. Verify production. |
| "No time during incident" | Unverified fix extends incidents. |

## Key Patterns

**Deployment:**
```
✅ [kubectl rollout status deploy/api -n prod] [See: successfully rolled out] "Deployment succeeded"
❌ "Helm exited 0, deployment done"
```

**Service health:**
```
✅ [curl -s https://api.example.com/healthz] [See: {"status":"ok"}] "Service healthy"
❌ "Pod is Running"
```

**Config/Secret applied:**
```
✅ [kubectl get cm app-config -o jsonpath='{.data.KEY}'] [See: expected-value] "Config applied"
❌ "kubectl apply returned exit 0"
```

**Infrastructure operation (TDO):**
```
✅ [Run verification command from plan] [See: expected output] "Phase complete"
❌ "Commands ran without errors"
```

**Agent delegation:**
```
✅ Agent reports success → [git diff / kubectl get] → Verify changes → Report actual state
❌ Trust agent report at face value
```

## When To Apply

**ALWAYS before:**
- ANY success/completion/healthy claim
- ANY expression of satisfaction
- Committing, PR creation, task completion
- Moving to next step in an operation plan
- Handing off to next skill (e.g., finishing-operation-branch)
- Delegating to subagents and accepting their results
- Closing an incident

**Rule applies to:**
- Exact phrases and paraphrases
- Implications of success
- ANY communication suggesting completion or correctness

## Integration

**Pairs with:**
- **test-driven-operation** — TDO's verification step IS this skill's gate function
- **executing-operation-plans** — Each phase completion requires verification before proceeding
- **finishing-operation-branch** — Branch completion requires all verifications passed
- **incident-commander** — Incident close requires verified service restoration
