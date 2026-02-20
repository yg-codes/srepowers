# Developer Portal

Backstage implementation, software templates, and service catalog configuration.

## Backstage Overview

Backstage is an open-source developer portal that provides:
- **Software Catalog**: Inventory of all services, APIs, and resources
- **Software Templates**: Self-service scaffolding for new projects
- **TechDocs**: Documentation powered by Markdown/MDX
- **Plugins**: Extensible ecosystem for integrations

## Service Catalog

### Component Registration

```yaml
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: payment-service
  description: Payment processing service
  annotations:
    github.com/project-slug: org/payment-service
    pagerduty.com/integration-key: abc123
    grafana/dashboard-selector: service=payment
    datadoghq.com/dashboard-url: https://app.datadoghq.com/dashboard/abc
  tags:
    - go
    - payments
    - critical
  links:
    - url: https://payment-service.docs.example.com
      title: Documentation
spec:
  type: service
  lifecycle: production
  owner: payments-team
  system: checkout
  dependsOn:
    - resource:default/payment-db
    - component:default/auth-service
  providesApis:
    - payment-api
  consumesApis:
    - auth-api
```

### API Definition

```yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: payment-api
  description: Payment processing API
spec:
  type: openapi
  lifecycle: production
  owner: payments-team
  system: checkout
  definition:
    $text: https://github.com/org/payment-service/blob/main/openapi.yaml
```

### Resource Definition

```yaml
apiVersion: backstage.io/v1alpha1
kind: Resource
metadata:
  name: payment-db
  description: PostgreSQL database for payments
  annotations:
    crossplane.io/composition: postgres-database
spec:
  type: database
  lifecycle: production
  owner: payments-team
  system: checkout
```

## Software Templates

### Microservice Template

```yaml
# templates/microservice/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: microservice-template
  title: Microservice Golden Path
  description: Create a new microservice with CI/CD, monitoring, and documentation
spec:
  owner: platform-team
  type: service
  parameters:
    - title: Service Information
      required:
        - name
        - owner
        - language
      properties:
        name:
          title: Service Name
          type: string
          description: Unique name for the service (kebab-case)
          ui:autofocus: true
        owner:
          title: Owner
          type: string
          description: Team responsible for this service
          ui:field: OwnerPicker
        language:
          title: Programming Language
          type: string
          description: Primary language for the service
          enum:
            - go
            - python
            - nodejs
            - java
            - rust
          enumNames:
            - Go
            - Python
            - Node.js
            - Java
            - Rust
        description:
          title: Description
          type: string
          description: Brief description of the service

    - title: Infrastructure
      properties:
        database:
          title: Database
          type: string
          description: Database type required
          enum:
            - none
            - postgres
            - mysql
            - redis
          default: none
        replicas:
          title: Replicas
          type: number
          description: Number of replicas
          default: 2
          minimum: 1
          maximum: 10

  steps:
    - id: fetch-base
      name: Fetch Base Template
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          owner: ${{ parameters.owner }}
          language: ${{ parameters.language }}
          description: ${{ parameters.description }}
          database: ${{ parameters.database }}
          replicas: ${{ parameters.replicas }}

    - id: publish
      name: Publish to GitHub
      action: publish:github
      input:
        allowedHosts: ['github.com']
        description: ${{ parameters.description }}
        repoUrl: github.com?owner=org&repo=${{ parameters.name }}
        defaultBranch: main
        protectDefaultBranch: true

    - id: register
      name: Register in Catalog
      action: catalog:register
      input:
        catalogInfoUrl: https://github.com/org/${{ parameters.name }}/blob/main/catalog-info.yaml

  output:
    links:
      - title: Repository
        url: https://github.com/org/${{ parameters.name }}
      - title: Open in Catalog
        icon: catalog
        entityRef: component:default/${{ parameters.name }}
```

### Template Skeleton Structure

```
skeleton/
├── catalog-info.yaml
├── README.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── docker-compose.yml
├── terraform/
│   └── main.tf
└── docs/
    └── index.md
```

## Custom Backstage Plugin

### Platform Metrics Plugin

