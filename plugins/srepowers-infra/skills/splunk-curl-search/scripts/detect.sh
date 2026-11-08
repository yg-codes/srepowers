#!/usr/bin/env bash
# detect.sh — fingerprint a Splunk front door WITHOUT credentials.
#
# Usage: detect.sh <profile|profile.env>        (or with SPLUNK_URL/SPLUNK_PORT exported)
#
# Prints KEY=VALUE:
#   MGMT         open | filtered | other:<code>      splunkd :8089 from this vantage
#   WEB          reachable | unreachable              Splunk Web port (443)
#   OAUTH2       google | entra-proxy | none | …      oauth2-proxy in front (/oauth2/start)
#   OAUTH2_GATE  enforced | bypassed-trusted-vantage | n/a
#   SAML         entra | entra-redirect | saml-other | none   Splunk-native SAML login
#   LOCAL_LOGIN  yes | no                             ?loginType=splunk gives a cval cookie
#   MODE         mgmt-basic | mgmt-token | web-local | blocked
#   REASON       (only when blocked)
# Exit 0 when a usable MODE exists, 6 when blocked.

set -euo pipefail
. "$(dirname "$0")/lib.sh"
load_config "${1:-}"
detect_frontdoor
print_frontdoor
[ "$DETECT_MODE" != blocked ] || exit 6
