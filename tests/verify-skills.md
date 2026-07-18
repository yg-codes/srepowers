# SREPowers Skills Verification Guide

This guide covers both Claude Code compatibility and Codex-native use. Use `tests/claude-code/` for Claude wrapper validation and `tests/codex/` for Codex packaging and repo-surface validation.

## Test Commands for Each Skill

### Meta-Skill

#### 1. Using-SREPowers

```
# Test: Start a new session
# The meta-skill should auto-inject via hooks

# Expected behavior:
# 1. Session-start hook runs
# 2. using-srepowers content injected as context
# 3. Claude knows about all SRE skills
# 4. Red flags table available for reference
```

### Mandatory Gates

#### 2. Verification Before Completion

```
# Test: Claim completion without verification
"I just deployed the ConfigMap. It's definitely working."

# Expected behavior:
# 1. Claude invokes verification-before-completion skill
# 2. Asks for verification command
# 3. Runs command and shows evidence
# 4. Only then allows claim
```

#### 3. Safety Validator

```
# Test: Propose a risky command
"I need to run kubectl delete namespace production --context prod"

# Expected behavior:
# 1. Claude invokes safety-validator skill
# 2. Classifies risk level
# 3. Proposes safer alternative or additional flags
# 4. Requires explicit approval before executing
```

#### 4. Evidence-First Reporting

```
# Test: Report findings
"Summarize what you found about the DNS issue."

# Expected behavior:
# 1. Claude invokes evidence-first-reporting skill
# 2. Separates observed evidence from inference
# 3. Labels unknowns explicitly
# 4. Structures report with Evidence / Inference / Unknowns / Next Steps
```

### Core Operation Workflow

#### 5. Brainstorming Operations

```
# Test: Plan a new operation
"I need to migrate our Keycloak setup to use CRDs. Use brainstorming-operations to design this."

# Expected behavior:
# 1. Claude announces: "I'm using the brainstorming-operations skill"
# 2. Asks questions one at a time about:
#    - Current infrastructure state
#    - Desired state
#    - Risk level
#    - Rollback strategy
# 3. Presents design in sections for validation
# 4. Saves design to docs/plans/YYYY-MM-DD-*.md
```

#### 6. Writing Operation Plans

```
# Test: Create an execution plan
"Create an execution plan for deploying nginx to production with 3 replicas. Use writing-operation-plans."

# Expected behavior:
# 1. Claude announces: "I'm using the writing-operation-plans skill"
# 2. Creates detailed plan with:
#    - Exact verification commands
#    - Expected outputs
#    - Rollback steps
#    - TDO discipline for each task
# 3. Saves to docs/plans/YYYY-MM-DD-*.md
```

#### 7. Executing Operation Plans

```
# Test: Execute a written plan
"I have an operation plan at docs/plans/test-plan.md. Execute it with the executing-operation-plans skill."

# Expected behavior:
# 1. Claude reads the plan
# 2. Executes tasks sequentially with checkpoints
# 3. Runs verification commands after each task
# 4. Pauses for review at defined checkpoints
```

#### 8. Subagent-Driven Operation (SDO)

```
# Test: Ask Claude to execute a plan with SDO
"I have an operation plan at docs/plans/test-plan.md. Use subagent-driven-operation to execute it."

# Expected behavior:
# 1. Claude announces: "I'm using the subagent-driven-operation skill"
# 2. Reads plan once, extracts all tasks
# 3. For each task:
#    - Dispatches operator subagent
#    - Executes operations with TDO
#    - Runs one task review returning spec + quality verdicts
#    - Loops until approved
```

#### 9. Test-Driven Operation (TDO)

```
# Test: Ask Claude to use TDO for a simple operation
"I need to create a Kubernetes ConfigMap in the production namespace. Use the test-driven-operation skill."

# Expected behavior:
# 1. Claude announces: "I'm using the test-driven-operation skill"
# 2. Writes RED verification command first
# 3. Runs verification and confirms it fails
# 4. Applies ConfigMap (GREEN)
# 5. Runs verification and confirms it passes
```

