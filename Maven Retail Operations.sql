#DATA SOURCE = https://mavenanalytics.io/data-playground

-- Data Analysis of Online Retail Store Operations

CREATE DATABASE retailstore;

USE retailstore;

SELECT * FROM categories;
SELECT * FROM customers;
SELECT * FROM employees;
SELECT * FROM order_details;
SELECT * FROM orders;
SELECT * FROM products;
SELECT * FROM shippers;

-- //////////////////////////////////////// DATA CLEANING  /////////////////////////////

#We will connect the tables based on primary and foreign keys 

-- ADDING PRIMARY KEYS 
ALTER TABLE categories
ADD CONSTRAINT pk_categories PRIMARY KEY (categoryID);

ALTER TABLE employees 
ADD CONSTRAINT pk_employees PRIMARY KEY (employeeID);

ALTER TABLE order_details
ADD CONSTRAINT pk_order_details PRIMARY KEY (orderID, productID);

ALTER TABLE orders
ADD CONSTRAINT pk_orders PRIMARY KEY (orderID);

ALTER TABLE products
ADD CONSTRAINT pk_products PRIMARY KEY (productID);

ALTER TABLE shippers
ADD CONSTRAINT pk_shippers PRIMARY KEY (shipperID);

ALTER TABLE customers
ADD CONSTRAINT pk_customers PRIMARY KEY (customerID);
#Error while executing above query - Error Code: 1170. BLOB/TEXT column 'customerID' used in key specification without a key length

-- So we will convert the data type to varchar
ALTER TABLE customers
MODIFY customerID VARCHAR(50);

ALTER TABLE orders
MODIFY customerID VARCHAR(50);

#now executing the query to add constraint 
ALTER TABLE customers
ADD CONSTRAINT pk_customers PRIMARY KEY (customerID);

-- ADDING FOREIGN KEYS

ALTER TABLE orders
ADD CONSTRAINT fk_categories FOREIGN KEY (categoryID) REFERENCES categories(categoryID);

ALTER TABLE orders
ADD CONSTRAINT fk_orders FOREIGN KEY (customerID) REFERENCES customers(customerID);

ALTER TABLE orders
ADD CONSTRAINT fk2_orders FOREIGN KEY (employeeID) REFERENCES employees(employeeID);

ALTER TABLE orders
ADD CONSTRAINT fk3_orders FOREIGN KEY (shipperID) REFERENCES shippers(shipperID);

ALTER TABLE order_details
ADD CONSTRAINT fk1_orderdetails FOREIGN KEY (orderID) REFERENCES orders(orderID);

ALTER TABLE order_details
ADD CONSTRAINT fk2_orderdetails FOREIGN KEY (productID) REFERENCES products(productID);

ALTER TABLE products
ADD CONSTRAINT fk1_products FOREIGN KEY (categoryID) REFERENCES categories(categoryID);

ALTER TABLE employees
ADD CONSTRAINT fk1_employees_reportsTo FOREIGN KEY (reportsTo) REFERENCES employees(employeeID);

-- we have executed the below queries to execute this above query
describe employees;
-- we are trying to update the row 
UPDATE employees
SET reportsTo = null
WHERE reportsTo = '';

-- updating the data type
ALTER TABLE employees
MODIFY reportsTo int;

describe categories;  -- This is fine
describe customers;   -- This is fine
describe employees;   -- This is fine
describe order_details; -- This is fine
describe orders;   -- We are chnaging the data types for date columns
describe products; -- This is fine 
describe shippers; -- This is fine 

ALTER TABLE orders
MODIFY orderDate DATE;

ALTER TABLE orders
MODIFY requiredDate DATE;

UPDATE orders SET shippedDate = NULL where shippedDate = '';

ALTER TABLE orders
MODIFY shippedDate DATE;

SELECT *FROM products;

-- //////////////////////////////////////// DATA ANALYSIS PART 1 /////////////////////////////

-- Part 1 of data analysis is based on different types of analysis 

-- 1. Customer Analysis:

--    a. What are the top 10 customers who have placed the highest number of orders?

