-- =====================================================================
-- 03_queries.sql | E-commerce report | 40 queries
-- Sections: A basics | B NULLs | C aggregates | D JOINs | E top products
--           F customer spend | G order trends | H CASE/string/date | I DDL checks
-- "Revenue" = quantity * unit_price on orders NOT cancelled/returned,
-- unless a query says otherwise.
-- =====================================================================

-- ############ A. SELECT / WHERE / ORDER BY / LIMIT / ALIASES ############
-- Q1: All customers, alphabetical by last name
SELECT customer_id, first_name || ' ' || last_name AS full_name, email, city
FROM customers ORDER BY last_name, first_name;

-- Q2: 5 most expensive products
SELECT product_name, price FROM products ORDER BY price DESC LIMIT 5;

-- Q3: Active products priced between 500 and 1500
SELECT product_name, price FROM products
WHERE is_active AND price BETWEEN 500 AND 1500 ORDER BY price;

-- Q4: Customers from Bengaluru, Mumbai or Delhi
SELECT first_name, last_name, city FROM customers
WHERE city IN ('Bengaluru','Mumbai','Delhi') ORDER BY city;

-- Q5: Products whose name contains 'Book' or starts with 'S'
SELECT product_name FROM products
WHERE product_name ILIKE '%book%' OR product_name LIKE 'S%';

-- Q6: Delivered orders in 2025, newest first (page 2 of 10 per page)
SELECT order_id, customer_id, order_date FROM orders
WHERE status = 'DELIVERED' AND order_date >= DATE '2025-01-01' AND order_date < DATE '2026-01-01'
ORDER BY order_date DESC LIMIT 10 OFFSET 10;

-- ############ B. NULL HANDLING: COALESCE / NULLIF / IS NULL ############
-- Q7: Customers with no phone number
SELECT customer_id, first_name, last_name FROM customers WHERE phone IS NULL;

-- Q8: Show phone or 'N/A'
SELECT first_name, COALESCE(phone, 'N/A') AS phone_display FROM customers ORDER BY customer_id;

-- Q9: Orders with unknown discount treated as 0
SELECT order_id, COALESCE(discount_pct, 0) AS discount_pct FROM orders ORDER BY order_id LIMIT 15;

-- Q10: Uncategorised products (category_id IS NULL)
SELECT product_id, product_name FROM products WHERE category_id IS NULL;

-- Q11: NULLIF avoids divide-by-zero: average price per unit of stock
SELECT product_name, ROUND(price / NULLIF(stock_qty, 0), 2) AS price_per_stock_unit FROM products
ORDER BY price_per_stock_unit NULLS LAST;

-- Q12: Orders not yet shipped (ship_date NULL) and their status
SELECT status, COUNT(*) AS orders_without_ship_date FROM orders
WHERE ship_date IS NULL GROUP BY status;

-- Q13: COUNT(*) vs COUNT(col) shows how many NULLs exist
SELECT COUNT(*) AS total_customers, COUNT(phone) AS with_phone, COUNT(*) - COUNT(phone) AS missing_phone,
       COUNT(city) AS with_city FROM customers;

-- ############ C. AGGREGATES: COUNT/SUM/AVG + GROUP BY + HAVING ############
-- Q14: Orders per status
SELECT status, COUNT(*) AS num_orders FROM orders GROUP BY status ORDER BY num_orders DESC;

-- Q15: Products and average price per category (join for names)
SELECT c.category_name, COUNT(*) AS products, ROUND(AVG(p.price),2) AS avg_price,
       MIN(p.price) AS min_price, MAX(p.price) AS max_price
FROM products p JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name ORDER BY avg_price DESC;

-- Q16: Customers per city (HAVING: only cities with 3+ customers)
SELECT city, COUNT(*) AS customers FROM customers WHERE city IS NOT NULL
GROUP BY city HAVING COUNT(*) >= 3 ORDER BY customers DESC;

-- Q17: Total revenue per payment method
SELECT method, COUNT(*) AS payments, SUM(amount) AS total_collected FROM payments
GROUP BY method ORDER BY total_collected DESC;

-- Q18: Overall KPIs (revenue, orders, average order value) excluding cancelled/returned
SELECT COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity * oi.unit_price) AS gross_revenue,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED');

-- ############ D. JOINS: INNER / LEFT / RIGHT / FULL OUTER ############
-- Q19: INNER JOIN - order lines with customer and product names
SELECT o.order_id, c.first_name, p.product_name, oi.quantity, oi.unit_price
FROM orders o
JOIN customers   c  ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products    p  ON p.product_id  = oi.product_id
ORDER BY o.order_id LIMIT 20;

