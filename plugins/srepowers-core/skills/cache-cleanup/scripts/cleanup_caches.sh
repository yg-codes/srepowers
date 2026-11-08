#!/bin/bash
# cache-cleanup: Interactive cache cleanup with pre-check, cleanup, and post-check verification
# Usage: scripts/cleanup_caches.sh [--all] [--auto] [--mise] [--npm] [--yarn] [--pnpm] [--go] [--cargo] [--uv] [--pipx] [--pip]
#
# Features:
#   - Auto-discovery of existing caches (--auto)
#   - Parallel cleanup for independent caches (--parallel)
#   - Accurate size tracking (measures immediately after cleanup, before tool verification)
#   - Audit logging with automatic rotation (keeps last 10 logs)
#   - Dry-run mode for preview
#   - Quiet mode for CI/CD
#   - Interactive numbered menu (no external dependencies)
#   - Safety prompts for destructive operations (pipx)
#   - npm cache verify as lighter alternative before full clean

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Configuration ──────────────────────────────────────────────────────────
VERBOSE=0
DRY_RUN=0
AUTO_CONFIRM=0
PARALLEL=0
QUIET=0
VERIFY_ONLY=0
SELECTED_CACHES=()
declare -A CACHE_SIZES_BEFORE
declare -A CACHE_SIZES_AFTER
declare -A CACHE_CLEANED_OK
# Detail-path sizes (reference baselines like mise installs, full npm dir).
# Captured so the summary can show large non-reclaimable footprints honestly.
declare -A CACHE_DETAIL_BEFORE
declare -A CACHE_DETAIL_AFTER
FAILED_CACHES=()

# ─── Cache Registry ─────────────────────────────────────────────────────────
CACHE_ORDER=(mise npm yarn pnpm go cargo uv pipx pip)
VALID_CACHES=("${CACHE_ORDER[@]}")

# Paths to measure for size (colon-separated for multiple paths).
#
# NOTE on npm: we measure the whole ~/.npm dir. The cleanup action removes
# ~/.npm/_cacache (see cleanup_cache npm case) — on modern npm (v9/v10+),
# `npm cache clean --force` alone frees ~0 bytes: it clears the index-v5
# mapping but leaves the content-v2 tarball blobs orphaned on disk. Only
# deleting _cacache reclaims the space (npm lazily rebuilds and re-downloads
# on demand, so this is safe and is what older npm's `clean` effectively did).
# Measuring the whole dir makes the Before/After/Saved columns reflect the
# genuine reclamation rather than reporting a misleading "0 B saved".
#
# NOTE on mise: ~/.cache/mise is the cleanable cache; ~/.local/share/mise/installs
# holds active tool versions (large — often GiB — and only partially reclaimable
# via `mise prune`, which removes *unreferenced* versions only). To avoid a
# misleading giant "Before" / tiny "Saved" row, the table measures the cache dir
# as the reclaimable baseline. Installs are still measured (prune can shrink
# them) and shown as a breakdown detail, and prune's effect is captured in the
# After measurement. See CACHE_DETAIL_PATHS and print_space_summary.
declare -A CACHE_PATHS
CACHE_PATHS=(
  ["mise"]="$HOME/.cache/mise"
  ["npm"]="$HOME/.npm"
  ["yarn"]="dynamic"
  ["pnpm"]="dynamic"
  ["go"]="$HOME/go/pkg/mod"
  ["cargo"]="$HOME/.cargo/registry/.cache"
  ["uv"]="$HOME/.cache/uv"
  ["pipx"]="$HOME/.local/pipx"
  ["pip"]="$HOME/.cache/pip"
)

# Extra paths measured for reference/breakdown but NOT counted in the table's
# reclaimable total. Used to surface large non-reclaimable baselines (e.g. mise
# active tool installs) so the summary is not misleading. Colon-separated.
declare -A CACHE_DETAIL_PATHS
CACHE_DETAIL_PATHS=(
  ["mise"]="$HOME/.local/share/mise/installs"
)

# Risk levels
declare -A CACHE_RISKS
CACHE_RISKS=(
  ["mise"]="low"
  ["npm"]="low"
  ["yarn"]="low"
  ["pnpm"]="low"
  ["go"]="medium"
  ["cargo"]="medium"
  ["uv"]="low"
  ["pipx"]="high"
  ["pip"]="low"
)

# Display labels
declare -A CACHE_LABELS
CACHE_LABELS=(
  ["mise"]="mise (cache + tool installs)"
  ["npm"]="npm"
  ["yarn"]="yarn"
  ["pnpm"]="pnpm"
  ["go"]="Go modules"
  ["cargo"]="Cargo registry"
  ["uv"]="uv"
  ["pipx"]="pipx (DESTRUCTIVE — removes installed tools!)"
  ["pip"]="pip"
)

# ─── Logging Setup ──────────────────────────────────────────────────────────
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOG_TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/cleanup-${LOG_TS}.log"
ERROR_FILE="$LOG_DIR/cleanup-${LOG_TS}.err"
MAX_LOGS=10

