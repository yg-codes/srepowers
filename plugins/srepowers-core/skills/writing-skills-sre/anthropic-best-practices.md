# Skill authoring best practices

> Learn how to write effective Skills that agents can discover and use successfully.

Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that agents can discover and use effectively.

This is Anthropic's official skill-authoring guidance, lightly recast for an SRE/infrastructure audience. It complements the TDD-focused approach in `SKILL.md`. For conceptual background on how Skills work, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).

## Core principles

### Concise is key

The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else your agent needs to know, including:

* The system prompt
* Conversation history
* Other Skills' metadata
* Your actual request

Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Agents read SKILL.md only when the Skill becomes relevant, and read additional files only as needed. However, being concise in SKILL.md still matters: once an agent loads it, every token competes with conversation history and other context.

**Default assumption**: Agents are already very smart

Only add context agents don't already have. Challenge each piece of information:

* "Does the agent really need this explanation?"
* "Can I assume the agent knows this?"
* "Does this paragraph justify its token cost?"

**Good example: Concise** (approximately 50 tokens):

````markdown
## Drain a node

Cordon then drain before maintenance:

```bash
kubectl --context="$CTX" cordon "$NODE"
kubectl --context="$CTX" drain "$NODE" --ignore-daemonsets --delete-emptydir-data
```
````

**Bad example: Too verbose** (approximately 150 tokens):

```markdown
## Drain a node

A Kubernetes node is a worker machine that runs pods. Before you perform
maintenance on a node, you need to safely evict the workloads running on it.
There are several ways to do this, but the recommended approach is to first
cordon the node so the scheduler stops placing new pods on it, and then drain
it to evict the existing pods. First, you'll need to identify the node name...
```

The concise version assumes the agent knows what a node is and why you cordon before draining.

### Set appropriate degrees of freedom

Match the level of specificity to the task's fragility and variability.

**High freedom** (text-based instructions):

Use when:

* Multiple approaches are valid
* Decisions depend on context
* Heuristics guide the approach

Example:

```markdown
## Incident triage process

1. Establish the blast radius (which services, which regions)
2. Check recent changes (deploys, config, feature flags)
3. Correlate against dashboards and alerts
4. Form a hypothesis, then verify before acting
```

**Medium freedom** (pseudocode or scripts with parameters):

Use when:

* A preferred pattern exists
* Some variation is acceptable
* Configuration affects behavior

Example:

````markdown
## Roll out a change

Use this pattern and customize the batch size:

```bash
rollout(env, batch_size=1, wait_seconds=60):
    # apply to one batch of hosts
    # verify health after each batch
    # halt on first failed health check
```
````

**Low freedom** (specific scripts, few or no parameters):

Use when:

* Operations are fragile and error-prone
* Consistency is critical
* A specific sequence must be followed

Example:

````markdown
## Puppet apply on production

Run exactly this sequence:

```bash
sudo ppr --environment infra_prod            # noop first
sudo ppr --no-noop --environment infra_prod  # apply only after noop is clean
```

Do not skip the noop, and do not reorder the steps.
````

**Analogy**: Think of the agent as a robot exploring a path:

* **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: a production apply that must run noop-then-apply in exact sequence.
* **Open field with no hazards**: Many paths lead to success. Give general direction and trust the agent to find the best route (high freedom). Example: incident triage where context determines the best approach.

### Test with all models you plan to use

Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the models you plan to use it with.

**Testing considerations by model**:

* **Claude Haiku** (fast, economical): Does the Skill provide enough guidance?
* **Claude Sonnet** (balanced): Is the Skill clear and efficient?
* **Claude Opus** (powerful reasoning): Does the Skill avoid over-explaining?

What works perfectly for Opus might need more detail for Haiku. If you plan to use your Skill across multiple models — and across runtimes like Claude Code and Codex — aim for instructions that work well with all of them.

## Skill structure

