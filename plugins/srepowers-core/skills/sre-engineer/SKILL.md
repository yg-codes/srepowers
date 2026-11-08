---
name: sre-engineer
description: Use when defining SLIs/SLOs, managing error budgets, or building reliable systems at scale. Invoke for incident management, chaos engineering, toil reduction, capacity planning.
---

# SRE Engineer

## When to Use This Skill

- Defining SLIs/SLOs and error budgets
- Implementing reliability monitoring and alerting
- Reducing operational toil through automation
- Designing chaos engineering experiments
- Managing incidents and postmortems
- Building capacity planning models
- Establishing on-call practices

## Core Workflow

1. **Assess reliability** - Review architecture, SLOs, incidents, toil levels
2. **Define SLOs** - Identify meaningful SLIs and set appropriate targets
3. **Implement monitoring** - Build golden signal dashboards and alerting
4. **Automate toil** - Identify repetitive tasks and build automation
5. **Test resilience** - Design and execute chaos experiments

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| SLO/SLI | `references/slo-sli-management.md` | Defining SLOs, calculating error budgets |
| Error Budgets | `references/error-budget-policy.md` | Managing budgets, burn rates, policies |
| Monitoring | `references/monitoring-alerting.md` | Golden signals, alert design, dashboards |
| Automation | `references/automation-toil.md` | Toil reduction, automation patterns |
| Incidents | `references/incident-chaos.md` | Incident response, chaos engineering |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "100% availability is the target" | Define realistic SLOs. 100% is impossible and wastes budget. |
| "SLOs can wait until we have data" | Set SLOs based on user expectations, refine with data. |
| "Error budget is just a metric" | Error budget drives decisions. Freeze features when exhausted. |
| "Toil is just part of the job" | Measure and eliminate toil. Sustainable operations require automation. |
| "On-call doesn't need runbooks" | Runbooks reduce MTTR. Write them before you need them. |
| "Post-mortems are blame sessions" | Blameless post-mortems. Learning requires psychological safety. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing SRE practices, provide:
1. SLO definitions with SLI measurements and targets
2. Monitoring/alerting configuration (Prometheus, etc.)
3. Automation scripts (Python, Go, Terraform)
4. Runbooks with clear remediation steps
5. Brief explanation of reliability impact

## Knowledge Reference

SLO/SLI design, error budgets, golden signals (latency/traffic/errors/saturation), Prometheus/Grafana, chaos engineering (Chaos Monkey, Gremlin), toil reduction, incident management, blameless postmortems, capacity planning, on-call best practices

## Authoritative References

Google SRE book series (free online):

| Book | URL | Focus |
|------|-----|-------|
| **SRE Book** | https://sre.google/sre-book/table-of-contents/ | Foundational SRE principles, SLOs, incident response, on-call |
| **SRE Workbook** | https://sre.google/workbook/table-of-contents/ | Practical implementation, case studies, SLO construction |
| **Building Secure & Reliable Systems** | https://google.github.io/building-secure-and-reliable-systems/raw/toc.html | Security + reliability integration, design patterns |