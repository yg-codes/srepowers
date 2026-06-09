---
name: puppet-release
description: Use when releasing Puppet modules through the cross-repo workflow — tagging modules, bumping Puppetfile references, and promoting through the sit -> uat -> prod merge chain on gitlab.fsx.zone. Also use for "bump module", "release module X", "promote to sit/uat/prod", "update Puppetfile", "tag module", or any Puppet cross-repo release operation.
---

# Puppet Cross-Repo Release

Orchestrate the Puppet module release workflow: module validation → tag creation → Puppetfile bump → control-repo MR chain. This skill handles the mechanical steps that are identical for every ticket, with human judgment gates at each phase transition.

**Core principle:** Validate before tag, tag before bump, bump before merge. Every step produces a verifiable artifact before the next step starts.

**Announce at start:** "I'm using the puppet-release skill to orchestrate the module release."

## Context

Puppet infrastructure uses a cross-repo workflow where a module change must propagate through multiple repositories before reaching production:

```
Module repo (topic branch → main) → Control repo (sit → uat → prod)
```

Each arrow is a manual operation (tag, Puppetfile edit, MR). This skill automates the mechanical parts while preserving human gates for judgment calls.

## Prerequisites

- Working in the Puppet multi-repo workspace (`~/src/fsx/puppet` or equivalent)
- `glab` CLI authenticated to `gitlab.fsx.zone`
- `git` configured with correct author email (company domain)
- Module repo has a clean working tree on the topic branch
- Ticket ID known (e.g., INFRA-1234)

Verify before starting:
```bash
glab auth status                       # Must show authenticated
git config user.email                  # Must be company email
git branch --show-current              # Must be on topic branch or main
```

## Release Phases

The release has three phases, executed in order. Not every ticket needs all three — assess which phase to start from based on the current state.

| Phase | When to Use | What It Does |
|-------|-------------|--------------|
| **1. Tag** | Module code is ready for testing in a topic-branch environment | Creates descriptive tag on module topic branch |
| **2. Release** | SIT validation has passed; module is ready for formal release | Merges topic → main, creates date tag |
| **3. Promote** | Module has a date tag; control repo needs updating | Bumps Puppetfile, creates MRs through env chain |

### Phase Selection Guide

```
Is the module code ready but untested?          → Start at Phase 1 (Tag)
Has SIT validation passed on the topic branch?   → Start at Phase 2 (Release)
Does the module already have a date tag on main? → Start at Phase 3 (Promote)
```

Always ask the user which phase to start from. Do not assume.

---

## Phase 1: Tag — Module Descriptive Tag

Create a descriptive tag on the module's topic branch for testing via g10k.

### Step 1.1: Validate Module Code

```bash
# cd to module repo root
cd ~/src/fsx/puppet/modules/<module_name>

# Verify on topic branch
git branch --show-current
# Must be: cu_<ticket>_<description>

# Run validation suite
pdk validate
bundle exec rake lint
bundle exec rake spec
```

**If any validation fails:** Stop. Fix issues before tagging. A failing module tagged and deployed wastes everyone's time.

### Step 1.2: Verify Working Tree

```bash
git status --porcelain
# Must be empty — all changes committed

git log --oneline -5
# Verify recent commits have ticket ID prefix: "INFRA-XXXX: ..."
```

### Step 1.3: Create Descriptive Tag

```bash
TAG_NAME="tag_cu_<ticket>_<description>"
git tag -a "$TAG_NAME" -m "Pre-release tag for <ticket>: <brief description>"
git push origin "$TAG_NAME"
```

**Tag naming convention:**
- Descriptive tags: `tag_cu_<ticket>_<description>` (for pre-release testing)
- Word characters only — no hyphens, slashes, dots, or commas
- The `tag_` prefix distinguishes these from date tags

### Step 1.4: Verify Tag

```bash
git tag -l "tag_cu_<ticket>*" -n1
# Must show the tag with its annotation message
```

### Step 1.5: Update Puppetfile (Topic Branch Reference)

If this is the first iteration, update the control repo's Puppetfile to point to the descriptive tag:

```bash
# cd to control repo topic branch
cd ~/src/fsx/puppet/control/<infra|jax>
git checkout cu_<ticket>_<description>
git pull

# Edit Puppetfile — change the module's reference
# FROM: :tag => 'YYYY-MM-DD' or :branch => 'cu_<ticket>_<desc>'
# TO:   :tag => 'tag_cu_<ticket>_<description>'
```

Then validate and commit:
```bash
./bin/fsx-puppetfile-format check Puppetfile
# Must pass — git modules before forge modules, correct key ordering

git add Puppetfile
git commit -m "<TICKET-ID>: Bump <module> to tag_cu_<ticket>_<description>"
git push
```

**Gate:** Confirm with user that the Puppetfile change looks correct before pushing.

---

## Phase 2: Release — Module to Main

After SIT validation passes, merge the module topic branch to `main` and create a formal date tag.

### Step 2.1: Verify Module Tests Pass on Latest

```bash
cd ~/src/fsx/puppet/modules/<module_name>
git checkout cu_<ticket>_<description>
git pull
pdk validate && bundle exec rake lint && bundle exec rake spec
# All must pass
```

### Step 2.2: Create Module MR to Main

```bash
# Create MR from topic branch to main
glab mr create \
  --title "<TICKET-ID>: <description>" \
  --description "Module release for <ticket>. Changes: <summary>" \
  --target-branch main \
  --source-branch cu_<ticket>_<description> \
  --assignee <username>
```

**Wait for MR approval and merge.** Do not proceed until the MR is merged.

### Step 2.3: Create Date Tag on Main

After the MR is merged to `main`:

