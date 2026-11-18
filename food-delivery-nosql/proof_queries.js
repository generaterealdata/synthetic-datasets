// Proof queries: every rule of this dataset checked inside MongoDB. Each line prints how many documents break
// the rule; all should print 0.
// Run after load: mongosh "mongodb://localhost:27017/food_delivery" proof_queries.js
const D = (x) => ({ $toDecimal: { $ifNull: [x, 0] } });
const off = (a, b) => ({ $gt: [{ $abs: { $subtract: [a, b] } }, NumberDecimal("0.011")] });
const count = (coll, pipeline) => {
  const r = db.getCollection(coll).aggregate([...pipeline, { $count: "n" }], { allowDiskUse: true }).toArray();
  return r.length ? r[0].n : 0;
};
const missingRef = (coll, field, to, unwind) => count(coll, [
  ...(unwind ? [{ $unwind: "$" + unwind }] : []),
  { $match: { [field]: { $exists: true } } },
  { $lookup: { from: to, localField: field, foreignField: "_id", as: "_r" } },
  { $match: { _r: { $size: 0 } } }]);

const checks = [];
const check = (name, fn) => { const t = Date.now(); const n = fn(); checks.push(n); print(`${n === 0 ? "OK " : "BAD"}  ${String(n).padStart(7)}  ${name}  (${Date.now() - t} ms)`); };

print("Documents: " + ["restaurants", "restaurant_menu_items", "customers", "couriers", "orders", "reviews"]
  .map((c) => `${c} ${db.getCollection(c).countDocuments()}`).join(", "));
print("");

// 1. Identity
check("customers: duplicate emails", () => count("customers", [{ $group: { _id: "$email", n: { $sum: 1 } } }, { $match: { n: { $gt: 1 } } }]));

// 2. Every reference points to a real document
check("orders.customer_id -> customers", () => missingRef("orders", "customer_id", "customers"));
check("orders.restaurant_id -> restaurants", () => missingRef("orders", "restaurant_id", "restaurants"));
check("orders.courier_id -> couriers", () => missingRef("orders", "courier_id", "couriers"));
check("orders.items.menu_item_id -> restaurant_menu_items", () => missingRef("orders", "items.menu_item_id", "restaurant_menu_items", "items"));
check("restaurant_menu_items.restaurant_id -> restaurants", () => missingRef("restaurant_menu_items", "restaurant_id", "restaurants"));
check("reviews.order_id -> orders", () => missingRef("reviews", "order_id", "orders"));
check("reviews.customer_id -> customers", () => missingRef("reviews", "customer_id", "customers"));
check("reviews.restaurant_id -> restaurants", () => missingRef("reviews", "restaurant_id", "restaurants"));

// 3. Money adds up
check("items: line_total = quantity x unit_price", () => count("orders", [{ $unwind: "$items" },
  { $match: { $expr: off(D("$items.line_total"), { $multiply: [D("$items.quantity"), D("$items.unit_price")] }) } }]));
check("orders: subtotal = sum of line totals", () => count("orders", [
  { $match: { $expr: off(D("$subtotal"), { $sum: { $map: { input: "$items", in: D("$$this.line_total") } } }) } }]));
check("orders: total = subtotal + delivery_fee + tip - discount (never below 0)", () => count("orders", [
  { $match: { $expr: off(D("$total"), { $max: [NumberDecimal("0"), { $subtract: [{ $add: [D("$subtotal"), D("$delivery_fee"), D("$tip")] }, D("$discount")] }] }) } }]));

// 4. Ordered items come from that restaurant's menu, at the menu's name and price
check("items: on the order's restaurant's menu, same name and price", () => count("orders", [{ $unwind: "$items" },
  { $lookup: { from: "restaurant_menu_items", localField: "items.menu_item_id", foreignField: "_id", as: "m" } }, { $unwind: "$m" },
  { $match: { $expr: { $or: [{ $ne: ["$m.restaurant_id", "$restaurant_id"] }, { $ne: ["$m.item_name", "$items.item_name"] },
                             off(D("$m.price"), D("$items.unit_price"))] } } }]));

