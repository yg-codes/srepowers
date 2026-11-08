# lib.sh — shared helpers for the splunk-curl-search skill. Sourced, never executed.
# shellcheck shell=bash
#
# Config precedence: profile < environment (SPLUNK_* exports) < credential file.
# SPLUNK_URL may not change between sources — a credential for host A is never
# sent to host B.

SKILL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

PROFILE_KEYS="SPLUNK_URL SPLUNK_PORT SPLUNK_MGMT_PORT SPLUNK_USER_NAME SPLUNK_PASSWORD
SPLUNK_TOKEN SPLUNK_CRED_FILE SPLUNK_PROXY AUTH_MODE ENV_CLASS ALLOWED_INDEXES DEFAULT_EARLIEST
MAX_WINDOW MAX_RESULTS MAX_TIME_S MAX_SCAN_EVENTS HOST_FORMAT STALE_AFTER CA_BUNDLE
REPORT_DIR"
PROFILE_KEYS=$(echo $PROFILE_KEYS)   # flatten newlines
CRED_KEYS="SPLUNK_URL SPLUNK_PORT SPLUNK_USER_NAME SPLUNK_PASSWORD SPLUNK_TOKEN"

declare -gA CFG=() CFG_SRC=()

die() { local rc=$1; shift; echo "FAIL: $*" >&2; exit "$rc"; }

_cfg_set() { # key value source
  if [ "$1" = SPLUNK_URL ] && [ -n "${CFG[SPLUNK_URL]:-}" ] && [ "${CFG[SPLUNK_URL]}" != "$2" ]; then
    die 2 "SPLUNK_URL conflict: ${CFG_SRC[SPLUNK_URL]}=${CFG[SPLUNK_URL]} vs $3=$2"
  fi
  CFG[$1]=$2; CFG_SRC[$1]=$3
}

# Parse a KEY=VALUE file without executing it. Comments on their own line only.
parse_kv() { # file allowed-keys source-label
  local file=$1 allowed=" $2 " src=$3 line k v n=0
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1)); line=${line%$'\r'}
    case $line in '' | '#'* | [[:space:]]'#'*) continue ;; esac
    line=${line#export }
    [[ $line =~ ^([A-Z_][A-Z0-9_]*)=(.*)$ ]] || die 2 "$file:$n: not KEY=VALUE"
    k=${BASH_REMATCH[1]}; v=${BASH_REMATCH[2]}
    [[ $allowed == *" $k "* ]] || die 2 "$file:$n: key $k not allowed in a $src"
    if [[ $v =~ ^\'(.*)\'$ ]] || [[ $v =~ ^\"(.*)\"$ ]]; then v=${BASH_REMATCH[1]}; fi
    _cfg_set "$k" "$v" "$src"
  done <"$file"
}

# A plaintext credential file must be a regular file, ours, mode 600/400.
check_secret_file() {
  local f=$1
  [ -e "$f" ] || die 2 "credential file $f does not exist"
  [ -L "$f" ] && die 2 "credential file $f is a symlink — refusing"
  [ -f "$f" ] || die 2 "credential file $f is not a regular file"
  [ "$(stat -c %u "$f")" = "$(id -u)" ] || die 2 "credential file $f is not owned by $(id -un)"
  case $(stat -c %a "$f") in 600 | 400) ;; *) die 2 "credential file $f is mode $(stat -c %a "$f") — chmod 600 it" ;; esac
}

