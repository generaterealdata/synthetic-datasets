-- Synthetic Smart Meter Readings (15-Minute Intervals): ten practice questions.
-- Written for SQLite (smart_meter_readings.sqlite); most run unchanged on PostgreSQL.

-- 1. Average load by hour of day for homes and businesses
SELECT CAST(strftime('%H', r.interval_start) AS INTEGER) AS hour,
       ROUND(AVG(CASE WHEN p.premise_type <> 'small_business' THEN r.import_kwh END), 3) AS home_kwh,
       ROUND(AVG(CASE WHEN p.premise_type = 'small_business' THEN r.import_kwh END), 3) AS business_kwh
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
GROUP BY hour ORDER BY hour;

-- 2. Daily energy and cost per premise type
SELECT p.premise_type, ROUND(SUM(r.import_kwh) / COUNT(DISTINCT date(r.interval_start)) / COUNT(DISTINCT r.meter_id), 2) AS kwh_per_meter_per_day,
       ROUND(SUM(r.cost) / COUNT(DISTINCT date(r.interval_start)) / COUNT(DISTINCT r.meter_id), 2) AS cost_per_meter_per_day
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
GROUP BY p.premise_type;

-- 3. What share of energy and of the bill falls in the peak window?
SELECT ROUND(100.0 * SUM(CASE WHEN is_peak = 1 THEN import_kwh END) / SUM(import_kwh), 1) AS peak_share_of_kwh,
       ROUND(100.0 * SUM(CASE WHEN is_peak = 1 THEN cost END) / SUM(cost), 1) AS peak_share_of_cost
FROM readings;

-- 4. The evening effect of an EV: load by hour, homes with and without one
SELECT CAST(strftime('%H', r.interval_start) AS INTEGER) AS hour,
       ROUND(AVG(CASE WHEN p.has_ev = 1 THEN r.import_kwh END), 3) AS with_ev,
       ROUND(AVG(CASE WHEN p.has_ev = 0 THEN r.import_kwh END), 3) AS without_ev
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
WHERE p.premise_type <> 'small_business'
GROUP BY hour HAVING hour >= 16 ORDER BY hour;

-- 5. Solar export by hour of day
SELECT CAST(strftime('%H', r.interval_start) AS INTEGER) AS hour, ROUND(AVG(r.export_kwh), 3) AS avg_export_kwh
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
WHERE p.has_solar = 1 GROUP BY hour ORDER BY hour;

-- 6. Net energy per solar premise (import minus export)
SELECT m.meter_id, ROUND(SUM(r.import_kwh), 1) AS imported, ROUND(SUM(r.export_kwh), 1) AS exported,
       ROUND(SUM(r.import_kwh) - SUM(r.export_kwh), 1) AS net_kwh
FROM readings r JOIN meters m USING (meter_id) JOIN premises p USING (premise_id)
WHERE p.has_solar = 1 GROUP BY m.meter_id ORDER BY net_kwh LIMIT 10;

-- 7. The ten highest daily bills
SELECT meter_id, date(interval_start) AS day, ROUND(SUM(import_kwh), 2) AS kwh, ROUND(SUM(cost), 2) AS cost
FROM readings GROUP BY meter_id, day ORDER BY cost DESC LIMIT 10;

-- 8. Hourly rolling average for one meter (window function)
SELECT interval_start, import_kwh,
       ROUND(AVG(import_kwh) OVER (ORDER BY interval_start ROWS BETWEEN 3 PRECEDING AND CURRENT ROW), 3) AS rolling_1h
FROM readings WHERE meter_id = 1 ORDER BY interval_start LIMIT 24;

-- 9. Check the series is complete: readings and gaps per meter
SELECT COUNT(*) AS meters, MIN(n) AS fewest_readings, MAX(n) AS most_readings, SUM(gaps) AS gaps
FROM (SELECT meter_id, COUNT(*) AS n,
             SUM(gap_min IS NOT NULL AND ABS(gap_min - 15) > 0.01) AS gaps
      FROM (SELECT meter_id, (julianday(interval_start) - julianday(LAG(interval_start) OVER (PARTITION BY meter_id ORDER BY interval_start))) * 1440 AS gap_min
            FROM readings)
      GROUP BY meter_id);

-- 10. Voltage range per tariff
SELECT m.tariff_code, ROUND(MIN(r.voltage_v), 1) AS min_v, ROUND(AVG(r.voltage_v), 2) AS avg_v, ROUND(MAX(r.voltage_v), 1) AS max_v
FROM readings r JOIN meters m USING (meter_id) GROUP BY m.tariff_code;
