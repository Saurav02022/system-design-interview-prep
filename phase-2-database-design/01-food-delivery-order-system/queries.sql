-- Customer order history
SELECT
  id,
  restaurant_id,
  status,
  total_amount,
  created_at
FROM orders
WHERE customer_id = $1
ORDER BY created_at DESC
LIMIT 20;

-- Restaurant active orders
-- With multiple active statuses, PostgreSQL may still sort after using the index.
-- This is acceptable for a small active list.
SELECT
  id,
  customer_id,
  status,
  total_amount,
  created_at
FROM orders
WHERE restaurant_id = $1
  AND status IN ('confirmed', 'preparing')
ORDER BY created_at DESC
LIMIT 50;

-- Order details with items
SELECT
  o.id AS order_id,
  o.status,
  o.total_amount,
  oi.menu_item_id,
  mi.name AS item_name,
  oi.quantity,
  oi.price_at_order_time
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN menu_items mi ON mi.id = oi.menu_item_id
WHERE o.id = $1;

-- Active menu items for a restaurant
-- If menu sorting by name becomes slow, we can later consider an index on
-- (restaurant_id, status, name).
SELECT
  id,
  name,
  price,
  image_url
FROM menu_items
WHERE restaurant_id = $1
  AND status = 'active'
ORDER BY name;

-- Payment status for an order
SELECT
  id,
  order_id,
  status,
  amount,
  created_at
FROM payments
WHERE order_id = $1;
