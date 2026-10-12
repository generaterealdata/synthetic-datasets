-- Synthetic Hospital Records (No Real Patients): rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py hospital-records <database file>

-- patients.patient_id is unique
SELECT COUNT(*) - COUNT(DISTINCT patient_id) FROM patients;

-- patients.mrn is unique
SELECT COUNT(*) - COUNT(DISTINCT mrn) FROM patients;

-- providers.provider_id is unique
SELECT COUNT(*) - COUNT(DISTINCT provider_id) FROM providers;

-- encounters.encounter_id is unique
SELECT COUNT(*) - COUNT(DISTINCT encounter_id) FROM encounters;

-- claims.encounter_id is unique
SELECT COUNT(*) - COUNT(DISTINCT encounter_id) FROM claims;

-- every encounters.patient_id exists in patients
SELECT COUNT(*) FROM encounters c LEFT JOIN patients p ON p.patient_id = c.patient_id WHERE c.patient_id IS NOT NULL AND p.patient_id IS NULL;

-- every encounters.provider_id exists in providers
SELECT COUNT(*) FROM encounters c LEFT JOIN providers p ON p.provider_id = c.provider_id WHERE c.provider_id IS NOT NULL AND p.provider_id IS NULL;

-- every vitals.encounter_id exists in encounters
SELECT COUNT(*) FROM vitals c LEFT JOIN encounters p ON p.encounter_id = c.encounter_id WHERE c.encounter_id IS NOT NULL AND p.encounter_id IS NULL;

-- every prescriptions.encounter_id exists in encounters
SELECT COUNT(*) FROM prescriptions c LEFT JOIN encounters p ON p.encounter_id = c.encounter_id WHERE c.encounter_id IS NOT NULL AND p.encounter_id IS NULL;

-- every claims.encounter_id exists in encounters
SELECT COUNT(*) FROM claims c LEFT JOIN encounters p ON p.encounter_id = c.encounter_id WHERE c.encounter_id IS NOT NULL AND p.encounter_id IS NULL;

-- every patient has an encounter
SELECT COUNT(*) FROM patients p WHERE NOT EXISTS (SELECT 1 FROM encounters e WHERE e.patient_id = p.patient_id);

-- every encounter has vitals
SELECT COUNT(*) FROM encounters e WHERE NOT EXISTS (SELECT 1 FROM vitals v WHERE v.encounter_id = e.encounter_id);

-- discharge date = admit date + length of stay
SELECT COUNT(*) FROM encounters WHERE julianday(discharge_date) - julianday(admit_date) <> length_of_stay;

-- length of stay fits the encounter type
SELECT COUNT(*) FROM encounters WHERE (encounter_type = 'outpatient' AND length_of_stay <> 0) OR (encounter_type = 'emergency' AND length_of_stay > 1) OR (encounter_type = 'inpatient' AND length_of_stay NOT BETWEEN 1 AND 12);

-- charges fit the encounter type
SELECT COUNT(*) FROM encounters WHERE (encounter_type = 'outpatient' AND total_charge NOT BETWEEN 80 AND 900) OR (encounter_type = 'emergency' AND total_charge NOT BETWEEN 400 AND 6000) OR (encounter_type = 'inpatient' AND total_charge NOT BETWEEN 4000 AND 60000);

-- an ICD-10 code always has the same diagnosis text
SELECT COUNT(*) FROM (SELECT icd10_code FROM encounters GROUP BY icd10_code HAVING COUNT(DISTINCT diagnosis) > 1);

-- there are 40 different diagnoses
SELECT CASE WHEN COUNT(DISTINCT icd10_code) = 40 THEN 0 ELSE 1 END FROM encounters;

-- a specialty always sits in the same department
SELECT COUNT(*) FROM (SELECT specialty FROM providers GROUP BY specialty HAVING COUNT(DISTINCT department) > 1);

-- patients were born before their first admission
SELECT COUNT(*) FROM encounters e JOIN patients p USING (patient_id) WHERE date(e.admit_date) < date(p.date_of_birth);

-- vitals are recorded between admission and discharge
SELECT COUNT(*) FROM vitals v JOIN encounters e USING (encounter_id) WHERE date(v.recorded_on) < date(e.admit_date) OR date(v.recorded_on) > date(e.discharge_date);

-- diastolic is lower than systolic
SELECT COUNT(*) FROM vitals WHERE diastolic_bp >= systolic_bp;

-- vitals are within human ranges
SELECT COUNT(*) FROM vitals WHERE heart_rate NOT BETWEEN 50 AND 130 OR systolic_bp NOT BETWEEN 90 AND 190 OR diastolic_bp NOT BETWEEN 55 AND 115 OR temperature_c NOT BETWEEN 35.5 AND 40.5 OR spo2 NOT BETWEEN 86 AND 100 OR respiratory_rate NOT BETWEEN 10 AND 30;

-- a drug always has the same dose
SELECT COUNT(*) FROM (SELECT drug_name FROM prescriptions GROUP BY drug_name HAVING COUNT(DISTINCT dose_mg) > 1);

-- prescribed during the encounter
SELECT COUNT(*) FROM prescriptions p JOIN encounters e USING (encounter_id) WHERE date(p.prescribed_on) < date(e.admit_date) OR date(p.prescribed_on) > date(e.discharge_date);

-- billed amount equals the encounter's total charge
SELECT COUNT(*) FROM claims c JOIN encounters e USING (encounter_id) WHERE ABS(c.billed_amount - e.total_charge) > 0.011;

-- allowed <= billed and paid <= allowed
SELECT COUNT(*) FROM claims WHERE allowed_amount > billed_amount + 0.011 OR paid_amount > allowed_amount + 0.011;

-- only paid claims carry a payment
SELECT COUNT(*) FROM claims WHERE (status = 'paid') <> (paid_amount > 0);

-- claim submitted 1-20 days after discharge
SELECT COUNT(*) FROM claims c JOIN encounters e USING (encounter_id) WHERE julianday(c.submitted_on) - julianday(e.discharge_date) NOT BETWEEN 1 AND 20;

-- decision date is empty exactly while pending, otherwise 5-45 days after submission
SELECT COUNT(*) FROM claims WHERE (status = 'pending') <> (decided_on IS NULL) OR (decided_on IS NOT NULL AND julianday(decided_on) - julianday(submitted_on) NOT BETWEEN 5 AND 45);

-- no admission or discharge is dated after 2026-09-30
SELECT COUNT(*) FROM encounters WHERE date(admit_date) > '2026-09-30' OR date(discharge_date) > '2026-09-30';

-- no claim is submitted or decided after 2026-09-30
SELECT COUNT(*) FROM claims WHERE date(submitted_on) > '2026-09-30' OR date(decided_on) > '2026-09-30';

-- claims are pending exactly when the discharge was on or after 2026-07-25
SELECT COUNT(*) FROM claims c JOIN encounters e USING (encounter_id) WHERE (c.status = 'pending') <> (date(e.discharge_date) >= '2026-07-25');
