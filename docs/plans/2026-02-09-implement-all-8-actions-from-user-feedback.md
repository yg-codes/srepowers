# Implement All 8 Actions from User Feedback

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** Implement all 8 priority actions from user feedback to make SREPowers a standalone, comprehensive SRE operations skill plugin

**Architecture:** Replicate superpowers patterns (commands/, hooks/, tests/, meta-skill) adapted for infrastructure operations, with all SRE equivalents and full integration tests

**Tech Stack:** Bash scripts, YAML frontmatter, Markdown documentation, Claude Code CLI for testing

---

## Task 1: Fix Dangling Superpowers References

**Problem:** `skills/subagent-driven-operation/SKILL.md` contains references to `superpowers:test-driven-development` and `superpowers:verification-before-completion` which don't exist in SREPowers.

**Files:**
- Modify: `skills/subagent-driven-operation/SKILL.md`
- Modify: `skills/test-driven-operation/SKILL.md`

**Step 1: Read current SDO skill**

Read: `skills/subagent-driven-operation/SKILL.md`
Identify all references to `superpowers:` skills.

**Step 2: Replace with SRE equivalents**

Update all skill references:
- `superpowers:test-driven-development` → `srepowers:test-driven-operation`
- `superpowers:verification-before-completion` → [will create in Task 3]

**Step 3: Verify TDO skill consistency**

Read: `skills/test-driven-operation/SKILL.md`
Ensure no external superpowers references remain.

**Step 4: Commit**

```bash
git add skills/subagent-driven-operation/SKILL.md skills/test-driven-operation/SKILL.md
git commit -m "fix: replace superpowers references with srepowers equivalents"
```

---

## Task 2: Add Commands Directory with Thin Wrappers

**Files:**
- Create: `commands/test-driven-operation.md`
- Create: `commands/subagent-driven-operation.md`
- Modify: `README.md` (document commands usage)

**Step 1: Create commands directory**

```bash
mkdir -p commands
```

**Step 2: Create test-driven-operation command**

Create: `commands/test-driven-operation.md`

```markdown
---
description: "Use when executing infrastructure operations with verification commands - API calls, kubectl, Keycloak CRDs, Git MRs, Linux server operations"
disable-model-invocation: true
---

Invoke the srepowers:test-driven-operation skill and follow it exactly as presented to you
```

**Step 3: Create subagent-driven-operation command**

Create: `commands/subagent-driven-operation.md`

```markdown
---
description: "Execute infrastructure operation plans with independent tasks in the current session"
disable-model-invocation: true
---

Invoke the srepowers:subagent-driven-operation skill and follow it exactly as presented to you
```

**Step 4: Update README with commands section**

Add section after "Skills" section:

```markdown
## Commands

Quick invoke skills using `/command` syntax:

- `/test-driven-operation` - Execute operations with verification commands
- `/subagent-driven-operation` - Execute operation plans with subagent dispatch

Commands are thin wrappers that invoke skills directly.
```

**Step 5: Commit**

```bash
git add commands/ README.md
git commit -m "feat: add commands directory with thin skill wrappers"
```

---

## Task 3: Add Verification-Before-Completion Skill (SRE-Adapted)

**Files:**
- Create: `skills/verification-before-completion/SKILL.md`

**Step 1: Create skill directory**

```bash
mkdir -p skills/verification-before-completion
```

**Step 2: Write SRE-adapted VBC skill**

Create: `skills/verification-before-completion/SKILL.md`

Key adaptations from superpowers:
- Replace "tests pass" with "verification command passes"
- Replace "linter clean" with "infrastructure validation passes"
- Add infrastructure-specific examples:
  - `kubectl get pods -n namespace` (pod status)
  - `curl -f http://endpoint/health` (API health)
  - `git log --oneline origin/prod..HEAD` (commit verification)
  - `keycloakadm get users/count` (user count)
