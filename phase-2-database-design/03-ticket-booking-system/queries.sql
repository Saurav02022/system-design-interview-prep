-- Event details with venue.
SELECT
  e.id,
  e.title,
  e.description,
  e.starts_at,
  v.name AS venue_name,
  v.location
FROM events e
JOIN venues v ON v.id = e.venue_id
WHERE e.id = $1
  AND e.status = 'published';

-- Available seats for an event.
-- This is good for display, but final booking still needs a transaction.
SELECT
  s.id,
  s.section,
  s.row_label,
  s.seat_number,
  s.price_cents
FROM seats s
LEFT JOIN booking_seats bs
  ON bs.seat_id = s.id
  AND bs.status IN ('held', 'booked')
WHERE s.event_id = $1
  AND s.status = 'open'
  AND bs.id IS NULL
ORDER BY s.section, s.row_label, s.seat_number;

-- User booking history.
SELECT
  p.id,
  p.status,
  p.amount_cents,
  p.created_at,
  e.title,
  e.starts_at
FROM payments p
JOIN events e ON e.id = p.event_id
WHERE p.user_id = $1
  AND p.status IN ('held', 'paid', 'failed', 'expired')
ORDER BY p.created_at DESC
LIMIT 50;

-- Booking details with selected seats.
SELECT
  p.id AS payment_id,
  p.status AS payment_status,
  p.amount_cents,
  e.title,
  s.section,
  s.row_label,
  s.seat_number,
  bs.status AS seat_booking_status
FROM payments p
JOIN events e ON e.id = p.event_id
JOIN booking_seats bs ON bs.payment_id = p.id
JOIN seats s ON s.id = bs.seat_id
  AND s.event_id = p.event_id
WHERE p.id = $1;

-- Organizer event bookings.
SELECT
  p.id,
  p.user_id,
  p.status,
  p.amount_cents,
  p.created_at
FROM payments p
JOIN events e ON e.id = p.event_id
WHERE p.event_id = $1
  AND e.organizer_id = $2
  AND p.status IN ('held', 'paid')
ORDER BY p.created_at DESC
LIMIT 100;

-- Expire old held bookings.
UPDATE booking_seats bs
SET status = 'released',
    updated_at = now()
FROM payments p
WHERE bs.payment_id = p.id
  AND p.status = 'held'
  AND p.held_until < now();

UPDATE payments
SET status = 'expired',
    updated_at = now()
WHERE status = 'held'
  AND held_until < now();
