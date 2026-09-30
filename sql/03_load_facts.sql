-- One row per item in an order
INSERT INTO dw.fact_order_items
  (order_id, order_item_id, customer_key, product_key, seller_key,
   purchase_date_key, delivered_date_key, order_status,
   price, freight_value, delivery_days, is_late)
SELECT oi.order_id, oi.order_item_id,
       c.customer_key, p.product_key, s.seller_key,
       TO_CHAR(o.order_purchase_timestamp::timestamp, 'YYYYMMDD')::int,
       TO_CHAR(o.order_delivered_customer_date::timestamp, 'YYYYMMDD')::int,
       o.order_status, oi.price, oi.freight_value,
       o.order_delivered_customer_date::timestamp::date
         - o.order_purchase_timestamp::timestamp::date,
       o.order_delivered_customer_date::timestamp
         > o.order_estimated_delivery_date::timestamp
FROM staging.order_items oi
JOIN staging.orders o     ON o.order_id = oi.order_id
JOIN dw.dim_customer c    ON c.customer_id = o.customer_id
JOIN dw.dim_product p     ON p.product_id = oi.product_id
JOIN dw.dim_seller s      ON s.seller_id = oi.seller_id;

-- One row per payment
INSERT INTO dw.fact_payments
  (order_id, payment_sequential, payment_type, installments, payment_value)
SELECT order_id, payment_sequential, payment_type,
       payment_installments, payment_value
FROM staging.order_payments;

-- One row per review
INSERT INTO dw.fact_reviews (review_id, order_id, review_score, review_date_key)
SELECT review_id, order_id, review_score,
       TO_CHAR(review_creation_date::timestamp, 'YYYYMMDD')::int
FROM staging.order_reviews;