- Update claim patterns for operations:
  - "Deployment succeeded" requires pod health verification
  - "Configuration applied" requires diff verification
  - "Server provisioned" requires SSH access verification

**Step 3: Commit**

```bash
git add skills/verification-before-completion/SKILL.md
git commit -m "feat: add verification-before-completion skill (SRE-adapted)"
```

---

## Task 4: Add Basic Test Suite

**Files:**
- Create: `tests/claude-code/test-helpers.sh`
- Create: `tests/claude-code/run-skill-tests.sh`
- Create: `tests/claude-code/test-test-driven-operation.sh`
- Create: `tests/claude-code/test-subagent-driven-operation.sh`

**Step 1: Create tests directory structure**

```bash
mkdir -p tests/claude-code
```

**Step 2: Create test helpers (adapted from superpowers)**

Create: `tests/claude-code/test-helpers.sh`

Functions to include (copied from superpowers):
- `run_claude()` - Run Claude Code with prompt
- `assert_contains()` - Check pattern exists
- `assert_not_contains()` - Check pattern absent
- `assert_order()` - Check A appears before B
- `create_test_project()` - Create temp dir
- `cleanup_test_project()` - Remove temp dir

**Step 3: Create test runner**

Create: `tests/claude-code/run-skill-tests.sh`

Features (adapted from superpowers):
- `--verbose` flag for detailed output
- `--test NAME` for single test
- `--timeout SECONDS` for timeout control
- Track passed/failed/skipped counts
- Summary report

**Step 4: Create TDO skill test**

Create: `tests/claude-code/test-test-driven-operation.sh`

Tests:
1. Skill loading - skill recognized
2. RED phase - mentions writing verification first
3. GREEN phase - mentions execution after verification
4. REFACTOR phase - mentions documentation
5. TDO cycle order - RED→Verify→GREEN→Verify→REFACTOR

**Step 5: Create SDO skill test**

Create: `tests/claude-code/test-subagent-driven-operation.sh`

Tests:
1. Skill loading - skill recognized
2. Workflow order - spec compliance before artifact quality
3. Full task text - provides text directly
4. Review loops - mentions looping on issues
5. Self-review - operator self-review requirement

**Step 6: Make scripts executable**

```bash
chmod +x tests/claude-code/*.sh
```

**Step 7: Commit**

```bash
git add tests/
git commit -m "test: add basic test suite for TDO and SDO skills"
```

---

## Task 5: Add Using-SREPowers Meta-Skill + Hooks

**Files:**
- Create: `skills/using-srepowers/SKILL.md`
- Create: `hooks/hooks.json`
- Create: `hooks/session-start.sh`
- Modify: `.claude-plugin/plugin.json` (add hooks reference)

**Step 1: Create meta-skill directory**

```bash
mkdir -p skills/using-srepowers
```

**Step 2: Write using-srepowers skill**

Create: `skills/using-srepowers/SKILL.md`

Key sections (adapted from using-superpowers):
- **EXTREMELY-IMPORTANT** - Strong language about skill invocation
- **How to Access Skills** - Skill tool in Claude Code
- **The Rule** - Invoke relevant/requested skills BEFORE any response
- **Red Flags table** - Infrastructure operation rationalizations:
  - "This is just a quick server check"
  - "I'll verify after the operation"
  - "Manual verification is enough"
  - "Already checked the dashboard"
- **Skill Priority** - TDO before SDO
- **Skill Types** - Rigid (TDO) vs Flexible (SDO)

**Step 3: Create hooks directory**

```bash
mkdir -p hooks
```

**Step 4: Create hooks.json**

Create: `hooks/hooks.json`

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

**Step 5: Create session-start.sh**

Create: `hooks/session-start.sh`

Bash script that:
1. Determines plugin root directory
2. Reads `using-srepowers/SKILL.md` content
3. Escapes content for JSON (using bash parameter substitution)
4. Outputs context injection as JSON with `<EXTREMELY_IMPORTANT>` marker

