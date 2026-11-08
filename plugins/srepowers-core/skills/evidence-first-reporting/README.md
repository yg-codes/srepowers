# evidence-first-reporting

Structure infrastructure reporting so it can't overstate certainty: every
status update separates what was observed from what is inferred, keeps
unknowns explicit, and names the exact check that would close each gap.
Ships as `srepowers-core:evidence-first-reporting`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Incident updates and investigation summaries
- Operator handoffs and summaries of another agent's work
- Post-change validation reports — "fixed" claims must route through proof
- Audit and health-check write-ups, where the `Unknowns` section is the
  whole point: an audit with no unknowns is hiding them
- Naming a cause or an actor — the direct-evidence test decides whether an
  attribution may be stated as observed fact or must be labeled inference

## How-to

Say "write a status report", "summarize findings", "what did we find", or
"handoff notes" — or invoke the `srepowers-core:evidence-first-reporting`
skill. Invoke it rather than paraphrasing it: the output contract below is
the gate, and inline imitation is exactly what drops the load-bearing
sections.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: hand it mock command output and check the report labels
observation vs inference, keeps unknowns explicit, and states the exact
next verification command.

## Reference

- `SKILL.md` — the output contract (`Status / Observed / Inference /
  Unknowns / Next Verification / Risk / Blast Radius`), the rules, the
  pre-delivery scan (fence tags, placeholders, digit counts), the
  attribution direct-evidence test, anti-patterns, and a good-vs-bad
  example pair

---
Last Updated: 2026-09-18
