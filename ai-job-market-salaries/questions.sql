-- 500K AI Jobs & Salaries Dataset (2024-2026): ten practice questions.
-- Written for SQLite (ai_job_market_salaries.sqlite); most run unchanged on PostgreSQL.

-- 1. Average salary by seniority level
SELECT seniority_level, COUNT(*) AS postings, ROUND(AVG(salary_usd)) AS avg_salary_usd,
       MIN(salary_usd) AS min_usd, MAX(salary_usd) AS max_usd
FROM ai_job_postings GROUP BY seniority_level ORDER BY avg_salary_usd;

-- 2. The ten best-paid job titles
SELECT job_title, role_family, COUNT(*) AS postings, ROUND(AVG(salary_usd)) AS avg_salary_usd
FROM ai_job_postings GROUP BY job_title, role_family ORDER BY avg_salary_usd DESC LIMIT 10;

-- 3. Pay by country, in dollars and in the local currency
SELECT country, salary_currency, COUNT(*) AS postings, ROUND(AVG(salary_usd)) AS avg_usd, ROUND(AVG(salary_local)) AS avg_local
FROM ai_job_postings GROUP BY country, salary_currency ORDER BY avg_usd DESC;

-- 4. How much more does LLM experience pay, by role family?
SELECT role_family,
       ROUND(AVG(CASE WHEN llm_experience_required = 1 THEN salary_usd END)) AS with_llm,
       ROUND(AVG(CASE WHEN llm_experience_required = 0 THEN salary_usd END)) AS without_llm,
       ROUND(100.0 * AVG(llm_experience_required), 1) AS llm_share_pct
FROM ai_job_postings GROUP BY role_family ORDER BY llm_share_pct DESC;

-- 5. Remote, hybrid or on-site: share of postings, pay and applicants
SELECT work_mode, COUNT(*) AS postings, ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ai_job_postings), 1) AS share_pct,
       ROUND(AVG(salary_usd)) AS avg_salary_usd, ROUND(AVG(applicants_count)) AS avg_applicants
FROM ai_job_postings GROUP BY work_mode ORDER BY postings DESC;

-- 6. Postings per quarter
SELECT substr(posted_date, 1, 4) || '-Q' || ((CAST(substr(posted_date, 6, 2) AS INTEGER) + 2) / 3) AS quarter, COUNT(*) AS postings
FROM ai_job_postings GROUP BY quarter ORDER BY quarter;

-- 7. The ten companies that post the most jobs
SELECT c.company_name, c.industry, c.company_size, COUNT(*) AS postings, ROUND(AVG(p.salary_usd)) AS avg_salary_usd
FROM ai_job_postings p JOIN companies c USING (company_id)
GROUP BY c.company_id ORDER BY postings DESC LIMIT 10;

-- 8. How long filled jobs took to fill, by level
SELECT seniority_level, COUNT(*) AS filled, ROUND(AVG(days_to_fill), 1) AS avg_days, MAX(days_to_fill) AS longest
FROM ai_job_postings WHERE posting_status = 'Filled' GROUP BY seniority_level ORDER BY avg_days;

-- 9. The most requested framework in each role family (window function)
SELECT role_family, primary_framework, postings FROM (
    SELECT role_family, primary_framework, COUNT(*) AS postings,
           ROW_NUMBER() OVER (PARTITION BY role_family ORDER BY COUNT(*) DESC) AS rnk
    FROM ai_job_postings GROUP BY role_family, primary_framework)
WHERE rnk = 1 ORDER BY postings DESC;

-- 10. Where employers sponsor visas
SELECT country, COUNT(*) AS postings, ROUND(100.0 * AVG(visa_sponsorship), 1) AS sponsor_pct
FROM ai_job_postings GROUP BY country ORDER BY sponsor_pct DESC, postings DESC LIMIT 10;
