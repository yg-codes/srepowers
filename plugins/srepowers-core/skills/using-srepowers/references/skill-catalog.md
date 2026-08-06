# Available Skills

## Plugin: srepowers-core (32 skills)

SRE workflow spine, mandatory gates, and incident response.

### Meta-Skill (Always Active)
| Skill | Use When |
|-------|----------|
| `srepowers-core:using-srepowers` | Auto-injected at session start; routes work through minimum sufficient workflow |

### Mandatory Gates
| Skill | Use When |
|-------|----------|
| `srepowers-core:verification-before-completion` | Before claiming anything is done, fixed, healthy, or verified |
| `srepowers-core:safety-validator` | Before risky, destructive, broad-scope, or production commands |
| `srepowers-core:git-guardrails` | Mechanical PreToolUse hook blocking force-push, reset --hard, clean -f, branch -D, checkout/restore ., add -A/., --no-verify |
| `srepowers-core:evidence-first-reporting` | When reporting findings, handoffs, status, or incident updates with mixed evidence and inference risk |

### Core Operation Workflow
| Skill | Use When |
|-------|----------|
| `srepowers-core:brainstorming-operations` | Starting any operation — design before executing |
| `srepowers-core:writing-operation-plans` | You have a design, need a detailed execution plan |
| `srepowers-core:executing-operation-plans` | Running a written plan in a separate session with checkpoints |
| `srepowers-core:subagent-driven-operation` | Running a written plan with fresh subagents per task |
| `srepowers-core:test-driven-operation` | Executing individual infrastructure operations with verification |
| `srepowers-core:finishing-operation-branch` | Operation complete, ready to merge/PR |

### Safety and Review
| Skill | Use When |
|-------|----------|
| `srepowers-core:requesting-review-sre` | Dispatching a reviewer before merging an infra change |
| `srepowers-core:receiving-code-review-sre` | Processing code review feedback on infra changes |
| `srepowers-core:code-reviewer` | PR reviews, code quality audits |
| `srepowers-core:environment-health-check` | Verifying SREPowers environment is configured |

### Incident Response
| Skill | Use When |
|-------|----------|
| `srepowers-core:incident-commander` | Coordinating major infrastructure incidents |
| `srepowers-core:systematic-troubleshooting` | Root cause analysis for incidents or failures |
| `srepowers-core:post-mortem-writer` | Writing blameless post-mortems |
| `srepowers-core:pcap-analysis` | Network packet capture investigation with tshark |

### Parallel and Workflow Tools
| Skill | Use When |
|-------|----------|
| `srepowers-core:dispatching-parallel-agents-sre` | 2+ independent infrastructure problems |
| `srepowers-core:using-git-worktrees-sre` | Isolated workspace for operations |
| `srepowers-core:writing-skills-sre` | Creating or editing SRE skills |
| `srepowers-core:playground-tutorial` | Learning SREPowers for the first time |

### SRE Practices
| Skill | Use When |
|-------|----------|
| `srepowers-core:sre-engineer` | SLI/SLO, error budgets, reliability |
| `srepowers-core:sre-runbook` | Creating structured runbooks |
| `srepowers-core:toil-analysis` | Identifying and reducing operational toil |
| `srepowers-core:observability-integration` | Metrics/traces/logs verification |
| `srepowers-core:observability-engineer` | Setting up observability stacks |
| `srepowers-core:progressive-delivery` | Canary, blue-green deployments |
| `srepowers-core:devops-engineer` | CI/CD, containers, IaC |
| `srepowers-core:wizard` | Console-only human procedures (vendor portals, cert rotation, CI secrets, cutovers) |
| `srepowers-core:wait-what` | Re-pitch a message that did not land — plain technical English |

---

## Plugin: srepowers-domain (21 skills)

Software engineering domain expertise.

### Architecture and Cloud
| Skill | Use When |
|-------|----------|
| `srepowers-domain:architecture-designer` | System architecture design |
| `srepowers-domain:cloud-architect` | Cloud architecture and migrations |
| `srepowers-domain:aws-account-inspection` | Read-only AWS account audit / resource discovery + Well-Architected scorecard |
| `srepowers-domain:microservices-architect` | Distributed systems design |
| `srepowers-domain:platform-engineer` | Internal developer platforms |
| `srepowers-domain:cost-optimizer` | Cloud cost optimization |

### Infrastructure Platforms
| Skill | Use When |
|-------|----------|
| `srepowers-domain:kubernetes-specialist` | K8s deployments, cluster management |
| `srepowers-domain:terraform-engineer` | IaC with Terraform |
| `srepowers-domain:terragrunt-expert` | Terragrunt module orchestration |
| `srepowers-domain:container-engineer` | Container builds and security |
| `srepowers-domain:network-engineer` | Cloud and hybrid networking |
| `srepowers-domain:linux-admin` | Linux system administration and operations |

