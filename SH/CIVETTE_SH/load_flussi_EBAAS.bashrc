

if [ $# -ne 1 ];  then
echo "Usage $(basename $0) <TERA_SERVER/TERA_USER,TERA_PWD> "
exit 1
fi

echo
echo inizio esecuzione $0 $(date)
echo =====================

#TERA_SERVER=PDWDB02C
#TERA_SERVER=CDWDB02C

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
WORK_DIR=$(dirname $0)
LOGON_STRING=$1
LOAD_DIR=/mnt_ftp1/ADEGUATA_VERIFICA
TEMP_DIR=$(dirname $WORK_DIR)/TARGET
BACKUP_DIR=$(dirname $WORK_DIR)/BACKUPSRC


#LOG_DIR=$WORK_DIR/LOG
#LOG_FILE=$LOG_DIR/$(basename $0)_$TIMESTAMP.log

umask 022

#if [ ! -d $LOG_DIR ]; then mkdir -p $LOG_DIR ; fi
#if [ ! -d $LOAD_DIR ]; then mkdir -p $LOAD_DIR ; fi
#if [ ! -d $TEMP_DIR ]; then mkdir -p $TEMP_DIR ; fi
#if [ ! -d $BACKUP_DIR ]; then mkdir -p $BACKUP_DIR ; fi




#FILE_LIST=$(ls $LOAD_DIR | grep .txt )
FILE_LIST=$(find $LOAD_DIR -name \AdegVer_*.txt -type f )
if [ -z "$FILE_LIST" ]; then

echo "Nessun file in "$LOAD_DIR  $(date) 
exit 99

fi

#for x in $FILE_LIST ; do
#cp $x $TEMP_DIR/$(basename $x) && rm -f $x 

#EXITSTAT=$?

#if [ $EXITSTAT -ne 0 ]
#then
#  echo "Errore durante l'esecuzione di $0"
#  exit 1
#fi

#done
#file piu recente in base al nome file AdegVer_aaSmmgg_aaaammgg.txt
#exit 0

INPUT_FILE=$("ls" $LOAD_DIR|grep .txt|tail -1)
INPUT_FILE_PATH=$LOAD_DIR/$INPUT_FILE

if [ -z "$INPUT_FILE" ]; then

 echo "Errore durante l'esecuzione di $0"
  exit 1

fi

echo "============================="
echo inizio esecuzione FASTLOAD $(date)
echo inputfile = $INPUT_FILE


fastload 2>&1 <<EOI 
sessions 8;
.LOGON $LOGON_STRING;

DATABASE EDWAE_SA;

DROP TABLE ADEGUATA_VERIFICA_ER1;
DROP TABLE ADEGUATA_VERIFICA_ER2;
DROP TABLE ADEGUATA_VERIFICA;

CREATE TABLE ADEGUATA_VERIFICA (
	FILIALE VARCHAR(5),
	NDG VARCHAR(16),
	DENOM VARCHAR(70),
	CODFIS_PIVA VARCHAR(16),
	CIAE VARCHAR(4),
	NUOVO_GUE VARCHAR(4),
	NAT_GIURIDICA VARCHAR(3),
	RAPPORTO VARCHAR(16),
	SERVIZIO VARCHAR(3),
	CATEGORIA VARCHAR(4),
	QAV VARCHAR(2),
	TE VARCHAR(2),
	DATAQ VARCHAR(8),
	WARNING VARCHAR(2),
	DATA_WARNING INTEGER,
	NUM_WARNING VARCHAR(5),
	DATA_ULT_WARNING INTEGER,
	PROFILO VARCHAR(1),
	CODICE_PRODOTTO VARCHAR(6),
	FLAG_OBBLIGATI VARCHAR(2),

	ts_ult_mod TIMESTAMP(0) ,
	nome_flusso VARCHAR(100)

) PRIMARY INDEX (NDG)
;


.SET RECORD TEXT;     

BEGIN LOADING ADEGUATA_VERIFICA
   ERRORFILES ADEGUATA_VERIFICA_ER1
            , ADEGUATA_VERIFICA_ER2 ;

DEFINE  
	FILIALE (CHAR(5))
	NDG (CHAR(16))
	DENOM (CHAR(70))
	CODFIS_PIVA (CHAR(16))
	CIAE (CHAR(4))
	NUOVO_GUE (CHAR(4))
	NAT_GIURIDICA (CHAR(3))
	RAPPORTO (CHAR(16))
	SERVIZIO (CHAR(3))
	CATEGORIA (CHAR(4))
	QAV (CHAR(2))
	TE (CHAR(2))
	DATAQ (CHAR(8))
	WARNING (CHAR(2))
	DATA_WARNING (CHAR(8))
	NUM_WARNING (CHAR(5))
	DATA_ULT_WARNING (CHAR(8))
	PROFILO (CHAR(1))
	CODICE_PRODOTTO (CHAR(6))
	FLAG_OBBLIGATI (CHAR(2))
	FILLER (CHAR(89))
	NON_DISPON (CHAR(12))
			
			           
FILE=$INPUT_FILE_PATH;

SHOW;

INSERT INTO ADEGUATA_VERIFICA
VALUES
  (
	:FILIALE              ,         
	:NDG                  ,         
	:DENOM                ,         
	:CODFIS_PIVA          ,         
	:CIAE                 ,         
	:NUOVO_GUE            ,         
	:NAT_GIURIDICA        ,         
	:RAPPORTO             ,         
	:SERVIZIO             ,         
	:CATEGORIA            ,         
	:QAV                  ,         
	:TE                   ,         
	:DATAQ                ,         
	:WARNING              ,         
	:DATA_WARNING         ,         
	:NUM_WARNING          ,         
	:DATA_ULT_WARNING     ,         
	:PROFILO              ,         
	:CODICE_PRODOTTO      ,         
	:FLAG_OBBLIGATI       ,         

	CURRENT_TIMESTAMP(0) ,
	'$INPUT_FILE' 
      
  );

END LOADING;

DROP TABLE EDWAE_DW.ADEGUATA_VERIFICA;

CREATE TABLE EDWAE_DW.ADEGUATA_VERIFICA AS EDWAE_SA.ADEGUATA_VERIFICA WITH DATA;

DROP TABLE EDWAE_SA.ADEGUATA_VERIFICA;


LOGOFF;
EOI

EXITSTAT=$?

if [ $EXITSTAT -ne 0 ]
then
  echo "Errore durante l'esecuzione fastload"

  exit 1
fi



echo fine esecuzione FASTLOAD $(date)
echo =====================

#backup tutti i file anche non caricati

for x in $FILE_LIST;  do
gzip -c $x > $BACKUP_DIR/$( basename $x ).gz && rm -f $x  
#&& rm -f $TEMP_DIR/$x
done




echo =====================
echo fine esecuzione $0 $(date)
