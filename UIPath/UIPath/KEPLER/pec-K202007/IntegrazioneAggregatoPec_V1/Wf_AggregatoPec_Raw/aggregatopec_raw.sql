CREATE DATABASE IF NOT EXISTS DATALAB;
USE DATALAB;

CREATE TABLE IF NOT EXISTS F_PEC_AGG_PARAMS (
    TIM_DAY_IDS INT
)
    STORED AS ORC
    LOCATION '/databreach/inbox/PEC/AggregatoPecParams/orc/';

CREATE TABLE IF NOT EXISTS aggregato_pec_raw_union 
row format delimited 
fields terminated by '|' 
AS 
SELECT
    `date`,
    system,
    CASE
        WHEN CAST(`HOUR` AS INT) < 080000
            THEN '00-08'
        WHEN CAST(`HOUR` AS INT) < 200000
            THEN '08-20'
        ELSE '20-24' END AS FASCIA_ORARIA,
    email,
    host_ip,
    host_ip_num,
    outcome_cod,
    COUNT(*)             AS NUM_LOGIN

FROM
    dbreach.loginproxy_raw pec
        LEFT JOIN (SELECT DISTINCT
                       TIM_DAY_IDS
                   FROM F_PEC_AGG_PARAMS) PAR
                  ON pec.`date` = PAR.TIM_DAY_IDS
        LEFT JOIN (SELECT
                       MAX(`date`) AS `date`
                   FROM dbreach.loginproxy_raw) AS MAX
                  ON pec.`date` = MAX.`date`
WHERE pec.`date` = MAX.`date` OR PAR.TIM_DAY_IDS IS NOT NULL
GROUP BY pec.`date`,
         system,
         CASE
             WHEN CAST(`HOUR` AS INT) < 080000
                 THEN '00-08'
             WHEN CAST(`HOUR` AS INT) < 200000
                 THEN '08-20'
             ELSE '20-24' END,
         email,
         host_ip,
         host_ip_num,
         outcome_cod

UNION ALL

SELECT
    `date`,
    system,
    CASE
        WHEN CAST(`HOUR` AS INT) < 080000
            THEN '00-08'
        WHEN CAST(`HOUR` AS INT) < 200000
            THEN '08-20'
        ELSE '20-24' END AS FASCIA_ORARIA,
    email,
    host_ip,
    host_ip_num,
    outcome_cod,
    COUNT(*)             AS NUM_LOGIN

FROM
    dbreach.pasmtp_raw pec
        LEFT JOIN (SELECT DISTINCT
                       TIM_DAY_IDS
                   FROM F_PEC_AGG_PARAMS) PAR
                  ON pec.`date` = PAR.TIM_DAY_IDS
        LEFT JOIN (SELECT
                       MAX(`date`) AS `date`
                   FROM dbreach.pasmtp_raw) AS MAX
                  ON pec.`date` = MAX.`date`
WHERE pec.`date` = MAX.`date` OR PAR.TIM_DAY_IDS IS NOT NULL
GROUP BY pec.`date`,
         system,
         CASE
             WHEN CAST(`HOUR` AS INT) < 080000
                 THEN '00-08'
             WHEN CAST(`HOUR` AS INT) < 200000
                 THEN '08-20'
             ELSE '20-24' END,
         email,
         host_ip,
         host_ip_num,
         outcome_cod;
-- export
INSERT OVERWRITE DIRECTORY '/kepler/export/PEC/AggregatoPecTime/'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '|' NULL DEFINED AS ''
SELECT * from aggregato_pec_raw_union;

DROP TABLE aggregato_pec_raw_union;