---
name: cache-cleanup
description: Use when cleaning up development tool caches from mise, npm, Go, Cargo, uv, pipx, or pip - interactive cleanup with pre-check and post-check verification to ensure tools remain functional
---

# Cache Cleanup

## Overview

Interactive cache cleanup for development toolchains with three-phase safety verification: **pre-check** → **cleanup** → **post-check**. Supports 9 cache types, auto-discovery, parallel execution, and audit logging.

## When to Use

- User says "clean cache", "free disk space", "clear npm/mise/cargo cache"
- Tool cache corruption (e.g., mise npm backend race conditions)
- Routine maintenance or before disk-intensive operations
- User asks what caches are consuming space

## Quick Start

```bash
# Recommended: preview first, then execute
./scripts/cleanup_caches.sh --auto --dry-run --yes    # Preview what exists
./scripts/cleanup_caches.sh --auto --yes               # Execute cleanup
./scripts/cleanup_caches.sh --all --yes --parallel     # Clean everything fast
```

## AI Agent Workflow

When an AI agent invokes this skill, follow this exact workflow:

### 1. Pre-Check (Always)

Run dry-run first to see what exists and what would be cleaned:

```bash
./scripts/cleanup_caches.sh --auto --dry-run --yes
```

Review the output:
- **Cache sizes**: Note actual sizes (mise reports cache + installs combined)
- **Warnings**: Check for corrupted files or missing tools
- **Selection**: Confirm the auto-discovered caches match expectations

Report to user what will be cleaned and approximate sizes.

### 2. Execute Cleanup

Run the actual cleanup with `--yes` for non-interactive mode:

```bash
./scripts/cleanup_caches.sh --auto --yes
```

For multiple caches where speed matters, add `--parallel`:
```bash
./scripts/cleanup_caches.sh --all --yes --parallel
```

### 3. Post-Check Verification

The script handles post-check automatically, but verify:

- Exit code is 0 (non-zero means at least one cache failed)
- Summary table shows ✓ for all cleaned caches
- No "NOT working" errors in output
- All tools respond to `--version`

If any tool fails post-check, report immediately and suggest recovery steps.

## Script Options

| Flag | Description |
|------|-------------|
| `--all` | Clean all 9 cache types |
| `--auto` | Only clean caches that exist on this system |
| `--mise`, `--npm`, `--yarn`, `--pnpm`, `--go`, `--cargo`, `--uv`, `--pipx`, `--pip` | Clean specific cache(s) |
| `--dry-run` | Preview only — no changes made |
| `-y`, `--yes` | Auto-confirm all operations (required for non-interactive) |
| `--parallel` | Run cleanups concurrently (implies `--yes`) |
| `--verify` | Run `npm cache verify` instead of full clean (npm only, lighter) |
| `-q`, `--quiet` | Suppress info output — show only warnings and summary |
| `-v`, `--verbose` | Show detailed output including stderr |
| `-h`, `--help` | Full usage documentation |

## Supported Caches

| Cache | Paths | Risk | Cleanup Method | Regenerates? |
|-------|-------|------|----------------|-------------|
| **mise** | `~/.cache/mise` + `~/.local/share/mise/installs` | Low | `mise cache clean`, `mise prune --yes` | Re-downloads on use |
| **npm** | `~/.npm` | Low | `npm cache clean --force` + remove `~/.npm/_cacache` | Re-downloads on install |
| **yarn** | Dynamic (`yarn cache dir`) | Low | `yarn cache clean` | Re-downloads on install |
| **pnpm** | Dynamic (`pnpm store path`) | Low | `pnpm store prune` | Re-downloads on install |
| **Go** | `~/go/pkg/mod` | Medium | `go clean -modcache` | Re-downloads on build |
| **Cargo** | `~/.cargo/registry/.cache` | Medium | `cargo-cache` or `rm -rf .cache` | Re-downloads on build |
| **uv** | `~/.cache/uv` | Low | `uv cache clean --force` | Re-downloads on install |
| **pipx** | `~/.local/pipx/venvs` | **HIGH** | `rm -rf venvs/*` | **Must reinstall manually** |
| **pip** | `~/.cache/pip` | Low | `pip cache purge` | Re-downloads on install |

### Important Notes

