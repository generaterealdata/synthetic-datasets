-- Screen Time, Sleep and Mental Health: ten practice questions.
-- Written for SQLite (screen_time_wellbeing.sqlite); most run unchanged on PostgreSQL.

-- 1. Weekdays against weekends: work, screens, sleep and stress
SELECT CASE WHEN is_weekend = 1 THEN 'weekend' ELSE 'weekday' END AS day_type, ROUND(AVG(work_hours), 2) AS work_hours,
       ROUND(AVG(screen_time_hours), 2) AS screen_hours, ROUND(AVG(sleep_hours), 2) AS sleep_hours, ROUND(AVG(stress_level), 2) AS stress
FROM daily_logs GROUP BY day_type;

-- 2. Stress by hours of sleep
SELECT CAST(sleep_hours AS INTEGER) AS sleep_hours, COUNT(*) AS days, ROUND(AVG(stress_level), 2) AS avg_stress, ROUND(AVG(mood_score), 2) AS avg_mood
FROM daily_logs GROUP BY 1 ORDER BY 1;

-- 3. Screens after 10 pm and sleep, in half-hour bands
SELECT (screen_after_10pm_minutes / 30) * 30 AS late_screen_from_min, COUNT(*) AS days, ROUND(AVG(sleep_hours), 2) AS sleep_hours,
       ROUND(AVG(sleep_quality), 2) AS sleep_quality
FROM daily_logs GROUP BY 1 ORDER BY 1;

-- 4. Morning and evening types: late screens and sleep
SELECT chronotype, ROUND(AVG(screen_after_10pm_minutes), 1) AS late_screen_min, ROUND(AVG(sleep_hours), 2) AS sleep_hours,
       ROUND(100.0 * AVG(bedtime_hour < 12), 1) AS after_midnight_pct
FROM daily_logs GROUP BY chronotype ORDER BY sleep_hours;

-- 5. Stress and work hours by occupation
SELECT occupation, COUNT(DISTINCT person_id) AS people, ROUND(AVG(work_hours), 2) AS work_hours, ROUND(AVG(stress_level), 2) AS stress
FROM daily_logs GROUP BY occupation ORDER BY stress DESC;

-- 6. Does exercise lift the mood?
SELECT (exercise_minutes / 20) * 20 AS exercise_from_min, COUNT(*) AS days, ROUND(AVG(mood_score), 2) AS mood, ROUND(AVG(stress_level), 2) AS stress
FROM daily_logs GROUP BY 1 ORDER BY 1;

-- 7. Caffeine and sleep
SELECT (caffeine_mg / 100) * 100 AS caffeine_from_mg, COUNT(*) AS days, ROUND(AVG(sleep_hours), 2) AS sleep_hours, ROUND(AVG(sleep_quality), 2) AS sleep_quality
FROM daily_logs GROUP BY 1 ORDER BY 1;

-- 8. Screen time by country and age group (join)
SELECT p.country, CASE WHEN p.age < 25 THEN 'under 25' WHEN p.age < 40 THEN '25-39' ELSE '40+' END AS age_group,
       ROUND(AVG(d.screen_time_hours), 2) AS screen_hours, ROUND(AVG(d.social_media_minutes)) AS social_media_min
FROM daily_logs d JOIN people p USING (person_id) GROUP BY 1, 2 ORDER BY 1, 2;

-- 9. Each person's most stressful day compared with their average (window function)
SELECT person_id, log_date, stress_level, ROUND(avg_stress, 2) AS person_avg, sleep_hours, work_hours FROM (
    SELECT *, AVG(stress_level) OVER (PARTITION BY person_id) AS avg_stress,
           ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY stress_level DESC, sleep_hours) AS rnk
    FROM daily_logs WHERE person_id <= 5)
WHERE rnk = 1 ORDER BY person_id;

-- 10. A 7-day moving average of stress for one person (window function)
SELECT log_date, day_of_week, stress_level,
       ROUND(AVG(stress_level) OVER (ORDER BY log_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS stress_7_day_avg
FROM daily_logs WHERE person_id = 1 ORDER BY log_date;
