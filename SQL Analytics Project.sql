--------------------------------- SQL PROJECTS ---------------------------------

-- EXPLORATORY DATA ANALYSIS --

/* First of all, imagine all your data as MEASURES and DIMENSIONS, having this in mind, you will
be able to extract a huge amount of insights. Is Data Type = Number? If NO, the Dimension. Does
it make sense to aggregate it? If YES, the MEASURE. If NO, then DIMENSION. */

SELECT DISTINCT
	category
FROM gold.dim_products

SELECT DISTINCT
	sales_amount
FROM gold.fact_sales

-- Explore ALL objects in the Database
SELECT
	*	
FROM INFORMATION_SCHEMA.TABLES

-- Explore All Columns in the Database
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'dim_customers'

							------ DIMENSIONS EXPLORATION ------

-- Identify the unique values (or categories) in each dimension. Recognizing how data might be 
-- grouped or segmented, which is useful for later analysis.

-- Explore All countries our customers come from.
SELECT DISTINCT country
FROM gold.dim_customers

-- Explore All product categories 'The Major Divisions'
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1,2,3

							------ DATE EXPLORATION ------

-- Identify the earliest and latest dates (boundaries). Understand the scope of data and the 
-- timespan. How many years of sales are available?
SELECT 
	MIN(order_date) first_order_date, 
	MAX(order_date) last_order_date,
	DATEDIFF(YEAR, MIN(order_date), MAX(order_date)) order_range_years
FROM gold.fact_sales