init_logging() {
  mkdir -p "$LOG_DIR"
  {
    echo "=== Cache Cleanup Log ==="
    echo "Started:  $(date)"
    echo "Operator: ${USER:-unknown}"
    echo "Args:     $*"
    echo ""
  } > "$LOG_FILE"
  {
    echo "=== Cache Cleanup Errors ==="
    echo "Started: $(date)"
    echo ""
  } > "$ERROR_FILE"
}

log_to_file() {
  local level="$1" message="$2"
  echo "[$(date '+%H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

log_info() {
  [[ $QUIET -eq 0 ]] && echo -e "${BLUE}[INFO]${NC} $1"
  log_to_file "INFO" "$1"
}

log_success() {
  [[ $QUIET -eq 0 ]] && echo -e "${GREEN}[OK]${NC}    $1"
  log_to_file "OK" "$1"
}

log_warning() {
  echo -e "${YELLOW}[WARN]${NC}  $1"
  log_to_file "WARN" "$1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
  log_to_file "ERROR" "$1"
  echo "[$(date '+%H:%M:%S')] $1" >> "$ERROR_FILE"
}

log_verbose() {
  if [[ $VERBOSE -eq 1 ]]; then
    [[ $QUIET -eq 0 ]] && echo -e "${CYAN}[DBG]${NC}   $1"
  fi
  log_to_file "DBG" "$1"
}

# Always prints — used for summary table and final results
log_output() {
  echo -e "$1"
}

# Detail lines (suppressed in quiet mode)
log_detail() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "$1"
  fi
}

# ─── Log Rotation ───────────────────────────────────────────────────────────
rotate_logs() {
  local count
  count=$(find "$LOG_DIR" -maxdepth 1 -name 'cleanup-*.log' -type f 2>/dev/null | wc -l)
  if [[ $count -gt $MAX_LOGS ]]; then
    local to_remove=$((count - MAX_LOGS))
    find "$LOG_DIR" -maxdepth 1 -name 'cleanup-*.log' -type f -printf '%T@ %p\n' 2>/dev/null \
      | sort -n | head -n "$to_remove" | awk '{print $2}' | xargs rm -f 2>/dev/null || true
    find "$LOG_DIR" -maxdepth 1 -name 'cleanup-*.err' -type f -printf '%T@ %p\n' 2>/dev/null \
      | sort -n | head -n "$to_remove" | awk '{print $2}' | xargs rm -f 2>/dev/null || true
    log_verbose "Rotated $to_remove old log files"
  fi
}

# ─── Helper Functions ───────────────────────────────────────────────────────

# Convert bytes to human-readable (uses numfmt, falls back to integer division)
bytes_to_human() {
  local bytes=${1:-0}
  if command -v numfmt &>/dev/null; then
    numfmt --to=iec-i --suffix=B "$bytes" 2>/dev/null && return
  fi
  # Fallback without bc
  if [[ $bytes -ge 1073741824 ]]; then
    echo "$((bytes / 1073741824))GiB"
  elif [[ $bytes -ge 1048576 ]]; then
    echo "$((bytes / 1048576))MiB"
  elif [[ $bytes -ge 1024 ]]; then
    echo "$((bytes / 1024))KiB"
  else
    echo "${bytes}B"
  fi
}

# Resolve dynamic cache paths (yarn, pnpm)
resolve_cache_path() {
  local cache_type="$1"
  if [[ "${CACHE_PATHS[$cache_type]:-}" == "dynamic" ]]; then
    case $cache_type in
      yarn)
        if command -v yarn &>/dev/null; then
          local p
          p=$(yarn cache dir 2>/dev/null) && echo "$p" && return
        fi
        # Common fallback paths
        for d in "$HOME/.cache/yarn" "$HOME/.yarn/berry/cache" "$HOME/Library/Caches/Yarn"; do
          [[ -d "$d" ]] && echo "$d" && return
        done
        echo ""
        ;;
      pnpm)
        if command -v pnpm &>/dev/null; then
          local p
          p=$(pnpm store path 2>/dev/null) && echo "$p" && return
        fi
        for d in "$HOME/.local/share/pnpm/store" "$HOME/Library/pnpm/store"; do
          [[ -d "$d" ]] && echo "$d" && return
        done
        echo ""
        ;;
    esac
  else
    echo "${CACHE_PATHS[$cache_type]:-}"
  fi
}

# Get total size in bytes for a cache (sums colon-separated paths)
get_size_bytes() {
  local cache_type="$1"
  local paths_str
  paths_str=$(resolve_cache_path "$cache_type")
  [[ -z "$paths_str" ]] && echo "0" && return

  local total=0
  local IFS=':'
  for path in $paths_str; do
    if [[ -e "$path" ]]; then
      local sz
      sz=$(du -sb "$path" 2>/dev/null | cut -f1) || sz=0
      total=$((total + sz))
    fi
  done
  echo "$total"
}

# Get human-readable size for a cache
get_size_human() {
  bytes_to_human "$(get_size_bytes "$1")"
}

