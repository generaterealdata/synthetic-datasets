-- Synthetic Auto Insurance Policies and Claims: ten practice questions.
-- Written for SQLite (auto_insurance_claims.sqlite); most run unchanged on PostgreSQL.

-- 1. Claims and average claim amount by peril
SELECT peril, COUNT(*) AS claims, ROUND(AVG(claim_amount), 2) AS avg_claim, ROUND(SUM(paid_total), 2) AS total_paid
FROM claims GROUP BY peril ORDER BY claims DESC;

-- 2. Where does hail and flood happen?
SELECT loss_state, COUNT(*) AS claims, ROUND(100.0 * SUM(peril = 'hail') / COUNT(*), 1) AS hail_pct,
       ROUND(100.0 * SUM(peril = 'flood') / COUNT(*), 1) AS flood_pct
FROM claims GROUP BY loss_state ORDER BY hail_pct DESC;

-- 3. Loss ratio by coverage: paid claims versus premium
SELECT p.coverage, COUNT(*) AS policies, ROUND(SUM(p.annual_premium), 0) AS premium, ROUND(SUM(x.paid), 0) AS paid,
       ROUND(100.0 * SUM(x.paid) / SUM(p.annual_premium), 1) AS loss_ratio_pct
FROM policies p LEFT JOIN (SELECT policy_id, SUM(paid_total) AS paid FROM claims GROUP BY policy_id) x USING (policy_id)
GROUP BY p.coverage;

-- 4. Claim frequency: claims per policy by coverage
SELECT p.coverage, COUNT(DISTINCT p.policy_id) AS policies, COUNT(c.claim_id) AS claims,
       ROUND(1.0 * COUNT(c.claim_id) / COUNT(DISTINCT p.policy_id), 2) AS claims_per_policy
FROM policies p LEFT JOIN claims c USING (policy_id) GROUP BY p.coverage;

-- 5. Open claims and the reserve held for them
SELECT status, COUNT(*) AS claims, ROUND(SUM(reserve_amount), 2) AS reserve
FROM claims WHERE status IN ('filed', 'under_review', 'investigation') GROUP BY status;

-- 6. Claim status by month of loss in 2026
SELECT substr(loss_date, 1, 7) AS loss_month, SUM(status = 'paid') AS paid, SUM(status = 'denied') AS denied,
       SUM(status IN ('filed', 'under_review', 'investigation')) AS still_open
FROM claims WHERE loss_date >= '2026-01-01' GROUP BY loss_month ORDER BY loss_month;

-- 7. How long from report to payment?
SELECT CAST(julianday(p.paid_on) - julianday(c.reported_on) AS INTEGER) / 10 * 10 AS days_from, COUNT(*) AS payments
FROM claim_payments p JOIN claims c USING (claim_id) GROUP BY days_from ORDER BY days_from;

-- 8. Share of the claim amount that gets paid, by payee
SELECT p.payee, COUNT(*) AS payments, ROUND(100.0 * SUM(p.amount) / SUM(c.claim_amount), 1) AS paid_pct_of_claimed
FROM claim_payments p JOIN claims c USING (claim_id) GROUP BY p.payee ORDER BY payments DESC;

-- 9. Policyholders with the most claims
SELECT h.policyholder_id, h.full_name, h.state, COUNT(DISTINCT p.policy_id) AS policies, COUNT(c.claim_id) AS claims
FROM policyholders h JOIN policies p USING (policyholder_id) JOIN claims c USING (policy_id)
GROUP BY h.policyholder_id ORDER BY claims DESC LIMIT 10;

-- 10. Theft claims by vehicle model
SELECT v.make, v.model, COUNT(*) AS theft_claims, ROUND(AVG(c.claim_amount), 2) AS avg_claim
FROM claims c JOIN policies p USING (policy_id) JOIN vehicles v USING (vehicle_id)
WHERE c.peril = 'theft' GROUP BY v.make, v.model ORDER BY theft_claims DESC LIMIT 10;
