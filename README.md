# System Design Interview Prep

I am preparing for SDE-2 system design interviews. This repo is where I keep my
practice notes.

It is not a theory book. It is practical notes and database design exercises I
work through one problem at a time, and then write down in the way I would
actually say it in an interview.

## Current focus: Phase 2 — Database Design

Most system design rounds at SDE-2 level go deep into data. If the schema is
wrong, nothing after it makes sense. So I start with the database and build
outward from there.

See [phase-2-database-design](phase-2-database-design/).

The [templates](templates/) folder contains the file structure I use when adding a
new practice problem.

## What each problem covers

Every problem folder walks through the same steps:

- Requirements — what we are building, and what we are not
- Database choice — SQL or NoSQL, and why
- Schema — tables, keys, relationships
- Indexes — driven by the actual queries
- Transactions — where multiple writes must happen together
- Replicas and cache — for read scaling
- Partitioning — for very large tables
- Sharding — only if there is a real reason
- Tradeoffs — what I gave up for what
- Interview answer — the short version I would say out loud

## The formula I follow

Tables come from data.
Relationships come from business rules.
Indexes come from queries.
Transactions come from multiple writes.
Cache comes from repeated reads.
Replicas come from read scaling.
Partitioning comes from very large tables.
Sharding comes last.

## The goal

The goal is not a perfect theoretical design. Nobody builds that in 45 minutes.
The goal is clear thinking and a simple explanation — being able to say why I
picked something, and what it costs me.
