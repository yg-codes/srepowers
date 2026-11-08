"""Tests for memory_lint.py — run: PYTHONDONTWRITEBYTECODE=1 python3 -B test_memory_lint.py"""

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from memory_lint import lint_store

SCRIPT = str(Path(__file__).parent / "memory_lint.py")

GOOD = """---
name: good-memory
description: a well-formed memory
metadata:
  type: reference
---

Body text linking [[other-memory]].
"""

OTHER = """---
name: other-memory
description: the link target
metadata:
  type: project
---

Body.
"""


def make_store(files, index_lines):
    d = Path(tempfile.mkdtemp(prefix="memlint_test_"))
    for fname, content in files.items():
        (d / fname).write_text(content)
    if index_lines is not None:
        (d / "MEMORY.md").write_text("# Memory Index\n\n" + "\n".join(index_lines) + "\n")
    return d


def rules(findings):
    return [f.rule for f in findings]


class TestPrefixType(unittest.TestCase):
    def test_prefix_type_mismatch_flagged(self):
        bad = GOOD.replace("type: reference", "type: project").replace("[[other-memory]]", "")
        d = make_store({"reference_a.md": bad}, ["- [A](reference_a.md) — hook"])
        self.assertIn("prefix-type-mismatch", rules(lint_store(d)))

    def test_prefix_type_match_clean(self):
        d = make_store({"reference_a.md": GOOD.replace("[[other-memory]]", "")}, ["- [A](reference_a.md) — hook"])
        self.assertNotIn("prefix-type-mismatch", rules(lint_store(d)))

    def test_no_prefix_not_flagged(self):
        d = make_store({"notes.md": GOOD.replace("[[other-memory]]", "")}, ["- [A](notes.md) — hook"])
        self.assertNotIn("prefix-type-mismatch", rules(lint_store(d)))


class TestFrontmatter(unittest.TestCase):
    def test_clean_store(self):
        d = make_store(
            {"a.md": GOOD, "b.md": OTHER},
            ["- [Good](a.md) — hook", "- [Other](b.md) — hook"],
        )
        self.assertEqual([], lint_store(d))

    def test_missing_frontmatter(self):
        d = make_store({"a.md": "just text, no frontmatter\n"}, ["- [A](a.md) — hook"])
        self.assertIn("missing-frontmatter", rules(lint_store(d)))

    def test_missing_type_field(self):
        bad = "---\nname: no-type\ndescription: lacks metadata type\n---\n\nBody.\n"
        d = make_store({"a.md": bad}, ["- [A](a.md) — hook"])
        self.assertIn("missing-field", rules(lint_store(d)))

    def test_bad_type_value(self):
        bad = GOOD.replace("type: reference", "type: banana")
        d = make_store({"a.md": bad}, ["- [A](a.md) — hook"])
        self.assertIn("bad-type", rules(lint_store(d)))

    def test_bad_name_format(self):
        bad = GOOD.replace("name: good-memory", "name: Good_Memory!")
        d = make_store({"a.md": bad}, ["- [A](a.md) — hook"])
        self.assertIn("bad-name-format", rules(lint_store(d)))

    def test_snake_case_name_accepted(self):
        # the store's established convention is snake_case; both separators are fine
        snake = GOOD.replace("name: good-memory", "name: good_memory").replace("[[other-memory]]", "")
        d = make_store({"a.md": snake}, ["- [A](a.md) — hook"])
        self.assertNotIn("bad-name-format", rules(lint_store(d)))

    def test_duplicate_names(self):
        d = make_store(
            {"a.md": GOOD, "b.md": GOOD.replace("[[other-memory]]", "")},
            ["- [A](a.md) — hook", "- [B](b.md) — hook"],
        )
        self.assertIn("duplicate-name", rules(lint_store(d)))

    def test_duplicate_names_across_separator_styles(self):
        # foo-bar and foo_bar resolve the same [[link]], so they are duplicates
        snake = GOOD.replace("name: good-memory", "name: good_memory").replace("[[other-memory]]", "")
        d = make_store(
            {"a.md": GOOD.replace("[[other-memory]]", ""), "b.md": snake},
            ["- [A](a.md) — hook", "- [B](b.md) — hook"],
        )
        self.assertIn("duplicate-name", rules(lint_store(d)))


class TestIndex(unittest.TestCase):
    def test_unindexed_file(self):
        d = make_store({"a.md": GOOD, "b.md": OTHER}, ["- [Good](a.md) — hook"])
        found = rules(lint_store(d))
        self.assertIn("unindexed-file", found)

    def test_dangling_index_entry(self):
        d = make_store(
            {"a.md": GOOD, "b.md": OTHER},
            ["- [Good](a.md) — hook", "- [Other](b.md) — hook", "- [Ghost](ghost.md) — gone"],
        )
        self.assertIn("dangling-index-entry", rules(lint_store(d)))

    def test_missing_index(self):
        d = make_store({"a.md": GOOD.replace("[[other-memory]]", "")}, None)
        self.assertIn("no-index", rules(lint_store(d)))


