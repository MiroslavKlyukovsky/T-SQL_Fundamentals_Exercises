-- (1) Write a query that returns all orders placed on the last day of activity
--     that can be found in the Orders table:
SELECT o.orderid, o.orderdate, o.custid, o.empid
  FROM Sales.Orders o
 INNER JOIN (SELECT MAX(o_inner.orderdate) as _date 
               FROM Sales.Orders o_inner
              WHERE o_inner.orderdate is not null) max_date
    ON max_date._date = o.orderdate;

-- (2) Write a query that returns all orders placed by the customer(s)
--     who placed the highest number of orders. Note that more than one
--     customer might have the same number of orders:
SELECT o.custid, o.orderid, o.orderdate, o.empid
  FROM Sales.Orders o
 INNER JOIN (SELECT o_outer.custid
               FROM Sales.Orders o_outer
              GROUP BY o_outer.custid
             HAVING COUNT(o_outer.orderid) = (SELECT MAX(T1.orders) 
                                                FROM (SELECT o_inner.custid, 
                                                             COUNT(o_inner.orderid) as orders
                                                        FROM Sales.Orders o_inner
                                                       GROUP BY o_inner.custid) T1)) T2
    ON o.custid = T2.custid;

SELECT o.custid, o.orderid, o.orderdate, o.empid
  FROM Sales.Orders o
 INNER JOIN (SELECT TOP(1) WITH TIES inner_o.custid
               FROM Sales.Orders inner_o
              GROUP BY inner_o.custid
              ORDER BY COUNT(inner_o.orderid) DESC) T1
    ON o.custid = T1.custid;

-- (3) Write a query that returns employees who did not place orders on or after May 1, 2022:
SELECT e.empid, e.firstname, e.lastname
  FROM HR.Employees e
  EXCEPT
SELECT T1.empid, e.firstname, e.lastname
  FROM (SELECT o.empid
          FROM Sales.Orders o
         WHERE o.orderdate >= CONVERT(DATE, '2022.05.01', 102)
         GROUP BY o.empid) T1
         INNER JOIN HR.Employees e ON e.empid = T1.empid;

-- (4) Write a query that returns countries where there are customers but not employees:
-- Tables involved: Sales.Customers and HR.Employees
SELECT DISTINCT c.country
  FROM Sales.Customers c
  EXCEPT
SELECT DISTINCT e.country
  FROM HR.Employees e;

-- (5) Write a query that returns for each customer all orders placed
--     on the customer’s last day of activity:
SELECT o.custid, o.orderid, o.orderdate, o.empid
  FROM Sales.Orders o
 INNER JOIN (SELECT inner_o.custid, MAX(inner_o.orderdate) max_date
               FROM Sales.Orders inner_o
              GROUP BY inner_o.custid) T1 ON o.custid = T1.custid 
                                         AND o.orderdate = T1.max_date;

-- (6) Write a query that returns customers who placed orders in 2021 but not in 2022:
SELECT cust.custid, c.companyname
  FROM (SELECT DISTINCT o.custid
          FROM Sales.Orders o
         WHERE o.orderdate >= CONVERT(DATE, '2021.01.01', 102) 
           and o.orderdate  < CONVERT(DATE, '2022.01.01', 102)
            EXCEPT
        SELECT DISTINCT o.custid
          FROM Sales.Orders o
         WHERE o.orderdate >= CONVERT(DATE, '2022.01.01', 102) 
           and o.orderdate  < CONVERT(DATE, '2023.01.01', 102)) cust
 INNER JOIN Sales.Customers c ON c.custid = cust.custid;

-- (7) Write a query that returns customers who ordered product 12:
SELECT cust.custid, c.companyname
  FROM (SELECT DISTINCT o.custid
          FROM Sales.OrderDetails od
         INNER JOIN Sales.Orders o ON od.productid = 12
                                  and od.orderid = o.orderid) cust
 INNER JOIN Sales.Customers c ON c.custid = cust.custid;

SELECT custid, companyname
  FROM Sales.Customers AS C
 WHERE EXISTS (SELECT 1
                 FROM Sales.Orders AS O
                WHERE O.custid = C.custid
                  AND EXISTS (SELECT 1
                                FROM Sales.OrderDetails AS OD
                               WHERE OD.orderid = O.orderid
                                 AND OD.ProductID = 12));

-- (8) Write a query that calculates a running-total quantity for each customer and month:
SELECT co.custid, co.ordermonth, co.qty, 
       SUM(co.qty) over (partition by co.custid
                             order by co.ordermonth 
                             rows between unbounded preceding and current row) as runqty
  FROM Sales.CustOrders co 
 ORDER BY co.custid, co.ordermonth;

-- (9) Explain the difference between IN and EXISTS:
/* IN is used because of need to check if a value is in one of those in ().
Not only literals can be in () but queries too.*/

/* EXISTS is used because of need to know if certain row does even exist in a table,
system starts to look in the table and returns True when finds first occurence. 
Cool thing EXISTS does not check whole table, it only check until first occurence, so it is fast.*/ 

-- (10) Write a query that returns for each order the number of days that passed since the same customer’s
--      previous order. To determine recency among orders, use orderdate as the primary sort element and
--      orderid as the tiebreaker:
SELECT o.custid, o.orderdate, o.orderid, 
       (select DATEDIFF(day, MAX(inner_o.orderdate), o.orderdate) 
          from Sales.Orders inner_o
         where o.custid = inner_o.custid and (inner_o.orderdate < o.orderdate
            or (inner_o.orderdate = o.orderdate and inner_o.orderid < o.orderid))) as diff
  FROM Sales.Orders o
 ORDER BY o.custid, o.orderdate, o.orderid;