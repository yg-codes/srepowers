# Test-Driven Operation Anti-Patterns

**Load this reference when:** writing verification commands, handling eventual consistency, testing rollbacks, or dealing with flaky infrastructure tests.

## Overview

Verification commands must check real infrastructure state, not just command success. Operations have different challenges than unit tests.

**Core principle:** Verify the operation achieved the desired state, not just that the command ran.

**Following strict TDO prevents these anti-patterns.**

## The Iron Laws

```
1. NEVER trust command success as verification
2. NEVER ignore eventual consistency
3. NEVER skip rollback verification
4. NEVER assume infrastructure is ready immediately
```

## Anti-Pattern 1: Command Success = Success

**The violation:**
```bash
# ❌ BAD: Assuming apply success means ready
kubectl apply -f deployment.yaml
# Exit code 0 - but is it actually working?

# ❌ BAD: Same with Terraform
terraform apply -auto-approve
# "Apply complete!" - but resources may be failing
```

**Why this is wrong:**
- `kubectl apply` only validates YAML syntax
- Pod may be in CrashLoopBackOff
- Missing ConfigMap, insufficient quota, wrong image
- Terraform apply doesn't wait for health checks

**Your correction:** "Did we verify the actual state or just the command output?"

**The fix:**
```bash
# ✅ GOOD: Verify actual resource state
kubectl apply -f deployment.yaml

# Wait for rollout
kubectl rollout status deployment/my-app -n production

# Verify specific state
kubectl get deployment my-app -n production -o jsonpath='{.status.readyReplicas}'
# Expected: 3

# Check pod status
kubectl get pods -n production -l app=my-app -o jsonpath='{.items[*].status.phase}'
# Expected: Running Running Running

# Verify application health (if health endpoint available)
curl -s http://my-app.production.svc.cluster.local/healthz
# Expected: 200 OK
```

### Gate Function

```
BEFORE claiming operation complete:
  Ask: "Did I verify the actual state or just command success?"

  IF only checked command exit code:
    STOP - Run verification command that checks state

  Ask: "What would prove this is actually working?"

  Run that verification command
  Confirm output matches expected
```

## Anti-Pattern 2: Ignoring Eventual Consistency

**The violation:**
```bash
# ❌ BAD: Checking immediately after apply
kubectl apply -f keycloak-realm.yaml
kubectl get keycloakrealm my-realm -o jsonpath='{.status.ready}'
# Output: <no value> - check too early
```

**Why this is wrong:**
- Controllers need time to reconcile
- CRD status updates asynchronously
- Checking too early gives false negative
- Declaring failure before reconciliation completes

**The fix:**
```bash
# ✅ GOOD: Wait for condition with timeout
kubectl apply -f keycloak-realm.yaml

# Wait for reconciliation (with reasonable timeout)
kubectl wait --for=condition=Ready keycloakrealm/my-realm --timeout=120s

# Or poll with condition check
for i in {1..30}; do
  status=$(kubectl get keycloakrealm my-realm -o jsonpath='{.status.ready}' 2>/dev/null)
  if [ "$status" = "true" ]; then
    echo "Realm is ready"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 5
done
```

### Gate Function

```
BEFORE verifying CRD or controller-managed resources:
  Ask: "Is this resource eventually consistent?"

  IF yes (CRDs, controllers, operators):
    Use kubectl wait OR poll with timeout
    Don't check immediately after apply

  Ask: "What's the reasonable timeout for this operation?"

  Document the wait time in runbook
```

## Anti-Pattern 3: Testing Idempotency Wrong

**The violation:**
```bash
# ❌ BAD: Testing idempotency by checking if command succeeds twice
kubectl apply -f configmap.yaml
kubectl apply -f configmap.yaml  # Should succeed
# But did anything unexpected change?
```

**Why this is wrong:**
- Second apply may succeed but change resourceVersion
- Some fields may be reset to defaults
- Annotations/labels may be modified
- Doesn't prove true idempotency

