CREATE TABLE dw.dim_date (
  date_key INT PRIMARY KEY,
  full_date DATE NOT NULL,
  year INT, quarter INT, month INT, month_name TEXT,
  day INT, day_of_week INT, is_weekend BOOLEAN
);

CREATE TABLE dw.dim_customer (
  customer_key SERIAL PRIMARY KEY,
  customer_id TEXT UNIQUE NOT NULL,
  customer_unique_id TEXT NOT NULL,
  zip_prefix TEXT, city TEXT, state TEXT
);

CREATE TABLE dw.dim_product (
  product_key SERIAL PRIMARY KEY,
  product_id TEXT UNIQUE NOT NULL,
  category_pt TEXT, category_en TEXT,
  weight_g NUMERIC, length_cm NUMERIC,
  height_cm NUMERIC, width_cm NUMERIC, photos_qty NUMERIC
);

CREATE TABLE dw.dim_seller (
  seller_key SERIAL PRIMARY KEY,
  seller_id TEXT UNIQUE NOT NULL,
  zip_prefix TEXT, city TEXT, state TEXT
);

CREATE TABLE dw.fact_order_items (
  order_item_key SERIAL PRIMARY KEY,
  order_id TEXT NOT NULL,
  order_item_id INT NOT NULL,
  customer_key INT REFERENCES dw.dim_customer,
  product_key INT REFERENCES dw.dim_product,
  seller_key INT REFERENCES dw.dim_seller,
  purchase_date_key INT REFERENCES dw.dim_date,
  delivered_date_key INT REFERENCES dw.dim_date,
  order_status TEXT,
  price NUMERIC(10,2), freight_value NUMERIC(10,2),
  delivery_days INT, is_late BOOLEAN
);

CREATE TABLE dw.fact_payments (
  payment_key SERIAL PRIMARY KEY,
  order_id TEXT NOT NULL,
  payment_sequential INT,
  payment_type TEXT,
  installments INT,
  payment_value NUMERIC(10,2)
);

CREATE TABLE dw.fact_reviews (
  review_key SERIAL PRIMARY KEY,
  review_id TEXT NOT NULL,
  order_id TEXT NOT NULL,
  review_score INT,
  review_date_key INT REFERENCES dw.dim_date
);