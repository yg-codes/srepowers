# dispatching-parallel-agents-sre

Coordinate several independent infrastructure problems at once: one
focused agent per problem domain, dispatched in parallel with its own
scope, safety constraints, and required output, then integrate and verify
the combined result. Ships as
`srepowers-core:dispatching-parallel-agents-sre`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Unrelated alerts fire simultaneously (different namespaces, services,
  regions) — investigate concurrently instead of serially
- Checks or fixes across environments where each target is independent
- Keep the coordinator's context clean: each agent gets precisely crafted
  instructions and evidence, never your session history
- Same-command-on-N-hosts runs go through `parallel-ssh`, not N agents

## How-to

Say "run these in parallel", "dispatch agents for each task", or describe
the independent failures — or invoke the
`srepowers-core:dispatching-parallel-agents-sre` skill. It applies only
when domains are truly independent and can work concurrently; related
failures get a single investigation instead. Dispatched agents never
re-invoke this skill — that would recurse the fan-out.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: give it two independent failures and confirm it groups the
domains, embeds safety constraints in each agent prompt, and checks for
conflicting edits before integrating.

## Reference

- `SKILL.md` — the independence test, agent prompt structure, safety-rules
  block, grouping patterns (region/service/layer/severity), and the
  parallel-ssh-vs-subagent decision table

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `dispatching-parallel-agents`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
