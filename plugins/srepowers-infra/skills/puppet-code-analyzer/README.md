# puppet-code-analyzer

Analyze Puppet code quality in control repos and modules: linting,
dependency analysis, best-practice validation, and error troubleshooting.
Activates proactively when a `.pp` manifest, `Puppetfile`, `environment.conf`,
or `hiera.yaml` is opened or edited in a Puppet project. Ships as
`srepowers-infra:puppet-code-analyzer`. (`SKILL.md` is the agent-facing
trigger doc; this file is for humans.)

## Use cases

- Lint a manifest or whole module, with auto-fix and JSON output options
- Map class/module dependencies before a refactor
- Check a module against the style guide and expected layout
- Trace a cryptic Puppet error to its root cause and get fix suggestions

## How-to

In Claude Code or Codex, just ask — "analyze this module", "check for
issues", "lint this manifest" — the skill also triggers automatically on
Puppet paths. Or run the lint wrapper directly:

```bash
scripts/lint_puppet.py <module-or-file>   # structured issues by severity
scripts/lint_puppet.py --fix <file>       # auto-correct where possible
```

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo.

## Reference

Scripts (run directly, no need to load into context):

- `scripts/lint_puppet.py` — wrapper around `puppet-lint` with structured output
- `scripts/analyze_deps.py` — dependency graph parser and visualizer
- `scripts/check_best_practices.py` — style guide validator
- `scripts/trace_error.py` — error parser and fix suggester

References (loaded into context as needed):

- `references/puppet-style-guide.md` — team-specific Puppet conventions
- `references/common-issues.md` — catalog of frequent issues and solutions
- `references/module-structure.md` — expected module layout and patterns
- `references/puppetbestpractices.pdf` — *Puppet Best Practices* (O'Reilly 2018), read by chapter (bundled where shipped; not redistributed in public editions)

---
Last Updated: 2026-09-14
