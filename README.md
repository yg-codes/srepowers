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
