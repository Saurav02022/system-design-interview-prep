CREATE TABLE users (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('user', 'organizer')),
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE venues (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE events (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  venue_id UUID NOT NULL REFERENCES venues(id),
  organizer_id UUID NOT NULL REFERENCES users(id),
  starts_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('draft', 'published', 'closed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE seats (
  id UUID PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES events(id),
  section TEXT NOT NULL,
  row_label TEXT NOT NULL,
  seat_number TEXT NOT NULL,
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
  status TEXT NOT NULL CHECK (status IN ('open', 'disabled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (event_id, section, row_label, seat_number)
);

CREATE TABLE payments (
  id UUID PRIMARY KEY,
  event_id UUID NOT NULL REFERENCES events(id),
  user_id UUID NOT NULL REFERENCES users(id),
  status TEXT NOT NULL CHECK (status IN ('held', 'paid', 'failed', 'expired')),
  held_until TIMESTAMPTZ,
  amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
  currency TEXT NOT NULL DEFAULT 'INR',
  provider_ref TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (status <> 'held' OR held_until IS NOT NULL)
);

CREATE TABLE booking_seats (
  id UUID PRIMARY KEY,
  seat_id UUID NOT NULL REFERENCES seats(id),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('held', 'booked', 'released')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_events_organizer_created_at
  ON events (organizer_id, created_at DESC);

CREATE INDEX idx_seats_event_status
  ON seats (event_id, status);

CREATE INDEX idx_payments_user_status_created_at
  ON payments (user_id, status, created_at DESC);

CREATE INDEX idx_payments_event_status_created_at
  ON payments (event_id, status, created_at DESC);

CREATE INDEX idx_booking_seats_payment_id
  ON booking_seats (payment_id);

CREATE UNIQUE INDEX idx_booking_seats_one_live_seat
  ON booking_seats (seat_id)
  WHERE status IN ('held', 'booked');

-- The application updates updated_at when it changes a row.
-- The application also checks that each selected seat belongs to the same event as the payment attempt.
