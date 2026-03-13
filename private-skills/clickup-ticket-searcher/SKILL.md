---
name: clickup-ticket-searcher
description: |
  Search ClickUp to list, view, or report on existing tickets/tasks.

  Use when the user mentions ClickUp in a read context: viewing their workload,
  checking assigned tickets, listing tasks by queue or searching tickets, or getting ticket reports.

  Common triggers:
  - "my tickets" / "my queue" / "assigned to me" / "show my tasks"
  - "what's on my plate" / "ticket report" / "SRE tickets"
  - "list my clickup tasks" / "search clickup" / "CCB state"

  DO NOT use for: creating, updating, or deleting ClickUp items.
---

# ClickUp Ticket Searcher

This skill searches ClickUp tickets using the ClickUp MCP server and generates 4 formatted lists with specific filter patterns.

## Prerequisites

- ClickUp MCP server must be connected (check with `claude mcp list`)
- The `mcp__clickup__clickup_search` tool must be available
- User ID for the default assignee (configure your own via `mcp__clickup__clickup_resolve_assignees`)

## Workflow

### Step 1: Ask User for Search Mode

**IMPORTANT:** Before executing any searches, ask the user which mode they want:

Use `AskUserQuestion` with these options:

| Option | Description |
|--------|-------------|
| **Default (4 lists)** (Recommended) | Run the standard 4-list search: SRE queue, SRE + assignee, Project-A + assignee, CCB State |
| **Interactive menu** | Customize search filters: choose assignee, queue, and/or CCB state filters |

Default values:
- Assignee: `<YOUR_NAME>` (ID: `<YOUR_USER_ID>` - configure your own)
- Queue: SRE
- CCB State: All values

### Step 2: Verify MCP Connection

Before searching, verify the ClickUp MCP is connected:

```bash
claude mcp list 2>/dev/null | grep -i clickup
```

### Step 3: Resolve Assignee ID (if needed)

If the assignee ID is unknown, resolve it:

```
mcp__clickup__clickup_resolve_assignees with assignees: ["<YOUR_NAME>"]
```

### Step 4: Interactive Menu (if selected)

If the user chose "Interactive menu", ask follow-up questions:

**Question 1: Assignee Filter**
- Options: "Me" (default), "All assignees", "Custom (enter name)"
- If custom, use `mcp__clickup__clickup_resolve_assignees` to get the user ID

**Question 2: Queue Filter**
- Options: "SRE" (default), "Project Alpha", "Project Beta", "All queues", "Custom (enter keyword)"

**Question 3: CCB State Filter**
- Options: "All states" (default), "Approved only", "Pending (Requested/CCB Ready)", "Custom"
- CCB State values: 0=Requested, 1=CCB Ready, 2=On hold, 3=Rejected, 4=Approved, 5=Cond. Approved, 6=Emergency Approved, 7=Lasting consent, 8=Not Required

### Step 5: Execute Searches

Run the following searches in parallel when possible:

1. **Queue: SRE** - Search with keyword "SRE" to get all SRE-related tickets
2. **Queue: SRE AND Assignees: Me** - Search with assignee filter for user ID
3. **Queue: Project Alpha AND Assignees: Me** - Search for project tickets assigned to you
4. **CCB State field** - Get detailed task info to check CCB State custom field (field ID: `52115558-7db7-4689-a597-2bc9c922c106`)

### Step 6: Get Due Dates

The search API returns summary data. For due dates, use `mcp__clickup__clickup_get_task` with `detail_level="summary"` on each task to get the `due_date` field.

**Due date conversion:** Due dates are in Unix milliseconds. Convert using:
```python
from datetime import datetime
datetime.fromtimestamp(due_date_ms / 1000).strftime('%Y-%m-%d')
```

### Step 7: Format Output

Generate 4 markdown tables with these columns:

| List | Columns |
|------|---------|
| 1. Queue: SRE | Ticket ID, Name, Status, Due Date |
| 2. Queue: SRE AND Assignees: Me | Ticket ID, Name, Status, Due Date |
| 3. Queue: Project Alpha AND Assignees: Me | Ticket ID, Name, Status, Due Date |
| 4. Assignees: Me AND CCB State | Ticket ID, Name, Status, Due Date, CCB State |

## CCB State Values

The CCB State custom field has these values:
- 0 = Requested
- 1 = CCB Ready
- 2 = On hold
- 3 = Rejected
- 4 = Approved
- 5 = Cond. Approved
- 6 = Emergency Approved
- 7 = Lasting consent
- 8 = Not Required

## Search Patterns

### Pattern 1: Queue SRE
```
mcp__clickup__clickup_search with keywords="SRE" count=100
```

### Pattern 2: SRE + Me
Filter results from Pattern 1 where assignees contains your user ID

### Pattern 3: Project Alpha + Me
```
mcp__clickup__clickup_search with filters={"assignees": ["<YOUR_USER_ID>"]} count=100
```
Then filter for `hierarchy.project.name == "Project Alpha"` (replace with your project name)

### Pattern 4: CCB State
Get detailed task info for tasks in your project space, extract CCB State from custom_fields

## Output Format

```markdown
## 1. Queue: SRE with Status and Due Date

| Ticket ID | Name | Status | Due Date |
|-----------|------|--------|----------|
| INFRA-XXX | [SRE] Task name | status | YYYY-MM-DD or - |

## 2. Queue: SRE AND Assignees: Me with Status and Due Date
...

## 3. Queue: Project Alpha AND Assignees: Me with Status and Due Date
...

## 4. Assignees: Me AND With field: CCB State with Status and Due Date
...
```

## Notes

- Due dates may be `null` for tasks without deadlines - display as `-`
- Status values vary by space/list (e.g., "to do", "in progress", "done", "complete", "stalled")
- CCB State field usage depends on your ClickUp workspace configuration
- Tasks may not have CCB State populated depending on your space setup
