# using-srepowers

The routing meta-skill: decides the minimum sufficient set of SREPowers
skills for a task before any work starts — mandatory gates first, then one
workflow route, then domain depth. Auto-injected at session start. Ships as
`srepowers-core:using-srepowers`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- Work out which skill (if any) a task needs: fast path, incident route, or planned-change route
- Check which mandatory gates apply (`verification-before-completion`, `safety-validator`, `evidence-first-reporting`)
- Understand the `<plugin>:<skill>` namespace across the five plugins
- Find the opt-in general software-engineering flow (`srepowers-swe`) for app/product work

## How-to

Ask — "how do I use srepowers", "which skill should I use", "show me
available skills" — or invoke `srepowers-core:using-srepowers`. It is loaded
automatically at the start of every session; for humans, the main entry
point is the catalog below.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

| File | Purpose |
|------|---------|
| `SKILL.md` | The routing rules: mandatory gates, the workflow router, fast-path criteria and the read-only → mutating state-transition gate, the standard workflow chain, anti-patterns |
| `references/skill-catalog.md` | The full catalog of every skill across all five plugins, organized by category with a "Use When" column per skill — the authoritative list when you know what you need but not what it is called |

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `using-superpowers`, recast from software development to
infrastructure operations. Rerouted to srepowers' plugin namespaces and routing map. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
