CREATE DATABASE IF NOT EXISTS DBREACH;
USE DBREACH;


CREATE EXTERNAL TABLE IF NOT EXISTS pasmtp_ext (
    MESSAGE STRING
)
    ROW FORMAT DELIMITED
    STORED AS TEXTFILE LOCATION '/databreach/inbox/PEC/PAsmtp/tmp/';


CREATE TABLE IF NOT EXISTS pasmtp_raw (
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
    LOCATION '/databreach/inbox/PEC/PAsmtp/orc/';


INSERT INTO
    pasmtp_raw
    PARTITION (`date`)
SELECT -- SMTP OK e KO
       CONCAT(SUBSTR(MESSAGE, 10, 2), SUBSTR(MESSAGE, 13, 2), SUBSTR(MESSAGE, 16, 2)) AS `HOUR`,
       SUBSTR(SPLIT(INPUT__FILE__NAME, 'tmp/')[1], 1, 3)                              AS SYSTEM,
       TRIM(SUBSTR(MESSAGE, 19, 17))                                                  AS SESSION_ID,
       'SMTP'                                                                         AS PROTOCOL,
       REGEXP_EXTRACT(MESSAGE, '(?i)USING (.*) AS', 1)                                AS MECHANISM,
       REGEXP_EXTRACT(MESSAGE, ' \'(.*)\' ', 1)                                       AS EMAIL,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM HOST ([^:]*):([0-9]*)', 1)                   AS HOST_IP,
       ip2num(REGEXP_EXTRACT(MESSAGE, '(?i)FROM HOST ([^:]*):([0-9]*)', 1))           AS HOST_IP_NUM,
       REGEXP_EXTRACT(MESSAGE, '(?i)FROM HOST ([^:]*):([0-9]*)', 2)                   AS HOST_PORT,
       'N/A'                                                                          AS MESSAGE,
       SUBSTR(MESSAGE, 36)                                                            AS MESSAGE_LONG,
       CASE
           WHEN UPPER(SUBSTR(MESSAGE, 36)) LIKE 'SMTP AUTHENTICATED%'
               THEN 'OK'
           WHEN UPPER(SUBSTR(MESSAGE, 36)) LIKE 'SMTP AUTHENTICATE FAILURE USING%'
               THEN 'KO'
           ELSE 'OTHER' END                                                           AS OUTCOME_COD,
       CASE
           WHEN UPPER(SUBSTR(MESSAGE, 36)) LIKE 'SMTP AUTHENTICATED%'
               THEN 'Authenticated'
           WHEN UPPER(SUBSTR(MESSAGE, 36)) LIKE 'SMTP AUTHENTICATE FAILURE USING%'
               THEN 'Auth Failed'
           ELSE 'Other' END                                                           AS OUTCOME_DES,
       CAST(TRIM(SUBSTR(MESSAGE, 0, 8)) AS INT)                                       AS `DATE`
FROM pasmtp_ext
WHERE UPPER(MESSAGE) LIKE '%SMTP AUTHENTICATE FAILURE USING%' OR
      UPPER(MESSAGE) LIKE '%SMTP AUTHENTICATED%';