-- Synthetic HR, Workforce and Attrition
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE departments (
    department_id   INTEGER PRIMARY KEY,
    department_name VARCHAR(60) NOT NULL UNIQUE,
    division        VARCHAR(40) NOT NULL,
    location        VARCHAR(60) NOT NULL
);

CREATE TABLE employees (
    employee_id       INTEGER PRIMARY KEY,
    first_name        VARCHAR(60)  NOT NULL,
    last_name         VARCHAR(60)  NOT NULL,
    email             VARCHAR(160) NOT NULL UNIQUE,
    department_id     INTEGER      NOT NULL REFERENCES departments(department_id),
    job_title         VARCHAR(80)  NOT NULL,
    job_level         INTEGER      NOT NULL CHECK (job_level BETWEEN 1 AND 7),
    hire_date         DATE         NOT NULL,
    termination_date  DATE,
    employment_status VARCHAR(12)  NOT NULL CHECK (employment_status IN ('active', 'terminated', 'on_leave')),
    gender            VARCHAR(12)  NOT NULL,
    date_of_birth     DATE         NOT NULL,
    work_mode         VARCHAR(8)   NOT NULL CHECK (work_mode IN ('office', 'hybrid', 'remote'))
);

CREATE TABLE salaries (
    salary_id      INTEGER PRIMARY KEY,
    employee_id    INTEGER       NOT NULL REFERENCES employees(employee_id),
    effective_from DATE          NOT NULL,
    base_salary    NUMERIC(12,2) NOT NULL CHECK (base_salary > 0),
    bonus_pct      NUMERIC(4,1)  NOT NULL,
    currency       CHAR(3)       NOT NULL
);

CREATE TABLE performance_reviews (
    review_id             INTEGER PRIMARY KEY,
    employee_id           INTEGER NOT NULL REFERENCES employees(employee_id),
    review_date           DATE    NOT NULL,
    rating                INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    goals_met_pct         INTEGER NOT NULL CHECK (goals_met_pct BETWEEN 0 AND 100),
    promotion_recommended BOOLEAN NOT NULL
);

CREATE TABLE absences (
    absence_id   INTEGER PRIMARY KEY,
    employee_id  INTEGER     NOT NULL REFERENCES employees(employee_id),
    start_date   DATE        NOT NULL,
    end_date     DATE        NOT NULL,
    absence_type VARCHAR(12) NOT NULL CHECK (absence_type IN ('vacation', 'sick', 'parental', 'unpaid', 'training')),
    days         INTEGER     NOT NULL CHECK (days >= 1)
);

CREATE TABLE attrition_events (
    attrition_id         INTEGER PRIMARY KEY,
    employee_id          INTEGER     NOT NULL REFERENCES employees(employee_id),
    left_on              DATE        NOT NULL,
    reason               VARCHAR(20) NOT NULL CHECK (reason IN ('better_offer', 'relocation', 'career_change', 'performance', 'redundancy', 'retirement', 'personal')),
    voluntary            BOOLEAN     NOT NULL,
    exit_interview_score INTEGER     CHECK (exit_interview_score BETWEEN 1 AND 10)
);
