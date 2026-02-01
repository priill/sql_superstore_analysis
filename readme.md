# Superstore SQL Analytics Project (SQLite)

## Overview

This project demonstrates an end-to-end analytical workflow using **SQLite** and **advanced SQL**.  
Starting from a raw transactional CSV (Superstore dataset), the work covers:

- Data modelling & normalisation
- Data cleaning and type conversion
- Fact–dimension design
- Advanced analytical queries using window functions
- Performance reasoning using `EXPLAIN QUERY PLAN`

The focus is **not just producing results**, but understanding **data grain, correctness, and execution behaviour**.

---

## Dataset

**Source:** Superstore transactional CSV  
**Grain:** One row per **order line item** (product × order)

Example:
- One `OrderID` can contain multiple `ProductID`s
- Revenue is recorded at the **line-item level**, not the order level

---

## Schema Design

The raw CSV was first loaded into a staging table (`Superstore`), then decomposed into a normalised schema.

### Tables

#### 1. Customers
- One row per customer
- Handles customer profile variations across transactions

```sql
Customers(CustomerID PK, CustomerName, Segment, Country, City, State, PostalCode, Region)
```

#### 2. Products
- One row per product
- ProductID treated as the business key

```sql
Products(ProductID PK, ProductName, Category, SubCategory, Price)
```

#### 3. Orders
- One row per order
- Derived metrics (GMV) added post-load

```sql
Orders(OrderID PK, CustomerID FK, OrderDate, ShipDate, ShipMode, GMV)
```

#### 4. OrderItems (Fact table)
- One row per product per order
- Revenue and profit live at this grain

```sql
OrderItems(OrderItemID PK, OrderID FK, ProductID FK, Quantity, Sales, Discount, Profit)
```

---

## Data Cleaning & Transformation

### Date Cleaning
- Raw dates were in inconsistent M/D/YYYY formats
- Converted into ISO format (YYYY-MM-DD) before insertion
- Enabled correct use of `julianday()`, `LAG()`, and date arithmetic

### Revenue Definition
- Sales is treated as net revenue (post-discount)

---

## Analytical Queries Implemented

### 1. Customer Lifetime Value (CLV)

Metrics:
- Lifetime revenue
- Average order value
- Purchase frequency
- Customer lifespan (days)
- Revenue-based ranking with `DENSE_RANK() OVER (ORDER BY lifetime_revenue DESC)`

### 2. Cumulative Revenue Thresholds
- Identified when a customer crosses 50% of lifetime revenue
- Used running cumulative sums and lagged window comparisons
- Required careful handling of order-level grain before applying windows

### 3. Order Gap Behaviour Analysis
Computed:
- Days between consecutive orders
- Average gap per customer
- Classified orders as: `first_order`, `habitual`, `reactivated`
- Implemented efficiently using shared window partitions

### 4. Basket Analysis (Product Pairing)
- Goal: Find the most frequently bought product pairs per order
- Approach: Self-join on de-duplicated (OrderID, ProductID)
- Enforced (A,B) but not (B,A)
- Ranked pairs by frequency

---

## Performance & Query Planning

### EXPLAIN QUERY PLAN Analysis
- Inspect CTE materialisation
- Identify unnecessary sorts
- Understand when SQLite uses TEMP B-TREES
- Reason about index effectiveness

### Indexing Strategy
Create composite indexes aligned with window partitions:

```sql
CREATE INDEX idx_orders_customer_date
ON Orders(CustomerID, OrderDate);
```

Benefits:
- Streaming window execution
- Fewer temporary B-trees
- Better scalability

---

## Tools

- SQLite
- VS Code with SQLite extension
- SQL window functions: `LAG`, `SUM OVER`, `AVG OVER`, `DENSE_RANK`

---

## Key Learnings

- Data grain determines correctness
- Window functions are powerful but sensitive to ordering
- CTEs are logical, not free — they affect execution
- Indexes should follow access patterns, not intuition
- SQL is both a data language and an execution model
