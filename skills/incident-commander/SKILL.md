---
name: incident-commander
description: Use when coordinating response to major infrastructure incidents requiring structured incident command - guides ICS-style response with role assignment, communication templates, and timeline tracking
---

# Incident Commander

## Overview

Coordinate major infrastructure incidents using Incident Command System (ICS) principles. Provides structure for complex outages requiring coordinated response across multiple teams.

**Core principle:** Clear command structure + effective communication + systematic troubleshooting = faster incident resolution.

**Announce at start:** "I'm using the incident-commander skill to coordinate this incident response."

## When to Use

**Use this skill when:**
- Multiple services affected (cascade failure)
- Multiple teams needed for response
- Incident duration expected > 30 minutes
- Customer-facing impact significant
- Executive communication required
- Post-incident review required

**Escalation triggers:**
| Condition | Action |
|-----------|--------|
| Single service, known fix | Use `systematic-troubleshooting` |
| Multiple services, unclear scope | **Use incident-commander** |
| Customer data at risk | **Use incident-commander** |
| Regulatory/compliance impact | **Use incident-commander** |
| Media/social media attention | **Use incident-commander** |

## Incident Command Structure

### Roles

| Role | Responsibility | Typical Assignee |
|------|---------------|------------------|
| **Incident Commander (IC)** | Overall coordination, decision making, communication | Senior SRE, Ops Lead |
| **Operations Lead** | Technical troubleshooting, fix implementation | SRE, Platform Engineer |
| **Communications Lead** | Status updates, stakeholder communication | Support Lead, Manager |
| **Scribe** | Timeline documentation, action logging | Any available team member |

**Note:** One person can hold multiple roles in small incidents.

## The Incident Response Process

### Phase 1: Declaration (0-5 minutes)

**Step 1: Acknowledge and Declare**
```
INCIDENT DECLARED: [brief description]

Severity: [SEV1/SEV2/SEV3]
Start Time: [timestamp]
Detected By: [monitoring/alert/user report]
Impact: [services affected, user impact]

Incident Commander: [name]
Operations Lead: [name]
Communications Lead: [name]
Scribe: [name]

War Room: [Zoom/Meet/Slack link]
Incident Channel: #incident-[YYYY-MM-DD]-[description]
```

**Severity Levels:**
| Level | Criteria | Response Time | Update Frequency |
|-------|----------|---------------|------------------|
| SEV1 | Complete outage, data loss, security breach | Immediate | 15 min |
| SEV2 | Major functionality impaired | 15 min | 30 min |
| SEV3 | Minor impact, workaround available | 30 min | 1 hour |

**Step 2: Establish Communication Channels**

```bash
# Create incident Slack channel
/slack create incident-$(date +%Y%m%d)-brief-description

# Set topic with key links
/slack topic "INCIDENT: [description] | War Room: [link] | Status Doc: [link] | IC: [name]"

# Invite response team
/slack invite @sre-team @platform-team @on-call-engineer
```

**Step 3: Initial Assessment**

```bash
# Scope impact quickly
kubectl get pods --all-namespaces | grep -v Running
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# Check recent changes
git log --oneline --since="2 hours ago"
kubectl rollout history deployment/[suspected-deployment] -n [namespace]
```

Document in incident timeline:
```markdown
## Incident Timeline

| Time | Event | Who |
|------|-------|-----|
| T+0 | Incident declared | [IC name] |
| T+2 | Impact scoped: [services] affected | [Ops Lead] |
| T+5 | [Next action] | [Assignee] |
```

### Phase 2: Assessment (5-15 minutes)

**Operations Lead:** Follow `systematic-troubleshooting` skill

**Incident Commander:**
1. Monitor troubleshooting progress
2. Prepare for escalation if needed
3. Begin stakeholder communication

**Communications Lead:**
```
Initial Status Update (T+5 min):

🚨 INCIDENT UPDATE

Status: INVESTIGATING
Impact: [Services affected, user-facing?]
Started: [time]
ETA: Unknown, investigating

We are investigating reports of [issue].
We will update every 15 minutes.

Incident Channel: [link]
```

**Scribe:**
- Log every action taken
- Note decisions and rationale
- Track time stamps

### Phase 3: Response (15+ minutes)

**Decision Points:**

| Situation | Decision | Authority |
|-----------|----------|-----------|
| Fix identified, low risk | Proceed with fix | Operations Lead |
| Fix identified, high risk | IC approves before execution | Incident Commander |
| Multiple fix options | IC decides approach | Incident Commander |
| Need external help | IC escalates | Incident Commander |
| Consider rollback | IC decides | Incident Commander |