SELECT 
    CustomerID, 
    COUNT(orderID) AS total_orders
FROM
    orders
GROUP BY customerID
ORDER BY COUNT(orderID) DESC
LIMIT 10;

--    b. Which customers have generated the highest total revenue for the store?

SELECT 
    customerID, 
    ROUND(SUM(od.unitPrice * od.quantity),2) AS total_revenue
FROM
    order_details od
        JOIN
    orders o ON od.orderID = o.orderID
GROUP BY o.customerID
ORDER BY total_revenue DESC
LIMIT 5;           

--    c. What is the average order value for each customer?

SELECT 
    customerID, 
    ROUND(AVG(od.unitPrice * od.quantity),2) AS avg_revenue
FROM
    order_details od
        JOIN
    orders o ON od.orderID = o.orderID
GROUP BY o.customerID
ORDER BY avg_revenue DESC;


-- 2. Product Analysis:

--    a. Which are the top 5 best-selling products by quantity sold?
SELECT 
    p.productName, 
    SUM(od.quantity) AS total_quantity_sold
FROM
    products p
        JOIN
    order_details od ON p.productID = od.productID
GROUP BY od.productID
ORDER BY total_quantity_sold DESC
LIMIT 5;

--    b. Write a query to find the top 5 customers who have made the highest average quantity purchases per order. 
--       Consider only the customers who have placed at least 10 orders.

SELECT 
    o.customerID, AVG(od.quantity) AS avg_qty
FROM
    orders o
        JOIN
    order_details od ON o.orderID = od.orderID
GROUP BY o.customerID
HAVING COUNT(od.quantity) >= 10
ORDER BY avg_qty DESC
LIMIT 5;

--    c. Which product categories contribute the most to the overall revenue?

SELECT
    c.categoryID,
    c.categoryName,
    ROUND(SUM(od.unitPrice * od.quantity), 2) AS totalRevenue
FROM
    order_details od
INNER JOIN
    products p ON od.productID = p.productID
INNER JOIN
    categories c ON p.categoryID = c.categoryID
GROUP BY
    c.categoryID, c.categoryName
ORDER BY
    totalRevenue DESC;


-- 3. Order Analysis:
--    a. What is the average order processing time from order date to shipped date?

SELECT 
AVG(DATEDIFF(shippedDate,orderDate)) AS avg_processing_time
FROM orders;


--    b. How many orders were placed in each month of the year?

SELECT 
    DATE_FORMAT(orderDate, '%M') AS Month,
    DATE_FORMAT(orderDate, '%Y') AS Year,
    COUNT(od.orderID) AS total_orders
FROM
    order_details od
        JOIN
    orders o ON o.orderID = od.orderID
GROUP BY Month, Year;


--    c. What is the distribution of order quantities across different order IDs?

SELECT 
    orderID, 
    SUM(quantity) AS total_quantity
FROM
    order_details
GROUP BY orderID
ORDER BY total_quantity DESC;


--    d. Identify the top-selling product category for each customer segment based on the country

SELECT country, categoryName
FROM (
       SELECT categoryName, 
       ROUND(SUM(od.unitPrice * od.quantity),2) as total_revenue, 
       cu.country,
       RANK() OVER (PARTITION BY cu.country ORDER BY SUM(od.unitPrice * od.quantity) desc) as rankk 
	FROM products p
    JOIN order_details od on p.productID = od.productID
	JOIN orders o on o.orderID = od.orderID
JOIN categories ca on p.categoryID = ca.categoryID
JOIN customers cu ON o.customerID = cu.customerID
GROUP BY cu.country, p.categoryID
) sq
WHERE rankk = 1;


-- 4. Category Analysis:
--    a. Which product category has the highest overall sales revenue?

SELECT 
    c.categoryID,
    c.categoryName,
    ROUND(SUM(od.unitPrice * od.quantity), 2) AS totalRevenue
FROM
    order_details od
        INNER JOIN
    products p ON od.productID = p.productID
        INNER JOIN
    categories c ON p.categoryID = c.categoryID
GROUP BY c.categoryID , c.categoryName
ORDER BY totalRevenue DESC;

