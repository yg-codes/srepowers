# systematic-troubleshooting

Four-phase investigation discipline for infrastructure incidents with one
Iron Law: no remediation without root-cause investigation first. Triage and
gather evidence → analyze patterns → form and minimally test a single
hypothesis → only then fix, one change at a time. Ships as
`srepowers-core:systematic-troubleshooting`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Investigate outages, degradation, crash loops, resource exhaustion, or connectivity failures
- Resist the "just restart it" reflex — especially under time pressure, when guessing is most tempting
- Diagnose distributed systems layer by layer: Ingress → Service → Pod → container → dependency
- Know when to stop: 3+ failed fixes means question the architecture, not attempt fix #4

## How-to

Say "investigate this outage", "troubleshoot this", or "find the root cause"
— the skill triggers automatically. Invoke directly as
`srepowers-core:systematic-troubleshooting`. Findings are reported in a fixed
contract: Symptoms / Evidence / Hypotheses / Validation Plan / Probable Cause
— writing `Probable Cause: not established` until the evidence supports it.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (e.g. a mocked pod-crash scenario; confirm it gathers evidence
and proposes no fix before a validated hypothesis).

## Reference

| Phase | Gate to pass |
|-------|--------------|
| 1. Triage | Timeline, blast radius, evidence per layer, recent changes |
| 2. Pattern | Working-vs-failing diff, history, dependencies |
| 3. Hypothesis | One hypothesis, minimal test, confirm or replace |
| 4. Remediation | Rollback plan, one fix, verify — escalate at 3+ failures |

- `SKILL.md` — phase checklists, output contract, communication templates, rationalization table
- `log-analysis.md`, `metrics-correlation.md`, `distributed-tracing.md`, `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md` — supporting techniques
- `find-polluter.sh` — bisect a check suite to find the step leaving stray state (locks, temp files) that makes runs flaky
- `condition-based-waiting-example.sh` — poll-until-condition utilities (rollouts, health endpoints, DNS) instead of fixed sleeps

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `systematic-debugging`, recast from software development to
infrastructure operations. Also absorbs superpowers `condition-based-waiting` guidance, recast for pod readiness, service health, and DNS propagation. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
