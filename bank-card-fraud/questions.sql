-- Synthetic Bank Card Transactions with Fraud Labels: ten practice questions.
-- Written for SQLite (bank_card_fraud.sqlite); most run unchanged on PostgreSQL.

-- 1. Fraud rate overall and by channel
SELECT channel, COUNT(*) AS transactions, SUM(is_fraud) AS fraud,
       ROUND(100.0 * SUM(is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions GROUP BY channel ORDER BY fraud_rate_pct DESC;

-- 2. Fraud rate by amount band
SELECT CASE WHEN amount < 100 THEN '1. under 100' WHEN amount < 300 THEN '2. 100-299'
            WHEN amount < 1000 THEN '3. 300-999' ELSE '4. 1000 and over' END AS amount_band,
       COUNT(*) AS transactions, SUM(is_fraud) AS fraud, ROUND(100.0 * SUM(is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions GROUP BY amount_band ORDER BY amount_band;

-- 3. Spend and average ticket by merchant category
SELECT m.category, m.mcc, COUNT(*) AS transactions, ROUND(SUM(t.amount), 2) AS spend, ROUND(AVG(t.amount), 2) AS avg_ticket
FROM transactions t JOIN merchants m USING (merchant_id)
WHERE t.is_declined = 0 AND t.is_fraud = 0
GROUP BY m.category, m.mcc ORDER BY spend DESC;

-- 4. How different are fraud and genuine transactions?
SELECT is_fraud, COUNT(*) AS transactions, ROUND(AVG(amount), 2) AS avg_amount,
       ROUND(AVG(km_from_last), 1) AS avg_km_from_last, ROUND(AVG(txns_last_1h), 2) AS avg_txns_last_1h,
       ROUND(100.0 * AVG(is_declined), 1) AS declined_pct
FROM transactions GROUP BY is_fraud;

-- 5. Countries where fraud is entered
SELECT entry_country, COUNT(*) AS fraud_transactions, ROUND(SUM(amount), 2) AS fraud_amount
FROM transactions WHERE is_fraud = 1
GROUP BY entry_country ORDER BY fraud_transactions DESC;

-- 6. Customers who lost the most to fraud that was not declined
SELECT u.customer_id, u.full_name, u.country, COUNT(*) AS fraud_transactions, ROUND(SUM(t.amount), 2) AS amount_lost
FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) JOIN customers u USING (customer_id)
WHERE t.is_fraud = 1 AND t.is_declined = 0
GROUP BY u.customer_id ORDER BY amount_lost DESC LIMIT 10;

-- 7. Does the customer's risk segment predict fraud?
SELECT u.risk_segment, COUNT(*) AS transactions, ROUND(100.0 * SUM(t.is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) JOIN customers u USING (customer_id)
GROUP BY u.risk_segment;

-- 8. A simple rule: flag transactions entered outside the customer's country
SELECT flagged, COUNT(*) AS transactions, SUM(is_fraud) AS fraud
FROM (SELECT t.is_fraud, t.entry_country <> u.country AS flagged
      FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) JOIN customers u USING (customer_id))
GROUP BY flagged;

-- 9. The ten busiest cards
SELECT card_id, COUNT(*) AS transactions, ROUND(SUM(amount), 2) AS total_spend
FROM transactions GROUP BY card_id ORDER BY transactions DESC LIMIT 10;

-- 10. Daily spend with a 7-day moving average (window function)
SELECT day, spend, ROUND(AVG(spend) OVER (ORDER BY day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS spend_7d_avg
FROM (SELECT date(txn_time) AS day, ROUND(SUM(amount), 2) AS spend FROM transactions WHERE is_declined = 0 GROUP BY day)
ORDER BY day LIMIT 30;
