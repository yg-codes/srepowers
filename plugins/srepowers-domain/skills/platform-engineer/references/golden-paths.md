# Golden Paths

Opinionated templates and workflows that make the right thing the easiest thing to do.

## Golden Path Principles

- **Paved road**: Pre-approved, secure, well-documented path
- **Friction reduction**: Make the right choice the easy choice
- **Self-service**: No tickets, no approvals for standard paths
- **Best practices baked in**: Security, observability, testing included

## Service Scaffolding Templates

### Backstage Software Template

```yaml
# templates/microservice/template.yaml
apiVersion: scaffolder.backstage.io/v1beta3
kind: Template
metadata:
  name: microservice-template
  title: Microservice Golden Path
spec:
  owner: platform-team
  type: service
  parameters:
    - title: Service Info
      properties:
        name:
          type: string
          description: Service name (kebab-case)
        owner:
          type: string
          ui:field: OwnerPicker
        language:
          type: string
          enum: [go, python, nodejs, java, rust]
        database:
          type: string
          enum: [none, postgres, mysql, redis]
          default: none
  steps:
    - id: fetch
      action: fetch:template
      input:
        url: ./skeleton
        values:
          name: ${{ parameters.name }}
          owner: ${{ parameters.owner }}
          language: ${{ parameters.language }}
    - id: publish
      action: publish:github
      input:
        repoUrl: github.com?owner=org&repo=${{ parameters.name }}
    - id: register
      action: catalog:register
      input:
        catalogInfoUrl: https://github.com/org/${{ parameters.name }}/blob/main/catalog-info.yaml
  output:
    links:
      - title: Repository
        url: https://github.com/org/${{ parameters.name }}
```

### Golden Path Scaffolding Script

```bash
#!/bin/bash
# create-service.sh - Golden path for new services

set -euo pipefail

SERVICE=$1
LANG=$2
ENV=${3:-staging}

# Validate inputs
[[ -z "$SERVICE" || -z "$LANG" ]] && { echo "Usage: $0 <service> <language> [env]"; exit 1; }

# Create from template
gh repo create "org/$SERVICE" --template "org/template-$LANG"
git clone "git@github.com:org/$SERVICE.git"
cd "$SERVICE"

# Setup CI/CD
cat > .github/workflows/ci.yml <<EOF
name: CI/CD
on: [push]
jobs:
  pipeline:
    uses: org/workflows/.github/workflows/standard.yml@v1
    with:
      service_name: $SERVICE
EOF

# Create infrastructure
mkdir -p terraform
cat > terraform/main.tf <<EOF
module "service" {
  source = "git::https://github.com/org/terraform//service"
  name   = "$SERVICE"
  env    = "$ENV"
}
EOF

# Add catalog-info.yaml for Backstage
cat > catalog-info.yaml <<EOF
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: $SERVICE
  annotations:
    github.com/project-slug: org/$SERVICE
spec:
  type: service
  lifecycle: experimental
  owner: unknown
EOF

git add . && git commit -m "Golden path init" && git push

echo "Service created! Push to main to deploy."
```

## CI/CD Pipeline Templates

### Reusable Workflow (GitHub Actions)

```yaml
# .github/workflows/standard.yml - Golden path pipeline
name: Standard Service Pipeline

on:
  workflow_call:
    inputs:
      service_name:
        required: true
        type: string
      environment:
        required: false
        type: string
        default: staging

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
      - name: Security scan
        uses: snyk/actions/runner@v1

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build container
        run: docker build -t ${{ inputs.service_name }}:${{ github.sha }} .
      - name: Push to registry
        run: |
          docker tag ${{ inputs.service_name }}:${{ github.sha }} \
            registry.example.com/${{ inputs.service_name }}:${{ github.sha }}
          docker push registry.example.com/${{ inputs.service_name }}:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/${{ inputs.service_name }} \
            ${{ inputs.service_name }}=registry.example.com/${{ inputs.service_name }}:${{ github.sha }}
```

### Terraform Service Module

```hcl
# modules/service/main.tf - Golden path infrastructure
variable "service_name" {}
variable "environment" {}
variable "cpu" { default = "100m" }
variable "memory" { default = "128Mi" }

module "k8s_deployment" {
  source = "./k8s-deployment"
  name   = var.service_name
  env    = var.environment
  cpu    = var.cpu
  memory = var.memory
}

module "monitoring" {
  source  = "./monitoring"
  service = var.service_name
}

output "service_url" {
  value = module.k8s_deployment.url
}
```

## Best Practices Enforcement

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-yaml
      - id: end-of-file-fixer
      - id: trailing-whitespace

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.5
    hooks:
      - id: terraform_fmt
      - id: terraform_validate

  - repo: https://github.com/golangci/golangci-lint
    rev: v1.55.2
    hooks:
      - id: golangci-lint
```

### Policy Enforcement (OPA/Gatekeeper)

```yaml
# Constraint: Require resource limits
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sContainerLimits
metadata:
  name: container-must-have-limits
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    cpu: "4"
    memory: "4Gi"
```

## Compliance Validation

### Service Readiness Checklist

```yaml
# service-readiness.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-readiness-checklist
data:
  checklist.yaml: |
    production_readiness:
      - name: Health checks
        required: true
        check: kubectl get deploy/{service} -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}'

      - name: Resource limits
        required: true
        check: kubectl get deploy/{service} -o jsonpath='{.spec.template.spec.containers[0].resources.limits}'

      - name: Monitoring
        required: true
        check: kubectl get servicemonitor/{service}

      - name: Security scan
        required: true
        check: curl -s https://security-api/scan/{service}

      - name: Documentation
        required: true
        check: kubectl get cm/{service}-docs
```

## Documentation Templates

### Service README Template

```markdown
# {Service Name}

## Overview
Brief description of service purpose and responsibilities.

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
- Postgres (primary database)
- Redis (cache)

## Monitoring
- Dashboard: https://grafana.example.com/d/{service}
- Alerts: #alerts-{service}

## Runbooks
- [Incident Response](./docs/incident-response.md)
- [Scaling Guide](./docs/scaling.md)
```

## Best Practices

- Make golden paths the easiest option
- Include security and observability by default
- Provide clear documentation with examples
- Automate compliance checks
- Gather feedback and iterate
- Version control all templates
- Test templates regularly
- Track adoption metrics
