-- Synthetic Auto Insurance Policies and Claims: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py auto-insurance-claims <database file>

-- policyholders.policyholder_id is unique
SELECT COUNT(*) - COUNT(DISTINCT policyholder_id) FROM policyholders;

-- vehicles.vin is unique
SELECT COUNT(*) - COUNT(DISTINCT vin) FROM vehicles;

-- policies.policy_number is unique
SELECT COUNT(*) - COUNT(DISTINCT policy_number) FROM policies;

-- policies.vehicle_id is unique
SELECT COUNT(*) - COUNT(DISTINCT vehicle_id) FROM policies;

-- claims.claim_number is unique
SELECT COUNT(*) - COUNT(DISTINCT claim_number) FROM claims;

-- every policies.policyholder_id exists in policyholders
SELECT COUNT(*) FROM policies c LEFT JOIN policyholders p ON p.policyholder_id = c.policyholder_id WHERE c.policyholder_id IS NOT NULL AND p.policyholder_id IS NULL;

-- every policies.vehicle_id exists in vehicles
SELECT COUNT(*) FROM policies c LEFT JOIN vehicles p ON p.vehicle_id = c.vehicle_id WHERE c.vehicle_id IS NOT NULL AND p.vehicle_id IS NULL;

-- every claims.policy_id exists in policies
SELECT COUNT(*) FROM claims c LEFT JOIN policies p ON p.policy_id = c.policy_id WHERE c.policy_id IS NOT NULL AND p.policy_id IS NULL;

-- every claim_payments.claim_id exists in claims
SELECT COUNT(*) FROM claim_payments c LEFT JOIN claims p ON p.claim_id = c.claim_id WHERE c.claim_id IS NOT NULL AND p.claim_id IS NULL;

-- VINs are 17 characters without I, O or Q
SELECT COUNT(*) FROM vehicles WHERE LENGTH(vin) <> 17 OR vin GLOB '*[IOQ]*';

-- a model always belongs to the same make
SELECT COUNT(*) FROM (SELECT model FROM vehicles GROUP BY model HAVING COUNT(DISTINCT make) > 1);

-- a city never appears under two states
SELECT COUNT(*) FROM (SELECT city FROM policyholders GROUP BY city HAVING COUNT(DISTINCT state) > 1);

-- licensed at 16 or older
SELECT COUNT(*) FROM policyholders WHERE (julianday(licensed_since) - julianday(date_of_birth)) / 365.25 < 15.99;

-- a policy lasts one year
SELECT COUNT(*) FROM policies WHERE julianday(end_date) - julianday(start_date) NOT BETWEEN 364 AND 366;

-- policies still running are active
SELECT COUNT(*) FROM policies WHERE date(end_date) >= '2026-10-01' AND status = 'expired';

-- loss date is inside the policy period
SELECT COUNT(*) FROM claims c JOIN policies p USING (policy_id) WHERE date(c.loss_date) < date(p.start_date) OR date(c.loss_date) > date(p.end_date);

-- reported 0-10 days after the loss
SELECT COUNT(*) FROM claims WHERE julianday(reported_on) - julianday(loss_date) NOT BETWEEN 0 AND 10;

-- loss state is the policyholder's state
SELECT COUNT(*) FROM claims c JOIN policies p USING (policy_id) JOIN policyholders h USING (policyholder_id) WHERE c.loss_state <> h.state;

-- hail is more common in TX, CO, OK and KS than elsewhere
SELECT CASE WHEN (SELECT AVG(peril = 'hail') FROM claims WHERE loss_state IN ('TX', 'CO', 'OK', 'KS')) > 2 * (SELECT AVG(peril = 'hail') FROM claims WHERE loss_state NOT IN ('TX', 'CO', 'OK', 'KS')) THEN 0 ELSE 1 END;

-- flood is more common in FL and LA than elsewhere
SELECT CASE WHEN (SELECT AVG(peril = 'flood') FROM claims WHERE loss_state IN ('FL', 'LA')) > 2 * (SELECT AVG(peril = 'flood') FROM claims WHERE loss_state NOT IN ('FL', 'LA')) THEN 0 ELSE 1 END;

-- open claims hold a reserve and no payment
SELECT COUNT(*) FROM claims WHERE status IN ('filed', 'under_review', 'investigation') AND (ABS(reserve_amount - claim_amount) > 0.011 OR paid_total <> 0);

-- denied claims have no reserve and no payment
SELECT COUNT(*) FROM claims WHERE status = 'denied' AND (reserve_amount <> 0 OR paid_total <> 0);

-- paid claims have no reserve left
SELECT COUNT(*) FROM claims WHERE status = 'paid' AND reserve_amount <> 0;

-- claim_payments.claim_id is unique
SELECT COUNT(*) - COUNT(DISTINCT claim_id) FROM claim_payments;

-- ended policies are expired or cancelled
SELECT COUNT(*) FROM policies WHERE date(end_date) < '2026-10-01' AND status = 'active';

-- no loss is dated after 30 September 2026
SELECT COUNT(*) FROM claims WHERE date(loss_date) > '2026-09-30';

-- a payment never exceeds the claim amount
SELECT COUNT(*) FROM claim_payments p JOIN claims c USING (claim_id) WHERE p.amount > c.claim_amount + 0.011;

-- payments exist only for paid claims
SELECT COUNT(*) FROM claim_payments p JOIN claims c USING (claim_id) WHERE c.status <> 'paid';

-- every paid claim has at least one payment
SELECT COUNT(*) FROM claims c WHERE c.status = 'paid' AND NOT EXISTS (SELECT 1 FROM claim_payments p WHERE p.claim_id = c.claim_id);

-- paid_total = sum of the claim's payments
SELECT COUNT(*) FROM claims c JOIN (SELECT claim_id, SUM(amount) s FROM claim_payments GROUP BY claim_id) x USING (claim_id) WHERE ABS(c.paid_total - x.s) > 0.011;

-- payment is made after the claim was reported
SELECT COUNT(*) FROM claim_payments p JOIN claims c USING (claim_id) WHERE date(p.paid_on) <= date(c.reported_on);

-- claims for losses from August 2026 on are not yet paid
SELECT COUNT(*) FROM claims WHERE status = 'paid' AND date(loss_date) >= '2026-08-01';

-- claims for losses before May 2026 are settled or under investigation
SELECT COUNT(*) FROM claims WHERE status IN ('filed', 'under_review') AND date(loss_date) < '2026-05-01';

-- no payment is dated after 2026-09-30
SELECT COUNT(*) FROM claim_payments WHERE date(paid_on) > '2026-09-30';

-- no claim is reported after 2026-09-30
SELECT COUNT(*) FROM claims WHERE date(reported_on) > '2026-09-30';
