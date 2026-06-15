---
name: goreleaser-pipeline
description: Use when building and releasing Go binaries with GoReleaser — creating .goreleaser.yml configurations, setting up cross-compilation, managing release pipelines on GitLab CI/CD or GitHub Actions, tagging releases, and troubleshooting build failures. Also use for "goreleaser", "go release", "cross compile go", "release binary", ".goreleaser.yml", "go binary pipeline", "gitlab release", "build go cli", or any GoReleaser release pipeline task.
---

# GoReleaser Pipeline

Configure and operate GoReleaser pipelines for building and releasing Go CLI tools. Covers `.goreleaser.yml` authoring, cross-compilation, GitLab CI/CD integration, and release troubleshooting.

**Core principle:** Build reproducibly, release from CI only, tag before release.

**Announce at start:** "I'm using the goreleaser-pipeline skill to [configure/release/debug] GoReleaser."

## When to Use

**Use when:**
- Creating or modifying `.goreleaser.yml` configuration
- Setting up cross-compilation for Go binaries
- Configuring GitLab CI/CD pipelines for GoReleaser
- Creating release tags and triggering builds
- Debugging GoReleaser build failures
- Adding new build targets (OS/arch combinations)

**Exceptions:**
- Non-Go projects — GoReleaser is Go-specific
- Docker-only releases without binary artifacts — use `container-engineer` instead

## .goreleaser.yml Reference

### Minimal Configuration

```yaml
project_name: mytool
before:
  hooks:
    - go mod tidy
builds:
  - env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
    main: ./cmd/mytool
archives:
  - format: tar.gz
    name_template: >-
      {{ .ProjectName }}_
      {{- .Version }}_
      {{- .Os }}_
      {{- .Arch }}
checksum:
  name_template: checksums.txt
```

### Full Configuration with Extras

```yaml
project_name: mytool

env:
  - GO111MODULE=on

before:
  hooks:
    - go mod tidy
    - go generate ./...

builds:
  - id: mytool
    binary: mytool
    main: ./cmd/mytool
    env:
      - CGO_ENABLED=0
    goos:
      - linux
      - darwin
      - windows
    goarch:
      - amd64
      - arm64
    ldflags:
      - -s -w
      - -X main.version={{.Version}}
      - -X main.commit={{.Commit}}
      - -X main.date={{.Date}}
      - -X main.builtBy=goreleaser
    flags:
      - -trimpath

archives:
  - id: mytool-archive
    builds:
      - mytool
    format: tar.gz
    name_template: >-
      {{ .ProjectName }}_
      {{- .Version }}_
      {{- .Os }}_
      {{- .Arch }}
    files:
      - README.md
      - LICENSE

checksum:
  name_template: checksums.txt

changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
      - '^chore:'
```

## GitLab CI/CD Integration

### Pipeline Configuration

```yaml
# .gitlab-ci.yml
stages:
  - test
  - release

test:
  stage: test
  image: golang:1.22
  script:
    - go test -race -v ./...
  rules:
    - if: $CI_COMMIT_TAG
      when: never
    - when: always

release:
  stage: release
  image:
    name: goreleaser/goreleaser:latest
    entrypoint: [""]
  variables:
    GITLAB_TOKEN: $GITLAB_TOKEN  # CI/CD variable (access token with api scope)
  script:
    - goreleaser release --clean
  rules:
    - if: $CI_COMMIT_TAG
      when: on_success
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
```

### Required CI/CD Variables

| Variable | Scope | Purpose |
|----------|-------|---------|
| `GITLAB_TOKEN` | Protected, masked | GitLab access token with `api` scope for creating releases |

```bash
# Set the variable via glab
glab variable set GITLAB_TOKEN "glpat-xxxxx" --masked --protected
```

## Release Workflow

### Step 1: Prepare the Release

```bash
# Ensure working tree is clean
git status
git diff --stat

# Run tests
go test -race -v ./...

# Dry-run goreleaser locally (no actual release)
goreleaser release --snapshot --clean

# Verify the binaries were built
ls -la dist/
```

### Step 2: Tag and Push

**Sync first — a clean working tree does not mean your `HEAD` is current.** `git tag`
pins the tag to wherever local `HEAD` points. If your checkout is behind `origin/main`,
you will tag a stale commit, and GoReleaser (which builds from the tag, not from `main`)
will release that old code — even after the fix you intended to ship was merged.

```bash
# Land on the release branch and sync it to the remote
git checkout main
git fetch origin
git pull --ff-only            # or: git reset --hard origin/main

# Sanity gate — these two MUST be equal before tagging
git rev-parse HEAD
git rev-parse origin/main

# Create an annotated tag (tag origin/main explicitly to sidestep stale HEAD entirely)
git tag -a v1.2.3 origin/main -m "Release v1.2.3: add feature X"

# Push the tag to trigger the pipeline
git push origin v1.2.3
```

If `git rev-parse HEAD` ≠ `git rev-parse origin/main`, stop — your tag would capture the
wrong commit. Tagging `origin/main` directly (as above) makes the tag immune to a stale
local `HEAD`, as long as you `git fetch` first.

### Step 3: Monitor the Pipeline

```bash
# Check pipeline status
glab ci status

# Watch the job log
glab ci trace
```

### Step 4: Verify the Release

