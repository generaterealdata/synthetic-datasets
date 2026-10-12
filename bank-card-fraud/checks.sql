-- Synthetic Bank Card Transactions with Fraud Labels: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py bank-card-fraud <database file>

-- customers.customer_id is unique
SELECT COUNT(*) - COUNT(DISTINCT customer_id) FROM customers;

-- accounts.account_id is unique
SELECT COUNT(*) - COUNT(DISTINCT account_id) FROM accounts;

-- accounts.iban is unique
SELECT COUNT(*) - COUNT(DISTINCT iban) FROM accounts;

-- cards.card_id is unique
SELECT COUNT(*) - COUNT(DISTINCT card_id) FROM cards;

-- merchants.merchant_id is unique
SELECT COUNT(*) - COUNT(DISTINCT merchant_id) FROM merchants;

-- transactions.txn_id is unique
SELECT COUNT(*) - COUNT(DISTINCT txn_id) FROM transactions;

-- every accounts.customer_id exists in customers
SELECT COUNT(*) FROM accounts c LEFT JOIN customers p ON p.customer_id = c.customer_id WHERE c.customer_id IS NOT NULL AND p.customer_id IS NULL;

-- every cards.account_id exists in accounts
SELECT COUNT(*) FROM cards c LEFT JOIN accounts p ON p.account_id = c.account_id WHERE c.account_id IS NOT NULL AND p.account_id IS NULL;

-- every transactions.card_id exists in cards
SELECT COUNT(*) FROM transactions c LEFT JOIN cards p ON p.card_id = c.card_id WHERE c.card_id IS NOT NULL AND p.card_id IS NULL;

-- every transactions.merchant_id exists in merchants
SELECT COUNT(*) FROM transactions c LEFT JOIN merchants p ON p.merchant_id = c.merchant_id WHERE c.merchant_id IS NOT NULL AND p.merchant_id IS NULL;

-- a city never appears under two countries
SELECT COUNT(*) FROM (SELECT city FROM customers GROUP BY city HAVING COUNT(DISTINCT country) > 1);

-- every customer has an account
SELECT COUNT(*) FROM customers c WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.customer_id = c.customer_id);

-- every account has a card
SELECT COUNT(*) FROM accounts a WHERE NOT EXISTS (SELECT 1 FROM cards c WHERE c.account_id = a.account_id);

-- account opened after the customer joined
SELECT COUNT(*) FROM accounts a JOIN customers c USING (customer_id) WHERE date(a.opened_on) < date(c.joined_on);

-- card issued after the account opened
SELECT COUNT(*) FROM cards c JOIN accounts a USING (account_id) WHERE date(c.issued_on) < date(a.opened_on);

-- card_last4 is four digits
SELECT COUNT(*) FROM cards WHERE card_last4 NOT GLOB '[0-9][0-9][0-9][0-9]';

-- a merchant category always has the same mcc
SELECT COUNT(*) FROM (SELECT category FROM merchants GROUP BY category HAVING COUNT(DISTINCT mcc) > 1);

-- account currency follows the customer's country
SELECT COUNT(*) FROM (SELECT c.country FROM accounts a JOIN customers c USING (customer_id) GROUP BY c.country HAVING COUNT(DISTINCT a.currency) > 1);

-- transaction currency is the account's currency
SELECT COUNT(*) FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) WHERE t.currency <> a.currency;

-- fraud rate is between 1% and 2%
SELECT CASE WHEN AVG(is_fraud) BETWEEN 0.01 AND 0.02 THEN 0 ELSE 1 END FROM transactions;

-- fraud transactions show high velocity (3+ in the last hour)
SELECT COUNT(*) FROM transactions WHERE is_fraud = 1 AND txns_last_1h < 3;

-- genuine transactions show low velocity (1-2)
SELECT COUNT(*) FROM transactions WHERE is_fraud = 0 AND txns_last_1h > 2;

-- fraud happens far from the last transaction (800+ km)
SELECT COUNT(*) FROM transactions WHERE is_fraud = 1 AND km_from_last < 800;

-- genuine transactions are entered in the customer's country
SELECT COUNT(*) FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) JOIN customers u USING (customer_id) WHERE t.is_fraud = 0 AND t.entry_country <> u.country;

-- fraud is entered outside the customer's country
SELECT COUNT(*) FROM transactions t JOIN cards c USING (card_id) JOIN accounts a USING (account_id) JOIN customers u USING (customer_id) WHERE t.is_fraud = 1 AND t.entry_country = u.country;

-- amounts are positive
SELECT COUNT(*) FROM transactions WHERE amount <= 0;

-- no transaction is dated before its card was issued
SELECT COUNT(*) FROM transactions t JOIN cards c USING (card_id) WHERE date(t.txn_time) < date(c.issued_on);

-- all transactions fall between 2026-04-01 and 2026-09-30
SELECT COUNT(*) FROM transactions WHERE date(txn_time) < '2026-04-01' OR date(txn_time) > '2026-09-30';

-- no card makes more than 12 transactions a day on average
SELECT COUNT(*) FROM (SELECT card_id FROM transactions GROUP BY card_id HAVING COUNT(*) > 12 * 183);
