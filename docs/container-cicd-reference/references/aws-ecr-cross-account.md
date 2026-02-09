# AWS ECR Cross-Account Setup Guide

**Document Version:** 1.0
**Date:** 2025-10-22
**Project:** AWS Network Account CDK Infrastructure
**Scenario:** ECR in Account A, Deploy to Accounts B, C, D (sit/uat/prod)

---

## Executive Summary

This document covers **cross-account ECR access** where:
- **ECR Repository:** In a central/shared AWS account (Account A)
- **Deployment Targets:** Different AWS accounts (Account B for sit, Account C for uat, Account D for prod)

**This is a common enterprise pattern** for centralized container image management.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Cross-Account ECR Setup                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐                                  │
│  │   Account A          │                                  │
│  │   (Central/Shared)   │                                  │
│  │                      │                                  │
│  │  ┌────────────────┐  │                                  │
│  │  │  ECR Repository│  │                                  │
│  │  │                │  │                                  │
│  │  │  aws-network-  │  │                                  │
│  │  │  cdk           │  │                                  │
│  │  │                │  │                                  │
│  │  │  Images:       │  │                                  │
│  │  │  - v1.0.0      │  │                                  │
│  │  │  - latest      │  │                                  │
│  │  └────────────────┘  │                                  │
│  └──────────────────────┘                                  │
│           │                                                 │
│           │ Cross-Account Pull Access                      │
│           │                                                 │
│  ┌────────┴────────┬────────────────┬────────────────┐    │
│  │                 │                │                │    │
│  ▼                 ▼                ▼                ▼    │
│ ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│ │Account B│  │Account C│  │Account D│  │GitLab CI│      │
│ │ (SIT)   │  │ (UAT)   │  │ (PROD)  │  │         │      │
│ │         │  │         │  │         │  │         │      │
│ │  Pull   │  │  Pull   │  │  Pull   │  │  Push   │      │
│ │  Images │  │  Images │  │  Images │  │  Images │      │
│ │  Deploy │  │  Deploy │  │  Deploy │  │         │      │
│ └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
└─────────────────────────────────────────────────────────────┘
```

---

## Account Structure

### Example Setup

| Account | Account ID | Purpose | ECR Access Needed |
|---------|-----------|---------|-------------------|
| **Account A** | `111111111111` | Central ECR | Push (GitLab CI) |
| **Account B** | `222222222222` | SIT environment | Pull (deploy) |
| **Account C** | `333333333333` | UAT environment | Pull (deploy) |
| **Account D** | `444444444444` | PROD environment | Pull (deploy) |

**Your Scenario:**
- ECR Repository: `111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk`
- Deploy targets: Accounts B, C, D

---

## Setup Steps

### Step 1: Create ECR Repository (Account A - Central)

In the **central account** (where ECR lives):

```bash
# Account A: 111111111111
aws ecr create-repository \
  --repository-name aws-network-cdk \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true
```

**Result:**
```
Repository URI: 111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk
```

---

### Step 2: Configure ECR Repository Policy (Account A)

**ECR repository policy** grants cross-account access.

#### Option A: Via AWS Console

1. Go to ECR → Repositories → aws-network-cdk
2. Click "Permissions" → "Edit policy JSON"
3. Add policy (see below)

#### Option B: Via AWS CLI

```bash
# Save policy to file
cat > ecr-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::222222222222:root",
          "arn:aws:iam::333333333333:root",
          "arn:aws:iam::444444444444:root"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    },
    {
      "Sid": "AllowCrossAccountDescribe",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::222222222222:root",
          "arn:aws:iam::333333333333:root",
          "arn:aws:iam::444444444444:root"
        ]
      },
      "Action": [
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ]
    }
  ]
}
EOF

# Apply policy
aws ecr set-repository-policy \
  --repository-name aws-network-cdk \
  --policy-text file://ecr-policy.json \
  --region us-east-1
```

**Replace Account IDs:**
- `222222222222` = Your SIT account
- `333333333333` = Your UAT account
- `444444444444` = Your PROD account

---

### Step 3: Configure IAM in Target Accounts (B, C, D)

In **each deployment account**, create an IAM policy for ECR pull access.

#### Create IAM Policy (in Accounts B, C, D)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowECRPullFromCentralAccount",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowPullFromSpecificRepository",
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecr:ListImages"
      ],
      "Resource": "arn:aws:ecr:us-east-1:111111111111:repository/aws-network-cdk"
    }
  ]
}
```

**Apply via AWS CLI (in each target account):**

