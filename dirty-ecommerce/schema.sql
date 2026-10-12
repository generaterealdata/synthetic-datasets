-- Dirty E-commerce Data for Cleaning Practice
-- Schema used to generate this dataset with GenerateRealData (https://generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    email       VARCHAR(160) NOT NULL,
    phone       VARCHAR(30),
    country     VARCHAR(60)  NOT NULL,
    city        VARCHAR(80)  NOT NULL,
    birth_date  DATE,
    signup_date DATE         NOT NULL
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    product_name VARCHAR(120)  NOT NULL,
    category     VARCHAR(40)   NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL,
    stock_qty    INTEGER       NOT NULL
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id INTEGER       NOT NULL REFERENCES customers(customer_id),
    order_date  DATE          NOT NULL,
    ship_date   DATE,
    status      VARCHAR(12)   NOT NULL CHECK (status IN ('pending', 'shipped', 'delivered', 'cancelled')),
    order_total NUMERIC(12,2) NOT NULL,
    country     VARCHAR(60)   NOT NULL
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER       NOT NULL REFERENCES products(product_id),
    quantity      INTEGER       NOT NULL,
    unit_price    NUMERIC(10,2) NOT NULL,
    line_total    NUMERIC(12,2) NOT NULL
);
