# AWS ECR Container Registry Setup Guide

**Document Version:** 1.0
**Date:** 2025-10-22
**Project:** AWS Network Account CDK Infrastructure
**Registry:** Amazon Elastic Container Registry (ECR)
**Decision:** ✅ AWS ECR Approved (Organization Standard)

---

## Executive Summary

This document provides complete setup and usage instructions for using **AWS ECR** as the container registry for the AWS Network CDK project. ECR is an excellent fit since:

✅ **Already using AWS** - Project deploys AWS infrastructure
✅ **Organization approved** - Allowed by your organization
✅ **Integrated authentication** - Uses AWS IAM
✅ **Private by default** - Secure image storage
✅ **Pay-as-you-go** - Only pay for storage used (~$0.10/GB/month)
✅ **High availability** - AWS-managed service
✅ **Podman compatible** - Works with Podman (and Docker)

---

## Table of Contents

1. [ECR Overview](#ecr-overview)
2. [Prerequisites](#prerequisites)
3. [ECR Repository Setup](#ecr-repository-setup)
4. [Authentication](#authentication)
5. [Build, Tag, and Push](#build-tag-and-push)
6. [GitLab CI/CD Integration](#gitlab-cicd-integration)
7. [Pull and Run Images](#pull-and-run-images)
8. [Lifecycle Policies](#lifecycle-policies)
9. [Cost Estimation](#cost-estimation)
10. [Best Practices](#best-practices)

---

## ECR Overview

### What is AWS ECR?

Amazon Elastic Container Registry (ECR) is a fully managed container registry that:
- Stores container images (OCI/Docker format)
- Integrates with AWS IAM for authentication
- Scans images for vulnerabilities (optional)
- Supports private and public repositories
- Works with Podman, Docker, and other OCI tools

### Why ECR for This Project?

| Benefit | Description |
|---------|-------------|
| **AWS Native** | Same AWS account as your CDK deployments |
| **IAM Integration** | Uses AWS credentials (no separate auth) |
| **Private** | Images not publicly accessible |
| **Org Approved** | Already allowed by your organization |
| **CI/CD Ready** | Easy GitLab integration with AWS credentials |
| **Cost Effective** | ~$0.10/GB/month storage + minimal transfer |

---

## Prerequisites

### 1. AWS Account Access

You need:
- ✅ AWS account where images will be stored
- ✅ IAM user/role with ECR permissions
- ✅ AWS credentials configured locally

**Recommended:** Use the **same AWS account** where you deploy CDK infrastructure.

### 2. Required IAM Permissions

Your AWS IAM user/role needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:ListImages",
        "ecr:DescribeImages"
      ],
      "Resource": "*"
    }
  ]
}
```

**Policy Name:** `ECRPowerUser` (AWS managed policy) or custom policy above.

### 3. Local Tools

- ✅ Podman (or Docker)
- ✅ AWS CLI v2
- ✅ AWS credentials configured

**Check installation:**
```bash
podman --version
aws --version
aws sts get-caller-identity  # Verify AWS credentials
```

---

## ECR Repository Setup

### Option 1: Create via AWS Console (5 minutes)

1. **Navigate to ECR:**
   ```
   AWS Console → Services → ECR (Elastic Container Registry)
   ```

2. **Create Repository:**
   - Click "Create repository"
   - **Visibility:** Private
   - **Repository name:** `aws-network-cdk`
   - **Tag immutability:** Disabled (allows overwriting tags)
   - **Scan on push:** Enabled (recommended for security)
   - **Encryption:** AES-256 (default)

3. **Note the Repository URI:**
   ```
   <aws-account-id>.dkr.ecr.<region>.amazonaws.com/aws-network-cdk

   Example:
   123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk
   ```

---

### Option 2: Create via AWS CLI (1 minute)

```bash
# Set variables
AWS_REGION="us-east-1"  # Change to your region
REPO_NAME="aws-network-cdk"

# Create ECR repository
aws ecr create-repository \
  --repository-name "$REPO_NAME" \
  --region "$AWS_REGION" \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

# Get repository URI
aws ecr describe-repositories \
  --repository-names "$REPO_NAME" \
  --region "$AWS_REGION" \
  --query 'repositories[0].repositoryUri' \
  --output text
```

**Save the repository URI** - you'll use it for pushing/pulling images.

---

### Option 3: Create via Infrastructure as Code (Recommended)

Since you're already using CDK, you can manage ECR repository as code:

```python
# Optional: Add to your CDK project
from aws_cdk import aws_ecr as ecr

# In one of your stacks (or create a new stack)
container_repo = ecr.Repository(
    self, "NetworkCDKRepository",
    repository_name="aws-network-cdk",
    image_scan_on_push=True,
    lifecycle_rules=[
        ecr.LifecycleRule(
            description="Keep last 10 images",
            max_image_count=10,
            rule_priority=1
        )
    ],
    removal_policy=cdk.RemovalPolicy.RETAIN
)
```

**Note:** Only needed if you want ECR managed via CDK. Manual creation is fine too.

---

## Authentication

### Podman Authentication to ECR

ECR uses **temporary credentials** that expire after 12 hours.

#### Method 1: One-Line Authentication (Recommended)

```bash
# Set your AWS region and account ID
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"  # Your AWS account ID

# Login with Podman
aws ecr get-login-password --region $AWS_REGION | \
  podman login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Expected output:
# Login Succeeded!
```

#### Method 2: Helper Script

Create `scripts/ecr-login.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "Logging into ECR: $ECR_REGISTRY"

# Get password and login
aws ecr get-login-password --region "$AWS_REGION" | \
  podman login --username AWS --password-stdin "$ECR_REGISTRY"

echo "✓ Successfully logged into ECR"
echo "Registry: $ECR_REGISTRY"
```

**Usage:**
```bash
chmod +x scripts/ecr-login.sh
./scripts/ecr-login.sh
```

---

## Build, Tag, and Push

### Complete Workflow

```bash
# 1. Set variables
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
export REPO_NAME="aws-network-cdk"
export IMAGE_TAG="v1.0.0"  # Or use git commit SHA

# 2. Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  podman login --username AWS --password-stdin $ECR_REGISTRY

# 3. Build image
podman build -t $REPO_NAME:$IMAGE_TAG -f Containerfile .

# 4. Tag for ECR
podman tag $REPO_NAME:$IMAGE_TAG \
  $ECR_REGISTRY/$REPO_NAME:$IMAGE_TAG

# Also tag as latest
podman tag $REPO_NAME:$IMAGE_TAG \
  $ECR_REGISTRY/$REPO_NAME:latest

# 5. Push to ECR
podman push $ECR_REGISTRY/$REPO_NAME:$IMAGE_TAG
podman push $ECR_REGISTRY/$REPO_NAME:latest

# 6. Verify upload
aws ecr list-images \
  --repository-name $REPO_NAME \
  --region $AWS_REGION
```

### Example with Real Values

```bash
# Using us-east-1 and account 123456789012
export ECR_REGISTRY="123456789012.dkr.ecr.us-east-1.amazonaws.com"

# Login
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin $ECR_REGISTRY

# Build
podman build -t aws-network-cdk:v1.0.0 -f Containerfile .

# Tag
podman tag aws-network-cdk:v1.0.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0

# Push
podman push \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0
```

---

## GitLab CI/CD Integration

### Prerequisites for GitLab

**Option 1: Store AWS Credentials in GitLab CI/CD Variables**

1. Go to: `Settings → CI/CD → Variables`
2. Add variables:
   ```
   AWS_ACCESS_KEY_ID      = <your-access-key>
   AWS_SECRET_ACCESS_KEY  = <your-secret-key>
   AWS_DEFAULT_REGION     = us-east-1
   AWS_ACCOUNT_ID         = 123456789012
   ```
3. Mark as **Protected** and **Masked**

**Option 2: Use IAM Role (Better for GitLab on AWS)**

If your GitLab runners are on EC2, attach IAM role with ECR permissions.

---

### Complete GitLab CI/CD Pipeline

```yaml
# .gitlab-ci.yml
variables:
  AWS_REGION: us-east-1  # Change to your region
  ECR_REGISTRY: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
  IMAGE_NAME: aws-network-cdk
  CONTAINER_IMAGE: $ECR_REGISTRY/$IMAGE_NAME

stages:
  - validate
  - build
  - test
  - release
  - deploy

# Validate configuration
validate:
  stage: validate
  image: python:3.12-slim
  before_script:
    - pip install uv
    - uv sync
  script:
    - python validate_config.py
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"

# Build container image and push to ECR
build:
  stage: build
  image: quay.io/podman/stable:latest
  services:
    - docker:dind
  before_script:
    # Install AWS CLI
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    # Login to ECR
    - aws ecr get-login-password --region $AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    # Build image
    - podman build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA -f Containerfile .

    # Tag with commit SHA
    - podman tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA
      $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA

    # Tag as latest for main branch
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        podman tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:latest
      fi

    # Push to ECR
    - podman push $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        podman push $CONTAINER_IMAGE:latest
      fi

    # Output image URI
    - echo "Image pushed to $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA"
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

# Test the built image
test:
  stage: test
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    - aws ecr get-login-password --region $AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    # Pull image
    - podman pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA

    # Test: Run help command
    - podman run --rm $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA --help

    # Test: Validate config (mount config directory)
    - podman run --rm
      -v $(pwd)/config:/app/config:ro
      $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA validate
  dependencies:
    - build
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

# Release tagged versions
release:
  stage: release
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip git curl
    - pip3 install awscli
    - aws ecr get-login-password --region $AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
    # Install glab CLI
    - curl -s https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest/downloads/glab_Linux_x86_64.tar.gz |
      tar -xz -C /usr/local/bin
  script:
    # Pull commit-based image
    - podman pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA

    # Tag with semantic version
    - podman tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
      $CONTAINER_IMAGE:$CI_COMMIT_TAG

    # Create major and minor tags
    - export MAJOR=$(echo $CI_COMMIT_TAG | cut -d. -f1)
    - export MINOR=$(echo $CI_COMMIT_TAG | cut -d. -f1-2)
    - podman tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:$MAJOR
    - podman tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:$MINOR

    # Push all version tags
    - podman push $CONTAINER_IMAGE:$CI_COMMIT_TAG
    - podman push $CONTAINER_IMAGE:$MAJOR
    - podman push $CONTAINER_IMAGE:$MINOR

    # Create GitLab release
    - |
      glab release create $CI_COMMIT_TAG \
        --notes "## AWS ECR Container Image

      Pull and run this release:
      \`\`\`bash
      # Login to ECR
      aws ecr get-login-password --region $AWS_REGION | \\
        podman login --username AWS --password-stdin $ECR_REGISTRY

      # Pull image
      podman pull $CONTAINER_IMAGE:$CI_COMMIT_TAG

      # Run deployment
      podman run --rm \\
        -v \$(pwd)/config:/app/config:ro \\
        -v ~/.aws:/root/.aws:ro \\
        $CONTAINER_IMAGE:$CI_COMMIT_TAG deploy
      \`\`\`

      ## Available Tags
      - \`$CI_COMMIT_TAG\` (exact version)
      - \`$MINOR\` (minor version)
      - \`$MAJOR\` (major version)

      ## Image Details
      - **Registry:** AWS ECR
      - **Region:** $AWS_REGION
      - **URI:** \`$CONTAINER_IMAGE:$CI_COMMIT_TAG\`

      ## What's Changed
      See [CHANGELOG.md](./CHANGELOG.md)
      "
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  dependencies:
    - build

# Deploy to environments
deploy:sit:
  stage: deploy
  image: $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
  before_script:
    - pip install awscli
  script:
    - python scripts/deploy.py --environment sit
  rules:
    - if: $CI_COMMIT_BRANCH == "sit"
  environment:
    name: sit

deploy:uat:
  stage: deploy
  image: $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
  before_script:
    - pip install awscli
  script:
    - python scripts/deploy.py --environment uat
  rules:
    - if: $CI_COMMIT_BRANCH == "uat"
  environment:
    name: uat

deploy:prod:
  stage: deploy
  image: $CONTAINER_IMAGE:$CI_COMMIT_TAG
  before_script:
    - pip install awscli
  script:
    - python scripts/deploy.py --environment prod
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
  environment:
    name: prod
```

---

## Pull and Run Images

### Developer Workflow

```bash
# 1. Login to ECR (valid for 12 hours)
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# 2. Pull specific version
podman pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0

# 3. Run deployment
podman run --rm \
  -v $(pwd)/config:/app/config:ro \
  -v ~/.aws:/root/.aws:ro \
  -e AWS_PROFILE=default \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0 deploy
```

### Convenience Script

Create `scripts/run-ecr-container.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_NAME="aws-network-cdk"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_IMAGE="$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "=== AWS ECR Container Runner ==="
echo "Registry: $ECR_REGISTRY"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
  podman login --username AWS --password-stdin "$ECR_REGISTRY"

# Pull image
echo "Pulling image..."
podman pull "$CONTAINER_IMAGE"

# Run container
echo "Running container..."
podman run --rm \
  -v "$(pwd)/config:/app/config:ro" \
  -v "$HOME/.aws:/root/.aws:ro" \
  -e AWS_PROFILE="${AWS_PROFILE:-default}" \
  "$CONTAINER_IMAGE" "$@"
```

**Usage:**
```bash
chmod +x scripts/run-ecr-container.sh

# Run with latest tag
./scripts/run-ecr-container.sh deploy

# Run with specific version
IMAGE_TAG=v1.0.0 ./scripts/run-ecr-container.sh deploy

# List stacks
./scripts/run-ecr-container.sh --list-stacks
```

---

## Lifecycle Policies

### Why Lifecycle Policies?

ECR charges for storage (~$0.10/GB/month). Lifecycle policies automatically delete old images to save costs.

### Recommended Policy: Keep Last 10 Images

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

### Apply via AWS CLI

```bash
# Save policy to file
cat > lifecycle-policy.json <<'EOF'
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF

# Apply policy
aws ecr put-lifecycle-policy \
  --repository-name aws-network-cdk \
  --lifecycle-policy-text file://lifecycle-policy.json \
  --region us-east-1
```

### Apply via Console

1. Go to ECR → Repositories → aws-network-cdk
2. Click "Lifecycle Policy"
3. Create rule:
   - **Rule priority:** 1
   - **Description:** Keep last 10 images
   - **Image status:** Any
   - **Match criteria:** Image count more than 10
   - **Action:** Expire

---

## Cost Estimation

### ECR Pricing (us-east-1, as of 2024)

| Item | Price | Notes |
|------|-------|-------|
| **Storage** | $0.10/GB/month | First 50GB: $0.10/GB |
| **Data Transfer OUT** | $0.09/GB | To internet (first 100GB free) |
| **Data Transfer IN** | Free | Uploads to ECR |
| **Data Transfer (same region)** | Free | ECR → EC2 same region |

### Estimated Monthly Cost

**Scenario:** 10 images, ~250MB each, keep for 3 months

```
Storage:
- Image size: 250MB per image
- Keep last 10 images: 2.5GB
- Cost: 2.5GB × $0.10/GB = $0.25/month

Data Transfer:
- Deploy 20 times/month
- Pull 250MB × 20 = 5GB
- Same region (ECR → GitLab runner in AWS): FREE
- Different region: 5GB × $0.02/GB = $0.10/month

Total: ~$0.25-$0.35/month
```

**Annual cost:** ~$3-$4/year (negligible)

---

## Best Practices

### 1. Authentication Management

```bash
# Use helper script for automatic login
# scripts/ecr-login.sh checks for expired credentials
#!/usr/bin/env bash
if ! podman login $ECR_REGISTRY 2>&1 | grep -q "Login Succeeded"; then
  aws ecr get-login-password --region $AWS_REGION | \
    podman login --username AWS --password-stdin $ECR_REGISTRY
fi
```

### 2. Tagging Strategy

```bash
# Always tag with:
# 1. Commit SHA (for traceability)
# 2. Semantic version (for releases)
# 3. Latest (for main branch only)

podman tag image:build $ECR_REGISTRY/$REPO_NAME:$CI_COMMIT_SHA
podman tag image:build $ECR_REGISTRY/$REPO_NAME:v1.0.0
podman tag image:build $ECR_REGISTRY/$REPO_NAME:latest  # main only
```

### 3. Security Scanning

Enable in ECR console or via CLI:
```bash
aws ecr put-image-scanning-configuration \
  --repository-name aws-network-cdk \
  --image-scanning-configuration scanOnPush=true \
  --region us-east-1
```

### 4. Cross-Region Replication (Optional)

For disaster recovery:
```bash
# Enable replication to another region
aws ecr put-replication-configuration \
  --replication-configuration file://replication.json
```

### 5. IAM Best Practices

- Use IAM roles for GitLab runners (not access keys)
- Least privilege: Grant only ECR permissions needed
- Separate read/write permissions for CI/CD vs developers

---

## Troubleshooting

### Error: "no basic auth credentials"

**Cause:** Not logged in or credentials expired (12-hour limit)

**Fix:**
```bash
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin <ecr-registry>
```

### Error: "denied: Your authorization token has expired"

**Cause:** ECR login expired (after 12 hours)

**Fix:** Re-run login command

### Error: "repository does not exist"

**Cause:** Repository not created in ECR

**Fix:**
```bash
aws ecr create-repository --repository-name aws-network-cdk --region us-east-1
```

### Error: "AccessDeniedException"

**Cause:** IAM user/role lacks ECR permissions

**Fix:** Add `AmazonEC2ContainerRegistryPowerUser` policy to IAM user/role

---

## Summary

### Quick Reference

**ECR Registry Format:**
```
<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>

Example:
123456789012.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0
```

**Common Commands:**
```bash
# Login
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin <ecr-registry>

# Build and push
podman build -t aws-network-cdk:v1.0.0 -f Containerfile .
podman tag aws-network-cdk:v1.0.0 <ecr-registry>/aws-network-cdk:v1.0.0
podman push <ecr-registry>/aws-network-cdk:v1.0.0

# Pull and run
podman pull <ecr-registry>/aws-network-cdk:v1.0.0
podman run --rm <ecr-registry>/aws-network-cdk:v1.0.0 deploy
```

---

## Next Steps

1. **Create ECR Repository** (5 minutes)
   - Via Console or AWS CLI
   - Note the repository URI

2. **Configure GitLab CI/CD Variables** (5 minutes)
   - Add AWS credentials to GitLab
   - Set AWS_ACCOUNT_ID and AWS_REGION

3. **Create Containerfile** (if not exists)
   - Follow PYTHON_DOCKER_COMPARISON.md guide

4. **Update .gitlab-ci.yml** (10 minutes)
   - Use template from this document
   - Test build and push

5. **Test Locally** (5 minutes)
   - Login to ECR
   - Pull and run image

6. **Set Lifecycle Policy** (2 minutes)
   - Keep last 10 images
   - Reduce storage costs

**Total Time:** ~30 minutes setup

---

**Document Owner:** SRE Team
**Last Updated:** 2025-10-22
