#!/usr/bin/env bash
# Stage the SREPowers public edition (docs/plans/2026-10-29-public-edition.md, Task 3).
#
# Dry run by default: stage → git init → add → staged validate-repo.py --publish
# → CI-parity tests → report. `--go` additionally removes the pattern file,
# commits, and tags. The script NEVER pushes: publication is approval-gated
# (plan Task 5).
#
# The staging order is load-bearing: the publish gate enumerates staged blobs
# via `git ls-files` and requires a RELEASE-NOTES.md, so the sequence is
# stage → init → add → validate → (rm patterns) → commit → tag.
#
# Edition RELEASE-NOTES are BORN-SANITIZED: generated fresh below, never
# derived from the private notes (they quote site tokens in refusal entries).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Canonicalize DEST before any use: the rm -rf below must only ever be able
# to reach a path we have validated (see the destination-safety block).
DEST="$(realpath -m "${DEST:-/tmp/srepowers-public-edition}")"
GO=0
[ "${1:-}" = "--go" ] && GO=1
EDITION_PLUGINS=(srepowers-core srepowers-infra)

# Tests that depend on plugins the edition does not ship. Extend ONLY when a
# dry-run test failure traces to an excluded plugin — never as a blanket.
# test-container/cost-optimizer/doc-sync/network-engineer/platform-engineer/
# terragrunt assert srepowers-domain skill content; swe-chain and
# upstream-fresh-context assert srepowers-swe; puppet-merge-request asserts
# srepowers-private.
EXCLUDE_TESTS=(
    test-container-engineer.sh
    test-cost-optimizer.sh
    test-doc-sync.sh
    test-network-engineer.sh
    test-platform-engineer.sh
    test-puppet-merge-request.sh
    test-swe-chain.sh
    test-terragrunt-expert.sh
    test-upstream-fresh-context.sh
)

log() { printf '[edition] %s\n' "$*"; }
die() { printf '[edition] FAIL: %s\n' "$*" >&2; exit 1; }

# Destination-safety guards live in their own sourced library so the
# regression tests can exercise every refusal path non-destructively
# (tests/publish-edition/test-dest-guards.sh, run by CI).
# shellcheck source=edition-dest-guards.sh
source "$(dirname "${BASH_SOURCE[0]}")/edition-dest-guards.sh"

# --- 0. preflight ------------------------------------------------------------
# Destination safety FIRST — the guards are pure path checks, so a hostile
# DEST is rejected even when every later preflight would also fail. The
# guards only inspect; the deletion happens in the staging step and only
# after they pass.
edition_dest_guards "$SRC" "$DEST" || exit $?

# Tracked dirtiness only: untracked local state (docs/handoffs/, .pi/) must
# not block a dry run — and cannot contaminate the edition, because the
# post-add audit below requires every staged path to be tracked in SRC.
[ -z "$(git -C "$SRC" status --porcelain --untracked-files=no)" ] \
    || die "private tree has uncommitted tracked changes — commit first"
[ -f "$SRC/.leakpatterns" ] || die "$SRC/.leakpatterns missing — the staged --publish gate needs it"
command -v jq >/dev/null 2>&1 || die "jq is required"
VERSION="$(jq -r '.version' "$SRC/plugins/${EDITION_PLUGINS[0]}/.claude-plugin/plugin.json")"
log "edition $VERSION from $(git -C "$SRC" rev-parse --short HEAD): ${EDITION_PLUGINS[*]} -> $DEST"

# --- 1. stage ----------------------------------------------------------------
rm -rf "$DEST"
mkdir -p "$DEST/plugins" "$DEST/.claude-plugin" "$DEST/.agents/plugins" "$DEST/.agents/skills" \
    "$DEST/.codex/skills" "$DEST/.codex/agents" "$DEST/.codex-plugin" "$DEST/evals/fixtures"
printf 'srepowers edition staging tree — regenerated wholesale by publish-edition.sh; safe to delete\n' \
    > "$DEST/.edition-staging"

for p in "${EDITION_PLUGINS[@]}"; do
    rsync -a "$SRC/plugins/$p/" "$DEST/plugins/$p/"
done
# Vendor PDFs do not ship: redistribution rights are unverified (one is a
# commercial O'Reilly title) and the edition carries canonical URLs instead.
# Owner decision 2026-11-08.
find "$DEST/plugins" -name '*.pdf' -delete
rsync -a "$SRC/scripts/" "$DEST/scripts/"
rsync -a "$SRC/tests/" "$DEST/tests/"
rsync -a "$SRC/.github/" "$DEST/.github/"
rsync -a "$SRC/.codex/agents/" "$DEST/.codex/agents/"
cp "$SRC/.codex/hooks.json" "$DEST/.codex/hooks.json"
cp "$SRC/.codex-plugin/plugin.json" "$DEST/.codex-plugin/plugin.json"
cp "$SRC/.gitignore" "$DEST/.gitignore"
cp "$SRC/LICENSE" "$DEST/LICENSE"
cp "$SRC/README.md" "$DEST/README.md"
cp "$SRC/CONTRIBUTING.md" "$DEST/CONTRIBUTING.md"

