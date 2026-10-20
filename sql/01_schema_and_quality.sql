
-- ==========================================================
-- 01_schema_and_quality.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Purpose:
-- Validate core warehouse dimensions, fact relationships,
-- analytical eligibility and data-quality flags.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. TABLE ROW COUNTS
-- ----------------------------------------------------------

SELECT
    'dim_customer' AS table_name,
    COUNT(*) AS row_count
FROM dim_customer

UNION ALL

SELECT
    'dim_product',
    COUNT(*)
FROM dim_product

UNION ALL

SELECT
    'dim_date',
    COUNT(*)
FROM dim_date

UNION ALL

SELECT
    'dim_dark_store',
    COUNT(*)
FROM dim_dark_store

UNION ALL

SELECT
    'fact_order',
    COUNT(*)
FROM fact_order

UNION ALL

SELECT
    'fact_order_item',
    COUNT(*)
FROM fact_order_item

UNION ALL

SELECT
    'weekly_store_category',
    COUNT(*)
FROM weekly_store_category

UNION ALL

SELECT
    'inventory_intelligence',
    COUNT(*)
FROM inventory_intelligence
;


-- ----------------------------------------------------------
-- 2. ORDER-LEVEL DATA QUALITY PROFILE
-- ----------------------------------------------------------

SELECT
    data_quality_flag,
    COUNT(*) AS orders,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM fact_order

GROUP BY
    data_quality_flag

ORDER BY
    orders DESC
;


-- ----------------------------------------------------------
-- 3. ANALYTICAL ELIGIBILITY
-- ----------------------------------------------------------

SELECT

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE commercial_eligible = TRUE
    ) AS commercial_eligible_orders,

    COUNT(*) FILTER (
        WHERE completed_sales_eligible = TRUE
    ) AS completed_sales_orders,

    COUNT(*) FILTER (
        WHERE cx_eligible = TRUE
    ) AS customer_experience_orders,

    COUNT(*) FILTER (
        WHERE sla_eligible = TRUE
    ) AS sla_eligible_orders

FROM fact_order
;


-- ----------------------------------------------------------
-- 4. REFERENTIAL INTEGRITY
-- ----------------------------------------------------------

WITH integrity_checks AS (

    SELECT
        'fact_order → dim_customer' AS relationship,
        COUNT(*) FILTER (
            WHERE c.customer_id IS NULL
        ) AS orphan_records

    FROM fact_order o

    LEFT JOIN dim_customer c
        ON o.customer_id = c.customer_id


    UNION ALL


    SELECT
        'fact_order → dim_dark_store',
        COUNT(*) FILTER (
            WHERE d.dark_store_id IS NULL
        )

    FROM fact_order o

    LEFT JOIN dim_dark_store d
        ON o.dark_store_id = d.dark_store_id


    UNION ALL


    SELECT
        'fact_order_item → fact_order',
        COUNT(*) FILTER (
            WHERE o.order_id IS NULL
        )

    FROM fact_order_item i

    LEFT JOIN fact_order o
        ON i.order_id = o.order_id


    UNION ALL


    SELECT
        'fact_order_item → dim_product',
        COUNT(*) FILTER (
            WHERE p.product_id IS NULL
        )

    FROM fact_order_item i

    LEFT JOIN dim_product p
        ON i.product_id = p.product_id

)

SELECT *
FROM integrity_checks
ORDER BY relationship
;