> **YAML Frontmatter**: The SKILL.md frontmatter requires two fields:
>
> * `name` - Human-readable name of the Skill (64 characters maximum); must match the skill's directory name
> * `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)

### Naming conventions

Use consistent naming patterns to make Skills easier to reference and discuss. We recommend using **gerund form** (verb + -ing) for Skill names, as this clearly describes the activity or capability the Skill provides.

**Good naming examples (gerund form)**:

* "Writing operation plans"
* "Analyzing packet captures"
* "Managing certificates"
* "Testing skills"
* "Debugging Hiera"

**Acceptable alternatives**:

* Noun phrases: "DNS operations", "Change management"
* Action-oriented: "Deploy Puppet", "Inspect an AWS account"

**Avoid**:

* Vague names: "Helper", "Utils", "Tools"
* Overly generic: "Infra", "Ops", "Files"
* Inconsistent patterns within your skill collection

Consistent naming makes it easier to:

* Reference Skills in documentation and conversations
* Understand what a Skill does at a glance
* Organize and search through multiple Skills
* Maintain a professional, cohesive skill library

### Writing effective descriptions

The `description` field enables Skill discovery and should include both what the Skill does and when to use it.

> **Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems.
>
> * **Good:** "Analyzes packet captures and generates a findings report"
> * **Avoid:** "I can help you analyze packet captures"
> * **Avoid:** "You can use this to analyze packet captures"

**Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.

Each Skill has exactly one description field. The description is critical for skill selection: agents use it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for an agent to know when to select this Skill, while the rest of SKILL.md provides the implementation details.

Effective examples:

**pcap analysis skill:**

```yaml
description: Use when analyzing network packet capture files (.pcap, .pcapng) for DNS errors, TCP connection failures, or HTTP proxy issues using tshark on the local workstation.
```

**Puppet deploy skill:**

```yaml
description: Use when deploying Puppet environments to hosts — running noop, validating Hiera, applying with ppr, and classifying exit codes. Triggers on ppr, g10k, noop, apply, puppet agent.
```

**Certificate management skill:**

```yaml
description: Use when issuing, renewing, or rotating TLS certificates, debugging TLS handshake failures, or checking certificate expiration. Triggers on cert-manager, openssl, CSR, x509, certificate chain.
```

Avoid vague descriptions like these:

```yaml
description: Helps with infrastructure
```

```yaml
description: Processes data
```

```yaml
description: Does stuff with servers
```

### Progressive disclosure patterns

SKILL.md serves as an overview that points agents to detailed materials as needed, like a table of contents in an onboarding guide.

**Practical guidance:**

* Keep SKILL.md body under 500 lines for optimal performance
* Split content into separate files when approaching this limit
* Use the patterns below to organize instructions, code, and resources effectively

A basic Skill starts with just a SKILL.md file containing metadata and instructions. As your Skill grows, you can bundle additional content that agents load only when needed. The complete Skill directory structure might look like this:

```
puppet-deploy/
├── SKILL.md              # Main instructions (loaded when triggered)
├── EXIT-CODES.md         # Exit-code decision table (loaded as needed)
├── reference.md          # g10k / environment reference (loaded as needed)
├── examples.md           # Worked deploy examples (loaded as needed)
└── scripts/
    ├── classify_run.sh   # Utility script (executed, not loaded)
    ├── check_env.sh      # Environment verification script
    └── validate.sh       # Validation script
```

#### Pattern 1: High-level guide with references

````markdown
---
name: puppet-deploy
description: Use when deploying Puppet environments to hosts with noop, validation, apply, and exit-code classification.
---

# Puppet Deploy

## Quick start

Noop then apply on a single host:
```bash
ssh "$HOST" 'sudo ppr --environment infra_sit'
ssh "$HOST" 'sudo ppr --no-noop --environment infra_sit'
```

## Advanced features

**Exit-code classification**: See [EXIT-CODES.md](EXIT-CODES.md) for the decision rule
**Environment reference**: See [reference.md](reference.md) for g10k and prefixes
**Examples**: See [examples.md](examples.md) for multi-host patterns
````

Agents load EXIT-CODES.md, reference.md, or examples.md only when needed.

#### Pattern 2: Domain-specific organization

For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about a DNS record, the agent only needs to read the DNS reference, not the backup or certificate references. This keeps token usage low and context focused.

```
infra-reference-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── dns.md (BIND zones, record types)
    ├── backup.md (ZFS snapshots, PBS jobs)
    ├── certs.md (PKI, cert-manager)
    └── network.md (VLANs, routing)
