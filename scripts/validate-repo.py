#!/usr/bin/env python3
"""Validate SREPowers packaging metadata and skill layout."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGINS = {
    "srepowers-core": 28,
    "srepowers-domain": 20,
    "srepowers-infra": 16,
}


def fail(message: str) -> None:
    raise SystemExit(f"[FAIL] {message}")


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"{path.relative_to(ROOT)} invalid JSON: {exc}")


def validate_json_files() -> None:
    for path in sorted(ROOT.rglob("*.json")):
        load_json(path)


def plugin_versions() -> list[str]:
    paths = [
        ROOT / ".claude-plugin" / "marketplace.json",
        ROOT / ".codex-plugin" / "plugin.json",
        ROOT / ".agents" / "plugins" / "marketplace.json",
    ]
    paths.extend(ROOT.glob("plugins/*/.claude-plugin/plugin.json"))
    paths.extend(ROOT.glob("plugins/*/.codex-plugin/plugin.json"))

    versions: list[str] = []
    for path in paths:
        data = load_json(path)
        if not isinstance(data, dict):
            fail(f"{path.relative_to(ROOT)} must contain a JSON object")

        if "version" in data:
            versions.append(str(data["version"]))
        metadata = data.get("metadata")
        if isinstance(metadata, dict) and "version" in metadata:
            versions.append(str(metadata["version"]))
        for entry in data.get("plugins", []):
            if isinstance(entry, dict) and "version" in entry:
                versions.append(str(entry["version"]))
    return versions


def validate_versions() -> None:
    versions = plugin_versions()
    if len(set(versions)) != 1:
        fail(f"plugin versions differ: {sorted(set(versions))}")


def validate_skills() -> None:
    seen: set[str] = set()

    for plugin, expected_count in PLUGINS.items():
        plugin_root = ROOT / "plugins" / plugin
        skills_dir = plugin_root / "skills"
        commands_dir = plugin_root / "commands"

        skills = sorted(path.parent.name for path in skills_dir.glob("*/SKILL.md"))
        commands = sorted(path.stem for path in commands_dir.glob("*.md"))

        if len(skills) != expected_count:
            fail(f"{plugin} skill count: expected {expected_count}, got {len(skills)}")
        if skills != commands:
            fail(f"{plugin} skills and command wrappers differ")

        for skill in skills:
            if skill in seen:
                fail(f"duplicate skill name: {skill}")
            seen.add(skill)

            text = (skills_dir / skill / "SKILL.md").read_text()
            match = re.search(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
            if not match:
                fail(f"{plugin}/{skill} missing YAML frontmatter")
            frontmatter = match.group(1)
            name = re.search(r"^name:\s*(.+)$", frontmatter, re.MULTILINE)
            description = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
            if not name:
                fail(f"{plugin}/{skill} missing frontmatter name")
            if name.group(1).strip() != skill:
                fail(f"{plugin}/{skill} frontmatter name mismatch")
            if not description:
                fail(f"{plugin}/{skill} missing frontmatter description")

    readme = (ROOT / "README.md").read_text()
    for plugin, expected_count in PLUGINS.items():
        if f"`{plugin}` | {expected_count} |" not in readme:
            fail(f"README skill count missing or stale for {plugin}")


def validate_mirrors() -> None:
    canonical = sorted(
        path.parent.name
        for plugin in PLUGINS
        for path in (ROOT / "plugins" / plugin / "skills").glob("*/SKILL.md")
    )

    for mirror in (ROOT / ".agents" / "skills", ROOT / ".codex" / "skills"):
        mirrored = sorted(path.name for path in mirror.iterdir() if path.is_dir() or path.is_symlink())
        if mirrored != canonical:
            fail(f"{mirror.relative_to(ROOT)} does not match canonical plugin skills")
        broken = [path.name for path in mirror.iterdir() if path.is_symlink() and not path.exists()]
        if broken:
            fail(f"{mirror.relative_to(ROOT)} has broken symlinks: {', '.join(broken)}")


def validate_claude_tests() -> None:
    obsolete = []
    for path in sorted((ROOT / "tests" / "claude-code").glob("test-*.sh")):
        text = path.read_text()
        if "$REPO_ROOT/skills/" in text or "$REPO_ROOT/commands/" in text:
            obsolete.append(str(path.relative_to(ROOT)))
    if obsolete:
        fail(f"Claude tests reference obsolete root paths: {', '.join(obsolete)}")


def main() -> None:
    validate_json_files()
    validate_versions()
    validate_skills()
    validate_mirrors()
    validate_claude_tests()
    print("[PASS] repository metadata, skills, commands, versions, and mirrors are valid")


if __name__ == "__main__":
    main()
