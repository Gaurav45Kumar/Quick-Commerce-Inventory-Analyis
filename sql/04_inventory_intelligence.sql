
-- ==========================================================
-- 04_inventory_intelligence.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Purpose:
-- Analyse inventory position, stockout exposure,
-- replenishment priorities and weekly demand behaviour.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. NETWORK INVENTORY CONTROL TOWER
-- ----------------------------------------------------------

SELECT

    COUNT(*) AS inventory_positions,

    SUM(modelled_inventory_on_hand)
        AS modelled_inventory_units,

    SUM(target_inventory_units)
        AS target_inventory_units,

    COUNT(*) FILTER (
        WHERE reorder_required = TRUE
    ) AS reorder_positions,

    SUM(recommended_replenishment_units)
        AS recommended_replenishment_units,

    ROUND(
        AVG(days_of_supply),
        2
    ) AS avg_days_of_supply,

    ROUND(
        AVG(stockout_probability_pct),
        2
    ) AS avg_stockout_probability_pct

FROM inventory_intelligence
;


-- ----------------------------------------------------------
-- 2. STOCKOUT RISK DISTRIBUTION
-- ----------------------------------------------------------

SELECT

    stockout_risk_band,

    COUNT(*) AS positions,

    SUM(modelled_inventory_on_hand)
        AS inventory_units,

    SUM(recommended_replenishment_units)
        AS replenishment_units,

    ROUND(
        SUM(total_revenue),
        2
    ) AS attributed_revenue,

    ROUND(
        AVG(stockout_probability_pct),
        2
    ) AS avg_stockout_probability_pct,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS position_share_pct,

    ROUND(
        100.0 * SUM(total_revenue) /
        SUM(SUM(total_revenue)) OVER (),
        2
    ) AS revenue_share_pct

FROM inventory_intelligence

GROUP BY
    stockout_risk_band

ORDER BY
    avg_stockout_probability_pct DESC
;


-- ----------------------------------------------------------
-- 3. MANAGEMENT REPLENISHMENT PRIORITY
-- ----------------------------------------------------------

WITH ranked_inventory AS (

    SELECT

        dark_store_id,
        category,
        value_tier,
        xyz_class,

        total_revenue,

        modelled_inventory_on_hand,
        safety_stock_units,
        reorder_point_units,
        target_inventory_units,

        days_of_supply,
        stockout_probability_pct,
        stockout_risk_band,

        recommended_replenishment_units,
        replenishment_priority_score,
        recommended_action,

        RANK() OVER (
            ORDER BY
                replenishment_priority_score DESC,
                total_revenue DESC
        ) AS network_priority_rank,

        RANK() OVER (
            PARTITION BY dark_store_id
            ORDER BY
                replenishment_priority_score DESC,
                total_revenue DESC
        ) AS store_priority_rank

    FROM inventory_intelligence

    WHERE
        reorder_required = TRUE
)

SELECT *
FROM ranked_inventory

ORDER BY
    network_priority_rank
;


-- ----------------------------------------------------------
-- 4. CATEGORY INVENTORY RISK
-- ----------------------------------------------------------

SELECT

    category,

    COUNT(*) AS store_positions,

    COUNT(*) FILTER (
        WHERE reorder_required = TRUE
    ) AS reorder_positions,

    COUNT(*) FILTER (
        WHERE stockout_risk_band = 'High'
    ) AS high_risk_positions,

    COUNT(*) FILTER (
        WHERE stockout_risk_band = 'Critical'
    ) AS critical_risk_positions,

    SUM(recommended_replenishment_units)
        AS replenishment_units,

    ROUND(
        AVG(days_of_supply),
        2
    ) AS avg_days_of_supply,

    ROUND(
        AVG(stockout_probability_pct),
        2
    ) AS avg_stockout_probability_pct,

    ROUND(
        SUM(total_revenue),
        2
    ) AS attributed_revenue

FROM inventory_intelligence

GROUP BY category

ORDER BY
    avg_stockout_probability_pct DESC
;


-- ----------------------------------------------------------
-- 5. HIGH-VALUE × VOLATILE INVENTORY
-- ----------------------------------------------------------

SELECT

    dark_store_id,
    category,

    ROUND(
        total_revenue,
        2
    ) AS attributed_revenue,

    avg_weekly_demand,
    demand_cv,

    modelled_inventory_on_hand,
    reorder_point_units,
    target_inventory_units,

    ROUND(
        stockout_probability_pct,
        2
    ) AS stockout_probability_pct,

    recommended_replenishment_units,
    recommended_action

FROM inventory_intelligence

WHERE
    value_tier = 'High'
    AND xyz_class = 'Z'

ORDER BY
    replenishment_priority_score DESC,
    total_revenue DESC
;


-- ----------------------------------------------------------
-- 6. FOUR-WEEK ROLLING DEMAND
-- Demonstrates window functions on the complete weekly panel.
-- ----------------------------------------------------------

WITH demand_windows AS (

    SELECT

        week_index,
        week_start,
        dark_store_id,
        category,
        weekly_units,
        weekly_revenue,

        LAG(weekly_units) OVER (
            PARTITION BY
                dark_store_id,
                category
            ORDER BY week_index
        ) AS previous_week_units,

        AVG(weekly_units) OVER (
            PARTITION BY
                dark_store_id,
                category
            ORDER BY week_index
            ROWS BETWEEN
                3 PRECEDING
                AND CURRENT ROW
        ) AS rolling_4w_units,

        SUM(weekly_revenue) OVER (
            PARTITION BY
                dark_store_id,
                category
            ORDER BY week_index
            ROWS BETWEEN
                3 PRECEDING
                AND CURRENT ROW
        ) AS rolling_4w_revenue

    FROM weekly_store_category
)

SELECT

    week_index,
    week_start,
    dark_store_id,
    category,
    weekly_units,
    previous_week_units,

    ROUND(
        rolling_4w_units,
        2
    ) AS rolling_4w_avg_units,

    ROUND(
        rolling_4w_revenue,
        2
    ) AS rolling_4w_revenue,

    ROUND(
        100.0 *
        (
            weekly_units -
            previous_week_units
        )
        /
        NULLIF(
            previous_week_units,
            0
        ),
        2
    ) AS wow_unit_growth_pct

FROM demand_windows

ORDER BY
    dark_store_id,
    category,
    week_index
;
