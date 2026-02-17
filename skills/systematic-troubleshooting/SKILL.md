---
name: systematic-troubleshooting
description: Use when investigating infrastructure incidents, service outages, performance degradation, or unexpected system behavior - guides 4-phase root cause analysis with log analysis, metrics correlation, and distributed tracing
---

# Systematic Troubleshooting

## Overview

Random restarts and config changes waste time and mask underlying issues. Guessing in production causes incidents.

**Core principle:** ALWAYS find root cause before attempting remediation. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of troubleshooting.**

## The Iron Law

```
NO REMEDIATION WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes or workarounds.

## When to Use

Use for ANY infrastructure issue:
- Service outages
- Performance degradation (high latency, errors)
- Pod crashes or restart loops
- Resource exhaustion (CPU, memory, disk)
- Network connectivity issues
- Configuration drift
- Certificate expiration
- Data inconsistency
- Backup failures

**Use this ESPECIALLY when:**
- Under time pressure (incidents make guessing tempting)
- "Just restart the service" seems obvious
- You've already tried multiple fixes
- Previous fix didn't work
- You don't fully understand the issue
- Multiple services seem affected

**Don't skip when:**
- Issue seems simple (simple symptoms have complex root causes)
- You're in a hurry (rushing guarantees prolonged incidents)
- Manager wants it fixed NOW (systematic is faster than thrashing)
- "It was working before" (find what changed)

## The Four Phases

You MUST complete each phase before proceeding to the next.

### Phase 1: Incident Triage and Data Gathering

**BEFORE attempting ANY remediation:**

#### 1. Establish Incident Timeline

```bash
# When did the issue start?
# Check various sources for first failure timestamp

# Kubernetes events (last hour, filtered)
kubectl get events --sort-by='.lastTimestamp' --all-namespaces | tail -50

# Application logs (grep for ERROR/FATAL)
kubectl logs -n <namespace> -l app=<app-name> --since=1h | grep -iE "error|fatal|exception"

# Infrastructure metrics (if available)
# Check when latency/error rate increased
```

Document:
- **Detection time**: When was the issue first noticed?
- **Start time**: When did the problem actually begin? (often earlier than detection)
- **Trigger**: What changed at that time? (deployments, config changes, traffic patterns)

#### 2. Scope the Impact

```bash
# Which services are affected?
kubectl get pods --all-namespaces -o wide | grep -v Running

# Check resource usage across cluster
kubectl top nodes
kubectl top pods --all-namespaces

# Check for network issues
kubectl get endpoints -n <namespace>
kubectl get svc -n <namespace>
```

Document:
- **Blast radius**: Which services/namespaces/users affected?
- **Severity**: Complete outage vs degraded performance vs single pod
- **Pattern**: All requests failing vs intermittent failures

#### 3. Gather Evidence in Distributed Systems

**WHEN system has multiple components (Ingress → Service → Pod → Container → DB):**

**BEFORE proposing fixes, gather data from each layer:**

```
For EACH component boundary:
  - Check logs at entry and exit points
  - Verify metrics (latency, errors, throughput)
  - Confirm configuration propagation
  - Check resource utilization

Analyze evidence to identify WHICH component is the bottleneck/failure point
THEN investigate that specific component in depth
```

**Layer-by-layer investigation:**

```bash
# Layer 1: Ingress/Load Balancer
kubectl get ingress -n <namespace>
kubectl describe ingress <name> -n <namespace>
# Check external LB logs if applicable

# Layer 2: Service
curl -v http://<service>:<port>/healthz
kubectl get endpoints <service> -n <namespace>
kubectl describe svc <service> -n <namespace>

# Layer 3: Pods
kubectl get pods -n <namespace> -l app=<app>
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # If restarted

# Layer 4: Container
kubectl logs <pod-name> -n <namespace> -c <container>
kubectl exec -it <pod-name> -n <namespace> -- ps aux
kubectl exec -it <pod-name> -n <namespace> -- df -h

# Layer 5: Dependencies (DB, cache, external APIs)
kubectl exec -it <pod-name> -n <namespace> -- nc -zv <db-host> <db-port>
# Check connection pools, query performance
```

**This reveals:** Which layer fails (ingress ✓, service ✓, pod ✗)

#### 4. Check Recent Changes

```bash
# Recent deployments
kubectl rollout history deployment/<name> -n <namespace>
kubectl rollout history deployment/<name> -n <namespace> | grep -A5 "CHANGE-CAUSE"

# Recent config changes
kubectl get configmap <name> -n <namespace> -o yaml | grep -i "resourceVersion"
kubectl get secret <name> -n <namespace> -o yaml | grep -i "resourceVersion"

# Git commits (if using GitOps)
git log --oneline --since="2 hours ago"
git diff HEAD~1 HEAD --name-only

