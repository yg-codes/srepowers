#!/usr/bin/env python3
"""fixture-lint — static linter for skill-test-runner fixture YAMLs.

Advisory only, never runs a fixture. WARN = the fixture would fail or lie
inside skill-test-runner (a golden that can't pass its own assertions,
malformed YAML, missing keys); style/convention drift is INFO.

Exit code: 1 if any WARN finding, else 0.
"""

import glob
import re
import sys
from collections import namedtuple
from pathlib import Path

import yaml

Finding = namedtuple("Finding", "level rule message")

def _default_fixtures_dir():
    """The repo's fixture store: <repo-root>/evals/fixtures.

    Walk up from this script (plugins/<plugin>/skills/<skill>/scripts/), then
    fall back to the cwd, so the linter runs unmodified from a clone or a
    marketplace clone. A packaged *cache* install (<plugin>/<version>/skills/…)
    has no repo root above it and ships no fixtures — there the default is
    meaningless and an explicit path argument is required.
    """
    for parent in Path(__file__).resolve().parents:
        candidate = parent / "evals" / "fixtures"
        if candidate.is_dir():
            return candidate
    return Path.cwd() / "evals" / "fixtures"


FIXTURES_DIR = _default_fixtures_dir()
RAW_NAME_RE = re.compile(r"_raw\.(json|yaml)$", re.IGNORECASE)
REQUIRED_KEYS = ("skill", "trigger", "assertions", "golden_output")
TOOL_RESPONSE_KEYS = ("tool", "match_on", "response")
# per skill-test-runner SKILL.md assertion definitions
ASSERTION_KEYS = {
    "required_section": ("value",),
    "llm_judge": ("rubric", "pass_threshold"),
    "required_table_column": ("section", "column"),
    "numeric_within_tolerance": ("pattern", "expected", "tolerance_pct"),
}


RUBRIC_ITEM_RE = re.compile(r"^\s*-\s+\S", re.MULTILINE)
DEDUCTION_RE = re.compile(r"deduct\s+([0-9]*\.?[0-9]+)\s+for each", re.IGNORECASE)
# "It ends with the `net: -<N> lines possible.` footer." — the demand that the
# output TERMINATE with something, plus the literal that must come last.
ENDS_WITH_RE = re.compile(
    r"(?:ends?\s+with|terminat\w*\s+(?:with|in)|final\s+line\s+is)\b[^`\n]*`([^`]+)`",
    re.IGNORECASE,
)


def _check_judge_arithmetic(assertion, threshold, warn):
    """Flag a rubric whose own arithmetic tolerates a missing mandatory item.

    A rubric listing N items and deducting D each scores 1-D when one is
    missing. If the threshold sits at or below that, "ALL of the following"
    is not what the gate enforces — a golden missing a mandatory item passes.
    Shipped once as 5 items x 0.2 against a 0.75 bar.

    Silent unless BOTH the deduction and at least two items are stated: a
    free-form rubric has no arithmetic to check, and guessing would produce
    the false-positive noise that trains readers to skip findings.
    """
    rubric = str(assertion.get("rubric") or "")
    ded = DEDUCTION_RE.search(rubric)
    if not ded:
        return
    items = len(RUBRIC_ITEM_RE.findall(rubric))
    if items < 2:
        return
    try:
        deduction = float(ded.group(1))
    except ValueError:
        return
    if deduction <= 0:
        return
    one_missing = round(1.0 - deduction, 10)
    if threshold <= one_missing:
        warn("weak-judge-threshold",
             f"rubric lists {items} items deducting {deduction} each, so one missing "
             f"item scores {one_missing:g} — at pass_threshold {threshold:g} that "
             "still PASSES, so the rubric cannot enforce 'all of the following'; "
             f"raise the threshold above {one_missing:g}")