-- Find the youngest and oldest customer
SELECT
MIN(birthdate) as oldest_birthdate,
DATEDIFF(YEAR, MIN(birthdate), GETDATE()) AS oldest_age,
MAX(birthdate) as youngest_birthdate,
DATEDIFF(YEAR, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers

							------ MEASURES EXPLORATION ------

-- Calculate the key metric of the business (Big Numbers)- Highest level of Aggregation | Lowest
-- level of Details

-- Find the total sales
SELECT
	FORMAT(SUM(sales_amount), 'N2', 'de-de') + ' €' AS Total_Revenue
FROM gold.fact_sales

--Find how many items are sold
SELECT
	SUM(quantity) AS Total_items_sold
FROM gold.fact_sales

-- Find the average selling price
SELECT
	AVG(price) AS Average_selling_price
FROM gold.fact_sales

-- Find the total number of orders
SELECT
	COUNT(DISTINCT order_number) AS Total_orders
FROM gold.fact_sales

-- Find the total number of product
SELECT
	COUNT(DISTINCT product_id) AS number_of_products
FROM gold.dim_products

-- Find the total number of customers
SELECT
	COUNT(DISTINCT customer_id) as number_of_customers
FROM gold.dim_customers

-- Find the total number of customers that has placed an order
SELECT
	COUNT(DISTINCT customer_key)
FROM gold.fact_sales

-- Generate a Report that shows all key metrics of the business
SELECT
	'Total Sales' AS Measure_name,
	FORMAT(SUM(sales_amount), 'N2', 'de-de') + ' €' AS Measure_value
FROM gold.fact_sales
UNION ALL 
SELECT
	'Total Quantity' AS Measure_name,
	SUM(quantity) AS Measure_value
FROM gold.fact_sales

-- Don't use UNION for different measure types
-- Instead, use separate columns or pivot
SELECT
    'Total Sales' AS Measure_name,
    FORMAT(SUM(sales_amount), 'N2', 'de-de') + ' €' AS Measure_value
FROM gold.fact_sales
UNION ALL 
SELECT
    'Total Quantity' AS Measure_name,
    FORMAT(SUM(quantity), 'N0', 'de-de') AS Measure_value  -- Convert to string
FROM gold.fact_sales
UNION ALL 
SELECT
	'Average Price' AS Measure_name,
	FORMAT(AVG(price), 'N0', 'de-de') AS Measure_value
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Orders' AS Measure_name,
	FORMAT(COUNT(DISTINCT order_number), 'N0', 'de-de') AS Total_orders
FROM gold.fact_sales
UNION ALL
SELECT
	'Total Products' AS Measure_name,
	FORMAT(COUNT(DISTINCT product_id), 'N0', 'de-de') AS Total_number_of_products
FROM gold.dim_products
UNION ALL
SELECT
	'Total Customers' AS Measure_name,
	FORMAT(COUNT(DISTINCT customer_id), 'N0', 'de-de') as number_of_customers
FROM gold.dim_customers

							------ MAGNITUDE ANALYSIS ------

-- Compare the measure values by categories. It helps us understand the importance of different
-- categories.

-- Find the Total Number of Customers by country
SELECT
	country,
	COUNT(DISTINCT customer_id) as Total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY Total_customers DESC

-- Find the total customers by gender
SELECT
	gender,
	COUNT(DISTINCT customer_id) as Total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY Total_customers DESC

-- Find the total products by category
SELECT
	category,
	COUNT(DISTINCT product_id) as Total_products
FROM gold.dim_products
GROUP BY category
ORDER BY Total_products DESC

-- What is the average cost of each category
SELECT
	category,
	AVG(cost) as AVG_cost
FROM gold.dim_products
GROUP BY category
ORDER BY AVG_cost DESC

-- What is the total revenue generated for each category?
SELECT
	p.category,
	FORMAT(SUM(s.price*s.quantity), 'N0', 'de-de') + ' €' as Total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p 
ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY Total_revenue

-- What is the total revenue generated by each customer?
SELECT
	CONCAT(d.first_name, ' ', d.last_name) AS Customer_name,
	FORMAT(SUM(S.sales_amount), 'N0', 'de-de') + ' €' as Total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers d
ON d.customer_key = s.customer_key
GROUP BY CONCAT(d.first_name, ' ', d.last_name)
ORDER BY SUM(S.sales_amount) DESC

-- What is the distribution of sold items across the countries
SELECT
	d.country AS Country,
	FORMAT(SUM(s.price*s.quantity), 'N0', 'de-de') + ' €' as Total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers d
ON d.customer_key = s.customer_key
GROUP BY d.country
ORDER BY SUM(s.price*s.quantity) DESC

							------ RANKING ANALYSIS ------
-- Order the values of dimensions by measure. Top N performers | Bottom N performers

-- Which 5 products generate the highest revenue?
SELECT
	TOP 5 p.product_name AS Product_name,
	FORMAT(SUM(s.sales_amount), 'N0', 'de-de') + ' €' as Total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY SUM(s.sales_amount) DESC

SELECT *
FROM (
	SELECT
		p.product_name AS Product_name,
		FORMAT(SUM(s.sales_amount), 'N0', 'de-de') + ' €' as Total_revenue,
		ROW_NUMBER() OVER (ORDER BY SUM(s.sales_amount) DESC) AS Rank_products
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.product_name)t

WHERE Rank_products <= 5

-- What are the 5 worst-performing product in terms of sales?
SELECT
	TOP 5 p.product_name AS Product_name,
	FORMAT(SUM(s.sales_amount), 'N0', 'de-de') + ' €' as Total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY SUM(s.sales_amount)

-- Find the Top-10 customers who have generated the highest revenue. 
-- And 3 customers with the fewest orders placed.
WITH rank_customers AS (
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS Customer_name,
		COUNT(DISTINCT s.order_number) AS Total_Orders,
		FORMAT(SUM(s.sales_amount), 'N0', 'de-de') + ' €' AS Total_Revenue,
		RANK() OVER (ORDER BY SUM(s.sales_amount) DESC) AS Ranked_Revenues
	FROM gold.dim_customers c
	JOIN gold.fact_sales s
	ON c.customer_key = s.customer_key
	GROUP BY CONCAT(c.first_name, ' ', c.last_name)
)
SELECT
	TOP 10 *
FROM rank_customers;

WITH rank_customers AS (
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS Customer_name,
		COUNT(DISTINCT s.order_number) AS Total_Orders,
		FORMAT(SUM(s.sales_amount), 'N0', 'de-de') + ' €' AS Total_Revenue,
		RANK() OVER (ORDER BY SUM(s.sales_amount) DESC) AS Ranked_Revenues
	FROM gold.dim_customers c
	JOIN gold.fact_sales s
	ON c.customer_key = s.customer_key
	GROUP BY CONCAT(c.first_name, ' ', c.last_name)
)

SELECT
	TOP 3 *
FROM rank_customers
ORDER BY Total_Orders, Ranked_Revenues;

------------------------------ ADVANCED ANALYTICS PROJECT ------------------------------

					     ------ CHANGE-OVER-TIME (trends) ------

-- Analyze Sales Performance Over Time
SELECT
	DATETRUNC(YEAR, order_date) AS Order_date,
	SUM(sales_amount) AS Total_sales,
	COUNT(DISTINCT customer_key) AS Total_customers,
	SUM(quantity) AS Total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR, order_date)
ORDER BY DATETRUNC(YEAR, order_date)

