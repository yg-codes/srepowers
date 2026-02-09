#!/bin/bash
# Interactive cache cleanup script with pre-check, cleanup, and post-check verification
# Usage: scripts/cleanup_caches.sh [--all] [--mise] [--npm] [--go] [--cargo] [--uv] [--pipx] [--pip]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=0
DRY_RUN=0
SELECTED_CACHES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      SELECTED_CACHES=("mise" "npm" "go" "cargo" "uv" "pipx" "pip")
      shift
      ;;
    --mise|--npm|--go|--cargo|--uv|--pipx|--pip)
      SELECTED_CACHES+=("${1#--}")
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS] [CACHE_TYPES...]"
      echo ""
      echo "Interactive cache cleanup with pre-check, cleanup, and post-check verification"
      echo ""
      echo "Options:"
      echo "  --all          Clean all caches"
      echo "  --mise         Clean mise cache"
      echo "  --npm          Clean npm cache"
      echo "  --go           Clean Go module cache"
      echo "  --cargo        Clean Cargo registry cache"
      echo "  --uv           Clean uv cache"
      echo "  --pipx         Clean pipx cache"
      echo "  --pip          Clean pip cache"
      echo "  --dry-run      Show what would be cleaned without cleaning"
      echo "  --verbose      Show detailed output"
      echo "  -h, --help     Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Interactive selection if no caches specified
if [[ ${#SELECTED_CACHES[@]} -eq 0 ]]; then
  echo -e "${BLUE}=== Cache Cleanup Tool ===${NC}"
  echo ""
  echo "Select caches to clean (space to select, enter to continue):"
  echo ""

  # Define valid cache types for validation
  VALID_CACHES=("mise" "npm" "go" "cargo" "uv" "pipx" "pip")

  # Use dialog for interactive selection if available, otherwise use simple prompt
  if command -v dialog &> /dev/null; then
    CMD=(dialog --separate-output --checklist "Select caches to clean:" 22 76 16)
    OPTIONS=(
      1 "mise" off
      2 "npm" off
      3 "go" off
      4 "cargo" off
      5 "uv" off
      6 "pipx" off
      7 "pip" off
    )
    CHOICES=$("${CMD[@]}" "${OPTIONS[@]}" 2>&1 >/dev/tty)
    clear

    if [[ -z "$CHOICES" ]]; then
      echo -e "${YELLOW}No caches selected. Exiting.${NC}"
      exit 0
    fi

    for choice in $CHOICES; do
      case $choice in
        1) SELECTED_CACHES+=("mise") ;;
        2) SELECTED_CACHES+=("npm") ;;
        3) SELECTED_CACHES+=("go") ;;
        4) SELECTED_CACHES+=("cargo") ;;
        5) SELECTED_CACHES+=("uv") ;;
        6) SELECTED_CACHES+=("pipx") ;;
        7) SELECTED_CACHES+=("pip") ;;
      esac
    done
  else
    # Fallback to simple prompt
    echo "Available caches: mise, npm, go, cargo, uv, pipx, pip"
    echo -n "Enter cache names (comma-separated): "
    read -r INPUT
    IFS=',' read -ra SELECTED_CACHES <<< "$INPUT"
    SELECTED_CACHES=("${SELECTED_CACHES[@]// /}")  # Trim whitespace
  fi

  # Validate cache types
  for cache in "${SELECTED_CACHES[@]}"; do
    if [[ ! " ${VALID_CACHES[@]} " =~ " ${cache} " ]]; then
      log_error "Invalid cache type: $cache"
      log_error "Valid types: ${VALID_CACHES[*]}"
      exit 1
    fi
  done
fi

# Log functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Get directory size
get_size() {
  local path="$1"
  if [[ -d "$path" ]]; then
    du -sh "$path" 2>/dev/null | cut -f1
  elif [[ -f "$path" ]]; then
    du -sh "$path" 2>/dev/null | cut -f1
  else
    echo "0"
  fi
}

# Test tool availability
test_tool() {
  local tool="$1"
  case $tool in
    mise)
      command -v mise &> /dev/null && mise --version &> /dev/null
      ;;
    npm)
      command -v npm &> /dev/null && npm --version &> /dev/null
      ;;
    go)
      command -v go &> /dev/null && go version &> /dev/null
      ;;
    cargo)
      command -v cargo &> /dev/null && cargo --version &> /dev/null
      ;;
    uv)
      command -v uv &> /dev/null && uv --version &> /dev/null
      ;;
    pipx)
      command -v pipx &> /dev/null && pipx --version &> /dev/null
      ;;
    pip)
      command -v pip &> /dev/null && pip --version &> /dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

