
/* 

Scenario 7 — “Are we mistaking noise for growth?”

Month-over-month revenue looks volatile.
Before we celebrate or panic, I need to know:
- Is this volatility coming from customer behaviour?
- Or from order size?
- Or from product mix?

I want to separate structural change from random fluctuation.

*/

-- Analyze month-over-month revenue volatility

with monthly_metrics as (
    select 
        strftime('%Y-%m', o.OrderDate) as order_month,
        round(sum(oi.Sales),2) as total_sales,
        count(distinct o.CustomerID) as unique_customers,
        count(oi.OrderID) as total_orders,
        count(distinct oi.ProductID) as unique_products
    from Orders o
    join OrderItems oi on o.OrderID = oi.OrderID
    group by order_month
    ORDER BY order_month
),
growth_rates as (
    select 
        order_month,
        total_sales,
        total_sales / cast(total_orders as float) as aov,
        cast(total_orders as float) / unique_customers as order_freq,
        total_sales / cast(unique_products as float) as sales_per_sku
    from monthly_metrics
)
select 
    order_month,
    round(total_sales, 2) as sales,
    round((total_sales - lag(total_sales) over (order by order_month)) / lag(total_sales) over (order by order_month) * 100, 2) as sales_growth_pct,
    round(aov, 2) as aov,
    round((aov - lag(aov) over (order by order_month)) / lag(aov) over (order by order_month) * 100, 2) as aov_growth_pct,
    round(order_freq, 2) as avg_orders_per_customer,
    round((order_freq - lag(order_freq) over (order by order_month)) / lag(order_freq) over (order by order_month) * 100, 2) as freq_growth_pct,
    round(sales_per_sku, 2) as sales_per_product,
    round((sales_per_sku - lag(sales_per_sku) over (order by order_month)) / lag(sales_per_sku) over (order by order_month) * 100, 2) as sales_per_sku_growth_pct 
from growth_rates;
/*

order_month	sales	sales_growth_pct	aov	aov_growth_pct	avg_orders_per_customer	freq_growth_pct	sales_per_product	sales_per_sku_growth_pct
2014-01	14236.9	    NULL	180.21	NULL	2.47	NULL	182.52	NULL
2014-02	4519.89	    -68.25	98.26	-45.48	1.7	    -30.99	100.44	-44.97
2014-03	55691.01	1132.13	354.72	261.01	2.28	33.55	368.81	267.19 --> 1st significant spike in sales, AOV, and sales per product
2014-04	28295.35	-49.19	209.6	-40.91	2.11	-7.29	216.0	-41.44
2014-05	23648.29	-16.42	193.84	-7.52	1.82	-13.68	205.64	-4.8
2014-06	34595.13	46.29	256.26	32.2	2.14	17.68	260.11	26.49
2014-07	33946.39	-1.88	237.39	-7.36	2.2	    2.67	245.99	-5.43
2014-08	27909.47	-17.78	182.41	-23.16	2.19	-0.65	191.16	-22.29
2014-09	81777.35	193.01	305.14	67.28	2.27	3.91	332.43	73.9 --> 3rd significant spike
2014-10	31453.39	-61.54	197.82	-35.17	2.12	-6.66	205.58	-38.16
2014-11	78628.72	149.98	247.26	24.99	2.29	7.91	269.28	30.99
2014-12	69545.62	-11.55	250.16	1.17	2.07	-9.32	269.56	0.1
2015-01	18174.08	-73.87	313.35	25.26	2.07	-0.15	313.35	16.25
2015-02	11951.41	-34.24	186.74	-40.4	1.78	-14.18	189.7	-39.46
2015-03	38726.25	224.03	280.63	50.28	1.79	0.81	286.86	51.21 --> 2nd significant spike
2015-04	34195.21	-11.7	213.72	-23.84	2.32	29.38	224.97	-21.58
2015-05	30131.69	-11.88	206.38	-3.43	2.12	-8.75	216.77	-3.64
2015-06	24797.29	-17.7	179.69	-12.93	2.03	-4.09	186.45	-13.99
2015-07	28765.33	16.0	205.47	14.34	2.19	7.79	224.73	20.53
2015-08	36898.33	28.27	232.06	12.95	2.48	13.57	244.36	8.74
2015-09	64595.92	75.06	220.46	-5.0	2.33	-6.4	238.36	-2.45
2015-10	31404.92	-51.38	189.19	-14.19	2.1	    -9.64	201.31	-15.54
2015-11	75972.56	141.91	234.48	23.94	2.22	5.61	254.94	26.64
2015-12	74919.52	-1.39	237.09	1.11	2.24	0.99	257.46	0.99
2016-01	18542.49	-75.25	208.34	-12.12	1.93	-13.67	208.34	-19.08
2016-02	22978.82	23.93	276.85	32.88	1.98	2.14	283.69	36.16
2016-03	51715.88	125.06	317.28	14.6	2.04	3.1	    335.82	18.38
2016-04	38750.04	-25.07	227.94	-28.16	2.05	0.52	234.85	-30.07
2016-05	56987.73	47.06	253.28	11.12	2.34	14.43	272.67	16.1
2016-06	40344.53	-29.2	202.74	-19.96	2.21	-5.66	216.91	-20.45
2016-07	39261.96	-2.68	195.33	-3.65	2.26	2.14	203.43	-6.21
2016-08	31115.37	-20.75	176.79	-9.49	2.05	-9.38	185.21	-8.96
2016-09	73410.02	135.93	202.23	14.39	2.06	0.78	224.5	21.21
2016-10	59687.75	-18.69	304.53	50.58	2.06	0.03	320.9	42.94
2016-11	79411.97	33.05	214.63	-29.52	2.24	8.69	235.64	-26.57
2016-12	96999.04	22.15	275.57	28.39	2.24	-0.02	307.93	30.68
2017-01	43971.37	-54.67	283.69	2.95	2.31	3.18	289.29	-6.06
2017-02	20301.13	-53.83	189.73	-33.12	2.02	-12.73	193.34	-33.16
2017-03	58872.35	190.0	247.36	30.38	2.07	2.51	264.0	36.54
2017-04	36521.54	-37.96	179.91	-27.27	1.86	-10.01	188.26	-28.69
2017-05	44261.11	21.19	182.9	1.66	2.14	14.99	197.59	4.96
2017-06	52981.73	19.7	216.25	18.24	2.08	-3.05	230.36	16.58
2017-07	45264.42	-14.57	200.29	-7.38	2.22	6.71	212.51	-7.75
2017-08	63120.89	39.45	289.55	44.57	2.1	    -5.39	309.42	45.6
2017-09	87866.65	39.2	191.43	-33.89	2.34	11.72	218.57	-29.36
2017-10	77776.92	-11.48	261.0	36.34	2.19	-6.43	285.94	30.82
2017-11	118447.82	52.29	258.06	-1.13	2.13	-3.02	296.86	3.82
2017-12	83829.32	-29.23	181.45	-29.69	2.37	11.49	206.99	-30.28

this means:
- average order value fluctuates significantly month-over-month
- average orders per customer remains relatively stable
- average sales per product also shows volatility

*/