```typescript
// plugins/platform-stats/PlatformMetrics.tsx
import React from 'react';
import { useAsync } from 'react-use';
import { InfoCard, Progress, Table } from '@backstage/core-components';
import { useApi } from '@backstage/core-plugin-api';
import { platformApiRef } from '../api';

export const PlatformMetrics = () => {
  const platformApi = useApi(platformApiRef);
  const { value, loading } = useAsync(async () => {
    return platformApi.getMetrics();
  }, []);

  if (loading) return <Progress />;

  const metrics = value || {
    selfServiceRate: 92,
    avgProvisionTime: '3.5min',
    uptime: '99.95%',
    satisfaction: 4.6,
    services: 0,
    templates: 0,
  };

  return (
    <InfoCard title="Platform Health">
      <Table
        data={[
          { metric: 'Self-Service Rate', value: `${metrics.selfServiceRate}%` },
          { metric: 'Avg Provision Time', value: metrics.avgProvisionTime },
          { metric: 'Platform Uptime', value: metrics.uptime },
          { metric: 'Developer Satisfaction', value: `${metrics.satisfaction}/5` },
          { metric: 'Active Services', value: metrics.services },
          { metric: 'Templates Available', value: metrics.templates },
        ]}
        columns={[
          { title: 'Metric', field: 'metric' },
          { title: 'Value', field: 'value' },
        ]}
      />
    </InfoCard>
  );
};
```

### Plugin Registration

```typescript
// packages/app/src/plugins.ts
export { platformStatsPlugin } from '@internal/plugin-platform-stats';

// packages/app/src/App.tsx
import { PlatformMetrics } from '@internal/plugin-platform-stats';

const routes = (
  <FlatRoutes>
    <Route path="/platform" element={<PlatformMetrics />} />
  </FlatRoutes>
);
```

## TechDocs Configuration

### mkdocs.yml

```yaml
site_name: Service Documentation
nav:
  - Home: index.md
  - Architecture: architecture.md
  - API Reference: api.md
  - Runbooks: runbooks/
  - Contributing: contributing.md

plugins:
  - techdocs-core

markdown_extensions:
  - admonition
  - codehilite
  - toc:
      permalink: true
```

### Documentation Template

```markdown
# ${{ values.name }}

## Overview
${{ values.description }}

## Quick Start
\`\`\`bash
# Run locally
make run

# Run tests
make test
\`\`\`

## Configuration
| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `PORT` | Server port | No | `8080` |

## Dependencies
<!-- Generated from catalog-info.yaml -->

## Monitoring
- Dashboard: [Grafana](https://grafana.example.com)
- Alerts: #alerts-${{ values.name }}

## Owner
This service is owned by [${{ values.owner }}](../groups/${{ values.owner }}.md).
```

## ArgoCD Integration

### Application Registration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payment-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/gitops
    path: apps/production/payment-service
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

## CLI Tool

### Self-Service CLI

```bash
#!/bin/bash
# platform-cli - Self-service command line tool

set -euo pipefail

PLATFORM_API="${PLATFORM_API:-https://platform.example.com/api/v1}"

platform() {
  case $1 in
    create)
      curl -s -X POST "$PLATFORM_API/services" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"name\":\"$2\",\"env\":\"$3\",\"language\":\"$4\"}" | jq
      ;;
    status)
      curl -s "$PLATFORM_API/services/$2/status" \
        -H "Authorization: Bearer $TOKEN" | jq
      ;;
    logs)
      kubectl logs -l "app=$2" -n "${3:-staging}" --tail=100 -f
      ;;
    cost)
      curl -s "$PLATFORM_API/services/$2/cost?period=mtd" \
        -H "Authorization: Bearer $TOKEN" | jq
      ;;
    list)
      curl -s "$PLATFORM_API/services" \
        -H "Authorization: Bearer $TOKEN" | jq '.[]'
      ;;
    *)
      echo "Usage: platform {create|status|logs|cost|list} [args...]"
      exit 1
      ;;
  esac
}

platform "$@"
```

## Adoption Strategy

### Platform Goals Tracking

```yaml
# platform-goals.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: platform-goals
data:
  goals.yaml: |
    q1_2026:
      self_service_rate: 90%
      avg_provision_time: 5min
      developer_satisfaction: 4.5/5
      golden_path_adoption: 80%

    tracking:
      weekly_provisioning: true
      team_feedback: true
      support_tickets: true
      training_completion: true
```

## Best Practices

- Keep software templates up-to-date
- Require catalog-info.yaml for all services
- Integrate with existing tools (Git, CI/CD, monitoring)
- Provide self-service CLI alongside portal
- Track adoption metrics weekly
- Gather developer feedback continuously
- Document all templates and capabilities
- Run platform as a product team