-- Q20: LEFT JOIN - customers who NEVER placed an order
SELECT c.customer_id, c.first_name, c.last_name, c.signup_date
FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Q21: LEFT JOIN - products never sold
SELECT p.product_id, p.product_name, p.price
FROM products p LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.order_id IS NULL;

-- Q22: RIGHT JOIN - every category, even with no products (same result via LEFT is preferred style)
SELECT c.category_name, COUNT(p.product_id) AS products
FROM products p RIGHT JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name ORDER BY products DESC;

-- Q23: FULL OUTER JOIN - products vs categories: find orphans on either side
SELECT c.category_name, p.product_name
FROM categories c FULL OUTER JOIN products p ON p.category_id = c.category_id
WHERE c.category_id IS NULL OR p.product_id IS NULL;

-- Q24: LEFT JOIN - orders without a payment record
SELECT o.order_id, o.status, o.order_date
FROM orders o LEFT JOIN payments pay ON pay.order_id = o.order_id
WHERE pay.payment_id IS NULL ORDER BY o.order_id;

-- Q25: SELF JOIN - who referred whom
SELECT c.first_name || ' ' || c.last_name AS customer,
       r.first_name || ' ' || r.last_name AS referred_by
FROM customers c JOIN customers r ON r.customer_id = c.referred_by;

-- Q26: Payment amount vs computed order total (reconciliation)
SELECT o.order_id, pay.amount AS paid, SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN payments pay   ON pay.order_id = o.order_id
GROUP BY o.order_id, pay.amount HAVING pay.amount <> SUM(oi.quantity * oi.unit_price);

-- ############ E. TOP PRODUCTS ############
-- Q27: Top 10 products by units sold
SELECT p.product_name, SUM(oi.quantity) AS units_sold
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY p.product_name ORDER BY units_sold DESC, p.product_name LIMIT 10;

-- Q28: Top 10 products by revenue
SELECT p.product_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY p.product_name ORDER BY revenue DESC LIMIT 10;

-- Q29: Best-selling product per category is Week 5 (window fns); here: revenue per category
SELECT COALESCE(c.category_name, 'Uncategorised') AS category, SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
LEFT JOIN categories c ON c.category_id = p.category_id
JOIN orders o ON o.order_id = oi.order_id WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY c.category_name ORDER BY revenue DESC;

-- Q30: Products with highest return rate (returned lines / all lines), min 5 lines
SELECT p.product_name, COUNT(*) AS lines,
       SUM(CASE WHEN o.status = 'RETURNED' THEN 1 ELSE 0 END) AS returned_lines,
       ROUND(100.0 * SUM(CASE WHEN o.status = 'RETURNED' THEN 1 ELSE 0 END) / COUNT(*), 1) AS return_pct
FROM order_items oi JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON o.order_id = oi.order_id
GROUP BY p.product_name HAVING COUNT(*) >= 5 ORDER BY return_pct DESC, lines DESC LIMIT 10;

-- Q31: Low-stock active products that still sell (stock < 50)
SELECT p.product_name, p.stock_qty, COALESCE(SUM(oi.quantity),0) AS units_sold
FROM products p LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE p.is_active AND p.stock_qty < 50 GROUP BY p.product_id, p.product_name, p.stock_qty
ORDER BY p.stock_qty;

-- ############ F. CUSTOMER SPEND ############
-- Q32: Top 10 customers by total spend
SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer,
       COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity * oi.unit_price) AS total_spend
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY c.customer_id, customer ORDER BY total_spend DESC LIMIT 10;

-- Q33: Spend after order-level discount (NULL discount = 0)
SELECT c.first_name || ' ' || c.last_name AS customer,
       ROUND(SUM(oi.quantity * oi.unit_price * (1 - COALESCE(o.discount_pct,0)/100.0)),2) AS net_spend
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY c.customer_id, customer ORDER BY net_spend DESC LIMIT 10;

-- Q34: Customer segments by spend (CASE WHEN)
SELECT segment, COUNT(*) AS customers FROM (
  SELECT c.customer_id,
         CASE WHEN COALESCE(SUM(oi.quantity*oi.unit_price),0) >= 15000 THEN 'High'
              WHEN COALESCE(SUM(oi.quantity*oi.unit_price),0) >=  5000 THEN 'Medium'
              WHEN COALESCE(SUM(oi.quantity*oi.unit_price),0) >     0   THEN 'Low'
              ELSE 'No purchases' END AS segment
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status NOT IN ('CANCELLED','RETURNED')
  LEFT JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY c.customer_id) s