**Step 6: Update plugin.json**

Add `"hooks": "hooks/hooks.json"` to plugin manifest.

**Step 7: Commit**

```bash
git add skills/using-srepowers/ hooks/ .claude-plugin/plugin.json
git commit -m "feat: add using-srepowers meta-skill with session-start hook"
```

---

## Task 6: Expand Rationalization Tables and "Why Order Matters"

**Files:**
- Modify: `skills/test-driven-operation/SKILL.md`
- Modify: `skills/subagent-driven-operation/SKILL.md`

**Step 1: Expand TDO rationalization table**

Add infrastructure-specific rationalizations:

| Excuse | Reality |
|--------|---------|
| "I'll verify after the operation" | Verification passing immediately proves nothing - could have been passing before |
| "Already manually checked the dashboard" | Ad-hoc ≠ systematic. No record, can't re-run, not reproducible |
| "This is just a quick server restart" | Quick operations fail too. Verification takes seconds, failures take hours |
| "Production is down, no time for verification" | Verification confirms fix works. Without it, you're guessing during emergency |
| "The script already has built-in checks" | Script output ≠ verification. You must read and confirm output |

**Step 2: Add TDO "Why Order Matters" section**

```markdown
## Why Order Matters

**RED before GREEN:**

Without verification first, you have no baseline. When GREEN fails, you don't know if:
- Your operation was wrong
- Your verification is wrong
- The system was already broken

**Verification after GREEN:**

Running verification after operation proves:
- System is in the expected state
- Verification command actually works
- You have evidence to share with team

**REFACTOR after both:**

Documentation and cleanup only make sense after:
- You know the operation works (GREEN)
- You know verification proves it (verified GREEN)
- You have evidence to document
```

**Step 3: Expand SDO rationalization table**

```markdown
| Excuse | Reality |
|--------|---------|
| "Spec reviewer can just read my report" | Reports are incomplete and optimistic. Code inspection required. |
| "I know what this task requires" | Knowing ≠ doing. Review catches missed requirements and over-building. |
| "Artifact quality review is enough" | Beautiful implementation of wrong requirements = failure. Spec first. |
| "Let me just fix this one thing" | Reviewer finds issues. Implementer fixes. Loop until approved. |
| "Reviews waste time" | Review loops prevent rework. One review cycle = faster than redirect. |

**Why Review Order Matters:**

**Spec compliance first:**
- Verifies correct thing was built
- Prevents "beautiful but wrong" implementations
- Artifact quality of wrong code = wasted effort

**Artifact quality second:**
- Only runs after spec confirmed
- Ensures correct thing is well-built
- Checks YAML/JSON syntax, labels, security

**Both reviews loop:**
- Implementer fixes issues
- Re-review until approval
- No "good enough" - approval required
```

**Step 4: Commit**

```bash
git add skills/test-driven-operation/SKILL.md skills/subagent-driven-operation/SKILL.md
git commit -m "docs: expand rationalization tables and add Why Order Matters sections"
```

---

## Task 7: Add Writing-Operation-Plans and Brainstorming-Operations Skills

**Files:**
- Create: `skills/writing-operation-plans/SKILL.md`
- Create: `skills/brainstorming-operations/SKILL.md`
- Create: `commands/writing-operation-plans.md`
- Create: `commands/brainstorming-operations.md`

**Step 1: Create brainstorming-operations skill**

Create: `skills/brainstorming-operations/SKILL.md`

Adapt from brainstorming skill:
- Focus on infrastructure operations instead of features
- Ask questions about:
  - Current infrastructure state
  - Operation scope and boundaries
  - Risk assessment and rollback plans
  - Verification commands available
  - Maintenance windows and constraints
- Save to: `docs/plans/YYYY-MM-DD-<operation-name>-design.md`

**Step 2: Create writing-operation-plans skill**