# Get total size in bytes for a cache's DETAIL (reference) paths.
# Returns 0 if no detail paths are registered for this cache type.
get_detail_size_bytes() {
  local cache_type="$1"
  local paths_str="${CACHE_DETAIL_PATHS[$cache_type]:-}"
  [[ -z "$paths_str" ]] && echo "0" && return

  local total=0
  local IFS=':'
  for path in $paths_str; do
    if [[ -e "$path" ]]; then
      local sz
      sz=$(du -sb "$path" 2>/dev/null | cut -f1) || sz=0
      total=$((total + sz))
    fi
  done
  echo "$total"
}

# Check if a cache exists (any of its paths exist)
cache_exists() {
  local cache_type="$1"
  local paths_str
  paths_str=$(resolve_cache_path "$cache_type")
  [[ -z "$paths_str" ]] && return 1

  local IFS=':'
  for path in $paths_str; do
    [[ -e "$path" ]] && return 0
  done
  return 1
}

# Test if a tool command works
test_tool() {
  local tool="$1"
  case $tool in
    mise)   command -v mise &>/dev/null && mise --version &>/dev/null ;;
    npm)    command -v npm &>/dev/null && npm --version &>/dev/null ;;
    yarn)   command -v yarn &>/dev/null && yarn --version &>/dev/null ;;
    pnpm)   command -v pnpm &>/dev/null && pnpm --version &>/dev/null ;;
    go)     command -v go &>/dev/null && go version &>/dev/null ;;
    cargo)  command -v cargo &>/dev/null && cargo --version &>/dev/null ;;
    uv)     command -v uv &>/dev/null && uv --version &>/dev/null ;;
    pipx)   command -v pipx &>/dev/null && pipx --version &>/dev/null ;;
    pip)    command -v pip &>/dev/null && pip --version &>/dev/null ;;
    *)      return 1 ;;
  esac
}

# Risk color indicator
risk_indicator() {
  local risk="${CACHE_RISKS[$1]:-unknown}"
  case $risk in
    low)    echo -e "${GREEN}[low]${NC}" ;;
    medium) echo -e "${YELLOW}[medium]${NC}" ;;
    high)   echo -e "${RED}[HIGH]${NC}" ;;
    *)      echo "[?]" ;;
  esac
}

# ─── Argument Parsing ───────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
  case $1 in
    --all)
      SELECTED_CACHES=("${CACHE_ORDER[@]}")
      shift
      ;;
    --auto)
      # Discover caches that actually exist on this system
      for cache in "${CACHE_ORDER[@]}"; do
        if cache_exists "$cache"; then
          SELECTED_CACHES+=("$cache")
        fi
      done
      shift
      ;;
    --mise|--npm|--yarn|--pnpm|--go|--cargo|--uv|--pipx|--pip)
      SELECTED_CACHES+=("${1#--}")
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose|-v)
      VERBOSE=1
      shift
      ;;
    -y|--yes)
      AUTO_CONFIRM=1
      shift
      ;;
    --parallel)
      PARALLEL=1
      shift
      ;;
    --quiet|-q)
      QUIET=1
      shift
      ;;
    --verify)
      # Only run npm cache verify (lighter alternative to full clean)
      VERIFY_ONLY=1
      shift
      ;;
    -h|--help)
      cat <<EOF
${BOLD}cache-cleanup${NC} — Interactive cache cleanup with safety verification

${BOLD}Usage:${NC}
  $(basename "$0") [OPTIONS] [CACHE_TYPES...]

${BOLD}Cache Types:${NC}
  --mise         mise cache + tool installs (prunes old versions)
  --npm          npm cache
  --yarn         yarn cache
  --pnpm         pnpm store
  --go           Go module cache
  --cargo        Cargo registry cache
  --uv           uv cache
  --pipx         pipx venvs (DESTRUCTIVE — removes installed tools!)
  --pip          pip cache
  --all          Clean all caches
  --auto         Only clean caches that exist on this system

${BOLD}Options:${NC}
  --dry-run      Preview what would be cleaned (no changes)
  -y, --yes      Auto-confirm all operations (non-interactive)
  --parallel     Run cleanups in parallel (implies --yes)
  --verify       Run npm cache verify instead of full clean (npm only)
  --quiet, -q    Suppress info output (show only warnings/errors/summary)
  --verbose, -v  Show detailed output including stderr
  -h, --help     Show this help

${BOLD}Examples:${NC}
  $(basename "$0") --auto --dry-run          # Preview cleanup of existing caches
  $(basename "$0") --mise --npm --yes        # Clean mise + npm, auto-confirm
  $(basename "$0") --all --parallel --yes    # Clean everything in parallel
  $(basename "$0") --npm --verify            # Verify npm cache (lighter than clean)
  $(basename "$0") --all --dry-run --verbose # Detailed preview

${BOLD}Logs:${NC}
  Written to ${LOG_DIR}/cleanup-YYYYMMDD-HHMMSS.{log,err}
  Last ${MAX_LOGS} log files retained automatically.
EOF
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC} (see --help)" >&2
      exit 1
      ;;
  esac
done

# --parallel implies --yes
if [[ $PARALLEL -eq 1 ]]; then
  AUTO_CONFIRM=1
fi

# ─── Interactive Menu (no args + TTY) ───────────────────────────────────────

