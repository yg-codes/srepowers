# Task Reviewer Prompt Template

Use this template when dispatching a task reviewer subagent for an
infrastructure operation. The reviewer reads the task's review package once and
returns two verdicts: **spec compliance** and **artifact quality**. One
reviewer, one diff read, both verdicts — a fix dispatch clears them together.

**Purpose:** Verify one operation task did exactly what was requested (nothing
more, nothing less) and produced well-built, safe artifacts (valid, clean,
reversible, evidence-backed).

This is a task-scoped gate, not the final merge review — a broad
whole-operation review runs separately after all tasks are complete (see
SKILL.md and the requesting-review-sre template).

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
         model silently inherits the session's most expensive one]
  prompt: |
    You are reviewing one operation task: first whether it matches its
    requirements, then whether the artifacts are well-built and safe. This is
    a task-scoped gate, not a merge review — a broad whole-operation review
    happens separately after all tasks are complete.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]

    Global constraints from the plan/spec that bind this task (exact values,
    formats, and stated relationships between components):
    [GLOBAL_CONSTRAINTS]

    ## What the Operator Claims They Executed

    Read the operator's report: [REPORT_FILE]

    ## Review Package Under Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Package file:** [DIFF_FILE]

    Read the review package once — it contains the commit list, a change-stat
    summary, and the full diff with surrounding context, and it is your view of
    the change. The diff's context lines ARE the changed files: do not Read a
    changed file separately unless a hunk you must judge is cut off
    mid-resource — and say so in your report. Use the recorded per-task BASE
    (never `HEAD~1`, which drops all but the last commit of a multi-commit
    task). Do not re-run git commands. If the package file is missing, fetch
    the diff yourself: `git diff --stat [BASE_SHA]..[HEAD_SHA]` and
    `git diff [BASE_SHA]..[HEAD_SHA]`.

    Do not crawl the broader infrastructure or codebase. Inspect artifacts
    outside the diff only to evaluate a concrete risk you can name — one
    focused check per named risk, and name both the risk and what you checked.
    Cross-cutting changes are legitimate named risks: if the diff changes a
    shared Hiera key, an RBAC binding, a network policy, or a value other
    manifests depend on, checking the consumers is the right method.

    Your review is read-only on this checkout. Do not mutate the working tree,
    the index, HEAD, branch state, or any live infrastructure in any way.

    ## Do Not Trust the Report

    Treat the operator's report as unverified claims. It may be incomplete,
    inaccurate, or optimistic. Verify the claims against the diff and the
    provided verification-command output. Design rationales in the report are
    claims too: "left it per YAGNI," "kept the default deliberately," or any
    other justification is the operator grading their own work. Judge the
    artifacts on their merits — a stated rationale never downgrades a finding's
    severity.

    ## Verification Commands

    The operator already ran the verification commands and reported results
    with evidence for exactly this change. Do not re-run the whole suite to
    confirm their report. Run a command only when reading the diff raises a
    specific doubt no existing run answers — and then a single focused,
    read-only check (a `--noop`/dry-run, a `kubectl get -o yaml`, a
    `named-checkzone`, a targeted API GET), never a live apply, a destructive
    action, or a broad sweep. If heavier validation seems warranted, recommend
    it in your report instead of running it. If you cannot run commands in this
    environment, name the command you would run and the state it would prove.

    Warnings or other noise in the operator's reported command output are
    findings — verification output should be pristine.

    ## Part 1: Spec Compliance

    Compare the diff against What Was Requested:

    - **Missing:** requirements they skipped, missed, or claimed without
      actually executing
    - **Extra:** operations, resources, or "nice to haves" that weren't
      requested; over-provisioning; scope creep
    - **Misunderstood:** right operation executed the wrong way, wrong problem
      solved, wrong environment/target

    If a requirement cannot be verified from this diff alone (it lives in
    unchanged config, live cluster/host state, or spans tasks), report it as a
    ⚠️ item instead of broadening your search — the controller will check it.

    ## Part 2: Artifact Quality

    **Correctness & safety:**
    - Valid syntax (YAML/JSON/HCL/Puppet/zone files parse)?
    - Idempotent and re-runnable? Verification checks real state, not side
      effects?
    - Is there a stated rollback path, and does the change preserve it?
    - Proper error handling / failure modes considered?

    **Infrastructure hygiene:**
    - No plaintext secrets, keys, or credentials in the diff?
    - Least-privilege (RBAC, IAM, firewall/network policy) — no broad grants?
    - Resource limits/requests, labels, and annotations present where the
      platform expects them?
    - Blast radius contained — no unintended cross-environment or
      cross-tenant reach?

    **Structure & maintainability:**
    - DRY without premature abstraction? No verbatim-duplicated blocks?
    - Each file/module one clear responsibility, following the plan's layout?
    - Clear, atomic commits with ticket-prefixed messages where required?
    - Did this change create already-large files or significantly grow
      existing ones? (Don't flag pre-existing sizes — focus on what this
      change contributed.)

    Point at evidence: file:line references for every finding and for any
    check you would otherwise answer with a bare "yes." A tight report that
    cites lines and command output gives the controller everything it needs.

    Your final message is the report itself: begin directly with the
    spec-compliance verdict. Every line is a verdict, a finding with
    file:line, or a check you ran — no preamble, no process narration, no
    closing summary.

    ## Calibration

    Categorize issues by actual severity. Not everything is Critical.
    Important means this task cannot be trusted until fixed: incorrect or
    fragile behavior, a missed requirement, a safety/security regression, or
    maintainability damage you would block a merge over — verbatim duplication
    of a logic block, swallowed errors, a verification that asserts nothing, a
    missing rollback path. "Coverage could be broader" and polish are Minor.
    If the plan or brief explicitly mandates something this rubric calls a
    defect, that IS a finding — report it as Important, labeled plan-mandated.
    The plan's authorship does not grade its own work; the human decides.
    Acknowledge what was done well before listing issues — accurate praise
    helps the operator trust the rest of the feedback.

    ## Output Format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood,
      with file:line references]
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]

    ### Strengths
    [What's well done? Be specific.]

    ### Issues

    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    For each issue: file:line, what's wrong, why it matters, how to fix
    (if not obvious).

    ### Assessment

    **Task quality:** [Approved | Needs fixes]

    **Reasoning:** [1-2 sentence technical assessment]
```

**Placeholders:**
- `[MODEL]` — REQUIRED: reviewer model per SKILL.md Model Selection
- `[BRIEF_FILE]` — REQUIRED: the task brief file (`scripts/task-brief PLAN N`
  prints the path; same file the operator worked from)
- `[GLOBAL_CONSTRAINTS]` — the binding requirements copied verbatim from the
  plan's Global Constraints section or the spec: exact values, formats, and
  stated relationships between components (not process rules — those are
  already in this template)
- `[REPORT_FILE]` — REQUIRED: the file the operator wrote its detailed report
  to
- `[BASE_SHA]` — commit before this task (the recorded per-task BASE)
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — REQUIRED: the review-package path the controller wrote
  (`scripts/review-package BASE HEAD` prints the unique path it wrote; the
  package never enters the controller's context)

**Reviewer returns:** Spec Compliance verdict (✅/❌/⚠️), Strengths, Issues
(Critical/Important/Minor), Task quality verdict.

A fix dispatch can address spec gaps and quality findings together; re-review
after fixes covers both verdicts.
