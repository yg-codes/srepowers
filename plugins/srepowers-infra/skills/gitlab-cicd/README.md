# gitlab-cicd

Author, debug, and manage GitLab CI/CD pipelines on self-hosted GitLab
instances: `.gitlab-ci.yml` authoring, runner management, the `glab` CLI,
CI/CD variables and secrets, and failed-pipeline debugging. Core rule:
validate YAML before push, test in a feature branch, protect main/prod
pipelines. Ships as `srepowers-infra:gitlab-cicd`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Write or modify a `.gitlab-ci.yml`, including modern `rules`-based pipelines
- Debug a failed pipeline job: identify the failure, categorize it, validate
  YAML locally, then debug interactively
- Check runner status, pick runner tags, or configure a Docker runner
- Set up multi-environment deployment pipelines and protected variables

## How-to

In Claude Code or Codex, just ask — "gitlab pipeline", "ci/cd config",
"gitlab-runner", "glab", "pipeline failed", "job timeout", "fix CI" —
the skill triggers automatically, or invoke it directly as the
`srepowers-infra:gitlab-cicd` command.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — pipeline authoring structure, key concepts, and modern
  `rules`; runner management (status, common runner types, tags, Docker
  config); `glab` CLI quick reference; the four-step failed-pipeline
  debugging workflow; CI/CD variable scoping and protection levels;
  anti-patterns

---
Last Updated: 2026-09-14
