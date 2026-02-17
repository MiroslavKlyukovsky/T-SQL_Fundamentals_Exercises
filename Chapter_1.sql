-- (1) Write a query against the Sales.Orders table that returns orders placed in June 2021:
SELECT o.orderid, o.orderdate, o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2021.06.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2021.07.01', 102);

-- (2) Write a query against the Sales.Orders table that returns orders placed on the day before the last day of the month:
SELECT o.orderid, o.orderdate, o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate = DATEADD(day, -1, EOMONTH(o.orderdate));

-- (3) Write a query against the HR.Employees table that returns employees with a last name containing the letter e twice or more:
SELECT e.empid, e.firstname, e.lastname
  FROM HR.Employees e
 WHERE len(e.lastname) - len(REPLACE(e.lastname,'e','')) >= 2;

-- (4) Write a query against the Sales.OrderDetails table that returns orders with a total value (quantity *unitprice) greater
--     than 10,000, sorted by total value, descending:
SELECT od.orderid as orderid, SUM(od.qty * od.unitprice) as totalvalue
  FROM Sales.OrderDetails od
 GROUP BY od.orderid
HAVING SUM(od.qty * od.unitprice) > 10000
 ORDER BY totalvalue DESC;

-- (5) To check the validity of the data, write a query against the HR.Employees table that returns employees
--     with a last name that starts with a lowercase English letter in the range a through z. Remember that the
--     collation of the sample database is case insensitive (Latin1_General_CI_CP1_AS if you didn’t choose an
--     explicit collation during the SQL Server installation, or Latin1_General_CI_AS if you chose Windows
--     collation, Case Insensitive, Accent Sensitive):
SELECT e.empid, e.lastname
  FROM HR.Employees e
 WHERE e.lastname COLLATE Latin1_General_CS_AS LIKE N'[abcdefghijklmnopqrstuvwxyz]%';

-- (6) Explain the difference between the following two queries:
-- Query 1
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
WHERE orderdate < '20220501'
GROUP BY empid;
-- How many orders did employee before 2022 MAY first;
-- Query 2
SELECT empid, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY empid
HAVING MAX(orderdate) < '20220501';
-- How many orders did employee whose last order was made before 2022 MAY first;

-- (7) Write a query against the Sales.Orders table that returns the three shipped-to countries with the
--     highest average freight for orders placed in 2021:
SELECT TOP (3) o.shipcountry, AVG(o.freight) as avgfreight
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2021.01.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.01.01', 102)
 GROUP BY o.shipcountry
 ORDER BY avgfreight DESC;

-- (8) Write a query against the Sales.Orders table that calculates row numbers for orders based on order
--     date ordering (using the order ID as the tiebreaker) for each customer separately:
SELECT o.custid, o.orderdate, o.orderid, 
       ROW_NUMBER() over (partition by o.custid order by o.orderdate,o.orderid) as rownum
  FROM Sales.Orders o;

-- (9) Using the HR.Employees table, write a SELECT statement that returns for each employee the gender
--     based on the title of courtesy. )or '0s.' and '0rs.' return ')emale' for '0r.' return '0ale' and in all other
--     cases for example, 'Dr.' return 'UnNnown':
SELECT e.empid, e.firstname, e.lastname, e.titleofcourtesy,
       CASE WHEN e.titleofcourtesy in ('Ms.','Mrs.') THEN 'Female'
            WHEN e.titleofcourtesy = 'Mr' THEN 'Male' 
            ELSE 'Unknown' END as gender
  FROM HR.Employees e;

-- (10) Write a query against the Sales.Customers table that returns for each customer the customer ID and
--      region. Sort the rows in the output by region, ascending, having NULLs sort last (after non-NULL values).
--      Note that the default sort behavior for NULLs in TS4/ is to sort first before nonNULL values):
SELECT c.custid, c.region
  FROM Sales.Customers c
 ORDER BY CASE WHEN c.region IS NULL THEN 1 ELSE 0 END, 
       c.region ASC; 