#### 10. Finishing Operation Branch

```
# Test: Complete an operation
"The operation is done and verified. Use finishing-operation-branch to wrap up."

# Expected behavior:
# 1. Claude invokes finishing-operation-branch skill
# 2. Reviews verification results
# 3. Suggests merge or PR approach
# 4. Cleans up worktree if applicable
```

### Safety and Review

#### 11. Receiving Code Review SRE

```
# Test: Process code review feedback
"A reviewer says my Hiera change should use lookup() instead of hiera_hash(). What should I do?"

# Expected behavior:
# 1. Claude invokes receiving-code-review-sre skill
# 2. Evaluates feedback on technical merit
# 3. Verifies claim before implementing
# 4. Does not blindly agree or implement without verification
```

#### 12. Environment Health Check

```
# Test: Verify environment
"Check that all SREPowers tools are available before we start."

# Expected behavior:
# 1. Claude invokes environment-health-check skill
# 2. Checks for kubectl, terraform, aws CLI, etc.
# 3. Reports which tools are available
# 4. Flags missing tools before operations begin
```

### Incident Response

#### 13. Incident Commander

```
# Test: Coordinate a major incident
"We have a production outage affecting the payment service. Use incident-commander to coordinate."

# Expected behavior:
# 1. Claude invokes incident-commander skill
# 2. Establishes incident structure (IC, Comms, Tech Lead)
# 3. Tracks timeline and actions
# 4. Coordinates communication
```

#### 14. Systematic Troubleshooting

```
# Test: Root cause analysis
"The API is returning 503 errors intermittently. Use systematic-troubleshooting to investigate."

# Expected behavior:
# 1. Claude invokes systematic-troubleshooting skill
# 2. Follows 4-phase approach (scope, hypothesize, test, conclude)
# 3. Rules out causes systematically
# 4. Documents evidence chain
```

#### 15. Post-Mortem Writer

```
# Test: Write a post-mortem
"Write a blameless post-mortem for the payment service outage that lasted 45 minutes."

# Expected behavior:
# 1. Claude invokes post-mortem-writer skill
# 2. Structures with timeline, root cause, impact
# 3. Includes action items with owners
# 4. Follows blameless format
```

#### 16. SRE Runbook

```
# Test: Create a runbook
"Create an SRE runbook for restarting the nginx service on production servers."

# Expected behavior:
# 1. Claude invokes sre-runbook skill
# 2. Creates structured runbook with:
#    - Pre-requisites
#    - Procedures with Command/Expected/Result format
#    - Verification steps
#    - Rollback procedures
#    - Troubleshooting section
```

### Parallel and Workflow Tools

#### 17. Dispatching Parallel Agents SRE

```
# Test: Parallel agent dispatch
"I need to check the health of 5 different clusters simultaneously. Use dispatching-parallel-agents-sre."

# Expected behavior:
# 1. Claude invokes dispatching-parallel-agents-sre skill
# 2. Identifies independent tasks
# 3. Dispatches subagents in parallel
# 4. Aggregates results
```

#### 18. Using Git Worktrees SRE

```
# Test: Create a worktree
"I need to work on this operation in isolation. Use using-git-worktrees-sre."

# Expected behavior:
# 1. Claude invokes using-git-worktrees-sre skill
# 2. Creates isolated worktree
# 3. Verifies environment in worktree
# 4. Provides instructions for switching back
```

#### 19. Writing Skills SRE

```
# Test: Create a new skill
"I need to create a new skill for managing AWS Lambda functions. Use writing-skills-sre."

# Expected behavior:
# 1. Claude invokes writing-skills-sre skill
# 2. Creates SKILL.md with proper frontmatter
# 3. Creates command wrapper
# 4. Follows project conventions
```

#### 20. Playground Tutorial

```
# Test: Learn SREPowers
"I'm new to SREPowers. Show me how it works."

# Expected behavior:
# 1. Claude invokes playground-tutorial skill
# 2. Walks through TDO workflow safely
# 3. Uses non-destructive examples
# 4. Explains each step
```

