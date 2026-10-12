-- Synthetic Web Analytics Funnel Events: ten practice questions.
-- Written for SQLite (web_funnel_events.sqlite); most run unchanged on PostgreSQL.

-- 1. The funnel: how many sessions reach each step?
SELECT event_name, COUNT(DISTINCT session_id) AS sessions,
       ROUND(100.0 * COUNT(DISTINCT session_id) / (SELECT COUNT(DISTINCT session_id) FROM events), 1) AS pct_of_sessions
FROM events WHERE event_name <> 'exit'
GROUP BY event_name ORDER BY sessions DESC;

-- 2. Conversion rate by device
SELECT s.device, COUNT(*) AS sessions, COUNT(c.conversion_id) AS purchases,
       ROUND(100.0 * COUNT(c.conversion_id) / COUNT(*), 2) AS conversion_pct
FROM sessions s LEFT JOIN conversions c USING (session_id) GROUP BY s.device;

-- 3. Revenue and average order value by referrer
SELECT s.referrer, COUNT(*) AS orders, ROUND(SUM(c.order_value), 2) AS revenue, ROUND(AVG(c.order_value), 2) AS avg_order_value
FROM conversions c JOIN sessions s USING (session_id) GROUP BY s.referrer ORDER BY revenue DESC;

-- 4. Where do sessions end? The step before exit
SELECT prev AS last_step_before_exit, COUNT(*) AS sessions
FROM (SELECT event_name, LAG(event_name) OVER (PARTITION BY session_id ORDER BY step_no) AS prev FROM events)
WHERE event_name = 'exit' GROUP BY prev ORDER BY sessions DESC;

-- 5. Cart abandonment: carts created versus carts bought
SELECT COUNT(*) AS sessions_with_cart, SUM(bought) AS purchased,
       ROUND(100.0 * (COUNT(*) - SUM(bought)) / COUNT(*), 1) AS abandonment_pct
FROM (SELECT session_id, MAX(event_name = 'purchase') AS bought
      FROM events GROUP BY session_id HAVING MAX(event_name = 'add_to_cart') = 1);

-- 6. The most common journeys
SELECT path, COUNT(*) AS sessions
FROM (SELECT session_id, GROUP_CONCAT(event_name, ' > ') AS path
      FROM (SELECT session_id, event_name FROM events ORDER BY session_id, step_no) GROUP BY session_id)
GROUP BY path ORDER BY sessions DESC LIMIT 10;

-- 7. Time from session start to purchase
SELECT ROUND(AVG((julianday(c.converted_at) - julianday(s.started_at)) * 1440), 2) AS avg_minutes_to_purchase,
       ROUND(MAX((julianday(c.converted_at) - julianday(s.started_at)) * 1440), 2) AS longest_minutes
FROM conversions c JOIN sessions s USING (session_id);

-- 8. Daily sessions and purchases
SELECT date(s.started_at) AS day, COUNT(*) AS sessions, COUNT(c.conversion_id) AS purchases
FROM sessions s LEFT JOIN conversions c USING (session_id) GROUP BY day ORDER BY day LIMIT 14;

-- 9. Which products are viewed most, and how often does a view lead to a purchase in the same session?
SELECT e.page_path, COUNT(*) AS views, COUNT(DISTINCT c.session_id) AS sessions_that_bought
FROM events e LEFT JOIN conversions c USING (session_id)
WHERE e.event_name = 'view_product' GROUP BY e.page_path ORDER BY views DESC;

-- 10. Do coupons go with bigger orders?
SELECT COALESCE(coupon_code, '(none)') AS coupon, COUNT(*) AS orders, ROUND(AVG(order_value), 2) AS avg_order_value, ROUND(AVG(items), 2) AS avg_items
FROM conversions GROUP BY coupon ORDER BY orders DESC;
