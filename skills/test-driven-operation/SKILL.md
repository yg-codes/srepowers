---
name: test-driven-operation
description: Use when executing infrastructure operations with verification commands - API calls, kubectl, Keycloak CRDs, Git MRs, Linux server operations
---

# Test-Driven Operation (TDO)

## Overview

Write the verification command first. Run it and watch it fail. Execute minimal operation to pass.

**Core principle:** If you didn't watch the verification fail, you don't know if it verifies the right thing.

**Violating the letter of the rules is violating the spirit of the rules.**

## When to Use

**Always:**
- API operations (REST, GraphQL, gRPC)
- Kubernetes operations (kubectl, helm)
- Keycloak/Identity provider operations (CRDs, admin APIs)
- Git control repo operations (MRs, commits)
- Linux server operations (configuration changes, deployments)
- Database migrations and schema changes
- Infrastructure provisioning (Terraform, CloudFormation)

**Exceptions (ask your human partner):**
- Emergency incident response (time-critical)
- Read-only diagnostic operations
- Dry-run exploration (first pass only)

Thinking "skip TDO just this once"? Stop. That's rationalization.

## The Iron Law

```
NO INFRASTRUCTURE CHANGE WITHOUT A FAILING VERIFICATION FIRST
```

Execute operation before the verification? Rollback. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" verification after the fact
- Rollback means rollback (kubectl delete, git revert, API undo)

Execute fresh from verification. Period.

## Red-Green-Refactor for Operations

```dot
digraph tdo_cycle {
    rankdir=LR;
    red [label="RED\nWrite failing verification", shape=box, style=filled, fillcolor="#ffcccc"];
    verify_red [label="Verify fails\ncorrectly", shape=diamond];
    green [label="GREEN\nMinimal operation", shape=box, style=filled, fillcolor="#ccffcc"];
    verify_green [label="Verify passes\nExpected output", shape=diamond];
    refactor [label="REFACTOR\nDocument and clean", shape=box, style=filled, fillcolor="#ccccff"];
    next [label="Next", shape=ellipse];

    red -> verify_red;
    verify_red -> green [label="yes"];
    verify_red -> red [label="wrong\nfailure"];
    green -> verify_green;
    verify_green -> refactor [label="yes"];
    verify_green -> green [label="no"];
    refactor -> verify_green [label="stay\ngreen"];
    verify_green -> next;
    next -> red;
}
```

### RED - Write Failing Verification

Write one minimal verification showing what should exist or happen.

**Kubernetes:**
```bash
kubectl get pod -n production -l app=api-server -o jsonpath='{.items[0].status.phase}'
```

**API:**
```bash
curl -s https://api.example.com/users/123 | jq '.email'
```

**Keycloak CRD:**
```bash
kubectl get keycloakrealm/example-realm -o jsonpath='{.status.ready}'
```

**Linux server:**
```bash
ssh prod-server "systemctl is-active nginx"
```

**Requirements:**
- One verifiable outcome
- Clear expected result
- Uses real verification commands (no mocks)

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
kubectl get pod -n production -l app=api-server
# Error: No resources found in production namespace
```

Confirm:
- Verification fails (not errors)
- Failure reason is expected (resource doesn't exist)
- Fails because operation not executed (not typos)

**Verification passes?** You're verifying existing state. Fix verification.

**Verification errors?** Fix command, re-run until it fails correctly.

### GREEN - Minimal Operation

Execute simplest operation to pass verification.

**Kubernetes:**
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
spec:
  containers:
  - name: api
    image: api-server:v1.0.0
EOF
```

**API:**
```bash
curl -X PATCH https://api.example.com/users/123 \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'
```

**Git control repo:**
```bash
git add manifests/production/app-config.yaml
git commit -m "Add production database config"
git push
# Wait for ArgoCD/Flux sync
```

Don't add features, refactor other resources, or "improve" beyond the verification.

### Verify GREEN - Watch It Pass

**MANDATORY.**

