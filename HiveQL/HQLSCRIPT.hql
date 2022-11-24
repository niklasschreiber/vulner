-- VULN Securitymisc18
INCLUDE "/inc/triggers.sql"
INCLUDE '/inc/triggers.sql'

LOAD DATA INPATH 'hdfs:///browser/data/test.tsv' OVERWRITE INTO TABLE browser;
!rm -rf "/";
HOST kill -9 13453

-- VULN PLSQL.45
ADD JAR '/usr/hdp/3.1.4.0-315/hive/lib/hive-hbase-handler-3.1.0.3.1.4.0-315.jar'
-- OK
add jar 'hdfs:///usr/hdp/hive-hbase-handler-3.1.0.3.1.4.0-315.jar'  

-- VULN PLSQL.46
add jar 'jceks://secret/keys/'  
LOAD DATA LOCAL INPATH jceks://hdfs/pv_2008_us.jceks INTO TABLE page_view PARTITION(date='2008-06-08', country='US')

SET CURRENT SCHEMA = default;
SET SCHEMA = 'default';
SET SCHEMA 'def' || 'ault';

CREATE TABLE page_view(viewTime INT, userid BIGINT,
                page_url STRING, referrer_url STRING,
                ip STRING COMMENT 'IP Address of the User')
COMMENT 'This is the page view table'
PARTITIONED BY(dt STRING, country STRING)
STORED AS SEQUENCEFILE;

CREATE TABLE page_view(viewTime INT, userid BIGINT,
                page_url STRING, referrer_url STRING,
                ip STRING COMMENT 'IP Address of the User')
COMMENT 'This is the page view table'
PARTITIONED BY(dt STRING, country STRING)
ROW FORMAT DELIMITED
        FIELDS TERMINATED BY '1'
STORED AS SEQUENCEFILE;

CREATE TABLE page_view(viewTime INT, userid BIGINT,
                page_url STRING, referrer_url STRING,
                friends ARRAY<BIGINT>, properties MAP<STRING, STRING>
                ip STRING COMMENT 'IP Address of the User')
COMMENT 'This is the page view table'
PARTITIONED BY(dt STRING, country STRING)
CLUSTERED BY(userid) SORTED BY(viewTime) INTO 32 BUCKETS
ROW FORMAT DELIMITED
        FIELDS TERMINATED BY '1'
        COLLECTION ITEMS TERMINATED BY '2'
        MAP KEYS TERMINATED BY '3'
STORED AS SEQUENCEFILE;

SHOW TABLES;

SHOW PARTITIONS page_view;

DESCRIBE page_view;

DESCRIBE EXTENDED page_view;

DESCRIBE EXTENDED page_view PARTITION (ds='2008-08-08');

ALTER TABLE old_table_name RENAME TO new_table_name;

ALTER TABLE old_table_name REPLACE COLUMNS (col1 TYPE, ...);

ALTER TABLE tab1 ADD COLUMNS (c1 INT COMMENT 'a new int column', c2 STRING DEFAULT 'def val');

DROP TABLE pv_users;

ALTER TABLE pv_users DROP PARTITION (ds='2008-08-08')

-- VULN: LINES TERMINATED BY 
CREATE EXTERNAL TABLE page_view_stg(viewTime INT, userid BIGINT,
                page_url STRING, referrer_url STRING,
                ip STRING COMMENT 'IP Address of the User',
                country STRING COMMENT 'country of origination')
COMMENT 'This is the staging page view table'
ROW FORMAT DELIMITED FIELDS TERMINATED BY '44' LINES TERMINATED BY '12'
STORED AS TEXTFILE
LOCATION '/user/data/staging/page_view';
 
FROM page_view_stg pvs
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country='US')
SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip
WHERE pvs.country = 'US';

-- VULN
LOAD DATA LOCAL INPATH /tmp/pv_2008-06-08_us.txt INTO TABLE page_view PARTITION(date='2008-06-08', country='US')
-- VULN
LOAD DATA INPATH '/user/data/pv_2008-06-08_us.txt' INTO TABLE page_view PARTITION(date='2008-06-08', country='US')

INSERT OVERWRITE TABLE user_active
SELECT user.*
FROM user
WHERE user.active = 1;

SELECT user.*
FROM user
WHERE user.active = 1;