### SRE Practices

#### 21. SRE Engineer

```
# Test: SLO definition
"Define SLIs and SLOs for our payment processing service. Use sre-engineer."

# Expected behavior:
# 1. Claude invokes sre-engineer skill
# 2. Defines meaningful SLIs
# 3. Sets appropriate SLO targets
# 4. Establishes error budget policies
```

#### 22. Toil Analysis

```
# Test: Identify toil
"We spend 10 hours a week manually restarting failed pods. Analyze this toil."

# Expected behavior:
# 1. Claude invokes toil-analysis skill
# 2. Categorizes toil (type, frequency, duration)
# 3. Identifies automation candidates
# 4. Proposes reduction strategies
```

#### 23. Observability Integration

```
# Test: Verify metrics
"Verify that our new service has proper monitoring in Prometheus and Grafana."

# Expected behavior:
# 1. Claude invokes observability-integration skill
# 2. Checks metrics are being collected
# 3. Verifies dashboards exist
# 4. Validates alerting rules
```

#### 24. Observability Engineer

```
# Test: Set up observability
"Design an observability stack with Prometheus, Grafana, and OpenTelemetry for our Kubernetes cluster."

# Expected behavior:
# 1. Claude invokes observability-engineer skill
# 2. Proposes metrics, logging, and tracing architecture
# 3. Creates dashboard templates
# 4. Defines SLO-based alerting
```

#### 25. Progressive Delivery

```
# Test: Canary deployment
"Set up a canary deployment for our API service with automatic rollback."

# Expected behavior:
# 1. Claude invokes progressive-delivery skill
# 2. Defines canary strategy with traffic shifting
# 3. Sets up monitoring for canary health
# 4. Configures rollback triggers
```

#### 26. Chaos Engineer

```
# Test: Design chaos experiment
"Design a chaos experiment to test our Kubernetes cluster's resilience to node failures. Use chaos-engineer."

# Expected behavior:
# 1. Claude invokes chaos-engineer skill
# 2. Defines hypothesis, blast radius, steady state
# 3. Plans failure injection approach
# 4. Includes rollback and abort criteria
```

### Platform and Infrastructure

#### 27. Kubernetes Specialist

```
# Test: K8s security hardening
"Harden the RBAC configuration for our production Kubernetes cluster. Use kubernetes-specialist."

# Expected behavior:
# 1. Claude invokes kubernetes-specialist skill
# 2. Reviews RBAC policies
# 3. Applies least-privilege principle
# 4. Configures NetworkPolicies
```

#### 28. Terraform Engineer

```
# Test: Terraform module
"Create a reusable Terraform module for an AWS VPC with subnets. Use terraform-engineer."

# Expected behavior:
# 1. Claude invokes terraform-engineer skill
# 2. Creates module with variables and outputs
# 3. Follows module best practices
# 4. Includes state management considerations
```

#### 29. Terragrunt Expert

```
# Test: Terragrunt orchestration
"Set up a Terragrunt stack for multi-environment Terraform deployment. Use terragrunt-expert."

# Expected behavior:
# 1. Claude invokes terragrunt-expert skill
# 2. Creates DRY Terragrunt configurations
# 3. Sets up dependency management
# 4. Configures remote state backends
```

#### 30. Platform Engineer

```
# Test: Internal developer platform
"Design an internal developer platform with self-service infrastructure provisioning."

# Expected behavior:
# 1. Claude invokes platform-engineer skill
# 2. Proposes golden paths for common workflows
# 3. Considers service catalog design
# 4. Addresses developer experience concerns
```

#### 31. DevOps Engineer

```
# Test: CI/CD pipeline setup
"Set up a CI/CD pipeline for a Node.js application with Docker. Use devops-engineer."

# Expected behavior:
# 1. Claude invokes devops-engineer skill
# 2. Creates pipeline configuration
# 3. Includes build, test, deploy stages
# 4. Containerization with Docker
```

