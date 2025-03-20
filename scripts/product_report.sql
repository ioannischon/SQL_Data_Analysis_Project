/*
=============================================================================
BUSSINESS REPORT: Products
=============================================================================
	
This script creates a report as a View Table. The report concludes 
bussiness metrics and behaviors about the products of the database.

Contents:
	
	~ Gathers information about the products (name, productid,category etc) 
	~ Segments products by sale-performance
	~ Aggregates product metrics
	~ Calculate useful product KPI's

*/
	-- Product Report -- 
CREATE VIEW gold.product_report AS

	WITH prod_info AS	
	(
		SELECT 
			p.product_key,
			p.product_name,
			p.category,
			p.subcategory,
			p.product_cost,
			s.customer_key,
			s.order_number,
			s.order_date,
			s.sales,
			s.quantity,
			s.price
		FROM gold.fact_sales s
		LEFT JOIN gold.dim_products p
		ON s.product_key = p.product_key
		WHERE s.order_date IS NOT NULL
	)
	, prod_aggregations AS 
	(
		SELECT
			product_key,
			product_name,
			category,
			subcategory,
			product_cost,
			COUNT(DISTINCT order_number) AS total_orders,
			SUM(sales) AS total_sales,
			SUM(quantity) AS total_quantity,
			COUNT(DISTINCT customer_key) AS total_customers,
			MAX(order_date) AS last_sale_date,
			DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan,
			ROUND(AVG(CAST(sales AS FLOAT) / NULLIF(quantity, 0)), 1) AS avg_selling_price
		FROM prod_info
		GROUP BY 
		product_key,
		product_name,
		category,
		subcategory,
		product_cost
	)

	SELECT 
		product_key,
		product_name,
		category,
		subcategory,
		product_cost,
		last_sale_date,
		DATEDIFF(month, last_sale_date, GETDATE()) AS recency,
		CASE 
			WHEN total_sales < 20000 THEN 'Low - Performers'
			WHEN total_sales BETWEEN 20000 AND 50000 THEN 'Mid-Range - Performers'
			ELSE 'High - Performers'
		END AS product_performance,
		lifespan,
		total_orders,
		total_sales,
		total_customers,
		avg_selling_price,
		CASE 
			WHEN total_orders = 0 THEN 0
			ELSE total_sales/total_orders
		END AS avg_order_revenue,
		CASE 
			WHEN lifespan = 0 THEN 0
			ELSE total_sales/lifespan
		END AS avg_monthly_revenue
	FROM prod_aggregations;
