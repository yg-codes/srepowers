# Artifact Quality Reviewer Prompt Template

Use this template when dispatching an artifact quality reviewer subagent for infrastructure operations.

**Purpose:** Verify infrastructure artifacts are well-built (valid, clean, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (general-purpose):
  description: "Review artifact quality for Operation Task N"
  prompt: |
    You are reviewing infrastructure artifact quality.

    ## What Was Executed

    Read the operator's report file `[.srepowers/sdd/task-N-report.md]`.

    ## Plan/Requirements

    Read the brief file `[.srepowers/sdd/task-N-brief.md]` (Operation Task N).

    ## Review Package

    Read `[.srepowers/sdd/review-<base>..<head>.diff]` — it contains the commit
    list, file-change stat, and the full diff with context. Use the recorded
    per-task BASE (never `HEAD~1`, which drops all but the last commit of a
    multi-commit task).

    ## Contract

    Exact scope:
    - Artifact quality for the reviewed task or segment only

    Input artifacts:
    - Operator report file
    - Brief file (relevant requirements)
    - Review package file (commits + stat + diff)

    Allowed tools/commands:
    - Read the review package and changed files
    - Run syntax or validation commands directly related to artifact quality

    Output boundary:
    - Do NOT re-open spec intent unless it creates a concrete quality or safety defect
    - Do NOT conclude the full operation is complete

    ## Your Job

    Review the infrastructure artifacts in the review package (the full diff is
    already in that file — read it rather than re-deriving with git).

    Focus areas:
    - YAML/JSON validity and syntax
    - Kubernetes best practices (labels, annotations, resource limits)
    - Security (no secrets in plain text, proper RBAC)
    - Git commit message quality
    - Documentation in manifests

    ## Report Format

    - Status: APPROVED | NEEDS_CHANGES
    - Scope reviewed: [task or segment]
    - Evidence checked: [diffs, validations, files]
    - Strengths: What was done well
    - Issues:
      Critical: [blocking problems]
      Important: [should fix before merge]
      Minor: [nice to have]
    - Out-of-scope notes: [anything noticed but not judged here]
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
