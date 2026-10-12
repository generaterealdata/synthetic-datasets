-- Synthetic SaaS Subscriptions and Churn
-- Schema used to generate this dataset with GenerateRealData (https://generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE plans (
    plan_id        INTEGER PRIMARY KEY,
    plan_name      VARCHAR(30)   NOT NULL UNIQUE,
    tier           VARCHAR(12)   NOT NULL CHECK (tier IN ('starter', 'team', 'business', 'enterprise')),
    monthly_price  NUMERIC(8,2)  NOT NULL,
    seats_included INTEGER       NOT NULL
);

CREATE TABLE accounts (
    account_id          INTEGER PRIMARY KEY,
    company_name        VARCHAR(120) NOT NULL,
    industry            VARCHAR(40)  NOT NULL,
    country             VARCHAR(60)  NOT NULL,
    employee_band       VARCHAR(10)  NOT NULL CHECK (employee_band IN ('1-10', '11-50', '51-200', '201-1000', '1000+')),
    signup_date         DATE         NOT NULL,
    acquisition_channel VARCHAR(16)  NOT NULL CHECK (acquisition_channel IN ('organic', 'paid_search', 'referral', 'outbound', 'partner', 'event'))
);

CREATE TABLE users (
    user_id       INTEGER PRIMARY KEY,
    account_id    INTEGER      NOT NULL REFERENCES accounts(account_id),
    email         VARCHAR(160) NOT NULL UNIQUE,
    role          VARCHAR(8)   NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    created_at    TIMESTAMP    NOT NULL,
    last_login_at TIMESTAMP,
    is_active     BOOLEAN      NOT NULL
);

CREATE TABLE subscriptions (
    subscription_id INTEGER PRIMARY KEY,
    account_id      INTEGER       NOT NULL REFERENCES accounts(account_id),
    plan_id         INTEGER       NOT NULL REFERENCES plans(plan_id),
    seats           INTEGER       NOT NULL CHECK (seats > 0),
    billing_cycle   VARCHAR(8)    NOT NULL CHECK (billing_cycle IN ('monthly', 'annual')),
    started_on      DATE          NOT NULL,
    ended_on        DATE,
    status          VARCHAR(10)   NOT NULL CHECK (status IN ('active', 'cancelled', 'past_due')),
    mrr             NUMERIC(12,2) NOT NULL
);

CREATE TABLE invoices (
    invoice_id      INTEGER PRIMARY KEY,
    subscription_id INTEGER       NOT NULL REFERENCES subscriptions(subscription_id),
    period_start    DATE          NOT NULL,
    period_end      DATE          NOT NULL,
    amount_due      NUMERIC(12,2) NOT NULL,
    amount_paid     NUMERIC(12,2) NOT NULL,
    status          VARCHAR(10)   NOT NULL CHECK (status IN ('paid', 'open', 'past_due', 'void')),
    issued_on       DATE          NOT NULL,
    paid_on         DATE
);

CREATE TABLE churn_events (
    churn_id        INTEGER PRIMARY KEY,
    subscription_id INTEGER     NOT NULL REFERENCES subscriptions(subscription_id),
    churned_on      DATE        NOT NULL,
    reason          VARCHAR(20) NOT NULL CHECK (reason IN ('price', 'missing_feature', 'switched_tool', 'low_usage', 'company_closed', 'support')),
    feedback_score  INTEGER     CHECK (feedback_score BETWEEN 1 AND 10)
);