class TestLinks(unittest.TestCase):
    def test_dangling_link_is_info(self):
        # forward-reference links are sanctioned; must be INFO, not WARN
        d = make_store({"a.md": GOOD}, ["- [Good](a.md) — hook"])
        findings = [f for f in lint_store(d) if f.rule == "dangling-link"]
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].level, "INFO")

    def test_resolved_link_clean(self):
        d = make_store(
            {"a.md": GOOD, "b.md": OTHER},
            ["- [Good](a.md) — hook", "- [Other](b.md) — hook"],
        )
        self.assertNotIn("dangling-link", rules(lint_store(d)))

    def test_posix_bracket_expression_not_a_link(self):
        # rg '[[:space:]]' is regex syntax, not a wiki-link: :space: has no "]"
        # so the naive [[...]] pattern matches it. Measured on a real store:
        # 18 of 20 INFO lines were this false positive.
        body = GOOD + "\n\nUse `rg '[[:space:]]'` and [[:alnum:]] here.\n"
        d = make_store({"a.md": body}, ["- [Good](a.md) — hook"])
        links = [f for f in lint_store(d) if f.rule == "dangling-link"]
        self.assertNotIn("space", " ".join(f.message for f in links))
        self.assertNotIn("alnum", " ".join(f.message for f in links))

    def test_fenced_code_links_ignored(self):
        body = GOOD + "\n\n```bash\ngrep '[[:digit:]]' f && echo [[not-a-memory]]\n```\n"
        d = make_store({"a.md": body}, ["- [Good](a.md) — hook"])
        links = [f for f in lint_store(d) if f.rule == "dangling-link"]
        self.assertNotIn("not-a-memory", " ".join(f.message for f in links))

    def test_link_separator_style_is_equivalent(self):
        # [[other_memory]] must resolve to name `other-memory` — the store mixes - and _
        mixed = GOOD.replace("[[other-memory]]", "[[other_memory]]")
        d = make_store(
            {"a.md": mixed, "b.md": OTHER},
            ["- [Good](a.md) — hook", "- [Other](b.md) — hook"],
        )
        self.assertNotIn("dangling-link", rules(lint_store(d)))


class TestPII(unittest.TestCase):
    def test_email_flagged(self):
        body = GOOD.replace("[[other-memory]]", "").replace(
            "Body text linking .", "Contact jane.doe@notreal-corp.invalid for details."
        )
        d = make_store({"a.md": body}, ["- [A](a.md) — hook"])
        self.assertIn("possible-pii-email", rules(lint_store(d)))

    def test_placeholder_email_domain_not_flagged(self):
        body = GOOD.replace("[[other-memory]]", "").replace(
            "Body text linking .", "Anonymized as userA@example.com in this note."
        )
        d = make_store({"a.md": body}, ["- [A](a.md) — hook"])
        self.assertNotIn("possible-pii-email", rules(lint_store(d)))

    def test_labeled_name_flagged(self):
        body = GOOD.replace("[[other-memory]]", "").replace(
            "Body text linking .", "Contact: Jane Doe\n"
        )
        d = make_store({"a.md": body}, ["- [A](a.md) — hook"])
        self.assertIn("possible-pii-name", rules(lint_store(d)))

    def test_git_style_authorship_flagged(self):
        body = GOOD.replace("[[other-memory]]", "").replace(
            "Body text linking .", "Committed by Jane Doe <jane.doe@notreal-corp.invalid>.\n"
        )
        d = make_store({"a.md": body}, ["- [A](a.md) — hook"])
        found = rules(lint_store(d))
        self.assertIn("possible-pii-name", found)
        self.assertIn("possible-pii-email", found)

    def test_ordinary_capitalized_prose_not_flagged(self):
        body = GOOD.replace("[[other-memory]]", "").replace(
            "Body text linking .", "We reviewed Control Tower and Cloud WAN routing today.\n"
        )
        d = make_store({"a.md": body}, ["- [A](a.md) — hook"])
        self.assertNotIn("possible-pii-name", rules(lint_store(d)))


class TestCLI(unittest.TestCase):
    def test_warn_exit_1_and_clean_exit_0(self):
        bad = make_store({"a.md": "no frontmatter\n"}, ["- [A](a.md) — hook"])
        good = make_store(
            {"a.md": GOOD, "b.md": OTHER},
            ["- [Good](a.md) — hook", "- [Other](b.md) — hook"],
        )
        r_bad = subprocess.run([sys.executable, "-B", SCRIPT, str(bad)], capture_output=True, text=True)
        r_good = subprocess.run([sys.executable, "-B", SCRIPT, str(good)], capture_output=True, text=True)
        self.assertEqual(r_bad.returncode, 1)
        self.assertIn("missing-frontmatter", r_bad.stdout)
        self.assertEqual(r_good.returncode, 0)
        self.assertIn("no findings", r_good.stdout.lower())


