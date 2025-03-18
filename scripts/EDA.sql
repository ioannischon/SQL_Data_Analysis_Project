/*
Exploratory Data Analysis (EDA) 

This EDA is being conducted on the model that has been created in the Data Warehouse Project.
The bussiness model that's been built in the Gold Schema is consisted of three Views, one 
being a fact table and the other two dimension ones. 

Purpose of the EDA:

 ~ Database exploration
 ~ Dimensions exploration
 ~ Dates exploration
 ~ Measures & Big Numbers exploration
 ~ Magnitute Analysis
 ~ Top to Bottom Perfomance Analysis

 For all the types of exploration, there are written queries alongside with insightful comments.
*/


-- Exploring METADATA in the Database

SELECT 
* 
FROM INFORMATION_SCHEMA.TABLES ;


SELECT 
* 
FROM INFORMATION_SCHEMA.COLUMNS;


-- Exploring Dimensions in the Database

SELECT
DISTINCT country 
FROM gold.dim_customers;

SELECT 
DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;


-- Exploring the DATE Columns of the Database

SELECT 
MIN(order_date) AS first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS months_of_sales_range
FROM gold.fact_sales;

SELECT 
DATEDIFF(year, MIN(birthdate), GETDATE()) AS oldest_age,
DATEDIFF(year, MAX(birthdate), GETDATE()) AS youngest_age
FROM gold.dim_customers;

SELECT 
product_id,
DATEDIFF(year, start_date, GETDATE()) AS years_of_existence
FROM gold.dim_products
GROUP BY product_id, start_date
ORDER BY product_id;


-- Exploring the Measures/Metrics of the Database

SELECT 
SUM(sales) AS total_sales,
SUM(quantity) AS total_quantity, 
AVG(price) AS avg_selling_price,
COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

SELECT
COUNT(product_key) AS total_products
FROM gold.dim_products;

SELECT
COUNT(customer_key) AS total_customers
FROM gold.dim_customers;

  -- All combined in one Query--
SELECT 'Total_Sales' AS measure_name, SUM(sales) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total_Quantity' AS measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Average_Price' AS measure_name, AVG(price) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total_Ordrs' AS measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total_Products' AS measure_name, COUNT(product_key) AS measure_value FROM gold.dim_products
UNION ALL 
SELECT 'Total_Customers' AS measure_name, COUNT(customer_key) AS measure_value FROM gold.dim_customers;


-- Magnitude Analysis --

 SELECT 
 country,
 COUNT(customer_key) AS total_customers_by_country
 FROM gold.dim_customers
 GROUP BY country
 ORDER BY total_customers_by_country DESC;

 SELECT 
 gender,
 COUNT(customer_key) AS total_customers_by_gender
 FROM gold.dim_customers
 GROUP BY gender
 ORDER BY total_customers_by_gender DESC;

 SELECT 
 category,
 COUNT(product_key) AS total_products_by_category,
 AVG(product_cost) AS avg_product_cost
 FROM gold.dim_products
 GROUP BY category
 ORDER BY total_products_by_category DESC;

 SELECT
 p.category,
 SUM(s.sales) total_revenue_by_category
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_products p
 ON s.product_key = p.product_key
 GROUP BY p.category
 ORDER BY total_revenue_by_category DESC;


 SELECT
 c.customer_key,
 c.first_name , 
 c.last_name,
 SUM(s.sales) AS total_revenue_by_customer
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_customers c
 ON s.customer_key = c.customer_key
 GROUP BY 
 c.customer_key,
 c.first_name, 
 c.last_name
 ORDER BY total_revenue_by_customer DESC;

 SELECT
 c.country,
 SUM(s.quantity) AS item_distribution_by_country,
 SUM(s.sales) AS total_revenue_by_country
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_customers c
 ON s.customer_key = c.customer_key
 GROUP BY 
 c.country
 ORDER BY item_distribution_by_country DESC;


 SELECT 
 gender,
 SUM(s.sales) AS total_revenue_by_gender,
 AVG(s.sales) AS avg_sales_by_gender
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_customers c
 ON s.customer_key = c.customer_key
 GROUP BY c.gender
 ORDER BY total_revenue_by_gender DESC;


 -- TOP to BOTTOM Analysis 
  
  -- Top 5 Products --
 SELECT TOP 5
 p.product_name,
 SUM(s.sales) total_revenue_by_category
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_products p
 ON s.product_key = p.product_key
 GROUP BY p.product_name
 ORDER BY total_revenue_by_category DESC;

  -- Bottom 5 Products --
 SELECT TOP 5
 p.product_name,
 SUM(s.sales) total_revenue_by_category
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_products p
 ON s.product_key = p.product_key
 GROUP BY p.product_name
 ORDER BY total_revenue_by_category;


 -- Top 3 Subcategories --
 SELECT 
 *
 FROM (
	 SELECT 
	 p.subcategory, 
	 SUM(s.sales) AS total_revenue_by_subcategory,
	 ROW_NUMBER() OVER (ORDER BY SUM(s.sales) DESC) AS rank_subcat
	FROM gold.fact_sales s
	LEFT JOIN gold.dim_products p
	ON s.product_key = p.product_key
	GROUP BY p.subcategory)s
WHERE rank_subcat <= 3

-- Bottom 5 customers in orders placed -- 
SELECT TOP 5
 c.customer_key,
 c.first_name , 
 c.last_name,
 COUNT(DISTINCT s.order_number) AS total_orders_placed
 FROM gold.fact_sales s
 LEFT JOIN gold.dim_customers c
 ON s.customer_key = c.customer_key
 GROUP BY 
 c.customer_key,
 c.first_name, 
 c.last_name
 ORDER BY total_orders_placed;
