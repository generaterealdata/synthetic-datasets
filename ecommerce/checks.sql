-- Synthetic E-commerce Database: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py ecommerce <database file>

-- customers.customer_id is unique
SELECT COUNT(*) - COUNT(DISTINCT customer_id) FROM customers;

-- customers.email is unique
SELECT COUNT(*) - COUNT(DISTINCT email) FROM customers;

-- products.product_id is unique
SELECT COUNT(*) - COUNT(DISTINCT product_id) FROM products;

-- products.sku is unique
SELECT COUNT(*) - COUNT(DISTINCT sku) FROM products;

-- orders.order_id is unique
SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM orders;

-- order_items.order_item_id is unique
SELECT COUNT(*) - COUNT(DISTINCT order_item_id) FROM order_items;

-- shipments.tracking_number is unique
SELECT COUNT(*) - COUNT(DISTINCT tracking_number) FROM shipments;

-- every orders.customer_id exists in customers
SELECT COUNT(*) FROM orders c LEFT JOIN customers p ON p.customer_id = c.customer_id WHERE c.customer_id IS NOT NULL AND p.customer_id IS NULL;

-- every order_items.order_id exists in orders
SELECT COUNT(*) FROM order_items c LEFT JOIN orders p ON p.order_id = c.order_id WHERE c.order_id IS NOT NULL AND p.order_id IS NULL;

-- every order_items.product_id exists in products
SELECT COUNT(*) FROM order_items c LEFT JOIN products p ON p.product_id = c.product_id WHERE c.product_id IS NOT NULL AND p.product_id IS NULL;

-- every payments.order_id exists in orders
SELECT COUNT(*) FROM payments c LEFT JOIN orders p ON p.order_id = c.order_id WHERE c.order_id IS NOT NULL AND p.order_id IS NULL;

-- every shipments.order_id exists in orders
SELECT COUNT(*) FROM shipments c LEFT JOIN orders p ON p.order_id = c.order_id WHERE c.order_id IS NOT NULL AND p.order_id IS NULL;

-- every returns.order_item_id exists in order_items
SELECT COUNT(*) FROM returns c LEFT JOIN order_items p ON p.order_item_id = c.order_item_id WHERE c.order_item_id IS NOT NULL AND p.order_item_id IS NULL;

-- a city never appears under two countries
SELECT COUNT(*) FROM (SELECT city FROM customers GROUP BY city HAVING COUNT(DISTINCT country) > 1);

-- every order is in USD
SELECT COUNT(*) FROM orders WHERE currency <> 'USD';

-- order date is never before the customer's signup
SELECT COUNT(*) FROM orders o JOIN customers c USING (customer_id) WHERE date(o.order_date) < date(c.signup_date);

-- item price equals the product's price
SELECT COUNT(*) FROM order_items i JOIN products p USING (product_id) WHERE ABS(i.unit_price - p.unit_price) > 0.005;

-- line_total = quantity x unit_price
SELECT COUNT(*) FROM order_items WHERE ABS(line_total - quantity * unit_price) > 0.011;

-- every order has at least one item
SELECT COUNT(*) FROM orders o WHERE NOT EXISTS (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id);

-- subtotal = sum of the order's line totals
SELECT COUNT(*) FROM orders o JOIN (SELECT order_id, SUM(line_total) s FROM order_items GROUP BY order_id) x USING (order_id) WHERE ABS(o.subtotal - x.s) > 0.011;

-- discount is 0 to 20% of subtotal
SELECT COUNT(*) FROM orders WHERE discount_amount < 0 OR discount_amount > subtotal * 0.2 + 0.011;

-- tax = 8% of (subtotal - discount)
SELECT COUNT(*) FROM orders WHERE ABS(tax_amount - (subtotal - discount_amount) * 0.08) > 0.011;

-- total = subtotal - discount + shipping + tax
SELECT COUNT(*) FROM orders WHERE ABS(total_amount - (subtotal - discount_amount + shipping_fee + tax_amount)) > 0.021;

-- shipping is free from 75, else 4.99-9.99
SELECT COUNT(*) FROM orders WHERE (subtotal >= 75 AND shipping_fee <> 0) OR (subtotal < 75 AND (shipping_fee < 4.98 OR shipping_fee > 10.0));

-- every order has exactly one payment
SELECT COUNT(*) FROM orders o WHERE (SELECT COUNT(*) FROM payments p WHERE p.order_id = o.order_id) <> 1;

-- payment amount equals the order total
SELECT COUNT(*) FROM payments p JOIN orders o USING (order_id) WHERE ABS(p.amount - o.total_amount) > 0.011;