**npm cache reclamation**: On modern npm (v9/v10+), `npm cache clean --force` alone frees ~0 bytes — it clears the `_cacache/index-v5` mapping but leaves the `_cacache/content-v2` tarball blobs orphaned on disk. To genuinely reclaim space, the script also removes `~/.npm/_cacache` after `clean --force`; npm lazily rebuilds and re-downloads on demand (safe — this is what older npm's `clean` effectively did). The "Saved" column therefore reflects the real `_cacache` reclamation. Use `--verify` to run only `npm cache verify` (lighter, no payload removal — verifies/dedupes indexed content but does not bulk-reclaim).

**mise npm backend corruption**: The npm backend (`npm:` prefixed tools) stores cache in `~/.cache/mise/npm-*`. Concurrent `mise upgrade` with `jobs > 1` causes race conditions. Corrupted `.msgpack.z` files produce warnings like `failed to parse cache file... failed to fill whole buffer`. The script detects and cleans these.

**pipx is destructive**: Removing pipx venvs uninstalls ALL pipx-managed tools. Even with `--yes`, the script warns about this. Always list installed tools first: `pipx list`.

**yarn/pnpm dynamic paths**: These tools report their cache/store paths dynamically. The script queries `yarn cache dir` / `pnpm store path` and falls back to common default paths if the CLI is unavailable.

## Safety Guidelines

### Before Cleanup

1. **Always dry-run first**: `--dry-run` shows what would be cleaned without making changes
2. **Check disk pressure**: `df -h /home` — if usage < 50%, cleanup is optional
3. **Review pipx tools**: `pipx list` — if important tools installed, skip pipx or note for reinstallation
4. **Check for active builds**: Don't clean Go/Cargo caches during builds

### During Cleanup

- The script measures cache sizes **immediately after cleanup**, before post-check tool invocations
- The "After" column reflects the on-disk state right after the cleanup action
- For caches with a large non-reclaimable baseline (e.g. mise active tool installs), a "footprint breakdown" line is printed under the table so a small "Saved" is not mistaken for a failure
- Parallel mode runs cleanups concurrently but post-checks sequentially (for accurate output)

### After Cleanup

- Verify exit code is 0
- Check summary table for any failures
- pip/uv caches will partially regenerate on next tool invocation — this is normal (npm's `_cacache` is removed outright and rebuilt lazily on demand)
- If a tool breaks, see Recovery section below

## Output Format

### Summary Table

```
┌──────────┬──────────────┬──────────────┬──────────────┬─────────┐
│ Cache    │ Before       │ After        │ Saved        │ Status  │
├──────────┼──────────────┼──────────────┼──────────────┼─────────┤
│ mise     │       265KiB │       265KiB │           0B │   ✓     │
│ npm      │       1.8GiB │       1.7GiB │        41MiB │   ✓     │
│ pipx     │        28KiB │         0B   │        28KiB │   ✓     │
├──────────┼──────────────┼──────────────┼──────────────┼─────────┤
│ TOTAL    │       1.8GiB │       1.7GiB │        41MiB │         │
└──────────┴──────────────┴──────────────┴──────────────┴─────────┘

On-disk footprint breakdown (not all reclaimable):
  mise:     active tool installs 3.5GiB (not cache; only unreferenced versions are prunable, 0B pruned this run)
```

- **Status** = `✓` (cleaned), `skip` (skipped), `dry-run` (preview only)
- **npm** "Before/After/Saved" measure the whole `~/.npm`; Saved reflects the `_cacache` payload actually removed
- **mise** "Before" measures only the cleanable cache dir; the active tool installs baseline is shown in the breakdown so a small "Saved" is not mistaken for a failure

### Logs

Written to `~/.cache/cleanup-YYYYMMDD-HHMMSS.log` (and `.err` for warnings/errors).
Last 10 log pairs retained automatically.

## Manual Cleanup

If the script is unavailable, clean individual caches:

```bash
# Pre-check: measure size
du -sh ~/.npm

# Cleanup — clean --force alone frees ~0 bytes on modern npm (v9/v10+);
# also remove _cacache to genuinely reclaim the payload. npm rebuilds lazily.
npm cache clean --force
rm -rf ~/.npm/_cacache

# Post-check: verify tool works
npm --version
```

## Recovery

| Tool | Recovery |
|------|----------|
| mise | `mise install` — tools re-download automatically |
| npm | `npm install` — packages re-download from registry |
| Go | `go mod download` — modules re-download on next build |
| Cargo | `cargo build` — crates re-download on next build |
| uv | `uv pip install` — packages re-download from registry |
| pipx | `pipx install <tool>` — **must reinstall manually** |
| pip | `pip install` — packages re-download from registry |

## SRE Principles

- **Safety first**: Always `--dry-run` before executing. Pre-check → Execute → Verify.
- **Evidence-driven**: Script reports exact byte sizes before/after. Use `--verbose` for stderr capture.
- **Audit-ready**: Timestamped logs with operator identity. Automatic rotation at 10 files.
- **Idempotent**: Running multiple times is safe. Already-clean caches report 0B.
- **Fail-open**: Individual cache failures don't block others. Failed caches reported in summary.

## Files

- `scripts/cleanup_caches.sh` — Main cleanup script (single file, no external dependencies beyond standard Linux tools)