load_config() { # [profile-name-or-path]
  local p=${1:-} k path
  if [ -n "$p" ]; then
    # Site profiles live OUTSIDE the skill so it carries no site data.
    local d dirs=("${SPLUNK_PROFILE_DIR:-}" "${XDG_CONFIG_HOME:-$HOME/.config}/splunk-curl-search/profiles" "$SKILL_DIR/profiles")
    path=""
    if [ -f "$p" ]; then path=$p; else
      for d in "${dirs[@]}"; do
        [ -n "$d" ] && [ -f "$d/$p.env" ] && { path=$d/$p.env; break; }
      done
    fi
    [ -n "$path" ] || die 2 "profile '$p' not found (searched: ${dirs[*]})"
    parse_kv "$path" "$PROFILE_KEYS" profile
    CFG[PROFILE]=$(basename "$path" .env)
  fi
  for k in $PROFILE_KEYS; do
    [ -n "${!k:-}" ] && _cfg_set "$k" "${!k}" env
  done
  unset SPLUNK_PASSWORD SPLUNK_TOKEN
  if [ -n "${CFG[SPLUNK_CRED_FILE]:-}" ]; then
    check_secret_file "${CFG[SPLUNK_CRED_FILE]}"
    parse_kv "${CFG[SPLUNK_CRED_FILE]}" "$CRED_KEYS" credfile
  fi
  [ -n "${CFG[SPLUNK_URL]:-}" ] || die 2 "SPLUNK_URL not set (profile, env or credential file)"
  : "${CFG[PROFILE]:=adhoc}"
  : "${CFG[SPLUNK_PORT]:=443}" "${CFG[SPLUNK_MGMT_PORT]:=8089}" "${CFG[AUTH_MODE]:=auto}"
  : "${CFG[DEFAULT_EARLIEST]:=-24h}" "${CFG[MAX_WINDOW]:=7d}" "${CFG[MAX_RESULTS]:=10000}"
  : "${CFG[MAX_TIME_S]:=120}" "${CFG[MAX_SCAN_EVENTS]:=5000000}" "${CFG[HOST_FORMAT]:=%s}"
  : "${CFG[STALE_AFTER]:=86400}" "${CFG[ALLOWED_INDEXES]:=}"
  if [ -z "${CFG[ENV_CLASS]:-}" ]; then # unclassified → prod unless the name says otherwise
    case ${CFG[SPLUNK_URL]} in *uat* | *dev* | *sit*) CFG[ENV_CLASS]=nonprod ;; *) CFG[ENV_CLASS]=prod ;; esac
  fi
  CURL_TLS=(-k); TLS_NOTE="unverified (-k)"
  if [ -n "${CFG[CA_BUNDLE]:-}" ]; then CURL_TLS=(--cacert "${CFG[CA_BUNDLE]}"); TLS_NOTE="verified (${CFG[CA_BUNDLE]})"; fi
  # Direct by default (ignores http(s)_proxy); SPLUNK_PROXY=http://host:port forces a proxy.
  if [ -n "${CFG[SPLUNK_PROXY]:-}" ]; then CURL_NET=(--proxy "${CFG[SPLUNK_PROXY]}"); else CURL_NET=(--noproxy '*'); fi
  CURL_OPTS=(-sS "${CURL_NET[@]}" --max-time 30 "${CURL_TLS[@]}")
}

prod_guard() {
  [ "${CFG[ENV_CLASS]}" = prod ] || return 0
  [ "${SPLUNK_ALLOW_PROD:-}" = yes ] && return 0
  die 5 "${CFG[SPLUNK_URL]} is ENV_CLASS=prod — set SPLUNK_ALLOW_PROD=yes only on the operator's explicit demand"
}

# Resolve a secret value: op://… via 1Password, anything else is literal.
resolve_secret() { # value
  local v=$1 op err
  case $v in
    op://*)
      op=${SPLUNK_OP_BIN:-$(command -v op || command -v op.exe || true)}   # op.exe = WSL → Windows CLI
      [ -n "$op" ] || die 4 "op:// reference but neither op nor op.exe on PATH (or set SPLUNK_OP_BIN)"
      err=$(mktemp); v=$("$op" read "$1" 2>"$err" | tr -d '\r') || true
      [ -n "$v" ] || { local e; e=$(head -c 300 "$err"); rm -f "$err"; die 4 "1Password read failed for $1: ${e:-empty value} (approve the desktop-app prompt / sign in, then retry)"; }
      rm -f "$err" ;;
  esac
  printf '%s' "$v"
}

