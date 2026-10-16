-- Synthetic HR, Workforce and Attrition: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py hr-workforce-attrition <database file>

-- departments.department_id is unique
SELECT COUNT(*) - COUNT(DISTINCT department_id) FROM departments;

-- employees.employee_id is unique
SELECT COUNT(*) - COUNT(DISTINCT employee_id) FROM employees;

-- employees.email is unique
SELECT COUNT(*) - COUNT(DISTINCT email) FROM employees;

-- every employees.department_id exists in departments
SELECT COUNT(*) FROM employees c LEFT JOIN departments p ON p.department_id = c.department_id WHERE c.department_id IS NOT NULL AND p.department_id IS NULL;

-- every salaries.employee_id exists in employees
SELECT COUNT(*) FROM salaries c LEFT JOIN employees p ON p.employee_id = c.employee_id WHERE c.employee_id IS NOT NULL AND p.employee_id IS NULL;

-- every performance_reviews.employee_id exists in employees
SELECT COUNT(*) FROM performance_reviews c LEFT JOIN employees p ON p.employee_id = c.employee_id WHERE c.employee_id IS NOT NULL AND p.employee_id IS NULL;

-- every absences.employee_id exists in employees
SELECT COUNT(*) FROM absences c LEFT JOIN employees p ON p.employee_id = c.employee_id WHERE c.employee_id IS NOT NULL AND p.employee_id IS NULL;

-- every attrition_events.employee_id exists in employees
SELECT COUNT(*) FROM attrition_events c LEFT JOIN employees p ON p.employee_id = c.employee_id WHERE c.employee_id IS NOT NULL AND p.employee_id IS NULL;

-- there are exactly forty departments
SELECT CASE WHEN COUNT(*) = 40 THEN 0 ELSE 1 END FROM departments;

-- termination date is set exactly for terminated employees
SELECT COUNT(*) FROM employees WHERE (employment_status = 'terminated') <> (termination_date IS NOT NULL);

-- termination is after hire and by 2026-09-30
SELECT COUNT(*) FROM employees WHERE termination_date IS NOT NULL AND (date(termination_date) <= date(hire_date) OR date(termination_date) > '2026-09-30');

-- hired at age 21-64
SELECT COUNT(*) FROM employees WHERE (julianday(hire_date) - julianday(date_of_birth)) / 365.25 NOT BETWEEN 20.9 AND 65.1;

-- every employee has a salary
SELECT COUNT(*) FROM employees e WHERE NOT EXISTS (SELECT 1 FROM salaries s WHERE s.employee_id = e.employee_id);

-- salary starts on or after the hire date
SELECT COUNT(*) FROM salaries s JOIN employees e USING (employee_id) WHERE date(s.effective_from) < date(e.hire_date);

-- base salary fits the job level
SELECT COUNT(*) FROM salaries s JOIN employees e USING (employee_id) WHERE s.base_salary NOT BETWEEN CASE e.job_level WHEN 1 THEN 38000 WHEN 2 THEN 52000 WHEN 3 THEN 70000 WHEN 4 THEN 95000 WHEN 5 THEN 130000 WHEN 6 THEN 175000 ELSE 240000 END AND CASE e.job_level WHEN 1 THEN 58000 WHEN 2 THEN 78000 WHEN 3 THEN 105000 WHEN 4 THEN 140000 WHEN 5 THEN 190000 WHEN 6 THEN 260000 ELSE 420000 END;

-- a review is never dated before the hire date
SELECT COUNT(*) FROM performance_reviews r JOIN employees e USING (employee_id) WHERE date(r.review_date) < date(e.hire_date);

-- job title starts with the level's title and names the department
SELECT COUNT(*) FROM employees e JOIN departments d USING (department_id) WHERE e.job_title <> CASE e.job_level WHEN 1 THEN 'Associate' WHEN 2 THEN 'Specialist' WHEN 3 THEN 'Senior Specialist' WHEN 4 THEN 'Lead' WHEN 5 THEN 'Manager' WHEN 6 THEN 'Director' ELSE 'Vice President' END || ', ' || d.department_name;

-- goals met follows the rating
SELECT COUNT(*) FROM performance_reviews WHERE goals_met_pct NOT BETWEEN CASE rating WHEN 1 THEN 20 WHEN 2 THEN 45 WHEN 3 THEN 65 WHEN 4 THEN 82 ELSE 93 END AND CASE rating WHEN 1 THEN 55 WHEN 2 THEN 70 WHEN 3 THEN 88 WHEN 4 THEN 97 ELSE 100 END;

-- promotion is recommended only for ratings 4 and 5
SELECT COUNT(*) FROM performance_reviews WHERE promotion_recommended = 1 AND rating < 4;

-- absence end = start + days - 1
SELECT COUNT(*) FROM absences WHERE ABS(julianday(end_date) - julianday(start_date) - (days - 1)) > 0.01;

-- absence starts on or after the hire date
SELECT COUNT(*) FROM absences a JOIN employees e USING (employee_id) WHERE date(a.start_date) < date(e.hire_date);

-- every terminated employee has exactly one attrition event
SELECT COUNT(*) FROM employees e WHERE e.employment_status = 'terminated' AND (SELECT COUNT(*) FROM attrition_events a WHERE a.employee_id = e.employee_id) <> 1;

-- attrition events exist only for terminated employees
SELECT COUNT(*) FROM attrition_events a JOIN employees e USING (employee_id) WHERE e.employment_status <> 'terminated';

-- left_on equals the termination date
SELECT COUNT(*) FROM attrition_events a JOIN employees e USING (employee_id) WHERE date(a.left_on) <> date(e.termination_date);

-- performance and redundancy exits are involuntary, others voluntary
SELECT COUNT(*) FROM attrition_events WHERE (reason IN ('performance', 'redundancy')) = (voluntary = 1);

-- no salary record starts after 2026-09-30
SELECT COUNT(*) FROM salaries WHERE date(effective_from) > '2026-09-30';

-- no review is dated after 2026-09-30
SELECT COUNT(*) FROM performance_reviews WHERE date(review_date) > '2026-09-30';

-- no absence starts after 2026-09-30
SELECT COUNT(*) FROM absences WHERE date(start_date) > '2026-09-30';

-- salaries, reviews and absences never start after the employee's last day
SELECT (SELECT COUNT(*) FROM salaries s JOIN employees e USING (employee_id) WHERE date(s.effective_from) > date(e.termination_date)) + (SELECT COUNT(*) FROM performance_reviews r JOIN employees e USING (employee_id) WHERE date(r.review_date) > date(e.termination_date)) + (SELECT COUNT(*) FROM absences a JOIN employees e USING (employee_id) WHERE date(a.start_date) > date(e.termination_date));

-- nobody is older than 67 on 2026-09-30
SELECT COUNT(*) FROM employees WHERE date(date_of_birth) < '1959-10-01';

-- no single day has more than 1% of all leavers
SELECT CASE WHEN MAX(n) > 0.01 * (SELECT COUNT(*) FROM attrition_events) THEN 1 ELSE 0 END FROM (SELECT left_on, COUNT(*) n FROM attrition_events GROUP BY left_on);
