# Terragrunt Stack Patterns

## Stack Architecture Overview

Terragrunt supports two primary stack patterns for organizing infrastructure:

| Pattern | Description | Best For |
|---------|-------------|----------|
| **Implicit** | Directory-based organization | Small to medium deployments, simple hierarchies |
| **Explicit** | Blueprint-based with terragrunt.stack.hcl | Large enterprises, complex multi-region/multi-account |

## Implicit Stack Pattern

Directory-based organization where Terragrunt discovers units by traversing the file system.

### Directory Structure

```
infrastructure/
├── root.hcl                    # Shared configuration
├── env-common/
│   └── networking.hcl          # Common networking inputs
├── prod/
│   ├── env.hcl                 # Environment-specific config
│   ├── networking/
│   │   └── vpc/
│   │       └── terragrunt.hcl
│   ├── compute/
│   │   └── eks/
│   │       └── terragrunt.hcl
│   └── database/
│       └── rds/
│           └── terragrunt.hcl
└── dev/
    ├── env.hcl
    ├── networking/
    │   └── vpc/
    │       └── terragrunt.hcl
    └── ...
```

### root.hcl Example

```hcl
# Generate provider configuration for all units
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terragrunt"
      Project     = var.project_name
    }
  }
}
EOF
}

# Remote state configuration
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "myorg-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Common inputs available to all units
inputs = {
  aws_region   = "us-east-1"
  project_name = "myorg-infra"
}
```

### Environment-Specific env.hcl

```hcl
# prod/env.hcl
locals {
  environment = "prod"
  aws_region  = "us-east-1"

  # Environment-specific tags
  tags = {
    Environment = "prod"
    CostCenter  = "engineering"
  }
}
```

### Unit terragrunt.hcl

```hcl
# prod/networking/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "git::https://github.com/org/terraform-modules.git//vpc?ref=v2.1.0"
}

inputs = {
  name       = "${include.env.locals.environment}-vpc"
  cidr_block = "10.0.0.0/16"

  tags = merge(
    include.env.locals.tags,
    { Component = "networking" }
  )
}
```

## Explicit Stack Pattern

Blueprint-based organization using terragrunt.stack.hcl for complex deployments.

### Directory Structure

```
infrastructure/
├── root.hcl
├── terragrunt.stack.hcl        # Stack blueprint
├── units/
│   ├── vpc/
│   │   └── terragrunt.hcl
│   ├── eks/
│   │   └── terragrunt.hcl
│   └── rds/
│       └── terragrunt.hcl
└── catalogs/
    └── standard/
        └── terragrunt.stack.hcl
```

### terragrunt.stack.hcl Example

```hcl
# Define stack units with explicit ordering
unit "vpc" {
  source = "./units/vpc"

  inputs = {
    name       = "production-vpc"
    cidr_block = "10.0.0.0/16"
  }
}

unit "eks" {
  source = "./units/eks"

  # Explicit dependency
  dependencies = [unit.vpc]

  inputs = {
    name          = "production-eks"
    vpc_id        = dependency.vpc.outputs.vpc_id
    subnet_ids    = dependency.vpc.outputs.private_subnet_ids
  }
}

unit "rds" {
  source = "./units/rds"

  dependencies = [unit.vpc]

  inputs = {
    name       = "production-rds"
    vpc_id     = dependency.vpc.outputs.vpc_id
    subnet_ids = dependency.vpc.outputs.database_subnet_ids
  }
}
```

### Stack Unit with Dependency

```hcl
# units/eks/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/org/terraform-modules.git//eks?ref=v3.0.0"
}

# Dependencies are declared in terragrunt.stack.hcl
# This file defines the unit's source and inputs

inputs = {
  # Inputs come from stack definition
  cluster_version = "1.28"
  node_count      = 3
}
```

## Unit Block Composition

### Multiple Include Blocks

```hcl
# Combine multiple configurations
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "deep"
}

include "region" {
  path           = find_in_parent_folders("region.hcl")
  expose         = true
  merge_strategy = "deep"
}
```

### Merge Strategies

| Strategy | Behavior |
|----------|----------|
| `shallow` | Replace entire block (default) |
| `deep` | Deep merge maps/lists |
| `no_merge` | Keep only original values |

### Exposed Includes

```hcl
# Access exposed include values
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

inputs = {
  environment = include.env.locals.environment
  tags        = include.env.locals.tags
}
```

## Stack Execution Commands

```bash
# Run all units in a stack (implicit)
terragrunt run-all plan

# Run with explicit stack file
terragrunt run --all plan

# Generate stack from blueprint
terragrunt stack generate

# List units in dependency order
terragrunt find --dag

# Visualize dependency graph
terragrunt dag graph

# Execute specific units
terragrunt run --all plan --terragrunt-modules-that-include vpc
```

## Stack Organization Best Practices

1. **Group by environment** - Separate prod/dev/staging at top level
2. **Group by service** - Group related units (networking, compute, data)
3. **Use consistent naming** - Match unit names to module names
4. **Limit stack depth** - Avoid deeply nested hierarchies
5. **Document dependencies** - Add comments explaining dependency rationale
6. **Version modules** - Always pin module sources to specific tags
7. **Test incrementally** - Validate one unit before adding dependencies

## Nested Stack Hierarchies

For large organizations with multi-account structures:

```
infrastructure/
├── root.hcl
├── accounts/
│   ├── shared-services/
│   │   ├── account.hcl
│   │   └── terragrunt.stack.hcl
│   ├── prod/
│   │   ├── account.hcl
│   │   └── terragrunt.stack.hcl
│   └── dev/
│       ├── account.hcl
│       └── terragrunt.stack.hcl
└── modules/
    └── ...
```

### Account-Level Configuration

```hcl
# accounts/prod/account.hcl
locals {
  account_id  = "123456789012"
  environment = "prod"

  # Account-wide tags
  tags = {
    Account     = "prod"
    Environment = "prod"
    ManagedBy   = "terragrunt"
  }
}
```
