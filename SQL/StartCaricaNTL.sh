echo ====================================
echo esecuzione $0 iniziata : `date +"%A %Od/%Om/%EY %H:%M:%S"`
echo ====================================
echo

## ridefinisco la $HOME per poter usare ftp in automatico

#############################

ORACLE_HOME=/orasw/app/oracle/product/9.2
HOME=/data/DWH/NTL
PATH_SOURCE=/data/DWH/NTL/SOURCE
PATH_SCRIPT=/data/DWH/NTL/LOADSCRIPT
PATH_FTP=/mnt_ftp1/ntl
SID=ODSCOLL
PATH=$PATH:$ORACLE_HOME/bin
ORA_BIC_USER=dipncr
ORA_BIC_PWD=dipncr
PATH_DS=/ascential/Ascential/DataStage/DSEngine
NUOVI_DATI=0
Last=0

export HOME ORA_BIC_USER ORA_BIC_PWD PATH_DS PATH ORACLE_HOME PATH_SCRIPT PATH_SOURCE SID PATH_FTP Last

echo
echo MAIN START
echo ==========

cd $ORACLE_HOME

echo
echo controllo della SANAU_LOG_ATTIVITA
echo ==============================
pippo=NAUTILUS
sqlplus $ORA_BIC_USER/$ORA_BIC_PWD@$SID <<!

WHENEVER SQLERROR exit 3 
VARIABLE ERRORE NUMBER
DEFINE ERRORE = 0 
DECLARE Ret number;

-- Ret = 3 : errore Oracle
-- Ret = 2 : sono gia' in esecuzione! non fare niente
-- Ret = 0 : non ci sono nuovi flussi NAUTILUS

BEGIN

  Ret := 0;

  -- controllo della tabella SANAU_LOG_ATTIVITA
  -- verifica se NAUTILUS non e' in esecuzione, altrimenti restituisce 2


  SELECT decode(count(*),0,0,2) INTO Ret FROM SANAU_LOG_ATTIVITA
  WHERE COD_ATTIVITA = 'NAUT'
  AND   DATA_FINE IS NULL;


  if Ret = 0 then 



  -- Controllo ultimo caricamento effettuato flussi Nautilus
  -- con esito positivo 

SELECT  decode(count(*),0,1,0) INTO Ret
  FROM SANAU_LOG_ATTIVITA
  WHERE (COD_ATTIVITA = 'NAUT') 
    AND (DATA_FINE IS NOT NULL) 
    AND SUBSTR(ESITO,1,2) = 'OK' 
    AND to_char(SysDate,'yyyymmdd') > (SELECT to_char(MAX(DATA_INIZIO),'yyyymmdd') 
  	  			          FROM SANAU_LOG_ATTIVITA 
				         WHERE COD_ATTIVITA = 'NAUT');
  end if;


  :ERRORE := Ret;

END;
/
	exit :ERRORE;
/
!

ORA_RET=$?
#echo "---"$ORA_RET"----"

echo
echo controllo LOG_ATTIVITA eseguito con Ret = $ORA_RET
echo ==================================================
echo
if [  $ORA_RET -eq 3 ]
then
	echo ERRORE GENERALE ORACLE \(1\)
	exit
fi

if [  $ORA_RET -eq 2 ]
then
	echo  NAUTILUS GIA' IN ESECUZIONE: COTROLLARE l\'ESITO DEL CARICAMENTO IN CORSO
	exit
fi

if [ $ORA_RET -eq 1 ]
then
	echo NUOVI DATI NON DISPONIBILI
	echo esecuzione Caricamento NAUTILUS GIA EFFETTUATO
	NUOVI_DATI=0
	exit
fi


echo Controllo Flussi per il nuovo caricamento


day=$(date +%Y%m%d)
echo Today is $day

