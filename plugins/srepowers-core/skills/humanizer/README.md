# humanizer

Strip the patterns that mark text as AI-generated before a deliverable
ships — inflated significance, promotional language, the rule of three,
AI vocabulary, em-dash overuse, passive voice, negative parallelisms,
filler phrases, oversized paragraphs, parenthetical overuse. Based on
Wikipedia's "Signs of AI writing" (WikiProject AI Cleanup). Ships as
`srepowers-core:humanizer`. (`SKILL.md` is the agent-facing trigger doc;
this file is for humans.)

## Use cases

- A post-mortem, status report, or runbook that reads as machine-written
- A ticket or MR description draft before it is pasted
- Voice matching — align a draft to a sample of your own writing
- Any deliverable where the reader will judge the prose, not just the facts

Not for code — when the srepowers-swe plugin is installed, `srepowers-swe:ponytail` owns code simplicity and explicitly
excludes prose.

## How-to

Say "humanize this", "does this read as AI-written", "make this sound
human", or invoke the `srepowers-core:humanizer` skill. Give it the text or
a file path; add a writing sample if you want voice calibration.

It reports and rewrites, then runs an adversarial slop-check against its own
rubric — at most two iterations, then it delivers and lists whatever is left
rather than polishing indefinitely.

### Verify

No fixture — verify by handing it a paragraph built from the patterns it
documents (a rule-of-three list, two em dashes, "it's worth noting that")
and checking that the rewrite removes them without inventing facts. The
rubric's own rule applies to the skill itself: specifics must stay real, so
a rewrite that adds a number is a failure.

## Reference

- `SKILL.md` — the pattern catalogue (§1–§36, including agent-era patterns),
  detection guidance, invocation modes, the draft → audit → final loop, a
  full worked example, sources, and Provenance
- `references/writing-rubric.md` — the structural contract for work
  deliverables: lead with the outcome, plain sentences, real specifics,
  detail moved out of the main flow, soft length budgets

## Provenance

Adapted from a community skill (MIT), itself derived from
`blader/humanizer` 2.9.1. Three site-specific excisions were made before it
landed here — an organization-specific report/ticket mode, a paste-target
reflow step naming a private fixer, and a real account name and ID in the
rubric's example. See `SKILL.md` → Provenance.

---
Last Updated: 2026-09-18
