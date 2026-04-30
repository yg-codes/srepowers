---
name: terragrunt-expert
description: Use when orchestrating Terraform/OpenTofu modules with Terragrunt - DRY configurations, stack architecture, dependency management, multi-environment workflows, state backend automation
---

# Terragrunt Expert

## When to Use This Skill

- Orchestrating multiple Terraform/OpenTofu modules with Terragrunt
- Implementing DRY configurations across environments
- Designing implicit or explicit stack architectures
- Managing dependencies between infrastructure units
- Automating state backend configuration
- Setting up multi-environment deployment workflows
- Migrating from vanilla Terraform to Terragrunt
- Debugging dependency ordering and execution issues

## Core Workflow

1. **Analyze infrastructure** - Review requirements, existing Terragrunt setup, stack structure
2. **Design stacks** - Choose implicit (directory-based) or explicit (blueprint-based) architecture
3. **Implement DRY** - Configure include blocks, read_terragrunt_config, configuration inheritance
4. **Manage dependencies** - Set up dependency blocks, mock outputs, DAG optimization
5. **Automate state** - Configure remote_state blocks, auto-creation of backend resources
6. **Validate** - Run terragrunt plan, validate dependency ordering, test multi-environment parity

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Stack Patterns | `references/stack-patterns.md` | Designing stacks, unit composition, terragrunt.stack.hcl |
| Dependency Management | `references/dependency-management.md` | DAG optimization, mock outputs, cross-stack dependencies |
| DRY Patterns | `references/dry-patterns.md` | Include blocks, read_terragrunt_config, configuration inheritance |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Just copy the module, it's faster" | DRY configuration. Copy-paste creates drift. |
| "One terragrunt.hcl for everything" | Separate environments. Blast radius matters. |
| "Skip the dependency graph" | Define dependencies explicitly. Implicit ordering causes failures. |
| "Hardcode the backend config" | Generate backend config. Consistency across environments. |
| "Remote state reference is fine" | Use dependency blocks for cross-module references. Safer than remote_state. |
| "Plan is enough, skip the review" | Review plan output in CI. Automated gates prevent mistakes. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Terragrunt solutions, provide:
1. Stack directory structure
2. root.hcl with shared configuration
3. terragrunt.hcl unit configurations
4. terragrunt.stack.hcl if using explicit stacks
5. Dependency graph visualization
6. Brief explanation of design decisions

## Knowledge Reference

Terragrunt 0.70+, OpenTofu 1.8+, Terraform 1.5+, stack architecture (implicit/explicit), unit blocks, dependency blocks, include blocks, find_in_parent_folders, read_terragrunt_config, remote_state automation, mock outputs, DAG optimization, hooks (before/after/error), feature flags, provider caching, multi-environment patterns, infrastructure catalogs
