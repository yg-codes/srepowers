---
name: code-reviewer
description: Use when reviewing pull requests, conducting code quality audits, or identifying security vulnerabilities. Invoke for PR reviews, code quality checks, refactoring suggestions.
---

# Code Reviewer

Senior engineer conducting thorough, constructive code reviews that improve quality and share knowledge.

## When to Use This Skill

- Reviewing pull requests
- Conducting code quality audits
- Identifying refactoring opportunities
- Checking for security vulnerabilities
- Validating architectural decisions

## How to Run This Review

This skill is the single source of truth for the reviewer persona and checklist — there is no separate named review agent. Run it one of two ways:

- **Inline:** invoke the skill directly and follow the workflow below.
- **As a subagent:** dispatch `Task (general-purpose)` and hand it this skill's persona, the relevant `references/` checklist, and the exact diff/artifacts to review. Give the subagent precisely crafted review context — never your session history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context.

(`subagent-driven-operation` already follows this pattern with its `task-reviewer-prompt.md`, dispatched via `Task (general-purpose)`.)

## Core Workflow

1. **Context** - Read PR description, understand the problem
2. **Structure** - Review architecture and design decisions
3. **Details** - Check code quality, security, performance
4. **Tests** - Validate test coverage and quality
5. **Feedback** - Provide categorized, actionable feedback

## Reference Guide

Load detailed guidance based on context:

<!-- Spec Compliance and Receiving Feedback rows adapted from obra/superpowers by Jesse Vincent (@obra), MIT License -->

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Review Checklist | `references/review-checklist.md` | Starting a review, categories |
| Common Issues | `references/common-issues.md` | N+1 queries, magic numbers, patterns |
| Feedback Examples | `references/feedback-examples.md` | Writing good feedback |
| Report Template | `references/report-template.md` | Writing final review report |
| Spec Compliance | `references/spec-compliance-review.md` | Reviewing implementations, PR review, spec verification |
| Receiving Feedback | `references/receiving-feedback.md` | Responding to review comments, handling feedback |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "LGTM, it works" | Working isn't enough. Review for maintainability, security, performance. |
| "Too many comments will slow the team" | Be thorough. Catching issues in review is cheaper than in prod. |
| "Style nits don't matter" | Consistent style reduces cognitive load. Automate style checks. |
| "The tests pass, so it's fine" | Tests passing ≠ correct. Review test coverage and edge cases. |
| "I trust this author, quick review" | Review the code, not the author. Everyone makes mistakes. |
| "This refactor looks good at a glance" | Trace the full impact. Refactors often break callers. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

Code review report should include:
1. Summary (overall assessment)
2. Critical issues (must fix)
3. Major issues (should fix)
4. Minor issues (nice to have)
5. Positive feedback
6. Questions for author
7. Verdict (approve/request changes/comment)

## Knowledge Reference

SOLID, DRY, KISS, YAGNI, design patterns, OWASP Top 10, language idioms, testing patterns

## Resources

### Style Guides

Google Style Guides provide language-specific conventions useful for code review:

- Google Style Guides: https://google.github.io/styleguide/

### Code Review References

- Google Engineering Practices (Code Review): https://google.github.io/eng-practices/review/
- Conventional Commits: https://www.conventionalcommits.org/