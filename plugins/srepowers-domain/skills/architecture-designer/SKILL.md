---
name: architecture-designer
description: Use when designing new system architecture, reviewing existing designs, or making architectural decisions. Invoke for system design, architecture review, design patterns, ADRs, scalability planning.
---

# Architecture Designer

## When to Use This Skill

- Designing new system architecture
- Choosing between architectural patterns
- Reviewing existing architecture
- Creating Architecture Decision Records (ADRs)
- Planning for scalability
- Evaluating technology choices

## Core Workflow

1. **Understand requirements** - Functional, non-functional, constraints
2. **Identify patterns** - Match requirements to architectural patterns
3. **Design** - Create architecture with trade-offs documented
4. **Document** - Write ADRs for key decisions
5. **Review** - Validate with stakeholders

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Architecture Patterns | `references/architecture-patterns.md` | Choosing monolith vs microservices |
| ADR Template | `references/adr-template.md` | Documenting decisions |
| System Design | `references/system-design.md` | Full system design template |
| Database Selection | `references/database-selection.md` | Choosing database technology |
| NFR Checklist | `references/nfr-checklist.md` | Gathering non-functional requirements |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "We can design as we go" | Design before code. Architecture decisions are expensive to reverse. |
| "This doesn't need a diagram" | Always diagram. Visual communication prevents misunderstanding. |
| "YAGNI, skip the interface" | Interfaces at boundaries. Internal flexibility vs external stability. |
| "Monolith first is always right" | Match architecture to team topology and scale requirements. |
| "Performance optimization can come later" | Design for target scale. Rearchitecting under load fails. |
| "No need for ADRs on this decision" | Document decisions. Future you will thank present you. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When designing architecture, provide:
1. Requirements summary (functional + non-functional)
2. High-level architecture diagram
3. Key decisions with trade-offs (ADR format)
4. Technology recommendations with rationale
5. Risks and mitigation strategies

## Knowledge Reference

Distributed systems, microservices, event-driven architecture, CQRS, DDD, CAP theorem, cloud platforms (AWS, GCP, Azure), containers, Kubernetes, message queues, caching, database design