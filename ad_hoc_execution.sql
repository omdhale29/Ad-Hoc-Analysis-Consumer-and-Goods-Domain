# Request_1:  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 
SELECT market FROM dim_customer
WHERE region = "APAC" AND customer = "Atliq Exclusive";

-- ------------------------------------------------------------------------------------------------------------------------------------

# Request_2:  What is the percentage of unique product increase in 2021 vs. 2020? The  final output contains these fields, 
-- unique_products_2020, unique_products_2021, percentage_chg

WITH CTE2 AS (SELECT 
COUNT(DISTINCT CASE WHEN fiscal_year=2020 THEN (product_code)END) AS products2020,
COUNT(DISTINCT CASE WHEN fiscal_year=2021 THEN (product_code)END) AS products2021
FROM fact_sales_monthly)
SELECT *, 
    ROUND((products2021 - products2020)/products2020*100,2)AS pct_change 
FROM CTE2;

-- ------------------------------------------------------------------------------------------------------------------------------------

# Request_3:  Provide a report with all the unique product counts for each  segment  
-- and sort them in descending order of product counts. The final output contains 2 fields, segment, product_count

SELECT segment, COUNT(product_code) AS unique_products 
FROM dim_product
GROUP BY segment
ORDER BY unique_products DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------

# Request_4:  Follow-up: Which segment had the most increase 
-- in unique products in 2021 vs 2020? The final output contains 
-- these fields, segment, product_count_2020, product_count_2021, difference 

WITH CTE3 AS
(SELECT segment, 
COUNT(DISTINCT(CASE WHEN fiscal_year=2020 THEN product_code END)) AS products2020,
COUNT(DISTINCT(CASE WHEN fiscal_year=2021 THEN product_code END)) AS products2021 
FROM fact_sales_monthly
INNER JOIN dim_product USING(product_code)
GROUP BY segment)
SELECT *,
products2021-products2020 AS increment
FROM CTE3 
ORDER BY increment DESC;
-- ------------------------------------------------------------------------------------------------------------------------------------

# Request_5:  Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, product_code, product, manufacturing_cost 


SELECT product_code, product, manufacturing_cost 
FROM fact_manufacturing_cost
INNER JOIN dim_product USING(product_code)
WHERE manufacturing_cost IN (
(SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
);

-- ------------------------------------------------------------------------------------------------------------------------------------

# Request_6:  Generate a report which contains the top 5 customers who received an 
-- average high pre_invoice_discount_pct for the  fiscal  year 2021  and in the Indian  market. 
-- The final output contains these fields, customer_code, customer, average_discount_percentage 

 WITH CTE6 AS 
	(SELECT c.customer_code,customer, ROUND(pre_invoice_discount_pct*100,2) AS pre_invoice_discount_pct,
	 AVG(pre_invoice_discount_pct*100) OVER() AS avg_value
	 FROM dim_customer c 
	 INNER JOIN fact_pre_invoice_deductions pre
	 ON c.customer_code = pre.customer_code
	 WHERE market ="India" AND fiscal_year = 2021)
SELECT CTE6.customer_code, CTE6.customer, CTE6.pre_invoice_discount_pct
FROM CTE6
WHERE pre_invoice_discount_pct > avg_value ORDER BY pre_invoice_discount_pct DESC LIMIT 5;

# Request_7: 

WITH CTE7 AS(
SELECT 
date, s.fiscal_year, sold_quantity, gross_price 
FROM fact_sales_monthly s 
INNER JOIN fact_gross_price USING(fiscal_year, product_code)
INNER JOIN dim_customer USING(customer_code)
WHERE customer= "Atliq Exclusive"
)
SELECT
MONTHNAME(date) Month,
fiscal_year AS fiscal_year,
ROUND(SUM((sold_quantity*gross_price))/1000000,2) AS gross_sales_million
FROM CTE7 
GROUP BY date ORDER BY fiscal_year;

# Request_8: 

WITH CTE8 AS
(select date,MONTH(date),
   CASE WHEN MONTH(date)  IN (9,10,11) THEN 'Q1' 
        WHEN MONTH(date)  IN (12,1,2) THEN 'Q2' 
		WHEN MONTH(date)  IN (3,4,5) THEN 'Q3 '
        WHEN MONTH(date)  IN (6,7,8) THEN 'Q4'END AS quarter,
	fiscal_year, SUM(sold_quantity)AS quantity
FROM fact_sales_monthly 
WHERE fiscal_year=2020
GROUP BY date,quarter)
SELECT quarter,SUM(quantity) AS total_qty
FROM CTE8  
GROUP BY quarter ORDER BY total_qty DESC;

# Request_9: 

WITH CTE9 AS
(SELECT channel,ROUND(SUM(sold_quantity*gross_price)/1000000,2) AS gross_sales_million 
FROM fact_sales_monthly s 
INNER JOIN dim_customer c ON c.customer_code = s.customer_code
INNER JOIN fact_gross_price g ON s.product_code = g.product_code AND 
s.fiscal_year = g.fiscal_year
WHERE s.fiscal_year =2021
GROUP BY channel)
SELECT *, ROUND(gross_sales_million*100/SUM(gross_sales_million) OVER(),2) AS pct
FROM CTE9;

# Request_10: 

WITH CTE11 AS 
(WITH CTE10 AS 
(SELECT p.product_code, division, product,SUM(sold_quantity) AS sold_qty
FROM fact_sales_monthly s 
INNER JOIN dim_product p ON s.product_code = p.product_code
WHERE fiscal_year = 2021
GROUP BY p.product_code,division,p.product ORDER BY division, sold_qty DESC)
SELECT *, DENSE_RANK() OVER (PARTITION BY division ORDER BY sold_qty DESC) AS ranks FROM CTE10 )
SELECT * FROM CTE11 WHERE ranks <=3