# Fixtures: only those belonging to shipped skills.
for d in "$SRC"/evals/fixtures/*/; do
    name="$(basename "$d")"
    for p in "${EDITION_PLUGINS[@]}"; do
        if [ -d "$SRC/plugins/$p/skills/$name" ]; then
            rsync -a "$d" "$DEST/evals/fixtures/$name/"
            break
        fi
    done
done

# Tests that need excluded plugins do not ship.
for t in "${EXCLUDE_TESTS[@]}"; do
    rm -f "$DEST/tests/claude-code/$t"
done

# Marketplaces: keep the edition's plugin entries (jq; the manifests are the
# single declaration of the shipped set — both validators derive from them).
KEEP="$(printf '%s\n' "${EDITION_PLUGINS[@]}" | jq -R . | jq -s .)"
for m in .claude-plugin/marketplace.json .agents/plugins/marketplace.json; do
    jq --argjson keep "$KEEP" '.plugins |= map(select(.name as $n | $keep | index($n)))' \
        "$SRC/$m" > "$DEST/$m"
done

# Mirrors: one symlink per shipped skill, same relative targets as upstream.
for p in "${EDITION_PLUGINS[@]}"; do
    for sd in "$SRC/plugins/$p/skills"/*/; do
        name="$(basename "$sd")"
        ln -s "../../plugins/$p/skills/$name" "$DEST/.agents/skills/$name"
        ln -s "../../plugins/$p/skills/$name" "$DEST/.codex/skills/$name"
    done
done

# Catalog: keep only the shipped plugins' sections.
python3 - "$DEST" "${EDITION_PLUGINS[@]}" <<'PY'
import re
import sys
from pathlib import Path

dest = Path(sys.argv[1])
shipped = set(sys.argv[2:])
cat = dest / "plugins/srepowers-core/skills/using-srepowers/references/skill-catalog.md"
text = cat.read_text()
parts = re.split(r"(?m)^## ", text)
out = [parts[0]]
for part in parts[1:]:
    m = re.match(r"Plugin:\s*(srepowers-[a-z]+)", part)
    if m and m.group(1) in shipped:
        out.append("## " + part)
cat.write_text("".join(out))
print(f"[edition] catalog: kept {len(out) - 1} plugin section(s)")
PY

# README: filter the plugin table, regenerate the Plugin Structure tree,
# add the public-edition note. CONTRIBUTING: filter the plugin-scope table.
python3 - "$DEST" "${EDITION_PLUGINS[@]}" "$VERSION" <<'PY'
import re
import sys
from pathlib import Path

dest = Path(sys.argv[1])
shipped = list(sys.argv[2:-1])
version = sys.argv[-1]

readme = (dest / "README.md").read_text()

# 1. plugin table rows AND install commands: keep shipped plugins only.
# Install-command lines naming unshipped plugins read as "plugin not found"
# for edition visitors — the exact defect the v5.41.2 review caught.
shipped_set = set(shipped)
rows = []
for line in readme.splitlines():
    m = re.match(r"^/plugin install (srepowers-[a-z]+)@srepowers-marketplace$", line)
    if m and m.group(1) not in shipped_set:
        continue
    m = re.match(r"^\|\s*`(srepowers-[a-z]+)`\s*\|", line)
    if m and m.group(1) not in shipped_set:
        continue
    rows.append(line)
readme = "\n".join(rows) + "\n"
# combined one-liner: rebuild from the shipped set
allcmd = "/plugin install " + " ".join(f"{p}@srepowers-marketplace" for p in shipped)
readme = re.sub(
    r"^/plugin install (srepowers-[a-z]+@srepowers-marketplace)(?: srepowers-[a-z]+@srepowers-marketplace)+$",
    allcmd,
    readme,
    count=1,
    flags=re.MULTILINE,
)
# 1b. Codex install-step bullets naming unshipped plugins (bullet list form:
# "- `srepowers-X` — description"): drop unshipped entries.
readme = "\n".join(
    l for l in readme.splitlines()
    if not (m := re.match(r"^[-*] `(srepowers-[a-z]+)` — ", l)) or m.group(1) in shipped_set
)
if readme.endswith("\n\n"):
    readme = readme[:-1]

# 2. counts + mirror count from the staged tree
counts = {p: len(list((dest / "plugins" / p / "skills").iterdir())) for p in shipped}
mirror_n = len(list((dest / ".agents" / "skills").iterdir()))

