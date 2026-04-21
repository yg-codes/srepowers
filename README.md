# SREPowers

SRE infrastructure skills for Claude Code and Codex.

SREPowers adapts software development workflows like brainstorming, planning, subagent execution, and verification-first discipline to infrastructure operations. It is the SRE companion to [superpowers](https://github.com/obra/superpowers): same workflow spine, different domain.

## How It Works

SREPowers starts by slowing the agent down before it does infrastructure work. Instead of jumping straight to `kubectl`, Terraform, or API calls, it pushes the agent to clarify the goal, write an execution plan, and define verification before making changes.

Once the plan is approved, the execution skills apply Test-Driven Operation: write a verification command, watch it fail, make the smallest change, and verify again. For larger changes, SREPowers can break the work into reviewed subagent steps so execution stays aligned with the plan.

The result is not “more automation.” The value is disciplined operations under pressure: verification before claims, rollback-aware planning, and explicit review of risky changes.

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

1. **`brainstorming-operations`**  
   Refines the operation goal, environment, risk, rollback, and success criteria before implementation.

2. **`writing-operation-plans`**  
   Turns the design into bite-sized steps with exact commands, verification checks, and rollback instructions.

3. **`subagent-driven-operation`** or **`executing-operation-plans`**  
   Executes the plan either with reviewed subagent steps or with checkpointed batches for longer operations.

4. **`test-driven-operation`**  
   Enforces the RED/GREEN loop for infrastructure work: verification first, change second, verification again.

5. **`verification-before-completion`**  
   Blocks “done” claims until fresh command output shows the expected result.

6. **`finishing-operation-branch`**  
   Wraps up the branch cleanly after the operational work and verification are complete.

Supporting skills such as `safety-validator`, `systematic-troubleshooting`, `observability-integration`, and `incident-commander` plug into this spine when the situation demands them.

## Reference

### Core Workflow Skills

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
| Incident response | `systematic-troubleshooting`, `incident-commander`, `post-mortem-writer` |
| Safety and delivery | `safety-validator`, `progressive-delivery`, `observability-integration` |
| Infra administration | `pve-admin`, `puppet-code-analyzer`, `gitlab-ecr-pipeline` |
| SRE practices | `sre-runbook`, `toil-analysis`, `cost-optimizer`, `environment-health-check` |
| Domain expertise | Kubernetes, Terraform, Terragrunt, containers, networking, security, observability, PostgreSQL, Go, Python, Rust |

### SRE Principles

| Principle | Meaning |
|-----------|---------|
| Safety First | Dry-run and preview before risky changes |
| Structured Output | Pre-check, execute, verify |
| Evidence-Driven | Prefer command output over agent claims |
| Audit-Ready | Make changes traceable and reversible |
| Communication | Keep updates technically precise and readable |

### Security Focus

SREPowers emphasizes least privilege, explicit rollback paths, secure secret handling, and post-change verification. High-risk operations should route through `safety-validator` before execution.

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

Last Updated: 2026-04-21
