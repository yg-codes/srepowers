#!/usr/bin/env bash
# Bisection script to find which flaky-check step creates unwanted files/state.
# Recast for SRE flaky-check bisection: run a sequence of check scripts and
# find the one that leaves behind a stray file, lock, temp dir, or other state
# that pollutes subsequent checks and makes a suite intermittently fail.
#
# Usage: ./find-polluter.sh <file_or_dir_to_check> <check_glob>
# Example: ./find-polluter.sh '/tmp/.deploy.lock' 'checks/**/*.sh'

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 <file_to_check> <check_glob>"
  echo "Example: $0 '/tmp/.deploy.lock' 'checks/**/*.sh'"
  exit 1
fi

POLLUTION_CHECK="$1"
CHECK_GLOB="$2"

echo "🔍 Searching for the check that creates: $POLLUTION_CHECK"
echo "Check glob: $CHECK_GLOB"
echo ""

# Get list of check scripts
CHECK_FILES=$(find . -path "$CHECK_GLOB" | sort)
TOTAL=$(echo "$CHECK_FILES" | wc -l | tr -d ' ')

echo "Found $TOTAL check scripts"
echo ""

COUNT=0
for CHECK_FILE in $CHECK_FILES; do
  COUNT=$((COUNT + 1))

  # Skip if pollution already exists
  if [ -e "$POLLUTION_CHECK" ]; then
    echo "⚠️  Pollution already exists before check $COUNT/$TOTAL"
    echo "   Skipping: $CHECK_FILE"
    continue
  fi

  echo "[$COUNT/$TOTAL] Running: $CHECK_FILE"

  # Run the check (ignore its own pass/fail — we only care about state it leaves)
  bash "$CHECK_FILE" > /dev/null 2>&1 || true

  # Check if pollution appeared
  if [ -e "$POLLUTION_CHECK" ]; then
    echo ""
    echo "🎯 FOUND POLLUTER!"
    echo "   Check: $CHECK_FILE"
    echo "   Created: $POLLUTION_CHECK"
    echo ""
    echo "Pollution details:"
    ls -la "$POLLUTION_CHECK"
    echo ""
    echo "To investigate:"
    echo "  bash $CHECK_FILE       # Run just this check"
    echo "  cat $CHECK_FILE        # Review check code"
    exit 1
  fi
done

echo ""
echo "✅ No polluter found - all checks clean!"
exit 0
