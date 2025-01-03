-- RFM Analysis
/*
EDA : Exploratory Data Analysis
	1. Total no. of purchasing countries, customers, purchasing customers, customers with no purchase. 
    
    -- PURCHASING COUNTRIES

    2. Total no. of products, productlines 
	3. % of total customers for each country
    4. Customer Count for each purchase-frequency -- SUBQUERY
            +---------------------+--------------------+
            | purchase_frequency  | customer_count     |
            +---------------------+--------------------+
            | 5					  | 10                 |
            +---------------------+--------------------+
	5. Top 3 selling products from each productLine
    6. Top 3 selling products from each Country
*/

-- RFM
/*
Step 1: Calculate recent_order_date, total_orders and spending for each customer
Step 2: Categorize recent_order_date, total_orders and spending of customers into 3 equal size bins as
		rfm_recency, rfm_frequency, rfm_monetary respectively
Step 3: Segment Customers based on their rfm values as
		'High-Value customers': rfm = 111,
        'Loyal customers': rfm IN (112,113, 211, 212, 213)
        'New Customers': rfm = 133
        'Lost Customers': else
*/
WITH rfm_data AS (
    SELECT 
        c.customerNumber,
        DATEDIFF(CURDATE(), MAX(p.paymentDate)) AS recent_order_days,
        COUNT(p.checkNumber) AS total_orders,
        SUM(p.amount) AS total_spending
    FROM 
        customers c
    INNER JOIN 
        payments p
    ON 
        c.customerNumber = p.customerNumber
    GROUP BY 
        c.customerNumber
),
rfm_bins AS (
    SELECT 
        customerNumber,
        recent_order_days,
        total_orders,
        total_spending,
        NTILE(3) OVER (ORDER BY recent_order_days ASC) AS rfm_recency, -- Lower values are better
        NTILE(3) OVER (ORDER BY total_orders DESC) AS rfm_frequency, -- Higher values are better
        NTILE(3) OVER (ORDER BY total_spending DESC) AS rfm_monetary -- Higher values are better
    FROM 
        rfm_data
)
SELECT 
    customerNumber,
    recent_order_days,
    total_orders,
    total_spending,
    rfm_recency,
    rfm_frequency,
    rfm_monetary,
	concat(rfm_recency , rfm_frequency , rfm_monetary) as rfm,
    case
		when concat(rfm_recency , rfm_frequency , rfm_monetary) in ( 111,222,333,444) then 'High Value Customer'
        when concat(rfm_recency , rfm_frequency , rfm_monetary) in (112,113, 211, 212, 213) then 'Loyal customers'
        when concat(rfm_recency , rfm_frequency , rfm_monetary) = 133 then  'New Customers'
        else 'Lost Customer'
	end as Customer_Type
         
FROM 
    rfm_bins
ORDER BY 
    customerNumber;
    




USE classicmodels;

# EDA : Exploratory Data Analysis
-- 1. Total no. of purchasing countries, customers, purchasing customers, customers with no purchase.
-- countries with purchasing customers
SELECT COUNT(DISTINCT country) AS purchasing_countries_count 
FROM customers
WHERE customerNumber IN (SELECT DISTINCT customerNumber FROM orders);
-- total with total customers
SELECT COUNT(DISTINCT customerNumber) AS customers_count FROM customers;
--  total purchasing customers
SELECT COUNT(DISTINCT customerNumber) AS purchasing_customers_count FROM orders;
-- total non-purchasing customers
SELECT COUNT(c.customerNumber)
FROM customers c LEFT JOIN orders o ON c.customerNumber = o.customerNumber
WHERE orderNumber IS NULL;

-- 2. Total no. of products, productlines 
SELECT
	COUNT(DISTINCT productCode) AS products_count,
    COUNT(DISTINCT productLine) AS productlines_count
FROM products;

-- 3. % of total customers for each country
SELECT
	country,
    COUNT(customerNumber) customer_count,
    COUNT(customerNumber)/(SELECT COUNT(DISTINCT customerNumber) FROM customers) AS `% of total`
FROM customers
GROUP BY country;

-- 4. Customer Count for each purchase-frequency 
SELECT
	purchase_frequency,
    COUNT(customerNumber) AS customer_count
FROM ( SELECT
		customerNumber,
		COUNT(orderNumber) AS purchase_frequency
FROM orders
GROUP BY customerNumber) t1
GROUP BY purchase_frequency
ORDER BY purchase_frequency DESC;

-- 5. Top 3 selling products from each productLine
SELECT
	productLine, productCode, productName, total_selling
FROM (
		SELECT *, 
			DENSE_RANK() OVER (PARTITION BY productLine ORDER BY total_selling DESC) _DRANK
		FROM (
		SELECT
			p.productLine,
			p.productCode,
			p.productName,
			SUM(d.quantityOrdered) AS total_selling
		FROM products p INNER JOIN orderDetails d ON p.productCode = d.productCode
		GROUP BY p.productLine, p.productCode, p.productName) t1) t2
WHERE _DRANK <= 3;

-- 6. Top 3 selling products from each Country
SELECT
	country,
	productCode,	
	total_selling
FROM (
		SELECT *,
			DENSE_RANK() OVER (PARTITION BY country ORDER BY total_selling DESC) _DRANK
		FROM (	SELECT
					country,
					d.productCode,
					SUM(quantityOrdered) AS total_selling
				FROM customers c
				INNER JOIN orders o ON c.customerNumber = o.customerNumber
				INNER JOIN orderdetails d ON o.orderNumber = d.orderNumber
				GROUP BY country, d.productCode) t1) t2
WHERE _DRANK <= 3;




    
    






 




















