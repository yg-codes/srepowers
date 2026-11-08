# verification-before-completion

The mandatory gate behind every completion claim: run the command that
proves the claim, read the full output, then — and only then — say it.
Fresh evidence, in this message, no exceptions. Ships as
`srepowers-core:verification-before-completion`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Before saying "deployed", "fixed", "healthy", or "done" — exit 0 and an agent's success report are not evidence
- Before any commit, PR, merge, or status update
- Before accepting a subagent's results — verify independently against actual state
- Closing an incident: verified service restoration, not "should be up"

## How-to

The gate is invoked, not paraphrased: invoke
`srepowers-core:verification-before-completion` before any success,
completion, or health claim. Its gate function:

1. Identify the command that proves the claim
2. Run it fresh and complete
3. Read the full output and exit code
4. Confirm the output actually confirms the claim
5. Only then state the claim — with the evidence

Examples: `kubectl rollout status` after a Helm apply, a health-endpoint
curl after the pod is Running, `git diff` after an agent reports success.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the Iron Law, the gate function, the claim → required-evidence
  table (deployment, health, config, rollback, agent delegation), red flags
  and rationalization counters, and the requirements-traceability procedure
  for operation plans

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `verification-before-completion`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
