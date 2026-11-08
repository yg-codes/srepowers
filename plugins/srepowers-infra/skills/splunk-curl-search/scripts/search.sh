#!/usr/bin/env bash
# search.sh — run ONE bounded, read-only SPL search against a Splunk profile.
#
# Usage:
#   search.sh -p <profile> [opts] '<SPL>'
#   search.sh -p <profile> [opts] -q <query-name> [KEY=VALUE ...]   # queries/<name>.spl
#   (all options BEFORE the SPL / KEY=VALUE args — getopts stops at the first non-option)
#
# Options:
#   -p PROFILE   profiles/<PROFILE>.env or a path (SPLUNK_* env exports also accepted)
#   -e EARLIEST  job earliest (default: query header, else profile DEFAULT_EARLIEST)
#   -l LATEST    job latest (default now)
#   -o FILE      results CSV (default REPORT_DIR or $TMPDIR/splunk-curl-search/<date>-<name>.csv)
#   -n           dry run: lint + print the plan, send nothing, no credential read
#   -x N         cost-preview ceiling in events for raw searches (default MAX_SCAN_EVENTS)
#   -E LIST      expected hosts (short names; HOST_FORMAT applied) → per-host SENDING/STALE/ABSENT
#   -s SECS      staleness threshold for -E (default STALE_AFTER)
#
# Safety: SPL is linted first (spl-lint.sh); raw searches get a | tstats cost preview;
# every job carries max_count/max_time/auto_cancel and is cancelled+deleted on exit;
# the session user is asserted before any result is trusted; prod profiles need
# SPLUNK_ALLOW_PROD=yes. Exit: 0 ok, 1 expectation failed (-E), 2 usage/config,
# 3 lint, 4 credential, 5 prod guard, 6 auth, 7 cost ceiling, 8 job failed.

set -euo pipefail
HERE=$(dirname "$0")
. "$HERE/lib.sh"

PROFILE="" E="" L="now" OUT="" DRY=0 XMAX="" QNAME="" EXPECT="" STALE=""
while getopts 'p:e:l:o:nx:q:E:s:' o; do
  case $o in
    p) PROFILE=$OPTARG ;; e) E=$OPTARG ;; l) L=$OPTARG ;; o) OUT=$OPTARG ;; n) DRY=1 ;;
    x) XMAX=$OPTARG ;; q) QNAME=$OPTARG ;; E) EXPECT=$OPTARG ;; s) STALE=$OPTARG ;;
    *) sed -n '2,22p' "$0"; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
load_config "$PROFILE"

fmt_hosts() { # comma list of short names → HOST_FORMAT applied
  local out="" h
  IFS=, read -ra hs <<<"$1"
  for h in "${hs[@]}"; do
    [[ $h =~ ^[A-Za-z0-9_.:-]+$ ]] || die 2 "bad host '$h'"
    # shellcheck disable=SC2059
    out+="${out:+,}$(printf "${CFG[HOST_FORMAT]}" "$h")"
  done
  echo "$out"
}

