CREATE TABLE superstore (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(50) NOT NULL,
    order_date VARCHAR(10) NOT NULL,
    ship_date VARCHAR(10) NOT NULL,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50) NOT NULL,
    customer_name VARCHAR(255),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    product_name VARCHAR(255),
    sales DECIMAL(10, 2),
    quantity INT,
    discount DECIMAL(5, 2),
    profit DECIMAL(10, 4)
);

-- Create Superstore Database Tables

-- 1. CUSTOMERS Table
CREATE TABLE Customers (
    CustomerID VARCHAR(50) PRIMARY KEY,
    CustomerName VARCHAR(255) NOT NULL,
    Segment VARCHAR(50) NOT NULL
);

-- 2. PRODUCTS Table
CREATE TABLE Products (
    ProductID VARCHAR(50) PRIMARY KEY,
    ProductName VARCHAR(255) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    SubCategory VARCHAR(100) NOT NULL,
    Price DECIMAL(10, 2)
);

-- 3. ORDERS Table
CREATE TABLE Orders (
    OrderID VARCHAR(50) PRIMARY KEY,
    CustomerID VARCHAR(50) NOT NULL,
    OrderDate DATE NOT NULL,
    ShipDate DATE,
    ShipMode VARCHAR(50),
    Country VARCHAR(100),
    City VARCHAR(100),
    State VARCHAR(100),
    PostalCode VARCHAR(20),
    Region VARCHAR(50)
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- 4. ORDER_ITEMS Table (Line Items)
CREATE TABLE OrderItems (
    OrderItemID INTEGER PRIMARY KEY,
    OrderID VARCHAR(50) NOT NULL,
    ProductID VARCHAR(50) NOT NULL,
    Quantity INT NOT NULL,
    Sales DECIMAL(10, 2) NOT NULL,
    Discount DECIMAL(5, 4),
    Profit DECIMAL(10, 2),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);