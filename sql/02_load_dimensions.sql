-- Calendar: every day from 2016 to 2018
INSERT INTO dw.dim_date (date_key, full_date, year, quarter, month,
                         month_name, day, day_of_week, is_weekend)
SELECT TO_CHAR(d,'YYYYMMDD')::int, d::date,
       EXTRACT(YEAR FROM d)::int, EXTRACT(QUARTER FROM d)::int,
       EXTRACT(MONTH FROM d)::int, TO_CHAR(d,'FMMonth'),
       EXTRACT(DAY FROM d)::int, EXTRACT(ISODOW FROM d)::int,
       EXTRACT(ISODOW FROM d) IN (6,7)
FROM generate_series('2016-01-01'::date, '2018-12-31'::date, '1 day') d;

-- Customers (zip codes lost their leading zeros in the CSV, so pad to 5)
INSERT INTO dw.dim_customer (customer_id, customer_unique_id, zip_prefix, city, state)
SELECT customer_id, customer_unique_id,
       LPAD(customer_zip_code_prefix::text, 5, '0'),
       customer_city, customer_state
FROM staging.customers;

-- Sellers
INSERT INTO dw.dim_seller (seller_id, zip_prefix, city, state)
SELECT seller_id, LPAD(seller_zip_code_prefix::text, 5, '0'),
       seller_city, seller_state
FROM staging.sellers;

-- Products (English category name; missing category becomes 'unknown')
INSERT INTO dw.dim_product (product_id, category_pt, category_en, weight_g,
                            length_cm, height_cm, width_cm, photos_qty)
SELECT p.product_id,
       COALESCE(p.product_category_name, 'unknown'),
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown'),
       p.product_weight_g, p.product_length_cm, p.product_height_cm,
       p.product_width_cm, p.product_photos_qty
FROM staging.products p
LEFT JOIN staging.product_category_name_translation t
       ON t.product_category_name = p.product_category_name;