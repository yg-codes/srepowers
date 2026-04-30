#!/usr/bin/env python3
"""
Puppet Error Tracer - Parse errors and suggest fixes

This script analyzes Puppet error messages and stack traces to identify
root causes and suggest fixes based on common issues and patterns.

Usage:
    python3 trace_error.py "Error message from puppet"
    python3 trace_error.py --file <path-to-error-log>
    python3 trace_error.py --interactive
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass


@dataclass
class ErrorAnalysis:
    """Represents an error analysis result."""
    error_type: str
    severity: str
    message: str
    cause: str
    suggestions: List[str]
    related_files: List[str] = None

    def __str__(self) -> str:
        output = [
            f"## Error Analysis: {self.error_type}",
            f"\n**Severity**: {self.severity.upper()}",
            f"\n### Cause",
            self.cause,
            f"\n### Suggestions"
        ]
        for i, suggestion in enumerate(self.suggestions, 1):
            output.append(f"{i}. {suggestion}")

        if self.related_files:
            output.append(f"\n### Related Files")
            for f in self.related_files:
                output.append(f"- {f}")

        return "\n".join(output)


class CommonIssuesDatabase:
    """Database of common Puppet issues and solutions."""

    ISSUES = {
        "duplicate_declaration": {
            "patterns": [
                r'is already declared',
                r'cannot reassign',
                r'Duplicate declaration'
            ],
            "cause": "The same resource is being declared multiple times in the catalog.",
            "suggestions": [
                "Check if the resource is declared in multiple classes or manifests",
                "Use resource collectors or virtual resources if you need multiple declarations",
                "Add a unique name or title variant using namevar",
                "Review include/require chains that might cause duplicate compilation"
            ]
        },
        "undefined_variable": {
            "patterns": [
                r'undefined variable',
                r'Unknown variable',
                r'parameter.*not provided'
            ],
            "cause": "A variable or parameter is being used but hasn't been defined.",
            "suggestions": [
                "Check the variable name for typos",
                "Ensure the parameter is defined in the class signature",
                "Verify the variable is set in Hiera data with correct key",
                "Check variable scope - top-scope vs. class scope",
                "Use $::variable for fully qualified top-scope access"
            ]
        },
        "dependency_cycle": {
            "patterns": [
                r'dependency cycle',
                r'circular dependency',
                r'found a cycle'
            ],
            "cause": "Resources or classes have circular dependencies through require/contain/include.",
            "suggestions": [
                "Review the dependency chain shown in the error",
                "Break the cycle by removing one dependency relationship",
                "Use chaining arrows (-> ~>) to make ordering explicit",
                "Consider if all dependencies are necessary - Puppet is declarative"
            ]
        },
        "file_not_found": {
            "patterns": [
                r'could not find file',
                r'No such file or directory',
                r'template.*not found'
            ],
            "cause": "Puppet cannot locate a referenced file or template.",
            "suggestions": [
                "Check the file path is correct relative to module path",
                "Verify the file exists in the module's files/ or templates/ directory",
                "Use modulePath('module_name', 'path/to/file') syntax",
                "Check for case sensitivity issues (Linux is case-sensitive)",
                "Ensure the module is installed and in the modulepath"
            ]
        },
        "syntax_error": {
            "patterns": [
                r'syntax error',
                r'unexpected',
                r'expected.*got'
            ],
            "cause": "Puppet manifest has invalid syntax.",
            "suggestions": [
                "Check for missing braces, brackets, or parentheses",
                "Ensure proper comma separation in arrays and parameters",
                "Verify quoted strings are closed",
                "Run puppet-lint to catch syntax issues before applying",
                "Check line number in error for exact location"
            ]
        },
        "hiera_lookup_failure": {
            "patterns": [
                r'key not found',
                r'Hiera data not found',
                r'no key.*in data'
            ],
            "cause": "Hiera lookup failed to find the requested key.",
            "suggestions": [
                "Verify the key exists in Hiera data files",
                "Check hiera.yaml hierarchy configuration",
                "Ensure the correct environment/layer is being used",
                "Use hiera() with default value: hiera('key', 'default')",
                "Check YAML syntax in Hiera data files (use yamllint)"
            ]
        },
        "catalog_compilation_failed": {
            "patterns": [
                r'could not compile catalog',
                r'catalog compilation failed',
                r'failed to compile'
            ],
            "cause": "General catalog compilation failure - usually a syntax or dependency issue.",
            "suggestions": [
                "Review the full error output for specific cause",
                "Check for syntax errors with puppet parser validate",
                "Run puppet-lint on modified manifests",
                "Test with --noop to see changes without applying",
                "Check for missing dependencies or broken module paths"
            ]
        },
        "package_not_installed": {
            "patterns": [
                r'package.*not installed',
                r'package provider.*not found',
                r'could not find package'
            ],
            "cause": "Package manager cannot find the specified package.",
            "suggestions": [
                "Verify package name is correct for the target OS",
                "Check the package repository is configured",
                "Ensure the package provider is correct (apt, yum, etc.)",
                "Use package resource with 'ensure => installed' for idempotency",
                "Test package name with: apt-cache search <package> or yum search <package>"
            ]
        },
        "permission_denied": {
            "patterns": [
                r'permission denied',
                r'could not create.*permission',
                r'access denied'
            ],
            "cause": "Puppet or the target resource has insufficient permissions.",
            "suggestions": [
                "Check Puppet agent is running with sufficient privileges (usually root)",
                "Verify file/directory permissions allow Puppet to modify",
                "Review exec resources - user/group might lack permissions",
                "Check SELinux/AppArmor contexts if applicable",
                "Ensure parent directories allow traversal"
            ]
        }
    }

    @classmethod
    def analyze(cls, error_message: str) -> Optional[ErrorAnalysis]:
        """Analyze an error message and return diagnosis."""
        error_lower = error_message.lower()

        for error_type, data in cls.ISSUES.items():
            for pattern in data["patterns"]:
                if re.search(pattern, error_message, re.IGNORECASE):
                    # Extract related files if present
                    related_files = re.findall(r'at ([^\s:]+\.pp:\d+)', error_message)
                    related_files = list(set(related_files))  # Deduplicate

                    return ErrorAnalysis(
                        error_type=error_type.replace('_', ' ').title(),
                        severity="critical" if error_type in ["dependency_cycle", "syntax_error"] else "warning",
                        message=error_message[:200] + "..." if len(error_message) > 200 else error_message,
                        cause=data["cause"],
                        suggestions=data["suggestions"],
                        related_files=related_files if related_files else None
                    )

        # Fallback for unknown errors
        return ErrorAnalysis(
            error_type="Unknown Error",
            severity="info",
            message=error_message[:200] + "..." if len(error_message) > 200 else error_message,
            cause="This error doesn't match known patterns in the database.",
            suggestions=[
                "Review the full error message for specific details",
                "Search the error message in Puppet documentation",
                "Check Puppet logs for additional context",
                "Run with --debug flag for more detailed output"
            ]
        )


def parse_error_file(filepath: Path) -> List[str]:
    """Extract error messages from a log file."""
    content = filepath.read_text()
    errors = []

    # Common Puppet error patterns in logs
    error_patterns = [
        r'Error:.*',
        r'err:.*',
        r'Failure:.*',
        r'Warning:.*',
    ]

    for pattern in error_patterns:
        matches = re.findall(pattern, content, re.MULTILINE)
        errors.extend(matches)

    return errors


def interactive_mode():
    """Interactive error analysis mode."""
    print("=== Puppet Error Tracer - Interactive Mode ===")
    print("Paste error messages (Ctrl+D or Ctrl+Z to finish):\n")

    error_lines = []
    try:
        while True:
            line = input()
            error_lines.append(line)
    except EOFError:
        pass

    if not error_lines:
        print("No error input provided.")
        return

    error_message = "\n".join(error_lines)
    analysis = CommonIssuesDatabase.analyze(error_message)

    print("\n" + "="*60)
    print(analysis)
    print("="*60)


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Puppet errors and suggest fixes"
    )
    parser.add_argument(
        "error",
        nargs="?",
        help="Error message to analyze (or use --file)"
    )
    parser.add_argument(
        "--file",
        type=Path,
        help="Read error from log file"
    )
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Interactive mode - paste error to analyze"
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="Write analysis to file"
    )

    args = parser.parse_args()

    # Interactive mode
    if args.interactive:
        interactive_mode()
        return 0

    # File mode
    if args.file:
        if not args.file.exists():
            print(f"Error: File not found: {args.file}")
            return 1
        errors = parse_error_file(args.file)
        if not errors:
            print("No errors found in file.")
            return 0
        # Analyze first error
        analysis = CommonIssuesDatabase.analyze(errors[0])
    # Direct error message mode
    elif args.error:
        analysis = CommonIssuesDatabase.analyze(args.error)
    else:
        parser.print_help()
        return 1

    result = str(analysis)

    if args.output:
        args.output.write_text(result)
        print(f"Analysis written to: {args.output}")
    else:
        print(result)

    return 0


if __name__ == "__main__":
    sys.exit(main())
