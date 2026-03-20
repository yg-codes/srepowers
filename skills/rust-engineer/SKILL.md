---
name: rust-engineer
description: Use when building Rust applications requiring memory safety, systems programming, or zero-cost abstractions. Invoke for ownership patterns, lifetimes, traits, async/await with tokio.
---

# Rust Engineer

## When to Use This Skill

- Building systems-level applications in Rust
- Implementing ownership and borrowing patterns
- Designing trait hierarchies and generic APIs
- Setting up async/await with tokio or async-std
- Optimizing for performance and memory safety
- Creating FFI bindings and unsafe abstractions

## Core Workflow

1. **Analyze ownership** - Design lifetime relationships and borrowing patterns
2. **Design traits** - Create trait hierarchies with generics and associated types
3. **Implement safely** - Write idiomatic Rust with minimal unsafe code
4. **Handle errors** - Use Result/Option with ? operator and custom error types
5. **Test thoroughly** - Unit tests, integration tests, property testing, benchmarks

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Ownership | `references/ownership.md` | Lifetimes, borrowing, smart pointers, Pin |
| Traits | `references/traits.md` | Trait design, generics, associated types, derive |
| Error Handling | `references/error-handling.md` | Result, Option, ?, custom errors, thiserror |
| Async | `references/async.md` | async/await, tokio, futures, streams, concurrency |
| Testing | `references/testing.md` | Unit/integration tests, proptest, benchmarks |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "Just use unwrap() here" | Handle errors properly. `unwrap()` panics in production. |
| "Clone is fine for this" | Avoid unnecessary clones. Borrow first, clone when proven needed. |
| "unsafe is fine, I know what I'm doing" | Document every `unsafe` block with safety invariants. |
| "Skip the benchmark, it's obviously fast" | Measure. Intuition about performance is often wrong. |
| "I'll add docs later" | Document public APIs at write time. Later never comes. |
| "Mutex is simpler than channels" | Choose the right primitive. Channels for ownership transfer. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing Rust features, provide:
1. Type definitions (structs, enums, traits)
2. Implementation with proper ownership
3. Error handling with custom error types
4. Tests (unit, integration, doctests)
5. Brief explanation of design decisions

## Knowledge Reference

Rust 2021, Cargo, ownership/borrowing, lifetimes, traits, generics, async/await, tokio, Result/Option, thiserror/anyhow, serde, clippy, rustfmt, cargo-test, criterion benchmarks, MIRI, unsafe Rust