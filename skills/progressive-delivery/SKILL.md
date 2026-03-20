---
name: progressive-delivery
description: Use when deploying services with canary releases, blue-green deployments, or shadow traffic requiring progressive traffic shifting with rollback triggers
---

# Progressive Delivery

## Overview

Progressive delivery shifts traffic incrementally with SLO-based rollback triggers. Unlike a full deployment (all-or-nothing), progressive delivery validates each traffic stage before proceeding.

**Core principle:** Verification at each traffic stage. Rollback trigger defined before traffic shifts. Never advance without SLO confirmation.

**Announce at start:** "I'm using the progressive-delivery skill to guide this canary/blue-green deployment."

## When to Use

**Use this skill when:**
- Canary deployments (5% → 25% → 50% → 100% traffic)
- Blue-green deployments (switch traffic between two identical environments)
- Shadow/mirror traffic (duplicate traffic to new version, compare responses)
- Feature flag progressive rollouts
- Any deployment requiring staged traffic shifting

**Pairs with:**
- `test-driven-operation` — TDO for infrastructure changes before traffic shifting
- `observability-integration` — Metrics baseline and per-stage SLO validation
- `sre-engineer` — SLO definitions and error budget management

## Deployment Strategies

### Strategy 1: Canary Release

Route small percentage of traffic to new version. Validate. Increase. Repeat.

```
Production traffic: 100% → v1
                          ↓
Stage 1:   95% → v1 │  5% → v2     [validate 15 min]
Stage 2:   75% → v1 │ 25% → v2     [validate 30 min]
Stage 3:   50% → v1 │ 50% → v2     [validate 30 min]
Stage 4:    0% → v1 │100% → v2     [validate 30 min]
```

### Strategy 2: Blue-Green

Two identical environments. Switch traffic 0% → 100% at once, but with immediate rollback path.

```
Blue (current):  100% traffic → v1
Green (new):       0% traffic → v2  [validate green in isolation]
                         ↓
Switch:          100% traffic → v2  [validate, keep blue for 30 min rollback]
```

### Strategy 3: Shadow / Mirror Traffic

Duplicate 100% of requests to new version. Compare responses. No user impact.

```
Production → v1  (serves users)
           → v2  (receives copy, responses discarded)
                 [compare response bodies, latency, error rates]
```

## The Progressive Delivery TDO Cycle

Each traffic stage is a TDO cycle:

### Pre-Deployment: Establish Baseline

Before any traffic shifting:

```bash
# Capture SLO baseline (run observability-integration skill)
echo "=== SLO Baseline ==="
# Error rate (last 30 min)
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[30m])/rate(http_requests_total[30m])" | jq '.data.result[0].value[1]'

# p99 latency
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket[30m]))" | jq '.data.result[0].value[1]'

# Request rate
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total[5m])" | jq '.data.result[0].value[1]'
```

**Document baseline:**

| Metric | Baseline Value | SLO Target | Rollback Trigger |
|--------|----------------|------------|-----------------|
| Error rate | 0.1% | < 1% | > 2% for 5 min |
| p99 latency | 45ms | < 200ms | > 400ms for 5 min |
| Request rate | 1,200 req/s | N/A (reference) | Drop > 20% |

**Set rollback triggers BEFORE any traffic shift.**

### Stage Verification Template (Per Traffic Stage)

**RED — define what "this stage healthy" looks like:**

```bash
# Verification: canary error rate must be < rollback_trigger
# This will fail before canary receives traffic (no canary metrics yet)
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{version='v2',status=~'5..'}[5m])/rate(http_requests_total{version='v2'}[5m])" \
  | jq -e '.data.result[0].value[1] | tonumber < 0.02' 2>&1
# Expected failure: null or parse error (no canary traffic yet)
```

**GREEN — shift traffic:**

**Kubernetes / Argo Rollouts (canary):**

```bash
kubectl argo rollouts set weight canary-deployment 5
kubectl argo rollouts status canary-deployment --watch --timeout 2m
```

**Nginx / Ingress weight annotation:**