```

````markdown SKILL.md
# Infrastructure Reference

## Available domains

**DNS**: BIND zones, records, reverse DNS → See [reference/dns.md](reference/dns.md)
**Backup**: ZFS, PBS, restore tests → See [reference/backup.md](reference/backup.md)
**Certificates**: PKI, cert-manager → See [reference/certs.md](reference/certs.md)
**Network**: VLANs, routing → See [reference/network.md](reference/network.md)

## Quick search

Find specific procedures using grep:

```bash
grep -i "reverse dns" reference/dns.md
grep -i "restore" reference/backup.md
grep -i "handshake" reference/certs.md
```
````

#### Pattern 3: Conditional details

Show basic content, link to advanced content:

```markdown
# Certificate Management

## Issuing certificates

Use cert-manager for Kubernetes workloads. See [CERT-MANAGER.md](CERT-MANAGER.md).

## Renewing certificates

For manual renewals, follow the CSR workflow.

**For internal CA operations**: See [INTERNAL-CA.md](INTERNAL-CA.md)
**For handshake debugging**: See [TLS-DEBUG.md](TLS-DEBUG.md)
```

Agents read INTERNAL-CA.md or TLS-DEBUG.md only when the user needs those features.

### Avoid deeply nested references

Agents may partially read files when they're referenced from other referenced files. When encountering nested references, an agent might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.

**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure agents read complete files when needed.

**Bad example: Too deep**:

```markdown
# SKILL.md
See [advanced.md](advanced.md)...

# advanced.md
See [details.md](details.md)...

# details.md
Here's the actual information...
```

**Good example: One level deep**:

```markdown
# SKILL.md

**Basic usage**: [instructions in SKILL.md]
**Advanced features**: See [advanced.md](advanced.md)
**Reference**: See [reference.md](reference.md)
**Examples**: See [examples.md](examples.md)
```

### Structure longer reference files with table of contents

For reference files longer than 100 lines, include a table of contents at the top. This ensures agents can see the full scope of available information even when previewing with partial reads.

**Example**:

```markdown
# Puppet Environment Reference

## Contents
- Environment naming and prefixes
- g10k deployment and verification
- ppr behavior and exit codes
- Multi-host patterns
- Rollback procedures

## Environment naming and prefixes
...

