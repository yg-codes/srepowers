#!/usr/bin/env bash
# Lightweight Codex-oriented validation for repo-native and plugin packaging.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"

echo "========================================"
echo " Codex Skill Validation"
echo "========================================"
echo ""

fail() {
  echo "[FAIL] $1"
  exit 1
}

pass() {
  echo "[PASS] $1"
}

[ -f .codex-plugin/plugin.json ] || fail ".codex-plugin/plugin.json missing"
pass "Codex plugin manifest present"

[ -f .agents/plugins/marketplace.json ] || fail ".agents/plugins/marketplace.json missing"
pass "Codex marketplace present"

[ -f .codex/hooks.json ] || fail ".codex/hooks.json missing"
pass "Codex hooks config present"

[ -f .codex/agents/infrastructure-operator.toml ] || fail "Codex infrastructure operator missing"
[ -f .codex/agents/infrastructure-reviewer.toml ] || fail "Codex infrastructure reviewer missing"
pass "Codex custom agents present"

[ -d .agents/skills ] || fail ".agents/skills directory missing"
[ -d .codex/skills ] || fail ".codex/skills directory missing"

python3 - <<'PY'
import json
import re
from pathlib import Path

plugins = (
    "srepowers-core",
    "srepowers-domain",
    "srepowers-infra",
    "srepowers-private",
)

marketplace = json.loads(Path(".agents/plugins/marketplace.json").read_text())
entries = {entry["name"]: entry for entry in marketplace["plugins"]}
root_manifest = json.loads(Path(".codex-plugin/plugin.json").read_text())
versions = {root_manifest["version"]}

for plugin in plugins:
    plugin_root = Path("plugins") / plugin
    codex_manifest = plugin_root / ".codex-plugin" / "plugin.json"
    claude_manifest = plugin_root / ".claude-plugin" / "plugin.json"
    skills_dir = plugin_root / "skills"
    commands_dir = plugin_root / "commands"

    if not codex_manifest.is_file():
        raise SystemExit(f"{codex_manifest} missing")
    if not claude_manifest.is_file():
        raise SystemExit(f"{claude_manifest} missing")

    entry = entries.get(plugin)
    if not entry:
        raise SystemExit(f"{plugin} missing from Codex marketplace")

    manifest = json.loads(codex_manifest.read_text())
    claude_plugin_manifest = json.loads(claude_manifest.read_text())
    versions.update(
        {
            entry["version"],
            manifest["version"],
            claude_plugin_manifest["version"],
        }
    )
    if manifest.get("name") != plugin:
        raise SystemExit(f"{codex_manifest} name mismatch")
    if manifest.get("skills") != "./skills/":
        raise SystemExit(f"{codex_manifest} skills path must be ./skills/")

    skills = sorted(path.parent.name for path in skills_dir.glob("*/SKILL.md"))
    commands = sorted(path.stem for path in commands_dir.glob("*.md"))
    if skills != commands:
        raise SystemExit(f"{plugin} skills and commands differ")

    for skill in skills:
        text = (skills_dir / skill / "SKILL.md").read_text()
        match = re.search(r"^name:\s*(.+)$", text, re.MULTILINE)
        if not match:
            raise SystemExit(f"{plugin}/{skill} missing frontmatter name")
        if match.group(1).strip() != skill:
            raise SystemExit(f"{plugin}/{skill} frontmatter name mismatch")

    source = entry.get("source")
    if not isinstance(source, dict):
        raise SystemExit(f"{plugin} marketplace source must be object")
    if source.get("source") != "local":
        raise SystemExit(f"{plugin} marketplace source.source must be local")
    if source.get("path") != f"./plugins/{plugin}":
        raise SystemExit(f"{plugin} marketplace source.path mismatch")
    if entry.get("category") != "Engineering":
        raise SystemExit(f"{plugin} marketplace category must be Engineering")

if len(versions) != 1:
    raise SystemExit(f"Codex marketplace and plugin versions differ: {sorted(versions)}")

canonical = sorted(
    path.parent.name
    for plugin in plugins
    for path in (Path("plugins") / plugin / "skills").glob("*/SKILL.md")
)
for mirror in (Path(".agents/skills"), Path(".codex/skills")):
    mirrored = sorted(path.name for path in mirror.iterdir() if path.is_dir() or path.is_symlink())
    if mirrored != canonical:
        raise SystemExit(f"{mirror} does not match canonical plugin skills")
    broken = [path.name for path in mirror.iterdir() if path.is_symlink() and not path.exists()]
    if broken:
        raise SystemExit(f"{mirror} has broken symlinks: {', '.join(broken)}")
PY

pass "Codex marketplace, plugin manifests, skills, commands, and mirrors are consistent"

if command -v codex >/dev/null 2>&1; then
  echo ""
  echo "codex detected: $(codex --version 2>/dev/null || echo unknown)"
else
  echo ""
  echo "[INFO] codex CLI not installed; skipping interactive runtime checks"
fi

echo ""
echo "STATUS: PASSED"
