# receiving-code-review-sre

Handle incoming code review feedback on infrastructure changes as technical
claims to verify — not orders to obey and not prompts for gratitude. Read,
verify against the real environment, then respond or push back with
reasoning. Ships as `srepowers-core:receiving-code-review-sre`. (`SKILL.md`
is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Triage multi-item review feedback without blind implementation
- Push back with evidence when a suggestion would break existing infrastructure
- Replace performative agreement ("You're absolutely right!") with a stated fix
- Sequence fixes: blocking issues first, one item at a time, each verified

## How-to

Just ask — "got review feedback", "reviewer says to change X", "how should I
handle this review comment" — or invoke the
`srepowers-core:receiving-code-review-sre` command.

Core pattern: read → understand → verify → evaluate → respond → implement.
If any item is unclear, stop and clarify all items before implementing any.
External reviewers' suggestions get checked against this environment (does it
break existing infra, work across sit/uat/prod?). This is the receiving side
of the review loop; `srepowers-core:requesting-review-sre` is the request
side. Reply to GitHub inline comments in the comment thread, not as
top-level PR comments.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the only file. Contains:
  - The response pattern and the forbidden-responses list
  - Source-specific handling (human partner vs external reviewers)
  - Pushback scenario tables: Kubernetes manifests, Terraform plans,
    security groups/firewalls — each with what to check first
  - Acknowledgment phrasing (good/bad examples) and the GitHub thread-reply
    API call

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `receiving-code-review`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