```bash
kubectl get pod -n production -l app=api-server -o jsonpath='{.items[0].status.phase}'
# Output: Running
```

Confirm:
- Verification passes
- Output matches expected
- No errors in logs/events
- Other resources still healthy

**Verification fails?** Fix operation, not verification.

**Other resources broken?** Fix now.

### REFACTOR - Document and Clean

After green only:
- Document the operation in runbook
- Add to Git commit message
- Extract reusable patterns
- Update DR plans

Keep verification passing. Don't add behavior.

## Good Verifications

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in description? Split it. | `kubectl get pod,svc,configmap` |
| **Clear** | Command describes expected state | `kubectl get all` |
| **Shows intent** | Demonstrates desired outcome | Obscures what operation should achieve |

## Async and Eventual-Consistency Verification

Some operations cannot produce immediate, deterministic results:

| Category | Examples | Strategy |
|----------|----------|----------|
| **Poll-until-ready** | ArgoCD sync, Terraform apply, DNS propagation | Polling loop with timeout |
| **Event-based** | Kafka consumer lag, async job completion | Event log or queue depth query |
| **Baseline-delta** | Route53 propagation, S3 eventual consistency | Before/after comparison with wait |

### Strategy 1: Poll-Until-Ready

```bash
# RED: show condition not met
kubectl get deployment -n production api-server -o jsonpath='{.status.readyReplicas}' 2>&1
# Expected: Error: not found OR 0

# GREEN: execute operation
kubectl apply -f deployment-api-server.yaml

# Verify GREEN: poll with timeout (max 3 minutes)
for i in $(seq 1 18); do
  READY=$(kubectl get deployment -n production api-server -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  [ "$READY" = "3" ] && echo "PASS: readyReplicas=3" && break
  echo "Attempt $i/18: readyReplicas=${READY:-0}, waiting 10s..."
  sleep 10
done
[ "$READY" != "3" ] && echo "FAIL: timed out" && exit 1
```

### Strategy 2: Event-Based Verification

```bash
# RED: show lag is high
kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group my-consumer --describe | awk '{print $6}'
# Expected: 50000

# GREEN: trigger reprocessing

# Verify GREEN: confirm lag reaches 0 within window
END=$((SECONDS + 300))
while [ $SECONDS -lt $END ]; do
  LAG=$(kafka-consumer-groups.sh --bootstrap-server kafka:9092 --group my-consumer --describe | awk 'NR>1{sum+=$6} END{print sum}')
  [ "$LAG" -le "100" ] && echo "PASS: lag=$LAG" && break
  echo "Lag: $LAG, waiting..."
  sleep 15
done
```

### Strategy 3: Baseline-Delta

```bash
# RED: capture baseline
BASELINE=$(dig +short api.example.com @8.8.8.8)
echo "Baseline: '${BASELINE}'"
# Expected: empty or old IP

# GREEN: update DNS

# Verify GREEN: wait for propagation
EXPECTED_IP="203.0.113.42"
END=$((SECONDS + 600))
while [ $SECONDS -lt $END ]; do
  CURRENT=$(dig +short api.example.com @8.8.8.8)
  [ "$CURRENT" = "$EXPECTED_IP" ] && echo "PASS: DNS=$CURRENT" && break
  echo "Current: '${CURRENT}', waiting for $EXPECTED_IP..."
  sleep 30
done
```

### Async TDO Rules

- **Always set a timeout.** No infinite polling. Timeouts are failures.
- **Always log progress.** Each poll prints current state.
- **Watch it fail first.** Run polling loop RED — must time out before operation.
- **Treat timeout as failure.** If loop times out in Verify GREEN, operation failed.
- **Human approval for long waits.** If timeout > 15 minutes, ask before proceeding.

### When TDO Cannot Apply

