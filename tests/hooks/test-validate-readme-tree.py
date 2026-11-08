#!/usr/bin/env python3
"""Tests for validate-repo.py's README tree / mirror assertions.

These lock in the cases a review found the first implementation got wrong:
it searched the whole README (so unrelated prose satisfied it, and a stale
line above the real tree false-failed it), and its "symlink count" was
compared to the skill total rather than to actual symlinks (so a mirror of
plain directories validated).

Run: python3 tests/hooks/test-validate-readme-tree.py
"""

from __future__ import annotations

import importlib.util
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
VALIDATOR = REPO / "scripts" / "validate-repo.py"


def load_validator(root: Path):
    """Import validate-repo.py with its ROOT pointed at a scratch tree."""
    spec = importlib.util.spec_from_file_location(f"vr_{root.name}", VALIDATOR)
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    mod.ROOT = root
    return mod


class ScratchRepo:
    """A minimal repo: 2 plugins, 1 skill each, both mirrors, a README tree."""

    def __enter__(self):
        self.dir = Path(tempfile.mkdtemp(prefix="vrtest_"))
        for plugin, skill in (("srepowers-core", "alpha"), ("srepowers-swe", "beta")):
            sk = self.dir / "plugins" / plugin / "skills" / skill
            sk.mkdir(parents=True)
            (sk / "SKILL.md").write_text(f"---\nname: {skill}\ndescription: d\n---\n")
            for mirror in (".agents/skills", ".codex/skills"):
                m = self.dir / mirror
                m.mkdir(parents=True, exist_ok=True)
                (m / skill).symlink_to(f"../../plugins/{plugin}/skills/{skill}")
        self.write_readme(core=1, swe=1, symlinks=2)
        return self

    def __exit__(self, *exc):
        shutil.rmtree(self.dir, ignore_errors=True)

    def write_readme(self, core: int, swe: int, symlinks: int, extra: str = "") -> None:
        (self.dir / "README.md").write_text(
            "# Scratch\n\n"
            "## Plugin Structure\n\n"
            f"{extra}"
            "```\n"
            "scratch/\n"
            "├── plugins/\n"
            f"│   ├── srepowers-core/                 ← {core} skills\n"
            f"│   └── srepowers-swe/                  ← {swe} skills\n"
            f"├── .agents/skills/                     ← Codex skill mirror ({symlinks} symlinks)\n"
            "└── README.md\n"
            "```\n\n"
            "## Next Section\n\nprose\n"
        )

    def check(self) -> tuple[bool, str]:
        """Run validate_readme_tree + validate_mirrors. (passed, message)."""
        mod = load_validator(self.dir)
        counts = {"srepowers-core": 1, "srepowers-swe": 1}
        readme = (self.dir / "README.md").read_text()
        try:
            mod.validate_readme_tree(readme, counts)
            mod.PLUGINS = ("srepowers-core", "srepowers-swe")
            mod.validate_mirrors()
        except SystemExit as exc:
            return False, str(exc)
        return True, ""


class TestTreeCounts(unittest.TestCase):
    def test_correct_readme_passes(self):
        with ScratchRepo() as r:
            passed, msg = r.check()
            self.assertTrue(passed, f"correct README must pass, got: {msg}")

    def test_stale_count_fails(self):
        with ScratchRepo() as r:
            r.write_readme(core=9, swe=1, symlinks=2)
            passed, msg = r.check()
            self.assertFalse(passed)
            self.assertIn("stale", msg)

    def test_missing_row_fails(self):
        with ScratchRepo() as r:
            text = (r.dir / "README.md").read_text()
            text = re.sub(r"^.*srepowers-swe/.*\n", "", text, flags=re.MULTILINE)
            (r.dir / "README.md").write_text(text)
            passed, msg = r.check()
            self.assertFalse(passed)
            self.assertIn("missing", msg)


