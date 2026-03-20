---
name: python-pro
description: Use when building Python 3.11+ applications requiring type safety, async programming, or production-grade patterns. Invoke for type hints, pytest, async/await, dataclasses, mypy configuration.
---

# Python Pro

## When to Use This Skill

- Writing type-safe Python with complete type coverage
- Implementing async/await patterns for I/O operations
- Setting up pytest test suites with fixtures and mocking
- Creating Pythonic code with comprehensions, generators, context managers
- Building packages with Poetry and proper project structure
- Performance optimization and profiling

## Core Workflow

1. **Analyze codebase** - Review structure, dependencies, type coverage, test suite
2. **Design interfaces** - Define protocols, dataclasses, type aliases
3. **Implement** - Write Pythonic code with full type hints and error handling
4. **Test** - Create comprehensive pytest suite with >90% coverage
5. **Validate** - Run mypy, black, ruff; ensure quality standards met

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Type System | `references/type-system.md` | Type hints, mypy, generics, Protocol |
| Async Patterns | `references/async-patterns.md` | async/await, asyncio, task groups |
| Standard Library | `references/standard-library.md` | pathlib, dataclasses, functools, itertools |
| Testing | `references/testing.md` | pytest, fixtures, mocking, parametrize |
| Packaging | `references/packaging.md` | poetry, pip, pyproject.toml, distribution |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Type hints aren't needed here" | Type hints on all public functions. Catches bugs early. |
| "Just catch Exception" | Catch specific exceptions. Broad catches hide bugs. |
| "requirements.txt is fine" | Use pyproject.toml with pinned deps. Reproducibility matters. |
| "This doesn't need async" | Profile first. Async for I/O-bound, multiprocessing for CPU. |
| "I'll add tests later" | Write tests alongside code. Untested code is broken code. |
| "Global state is fine for this" | Dependency injection. Global state makes testing impossible. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Python features, provide:
1. Module file with complete type hints
2. Test file with pytest fixtures
3. Type checking confirmation (mypy --strict passes)
4. Brief explanation of Pythonic patterns used

## Knowledge Reference

Python 3.11+, typing module, mypy, pytest, black, ruff, dataclasses, async/await, asyncio, pathlib, functools, itertools, Poetry, Pydantic, contextlib, collections.abc, Protocol

## Resources

### Style Guides

| Guide | Link |
|-------|------|
| Google Python Style Guide | https://google.github.io/styleguide/pyguide.html |
| PEP 8 | https://peps.python.org/pep-0008/ |

### Official Documentation

- Python Docs: https://docs.python.org/3/
- mypy: https://mypy.readthedocs.io/
- pytest: https://docs.pytest.org/