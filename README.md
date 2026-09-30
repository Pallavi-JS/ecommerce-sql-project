# E-commerce Database – SQL Mini Project (Week 4)

Analysis of an e-commerce database: **top products, customer spend, order trends**.
Covers Week 4 SQL topics: SELECT/WHERE/ORDER BY/LIMIT, aliases, NULL handling (COALESCE, NULLIF, IS NULL),
aggregates + GROUP BY/HAVING, all JOIN types, CASE WHEN, string & date functions, DDL (CREATE/ALTER/constraints).

## Folder structure
```
ecommerce-sql-project/
├── README.md
├── sql/
│   ├── 01_schema.sql       # 6 tables, PK/FK/UNIQUE/CHECK/NOT NULL/DEFAULT, ALTER TABLE, indexes
│   ├── 02_seed_data.sql    # 30 customers, 27 products, 90 orders, 237 order lines, 70 payments
│   └── 03_queries.sql      # 45 queries + 5 constraint-violation demos
├── docs/
│   └── report.md           # findings and observations
└── results/query_output.txt  # saved output of all queries
```

## ER diagram
```
categories 1───< products 1───< order_items >───1 orders >───1 customers
                                                   │              └─ referred_by (self FK)
                                                   └───< payments
```

## How to run (PostgreSQL)
Tested on PostgreSQL 16 and Neon (neon.tech, free online PostgreSQL). Open the SQL Editor and run the files in this order:
1. `sql/01_schema.sql` - creates the tables
2. `sql/02_seed_data.sql` - loads the sample data
3. `sql/03_queries.sql` - run the queries one at a time

## Data notes (intentional, to practise NULLs and JOINs)
- ~25% customers have no phone; some have no city → `IS NULL`, `COALESCE`
- 2 products have no category; 2 products were never sold; 5 customers never ordered → LEFT/FULL JOIN
- Unshipped/cancelled orders have NULL `ship_date`; some orders have NULL `discount_pct`
- 20 orders have no payment row (cancelled + unpaid)
- Revenue = `quantity * unit_price`, excluding CANCELLED and RETURNED orders

## Query index
| Section | Queries | Topic |
|---|---|---|
| A | Q1–Q6 | SELECT, WHERE, ORDER BY, LIMIT/OFFSET, aliases, LIKE/IN/BETWEEN |
| B | Q7–Q13 | NULL handling |
| C | Q14–Q18 | Aggregates, GROUP BY, HAVING |
| D | Q19–Q26 | INNER/LEFT/RIGHT/FULL/SELF joins |
| E | Q27–Q31 | **Top products** |
| F | Q32–Q37 | **Customer spend** |
| G | Q38–Q44 | **Order trends** |
| H | Q45 | String functions |
| I | Q46–Q50 | DDL constraint demos (commented out; each should fail) |
