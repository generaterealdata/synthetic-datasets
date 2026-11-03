-- Black Friday and Cyber Week Sales 2023-2025
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE purchases (
    purchase_id         VARCHAR(12)   PRIMARY KEY,
    order_date          DATE          NOT NULL,
    year                INTEGER       NOT NULL,
    event_day           VARCHAR(24)   NOT NULL,
    order_hour          INTEGER       NOT NULL,
    channel             VARCHAR(8)    NOT NULL,
    device              VARCHAR(10)   NOT NULL,
    customer_id         INTEGER       NOT NULL,
    customer_segment    VARCHAR(16)   NOT NULL,
    age_group           VARCHAR(8)    NOT NULL,
    gender              VARCHAR(10)   NOT NULL,
    state               VARCHAR(30)   NOT NULL,
    product_category    VARCHAR(24)   NOT NULL,
    product_type        VARCHAR(32)   NOT NULL,
    product_name        VARCHAR(80)   NOT NULL,
    brand               VARCHAR(30)   NOT NULL,
    list_price          NUMERIC(10,2) NOT NULL,
    discount_pct        INTEGER       NOT NULL,
    unit_price          NUMERIC(10,2) NOT NULL,
    quantity            INTEGER       NOT NULL,
    line_total          NUMERIC(12,2) NOT NULL,
    coupon_used         BOOLEAN       NOT NULL,
    coupon_savings      NUMERIC(10,2) NOT NULL,
    order_total         NUMERIC(12,2) NOT NULL,
    payment_method      VARCHAR(20)   NOT NULL,
    fulfilment          VARCHAR(24)   NOT NULL,
    delivery_days       INTEGER,
    is_returned         BOOLEAN       NOT NULL,
    return_reason       VARCHAR(24),
    customer_rating     INTEGER
);
