# test-driven-operation

Define the verification command before executing any state-changing
infrastructure operation — and when the target state is absent or broken, run
the verification first and watch it fail (RED), execute the smallest safe
operation (GREEN), then document (REFACTOR). Success is claimed only from
fresh evidence. Ships as `srepowers-core:test-driven-operation`. (`SKILL.md`
is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Kubernetes, API, Keycloak, git control-repo, and Linux server changes
- Valid-state operations (restarts, cert rotation): baseline first, verify the delta
- Async work (ArgoCD sync, DNS propagation, Kafka lag) via poll-until-ready loops that always carry a timeout
- Read-only data pipelines: validate JSON, reconcile aggregates against raw counts, spot-check the report

## How-to

Say "do this with TDO" or simply start an infrastructure change — the skill
triggers on state-changing infra work. Invoke directly as
`srepowers-core:test-driven-operation`. The cycle: write one minimal
verification → watch it fail for the expected reason (or record the baseline)
→ run the minimal operation → watch the verification pass → document.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (e.g. create a k8s ConfigMap; confirm the verification was
written and failed before the apply, and that GREEN is claimed from real
command output).

## Reference

Async verifications pick one of three strategies:

| Strategy | Example |
|----------|---------|
| Poll-until-ready | Deployment `readyReplicas`, Terraform apply |
| Event-based | Kafka consumer lag reaching zero |
| Baseline-delta | DNS propagation, S3 eventual consistency |

Puppet note: exit 2 means "changes applied successfully" and exit 6 means
"applied AND failures" — check output for `Error:` lines, not just the exit
code.

- `SKILL.md` — RED/GREEN/REFACTOR cycle, verification quality table, rationalization table, completion checklist
- `testing-anti-patterns.md` — failure modes to avoid: command success ≠ verified state, fixed sleeps, incomplete verification

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `test-driven-development`, recast from software development to
infrastructure operations. Distinct from `srepowers-swe:tdd` (when shipped), which is the per-cycle code loop. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
