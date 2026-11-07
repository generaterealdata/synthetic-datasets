-- Student Performance and Lifestyle: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py student-performance <database file>

-- students.student_id is unique
SELECT COUNT(*) - COUNT(DISTINCT student_id) FROM students;

-- age is grade + 5 or grade + 6
SELECT COUNT(*) FROM students WHERE age - grade_level NOT IN (5, 6);

-- distance to school fits the location
SELECT COUNT(*) FROM students WHERE (school_location = 'Urban' AND distance_to_school_km > 5) OR (school_location = 'Suburban' AND distance_to_school_km NOT BETWEEN 1 AND 12) OR (school_location = 'Rural' AND distance_to_school_km < 3);

-- attendance is 50-100%
SELECT COUNT(*) FROM students WHERE attendance_pct NOT BETWEEN 50 AND 100;

-- social media time is part of screen time
SELECT COUNT(*) FROM students WHERE social_media_hours_per_day > screen_time_hours_per_day + 0.05;

-- sleep is 4-10 hours
SELECT COUNT(*) FROM students WHERE sleep_hours_per_night NOT BETWEEN 4 AND 10;

-- stress is 1-10
SELECT COUNT(*) FROM students WHERE stress_level NOT BETWEEN 1 AND 10;

-- scores are 0-100
SELECT COUNT(*) FROM students WHERE previous_score NOT BETWEEN 0 AND 100 OR exam_score NOT BETWEEN 0 AND 100;

-- the final grade follows the exam score (A 90+, B 80+, C 70+, D 60+, F below)
SELECT COUNT(*) FROM students WHERE final_grade <> CASE WHEN exam_score >= 90 THEN 'A' WHEN exam_score >= 80 THEN 'B' WHEN exam_score >= 70 THEN 'C' WHEN exam_score >= 60 THEN 'D' ELSE 'F' END;

-- passed exactly when the exam score is 60 or more
SELECT COUNT(*) FROM students WHERE passed <> (exam_score >= 60);

-- study time is 0-40 hours a week
SELECT COUNT(*) FROM students WHERE study_hours_per_week NOT BETWEEN 0 AND 40;
