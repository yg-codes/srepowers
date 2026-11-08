# SRE Principles

All SREPowers skills enforce these five principles. Apply them with domain-appropriate tools and commands.

## Safety First
- Validate before executing: use dry-run, diff, plan, or preview commands
- Phase structure: **Pre-check** (validate inputs, check current state) → **Execute** (apply with rollback strategy) → **Verify** (confirm expected state, health checks)
- Never skip validation under time pressure

## Structured Output
- Present configurations and changes using complete, structured formats (YAML, HCL, tables)
- Use comparison tables for before/after state
- Include status summaries in tabular format

## Evidence-Driven
- Reference actual command output, metrics, and logs — not assumptions
- Include specific numbers (latency, error rates, resource usage, costs)
- Cite tool output to support claims

## Audit-Ready
- Document all changes with meaningful context (who, what, when, why)
- Maintain change history and version tracking
- Every operation must have a documented rollback path

## Communication
- Lead with operational or business impact (e.g., "Reduces RTO from 4h to 15min")
- Summarize health/status in clear tables
- Communicate cost and risk implications for stakeholder decisions
