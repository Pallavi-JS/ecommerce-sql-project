# E-commerce Database

## Overview
I built a small online-shop (e-commerce) database from scratch using SQL and wrote SQL queries to answer common business questions.

**Business questions answered**
1. **Top products:** Which products sell the most units and earn the most revenue? Which categories perform best? Which products are never sold?
2. **Customer spend:** Who are the top customers? How much does each customer spend? Which customers never ordered? How do customers group into High / Medium / Low spenders?
3. **Order trends:** How do orders and revenue change month by month and quarter by quarter? Which days of the week are busiest? How many orders are cancelled or returned, and how long does shipping take?

## What the project contains
- **Database design:** 6 linked tables (customers, categories, products, orders, order_items, payments) with primary keys, foreign keys, UNIQUE, CHECK, NOT NULL and DEFAULT constraints.
- **Sample data:** 30 customers, 27 products, 90 orders, 237 order lines and 70 payments, with some NULL values and unmatched rows added on purpose so NULL handling and JOINs can be practised.
- **45 SQL queries** grouped into 9 sections, plus 5 constraint demos that are meant to fail.
- **Results and report:** the output of all queries, a findings report and my notes on what I learned.

## Tools used
- **SQL** to create the tables, load the data and write all the queries
- Neon (a free online SQL editor) to run the queries
- GitHub to store and submit the project


## Project structure
```
ecommerce-sql-project/
├── README.md
├── sql/
│   ├── 01_schema.sql       # 6 tables, PK/FK/UNIQUE/CHECK/NOT NULL/DEFAULT, ALTER TABLE, indexes
│   ├── 02_seed_data.sql    # 30 customers, 27 products, 90 orders, 237 order lines, 70 payments
│   └── 03_queries.sql      # 45 queries + 5 constraint-violation demos
├── docs/report.md          # findings and what I learned
└── results/query_output.txt  # full output of all 45 queries
```

## Database design
```
categories 1---< products 1---< order_items >---1 orders >---1 customers
                                                   |             (referred_by = self link)
                                                   +---< payments
```

## How to run
Run the SQL files in any SQL editor (I ran them in Neon). Run in this order:
1. `sql/01_schema.sql` - creates the tables
2. `sql/02_seed_data.sql` - loads the sample data
3. `sql/03_queries.sql` - run the queries one at a time

## Data notes
- 8 of 30 customers have no phone number; some have no city (NULL handling).
- 2 products have no category, 2 products were never sold, 5 customers never ordered (LEFT / FULL JOIN).
- Cancelled or unshipped orders have a NULL ship date; some orders have a NULL discount.
- Revenue = `quantity * unit_price`, excluding CANCELLED and RETURNED orders.

## Sample output

### Overall numbers (Q18)
```
 orders | gross_revenue | avg_order_value 
--------+---------------+-----------------
     69 |     473425.00 |         6861.23
(1 row)
```

### Top 5 products by revenue (Q28)
```
    product_name     | units_sold | revenue  
---------------------+------------+----------
 Bluetooth Speaker   |         35 | 69965.00
 Wireless Earbuds    |         17 | 42483.00
 Mixer Grinder       |         12 | 41988.00
 Running Jacket      |         18 | 41382.00
 Power Bank 10000mAh |         23 | 29877.00
(5 rows)
```

### Revenue by category (Q29)
```
    category    |  revenue  
----------------+-----------
 Electronics    | 160523.00
 Clothing       |  98229.00
 Home & Kitchen |  80153.00
 Sports         |  51667.00
 Books          |  43884.00
 Toys           |  27188.00
 Beauty         |  11781.00
(7 rows)
```

### Top 5 customers by total spend (Q32)
```
 customer_id |    customer     | orders | total_spend 
-------------+-----------------+--------+-------------
          22 | Siddharth Patel |      5 |    47068.00
           2 | Vivaan Patel    |      6 |    46918.00
           7 | Kavya Singh     |      5 |    39171.00
          14 | Rahul Iyer      |      5 |    38867.00
          10 | Arjun Joshi     |      3 |    33079.00
(5 rows)
```

### Customers who never placed an order (Q20, LEFT JOIN)
```
 customer_id | first_name | last_name 
-------------+------------+-----------
          26 | Harsh      | Gupta
          27 | Isha       | Singh
          28 | Kunal      | Mehta
          30 | Yash       | Joshi
          29 | Lakshmi    | Das
(5 rows)
```

### Products that were never sold (Q21, LEFT JOIN)
```
 product_id |        product_name         |  price  
------------+-----------------------------+---------
         25 | Vintage Lamp (Discontinued) | 1599.00
         27 | Smart Watch                 | 4999.00
(2 rows)
```

### Monthly orders and revenue, first 6 months (Q38)
```
  month  | orders | revenue  
---------+--------+----------
 2025-01 |      4 | 32276.00
 2025-02 |      6 | 38615.00
 2025-03 |      2 |  5843.00
 2025-04 |      6 | 29574.00
 2025-05 |      2 | 23683.00
 2025-06 |      5 | 40720.00
(6 rows)
```

### Orders by status (Q14)
```
  status   | num_orders 
-----------+------------
 DELIVERED |         55
 CANCELLED |         12
 RETURNED  |          9
 SHIPPED   |          9
 PLACED    |          5
(5 rows)
```

### Weekday vs weekend orders (Q43, CASE WHEN)
```
 day_type | orders 
----------+--------
 Weekend  |     25
 Weekday  |     65
(2 rows)
```

### NULL check: missing phone numbers (Q13)
```
 total_customers | with_phone | missing_phone 
-----------------+------------+---------------
              30 |         22 |             8
(1 row)
```

The output of all 45 queries is in `results/query_output.txt`.

## Query index
| Section | Queries | Topic |
|---|---|---|
| A | Q1-Q6 | SELECT, WHERE, ORDER BY, LIMIT/OFFSET, aliases, LIKE / IN / BETWEEN |
| B | Q7-Q13 | NULL handling (IS NULL, COALESCE, NULLIF) |
| C | Q14-Q18 | Aggregates, GROUP BY, HAVING |
| D | Q19-Q26 | INNER / LEFT / RIGHT / FULL / SELF joins |
| E | Q27-Q31 | Top products |
| F | Q32-Q37 | Customer spend |
| G | Q38-Q44 | Order trends (date functions) |
| H | Q45 | String functions |
| I | Q46-Q50 | Constraint demos (each one fails on purpose) |

## Key findings
- Total revenue is Rs 4,73,425 from 69 orders (average order value about Rs 6,861).
- Electronics earns the most revenue; Bluetooth Speaker is the top product.
- Top customer is Siddharth Patel (Rs 47,068).
- About 25% of orders were cancelled or returned.
