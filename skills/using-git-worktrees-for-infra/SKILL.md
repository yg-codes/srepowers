---
name: using-git-worktrees-for-infra
description: Use when starting infrastructure operations that need isolation from current workspace - creates isolated git worktrees for control repos with environment-aware directory selection and safety verification
---

# Using Git Worktrees for Infrastructure

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple infrastructure branches simultaneously without switching. Essential for safe control repo operations.

**Core principle:** Systematic directory selection + environment verification + safety checks = reliable infrastructure isolation.

**Announce at start:** "I'm using the using-git-worktrees-for-infra skill to set up an isolated workspace for infrastructure operations."

## When to Use

**Always for control repo operations:**
- Creating new Kubernetes manifests
- Modifying Terraform configurations
- Updating ArgoCD/Flux deployments
- Changing Keycloak realm configurations
- Any infrastructure-as-code changes

**Required before:**
- `subagent-driven-operation`
- `writing-operation-plans` execution
- Any multi-step infrastructure change

## Directory Selection Process

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**If preference specified:** Use it without asking.

### 3. Ask User

If no directory exists and no CLAUDE.md preference:

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/.config/srepowers/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

Per safety-first principle:
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents to control repo, which could trigger unintended deployments.

### For Global Directory (~/.config/srepowers/worktrees)

No .gitignore verification needed - outside project entirely.

## Environment Detection

Before creating worktree, determine the target environment:

```bash
# Check current branch for environment indicators
current_branch=$(git branch --show-current)

# Common patterns
if [[ "$current_branch" == "sit" ]] || [[ "$current_branch" == *"sit"* ]]; then
    environment="sit"
elif [[ "$current_branch" == "uat" ]] || [[ "$current_branch" == *"uat"* ]]; then
    environment="uat"
elif [[ "$current_branch" == "prod" ]] || [[ "$current_branch" == *"prod"* ]]; then
    environment="prod"
else
    environment="unknown"
fi
```

**If environment is prod:**
- Warn user about direct production work
- Recommend using sit/uat promotion workflow
- Require explicit confirmation to proceed

## Creation Steps

### 1. Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

```bash
# Determine full path
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/srepowers/worktrees/*)
    path="~/.config/srepowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. Verify Control Repo Structure

Check for expected infrastructure directories:

```bash
# Kubernetes control repo
if [ -d manifests/ ] || [ -d k8s/ ] || [ -d clusters/ ]; then
    echo "Kubernetes control repo detected"
    # Verify structure
    ls -la manifests/ 2>/dev/null || ls -la k8s/ 2>/dev/null
fi

# Terraform repo
if [ -d terraform/ ] || [ -f main.tf ]; then
    echo "Terraform repo detected"
    # Verify state backend configuration
    grep -l "backend" *.tf 2>/dev/null | head -5
fi

# Ansible repo
if [ -d playbooks/ ] || [ -d roles/ ]; then
    echo "Ansible repo detected"
fi
```

### 4. Environment Isolation Check

**Critical for infrastructure repos:**

```bash
# Check if this repo has environment-specific directories
for env in sit uat prod; do
    if [ -d "$env" ] || [ -d "manifests/$env" ] || [ -d "overlays/$env" ]; then
        echo "Environment-specific structure detected: $env"
    fi
done

# Warn if branch name doesn't match environment structure
if [[ "$BRANCH_NAME" == *"prod"* ]] && [[ "$current_branch" != "prod" ]]; then
    echo "WARNING: Creating production branch from non-production base"
fi
```

### 5. Verify Clean Baseline

For infrastructure repos, verify baseline state:

```bash
# Check for uncommitted changes in main worktree
cd "$(git rev-parse --git-common-dir)/.."
if [ -n "$(git status --porcelain)" ]; then
    echo "WARNING: Main worktree has uncommitted changes"
fi

# Return to new worktree
cd "$path"

# Validate YAML/JSON files if present
find . -name "*.yaml" -o -name "*.yml" 2>/dev/null | head -5 | while read f; do
    if command -v yq >/dev/null 2>&1; then
        yq eval '.' "$f" > /dev/null 2>&1 && echo "Valid YAML: $f" || echo "INVALID YAML: $f"
    fi
