-- Black Friday and Cyber Week Sales 2023-2025: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py black-friday-sales <database file>

-- purchases.purchase_id is unique
SELECT COUNT(*) - COUNT(DISTINCT purchase_id) FROM purchases;

-- every order falls between 1 November and the end of Cyber Week
SELECT COUNT(*) FROM purchases WHERE NOT ((order_date BETWEEN '2023-11-01' AND '2023-12-01') OR (order_date BETWEEN '2024-11-01' AND '2024-12-06') OR (order_date BETWEEN '2025-11-01' AND '2025-12-05'));

-- year is the year of the order date
SELECT COUNT(*) FROM purchases WHERE year <> CAST(substr(order_date, 1, 4) AS INTEGER);

-- Black Friday rows are dated on Black Friday
SELECT COUNT(*) FROM purchases WHERE (event_day = 'Black Friday') <> (order_date IN ('2023-11-24', '2024-11-29', '2025-11-28'));

-- Cyber Monday rows are dated on Cyber Monday
SELECT COUNT(*) FROM purchases WHERE (event_day = 'Cyber Monday') <> (order_date IN ('2023-11-27', '2024-12-02', '2025-12-01'));

-- Thanksgiving rows are dated on Thanksgiving
SELECT COUNT(*) FROM purchases WHERE (event_day = 'Thanksgiving') <> (order_date IN ('2023-11-23', '2024-11-28', '2025-11-27'));

-- order_hour is 0-23
SELECT COUNT(*) FROM purchases WHERE order_hour NOT BETWEEN 0 AND 23;

-- store purchases are made in store, and only they
SELECT COUNT(*) FROM purchases WHERE (channel = 'Store') <> (device = 'In store') OR (channel = 'Store') <> (fulfilment = 'Store purchase');

-- only store purchases have no delivery time
SELECT COUNT(*) FROM purchases WHERE (fulfilment = 'Store purchase') <> (delivery_days IS NULL);

-- delivery time matches the fulfilment
SELECT COUNT(*) FROM purchases WHERE (fulfilment = 'Pick up in store' AND delivery_days > 1) OR (fulfilment = 'Express shipping' AND delivery_days NOT BETWEEN 1 AND 2) OR (fulfilment = 'Free 2-day shipping' AND delivery_days NOT BETWEEN 2 AND 3) OR (fulfilment = 'Standard shipping' AND delivery_days NOT BETWEEN 3 AND 10);

-- free 2-day shipping is for loyalty members only
SELECT COUNT(*) FROM purchases WHERE fulfilment = 'Free 2-day shipping' AND customer_segment <> 'Loyalty member';

-- product_name = brand + product type
SELECT COUNT(*) FROM purchases WHERE product_name <> brand || ' ' || product_type;

-- each product type belongs to one category
SELECT COUNT(*) FROM (SELECT product_type FROM purchases GROUP BY product_type HAVING COUNT(DISTINCT product_category) > 1);

-- each brand belongs to one category
SELECT COUNT(*) FROM (SELECT brand FROM purchases GROUP BY brand HAVING COUNT(DISTINCT product_category) > 1);

-- list prices end in .99
SELECT COUNT(*) FROM purchases WHERE ABS(list_price - ROUND(list_price) + 0.01) > 0.001;

-- discount is 0-70%
SELECT COUNT(*) FROM purchases WHERE discount_pct NOT BETWEEN 0 AND 70;

-- unit_price = list_price less the discount
SELECT COUNT(*) FROM purchases WHERE ABS(unit_price - ROUND(list_price * (100 - discount_pct) / 100.0, 2)) > 0.011;

-- line_total = unit_price x quantity
SELECT COUNT(*) FROM purchases WHERE ABS(line_total - unit_price * quantity) > 0.011;

-- coupon savings are 0 without a coupon and 5-15% of the line with one
SELECT COUNT(*) FROM purchases WHERE (coupon_used = 0 AND coupon_savings <> 0) OR (coupon_used = 1 AND (coupon_savings < line_total * 0.05 - 0.011 OR coupon_savings > line_total * 0.15 + 0.011));

-- order_total = line_total - coupon savings
SELECT COUNT(*) FROM purchases WHERE ABS(order_total - (line_total - coupon_savings)) > 0.011;

-- a return reason is given exactly for returned purchases
SELECT COUNT(*) FROM purchases WHERE (is_returned = 1) <> (return_reason IS NOT NULL);

-- 'Wrong size' is a return reason for apparel only
SELECT COUNT(*) FROM purchases WHERE return_reason = 'Wrong size' AND product_category <> 'Apparel';

-- ratings are 1-5
SELECT COUNT(*) FROM purchases WHERE customer_rating NOT BETWEEN 1 AND 5;
