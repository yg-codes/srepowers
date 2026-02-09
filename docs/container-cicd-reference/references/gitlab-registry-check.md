# How to Check GitLab Container Registry Availability

**Document Version:** 1.0
**Date:** 2025-10-22
**GitLab Instance:** gitlab.example.com
**Project:** org/team/cdk/aws-network-acc-cdk

---

## Quick Checks

### Method 1: Web UI Check (Fastest)

1. **Navigate to your project:**
   ```
   https://gitlab.example.com/org/team/cdk/aws-network-acc-cdk
   ```

2. **Look for "Container Registry" in left sidebar:**
   ```
   Project Overview
   Repository
   Issues
   Merge Requests
   → Packages & Registries
      → Container Registry  ← Look for this
      → Package Registry    ← You mentioned you have this
   CI/CD
   Settings
   ```

3. **Click "Container Registry":**
   - ✅ **If available:** You'll see a page explaining how to use it (or showing existing images)
   - ❌ **If NOT available:** Menu item won't exist OR you'll see "Feature not available"

---

### Method 2: Project Settings Check

1. **Go to Settings → General:**
   ```
   https://gitlab.example.com/org/team/cdk/aws-network-acc-cdk/-/settings/general
   ```

2. **Expand "Visibility, project features, permissions"**

3. **Look for "Container Registry" toggle:**
   ```
   [ ] Issues
   [ ] Repository
   [ ] Merge Requests
   [ ] CI/CD
   [ ] Container Registry  ← Look for this toggle
   [ ] Package Registry    ← You have this
   ```

   - ✅ **If you see the toggle:** Feature is available (may be turned off for project)
   - ❌ **If toggle doesn't exist:** Feature not enabled at instance level

---

### Method 3: API Check (Command Line)

```bash
# Check if Container Registry is enabled for your project
curl --header "PRIVATE-TOKEN: <your-gitlab-token>" \
  "https://gitlab.example.com/api/v4/projects/org%2Fteam%2Fcdk%2Faws-network-acc-cdk" \
  | jq '.container_registry_enabled'

# Expected outputs:
# true   = Container Registry is enabled
# false  = Container Registry is disabled (but may be available)
# null   = Feature not available at instance level
```

**Get your GitLab token:**
1. Go to User Settings → Access Tokens
2. Create token with `read_api` scope
3. Use in command above

---

### Method 4: Try Direct Registry Access

```bash
# Try to access the registry endpoint
curl -I https://gitlab.example.com/v2/

# Expected responses:
# 401 Unauthorized = Registry is running (needs auth)
# 404 Not Found    = Registry not enabled
# Connection error = Registry not configured
```

---

## Detailed Investigation

### Check 1: Instance-Level Configuration

**Ask your GitLab administrator** or check if you have admin access:

1. **As GitLab Admin, go to:**
   ```
   Admin Area → Settings → CI/CD
   ```

2. **Look for "Container Registry" section:**
   ```
   Container Registry
   ├── [ ] Enable Container Registry
   ├── Registry URL: registry.gitlab.example.com
   └── Registry storage path: /var/opt/gitlab/gitlab-rails/shared/registry
   ```

3. **Key settings to check:**
   - `Enable Container Registry` checkbox
   - Registry URL (should be configured)
   - Storage path (where images are stored)

---

### Check 2: GitLab Version

Container Registry requires **GitLab 8.8+** (you almost certainly have this).

```bash
# Check GitLab version
curl https://gitlab.example.com/api/v4/version

# Or visit:
https://gitlab.example.com/help
```

**Minimum versions:**
- GitLab 8.8+ (2016) - Basic Container Registry
- GitLab 12.8+ (2020) - Cleanup policies
- GitLab 13.0+ (2020) - Better UI/UX

---

### Check 3: DNS and SSL

Container Registry typically uses a subdomain:

```bash
# Check if registry subdomain exists
nslookup registry.gitlab.example.com

# Or try:
dig registry.gitlab.example.com

# Expected: Should resolve to an IP address
# If "NXDOMAIN" = DNS not configured for registry
```

**Common patterns:**
- `registry.gitlab.example.com` (subdomain)
- `gitlab.example.com:5005` (port-based)
- `gitlab.example.com/registry` (path-based - uncommon)

---

## What You Might Find

### Scenario A: Container Registry Fully Enabled ✅

**Indicators:**
- ✅ "Container Registry" appears in project sidebar
- ✅ Settings has Container Registry toggle (ON)
- ✅ `curl https://gitlab.example.com/v2/` returns 401
- ✅ Registry URL configured (e.g., registry.gitlab.example.com)

**Action:** You're good to go! Proceed with implementation.

---

### Scenario B: Available But Disabled for Your Project ⚠️

**Indicators:**
- ⚠️ "Container Registry" toggle exists in Settings (but OFF)
- ⚠️ Sidebar doesn't show Container Registry menu

**Action:** Enable it yourself!

**Steps:**
1. Go to `Settings → General → Visibility, project features, permissions`
2. Enable "Container Registry" toggle
3. Save changes
4. Refresh page - menu should appear

---

