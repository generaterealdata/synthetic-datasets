-- Dirty E-commerce Data for Cleaning Practice: rule checks.
-- Each query counts the rows that break one rule. On the clean version every query returns 0.
-- Written for SQLite; run them all with: python verify.py dirty-ecommerce <database file>

-- customers.customer_id is unique
SELECT COUNT(*) - COUNT(DISTINCT customer_id) FROM customers;

-- customers.email is unique
SELECT COUNT(*) - COUNT(DISTINCT email) FROM customers;

-- products.product_id is unique
SELECT COUNT(*) - COUNT(DISTINCT product_id) FROM products;

-- orders.order_id is unique
SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM orders;

-- order_items.order_item_id is unique
SELECT COUNT(*) - COUNT(DISTINCT order_item_id) FROM order_items;

-- every orders.customer_id exists in customers
SELECT COUNT(*) FROM orders c LEFT JOIN customers p ON p.customer_id = c.customer_id WHERE c.customer_id IS NOT NULL AND p.customer_id IS NULL;

-- every order_items.order_id exists in orders
SELECT COUNT(*) FROM order_items c LEFT JOIN orders p ON p.order_id = c.order_id WHERE c.order_id IS NOT NULL AND p.order_id IS NULL;

-- every order_items.product_id exists in products
SELECT COUNT(*) FROM order_items c LEFT JOIN products p ON p.product_id = c.product_id WHERE c.product_id IS NOT NULL AND p.product_id IS NULL;

-- a city never appears under two countries
SELECT COUNT(*) FROM (SELECT city FROM customers GROUP BY city HAVING COUNT(DISTINCT country) > 1);

-- order country is the customer's country
SELECT COUNT(*) FROM orders o JOIN customers c USING (customer_id) WHERE o.country <> c.country;

-- order date is never before the customer's signup
SELECT COUNT(*) FROM orders o JOIN customers c USING (customer_id) WHERE date(o.order_date) < date(c.signup_date);

-- ship_date is empty exactly for pending and cancelled orders
SELECT COUNT(*) FROM orders WHERE (status IN ('pending', 'cancelled')) <> (ship_date IS NULL);

-- shipped 1-5 days after the order
SELECT COUNT(*) FROM orders WHERE ship_date IS NOT NULL AND julianday(ship_date) - julianday(order_date) NOT BETWEEN 1 AND 5;

-- item price equals the product's price
SELECT COUNT(*) FROM order_items i JOIN products p USING (product_id) WHERE ABS(i.unit_price - p.unit_price) > 0.005;

-- line_total = quantity x unit_price
SELECT COUNT(*) FROM order_items WHERE ABS(line_total - quantity * unit_price) > 0.011;

-- every order has at least one item
SELECT COUNT(*) FROM orders o WHERE NOT EXISTS (SELECT 1 FROM order_items i WHERE i.order_id = o.order_id);

-- order_total = sum of the order's line totals
SELECT COUNT(*) FROM orders o JOIN (SELECT order_id, SUM(line_total) s FROM order_items GROUP BY order_id) x USING (order_id) WHERE ABS(o.order_total - x.s) > 0.011;

-- no order or shipment is dated after 2026-09-30
SELECT COUNT(*) FROM orders WHERE date(order_date) > '2026-09-30' OR date(ship_date) > '2026-09-30';

-- email is built from the customer's own name and id
SELECT COUNT(*) FROM customers WHERE email NOT LIKE '%' || customer_id || '@example.com';
