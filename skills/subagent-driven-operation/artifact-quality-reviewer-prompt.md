# Artifact Quality Reviewer Prompt Template

Use this template when dispatching an artifact quality reviewer subagent for infrastructure operations.

**Purpose:** Verify infrastructure artifacts are well-built (valid, clean, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (superpowers:code-reviewer):
  Use template at requesting-code-review/code-reviewer.md

  Adapt for infrastructure artifacts:

  WHAT_WAS_EXECUTED: [from operator's report]
  PLAN_OR_REQUIREMENTS: Operation Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [operation summary]

  Focus areas for infrastructure artifacts:
  - YAML/JSON validity and syntax
  - Kubernetes best practices (labels, annotations, resource limits)
  - Security (no secrets in plain text, proper RBAC)
  - Git commit message quality
  - Documentation in manifests
```

**Artifact reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

**Infrastructure-specific focus:**

| Area | What to Check |
|------|---------------|
| **Kubernetes YAML** | Valid syntax, proper API version, correct structure |
| **Labels** | app, version, component labels present |
| **Annotations** | Documentation, change tracking |
| **Security** | No plaintext secrets, proper RBAC, resource limits |
| **Git commits** | Clear messages, proper formatting, atomic changes |
| **Verification commands** | Idempotent, check actual state, not side effects |

**Example issues:**

- **Critical**: Invalid YAML, broken syntax, security exposure
- **Important**: Missing labels, no resource limits, unclear commit message
- **Minor**: Formatting, whitespace, documentation improvements
