# code-reviewer

A senior-engineer code review run against a fixed checklist —
architecture, code quality, security, performance, and test coverage —
ending in a categorized report and an explicit verdict. Ships as
`srepowers-core:code-reviewer`. (`SKILL.md` is the agent-facing trigger
doc; this file is for humans.)

## Use cases

- Review a pull request or branch diff before merge
- Audit a codebase for quality issues and refactoring opportunities
- Check a change for security vulnerabilities (OWASP Top 10 lens)
- Verify an implementation actually matches its spec

## How-to

Say "review this PR", "audit this code for security issues", or "check my
change before I open an MR" — or invoke the `srepowers-core:code-reviewer`
skill. It runs inline, or as a general-purpose subagent handed the
relevant checklist and the exact diff (never your session history). The
report follows the template: summary → critical/major/minor issues →
positive feedback → questions for author → verdict (approve / request
changes / comment).

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo: review a deliberately flawed diff and confirm the report
categorizes issues by severity and lands on an explicit verdict.

## Reference

| File | Contents |
|------|----------|
| `references/review-checklist.md` | review categories and what to check in each |
| `references/common-issues.md` | recurring defects: N+1 queries, magic numbers, patterns |
| `references/feedback-examples.md` | how to phrase actionable feedback |
| `references/report-template.md` | final review report structure |
| `references/spec-compliance-review.md` | implementation-vs-spec verification |
| `references/receiving-feedback.md` | responding to review comments |

`SKILL.md` holds the persona, workflow, red flags, and report structure.

## Provenance

Dual-source: base skill from [Jeffallan/claude-skills](https://github.com/Jeffallan/claude-skills) `code-reviewer` (MIT — see CREDITS.md/LICENSE in this directory), with the Spec Compliance and Receiving Feedback reference rows adapted from [obra/superpowers](https://github.com/obra/superpowers) (MIT, © Jesse Vincent), inline-commented at the point of use.

---
Last Updated: 2026-09-14
