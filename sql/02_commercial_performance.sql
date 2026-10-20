
-- ==========================================================
-- 02_commercial_performance.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================


-- ----------------------------------------------------------
-- 1. EXECUTIVE COMMERCIAL KPIs
-- ----------------------------------------------------------

SELECT

    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE completed_sales_eligible = TRUE
    ) AS completed_orders,

    ROUND(
        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN gross_merchandise_value
                ELSE 0
            END
        ),
        2
    ) AS completed_gmv,

    ROUND(
        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN gross_merchandise_value
                ELSE 0
            END
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE completed_sales_eligible = TRUE
            ),
            0
        ),
        2
    ) AS completed_aov,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        /
        COUNT(*),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Returned'
        )
        /
        COUNT(*),
        2
    ) AS return_rate_pct

FROM fact_order
;


-- ----------------------------------------------------------
-- 2. MONTHLY COMMERCIAL PERFORMANCE
-- ----------------------------------------------------------

WITH monthly_sales AS (

    SELECT

        DATE_TRUNC(
            'month',
            order_date
        ) AS month,

        COUNT(*) FILTER (
            WHERE completed_sales_eligible = TRUE
        ) AS completed_orders,

        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN gross_merchandise_value
                ELSE 0
            END
        ) AS completed_gmv,

        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN total_units
                ELSE 0
            END
        ) AS units_sold

    FROM fact_order

    GROUP BY 1
),

monthly_growth AS (

    SELECT

        *,

        LAG(completed_gmv) OVER (
            ORDER BY month
        ) AS previous_month_gmv

    FROM monthly_sales
)

SELECT

    month,
    completed_orders,

    ROUND(
        completed_gmv,
        2
    ) AS completed_gmv,

    units_sold,

    ROUND(
        completed_gmv /
        NULLIF(completed_orders, 0),
        2
    ) AS aov,

    ROUND(
        100.0 *
        (
            completed_gmv -
            previous_month_gmv
        )
        /
        NULLIF(
            previous_month_gmv,
            0
        ),
        2
    ) AS mom_gmv_growth_pct

FROM monthly_growth

ORDER BY month
;


-- ----------------------------------------------------------
-- 3. CATEGORY PERFORMANCE
-- ----------------------------------------------------------

SELECT

    category,

    COUNT(
        DISTINCT order_id
    ) AS completed_orders,

    SUM(quantity)
        AS units_sold,

    ROUND(
        SUM(line_revenue),
        2
    ) AS revenue,

    ROUND(
        100.0 *
        SUM(line_revenue)
        /
        SUM(SUM(line_revenue)) OVER (),
        2
    ) AS revenue_share_pct,

    ROUND(
        SUM(line_revenue)
        /
        NULLIF(
            COUNT(DISTINCT order_id),
            0
        ),
        2
    ) AS revenue_per_order

FROM fact_order_item

WHERE
    completed_sales_eligible = TRUE

GROUP BY category

ORDER BY revenue DESC
;


-- ----------------------------------------------------------
-- 4. TOP PRODUCTS BY NETWORK REVENUE
-- ----------------------------------------------------------

SELECT

    product_id,
    product_name,
    category,
    completed_orders,
    units_sold,

    ROUND(
        revenue,
        2
    ) AS revenue,

    abc_class,

    RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank

FROM sku_network_profile

ORDER BY revenue_rank

LIMIT 50
;
