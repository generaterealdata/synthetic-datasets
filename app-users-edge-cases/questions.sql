-- App Users with Edge Cases for QA Testing: ten practice questions.
-- Written for SQLite (app_users_edge_cases.sqlite); most run unchanged on PostgreSQL.

-- 1. The edge-case names and how often each appears
SELECT display_name, LENGTH(display_name) AS characters, COUNT(*) AS users
FROM users GROUP BY display_name HAVING COUNT(*) > 100 ORDER BY users DESC LIMIT 40;

-- 2. Names that contain characters outside basic ASCII
SELECT COUNT(*) AS users_with_non_ascii_names
FROM users WHERE display_name GLOB '*[^ -~]*';

-- 3. Names with leading or trailing whitespace, or a tab inside
SELECT '[' || display_name || ']' AS shown_in_brackets, COUNT(*) AS users
FROM users WHERE display_name <> TRIM(display_name) OR display_name LIKE '%' || char(9) || '%'
GROUP BY display_name;

-- 4. Email shapes: plus-addressing, subdomains and length
SELECT SUM(email LIKE '%+%@%') AS plus_addressed, SUM(email LIKE '%@mail.%') AS with_subdomain,
       MAX(LENGTH(email)) AS longest_email, MIN(LENGTH(email)) AS shortest_email
FROM users;

-- 5. Users by status, with login and deletion facts
SELECT status, COUNT(*) AS users, SUM(last_login_at IS NULL) AS never_logged_in, SUM(deleted_at IS NOT NULL) AS soft_deleted
FROM users GROUP BY status;

-- 6. Locales and their time zones
SELECT locale, time_zone, COUNT(*) AS users FROM users GROUP BY locale, time_zone ORDER BY users DESC LIMIT 12;

-- 7. Token states: live, expired and revoked (as of 30 September 2026)
SELECT CASE WHEN revoked_at IS NOT NULL THEN 'revoked' WHEN expires_at < '2026-09-30' THEN 'expired' ELSE 'live' END AS state,
       COUNT(*) AS tokens
FROM api_tokens GROUP BY state;

-- 8. Organizations with the most members, and their owners
SELECT o.org_id, o.org_name, o.plan, COUNT(*) AS members, SUM(m.role = 'owner') AS owners
FROM memberships m JOIN organizations o USING (org_id) GROUP BY o.org_id ORDER BY members DESC LIMIT 10;

-- 9. Audit actions and IP versions
SELECT action, COUNT(*) AS events, SUM(ip_address LIKE '%:%') AS ipv6, SUM(ip_address NOT LIKE '%:%') AS ipv4
FROM audit_events GROUP BY action ORDER BY events DESC;

-- 10. Users who belong to more than one organization
SELECT orgs, COUNT(*) AS users
FROM (SELECT user_id, COUNT(DISTINCT org_id) AS orgs FROM memberships GROUP BY user_id)
GROUP BY orgs ORDER BY orgs;