```bash
git checkout main
git pull
git log --oneline -3   # Verify the merge commit is present

# Create date tag — use today's date
TODAY=$(date +%Y-%m-%d)
git tag -a "$TODAY" -m "Release <TODAY>: <module_name> — <TICKET-ID>: <brief description>"
git push origin "$TODAY"
```

**Date tag rules:**
- Format: `YYYY-MM-DD` (e.g., `2026-06-09`)
- Always from `main` branch
- If a date tag already exists for today, append a letter: `2026-06-09b`
- Tags are immutable — never force-move or retag

### Step 2.4: Verify Date Tag

```bash
git tag -l "2026-*" -n1 | tail -5
# Confirm the new date tag appears with correct message
```

---

## Phase 3: Promote — Control Repo Puppetfile Bump + MR Chain

Update the Puppetfile in each control repo environment branch to reference the new date tag, then create MRs through the sit → uat → prod pipeline.

### Step 3.1: Determine Scope

Ask the user:
- Which control repo? (`infra`, `jax`, or both)
- Which module was updated?
- What is the date tag?

### Step 3.2: Bump Puppetfile on Topic Branch

For each control repo that needs updating:

```bash
cd ~/src/fsx/puppet/control/<infra|jax>
git checkout cu_<ticket>_<description>
git pull

# Edit Puppetfile — update the module's reference
# FROM: :tag => 'tag_cu_<ticket>_<description>' or previous date tag
# TO:   :tag => 'YYYY-MM-DD' (the new date tag)
```

Validate:
```bash
./bin/fsx-puppetfile-format check Puppetfile
# Must pass
```

Commit and push:
```bash
git add Puppetfile
git commit -m "<TICKET-ID>: Release <module> to YYYY-MM-DD"
git push
```

### Step 3.3: Trigger g10k Deploy

If auto-deploy is not active, trigger manually:

```bash
ssh fsx-mgmt-puppet01.fsx.zone "sudo -u puppet env https_proxy=http://proxy:3128 \
  /opt/puppetlabs/puppet/bin/g10k -config /etc/puppetlabs/g10k/g10k.yaml"
```

### Step 3.4: Verify Environment Deployment

```bash
ssh fsx-mgmt-puppet01.fsx.zone \
  "cat /etc/puppetlabs/code/environments/<source>_<topic_branch>/.g10k-deploy.json"
# Confirm the new date tag appears in the deploy signature
```

### Step 3.5: Invoke puppet-merge-request

Once the Puppetfile bump is verified, invoke the `srepowers:puppet-merge-request` skill to create the MR chain through sit → uat → prod.

The merge chain follows strict ordering — server-side hooks enforce that commits must be reachable from the previous environment branch before merging to the next:

```
topic branch → sit → uat → prod
```

**Do not skip environments.** The server will reject it.

### Step 3.6: Update Puppetfile Across All Remaining Branches

After each MR merges, update the Puppetfile on the next branch:

```bash
# After sit merge, update on uat branch
git checkout uat && git pull
# Edit Puppetfile to same date tag
./bin/fsx-puppetfile-format check Puppetfile
git add Puppetfile && git commit -m "<TICKET-ID>: Release <module> to YYYY-MM-DD"
git push

# After uat merge, update on prod branch
git checkout prod && git pull
# Edit Puppetfile to same date tag
./bin/fsx-puppetfile-format check Puppetfile
git add Puppetfile && git commit -m "<TICKET-ID>: Release <module> to YYYY-MM-DD"
git push
```

**This step must be repeated for each environment.** The Puppetfile bump is per-branch, not automatic.

---

## Environment Reference

| Control repo | Source prefix | Branch pattern | Example environment |
|-------------|---------------|----------------|---------------------|
| `control/infra` | `infra` | `infra_<branch>` | `infra_cu_infra_11349_modulejail` |
| `control/jax` | `jax` | `jax_<branch>` | `jax_cu_exch_717_auto_reboot` |
| `control/proxmox` | `proxmox` | `proxmox_<branch>` | `proxmox_prod` |

**Default branch**: `main` for modules, `prod` for control repos (except proxmox which uses `prod`).

**Modules using `master` instead of `main`:** `fsx_pcap`, `fsx_repo`, `puppet-keepalived`, `fsx_tacacs`. Adjust `--target-branch` accordingly.

---

## Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Tag push rejected | Tag name already exists | Check `git tag -l` — use a different suffix or verify the existing tag points to the right commit |
| Puppetfile format check fails | Module in wrong position or missing key | Run `./bin/fsx-puppetfile-format fix Puppetfile` then review the diff |
| Server hook rejects MR | Commit not reachable from target branch | Rebase topic branch from the target branch first |
| g10k deploy shows stale tag | Cache or webhook delay | Trigger manual g10k deploy (see Step 3.3) |
| "Branch name contains non-word characters" | Hyphens/slashes in branch name | Rename branch: `git branch -m <old> <new>` |
| Date tag collision | Another module tagged with same date | Append letter: `2026-06-09b` |

---

## Red Flags

- **Never** tag a module with failing tests
- **Never** push a date tag to a topic branch — date tags are for `main` only
- **Never** force-push tags (`git push --force origin <tag>`) — tags are immutable
- **Never** skip the Puppetfile format check
- **Never** merge to prod without first merging through sit and uat
- **Always** verify the g10k deployment on the puppet master before running puppet agent
- **Always** include the ticket ID in commit messages
- **Always** use the company email as git author

---

## Integration

**Pairs with:**
- `srepowers:puppet-merge-request` — creates the MR chain (invoked during Phase 3)
- `srepowers:puppet-code-analyzer` — validates module code before tagging
- `srepowers:puppet-deploy` — applies the released code to target hosts
- `srepowers:test-driven-operation` — verification discipline for each phase gate
- `gitlab-cli` — reference for `glab` commands when troubleshooting MR issues
