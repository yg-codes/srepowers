---
name: puppet-merge-request
description: Use when creating Puppet control repo merge requests for the sit → uat → prod pipeline on gitlab.example.com - includes branch rename validation, conflict pre-check, and glab MR creation
---

# Puppet Merge Request

Create merge requests for Puppet control repo branches targeting the `sit → uat → prod` pipeline on your self-hosted GitLab.

**Core principle:** Validate branch name → Pre-check conflicts → Create MRs → Report results.

## Parameters (never hardcode environment-specific values)

This skill is generic. Resolve these at runtime — do not bake hostnames, repo
names, usernames, or emails into commands:

| Parameter | How to resolve |
|---|---|
| `GITLAB_HOST` | Your GitLab host, from `glab auth status` or `git remote get-url origin` |
| `CONTROL_REPO` | The control repo you are in, from the remote URL |
| `GIT_USER` | The MR author's username (`glab api /user`) |
| `REVIEWERS` | Team reviewer usernames, from your local GitLab rules file |
| `COMPANY_EMAIL` | Git author email required by the server hook, from `git config user.email` |

**Announce at start:** "I'm using the puppet-merge-request skill to create merge requests for this Puppet control repo branch."

## Prerequisites

- Working inside a Puppet control repo that has env branches — see Environment Derivation Reference; a facts-driven control repo (no env branches) is out of scope
- On a topic branch with commits ready to merge
- `glab` CLI authenticated to `gitlab.example.com`
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

# Valid: cu_1234_example, cu_1234_logrotate
# Invalid: cu_1234-example, cu_1234/example, cu_1234.example
```

**If the branch name contains non-word characters** (common mistake: missing underscores), rename it:

```bash
# Rename local branch
git branch -m "$current_branch" "cu_<ticketid>_<description>"

# Push the renamed branch
git push origin "cu_<ticketid>_<description>"

# Delete the old branch from origin
git push origin --delete "$current_branch"

# Fix upstream tracking
git branch --set-upstream-to="origin/cu_<ticketid>_<description>" "cu_<ticketid>_<description>"
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
GIT_USER=$(glab api /user | jq -r .username)
for target in sit uat prod; do
  glab mr create -y \
    --fill \
    --target-branch "$target" \
    --assignee "$GIT_USER" \
    --reviewer "$GIT_USER" \
    --label "$target"
done
```

**Flags explained:**
- `-y` — Accept defaults, don't open in browser
- `--fill` — Auto-fill title and description from commit messages; use for the
  title, then overwrite the description per Step 5 (concise, structured)
- `--target-branch` — The environment branch (sit, uat, or prod)
- `--assignee` / `--reviewer` — Author self-assigns by default; reassign the
  reviewer manually after self-check, per your local GitLab rules file

## Step 5: Write the MR Description

Do **not** rely on `--fill` alone — commit messages make a thin or rambling
description. Write the body explicitly, following your local GitLab rules file's
MR-description policy (if you have one):

- **≤ ~4,000 characters.** Focused, precise, informative — not a design essay.
- Structure: **what changed** (small table), **why**, **verification**,
  **rollback**, plus any **rider** the diff carries beyond the ticket
  (e.g. work riding in a module tag bump).
- Design rationale and background narrative go in the ticket doc
  (`docs/<TICKET-ID>/`), not the MR.
- **Re-verify factual claims against the current diff** before writing — pins,
  per-branch state, "first time in env". Descriptions drafted at
  branch-creation go stale after rebases.
- Cross-env chains (sit/uat/prod) share **one body** with a short per-target
  footer stating merge order and any target-specific note.
- Full detail lives in the rule file; this step is the reminder to apply it.

## Step 6: Report Results

Present a summary table with all created MRs:

```
| Target | MR | URL |
|--------|-----|-----|
| sit    | !NNN | https://${GITLAB_HOST}/${CONTROL_REPO_PATH}/-/merge_requests/NNN |
| uat    | !NNN | https://${GITLAB_HOST}/${CONTROL_REPO_PATH}/-/merge_requests/NNN |
| prod   | !NNN | https://${GITLAB_HOST}/${CONTROL_REPO_PATH}/-/merge_requests/NNN |
```

Remind the user of the merge order:

> **Merge order: sit → uat → prod (no skipping).** Merge sit first, wait for validation, then merge uat, then prod.

## Environment Derivation Reference

The Puppet environment is derived from the branch name via g10k as `{source}_{branch}`:

| Control Repo | Source Prefix | Example Branch | Environment |
|---|---|---|---|
| `control/<source-a>` | `<source-a>_` | `cu_<ticket>_example` | `<source-a>_cu_<ticket>_example` |
| `control/<source-b>` | `<source-b>_` | `cu_<ticket>_demo` | `<source-b>_cu_<ticket>_demo` |
| facts-driven repo | `<source>_` | N/A | No env branches — uses Hiera facts |

The `<source>` of each control repo (and therefore its environment prefix) is
defined in the g10k config on the Puppet master — read it there, don't guess.

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `Branches with non-'word' characters cannot be deployed` | Hyphens/slashes/dots in branch name | Rename branch with underscores only |
| `a1b2c3 has a bad author email` | Git configured with personal email | `git config user.email "you@company.example"` |
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
- Write a concise structured description (Step 5) — never ship `--fill` output as-is

## Integration

**Pairs with:**
- **puppet-deploy** (CLAUDE.md) — Deployment happens after MRs are merged
- **gitlab-cli** — Underlying `glab` command reference
- **puppet-code-analyzer** — Run validation before creating MRs
- **finishing-operation-branch** — Alternative workflow for non-Puppet repos
