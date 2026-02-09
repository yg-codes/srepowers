---
name: gitlab-ecr-pipeline
description: Use this skill when creating or modifying GitLab CI/CD pipelines that push container images to AWS ECR. Supports both building images from Containerfile/Dockerfile and mirroring upstream images to ECR. Requires GitLab project with AWS credentials configured as CI/CD variables.
skills:
  - container-cicd-reference
---

# GitLab ECR Pipeline

Generate GitLab CI/CD pipelines that push container images to Amazon Elastic Container Registry (ECR). This skill provides tested patterns for two common workflows:

1. **Build & Push** - Build a container image from Containerfile/Dockerfile and push to ECR
2. **Mirror & Push** - Pull an upstream image, re-tag it, and push to ECR

Both patterns use **Podman** instead of Docker to avoid Docker-in-Docker issues in GitLab CI runners.

## Quick Start

Identify the workflow needed:

| Workflow | When to Use | Source |
|----------|-------------|--------|
| Build & Push | Building images from source code | Containerfile/Dockerfile in repo |
| Mirror & Push | Mirroring third-party images to private ECR | Upstream image registry (Docker Hub, GHCR, Quay) |

Then read the corresponding section below for the complete pipeline template.

---

## Workflow 1: Build & Push

Build a container image from a Containerfile (or Dockerfile) in the repository and push it to AWS ECR.

### Prerequisites

Required GitLab CI/CD variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `ECR_AWS_ACCESS_KEY_ID` | AWS Access Key ID with ECR push permissions | `AKIAIOSFODNN7EXAMPLE` (⚠️ DO NOT use - example only) |
| `ECR_AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` (⚠️ DO NOT use - example only) |
| `ECR_AWS_REGION` | AWS region for ECR | `ap-northeast-1` |
| `ECR_AWS_ACCOUNT_ID` | AWS account ID (12 digits) | `455931011959` |

### Pipeline Template

```yaml
variables:
  ECR_REGISTRY: $ECR_AWS_ACCOUNT_ID.dkr.ecr.$ECR_AWS_REGION.amazonaws.com
  IMAGE_NAME: my-app
  CONTAINER_IMAGE: $ECR_REGISTRY/$IMAGE_NAME
  CONTAINER_ENGINE: podman

stages:
  - build
  - test
  - release

# Build container image and push to AWS ECR
build:
  stage: build
  image: quay.io/podman/stable:latest
  before_script:
    # Install AWS CLI
    - microdnf install -y python3 python3-pip
    - pip3 install awscli
    # Configure AWS credentials
    - export AWS_ACCESS_KEY_ID=$ECR_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$ECR_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    # Login to ECR
    - echo "Logging into ECR..."
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      $CONTAINER_ENGINE login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - echo "Building container image..."
    - $CONTAINER_ENGINE build -t $IMAGE_NAME:$CI_COMMIT_SHORT_SHA -f Containerfile .

    # Tag with commit SHA
    - $CONTAINER_ENGINE tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA

    # Tag as latest for main branch
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        echo "Tagging as latest..."
        $CONTAINER_ENGINE tag $IMAGE_NAME:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:latest
      fi

    # Push to ECR
    - echo "Pushing image to ECR..."
    - $CONTAINER_ENGINE push $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - |
      if [ "$CI_COMMIT_BRANCH" = "main" ]; then
        $CONTAINER_ENGINE push $CONTAINER_IMAGE:latest
      fi

    - echo "Image pushed successfully:"
    - echo "  $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA"
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG
  tags:
    - shared

# Optional: Test the built image
test:
  stage: test
  image: quay.io/podman/stable:latest
  before_script:
    - microdnf install -y python3 python3-pip
    - pip3 install awscli
    - export AWS_ACCESS_KEY_ID=$ECR_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$ECR_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      $CONTAINER_ENGINE login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - echo "Pulling image from ECR..."
    - $CONTAINER_ENGINE pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA
    - echo "Running tests..."
    - $CONTAINER_ENGINE run --rm --entrypoint <command> $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA <args>
    - echo "All tests passed!"
  dependencies:
    - build
  rules:
    - if: $CI_COMMIT_BRANCH
  tags:
    - shared

# Release tagged versions
release:
  stage: release
  image: quay.io/podman/stable:latest
  before_script:
    - microdnf install -y python3 python3-pip
    - pip3 install awscli
    - export AWS_ACCESS_KEY_ID=$ECR_AWS_ACCESS_KEY_ID
    - export AWS_SECRET_ACCESS_KEY=$ECR_AWS_SECRET_ACCESS_KEY
    - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
    - aws ecr get-login-password --region $ECR_AWS_REGION |
      $CONTAINER_ENGINE login --username AWS --password-stdin $ECR_REGISTRY
  script:
    - echo "Creating release for tag $CI_COMMIT_TAG..."
    - $CONTAINER_ENGINE pull $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA

    # Tag with semantic version
    - $CONTAINER_ENGINE tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:$CI_COMMIT_TAG

    # Create major and minor version tags
    - export MAJOR=$(echo $CI_COMMIT_TAG | sed 's/v//' | cut -d. -f1)
    - export MINOR=$(echo $CI_COMMIT_TAG | sed 's/v//' | cut -d. -f1-2)
    - $CONTAINER_ENGINE tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:v$MAJOR
    - $CONTAINER_ENGINE tag $CONTAINER_IMAGE:$CI_COMMIT_SHORT_SHA $CONTAINER_IMAGE:v$MINOR

    # Push all version tags
    - $CONTAINER_ENGINE push $CONTAINER_IMAGE:$CI_COMMIT_TAG
    - $CONTAINER_ENGINE push $CONTAINER_IMAGE:v$MAJOR
    - $CONTAINER_ENGINE push $CONTAINER_IMAGE:v$MINOR
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
  dependencies:
    - build
  tags:
    - shared
```

