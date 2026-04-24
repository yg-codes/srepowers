---
name: puppet-merge-request
description: Use when creating Puppet control repo merge requests for the sit → uat → prod pipeline on gitlab.fsx.zone - includes branch rename validation, conflict pre-check, and glab MR creation
---

# Puppet Merge Request

Create merge requests for Puppet control repo branches (`control/infra`, `control/jax`) targeting the `sit → uat → prod` pipeline on `gitlab.fsx.zone`.

**Core principle:** Validate branch name → Pre-check conflicts → Create MRs → Report results.

**Announce at start:** "I'm using the puppet-merge-request skill to create merge requests for this Puppet control repo branch."

## Prerequisites

- Working inside a Puppet control repo (`control/infra` or `control/jax`)
- On a topic branch with commits ready to merge
- `glab` CLI authenticated to `gitlab.fsx.zone`
- Clean working tree (no uncommitted changes)

Verify before starting:
```bash
git status --porcelain          # Must be empty
glab auth status                # Must show authenticated
git branch --show-current       # Must be a cu_* topic branch
```

## Step 1: Validate Branch Name

Topic branches **must** use `cu_` prefix with word characters only (no hyphens, slashes, dots, commas). This is enforced by server-side hooks because branch names become Puppet environment names via g10k.

```bash
current_branch=$(git branch --show-current)

# Valid: cu_infra_10768_subid_sss, cu_infra_10615_logrotate
# Invalid: cu_infra-10768-subid, cu_infra/10615, cu_infra.10615
```

**If the branch name contains non-word characters** (common mistake: missing underscores), rename it:

```bash
# Rename local branch
git branch -m "$current_branch" "cu_infra_<ticketid>_<description>"

# Push the renamed branch
git push origin "cu_infra_<ticketid>_<description>"

# Delete the old branch from origin
git push origin --delete "$current_branch"

# Fix upstream tracking
git branch --set-upstream-to="origin/cu_infra_<ticketid>_<description>" "cu_infra_<ticketid>_<description>"
```

**Verify the rename:**
```bash
git log --oneline origin/prod..HEAD   # Should show only your commits
```

## Step 2: Review Commits

Confirm the branch contains the expected commits and nothing extra:

```bash
# Show commits ahead of prod
git log --oneline origin/prod..HEAD
```

Each commit **must** start with a ticket ID (`INFRA-1234: Description`). If any commit is missing the ticket ID, amend before proceeding.

## Step 3: Pre-Check Merge Conflicts

Test merge compatibility against all three target branches **before** creating any MR. This avoids discovering conflicts after the first MR is already open.

```bash
# Fetch latest target branches
git fetch origin sit uat prod
```

For each target branch, perform a dry-run merge:

```bash
for target in sit uat prod; do
  echo "=== Checking merge into $target ==="
  git checkout -b "tmp_check_${target}" "origin/${target}" 2>/dev/null
  if git merge --no-commit --no-ff "$(git branch --show-current --list 'cu_*' | head -1 || echo HEAD)" >/dev/null 2>&1; then
    echo "  ✅ No conflicts"
    git merge --abort
  else
    echo "  ❌ CONFLICTS detected"
    git diff --name-only --diff-filter=U
    git merge --abort
  fi
  git checkout -  >/dev/null
  git branch -D "tmp_check_${target}" >/dev/null 2>&1
done
```

**Alternative (simpler to run step by step):**

```bash
# Check sit
git checkout -b tmp_check_sit origin/sit
git merge --no-commit --no-ff <topic-branch> 2>&1
# If clean: git merge --abort && git checkout <topic-branch> && git branch -D tmp_check_sit
# If conflicts: note the files, then abort

# Repeat for uat and prod
```

**If conflicts are found:**
1. Report which files conflict against which target
2. The user must resolve conflicts before MRs can be created
3. Do NOT proceed to Step 4 until all three targets are clean

**Important:** Conflicts from commits in `sit` that are not yet in `uat` are expected — they are **not** caused by your branch. Only report conflicts that involve files your branch actually changed.

To check which files your branch changed:
```bash
git diff --name-only origin/prod..HEAD
```

## Step 4: Create Merge Requests

Use `glab mr create` to create MRs targeting `sit`, `uat`, and `prod` in sequence.

```bash
for target in sit uat prod; do
  glab mr create -y \
    --fill \
    --target-branch "$target" \
    --assignee "yan.gao" \
    --reviewer "yan.gao" \
    --label "$target"
done
```

**Flags explained:**
- `-y` — Accept defaults, don't open in browser
- `--fill` — Auto-fill title and description from commit messages
- `--target-branch` — The environment branch (sit, uat, or prod)
- `--assignee` — Default assignee
- `--reviewer` — Default reviewer (change as needed per team)
- `--label` — Labels the MR with the target environment name

**Reviewer alternatives** (uncomment based on team):
```bash
# --reviewer "guillaume.ludinard"
# --reviewer "kelvin.maung"
# --reviewer "weihua.du"
```

## Step 5: Report Results

Present a summary table with all created MRs:

```
| Target | MR | URL |
|--------|-----|-----|
| sit    | !NNN | https://gitlab.fsx.zone/puppet/control/infra/-/merge_requests/NNN |
| uat    | !NNN | https://gitlab.fsx.zone/puppet/control/infra/-/merge_requests/NNN |
| prod   | !NNN | https://gitlab.fsx.zone/puppet/control/infra/-/merge_requests/NNN |
```

Remind the user of the merge order:

> **Merge order: sit → uat → prod (no skipping).** Merge sit first, wait for validation, then merge uat, then prod.

## Environment Derivation Reference

The Puppet environment is derived from the branch name via g10k as `{source}_{branch}`:

| Control Repo | Source Prefix | Example Branch | Environment |
|---|---|---|---|
| `control/infra` | `infra_` | `cu_infra_10768_subid_sss` | `infra_cu_infra_10768_subid_sss` |
| `control/jax` | `jax_` | `cu_exch_685_splunk` | `jax_cu_exch_685_splunk` |
| `control/proxmox` | `proxmox_` | N/A | No env branches, uses facts |

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `Branches with non-'word' characters cannot be deployed` | Hyphens/slashes/dots in branch name | Rename branch with underscores only |
| `a1b2c3 has a bad author email` | Git configured with personal email | `git config user.email "firstname.lastname@finstadiumx.co.jp"` |
| `Commit a1b2c3 is not in the official uat branch` | Trying to merge to prod before uat | Merge to uat first |
| `You are pushing N commits` | Too many commits in one MR | Split into smaller MRs |
| Conflict on `Puppetfile` | Module version bumps clash | Rebase onto target, resolve version conflicts |
| Conflict on `data/profile/*.yaml` | Hiera data changes from other branches | Rebase onto target, keep both changes |

## Red Flags

**Never:**
- Create MRs before pre-checking conflicts
- Skip the sit → uat → prod merge order
- Push directly to protected branches (sit, uat, prod)
- Create MRs with missing ticket IDs in commit messages
- Merge more than one topic branch in a single MR

**Always:**
- Validate branch name follows `cu_*` word-character convention
- Pre-check merge against all three target branches
- Report which files (if any) conflict
- Remind user of the required merge sequence
- Verify clean working tree before starting

## Integration

**Pairs with:**
- **puppet-deploy** (CLAUDE.md) — Deployment happens after MRs are merged
- **gitlab-cli** — Underlying `glab` command reference
- **puppet-code-analyzer** — Run validation before creating MRs
- **finishing-operation-branch** — Alternative workflow for non-Puppet repos
