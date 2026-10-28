-- 500K AI Jobs & Salaries Dataset (2024-2026): rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py ai-job-market-salaries <database file>

-- ai_job_postings.job_id is unique
SELECT COUNT(*) - COUNT(DISTINCT job_id) FROM ai_job_postings;

-- companies.company_id is unique
SELECT COUNT(*) - COUNT(DISTINCT company_id) FROM companies;

-- companies.company_name is unique
SELECT COUNT(*) - COUNT(DISTINCT company_name) FROM companies;

-- locations.location_id is unique
SELECT COUNT(*) - COUNT(DISTINCT location_id) FROM locations;

-- every ai_job_postings.company_id exists in companies
SELECT COUNT(*) FROM ai_job_postings c LEFT JOIN companies p ON p.company_id = c.company_id WHERE c.company_id IS NOT NULL AND p.company_id IS NULL;

-- every ai_job_postings.location_id exists in locations
SELECT COUNT(*) FROM ai_job_postings c LEFT JOIN locations p ON p.location_id = c.location_id WHERE c.location_id IS NOT NULL AND p.location_id IS NULL;

-- every posting carries its company's name, industry, size, funding stage, AI maturity and rating
SELECT COUNT(*) FROM ai_job_postings p JOIN companies c USING (company_id) WHERE p.company_name <> c.company_name OR p.industry <> c.industry OR p.company_size <> c.company_size OR p.funding_stage <> c.funding_stage OR p.ai_maturity <> c.ai_maturity OR ABS(p.company_rating - c.company_rating) > 0.001;

-- every posting carries its location's city, country, region, cost-of-living index and currency
SELECT COUNT(*) FROM ai_job_postings p JOIN locations l USING (location_id) WHERE p.city <> l.city OR p.country <> l.country OR p.region <> l.region OR p.cost_of_living_index <> l.cost_of_living_index OR p.salary_currency <> l.currency;

-- salary_local = salary_usd x the location's exchange rate, rounded to hundreds
SELECT COUNT(*) FROM ai_job_postings p JOIN locations l USING (location_id) WHERE ABS(p.salary_local - p.salary_usd * l.usd_to_local) > 50.01;

-- salary_usd is positive and a whole multiple of 100
SELECT COUNT(*) FROM ai_job_postings WHERE salary_usd <= 0 OR salary_usd % 100 <> 0;

-- each job title belongs to exactly one role family
SELECT COUNT(*) FROM (SELECT job_title FROM ai_job_postings GROUP BY job_title HAVING COUNT(DISTINCT role_family) > 1);

-- postings run from 2024-01-01 to 2026-09-30
SELECT COUNT(*) FROM ai_job_postings WHERE posted_date < '2024-01-01' OR posted_date > '2026-09-30';

-- the application deadline is 14-60 days after posting
SELECT COUNT(*) FROM ai_job_postings WHERE julianday(application_deadline) - julianday(posted_date) NOT BETWEEN 14 AND 60;

-- days_to_fill is set exactly for filled postings
SELECT COUNT(*) FROM ai_job_postings WHERE (posting_status = 'Filled') <> (days_to_fill IS NOT NULL);

-- a filled posting is filled by 2026-09-30
SELECT COUNT(*) FROM ai_job_postings WHERE days_to_fill IS NOT NULL AND date(posted_date, '+' || days_to_fill || ' days') > '2026-09-30';

-- postings from the last two weeks are still open or closed, never filled or expired
SELECT COUNT(*) FROM ai_job_postings WHERE posted_date >= '2026-09-16' AND posting_status NOT IN ('Open', 'Closed');

-- only postings from July 2026 on are still open
SELECT COUNT(*) FROM ai_job_postings WHERE posting_status = 'Open' AND posted_date < '2026-07-01';

-- interns are internships with no experience required and no bonus
SELECT COUNT(*) FROM ai_job_postings WHERE (seniority_level = 'Intern') <> (employment_type = 'Internship') OR (seniority_level = 'Intern' AND (years_experience_required <> 0 OR bonus_pct <> 0));

-- years of experience match the seniority level
SELECT COUNT(*) FROM ai_job_postings WHERE (seniority_level = 'Intern' AND years_experience_required NOT BETWEEN 0 AND 0) OR (seniority_level = 'Junior' AND years_experience_required NOT BETWEEN 0 AND 2) OR (seniority_level = 'Mid' AND years_experience_required NOT BETWEEN 2 AND 5) OR (seniority_level = 'Senior' AND years_experience_required NOT BETWEEN 5 AND 9) OR (seniority_level = 'Lead' AND years_experience_required NOT BETWEEN 7 AND 12) OR (seniority_level = 'Principal' AND years_experience_required NOT BETWEEN 10 AND 18);

-- the bonus range matches the seniority level
SELECT COUNT(*) FROM ai_job_postings WHERE (seniority_level = 'Intern' AND bonus_pct NOT BETWEEN 0 AND 0) OR (seniority_level = 'Junior' AND bonus_pct NOT BETWEEN 0 AND 8) OR (seniority_level = 'Mid' AND bonus_pct NOT BETWEEN 5 AND 12) OR (seniority_level = 'Senior' AND bonus_pct NOT BETWEEN 8 AND 18) OR (seniority_level = 'Lead' AND bonus_pct NOT BETWEEN 10 AND 22) OR (seniority_level = 'Principal' AND bonus_pct NOT BETWEEN 12 AND 30);

-- interview rounds: 2-3 for interns and juniors, 3-5 for mid and senior, 4-6 above
SELECT COUNT(*) FROM ai_job_postings WHERE (seniority_level IN ('Intern', 'Junior') AND interview_rounds NOT BETWEEN 2 AND 3) OR (seniority_level IN ('Mid', 'Senior') AND interview_rounds NOT BETWEEN 3 AND 5) OR (seniority_level IN ('Lead', 'Principal') AND interview_rounds NOT BETWEEN 4 AND 6);

-- views are 6-22 times the applicants
SELECT COUNT(*) FROM ai_job_postings WHERE views_count < 6 * applicants_count OR views_count > 22 * applicants_count;

-- paid leave in Europe is 25-32 days
SELECT COUNT(*) FROM ai_job_postings WHERE region = 'Europe' AND paid_leave_days NOT BETWEEN 25 AND 32;

-- startups are seed to Series B or bootstrapped; large and enterprise companies are public or private
SELECT COUNT(*) FROM companies WHERE (company_size = 'Startup' AND funding_stage NOT IN ('Seed', 'Series A', 'Series B', 'Bootstrapped')) OR (company_size IN ('Large', 'Enterprise') AND funding_stage NOT IN ('Public', 'Private'));

-- startups were founded from 2018 on
SELECT COUNT(*) FROM companies WHERE company_size = 'Startup' AND founded_year < 2018;

-- company ratings are between 2.0 and 5.0
SELECT COUNT(*) FROM companies WHERE company_rating < 2.0 OR company_rating > 5.0;
