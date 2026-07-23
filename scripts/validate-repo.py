#!/usr/bin/env python3
"""Validate SREPowers packaging metadata and skill layout."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PLUGINS = (
    "srepowers-core",
    "srepowers-domain",
    "srepowers-infra",
    "srepowers-private",
    "srepowers-swe",
)


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


def manifest_paths() -> list[Path]:
    """Every JSON manifest that carries a version string."""
    paths = [
        ROOT / ".claude-plugin" / "marketplace.json",
        ROOT / ".codex-plugin" / "plugin.json",
        ROOT / ".agents" / "plugins" / "marketplace.json",
    ]
    paths.extend(sorted(ROOT.glob("plugins/*/.claude-plugin/plugin.json")))
    paths.extend(sorted(ROOT.glob("plugins/*/.codex-plugin/plugin.json")))
    return paths


def version_sites(path: Path) -> list[tuple[str, str]]:
    """Return (json-pointer-ish field, value) pairs for one manifest.

    Versions live in three shapes: a top-level `version`, a
    `metadata.version` (marketplace root), and per-entry `plugins.N.version`.
    Discovering them structurally keeps this list from drifting out of sync
    with the packaging layout the way a hardcoded file list would.
    """
    data = load_json(path)
    if not isinstance(data, dict):
        fail(f"{path.relative_to(ROOT)} must contain a JSON object")

    sites: list[tuple[str, str]] = []
    if "version" in data:
        sites.append(("version", str(data["version"])))
    metadata = data.get("metadata")
    if isinstance(metadata, dict) and "version" in metadata:
        sites.append(("metadata.version", str(metadata["version"])))
    for index, entry in enumerate(data.get("plugins", [])):
        if isinstance(entry, dict) and "version" in entry:
            sites.append((f"plugins.{index}.version", str(entry["version"])))
    return sites


def plugin_versions() -> list[str]:
    versions: list[str] = []
    for path in manifest_paths():
        versions.extend(value for _, value in version_sites(path))
    return versions


def set_version(new_version: str) -> None:
    """Rewrite every `"version": "..."` line in the version-bearing manifests.

    Substitutes at the text level rather than round-tripping through
    json.dumps: these manifests are hand-formatted (grouped keyword arrays,
    inline capability lists) and contain non-ASCII punctuation, both of which
    a dump-and-rewrite would silently destroy.
    """
    if not re.fullmatch(r"\d+\.\d+\.\d+", new_version):
        fail(f"version must be MAJOR.MINOR.PATCH, got: {new_version}")

    pattern = re.compile(r'("version"\s*:\s*")\d+\.\d+\.\d+(")')
    updated = 0
    sites = 0
    for path in manifest_paths():
        original = path.read_text()
        replaced, count = pattern.subn(rf"\g<1>{new_version}\g<2>", original)
        if count:
            path.write_text(replaced)
            updated += 1
            sites += count

    print(f"[OK] set version {new_version} at {sites} sites across {updated} manifests")


def validate_versions() -> None:
    versions = plugin_versions()
    if len(set(versions)) != 1:
        fail(f"plugin versions differ: {sorted(set(versions))}")


def validate_skills() -> None:
    seen: set[str] = set()
    counts: dict[str, int] = {}

    for plugin in PLUGINS:
        plugin_root = ROOT / "plugins" / plugin
        skills_dir = plugin_root / "skills"
        commands_dir = plugin_root / "commands"

        skills = sorted(path.parent.name for path in skills_dir.glob("*/SKILL.md"))
        commands = sorted(path.stem for path in commands_dir.glob("*.md"))
        counts[plugin] = len(skills)

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
    for plugin, count in counts.items():
        if f"`{plugin}` | {count} |" not in readme:
            fail(f"README skill count missing or stale for {plugin} (expected {count})")


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


def show_versions() -> None:
    for path in manifest_paths():
        for field, value in version_sites(path):
            print(f"{path.relative_to(ROOT)}\t{field}\t{value}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--bump",
        metavar="VERSION",
        help="set every version-bearing manifest to VERSION, then validate",
    )
    group.add_argument(
        "--show-versions",
        action="store_true",
        help="list every version site and its current value",
    )
    args = parser.parse_args()

    if args.show_versions:
        show_versions()
        return

    if args.bump:
        set_version(args.bump)

    validate_json_files()
    validate_versions()
    validate_skills()
    validate_mirrors()
    validate_claude_tests()
    print("[PASS] repository metadata, skills, commands, versions, and mirrors are valid")


if __name__ == "__main__":
    main()
