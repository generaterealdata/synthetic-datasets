-- Synthetic Smart Meter Readings (15-Minute Intervals)
-- Schema used to generate this dataset with GenerateRealData (https://generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE premises (
    premise_id   INTEGER PRIMARY KEY,
    address      VARCHAR(120) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    postcode     VARCHAR(12)  NOT NULL,
    premise_type VARCHAR(14)  NOT NULL CHECK (premise_type IN ('house', 'apartment', 'small_business')),
    has_solar    BOOLEAN      NOT NULL,
    has_ev       BOOLEAN      NOT NULL
);

CREATE TABLE meters (
    meter_id     INTEGER PRIMARY KEY,
    premise_id   INTEGER     NOT NULL REFERENCES premises(premise_id),
    meter_serial VARCHAR(16) NOT NULL UNIQUE,
    tariff_code  VARCHAR(10) NOT NULL CHECK (tariff_code IN ('TOU-STD', 'TOU-EV', 'TOU-SOLAR')),
    installed_on DATE        NOT NULL
);

CREATE TABLE readings (
    reading_id     INTEGER PRIMARY KEY,
    meter_id       INTEGER      NOT NULL REFERENCES meters(meter_id),
    interval_start TIMESTAMP    NOT NULL,
    import_kwh     NUMERIC(8,3) NOT NULL CHECK (import_kwh >= 0),
    export_kwh     NUMERIC(8,3) NOT NULL CHECK (export_kwh >= 0),
    voltage_v      NUMERIC(5,1) NOT NULL,
    is_peak        BOOLEAN      NOT NULL,
    rate_per_kwh   NUMERIC(5,2) NOT NULL,
    cost           NUMERIC(8,2) NOT NULL
);
