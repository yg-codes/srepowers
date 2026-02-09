# Release Notes

## [1.0.0] - 2025-02-09

### Initial Release

First release of SREPowers - SRE infrastructure skills for Claude Code.

#### New Skills

**test-driven-operation**
- Test-Driven Operation (TDO) workflow for infrastructure
- Verification-first discipline for kubectl, API calls, Keycloak CRDs, Git MRs, Linux server operations
- Red-Green-Refactor cycle adapted for infrastructure operations
- Comprehensive examples for Kubernetes, Keycloak, Git control repos, APIs, and Linux servers

**subagent-driven-operation**
- Subagent-driven operation workflow for executing infrastructure plans
- Two-stage review process: spec compliance then artifact quality
- Operator subagent with specialized prompts for infrastructure work
- Spec compliance reviewer to verify operations match requirements
- Artifact quality reviewer for YAML/JSON validation and Kubernetes best practices

#### Features

- Full compatibility with Claude Code plugin system
- Marketplace-ready plugin configuration
- Comprehensive documentation with usage examples
- MIT licensed

#### Plugin Structure

- `.claude-plugin/plugin.json` - Plugin manifest
- `.claude-plugin/marketplace.json` - Marketplace configuration
- `skills/test-driven-operation/SKILL.md` - TDO skill definition
- `skills/subagent-driven-operation/` - Subagent-driven operation with prompts:
  - `SKILL.md` - Main skill definition
  - `operator-prompt.md` - Operator subagent prompt template
  - `spec-reviewer-prompt.md` - Spec compliance reviewer prompt
  - `artifact-quality-reviewer-prompt.md` - Artifact quality reviewer prompt

#### Documentation

- Comprehensive README with installation instructions
- Usage examples for multiple infrastructure types
- Clear explanation of TDO principles adapted from TDD
- Two-stage review process documentation

#### Acknowledgments

Adapted from the [superpowers](https://github.com/obra/superpowers) plugin by Jesse Vital, with infrastructure-specific adaptations for SRE workflows.

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-02-09 | Initial release with test-driven-operation and subagent-driven-operation skills |
