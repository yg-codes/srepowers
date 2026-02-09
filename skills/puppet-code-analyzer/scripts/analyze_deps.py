#!/usr/bin/env python3
"""
Puppet Dependency Analyzer - Parse and visualize Puppet module dependencies

This script analyzes Puppet manifests to build dependency graphs between classes,
detect circular dependencies, and identify missing or unused dependencies.

Usage:
    python3 analyze_deps.py <path-to-module-or-manifests>
    python3 analyze_deps.py --mermaid <path-to-module-or-manifests>
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Set, Tuple
from collections import defaultdict


class DependencyGraph:
    """Represents Puppet class dependencies."""

    def __init__(self):
        self.nodes: Set[str] = set()
        self.edges: List[Tuple[str, str, str]] = []  # (from, to, relationship)
        self.adjacency: Dict[str, Set[str]] = defaultdict(set)

    def add_class(self, class_name: str):
        """Add a class to the graph."""
        self.nodes.add(class_name)

    def add_dependency(self, source: str, target: str, relationship: str):
        """Add a dependency edge."""
        self.nodes.add(source)
        self.nodes.add(target)
        self.edges.append((source, target, relationship))
        self.adjacency[source].add(target)

    def find_circular_dependencies(self) -> List[List[str]]:
        """Detect circular dependencies using DFS."""
        cycles = []
        visited = set()
        rec_stack = set()
        path = []

        def dfs(node):
            visited.add(node)
            rec_stack.add(node)
            path.append(node)

            for neighbor in self.adjacency[node]:
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    # Found a cycle
                    cycle_start = path.index(neighbor)
                    cycles.append(path[cycle_start:] + [neighbor])
                    return True

            path.pop()
            rec_stack.remove(node)
            return False

        for node in self.nodes:
            if node not in visited:
                dfs(node)

        return cycles

    def find_unused_classes(self) -> Set[str]:
        """Find classes that are never referenced."""
        referenced = {target for _, target, _ in self.edges}
        defined = self.nodes - referenced
        return defined

    def to_mermaid(self) -> str:
        """Generate Mermaid diagram."""
        lines = ["graph TD"]

        # Add edges
        edge_labels = {
            "include": "--include-->",
            "require": "==require==>",
            "contain": "==contain==>",
            "notify": "-.notify.->",
            "subscribe": "-.subscribe.->"
        }

        for source, target, relationship in self.edges:
            arrow = edge_labels.get(relationship, "-->")
            lines.append(f"    {source.replace('::', '_')} {arrow} {target.replace('::', '_')}")

        return "\n".join(lines)


class PuppetParser:
    """Parse Puppet manifests to extract dependencies."""

    # Pattern to match class definitions
    CLASS_DEF = re.compile(r'class\s+([a-z][a-z0-9_:]*)\s*(?:\(|\s*\{|\s*$)', re.MULTILINE)

    # Patterns for dependency relationships
    INCLUDES = re.compile(r'include\s+([a-z][a-z0-9_:]*)')
    REQUIRE = re.compile(r'Require\s*\(\s*[\'"]?([a-z][a-z0-9_:]*)')
    CONTAIN = re.compile(r'Contain\s*\(\s*[\'"]?([a-z][a-z0-9_:]*)')
    NOTIFY = re.compile(r'Notify\s*\(\s*[\'"]?([a-z][a-z0-9_:]*)')
    SUBSCRIBE = re.compile(r'Subscribe\s*\(\s*[\'"]?([a-z][a-z0-9_:]*)')

    # Chain arrows
    CHAIN_ARROW = re.compile(r'([a-z][a-z0-9_:]*)\s*(->|~>|<-|<~)\s*([a-z][a-z0-9_:]*)')

    def __init__(self):
        self.graph = DependencyGraph()

    def parse_file(self, filepath: Path) -> Tuple[str, Set[str]]:
        """Parse a single Puppet manifest file."""
        try:
            content = filepath.read_text()
        except Exception as e:
            print(f"Warning: Could not read {filepath}: {e}")
            return "", set()

        # Extract class name
        class_match = self.CLASS_DEF.search(content)
        current_class = class_match.group(1) if class_match else None

        if not current_class:
            return "", set()

        self.graph.add_class(current_class)
        dependencies = set()

        # Extract include statements
        for match in self.INCLUDES.finditer(content):
            dep = match.group(1)
            dependencies.add(dep)
            self.graph.add_dependency(current_class, dep, "include")

        # Extract require relationships
        for match in self.REQUIRE.finditer(content):
            dep = match.group(1)
            dependencies.add(dep)
            self.graph.add_dependency(current_class, dep, "require")

        # Extract contain relationships
        for match in self.CONTAIN.finditer(content):
            dep = match.group(1)
            dependencies.add(dep)
            self.graph.add_dependency(current_class, dep, "contain")

        # Extract notify relationships
        for match in self.NOTIFY.finditer(content):
            dep = match.group(1)
            dependencies.add(dep)
            self.graph.add_dependency(current_class, dep, "notify")

        # Extract subscribe relationships
        for match in self.SUBSCRIBE.finditer(content):
            dep = match.group(1)
            dependencies.add(dep)
            self.graph.add_dependency(current_class, dep, "subscribe")

        # Extract chain arrows
        for match in self.CHAIN_ARROW.finditer(content):
            source, arrow, target = match.groups()
            if arrow in ["->", "~>"]:
                relationship = "require" if arrow == "->" else "notify"
                self.graph.add_dependency(current_class, target, relationship)
                dependencies.add(target)
            elif arrow in ["<-", "<~"]:
                relationship = "require" if arrow == "<-" else "subscribe"
                self.graph.add_dependency(source, current_class, relationship)
                dependencies.add(source)

        return current_class, dependencies

    def parse_directory(self, directory: Path) -> Dict[str, Set[str]]:
        """Parse all .pp files in a directory."""
        all_dependencies = {}

        for pp_file in directory.rglob("*.pp"):
            class_name, deps = self.parse_file(pp_file)
            if class_name:
                all_dependencies[class_name] = deps

        return all_dependencies


def format_analysis(graph: DependencyGraph, dependencies: Dict[str, Set[str]]) -> str:
    """Format dependency analysis results."""
    output = ["## Puppet Dependency Analysis\n"]

    # Summary stats
    output.append(f"### Summary")
    output.append(f"- **Classes**: {len(graph.nodes)}")
    output.append(f"- **Dependencies**: {len(graph.edges)}")

    # Check for issues
    cycles = graph.find_circular_dependencies()
    unused = graph.find_unused_classes()

    if cycles:
        output.append(f"\n### ⚠️ CIRCULAR DEPENDENCIES DETECTED")
        for i, cycle in enumerate(cycles, 1):
            output.append(f"{i}. {' → '.join(cycle)}")

    if unused:
        output.append(f"\n### ℹ️ Potentially Unused Classes")
        for cls in sorted(unused):
            output.append(f"- {cls}")

    # Dependency breakdown
    output.append(f"\n### Class Dependencies")
    for source in sorted(dependencies.keys()):
        deps = dependencies[source]
        if deps:
            output.append(f"\n**{source}**:")
            for dep in sorted(deps):
                output.append(f"  → {dep}")

    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Puppet module dependencies"
    )
    parser.add_argument(
        "target",
        type=Path,
        help="Path to Puppet module or manifests directory"
    )
    parser.add_argument(
        "--mermaid",
        action="store_true",
        help="Output Mermaid diagram"
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

    parser_obj = PuppetParser()
    dependencies = parser_obj.parse_directory(args.target)

    if args.mermaid:
        output = parser_obj.graph.to_mermaid()
    else:
        output = format_analysis(parser_obj.graph, dependencies)

    if args.output:
        args.output.write_text(output)
        print(f"Analysis written to: {args.output}")
    else:
        print(output)

    return 1 if parser_obj.graph.find_circular_dependencies() else 0


if __name__ == "__main__":
    exit(main())
