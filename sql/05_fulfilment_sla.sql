
-- ==========================================================
-- 05_fulfilment_sla.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Purpose:
-- Analyse delivery speed, SLA attainment, distance effects
-- and fulfilment trends across the modelled network.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. EXECUTIVE SLA KPIs
-- ----------------------------------------------------------

SELECT

    COUNT(*) FILTER (
        WHERE sla_eligible = TRUE
    ) AS sla_eligible_orders,

    COUNT(*) FILTER (
        WHERE
            sla_eligible = TRUE
            AND derived_sla_status = 'On Time'
    ) AS on_time_orders,

    COUNT(*) FILTER (
        WHERE
            sla_eligible = TRUE
            AND derived_sla_status = 'At Risk'
    ) AS at_risk_orders,

    COUNT(*) FILTER (
        WHERE
            sla_eligible = TRUE
            AND derived_sla_status = 'Late'
    ) AS late_orders,

    ROUND(
        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ),
        2
    ) AS avg_delivery_minutes,

    ROUND(
        MEDIAN(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ),
        2
    ) AS median_delivery_minutes,

    ROUND(
        QUANTILE_CONT(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END,
            0.90
        ),
        2
    ) AS p90_delivery_minutes,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND derived_sla_status = 'On Time'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sla_eligible = TRUE
            ),
            0
        ),
        2
    ) AS sla_on_time_pct

FROM fact_order
;


-- ----------------------------------------------------------
-- 2. MONTHLY SLA TREND
-- ----------------------------------------------------------

WITH monthly_sla AS (

    SELECT

        DATE_TRUNC(
            'month',
            order_date
        ) AS month,

        COUNT(*) FILTER (
            WHERE sla_eligible = TRUE
        ) AS sla_orders,

        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND derived_sla_status = 'On Time'
        ) AS on_time_orders,

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS avg_delivery_minutes,

        QUANTILE_CONT(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END,
            0.90
        ) AS p90_delivery_minutes

    FROM fact_order

    GROUP BY 1
),

monthly_metrics AS (

    SELECT

        *,

        100.0 *
        on_time_orders /
        NULLIF(
            sla_orders,
            0
        ) AS sla_on_time_pct

    FROM monthly_sla
),

trend AS (

    SELECT

        *,

        LAG(
            sla_on_time_pct
        ) OVER (
            ORDER BY month
        ) AS previous_month_sla

    FROM monthly_metrics
)

SELECT

    month,
    sla_orders,

    ROUND(
        avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes,

    ROUND(
        p90_delivery_minutes,
        2
    ) AS p90_delivery_minutes,

    ROUND(
        sla_on_time_pct,
        2
    ) AS sla_on_time_pct,

    ROUND(
        sla_on_time_pct -
        previous_month_sla,
        2
    ) AS mom_sla_change_pp

FROM trend

ORDER BY month
;


-- ----------------------------------------------------------
-- 3. DELIVERY DISTANCE BANDS
-- ----------------------------------------------------------

WITH distance_bands AS (

    SELECT

        CASE

            WHEN distance_km <= 3
                THEN '0–3 km'

            WHEN distance_km <= 5
                THEN '3–5 km'

            WHEN distance_km <= 7
                THEN '5–7 km'

            ELSE '7+ km'

        END AS distance_band,

        CASE

            WHEN distance_km <= 3 THEN 1
            WHEN distance_km <= 5 THEN 2
            WHEN distance_km <= 7 THEN 3
            ELSE 4

        END AS distance_band_order,

        delivery_time_mins,
        derived_sla_status

    FROM fact_order

    WHERE sla_eligible = TRUE
)

SELECT

    distance_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(delivery_time_mins),
        2
    ) AS avg_delivery_minutes,

    ROUND(
        MEDIAN(delivery_time_mins),
        2
    ) AS median_delivery_minutes,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE derived_sla_status = 'On Time'
        )
        /
        COUNT(*),
        2
    ) AS sla_on_time_pct

FROM distance_bands

GROUP BY
    distance_band,
    distance_band_order

ORDER BY
    distance_band_order
;


-- ----------------------------------------------------------
-- 4. DARK STORE SLA RANKING
-- ----------------------------------------------------------

WITH store_sla AS (

    SELECT

        dark_store_id,
        dark_store_name,
        city,

        COUNT(*) FILTER (
            WHERE sla_eligible = TRUE
        ) AS sla_orders,

        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ) AS avg_delivery_minutes,

        QUANTILE_CONT(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END,
            0.90
        ) AS p90_delivery_minutes,

        100.0 *
        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND derived_sla_status = 'On Time'
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

    dark_store_id,
    dark_store_name,
    city,
    sla_orders,

    ROUND(
        avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes,

    ROUND(
        p90_delivery_minutes,
        2
    ) AS p90_delivery_minutes,

    ROUND(
        sla_on_time_pct,
        2
    ) AS sla_on_time_pct,

    RANK() OVER (
        ORDER BY
            sla_on_time_pct DESC
    ) AS sla_rank,

    RANK() OVER (
        ORDER BY
            p90_delivery_minutes ASC
    ) AS p90_speed_rank

FROM store_sla

ORDER BY sla_rank
;


-- ----------------------------------------------------------
-- 5. CITY FULFILMENT PERFORMANCE
-- ----------------------------------------------------------

SELECT

    city,
    state,

    COUNT(*) FILTER (
        WHERE sla_eligible = TRUE
    ) AS sla_orders,

    ROUND(
        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN delivery_time_mins
            END
        ),
        2
    ) AS avg_delivery_minutes,

    ROUND(
        AVG(
            CASE
                WHEN sla_eligible = TRUE
                THEN distance_km
            END
        ),
        2
    ) AS avg_distance_km,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE
                sla_eligible = TRUE
                AND derived_sla_status = 'On Time'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE sla_eligible = TRUE
            ),
            0
        ),
        2
    ) AS sla_on_time_pct

FROM fact_order

GROUP BY
    city,
    state

ORDER BY
    sla_on_time_pct DESC
;
