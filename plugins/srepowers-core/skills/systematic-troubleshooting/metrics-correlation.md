# Metrics Correlation Techniques

## Overview

Metrics provide quantitative evidence for troubleshooting. Correlate metrics across time and services to find patterns.

## Key Metrics to Check

### The RED Method

| Metric | Query Example | Purpose |
|--------|---------------|---------|
| **Rate** | Request rate per second | Throughput, load |
| **Errors** | Error rate percentage | Reliability |
| **Duration** | Request latency (p50, p95, p99) | Performance |

### Resource Metrics

```bash
# Kubernetes resource usage
kubectl top nodes
kubectl top pods --all-namespaces
kubectl top pods -n <namespace> --containers

# Specific pod resource usage
kubectl exec -it <pod> -n <namespace> -- ps aux
kubectl exec -it <pod> -n <namespace> -- df -h
kubectl exec -it <pod> -n <namespace> -- free -m
```

## Prometheus Queries

### Error Rate

```promql
# HTTP 5xx error rate
rate(http_requests_total{status=~"5.."}[5m])

# Error rate as percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# Errors by service
sum by (service) (rate(http_requests_total{status=~"5.."}[5m]))
```

### Latency

```promql
# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Latency by endpoint
histogram_quantile(0.95,
  sum by (le, path) (rate(http_request_duration_seconds_bucket[5m]))
)
```

### Resource Saturation

```promql
# CPU saturation (container throttling)
rate(container_cpu_cfs_throttled_seconds_total[5m])

# Memory saturation
container_memory_working_set_bytes / container_spec_memory_limit_bytes

# Disk saturation
rate(container_fs_writes_bytes_total[5m])
```

## Correlation Patterns

### Time-Based Correlation

1. **Get incident start time from logs**
2. **Query metrics at that time**
3. **Look for step changes**

```
Timeline:
10:00 - Deployment completed
10:05 - Error rate starts climbing (logs)
10:07 - Memory usage spikes (metrics)
10:10 - OOMKilled events begin

Pattern: Memory leak introduced in deployment
```

### Cross-Service Correlation

```promql
# Compare latency across services
# Service A (frontend)
histogram_quantile(0.95, rate(http_request_duration_seconds{service="frontend"}[5m]))

# Service B (backend)
histogram_quantile(0.95, rate(http_request_duration_seconds{service="backend"}[5m]))

# If frontend latency spikes but backend doesn't:
# - Issue is in frontend or between frontend/backend
```

## Dashboards for Troubleshooting

Create/using dashboards showing:

1. **Overview**: Request rate, error rate, latency (all services)
2. **Resource**: CPU, memory, disk, network (per node/pod)
3. **Dependencies**: Database connections, cache hit rate, external API latency
4. **Logs**: Error log volume, log rate

## Common Metric Patterns

| Pattern | Meaning | Investigation |
|---------|---------|---------------|
| Error rate spike | Service failing | Check logs, recent deployments |
| Latency increase + CPU increase | Resource constrained | Check resource limits |
| Latency increase + CPU flat | Waiting on dependency | Check downstream services |
| Memory steady climb | Memory leak | Profile application, check for unreleased resources |
| Memory sudden spike | Load spike or batch job | Check traffic patterns, cron jobs |
| Request rate drop | Traffic not reaching service | Check ingress, load balancer |
