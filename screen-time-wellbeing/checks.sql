-- Screen Time, Sleep and Mental Health: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py screen-time-wellbeing <database file>

-- people.person_id is unique
SELECT COUNT(*) - COUNT(DISTINCT person_id) FROM people;

-- daily_logs.log_id is unique
SELECT COUNT(*) - COUNT(DISTINCT log_id) FROM daily_logs;

-- every daily_logs.person_id exists in people
SELECT COUNT(*) FROM daily_logs c LEFT JOIN people p ON p.person_id = c.person_id WHERE c.person_id IS NOT NULL AND p.person_id IS NULL;

-- every person has exactly 30 days of logs, one per date
SELECT COUNT(*) FROM (SELECT person_id FROM daily_logs GROUP BY person_id HAVING COUNT(*) <> 30 OR COUNT(DISTINCT log_date) <> 30);

-- a person's daily rows carry their own age, gender, occupation, chronotype, children, fitness and anxiety
SELECT COUNT(*) FROM daily_logs l JOIN people p USING (person_id) WHERE l.age <> p.age OR l.gender <> p.gender OR l.occupation <> p.occupation OR l.chronotype <> p.chronotype OR l.has_children <> p.has_children OR l.fitness_level <> p.fitness_level OR l.diagnosed_anxiety <> p.diagnosed_anxiety;

-- day_of_week is the weekday of log_date
SELECT COUNT(*) FROM daily_logs WHERE day_of_week <> CASE CAST(strftime('%w', log_date) AS INTEGER) WHEN 0 THEN 'Sunday' WHEN 1 THEN 'Monday' WHEN 2 THEN 'Tuesday' WHEN 3 THEN 'Wednesday' WHEN 4 THEN 'Thursday' WHEN 5 THEN 'Friday' ELSE 'Saturday' END;

-- is_weekend exactly on Saturdays and Sundays
SELECT COUNT(*) FROM daily_logs WHERE is_weekend <> (day_of_week IN ('Saturday', 'Sunday'));

-- anyone 22 or younger is a student
SELECT COUNT(*) FROM people WHERE age <= 22 AND occupation <> 'Student';

-- social media time fits inside screen time
SELECT COUNT(*) FROM daily_logs WHERE social_media_minutes > screen_time_hours * 60 + 30;

-- bedtime is a clock time 0-24
SELECT COUNT(*) FROM daily_logs WHERE bedtime_hour < 0 OR bedtime_hour >= 24;

-- sleep is 3-11 hours
SELECT COUNT(*) FROM daily_logs WHERE sleep_hours NOT BETWEEN 3 AND 11;

-- scores are 1-10
SELECT COUNT(*) FROM daily_logs WHERE sleep_quality NOT BETWEEN 1 AND 10 OR mood_score NOT BETWEEN 1 AND 10 OR stress_level NOT BETWEEN 1 AND 10 OR productivity_score NOT BETWEEN 1 AND 10;

-- steps are at least 2,500 plus 95 per exercise minute
SELECT COUNT(*) FROM daily_logs WHERE steps < 2500 + exercise_minutes * 95;
