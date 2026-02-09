#!/usr/bin/env python3
"""
Puppet Best Practices Checker - Validate against Puppet style guide

This script checks Puppet manifests against best practices and style guidelines.
It validates naming conventions, resource ordering, parameter handling, and more.

Usage:
    python3 check_best_practices.py <path-to-manifest-or-directory>
    python3 check_best_practices.py --style-guide <path-to-style-guide.md> <target>
"""

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
from dataclasses import dataclass


@dataclass
class PracticeIssue:
    """Represents a best practice violation."""
    file: str
    line: int
    severity: str  # critical, warning, info
    category: str
    message: str
    suggestion: str = ""

    def to_dict(self) -> Dict:
        return {
            "file": self.file,
            "line": self.line,
            "severity": self.severity,
            "category": self.category,
            "message": self.message,
            "suggestion": self.suggestion
        }


class BestPracticeChecker:
    """Check Puppet manifests against best practices."""

    # Regex patterns
    CLASS_DEF = re.compile(r'^class\s+([a-z][a-z0-9_:]*)\s*(?:\(|\s*\{)', re.MULTILINE)
    RESOURCE_DECL = re.compile(r'^\s*([a-z][a-z0-9_]*)\s*\{', re.MULTILINE)
    PARAMETER_DEF = re.compile(r'(\$\w+)\s*=\s*([^,)]+)', re.MULTILINE)
    HIERA_LOOKUP = re.compile(r'hiera\([\'"]([^\'"]+)[\'"]\s*,\s*([^)]+)\)', re.MULTILINE)
    AUTO_LOOKUP = re.compile(r'(\$\w+)\s*=', re.MULTILINE)
    STRING_QUOTE_DOUBLE = re.compile(r'^\s*\w+\s*\{[^}]*"[^"]*"[^}]*\}', re.MULTILINE)
    SELECTOR_STMT = re.compile(r'\$[a-z_]+\s*\?\s*\{[^}]+\}', re.MULTILINE | re.DOTALL)
    CASE_STMT = re.compile(r'case\s*\$[^{]+\{[^}]+\}', re.MULTILINE | re.DOTALL)

    def __init__(self, style_guide_path: Path = None):
        self.issues: List[PracticeIssue] = []
        self.style_guide_rules: Dict[str, List[str]] = {}
        if style_guide_path and style_guide_path.exists():
            self._load_style_guide(style_guide_path)

    def _load_style_guide(self, path: Path):
        """Load custom style guide rules from markdown file."""
        content = path.read_text()
        # Simple parsing - in production, use proper markdown parser
        current_section = "general"
        for line in content.splitlines():
            if line.startswith("##"):
                current_section = line.lower().replace("##", "").strip()
            elif line.strip().startswith("-"):
                rule = line.strip().lstrip("-").strip()
                if current_section not in self.style_guide_rules:
                    self.style_guide_rules[current_section] = []
                self.style_guide_rules[current_section].append(rule)

    def check_naming_conventions(self, content: str, filepath: Path) -> List[PracticeIssue]:
        """Check naming conventions."""
        issues = []
        lines = content.splitlines()

        # Check class names (should be lowercase with underscores)
        for match in self.CLASS_DEF.finditer(content):
            class_name = match.group(1)
            line_no = content[:match.start()].count('\n') + 1
            if '::' in class_name:
                parts = class_name.split('::')
                for part in parts:
                    if not re.match(r'^[a-z][a-z0-9_]*$', part):
                        issues.append(PracticeIssue(
                            file=str(filepath),
                            line=line_no,
                            severity="warning",
                            category="naming",
                            message=f"Class name '{class_name}' should use lowercase with underscores",
                            suggestion=f"Rename to: {self._suggest_class_name(class_name)}"
                        ))
                        break

        # Check resource names (should be lowercase with underscores)
        for i, line in enumerate(lines, 1):
            for match in self.RESOURCE_DECL.finditer(line):
                resource_type = match.group(1)
                if not re.match(r'^[a-z][a-z0-9_]*$', resource_type):
                    issues.append(PracticeIssue(
                        file=str(filepath),
                        line=i,
                        severity="warning",
                        category="naming",
                        message=f"Resource type '{resource_type}' should use lowercase",
                        suggestion=f"Use: {resource_type.lower()}"
                    ))

        return issues

    def check_string_quotes(self, content: str, filepath: Path) -> List[PracticeIssue]:
        """Check string quote usage - prefer single quotes."""
        issues = []
        lines = content.splitlines()

        for i, line in enumerate(lines, 1):
            # Find double-quoted strings that don't contain variables
            double_quotes = re.findall(r'"([^$"]*)"', line)
            for _ in double_quotes:
                # This is a simplified check
                if '$' not in line and '\\' not in line:
                    issues.append(PracticeIssue(
                        file=str(filepath),
                        line=i,
                        severity="info",
                        category="style",
                        message="Prefer single quotes for static strings",
                        suggestion="Replace with single quotes unless string contains variables or escapes"
                    ))

        return issues

    def check_parameter_defaults(self, content: str, filepath: Path) -> List[PracticeIssue]:
        """Check parameter default values."""
        issues = []

        # Look for parameters without type specifications
        param_pattern = re.compile(r'^\s*(\$\w+)\s*=', re.MULTILINE)
        for match in param_pattern.finditer(content):
            param = match.group(1)
            line_no = content[:match.start()].count('\n') + 1

            # Check if this parameter is in a class definition with type
            # This is simplified - proper parsing would need full grammar
            issues.append(PracticeIssue(
                file=str(filepath),
                line=line_no,
                severity="info",
                category="parameters",
                message=f"Parameter '{param}' should have a type specification",
                suggestion="Add type: e.g., 'String $param_name ='"
            ))

        return issues

    def check_hiera_lookups(self, content: str, filepath: Path) -> List[PracticeIssue]:
        """Check for old-style hiera() function calls."""
        issues = []

        for match in self.HIERA_LOOKUP.finditer(content):
            line_no = content[:match.start()].count('\n') + 1
            key = match.group(1)
            issues.append(PracticeIssue(
                file=str(filepath),
                line=line_no,
                severity="warning",
                category="hiera",
                message=f"Use automatic parameter lookup instead of hiera() function",
                suggestion=f"Replace with automatic lookup: use 'class { 'myclass::${key}': }' in Hiera data"
            ))

        return issues

    def check_resource_ordering(self, content: str, filepath: Path) -> List[PracticeIssue]:
        """Check for implicit ordering issues."""
        issues = []
        lines = content.splitlines()

        # Look for resources without explicit ordering that might conflict
        resource_types = defaultdict(list)
        for i, line in enumerate(lines, 1):
            match = self.RESOURCE_DECL.search(line)
            if match:
                resource_type = match.group(1)
                resource_types[resource_type].append((i, line))

        # Check for multiple packages/files that might need ordering
        if len(resource_types.get('package', [])) > 3:
            issues.append(PracticeIssue(
                file=str(filepath),
                line=resource_types['package'][0][0],
                severity="info",
                category="ordering",
                message=f"Multiple package resources - consider explicit ordering",
                suggestion="Use chaining or require/contain relationships"
            ))

        return issues

    def _suggest_class_name(self, name: str) -> str:
        """Suggest corrected class name."""
        parts = name.split('::')
        corrected = []
        for part in parts:
            # Convert CamelCase to snake_case
            s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', part)
            corrected.append(re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower())
        return '::'.join(corrected)

    def check_file(self, filepath: Path) -> List[PracticeIssue]:
        """Run all checks on a single file."""
        try:
            content = filepath.read_text()
        except Exception:
            return []

        issues = []
        issues.extend(self.check_naming_conventions(content, filepath))
        issues.extend(self.check_string_quotes(content, filepath))
        issues.extend(self.check_parameter_defaults(content, filepath))
        issues.extend(self.check_hiera_lookups(content, filepath))
        issues.extend(self.check_resource_ordering(content, filepath))

        return issues

    def check_directory(self, directory: Path) -> List[PracticeIssue]:
        """Check all .pp files in directory."""
        all_issues = []
        for pp_file in directory.rglob("*.pp"):
            all_issues.extend(self.check_file(pp_file))
        return all_issues


