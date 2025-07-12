/*
SELECT * FROM departments; 
SELECT * FROM categories;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM order_items;
*/
--===========================================================
/*
--SELECT * FROM products
--ORDER BY product_id ASC LIMIT 100

SELECT 
category_id,
category_department_id,
category_name 
FROM categories
ORDER BY category_id ASC LIMIT 100
--category_department_id (FK)-->Department

--===========================================================
SELECT 
customer_id,
customer_fname,
customer_lname,
customer_email,
customer_password,
customer_street,
customer_city,
customer_state,
customer_zipcode 
FROM customers
ORDER BY customer_id ASC LIMIT 100

--===========================================================
SELECT 
department_id,
department_name
FROM departments
ORDER BY department_id ASC LIMIT 100

--===========================================================

SELECT 
order_item_id,
order_item_order_id,
order_item_product_id,
order_item_subtotal,
order_item_product_price
FROM order_items
ORDER BY order_item_id ASC LIMIT 100
--order_item_order_id (FK)-->orders
--order_item_product_id (FK)-->products

--===========================================================

SELECT 
order_id,
order_date,
order_customer_id,
order_status
FROM orders
ORDER BY order_id ASC LIMIT 100
--order_customer_id (FK) --> customers

--===========================================================
SELECT 
product_id,
product_category_id,
product_description,
product_price,
product_image FROM products
ORDER BY product_id ASC LIMIT 100
--product_category_id (FK) --> categories
*/
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--TOP QUERIES
-- 1. Top 5 Selling Products by Quantity
/*
SELECT 
    p.product_id, --1
    p.product_name, --2
    SUM(oi.order_item_quantity) AS total_quantity_sold --3
FROM order_items oi
JOIN products p ON oi.order_item_product_id = p.product_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;
*/
-- 2. Monthly Sales Summary (Quantity and Revenue)
/*
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
	
    SUM(oi.order_item_quantity) AS total_items_sold,
   ROUND(SUM(oi.order_item_quantity * oi.order_item_product_price) ::numeric ,2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_item_order_id
GROUP BY month
ORDER BY month;

*/
/*
--3. Total Revenue per Department
--select * from categories
SELECT 
    d.department_id,
    d.department_name,
	c.category_name,
    ROUND(SUM(oi.order_item_subtotal)::numeric, 2) AS total_revenue
FROM departments d
JOIN categories c ON c.category_department_id = d.department_id
JOIN products p ON p.product_category_id = c.category_id
JOIN order_items oi ON oi.order_item_product_id = p.product_id
GROUP BY d.department_id, d.department_name,c.category_name
ORDER BY total_revenue DESC;
*/
/*
--4. Top 5 Customers by Total Spend
--SELECT * FROM customers
--SELECT * FROM orders
--SELECT * FROM order_items
SELECT 
c.customer_id,
CONCAT(c.customer_fname,' ' , c.customer_lname) Fullname,
ROUND(SUM(oi.order_item_subtotal) :: numeric ,2) total_spent --3
FROM customers c
JOIN orders o
ON c.customer_id = o.order_customer_id
Join order_items oi
ON oi.order_item_order_id = o.order_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;
*/
/*
--5. Average Order Value per Customer

SELECT 
    c.customer_id,
    CONCAT(c.customer_fname,' ' , c.customer_lname) Fullname,
    ROUND(AVG(order_total):: numeric, 2) AS avg_order_value
FROM customers c
JOIN (
    SELECT 
        o.order_id,
        o.order_customer_id,
        ROUND(SUM(oi.order_item_subtotal)::numeric,2) AS order_total
    FROM orders o
    JOIN order_items oi ON oi.order_item_order_id = o.order_id
    GROUP BY o.order_id, o.order_customer_id
) AS order_summaries ON order_summaries.order_customer_id = c.customer_id
GROUP BY 1, 2
ORDER BY 3 DESC;

*/
/*
--6. Customer Last Order Date
SELECT 
    c.customer_id,
    CONCAT(c.customer_fname,'  ' , c.customer_lname) Fullname,
    MAX(o.order_date) AS last_order_date,
	EXTRACT(Month FROM o.order_date) AS order_year,
	TO_CHAR(o.order_date, 'Day') AS day_name
FROM customers c
JOIN orders o ON o.order_customer_id = c.customer_id
GROUP BY 1,2,4,5
ORDER BY 3 DESC;
*/

--=================================================================================================================
--CTE --> A CTE is a temporary result set you can reference within a larger query. Use it to break complex logic into readable steps.
--Example: Customers with total spending over 5000
/*
WITH customer_totals AS (
    SELECT 
        c.customer_id,
		CONCAT(c.customer_fname,'  ' , c.customer_lname) Fullname,
        ROUND(SUM(oi.order_item_subtotal) :: numeric ,2) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.order_customer_id
    JOIN order_items oi ON o.order_id = oi.order_item_order_id
    GROUP BY c.customer_id, Fullname 
)
SELECT * FROM customer_totals
WHERE total_spent > 5000
ORDER BY total_spent DESC;
*/

