# Available Skills

## Plugin: srepowers-core (28 skills)

SRE workflow spine, mandatory gates, and incident response.

### Meta-Skill (Always Active)
| Skill | Use When |
|-------|----------|
| `srepowers:using-srepowers` | Auto-injected at session start; routes work through minimum sufficient workflow |

### Mandatory Gates
| Skill | Use When |
|-------|----------|
| `srepowers:verification-before-completion` | Before claiming anything is done, fixed, healthy, or verified |
| `srepowers:safety-validator` | Before risky, destructive, broad-scope, or production commands |
| `srepowers:evidence-first-reporting` | When reporting findings, handoffs, status, or incident updates with mixed evidence and inference risk |

### Core Operation Workflow
| Skill | Use When |
|-------|----------|
| `srepowers:brainstorming-operations` | Starting any operation — design before executing |
| `srepowers:writing-operation-plans` | You have a design, need a detailed execution plan |
| `srepowers:executing-operation-plans` | Running a written plan in a separate session with checkpoints |
| `srepowers:subagent-driven-operation` | Running a written plan with fresh subagents per task |
| `srepowers:test-driven-operation` | Executing individual infrastructure operations with verification |
| `srepowers:finishing-operation-branch` | Operation complete, ready to merge/PR |

### Safety and Review
| Skill | Use When |
|-------|----------|
| `srepowers:receiving-code-review-sre` | Processing code review feedback on infra changes |
| `srepowers:code-reviewer` | PR reviews, code quality audits |
| `srepowers:environment-health-check` | Verifying SREPowers environment is configured |

### Incident Response
| Skill | Use When |
|-------|----------|
| `srepowers:incident-commander` | Coordinating major infrastructure incidents |
| `srepowers:systematic-troubleshooting` | Root cause analysis for incidents or failures |
| `srepowers:post-mortem-writer` | Writing blameless post-mortems |
| `srepowers:pcap-analysis` | Network packet capture investigation with tshark |

### Parallel and Workflow Tools
| Skill | Use When |
|-------|----------|
| `srepowers:dispatching-parallel-agents-sre` | 2+ independent infrastructure problems |
| `srepowers:using-git-worktrees-sre` | Isolated workspace for operations |
| `srepowers:writing-skills-sre` | Creating or editing SRE skills |
| `srepowers:playground-tutorial` | Learning SREPowers for the first time |

### SRE Practices
| Skill | Use When |
|-------|----------|
| `srepowers:sre-engineer` | SLI/SLO, error budgets, reliability |
| `srepowers:sre-runbook` | Creating structured runbooks |
| `srepowers:toil-analysis` | Identifying and reducing operational toil |
| `srepowers:observability-integration` | Metrics/traces/logs verification |
| `srepowers:observability-engineer` | Setting up observability stacks |
| `srepowers:progressive-delivery` | Canary, blue-green deployments |
| `srepowers:devops-engineer` | CI/CD, containers, IaC |

---

## Plugin: srepowers-domain (20 skills)

Software engineering domain expertise.

### Architecture and Cloud
| Skill | Use When |
|-------|----------|
| `srepowers:architecture-designer` | System architecture design |
| `srepowers:cloud-architect` | Cloud architecture and migrations |
| `srepowers:microservices-architect` | Distributed systems design |
| `srepowers:platform-engineer` | Internal developer platforms |
| `srepowers:cost-optimizer` | Cloud cost optimization |

### Infrastructure Platforms
| Skill | Use When |
|-------|----------|
| `srepowers:kubernetes-specialist` | K8s deployments, cluster management |
| `srepowers:terraform-engineer` | IaC with Terraform |
| `srepowers:terragrunt-expert` | Terragrunt module orchestration |
| `srepowers:container-engineer` | Container builds and security |
| `srepowers:network-engineer` | Cloud and hybrid networking |
| `srepowers:linux-admin` | Linux system administration and operations |

### Languages
| Skill | Use When |
|-------|----------|
| `srepowers:golang-pro` | Go application development |
| `srepowers:python-pro` | Python 3.11+ development |
| `srepowers:rust-engineer` | Rust systems programming |
| `srepowers:postgresql-engineer` | PostgreSQL operations |

### Security and Quality
| Skill | Use When |
|-------|----------|
| `srepowers:security-reviewer` | Security audits |
| `srepowers:secure-code-guardian` | Application security |
| `srepowers:chaos-engineer` | Chaos experiments, resilience testing |
| `srepowers:test-master` | Testing strategy |
| `srepowers:code-documenter` | API documentation |

---

## Plugin: srepowers-infra (10 skills)

Portable infrastructure administration — no organization-specific values.

| Skill | Use When |
|-------|----------|
| `srepowers:pve-admin` | Proxmox VE/PBS administration |
| `srepowers:pve-vlan-trunk-troubleshooting` | Debugging PVE VLAN trunk connectivity |
| `srepowers:puppet-code-analyzer` | Puppet code quality analysis |
| `srepowers:puppet-fact-query` | Querying PuppetDB for host inventories by OS, environment, or custom facts |
| `srepowers:dns-operations` | DNS administration and troubleshooting |
| `srepowers:certificate-management` | TLS/SSL certificate lifecycle management |
| `srepowers:backup-and-recovery` | Backup strategy and disaster recovery |
| `srepowers:change-management` | Change control board processes and procedures |

**GitLab CI family** — pick the most specific skill; each handles a distinct
pipeline shape and cross-references the others. Not duplicates.

| Skill | Use When |
|-------|----------|
| `srepowers:gitlab-cicd` | Base: `.gitlab-ci.yml` authoring, runners, pipeline debugging |
| `srepowers:gitlab-ecr-pipeline` | Specialization: build/mirror container images → AWS ECR |
| `srepowers:goreleaser-pipeline` | Specialization: Go binary cross-compile/release via GoReleaser |

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
| `srepowers:puppet-module-init` | Start a ticket: topic branch, dev context, doc skeleton |
| `srepowers:puppet-release` | Tag module, bump Puppetfile, promote through env chain |
| `srepowers:puppet-merge-request` | Create control-repo MRs for the sit → uat → prod chain |
| `srepowers:puppet-deploy` | Run noop/apply across hosts or fleets; classify exit codes |
| `srepowers:hiera-debugging` | Trace why a Hiera key resolves to an unexpected value |
| `srepowers:ansible-operations` | Ansible playbook development, inventory, vault, execution |
