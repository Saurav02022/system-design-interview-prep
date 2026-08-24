# AGENTS.md

This repo is for SDE-2 system design interview preparation.

The goal is to keep each design clear, practical, and easy to explain in an interview.

## Writing style

Use simple English.

Keep sentences short and clear.

Prefer practical reasoning over long theory.

Do not use marketing-style language.

Do not over-polish the writing. The notes should sound like a real engineer explaining their own thinking.

If a technical term is needed, explain it with a simple example.

## Update rules

Update only the file or folder requested.

Do not change unrelated problem folders.

Do not invent requirements, scale numbers, features, technologies, or experience.

Do not make the design more advanced than the problem needs.

Preserve the original meaning when improving an answer.

## Database design structure

Use this order for database design problems:

1. Scope
2. Database choice
3. Tables
4. Primary keys and foreign keys
5. Common queries
6. Indexes
7. Transactions
8. Cache and read replicas
9. Partitioning
10. Sharding
11. Final summary

## Database thinking rules

Tables come from data.

Relationships come from business rules.

Indexes come from queries.

Transactions come from multiple related writes.

Cache comes from repeated reads.

Read replicas come from read scaling.

Partitioning comes from very large tables.

Sharding comes last.

## Technical rules

Connect every index to a real query.

Do not say "cache everything."

Do not send writes to read replicas.

All writes should go to the primary database unless the design clearly says otherwise.

Mention replication lag when read replicas are used.

Do not shard on day one unless the scale clearly requires it.

If partitioning is used, explain which table grows fast and which column is used for partitioning.

Do not store one-to-many relationships as arrays in SQL unless there is a clear reason.

## File responsibilities

problem.md should contain the problem statement, features, scale, common reads, out of scope, and what the problem tests.

design.md should contain the main database design and follow the database design structure.

schema.sql should contain readable PostgreSQL-style table definitions, constraints, foreign keys, and useful indexes.

queries.sql should contain common queries only, with short comments.

diagrams.md should contain useful Mermaid diagrams, not decorative diagrams.

tradeoffs.md should explain the cost and benefit of important choices.

interview-answer.md should contain a short spoken answer, a longer spoken answer, and follow-up points.

## Diagram rules

Use diagrams only when they make the design easier to understand.

Prefer Mermaid diagrams because GitHub renders them in Markdown.

Useful diagrams:
- ER diagram for table relationships
- Sequence diagram for important write flows
- Read flow diagram for cache and database reads
- Scaling diagram for cache, primary database, replicas, partitioning, or sharding

Every diagram should answer a real design question.
