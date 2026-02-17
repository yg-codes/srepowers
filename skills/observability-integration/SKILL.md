---
name: observability-integration
description: Use when verifying infrastructure operations using metrics and alerting data from Prometheus, Grafana, or other observability platforms - for pre/post operation metric comparison and alert validation
---

# Observability Integration

## Overview

Integrate metrics, logs, and alerting data into operational workflows to verify infrastructure changes using objective data rather than just command output.

**Core principle:** Metrics don't lie - use observability data to verify operations and detect issues early.

**Announce at start:** "I'm using the observability-integration skill to verify this operation using metrics data."

## When to Use

**Use this skill when:**
- Verifying performance impact of changes
- Confirming service health after deployment
- Investigating incidents with metrics correlation
- Setting up monitoring for new services
- Validating SLOs after infrastructure changes

**Pairs with:**
- `test-driven-operation` - Add metric verification to TDO cycles
- `systematic-troubleshooting` - Use metrics for root cause analysis
- `monitoring-expert` - Deep monitoring configuration

## The Process

### Step 1: Establish Baseline Metrics

Before any operation, capture current state:

```bash
# Prometheus query examples

# Request rate
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total[5m])" | jq

# Error rate
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~'5..'}[5m])" | jq

# Latency percentiles
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.99,rate(http_request_duration_seconds_bucket[5m]))" | jq

# Resource utilization
curl -s "http://prometheus:9090/api/v1/query?query=container_memory_usage_bytes" | jq
```

**Document baseline:**
```markdown
## Metric Baseline (Pre-Operation)

| Metric | Current Value | Threshold | Status |
|--------|---------------|-----------|--------|
| Request Rate | 1,200 req/s | N/A | ✅ |
| Error Rate | 0.1% | < 1% | ✅ |
| p99 Latency | 45ms | < 100ms | ✅ |
| CPU Usage | 45% | < 80% | ✅ |
| Memory Usage | 60% | < 85% | ✅ |
```

### Step 2: Define Expected Changes

Based on the operation, predict metric changes:

| Operation | Expected Metric Change |
|-----------|----------------------|
| Scale up | Request rate capacity ↑, CPU usage may ↑ |
| Add caching | Latency ↓, cache hit rate ↑ |
| Database optimization | Query latency ↓, connection pool usage ↓ |
| New feature | Request rate ↑, error rate stable |

### Step 3: Execute Operation with Metric Monitoring

During operation execution, monitor key metrics:

```bash
# Watch metrics in real-time (every 10 seconds)
while true; do
  echo "=== $(date) ==="
  curl -s "http://prometheus:9090/api/v1/query?query=up" | jq '.data.result[] | .metric.instance, .value[1]'
  sleep 10
done
```

### Step 4: Post-Operation Metric Comparison

After operation, compare to baseline:

```bash
# Query same metrics as baseline
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total[5m])" | jq
```

**Comparison template:**
```markdown
## Metric Comparison (Post-Operation)

| Metric | Before | After | Change | Expected? | Status |
|--------|--------|-------|--------|-----------|--------|
| Request Rate | 1,200 | 1,200 | 0% | Stable | ✅ |
| Error Rate | 0.1% | 0.1% | 0% | Stable | ✅ |
| p99 Latency | 45ms | 32ms | -29% | ↓ | ✅ |
| CPU Usage | 45% | 38% | -15% | ↓ | ✅ |
| Memory Usage | 60% | 62% | +3% | Stable | ✅ |

**Verdict**: Operation successful, all metrics within expected ranges.
```

### Step 5: Alert Validation

Check for new or resolved alerts:

```bash
# Check Alertmanager

# Active alerts
curl -s "http://alertmanager:9093/api/v1/alerts" | jq '.data[] | .labels.alertname, .labels.severity, .status.state'

# Silences (should be none for new operation)
curl -s "http://alertmanager:9093/api/v1/silences" | jq
```

