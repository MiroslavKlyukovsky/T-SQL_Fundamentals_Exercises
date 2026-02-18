-- (1.1) Write a query that generates five copies of each employee row:
SELECT e.empid, e.firstname, e.lastname, nums_5.n
  FROM HR.Employees e
 CROSS JOIN (SELECT num_inner.n as n
               FROM dbo.nums num_inner
              WHERE num_inner.n <= 5
             ) nums_5
 ORDER BY n; 

-- (1.2) Write a query that returns a row for each employee and day
--     in the range June 12, 2022 through June 16,2022:
SELECT e.empid, dates.dt
  FROM HR.Employees e
 CROSS JOIN (SELECT DATEADD(day, num_inner.n, CONVERT(DATE, '2021.06.11', 102) ) as dt
               FROM dbo.nums num_inner
              WHERE num_inner.n <= 5
             ) dates
 ORDER BY empid, dt;
 
-- (2) Explain what’s wrong in the following query, and provide a correct alternative:
SELECT Customers.custid, Customers.companyname, Orders.orderid, Orders.orderdate
  FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
    ON Customers.custid = Orders.custid;

SELECT C.custid, C.companyname, O.orderid, O.orderdate
  FROM Sales.Customers AS C
 INNER JOIN Sales.Orders AS O
    ON C.custid = O.custid;

-- (3) Return US customers, and for each customer return the total number of orders
--     and total quantities:
SELECT o.custid, count(distinct o.orderid) as numorders, SUM(od.qty) as totalqty
  FROM (SELECT distinct c.custid
          FROM Sales.Customers c
         WHERE c.country = N'USA') usa_cust
  JOIN Sales.Orders o on o.custid = usa_cust.custid
  JOIN Sales.OrderDetails od on od.orderid = o.orderid
 GROUP BY o.custid;

-- (4) Return customers and their orders, including customers who placed no orders:
SELECT c.custid, c.companyname, o.orderid, o.orderdate
  FROM Sales.Customers c
  LEFT JOIN Sales.Orders o on c.custid = o.custid;

-- (5) Return customers who placed no orders:
SELECT c.custid, c.companyname
  FROM Sales.Customers c
  LEFT JOIN Sales.Orders o on c.custid = o.custid
 WHERE o.orderid is null;

-- (6) Return customers with orders placed on February 12, 2022, along with their orders:
SELECT c.custid, c.companyname, o.orderid, o.orderdate
  FROM Sales.Customers c
 INNER JOIN Sales.Orders o on o.orderdate = CONVERT(DATE, '2022.02.12', 102)
                          and c.custid = o.custid;

-- (7) Write a query that returns all customers, but matches them with their respective
--     orders only if they were placed on February 12, 2022:
SELECT c.custid, c.companyname, o.orderid, o.orderdate
  FROM Sales.Customers c
  LEFT JOIN Sales.Orders o on o.orderdate = CONVERT(DATE, '2022.02.12', 102)
                          and c.custid = o.custid;

-- (8) Explain why the following query isn’t a correct solution query for Exercise 7:
SELECT C.custid, C.companyname, O.orderid, O.orderdate
  FROM Sales.Customers AS C
  LEFT OUTER JOIN Sales.Orders AS O
    ON O.custid = C.custid
 WHERE O.orderdate = '20220212'
    OR O.orderid IS NULL;
-- Where clause of the query returns only customers and their orders if orders are placed
-- on February 12, 2022 or if there were no orders at all

-- (9) Return all customers, and for each return a Yes/No value depending on whether
--     the customer placed orders on February 12, 2022:
-- Tables involved: Sales.Customers and Sales.Orders
SELECT distinct c.custid, c.companyname, 
  CASE WHEN o.orderid IS NULL THEN 'No' ELSE 'Yes' END as HasOrderOn20220212
  FROM Sales.Customers as c
  LEFT JOIN Sales.Orders as o
    ON o.orderdate = CONVERT(DATE, '2022.02.12', 102)
   and c.custid = o.custid
 ORDER BY 1, 2, 3; 