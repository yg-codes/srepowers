# progressive-delivery

Shift traffic to a new version incrementally — canary, blue-green, or shadow
— validating SLOs at each stage against rollback triggers set before the
first shift. Ships as `srepowers-core:progressive-delivery`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- Canary rollout: 5% → 25% → 50% → 100%, SLO-checked at each stage
- Blue-green switch with a smoke test on green before any traffic moves
- Shadow/mirror traffic to compare a new version with zero user impact
- Decide advance / extend / rollback per stage from metrics, per the
  decision matrix

## How-to

Just ask — "canary deploy this service", "set up a blue-green switch",
"mirror traffic to the new version" — or invoke the
`srepowers-core:progressive-delivery` command.

Before any traffic shift: capture the SLO baseline (within 30 minutes of
deploy start) and write down numeric rollback triggers:

| Metric | SLO target | Rollback trigger |
|--------|-----------|------------------|
| Error rate | < 1% | > 2% for 5 min |
| p99 latency | < 200ms | > 400ms for 5 min |

Each stage is a TDO cycle: define "healthy" → shift traffic (Argo Rollouts,
nginx canary-weight, or Istio weights) → validate → decide. Keep the old
version running 30 minutes after full cutover.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - The three strategies with traffic diagrams
  - Per-stage TDO cycle with copy-paste verification and rollback commands
  - Stage decision matrix (advance / extend / rollback / declare incident)
  - Shadow-traffic Istio mirroring config and comparison approach
  - Common mistakes: no SLO validation, undefined triggers, untested green,
    stale baselines

---
Last Updated: 2026-09-14
