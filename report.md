# E-commerce SQL Report

**Scope:** 30 customers · 27 products · 90 orders (69 completed/in-flight, excluding cancelled/returned) · ₹4,73,425 revenue.

## 1. Top products (Q27–Q31)
- Highest revenue: **Bluetooth Speaker** (35 units, ₹69,965), then Wireless Earbuds (₹42,483) and Mixer Grinder (₹41,988).
- Two products (Vintage Lamp – discontinued, Smart Watch) were never sold (Q21).
- Q30 highlights products with the highest return rate (min. 5 lines).

## 2. Customer spend (Q32–Q37)
- Top spenders: **Siddharth Patel** (₹47,068), **Vivaan Patel** (₹46,918), **Kavya Singh** (₹39,171).
- 5 customers have never ordered (Q20) – candidates for a re-engagement campaign.
- Q34 splits customers into High / Medium / Low / No-purchase segments.

## 3. Order trends (Q38–Q44)
- Busiest months by order count: **2025-06** and **2026-01** (8 orders each).
- Q41 tracks average days to ship; Q42 tracks the monthly cancellation rate.

## 4. Data quality findings
- Missing phone numbers, missing cities, uncategorised products (Q7, Q10, Q13).
- 20 orders without a payment record, mostly cancelled or unpaid (Q24).

## 5. What I learned
- **JOINs:** INNER JOIN only returns rows that match on both sides. LEFT JOIN with `WHERE ... IS NULL` finds rows with no match, for example customers who never ordered (5 customers) and products that were never sold (2 products). FULL OUTER JOIN shows unmatched rows from both tables.
- **NULL handling:** NULL is not the same as 0 or an empty string, so I used `IS NULL` instead of `= NULL`. `COALESCE` replaced missing values (phone became 'N/A', missing discount became 0), and `NULLIF` avoided divide-by-zero errors.
- **Aggregates:** `GROUP BY` groups rows, and `HAVING` filters the groups after they are counted, whereas `WHERE` filters rows before grouping. I used these for top products, customer spend and monthly trends.
- **CASE WHEN and dates:** I used CASE WHEN to make customer segments and to split weekday from weekend orders, and TO_CHAR / EXTRACT to build monthly and quarterly trends.
- **Constraints:** PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK and NOT NULL stop bad data. When I tried to insert a negative price or a duplicate email, the database rejected it with an error.
- **Hardest part:** counting revenue correctly. Because one order has many order lines, I had to use `COUNT(DISTINCT order_id)` to avoid counting an order twice, and filter out cancelled and returned orders.
