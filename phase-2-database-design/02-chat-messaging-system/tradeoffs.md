# Tradeoffs

## SQL vs NoSQL

I will start with PostgreSQL because users, connections, message items, and read state have clear relationships.

PostgreSQL also gives transactions for sending a message and updating the connection's latest message fields together.

The cost is that `message_items` can become very large. At very high scale, a NoSQL or message-optimized store may handle message writes better, but then we need to handle consistency and query patterns more carefully in application code.

## Normalization vs Denormalization

The design is mostly normalized.

Messages are stored in `message_items`, and read state is stored separately in `connection_reads`.

One denormalized part is `connections.last_message_id` and `connections.last_message_at`.

The benefit is that the conversation list is fast.

The cost is that sending a message must update both `message_items` and `connections` together. A transaction keeps them consistent.

## Cache Tradeoffs

Redis can cache recent messages for active connections and conversation lists for active users.

This helps because users usually open recent conversations again and again.

The cost is freshness. A user expects a sent message to appear immediately, so after a fresh write the app may read from the primary database for that connection.

I will not cache every message forever because message volume is high and cache can become expensive.

## Replica Tradeoffs

Read replicas can reduce load on the primary database for older messages and conversation lists.

The cost is replication lag. A replica may be slightly behind the primary database.

After sending a message, the app can read from primary for that connection for a short time.

## Partitioning Tradeoffs

`message_items` is the fastest-growing table.

Partitioning it by `created_at` can help with old message history, archiving, and large scans.

The cost is that one long conversation may have messages across many time partitions, so fetching older history can touch multiple partitions.

## Sharding Tradeoffs

I will not shard on day one.

If one database cannot handle message volume later, `connection_id` is a possible shard key because most message reads happen inside one connection.

The cost is that one user's conversation list may contain many connections across many shards. That may need a separate denormalized conversation-list store later.

## Final Decision

Start with PostgreSQL, clear tables, indexes for real queries, short transactions, cache for recent active reads, and read replicas for safe reads.

Partition `message_items` later if the table becomes too large.

Consider sharding by `connection_id` only after simpler options are not enough.