### Languages
| Skill | Use When |
|-------|----------|
| `srepowers-domain:golang-pro` | Go application development |
| `srepowers-domain:python-pro` | Python 3.11+ development |
| `srepowers-domain:rust-engineer` | Rust systems programming |
| `srepowers-domain:postgresql-engineer` | PostgreSQL operations |

### Security and Quality
| Skill | Use When |
|-------|----------|
| `srepowers-domain:security-reviewer` | Security audits |
| `srepowers-domain:secure-code-guardian` | Application security |
| `srepowers-domain:chaos-engineer` | Chaos experiments, resilience testing |
| `srepowers-domain:test-master` | Testing strategy |
| `srepowers-domain:code-documenter` | API documentation |

---

## Plugin: srepowers-infra (11 skills)

Portable infrastructure administration — no organization-specific values.

| Skill | Use When |
|-------|----------|
| `srepowers-infra:pve-admin` | Proxmox VE/PBS administration |
| `srepowers-infra:pve-vlan-trunk-troubleshooting` | Debugging PVE VLAN trunk connectivity |
| `srepowers-infra:puppet-code-analyzer` | Puppet code quality analysis |
| `srepowers-infra:puppet-fact-query` | Querying PuppetDB for host inventories by OS, environment, or custom facts |
| `srepowers-infra:dns-operations` | DNS administration and troubleshooting |
| `srepowers-infra:certificate-management` | TLS/SSL certificate lifecycle management |
| `srepowers-infra:backup-and-recovery` | Backup strategy and disaster recovery |
| `srepowers-infra:change-management` | Change control board processes and procedures |

**GitLab CI family** — pick the most specific skill; each handles a distinct
pipeline shape and cross-references the others. Not duplicates.

| Skill | Use When |
|-------|----------|
| `srepowers-infra:gitlab-cicd` | Base: `.gitlab-ci.yml` authoring, runners, pipeline debugging |
| `srepowers-infra:gitlab-ecr-pipeline` | Specialization: build/mirror container images → AWS ECR |
| `srepowers-infra:goreleaser-pipeline` | Specialization: Go binary cross-compile/release via GoReleaser |

---

## Plugin: srepowers-private (6 skills)

Site-specific operational workflows, shipped as **sanitized templates**.
Substitute placeholders (`<puppet-master>`, `<host>`, `site-a`/`site-b`
prefixes, `<TICKET-ID>`) with your environment's values — those belong in your
project `CLAUDE.md`, not in the skill.

**Puppet lifecycle family** — complementary phases of one cross-repo workflow,
not duplicates. Typical order: init → analyze → release → merge-request →
deploy; debug Hiera at any point.

| Skill | Use When |
|-------|----------|
| `srepowers-private:puppet-module-init` | Start a ticket: topic branch, dev context, doc skeleton |
| `srepowers-private:puppet-release` | Tag module, bump Puppetfile, promote through env chain |
| `srepowers-private:puppet-merge-request` | Create control-repo MRs for the sit → uat → prod chain |
| `srepowers-private:puppet-deploy` | Run noop/apply across hosts or fleets; classify exit codes |
| `srepowers-private:hiera-debugging` | Trace why a Hiera key resolves to an unexpected value |
| `srepowers-private:ansible-operations` | Ansible playbook development, inventory, vault, execution |

## Plugin: srepowers-swe (11 skills)

General software-engineering skill surface — the idea → ship flow for
building software, opt-in and separate from the SRE spine. Configure the
project first with `srepowers-swe:project-onboarding` so the tracker and label
vocabulary the other swe skills assume are in place.

**Idea → ship pipeline** — sharpen, specify, split, build:

| Skill | Use When |
|-------|----------|
| `srepowers-swe:grilling` | Sharpen an idea or plan by interview, one question at a time ("grill me") |
| `srepowers-swe:domain-modeling` | Pin down the domain vocabulary; record hard-to-reverse decisions as ADRs |
| `srepowers-swe:to-spec` | Turn the current conversation into a spec (PRD) — synthesis, no interview |
| `srepowers-swe:to-tickets` | Split a spec into tracer-bullet tickets on the issue tracker |
| `srepowers-swe:prototype` | Throwaway code to answer a state-model or UI design question |

**On-ramps and codebase upkeep:**

| Skill | Use When |
|-------|----------|
| `srepowers-swe:backlog-triage` | Sort a *backlog* of incoming issues/PRs (not incident triage) |
| `srepowers-swe:wayfinder` | Chart a shared map of decision tickets for a foggy, multi-session effort |
| `srepowers-swe:improve-codebase-architecture` | Survey deepening opportunities as a visual HTML report |
| `srepowers-swe:codebase-design` | Design a module's shape — deep modules, seams (internal, not system architecture) |

**Learning and setup:**

| Skill | Use When |
|-------|----------|
| `srepowers-swe:teach` | Learn a concept over multiple sessions using a stateful workspace |
| `srepowers-swe:project-onboarding` | Configure the issue tracker + label vocabulary the swe skills depend on (run first) |