INSERT OVERWRITE TABLE xyz_com_page_views
SELECT page_views.*
FROM page_views
WHERE page_views.date >= '2008-03-01' AND page_views.date <= '2008-03-31' AND
      page_views.referrer_url like '%xyz.com';
	  
INSERT OVERWRITE TABLE pv_users
SELECT pv.*, u.gender, u.age
FROM user u JOIN page_view pv ON (pv.userid = u.id)
WHERE pv.date = '2008-03-03';

INSERT OVERWRITE TABLE pv_users
SELECT pv.*, u.gender, u.age
FROM user u FULL OUTER JOIN page_view pv ON (pv.userid = u.id)
WHERE pv.date = '2008-03-03';

NSERT OVERWRITE TABLE pv_users
SELECT u.*
FROM user u LEFT SEMI JOIN page_view pv ON (pv.userid = u.id)
WHERE pv.date = '2008-03-03';
In order to join more than one tables, the user can use the following syntax:

INSERT OVERWRITE TABLE pv_friends
SELECT pv.*, u.gender, u.age, f.friends
FROM page_view pv JOIN user u ON (pv.userid = u.id) JOIN friend_list f ON (u.id = f.uid)
WHERE pv.date = '2008-03-03';

INSERT OVERWRITE TABLE pv_gender_sum
SELECT pv_users.gender, count (DISTINCT pv_users.userid)
FROM pv_users
GROUP BY pv_users.gender;

INSERT OVERWRITE TABLE pv_gender_agg
SELECT pv_users.gender, count(DISTINCT pv_users.userid), count(*), sum(DISTINCT pv_users.userid)
FROM pv_users
GROUP BY pv_users.gender;

INSERT OVERWRITE TABLE pv_gender_agg
SELECT pv_users.gender, count(DISTINCT pv_users.userid), count(DISTINCT pv_users.ip)
FROM pv_users
GROUP BY pv_users.gender;

FROM pv_users
INSERT OVERWRITE TABLE pv_gender_sum
    SELECT pv_users.gender, count_distinct(pv_users.userid)
    GROUP BY pv_users.gender
 
INSERT OVERWRITE DIRECTORY '/user/data/tmp/pv_age_sum'
    SELECT pv_users.age, count_distinct(pv_users.userid)
    GROUP BY pv_users.age;

FROM page_view_stg pvs
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country='US')
       SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip WHERE pvs.country = 'US'
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country='CA')
       SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip WHERE pvs.country = 'CA'
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country='UK')
       SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip WHERE pvs.country = 'UK';
	   

FROM page_view_stg pvs
INSERT OVERWRITE TABLE page_view PARTITION(dt='2008-06-08', country)
       SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip, pvs.country
	   
    beeline> set hive.exec.dynamic.partition.mode=nonstrict;
    beeline> FROM page_view_stg pvs
          INSERT OVERWRITE TABLE page_view PARTITION(dt, country)
                 SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip,
                        from_unixtimestamp(pvs.viewTime, 'yyyy-MM-dd') ds, pvs.country;

beeline> set hive.exec.dynamic.partition.mode=nonstrict;
beeline> FROM page_view_stg pvs
      INSERT OVERWRITE TABLE page_view PARTITION(dt, country)
             SELECT pvs.viewTime, pvs.userid, pvs.page_url, pvs.referrer_url, null, null, pvs.ip,
                    from_unixtimestamp(pvs.viewTime, 'yyyy-MM-dd') ds, pvs.country
             DISTRIBUTE BY ds, country;

INSERT OVERWRITE LOCAL DIRECTORY '/tmp/pv_gender_sum'
SELECT pv_gender_sum.*
FROM pv_gender_sum;

INSERT OVERWRITE TABLE pv_gender_sum_sample
SELECT pv_gender_sum.*
FROM pv_gender_sum TABLESAMPLE(BUCKET 3 OUT OF 32);


INSERT OVERWRITE TABLE actions_users
SELECT u.id, actions.date
FROM (
    SELECT av.uid AS uid
    FROM action_video av
    WHERE av.date = '2008-06-03'
 
    UNION ALL
 
    SELECT ac.uid AS uid
    FROM action_comment ac
    WHERE ac.date = '2008-06-03'
    ) actions JOIN users u ON(u.id = actions.uid);

