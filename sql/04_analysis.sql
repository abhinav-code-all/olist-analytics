-- Query 1: Monthly revenue and month-over-month growth
WITH monthly AS (
  SELECT d.year, d.month,
         SUM(f.price) AS revenue,
         COUNT(DISTINCT f.order_id) AS orders
  FROM dw.fact_order_items f
  JOIN dw.dim_date d ON d.date_key = f.purchase_date_key
  WHERE f.order_status = 'delivered'
    AND f.purchase_date_key BETWEEN 20170101 AND 20180831
  GROUP BY d.year, d.month
)
SELECT year, month, ROUND(revenue, 0) AS revenue, orders,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year, month))
             / LAG(revenue) OVER (ORDER BY year, month), 1) AS mom_growth_pct
FROM monthly
ORDER BY year, month;

-- Query 2: Top 3 categories per year
WITH cat AS (
  SELECT d.year, p.category_en, SUM(f.price) AS revenue
  FROM dw.fact_order_items f
  JOIN dw.dim_product p ON p.product_key = f.product_key
  JOIN dw.dim_date d    ON d.date_key = f.purchase_date_key
  WHERE f.order_status = 'delivered' AND d.year IN (2017, 2018)
  GROUP BY d.year, p.category_en
),
ranked AS (
  SELECT *, RANK() OVER (PARTITION BY year ORDER BY revenue DESC) AS rnk
  FROM cat
)
SELECT year, rnk, category_en, ROUND(revenue, 0) AS revenue
FROM ranked
WHERE rnk <= 3
ORDER BY year, rnk;

-- Query 3: Repeat customer rate
WITH per_person AS (
  SELECT c.customer_unique_id,
         COUNT(DISTINCT f.order_id) AS orders
  FROM dw.fact_order_items f
  JOIN dw.dim_customer c ON c.customer_key = f.customer_key
  WHERE f.order_status = 'delivered'
  GROUP BY c.customer_unique_id
)
SELECT COUNT(*) AS customers,
       COUNT(*) FILTER (WHERE orders > 1) AS repeat_customers,
       ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1) / COUNT(*), 1) AS repeat_pct
FROM per_person;

-- Query 4: Cohort retention
WITH orders_by_person AS (
  SELECT c.customer_unique_id, f.order_id,
         DATE_TRUNC('month', d.full_date)::date AS order_month
  FROM dw.fact_order_items f
  JOIN dw.dim_customer c ON c.customer_key = f.customer_key
  JOIN dw.dim_date d     ON d.date_key = f.purchase_date_key
  WHERE f.order_status = 'delivered'
  GROUP BY c.customer_unique_id, f.order_id, DATE_TRUNC('month', d.full_date)
),
first_month AS (
  SELECT customer_unique_id, MIN(order_month) AS cohort_month
  FROM orders_by_person
  GROUP BY customer_unique_id
),
activity AS (
  SELECT fm.cohort_month, o.customer_unique_id,
         (EXTRACT(YEAR FROM AGE(o.order_month, fm.cohort_month)) * 12
          + EXTRACT(MONTH FROM AGE(o.order_month, fm.cohort_month)))::int AS months_since
  FROM orders_by_person o
  JOIN first_month fm USING (customer_unique_id)
),
counts AS (
  SELECT cohort_month, months_since,
         COUNT(DISTINCT customer_unique_id) AS active_customers
  FROM activity
  WHERE cohort_month BETWEEN '2017-01-01' AND '2018-02-01'
    AND months_since BETWEEN 0 AND 6
  GROUP BY cohort_month, months_since
)
SELECT cohort_month, months_since, active_customers,
       ROUND(100.0 * active_customers /
             FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month
                                                 ORDER BY months_since), 2) AS retention_pct
FROM counts
ORDER BY cohort_month, months_since;