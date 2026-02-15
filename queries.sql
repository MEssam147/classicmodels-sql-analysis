-- =========================================
-- CLASSICMODELS SQL ANALYSIS PROJECT
-- Author: Mohamed Essam
-- =========================================


-- =========================================
-- 1. Calculate total sales value per order
-- =========================================
WITH Sales_CTE AS (
    SELECT T1.orderNumber,
           T1.orderDate,
           T1.customerNumber,
           SUM(T2.quantityOrdered * T2.priceEach) AS Sales_Value
    FROM orders T1
    INNER JOIN orderdetails T2
        ON T1.orderNumber = T2.orderNumber
    GROUP BY T1.orderNumber, T1.orderDate, T1.customerNumber
)
SELECT *
FROM Sales_CTE;


-- ==============================================================
-- 2. Analyze customer purchase sequence and change in order value
-- ==============================================================
WITH First_CTE AS (
    SELECT T1.orderNumber,
           T1.orderDate,
           T3.customerName,
           SUM(T2.quantityOrdered * T2.priceEach) AS Sales_Value
    FROM orders T1
    INNER JOIN orderdetails T2 ON T1.orderNumber = T2.orderNumber
    INNER JOIN customers T3 ON T1.customerNumber = T3.customerNumber
    GROUP BY T1.orderNumber, T1.orderDate, T3.customerName
),
Second_CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customerName ORDER BY orderDate) AS Purchase_Number,
           LAG(Sales_Value) OVER (PARTITION BY customerName ORDER BY orderDate) AS Prev_Sales
    FROM First_CTE
)
SELECT *,
       Sales_Value - Prev_Sales AS Change_in_Sales
FROM Second_CTE
WHERE Prev_Sales IS NOT NULL;


-- ==========================================================================
-- 3. Segment customers by credit limit and count total customers per segment
-- ==========================================================================


SELECT 
    CASE 
        WHEN creditLimit < 75000 THEN 'A: Less than 75K'
        WHEN creditLimit BETWEEN 75000 AND 100000 THEN 'B: 75K - 100K'
        WHEN creditLimit BETWEEN 100000 AND 150000 THEN 'C: 100K - 150K'
        WHEN creditLimit > 150000 THEN 'D: More than 150K'
        ELSE 'Other'
    END AS Credit_Limit_Group,
    COUNT(DISTINCT customerNumber) AS Total_Customers
FROM customers
GROUP BY Credit_Limit_Group;


-- =======================================================
-- 4. Analyze sales by product line and customer geography
-- =======================================================


WITH First_CTE AS (
    SELECT T1.orderNumber,
           T3.productLine,
           T4.country AS Customer_Country,
           SUM(T2.quantityOrdered * T2.priceEach) AS Sales_Value
    FROM orders T1
    INNER JOIN orderdetails T2 ON T1.orderNumber = T2.orderNumber
    INNER JOIN products T3 ON T2.productCode = T3.productCode
    INNER JOIN customers T4 ON T1.customerNumber = T4.customerNumber
    GROUP BY T1.orderNumber, T3.productLine, T4.country
)
SELECT productLine,
       Customer_Country,
       SUM(Sales_Value) AS Total_Sales
FROM First_CTE
GROUP BY productLine, Customer_Country
ORDER BY Total_Sales DESC;


-- ===================================================
-- 5. Perform time-based analysis using date functions
-- ===================================================


SELECT orderNumber,
       orderDate,
       DATEDIFF(NOW(), orderDate) AS Days_Since_Order,
       DATE_ADD(orderDate, INTERVAL 1 YEAR) AS One_Year_After,
       DATE_SUB(orderDate, INTERVAL 2 MONTH) AS Two_Months_Ago
FROM orders;


-- ======================================
-- 6. Identify customers' second purchase
-- ======================================


WITH main_cte AS (
    SELECT T3.customerName,
           T1.orderNumber,
           T1.orderDate,
           ROW_NUMBER() OVER (
               PARTITION BY T3.customerName
               ORDER BY T1.orderDate
           ) AS Purchase_Number
    FROM orders T1
    JOIN customers T3 ON T1.customerNumber = T3.customerNumber
)
SELECT *
FROM main_cte
WHERE Purchase_Number = 2;
