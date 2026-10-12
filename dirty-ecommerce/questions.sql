-- Dirty E-commerce Data for Cleaning Practice: ten practice questions.
-- Written for SQLite (dirty_ecommerce.sqlite); most run unchanged on PostgreSQL.

-- 1. How many placeholder values hide in each customer text column?
SELECT 'full_name' AS col, SUM(full_name IN ('', 'N/A', 'UNKNOWN', 'ERROR')) AS placeholders FROM customers
UNION ALL SELECT 'email', SUM(email IN ('', 'N/A', 'UNKNOWN', 'ERROR')) FROM customers
UNION ALL SELECT 'country', SUM(country IN ('', 'N/A', 'UNKNOWN', 'ERROR')) FROM customers
UNION ALL SELECT 'city', SUM(city IN ('', 'N/A', 'UNKNOWN', 'ERROR')) FROM customers;

-- 2. Emails that are not valid addresses
SELECT email, COUNT(*) AS n FROM customers
WHERE email NOT LIKE '%_@_%._%' GROUP BY email ORDER BY n DESC;

-- 3. Impossible dates: sentinel values and customers born in the future
SELECT SUM(birth_date IN ('1900-01-01', '2099-12-31')) AS sentinel_birth_dates,
       SUM(signup_date IN ('1900-01-01', '2099-12-31')) AS sentinel_signup_dates,
       SUM(birth_date > signup_date) AS born_after_signup
FROM customers;

-- 4. Orders shipped before they were placed, or shipped although pending or cancelled
SELECT SUM(ship_date < order_date) AS shipped_before_ordered,
       SUM(status IN ('pending', 'cancelled') AND ship_date IS NOT NULL) AS shipped_but_not_sent,
       SUM(status IN ('shipped', 'delivered') AND ship_date IS NULL) AS sent_without_ship_date
FROM orders;

-- 5. Lines whose total is not quantity x unit price
SELECT COUNT(*) AS bad_lines FROM order_items
WHERE ABS(line_total - quantity * unit_price) > 0.011;

-- 6. Negative or zero quantities and prices
SELECT SUM(quantity <= 0) AS bad_quantity, SUM(unit_price <= 0) AS bad_price, SUM(line_total <= 0) AS bad_total
FROM order_items;

-- 7. Price outliers: lines priced far above the product's catalogue price
SELECT i.order_item_id, p.product_name, p.unit_price AS catalogue_price, i.unit_price AS line_price
FROM order_items i JOIN products p USING (product_id)
WHERE i.unit_price > p.unit_price * 5 AND p.unit_price > 0
ORDER BY i.unit_price DESC LIMIT 10;

-- 8. Orders whose total does not match their lines
SELECT COUNT(*) AS mismatched_orders
FROM orders o JOIN (SELECT order_id, SUM(line_total) AS s FROM order_items GROUP BY order_id) x USING (order_id)
WHERE ABS(o.order_total - x.s) > 0.011;

-- 9. Orders whose country differs from the customer's country
SELECT o.country AS order_country, c.country AS customer_country, COUNT(*) AS orders
FROM orders o JOIN customers c USING (customer_id)
WHERE o.country <> c.country
GROUP BY 1, 2 ORDER BY orders DESC LIMIT 10;

-- 10. Cities that appear under more than one country
SELECT city, COUNT(DISTINCT country) AS countries, COUNT(*) AS customers
FROM customers WHERE city NOT IN ('', 'N/A', 'UNKNOWN', 'ERROR')
GROUP BY city HAVING COUNT(DISTINCT country) > 1 ORDER BY countries DESC, customers DESC LIMIT 10;
