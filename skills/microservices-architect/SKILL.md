---
name: microservices-architect
description: Use when designing distributed systems, decomposing monoliths, or implementing microservices patterns. Invoke for service boundaries, DDD, saga patterns, event sourcing, service mesh, distributed tracing.
---

# Microservices Architect

## When to Use This Skill

- Decomposing monoliths into microservices
- Defining service boundaries and bounded contexts
- Designing inter-service communication patterns
- Implementing resilience patterns (circuit breakers, retries, bulkheads)
- Setting up service mesh (Istio, Linkerd)
- Designing event-driven architectures
- Implementing distributed transactions (Saga, CQRS)
- Establishing observability (tracing, metrics, logging)

## Core Workflow

1. **Domain Analysis** - Apply DDD to identify bounded contexts and service boundaries
2. **Communication Design** - Choose sync/async patterns, protocols (REST, gRPC, events)
3. **Data Strategy** - Database per service, event sourcing, eventual consistency
4. **Resilience** - Circuit breakers, retries, timeouts, bulkheads, fallbacks
5. **Observability** - Distributed tracing, correlation IDs, centralized logging
6. **Deployment** - Container orchestration, service mesh, progressive delivery

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Service Boundaries | `references/decomposition.md` | Monolith decomposition, bounded contexts, DDD |
| Communication | `references/communication.md` | REST vs gRPC, async messaging, event-driven |
| Resilience Patterns | `references/patterns.md` | Circuit breakers, saga, bulkhead, retry strategies |
| Data Management | `references/data.md` | Database per service, event sourcing, CQRS |
| Observability | `references/observability.md` | Distributed tracing, correlation IDs, metrics |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "This service can call that one directly" | Define contracts first. Direct coupling creates distributed monoliths. |
| "Distributed transactions are fine" | Prefer sagas. Distributed transactions don't scale. |
| "One database per service is overkill" | Database per service. Shared databases create hidden coupling. |
| "Service mesh is too complex" | Evaluate complexity vs. observability and security gains. |
| "Synchronous calls are simpler" | Async where possible. Synchronous chains amplify failures. |
| "This doesn't need circuit breaking" | Circuit breakers on all external calls. Cascading failures kill. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When designing microservices architecture, provide:
1. Service boundary diagram with bounded contexts
2. Communication patterns (sync/async, protocols)
3. Data ownership and consistency model
4. Resilience patterns for each integration point
5. Deployment and infrastructure requirements

## Knowledge Reference

Domain-driven design, bounded contexts, event storming, REST/gRPC, message queues (Kafka, RabbitMQ), service mesh (Istio, Linkerd), Kubernetes, circuit breakers, saga patterns, event sourcing, CQRS, distributed tracing (Jaeger, Zipkin), API gateways, eventual consistency, CAP theorem