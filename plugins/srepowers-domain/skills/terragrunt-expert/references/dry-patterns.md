# Terragrunt DRY Patterns

## DRY Philosophy

Terragrunt's primary goal is eliminating duplication in infrastructure code. Target >90% DRY configuration.

## Include Blocks

### find_in_parent_folders

Automatically locate and include configuration from parent directories.

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}
```

### Multiple Include Blocks

Combine configurations from multiple levels:

```hcl
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

### Include with Expose

Access included configuration values:

```hcl
include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

inputs = {
  environment = include.env.locals.environment
  tags        = merge(include.env.locals.tags, { Service = "api" })
}
```

### Merge Strategies

| Strategy | Use Case |
|----------|----------|
| `shallow` | Complete override (default) |
| `deep` | Merge nested maps and lists |
| `no_merge` | Ignore included values |

```hcl
include "env" {
  path           = find_in_parent_folders("env.hcl")
  merge_strategy = "deep"  # Merge tags, inputs, etc.
}
```

## read_terragrunt_config

Read arbitrary terragrunt configuration files and use their values.

### Basic Usage

```hcl
# Read common configuration
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = {
  tags = merge(
    local.common_vars.locals.common_tags,
    { Component = "api" }
  )
}
```

### Reading Multiple Configs

```hcl
locals {
  env_config    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_config = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  account_config = read_terragrunt_config("${get_parent_terragrunt_dir()}/account.hcl")
}

inputs = {
  environment  = local.env_config.locals.environment
  region       = local.region_config.locals.region
  account_name = local.account_config.locals.account_name
}
```

### Shared Input Patterns

```hcl
# common/networking.hcl
locals {
  vpc_cidr_base     = "10.0"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# prod/networking/vpc/terragrunt.hcl
locals {
  networking = read_terragrunt_config(find_in_parent_folders("networking.hcl"))
}

inputs = {
  cidr_block = "${local.networking.locals.vpc_cidr_base}.0.0/16"
  azs        = local.networking.locals.availability_zones
}
```

## Configuration Inheritance

### Layered Configuration

```
root.hcl (global defaults)
    │
    ├── account.hcl (account-specific)
    │       │
    │       └── region.hcl (region-specific)
    │               │
    │               └── env.hcl (environment-specific)
    │                       │
    │                       └── terragrunt.hcl (unit-specific)
```

### root.hcl (Global)

```hcl
# Shared provider generation
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region
}
EOF
}

# Shared remote state
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "org-terraform-state"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Default inputs
inputs = {
  project     = "myorg"
  managed_by  = "terragrunt"
}
```

### account.hcl (Account Level)

```hcl
locals {
  account_id  = "123456789012"
  account_name = "prod"
}

inputs = {
  account_id = local.account_id
}
```

### env.hcl (Environment Level)

```hcl
locals {
  environment = "prod"
}

inputs = {
  environment = local.environment
  tags = {
    Environment = local.environment
  }
}
```

### Unit terragrunt.hcl (Leaf)

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "account" {
  path           = find_in_parent_folders("account.hcl")
  expose         = true
  merge_strategy = "deep"
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "git::https://github.com/org/modules.git//eks?ref=v2.0.0"
}

# Unit-specific inputs merged with inherited
inputs = {
  cluster_name = "${include.env.locals.environment}-eks"
}
```

## Generate Blocks

Automatically generate Terraform files to eliminate boilerplate.

### Provider Generation

```hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}
```

### Backend Generation

```hcl
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "org-terraform-state"
    key            = "prod/eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
EOF
}
```

### Version Constraints Generation

```hcl
generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF
}
```

### Conditional Generation

```hcl
locals {
  enable_monitoring = true
}

generate "monitoring" {
  path      = "monitoring.tf"
  if_exists = "overwrite_terragrunt"
  contents  = local.enable_monitoring ? <<EOF
resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name  = "high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  period      = 300
  statistic   = "Average"
  threshold   = 80
}
EOF : ""
}
```

## remote_state Block

Centralized state management configuration.

### S3 Backend

```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "org-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"

    # Optional: Enable versioning
    enable_lock_table_ssencryption = true
  }
}
```

### Auto-Create State Resources

```hcl
remote_state {
  backend = "s3"
  config = {
    bucket = "org-terraform-state-${get_aws_account_id()}"

    # Terragrunt can create the S3 bucket and DynamoDB table
    # Set to false in production after initial creation
    disable_bucket_update = false
  }
}
```

### GCS Backend

```hcl
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket      = "org-terraform-state"
    prefix      = "${path_relative_to_include()}/terraform.tfstate"
    location    = "US"
    project     = "my-project"
    credentials = file("~/.config/gcloud/application_default_credentials.json")
  }
}
```

### Azure Backend

```hcl
remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    resource_group_name  = "terraform-state"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

## DRY Best Practices

1. **Centralize common configuration** - Put shared inputs in root.hcl
2. **Use environment layers** - env.hcl, region.hcl, account.hcl
3. **Generate boilerplate** - Use generate blocks for providers, backends
4. **Expose includes** - Use expose = true to access parent values
5. **Deep merge tags** - Always merge_strategy = "deep" for tags
6. **Factor out patterns** - Create common.hcl files for repeated patterns
7. **Version modules centrally** - Define module versions in one place

## DRY Metrics

Track DRY percentage to ensure maintainability:

```bash
# Count unique input values
find . -name terragrunt.hcl -exec grep "^inputs" {} \; | wc -l

# Count total lines of configuration
find . -name "*.hcl" | xargs wc -l

# Target: <10% of lines should be unique to any single unit
```

## Common DRY Anti-Patterns

### Anti-Pattern: Duplicated Tags

```hcl
# Wrong - tags duplicated in every unit
inputs = {
  tags = {
    Environment = "prod"
    ManagedBy   = "terragrunt"
    Project     = "myorg"
  }
}
```

### Correct Pattern: Inherited Tags

```hcl
# In root.hcl
inputs = {
  tags = {
    ManagedBy = "terragrunt"
    Project   = "myorg"
  }
}

# In env.hcl
locals {
  environment = "prod"
}

inputs = {
  tags = {
    Environment = local.environment
  }
}

# In terragrunt.hcl - just add component tag
inputs = {
  tags = {
    Component = "api"
  }
}
```

### Anti-Pattern: Hardcoded Module Source

```hcl
# Wrong - version duplicated everywhere
terraform {
  source = "git::https://github.com/org/modules.git//vpc?ref=v2.1.0"
}
```

### Correct Pattern: Centralized Version

```hcl
# In root.hcl
locals {
  module_version = "v2.1.0"
}

# In terragrunt.hcl
locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

terraform {
  source = "git::https://github.com/org/modules.git//vpc?ref=${local.root.locals.module_version}"
}
```
