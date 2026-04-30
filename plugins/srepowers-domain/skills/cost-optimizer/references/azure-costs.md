# Azure Cost Optimization

## Cost Analysis Tools

- **Cost Management + Billing** - Central cost dashboard
- **Azure Advisor** - Optimization recommendations
- **Budgets** - Spending thresholds and alerts
- **Cost Analysis** - Detailed spending views

## Virtual Machine Optimization

### VM Size Selection

| Family | Use Case | vCPU:Memory |
|--------|----------|-------------|
| B-series | Burstable workloads | 1:4 |
| D-series | General purpose | 1:4 |
| F-series | Compute-optimized | 1:2 |
| E-series | Memory-optimized | 1:8 |

### Spot VMs

- Up to 90% discount
- 30-second eviction notice
- Good for batch jobs, dev/test

```bash
# Create spot VM
az vm create \
  --name my-vm \
  --resource-group myRG \
  --image Ubuntu2204 \
  --priority Spot \
  --max-price 0.05
```

## Reserved VM Instances

| Commitment | Discount |
|------------|----------|
| 1-year | Up to 40% |
| 3-year | Up to 72% |

### Purchase Reserved Instance

```bash
az reservations reservation-order purchase \
  --reservation-order-id <order-id> \
  --sku Standard_B2s \
  --location eastus \
  --quantity 1 \
  --term P1Y
```

## Storage Optimization

### Blob Storage Tiers

| Tier | Use Case | Price |
|------|----------|-------|
| Hot | Frequent access | $0.0184/GB |
| Cool | Infrequent access | $0.01/GB |
| Cold | Rare access | $0.0045/GB |
| Archive | Long-term archive | $0.00099/GB |

### Lifecycle Management

```json
{
  "rules": [
    {
      "name": "archive-old",
      "enabled": true,
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": { "daysAfterModificationGreaterThan": 30 },
            "tierToArchive": { "daysAfterModificationGreaterThan": 90 },
            "delete": { "daysAfterModificationGreaterThan": 365 }
          }
        }
      }
    }
  ]
}
```

## Azure Hybrid Benefit

- Bring your own Windows Server and SQL licenses
- Up to 85% savings on Windows VMs
- Up to 55% savings on SQL Database
