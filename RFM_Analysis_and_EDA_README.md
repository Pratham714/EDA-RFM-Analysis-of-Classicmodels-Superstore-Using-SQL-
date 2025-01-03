
# RFM Analysis and EDA using SQL

## Description
This repository contains SQL queries for performing **RFM Analysis** and **Exploratory Data Analysis (EDA)** on the `classicmodels` dataset. The objective is to understand customer behavior and categorize customers based on their purchasing patterns and RFM values.

### Key Components:
1. **RFM Analysis**
   - Calculate `recent_order_date`, `total_orders`, and `spending` for each customer.
   - Categorize customers into bins for **Recency**, **Frequency**, and **Monetary**.
   - Segment customers into categories: `High-Value customers`, `Loyal customers`, `New Customers`, and `Lost Customers`.

2. **EDA (Exploratory Data Analysis)**
   - Analyze purchasing trends by country, product, and customer behavior.
   - Insights include the number of purchasing customers, non-purchasing customers, product lines, and top-selling products by product line and country.

---

## RFM Analysis
### Steps:
1. **Calculate RFM Metrics**:
   - `recent_order_date`: Days since the last order.
   - `total_orders`: Number of orders by each customer.
   - `spending`: Total spending of each customer.

2. **Bin RFM Values**:
   - Divide `recent_order_date`, `total_orders`, and `spending` into 3 equal-size bins using the `NTILE(3)` function.

3. **Segment Customers**:
   - Categorize customers based on their RFM values into the following segments:
     - **High-Value Customers**: RFM = 111
     - **Loyal Customers**: RFM IN (112,113, 211, 212, 213)
     - **New Customers**: RFM = 133
     - **Lost Customers**: All others

### Query:
```sql
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
        NTILE(3) OVER (ORDER BY recent_order_days ASC) AS rfm_recency,
        NTILE(3) OVER (ORDER BY total_orders DESC) AS rfm_frequency,
        NTILE(3) OVER (ORDER BY total_spending DESC) AS rfm_monetary
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
    CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS rfm,
    CASE
        WHEN CONCAT(rfm_recency, rfm_frequency, rfm_monetary) = '111' THEN 'High-Value Customer'
        WHEN CONCAT(rfm_recency, rfm_frequency, rfm_monetary) IN ('112', '113', '211', '212', '213') THEN 'Loyal Customer'
        WHEN CONCAT(rfm_recency, rfm_frequency, rfm_monetary) = '133' THEN 'New Customer'
        ELSE 'Lost Customer'
    END AS Customer_Type
FROM 
    rfm_bins
ORDER BY 
    customerNumber;
```

---

## EDA: Exploratory Data Analysis

### Queries and Insights:

1. **Total Number of Purchasing Countries, Customers, and Non-Purchasing Customers**:
```sql
-- Purchasing countries
SELECT COUNT(DISTINCT country) AS purchasing_countries_count 
FROM customers
WHERE customerNumber IN (SELECT DISTINCT customerNumber FROM orders);

-- Total customers
SELECT COUNT(DISTINCT customerNumber) AS customers_count FROM customers;

-- Purchasing customers
SELECT COUNT(DISTINCT customerNumber) AS purchasing_customers_count FROM orders;

-- Non-purchasing customers
SELECT COUNT(c.customerNumber)
FROM customers c LEFT JOIN orders o ON c.customerNumber = o.customerNumber
WHERE orderNumber IS NULL;
```

2. **Total Number of Products and Product Lines**:
```sql
SELECT
    COUNT(DISTINCT productCode) AS products_count,
    COUNT(DISTINCT productLine) AS productlines_count
FROM products;
```

3. **Percentage of Total Customers for Each Country**:
```sql
SELECT
    country,
    COUNT(customerNumber) AS customer_count,
    COUNT(customerNumber)/(SELECT COUNT(DISTINCT customerNumber) FROM customers) AS percentage_of_total
FROM customers
GROUP BY country;
```

4. **Customer Count for Each Purchase-Frequency**:
```sql
SELECT
    purchase_frequency,
    COUNT(customerNumber) AS customer_count
FROM ( 
    SELECT
        customerNumber,
        COUNT(orderNumber) AS purchase_frequency
    FROM orders
    GROUP BY customerNumber
) t1
GROUP BY purchase_frequency
ORDER BY purchase_frequency DESC;
```

5. **Top 3 Selling Products from Each Product Line**:
```sql
SELECT
    productLine, productCode, productName, total_selling
FROM (
    SELECT *, 
        DENSE_RANK() OVER (PARTITION BY productLine ORDER BY total_selling DESC) AS rank
    FROM (
        SELECT
            p.productLine,
            p.productCode,
            p.productName,
            SUM(d.quantityOrdered) AS total_selling
        FROM products p INNER JOIN orderDetails d ON p.productCode = d.productCode
        GROUP BY p.productLine, p.productCode, p.productName
    ) t1
) t2
WHERE rank <= 3;
```

6. **Top 3 Selling Products from Each Country**:
```sql
SELECT
    country,
    productCode,
    total_selling
FROM (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY country ORDER BY total_selling DESC) AS rank
    FROM (
        SELECT
            c.country,
            d.productCode,
            SUM(quantityOrdered) AS total_selling
        FROM customers c
        INNER JOIN orders o ON c.customerNumber = o.customerNumber
        INNER JOIN orderdetails d ON o.orderNumber = d.orderNumber
        GROUP BY country, d.productCode
    ) t1
) t2
WHERE rank <= 3;
```

---

## Usage
- Import the SQL queries into your preferred database management system (e.g., MySQL Workbench).
- Execute the queries step by step to perform RFM analysis and EDA on the dataset.

---

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments
- Dataset: `classicmodels`
- SQL Concepts: Window Functions, Aggregate Functions, and Conditional Logic
