-- Conversation list for a user.
-- UNION ALL lets each side use its own index on user_a_id or user_b_id.
WITH user_connections AS (
  SELECT
    id,
    user_a_id,
    user_b_id,
    last_message_id,
    last_message_at
  FROM connections
  WHERE user_a_id = $1

  UNION ALL

  SELECT
    id,
    user_a_id,
    user_b_id,
    last_message_id,
    last_message_at
  FROM connections
  WHERE user_b_id = $1
)
SELECT
  uc.id,
  uc.user_a_id,
  uc.user_b_id,
  uc.last_message_id,
  uc.last_message_at,
  mi.text AS last_message_text
FROM user_connections uc
LEFT JOIN message_items mi ON mi.id = uc.last_message_id
ORDER BY uc.last_message_at DESC NULLS LAST
LIMIT 50;

-- Latest messages inside one conversation.
SELECT
  id,
  sender_id,
  text,
  created_at
FROM message_items
WHERE connection_id = $1
  AND deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 50;

-- Read position for one user inside one conversation.
SELECT
  connection_id,
  user_id,
  last_read_message_id,
  last_read_at
FROM connection_reads
WHERE connection_id = $1
  AND user_id = $2;

-- Unread count for one conversation.
-- This uses last_read_at so we do not update every message when a user opens the chat.
SELECT
  count(*) AS unread_count
FROM message_items mi
JOIN connection_reads cr
  ON cr.connection_id = mi.connection_id
WHERE mi.connection_id = $1
  AND cr.user_id = $2
  AND mi.sender_id <> $2
  AND mi.created_at > COALESCE(cr.last_read_at, 'epoch'::timestamptz)
  AND mi.deleted_at IS NULL;

-- Find or create logic should first check if the one-to-one connection already exists.
-- The application stores the smaller user id in user_a_id and larger user id in user_b_id.
SELECT
  id,
  user_a_id,
  user_b_id
FROM connections
WHERE user_a_id = $1
  AND user_b_id = $2;
