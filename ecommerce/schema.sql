-- Synthetic E-commerce Database
-- Schema used to generate this dataset with GenerateRealData (https://generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE customers (
    customer_id      INTEGER PRIMARY KEY,
    first_name       VARCHAR(60)  NOT NULL,
    last_name        VARCHAR(60)  NOT NULL,
    email            VARCHAR(160) NOT NULL UNIQUE,
    phone            VARCHAR(30),
    country          VARCHAR(60)  NOT NULL,
    city             VARCHAR(80)  NOT NULL,
    signup_date      DATE         NOT NULL,
    loyalty_tier     VARCHAR(10)  NOT NULL CHECK (loyalty_tier IN ('none', 'silver', 'gold', 'platinum')),
    marketing_opt_in BOOLEAN      NOT NULL
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    sku          VARCHAR(20)   NOT NULL UNIQUE,
    product_name VARCHAR(120)  NOT NULL,
    category     VARCHAR(40)   NOT NULL,
    brand        VARCHAR(60)   NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    unit_cost    NUMERIC(10,2) NOT NULL CHECK (unit_cost > 0),
    weight_kg    NUMERIC(6,2),
    is_active    BOOLEAN       NOT NULL,
    created_at   DATE          NOT NULL
);

CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER       NOT NULL REFERENCES customers(customer_id),
    order_date      TIMESTAMP     NOT NULL,
    status          VARCHAR(12)   NOT NULL CHECK (status IN ('processing', 'shipped', 'delivered', 'cancelled', 'returned')),
    channel         VARCHAR(12)   NOT NULL CHECK (channel IN ('web', 'app', 'marketplace', 'store')),
    subtotal        NUMERIC(12,2) NOT NULL,
    discount_amount NUMERIC(12,2) NOT NULL,
    shipping_fee    NUMERIC(8,2)  NOT NULL,
    tax_amount      NUMERIC(12,2) NOT NULL,
    total_amount    NUMERIC(12,2) NOT NULL,
    currency        CHAR(3)       NOT NULL
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER       NOT NULL REFERENCES orders(order_id),
    product_id    INTEGER       NOT NULL REFERENCES products(product_id),
    quantity      INTEGER       NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL,
    line_total    NUMERIC(12,2) NOT NULL
);

CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    order_id   INTEGER       NOT NULL REFERENCES orders(order_id),
    method     VARCHAR(16)   NOT NULL CHECK (method IN ('card', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer', 'klarna')),
    amount     NUMERIC(12,2) NOT NULL,
    paid_at    TIMESTAMP     NOT NULL,
    status     VARCHAR(10)   NOT NULL CHECK (status IN ('captured', 'refunded', 'failed'))
);

CREATE TABLE shipments (
    shipment_id     INTEGER PRIMARY KEY,
    order_id        INTEGER     NOT NULL REFERENCES orders(order_id),
    carrier         VARCHAR(30) NOT NULL,
    tracking_number VARCHAR(30) NOT NULL UNIQUE,
    shipped_at      TIMESTAMP   NOT NULL,
    delivered_at    TIMESTAMP,
    status          VARCHAR(12) NOT NULL CHECK (status IN ('in_transit', 'delivered', 'lost'))
);

CREATE TABLE returns (
    return_id     INTEGER PRIMARY KEY,
    order_item_id INTEGER       NOT NULL REFERENCES order_items(order_item_id),
    reason        VARCHAR(20)   NOT NULL CHECK (reason IN ('wrong_size', 'damaged', 'not_as_described', 'changed_mind', 'arrived_late')),
    refund_amount NUMERIC(12,2) NOT NULL,
    requested_at  TIMESTAMP     NOT NULL,
    status        VARCHAR(10)   NOT NULL CHECK (status IN ('requested', 'approved', 'refunded', 'rejected'))
);
