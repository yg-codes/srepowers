# safety-validator

Review proposed infrastructure commands before execution, classify each by
risk tier, block destructive operations until a typed confirmation phrase is
given, and propose safer alternatives. Ships as `srepowers-core:safety-validator`.
(`SKILL.md` is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Vet commands before they run — generated scripts, bulk operations, anything touching production
- Get a safer alternative for a destructive operation (delete → scale to zero, `git push --force` → `--force-with-lease`, `terraform destroy` → `plan -destroy`)
- Catch writes aimed at hosts approved read-only: SSH redirects, container-exec writes, fan-out scp/rsync
- Produce an audit-ready report: impact, verification questions, rollback plan, confirmation phrase

## How-to

Ask — "review these commands before execution", "is this safe to run" — or
invoke `srepowers-core:safety-validator`. Compound commands are parsed into
parts, each matched against the pattern rules, producing a report that ends
in a typed gate:

```text
Risk Level: HIGH — deleting production deployment
Type 'delete-api-server-production' to confirm execution:
```

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (e.g. feed it `rm -rf /data` plus an SSH redirect and confirm it
blocks on the typed confirmation).

## Reference

| Risk tier | Handling |
|-----------|----------|
| 🔴 Critical | Block without explicit typed confirmation |
| 🟠 High | Require typed confirmation |
| 🟡 Medium | Warn and confirm |
| 🟢 Low | Proceed, log |

Rule sets in SKILL.md cover Kubernetes, Terraform, databases, filesystem,
remote/SSH writes (hard block for READONLY-approved hosts), and Proxmox/ZFS —
each with a matching safe-alternatives table.

- `SKILL.md` — risk pattern tables, validation process, safe alternatives, red flags and limitations

---
Last Updated: 2026-09-14
