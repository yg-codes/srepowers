# SREPowers Plugin Implementation Plan

## Overview
Package `test-driven-operation` and `subagent-driven-operation` skills as a Claude Code plugin for SRE infrastructure workflows.

## Repository Structure

```
srepowers/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Marketplace configuration
├── skills/                  # Skills library
│   ├── test-driven-operation/
│   │   └── SKILL.md
│   └── subagent-driven-operation/
│       ├── SKILL.md
│       ├── operator-prompt.md
│       ├── spec-reviewer-prompt.md
│       └── artifact-quality-reviewer-prompt.md
├── README.md
├── LICENSE
└── RELEASE-NOTES.md
```

## Implementation Tasks

### Phase 1: Core Plugin Configuration

#### Task 1.1: Create `.claude-plugin` directory structure
- Create `.claude-plugin/` directory
- Set up proper directory permissions

#### Task 1.2: Create `plugin.json` manifest
- Define plugin metadata: name, description, version, author
- Set homepage and repository URLs
- Add relevant keywords (sre, infrastructure, kubernetes, keycloak, tdo)
- Configure license (MIT)

**Expected content:**
```json
{
  "name": "srepowers",
  "description": "SRE infrastructure skills: Test-Driven Operations and Subagent-Driven Operations for Kubernetes, Keycloak, GitOps, and API workflows",
  "version": "1.0.0",
  "author": {
    "name": "yg",
    "email": "yg@example.com"
  },
  "homepage": "https://github.com/yg/srepowers",
  "repository": "https://github.com/yg/srepowers",
  "license": "MIT",
  "keywords": ["sre", "infrastructure", "kubernetes", "keycloak", "gitops", "tdo", "operations", "devops"]
}
```

#### Task 1.3: Create `marketplace.json` configuration
- Define marketplace metadata
- Configure plugin source reference
- Set owner information

### Phase 2: Skills Migration

#### Task 2.1: Create `skills/` directory structure
- Create `skills/test-driven-operation/`
- Create `skills/subagent-driven-operation/`

#### Task 2.2: Copy `test-driven-operation` skill
- Copy SKILL.md from `~/.claude/skills/test-driven-operation/SKILL.md`
- Verify frontmatter metadata is correct
- Test skill loads properly

#### Task 2.3: Copy `subagent-driven-operation` skill
- Copy all skill files:
  - SKILL.md
  - operator-prompt.md
  - spec-reviewer-prompt.md
  - artifact-quality-reviewer-prompt.md
- Verify all prompt templates are included
- Test skill loads properly

### Phase 3: Documentation

#### Task 3.1: Update README.md
- Add plugin description and purpose
- Document installation instructions
- List available skills with descriptions
- Add usage examples
- Include contribution guidelines

**README sections:**
```markdown
# SREPowers

SRE infrastructure skills for Claude Code.

## Installation

Via Claude Code marketplace:
```bash
/plugin marketplace add yg/srepowers-marketplace
/plugin install srepowers@srepowers-marketplace
```

## Available Skills

### test-driven-operation
Use when executing infrastructure operations with verification commands.

### subagent-driven-operation
Use when executing infrastructure operation plans with independent tasks.

## Usage Examples
...
```

#### Task 3.2: Create RELEASE-NOTES.md
- Document version history
- List new features and changes
- Track breaking changes

#### Task 3.3: Update LICENSE
- Ensure MIT license is properly configured
- Add copyright notice

### Phase 4: Git Repository Setup

#### Task 4.1: Initialize git repository
- Initialize `.git/` if not already present
- Create `.gitignore` file

**.gitignore content:**
```
# Claude Code
.claude/debug/
.claude/downloads/
.claude/file-history/
.claude/session-env/
.claude/shell-snapshots/
.claude/transcripts/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo
```

#### Task 4.2: Create initial commit
- Stage all plugin files
- Create descriptive commit message
- Verify commit was created successfully

#### Task 4.3: Push to GitHub
- Verify remote repository exists
- Push main branch
- Verify files on GitHub

### Phase 5: Testing and Verification

#### Task 5.1: Local plugin testing
- Install plugin from local path
- Verify skills are loaded
- Test skill invocation
- Verify prompt templates load correctly

#### Task 5.2: Create test scenarios
- Test `test-driven-operation` with kubectl example
- Test `subagent-driven-operation` with Keycloak example
- Document test results

### Phase 6: Marketplace Preparation (Optional)

#### Task 6.1: Create marketplace repository
- Create separate `srepowers-marketplace` repo
- Add marketplace configuration

#### Task 6.2: Register marketplace
- Publish marketplace to GitHub
- Test marketplace installation

## Success Criteria

- [ ] Plugin structure matches superpowers format
- [ ] Both skills load successfully in Claude Code
- [ ] All prompt templates are accessible
- [ ] README provides clear installation instructions
- [ ] Git repository is properly initialized
- [ ] Skills can be invoked and execute correctly
- [ ] Documentation is complete and accurate

## Notes

- Plugin follows the same structure as `obra/superpowers` for consistency
- Skills remain in both `~/.claude/skills/` and the plugin repository
- OpenCode support can be added later if needed
- Version should start at 1.0.0 for initial release
