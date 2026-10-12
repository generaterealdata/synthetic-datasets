-- Synthetic HR, Workforce and Attrition: ten practice questions.
-- Written for SQLite (hr_workforce_attrition.sqlite); most run unchanged on PostgreSQL.

-- 1. Headcount and attrition rate by division
SELECT d.division, COUNT(*) AS employees, SUM(e.employment_status = 'terminated') AS left_company,
       ROUND(100.0 * SUM(e.employment_status = 'terminated') / COUNT(*), 1) AS attrition_pct
FROM employees e JOIN departments d USING (department_id) GROUP BY d.division ORDER BY employees DESC;

-- 2. The job pyramid: people and average latest salary per level
SELECT e.job_level, COUNT(DISTINCT e.employee_id) AS employees, ROUND(AVG(s.base_salary), 0) AS avg_base_salary
FROM employees e JOIN salaries s USING (employee_id)
WHERE s.effective_from = (SELECT MAX(effective_from) FROM salaries x WHERE x.employee_id = e.employee_id)
GROUP BY e.job_level ORDER BY e.job_level;

-- 3. Why do people leave?
SELECT reason, COUNT(*) AS leavers, ROUND(100.0 * AVG(voluntary), 0) AS voluntary_pct, ROUND(AVG(exit_interview_score), 2) AS avg_exit_score
FROM attrition_events GROUP BY reason ORDER BY leavers DESC;

-- 4. Tenure of leavers, in years
SELECT CAST((julianday(termination_date) - julianday(hire_date)) / 365.25 AS INTEGER) AS full_years, COUNT(*) AS leavers
FROM employees WHERE employment_status = 'terminated' GROUP BY full_years ORDER BY full_years;

-- 5. Hires and exits per year
SELECT year, SUM(hired) AS hired, SUM(left_company) AS left_company
FROM (SELECT substr(hire_date, 1, 4) AS year, 1 AS hired, 0 AS left_company FROM employees
      UNION ALL SELECT substr(termination_date, 1, 4), 0, 1 FROM employees WHERE termination_date IS NOT NULL)
GROUP BY year ORDER BY year;

-- 6. Rating distribution and promotion recommendations
SELECT rating, COUNT(*) AS reviews, ROUND(AVG(goals_met_pct), 1) AS avg_goals_met, ROUND(100.0 * AVG(promotion_recommended), 1) AS promo_pct
FROM performance_reviews GROUP BY rating ORDER BY rating;

-- 7. Gender split by job level
SELECT job_level, ROUND(100.0 * SUM(gender = 'Female') / COUNT(*), 1) AS female_pct,
       ROUND(100.0 * SUM(gender = 'Male') / COUNT(*), 1) AS male_pct,
       ROUND(100.0 * SUM(gender = 'Non-binary') / COUNT(*), 1) AS non_binary_pct
FROM employees GROUP BY job_level ORDER BY job_level;

-- 8. Absence days per employee by type and work mode
SELECT e.work_mode, a.absence_type, COUNT(*) AS absences, ROUND(AVG(a.days), 1) AS avg_days
FROM absences a JOIN employees e USING (employee_id) GROUP BY e.work_mode, a.absence_type ORDER BY e.work_mode, absences DESC;

-- 9. Payroll by office
SELECT d.location, COUNT(DISTINCT e.employee_id) AS active_employees, ROUND(SUM(s.base_salary) / 1e6, 2) AS payroll_musd
FROM employees e JOIN departments d USING (department_id) JOIN salaries s USING (employee_id)
WHERE e.employment_status <> 'terminated'
  AND s.effective_from = (SELECT MAX(effective_from) FROM salaries x WHERE x.employee_id = e.employee_id)
GROUP BY d.location ORDER BY payroll_musd DESC;

-- 10. Rank departments by average rating (window function)
SELECT department_name, avg_rating, RANK() OVER (ORDER BY avg_rating DESC) AS rank
FROM (SELECT d.department_name, ROUND(AVG(r.rating), 3) AS avg_rating
      FROM performance_reviews r JOIN employees e USING (employee_id) JOIN departments d USING (department_id)
      GROUP BY d.department_name)
ORDER BY rank LIMIT 10;