-- Not recommended. Output od order_date will be a string and cannot order months properly
SELECT
	FORMAT(order_date, 'yyyy - MMM') AS Order_date,
	SUM(sales_amount) AS Total_sales,
	COUNT(DISTINCT customer_key) AS Total_customers,
	SUM(quantity) AS Total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy - MMM')
ORDER BY FORMAT(order_date, 'yyyy - MMM')

					     ------ CUMULATIVE ANALYSIS ------
-- Calculate the total sales per month and the running total of sales over time.
SELECT
Order_date,
Month_sales,
SUM(Month_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY  order_date) AS Running_total_sales,
AVG(AVG_price) OVER (PARTITION BY YEAR(order_date) ORDER BY  order_date) AS Moving_average_price
FROM (
	SELECT
		DATETRUNC(MONTH, order_date) AS Order_date,
		SUM(sales_amount) AS Month_sales,
		AVG(Price) AS AVG_price
	FROM gold.fact_sales
	WHERE order_date IS NOT NULL
	GROUP BY DATETRUNC(MONTH, order_date)
	)t

                  ------ PERFORMANCE ANALYSIS (Current VS Target value) ------

-- Analyze the yearly performance of products by comparing each product's sales to both its
-- average sales performance and the previous years's sales.
-- YEAR-OVER-YEAR Analysis
WITH yearly_product_sales AS (
	SELECT
		YEAR(s.order_date) AS Order_year,
		p.product_name,
		SUM(s.sales_amount) AS Current_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	WHERE order_date IS NOT NULL
	GROUP BY YEAR(s.order_date), p.product_name
)

