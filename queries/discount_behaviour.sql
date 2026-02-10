/*

Scenario 3 — “Discounts make me nervous”

We keep running discounts, and sales do go up — but I’m not convinced profit follows.

I want to understand:
- Whether discounted orders behave differently from non-discounted ones
- If customers who buy discounted items are actually good long-term customers

*/

-- Analyze order-level behavior based on discount usage
with discount_flag as (
    select
        OrderID, Quantity, Sales, Profit,
        case 
            when Discount > 0 then 1 else 0 
        end as flag  
    from OrderItems
),

discounted_orders as (
    select 
        OrderID, 
        sum(Quantity) as total_quantity, 
        sum(Sales) as total_sales, 
        sum(Profit) as total_profit,
        max(flag)  as disc_flag
    FROM discount_flag
    GROUP BY OrderID
)

select 
    disc_flag, 
    avg(total_quantity) as avg_quantity,
    avg(total_profit) as avg_profit
from discounted_orders
group by disc_flag;

/* 
disc_flag	avg_quantity	avg_profit
0	7.7070328755722	132.841182979609
1	7.42632386799693	-12.594144666155

while average quantity per order is not significantly different, 
the average profit shows a contrasting number, 
meaning discount correlates with the avg_profit
*/

-- Analyze customer-level behavior based on discount usage
with customer_discount_flag as (
    select
        o.CustomerID,
        julianday(
            max(o.OrderDate) over (partition by o.CustomerID)
        ) - julianday(
            min(o.OrderDate) over (partition by o.CustomerID)
        ) as customer_lifespan_days,
        sum(oi.Sales) over (partition by o.CustomerID) as total_sales,
        sum(oi.Profit) over (partition by o.CustomerID) as total_profit,
        case 
            when max(oi.Discount) over (partition by o.CustomerID) > 0 then 1 else 0 
        end as flag  
    from OrderItems oi
    join Orders o on oi.OrderID = o.OrderID
)

select 
    flag,
    avg(customer_lifespan_days) as avg_customer_lifespan_days,
    avg(total_sales) as avg_total_sales,
    avg(total_profit) as avg_total_profit
from customer_discount_flag
group by flag;

/*

flag	avg_customer_lifespan_days	avg_total_sales	avg_total_profit
0	701.379310344828	1014.57643678161	244.060825287356
1	1065.4934894519	3616.3434454729	456.961002321591

Customers who have purchased discounted items tend to have a longer lifespan on average,
average lifetime sales, and average lifetime profit; indicating that they might be better 
long-term customers despite the discounts. However, further analysis on how significant 
this difference should be conducted.

*/