-- App Users with Edge Cases for QA Testing: rule checks.
-- Each query counts the rows that break one rule. On the full dataset every query returns 0.
-- Written for SQLite; run them all with: python verify.py app-users-edge-cases <database file>

-- organizations.org_id is unique
SELECT COUNT(*) - COUNT(DISTINCT org_id) FROM organizations;

-- organizations.slug is unique
SELECT COUNT(*) - COUNT(DISTINCT slug) FROM organizations;

-- users.user_id is unique
SELECT COUNT(*) - COUNT(DISTINCT user_id) FROM users;

-- users.email is unique
SELECT COUNT(*) - COUNT(DISTINCT email) FROM users;

-- every memberships.org_id exists in organizations
SELECT COUNT(*) FROM memberships c LEFT JOIN organizations p ON p.org_id = c.org_id WHERE c.org_id IS NOT NULL AND p.org_id IS NULL;

-- every memberships.user_id exists in users
SELECT COUNT(*) FROM memberships c LEFT JOIN users p ON p.user_id = c.user_id WHERE c.user_id IS NOT NULL AND p.user_id IS NULL;

-- every api_tokens.user_id exists in users
SELECT COUNT(*) FROM api_tokens c LEFT JOIN users p ON p.user_id = c.user_id WHERE c.user_id IS NOT NULL AND p.user_id IS NULL;

-- every audit_events.org_id exists in organizations
SELECT COUNT(*) FROM audit_events c LEFT JOIN organizations p ON p.org_id = c.org_id WHERE c.org_id IS NOT NULL AND p.org_id IS NULL;

-- every audit_events.user_id exists in users
SELECT COUNT(*) FROM audit_events c LEFT JOIN users p ON p.user_id = c.user_id WHERE c.user_id IS NOT NULL AND p.user_id IS NULL;

-- emails use example domains only
SELECT COUNT(*) FROM users WHERE email NOT LIKE '%@%example.com' AND email NOT LIKE '%@%example.org' AND email NOT LIKE '%@%example.net' AND email NOT LIKE '%@%example.co.uk';

-- plus-addressed emails are present
SELECT CASE WHEN SUM(email LIKE '%+%@%') > 0 THEN 0 ELSE 1 END FROM users;

-- non-Latin, right-to-left and injection-style names are present
SELECT CASE WHEN SUM(display_name = '李伟') > 0 AND SUM(display_name = 'أحمد الفلاسي') > 0 AND SUM(display_name LIKE '%DROP TABLE%') > 0 AND SUM(display_name LIKE '<script>%') > 0 AND SUM(LENGTH(display_name) > 80) > 0 AND SUM(LENGTH(display_name) = 1) > 0 THEN 0 ELSE 1 END FROM users;

-- edge-case names are 10-20% of users
SELECT CASE WHEN AVG(display_name IN ('李伟', '山田太郎', '김민준', 'Zoë Müller', 'José Álvarez', 'X', 'Jo', 'Null', 'undefined', '0', '-1', '🙂', 'O''Connor', 'Дмитрий Иванов', 'דוד כהן', 'أحمد الفلاسي') OR display_name LIKE '%DROP TABLE%' OR display_name LIKE '<script>%' OR LENGTH(display_name) > 80) BETWEEN 0.04 AND 0.2 THEN 0 ELSE 1 END FROM users;

-- deleted_at is set exactly for deleted users
SELECT COUNT(*) FROM users WHERE (status = 'deleted') <> (deleted_at IS NOT NULL);

-- deleted_at is after created_at
SELECT COUNT(*) FROM users WHERE deleted_at IS NOT NULL AND datetime(deleted_at) <= datetime(created_at);

-- invited users have never logged in
SELECT COUNT(*) FROM users WHERE status = 'invited' AND last_login_at IS NOT NULL;

-- last login is after creation
SELECT COUNT(*) FROM users WHERE last_login_at IS NOT NULL AND datetime(last_login_at) < datetime(created_at);

-- every organization has a membership
SELECT COUNT(*) FROM organizations o WHERE NOT EXISTS (SELECT 1 FROM memberships m WHERE m.org_id = o.org_id);

-- joined_at is not before the organization existed
SELECT COUNT(*) FROM memberships m JOIN organizations o USING (org_id) WHERE datetime(m.joined_at) < datetime(o.created_at);

-- a token expires 30-365 days after creation
SELECT COUNT(*) FROM api_tokens WHERE julianday(expires_at) - julianday(created_at) NOT BETWEEN 29.9 AND 365.1;

-- revoked_at is after created_at
SELECT COUNT(*) FROM api_tokens WHERE revoked_at IS NOT NULL AND datetime(revoked_at) < datetime(created_at);

-- both IPv4 and IPv6 addresses are present
SELECT CASE WHEN SUM(ip_address LIKE '%:%') > 0 AND SUM(ip_address LIKE '%.%') > 0 THEN 0 ELSE 1 END FROM audit_events;

-- no token is created or revoked after 2026-09-30
SELECT COUNT(*) FROM api_tokens WHERE date(created_at) > '2026-09-30' OR date(revoked_at) > '2026-09-30';

-- a token is revoked before it expires
SELECT COUNT(*) FROM api_tokens WHERE revoked_at IS NOT NULL AND datetime(revoked_at) > datetime(expires_at);

-- a token is never created before its user
SELECT COUNT(*) FROM api_tokens t JOIN users u USING (user_id) WHERE datetime(t.created_at) < datetime(u.created_at);

-- no audit event is dated after 2026-09-30
SELECT COUNT(*) FROM audit_events WHERE date(occurred_at) > '2026-09-30';

-- an audit event never happens before its user or organization existed
SELECT COUNT(*) FROM audit_events a JOIN users u USING (user_id) JOIN organizations o USING (org_id) WHERE datetime(a.occurred_at) < datetime(u.created_at) OR datetime(a.occurred_at) < datetime(o.created_at);

-- no login or deletion is dated after 2026-09-30
SELECT COUNT(*) FROM users WHERE date(last_login_at) > '2026-09-30' OR date(deleted_at) > '2026-09-30';

-- no membership starts after 2026-09-30
SELECT COUNT(*) FROM memberships WHERE date(joined_at) > '2026-09-30';

-- a membership never starts before the user's account existed
SELECT COUNT(*) FROM memberships m JOIN users u USING (user_id) WHERE datetime(m.joined_at) < datetime(u.created_at);