## g10k deployment and verification
...
```

Agents can then read the complete file or jump to specific sections as needed.

## Workflows and feedback loops

### Use workflows for complex tasks

Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that the agent can copy into its response and check off as it progresses.

**Example 1: Post-incident synthesis workflow** (for Skills without code):

````markdown
## Post-incident synthesis workflow

Copy this checklist and track your progress:

```
Post-Mortem Progress:
- [ ] Step 1: Assemble the timeline from logs and alerts
- [ ] Step 2: Identify the trigger and the root cause
- [ ] Step 3: Cross-reference contributing factors
- [ ] Step 4: Draft the blameless narrative
- [ ] Step 5: Verify action items are owned and dated
```

**Step 1: Assemble the timeline**

Pull events from monitoring, deploy logs, and chat. Note the first
symptom, the first alert, and the mitigation time.

**Step 2: Identify the trigger and root cause**

Distinguish the change that triggered the incident from the latent
condition that made it possible.

**Step 3: Cross-reference contributing factors**

For each contributing factor, cite the evidence (a log line, a metric).

**Step 4: Draft the blameless narrative**

Organize by timeline. Describe systems and decisions, not individuals.

**Step 5: Verify action items**

Each action item has an owner and a due date. If any is unowned,
return to Step 4.
````

This example shows how workflows apply to analysis tasks that don't require code. The checklist pattern works for any complex, multi-step process.

**Example 2: Puppet deploy workflow** (for Skills with code):

````markdown
## Puppet deploy workflow

Copy this checklist and check off items as you complete them:

```
Deploy Progress:
- [ ] Step 1: Verify the environment on the puppet master
- [ ] Step 2: Validate Hiera resolution for the target node
- [ ] Step 3: Run noop (dry run)
- [ ] Step 4: Review noop output and logs
- [ ] Step 5: Apply with --no-noop
- [ ] Step 6: Post-apply check with pplog
```

**Step 1: Verify the environment**

Run: `ssh master "cat /etc/puppetlabs/code/environments/$ENV/.g10k-deploy.json"`

**Step 2: Validate Hiera**

Run: `ssh master "sudo puppet lookup --environment $ENV --node $NODE $KEY"`

**Step 3: Run noop**

Run: `ssh "$HOST" 'sudo ppr --environment infra_sit'`

**Step 4: Review noop output**

Check for compilation errors and previewed changes. Do not proceed if
noop shows errors.

**Step 5: Apply**

Run: `ssh "$HOST" 'sudo ppr --no-noop --environment infra_sit'`

**Step 6: Verify output**

Run: `ssh "$HOST" 'sudo pplog'`

If verification fails, investigate before declaring success.
````

Clear steps prevent agents from skipping critical validation. The checklist helps both you and the agent track progress through multi-step workflows.

### Implement feedback loops

**Common pattern**: Run validator → fix errors → repeat

This pattern greatly improves output quality.

**Example 1: Runbook style compliance** (for Skills without code):

```markdown
## Runbook review process

1. Draft the runbook following the guidelines in STYLE_GUIDE.md
2. Review against the checklist:
   - Every command is copy-pasteable with variables defined
   - Every step has a verification
   - A rollback path exists for each mutating step
3. If issues found:
   - Note each issue with a specific step reference
   - Revise the runbook
   - Review the checklist again
4. Only proceed when all requirements are met
5. Finalize and commit the runbook
```

The "validator" is STYLE_GUIDE.md, and the agent performs the check by reading and comparing.

**Example 2: Manifest validation process** (for Skills with code):

```markdown
## Manifest editing process

1. Make your edits to the Puppet manifest
2. **Validate immediately**: `puppet parser validate manifests/`
3. If validation fails:
   - Read the error message carefully
   - Fix the manifest
   - Run validation again
4. **Only proceed when validation passes**
5. Run noop against a test node
6. Review the previewed catalog changes
```

The validation loop catches errors early.

## Content guidelines

### Avoid time-sensitive information

Don't include information that will become outdated:

**Bad example: Time-sensitive** (will become wrong):

```markdown
If you're doing this before August 2025, use the old g10k path.
After August 2025, use the new path.
```

**Good example** (use "old patterns" section):

```markdown
## Current method

Use the canonical g10k path: `/opt/puppetlabs/puppet/bin/g10k`

## Old patterns

<details>
<summary>Legacy g10k path (deprecated)</summary>

Older notes referenced `/usr/local/bin/g10k`. This still exists as a
symlink, but prefer the canonical path in new commands.

</details>
```

The old patterns section provides historical context without cluttering the main content.

### Use consistent terminology

Choose one term and use it throughout the Skill:

**Good - Consistent**:

* Always "environment"
* Always "noop"
* Always "apply"

**Bad - Inconsistent**:

* Mix "environment", "env", "branch env", "deploy target"
* Mix "noop", "dry run", "preview", "plan"
* Mix "apply", "run", "deploy", "push"

Consistency helps agents understand and follow instructions.

## Common patterns

### Template pattern

Provide templates for output format. Match the level of strictness to your needs.

**For strict requirements** (like change records or status reports):

````markdown
## Change record structure

ALWAYS use this exact template structure:

```markdown
# [Change Title]

