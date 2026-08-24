# Design

## Scope

I am designing the database part of the food delivery order system.

The focus is on customers, restaurants, menu items, orders, order items, and payments.

Delivery partner tracking, real-time chat, recommendations, full payment gateway design, and notifications are out of scope.

## Database Choice

I will use PostgreSQL as the main database.

This system has clear relationships:

- one customer can place many orders
- one restaurant can receive many orders
- one order has many order items
- one menu item can appear in many order items
- one order has a payment record

PostgreSQL is a good choice because it supports tables, joins, foreign keys, indexes, and transactions.

## Tables

### customers

Stores customer information.

Columns:

- id
- name
- email
- created_at
- updated_at

### restaurants

Stores restaurant information.

Columns:

- id
- name
- email
- location
- open_time
- close_time
- created_at
- updated_at

### menu_items

Stores food items for each restaurant.

Columns:

- id
- restaurant_id
- name
- price
- image_url
- status
- created_at
- updated_at

### orders

Stores one order placed by a customer.

Columns:

- id
- customer_id
- restaurant_id
- status
- total_amount
- created_at
- updated_at

orders.status can be:

- pending_payment
- confirmed
- preparing
- delivered
- cancelled
- failed

What each one means:

- pending_payment means payment has not been completed yet.
- confirmed means payment is completed and the restaurant can see the order.
- preparing means the restaurant is working on the order.
- delivered is a terminal success state.
- cancelled and failed are terminal failure states.

The terminal states matter. Without delivered, an order would stay in the active list forever and the restaurant screen would keep growing.

### order_items

Stores the food items inside an order.

Columns:

- id
- order_id
- menu_item_id
- quantity
- price_at_order_time
- created_at

I will not store order items as an array inside the orders table. One order can have many items, so order_items should be a separate table.

price_at_order_time is stored because menu item prices can change later, but old orders should keep the price used when the order was placed.

### payments

Stores payment information for an order.

Columns:

- id
- order_id
- status
- amount
- created_at
- updated_at

## Primary Keys and Foreign Keys

- customers.id is the primary key.
- restaurants.id is the primary key.
- menu_items.id is the primary key.
- orders.id is the primary key.
- order_items.id is the primary key.
- payments.id is the primary key.

Foreign keys:

- menu_items.restaurant_id references restaurants.id.
- orders.customer_id references customers.id.
- orders.restaurant_id references restaurants.id.
- order_items.order_id references orders.id.
- order_items.menu_item_id references menu_items.id.
- payments.order_id references orders.id.

## Common Queries

### Customer Order History

A customer wants to see their past orders.

Query uses:

- customer_id
- created_at

### Restaurant Active Orders

A restaurant wants to see current incoming orders.

Active statuses are confirmed and preparing. pending_payment is not active, because the customer has not paid yet and the restaurant should not start cooking.

Query uses:

- restaurant_id
- status
- created_at

### Order Details Page

The app needs to show order details with food items.

Query uses:

- order_id

### Restaurant Menu

The app needs to show active menu items for a restaurant.

Query uses:

- restaurant_id
- status

### Payment Status

The app needs to check payment status for an order.

Query uses:

- order_id

## Indexes

I will create indexes based on common queries.

### Customer order history

orders(customer_id, created_at)

This helps fetch a customer's past orders in time order.

### Restaurant active orders

orders(restaurant_id, status, created_at)

This helps restaurants see active orders quickly.

### Order details

order_items(order_id)

This helps fetch all items for one order.

### Restaurant menu

menu_items(restaurant_id, status)

This helps fetch active menu items for a restaurant.

### Payment status

No separate index here. payments.order_id has a UNIQUE constraint, and PostgreSQL already creates an index for that constraint. So checking payment status by order_id is covered.

## Transactions

Order creation needs more than one write, so it needs a transaction.

But I will not keep one transaction open for the whole flow. The payment gateway is an external service and it can be slow. I will use two short transactions instead.

First transaction:

1. Create the order with pending_payment status.
2. Create the order_items rows.
3. Create the payment row with initiated status.
4. Commit.

Then call the payment gateway. No database transaction is open at this point.

Second transaction:

1. If payment succeeded, update payment status to completed and order status to confirmed.
2. If payment failed, update payment status to failed and order status to failed.
3. Commit.

Why two transactions instead of one:

If we keep the transaction open while calling the payment gateway, the database holds row locks and one connection for the full wait time. If the gateway takes a few seconds, or times out, those locks and connections stay busy. During lunch and dinner rush this can block other order writes.

Each transaction still keeps the database correct on its own. We should not create order_items if the order row failed, and we should not mark an order confirmed if the payment row was not updated.

### Failure and recovery

If the backend crashes or the payment gateway times out between the two transactions, the order can stay in pending_payment. To handle this, a payment webhook or a background reconciliation job can check pending_payment orders older than 15 minutes, verify payment status with the gateway, and update the order and payment status.

## Cache and Read Replicas

All writes should go to the primary database.

Read replicas can handle safe reads like:

- customer order history
- restaurant order list
- order details page

There can be replication lag. This means a replica may be slightly behind the primary database.

Redis can cache:

- restaurant menu
- popular restaurant details

Menus are worth caching because there are around 20 menu reads for every order.

I will not cache everything, and I will not cache payment status. After a fresh write, the app can read from the primary database for that user for a short time, then return to replicas for normal reads.

## Partitioning

I will not partition on day one.

Later, the orders table can become very large because many orders are created every day.

orders is the main table for customer history, restaurant order lists, and analytics. order_items may have more rows, but orders is the table we most commonly query by time.

If needed, I can partition orders by created_at, probably monthly.

This helps with:

- old order history
- analytics
- cleaning or archiving old data

One caution: if PostgreSQL table partitioning is added later, primary keys and foreign keys may need to include the partition key, so this should be planned carefully before changing the schema.

## Sharding

I will not shard on day one.

Sharding makes joins, transactions, and database management harder.

I will first use:

- good indexes
- cache
- read replicas
- partitioning

Only if one database cannot handle the traffic, I will consider sharding.

Possible shard keys later:

- customer_id if most queries are customer-focused
- restaurant_id if restaurant-side traffic becomes the main pressure

## Final Summary

I will use PostgreSQL because the system has clear relationships between customers, restaurants, menu items, orders, order items, and payments.

The main tables are customers, restaurants, menu_items, orders, order_items, and payments. An order belongs to one customer and one restaurant, and order_items stores the food items inside that order.

For correctness, order creation uses two short transactions. The first transaction creates the order, order_items, and initiated payment record together. After the payment gateway responds, a second short transaction updates payment status and order status together.

For performance, I will add indexes on customer order history, restaurant active orders, order details, and restaurant menu items. Payment status lookup is covered by the unique order_id constraint on payments.

All writes will go to the primary database. Read replicas can handle safe reads like order history and order details. Redis can cache restaurant menus and popular restaurant details.

I will not partition or shard on day one. Later, I can partition orders by created_at if the orders table becomes very large. I will consider sharding only after indexes, cache, replicas, and partitioning are not enough.
