---
name: post-mortem-writer
description: Use when creating blameless post-mortems after infrastructure incidents or outages that need documented timeline, root cause, and action items
---

# Post-Mortem Writer

## Overview

Create blameless post-mortems that focus on learning and prevention rather than blame. Document what happened, why it happened, and how to prevent recurrence.

**Core principle:** Blameless post-mortems create a culture of learning and continuous improvement.

**Announce at start:** "I'm using the post-mortem-writer skill to create a blameless post-mortem for this incident."

## When to Use

**Required for:**
- All SEV1 incidents
- Any incident with customer impact
- Any incident requiring rollback
- Any incident > 30 minutes duration
- Any security or data integrity incident

**Recommended for:**
- SEV2 incidents
- Near-misses (could have been worse)
- Interesting failures with learning value
- First occurrence of a new failure mode

**Not needed for:**
- Planned maintenance with expected behavior
- Issues caught in staging before production
- Minor issues with obvious fixes and no impact

## The Post-Mortem Process

### Step 1: Gather Evidence (Before Writing)

Collect all relevant data:

```bash
# Timeline reconstruction
kubectl --context <context> get events --all-namespaces --sort-by='.lastTimestamp' --since-time="2026-01-15T10:00:00Z"

# Logs from affected services
kubectl --context <context> logs -n [namespace] -l app=[app-name] --since=2h

# Metrics during incident window
# (Export from Prometheus/Grafana)

# Changes during incident window
git log --since="2 hours ago" --oneline

# Deployment history
kubectl --context <context> rollout history deployment/[name] -n [namespace]
```

**Evidence checklist:**
- [ ] Incident timeline (from scribe or reconstructed)
- [ ] Monitoring alerts and their timing
- [ ] Log excerpts showing errors
- [ ] Metrics showing impact
- [ ] Changes made during incident
- [ ] Communication records (Slack, PagerDuty)

### Step 2: Write Post-Mortem

Use this structure:

```markdown
# Post-Mortem: [Brief Incident Description]

**Date:** YYYY-MM-DD
**Incident ID:** INC-YYYY-MM-DD-XXX
**Severity:** SEV1/SEV2/SEV3
**Duration:** HH:MM (Start: HH:MM, End: HH:MM)
**Authors:** [Names]
**Status:** [Draft/Review/Complete]

---

## Executive Summary

[2-3 sentences describing what happened and impact]

**Impact:**
- Services affected: [list]
- Users affected: [number or "unknown"]
- Data loss: [yes/no, extent if yes]
- Revenue impact: [if applicable]

---

## Timeline (All Times UTC)

| Time | Event | Source |
|------|-------|--------|
| 10:00 | First alert fired: High error rate on api-service | PagerDuty |
| 10:05 | Engineer acknowledged alert | PagerDuty |
| 10:10 | Identified database connection pool exhaustion | Logs |
| 10:15 | Attempted fix: Increased connection pool size | Runbook |
| 10:20 | Fix failed, error rate increased | Metrics |
| 10:25 | Rolled back to previous version | kubectl --context <context> rollout undo |
| 10:30 | Service recovered, error rate normal | Metrics |
| 10:45 | All services verified healthy | Manual check |

---

## Root Cause Analysis

### What Happened

[Detailed description of the failure]

### Why It Happened

**Contributing factors:**
1. [Factor 1: e.g., Recent deployment introduced connection leak]
2. [Factor 2: e.g., Connection pool size not sufficient for peak load]
3. [Factor 3: e.g., Monitoring didn't alert on connection pool saturation]

**Trigger:**
[The specific event that caused the incident]

**Root Cause:**
[The underlying issue that allowed the trigger to cause impact]

---

## Impact Assessment

| Category | Impact | Details |
|----------|--------|---------|
| Availability | 99.5% → 95% | 30-minute partial outage |
| Latency | p99 50ms → 500ms | During outage window |
| Error Rate | 0.1% → 15% | HTTP 500 errors |
| Users Affected | ~10,000 | Based on request volume |
| Data Loss | None | No data corruption |

---

## Detection

**How was the incident detected?**
- [ ] Automated alert
- [ ] Customer report
- [ ] Internal user report
- [ ] Monitoring dashboard

**Time to detect:** X minutes
**Time to acknowledge:** X minutes

**Detection gaps:**
[What wasn't detected quickly enough and why]

---

## Response

**What went well:**
1. [Positive aspect 1]
2. [Positive aspect 2]

**What could have gone better:**
1. [Improvement area 1]
2. [Improvement area 2]

**Lessons learned:**
1. [Lesson 1]
2. [Lesson 2]

---

## Action Items

| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|
| 1 | Fix connection pool leak in api-service | @engineer1 | P0 | YYYY-MM-DD | Open |
| 2 | Add monitoring for connection pool saturation | @engineer2 | P1 | YYYY-MM-DD | Open |
| 3 | Update runbook with rollback procedure | @engineer3 | P2 | YYYY-MM-DD | Open |
| 4 | Load test connection pool limits | @engineer1 | P1 | YYYY-MM-DD | Open |

---

## Appendix

### Supporting Data

[Links to metrics, logs, additional context]

### Related Incidents

[Links to similar past incidents]

### References

[Runbooks, architecture docs, etc.]
```

