"""Tests for fixture_lint.py — run: PYTHONDONTWRITEBYTECODE=1 python3 -B test_fixture_lint.py"""

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fixture_lint import collect_paths, lint_file

GOOD = """\
skill: report-lint
trigger: |
  Run report-lint on the report.
tool_responses:
  - tool: bash
    match_on: report_lint.py
    response: |
      no findings
      (exit code: 0)
assertions:
  - type: required_section
    value: "no findings"
  - type: llm_judge
    rubric: |
      Score 1.0 if the output states the report passed.
    pass_threshold: 0.7
golden_output: |
  report-lint reports no findings (exit 0); ready to deliver.
"""


def write_fixture(text):
    d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
    p = d / "fixture-test.yaml"
    p.write_text(text)
    return p


def rules(findings):
    return [f.rule for f in findings]


class TestJsonFixtures(unittest.TestCase):
    JSON_GOOD = """{
  "skill": "cost-anomaly-trace",
  "trigger": "trace the NAT spike",
  "tool_responses": [{"tool": "Bash", "match_on": "describe-nat-gateways", "response": "table..."}],
  "assertions": [{"type": "required_section", "value": "nat-04aef40d4ce567a17"}],
  "golden_output": "The spike traces to nat-04aef40d4ce567a17."
}"""

    def test_json_fixture_is_linted(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        p = d / "fixture-test.json"
        p.write_text(self.JSON_GOOD.replace("nat-04aef40d4ce567a17.", "a different golden."))
        self.assertIn("golden-misses-required-section", rules(lint_file(p)))

    def test_json_fixture_clean(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        p = d / "fixture-test.json"
        p.write_text(self.JSON_GOOD)
        self.assertEqual([], lint_file(p))

    def test_collect_includes_fixture_json_and_raw_excludes_other_json(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        (d / "fixture-a.yaml").write_text(GOOD)
        (d / "fixture-b.json").write_text(self.JSON_GOOD)
        (d / "b_raw.json").write_text("{}")
        (d / "notes.json").write_text("{}")
        names = sorted(Path(p).name for p in collect_paths([str(d)]))
        self.assertEqual(["b_raw.json", "fixture-a.yaml", "fixture-b.json"], names)


class TestRawDump(unittest.TestCase):
    def test_raw_json_filename_flagged(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        p = d / "abc123_raw.json"
        p.write_text('{"anything": "here"}')
        self.assertIn("uncurated-raw-dump", rules(lint_file(p)))

    def test_raw_yaml_filename_flagged(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        p = d / "abc123_raw.yaml"
        p.write_text("anything: here\n")
        self.assertIn("uncurated-raw-dump", rules(lint_file(p)))

    def test_raw_dump_marker_flagged_regardless_of_filename(self):
        p = write_fixture("# RAW DUMP\nanything: here\n")
        self.assertIn("uncurated-raw-dump", rules(lint_file(p)))

    def test_raw_dump_skips_other_checks(self):
        # a raw dump has no skill/trigger/assertions/golden_output — that's expected,
        # not a separate defect to also report
        d = Path(tempfile.mkdtemp(prefix="fixlint_test_"))
        p = d / "abc123_raw.json"
        p.write_text('{"anything": "here"}')
        self.assertEqual(["uncurated-raw-dump"], rules(lint_file(p)))

    def test_ordinary_fixture_not_flagged(self):
        self.assertNotIn("uncurated-raw-dump", rules(lint_file(write_fixture(GOOD))))


class TestParseAndShape(unittest.TestCase):
    def test_clean_fixture(self):
        self.assertEqual([], lint_file(write_fixture(GOOD)))

    def test_unparseable_yaml(self):
        p = write_fixture("skill: [unclosed\n  bad: {indent")
        self.assertIn("yaml-unparseable", rules(lint_file(p)))

    def test_unreadable_file_is_file_unreadable_not_yaml(self):
        findings = lint_file(Path(tempfile.mkdtemp(prefix="fixlint_test_")) / "nope.yaml")
        self.assertIn("file-unreadable", rules(findings))
        self.assertNotIn("yaml-unparseable", rules(findings))

    def test_not_a_mapping(self):
        p = write_fixture("- just\n- a\n- list\n")
        self.assertIn("not-a-mapping", rules(lint_file(p)))

    def test_missing_top_level_key(self):
        p = write_fixture(GOOD.replace("golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n", ""))
        found = rules(lint_file(p))
        self.assertIn("missing-key", found)

    def test_assertions_not_a_list(self):
        text = GOOD.replace("""assertions:
  - type: required_section
    value: "no findings"
  - type: llm_judge
    rubric: |
      Score 1.0 if the output states the report passed.
    pass_threshold: 0.7
""", "assertions: just a string\n")
        self.assertIn("not-a-list", rules(lint_file(write_fixture(text))))

    def test_tool_responses_not_a_list(self):
        text = GOOD.replace("""tool_responses:
  - tool: bash
    match_on: report_lint.py
    response: |
      no findings
      (exit code: 0)
""", "tool_responses: nope\n")
        self.assertIn("not-a-list", rules(lint_file(write_fixture(text))))

    def test_numeric_within_tolerance_missing_keys(self):
        text = GOOD.replace("""  - type: required_section
    value: "no findings"
""", """  - type: required_section
    value: "no findings"
  - type: numeric_within_tolerance
    pattern: "(\\\\d+) findings"
""")
        self.assertIn("assertion-missing-keys", rules(lint_file(write_fixture(text))))

    def test_missing_tool_responses_is_info(self):
        text = GOOD.replace("""tool_responses:
  - tool: bash
    match_on: report_lint.py
    response: |
      no findings
      (exit code: 0)
""", "")
        findings = lint_file(write_fixture(text))
        info = [f for f in findings if f.rule == "missing-tool-responses"]
        self.assertEqual(1, len(info))
        self.assertEqual("INFO", info[0].level)


class TestAssertions(unittest.TestCase):
    def test_golden_misses_required_section(self):
        p = write_fixture(GOOD.replace('value: "no findings"', 'value: "totally absent phrase"'))
        self.assertIn("golden-misses-required-section", rules(lint_file(p)))

    def test_required_section_match_is_case_insensitive(self):
        # runner semantics: case-insensitive substring — Title-case golden must NOT be flagged
        p = write_fixture(GOOD.replace("report-lint reports no findings", "Report-lint reports No Findings"))
        self.assertNotIn("golden-misses-required-section", rules(lint_file(p)))

    def test_llm_judge_missing_rubric(self):
        text = GOOD.replace("""    rubric: |
      Score 1.0 if the output states the report passed.
""", "")
        self.assertIn("assertion-missing-keys", rules(lint_file(write_fixture(text))))

    def test_llm_judge_missing_pass_threshold(self):
        text = GOOD.replace("    pass_threshold: 0.7\n", "")
        self.assertIn("assertion-missing-keys", rules(lint_file(write_fixture(text))))

    def test_bad_pass_threshold(self):
        text = GOOD.replace("pass_threshold: 0.7", "pass_threshold: 7")
        self.assertIn("bad-pass-threshold", rules(lint_file(write_fixture(text))))

    def test_bool_pass_threshold_flagged(self):
        # bool is an int subclass — `pass_threshold: true` must not slip through as 1
        text = GOOD.replace("pass_threshold: 0.7", "pass_threshold: true")
        self.assertIn("bad-pass-threshold", rules(lint_file(write_fixture(text))))

    def test_unknown_assertion_type(self):
        text = GOOD.replace("type: required_section", "type: required_paragraph")
        self.assertIn("unknown-assertion-type", rules(lint_file(write_fixture(text))))

    def test_required_table_column_needs_section_and_column(self):
        text = GOOD + "  # extended below\n"
        text = text.replace("""assertions:
  - type: required_section
    value: "no findings"
""", """assertions:
  - type: required_section
    value: "no findings"
  - type: required_table_column
    column: "Account"
""")
        self.assertIn("assertion-missing-keys", rules(lint_file(write_fixture(text))))


class TestParaphraseBrittle(unittest.TestCase):
    """paraphrase-brittle-required-section: multi-word required_section values
    matched only in golden prose (not on a heading line) are brittle to valid
    paraphrase — R24: "S3 VPC endpoint" failed against "S3 gateway VPC endpoint"."""

    def fixture_with(self, value, golden):
        return GOOD.replace('value: "no findings"', f'value: "{value}"').replace(
            "golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n",
            f"golden_output: |\n{golden}",
        )

    def test_multiword_prose_value_flagged_info(self):
        text = self.fixture_with("S3 VPC endpoint", "  Add an S3 VPC endpoint to the VPC.\n")
        findings = lint_file(write_fixture(text))
        hits = [f for f in findings if f.rule == "paraphrase-brittle-required-section"]
        self.assertEqual(1, len(hits))
        self.assertEqual("INFO", hits[0].level)

    def test_multiword_heading_value_not_flagged(self):
        text = self.fixture_with("Cost Anomaly Summary",
                                 "  ## Cost Anomaly Summary\n  All clear.\n")
        self.assertNotIn("paraphrase-brittle-required-section", rules(lint_file(write_fixture(text))))

    def test_heading_match_is_case_insensitive(self):
        text = self.fixture_with("cost anomaly summary",
                                 "  ## Cost Anomaly Summary\n  All clear.\n")
        self.assertNotIn("paraphrase-brittle-required-section", rules(lint_file(write_fixture(text))))

    def test_single_word_value_not_flagged(self):
        text = self.fixture_with("Timeline", "  The timeline is below.\n")
        self.assertNotIn("paraphrase-brittle-required-section", rules(lint_file(write_fixture(text))))

    def test_value_anchored_in_tool_response_not_flagged(self):
        # "no findings" in GOOD is verbatim mock tool output — the agent echoes
        # tool output literally, so the exact substring is anchored, not brittle
        self.assertNotIn("paraphrase-brittle-required-section", rules(lint_file(write_fixture(GOOD))))

    def test_absent_value_not_double_flagged(self):
        # a value missing from the golden entirely is the WARN rule's territory;
        # the brittleness INFO must not also fire on it
        text = self.fixture_with("totally absent phrase", "  Something else entirely.\n")
        found = rules(lint_file(write_fixture(text)))
        self.assertIn("golden-misses-required-section", found)
        self.assertNotIn("paraphrase-brittle-required-section", found)


class TestToolResponses(unittest.TestCase):
    def test_tool_response_missing_keys(self):
        text = GOOD.replace("    match_on: report_lint.py\n", "")
        self.assertIn("tool-response-missing-keys", rules(lint_file(write_fixture(text))))

    def test_bash_response_without_exit_code_is_info(self):
        text = GOOD.replace("      (exit code: 0)\n", "")
        findings = lint_file(write_fixture(text))
        hits = [f for f in findings if f.rule == "bash-response-no-exit-code"]
        self.assertEqual(1, len(hits))
        self.assertEqual("INFO", hits[0].level)

    def test_non_bash_response_without_exit_code_not_flagged(self):
        text = GOOD.replace("tool: bash", "tool: mcp_query").replace("      (exit code: 0)\n", "")
        self.assertNotIn("bash-response-no-exit-code", rules(lint_file(write_fixture(text))))

    def test_capital_bash_captured_fixture_not_flagged(self):
        # R27 decision: `tool: Bash` (capital) marks verbatim real-session captures, where
        # appending synthetic exit-code lines would falsify the capture — never flag them
        text = GOOD.replace("tool: bash", "tool: Bash").replace("      (exit code: 0)\n", "")
        self.assertNotIn("bash-response-no-exit-code", rules(lint_file(write_fixture(text))))


class TestVacuousFixtures(unittest.TestCase):
    """A fixture that cannot fail is the §1 pathology inside the gate itself."""

    def test_empty_assertions_list_flagged(self):
        text = GOOD.replace(
            'assertions:\n  - type: required_section\n    value: "no findings"\n'
            "  - type: llm_judge\n    rubric: |\n"
            "      Score 1.0 if the output states the report passed.\n"
            "    pass_threshold: 0.7\n",
            "assertions: []\n",
        )
        self.assertIn("no-assertions", rules(lint_file(write_fixture(text))))

    def test_empty_required_section_value_flagged(self):
        # "" is a substring of every possible output — the assertion can never fail
        text = GOOD.replace('value: "no findings"', 'value: ""')
        self.assertIn("vacuous-required-section", rules(lint_file(write_fixture(text))))

    def test_whitespace_required_section_value_flagged(self):
        text = GOOD.replace('value: "no findings"', 'value: "   "')
        self.assertIn("vacuous-required-section", rules(lint_file(write_fixture(text))))

    def test_non_mapping_assertion_entry_flagged(self):
        # a scalar entry is silently skipped by the runner — it asserts nothing
        text = GOOD.replace('  - type: required_section\n    value: "no findings"\n',
                            "  - just-a-string\n")
        self.assertIn("assertion-not-a-mapping", rules(lint_file(write_fixture(text))))


class TestNumericTolerance(unittest.TestCase):
    """m5: the tolerance formula is undefined at 0 and sign-inverted below it."""

    def _with_numeric(self, expected):
        return GOOD.replace(
            '  - type: required_section\n    value: "no findings"\n',
            "  - type: numeric_within_tolerance\n"
            "    pattern: 'count: (\\d+)'\n"
            f"    expected: {expected}\n"
            "    tolerance_pct: 10\n",
        )

    def test_zero_expected_flagged(self):
        # |actual-0|/0 divides by zero
        self.assertIn("bad-numeric-expected",
                      rules(lint_file(write_fixture(self._with_numeric(0)))))

    def test_negative_expected_flagged(self):
        # dividing by a negative flips the comparison — every actual passes
        self.assertIn("bad-numeric-expected",
                      rules(lint_file(write_fixture(self._with_numeric(-5)))))

    def test_positive_expected_clean(self):
        self.assertNotIn("bad-numeric-expected",
                         rules(lint_file(write_fixture(self._with_numeric(42)))))


JUDGE_RUBRIC = """\
  - type: llm_judge
    rubric: |
      Score 1.0 if ALL of the following hold:
        - item one holds.
        - item two holds.
        - item three holds.
        - item four holds.
        - item five holds.
      Deduct {deduction} for each missing item.
    pass_threshold: {threshold}
"""


def with_judge(threshold, deduction="0.2", items=5, golden="report-lint reports no findings (exit 0); ready to deliver.\n"):
    """GOOD, but with its llm_judge replaced by a countable N-item rubric."""
    bullets = "".join(f"        - item {n} holds.\n" for n in range(1, items + 1))
    judge = (
        "  - type: llm_judge\n"
        "    rubric: |\n"
        "      Score 1.0 if ALL of the following hold:\n"
        f"{bullets}"
        f"      Deduct {deduction} for each missing item.\n"
        f"    pass_threshold: {threshold}\n"
    )
    old_judge = (
        "  - type: llm_judge\n    rubric: |\n"
        "      Score 1.0 if the output states the report passed.\n"
        "    pass_threshold: 0.7\n"
    )
    text = GOOD.replace(old_judge, judge)
    assert judge in text, "judge block substitution failed"
    return text.replace(
        "golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n",
        f"golden_output: |\n  {golden}",
    )


class TestJudgeThresholdArithmetic(unittest.TestCase):
    """A rubric whose own arithmetic lets a mandatory item go missing.

    5 items x 0.2 means one omission scores 0.8. A threshold at or below that
    cannot enforce "ALL of the following" — the defect that shipped in the
    first sre-runbook fixture (5 x 0.2 against 0.75).
    """

    def test_threshold_below_one_omission_flagged(self):
        text = with_judge(threshold="0.75")   # 1.0 - 0.2 = 0.8 > 0.75 -> passes
        self.assertIn("weak-judge-threshold", rules(lint_file(write_fixture(text))))

    def test_threshold_equal_to_one_omission_flagged(self):
        text = with_judge(threshold="0.8")    # exactly 0.8 still passes at >=
        self.assertIn("weak-judge-threshold", rules(lint_file(write_fixture(text))))

    def test_threshold_above_one_omission_clean(self):
        text = with_judge(threshold="0.9")
        self.assertNotIn("weak-judge-threshold", rules(lint_file(write_fixture(text))))

    def test_full_marks_threshold_clean(self):
        text = with_judge(threshold="1.0")
        self.assertNotIn("weak-judge-threshold", rules(lint_file(write_fixture(text))))

    def test_other_deduction_value_respected(self):
        # 5 items x 0.1 -> one omission scores 0.9; a 0.85 bar is too low
        low = with_judge(threshold="0.85", deduction="0.1")
        self.assertIn("weak-judge-threshold", rules(lint_file(write_fixture(low))))
        ok = with_judge(threshold="0.95", deduction="0.1")
        self.assertNotIn("weak-judge-threshold", rules(lint_file(write_fixture(ok))))

    def test_rubric_without_countable_items_not_flagged(self):
        # The stock GOOD rubric states no deduction and lists no items — the
        # rule must stay silent rather than guess.
        self.assertNotIn("weak-judge-threshold", rules(lint_file(write_fixture(GOOD))))


class TestGoldenEndsWithFooter(unittest.TestCase):
    """A rubric demanding the output END with a footer, and a golden that does not.

    This is what let three withdrawn ponytail goldens pass every gate while
    scoring 0.8 against their own 0.9 threshold: each ran 9-13 lines past the
    terminal footer its rubric required it to end with.
    """

    def _with_footer_rule(self, golden):
        bullets = "".join(f"        - item {n} holds.\n" for n in range(1, 6))
        judge = (
            "  - type: llm_judge\n"
            "    rubric: |\n"
            "      Score 1.0 if ALL of the following hold:\n"
            f"{bullets}"
            "        - It ends with the `net: -<N> lines possible.` footer.\n"
            "      Deduct 0.2 for each missing item.\n"
            "    pass_threshold: 0.9\n"
        )
        old_judge = (
            "  - type: llm_judge\n    rubric: |\n"
            "      Score 1.0 if the output states the report passed.\n"
            "    pass_threshold: 0.7\n"
        )
        text = GOOD.replace(old_judge, judge)
        return text.replace(
            "golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n",
            "golden_output: |\n" + golden,
        )

    def test_content_after_footer_flagged(self):
        golden = (
            "  no findings\n"
            "  net: -12 lines possible.\n"
            "\n"
            "  Biggest single win is the retry wrapper.\n"
        )
        self.assertIn(
            "golden-content-after-footer", rules(lint_file(write_fixture(self._with_footer_rule(golden))))
        )

    def test_footer_last_is_clean(self):
        golden = "  no findings\n  net: -12 lines possible.\n"
        self.assertNotIn(
            "golden-content-after-footer", rules(lint_file(write_fixture(self._with_footer_rule(golden))))
        )

    def test_trailing_blank_lines_are_not_content(self):
        golden = "  no findings\n  net: -12 lines possible.\n\n\n"
        self.assertNotIn(
            "golden-content-after-footer", rules(lint_file(write_fixture(self._with_footer_rule(golden))))
        )

    def test_no_ends_with_requirement_not_flagged(self):
        # No "ends with" language in the rubric -> the rule must stay silent.
        text = with_judge(threshold="0.9", golden="no findings\n  trailing prose is fine here.\n")
        self.assertNotIn("golden-content-after-footer", rules(lint_file(write_fixture(text))))

    def test_placeholder_first_literal_still_checked(self):
        # A literal whose FIXED text follows its placeholder (`<N> markers, <M>
        # with no trigger.`) left an empty leading segment, so the rule bailed
        # silently. That is why the withdrawn ponytail-debt golden was missed —
        # not, as first documented, a phrasing mismatch.
        bullets = "".join(f"        - item {n} holds.\n" for n in range(1, 6))
        judge = (
            "  - type: llm_judge\n"
            "    rubric: |\n"
            "      Score 1.0 if ALL of the following hold:\n"
            f"{bullets}"
            "        - It ends with the `<N> markers, <M> with no trigger.` footer.\n"
            "      Deduct 0.2 for each missing item.\n"
            "    pass_threshold: 0.9\n"
        )
        old_judge = (
            "  - type: llm_judge\n    rubric: |\n"
            "      Score 1.0 if the output states the report passed.\n"
            "    pass_threshold: 0.7\n"
        )
        text = GOOD.replace(old_judge, judge).replace(
            "golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n",
            "golden_output: |\n"
            "  no findings\n"
            "  7 markers, 2 with no trigger.\n"
            "\n"
            "  The two no-trigger rows are the rot risk.\n",
        )
        self.assertIn(
            "golden-content-after-footer", rules(lint_file(write_fixture(text)))
        )


class TestGoldenMissingFooter(unittest.TestCase):
    """A golden that omits the mandated footer entirely must not pass.

    Trailing-past-the-footer was caught; forgetting it outright was not, and an
    in-code comment wrongly claimed golden-misses-required-section covered it —
    that rule only inspects `required_section` values, never llm_judge literals.
    """

    def _with_footer_rule(self, golden):
        bullets = "".join(f"        - item {n} holds.\n" for n in range(1, 6))
        judge = (
            "  - type: llm_judge\n"
            "    rubric: |\n"
            "      Score 1.0 if ALL of the following hold:\n"
            f"{bullets}"
            "        - It ends with the `net: -<N> lines possible.` footer.\n"
            "      Deduct 0.2 for each missing item.\n"
            "    pass_threshold: 0.9\n"
        )
        old_judge = (
            "  - type: llm_judge\n    rubric: |\n"
            "      Score 1.0 if the output states the report passed.\n"
            "    pass_threshold: 0.7\n"
        )
        return GOOD.replace(old_judge, judge).replace(
            "golden_output: |\n  report-lint reports no findings (exit 0); ready to deliver.\n",
            "golden_output: |\n" + golden,
        )

    def test_absent_footer_flagged(self):
        golden = "  no findings\n  looks lean otherwise.\n"
        self.assertIn(
            "golden-misses-rubric-footer",
            rules(lint_file(write_fixture(self._with_footer_rule(golden)))),
        )

    def test_present_footer_not_flagged(self):
        golden = "  no findings\n  net: -12 lines possible.\n"
        self.assertNotIn(
            "golden-misses-rubric-footer",
            rules(lint_file(write_fixture(self._with_footer_rule(golden)))),
        )

    def test_absent_and_trailing_are_distinct_rules(self):
        # A golden with the footer mid-document gets the content-after rule,
        # not the absence rule — the two must not both fire.
        golden = "  no findings\n  net: -12 lines possible.\n\n  more prose.\n"
        found = rules(lint_file(write_fixture(self._with_footer_rule(golden))))
        self.assertIn("golden-content-after-footer", found)
        self.assertNotIn("golden-misses-rubric-footer", found)


class TestScanDenominator(unittest.TestCase):
    """C1: a scan that read nothing must not report clean."""

    def test_yml_extension_is_collected(self):
        d = Path(tempfile.mkdtemp(prefix="fixlint_yml_"))
        (d / "fixture-a.yml").write_text(GOOD)
        self.assertEqual(1, len(collect_paths([str(d)])))

    def test_empty_directory_scan_is_not_a_pass(self):
        from fixture_lint import main
        d = tempfile.mkdtemp(prefix="fixlint_empty_")
        self.assertNotEqual(0, main([d]),
                            "a scan over zero files must not exit 0 — that is the "
                            "zero-denominator pass this tool warns about")

    def test_explicit_missing_file_still_reported(self):
        # the missing-default-store skip must not swallow a path the user named
        from fixture_lint import main
        self.assertEqual(1, main(["/tmp/fixlint-definitely-not-here.yaml"]),
                         "an explicitly named missing file must WARN, not vanish")


if __name__ == "__main__":
    unittest.main()
