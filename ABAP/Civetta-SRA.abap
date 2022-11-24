REPORT  zcivetta_rg.
DATA: id TYPE i.

TABLES : spfli, connection_tab.
SELECT DISTINCT cityfrom cityto distid distance   "VIOLAZ Avoid using SELECT DISTINCT (SRA)
FROM spfli
INTO TABLE connection_tab.

SELECT cityfrom cityto distid distance
FROM spfli
INTO TABLE connection_tab.
DELETE ADJACENT DUPLICATES FROM connection_tab.  "OK
TRUNCATE TABLE spfli. *VIOLAZ Truncate tables compromise backups (SRA)