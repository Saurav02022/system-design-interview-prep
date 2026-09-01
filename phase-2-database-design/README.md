# Phase 2 — Database Design

## What this phase covers

This phase is only about the data layer. For each problem I work out:

- what data we actually store
- SQL or NoSQL, and why
- tables, keys and relationships
- the queries the app will really run
- indexes for those queries
- where transactions are needed
- cache and read replicas
- partitioning, and whether it is needed yet
- sharding, and whether it is needed at all

No load balancers, no API gateway diagrams. Just the database thinking.

## Practice problems

- 01 [Food Delivery Order System](01-food-delivery-order-system/) - completed
- 02 [Chat Messaging System](02-chat-messaging-system/) - completed
- 03 [Ticket Booking System](03-ticket-booking-system/) - completed
- 04 Ecommerce Order System - not started yet
- 05 Video Learning Platform - not started yet

## Answer structure I follow

Same 11 steps for every problem. Having a fixed order means I do not freeze in
the interview trying to decide what to say next.

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
11. Final interview summary

## Files in each problem folder

- `problem.md` — the requirements
- `design.md` — the full walkthrough, all 11 steps
- `schema.sql` — the tables
- `queries.sql` — the queries the design is built around
- `diagrams.md` — useful diagrams for the schema and flows
- `tradeoffs.md` — what I gave up, and why
- `interview-answer.md` — the spoken version