-- hero products on the months with significant sales spikes

with ranked_products as (
    select 
        strftime('%Y-%m', o.OrderDate) as order_month, 
        oi.ProductID, 
        p.ProductName, 
        sum(oi.Quantity) as Quantity, 
        sum(oi.Sales) as total_sales,
        DENSE_RANK() over (
            partition by strftime('%Y-%m', o.OrderDate)
            order by sum(oi.Sales) desc
        ) as sales_rank
    from OrderItems oi
    join Products p on oi.ProductID = p.ProductID
    join Orders o on oi.OrderID = o.OrderID
    where strftime('%Y-%m', o.OrderDate) in ('2014-03', '2015-03', '2014-09')
    group by order_month, oi.ProductID, p.ProductName
), 

limited_ranked_products as (
    select *
    from ranked_products
    where sales_rank <= 5
    order by order_month, sales_rank
),

sales_monthly as (
    SELECT
        strftime('%Y-%m', o.OrderDate) as order_month,
        sum(oi.Sales) as total_sales
    FROM OrderItems oi
    JOIN Orders o ON oi.OrderID = o.OrderID
    WHERE strftime('%Y-%m', o.OrderDate) in ('2014-03', '2015-03', '2014-09')
    GROUP BY order_month
)

select
    l.order_month,
    sum(l.total_sales) as top_5_sales,
    round(s.total_sales,2) as total_sales,
    round(sum(l.total_sales) / s.total_sales * 100,2) as top_5_sales_pct
from limited_ranked_products l
join sales_monthly s on l.order_month = s.order_month
where l.order_month in ('2014-03', '2015-03', '2014-09')
group by l.order_month;


/*

order_month	ProductID	ProductName	Quantity	total_sales	sales_rank
2014-03	TEC-MA-10002412	Cisco TelePresence System EX90 Videoconferencing Unit	6	22638.48	1
2014-03	TEC-PH-10000730	Samsung Galaxy S4 Active	7	3499.93	2
2014-03	OFF-ST-10000078	Tennsco 6- and 18-Compartment Lockers	7	1856.19	3
2014-03	FUR-TA-10003473	Bretford Rectangular Conference Table Tops	7	1579.746	4
2014-03	TEC-MA-10001148	Swingline SM12-08 MicroCut Jam Free Shredder	4	1279.968	5
2014-09	OFF-BI-10001120	Ibico EPK-21 Electric Binding System	5	9449.95	1
2014-09	TEC-MA-10000822	Lexmark MX611dhe Monochrome Laser Printer	8	8159.952	2
2014-09	FUR-CH-10002024	HON 5400 Series Task Chairs for Big and Tall	6	3785.292	3
2014-09	TEC-MA-10000822	Lexmark MX611dhe Monochrome Laser Printer	3	3059.982	4
2014-09	TEC-MA-10003979	Ativa V4110MDD Micro-Cut Shredder	4	2799.96	5
2015-03	OFF-BI-10003527	Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind	5	6354.95	1
2015-03	FUR-TA-10001889	Bush Advantage Collection Racetrack Conference Table	8	3393.68	2
2015-03	TEC-CO-10001766	Canon PC940 Copier	7	3149.93	3
2015-03	TEC-PH-10001795	ClearOne CHATAttach 160 -�speaker phone	3	1487.976	4
2015-03	OFF-ST-10000142	Deluxe Rollaway Locking File with Drawer	3	1247.64	5

Cisco TelePresence System EX90 Videoconferencing Unit is the hero product 
for the significant sales spikes in March 2014, while Ibico EPK-21 Electric 
Binding System is the hero product for the September 2014 spike. 
This indicates that these products might have contributed significantly 
to the sales spikes during those months.

order_month	top_5_sales	total_sales	top_5_sales_pct
2014-03	31606.964	55691.01	56.75
2014-09	29961.896	81777.35	36.64
2015-03	15634.176	38726.25	40.37

top 5 products accounted for a significant portion of total sales 
during the spike in March 2014: 56.75% --> Noise from a few products

*/