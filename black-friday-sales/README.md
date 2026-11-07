# Black Friday and Cyber Week Sales 2023-2025

**408K US holiday purchases: discounts, channels, payments and returns.**

> **Made with [GenerateRealData](https://www.generaterealdata.com?ref=github).** You can create your own realistic datasets like this one in minutes, from a single table to a full database with many linked tables. Just describe what you need in plain English, or upload your SQL schema. IDs match across tables, totals add up, and your business rules hold on every row. With 232 data types and 222 built-in generators, it has one of the largest libraries of any test data generator. **Try it free at [www.generaterealdata.com](https://www.generaterealdata.com?ref=github)**, or write to support@generaterealdata.com.

408,000 purchases from a US retailer's holiday season in 2023, 2024 and 2025: early November, the days before Thanksgiving, Thanksgiving Day, Black Friday, the weekend after, Cyber Monday and Cyber Week. Each row is one purchase with when it happened (date, event day, hour), how (web, app or store, device, payment, fulfilment), who bought it (segment, age group, gender, state), what was bought (category, product, brand), the money (list price, discount, unit price, quantity, coupon, order total) and what happened next (delivery days, returned or not, return reason, rating). One wide table that works on its own; all brands and products are fictional.

| | |
|---|---|
| Tables | 1 |
| Rows | 408,000 |
| Full data | [Kaggle](https://www.kaggle.com/datasets/generaterealdata/black-friday-and-cyber-week-sales): CSV files and a SQLite database |
| Sample in this folder | [`sample/`](sample/), a connected slice of up to 1,000 rows per table |
| Licence | [CC BY 4.0](../LICENSE): free to use, share and adapt, with credit |
| Made with | [GenerateRealData](https://www.generaterealdata.com/industries/retail-ecommerce/?ref=github), a relational synthetic data generator with 232 data types and 222 built-in generators, one of the largest libraries of any test data generator; fully synthetic, no real records |

## What makes it useful

- The calendar drives everything: Black Friday alone is 26% of purchases and Cyber Monday 20%. Average discounts go from 11% in early November to 33% on Cyber Monday and 38% on Black Friday.
- Each day has its own rhythm: Black Friday peaks at 6-8 am with door-buster store traffic (35% of its purchases in store), while Thanksgiving and Cyber Monday peak at 7-9 pm, and Thanksgiving is almost entirely online (3% in store).
- Returns you can predict: 21% of purchases are returned, from 9% of books to 41% of apparel. New customers, deep discounts, buy-now-pay-later, several items, late-night orders and slow deliveries all raise the chance. A gradient-boosting model reaches ROC AUC 0.74 on held-out rows: learnable, not trivial.
- The money adds up on every row: unit price = list price minus the discount, line total = unit price x quantity, order total = line total minus the coupon. 23 rules are checked with SQL and all hold.
- Three years of growth: 122K purchases ($23.6M) in 2023, 135K ($26.4M) in 2024 and 151K ($29.4M) in 2025.

**Good for:** Classification: predict which purchases will be returned; Exploratory analysis and dashboards of holiday sales; SQL practice on one wide table: group by, window functions, pivots; Discount and pricing analysis; Teaching data leakage (return_reason and customer_rating give the answer away).

## Tables

```mermaid
erDiagram
```

| Table | Rows | What it holds |
|---|---:|---|
| `purchases` | 408,000 | One row per purchase: the only table. |

## Rules you can rely on

23 rules were checked on the full dataset and all 23 hold. Each rule is a query that counts the rows breaking it, and every count is 0. The queries are in [`checks.sql`](checks.sql).

- purchases.purchase_id is unique
- Every order falls between 1 November and the end of Cyber Week
- Year is the year of the order date
- Black Friday rows are dated on Black Friday
- Cyber Monday rows are dated on Cyber Monday
- Thanksgiving rows are dated on Thanksgiving
- order_hour is 0-23
- Store purchases are made in store, and only they
- Only store purchases have no delivery time
- Delivery time matches the fulfilment
- Free 2-day shipping is for loyalty members only
- product_name = brand + product type
- Each product type belongs to one category
- Each brand belongs to one category
- List prices end in .99
- Discount is 0-70%
- unit_price = list_price less the discount
- line_total = unit_price x quantity
- Coupon savings are 0 without a coupon and 5-15% of the line with one
- order_total = line_total - coupon savings
- A return reason is given exactly for returned purchases
- 'Wrong size' is a return reason for apparel only
- Ratings are 1-5

## Column dictionary

The last column is measured from the data.

### `purchases` (408,000 rows)

One row per purchase: the only table.

| Column | Type | Meaning | In this dataset |
|---|---|---|---|
| `purchase_id` (PK) | VARCHAR(12) | Purchase id, BF-0000001 onwards (primary key). | BF-0000001 to BF-0408000 |
| `order_date` | DATE | Date of the purchase, between 1 November and the end of Cyber Week of each year. | 2023-11-01 to 2025-12-04 |
| `year` | INTEGER | Year of the purchase: 2023, 2024 or 2025. | `2025` 37.1%, `2024` 33%, `2023` 29.9% |
| `event_day` | VARCHAR(24) | Which part of the season: Early November, Thanksgiving week, Thanksgiving, Black Friday, Black Friday weekend, Cyber Monday or Cyber Week. | `Black Friday` 26.1%, `Cyber Monday` 19.9%, `Black Friday weekend` 15.9%, `Early November` 12%, `Cyber Week` 10%, `Thanksgiving week` 9%, `Thanksgiving` 7% |
| `order_hour` | INTEGER | Hour of the day the purchase was made, 0-23; each event day has its own pattern. | 0 to 23 |
| `channel` | VARCHAR(8) | Web, App or Store; stores are busiest on Black Friday and almost closed on Thanksgiving. | `Web` 42.5%, `App` 36.9%, `Store` 20.5% |
| `device` | VARCHAR(10) | Mobile, Desktop or Tablet for online purchases; 'In store' for store purchases. | `Mobile` 54.5%, `In store` 20.5%, `Desktop` 17.1%, `Tablet` 7.9% |
| `customer_id` | INTEGER | A customer number drawn for each purchase (not a consistent customer; see Good to know). | 1 to 149,999 |
| `customer_segment` | VARCHAR(16) | New, Returning or Loyalty member. | `Returning` 46%, `New` 29.9%, `Loyalty member` 24.1% |
| `age_group` | VARCHAR(8) | 18-24, 25-34, 35-44, 45-54, 55-64 or 65+. | `25-34` 26%, `35-44` 23.9%, `45-54` 17%, `18-24` 14%, `55-64` 12%, `65+` 7.1% |
| `gender` | VARCHAR(10) | Female, Male or Not stated. | `Female` 50%, `Male` 47%, `Not stated` 3% |
| `state` | VARCHAR(30) | US state (or District of Columbia) of the customer; follows population. | 51 different values, e.g. `Colorado`, `California` |
| `product_category` | VARCHAR(24) | One of 10 categories, from Electronics and Apparel to Books and Smart Home. | `Electronics` 24.1%, `Apparel` 17.9%, `Home & Kitchen` 14%, `Toys & Games` 11.9%, `Beauty` 8%, `Sports & Outdoors` 7%, `Video Games` 6%, `Jewelry` 4.1% and 2 more |
| `product_type` | VARCHAR(32) | One of 47 product types, each in one category (for example 4K Smart TV, Air Fryer, Puffer Jacket). | 47 different values, e.g. `Laptop`, `Wireless Earbuds` |
| `product_name` | VARCHAR(80) | Fictional brand plus product type, for example 'Lumora Laptop'. | 188 different values, e.g. `Lumora Laptop`, `Nexwave Wireless Earbuds` |
| `brand` | VARCHAR(30) | One of 40 fictional brands, four per category. | 40 different values, e.g. `Lumora`, `Nexwave` |
| `list_price` | NUMERIC(10,2) | Regular price in US dollars, within a typical range for the product type; ends in .99. | 7.99 to 1,898.99 |
| `discount_pct` | INTEGER | Discount in percent, 0-58; deepest on Black Friday and Cyber Monday, a little deeper for apparel, electronics, toys and jewelry and smaller for books. | 0 to 58 |
| `unit_price` | NUMERIC(10,2) | Price paid per item: list_price minus the discount, rounded to cents. | 4.05 to 1,796.44 |
| `quantity` | INTEGER | Items bought, 1-5; one item in 74% of purchases. | `1` 74%, `2` 17%, `3` 5%, `4` 2.5%, `5` 1.5% |
| `line_total` | NUMERIC(12,2) | unit_price x quantity. | 4.05 to 8,112.15 |
| `coupon_used` | BOOLEAN | 1 if a coupon was applied; more common on Black Friday and Cyber Monday. | `0` 79.4%, `1` 20.6% |
| `coupon_savings` | NUMERIC(10,2) | Coupon value in US dollars, 5-15% of line_total; 0 without a coupon. | 0 to 863.63 |
| `order_total` | NUMERIC(12,2) | Amount paid: line_total minus coupon_savings. | 4.05 to 8,112.15 |
| `payment_method` | VARCHAR(20) | Credit card, Debit card, PayPal, Apple Pay, Buy now, pay later or Gift card; pay-later is three times as common on orders of $400 or more. | `Credit card` 40.7%, `Debit card` 22.8%, `PayPal` 14.7%, `Apple Pay` 9.6%, `Buy now, pay later` 7.4%, `Gift card` 4.8% |
| `fulfilment` | VARCHAR(24) | Store purchase, Standard shipping, Express shipping, Free 2-day shipping (loyalty members) or Pick up in store. | `Standard shipping` 46.6%, `Store purchase` 20.5%, `Express shipping` 12.8%, `Pick up in store` 12.5%, `Free 2-day shipping` 7.6% |
| `delivery_days` | INTEGER | Days until the customer had the item: 0-1 for pick-up, 1-2 express, 2-3 free 2-day, 3-10 standard (slower on the busiest days); empty for store purchases. | `1` 12.6%, `2` 10.2%, `7` 8.5%, `6` 8.4%, `5` 8.4%, `8` 6.3%, `0` 6.2%, `4` 6.2% and 3 more; 20.5% empty |
| `is_returned` | BOOLEAN | 1 if the purchase was returned. The column to predict. | `0` 78.9%, `1` 21.1% |
| `return_reason` | VARCHAR(24) | Why it was returned (Wrong size, Changed mind, Not as described, Defective, Better price found, Arrived late); empty if not returned. | `Changed mind` 5.7%, `Wrong size` 4.1%, `Not as described` 3.5%, `Defective` 3.3%, `Better price found` 2.3%, `Arrived late` 2.1%; 78.9% empty |
| `customer_rating` | INTEGER | Rating 1-5 given by the customer; empty when no rating was left (60%). Lower for returned purchases. | `5` 15.2%, `4` 9.7%, `3` 6.6%, `2` 5%, `1` 3.8%; 59.7% empty |

## Questions to try

**Purchases, revenue and average discount by event day**

```sql
SELECT event_day, COUNT(*) AS purchases, ROUND(SUM(order_total)) AS revenue_usd, ROUND(AVG(discount_pct), 1) AS avg_discount_pct
FROM purchases GROUP BY event_day ORDER BY revenue_usd DESC;
```

**Growth from year to year**

```sql
SELECT year, COUNT(*) AS purchases, ROUND(SUM(order_total)) AS revenue_usd,
       ROUND(100.0 * SUM(order_total) / LAG(SUM(order_total)) OVER (ORDER BY year) - 100, 1) AS revenue_growth_pct
FROM purchases GROUP BY year ORDER BY year;
```

**The busiest hour of Thanksgiving, Black Friday and Cyber Monday (window function)**

```sql
SELECT event_day, order_hour, purchases FROM (
    SELECT event_day, order_hour, COUNT(*) AS purchases,
           ROW_NUMBER() OVER (PARTITION BY event_day ORDER BY COUNT(*) DESC) AS rnk
    FROM purchases WHERE event_day IN ('Thanksgiving', 'Black Friday', 'Cyber Monday')
    GROUP BY event_day, order_hour)
WHERE rnk = 1;
```

Seven more are in [`questions.sql`](questions.sql). All ten run as written on the SQLite file.

## Good to know

- Returns are built from the factors listed above plus chance, so a model learns exactly those; use the dataset to practise analysis and modelling, not as evidence about a real retailer.
- return_reason is filled only for returned purchases, and customer_rating is lower for them: both give is_returned away, so drop them when predicting returns.
- customer_id is drawn for each purchase on its own, not a consistent customer: the same number can appear with a different age group, segment or state. Do not build per-customer features from it.
- Only the season is covered: from 1 November to the end of Cyber Week each year, with no December holiday sales.
- Product names are a fictional brand plus a product type (40 brands, 47 product types); list prices are drawn within a typical range per product type and end in .99.
- delivery_days is empty for store purchases. State follows population, so California, Texas and Florida lead.
- Yes/no columns hold 1 and 0. Empty cells in the CSV files mean no value (NULL in the database files).
- The CSV files are UTF-8. Dates are `YYYY-MM-DD` and timestamps `YYYY-MM-DD HH:MM:SS`.

## Files

| File | What it is |
|---|---|
| `schema.sql` | The `CREATE TABLE` statements (PostgreSQL syntax) the data was generated from |
| `generation.json` | Settings of the run: seed, rows per table, options |
| `plan.json` | The full generation plan: one rule set per column |
| `checks.sql` | One query per rule above; each returns 0 on the full dataset |
| `questions.sql` | Ten practice questions with their queries |
| `sample/` | `purchases.csv` 1,000 rows |

## Re-create it

The dataset is reproducible. With a GenerateRealData API key, [`scripts/recreate.py`](../scripts/recreate.py) sends `plan.json`, `schema.sql` and the seed `20261313` to the API and downloads the same data:

```bash
python scripts/recreate.py black-friday-sales
```

To build your own version, change the row counts or rules, or start from your own schema: [www.generaterealdata.com/industries/retail-ecommerce/](https://www.generaterealdata.com/industries/retail-ecommerce/?ref=github).

## How it was made

Fully synthetic: generated with [GenerateRealData](https://www.generaterealdata.com/industries/retail-ecommerce/?ref=github) from a database schema and a set of rules, using a fixed seed. No real person, company or transaction is in the data, and no value was edited after generation. No field was written by AI. 

## Licence

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Use it for anything, including commercial work; please credit "Black Friday and Cyber Week Sales 2023-2025, GenerateRealData" with a link to https://www.generaterealdata.com.
