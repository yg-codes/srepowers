---
name: gitlab-cicd
description: Use when creating, modifying, or debugging GitLab CI/CD pipelines on self-hosted GitLab instances — writing .gitlab-ci.yml files, managing GitLab Runners, using the glab CLI, automating GitLab API operations, debugging failed pipeline jobs, or setting up multi-environment deployment pipelines. Also use for "gitlab pipeline", "ci/cd config", "gitlab-runner", "glab", "pipeline failed", "job timeout", "fix CI", ".gitlab-ci.yml", "gitlab ci", or any GitLab CI/CD pipeline task beyond ECR image pushing.
---

# GitLab CI/CD

Author, debug, and manage GitLab CI/CD pipelines for self-hosted GitLab instances. Covers `.gitlab-ci.yml` authoring, runner management, the `glab` CLI, and pipeline debugging.

**Core principle:** Validate YAML before push, test in a feature branch, protect main/prod pipelines.

**Announce at start:** "I'm using the gitlab-cicd skill to [create/debug/manage] GitLab CI/CD pipelines."

## When to Use

**Use when:**
- Writing or modifying `.gitlab-ci.yml` files
- Debugging failed pipeline jobs
- Setting up new GitLab Runners
- Using `glab` CLI for pipeline operations
- Creating multi-environment deployment pipelines (sit → uat → prod)
- Managing CI/CD variables and secrets
- Configuring pipeline triggers, schedules, or rules
- Working with GitLab's CI/CD API

**Not for:**
- ECR-specific image pushing — use `gitlab-ecr-pipeline`
- General Git operations — use standard git workflow

## Pipeline Authoring

### .gitlab-ci.yml Structure

```yaml
stages:
  - validate
  - test
  - build
  - deploy

variables:
  APP_NAME: myapp

# Global defaults
default:
  image: ruby:3.2
  before_script:
    - echo "Starting $CI_JOB_NAME"

# Reusable configuration
.build_template: &build_template
  stage: build
  script:
    - make build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week

validate:
  stage: validate
  script:
    - make lint
    - make validate

test:
  stage: test
  script:
    - make test
  coverage: '/Coverage: \d+\.\d+/'

build:
  <<: *build_template
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy_sit:
  stage: deploy
  script:
    - make deploy ENV=sit
  environment:
    name: sit
    url: https://sit.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "sit"

deploy_uat:
  stage: deploy
  script:
    - make deploy ENV=uat
  environment:
    name: uat
    url: https://uat.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "uat"
  needs: [deploy_sit]  # Must pass SIT first
```

### Key Concepts

| Concept | Keyword | Purpose |
|---------|---------|---------|
| Stage ordering | `stages:` | Define job execution order |
| Conditional jobs | `rules:` / `only:` / `except:` | Control when jobs run |
| Reusable config | `extends:` / YAML anchors | DRY pipeline definitions |
| Artifacts | `artifacts:` | Pass files between jobs |
| Caching | `cache:` | Speed up repeated builds |
| Environments | `environment:` | Track deployments, enable rollback |
| Variables | `variables:` | Configure job behavior |
| Parallel | `parallel:` / `parallel:matrix:` | Run jobs in parallel variants |

### Pipeline Rules (modern approach)

```yaml
# Run on default branch only
rules:
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

# Run on MRs only
rules:
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"

# Run on tags
rules:
  - if: $CI_COMMIT_TAG

# Manual trigger on prod
rules:
  - if: $CI_COMMIT_BRANCH == "prod"
    when: manual
    allow_failure: false  # Must succeed for pipeline to pass
```

## Runner Management

### Check Runner Status

```bash
# List runners for a project
glab api projects/:id/runners

# List shared runners (admin)
glab api admin/runners

# Check runner details
glab api admin/runners/<runner_id>
```

### Common Runner Types

| Type | Scope | Use for |
|------|-------|---------|
| Shared | All projects | Common tooling (lint, test) |
| Group | Projects in group | Group-specific builds |
| Specific | Single project | Specialized builds |
| Instance | All projects (admin) | Privileged operations |

### Runner Tags

Use tags to route jobs to specific runners:

```yaml
job:
  tags:
    - docker
    - linux
  script:
    - make build
```

### Docker Runner Configuration

```toml
# /etc/gitlab-runner/config.toml
[[runners]]
  name = "docker-runner"
  executor = "docker"
  [runners.docker]
    image = "ruby:3.2"
    volumes = ["/cache"]
    pull_policy = "if-not-present"
```

## glab CLI Quick Reference

