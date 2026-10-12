-- Synthetic SaaS Subscriptions and Churn: ten practice questions.
-- Written for SQLite (saas_subscriptions.sqlite); most run unchanged on PostgreSQL.

-- 1. Current MRR by plan
SELECT p.plan_name, COUNT(*) AS active_subscriptions, SUM(s.seats) AS seats, ROUND(SUM(s.mrr), 2) AS mrr
FROM subscriptions s JOIN plans p USING (plan_id)
WHERE s.status <> 'cancelled'
GROUP BY p.plan_name ORDER BY mrr DESC;

-- 2. Churn rate by tier
SELECT p.tier, COUNT(*) AS subscriptions, SUM(s.status = 'cancelled') AS cancelled,
       ROUND(100.0 * SUM(s.status = 'cancelled') / COUNT(*), 1) AS churn_pct
FROM subscriptions s JOIN plans p USING (plan_id) GROUP BY p.tier ORDER BY churn_pct DESC;

-- 3. Why do customers leave, and how do they feel about it?
SELECT reason, COUNT(*) AS churned, ROUND(AVG(feedback_score), 2) AS avg_feedback
FROM churn_events GROUP BY reason ORDER BY churned DESC;

-- 4. New subscriptions and cancellations per quarter
SELECT quarter, SUM(started) AS started, SUM(cancelled) AS cancelled
FROM (SELECT substr(started_on, 1, 4) || '-Q' || ((CAST(substr(started_on, 6, 2) AS INTEGER) + 2) / 3) AS quarter, 1 AS started, 0 AS cancelled FROM subscriptions
      UNION ALL
      SELECT substr(ended_on, 1, 4) || '-Q' || ((CAST(substr(ended_on, 6, 2) AS INTEGER) + 2) / 3), 0, 1 FROM subscriptions WHERE ended_on IS NOT NULL)
GROUP BY quarter ORDER BY quarter;

-- 5. How long do cancelled subscriptions last?
SELECT CASE WHEN months < 6 THEN '0-5 months' WHEN months < 12 THEN '6-11 months' WHEN months < 24 THEN '12-23 months' ELSE '24+ months' END AS lifetime,
       COUNT(*) AS subscriptions
FROM (SELECT (julianday(ended_on) - julianday(started_on)) / 30.44 AS months FROM subscriptions WHERE status = 'cancelled')
GROUP BY lifetime ORDER BY MIN(months);

-- 6. Average revenue per account by company size
SELECT a.employee_band, COUNT(DISTINCT a.account_id) AS accounts, ROUND(AVG(s.seats), 1) AS avg_seats, ROUND(AVG(s.mrr), 2) AS avg_mrr
FROM subscriptions s JOIN accounts a USING (account_id)
WHERE s.status <> 'cancelled'
GROUP BY a.employee_band ORDER BY avg_mrr;

-- 7. Collections: invoiced, collected and outstanding per year
SELECT substr(issued_on, 1, 4) AS year, ROUND(SUM(amount_due), 2) AS invoiced, ROUND(SUM(amount_paid), 2) AS collected,
       ROUND(SUM(CASE WHEN status IN ('open', 'past_due') THEN amount_due ELSE 0 END), 2) AS outstanding
FROM invoices GROUP BY year;

-- 8. How fast do customers pay?
SELECT CAST(julianday(paid_on) - julianday(issued_on) AS INTEGER) / 5 * 5 AS days_from, COUNT(*) AS invoices
FROM invoices WHERE status = 'paid' GROUP BY days_from ORDER BY days_from;

-- 9. Which acquisition channel brings the most valuable accounts?
SELECT a.acquisition_channel, COUNT(DISTINCT a.account_id) AS accounts, ROUND(SUM(s.mrr), 2) AS mrr,
       ROUND(100.0 * SUM(s.status = 'cancelled') / COUNT(*), 1) AS churn_pct
FROM accounts a JOIN subscriptions s USING (account_id)
GROUP BY a.acquisition_channel ORDER BY mrr DESC;

-- 10. Signup cohorts: share of each year's accounts that still has a live subscription
SELECT substr(a.signup_date, 1, 4) AS signup_year, COUNT(*) AS accounts,
       ROUND(100.0 * SUM(EXISTS (SELECT 1 FROM subscriptions s WHERE s.account_id = a.account_id AND s.status <> 'cancelled')) / COUNT(*), 1) AS retained_pct
FROM accounts a GROUP BY signup_year;
