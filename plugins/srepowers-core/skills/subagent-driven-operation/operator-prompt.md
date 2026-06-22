# Operator Subagent Prompt Template

Use this template when dispatching an operator subagent for infrastructure operations.

**File handoffs (not pasted text):** Hand the operator its requirements as a
**brief file**, not pasted plan text. Run this skill's
`scripts/task-brief PLAN_FILE N` (it prints the brief path), and have the
operator write its full report to a **report file** named after the brief
(`…/task-N-brief.md` → `…/task-N-report.md`). Bulk text moving as files keeps
it out of your controller context. Without bash (e.g. some Codex setups),
write the brief file by hand from the plan's Task N section.

```
Task tool (general-purpose):
  description: "Execute Operation Task N: [task name]"
  prompt: |
    You are executing Operation Task N: [task name]

    ## Your Requirements (read this first)

    Read `[.srepowers/sdd/task-N-brief.md]` — it is your requirements, with the
    exact values (names, namespaces, commands) to use verbatim. It is the single
    source of truth for what this task must accomplish.

    ## Context

    [Scene-setting: where this fits, infrastructure context, dependencies.
    Include interfaces/decisions from earlier tasks the brief cannot know —
    exact resource names or output values produced by prior tasks — and your
    resolution of any ambiguity you noticed in the brief.]

    ## Report File

    Write your full report (operations executed, evidence, files, commits,
    self-review findings, concerns) to `[.srepowers/sdd/task-N-report.md]`.
    Return only: status, commits, a one-line verification summary, and concerns.

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or execution strategy
    - Dependencies or assumptions
    - Infrastructure environment (cluster, namespace, etc.)
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    ## Contract

    Exact scope:
    - [One task or one task segment only]

    Input artifacts:
    - [Brief file path — your requirements]
    - [Relevant files or paths]
    - [Verification commands]
    - [Rollback commands]
    - [Report file path — where you write your full report]

    Allowed tools/commands:
    - [List only what this operator should use]

    Output boundary:
    - Report only on this assigned scope
    - Do NOT claim the whole operation is complete
    - Do NOT make architectural decisions outside the assigned task

    Once you're clear on requirements:
    1. Follow Test-Driven Operation (TDO): define verification first; watch it fail when target state is absent or broken, or capture baseline when failure is not meaningful
    2. Execute minimal infrastructure operation to pass verification
    3. Verify operation succeeded
    4. Commit to control repo (if applicable)
    5. Self-review (see below)
    6. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Test-Driven Operation Guidelines

    For infrastructure operations:
    - **Tests** = Verification commands (kubectl, API calls, Git queries)
    - **Commits** = Git operations on control repo
    - Always define verification first
    - Run it before the operation and watch it fail when the target state is absent or broken
    - Capture baseline first when failure is not meaningful
    - Execute minimal operation to pass
    - Verify output matches expected result

    Example verification commands:
    - Kubernetes: `kubectl get pod -n production -l app=api -o jsonpath='{.items[0].status.phase}'`
    - Keycloak: `kubectl get keycloakrealm/example -o jsonpath='{.status.ready}'`
    - API: `curl -s https://api.example.com/users/123 | jq '.email'`
    - Git: `git log --oneline -1 control-repo/`
    - SSH/Puppet: `ssh host "puppet resource file /etc/app/config.yaml" 2>&1`
    - SSH/PVE: `ssh host "pvecm status" | grep Quorum`
    - SSH/Service: `ssh host "systemctl is-active nginx"`

    ## Deviation Handling

    When you encounter unexpected situations, classify and respond:

    | Rule | Type | Action | Max Retries |
    |------|------|--------|-------------|
    | **R1 - Minor bug** | Auto-fix | Fix, re-verify, continue | 3 |
    | **R2 - Missing info** | Auto-resolve | Read adjacent files, infer, continue | 3 |
    | **R3 - Verification drift** | Auto-adapt | Adjust expected output, re-verify | 3 |
    | **R4 - Scope/arch change** | **STOP** | Report to human, await approval | N/A |

    **R1 examples:** Typo in label, wrong namespace in YAML field, missing annotation
    **R2 examples:** Missing port number, unclear annotation value, ambiguous config key
    **R3 examples:** Pod name includes random suffix, output format differs slightly, timing values
    **R4 examples:** Need different resource type (Deployment vs StatefulSet), API version incompatible, requires additional infrastructure not in plan

    **Scope boundary:** Do NOT auto-fix pre-existing issues unrelated to your assigned task. If an unrelated issue blocks you, report as R4.

    **After 3 failed retries on R1-R3:** Escalate to R4. Report what you tried, what failed, and what you think is needed.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully execute everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?
    - Did I verify all operations succeeded?

    **Quality:**
    - Is this my best work?
    - Are YAML/JSON files valid?
    - Are resource names clear and accurate?
    - Are labels/annotations appropriate?
    - Is the infrastructure artifact maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only execute what was requested?
    - Did I follow existing infrastructure patterns?
    - Did I write verification before operation?

    **Verification:**
    - Do verifications actually check infrastructure state?
    - Did I follow TDO (verification or baseline before operation)?
    - Are verifications comprehensive?
    - Can I re-run verifications later?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    Write the FULL report to your report file:
    - Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
    - Scope completed: [exact task or segment]
    - Operations executed
    - Evidence: verification commands run and outputs observed
    - Files changed (manifests, configs, etc.)
    - Commits made (if applicable)
    - Self-review findings (if any)
    - Open issues or concerns

    Return to the controller only: status, commits (short SHAs), a one-line
    verification summary, and concerns. The report file carries the detail.
```