# Infrastructure changes (Terraform)
terraform show | head -100
```

**Key question:** What changed that could cause this?

#### 5. Correlate Logs Across Services

```bash
# Get logs from all related services with timestamps
kubectl logs -n <namespace> -l app=frontend --since=10m | jq -r '.timestamp + " [FRONTEND] " + .message'
kubectl logs -n <namespace> -l app=backend --since=10m | jq -r '.timestamp + " [BACKEND] " + .message'
kubectl logs -n <database-namespace> -l app=postgres --since=10m | tail -20

# Sort by timestamp to see event sequence
cat logs-*.log | sort
```

Look for:
- Cascade failures (one service fails, others follow)
- Timeout patterns
- Error propagation

### Phase 2: Pattern Analysis

**Find the pattern before fixing:**

#### 1. Compare Working vs Failing

```bash
# Find a working pod vs failing pod
kubectl get pods -n <namespace> -o wide

# Compare their states
kubectl describe pod <working-pod> -n <namespace> > working.txt
kubectl describe pod <failing-pod> -n <namespace> > failing.txt
diff working.txt failing.txt

# Compare resource allocation
kubectl get pod <working-pod> -n <namespace> -o jsonpath='{.spec.containers[0].resources}'
kubectl get pod <failing-pod> -n <namespace> -o jsonpath='{.spec.containers[0].resources}'
```

Document differences:
- Node assignment (noisy neighbor?)
- Resource limits
- Environment variables
- Image version

#### 2. Check Historical Patterns

```bash
# Has this happened before?
# Check metrics history if available

# Look at previous pod events
kubectl get events --field-selector reason=Failed --all-namespaces | grep <app-name>

# Check if error is periodic (cron-related, traffic-pattern related)
kubectl logs -n <namespace> -l app=<app> --since=24h | grep -i error | wc -l
```

#### 3. Identify Dependencies

```bash
# What does this service need?
kubectl get deployment <name> -n <namespace> -o yaml | grep -A20 env:

# Check dependency health
kubectl get svc -n <dependency-namespace>
# Check external endpoints
curl -s -o /dev/null -w "%{http_code}" https://api.external-service.com/health
```

Document:
- Upstream dependencies (databases, caches, APIs)
- Downstream consumers
- Network requirements
- Resource requirements

### Phase 3: Hypothesis and Testing

**Scientific method:**

#### 1. Form Single Hypothesis

State clearly: "I think X is the root cause because Y"

Examples:
- "I think the database connection pool is exhausted because logs show 'connection refused' and connection count is at max"
- "I think the liveness probe is misconfigured because pods restart exactly every 30 seconds"

#### 2. Test Minimally

Make the SMALLEST possible change to test hypothesis. One variable at a time.

```bash
# Example: Testing if it's resource limits
# Instead of: Change deployment spec, rollout, wait
# Try: kubectl top pod <name> to confirm resource usage

# Example: Testing if it's config issue
# Instead of: Edit ConfigMap, restart pods
# Try: kubectl get configmap -o yaml | grep <expected-value>

# Example: Testing network connectivity
# Instead of: Change network policies
# Try: kubectl exec -it <pod> -- nc -zv <target> <port>
```

#### 3. Verify Before Continuing

- Did the test confirm your hypothesis? Yes → Phase 4
- Didn't confirm? Form NEW hypothesis
- DON'T add more tests on top

#### 4. When You Don't Know

- Say "I don't understand X"
- Don't pretend to know
- Escalate to team with gathered evidence
- Add more monitoring/logging for next time

### Phase 4: Remediation

**Fix the root cause, not the symptom:**

#### 1. Create Reproduction Verification

Before fixing, ensure you can verify the issue:

```bash
# Document the failing state
kubectl get pods -n <namespace> -o wide > before-fix.txt
kubectl logs <pod> -n <namespace> | tail -20 > before-logs.txt

# If possible, create a test command that shows the issue
curl -s http://<service>/healthz
# Expected: 500 error
```

#### 2. Plan the Fix

Document the planned remediation:

```
Root Cause: <specific cause identified>
Remediation: <specific action>
Rollback Plan: <how to undo if it fails>
Verification: <how to confirm it worked>
```

#### 3. Implement Single Fix

Address the root cause identified:

```bash
# Examples by issue type:

# Resource exhaustion
kubectl set resources deployment/<name> -n <namespace> --limits=memory=512Mi

# Config issue
kubectl edit configmap <name> -n <namespace>
# Or: kubectl apply -f fixed-config.yaml

# Image issue
kubectl set image deployment/<name> <container>=<new-image>:<tag> -n <namespace>

# Scale up for load
kubectl scale deployment/<name> -n <namespace> --replicas=5
```

**ONE change at a time.**
No "while I'm here" improvements.
No bundled changes.

#### 4. Verify Fix

```bash
# Wait for rollout
kubectl rollout status deployment/<name> -n <namespace>

# Verify new pods are healthy
kubectl get pods -n <namespace> -l app=<app>

# Run verification command
curl -s http://<service>/healthz
# Expected: 200 OK

# Check logs for errors
kubectl logs -n <namespace> -l app=<app> --tail=20

