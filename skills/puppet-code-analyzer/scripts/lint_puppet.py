#!/usr/bin/env python3
"""
Puppet Lint Runner - Wrapper script for puppet-lint with project-specific rules

This script runs puppet-lint on Puppet manifests and returns structured output.
It respects .puppet-lint.rc configuration files if present.

Usage:
    python3 lint_puppet.py <path-to-manifest-or-directory>
    python3 lint_puppet.py --fix <path-to-manifest-or-directory>
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional


class LintResult:
    """Structured lint result."""

    def __init__(self, file: str, line: int, column: int, severity: str,
                 rule_code: str, message: str, fixable: bool = False):
        self.file = file
        self.line = line
        self.column = column
        self.severity = severity  # critical, warning, info
        self.rule_code = rule_code
        self.message = message
        self.fixable = fixable

    def to_dict(self) -> Dict:
        return {
            "file": self.file,
            "line": self.line,
            "column": self.column,
            "severity": self.severity,
            "rule_code": self.rule_code,
            "message": self.message,
            "fixable": self.fixable
        }


def find_puppet_lint_rc(start_path: Path) -> Optional[Path]:
    """Find .puppet-lint.rc configuration file."""
    current = start_path if start_path.is_dir() else start_path.parent
    while current != current.parent:
        config = current / ".puppet-lint.rc"
        if config.exists():
            return config
        current = current.parent
    return None


def run_puppet_lint(target: Path, fix: bool = False,
                    config: Optional[Path] = None) -> List[LintResult]:
    """Run puppet-lint and parse results."""
    cmd = ["puppet-lint"]

    if fix:
        cmd.append("--fix")

    if config:
        cmd.extend(["--config", str(config)])

    # Add default flags for better output
    cmd.extend([
        "--relative",
        "--format", "%{path}:%{line}:%{column}:%{kind}:%{check}:%{message}"
    ])

    cmd.append(str(target))

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=False
        )

        issues = []
        for line in result.stdout.splitlines():
            if line.strip():
                parts = line.split(":", 5)
                if len(parts) == 6:
                    file_path, line_no, column, severity, rule, msg = parts
                    issues.append(LintResult(
                        file=file_path,
                        line=int(line_no),
                        column=int(column),
                        severity=severity.lower(),
                        rule_code=rule,
                        message=msg.strip(),
                        fixable=fix
                    ))

        return issues

    except FileNotFoundError:
        print("Error: puppet-lint not found. Install with: gem install puppet-lint")
        return []
    except Exception as e:
        print(f"Error running puppet-lint: {e}")
        return []


def format_results(results: List[LintResult], target: Path) -> str:
    """Format lint results for display."""
    if not results:
        return f"✅ No lint issues found in {target}"

    # Group by severity
    critical = [r for r in results if r.severity == "error"]
    warnings = [r for r in results if r.severity in ["warning", "warn"]]
    info = [r for r in results if r.severity == "info"]

    output = [f"## Puppet Lint Analysis: {target}\n"]

    if critical:
        output.append("### CRITICAL")
        for r in critical:
            output.append(
                f"- **{r.rule_code}**: {r.message}\n"
                f"  at `{r.file}:{r.line}:{r.column}`"
            )

    if warnings:
        output.append("\n### WARNING")
        for r in warnings:
            output.append(
                f"- **{r.rule_code}**: {r.message}\n"
                f"  at `{r.file}:{r.line}:{r.column}`"
            )

    if info:
        output.append("\n### INFO")
        for r in info:
            output.append(
                f"- **{r.rule_code}**: {r.message}\n"
                f"  at `{r.file}:{r.line}:{r.column}`"
            )

    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(
        description="Run puppet-lint with project-specific rules"
    )
    parser.add_argument(
        "target",
        type=Path,
        help="Path to Puppet manifest or directory"
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        help="Automatically fix lint issues where possible"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON"
    )
    parser.add_argument(
        "--config",
        type=Path,
        help="Path to .puppet-lint.rc configuration file"
    )

    args = parser.parse_args()

    if not args.target.exists():
        print(f"Error: Target path does not exist: {args.target}")
        sys.exit(1)

    # Find config file if not specified
    config = args.config or find_puppet_lint_rc(args.target)

    if config:
        print(f"Using config: {config}")

    results = run_puppet_lint(args.target, args.fix, config)

    if args.json:
        print(json.dumps([r.to_dict() for r in results], indent=2))
    else:
        print(format_results(results, args.target))

    # Exit with error code if issues found
    sys.exit(1 if results else 0)


if __name__ == "__main__":
    main()
