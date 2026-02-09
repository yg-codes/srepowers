---
name: clickup-ticket-creator
description: Use when creating ClickUp tickets following the CCB template format - structures content with Description, Rationale, Impact, Risk, UAT, Procedure, Verification, and Rollback sections
---

# Clickup Ticket Creator

Create Clickup tickets following the CCB (Change Control Board) template format. This skill ensures consistent ticket structure with all required sections for infrastructure change requests.

## When to Use This Skill

- Creating INFRA tickets for infrastructure changes
- Preparing change control board (CCB) requests
- Documenting production changes with proper risk assessment
- Structuring tickets with Description, Rationale, Impact, Risk, UAT, Procedure, Verification, Rollback

## How This Skill Works

Two modes available:

1. **Interactive Mode** - Ask the user for each section step-by-step
2. **Free-form Mode** - Accept a description and structure it into the CCB template format

## Ticket Structure (CCB Template)

The ticket follows this exact format:

```markdown
# Title:
*Priority rules: Low (2 weeks), Normal/High (5 business days), Urgent (same day)*

# **Description**
What should be done in this task.

# **Rationale**
Why the change is needed.

**Production change**
YES [ ] NO [ ]

# **Impact**
HIGH - May impact the business.
MEDIUM - May impact the office (we can't work). Some sub-systems may fail.
LOW - Very minor things may fail.

# **Risk**
HIGH - Long, hard to test, first time doing it.
MEDIUM - Good confidence, tested in UAT.
LOW - Strong confidence, BAU change.

# **UAT implementation**
OK - UAT implementation is done
In SIT - Tested in SIT, no UAT
No UAT - No UAT nor SIT available
N/A - UAT doesn't make sense

# **Procedure**
Commands/procedure used to implement the change.
- Action: <Commands>
    - Expect:

# **Verification**
Commands/procedure used to validate the change.
Example: `du -sh /var/log` . Expect: usage less than 20G.

# **Rollback**
Commands/procedures used to rollback the change.
**Estimated rollback time**: x minutes, y hours
```

## Default Values

| Field | Default Value |
|-------|---------------|
| Status | triage |
| Assignee | Unassigned |
| Priority | Normal (5 business days) |
| Ticket ID Format | INFRA-xxxx |

## Workflow

### Step 1: Determine Mode

Ask the user which mode they prefer:

- **Interactive**: "Should I prompt you for each section individually?"
- **Free-form**: "Paste your ticket description and I'll structure it"

### Step 2: Gather Information

**For Interactive Mode:**
1. Title
2. Description (what should be done)
3. Rationale (why the change is needed)
4. Production change (YES/NO)
5. Impact level (HIGH/MEDIUM/LOW) - User provides level, then writes a brief description. Review and revise the justification based on the level selected and description provided.
6. Risk level (HIGH/MEDIUM/LOW) - User provides level, then writes a brief description. Review and revise the justification based on the level selected and description provided.
7. UAT implementation status (OK/In SIT/No UAT/N/A)
8. Procedure (action commands and expected results)
9. Verification (validation commands and what to look for)
10. Rollback (rollback commands and estimated time)

**For Free-form Mode:**
Analyze the user's input and extract/structure information into the appropriate sections. If critical information is missing, prompt for it.

### Step 3: Format Output

Generate the complete ticket content following the CCB template format exactly. The output should be ready to copy-paste into Clickup.

### Step 4: Present to User

Display the formatted ticket and ask the user how they want to proceed:

**Copy/Paste Mode**: Display the full ticket content in a code block for manual copy-paste into Clickup.

**File Mode**: Ask for a filename (default: `INFRA-ticket-YYYYMMDD.md`) and write the ticket content to a markdown file in the current working directory.

## Templates Reference

| Template File | Location |
|---------------|----------|
| CCB Template | `assets/CCB-Template-20260105.md` |

Load the template file when generating tickets to ensure exact format compliance.

## Notes

- Tickets are created manually by copying the output into Clickup (no API integration)
- Always follow the CCB template structure exactly
- Include the priority reminder note at the top
- Ensure all sections are present even if minimal content
