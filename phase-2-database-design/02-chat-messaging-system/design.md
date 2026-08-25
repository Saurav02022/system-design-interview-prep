# Design

## Scope

I am designing the database part of a simple one-to-one chat system.

The focus is on users, chat connections, message items, conversation list, latest messages, and read state.

Group chat, voice or video calls, media storage, encryption, push notifications, online/offline presence, and blocking are out of scope.

## Database Choice

I will start with PostgreSQL as the main database.

This problem has clear relationships:

- one user can have many chat connections
- one connection belongs to two users
- one connection has many message items
- one user has one read position inside one connection

PostgreSQL works well here because it gives tables, joins, foreign keys, indexes, and transactions.

At very high message scale, the `message_items` table is the first table I would revisit. It can be partitioned, sharded, or later moved to a message-optimized store if PostgreSQL is not enough. I will not start with that complexity on day one.

## Tables

### users

Stores user information.

Columns:

- id
- name
- phone_number
- image_url
- created_at
- updated_at

I will not store online/offline status here because presence is out of scope and usually changes too often for the main relational user table.

### connections

Stores one chat thread between two users.

Columns:

- id
- user_a_id
- user_b_id
- last_message_id
- last_message_at
- created_at
- updated_at

This is close to the original `connection` idea. The important fix is that a connection represents the chat container, and every message item points to this connection.

For one-to-one chat, one connection should have exactly two users.

`last_message_id` and `last_message_at` help build the conversation list without scanning the full message history every time.

### message_items

Stores messages inside one connection.

Columns:

- id
- connection_id
- sender_id
- text
- created_at
- deleted_at

I will use `message_items` because that matches the original flow. It means one row is one message item.

I will not store both `sender_id` and `receiver_id` on every message. Since the message belongs to a connection, we can get the other user from the connection. This keeps message queries simple:

```sql
WHERE connection_id = $1
ORDER BY created_at DESC
```

### connection_reads

Stores how far each user has read inside one connection.

Columns:

- id
- connection_id
- user_id
- last_read_message_id
- last_read_at
- updated_at

This is better than a boolean `read` status on every message item.

Read state belongs to a user inside a connection. For example, Saurav may have read till message 100 and Rahul may have read till message 95.

With `last_read_message_id`, we do not need to update every message row when a user opens the chat.

## Primary Keys and Foreign Keys

- users.id is the primary key.
- connections.id is the primary key.
- message_items.id is the primary key.
- connection_reads.id is the primary key.

Foreign keys:

- connections.user_a_id references users.id.
- connections.user_b_id references users.id.
- connections.last_message_id references message_items.id.
- message_items.connection_id references connections.id.
- message_items.sender_id references users.id.
- connection_reads.connection_id references connections.id.
- connection_reads.user_id references users.id.
- connection_reads.last_read_message_id references message_items.id.

Important constraints:

- `connections(user_a_id, user_b_id)` should be unique after storing the smaller user id in `user_a_id` and larger user id in `user_b_id`.
- `connection_reads(connection_id, user_id)` should be unique because one user should have only one read position per connection.

The application should also verify that `message_items.sender_id` belongs to the connection before inserting a message. The same check applies before creating a `connection_reads` row.

## Common Queries

### Conversation List For A User

A user wants to see all conversations sorted by latest activity.

Query uses:

- user_id
- last_message_at

### Latest Messages Inside A Conversation

A user opens one conversation and wants the latest messages.

Query uses:

- connection_id
- created_at

### Latest Message Preview

The conversation list should show the last message preview.

Query uses:

- connections.last_message_id
- message_items.id

### Read Position

The app needs to know how far the user has read in the conversation.

Query uses:

- connection_id
- user_id

### Unread Count

The app can calculate unread count by comparing messages in a connection with the user's last read position.

Query uses:

- connection_id
- created_at
- last_read_at

## Indexes

I will create indexes based on the real queries.

### Conversation list

```text
connections(user_a_id, last_message_at)
connections(user_b_id, last_message_at)
```

This helps find conversations for a user and sort them by latest activity.

Because one-to-one connection has two user columns, we need to check both sides. The query can use `UNION ALL` so each side can use its own index. At larger scale, a separate membership table can make this cleaner.

### Latest messages

```text
message_items(connection_id, created_at DESC)
```

This helps fetch latest messages in one conversation.

### Read position

```text
connection_reads(connection_id, user_id)
```

This helps find one user's read position inside one connection.

This is also unique, so PostgreSQL creates an index for it.

### Unread count

```text
message_items(connection_id, created_at)
```

This is covered by the latest messages index because it starts with `connection_id` and includes `created_at`.

I will not create another duplicate index for unread count.

## Transactions

Sending a message should use a short transaction.

Inside one transaction:

1. Insert a row into `message_items`.
2. Update `connections.last_message_id`.
3. Update `connections.last_message_at`.
4. Commit.

Before inserting the message, the backend should verify that the sender belongs to the connection.

These writes should happen together. If the message is inserted but the connection is not updated, the conversation list may not show the latest message.

Marking a conversation as read is a smaller write:

1. Update `connection_reads.last_read_message_id`.
2. Update `connection_reads.last_read_at`.

This avoids updating every message item one by one.

## Cache and Read Replicas

All writes should go to the primary database.

Read replicas can serve safe reads like:

- older messages
- conversation list
- read-only conversation details

There can be replication lag. After sending a message, the app can read from the primary for that connection for a short time so the sender sees the message immediately.

Redis can cache:

- recent messages for very active connections
- conversation list for active users for a short time
- user profile data used in chat list

I will not cache every message forever. Chat data changes quickly and the cache can become expensive.

I will not rely only on cache for read state because read state changes often and users expect it to be correct.

## Partitioning

I will not partition on day one if traffic is still manageable.

At this scale, `message_items` is the fastest-growing table because every sent message creates a new row.

If needed, I can partition `message_items` by `created_at`, probably monthly.

This helps with:

- old message history
- archiving
- time-based cleanup
- keeping large scans smaller

The tradeoff is that queries by one connection may touch multiple time partitions when a conversation has messages across many months.

If that becomes a bigger issue, I can consider partitioning or sharding by `connection_id`.

## Sharding

I will not shard on day one.

Sharding makes joins, transactions, and operations harder.

I will first use:

- good indexes
- cache
- read replicas
- partitioning

If one database cannot handle the message volume later, `connection_id` is a possible shard key because most message reads happen inside one connection.

The tradeoff is that a user's conversation list may need data from many connections across shards, so the design may need a separate conversation-list store or denormalized metadata later.

## Final Summary

I will use PostgreSQL first because the system has clear relationships between users, connections, message items, and read state.

The main tables are users, connections, message_items, and connection_reads. A connection represents one chat thread between two users, and every message item belongs to one connection.

For latest messages, I will index message_items by connection_id and created_at. For conversation list, I will keep last_message_id and last_message_at on connections.

Sending a message uses a transaction to insert the message and update the connection's last message fields together.

All writes go to the primary database. Read replicas can serve safe reads, and Redis can cache recent messages or conversation lists for active users.

I will not shard on day one. Later, message_items can be partitioned by created_at, and if traffic becomes too high, connection_id is a possible shard key.
