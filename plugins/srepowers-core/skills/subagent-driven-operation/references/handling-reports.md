# Handling a Report That Isn't DONE

Part of `srepowers-core:subagent-driven-operation`. Read this every time an
operator reports a status other than DONE.

**DONE_WITH_CONCERNS:** The operator completed the work but flagged doubts.
Read the concerns before proceeding. If concerns are about safety or
correctness (e.g., "unexpected pod restarts during rollout"), investigate
before review. If they're observations (e.g., "this namespace has many
resources"), note them and proceed.

**NEEDS_CONTEXT:** The operator needs information that wasn't provided —
cluster context, credentials, environment details, or permission. Provide
the missing context and re-dispatch.

**BLOCKED:** The operator cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch on a more capable model
3. If the task is too large, break it into smaller pieces
4. If the operation requires human approval (e.g., production changes), escalate to the human — this is stop class 5, not a ruling
5. If the plan itself is wrong in a way no stop class covers, rule on the correction, ledger it, and re-dispatch with the ruling carried in the dispatch

**Never** ignore an escalation or force the same model to retry without
changes. If the operator said it's stuck, something needs to change.
