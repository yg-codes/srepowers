#!/usr/bin/env bash
# UserPromptSubmit hook: suggest skills based on prompt keywords and intent patterns
# Reads JSON from stdin, outputs skill suggestions to stdout
# Exit 0 always (suggest only, never block)

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="${SCRIPT_DIR}/skill-rules.json"

# Read stdin JSON
INPUT="$(cat)"
PROMPT="$(echo "${INPUT}" | jq -r '.prompt // ""' | tr '[:upper:]' '[:lower:]')"

if [[ -z "${PROMPT}" ]]; then
  exit 0
fi

if [[ ! -f "${RULES_FILE}" ]]; then
  exit 0
fi

# Match skills - use simple variables instead of associative arrays for portability
MATCHED_CRITICAL=""
MATCHED_HIGH=""
MATCHED_MEDIUM=""
MATCHED_LOW=""

while IFS= read -r SKILL_NAME; do
  PRIORITY="$(jq -r --arg s "${SKILL_NAME}" '.skills[$s].priority' "${RULES_FILE}")"

  # Check keywords (case-insensitive substring)
  MATCHED=false
  while IFS= read -r KW; do
    KW_LOWER="$(echo "${KW}" | tr '[:upper:]' '[:lower:]')"
    if [[ "${PROMPT}" == *"${KW_LOWER}"* ]]; then
      MATCHED=true
      break
    fi
  done < <(jq -r --arg s "${SKILL_NAME}" '.skills[$s].promptTriggers.keywords[]? // empty' "${RULES_FILE}")

  # Check intent patterns (regex via grep -qP)
  if [[ "${MATCHED}" == "false" ]]; then
    while IFS= read -r PATTERN; do
      if echo "${PROMPT}" | grep -qPi "${PATTERN}" 2>/dev/null; then
        MATCHED=true
        break
      fi
    done < <(jq -r --arg s "${SKILL_NAME}" '.skills[$s].promptTriggers.intentPatterns[]? // empty' "${RULES_FILE}")
  fi

  if [[ "${MATCHED}" == "true" ]]; then
    case "${PRIORITY}" in
      critical) MATCHED_CRITICAL="${MATCHED_CRITICAL} ${SKILL_NAME}" ;;
      high)     MATCHED_HIGH="${MATCHED_HIGH} ${SKILL_NAME}" ;;
      medium)   MATCHED_MEDIUM="${MATCHED_MEDIUM} ${SKILL_NAME}" ;;
      low)      MATCHED_LOW="${MATCHED_LOW} ${SKILL_NAME}" ;;
    esac
  fi

done < <(jq -r '.skills | keys[]' "${RULES_FILE}")

# Trim whitespace
MATCHED_CRITICAL="$(echo "${MATCHED_CRITICAL}" | xargs)"
MATCHED_HIGH="$(echo "${MATCHED_HIGH}" | xargs)"
MATCHED_MEDIUM="$(echo "${MATCHED_MEDIUM}" | xargs)"
MATCHED_LOW="$(echo "${MATCHED_LOW}" | xargs)"

# Only output if any matches found
if [[ -z "${MATCHED_CRITICAL}" && -z "${MATCHED_HIGH}" && -z "${MATCHED_MEDIUM}" && -z "${MATCHED_LOW}" ]]; then
  exit 0
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SKILL ACTIVATION CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ -n "${MATCHED_CRITICAL}" ]]; then
  echo "CRITICAL SKILLS (REQUIRED):"
  for S in ${MATCHED_CRITICAL}; do echo "  -> srepowers:${S}"; done
  echo ""
fi

if [[ -n "${MATCHED_HIGH}" ]]; then
  echo "RECOMMENDED SKILLS:"
  for S in ${MATCHED_HIGH}; do echo "  -> srepowers:${S}"; done
  echo ""
fi

if [[ -n "${MATCHED_MEDIUM}" ]]; then
  echo "SUGGESTED SKILLS:"
  for S in ${MATCHED_MEDIUM}; do echo "  -> srepowers:${S}"; done
  echo ""
fi

if [[ -n "${MATCHED_LOW}" ]]; then
  echo "OPTIONAL SKILLS:"
  for S in ${MATCHED_LOW}; do echo "  -> srepowers:${S}"; done
  echo ""
fi

echo "ACTION: Use Skill tool BEFORE responding"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