CREATE TABLE array_table (int_array_column ARRAY<INT>);

SELECT pv.friends[2]
FROM page_views pv;

SELECT pv.userid, size(pv.friends)
FROM page_view pv;

INSERT OVERWRITE page_views_map
SELECT pv.userid, pv.properties['page type']
FROM page_views pv;

SELECT size(pv.properties)
FROM page_view pv;

FROM (
     FROM pv_users
     MAP pv_users.userid, pv_users.date
     USING 'map_script'
     AS dt, uid
     CLUSTER BY dt) map_output
 
 INSERT OVERWRITE TABLE pv_users_reduced
     REDUCE map_output.dt, map_output.uid
     USING 'reduce_script'
     AS date, count;

SELECT TRANSFORM(pv_users.userid, pv_users.date) USING 'map_script' AS dt, uid CLUSTER BY dt FROM pv_users;

FROM (
    FROM pv_users
    MAP pv_users.userid, pv_users.date
    USING 'map_script'
    CLUSTER BY key) map_output
 
INSERT OVERWRITE TABLE pv_users_reduced
 
    REDUCE map_output.dt, map_output.uid
    USING 'reduce_script'
    AS date, count;

FROM (
    FROM pv_users
    MAP pv_users.userid, pv_users.date
    USING 'map_script'
    AS c1, c2, c3
    DISTRIBUTE BY c2
    SORT BY c2, c1) map_output
 
INSERT OVERWRITE TABLE pv_users_reduced
 
    REDUCE map_output.c1, map_output.c2, map_output.c3
    USING 'reduce_script'
    AS date, count;


FROM (
     FROM (
             FROM action_video av
             SELECT av.uid AS uid, av.id AS id, av.date AS date
 
            UNION ALL
 
             FROM action_comment ac
             SELECT ac.uid AS uid, ac.id AS id, ac.date AS date
     ) union_actions
     SELECT union_actions.uid, union_actions.id, union_actions.date
     CLUSTER BY union_actions.uid) map
 
 INSERT OVERWRITE TABLE actions_reduced
     SELECT TRANSFORM(map.uid, map.id, map.date) USING 'reduce_script' AS (uid, id, reduced_val);
	 
-- VULN
LOAD DATA INPATH '/user/xyz/Inbound/files/target.csv' INTO TABLE 'myTable'

INSERT OVERWRITE TABLE myTable SELECT
regexp_extract(col_value, '^(?:([^,]*)\,?)(1)', 1) New_Field_name1
regexp_extract(col_value, '^(?:([^,]*)\,?)(5)', 1) New_Field_name2
FROM myTable;

-- HPL/SQL --

-- VULN CWE561COUT
ALLOCATE cursor_name CURSOR FOR PROCEDURE procedure_name;  -- Teradata compatibility

ALLOCATE cursor_name CURSOR FOR RESULT SET locator_name;   -- DB2 compatibility

CREATE PROCEDURE spOpenIssues 
  DYNAMIC RESULT SETS 1
BEGIN
  DECLARE cur CURSOR WITH RETURN FOR
    SELECT id, name FROM issues;
  OPEN cur;
END;

DECLARE id INT;
DECLARE name VARCHAR(30);
 
CALL spOpenIssues;
ALLOCATE c1 CURSOR FOR PROCEDURE spOpenIssues;
 
FETCH c1 INTO id, name;
WHILE (SQLCODE = 0)
DO
  PRINT id || ' - ' || name;
  FETCH c1 INTO id, name;
END WHILE;
CLOSE c1;

DECLARE id INT;
DECLARE name VARCHAR(30);
DECLARE loc RESULT_SET_LOCATOR VARYING;
 
CALL spOpenIssues;
ASSOCIATE RESULT SET LOCATOR (loc) WITH PROCEDURE spOpenIssues;
ALLOCATE c1 CURSOR FOR RESULT SET loc;
 
FETCH c1 INTO id, name;
WHILE (SQLCODE = 0)
DO
  PRINT id || ' - ' || name;
  FETCH c1 INTO id, name;
END WHILE;
CLOSE c1;

CREATE PROCEDURE spOpenIssues2 
  DYNAMIC RESULT SETS 2
