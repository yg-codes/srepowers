# Infrastructure Operation Testing Anti-Patterns

## Overview

This document catalogs common testing pitfalls in infrastructure operations, why they fail, and the correct Test-Driven Operation (TDO) approach to avoid them.

## Anti-Patterns

### 1. Trusting "kubectl succeeded" Without Checking Pod Status

**What it looks like:**
```bash
kubectl apply -f deployment.yaml
# Output: deployment.apps/app-deployment created
# Claim: "Deployment successful"
```

**Why it fails:**
- `kubectl apply` succeeding only means YAML was valid and accepted by API server
- Pods may fail to start (CrashLoopBackOff, ImagePullBackOff, Insufficient resources)
- ConfigMaps referenced by deployment may not exist
- The deployment may never become ready

**Correct approach (TDO):**
```bash
# RED - Write verification first
kubectl get deployment -n production app-deployment -o jsonpath='{.status.readyReplicas}'
# Expected: Error: not found

# GREEN - Apply deployment
kubectl apply -f deployment.yaml

# Verify GREEN - Confirm deployment is ready
kubectl get deployment -n production app-deployment -o jsonpath='{.status.readyReplicas}'
# Expected: 3 (or your replica count)
```

### 2. Assuming API Works Without curl/Health Check

**What it looks like:**
```bash
curl -X POST https://api.example.com/users -d '{"name":"Test"}'
# Output: {"id": 123}
# Claim: "API is working"
```

**Why it fails:**
- API returning 200 doesn't mean response body is correct
- POST may succeed but GET may fail
- Response may contain wrong data structure
- Authentication may work but authorization may fail

**Correct approach (TDO):**
```bash
# RED - Write verification first
curl -s https://api.example.com/users/123 | jq '.email'
# Expected: null or error

# GREEN - Create user
curl -X POST https://api.example.com/users -d '{"name":"Test User","email":"test@example.com"}'

# Verify GREEN - Confirm user was created with correct data
curl -s https://api.example.com/users/123 | jq '.email'
# Expected: "test@example.com"
```

### 3. Confirmed "MR Created" Without Checking Pipeline

**What it looks like:**
```bash
git push origin cu_add_feature
# Output: branch 'cu_add_feature' set up to track 'origin/cu_add_feature'
# Claim: "MR created and ready"
```

**Why it fails:**
- Push succeeding ≠ MR created
- CI pipeline may fail (tests, linting, security scans)
- MR may have merge conflicts
- Pipeline may be pending for hours

**Correct approach (TDO):**
```bash
# RED - Write verification first
glab mr list --source_branch cu_add_feature
# Expected: (no output or error)

# GREEN - Push branch
git push origin cu_add_feature

# Verify GREEN - Confirm MR exists and pipeline passed
glab mr list --source_branch cu_add_feature
# Expected: Shows MR with pipeline status

# Additional verification - check pipeline status
glab ci view --branch cu_add_feature
# Expected: Pipeline passed
```

### 4. Manual Verification as "Good Enough"

**What it looks like:**
```bash
kubectl get pods -n production
# Output: All pods look Running
# Claim: "Deployment successful, I checked manually"
```

**Why it fails:**
- Manual checks are ad-hoc and inconsistent
- No record of what was verified
- Can't re-run when infrastructure changes
- Easy to forget checks under pressure
- Manual "looks good" misses container restarts, partial readiness

**Correct approach (TDO):**
```bash
# RED - Write verification (automated)
kubectl get pods -n production -l app=myapp --field-selector=status.phase=Running | wc -l
# Expected: 0 (no running pods)

# GREEN - Apply deployment
kubectl apply -f deployment.yaml

# Verify GREEN - Automated verification with count
kubectl get pods -n production -l app=myapp --field-selector=status.phase=Running | wc -l
# Expected: 3 (exact replica count)
```

### 5. Dashboard Checks Without Command Evidence

**What it looks like:**
```bash
# (User checks Grafana dashboard)
# Claim: "All systems healthy, dashboard looks green"
```

**Why it fails:**
- Dashboards lag behind actual state (caching, polling intervals)
- Dashboard may show stale data
- No audit trail of what was checked
- Can't automate dashboard checks
- Dashboard may be down or showing wrong data

**Correct approach (TDO):**
```bash
# RED - Write verification (command, not dashboard)
kubectl get endpoints -n production api-service -o jsonpath='{.subsets[*].addresses[*].ip}'
# Expected: (empty or error)

# GREEN - Apply service
kubectl apply -f service.yaml

# Verify GREEN - Command-based verification
kubectl get endpoints -n production api-service -o jsonpath='{.subsets[*].addresses[*].ip}'
# Expected: Shows actual IP addresses
```