# ---- build the SPL
NAME=adhoc
if [ -n "$QNAME" ]; then
  QF=$HERE/../queries/$QNAME.spl
  [ -f "$QF" ] || die 2 "no query '$QNAME' (have: $(ls "$HERE/../queries" | sed 's/\.spl$//' | xargs))"
  NAME=$QNAME
  declare -A P=()
  while IFS= read -r d; do # defaults from "# default: KEY=VALUE"
    P[${d%%=*}]=${d#*=}
  done < <(sed -n 's/^# default:[[:space:]]*//p' "$QF")
  for kv in "$@"; do
    [[ $kv =~ ^([A-Z_]+)=(.+)$ ]] || die 2 "query args must be KEY=VALUE, got '$kv'"
    P[${BASH_REMATCH[1]}]=${BASH_REMATCH[2]}
  done
  hostparam=$(sed -n 's/^# hosts:[[:space:]]*//p' "$QF")
  if [ -n "$hostparam" ]; then
    [ -n "${P[$hostparam]:-}" ] || die 2 "query '$QNAME' needs $hostparam=h1,h2,…"
    [ -z "$EXPECT" ] && EXPECT=${P[$hostparam]}
    P[$hostparam]=$(fmt_hosts "${P[$hostparam]}")
  fi
  SPL=$(grep -v '^#' "$QF" | sed '/^[[:space:]]*$/d' | paste -sd' ' -)
  for k in "${!P[@]}"; do
    [[ ${P[$k]} =~ ^[A-Za-z0-9_.,:*@-]+$ ]] || die 2 "param $k='${P[$k]}' has unsafe characters"
    SPL=${SPL//\{\{$k\}\}/${P[$k]}}
  done
  [[ $SPL == *'{{'* ]] && die 2 "unfilled parameter in: $SPL"
  [ -z "$E" ] && E=$(sed -n 's/^# earliest:[[:space:]]*//p' "$QF")
else
  SPL=${1:?give '<SPL>' or -q <query>}
fi
: "${E:=${CFG[DEFAULT_EARLIEST]}}"
: "${XMAX:=${CFG[MAX_SCAN_EVENTS]}}" "${STALE:=${CFG[STALE_AFTER]}}"

# ---- lint
LINT=$("$HERE/spl-lint.sh" -i "${CFG[ALLOWED_INDEXES]}" -w "${CFG[MAX_WINDOW]}" -e "$E" -l "$L" "$SPL") || {
  rc=$?; echo "$LINT"; exit "$rc"; }
KIND=$(sed -n 's/^KIND=//p' <<<"$LINT"); IDX=$(sed -n 's/^INDEXES=//p' <<<"$LINT")

if [ -z "$OUT" ]; then
  dir=${CFG[REPORT_DIR]:-${TMPDIR:-/tmp}/splunk-curl-search}
  OUT=$dir/$(date +%Y%m%d-%H%M)-${CFG[PROFILE]}-$NAME.csv
fi
JOBSPL=$SPL; [[ $SPL =~ ^[[:space:]]*\| ]] || JOBSPL="search $SPL"

cat >&2 <<EOF
plan: profile=${CFG[PROFILE]} url=${CFG[SPLUNK_URL]} env=${CFG[ENV_CLASS]} auth=${CFG[AUTH_MODE]}
      kind=$KIND indexes=${IDX:-<none>} earliest=$E latest=$L
      max_count=${CFG[MAX_RESULTS]} max_time=${CFG[MAX_TIME_S]}s preview_ceiling=$([ "$KIND" = raw ] && echo "$XMAX" || echo n/a)
      out=$OUT
      spl: $JOBSPL
EOF
[ "$DRY" = 1 ] && { echo "DRY RUN — nothing sent" >&2; exit 0; }
prod_guard

# ---- session + job lifecycle
SID="" SID_DONE=""
cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  if [ -n "$SID" ]; then
    [ -z "$SID_DONE" ] && sp_curl POST "/search/v2/jobs/$SID/control" -d action=cancel -o /dev/null 2>/dev/null || true
    sp_curl DELETE "/search/v2/jobs/$SID" -o /dev/null 2>/dev/null || true
  fi
  close_session
  exit "$rc"
}
trap cleanup EXIT INT TERM
open_session

run_job() { # spl earliest latest out-csv  → sets JOB (status json)
  local spl=$1 e=$2 l=$3 out=$4 st waited=0 limit=$((${CFG[MAX_TIME_S]} + 60))
  SID=$(sp_curl POST /search/v2/jobs -d output_mode=json --data-urlencode "search=$spl" \
    --data-urlencode "earliest_time=$e" --data-urlencode "latest_time=$l" \
    -d "max_count=${CFG[MAX_RESULTS]}" -d "max_time=${CFG[MAX_TIME_S]}" -d auto_cancel=120 -d timeout=600 |
    jq -r '.sid // empty') || true
  [ -n "$SID" ] || die 8 "job create returned no sid"
  SID_DONE=""
  while :; do
    JOB=$(sp_curl GET "/search/v2/jobs/$SID" -G -d output_mode=json) || die 8 "status poll failed (sid $SID)"
    st=$(jq -r '.entry[0].content.dispatchState' <<<"$JOB")
    case $st in DONE | FAILED) break ;; esac
    [ "$waited" -ge "$limit" ] && die 8 "job $SID still $st after ${limit}s — cancelled"
    sleep 2; waited=$((waited + 2))
  done
  [ "$st" = DONE ] || die 8 "job $SID $st: $(jq -c '[.entry[0].content.messages[]?.text]' <<<"$JOB")"
  SID_DONE=1
  mkdir -p "$(dirname "$out")"
  sp_curl GET "/search/v2/jobs/$SID/results" -G -d output_mode=csv -d count=0 -o "$out" || die 8 "results fetch failed"
  sp_curl DELETE "/search/v2/jobs/$SID" -o /dev/null 2>/dev/null || true
  SID=""
}
jstat() { jq -r ".entry[0].content.$1 | if . == null then \"\" else tostring end" <<<"$JOB"; }

