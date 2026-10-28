-- Synthetic Auto Insurance Policies and Claims
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE policyholders (
    policyholder_id INTEGER PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    date_of_birth   DATE         NOT NULL,
    state           CHAR(2)      NOT NULL,
    city            VARCHAR(80)  NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,
    licensed_since  DATE         NOT NULL,
    credit_band     VARCHAR(10)  NOT NULL CHECK (credit_band IN ('poor', 'fair', 'good', 'excellent'))
);

CREATE TABLE vehicles (
    vehicle_id      INTEGER PRIMARY KEY,
    vin             CHAR(17)      NOT NULL UNIQUE,
    make            VARCHAR(30)   NOT NULL,
    model           VARCHAR(40)   NOT NULL,
    model_year      INTEGER       NOT NULL,
    body_type       VARCHAR(12)   NOT NULL CHECK (body_type IN ('sedan', 'suv', 'pickup', 'hatchback', 'coupe', 'van')),
    market_value    NUMERIC(10,2) NOT NULL
);

CREATE TABLE policies (
    policy_id       INTEGER PRIMARY KEY,
    policy_number   VARCHAR(16)   NOT NULL UNIQUE,
    policyholder_id INTEGER       NOT NULL REFERENCES policyholders(policyholder_id),
    vehicle_id      INTEGER       NOT NULL REFERENCES vehicles(vehicle_id),
    coverage        VARCHAR(14)   NOT NULL CHECK (coverage IN ('liability', 'collision', 'comprehensive')),
    deductible      INTEGER       NOT NULL CHECK (deductible IN (250, 500, 1000, 2000)),
    annual_premium  NUMERIC(10,2) NOT NULL,
    start_date      DATE          NOT NULL,
    end_date        DATE          NOT NULL,
    status          VARCHAR(10)   NOT NULL CHECK (status IN ('active', 'expired', 'cancelled'))
);

CREATE TABLE claims (
    claim_id       INTEGER PRIMARY KEY,
    claim_number   VARCHAR(14)   NOT NULL UNIQUE,
    policy_id      INTEGER       NOT NULL REFERENCES policies(policy_id),
    loss_date      DATE          NOT NULL,
    reported_on    DATE          NOT NULL,
    loss_state     CHAR(2)       NOT NULL,
    peril          VARCHAR(16)   NOT NULL CHECK (peril IN ('collision', 'hail', 'flood', 'theft', 'vandalism', 'glass', 'animal', 'fire')),
    status         VARCHAR(14)   NOT NULL CHECK (status IN ('filed', 'under_review', 'investigation', 'paid', 'denied')),
    claim_amount   NUMERIC(12,2) NOT NULL,
    reserve_amount NUMERIC(12,2) NOT NULL,
    paid_total     NUMERIC(12,2) NOT NULL
);

CREATE TABLE claim_payments (
    payment_id INTEGER PRIMARY KEY,
    claim_id   INTEGER       NOT NULL REFERENCES claims(claim_id),
    paid_on    DATE          NOT NULL,
    amount     NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    payee      VARCHAR(16)   NOT NULL CHECK (payee IN ('policyholder', 'repair_shop', 'third_party', 'medical_provider')),
    method     VARCHAR(14)   NOT NULL CHECK (method IN ('bank_transfer', 'check', 'card'))
);
