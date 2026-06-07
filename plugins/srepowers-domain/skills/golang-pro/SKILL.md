---
name: golang-pro
description: Use when building or reviewing Go applications requiring concurrent programming, microservices architecture, or high-performance systems. Invoke for Go code review, goroutines, channels, generics, and gRPC integration.
---

# Golang Pro

## When to Use This Skill

- Building concurrent Go applications with goroutines and channels
- Implementing microservices with gRPC or REST APIs
- Creating CLI tools and system utilities
- Optimizing Go code for performance and memory efficiency
- Designing interfaces and using Go generics
- Setting up testing with table-driven tests and benchmarks
- Reviewing Go code for correctness, concurrency, security, and performance issues

## Core Workflow

1. **Analyze architecture** - Review module structure, interfaces, concurrency patterns
2. **Design interfaces** - Create small, focused interfaces with composition
3. **Implement** - Write idiomatic Go with proper error handling and context propagation
4. **Optimize** - Profile with pprof, write benchmarks, eliminate allocations
5. **Test** - Table-driven tests, race detector, fuzzing, 80%+ coverage

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Concurrency | `references/concurrency.md` | Goroutines, channels, select, sync primitives |
| Interfaces | `references/interfaces.md` | Interface design, io.Reader/Writer, composition |
| Generics | `references/generics.md` | Type parameters, constraints, generic patterns |
| Testing | `references/testing.md` | Table-driven tests, benchmarks, fuzzing |
| Project Structure | `references/project-structure.md` | Module layout, internal packages, go.mod |
| Code Review | `references/code-review.md` | Reviewing Go code, anti-patterns, architecture checks, performance profiling |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "I'll add error handling later" | Handle errors at write time. `_` assignments hide bugs. |
| "This goroutine is simple, no lifecycle needed" | Every goroutine needs clear start/stop. Leaks compound. |
| "Race detector is slow, skip it" | Always `-race`. Data races cause silent corruption. |
| "Context isn't needed for this function" | All blocking ops get `context.Context`. Always. |
| "Reflection makes this cleaner" | Prefer generics or interfaces. Reflection has runtime cost. |
| "Panic is fine for this error" | Panic for programmer bugs only, never for runtime errors. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Go features, provide:
1. Interface definitions (contracts first)
2. Implementation files with proper package structure
3. Test file with table-driven tests
4. Brief explanation of concurrency patterns used

## Knowledge Reference

Go 1.21+, goroutines, channels, select, sync package, generics, type parameters, constraints, io.Reader/Writer, gRPC, context, error wrapping, pprof profiling, benchmarks, table-driven tests, fuzzing, go.mod, internal packages, functional options

## Resources

### Style Guides

| Guide | Link |
|-------|------|
| Google Go Style Guide | https://google.github.io/styleguide/go/guide.html |
| Effective Go | https://go.dev/doc/effective_go |
| Go Code Review Comments | https://github.com/golang/go/wiki/CodeReviewComments |

### Official Documentation

- Go Docs: https://go.dev/doc/
- Go by Example: https://gobyexample.com/