class TestIndexPII(unittest.TestCase):
    """M10: MEMORY.md is the most-read file in the store and was exempt."""

    def test_email_in_index_flagged(self):
        d = make_store({"a.md": GOOD}, ["- [Good](a.md) — contact jane.doe@notreal-corp.invalid"])
        hits = [f for f in lint_store(d) if f.rule == "possible-pii-email"]
        self.assertTrue(hits, "MEMORY.md must be PII-scanned — it loads every session")
        self.assertIn("MEMORY.md", hits[0].message)

    def test_labeled_name_in_index_flagged(self):
        # LABELED_NAME_RE anchors the label at line start by design (mid-line
        # labels false-positive on prose), so the leak shape in an index is a
        # trailing owner/contact line rather than an inline aside.
        d = make_store({"a.md": GOOD}, ["- [Good](a.md) — hook", "Owner: Jane Smith"])
        hits = [f for f in lint_store(d) if f.rule == "possible-pii-name"]
        self.assertTrue(hits, "MEMORY.md must be PII-scanned — it loads every session")
        self.assertIn("MEMORY.md", hits[0].message)

    def test_labeled_name_after_index_separator_flagged(self):
        # r3: index rows are `- [Title](file.md) — hook`, so a label in the
        # hook is structurally mid-line; a line-start-only anchor never saw it
        d = make_store({"a.md": GOOD}, ["- [Good](a.md) — Owner: Jane Smith"])
        hits = [f for f in lint_store(d) if f.rule == "possible-pii-name"]
        self.assertTrue(hits, "a label after the index separator must be caught")
        self.assertIn("MEMORY.md", hits[0].message)

    def test_midsentence_label_word_not_flagged(self):
        # the widened pattern must not fire on ordinary prose
        body = GOOD.replace("Body text linking [[other-memory]].",
                            "Decide whether the owner: Bob Jones framing helps.")
        d = make_store({"a.md": body}, ["- [Good](a.md) — hook"])
        self.assertNotIn("possible-pii-name", rules(lint_store(d)))

    def test_git_authorship_in_index_flagged(self):
        d = make_store({"a.md": GOOD},
                       ["- [Good](a.md) — from Jane Smith <jane@notreal-corp.invalid>"])
        hits = [f for f in lint_store(d) if f.rule.startswith("possible-pii")]
        self.assertTrue(hits)
        self.assertIn("MEMORY.md", hits[0].message)

    def test_clean_index_not_flagged(self):
        d = make_store({"a.md": GOOD}, ["- [Good](a.md) — hook"])
        found = rules(lint_store(d))
        self.assertNotIn("possible-pii-email", found)
        self.assertNotIn("possible-pii-name", found)


class TestPlaceholderDomains(unittest.TestCase):
    """M10: only RFC 2606 example.* are reserved; the rest are registrable."""

    def _store_with_email(self, addr):
        body = GOOD.replace("Body text linking [[other-memory]].",
                            f"Reach {addr} for details.")
        return make_store({"a.md": body}, ["- [Good](a.md) — hook"])

    def test_rfc2606_example_domains_exempt(self):
        for addr in ("x@example.com", "x@example.org", "x@example.net"):
            with self.subTest(addr=addr):
                self.assertNotIn("possible-pii-email",
                                 rules(lint_store(self._store_with_email(addr))))

    def test_registrable_lookalike_domains_flagged(self):
        # real, registrable .com domains that can hold live mailboxes
        for addr in ("x@test.com", "x@domain.com", "x@company.com", "x@yourcompany.com"):
            with self.subTest(addr=addr):
                self.assertIn("possible-pii-email",
                              rules(lint_store(self._store_with_email(addr))),
                              f"{addr} is not RFC 2606 reserved — must not be whitelisted")


class TestConfigDir(unittest.TestCase):
    """m6: honor CLAUDE_CONFIG_DIR instead of hardcoding ~/.claude."""

    def test_nearest_store_honors_config_dir_env(self):
        import importlib
        import memory_lint
        d = Path(tempfile.mkdtemp(prefix="memlint_cfg_"))
        (d / "projects" / "-some-project" / "memory").mkdir(parents=True)
        old = os.environ.get("CLAUDE_CONFIG_DIR")
        os.environ["CLAUDE_CONFIG_DIR"] = str(d)
        try:
            importlib.reload(memory_lint)
            self.assertTrue(
                str(memory_lint.CONFIG_ROOT).startswith(str(d)),
                "store root must follow CLAUDE_CONFIG_DIR when set")
        finally:
            if old is None:
                os.environ.pop("CLAUDE_CONFIG_DIR", None)
            else:
                os.environ["CLAUDE_CONFIG_DIR"] = old
            importlib.reload(memory_lint)


if __name__ == "__main__":
    unittest.main(verbosity=2)