## Description
[What is changing and why]

## Blast radius
[Hosts, services, customers affected]

## Rollback
[Exact commands to undo]

## Verification
[How success is confirmed]
```
````

**For flexible guidance** (when adaptation is useful):

````markdown
## Findings report structure

Here is a sensible default format, but use your best judgment:

```markdown
# [Investigation Title]

## Observed
[What the evidence shows]

## Inferred
[What we conclude, with confidence level]

## Recommendations
[Tailored to the specific incident]
```

Adjust sections as needed for the specific investigation type.
````

### Examples pattern

For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular prompting:

````markdown
## Commit message format

Generate commit messages following these examples:

**Example 1:**
Input: Added a Wazuh agent class to the rsyslog profile
Output:
```
INFRA-1234: Add Wazuh agent to rsyslog profile

Include the fsx_wazuh::agent class and pin the manager address in Hiera
```

**Example 2:**
Input: Fixed a Hiera key that resolved to the wrong environment
Output:
```
INFRA-1290: Fix rsyslog instance key resolving to wrong env

Quote the interpolated value so %{} resolves per-environment
```

Follow this style: TICKET-ID: brief description, then detailed explanation.
````

Examples help agents understand the desired style and level of detail more clearly than descriptions alone.

### Conditional workflow pattern

Guide agents through decision points:

```markdown
## Deploy workflow

1. Determine the target:

   **Validating an unmerged branch?** → Environment is <source>_<branch>
   **Deploying to a standard env?** → Derive from the hostname prefix

2. Branch workflow:
   - Environment name is the branch name
   - Pin the control repo to :branch during iteration

3. Standard workflow:
   - fsx-* → infra_*, jax-* → jax_*, pve* → proxmox_*
   - Run noop, validate, apply, post-check