**The fix:**
```bash
# ✅ GOOD: Verify state is identical after re-apply

# First apply
kubectl apply -f configmap.yaml
kubectl get configmap my-config -o yaml > first-apply.yaml

# Second apply
kubectl apply -f configmap.yaml
kubectl get configmap my-config -o yaml > second-apply.yaml

# Compare (ignoring managed fields and resourceVersion)
diff <(yq eval 'del(.metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields)' first-apply.yaml) \
     <(yq eval 'del(.metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields)' second-apply.yaml)
# Expected: No difference
```

## Anti-Pattern 4: Skip Rollback Testing

**The violation:**
```bash
# ❌ BAD: Documenting rollback but never testing it
# Rollback: kubectl delete -f deployment.yaml
# (Never actually verified this works)
```

**Why this is wrong:**
- Rollback may fail due to dependencies
- Finalizers may block deletion
- Data loss may occur in unexpected ways
- During incident, untested rollback adds stress

**The fix:**
```bash
# ✅ GOOD: Test rollback in non-production first

# Apply the change
kubectl apply -f deployment.yaml
kubectl rollout status deployment/my-app

# Verify it's working
curl -s http://my-app/healthz  # 200 OK

# Test rollback
kubectl delete -f deployment.yaml
# OR: kubectl rollout undo deployment/my-app

# Verify rollback succeeded
kubectl get deployment my-app  # Should be gone or previous version

# Verify no orphaned resources
kubectl get pods -n production -l app=my-app  # Should be empty or old version

# Document any issues found during test
```

### Gate Function

```
BEFORE marking operation as production-ready:
  Ask: "Have I tested the rollback procedure?"

  IF no:
    STOP - Test rollback in non-production environment
    Document any issues or special steps needed

  Ask: "What could prevent rollback from working?"

  Check: Finalizers, dependencies, data consistency
```

## Anti-Pattern 5: Hardcoded Timeouts

**The violation:**
```bash
# ❌ BAD: Arbitrary sleep
kubectl apply -f deployment.yaml
sleep 30  # "Should be enough"
kubectl get pods
```

**Why this is wrong:**
- 30 seconds may be too short (slow image pull)
- 30 seconds may be too long (fast operation)
- Wastes time OR causes flaky failures
- Doesn't adapt to actual conditions

**The fix:**
```bash
# ✅ GOOD: Condition-based waiting
kubectl apply -f deployment.yaml

# Wait for specific condition
kubectl rollout status deployment/my-app --timeout=5m

# Or custom condition loop
kubectl wait --for=condition=Available deployment/my-app --timeout=5m

# For CRDs: poll until condition met
until kubectl get crd my-resources.example.com -o jsonpath='{.status.conditions[?(@.type=="Established")].status}' | grep True; do
  echo "Waiting for CRD to be established..."
  sleep 2
done
```

## Anti-Pattern 6: Environment-Specific Verification

**The violation:**
```bash
# ❌ BAD: Verification that works in sit but not production
kubectl get pods -n sit -l app=my-app
# Works in sit

kubectl get pods -n production -l app=my-app
# Fails in production (different labels, permissions)
```

**Why this is wrong:**
- sit and production may differ in structure
- Labels, namespaces, resource names may vary
- Verification must match target environment
- Copy-paste from docs without adaptation

**The fix:**
```bash
# ✅ GOOD: Parameterize verification by environment
NAMESPACE=${TARGET_ENV:-sit}
APP_NAME=my-app

# Verification works in any environment
kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME"

# Or detect from context
NAMESPACE=$(kubectl config view --minify -o jsonpath='{..namespace}')
```

## Anti-Pattern 7: External State Assumptions

**The violation:**
```bash
# ❌ BAD: Assuming external service state
kubectl apply -f config-with-db-credentials.yaml
# Assumes DB exists and is accessible
# Verification passes locally but fails in real environment
```

**Why this is wrong:**
- External dependencies may not exist
- Network policies may block connectivity
- Credentials may be wrong
- Verification must check dependencies

**The fix:**
```bash
# ✅ GOOD: Verify dependencies first

# Check if DB is reachable
kubectl exec -it deployment/my-app -n production -- nc -zv db-host 5432

# Apply config
kubectl apply -f config-with-db-credentials.yaml

# Verify app can connect (via logs or health check)
kubectl logs -n production -l app=my-app | grep "Database connection established"
```

