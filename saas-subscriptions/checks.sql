-- Synthetic SaaS Subscriptions and Churn: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py saas-subscriptions <database file>

-- plans.plan_id is unique
SELECT COUNT(*) - COUNT(DISTINCT plan_id) FROM plans;

-- accounts.account_id is unique
SELECT COUNT(*) - COUNT(DISTINCT account_id) FROM accounts;

-- users.email is unique
SELECT COUNT(*) - COUNT(DISTINCT email) FROM users;

-- subscriptions.subscription_id is unique
SELECT COUNT(*) - COUNT(DISTINCT subscription_id) FROM subscriptions;

-- invoices.invoice_id is unique
SELECT COUNT(*) - COUNT(DISTINCT invoice_id) FROM invoices;

-- every users.account_id exists in accounts
SELECT COUNT(*) FROM users c LEFT JOIN accounts p ON p.account_id = c.account_id WHERE c.account_id IS NOT NULL AND p.account_id IS NULL;

-- every subscriptions.account_id exists in accounts
SELECT COUNT(*) FROM subscriptions c LEFT JOIN accounts p ON p.account_id = c.account_id WHERE c.account_id IS NOT NULL AND p.account_id IS NULL;

-- every subscriptions.plan_id exists in plans
SELECT COUNT(*) FROM subscriptions c LEFT JOIN plans p ON p.plan_id = c.plan_id WHERE c.plan_id IS NOT NULL AND p.plan_id IS NULL;

-- every invoices.subscription_id exists in subscriptions
SELECT COUNT(*) FROM invoices c LEFT JOIN subscriptions p ON p.subscription_id = c.subscription_id WHERE c.subscription_id IS NOT NULL AND p.subscription_id IS NULL;

-- every churn_events.subscription_id exists in subscriptions
SELECT COUNT(*) FROM churn_events c LEFT JOIN subscriptions p ON p.subscription_id = c.subscription_id WHERE c.subscription_id IS NOT NULL AND p.subscription_id IS NULL;

-- there are exactly eight plans
SELECT CASE WHEN COUNT(*) = 8 THEN 0 ELSE 1 END FROM plans;

-- every account has a subscription
SELECT COUNT(*) FROM accounts a WHERE NOT EXISTS (SELECT 1 FROM subscriptions s WHERE s.account_id = a.account_id);

-- subscription starts on or after the account's signup
SELECT COUNT(*) FROM subscriptions s JOIN accounts a USING (account_id) WHERE date(s.started_on) < date(a.signup_date);

-- billing cycle matches the plan name
SELECT COUNT(*) FROM subscriptions s JOIN plans p USING (plan_id) WHERE (p.plan_name LIKE '%Annual%') <> (s.billing_cycle = 'annual');

-- mrr = seats x the plan's monthly price
SELECT COUNT(*) FROM subscriptions s JOIN plans p USING (plan_id) WHERE ABS(s.mrr - s.seats * p.monthly_price) > 0.011;

-- ended_on is set exactly for cancelled subscriptions
SELECT COUNT(*) FROM subscriptions WHERE (status = 'cancelled') <> (ended_on IS NOT NULL);

-- a subscription ends after it starts and by 2026-09-30
SELECT COUNT(*) FROM subscriptions WHERE ended_on IS NOT NULL AND (date(ended_on) <= date(started_on) OR date(ended_on) > '2026-09-30');

-- every cancelled subscription has exactly one churn event
SELECT COUNT(*) FROM subscriptions s WHERE s.status = 'cancelled' AND (SELECT COUNT(*) FROM churn_events c WHERE c.subscription_id = s.subscription_id) <> 1;

-- churn events exist only for cancelled subscriptions
SELECT COUNT(*) FROM churn_events c JOIN subscriptions s USING (subscription_id) WHERE s.status <> 'cancelled';

-- churned_on equals the subscription's ended_on
SELECT COUNT(*) FROM churn_events c JOIN subscriptions s USING (subscription_id) WHERE date(c.churned_on) <> date(s.ended_on);

-- invoice amount_due equals the subscription's mrr
SELECT COUNT(*) FROM invoices i JOIN subscriptions s USING (subscription_id) WHERE ABS(i.amount_due - s.mrr) > 0.011;

-- invoice period starts on or after the subscription start
SELECT COUNT(*) FROM invoices i JOIN subscriptions s USING (subscription_id) WHERE date(i.period_start) < date(s.started_on);

-- paid invoices are paid in full, others not at all
SELECT COUNT(*) FROM invoices WHERE (status = 'paid' AND ABS(amount_paid - amount_due) > 0.011) OR (status <> 'paid' AND amount_paid <> 0);

-- paid_on is set exactly for paid invoices, 0-20 days after issue
SELECT COUNT(*) FROM invoices WHERE (status = 'paid') <> (paid_on IS NOT NULL) OR (paid_on IS NOT NULL AND julianday(paid_on) - julianday(issued_on) NOT BETWEEN 0 AND 20);

-- user created on or after the account's signup
SELECT COUNT(*) FROM users u JOIN accounts a USING (account_id) WHERE date(u.created_at) < date(a.signup_date);

-- last login is after creation
SELECT COUNT(*) FROM users WHERE last_login_at IS NOT NULL AND datetime(last_login_at) < datetime(created_at);

-- no subscription starts after 2026-09-30
SELECT COUNT(*) FROM subscriptions WHERE date(started_on) > '2026-09-30';

-- no invoice period starts after 2026-09-30
SELECT COUNT(*) FROM invoices WHERE date(period_start) > '2026-09-30';

-- no user was created or logged in after 2026-09-30
SELECT COUNT(*) FROM users WHERE date(created_at) > '2026-09-30' OR date(last_login_at) > '2026-09-30';

-- seats are between 1 and 500
SELECT COUNT(*) FROM subscriptions WHERE seats NOT BETWEEN 1 AND 500;
