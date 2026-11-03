-- Black Friday and Cyber Week Sales 2023-2025: ten practice questions.
-- Written for SQLite (black_friday_sales.sqlite); most run unchanged on PostgreSQL.

-- 1. Purchases, revenue and average discount by event day
SELECT event_day, COUNT(*) AS purchases, ROUND(SUM(order_total)) AS revenue_usd, ROUND(AVG(discount_pct), 1) AS avg_discount_pct
FROM purchases GROUP BY event_day ORDER BY revenue_usd DESC;

-- 2. Growth from year to year
SELECT year, COUNT(*) AS purchases, ROUND(SUM(order_total)) AS revenue_usd,
       ROUND(100.0 * SUM(order_total) / LAG(SUM(order_total)) OVER (ORDER BY year) - 100, 1) AS revenue_growth_pct
FROM purchases GROUP BY year ORDER BY year;

-- 3. The busiest hour of Thanksgiving, Black Friday and Cyber Monday (window function)
SELECT event_day, order_hour, purchases FROM (
    SELECT event_day, order_hour, COUNT(*) AS purchases,
           ROW_NUMBER() OVER (PARTITION BY event_day ORDER BY COUNT(*) DESC) AS rnk
    FROM purchases WHERE event_day IN ('Thanksgiving', 'Black Friday', 'Cyber Monday')
    GROUP BY event_day, order_hour)
WHERE rnk = 1;

-- 4. Return rate by product category
SELECT product_category, COUNT(*) AS purchases, ROUND(100.0 * AVG(is_returned), 1) AS return_rate_pct
FROM purchases GROUP BY product_category ORDER BY return_rate_pct DESC;

-- 5. Do deeper discounts bring more returns?
SELECT (discount_pct / 10) * 10 AS discount_from_pct, COUNT(*) AS purchases, ROUND(100.0 * AVG(is_returned), 1) AS return_rate_pct
FROM purchases GROUP BY discount_from_pct ORDER BY discount_from_pct;

-- 6. Channel mix on each event day (pivot)
SELECT event_day,
       ROUND(100.0 * AVG(channel = 'Web'), 1) AS web_pct,
       ROUND(100.0 * AVG(channel = 'App'), 1) AS app_pct,
       ROUND(100.0 * AVG(channel = 'Store'), 1) AS store_pct
FROM purchases GROUP BY event_day ORDER BY store_pct DESC;

-- 7. The ten products with the most revenue
SELECT product_name, product_category, COUNT(*) AS purchases, ROUND(SUM(order_total)) AS revenue_usd
FROM purchases GROUP BY product_name, product_category ORDER BY revenue_usd DESC LIMIT 10;

-- 8. Buy now, pay later: who uses it and how often it is returned
SELECT CASE WHEN order_total >= 400 THEN '$400 or more' ELSE 'under $400' END AS order_size,
       ROUND(100.0 * AVG(payment_method = 'Buy now, pay later'), 1) AS pay_later_share_pct,
       ROUND(100.0 * AVG(CASE WHEN payment_method = 'Buy now, pay later' THEN is_returned END), 1) AS pay_later_return_pct,
       ROUND(100.0 * AVG(CASE WHEN payment_method <> 'Buy now, pay later' THEN is_returned END), 1) AS other_return_pct
FROM purchases GROUP BY order_size;

-- 9. Delivery days by fulfilment, on the busiest days and the rest
SELECT fulfilment,
       ROUND(AVG(CASE WHEN event_day IN ('Black Friday', 'Black Friday weekend', 'Cyber Monday') THEN delivery_days END), 1) AS busy_days,
       ROUND(AVG(CASE WHEN event_day NOT IN ('Black Friday', 'Black Friday weekend', 'Cyber Monday') THEN delivery_days END), 1) AS other_days
FROM purchases WHERE delivery_days IS NOT NULL GROUP BY fulfilment ORDER BY busy_days;

-- 10. Coupons: how often they are used and what they save, by event day
SELECT event_day, ROUND(100.0 * AVG(coupon_used), 1) AS coupon_share_pct,
       ROUND(AVG(CASE WHEN coupon_used = 1 THEN coupon_savings END), 2) AS avg_saving_usd
FROM purchases GROUP BY event_day ORDER BY coupon_share_pct DESC;
