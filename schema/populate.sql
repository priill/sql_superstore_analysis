/*
    Populate the Customers, Products, Orders, and OrderItems tables
    from the Superstore table.
*/

-- Populate Customers from Superstore
INSERT INTO Customers (
    CustomerID,
    CustomerName,
    Segment
)
SELECT DISTINCT
    CustomerID,
    CustomerName,
    Segment
FROM Superstore;

-- Populate Products from Superstore
-- Handle duplicate products (64 items) by selecting the most frequent variant
WITH variant_counts AS (
    SELECT
        ProductID,
        ProductName,
        Category,
        SubCategory,
        COUNT(*) AS cnt
    FROM Superstore
    GROUP BY
        ProductID,
        ProductName,
        Category,
        SubCategory
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ProductID
            ORDER BY cnt DESC, ProductName
        ) AS rn
    FROM variant_counts
)
INSERT INTO Products (
    ProductID,
    ProductName,
    Category,
    SubCategory,
    Price
)
SELECT
    ProductID,
    ProductName,
    Category,
    SubCategory,
    ROUND(Sales / NULLIF(Quantity, 0), 2) AS Price
FROM ranked
WHERE rn = 1;


-- Populate Orders from Superstore --
-- Handle date format conversion from M/D/YYYY to YYYY-MM-DD
WITH dates AS (
    SELECT
        *,
        instr(OrderDate, '/') AS s1,
        instr(substr(OrderDate, instr(OrderDate,'/')+1), '/') 
            + instr(OrderDate,'/') AS s2,
        instr(ShipDate, '/') AS ss1,
        instr(substr(ShipDate, instr(ShipDate,'/')+1), '/') 
            + instr(ShipDate,'/') AS ss2
    FROM Superstore
)

INSERT INTO Orders (
    OrderID,
    CustomerID,
    OrderDate,
    ShipDate,
    ShipMode,
    Country,
    City,
    State,
    PostalCode,
    Region
)

SELECT DISTINCT
    OrderID,
    CustomerID,

    CASE
        -- M/D/YYYY
        WHEN s1 = 2 AND s2 = 4 THEN
            substr(OrderDate, s2+1, 4) || '-0' ||
            substr(OrderDate, 1, 1) || '-0' ||
            substr(OrderDate, 3, 1)

        -- M/DD/YYYY
        WHEN s1 = 2 AND s2 = 5 THEN
            substr(OrderDate, s2+1, 4) || '-0' ||
            substr(OrderDate, 1, 1) || '-' ||
            substr(OrderDate, 3, 2)

        -- MM/D/YYYY
        WHEN s1 = 3 AND s2 = 5 THEN
            substr(OrderDate, s2+1, 4) || '-' ||
            substr(OrderDate, 1, 2) || '-0' ||
            substr(OrderDate, 4, 1)

        -- MM/DD/YYYY
        WHEN s1 = 3 AND s2 = 6 THEN
            substr(OrderDate, s2+1, 4) || '-' ||
            substr(OrderDate, 1, 2) || '-' ||
            substr(OrderDate, 4, 2)
    END AS OrderDate,

    CASE
        WHEN ss1 = 2 AND ss2 = 4 THEN
            substr(ShipDate, ss2+1, 4) || '-0' ||
            substr(ShipDate, 1, 1) || '-0' ||
            substr(ShipDate, 3, 1)

        WHEN ss1 = 2 AND ss2 = 5 THEN
            substr(ShipDate, ss2+1, 4) || '-0' ||
            substr(ShipDate, 1, 1) || '-' ||
            substr(ShipDate, 3, 2)

        WHEN ss1 = 3 AND ss2 = 5 THEN
            substr(ShipDate, ss2+1, 4) || '-' ||
            substr(ShipDate, 1, 2) || '-0' ||
            substr(ShipDate, 4, 1)

        WHEN ss1 = 3 AND ss2 = 6 THEN
            substr(ShipDate, ss2+1, 4) || '-' ||
            substr(ShipDate, 1, 2) || '-' ||
            substr(ShipDate, 4, 2)
    END AS ShipDate,

    ShipMode,
    Country,
    City,
    State,
    PostalCode,
    Region
FROM dates;

-- Populate OrderItems from Superstore
INSERT INTO OrderItems (
    OrderID,
    ProductID,
    Quantity,
    Sales,
    Discount,
    Profit
)
SELECT
    OrderID,
    ProductID,
    Quantity,
    Sales,
    Discount,
    Profit
FROM Superstore;