```bash
kubectl annotate ingress api-ingress \
  nginx.ingress.kubernetes.io/canary-weight=5 --overwrite
```

**Istio VirtualService:**

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: api-vs
spec:
  http:
  - route:
    - destination:
        host: api-v1
      weight: 95
    - destination:
        host: api-v2
      weight: 5
```

**Verify GREEN — validate SLOs at this stage:**

```bash
# Wait for traffic to stabilize (2-5 min)
sleep 120

echo "=== Stage Validation: 5% canary ==="

# 1. Canary error rate within threshold
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{version='v2',status=~'5..'}[5m])/rate(http_requests_total{version='v2'}[5m])" \
  | jq -r '.data.result[0].value[1] // "0"')
echo "Canary error rate: ${ERROR_RATE} (threshold: 0.02)"

# 2. Canary p99 latency within threshold
P99=$(curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{version='v2'}[5m]))" \
  | jq -r '.data.result[0].value[1] // "0"')
echo "Canary p99 latency: ${P99}s (threshold: 0.4s)"

# 3. Stable request baseline (no traffic drop)
RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total[5m])" | jq -r '.data.result[0].value[1]')
echo "Total request rate: ${RATE} req/s (baseline: 1200)"
```

**Stage result table:**

| Stage | Traffic % | Error Rate | p99 Latency | Rate | Decision |
|-------|-----------|------------|-------------|------|----------|
| Baseline | 0% | 0.1% | 45ms | 1200 | ✅ |
| Stage 1 | 5% | ? | ? | ? | pending |

### Rollback Trigger — Automatic Check

Before advancing to next stage, run:

```bash
ERROR=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{version='v2',status=~'5..'}[5m])/rate(http_requests_total{version='v2'}[5m])" \
  | jq -r '.data.result[0].value[1] // "0"')

P99=$(curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket{version='v2'}[5m]))" \
  | jq -r '.data.result[0].value[1] // "0"')

python3 -c "
error=float('${ERROR}'); p99=float('${P99}')
if error > 0.02: print('ROLLBACK: error rate too high:', error)
elif p99 > 0.4: print('ROLLBACK: p99 too high:', p99)
else: print('ADVANCE: all SLOs healthy')
"
```

If `ROLLBACK` output:

```bash
# Argo Rollouts
kubectl argo rollouts abort canary-deployment
kubectl argo rollouts undo canary-deployment

# Ingress weight
kubectl annotate ingress api-ingress \
  nginx.ingress.kubernetes.io/canary-weight=0 --overwrite

# Istio
kubectl apply -f virtualservice-100pct-v1.yaml
```

## Blue-Green Workflow

### Step 1: Deploy to Green (no traffic)

```bash
# RED: green deployment does not exist / is not ready
kubectl get deployment api-green -n production -o jsonpath='{.status.readyReplicas}'
# Expected: Error or 0

# GREEN: deploy green stack
kubectl apply -f deployment-api-green.yaml

# Verify GREEN: green is ready, serving 0% traffic
kubectl rollout status deployment/api-green -n production
kubectl get deployment api-green -n production -o jsonpath='{.status.readyReplicas}'
# Expected: N (desired replica count)
```

### Step 2: Validate Green in Isolation

```bash
# Direct traffic to green via internal service (bypasses load balancer)
GREEN_URL="http://api-green.production.svc.cluster.local"
curl -s "${GREEN_URL}/health" | jq '.status'
# Expected: "ok"

# Smoke test: verify key endpoints respond correctly on green
echo "=== Green smoke tests ==="
curl -sf "${GREEN_URL}/health" -o /dev/null && echo "PASS: /health" || echo "FAIL: /health"
curl -sf "${GREEN_URL}/ready" -o /dev/null && echo "PASS: /ready" || echo "FAIL: /ready"
# Add application-specific endpoint checks here
# curl -sf "${GREEN_URL}/api/v1/status" | jq '.version' | grep -q "v2" && echo "PASS: version" || echo "FAIL: version"
```

### Step 3: Switch Traffic

```bash
# RED: production service points to blue (v1)
kubectl get service api -n production -o jsonpath='{.spec.selector.version}'
# Expected: v1

