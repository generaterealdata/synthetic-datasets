-- Synthetic E-commerce Database: ten practice questions.
-- Written for SQLite (ecommerce.sqlite); most run unchanged on PostgreSQL.

-- 1. Monthly revenue and order count
SELECT substr(order_date, 1, 7) AS month, COUNT(*) AS orders, ROUND(SUM(total_amount), 2) AS revenue
FROM orders WHERE status <> 'cancelled'
GROUP BY month ORDER BY month;

-- 2. Top 10 customers by lifetime spend
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer, c.country,
       COUNT(*) AS orders, ROUND(SUM(o.total_amount), 2) AS spend
FROM orders o JOIN customers c USING (customer_id)
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id ORDER BY spend DESC LIMIT 10;

-- 3. Revenue and gross margin by category
SELECT p.category, ROUND(SUM(i.line_total), 2) AS revenue,
       ROUND(100.0 * SUM(i.line_total - i.quantity * p.unit_cost) / SUM(i.line_total), 1) AS margin_pct
FROM order_items i JOIN products p USING (product_id) JOIN orders o USING (order_id)
WHERE o.status NOT IN ('cancelled', 'returned')
GROUP BY p.category ORDER BY revenue DESC;

-- 4. How many customers order once, twice, three times or more?
SELECT CASE WHEN n = 1 THEN '1 order' WHEN n = 2 THEN '2 orders' WHEN n <= 5 THEN '3-5 orders' ELSE '6+ orders' END AS bucket,
       COUNT(*) AS customers
FROM (SELECT customer_id, COUNT(*) AS n FROM orders GROUP BY customer_id)
GROUP BY bucket ORDER BY MIN(n);

-- 5. Return rate by category
SELECT p.category, COUNT(r.return_id) AS returned_lines, COUNT(*) AS lines,
       ROUND(100.0 * COUNT(r.return_id) / COUNT(*), 2) AS return_rate_pct
FROM order_items i JOIN products p USING (product_id) LEFT JOIN returns r USING (order_item_id)
GROUP BY p.category ORDER BY return_rate_pct DESC;

-- 6. Average delivery time by carrier, in days
SELECT carrier, COUNT(*) AS deliveries,
       ROUND(AVG(julianday(delivered_at) - julianday(shipped_at)), 2) AS avg_days
FROM shipments WHERE delivered_at IS NOT NULL
GROUP BY carrier ORDER BY avg_days;

-- 7. Average order value by channel and loyalty tier
SELECT o.channel, c.loyalty_tier, COUNT(*) AS orders, ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o JOIN customers c USING (customer_id)
GROUP BY o.channel, c.loyalty_tier ORDER BY o.channel, avg_order_value DESC;

-- 8. Share of orders that got free shipping, per year
SELECT substr(order_date, 1, 4) AS year,
       ROUND(100.0 * SUM(shipping_fee = 0) / COUNT(*), 1) AS free_shipping_pct
FROM orders GROUP BY year;

-- 9. Products most often bought together
SELECT a.product_id AS product_a, b.product_id AS product_b, COUNT(*) AS orders_together
FROM order_items a JOIN order_items b ON a.order_id = b.order_id AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id ORDER BY orders_together DESC LIMIT 10;

-- 10. Running total of revenue per month (window function)
SELECT month, revenue, ROUND(SUM(revenue) OVER (ORDER BY month), 2) AS running_revenue
FROM (SELECT substr(order_date, 1, 7) AS month, ROUND(SUM(total_amount), 2) AS revenue
      FROM orders WHERE status <> 'cancelled' GROUP BY month)
ORDER BY month;
