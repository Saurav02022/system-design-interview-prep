# Diagrams

## Data Model Diagram

```mermaid
erDiagram
  CUSTOMERS ||--o{ ORDERS : places
  RESTAURANTS ||--o{ ORDERS : receives
  RESTAURANTS ||--o{ MENU_ITEMS : has
  ORDERS ||--o{ ORDER_ITEMS : contains
  MENU_ITEMS ||--o{ ORDER_ITEMS : included_in
  ORDERS ||--|| PAYMENTS : has

  CUSTOMERS {
    uuid id
    string name
    string email
    timestamp created_at
  }

  RESTAURANTS {
    uuid id
    string name
    string location
  }

  MENU_ITEMS {
    uuid id
    uuid restaurant_id
    string name
    decimal price
    string status
  }

  ORDERS {
    uuid id
    uuid customer_id
    uuid restaurant_id
    string status
    decimal total_amount
    timestamp created_at
  }

  ORDER_ITEMS {
    uuid id
    uuid order_id
    uuid menu_item_id
    int quantity
    decimal price_at_order_time
  }

  PAYMENTS {
    uuid id
    uuid order_id
    string status
    decimal amount
  }
```

## Order Creation Flow

```mermaid
sequenceDiagram
  participant Customer
  participant Backend
  participant DB
  participant Payment
  participant Job

  Customer->>Backend: Place order
  Backend->>DB: Begin transaction
  Backend->>DB: Create order with pending_payment status
  Backend->>DB: Create order_items
  Backend->>DB: Create payment with initiated status
  Backend->>DB: Commit

  Backend->>Payment: Call payment gateway

  alt Payment success
    Payment-->>Backend: Success
    Backend->>DB: Begin transaction
    Backend->>DB: Update payment status to completed
    Backend->>DB: Update order status to confirmed
    Backend->>DB: Commit
    Backend-->>Customer: Order confirmed
  else Payment failed
    Payment-->>Backend: Failed
    Backend->>DB: Begin transaction
    Backend->>DB: Update payment status to failed
    Backend->>DB: Update order status to failed
    Backend->>DB: Commit
    Backend-->>Customer: Payment failed
  else No response or backend crash
    Backend-->>Customer: No confirmation
    Note over DB: Order stays in pending_payment
    Job->>DB: Find pending_payment orders older than 15 minutes
    Job->>Payment: Check real payment status
    Payment-->>Job: Status
    Job->>DB: Update payment and order status
  end
```

## Common Read Flow

```mermaid
flowchart TD
  Client[Customer or Restaurant] --> Backend[Backend]
  Backend --> Hit{Cache hit?}
  Hit -->|Yes| Cached[Return cached data]
  Hit -->|No| Fresh{Needs latest data?}
  Fresh -->|No| Replica[(Read Replica)]
  Fresh -->|Yes, just after a write| Primary[(Primary PostgreSQL)]
  Replica --> Fill[Fill cache if cacheable]
  Primary --> Fill
  Fill --> Backend
  Cached --> Backend
```

Menus and restaurant details are cacheable. Payment status is not cached, and a
read right after a write goes to the primary database.

## Scaling View

```mermaid
flowchart LR
  Backend[Backend] --> Redis[Redis Cache]
  Backend -->|writes and fresh reads| Primary

  subgraph Primary [Primary PostgreSQL]
    Orders[orders table]
    Orders --- P1[2026-07 partition]
    Orders --- P2[2026-08 partition]
  end

  Primary -->|replication| Replica1[(Read Replica 1)]
  Primary -->|replication| Replica2[(Read Replica 2)]
  Backend -->|normal reads| Replica1
  Backend -->|normal reads| Replica2
```

Partitioning the orders table is a later step, not day one.
