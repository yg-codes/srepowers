# goreleaser-pipeline

Configure and operate GoReleaser pipelines for building and releasing Go
binaries: `.goreleaser.yml` authoring, cross-compilation, GitLab CI/CD or
GitHub Actions integration, tagging, and build-failure troubleshooting.
Core rule: build reproducibly, release from CI only, tag before release.
Ships as `srepowers-infra:goreleaser-pipeline`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Create or modify a `.goreleaser.yml` for a CLI tool or a daemon/service
  (RPM + systemd unit)
- Wire a release pipeline on GitLab (project access token required —
  `CI_JOB_TOKEN` is not enough) or GitHub Actions
- Cut a release: prepare, tag, monitor, verify — and recover from a
  wrong-commit tag
- Inject version metadata at build time via `ldflags`

## How-to

In Claude Code or Codex, just ask — "goreleaser", "go release", "release
binary", ".goreleaser.yml", "gitlab release" — the skill triggers
automatically, or invoke it directly as the
`srepowers-infra:goreleaser-pipeline` command.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — minimal and full `.goreleaser.yml` reference; GitLab
  integration (variables, token minting, `v*` tag protection, API release
  verification, gotchas); GitHub Actions; release workflow; debugging;
  `ldflags`
- `templates/gitlab/gitlab-ci.yml` — ready-to-fill release pipeline
  (fill `{{GO_IMAGE}}` from `go.mod`; pinned `GORELEASER_VERSION`)
- `templates/gitlab/goreleaser-cli.yaml` — CLI shape: `force_token: gitlab`
  + `gitlab_urls`, publishes to the Generic Package Registry
- `templates/gitlab/goreleaser-daemon.yaml` — daemon/service shape:
  linux-only, nfpms RPM + systemd unit
- `templates/github/goreleaser-cli.yaml` — GitHub Actions variant, CLI shape
- `templates/github/goreleaser-daemon.yaml` — GitHub Actions variant, daemon
- `templates/github/release.yml` — tag-triggered release workflow
  (`contents: write`; `GITHUB_TOKEN` is injected automatically)

---
Last Updated: 2026-09-14
