#!/usr/bin/env python3
"""Tests for validate-repo.py's YAML frontmatter parsing.

A plain-scalar description containing ": " is invalid YAML (it parses as a
nested mapping), and every real consumer — Claude Code's skill loader — rejects
the skill at load. One such description shipped in 5.16.0 and survived four
green releases because validate-repo checked frontmatter with a regex, which
cannot see YAML-invalid content. These tests pin the parse.

The same defect class shipped again in 5.27.5 — this time in a *command
wrapper* (`pdf-to-md`), which validate_skills() never parsed at all until
5.27.7. The wrapper tests below pin that gate.

Run: python3 tests/hooks/test-validate-frontmatter.py
"""

from __future__ import annotations

import importlib.util
import shutil
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VALIDATOR = REPO / "scripts" / "validate-repo.py"

try:
    import yaml  # noqa: F401

    HAVE_YAML = True
except ImportError:
    HAVE_YAML = False


def load_validator(root: Path):
    spec = importlib.util.spec_from_file_location(f"vr_{root.name}", VALIDATOR)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.ROOT = root
    # validate_skills() chains into the README tree check, which needs a full
    # scratch layout (tree block, mirror symlinks) orthogonal to frontmatter.
    mod.validate_readme_tree = lambda *a, **k: None
    return mod


def scratch_with_description(description_line: str) -> Path:
    """Minimal repo: one plugin, one skill, frontmatter as given."""
    d = Path(tempfile.mkdtemp(prefix="fmtest_"))
    skill = d / "plugins" / "srepowers-core" / "skills" / "demo"
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        f"---\nname: demo\ndescription: {description_line}\n---\n\nbody\n"
    )
    (d / "plugins" / "srepowers-core" / "commands").mkdir(parents=True)
    (d / "plugins" / "srepowers-core" / "commands" / "demo.md").write_text(
        '---\ndescription: "Demo wrapper."\n---\n\nx\n'
    )
    # validate_skills() ends by reading the README for count assertions
    (d / "README.md").write_text("| `srepowers-core` | 1 | demo |\n")
    return d


class TestFrontmatterParses(unittest.TestCase):
    """The colon-space case that shipped and the shapes that must keep passing."""

    def _run(self, description_line: str) -> None:
        d = scratch_with_description(description_line)
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)

    @unittest.skipUnless(HAVE_YAML, "pyyaml not installed; regex fallback active")
    def test_colon_space_in_description_rejected(self):
        # The exact defect: "diff-scoped: a ranked list" in a plain scalar.
        with self.assertRaises(SystemExit):
            self._run(
                'Audit a repo — like review but repo-wide instead of '
                'diff-scoped: a ranked list of cuts.'
            )

    def test_clean_description_passes(self):
        self._run("Audit a whole repository for over-engineering, ranked biggest cut first.")

    def test_quoted_colon_description_passes(self):
        # A colon is fine when the scalar is quoted — the fix must not force
        # colon-avoidance, only valid YAML.
        self._run('"Use for X: finds bloat, ranks cuts."')

    @unittest.skipUnless(HAVE_YAML, "pyyaml not installed; regex fallback active")
    def test_command_wrapper_invalid_yaml_rejected(self):
        # The 5.27.5 defect: a double-quoted description with unescaped inner
        # quotes. YAML ends the scalar at the first inner quote and the rest
        # becomes "Unexpected scalar at node end" — Claude Code could not
        # load the command at all, on every session start.
        d = scratch_with_description("A clean skill description.")
        (d / "plugins" / "srepowers-core" / "commands" / "demo.md").write_text(
            '---\n'
            'description: "Trigger on phrases like "run this", "do that" now."\n'
            '---\n\nx\n'
        )
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            with self.assertRaises(SystemExit):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)

    def test_command_wrapper_missing_description_rejected(self):
        d = scratch_with_description("A clean skill description.")
        (d / "plugins" / "srepowers-core" / "commands" / "demo.md").write_text(
            "---\nanything: else\n---\n\nx\n"
        )
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            with self.assertRaises(SystemExit):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)

    @unittest.skipUnless(HAVE_YAML, "pyyaml not installed")
    def test_frontmatter_not_a_mapping_rejected(self):
        d = scratch_with_description("whatever")
        (d / "plugins" / "srepowers-core" / "skills" / "demo" / "SKILL.md").write_text(
            "---\n- just\n- a list\n---\n"
        )
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            with self.assertRaises(SystemExit):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)


class TestRegexFallback(unittest.TestCase):
    """The pyyaml-absent branch, executed rather than assumed.

    It shipped with a NameError on first run (sys unimported) because every
    local and CI run had pyyaml — an untested fallback is a fallback that
    does not work.
    """

    def _run_without_pyyaml(self, description_line: str):
        import contextlib
        import io

        d = scratch_with_description(description_line)
        err = io.StringIO()
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            mod.yaml = None  # simulate a pyyaml-free host
            with contextlib.redirect_stderr(err):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)
        return err.getvalue()

    def test_fallback_runs_clean_and_warns(self):
        stderr = self._run_without_pyyaml("A clean description with no colons.")
        self.assertIn("WARNING: pyyaml absent", stderr)
        self.assertIn("regex only", stderr)

    def test_fallback_still_catches_missing_description(self):
        d = scratch_with_description("x")
        (d / "plugins" / "srepowers-core" / "skills" / "demo" / "SKILL.md").write_text(
            "---\nname: demo\n---\n"
        )
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            mod.yaml = None
            with self.assertRaises(SystemExit):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)

    def test_warning_prints_once_not_per_skill(self):
        d = Path(tempfile.mkdtemp(prefix="fmtest_multi_"))
        for name in ("alpha", "beta"):
            s = d / "plugins" / "srepowers-core" / "skills" / name
            s.mkdir(parents=True)
            (s / "SKILL.md").write_text(
                f"---\nname: {name}\ndescription: d\n---\n"
            )
            cmd = d / "plugins" / "srepowers-core" / "commands"
            cmd.mkdir(parents=True, exist_ok=True)
            (cmd / f"{name}.md").write_text(
                f'---\ndescription: "{name} wrapper."\n---\n\nx\n'
            )
        (d / "README.md").write_text("| `srepowers-core` | 2 | two |\n")
        import contextlib
        import io

        err = io.StringIO()
        try:
            mod = load_validator(d)
            mod.PLUGINS = ("srepowers-core",)
            mod.yaml = None
            with contextlib.redirect_stderr(err):
                mod.validate_skills()
        finally:
            shutil.rmtree(d, ignore_errors=True)
        self.assertEqual(1, err.getvalue().count("WARNING: pyyaml absent"))


class TestRealRepo(unittest.TestCase):
    def test_repo_as_committed_passes(self):
        import subprocess
        import sys

        proc = subprocess.run(
            [sys.executable, str(VALIDATOR)], capture_output=True, text=True, cwd=REPO
        )
        self.assertEqual(0, proc.returncode, proc.stdout + proc.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
