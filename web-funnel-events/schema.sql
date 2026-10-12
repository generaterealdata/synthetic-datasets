-- Synthetic Web Analytics Funnel Events
-- Schema used to generate this dataset with GenerateRealData (https://generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE users (
    user_id             INTEGER PRIMARY KEY,
    signup_date         DATE        NOT NULL,
    country             VARCHAR(60) NOT NULL,
    device_preference   VARCHAR(8)  NOT NULL CHECK (device_preference IN ('mobile', 'desktop', 'tablet')),
    acquisition_channel VARCHAR(14) NOT NULL CHECK (acquisition_channel IN ('organic', 'paid_search', 'social', 'email', 'referral', 'direct')),
    is_customer         BOOLEAN     NOT NULL
);

CREATE TABLE sessions (
    session_id   INTEGER PRIMARY KEY,
    user_id      INTEGER      NOT NULL REFERENCES users(user_id),
    started_at   TIMESTAMP    NOT NULL,
    device       VARCHAR(8)   NOT NULL CHECK (device IN ('mobile', 'desktop', 'tablet')),
    browser      VARCHAR(20)  NOT NULL,
    referrer     VARCHAR(40)  NOT NULL,
    landing_page VARCHAR(120) NOT NULL,
    duration_s   INTEGER      NOT NULL
);

CREATE TABLE events (
    event_id     INTEGER PRIMARY KEY,
    session_id   INTEGER       NOT NULL REFERENCES sessions(session_id),
    step_no      INTEGER       NOT NULL CHECK (step_no >= 1),
    event_name   VARCHAR(16)   NOT NULL CHECK (event_name IN ('session_start', 'search', 'view_product', 'add_to_cart', 'begin_checkout', 'purchase', 'exit')),
    page_path    VARCHAR(120)  NOT NULL,
    occurred_at  TIMESTAMP     NOT NULL,
    secs_on_step INTEGER       NOT NULL CHECK (secs_on_step >= 0),
    cart_value   NUMERIC(10,2) NOT NULL CHECK (cart_value >= 0)
);

CREATE TABLE conversions (
    conversion_id INTEGER PRIMARY KEY,
    session_id    INTEGER       NOT NULL REFERENCES sessions(session_id),
    order_value   NUMERIC(10,2) NOT NULL,
    items         INTEGER       NOT NULL CHECK (items > 0),
    coupon_code   VARCHAR(16),
    converted_at  TIMESTAMP     NOT NULL
);
