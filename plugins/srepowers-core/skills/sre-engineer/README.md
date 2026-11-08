# sre-engineer

Routing skill for SRE practice: define SLIs/SLOs and error budgets, build
golden-signal monitoring and alerting, reduce toil through automation, and
run incident-response and chaos-engineering work — loading the topic
reference that matches your context. Ships as `srepowers-core:sre-engineer`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Define meaningful SLIs and realistic SLO targets, then an error-budget policy (freeze features when the budget burns out)
- Design alerts and dashboards around the golden signals: latency, traffic, errors, saturation
- Measure and prioritize toil, then build automation for it
- Plan chaos experiments, incident response, and blameless post-mortems

## How-to

Ask for the work directly — "define SLOs for this service", "set an error
budget policy", "reduce on-call toil" — or invoke `srepowers-core:sre-engineer`.
The skill loads only the reference your task needs and returns SLO
definitions, monitoring configuration, automation scripts, or runbooks as the
work requires.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (e.g. ask for an SLO + error-budget policy and check which
reference it loads and the shape of the output).

## Reference

- `SKILL.md` — core workflow, red-flags table, output templates, Google SRE book links
- `references/slo-sli-management.md` — SLI patterns and SLO target setting
- `references/error-budget-policy.md` — budget management, burn rates, policy decisions
- `references/monitoring-alerting.md` — golden signals, alert design, dashboards
- `references/automation-toil.md` — toil reduction and automation patterns
- `references/incident-chaos.md` — incident response and chaos engineering

---
Last Updated: 2026-09-14
