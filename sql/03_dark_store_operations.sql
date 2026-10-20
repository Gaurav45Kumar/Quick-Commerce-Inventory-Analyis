
-- ==========================================================
-- 03_dark_store_operations.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================


-- ----------------------------------------------------------
-- 1. DARK STORE KPI BASE
-- ----------------------------------------------------------

WITH store_kpis AS (

    SELECT

        dark_store_id,
        dark_store_name,
        city,
        state,

        COUNT(*) AS total_orders,

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

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS avg_delivery_minutes,

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN distance_km
            END
        ) AS avg_delivery_distance_km,

        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND
                derived_sla_status = 'On Time'
        ) AS on_time_orders,

        COUNT(*) FILTER (
            WHERE sla_eligible = TRUE
        ) AS sla_orders

    FROM fact_order

    GROUP BY
        dark_store_id,
        dark_store_name,
        city,
        state
)

SELECT

    *,

    ROUND(
        completed_gmv,
        2
    ) AS completed_gmv_rounded,

    ROUND(
        completed_gmv /
        NULLIF(
            completed_orders,
            0
        ),
        2
    ) AS aov,

    ROUND(
        avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes_rounded,

    ROUND(
        avg_delivery_distance_km,
        2
    ) AS avg_delivery_distance_km_rounded,

    ROUND(
        100.0 *
        on_time_orders /
        NULLIF(
            sla_orders,
            0
        ),
        2
    ) AS sla_on_time_pct

FROM store_kpis

ORDER BY completed_gmv DESC
;


-- ----------------------------------------------------------
-- 2. DARK STORE PERFORMANCE RANKING
-- ----------------------------------------------------------

WITH store_performance AS (

    SELECT

        dark_store_id,
        dark_store_name,
        city,

        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN gross_merchandise_value
                ELSE 0
            END
        ) AS completed_gmv,

        COUNT(*) FILTER (
            WHERE completed_sales_eligible = TRUE
        ) AS completed_orders,

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS avg_delivery_minutes,

        100.0 *
        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND
                derived_sla_status = 'On Time'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sla_eligible = TRUE
            ),
            0
        ) AS sla_on_time_pct

    FROM fact_order

    GROUP BY
        dark_store_id,
        dark_store_name,
        city
)

SELECT

    *,

    RANK() OVER (
        ORDER BY completed_gmv DESC
    ) AS gmv_rank,

    RANK() OVER (
        ORDER BY sla_on_time_pct DESC
    ) AS sla_rank,

    RANK() OVER (
        ORDER BY avg_delivery_minutes ASC
    ) AS delivery_speed_rank

FROM store_performance

ORDER BY gmv_rank
;


-- ----------------------------------------------------------
-- 3. STORE VS NETWORK BENCHMARK
-- ----------------------------------------------------------

WITH store_metrics AS (

    SELECT

        dark_store_id,
        dark_store_name,

        SUM(
            CASE
                WHEN completed_sales_eligible = TRUE
                THEN gross_merchandise_value
                ELSE 0
            END
        ) AS store_gmv,

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS store_delivery_minutes

    FROM fact_order

    GROUP BY
        dark_store_id,
        dark_store_name
),

benchmarked AS (

    SELECT

        *,

        AVG(store_gmv) OVER ()
            AS network_avg_store_gmv,

        AVG(store_delivery_minutes) OVER ()
            AS network_avg_delivery_minutes

    FROM store_metrics
)

SELECT

    dark_store_id,
    dark_store_name,

    ROUND(
        store_gmv,
        2
    ) AS store_gmv,

    ROUND(
        network_avg_store_gmv,
        2
    ) AS network_avg_store_gmv,

    ROUND(
        100.0 *
        (
            store_gmv -
            network_avg_store_gmv
        )
        /
        NULLIF(
            network_avg_store_gmv,
            0
        ),
        2
    ) AS gmv_vs_network_pct,

    ROUND(
        store_delivery_minutes,
        2
    ) AS store_delivery_minutes,

    ROUND(
        store_delivery_minutes -
        network_avg_delivery_minutes,
        2
    ) AS delivery_minutes_vs_network

FROM benchmarked

ORDER BY
    gmv_vs_network_pct DESC
;
