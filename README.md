# Quick-Commerce Operations, Inventory & Profitability Intelligence

## Dark Store, Inventory, Last-Mile & Unit Economics Analytics

An end-to-end analytics portfolio project that transforms a public
quick-commerce practice dataset into a management decision-support
system covering:

- Commercial performance
- Dark-store operations
- Inventory intelligence
- Fulfilment SLA
- Customer experience
- Last-mile economics
- Contribution-margin modelling
- Management prioritisation

> **Important disclosure**
>
> This project does not use proprietary operational or financial data
> from Zepto, Blinkit, Swiggy Instamart or any other quick-commerce
> company.
>
> The source dataset is a public Zepto-inspired practice dataset.
> Dark stores, inventory positions, replenishment policies and
> profitability assumptions are explicitly modelled for portfolio
> analytics.

---

# Business Objective

Quick-commerce businesses must simultaneously:

- grow order volume and GMV,
- maintain fast delivery,
- position inventory close to demand,
- minimise stockouts,
- control last-mile cost,
- and protect contribution margin.

This project develops an analytical system to answer:

1. Which dark stores generate the strongest commercial performance?
2. Which stores and categories face the highest inventory risk?
3. Where should replenishment be prioritised?
4. How does delivery distance affect cost-to-serve?
5. Which basket sizes create weak or negative contribution economics?
6. Which dark stores require management intervention?
7. How do commercial, inventory and fulfilment metrics interact?

---

# Technology Stack

| Layer | Technology |
|---|---|
| Data Engineering | Python, Pandas, NumPy |
| Statistical Modelling | SciPy |
| Analytical Database | DuckDB |
| SQL Analytics | SQL, CTEs, Window Functions |
| BI & Reporting | Power BI |
| Source Format | Excel |
| Development | Google Colab |
| Version Control | Git & GitHub |

---

# Analytical Architecture

Source Dataset  
→ Python Data Quality & Transformation  
→ Canonical Analytical Model  
→ Dark Store Simulation  
→ Inventory Intelligence  
→ Fulfilment & Last-Mile Analytics  
→ Profitability & Unit Economics  
→ DuckDB Analytical Warehouse  
→ SQL Analytics Layer  
→ Power BI Reporting Tables  
→ Management Decision Dashboard

---

# Dataset

**Dataset:** Zepto-Inspired Online Grocery & Delivery Dataset  
**Source:** Kaggle

Dataset page:

https://www.kaggle.com/datasets/ashishjangir6494/zepto-inspired-online-grocery-and-delivery-dataset

The source workbook contains six relational tables:

| Table | Rows |
|---|---:|
| Customers | 10,000 |
| Products | 1,200 |
| Orders | 20,000 |
| Transactions | 50,000 |
| Ratings | 20,000 |
| Deliveries | 20,000 |

**Total source records: 121,200**

The raw workbook is intentionally not redistributed in this repository.
Users should obtain the dataset directly from its original Kaggle page.

---

# Data Quality Treatment

The raw source tables are preserved.

Important analytical rules include:

- `customer_id` is the authoritative customer identifier.
- Orders without transaction details remain in operational counts.
- Orders without transaction details are excluded from revenue analytics.
- Completed-sales analytics require a Delivered order and transaction detail.
- Multiple ratings are aggregated to one order-level average.
- Customer-experience KPIs use delivered rated orders only.
- Source delivery status is retained for lineage.
- A separate analytical SLA is derived from delivery minutes.
- Customer creation dates are excluded from lifecycle analysis because of temporal inconsistencies.
- Payment mode is treated as transaction-line metadata.

---

# Analytical SLA

For portfolio analysis:

| SLA Status | Delivery Time |
|---|---:|
| On Time | <= 35 minutes |
| At Risk | 36–50 minutes |
| Late | > 50 minutes |

Only delivered orders are SLA eligible.

This is an analytical SLA definition and not a claimed Zepto SLA policy.

---

# Dark Store Network

The source dataset does not contain dark-store identifiers.

A deterministic analytical network of:

**20 modelled dark stores across 10 cities**

was created.

Orders are assigned consistently using a deterministic customer-based
hash.

These locations are analytical operating nodes and do not represent
actual company dark stores.

---

# Validated Executive KPIs

| KPI | Result |
|---|---:|
| Total Orders | 20,000 |
| Commercial Eligible Orders | 18,372 |
| Completed Orders | 14,333 |
| Completed GMV | ₹28,224,720 |
| Completed AOV | ₹1,969.21 |
| Average Delivery Time | 41.30 min |
| P90 Delivery Time | 71.00 min |
| SLA On-Time Rate | 42.50% |
| CX Eligible Orders | 9,826 |
| Average Customer Rating | 3.88 |
| Modelled Contribution Margin | ₹4,301,584.56 |
| Contribution Margin % | 15.24% |
| Negative Contribution Orders | ~10.3% |
| Inventory Positions | 160 |
| Reorder Positions | 130 |
| Recommended Replenishment | 800 units |
| Average Stockout Probability | 10.64% |

