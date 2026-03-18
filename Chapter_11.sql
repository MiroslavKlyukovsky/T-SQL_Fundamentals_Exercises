-- (1) In this exercise, you’ll query data from the tables Graph.Account and Graph.Follows.
-- (1.1) Write a query that identifies who follows Stav.
SELECT a_o.accountname
  FROM Graph.Account a_o
 WHERE a_o.$node_id in (SELECT f.$from_id
						  FROM Graph.Follows f
						 WHERE f.$to_id = (SELECT a_i.$node_id
											 FROM Graph.Account a_i
											WHERE a_i.accountname = N'Stav'))
 ORDER BY a_o.accountname;

SELECT follower.accountname
  FROM Graph.Account follower, Graph.Account followee, Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee)
   AND followee.accountname = N'Stav'
 ORDER BY follower.accountname;

-- (1.2) Write a query that identifies who follows Stav, Yatzek, or both.
SELECT follower.accountname, followee.accountname as follows
  FROM Graph.Account follower, Graph.Account followee, Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee)
   AND followee.accountname in (N'Stav',N'Yatzek')
 ORDER BY follower.accountname;	

-- (1.3) Write a query that identifies who follows both Stav and Yatzek.
SELECT follower.accountname
  FROM Graph.Account follower,
	   Graph.Account followee1,
	   Graph.Account followee2,
	   Graph.Follows follows1, 
       Graph.Follows follows2
 WHERE MATCH(followee1<-(follows1)-follower-(follows2)->followee2)
   AND followee1.accountname = N'Stav'
   AND followee2.accountname = N'Yatzek'
 ORDER BY follower.accountname;

-- (1.4) Write a query that identifies who follows Stav but not Yatzek.
SELECT follower.accountname AS accountname
  FROM Graph.Account follower,
	   Graph.Account followee,
       Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee)
   AND followee.accountname = N'Stav'
   EXCEPT
SELECT follower.accountname AS accountname
  FROM Graph.Account follower,
	   Graph.Account followee,
       Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee)
   AND followee.accountname = N'Yatzek'
ORDER BY accountname;

-- (2) In this exercise, you’ll query data from the tables Graph.Account, Graph.IsFriendOf, and Graph.Follows.
-- (2.1) Write a query that returns relationships where the first account is a friend of the second account,
--       follows the second account, or both.
SELECT follower.accountid AS actid1,
       follower.accountname AS act1,
	   followee.accountid AS actid2,
       followee.accountname AS act2
  FROM Graph.Account follower,
	   Graph.Account followee,
       Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee)
   UNION
SELECT account1.accountid AS actid1,
       account1.accountname AS act1,
	   account2.accountid AS actid2,
       account2.accountname AS act2
  FROM Graph.Account account1,
	   Graph.Account account2,
       Graph.IsFriendOf isfriendof
 WHERE MATCH(account1-(isfriendof)->account2);

-- (2.2) Write a query that returns relationships where the first account is a friend of, but doesn't follow, the
--       second account.
SELECT account1.accountid AS actid1,
       account1.accountname AS act1,
	   account2.accountid AS actid2,
       account2.accountname AS act2
  FROM Graph.Account account1,
	   Graph.Account account2,
       Graph.IsFriendOf isfriendof
 WHERE MATCH(account1-(isfriendof)->account2)
   EXCEPT
SELECT follower.accountid AS actid1,
       follower.accountname AS act1,
	   followee.accountid AS actid2,
       followee.accountname AS act2
  FROM Graph.Account follower,
	   Graph.Account followee,
       Graph.Follows follows
 WHERE MATCH(follower-(follows)->followee);

-- (3) Given an input post ID, possibly representing a reply to another post, return the chain of posts leading
--     to the input one. Use a recursive query. 
--     Tables involved: Graph.Post and Graph.IsReplyTo
DECLARE @postid AS INT = 1187;

WITH C AS (
  SELECT p.postid AS postid, 
         p.posttext AS posttext,
         0 AS ord_col 
    FROM Graph.Post p
   WHERE p.postid = @postid
   UNION ALL
  SELECT parentpost.postid AS postid, 
         parentpost.posttext AS posttext,
         c.ord_col + 1 AS ord_col
    FROM C c, Graph.Post replypost, Graph.Post parentpost, Graph.IsReplyTo isreplyto
   WHERE c.postid = replypost.postid  
     AND MATCH(replypost-(isreplyto)->parentpost)
)
SELECT C.postid, C.posttext
  FROM C
 ORDER BY C.ord_col DESC;

-- (4) Solve Exercise 3 again, only this time using the SHORTEST_PATH option.
DECLARE @postid AS INT = 1187;

WITH C AS
(
     SELECT postid, posttext, 0 AS sortkey
       FROM Graph.Post
      WHERE postid = @postid
      UNION ALL
     SELECT LAST_VALUE(Post.postid) WITHIN GROUP (GRAPH PATH) AS postid,
            LAST_VALUE(Post.posttext) WITHIN GROUP (GRAPH PATH) AS posttext,
            COUNT(Post.postid) WITHIN GROUP (GRAPH PATH) AS sortkey
       FROM Graph.Post AS Reply,
            Graph.IsReplyTo FOR PATH AS IRT,
            Graph.Post FOR PATH AS Post
      WHERE MATCH(SHORTEST_PATH(Reply(-(IRT)->Post)+))
        AND Reply.postid = @postid
)
SELECT C.postid, C.posttext
  FROM C
 ORDER BY C.sortkey DESC;