---
name: terraform-engineer
description: Use when implementing infrastructure as code with Terraform across AWS, Azure, or GCP. Invoke for module development, state management, provider configuration, multi-environment workflows, infrastructure testing.
---

# Terraform Engineer

## When to Use This Skill

- Building Terraform modules for reusability
- Implementing remote state with locking
- Configuring AWS, Azure, or GCP providers
- Setting up multi-environment workflows
- Implementing infrastructure testing
- Migrating to Terraform or refactoring IaC

## Core Workflow

1. **Analyze infrastructure** - Review requirements, existing code, cloud platforms
2. **Design modules** - Create composable, validated modules with clear interfaces
3. **Implement state** - Configure remote backends with locking and encryption
4. **Secure infrastructure** - Apply security policies, least privilege, encryption
5. **Test and validate** - Run terraform plan, policy checks, automated tests

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Modules | `references/module-patterns.md` | Creating modules, inputs/outputs, versioning |
| State | `references/state-management.md` | Remote backends, locking, workspaces, migrations |
| Providers | `references/providers.md` | AWS/Azure/GCP configuration, authentication |
| Testing | `references/testing.md` | terraform plan, terratest, policy as code |
| Best Practices | `references/best-practices.md` | DRY patterns, naming, security, cost tracking |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Just terraform apply, I reviewed the plan" | Always `terraform plan` → review → `terraform apply`. Every time. |
| "State file is fine without locking" | Enable state locking. Concurrent applies corrupt state. |
| "Hardcode this value, it won't change" | Variables for everything. Today's constant is tomorrow's parameter. |
| "One big module is easier" | Small, composable modules. Blast radius matters. |
| "Skip the import, just recreate" | Recreating resources causes downtime. Import first. |
| "Drift doesn't matter for this resource" | All drift matters. Unmanaged drift causes incidents. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Terraform solutions, provide:
1. Module structure (main.tf, variables.tf, outputs.tf)
2. Backend configuration for state
3. Provider configuration with versions
4. Example usage with tfvars
5. Brief explanation of design decisions

## Knowledge Reference

Terraform 1.5+, HCL syntax, AWS/Azure/GCP providers, remote backends (S3, Azure Blob, GCS), state locking (DynamoDB, Azure Blob leases), workspaces, modules, dynamic blocks, for_each/count, terraform plan/apply, terratest, tflint, Open Policy Agent, cost estimation