def _check_golden_ends_with_footer(assertion, golden, warn):
    """Check a golden against a rubric item demanding the output END with a literal.

    Two ways to fail that item, both of which shipped in withdrawn fixtures:
    the golden runs past the footer (three ponytail goldens, 9-13 extra lines
    each, scoring 0.8 against their own 0.9 threshold), or it omits the footer
    outright. Neither is caught anywhere else — `golden-misses-required-section`
    only inspects `required_section` values, never llm_judge literals.
    """
    rubric = str(assertion.get("rubric") or "")
    match = ENDS_WITH_RE.search(rubric)
    if not match or not golden.strip():
        return

    # The rubric's literal is a template (`net: -<N> lines possible.`,
    # `<N> markers, <M> with no trigger.`), so match on its longest FIXED
    # segment. Taking the leading segment instead silently skipped every
    # literal that begins with a placeholder — which is the real reason the
    # withdrawn ponytail-debt fixture was missed, not a phrasing mismatch.
    literal = match.group(1)
    segments = [s.strip() for s in re.split(r"<[^>]*>|\{[^}]*\}", literal)]
    stem = max(segments, key=len) if segments else ""
    if len(stem) < 3:
        return

    idx = golden.lower().rfind(stem.lower())
    if idx == -1:
        warn("golden-misses-rubric-footer",
             f"the rubric requires the output to end with {literal!r}, but the "
             f"golden contains no {stem!r} — the golden would fail the fixture's "
             "own rubric item")
        return

    tail = golden[idx + len(stem):]
    # Everything after the footer's own line must be blank.
    after_line = tail.split("\n", 1)[1] if "\n" in tail else ""
    if after_line.strip():
        extra = len([ln for ln in after_line.splitlines() if ln.strip()])
        warn("golden-content-after-footer",
             f"the rubric requires the output to end with {literal!r}, but the "
             f"golden continues for {extra} more non-blank line(s) — the golden "
             "would fail the fixture's own rubric item")


def lint_file(path):
    """Lint one fixture YAML. Returns [Finding]."""
    findings = []
    warn = lambda rule, msg: findings.append(Finding("WARN", rule, msg))
    info = lambda rule, msg: findings.append(Finding("INFO", rule, msg))

    try:
        text = Path(path).read_text()
    except OSError as e:
        warn("file-unreadable", f"cannot read: {str(e).splitlines()[0]}")
        return findings

    if RAW_NAME_RE.search(Path(path).name) or "RAW DUMP" in text:
        warn("uncurated-raw-dump",
             "filename matches `_raw.(json|yaml)` or contains a `RAW DUMP` marker — "
             "this is an uncurated capture of real tool output, the highest-risk "
             "artifact in the store (may carry identities or business-confidential "
             "content); curate it into a proper fixture or scrub it before it stays")
        return findings

    try:
        d = yaml.safe_load(text)
    except yaml.YAMLError as e:
        warn("yaml-unparseable", f"cannot parse: {str(e).splitlines()[0]}")
        return findings
    if not isinstance(d, dict):
        warn("not-a-mapping", "top level must be a mapping with skill/trigger/assertions/golden_output")
        return findings

    for k in REQUIRED_KEYS:
        if k not in d:
            warn("missing-key", f"required top-level key `{k}` is missing")
    for k in ("assertions", "tool_responses"):
        if k in d and not isinstance(d[k], list):
            warn("not-a-list", f"`{k}` must be a list — a scalar/mapping here makes the "
                               "runner silently skip every entry")
            d = {**d, k: []}
    if "tool_responses" not in d:
        info("missing-tool-responses", "no tool_responses — the runner will have no mocked tool "
                                       "output; every fixture in the store provides them")

    # An assertion list that is present but empty makes every run pass: the
    # fixture exercises the skill and then checks nothing. Same class as the
    # zero-denominator scan below.
    if isinstance(d.get("assertions"), list) and not d["assertions"]:
        warn("no-assertions",
             "`assertions` is empty — the fixture would PASS unconditionally; "
             "a fixture that cannot fail tests nothing")

    golden = str(d.get("golden_output") or "").lower()
    golden_headings = [ln for ln in golden.splitlines() if ln.lstrip().startswith("#")]
    mock_text = " ".join(str(tr.get("response") or "") for tr in d.get("tool_responses") or []
                         if isinstance(tr, dict)).lower()
    for a in d.get("assertions") or []:
        if not isinstance(a, dict):
            warn("assertion-not-a-mapping",
                 f"assertion entry {a!r} is not a mapping — the runner skips it "
                 "silently, so it asserts nothing")
            continue
        atype = a.get("type")
        if atype not in ASSERTION_KEYS:
            warn("unknown-assertion-type",
                 f"assertion type `{atype}` is not defined by skill-test-runner "
                 f"(known: {', '.join(ASSERTION_KEYS)})")
            continue
        missing = [k for k in ASSERTION_KEYS[atype] if k not in a]
        if missing:
            warn("assertion-missing-keys", f"`{atype}` assertion lacks required key(s): {', '.join(missing)}")
        if atype == "required_section" and "value" in a:
            val = str(a["value"]).lower()
            if not val.strip():
                # "" is a substring of every string, so this can never fail
                warn("vacuous-required-section",
                     f"required_section value {a['value']!r} is empty/whitespace — "
                     "it matches any output, so the assertion can never fail")
                continue
            if val not in golden:
                warn("golden-misses-required-section",
                     f"golden_output does not contain required_section {a['value']!r} "
                     "(case-insensitive substring, per runner semantics) — the golden "
                     "would fail the fixture's own assertion")
            elif (len(val.split()) >= 2 and val not in mock_text
                    and not any(val in h for h in golden_headings)):
                info("paraphrase-brittle-required-section",
                     f"multi-word required_section {a['value']!r} matches only golden "
                     "prose — not a heading, not verbatim mock tool output — so the "
                     "exact substring is brittle to valid paraphrase; prefer the "
                     "shortest distinctive token or cover the concept in the "
                     "llm_judge rubric")
        if atype == "numeric_within_tolerance" and "expected" in a:
            exp = a["expected"]
            # The runner computes |actual-expected|/expected: zero divides, and a
            # negative denominator inverts the comparison so every actual passes.
            if isinstance(exp, bool) or not isinstance(exp, int | float) or exp <= 0:
                warn("bad-numeric-expected",
                     f"expected {exp!r} must be a positive number — the tolerance "
                     "formula divides by it, so 0 is undefined and a negative "
                     "value inverts the check into one that always passes")

        if atype == "llm_judge" and "pass_threshold" in a:
            t = a["pass_threshold"]
            if isinstance(t, bool) or not isinstance(t, int | float) or not 0 < t <= 1:
                warn("bad-pass-threshold", f"pass_threshold {t!r} must be a number in (0, 1]")
            else:
                _check_judge_arithmetic(a, t, warn)
            _check_golden_ends_with_footer(a, str(d.get("golden_output") or ""), warn)

    for tr in d.get("tool_responses") or []:
        if not isinstance(tr, dict):
            continue
        missing = [k for k in TOOL_RESPONSE_KEYS if k not in tr]
        if missing:
            warn("tool-response-missing-keys", f"tool_responses entry lacks: {', '.join(missing)}")
        # case-sensitive on purpose: `bash` = hand-authored mock (convention applies);
        # `Bash` = verbatim real-session capture, where adding exit-code lines would falsify it
        if tr.get("tool") == "bash" and "(exit code:" not in str(tr.get("response") or ""):
            info("bash-response-no-exit-code", "bash response has no `(exit code: N)` line — "
                                               "store convention for bash mocks")

    return findings


