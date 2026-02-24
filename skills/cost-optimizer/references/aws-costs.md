# AWS Cost Optimization

## Cost Analysis Tools

- **AWS Cost Explorer** - Visualize and analyze costs over time
- **AWS Budgets** - Set cost and usage budgets with alerts
- **Cost and Usage Report (CUR)** - Detailed cost data for analysis
- **Trusted Advisor** - Optimization recommendations

## EC2 Cost Optimization

### Right-Sizing

```bash
# Get CPU utilization for instances
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --statistics Average \
  --period 86400 \
  --start-time $(date -d '7 days ago' -Is) \
  --end-time $(date -Is)
```

### Instance Types Cost Comparison

| Type | vCPU | Memory | On-Demand/hr | 1-Year RI | Savings |
|------|------|--------|--------------|-----------|---------|
| t3.medium | 2 | 4GB | $0.0416 | $0.027 | 35% |
| m5.large | 2 | 8GB | $0.096 | $0.062 | 35% |
| c5.large | 2 | 4GB | $0.085 | $0.055 | 35% |

### Spot Instances

```bash
# Get spot pricing history
aws ec2 describe-spot-price-history \
  --instance-types t3.medium \
  --availability-zones us-east-1a \
  --start-time $(date -d '1 day ago' -Is)
```

## RDS Cost Optimization

### Instance Sizing

| DB Instance Class | vCPU | Memory | On-Demand/hr |
|-------------------|------|--------|--------------|
| db.t3.medium | 2 | 4GB | $0.068 |
| db.r5.large | 2 | 16GB | $0.26 |
| db.m5.large | 2 | 8GB | $0.17 |

### Storage Optimization

- Use GP3 instead of GP2 (20% cheaper, better performance)
- Delete unused snapshots
- Set retention policies for automated backups

## S3 Cost Optimization

### Storage Classes

| Class | Use Case | Price (per GB/month) |
|-------|----------|---------------------|
| Standard | Frequently accessed | $0.023 |
| Intelligent-Tiering | Unknown patterns | $0.023 + monitoring |
| Standard-IA | Infrequent access | $0.0125 |
| Glacier Instant | Archive | $0.004 |

### Lifecycle Policies

```json
{
  "Rules": [
    {
      "ID": "MoveToIA",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 180,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

## Data Transfer Costs

- **Same AZ**: Free
- **Cross-AZ**: $0.01/GB
- **Internet egress**: $0.09/GB (first 100TB/month)
- **VPC Peering**: $0.01/GB

### Optimization Tips

1. Keep data in same AZ when possible
2. Use CloudFront for external traffic
3. Use VPC endpoints for S3/DynamoDB (avoid NAT gateway charges)

## Savings Plans vs Reserved Instances

| Feature | Savings Plans | Reserved Instances |
|---------|---------------|-------------------|
| Commitment | 1 or 3 years | 1 or 3 years |
| Flexibility | Instance family, region, AZ | Specific instance type |
| Savings | Up to 72% | Up to 75% |
| Best for | Dynamic workloads | Stable, predictable workloads |
