-- (1.1) Insert into the dbo.Customers table a row with the following information:
--       custid: 100
--       companyname: Coho Winery
--       country: USA
--       region: WA
--       city: Redmond
INSERT INTO dbo.Customers(custid, companyname,country,region,city)
     VALUES (100,N'Coho Winery',N'USA',N'WA',N'Redmond');

-- (1.2) Insert into the dbo.Customers table all customers from Sales.Customers who placed orders.
INSERT INTO dbo.Customers(custid, companyname,country,region,city)
  SELECT c.custid, c.companyname, c.country, c.region, c.city
    FROM Sales.Customers c
   WHERE EXISTS(SELECT 1
                  FROM Sales.Orders o
                 WHERE o.custid = c.custid);

-- (1.3) Use a SELECT INTO statement to create and populate the dbo.Orders
--       table with orders from the Sales.Orders table that were placed
--       in the years 2020 through 2022.
SELECT so.*
  INTO dbo.Orders
  FROM Sales.Orders so
 WHERE so.orderdate >= CONVERT(DATE, '2020.01.01', 102) 
   AND so.orderdate <  CONVERT(DATE, '2023.01.01', 102);

 -- (2) To delete orders placed before August 2020, you need a DELETE
 --     statement with a filter based on the predicate orderdate < '20200801'.
 --     As requested, use the OUTPUT clause to return attributes from the deleted rows:
DELETE FROM dbo.Orders
     OUTPUT deleted.orderid, deleted.orderdate
 WHERE orderdate < CONVERT(DATE, '2020.08.01', 102);

-- (3) Delete from the dbo.Orders table orders placed by customers from Brazil.
DELETE FROM o
  FROM dbo.Orders as o
 INNER JOIN dbo.Customers as c ON o.custid = c.custid
 WHERE c.country = N'Brazil';

-- (4) Run the following query against dbo.Customers,
--     and notice that some rows have a NULL in the region column:
-- SELECT * FROM dbo.Customers;
--     Update the dbo.Customers table, and change all NULL region
--     values to <None>. Use the OUTPUT clause to show the custid, oldregion, and newregion:
UPDATE dbo.Customers 
   SET region = '<None>'
OUTPUT deleted.custid, deleted.region as oldregion, inserted.region as newregion
 WHERE region is Null;

-- (5) Update all orders in the dbo.Orders table that were placed
--     by United Kingdom customers, and set their shipcountry, shipregion,
--     and shipcity values to the country, region, and city values of the corresponding
--     customers.    
UPDATE Orders 
   SET shipcountry = Customers.country,
       shipregion  = Customers.region,
       shipcity    = Customers.city
  FROM dbo.Orders JOIN dbo.Customers
    ON Orders.custid = Customers.custid
 WHERE Customers.country = N'UK';

-- (6) Write and test the T-SQL code that is required to truncate both tables,
--     and make sure your code runs successfully.
ALTER TABLE dbo.OrderDetails DROP CONSTRAINT FK_OrderDetails_Orders;

TRUNCATE TABLE dbo.OrderDetails;
TRUNCATE TABLE dbo.Orders;

ALTER TABLE dbo.OrderDetails ADD CONSTRAINT FK_OrderDetails_Orders
 FOREIGN KEY(orderid) REFERENCES dbo.Orders(orderid);