**Alert status:**
| Alert | Before | After | Expected | Status |
|-------|--------|-------|----------|--------|
| HighLatency | FIRING | RESOLVED | Resolved | ✅ |
| HighErrorRate | RESOLVED | RESOLVED | Stable | ✅ |
| PodCrashLoop | FIRING | FIRING | Still firing | ❌ |

## Metric Queries by Use Case

### Service Health Verification

```promql
# Service availability
up{job="api-server"}

# Request rate
rate(http_requests_total{job="api-server"}[5m])

# Error rate
rate(http_requests_total{job="api-server",status=~"5.."}[5m])
/ rate(http_requests_total{job="api-server"}[5m])

# Latency percentiles
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket{job="api-server"}[5m]))
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job="api-server"}[5m]))
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{job="api-server"}[5m]))
```

### Resource Utilization

```promql
# CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Memory usage
container_memory_usage_bytes / container_spec_memory_limit_bytes

# Disk usage
node_filesystem_avail_bytes / node_filesystem_size_bytes

# Network I/O
rate(container_network_receive_bytes_total[5m])
rate(container_network_transmit_bytes_total[5m])
```

### Kubernetes-Specific

```promql
# Pod status
kube_pod_status_phase{phase="Running"}

# Container restarts
kube_pod_container_status_restarts_total

# Resource requests vs limits
kube_pod_container_resource_requests
kube_pod_container_resource_limits

# Persistent volume usage
kubelet_volume_stats_available_bytes / kubelet_volume_stats_capacity_bytes
```

## Integration with TDO

Add metric verification to Test-Driven Operation cycles:

### RED Phase (Enhanced)
```bash
# Traditional verification
kubectl get pod -n production -l app=api-server

# Add metric baseline
echo "=== Metric Baseline ==="
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}" | jq
```

### GREEN Phase (Enhanced)
```bash
# Execute operation
kubectl apply -f api-server-deployment.yaml

# Watch metrics during rollout
kubectl rollout status deployment/api-server -n production

# Verify metrics healthy
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}" | jq
```

### Verify GREEN Phase (Enhanced)
```bash
# Traditional verification
kubectl get pod -n production -l app=api-server

# Metric verification
echo "=== Metric Verification ==="
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}" | jq
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{job='api-server'}[5m])" | jq
```

## SRE Principles

### Safety First
- Always capture baseline before changes
- Set metric thresholds for automatic rollback
- Monitor error rates during deployments

### Structured Output
- Present metric comparisons in tables
- Show before/after with percentage changes
- Include threshold status

### Evidence-Driven
- Use actual metric values, not impressions
- Query Prometheus directly for evidence
- Include query timestamps for audit trail

### Audit-Ready
- Record baseline queries and results
- Document expected metric changes
- Preserve post-operation comparisons

### Communication
- Translate metric changes to business impact
- Report "p99 latency improved by 30%" not just "metrics look good"
- Explain what metrics mean for users

## Common Mistakes

### Not capturing baseline
- **Problem**: Can't prove improvement or detect regression
- **Fix**: Always query metrics before operation

### Wrong time ranges
- **Problem**: Comparing 1m rate to 5m rate shows false changes
- **Fix**: Use consistent time ranges

### Ignoring counter resets
- **Problem**: Rate() on reset counters shows spikes
- **Fix**: Use increase() or rate() with proper handling

### Alert fatigue blindness
- **Problem**: Ignoring alerts because "they're always firing"
- **Fix**: Investigate every alert during operation window

## Integration

**Pairs with:**
- `test-driven-operation` - Add metric verification to TDO
- `systematic-troubleshooting` - Use metrics for incident analysis
- `monitoring-expert` - Configure metrics and alerts
- `executing-operation-plans` - Metric checkpoints between batches

**Called by:**
- Any operation where metric verification adds confidence
- Performance-related changes
- Capacity changes (scaling)
