# observability-integration

Verify infrastructure changes against live metrics and alerts — baseline
before, compare after, check what fired — instead of trusting command output
alone. For building or configuring monitoring, use
`srepowers-core:observability-engineer` instead. Ships as
`srepowers-core:observability-integration`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Prove a deploy or scaling change didn't regress error rate or latency,
  with a before/after metric table
- Confirm which alerts fired, resolved, or stayed silent during a change window
- Add metric verification steps to test-driven-operation verification cycles
- Correlate an incident timeline with what the metrics actually showed

## How-to

Just ask — "check metrics after deploy", "verify with dashboards", "are
alerts firing", "check Grafana", "look at Prometheus" — or invoke the
`srepowers-core:observability-integration` command.

Process: capture a baseline → predict expected metric changes → monitor
during the operation → compare against baseline → validate alerts. Every
claim about system health comes from a query output, not an impression.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - Five-step verification process with baseline/comparison table templates
  - Copy-paste query examples: PromQL, Datadog, CloudWatch, New Relic
    (NerdGraph), Kiali, Jaeger
  - Stack-agnostic golden-signals baseline template (errors, latency,
    traffic, saturation) with SLO target and rollback trigger columns
  - TDO integration examples (RED / GREEN / Verify GREEN with metrics)
  - Common mistakes: no baseline, mismatched time ranges, counter resets

---
Last Updated: 2026-09-14
