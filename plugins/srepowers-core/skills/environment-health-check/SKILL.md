---
name: environment-health-check
description: Use when you need to verify that infrastructure tools (kubectl, terraform, aws CLI, glab, helm, tshark, etc.) are installed and configured before starting work. Also use for "check my environment", "verify tools", "am I set up correctly", "pre-flight check", or at the start of any session where missing tools could cause failures.
---

# Environment Health Check

## Overview

Verify that required infrastructure tools are installed, accessible, and properly configured before attempting operations. Prevents frustrating failures mid-operation.

**Core principle:** Verify environment readiness before starting work.

**Announce at start:** "I'm using the environment-health-check skill to verify tool availability."

## When to Use

**Use at:**
- Start of new SREPowers session
- Before complex multi-step operations
- When switching to new workstation
- After tool installation/updates
- When troubleshooting "command not found" errors

**Called automatically by:**
- Session start hook (optional configuration)
- Other skills before critical operations

## Tool Categories

### Core Infrastructure Tools

| Tool | Purpose | Verification Command |
|------|---------|---------------------|
| `kubectl` | Kubernetes operations | `kubectl version --client` |
| `helm` | Helm chart management | `helm version` |
| `terraform` | Infrastructure as Code | `terraform version` |
| `aws` | AWS CLI | `aws --version` |
| `az` | Azure CLI | `az version` |
| `gcloud` | GCP CLI | `gcloud version` |

### Development Tools

| Tool | Purpose | Verification Command |
|------|---------|---------------------|
| `git` | Version control | `git --version` |
| `docker` / `podman` | Containers | `docker --version` / `podman --version` |
| `curl` | HTTP requests | `curl --version` |
| `jq` | JSON processing | `jq --version` |
| `yq` | YAML processing | `yq --version` |

### SRE-Specific Tools

| Tool | Purpose | Verification Command |
|------|---------|---------------------|
| `k9s` | Kubernetes TUI | `k9s version` |
| `stern` | Log tailing | `stern --version` |
| `kustomize` | K8s config management | `kustomize version` |
| `argocd` | ArgoCD CLI | `argocd version --client` |
| `velero` | Backup/restore | `velero version` |

## The Health Check Process

### Step 1: Quick Scan

Check for essential tools. **Important:** Not all tools use `--version` — use the per-tool version command lookup below.

```bash
#!/usr/bin/env bash

# Tool name -> version command (not all tools use --version)
declare -A VERSION_CMD=(
    [kubectl]="version --client 2>&1 | head -1"
    [helm]="version 2>&1 | head -1"
    [git]="--version"
    [curl]="--version 2>&1 | head -1"
    [terraform]="version 2>&1 | head -1"
    [aws]="--version 2>&1 | head -1"
    [jq]="--version"
    [yq]="--version 2>&1 | head -1"
    [docker]="--version"
    [podman]="--version"
    [k9s]="version 2>&1 | head -1"
    [stern]="--version 2>&1 | head -1"
    [kustomize]="version 2>&1 | head -1"
    [argocd]="version --client 2>&1 | head -1"
    [velero]="version --client-only 2>&1 | head -1"
    [helmfile]="version 2>&1 | head -1"
    [kubeseal]="--version 2>&1 | head -1"
    [glab]="version 2>&1 | head -1"
    [tshark]="--version 2>&1 | head -1"
)

# Essential tools
ESSENTIAL_TOOLS=("kubectl" "git" "curl")
# Extended tool set
EXTENDED_TOOLS=("helm" "terraform" "aws" "jq" "yq" "docker")
# SRE-specific tools
SRE_TOOLS=("k9s" "stern" "kustomize")

check_tool_version() {
    local tool=$1
    if command -v "$tool" >/dev/null 2>&1; then
        local cmd="${VERSION_CMD[$tool]:---version}"
        local version
        version=$(eval "$tool $cmd" 2>&1 | head -1)
        printf "  ✅ %-15s %s\n" "$tool" "$version"
        return 0
    else
        printf "  ❌ %-15s NOT FOUND\n" "$tool"
        return 1
    fi
}

echo "=== Environment Health Check ==="
echo ""
echo "Checking essential tools..."
for tool in "${ESSENTIAL_TOOLS[@]}"; do check_tool_version "$tool"; done
```

### Step 2: Configuration Verification

Check tool configurations:

