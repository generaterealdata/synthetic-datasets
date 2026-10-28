-- 500K AI Jobs & Salaries Dataset (2024-2026)
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE locations (
    location_id          INTEGER PRIMARY KEY,
    city                 VARCHAR(60)  NOT NULL,
    country              VARCHAR(60)  NOT NULL,
    region               VARCHAR(40)  NOT NULL,
    currency             CHAR(3)      NOT NULL,
    usd_to_local         NUMERIC(12,4) NOT NULL,
    cost_of_living_index INTEGER      NOT NULL
);

CREATE TABLE companies (
    company_id     INTEGER PRIMARY KEY,
    company_name   VARCHAR(80)  NOT NULL UNIQUE,
    industry       VARCHAR(40)  NOT NULL,
    company_size   VARCHAR(30)  NOT NULL,
    funding_stage  VARCHAR(20)  NOT NULL,
    founded_year   INTEGER      NOT NULL,
    ai_maturity    VARCHAR(20)  NOT NULL,
    company_rating NUMERIC(2,1) NOT NULL
);

CREATE TABLE ai_job_postings (
    job_id                    VARCHAR(12)  PRIMARY KEY,
    posted_date               DATE         NOT NULL,
    application_deadline      DATE         NOT NULL,
    posting_status            VARCHAR(10)  NOT NULL,
    job_title                 VARCHAR(60)  NOT NULL,
    role_family               VARCHAR(40)  NOT NULL,
    seniority_level           VARCHAR(10)  NOT NULL,
    years_experience_required INTEGER      NOT NULL,
    employment_type           VARCHAR(12)  NOT NULL,
    company_id                INTEGER      NOT NULL REFERENCES companies(company_id),
    company_name              VARCHAR(80)  NOT NULL,
    industry                  VARCHAR(40)  NOT NULL,
    company_size              VARCHAR(30)  NOT NULL,
    funding_stage             VARCHAR(20)  NOT NULL,
    ai_maturity               VARCHAR(20)  NOT NULL,
    company_rating            NUMERIC(2,1) NOT NULL,
    location_id               INTEGER      NOT NULL REFERENCES locations(location_id),
    city                      VARCHAR(60)  NOT NULL,
    country                   VARCHAR(60)  NOT NULL,
    region                    VARCHAR(40)  NOT NULL,
    cost_of_living_index      INTEGER      NOT NULL,
    work_mode                 VARCHAR(10)  NOT NULL,
    education_required        VARCHAR(20)  NOT NULL,
    primary_framework         VARCHAR(30)  NOT NULL,
    required_skills           VARCHAR(120) NOT NULL,
    llm_experience_required   BOOLEAN      NOT NULL,
    python_required           BOOLEAN      NOT NULL,
    cloud_platform            VARCHAR(15)  NOT NULL,
    visa_sponsorship          BOOLEAN      NOT NULL,
    salary_usd                INTEGER      NOT NULL,
    salary_local              BIGINT       NOT NULL,
    salary_currency           CHAR(3)      NOT NULL,
    bonus_pct                 INTEGER      NOT NULL,
    equity_offered            BOOLEAN      NOT NULL,
    paid_leave_days           INTEGER      NOT NULL,
    interview_rounds          INTEGER      NOT NULL,
    team_size                 INTEGER      NOT NULL,
    hiring_urgency            VARCHAR(8)   NOT NULL,
    posting_source            VARCHAR(20)  NOT NULL,
    applicants_count          INTEGER      NOT NULL,
    views_count               INTEGER      NOT NULL,
    days_to_fill              INTEGER
);
