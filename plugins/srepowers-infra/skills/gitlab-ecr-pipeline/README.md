# gitlab-ecr-pipeline

Generate GitLab CI/CD pipelines that push container images to Amazon ECR,
in two shapes: build an image from a Containerfile/Dockerfile in the repo,
or pull an upstream image, re-tag it, and mirror it into ECR. Both patterns
use Podman instead of Docker to avoid Docker-in-Docker issues on GitLab
runners. Ships as `srepowers-infra:gitlab-ecr-pipeline`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Build and push a project's container image to ECR from a GitLab pipeline
- Mirror an upstream/third-party image into your own ECR repository
- Create the ECR repository the pipeline pushes to
- Troubleshoot push failures: Access Denied, "no basic auth credentials",
  "link is not supported", or image-pull failures in the cluster

## How-to

In Claude Code or Codex, just ask — "ECR pipeline", "push image to ECR",
"mirror image to ECR" — or invoke it directly as the
`srepowers-infra:gitlab-ecr-pipeline` command. The skill first identifies
which of the two workflows fits, then fills the matching template.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

- `SKILL.md` — workflow selection table; both pipeline templates inline;
  ECR login, tag, and version-tagging patterns; why Podman; ECR repository
  creation; troubleshooting; pointers to the container-cicd-reference skill
  for ECR setup and cross-account details
- `references/build-push-template.yml` — complete Build & Push pipeline
- `references/mirror-push-template.yml` — complete Mirror & Push pipeline

---
Last Updated: 2026-09-14
