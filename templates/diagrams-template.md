# Diagrams

## Data Model Diagram

Use this section for the ER diagram.

```mermaid
erDiagram
  ENTITY_ONE ||--o{ ENTITY_TWO : relation
```

## Important Write Flow

Use this section for flows where multiple writes must happen correctly.

```mermaid
sequenceDiagram
  participant User
  participant Backend
  participant Database

  User->>Backend: Send request
  Backend->>Database: Begin transaction
  Backend->>Database: Write data
  Backend->>Database: Commit transaction
  Backend-->>User: Success response
```

## Important Read Flow

Use this section for common read requests.

```mermaid
flowchart LR
  User --> Backend
  Backend --> Cache
  Backend --> Database
  Database --> Backend
  Cache --> Backend
  Backend --> User
```

## Scaling View

Use this section only if cache, replicas, partitioning, or sharding are part of the design.

```mermaid
flowchart LR
  App[Backend] --> Cache[Redis Cache]
  App --> Primary[(Primary DB)]
  Primary --> Replica1[(Read Replica)]
  Primary --> Replica2[(Read Replica)]
```
