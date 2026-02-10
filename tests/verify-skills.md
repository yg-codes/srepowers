# SREPowers Skills Verification Guide

## Test Commands for Each Skill

### 1. Test-Driven Operation (TDO)

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

### 2. Subagent-Driven Operation (SDO)

```
# Test: Ask Claude to execute a plan with SDO
"I have an operation plan at docs/plans/test-plan.md. Use subagent-driven-operation to execute it."

# Expected behavior:
# 1. Claude announces: "I'm using the subagent-driven-operation skill"
# 2. Reads plan once, extracts all tasks
# 3. For each task:
#    - Dispatches operator subagent
#    - Executes operations with TDO
#    - Runs spec compliance review
#    - Runs artifact quality review
#    - Loops until approved
```

### 3. Verification Before Completion (VBC)

```
# Test: Claim completion without verification
"I just deployed the ConfigMap. It's definitely working."

# Expected behavior:
# 1. Claude invokes verification-before-completion skill
# 2. Asks for verification command
# 3. Runs command and shows evidence
# 4. Only then allows claim
```

### 4. Brainstorming Operations

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

### 5. Writing Operation Plans

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

### 6. Using-SREPowers (Meta-Skill)

```
# Test: Start a new session
# The meta-skill should auto-inject via hooks

# Expected behavior:
# 1. Session-start hook runs
# 2. using-srepowers content injected as context
# 3. Claude knows about all SRE skills
# 4. Red flags table available for reference
```

### 7. SRE Runbook

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

### 8. PVE Admin

```
# Test: Proxmox administration
"How do I check the health of my Proxmox cluster? Use pve-admin."

# Expected behavior:
# 1. Claude invokes pve-admin skill
# 2. Shows cluster health check commands
# 3. References check-pve-cluster.sh helper script
# 4. Covers: node status, storage, network, services
```

### 9. Puppet Code Analyzer

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

### 10. Cache Cleanup

```
# Test: Clean development caches
"Clean up my Go and npm caches. Use cache-cleanup."

# Expected behavior:
# 1. Claude invokes cache-cleanup skill
# 2. Pre-check: Verifies Go and npm tools work
# 3. Shows cache sizes before cleanup
# 4. Performs cleanup
# 5. Post-check: Verifies tools still work after cleanup
```

### 11. GitLab ECR Pipeline

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

### 12. ClickUp Ticket Creator

```
# Test: Create a ticket
"Create a ClickUp ticket for adding a new load balancer to production."

# Expected behavior:
# 1. Claude invokes clickup-ticket-creator skill
# 2. Structures content with CCB template:
#    - Description, Rationale, Impact, Risk
#    - UAT, Procedure, Verification, Rollback
```

### 13. Architecture Designer

```
# Test: Design system architecture
"I need to design a microservices architecture for an e-commerce platform. Use architecture-designer."

# Expected behavior:
# 1. Claude invokes architecture-designer skill
# 2. Discusses design patterns and trade-offs
# 3. Considers scalability, reliability, maintainability
# 4. May suggest creating an ADR
```

### 14. Chaos Engineer

```
# Test: Design chaos experiment
"Design a chaos experiment to test our Kubernetes cluster's resilience to node failures. Use chaos-engineer."

# Expected behavior:
# 1. Claude invokes chaos-engineer skill
# 2. Defines hypothesis, blast radius, steady state
# 3. Plans failure injection approach
# 4. Includes rollback and abort criteria
```

### 15. Cloud Architect

```
# Test: Cloud architecture design
"Design a multi-region deployment on AWS following the Well-Architected Framework. Use cloud-architect."

# Expected behavior:
# 1. Claude invokes cloud-architect skill
# 2. Addresses all WAF pillars
# 3. Covers DR, cost optimization, security
# 4. Proposes landing zone structure
```

### 16. Code Documenter

```
# Test: Create API documentation
"Generate OpenAPI documentation for our REST API endpoints. Use code-documenter."

# Expected behavior:
# 1. Claude invokes code-documenter skill
# 2. Creates structured API documentation
# 3. Uses OpenAPI/Swagger format
# 4. Includes examples and schemas
```

### 17. Code Reviewer

```
# Test: Review code quality
"Review this pull request for code quality and security issues. Use code-reviewer."

# Expected behavior:
# 1. Claude invokes code-reviewer skill
# 2. Checks for security vulnerabilities
# 3. Evaluates code quality and readability
# 4. Provides actionable feedback
```

### 18. DevOps Engineer

```
# Test: CI/CD pipeline setup
"Set up a CI/CD pipeline for a Node.js application with Docker. Use devops-engineer."

# Expected behavior:
# 1. Claude invokes devops-engineer skill
# 2. Creates pipeline configuration
# 3. Includes build, test, deploy stages
# 4. Containerization with Docker
```

### 19. Golang Pro

```
# Test: Go concurrency
"Implement a worker pool pattern in Go with error handling. Use golang-pro."

# Expected behavior:
# 1. Claude invokes golang-pro skill
# 2. Uses goroutines and channels
# 3. Implements proper error handling
# 4. Follows Go best practices
```

### 20. Kubernetes Specialist

```
# Test: K8s security hardening
"Harden the RBAC configuration for our production Kubernetes cluster. Use kubernetes-specialist."

# Expected behavior:
# 1. Claude invokes kubernetes-specialist skill
# 2. Reviews RBAC policies
# 3. Applies least-privilege principle
# 4. Configures NetworkPolicies
```

