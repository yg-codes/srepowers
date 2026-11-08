# Log Analysis Techniques

## Overview

Logs are the primary source of evidence for infrastructure troubleshooting. Structured analysis prevents guesswork.

## Log Collection

### Kubernetes

```bash
# Get logs from specific pod
kubectl logs -n <namespace> <pod-name>

# Get logs from previous container (if crashed/restarted)
kubectl logs -n <namespace> <pod-name> --previous

# Stream logs in real-time
kubectl logs -n <namespace> <pod-name> --follow

# Get logs from all pods matching label
kubectl logs -n <namespace> -l app=<app-name> --all-containers

# Get logs since specific time
kubectl logs -n <namespace> <pod-name> --since=1h
kubectl logs -n <namespace> <pod-name> --since-time="2024-01-15T10:00:00Z"
```

### Multi-Service Aggregation

```bash
# Collect logs from all related services
kubectl logs -n frontend frontend-* --since=30m > frontend.log
kubectl logs -n backend api-* --since=30m > api.log
kubectl logs -n data postgres-* --since=30m > postgres.log

# Sort by timestamp
sort -k1,1 logs-*.log > all-sorted.log
```

## Structured Log Parsing

### JSON Logs

```bash
# Parse structured JSON logs with jq
kubectl logs -n <namespace> <pod> | jq -r 'select(.level=="ERROR") | [.timestamp, .message, .error] | @tsv'

# Count errors by type
kubectl logs -n <namespace> <pod> | jq -r '.error' | sort | uniq -c | sort -rn

# Extract specific fields
kubectl logs -n <namespace> <pod> | jq -r 'select(.http_status >= 500) | [.timestamp, .path, .http_status, .duration_ms] | @tsv'
```

### Plain Text Logs

```bash
# Extract errors with context
grep -B2 -A2 "ERROR\|FATAL\|Exception" app.log

# Count occurrences over time
grep "ERROR" app.log | cut -d' ' -f1 | sort | uniq -c

# Find unique error messages
grep "ERROR" app.log | sed 's/.*ERROR: //' | sort | uniq -c | sort -rn | head -20
```

## Correlation Techniques

### Request Tracing

```bash
# Find a specific request ID through all services
REQUEST_ID="abc-123-xyz"

grep "$REQUEST_ID" frontend.log
grep "$REQUEST_ID" api.log
grep "$REQUEST_ID" postgres.log

# Timeline view
grep -h "$REQUEST_ID" *.log | sort
```

### Error Cascade Detection

```bash
# Look for errors that trigger other errors
grep -n "timeout\|connection refused" service-a.log
grep -n "upstream unavailable" service-b.log
# Check if service-b errors started after service-a errors
```

## Common Log Patterns

| Pattern | Meaning | Next Step |
|---------|---------|-----------|
| `Connection refused` | Target service not listening | Check if target pod is running |
| `Connection timeout` | Network/routing issue | Check connectivity, firewall rules |
| `No route to host` | DNS or network policy | Verify service discovery, CNI |
| `OutOfMemory killed` | Memory limits too low | Check memory usage, increase limits |
| `OOMKilled` | Container exceeded memory | Review memory requests/limits |
| `CrashLoopBackOff` | Container crashing repeatedly | Check logs --previous |
| `ImagePullBackOff` | Cannot pull container image | Verify image tag, registry auth |
| `CreateContainerConfigError` | Secret/ConfigMap missing | Check secret existence |