def collect_paths(argv):
    """Expand args into fixture files: *.yaml/*.yml, fixture-*.json, *_raw.(json|yaml).

    A directory that does not exist contributes nothing rather than being
    passed through as a phantom file: the caller reports "nothing examined",
    which is the honest answer, instead of a per-file read error that looks
    like one broken fixture among many.
    """
    paths = []
    for a in argv or [str(FIXTURES_DIR)]:
        p = Path(a)
        if not p.exists() and (p == FIXTURES_DIR or not argv):
            continue
        if p.is_dir():
            paths.extend(sorted(set(glob.glob(str(p / "**/*.yaml"), recursive=True)
                                + glob.glob(str(p / "**/*.yml"), recursive=True)
                                + glob.glob(str(p / "**/fixture-*.json"), recursive=True)
                                + glob.glob(str(p / "**/*_raw.json"), recursive=True))))
        else:
            paths.append(a)
    return paths


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    paths = collect_paths(argv)

    # A scan that read nothing must never print a clean result: "0 problems out
    # of 0 examined" is indistinguishable from a healthy store, and that is the
    # zero-denominator pass this linter exists to catch elsewhere. Name the
    # location so the cause (wrong cwd, empty store, packaged install with no
    # fixtures) is diagnosable from the message alone.
    if not paths:
        where = argv[0] if argv else str(FIXTURES_DIR)
        print(f"FAIL: no fixture files found under {where} — "
              "nothing was examined, so this is not a pass. Check the path, or "
              "pass an explicit fixture/directory argument.", file=sys.stderr)
        return 2

    total = []
    for path in paths:
        findings = lint_file(path)
        if findings:
            print(f"> {path}")
            for f in findings:
                print(f"  {f.level} {f.rule}: {f.message}")
        total.extend(findings)

    # Always print the denominator — a bare "no findings" hides how much was read.
    if not total:
        print(f"no findings ({len(paths)} fixture(s) checked)")
    return 1 if any(f.level == "WARN" for f in total) else 0


if __name__ == "__main__":
    sys.exit(main())
