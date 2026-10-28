-- Synthetic Hospital Records (No Real Patients)
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE patients (
    patient_id     INTEGER PRIMARY KEY,
    mrn            VARCHAR(12) NOT NULL UNIQUE,
    first_name     VARCHAR(60) NOT NULL,
    last_name      VARCHAR(60) NOT NULL,
    sex            CHAR(1)     NOT NULL CHECK (sex IN ('F', 'M')),
    date_of_birth  DATE        NOT NULL,
    blood_type     VARCHAR(3)  NOT NULL CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    city           VARCHAR(80) NOT NULL,
    insurance_type VARCHAR(12) NOT NULL CHECK (insurance_type IN ('private', 'public', 'self_pay'))
);

CREATE TABLE providers (
    provider_id INTEGER PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    specialty   VARCHAR(40)  NOT NULL,
    department  VARCHAR(40)  NOT NULL
);

CREATE TABLE encounters (
    encounter_id   INTEGER PRIMARY KEY,
    patient_id     INTEGER       NOT NULL REFERENCES patients(patient_id),
    provider_id    INTEGER       NOT NULL REFERENCES providers(provider_id),
    encounter_type VARCHAR(12)   NOT NULL CHECK (encounter_type IN ('outpatient', 'emergency', 'inpatient')),
    admit_date     DATE          NOT NULL,
    discharge_date DATE          NOT NULL,
    length_of_stay INTEGER       NOT NULL CHECK (length_of_stay >= 0),
    icd10_code     VARCHAR(8)    NOT NULL,
    diagnosis      VARCHAR(120)  NOT NULL,
    total_charge   NUMERIC(12,2) NOT NULL
);

CREATE TABLE vitals (
    vital_id         INTEGER PRIMARY KEY,
    encounter_id     INTEGER      NOT NULL REFERENCES encounters(encounter_id),
    recorded_on      DATE         NOT NULL,
    heart_rate       INTEGER      NOT NULL,
    systolic_bp      INTEGER      NOT NULL,
    diastolic_bp     INTEGER      NOT NULL,
    temperature_c    NUMERIC(4,1) NOT NULL,
    spo2             INTEGER      NOT NULL,
    respiratory_rate INTEGER      NOT NULL
);

CREATE TABLE prescriptions (
    prescription_id INTEGER PRIMARY KEY,
    encounter_id    INTEGER      NOT NULL REFERENCES encounters(encounter_id),
    drug_name       VARCHAR(60)  NOT NULL,
    dose_mg         NUMERIC(8,2) NOT NULL,
    frequency       VARCHAR(20)  NOT NULL CHECK (frequency IN ('once daily', 'twice daily', 'three times daily', 'as needed')),
    days_supply     INTEGER      NOT NULL,
    prescribed_on   DATE         NOT NULL
);

CREATE TABLE claims (
    claim_id       INTEGER PRIMARY KEY,
    encounter_id   INTEGER       NOT NULL REFERENCES encounters(encounter_id),
    payer          VARCHAR(60)   NOT NULL,
    billed_amount  NUMERIC(12,2) NOT NULL,
    allowed_amount NUMERIC(12,2) NOT NULL,
    paid_amount    NUMERIC(12,2) NOT NULL,
    status         VARCHAR(10)   NOT NULL CHECK (status IN ('paid', 'denied', 'pending', 'appealed')),
    submitted_on   DATE          NOT NULL,
    decided_on     DATE
);
