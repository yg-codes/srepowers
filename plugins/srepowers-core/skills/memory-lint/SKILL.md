---
name: memory-lint
description: Use when saving or editing agent memory files, when MEMORY.md and the memory directory may have drifted (unindexed files, dangling index entries), when a recalled memory seems missing or duplicated, or for a periodic hygiene pass over a file-based memory store. Also use for "check my memories", "lint the memory store", "is MEMORY.md in sync". Read-only check; changes nothing.
---

# memory-lint

Integrity checker for a file-based agent memory store: frontmatter schema,
name-slug format and uniqueness, two-way `MEMORY.md` index consistency,
`[[link]]` resolution, and email/name-shaped PII spans. It only reports —
fixing is a deliberate follow-up, never automatic.

**Announce at start:** "I'm using the memory-lint skill to check store
integrity."

## Why a linter for memory

A memory store fails silently. An unindexed file is invisible to recall, a
dangling index entry points at nothing, and a duplicate slug means one of two
memories wins arbitrarily. None of these produce an error at write time — the
store just quietly stops answering questions it should answer. The failure
surfaces months later as "I thought we recorded that."

PII is the other half. Memory files are re-read by every later tool call and
travel wherever that context goes, so a colleague's real name or email in a
memory file is a **standing** leak, not a one-time exposure.

## Usage

```bash
python3 scripts/memory_lint.py                    # nearest store at/above cwd
python3 scripts/memory_lint.py /path/to/memory    # any other store
```

Exit 1 if any WARN, 0 otherwise. INFO findings do not affect the exit code.

Run the unit tests with:

```bash
python3 -B scripts/test_memory_lint.py
```

## Expected store shape

```text
<store>/
  MEMORY.md              # the index — one line per memory
  <name>.md              # one memory per file, with frontmatter
```

Each memory file carries:

```yaml
---
name: <short-kebab-case-slug>
description: <one-line summary>
metadata:
  type: user | feedback | project | reference
---
```

## Rules

| Rule id | Level | Catches |
|---|---|---|
| `missing-frontmatter` | WARN | file has no `---` block |
| `missing-field` | WARN | frontmatter lacks `name`, `description`, or `type` |
| `bad-type` | WARN | `type` outside user / feedback / project / reference |
| `prefix-type-mismatch` | WARN | filename prefix (`reference_` / `project_` / `feedback_` / `user_`) disagrees with `type`. Unprefixed names are not flagged |
| `bad-name-format` | WARN | name slug is not a lowercase kebab/snake slug (both accepted; `-` and `_` are equivalent in `[[links]]` too) |
| `duplicate-name` | WARN | two files share a name slug |
| `no-index` / `dangling-index-entry` / `unindexed-file` | WARN | MEMORY.md missing, points at a deleted file, or omits an existing file |
| `dangling-link` | INFO | `[[name]]` with no matching memory — sanctioned as "worth writing later", so never WARN |
| `possible-pii-email` | WARN | email-shaped span (placeholder domains like `example.com` excluded) |
| `possible-pii-name` | WARN | name-shaped span in a PII-correlated context: a `Name:`/`Contact:`/`Author:`/`Owner:`/`Assignee:`/`CC:` label, a "reported by" / "assigned to" phrase, or git-style `First Last <email>` authorship — not raw capitalized prose |

## Reading the output

**`dangling-link` is INFO on purpose.** A `[[link]]` to a memory that does not
exist yet marks something worth writing, not an error. Do not "fix" these by
deleting the link — that discards the signal.

Code spans and fenced blocks are excluded from link scanning, so a memory
recording a shell idiom (`rg '[[:space:]]'`) does not report one dangling link
per POSIX bracket expression. Measured on a real 11-file store: that exclusion
took the INFO output from 20 lines to 2, and both survivors were genuine.

**A clean run is not proof the store is useful** — only that it is
structurally sound. The linter cannot tell you a memory is stale, wrong, or
duplicative in substance. That judgment stays with you.

## When to run it

- After saving new memories — fix WARNs immediately; they are always small
  (add an index line, fill a field).
- Before a session that depends on recall being complete.
- Periodically, as a hygiene pass.

Fix WARNs; leave INFO `dangling-link` alone unless the linked memory is now
worth writing.

## Limits

- Checks structure, never substance.
- The `possible-pii-name` heuristic is deliberately narrow — scoped to contexts
  that correlate with a real person. It will miss a bare name in prose. Treat a
  clean PII result as "no obvious leak", not "audited".
- Assumes the frontmatter schema above. A store with a different shape reports
  noise, not findings.