### Customization Points

| Variable | Change to |
|----------|----------|
| `IMAGE_NAME` | Your application name |
| `CONTAINER_ENGINE` | `docker` if using Docker (requires DinD service) |
| Containerfile path | `-f path/to/Dockerfile` if not in root |
| Test command | Modify `--entrypoint` and `<args>` for your app |

---

## Workflow 2: Mirror & Push

Pull an upstream container image from a public registry, re-tag it for ECR, and push. Use this when mirroring third-party images to your private registry.

### Pipeline Template

```yaml
variables:
  GRAVITY_IMAGE: ghcr.io/beryju/gravity
  GRAVITY_TAG: stable

stages:
  - publish

# Push upstream image to AWS ECR on tag
publish:ecr:
  stage: publish
  image: quay.io/podman/stable:latest
  before_script:
    # Install AWS CLI
    - microdnf install -y python3 python3-pip
    - pip3 install awscli
    # Configure AWS credentials
    - export AWS_ACCESS_KEY_ID=${ECR_AWS_ACCESS_KEY_ID}
    - export AWS_SECRET_ACCESS_KEY=${ECR_AWS_SECRET_ACCESS_KEY}
    - export AWS_DEFAULT_REGION=${ECR_AWS_REGION}
    # Login to ECR
    - echo "Logging into AWS ECR..."
    - aws ecr get-login-password --region ${ECR_AWS_REGION} |
      podman login --username AWS --password-stdin ${ECR_AWS_ACCOUNT_ID}.dkr.ecr.${ECR_AWS_REGION}.amazonaws.com
  script:
    - VERSION=${CI_COMMIT_TAG#v}
    - ECR_REGISTRY="${ECR_AWS_ACCOUNT_ID}.dkr.ecr.${ECR_AWS_REGION}.amazonaws.com"
    - ECR_REPOSITORY="${ECR_REGISTRY}/gravity"
    - echo "Pushing image to ECR ${ECR_REPOSITORY}:${VERSION}"

    # Pull upstream image
    - echo "Pulling upstream image..."
    - podman pull ${GRAVITY_IMAGE}:${GRAVITY_TAG}

    # Tag for ECR
    - echo "Tagging images..."
    - podman tag ${GRAVITY_IMAGE}:${GRAVITY_TAG} ${ECR_REPOSITORY}:${VERSION}
    - podman tag ${GRAVITY_IMAGE}:${GRAVITY_TAG} ${ECR_REPOSITORY}:latest

    # Push to ECR
    - echo "Pushing to ECR..."
    - podman push ${ECR_REPOSITORY}:${VERSION}
    - podman push ${ECR_REPOSITORY}:latest

    - echo "Image pushed successfully:"
    - echo "  ${ECR_REPOSITORY}:${VERSION}"
    - echo "  ${ECR_REPOSITORY}:latest"
  rules:
    - if: $CI_COMMIT_TAG =~ /^v[0-9]+\.[0-9]+\.[0-9]+$/
  tags:
    - shared
```

### Customization Points

