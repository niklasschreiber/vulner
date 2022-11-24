#! /bin/ksh

#cd ..
#. ./.profile.star

#data della shell con anno a 2 cifre ed ore + minuti
#usata da: ERROR, OUTPUT, contenuto di LAST_GENERA_TRACCE_EDWH, LST_FILE
DATE_2_MIN=`date '+%y%m%d%H%M'`

#data della shell con anno a 4 cifre ed ore + minuti
#usata da: nome file SERVIZIO, nome file OPERAZIONE, nome file MESSAGGIO, nome file IMPLAVORAZIONE
DATE_4_MIN=`date '+%Y%m%d%H%M'`

#data della shell con anno a 4 cifre ed ore + minuti + secondi
#usata da: nome file TRACCE, nome file semaforo
DATE_4_SEC=`date '+%Y%m%d%H%M%S'`

ERROR_DIR=$HOME/nuovocentrale/circolante/scripts/dump_edwh/ERROR
ERR_FILE=$ERROR_DIR/ERR_${DATE_2_MIN}
OUTPUT_DIR=$HOME/nuovocentrale/circolante/scripts/dump_edwh/OUTPUT
OUT_FILE=$OUTPUT_DIR/OUT_${DATE_2_MIN}
EXE_DIR=$HOME/nuovocentrale/circolante/scripts/dump_edwh

FTP_ROOT=$HOME/EDWH_Root

export ERROR_DIR
export ERR_FILE
export OUTPUT_DIR
export OUT_FILE
export EXE_DIR

#produzione
ORACLE_HOME=/export/home/oracle/product/9.2.0
#sviluppo
###ORACLE_HOME=/oracle/app/oracle/product/9.2.0
export ORACLE_HOME

PATH=$PATH:$ORACLE_HOME/bin
export PATH

USER=$1
PASSWD=$2
SID=$3

SQLPLUS=$ORACLE_HOME/bin/sqlplus

echo ${DATE_2_MIN} > $EXE_DIR/LAST_GENERA_TRACCE_EDWH
## Definisco il nome del file lst in modo da preservare la data nell'esecuzione delle varie procedure
LST_FILE=$EXE_DIR/Genera_tracce_EDWH_${DATE_2_MIN}.lst

#data di competenza delle tracce, come delta rispetto al giorno dell'estrazione (oggi)
DELTA=$4

echo "Delta giorno competenza tracce = $DELTA" >> $EXE_DIR/LAST_GENERA_TRACCE_EDWH

## Recupero dal db la data di competenza delle tracce
DATA_DATI=`$SQLPLUS -silent $USER/$PASSWD@$SID << EOT
set heading off
set feedback off
set pagesize 0
set timing off
set verify off
set echo off
select to_char(sysdate-$DELTA,'dd/mm/yyyy hh24:mi:ss') from dual;
exit;
EOT`

Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        echo "Estrazione della data di competenza dei dati sul database non terminata correttamente">$ERR_FILE
        echo "Estrazione della data di competenza dei dati sul database non terminata correttamente vedere $ERR_FILE">>$OUT_FILE
        exit 1
fi

ANNO_DATI_4=`echo ${DATA_DATI} | cut -c7-10`
ANNO_DATI_2=`echo ${DATA_DATI} | cut -c9-10`
MESE_DATI=`echo ${DATA_DATI} | cut -c4-5`
GIORNO_DATI=`echo ${DATA_DATI} | cut -c1-2`


## Generazione file SERVIZIO
#ricalcolo data shell
DATE_4_MIN=`date '+%Y%m%d%H%M'`
#nome del file
TT_01_SERVIZIO_FILE=TT_01_SERVIZIO_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_MIN}.csv

$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_servizio_EDWH.sql $EXE_DIR > /dev/null
Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        if [ -f $EXE_DIR/FileDay_Servizio.lst ]
        then
         mv $EXE_DIR/FileDay_Servizio.lst $LST_FILE
         echo "Dump della Tipologica Servizio non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Servizio non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
        fi
else
      if [ -f $EXE_DIR/FileDay_Servizio.lst ]
      then
       grep ORA- $EXE_DIR/FileDay_Servizio.lst > /dev/null
       if [ $? = "0" ]
       then
         mv $EXE_DIR/FileDay_Servizio.lst $LST_FILE
         echo "Dump della Tipologica Servizio non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Servizio non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
       fi
	   mv $EXE_DIR/FileDay_Servizio.lst $EXE_DIR/$TT_01_SERVIZIO_FILE
       gzip $EXE_DIR/$TT_01_SERVIZIO_FILE
      fi 
