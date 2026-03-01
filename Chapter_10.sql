-- (1) Exercises 1-1 through 1-6 deal with blocking. They assume you’re using the
--     isolation level READ COMMITTED (locking). Remember that this is the default
--     isolation level in a SQL Server box product. To perform these exercises
--     on Azure SQL Database, you need to turn versioning off.
ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT OFF;

-- (1.1) Open three connections in SQL Server Management Studio.
--       (The exercises will refer to them as Connection 1, Connection 2,
--       and Connection 3.) Run the following code in Connection 1 to open a
--       transaction and update rows in Sales.OrderDetails:
BEGIN TRAN;
 UPDATE Sales.OrderDetails
 SET discount = 0.05
 WHERE orderid = 10249;

-- (1.2) Run the following code in Connection 2 to query Sales.OrderDetails;
--       Connection 2 will be blocked:
SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

-- (1.3) Run the following code in Connection 3, and identify the locks and
--       session IDs involved in the blocking chain:
SELECT -- use * to explore
 request_session_id AS sid,
 resource_type AS restype,
 resource_database_id AS dbid,
 resource_description AS res,
 resource_associated_entity_id AS resid,
 request_mode AS mode,
 request_status AS status
FROM sys.dm_tran_locks;

-- sid 51 is blocking sid 52

-- (1.4) Replace the session IDs 52 and 53 with the ones you found to be involved
--       in the blocking chain in the previous exercise.
--       Run the following code to obtain connection, session, and blocking information
--       about the processes involved in the blocking chain:
-- Connection info:
SELECT -- use * to explore
 session_id AS sid,
 connect_time,
 last_read,
 last_write,
 most_recent_sql_handle
FROM sys.dm_exec_connections
WHERE session_id IN(51, 52);

-- Session info
SELECT -- use * to explore
 session_id AS sid,
 login_time,
 host_name,
 program_name,
 login_name,
 nt_user_name,
 last_request_start_time,
 last_request_end_time
FROM sys.dm_exec_sessions
WHERE session_id IN(51, 52);

-- Blocking
SELECT -- use * to explore
 session_id AS sid,
 blocking_session_id,
 command,
 sql_handle,
 database_id,
 wait_type,
 wait_time,
 wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id > 0;

-- (1.5) Run the following code to obtain the SQL text of the connections
--       involved in the blocking chain:
SELECT session_id, text
FROM sys.dm_exec_connections
 CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS ST
WHERE session_id IN(51, 52);

-- 51: BEGIN TRAN;   UPDATE Sales.OrderDetails   SET discount = 0.05   WHERE orderid = 10249;
-- 52: (@1 smallint)SELECT [orderid],[productid],[unitprice],[qty],[discount] FROM [Sales].[OrderDetails] WHERE [orderid]=@1

-- (1.6) Run the following code in Connection 1 to roll back the transaction:
ROLLBACK TRAN;
--       Observe in Connection 2 that the SELECT query returned the two order detail rows,
--       and that those rows were not modified - namely, their discounts remained 0.000.
--       Remember that if you need to terminate the blocker’s transaction,
--       you can use the KILL command. Close all connections.

-- (2) Exercises 2-1 through 2-6 deal with isolation levels.
-- (2.1) In this exercise, you’ll practice using the READ UNCOMMITTED isolation level.
-- (2.1.a) Open two new connections. (This exercise will refer to them as Connection 1
--         and Connection 2.) As a reminder, make sure that you’re connected to the sample database TSQLV6.
-- (2.1.b) Run the following code in Connection 1 to open a transaction, update rows in Sales.OrderDetails, and
--         query it:
BEGIN TRAN;
 UPDATE Sales.OrderDetails
 SET discount += 0.05
 WHERE orderid = 10249;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.1.c) Run the following code in Connection 2 to set the isolation level to READ UNCOMMITTED and query
--         Sales.OrderDetails:
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;
-- Notice that you get the modified, uncommitted version of the rows.
-- (2.1.d) Run the following code in Connection 1 to roll back the transaction:
ROLLBACK TRAN;

