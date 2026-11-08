# sre-readme

Generate concise, Structure-framework READMEs for any repository or component
— How-to and Reference sections always, Explanation only when the "why" isn't
obvious from the code structure. Works for infra, apps, libraries, Helm
charts, Terraform modules. Ships as `srepowers-core:sre-readme`. (`SKILL.md`
is the agent-facing trigger doc; this file is for humans.)

## Use cases

- Write a README for a repo, service, chart, or module that has none
- Restructure an existing README that buries workflows in lookup tables or vice versa
- Enforce the mandatory pieces: a Verify step with expected output on every How-to, a rollback for state changes, a `Last Updated` footer
- Cut boilerplate: no placeholder sections, sizing targets by complexity

## How-to

Say "write a README for this repo" or "update the README" — the skill
triggers automatically. Invoke directly as `srepowers-core:sre-readme`. It
reads the project first (what it does, how it's deployed, what's
configurable), writes How-to first, and trims anything that restates the
obvious.

### Verify

No fixture — verify by invoking the skill on a representative task in a
scratch repo (generate a README for a small component and check section
structure, Verify steps, and footer).

## Reference

| Complexity | Target length | Sections |
|------------|---------------|----------|
| Simple (script, small lib) | 20-50 lines | How-to (with Verify) + Reference |
| Standard (service, chart, module) | 50-100 | + Rollback, brief Explanation |
| Complex (platform) | 100-150 | All, plus Environment Matrix, Troubleshooting |

For code documentation (docstrings, API specs, doc sites), use
`srepowers-domain:code-documenter` instead (if installed) — this skill owns operational and
infrastructure READMEs.

- `SKILL.md` — Structure type table, section templates, 11 rules, optional-section criteria

---
Last Updated: 2026-09-14
