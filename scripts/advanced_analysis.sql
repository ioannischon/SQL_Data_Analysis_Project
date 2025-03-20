/*
===============================================================================================
Advanced Analytics Queries
===============================================================================================

This script demonstrates more advanced analytic topics and metrics in this particular dataset. 

Purpose: 
	
	~ Analysis over time (changes, seasonality etc)
    ~ Cumulative Analysis
	~ Performance Analysis
	~ Part to Whole Analysis
	~ Data Segmentations

Each query can be executed on its own and it shows particular results. 
*/


-- Change Over Years --

SELECT 
	YEAR(order_date) AS order_year,
	SUM(sales) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date)
ORDER BY YEAR(order_date);

-- Checking Seasonality of the bussiness -- 

SELECT 
	MONTH(order_date) AS order_month,
	SUM(sales) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY MONTH(order_date)
ORDER BY MONTH(order_date);

-- Month by Month Changes over the years -- 

SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	SUM(sales) AS total_sales,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);


-- Cumulative Analysis --

SELECT 
	order_date,
	total_sales,
	SUM(total_sales) OVER (ORDER BY order_date) AS running_total_sales,
	AVG(avg_price) OVER (ORDER BY order_date) AS moving_average_price
	FROM 
(
SELECT 
	DATETRUNC(month, order_date) AS order_date,
	SUM(sales) AS total_sales,
	AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
) s;


-- Performance Analysis: Year over Year --
WITH yearly_product_sales AS (
SELECT 
	YEAR(s.order_date) AS order_year,
	p.product_name,
	SUM(s.sales) AS current_sales
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
ON s.product_key = p.product_key
WHERE s.order_date IS NOT NULL
GROUP BY 
YEAR(s.order_date),
p.product_name
)

SELECT 
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
	current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_from_avg,
	CASE
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Average'
		WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Average'
		ELSE 'Average'
	END AS performance,
	LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
	current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_from_previous_year,
	CASE 
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
		WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
		ELSE 'No change'
	END AS revenue_tendency
FROM yearly_product_sales
ORDER BY product_name, order_year;


-- Part to Whole Analysis --

 -- Category Contibution in overall revenue --
WITH category_sales AS 
(
	SELECT 
		p.category,
		SUM(s.sales) AS total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.category
)

SELECT
	category,
	total_sales,
	SUM(total_sales) OVER () AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT)/ SUM(total_sales) OVER ()) * 100, 2), '%') AS percent_of_total
FROM category_sales 
ORDER BY percent_of_total DESC

  -- Country Contribution in overall revenue -- 
WITH country_sales AS 
(
	SELECT 
		c.country,
		SUM(s.sales) AS total_sales
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	GROUP BY c.country
)

SELECT
	country,
	total_sales,
	SUM(total_sales) OVER () AS overall_sales,
	CONCAT(ROUND((CAST(total_sales AS FLOAT)/ SUM(total_sales) OVER ()) * 100, 2), '%') AS percent_of_total
FROM country_sales 
ORDER BY percent_of_total DESC


-- Data Segmentations -- 

  -- Product Cost Distribution -- 
WITH product_cost_range AS
(
	SELECT 
		product_key,
		product_name,
		product_cost,
		CASE 
			WHEN product_cost < 100 THEN 'Below 100'
			WHEN product_cost BETWEEN 100 AND 800 THEN '100-800'
			WHEN product_cost BETWEEN 800 AND 1500 THEN '800-1500'
			ELSE 'Above 1500'
		END AS cost_range
	FROM gold.dim_products
)

SELECT 
	cost_range,
	COUNT(product_key) AS total_products
FROM product_cost_range
GROUP BY cost_range
ORDER BY total_products DESC


 -- Grouping customers on spending behavior -- 

WITH customer_spending AS 
(
	SELECT 
		c.customer_key,
		SUM(s.sales) AS total_spending,
		MIN(s.order_date) AS first_order,
		MAX(s.order_date) AS last_order,
		DATEDIFF(month, MIN(s.order_date), MAX(s.order_date)) AS lifespan
		FROM gold.fact_sales s
	LEFT JOIN gold.dim_customers c
	ON s.customer_key = c.customer_key
	GROUP BY c.customer_key
)
SELECT
	customer_behavior,
	COUNT(customer_key) AS total_customers_by_tier
FROM
(
	SELECT 
	customer_key,
	total_spending,
	CASE 
		WHEN lifespan >= 12 AND total_spending > 5000  THEN 'Top Tier Customer'
		WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular Tier Customer'
		ELSE 'New Tier Customer'
	END AS customer_behavior
	FROM customer_spending
)s
GROUP BY customer_behavior
ORDER BY total_customers_by_tier DESC
