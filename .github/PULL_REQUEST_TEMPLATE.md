<!--
BEFORE SUBMITTING: Read every word of this template. PRs that leave
sections blank, contain multiple unrelated changes, or show no evidence
of human involvement will be closed without review.
-->

> **Target `main` from a topic branch.** Do not commit to `main` directly.
> Branch, open a PR, and let CI (`.github/workflows/validate.yml`) run.

## Who is submitting this PR? (required)
<!-- Required. PRs that omit this will be closed. We assume an agent wrote
     this PR — tell us which one and where it ran. We weigh contributions by
     what produced them: content reasoned from documentation is held to a
     different bar than work grounded in a real session. -->

| Field | Value |
|-------|-------|
| Your model + version | |
| Harness + version | |
| All plugins installed | |
| Human partner who reviewed this diff | |

## What problem are you trying to solve?
<!-- Describe the specific problem you encountered. If this was a session
     issue, include: what you were doing, what went wrong, the model's
     exact failure mode, and ideally a transcript or session log.

     "Improving" something is not a problem statement. What broke? What
     failed? What was the user experience that motivated this? -->

## What does this PR change?
<!-- 1-3 sentences. What, not why — the "why" belongs above. -->

## Is this change appropriate for the core library?
<!-- SREPowers core contains general-purpose skills and infrastructure
     that benefit all users. Ask yourself:

     - Would this be useful to someone working on a completely different
       kind of project than yours?
     - Is this project-specific, team-specific, or tool-specific?
     - Does this integrate or promote a third-party service?

     If your change is a new skill for a specific domain, workflow tool,
     or third-party integration, it belongs in its own plugin — not here.
     See the plugin development docs for how to publish it separately. -->

## What alternatives did you consider?
<!-- What other approaches did you try or evaluate before landing on this
     one? Why were they worse? If you didn't consider alternatives, say so
     — but know that's a red flag. -->

## Does this PR contain multiple unrelated changes?
<!-- If yes: stop. Split it into separate PRs. Bundled PRs will be closed.
     If you believe the changes are related, explain the dependency. -->

## Existing PRs
- [ ] I have reviewed all open AND closed PRs for duplicates or prior art
- Related PRs: <!-- #number, #number, or "none found" -->

<!-- If a related closed PR exists, explain what's different about your
     approach and why it should succeed where the other didn't. -->

## Environment tested

| Runtime (Claude Code / Codex) | Runtime version | Model | Model version/ID |
|-------------------------------|-----------------|-------|------------------|
|                               |                 |       |                  |

## Repo invariants

<!-- CI runs these. Run them locally first — a red CI run costs a review cycle. -->

- [ ] `python3 scripts/validate-repo.py` passes
- [ ] `bash scripts/lint-shell.sh --strict` passes
- [ ] `bash tests/hooks/test-session-start.sh` passes
- [ ] `bash tests/codex/run-skill-tests.sh` passes
- [ ] If this adds a skill: command wrapper, both mirror symlinks, and the
      README count are updated (the validator enforces all four)

## Runtime support (required if this PR changes the bootstrap or adds a runtime)

<!-- SREPowers targets Claude Code and Codex. If this PR touches the
     SessionStart hook, the plugin manifests, or adds a new runtime, you
     MUST include a session transcript proving the bootstrap still works.

     A working integration loads the `using-srepowers` bootstrap at session
     start. The bootstrap is what causes skills to auto-trigger. Without it,
     the skills are dead weight — present on disk but never invoked at the
     right moments.

     ACCEPTANCE TEST: open a clean session and send exactly this message:

         Roll out a config change to the uat rsyslog hosts

     A working integration auto-triggers the SRE workflow router — the
     session should route to brainstorming/planning and raise verification
     and rollback before any command is proposed. Paste the transcript below.

     These are NOT real integrations and PRs that ship them will be closed:

     - Manually copying skill files into the runtime
     - At-runtime shims that require per-session opt-in
     - Anything where the router does not auto-trigger on the test above
-->

<details>
<summary>Clean-session transcript for the acceptance test</summary>

```
paste the complete transcript here
```

</details>

## Evaluation
- What was the initial prompt you (or your human partner) used to start
  the session that led to this change?
- How many eval sessions did you run AFTER making the change?
- How did outcomes change compared to before the change?

<!-- "It works" is not evaluation. Describe the before/after difference
     you observed across multiple sessions. -->

## Rigor

- [ ] If this is a skills change: I used `srepowers-core:writing-skills-sre` and
      completed adversarial pressure testing (paste results below)
- [ ] This change was tested adversarially, not just on the happy path
- [ ] I did not modify carefully-tuned content (Red Flags table,
      rationalizations, "human partner" language) without extensive evals
      showing the change is an improvement

<!-- If you changed wording in skills that shape agent behavior, show your
     eval methodology and results. These are not prose — they are code. -->

## Human review
- [ ] A human has reviewed the COMPLETE proposed diff before submission

<!--
STOP. If the checkbox above is not checked, do not submit this PR.

PRs will be closed without review if they:
- Show no evidence of human involvement
- Contain multiple unrelated changes
- Promote or integrate third-party services or tools
- Submit project-specific or personal configuration as core changes
- Leave required sections blank or use placeholder text
- Modify behavior-shaping content without eval evidence
-->
