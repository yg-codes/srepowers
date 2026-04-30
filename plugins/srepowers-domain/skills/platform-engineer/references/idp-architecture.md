# IDP Architecture

Internal Developer Platform architecture patterns for multi-tenancy, resource isolation, RBAC, and cost allocation.

## Platform Principles

- **Self-service first**: Reduce manual work to <10%
- **Golden paths**: Pre-approved, opinionated templates
- **Developer experience**: Measure and optimize productivity
- **Platform as product**: Treat with product mindset

## Multi-Tenant Architecture

### Namespace-Based Isolation

```yaml
# Policy: Resource quotas per tenant
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: team-payments
spec:
  hard:
    requests.cpu: "20"
    requests.memory: 40Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"
```

### RBAC Configuration

```yaml
# RBAC: Namespace admin role
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-admin
  namespace: team-payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: namespace-admin
subjects:
  - kind: Group
    name: team-payments
```

### Network Policies

```yaml
# Isolate tenant namespaces
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
  namespace: team-payments
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              tenant: payments
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              tenant: payments
```

## Self-Service with Crossplane

### Composition for Database Provisioning

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: postgres-database
spec:
  compositeTypeRef:
    apiVersion: platform.example.com/v1alpha1
    kind: Database
  resources:
    - name: rds-instance
      base:
        apiVersion: rds.aws.crossplane.io/v1alpha1
        kind: DBInstance
        spec:
          forProvider:
            dbInstanceClass: db.t3.micro
            engine: postgres
            engineVersion: "15"
            masterUsername: admin
            allocatedStorage: 20
```

### Composite Resource Definition

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: databases.platform.example.com
spec:
  group: platform.example.com
  names:
    kind: Database
    plural: databases
  versions:
    - name: v1alpha1
      served: true
      referenceable: true
      schema:
        openAPIV3Schema:
          properties:
            spec:
              properties:
                size:
                  type: string
                  enum: [small, medium, large]
              required: [size]
```

## Cost Allocation

### Kubecost Configuration

```yaml
# kubecost/allocation.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cost-allocation
data:
  allocation.json: |
    {
      "defaultLabels": {
        "team": "team",
        "service": "app",
        "environment": "env"
      },
      "shareNamespaces": ["kube-system"],
      "shareCost": "weighted"
    }
```

### Resource Labels for Cost Tracking

```yaml
# Required labels for all resources
metadata:
  labels:
    team: payments
    service: payment-api
    environment: production
    cost-center: "12345"
```

## Platform APIs

### Self-Service Provisioning API

```python
# Platform API for self-service provisioning
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI()

class ServiceRequest(BaseModel):
    name: str
    environment: str
    language: str
    database: bool = False

@app.post("/api/v1/services")
async def create_service(request: ServiceRequest):
    # Validate and enqueue
    task = platform.provision_service(
        name=request.name,
        env=request.environment,
        template=f"golden-path-{request.language}"
    )
    return {"task_id": task.id, "status": "provisioning"}

@app.get("/api/v1/services/{name}/status")
async def service_status(name: str):
    return {
        "status": "running",
        "url": f"https://{name}.example.com",
        "health": "healthy",
        "cost_mtd": "$142.50"
    }
```

## GitOps Repository Structure

```
gitops/
├── apps/
│   ├── production/
│   │   ├── payment-service/
│   │   └── auth-service/
│   └── staging/
│       └── payment-service/
├── infrastructure/
│   ├── clusters/
│   │   ├── prod-us-east/
│   │   └── prod-eu-west/
│   └── base/
│       ├── ingress/
│       └── monitoring/
└── platform/
    ├── backstage/
    ├── argocd/
    └── vault/
```

## Platform Metrics

### Prometheus Recording Rules

```yaml
# prometheus/platform-metrics.yaml
groups:
  - name: platform
    rules:
      # Self-service adoption rate
      - record: platform:self_service:rate
        expr: |
          sum(rate(platform_provision_automated[1h]))
          /
          sum(rate(platform_provision_total[1h]))

      # Provisioning time P95
      - record: platform:provision:p95
        expr: |
          histogram_quantile(0.95,
            rate(platform_provision_duration_bucket[5m]))

      # Golden path adoption
      - record: platform:golden_path:adoption
        expr: |
          count(service{template="golden-path"})
          / count(service)
```

## Best Practices

- Design for self-service from day one
- Implement proper RBAC before opening access
- Use namespace-based isolation for multi-tenancy
- Track cost allocation per team/service
- Maintain platform SLOs (99.9% uptime)
- Provide APIs, not just UIs
- Document all platform capabilities
- Measure and publish platform metrics
