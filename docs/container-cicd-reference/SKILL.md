---
name: container-cicd-reference
description: Comprehensive reference documentation for AWS ECR, GitLab CI/CD, and container deployment patterns. Use when setting up ECR repositories, configuring cross-account access, choosing between IAM User vs Role authentication, verifying GitLab Container Registry availability, or comparing Python vs Docker deployment approaches. Provides detailed guides, decision matrices, troubleshooting steps, and complete workflow examples.
---

# Container CI/CD Reference

Comprehensive reference documentation for container-based CI/CD with AWS ECR and GitLab. This skill provides detailed setup guides, architectural patterns, authentication decisions, and deployment comparisons for container infrastructure.

## Purpose

This skill serves as a reference library for:
- **AWS ECR setup and usage** - Complete container registry configuration
- **Cross-account ECR access** - Multi-account deployment patterns
- **IAM authentication decisions** - User vs Role comparison for GitLab CI/CD
- **GitLab Container Registry** - Availability verification and configuration
- **Deployment comparisons** - Language and containerization approach analysis

## When to Use

Use this reference when:
- Setting up AWS ECR repositories for the first time
- Configuring cross-account ECR access for multi-environment deployments
- Deciding between IAM User vs IAM Role for GitLab CI/CD authentication
- Verifying GitLab Container Registry availability
- Comparing Python vs Docker deployment approaches
- Troubleshooting ECR authentication or pull/push issues
- Designing GitLab CI/CD pipelines for container images

## Available References

### Core ECR Documentation

**`references/aws-ecr-setup.md`**
- Complete ECR repository setup guide
- Prerequisites and IAM permissions
- Authentication methods (Podman/Docker)
- Build, tag, and push workflows
- GitLab CI/CD integration templates
- Lifecycle policies and cost estimation
- Best practices and troubleshooting

**`references/aws-ecr-cross-account.md`**
- Cross-account ECR architecture patterns
- Repository policy configuration
- IAM permissions for deployment accounts
- GitLab multi-account pipeline setup
- Local development workflows
- Security best practices
- Cost implications

### Authentication & Security

**`references/aws-iam-auth.md`**
- IAM User vs IAM Role comparison
- When to use each approach
- GitLab CI/CD authentication patterns
- Cross-account access considerations
- Security and maintenance trade-offs
- Complete permission requirements
- Setup and troubleshooting guides

### GitLab Integration

**`references/gitlab-registry-check.md`**
- Verify GitLab Container Registry availability
- Web UI and API check methods
- DNS and SSL validation
- Instance-level configuration
- Alternative registry options
- Diagnostic scripts
- Admin communication templates

### Deployment Comparisons

**`references/language-comparison.md`**
- Language deployment approach comparisons
- Container vs non-container patterns
- Runtime and dependency considerations

**`references/python-docker-comparison.md`**
- Python vs Docker deployment trade-offs
- When to containerize Python applications
- Development and operations considerations
- GitLab CI/CD implications

## Quick Reference

### ECR Authentication

```bash
# Login to ECR (valid for 12 hours)
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Cross-Account Pull

```bash
# From deployment account (Account B)
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin \
  <account-a-id>.dkr.ecr.us-east-1.amazonaws.com

podman pull <account-a-id>.dkr.ecr.us-east-1.amazonaws.com/repo:tag
```

### GitLab CI/CD Variables (ECR)

| Variable | Purpose | Example |
|----------|---------|---------|
| `ECR_AWS_ACCESS_KEY_ID` | ECR account access key | `AKIAIOSFODNN7EXAMPLE` (⚠️ DO NOT use - AWS doc example) |
| `ECR_AWS_SECRET_ACCESS_KEY` | ECR account secret key | `wJalrXUtnFEMI...` (⚠️ DO NOT use - AWS doc example) |
| `ECR_AWS_REGION` | ECR region | `us-east-1` |
| `ECR_AWS_ACCOUNT_ID` | ECR account ID (12 digits) | `123456789012` |

## Related Skills

This reference skill is designed to complement:
- **`gitlab-ecr-pipeline`** - Practical GitLab CI/CD pipeline templates
- **`aws-mcp-setup`** - AWS MCP server configuration
- **`aws-cdk-development`** - CDK infrastructure patterns

## Usage Tips

1. **For pipeline implementation**: Use `gitlab-ecr-pipeline` skill for actionable templates
2. **For architecture decisions**: Reference the detailed guides in this skill
3. **For authentication setup**: Start with `references/aws-iam-auth.md`
4. **For troubleshooting**: Each reference includes comprehensive troubleshooting sections

## Document Structure

Each reference document follows a consistent structure:
- **Executive Summary** - Quick overview and decision points
- **Prerequisites** - Required setup and permissions
- **Step-by-Step Guides** - Detailed implementation instructions
- **Code Examples** - Ready-to-use commands and configurations
- **Troubleshooting** - Common issues and solutions
- **Best Practices** - Security and operational guidelines
