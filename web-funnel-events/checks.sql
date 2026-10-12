-- Synthetic Web Analytics Funnel Events: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py web-funnel-events <database file>

-- users.user_id is unique
SELECT COUNT(*) - COUNT(DISTINCT user_id) FROM users;

-- sessions.session_id is unique
SELECT COUNT(*) - COUNT(DISTINCT session_id) FROM sessions;

-- events.event_id is unique
SELECT COUNT(*) - COUNT(DISTINCT event_id) FROM events;

-- conversions.session_id is unique
SELECT COUNT(*) - COUNT(DISTINCT session_id) FROM conversions;

-- every sessions.user_id exists in users
SELECT COUNT(*) FROM sessions c LEFT JOIN users p ON p.user_id = c.user_id WHERE c.user_id IS NOT NULL AND p.user_id IS NULL;

-- every events.session_id exists in sessions
SELECT COUNT(*) FROM events c LEFT JOIN sessions p ON p.session_id = c.session_id WHERE c.session_id IS NOT NULL AND p.session_id IS NULL;

-- every conversions.session_id exists in sessions
SELECT COUNT(*) FROM conversions c LEFT JOIN sessions p ON p.session_id = c.session_id WHERE c.session_id IS NOT NULL AND p.session_id IS NULL;

-- session never starts before the user signed up
SELECT COUNT(*) FROM sessions s JOIN users u USING (user_id) WHERE date(s.started_at) < date(u.signup_date);

-- every journey starts with session_start
SELECT COUNT(*) FROM events WHERE step_no = 1 AND event_name <> 'session_start';

-- step numbers run 1, 2, 3 with no gaps
SELECT COUNT(*) FROM (SELECT session_id FROM events GROUP BY session_id HAVING MAX(step_no) <> COUNT(*) OR MIN(step_no) <> 1);

-- time moves forward within a session
SELECT COUNT(*) FROM (SELECT datetime(occurred_at) t, LAG(datetime(occurred_at)) OVER (PARTITION BY session_id ORDER BY step_no) p FROM events) WHERE p IS NOT NULL AND t < p;

-- nothing happens after purchase or exit
SELECT COUNT(*) FROM (SELECT LAG(event_name) OVER (PARTITION BY session_id ORDER BY step_no) prev FROM events) WHERE prev IN ('purchase', 'exit');

-- only allowed funnel moves occur
SELECT COUNT(*) FROM (SELECT event_name e, LAG(event_name) OVER (PARTITION BY session_id ORDER BY step_no) p FROM events) WHERE p IS NOT NULL AND NOT ((p = 'session_start' AND e IN ('view_product', 'search', 'exit')) OR (p = 'search' AND e IN ('view_product', 'exit')) OR (p = 'view_product' AND e IN ('add_to_cart', 'view_product', 'exit')) OR (p = 'add_to_cart' AND e IN ('begin_checkout', 'view_product', 'exit')) OR (p = 'begin_checkout' AND e IN ('purchase', 'exit')));

-- cart is empty before add_to_cart
SELECT COUNT(*) FROM events WHERE event_name IN ('session_start', 'search') AND cart_value <> 0;

-- purchase and checkout carry a cart value
SELECT COUNT(*) FROM events WHERE event_name IN ('add_to_cart', 'begin_checkout', 'purchase') AND cart_value <= 0;

-- the cart value stays the same within a session once something is added
SELECT COUNT(*) FROM (SELECT session_id FROM events WHERE cart_value > 0 GROUP BY session_id HAVING COUNT(DISTINCT cart_value) > 1);

-- session duration = sum of its steps' seconds
SELECT COUNT(*) FROM sessions s JOIN (SELECT session_id, SUM(secs_on_step) t FROM events GROUP BY session_id) x USING (session_id) WHERE s.duration_s <> x.t;

-- the first event happens at the session start
SELECT COUNT(*) FROM events e JOIN sessions s USING (session_id) WHERE e.step_no = 1 AND datetime(e.occurred_at) <> datetime(s.started_at);

-- every purchase has exactly one conversion
SELECT COUNT(*) FROM events e WHERE e.event_name = 'purchase' AND (SELECT COUNT(*) FROM conversions c WHERE c.session_id = e.session_id) <> 1;

-- conversions exist only for sessions that purchased
SELECT COUNT(*) FROM conversions c WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.session_id = c.session_id AND e.event_name = 'purchase');

-- conversion value equals the purchase's cart value
SELECT COUNT(*) FROM conversions c JOIN events e ON e.session_id = c.session_id AND e.event_name = 'purchase' WHERE ABS(c.order_value - e.cart_value) > 0.011;

-- every session has events
SELECT COUNT(*) FROM sessions s WHERE NOT EXISTS (SELECT 1 FROM events e WHERE e.session_id = s.session_id);

-- no session starts after 2026-09-30
SELECT COUNT(*) FROM sessions WHERE date(started_at) > '2026-09-30';
