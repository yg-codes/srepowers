---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

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

## Infrastructure Operation Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Pod running | `kubectl get pod -n namespace -o jsonpath='{.status.phase}'` shows Running | Pod exists, Deployment ready, "should be up" |
| Config applied | `kubectl get configmap -n namespace name -o jsonpath='{.data.key}'` shows value | Git committed, ArgoCD synced, "should deploy" |
| API works | `curl -f http://endpoint/health` returns 200 with expected body | API returns 200, "looks correct", swagger says valid |
| Git MR created | `glab mr list` shows MR with correct source/target | Push succeeded, "MR should exist", git log shows commit |
| Keycloak realm ready | `kubectl get keycloakrealm/realm -o jsonpath='{.status.ready}'` is true | CR applied, "Keycloak should reconcile", realm exists |
| Server provisioned | `ssh server "hostname"` returns expected hostname | Cloud API says running, IP assigned, "accessible" |
| Service healthy | `kubectl get endpoints -n namespace service -o jsonpath='{.subsets[*].addresses[*].ip}'` shows IPs | Service exists, pods running, "should work" |
| Database migrated | Migration table shows version N, schema reflects changes | Migration script ran, "no errors", exit code 0 |
| User created | `keycloakadm get users/count` increased, `get users` shows user | API returned 201, "user should exist" |
| RBAC applied | `kubectl auth can-i --as=sa:service-account namespace/resource` returns yes | RoleBinding exists, "permissions granted" |

## Red Flags - STOP

- Using "should", "probably", "seems to", "looks like"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/create MR without verification
- Trusting subagent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "kubectl apply succeeded" | Apply succeeded ≠ resource ready |
| "API returned 200" | 200 ≠ correct response body |
| "Subagent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |
| "ArgoCD will deploy it" | Verify deployment actually happened |
| "Dashboard shows it's up" | Dashboard ≠ verification command |
| "Already checked manually" | Manual ≠ systematic, no record |

## Key Patterns

**Pod/Deployment status:**
```
✅ [kubectl get pod -n namespace pod-name] [See: Running] "Pod is running"
❌ "Should be running" / "Deployment looks good"
```

**ConfigMap/Secret applied:**
```
✅ [kubectl get configmap -n namespace name -o jsonpath='{.data.VERSION}'] [See: v1.2.3] "Config applied with version v1.2.3"
❌ "Git committed" / "ArgoCD synced"
```

**API health:**
```
✅ [curl -f http://endpoint/health] [See: {"status":"healthy"}] "API is healthy"
❌ "API is responding" / "Looks good"
```

**Git MR/PR created:**
```
✅ [glab mr list --source_branch cu_feature] [See: 1 MR] "MR created and ready for review"
❌ "Push succeeded" / "MR should exist"
```

**Service endpoints:**
```
✅ [kubectl get endpoints -n namespace service] [See: IPs] "Service has endpoints"
❌ "Service exists" / "Pods are running"
```

**Database migration:**
```
✅ [psql -c "SELECT version FROM schema_migrations"] [See: 20250209] "Migration 20250209 applied"
❌ "Migration script ran" / "No errors in output"
```

## Why This Matters

From infrastructure operations failures:
- Claimed "deployment successful" but pods never started - production down
- Claimed "config applied" but ArgoCD failed to sync - stale config in production
- Claimed "API works" but returned wrong data - client integration broken
- Claimed "MR created" but push failed - no code review, bad code merged
- Claimed "Keycloak realm ready" but CRD reconciliation failed - authentication broken
- Claimed "RBAC applied" but permissions denied - service couldn't access resources
- Time wasted on false completion → failed operations → incidents
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about operation state
- Committing to control repo, MR/PR creation, task completion
- Moving to next operation
- Delegating to subagents
- Closing incident tickets

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Infrastructure-Specific Verification Commands

### Kubernetes Operations
- **Pods:** `kubectl get pod -n namespace name -o jsonpath='{.status.phase}'`
- **Deployments:** `kubectl get deployment -n namespace name -o jsonpath='{.status.readyReplicas}'`
- **Services:** `kubectl get endpoints -n namespace service -o jsonpath='{.subsets[*].addresses[*].ip}'`
- **ConfigMaps:** `kubectl get configmap -n namespace name -o jsonpath='{.data.KEY}'`
- **Secrets:** `kubectl get secret -n namespace name -o jsonpath='{.data.KEY}' | base64 -d`
- **CRDs:** `kubectl get <crd-type>/name -o jsonpath='{.status.ready}'` or `'{.status.phase}'`

### API Operations
- **Health checks:** `curl -f http://endpoint/health` or `curl -f http://endpoint/healthz`
- **Specific resource:** `curl -s https://api.example.com/resource/123 | jq '.field'`
- **Authentication:** `curl -f -H "Authorization: Bearer $TOKEN" https://api.example.com/me`

### Git Operations
- **MR created:** `glab mr list --source_branch feature_branch` (GitLab)
- **PR created:** `gh pr list --head feature_branch` (GitHub)
- **Commit pushed:** `git log origin/main..HEAD --oneline` (show local commits not on remote)
- **Branch merged:** `git branch -r --merged main` (show branches merged to main)

### Keycloak Operations
- **Realm ready:** `kubectl get keycloakrealm/realm -o jsonpath='{.status.ready}'`
- **Client exists:** `kubectl get keycloakclient/client -o jsonpath='{.spec.clientId}'`
- **User count:** `keycloakadm get users/count`

### Linux Server Operations
- **Service running:** `ssh server "systemctl is-active service-name"`
- **Package installed:** `ssh server "dpkg -l | grep package-name"`
- **Port listening:** `ssh server "ss -tlnp | grep :port"`

### Database Operations
- **Migration applied:** `psql -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"`
- **Table exists:** `psql -c "\dt table_name"`
- **Row count:** `psql -c "SELECT COUNT(*) FROM table_name"`

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
