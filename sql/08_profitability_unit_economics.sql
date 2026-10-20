
-- ==========================================================
-- 08_profitability_unit_economics.sql
-- Quick-Commerce Profitability & Fulfilment Intelligence
-- ==========================================================
--
-- Profitability values are modelled contribution economics
-- based on explicit portfolio assumptions.
-- They are NOT reported company profits.
-- ==========================================================


-- ----------------------------------------------------------
-- 1. NETWORK UNIT ECONOMICS
-- ----------------------------------------------------------

SELECT

    COUNT(*) AS completed_orders,

    ROUND(
        SUM(merchandise_revenue),
        2
    ) AS completed_gmv,

    ROUND(
        SUM(modelled_merchandise_gross_profit),
        2
    ) AS merchandise_gross_profit,

    ROUND(
        SUM(modelled_variable_cost_to_serve),
        2
    ) AS variable_cost_to_serve,

    ROUND(
        SUM(modelled_contribution_margin),
        2
    ) AS contribution_margin,

    ROUND(
        100.0 *
        SUM(modelled_contribution_margin)
        /
        NULLIF(
            SUM(merchandise_revenue),
            0
        ),
        2
    ) AS contribution_margin_pct,

    ROUND(
        AVG(modelled_contribution_margin),
        2
    ) AS avg_contribution_per_order,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE modelled_contribution_margin < 0
        )
        /
        COUNT(*),
        2
    ) AS negative_contribution_order_pct

FROM fact_order_profitability
;


-- ----------------------------------------------------------
-- 2. DARK STORE PROFITABILITY RANKING
-- ----------------------------------------------------------

SELECT

    dark_store_id,
    dark_store_name,
    city,

    completed_orders,

    ROUND(
        completed_gmv,
        2
    ) AS completed_gmv,

    ROUND(
        contribution_margin,
        2
    ) AS contribution_margin,

    ROUND(
        contribution_margin_pct,
        2
    ) AS contribution_margin_pct,

    ROUND(
        avg_contribution_per_order,
        2
    ) AS avg_contribution_per_order,

    ROUND(
        negative_order_share_pct,
        2
    ) AS negative_order_share_pct,

    RANK() OVER (
        ORDER BY
            contribution_margin DESC
    ) AS contribution_rank,

    RANK() OVER (
        ORDER BY
            contribution_margin_pct DESC
    ) AS margin_efficiency_rank

FROM dark_store_profitability

ORDER BY
    contribution_rank
;


-- ----------------------------------------------------------
-- 3. CATEGORY GROSS PROFITABILITY
-- ----------------------------------------------------------

SELECT

    category,

    completed_orders,
    units_sold,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        merchandise_gross_profit,
        2
    ) AS merchandise_gross_profit,

    ROUND(
        gross_margin_pct,
        2
    ) AS gross_margin_pct,

    ROUND(
        revenue_share_pct,
        2
    ) AS revenue_share_pct,

    RANK() OVER (
        ORDER BY
            merchandise_gross_profit DESC
    ) AS gross_profit_rank

FROM category_profitability

ORDER BY
    gross_profit_rank
;


-- ----------------------------------------------------------
-- 4. DISTANCE ECONOMICS
-- ----------------------------------------------------------

WITH distance_economics AS (

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
        END AS band_order,

        merchandise_revenue,
        modelled_last_mile_cost,
        modelled_variable_cost_to_serve,
        modelled_contribution_margin

    FROM fact_order_profitability
)

SELECT

    distance_band,

    COUNT(*) AS orders,

    ROUND(
        AVG(merchandise_revenue),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(modelled_last_mile_cost),
        2
    ) AS avg_last_mile_cost,

    ROUND(
        AVG(modelled_variable_cost_to_serve),
        2
    ) AS avg_cost_to_serve,

    ROUND(
        AVG(modelled_contribution_margin),
        2
    ) AS avg_contribution,

    ROUND(
        100.0 *
        SUM(modelled_contribution_margin)
        /
        NULLIF(
            SUM(merchandise_revenue),
            0
        ),
        2
    ) AS contribution_margin_pct

FROM distance_economics

GROUP BY
    distance_band,
    band_order

ORDER BY
    band_order
;


-- ----------------------------------------------------------
-- 5. LOW-VALUE / LOSS-MAKING ORDER DIAGNOSTIC
-- ----------------------------------------------------------

WITH order_segments AS (

    SELECT

        *,

        NTILE(4) OVER (
            ORDER BY merchandise_revenue
        ) AS basket_value_quartile

    FROM fact_order_profitability
)

SELECT

    basket_value_quartile,

    COUNT(*) AS orders,

    ROUND(
        AVG(merchandise_revenue),
        2
    ) AS avg_order_value,

    ROUND(
        AVG(modelled_variable_cost_to_serve),
        2
    ) AS avg_cost_to_serve,

    ROUND(
        AVG(modelled_contribution_margin),
        2
    ) AS avg_contribution,

    COUNT(*) FILTER (
        WHERE modelled_contribution_margin < 0
    ) AS negative_contribution_orders,

    ROUND(
        100.0 *
        COUNT(*) FILTER (
            WHERE modelled_contribution_margin < 0
        )
        /
        COUNT(*),
        2
    ) AS negative_contribution_order_pct

FROM order_segments

GROUP BY
    basket_value_quartile

ORDER BY
    basket_value_quartile
;
