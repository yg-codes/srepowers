---
name: session-log
description: |
  Append a timestamped changelog entry to the per-project SESSIONLOG.md summarizing what was done in the current session. Use when user says "session log", "log session", "update session log", "write changelog", or at the end of a productive session before exiting.

  TRIGGER: When user says "session log", "log this session", "write session log", "update changelog", or explicitly asks to record session activity.
---

# Session Log

Append a timestamped summary of the current session's work to the **per-project**
`SESSIONLOG.md` that lives in Claude's project directory for the current working
directory — alongside this project's auto-memory store.

## Where this fits

Session narrative is **ephemeral local history**. It is one of three sinks, and
must never leak into instruction memory:

| Sink | Holds | Lifetime |
|------|-------|----------|
| **SESSIONLOG.md** (this skill) | "what I did this session" — curated digest | Local, ephemeral |
| **git commit body** | durable change narrative for shared repos | Permanent, shared |
| **CLAUDE.md** | conventions + current structural facts | Never holds history |
| **claude-mem** (plugin) | automatic per-tool observation log | Cross-session DB |

Rule of thumb: **history → SESSIONLOG or commit, never `CLAUDE.md`.**

### Relationship to claude-mem

This skill is **not** redundant with the `claude-mem` plugin, even though both
record "what happened." They differ on purpose:

- **claude-mem** = automatic, granular, machine-generated observations in a
  searchable DB. It captures *everything* — but only when its worker is running,
  and in some setups its compression step sends session content to an external
  LLM relay. That makes it unsuitable for sensitive repos where you
  deliberately leave it off.
- **session-log** = a manual, curated, **local-only, zero-egress** digest — the
  handful of outcomes worth remembering, with no worker, no DB, no network.

Keep both: session-log is the safe, deliberate executive summary; claude-mem is
the optional automatic full log. When claude-mem is off (or excluded for a
repo), session-log is the only session-history layer left.

## When to Use

- User explicitly requests logging the session
- End of a productive session (paired with Stop hook reminder)
- User says "session log", "log session", "update changelog"

## Log File Location

**Always:** `~/.claude/projects/<slug>/SESSIONLOG.md`, where `<slug>` is the
current working directory with every `/` replaced by `-`.

```bash
SLUG=$(echo "$PWD" | sed 's#/#-#g')           # ~/src/site-a/puppet -> -home-user-src-site-a-puppet
LOG="$HOME/.claude/projects/$SLUG/SESSIONLOG.md"
```

This is the same per-project directory that holds the project's auto-memory
store, so session history sits next to the memory it relates to. Because it lives
**outside** the repo, it can never be committed — no `.gitignore` step is needed.
The same `<slug>` path is what the SessionStart/Stop hooks use, so the hook
reminder and this skill always agree on the file.

## Workflow

### Step 1 — Resolve the log path

Compute `$LOG` as above. The project directory normally already exists (Claude
creates it on first use); if not, create it with `mkdir -p "$(dirname "$LOG")"`.

### Step 2 — Review the session

Scan the conversation for significant actions:
- Files created, modified, or deleted
- Commits made
- Rules or configs changed
- Infrastructure operations performed
- Decisions made or problems solved

### Step 3 — Classify entries

Use these prefixes for quick scanning:

| Prefix | Meaning |
|--------|---------|
| `add:` | New file, feature, or rule |
| `fix:` | Bug fix or correction |
| `ref:` | Refactor or restructure |
| `chg:` | Configuration or behavior change |
| `del:` | Removed something |
| `inv:` | Investigation / discovery (no code change) |

### Step 4 — Write to SESSIONLOG.md

Create `$LOG` if it doesn't exist. One **full-timestamp line per action** — no
per-date headings to maintain:

```markdown
# Session Log

Significant session activity, newest first.
Format: `YYYY-MM-DD HH:MM - prefix: description` (prefixes: add, fix, ref, chg, del, inv)

2026-06-19 14:05 - add: description of what was added
2026-06-19 13:50 - fix: description of what was fixed
2026-05-26 13:59 - inv: description of an earlier session's investigation
```

Rules:
- One line per significant action; terse — this is a skim document.
- Full `YYYY-MM-DD HH:MM` per line, 24-hour, session's local timezone. (No date
  headings — the date is on every line, so entries from any day interleave
  cleanly.)
- Use a plain hyphen separator `- ` (not em-dash) — matches existing files and
  is trivial to type.
- **Prepend** new entries at the TOP (newest first) so recent history shows
  without scrolling.

> **Format note:** this matches the format already in use. Do not rewrite
> existing entries to a different scheme — append in the same style the file
> already uses.

### Step 5 — Never commit

SESSIONLOG.md lives in `~/.claude/projects/<slug>/`, **outside any repo**, so it
cannot be committed. Never copy its contents into a tracked file or a
`CLAUDE.md`.

## Example Output

```markdown
# Session Log

Significant session activity, newest first.
Format: `YYYY-MM-DD HH:MM - prefix: description` (prefixes: add, fix, ref, chg, del, inv)

2026-04-26 22:43 - add: AI-instruction file exclusion rule to rules.md (abc1234)
2026-04-26 22:40 - inv: Searched for existing CLAUDE.md/AGENTS.md gitignore patterns across rules files
2026-04-26 22:38 - inv: Explored rules.md structure for optimal rule placement
2026-04-26 22:35 - add: session-log skill and Stop hook reminder for automatic session changelog
```

## Anti-Patterns

- Do NOT log every tool call or trivial action — only significant outcomes
- Do NOT duplicate git commit history — summarize the intent, not the diff
- Do NOT include sensitive information (passwords, tokens, internal URLs)
- Do NOT overwrite existing entries — always prepend (newest first)
- Do NOT commit SESSIONLOG.md to any git repository
