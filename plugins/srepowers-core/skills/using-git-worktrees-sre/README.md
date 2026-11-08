# using-git-worktrees-sre

Put infrastructure changes in an isolated git worktree so your current
branch — and any in-flight environment pointed at it — stays untouched.
Layers SRE safety on top: environment detection, ignore checks, clean
baseline. Ships as `srepowers-core:using-git-worktrees-sre`. (`SKILL.md` is
the agent-facing trigger doc; this file is for humans.)

## Use cases

- Start Kubernetes manifest, Terraform, or control-repo changes without disturbing the checked-out branch
- Prepare the isolated workspace required before `subagent-driven-operation` or operation-plan execution
- Detect whether you are already in a linked worktree (or a submodule) before creating anything
- Catch production-target work early — branch-name and directory-structure detection, with explicit confirmation required for prod

## How-to

Say — "work in a worktree", "isolate this change", "worktree for this
operation" — or invoke `srepowers-core:using-git-worktrees-sre` before any
infrastructure-as-code change.

The skill's decision order: detect existing isolation first, prefer the
harness's native worktree tool if one exists, fall back to `git worktree
add` only with consent. Project-local worktree directories must be verified
gitignored before use — untracked worktree contents in a control repo can
trigger unintended deployments.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — the full procedure: Step 0 isolation/submodule detection,
  native-tool-vs-git-fallback decision, directory selection, ignore/env/
  baseline safety verification, control-repo-type checks (k8s / Terraform /
  Ansible), and how it differs from software-development worktrees

## Provenance

Adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent) `using-git-worktrees`, recast from software development to
infrastructure operations. Deliberate divergences are recorded in
the `RELEASE-NOTES.md` sync sections.

---
Last Updated: 2026-09-14