-- (2.2) In this exercise, you’ll practice using the READ COMMITTED isolation level.
-- (2.2.a) Run the following code in Connection 1 to open a transaction, update rows in Sales.OrderDetails,
--         and query it:
BEGIN TRAN;
 UPDATE Sales.OrderDetails
 SET discount += 0.05
 WHERE orderid = 10249;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.2.b) Run the following code in Connection 2 to set the isolation level to READ COMMITTED and query
--         Sales.OrderDetails:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;
-- Notice that you’re now blocked.

-- (2.2.c) Run the following code in Connection 1 to commit the transaction:
COMMIT TRAN;

-- (2.2.d) Go to Connection 2, and notice that you get the modified, committed version of the rows.

-- (2.2.e) Run the following code for cleanup:
UPDATE Sales.OrderDetails
 SET discount = 0.00
WHERE orderid = 10249;

-- (2.3) In this exercise, you’ll practice using the REPEATABLE READ isolation level.
-- (2.3.a) Run the following code in Connection 1 to set the isolation level to REPEATABLE READ, open a
--         transaction, and read data from Sales.OrderDetails:
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRAN;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;
-- You get two rows with discount values of 0.00.

-- (2.3.b) Run the following code in Connection 2, and notice that you’re blocked:
UPDATE Sales.OrderDetails
 SET discount += 0.05
WHERE orderid = 10249;

-- (2.3.c) Run the following code in Connection 1 to read the data again and commit the transaction:
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;
COMMIT TRAN;
-- You get the two rows with discount values of 0.00 again, giving you repeatable reads. Note that
-- if your code were running under a lower isolation level (such as READ UNCOMMITTED or READ
-- COMMITTED), the UPDATE statement wouldn’t be blocked and you would get nonrepeatable reads.

-- (2.3.d) Go to Connection 2, and notice that the update has finished.

-- (2.3.e) Run the following code for cleanup:
UPDATE Sales.OrderDetails
 SET discount = 0.00
WHERE orderid = 10249;

-- (2.4) In this exercise, you’ll practice using the SERIALIZABLE isolation level.

-- (2.4.a) Run the following code in Connection 1 to set the isolation level to SERIALIZABLE and query
--         Sales.OrderDetails:
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRAN;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.4.b) Run the following code in Connection 2 to attempt to insert a row to Sales.OrderDetails
--         with the same order ID that is filtered by the previous query, and notice that you·re blocked:
INSERT INTO Sales.OrderDetails
 (orderid, productid, unitprice, qty, discount)
 VALUES(10249, 2, 19.00, 10, 0.00);
-- Note that in lower isolation levels (such as READ UNCOMMITTED, READ COMMITTED, or
-- REPEATABLE READ), this INSERT statement wouldn’t be blocked.

-- (2.4.c) Run the following code in Connection 1 to query Sales.OrderDetails again and
--         commit the transaction:
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;
COMMIT TRAN;
-- You get the same result set you got from the previous query in the same transaction, and because
-- the INSERT statement was blocked, you get no phantom reads.

-- (2.4.d) Go back to Connection 2, and notice that the INSERT statement has finished.

-- (2.4.e) Run the following code for cleanup:
DELETE FROM Sales.OrderDetails
WHERE orderid = 10249
 AND productid = 2;

-- (2.4.f) Run the following code in both Connection 1 and Connection 2 to set the isolation level
--         to the default:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- (2.5) In this exercise, you’ll practice using the SNAPSHOT isolation level.
-- (2.5.a) Run the following code to allow the SNAPSHOT isolation level in the TSQLV6 database:
ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION ON;

-- (2.5.b) Run the following code in Connection 1 to open a transaction,
--         update rows in Sales.OrderDetails, and query it:
BEGIN TRAN;
 UPDATE Sales.OrderDetails
 SET discount += 0.05
 WHERE orderid = 10249;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.5.c) Run the following code in Connection 2 to set the isolation level to SNAPSHOT and query
--         Sales.OrderDetails. Notice that you’re not blocked—instead, you get an earlier,
--         consistent version of the data that was available when the transaction started
--         (with discount values of 0.00):
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
BEGIN TRAN;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.5.d) Go to Connection 1 and commit the transaction:
COMMIT TRAN;