Core metrics are reconciled across Python, DuckDB and SQL.

---

# Key Business Findings

## 1. Low-value baskets create the greatest profitability pressure

The lowest basket-value quartile averages approximately:

**₹449.68 per order**

Within this segment:

- 40.89% of orders are negative contribution
- average cost-to-serve is approximately ₹79.31
- average contribution is approximately ₹13.35/order

No negative-contribution orders appear in Q2–Q4 under the scenario model.

### Decision implication

Potential interventions include:

- basket-building incentives,
- minimum-order economics,
- product bundling,
- targeted cross-sell,
- and delivery-fee optimisation.

---

## 2. Delivery distance increases cost-to-serve

| Distance | Avg Cost-to-Serve | Contribution Margin |
|---|---:|---:|
| 0–3 km | ₹83.85 | 15.86% |
| 3–5 km | ₹92.76 | 15.50% |
| 5–7 km | ₹100.77 | 15.14% |
| 7+ km | ₹110.73 | 14.58% |

Contribution efficiency declines as delivery distance increases within
the modelled scenario.

This is an analytical association and should not be interpreted as
causal proof.

---

## 3. Fulfilment performance and economics interact

| SLA Status | Contribution Margin |
|---|---:|
| On Time | 15.72% |
| At Risk | 15.14% |
| Late | 14.71% |

Late deliveries are also associated with greater delivery distance and
higher modelled fulfilment cost.

---

## 4. Inventory intervention is highly targeted

Across 160 Dark Store × Category positions:

- 92 are Low stockout risk
- 56 are Medium risk
- 12 are High risk
- 130 have reached or fallen below reorder point
- 800 units are recommended for replenishment

---

## 5. Commercial importance and demand variability are combined

Commercial Value:

- High
- Medium
- Low

Demand Variability:

- X = comparatively predictable
- Y = moderate variability
- Z = comparatively volatile

The **High Value × Z** combination represents a strategically important
inventory segment.

---

# Inventory Methodology

The source dataset does not contain actual inventory-on-hand values.

The project therefore models inventory decision intelligence using:

- weekly observed demand,
- ABC/XYZ-style segmentation,
- commercial value,
- lead-time assumptions,
- coverage assumptions,
- service levels,
- safety stock,
- reorder points,
- simulated inventory on hand,
- stockout probability,
- replenishment priority.

## Core formulas

Average Daily Demand:

Average Weekly Demand / 7

Safety Stock:

Service Z Score × Lead-Time Demand Standard Deviation

Reorder Point:

Expected Lead-Time Demand + Safety Stock

Recommended Replenishment:

Target Inventory − Modelled Inventory On Hand

Replenishment is recommended only after the calculated reorder threshold
is reached.

---

# Inventory Scenario Assumptions

| Category | Lead Time | Coverage |
|---|---:|
| Fruits & Vegetables | 1 | 3 |
| Dairy & Bakery | 1 | 3 |
| Beverages | 2 | 5 |
| Snacks & Branded Foods | 2 | 6 |
| Grocery & Staples | 3 | 7 |
| Baby Care | 4 | 8 |
| Personal Care | 4 | 8 |
| Household | 5 | 10 |

These are portfolio modelling assumptions.

---

# Profitability & Unit Economics

Actual procurement costs and corporate cost structures are not present
in the source dataset.

The project therefore creates a transparent scenario-based
contribution-margin model.

## Modelled category gross margins

| Category | Margin |
|---|---:|
| Fruits & Vegetables | 24% |
| Dairy & Bakery | 20% |
| Beverages | 18% |
| Snacks & Branded Foods | 21% |
| Grocery & Staples | 16% |
| Baby Care | 18% |
| Personal Care | 25% |
| Household | 22% |

## Fulfilment assumptions

- Picking & packing: ₹20/order
- Packaging: ₹8/order
- Last-mile base cost: ₹25/order
- Distance cost: ₹4/km
- Payment processing: 1.2% of revenue

## Contribution formula

Modelled Contribution Margin

= Merchandise Gross Profit  
− Picking & Packing  
− Packaging  
− Last-Mile Cost  
− Payment Processing

The metric represents contribution before fixed overhead and is not
actual company profit.

---

# Dark Store Profitability

The project distinguishes between:

