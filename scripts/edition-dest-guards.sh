#!/usr/bin/env bash
# Destination-safety guards for publish-edition.sh — sourced, never executed.
#
# Kept in its own file so tests/publish-edition/test-dest-guards.sh can
# exercise every refusal path non-destructively: this library only INSPECTS
# paths (no rm anywhere); the deletion itself stays in publish-edition.sh,
# which refuses to proceed unless these guards pass.
#
# Contract: edition_dest_guards SRC DEST
#   exit 0  — destination accepted (nonexistent, empty, or marker-carrying)
#   exit 2  — destination refused; reason printed to stderr
edition_dest_guards() {
    if [ "$#" -ne 2 ]; then
        printf 'edition_dest_guards: usage: edition_dest_guards SRC DEST\n' >&2
        return 2
    fi
    local src="$1" dest="$2"

    # The source checkout is untouchable from either direction: DEST may not
    # be it, sit inside it, or contain it.
    case "$dest/" in
        "$src/") printf 'DEST equals the source checkout — refusing\n' >&2; return 2 ;;
        "$src"/*) printf 'DEST is inside the source checkout — refusing\n' >&2; return 2 ;;
    esac
    case "$src/" in
        "$dest"/*) printf 'DEST contains the source checkout — refusing\n' >&2; return 2 ;;
    esac
    # Filesystem root, unconditionally: the case guards above cannot express
    # it cleanly (every path is "inside" / once the trailing-slash forms line
    # up), and the marker check must not be the only thing standing between a
    # typo and `rm -rf /` — GNU rm's own --preserve-root guard is a backstop,
    # not a plan.
    [ "$dest" != "/" ] || { printf 'DEST is the filesystem root — refusing\n' >&2; return 2; }
    # Root-equivalent targets: refuse any top-level directory as staging.
    if [ "$(dirname "$dest")" = "/" ]; then
        printf 'DEST is a top-level directory — refusing (staging belongs under a working path like /tmp)\n' >&2
        return 2
    fi
    # An existing, non-empty destination may be regenerated only if it
    # carries this script's own staging marker; anything else is an
    # unrelated directory and is refused, never deleted.
    if [ -e "$dest" ] && [ -n "$(ls -A "$dest")" ]; then
        if [ ! -f "$dest/.edition-staging" ]; then
            printf 'DEST exists, is non-empty, and lacks the staging marker — refusing to delete: %s\n' "$dest" >&2
            return 2
        fi
    fi
    return 0
}