Create: `skills/writing-operation-plans/SKILL.md`

Adapt from writing-plans skill:
- Focus on infrastructure operation execution
- Each step is 2-5 minutes
- Include verification commands at each step
- Save to: `docs/plans/YYYY-MM-DD-<operation-name>.md`

Plan header:
```markdown
# [Operation Name] Execution Plan

> **For Claude:** REQUIRED SUB-SKILL: Use srepowers:subagent-driven-operation to implement this plan task-by-task.

**Goal:** [One sentence describing operation]
**Risk Level:** [Low/Medium/High with rationale]
**Rollback Plan:** [Brief rollback strategy]
**Verification Commands:** [List of commands that prove success]

---
```

**Step 3: Create command wrappers**

Create: `commands/brainstorming-operations.md`
Create: `commands/writing-operation-plans.md`

**Step 4: Update README**

Add new skills to "Skills" section.

**Step 5: Commit**

```bash
git add skills/writing-operation-plans/ skills/brainstorming-operations/ commands/ README.md
git commit -m "feat: add brainstorming-operations and writing-operation-plans skills"
```

---

## Task 8: Add Documentation Directory with Testing Methodology

**Files:**
- Create: `docs/testing-anti-patterns.md`
- Create: `docs/persuasion-principles.md`
- Modify: `README.md` (add docs section)

**Step 1: Create docs directory (if not exists)**

```bash
mkdir -p docs
```

**Step 2: Create testing-anti-patterns documentation**

Create: `docs/testing-anti-patterns.md`

Infrastructure operation testing pitfalls:
- Trusting "kubectl succeeded" without checking pod status
- Assuming API works without curl/health check
- Confirmed "MR created" without checking pipeline
- Manual verification as "good enough"
- Dashboard checks without command evidence
- Verification before operation (no baseline)

Each anti-pattern with:
- What it looks like
- Why it fails
- Correct approach (TDO)

**Step 3: Create persuasion-principles documentation**

Create: `docs/persuasion-principles.md`

Adapt from superpowers:
- Seven principles (Authority, Commitment, etc.)
- Authority + Commitment most effective for SRE discipline
- Infrastructure-specific examples:
  - "YOU MUST verify" (Authority)
  - "Announce: I'm using TDO" (Commitment)
- Ethical use guidelines

**Step 4: Update README with docs section**

```markdown
## Documentation

- [Testing Anti-Patterns](docs/testing-anti-patterns.md) - Common infrastructure operation testing pitfalls
- [Persuasion Principles](docs/persuasion-principles.md) - Psychology of effective skill design
- [Implementation Plan](docs/plans/2026-02-09-implement-all-8-actions-from-user-feedback.md) - This plan
```

**Step 5: Commit**

```bash
git add docs/ README.md
git commit -m "docs: add testing-anti-patterns and persuasion-principles documentation"
```

---

## Summary

This plan implements all 8 priority actions:

1. ✅ Fix dangling superpowers references (Task 1)
2. ✅ Add commands/ directory with thin wrappers (Task 2)
3. ✅ Add verification-before-completion skill (Task 3)
4. ✅ Add basic test suite (Task 4)
5. ✅ Add using-srepowers meta-skill + hooks (Task 5)
6. ✅ Expand rationalization tables and "Why Order Matters" (Task 6)
7. ✅ Add writing-operation-plans and brainstorming-operations (Task 7)
8. ✅ Add docs/ directory with testing methodology (Task 8)

**New skills added:** 4 (VBC, brainstorming-ops, writing-ops, using-srepowers)
**Total skill count:** 6 (TDO, SDO, VBC, brainstorming-ops, writing-ops, using-srepowers)
**Test coverage:** 2 skills (TDO, SDO) with unit tests
**Integration:** Hooks, commands, full test suite

**Execution Order:** Tasks are independent except where noted. Tasks 1-3 are foundational, 4-5 add integration, 6-8 add polish and completeness.
