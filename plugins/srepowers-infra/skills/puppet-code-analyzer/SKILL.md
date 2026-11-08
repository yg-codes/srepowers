---
name: puppet-code-analyzer
description: Use when analyzing Puppet code quality in control repos and modules - linting, dependency analysis, best practice validation, and error troubleshooting for Puppet manifests, Puppetfiles, and Hiera data
---

# Puppet Code Analyzer

## Overview

Automatically analyze and improve Puppet code quality when working with control repos or modules. Activates proactively when referencing Puppet paths, opening `.pp` files, or modifying Puppet configuration. Leverages existing tools (puppet-lint, PDK) with helper scripts for dependency graphing, best practice validation, and error tracing.

## Activation

This skill activates automatically when:

- Opening or editing `.pp` manifest files in:
  - `~/src/<org>/puppet/control/*`
  - `~/src/<org>/puppet/modules/*`
- Modifying `Puppetfile`, `environment.conf`, `hiera.yaml`
- Explicitly requesting Puppet analysis (e.g., "analyze this module", "check for issues")
- Encountering Puppet errors during development or deployment

## Reference Loading Protocol

**Always load the following before starting any analysis**, based on what is being reviewed:

| Target | Load immediately |
|--------|-----------------|
| Any `.pp` manifest file | *Puppet Best Practices* (O'Reilly 2018) Ch3: Coding Practices (pp. 37–72) — bundled at `references/puppetbestpractices.pdf` where shipped |
| Module directory | *Puppet Best Practices* (O'Reilly 2018) Ch4: Module Design (pp. 75–110) — bundled at `references/puppetbestpractices.pdf` where shipped |
| `hiera.yaml` or Hiera data (`*.yaml` under `data/`) | *Puppet Best Practices* (O'Reilly 2018) Ch6: Hiera Data (pp. 151–170) — bundled at `references/puppetbestpractices.pdf` where shipped |
| Resource declarations (`package`, `file`, `service`, `exec`) | *Puppet Best Practices* (O'Reilly 2018) Ch5: Resources (pp. 113–148) — bundled at `references/puppetbestpractices.pdf` where shipped |
| `Puppetfile` or environment-level code | *Puppet Best Practices* (O'Reilly 2018) Ch2: Code and Data Design (pp. 21–34) — bundled at `references/puppetbestpractices.pdf` where shipped |
| Any Puppet code (catch-all) | `references/puppet-style-guide.md` |

**Additionally load on demand:**
- `references/common-issues.md` — when diagnosing errors or anti-patterns
- `references/module-structure.md` — when reviewing module layout or class structure
- *Puppet Best Practices* (O'Reilly 2018) Ch1: Design Philosophy (pp. 1–20) — bundled at `references/puppetbestpractices.pdf` where shipped — when evaluating idempotency or declarative correctness

**Do not skip reference loading where the book is bundled** — its chapters are
the authoritative source for best practice judgements; always cite chapter
and page for findings that come from it. Where the book is NOT bundled
(public editions — it is a commercial O'Reilly title and is not
redistributed), judge from `common-issues.md` and `module-structure.md` and
cite the chapter by number only.

## Core Capabilities

### 1. Code Linting

Run `puppet-lint` with project-specific rules whenever opening or modifying `.pp` files.

**Usage:**
```bash
# Lint a specific file
scripts/lint_puppet.py ~/src/<org>/puppet/modules/<module>_dns/manifests/init.pp

# Lint entire module
scripts/lint_puppet.py ~/src/<org>/puppet/modules/<module>_dns

# Auto-fix issues
scripts/lint_puppet.py --fix ~/src/<org>/puppet/modules/<module>_dns/manifests/init.pp

# JSON output for parsing
scripts/lint_puppet.py --json ~/src/<org>/puppet/modules/<module>_dns > lint-results.json
```

**Behavior:**
- Respects `.puppet-lint.rc` if present in project
- Returns structured output: file, line, column, severity, rule code, message
- Groups issues by severity: CRITICAL, WARNING, INFO
- Supports `--fix` flag for auto-correction where possible

**Integration:**
- Automatically runs on `.pp` file saves
- Suggests fixes with code examples
- Can be integrated as git pre-commit hook

### 2. Dependency Analysis

Parse manifests to build dependency graphs, detect circular dependencies, and identify missing/unused classes.

**Usage:**
```bash
# Analyze module dependencies
scripts/analyze_deps.py ~/src/<org>/puppet/modules/<module>_infra

# Output Mermaid diagram for visualization
scripts/analyze_deps.py --mermaid ~/src/<org>/puppet/modules/<module>_infra > deps.mmd

# Write analysis to file
scripts/analyze_deps.py ~/src/<org>/puppet/modules/<module>_infra --output analysis.md
```

**Detects:**
- Class relationships: include, require, contain, notify, subscribe
- Chain arrows: `->`, `~>`, `<-`, `<~`
- Circular dependencies
- Unused classes (defined but never referenced)
- Dependency clusters (tightly coupled modules)

**Output:**
- Text summary with class relationships
- Mermaid diagram for visualization
- Critical warnings for circular dependencies

### 3. Best Practice Review

Validate manifests against Puppet style guide and common anti-patterns.

**Usage:**
```bash
# Check best practices
scripts/check_best_practices.py ~/src/<org>/puppet/modules/<module>_dns

# Use custom style guide
scripts/check_best_practices.py --style-guide ~/path/to/style-guide.md ~/src/<org>/puppet/modules/<module>_dns

# JSON output
scripts/check_best_practices.py --json ~/src/<org>/puppet/modules/<module>_dns > practices.json
```

**Validates:**
- **Naming conventions**: Class names, resource types, variables (lowercase with underscores)
- **String quotes**: Prefer single quotes for static strings
- **Hiera YAML quoting**: All string values quoted — single quotes default, double only for `%{}` interpolation or embedded single quotes; enforced by yamllint `quoted-strings` rule (see `references/puppet-style-guide.md` § Hiera YAML String Quoting)
- **Psych semantics**: Judge Hiera data types as Ruby Psych (YAML 1.1) resolves them, not YAML 1.2 — unquoted `yes`/`on` are booleans; bulk YAML edits must verify semantic equivalence via Psych parse comparison
- **eYAML integrity**: `ENC[...]` blobs never reflowed; original line-wrapping preserved verbatim (see style guide § eYAML / ENC Value Handling)
- **Parameter handling**: Type specifications, default values
- **Required parameters without defaults**: CRITICAL - causes bootstrap failures when Hiera data doesn't match
- **Hiera lookups**: Automatic parameter lookup vs. `hiera()` function
- **Resource ordering**: Implicit ordering issues, missing explicit relationships
- **Class inclusion patterns**: Classes in `common/all.yaml` must have safe defaults
- **Custom rules**: Load team-specific rules from `references/puppet-style-guide.md`

**Integration:**
- Reads `references/puppet-style-guide.md` for team conventions
- Suggests specific fixes with examples
- Links to relevant Puppet documentation

### 4. Error Troubleshooting

Parse Puppet error messages and stack traces to identify root causes and suggest fixes.

**Usage:**
```bash
# Analyze error message
scripts/trace_error.py "Error: Could not parse for environment production: Syntax error at '}'"

# Parse error log file
scripts/trace_error.py --file /var/log/puppet/puppet.log

# Interactive mode
scripts/trace_error.py --interactive
```

**Diagnoses:**
- Duplicate declarations
- Undefined variables
- Dependency cycles
- File not found (templates, modules)
- Syntax errors
- Hiera lookup failures
- Catalog compilation failures
- Package installation failures
- Permission denied errors

**Suggestions:**
- Root cause explanation
- Specific fix steps
- Related files (extracted from error output)
- Links to documentation

## Project Detection

The skill automatically identifies project type and applies appropriate analysis:

| Project Type | Path Pattern | Analysis Focus |
|--------------|--------------|----------------|
| Control repo environment | `~/src/<org>/puppet/control/{infra,<site-b>,...}` | `environment.conf`, `Puppetfile`, role/profile patterns |
| Module | `~/src/<org>/puppet/modules/<module>_*` | Class structure, parameter handling, documentation |
| Hiera data | `*.yaml`, `*.yml` | YAML syntax, string quoting convention, Psych (YAML 1.1) type resolution, eyaml ENC integrity, key references, hierarchy |

## Configuration Sources

The skill respects project-specific configuration:

1. **`.puppet-lint.rc`** → Linting rules and exclusions
2. **`.yamllint.yml`** → YAML validation for Hiera files
3. **`PDK` metadata** → Module structure validation via `metadata.json`
4. **`references/puppet-style-guide.md`** → Team-specific conventions (customizable)

## Output Format

Analysis results follow this consistent structure:

```markdown
## Puppet Analysis: [path]

### Issues Found
- **CRITICAL**: [description] at [file]:[line]
- **WARNING**: [description] at [file]:[line]

### Dependencies
[Mermaid diagram or text summary]

### Suggestions
1. [Actionable recommendation]
2. [Actionable recommendation]

### References
- [Link to relevant docs]
```

## Integration with Existing Tools

The skill wraps and enhances existing Puppet tooling:

| Tool | Skill Integration |
|------|------------------|
| **puppet-lint** | Structured output, `--fix` support, project config detection |
| **PDK** | `pdk validate` integration, metadata-based checks |
| **puppet parser** | Syntax validation via lint script |
| **yamllint** | `yamllint --strict data/` per control repo `.yamllint.yml` (incl. `quoted-strings` rule) |
| **<org>-puppetfile-format** | `./bin/<org>-puppetfile-format check Puppetfile` in control repos (git-before-Forge ordering) |
| **Git** | Pre-commit hooks (optional), staged file scanning |

## SRE Principles

### Safety First
- Run analysis in `--check` mode before applying `--fix` to preview all proposed changes
- Commit current state before running `--fix` to ensure reversibility via `git revert`
- Phase structure: **Pre-check** (lint, dependency scan, best practice check) → **Execute** (apply fixes with `--fix`) → **Verify** (re-run analysis, confirm zero issues, test compilation)

### Structured Output
- Present analysis results using severity tables (file, line, severity, rule, message, auto-fixable)
- Use dependency summary tables (module, current version, latest version, breaking changes)
- Include trend reports showing issue counts over time (date, critical, warning, info, total)

### Evidence-Driven
- Reference specific puppet-lint rule codes and line numbers for every finding
- Include `puppet parser validate` output and r10k/librarian dependency resolution logs
- Cite before/after code diffs showing exactly what `--fix` changed

### Audit-Ready
- Save analysis reports with timestamps in JSON format for historical tracking
- Document all auto-fix changes with git diffs showing original and modified code
- Maintain a remediation log linking findings to fix commits and review approvals

### Communication
- Lead with deployment risk (e.g., "12 critical issues blocking safe Puppet deployment across 200 nodes")
- Present code quality trends in business terms (deployment confidence, change failure rate)
- Summarize technical debt in effort estimates (hours to remediate per severity level)

## Resources

### scripts/

Executable Python scripts for Puppet code analysis:

- **`lint_puppet.py`** - Wrapper around `puppet-lint` with structured output
- **`analyze_deps.py`** - Dependency graph parser and visualizer
- **`check_best_practices.py`** - Style guide validator
- **`trace_error.py`** - Error parser and fix suggester

**Execution:** Scripts can be run directly without loading into context, or read by Claude for patching and environment-specific adjustments.

### references/

Documentation loaded into context as needed:

- **`puppet-style-guide.md`** - Team-specific Puppet conventions and standards
- **`common-issues.md`** - Catalog of frequently encountered issues and solutions
- **`module-structure.md`** - Expected module layout and patterns
- **`puppetbestpractices.pdf`** - *Puppet Best Practices: Design Patterns for Maintainable Code* by Chris Barbour & Jo Rhett (O'Reilly, 2018, ISBN 978-1-491-92300-9). Authoritative reference for:
  - Ch1: Design philosophy — declarative code, idempotency, stateless design
  - Ch2: High-level code and data design — roles/profiles, Hiera data sources
  - Ch3: Coding practices — KISS/DRY/SRP principles, variables, EPP vs ERB templates
  - Ch4: Module design — PDK, module structure, params.pp pattern, input validation
  - Ch5: Resources — resource declaration, virtual resources, metaparameters, chaining
  - Ch6: Hiera data — hierarchy design, automatic parameter lookups, eYAML, backends

**Usage:** Claude reads PDF pages when deep authoritative guidance is needed. Use `pages:` parameter to target specific chapters — e.g., pages 151–170 for Hiera, pages 37–73 for coding practices, pages 75–110 for module design.

## Quick Start Examples

**Scenario 1: Analyze a new module**
```bash
cd ~/src/<org>/puppet/modules/<module>_new
# Skill activates automatically
# Runs: lint + dependency analysis + best practices check
```

**Scenario 2: Troubleshoot deployment error**
```bash
# Paste Puppet error
scripts/trace_error.py "Error: Duplicate declaration: Package[nginx]"
# Get: Root cause + specific fix suggestions
```

**Scenario 3: Review Puppetfile changes**
```bash
# Edit Puppetfile
# Skill detects change
# Runs: Dependency version check + breaking change warnings
```

**Scenario 4: Pre-commit validation**
```bash
# Stage .pp files
git add ~/src/<org>/puppet/modules/<module>_dns/manifests/*.pp
# Skill runs: Lint + syntax check on staged files
# Blocks commit if critical issues found