```bash
# Check the release on GitLab
glab release view v1.2.3

# Download and test the binary
curl -L -o mytool.tar.gz \
  "https://gitlab.example.com/api/v4/projects/<id>/packages/generic/mytool/v1.2.3/mytool_v1.2.3_linux_amd64.tar.gz"
tar xzf mytool.tar.gz
./mytool --version
```

### Recovering from a wrong-commit tag

Tags are immutable by convention — but if a tag was pushed against the wrong commit
(e.g. a stale `HEAD`) and the resulting release shipped old code, you must replace it.
This is the one sanctioned exception to "never re-create a tag":

```bash
# 1. Delete the bad GitLab release (assets + release object), then the tag
glab api -X DELETE "projects/<id>/releases/v1.2.3"
git push origin --delete v1.2.3        # may be blocked — see protected-tag note
git tag -d v1.2.3                       # local

# 2. Re-cut from the verified-current branch (see Step 2 sync gate)
git fetch origin
git tag -a v1.2.3 origin/main -m "Release v1.2.3"
git push origin v1.2.3
```

**Protected tags:** if `v*` is a protected tag, `git push origin --delete` is rejected by
a server hook ("You can only delete protected tags using the web interface"). Delete the
tag via the GitLab web UI (**Code → Tags**), then re-cut from CLI. Deleting the GitLab
*release* does not move or remove the underlying *tag* — both must be handled.

**Prefer a new version over re-cutting.** If the bad tag's release was already consumed by
anyone, bump to the next patch (`v1.2.4`) instead of re-using `v1.2.3` — a re-cut tag with
the same name but a different commit is exactly the kind of surprise immutability exists to
prevent.

## Debugging Build Failures

### Common Failures

| Error | Cause | Fix |
|-------|-------|-----|
| `multiple binaries match` | Multiple `builds` entries with same `id` or `binary` name | Ensure unique `id` and `binary` per build |
| `template: ... executing ...` | Invalid Go template in `name_template` | Validate template syntax |
| `GOFLAGS` conflict | Global env conflicts with build env | Check `env` blocks for conflicts |
| `CGO_ENABLED=0` but using CGO | Code imports a CGO package | Remove CGO dependency or enable CGO |
| `main.go: package ... cannot find` | Wrong `main` path | Verify `main:` points to the package with `func main()` |
| Permission denied on release | `GITLAB_TOKEN` missing or wrong scope | Set protected, masked variable with `api` scope |

### Local Debugging

```bash
# Build without releasing
goreleaser build --clean --snapshot

# Check what goreleaser would do (debug mode)
goreleaser release --clean --debug

# Validate the configuration
goreleaser check
```

## ldflags for Version Injection

Inject build metadata into the binary at compile time:

```go
// cmd/mytool/main.go
var (
    version = "dev"      // overridden by goreleaser
    commit  = "none"     // overridden by goreleaser
    date    = "unknown"  // overridden by goreleaser
)

func main() {
    fmt.Printf("mytool %s (commit: %s, built: %s)\n", version, commit, date)
}
```

```yaml
# .goreleaser.yml
ldflags:
  - -s -w
  - -X main.version={{.Version}}
  - -X main.commit={{.Commit}}
  - -X main.date={{.Date}}
```

## Anti-Patterns

| Anti-pattern | Why | Do instead |
|-------------|-----|-----------|
| Releasing from local machine | Non-reproducible, no audit trail | Always release from CI pipeline |
| Unannotated tags (`git tag v1.0`) | No release message, harder to track | Use `git tag -a v1.0 -m "message"` |
| Tagging without syncing `main` | Stale local `HEAD` → release built from old commit, even after the fix merged | `git fetch` + verify `HEAD == origin/main`, or tag `origin/main` directly |
| Missing `CGO_ENABLED=0` | Binary won't run on Alpine/musl unless CGO is off | Set unless CGO is explicitly needed |
| Hardcoded version in code | Must update two places for every release | Use ldflags to inject version at build time |
| No `--clean` flag | Stale artifacts from previous builds contaminate release | Always use `--clean` |

## Integration

**Called by:**
- `srepowers-domain:golang-pro` — for Go project release operations
- `srepowers-infra:gitlab-cicd` — for pipeline configuration

**Pairs with:**
- `srepowers-infra:gitlab-ecr-pipeline` — when also pushing Docker images alongside binaries

**Site-specific overlays** (private skills — invoke this skill first, then the overlay for platform-specific details):
- `github-goreleaser-pipeline` — GitHub Actions workflow (auto `GITHUB_TOKEN`, `gh` verification, permissions model)
- `gitlab-goreleaser-pipeline` — GitLab token minting, protected tag ordering, API quirks, `CI_JOB_TOKEN` vs real token

## SRE Principles

### Safety First
- Always dry-run locally before pushing a tag
- Sync `main` and verify `HEAD == origin/main` before tagging (see Step 2) — the
  commonest release failure is tagging a stale local commit
- Treat tags as immutable; re-create one only to recover from a wrong-commit tag, and
  prefer a version bump (see "Recovering from a wrong-commit tag")
- Test the released binary before announcing the release

### Structured Output
- Report: version, tag, OS/arch targets, binary sizes, checksum
- Use tables for multi-platform build results

### Evidence-Driven
- Capture dry-run output as evidence before the actual release
- Show pipeline job URL and build logs for traceability

### Audit-Ready
- Release tags are permanent records in git
- GoReleaser changelog documents what changed

### Communication
- Report release status: "v1.2.3 built successfully for linux/amd64, linux/arm64"
- Surface binary sizes and checksums for verification
