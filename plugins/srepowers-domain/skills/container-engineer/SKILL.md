---
name: container-engineer
description: Use when building, optimizing, or securing container images and orchestration for production environments. Invoke for Docker, containerd, multi-stage builds, image size reduction, security hardening, supply chain security, Docker Compose, registry management, Kubernetes runtime.
---

# Container Engineer

## When to Use This Skill

- Building optimized multi-stage Dockerfiles
- Reducing container image size
- Hardening container security (users, capabilities, seccomp)
- Implementing supply chain security (SBOM, cosign, SLSA)
- Creating Docker Compose stacks for local development or production
- Managing container registries and image promotion
- Troubleshooting container build and runtime issues
- Implementing DHI (Docker Host Intrusion) detection

## Core Workflow

1. **Analyze requirements** - Understand application dependencies, runtime needs, security requirements
2. **Design Dockerfile** - Choose base images, plan stages, optimize layers
3. **Implement security** - Minimal users, capability dropping, secret management
4. **Optimize** - Layer caching, size reduction, build speed
5. **Validate** - Security scanning, SBOM generation, signing

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Dockerfile Patterns | `references/dockerfile-patterns.md` | Multi-stage builds, layer optimization, .dockerignore |
| Security Hardening | `references/security-hardening.md` | Image scanning, vulnerability remediation, secret management, DHI |
| Supply Chain | `references/supply-chain.md` | SBOM generation, cosign signing, SLSA provenance |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Use latest tag, it's simpler" | Pin image versions. `latest` causes non-reproducible builds. |
| "Root user is fine in the container" | Run non-root. Principle of least privilege. |
| "One big Dockerfile is easier" | Multi-stage builds. Smaller images = faster deploys + smaller attack surface. |
| "Base image doesn't matter" | Use minimal bases (distroless/alpine). Every package is attack surface. |
| "Skip the vulnerability scan" | Scan every image. Known CVEs in containers cause breaches. |
| "Build context includes everything" | .dockerignore rigorously. Large contexts slow builds and leak secrets. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Docker solutions, provide:
1. Complete Dockerfile with multi-stage structure
2. .dockerignore file for the project
3. docker-compose.yml if orchestration is needed
4. Build and run commands with explanations
5. Security scan results and remediation notes

## Knowledge Reference

Docker Engine, Docker BuildKit, multi-stage builds, Alpine vs Distroless, layer caching, .dockerignore, HEALTHCHECK, non-root containers, capability dropping, seccomp profiles, Docker Content Trust, cosign, SBOM (syft, trivy), SLSA provenance, Docker Compose, container registries (ECR, GCR, Docker Hub), vulnerability scanning (Trivy, Grype, Snyk)
