-- =====================================================================
-- 01_schema.sql  |  E-commerce DB  |  DDL: CREATE / ALTER / constraints
-- Target: PostgreSQL 14+
-- =====================================================================
DROP TABLE IF EXISTS payments    CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS categories  CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;

CREATE TABLE customers (
    customer_id  SERIAL       PRIMARY KEY,
    first_name   VARCHAR(50)  NOT NULL,
    last_name    VARCHAR(50)  NOT NULL,
    email        VARCHAR(120) NOT NULL UNIQUE,
    phone        VARCHAR(20),                       -- nullable on purpose
    city         VARCHAR(60),
    country      VARCHAR(60)  NOT NULL DEFAULT 'India',
    signup_date  DATE         NOT NULL DEFAULT CURRENT_DATE,
    referred_by  INT REFERENCES customers(customer_id)  -- self reference, nullable
);

CREATE TABLE categories (
    category_id   SERIAL      PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE products (
    product_id   SERIAL        PRIMARY KEY,
    product_name VARCHAR(100)  NOT NULL,
    category_id  INT           REFERENCES categories(category_id),  -- nullable: uncategorised
    price        NUMERIC(10,2) NOT NULL CHECK (price > 0),
    stock_qty    INT           NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    is_active    BOOLEAN       NOT NULL DEFAULT TRUE
);

CREATE TABLE orders (
    order_id     SERIAL       PRIMARY KEY,
    customer_id  INT          NOT NULL REFERENCES customers(customer_id),
    order_date   DATE         NOT NULL,
    ship_date    DATE,                               -- NULL until shipped
    status       VARCHAR(15)  NOT NULL DEFAULT 'PLACED'
                 CHECK (status IN ('PLACED','SHIPPED','DELIVERED','CANCELLED','RETURNED')),
    discount_pct NUMERIC(5,2) CHECK (discount_pct BETWEEN 0 AND 100),  -- NULL = no discount info
    CONSTRAINT chk_ship_after_order CHECK (ship_date IS NULL OR ship_date >= order_date)
);

CREATE TABLE order_items (
    order_id    INT           NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id  INT           NOT NULL REFERENCES products(product_id),
    quantity    INT           NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id   SERIAL        PRIMARY KEY,
    order_id     INT           NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    method       VARCHAR(20)   NOT NULL CHECK (method IN ('CARD','UPI','NETBANKING','COD')),
    amount       NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    paid_at      TIMESTAMP
);

-- ---------- ALTER TABLE examples ----------
ALTER TABLE customers ADD COLUMN loyalty_tier VARCHAR(10) DEFAULT 'BRONZE';
ALTER TABLE customers ADD CONSTRAINT chk_loyalty_tier
      CHECK (loyalty_tier IN ('BRONZE','SILVER','GOLD'));
ALTER TABLE products  ADD COLUMN sku VARCHAR(20);
ALTER TABLE products  ADD CONSTRAINT uq_products_sku UNIQUE (sku);
ALTER TABLE orders    ADD COLUMN shipping_city VARCHAR(60);
ALTER TABLE orders    DROP COLUMN shipping_city;
ALTER TABLE products  ALTER COLUMN is_active SET NOT NULL;
ALTER TABLE payments  RENAME COLUMN paid_at TO paid_timestamp;

-- ---------- Indexes ----------
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_items_product     ON order_items(product_id);