### Scenario C: Available But Not Configured at Instance Level ⚠️

**Indicators:**
- ⚠️ No Container Registry toggle in project settings
- ⚠️ API returns `null` for `container_registry_enabled`
- ⚠️ Admin area shows Container Registry disabled

**Action:** Ask GitLab admin to enable it.

**What admin needs to do:**
```ruby
# /etc/gitlab/gitlab.rb (GitLab Omnibus)

# Enable Container Registry
registry_external_url 'https://registry.gitlab.example.com'

# Optional: Configure storage path
gitlab_rails['registry_path'] = '/var/opt/gitlab/gitlab-rails/shared/registry'

# Save and reconfigure
sudo gitlab-ctl reconfigure
```

**If using GitLab Helm Chart (Kubernetes):**
```yaml
# values.yaml
registry:
  enabled: true
  host: registry.gitlab.example.com
```

---

### Scenario D: Not Available (Instance Too Old or Disabled) ❌

**Indicators:**
- ❌ GitLab version < 8.8
- ❌ Admin explicitly disabled Container Registry
- ❌ Infrastructure doesn't support it

**Action:** Use alternative registry (see below).

---

## Quick Diagnostic Script

Save this as `check-registry.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

GITLAB_URL="https://gitlab.example.com"
PROJECT_PATH="org/team/cdk/aws-network-acc-cdk"
ENCODED_PATH="org%2Fteam%2Fcdk%2Faws-network-acc-cdk"

echo "=== GitLab Container Registry Availability Check ==="
echo ""

# Check 1: Registry endpoint
echo "1. Checking registry endpoint..."
if curl -s -I "${GITLAB_URL}/v2/" | grep -q "401"; then
  echo "   ✅ Registry endpoint is responding (401 Unauthorized - expected)"
else
  echo "   ❌ Registry endpoint not accessible"
fi
echo ""

# Check 2: GitLab version
echo "2. Checking GitLab version..."
VERSION=$(curl -s "${GITLAB_URL}/api/v4/version" | jq -r '.version // "unknown"')
echo "   GitLab version: ${VERSION}"
echo ""

# Check 3: DNS for registry subdomain
echo "3. Checking registry subdomain DNS..."
if nslookup registry.gitlab.example.com > /dev/null 2>&1; then
  echo "   ✅ registry.gitlab.example.com resolves"
elif nslookup gitlab.example.com > /dev/null 2>&1; then
  echo "   ⚠️  registry.gitlab.example.com not found, but gitlab.example.com exists"
  echo "      (Registry might use port-based access)"
else
  echo "   ❌ DNS resolution failed"
fi
echo ""

# Check 4: Project-level setting (requires token)
echo "4. Checking project Container Registry setting..."
if [ -n "${GITLAB_TOKEN:-}" ]; then
  REGISTRY_ENABLED=$(curl -s --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_URL}/api/v4/projects/${ENCODED_PATH}" \
    | jq -r '.container_registry_enabled // "not_available"')

  case "$REGISTRY_ENABLED" in
    true)
      echo "   ✅ Container Registry enabled for project"
      ;;
    false)
      echo "   ⚠️  Container Registry available but disabled for project"
      echo "      Action: Enable in Settings → General → Visibility"
      ;;
    not_available|null)
      echo "   ❌ Container Registry not available at instance level"
      echo "      Action: Contact GitLab admin"
      ;;
  esac
else
  echo "   ⚠️  GITLAB_TOKEN not set - skipping API check"
  echo "      Set token: export GITLAB_TOKEN='your-token'"
fi
echo ""

echo "=== Summary ==="
echo "Visit these URLs to verify:"
echo "  - Project: ${GITLAB_URL}/${PROJECT_PATH}"
echo "  - Container Registry: ${GITLAB_URL}/${PROJECT_PATH}/-/container_registry"
echo "  - Settings: ${GITLAB_URL}/${PROJECT_PATH}/-/settings/general"
```

**Usage:**
```bash
chmod +x check-registry.sh

# Without token
./check-registry.sh

# With token (for full check)
export GITLAB_TOKEN='your-gitlab-token'
./check-registry.sh
```

---

## Alternative Registries (If GitLab Registry Not Available)

### Option 1: Package Registry (You Already Have)

**Can Package Registry store containers?**
- ❌ **No** - Package Registry is for packages (npm, PyPI, Maven, etc.)
- ❌ Cannot store container images

**Your existing Package Registry is good for:**
- Python packages (PyPI)
- npm packages
- Helm charts
- Generic packages (zip/tar files)

---

### Option 2: Self-Host Harbor

**Harbor** is an open-source container registry:

```bash
# Using Docker Compose
wget https://github.com/goharbor/harbor/releases/download/v2.10.0/harbor-offline-installer-v2.10.0.tgz
tar xvf harbor-offline-installer-v2.10.0.tgz
cd harbor
./install.sh
```

**Pros:**
- ✅ Full-featured registry
- ✅ Vulnerability scanning
- ✅ Replication
- ✅ Good web UI

**Cons:**
- ⚠️ Separate infrastructure to manage
- ⚠️ More complex than GitLab registry
- ⚠️ Need DNS, SSL certificates