# ─── Interactive Menu ──────────────────────────────────────────────────────

show_interactive_menu() {
  echo ""
  echo -e "${BOLD}${BLUE}╭─────────────────────────────────────╮${NC}"
  echo -e "${BOLD}${BLUE}│       Cache Cleanup Tool            │${NC}"
  echo -e "${BOLD}${BLUE}╰─────────────────────────────────────╯${NC}"
  echo ""
  echo "Select caches to clean:"
  echo ""

  local i=1
  for cache in "${CACHE_ORDER[@]}"; do
    local label="${CACHE_LABELS[$cache]}"
    local risk
    risk=$(risk_indicator "$cache")
    local exists=""
    cache_exists "$cache" && exists=" ${GREEN}✓${NC}" || exists=" ${NC}—${NC}"
    printf "  ${BOLD}%2d)${NC} %-36s %-12s %s\n" "$i" "$label" "$risk" "$exists"
    i=$((i + 1))
  done

  echo ""
  echo "  a) Select all    q) Quit"
  echo ""
  echo -n "Enter selections (space-separated numbers): "
  read -r INPUT

  if [[ -z "$INPUT" || "$INPUT" == "q" ]]; then
    echo "Cancelled."
    return 1
  fi

  if [[ "$INPUT" == "a" || "$INPUT" == "A" ]]; then
    SELECTED_CACHES=("${CACHE_ORDER[@]}")
  else
    for num in $INPUT; do
      if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "${#CACHE_ORDER[@]}" ]]; then
        SELECTED_CACHES+=("${CACHE_ORDER[$((num - 1))]}")
      else
        echo -e "${YELLOW}Skipping invalid selection: $num${NC}"
      fi
    done
  fi

  # Validate (exact string match — no regex/glob metachar semantics)
  local valid
  for cache in "${SELECTED_CACHES[@]}"; do
    valid=0
    for v in "${VALID_CACHES[@]}"; do
      [[ "$cache" == "$v" ]] && valid=1 && break
    done
    if [[ $valid -eq 0 ]]; then
      echo -e "${RED}Invalid cache type: $cache${NC}"
      return 1
    fi
  done

  if [[ ${#SELECTED_CACHES[@]} -eq 0 ]]; then
    echo "No caches selected. Exiting."
    return 1
  fi
  return 0
}

if [[ ${#SELECTED_CACHES[@]} -eq 0 ]]; then
  if [[ ! -t 0 ]]; then
    echo -e "${YELLOW}No cache types specified and no TTY detected.${NC}"
    echo ""
    echo "Usage: $(basename "$0") --auto --yes    # Clean existing caches"
    echo "       $(basename "$0") --all --dry-run # Preview all"
    echo "       $(basename "$0") --help           # Full help"
    exit 1
  fi

  if ! show_interactive_menu; then
    exit 0
  fi
fi

# ─── Pre-Check ──────────────────────────────────────────────────────────────

pre_check() {
  local cache_type="$1"
  local risk="${CACHE_RISKS[$cache_type]}"

  log_info "Pre-check: ${CACHE_LABELS[$cache_type]} (risk: $risk)"

  case $cache_type in
    mise)
      if ! cache_exists mise; then
        log_warning "No mise cache or installs found"
        return 1
      fi
      log_detail "  Cache:    $(get_size_human_for_path "$HOME/.cache/mise")"
      log_detail "  Installs: $(get_size_human_for_path "$HOME/.local/share/mise/installs")"
      log_detail "  Tools:    $(mise list 2>/dev/null | wc -l) installed"
      # Corrupted npm backend check
      local corrupted
      corrupted=$(find ~/.cache/mise/npm-* -name "*.msgpack.z" -size -100c 2>/dev/null | wc -l)
      if [[ $corrupted -gt 0 ]]; then
        log_warning "  Found $corrupted potentially corrupted npm backend cache files"
      fi
      ;;
    npm)
      if ! cache_exists npm; then
        log_warning "No npm cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human npm)  (removes _cacache payload; npm re-downloads on demand)"
      log_detail "  Global packages: $(npm list -g --depth=0 2>/dev/null | tail -n +2 | wc -l)"
      ;;
    yarn)
      if ! command -v yarn &>/dev/null && ! cache_exists yarn; then
        log_warning "yarn not installed and no cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human yarn)"
      if command -v yarn &>/dev/null; then
        log_detail "  Cache dir: $(yarn cache dir 2>/dev/null || echo 'unknown')"
      fi
      ;;
    pnpm)
      if ! command -v pnpm &>/dev/null && ! cache_exists pnpm; then
        log_warning "pnpm not installed and no store found"
        return 1
      fi
      log_detail "  Store: $(get_size_human pnpm)"
      if command -v pnpm &>/dev/null; then
        log_detail "  Store path: $(pnpm store path 2>/dev/null || echo 'unknown')"
      fi
      ;;
    go)
      if ! cache_exists go; then
        log_warning "No Go module cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human go)"
      ;;
    cargo)
      if ! cache_exists cargo; then
        log_warning "No Cargo registry cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human cargo)"
      log_detail "  Full registry: $(get_size_human_for_path "$HOME/.cargo/registry")"
      ;;
    uv)
      if ! cache_exists uv; then
        log_warning "No uv cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human uv)"
      ;;
    pipx)
      if ! cache_exists pipx; then
        log_warning "No pipx directory found"
        return 1
      fi
      local pkg_count
      pkg_count=$(find ~/.local/pipx/venvs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
      log_detail "  Size: $(get_size_human pipx)"
      log_detail "  Installed packages: $pkg_count"
      if [[ $pkg_count -gt 0 ]]; then
        log_warning "  This will UNINSTALL $pkg_count pipx-managed tools!"
      fi
      ;;
    pip)
      if ! cache_exists pip; then
        log_warning "No pip cache found"
        return 1
      fi
      log_detail "  Cache: $(get_size_human pip)"
      ;;
  esac

  # Record size before
  CACHE_SIZES_BEFORE["$cache_type"]=$(get_size_bytes "$cache_type")
  CACHE_DETAIL_BEFORE["$cache_type"]=$(get_detail_size_bytes "$cache_type")
  return 0
}