- total contribution generation,
- margin efficiency,
- GMV scale,
- and negative-contribution exposure.

For example, a store can rank highly in revenue but lower in
operational or inventory performance.

This prevents management prioritisation from becoming a simple GMV
leaderboard.

---

# SQL Analytics

Eight standalone SQL scripts are included.

| SQL File | Domain |
|---|---|
| 01_schema_and_quality.sql | Data quality and integrity |
| 02_commercial_performance.sql | Commercial analytics |
| 03_dark_store_operations.sql | Store operations |
| 04_inventory_intelligence.sql | Inventory |
| 05_fulfilment_sla.sql | SLA and fulfilment |
| 06_customer_experience.sql | Customer experience |
| 07_management_priority.sql | Management ranking |
| 08_profitability_unit_economics.sql | Profitability |

SQL capabilities demonstrated include:

- CTEs
- joins
- conditional aggregation
- LAG()
- RANK()
- PERCENT_RANK()
- NTILE()
- rolling windows
- partitioned rankings
- percentile calculations
- management scoring

---

# Management Intervention Framework

The modelled management score combines:

| Component | Weight |
|---|---:|
| Commercial Exposure | 20% |
| SLA Risk | 25% |
| Delivery Risk | 15% |
| Cancellation Risk | 10% |
| Inventory Risk | 30% |

These weights are analytical assumptions.

---

# DuckDB Warehouse

The analytical warehouse contains 14 validated base tables.

Dimensions:

- dim_customer
- dim_product
- dim_date
- dim_dark_store

Core facts:

- fact_order
- fact_order_item

Operational tables:

- weekly_store_category
- inventory_intelligence
- sku_network_profile
- inventory_assumptions

Profitability tables:

- fact_order_profitability
- fact_order_item_profitability
- dark_store_profitability
- category_profitability

---

# Power BI Dashboard

The planned dashboard consists of five pages:

1. Executive Overview
2. Dark Store Performance
3. Inventory Control Tower
4. Fulfilment & Last Mile
5. Profitability & Decision Intelligence

The analytical engine is completed and validated before dashboard
development so presentation changes cannot alter the underlying
business logic.

---

# Repository Structure

README.md

requirements.txt

.gitignore

data/
- README.md

notebooks/
- India_Quick_Commerce_Profitability_Fulfilment_Intelligence.ipynb
- README.md

sql/
- 01_schema_and_quality.sql
- 02_commercial_performance.sql
- 03_dark_store_operations.sql
- 04_inventory_intelligence.sql
- 05_fulfilment_sla.sql
- 06_customer_experience.sql
- 07_management_priority.sql
- 08_profitability_unit_economics.sql

database/
- quick_commerce_intelligence.duckdb

powerbi/
- README.md
- exports/

docs/
- methodology.md
- kpi_dictionary.md

reports/
- final_validation_report.csv
- project_asset_manifest.csv

---

# Reproducibility

The notebook executes the complete workflow:

1. Data ingestion
2. Data-quality audit
3. Canonical modelling
4. Dark-store simulation
5. Demand analysis
6. Inventory modelling
7. Stockout-risk modelling
8. Profitability modelling
9. DuckDB materialisation
10. SQL analytics
11. Power BI reporting exports
12. Final project validation

---

# Important Limitations

This is a portfolio analytics project rather than an operational system
deployed by a quick-commerce company.

Important limitations:

- dark stores are simulated,
- inventory levels are simulated,
- lead times are assumptions,
- gross margins are assumptions,
- cost-to-serve parameters are assumptions,
- no rider-level operational data is available,
- source customer creation dates are not used for lifecycle analysis,
- some synthetic product names/categories may not be semantically realistic.

Modelled inventory and financial metrics demonstrate methodology rather
than actual company performance.

---

# Skills Demonstrated

## Analytics
- Data quality
- KPI modelling
- Business analysis
- Decision intelligence

## Python
- Pandas
- NumPy
- SciPy
- Feature engineering

## SQL
- DuckDB
- CTEs
- Window functions
- Ranking
- Analytical SQL

## Supply Chain
- ABC/XYZ
- Safety stock
- Reorder point
- Stockout risk

## Operations
- Dark stores
- SLA
- Delivery distance
- Last-mile analytics

## Finance
- Gross margin
- Cost-to-serve
- Contribution economics

## BI
- Power BI
- Semantic modelling
- Management dashboards

---

# Project Status

Analytics Engine: COMPLETE  
Data Validation: COMPLETE  
DuckDB Warehouse: COMPLETE  
SQL Analytics: COMPLETE  
Power BI Export Layer: COMPLETE  
Power BI Dashboard: NEXT PHASE