# 3. regenerate the Plugin Structure section
tree_lines = ["srepowers/"]
tree_lines.append("├── .claude-plugin/marketplace.json     ← lists the edition's plugins")
tree_lines.append("├── plugins/")
for i, p in enumerate(shipped):
    tree_lines.append(f"│   {'└──' if i == len(shipped) - 1 else '├──'} {p}/                 ← {counts[p]} skills")
    inner = [".claude-plugin/plugin.json", ".codex-plugin/plugin.json", "skills/", "commands/"]
    if (dest / "plugins" / p / "hooks").is_dir():
        inner.append("hooks/")
    for j, row in enumerate(inner):
        tree_lines.append(f"│   {'    ' if i == len(shipped) - 1 else '│   '}{'└──' if j == len(inner) - 1 else '├──'} {row}")
tree_lines.append(f"├── .agents/skills/                     ← Codex skill mirror ({mirror_n} symlinks)")
tree_lines.append("├── .codex/skills/                      ← Codex repo-native symlinks")
tree_lines.append("├── .codex/agents/                      ← Codex custom agents")
tree_lines.append("├── .codex-plugin/                      ← Codex plugin manifest")
tree_lines.append("├── tests/, scripts/                    ← shared resources")
tree_lines.append("├── evals/fixtures/                     ← skill-test fixtures")
tree_lines.append("└── README.md, LICENSE")
# 3. regenerate ONLY the fenced tree inside the Plugin Structure section —
#    the plugin table lives in the same section and is already row-filtered
#    by step 1; a whole-section replacement would eat it (it did, once).
section_m = re.search(r"(?ms)^## Plugin Structure\s*\n.*?(?=^## |\Z)", readme)
if section_m is None:
    raise SystemExit("README has no Plugin Structure section")
sec = section_m.group(0)
sec = re.sub(
    r"(?ms)(^```\n).*?(```)",
    lambda m: m.group(1) + "\n".join(tree_lines) + "\n" + m.group(2),
    sec,
    count=1,
)
sec = sec.replace("containing five plugins", f"containing {len(shipped)} plugins")
readme = readme[: section_m.start()] + sec + readme[section_m.end():]

# 4. public-edition note right after the intro paragraph (string splice:
#    a regex replacement template would parse the note as backreferences)
note = (
    "> **Public edition:** this distribution ships `srepowers-core` and "
    "`srepowers-infra`. The `srepowers-domain`, `srepowers-private` (site "
    "templates), and `srepowers-swe` plugins are separate distributions; "
    "references to them describe the full distribution."
)
i = readme.find("\n\n")
if i != -1:
    readme = readme[:i] + "\n\n" + note + "\n" + readme[i:]

# 5. provenance note: swe/private skills named in the table ship separately
readme = readme.replace(
    "the pinned source revision is recorded there.",
    "the pinned source revision is recorded there. Skills named with a "
    "`srepowers-swe:`/`srepowers-private:` prefix ship in those plugins, "
    "distributed separately from this edition.",
)

(dest / "README.md").write_text(readme)

contrib = (dest / "CONTRIBUTING.md").read_text().splitlines()
kept = [
    line
    for line in contrib
    if not re.match(r"^\|\s*`(srepowers-(domain|private|swe))`\s*\|", line)
]
(dest / "CONTRIBUTING.md").write_text("\n".join(kept) + "\n")
print(f"[edition] README + CONTRIBUTING rewritten for {len(shipped)} plugins")
PY

# RELEASE-NOTES: born-sanitized, edition-only. Never derive from the private
# notes — they quote site tokens in refusal entries (the private-root
# --publish gate fails on exactly those).
# EDITION_INITIAL=1 marks the FIRST cut of a (possibly recreated) public
# repo; default 0 — a cut is an edition update, not "initial". The 5.41.1
# push shipped the hardcoded "(initial)" label wrongly (5.41.0 was initial).
NOTES_TITLE="## $VERSION — SREPowers public edition"
NOTES_LEAD="An edition of SREPowers, shipping the"
if [ "${EDITION_INITIAL:-0}" = "1" ]; then
    NOTES_TITLE="## $VERSION — SREPowers public edition (initial)"
    NOTES_LEAD="The first public edition of SREPowers, shipping the"
fi
cat > "$DEST/RELEASE-NOTES.md" <<NOTES
# Release Notes

$NOTES_TITLE

$NOTES_LEAD
$(printf '%s and %s' "${EDITION_PLUGINS[0]}" "${EDITION_PLUGINS[1]}") plugins.
The full distribution additionally ships srepowers-domain,
srepowers-private (site templates), and srepowers-swe as separate
distributions.

This file is born-sanitized: edition notes are authored fresh here and
never derived from the private development history.
NOTES

# --- 2. init → add → validate (order is load-bearing) ------------------------
git -C "$DEST" init -q -b main
git -C "$DEST" add .github .agents .codex .codex-plugin .claude-plugin \
    evals plugins scripts tests .gitignore CONTRIBUTING.md LICENSE \
    README.md RELEASE-NOTES.md
