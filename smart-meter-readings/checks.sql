-- Synthetic Smart Meter Readings (15-Minute Intervals): rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py smart-meter-readings <database file>

-- premises.premise_id is unique
SELECT COUNT(*) - COUNT(DISTINCT premise_id) FROM premises;

-- meters.meter_id is unique
SELECT COUNT(*) - COUNT(DISTINCT meter_id) FROM meters;

-- meters.meter_serial is unique
SELECT COUNT(*) - COUNT(DISTINCT meter_serial) FROM meters;

-- meters.premise_id is unique
SELECT COUNT(*) - COUNT(DISTINCT premise_id) FROM meters;

-- readings.reading_id is unique
SELECT COUNT(*) - COUNT(DISTINCT reading_id) FROM readings;

-- every meters.premise_id exists in premises
SELECT COUNT(*) FROM meters c LEFT JOIN premises p ON p.premise_id = c.premise_id WHERE c.premise_id IS NOT NULL AND p.premise_id IS NULL;

-- every readings.meter_id exists in meters
SELECT COUNT(*) FROM readings c LEFT JOIN meters p ON p.meter_id = c.meter_id WHERE c.meter_id IS NOT NULL AND p.meter_id IS NULL;

-- every premise has a meter
SELECT COUNT(*) FROM premises p WHERE NOT EXISTS (SELECT 1 FROM meters m WHERE m.premise_id = p.premise_id);

-- tariff follows solar and EV
SELECT COUNT(*) FROM meters m JOIN premises p USING (premise_id) WHERE m.tariff_code <> CASE WHEN p.has_solar = 1 THEN 'TOU-SOLAR' WHEN p.has_ev = 1 THEN 'TOU-EV' ELSE 'TOU-STD' END;

-- every meter has the same number of readings
SELECT CASE WHEN MIN(n) = MAX(n) THEN 0 ELSE 1 END FROM (SELECT COUNT(*) n FROM readings GROUP BY meter_id);

-- no meter has two readings for the same interval
SELECT COUNT(*) FROM (SELECT meter_id, interval_start FROM readings GROUP BY 1, 2 HAVING COUNT(*) > 1);

-- readings are exactly 15 minutes apart with no gaps
SELECT COUNT(*) FROM (SELECT (julianday(interval_start) - julianday(LAG(interval_start) OVER (PARTITION BY meter_id ORDER BY interval_start))) * 1440 AS gap FROM readings) WHERE gap IS NOT NULL AND ABS(gap - 15) > 0.01;

-- rate is 0.38 at peak and 0.24 otherwise
SELECT COUNT(*) FROM readings WHERE rate_per_kwh <> CASE WHEN is_peak = 1 THEN 0.38 ELSE 0.24 END;

-- cost = import x rate
SELECT COUNT(*) FROM readings WHERE ABS(cost - import_kwh * rate_per_kwh) > 0.0051;

-- import and export are within range
SELECT COUNT(*) FROM readings WHERE import_kwh NOT BETWEEN 0 AND 3.6 OR export_kwh NOT BETWEEN 0 AND 1.25;

-- peak is exactly 17:00 to 21:00
SELECT COUNT(*) FROM readings WHERE (is_peak = 1) <> (CAST(strftime('%H', interval_start) AS INTEGER) BETWEEN 17 AND 20);

-- homes use at least three times more in the evening peak than overnight
SELECT CASE WHEN (SELECT AVG(r.import_kwh) FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id) WHERE p.premise_type <> 'small_business' AND CAST(strftime('%H', r.interval_start) AS INTEGER) BETWEEN 17 AND 20) > 3 * (SELECT AVG(r.import_kwh) FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id) WHERE p.premise_type <> 'small_business' AND p.has_ev = 0 AND CAST(strftime('%H', r.interval_start) AS INTEGER) < 6) THEN 0 ELSE 1 END;

-- only solar premises export, and only between 07:00 and 19:00
SELECT COUNT(*) FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id) WHERE r.export_kwh > 0 AND (p.has_solar = 0 OR CAST(strftime('%H', r.interval_start) AS INTEGER) NOT BETWEEN 7 AND 18);

-- businesses use more in working hours than at night
SELECT CASE WHEN COALESCE((SELECT AVG(r.import_kwh) FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id) WHERE p.premise_type = 'small_business' AND CAST(strftime('%H', r.interval_start) AS INTEGER) BETWEEN 8 AND 17), 1) > 3 * COALESCE((SELECT AVG(r.import_kwh) FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id) WHERE p.premise_type = 'small_business' AND CAST(strftime('%H', r.interval_start) AS INTEGER) < 6), 0) THEN 0 ELSE 1 END;

-- voltage stays between 228 and 252
SELECT COUNT(*) FROM readings WHERE voltage_v NOT BETWEEN 228 AND 252;