--    b. Which category has the highest number of unique products?

SELECT 
    categoryName,
    COUNT(DISTINCT productID) AS unique_product_count
FROM
    products p
        JOIN
    categories c ON p.categoryID = c.categoryID
GROUP BY categoryName
ORDER BY unique_product_count DESC
LIMIT 1;

--    c. What is the average number of orders per customer for each category?

SELECT
    c.categoryName,
    COUNT(DISTINCT o.customerID) AS total_customers,
    ROUND(COUNT(o.orderID) / COUNT(DISTINCT o.customerID),2) AS average_orders_per_customer
FROM
    categories c
    JOIN products p ON c.categoryID = p.categoryID
    JOIN order_details od ON p.productID = od.productID
    JOIN orders o ON od.orderID = o.orderID
GROUP BY
    c.categoryName;


-- 5. Employee Analysis:

--    a. Which employee has processed the highest number of orders?

SELECT 
    e.employeeID,
    e.employeeName,
    COUNT(od.orderID) AS total_orders
FROM
    employees e
        JOIN
    orders o ON e.employeeID = o.employeeID
        JOIN
    order_details od ON od.orderID = o.orderID
GROUP BY o.employeeID
ORDER BY total_orders DESC;



--    b. What is the average order value for each employee?

SELECT e.employeename, ROUND(AVG(od.unitprice * od.quantity),2) as avg_order_value
FROM
    employees e
        JOIN
    orders o ON e.employeeID = o.employeeID
        JOIN
    order_details od ON od.orderID = o.orderID
GROUP BY o.employeeID
ORDER BY avg_order_value DESC;

--    c. How many employees report to each manager?

SELECT 
    e.employeename as manager_name, COUNT(em.reportsTo) as employees_count
FROM
    employees e
        JOIN
    employees em ON e.employeeID = em.reportsTo
WHERE
    e.title LIKE '%Manager%'
GROUP BY e.employeename;


-- 6. Shipping Analysis:
--    a. Which shipper has handled the most orders?

SELECT 
    s.companyname, COUNT(o.orderID) AS total_orders
FROM
    shippers s
        JOIN
    orders o ON s.shipperID = o.shipperID
GROUP BY s.companyname
ORDER BY total_orders DESC
LIMIT 1;


--    b. What is the average freight cost per order for each shipper?

SELECT s.companyname, ROUND(AVG(freight),2) as avg_freight_cost
FROM
    shippers s
        JOIN
    orders o ON s.shipperID = o.shipperID
GROUP BY s.companyname
ORDER BY avg_freight_cost DESC;


--    c. How many orders were shipped within the required date?

SELECT 
    COUNT(orderID) AS shipped_order_within_required_date
FROM
    orders
WHERE
    shippedDate <= requiredDate;


-- 7. Time Analysis:
--    a. What are the busiest months in terms of order volume?

SELECT 
    DATE_FORMAT(orderDate, '%M') AS Months
    ,COUNT(orderID) AS order_volume
FROM
    orders
GROUP BY Months
ORDER BY order_volume DESC;

--    b. Is there any seasonality pattern in the order quantity?

-- 1st way
SELECT 
    DATE_FORMAT(orderDate, '%M') AS Months
    ,SUM(quantity) AS Total_Quantity
FROM
    order_details
        JOIN
    orders ON order_details.orderID = orders.orderID
