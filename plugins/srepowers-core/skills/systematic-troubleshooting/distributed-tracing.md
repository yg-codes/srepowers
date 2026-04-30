# Distributed Tracing Techniques

## Overview

Traces follow requests across service boundaries, revealing latency bottlenecks and failure propagation.

## Key Concepts

| Term | Definition |
|------|------------|
| **Trace** | End-to-end request path through all services |
| **Span** | Single operation within a trace |
| **Parent Span** | Calling operation |
| **Child Span** | Called operation |

## Using Traces for Troubleshooting

### 1. Find Slow Requests

```bash
# Query for high-latency traces
# (Using Jaeger example)
curl -s "http://jaeger:16686/api/traces?service=frontend&minDuration=2s" | jq .
```

### 2. Identify Bottlenecks

Look for:
- **Long spans**: Which operation took the most time?
- **Sequential calls**: Are services waiting unnecessarily?
- **Retry storms**: Multiple retries of failed calls

### 3. Error Propagation

Trace shows:
- Which service first returned error
- How error propagated to user
- What services were affected

## Span Attributes to Check

```yaml
# Critical attributes for troubleshooting
http.method: GET
http.url: /api/users/123
http.status_code: 500
error: true
error.message: "connection refused"

# Performance attributes
duration_ms: 2500
cpu.time_ms: 100
wait.time_ms: 2400  # Indicates waiting on dependency
```

## Common Trace Patterns

| Pattern | Visualization | Meaning |
|---------|--------------|---------|
| **Fan out** | One parent, many parallel children | Concurrent requests to multiple services |
| **Cascade** | Sequential chain of spans | Synchronous dependency chain |
| **Diamond** | A→B→D and A→C→D | Multiple paths to same service |
| **Retry** | Repeated same span | Failed calls being retried |

## Without Distributed Tracing

If tracing isn't available, simulate with logs:

```bash
# Add correlation ID to logs
# In each service, log: timestamp, correlation_id, service_name, operation, duration

# Then correlate by correlation_id
grep "corr-abc-123" *.log | sort
```

## Integration with Troubleshooting

1. **Phase 1 (Gather)**: Find example traces of failing requests
2. **Phase 2 (Pattern)**: Compare trace structure (working vs failing)
3. **Phase 3 (Hypothesis)**: Identify which span is slow/failing
4. **Phase 4 (Fix)**: Verify fix with new traces showing improvement
