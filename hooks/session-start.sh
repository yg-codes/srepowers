#!/usr/bin/env bash
# SessionStart hook for srepowers plugin

set -euo pipefail

# Determine plugin root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Read using-srepowers content
using_srepowers_content=$(cat "${PLUGIN_ROOT}/skills/using-srepowers/SKILL.md" 2>&1 || echo "Error reading using-srepowers skill")

# Escape string for JSON embedding using bash parameter substitution.
# Each ${s//old/new} is a single C-level pass - orders of magnitude
# faster than the character-by-character loop this replaces.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_srepowers_escaped=$(escape_for_json "$using_srepowers_content")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have SREPowers - SRE infrastructure skills for disciplined operations.\n\n**Below is the full content of your 'srepowers:using-srepowers' skill - your introduction to using SRE infrastructure skills. For all other skills, use the 'Skill' tool:**\n\n${using_srepowers_escaped}\n\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
