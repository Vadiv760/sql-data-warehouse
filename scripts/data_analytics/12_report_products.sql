/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
CREATE VIEW gold.report_products AS
WITH base_query AS(
-- 1) Base Query: Retrieves core columns from fact_sales and dim_products
SELECT
    f.order_number,
    f.order_date,
    f.customer_key,
    f.sales_amount,
    f.quantity,
    p.product_key,
    p.product_name,
    p.category,
    p.subcategory,
    p.cost
FROM gold.dim_products AS p
LEFT JOIN gold.fact_sales AS f
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
),

-- 2) Product Aggregations: Summarizes key metrics at the product level
product_aggregation AS(
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_sales,
    ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query
GROUP BY 
product_key,
product_name,
category,
subcategory,
cost
)

-- 3) Final Query: Combines all product results into one output

SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    lifespan
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency,
    total_sales,
    CASE WHEN total_sales > 50000 THEN 'High-Performers'
         WHEN total_sales >= 15000 THEN 'Mid-Range'
         ELSE 'Low-Performers'
    END AS product_classification,
    total_orders,
    total_customers,
    total_quantity,
    avg_selling_price,
    CASE WHEN total_orders = 0 THEN 0
         ELSE total_sales / total_orders
    END AS average_order_revenue,
    CASE WHEN lifespan = 0 THEN 0
         ELSE total_sales / lifespan
    END AS average_monthly_revenue
FROM product_aggregation
