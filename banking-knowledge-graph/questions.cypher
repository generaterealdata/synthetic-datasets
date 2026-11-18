// Ten questions answered in Neo4j with Cypher. Run after loading:
//   cypher-shell -a neo4j://localhost:7687 -u neo4j -p <password> -f questions.cypher
// The starter notebook on Kaggle answers the same ten questions with pandas on the import CSV files.

// 1. Money moved per month: transfers, total amount and the share flagged suspicious
MATCH ()-[t:TRANSFERRED_TO]->()
WITH substring(toString(t.sent_at), 0, 7) AS month, count(*) AS transfers, sum(t.amount) AS amount,
     sum(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) AS suspicious
RETURN month, transfers, round(amount) AS amount, round(100.0 * suspicious / transfers, 2) AS suspicious_pct ORDER BY month;

// 2. Structuring: suspicious share by transfer amount band (just under the 10,000 reporting line stands out)
MATCH ()-[t:TRANSFERRED_TO]->()
WITH CASE WHEN t.amount < 500 THEN '1: under 500' WHEN t.amount < 2000 THEN '2: 500-1,999'
          WHEN t.amount < 9000 THEN '3: 2,000-8,999' WHEN t.amount < 10000 THEN '4: 9,000-9,999' ELSE '5: 10,000+' END AS band, t
RETURN band, count(*) AS transfers, round(100.0 * sum(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) / count(*), 2) AS suspicious_pct ORDER BY band;

// 3. Who sends suspicious money: suspicious share by the sending owner's KYC risk and PEP flag (two hops)
MATCH (p:Person)<-[:HAS_OWNER_PERSON]-(:Account)-[t:TRANSFERRED_TO]->()
RETURN p.kyc_risk_rating AS kyc, p.is_pep AS pep, count(*) AS transfers,
       round(100.0 * sum(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) / count(*), 2) AS suspicious_pct ORDER BY kyc, pep;

// 4. Card fraud by merchant category and channel
MATCH (:Card)-[p:PAID]->(:Merchant)-[:HAS_MERCHANT_CATEGORY]->(c:MerchantCategory)
WITH c.category AS category, count(*) AS payments,
     sum(CASE WHEN p.channel = 'online' THEN 1 ELSE 0 END) AS online, sum(CASE WHEN p.is_fraud AND p.channel = 'online' THEN 1 ELSE 0 END) AS online_fraud,
     sum(CASE WHEN p.channel <> 'online' THEN 1 ELSE 0 END) AS other, sum(CASE WHEN p.is_fraud AND p.channel <> 'online' THEN 1 ELSE 0 END) AS other_fraud
RETURN category, payments, online,
       CASE WHEN online > 0 THEN round(100.0 * online_fraud / online, 2) END AS online_fraud_pct,
       CASE WHEN other > 0 THEN round(100.0 * other_fraud / other, 2) END AS other_fraud_pct
ORDER BY payments DESC;

// 5. Frozen accounts: suspicious share of the transfers they send, by account status
MATCH (a:Account)-[t:TRANSFERRED_TO]->()
RETURN a.status AS status, count(*) AS transfers, round(100.0 * sum(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) / count(*), 2) AS suspicious_pct ORDER BY status;

// 6. Hubs: the 10 accounts that receive money from the most different accounts
MATCH (s:Account)-[:TRANSFERRED_TO]->(r:Account)
WITH r, count(DISTINCT s) AS senders ORDER BY senders DESC, r.account_id LIMIT 10
MATCH (r)-[:HAS_OWNER_PERSON|HAS_OWNER_BUSINESS]->(o)
RETURN r.account_id AS account, r.type AS type, labels(o)[0] AS owner_kind, senders;

// 7. Exposure: accounts that received money from an account that sent at least one suspicious transfer (two hops)
MATCH (flagged:Account)-[t:TRANSFERRED_TO]->() WHERE t.is_suspicious
WITH DISTINCT flagged
MATCH (flagged)-[:TRANSFERRED_TO]->(r:Account)
RETURN count(DISTINCT flagged) AS flagged_senders, count(DISTINCT r) AS exposed_receivers;

// 8. Sign-ins from someone else's device: accounts signed in from a device whose owner is not the account's owner or joint holder
MATCH (a:Account)-[:SIGNED_IN]->(d:Device)-[:HAS_PERSON]->(p:Person)
WHERE NOT (a)-[:HAS_OWNER_PERSON]->(p) AND NOT (p)-[:JOINT_HOLDER_OF]->(a)
RETURN count(DISTINCT a) AS accounts, count(DISTINCT d) AS devices, count(*) AS sign_ins;

// 9. Money between cities: the 10 city pairs with the most money moved between people's accounts (six hops)
// (three MATCH clauses: a transfer between two accounts of the same person must count too; one pattern would skip it)
MATCH (a1:Account)-[t:TRANSFERRED_TO]->(a2:Account)
MATCH (a1)-[:HAS_OWNER_PERSON]->(:Person)-[:HAS_CITY]->(c1:City)
MATCH (a2)-[:HAS_OWNER_PERSON]->(:Person)-[:HAS_CITY]->(c2:City)
WITH c1.city_name AS from_city, c2.city_name AS to_city, count(t) AS transfers, sum(t.amount) AS amount
RETURN from_city, to_city, transfers, round(amount) AS amount ORDER BY amount DESC LIMIT 10;

// 10. Customers and money flow by city: people, accounts and suspicious transfers sent from accounts of people living there
MATCH (c:City)<-[:HAS_CITY]-(p:Person)<-[:HAS_OWNER_PERSON]-(a:Account)
OPTIONAL MATCH (a)-[t:TRANSFERRED_TO]->()
WITH c, count(DISTINCT p) AS people, count(DISTINCT a) AS accounts, count(t) AS transfers,
     sum(CASE WHEN t.is_suspicious THEN 1 ELSE 0 END) AS suspicious
RETURN c.city_name AS city, c.state AS state, people, accounts, transfers, suspicious ORDER BY people DESC LIMIT 10;
