-- (1) The following query attempts to filter orders that were not placed
--     on the last day of the year. It·s supposed to return the order ID, order date,
--     customer ID, employee ID, and respective end-of-year date for each order:
-- SELECT orderid, orderdate, custid, empid,
--        DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
--   FROM Sales.Orders
--  WHERE orderdate <> endofyear;
-- When you try to run this query, you get the following error:
/* Msg 207, Level 16, State 1, Line 17
   Invalid column name 'endofyear'.
   Explain what the problem is, and suggest a valid solution*/
SELECT o.orderid, o.orderdate, o.custid, o.empid,
       DATEFROMPARTS(YEAR(orderdate), 12, 31) AS endofyear
  FROM Sales.Orders o
 WHERE o.orderdate <> DATEFROMPARTS(YEAR(o.orderdate), 12, 31);

SELECT T1.orderid, T1.orderdate, T1.custid, T1.empid, T1.endofyear
  FROM (SELECT o_inner.orderid, o_inner.orderdate, o_inner.custid, o_inner.empid,
               DATEFROMPARTS(YEAR(o_inner.orderdate), 12, 31) AS endofyear
          FROM Sales.Orders o_inner) T1
 WHERE T1.orderdate <> T1.endofyear;

SELECT o.orderid, o.orderdate, o.custid, o.empid, T1.endofyear 
  FROM Sales.Orders o
 INNER JOIN (SELECT o_inner.orderid, DATEFROMPARTS(YEAR(o_inner.orderdate), 12, 31) AS endofyear 
               FROM Sales.Orders o_inner) T1
       ON o.orderid = T1.orderid 
 WHERE o.orderdate <> T1.endofyear;

-- (2.1) Write a query that returns the maximum value in the orderdate column for each employee:
SELECT o.empid, MAX(o.orderdate) as maxorderdate
  FROM Sales.Orders o
 GROUP BY o.empid
 ORDER BY o.empid;

-- (2.2) Encapsulate the query from Exercise 2-1 in a derived table.
--       Write a join query between the derived table and the Orders table
--       to return the orders with the maximum order date for each employee:
SELECT o.empid, o.orderdate, o.orderid, o.custid
  FROM Sales.Orders o
 INNER JOIN (SELECT o_inner.empid, MAX(o_inner.orderdate) as maxorderdate
               FROM Sales.Orders o_inner
              GROUP BY o_inner.empid) T1 ON T1.empid = o.empid 
                                        AND T1.maxorderdate = o.orderdate;

-- (3.1) Write a query that calculates a row number for each order based on orderdate, orderid ordering:
SELECT o.orderid, o.orderdate, o.custid, o.empid,
       ROW_NUMBER() OVER (ORDER BY orderdate, orderid) as rownum
  FROM Sales.Orders o
 ORDER BY o.orderdate, o.orderid;

-- (3.2) Write a query that returns rows with row numbers 11 through 20 based on the row-number definition in
--       Exercise 3-1. Use a CTE to encapsulate the code from Exercise 3-1:
WITH numbered_orders as (SELECT o.orderid, o.orderdate, o.custid, o.empid,
                                ROW_NUMBER() OVER (ORDER BY orderdate, orderid) as rownum
                           FROM Sales.Orders o)
SELECT numbered_orders.orderid,
       numbered_orders.orderdate, 
       numbered_orders.custid,
       numbered_orders.empid,
       numbered_orders.rownum
  FROM numbered_orders
 WHERE numbered_orders.rownum BETWEEN 11 AND 20
 ORDER BY numbered_orders.rownum;

-- (4) Write a solution using a recursive CTE that returns the management chain leading to Patricia Doyle
--     (employee ID 9):
WITH T1 AS (SELECT e.empid, e.mgrid, e.firstname, e.lastname
              FROM HR.Employees e
             WHERE e.empid = 9
             UNION ALL
            SELECT e.empid, e.mgrid, e.firstname, e.lastname
              FROM HR.Employees e INNER JOIN T1 ON e.empid = T1.mgrid)
SELECT T1.empid, T1.mgrid, T1.firstname, T1.lastname
  FROM T1
 ORDER BY T1.empid, T1.mgrid;

-- (5-1) Create a view that returns the total quantity for each employee and year.
--       Tables involved: Sales.Orders and Sales.OrderDetails
--       When running the following code:
-- SELECT * FROM Sales.VEmpOrders ORDER BY empid, orderyear;
IF EXISTS (SELECT * FROM sys.views WHERE name = 'VEmpOrders' AND schema_id = SCHEMA_ID('Sales'))
     DROP VIEW Sales.VEmpOrders;
GO

CREATE VIEW Sales.VEmpOrders AS
  SELECT o.empid, YEAR(o.orderdate) as orderyear, SUM(qty) as qty
    FROM Sales.Orders o INNER JOIN Sales.OrderDetails od
      ON o.orderid = od.orderid
   GROUP BY o.empid, YEAR(o.orderdate);
GO

SELECT * FROM Sales.VEmpOrders ORDER BY empid, orderyear;

-- (5-2) Write a query against Sales.VEmpOrders that returns the running total quantity
--       for each employee and year:
SELECT veo.empid, veo.orderyear, veo.qty,
       SUM(veo.qty) OVER (partition by veo.empid 
                              order by veo.orderyear) as runqty
  FROM Sales.VEmpOrders veo
 ORDER BY veo.empid, veo.orderyear;

-- (6.1) Create an inline TVF that accepts as inputs a supplier ID (@supid AS INT) and
--       a requested number of products (@n AS INT). The function should return @n products
--       with the highest unit prices that are supplied by the specified supplier ID:
-- When issuing the following query:
-- SELECT * FROM Production.TopProducts(5, 2);
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Production.TopProducts') AND type IN (N'FN', N'IF', N'TF'))
    DROP FUNCTION Production.TopProducts;
GO

CREATE FUNCTION Production.TopProducts
(
  @supid INT,
  @n     INT
)        
RETURNS TABLE
AS
RETURN
      (SELECT TOP(@n) p.productid, p.productname, p.unitprice 
         FROM Production.Products p
        WHERE p.supplierid = @supid
        ORDER BY p.unitprice DESC);
GO

SELECT * FROM Production.TopProducts(5, 2);

-- (6.2) Using the CROSS APPLY operator and the function you created in Exercise 6-1, return the two most
--       expensive products for each supplier:
-- Table involved: Production.Suppliers
SELECT s.supplierid, s.companyname, p.productid, p.productname, p.unitprice
  FROM Production.Suppliers s
 CROSS APPLY Production.TopProducts(s.supplierid, 2) AS p
 ORDER BY s.supplierid, p.unitprice desc;


DROP VIEW IF EXISTS Sales.VEmpOrders;
DROP FUNCTION IF EXISTS Production.TopProducts;