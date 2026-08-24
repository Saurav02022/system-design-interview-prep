# Interview Answer

## 30-Second Answer

I will use PostgreSQL because this data is relational and order creation needs correctness.

The main tables are customers, restaurants, menu_items, orders, order_items, and payments.

order_items is a separate table from orders, and order creation uses short transactions so the order and payment state do not become inconsistent.

## 2-Minute Answer

I will focus on the database design for customers, restaurants, menu items, orders, order items, and payments.

I will use PostgreSQL because the data is relational. A customer can place many orders, a restaurant can receive many orders, and one order can have many order items. PostgreSQL also gives us joins, foreign keys, indexes, and transactions.

The main tables are customers, restaurants, menu_items, orders, order_items, and payments. The orders table stores the main order record, and order_items stores each food item inside that order. I will not store order items as an array inside orders because one order can have many items.

For common reads, I will add indexes on orders(customer_id, created_at) for customer order history, orders(restaurant_id, status, created_at) for restaurant active orders, order_items(order_id) for order details, and menu_items(restaurant_id, status) for menu listing. Payment status lookup is covered by the unique index created by the UNIQUE constraint on payments.order_id, so I do not need a separate index there.

For the restaurant screen, active means confirmed and preparing. An order that is still pending_payment is not shown, because the customer has not paid yet.

Order creation needs a transaction, but I will use two short ones instead of one long one. The first transaction creates the order with pending_payment status, creates the order_items, and creates the payment row with initiated status, then commits. After that I call the payment gateway with no transaction open. The second transaction updates the payment status and the order status based on the result. This way we are not holding database locks and a connection while waiting for an external service. If the process dies between the two transactions, a webhook or background job can settle old pending_payment orders.

All writes should go to the primary database. Read replicas can serve safe reads like order history and order details. Redis can cache restaurant menus and popular restaurant details, because there are around 20 menu reads for every order. I will not cache payment status.

I will not partition or shard on day one. Later, if orders become very large, I can partition orders by created_at, probably monthly. Sharding comes only after indexes, cache, replicas, and partitioning are not enough.

## Follow-Up Points

- If payment retry is needed, we can use payment_attempts instead of only one payment row.
- If order traffic becomes very high, orders can be partitioned by created_at.
- If customer order history is the main pressure, customer_id can be a possible shard key later.
- If restaurant-side traffic is the main pressure, restaurant_id can be considered later.
- For fresh data after order placement, read from the primary database instead of a replica.