fi

## Generazione file OPERAZIONE
#ricalcolo data shell
DATE_4_MIN=`date '+%Y%m%d%H%M'`
#nome del file
TT_02_OPERAZIONE_FILE=TT_02_OPERAZIONE_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_MIN}.csv

$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_operazione_EDWH.sql $EXE_DIR > /dev/null
Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        if [ -f $EXE_DIR/FileDay_Operazione.lst ]
        then
         mv $EXE_DIR/FileDay_Operazione.lst $LST_FILE
         echo "Dump della Tipologica Operazione non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Operazione non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
        fi
else
      if [ -f $EXE_DIR/FileDay_Operazione.lst ]
      then
       grep ORA- $EXE_DIR/FileDay_Operazione.lst > /dev/null
       if [ $? = "0" ]
       then
         mv $EXE_DIR/FileDay_Operazione.lst $LST_FILE
         echo "Dump della Tipologica Operazione non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Operazione non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
       fi
	   mv $EXE_DIR/FileDay_Operazione.lst $EXE_DIR/$TT_02_OPERAZIONE_FILE
       gzip $EXE_DIR/$TT_02_OPERAZIONE_FILE
      fi 
fi

## Generazione file MESSAGGIO
#ricalcolo data shell
DATE_4_MIN=`date '+%Y%m%d%H%M'`
#nome del file
TT_03_MESSAGGIO_FILE=TT_03_MESSAGGIO_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_MIN}.csv

$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_messaggio_EDWH.sql $EXE_DIR > /dev/null
Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        if [ -f $EXE_DIR/FileDay_Messaggio.lst ]
        then
         mv $EXE_DIR/FileDay_Messaggio.lst $LST_FILE
         echo "Dump della Tipologica Messaggio non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Messaggio non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
        fi
else
      if [ -f $EXE_DIR/FileDay_Messaggio.lst ]
      then
       grep ORA- $EXE_DIR/FileDay_Messaggio.lst > /dev/null
       if [ $? = "0" ]
       then
         mv $EXE_DIR/FileDay_Messaggio.lst $LST_FILE
         echo "Dump della Tipologica Messaggio non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump della Tipologica Messaggio non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
       fi
	   mv $EXE_DIR/FileDay_Messaggio.lst $EXE_DIR/$TT_03_MESSAGGIO_FILE
       gzip $EXE_DIR/$TT_03_MESSAGGIO_FILE
      fi 
fi

## Generazione file IMPLAVORAZIONE
#ricalcolo data shell
DATE_4_MIN=`date '+%Y%m%d%H%M'`
#nome del file
TT_04_IMPLAVORAZIONE_FILE=TT_04_IMPLAVORAZIONE_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_MIN}.csv

DELIM="'"
#formattazione data di competenza delle tracce 
DATA_TR=$DELIM$DATA_DATI$DELIM

#massivo
#$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_imp_lavorazione_EDWH.sql $EXE_DIR > /dev/null
#incrementale
$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_imp_lavorazione_EDWH_incr.sql $EXE_DIR $DATA_TR > /dev/null
Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        if [ -f $EXE_DIR/FileDay_Imp_Lavorazione.lst ]
        then
         mv $EXE_DIR/FileDay_Imp_Lavorazione.lst $LST_FILE
         echo "Dump Anagrafica Impianti Lavorazione non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump Anagrafica Impianti Lavorazione non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
        fi
else
      if [ -f $EXE_DIR/FileDay_Imp_Lavorazione.lst ]
      then
       grep ORA- $EXE_DIR/FileDay_Imp_Lavorazione.lst > /dev/null
       if [ $? = "0" ]
       then
         mv $EXE_DIR/FileDay_Imp_Lavorazione.lst $LST_FILE
         echo "Dump Anagrafica Impianti Lavorazione non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump Anagrafica Impianti Lavorazione non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
       fi
	   mv $EXE_DIR/FileDay_Imp_Lavorazione.lst $EXE_DIR/$TT_04_IMPLAVORAZIONE_FILE
       gzip $EXE_DIR/$TT_04_IMPLAVORAZIONE_FILE
      fi 
