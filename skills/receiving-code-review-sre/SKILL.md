---
name: receiving-code-review-sre
description: Use when receiving code review feedback on infrastructure changes, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception (SRE/Infrastructure)

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (explicit CLAUDE.md violation)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
your human partner: "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

**your human partner's rule:** "External feedback - be skeptical, but check carefully"

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**your human partner's rule:** "You and reviewer both report to me. If we don't need this feature, don't add it."

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve your human partner if architectural

**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
❌ "Thanks for [anything]"
❌ ANY gratitude expression
```

**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

❌ Long apology
❌ Defending why you pushed back
❌ Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |

## Real Examples

**Performative Agreement (Bad):**
```
Reviewer: "Remove legacy code"
❌ "You're absolutely right! Let me remove that..."
```

**Technical Verification (Good):**
```
Reviewer: "Remove legacy code"
✅ "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
✅ "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**Unclear Item (Good):**
```
your human partner: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## Infrastructure Review Scenarios

### Kubernetes Manifest Reviews

**Resource Limits:**
```
Reviewer: "Add resource limits to all deployments"

Before implementing:
  1. Check: Does application have predictable resource usage?
  2. Check: Are metrics available to determine appropriate limits?
  3. Check: Will limits cause OOMKills under load?

✅ "Checked metrics - app uses 200-800MB RAM. Proposing 256Mi request, 1Gi limit. Should work, but need load test to confirm. Proceed?"
```

**Security Contexts:**
```
Reviewer: "Run as non-root, drop all capabilities"

Before implementing:
  1. Check: Does application write to root-owned paths?
  2. Check: Does it bind to privileged ports (<1024)?
  3. Check: Are there init containers or sidecars requiring capabilities?

✅ "App binds to port 80. Options: (1) run as root with dropped caps, (2) use NET_BIND_SERVICE cap, (3) change to port 8080. Which approach?"
```

**Labels and Annotations:**
```
Reviewer: "Add standard labels to all resources"

Before implementing:
  1. Check: What labeling standard? (k8s recommended, org-specific)
  2. Check: Are selectors using existing labels that can't change?
  3. Check: Will label changes break existing monitoring/CI pipelines?

✅ "Existing deployment uses 'app=myapp' selector. Standard labels use 'app.kubernetes.io/name'. Need to migrate both deployment and service selectors atomically. Proceed with migration?"
```

### Terraform Plan Reviews

**State Changes:**
```
Reviewer: "Terraform shows resource replacement, that's fine"

Before implementing:
  1. Check: What data will be lost?
  2. Check: Is this production or non-production?
  3. Check: Are there dependent resources not managed by Terraform?
  4. Check: Is there a backup/restore procedure?

✅ "RDS instance replacement will lose all data. Plan shows no snapshot before destroy. Need to: (1) create manual snapshot, (2) apply, (3) restore data. Proceed with snapshot first?"
```

**Resource Dependencies:**
```
Reviewer: "Remove explicit depends_on, Terraform handles it"

Before implementing:
  1. Check: Are there implicit dependencies Terraform might miss?
  2. Check: Does resource creation have side effects (DNS propagation, IAM eventual consistency)?
  3. Check: What happens if implicit dependency ordering is wrong?

✅ "Explicit depends_on exists because IAM role policy attachment has eventual consistency (30-60s). Without it, EKS cluster creation fails. Keep explicit dependency?"
```

**Cost Implications:**
```
Reviewer: "Upgrade from t3.medium to t3.large for performance"

Before implementing:
  1. Check: What's the monthly cost difference?
  2. Check: Is this in budget/approved?
  3. Check: Are there reserved instances or savings plans applicable?
  4. Check: Is auto-scaling a better alternative?

✅ "Cost difference: $30/mo → $60/mo per instance (3 instances = $90/mo increase). Budget impact: +$1,080/year. No reserved capacity available. Proceed with upgrade, or explore horizontal scaling first?"
```

### Security Group/Firewall Rule Reviews

**Port Exposure:**
```
Reviewer: "Open port 3306 for database access"

Before implementing:
  1. Check: Which source IPs need access?
  2. Check: Is this internet-facing or internal only?
  3. Check: Can we use private endpoints/VPC peering instead?
  4. Check: Are there security compliance requirements (PCI, HIPAA)?

✅ "Request opens 3306 to 0.0.0.0/0. Database contains PII. Options: (1) restrict to specific CIDRs, (2) use VPC endpoint, (3) SSH tunnel. Which approach meets security requirements?"
```

**CIDR Range Accuracy:**
```
Reviewer: "Allow 10.0.0.0/8 for internal services"

Before implementing:
  1. Check: Is this the actual internal range, or too permissive?
  2. Check: Does it overlap with VPC CIDRs?
  3. Check: Are there partner/external networks in that range?

✅ "VPC uses 10.100.0.0/16. 10.0.0.0/8 includes 16M+ IPs from other orgs in shared VPC. Restrict to 10.100.0.0/16 or list specific service CIDRs?"
```

**Least Privilege:**
```
Reviewer: "Allow all outbound traffic"

Before implementing:
  1. Check: What external services does the application actually need?
  2. Check: Are there data exfiltration risks?
  3. Check: Do compliance requirements restrict egress?

✅ "App only needs: (1) S3 API, (2) RDS endpoint, (3) external payment gateway. Restrict egress to these endpoints? Payment gateway uses dynamic IPs - need FQDN-based egress or allow wider range?"
```

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.
