# Tradeoffs

## PostgreSQL Instead Of NoSQL

PostgreSQL fits because the data has relationships and the booking flow needs transactions.

The cost is that we must design indexes and transactions carefully. A document database may make some reads simpler, but preventing double booking and keeping payment plus selected seats consistent would become harder in application code.

## Payments As Booking Attempt

In this design, `payments` is also the parent booking attempt.

The benefit is fewer tables and a simple flow for this learning problem.

The cost is naming confusion. In a larger system, I may add a separate `bookings` table and keep payment attempts separate. For now, I will explain clearly that one payment row groups the selected seats.

## booking_seats Instead Of Seat Array

I will not store selected seat ids as an array inside `payments`.

One booking attempt can contain many seats, so `booking_seats` is a better table.

The benefit is that I can query seats, add constraints, and enforce one live booking per seat.

## Database Constraint For Double Booking

The main guard is a unique rule on live `booking_seats` rows.

The benefit is correctness. Even if two requests arrive at the same time, the database stops the second live booking for the same seat.

The cost is that the write path must handle constraint errors and return a clean message like "seat already taken."

## Cache

Redis can make event details and seat map display faster.

The cost is stale data. A cached seat map may show a seat as available for a few seconds even after someone else has started booking it.

Because of that, cache is only a hint. Final booking always checks PostgreSQL.

## Read Replicas

Read replicas help with read-heavy traffic like event browsing and organizer reports.

The cost is replication lag. A replica may be behind the primary for a short time.

For checkout and read-after-booking, I will use the primary database.

## Partitioning

Partitioning can help later if payments and booking history become very large.

The cost is extra database complexity. Queries must include the partition key, otherwise the database may scan many partitions.

I will not partition on day one.

## Sharding

Sharding is not needed at this scale.

The benefit would be more write capacity later.

The cost is high: joins, transactions, reporting, migrations, and debugging become harder.

If I ever shard this system, I will first consider `event_id` so the seats and bookings for one event stay together.
