# Tradeoffs

## SQL vs NoSQL

I will use SQL because the data has strong relationships.

Examples:

- customer to orders
- restaurant to orders
- order to order_items
- order to payment

PostgreSQL also gives transactions, joins, constraints, and indexes.

NoSQL can work for some high-scale read cases, but for this problem SQL is simpler and safer.

With NoSQL, we would need to manage cross-table consistency in application code, especially during order creation and payment updates.

## Normalization vs Denormalization

The design is mostly normalized.

For example, order_items is a separate table instead of storing items as an array inside orders.

This makes querying and updating cleaner.

One small denormalized field is total_amount in orders. It avoids recalculating the total every time we show order history.

The cost of storing total_amount is that it can drift from order_items if order items are changed later, so updates must keep them consistent.

## Cache Tradeoffs

Caching menus pays off here because there are around 20 menu reads for every order, and the same menu is read by many customers.

The cost is stale data. A menu edit is only visible after the cache entry expires or is cleared on write.

I will not cache payment status. A wrong payment status on screen is worse than a slightly slower query.

## Replica Tradeoffs

Read replicas take history and listing reads off the primary, which matters during the lunch and dinner rush.

The cost is replication lag. A replica can be behind the primary, so a customer who just placed an order may not see it yet.

The fix is not free either: reading from the primary for a short time after a write means some traffic still lands on the primary.

## Partitioning Tradeoffs

I will not partition on day one.

Later, orders can become very large. If needed, I can partition orders by created_at, probably monthly.

The benefit is that old history, analytics, and archiving only touch the partitions they need.

The cost is not just extra database management. Primary keys and foreign keys may need to include the partition key, so the schema change is not a small one.

## Sharding Tradeoffs

I will not shard on day one.

Sharding makes joins, transactions, and operations harder.

I will first use indexes, cache, read replicas, and partitioning.

If one database cannot handle the traffic later, I can consider sharding by customer_id or restaurant_id based on the main query pattern.

If we shard by customer_id, restaurant active orders may need to query many shards, so the shard key must be chosen based on the main access pattern.

## Final Decision

Start simple with PostgreSQL, good schema design, useful indexes, transactions, Redis for repeated reads, and read replicas for scaling reads.

Partition orders later if the table becomes too large.

Shard only as a last step.
