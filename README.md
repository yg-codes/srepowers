# SREPowers

SRE infrastructure skills for Claude Code and Codex.

SREPowers adapts software development workflows like brainstorming, planning, subagent execution, and verification-first discipline to infrastructure operations. It is the SRE companion to [superpowers](https://github.com/obra/superpowers): same workflow spine, different domain.

## How It Works

SREPowers starts by slowing the agent down before it does infrastructure work. Instead of jumping straight to `kubectl`, Terraform, or API calls, it pushes the agent to clarify the goal, write an execution plan, and define verification before making changes.

Once the plan is approved, the execution skills apply Test-Driven Operation: write a verification command, watch it fail, make the smallest change, and verify again. For larger changes, SREPowers can break the work into reviewed subagent steps so execution stays aligned with the plan.

The result is not “more automation.” The value is disciplined operations under pressure: verification before claims, rollback-aware planning, and explicit review of risky changes.

## Minimum Sufficient Workflow

SREPowers now routes tasks through the minimum sufficient workflow instead of forcing the heaviest process every time.

### Skill Classes

| Class | Skills | Purpose |
|------|--------|---------|
| Mandatory gates | `verification-before-completion`, `safety-validator`, `evidence-first-reporting` | Enforce evidence, safety, and precise reporting |
| Workflow skills | `brainstorming-operations`, `writing-operation-plans`, `test-driven-operation`, `subagent-driven-operation`, `executing-operation-plans` | Shape the operation process |
| Domain helpers | `kubernetes-specialist`, `terraform-engineer`, `pve-admin`, `puppet-code-analyzer`, and peers | Add platform-specific depth after routing |

### Routing Rules

| Situation | Route |
|----------|-------|
| Incident or unclear outage | `systematic-troubleshooting` first |
| Major incident with multiple teams or broad impact | `incident-commander` + `systematic-troubleshooting` |
| Planned multi-step change | `brainstorming-operations` → `writing-operation-plans` → execution skill |
| Small known-safe local change | `test-driven-operation` fast path |
| Read-only review or diagnosis | Domain skill + `evidence-first-reporting` |
| Risky or production command set | Add `safety-validator` before execution |

### Fast Path

Use the fast path only for low-risk, read-only, or single-file/local-only work with exact local validation. It skips full planning, but it does not skip validation or evidence.

## What’s Inside

| Path | Purpose |
|------|---------|
| `skills/` | Canonical SREPowers skill definitions |
| `.agents/skills/` | Codex skill mirror for repo-native discovery |
| `.codex-plugin/` | Codex plugin manifest |
| `.claude-plugin/` | Claude Code plugin and marketplace metadata |
| `.codex/agents/` | Codex custom infrastructure agents |
| `commands/` | Claude compatibility wrappers for `/command` usage |
| `hooks/` | Shared session-start context injection |
| `tests/` | Claude and Codex validation scripts |

## Installation

### Claude Code Marketplace

```bash
/plugin marketplace add yg-codes/srepowers
/plugin install srepowers@srepowers-marketplace
```

Verify with `/help`. You should see commands such as `/test-driven-operation` and `/subagent-driven-operation`.

### Claude Code Manual Installation

```bash
git clone https://github.com/yg-codes/srepowers.git ~/.claude/plugins/srepowers
```

Or copy the skills directly:

```bash
cp -r srepowers/skills/* ~/.claude/skills/
```

### Codex Native Skills Install

This is the recommended Codex setup if you want the simplest update path:

1. Clone the repository into your Codex workspace area.

```bash
git clone https://github.com/yg-codes/srepowers.git ~/.codex/srepowers
```

2. Create the skills symlink.

```bash
mkdir -p ~/.agents/skills
ln -s ~/.codex/srepowers/skills ~/.agents/skills/srepowers
```

3. Restart Codex.

Codex will discover the SREPowers skills through `~/.agents/skills/srepowers`. Use `/skills` to inspect them, or mention a skill directly such as `$test-driven-operation`.

Verify:

```bash
ls -la ~/.agents/skills/srepowers
```

You should see a symlink pointing at `~/.codex/srepowers/skills`.

Update:

```bash
cd ~/.codex/srepowers && git pull
```

This path updates cleanly because the skills are loaded directly from the cloned repository through the symlink.

### Codex Repo-Native Use

Use this when you are working inside the SREPowers repository itself:

```bash
git clone https://github.com/yg-codes/srepowers.git
cd srepowers
codex .
```

Codex will load:

- `AGENTS.md`
- `.agents/skills/`
- `.codex/agents/`
- `.codex/hooks.json`

### Codex Local Plugin Install

Use this when you specifically want SREPowers to appear in Codex `/plugins` as a local plugin:

1. Clone the plugin into your Codex plugins directory.

```bash
mkdir -p ~/.codex/plugins
git clone https://github.com/yg-codes/srepowers.git ~/.codex/plugins/srepowers
```

2. Add a local plugin marketplace file.

```bash
mkdir -p ~/.agents/plugins
cat > ~/.agents/plugins/marketplace.json <<'EOF'
{
  "name": "local-plugins",
  "interface": {
    "displayName": "Local Plugins"
  },
  "plugins": [
    {
      "name": "srepowers",
      "source": {
        "source": "local",
        "path": "./.codex/plugins/srepowers"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Engineering"
    }
  ]
}
EOF
```

3. Restart Codex, open `/plugins`, find `srepowers`, and install or enable it.

This method does not auto-update. You still need to run:

```bash
cd ~/.codex/plugins/srepowers && git pull
```

Then restart Codex to pick up the new plugin files.

The checked-in `.agents/plugins/marketplace.json` is for developing SREPowers from inside this repository. It is not the recommended global install path.

## Basic Workflow

1. **Choose the route**
   Fast path for trivial local work, troubleshooting for incidents, full planning flow for meaningful changes.

2. **Apply mandatory gates**
   `safety-validator` for risky commands, `evidence-first-reporting` for precise status, `verification-before-completion` before any success claim.

3. **Use the smallest workflow that fits**
   `test-driven-operation` for small safe work, or `brainstorming-operations` → `writing-operation-plans` → `subagent-driven-operation`/`executing-operation-plans` for larger changes.

4. **`finishing-operation-branch`**  
   Wraps up the branch cleanly after the operational work and verification are complete.

## Reference

### Mandatory Gates

| Skill | Purpose |
|------|---------|
| `verification-before-completion` | Evidence before any completion claim |
| `safety-validator` | Command safety gate for risky work |
| `evidence-first-reporting` | Separate observation, inference, and unknowns in reports |

### Workflow Skills

| Skill | Purpose |
|------|---------|
| `brainstorming-operations` | Design the operation before acting |
| `writing-operation-plans` | Create step-by-step execution plans |
| `subagent-driven-operation` | Run plan tasks with reviewed subagent execution |
| `executing-operation-plans` | Run long plans with checkpoints |
| `test-driven-operation` | Verification-first infrastructure changes |
| `verification-before-completion` | Evidence before claims |
| `finishing-operation-branch` | Clean completion workflow |

### Operational Support

| Category | Representative Skills |
|----------|-----------------------|
| Incident response | `systematic-troubleshooting`, `incident-commander`, `post-mortem-writer`, `pcap-analysis` |
| Safety and delivery | `safety-validator`, `progressive-delivery`, `observability-integration` |
| Infra administration | `pve-admin`, `puppet-code-analyzer`, `puppet-merge-request`, `gitlab-ecr-pipeline` |
| SRE practices | `sre-runbook`, `toil-analysis`, `cost-optimizer`, `environment-health-check` |
| Domain expertise | Kubernetes, Terraform, Terragrunt, containers, networking, security, observability, PostgreSQL, Go, Python, Rust |

### SRE Principles

| Principle | Meaning |
|-----------|---------|
| Safety First | Dry-run and preview before risky changes |
| Structured Output | Fixed schemas for plans, investigations, and reports |
| Evidence-Driven | Prefer command output over agent claims |
| Audit-Ready | Make changes traceable and reversible |
| Communication | Keep updates technically precise and readable |

### Security Focus

SREPowers emphasizes least privilege, explicit rollback paths, secure secret handling, and post-change verification. High-risk operations should route through `safety-validator` before execution, and status reporting should keep observations distinct from inference.

## Explanation

### Why SREPowers Exists

Infrastructure failures usually come from rushed operations, weak verification, or success claims based on exit codes instead of observed state. SREPowers exists to make the agent behave more like a careful operator: define success first, constrain the blast radius, and verify after every meaningful change.

### Workflow Diagram

```text
Need infrastructure change
          |
          v
+---------------------------+
| brainstorming-operations  |
+---------------------------+
          |
          v
+---------------------------+
| writing-operation-plans   |
+---------------------------+
          |
          v
   +-------------------+
   | choose execution  |
   +-------------------+
      |             |
      v             v
+----------------+ +-------------------------+
| subagent-      | | executing-operation-    |
| driven-        | | plans                   |
| operation      | +-------------------------+
+----------------+
      \             /
       \           /
        v         v
     +----------------------+
     | test-driven-         |
     | operation            |
     +----------------------+
               |
               v
     +----------------------+
     | verification-before- |
     | completion           |
     +----------------------+
               |
               v
     +----------------------+
     | finishing-operation- |
     | branch               |
     +----------------------+
```

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Follow the existing skill format and repository conventions.
4. Run the relevant tests in `tests/`.
5. Submit a pull request.

## License

MIT License. See [LICENSE](LICENSE).

Last Updated: 2026-04-26
