---
name: aws-account-inspection
description: Read-only audit and discovery of a single AWS account's resources, architecture, and Well-Architected posture. Use this whenever the user wants to inspect, audit, enumerate, inventory, map, or document an AWS account — its IAM, networking, compute, storage, databases, security services, monitoring, messaging, CloudFormation, DNS, and cost — and produce a structured findings report. Triggers on "inspect/audit/review/walk this AWS account", "what's in account X", "enumerate resources", "account inventory", "AWS architecture discovery", "Well-Architected assessment", or continuing a per-account inspection series. Strictly read-only — never mutates. Use even when the user names only one layer (e.g. "what VPCs are in this account") if a full picture is implied.
---

# AWS Account Inspection (Read-Only)

Inspect any AWS account using **read-only** AWS CLI calls and produce a consistent
markdown report: a 12-phase resource inventory plus a Phase 13 Well-Architected
scorecard. The discipline here is safety (never mutate, never leak secrets) and
**evidence-first** reporting (every claim traces to a command you ran).

This skill is self-contained. The per-phase command catalog lives in
`references/phases.md` — read it when you reach the inspection phases. The Phase 13
rubric is below in full because it's the synthesis step most worth having inline.

## When NOT to use this

- The user wants to *create, change, or delete* AWS resources → this skill is read-only; stop and use a deployment workflow instead.
- The user wants to *design* a new architecture → that's a design task, not discovery.
- A single trivial lookup the user can read off one command with no report needed (e.g. "is bucket X versioned?") → just answer it.

## Safety contract (hard constraints — violating any is a failure)

These exist because an inspection runs against live accounts, often production.
A read-only guarantee is what makes it safe to run without a change ticket.

1. **Verb allowlist.** Only `describe-*`, `get-*`, `list-*`, `ls`, `lookup-events`,
   `head-*`. Never `create/delete/update/put/attach/detach/start/stop/terminate/run/modify/enable/disable/tag/untag/invoke/assume-role`. If a question can only be answered by a mutating call, record it as a gap — do not run it.
2. **Profile enforcement.** Every `aws` command includes `--profile $PROFILE`. Never a default profile or env var. Only profiles mapped to `ReadOnlyAccess` (or a profile the user explicitly approved for read-only verbs).
3. **No secrets in output.** Never write access keys, secret keys, passwords, or tokens. SSM `SecureString`: record name + type only, never the value. KMS: record key ID + state, never key material. This repo is GitHub-mirror-eligible — also avoid internal IPs and hostnames in the notes.
4. **Region discipline.** Default `ap-northeast-1`; pass `--region $REGION` on regional commands. Global services (IAM, Organizations, Route 53 zones) omit `--region`.
5. **AccessDenied is data, not an error.** `AccessDenied`/`UnauthorizedOperation` is an IAM/SCP boundary lesson. Record the command, error, and denied service as a finding. Do NOT retry with a different profile or seek a workaround. Move on.

## Pre-flight (stop if any step fails)

SSO is browser-based — **you cannot log the user in.** If identity check fails with
an expired-token error, ask the user to run `! aws sso login --profile $PROFILE`
themselves, then retry. Do not start enumeration until pre-flight passes.

```bash
# 1. Identity — assert Account matches the target ID and Arn contains the RO role
aws sts get-caller-identity --profile $PROFILE --output json

# 2. Region reachable — assert ≥1 AZ returned
aws ec2 describe-availability-zones --profile $PROFILE --region $REGION --output table
```

If `Account` ≠ the expected `$ACCOUNT_ID`, or the `Arn` is not the read-only role,
**stop and report the mismatch** — never inspect the wrong account.

## Session variables

```bash
PROFILE="<ro-profile>"     # e.g. fsx-aws-prod-ro
REGION="ap-northeast-1"
ACCOUNT_NAME="<account>"   # e.g. fsx-prod-apps
ACCOUNT_ID="<id>"          # e.g. 213387004475
```

## Workflow

1. **Pre-flight** (above). Confirm you are in the right account as the RO role.
2. **Run phases 1–12.** Read `references/phases.md` for the exact commands per phase.
   Phase 1 (identity) and Phase 7 (security) are mandatory. Every other phase has a
   **skip condition** — if the headline count is 0, write
   `## Phase N: <Title> — SKIPPED (0 resources found)` and move on. Don't enumerate
   sub-resources of an empty service; that's wasted context with no learning value.
