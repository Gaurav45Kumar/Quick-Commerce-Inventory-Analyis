
-- ==========================================================
-- 07_management_priority.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Purpose:
-- Combine commercial, fulfilment and inventory signals into
-- a management-level dark-store intervention framework.
--
-- This is a portfolio decision-support score.
-- Weights are analytical assumptions and do not represent
-- proprietary operating policies.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. DARK STORE MANAGEMENT PRIORITY
-- ----------------------------------------------------------

WITH store_operations AS (

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
        ) AS sla_on_time_pct,

        100.0 *
        COUNT(*) FILTER (
            WHERE order_status = 'Cancelled'
        )
        /
        NULLIF(
            COUNT(*),
            0
        ) AS cancellation_rate_pct,

        AVG(
            CASE
                WHEN cx_eligible = TRUE
                THEN avg_rating
            END
        ) AS avg_customer_rating

    FROM fact_order

    GROUP BY
        dark_store_id,
        dark_store_name,
        city,
        state
),


store_inventory AS (

    SELECT

        dark_store_id,

        COUNT(*) AS inventory_positions,

        COUNT(*) FILTER (
            WHERE reorder_required = TRUE
        ) AS reorder_positions,

        COUNT(*) FILTER (
            WHERE stockout_risk_band IN (
                'High',
                'Critical'
            )
        ) AS high_risk_inventory_positions,

        SUM(
            recommended_replenishment_units
        ) AS replenishment_units,

        AVG(
            stockout_probability_pct
        ) AS avg_stockout_probability_pct,

        MAX(
            replenishment_priority_score
        ) AS highest_inventory_priority_score

    FROM inventory_intelligence

    GROUP BY
        dark_store_id
),


combined AS (

    SELECT

        o.*,

        i.inventory_positions,
        i.reorder_positions,
        i.high_risk_inventory_positions,
        i.replenishment_units,
        i.avg_stockout_probability_pct,
        i.highest_inventory_priority_score

    FROM store_operations o

    LEFT JOIN store_inventory i
        ON o.dark_store_id =
           i.dark_store_id
),


normalized AS (

    SELECT

        *,

        -- High GMV = larger commercial exposure
        PERCENT_RANK() OVER (
            ORDER BY completed_gmv ASC
        ) AS commercial_exposure_score,

        -- Lower SLA = higher operational risk
        PERCENT_RANK() OVER (
            ORDER BY sla_on_time_pct DESC
        ) AS sla_risk_score,

        -- Slower delivery = higher operational risk
        PERCENT_RANK() OVER (
            ORDER BY avg_delivery_minutes ASC
        ) AS delivery_risk_score,

        -- Higher cancellation rate = higher risk
        PERCENT_RANK() OVER (
            ORDER BY cancellation_rate_pct ASC
        ) AS cancellation_risk_score,

        -- Higher stockout probability = higher risk
        PERCENT_RANK() OVER (
            ORDER BY avg_stockout_probability_pct ASC
        ) AS inventory_risk_score

    FROM combined
),


scored AS (

    SELECT

        *,

        (
            0.20 * commercial_exposure_score
            +
            0.25 * sla_risk_score
            +
            0.15 * delivery_risk_score
            +
            0.10 * cancellation_risk_score
            +
            0.30 * inventory_risk_score
        ) * 100 AS management_intervention_score

    FROM normalized
),


ranked AS (

    SELECT

        *,

        RANK() OVER (
            ORDER BY
                management_intervention_score DESC
        ) AS management_priority_rank

    FROM scored
)

SELECT

    dark_store_id,
    dark_store_name,
    city,
    state,

    total_orders,
    completed_orders,

    ROUND(
        completed_gmv,
        2
    ) AS completed_gmv,

    ROUND(
        sla_on_time_pct,
        2
    ) AS sla_on_time_pct,

    ROUND(
        avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes,

    ROUND(
        cancellation_rate_pct,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        avg_customer_rating,
        2
    ) AS avg_customer_rating,

    inventory_positions,
    reorder_positions,
    high_risk_inventory_positions,
    replenishment_units,

    ROUND(
        avg_stockout_probability_pct,
        2
    ) AS avg_stockout_probability_pct,

    ROUND(
        commercial_exposure_score * 100,
        2
    ) AS commercial_exposure_score,

    ROUND(
        sla_risk_score * 100,
        2
    ) AS sla_risk_score,

    ROUND(
        delivery_risk_score * 100,
        2
    ) AS delivery_risk_score,

    ROUND(
        cancellation_risk_score * 100,
        2
    ) AS cancellation_risk_score,

    ROUND(
        inventory_risk_score * 100,
        2
    ) AS inventory_risk_score,

    ROUND(
        management_intervention_score,
        2
    ) AS management_intervention_score,

    management_priority_rank,

    CASE

        WHEN management_intervention_score >= 70
            THEN 'Immediate Review'

        WHEN management_intervention_score >= 55
            THEN 'High Attention'

        WHEN management_intervention_score >= 40
            THEN 'Monitor Closely'

        ELSE 'Standard Monitoring'

    END AS management_action

FROM ranked

ORDER BY
    management_priority_rank
;


-- ----------------------------------------------------------
-- 2. CITY MANAGEMENT SUMMARY
-- ----------------------------------------------------------

WITH city_operations AS (

    SELECT

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
        city,
        state
),

city_inventory AS (

    SELECT

        d.city,
        d.state,

        SUM(
            i.recommended_replenishment_units
        ) AS replenishment_units,

        COUNT(*) FILTER (
            WHERE i.reorder_required = TRUE
        ) AS reorder_positions,

        AVG(
            i.stockout_probability_pct
        ) AS avg_stockout_probability_pct

    FROM inventory_intelligence i

    INNER JOIN dim_dark_store d
        ON i.dark_store_id =
           d.dark_store_id

    GROUP BY
        d.city,
        d.state
)

SELECT

    o.city,
    o.state,
    o.total_orders,
    o.completed_orders,

    ROUND(
        o.completed_gmv,
        2
    ) AS completed_gmv,

    ROUND(
        o.avg_delivery_minutes,
        2
    ) AS avg_delivery_minutes,

    ROUND(
        o.sla_on_time_pct,
        2
    ) AS sla_on_time_pct,

    i.reorder_positions,
    i.replenishment_units,

    ROUND(
        i.avg_stockout_probability_pct,
        2
    ) AS avg_stockout_probability_pct

FROM city_operations o

LEFT JOIN city_inventory i
    ON o.city = i.city
    AND o.state = i.state

ORDER BY
    o.completed_gmv DESC
;
