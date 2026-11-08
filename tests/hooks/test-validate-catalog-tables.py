#!/usr/bin/env python3
"""Tests for validate-repo.py's catalog table-shape assertion.

Locks in the case PR #36 review found (F2): a row with a trailing empty
cell (`| … | |`) renders as a phantom third column, but the catalog's row
regex only ever looks at the leading `srepowers-<plugin>:<skill>` cell, so
membership and header-count checks passed over it. The shape check compares
every row's cell count against its table header.

Run: python3 tests/hooks/test-validate-catalog-tables.py
"""

from __future__ import annotations

import importlib.util
import shutil
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
    mod.PLUGINS = ("srepowers-core",)
    return mod


class ScratchCatalog:
    """A minimal repo: one plugin, two skills, a well-formed catalog."""

    GOOD = (
        "# Available Skills\n\n"
        "## Plugin: srepowers-core (2 skills)\n\n"
        "SRE workflow spine.\n\n"
        "| Skill | Description |\n"
        "|-------|-------------|\n"
        "| `srepowers-core:alpha` | Alpha skill |\n"
        "| `srepowers-core:using-srepowers` | Meta-skill |\n"
    )

    def __enter__(self):
        self.dir = Path(tempfile.mkdtemp(prefix="vrtest_"))
        for skill in ("alpha", "using-srepowers"):
            sk = self.dir / "plugins" / "srepowers-core" / "skills" / skill
            sk.mkdir(parents=True)
            (sk / "SKILL.md").write_text(
                f"---\nname: {skill}\ndescription: d\n---\n")
        self.catalog = (
            self.dir / "plugins" / "srepowers-core" / "skills"
            / "using-srepowers" / "references" / "skill-catalog.md")
        self.catalog.parent.mkdir(parents=True, exist_ok=True)
        self.catalog.write_text(self.GOOD)
        return self

    def __exit__(self, *exc):
        shutil.rmtree(self.dir, ignore_errors=True)

    def check(self) -> tuple[bool, str]:
        """Run validate_catalog on the scratch tree. (passed, message)."""
        mod = load_validator(self.dir)
        try:
            mod.validate_catalog()
        except SystemExit as exc:
            return False, str(exc)
        return True, ""


class TestCatalogTableShape(unittest.TestCase):
    def test_well_formed_catalog_passes(self):
        with ScratchCatalog() as c:
            passed, msg = c.check()
            self.assertTrue(passed, f"valid catalog must pass, got: {msg}")

    def test_trailing_empty_cell_fails(self):
        # The F2 defect class: phantom third column invisible to the
        # row-membership regex.
        with ScratchCatalog() as c:
            c.catalog.write_text(c.GOOD.replace(
                "| `srepowers-core:alpha` | Alpha skill |",
                "| `srepowers-core:alpha` | Alpha skill | |"))
            passed, msg = c.check()
            self.assertFalse(passed, "trailing empty cell must fail")
            self.assertIn("table row", msg)

    def test_row_missing_trailing_pipe_fails(self):
        # Deliberate policy: catalog rows are consistently |-delimited;
        # a row without its trailing pipe miscounts and is flagged rather
        # than silently rendered with an implicit empty cell.
        with ScratchCatalog() as c:
            c.catalog.write_text(c.GOOD.replace(
                "| `srepowers-core:alpha` | Alpha skill |",
                "| `srepowers-core:alpha` | Alpha skill"))
            passed, msg = c.check()
            self.assertFalse(passed, "unpiped row must fail")
            self.assertIn("table row", msg)


if __name__ == "__main__":
    unittest.main()