```

## Evaluation and iteration

### Build evaluations first

**Create evaluations BEFORE writing extensive documentation.** This ensures your Skill solves real problems rather than documenting imagined ones.

**Evaluation-driven development:**

1. **Identify gaps**: Run your agent on representative infrastructure tasks without a Skill. Document specific failures or missing context
2. **Create evaluations**: Build three scenarios that test these gaps
3. **Establish baseline**: Measure the agent's performance without the Skill
4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations
5. **Iterate**: Execute evaluations, compare against baseline, and refine

This approach ensures you're solving actual problems rather than anticipating requirements that may never materialize.

**Evaluation structure**:

```json
{
  "skills": ["puppet-deploy"],
  "query": "Deploy the infra_sit environment to fsx-sit-rsyslog01 and confirm it applied cleanly",
  "expected_behavior": [
    "Runs a noop (dry run) before any real apply",
    "Reviews noop output for compilation errors before proceeding",
    "Applies with --no-noop only after the noop is clean",
    "Classifies the run by inspecting log bodies, not the exit code alone"
  ]
}
```

> This example demonstrates a data-driven evaluation with a simple testing rubric. Evaluations are your source of truth for measuring Skill effectiveness. For infrastructure discipline skills, the pressure-scenario methodology in `testing-skills-with-subagents.md` is the primary gate.

### Develop Skills iteratively with the agent

The most effective Skill development process involves the agent itself. Work with one instance ("Agent A") to create a Skill that will be used by other instances ("Agent B"). Agent A helps you design and refine instructions, while Agent B tests them in real tasks.

**Creating a new Skill:**

1. **Complete a task without a Skill**: Work through an operation with Agent A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.

2. **Identify the reusable pattern**: After completing the task, identify what context you provided that would be useful for similar future operations.

   **Example**: If you worked through a Puppet deploy, you might have provided the environment prefix rules, the noop-then-apply sequence, and the rule about classifying exit 2 vs exit 6.

3. **Ask Agent A to create a Skill**: "Create a Skill that captures this Puppet deploy pattern. Include the prefix rules, the noop-then-apply sequence, and the exit-code decision rule."

4. **Review for conciseness**: Check that Agent A hasn't added unnecessary explanations. Ask: "Remove the explanation of what a catalog is — the agent already knows that."

5. **Improve information architecture**: Ask Agent A to organize the content more effectively. For example: "Move the exit-code table into a separate reference file. We might add more environments later."

6. **Test on similar tasks**: Use the Skill with Agent B (a fresh instance with the Skill loaded) on related operations. Observe whether Agent B finds the right information, applies rules correctly, and handles the task successfully.

7. **Iterate based on observation**: If Agent B struggles or misses something, return to Agent A with specifics: "When the agent used this Skill, it trusted the parallel-ssh summary instead of inspecting log bodies. Should we make the exit-code rule more prominent?"

**Iterating on existing Skills:**

The same hierarchical pattern continues when improving Skills. You alternate between:

* **Working with Agent A** (the expert who helps refine the Skill)
* **Testing with Agent B** (the agent using the Skill to perform real work)
* **Observing Agent B's behavior** and bringing insights back to Agent A

**Gathering team feedback:**

1. Share Skills with teammates and observe their usage
2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
3. Incorporate feedback to address blind spots in your own usage patterns

**Why this approach works**: Agent A understands agent needs, you provide domain expertise, Agent B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.

### Observe how agents navigate Skills

As you iterate on Skills, pay attention to how agents actually use them in practice. Watch for:

* **Unexpected exploration paths**: Does the agent read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
* **Missed connections**: Does the agent fail to follow references to important files? Your links might need to be more explicit or prominent
* **Overreliance on certain sections**: If the agent repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
* **Ignored content**: If the agent never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions

Iterate based on these observations rather than assumptions. The `name` and `description` in your Skill's metadata are particularly critical. Agents use these when deciding whether to trigger the Skill in response to the current task.

## Anti-patterns to avoid

### Avoid Windows-style paths

Always use forward slashes in file paths, even on Windows:

* ✓ **Good**: `scripts/classify_run.sh`, `reference/dns.md`
* ✗ **Avoid**: `scripts\classify_run.sh`, `reference\dns.md`

Unix-style paths work across all platforms, while Windows-style paths cause errors on Unix systems.

### Avoid offering too many options

Don't present multiple approaches unless necessary:

````markdown
**Bad example: Too many choices** (confusing):
"You can use kubectl, or helm, or helmfile, or kustomize, or..."

**Good example: Provide a default** (with escape hatch):
"Use helmfile for declarative deploys:
```bash
helmfile -e "$ENV" diff && helmfile -e "$ENV" sync
```

For a one-off resource inspection, use kubectl directly instead."
````

## Advanced: Skills with executable code

The sections below focus on Skills that include executable scripts. If your Skill uses only markdown instructions, skip to the checklist in `SKILL.md`.

### Solve, don't punt

When writing scripts for Skills, handle error conditions rather than punting to the agent.

**Good example: Handle errors explicitly**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Classify a puppet run from its log file.
# Real success = exit in {0,2} AND no Error:/Failed lines.
classify_run() {
  local logfile="$1"
  if [[ ! -f "$logfile" ]]; then
    echo "UNKNOWN: log file $logfile not found" >&2
    return 2
  fi
  if grep -qE '^(Error|Failed)' "$logfile"; then
    echo "FAILURE: errors present in $logfile"
    return 1
  fi
  echo "SUCCESS: no errors in $logfile"
}
```

**Bad example: Punt to the agent**:

```bash
classify_run() {
  # Just cat the log and let the agent figure it out
  cat "$1"
}
```

Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will the agent determine it?

**Good example: Self-documenting**:

```bash
# Wait 30s between rolling-restart batches so health checks
# have time to report before the next batch is touched.
BATCH_WAIT_SECONDS=30

# Three retries balances reliability vs speed; most transient
# apply failures clear by the second retry.
MAX_RETRIES=3
```

**Bad example: Magic numbers**:

```bash
WAIT=47   # Why 47?
RETRIES=5 # Why 5?
```

