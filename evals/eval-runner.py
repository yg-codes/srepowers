#!/usr/bin/env python3
"""
SREPowers Evaluation Runner

Runs automated evaluations on skills to verify output quality and catch regressions.

Usage:
    python evals/eval-runner.py
    python evals/eval-runner.py --skill sre-runbook
    python evals/eval-runner.py --verbose --report results.md
"""

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass
class EvalResult:
    """Result of a single evaluation."""
    skill: str
    test_name: str
    passed: bool
    score: float  # 0-100
    message: str
    details: Dict = field(default_factory=dict)


@dataclass
class SkillEval:
    """Evaluation suite for a skill."""
    skill: str
    prompt: str
    expected_patterns: List[str]
    forbidden_patterns: List[str]
    min_score: float = 80.0


class EvalRunner:
    """Main evaluation runner."""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.results: List[EvalResult] = []
        self.repo_root = Path(__file__).parent.parent

    def log(self, message: str):
        """Log message if verbose."""
        if self.verbose:
            print(message)

    def run_claude(self, prompt: str, timeout: int = 60) -> str:
        """Run Claude Code with prompt and return output."""
        # This is a placeholder - actual implementation would use Claude Code CLI
        # For now, we'll simulate with a mock response
        try:
            # In real implementation:
            # result = subprocess.run(
            #     ["claude", "--no-interactive", "--prompt", prompt],
            #     capture_output=True,
            #     text=True,
            #     timeout=timeout,
            #     cwd=self.repo_root
            # )
            # return result.stdout

            # Mock for demonstration:
            return f"[Mock response for: {prompt[:50]}...]"
        except subprocess.TimeoutExpired:
            return "[Timeout]"
        except Exception as e:
            return f"[Error: {e}]"

    def check_patterns(self, output: str, patterns: List[str]) -> Tuple[int, int]:
        """Check how many patterns match in output."""
        matches = 0
        for pattern in patterns:
            if re.search(pattern, output, re.IGNORECASE):
                matches += 1
        return matches, len(patterns)

    def evaluate_skill(self, eval_spec: SkillEval) -> List[EvalResult]:
        """Run evaluation for a skill."""
        results = []

        self.log(f"\nEvaluating: {eval_spec.skill}")
        self.log(f"Prompt: {eval_spec.prompt[:80]}...")

        # Get skill output
        output = self.run_claude(eval_spec.prompt)

        # Check expected patterns
        matches, total = self.check_patterns(output, eval_spec.expected_patterns)
        expected_score = (matches / total) * 100 if total > 0 else 100

        results.append(EvalResult(
            skill=eval_spec.skill,
            test_name="expected_patterns",
            passed=expected_score >= eval_spec.min_score,
            score=expected_score,
            message=f"Matched {matches}/{total} expected patterns",
            details={"matches": matches, "total": total}
        ))

        # Check forbidden patterns
        forbidden_matches, _ = self.check_patterns(output, eval_spec.forbidden_patterns)
        forbidden_score = 100 if forbidden_matches == 0 else 0

        results.append(EvalResult(
            skill=eval_spec.skill,
            test_name="forbidden_patterns",
            passed=forbidden_matches == 0,
            score=forbidden_score,
            message=f"Found {forbidden_matches} forbidden patterns",
            details={"forbidden_found": forbidden_matches}
        ))

        return results

    def get_eval_specs(self) -> List[SkillEval]:
        """Get evaluation specifications for all skills."""
        return [
            # SRE Runbook Format Eval
            SkillEval(
                skill="sre-runbook",
                prompt="Create a runbook for checking disk space on a Linux server using the sre-runbook skill.",
                expected_patterns=[
                    r"Command\s*:",
                    r"Expected\s*:",
                    r"Result\s*:",
                    r"##\s+(Step|Pre-check|Verification)",
                    r"```bash",
                ],
                forbidden_patterns=[
                    r"skip.*verification",
                    r"manual.*check",
                ],
                min_score=80.0
            ),

            # Test-Driven Operation Eval
            SkillEval(
                skill="test-driven-operation",
                prompt="What is the correct order of phases in test-driven-operation? Explain why order matters.",
                expected_patterns=[
                    r"RED",
                    r"GREEN",
                    r"REFACTOR",
                    r"verification.*first",
                    r"watch.*fail",
                ],
                forbidden_patterns=[
                    r"GREEN.*RED",
                    r"skip.*RED",
                    r"verify.*after",
                ],
                min_score=100.0
            ),

            # Systematic Troubleshooting Eval
            SkillEval(
                skill="systematic-troubleshooting",
                prompt="List the 4 phases of systematic-troubleshooting and what happens in each.",
                expected_patterns=[
                    r"Phase 1.*Triage",
                    r"Phase 2.*Pattern",
                    r"Phase 3.*Hypothesis",
                    r"Phase 4.*Remediation",
                    r"NO REMEDIATION WITHOUT ROOT CAUSE",
                ],
                forbidden_patterns=[
                    r"restart.*first",
                    r"guess",
                ],
                min_score=80.0
            ),

            # SRE Principles Eval (meta)
            SkillEval(
                skill="using-srepowers",
                prompt="What are the 5 SRE Principles in SREPowers?",
                expected_patterns=[
                    r"Safety First",
                    r"Structured Output",
                    r"Evidence-Driven",
                    r"Audit-Ready",
                    r"Communication",
                ],
                forbidden_patterns=[],
                min_score=100.0
            ),

            # Incident Commander Eval
            SkillEval(
                skill="incident-commander",
                prompt="What are the roles in incident-commander and their responsibilities?",
                expected_patterns=[
                    r"Incident Commander",
                    r"Operations Lead",
                    r"Communications Lead",
                    r"Scribe",
                    r"SEV[12]",
                ],
                forbidden_patterns=[
                    r"blame",
                ],
                min_score=80.0
            ),
        ]

    def run_all(self, skill_filter: Optional[str] = None) -> Dict:
        """Run all evaluations."""
        specs = self.get_eval_specs()

        if skill_filter:
            specs = [s for s in specs if s.skill == skill_filter]

        print(f"Running {len(specs)} evaluation suites...")

        for spec in specs:
            results = self.evaluate_skill(spec)
            self.results.extend(results)

        return self.generate_summary()

    def generate_summary(self) -> Dict:
        """Generate evaluation summary."""
        total = len(self.results)
        passed = sum(1 for r in self.results if r.passed)
        failed = total - passed

        by_skill: Dict[str, List[EvalResult]] = {}
        for r in self.results:
            by_skill.setdefault(r.skill, []).append(r)

        summary = {
            "timestamp": datetime.now().isoformat(),
            "total_tests": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": (passed / total * 100) if total > 0 else 0,
            "by_skill": {
                skill: {
                    "tests": len(results),
                    "passed": sum(1 for r in results if r.passed),
                    "avg_score": sum(r.score for r in results) / len(results),
                }
                for skill, results in by_skill.items()
            }
        }

        return summary

    def print_report(self):
        """Print evaluation report to console."""
        print("\n" + "=" * 60)
        print("EVALUATION REPORT")
        print("=" * 60)

        summary = self.generate_summary()

        print(f"\nTimestamp: {summary['timestamp']}")
        print(f"Total Tests: {summary['total_tests']}")
        print(f"Passed: {summary['passed']}")
        print(f"Failed: {summary['failed']}")
        print(f"Pass Rate: {summary['pass_rate']:.1f}%")

        print("\n" + "-" * 60)
        print("BY SKILL")
        print("-" * 60)

        for skill, stats in summary['by_skill'].items():
            status = "✅" if stats['passed'] == stats['tests'] else "⚠️"
            print(f"{status} {skill}: {stats['passed']}/{stats['tests']} passed "
                  f"(avg score: {stats['avg_score']:.1f}%)")

        if summary['failed'] > 0:
            print("\n" + "-" * 60)
            print("FAILED TESTS")
            print("-" * 60)

            for result in self.results:
                if not result.passed:
                    print(f"\n❌ {result.skill} - {result.test_name}")
                    print(f"   Score: {result.score:.1f}%")
                    print(f"   Message: {result.message}")

        print("\n" + "=" * 60)

    def write_report(self, output_path: str):
        """Write evaluation report to file."""
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)

        summary = self.generate_summary()

        lines = [
            "# SREPowers Evaluation Report",
            "",
            f"**Timestamp:** {summary['timestamp']}",
            f"**Pass Rate:** {summary['pass_rate']:.1f}%",
            "",
            "## Summary",
            "",
            f"- Total Tests: {summary['total_tests']}",
            f"- Passed: {summary['passed']}",
            f"- Failed: {summary['failed']}",
            "",
            "## Results by Skill",
            "",
            "| Skill | Tests | Passed | Avg Score | Status |",
            "|-------|-------|--------|-----------|--------|",
        ]

        for skill, stats in summary['by_skill'].items():
            status = "✅" if stats['passed'] == stats['tests'] else "⚠️"
            lines.append(
                f"| {skill} | {stats['tests']} | {stats['passed']} | "
                f"{stats['avg_score']:.1f}% | {status} |"
            )

        lines.extend([
            "",
            "## Detailed Results",
            "",
        ])

        for result in self.results:
            status = "✅ PASS" if result.passed else "❌ FAIL"
            lines.extend([
                f"### {result.skill} - {result.test_name}",
                "",
                f"- **Status:** {status}",
                f"- **Score:** {result.score:.1f}%",
                f"- **Message:** {result.message}",
                "",
            ])

        path.write_text("\n".join(lines))
        print(f"\nReport written to: {path}")


def main():
    parser = argparse.ArgumentParser(description="SREPowers Evaluation Runner")
    parser.add_argument("--skill", help="Evaluate specific skill only")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument("--report", help="Write report to file")
    parser.add_argument("--json", help="Write JSON results to file")

    args = parser.parse_args()

    runner = EvalRunner(verbose=args.verbose)
    summary = runner.run_all(skill_filter=args.skill)

    runner.print_report()

    if args.report:
        runner.write_report(args.report)

    if args.json:
        path = Path(args.json)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(summary, indent=2))
        print(f"JSON results written to: {path}")

    # Exit with error if any tests failed
    sys.exit(0 if summary['failed'] == 0 else 1)


if __name__ == "__main__":
    main()