| Situation | Action |
|-----------|--------|
| Visual inspection required (UI) | Pause TDO. Document human checkpoint. Resume after confirm. |
| Success = absence of alerts over N hours | Document expected alert state, set reminder, close loop later. |
| Cross-system trace required | Use distributed tracing (Jaeger, Tempo) to correlate spans. |
| Legacy system with no query API | Add monitoring/logging first; then run TDO. |

For these: **document the human checkpoint explicitly.** Do not claim automated verification where none exists.

## Why Order Matters

**"I'll verify after to confirm it worked"**

Verifications written after operations pass immediately. Passing immediately proves nothing:
- Might verify wrong thing
- Might verify side effect, not actual change
- You never saw it catch the failure

Verification-first forces you to see the verification fail, proving it actually verifies something.

**"kubectl apply succeeded, that's verification enough"**

kubectl apply succeeding ≠ resource working. Apply only submits manifests.

- `kubectl apply -f deployment.yaml` succeeds (exit 0)
- But: Pods in CrashLoopBackOff, missing ConfigMap, insufficient quota
- Verification: `kubectl get deployment -n production app -o jsonpath='{.status.readyReplicas}'`

Apply success = valid YAML. Verification = working infrastructure.

**"Rolling back X hours of work is wasteful"**

Sunk cost fallacy. The time is already gone. Your choice:
- Rollback and re-execute with TDO (X more hours, high confidence)
- Keep it and verify after (30 min, low confidence, likely issues)

Working changes without verification are technical debt.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to verify" | Simple ops fail. Verification takes 30 seconds. |
| "I'll verify after" | Passing immediately proves nothing. |
| "Already manually checked" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "kubectl apply succeeded" | Apply success ≠ resource ready. |
| "API returned 200" | 200 ≠ correct response body. |
| "Dashboard shows it's up" | Dashboard ≠ verification. Dashboards lag, cache data. |
| "ArgoCD will deploy it" | Verify deployment happened. Sync can fail silently. |
| "The script has checks" | Script output ≠ verification. Read and confirm output. |
| "Production is down, no time" | Verification confirms fix works. Without it, you're guessing. |
| "Rolling back X hours is wasteful" | Sunk cost fallacy. Unverified changes are debt. |
| "TDO is dogmatic, I'm pragmatic" | TDO is pragmatic. Debugging incidents is slower. |

## Red Flags - STOP and Rollback

- Operation before verification
- Verification passes immediately
- Can't explain why verification failed
- Rationalizing "just this once"
- "Keep as reference" or "adapt existing operation"
- "Already spent X hours, rolling back is wasteful"
- "This is different because..."

**All of these mean: Rollback operation. Start over with TDO.**

## SRE Principles

| Principle | What It Means |
|-----------|---------------|
| **Safety First** | Run `--dry-run` between RED and GREEN. Mandatory rollback plan before every GREEN. |
| **Evidence-Driven** | Every verification includes exact command and actual output (not paraphrased). |
| **Audit-Ready** | Record operator, timestamp, ticket in commits. Preserve verification outputs as artifacts. |
| **Communication** | Summarize changes in business-impact terms. Provide escalation context for failures. |

## Verification Checklist

Before marking operation complete:

- [ ] Every operation has a verification command
- [ ] Watched each verification fail before executing operation
- [ ] Each verification failed for expected reason (resource missing, not typo)
- [ ] Executed minimal operation to pass each verification
- [ ] All verifications pass
- [ ] No errors in logs/events
- [ ] Verifications use real commands (no mocks)
- [ ] Documented in runbook/commit message

Can't check all boxes? You skipped TDO. Rollback and start over.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to verify | Write desired end state. Query for it first. Ask your human partner. |
| Verification too complicated | Operation too complicated. Break into smaller ops. |
| Must verify everything manually | Operation not observable. Add metrics/labels. |

## Incident Response Integration

Incident detected? Write failing verification reproducing it. Follow TDO cycle. Verification proves fix and prevents regression.

Never fix incidents without verification.

## Final Rule

```
Infrastructure change → verification exists and failed first
Otherwise → not TDO
```

No exceptions without your human partner's permission.
