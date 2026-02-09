---
name: puppet-code-analyzer
description: Automatically analyze and improve Puppet code quality in control repos and modules. Activates when working with Puppet manifests (.pp files), Puppetfiles, or Hiera data at ~/src/fsx/puppet/control or ~/src/fsx/puppet/modules. Provides code linting, dependency analysis, best practice validation, and error troubleshooting.
license: Complete terms in LICENSE.txt
---

# Puppet Code Analyzer

## Overview

Automatically analyze and improve Puppet code quality when working with control repos or modules. Activates proactively when referencing Puppet paths, opening `.pp` files, or modifying Puppet configuration. Leverages existing tools (puppet-lint, PDK) with helper scripts for dependency graphing, best practice validation, and error tracing.

## Activation

This skill activates automatically when:

- Opening or editing `.pp` manifest files in:
  - `~/src/fsx/puppet/control/*`
  - `~/src/fsx/puppet/modules/*`
- Modifying `Puppetfile`, `environment.conf`, `hiera.yaml`
- Explicitly requesting Puppet analysis (e.g., "analyze this module", "check for issues")
- Encountering Puppet errors during development or deployment

## Core Capabilities

### 1. Code Linting

Run `puppet-lint` with project-specific rules whenever opening or modifying `.pp` files.

**Usage:**
```bash
# Lint a specific file
scripts/lint_puppet.py ~/src/fsx/puppet/modules/fsx_dns/manifests/init.pp

# Lint entire module
scripts/lint_puppet.py ~/src/fsx/puppet/modules/fsx_dns

# Auto-fix issues
scripts/lint_puppet.py --fix ~/src/fsx/puppet/modules/fsx_dns/manifests/init.pp

# JSON output for parsing
scripts/lint_puppet.py --json ~/src/fsx/puppet/modules/fsx_dns > lint-results.json
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
scripts/analyze_deps.py ~/src/fsx/puppet/modules/fsx_infra

# Output Mermaid diagram for visualization
scripts/analyze_deps.py --mermaid ~/src/fsx/puppet/modules/fsx_infra > deps.mmd

# Write analysis to file
scripts/analyze_deps.py ~/src/fsx/puppet/modules/fsx_infra --output analysis.md
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
scripts/check_best_practices.py ~/src/fsx/puppet/modules/fsx_dns

# Use custom style guide
scripts/check_best_practices.py --style-guide ~/path/to/style-guide.md ~/src/fsx/puppet/modules/fsx_dns

# JSON output
scripts/check_best_practices.py --json ~/src/fsx/puppet/modules/fsx_dns > practices.json
```

**Validates:**
- **Naming conventions**: Class names, resource types, variables (lowercase with underscores)
- **String quotes**: Prefer single quotes for static strings
- **Parameter handling**: Type specifications, default values
- **Hiera lookups**: Automatic parameter lookup vs. `hiera()` function
- **Resource ordering**: Implicit ordering issues, missing explicit relationships
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
| Control repo environment | `~/src/fsx/puppet/control/{infra,jax,...}` | `environment.conf`, `Puppetfile`, role/profile patterns |
| Module | `~/src/fsx/puppet/modules/fsx_*` | Class structure, parameter handling, documentation |
| Hiera data | `*.yaml`, `*.yml` | YAML syntax, key references, hierarchy |

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
| **Git** | Pre-commit hooks (optional), staged file scanning |

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

**Usage:** Claude loads these files when detailed reference material is needed for analysis or recommendations.

### assets/

PDK templates and configuration files:

- **`pdk-config/`** - PDK templates for project initialization
- (Additional assets as needed for team standards)

**Note:** Most teams won't need this directory. Delete if unused.

## Quick Start Examples

**Scenario 1: Analyze a new module**
```bash
cd ~/src/fsx/puppet/modules/fsx_new_module
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
git add ~/src/fsx/puppet/modules/fsx_dns/manifests/*.pp
# Skill runs: Lint + syntax check on staged files
# Blocks commit if critical issues found
