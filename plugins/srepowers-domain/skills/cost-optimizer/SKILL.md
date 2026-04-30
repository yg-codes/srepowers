---
name: cost-optimizer
description: Use when analyzing cloud costs, optimizing resource spending, or planning reserved capacity. Invoke for AWS/GCP/Azure cost analysis, right-sizing, reserved instances, spot instances, cost allocation, and FinOps practices.
---

# Cloud Cost Optimizer

## When to Use This Skill

- Analyzing cloud bills and identifying cost drivers
- Right-sizing over-provisioned resources (EC2, VMs, databases)
- Planning and purchasing reserved instances or savings plans
- Implementing spot instance strategies for non-critical workloads
- Setting up cost allocation and chargeback models
- Optimizing storage costs (S3 lifecycle, EBS volumes)
- Reducing data transfer and egress costs
- Building cost dashboards and budgets
- Implementing auto-shutdown for dev/test environments
- Analyzing container resource efficiency (EKS/GKE/AKS)

## Core Workflow

1. **Analyze** - Review billing data, identify top cost drivers
2. **Categorize** - Tag resources, allocate costs by team/project
3. **Identify waste** - Unused resources, over-provisioning, idle capacity
4. **Optimize** - Right-size, reserved capacity, spot instances
5. **Automate** - Auto-scaling, shutdown schedules, lifecycle policies
6. **Monitor** - Budget alerts, anomaly detection, cost dashboards

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| AWS Cost Optimization | `references/aws-costs.md` | EC2, RDS, S3, data transfer, Savings Plans |
| GCP Cost Optimization | `references/gcp-costs.md` | Compute Engine, Cloud Storage, committed use |
| Azure Cost Optimization | `references/azure-costs.md` | VMs, SQL Database, reserved instances |
| Right-Sizing | `references/right-sizing.md` | Instance types, utilization analysis |
| Reserved Capacity | `references/reserved-capacity.md` | RI planning, break-even analysis |
| Spot/Preemptible | `references/spot-instances.md` | Spot strategies, interruption handling |
| Cost Allocation | `references/cost-allocation.md` | Tagging, chargeback, showback |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "We'll optimize costs later" | Cost optimization at design time. Retrofitting is expensive. |
| "Reserved instances are too committal" | Analyze usage patterns. RIs/Savings Plans for stable workloads. |
| "This resource is cheap, don't bother" | Small costs compound. Right-size everything. |
| "Dev environments don't need cost controls" | Dev often exceeds prod spend. Enforce budgets everywhere. |
| "Just scale up when it's slow" | Profile first. Scaling up hides architectural problems. |
| "Spot instances are too risky" | Spot for stateless/fault-tolerant. 60-90% savings are significant. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

### Cost Analysis Report
```markdown
## Cost Analysis: [Scope]

### Current State
- Monthly spend: $X
- Top 3 cost drivers: [service] $Y ([Z]%)
- Untagged resources: $W ([V]%)

### Optimization Opportunities
| Resource | Current | Recommended | Savings | Risk |
|----------|---------|-------------|---------|------|
| [type] | [size] | [size] | $X/month | Low |

### Reserved Capacity Recommendations
| Service | Instance Type | Term | Upfront | Monthly Savings | Break-even |
|---------|---------------|------|---------|-----------------|------------|
| [service] | [type] | 1-year | $X | $Y | Z months |

### Implementation Plan
1. [Quick wins - immediate]
2. [Medium-term optimizations]
3. [Long-term architecture changes]
```

## Knowledge Reference

AWS Cost Explorer, AWS Budgets, AWS Savings Plans, Reserved Instances, Spot Instances, GCP Billing, GCP Committed Use Discounts, Azure Cost Management, Azure Reserved VM Instances, FinOps Foundation principles, tagging strategies, unit economics, cloud pricing models, amortization calculations
