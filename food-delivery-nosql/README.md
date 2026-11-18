# Food Delivery NoSQL Database (MongoDB)

> **Made with [GenerateRealData](https://www.generaterealdata.com?ref=kaggle).** You can create your own realistic datasets like this one in minutes: SQL databases with many linked tables, NoSQL document databases for MongoDB, Firestore, DynamoDB and Elasticsearch, and knowledge graphs for Neo4j and Amazon Neptune. Just describe what you need in plain English, or upload your SQL schema, JSON Schema, MongoDB validator or Cypher schema. IDs match across tables and collections, totals add up, and your business rules hold on every row and every document. With 232 data types and 222 built-in generators, it has one of the largest libraries of any test data generator. **Try it free at [www.generaterealdata.com](https://www.generaterealdata.com?ref=kaggle)**, or write to support@generaterealdata.com.

A food delivery platform as a **MongoDB database**: 512,550 documents in six collections, covering 316,200 orders from January 2025 to March 2026 in six US cities (New York, Los Angeles, San Francisco, Chicago, Austin and Seattle). Customers order from 306 restaurants, couriers pick the food up and bring it to the door, and some customers leave a review. It is a real NoSQL data model, not a flat table exported as JSON: each order embeds its items with the name and price at the time of ordering, each customer embeds their saved addresses, each restaurant embeds its cuisines, and orders, menu items and reviews point to other collections by `_id`. Counting the embedded documents, the dataset holds 1,452,495 records.

## Why this dataset

- A document database to practise on: nested objects, embedded lists, optional fields and references between collections. Practise aggregation pipelines with `$unwind`, `$lookup`, `$group` and `$bucket`, or flatten the documents into tables for pandas and SQL.
- Ready to load: the `mongodb` folder has one Extended JSON file per collection, a `setup.js` that creates every collection with its JSON Schema validator (plus indexes on the reference fields and a unique index on email), and a load script for Linux, macOS and Windows. All 512,550 documents load with the validators switched on and none is rejected.
- No MongoDB needed: the `json` folder has the same data as plain JSON Lines (one document per line, ISO dates, plain numbers), plus a readable sample of each collection.
- References always resolve and the money adds up: every `customer_id`, `restaurant_id`, `courier_id`, `menu_item_id` and `order_id` points to a real document; line totals, subtotals and totals hold on every order. 23 rules are checked inside MongoDB and all hold.
- It behaves like a delivery business: orders grow through 2025 and peak over the December holidays, follow a lunch and a dinner peak, take 49.5 minutes on average from order to door, and each order's items come from its own restaurant's menu, delivered by a courier in the restaurant's city.

**Good for:** Learning MongoDB and aggregation pipelines; NoSQL data modelling (embedding against referencing); Flattening nested JSON for analysis; Testing ETL from a document store to a warehouse; Teaching schema validation; Analytics on orders, menus and reviews.

## Collections

| Collection | Documents | What it holds |
|---|---:|---|
| `restaurants` | 306 | Name, city, coordinates, cuisines (embedded list of 1 to 5), opening and closing hour, price level 1-4, average rating. |
| `restaurant_menu_items` | 7,344 | A restaurant's dishes: name, category (starter, main, dessert, drink), price, vegetarian and available flags. References `restaurants`. |
| `customers` | 59,160 | Name, unique email, phone, loyalty tier, sign-up date, optional referral code, and 1 to 3 saved addresses (embedded, each with a label, street, city, zip code and coordinates). |
| `couriers` | 2,040 | Name, city, vehicle (car, scooter, bicycle), rating, joined date, active flag. |
| `orders` | 316,200 | References to the customer, restaurant and courier; 1 to 14 embedded items (833,473 in all); placed, accepted, picked-up and delivered times; payment method with card details or wallet name; subtotal, delivery fee, tip, discount and total. |
| `reviews` | 127,500 | One per reviewed delivered order: rating 1-5 and an optional comment. References the order, its customer and its restaurant. |

The first order, as it is in `json/orders.jsonl` (fields reordered for reading):

```json
{"_id": "ORD-100001", "customer_id": "CUST-018051", "restaurant_id": "REST-1128", "courier_id": "COUR-2403",
 "status": "delivered", "platform": "android",
 "placed_at": "2025-01-06T20:29:49Z", "accepted_at": "2025-01-06T20:30:49Z",
 "picked_up_at": "2025-01-06T20:49:49Z", "delivered_at": "2025-01-06T21:01:49Z",
 "items": [{"menu_item_id": "MENU-013138", "item_name": "Craft Cola", "quantity": 2, "unit_price": 3.24, "line_total": 6.48},
           {"menu_item_id": "MENU-013127", "item_name": "Spring Rolls", "quantity": 2, "unit_price": 8.9, "line_total": 17.8}],
 "payment_method": "card", "card": {"brand": "Mastercard", "last4": "3793"},
 "subtotal": 24.28, "delivery_fee": 3.99, "tip": 1.14, "discount": 0.0, "total": 29.41}
```

## Files

- `mongodb/`: one MongoDB Extended JSON file per collection (`orders.json`, `customers.json` and so on; dates as `$date`, money as `$numberDecimal`), `setup.js` (collections with validators, and indexes), `load.sh` and `load.ps1`, `proof_queries.js` (the 23 rule checks) and `questions.js` (ten questions as aggregation pipelines).
- `json/`: one plain JSON Lines file per collection (`orders.jsonl` and so on) and one sample per collection (`sample_orders.json` and so on: the first 100 documents, indented).

To load into MongoDB: set the connection string and run the load script from the `mongodb` folder, for example `URI="mongodb://localhost:27017/food_delivery" sh load.sh` (Windows: `$env:URI = "..."; ./load.ps1`), then `mongosh "$URI" proof_queries.js`. In Python without MongoDB: `pd.read_json("orders.jsonl", lines=True)`, or read the lines with `json.loads` and flatten the lists you need.

## Rules you can rely on

23 rules were checked inside MongoDB 8 on the full dataset and all 23 hold. Each rule is an aggregation that counts the documents breaking it, and every count is 0. The queries are in `mongodb/proof_queries.js` and in the [GitHub repository](https://github.com/generaterealdata/synthetic-datasets/tree/main/food-delivery-nosql).

- Every customer email is unique
- Every reference points to a real document (8 checks: orders to customers, restaurants and couriers; order items to menu items; menu items to restaurants; reviews to orders, customers and restaurants)
- line_total = quantity x unit_price on every order item
- subtotal = the sum of the order's line totals
- total = subtotal + delivery_fee + tip - discount, never below 0
- Every ordered item is on the order's restaurant's menu, with the menu's name and price
- The courier works in the restaurant's city
- Placed before accepted, before picked up, before delivered
- A cancelled order has no delivery time; a delivered order has one
- No order is placed before the customer signed up
- No order is delivered by a courier who had not joined yet
- Card details only on card payments; a wallet name only on wallet payments; neither on cash
- A review is by the order's customer, for its restaurant, on a delivered order, written after delivery
- An order lists each dish once
- A customer uses each address label (home, work, other) once
- A restaurant lists each cuisine once

## Questions to try

1. Delivered orders and revenue per month
2. Payment methods: share of orders, average total and tip
3. Orders by hour of the day
4. Top 10 dishes by quantity sold (`$unwind` the embedded items)
5. The order life cycle: average minutes in each stage
6. Basket size: orders by number of items, with the average subtotal
7. Best-reviewed restaurants (`$lookup` for the name and city)
8. Ratings: how many of each, how many with a comment, and the most common comment
9. Repeat ordering: customers by how many orders they placed (`$bucket`)
10. Saved addresses per customer and their labels

`questions.js` answers all ten inside MongoDB, and the starter notebook answers them with pandas on the JSON Lines files, showing the pipeline next to each answer.

## Good to know

- Synthetic data generated from a design, so not everything behaves like a real platform. Many fields are drawn independently: delivery times, cancellations, tips and order totals do not change with the city, platform, courier vehicle or loyalty tier. Use the dataset to practise queries and data handling, not to estimate those effects.
- Every restaurant's menu is drawn from the same 26 dishes, whatever its cuisines, and the vegetarian flag is set per menu item rather than per dish. Each dish appears at most once on a menu and once in an order.
- `restaurants.average_rating` is a field of its own; it is not computed from the reviews.
- Review comments come from a short list of 9 phrases chosen to match the rating; 70% of reviews have one. 43.8% of delivered orders have a review.
- Timestamps end in `Z` but are the city's local time: there is no time-zone shift between cities.
- Address coordinates fall inside their city (99.1% within a tight box around it), and zip codes are valid for the city's state but not always for the city itself. Streets are made up.
- Phone numbers come in several formats, as if typed by users, and 15% of customers have none. Customer names can repeat; emails never do.
- A cancelled order keeps its courier, accepted time, items and money fields, but has no pick-up or delivery time. A discount can bring the total to 0 (110 orders).
- Ids are readable strings (`ORD-100001`, `CUST-010001`), not ObjectIds. Money is Decimal128 in the MongoDB files and a plain number in the JSON Lines files.

## How it was made

Fully synthetic: generated with [GenerateRealData](https://www.generaterealdata.com/capabilities/?ref=kaggle) in its NoSQL document mode for MongoDB, using a fixed seed. The design (collections, fields, lists, references and rules) was drafted by AI from a plain-English description of a food delivery platform; every value was then generated by the engine, which also keeps references, totals, times and the realism rules above. No field value was written by AI, no real person, restaurant or transaction is in the data, and nothing was edited after generation. The design, the validators, the rule checks, the questions and a sample of each collection are on [GitHub](https://github.com/generaterealdata/synthetic-datasets/tree/main/food-delivery-nosql).

## Licence

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Use it for anything, including commercial work; please credit "Food Delivery NoSQL Database (MongoDB), GenerateRealData" with a link to https://www.generaterealdata.com.
