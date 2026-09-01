# Design

## Scope

I am designing the database part of a simple ticket booking system.

The focus is on users, organizers, venues, events, seats, booking attempts, selected seats, payments, and booking history.

Seat map UI, payment gateway internals, notifications, QR code generation, refunds, waitlist, and recommendations are out of scope.

## Database Choice

I will use PostgreSQL as the main database.

This system has clear relationships:

- one organizer can create many events
- one event belongs to one venue
- one event has many seats
- one user can make many booking attempts
- one booking attempt can contain many selected seats

PostgreSQL is a good choice because the main challenge is correctness. Two users should not be able to book the same seat. PostgreSQL gives transactions, row locks, foreign keys, and unique constraints for this.

## Tables

### users

Stores user and organizer information.

Columns:

- id
- name
- phone_number
- role
- image_url
- created_at
- updated_at

users.role can be:

- user
- organizer

### venues

Stores venue information.

Columns:

- id
- name
- location
- capacity
- created_at
- updated_at

### events

Stores event information.

Columns:

- id
- title
- description
- venue_id
- organizer_id
- starts_at
- status
- created_at
- updated_at

events.status can be:

- draft
- published
- closed
- cancelled

### seats

Stores seats for an event.

Columns:

- id
- event_id
- section
- row_label
- seat_number
- price_cents
- status
- created_at
- updated_at

seats.status can be:

- open
- disabled

I am treating seats as event-specific seats. That means one seat row belongs to one event.

### payments

Stores one booking and payment attempt.

Columns:

- id
- event_id
- user_id
- status
- held_until
- amount_cents
- currency
- provider_ref
- idempotency_key
- created_at
- updated_at

In this design, `payments` is also the parent booking attempt. One payment attempt can have many selected seats through `booking_seats`.

payments.status can be:

- held
- paid
- failed
- expired

`held_until` is used because selected seats should not stay blocked forever if the user does not complete payment.

`idempotency_key` helps make retries safe. If the same payment request is retried, we should not create duplicate booking attempts.

### booking_seats

Stores the seats selected inside one booking attempt.

Columns:

- id
- seat_id
- payment_id
- status
- created_at
- updated_at

booking_seats.status can be:

- held
- booked
- released

This table is needed because one booking attempt can contain more than one seat.

## Primary Keys and Foreign Keys

- users.id is the primary key.
- venues.id is the primary key.
- events.id is the primary key.
- seats.id is the primary key.
- payments.id is the primary key.
- booking_seats.id is the primary key.

Foreign keys:

- events.venue_id references venues.id.
- events.organizer_id references users.id.
- seats.event_id references events.id.
- payments.event_id references events.id.
- payments.user_id references users.id.
- booking_seats.seat_id references seats.id.
- booking_seats.payment_id references payments.id.

Important constraints:

- `seats(event_id, section, row_label, seat_number)` should be unique.
- `payments.idempotency_key` should be unique.
- One seat should have only one live booking row where booking_seats.status is held or booked.
- The app should verify that every selected seat belongs to the same event as the payment attempt.

The last constraint is the main guard against double booking. Application code can make mistakes, but the database must still protect the seat.

## Common Queries

### Event Details

A user wants to see one event with venue information.

Query uses:

- event id
- venue id

### Available Seats For An Event

A user wants to see available seats for one event.

Query uses:

- event_id
- seat status
- booking_seats status

### User Booking History

A user wants to see bookings they have started or completed.

Query uses:

- user_id
- created_at
- status

### Booking Details

The app needs to show one booking attempt with all selected seats.

Query uses:

- payment_id

### Organizer Event Bookings

An organizer wants to see bookings for one event.

Query uses:

- event_id
- payment status
- created_at

## Indexes

I will create indexes based on common queries.

### Event details

```text
events(id)
```

This is already covered by the primary key.

### Events by organizer

```text
events(organizer_id, created_at)
```

This helps an organizer see their events.

### Available seats

```text
seats(event_id, status)
```

This helps find seats for one event.

```text
booking_seats(seat_id)
```

This helps check whether a seat already has a live booking row.

The important rule is a partial unique index:

```text
booking_seats(seat_id) where status in held or booked
```

This means one seat can have only one live booking.

### User booking history

```text
payments(user_id, status, created_at)
```

This helps fetch a user's booking history in time order.

### Booking details

```text
booking_seats(payment_id)
```

This helps fetch all seats inside one booking attempt.

### Organizer event bookings

```text
payments(event_id, status, created_at)
```

This helps organizers see paid or held bookings for one event.

## Transactions

Booking seats needs a transaction because multiple related writes must stay correct together.

### Start booking

Inside one short transaction:

1. Select the requested seat rows using `FOR UPDATE`.
2. Check that the seats are open.
3. Check that all selected seats belong to the same event.
4. Create a `payments` row with status held.
5. Create `booking_seats` rows with status held.
6. Commit.

The database unique rule on live `booking_seats` rows prevents two users from holding or booking the same seat at the same time.

### Payment call

The payment gateway call should happen outside the database transaction.

I do not want to hold database locks or a database connection while waiting for a third-party payment service.

### Payment success

Inside another short transaction:

1. Update payments.status to paid.
2. Update booking_seats.status to booked.
3. Commit.

### Payment failure or timeout

Inside another short transaction:

1. Update payments.status to failed or expired.
2. Update booking_seats.status to released.
3. Commit.

A background job can expire old held bookings where `held_until` is in the past.

## Cache and Read Replicas

I will use Redis for repeated reads, not for final booking correctness.

Good cache candidates:

- event details
- venue details
- event listing
- seat map display hint

The seat map cache should have a short TTL because seat availability changes quickly during a popular event sale.

I will not trust cache for final booking. Final booking should always check and lock rows in PostgreSQL.

Read replicas can handle safe reads:

- event browsing
- event details
- old booking history
- organizer reports

The primary database should handle:

- every write
- seat availability during checkout
- reading back the booking immediately after the user pays

Replica lag can show old data for a short time. For read-after-write flows, I will read from primary.

## Partitioning

I will not partition on day one.

At this scale, PostgreSQL with good indexes should handle the data.

If the data grows much larger, I may partition:

- payments by created_at, monthly
- booking_seats by created_at, monthly
- seats by event_id for very large event data

Partitioning by time helps with booking history and old data cleanup.

Before partitioning, I need to check query patterns. A query that does not include the partition key may still scan many partitions.

## Sharding

I will not shard on day one.

Sharding makes joins, transactions, reporting, and database operations harder.

I will consider sharding only after indexes, cache, replicas, and partitioning are not enough.

If sharding is needed later, `event_id` can be a good shard key because seats, booking seats, and payments for one event should stay close together.

## Final Summary

I will use PostgreSQL because ticket booking has relationships and needs strong correctness. The main tables are users, venues, events, seats, payments, and booking_seats. In this design, payments acts as the booking attempt, and booking_seats stores the selected seats. To prevent double booking, I will use a short transaction, row locks, and a database-level unique rule so one seat can have only one live booking. I will cache event data and seat map hints, but final booking always checks the primary database. Read replicas can serve safe reads, but checkout uses primary. I will not partition or shard on day one.