cp "$SRC/.leakpatterns" "$DEST/.leakpatterns"      # untracked; removed before any commit
cp "$SRC/.editionpatterns" "$DEST/.editionpatterns"  # same rule — never tracked, never committed

# Contamination audit: every staged path must be a tracked path in SRC — an
# untracked scratch file inside plugins/ would otherwise rsync straight into
# the edition and read as payload.
while IFS= read -r f; do
    git -C "$SRC" ls-files --error-unmatch "$f" >/dev/null 2>&1 \
        || die "staged path not tracked in SRC (contamination?): $f"
done < <(git -C "$DEST" ls-files)

log "staged payload: $(git -C "$DEST" ls-files | wc -l) tracked files"
( cd "$DEST" && python3 scripts/validate-repo.py --publish ) || die "staged publish gate failed"

# --- 3. CI-parity suite against the staged tree --------------------------------
# Every loop iteration propagates its own failure with an explicit
# `|| exit 1`. Do NOT rely on `set -e` here: the subshells are the left side
# of `|| die`, and bash suppresses errexit inside a command whose failure is
# being tested — demonstrated live in review: a mid-loop test failure was
# masked by the last iteration's exit 0, and an edition with red hosted CI
# passed this suite. The explicit propagation is what makes the guarantee.
log "running CI-parity suite against the staged tree"
( cd "$DEST" && set -e && bash tests/codex/run-skill-tests.sh ) >/dev/null || die "codex packaging tests failed"
( cd "$DEST" && set -e
  found=0
  for t in tests/hooks/test-*.sh; do echo "== $t"; bash "$t" >/dev/null || exit 1; found=$((found + 1)); done
  for t in tests/hooks/test-*.py; do echo "== $t"; python3 "$t" >/dev/null || exit 1; found=$((found + 1)); done
  [ "$found" -gt 0 ] || { echo "FAIL: no hooks tests found in staging" >&2; exit 1; }
  echo "ran $found hooks test(s)"
) || die "hooks tests failed"
( cd "$DEST" && set -e && python3 plugins/srepowers-core/skills/fixture-lint/scripts/fixture_lint.py ) \
    || die "fixture lint failed"
( cd "$DEST" && set -e
  shopt -s nullglob
  found=0
  for t in tests/claude-code/test-*.sh; do
      grep -q 'run_claude' "$t" && continue
      echo "== $t"; bash "$t" >/dev/null || exit 1
      found=$((found + 1))
  done
  [ "$found" -gt 0 ] || { echo "FAIL: no content tests found in staging" >&2; exit 1; }
  echo "ran $found content test(s)"
) || die "content tests failed"
( cd "$DEST" && set -e && bash scripts/lint-shell.sh --all --strict ) || die "shell lint failed"
( cd "$DEST" && set -e
  shopt -s nullglob
  found=0
  for t in tests/shell-lint/test-*.sh tests/publish-edition/test-*.sh; do
      echo "== $t"; bash "$t" >/dev/null || exit 1
      found=$((found + 1))
  done
  [ "$found" -gt 0 ] || { echo "FAIL: no shell-linter/dest-guard tests found in staging" >&2; exit 1; }
  echo "ran $found shell-linter/dest-guard test(s)"
) || die "shell-linter/dest-guard tests failed"
( cd "$DEST" && set -e
  shopt -s nullglob
  found=0
  for t in plugins/*/skills/*/scripts/test_*.py; do
      echo "== $t"; python3 -B "$t" >/dev/null || exit 1
      found=$((found + 1))
  done
  [ "$found" -gt 0 ] || { echo "FAIL: no skill test suites found in staging" >&2; exit 1; }
  echo "ran $found skill test suite(s)"
) || die "skill script tests failed"

# --- 4. verdict / commit -------------------------------------------------------
log "dry run complete — review the skip report above and the staged tree at $DEST"
if [ "$GO" -eq 1 ]; then
    rm "$DEST/.leakpatterns" "$DEST/.editionpatterns"
    GIT_NAME="$(git -C "$SRC" log -1 --format=%an)"
    GIT_EMAIL="$(git -C "$SRC" log -1 --format=%ae)"
    git -C "$DEST" -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" \
        commit -q -m "SREPowers public edition $VERSION (plugins: ${EDITION_PLUGINS[*]})"
    git -C "$DEST" -c user.name="$GIT_NAME" -c user.email="$GIT_EMAIL" \
        tag -a "v$VERSION" -m "SREPowers public edition $VERSION"
    log "committed + tagged v$VERSION in $DEST (NOT pushed — publication is approval-gated, plan Task 5)"
else
    log "dry run only — pass --go to commit + tag (still no push)"
fi
