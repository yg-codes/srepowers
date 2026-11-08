# session-log

Append a timestamped changelog entry — one terse line per significant action,
newest first — to the per-project `~/.claude/projects/<slug>/SESSIONLOG.md`,
where `<slug>` is the working directory with `/` replaced by `-`. Ships as
`srepowers-core:session-log`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- Capture "what I did this session" at the end of productive work
- Recover context in a later session without re-reading diffs
- Keep session history local-only and zero-egress — no worker, no DB, no network (including in sensitive repos where claude-mem is off)
- Keep history out of `CLAUDE.md` and out of any git repo: the log lives outside the repo, so it can never be committed

## How-to

Say "session log", "log this session", or "update changelog" — the skill
triggers automatically; it is also the natural close of a productive session.
Invoke directly as `srepowers-core:session-log`. Entries are prepended at the
top, full `YYYY-MM-DD HH:MM` per line, classified with a prefix:

```markdown
2026-06-19 14:05 - add: session-log skill and Stop hook reminder
2026-06-19 13:50 - fix: description of what was fixed
```

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (end a session, confirm the entry was prepended to the project's
`SESSIONLOG.md`).

## Reference

| Prefix | Meaning |
|--------|---------|
| `add:` | New file, feature, or rule |
| `fix:` | Bug fix or correction |
| `ref:` | Refactor or restructure |
| `chg:` | Configuration or behavior change |
| `del:` | Removed something |
| `inv:` | Investigation / discovery (no code change) |

- `SKILL.md` — log path resolution, entry format rules, relationship to claude-mem/commits/CLAUDE.md, anti-patterns

---
Last Updated: 2026-09-14