-- payment status follows the order status
SELECT COUNT(*) FROM payments p JOIN orders o USING (order_id) WHERE (o.status = 'cancelled' AND p.status NOT IN ('refunded', 'failed')) OR (o.status = 'returned' AND p.status <> 'refunded') OR (o.status IN ('processing', 'shipped', 'delivered') AND p.status <> 'captured');

-- shipments exist only for shipped, delivered or returned orders
SELECT COUNT(*) FROM shipments s JOIN orders o USING (order_id) WHERE o.status NOT IN ('shipped', 'delivered', 'returned');

-- every shipped, delivered or returned order has exactly one shipment
SELECT COUNT(*) FROM orders o WHERE o.status IN ('shipped', 'delivered', 'returned') AND (SELECT COUNT(*) FROM shipments s WHERE s.order_id = o.order_id) <> 1;

-- shipment status follows the order status
SELECT COUNT(*) FROM shipments s JOIN orders o USING (order_id) WHERE (o.status = 'shipped') <> (s.status = 'in_transit');

-- shipped 1-3 days after the order
SELECT COUNT(*) FROM shipments s JOIN orders o USING (order_id) WHERE julianday(date(s.shipped_at)) - julianday(date(o.order_date)) NOT BETWEEN 1 AND 3;

-- delivered_at is empty exactly while in transit
SELECT COUNT(*) FROM shipments WHERE (status = 'in_transit') <> (delivered_at IS NULL);

-- delivered 2-9 days after shipping
SELECT COUNT(*) FROM shipments WHERE delivered_at IS NOT NULL AND julianday(date(delivered_at)) - julianday(date(shipped_at)) NOT BETWEEN 2 AND 9;

-- returns only for items of returned orders
SELECT COUNT(*) FROM returns r JOIN order_items i USING (order_item_id) JOIN orders o USING (order_id) WHERE o.status <> 'returned';

-- returns.order_item_id is unique
SELECT COUNT(*) - COUNT(DISTINCT order_item_id) FROM returns;

-- refund never exceeds the line total
SELECT COUNT(*) FROM returns r JOIN order_items i USING (order_item_id) WHERE r.refund_amount > i.line_total + 0.011;

-- unit_cost is 35-70% of unit_price
SELECT COUNT(*) FROM products WHERE unit_cost < unit_price * 0.349 OR unit_cost > unit_price * 0.701;

-- no order is dated after 2026-09-30
SELECT COUNT(*) FROM orders WHERE date(order_date) > '2026-09-30';

-- no shipment or delivery is dated after 2026-09-30
SELECT COUNT(*) FROM shipments WHERE date(shipped_at) > '2026-09-30' OR date(delivered_at) > '2026-09-30';

-- no return is requested after 2026-09-30
SELECT COUNT(*) FROM returns WHERE date(requested_at) > '2026-09-30';

-- only orders from the last 12 days are still processing or in transit
SELECT COUNT(*) FROM orders WHERE status IN ('processing', 'shipped') AND date(order_date) < '2026-09-19';

-- orders are returned only if placed before September 2026
SELECT COUNT(*) FROM orders WHERE status = 'returned' AND date(order_date) >= '2026-09-01';

-- orders peak in November and December (at least 1.5 times an average month)
SELECT CASE WHEN (SELECT COUNT(*) / 4.0 FROM orders WHERE substr(order_date, 6, 2) IN ('11', '12')) > 1.5 * (SELECT COUNT(*) / 29.0 FROM orders WHERE substr(order_date, 6, 2) NOT IN ('11', '12')) THEN 0 ELSE 1 END;

-- each year has more orders per month than the year before
SELECT CASE WHEN (SELECT COUNT(*) / 9.0 FROM orders WHERE order_date >= '2026') > (SELECT COUNT(*) / 12.0 FROM orders WHERE order_date LIKE '2025%') AND (SELECT COUNT(*) FROM orders WHERE order_date LIKE '2025%') > (SELECT COUNT(*) FROM orders WHERE order_date LIKE '2024%') THEN 0 ELSE 1 END;

-- no order has more than 12 line items
SELECT COUNT(*) FROM orders WHERE order_id IN (SELECT order_id FROM order_items GROUP BY order_id HAVING COUNT(*) > 12);

-- every product name is unique
SELECT COUNT(*) - COUNT(DISTINCT product_name) FROM products;

-- email is built from the customer's own name
SELECT COUNT(*) FROM customers WHERE email NOT LIKE lower(replace(first_name, ' ', '')) || '.%' OR email NOT LIKE '%@example.com';

-- phone numbers use only ranges reserved for fiction
SELECT COUNT(*) FROM customers WHERE phone IS NOT NULL AND phone NOT LIKE '+1-___-555-01__' AND phone NOT LIKE '+44 7700 900___' AND phone NOT LIKE '+353 20 91_ ____' AND phone NOT LIKE '+61 491 570 ___';
