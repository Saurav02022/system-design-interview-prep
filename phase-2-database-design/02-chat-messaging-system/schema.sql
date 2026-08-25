CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- updated_at is maintained by the application when rows are changed.

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL UNIQUE,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id UUID NOT NULL REFERENCES users(id),
  user_b_id UUID NOT NULL REFERENCES users(id),
  last_message_id UUID,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (user_a_id <> user_b_id),
  UNIQUE (user_a_id, user_b_id)
);

CREATE TABLE message_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE connection_reads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_id UUID NOT NULL REFERENCES connections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  last_read_message_id UUID REFERENCES message_items(id),
  last_read_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (connection_id, user_id)
);

ALTER TABLE connections
ADD CONSTRAINT fk_connections_last_message
FOREIGN KEY (last_message_id) REFERENCES message_items(id);

CREATE INDEX idx_connections_user_a_last_message_at
ON connections (user_a_id, last_message_at DESC);

CREATE INDEX idx_connections_user_b_last_message_at
ON connections (user_b_id, last_message_at DESC);

CREATE INDEX idx_message_items_connection_created_at
ON message_items (connection_id, created_at DESC);

-- connection_reads(connection_id, user_id) is already indexed by the UNIQUE constraint.
