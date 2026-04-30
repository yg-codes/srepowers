---
name: chaos-engineer
description: Use when designing chaos experiments, implementing failure injection frameworks, or conducting game day exercises. Invoke for chaos experiments, resilience testing, blast radius control, game days, antifragile systems.
---

# Chaos Engineer

## When to Use This Skill

- Designing and executing chaos experiments
- Implementing failure injection frameworks (Chaos Monkey, Litmus, etc.)
- Planning and conducting game day exercises
- Building blast radius controls and safety mechanisms
- Setting up continuous chaos testing in CI/CD
- Improving system resilience based on experiment findings

## Core Workflow

1. **System Analysis** - Map architecture, dependencies, critical paths, and failure modes
2. **Experiment Design** - Define hypothesis, steady state, blast radius, and safety controls
3. **Execute Chaos** - Run controlled experiments with monitoring and quick rollback
4. **Learn & Improve** - Document findings, implement fixes, enhance monitoring
5. **Automate** - Integrate chaos testing into CI/CD for continuous resilience

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Experiments | `references/experiment-design.md` | Designing hypothesis, blast radius, rollback |
| Infrastructure | `references/infrastructure-chaos.md` | Server, network, zone, region failures |
| Kubernetes | `references/kubernetes-chaos.md` | Pod, node, Litmus, chaos mesh experiments |
| Tools & Automation | `references/chaos-tools.md` | Chaos Monkey, Gremlin, Pumba, CI/CD integration |
| Game Days | `references/game-days.md` | Planning, executing, learning from game days |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Production is too risky for chaos" | Chaos in prod finds real issues. Start small, expand. |
| "We don't need a hypothesis" | Always hypothesize first. Chaos without hypothesis is just breaking things. |
| "Skip the blast radius limit" | Constrain blast radius. Uncontrolled chaos causes outages. |
| "Steady state is obvious" | Define and measure steady state explicitly. Assumptions mislead. |
| "One big experiment covers everything" | Small, targeted experiments. Isolate variables. |
| "We can skip the abort conditions" | Always define abort criteria before starting. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing chaos engineering, provide:
1. Experiment design document (hypothesis, metrics, blast radius)
2. Implementation code (failure injection scripts/manifests)
3. Monitoring setup and alert configuration
4. Rollback procedures and safety controls
5. Learning summary and improvement recommendations

## Knowledge Reference

Chaos Monkey, Litmus Chaos, Chaos Mesh, Gremlin, Pumba, toxiproxy, chaos experiments, blast radius control, game days, failure injection, network chaos, infrastructure resilience, Kubernetes chaos, organizational resilience, MTTR reduction, antifragile systems