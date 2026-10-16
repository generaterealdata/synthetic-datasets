# Synthetic datasets

**11 free, realistic, fully synthetic databases (3.7 million rows) for SQL practice, software testing, analytics and teaching.** Each one is a set of related tables whose keys match, totals add up and dates are in order, and each comes with the queries that prove it.

No real person, company or transaction appears in any file, so the data can be used and shared without privacy approval. Licence: [CC BY 4.0](LICENSE).

| Dataset | Tables | Rows | Good for | Full data |
|---|---:|---:|---|---|
| [Synthetic E-commerce Database](ecommerce/) | 7 | 499,385 | SQL practice, shop and billing test data, BI dashboards | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-ecommerce-database) |
| [Dirty E-commerce Data for Cleaning Practice](dirty-ecommerce/) | 4 | 250,000 | Data-cleaning practice with an answer key | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/dirty-ecommerce-data-for-cleaning-practice) |
| [Synthetic Bank Card Transactions with Fraud Labels](bank-card-fraud/) | 5 | 500,000 | Fraud detection on imbalanced, labelled data | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-card-transactions-fraud-labels) |
| [Synthetic SaaS Subscriptions and Churn](saas-subscriptions/) | 6 | 249,113 | MRR, churn and cohort analysis | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-saas-subscriptions-churn) |
| [Synthetic Web Analytics Funnel Events](web-funnel-events/) | 4 | 425,918 | Funnel, path and conversion analysis | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-web-analytics-funnel-events) |
| [Synthetic Hospital Records (No Real Patients)](hospital-records/) | 6 | 300,000 | Healthcare analytics and software testing without privacy risk | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-hospital-records) |
| [App Users with Edge Cases for QA Testing](app-users-edge-cases/) | 5 | 200,000 | QA seed data: Unicode, injection strings, soft deletes | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/app-users-edge-cases-qa-testing) |
| [Synthetic HR, Workforce and Attrition](hr-workforce-attrition/) | 6 | 155,186 | People analytics: headcount, pay bands, turnover | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/synthetic-hr-workforce-attrition) |
| [Synthetic Smart Meter Readings (15-Minute Intervals)](smart-meter-readings/) | 3 | 500,000 | Time-series analysis of 15-minute energy readings | Kaggle (coming soon) |
| [Synthetic Auto Insurance Policies and Claims](auto-insurance-claims/) | 5 | 192,843 | Claims analytics: frequency, severity, reserves | Kaggle (coming soon) |
| [Synthetic Fleet GPS Tracking](fleet-gps-tracking/) | 4 | 404,052 | Trajectory analysis, geofencing, telematics testing | Kaggle (coming soon) |

## What is in each folder

| File | What it is |
|---|---|
| `README.md` | The data card: the story, a table diagram, the rules that hold, every column explained with measured values, and what to keep in mind |
| `sample/` | A connected slice of up to 1,000 rows per table as CSV, so joins work on the sample too |
| `schema.sql` | The `CREATE TABLE` statements |
| `checks.sql` | One query per rule; each counts the rows breaking the rule and returns 0 |
| `questions.sql` | Ten practice questions with their queries |
| `generation.json`, `plan.json` | The settings, seed and full generation plan, so the dataset can be re-created exactly |

The full data of each dataset (CSV files and a SQLite database) is on its Kaggle page, linked in the table above.

## Quick start

Download the SQLite file from a dataset's Kaggle page and query it. Nothing to install beyond Python:

```python
import sqlite3

con = sqlite3.connect("ecommerce.sqlite")
for row in con.execute("""
    SELECT substr(order_date, 1, 7) AS month, COUNT(*) AS orders, ROUND(SUM(total_amount), 2) AS revenue
    FROM orders WHERE status <> 'cancelled' GROUP BY month ORDER BY month LIMIT 5"""):
    print(row)
```

Or load the CSV files with pandas, or run the `.sql` script in PostgreSQL with `psql -d your_database -f ecommerce.sql`.

## Check the data yourself

Every claim in a data card is a query. Run them all on a downloaded file:

```bash
python verify.py ecommerce path/to/ecommerce.sqlite
```

It prints one line per rule and ends with a line such as `48 of 48 rules hold.`

## How the data is made

The datasets are generated with [GenerateRealData](https://generaterealdata.com) from a database schema plus rules in plain terms (for example: a payment equals its order total; a cancelled order has no shipment). Each run uses a fixed seed, so it can be repeated exactly: [`scripts/recreate.py`](scripts/recreate.py) rebuilds any dataset here through the [API](https://generaterealdata.com/docs/api/). No value is edited after generation, and no field is written by AI.

Each data card also has a *Good to know* section listing what the dataset does not model. Read it before drawing conclusions: these are teaching and testing datasets, not samples of a real population.

Need a different schema, more rows or your own rules? Generate your own at [generaterealdata.com](https://generaterealdata.com). Code examples for the API are in the [API examples repository](https://github.com/generaterealdata/api-examples).

## Licence and credit

The data and documentation are licensed under [CC BY 4.0](LICENSE): use them for anything, including commercial work, and credit "GenerateRealData" with a link to https://generaterealdata.com. The scripts are also available under the MIT licence.

Found a problem in a dataset? Please open an issue.