#echo $PATH_FTP
NumFile=$(ls $PATH_FTP/*$day.txt 2>/dev/null | wc -l)
NumFileOk=$(ls $PATH_FTP/*$day.ok 2>/dev/null | wc -l)
echo NumFile = $NumFile , NumFileOk = $NumFileOk

ls $PATH_FTP/*$day.*

i=0
z=0
y=1
s=4
end=end
var=0
DFile=''
Array=xxx
Arr=xx
stop=''

if [ $(ls $PATH_FTP/*$day.ok 2>/dev/null | wc -l) != '0' ]
then
        if [ $(ls $PATH_FTP/*$day.ok 2>/dev/null | wc -l) -ge 25 ]
        then
        	DFile=$(ls $PATH_FTP/*.ok  2>/dev/null | rev |cut -c4-11 | rev | sort | uniq)
                while [ $Array != $Last ]
                do
                        ((i=i+1))
                        Array=`echo $DFile | cut -d ' ' -f$i`
                        num=$(ls $PATH_FTP/*$Array.ok | wc -l)
			#echo Array - $Array   Num - $num Day - $day
			if [ $Array -eq $day ]
			then	
				Last=$Array 
                        	echo Presenti $num  flussi con data competenza $Array
				#echo ---$Array----
				echo  $ORA_BIC_USER/$ORA_BIC_PWD@$SID 

#########START ORACLE SCRIPT #############
sqlplus $ORA_BIC_USER/$ORA_BIC_PWD@$SID <<!
WHENEVER SQLERROR exit 3 
VARIABLE ERRORE NUMBER
DEFINE ERRORE = 0 
DECLARE Ret number;
BEGIN
Ret := 0;
INSERT INTO SANAU_LOG_ATTIVITA VALUES ('NAUT',SysDate,null,to_date($Array,'yyyymmdd'),null,'ALL');
COMMIT;

:ERRORE := Ret;
END;
/
	exit :ERRORE;
/
!
#########END ORACLE SCRIPT #############

				ORAORA=$?
				if [ $ORAORA -eq '0' ]
                		 then
                 			echo Oracle Succesful
                 			FDS=0
                 		else
                 			echo Oracle ERROR
                 			FDS=1
                 		fi
			fi
              	done
	else 
		if [ $(ls $PATH_FTP/*$day.ok 2>/dev/null | wc -l) -lt '25' ]
		then

########START ORACLE SCRIPT #############
sqlplus $ORA_BIC_USER/$ORA_BIC_PWD@$SID <<!
WHENEVER SQLERROR exit 3
VARIABLE ERRORE NUMBER
DEFINE ERRORE = 0
DECLARE Ret number;
BEGIN
Ret := 0;
INSERT INTO SANAU_LOG_ATTIVITA VALUES ('NAUT',SysDate,null,to_date($day,'yyyymmdd'),null,$NumFile);
-- if Ret = 0 then
-- dbms_output.put_line('......');
-- end if;
:ERRORE := Ret;
END;
/
  	exit :ERRORE;
/
!
		#########END ORACLE SCRIPT #############

                 ORAORA=$?
                 if [ $ORAORA -eq '0' ]
                 then
                 	echo Oracle Succesful
                 	FDS=0
                 else
                 	echo Oracle ERROR
                 	FDS=1
                 fi

		## Dichiarazione Array FileList ##
		FileList[1]=Anagrafica
		FileList[2]=Cash_Dispenser
		FileList[3]=Chiusure
		FileList[4]=ClusterTerritoriale
		FileList[5]=CodiceTipologiaUP
		FileList[6]=Filiali
		FileList[7]=IndirizziFiliali
		FileList[8]=IndirizziUP
		FileList[9]=Manager
		FileList[10]=OrarioUP
		FileList[11]=Polo
		FileList[12]=Recapito
		FileList[13]=Regioni
		FileList[14]=Sportelli
		FileList[15]=Sprint
		FileList[16]=TelefoniUP
		FileList[17]=TipologieUP
		FileList[18]=TipoOrario
		FileList[19]=Anagrafica_Aggiuntiva
		FileList[20]=Dettaglio_Pdl
		FileList[21]=IndirizziUP
		FileList[22]=Numero_Pdl
		FileList[23]=Regioni_2
		FileList[24]=Tipologia_PDL
		FileList[25]=TurnoUP
		FileList[26]=end
	
		## Fine Dichiarazione  FileList ##

        	ListFileDir=$(ls $PATH_FTP/*$day.ok  2>/dev/null | rev |cut -c13- | rev | cut -c15- | sort | uniq ) 
		ListFileDir=$ListFileDir' z'
               	while [ "${FileList[y]}" != 'end' ]
		do
			while [ $Arr != $Last ]
                	do
				((z=z+1))
                        	Arr=`echo $ListFileDir | cut -d ' ' -f$z`
				if [ "${FileList[y]}" != $Arr ]
				then
					if [ $Arr == 'z'  ] 
					then
						echo Flusso ${FileList[y]} NON trovato
########START ORACLE SCRIPT #############
        sqlplus $ORA_BIC_USER/$ORA_BIC_PWD@$SID <<!
        WHENEVER SQLERROR exit 3
        VARIABLE ERRORE NUMBER
        DEFINE ERRORE = 0
        DECLARE Ret number;
        BEGIN
        Ret := 0;
        INSERT INTO SANAU_LOG_ATTIVITA VALUES ('NAUT',SysDate,null,to_date($day,'yyyymmdd'),'NOK','${FileList[y]}');
        -- if Ret = 0 then
        -- dbms_output.put_line('......');
        -- end if;
        :ERRORE := Ret;
        END;
/
        exit :ERRORE;
/
!
#########END ORACLE SCRIPT #############
                               			ORAORA=$?
                                		if [ $ORAORA -eq '0' ]
                                        	then
                                                	echo Oracle Succesful
							FDS=0
                                        	else
                                                	echo Oracle ERROR
							FDS=1
                                		fi

						break
					fi
					
				else
					echo OK $z - $Arr - ${FileList[y]}
					break
				fi
			done
		z=0
		((y=y+1))
		done

        	else              
        			echo TROPPI
        	fi                      
        fi                              
        	                        
else                                    
        echo Flussi Nautilus MANCANTI   
fi                                      

###### Run DATA STAGE NAUTILUS #####

# inizio esecuzione job-sequence DataStage release 2Plus
# ========================================

BIC_JOB=Js_START_BicNtl_Integr

echo esecuzione job DataStage: $BIC_JOB
echo ==================================
echo

DS_PROJECT=/data/DWH/PROJECTS/BIC_AD__UP

DS_UVHOME=/ascential/Ascential/DataStage/DSEngine

BIC_PROJECT=BIC_AD__UP

PAR01='$Parm_Path_NTL_Source'=/data/DWH/NTL/SOURCE
PAR02='$Parm_HRA_ODS_Dsn_ORA'=ODSCOLL
PAR03='$Parm_HRA_ODS_Pwd_ORA'=dipncr
PAR04='$Parm_HRA_ODS_Usr_ORA'=dipncr
PAR05='$Parm_path_work_NTL'=/data/DWH/NTL/WORK
PAR06='$Parm_Path_NTL'=/mnt_ftp1/ntl
PAR07=NomeFile=

cd $DS_PROJECT
. $DS_UVHOME/dsenv

echo $DS_UVHOME/bin/dsjob -run -wait -warn 0 -param $PAR01 -param $PAR02 -param $PAR03 -param $PAR04 -param $PAR05 -param $PAR06 -param $PAR07 $BIC_PROJECT $BIC_JOB

$DS_UVHOME/bin/dsjob -run -wait -warn 0 -param $PAR01 -param $PAR02 -param $PAR03 -param $PAR04 -param $PAR05 -param $PAR06 -param $PAR07 $BIC_PROJECT $BIC_JOB

RET_DS=$?
if [ $RET_DS -ne 0 ]
then
        echo ERRORE ESECUZIONE DATASTAGE !!!!!
fi

echo $DS_UVHOME/bin/dsjob -jobinfo $BIC_PROJECT $BIC_JOB
$DS_UVHOME/bin/dsjob -jobinfo $BIC_PROJECT $BIC_JOB

echo
echo fine esecuzione job $BIC_JOB \(DataStage\) release 2Plus
echo ==========================================
echo


###### End DATA STAGE NAUTILUS #####
echo ====================================
echo
sqlplus $ORA_BIC_USER/$ORA_BIC_PWD@$SID <<!

WHENEVER SQLERROR exit 3
VARIABLE ERRORE NUMBER
DEFINE ERRORE = 0
DECLARE Ret number;

-- Ret = 3 : errore Oracle
-- Ret = 2 :
-- Ret = 1 :
-- Ret = 0 :

BEGIN

  UPDATE SANAU_LOG_ATTIVITA
  SET DATA_FINE=sysdate, ESITO=decode($RET_DS,0,'OK','NOK')
  WHERE COD_ATTIVITA='NAUT' AND DATA_FINE IS NULL AND ESITO IS NULL;
  COMMIT;

END;
/
        exit;
/
!

TABLOG_RET=$?

echo TABLOG_RET=$TABLOG_RET
echo

if [  $TABLOG_RET -ne 0 ]
then
        echo Aggiornamento record nella SANAU_LOG_ATTIVITA fallito per errore Oracle
        echo Controllare lo stato della tabella !!!
fi

echo ====================================
echo esecuzione $0 finita : `date +"%A %Od/%Om/%EY %H:%M:%S"`
echo ====================================
echo

exit

