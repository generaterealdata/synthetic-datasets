-- Student Performance and Lifestyle: ten practice questions.
-- Written for SQLite (student_performance.sqlite); most run unchanged on PostgreSQL.

-- 1. Average exam score and pass rate by grade level
SELECT grade_level, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score, ROUND(100.0 * AVG(passed), 1) AS pass_rate_pct
FROM students GROUP BY grade_level ORDER BY grade_level;

-- 2. Does sleep matter? Exam score by hours of sleep
SELECT CAST(sleep_hours_per_night AS INTEGER) AS sleep_hours, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY sleep_hours ORDER BY sleep_hours;

-- 3. Exam score by weekly study hours, in bands of five
SELECT (CAST(study_hours_per_week AS INTEGER) / 5) * 5 AS study_hours_from, COUNT(*) AS students, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY study_hours_from ORDER BY study_hours_from;

-- 4. Motivation: study hours, attendance and scores
SELECT motivation_level, COUNT(*) AS students, ROUND(AVG(study_hours_per_week), 1) AS study_hours,
       ROUND(AVG(attendance_pct), 1) AS attendance_pct, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY motivation_level ORDER BY avg_score;

-- 5. What a part-time job comes with
SELECT part_time_job, COUNT(*) AS students, ROUND(AVG(attendance_pct), 1) AS attendance_pct, ROUND(AVG(sleep_hours_per_night), 2) AS sleep,
       ROUND(AVG(stress_level), 2) AS stress, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY part_time_job;

-- 6. Parents' education and family income: average exam score (pivot)
SELECT parental_education,
       ROUND(AVG(CASE WHEN family_income = 'Low' THEN exam_score END), 1) AS low_income,
       ROUND(AVG(CASE WHEN family_income = 'Middle' THEN exam_score END), 1) AS middle_income,
       ROUND(AVG(CASE WHEN family_income = 'High' THEN exam_score END), 1) AS high_income
FROM students GROUP BY parental_education ORDER BY middle_income;

-- 7. Share of each letter grade by school type
SELECT school_type, final_grade, COUNT(*) AS students,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY school_type), 1) AS share_pct
FROM students GROUP BY school_type, final_grade ORDER BY school_type, final_grade;

-- 8. More than three hours of social media a day
SELECT social_media_hours_per_day > 3 AS heavy_social_media, COUNT(*) AS students,
       ROUND(AVG(sleep_hours_per_night), 2) AS sleep, ROUND(AVG(exam_score), 1) AS avg_score
FROM students GROUP BY heavy_social_media;

-- 9. How many students improved on last year, by tutoring sessions
SELECT tutoring_sessions_per_month, COUNT(*) AS students,
       ROUND(100.0 * AVG(exam_score > previous_score), 1) AS improved_pct, ROUND(AVG(exam_score - previous_score), 1) AS avg_change
FROM students GROUP BY tutoring_sessions_per_month ORDER BY tutoring_sessions_per_month;

-- 10. The top three students in each grade (window function)
SELECT grade_level, student_id, exam_score, study_hours_per_week, sleep_hours_per_night FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY grade_level ORDER BY exam_score DESC, previous_score DESC, student_id) AS rnk
    FROM students)
WHERE rnk <= 3 ORDER BY grade_level, rnk;
