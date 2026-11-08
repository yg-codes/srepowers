# observability-engineer

Set up and mature an observability stack end to end: logging, metrics,
tracing, dashboards, and alerting, plus load testing, profiling, and capacity
planning. Ships as `srepowers-core:observability-engineer`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- Instrument a service from zero: structured logs, RED metrics, distributed traces
- Configure alerting that pages on symptoms (SLOs), not on every metric
- Build RED/USE dashboards before the next on-call rotation needs them
- Load-test, profile, and forecast capacity before a scaling decision

## How-to

Just ask — "set up monitoring for this service", "add Prometheus metrics",
"wire up OpenTelemetry tracing", "create a Grafana dashboard", "capacity-plan
this service" — or invoke the `srepowers-core:observability-engineer` command.

Workflow: assess what needs monitoring → instrument → collect → visualize →
alert. The skill loads only the deep-dive reference matching the current
topic, not all eight.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — core workflow, "red flags" counter-table, knowledge reference
- `references/structured-logging.md` — Pino, JSON logging
- `references/prometheus-metrics.md` — counters, histograms, gauges
- `references/opentelemetry.md` — tracing, spans
- `references/alerting-rules.md` — Prometheus alert rules
- `references/dashboards.md` — RED/USE method, Grafana
- `references/performance-testing.md` — load testing, k6, Artillery, benchmarks
- `references/application-profiling.md` — CPU/memory profiling, bottlenecks
- `references/capacity-planning.md` — scaling, forecasting, budgets

---
Last Updated: 2026-09-14