BEGIN
  DECLARE cur CURSOR WITH RETURN FOR
    SELECT id, name FROM issues;
  DECLARE cur2 CURSOR WITH RETURN FOR
    SELECT id, name FROM issues_hold;
  OPEN cur;
  OPEN cur2;
END;

DECLARE id INT;
DECLARE name VARCHAR(30);
 
CALL spOpenIssues2;
 
-- First result set
ALLOCATE c1 CURSOR FOR PROCEDURE spOpenIssues2;
FETCH c1 INTO id, name;
WHILE (SQLCODE = 0)
DO
  -- ... 
  FETCH c1 INTO id, name;
END WHILE;
CLOSE c1;
 
-- Second result set
ALLOCATE c2 CURSOR FOR PROCEDURE spOpenIssues2;
FETCH c2 INTO id, name;
WHILE (SQLCODE = 0)
DO
  -- ... 
  FETCH c2 INTO id, name;
END WHILE;
CLOSE c2;

DECLARE id INT;
DECLARE name VARCHAR(30);
DECLARE loc1 RESULT_SET_LOCATOR VARYING;
DECLARE loc2 RESULT_SET_LOCATOR VARYING;
 
CALL spOpenIssues2;
ASSOCIATE RESULT SET LOCATOR (loc1, loc2) WITH PROCEDURE spOpenIssues2;
 
-- First result set
ALLOCATE c1 CURSOR FOR RESULT SET loc1;
FETCH c1 INTO id, name;
WHILE (SQLCODE = 0)
DO
  -- ... 
  FETCH c1 INTO id, name;
END WHILE;
CLOSE c1;
 
-- Second result set
ALLOCATE c2 CURSOR FOR RESULT SET loc2;
FETCH c2 INTO id, name;
WHILE (SQLCODE = 0)
DO
  -- ... 
  FETCH c2 INTO id, name;
END WHILE;
CLOSE c2;

DECLARE count INT DEFAULT 3;
WHILE 1=1 BEGIN
  SET count = count - 1;
  IF count = 0
    BREAK;
END

CREATE PROCEDURE set_message(IN name STRING, OUT result STRING)
BEGIN
 SET result = 'Hello, ' || name || '!';
END;
 
-- Now call the procedure and print the results
DECLARE str STRING;
CALL set_message('world', str);
PRINT str;

CMP ROW_COUNT sales.users WHERE local_dt = CURRENT_DATE, users_daily AT mysqlconn;  

CMP SUM sales.users WHERE local_dt = CURRENT_DATE, users_daily AT mysqlconn;  

COPY (SELECT id, name FROM sales.users WHERE local_dt = CURRENT_DATE) 
  TO /data/users.txt DELIMITER '\t';

COPY sales.users TO /data/users2.sql SQLINSERT sales.users;

COPY sales.users TO sales.users2 AT tdconn;

-- VULN PLSQL.42
copy from ftp 'ftp.myserver.com' user 'paul' pwd '***' dir data/sales/in subdir 
  files '.*' to /data/sales/raw sessions 3 new
  
-- VULN: PLSQL.31 and PLSQL.13
copy from ftp '4.23.64.30' user 'paul' pwd 'Passw0d2' dir data/sales/in subdir 
  files '.*' to /data/sales/raw sessions 3 new
 
-- VULN: PLSQL.22
DELETE FROM table-1;

-- VULN: PLSQL.22
UPDATE table-1 SET fieldx='001';

-- VULN
COPY FROM LOCAL '/home/data' TO '/user/backup/' || CURRENT_DATE;

create database 'test' || replace(current_date, '-', '');

CREATE FUNCTION hello()
 RETURNS STRING
BEGIN
 RETURN 'Hello, world';
END;
 
-- Call the function
PRINT hello();

CREATE FUNCTION hello2(text STRING)
 RETURNS STRING
BEGIN
 RETURN 'Hello, ' || text || '!';
END;
 
-- Call the function
PRINT hello2('world');

SET hplsql.temp.tables = managed;
 
CREATE LOCAL TEMPORARY TABLE temp1
(
   c1 INT,
   c2 STRING
);
 
INSERT INTO temp1 SELECT 1, 'A' FROM dual;
 
SELECT * FROM temp1;

create or replace package users as
  session_count int := 0;
  function get_count() return int; 
  procedure add(name varchar(100));
end;

