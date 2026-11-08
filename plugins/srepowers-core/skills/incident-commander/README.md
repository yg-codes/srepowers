# incident-commander

Coordinate a major incident with Incident Command System structure:
declare and rate severity, assign IC / Operations / Communications /
Scribe roles, run the response in phases with a fixed stakeholder update
cadence, and close with a mandatory post-mortem. Includes async and
follow-the-sun adaptations for distributed teams. Ships as
`srepowers-core:incident-commander`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Multi-service cascade failures or unclear blast radius
- Outages expected to run past 30 minutes, with customer or executive impact
- Long incidents: 4-hour checkpoints, IC handoff protocol, timezone rotation
- Escalation calls: a single-service known fix belongs to
  `srepowers-core:systematic-troubleshooting`; data at risk, compliance
  exposure, or media attention belongs here

## How-to

Say "declare an incident" or "coordinate this outage response" — or
invoke the `srepowers-core:incident-commander` skill. It runs five
phases: declaration → assessment → response → recovery → post-incident,
with copy-paste templates for status updates, IC handoffs, and
escalations. Post-incident documentation goes through
`srepowers-core:post-mortem-writer`.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: run a tabletop SEV2 and confirm it assigns roles, opens a
timeline, and produces updates at the severity's cadence.

## Reference

| Severity | Criteria | Response time | Update cadence |
|----------|----------|---------------|----------------|
| SEV1 | Complete outage, data loss, security breach | Immediate | every 15 min |
| SEV2 | Major functionality impaired | 15 min | every 30 min |
| SEV3 | Minor impact, workaround available | 30 min | every hour |

`SKILL.md` carries the role table, phase-by-phase process, communication
templates per audience, red flags, and the distributed/async section
(incident command document, handoff protocol, rotation schedule).

---
Last Updated: 2026-09-14