#### 32. GitLab ECR Pipeline

```
# Test: Create pipeline
"Create a GitLab CI/CD pipeline to build and push a container image to AWS ECR."

# Expected behavior:
# 1. Claude invokes gitlab-ecr-pipeline skill
# 2. Asks about build type (build vs mirror)
# 3. Generates .gitlab-ci.yml with:
#    - ECR authentication
#    - Build stage
#    - Push stage
#    - Proper tagging
```

#### 33. Container Engineer

```
# Test: Container optimization
"Optimize this Dockerfile for production use with security hardening."

# Expected behavior:
# 1. Claude invokes container-engineer skill
# 2. Suggests multi-stage build
# 3. Recommends distroless or minimal base image
# 4. Adds security scanning (trivy/grype)
```

#### 34. Network Engineer

```
# Test: Network troubleshooting
"Investigate why pods in different namespaces cannot communicate. Use network-engineer."

# Expected behavior:
# 1. Claude invokes network-engineer skill
# 2. Analyzes NetworkPolicy configuration
# 3. Checks VPC and subnet routing
# 4. Proposes DNS and load balancing fixes
```

#### 35. PVE Admin

```
# Test: Proxmox administration
"How do I check the health of my Proxmox cluster? Use pve-admin."

# Expected behavior:
# 1. Claude invokes pve-admin skill
# 2. Shows cluster health check commands
# 3. References check-pve-cluster.sh helper script
# 4. Covers: node status, storage, network, services
```

#### 36. PVE VLAN Trunk Troubleshooting

```
# Test: VLAN trunk debugging
"A VM on VLAN 227 cannot reach the network on pve-node02. Use pve-vlan-trunk-troubleshooting."

# Expected behavior:
# 1. Claude invokes pve-vlan-trunk-troubleshooting skill
# 2. Tests VLAN reachability from the PVE host
# 3. Checks upstream switch trunk config
# 4. Compares bridge config between nodes
```

#### 37. Puppet Code Analyzer

```
# Test: Analyze Puppet code
"Analyze the Puppet module at ~/src/fsx/puppet/modules/my_module for code quality."

# Expected behavior:
# 1. Claude invokes puppet-code-analyzer skill
# 2. Runs linting with puppet-lint
# 3. Analyzes dependencies
# 4. Checks best practices
# 5. Generates report with recommendations
```

#### 38. Puppet Merge Request

```
# Test: Create Puppet MR
"Create a merge request for the cu_infra_1234_splunk branch in control/infra."

# Expected behavior:
# 1. Claude invokes puppet-merge-request skill
# 2. Validates branch name
# 3. Pre-checks for conflicts
# 4. Creates MRs using glab CLI
```

#### 39. PCAP Analysis

```
# Test: Analyze packet capture
"Analyze /var/tmp/dns_err.pcap for DNS resolution failures."

# Expected behavior:
# 1. Claude invokes pcap-analysis skill
# 2. Starts with summary stats (scope, time range)
# 3. Extracts DNS fields as TSV
# 4. Identifies failures using CLI tools
# 5. Deep-inspects specific frames only
```

### Architecture and Cloud

#### 40. Architecture Designer

```
# Test: Design system architecture
"I need to design a microservices architecture for an e-commerce platform. Use architecture-designer."

# Expected behavior:
# 1. Claude invokes architecture-designer skill
# 2. Discusses design patterns and trade-offs
# 3. Considers scalability, reliability, maintainability
# 4. May suggest creating an ADR
```

#### 41. Cloud Architect

```
# Test: Cloud architecture design
"Design a multi-region deployment on AWS following the Well-Architected Framework. Use cloud-architect."

# Expected behavior:
# 1. Claude invokes cloud-architect skill
# 2. Addresses all WAF pillars
# 3. Covers DR, cost optimization, security
# 4. Proposes landing zone structure
```

#### 42. Microservices Architect