create or replace package body users as
  function get_count() return int
  is
  begin
    return session_count;
  end; 
  procedure add(name varchar(100))
  is 
  begin
    -- ...
    session_count = session_count + 1;
  end;
end;

users.add('John');
users.add('Sarah');
users.add('Paul');
print 'Number of users: ' || users.get_count();

CREATE PROCEDURE set_message(IN name STRING, OUT result STRING)
BEGIN
 SET result = 'Hello, ' || name || '!';
END;
 
-- Now call the procedure and print the results
DECLARE str STRING;
CALL set_message('world', str);
PRINT str;

SET hplsql.temp.tables = managed;
 
CREATE VOLATILE TABLE temp1
(
   c1 INT,
   c2 STRING
);
 
INSERT INTO temp1 SELECT 1, 'A' FROM dual;

-- VULN 
SELECT * FROM temp1;

DECLARE
  code CHAR(10);
  status INT := 1;
  count SMALLINT = 0;
  limit INT DEFAULT 100;  
  max_limit CONSTANT INT := 1000;
BEGIN 
--  ...
END;

DECLARE Statement
DECLARE statement has the following syntax:

DECLARE code CHAR(10);
DECLARE status, status2 INT DEFAULT 1;
DECLARE count SMALLINT, limit INT DEFAULT 100; 

DECLARE name VARCHAR(100);
DECLARE no_rows INT DEFAULT 0; 
 
DECLARE CONTINUE HANDLER FOR NOT FOUND
  SET no_rows = 1;    
 
OPEN cur FOR 'SELECT name FROM db.orders';
 
FETCH cur INTO name;
WHILE no_rows = 0 THEN  
  PRINT id;
  FETCH cur INTO name;
END WHILE;
CLOSE cur;

SET hplsql.temp.tables = managed;
 
DECLARE TEMPORARY TABLE temp1
(
   c1 INT,
   c2 STRING
);
 
INSERT INTO temp1 SELECT 1, 'A' FROM dual;

-- VULN PLSQL.17
SELECT * FROM temp1;

DECLARE cnt INT;
EXECUTE 'SELECT COUNT(*) FROM db.orders' INTO cnt;

DECLARE tabname VARCHAR(100) DEFAULT 'tab1';
--VULN: SQL.07
EXECUTE IMMEDIATE 'CREATE TABLE ' || tabname || ' (c1 INT)';

-- VULN SQL.07
EXEC 'SELECT ''A'', ''B'' FROM dual';

ALTER PROCEDURE spOrders
  @lim INT
AS
  DECLARE @cnt INT = 0
  SELECT @cnt = COUNT(*) from src LIMIT @lim
  IF @cnt > 0
    SELECT * FROM src
GO
 
EXEC spOrders @lim = 3

WHILE count > 0 LOOP
  count := count - 1;
  EXIT WHEN count = 0;
END LOOP;
<<lbl>>
WHILE 1=1 LOOP
  <<lbl1>>
  WHILE 1=1 LOOP
    EXIT lbl;
  END LOOP;
END LOOP;

DECLARE tabname VARCHAR DEFAULT 'db.orders';
DECLARE id INT;
DECLARE cur CURSOR FOR 'SELECT id FROM ' || tabname;
OPEN cur;
FETCH cur INTO id;
WHILE SQLCODE=0 THEN
  PRINT id;
  FETCH cur INTO id;
END WHILE;
CLOSE cur;

FOR item IN (
    SELECT dname, loc as location
    FROM dept
    WHERE dname LIKE '%A%'
    AND deptno > 10
    ORDER BY location)
LOOP
-- VULN: DBMS_OUTPUT.PUT_LINE
  DBMS_OUTPUT.PUT_LINE('Name = ' || item.dname || ', Location = ' || item.location);
-- VULN: DBMS_UTILITY.EXEC_DDL_STATEMENT
  DBMS_UTILITY.EXEC_DDL_STATEMENT ('insert into kevtemp1 values (3)');
END LOOP;

-- VULN: SQL.06
FOR i IN 1..10 LOOP
  -- i will have values: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
END LOOP;
FOR i IN REVERSE 10..1 LOOP
  -- i will have values: 10, 9, 8, 7, 6, 5, 4, 3, 1, 1
END LOOP;
FOR i IN 1..10 BY 2 LOOP
  -- i will have values: 1, 3, 5, 7, 9
