---
name: code-documenter
description: Use when adding docstrings, creating API documentation, or building documentation sites. Invoke for OpenAPI/Swagger specs, JSDoc, doc portals, tutorials, user guides.
---

# Code Documenter

## When to Use This Skill

- Adding docstrings to functions and classes
- Creating OpenAPI/Swagger documentation
- Building documentation sites (Docusaurus, MkDocs, VitePress)
- Documenting APIs with framework-specific patterns
- Creating interactive API portals (Swagger UI, Redoc, Stoplight)
- Writing getting started guides and tutorials
- Documenting multi-protocol APIs (REST, GraphQL, WebSocket, gRPC)
- Generating documentation reports and coverage metrics

## Core Workflow

1. **Discover** - Ask for format preference and exclusions
2. **Detect** - Identify language and framework
3. **Analyze** - Find undocumented code
4. **Document** - Apply consistent format
5. **Report** - Generate coverage summary

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Python Docstrings | `references/python-docstrings.md` | Google, NumPy, Sphinx styles |
| TypeScript JSDoc | `references/typescript-jsdoc.md` | JSDoc patterns, TypeScript |
| FastAPI/Django API | `references/api-docs-fastapi-django.md` | Python API documentation |
| NestJS/Express API | `references/api-docs-nestjs-express.md` | Node.js API documentation |
| Coverage Reports | `references/coverage-reports.md` | Generating documentation reports |
| Documentation Systems | `references/documentation-systems.md` | Doc sites, static generators, search, testing |
| Interactive API Docs | `references/interactive-api-docs.md` | OpenAPI 3.1, portals, GraphQL, WebSocket, gRPC, SDKs |
| User Guides & Tutorials | `references/user-guides-tutorials.md` | Getting started, tutorials, troubleshooting, FAQs |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "The code is self-documenting" | Document WHY, not WHAT. Intent isn't in the code. |
| "I'll add docs after release" | Document alongside code. Post-release docs never happen. |
| "Internal APIs don't need docs" | Internal consumers need docs too. Reduce knowledge silos. |
| "README is enough" | API docs, architecture docs, and READMEs serve different purposes. |
| "Examples aren't needed" | Examples are the most-read documentation. Always include them. |
| "Keep it brief" | Completeness over brevity for reference docs. Conciseness for guides. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Formats

Depending on the task, provide:
1. **Code Documentation:** Documented files + coverage report
2. **API Docs:** OpenAPI specs + portal configuration
3. **Doc Sites:** Site configuration + content structure + build instructions
4. **Guides/Tutorials:** Structured markdown with examples + diagrams

## See also

- `sre-readme` (private skill) — operational/infrastructure README generation (deploy/verify/rollback template, sizing guide). Use this skill for code documentation (docstrings, API specs, doc sites); use `sre-readme` for SRE-facing operational READMEs.

## Knowledge Reference

Google/NumPy/Sphinx docstrings, JSDoc, OpenAPI 3.0/3.1, AsyncAPI, gRPC/protobuf, FastAPI, Django, NestJS, Express, GraphQL, Docusaurus, MkDocs, VitePress, Swagger UI, Redoc, Stoplight