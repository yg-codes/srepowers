# Available Skills

## Plugin: srepowers-core (47 skills)

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
| `srepowers-core:verification-guardrails` | Mechanical PreToolUse hook blocking shell idioms that make a gate lie (comm && echo PASS, $? after a pipe, sudo globs, denylisted errors, unmatchable greps); ships an opt-in Stop hook for unsourced state claims |
| `srepowers-core:evidence-first-reporting` | When reporting findings, handoffs, status, or incident updates with mixed evidence and inference risk |

### Core Operation Workflow
| Skill | Use When |
|-------|----------|
| `srepowers-core:brainstorming-operations` | Starting any operation — design before executing |
| `srepowers-core:writing-operation-plans` | You have a design, need a detailed execution plan |
| `srepowers-core:executing-operation-plans` | Running a written plan in a separate session with checkpoints |
| `srepowers-core:subagent-driven-operation` | Running a written plan with fresh subagents per task (raw fan-out → dispatching-parallel-agents-sre) |
| `srepowers-core:test-driven-operation` | Executing individual infrastructure operations with verification (code TDD → srepowers-swe:tdd) |
| `srepowers-core:finishing-operation-branch` | Operation complete, ready to merge/PR (body via srepowers-swe:pr) |

### Safety and Review
| Skill | Use When |
|-------|----------|
| `srepowers-core:requesting-review-sre` | Dispatching a reviewer before merging an infra change |
| `srepowers-core:receiving-code-review-sre` | Processing code review feedback on infra changes |
| `srepowers-core:code-reviewer` | PR reviews, code quality audits (security audits → security-reviewer; feedback handling → receiving-code-review-sre) |
| `srepowers-core:environment-health-check` | Verifying SREPowers environment is configured |
| `srepowers-core:cache-cleanup` | Interactive cleanup of dev tool caches (mise, npm, Go, Cargo, uv, pipx, pip) with pre/post verification that tools still work |

### Incident Response
| Skill | Use When |
|-------|----------|
| `srepowers-core:incident-commander` | Coordinating major infrastructure incidents |
| `srepowers-core:systematic-troubleshooting` | Root cause analysis for incidents or failures (code bugs → srepowers-swe:diagnosing-bugs) |
| `srepowers-core:post-mortem-writer` | Writing blameless post-mortems |
| `srepowers-core:pcap-analysis` | Network packet capture investigation with tshark |

### Parallel and Workflow Tools
| Skill | Use When |
|-------|----------|
| `srepowers-core:dispatching-parallel-agents-sre` | 2+ independent infrastructure tasks to fan out (plan execution with review gates → subagent-driven-operation) |
| `srepowers-core:using-git-worktrees-sre` | Isolated workspace for operations |
| `srepowers-core:writing-skills-sre` | Creating or editing skills in this repo's plugins (generic skill-creator covers other ecosystems) |
| `srepowers-core:playground-tutorial` | Learning SREPowers for the first time |

### SRE Practices
| Skill | Use When |
|-------|----------|
| `srepowers-core:sre-engineer` | SLI/SLO, error budgets, reliability |
| `srepowers-core:sre-runbook` | Creating structured runbooks |
| `srepowers-core:sre-readme` | Creating or updating repository READMEs (Structure framework: How-to, Reference, Explanation) |
| `srepowers-core:toil-analysis` | Identifying and reducing operational toil |
| `srepowers-core:feasibility-report` | Go/no-go decision document before planning or CCB — TELOS assessment, 2–3 options with do-nothing baseline, blast radius, rollback feasibility |
| `srepowers-core:observability-integration` | Metrics/traces/logs verification |
| `srepowers-core:observability-engineer` | Setting up observability stacks |
| `srepowers-core:progressive-delivery` | Canary, blue-green deployments |
| `srepowers-core:devops-engineer` | CI/CD, containers, IaC — generalist entry; depth via kubernetes-specialist / container-engineer / gitlab-cicd |
| `srepowers-core:wizard` | Console-only human procedures (vendor portals, cert rotation, CI secrets, cutovers) |
| `srepowers-core:wait-what` | Re-pitch a message that did not land — plain technical English |
| `srepowers-core:humanizer` | Strip AI writing patterns from a deliverable before it ships — inflated significance, rule of three, em-dash overuse, filler; also voice matching. Not for code |
| `srepowers-core:ops-brief` | Operator wants action-first output — next command first, no preamble |
| `srepowers-core:tzstamp` | Dual UTC/local stamps for timelines, post-mortems, reports — no bare timestamps |
| `srepowers-core:handoff` | Capturing in-flight work for continuation by a fresh session or agent — verified repo state, redacted secrets, identity-pinned, per-task file (completed-work record → session-log) |
| `srepowers-core:session-log` | Appending a timestamped changelog entry to a project's SESSIONLOG.md at session end |
| `srepowers-core:memory-lint` | Integrity check on a file-based memory store (frontmatter, index, links, PII) |
| `srepowers-core:skill-test-runner` | Run a fixture against a skill in a sub-agent — PASS/FAIL with scored assertions |
| `srepowers-core:skill-iterate` | Loop the runner until a skill passes (max 5 cycles), restoring on failure |
| `srepowers-core:fixture-lint` | Validate a skill-test fixture before running it (golden-vs-assertion invariant) |
| `srepowers-core:md-to-html` | Convert a Markdown file to standalone HTML and open it rendered — WSL routes to the Windows default browser |
| `srepowers-core:pdf-to-md` | Convert PDFs to Markdown via a local docling + RapidOCR stack — better table/OCR accuracy than generic PDF libraries |

---

## Plugin: srepowers-infra (12 skills)

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
| `srepowers-infra:splunk-curl-search` | Read-only Splunk REST search via curl — front-door detection, linted/bounded SPL |

**GitLab CI family** — pick the most specific skill; each handles a distinct
pipeline shape and cross-references the others. Not duplicates.

| Skill | Use When |
|-------|----------|
| `srepowers-infra:gitlab-cicd` | Base: `.gitlab-ci.yml` authoring, runners, pipeline debugging |
| `srepowers-infra:gitlab-ecr-pipeline` | Specialization: build/mirror container images → AWS ECR |
| `srepowers-infra:goreleaser-pipeline` | Specialization: Go binary cross-compile/release via GoReleaser |

---

