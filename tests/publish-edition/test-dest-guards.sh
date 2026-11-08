#!/usr/bin/env bash
# Non-destructive regression tests for the publish-edition.sh destination
# guards (scripts/edition-dest-guards.sh). Every refusal path is exercised
# against representative paths; the guards only inspect, so nothing is ever
# created-then-deleted beyond two empty temp dirs and one marker file.
#
# CI runs this via the globbed "edition destination guards" step in
# .github/workflows/validate.yml.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../../scripts/edition-dest-guards.sh
source "$REPO_ROOT/scripts/edition-dest-guards.sh"

SRC="$REPO_ROOT"
pass=0

expect_refusal() { # expect_refusal <label> <dest> <message-substring>
    local label="$1" dest="$2" want="$3" out rc=0
    out="$(edition_dest_guards "$SRC" "$dest" 2>&1 >/dev/null)" || rc=$?
    if [ "$rc" -ne 2 ] || ! printf '%s' "$out" | grep -q "$want"; then
        printf 'FAIL %s: rc=%s out=%s (wanted rc=2 matching %q)\n' "$label" "$rc" "$out" "$want" >&2
        exit 1
    fi
    pass=$((pass + 1))
    printf 'ok   %s -> refused (%s)\n' "$label" "$want"
}

expect_accept() { # expect_accept <label> <dest>
    local label="$1" dest="$2" out rc=0
    out="$(edition_dest_guards "$SRC" "$dest" 2>&1 >/dev/null)" || rc=$?
    if [ "$rc" -ne 0 ]; then
        printf 'FAIL %s: rc=%s out=%s (wanted rc=0)\n' "$label" "$rc" "$out" >&2
        exit 1
    fi
    pass=$((pass + 1))
    printf 'ok   %s -> accepted\n' "$label"
}

expect_refusal "dest-equals-src"        "$SRC"                    "equals the source checkout"
expect_refusal "dest-inside-src"        "$SRC/build/edition"      "inside the source checkout"
expect_refusal "dest-contains-src"      "$(dirname "$SRC")"       "contains the source checkout"
expect_refusal "filesystem-root"        "/"                       "filesystem root"
# /tmp is location-fragile by design: when the repo itself lives under /tmp
# (the edition stager's DEST), the contains-source guard fires first — a
# correct refusal either way. Accept both messages; assert the refusal.
rc=0
out="$(edition_dest_guards "$SRC" "/tmp" 2>&1 >/dev/null)" || rc=$?
if [ "$rc" -ne 2 ] || ! printf '%s' "$out" | grep -qE "top-level directory|contains the source checkout"; then
    printf 'FAIL top-level-dir: rc=%s out=%s (wanted rc=2, top-level or contains-source refusal)\n' "$rc" "$out" >&2
    exit 1
fi
printf 'ok   top-level-dir -> refused (%s)\n' "$(printf '%s' "$out" | head -1)"
pass=$((pass + 1))

# An unrelated non-empty directory is refused and its contents untouched.
GUARD_TMP="$(mktemp -d)"
trap 'rm -rf "$GUARD_TMP"' EXIT
mkdir -p "$GUARD_TMP/unrelated"
printf 'important\n' > "$GUARD_TMP/unrelated/important.txt"
expect_refusal "unrelated-nonempty-dir" "$GUARD_TMP/unrelated"   "lacks the staging marker"
[ -f "$GUARD_TMP/unrelated/important.txt" ] || { printf 'FAIL: unrelated dir was mutated\n' >&2; exit 1; }
printf 'ok   unrelated-dir-intact (file survived)\n'
pass=$((pass + 1))

# Acceptance paths: marked staging tree, empty dir, nonexistent deep path,
# and the canonical working destination.
mkdir -p "$GUARD_TMP/marked"
printf 'staging\n' > "$GUARD_TMP/marked/.edition-staging"
expect_accept "marked-staging-tree"     "$GUARD_TMP/marked"
mkdir -p "$GUARD_TMP/empty"
expect_accept "empty-dir"               "$GUARD_TMP/empty"
expect_accept "nonexistent-deep-path"   "$GUARD_TMP/does/not/exist/yet"
# Canonical dest — but when this test runs INSIDE the staging tree (parity
# suite), the canonical path IS the source; use an equivalent deep path.
CANON="${CANONICAL_DEST:-/tmp/srepowers-public-edition}"
if [ "$CANON" = "$SRC" ]; then
    CANON="$GUARD_TMP/edition-work"
fi
expect_accept "canonical-dest"          "$CANON"

printf 'PASS: %d destination-guard assertions\n' "$pass"
