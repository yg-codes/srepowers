#!/usr/bin/env python3
"""
SREPowers Skill Generator

Creates scaffolding for new SREPowers skills including:
- SKILL.md with proper frontmatter
- Command wrapper file
- References directory (optional)
- Test script template (optional)

Usage:
    python scripts/create-skill.py
    python scripts/create-skill.py --name my-skill --description "My skill description"
"""

import argparse
import os
import re
import sys
from datetime import datetime
from pathlib import Path


def slugify(name: str) -> str:
    """Convert name to kebab-case."""
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')


def validate_skill_name(name: str) -> bool:
    """Validate skill name follows conventions."""
    if not name:
        return False
    # Must be kebab-case: lowercase with hyphens
    if not re.match(r'^[a-z][a-z0-9-]*$', name):
        return False
    # No consecutive hyphens
    if '--' in name:
        return False
    # Must not start or end with hyphen
    if name.startswith('-') or name.endswith('-'):
        return False
    return True


def get_skill_category() -> str:
    """Interactive skill category selection."""
    categories = {
        '1': ('core', 'Core Operations (TDO, SDO, verification)'),
        '2': ('planning', 'Planning (brainstorming, writing plans)'),
        '3': ('infrastructure', 'Infrastructure Administration (PVE, Puppet, etc.)'),
        '4': ('cicd', 'CI/CD & Pipelines'),
        '5': ('domain', 'Domain Expertise (architecture, cloud, security)'),
        '6': ('incident', 'Incident Management'),
        '7': ('other', 'Other'),
    }

    print("\nSelect skill category:")
    for key, (_, desc) in categories.items():
        print(f"  {key}. {desc}")

    while True:
        choice = input("\nChoice (1-7): ").strip()
        if choice in categories:
            return categories[choice][0]
        print("Invalid choice. Please enter 1-7.")


def create_skill_directory(skill_name: str) -> Path:
    """Create the skill directory structure."""
    repo_root = Path(__file__).parent.parent
    skill_dir = repo_root / "skills" / skill_name

    if skill_dir.exists():
        print(f"Error: Skill directory already exists: {skill_dir}")
        sys.exit(1)

    skill_dir.mkdir(parents=True)
    print(f"Created: {skill_dir}")
    return skill_dir


def create_skill_md(skill_dir: Path, skill_name: str, description: str, category: str) -> None:
    """Create SKILL.md with proper frontmatter and template."""
    skill_md = skill_dir / "SKILL.md"

    # Get template based on category
    template = get_skill_template(category, skill_name, description)

    skill_md.write_text(template)
    print(f"Created: {skill_md}")


def get_skill_template(category: str, skill_name: str, description: str) -> str:
    """Get appropriate template based on category."""

    base_frontmatter = f"""---
name: {skill_name}
description: {description}
---

"""

    # Core operations template (TDO-style)
    core_template = base_frontmatter + f"""# {skill_name.replace('-', ' ').title()}

## Overview

[Brief description of what this skill does and its core principle]

**Core principle:** [One-sentence guiding principle]

**Announce at start:** "I'm using the {skill_name} skill to [action]."

## When to Use

**Always:**
- [Situation 1]
- [Situation 2]

**Exceptions:**
- [Exception 1]

## The Process

### Step 1: [First Step]

[Description]

```bash
# Example command
command --example
```

### Step 2: [Second Step]

[Description]

## SRE Principles

### Safety First
- [Safety consideration 1]
- [Safety consideration 2]

### Structured Output
- [Output format guidance]

### Evidence-Driven
- [Evidence requirements]

### Audit-Ready
- [Audit trail requirements]

### Communication
- [Communication guidance]

## Integration

**Called by:**
- [Other skills that use this]

**Pairs with:**
- [Related skills]
"""

    # Domain expertise template
    domain_template = base_frontmatter + f"""# {skill_name.replace('-', ' ').title()}

## Overview

[Brief description of domain expertise area]

## When to Use

**Use when:** [Specific scenarios]

**Focus:** [Key areas of expertise]

## Key Concepts

### Concept 1

[Explanation]

### Concept 2

[Explanation]

## Best Practices

1. [Best practice 1]
2. [Best practice 2]

## Common Patterns

### Pattern 1

```[language]
# Example code/config
```

## Anti-Patterns to Avoid

- [Anti-pattern 1]: [Why it's bad]
- [Anti-pattern 2]: [Why it's bad]

## SRE Principles

### Safety First
- [Safety consideration]

### Structured Output
- [Output format]

### Evidence-Driven
- [Evidence requirements]

### Audit-Ready
- [Audit requirements]

### Communication
- [Communication approach]

## References

See `references/` directory for detailed documentation.
"""

    templates = {
        'core': core_template,
        'planning': core_template,
        'infrastructure': domain_template,
        'cicd': domain_template,
        'domain': domain_template,
        'incident': core_template,
        'other': core_template,
    }

    return templates.get(category, core_template)


def create_command_file(skill_name: str, description: str) -> None:
    """Create command wrapper file."""
    repo_root = Path(__file__).parent.parent
    command_file = repo_root / "commands" / f"{skill_name}.md"

    if command_file.exists():
        print(f"Warning: Command file already exists: {command_file}")
        return

    content = f"""---
description: "{description}"
disable-model-invocation: true
---

Invoke the srepowers:{skill_name} skill and follow it exactly as presented to you
"""

    command_file.write_text(content)
    print(f"Created: {command_file}")


