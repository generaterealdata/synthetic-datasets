-- Synthetic Bank Card Transactions with Fraud Labels
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    full_name     VARCHAR(120) NOT NULL,
    date_of_birth DATE         NOT NULL,
    country       VARCHAR(60)  NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    risk_segment  VARCHAR(8)   NOT NULL CHECK (risk_segment IN ('low', 'medium', 'high')),
    joined_on     DATE         NOT NULL
);

CREATE TABLE accounts (
    account_id   INTEGER PRIMARY KEY,
    customer_id  INTEGER     NOT NULL REFERENCES customers(customer_id),
    iban         VARCHAR(34) NOT NULL UNIQUE,
    account_type VARCHAR(10) NOT NULL CHECK (account_type IN ('current', 'savings', 'premium')),
    currency     CHAR(3)     NOT NULL,
    opened_on    DATE        NOT NULL,
    status       VARCHAR(8)  NOT NULL CHECK (status IN ('active', 'frozen', 'closed'))
);

CREATE TABLE cards (
    card_id      INTEGER PRIMARY KEY,
    account_id   INTEGER     NOT NULL REFERENCES accounts(account_id),
    card_network VARCHAR(12) NOT NULL CHECK (card_network IN ('visa', 'mastercard', 'amex')),
    card_last4   CHAR(4)     NOT NULL,
    expiry_month INTEGER     NOT NULL CHECK (expiry_month BETWEEN 1 AND 12),
    expiry_year  INTEGER     NOT NULL,
    is_virtual   BOOLEAN     NOT NULL,
    issued_on    DATE        NOT NULL,
    status       VARCHAR(8)  NOT NULL CHECK (status IN ('active', 'blocked', 'expired'))
);

CREATE TABLE merchants (
    merchant_id   INTEGER PRIMARY KEY,
    merchant_name VARCHAR(120) NOT NULL,
    mcc           CHAR(4)      NOT NULL,
    category      VARCHAR(30)  NOT NULL,
    country       VARCHAR(60)  NOT NULL,
    city          VARCHAR(80)  NOT NULL,
    is_online     BOOLEAN      NOT NULL
);

CREATE TABLE transactions (
    txn_id        INTEGER PRIMARY KEY,
    card_id       INTEGER       NOT NULL REFERENCES cards(card_id),
    merchant_id   INTEGER       NOT NULL REFERENCES merchants(merchant_id),
    txn_time      TIMESTAMP     NOT NULL,
    amount        NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency      CHAR(3)       NOT NULL,
    channel       VARCHAR(12)   NOT NULL CHECK (channel IN ('chip', 'contactless', 'online', 'atm')),
    entry_country VARCHAR(60)   NOT NULL,
    txns_last_1h  INTEGER       NOT NULL CHECK (txns_last_1h >= 1),
    km_from_last  NUMERIC(8,1)  NOT NULL CHECK (km_from_last >= 0),
    is_declined   BOOLEAN       NOT NULL,
    is_fraud      BOOLEAN       NOT NULL
);