# Helper: human size for a single path
get_size_human_for_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    du -sh "$path" 2>/dev/null | cut -f1
  else
    echo "—"
  fi
}

# ─── Cleanup ────────────────────────────────────────────────────────────────

cleanup_cache() {
  local cache_type="$1"

  if [[ $DRY_RUN -eq 1 ]]; then
    log_warning "DRY RUN: Would clean ${CACHE_LABELS[$cache_type]}"
    return 0
  fi

  log_info "Cleaning ${CACHE_LABELS[$cache_type]}..."

  case $cache_type in
    mise)
      if [[ $VERBOSE -eq 1 ]]; then
        mise cache clean 2>&1 | tee -a "$ERROR_FILE" || true
        mise prune --yes 2>&1 | tee -a "$ERROR_FILE" || true
      else
        mise cache clean 2>>"$ERROR_FILE" || true
        mise prune --yes 2>>"$ERROR_FILE" || true
      fi
      # Clean npm backend cache (can become corrupted due to race conditions)
      rm -rf ~/.cache/mise/npm-* 2>/dev/null || true
      log_success "mise cleaned (cache + pruned old versions + npm backend)"
      ;;
    npm)
      if [[ $VERIFY_ONLY -eq 1 ]]; then
        if [[ $VERBOSE -eq 1 ]]; then
          npm cache verify 2>&1 | tee -a "$ERROR_FILE" || true
        else
          npm cache verify &>>"$ERROR_FILE" || true
        fi
        log_success "npm cache verified (lighter than full clean)"
      else
        if [[ $VERBOSE -eq 1 ]]; then
          npm cache clean --force 2>&1 | tee -a "$ERROR_FILE" || true
        else
          npm cache clean --force &>>"$ERROR_FILE" || true
        fi
        # `npm cache clean --force` alone frees ~0 bytes on modern npm (v9/v10+):
        # it clears the index-v5 mapping but leaves the content-v2 tarball blobs
        # orphaned on disk. Remove _cacache so the payload is genuinely freed;
        # npm lazily rebuilds and re-downloads on demand (safe; this is what
        # older npm's `clean` effectively did). Skip under --verify.
        rm -rf "$HOME/.npm/_cacache" 2>/dev/null || true
        log_success "npm cache cleaned (clean --force + removed _cacache payload)"
      fi
      ;;
    yarn)
      if command -v yarn &>/dev/null; then
        if [[ $VERBOSE -eq 1 ]]; then
          yarn cache clean 2>&1 | tee -a "$ERROR_FILE" || true
        else
          yarn cache clean 2>>"$ERROR_FILE" || true
        fi
      else
        # Remove known cache directories directly
        rm -rf ~/.cache/yarn ~/.yarn/berry/cache ~/Library/Caches/Yarn 2>/dev/null || true
      fi
      log_success "yarn cache cleaned"
      ;;
    pnpm)
      if command -v pnpm &>/dev/null; then
        if [[ $VERBOSE -eq 1 ]]; then
          pnpm store prune 2>&1 | tee -a "$ERROR_FILE" || true
        else
          pnpm store prune &>>"$ERROR_FILE" || true
        fi
      else
        rm -rf ~/.local/share/pnpm/store 2>/dev/null || true
      fi
      log_success "pnpm store pruned"
      ;;
    go)
      if [[ $VERBOSE -eq 1 ]]; then
        go clean -modcache 2>&1 | tee -a "$ERROR_FILE" || true
      else
        go clean -modcache &>>"$ERROR_FILE" || true
      fi
      log_success "Go module cache cleaned"
      ;;
    cargo)
      if command -v cargo-cache &>/dev/null; then
        if [[ $VERBOSE -eq 1 ]]; then
          cargo-cache 2>&1 | tee -a "$ERROR_FILE" || true
        else
          cargo-cache &>>"$ERROR_FILE" || true
        fi
      else
        rm -rf ~/.cargo/registry/.cache 2>/dev/null || true
      fi
      log_success "Cargo cache cleaned"
      ;;
    uv)
      if command -v uv &>/dev/null; then
        uv cache clean --force 2>/dev/null || rm -rf ~/.cache/uv 2>/dev/null || true
      else
        rm -rf ~/.cache/uv 2>/dev/null || true
      fi
      log_success "uv cache cleaned"
      ;;
    pipx)
      local pkg_count
      pkg_count=$(find ~/.local/pipx/venvs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
      if [[ $pkg_count -gt 0 ]]; then
        if [[ $AUTO_CONFIRM -eq 0 ]]; then
          echo -n "  Type 'yes' to confirm pipx cleanup (removes $pkg_count tools): "
          read -r confirm
          if [[ "$confirm" != "yes" ]]; then
            log_info "Skipping pipx cleanup"
            return 0
          fi
        else
          log_warning "Auto-confirm: removing $pkg_count pipx-managed tools"
        fi
      fi
      rm -rf ~/.local/pipx/venvs/* 2>/dev/null || true
      log_success "pipx venvs cleaned (shared cache kept)"
      ;;
    pip)
      if [[ $VERBOSE -eq 1 ]]; then
        pip cache purge 2>&1 | tee -a "$ERROR_FILE" || rm -rf ~/.cache/pip/* 2>/dev/null || true
      else
        pip cache purge &>>"$ERROR_FILE" || rm -rf ~/.cache/pip/* 2>/dev/null || true
      fi
      log_success "pip cache cleaned"
      ;;
  esac

  CACHE_CLEANED_OK["$cache_type"]=1
  return 0
}

# ─── Measure After (immediately after cleanup, before any tool invocation) ──

measure_after() {
  local cache_type="$1"
  CACHE_SIZES_AFTER["$cache_type"]=$(get_size_bytes "$cache_type")
  CACHE_DETAIL_AFTER["$cache_type"]=$(get_detail_size_bytes "$cache_type")
  log_verbose "Size after $cache_type: $(bytes_to_human "${CACHE_SIZES_AFTER[$cache_type]}")"
}

# ─── Post-Check ─────────────────────────────────────────────────────────────

post_check() {
  local cache_type="$1"

  log_info "Post-check: verifying $cache_type..."

  case $cache_type in
    mise)
      if test_tool mise; then
        log_success "mise working — $(mise --version 2>/dev/null | head -1)"
      else
        log_error "mise is NOT working after cleanup!"
        return 1
      fi
      ;;
    npm)
      if test_tool npm; then
        log_success "npm working — v$(npm --version)"
      else
        log_error "npm is NOT working after cleanup!"
        return 1
      fi
      ;;
    yarn)
      if test_tool yarn; then
        log_success "yarn working — $(yarn --version)"
      else
        # yarn may not be installed — that's OK if we just cleaned orphaned cache
        log_verbose "yarn not installed (expected if only cleaning orphaned cache)"
      fi
      ;;
    pnpm)
      if test_tool pnpm; then
        log_success "pnpm working — v$(pnpm --version)"
      else
        log_verbose "pnpm not installed (expected if only cleaning orphaned store)"
      fi
      ;;
    go)
      if test_tool go; then
        log_success "go working — $(go version | head -1)"
      else
        log_error "go is NOT working after cleanup!"
        return 1
      fi
      ;;
    cargo)
      if test_tool cargo; then
        log_success "cargo working — $(cargo --version | head -1)"
      else
        log_error "cargo is NOT working after cleanup!"
        return 1
      fi
      ;;
    uv)
      if test_tool uv; then
        log_success "uv working — $(uv --version | head -1)"
      else
        log_verbose "uv not installed (may be expected)"
      fi
      ;;
    pipx)
      if test_tool pipx; then
        local pkg_count
        pkg_count=$(find ~/.local/pipx/venvs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        log_success "pipx working — v$(pipx --version), $pkg_count packages installed"
        if [[ $pkg_count -eq 0 && $DRY_RUN -eq 0 ]]; then
          log_warning "All pipx packages were removed — reinstall with: pipx install <tool>"
        fi
      else
        log_error "pipx is NOT working after cleanup!"
        return 1
      fi
      ;;
    pip)
      if test_tool pip; then
        log_success "pip working — $(pip --version | head -1)"
      else
        log_error "pip is NOT working after cleanup!"
        return 1
      fi
      ;;
  esac
  return 0
}

# ─── Space Summary Table ────────────────────────────────────────────────────

print_space_summary() {
  local total_before=0
  local total_after=0

  echo ""
  log_output "${BLUE}┌──────────┬──────────────┬──────────────┬──────────────┬─────────┐${NC}"
  log_output "${BLUE}│${NC} ${BOLD}Cache${NC}    ${BLUE}│${NC} ${BOLD}Before${NC}       ${BLUE}│${NC} ${BOLD}After${NC}        ${BLUE}│${NC} ${BOLD}Saved${NC}        ${BLUE}│${NC} ${BOLD}Status${NC}  ${BLUE}│${NC}"
  log_output "${BLUE}├──────────┼──────────────┼──────────────┼──────────────┼─────────┤${NC}"

  for cache_type in "${SELECTED_CACHES[@]}"; do
    local before="${CACHE_SIZES_BEFORE[$cache_type]:-0}"
    local after="${CACHE_SIZES_AFTER[$cache_type]:-0}"
    # Detail paths (e.g. mise active installs, full npm dir) hold large
    # non-reclaimable baselines AND may themselves shrink (mise prune removes
    # unreferenced install versions). Fold that detail-delta into "Saved" so
    # prune's real wins are counted, but keep "Before" as the reclaimable
    # baseline so the row is not dominated by active tool installs.
    local dbefore="${CACHE_DETAIL_BEFORE[$cache_type]:-0}"
    local dafter="${CACHE_DETAIL_AFTER[$cache_type]:-0}"
    local detail_delta=$((dbefore - dafter))
    [[ $detail_delta -lt 0 ]] && detail_delta=0
    local saved=$((before - after + detail_delta))
    [[ $saved -lt 0 ]] && saved=0

    total_before=$((total_before + before))
    total_after=$((total_after + after))

    local before_h after_h saved_h
    before_h=$(bytes_to_human "$before")
    after_h=$(bytes_to_human "$after")
    saved_h=$(bytes_to_human "$saved")

    local status
    if [[ $DRY_RUN -eq 1 ]]; then
      status="dry-run"
    elif [[ "${CACHE_CLEANED_OK[$cache_type]:-0}" -eq 1 ]]; then
      status="  ${GREEN}✓${NC}    "
    else
      status="  skip  "
    fi

    log_output "${BLUE}│${NC} $(printf '%-8s' "$cache_type") ${BLUE}│${NC} $(printf '%12s' "$before_h") ${BLUE}│${NC} $(printf '%12s' "$after_h") ${BLUE}│${NC} $(printf '%12s' "$saved_h") ${BLUE}│${NC} $status ${BLUE}│${NC}"
  done

  log_output "${BLUE}├──────────┼──────────────┼──────────────┼──────────────┼─────────┤${NC}"

  local total_saved=$((total_before - total_after))
  [[ $total_saved -lt 0 ]] && total_saved=0
  local total_before_h total_after_h total_saved_h
  total_before_h=$(bytes_to_human "$total_before")
  total_after_h=$(bytes_to_human "$total_after")
  total_saved_h=$(bytes_to_human "$total_saved")

  log_output "${BLUE}│${NC} ${BOLD}TOTAL${NC}    ${BLUE}│${NC} $(printf '%12s' "$total_before_h") ${BLUE}│${NC} $(printf '%12s' "$total_after_h") ${BLUE}│${NC} $(printf '%12s' "$total_saved_h") ${BLUE}│${NC}         ${BLUE}│${NC}"
  log_output "${BLUE}└──────────┴──────────────┴──────────────┴──────────────┴─────────┘${NC}"

  # Honest breakdown for caches whose on-disk footprint is dominated by a
  # non-reclaimable baseline. Without this, mise shows a giant "Before" that is
  # mostly active tool installs (only unreferenced versions are prunable).
  local breakdown_printed=0
  for cache_type in "${SELECTED_CACHES[@]}"; do
    local dbefore="${CACHE_DETAIL_BEFORE[$cache_type]:-0}"
    [[ $dbefore -eq 0 ]] && continue
    local dafter="${CACHE_DETAIL_AFTER[$cache_type]:-0}"
    local prune_saved=$((dbefore - dafter))
    [[ $prune_saved -lt 0 ]] && prune_saved=0
    if [[ $breakdown_printed -eq 0 ]]; then
      echo ""
      log_output "${CYAN}On-disk footprint breakdown (not all reclaimable):${NC}"
      breakdown_printed=1
    fi
    case $cache_type in
      mise)
        log_output "  mise:     active tool installs $(bytes_to_human "$dafter") (not cache; only unreferenced versions are prunable, $(bytes_to_human "$prune_saved") pruned this run)"
        ;;
    esac
  done

  # Log totals
  log_to_file "SUMMARY" "Total before: $total_before_h"
  log_to_file "SUMMARY" "Total after:  $total_after_h"
  log_to_file "SUMMARY" "Total saved:  $total_saved_h"
}

# ─── Sequential Cleanup Flow ───────────────────────────────────────────────

run_sequential() {
  for cache_type in "${SELECTED_CACHES[@]}"; do
    echo ""
    log_detail "${BLUE}────────────────────────────────────────${NC}"
    log_detail "${BLUE} ${CACHE_LABELS[$cache_type]}${NC}"
    log_detail "${BLUE}────────────────────────────────────────${NC}"

    # Pre-check
    if ! pre_check "$cache_type"; then
      log_warning "Skipping $cache_type (not found)"
      CACHE_SIZES_BEFORE["$cache_type"]=0
      CACHE_SIZES_AFTER["$cache_type"]=0
      continue
    fi

    # Confirm (interactive)
    if [[ $DRY_RUN -eq 0 && $AUTO_CONFIRM -eq 0 ]]; then
      echo -n "  Clean this cache? [y/N] "
      read -r response
      if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Skipping $cache_type"
        CACHE_SIZES_AFTER["$cache_type"]="${CACHE_SIZES_BEFORE[$cache_type]}"
        continue
      fi
    fi

    # Cleanup
    if ! cleanup_cache "$cache_type"; then
      FAILED_CACHES+=("$cache_type")
      CACHE_SIZES_AFTER["$cache_type"]="${CACHE_SIZES_BEFORE[$cache_type]}"
      continue
    fi

    # Measure immediately (before post-check tool invocations)
    measure_after "$cache_type"

    # Post-check
    if ! post_check "$cache_type"; then
      FAILED_CACHES+=("$cache_type")
    fi
  done
}

# ─── Parallel Cleanup Flow ─────────────────────────────────────────────────

run_parallel() {
  # Pre-check all caches first (sequential — fast)
  local caches_to_clean=()

  for cache_type in "${SELECTED_CACHES[@]}"; do
    if pre_check "$cache_type"; then
      caches_to_clean+=("$cache_type")
    else
      log_warning "Skipping $cache_type (not found)"
      CACHE_SIZES_BEFORE["$cache_type"]=0
      CACHE_SIZES_AFTER["$cache_type"]=0
    fi
  done

  if [[ ${#caches_to_clean[@]} -eq 0 ]]; then
    log_warning "No caches to clean"
    return
  fi

  # Run cleanups in parallel
  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "${tmpdir:-}"' RETURN

  local pids=()
  local i=0
  for cache_type in "${caches_to_clean[@]}"; do
    (
      {
        cleanup_cache "$cache_type"
        echo $? > "$tmpdir/${i}.rc"
        # Measure immediately in subshell
        get_size_bytes "$cache_type" > "$tmpdir/${i}.size"
        get_detail_size_bytes "$cache_type" > "$tmpdir/${i}.dsize"
      } > "$tmpdir/${i}.out" 2>&1
    ) &
    pids+=($!)
    i=$((i + 1))
  done

  # Wait for all background jobs
  for pid in "${pids[@]}"; do
    wait "$pid" || true
  done

  # Display captured output, collect sizes, and check success
  i=0
  for cache_type in "${caches_to_clean[@]}"; do
    if [[ -f "$tmpdir/${i}.out" ]]; then
      [[ $QUIET -eq 0 ]] && cat "$tmpdir/${i}.out"
    fi
    if [[ -f "$tmpdir/${i}.size" ]]; then
      CACHE_SIZES_AFTER["$cache_type"]=$(cat "$tmpdir/${i}.size")
    else
      CACHE_SIZES_AFTER["$cache_type"]="${CACHE_SIZES_BEFORE[$cache_type]}"
    fi
    if [[ -f "$tmpdir/${i}.dsize" ]]; then
      CACHE_DETAIL_AFTER["$cache_type"]=$(cat "$tmpdir/${i}.dsize")
    else
      CACHE_DETAIL_AFTER["$cache_type"]="${CACHE_DETAIL_BEFORE[$cache_type]:-0}"
    fi
    # Check success via return code file
    if [[ -f "$tmpdir/${i}.rc" ]] && [[ "$(cat "$tmpdir/${i}.rc")" == "0" ]]; then
      CACHE_CLEANED_OK["$cache_type"]=1
    else
      FAILED_CACHES+=("$cache_type")
    fi
    i=$((i + 1))
  done

  # Post-check all (sequential — fast, just verifies tool commands)
  for cache_type in "${caches_to_clean[@]}"; do
    if ! post_check "$cache_type"; then
      FAILED_CACHES+=("$cache_type")
    fi
  done
}

# ─── Main ───────────────────────────────────────────────────────────────────

main() {
  init_logging "$@"
  rotate_logs

  log_info "Starting cache cleanup..."
  log_info "Log: $LOG_FILE"
  if [[ $DRY_RUN -eq 1 ]]; then
    log_warning "DRY RUN MODE — no changes will be made"
  fi
  echo ""

  # Run cleanup flow
  if [[ $PARALLEL -eq 1 && $DRY_RUN -eq 0 ]]; then
    run_parallel
  else
    run_sequential
  fi

  # Summary
  print_space_summary

  echo ""
  log_detail "${BLUE}────────────────────────────────────────${NC}"
  log_detail "${BLUE} ${BOLD}Results${NC}${NC}"

  if [[ ${#FAILED_CACHES[@]} -gt 0 ]]; then
    echo ""
    for cache in "${FAILED_CACHES[@]}"; do
      log_error "Failed: $cache"
    done
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo ""
    log_warning "This was a DRY RUN — no changes were made"
    log_info "Run without --dry-run to execute, or add --yes to auto-confirm"
  else
    echo ""
    log_output "${GREEN}${BOLD}Cache cleanup complete.${NC}"
  fi

  echo ""
  log_verbose "Log: $LOG_FILE"
  if [[ -s "$ERROR_FILE" ]]; then
    log_verbose "Errors/warnings: $ERROR_FILE"
  fi

  # Finalize log
  log_to_file "INFO" "Completed at $(date)"
  log_to_file "INFO" "Failed caches: ${FAILED_CACHES[*]:-none}"

  if [[ ${#FAILED_CACHES[@]} -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
