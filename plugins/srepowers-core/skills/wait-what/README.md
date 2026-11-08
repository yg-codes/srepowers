# wait-what

Re-pitch an explanation that did not land — rebuild it, not repeat it. When
you say "I don't follow", the agent rewrites its previous message with real
context first, short plain sentences, and no apology for the miss. Ships as
`srepowers-core:wait-what`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- After "I don't follow" / "that didn't land" / "you lost me" — get the same point rebuilt from context
- Get an explanation rewritten in Simplified Technical English: short sentences, one idea each, plain verbs
- Get jargon dropped and acronyms expanded on first use, using the project's own glossary terms

## How-to

Just say it — "I don't follow", "that didn't land", "explain that again" —
or invoke `srepowers-core:wait-what`.

Not for redirections: "wait, use host02 instead" is a change of instruction,
and the skill stays out of the way — the agent acts on the instruction
instead of re-explaining.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the re-pitch rules: lead with context, ASD-STE100 style,
  ubiquitous language from the project `CLAUDE.md`/glossary, expand acronyms
  on first use, and act when the message was a redirection rather than a
  confusion signal

## Provenance

Adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT, © Matt Pocock) `productivity/wait-what`, rewired onto srepowers skill
names and doctrines. Upstream reference rewires are recorded in
`RELEASE-NOTES.md`.

---
Last Updated: 2026-09-14