## Anti-Pattern 8: Ignoring Test Flakiness

**The violation:**
```bash
# ❌ BAD: "Sometimes it fails, just run it again"
kubectl apply -f deployment.yaml
sleep 10
kubectl get pods
# Occasionally fails, re-run usually works
```

**Why this is wrong:**
- Flakiness indicates race condition or timing issue
- Re-running masks real problems
- Production may hit the same race condition
- Trust in verification erodes

**The fix:**
```bash
# ✅ GOOD: Identify and fix root cause of flakiness

# Instead of sleep, use proper waiting
kubectl apply -f deployment.yaml
kubectl wait --for=condition=Available deployment/my-app --timeout=2m

# If still flaky, investigate:
# - Are you checking too early? (eventual consistency)
# - Is there a race condition in the controller?
# - Does the pod restart before ready?

# Add retry logic with proper conditions
for attempt in 1 2 3; do
  if kubectl rollout status deployment/my-app --timeout=30s; then
    break
  fi
  echo "Attempt $attempt failed, retrying..."
  sleep 5
done
```

## Anti-Pattern 9: Incomplete Verification

**The violation:**
```bash
# ❌ BAD: Checking pod exists but not health
kubectl get pod my-app-12345 -n production
# Pod exists

# But is it ready? Is it passing health checks?
# Is it serving traffic correctly?
```

**Why this is wrong:**
- Pod existing ≠ Pod working
- Container may be running but app failing
- Health checks may be failing
- Not serving actual traffic

**The fix:**
```bash
# ✅ GOOD: Multi-layer verification

# Layer 1: Pod exists and is ready
kubectl get pod my-app-12345 -n production -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'
# Expected: True

# Layer 2: Container started
kubectl get pod my-app-12345 -n production -o jsonpath='{.status.containerStatuses[0].started}'
# Expected: true

# Layer 3: Application health (if health endpoint)
kubectl exec -n production my-app-12345 -- wget -qO- http://localhost:8080/healthz
# Expected: OK

# Layer 4: Service responds via ingress (if applicable)
curl -s https://my-app.example.com/healthz
# Expected: 200 OK
```

## Anti-Pattern 10: Verification as Afterthought

**The violation:**
```
✅ Operation complete
❌ No verification run
"Ready for production"
```

**Why this is wrong:**
- Verification is part of the operation, not optional
- TDO would have caught this
- Can't claim complete without verification
- Production incidents from unverified changes

**The fix:**
```
TDO cycle:
1. Define verification command (RED)
2. Run it and watch it fail when the target state is absent or broken, or capture baseline when failure is not meaningful
3. Execute operation (GREEN)
4. Run verification and confirm the target state
5. Document and clean up (REFACTOR)
6. THEN claim complete
```

## TDO Prevents These Anti-Patterns

**Why TDO helps:**
1. **Write verification first** → Forces thinking about what "working" means
2. **Watch it fail** → Confirms verification checks the right thing
3. **Minimal operation** → Only what's needed to pass verification
4. **Real verification** → Must check actual state, not just command output

**If you're trusting command success, you violated TDO** - you skipped verification.

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Command success = success | Verify actual resource state |
| Ignoring eventual consistency | Use kubectl wait or polling with timeout |
| Testing idempotency wrong | Compare state before/after re-apply |
| Skip rollback testing | Test rollback procedure in non-production |
| Hardcoded timeouts | Use condition-based waiting |
| Environment-specific verification | Parameterize by environment |
| External state assumptions | Verify dependencies first |
| Ignoring flakiness | Fix root cause with proper waiting |
| Incomplete verification | Multi-layer verification (pod → container → app → service) |
| Verification as afterthought | TDO - verification first |

## Red Flags

- "Exit code 0, must be working"
- Arbitrary `sleep` commands
- "It usually works, just run it again"
- No rollback procedure tested
- Verification that only works in one environment
- Checking only that resource exists
- Skipping verification "to save time"
- "The apply succeeded, that's enough"

## The Bottom Line

**Verification commands prove the infrastructure is in the desired state, not that commands ran successfully.**

If TDO reveals you're only checking command output, you've gone wrong.

Fix: Write verification that checks actual state, run it, watch it pass.