### Provide utility scripts

Even if your agent could write a script, pre-made scripts offer advantages:

**Benefits of utility scripts**:

* More reliable than generated code
* Save tokens (no need to include code in context)
* Save time (no code generation required)
* Ensure consistency across uses

**Important distinction**: Make clear in your instructions whether the agent should:

* **Execute the script** (most common): "Run `classify_run.sh` to score the log"
* **Read it as reference** (for complex logic): "See `classify_run.sh` for the classification rule"

For most utility scripts, execution is preferred because it's more reliable and efficient.

### Create verifiable intermediate outputs

When agents perform complex, open-ended operations, they can make mistakes. The "plan-validate-execute" pattern catches errors early by having the agent first create a plan in a structured format, then validate that plan with a script before executing it.

**Example**: Imagine asking the agent to update DNS records for 50 hosts based on a spreadsheet. Without validation, it might reference non-existent zones, create conflicting records, miss required PTRs, or apply updates incorrectly.

**Solution**: Add an intermediate `changes.json` (or a proposed zone diff) that gets validated before applying. The workflow becomes: gather → **create plan file** → **validate plan** (`named-checkzone`) → execute → verify (`dig`).

**Why this pattern works:**

* **Catches errors early**: Validation finds problems before changes are applied
* **Machine-verifiable**: Scripts provide objective verification
* **Reversible planning**: The agent can iterate on the plan without touching production
* **Clear debugging**: Error messages point to specific problems

**When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.

### Package dependencies

Skills run in whatever environment the agent operates in. Don't assume tools are present:

* On the local workstation, mise-managed tools are generally available
* On remote hosts, CI runners, or minimal containers, assume only base tooling and probe first

List required tools in your SKILL.md and verify they're available before relying on them.

### MCP tool references

If your Skill uses MCP (Model Context Protocol) tools, always use fully qualified tool names to avoid "tool not found" errors.

**Format**: `ServerName:tool_name`

Without the server prefix, agents may fail to locate the tool, especially when multiple MCP servers are available.

### Avoid assuming tools are installed

Don't assume packages are available:

````markdown
**Bad example: Assumes installation**:
"Use tshark to analyze the capture."

**Good example: Explicit about dependencies**:
"Verify tshark is present: `command -v tshark`
If missing, do not auto-install — ask the user for approval.

Then analyze:
```bash
tshark -r capture.pcap -nn -q -z io,phs
```"
````

## Technical notes

### YAML frontmatter requirements

The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. The `name` must match the skill's directory name.

### Token budgets

Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier.

## Checklist for effective Skills

Before sharing a Skill, verify:

### Core quality

* [ ] Description is specific and includes key terms
* [ ] Description describes ONLY when to use (triggering conditions), not the workflow
* [ ] SKILL.md body is under 500 lines
* [ ] Additional details are in separate files (if needed)
* [ ] No time-sensitive information (or in "old patterns" section)
* [ ] Consistent terminology throughout
* [ ] Examples are concrete, not abstract
* [ ] File references are one level deep
* [ ] Progressive disclosure used appropriately
* [ ] Workflows have clear steps

### Code and scripts

* [ ] Scripts solve problems rather than punt to the agent
* [ ] Standalone bash scripts start with `set -euo pipefail`
* [ ] Error handling is explicit and helpful
* [ ] No "voodoo constants" (all values justified)
* [ ] Required tools listed and probed rather than assumed
* [ ] Scripts have clear documentation
* [ ] No Windows-style paths (all forward slashes)
* [ ] Verification steps for critical operations
* [ ] Rollback path documented for mutating operations
* [ ] Feedback loops included for quality-critical tasks

### Testing

* [ ] Baseline (RED) run captured without the skill
* [ ] Pressure scenarios cover 3+ combined pressures (for discipline skills)
* [ ] Tested with the models and runtimes you plan to use
* [ ] Tested with real usage scenarios
* [ ] Team feedback incorporated (if applicable)