```
# Test: Service decomposition
"Decompose our monolithic order system into microservices. Use microservices-architect."

# Expected behavior:
# 1. Claude invokes microservices-architect skill
# 2. Identifies bounded contexts
# 3. Defines service boundaries
# 4. Proposes communication patterns (sync/async)
```

#### 43. Cost Optimizer

```
# Test: Cloud cost analysis
"Analyze our AWS bill and identify cost reduction opportunities."

# Expected behavior:
# 1. Claude invokes cost-optimizer skill
# 2. Identifies top cost drivers
# 3. Suggests right-sizing for over-provisioned resources
# 4. Proposes reserved instance or savings plan strategy
```

### Languages and Development

#### 44. Golang Pro

```
# Test: Go concurrency
"Implement a worker pool pattern in Go with error handling. Use golang-pro."

# Expected behavior:
# 1. Claude invokes golang-pro skill
# 2. Uses goroutines and channels
# 3. Implements proper error handling
# 4. Follows Go best practices
```

#### 45. Python Pro

```
# Test: Python async programming
"Implement an async HTTP client with proper type hints and error handling. Use python-pro."

# Expected behavior:
# 1. Claude invokes python-pro skill
# 2. Uses async/await with aiohttp
# 3. Adds comprehensive type hints
# 4. Follows Python best practices
```

#### 46. Rust Engineer

```
# Test: Rust ownership patterns
"Implement a thread-safe cache in Rust with proper lifetime management. Use rust-engineer."

# Expected behavior:
# 1. Claude invokes rust-engineer skill
# 2. Uses proper ownership and borrowing
# 3. Implements Send + Sync traits
# 4. Uses Arc/Mutex for thread safety
```

#### 47. PostgreSQL Engineer

```
# Test: Query optimization
"Optimize this slow PostgreSQL query using EXPLAIN ANALYZE."

# Expected behavior:
# 1. Claude invokes postgresql-engineer skill
# 2. Analyzes query plan
# 3. Suggests index improvements
# 4. Recommends VACUUM/ANALYZE if needed
```

### Security and Quality

#### 48. Security Reviewer

```
# Test: Security audit
"Conduct a security review of our cloud infrastructure configuration. Use security-reviewer."

# Expected behavior:
# 1. Claude invokes security-reviewer skill
# 2. Performs SAST-style analysis
# 3. Checks infrastructure security
# 4. Generates findings report
```

#### 49. Secure Code Guardian

```
# Test: Security hardening
"Review this login form for OWASP Top 10 vulnerabilities. Use secure-code-guardian."

# Expected behavior:
# 1. Claude invokes secure-code-guardian skill
# 2. Checks for injection, XSS, CSRF
# 3. Validates authentication flow
# 4. Recommends security improvements
```

#### 50. Code Reviewer

```
# Test: Review code quality
"Review this pull request for code quality and security issues. Use code-reviewer."

# Expected behavior:
# 1. Claude invokes code-reviewer skill
# 2. Checks for security vulnerabilities
# 3. Evaluates code quality and readability
# 4. Provides actionable feedback
```

#### 51. Code Documenter

```
# Test: Create API documentation
"Generate OpenAPI documentation for our REST API endpoints. Use code-documenter."

# Expected behavior:
# 1. Claude invokes code-documenter skill
# 2. Creates structured API documentation
# 3. Uses OpenAPI/Swagger format
# 4. Includes examples and schemas
```

#### 52. Test Master

```
# Test: Test strategy
"Create a comprehensive testing strategy for our microservices. Use test-master."

# Expected behavior:
# 1. Claude invokes test-master skill
# 2. Covers test pyramid (unit, integration, E2E)
# 3. Defines coverage targets
# 4. Includes performance and security testing
```

## Command Wrappers Test

