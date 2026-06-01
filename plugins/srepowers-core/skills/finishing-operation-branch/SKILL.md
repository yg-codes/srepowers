---
name: finishing-operation-branch
description: Use when infrastructure work is done and verified — decides whether to merge, create a PR, or clean up the branch. Also use for "merge this branch", "create a PR", "finish up", "wrap up this operation", "ready to merge", or when all verification has passed and the work needs integration.
---

# Finishing an Operation Branch

## Overview

Guide completion of infrastructure operations by presenting clear options for integrating changes into control repos, with environment-aware workflows and safety checks.

**Core principle:** Verify infrastructure state → Present options → Execute choice → Document rollback → Clean up.

**Announce at start:** "I'm using the finishing-operation-branch skill to complete this infrastructure operation."

## The Process

### Step 1: Verify Infrastructure State

**Before presenting options, verify all operations completed:**

```bash
# Run verification commands from the operation plan
kubectl get deployment -n <namespace> <name> -o jsonpath='{.status.readyReplicas}'
terraform plan -detailed-exitcode  # Should return 0
argocd app get <app-name> | grep "Sync Status"
```

**If verification fails:**
```
Infrastructure verification failed (<N> failures). Must fix before completing.

[Show verification failures]

Cannot proceed with merge/PR until infrastructure is in expected state.
```

Stop. Don't proceed to Step 2.

**If verification passes:** Continue to Step 2.

### Step 2: Detect Workspace State and Target Environment

First, detect the workspace shape — this governs which menu to show and how cleanup works:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
current_branch=$(git branch --show-current)   # empty = detached HEAD
```

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Full 5 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Full 5 options | Provenance-based (Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Drop merge/promote (Options 1 & 3) — offer MR-from-new-branch, keep, discard | No cleanup (externally managed) |

Then determine the target environment from the branch name / directory structure:

```bash
# sit → uat → prod promotion path
```

| Branch Pattern | Target Env | Next Env |
|----------------|------------|----------|
| `*sit*`, `*staging*` | sit | uat |
| `*uat*`, `*preprod*` | uat | prod |
| `*prod*`, `*production*` | prod | none |

### Step 3: Present Options

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

### Step 4: Execute Choice

#### Option 1: Merge and Deploy

```bash
git checkout <target-env>
git pull origin <target-env>
git merge <operation-branch>
git push origin <target-env>

# Wait for deployment and verify
kubectl get deployment -n <namespace> -l <label>
```

**For production merges - require explicit confirmation:**
```
⚠️  PRODUCTION DEPLOYMENT WARNING

Confirm:
- [ ] Change has been tested in uat
- [ ] Rollback procedure is documented
- [ ] This is an emergency or trivial change

Type 'deploy-to-production' to confirm.
```

Then: Document rollback (Step 5), Cleanup worktree (Step 6)

#### Option 2: Create Merge Request

```bash
git push -u origin <operation-branch>

glab mr create --title "[<TARGET-ENV>] <title>" --description "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Environment
<sit/uat/prod>

## Verification Steps
- [ ] <kubectl command to verify>

## Rollback Procedure
```bash
<rollback commands>
```

## Risk Assessment
- **Impact**: <low/medium/high>
- **Blast radius**: <services affected>
EOF
)"
```

Then: Document rollback (Step 5). **Keep the worktree** — you need it alive to iterate on MR feedback (Step 6 does not clean up for Option 2).

#### Option 3: Promote to Next Environment

**Only available if verified in current environment:**

```bash
git checkout -b promote-to-<next-env>

# Copy and adapt manifests for next environment
mkdir -p manifests/<next-env>/
cp manifests/<current-env>/<changed-files> manifests/<next-env>/

# Update environment-specific values
yq eval '.spec.replicas = 3' -i manifests/<next-env>/deployment.yaml

git add manifests/<next-env>/
git commit -m "Promote <change> from <current-env> to <next-env>"
git push -u origin promote-to-<next-env>
glab mr create --title "[PROMOTION] <current-env> → <next-env>: <change>"
```

Then: Document rollback (Step 5). **Keep the worktree** — you need it alive for the next promotion step (Step 6 does not clean up for Option 3).

#### Option 4: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 5: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

⚠️  WARNING: If changes were already deployed, this does NOT rollback infrastructure.
Manual rollback may be required:
<rollback commands>

Type 'discard' to confirm.
```

If confirmed:
```bash
git checkout <base-branch>
git branch -D <operation-branch>
```

Then: Cleanup worktree (Step 6)

### Step 5: Document Rollback (for Options 1, 2, 3)

```bash
cat > rollback-<operation-branch>.md <<EOF
# Rollback for <operation-branch>
# Created: $(date -Iseconds)

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

### Step 6: Cleanup Workspace

**Only runs for Option 1 (merge & deploy) and Option 5 (discard).** Options 2 (MR) and 3 (promote) keep the worktree alive so you can iterate on review feedback or run the next promotion; Option 4 keeps it by definition.

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**If the worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/srepowers/worktrees/`:** SREPowers created this worktree — we own cleanup. Remove from the main repo root, never from inside the worktree:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune  # Self-healing: clear any stale registrations
```

**Otherwise:** The harness owns this workspace (provenance check failed). Do NOT remove it. If your platform provides a workspace-exit tool (e.g., `ExitWorktree`), use it. Otherwise leave the workspace in place.

**Detached HEAD:** No branch was created here and the workspace is externally managed — skip removal entirely.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch | Document Rollback |
|--------|-------|------|---------------|----------------|-------------------|
| 1. Merge & deploy | ✓ | ✓ | - | ✓ | ✓ |
| 2. Create MR | - | ✓ | ✓ | - | ✓ |
| 3. Promote | ✓ | ✓ | ✓ | - | ✓ |
| 4. Keep as-is | - | - | ✓ | - | - |
| 5. Discard | - | - | - | ✓ (force) | - |

## Environment Promotion

| From | To | Verification Required | Approval |
|------|-----|----------------------|----------|
| sit | uat | ✅ Verified in sit | Standard MR |
| uat | prod | ✅ Verified in uat | Peer review + explicit confirm |
| feature | sit | None | Standard MR |

**Never allow sit → prod promotion.** Must go through uat.

## Key Principles

| Principle | What It Means |
|-----------|---------------|
| **Safety First** | Explicit confirmation for production. Verify state before options. Document rollback before cleanup. |
| **Evidence-Driven** | Include verification commands in MR. Reference actual kubectl outputs. Show git commit SHAs. |
| **Audit-Ready** | Document rollback with exact commands. Record promotion path. Preserve verification evidence. |

## Red Flags

**Never:**
- Proceed with failing verification
- Merge to production without explicit confirmation
- Delete work without confirmation
- Skip rollback documentation for deployed changes
- Allow sit → prod promotion
- Clean up a worktree you didn't create (provenance check must pass)
- Run `git worktree remove` from inside the worktree being removed
- Remove a worktree before confirming the merge succeeded

**Always:**
- Detect workspace state before presenting the menu
- Verify infrastructure state before offering options
- Require typed confirmation for production operations
- Document rollback procedure
- Get explicit confirmation for Option 5 (discard)
- `cd` to the main repo root before worktree removal, then `git worktree prune`
- Prefer the harness's native workspace-exit tool when the worktree is harness-owned

## Integration

**Called by:**
- **subagent-driven-operation** - After all tasks complete
- **executing-operation-plans** - After all batches complete

**Pairs with:**
- **using-git-worktrees-sre** - Cleans up worktree created by that skill
- **writing-operation-plans** - References verification commands from plan
- **test-driven-operation** - Uses verification commands for final check
