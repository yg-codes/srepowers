# Cost Allocation and Tagging

## Overview

Cost allocation enables chargeback, showback, and accountability by attributing costs to teams, projects, and environments.

## Tagging Strategy

### Required Tags

| Tag Key | Purpose | Example |
|---------|---------|---------|
| `Owner` | Responsible team/person | `team-platform` |
| `Project` | Business project | `checkout-redesign` |
| `Environment` | Deployment stage | `production`, `staging`, `dev` |
| `CostCenter` | Billing code | `CC-12345` |
| `Application` | Service name | `api-gateway` |

### Optional Tags

| Tag Key | Purpose | Example |
|---------|---------|---------|
| `Customer` | Multi-tenant attribution | `acme-corp` |
| `Compliance` | Regulatory scope | `pci-dss`, `hipaa` |
| `DataClassification` | Data sensitivity | `confidential`, `public` |

## AWS Cost Allocation

### Tag-based Cost Reports

```bash
# Enable cost allocation tags
aws ce update-cost-allocation-tags-status \
  --tag-keys Owner Environment Project \
  --status Active

# Get costs by tag
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

### Cost Categories

```bash
# Create cost category for chargeback
aws ce create-cost-category-definition \
  --name "BusinessUnit" \
  --rule-version CostCategoryExpression.v1 \
  --rules file://cost-category-rules.json
```

## GCP Labels

```bash
# Apply labels to GCE instance
gcloud compute instances update my-instance \
  --labels=environment=production,team=platform

# Query costs by label
gcloud beta billing accounts list --format="table(name,displayName)"
```

## Azure Tags

```bash
# Apply tags to resource
az resource tag --ids /subscriptions/.../resourceGroups/myRG \
  --tags Environment=Production Team=Platform

# Query costs by tag
az consumption usage list --start-date 2026-01-01 --end-date 2026-01-31
```

## Chargeback Models

### Direct Chargeback

- 100% of costs assigned to consuming team
- Best for dedicated resources

### Proportional Allocation

- Shared costs distributed by usage percentage
- Good for multi-tenant services

### Tiered Allocation

- Fixed base cost + variable usage cost
- Balances predictability with fairness

## Showback vs Chargeback

| Model | Description | Impact |
|-------|-------------|--------|
| Showback | Visibility only, no billing | Awareness building |
| Chargeback | Actual budget transfer | Accountability |

## Tagging Compliance

### Compliance Rate Calculation

```
Compliance Rate = (Tagged Resources / Total Resources) × 100

Target: > 95% compliance for required tags
```

### Enforcement Strategies

1. **Preventive**: Deny untagged resources via IAM/IaC
2. **Detective**: Alert on missing tags
3. **Corrective**: Auto-tag based on rules

## Cost Allocation Report Template

```markdown
## Monthly Cost Allocation Report - [Month]

### Summary by Team
| Team | Cost | % of Total | Trend |
|------|------|------------|-------|
| Platform | $X | Y% | ↑↓ |
| Backend | $X | Y% | ↑↓ |

### Untagged Resources
| Service | Resource | Estimated Cost | Action |
|---------|----------|----------------|--------|
| EC2 | i-xxx | $X | Tag or terminate |

### Recommendations
1. [Optimization opportunity]
2. [Compliance issue]
```