### 21. Microservices Architect

```
# Test: Service decomposition
"Decompose our monolithic order system into microservices. Use microservices-architect."

# Expected behavior:
# 1. Claude invokes microservices-architect skill
# 2. Identifies bounded contexts
# 3. Defines service boundaries
# 4. Proposes communication patterns (sync/async)
```

### 22. Monitoring Expert

```
# Test: Observability setup
"Set up a monitoring stack with Prometheus and Grafana for our Kubernetes cluster. Use monitoring-expert."

# Expected behavior:
# 1. Claude invokes monitoring-expert skill
# 2. Configures metrics collection
# 3. Creates dashboards
# 4. Sets up alerting rules
```

### 23. Postgres Pro

```
# Test: Query optimization
"Optimize this slow PostgreSQL query using EXPLAIN ANALYZE. Use postgres-pro."

# Expected behavior:
# 1. Claude invokes postgres-pro skill
# 2. Analyzes query plan
# 3. Suggests index improvements
# 4. Recommends VACUUM/ANALYZE if needed
```

### 24. Prompt Engineer

```
# Test: Prompt design
"Design a chain-of-thought prompt for code review automation. Use prompt-engineer."

# Expected behavior:
# 1. Claude invokes prompt-engineer skill
# 2. Structures prompt with CoT
# 3. Includes few-shot examples
# 4. Suggests evaluation metrics
```

### 25. Python Pro

```
# Test: Python async programming
"Implement an async HTTP client with proper type hints and error handling. Use python-pro."

# Expected behavior:
# 1. Claude invokes python-pro skill
# 2. Uses async/await with aiohttp
# 3. Adds comprehensive type hints
# 4. Follows Python best practices
```

### 26. Rust Engineer

```
# Test: Rust ownership patterns
"Implement a thread-safe cache in Rust with proper lifetime management. Use rust-engineer."

# Expected behavior:
# 1. Claude invokes rust-engineer skill
# 2. Uses proper ownership and borrowing
# 3. Implements Send + Sync traits
# 4. Uses Arc/Mutex for thread safety
```

### 27. Secure Code Guardian

```
# Test: Security hardening
"Review this login form for OWASP Top 10 vulnerabilities. Use secure-code-guardian."

# Expected behavior:
# 1. Claude invokes secure-code-guardian skill
# 2. Checks for injection, XSS, CSRF
# 3. Validates authentication flow
# 4. Recommends security improvements
```

### 28. Security Reviewer

```
# Test: Security audit
"Conduct a security review of our cloud infrastructure configuration. Use security-reviewer."

# Expected behavior:
# 1. Claude invokes security-reviewer skill
# 2. Performs SAST-style analysis
# 3. Checks infrastructure security
# 4. Generates findings report
```

### 29. SQL Pro

```
# Test: Complex query optimization
"Optimize this query using window functions and CTEs. Use sql-pro."

# Expected behavior:
# 1. Claude invokes sql-pro skill
# 2. Rewrites with window functions
# 3. Uses CTEs for readability
# 4. Analyzes indexing strategy
```

### 30. SRE Engineer

```
# Test: SLO definition
"Define SLIs and SLOs for our payment processing service. Use sre-engineer."

# Expected behavior:
# 1. Claude invokes sre-engineer skill
# 2. Defines meaningful SLIs
# 3. Sets appropriate SLO targets
# 4. Establishes error budget policies
```

### 31. Terraform Engineer

```
# Test: Terraform module
"Create a reusable Terraform module for an AWS VPC with subnets. Use terraform-engineer."

# Expected behavior:
# 1. Claude invokes terraform-engineer skill
# 2. Creates module with variables and outputs
# 3. Follows module best practices
# 4. Includes state management considerations
```

### 32. Test Master

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
# Test each /command - SRE workflow skills
claude -p "/test-driven-operation"
claude -p "/subagent-driven-operation"
claude -p "/brainstorming-operations"
claude -p "/writing-operation-plans"
claude -p "/verification-before-completion"
claude -p "/sre-runbook"
claude -p "/pve-admin"
claude -p "/puppet-code-analyzer"
claude -p "/cache-cleanup"
claude -p "/gitlab-ecr-pipeline"
claude -p "/clickup-ticket-creator"

# Test each /command - Domain expertise skills
claude -p "/architecture-designer"
claude -p "/chaos-engineer"
claude -p "/cloud-architect"
claude -p "/code-documenter"
claude -p "/code-reviewer"
claude -p "/devops-engineer"
claude -p "/golang-pro"
claude -p "/kubernetes-specialist"
claude -p "/microservices-architect"
claude -p "/monitoring-expert"
claude -p "/postgres-pro"
claude -p "/prompt-engineer"
claude -p "/python-pro"
claude -p "/rust-engineer"
claude -p "/secure-code-guardian"
claude -p "/security-reviewer"
claude -p "/sql-pro"
claude -p "/sre-engineer"
claude -p "/terraform-engineer"
claude -p "/test-master"

# Each should invoke the corresponding skill
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
   - Verify `session-start.sh` is executable
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
# - "/cache-cleanup for Go and npm"
# - etc.

# 5. Check hooks fired
# (using-srepowers should be in context automatically)
```

## Success Criteria

- All tests pass: `./tests/claude-code/run-skill-tests.sh`
- All 32 skills load when prompted
- All 31 commands invoke correct skills
- Hooks inject meta-skill on session start
- Each skill demonstrates its workflow correctly