```bash
# In Account B (SIT)
aws iam create-policy \
  --policy-name ECRCrossAccountPullPolicy \
  --policy-document file://ecr-pull-policy.json

# Attach to IAM user/role that will deploy
aws iam attach-user-policy \
  --user-name deploy-user \
  --policy-arn arn:aws:iam::222222222222:policy/ECRCrossAccountPullPolicy

# Or attach to IAM role
aws iam attach-role-policy \
  --role-name deploy-role \
  --policy-arn arn:aws:iam::222222222222:policy/ECRCrossAccountPullPolicy
```

**Repeat for Accounts C and D.**

---

### Step 4: Test Cross-Account Access

From a deployment account (e.g., Account B - SIT):

```bash
# Authenticate to Account B
export AWS_PROFILE=sit-account  # Or use Account B credentials

# Login to ECR in Account A (central)
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin \
  111111111111.dkr.ecr.us-east-1.amazonaws.com

# Pull image from Account A's ECR
podman pull 111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:latest

# Expected: Image pulls successfully ✅
```

**If this works, cross-account access is configured correctly!**

---

## GitLab CI/CD Configuration

### GitLab Variables Setup

Since you have **multiple AWS accounts**, configure variables per environment:

#### Global Variables (Settings → CI/CD → Variables)

```
# ECR Account (Account A - where images are stored)
ECR_AWS_ACCESS_KEY_ID      = <account-a-access-key>
ECR_AWS_SECRET_ACCESS_KEY  = <account-a-secret-key>
ECR_AWS_ACCOUNT_ID         = 111111111111
ECR_AWS_REGION            = us-east-1

# Deployment accounts (for CDK deployments)
SIT_AWS_ACCESS_KEY_ID     = <account-b-access-key>
SIT_AWS_SECRET_ACCESS_KEY = <account-b-secret-key>

UAT_AWS_ACCESS_KEY_ID     = <account-c-access-key>
UAT_AWS_SECRET_ACCESS_KEY = <account-c-secret-key>

PROD_AWS_ACCESS_KEY_ID    = <account-d-access-key>
PROD_AWS_SECRET_ACCESS_KEY = <account-d-secret-key>
```

---

### Updated .gitlab-ci.yml

```yaml
# .gitlab-ci.yml
variables:
  ECR_REGISTRY: $ECR_AWS_ACCOUNT_ID.dkr.ecr.$ECR_AWS_REGION.amazonaws.com
  IMAGE_NAME: aws-network-cdk
  CONTAINER_IMAGE: $ECR_REGISTRY/$IMAGE_NAME

stages:
  - validate
  - build
  - test
  - release
  - deploy

# Build and push to ECR (Account A)
build:
  stage: build
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    # Use ECR account credentials (Account A)
    - export AWS_ACCESS_KEY_ID=$ECR_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$ECR_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    # Login to ECR in Account A
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - podman build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA -f Containerfile .
    - podman tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        podman tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:latest
      fi
    - podman push $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        podman push $CONTAINER_IMAGE:latest
      fi
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

# Deploy to SIT (Account B)
deploy:sit:
  stage: deploy
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    # Use SIT account credentials (Account B) for deployment
    - export AWS_ACCESS_KEY_ID=$SIT_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$SIT_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    # Login to ECR (cross-account pull from Account A)
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    # Pull image from Account A's ECR
    - podman pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    # Run deployment to Account B
    - podman run --rm
      -e AWS_ACCESS_KEY_ID=$SIT_AWS_ACCESS_KEY_ID
      -e AWS_SECRET_ACCESS_KEY=$SIT_AWS_SECRET_ACCESS_KEY
      -e AWS_DEFAULT_REGION=us-east-1
      -v $(pwd)/config:/app/config:ro
      $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
      python scripts/deploy.py --environment sit
  rules:
    - if: $CI_COMMIT_BRANCH == "sit"
  environment:
    name: sit

# Deploy to UAT (Account C)
deploy:uat:
  stage: deploy
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    # Use UAT account credentials (Account C)
    - export AWS_ACCESS_KEY_ID=$UAT_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$UAT_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    # Login to ECR (cross-account pull from Account A)
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - podman pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - podman run --rm
      -e AWS_ACCESS_KEY_ID=$UAT_AWS_ACCESS_KEY_ID
      -e AWS_SECRET_ACCESS_KEY=$UAT_AWS_SECRET_ACCESS_KEY
      -e AWS_DEFAULT_REGION=us-east-1
      -v $(pwd)/config:/app/config:ro
      $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
      python scripts/deploy.py --environment uat
  rules:
    - if: $CI_COMMIT_BRANCH == "uat"
  environment:
    name: uat

# Deploy to PROD (Account D)
deploy:prod:
  stage: deploy
  image: quay.io/podman/stable:latest
  before_script:
    - apk add --no-cache python3 py3-pip
    - pip3 install awscli
    # Use PROD account credentials (Account D)
    - export AWS_ACCESS_KEY_ID=$PROD_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$PROD_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    # Login to ECR (cross-account pull from Account A)
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      podman login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - podman pull $CONTAINER_IMAGE:$CI_COMMIT_TAG
    - podman run --rm
      -e AWS_ACCESS_KEY_ID=$PROD_AWS_ACCESS_KEY_ID
      -e AWS_SECRET_ACCESS_KEY=$PROD_AWS_SECRET_ACCESS_KEY
      -e AWS_DEFAULT_REGION=us-east-1
      -v $(pwd)/config:/app/config:ro
      $CONTAINER_IMAGE:$CI_COMMIT_TAG
      python scripts/deploy.py --environment prod
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
  environment:
    name: prod
```