class TestTreeScoping(unittest.TestCase):
    """The check must read the Plugin Structure tree, not the whole file."""

    def test_prose_lookalikes_do_not_satisfy_it(self):
        # Real rows deleted; unrelated prose elsewhere carries the right numbers.
        with ScratchRepo() as r:
            (r.dir / "README.md").write_text(
                "# Scratch\n\n## Plugin Structure\n\n```\nscratch/\n└── README.md\n```\n\n"
                "## Archived\n\n"
                "Archived /tmp/srepowers-core/ ← 1 skills\n"
                "Archived /tmp/srepowers-swe/ ← 1 skills\n"
                "Historically the ← Codex skill mirror (2 symlinks) lived elsewhere.\n"
            )
            passed, msg = r.check()
            self.assertFalse(passed, "prose outside the tree must not satisfy the check")

    def test_stale_line_above_the_tree_does_not_false_fail(self):
        # A correct tree preceded by a historical mention must still pass.
        with ScratchRepo() as r:
            r.write_readme(
                core=1, swe=1, symlinks=2,
                extra="Historically: srepowers-core/ ← 34 skills\n\n",
            )
            passed, msg = r.check()
            self.assertTrue(
                passed, f"a correct tree must pass despite nearby prose, got: {msg}"
            )

    def test_phantom_plugin_row_fails(self):
        # A row naming a plugin that is not on disk must not survive: checking
        # only that each *expected* plugin has a row leaves a removed plugin
        # advertised forever.
        with ScratchRepo() as r:
            text = (r.dir / "README.md").read_text().replace(
                "│   └── srepowers-swe/",
                "│   ├── srepowers-legacy/               ← 99 skills\n"
                "│   └── srepowers-swe/",
                1,
            )
            (r.dir / "README.md").write_text(text)
            passed, msg = r.check()
            self.assertFalse(passed, "a row for a nonexistent plugin must fail")
            self.assertIn("not on disk", msg)

    def test_section_at_end_of_file_passes(self):
        # Requiring a following '## ' heading false-failed a valid README whose
        # Plugin Structure section happened to be last.
        with ScratchRepo() as r:
            text = (r.dir / "README.md").read_text()
            text = text.replace("## Next Section\n\nprose\n", "")
            (r.dir / "README.md").write_text(text.rstrip() + "\n")
            passed, msg = r.check()
            self.assertTrue(
                passed, f"a section at EOF must still be found, got: {msg}"
            )

    def test_duplicate_row_fails(self):
        with ScratchRepo() as r:
            text = (r.dir / "README.md").read_text().replace(
                "│   └── srepowers-swe/                  ← 1 skills\n",
                "│   ├── srepowers-swe/                  ← 1 skills\n"
                "│   └── srepowers-swe/                  ← 1 skills\n",
            )
            (r.dir / "README.md").write_text(text)
            passed, msg = r.check()
            self.assertFalse(passed)
            self.assertIn("exactly one", msg)


class TestMirrorSymlinks(unittest.TestCase):
    """A 'symlink count' must count symlinks, and mirrors must be symlinks."""

    def test_plain_directory_mirror_fails(self):
        with ScratchRepo() as r:
            for mirror in (".agents/skills", ".codex/skills"):
                for entry in list((r.dir / mirror).iterdir()):
                    entry.unlink()
                    entry.mkdir()
                    (entry / "SKILL.md").write_text("copy\n")
            # Claim 0 symlinks so validate_readme_tree's count check passes and
            # the failure must come from validate_mirrors' not_links branch.
            # With the README still claiming 2, this test passed on the count
            # check alone and never exercised the branch it names.
            r.write_readme(core=1, swe=1, symlinks=0)
            passed, msg = r.check()
            self.assertFalse(passed, "a mirror of regular dirs must not validate")
            self.assertIn("must be symlinks", msg)

    def test_symlink_pointing_at_wrong_skill_fails(self):
        # Present, a symlink, and resolves — but to the *other* skill. Codex
        # would serve beta's instructions under alpha with nothing failing.
        with ScratchRepo() as r:
            for mirror in (".agents/skills", ".codex/skills"):
                link = r.dir / mirror / "alpha"
                link.unlink()
                link.symlink_to("../../plugins/srepowers-swe/skills/beta")
            passed, msg = r.check()
            self.assertFalse(passed, "a wrong-target symlink must not validate")
            self.assertIn("must point at", msg)

    def test_mirror_count_compared_to_symlinks(self):
        # 2 symlinks on disk, README claims 5 — must fail even though the
        # skill total is unrelated to the claimed number.
        with ScratchRepo() as r:
            r.write_readme(core=1, swe=1, symlinks=5)
            passed, msg = r.check()
            self.assertFalse(passed)
            self.assertIn("mirror count stale", msg)


class TestRealRepo(unittest.TestCase):
    def test_repo_as_committed_passes(self):
        proc = subprocess.run(
            [sys.executable, str(VALIDATOR)], capture_output=True, text=True, cwd=REPO
        )
        self.assertEqual(0, proc.returncode, proc.stdout + proc.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