**Communication Templates:**

**Every 15 minutes (SEV1):**
```
⏱️ INCIDENT UPDATE (T+[minutes])

Status: [INVESTIGATING/IDENTIFIED/MITIGATING]
Root Cause: [known/unknown - brief if known]
Impact: [current status]
Actions: [what's being done]
ETA: [estimated resolution time or "unknown"]

Next update: [time]
```

**When root cause identified:**
```
✓ INCIDENT UPDATE - ROOT CAUSE IDENTIFIED

Cause: [brief description]
Impact: [what was affected]
Fix: [what's being done]
ETA: [time to resolution]
```

**When mitigated:**
```
✅ INCIDENT RESOLVED

Duration: [start] to [end] ([duration])
Resolution: [what fixed it]
Verification: [how we confirmed]

Monitoring for [X] minutes before all-clear.
Post-mortem scheduled: [date/time]
```

### Phase 4: Resolution and Recovery

**Step 1: Verify Fix**
- All services healthy
- Metrics back to baseline
- No new errors

**Step 2: Monitor**
- Watch for 15-30 minutes
- Confirm no recurrence
- Monitor for cascade effects

**Step 3: Communications**
- Final all-clear
- Schedule post-mortem
- Thank response team

### Phase 5: Post-Incident

**Immediate (within 1 hour):**
- Export incident timeline
- Collect key metrics/logs
- Preserve evidence

**Within 24 hours:**
- Schedule post-mortem
- Create preliminary timeline
- Identify action items

**Use `post-mortem-writer` skill for documentation.**

## Communication Guidelines

### Internal (Response Team)
- **Channel:** Incident Slack channel
- **Frequency:** Real-time updates
- **Content:** Technical details, actions taken

### Stakeholders (Internal)
- **Channel:** #incidents or #engineering
- **Frequency:** Every 15-30 minutes
- **Content:** Status, impact, ETA

### Customers (External)
- **Channel:** Status page, Twitter
- **Frequency:** Every 30-60 minutes
- **Content:** High-level status, no technical details

### Executive
- **Channel:** Email or direct message
- **Frequency:** At declaration, resolution, and key milestones
- **Content:** Business impact, estimated revenue/customer impact

## SRE Principles

### Safety First
- No rushed fixes without risk assessment
- Rollback plan ready before any change
- Two-person rule for high-risk actions

### Structured Output
- Use templates for all communications
- Maintain structured timeline
- Clear role assignments

### Evidence-Driven
- Document every action with timestamp
- Reference specific metrics and logs
- Preserve evidence for post-mortem

### Audit-Ready
- Complete timeline of events
- Decision rationale documented
- All actions attributable

### Communication
- Lead with impact and ETA
- Regular updates even if no progress
- Clear escalation paths

## Red Flags

**Stop and reassess when:**
- Fix attempts making situation worse
- Multiple people giving conflicting instructions
- Communication breaking down
- No clear progress after 30 minutes
- Customer impact increasing

**Escalate immediately when:**
- Data loss suspected
- Security breach possible
- Regulatory compliance at risk
- Executive attention required

## Integration

**Pairs with:**
- `systematic-troubleshooting` - Technical root cause analysis
- `post-mortem-writer` - Post-incident documentation
- `observability-integration` - Metrics-driven assessment

**Called by:**
- Any major incident requiring coordination
- Automated escalation from monitoring

## Differences from Regular Troubleshooting

| Aspect | Regular Troubleshooting | Incident Commander |
|--------|------------------------|-------------------|
| **Scope** | Single service | Multiple services/teams |
| **Structure** | Individual investigation | Coordinated response |
| **Communication** | Ad-hoc updates | Structured, regular updates |
| **Documentation** | Notes | Formal timeline |
| **Roles** | One person | Multiple defined roles |
| **Post-incident** | Optional review | Mandatory post-mortem |

## Distributed and Async Incident Response

The standard ICS model assumes synchronous, co-located response. Distributed teams across time zones require adaptations.

### When Distributed Patterns Apply

| Condition | Adaptation |
|-----------|-----------|
| On-call engineer in different time zone from affected users | Async handoff protocol |
| Incident duration > 8 hours | Shift handoff with written transfer |
| Team span > 3 time zones | Follow-the-sun IC rotation |
| No synchronous war room possible | Written command structure |

### Async Incident Command Structure

Replace synchronous war room with a structured incident document as the single source of truth:

```markdown
# Incident Command Document — [INC-YYYY-MMDD-NNN]

**Status:** [INVESTIGATING / IDENTIFIED / MITIGATING / RESOLVED]
**Severity:** SEV[1/2/3]
**Started:** [UTC timestamp]
**IC:** [Name] (on-call until [UTC time], then handoff to [Name])
**Last updated:** [UTC timestamp] by [Name]

## Impact
[Current user-facing impact — update on every status change]

## Timeline
| Time (UTC) | Event | Who |
|------------|-------|-----|
| 00:00 | Incident declared | [Name] |
| 00:05 | [action taken] | [Name] |

## Current Working Theory
[One paragraph — what we believe is happening and why]

## Actions In Progress
- [ ] [Name]: [action] — ETA [time]
- [ ] [Name]: [action] — ETA [time]

## Actions Completed
- [x] [Name] at [time]: [action] — Result: [outcome]

## Do NOT Do
- [anything tried that made it worse]
- [dead ends to avoid]

## Handoff Notes (for next IC)
[What the incoming IC needs to know to continue response]
```

### IC Handoff Protocol

When the active IC reaches end of their shift during an ongoing incident:

**30 minutes before handoff:**
1. Update incident document with current state
2. Summarize "Current Working Theory" in 2-3 sentences
3. List all active actions and their owners
4. Identify the single most important next diagnostic step

**Handoff message template (post in incident channel):**
```
🔄 IC HANDOFF: [Outgoing IC] → [Incoming IC]

Current Status: [one line]
Working Theory: [one line]
Active Actions: [N actions in progress, see incident doc]
Next Critical Step: [what incoming IC should do first]
Escalation Context: [who to call if [condition]]

Incident Doc: [link]
War Room (if active): [link]
```

**Incoming IC acknowledgment (required):**
```
✅ IC HANDOFF ACKNOWLEDGED — [Incoming IC]
I have read the incident document and understand:
1. [confirm working theory]
2. [confirm next step]
3. [any questions for outgoing IC]
```

### Follow-the-Sun IC Rotation

For long-running incidents (> 8 hours) spanning time zones:

```markdown
## IC Rotation Schedule — [Incident Name]

| Window (UTC) | IC | Backup IC | Timezone |
|--------------|----|-----------|----------|
| 00:00–08:00 | [Name] | [Name] | APAC |
| 08:00–16:00 | [Name] | [Name] | EMEA |
| 16:00–24:00 | [Name] | [Name] | Americas |

Handoff at each window boundary. Use handoff protocol above.
```

### Async Communication Patterns

When synchronous communication is not possible:

**Instead of verbal war room — async channel protocol:**

```
Update every 30 min (SEV1) / 60 min (SEV2):

🕐 [UTC time] STATUS UPDATE — [IC Name]

WHAT WE KNOW: [2-3 sentences max]
WHAT WE'RE DOING: [active actions]
WHAT WE NEED: [blocking items — specific asks to named people]
NEXT UPDATE: [UTC time]
```

**For cross-timezone escalation:**
```
🚨 ESCALATION REQUEST — [UTC time]

Requesting: [Name / Team] to join incident
Why now: [specific reason this can't wait for business hours]
What we need: [specific skill/access/decision]
Contact: [phone / page / Slack]
Incident doc: [link]
```

### Long-Running Incident Management (> 4 hours)

**Every 4 hours, the IC must:**

1. **Reassess severity** — has impact changed?
2. **Review working theory** — is the hypothesis still valid?
3. **Check team fatigue** — rotate if anyone has been active > 4 hours
4. **Stakeholder update** — even if no progress, communicate that

**4-hour checkpoint template:**
```
⏱️ 4-HOUR CHECKPOINT — [Incident Name]

Duration: [X] hours
Severity: [same/escalated/downgraded] — [reason if changed]
Progress: [what we've ruled out, what we've confirmed]
Current hypothesis: [updated theory]
Team status: [who is rotating in/out]
Decision needed: [if IC cannot resolve, escalate to [Name] for call on [option A vs B]]

Next checkpoint: [UTC time]
```

### Escalation Decision Framework (Async)

When escalation is needed but stakeholders are asleep:

| Condition | Action |
|-----------|--------|
| SEV1 (full outage, data loss risk) | Page immediately regardless of time zone |
| SEV2, degraded > 2 hours, no progress | Page on-call manager, not full team |
| SEV2, workaround available | Post in #incidents, schedule morning sync |
| SEV3, impact isolated | Update ticket, no paging |

**Escalation test:** "If this incident is still open at 08:00 local time for [stakeholder], will I be glad I paged them at 02:00?" If yes, page. If uncertain, page manager first.
