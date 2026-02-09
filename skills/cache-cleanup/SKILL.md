---
name: cache-cleanup
description: Interactive cache cleanup for development tools with pre-check, cleanup, and post-check verification. Use this skill when users request to clean up caches from mise, npm, Go, Cargo, uv, pipx, or pip. This skill ensures tools remain functional after cleanup by verifying availability before and after.
---

# Cache Cleanup

## Overview

Provides interactive cache cleanup for development toolchains with safety checks to ensure tools remain functional. The cleanup process includes three phases: pre-check (analyze and report cache sizes), cleanup (remove cache files), and post-check (verify tools still work).

## When to Use This Skill

Use this skill when:
- Users request to clean up disk space from development tool caches
- Users ask to "clean cache" for specific tools (mise, npm, go, cargo, etc.)
- Systems are running low on disk space and cache cleanup is needed
- Tools need to be reset due to cache corruption
- Users want to understand what caches are consuming space

## Workflow

### Phase 1: Pre-Check Analysis

Before cleaning, analyze what will be removed:

1. **Identify target caches** - Determine which tool caches to clean
2. **Report cache sizes** - Show current disk usage for each cache
3. **List impacted tools** - Display tools that depend on each cache
4. **User confirmation** - Ask for permission before proceeding

### Phase 2: Cleanup Execution

Execute cleanup for confirmed caches:

1. **Run cleanup commands** - Use tool-specific cleanup methods
2. **Handle errors gracefully** - Continue if individual cleanup fails
3. **Log actions taken** - Document what was cleaned

### Phase 3: Post-Check Verification

Verify tools remain functional:

1. **Test tool availability** - Verify each tool still runs
2. **Report versions** - Confirm tool versions post-cleanup
3. **Document failures** - Flag any tools that stopped working
4. **Provide summary** - Show total space reclaimed and any issues

## Supported Caches

### mise

**Location**: `~/.cache/mise/`, `~/.local/share/mise/installs/`

**Cleanup commands**:
```bash
mise cache clean          # Clear cache
mise prune --yes          # Remove old versions
```

**Pre-check reports**:
- Cache directory size
- Number of installed tools
- Old versions that can be pruned

**Post-check verifies**:
- mise command works
- Lists installed tools
- Reports current version

### npm

**Location**: `~/.npm/`

**Cleanup command**:
```bash
npm cache clean --force
```

**Pre-check reports**:
- npm cache size
- Number of global packages

**Post-check verifies**:
- npm command works
- Reports npm version
- Lists global packages

### Go (golang)

**Location**: `~/go/pkg/mod/`

**Cleanup command**:
```bash
go clean -modcache
```

**Pre-check reports**:
- Go module cache size
- Number of cached modules

**Post-check verifies**:
- go command works
- Reports go version

### Cargo (Rust)

**Location**: `~/.cargo/registry/`

**Cleanup commands**:
```bash
cargo-cache                # If cargo-cache installed
rm -rf ~/.cargo/registry/.cache  # Manual fallback
```

**Pre-check reports**:
- Cargo registry cache size
- Number of cached crates

**Post-check verifies**:
- cargo command works
- Reports cargo version

### uv

**Location**: `~/.cache/uv/`

**Cleanup command**:
```bash
rm -rf ~/.cache/uv
```

**Pre-check reports**:
- uv cache size

**Post-check verifies**:
- uv command works (if installed)
- Reports uv version

### pipx

**Location**: `~/.local/pipx/shared/`, `~/.local/pipx/venvs/`

**Cleanup command**:
```bash
rm -rf ~/.local/pipx/venvs/*  # Remove venvs, keep shared cache
```

**Pre-check reports**:
- pipx shared cache size
- Number of installed packages

**Post-check verifies**:
- pipx command works
- Reports pipx version
- Lists installed packages

### pip

**Location**: `~/.cache/pip/`

**Cleanup commands**:
```bash
pip cache purge
# or
rm -rf ~/.cache/pip/*
```

**Pre-check reports**:
- pip cache size

**Post-check verifies**:
- pip command works
- Reports pip version

## Using the Script

This skill includes `scripts/cleanup_caches.sh` which automates the entire workflow.

### Interactive Usage

```bash
# Launch interactive selection
~/.claude/skills/cache-cleanup/scripts/cleanup_caches.sh

# Select specific caches
~/.claude/skills/cache-cleanup/scripts/cleanup_caches.sh --mise --npm --go

# Clean all caches
~/.claude/skills/cache-cleanup/scripts/cleanup_caches.sh --all

# Dry run (show what would be cleaned)
~/.claude/skills/cache-cleanup/scripts/cleanup_caches.sh --all --dry-run

# Verbose output
~/.claude/skills/cache-cleanup/scripts/cleanup_caches.sh --all --verbose
```

### Script Features

- **Interactive selection** - Uses dialog for cache selection (falls back to prompt)
- **Color-coded output** - Visual feedback for info, success, warnings, errors
- **Confirmation prompts** - Asks before each cleanup operation
- **Dry-run mode** - Preview changes without executing
- **Error handling** - Continues on individual failures, reports summary
- **Space calculation** - Reports disk usage before and after

## Manual Cleanup (Alternative to Script)

If the script is unavailable, perform cleanup manually:

1. Check cache size
2. Run cleanup command
3. Verify tool functionality

Example for npm:
```bash
# Pre-check
du -sh ~/.npm
npm list -g --depth=0

# Cleanup
npm cache clean --force

# Post-check
npm --version
npm list -g --depth=0
```

## Safety Considerations

### Cache Cleanup Risks

| Cache | Risk Level | Impact of Cleanup |
|-------|------------|-------------------|
| mise | Low | Tools re-download as needed |
| npm | Low | Packages re-download on install |
| go | Medium | Modules re-download on build |
| cargo | Medium | Crates re-download on build |
| uv | Low | Packages re-download on install |
| pipx | Low | Shared libs kept, venvs recreated |
| pip | Low | Packages re-download on install |

### When to Be Careful

- **Before important builds** - Don't clean Go/Cargo caches before builds
- **Slow internet** - Consider bandwidth before cleaning large caches
- **Offline work** - Don't clean if you need tools offline
- **Shared environments** - Check with team before cleaning shared caches

## Recovery

If tools stop working after cleanup:

1. **Reinstall the tool** - Use mise or package manager
2. **Rebuild cache** - Run a build/install operation to repopulate cache
3. **Check tool paths** - Verify tool is in PATH
4. **Check permissions** - Ensure cache directories are writable

## Resources

### scripts/

- **cleanup_caches.sh** - Interactive cache cleanup script with pre-check, cleanup, and post-check phases

### references/

This skill does not include reference documentation.

### assets/

This skill does not include assets.