### Step 3: Review and Share

**Review checklist:**
- [ ] Timeline is accurate and complete
- [ ] Root cause is specific (not "human error")
- [ ] No blame assigned to individuals
- [ ] Action items are specific and assigned
- [ ] Impact is quantified where possible
- [ ] Lessons learned are captured

**Share with:**
- Response team (for accuracy check)
- Engineering leadership
- Broader engineering team (for learning)

### Step 4: Follow Up

**Track action items:**
- Review weekly until all closed
- Update post-mortem with completion status
- Verify fixes prevent recurrence

## Writing Guidelines

### Be Specific

**❌ Bad:** "The database was slow"
**✅ Good:** "Database query latency increased from 5ms to 200ms due to missing index on user_id column"

### Be Blameless

**❌ Bad:** "Engineer X forgot to add the index"
**✅ Good:** "The deployment process didn't include a database schema review step"

### Focus on Systems

**❌ Bad:** "Someone should have caught this"
**✅ Good:** "Our pre-deployment checks didn't include database query plan analysis"

### Quantify Impact

**❌ Bad:** "Users were affected"
**✅ Good:** "Approximately 10,000 users experienced 30-second page load times"

## SRE Principles

### Safety First
- Focus on how to prevent, not who to blame
- Create psychological safety to report issues
- Action items address systemic issues

### Structured Output
- Use consistent post-mortem template
- Include timeline, root cause, impact, action items
- Make scannable with tables and sections

### Evidence-Driven
- Reference specific metrics, logs, timestamps
- Include actual alert text
- Link to supporting data

### Audit-Ready
- Complete timeline of events
- All decisions documented
- Action items tracked to completion

### Communication
- Lead with impact and root cause
- Explain technical details clearly
- Share lessons learned broadly

## Common Mistakes

### Blame assignment
- **Problem:** "Engineer X made a mistake"
- **Fix:** "The process allowed this mistake to reach production"

### Vague root cause
- **Problem:** "A bug caused the outage"
- **Fix:** "The deployment introduced a race condition in the connection pool manager"

### Missing timeline
- **Problem:** No specific times recorded
- **Fix:** Include precise timestamps for all key events

### Action items too vague
- **Problem:** "Improve monitoring"
- **Fix:** "Add alert when connection pool utilization > 80% for 2 minutes"

### Not sharing broadly
- **Problem:** Post-mortem only seen by immediate team
- **Fix:** Share with all engineering for organizational learning

## Integration

**Pairs with:**
- `incident-commander` - Uses incident timeline and records
- `systematic-troubleshooting` - Root cause analysis
- `observability-integration` - Metrics and evidence

**Called by:**
- After any incident requiring documentation
- During scheduled post-mortem meetings

## Post-Mortem Meeting Format

**Duration:** 30-60 minutes
**Attendees:** Response team, relevant stakeholders

**Agenda:**
1. **Timeline review** (10 min) - Verify accuracy
2. **Root cause discussion** (15 min) - Understand why
3. **What went well/not well** (10 min) - Process improvement
4. **Action item review** (10 min) - Assign and prioritize
5. **Lessons learned** (5 min) - Share insights

**Ground rules:**
- Blameless culture
- Focus on improvement
- Everyone can speak
- Document decisions