```bash
# Test each /command — Core workflow
claude -p "/using-srepowers"
claude -p "/brainstorming-operations"
claude -p "/writing-operation-plans"
claude -p "/executing-operation-plans"
claude -p "/subagent-driven-operation"
claude -p "/test-driven-operation"
claude -p "/finishing-operation-branch"

# Test each /command — Mandatory gates
claude -p "/verification-before-completion"
claude -p "/safety-validator"
claude -p "/evidence-first-reporting"

# Test each /command — Safety and review
claude -p "/receiving-code-review-sre"
claude -p "/environment-health-check"

# Test each /command — Incident and troubleshooting
claude -p "/incident-commander"
claude -p "/systematic-troubleshooting"
claude -p "/post-mortem-writer"
claude -p "/sre-runbook"

# Test each /command — Parallel and workflow tools
claude -p "/dispatching-parallel-agents-sre"
claude -p "/using-git-worktrees-sre"
claude -p "/writing-skills-sre"
claude -p "/playground-tutorial"

# Test each /command — SRE practices
claude -p "/sre-engineer"
claude -p "/toil-analysis"
claude -p "/observability-integration"
claude -p "/observability-engineer"
claude -p "/progressive-delivery"
claude -p "/chaos-engineer"

# Test each /command — Infrastructure administration
claude -p "/kubernetes-specialist"
claude -p "/terraform-engineer"
claude -p "/terragrunt-expert"
claude -p "/platform-engineer"
claude -p "/devops-engineer"
claude -p "/gitlab-ecr-pipeline"
claude -p "/container-engineer"
claude -p "/network-engineer"
claude -p "/pve-admin"
claude -p "/pve-vlan-trunk-troubleshooting"
claude -p "/puppet-code-analyzer"
claude -p "/puppet-merge-request"
claude -p "/pcap-analysis"

# Test each /command — Architecture and cloud
claude -p "/architecture-designer"
claude -p "/cloud-architect"
claude -p "/microservices-architect"
claude -p "/cost-optimizer"

# Test each /command — Languages and development
claude -p "/golang-pro"
claude -p "/python-pro"
claude -p "/rust-engineer"
claude -p "/postgresql-engineer"

# Test each /command — Security and quality
claude -p "/security-reviewer"
claude -p "/secure-code-guardian"
claude -p "/code-reviewer"
claude -p "/code-documenter"
claude -p "/test-master"
```

## Infrastructure-Specific Verification Tests

### Kubernetes Test
```
"Use test-driven-operation to deploy a nginx pod with label app=nginx in the default namespace."
```

### API Test
```
"Use test-driven-operation to make a GET request to https://api.github.com and verify it returns JSON."
```

### Git Test
```
"Use test-driven-operation to create a new branch called test_branch."
```

## Common Issues to Check

1. **Skills don't load:**
   - Check you're running from srepowers directory
   - Verify plugin is in `~/.claude/plugins/`
   - Check `~/.claude/settings.json` has plugin enabled

2. **Hooks don't fire:**
   - Check `hooks/hooks.json` exists
   - Verify `hooks/session-start` and `hooks/run-hook.cmd` are executable
   - Check Claude Code version supports hooks

3. **Tests fail:**
   - Ensure Claude Code CLI is installed
   - Check network connectivity
   - Run with `--verbose` flag for details

## Full Test Session Example

```bash
# 1. Clone/fresh checkout
cd /tmp
git clone https://github.com/yg-codes/srepowers.git
cd srepowers

# 2. Run test suite
./tests/claude-code/run-skill-tests.sh --verbose

# 3. Start interactive session
claude

# 4. In Claude, test each skill:
# - "List all srepowers skills"
# - "Use test-driven-operation to create a ConfigMap"
# - "Use brainstorming-operations to plan a deployment"
# - "/sre-runbook for restarting nginx"
# - "/pve-admin check cluster health"
# - "/container-engineer optimize Dockerfile"
# - "/pcap-analysis investigate dns_err.pcap"
# - "/puppet-merge-request create MR for cu_infra branch"
# - etc.

# 5. Check hooks fired
# (using-srepowers should be in context automatically)
```

## Success Criteria

- All tests pass: `./tests/claude-code/run-skill-tests.sh`
- All 52 skills load when prompted
- All 52 commands invoke correct skills
- Hooks inject meta-skill on session start
- Each skill demonstrates its workflow correctly
