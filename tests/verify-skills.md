# SREPowers Skills Verification Guide

## Test Commands for Each Skill

### 1. Test-Driven Operation (TDO)

```
# Test: Ask Claude to use TDO for a simple operation
"I need to create a Kubernetes ConfigMap in the production namespace. Use the test-driven-operation skill."

# Expected behavior:
# 1. Claude announces: "I'm using the test-driven-operation skill"
# 2. Writes RED verification command first
# 3. Runs verification and confirms it fails
# 4. Applies ConfigMap (GREEN)
# 5. Runs verification and confirms it passes
```

### 2. Subagent-Driven Operation (SDO)

```
# Test: Ask Claude to execute a plan with SDO
"I have an operation plan at docs/plans/test-plan.md. Use subagent-driven-operation to execute it."

# Expected behavior:
# 1. Claude announces: "I'm using the subagent-driven-operation skill"
# 2. Reads plan once, extracts all tasks
# 3. For each task:
#    - Dispatches operator subagent
#    - Executes operations with TDO
#    - Runs spec compliance review
#    - Runs artifact quality review
#    - Loops until approved
```

### 3. Verification Before Completion (VBC)

```
# Test: Claim completion without verification
"I just deployed the ConfigMap. It's definitely working."

# Expected behavior:
# 1. Claude invokes verification-before-completion skill
# 2. Asks for verification command
# 3. Runs command and shows evidence
# 4. Only then allows claim
```

### 4. Brainstorming Operations

```
# Test: Plan a new operation
"I need to migrate our Keycloak setup to use CRDs. Use brainstorming-operations to design this."

# Expected behavior:
# 1. Claude announces: "I'm using the brainstorming-operations skill"
# 2. Asks questions one at a time about:
#    - Current infrastructure state
#    - Desired state
#    - Risk level
#    - Rollback strategy
# 3. Presents design in sections for validation
# 4. Saves design to docs/plans/YYYY-MM-DD-*.md
```

### 5. Writing Operation Plans

```
# Test: Create an execution plan
"Create an execution plan for deploying nginx to production with 3 replicas. Use writing-operation-plans."

# Expected behavior:
# 1. Claude announces: "I'm using the writing-operation-plans skill"
# 2. Creates detailed plan with:
#    - Exact verification commands
#    - Expected outputs
#    - Rollback steps
#    - TDO discipline for each task
# 3. Saves to docs/plans/YYYY-MM-DD-*.md
```

### 6. Using-SREPowers (Meta-Skill)

```
# Test: Start a new session
# The meta-skill should auto-inject via hooks

# Expected behavior:
# 1. Session-start hook runs
# 2. using-srepowers content injected as context
# 3. Claude knows about all SRE skills
# 4. Red flags table available for reference
```

## Command Wrappers Test

```bash
# Test each /command
claude -p "/test-driven-operation"
claude -p "/subagent-driven-operation"
claude -p "/brainstorming-operations"
claude -p "/writing-operation-plans"

# Each should invoke the corresponding skill
```

## Infrastructure-Specific Verification Tests

### Kubernetes Test
```
"Use test-driven-operation to deploy a nginx pod with label app=nginx in the default namespace."
```

### API Test
```
"Use test-driven-operation to make a GET request to https://api.github.com and verify it returns JSON."
```

### Git Test
```
"Use test-driven-operation to create a new branch called test_branch."
```

## Common Issues to Check

1. **Skills don't load:**
   - Check you're running from srepowers directory
   - Verify plugin is in `~/.claude/plugins/`
   - Check `~/.claude/settings.json` has plugin enabled

2. **Hooks don't fire:**
   - Check `hooks/hooks.json` exists
   - Verify `session-start.sh` is executable
   - Check Claude Code version supports hooks

3. **Tests fail:**
   - Ensure Claude Code CLI is installed
   - Check network connectivity
   - Run with `--verbose` flag for details

## Full Test Session Example

```bash
# 1. Clone/fresh checkout
cd /tmp
git clone https://github.com/yg-codes/srepowers.git
cd srepowers

# 2. Run test suite
./tests/claude-code/run-skill-tests.sh --verbose

# 3. Start interactive session
claude

# 4. In Claude, test each skill:
# - "List all srepowers skills"
# - "Use test-driven-operation to create a ConfigMap"
# - "Use brainstorming-operations to plan a deployment"
# - etc.

# 5. Check hooks fired
# (using-srepowers should be in context automatically)
```

## Success Criteria

✅ All tests pass: `./tests/claude-code/run-skill-tests.sh`
✅ Skills load when prompted
✅ Commands invoke correct skills
✅ Hooks inject meta-skill on session start
✅ Each skill demonstrates its workflow correctly