def create_references_dir(skill_dir: Path) -> None:
    """Create references directory."""
    refs_dir = skill_dir / "references"
    refs_dir.mkdir()

    # Create a README explaining the directory
    readme = refs_dir / "README.md"
    readme.write_text("""# References

This directory contains reference materials for this skill:

- Documentation
- Example configurations
- Best practice guides
- External resources

Add relevant files here to support the skill.
""")
    print(f"Created: {refs_dir}/")


def create_test_template(skill_name: str) -> None:
    """Create test script template."""
    repo_root = Path(__file__).parent.parent
    test_file = repo_root / "tests" / "claude-code" / f"test-{skill_name}.sh"

    if test_file.exists():
        print(f"Warning: Test file already exists: {test_file}")
        return

    content = f"""#!/usr/bin/env bash
# Test: {skill_name} skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" \&\& pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: {skill_name} skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the {skill_name} skill? Describe its purpose briefly." 30)

if assert_contains "$output" "{skill_name}" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify core concept
echo "Test 2: Core concept..."

# Add specific test for your skill's core concept
# output=$(run_claude "Question about skill?" 30)
# if assert_contains "$output" "expected" "Description"; then
#     : # pass
# else
#     exit 1
# fi

echo ""

echo "========================================"
echo "All tests passed!"
echo "========================================"
"""

    test_file.write_text(content)
    test_file.chmod(0o755)
    print(f"Created: {test_file}")


def update_readme(skill_name: str, description: str) -> None:
    """Add skill to README.md."""
    repo_root = Path(__file__).parent.parent
    readme = repo_root / "README.md"

    if not readme.exists():
        print(f"Warning: README.md not found at {readme}")
        return

    # Read current content
    content = readme.read_text()

    # Find the appropriate section to add (before "## Commands" or at end)
    insert_marker = "## Commands"
    if insert_marker in content:
        skill_entry = f"""### {skill_name}

**Use when:** {description}

**Core principle:** [Add core principle]

---

"""
        # Insert before ## Commands
        content = content.replace(insert_marker, skill_entry + insert_marker)
        readme.write_text(content)
        print(f"Updated: {readme} (added skill description)")
    else:
        print(f"Warning: Could not find insertion point in README.md")


def main():
    parser = argparse.ArgumentParser(
        description="Generate scaffolding for new SREPowers skills"
    )
    parser.add_argument(
        "--name",
        help="Skill name (kebab-case, e.g., 'my-new-skill')"
    )
    parser.add_argument(
        "--description",
        help="Skill description for frontmatter"
    )
    parser.add_argument(
        "--category",
        choices=['core', 'planning', 'infrastructure', 'cicd', 'domain', 'incident', 'other'],
        help="Skill category"
    )
    parser.add_argument(
        "--no-references",
        action="store_true",
        help="Skip creating references directory"
    )
    parser.add_argument(
        "--no-test",
        action="store_true",
        help="Skip creating test template"
    )
    parser.add_argument(
        "--no-readme",
        action="store_true",
        help="Skip updating README.md"
    )

    args = parser.parse_args()

    print("=" * 50)
    print("SREPowers Skill Generator")
    print("=" * 50)

    # Get skill name
    skill_name = args.name
    if not skill_name:
        skill_name = input("\nSkill name (kebab-case, e.g., 'my-new-skill'): ").strip()

    if not validate_skill_name(skill_name):
        print(f"Error: Invalid skill name '{skill_name}'")
        print("Skill names must:")
        print("  - Start with a lowercase letter")
        print("  - Contain only lowercase letters, numbers, and hyphens")
        print("  - Not have consecutive hyphens")
        print("  - Examples: 'test-driven-operation', 'kubernetes-specialist'")
        sys.exit(1)

    # Get description
    description = args.description
    if not description:
        description = input("\nSkill description: ").strip()

    if not description:
        print("Error: Description is required")
        sys.exit(1)

    # Ensure description starts with "Use when"
    if not description.lower().startswith("use when"):
        description = f"Use when {description}"

    # Get category
    category = args.category
    if not category:
        category = get_skill_category()

    print(f"\nCreating skill: {skill_name}")
    print(f"Description: {description}")
    print(f"Category: {category}")
    print()

    # Create skill directory and files
    skill_dir = create_skill_directory(skill_name)
    create_skill_md(skill_dir, skill_name, description, category)
    create_command_file(skill_name, description)

    if not args.no_references:
        create_references_dir(skill_dir)

    if not args.no_test:
        create_test_template(skill_name)

    if not args.no_readme:
        update_readme(skill_name, description)

    print("\n" + "=" * 50)
    print("Skill created successfully!")
    print("=" * 50)
    print(f"\nNext steps:")
    print(f"1. Edit: skills/{skill_name}/SKILL.md")
    print(f"2. Add documentation to: skills/{skill_name}/references/")
    if not args.no_test:
        print(f"3. Customize tests: tests/claude-code/test-{skill_name}.sh")
    print(f"4. Test the skill: /{skill_name}")
    print(f"5. Update README.md with detailed description")
    print(f"6. Bump version in .claude-plugin/plugin.json")


if __name__ == "__main__":
    main()
