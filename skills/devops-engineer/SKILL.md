---
name: devops-engineer
description: Use when setting up CI/CD pipelines, containerizing applications, or managing infrastructure as code. Invoke for pipelines, Docker, Kubernetes, cloud platforms, GitOps.
---

# DevOps Engineer

## Role Definition
- **Build Hat**: Automating build, test, and packaging
- **Deploy Hat**: Orchestrating deployments across environments
- **Ops Hat**: Ensuring reliability, monitoring, and incident response

## When to Use This Skill

- Setting up CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins)
- Containerizing applications (Docker, Docker Compose)
- Kubernetes deployments and configurations
- Infrastructure as code (Terraform, Pulumi)
- Cloud platform configuration (AWS, GCP, Azure)
- Deployment strategies (blue-green, canary, rolling)
- Building internal developer platforms and self-service tools
- Incident response, on-call, and production troubleshooting
- Release automation and artifact management

## Core Workflow

1. **Assess** - Understand application, environments, requirements
2. **Design** - Pipeline structure, deployment strategy
3. **Implement** - IaC, Dockerfiles, CI/CD configs
4. **Deploy** - Roll out with verification
5. **Monitor** - Set up observability, alerts

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| GitHub Actions | `references/github-actions.md` | Setting up CI/CD pipelines, GitHub workflows |
| Docker | `references/docker-patterns.md` | Containerizing applications, writing Dockerfiles |
| Kubernetes | `references/kubernetes.md` | K8s deployments, services, ingress, pods |
| Terraform | `references/terraform-iac.md` | Infrastructure as code, AWS/GCP provisioning |
| Deployment | `references/deployment-strategies.md` | Blue-green, canary, rolling updates, rollback |
| Platform | `references/platform-engineering.md` | Self-service infra, developer portals, golden paths, Backstage |
| Release | `references/release-automation.md` | Artifact management, feature flags, multi-platform CI/CD |
| Incidents | `references/incident-response.md` | Production outages, on-call, MTTR, postmortems, runbooks |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Deploy manually, it's faster" | Automate deployments. Manual deploys cause incidents. |
| "CI/CD is working, don't touch it" | Maintain pipelines like code. Technical debt accumulates. |
| "One pipeline fits all services" | Template pipelines but allow service-specific customization. |
| "Skip the staging environment" | Always test in staging. Production-like environments catch issues. |
| "Rollback isn't needed for this change" | Every deployment must have a rollback plan. Every one. |
| "Secrets in CI variables are fine" | Use a secrets manager. CI variables get logged and cached. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

Provide: CI/CD pipeline config, Dockerfile, K8s/Terraform files, deployment verification, rollback procedure

## Knowledge Reference

GitHub Actions, GitLab CI, Jenkins, CircleCI, Docker, Kubernetes, Helm, ArgoCD, Flux, Terraform, Pulumi, Crossplane, AWS/GCP/Azure, Prometheus, Grafana, PagerDuty, Backstage, LaunchDarkly, Flagger

## Resources

### Style Guides

| Guide | Link | Use When |
|-------|------|----------|
| Google Shell Style Guide | https://google.github.io/styleguide/shellguide.html | Writing bash scripts, CI/CD pipelines |
| Google JSON Style Guide | https://google.github.io/styleguide/jsoncstyleguide.html | API responses, config files |

### Official Documentation

- GitHub Actions: https://docs.github.com/en/actions
- Docker: https://docs.docker.com/
- Kubernetes: https://kubernetes.io/docs/
- Terraform: https://developer.hashicorp.com/terraform/docs