def format_results(issues: List[PracticeIssue], target: Path) -> str:
    """Format best practice check results."""
    if not issues:
        return f"✅ No best practice violations found in {target}"

    output = [f"## Puppet Best Practices Check: {target}\n"]

    # Group by category
    by_category: Dict[str, List[PracticeIssue]] = {}
    for issue in issues:
        if issue.category not in by_category:
            by_category[issue.category] = []
        by_category[issue.category].append(issue)

    # Sort categories by severity
    for category, cat_issues in sorted(by_category.items()):
        # Sort by severity
        critical = [i for i in cat_issues if i.severity == "critical"]
        warnings = [i for i in cat_issues if i.severity == "warning"]
        info = [i for i in cat_issues if i.severity == "info"]

        if critical:
            output.append(f"### {category.upper()} - CRITICAL")
            for issue in critical:
                output.append(f"- **{issue.message}** at `{issue.file}:{issue.line}`")
                if issue.suggestion:
                    output.append(f"  💡 {issue.suggestion}")

        if warnings:
            output.append(f"\n### {category.capitalize()} - WARNING")
            for issue in warnings:
                output.append(f"- **{issue.message}** at `{issue.file}:{issue.line}`")
                if issue.suggestion:
                    output.append(f"  💡 {issue.suggestion}")

        if info and not critical and not warnings:
            output.append(f"\n### {category.capitalize()} - INFO")
            for issue in info[:5]:  # Limit info messages
                output.append(f"- **{issue.message}** at `{issue.file}:{issue.line}`")

    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(
        description="Check Puppet manifests against best practices"
    )
    parser.add_argument(
        "target",
        type=Path,
        help="Path to Puppet manifest or directory"
    )
    parser.add_argument(
        "--style-guide",
        type=Path,
        help="Path to custom style guide markdown file"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON"
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Write output to file"
    )

    args = parser.parse_args()

    if not args.target.exists():
        print(f"Error: Target path does not exist: {args.target}")
        return 1

    checker = BestPracticeChecker(args.style_guide)

    if args.target.is_file() and args.target.suffix == ".pp":
        issues = checker.check_file(args.target)
    else:
        issues = checker.check_directory(args.target)

    if args.json:
        print(json.dumps([i.to_dict() for i in issues], indent=2))
    else:
        output = format_results(issues, args.target)
        if args.output:
            args.output.write_text(output)
            print(f"Check results written to: {args.output}")
        else:
            print(output)

    return 1 if issues else 0


if __name__ == "__main__":
    from collections import defaultdict
    exit(main())