**Effort:** 1-2 days setup

---

### Option 3: Cloud Registry (External)

If your self-hosted GitLab doesn't have Container Registry:

| Provider | URL | Free Tier | Notes |
|----------|-----|-----------|-------|
| **Quay.io** | quay.io | ✅ Public repos | Red Hat, good features |
| **Docker Hub** | docker.io | ✅ Limited | Rate limits |
| **GitHub GHCR** | ghcr.io | ✅ Generous | If you have GitHub org |
| **AWS ECR** | ECR | ❌ Pay-as-you-go | If using AWS |

**Example with Quay.io:**
```bash
# Free for public images
podman push quay.io/your-org/network-cdk:v1.0.0
```

---

## Decision Matrix

```
IF GitLab Container Registry is available:
  ✅ Use it (best option - integrated)

ELSE IF you can get GitLab admin to enable it:
  ✅ Request enablement (worth the wait - 1-2 days)

ELSE IF you need solution immediately:
  Option A: Self-host Harbor (1-2 days setup, full control)
  Option B: Use Quay.io (immediate, but external dependency)
  Option C: Use AWS ECR (if already using AWS)

ELSE IF Container Registry not critical:
  → Stick with current Python approach (no container needed)
```

---

## Expected Timeline

### If Container Registry Available:
- **Check availability:** 5 minutes
- **Enable for project:** 1 minute
- **Test push/pull:** 10 minutes
- **Total:** 15-20 minutes

### If Need Admin to Enable:
- **Submit request:** 1 hour
- **Admin enables:** 1-2 days (varies)
- **Your testing:** 30 minutes
- **Total:** 2-3 days

### If Self-Host Harbor:
- **Setup Harbor:** 1-2 days
- **Configure DNS/SSL:** 2-4 hours
- **Test integration:** 2-4 hours
- **Total:** 2-3 days

---

## Recommended Next Steps

1. **Run Quick Check (5 minutes):**
   ```bash
   # Navigate to your project
   https://gitlab.example.com/org/team/cdk/aws-network-acc-cdk

   # Look for "Container Registry" in sidebar
   # Check Settings → General for toggle
   ```

2. **If Available:**
   - Enable Container Registry toggle (if disabled)
   - Proceed with containerization implementation
   - Follow PYTHON_DOCKER_COMPARISON.md guide

3. **If Not Available (No Toggle in Settings):**
   - Contact GitLab administrator
   - Share this document with them
   - Ask: "Can we enable Container Registry at instance level?"

4. **While Waiting for Decision:**
   - Continue with current Python approach
   - Prepare Containerfile locally
   - Test with Podman locally (without pushing to registry)

---

## What to Ask Your GitLab Admin

**Email template:**

```
Subject: Request: Enable GitLab Container Registry

Hi [Admin Name],

I'm working on the AWS Network CDK project and would like to use
Container Registry for distributing container images.

Current status:
- We have Package Registry enabled ✅
- Container Registry appears to be disabled ❌

Request:
Can you please enable Container Registry at the instance level?

Configuration needed:
- Enable Container Registry feature
- Registry URL: registry.gitlab.example.com (or appropriate subdomain)
- Storage path: Default is fine

Benefits:
- Better CI/CD integration
- Self-contained deployment artifacts
- Aligns with our glab release workflow
- No external dependencies

Reference:
https://docs.gitlab.com/ee/administration/packages/container_registry.html

Please let me know if you need any additional information.

Thanks,
[Your Name]
```

---

## Fallback Plan

**If Container Registry is not available and won't be enabled:**

### Option: Keep Python + Add Docker Compose Distribution

```yaml
# docker-compose.yml
version: '3.8'
services:
  cdk-deploy:
    build:
      context: .
      dockerfile: Containerfile
    volumes:
      - ./config:/app/config:ro
      - ~/.aws:/root/.aws:ro
    environment:
      - AWS_PROFILE=default
```

**Usage:**
```bash
# Build locally
docker-compose build

# Run deployment
docker-compose run --rm cdk-deploy deploy
```

**Pros:**
- ✅ No registry needed
- ✅ Build locally on-demand
- ✅ Still containerized

**Cons:**
- ❌ No pre-built images
- ❌ Each developer builds locally
- ❌ Slower than pulling pre-built image

---

## Summary Checklist

Run these checks in order:

- [ ] Check project sidebar for "Container Registry" menu
- [ ] Check Settings → General for Container Registry toggle
- [ ] Try accessing `https://gitlab.example.com/v2/`
- [ ] Check DNS for `registry.gitlab.example.com`
- [ ] If not available, contact GitLab admin
- [ ] While waiting, prepare Containerfile locally
- [ ] Test local build with Podman
- [ ] Once enabled, test push to registry
- [ ] Update CI/CD pipeline
- [ ] Update documentation

---

**Next Steps:**
1. Run the quick checks above (5-10 minutes)
2. Report back findings
3. Based on results, we'll proceed with appropriate approach

---

**Document Owner:** SRE Team
**Last Updated:** 2025-10-22
