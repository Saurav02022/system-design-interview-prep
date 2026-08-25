# Interview Answer

## 30-Second Answer

I will use PostgreSQL first because one-to-one chat has clear relationships between users, connections, message items, and read state. A connection represents one chat thread between two users, and message_items stores messages inside that connection. Sending a message uses a transaction to insert the message and update the connection's latest message fields together.

## 2-Minute Answer

I will focus on the database design for one-to-one chat. Group chat, media storage, encryption, push notifications, and online/offline presence are out of scope.

I will start with PostgreSQL because this design has clear relationships. The main tables are users, connections, message_items, and connection_reads.

A connection is one chat thread between two users. I will store user_a_id and user_b_id on the connection, and each message item will point to connection_id. This makes message reads simple because the query can fetch messages by connection_id instead of checking sender and receiver in both directions.

For read state, I will not keep a boolean read status on every message. I will use connection_reads to store last_read_message_id and last_read_at for each user inside a connection. This avoids updating many message rows when a user opens the chat.

For performance, I will add indexes for conversation list and latest messages. The main index is message_items(connection_id, created_at DESC), which helps fetch latest messages in one conversation. For the conversation list, I will index connections by each user column and last_message_at.

When a user sends a message, I will use a transaction to insert the message and update connections.last_message_id and last_message_at together. If one step fails, the transaction rolls back.

All writes go to the primary database. Read replicas can serve safe reads like older messages and conversation list. Because replicas can lag, after sending a message I can read from the primary for that connection for a short time.

Redis can cache recent messages for active conversations and conversation lists for active users. I will not cache every message forever because chat data grows quickly.

I will not shard on day one. Later, message_items can be partitioned by created_at because it is the fastest-growing table. If traffic becomes too high, connection_id is a possible shard key because most message reads happen inside one chat.

## Follow-Up Points

- If group chat is added later, I would replace user_a_id and user_b_id with a separate connection_members table.
- If message volume becomes too high, message_items is the first table to partition or shard.
- If conversation list becomes slow after sharding, I may keep a denormalized conversation-list store per user.
- If read receipts become more detailed, connection_reads can store more fields like delivered_at or seen_at.
- If online/offline presence is needed, I would handle it separately from the main PostgreSQL user table.
