# Superstore SQL Analytics Project (SQLite)

## Background

This project demonstrates an end-to-end analytical workflow using **SQLite** and **advanced SQL**, starting from raw transactional data.

**Data Source:** Superstore dataset (transactional CSV)  

**Project Scope:** From raw data ingestion to normalised schema to advanced analytical insights using window functions and performance-conscious query design.

---

## Methodology

### Data Modelling & Schema Design

The raw CSV was first loaded into a staging table, then decomposed into a normalised star schema:

**Tables:**
- **Customers:** One row per customer with profile attributes (segment, location, region)
- **Products:** One row per product with category classification and pricing
- **Orders:** One row per order with customer reference and order-level metrics (GMV)
- **OrderItems (Fact):** One row per product per order, containing revenue and profit at the line-item grain

### Data Cleaning & Transformation

**Date Handling:**
- Raw dates in inconsistent M/D/YYYY format → ISO format (YYYY-MM-DD)
- Enables correct use of `julianday()`, `LAG()`, and date arithmetic

**Revenue Definition:**
- Sales treated as net revenue (post-discount)

### Analytical Approach

Four key analytical queries implemented:

1. **Customer Lifetime Value (CLV):** Lifetime revenue, order value, frequency, lifespan, and ranking
2. **Cumulative Revenue Thresholds:** Identified when customers cross 50% of lifetime revenue using running sums
3. **Order Gap Behaviour:** Days between orders, gap classification (`first_order`, `habitual`, `reactivated`)
4. **Basket Analysis:** Most frequently bought product pairs per order with ranked output

**Techniques:** Window functions (`LAG`, `SUM OVER`, `DENSE_RANK`), CTEs, self-joins, careful grain management

---

## Directory and Skills Reflected

```
sql_projects/
├── readme.md                          # Project documentation
├── data/
│   ├── Sample - Superstore.csv       # Raw transactional data
│   └── merged_sales_with_latlong.csv # Enriched dataset with geolocation
├── schema/
│   ├── create_tables.sql             # Normalised schema definition
│   └── populate.sql                  # Data pipeline (load & transform)
├── queries/
│   ├── case_1.sql                    # Baseline analytical queries
│   ├── discount_behaviour.sql        # Discount impact analysis
│   └── MoM_volatility_analysis.sql   # Month-over-month business metrics
└── python/
    └── ETL.ipynb                     # Data pipeline orchestration & exploration
```

**Skills Demonstrated:**
- **SQL:** Schema normalisation, window functions, CTEs, performance reasoning with `EXPLAIN QUERY PLAN`
- **Data Engineering:** ETL pipeline design, data cleaning, grain definition and validation
- **Analytics:** Customer cohort analysis, temporal patterns, basket analysis
- **Performance Optimisation:** Index strategy aligned with window partitions, CTE materialisation analysis
- **Tools:** SQLite, Python (Jupyter), VS Code
