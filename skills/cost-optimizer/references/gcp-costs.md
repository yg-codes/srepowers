# GCP Cost Optimization

## Cost Analysis Tools

- **Cloud Billing Reports** - Visualize spending trends
- **Budgets and Alerts** - Set spending thresholds
- **Recommender** - Automated optimization suggestions
- **BigQuery Export** - Detailed billing data analysis

## Compute Engine Optimization

### Machine Type Selection

| Family | Use Case | vCPU:Memory |
|--------|----------|-------------|
| e2 | Cost-optimized general purpose | 1:4 |
| n2 | Balanced performance | 1:4 |
| c2 | Compute-intensive | 1:2 |
| m2 | Memory-intensive | 1:8+ |

### Preemptible/Spot VMs

- Up to 91% discount
- 24-hour maximum runtime
- 30-second termination notice

```bash
# Create preemptible instance
gcloud compute instances create my-instance \
  --preemptible \
  --machine-type e2-medium
```

## Committed Use Discounts

| Commitment | Discount |
|------------|----------|
| 1-year | Up to 37% |
| 3-year | Up to 55% |

### Resource-based Commitments

```bash
# Purchase commitment
gcloud compute commitments create my-commitment \
  --region us-central1 \
  --plan 12-month \
  --resources vcpu=100,memory=400GB
```

## Cloud Storage Optimization

### Storage Classes

| Class | Use Case | Price |
|-------|----------|-------|
| Standard | Hot data | $0.020/GB |
| Nearline | < 30 days access | $0.010/GB |
| Coldline | < 90 days access | $0.004/GB |
| Archive | < 365 days access | $0.0012/GB |

## BigQuery Cost Optimization

- Use clustered tables
- Set maximum bytes billed
- Use materialized views
- Partition tables by date

## Network Cost Optimization

- Egress to same region: Free
- Egress to different region: $0.01-0.08/GB
- Internet egress: $0.12/GB (first 10TB)