| Variable | Change to |
|----------|----------|
| `GRAVITY_IMAGE` | Upstream image repository |
| `GRAVITY_TAG` | Upstream image tag (e.g., `stable`, `latest`, `v1.0.0`) |
| `ECR_REPOSITORY` | ECR repository name (after registry/) |

---

## Common Patterns

### ECR Login (Standard Pattern)

All ECR jobs require this login sequence:

```yaml
before_script:
  - microdnf install -y python3 python3-pip
  - pip3 install awscli
  - export AWS_ACCESS_KEY_ID=$ECR_AWS_ACCESS_KEY_ID
  - export AWS_SECRET_ACCESS_KEY=$ECR_AWS_SECRET_ACCESS_KEY
  - export AWS_DEFAULT_REGION=$ECR_AWS_REGION
  - aws ecr get-login-password --region $ECR_AWS_REGION |
    podman login --username AWS --password-stdin $ECR_REGISTRY
```

### Tag Patterns

| Git Variable | Description | Example Output |
|--------------|-------------|----------------|
| `$CI_COMMIT_SHORT_SHA` | First 8 characters of commit SHA | `f2ac2bc` |
| `${CI_COMMIT_TAG#v}` | Tag without 'v' prefix | `1.2.3` from `v1.2.3` |
| `$CI_COMMIT_TAG` | Full tag | `v1.2.3` |

### Version Tagging Strategy

For semantic versioning, create multiple tags:

```bash
# Given tag v1.2.3
export MAJOR=$(echo $CI_COMMIT_TAG | sed 's/v//' | cut -d. -f1)    # 1
export MINOR=$(echo $CI_COMMIT_TAG | sed 's/v//' | cut -d. -f1-2)  # 1.2
# Results in tags: v1.2.3, v1.2, v1
```

### Why Podman Instead of Docker?

Podman is recommended for GitLab CI/CD because:

1. **No DinD service required** - Docker-in-Docker adds complexity and can fail with proxy/firewall issues
2. **Daemonless** - No background daemon needed
3. **Drop-in compatible** - Same CLI syntax as Docker

To use Docker instead, add the service and adjust configuration:

```yaml
image: docker:24-cli
services:
  - docker:24-dind
variables:
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"
```

---

## Creating the ECR Repository

Before the pipeline runs, create the ECR repository:

```bash
aws ecr create-repository \
  --repository-name my-app \
  --region ap-northeast-1 \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256
```

Optional: Add lifecycle policy to keep only last N images:

```bash
aws ecr put-lifecycle-policy \
  --repository-name my-app \
  --region ap-northeast-1 \
  --lifecycle-policy-text '{
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
  }'
```

---

## Troubleshooting

### Job fails with "Access Denied"

**Cause:** Missing or invalid AWS credentials.

**Solution:** Verify all four ECR variables are set in GitLab CI/CD configuration.

### Job fails with "link is not supported"

**Cause:** Docker-in-Docker service incompatibility with GitLab runner.

**Solution:** Switch to Podman (see templates above).

### "no basic auth credentials" error

**Cause:** ECR login failed.

**Solution:** Check `ECR_AWS_REGION` and `ECR_AWS_ACCOUNT_ID` variables are correct.

### Pod image pull fails in cluster

**Cause:** Kubernetes nodes cannot pull from ECR.

**Solution:** Configure IAM role for nodes or create image pull secret.

---

## Resources

### references/build-push-template.yml
Complete Build & Push pipeline template with all stages included.

### references/mirror-push-template.yml
Complete Mirror & Push pipeline template for mirroring upstream images.

---

## Related Reference Documentation

For detailed ECR setup, cross-account configuration, and authentication guidance, refer to the **container-cicd-reference** skill (auto-loaded):

- **ECR Repository Setup** - `container-cicd-reference/references/aws-ecr-setup.md`
  - Complete ECR repository creation and configuration
  - Authentication methods and best practices
  - Lifecycle policies and cost optimization

- **Cross-Account ECR Access** - `container-cicd-reference/references/aws-ecr-cross-account.md`
  - Multi-account deployment architecture
  - Repository policy configuration
  - Cross-account IAM permissions

- **IAM Authentication** - `container-cicd-reference/references/aws-iam-auth.md`
  - IAM User vs IAM Role decision guide
  - GitLab CI/CD authentication patterns
  - Security and maintenance considerations

- **GitLab Registry Check** - `container-cicd-reference/references/gitlab-registry-check.md`
  - Verify GitLab Container Registry availability
  - Configuration validation methods
  - Alternative registry options