fi

## Generazione file TRACCE
#ricalcolo data shell
DATE_4_SEC=`date '+%Y%m%d%H%M%S'`
#nome del file
TT_05_TRACCE_FILE=TT_05_TRACCE_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_SEC}.csv

## Eseguo la query
$SQLPLUS $USER/$PASSWD@$SID @$EXE_DIR/Genera_tracce_EDWH_codice.sql $EXE_DIR $DATA_TR > /dev/null
Res_sqlplus=`echo $?`
if [ $Res_sqlplus -ne 0 ]
then
        if [ -f $EXE_DIR/FileDay_Tracce.lst ]
        then
         mv $EXE_DIR/FileDay_Tracce.lst $LST_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
        fi
else
      if [ -f $EXE_DIR/FileDay_Tracce.lst ]
      then
       grep ORA- $EXE_DIR/FileDay_Tracce.lst > /dev/null
       if [ $? = "0" ]
       then
         mv $EXE_DIR/FileDay_Tracce.lst $LST_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non terminato correttamente vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non terminato correttamente vedere $ERR_FILE">>$OUT_FILE
         exit 1
       fi
      fi

     if [ -f $EXE_DIR/FileDay_Tracce.lst ]
     then
       res=`grep -i "1" $EXE_DIR/FileDay_Tracce.lst|wc -l`
       if [ $res = "0" ]
       #se il recordset e' vuoto, il file contiene solo l'header e viene mandato lo stesso come richiesto, pero' lo segnalo
       then
         mv $EXE_DIR/FileDay_Tracce.lst $EXE_DIR/$TT_05_TRACCE_FILE
         echo "File dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} vuoto">$LST_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non contiene dati vedere Genera_tracce_EDWH_*.lst">$ERR_FILE
         echo "Dump tracce del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} non contiene dati vedere $ERR_FILE">>$OUT_FILE
         gzip $EXE_DIR/$TT_05_TRACCE_FILE
       else
         mv $EXE_DIR/FileDay_Tracce.lst $EXE_DIR/$TT_05_TRACCE_FILE
         gzip $EXE_DIR/$TT_05_TRACCE_FILE
       fi
     fi
fi


## file semaforo: nome e contenuto
#ricalcolo data shell
DATE_4_SEC=`date '+%Y%m%d%H%M%S'`

# nome del file
TT_SEM_FILE=TT_${ANNO_DATI_2}G${MESE_DATI}${GIORNO_DATI}_${DATE_4_SEC}.smf

#contenuto del file semaforo: YYYY-MM-DD
SEM_CONTENT=${ANNO_DATI_4}-${MESE_DATI}-${GIORNO_DATI}

echo ${SEM_CONTENT} > $EXE_DIR/$TT_SEM_FILE

## Sposto i files nella directory da cui parte FTP
mv $EXE_DIR/$TT_01_SERVIZIO_FILE.gz $FTP_ROOT/.
mv $EXE_DIR/$TT_02_OPERAZIONE_FILE.gz $FTP_ROOT/.
mv $EXE_DIR/$TT_03_MESSAGGIO_FILE.gz $FTP_ROOT/.
mv $EXE_DIR/$TT_04_IMPLAVORAZIONE_FILE.gz $FTP_ROOT/.
mv $EXE_DIR/$TT_05_TRACCE_FILE.gz $FTP_ROOT/.
mv $EXE_DIR/$TT_SEM_FILE $FTP_ROOT/.

## Eseguo ftp verso macchina remota
ftp -n -v<< EOT
open 10.207.230.60
user t&t1001 t&t1001
lcd $FTP_ROOT
bin
put $TT_01_SERVIZIO_FILE.gz
put $TT_02_OPERAZIONE_FILE.gz
put $TT_03_MESSAGGIO_FILE.gz
put $TT_04_IMPLAVORAZIONE_FILE.gz
put $TT_05_TRACCE_FILE.gz
ascii
put $TT_SEM_FILE
bye

EOT


echo "Dump kit dati del giorno ${GIORNO_DATI}-${MESE_DATI}-${ANNO_DATI_4} terminato correttamente" >>$OUT_FILE
rm -f $EXE_DIR/LAST_GENERA_TRACCE_EDWH
exit 0