```bash
# Pipeline operations
glab ci list                    # List pipelines
glab ci status                  # Current pipeline status
glab ci trace                   # Stream current job logs
glab ci run                     # Trigger a pipeline
glab ci retry <job-id>          # Retry a failed job
glab ci artifact download       # Download job artifacts

# Variable management
glab variable list              # List CI/CD variables
glab variable set KEY VALUE     # Set a variable
glab variable set KEY VALUE --masked   # Masked (hidden in logs)
glab variable set KEY VALUE --protected # Protected (protected branches only)

# MR operations (pipeline-related)
glab mr create --fill           # Create MR
glab mr view                    # View MR details
glab mr merge                   # Merge MR

# General API
glab api <endpoint>             # Hit any GitLab API endpoint
```

## Debugging Failed Pipelines

### Step 1: Identify the Failure

```bash
# Get the failed pipeline
glab ci status
glab ci list --status failed

# View the failed job log
glab ci trace
```

### Step 2: Common Failure Categories

| Symptom | Likely cause | Debug command |
|---------|-------------|---------------|
| `exit code 1` with no clear error | Script error in `before_script` or `script` | Read the full job log |
| `permission denied` | Wrong Docker image or missing tool | Check `image:` and runner tags |
| `timeout` | Job exceeds `timeout:` or runner limit | Increase timeout or optimize job |
| `artifact not found` | Previous job didn't produce expected artifact | Check `artifacts:` config in upstream job |
| `variable not set` | Missing CI/CD variable | `glab variable list` |
| `runner unavailable` | No runner with matching tags | Check runner tags and online status |
| YAML error | Invalid `.gitlab-ci.yml` syntax | Use CI lint (see below) |

### Step 3: Validate YAML Locally

```bash
# Validate CI YAML via GitLab API
glab api -X POST "projects/:id/ci/lint" \
  --field content="$(cat .gitlab-ci.yml)"
```

### Step 4: Debug Interactively

```bash
# Run a job locally with gitlab-runner (if available)
gitlab-runner exec docker <job-name>

# Add debug output to the job
script:
  - env | sort
  - set -x  # Enable command tracing
  - make build
```

## CI/CD Variables and Secrets

### Variable Scoping

| Scope | Where to set | Access |
|-------|-------------|--------|
| Project | Settings → CI/CD → Variables | That project's pipelines |
| Group | Group → Settings → CI/CD → Variables | All projects in group |
| Instance (admin) | Admin → Settings → CI/CD → Variables | All projects |
| `.gitlab-ci.yml` | `variables:` block | All jobs (overrideable) |

### Variable Protection Levels

- **Protected**: Only available on protected branches/tags
- **Masked**: Hidden in job logs (must match masking requirements)
- **Expanded**: Variable expansion enabled (default)

```bash
# Set a protected, masked variable
glab variable set DEPLOY_KEY "-----BEGIN..." --masked --protected
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Hardcoded credentials in `.gitlab-ci.yml` | Visible in git history | Use CI/CD variables (masked + protected) |
| `when: always` on deploy jobs | Deploys even when tests fail | Use `rules:` with branch conditions |
| Single monolithic job | Slow, hard to debug | Split into stages with clear responsibilities |
| `allow_failure: true` on critical jobs | Silently passes broken pipelines | Only use on non-critical (lint, optional) jobs |
| No `artifacts:expire_in` | Artifacts accumulate indefinitely | Set expiry to reasonable window |
| Using `only`/`except` (legacy) | Deprecated in favor of `rules:` | Use `rules:` for new pipelines |

## Integration

**Called by:**
- `srepowers:puppet-release` — for control repo MR pipelines
- `srepowers:gitlab-ecr-pipeline` — ECR-specific pipeline patterns

**Pairs with:**
- `srepowers:safety-validator` — before merging pipeline changes to protected branches
- `srepowers:test-driven-operation` — for verifying pipeline changes

## SRE Principles

### Safety First
- Test pipeline changes in a feature branch before merging to default
- Use protected environments for production deployments
- Require manual approval for prod deploy jobs (`when: manual`)

### Structured Output
- Present pipeline status as a table: stage → job → status → duration
- Surface failed job logs with the relevant error section highlighted

### Evidence-Driven
- Capture pipeline URLs and job IDs as evidence
- Show before/after pipeline configuration when debugging

### Audit-Ready
- Pipeline runs are automatically recorded in GitLab
- Document intentional `allow_failure` or `when: manual` decisions in comments

### Communication
- Report pipeline health: "3/4 stages passed, deploy_sit failed with timeout"
- Surface the actionable fix: "increase timeout to 30m or optimize the build step"
