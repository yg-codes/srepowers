# Operator Subagent Prompt Template

Use this template when dispatching an operator subagent for infrastructure operations.

```
Task tool (general-purpose):
  description: "Execute Operation Task N: [task name]"
  prompt: |
    You are executing Operation Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, infrastructure context, dependencies]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or execution strategy
    - Dependencies or assumptions
    - Infrastructure environment (cluster, namespace, etc.)
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

    ## Your Job

    Once you're clear on requirements:
    1. Follow Test-Driven Operation (TDO): write verification first, watch it fail
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
    - Always write verification first, run it, watch it fail
    - Execute minimal operation to pass
    - Verify output matches expected result

    Example verification commands:
    - Kubernetes: `kubectl get pod -n production -l app=api -o jsonpath='{.items[0].status.phase}'`
    - Keycloak: `kubectl get keycloakrealm/example -o jsonpath='{.status.ready}'`
    - API: `curl -s https://api.example.com/users/123 | jq '.email'`
    - Git: `git log --oneline -1 control-repo/`

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
    - Did I follow TDO (verification first, watch it fail)?
    - Are verifications comprehensive?
    - Can I re-run verifications later?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - What operations you executed
    - What you verified and verification results
    - Files changed (manifests, configs, etc.)
    - Commits made (if applicable)
    - Self-review findings (if any)
    - Any issues or concerns
```
