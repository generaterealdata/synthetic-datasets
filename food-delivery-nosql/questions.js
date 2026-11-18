// Ten questions answered inside MongoDB with aggregation pipelines.
// Run after load: mongosh "mongodb://localhost:27017/food_delivery" questions.js
// The starter notebook on Kaggle answers the same ten questions with pandas on the JSON Lines files.
const D = (x) => ({ $toDouble: { $ifNull: [x, 0] } });
const minutes = (a, b) => ({ $divide: [{ $subtract: [b, a] }, 60000] });
const ask = (n, title, coll, pipeline) => {
  print(`\n${n}. ${title}`);
  db.getCollection(coll).aggregate(pipeline, { allowDiskUse: true }).forEach((d) => print("   " + JSON.stringify(d)));
};

ask(1, "Delivered orders and revenue per month", "orders", [
  { $match: { status: "delivered" } },
  { $group: { _id: { $dateToString: { format: "%Y-%m", date: "$placed_at" } }, orders: { $sum: 1 }, revenue: { $sum: D("$total") } } },
  { $sort: { _id: 1 } },
  { $project: { orders: 1, revenue: { $round: ["$revenue", 2] } } }]);

ask(2, "Payment methods: share of orders, average total and tip", "orders", [
  { $group: { _id: "$payment_method", orders: { $sum: 1 }, avg_total: { $avg: D("$total") }, avg_tip: { $avg: { $toDouble: "$tip" } } } },
  { $sort: { orders: -1 } },
  { $project: { orders: 1, avg_total: { $round: ["$avg_total", 2] }, avg_tip: { $round: ["$avg_tip", 2] } } }]);

ask(3, "Orders by hour of the day (lunch and dinner peaks)", "orders", [
  { $group: { _id: { $hour: "$placed_at" }, orders: { $sum: 1 } } },
  { $sort: { _id: 1 } }]);

ask(4, "Top 10 dishes by quantity sold (items are embedded in each order)", "orders", [
  { $match: { status: "delivered" } },
  { $unwind: "$items" },
  { $group: { _id: "$items.item_name", quantity: { $sum: "$items.quantity" }, revenue: { $sum: D("$items.line_total") } } },
  { $sort: { quantity: -1, _id: 1 } }, { $limit: 10 },
  { $project: { quantity: 1, revenue: { $round: ["$revenue", 2] } } }]);

ask(5, "The order life cycle: average minutes in each stage", "orders", [
  { $match: { status: "delivered" } },
  { $group: { _id: null, orders: { $sum: 1 }, to_accept: { $avg: minutes("$placed_at", "$accepted_at") },
              to_pick_up: { $avg: minutes("$accepted_at", "$picked_up_at") }, to_door: { $avg: minutes("$picked_up_at", "$delivered_at") },
              total: { $avg: minutes("$placed_at", "$delivered_at") } } },
  { $project: { _id: 0, orders: 1, to_accept: { $round: ["$to_accept", 1] }, to_pick_up: { $round: ["$to_pick_up", 1] },
                to_door: { $round: ["$to_door", 1] }, total: { $round: ["$total", 1] } } }]);

ask(6, "Basket size: orders by number of items, with the average subtotal", "orders", [
  { $group: { _id: { $size: "$items" }, orders: { $sum: 1 }, subtotal: { $avg: D("$subtotal") } } },
  { $sort: { _id: 1 } },
  { $project: { orders: 1, avg_subtotal: { $round: ["$subtotal", 2] } } }]);

ask(7, "Best-reviewed restaurants (at least 300 reviews, joined with $lookup)", "reviews", [
  { $group: { _id: "$restaurant_id", reviews: { $sum: 1 }, rating: { $avg: "$rating" } } },
  { $match: { reviews: { $gte: 300 } } },
  { $sort: { rating: -1, _id: 1 } }, { $limit: 10 },
  { $lookup: { from: "restaurants", localField: "_id", foreignField: "_id", as: "r" } },
  { $project: { name: { $first: "$r.name" }, city: { $first: "$r.city" }, reviews: 1, rating: { $round: ["$rating", 2] } } }]);

ask(8, "Ratings: how many of each, how many with a comment, and the most common comment", "reviews", [
  { $group: { _id: { rating: "$rating", comment: "$comment" }, n: { $sum: 1 } } },
  { $sort: { n: -1 } },
  { $group: { _id: "$_id.rating", reviews: { $sum: "$n" },
              with_comment: { $sum: { $cond: [{ $gt: ["$_id.comment", null] }, "$n", 0] } },
              comments: { $push: "$_id.comment" } } },
  { $project: { reviews: 1, with_comment: 1,
                top_comment: { $first: { $filter: { input: "$comments", cond: { $gt: ["$$this", null] } } } } } },
  { $sort: { _id: 1 } }]);

ask(9, "Repeat ordering: customers by how many orders they placed", "orders", [
  { $group: { _id: "$customer_id", orders: { $sum: 1 } } },
  { $bucket: { groupBy: "$orders", boundaries: [1, 2, 3, 6, 11, 21, 51, 1000], default: "other",
               output: { customers: { $sum: 1 }, orders: { $sum: "$orders" } } } }]);

ask(10, "Saved addresses per customer (an embedded list) and their labels", "customers", [
  { $unwind: "$addresses" },
  { $group: { _id: "$addresses.label", addresses: { $sum: 1 }, customers: { $addToSet: "$_id" } } },
  { $project: { addresses: 1, customers: { $size: "$customers" } } },
  { $sort: { addresses: -1 } }]);