# Pre-check: Analyze caches before cleanup
pre_check() {
  local cache_type="$1"
  log_info "Pre-check: Analyzing $cache_type cache..."

  case $cache_type in
    mise)
      if [[ -d ~/.cache/mise ]]; then
        echo "  Location: ~/.cache/mise"
        echo "  Size: $(get_size ~/.cache/mise)"
        echo "  Tools installed: $(mise list 2>/dev/null | wc -l)"
      else
        log_warning "No mise cache found"
        return 1
      fi
      ;;
    npm)
      if [[ -d ~/.npm ]]; then
        echo "  Location: ~/.npm"
        echo "  Size: $(get_size ~/.npm)"
        echo "  Global packages: $(npm list -g --depth=0 2>/dev/null | wc -l)"
      else
        log_warning "No npm cache found"
        return 1
      fi
      ;;
    go)
      if [[ -d ~/go/pkg/mod ]]; then
        echo "  Location: ~/go/pkg/mod"
        echo "  Size: $(get_size ~/go/pkg/mod)"
      else
        log_warning "No Go module cache found"
        return 1
      fi
      ;;
    cargo)
      if [[ -d ~/.cargo/registry ]]; then
        echo "  Location: ~/.cargo/registry"
        echo "  Size: $(get_size ~/.cargo/registry)"
      else
        log_warning "No Cargo registry cache found"
        return 1
      fi
      ;;
    uv)
      if [[ -d ~/.cache/uv ]]; then
        echo "  Location: ~/.cache/uv"
        echo "  Size: $(get_size ~/.cache/uv)"
      else
        log_warning "No uv cache found"
        return 1
      fi
      ;;
    pipx)
      if [[ -d ~/.local/pipx ]]; then
        echo "  Location: ~/.local/pipx/shared"
        echo "  Size: $(get_size ~/.local/pipx/shared)"
        echo "  Installed packages: $(pipx list 2>/dev/null | wc -l)"
      else
        log_warning "No pipx cache found"
        return 1
      fi
      ;;
    pip)
      if [[ -d ~/.cache/pip ]]; then
        echo "  Location: ~/.cache/pip"
        echo "  Size: $(get_size ~/.cache/pip)"
      else
        log_warning "No pip cache found"
        return 1
      fi
      ;;
  esac

  return 0
}

# Cleanup function
cleanup_cache() {
  local cache_type="$1"

  if [[ $DRY_RUN -eq 1 ]]; then
    log_warning "DRY RUN: Would clean $cache_type cache"
    return 0
  fi

  log_info "Cleaning $cache_type cache..."

  case $cache_type in
    mise)
      mise cache clean &> /dev/null
      mise prune --yes &> /dev/null
      log_success "mise cache cleaned"
      ;;
    npm)
      npm cache clean --force &> /dev/null
      log_success "npm cache cleaned"
      ;;
    go)
      go clean -modcache &> /dev/null
      log_success "Go module cache cleaned"
      ;;
    cargo)
      if command -v cargo-cache &> /dev/null; then
        cargo-cache &> /dev/null
      else
        rm -rf ~/.cargo/registry/.cache
      fi
      log_success "Cargo cache cleaned"
      ;;
    uv)
      rm -rf ~/.cache/uv
      log_success "uv cache cleaned"
      ;;
    pipx)
      # pipx doesn't have a clean command, but shared cache is small
      # Just remove old venvs
      rm -rf ~/.local/pipx/venvs/*
      log_success "pipx venvs cleaned (shared cache kept)"
      ;;
    pip)
      pip cache purge &> /dev/null || rm -rf ~/.cache/pip/*
      log_success "pip cache cleaned"
      ;;
  esac

  return 0
}

# Post-check: Verify tools still work
post_check() {
  local cache_type="$1"
  local exit_code=0

  log_info "Post-check: Verifying $cache_type functionality..."

  case $cache_type in
    mise)
      if test_tool mise; then
        echo "  ✓ mise is working"
        echo "  Version: $(mise --version | head -1)"
      else
        log_error "mise is not working!"
        exit_code=1
      fi
      ;;
    npm)
      if test_tool npm; then
        echo "  ✓ npm is working"
        echo "  Version: $(npm --version)"
      else
        log_error "npm is not working!"
        exit_code=1
      fi
      ;;
    go)
      if test_tool go; then
        echo "  ✓ go is working"
        echo "  Version: $(go version | head -1)"
      else
        log_error "go is not working!"
        exit_code=1
      fi
      ;;
    cargo)
      if test_tool cargo; then
        echo "  ✓ cargo is working"
        echo "  Version: $(cargo --version | head -1)"
      else
        log_error "cargo is not working!"
        exit_code=1
      fi
      ;;
    uv)
      if test_tool uv; then
        echo "  ✓ uv is working"
        echo "  Version: $(uv --version | head -1)"
      else
        log_warning "uv is not installed (this may be expected)"
      fi
      ;;
    pipx)
      if test_tool pipx; then
        echo "  ✓ pipx is working"
        echo "  Version: $(pipx --version | head -1)"
        echo "  Installed packages: $(pipx list 2>/dev/null | wc -l)"
      else
        log_error "pipx is not working!"
        exit_code=1
      fi
      ;;
    pip)
      if test_tool pip; then
        echo "  ✓ pip is working"
        echo "  Version: $(pip --version | head -1)"
      else
        log_error "pip is not working!"
        exit_code=1
      fi
      ;;
  esac

  return $exit_code
}

# Main execution
main() {
  echo ""
  log_info "Starting cache cleanup process..."
  echo ""

  local total_before=0
  local total_after=0
  local failed_cleanup=()

  for cache_type in "${SELECTED_CACHES[@]}"; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Processing: $cache_type${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Pre-check
    if pre_check "$cache_type"; then
      echo ""

      # Confirm cleanup
      if [[ $DRY_RUN -eq 0 ]]; then
        echo -n "Continue with cleanup? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
          log_warning "Skipping $cache_type cleanup"
          echo ""
          continue
        fi
      fi

      # Cleanup
      if cleanup_cache "$cache_type"; then
        echo ""

        # Post-check
        if ! post_check "$cache_type"; then
          failed_cleanup+=("$cache_type")
        fi
      else
        failed_cleanup+=("$cache_type")
      fi
    else
      log_warning "Skipping $cache_type (pre-check failed)"
    fi

    echo ""
  done

  # Summary
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}Summary${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""

  if [[ ${#failed_cleanup[@]} -gt 0 ]]; then
    log_error "Failed to clean the following caches:"
    for cache in "${failed_cleanup[@]}"; do
      echo "  - $cache"
    done
    echo ""
    exit 1
  else
    log_success "All caches cleaned successfully!"
    echo ""
  fi
}

# Run main
main "$@"
