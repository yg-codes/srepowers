#!/usr/bin/env python3
"""Validate SREPowers packaging metadata and skill layout.

Default mode is contributor-friendly: a missing local .leakpatterns only
warns. `--publish` is the pre-release gate — it hard-requires that file,
because CI (which never has it, by design) proves only the placeholder
contract, never the absence of real site data.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Optional: enables real YAML parsing of skill frontmatter in validate_skills.
# CI installs pyyaml; a stdlib-only local run falls back to regex checks.
try:
    import yaml
except ImportError:  # pragma: no cover - exercised only on pyyaml-free hosts
    yaml = None


ROOT = Path(__file__).resolve().parents[1]

# Edition-scope disclosure patterns — loaded from an untracked local file
# (.editionpatterns) in publish mode ONLY. These are ESTATE SHAPES that must
# not ship in a public edition of core+infra but occur legitimately in the
# private plugin and in the audit docs that quote them as evidence. They are
# NOT hardcoded here: the patterns ARE the site's conventions, and this file
# SHIPS — an earlier revision embedded them as literals and published the
# very conventions the Task-4 remediation had scrubbed from the skills.
# Same contract as .leakpatterns: gitignored, local-only, hard-fail in
# publish mode when absent or empty.
def _load_edition_patterns() -> list[tuple[str, str]]:
    spec = ROOT / ".editionpatterns"
    if not spec.exists():
        fail(
            f"{spec.name} absent — publish mode needs the edition-scope pattern "
            "set (local-only, gitignored; create it per the manifest)"
        )
    patterns: list[tuple[str, str]] = []
    for raw in spec.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        regex, _, label = line.partition("\t")
        patterns.append((regex.strip(), label.strip() or "edition shape"))
    if not patterns:
        fail(f"{spec.name} carries zero patterns (empty or comment-only)")
    return patterns


def fail(message: str) -> None:
    raise SystemExit(f"[FAIL] {message}")


def plugin_names() -> tuple[str, ...]:
    """Derive the plugin set from the marketplace manifest.

    The shipped-plugin set is declared exactly once — in
    .claude-plugin/marketplace.json — and read from there by this validator
    and by tests/codex/run-skill-tests.sh. A hardcoded tuple in two scripts
    drifted from a new plugin's mirrors once (5.9.0); deriving it also lets
    the same validator check a public EDITION (a plugin subset) without code
    changes: the edition's regenerated marketplace defines its plugin set.

    Defined AFTER fail(): this runs at import time (module-level PLUGINS
    below), so a malformed or missing manifest must reach the intended
    diagnostic, not a NameError.
    """
    mp = ROOT / ".claude-plugin" / "marketplace.json"
    try:
        data = json.loads(mp.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"cannot derive the plugin set from {mp.relative_to(ROOT)}: {exc}")
    entries = data.get("plugins") if isinstance(data, dict) else None
    names = [e.get("name") for e in entries] if isinstance(entries, list) else []
    if not names or any(not isinstance(n, str) or not n for n in names):
        fail(f"{mp.relative_to(ROOT)} carries no usable plugin name list")
    return tuple(names)  # type: ignore[misc]


PLUGINS = plugin_names()


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


_PYRAML_WARNED = False


def _warn_no_pyyaml() -> None:
    """Announce the regex fallback once, loudly.

    A silent fallback is how the frontmatter gate degrades to the exact regex
    that missed the 5.16.0 defect with no signal: same exit code, weaker
    check. Degradation must be visible, even when it is intentional (a
    stdlib-only local run).
    """
    global _PYRAML_WARNED
    if not _PYRAML_WARNED:
        _PYRAML_WARNED = True
        print(
            "WARNING: pyyaml absent — skill frontmatter checked by regex only; "
            "YAML-invalid descriptions will NOT be caught (pip install pyyaml)",
            file=sys.stderr,
        )


def check_name_description(plugin: str, skill: str, name: object, description: object) -> None:
    """The name/description contract, shared by the parse and fallback branches
    so the two cannot drift apart."""
    if name is None:
        fail(f"{plugin}/{skill} missing frontmatter name")
    if str(name).strip() != skill:
        fail(f"{plugin}/{skill} frontmatter name mismatch")
    if description is None:
        fail(f"{plugin}/{skill} missing frontmatter description")


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

        # Command wrappers ride through the same YAML load path in Claude
        # Code, but until 5.27.7 nothing here parsed them — an unescaped inner
        # quote in a double-quoted description shipped in 5.27.5 and made the
        # whole plugin unloadable ("Unexpected scalar at node end"). Parse
        # them like skills: real YAML, not regex.
        for command in commands:
            text = (commands_dir / f"{command}.md").read_text()
            match = re.search(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
            if not match:
                fail(f"{plugin}/{command} command wrapper missing YAML frontmatter")
            frontmatter = match.group(1)
            if yaml is None:
                _warn_no_pyyaml()
                if not re.search(r"^description:\s*\S", frontmatter, re.MULTILINE):
                    fail(f"{plugin}/{command} command wrapper missing description")
                continue
            try:
                parsed = yaml.safe_load(frontmatter)
            except yaml.YAMLError as exc:
                first = str(exc).splitlines()[0]
                fail(f"{plugin}/{command} command frontmatter is not valid YAML: {first}")
            if not isinstance(parsed, dict) or parsed.get("description") is None:
                fail(f"{plugin}/{command} command frontmatter missing description")

        for skill in skills:
            if skill in seen:
                fail(f"duplicate skill name: {skill}")
            seen.add(skill)

            text = (skills_dir / skill / "SKILL.md").read_text()
            match = re.search(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
            if not match:
                fail(f"{plugin}/{skill} missing YAML frontmatter")
            frontmatter = match.group(1)

            # Parse the frontmatter as real YAML when pyyaml is available. The
            # regex checks cannot see YAML-invalid content: a plain-scalar
            # description containing ": " parses as a nested mapping and breaks
            # every consumer that loads the skill for real (Claude Code rejects
            # the skill at load). One such description shipped in 5.16.0 and
            # survived four green releases because nothing parsed it.
            if yaml is None:
                _warn_no_pyyaml()
                name = re.search(r"^name:\s*(.+)$", frontmatter, re.MULTILINE)
                description = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
                check_name_description(
                    plugin,
                    skill,
                    name.group(1).strip() if name else None,
                    description.group(1).strip() if description else None,
                )
            else:
                parsed = None
                try:
                    parsed = yaml.safe_load(frontmatter)
                except yaml.YAMLError as exc:
                    first = str(exc).splitlines()[0]
                    fail(f"{plugin}/{skill} frontmatter is not valid YAML: {first}")
                if parsed is None:
                    parsed = {}
                if not isinstance(parsed, dict):
                    fail(f"{plugin}/{skill} frontmatter must be a mapping, got {type(parsed).__name__}")
                check_name_description(
                    plugin, skill, parsed.get("name"), parsed.get("description")
                )

    readme = (ROOT / "README.md").read_text()
    for plugin, count in counts.items():
        if f"`{plugin}` | {count} |" not in readme:
            fail(f"README skill count missing or stale for {plugin} (expected {count})")

    validate_readme_tree(readme, counts)


def plugin_structure_tree(readme: str) -> str:
    """The fenced code block under '## Plugin Structure'.

    Scoped deliberately: an earlier version searched the whole README, which
    made unrelated prose ("Archived /tmp/srepowers-core/ ← 39 skills") satisfy
    the check, and made a stale historical line *anywhere above* the real tree
    false-fail it, because `re.search` returns the first match in the file. A
    validator that can be satisfied by prose it does not mean, or refuse a
    correct README, is worse than no validator.
    """
    # `\Z` so the section may be the last one in the file — requiring a
    # following `## ` heading false-failed an otherwise-valid README whose
    # Plugin Structure section sat at EOF.
    section = re.search(
        r"^## Plugin Structure\s*$(.*?)(?:^## |\Z)", readme, re.MULTILINE | re.DOTALL
    )
    if not section:
        fail("README is missing its '## Plugin Structure' section")
    fence = re.search(r"^```\n(.*?)^```", section.group(1), re.MULTILINE | re.DOTALL)
    if not fence:
        fail("README '## Plugin Structure' section has no fenced tree block")
    return fence.group(1)


def validate_readme_tree(readme: str, counts: dict[str, int]) -> None:
    """The README's ASCII tree and mirror counts must match disk too.

    The plugin *table* has been asserted since early on; the *tree* right
    beside it renders the same numbers and was checked by nobody. By 5.16.0 it
    had drifted three ways at once — core said 34 against 39 on disk, swe said
    12 against 16, and the mirror line said 83 against 93 — through several
    green CI runs, because a reader assumes a validated table implies a
    validated diagram.
    """
    tree = plugin_structure_tree(readme)

    # Reject a row for a plugin that is not on disk. Checking only that each
    # expected plugin has a row leaves a removed one advertised forever: a
    # `srepowers-legacy/ ← 99 skills` row passed while naming nothing real.
    advertised = set(
        re.findall(
            r"^[│─├└\s]*(?:├──|└──)\s*(srepowers-[a-z-]+)/\s*←\s*\d+ skills?\b",
            tree,
            re.MULTILINE,
        )
    )
    phantom = sorted(advertised - set(counts))
    if phantom:
        fail(
            f"README tree advertises plugin(s) not on disk: {', '.join(phantom)}"
        )

    for plugin, count in counts.items():
        # A real tree row: `│   ├── srepowers-core/   ← 39 skills`. Anchor on the
        # box-drawing prefix so only the diagram's own rows can match, and
        # require exactly one so a duplicated or stale row is an error rather
        # than a coin flip over which one `search` happened to find first.
        matches = re.findall(
            rf"^[│─├└\s]*(?:├──|└──)\s*{re.escape(plugin)}/\s*←\s*(\d+) skills?\b",
            tree,
            re.MULTILINE,
        )
        if not matches:
            fail(f"README tree missing a '← N skills' row for {plugin}")
        if len(matches) > 1:
            fail(
                f"README tree has {len(matches)} '← N skills' rows for {plugin}; "
                "exactly one is expected"
            )
        if int(matches[0]) != count:
            fail(
                f"README tree count stale for {plugin}: "
                f"says {matches[0]}, disk has {count}"
            )

    # `├── .agents/skills/   ← Codex skill mirror (93 symlinks)`. The value is a
    # symlink count, so count symlinks — comparing it to the skill total would
    # pass a mirror built entirely from regular directories.
    mirror_links = sorted(
        path.name
        for path in (ROOT / ".agents" / "skills").iterdir()
        if path.is_symlink()
    )
    matches = re.findall(
        r"^[│─├└\s]*(?:├──|└──)\s*\.agents/skills/\s*←\s*Codex skill mirror "
        r"\((\d+) symlinks\)",
        tree,
        re.MULTILINE,
    )
    if not matches:
        fail("README tree missing the '.agents/skills/ ← Codex skill mirror (N symlinks)' row")
    if len(matches) > 1:
        fail(f"README tree has {len(matches)} mirror rows; exactly one is expected")
    if int(matches[0]) != len(mirror_links):
        fail(
            f"README mirror count stale: says {matches[0]}, "
            f".agents/skills holds {len(mirror_links)} symlinks"
        )


def validate_catalog() -> None:
    """The skill catalog must name every skill on disk, and only those.

    `using-srepowers` loads this file to route work, so a missing row makes a
    skill effectively invisible and a stale row advertises one that does not
    exist. Nothing checked it until 5.13.1: a row naming a nonexistent skill
    was inserted deliberately and the validator passed. Both header counts and
    row membership drifted in practice — core read "33 skills" while carrying
    34 — so both are asserted here.
    """
    catalog = (
        ROOT / "plugins" / "srepowers-core" / "skills" / "using-srepowers"
        / "references" / "skill-catalog.md"
    )
    if not catalog.exists():
        fail("skill-catalog.md is missing")

    text = catalog.read_text()
    rel = catalog.relative_to(ROOT)

    # Rows look like: | `srepowers-core:some-skill` | Use when … |
    listed: dict[str, set[str]] = {plugin: set() for plugin in PLUGINS}
    for plugin, skill in re.findall(
        r"^\|\s*`(srepowers-[a-z]+):([a-z0-9-]+)`", text, re.MULTILINE
    ):
        if plugin not in listed:
            fail(f"{rel} references unknown plugin: {plugin}")
        if skill in listed[plugin]:
            fail(f"{rel} lists {plugin}:{skill} more than once")
        listed[plugin].add(skill)

    # Table shape: within each |-delimited block, every row must carry the
    # same cell count as its header. A trailing empty cell (`| … | |`)
    # renders as a phantom column and is invisible to the row regex above,
    # which never looks past the skill name — the defect that slipped
    # through 5.21.0 review. (A `\|` inside a cell would inflate the count;
    # the catalog carries none, grep-verified.)
    lines = text.splitlines()
    start = 0
    while start < len(lines):
        if not lines[start].lstrip().startswith("|"):
            start += 1
            continue
        end = start
        while end < len(lines) and lines[end].lstrip().startswith("|"):
            end += 1
        width = len(lines[start].split("|")) - 2
        for lineno in range(start + 1, end):
            cells = len(lines[lineno].split("|")) - 2
            if cells != width:
                fail(f"{rel}:{lineno + 1} table row has {cells} cells, "
                     f"its header has {width} — malformed table row")
        start = end

    for plugin in PLUGINS:
        actual = {
            path.parent.name
            for path in (ROOT / "plugins" / plugin / "skills").glob("*/SKILL.md")
        }
        missing = sorted(actual - listed[plugin])
        if missing:
            fail(f"{rel} missing rows for {plugin}: {', '.join(missing)}")
        extra = sorted(listed[plugin] - actual)
        if extra:
            fail(f"{rel} lists nonexistent {plugin} skills: {', '.join(extra)}")

        # Header counts drift silently; assert them against disk too.
        header = re.search(
            rf"^## Plugin: {re.escape(plugin)} \((\d+) skills?\)$",
            text,
            re.MULTILINE,
        )
        if not header:
            fail(f"{rel} missing '## Plugin: {plugin} (N skills)' header")
        if int(header.group(1)) != len(actual):
            fail(
                f"{rel} header count stale for {plugin}: "
                f"says {header.group(1)}, disk has {len(actual)}"
            )


def validate_mirrors() -> None:
    # skill name -> the one canonical SKILL.md dir it must resolve to
    canonical_paths = {
        path.parent.name: path.parent.resolve()
        for plugin in PLUGINS
        for path in (ROOT / "plugins" / plugin / "skills").glob("*/SKILL.md")
    }
    canonical = sorted(canonical_paths)

    for mirror in (ROOT / ".agents" / "skills", ROOT / ".codex" / "skills"):
        entries = sorted(mirror.iterdir(), key=lambda p: p.name)
        mirrored = sorted(path.name for path in entries if path.is_dir() or path.is_symlink())
        if mirrored != canonical:
            fail(f"{mirror.relative_to(ROOT)} does not match canonical plugin skills")

        # Every entry must be a symlink, not a copy. `is_dir()` alone accepted a
        # mirror rebuilt from regular directories — which passes the name check
        # while silently forking the content away from plugins/, so an edit to a
        # skill would stop reaching Codex with nothing failing.
        not_links = [path.name for path in entries if not path.is_symlink()]
        if not_links:
            fail(
                f"{mirror.relative_to(ROOT)} entries must be symlinks into plugins/, "
                f"found regular paths: {', '.join(not_links)}"
            )
        broken = [path.name for path in entries if path.is_symlink() and not path.exists()]
        if broken:
            fail(f"{mirror.relative_to(ROOT)} has broken symlinks: {', '.join(broken)}")

        # ...and each must resolve to *its own* skill. A link that is present,
        # is a symlink, and resolves somewhere still passes every check above
        # while pointing at the wrong skill — so `ponytail` could serve
        # `ponytail-review`'s instructions to Codex with nothing failing. The
        # name and the target are independent facts; assert both.
        for path in entries:
            expected = canonical_paths[path.name]
            actual = path.resolve()
            if actual != expected:
                fail(
                    f"{mirror.relative_to(ROOT)}/{path.name} points at "
                    f"{actual} but must point at {expected}"
                )


def validate_claude_tests() -> None:
    obsolete = []
    for path in sorted((ROOT / "tests" / "claude-code").glob("test-*.sh")):
        text = path.read_text()
        if "$REPO_ROOT/skills/" in text or "$REPO_ROOT/commands/" in text:
            obsolete.append(str(path.relative_to(ROOT)))
    if obsolete:
        fail(f"Claude tests reference obsolete root paths: {', '.join(obsolete)}")


def _load_leak_patterns(publish: bool = False) -> tuple[list[tuple[str, str]], str | None]:
    """Read site-leak patterns from an untracked local file.

    The patterns ARE the site's own names, so they must never live in this
    tracked file: committing them would make the gate itself the leak. The
    pattern file is gitignored and local-only; this script ships knowing only
    the placeholder shapes that srepowers-private is contracted to use.

    Format: one `regex<TAB>label` per line, `#` comments and blanks ignored.
    Returns (patterns, warning, site_count) — a warning instead of a hard
    fail in default mode, because a contributor without the file must still
    be able to validate the repo. Publish mode hard-fails on the missing
    file AND on zero site patterns: a file that exists but carries only
    comments degrades the gate to the placeholder contract while reading
    as provisioned — a green lie.
    """
    spec = ROOT / ".leakpatterns"
    shipped = [
        # Placeholder contract: srepowers-private ships these, never real values.
        # A real value replacing a placeholder is the defect this catches.
        (r"<puppet-master>\.[a-z]", "placeholder given a real domain suffix"),
        (r"\bsite-[ab]-[a-z0-9]+\.[a-z]{2,}", "site-a/site-b given a real domain"),
        (r"<TICKET-ID>-\d", "ticket placeholder given a real number"),
    ]
    if not spec.exists():
        if publish:
            fail(
                f"{spec.name} absent — publication mode refuses to run without it. "
                "CI green proves only the placeholder contract, never that real "
                "site hostnames/domains/paths are absent"
            )
        return shipped, (
            f"{spec.name} absent — leak scan covers placeholder contract only, "
            "NOT site hostnames/paths/domains (create it locally; it is gitignored)"
        ), 0
    patterns = list(shipped)
    site_count = 0
    for raw in spec.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        regex, _, label = line.partition("\t")
        patterns.append((regex.strip(), label.strip() or "site token"))
        site_count += 1
    return patterns, None, site_count


def validate_no_leaks(publish: bool = False) -> None:
    """Fail if a skill ships a site hostname, path, domain, or ticket ID.

    Scans the WHOLE skill directory — bundled references and scripts, not just
    SKILL.md — because that is where leaks have actually been found. Publish
    mode scans the STAGED BLOBS (index content, exactly what git commit will
    ship), never the working tree: a staged file whose working-tree copy was
    sanitized afterwards must not read as clean.
    """
    patterns, warning, site_count = _load_leak_patterns(publish=publish)
    if warning:
        print(f"WARNING: {warning}", file=sys.stderr)
    if publish and site_count == 0:
        fail(
            ".leakpatterns exists but carries zero site patterns (empty or "
            "comment-only) — publication mode refuses a placeholder-only scan"
        )

    site_compiled = []
    edition_compiled = []
    for regex, label in patterns:
        try:
            site_compiled.append((re.compile(regex, re.IGNORECASE), label))
        except re.error as exc:
            fail(f".leakpatterns has an invalid regex {regex!r}: {exc}")
    if publish:
        edition_compiled = []
        for regex, label in _load_edition_patterns():
            try:
                edition_compiled.append((re.compile(regex, re.IGNORECASE), label))
            except re.error as exc:
                fail(f".editionpatterns has an invalid regex {regex!r}: {exc}")
    else:
        edition_compiled = []

    findings: list[str] = []
    scanned = 0
    payload: list[tuple[str, str]] = []  # (path relative to ROOT, text)
    skipped_symlinks = 0
    skipped_binary = 0
    if publish:
        # Publication mode scans the COMPLETE release payload as the INDEX
        # blobs git will commit — not the working tree. Root files (README,
        # CONTRIBUTING, LICENSE, AGENTS), hidden packaging/config dirs
        # (.claude-plugin, .github, .codex), and extensionless hook scripts
        # all ship in a public edition; untracked working-dir files (.pi/
        # session transcripts, .claude/ local state, the pattern file itself)
        # are not payload and are excluded by construction. Reading blobs via
        # `git cat-file --batch` makes the scan index-exact: working-tree
        # drift after `git add` can neither mask staged content nor matter.
        # This requires an initialized, populated git repo: the staging
        # sequence is git init -> add payload -> validate -> commit -> tag.
        try:
            listed = subprocess.run(
                ["git", "ls-files", "-s", "-z"], cwd=ROOT, capture_output=True, check=True
            ).stdout
        except subprocess.CalledProcessError:
            fail(
                "publication mode needs a populated git repository (git ls-files "
                "failed) — staging sequence: git init, add payload, then validate"
            )
        entries: list[tuple[str, str]] = []  # (blob sha, path)
        # Record format with -z is `<mode> <sha> <stage>\t<path>` NUL-separated:
        # the NUL replaces the record terminator, the internal TAB stays.
        for field in listed.split(b"\0"):
            if not field:
                continue
            meta, _, path_b = field.partition(b"\t")
            mode, sha, stage = meta.decode().split(" ")
            path = path_b.decode()
            if stage != "0":
                # Defense-in-depth: stage 0 is the only valid payload entry;
                # stages 1-3 are unmerged conflict paths — never a release.
                fail(f"unmerged index entry in payload: {path} (stage {stage}) — resolve before validating")
            if mode == "120000":
                # Release policy: symlinks ship as references; their targets
                # are scanned as the regular files they are. Counted and
                # reported, never silently dropped.
                skipped_symlinks += 1
                continue
            if mode == "160000":
                fail(f"submodule (gitlink) in payload: {path} — unsupported by the publication gate")
            entries.append((sha, path))
        cat = subprocess.Popen(
            ["git", "cat-file", "--batch"], cwd=ROOT,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        )
        assert cat.stdin is not None and cat.stdout is not None
        try:
            for sha, path in entries:
                cat.stdin.write(sha.encode() + b"\n")
                cat.stdin.flush()
                header = cat.stdout.readline().decode()
                parts = header.split()
                if len(parts) != 3 or parts[1] != "blob":
                    fail(f"staged blob unreadable for {path}: {header.strip()}")
                size = int(parts[2])
                data = cat.stdout.read(size)
                cat.stdout.read(1)  # trailing LF after each blob
                if b"\0" in data[:8192]:
                    # Release policy: binary blobs skipped, counted, reported.
                    skipped_binary += 1
                    continue
                payload.append((path, data.decode("utf-8", errors="replace")))
        finally:
            cat.kill()
            cat.wait()
    else:
        # Default mode: scan every tracked authored tree, not just skills. A
        # skills-only scope shipped a site path in tests/verify-skills.md and
        # read as a clean pass: the gate's blind spot, not the tree's.
        # RELEASE-NOTES.md is excluded by design — it records upstream skill
        # NAMES in refusal entries, and rewriting those would falsify the
        # audit trail.
        roots = [ROOT / "plugins", ROOT / "tests", ROOT / "docs", ROOT / "scripts"]
        for root in roots:
            if not root.is_dir():
                continue
            for path in sorted(root.rglob("*")):
                if path.is_symlink() or not path.is_file():
                    continue
                if path.suffix not in {".md", ".py", ".sh", ".yaml", ".yml", ".json"}:
                    continue
                try:
                    payload.append(
                        (str(path.relative_to(ROOT)), path.read_text(encoding="utf-8", errors="replace"))
                    )
                except OSError as exc:  # pragma: no cover - unreadable file
                    fail(f"cannot read {path.relative_to(ROOT)}: {exc}")
                    raise AssertionError("unreachable")  # fail() raises; satisfies type narrowing
    for rel, text in payload:
        scanned += 1
        for lineno, line in enumerate(text.splitlines(), 1):
            for rx, label in site_compiled + edition_compiled:
                if rx.search(line):
                    findings.append(f"{rel}:{lineno} ({label})")
                    break

    # Print the denominator: "0 findings out of 0 scanned" must never read as a pass.
    if scanned == 0:
        if publish:
            fail("publication scan examined zero staged files — staging sequence is git init, add payload, then validate")
        fail("leak scan examined zero files — skills layout changed?")
    if findings:
        joined = "\n  ".join(findings[:40])
        more = f"\n  ... and {len(findings) - 40} more" if len(findings) > 40 else ""
        skips = (
            f" ({skipped_symlinks} symlink refs, {skipped_binary} binary blobs skipped)"
            if publish
            else ""
        )
        fail(
            f"site data in {len(findings)} location(s) across {scanned} files "
            f"scanned{skips}:\n  {joined}{more}"
        )
    if publish:
        print(
            f"[ok] publication leak scan: {scanned} staged payload files "
            f"({skipped_symlinks} symlink refs, {skipped_binary} binary blobs skipped), "
            f"{site_count} site + {len(edition_compiled)} edition patterns, no site data"
        )
    else:
        print(f"[ok] leak scan: {scanned} skill files, no site data")


def validate_release_tags() -> None:
    """Every released version in RELEASE-NOTES.md must have its git tag.

    The release cycle is: merge PR -> annotated tag vX.Y.Z at the merge commit
    -> GitHub Release. v5.25.0 and v5.25.1 shipped without their tags (caught
    2026-10-07 while backfilling, two releases late, because nothing failed
    when the tag step was skipped. This gate makes the skip loud: the NEXT
    release's CI goes red while the previous one is still untagged.

    The highest version is exempt - it is the release in flight; its tag
    lands after merge, so requiring it here would fail every version-bump
    PR at CI time (tags never exist pre-merge). Exempting by max version
    rather than by file position keeps the rule correct even if section
    order drifts from the "Newest first." convention.

    Tags are read from the local clone; CI gets them via fetch-depth: 0 on
    the checkout step (.github/workflows/validate.yml). A stale local clone
    can false-fail - run `git fetch --tags origin` first.
    """
    notes = ROOT / "RELEASE-NOTES.md"
    if not notes.exists():
        fail("RELEASE-NOTES.md is missing")

    versions = re.findall(r"^## (\d+\.\d+\.\d+)", notes.read_text(), re.MULTILINE)
    if not versions:
        fail("RELEASE-NOTES.md contains no '## X.Y.Z' release sections")

    def ver_key(v: str) -> tuple[int, int, int]:
        return tuple(int(p) for p in v.split("."))  # type: ignore[return-value]

    in_flight = max(versions, key=ver_key)
    prior = [v for v in versions if v != in_flight]

    listed = subprocess.run(
        ["git", "tag", "-l"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout.split()
    existing = set(listed)

    missing = [v for v in prior if f"v{v}" not in existing]
    if missing:
        fail(
            f"RELEASE-NOTES names {len(missing)} release(s) with no git tag: "
            f"{', '.join('v' + v for v in sorted(missing, key=ver_key))}. "
            "The tag step of the release cycle was skipped - create the "
            "annotated tag at that release's merge commit. (If this is a "
            "local run on a stale clone: `git fetch --tags origin` first.)"
        )
    print(
        f"[ok] release tags: {len(prior)} prior release(s) all tagged, "
        f"{in_flight} in flight"
    )


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
    parser.add_argument(
        "--publish",
        action="store_true",
        help="pre-release gate: hard-require the local (gitignored) "
        ".leakpatterns file, so the leak scan covers real site tokens, "
        "not just the placeholder contract",
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
    validate_catalog()
    validate_mirrors()
    validate_claude_tests()
    validate_no_leaks(publish=args.publish)
    validate_release_tags()
    print("[PASS] repository metadata, skills, commands, versions, catalog, and mirrors are valid")


if __name__ == "__main__":
    main()


