#!/usr/bin/env bash
# spl-lint.sh — reject SPL that is mutating, unbounded, or too broad, BEFORE it is sent.
#
# Usage: spl-lint.sh [-i allowed,indexes] [-w max_window] [-e earliest] [-l latest] '<SPL>'
#   -i  comma list of indexes a raw search may name (empty = any explicit, non-wildcard index)
#   -w  max raw-search window, e.g. 7d (default 7d)
#   -e/-l  job time range (default -24h / now); inline earliest=/latest= in the SPL win
# Output (stdout): KIND=…, INDEXES=…, EARLIEST=…, LATEST=…, then "LINT PASS".
# Violations go to stderr as "LINT FAIL: …"; exit 3 if any.
#
# KIND=cheap — first command is tstats/metadata/eventcount/rest/makeresults/inputlookup/dbinspect:
#   reads index-time summaries or config; index=* and earliest=0 are allowed.
# KIND=raw   — everything else (event search): needs explicit allowed indexes, a bounded
#   window <= max, and no leading-wildcard terms.
# Known limit: subsearches inside a cheap query are not linted separately.

set -euo pipefail
. "$(dirname "$0")/lib.sh"

ALLOWED="" MAXW="7d" E="-24h" L="now"
while getopts 'i:w:e:l:' o; do
  case $o in i) ALLOWED=$OPTARG ;; w) MAXW=$OPTARG ;; e) E=$OPTARG ;; l) L=$OPTARG ;; *) exit 2 ;; esac
done
shift $((OPTIND - 1))
SPL=${1:?usage: spl-lint.sh [opts] '<SPL>'}

FAILS=()
fail() { FAILS+=("$*"); }

# 1. mutating / side-effect commands — anywhere after a pipe or at the start
FORBIDDEN='collect|outputlookup|outputcsv|outputtext|delete|sendemail|sendalert|script|run|runshellscript|map|tscollect|mcollect|meventcollect|dbxoutput|summaryindex'
if grep -qiE "(^|\|)[[:space:]]*($FORBIDDEN)([[:space:]]|$)" <<<"$SPL"; then
  fail "forbidden command: $(grep -oiE "(^|\|)[[:space:]]*($FORBIDDEN)([[:space:]]|$)" <<<"$SPL" | tr -d '|' | xargs | tr ' ' ',') (skill is read-only)"
fi

# 2. kind, from the first command
first=$(sed -E 's/^[[:space:]]+//' <<<"$SPL")
KIND=raw
if [[ $first == '|'* ]]; then
  cmd=$(sed -E 's/^\|[[:space:]]*([A-Za-z_]+).*/\1/' <<<"$first" | tr 'A-Z' 'a-z')
  case $cmd in
    tstats | metadata | eventcount | rest | makeresults | inputlookup | dbinspect) KIND=cheap ;;
    search) KIND=raw ;;
    *) fail "generating command '| $cmd' is not on the allowlist (tstats metadata eventcount rest makeresults inputlookup dbinspect search)" ;;
  esac
fi

# 3. inline time modifiers override the job range
ie=$(grep -oiE '(^|[[:space:]])earliest[[:space:]]*=[[:space:]]*"?[^"[:space:]|]+' <<<"$SPL" | head -1 | sed -E 's/.*=[[:space:]]*"?//') || true
il=$(grep -oiE '(^|[[:space:]])latest[[:space:]]*=[[:space:]]*"?[^"[:space:]|]+' <<<"$SPL" | head -1 | sed -E 's/.*=[[:space:]]*"?//') || true
[ -n "$ie" ] && E=$ie
[ -n "$il" ] && L=$il

# 4. indexes named
IDX=$( { grep -oiE 'index[[:space:]]*=[[:space:]]*"?[A-Za-z0-9_*.:-]+' <<<"$SPL" | sed -E 's/.*=[[:space:]]*"?//'
         grep -oiE 'index[[:space:]]+in[[:space:]]*\([^)]*\)' <<<"$SPL" | sed -E 's/.*\(//; s/\)//' | tr ',' '\n'
       } | tr -d ' "' | sed '/^$/d' | sort -u | paste -sd, -) || true

if [ "$KIND" = raw ]; then
  [ -n "$IDX" ] || fail "raw search names no index — add index=<name>"
  IFS=, read -ra arr <<<"$IDX"
  for i in "${arr[@]}"; do
    [[ $i == *'*'* ]] && { fail "wildcard index '$i' in a raw search — name the index, or use | tstats"; continue; }
    if [ -n "$ALLOWED" ] && [[ ",$ALLOWED," != *",$i,"* ]]; then
      fail "index '$i' not in ALLOWED_INDEXES ($ALLOWED)"
    fi
  done
  # 5. bounded window
  es=$(rel_to_secs "$E") || { fail "earliest '$E' unparseable — use relative (-24h) or epoch"; es=""; }
  ls=$(rel_to_secs "$L") || { fail "latest '$L' unparseable — use relative or epoch"; ls=""; }
  ms=$(rel_to_secs "-$MAXW") || ms=604800
  if [ "$es" = all ]; then
    fail "earliest=0 (all time) on a raw search — use | tstats, or bound the window (max $MAXW)"
  elif [ -n "$es" ] && [ -n "$ls" ] && [ "$ls" != all ]; then
    win=$((es - ls))
    [ "$win" -le "$ms" ] || fail "window ${win}s exceeds MAX_WINDOW $MAXW (${ms}s)"
    [ "$win" -gt 0 ] || fail "empty/negative window (earliest $E, latest $L)"
  fi
  # 6. leading wildcards force a full scan
  if grep -qE '(^|[[:space:]("'"'"'=])\*[^[:space:]|)"'"'"',]' <<<"$SPL"; then
    fail "leading-wildcard term ($(grep -oE '(^|[[:space:]("'"'"'=])\*[^[:space:]|)"'"'"',]+' <<<"$SPL" | head -3 | xargs)) — anchor the term"
  fi
fi

echo "KIND=$KIND"
echo "INDEXES=$IDX"
echo "EARLIEST=$E"
echo "LATEST=$L"
if [ ${#FAILS[@]} -gt 0 ]; then
  for f in "${FAILS[@]}"; do echo "LINT FAIL: $f" >&2; done
  exit 3
fi
echo "LINT PASS"
