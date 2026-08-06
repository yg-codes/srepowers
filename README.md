# SREPowers

SRE + software-engineering skills for Claude Code and Codex.

SREPowers adapts software development workflows like brainstorming, planning, subagent execution, and verification-first discipline to infrastructure operations. It is the SRE companion to [superpowers](https://github.com/obra/superpowers): same workflow spine, different domain and risk model. Since v5.9.0 it also ships an **opt-in** `srepowers-swe` plugin — a general software-engineering flow (spec → tickets, domain modeling, codebase design, prototyping, teaching) that stays separate from the SRE spine.

## How It Works

SREPowers starts by slowing the agent down before it does infrastructure work. Instead of jumping straight to `kubectl`, Terraform, or API calls, it pushes the agent to clarify the goal, write an execution plan, and define verification before making changes.

Once the plan is approved, the execution skills apply Test-Driven Operation: define verification before execution, capture a failing check when the target state is absent or broken, capture a baseline when the current state is already valid, make the smallest change, and verify again. For larger changes, SREPowers can break the work into reviewed subagent steps so execution stays aligned with the plan.

The result is not "more automation." The value is disciplined operations under pressure: verification before claims, rollback-aware planning, and explicit review of risky changes.

## Relationship to Superpowers

SREPowers uses Superpowers as a methodology reference, not as a strict downstream clone. It follows upstream for plugin layout, skill format, planning discipline, reviewed subagent execution, and evidence before success claims.

It intentionally diverges for infrastructure operations: routing is risk-based, production/destructive actions require safety gates, incident response has its own workflow, and TDO means verification-first rather than always failing-first. Baseline capture, blast radius, rollback, evidence, and change-control context are first-class requirements.

The `subagent-driven-operation` skill ships its SDD file-handoff scripts (`task-brief`, `review-package`, `sdd-workspace`) under a srepowers-namespaced `.srepowers/sdd/` workspace in the working tree — never under `.git/`, which Claude Code treats as a protected path. `tests/claude-code/test-sdd-workspace.sh` locks in that the workspace is self-ignoring, that the handoff scripts write into it, and that a linked git worktree resolves its own distinct workspace.

The Codex `SessionStart` bootstrap hook matches `startup|clear|compact` — not `resume` — so resuming a Codex session does not re-fire the bootstrap, while context compaction still re-injects it (superpowers v6.1.0 parity, upstream `879ae59`). Each packaged Codex plugin manifest declares `"hooks": {}` to suppress Codex's auto-discovery of `hooks/hooks.json`: without that declaration, Codex falls back to registering `plugins/srepowers-core/hooks/hooks.json` (the Claude Code hook) on every install (superpowers v6.1.1 parity, upstream `7d8d3d4`). `tests/codex/run-skill-tests.sh` asserts both invariants.

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
| Planned multi-step change | `brainstorming-operations` -> `writing-operation-plans` -> execution skill |
| Small known-safe local change | `test-driven-operation` fast path |
| Read-only review or diagnosis | Domain skill + `evidence-first-reporting` |
| Risky or production command set | Add `safety-validator` before execution |

### Fast Path

Use the fast path only for low-risk, read-only, or single-file/local-only work with exact local validation. It skips full planning, but it does not skip validation or evidence.

## Plugin Structure

SREPowers is distributed as a marketplace containing five plugins, each with its own skills and commands.

```
srepowers/
├── .claude-plugin/marketplace.json     ← lists all 5 plugins
├── plugins/
│   ├── srepowers-core/                 ← 32 skills
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .codex-plugin/plugin.json
│   │   ├── skills/
│   │   ├── commands/
│   │   └── hooks/
│   ├── srepowers-domain/               ← 21 skills
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .codex-plugin/plugin.json
│   │   ├── skills/
│   │   └── commands/
│   ├── srepowers-infra/                ← 11 skills (portable)
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .codex-plugin/plugin.json
│   │   ├── skills/
│   │   └── commands/
│   ├── srepowers-private/              ← 6 skills (sanitized site templates)
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .codex-plugin/plugin.json
│   │   ├── skills/
│   │   └── commands/
│   └── srepowers-swe/                  ← 12 skills (general software engineering)
│       ├── .claude-plugin/plugin.json
│       ├── .codex-plugin/plugin.json
│       ├── skills/
│       └── commands/
├── .agents/skills/                     ← Codex skill mirror (82 symlinks)
├── .codex/skills/                      ← Codex repo-native symlinks
├── .codex/agents/                      ← Codex custom agents
├── .codex-plugin/                      ← Codex plugin manifest
├── docs/, tests/, evals/, scripts/     ← shared resources
└── README.md, LICENSE, AGENTS.md
```

| Plugin | Skills | Focus |
|--------|--------|-------|
| `srepowers-core` | 32 | Workflow spine, mandatory gates, incident response, SRE practices |
| `srepowers-domain` | 21 | Software engineering depth: Go, Python, Rust, K8s, Terraform, containers, networking, security, testing, databases |
| `srepowers-infra` | 11 | Portable infrastructure administration: Proxmox VE, Puppet code analysis, PuppetDB queries, DNS, TLS/PKI, backup/recovery, change management, GitLab CI/CD (incl. ECR & GoReleaser) |
| `srepowers-private` | 6 | Site-specific operational workflows (sanitized templates): Puppet deploy/release/MR lifecycle, Hiera debugging, Ansible — substitute placeholders with your environment's values |
| `srepowers-swe` | 12 | General software-engineering flow (opt-in): spec→tickets, backlog triage, wayfinding, domain modeling, codebase design, architecture improvement, prototyping, teaching, project onboarding |

Marketplace install pulls all five at once. Each plugin can also be installed individually if you only need a subset.

## What's Inside

| Path | Purpose |
|------|---------|
| `plugins/*/skills/` | Skill definitions, grouped by plugin |
| `plugins/*/commands/` | Claude compatibility wrappers for `/command` usage |
| `.claude-plugin/marketplace.json` | Marketplace manifest listing all plugins |
| `plugins/*/.codex-plugin/plugin.json` | Codex plugin manifests for marketplace installation |
| `.agents/skills/` | Codex skill mirror for repo-native discovery |
| `.codex-plugin/` | Codex plugin manifest |
| `.codex/agents/` | Codex custom infrastructure agents |
| `tests/` | Claude and Codex validation scripts |

## Installation

### Claude Code Marketplace

```bash
/plugin marketplace add yg-codes/srepowers
/plugin install srepowers-core@srepowers-marketplace
/plugin install srepowers-domain@srepowers-marketplace
/plugin install srepowers-infra@srepowers-marketplace
/plugin install srepowers-private@srepowers-marketplace
/plugin install srepowers-swe@srepowers-marketplace
```

Or install all five at once:

```bash
/plugin install srepowers-core@srepowers-marketplace srepowers-domain@srepowers-marketplace srepowers-infra@srepowers-marketplace srepowers-private@srepowers-marketplace srepowers-swe@srepowers-marketplace
```

Verify with `/help`. You should see commands such as `/test-driven-operation` and `/subagent-driven-operation`.

### Claude Code Manual Installation

```bash
git clone https://github.com/yg-codes/srepowers.git ~/.claude/plugins/srepowers
```

### Codex Marketplace Install

This is the recommended Codex setup. Add the SREPowers marketplace, then install the plugins from Codex's `/plugins` UI.

1. Add the marketplace.

```bash
codex plugin marketplace add yg-codes/srepowers
```

2. Open Codex and launch the plugin UI.

```text
/plugins
```

3. Search for `srepowers`, then install one or more plugins:

- `srepowers-core` — workflow spine, mandatory gates, incident response
- `srepowers-domain` — Go, Python, Rust, Kubernetes, Terraform, security, testing, and other domain skills
- `srepowers-infra` — portable Proxmox, Puppet analysis, DNS, TLS, backup, and GitLab CI/CD skills
- `srepowers-private` — sanitized site-specific Puppet/Hiera/Ansible workflow templates
- `srepowers-swe` — general software-engineering flow (opt-in): spec→tickets, backlog triage, wayfinding, domain modeling, codebase design, prototyping, teaching

Install all five for full SREPowers coverage.

4. Verify installed skills.

```text
/skills
```

You should see skills such as `using-srepowers`, `test-driven-operation`, `kubernetes-specialist`, and `pve-admin`.

Update:

```bash
codex plugin marketplace upgrade srepowers-marketplace
```

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

### Codex Local Marketplace Development

Use this only when testing local repository changes before they are pushed.

1. Add the local checkout as a marketplace.

```bash
codex plugin marketplace add /path/to/srepowers
```

For this repository checkout:

```bash
codex plugin marketplace add /home/yg/src/github/srepowers
```

2. Open `/plugins`, search for `srepowers`, and install the local plugin entries.

When local files change, restart Codex or run:

```bash
codex plugin marketplace upgrade srepowers-marketplace
```

## Basic Workflow

1. **Choose the route**
   Fast path for trivial local work, troubleshooting for incidents, full planning flow for meaningful changes.

2. **Apply mandatory gates**
   `safety-validator` for risky commands, `evidence-first-reporting` for precise status, `verification-before-completion` before any success claim.

3. **Use the smallest workflow that fits**
   `test-driven-operation` for small safe work, or `brainstorming-operations` -> `writing-operation-plans` -> `subagent-driven-operation`/`executing-operation-plans` for larger changes.

4. **`finishing-operation-branch`**
   Wraps up the branch cleanly after the operational work and verification are complete.

## Reference

### Mandatory Gates (core)

| Skill | Purpose |
|------|---------|
| `verification-before-completion` | Evidence before any completion claim |
| `safety-validator` | Command safety gate for risky work |
| `evidence-first-reporting` | Separate observation, inference, and unknowns in reports |

### Workflow Skills (core)

| Skill | Purpose |
|------|---------|
| `brainstorming-operations` | Design the operation before acting |
| `writing-operation-plans` | Create step-by-step execution plans |
| `subagent-driven-operation` | Run plan tasks with reviewed subagent execution — file handoffs (task briefs, review packages, reports) and a durable progress ledger keep the controller's context lean across long operations |
| `executing-operation-plans` | Run long plans with checkpoints |
| `test-driven-operation` | Verification-first infrastructure changes |
| `finishing-operation-branch` | Clean completion workflow |

### Incident Response (core)

| Skill | Purpose |
|------|---------|
| `systematic-troubleshooting` | 4-phase root cause analysis |
| `incident-commander` | Major incident coordination |
| `post-mortem-writer` | Blameless post-mortems |
| `pcap-analysis` | Network packet capture investigation |

### Operational Support (core)

| Skill | Purpose |
|------|---------|
| `sre-runbook` | Structured runbook generation |
| `toil-analysis` | Toil identification and reduction |
| `progressive-delivery` | Canary and blue-green deployments |
| `observability-integration` | Metric and alerting verification |
| `observability-engineer` | Observability stack setup |
| `sre-engineer` | SLO/SLI and error budget management |
| `environment-health-check` | Verify SREPowers environment |
| `playground-tutorial` | First-time SREPowers onboarding |
| `dispatching-parallel-agents-sre` | Parallel SRE agent dispatch |
| `using-git-worktrees-sre` | Isolated git worktrees for ops |
| `code-reviewer` | PR reviews and code quality |
| `receiving-code-review-sre` | Process code review feedback |
| `devops-engineer` | CI/CD, containers, and IaC |
| `writing-skills-sre` | Create and edit SRE skills |
| `using-srepowers` | Meta-skill: how to find and use skills |

### Domain Expertise (domain)

| Skill | Domain |
|------|--------|
| `golang-pro` | Go: concurrency, generics, gRPC |
| `python-pro` | Python: type hints, async, pytest |
| `rust-engineer` | Rust: ownership, lifetimes, async |
| `kubernetes-specialist` | K8s: Helm, RBAC, storage, security |
| `terraform-engineer` | Terraform: modules, state, multi-env |
| `terragrunt-expert` | Terragrunt: DRY configs, stacks |
| `container-engineer` | Containers: builds, security, registries |
| `network-engineer` | Networking: VPC, DNS, load balancing |
| `security-reviewer` | Security: audits, SAST, DevSecOps |
| `secure-code-guardian` | AppSec: auth, OWASP Top 10 |
| `test-master` | Testing: unit, integration, E2E |
| `cost-optimizer` | FinOps: right-sizing, reserved capacity |
| `postgresql-engineer` | PostgreSQL: queries, replication, tuning |
| `architecture-designer` | Architecture: design patterns, ADRs |
| `microservices-architect` | Distributed systems: DDD, sagas |
| `chaos-engineer` | Resilience: failure injection, game days |
| `cloud-architect` | Cloud: migrations, Well-Architected |
| `platform-engineer` | IDP: Backstage, golden paths |
| `code-documenter` | Documentation: API specs, doc portals |
| `linux-admin` | Linux system administration and operations |

### Infrastructure Administration (infra)

| Skill | Purpose |
|------|---------|
| `pve-admin` | Proxmox VE/PBS: cluster, VM/CT, ZFS, HA |
| `pve-vlan-trunk-troubleshooting` | PVE VLAN trunk debugging |
| `puppet-code-analyzer` | Puppet code quality analysis |
| `puppet-fact-query` | PuppetDB host inventory queries (read-only) |
| `puppet-merge-request` | Puppet control repo MR creation |
| `puppet-deploy` | Puppet environment deployment workflow |
| `puppet-release` | Puppet module release process |
| `puppet-module-init` | Puppet module scaffolding and initialization |
| `gitlab-ecr-pipeline` | GitLab CI/CD to AWS ECR |
| `ansible-operations` | Ansible playbook development and execution |
| `hiera-debugging` | Debugging Puppet Hiera data resolution |
| `dns-operations` | DNS administration and troubleshooting |
| `gitlab-cicd` | GitLab CI/CD pipeline authoring and debugging |
| `certificate-management` | TLS/SSL certificate lifecycle management |
| `backup-and-recovery` | Backup strategy and disaster recovery |
| `change-management` | Change control board processes and procedures |
| `goreleaser-pipeline` | GoReleaser pipeline setup and releases |

### Software Engineering (swe)

| Skill | Purpose |
|------|---------|
| `to-spec` | Turn a conversation into a spec (PRD) |
| `to-tickets` | Split a spec into tracer-bullet tickets |
| `backlog-triage` | Backlog/issue triage (not incident triage) |
| `wayfinder` | Chart decision tickets for a foggy, multi-session effort |
| `domain-modeling` | Sharpen domain vocabulary; record ADRs |
| `codebase-design` | Deep-module design: interface, seam, depth |
| `improve-codebase-architecture` | Survey deepening opportunities as an HTML report |
| `prototype` | Throwaway code to answer a design question |
| `grilling` | Sharpen an idea by interview, one question at a time |
| `teach` | Learn a concept over multiple sessions |
| `project-onboarding` | Configure tracker + label vocabulary the swe skills need |

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
