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