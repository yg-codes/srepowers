---
name: observability-engineer
description: Use when setting up observability systems including monitoring, logging, metrics, tracing, or alerting. Invoke for dashboards, Prometheus/Grafana, OpenTelemetry, load testing, profiling, capacity planning, SLO-based alerting.
---

# Observability Engineer

## When to Use This Skill

- Setting up application monitoring
- Implementing structured logging
- Creating metrics and dashboards
- Configuring alerting rules
- Implementing distributed tracing
- Debugging production issues with observability
- Performance testing and load testing
- Application profiling and bottleneck analysis
- Capacity planning and resource forecasting

## Core Workflow

1. **Assess** - Identify what needs monitoring
2. **Instrument** - Add logging, metrics, traces
3. **Collect** - Set up aggregation and storage
4. **Visualize** - Create dashboards
5. **Alert** - Configure meaningful alerts

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Logging | `references/structured-logging.md` | Pino, JSON logging |
| Metrics | `references/prometheus-metrics.md` | Counter, Histogram, Gauge |
| Tracing | `references/opentelemetry.md` | OpenTelemetry, spans |
| Alerting | `references/alerting-rules.md` | Prometheus alerts |
| Dashboards | `references/dashboards.md` | RED/USE method, Grafana |
| Performance Testing | `references/performance-testing.md` | Load testing, k6, Artillery, benchmarks |
| Profiling | `references/application-profiling.md` | CPU/memory profiling, bottlenecks |
| Capacity Planning | `references/capacity-planning.md` | Scaling, forecasting, budgets |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Logging is enough" | Logs + metrics + traces. All three are needed for diagnosis. |
| "We'll add monitoring later" | Observability is foundational. Deploy monitoring with the service. |
| "Alert on everything" | Alert on symptoms, not causes. Too many alerts cause fatigue. |
| "Custom metrics aren't needed" | RED metrics (Rate, Errors, Duration) minimum for every service. |
| "Traces are too complex to set up" | Distributed tracing finds issues logs and metrics can't. |
| "Dashboards can wait" | Create dashboards at deploy time. You'll need them at 3am. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Knowledge Reference

Prometheus, Grafana, ELK Stack, Loki, Jaeger, OpenTelemetry, DataDog, New Relic, CloudWatch, structured logging, RED metrics, USE method, k6, Artillery, Locust, JMeter, clinic.js, pprof, py-spy, async-profiler, capacity planning