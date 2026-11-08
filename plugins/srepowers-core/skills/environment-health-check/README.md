# environment-health-check

Pre-flight check for your workstation: verify the infrastructure tools an
operation will need — kubectl, terraform, aws, glab, helm, tshark, and
friends — are installed, respond to their correct version commands, and
have working config, contexts, and auth. Catches missing tools before
they fail mid-operation. Ships as
`srepowers-core:environment-health-check`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Start of a session or a new workstation: what's missing or unauthenticated?
- Before a multi-step operation that depends on many tools
- After installing or updating tools — confirm they still work
- Debugging "command not found" or auth errors ("Unable to locate credentials")

## How-to

Say "check my environment", "verify tools", or "am I set up correctly" —
or invoke the `srepowers-core:environment-health-check` skill. Pick a
level (see table), run the checks, and get a health report with pass/fail
per tool plus installation guidance. Scope is tool and connectivity
readiness only — enumerating cluster resources is a different task.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: run a level-2 check on a machine with a deliberately broken
tool install and confirm the report flags it instead of passing silently.

## Reference

| Level | Checks | Use when |
|-------|--------|----------|
| 1 Essential | kubectl, git, curl | quick check before simple operations |
| 2 Standard | + helm, terraform, aws, jq, yq | before multi-step operations |
| 3 Comprehensive | + k9s, stern, kustomize, argocd | setting up a new workstation |

`SKILL.md` carries the per-tool version commands (not every tool takes
`--version`: `kubectl version --client`, `helm version`), config and
connectivity checks, common issue fixes, and installation guidance.

---
Last Updated: 2026-09-14