// 5. The courier works in the restaurant's city
check("orders: courier in the restaurant's city", () => count("orders", [{ $match: { courier_id: { $exists: true } } },
  { $lookup: { from: "couriers", localField: "courier_id", foreignField: "_id", as: "c" } },
  { $lookup: { from: "restaurants", localField: "restaurant_id", foreignField: "_id", as: "r" } },
  { $match: { $expr: { $ne: [{ $first: "$c.city" }, { $first: "$r.city" }] } } }]));

// 6. Order life cycle
check("orders: placed < accepted < picked up < delivered", () => count("orders", [{ $match: { $expr: { $or: [
  { $and: [{ $gt: ["$accepted_at", null] }, { $lte: ["$accepted_at", "$placed_at"] }] },
  { $and: [{ $gt: ["$picked_up_at", null] }, { $lte: ["$picked_up_at", "$accepted_at"] }] },
  { $and: [{ $gt: ["$delivered_at", null] }, { $lte: ["$delivered_at", "$picked_up_at"] }] }] } } }]));
check("orders: cancelled with a delivery time, or delivered without one", () => count("orders", [{ $match: { $or: [
  { status: "cancelled", delivered_at: { $exists: true } }, { status: "delivered", delivered_at: { $exists: false } }] } }]));
check("orders: placed before the customer signed up", () => count("orders", [
  { $lookup: { from: "customers", localField: "customer_id", foreignField: "_id", as: "c", pipeline: [{ $project: { signup_date: 1 } }] } },
  { $match: { $expr: { $lt: ["$placed_at", { $first: "$c.signup_date" }] } } }]));
check("orders: delivered by a courier who had not joined yet", () => count("orders", [{ $match: { courier_id: { $exists: true } } },
  { $lookup: { from: "couriers", localField: "courier_id", foreignField: "_id", as: "c" } },
  { $match: { $expr: { $lt: ["$placed_at", { $first: "$c.joined_date" }] } } }]));

// 7. Payment details match the method
check("orders: card details only on card payments, wallet name only on wallet", () => count("orders", [{ $match: { $or: [
  { payment_method: "card", $or: [{ card: { $exists: false } }, { wallet_name: { $exists: true } }] },
  { payment_method: "wallet", $or: [{ wallet_name: { $exists: false } }, { card: { $exists: true } }] },
  { payment_method: "cash", $or: [{ card: { $exists: true } }, { wallet_name: { $exists: true } }] }] } }]));

// 8. Reviews belong to a delivered order of the same customer and restaurant, written after delivery
check("reviews: same customer and restaurant as the order, delivered, written after delivery", () => count("reviews", [
  { $lookup: { from: "orders", localField: "order_id", foreignField: "_id", as: "o",
               pipeline: [{ $project: { customer_id: 1, restaurant_id: 1, status: 1, delivered_at: 1 } }] } }, { $unwind: "$o" },
  { $match: { $expr: { $or: [{ $ne: ["$customer_id", "$o.customer_id"] }, { $ne: ["$restaurant_id", "$o.restaurant_id"] },
                             { $ne: ["$o.status", "delivered"] }, { $lt: ["$created_at", "$o.delivered_at"] }] } } }]));

// 9. Each dish once per order, each address label once per customer, each cuisine once per restaurant
const once = (list, key) => ({ $expr: { $ne: [{ $size: { $setUnion: [{ $map: { input: { $ifNull: [list, []] }, in: key } }, []] } },
                                                { $size: { $ifNull: [list, []] } }] } });
check("orders: a dish listed twice in one order", () => count("orders", [{ $match: once("$items", "$$this.menu_item_id") }]));
check("customers: an address label (home, work...) used twice", () => count("customers", [{ $match: once("$addresses", "$$this.label") }]));
check("restaurants: a cuisine listed twice", () => count("restaurants", [{ $match: once("$cuisines", "$$this") }]));

print("");
print(checks.every((n) => n === 0) ? `All ${checks.length} rules hold.` : `${checks.filter((n) => n).length} rule(s) broken.`);
