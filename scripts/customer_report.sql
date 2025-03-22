/*
=============================================================================
BUSSINESS REPORT: Customers
=============================================================================
	
This script creates a report as a View Table. The report concludes 
bussiness metrics and behaviors about the customers of the database.

Contents:
	
	~ Gathers information about the customers (name, customerid,country etc) 
	~ Segments customers by performance
	~ Aggregates customer metrics
	~ Calculate useful customer KPI's

*/


CREATE VIEW gold.customer_report AS
	
	WITH cust_info AS
	(
		SELECT
			s.order_number,
			s.product_key,
			s.order_date,
			s.sales,
			s.quantity,
			c.customer_key,
			c.customer_number,
			CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
			DATEDIFF(year, c.birthdate, GETDATE()) AS customer_age
		FROM gold.fact_sales s
		LEFT JOIN gold.dim_customers c
		ON c.customer_key = s.customer_key
		WHERE s.order_date IS NOT NULL
	)
	,cust_aggregations AS
	(
		SELECT
			customer_key,
			customer_number,
			customer_name,
			customer_age,
			COUNT(DISTINCT order_number) AS total_orders,
			SUM(sales) AS total_sales,
			SUM(quantity) AS total_quantity,
			COUNT(DISTINCT product_key) AS total_products,
			MAX(order_date) AS last_order_date,
			DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
		FROM cust_info
		GROUP BY
		customer_key,
		customer_number,
		customer_name,
		customer_age
	)

	SELECT 
		customer_key,
		customer_number,
		customer_name,
		customer_age,
		CASE 
			WHEN customer_age < 20 THEN 'UNDER 20'
			WHEN customer_age BETWEEN 20 AND 29 THEN '20-29'
			WHEN customer_age BETWEEN 30 AND 39 THEN '30-39'
			WHEN customer_age BETWEEN 40 AND 49 THEN '40-49'
			WHEN customer_age BETWEEN 50 AND 59 THEN '50-59'
			ELSE 'ABOVE 60'
		END AS age_group,
		CASE 
			WHEN lifespan >= 12 AND total_sales > 5000  THEN 'Top - Tier Customer'
			WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular - Tier Customer'
			ELSE 'New - Tier Customer'
		END AS customer_behavior,
		last_order_date,
		DATEDIFF(month, last_order_date, GETDATE()) AS recency,
		total_orders,
		total_sales,
		total_quantity,
		total_products,
		lifespan,
		CASE 
			WHEN total_orders = 0 THEN 0
			ELSE total_sales/total_orders
		END AS avg_order_value,
		CASE
			WHEN lifespan = 0 THEN 0
			ELSE total_sales/lifespan
		END AS avg_monthly_spend
	FROM cust_aggregations;
