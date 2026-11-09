# SREPowers

> **Public edition:** this distribution ships `srepowers-core` and `srepowers-infra`. The `srepowers-domain`, `srepowers-private` (site templates), and `srepowers-swe` plugins are separate distributions; references to them describe the full distribution.


SRE + software-engineering skills for Claude Code and Codex.

SREPowers adapts software development workflows like brainstorming, planning, subagent execution, and verification-first discipline to infrastructure operations. It is the SRE companion to [superpowers](https://github.com/obra/superpowers): same workflow spine, different domain and risk model. Since v5.9.0 the full distribution (not this edition) also includes an **opt-in** `srepowers-swe` plugin — a general software-engineering flow (spec → tickets, domain modeling, codebase design, prototyping, teaching) that stays separate from the SRE spine.

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

SREPowers is distributed as a marketplace containing 2 plugins, each with its own skills and commands.

```
srepowers/
├── .claude-plugin/marketplace.json     ← lists the edition's plugins
├── plugins/
│   ├── srepowers-core/                 ← 47 skills
│   │   ├── .claude-plugin/plugin.json
│   │   ├── .codex-plugin/plugin.json
│   │   ├── skills/
│   │   ├── commands/
│   │   └── hooks/
│   └── srepowers-infra/                 ← 12 skills
│       ├── .claude-plugin/plugin.json
│       ├── .codex-plugin/plugin.json
│       ├── skills/
│       └── commands/
├── .agents/skills/                     ← Codex skill mirror (59 symlinks)
├── .codex/skills/                      ← Codex repo-native symlinks
├── .codex/agents/                      ← Codex custom agents
├── .codex-plugin/                      ← Codex plugin manifest
├── tests/, scripts/                    ← shared resources
├── evals/fixtures/                     ← skill-test fixtures
└── README.md, LICENSE
```

| Plugin | Skills | Focus |
|--------|--------|-------|
| `srepowers-core` | 47 | Workflow spine, mandatory gates, incident response, SRE practices |
| `srepowers-infra` | 12 | Portable infrastructure administration: Proxmox VE, Puppet code analysis, PuppetDB queries, DNS, TLS/PKI, backup/recovery, change management, GitLab CI/CD (incl. ECR & GoReleaser), Splunk search |

Marketplace install pulls all plugins at once. Each plugin can also be installed individually if you only need a subset.

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
/plugin install srepowers-infra@srepowers-marketplace
```

Or install them all at once:

```bash
/plugin install srepowers-core@srepowers-marketplace srepowers-infra@srepowers-marketplace
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
- `srepowers-infra` — portable Proxmox, Puppet analysis, DNS, TLS, backup, GitLab CI/CD, and Splunk search skills

Install all plugins for full SREPowers coverage.

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
| `brainstorming-operations` | Design the operation before acting — probe/bounded/architectural routing scales ceremony with risk |
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
| `sre-readme` | Structured README generation (How-to / Reference / Explanation) |
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
| `requesting-review-sre` | Dispatch a reviewer subagent with crafted context before merge |
| `devops-engineer` | CI/CD, containers, and IaC |
| `writing-skills-sre` | Create and edit SRE skills |
| `git-guardrails` | Mechanical git-safety enforcement (shipped PreToolUse guard hook) |
| `verification-guardrails` | Mechanical verification-discipline enforcement (shipped guards) |
| `wizard` | Interactive bash wizard for human-only console steps |
| `wait-what` | Re-pitch a message that did not land |
| `ops-brief` | Action-first output mode ("adhd mode" for ops) — next command first, safety before brevity |
| `tzstamp` | Dual UTC/local timestamps for timelines and reports (ships `scripts/tzstamp.py`) |
| `memory-lint` | Integrity check on a file-based memory store (ships `scripts/memory_lint.py` + tests) |
| `session-log` | Append a timestamped session changelog to a project's SESSIONLOG.md |
| `skill-test-runner` | Run a fixture against a skill in a sub-agent — PASS/FAIL with scored assertions |
| `skill-iterate` | Loop the runner until a skill passes (max 5 cycles), restoring on failure |
| `fixture-lint` | Validate a skill-test fixture before running it (ships `scripts/fixture_lint.py` + tests) |
| `md-to-html` | Convert a Markdown file to standalone HTML and open it rendered — WSL routes to the Windows default browser (ships `scripts/md_to_html.py` + tests) |
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
| `aws-account-inspection` | AWS: read-only account audit and discovery |

### Infrastructure Administration (infra)

| Skill | Purpose |
|------|---------|
| `pve-admin` | Proxmox VE/PBS: cluster, VM/CT, ZFS, HA |
| `pve-vlan-trunk-troubleshooting` | PVE VLAN trunk debugging |
| `puppet-code-analyzer` | Puppet code quality analysis |
| `puppet-fact-query` | PuppetDB host inventory queries (read-only) |
| `dns-operations` | DNS administration and troubleshooting |
| `gitlab-cicd` | GitLab CI/CD pipeline authoring and debugging |
| `gitlab-ecr-pipeline` | GitLab CI/CD to AWS ECR |
| `goreleaser-pipeline` | GoReleaser pipeline setup and releases |
| `certificate-management` | TLS/SSL certificate lifecycle management |
| `backup-and-recovery` | Backup strategy and disaster recovery |
| `change-management` | Change control board processes and procedures |

### Site Templates (private)

Sanitized site-specific workflow templates — substitute the placeholders with your environment's values.

| Skill | Purpose |
|------|---------|
| `puppet-module-init` | Start a Puppet ticket: module scaffolding and initialization |
| `puppet-merge-request` | Puppet control repo MR creation |
| `puppet-deploy` | Puppet environment deployment workflow |
| `puppet-release` | Puppet module release process |
| `hiera-debugging` | Debugging Puppet Hiera data resolution |
| `ansible-operations` | Ansible playbook development and execution |
| `clickup-ticket-searcher` | Search ClickUp: my tickets, queues, CCB state (read-only) |
| `clickup-ticket-creator` | Author CCB-format ClickUp tickets |
| `infra-gitlab-sync` | Rsync GitLab source repos to GitHub mirrors, history-preserving |

### Software Engineering (swe)

| Skill | Purpose |
|------|---------|
| `to-spec` | Turn a conversation into a spec (PRD) |
| `to-tickets` | Split a spec into tracer-bullet tickets |
| `to-questionnaire` | Gather info you lack from someone who has it |
| `backlog-triage` | Backlog/issue triage (not incident triage) |
| `wayfinder` | Chart decision tickets for a foggy, multi-session effort |
| `domain-modeling` | Sharpen domain vocabulary; record ADRs |
| `codebase-design` | Deep-module design: interface, seam, depth |
| `improve-codebase-architecture` | Survey deepening opportunities as an HTML report |
| `prototype` | Throwaway code to answer a design question |
| `grilling` | Sharpen an idea by interview, one question at a time |
| `teach` | Learn a concept over multiple sessions |
| `project-onboarding` | Configure tracker + label vocabulary the swe skills need |
| `ponytail` | Forces the laziest solution that works — YAGNI, stdlib, one line before fifty |
| `ponytail-review` | Diff review hunting over-engineering only |
| `ponytail-audit` | Whole-repo over-engineering audit — ranked delete/simplify list |
| `ponytail-debt` | Harvest `ponytail:` deferral comments into a debt ledger |

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

## Provenance

Most skills here are original work. SREPowers is **not a fork** of any project:
it shares superpowers' plugin format and workflow spine by adaptation, not
common history. Ported skills are recast — development framing becomes
operational framing — under the upstream licences, with attribution
preserved:

| Upstream | License | What SREPowers adapts | Attribution carried by |
|---|---|---|---|
| [obra/superpowers](https://github.com/obra/superpowers) © Jesse Vincent | MIT | The 14-skill workflow spine recast for operations: `brainstorming-operations`, `writing-operation-plans`, `executing-operation-plans`, `subagent-driven-operation`, `dispatching-parallel-agents-sre`, `using-git-worktrees-sre`, `requesting-review-sre`, `receiving-code-review-sre`, `finishing-operation-branch`, `verification-before-completion`, `test-driven-operation`, `systematic-troubleshooting`, `using-srepowers`, `writing-skills-sre`; partial rows in `code-reviewer` and `test-master`; the `diagnosing-superpowers` method folded into `retro` | `license:` frontmatter + each skill README → Provenance |
| [mattpocock/skills](https://github.com/mattpocock/skills) © Matt Pocock | MIT | The `srepowers-swe` on-ramp (`to-spec`, `to-tickets`, `implement-spec`, `tdd`, `prototype`, `domain-modeling`, `teach`, `to-questionnaire`, `grilling`, `wayfinder`, `codebase-design`, `improve-codebase-architecture`, `diagnosing-bugs`, `backlog-triage` ← `triage`, `retro`, the `pr` base) plus `srepowers-core:wait-what` and `srepowers-core:wizard` | `license:` frontmatter + each skill README |
| [espennilsen/pi](https://github.com/espennilsen/pi), [Codagent-AI/agent-skills](https://github.com/Codagent-AI/agent-skills), [ebaumel/claude-wrapup](https://github.com/ebaumel/claude-wrapup) | MIT | `srepowers-core:handoff` — consolidated three-source port (5.32.0): pi's verify-first workflow as foundation, Codagent's aspect-scoping and cold-reader guardrails, wrapup's decision-capture format | `license:` frontmatter + handoff README → Provenance |
| [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) © DietrichGebert | MIT | `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt` | `license:` frontmatter in each SKILL.md |
| [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) © Ayoub Ghriss | MIT | `srepowers-core:ops-brief` | `license:` frontmatter + skill README |
| [`blader/humanizer`](https://github.com/blader/humanizer) 2.9.1 © Siqi Chen, via a community adaptation | MIT | `srepowers-core:humanizer` | `license:` frontmatter + skill README |
| [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) (MIT) | 4 core skills — `sre-engineer`, `devops-engineer`, `code-reviewer`, `observability-engineer` (upstream `monitoring-expert`) — with references/ carried verbatim, plus 14 unpublished `srepowers-domain` skills | per-skill `LICENSE` + `CREDITS.md` |
| [HumanLayer `show-me`](https://github.com/humanlayer/humanlayer) © 2025-2026 QueryTale, Inc. | **Apache-2.0** | `srepowers-swe:pr` — the Summary menu of visuals, reproduced near-verbatim (the only non-MIT upstream) | `srepowers-swe:pr/CREDITS.md` + Apache-2.0 `LICENSE` in the skill dir |

The `pr` skill's copied menu carries Apache-2.0 obligations (license retained,
changes stated) satisfied by `CREDITS.md` + `LICENSE` in its skill directory;
the pinned source revision is recorded there. Skills named with a `srepowers-swe:`/`srepowers-private:` prefix ship in those plugins, distributed separately from this edition. Every ported skill carries
`license:` frontmatter naming the governing upstream licence, and every
ported skill's README has a Provenance section (or an equivalent origin note)
naming the upstream repository and skill.

Per-skill `CREDITS.md` files for the remaining ported skills are being
completed as part of the public-edition provenance pass
(`docs/plans/2026-10-29-public-edition.md`). Deliberate divergences from
upstream are recorded in `RELEASE-NOTES.md` under each sync. Do not strip or
alter attribution when editing these skills.

## License

MIT License. See [LICENSE](LICENSE).