```bash
# Kubernetes context
echo ""
echo "=== Kubernetes Configuration ==="
if command -v kubectl >/dev/null 2>&1; then
    echo "Available contexts:"
    kubectl config get-contexts -o name 2>&1 | head -5 || echo "  ❌ No contexts configured"

    echo ""
    echo "Target context connectivity:"
    kubectl --context <context> cluster-info 2>&1 | head -3 || echo "  ❌ Cannot connect to target context"

    echo ""
    echo "Client/server version:"
    kubectl version --client -o json 2>&1 | jq -r '"Client: " + .clientVersion.gitVersion' 2>/dev/null || kubectl version --client 2>&1 | head -2
    kubectl --context <context> version -o json 2>&1 | jq -r '"Server: " + .serverVersion.gitVersion' 2>/dev/null || true
else
    echo "  ❌ kubectl not installed"
fi

# AWS configuration
echo ""
echo "=== AWS Configuration ==="
if command -v aws >/dev/null 2>&1; then
    echo "AWS CLI version:"
    aws --version

    echo ""
    echo "Configured profiles:"
    aws configure list-profiles 2>&1 | head -5 || echo "  ❌ No profiles configured"

    echo ""
    echo "Current identity:"
    aws sts get-caller-identity 2>&1 || echo "  ❌ Not authenticated"
else
    echo "  ❌ AWS CLI not installed"
fi

# Terraform configuration
echo ""
echo "=== Terraform Configuration ==="
if command -v terraform >/dev/null 2>&1; then
    echo "Terraform version:"
    terraform version | head -1
else
    echo "  ❌ Terraform not installed"
fi
```

### Step 3: Generate Health Report

```bash
# Generate structured report
cat <<EOF

## Environment Health Report

Generated: $(date -Iseconds)
User: $(whoami)
Hostname: $(hostname)

### Tool Status Summary

| Category | Available | Missing |
|----------|-----------|---------|
| Essential | [count] | [count] |
| Extended | [count] | [count] |
| SRE-Specific | [count] | [count] |

### Recommendations

[Based on missing tools]

EOF
```

## Health Check Levels

### Level 1: Essential Only

Check only critical tools:
- kubectl
- git
- curl

**Use when:** Quick check before simple operations

### Level 2: Standard

Check common infrastructure tools:
- Essential + helm, terraform, aws, jq, yq

**Use when:** Before multi-step operations

### Level 3: Comprehensive

Check all tools including SRE-specific:
- Standard + k9s, stern, kustomize, argocd

**Use when:** Setting up new workstation

## Interactive Health Check

```bash
#!/usr/bin/env bash

# Interactive mode - prompts for fixes

check_tool() {
    local tool=$1
    local install_suggestion=$2

    if command -v "$tool" >/dev/null 2>&1; then
        echo "  ✅ $tool"
        return 0
    else
        echo "  ❌ $tool - $install_suggestion"
        return 1
    fi
}

echo "=== Interactive Environment Health Check ==="
echo ""

MISSING=()

# Check each tool
for tool in kubectl helm terraform aws jq yq; do
    if ! check_tool "$tool" "See https://docs.$tool.io"; then
        MISSING+=("$tool")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo ""
    echo "✅ All tools available!"
    exit 0
fi

echo ""
echo "⚠️  ${#MISSING[@]} tools missing"
echo ""
echo "Would you like to:"
echo "  1. Continue anyway (may fail during operations)"
echo "  2. Install missing tools first"
echo "  3. Abort and install tools manually"

read -p "Choice (1-3): " choice

case $choice in
    1)
        echo "Continuing with available tools..."
        ;;
    2)
        echo "Installing missing tools..."
        # Platform-specific installation
        ;;
    3)
        echo "Aborting. Install tools and try again."
        exit 1
        ;;
esac
```

## SRE Principles

### Safety First
- Verify tools before attempting operations
- Prevent partial failures due to missing dependencies
- Warn about version incompatibilities

### Structured Output
- Present results in tables
- Group by tool category
- Show clear pass/fail status

### Evidence-Driven
- Show actual version numbers
- Test connectivity to clusters/APIs
- Verify configurations, not just installations

### Audit-Ready
- Log health check results
- Track tool versions over time
- Document environment state

### Communication
- Explain why each tool is needed
- Provide installation guidance
- Suggest alternatives where applicable

## Integration

**Called by:**
- Session start (optional)
- `test-driven-operation` (before first operation)
- `brainstorming-operations` (to assess capability)

**Calls:**
- Platform-specific package managers for installation

**Pairs with:**
- `cache-cleanup` - Verify tools still work after cleanup
- `playground-tutorial` - Check before tutorial

## Installation Guidance

### macOS (Homebrew)