3. **Token discipline.** Always `--output json | jq '<filter>'` to extract only the
   fields that matter. Never dump full JSON or run `-V`/`--verbose`/`--debug` into the
   report. For large accounts, fan the phases out to parallel subagents (each phase is
   independent and read-only) and collate their structured returns.
4. **Phase 13 — Well-Architected scorecard** (below). Synthesis only, no new API calls.
5. **Write the report** to `notes/<NN>-<account-name>.md` following the structure in
   `references/phases.md` §Output. Check the `notes/` directory for the current highest
   `NN` and continue the sequence.
6. **Verify before claiming done** — run the post-inspection checklist at the end of
   `references/phases.md`. Don't report "complete" until every phase is executed or
   explicitly skipped and the scorecard has no blank cells.

## Phase 13 — Well-Architected Assessment (mandatory)

This is the synthesis phase: it turns the raw inventory from Phases 1–12 into a
posture judgement. **No new AWS API calls** — read only the evidence already gathered.
The point is to move the report from *"here is what exists"* to *"here is how well it
is built, and where the gaps are."*

Score each of the six AWS Well-Architected pillars **Strong / Adequate / Weak /
Unknown**, cite the *specific* phase evidence that justifies the score, and turn each
gap into a Key Findings row. "Unknown" is legitimate when a read-only inspection
genuinely cannot see the signal (e.g. application-level resilience) — say so rather
than guess. A fixed rubric is what makes two accounts comparable and makes a *missing*
control visible: an empty cell is itself a finding.

| Pillar | Look for (evidence source) | Strong if… | Weak if… |
|---|---|---|---|
| **Operational Excellence** | CloudFormation/CDK stacks, tags (Ph12), SSM docs (Ph11), dashboards/alarms (Ph8) | IaC-managed, tagged, has dashboards | No IaC, untagged, no dashboards |
| **Security** | IAM users vs roles (Ph1/7), CloudTrail/Config/GuardDuty/Security Hub (Ph7), KMS CMK vs AWS-managed (Ph7), S3 public-access blocks (Ph4), SGs (Ph2) | 0 IAM users (SSO only), CloudTrail logging, GuardDuty on, S3 fully blocked | IAM users w/ keys, no CloudTrail, GuardDuty off, Security Hub 0 standards, open SGs |
| **Reliability** | Multi-AZ (Ph5/Ph2), PITR/backups (Ph5), versioning (Ph4), health checks (Ph6), alarms (Ph8) | Multi-AZ DBs, PITR on, versioned, alarms present | Single-AZ DB, no PITR, no backups, no alarms |
| **Performance Efficiency** | Instance generations (Ph3), serverless vs VM mix (Ph3), caching (Ph5/Ph6) | Current-gen, right-sized, serverless-first | Old-gen, oversized, no caching where expected |
| **Cost Optimization** | Cost trend (Ph12), S3 lifecycle (Ph4), log retention (Ph8), budgets (Ph12), idle resources (Ph3) | Lifecycle + retention set, budgets configured, no idle | Rising cost no budget, no lifecycle, ∞ retention, idle EIPs/volumes |
| **Sustainability** | Idle/over-provisioned resources (Ph3/8), serverless adoption (Ph3) | Serverless-heavy, no idle waste | Idle EC2, unattached volumes, ∞-retention logs |

**Scorecard output (Phase 13 section of the report):**

```markdown
| Pillar | Score | Evidence (cite phase) | Gaps |
|---|---|---|---|
| Operational Excellence | Adequate | 16 CFN stacks all org-managed; 0 dashboards (Ph8) | No app-level dashboards |
| Security | Weak | Security Hub enabled but 0 standards (Ph7); 1 CRITICAL Inspector finding open | Subscribe FSBP; remediate finding |
| … | … | … | … |
```

Each **Weak** (and each **Adequate** with a clear gap) must produce a corresponding
row in the **Key Findings** table with a severity and recommendation. Phase 13 is the
bridge from inventory to findings — not a scoring exercise that floats free of them.

## Anti-patterns

| Anti-pattern | Do instead |
|---|---|
| Full JSON dump into the report | `jq` only the fields you'll cite |
| Enumerating sub-resources of an empty service | Record count 0, trigger skip |
| Re-running across all regions | Inspect `$REGION`; note multi-region resources if found |
| Retrying AccessDenied with another profile | Record it as a boundary finding, move on |
| A Phase 13 score with no cited evidence | Every score names the phase that justifies it |
| Claiming done before the checklist passes | Run the post-inspection checklist first |
