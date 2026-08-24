# Food Delivery Order System

## Problem

Design the database part of a simple food delivery order system.

## Features

- Customers can browse restaurants and menu items.
- A customer can place an order from one restaurant.
- An order can have multiple food items.
- A customer can see their past orders.
- A restaurant can see incoming active orders.
- The system stores payment status for an order.

## Scale

- 1 million customers
- 50,000 restaurants
- 3 million orders per month
- 100,000 orders per day
- High traffic during lunch and dinner time
- Around 20 menu reads for every 1 order

## Common Reads

- Customer order history
- Restaurant active orders
- Order details page
- Restaurant menu items

## Out of Scope

- Delivery partner tracking
- Real-time chat
- Recommendation system
- Full payment gateway design
- Notification system

## What This Problem Tests

- SQL database choice
- Schema design
- Primary keys and foreign keys
- One-to-many relationships
- Indexes from query patterns
- Transactions for order creation
- Cache and read replicas
- Partitioning decision
- Sharding decision