-- (2.5.e) Go to Connection 2 and query the data again; notice that you still get discount values of 0.00:
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.5.f) In Connection 2, commit the transaction and query the data again;
--         notice that now you get discount values of 0.05:
COMMIT TRAN;
SELECT orderid, productid, unitprice, qty, discount
FROM Sales.OrderDetails
WHERE orderid = 10249;

-- (2.5.g) Run the following code for cleanup:
UPDATE Sales.OrderDetails
 SET discount = 0.00
WHERE orderid = 10249;
-- Close all connections.

-- (2.6) In this exercise, you’ll practice using the READ COMMITTED SNAPSHOT isolation level.
-- (2.6.a) Turn on READ_COMMITTED_SNAPSHOT in the TSQLV6 database by running the following code in any
--         connection:
ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT ON;

-- (2.6.b) Open two new connections. (This exercise will refer to them as Connection 1 and Connection 2.)

-- (2.6.c) Run the following code in Connection 1 to open a transaction,
--         update rows in Sales.OrderDetails, and query it:
BEGIN TRAN;
 UPDATE Sales.OrderDetails
 SET discount += 0.05
 WHERE orderid = 10249;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.6.d) Run the following code in Connection 2, which is now running under the READ COMMITTED SNAPSHOT
--         isolation level because the database flag READ_COMMITTED_SNAPSHOT is turned on. Notice
--         that you’re not blocked—instead, you get an earlier, consistent version of the data
--         that was available when the statement started (with discount values of 0.00):
BEGIN TRAN;
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;

-- (2.6.e) Go to Connection 1 and commit the transaction:
COMMIT TRAN;

-- (2.6.f) Go to Connection 2, query the data again, and commit the transaction.
--         Notice that you get the new discount values of 0.05:
 SELECT orderid, productid, unitprice, qty, discount
 FROM Sales.OrderDetails
 WHERE orderid = 10249;
COMMIT TRAN;

-- (2.6.g) Run the following code for cleanup:
UPDATE Sales.OrderDetails
 SET discount = 0.00
WHERE orderid = 10249;
-- Close all connections.

-- (2.6.h) Change the database flags back to the defaults in a box product,
--         disabling isolation levels based on row versioning:
ALTER DATABASE TSQLV6 SET ALLOW_SNAPSHOT_ISOLATION OFF;
ALTER DATABASE TSQLV6 SET READ_COMMITTED_SNAPSHOT OFF;
-- Note that if you want to change these settings back to the defaults in Azure SQL Database, you’ll
-- need to set both to ON.

-- (3) (steps 1 through 7) deals with deadlocks. It assumes that versioning is turned off.
-- (3.1) Open two new connections. (This exercise will refer to them as Connection 1 and Connection 2.)

-- (3.2) Run the following code in Connection 1 to open a transaction and update the row for product 2
--       in Production.Products:
BEGIN TRAN;
 UPDATE Production.Products
 SET unitprice += 1.00
 WHERE productid = 2;

-- (3.3) Run the following code in Connection 2 to open a transaction and update the row for product 3
--       in Production.Products:
BEGIN TRAN;
 UPDATE Production.Products
 SET unitprice += 1.00
 WHERE productid = 3;

-- (3.4) Run the following code in Connection 1 to query product 3. You will be blocked.
 SELECT productid, unitprice
 FROM Production.Products
 WHERE productid = 3;
COMMIT TRAN;

-- (3.5) Run the following code in Connection 2 to query product 2. You will be blocked,
--       and a deadlock error will be generated either in Connection 1 or Connection 2:
 SELECT productid, unitprice
 FROM Production.Products
 WHERE productid = 2;
COMMIT TRAN;

-- (3.6) Can you suggest a way to prevent this deadlock? Refer back to what you read in the “Deadlocks”
--       section-specifically, ways to mitigate deadlock occurrences.

/* To prevent the deadlock it's possible to change positions of the SELECT and the UPDATE in 2nd Connection
If done so, the deadlock is prevented and the code executes successfully.*/

-- (3.7) Run the following code for cleanup:
UPDATE Production.Products
 SET unitprice = 19.00
WHERE productid = 2;
UPDATE Production.Products
 SET unitprice = 10.00
WHERE productid = 3;