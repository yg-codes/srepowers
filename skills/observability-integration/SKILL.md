---
name: observability-integration
description: Use when verifying infrastructure operations using metrics and alerting data from Prometheus, Grafana, Datadog, CloudWatch, New Relic, or other observability platforms
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
- `observability-engineer` - Deep monitoring configuration

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
kubectl --context <context> get pod -n production -l app=api-server

# Add metric baseline
echo "=== Metric Baseline ==="
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}" | jq
```

### GREEN Phase (Enhanced)
```bash
# Execute operation
kubectl --context <context> apply -f api-server-deployment.yaml

# Watch metrics during rollout
kubectl --context <context> rollout status deployment/api-server -n production

# Verify metrics healthy
curl -s "http://prometheus:9090/api/v1/query?query=up{job='api-server'}" | jq
```

### Verify GREEN Phase (Enhanced)
```bash
# Traditional verification
kubectl --context <context> get pod -n production -l app=api-server

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

## Multi-Stack Observability

The examples above use Prometheus/Grafana. Use the equivalent queries for your observability stack.

### Datadog

```bash
# Requires: DD_API_KEY, DD_APP_KEY environment variables

# Query metric (error rate, last 5 min)
curl -X GET "https://api.datadoghq.com/api/v1/query" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -G --data-urlencode \
  "query=sum:http.requests.error{service:api}.as_count()/sum:http.requests{service:api}.as_count()" \
  --data-urlencode "from=$(date -d '-5 minutes' +%s)" \
  --data-urlencode "to=$(date +%s)" | jq '.series[0].pointlist[-1][1]'

# Query p99 latency
curl -X GET "https://api.datadoghq.com/api/v1/query" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -G --data-urlencode \
  "query=p99:http.request.duration{service:api}" \
  --data-urlencode "from=$(date -d '-5 minutes' +%s)" \
  --data-urlencode "to=$(date +%s)" | jq '.series[0].pointlist[-1][1]'

# Check active monitors (Datadog equivalent of Alertmanager alerts)
curl -X GET "https://api.datadoghq.com/api/v1/monitor" \
  -H "DD-API-KEY: ${DD_API_KEY}" \
  -H "DD-APPLICATION-KEY: ${DD_APP_KEY}" \
  -G --data-urlencode "monitor_tags=service:api" \
  --data-urlencode "with_downtime=false" | \
  jq '.[] | select(.overall_state == "Alert") | {name: .name, state: .overall_state}'
```

### AWS CloudWatch

```bash
# Requires: AWS CLI configured with appropriate IAM permissions

# Query error rate metric
aws cloudwatch get-metric-statistics \
  --namespace "MyApp/API" \
  --metric-name "ErrorRate" \
  --dimensions Name=Service,Value=api \
  --start-time "$(date -u -d '-5 minutes' '+%Y-%m-%dT%H:%M:%SZ')" \
  --end-time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --period 300 \
  --statistics Average \
  --query 'Datapoints[0].Average'

# Query ALB p99 latency (Application Load Balancer)
aws cloudwatch get-metric-statistics \
  --namespace "AWS/ApplicationELB" \
  --metric-name "TargetResponseTime" \
  --dimensions Name=LoadBalancer,Value=app/[LOAD_BALANCER_NAME]/[SUFFIX] \  # replace with actual LoadBalancer dimension from AWS console
  --start-time "$(date -u -d '-5 minutes' '+%Y-%m-%dT%H:%M:%SZ')" \
  --end-time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
  --period 300 \
  --extended-statistics p99 \
  --query 'Datapoints[0].ExtendedStatistics.p99'

# Check CloudWatch alarms in ALARM state
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Reason:StateReason}' \
  --output table
```

### New Relic

```bash
# Requires: NEW_RELIC_API_KEY, NEW_RELIC_ACCOUNT_ID environment variables

# NerdGraph query (New Relic's GraphQL API) — error rate
curl -X POST "https://api.newrelic.com/graphql" \
  -H "Content-Type: application/json" \
  -H "API-Key: ${NEW_RELIC_API_KEY}" \
  -d "{\"query\": \"{ actor { account(id: ${NEW_RELIC_ACCOUNT_ID}) { nrql(query: \\\"SELECT percentage(count(*), WHERE httpResponseCode >= 500) FROM Transaction WHERE appName = 'MyAPI' SINCE 5 MINUTES AGO\\\") { results } } } }\"}" \
  | jq '.data.actor.account.nrql.results[0]["percentage(count(*), WHERE httpResponseCode >= 500)"]'

# p99 latency
curl -X POST "https://api.newrelic.com/graphql" \
  -H "Content-Type: application/json" \
  -H "API-Key: ${NEW_RELIC_API_KEY}" \
  -d "{\"query\": \"{ actor { account(id: ${NEW_RELIC_ACCOUNT_ID}) { nrql(query: \\\"SELECT percentile(duration, 99) FROM Transaction WHERE appName = 'MyAPI' SINCE 5 MINUTES AGO\\\") { results } } } }\"}" \
  | jq '.data.actor.account.nrql.results[0]["percentile.duration.99"]'
```

### Stack-Agnostic Baseline Template

Regardless of your observability stack, capture the same four golden signals before any operation:

```markdown
## Metric Baseline (Pre-Operation) — [Stack Name]

| Signal | Metric Name | Current Value | SLO Target | Rollback Trigger |
|--------|-------------|---------------|------------|-----------------|
| **Errors** | [metric] | [value] | < [threshold] | > [trigger] for [duration] |
| **Latency** | [metric p99] | [value]ms | < [threshold]ms | > [trigger]ms for [duration] |
| **Traffic** | [metric req/s] | [value] | N/A (reference) | Drop > [pct]% |
| **Saturation** | [metric cpu/mem] | [value]% | < [threshold]% | > [trigger]% for [duration] |
```

**Adapt the query tool but keep the same four signals.** If your stack cannot provide one of the four, note it as "not available" and add a rationale.

### Service Mesh Observability (Kiali / Jaeger)

```bash
# Kiali API — service health
curl -s "http://kiali:20001/api/namespaces/production/services/api" \
  -H "Authorization: Bearer $(kubectl --context <context> create token kiali -n istio-system)" | \
  jq '{healthScore: .health.requests.errorRatio, requestRate: .health.requests.requestCount}'

# Jaeger — trace latency percentiles for a service
curl -s "http://jaeger:16686/api/traces?service=api&operation=GET%20/users&limit=100" | \
  jq '[.data[].spans[0].duration] | sort | .[length * 0.99 | floor] / 1000 | . * 100 | round / 100'
# Returns p99 latency in milliseconds
```

## Integration

**Pairs with:**
- `test-driven-operation` - Add metric verification to TDO
- `systematic-troubleshooting` - Use metrics for incident analysis
- `observability-engineer` - Configure metrics and alerts
- `executing-operation-plans` - Metric checkpoints between batches

**Called by:**
- Any operation where metric verification adds confidence
- Performance-related changes
- Capacity changes (scaling)
