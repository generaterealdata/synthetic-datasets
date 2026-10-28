-- App Users with Edge Cases for QA Testing
-- Schema used to generate this dataset with GenerateRealData (https://www.generaterealdata.com).
-- PostgreSQL syntax; structure only.

CREATE TABLE organizations (
    org_id     INTEGER PRIMARY KEY,
    org_name   VARCHAR(160) NOT NULL,
    slug       VARCHAR(80)  NOT NULL UNIQUE,
    plan       VARCHAR(12)  NOT NULL CHECK (plan IN ('free', 'team', 'business', 'enterprise')),
    created_at TIMESTAMP    NOT NULL
);

CREATE TABLE users (
    user_id       INTEGER PRIMARY KEY,
    email         VARCHAR(254) NOT NULL UNIQUE,
    display_name  VARCHAR(160) NOT NULL,
    locale        VARCHAR(8)   NOT NULL,
    time_zone     VARCHAR(40)  NOT NULL,
    mfa_enabled   BOOLEAN      NOT NULL,
    status        VARCHAR(10)  NOT NULL CHECK (status IN ('active', 'invited', 'suspended', 'deleted')),
    created_at    TIMESTAMP    NOT NULL,
    last_login_at TIMESTAMP,
    deleted_at    TIMESTAMP
);

CREATE TABLE memberships (
    membership_id INTEGER PRIMARY KEY,
    org_id        INTEGER    NOT NULL REFERENCES organizations(org_id),
    user_id       INTEGER    NOT NULL REFERENCES users(user_id),
    role          VARCHAR(8) NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
    joined_at     TIMESTAMP  NOT NULL
);

CREATE TABLE api_tokens (
    token_id     INTEGER PRIMARY KEY,
    user_id      INTEGER     NOT NULL REFERENCES users(user_id),
    token_prefix VARCHAR(12) NOT NULL,
    scopes       VARCHAR(60) NOT NULL,
    created_at   TIMESTAMP   NOT NULL,
    expires_at   TIMESTAMP   NOT NULL,
    revoked_at   TIMESTAMP
);

CREATE TABLE audit_events (
    event_id    INTEGER PRIMARY KEY,
    org_id      INTEGER     NOT NULL REFERENCES organizations(org_id),
    user_id     INTEGER     NOT NULL REFERENCES users(user_id),
    action      VARCHAR(30) NOT NULL,
    target_type VARCHAR(20) NOT NULL,
    ip_address  VARCHAR(45) NOT NULL,
    occurred_at TIMESTAMP   NOT NULL
);