# ---------------------------------------------------------------- front door
# Anonymous probes only. Prints KEY=VALUE lines and sets DETECT_MODE.
detect_frontdoor() {
  local h=${CFG[SPLUNK_URL]} wp=${CFG[SPLUNK_PORT]} mp=${CFG[SPLUNK_MGMT_PORT]}
  local t r code red
  t=$(mktemp -d)
  _probe() { curl -s "${CURL_NET[@]}" --max-time 6 "${CURL_TLS[@]}" -o "$t/b" -D "$t/h" \
    -w '%{http_code} %{redirect_url}' "$1" 2>/dev/null || true; }

  r=$(_probe "https://$h:$mp/services/server/info"); code=${r%% *}
  case $code in 401 | 200) MGMT=open ;; 000) MGMT=filtered ;; *) MGMT=other:$code ;; esac

  r=$(_probe "https://$h:$wp/en-US/account/login"); code=${r%% *}; red=${r#* }
  WEB=reachable; OAUTH2_GATE=n/a; SAML=none
  case $code in
    000) WEB=unreachable ;;
    30*) case $red in
           *accounts.google.com*) OAUTH2_GATE=enforced ;;
           *login.microsoftonline.com*) SAML=entra-redirect ;;
         esac ;;
    200) if grep -qi 'login.microsoftonline.com' "$t/b"; then SAML=entra
         elif grep -qi 'saml' "$t/b"; then SAML=saml-other; fi ;;
  esac

  OAUTH2=none
  r=$(_probe "https://$h:$wp/oauth2/start"); code=${r%% *}; red=${r#* }
  case $red in
    *accounts.google.com*) OAUTH2=google ;;
    *login.microsoftonline.com*) OAUTH2=entra-proxy ;;
    */en-US/*) OAUTH2=none ;;            # Splunk Web answered the path itself
    '') [ "$code" = 200 ] && grep -qi oauth2 "$t/b" && OAUTH2=oauth2-proxy-unknown-provider ;;
  esac
  if [ "$OAUTH2" != none ] && [ "$OAUTH2_GATE" = n/a ]; then OAUTH2_GATE=bypassed-trusted-vantage; fi

  LOCAL_LOGIN=no
  r=$(_probe "https://$h:$wp/en-US/account/login?loginType=splunk"); code=${r%% *}
  [ "$code" = 200 ] && grep -qi '^set-cookie: cval=' "$t/h" && LOCAL_LOGIN=yes
  rm -rf "$t"

  DETECT_REASON=""
  if [ "$MGMT" = open ]; then
    if [ -n "${CFG[SPLUNK_TOKEN]:-}" ]; then DETECT_MODE=mgmt-token; else DETECT_MODE=mgmt-basic; fi
  elif [ "$LOCAL_LOGIN" = yes ]; then
    DETECT_MODE=web-local
  else
    DETECT_MODE=blocked
    if [ "$OAUTH2_GATE" = enforced ]; then DETECT_REASON="Google oauth2-proxy enforces SSO from this vantage and :$mp is not reachable"
    elif [ "$WEB" = unreachable ]; then DETECT_REASON="neither :$wp nor :$mp reachable"
    else DETECT_REASON="no local-login form (cval) and :$mp not reachable"; fi
  fi
  FRONTDOOR="MGMT=$MGMT WEB=$WEB OAUTH2=$OAUTH2 OAUTH2_GATE=$OAUTH2_GATE SAML=$SAML LOCAL_LOGIN=$LOCAL_LOGIN"
}

print_frontdoor() {
  local k
  for k in MGMT WEB OAUTH2 OAUTH2_GATE SAML LOCAL_LOGIN; do echo "$k=${!k}"; done
  echo "MODE=$DETECT_MODE"
  [ -n "$DETECT_REASON" ] && echo "REASON=$DETECT_REASON"
  return 0
}

# ---------------------------------------------------------------- session
# MODE, SECRET, JAR, CSRF are globals set by open_session.
_auth_cfg() { # curl -K config on stdin — keeps the secret off argv
  local s=${SECRET//\\/\\\\}; s=${s//\"/\\\"}
  if [ "$MODE" = mgmt-token ]; then printf 'header = "Authorization: Bearer %s"\n' "$s"
  else printf 'user = "%s:%s"\n' "${CFG[SPLUNK_USER_NAME]}" "$s"; fi
}

sp_curl() { # METHOD /path-under-services [curl args...]
  local m=$1 p=$2; shift 2
  case $MODE in
    web-local)
      curl "${CURL_OPTS[@]}" -X "$m" -b "$JAR" -H "X-Splunk-Form-Key: $CSRF" \
        -H 'X-Requested-With: XMLHttpRequest' "$@" \
        "https://${CFG[SPLUNK_URL]}:${CFG[SPLUNK_PORT]}/en-US/splunkd/__raw/services$p" ;;
    mgmt-basic | mgmt-token)
      _auth_cfg | curl "${CURL_OPTS[@]}" -K - -X "$m" "$@" \
        "https://${CFG[SPLUNK_URL]}:${CFG[SPLUNK_MGMT_PORT]}/services$p" ;;
    *) die 9 "sp_curl: no session (MODE=$MODE)" ;;
  esac
}

open_session() {
  if [ "${CFG[AUTH_MODE]}" = auto ]; then
    detect_frontdoor
    MODE=$DETECT_MODE
    echo "frontdoor: $FRONTDOOR → MODE=$MODE" >&2
    [ "$MODE" = blocked ] && die 6 "cannot authenticate: $DETECT_REASON"
  else
    MODE=${CFG[AUTH_MODE]}; FRONTDOOR="AUTH_MODE fixed by profile"
  fi
  if [ "$MODE" = mgmt-token ]; then
    SECRET=$(resolve_secret "${CFG[SPLUNK_TOKEN]:?SPLUNK_TOKEN not set}")
  else
    : "${CFG[SPLUNK_USER_NAME]:?SPLUNK_USER_NAME not set}"
    SECRET=$(resolve_secret "${CFG[SPLUNK_PASSWORD]:?SPLUNK_PASSWORD not set}")
  fi
  if [ "$MODE" = web-local ]; then
    local base="https://${CFG[SPLUNK_URL]}:${CFG[SPLUNK_PORT]}" cval code
    JAR=$(umask 077; mktemp "${TMPDIR:-/tmp}/splunk-jar.XXXXXX")
    curl "${CURL_OPTS[@]}" -b "$JAR" -c "$JAR" -o /dev/null "$base/en-US/account/login?loginType=splunk"
    cval=$(awk '$6=="cval"{print $7}' "$JAR")
    [ -n "$cval" ] || die 6 "login page set no cval cookie"
    code=$(printf '%s' "$SECRET" | curl "${CURL_OPTS[@]}" -b "$JAR" -c "$JAR" -o /dev/null -w '%{http_code}' \
      --data-urlencode "username=${CFG[SPLUNK_USER_NAME]}" --data-urlencode "password@-" \
      --data-urlencode "cval=$cval" --data-urlencode "set_has_logged_in=false" \
      "$base/en-US/account/login")
    CSRF=$(awk '$6 ~ /^splunkweb_csrf_token_/{print $7}' "$JAR")
    awk '$6 ~ /^splunkd_/{f=1} END{exit !f}' "$JAR" || die 6 "login http=$code but no splunkd session cookie — wrong credential?"
  fi
  # Fail closed: prove who we are before any result can be read as "empty".
  local ctx
  ctx=$(sp_curl GET /authentication/current-context -G -d output_mode=json) || die 6 "current-context request failed"
  WHO=$(jq -r '.entry[0].content.username // empty' <<<"$ctx" 2>/dev/null)
  ROLES=$(jq -r '.entry[0].content.roles // [] | join(",")' <<<"$ctx" 2>/dev/null)
  [ -n "$WHO" ] || die 6 "authenticated request returned no username — session not valid"
  if [ "$MODE" != mgmt-token ] && [ "$WHO" != "${CFG[SPLUNK_USER_NAME]}" ]; then
    die 6 "session user '$WHO' != expected '${CFG[SPLUNK_USER_NAME]}'"
  fi
  echo "session: user=$WHO roles=$ROLES mode=$MODE tls=$TLS_NOTE" >&2
}

close_session() {
  if [ "${MODE:-}" = web-local ] && [ -n "${JAR:-}" ] && [ -f "$JAR" ]; then
    curl "${CURL_OPTS[@]}" -b "$JAR" -o /dev/null "https://${CFG[SPLUNK_URL]}:${CFG[SPLUNK_PORT]}/en-US/account/logout" 2>/dev/null || true
    rm -f "$JAR"
  fi
  SECRET=""
}

# ---------------------------------------------------------------- time math
# "-24h", "-7d@d", "-30m", "now", "0" (all time), or a unix epoch → seconds ago.
rel_to_secs() {
  local t=${1%%@*} n u
  case $t in
    now | '') echo 0; return ;;
    0) echo all; return ;;
  esac
  if [[ $t =~ ^-([0-9]+)([a-z]+)$ ]]; then
    n=${BASH_REMATCH[1]}; u=${BASH_REMATCH[2]}
    case $u in
      s | sec | secs | second | seconds) echo "$n" ;;
      m | min | mins | minute | minutes) echo $((n * 60)) ;;
      h | hr | hrs | hour | hours) echo $((n * 3600)) ;;
      d | day | days) echo $((n * 86400)) ;;
      w | week | weeks) echo $((n * 604800)) ;;
      mon | month | months) echo $((n * 2592000)) ;;
      y | yr | year | years) echo $((n * 31536000)) ;;
      *) return 1 ;;
    esac
  elif [[ $t =~ ^[0-9]{9,10}$ ]]; then
    echo $(($(date +%s) - t))
  else
    return 1
  fi
}
