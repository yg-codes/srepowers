# Terragrunt Dependency Management

## Dependency Overview

Terragrunt's dependency system enables automatic:
- Output passing between units
- Execution ordering (DAG-based)
- Parallel execution of independent units
- Cross-stack references

## dependency Block

### Basic Dependency

```hcl
# prod/compute/eks/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/org/terraform-modules.git//eks?ref=v3.0.0"
}

dependency "vpc" {
  config_path = "../networking/vpc"
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids
}
```

### Multiple Dependencies

```hcl
# prod/app/backend/terragrunt.hcl
dependency "vpc" {
  config_path = "../networking/vpc"
}

dependency "eks" {
  config_path = "../compute/eks"
}

dependency "rds" {
  config_path = "../database/rds"
}

inputs = {
  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnet_ids
  cluster_name    = dependency.eks.outputs.cluster_name
  cluster_endpoint = dependency.eks.outputs.cluster_endpoint
  db_endpoint     = dependency.rds.outputs.endpoint
  db_port         = dependency.rds.outputs.port
}
```

## Mock Outputs

Mock outputs allow `terragrunt plan` to work even when dependencies haven't been applied yet.

### Basic Mock Outputs

```hcl
dependency "vpc" {
  config_path = "../networking/vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock-12345"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2", "subnet-mock-3"]
  }
}
```

### Mock Outputs with Terraform Commands

```hcl
dependency "vpc" {
  config_path = "../networking/vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock-12345"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }

  # Use real outputs for apply, mock for plan
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
}
```

### Comprehensive Mock Pattern

```hcl
dependency "eks" {
  config_path = "../compute/eks"

  mock_outputs = {
    cluster_id                       = "eks-mock-cluster"
    cluster_name                     = "mock-cluster"
    cluster_endpoint                 = "https://mock.eks.amazonaws.com"
    cluster_certificate_authority_data = "mock-ca-data"
    cluster_security_group_id        = "sg-mock-12345"
    node_security_group_id           = "sg-mock-67890"
  }

  mock_outputs_allowed_terraform_commands = ["plan", "validate", "show"]
}
```

## dependencies Block

The `dependencies` block declares units that must be applied before this one, but whose outputs are not needed.

```hcl
# prod/database/rds/terragrunt.hcl
dependency "vpc" {
  config_path = "../networking/vpc"

  mock_outputs = {
    vpc_id             = "vpc-mock"
    database_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
}

# These units must be applied first, but we don't need their outputs
dependencies {
  paths = [
    "../secrets/db-passwords",
    "../iam/rds-roles"
  ]
}

inputs = {
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.database_subnet_ids
}
```

## DAG Optimization

### Execution Order

Terragrunt builds a Directed Acyclic Graph (DAG) from dependencies:

```
vpc (no deps)
  ├── eks (depends on vpc)
  │     └── backend (depends on eks, rds)
  └── rds (depends on vpc)
```

### Parallel Execution

Independent units execute in parallel:

```bash
# terragrunt run-all apply executes in parallel where possible
# vpc first, then eks and rds in parallel, then backend last

terragrunt run-all plan --terragrunt-parallelism 10
```

### View Dependency Graph

```bash
# ASCII output
terragrunt dag graph

# DOT format for visualization
terragrunt dag graph --terragrunt-graph-type dot > deps.dot
dot -Tpng deps.dot -o deps.png
```

### Find Affected Units

```bash
# Find all units that depend on vpc
terragrunt run-all plan --terragrunt-modules-that-depend-on prod/networking/vpc

# Find units in dependency order
terragrunt find --dag

# Find units excluding some paths
terragrunt find --ignore-external-dependencies
```

## Cross-Stack Dependencies

### Dependencies Across Environments

```hcl
# prod/app/backend/terragrunt.hcl
dependency "shared_vpc" {
  config_path = "../../shared-services/networking/vpc"
}

dependency "shared_secrets" {
  config_path = "../../shared-services/secrets/app-secrets"
}

inputs = {
  shared_vpc_id = dependency.shared_vpc.outputs.vpc_id
  db_password   = dependency.shared_secrets.outputs.db_password
}
```

### Dependencies Across Accounts

```hcl
# prod/dns/route53/terragrunt.hcl
dependency "shared_zones" {
  config_path = "../../../shared-services/dns/delegated-zones"

  mock_outputs = {
    zone_ids = { main = "Z1234567890ABC" }
  }
}

inputs = {
  delegated_zone_id = dependency.shared_zones.outputs.zone_ids.main
}
```

## Conditional Dependencies

### Skip Dependency

```hcl
dependency "optional_feature" {
  config_path = "../features/optional-feature"

  # Skip if the dependency doesn't exist
  skip = !fileexists("${get_terragrunt_dir()}/../features/optional-feature/terragrunt.hcl")

  mock_outputs = {
    enabled = false
  }
}

inputs = {
  feature_enabled = dependency.optional_feature.outputs.enabled
}
```

### Feature Flags

```hcl
feature "enable_monitoring" {
  default = false
}

dependency "monitoring" {
  config_path = "../monitoring/prometheus"

  enabled = feature.enable_monitoring.value

  mock_outputs = {
    prometheus_endpoint = "http://localhost:9090"
  }
}
```

## Circular Dependency Prevention

### Detection

Terragrunt automatically detects circular dependencies:

```
Error: Circular dependency detected:
  unit-a -> unit-b -> unit-c -> unit-a
```

### Resolution Patterns

1. **Refactor shared outputs into a base unit**
```
Before:
  unit-a -> unit-b -> unit-a (circular)

After:
  shared-base -> unit-a
             -> unit-b
```

2. **Use data sources instead of dependencies**
```hcl
# Instead of dependency
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["existing-vpc"]
  }
}
```

3. **Merge tightly coupled units**
```hcl
# If units are always deployed together, combine them
# networking/vpc + networking/subnets -> networking/
```

## Dependency Best Practices

1. **Minimize dependencies** - Only depend on what you need
2. **Always use mock outputs** - Enables plan without apply
3. **Document dependency rationale** - Add comments explaining why
4. **Test with mocks** - Verify units work with mock outputs
5. **Use dependencies block** - For ordering without output passing
6. **Avoid deep chains** - Long chains slow deployments and increase blast radius
7. **Group related units** - Reduces cross-stack dependencies

## Troubleshooting

### Dependency Not Found

```bash
Error: Module ../networking/vpc does not exist

# Check path is correct relative to current terragrunt.hcl
ls -la ../networking/vpc/terragrunt.hcl
```

### Mock Output Type Mismatch

```hcl
# Wrong - string instead of list
mock_outputs = {
  subnet_ids = "subnet-123"  # Should be a list
}

# Correct
mock_outputs = {
  subnet_ids = ["subnet-123"]
}
```

### Dependency Timeout

```hcl
# Increase timeout for slow dependencies
dependency "large_database" {
  config_path = "../database/large-rds"

  timeout = "10m"  # Default is 5m
}
```
