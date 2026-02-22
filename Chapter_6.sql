-- (1) Explain the difference between the UNION ALL and UNION operators.
--     In what cases are the two equivalent? When they are equivalent, which one should you use?

--     UNION ALL just adds rows without any filtration, UNION is an operator which
--     returns distinct rows after adding the first and second group of rows.

--     They are equivalent in cases when two groups of rows each has distinct rows, and those
--     rows are also distinct between the groups.

--     When they are equivalent UNION ALL should be used as it does not check for distinctness
--     and works faster because of it.

-- (2) Write a query that generates a virtual auxiliary table of 10 numbers
--     in the range 1 through 10 without using a looping construct
--     or the GENERATE_SERIES function. You do not need to guarantee
--     any presentation order of the rows in the output of your solution.
SELECT 1 as n
 UNION ALL
SELECT 2
 UNION ALL
SELECT 3
 UNION ALL
SELECT 4
 UNION ALL
SELECT 5
 UNION ALL
SELECT 6
 UNION ALL
SELECT 7
 UNION ALL
SELECT 8
 UNION ALL
SELECT 9
 UNION ALL
SELECT 10;

SELECT value as n
  FROM GENERATE_SERIES(1, 10, 1);

-- (3) Write a query that returns customer and employee pairs that had order activity
--     in January 2022 but not in February 2022.
--     Table involved: Sales.Orders
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.01.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.02.01', 102)
    EXCEPT
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.02.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.03.01', 102);

-- (4) Write a query that returns customer and employee pairs
--     that had order activity in both January 2022 and February 2022.
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.01.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.02.01', 102)
   INTERSECT
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.02.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.03.01', 102);

-- (5) Write a query that returns customer and employee pairs
--     that had order activity in both January 2022 and February 2022 but not in 2021.
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.01.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.02.01', 102)
   INTERSECT
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2022.02.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.03.01', 102)
    EXCEPT
SELECT o.custid, o.empid
  FROM Sales.Orders o
 WHERE o.orderdate >= CONVERT(DATE, '2021.01.01', 102) 
   and o.orderdate  < CONVERT(DATE, '2022.01.01', 102);

-- (6) You are given the following query:
/*SELECT country, region, city
    FROM HR.Employees
   UNION ALL
  SELECT country, region, city
    FROM Production.Suppliers;*/
--    You are asked to add logic to the query so that it guarantees 
--    that the rows from Employees are returned in the output before
--    the rows from Suppliers. Also, within each segment, the rows should be
--    sorted by country, region, and city.
SELECT outer_tab.country, outer_tab.region, outer_tab.city
  FROM (SELECT e.country, e.region, e.city, 1 as group_num,
               ROW_NUMBER() OVER (order by e.country, e.region, e.city) as inside_group_num
          FROM HR.Employees e
         UNION ALL
        SELECT s.country, s.region, s.city, 2 as group_num,
               ROW_NUMBER() OVER (order by s.country, s.region, s.city) as inside_group_num
          FROM Production.Suppliers s) outer_tab
 ORDER BY outer_tab.group_num, outer_tab.inside_group_num;

SELECT outer_tab.country, outer_tab.region, outer_tab.city
  FROM (SELECT e.country, e.region, e.city, 1 as group_num
          FROM HR.Employees e
         UNION ALL
        SELECT s.country, s.region, s.city, 2 as group_num
          FROM Production.Suppliers s) outer_tab
 ORDER BY outer_tab.group_num, outer_tab.country, outer_tab.region, outer_tab.city;