---
name: platform-engineer
description: Use when building or improving internal developer platforms (IDPs), designing self-service infrastructure, or optimizing developer workflows - Backstage, golden paths, service catalogs
---

# Platform Engineer

## When to Use This Skill

- Building internal developer platforms (IDPs)
- Implementing self-service infrastructure
- Creating golden path templates for services
- Setting up Backstage developer portals
- Designing service catalogs and software templates
- Improving developer experience and productivity
- Implementing GitOps workflows at scale
- Multi-tenant platform architecture
- Platform metrics and adoption tracking

## Core Workflow

1. **Assess** - Understand developer needs, pain points, and existing tools
2. **Design** - Platform architecture, self-service capabilities, golden paths
3. **Implement** - Developer portal, service templates, automation
4. **Enable** - Onboarding, documentation, training
5. **Measure** - Adoption metrics, developer satisfaction, platform SLOs

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Platform Architecture | `references/idp-architecture.md` | Multi-tenancy, RBAC, resource isolation, cost allocation |
| Golden Paths | `references/golden-paths.md` | Service scaffolding, CI/CD templates, best practices enforcement |
| Developer Portal | `references/developer-portal.md` | Backstage implementation, software templates, service catalog |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Just give them admin access" | Least privilege. Self-service within guardrails. |
| "This platform doesn't need docs" | Internal platforms need docs more than external ones. |
| "Skip the golden path, teams can figure it out" | Paved paths reduce cognitive load and increase velocity. |
| "Manual provisioning is fine for now" | Automate from day one. Manual processes don't scale. |
| "We'll add observability later" | Platform observability is foundational, not optional. |
| "One size fits all" | Provide sensible defaults with escape hatches. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Platform Engineering Targets

| Metric | Target |
|--------|--------|
| Self-service rate | >90% |
| Provisioning time | <5 minutes |
| Platform uptime | 99.9% |
| API response time | <200ms |
| Documentation coverage | 100% |
| Developer onboarding | <1 day |
| Developer satisfaction | >4.5/5 |

## Output Templates

When building platform capabilities, provide:
1. Architecture diagram and component overview
2. Self-service capability specifications
3. Golden path templates with examples
4. RBAC and multi-tenancy configuration
5. Platform metrics and monitoring setup
6. Developer documentation and onboarding guides

## Knowledge Reference
