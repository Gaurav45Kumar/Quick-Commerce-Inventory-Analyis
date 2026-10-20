# Methodology

## Data Treatment

Raw source records are retained.

Analytical eligibility flags determine which records are valid for
commercial, SLA and customer-experience calculations.

## Commercial Analytics

Orders with transaction information are commercially eligible.

Completed-sales analytics require:

- transaction detail
- Delivered order status

## Customer Experience

Multiple ratings are aggregated to one order-level mean rating.

CX KPIs use delivered rated orders only.

## Analytical SLA

Delivered orders are classified using delivery minutes:

- On Time: <= 35 minutes
- At Risk: 36–50 minutes
- Late: > 50 minutes

## Dark Store Simulation

The dataset contains cities but no real dark-store IDs.

Twenty analytical dark stores are generated deterministically across
ten cities.

## Inventory Grain

Store × SKU daily demand was too sparse for reliable variability
modelling.

Therefore:

- Network × SKU is used for ABC analysis.
- Dark Store × Category × Week is used for inventory variability.

## XYZ Classification

Relative quartiles of coefficient of variation are used.

- X = lowest 25% variability
- Y = middle 50%
- Z = highest 25%

## Inventory

Safety stock and reorder points use:

- weekly demand
- lead-time assumptions
- service-level assumptions
- demand uncertainty

Inventory-on-hand values are simulated deterministically.

## Profitability

Category gross margins and fulfilment costs are scenario assumptions.

Contribution Margin:

Merchandise Gross Profit
minus Variable Cost-to-Serve.

The resulting metrics are modelled contribution economics rather than
actual company financial results.

## Validation

Core metrics are reconciled across:

Python → DuckDB → SQL → Reporting Exports.

The final project contains 18 validation checks.
