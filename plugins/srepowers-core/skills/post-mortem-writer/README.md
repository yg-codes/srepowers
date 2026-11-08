# post-mortem-writer

Write a blameless post-mortem after an incident or outage: evidence gathering
first, then a structured document with timeline, root cause, quantified
impact, and owned action items — focused on systems, never on people. Ships
as `srepowers-core:post-mortem-writer`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Document a SEV1, customer-impacting, rollback, or >30-minute incident
- Turn a raw incident timeline into specific root cause and assigned action items
- Run the 30–60 minute review meeting from a fixed agenda
- Rewrite a draft that names individuals into a systems-focused one

## How-to

Just ask — "write the post-mortem for this incident", "document this outage",
"blameless review of what happened" — or invoke the
`srepowers-core:post-mortem-writer` command.

Gather evidence before writing (events, logs, metrics, changes in the
window), fill the template, then check the blameless/specificity review list
before sharing. Not for planned maintenance, staging catches, or minor issues
with obvious fixes and no impact.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - Full post-mortem template: executive summary, UTC timeline table, root
    cause, impact assessment, detection, response, action items, appendix
  - Evidence checklist and evidence-gathering commands
  - Writing guidelines with bad/good pairs (be specific, blameless,
    systems-focused, quantify)
  - Review checklist, sharing list, meeting agenda and ground rules

---
Last Updated: 2026-09-14