# ---- cost preview for raw event searches
if [ "$KIND" = raw ]; then
  pv=$(mktemp)
  idxq=$(tr ',' '\n' <<<"$IDX" | sed 's/^/index=/' | paste -sd' ' - | sed 's/ / OR /g')
  run_job "| tstats count where ($idxq)" "$E" "$L" "$pv"
  n=$(awk -F, 'NR==2{gsub(/"/,"",$1); print $1+0}' "$pv"); rm -f "$pv"
  echo "preview: ${n:-0} events in ${IDX} over [$E, $L] (ceiling $XMAX)" >&2
  [ "${n:-0}" -le "$XMAX" ] || die 7 "upper-bound scan ${n} > ceiling $XMAX — narrow the window/index, or raise with -x after review"
fi

# ---- the search
run_job "$JOBSPL" "$E" "$L" "$OUT"
rows=$(($(awk 'END{print NR}' "$OUT") - 1)); [ "$rows" -lt 0 ] && rows=0
{
  echo "generated_at=$(date -Iseconds)"
  echo "profile=${CFG[PROFILE]} url=${CFG[SPLUNK_URL]} env=${CFG[ENV_CLASS]}"
  echo "frontdoor=$FRONTDOOR"
  echo "mode=$MODE user=$WHO roles=$ROLES tls=$TLS_NOTE"
  echo "kind=$KIND indexes=$IDX earliest=$E latest=$L"
  echo "spl=$JOBSPL"
  echo "dispatchState=$(jstat dispatchState) scanCount=$(jstat scanCount) eventCount=$(jstat eventCount) resultCount=$(jstat resultCount) runDuration=$(jstat runDuration)"
  echo "isFinalized=$(jstat isFinalized) messages=$(jq -c '[.entry[0].content.messages[]?.text]' <<<"$JOB")"
  echo "rows=$rows"
} >"$OUT.meta"
echo "result: rows=$rows scanCount=$(jstat scanCount) runDuration=$(jstat runDuration)s finalized=$(jstat isFinalized) → $OUT (+ .meta)" >&2
[ "$(jstat isFinalized)" = true ] && echo "WARN: job hit max_time/max_count and was finalized early — results may be partial" >&2
[ "$rows" = "$(jstat resultCount)" ] || echo "WARN: CSV rows ($rows) != resultCount ($(jstat resultCount))" >&2
head -n 21 "$OUT"
[ "$rows" -gt 20 ] && echo "… ($rows rows total)"

# ---- expectations: every expected host must appear, fresh
if [ -n "$EXPECT" ]; then
  want=$(fmt_hosts "$EXPECT"); now=$(date +%s)
  awk -F, -v want="$want" -v now="$now" -v stale="$STALE" '
    function uq(s){ gsub(/^"|"$/, "", s); return s }
    NR==1 { for (i=1;i<=NF;i++) col[uq($i)]=i
            if (!("host" in col) || !("last" in col)) { print "FAIL: result has no host/last column"; bad=1; exit } next }
    { h=uq($col["host"]); t=uq($col["last"])+0; if (t>last[h]) last[h]=t }
    END { if (bad) exit 1
          n=split(want, w, ","); ok=0
          for (i=1;i<=n;i++) { h=w[i]
            if (!(h in last)) { printf "ABSENT   %s\n", h; continue }
            age=now-last[h]
            if (age>stale) printf "STALE    %s  last %s (%dh ago)\n", h, strftime("%FT%T%z", last[h]), age/3600
            else { printf "SENDING  %s  last %s\n", h, strftime("%FT%T%z", last[h]); ok++ } }
          printf "expect: %d/%d SENDING (stale after %ds)\n", ok, n, stale
          exit (ok==n ? 0 : 1) }' "$OUT"
fi
