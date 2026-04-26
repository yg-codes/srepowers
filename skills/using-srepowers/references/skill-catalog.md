# Available Skills

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
| `srepowers:environment-health-check` | Verifying SREPowers environment is configured |

> Note: `verification-before-completion`, `safety-validator`, and `evidence-first-reporting` are listed in Mandatory Gates above.

### Incident Response
| Skill | Use When |
|-------|----------|
| `srepowers:incident-commander` | Coordinating major infrastructure incidents |
| `srepowers:systematic-troubleshooting` | Root cause analysis for incidents or failures |
| `srepowers:post-mortem-writer` | Writing blameless post-mortems |
| `srepowers:sre-runbook` | Creating structured runbooks |

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
| `srepowers:toil-analysis` | Identifying and reducing operational toil |
| `srepowers:observability-integration` | Metrics/traces/logs verification |
| `srepowers:observability-engineer` | Setting up observability stacks |
| `srepowers:progressive-delivery` | Canary, blue-green deployments |
| `srepowers:chaos-engineer` | Chaos experiments, resilience testing |

### Platform and Infrastructure
| Skill | Use When |
|-------|----------|
| `srepowers:kubernetes-specialist` | K8s deployments, cluster management |
| `srepowers:terraform-engineer` | IaC with Terraform |
| `srepowers:terragrunt-expert` | Terragrunt module orchestration |
| `srepowers:platform-engineer` | Internal developer platforms |
| `srepowers:devops-engineer` | CI/CD, containers, IaC |
| `srepowers:gitlab-ecr-pipeline` | GitLab CI/CD → AWS ECR |
| `srepowers:container-engineer` | Container builds and security |
| `srepowers:network-engineer` | Cloud and hybrid networking |
| `srepowers:pve-admin` | Proxmox VE/PBS administration |
| `srepowers:pve-vlan-trunk-troubleshooting` | Debugging PVE VLAN trunk connectivity |
| `srepowers:puppet-code-analyzer` | Puppet code quality analysis |
| `srepowers:puppet-merge-request` | Creating Puppet control repo merge requests |
| `srepowers:pcap-analysis` | Network packet capture investigation with tshark |

### Architecture and Cloud
| Skill | Use When |
|-------|----------|
| `srepowers:architecture-designer` | System architecture design |
| `srepowers:cloud-architect` | Cloud architecture and migrations |
| `srepowers:microservices-architect` | Distributed systems design |
| `srepowers:cost-optimizer` | Cloud cost optimization |

### Languages and Development
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
| `srepowers:code-reviewer` | PR reviews, code quality |
| `srepowers:code-documenter` | API documentation |
| `srepowers:test-master` | Testing strategy |
