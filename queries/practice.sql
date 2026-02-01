/*
Customer Purchase Velocity

Task
For each customer order, compute:
- Days since their previous order
- Average days between orders (per customer)

Classify each order as:
- first_order
- habitual
- reactivated

*/

WITH gaps_between_orders AS (
    SELECT 
        o.CustomerID,
        o.OrderID,
        o.OrderDate,
        JULIANDAY(o.OrderDate) - JULIANDAY(LAG(o.OrderDate) OVER (
                PARTITION BY o.CustomerID ORDER BY o.OrderDate)
            ) AS days_since_last_order
    FROM Orders o
),

avg_gaps AS (
    SELECT *,
        AVG(days_since_last_order) OVER (
            PARTITION BY CustomerID
        ) AS avg_gap_days
    FROM gaps_between_orders
)

SELECT
    g.CustomerID,
    g.OrderID,
    g.OrderDate,
    g.days_since_last_order,
    avg_gap_days,
    CASE
        WHEN g.days_since_last_order IS NULL THEN 'first_order'
        WHEN g.days_since_last_order <= AVG(g.days_since_last_order) OVER (
            PARTITION BY g.CustomerID) THEN 'habitual'
        ELSE 'reactivated'
    END AS order_type
FROM avg_gaps g

/*

Revenue Contribution Over Time

Task
For each customer order:
- Compute cumulative spend
- Compute % of lifetime spend at that order
- Identify the order where the customer crosses 50% of lifetime spend

*/

WITH revenues AS (
	SELECT
        o.CustomerID,
        o.OrderID,
		o.OrderDate,
		SUM(oi.Sales) OVER (
			PARTITION BY o.OrderID) AS order_revenue
		 FROM Orders o JOIN OrderItems oi ON o.OrderID = oi.OrderID
),