# Monitor metrics (if available)
# Check error rate, latency returning to normal
```

**Issue actually resolved?** Confirm with evidence.

#### 5. If Fix Doesn't Work

**STOP.**

Count: How many fixes have you tried?

- If < 3: Return to Phase 1, re-analyze with new information
- **If ≥ 3: STOP and question the architecture**
- DON'T attempt Fix #4 without architectural discussion

#### 6. If 3+ Fixes Failed: Question Architecture

**Pattern indicating architectural problem:**
- Each fix reveals new coupling/problem in different service
- Fixes require changes across multiple services
- Each fix creates new symptoms elsewhere
- Root cause keeps shifting

**STOP and question fundamentals:**
- Is this architecture fundamentally sound?
- Are we adding complexity to workaround bad design?
- Should we refactor vs. continue patching?

**Escalate to architecture review before attempting more fixes.**

This is NOT failed troubleshooting - this indicates technical debt.

## Incident Response Integration

### During Active Incident

**First 5 minutes:**
1. Acknowledge the incident (start timer)
2. Scope impact (Phase 1.2)
3. Gather quick evidence (logs, events)
4. **DO NOT fix yet** - gather data first

**Next 10 minutes:**
1. Complete Phase 1 (timeline, evidence, changes)
2. Begin Phase 2 (pattern analysis)
3. Communicate status to stakeholders

**Before remediation:**
1. Form hypothesis (Phase 3)
2. Document rollback plan
3. Get explicit confirmation for production changes

### Communication Templates

**Initial assessment:**
```
Incident: <brief description>
Start time: <timestamp>
Impact: <services affected>
Severity: <critical/high/medium>
Current status: Investigating
Next update: <time>
```

**Root cause identified:**
```
Root Cause: <specific technical cause>
Impact: <what was affected>
Timeline: <when it started, when detected, when resolved>
Fix: <what was changed>
Verification: <how we confirmed it's fixed>
```

## SRE Principles

### Safety First
- Never remediate without rollback plan documented
- Always test fix in non-production first if possible
- Use gradual rollout (canary) for production fixes
- Require explicit confirmation for production changes

### Structured Output
- Present findings in timeline format
- Use tables for impact assessment (service, status, error rate)
- Document each phase completion before proceeding

### Evidence-Driven
- Include actual log lines, not summaries
- Reference specific pod names, node names, timestamps
- Show metric values (latency p99, error rate %)
- Correlate evidence across services

### Audit-Ready
- Document all commands run during investigation
- Preserve before/after state (kubectl get outputs)
- Record timeline of events
- Link to incident ticket/alert

### Communication
- Lead with impact (services down, users affected)
- Update stakeholders at regular intervals (5-min during active)
- Explain technical findings in business terms
- Provide ETA for resolution (or "investigating, next update in X min")

## Red Flags - STOP and Follow Process

If you catch yourself thinking:
- "Just restart it and see"
- "Scale up to handle the load" (without knowing why load increased)
- "Quick fix for now, investigate later"
- "Add multiple changes, monitor"
- "It's probably X, let me change that"
- "I don't fully understand but this might work"
- "One more restart" (when already tried 2+)
- **Each fix reveals new problem in different service**

**ALL of these mean: STOP. Return to Phase 1.**

**If 3+ fixes failed:** Question the architecture.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Service is down, no time for process" | Systematic troubleshooting is FASTER than random restarts. |
| "Just restart the pod first" | Restarting masks the root cause. It will fail again. |
| "Scale up to handle it" | Scaling fixes symptoms, not causes. Find why load increased. |
| "Roll back the deployment" | Good IF you identified the bad change. Bad if guessing. |
| "It's a known intermittent issue" | Document the pattern, find the trigger. |
| "The error is in the database" | Which query? What changed? Keep investigating. |
| "It's a network issue" | Which hop? What changed? Specifics required. |

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Triage** | Timeline, scope, gather evidence per layer | Know WHEN, WHERE, WHAT failed |
| **2. Pattern** | Compare working/failing, check history | Identify differences and triggers |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Remediation** | Document plan, fix, verify | Root cause resolved |

## Supporting Techniques

See reference files in this directory:

- **`log-analysis.md`** - Structured log parsing and correlation
- **`metrics-correlation.md`** - Using Prometheus/Grafana for root cause
- **`distributed-tracing.md`** - Following requests across services
- **`incident-timeline.md`** - Reconstructing event sequences

## Real-World Impact

From incident response:
- Systematic approach: 15-30 minutes MTTR
- Random restarts approach: 1-3 hours of prolonged outage
- First-time fix rate: 85% vs 30%
- Recurrence rate: Low vs high (same issue returns)

## Integration

**Called by:**
- Any infrastructure skill when issues arise
- Incident response workflows
- Post-deployment verification failures

**Pairs with:**
- **test-driven-operation** - Verify fix with TDO discipline
- **sre-runbook** - Document remediation for future incidents
- **finishing-operation-branch** - When fix requires control repo changes
