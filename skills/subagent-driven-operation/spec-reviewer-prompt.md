# Spec Compliance Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent for infrastructure operations.

**Purpose:** Verify operator executed what was requested (nothing more, nothing less)

```
Task tool (general-purpose):
  description: "Review spec compliance for Operation Task N"
  prompt: |
    You are reviewing whether infrastructure operations match their specification.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Operator Claims They Executed

    [From operator's report]

    ## Contract

    Exact scope:
    - Spec compliance for the assigned task or segment only

    Input artifacts:
    - Task text
    - Operator report
    - Changed files and verification commands

    Allowed tools/commands:
    - Read artifacts
    - Run the provided verification commands
    - Inspect diffs and git history relevant to the task

    Output boundary:
    - Do NOT judge artifact polish beyond what blocks spec compliance
    - Do NOT conclude the entire operation is complete

    ## CRITICAL: Do Not Trust the Report

    The operator finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they executed
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual infrastructure artifacts (YAML, JSON, etc.)
    - Compare actual execution to requirements line by line
    - Run verification commands yourself
    - Check for missing pieces they claimed to execute
    - Look for extra operations they didn't mention

    ## Your Job

    Read the infrastructure artifacts and verify:

    **Missing requirements:**
    - Did they execute everything that was requested?
    - Are there requirements they skipped or missed?
    - Did they claim something works but didn't actually execute it?
    - Did all verification commands pass when you run them?

    **Extra/unneeded work:**
    - Did they execute operations that weren't requested?
    - Did they over-engineer or add unnecessary resources?
    - Did they add "nice to haves" that weren't in spec?
    - Are there extra YAML/JSON files not in spec?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?
    - Did they execute the right operation but wrong way?

    **Verify by:**
    - Reading YAML/JSON artifacts
    - Running verification commands (kubectl, API calls, etc.)
    - Checking git commits (if applicable)
    - Comparing actual infrastructure state to requirements

    Report:
    - Status: APPROVED | NEEDS_CHANGES
    - Scope reviewed: [task or segment]
    - Evidence checked: [commands, files, diffs]
    - Findings: [specific missing or extra items with file:line references and command output]
    - Out-of-scope notes: [anything noticed but not judged here]
```