GROUP BY segment ORDER BY customers DESC;

-- Q35: Repeat customers (2+ orders) and average gap information
SELECT c.customer_id, c.first_name, COUNT(*) AS orders,
       MIN(o.order_date) AS first_order, MAX(o.order_date) AS last_order
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name HAVING COUNT(*) >= 2 ORDER BY orders DESC, c.customer_id;

-- Q36: Spend by city (unknown city labelled)
SELECT COALESCE(c.city,'Unknown') AS city, COUNT(DISTINCT c.customer_id) AS buyers,
       SUM(oi.quantity*oi.unit_price) AS revenue
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY COALESCE(c.city,'Unknown') ORDER BY revenue DESC;

-- Q37: Spend by loyalty tier
SELECT c.loyalty_tier, COUNT(DISTINCT c.customer_id) AS customers,
       ROUND(SUM(oi.quantity*oi.unit_price)/COUNT(DISTINCT c.customer_id),2) AS revenue_per_customer
FROM customers c JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY c.loyalty_tier ORDER BY revenue_per_customer DESC;

-- ############ G. ORDER TRENDS (date/time functions) ############
-- Q38: Monthly orders and revenue
SELECT TO_CHAR(o.order_date,'YYYY-MM') AS month, COUNT(DISTINCT o.order_id) AS orders,
       SUM(oi.quantity*oi.unit_price) AS revenue
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY TO_CHAR(o.order_date,'YYYY-MM') ORDER BY month;

-- Q39: Orders by day of week
SELECT TO_CHAR(order_date,'Dy') AS weekday, EXTRACT(ISODOW FROM order_date) AS dow_no, COUNT(*) AS orders
FROM orders GROUP BY 1, 2 ORDER BY dow_no;

-- Q40: Quarterly revenue
SELECT EXTRACT(YEAR FROM o.order_date) AS yr, EXTRACT(QUARTER FROM o.order_date) AS qtr,
       SUM(oi.quantity*oi.unit_price) AS revenue
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status NOT IN ('CANCELLED','RETURNED')
GROUP BY 1, 2 ORDER BY 1, 2;

-- Q41: Average days from order to shipment, by month
SELECT DATE_TRUNC('month', order_date)::date AS month,
       ROUND(AVG(ship_date - order_date),2) AS avg_days_to_ship
FROM orders WHERE ship_date IS NOT NULL GROUP BY 1 ORDER BY 1;

-- Q42: Cancellation rate by month
SELECT TO_CHAR(order_date,'YYYY-MM') AS month, COUNT(*) AS orders,
       SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END) AS cancelled,
       ROUND(100.0*SUM(CASE WHEN status='CANCELLED' THEN 1 ELSE 0 END)/COUNT(*),1) AS cancel_pct
FROM orders GROUP BY 1 ORDER BY 1;

-- Q43: Weekend vs weekday orders (CASE + date function)
SELECT CASE WHEN EXTRACT(ISODOW FROM order_date) IN (6,7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
       COUNT(*) AS orders FROM orders GROUP BY 1;

-- Q44: Orders in the last 90 days of data (relative to max order date)
SELECT COUNT(*) AS recent_orders FROM orders
WHERE order_date >= (SELECT MAX(order_date) FROM orders) - INTERVAL '90 days';

-- ############ H. STRING FUNCTIONS ############
-- Q45: Email domain, upper-case name, name length
SELECT UPPER(first_name) AS first_upper, LENGTH(email) AS email_len,
       SPLIT_PART(email,'@',2) AS domain, LEFT(last_name,3) AS short_last
FROM customers LIMIT 10;

-- ############ I. DDL / CONSTRAINT DEMOS (each should FAIL - that is the point) ############
-- Run these one by one; each raises an error proving the constraint works.
-- Q46: CHECK violation (price must be > 0)
-- INSERT INTO products(product_name, price) VALUES ('Bad Product', -5);
-- Q47: UNIQUE violation (email)
-- INSERT INTO customers(first_name,last_name,email) VALUES ('A','B','aarav.sharma1@example.com');
-- Q48: FK violation (customer 9999 does not exist)
-- INSERT INTO orders(customer_id, order_date) VALUES (9999, CURRENT_DATE);
-- Q49: NOT NULL violation
-- INSERT INTO customers(first_name,last_name,email) VALUES (NULL,'B','x@y.com');
-- Q50: Table-level CHECK (ship_date before order_date)
-- INSERT INTO orders(customer_id, order_date, ship_date) VALUES (1, '2025-05-10', '2025-05-01');
