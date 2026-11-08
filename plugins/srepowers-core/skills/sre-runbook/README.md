# sre-runbook

Write executable SRE runbooks for infrastructure operations: every step
carries a mandatory **Command / Expected / Result** triple, all commands are
non-interactive and copy-pasteable, and steps are organized into pre-checks →
(dry-run) → execution → verification → post-checks. Ships as
`srepowers-core:sre-runbook`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- Document a server operation before or while performing it — restarts, config changes, log checks
- Write pre-flight / post-flight checklists and validation steps
- Capture incident-response command sequences as reusable procedures
- Keep completed runbooks as audit artifacts with actual Result values filled in

## How-to

Say "write a runbook for this operation" or "document this procedure" — the
skill triggers automatically. Invoke directly as `srepowers-core:sre-runbook`.
Every step looks like:

```markdown
### Step 1.1: Check Service Status

**Command**: ssh server "sudo systemctl status nginx --no-pager | head -15"
**Expected**: Service shows `active (running)` or `inactive (dead)`
**Result**: ✅ Service active (running), uptime 5 days
```

### Verify

Fixture: `evals/fixtures/sre-runbook/fixture-restart-service.yaml` — run it
with the `srepowers-core:skill-test-runner` skill.

## Reference

Every command must be non-interactive:

| Instead of | Use |
|------------|-----|
| Confirmation prompts | `--yes`, `--force`, `--batch` flags |
| Interactive password prompts | Credentials via environment variables |
| `vi`/`nano` edits | `sed`, `awk`, or file replacement |
| Paginating output | `--no-pager` or `| head -N` |

- `SKILL.md` — header metadata (operator/ticket/approver), step format, per-operation step patterns, SSH flag table, rollback/escalation sections

---
Last Updated: 2026-09-14