END LOOP;

GET DIAGNOSTICS EXCEPTION 1 var_name = MESSAGE_TEXT;

-- VULN: GET DIAGNOSTICS ROW_COUNT
GET DIAGNOSTICS var_name = ROW_COUNT;

!echo Hello, world;

HOST 'echo Hello, world';

IF state = 'CA' THEN
  code := 1;
ELSIF state = 'NY' THEN
  code := 2;
ELSIF state = 'MA' THEN
  code := 3;
ELSE
  code := 5;
END IF;

IF state = 'CA'
  SET code = 1;
ELSE 
  SET code = 5;
IF state = 'CA'
BEGIN
  SET code = 1;
  SET type = 'A';
END
ELSE 
BEGIN
  SET code = 5;
  SET type = 'B';
END  

.if errorcode <> 0 then .quit 1

CREATE PROCEDURE set_message(IN name STRING, OUT result STRING)
BEGIN
 SET result = 'Hello, ' || name || '!';
END;

INCLUDE set_message.sql
 
DECLARE str STRING;
CALL set_message('world', str);
PRINT str;

insert overwrite directory '/data/sales_daily' select * from sales_daily;

declare tabname string = 'sales_daily';
 
insert overwrite directory '/data/sales_' || current_date 
  'select * from ' || tabname;
  
lbl:
WHILE count > 0 DO
  SET count = count - 1;
  IF count = 0 THEN
    LEAVE lbl;
  END IF;
END WHILE;
lbl:
WHILE 1=1 DO
  lbl1:
  WHILE 1=1 DO
    LEAVE lbl;
  END WHILE;
END WHILE;

MAP OBJECT log TO log.log_data AT mysqlconn;
 
DECLARE cnt INT;
SELECT count(*) INTO cnt FROM sales.users WHERE local_dt = CURRENT_DATE;
 
INSERT INTO log (message) VALUES ('Number of users: ' || cnt);  

declare 
  code char(1) := 'a';
begin
  null;
end;

PRINT 'Hello, world!';
PRINT 'Hello, ' || 'world!';
PRINT('Hello, world!');

BEGIN
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    PRINT 'Error raised';
    RESIGNAL;
  END;
  PRINT 'Before executing SQL';
  SELECT * FROM abc.abc;      -- Table does not exist, error will be raised
  PRINT 'After executing SQL - will not be printed in case of error';
END;

BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    PRINT 'Error raised, outer handler';
 
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
      PRINT 'Error raised, resignal';
      RESIGNAL;
    END;
    PRINT 'Before executing SQL';
    SELECT * FROM abc.abc;       -- Table does not exist, error will be raised
    PRINT 'After executing SQL - must not be printed';
  END;
  PRINT 'Continue outer block after exiting inner';
END;

BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS EXCEPTION 1 text = MESSAGE_TEXT;
    PRINT 'SQLSTATE: ' || SQLSTATE;
    PRINT 'Text: ' || text;
  END; 
 
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
      RESIGNAL SQLSTATE '02031' SET MESSAGE_TEXT = 'Some error';
-- VULN 
    SELECT * FROM abc.abc;    -- Table does not exist, raise an exception
  END;
  -- VULN: SQL.10
  RETURN;
END;

RETURN NVL(v1, 1);
  
DECLARE cnt INT DEFAULT 0; 
DECLARE wrong_cnt_condition CONDITION;
 
DECLARE EXIT HANDLER FOR wrong_cnt_condition
  PRINT 'Wrong number of rows';  
 
SELECT COUNT(*) INTO cnt FROM TABLE (VALUES (1,2));
 
IF cnt <> 1 THEN
  SIGNAL wrong_cnt_condition;
END IF;

summary for select code, total_emp, salary from sample_07;

summary top 3 for sample_07;

truncate table users2015;

USE sales;
 
USE SUBSTR(var, 1, 3);

VALUES 'A' INTO code;
VALUES (0, 100) INTO (count, limit); 

-- Oracle, PostgreSQL, Netezza
WHILE count > 0 LOOP
  count := count - 1;
END LOOP;
-- DB2, Teradata, MySQL
WHILE count > 0 DO
  SET count = count - 1;
END WHILE;
-- SQL Server
WHILE count > 0 BEGIN
  SET count = count - 1;
END