GROUP BY Months
ORDER BY FIELD(Months, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');

-- 2nd way
SELECT
    CONCAT(YEAR(orderDate), '-', 
           QUARTER(orderDate)) AS YearQuarter,
    SUM(quantity) AS OrderQuantity
FROM
    order_details
        JOIN
    orders ON order_details.orderID = orders.orderID
GROUP BY YearQuarter
ORDER BY Year(orderDate), Quarter(orderDate);

--    c. What is the average time it takes for a customer to place a reorder after their initial order?

SELECT 
    customerID,
    ROUND(AVG(DATEDIFF(subsequent_order_date,
                    initial_order_date))) AS avg_reorder_time
FROM
    (SELECT 
        o1.customerID,
            MIN(o1.orderDate) AS initial_order_date,
            MIN(o2.orderDate) AS subsequent_order_date
    FROM
        orders o1
    JOIN orders o2 ON o1.customerID = o2.customerID
    WHERE
        o2.orderDate > o1.orderDate
    GROUP BY o1.customerID) AS subquery
GROUP BY customerID
ORDER BY avg_reorder_time desc;


-- 8. Order Details Analysis:

--     a. Which products have the highest total revenue, considering only products that have been ordered at least 50 times?

SELECT 
    productname,
    SUM(od.unitprice * od.quantity) AS total_revenue
FROM
    order_details od
        JOIN
    products p ON od.ProductID = p.productID
GROUP BY od.productID
HAVING COUNT(od.productID) >= 50;


-- 9. Customer Location Analysis:

--    a. Which city and country have the highest number of customers?

SELECT 
  city, country,   COUNT(customerID) AS total_customers
FROM
    customers
GROUP BY city , country
ORDER BY total_customers DESC
LIMIT 1;

--    b. What is the distribution of customers across different cities?

SELECT 
  city, COUNT(customerID) AS total_customers
FROM
    customers
GROUP BY city 
ORDER BY total_customers DESC;

--    c. How does the average order value vary based on customer location?

SELECT 
    c.country,
    ROUND(AVG(od.unitprice * od.quantity), 2) AS avg_order_value
FROM
    customers c
        JOIN
    orders o ON c.customerID = o.customerID
        JOIN
    order_details od ON o.orderID = od.orderID
GROUP BY c.country;

-- //////////////////////////// SUGGESTIONS //////////////////////////////

-- Order Analysis:
-- - Improve order processing time by streamlining internal processes and optimizing logistics.
-- - Monitor and analyze the order volume and distribution across different months to identify peak seasons and plan resources accordingly.
-- - Focus on customer segmentation and tailor marketing efforts to encourage repeat orders.

-- Category Analysis:
-- - Invest in marketing and promotions for the product categories with the highest overall sales revenue.
-- - Expand the product range and offerings within the category with the highest number of unique products to attract a wider customer base.
-- - Analyze customer behavior and preferences within each category to offer personalized recommendations and enhance cross-selling opportunities.

-- Employee Analysis:
-- - Recognize and reward the employee who has processed the highest number of orders to motivate and incentivize the team.
-- - Provide training and support to employees with lower average order values to improve their sales and customer service skills.
-- - Implement regular performance reviews and feedback sessions to identify areas for improvement and promote professional growth.

-- Shipping Analysis:
-- - Strengthen the partnership with the shipper that has handled the most orders to ensure efficient and reliable shipping services.
-- - Analyze the average freight cost per order for each shipper and negotiate favorable rates or explore alternative shipping options.
-- - Improve shipping processes and communication to ensure a higher percentage of orders are shipped within the required date.

-- Time Analysis:
-- - Allocate additional resources during the busiest months in terms of order volume to meet customer demand and avoid delays.
-- - Monitor and analyze order quantity patterns to identify seasonality trends and adjust inventory levels and production accordingly.
-- - Enhance customer communication and streamline the reordering process to reduce the average time it takes for customers to place a reorder.

-- Order Details Analysis:
-- - Focus on promoting and upselling the products with the highest total revenue to maximize profitability.
-- - Analyze customer preferences and purchasing patterns for products that have been ordered at least 50 times to identify cross-selling opportunities.
-- - Monitor inventory levels and ensure sufficient stock for high-revenue products to avoid stockouts.

-- Customer Location Analysis:
-- - Invest in targeted marketing campaigns in the city and country with the highest number of customers to maintain customer loyalty and attract new customers.
-- - Analyze customer behavior and preferences based on location to customize marketing messages and offerings for specific regions.
-- - Continuously monitor the average order value based on customer location and tailor pricing strategies and promotions to increase customer spending.



-- //////////////////////////////////////// DATA ANALYSIS PART 2 /////////////////////////////

-- Part 2 of data analysis is based on practicing Advanced SQL 

-- Sub-queries:
-- 1. Find all customers who have placed orders but have not placed any orders in the year 2015

SELECT O.customerID, C.companyname
FROM orders O
JOIN customers C ON O.customerID = C.customerID
WHERE O.customerID NOT IN (
    SELECT O.customerID
    FROM orders O
    WHERE YEAR(O.orderDate) = 2015
)
GROUP BY o.customerID;

-- 2. Retrieve the product details for all products that have been ordered by customers from a specific country.

SELECT 
    o.customerID,
    p.productID,
    p.productname,
    ROUND(SUM(od.unitprice * od.quantity), 2) AS total_revenue
FROM
    products p
        JOIN
    order_details od ON p.productID = od.productID
        JOIN
    orders o ON o.orderID = od.orderID
        JOIN
    customers c ON c.customerID = o.customerID
WHERE
    c.country IN (SELECT 
            c.country
        FROM
            customers c
        WHERE
            c.country = 'Mexico')
GROUP BY o.customerID , p.productID;

-- 3. List all orders where the order total exceeds the average order total.

SELECT 
    od.orderID,
    od.productID,
    SUM(unitprice * quantity) AS revenue
FROM
    order_details od
GROUP BY orderID , productID
HAVING SUM(unitprice * quantity) > (SELECT 
        AVG(sq.total_revenue)
    FROM
        (SELECT 
            SUM(unitprice * quantity) AS total_revenue
        FROM
            order_details
        GROUP BY orderID) sq);


-- Views and Indexes:
-- 4. Create a view that displays the total revenue generated by each product category.

CREATE VIEW category_revenue AS
    SELECT 
        categoryname, ROUND(SUM(od.unitprice * od.quantity),2) AS total_revenue
    FROM
        categories c
            JOIN
        products p ON c.categoryID = p.categoryID
            JOIN
        order_details od ON od.productID = p.productID
	GROUP BY categoryname;
        
select * from category_revenue;


-- 5. Create an index on the customer's last name column to improve search performance.

CREATE INDEX idx_lastname ON customers ((SUBSTRING(contactName, 1, 255)));

SELECT SUBSTRING_INDEX(contactName, ' ', -1) AS lastName
FROM customers;

-- 6. Retrieve the data from a specific view and apply filters to get orders placed in a particular year.



-- Data integrity and constraints:
-- 7. Add a constraint to the product table that ensures the unit price is always greater than zero.
-- 8. Identify any orders that violate the foreign key constraint between the orders table and customers table.
-- 9. Remove a specific constraint from the orders table temporarily to allow a data migration.

-- Modifying Tables - ALTER TABLE, DROP TABLE, RENAME TABLE:
-- 10. Add a new column called "discounted_price" to the order_details table.
-- 11. Remove the "discontinued" column from the products table.
-- 12. Rename the "employeeName" column in the employees table to "fullName".

-- Advanced Joins and Subqueries - Self joins, non-equijoins, and complex conditions:
-- 13. Retrieve the employee names and their corresponding managers' names using a self-join on the employees table.
-- 14. Join the orders and customers tables using a non-equijoin based on a range of order dates.
-- 15. Retrieve the customers who have placed orders for products from multiple categories.

-- Correlated subqueries and Exists operator:
-- 16. Find all orders where the order total exceeds the average order total for that customer.
-- 17. List the customers who have placed orders for products that are also ordered by other customers.
-- 18. Retrieve the products that have never been ordered by using the EXISTS operator.

-- Stored procedures, triggers, and user-defined functions:
-- 19. Create a stored procedure to calculate and insert the total revenue generated by each product category into a separate table.
-- 20. Implement a trigger that automatically updates the inventory quantity whenever an order is placed.
-- 21. Create a user-defined function to calculate the total revenue generated by a specific customer.

-- SQL optimization techniques:
-- 22. Identify and optimize the slow-performing SQL query that retrieves the top 10 customers based on their total revenue.
-- 23. Rewrite a complex query using table joins and subqueries to improve its efficiency.
-- 24. Apply indexing techniques to improve the performance of a frequently executed search query.