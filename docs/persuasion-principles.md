# Persuasion Principles for SRE Skill Design

## Overview

LLMs respond to the same persuasion principles as humans. Understanding this psychology helps you design more effective infrastructure operation skills - not to manipulate, but to ensure critical practices are followed even under pressure.

**Research foundation:** Meincke et al. (2025) tested 7 persuasion principles with N=28,000 AI conversations. Persuasion techniques more than doubled compliance rates (33% → 72%, p < .001).

## The Seven Principles

### 1. Authority

**What it is:** Deference to expertise, credentials, or official sources.

**How it works in skills:**
- Imperative language: "YOU MUST", "Never", "Always"
- Non-negotiable framing: "No exceptions"
- Eliminates decision fatigue and rationalization

**When to use:**
- Discipline-enforcing skills (TDO, verification requirements)
- Safety-critical practices
- Established best practices

**Infrastructure examples:**
```markdown
✅ Write verification before operation. Delete operation if you executed first. No exceptions.
❌ Consider writing verification before operations when feasible.
```

```markdown
✅ NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
❌ You should probably verify before claiming completion.
```

### 2. Commitment

**What it is:** Consistency with prior actions, statements, or public declarations.

**How it works in skills:**
- Require announcements: "Announce skill usage"
- Force explicit choices: "Choose A, B, or C"
- Use tracking: TodoWrite for checklists

**When to use:**
- Ensuring skills are actually followed
- Multi-step processes
- Accountability mechanisms

**Infrastructure examples:**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

```markdown
✅ Choose A) Delete code and start over with TDO, B) Commit now and add tests later, C) Write tests now
❌ What would you like to do about testing?
```

### 3. Scarcity

**What it is:** Urgency from time limits or limited availability.

**How it works in skills:**
- Time-bound requirements: "Before proceeding"
- Sequential dependencies: "Immediately after X"
- Prevents procrastination

**When to use:**
- Immediate verification requirements
- Time-sensitive workflows
- Preventing "I'll do it later"

**Infrastructure examples:**
```markdown
✅ After completing an operation, IMMEDIATELY run verification before claiming success.
❌ You can verify the operation when convenient.
```

```markdown
✅ Before claiming any status, run verification command in this message.
❌ Run verification before claiming completion at some point.
```

### 4. Social Proof

**What it is:** Conformity to what others do or what's considered normal.

**How it works in skills:**
- Universal patterns: "Every time", "Always"
- Failure modes: "X without Y = failure"
- Establishes norms

**When to use:**
- Documenting universal practices
- Warning about common failures
- Reinforcing standards

**Infrastructure examples:**
```markdown
✅ Verification before operation = confidence. Operation before verification = incidents. Every time.
❌ Some people find verification before operations helpful.
```

```markdown
✅ Infrastructure changes without verification = production incidents.
❌ Unverified changes sometimes cause issues.
```

### 5. Unity

**What it is:** Shared identity, "we-ness", in-group belonging.

**How it works in skills:**
- Collaborative language: "our infrastructure", "we're colleagues"
- Shared goals: "we both want reliability"
- Shared responsibility: "we prevent incidents together"

**When to use:**
- Collaborative workflows
- Establishing team culture
- Non-hierarchical practices

**Infrastructure examples:**
```markdown
✅ We're colleagues working together. I need your honest technical judgment about this operation.
❌ You should probably tell me if I'm wrong.
```

```markdown
✅ Our infrastructure depends on verification. We don't skip it.
❌ You should verify operations to prevent issues.
```

### 6. Reciprocity

**What it is:** Obligation to return benefits received.

**How it works:**
- Use sparingly - can feel manipulative
- Rarely needed in skills

**When to avoid:**
- Almost always (other principles more effective for SRE discipline)

### 7. Liking

**What it is:** Preference for cooperating with those we like.

**How it works:**
- **DON'T USE for compliance**
- Conflicts with honest feedback culture
- Creates sycophancy

**When to avoid:**
- Always for discipline enforcement

**Infrastructure example of what NOT to do:**
```markdown
❌ "Great job on that operation! Now let's verify it properly." (Undermines discipline)
```

## Principle Combinations by Skill Type

| Skill Type | Use | Avoid |
|------------|-----|-------|
| **Discipline-enforcing** (TDO, VBC) | Authority + Commitment + Social Proof | Liking, Reciprocity |
| **Guidance/technique** (writing-plans) | Moderate Authority + Unity | Heavy authority |
| **Collaborative** (brainstorming) | Unity + Commitment | Authority, Liking |
| **Reference** (meta-skill) | Clarity only | All persuasion |

## Why This Works: The Psychology

**Bright-line rules reduce rationalization:**
- "YOU MUST" removes decision fatigue
- Absolute language eliminates "is this an exception?" questions
- Explicit anti-rationalization counters close specific loopholes

**Implementation intentions create automatic behavior:**
- Clear triggers + required actions = automatic execution
- "When X, do Y" more effective than "generally do Y"
- Reduces cognitive load on compliance

**LLMs are parahuman:**
- Trained on human text containing these patterns
- Authority language precedes compliance in training data
- Commitment sequences (statement → action) frequently modeled
- Social proof patterns (everyone does X) establish norms

## Ethical Use

**Legitimate:**
- Ensuring critical infrastructure practices are followed
- Creating effective documentation
- Preventing predictable failures
- Protecting production systems

**Illegitimate:**
- Manipulating for personal gain
- Creating false urgency
- Guilt-based compliance

**The test:** Would this technique serve the user's genuine interests if they fully understood it?

## Infrastructure-Specific Applications

### For Test-Driven Operation (TDO)

**Authority:** "NO INFRASTRUCTURE CHANGE WITHOUT A FAILING VERIFICATION FIRST"
**Commitment:** Announce "I'm using TDO" at start
**Social Proof:** "Verification before operation = confidence. Operation before verification = incidents. Every time."
**Scarcity:** "Verification must happen in this message, before any claim"

### For Verification Before Completion (VBC)

**Authority:** "NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE"
**Scarcity:** "Run verification in this message before claiming"
**Social Proof:** "Claims without evidence = dishonesty, not efficiency"

### For Subagent-Driven Operation (SDO)

**Authority:** "Spec compliance review MUST pass before artifact quality review"
**Commitment:** Announce "I'm using Subagent-Driven Operation"
**Unity:** "We're colleagues working together on infrastructure"

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
- Seven principles of persuasion
- Empirical foundation for influence research

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
- Tested 7 principles with N=28,000 LLM conversations
- Compliance increased 33% → 72% with persuasion techniques
- Authority, commitment, scarcity most effective
- Validates parahuman model of LLM behavior

## Quick Reference

When designing an SRE skill, ask:

1. **What type is it?** (Discipline vs. guidance vs. reference)
2. **What behavior am I trying to change?**
3. **Which principle(s) apply?** (Usually authority + commitment for discipline)
4. **Am I combining too many?** (Don't use all seven)
5. **Is this ethical?** (Serves user's genuine interests? Protects infrastructure?)

## Related Documentation

- [Testing Anti-Patterns](testing-anti-patterns.md)
- [Test-Driven Operation Skill](../skills/test-driven-operation/SKILL.md)
- [Verification Before Completion Skill](../skills/verification-before-completion/SKILL.md)