```bash
# Essential
brew install kubectl git curl

# Extended
brew install helm terraform awscli jq yq

# SRE tools
brew install k9s stern kustomize argocd
```

### Linux (apt)

```bash
# Essential
sudo apt-get install -y kubectl git curl

# Extended
sudo apt-get install -y jq
# terraform, awscli from specific repos
```

### mise (Recommended)

```bash
# Using mise for tool management
mise use kubectl@1.28.0
mise use terraform@1.5.0
mise use awscli@2.0.0
```

## Common Issues and Fixes

### Issue: kubectl version flags not working as expected

**Symptom:**
```
error: unknown flag: --version
error: unknown flag: --short
```

**Context:**
- `kubectl` does NOT support `--version` (use `kubectl version --client`)
- `kubectl version --short` was removed in kubectl v1.33+ — use `kubectl version --client` or `kubectl version -o json`
- `helm` uses `helm version` (no dashes), not `helm --version`
- `k9s`, `kubecolor`, and some Go-based tools may not support any version flag — wrap in `2>&1 | head -1` and treat errors as "installed, version unavailable"

**Fix:**
```bash
# Correct per-tool version commands
kubectl version --client -o json 2>&1 | jq -r '"Client: " + .clientVersion.gitVersion'
helm version --short 2>&1
k9s version 2>&1 | head -1
```

### Issue: Vault status check fails with TLS error inside pod

**Symptom:**
```
Error checking seal status: Get "https://127.0.0.1:8200/v1/sys/seal-status": tls: failed to verify certificate: x509: certificate signed by unknown authority
```

**Context:** When Vault uses custom TLS certificates (e.g., Vault PKI), the `vault` CLI inside the pod may not trust the local listener cert because it uses the system CA bundle instead of the Vault-specific CA.

**Fix:**
```bash
# Option 1: Skip TLS verification (quick check)
kubectl exec -n vault vault-0 -- vault status -tls-skip-verify

# Option 2: Use the correct CA cert
kubectl exec -n vault vault-0 -- vault status \
  -ca-cert=/vault/tls/ca.crt

# Option 3: Use wget from sidecar with --no-check-certificate
kubectl exec -n vault vault-0 -c bank-vaults -- \
  wget -qO- --no-check-certificate https://127.0.0.1:8200/v1/sys/seal-status
```

### Issue: Cannot check certificate expiry inside static pod containers

**Symptom:**
```
exec: "openssl": executable file not found in $PATH
```

**Context:** etcd, kube-apiserver, and other Kubernetes static pod containers use minimal base images that do not include `openssl`.

**Fix:**
```bash
# Option 1: Check cert expiry on the host node (not inside the container)
ssh node.example.com "openssl x509 -checkend 2592000 -noout -in /etc/kubernetes/pki/etcd/server.crt"

# Option 2: Use kubectl to decode the cert from a secret (if certs are managed by cert-manager)
kubectl --context <ctx> -n cert-manager get secret <secret-name> \
  -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -checkend 2592000 -noout

# Option 3: Check kube-apiserver health endpoint
kubectl --context <ctx> get --raw /livez
kubectl --context <ctx> get --raw /readyz
```

### Issue: kubectl not connected to cluster

**Symptom:**
```
The connection to the server localhost:8080 was refused
```

**Fix:**
```bash
# Check kubeconfig
export KUBECONFIG=~/.kube/config

# Or use specific config
kubectl --kubeconfig=/path/to/config --context <context> get nodes
```

### Issue: AWS CLI not authenticated

**Symptom:**
```
Unable to locate credentials
```

**Fix:**
```bash
# Configure credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

### Issue: Terraform version mismatch

**Symptom:**
```
Error: Unsupported Terraform Core version
```

**Fix:**
```bash
# Check required version
cat versions.tf | grep required_version

# Install matching version
mise use terraform@1.5.0
```

## Extending the Health Check

Add custom tools:

```bash
# In your CLAUDE.md or wrapper script
CUSTOM_TOOLS=("my-tool" "another-tool")

for tool in "${CUSTOM_TOOLS[@]}"; do
    check_tool "$tool" "Custom installation instructions"
done
```

## Quick Reference

| Check | Command |
|-------|---------|
| Tool installed | `command -v kubectl` |
| Tool version (kubectl) | `kubectl version --client` |
| Tool version (helm) | `helm version` |
| Tool version (generic) | `<tool> --version 2>&1 \| head -1` |
| K8s contexts | `kubectl config get-contexts -o name` |
| K8s client/server skew | `kubectl version -o json \| jq` |
| AWS identity | `aws sts get-caller-identity` |
| All tools | Run this skill! |
