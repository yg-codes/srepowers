# dns-operations

Manage and troubleshoot on-premises DNS on BIND or similar servers: zone
file edits, record management, reverse DNS, syntax validation, and
resolution debugging. Enforced sequence: validate before reload, reload
before verify, verify before reporting success. Ships as
`srepowers-infra:dns-operations`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- Add, modify, or remove A, AAAA, CNAME, MX, TXT, or PTR records
- Debug resolution failures: NXDOMAIN, wrong IP returned, SERVFAIL
- Manage reverse DNS (PTR) zones
- Verify propagation after a zone change

## How-to

In Claude Code or Codex, just ask — "add DNS record", "fix DNS", "zone
file edit", "reverse DNS", "PTR record", "DNS not resolving", "dig",
"named-checkzone", "rndc reload" — the skill triggers automatically, or
invoke it directly as the `srepowers-infra:dns-operations` command.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the record-management workflow (edit → validate → reload →
  verify); reverse DNS management; symptom-based debugging playbooks
  (NXDOMAIN, wrong IP, SERVFAIL); anti-patterns

---
Last Updated: 2026-09-14