done
```

### 6. Report Location

```
Infrastructure worktree ready at <full-path>
Environment: <detected-environment>
Control repo type: <k8s/terraform/ansible>
Clean baseline: verified
Ready to implement <operation-name>

Next steps:
1. Use /writing-operation-plans to create detailed steps
2. Use /test-driven-operation for each change
3. Use /finishing-operation-branch when complete
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Target is production | Warn + require explicit confirmation |
| Uncommitted changes in main | Warn about state consistency |

## SRE Principles

### Safety First
- Verify worktree directory is ignored before creation (prevents accidental commits)
- Detect target environment and warn for production operations
- Check for uncommitted changes in main worktree that could affect isolation

### Structured Output
- Present directory selection decision with rationale
- Show environment detection results in tabular format
- Report control repo type and baseline status clearly

### Evidence-Driven
- Use `git check-ignore` to verify directory is properly ignored
- Reference specific branch names and environment indicators
- Show actual directory contents when detecting repo type

### Audit-Ready
- Record worktree location and base branch for each operation
- Note environment target in operation documentation
- Track branch creation timestamp and operator identity

### Communication
- Lead with safety considerations (environment detection, production warnings)
- Provide clear next steps after worktree creation
- Explain why isolation matters for infrastructure operations

## Common Mistakes

### Skipping ignore verification
- **Problem:** Worktree contents get tracked, could trigger unintended deployments
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Ignoring environment context
- **Problem:** Operating on production without awareness, causing incidents
- **Fix:** Always detect environment from branch name and structure, warn appropriately

### Assuming repo type
- **Problem:** Using wrong verification commands for repo type
- **Fix:** Auto-detect from directory structure (manifests/, terraform/, etc.)

### Not checking baseline state
- **Problem:** Starting from dirty state, conflating existing issues with new changes
- **Fix:** Verify main worktree is clean, validate YAML/JSON in new worktree

## Example Workflow

```
You: I'm using the using-git-worktrees-for-infra skill to set up an isolated workspace.

[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[Detect environment - current branch is 'sit', target branch contains 'uat']
[Create worktree: git worktree add .worktrees/cu_add_keycloak_client -b cu_add_keycloak_client]
[Detect repo type - Kubernetes control repo (manifests/ directory present)]
[Check baseline - main worktree clean, YAML files valid]

Infrastructure worktree ready at /home/yg/src/github/control-repo/.worktrees/cu_add_keycloak_client
Environment: uat (detected from branch name)
Control repo type: Kubernetes (manifests/ directory)
Clean baseline: verified
Ready to implement Keycloak client provisioning

Next steps:
1. Use /writing-operation-plans to create detailed steps
2. Use /test-driven-operation for each change
3. Use /finishing-operation-branch when complete
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Proceed with production operations without explicit confirmation
- Skip environment detection
- Ignore uncommitted changes in main worktree
- Assume control repo type without verification

**Always:**
- Follow directory priority: existing > CLAUDE.md > ask
- Verify directory is ignored for project-local
- Detect and report target environment
- Verify clean baseline
- Confirm repo type before proceeding

## Integration

**Called by:**
- **brainstorming-operations** (Phase 4) - REQUIRED when design is approved
- **subagent-driven-operation** - REQUIRED before executing any tasks
- **writing-operation-plans** - REQUIRED before plan execution
- Any infrastructure skill needing isolated workspace

**Pairs with:**
- **writing-operation-plans** - Create detailed steps after workspace ready
- **test-driven-operation** - Execute each step with verification
- **finishing-operation-branch** - REQUIRED for cleanup and merge decision

## Differences from Software Development Worktrees

| Aspect | Software (Superpowers) | Infrastructure (SREPowers) |
|--------|------------------------|---------------------------|
| **Primary concern** | Test isolation | Environment isolation |
| **Baseline check** | Run test suite | Verify YAML/JSON validity |
| **Key detection** | package.json, Cargo.toml | manifests/, terraform/, etc. |
| **Environment awareness** | Not critical | Critical (sit/uat/prod) |
| **Safety mechanism** | Test failures block | Production warnings |
| **Completion workflow** | finishing-a-development-branch | finishing-operation-branch |
