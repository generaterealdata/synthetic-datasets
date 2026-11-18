// Proof queries: every rule of this knowledge graph checked inside Neo4j. Each query returns how many nodes or
// relationships break the rule; all should return 0.
// Run after loading (and after constraints.cypher):
//   cypher-shell -a neo4j://localhost:7687 -u neo4j -p <password> -f proof_queries.cypher

// Keys: unique emails and account numbers (constraints.cypher also makes every node key unique)
MATCH (p:Person) WITH p.email AS v, count(*) AS c WHERE c > 1 RETURN count(*) AS broken;
MATCH (a:Account) WITH a.account_number AS v, count(*) AS c WHERE c > 1 RETURN count(*) AS broken;

// Ownership: every account has exactly one owner, a business for business accounts and a person otherwise
MATCH (a:Account) WHERE COUNT { (a)-[:HAS_OWNER_PERSON|HAS_OWNER_BUSINESS]->() } <> 1 RETURN count(a) AS broken;
MATCH (a:Account)-[:HAS_OWNER_BUSINESS]->() WHERE a.type <> 'business' RETURN count(a) AS broken;
MATCH (a:Account)-[:HAS_OWNER_PERSON]->() WHERE a.type = 'business' RETURN count(a) AS broken;
// Every account is at one branch, every card on one account, every device owned by one person
MATCH (a:Account) WHERE COUNT { (a)-[:HAS_BRANCH]->(:Branch) } <> 1 RETURN count(a) AS broken;
MATCH (c:Card) WHERE COUNT { (c)-[:HAS_ACCOUNT]->(:Account) } <> 1 RETURN count(c) AS broken;
MATCH (d:Device) WHERE COUNT { (d)-[:HAS_PERSON]->(:Person) } <> 1 RETURN count(d) AS broken;
// Every person, merchant and branch is in a city; every merchant has a category
MATCH (p:Person) WHERE COUNT { (p)-[:HAS_CITY]->(:City) } <> 1 RETURN count(p) AS broken;
MATCH (b:Branch) WHERE COUNT { (b)-[:HAS_CITY]->(:City) } <> 1 RETURN count(b) AS broken;
MATCH (m:Merchant) WHERE COUNT { (m)-[:HAS_CITY]->(:City) } <> 1 OR COUNT { (m)-[:HAS_MERCHANT_CATEGORY]->(:MerchantCategory) } <> 1 RETURN count(m) AS broken;

// Money: no account sends money to itself; amounts are positive; balances never negative
MATCH (a:Account)-[t:TRANSFERRED_TO]->(a) RETURN count(t) AS broken;
MATCH ()-[t:TRANSFERRED_TO]->() WHERE t.amount <= 0 RETURN count(t) AS broken;
MATCH ()-[p:PAID]->() WHERE p.amount <= 0 RETURN count(p) AS broken;
MATCH (a:Account) WHERE a.current_balance < 0 RETURN count(a) AS broken;
// Every transfer is flagged true or false; so is every card payment
MATCH ()-[t:TRANSFERRED_TO]->() WHERE t.is_suspicious IS NULL RETURN count(t) AS broken;
MATCH ()-[p:PAID]->() WHERE p.is_fraud IS NULL RETURN count(p) AS broken;

// Time order
MATCH (s:Account)-[t:TRANSFERRED_TO]->(r:Account) WHERE t.sent_at < s.opened_date OR t.sent_at < r.opened_date RETURN count(t) AS broken;
MATCH (c:Card)-[p:PAID]->(:Merchant) WHERE p.paid_at < c.issued_date RETURN count(p) AS broken;
MATCH (c:Card)-[:HAS_ACCOUNT]->(a:Account) WHERE c.issued_date < a.opened_date RETURN count(c) AS broken;
MATCH (c:Card) WHERE c.expiry_date <= c.issued_date RETURN count(c) AS broken;
MATCH (a:Account)-[s:SIGNED_IN]->(d:Device) WHERE s.signed_in_at < a.opened_date OR date(s.signed_in_at) < d.first_seen_date RETURN count(s) AS broken;
MATCH (a:Account)-[:HAS_OWNER_PERSON]->(p:Person) WHERE date(a.opened_date) < p.customer_since RETURN count(a) AS broken;
MATCH (:Person)-[d:DIRECTOR_OF]->(b:Business) WHERE date(d.since) < b.incorporation_date RETURN count(d) AS broken;
MATCH (a:Account) WHERE (a.status = 'closed') <> (a.closed_date IS NOT NULL) RETURN count(a) AS broken;
MATCH (a:Account) WHERE a.closed_date < date(a.opened_date) RETURN count(a) AS broken;

// No repeated memberships and no self-links
MATCH (p:Person)-[r:DIRECTOR_OF]->(b:Business) WITH p, b, count(r) AS c WHERE c > 1 RETURN count(*) AS broken;
MATCH (p:Person)-[r:JOINT_HOLDER_OF]->(a:Account) WITH p, a, count(r) AS c WHERE c > 1 RETURN count(*) AS broken;
MATCH (d:Device)-[r:USED_IP]->(i:IpAddress) WITH d, i, count(r) AS c WHERE c > 1 RETURN count(*) AS broken;
MATCH (p:Person)-[r:REFERRED]->(p) RETURN count(r) AS broken;
MATCH (p:Person)<-[r:REFERRED]-() WITH p, count(r) AS c WHERE c > 1 RETURN count(*) AS broken;
