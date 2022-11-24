CREATE DATABASE IF NOT EXISTS DBREACH;
USE DBREACH;


CREATE EXTERNAL TABLE IF NOT EXISTS loginproxy_ext (
    MESSAGE STRING
)
    ROW FORMAT DELIMITED
    STORED AS TEXTFILE LOCATION '/databreach/inbox/PEC/Loginproxy/tmp/';


CREATE TABLE IF NOT EXISTS loginproxy_raw (
    hour         STRING,
    system       STRING,
    session_id   STRING,
    protocol     STRING,
    mechanism    STRING,
    email        STRING,
    host_ip      STRING,
    host_ip_num  BIGINT,
    host_port    STRING,
    message      STRING,
    message_long STRING,
    outcome_cod  STRING,
    outcome_des  STRING
)
    PARTITIONED BY (`date` INT)
    STORED AS ORC
    LOCATION '/databreach/inbox/PEC/Loginproxy/orc/';


INSERT INTO
    loginproxy_raw
    PARTITION (`date`)
SELECT -- login OK
       CONCAT(SUBSTR(MESSAGE, 10, 2), SUBSTR(MESSAGE, 13, 2), SUBSTR(MESSAGE, 16, 2)) AS `HOUR`,
       SUBSTR(SPLIT(INPUT__FILE__NAME, 'tmp/')[1], 1, 3)                              AS SYSTEM,
       SUBSTR(MESSAGE, 19, 8)                                                         AS SESSION_ID,
       REGEXP_EXTRACT(SUBSTR(MESSAGE, 28), '([^ ]*) ', 1)                             AS PROTOCOL,
       'N/A'                                                                          AS MECHANISM,
       REGEXP_EXTRACT(MESSAGE, ' \'(.*)\' ', 1)                                       AS EMAIL,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM ([^:]*):([0-9]*)', 1)                        AS HOST_IP,
       ip2num(REGEXP_EXTRACT(MESSAGE, '(?i)FROM ([^:]*):([0-9]*)', 1))                AS HOST_IP_NUM,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM ([^:]*):([0-9]*)', 2)                        AS HOST_PORT,
       'N/A'                                                                          AS MESSAGE,
       SUBSTR(MESSAGE, 28)                                                            AS MESSAGE_LONG,
       'OK'                                                                           AS OUTCOME_COD,
       'Authenticated'                                                                AS OUTCOME_DES,
       CAST(TRIM(SUBSTR(MESSAGE, 0, 8)) AS INT)                                       AS `DATE`
FROM loginproxy_ext
WHERE UPPER(MESSAGE) LIKE '%PROXY USER%'

UNION ALL

SELECT -- login KO
       CONCAT(SUBSTR(MESSAGE, 10, 2), SUBSTR(MESSAGE, 13, 2), SUBSTR(MESSAGE, 16, 2))                      AS `HOUR`,
       SUBSTR(SPLIT(INPUT__FILE__NAME, 'tmp/')[1], 1, 3)                                                   AS SYSTEM,
       SUBSTR(MESSAGE, 19, 8)                                                                              AS SESSION_ID,
       REGEXP_EXTRACT(SUBSTR(MESSAGE, 28), '([^ ]*) ', 1)                                                  AS PROTOCOL,
       'N/A'                                                                                               AS MECHANISM,
       REGEXP_EXTRACT(MESSAGE, '(?i)USER(?: name)? \'([^\']*)\'', 1)                                       AS EMAIL,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM(?: IP)? ((?:[0-9]{1,3}\.){3}[0-9]{1,3}):([0-9]{1,5})', 1)         AS HOST_IP,
       ip2num(REGEXP_EXTRACT(MESSAGE, '(?i)FROM(?: IP)? ((?:[0-9]{1,3}\.){3}[0-9]{1,3}):([0-9]{1,5})', 1)) AS HOST_IP_NUM,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM(?: IP)? ((?:[0-9]{1,3}\.){3}[0-9]{1,3}):([0-9]{1,5})', 2)         AS HOST_PORT,
       TRIM(UPPER(CASE
                      WHEN UPPER(MESSAGE) LIKE '%CANNOT AUTHENTICATE ON SERVER%'
                          THEN REGEXP_EXTRACT(MESSAGE, '(?i)(CANNOT AUTHENTICATE ON SERVER .*)(?:FROM)', 1)
                      ELSE SUBSTR(REGEXP_EXTRACT(UPPER(MESSAGE), '(?i)USER(?: name)? \'([^\']*)\' (?:- )?([^,]*)', 2),
                                  LOCATE('- ', REGEXP_EXTRACT(UPPER(MESSAGE), '(?i)USER(?: name)? \'([^\']*)\' (?:- )?([^,]*)', 2)) + 1)
           END))                                                                                           AS MESSAGE,
       SUBSTR(MESSAGE, 28)                                                                                 AS MESSAGE_LONG,
       'KO'                                                                                                AS OUTCOME_COD,
       'Auth Failed'                                                                                       AS OUTCOME_DES,
       CAST(TRIM(SUBSTR(MESSAGE, 0, 8)) AS INT)                                                            AS `DATE`
FROM loginproxy_ext
WHERE UPPER(MESSAGE) LIKE '%AUTH ERROR USER%';