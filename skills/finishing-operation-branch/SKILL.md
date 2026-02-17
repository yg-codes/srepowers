---
name: finishing-operation-branch
description: Use when infrastructure operations are complete, all verifications pass, and you need to decide how to integrate the work - guides completion with merge/PR options, environment promotion, and cleanup
---

# Finishing an Operation Branch

## Overview

Guide completion of infrastructure operations by presenting clear options for integrating changes into control repos, with environment-aware workflows and safety checks.

**Core principle:** Verify infrastructure state → Present options → Execute choice → Document rollback → Clean up.

**Announce at start:** "I'm using the finishing-operation-branch skill to complete this infrastructure operation."

## The Process

### Step 1: Verify Infrastructure State

**Before presenting options, verify all operations completed successfully:**

```bash
# Run verification commands from the operation plan
# Examples by operation type:

# Kubernetes deployments
kubectl get deployment -n <namespace> <name> -o jsonpath='{.status.readyReplicas}'

# ConfigMaps/Secrets
kubectl get configmap -n <namespace> <name> -o jsonpath='{.data.<key>}'

# Terraform state
terraform plan -detailed-exitcode  # Should return 0 (no changes)

# ArgoCD sync
argocd app get <app-name> | grep "Sync Status"
```

**If verification fails:**
```
Infrastructure verification failed (<N> failures). Must fix before completing:

[Show verification failures]

Cannot proceed with merge/PR until infrastructure is in expected state.
```

Stop. Don't proceed to Step 2.

**If verification passes:** Continue to Step 2.

### Step 2: Determine Target Environment

```bash
# Detect environment from branch name or directory structure
current_branch=$(git branch --show-current)

if [[ "$current_branch" == *"sit"* ]] || [[ "$current_branch" == *"staging"* ]]; then
    target_env="sit"
    next_env="uat"
elif [[ "$current_branch" == *"uat"* ]] || [[ "$current_branch" == *"preprod"* ]]; then
    target_env="uat"
    next_env="prod"
elif [[ "$current_branch" == *"prod"* ]] || [[ "$current_branch" == *"production"* ]]; then
    target_env="prod"
    next_env="none"
else
    target_env="unknown"
    next_env="unknown"
fi
```

Check environment structure:
```bash
# Check for environment directories
for env in sit uat prod; do
    if [ -d "$env" ] || [ -d "manifests/$env" ] || [ -d "overlays/$env" ]; then
        echo "Environment structure detected: $env"
    fi
done
```

### Step 3: Present Options

Present exactly these 5 options (adapted for infrastructure):

```
Infrastructure operation complete. What would you like to do?

1. Merge to control repo and deploy to <target-env>
2. Create Merge Request for peer review (recommended for production)
3. Promote to <next-env> (if verified in current environment)
4. Keep the branch as-is (I'll handle it later)
5. Discard this work

Current environment: <target-env>
Verification status: ✅ All checks passed

Which option?
```

**Option variations by environment:**

| Environment | Option 3 Text | Notes |
|-------------|---------------|-------|
| sit | "Promote to uat" | Standard promotion |
| uat | "Promote to prod" | Requires explicit confirmation |
| prod | "N/A" | Not shown for production |

**Don't add explanation** - keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge and Deploy

```bash
# Switch to target branch (e.g., sit)
git checkout <target-env>

# Pull latest
git pull origin <target-env>

# Merge operation branch
git merge <operation-branch>

# Push to trigger deployment
git push origin <target-env>

# Wait for deployment and verify
kubectl get deployment -n <namespace> -l <label>
```

**For production merges - require explicit confirmation:**
```
⚠️  PRODUCTION DEPLOYMENT WARNING

You are about to merge directly to production. This bypasses peer review.

Confirm:
- [ ] Change has been tested in uat
- [ ] Rollback procedure is documented
- [ ] This is an emergency or trivial change

Type 'deploy-to-production' to confirm direct merge.
```

Then: Cleanup worktree (Step 6)

#### Option 2: Create Merge Request

```bash
# Push branch
git push -u origin <operation-branch>

# Create MR using glab or gh
glab mr create --title "[<TARGET-ENV>] <title>" --description "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Environment
<sit/uat/prod>

## Verification Steps
- [ ] <kubectl command to verify>
- [ ] <API call to verify>

## Rollback Procedure
```bash
<rollback commands>
```

## Risk Assessment
- **Impact**: <low/medium/high>
- **Blast radius**: <specific services affected>
- **Rollback time**: <minutes>
EOF
)"
```

Then: Cleanup worktree (Step 6)

#### Option 3: Promote to Next Environment

**Only available if verified in current environment:**

```bash
# Create promotion branch
git checkout -b promote-to-<next-env>

# Cherry-pick or merge changes for next environment
# (Adapt manifests for next environment if needed)

# Example: Copy sit manifests to uat
mkdir -p manifests/uat/
cp manifests/sit/<changed-files> manifests/uat/

# Update environment-specific values (using sed or yq)
yq eval '.spec.replicas = 3' -i manifests/uat/deployment.yaml

# Commit promotion
git add manifests/uat/
git commit -m "Promote <change> from sit to uat"

# Push and create MR for promotion
git push -u origin promote-to-<next-env>
glab mr create --title "[PROMOTION] sit → uat: <change>" --description "..."
```

