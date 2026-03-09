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
3. VERIFY: Check against infrastructure reality
4. EVALUATE: Technically sound for THIS environment?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, verify each
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

## Source-Specific Handling

### From your human partner
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS environment?
  2. Check: Breaks existing infrastructure?
  3. Check: Reason for current configuration?
  4. Check: Works across all environments (sit/uat/prod)?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with your human partner's prior decisions:
  Stop and discuss with your human partner first
```

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, labels)
     - Complex fixes (refactoring, logic)
  3. Verify each fix individually
  4. Verify no regressions
```

## Infrastructure Review Scenarios

### Kubernetes Manifest Reviews

| Review Suggestion | Before Implementing | Pushback Example |
|------------------|--------------------|--------------------|
| **"Add resource limits"** | Check metrics for usage patterns. Will limits cause OOMKills? | "Checked metrics - app uses 200-800MB. Proposing 256Mi request, 1Gi limit. Need load test to confirm?" |
| **"Run as non-root"** | Check for privileged ports, root-owned paths | "App binds to port 80. Options: (1) run as root with dropped caps, (2) use NET_BIND_SERVICE cap, (3) change to 8080?" |
| **"Add standard labels"** | Check if selectors use existing labels | "Existing deployment uses 'app=myapp'. Need atomic migration of both deployment and service selectors. Proceed?" |

### Terraform Plan Reviews

| Review Suggestion | Before Implementing | Pushback Example |
|------------------|--------------------|--------------------|
| **"Resource replacement is fine"** | Check data loss, backup/restore | "RDS replacement loses all data. No snapshot in plan. Need: (1) manual snapshot, (2) apply, (3) restore?" |
| **"Remove explicit depends_on"** | Check for implicit dependencies Terraform misses | "Explicit dependency exists for IAM eventual consistency (30-60s). Without it, EKS creation fails. Keep?" |
| **"Upgrade instance size"** | Check cost, budget approval, alternatives | "Cost: $30→$60/mo per instance (3 = +$90/mo). Budget impact: +$1,080/yr. Explore horizontal scaling first?" |

### Security Group/Firewall Reviews

| Review Suggestion | Before Implementing | Pushback Example |
|------------------|--------------------|--------------------|
| **"Open port 3306"** | Check source IPs, compliance, alternatives | "Opens 3306 to 0.0.0.0/0. Database has PII. Options: (1) restrict CIDRs, (2) VPC endpoint, (3) SSH tunnel?" |
| **"Allow 10.0.0.0/8"** | Check actual internal range | "VPC uses 10.100.0.0/16. 10.0.0.0/8 includes 16M+ IPs from other orgs. Restrict to 10.100.0.0/16?" |
| **"Allow all outbound"** | Check what external services needed | "App needs: S3, RDS, payment gateway. Restrict egress to these? Payment gateway uses dynamic IPs - FQDN or wider range?" |

## When To Push Back

Push back when:
- Suggestion breaks existing infrastructure
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Security/compliance reasons exist
- Conflicts with your human partner's architectural decisions

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working infrastructure
- Involve your human partner if architectural

**Signal if uncomfortable:** "Strange things are afoot at the Circle K"

## Acknowledging Correct Feedback

```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for [anything]"
```

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against infrastructure first |
| Batch without verification | One at a time, verify each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread (`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a top-level PR comment.

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.
