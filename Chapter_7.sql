-- (1) Write a query against the dbo.Orders table that computes both a rank
--     and a dense rank for each customer order, partitioned by custid and ordered by qty:
SELECT o.custid, o.orderid, o.qty,
       RANK()       OVER(partition by custid order by o.qty) as rnk, 
       DENSE_RANK() OVER(partition by custid order by o.qty) as drnk
  FROM dbo.Orders o
 ORDER BY o.custid, o.qty;

SELECT o.custid, o.orderid, o.qty,
       RANK()       OVER W AS rnk,
       DENSE_RANK() OVER W AS drnk
  FROM dbo.Orders o
WINDOW W AS (PARTITION BY o.custid ORDER BY o.qty);

-- (2) Earlier in the chapter, in the section “Ranking window functions,”
--     I provided the following query against the Sales.OrderValues view to return
--     distinct values and their associated row numbers:
/* SELECT val, ROW_NUMBER() OVER(ORDER BY val) AS rownum
     FROM Sales.OrderValues
    GROUP BY val;*/
--     Can you think of an alternative way to achieve the same task?
SELECT DISTINCT ov.val, DENSE_RANK() OVER(ORDER BY ov.val) AS rownum
  FROM Sales.OrderValues ov;

WITH C AS
(
 SELECT DISTINCT ov.val
 FROM Sales.OrderValues ov
)
SELECT C.val, ROW_NUMBER() OVER(ORDER BY C.val) AS rownum
FROM C;

-- (3) Write a query against the dbo.Orders table that computes for each customer
--     order both the difference between the current order quantity and the customer’s
--     previous order quantity and the difference between the current order quantity
--     and the customer’s next order quantity:
SELECT o.custid, o.orderid, o.qty,
       o.qty - LAG(o.qty)  OVER W as diffprev,
       o.qty - LEAD(o.qty) OVER W as diffnext
  FROM dbo.Orders o
WINDOW W AS (partition by o.custid order by o.orderdate)
 ORDER BY o.custid, o.orderdate;

-- (4) Write a query against the dbo.Orders table that returns a row for each employee,
--     a column for each order year, and the count of orders for each employee and order year:
SELECT p.empid, p.[2020] AS cnt2020, p.[2021] AS cnt2021, p.[2022] AS cnt2022
  FROM (SELECT empid, orderid, YEAR(orderdate) as orderyear 
          FROM dbo.Orders) o
 PIVOT (COUNT(o.orderid) 
         for o.orderyear in ([2020],[2021],[2022])) as p;

-- (5) Write a query against the EmpYearOrders table that unpivots the data,
--     returning a row for each employee and order year with the number of orders.
--     Exclude rows in which the number of orders is 0 (in this example, employee 3 in the year 2021).
SELECT empid, CAST(RIGHT(orderyear, 4) AS INT) AS orderyear, numorders
  FROM dbo.EmpYearOrders eyo
  UNPIVOT (numorders for orderyear in ([cnt2020],[cnt2021],[cnt2022])) as unpvt
 WHERE numorders > 0;

-- (6) Write a query against the dbo.Orders table that returns the total quantities
--     for each of the following: (employee, customer, and order year),
--     (employee and order year), and (customer and order year).
--     Include a result column in the output that uniquely identifies
--     the grouping set with which the current row is associated:
SELECT GROUPING_ID(o.empid, o.custid, YEAR(o.orderdate)) AS groupingset,
                   o.empid, o.custid, YEAR(o.orderdate) AS orderyear, SUM(o.qty) AS sumqty
  FROM dbo.Orders o
 GROUP BY 
   GROUPING SETS ((o.empid, o.custid, YEAR(o.orderdate)),
                  (o.empid, YEAR(o.orderdate)),
                  (o.custid, YEAR(o.orderdate)));

-- (7) Write a query against the Sales.Orders table that returns a row for each week,
--     assuming the week starts on a Sunday, with result columns showing when the week started,
--     when the week ended, and the week’s order count:
SELECT DATE_BUCKET(day, 7, o.orderdate,CONVERT(DATE, '1905.01.01', 102)) as startofweek,
       DATEADD(day, 6, DATE_BUCKET(day, 7, o.orderdate,CONVERT(DATE, '1905.01.01', 102))) as endofweek,
       COUNT(*) as numorders
  FROM Sales.Orders o
 GROUP BY DATE_BUCKET(day, 7, o.orderdate, CONVERT(DATE, '1905.01.01', 102))
 ORDER BY startofweek;

WITH c AS (
           SELECT DATE_BUCKET(week, 1, o.orderdate, CAST('19000107' AS DATE)) AS startofweek
             FROM Sales.Orders o
           )
SELECT c.startofweek, DATEADD(day, 6, c.startofweek) AS endofweek,
       COUNT(*) AS numorders
  FROM c
 GROUP BY c.startofweek
 ORDER BY c.startofweek;

-- (8) Suppose that your organization's fiscal year runs from July 1 to June 30.
--     Write a query against the Sales.OrderValues view that returns the total quantities
--     and values per shipper and fiscal year of the order date. The result should
--     have columns for the shipper ID, start date of fiscal year, end date of fiscal year,
--     total quantity, and total value:
SELECT t.shipperid, t.startofyear,
       EOMONTH(DATEADD(MONTH, 11, t.startofyear)) AS endofyear, 
       SUM(t.qty) AS totalqty, SUM(t.val) AS totalval
  FROM (
        SELECT ov.shipperid,
               DATE_BUCKET(YEAR, 1, ov.orderdate, CONVERT(DATE, '1900.07.01', 102)) AS startofyear,
               ov.qty,ov.val
          FROM Sales.OrderValues ov
        ) t
GROUP BY t.shipperid, t.startofyear
ORDER BY t.shipperid, t.startofyear;