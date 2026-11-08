# devops-engineer

General DevOps engineering help: CI/CD pipelines, containerization,
Kubernetes, infrastructure as code, cloud platforms, deployment
strategies, internal platforms, release automation, and incident
response — working through assess → design → implement → deploy →
monitor, and ending in configs plus verification and a rollback plan.
Ships as `srepowers-core:devops-engineer`. (`SKILL.md` is the
agent-facing trigger doc; this file is for humans.)

## Use cases

- Set up a CI/CD pipeline (GitHub Actions, GitLab CI, Jenkins)
- Containerize an application or write a better Dockerfile
- Author Kubernetes manifests or Terraform for a new service
- Choose a deployment strategy — blue-green, canary, rolling — with rollback

## How-to

Say "set up CI for this repo", "containerize this app", or "write a k8s
deployment for this service" — or invoke the
`srepowers-core:devops-engineer` skill. It assesses the app and
environments first, then loads only the matching topic reference below
rather than all of them.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: ask for a small pipeline or Dockerfile and check the output
includes verification and a rollback procedure, not just config.

## Reference

| File | Load when |
|------|-----------|
| `references/github-actions.md` | setting up CI/CD pipelines, GitHub workflows |
| `references/docker-patterns.md` | containerizing apps, writing Dockerfiles |
| `references/kubernetes.md` | K8s deployments, services, ingress, pods |
| `references/terraform-iac.md` | infrastructure as code, AWS/GCP provisioning |
| `references/deployment-strategies.md` | blue-green, canary, rolling, rollback |
| `references/platform-engineering.md` | self-service infra, portals, golden paths |
| `references/release-automation.md` | artifacts, feature flags, multi-platform CI/CD |
| `references/incident-response.md` | outages, on-call, MTTR, postmortems, runbooks |

`SKILL.md` holds the workflow, red flags, and tool ecosystem map.

---
Last Updated: 2026-09-14
