# SREPowers

SRE infrastructure skills for Claude Code: Test-Driven Operations and Subagent-Driven Operations for Kubernetes, Keycloak, GitOps, API workflows, and more.

## Overview

SREPowers adapts proven software development workflows (TDD, subagent-driven development) for infrastructure operations. These skills help you execute infrastructure changes systematically with verification-first discipline.

## Installation

### Via Claude Code Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add yg/srepowers-marketplace

# Install the plugin
/plugin install srepowers@srepowers-marketplace

# Verify installation
/help
# You should see:
# /test-driven-operation - Use when executing infrastructure operations...
# /subagent-driven-operation - Use when executing infrastructure operation plans...
```

### Manual Installation

Clone this repository to your local skills directory:

```bash
# Clone the repository
git clone https://github.com/yg/srepowers.git ~/.claude/plugins/srepowers

# Or copy skills directly
cp -r srepowers/skills/* ~/.claude/skills/
```

## Available Skills

### test-driven-operation

**Use when:** Executing infrastructure operations with verification commands - API calls, kubectl, Keycloak CRDs, Git MRs, Linux server operations.

**Core principle:** If you didn't watch the verification fail, you don't know if it verifies the right thing.

**Workflow:**
1. **RED** - Write failing verification command (kubectl, API call, etc.)
2. **Verify RED** - Run it and watch it fail
3. **GREEN** - Execute minimal infrastructure operation
4. **Verify GREEN** - Run verification and confirm it passes
5. **REFACTOR** - Document and clean up

**Example:**
```bash
# RED - Verification fails
kubectl get pod -n production -l app=api-server
# Error: No resources found

# GREEN - Apply minimal manifest
kubectl apply -f api-server-pod.yaml

# Verify GREEN - Passes
kubectl get pod -n production -l app=api-server
# NAME          READY   STATUS    RESTARTS   AGE
# api-server    1/1     Running   0          5s
```

### subagent-driven-operation

**Use when:** Executing infrastructure operation plans with independent tasks in the current session.

**Core principle:** Fresh subagent per task + two-stage review (spec compliance then artifact quality) = high quality, fast iteration.

**Workflow:**
1. Read plan, extract all tasks with full text
2. For each task:
   - Dispatch operator subagent with full task text
   - Execute operations following Test-Driven Operation
   - Verify operations succeeded
   - Commit to control repo (if applicable)
   - **Spec compliance review** - Verify all requirements met, nothing missing/extra
   - **Artifact quality review** - Verify YAML/JSON valid, proper labels/annotations
3. After all tasks: Final artifact review

**Two-Stage Review:**
- **Spec Compliance:** Did we execute exactly what was requested?
- **Artifact Quality:** Are the infrastructure artifacts well-built?

### brainstorming-operations

**Use when:** Planning infrastructure operations before implementation.

**Core principle:** Design operations with risk assessment, verification strategies, and rollback plans before executing.

**Workflow:**
1. Understand current infrastructure state
2. Ask questions to refine operation scope
3. Present design in sections with validation
4. Document current state, desired state, approach
5. Include risk assessment and rollback strategies

**Output:** Design document saved to `docs/plans/YYYY-MM-DD-<operation-name>-design.md`

### writing-operation-plans

**Use when:** You have a design and need to create bite-sized execution steps.

**Core principle:** Create detailed plans with exact commands, verification steps, and rollback instructions.

**Workflow:**
1. Write plan with TDO discipline for each task
2. Include exact commands (no placeholders)
3. Document verification commands with expected outputs
4. Provide rollback steps for each task
5. Save to `docs/plans/YYYY-MM-DD-<operation-name>.md`

**Output:** Execution plan that operators can follow step-by-step.

### verification-before-completion

**Use when:** About to claim work is complete, fixed, or passing.

**Core principle:** Evidence before claims, always.

**Workflow:**
1. IDENTIFY: What command proves this claim?
2. RUN: Execute the full command (fresh, complete)
3. READ: Full output, check exit code
4. VERIFY: Does output confirm the claim?
5. ONLY THEN: Make the claim with evidence

### cache-cleanup

**Use when:** Cleaning up development tool caches interactively with pre/post verification.

**Core principle:** Clean caches safely - verify tools work before cleanup, verify tools still work after cleanup.

**Supported Tools:** mise-managed tools (Go, Rust, Node.js, Python), npm, Cargo, uv, pipx, pip

**Workflow:**
1. Select caches to clean (mise, npm, Go, Cargo, uv, pipx, pip)
2. Pre-check: Verify each tool is available and working
3. Cleanup: Remove cache directories
4. Post-check: Verify tools still work after cleanup

### clickup-ticket-creator

**Use when:** Creating ClickUp tickets following CCB template format.

**Core principle:** Structured ticket generation with all required sections.

**Sections:** Description, Rationale, Impact, Risk, UAT, Procedure, Verification, Rollback

**Output:** Formatted ClickUp ticket ready for submission

### gitlab-ecr-pipeline

**Use when:** Creating GitLab CI/CD pipelines that push container images to AWS ECR.

**Core principle:** Generate complete pipelines with proper authentication, building, and pushing.

**Supports:** Building from Containerfile/Dockerfile, mirroring upstream images

**Features:** AWS ECR authentication, Podman/buildah support, multi-stage builds, tagging strategies

### puppet-code-analyzer

**Use when:** Analyzing Puppet code quality in control repos or modules.

**Core principle:** Automated analysis with linting, dependency checking, best practice validation.

**Features:** Syntax validation, dependency analysis, style guide compliance, error troubleshooting

**Workflow:**
1. Identify Puppet control repo or module
2. Run syntax validation with puppet-lint
3. Analyze dependencies and module structure
4. Check style guide compliance
5. Generate analysis report with recommendations

### pve-admin

**Use when:** Managing Proxmox VE 8.x/9.x and Proxmox Backup Server 3.x infrastructure.

**Core principle:** Complete Proxmox administration with cluster management and safe operations.

**Features:** Cluster management, VM/CT operations, ZFS storage, networking, HA, backup/restore, health checks

**Operations:**
- VM/CT lifecycle (create, start, stop, migrate)
- Storage management (ZFS, LVM, directory, NFS)
- Network configuration (bridges, bonds, VLANs)
- Cluster operations (join, leave, quorum)
- Backup/restore (PBS integration)
- Health monitoring and diagnostics

### sre-runbook

**Use when:** Creating structured SRE runbooks for infrastructure operations.

**Core principle:** Runbooks with Command/Expected/Result format for verifiable procedures.

**Output:** Structured runbooks with pre-requisites, step-by-step procedures, verification, rollback

**Format:**
- Pre-requisites (access, tools, state)
- Procedures with Command/Expected/Result format
- Verification steps
- Rollback procedures
- Troubleshooting section

## Commands

Quick invoke skills using `/command` syntax:

**SRE Operations:**
- `/test-driven-operation` - Execute operations with verification commands
- `/subagent-driven-operation` - Execute operation plans with subagent dispatch
- `/brainstorming-operations` - Design infrastructure operations
- `/writing-operation-plans` - Create detailed execution plans
- `/sre-runbook` - Create structured SRE runbooks

**Infrastructure Administration:**
- `/pve-admin` - Proxmox VE/Backup administration
- `/puppet-code-analyzer` - Puppet code quality analysis

**Development Tools:**
- `/cache-cleanup` - Interactive dev tool cache cleanup

**CI/CD & Pipelines:**
- `/gitlab-ecr-pipeline` - GitLab CI/CD → AWS ECR pipelines

**Project Management:**
- `/clickup-ticket-creator` - Create CCB-formatted ClickUp tickets

Commands are thin wrappers that invoke skills directly for quick access.

## Usage Examples

### Kubernetes Deployment

```bash
# Write verification first
kubectl get deployment -n staging api-server -o jsonpath='{.spec.replicas}'

# Apply deployment
kubectl apply -f deployment.yaml

# Verify
kubectl get deployment -n staging api-server -o jsonpath='{.spec.replicas}'
# Output: 3
```

### Keycloak Realm Provisioning

```bash
# Write verification first
kubectl get keycloakrealm/example-realm -o jsonpath='{.status.ready}'

# Apply Keycloak CRD
kubectl apply -f keycloak-realm.yaml

# Verify
kubectl get keycloakrealm/example-realm -o jsonpath='{.status.ready}'
# Output: true
```

### Git Control Repo Operation

```bash
# Write verification first
kubectl get configmap -n production app-config -o jsonpath='{.data.DATABASE_URL}'

# Create config in control repo
cat > manifests/production/app-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  DATABASE_URL: postgresql://prod-db.example.com:5432/app
EOF

git add manifests/production/app-config.yaml
git commit -m "Add production database config"
git push

# Wait for ArgoCD/Flux sync, then verify
kubectl get configmap -n production app-config -o jsonpath='{.data.DATABASE_URL}'
# Output: postgresql://prod-db.example.com:5432/app
```

### API Operation

```bash
# Write verification first
curl -s https://api.example.com/users/123 | jq '.email'
# Output: null

# Execute API call
curl -X PATCH https://api.example.com/users/123 \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com"}'

# Verify
curl -s https://api.example.com/users/123 | jq '.email'
# Output: "user@example.com"
```

## Key Principles

### Test-Driven Operation (TDO)

- **Tests** = Verification commands (kubectl, API calls, Git queries)
- **Commits** = Git operations on control repo
- Always write verification first, run it, watch it fail
- Execute minimal operation to pass
- Verify output matches expected result

### Subagent-Driven Operation

- **Operator** = Infrastructure operations specialist
- **Artifact quality review** = YAML/JSON validity, Kubernetes best practices
- **Tests** = Verification commands
- **Commits** = Git operations on control repo

### Two-Stage Review

1. **Spec Compliance** - Verified all operations executed, nothing missing/extra
2. **Artifact Quality** - YAML/JSON valid, proper labels/annotations, security best practices

## Documentation

- [Testing Anti-Patterns](docs/testing-anti-patterns.md) - Common infrastructure operation testing pitfalls and how to avoid them
- [Persuasion Principles](docs/persuasion-principles.md) - Psychology of effective skill design for SRE discipline
- [Container CI/CD Reference](docs/container-cicd-reference/) - ECR, GitLab Container Registry, IAM auth patterns
- [Implementation Plan](docs/plans/2026-02-09-implement-all-8-actions-from-user-feedback.md) - Development roadmap and task breakdown
- [Merge Plan](docs/plans/2026-02-09-merge-yg-claude-skills-into-srepowers.md) - yg-claude merge strategy and execution

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`cu_your_feature`)
3. Follow the skill format (SKILL.md with frontmatter)
4. Test your skills thoroughly
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

Adapted from the excellent [superpowers](https://github.com/obra/superpowers) plugin by Jesse Vital, with adaptations for SRE infrastructure workflows.

## Release Notes

See [RELEASE-NOTES.md](RELEASE-NOTES.md) for version history and changes.
