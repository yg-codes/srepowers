---
name: sre-readme
description: Use when creating or updating README.md files for any repository or component. Generates concise, Structure-based READMEs with How-to, Reference, and Explanation sections. Works for infra, apps, libraries, Helm charts, Terraform modules, etc.
---

# SRE README

Generate concise, useful READMEs based on the Structure documentation framework.

## Structure Principle

READMEs mix four documentation types. Keep them **separated and labeled**:

| Type | Purpose | In README? |
|------|---------|:----------:|
| **How-to** | Steps to accomplish a task | Always |
| **Reference** | Lookup info (commands, config, API) | Always |
| **Explanation** | Why things work this way | When needed |
| **Tutorial** | Learning-oriented walkthrough | Optional |

**Key boundaries:**
- **How-to** = ordered steps to achieve a goal (deploy, configure, rollback)
- **Reference** = unordered lookup (commands, flags, config parameters)
- Don't dump command lists into How-to. Don't hide workflows inside Reference.

## README Structure

### Required Sections

```markdown
# Project Name

One-line description of what this does.

## How-to

### Deploy / Install / Run

Step-by-step commands. No explanation — just do.

### Configure

What to change and where.

### Verify

Commands to confirm success. Always include expected output.

### Upgrade / Update

Steps to update to a new version.

### Rollback

Steps to safely revert changes.

## Reference

### Commands

| Command | Purpose |
|---------|---------|
| `cmd1`  | Does X  |
| `cmd2`  | Does Y  |

### Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `key`     | `val`   | What it controls |

### Directory Structure

Only if non-obvious.

## Explanation

### Architecture

Why it's built this way. Mermaid diagram if it helps.

Add Explanation when:
- Architecture is non-trivial (multi-node, HA, networking)
- There are hidden constraints (ordering, dependencies)
- Failure modes are not obvious from logs

### Design Decisions

Only document decisions that would surprise a newcomer.

---
Last Updated: YYYY-MM-DD
```

### Optional Sections

Add **only when they earn their place**:

| Section | When to Include |
|---------|-----------------|
| **Quick Start** | Appears before How-to. Provide a <60s fast path when getting running takes >3 commands |
| **Tutorial** | Onboarding is non-trivial (3+ steps with context needed) |
| **Troubleshooting** | Known failure modes exist that aren't obvious from logs |
| **Environment Matrix** | Multi-env deployments (dev/test/prod) |
| **Prerequisites** | Non-standard dependencies that aren't in package manager |

## Rules

1. **Short by default.** A README for a simple component should be <50 lines. Scale up only with actual complexity.
2. **No boilerplate.** Skip sections that would contain only placeholder text. Empty sections are worse than missing sections.
3. **Real values + expected results.** Show actual commands, actual config. Always show what success looks like. Include failure indicators when non-obvious.
4. **How-to comes first.** The most common reader is someone trying to DO something, not understand something.
5. **One source of truth.** Don't duplicate what's in values.yaml comments, --help output, or inline code comments. Link to it instead.
6. **Explanation is earned.** Only add architecture/design sections when the "why" isn't obvious from the code structure.
7. **Footer required.** Always end with `Last Updated: YYYY-MM-DD`.
8. **Verification is mandatory.** Every How-to section must include a Verify step with expected output.
9. **Rollback for state changes.** Any operation that modifies state (deploy, upgrade, config change) must document how to revert. Rollback must: restore previous working state, be executable without external knowledge, and specify data impact (if any).
10. **Local verification for critical steps.** In multi-step workflows, include verification immediately after key operations — don't defer all checks to the end.
11. **Indicate idempotency when relevant.** Mark critical commands as "safe to re-run" or "one-time only".

## Sizing Guide

| Project Complexity | Target Lines | Sections |
|-------------------|:------------:|----------|
| **Simple** (single script, small lib) | 20-50 | How-to (with Verify) + Reference |
| **Standard** (service, chart, module) | 50-100 | How-to (with Verify + Rollback) + Reference + brief Explanation |
| **Complex** (platform, multi-component) | 100-150 | All sections, Environment Matrix, Troubleshooting |

## Process

1. **Read the project** — understand what it does, how it's deployed, what's configurable
2. **Identify the audience** — who reads this? Operator deploying it? Developer extending it?
3. **Write How-to first** — deploy, configure, verify, rollback commands
4. **Add Reference** — commands table, config parameters, directory structure
5. **Add Explanation only if needed** — architecture diagram, non-obvious design decisions
6. **Trim** — remove anything that restates the obvious or duplicates other sources

## See also

- `srepowers-domain:code-documenter` (if installed) — software documentation (docstrings, API specs, doc sites, OpenAPI). Use that for code documentation; use this skill for operational/infrastructure READMEs.
