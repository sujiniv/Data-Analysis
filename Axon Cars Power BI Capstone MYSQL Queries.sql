show databases;
use classicmodels;
show tables;


DESC Customers;
# Display First 20 records of customers who belongs to USA
SELECT *
FROM customers
where country = 'USA'
LIMIT 20;

# Display order numbers and total sales for which the order status is delivered.
SELECT YEAR(orderDate) Year,
       SUM(amount) Sales,
       COUNT(status) 'Orders Resolved'
FROM Orders
JOIN Payments using(customernumber)
WHERE status = 'Resolved'
GROUP BY 1;

# Display Total Sales by Product Line Category on 2003 and 2004
with Sub_Category_CTE as(
	SELECT orderNumber, SUM( IF( YEAR(orderDate) = 2003, amount, 0)) over() Sales2003,
			SUM( IF( YEAR(orderDate) = 2004, amount, 0)) over() Sales2004
     FROM orders
     JOIN payments using(customerNumber)
     WHERE status = 'Shipped'),
Product_CTE as(
	SELECT ProductLine, ProductCode, orderNumber
    from (
		select ProductLine, Productcode, orderNumber from Products
        join orderdetails using(productCode)
    ) Pro_Order
		)

select ProductLine, Sales2003, Sales2004,
		ROUND((sales2004-sales2003)*100/sales2004, 2) 'Growth of Sales (%)'
from Sub_Category_CTE
join Product_CTE using(orderNumber)
group by 1,2,3;

# Promotion Efficiency by Year and Burn Rate
SELECT YEAR(orderDate) Years,
       SUM(amount) sales,
       SUM(amount*0.15) 'Promotion Value',
       ROUND( SUM(amount*0.15)*100/SUM(amount), 2) 'burn rate (%)'
FROM orders
JOIN payments using(customerNumber)
WHERE status = 'Shipped'
GROUP BY 1;

# Display number of New Customers per Year
SELECT Year(orderDate) Years, Quarter(orderDate) Quartr,
       COUNT(DISTINCT customerNumber) 'Number of Customer'
FROM Orders
WHERE status = 'Shipped'
GROUP BY 1, 2;

