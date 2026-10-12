-- Synthetic Hospital Records (No Real Patients): ten practice questions.
-- Written for SQLite (hospital_records.sqlite); most run unchanged on PostgreSQL.

-- 1. Encounters, average stay and average charge by type
SELECT encounter_type, COUNT(*) AS encounters, ROUND(AVG(length_of_stay), 2) AS avg_stay_days, ROUND(AVG(total_charge), 2) AS avg_charge
FROM encounters GROUP BY encounter_type;

-- 2. The ten most common diagnoses
SELECT icd10_code, diagnosis, COUNT(*) AS encounters
FROM encounters GROUP BY icd10_code, diagnosis ORDER BY encounters DESC LIMIT 10;

-- 3. Encounters per patient by age group
SELECT CASE WHEN age < 18 THEN '0-17' WHEN age < 40 THEN '18-39' WHEN age < 65 THEN '40-64' ELSE '65+' END AS age_group,
       COUNT(DISTINCT patient_id) AS patients, COUNT(*) AS encounters,
       ROUND(1.0 * COUNT(*) / COUNT(DISTINCT patient_id), 2) AS encounters_per_patient
FROM (SELECT e.patient_id, (julianday(e.admit_date) - julianday(p.date_of_birth)) / 365.25 AS age
      FROM encounters e JOIN patients p USING (patient_id))
GROUP BY age_group ORDER BY MIN(age);

-- 4. Readmissions: inpatient stays followed by another encounter within 30 days
SELECT COUNT(*) AS inpatient_stays, SUM(readmitted) AS followed_within_30_days,
       ROUND(100.0 * SUM(readmitted) / COUNT(*), 1) AS pct
FROM (SELECT e.encounter_id,
             EXISTS (SELECT 1 FROM encounters n WHERE n.patient_id = e.patient_id AND n.encounter_id <> e.encounter_id
                     AND julianday(n.admit_date) - julianday(e.discharge_date) BETWEEN 0 AND 30) AS readmitted
      FROM encounters e WHERE e.encounter_type = 'inpatient');

-- 5. Monthly admissions by encounter type
SELECT substr(admit_date, 1, 7) AS month,
       SUM(encounter_type = 'outpatient') AS outpatient, SUM(encounter_type = 'emergency') AS emergency,
       SUM(encounter_type = 'inpatient') AS inpatient
FROM encounters GROUP BY month ORDER BY month;

-- 6. Claim outcomes and payment ratio by payer
SELECT payer, COUNT(*) AS claims, ROUND(100.0 * SUM(status = 'denied') / COUNT(*), 1) AS denied_pct,
       ROUND(100.0 * SUM(paid_amount) / SUM(billed_amount), 1) AS paid_pct_of_billed
FROM claims GROUP BY payer ORDER BY paid_pct_of_billed DESC;

-- 7. How long do claim decisions take?
SELECT status, COUNT(*) AS claims, ROUND(AVG(julianday(decided_on) - julianday(submitted_on)), 1) AS avg_days_to_decision
FROM claims WHERE decided_on IS NOT NULL GROUP BY status;

-- 8. Readings with a fever or low oxygen
SELECT SUM(temperature_c >= 38.0) AS fever_readings, SUM(spo2 < 92) AS low_oxygen_readings, COUNT(*) AS readings
FROM vitals;

-- 9. Most prescribed drugs and their usual course
SELECT drug_name, dose_mg, COUNT(*) AS prescriptions, ROUND(AVG(days_supply), 1) AS avg_days_supply
FROM prescriptions GROUP BY drug_name, dose_mg ORDER BY prescriptions DESC LIMIT 10;

-- 10. Busiest providers and the revenue they generate
SELECT pr.provider_id, pr.full_name, pr.specialty, COUNT(*) AS encounters, ROUND(SUM(e.total_charge), 2) AS charges
FROM encounters e JOIN providers pr USING (provider_id)
GROUP BY pr.provider_id ORDER BY encounters DESC LIMIT 10;
