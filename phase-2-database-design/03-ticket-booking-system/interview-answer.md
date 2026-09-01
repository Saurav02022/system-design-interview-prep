# Interview Answer

## 30-Second Answer

I will use PostgreSQL because ticket booking has relationships and needs correctness. The main tables are users, venues, events, seats, payments, and booking_seats. In my design, payments acts as the booking attempt, and booking_seats stores selected seats. The key rule is that one seat can have only one live booking.

## 2-Minute Answer

I will use PostgreSQL as the main database. Ticket booking has clear relationships between users, organizers, venues, events, seats, and payment attempts. The hard part is not just storing data. The hard part is preventing two users from booking the same seat.

The main tables are users, venues, events, seats, payments, and booking_seats. A user can be a normal user or an organizer. An event belongs to a venue and an organizer. Seats belong to an event. In this design, the payments table also acts as the booking attempt. One payment attempt can contain many selected seats through booking_seats.

For correctness, I will use a transaction when a user starts booking. I will lock the selected seats, create a payment row with status held, create booking_seats rows with status held, and commit. I will also use a database-level unique rule so one seat can have only one live booking row. This protects the system even if two users click the same seat at the same time.

The payment gateway call happens outside the database transaction. After success, I will update the payment to paid and booking seats to booked. If payment fails or times out, I will mark the payment failed or expired and release the seats. A background job can clean old held seats using held_until.

For performance, I will add indexes for available seats, user booking history, booking details, organizer event bookings, and organizer events. Redis can cache event details and seat map hints, but final booking will always check PostgreSQL. Read replicas can serve safe reads like event browsing and reports, but checkout writes and fresh booking reads should use the primary database.

I will not partition or shard on day one. Later, I may partition payments and booking_seats by created_at if history tables grow very large. I will consider sharding only if one database cannot handle the write load or data size.

## Follow-Up Points

### Why PostgreSQL?

Because I need relationships, joins, transactions, locks, and constraints. These are important for seat booking correctness.

### Why not only Redis for seat availability?

Redis can be stale. It is fine for showing a fast seat map, but the final booking must be checked and locked in PostgreSQL.

### How do I prevent double booking?

I use a transaction, row locks, and a database unique rule that allows only one live booking row for one seat.

### Why is the payment call outside the transaction?

Payment gateways are external and can be slow. Holding a database transaction open during that call can block locks and database connections.

### When would I partition?

Only when tables like payments and booking_seats become very large. I may partition by created_at because booking history is usually time-based.

### When would I shard?

Not on day one. If needed later, I may shard by event_id so seats, booking seats, and payments for one event stay together.