--=================================================================================================================
--CTAS --> Example: Create a reporting table of all completed orders
--Creates a new physical table from a SELECT result. Useful for snapshots, testing, or temporary staging.
--Basic way to create CTAS
/*
CREATE TABLE completed_orders AS
SELECT * FROM orders
WHERE order_status = 'COMPLETE';

CREATE TABLE closed_orders AS
SELECT * FROM orders
WHERE order_status = 'CLOSED';

CREATE TABLE processed_orders AS
SELECT * FROM orders
WHERE order_status = 'PROCESSING';

CREATE TABLE payment_pending_orders AS
SELECT * FROM orders
WHERE order_status = 'PENDING_PAYMENT';


SELECT * FROM completed_orders
order by order_date DESC

SELECT * FROM payment_pending_orders;

--before updated orders table
SELECT count(*) FROM processed_orders;
--8275

SELECT count(*) FROM closed_orders;
--7556

--++++++++++++++++++++++++++++++++++++++++++++++
-- updated order_status in orders table

update orders 
SET order_status = 'CLOSED'
where order_id = 8

--NOTE :-
--After updated the main table with CLOSED & PROCESSING, the count is changed in main table(orders)
--But not reflected in CTAS of 'processed_orders' & 'closed_orders' until we update both of the CTAS 

SELECT count(*) FROM orders
where order_status = 'CLOSED'
--7557

SELECT count(*) FROM orders
where order_status = 'PROCESSING'
--8274

--We have to update it again 
--Best way to create CTAS
DROP TABLE IF EXISTS closed_orders;
CREATE TABLE closed_orders AS
SELECT * FROM orders WHERE order_status = 'CLOSED';


DROP TABLE IF EXISTS processed_orders;
CREATE TABLE processed_orders AS
SELECT * FROM orders WHERE order_status = 'PROCESSING';

--after updated orders table & recreated CTAS again

SELECT count(*) FROM processed_orders;
--8274

SELECT count(*) FROM closed_orders;
--7557

*/
--=================================================================================================================
/*
--VIEW
--A view is a saved SQL query that acts like a virtual table. You query it like a table, but it's dynamically updated from the base data.
--Example: View of top 10 best-selling products
DROP VIEW IF EXISTS top_selling_products;
CREATE VIEW top_selling_products AS
SELECT 
    p.product_id,
    p.product_description,
    ROUND(SUM(oi.order_item_subtotal)::numeric ,2) AS total_revenue
FROM products p
JOIN order_items oi ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, p.product_description
ORDER BY total_revenue DESC
LIMIT 10;

-- Query the view
SELECT total_revenue FROM top_selling_products;

*/

--=================================================================================================================
--INDEXES
--Indexes improve query speed by allowing faster lookups, especially for large tables

--=================================================================================================================
--Window Function
--These are used for advanced analytics over sets of rows—without collapsing them into a single row like GROUP BY would
--Window functions perform calculations across a set of rows related to the current row, defined by an OVER() clause
-------------------------------------------------------------------------------------------------------------------
/*
--1. ROW_NUMBER(): Orders by recency per customer
SELECT 
    order_id,
    order_customer_id,
    order_date,
    ROW_NUMBER() OVER (PARTITION BY order_customer_id ORDER BY order_date DESC) AS row_num
FROM orders
ORDER BY order_customer_id, row_num;
--Use case: Get latest order per customer with a WHERE row_num = 1.
*/
-------------------------------------------------------------------------------------------------------------------
/*
--2. RANK() and DENSE_RANK(): Rank products by revenue
SELECT 
    p.product_id,
    p.product_description,
    ROUND(SUM(oi.order_item_subtotal)::numeric,2) AS total_revenue,
    RANK() OVER (ORDER BY ROUND(SUM(oi.order_item_subtotal)::numeric,2) DESC) AS revenue_rank,
    DENSE_RANK() OVER (ORDER BY ROUND(SUM(oi.order_item_subtotal)::numeric,2) DESC) AS dense_revenue_rank
FROM products p
JOIN order_items oi ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, p.product_description;
--RANK() leaves gaps if there's a tie. DENSE_RANK() doesn’t.
*/
----------------------------------------------------------------------------------------------------------------------
/*
--3. NTILE(4): Divide products into quartiles by sales
SELECT 
    p.product_id,
    p.product_description,
	NTILE(4) OVER (ORDER BY SUM(oi.order_item_subtotal)) AS revenue_quartile,
    SUM(oi.order_item_subtotal) AS revenue
FROM products p
JOIN order_items oi ON oi.order_item_product_id = p.product_id
GROUP BY p.product_id, p.product_description;
--Use case: Bucket products into sales performance tiers.
*/
----------------------------------------------------------------------------------------------------------------------
/*
--4. LAG() and LEAD(): Compare a customer's orders over time
SELECT 
    o.order_id,
    o.order_customer_id,
    o.order_date,
    LAG(o.order_date) OVER (PARTITION BY o.order_customer_id ORDER BY o.order_date) AS previous_order,
    LEAD(o.order_date) OVER (PARTITION BY o.order_customer_id ORDER BY o.order_date) AS next_order
FROM orders o;
--Helpful for churn analysis or time gaps between purchases.
*/

----------------------------------------------------------------------------------------------------------------------
/*
--5. Running Total of Sales per Customer
SELECT 
    c.customer_id,
    o.order_date,
    ROUND(oi.order_item_subtotal::numeric,2) ,
	ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS row_num,
    SUM(ROUND(oi.order_item_subtotal::numeric,2)) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM customers c
JOIN orders o ON c.customer_id = o.order_customer_id
JOIN order_items oi ON o.order_id = oi.order_item_order_id
ORDER BY c.customer_id, o.order_date;
--Tracks cumulative spending for each customer over time.

*/
----------------------------------------------------------------------------------------------------------------------
/*
--Calculate time between orders per customer (LAG):
SELECT 
 	CONCAT(c.customer_fname,' ' , c.customer_lname) Fullname,
    o.order_customer_id,
    o.order_id,
    o.order_date,
    LAG(o.order_date) OVER (PARTITION BY o.order_customer_id ORDER BY o.order_date) AS prev_order_date,
    o.order_date - LAG(o.order_date) OVER (PARTITION BY o.order_customer_id ORDER BY o.order_date) AS days_between
FROM orders o
JOIN customers c
ON c.customer_id = o.order_customer_id
*/
--SELECT * from customers






