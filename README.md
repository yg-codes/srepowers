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

## Commands

Quick invoke skills using `/command` syntax:

- `/test-driven-operation` - Execute operations with verification commands
- `/subagent-driven-operation` - Execute operation plans with subagent dispatch
- `/brainstorming-operations` - Design infrastructure operations
- `/writing-operation-plans` - Create detailed execution plans

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
- [Implementation Plan](docs/plans/2026-02-09-implement-all-8-actions-from-user-feedback.md) - Development roadmap and task breakdown

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