# GREEN: switch selector to green (v2)
kubectl patch service api -n production \
  -p '{"spec":{"selector":{"version":"v2"}}}'

# Verify GREEN: service selector updated, requests flowing to green
kubectl get service api -n production -o jsonpath='{.spec.selector.version}'
# Expected: v2

# Validate SLOs using observability-integration skill
sleep 120
echo "=== Post-switch SLO validation ==="
ERROR_RATE=$(curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])/rate(http_requests_total[5m])" \
  | jq -r '.data.result[0].value[1] // "0"')
P99=$(curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket[5m]))" \
  | jq -r '.data.result[0].value[1] // "0"')
echo "Error rate: ${ERROR_RATE} (SLO: < 0.01)"
echo "p99 latency: ${P99}s (SLO: < 0.2)"
python3 -c "
error=float('${ERROR_RATE}'); p99=float('${P99}')
if error > 0.02 or p99 > 0.4: print('WARNING: SLOs degraded after switch — consider rollback')
else: print('PASS: SLOs healthy after traffic switch')
"
```

### Step 4: Keep Blue for Rollback Window (30 min)

```bash
# Blue remains deployed but receives 0% traffic
# Monitor for 30 minutes before decommissioning
echo "Blue deployment kept for rollback. Decommission after: $(date -d '+30 minutes')"

# Rollback command (if needed within window):
# kubectl patch service api -n production -p '{"spec":{"selector":{"version":"v1"}}}'
```

## Shadow Traffic Workflow

```bash
# Deploy shadow service (receives copy of all requests)
kubectl apply -f deployment-api-shadow.yaml

# Configure Istio mirroring
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: api-vs
spec:
  http:
  - route:
    - destination:
        host: api-v1
      weight: 100
    mirror:
      host: api-v2
    mirrorPercentage:
      value: 100
EOF

# Compare response bodies (requires shadow logging)
# Run for 30-60 minutes, then compare:
kubectl logs -l app=api-v2 -n production | grep "SHADOW_DIFF" | head -20
```

## Stage Decision Matrix

| Stage SLO Status | Decision |
|-----------------|----------|
| All SLOs healthy, stable for required window | ✅ Advance to next stage |
| SLO breached once, recovered | ⚠️ Extend observation window by 15 min |
| SLO breached > 2x | 🔴 Rollback immediately |
| SLO breached, rollback trigger sustained | 🔴 Rollback immediately, incident declared |

## SRE Principles

### Safety First
- Define rollback triggers BEFORE first traffic shift
- Keep previous version running until post-deployment window passes
- Phase structure: **Baseline** → **Stage N** (shift, validate, decide) → **Complete or Rollback**

### Structured Output
- Present each stage result as table: Stage | Traffic % | Error Rate | p99 | Decision
- Show rollback trigger thresholds alongside actual values
- Document go/no-go decision at each stage

### Evidence-Driven
- All stage decisions based on metric queries, not intuition
- Include exact Prometheus query output in stage validation
- Reference error budget impact of rollback vs advance

### Audit-Ready
- Record each stage transition with timestamp and metric values
- Document who approved traffic advance at each stage
- Preserve rollback command alongside every deployment step

### Communication
- Summarize deployment progress as: "Stage 2 of 4 complete: 25% traffic on v2, error rate 0.08% (SLO: <1%), p99 42ms (SLO: <200ms)"
- Alert stakeholders if rollback triggered: what failed, customer impact, ETA for re-deploy

## Common Mistakes

### Advancing without SLO validation
- **Problem**: Traffic moved to next stage before metrics stabilized
- **Fix**: Always wait minimum observation window before advancing

### Rollback trigger undefined
- **Problem**: Incident during canary, no clear threshold for rollback
- **Fix**: Define numeric rollback triggers in the operation plan before deployment

### Blue-green without smoke test on green
- **Problem**: Switched traffic to broken green, full outage
- **Fix**: Always validate green in isolation before traffic switch

### Ignoring baseline drift
- **Problem**: Comparing canary metrics to stale baseline
- **Fix**: Capture baseline within 30 minutes of deployment start
