#!/usr/bin/env bash
# test-spl-lint.sh — the linter must both PASS good SPL and FAIL bad SPL.
set -uo pipefail
L=$(dirname "$0")/../scripts/spl-lint.sh
pass=0 failn=0
t() { # expect(PASS|FAIL) description lint-args...
  local want=$1 desc=$2; shift 2
  local got=PASS; "$L" "$@" >/dev/null 2>&1 || got=FAIL
  if [ "$got" = "$want" ]; then pass=$((pass+1)); else failn=$((failn+1)); echo "WRONG: want $want got $got — $desc"; fi
}
A=(-i "main,network" -w 7d)
t PASS "tstats all-time over index=*"        "${A[@]}" -e 0 '| tstats count where index=* by host'
t PASS "metadata"                            "${A[@]}" -e 0 '| metadata type=hosts index=*'
t PASS "rest data/indexes"                   "${A[@]}" -e 0 '| rest /services/data/indexes splunk_server=local'
t PASS "raw, allowed index, 24h"             "${A[@]}" -e -24h 'index=main host=web01.log error | head 100'
t PASS "raw via search keyword, IN list"     "${A[@]}" -e -1h '| search index IN (main, network) sourcetype=fw:traffic'
t PASS "raw, exactly max window"             "${A[@]}" -e -7d 'index=network sourcetype=switch:syslog'
t PASS "raw, trailing wildcard ok"           "${A[@]}" -e -4h 'index=main host=web0*'
t PASS "raw, bare host=* ok"                 "${A[@]}" -e -4h 'index=main host=* | stats count by host'
t PASS "no allowlist → any named index"      -w 7d -e -1h 'index=foo bar'
t PASS "absolute epoch window"               "${A[@]}" -e $(( $(date +%s) - 3600 )) 'index=main x'
t FAIL "raw index=*"                         "${A[@]}" -e -24h 'index=* error'
t FAIL "raw with no index"                   "${A[@]}" -e -24h 'error sourcetype=syslog'
t FAIL "raw all time"                        "${A[@]}" -e 0 'index=main error'
t FAIL "inline earliest=0 overrides job"     "${A[@]}" -e -1h 'index=main earliest=0 error'
t FAIL "raw window > max"                    "${A[@]}" -e -30d 'index=main error'
t FAIL "index not on allowlist"              "${A[@]}" -e -1h 'index=_internal error'
t FAIL "wildcard index name"                 "${A[@]}" -e -1h 'index=ma* error'
t FAIL "leading wildcard term"               "${A[@]}" -e -1h 'index=main *error*'
t FAIL "leading wildcard field value"        "${A[@]}" -e -1h 'index=main host=*web02'
t FAIL "| delete"                            "${A[@]}" -e -1h 'index=main x | delete'
t FAIL "| collect"                           "${A[@]}" -e 0 '| tstats count where index=* by host | collect index=summary'
t FAIL "| outputlookup"                      "${A[@]}" -e 0 '| tstats count where index=* by host | outputlookup x.csv'
t FAIL "| sendemail"                         "${A[@]}" -e -1h 'index=main x | sendemail to=a@b'
t FAIL "| map"                               "${A[@]}" -e -1h 'index=main x | map search="search index=main"'
t FAIL "| script"                            "${A[@]}" -e 0 '| script python foo'
t FAIL "unknown generating command"          "${A[@]}" -e -1h '| dbxquery query="select 1"'
t FAIL "unparseable earliest"                "${A[@]}" -e yesterday 'index=main x'
echo "spl-lint tests: $pass passed, $failn wrong"
[ "$failn" -eq 0 ]
