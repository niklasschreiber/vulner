#!/usr/bin/sh
stty -echo
RETCODE=0
ERR="Errore Generico"
SEVERITY="ERROR"
CMDOUT="Comando non valido"
ERRCLASS="E_DBACC"
if [ "$4" != "" ] && [ "$8" != "" ] && [ "$9" != "" ] ; then
	DATABASE="$4"
	OUTPUT="$8/$9"
	if [ -f $OUTPUT ] ; then
		echo "*****************************************"
		echo "***   START BATCH SCRIPT FOR CHECKS   ***"
		echo "*****************************************"
		echo "*** EXPORTED FILE ALREADY EXIST       ***"
		echo "*****************************************"
	else	
		echo "*****************************************"
		echo "***   START BATCH SCRIPT FOR CHECKS   ***"
		echo "*****************************************"
		echo "*** DISABLE AUTOCOMMIT                ***"
		db2 +o "UPDATE COMMAND OPTIONS USING c OFF"
		db2 +o "UPDATE COMMAND OPTIONS USING o OFF"
		echo "*** OPEN DATABASE CONNECTION          ***"
		CMDOUT=`db2 +c "CONNECT TO $DATABASE"`
		if [ $? -eq 0 ] ; then
			echo "*** MARK RECORDS FOR EXPORT           ***"
			CMDOUT=`db2 +c "UPDATE SDP2.ASSEGNO SET FL_EXP = 'X' WHERE FL_TRAS_ASSG = 'S' AND (FL_EXP = 'N' OR FL_EXP = 'X')"`
			if [ $? -eq 0 ] ; then
				echo "*** EXPORT MARKED RECORDS             ***"
				CMDOUT=`db2 +c "EXPORT TO $OUTPUT OF DEL MODIFIED BY NOCHARDEL SELECT CLOB(CONCAT(DIGITS(CAST(A.FRAZ AS DECIMAL(5,0))), CONCAT(VARCHAR_FORMAT(TIMESTAMP(A.DT_CONT,'00:00:00'),'YYYYMMDD'), CONCAT(REPEAT(' ',1), CONCAT(REPEAT('X',4), CONCAT(REPEAT(' ',26), CONCAT(CONCAT(TRIM(REPLACE(VERS_SOFT,'.','')),REPEAT(' ',6 - LENGTH(TRIM(REPLACE(VERS_SOFT,'.',''))))), CONCAT(CONCAT(B.CD_OPERAT,REPEAT(' ',31 - LENGTH(B.CD_OPERAT))), CONCAT(DIGITS(CAST(A.FRAZ AS DECIMAL(5,0))), CONCAT('00001', CONCAT(VARCHAR_FORMAT(TIMESTAMP(A.DT_CONT,'00:00:00'),'YYYYMMDD'), CONCAT(CAST(DIGITS(CAST(A.NUM_PDL AS DECIMAL(3,0))) AS VARCHAR(3)), CONCAT(CAST(DIGITS(CAST(A.PROG_PDL AS DECIMAL(4,0))) AS VARCHAR(4)), CONCAT(A.COD_FASE, CONCAT(DIGITS(CAST(A.NUM_ASSG AS DECIMAL(17,0))), CONCAT(CASE WHEN TRIM(A.ABI) = '' THEN REPEAT(' ',5) ELSE DIGITS(CAST(A.ABI AS DECIMAL(5,0))) END, CONCAT(CASE WHEN TRIM(A.CAB) = '' THEN REPEAT(' ',5) ELSE DIGITS(CAST(A.CAB AS DECIMAL(5,0))) END, CONCAT(CASE WHEN A.DT_EMIS IS NULL THEN REPEAT(' ',8) ELSE VARCHAR_FORMAT(TIMESTAMP(A.DT_EMIS,'00:00:00'),'YYYYMMDD') END, CONCAT(CAST(DIGITS(CAST((A.IMPO_ASSG * 100) AS DECIMAL(15,0))) AS VARCHAR(15)), CONCAT(A.COD_RAGP, CONCAT(CASE WHEN A.CNTO_CORR_BENE IS NULL THEN REPEAT(' ',3) ELSE CONCAT(A.COD_CAUS,REPEAT(' ', 3 - LENGTH(A.COD_CAUS))) END, CONCAT(CASE WHEN A.CNTO_CORR_BENE IS NULL THEN REPEAT(' ',12) ELSE DIGITS(CAST(A.CNTO_CORR_BENE AS DECIMAL(12,0))) END, CONCAT(CASE WHEN A.FL_TRAS_ASSG = 'S' THEN '0' ELSE '1' END,REPEAT(' ',51))))))))))))))))))))))),230) FROM SDP2.ASSEGNO AS A INNER JOIN SDP2.TBGIOOPER AS B ON A.ID_OPEZ = B.ID_OPERAZ INNER JOIN SDP2.UFFICIO AS C ON A.FRAZ = C.FRAZ WHERE FL_EXP = 'X'"`
				if [ $? -eq 0 ] ; then
					echo "*** MARK RECORDS EXPORTED             ***"
					CMDOUT=`db2 +c "UPDATE SDP2.ASSEGNO SET FL_EXP = 'E' WHERE FL_TRAS_ASSG = 'S' AND FL_EXP = 'X'"`
					if [ $? -eq 0 ] ; then
						echo "*** COMMIT WORK                       ***"
						CMDOUT=`db2 +c "COMMIT"`
						echo "*****" >> $OUTPUT
						if [ $? -eq 0 ] ; then
							echo "*****************************************"
							echo "***         END BATCH SCRIPT          ***"
							echo "*****************************************"	
						else
							echo "*** ROLLBACK WORK                     ***"
							db2 +c +o "ROLLBACK"
							rm $OUTPUT
							echo "*****************************************"
							echo "***             LOG ERROR             ***"
							echo "*****************************************"
							echo "*** COMMIT WORK FAILED                ***"
							echo "*****************************************"
							ERR="Impossibile effetuare la commit del batch assegni."
							SEVERITY="ERROR"
							RETCODE=4
						fi
					else
						echo "*** ROLLBACK WORK                     ***"
						db2 +c +o "ROLLBACK"
						rm $OUTPUT
						echo "*****************************************"
						echo "***              LOG ERROR            ***"
						echo "*****************************************"
						echo "*** MARKED EXPORTED RECORDS FAILED    ***"
						echo "*****************************************"
						ERR="Impossibile marcare i record da esportare."
						SEVERITY="ERROR"
						RETCODE=9
					fi
				else
					echo "*** ROLLBACK WORK                     ***"
					db2 +c +o "ROLLBACK"
					echo "*****************************************"
					echo "***             LOG ERROR             ***"
					echo "*****************************************"
					echo "*** EXPORT MARKED RECORDS FAILED      ***"
					echo "*****************************************"
					ERR="Impossibile esportare i record marcati."
					SEVERITY="ERROR"
					RETCODE=8
				fi
			elif [ $? -eq 1 ] ; then
				echo "*** COMMIT WORK                       ***"
				db2 +c +o "COMMIT"
				echo "*****" > $OUTPUT
				echo "*****************************************"
				echo "***             LOG INFO              ***"
				echo "*****************************************"
				echo "*** NO RECORDS TO EXPORT              ***"
				echo "*****************************************"
				ERR="Non sono stati individuati record da esportare."
				SEVERITY="WARN"
				RETCODE=0
			else
				echo "*** ROLLBACK WORK                     ***"
				db2 +c +o "ROLLBACK"
				echo "*****************************************"
				echo "***             LOG ERROR             ***"
				echo "*****************************************"
				echo "*** MARK RECORDS FOR EXPORT FAILED    ***"
				echo "*****************************************"
				ERR="Impossibile marcare i record da esportare."
				SEVERITY="ERROR"
				RETCODE=6
			fi
			echo "*** CLOSE DATABASE CONNECTION         ***"
			echo "*****************************************"
			db2 +c +o "CONNECT RESET"
		else
			echo "*****************************************"
			echo "***             LOG ERROR             ***"
			echo "*****************************************"
			echo "*** DATABASE CONNECTION FAILED        ***"
			echo "*****************************************"
			ERR="Impossibile effettuare la connessione al database."
			SEVERITY="ERROR"
			RETCODE=2
		fi
	fi
else
	echo "****************************************"
	echo "***     INVALID ARGUMENTS VALUE      ***"
	echo "****************************************"
	echo "***                                  ***"
	echo "*** arg4: Database Name              ***"
	echo "***                                  ***"
	echo "*** arg7: Output File Path           ***"
	echo "***                                  ***"
	echo "*** arg8: Output File Name           ***"
	echo "***                                  ***"
	echo "****************************************"
	ERR="Numero di argomenti di INPUT non valido."
	SEVERITY="ERROR"
	ERRCLASS="E_APPLI"
	CMDOUT="arg4: Nome database - arg8: Path file di output - arg9: Nome file di output"
	RETCODE=1
fi
if [ $RETCODE -gt 0 ] ; then
	echo "LTEC{$SEVERITY#$ERRCLASS#SEAS_ERR_$RETCODE#$ERR#$CMDOUT}LTEC"
fi
stty echo
exit $RETCODE