Then: Cleanup worktree (Step 6)

#### Option 4: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>.

To resume later:
```
cd <path>
# Make additional changes
# Then run /finishing-operation-branch again
```
"

**Don't cleanup worktree.**

#### Option 5: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

⚠️  WARNING: If changes were already deployed, this does NOT rollback the infrastructure.
Manual rollback may be required:
<rollback commands>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
# Note: This only deletes git branch, not deployed resources
git checkout <base-branch>
git branch -D <operation-branch>
```

Then: Cleanup worktree (Step 6)

### Step 5: Document Rollback (for Options 1, 2, 3)

Before cleanup, ensure rollback is documented:

```bash
# Extract rollback commands from operation history
cat > rollback-<operation-branch>.md <<EOF
# Rollback for <operation-branch>
# Created: $(date -Iseconds)

## Pre-rollback Verification
kubectl get <resources> -n <namespace>

## Rollback Steps
kubectl delete -f <manifests>
# OR
kubectl rollout undo deployment/<name> -n <namespace>
# OR
git revert <commit-sha> && git push

## Post-rollback Verification
kubectl get <resources> -n <namespace>
EOF
```

### Step 6: Cleanup Worktree

**For Options 1, 2, 3, 5:**

Check if in worktree:
```bash
git worktree list | grep $(git branch --show-current)
```

If yes:
```bash
git worktree remove <worktree-path>
```

**For Option 4:** Keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Document Rollback |
|--------|-------|------|---------------|----------------|-------------------|
| 1. Merge & deploy | ✓ | ✓ | - | ✓ | ✓ |
| 2. Create MR | - | ✓ | ✓ | - | ✓ |
| 3. Promote | ✓ | ✓ | ✓ | - | ✓ |
| 4. Keep as-is | - | - | ✓ | - | - |
| 5. Discard | - | - | - | ✓ (force) | - |

## Environment Promotion Matrix

| Current | Next | Verification Required | Approval Required |
|---------|------|----------------------|-------------------|
| sit | uat | ✅ Verified in sit | Standard MR |
| uat | prod | ✅ Verified in uat | Peer review + explicit confirm |
| feature | sit | None | Standard MR |

## SRE Principles

### Safety First
- Require explicit confirmation for production deployments
- Verify infrastructure state before offering completion options
- Document rollback procedure before cleanup
- Warn about irreversible operations

### Structured Output
- Present options in numbered list with clear consequences
- Show environment context and verification status
- Provide rollback documentation in structured format

### Evidence-Driven
- Include verification commands in MR description
- Reference actual kubectl outputs, not just claims
- Show git commit SHAs for audit trail

### Audit-Ready
- Document rollback procedure with exact commands
- Record environment promotion path
- Preserve verification evidence in MR/commit messages
- Include operator identity and timestamp

### Communication
- Lead with environment and verification status
- Clearly state risk level for production operations
- Provide rollback instructions in business terms
- Explain promotion path for multi-environment workflows

## Common Mistakes

### Skipping verification
- **Problem:** Merge broken infrastructure, cause incident
- **Fix:** Always run verification commands before offering options

### Production direct merge without confirmation
- **Problem:** Bypass peer review, introduce untested changes to production
- **Fix:** Require typed confirmation for Option 1 on production

### Missing rollback documentation
- **Problem:** Can't revert quickly during incident
- **Fix:** Always document rollback procedure before cleanup

### Assuming promotion path
- **Problem:** Skip environments (sit → prod), missing validation
- **Fix:** Enforce sit → uat → prod sequence, show promotion option only for next environment

### Not adapting manifests for environment
- **Problem:** Copy sit manifests to uat with sit-specific values (replicas, URLs)
- **Fix:** Update environment-specific values during promotion

## Red Flags

**Never:**
- Proceed with failing verification
- Merge to production without explicit confirmation
- Delete work without confirmation
- Skip rollback documentation for deployed changes
- Allow sit → prod promotion (must go through uat)

**Always:**
- Verify infrastructure state before offering options
- Require typed confirmation for production operations
- Document rollback procedure
- Get explicit confirmation for Option 5 (discard)
- Clean up worktree for Options 1, 2, 3, 5 only

## Integration

**Called by:**
- **subagent-driven-operation** (final step) - After all tasks complete
- **writing-operation-plans** (execution complete) - After plan execution
- Any infrastructure skill needing completion workflow

**Pairs with:**
- **using-git-worktrees-for-infra** - Cleans up worktree created by that skill
- **writing-operation-plans** - References verification commands from plan
- **test-driven-operation** - Uses verification commands for final check

## Differences from Software Development Completion

| Aspect | Software (Superpowers) | Infrastructure (SREPowers) |
|--------|------------------------|---------------------------|
| **Verification** | Unit tests | Infrastructure state (kubectl, API) |
| **Options** | 4 options | 5 options (+promotion) |
| **Environment awareness** | Not critical | Critical (sit/uat/prod) |
| **Safety mechanism** | Test failures block | Verification + confirmation |
| **Documentation** | Test results | Rollback procedures |
| **Promotion** | N/A | sit → uat → prod workflow |