cumulative_spends AS (
    SELECT *,
        SUM(order_revenue) OVER (
            PARTITION BY CustomerID ORDER BY OrderDate 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM revenues
),

cumulative_spend_pctg AS (
    SELECT
        *,
        100.0*cumulative_revenue/MAX(cumulative_revenue) OVER (
            PARTITION BY CustomerID 
        ) AS pct_lifetime_revenue
    FROM cumulative_spends
)

SELECT *,
	CASE
		WHEN pct_lifetime_revenue < 50 THEN 0 
		WHEN pct_lifetime_revenue >= 50 AND LAG(pct_lifetime_revenue)  OVER (
			PARTITION BY CustomerID ORDER BY OrderDate
		) < 50 THEN 1 
		ELSE 0
	END AS crossed_50_pct_flag
FROM cumulative_spend_pctg


/*

Basket Analysis (Self-Join)

Task
Find the top 10 most frequent product pairs bought together in the same order.

Rules:
- Each pair appears once (A,B) not (B,A)
- Ignore order of purchase

*/

with order_products AS (
    SELECT
        oi.OrderID,
        oi.ProductID,
        p.ProductName
    FROM OrderItems oi
    JOIN Products p ON oi.ProductID = p.ProductID
    group by oi.OrderID, oi.ProductID, p.ProductName
),

product_pairs AS (
    SELECT
        op1.ProductID AS ProductA,
        op1.ProductName AS ProductAName,
        op2.ProductID AS ProductB,
        op2.ProductName AS ProductBName,
        COUNT(*) AS pair_count
    FROM order_products op1
    JOIN order_products op2
        ON op1.OrderID = op2.OrderID
        AND op1.ProductID < op2.ProductID
    GROUP BY ProductA, ProductB
    ORDER BY pair_count DESC
),

ranked_pairs AS (
    SELECT *,
        DENSE_RANK() OVER (
            ORDER BY pair_count DESC
        ) AS rn
    FROM product_pairs
)

SELECT
    *
FROM ranked_pairs
WHERE rn <= 10

/*

Customer Lifetime Value Ranking

Task
Rank customers by:
- Lifetime revenue
- Average order value
- Purchase frequency
- Lifetime duration (first → last order)

Output
CustomerID
lifetime_revenue
avg_order_value
orders_count
lifetime_days
customer_rank

Rules:
- Correct joins
- No duplicated revenue
- One row per customer

*/

with clv as (
    select 
        o.CustomerID,
        sum(oi.Sales) AS lifetime_revenue,
        avg(oi.Sales) as avg_order_value,
        count(o.OrderID) as orders_count,
        julianday(max(o.OrderDate)) 
        - 
        julianday(min(o.OrderDate)) AS lifetime_days
    FROM Orders o
    JOIN OrderItems oi ON o.OrderID = oi.OrderID
    GROUP BY CustomerID
)

select CustomerID, 
    lifetime_revenue, 
    avg_order_value, 
    orders_count, 
    lifetime_days,
    DENSE_RANK() OVER (
        ORDER BY lifetime_revenue DESC
    ) AS customer_rank
from clv

/*

Performance Awareness

Task
Identify 3 queries from above that will be slow at scale
Propose indexes to optimise them

Verify using:

EXPLAIN QUERY PLAN

Output:
- Query
- Index
- Why it helps

*/

-- Practice 1
EXPLAIN QUERY PLAN
WITH gaps_between_orders AS (
    SELECT 
        o.CustomerID,
        o.OrderID,
        o.OrderDate,
        JULIANDAY(o.OrderDate) - JULIANDAY(LAG(o.OrderDate) OVER (
                PARTITION BY o.CustomerID ORDER BY o.OrderDate)
            ) AS days_since_last_order
    FROM Orders o
)

SELECT
    g.CustomerID,
    g.OrderID,
    g.OrderDate,
    g.days_since_last_order,
    AVG(days_since_last_order) OVER (
            PARTITION BY CustomerID
        ) AS avg_gap_days,
    CASE
        WHEN g.days_since_last_order IS NULL THEN 'first_order'
        WHEN g.days_since_last_order <= AVG(g.days_since_last_order) OVER (
            PARTITION BY g.CustomerID) THEN 'habitual'
        ELSE 'reactivated'
    END AS order_type
FROM gaps_between_orders g

-- Optimized by index on:
-- Orders(CustomerID, OrderDate)

-- Practice 2
EXPLAIN QUERY PLAN
WITH revenues AS (
	SELECT
        o.CustomerID,
        o.OrderID,
		o.OrderDate,
		SUM(oi.Sales) OVER (
			PARTITION BY o.OrderID) AS order_revenue
		 FROM Orders o JOIN OrderItems oi ON o.OrderID = oi.OrderID
),

cumulative_spends AS (
    SELECT *,
        SUM(order_revenue) OVER (
            PARTITION BY CustomerID ORDER BY OrderDate 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM revenues
),

cumulative_spend_pctg AS (
    SELECT
        *,
        100.0*cumulative_revenue/MAX(cumulative_revenue) OVER (
            PARTITION BY CustomerID 
        ) AS pct_lifetime_revenue
    FROM cumulative_spends
)

SELECT *,
	CASE
		WHEN pct_lifetime_revenue < 50 THEN 0 
		WHEN pct_lifetime_revenue >= 50 AND LAG(pct_lifetime_revenue)  OVER (
			PARTITION BY CustomerID ORDER BY OrderDate
		) < 50 THEN 1 
		ELSE 0
	END AS crossed_50_pct_flag
FROM cumulative_spend_pctg

-- Optimized by index on:
-- Orders(CustomerID, OrderDate), OrderItems(OrderID)

-- Practice 4
EXPLAIN QUERY PLAN
with order_products AS (
    SELECT
        oi.OrderID,
        oi.ProductID,
        p.ProductName
    FROM OrderItems oi
    JOIN Products p ON oi.ProductID = p.ProductID
    group by oi.OrderID, oi.ProductID, p.ProductName
),

product_pairs AS (
    SELECT
        op1.ProductID AS ProductA,
        op1.ProductName AS ProductAName,
        op2.ProductID AS ProductB,
        op2.ProductName AS ProductBName,
        COUNT(*) AS pair_count
    FROM order_products op1
    JOIN order_products op2
        ON op1.OrderID = op2.OrderID
        AND op1.ProductID < op2.ProductID
    GROUP BY ProductA, ProductB
    ORDER BY pair_count DESC
),

ranked_pairs AS (
    SELECT *,
        DENSE_RANK() OVER (
            ORDER BY pair_count DESC
        ) AS rn
    FROM product_pairs
)

SELECT
    *
FROM ranked_pairs
WHERE rn <= 10



-- Practice 6
EXPLAIN QUERY PLAN
with clv as (
    select 
        o.CustomerID,
        sum(oi.Sales) AS lifetime_revenue,
        avg(oi.Sales) as avg_order_value,
        count(o.OrderID) as orders_count,
        julianday(max(o.OrderDate)) 
        - 
        julianday(min(o.OrderDate)) AS lifetime_days
    FROM Orders o
    JOIN OrderItems oi ON o.OrderID = oi.OrderID
    GROUP BY CustomerID
)

select CustomerID, 
    lifetime_revenue, 
    avg_order_value, 
    orders_count, 
    lifetime_days,
    DENSE_RANK() OVER (
        ORDER BY lifetime_revenue DESC
    ) AS customer_rank
from clv