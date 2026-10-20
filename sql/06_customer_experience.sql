
-- ==========================================================
-- 06_customer_experience.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Purpose:
-- Analyse delivered-order customer experience using the
-- canonical order-level rating layer.
--
-- Important:
-- CX metrics include only delivered orders with valid ratings.
-- Multiple source ratings per order were aggregated upstream
-- into one order-level average rating.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. EXECUTIVE CUSTOMER EXPERIENCE KPIs
-- ----------------------------------------------------------

SELECT

    COUNT(*) FILTER (
        WHERE completed_sales_eligible = TRUE
    ) AS delivered_commercial_orders,

    COUNT(*) FILTER (
        WHERE cx_eligible = TRUE
    ) AS cx_eligible_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE cx_eligible = TRUE
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE completed_sales_eligible = TRUE
            ),
            0
        ),
        2
    ) AS rating_coverage_pct,

    ROUND(
        AVG(
            CASE
                WHEN cx_eligible = TRUE
                THEN avg_rating
            END
        ),
        2
    ) AS avg_customer_rating,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE
                cx_eligible = TRUE
                AND avg_rating >= 4
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE cx_eligible = TRUE
            ),
            0
        ),
        2
    ) AS high_rating_order_pct

FROM fact_order
;


-- ----------------------------------------------------------
-- 2. CUSTOMER RATING DISTRIBUTION
-- ----------------------------------------------------------

WITH rating_bands AS (

    SELECT

        CASE
            WHEN avg_rating < 2
                THEN 'Below 2.0'

            WHEN avg_rating < 3
                THEN '2.0–2.9'

            WHEN avg_rating < 4
                THEN '3.0–3.9'

            ELSE '4.0–5.0'
        END AS rating_band,

        CASE
            WHEN avg_rating < 2 THEN 1
            WHEN avg_rating < 3 THEN 2
            WHEN avg_rating < 4 THEN 3
            ELSE 4
        END AS rating_band_order

    FROM fact_order

    WHERE
        cx_eligible = TRUE
)

SELECT

    rating_band,

    COUNT(*) AS orders,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS order_share_pct

FROM rating_bands

GROUP BY
    rating_band,
    rating_band_order

ORDER BY
    rating_band_order
;


-- ----------------------------------------------------------
-- 3. DARK STORE CUSTOMER EXPERIENCE
-- ----------------------------------------------------------

WITH store_cx AS (

    SELECT

        dark_store_id,
        dark_store_name,
        city,

        COUNT(*) FILTER (
            WHERE completed_sales_eligible = TRUE
        ) AS completed_orders,

        COUNT(*) FILTER (
            WHERE cx_eligible = TRUE
        ) AS rated_orders,

        AVG(
            CASE
                WHEN cx_eligible = TRUE
                THEN avg_rating
            END
        ) AS avg_rating,

        AVG(
            CASE
                WHEN cx_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS avg_delivery_minutes,

        100.0 *
        COUNT(*) FILTER (
            WHERE
                cx_eligible = TRUE
                AND derived_sla_status = 'On Time'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE cx_eligible = TRUE
            ),
            0
        ) AS rated_order_sla_pct

    FROM fact_order

    GROUP BY
        dark_store_id,
        dark_store_name,
        city
)

SELECT

    dark_store_id,
    dark_store_name,
    city,
    completed_orders,
    rated_orders,

    ROUND(
        100.0 *
        rated_orders /
        NULLIF(completed_orders, 0),
        2
    ) AS rating_coverage_pct,

    ROUND(
        avg_rating,
        2
    ) AS avg_rating,

    ROUND(
        avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes,

    ROUND(
        rated_order_sla_pct,
        2
    ) AS rated_order_sla_pct,

    RANK() OVER (
        ORDER BY avg_rating DESC
    ) AS customer_rating_rank

FROM store_cx

ORDER BY
    customer_rating_rank,
    dark_store_id
;


-- ----------------------------------------------------------
-- 4. RATING VS SLA PERFORMANCE
-- ----------------------------------------------------------

SELECT

    derived_sla_status,

    COUNT(*) AS rated_orders,

    ROUND(
        AVG(avg_rating),
        2
    ) AS avg_rating,

    ROUND(
        AVG(delivery_time_mins),
        2
    ) AS avg_delivery_minutes,

    ROUND(
        100.0 *
        COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS rated_order_share_pct

FROM fact_order

WHERE
    cx_eligible = TRUE

GROUP BY
    derived_sla_status

ORDER BY
    CASE derived_sla_status
        WHEN 'On Time' THEN 1
        WHEN 'At Risk' THEN 2
        WHEN 'Late' THEN 3
        ELSE 4
    END
;


-- ----------------------------------------------------------
-- 5. MONTHLY CUSTOMER EXPERIENCE TREND
-- ----------------------------------------------------------

WITH monthly_cx AS (

    SELECT

        DATE_TRUNC(
            'month',
            order_date
        ) AS month,

        COUNT(*) FILTER (
            WHERE cx_eligible = TRUE
        ) AS rated_orders,

        AVG(
            CASE
                WHEN cx_eligible = TRUE
                THEN avg_rating
            END
        ) AS avg_rating

    FROM fact_order

    GROUP BY 1
),

cx_trend AS (

    SELECT

        *,

        LAG(avg_rating) OVER (
            ORDER BY month
        ) AS previous_month_rating,

        AVG(avg_rating) OVER (
            ORDER BY month
            ROWS BETWEEN
                2 PRECEDING
                AND CURRENT ROW
        ) AS rolling_3m_avg_rating

    FROM monthly_cx
)

SELECT

    month,
    rated_orders,

    ROUND(
        avg_rating,
        3
    ) AS avg_rating,

    ROUND(
        avg_rating -
        previous_month_rating,
        3
    ) AS mom_rating_change,

    ROUND(
        rolling_3m_avg_rating,
        3
    ) AS rolling_3m_avg_rating

FROM cx_trend

ORDER BY month
;