---

## Local Development Workflow

### Scenario: Developer Deploying to SIT

```bash
# 1. Configure AWS credentials for SIT account (Account B)
export AWS_PROFILE=sit-account  # Or configure credentials for Account B

# 2. Login to ECR in Account A (cross-account)
aws ecr get-login-password --region us-east-1 | \
  podman login --username AWS --password-stdin \
  111111111111.dkr.ecr.us-east-1.amazonaws.com

# 3. Pull image from Account A's ECR
podman pull 111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:latest

# 4. Run deployment to Account B (SIT)
podman run --rm \
  -v $(pwd)/config:/app/config:ro \
  -v ~/.aws:/root/.aws:ro \
  -e AWS_PROFILE=sit-account \
  111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:latest deploy
```

---

## Convenience Script for Cross-Account

Create `scripts/run-ecr-cross-account.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
ECR_ACCOUNT_ID="${ECR_ACCOUNT_ID:-111111111111}"  # Account A (ECR)
ECR_REGION="${ECR_REGION:-us-east-1}"
IMAGE_NAME="aws-network-cdk"
IMAGE_TAG="${IMAGE_TAG:-latest}"

DEPLOY_ACCOUNT_PROFILE="${DEPLOY_ACCOUNT_PROFILE:-default}"  # Account B/C/D
ECR_REGISTRY="$ECR_ACCOUNT_ID.dkr.ecr.$ECR_REGION.amazonaws.com"
CONTAINER_IMAGE="$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "=== AWS ECR Cross-Account Container Runner ==="
echo "ECR Account: $ECR_ACCOUNT_ID"
echo "Deploy Account: Using profile '$DEPLOY_ACCOUNT_PROFILE'"
echo "Image: $CONTAINER_IMAGE"
echo ""

# Login to ECR (using deploy account credentials for cross-account pull)
echo "Logging into ECR (cross-account)..."
aws ecr get-login-password --region "$ECR_REGION" --profile "$DEPLOY_ACCOUNT_PROFILE" | \
  podman login --username AWS --password-stdin "$ECR_REGISTRY"

# Pull image
echo "Pulling image..."
podman pull "$CONTAINER_IMAGE"

# Run container with deploy account credentials
echo "Running container..."
podman run --rm \
  -v "$(pwd)/config:/app/config:ro" \
  -v "$HOME/.aws:/root/.aws:ro" \
  -e AWS_PROFILE="$DEPLOY_ACCOUNT_PROFILE" \
  "$CONTAINER_IMAGE" "$@"
```

**Usage:**
```bash
chmod +x scripts/run-ecr-cross-account.sh

# Deploy to SIT (Account B)
DEPLOY_ACCOUNT_PROFILE=sit-account ./scripts/run-ecr-cross-account.sh deploy

# Deploy to UAT (Account C)
DEPLOY_ACCOUNT_PROFILE=uat-account ./scripts/run-ecr-cross-account.sh deploy

# Deploy to PROD (Account D) with specific version
DEPLOY_ACCOUNT_PROFILE=prod-account IMAGE_TAG=v1.0.0 ./scripts/run-ecr-cross-account.sh deploy
```

---

## AWS CLI Profiles Configuration

Configure `~/.aws/credentials` and `~/.aws/config`:

```ini
# ~/.aws/credentials
[ecr-account]
aws_access_key_id = <account-a-key>
aws_secret_access_key = <account-a-secret>

[sit-account]
aws_access_key_id = <account-b-key>
aws_secret_access_key = <account-b-secret>

[uat-account]
aws_access_key_id = <account-c-key>
aws_secret_access_key = <account-c-secret>

[prod-account]
aws_access_key_id = <account-d-key>
aws_secret_access_key = <account-d-secret>
```