### 6. Verification Before Operation (No Baseline)

**What it looks like:**
```bash
# Already ran the operation
kubectl get pod -n production app-pod
# Output: Running
# Claim: "Verified: pod is running"
```

**Why it fails:**
- Verification passing immediately proves nothing
- Might verify wrong thing (pod name, label, namespace)
- Might verify side effect, not actual change
- You never saw it catch the failure
- Can't confirm verification actually checks what you think it does

**Correct approach (TDO):**
```bash
# RED - Write verification FIRST, watch it fail
kubectl get pod -n production app-pod -o jsonpath='{.status.phase}'
# Expected: Error: not found

# Confirm it failed for correct reason (not typo, but missing)
# This proves verification actually checks for pod existence

# GREEN - Create pod
kubectl apply -f pod.yaml

# Verify GREEN - Now verification passes
kubectl get pod -n production app-pod -o jsonpath='{.status.phase}'
# Expected: Running
```

### 7. Partial Verification (Checking Only One Aspect)

**What it looks like:**
```bash
kubectl apply -f deployment.yaml
kubectl get deployment -n production app-deployment
# Output: Shows deployment exists
# Claim: "Deployment successful"
```

**Why it fails:**
- Deployment existing ≠ deployment ready
- Replica count may be wrong
- Pods may be in CrashLoopBackOff
- No check of actual service availability

**Correct approach (TDO):**
```bash
# RED - Write comprehensive verification
kubectl get deployment -n production app-deployment -o jsonpath='{.status.readyReplicas}'
# Expected: Error: not found

# GREEN - Apply deployment
kubectl apply -f deployment.yaml

# Verify GREEN - Check multiple aspects
# 1. Ready replicas
kubectl get deployment -n production app-deployment -o jsonpath='{.status.readyReplicas}'
# Expected: 3

# 2. Pod status
kubectl get pods -n production -l app=myapp --field-selector=status.phase=Running | wc -l
# Expected: 3

# 3. Service endpoints
kubectl get endpoints -n production api-service -o jsonpath='{.subsets[*].addresses[*].ip}'
# Expected: Shows IPs
```

### 8. "Should Work" Assertions Without Evidence

**What it looks like:**
```bash
kubectl apply -f configmap.yaml
# Claim: "Config should be applied now"
```

**Why it fails:**
- "Should" is not evidence
- No verification run
- Assumptions are not proof
- Configuration may be invalid, namespace missing, etc.

**Correct approach (TDO):**
```bash
# RED - Write verification
kubectl get configmap -n production app-config -o jsonpath='{.data.VERSION}'
# Expected: Error: not found

# GREEN - Apply config
kubectl apply -f configmap.yaml

# Verify GREEN - Get actual evidence
kubectl get configmap -n production app-config -o jsonpath='{.data.VERSION}'
# Expected: v1.2.3
# Claim: "ConfigMap applied with version v1.2.3 [See: output shows v1.2.3]"
```

## Key Principles

1. **Verification First:** Always write the verification command before executing the operation
2. **Watch It Fail:** Run the verification and confirm it fails for the expected reason
3. **Evidence Required:** Never claim success without running verification and showing output
4. **Comprehensive Checks:** Verify all aspects of the operation, not just one
5. **Automated Commands:** Use commands (kubectl, curl, etc.) not dashboards or manual checks
6. **No Assumptions:** "Should work" is not verification. Run the command.

## Quick Reference

| Anti-Pattern | Correct Approach |
|--------------|-----------------|
| `kubectl apply` succeeded | Verify deployment ready: `kubectl get deployment -o jsonpath='{.status.readyReplicas}'` |
| API returned 200 | Verify response body: `curl -s API | jq '.field'` |
| Push succeeded | Verify MR exists: `glab mr list --source_branch` |
| Manual check | Write automated verification command |
| Dashboard green | Use command-based verification |
| Verification before operation | Write verification FIRST, watch it fail |
| Partial check | Verify all aspects (replicas, pods, endpoints) |
| "Should work" | Run verification, show evidence |

## Related Documentation

- [Test-Driven Operation Skill](../skills/test-driven-operation/SKILL.md)
- [Verification Before Completion Skill](../skills/verification-before-completion/SKILL.md)
- [Persuasion Principles](persuasion-principles.md)
