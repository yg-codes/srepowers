---
name: brainstorming-operations
description: "Use when planning infrastructure operations - explores requirements, risks, verification strategies, and rollback plans before implementation"
---

# Brainstorming Infrastructure Operations

## Overview

Help turn infrastructure operation ideas into fully formed designs and execution plans through natural collaborative dialogue.

Start by understanding the current infrastructure state, then ask questions one at a time to refine the operation. Once you understand what you're executing, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

**Announce at start:** "I'm using the brainstorming-operations skill to design this infrastructure operation."

**Context:** This should be run before creating detailed operation plans.

**Save designs to:** `docs/plans/YYYY-MM-DD-<operation-name>-design.md`

## The Process

**Understanding the operation:**
- Check out the current infrastructure state first (kubectl, configs, recent changes)
- Ask questions one at a time to refine the operation
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message - if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, scope, constraints, risk level

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why
- Consider: downtime, rollback complexity, verification strategies

**Presenting the design:**
- Once you understand what you're executing, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: current state, desired state, operation steps, verification commands, rollback plan, risk assessment
- Be ready to go back and clarify if something doesn't make sense

## Design Document Structure

Every operation design should include:

**Current State:**
- What infrastructure exists now
- Recent changes that are relevant
- Known issues or constraints

**Desired State:**
- What the operation achieves
- Success criteria (how you'll know it worked)
- Rollback criteria (when to abort)

**Operation Approach:**
- High-level steps (not detailed commands yet)
- Verification strategies for each step
- Rollback strategy for each step

**Risk Assessment:**
- Risk level: Low/Medium/High
- What could go wrong
- How to detect failures
- Rollback triggers

**Prerequisites:**
- Tools or access needed
- Information to gather first
- Dependencies on other systems

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<operation-name>-design.md`
- Commit the design document to git

**Planning (if continuing):**
- Ask: "Ready to create the execution plan?"
- Use srepowers:writing-operation-plans to create detailed operation plan

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **Risk-focused** - Always consider what could go wrong and how to detect it
- **Verification-first** - Design verification strategies before operation steps
- **Rollback-aware** - Every operation should have a rollback plan
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

## Infrastructure Operation Examples

### Kubernetes Deployment Update
- Current: app v1.0.0 running on 3 pods
- Desired: app v1.1.0 with updated ConfigMap
- Approach: Rolling update with verification
- Risk: Medium (traffic disruption possible)
- Verification: Pod health checks, API smoke tests

### Keycloak Realm Migration
- Current: legacy Keycloak with manual realm config
- Desired: new Keycloak with CRD-based realm import
- Approach: Export from old, import via CRD
- Risk: High (authentication disruption)
- Verification: User login tests, token validation

### Database Migration
- Current: PostgreSQL 14 with schema v1
- Desired: PostgreSQL 14 with schema v2
- Approach: pg migrations with rollback script
- Risk: High (data loss potential)
- Verification: Row counts, checksums, application queries

### Git Control Repo Reorganization
- Current: monolithic manifests/ directory
- Desired: split by environment (dev/staging/prod)
- Approach: Create new structure, move manifests, update ArgoCD
- Risk: Medium (config drift possible)
- Verification: ArgoCD sync status, pod configs

## Questions to Ask

**Understanding scope:**
- What infrastructure components are affected?
- What's the current state? What's the desired state?
- Are there dependencies or prerequisites?

**Risk assessment:**
- What's the worst-case scenario?
- How would we detect failure?
- What's the rollback strategy?

**Verification strategy:**
- How will we verify each step?
- What commands confirm success?
- What indicators show failure?

**Execution approach:**
- Can this be done incrementally?
- Are there maintenance windows?
- Who needs to be notified?

## SRE Principles

### Safety First
- Include a "Dry-Run Strategy" in every design document: which commands support `--dry-run` and should be validated before live execution
- Every operation design must include rollback triggers and rollback procedures for each step
- Phase structure: **Pre-check** (assess current state, identify risks) → **Design** (create operation approach with safety gates) → **Verify** (review design with stakeholders before execution)

### Structured Output
- Present operation designs using structured sections: Current State → Desired State → Approach → Risk Assessment → Prerequisites
- Use risk assessment matrices with likelihood and impact ratings in tabular format
- Include verification strategy tables (step, verification command, expected outcome, rollback trigger)

### Evidence-Driven
- Reference specific current-state evidence (pod counts, config values, metric baselines) in the design document
- Include actual infrastructure metrics and capacity numbers, not estimates or assumptions
- Cite previous operation outcomes and incident data to inform risk assessment

### Audit-Ready
- Save design documents with date-stamped filenames in `docs/plans/` and commit to version control
- Document all design decisions with rationale, alternatives considered, and trade-offs
- Include rollback strategy for each operation step with specific commands and verification

### Communication
- Include a "Business Impact" section: what business services are affected, expected downtime, customer-facing impact
- Present risk assessment in terms stakeholders understand (revenue impact, user experience, compliance)
- Collaborate iteratively: present design in small sections, check understanding after each before proceeding

## Red Flags

- Proceeding without understanding current infrastructure state
- Skipping rollback planning
- Not considering verification strategies
- Ignoring dependencies between systems
- Assuming things will "just work"
- Not asking about maintenance windows
- Forgetting about monitoring/alerting during operation