```ini
# ~/.aws/config
[profile ecr-account]
region = us-east-1
output = json

[profile sit-account]
region = us-east-1
output = json

[profile uat-account]
region = us-east-1
output = json

[profile prod-account]
region = us-east-1
output = json
```

---

## Troubleshooting Cross-Account Access

### Error: "no basic auth credentials"

**Cause:** Using wrong AWS account credentials for ECR login

**Fix:** Use deployment account credentials (B/C/D) for cross-account pull:
```bash
# Use sit-account credentials to pull from Account A's ECR
aws ecr get-login-password --region us-east-1 --profile sit-account | \
  podman login --username AWS --password-stdin \
  111111111111.dkr.ecr.us-east-1.amazonaws.com
```

---

### Error: "denied: User is not authorized to perform: ecr:BatchGetImage"

**Cause:** Missing ECR repository policy or IAM policy

**Fix:**
1. Check ECR repository policy in Account A includes target account ARN
2. Check IAM policy in target account allows ECR pull from Account A

---

### Error: "repository does not exist or may require 'docker login'"

**Cause:** Wrong ECR account ID or region

**Fix:** Verify ECR registry URL matches Account A:
```bash
# Should be Account A's ID (111111111111), not deployment account ID
111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk
```

---

## Security Best Practices

### 1. Least Privilege

**ECR Repository Policy (Account A):**
- Only grant pull permissions (`BatchGetImage`, `GetDownloadUrlForLayer`)
- Don't grant push permissions to deployment accounts

**IAM Policies (Accounts B/C/D):**
- Only grant access to specific ECR repository
- Use resource-based restrictions

### 2. Use IAM Roles (Recommended)

For GitLab runners on EC2:
- Attach IAM role to EC2 instance
- No need to store access keys in GitLab variables
- Automatic credential rotation

### 3. Separate Push/Pull Credentials

- **Push (GitLab CI):** Use ECR account credentials (Account A)
- **Pull (Deploy):** Use deployment account credentials (B/C/D)

### 4. Enable ECR Image Scanning

In Account A:
```bash
aws ecr put-image-scanning-configuration \
  --repository-name aws-network-cdk \
  --image-scanning-configuration scanOnPush=true \
  --region us-east-1
```

---

## Cost Implications

**Cross-account ECR access does NOT incur additional costs.**

### Data Transfer Costs

| Scenario | Cost |
|----------|------|
| ECR (Account A) → Same region (Account B) | **FREE** |
| ECR (Account A) → Different region | Standard data transfer rates |
| ECR (Account A) → Internet | Standard egress rates |

**For your setup:**
- If all accounts in same region (us-east-1): **FREE data transfer**
- Only pay for ECR storage (~$0.10/GB/month)

---

## Summary Checklist

### Account A (ECR Account) Setup
- [ ] Create ECR repository
- [ ] Configure repository policy (allow Accounts B, C, D)
- [ ] Enable image scanning
- [ ] Set lifecycle policy (cleanup old images)

### Accounts B, C, D (Deployment Accounts) Setup
- [ ] Create IAM policy for cross-account ECR pull
- [ ] Attach policy to IAM user/role
- [ ] Test cross-account pull

### GitLab CI/CD Setup
- [ ] Add ECR account credentials (Account A)
- [ ] Add deployment account credentials (B, C, D)
- [ ] Update .gitlab-ci.yml with cross-account logic
- [ ] Test pipeline

### Local Development Setup
- [ ] Configure AWS CLI profiles (ecr-account, sit-account, etc.)
- [ ] Create convenience scripts
- [ ] Test local cross-account pull and deploy

---

## Quick Reference

### Account Structure
```
Account A (111111111111) = ECR Repository
Account B (222222222222) = SIT Deployment
Account C (333333333333) = UAT Deployment
Account D (444444444444) = PROD Deployment
```

### ECR Registry URL
```
111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:v1.0.0
```

### Cross-Account Pull Command
```bash
# Use deployment account credentials
aws ecr get-login-password --region us-east-1 --profile sit-account | \
  podman login --username AWS --password-stdin \
  111111111111.dkr.ecr.us-east-1.amazonaws.com

podman pull 111111111111.dkr.ecr.us-east-1.amazonaws.com/aws-network-cdk:latest
```

---

**Document Owner:** SRE Team
**Last Updated:** 2025-10-22
