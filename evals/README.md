# SREPowers Evaluation Framework (Evals)

Automated evaluation framework for testing skill output quality and catching regressions.

## Overview

Unlike unit tests that verify code functionality, evals verify that skills produce correct, well-formatted, and useful outputs when invoked by Claude Code.

## Directory Structure

```
evals/
├── README.md                 # This file
├── eval-runner.py            # Main evaluation runner
├── schemas/                  # JSON schemas for output validation
│   ├── runbook-format.json
│   ├── operation-plan.json
│   └── incident-timeline.json
├── test-scenarios/           # Test scenarios for skills
│   ├── sre-runbook/
│   ├── test-driven-operation/
│   └── systematic-troubleshooting/
└── results/                  # Evaluation results (gitignored)
```

## Running Evaluations

```bash
# Run all evals
python evals/eval-runner.py

# Run specific skill eval
python evals/eval-runner.py --skill sre-runbook

# Run with verbose output
python evals/eval-runner.py --verbose

# Generate report
python evals/eval-runner.py --report results/eval-report.md
```

## Evaluation Types

### 1. Format Validation

Verify output matches expected structure:

- **sre-runbook**: Must have Command/Expected/Result sections
- **operation-plan**: Must have verification commands
- **incident-timeline**: Must have chronological events

### 2. Content Validation

Verify output contains required elements:

- **SRE Principles**: Must mention all 5 principles
- **Safety checks**: Must include dry-run recommendations
- **Structured output**: Must use tables, lists, or phases

### 3. Behavioral Validation

Verify skill behavior is correct:

- **RED before GREEN**: TDO skills must emphasize verification first
- **No shortcuts**: Skills must not allow skipping verification
- **Complete coverage**: All scenarios must be addressed

## Writing New Evals

See `evals/test-scenarios/TEMPLATE.md` for creating new evaluations.

## Scoring

| Score | Meaning |
|-------|---------|
| 100% | Perfect - output meets all criteria |
| 80-99% | Good - minor issues |
| 60-79% | Fair - significant issues |
| <60% | Poor - needs improvement |

## CI Integration

Evals run automatically on:
- Pull requests modifying skills/
- Weekly scheduled runs
- Manual workflow dispatch
