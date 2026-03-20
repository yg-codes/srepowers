---
name: postgresql-engineer
description: Use when optimizing PostgreSQL queries, configuring replication, or implementing advanced database features. Invoke for EXPLAIN analysis, JSONB operations, extension usage, VACUUM tuning, performance monitoring, complex SQL patterns, query migration.
---

# PostgreSQL Engineer

## When to Use This Skill

- Analyzing and optimizing slow queries with EXPLAIN
- Implementing JSONB storage and indexing strategies
- Setting up streaming or logical replication
- Configuring and using PostgreSQL extensions
- Tuning VACUUM, ANALYZE, and autovacuum
- Monitoring database health with pg_stat views
- Designing indexes for optimal performance
- Writing complex queries with CTEs and window functions
- Optimizing SQL across PostgreSQL, MySQL, SQL Server, Oracle
- Migrating queries between database platforms

## Core Workflow

1. **Analyze performance** - Use EXPLAIN ANALYZE, pg_stat_statements
2. **Design indexes** - B-tree, GIN, GiST, BRIN based on workload
3. **Optimize queries** - Rewrite inefficient queries, update statistics
4. **Setup replication** - Streaming or logical based on requirements
5. **Monitor and maintain** - VACUUM, ANALYZE, bloat tracking

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Performance | `references/performance.md` | EXPLAIN ANALYZE, indexes, statistics, query tuning |
| JSONB | `references/jsonb.md` | JSONB operators, indexing, GIN indexes, containment |
| Extensions | `references/extensions.md` | PostGIS, pg_trgm, pgvector, uuid-ossp, pg_stat_statements |
| Replication | `references/replication.md` | Streaming replication, logical replication, failover |
| Maintenance | `references/maintenance.md` | VACUUM, ANALYZE, pg_stat views, monitoring, bloat |
| Query Patterns | `references/query-patterns.md` | CTEs, window functions, recursive queries, complex JOINs |
| Window Functions | `references/window-functions.md` | ROW_NUMBER, RANK, LAG/LEAD, analytics |
| Optimization | `references/optimization.md` | Query tuning, execution plans, covering indexes |
| Database Design | `references/database-design.md` | Normalization, keys, constraints, schemas |
| SQL Dialects | `references/dialect-differences.md` | PostgreSQL vs MySQL vs SQL Server specifics |

## Red Flags — Stop and Verify

| Thought | Reality |
|---------|--------|
| "This query is fast enough" | EXPLAIN ANALYZE everything. Fast today breaks at scale. |
| "Skip the index, table is small" | Plan for growth. Add indexes based on query patterns. |
| "Direct production queries are fine" | Read replicas for analytics. Never load prod primary unnecessarily. |
| "Schema migration without backup" | Backup before ANY schema change. Point-in-time recovery ready. |
| "No need for connection pooling" | Always pool. Connection overhead compounds under load. |
| "Locks are fine, it's a quick update" | Minimize lock duration. Use `CONCURRENTLY` for indexes. |

## SRE Principles

Apply the [SRE Principles](../../references/sre-principles.md) (Safety First, Structured Output, Evidence-Driven, Audit-Ready, Communication) using domain-appropriate tools and commands.

## Output Templates

When implementing PostgreSQL solutions, provide:
1. Query with EXPLAIN ANALYZE output
2. Index definitions with rationale
3. Configuration changes with before/after values
4. Monitoring queries for ongoing health checks
5. Brief explanation of performance impact

## Cross-Database SQL Expertise

This skill includes comprehensive SQL optimization knowledge applicable across database systems:

### Complex Query Patterns
- **CTEs (Common Table Expressions)** - Recursive queries, hierarchical data
- **Window Functions** - ROW_NUMBER, RANK, LAG/LEAD, running totals, analytics
- **Advanced JOINs** - LATERAL, CROSS JOIN, semi-joins, anti-joins
- **Set Operations** - Efficient UNION, INTERSECT, EXCEPT patterns

### Multi-Database Considerations
When working with other databases (MySQL, SQL Server, Oracle):
- Use standard SQL where possible
- Note dialect differences in functions and syntax
- Adapt indexing strategies to platform capabilities
- Consider platform-specific optimizations

### Query Migration
When migrating queries between databases:
1. Identify non-standard functions and syntax
2. Map data types appropriately
3. Adapt indexing recommendations
4. Re-test execution plans on target platform

## Knowledge Reference

PostgreSQL 12-16, EXPLAIN ANALYZE, B-tree/GIN/GiST/BRIN indexes, JSONB operators, streaming replication, logical replication, VACUUM/ANALYZE, pg_stat views, PostGIS, pgvector, pg_trgm, WAL archiving, PITR, CTEs, window functions, recursive queries, query optimization across database platforms