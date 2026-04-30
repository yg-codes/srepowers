# Reserved Capacity Planning

## Overview

Reserved Instances (RI) and Savings Plans offer significant discounts (up to 75%) in exchange for 1 or 3-year commitments.

## Reserved Instances vs Savings Plans

| Feature | Reserved Instances | Savings Plans |
|---------|-------------------|---------------|
| Discount | Up to 75% | Up to 72% |
| Flexibility | Instance-specific | Family/region flexible |
| Payment | All, Partial, No upfront | Same |
| Best for | Stable, predictable | Dynamic workloads |

## Commitment Analysis

### Break-Even Calculation

```
Break-even months = (RI cost - On-demand cost) / Monthly savings

Example:
- On-demand: $100/month
- 1-year RI: $600 (no upfront) = $50/month
- Savings: $50/month
- Break-even: Immediate (no upfront)
```

### Utilization Threshold

Before purchasing reserved capacity:

| Utilization | Recommendation |
|-------------|----------------|
| < 50% | Do not purchase - right-size first |
| 50-70% | Consider convertible RI |
| 70-85% | Standard RI recommended |
| > 85% | 3-year term justified |

## AWS Reserved Instance Types

### Standard Reserved Instances

- Fixed instance type, AZ, and tenancy
- Up to 75% discount
- Cannot change instance family

### Convertible Reserved Instances

- Can exchange for different instance types
- Up to 54% discount
- Good for evolving workloads

### Scheduled Reserved Instances

- Reserve capacity for specific time windows
- Good for batch jobs, scheduled workloads

## Savings Plans

### Compute Savings Plan

- Applies to EC2, Fargate, Lambda
- Instance family and region flexible
- Up to 72% discount

### EC2 Instance Savings Plan

- EC2 only
- Instance family flexible within region
- Up to 72% discount

## GCP Committed Use Discounts

| Commitment | Discount |
|------------|----------|
| 1-year | Up to 37% |
| 3-year | Up to 55% |

### Machine-type Flexibility

- Committed vCPUs and memory can be applied across instance families
- More flexible than AWS RIs

## Azure Reserved VM Instances

| Commitment | Discount |
|------------|----------|
| 1-year | Up to 40% |
| 3-year | Up to 72% |

## Planning Checklist

- [ ] Analyze 90+ days of usage history
- [ ] Identify workloads with stable demand
- [ ] Calculate break-even point
- [ ] Compare RI vs Savings Plans
- [ ] Consider 3-year only for highly stable workloads
- [ ] Review cancellation policies
- [ ] Set reminders for renewal/expiration
- [ ] Track realized vs projected savings