SELECT
	Order_year,
	product_name,
	Current_sales,
	AVG(Current_sales) OVER (PARTITION BY product_name) AS AVG_sales,
	Current_sales - AVG(Current_sales) OVER (PARTITION BY product_name) AS diff_avg,
	CASE WHEN Current_sales - AVG(Current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above AVG'
		 WHEN Current_sales - AVG(Current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below AVG'
		 ELSE 'AVG'
	END avg_change,
	LAG(Current_sales) OVER (PARTITION BY product_name ORDER BY Order_year) AS PY_sales,
	Current_sales - LAG(Current_sales) OVER (PARTITION BY product_name ORDER BY Order_year) AS diff_PY,
	CASE WHEN Current_sales - LAG(Current_sales) OVER (PARTITION BY product_name ORDER BY Order_year) > 0 THEN 'Increase'
		 WHEN Current_sales - LAG(Current_sales) OVER (PARTITION BY product_name ORDER BY Order_year) < 0 THEN 'Decrease'
		 ELSE 'No Change'
	END PY_change
FROM yearly_product_sales
ORDER BY product_name, Order_year

                  ------ PART TO WHOLE ANALYSIS (Proportional) ------

-- Analyze how an individual part is performing compared to the overall, 
-- allowing us to undestand which category has the greatest impact on the business. 

-- Which categories contribute the most to overall sales?
WITH category_sales AS (	
	SELECT
		p.category,
		SUM(s.sales_amount) AS Total_Sales
	FROM gold.fact_sales s
	JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.category
)

SELECT
	category,
	Total_Sales,
	SUM(Total_Sales) OVER () AS Overall_Sales,
	CONCAT(ROUND((CAST (Total_Sales AS FLOAT) / SUM(Total_Sales) OVER ()) * 100, 2), '%') AS Percentage_of_Total
FROM category_sales

							    ------ DATA SEGMENTATION ------

-- Group the data based on a specific range. Helps understand the correlation between two measures

-- Segment products into cost ranges and count how many products fal into each segment.
WITH product_segment AS (
	SELECT
		product_name,
		cost,
		CASE WHEN cost <= 250 THEN 'Cheap'
			 WHEN cost BETWEEN 251 AND 500 THEN 'Normal'
			 WHEN cost BETWEEN 501 AND 1000 THEN 'Expensive'
			 ELSE 'Very Expensive'
			 END Cost_label
	FROM gold.dim_products
)

SELECT
	Cost_label,
	COUNT(product_name) AS Total_Products
FROM product_segment
GROUP BY Cost_label
ORDER BY Total_Products DESC

/* Group customers into three segments based on their spending behaviour:
	- VIP: customers with at least 12 months of history spending more than 5000€.
	- Regular: Customers with at least 12 month of history but spending 5000€ or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group. */
WITH customer_spending  AS (
	SELECT
		c.customer_key,
		SUM(s.sales_amount) AS Total_Expenses,
		MIN(order_date) AS First_Order,
		MAX(order_date) AS Last_Order,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS Lifespan
	FROM gold.fact_sales s
	JOIN gold.dim_customers c
		ON s.customer_key = c.customer_key
	GROUP BY c.customer_key
)
SELECT
	Customer_Segment,
	COUNT(customer_key) AS Total_Customers
FROM (
SELECT
	customer_key,
	Total_Expenses,
	Lifespan,
	CASE WHEN Lifespan >= 12 AND Total_Expenses > 5000 THEN 'VIP'
		 WHEN Lifespan >= 12 AND Total_Expenses <= 5000 THEN 'Regular'
		 ELSE 'New'
	END Customer_Segment
FROM customer_spending
)t
GROUP BY Customer_Segment
ORDER BY Total_Customers DESC

							    ------ BUILD CUSTOMER REPORT ------
/*

Purpose:
	- This report consolidates key customer metrics and behaviors

Highlights:
	1. Gather essential fields such as names, ages and transaction details.
	2. Segment custoemrs into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity purchased
		- total products
		- lifespan (in months)
	4. Calculate valuable KPI's:
		- recency (months since last order)
		- average order value
		- average monthly spend

*/
CREATE VIEW gold.report_customers AS
/*
1) Base Query: Retrieves core columns from tables
*/
WITH base_query AS (
	SELECT
		s.order_number,
		s.product_key,
		s.order_date,
		s.sales_amount,
		s.quantity,
		c.customer_key,
		c.customer_number,
		CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
		DATEDIFF(YEAR, c.birthdate, GETDATE()) age
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON c.customer_key = s. customer_key
	WHERE order_date IS NOT NULL
),

/*
2) Customer Aggregations: Summarizes key metrics at the customer level
*/

customer_aggregation AS (
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order,
	DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS Lifespan
FROM base_query
GROUP BY
	customer_key,
	customer_number,
	customer_name,
	age
)

SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	CASE WHEN age < 20 THEN 'Under 20'
		 WHEN age BETWEEN 20 AND 29 THEN '20-29'
		 WHEN age BETWEEN 30 AND 39 THEN '30-39'
		 WHEN age BETWEEN 40 AND 49 THEN '40-49'
		 WHEN age BETWEEN 50 AND 59 THEN '50-59'
		 WHEN age BETWEEN 60 AND 69 THEN '60-69'
		 WHEN age BETWEEN 70 AND 79 THEN '70-79'
		 ELSE '80+'
	END AS Age_Segment,
	CASE WHEN Lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
		 WHEN Lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
		 ELSE 'New'
	END AS Customer_Segment,
	total_orders,
	-- Compute average order value (AVO)
	CASE WHEN total_orders = 0 THEN	0
		 ELSE total_sales / total_orders
	END AS avg_order_value,
	total_sales,
		-- Compute average monthly spend
	CASE WHEN Lifespan = 0 THEN total_sales
		 ELSE total_sales / Lifespan
	END AS avg_monthly_spend,
	total_quantity,
	total_products,
	last_order,
	DATEDIFF(MONTH, last_order, GETDATE()) AS recency,
	Lifespan
FROM customer_aggregation

SELECT * FROM gold.report_customers

/*

Purpose:
	- This report consolidates key product metrics and behaviors

Highlights:
	1. Gather essential fields such as category, subcatefory and cost.
	2. Segment products by revenur to identify High-Performers, Mid-Range or Low Performers.
	3. Aggregates customer-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months)
	4. Calculate valuable KPI's:
		- recency (months since last sale)
		- average order revenue
		- average monthly revenue

*/
CREATE VIEW gold.report_products AS
/*
1) Base Query: Retrieves core columns from tables
*/
WITH base_query AS (
	SELECT
		s.order_number,
		s.order_date,
		s.customer_key,
		s.sales_amount,
		s.quantity,
		p.product_key,
		p.product_name,
		p.category,
		p.subcategory,
		p.cost
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
		ON p.product_key = s.product_key
	WHERE order_date IS NOT NULL
),

product_agrregations AS (
	SELECT
		product_key,
		product_name,
		category,
		subcategory,
		cost,
		COUNT(DISTINCT order_number) AS total_orders,
		COUNT(DISTINCT customer_key) AS total_customers,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS total_quantity,
		MAX(order_date) AS last_sale_date,
		DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS Lifespan,
		ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
	FROM base_query
	GROUP BY
		product_key,
		product_name,
		category,
		subcategory,
		cost
)

SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	Lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders
	END AS avg_order_revenue,
	CASE
		WHEN Lifespan = 0 THEN total_sales
		ELSE total_sales/Lifespan
	END AS avg_monthly_revenue
FROM product_agrregations

SELECT * FROM gold.report_products