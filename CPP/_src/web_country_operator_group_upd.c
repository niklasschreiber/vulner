/*----------------------------------------------------------------------------
*   PROGETTO : Aggiorna Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : updb.c
*   Ultima Modifica : 09/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   allinea la descrizione guppi OP e PA nel file operatori rispetto ai GRop e GRPA
*   -----------
*------------------------------------------------------------------------------
*   Funzioni contenute
*   ------------------
*
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

/*------------- INCLUDE -------------*/
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <tal.h>
#include <usrlib.h>
#include <cextdecs.h (DELAY)>
#include <cextdecs.h (SERVERCLASS_SEND_, SERVERCLASS_SEND_INFO_)>
#include <cextdecs.h (JULIANTIMESTAMP)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"


/*------------- PROTOTIPI -------------*/
void  Display_File();
short Aggiorna_Dati();
short Aggiorna_Operatori_GrPa(char *ac_GRP, char *acPaese, short nMaxTs, short handleOP, short handleOP_rem );
short Cerca_in_OP(short handleOP, short handleOP_rem);

extern short	Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern short 	scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation );

AVLTREE		listaGR_PA;

short gAggiornato;


/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sTmp[500];
	short	rc = 0;
	char ac_err_msg[255];
    short rcSes;
    short nAltraCgi;

    disp_Top = 0;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));
	memset(acFilePaesi_Loc, 0x00, sizeof(acFilePaesi_Loc));

	// Returns 1 (OK) o 0 (KO)
	rcSes =  (short) cgi_session_verify(ac_err_msg);
	if (rcSes == 0)
	{
		printf("<br><br><center><font color=red>%s</font>", ac_err_msg);
		fflush(stdout);
		exit(0);
	}	

	// **************************** Nome della CGI ********************************************
	gName_cgi  = getenv( "SCRIPT_NAME" );

	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	/* Cgi chiamata da altro programma */
	nAltraCgi = 0;
	if (( (wrk_str = cgi_param( "ALTRA-CGI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		if( wrk_str[0] == 'Y')
			nAltraCgi = 1;
	}
    /**************************************************************************
    ** Determinazione identificativo processo
    **************************************************************************/
	rc = get_process_name(ac_procname);
	if (rc != 0)
	{
		sprintf(sTmp,"Error get_process_name: %d", rc);
		Display_Message(0, "Operation result", sTmp);
		return(0);
	}

	// -------------------------- UTENTE e IP ------------------------------------------
	gUtente = cgi_session_var("USER");
	gIP     = getenv( "REMOTE_ADDR" );

	if ( (wrk_str = getenv( "INI_FILE" ) ) != NULL )
		strcpy(ini_file, wrk_str);
	else
	{
		Display_Message(-1, "", "INI_FILE");
		exit(0);
	}

	/*--------------------------------
	   Init per LOG Sicurezza
	 --------------------------------*/
	memset(&log_spooler, 0, sizeof(log_spooler));
	if ( InitSLOG() )
		return(0);
	sprintf(log_spooler.NomeDB, "Operator");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	//-------------------------------------------------------------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		Display_File();
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update Operators DB - Start",gUtente, gIP);
		Display_TOP("UPDATE DB ");
		printf("<center><br><br>\n\
					<span id='wait1'>\n\
					<BR><BR>\
					<IMG SRC='images/loading.gif' BORDER=0 ALT=''>\n\
					</span>\n");
		fflush(stdout);

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "ALL");
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		rc = Aggiorna_Dati();

		if(rc != 0)
			LOGResult = SLOG_ERROR;

		/*------------------------------------------*/
		/* LOG SICUREZZA solo per db rules      	*/
		/*------------------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);


		printf("<SCRIPT LANGUAGE='JavaScript'>\n\
				togliegif('wait1', 0);\n\
				</SCRIPT>");

		if (rc == 0)
		{
			printf("<br><br><br><br><br>");
			printf("<center>");
			printf("<H3>Update Complete</H3>");
			printf("<BR><BR>");
			if (nAltraCgi == 1)
				printf( "<INPUT TYPE='button' icon='ui-icon-circle-close' VALUE='Close' onclick=\"javascript:window.close()\" >\n");
		}
		Display_BOTTOM();
	}

	log_close();

	return(0);
}

/******************************************************************************/
void Display_File()
{


	Display_TOP("UPDATE DB ");

	printf("<br><br><center><br><br><br><br><b>Align OPERATOR information with GRP Country</b><br><br><br><br>\n");
	printf( "<INPUT TYPE='button' icon='ui-icon-play' VALUE='Start' onclick=\"javascript:location='%s?OPERATION=Update'\" >\n", gName_cgi);


	Display_BOTTOM();
	return;
}


//************************************************************************
short Aggiorna_Dati()
{
	char		*pChiave;
	char		sTmp[500];
	char		ac_GRP[70];
	char		prec_GRP[70];
	char		ac_Chiave[70];
	char		ac_CodOp[20];
	char		acPaese[8];
	short		handleGRPA = -1;
	short		handleOP = -1;
	short		handleOP_rem = -1;
	short		rc = 0;
	short		nMaxTs = 0;

	t_ts_paesi_record record_paesi;

	//Creare la lista Gruppo Paesi
	listaGR_PA = avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acPaese, ' ', sizeof(acPaese));
	memset(sTmp,    0, sizeof(sTmp));
	memset(ac_CodOp,   0, sizeof(ac_CodOp));
	memset(ac_GRP, 0, sizeof(ac_GRP));
	memset(prec_GRP, 0, sizeof(prec_GRP));


	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handleGRPA, 1, 0);
	if(rc == 0)
		rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 0);
	if(rc == 0)
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 0);

	if (rc == 0 )
	{
		log(LOG_DEBUG, "%s;%s; Files successfully opened",gUtente, gIP);

		/***********************
		* Cerco il record PAESI
		************************/
		rc = MBE_FILE_SETKEY_( handleGRPA, (char *) &acPaese, (short)sizeof(acPaese), 0, APPROXIMATE);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", rc);
			log(LOG_ERROR, "%s;%s; Error in reading file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);
			Display_Message(0, "GRP PAESI DB - Operation result", sTmp);
		}
		/* tutto ok */
		else
		{
			// ciclo sul db Paesi e aggiorno il Db Operatori
			while(1)
			{
				rc = MBE_READX( handleGRPA, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				/* errore... */
				if ( rc)
				{
					if(rc != 1)
					{
						sprintf(sTmp, "Readxlock: error %d ", rc);
						log(LOG_ERROR, "%s;%s; Error in reading file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);
						Display_Message(0, "GRP PAESI DB - Operation result", sTmp);
					}
					else
						rc = 0;
					break;
				}
				else
				{
					if( (memcmp(record_paesi.gr_pa, "     ", 5 )) && (memcmp(record_paesi.gr_pa, "******", 5 )) )
					{
						memset(ac_GRP, 0, sizeof(ac_GRP));

						// salvo il gruppo e il Max ts
						memcpy(ac_GRP, record_paesi.gr_pa, sizeof(record_paesi.gr_pa));
						nMaxTs = record_paesi.max_ts;

						// aggiorno il db operatori
						memset(sTmp, 0, sizeof(sTmp));
						memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
						rc =  Aggiorna_Operatori_GrPa(ac_GRP, sTmp, nMaxTs, handleOP, handleOP_rem );
						if(rc != 0)
							break;

						//Aggiungo il gruppo alla lista gruppo paesi
						if( strcmp(ac_GRP, prec_GRP))
						{
							//Aggiungere un elemento alla lista:
							pChiave = malloc((strlen(ac_GRP)+1)*sizeof(char));
							sprintf(pChiave,"%s", ac_GRP);

							if (avlAdd(listaGR_PA, pChiave, pChiave) == -1)
							{
								// nel file ci sono chiavi duplicate
								//sprintf(sTmp, "la chiave %s esiste già in listaGR_PA!!!", pChiave);
								//Display_Message(1, "COUNTRY DB: - Operation result", sTmp, 0);
								//rc = 1;
								//break;
							}
						}
						memset(prec_GRP, 0, sizeof(prec_GRP));
						strcpy(prec_GRP, ac_GRP);
					}
				}
			}
		}

		if(rc == 0)
		{
			/**************************************************
			* Cerco se in OPERATORI ci sono gruppi non validi
			****************************************************/
			rc = Cerca_in_OP(handleOP, handleOP_rem);
		}

		if(rc == 0 )
		{
			Aggiorna_Operatori_rec_Aster(handleOP, handleOP_rem);
		}

		MBE_FILE_CLOSE_(handleGRPA);
		MBE_FILE_CLOSE_(handleOP);
		MBE_FILE_CLOSE_(handleOP_rem);

		log(LOG_DEBUG, "%s;%s; Files closed",gUtente, gIP);
	}

	return(rc);	
}

//*************************************************************************
// aggiorno il campo gruppo PAESI nel db operatori
//*************************************************************************
short Cerca_in_OP(short handleOP, short handleOP_rem)
{
	char	ac_Chiave[18];
	char	ac_GRP_Pa[70];
	char	sTmp[500];
	short	rc = 0;
	short	nAgg;
	t_ts_oper_record record_operatori;
	t_ts_oper_record record_operatori_backup;

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_backup, ' ', sizeof(t_ts_oper_record));

	rc = MBE_FILE_SETKEY_( handleOP, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) in File_setkey file [%s] ", rc, acFileOperatori_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(0, "OPERATOR DB: - Operation result", sTmp);
	}
	/* tutto ok */
	else
	{
		// ciclo sul db Operatori x vedere se ci sono gruppi non validi
		while(1)
		{
			rc = MBE_READLOCKX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
			/* errore... */
			if ( rc)
			{
				if(rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s] ", rc, acFileOperatori_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(0, "OPERATOR DB: View Records- Operation result", sTmp);
				}
				else
					rc = 0;
				break;
			}
			else
			{
				memset(ac_GRP_Pa, 0, sizeof(ac_GRP_Pa));

				// salvo il gruppo PA
				memcpy(ac_GRP_Pa, record_operatori.gruppo_pa, sizeof(record_operatori.gruppo_pa));
	
				//cerco se i gruppi non sono presenti nei DB Paesi
				// se non ci sono li cancello dal db operatori
				nAgg = 0;
				if(memcmp( ac_GRP_Pa, "     ", 5) )
				{
					if(avlFind(listaGR_PA, ac_GRP_Pa) == NULL)
					{
						memset(record_operatori.gruppo_pa, ' ', sizeof(record_operatori.gruppo_pa));
						nAgg = 1;
					}
				}

				if( nAgg == 1)
				{
					//salvo ciò ce ho letto in un rec di backup per eventuale ripristino
					record_operatori_backup = record_operatori;

					//Aggiorno il db Operatori
					rc = MBE_WRITEUPDATEX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
					if(rc)
					{
						sprintf(sTmp, "Error in writing file [%s] : code %d", acFileOperatori_Loc, rc);
						log(LOG_ERROR, "%s;%s; Error in writing file operator : code %d",gUtente, gIP, rc);
						Display_Message(0, "OPERATOR DB: Operation result", sTmp);
						MBE_UNLOCKREC(handleOP);
						break;
					}
					else
					{
						// ********************* scrivo DB REMOTO ***********************
						rc = scrivi_Operatori_remoto(handleOP_rem, &record_operatori, UPD );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleOP);

							memset(sTmp, 0, sizeof(sTmp));
							//Aggiornato Operatore scrivo log
							memcpy(sTmp, record_operatori.gruppo_pa, sizeof(record_operatori.gruppo_pa));
							AlltrimString(ac_GRP_Pa);
							AlltrimString(sTmp);

							log(LOG_INFO, "%s;%s; (UPD) Operatore (before): %.8s-%.10s-GRPA:%s",
											gUtente, gIP, record_operatori.paese, record_operatori.cod_op, ac_GRP_Pa);
							log(LOG_INFO, "%s;%s; (UPD) Operatore (after): %.8s-%.10s-GRPA:%s",
											gUtente, gIP, record_operatori.paese, record_operatori.cod_op, sTmp );
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_operatori_backup, (short) sizeof(t_ts_oper_record) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(0, "", sTmp);
								MBE_UNLOCKREC(handleOP);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
						}
					}
				}
				else
					MBE_UNLOCKREC(handleOP);
			}
		}//fine while
	}
	return (rc);
}
//*************************************************************************
// aggiorno il campo gruppo nel db operatori
//*************************************************************************
short Aggiorna_Operatori_GrPa(char *ac_GRP, char *acPaese, short nMaxTs, short handleOP, short handleOP_rem )
{
	char		sTmp[2000];
	char		ac_Chiave[8];
	char		acGRP_Old[70];
	short		nMaxTs_Old = 0;
	short		rc = 0;
	short		lenChiave;

	t_ts_oper_record record_operatori;
	t_ts_oper_record record_operatori_backup;
	t_ts_oper_record record_operatori_tmp;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_backup, ' ', sizeof(t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, acPaese, strlen(acPaese));
	lenChiave = LEN_CC;

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handleOP, ac_Chiave, lenChiave, 0, GENERIC);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileOperatori_Loc );
		log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
		Display_Message(0, "", sTmp);
	}

	while ( 1 )
	{
		/*******************
		* Leggo il record LOCALE
		*******************/
		rc = MBE_READLOCKX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
		/* errore... */
		if (rc != 0)
		{
			if (rc != 1)
			{
				sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc );
				log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
				Display_Message(0, "", sTmp);
			}
			else
				rc = 0;
			break;
		}
		/* record TROVATO */
		else  /* readx ok */
		{
			// ****  faccio copia di BACKUP per eventuale ripristino ******
			record_operatori_backup = record_operatori;

			// se gruppo paese o maxts sono diversi  li aggiorno
			if( strncmp(ac_GRP, record_operatori.gruppo_pa, sizeof(record_operatori.gruppo_pa)) ||
				nMaxTs !=  record_operatori.max_ts )
			{
				memset(acGRP_Old, 0, sizeof(acGRP_Old));
				memset(sTmp, 0, sizeof(sTmp));

				memcpy(acGRP_Old, record_operatori.gruppo_pa, sizeof(record_operatori.gruppo_pa));
				nMaxTs_Old =  record_operatori.max_ts;

				// aggiorno il gruppo e Max TS
				memset(record_operatori.gruppo_pa, ' ', sizeof(record_operatori.gruppo_pa));
				memcpy(record_operatori.gruppo_pa, ac_GRP, strlen(ac_GRP));
				record_operatori.max_ts = nMaxTs;


				//aggiorno il record con i dati modificati
				rc = MBE_WRITEUPDATEX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating Local file [%s][grp:%s]", rc, acFileOperatori_Loc, ac_GRP );
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
					MBE_UNLOCKREC(handleOP);
					break;
				}

				if (rc == 0)
				{
					/*******************
					* Aggiorno DB REMOTO
					*******************/
					rc = MBE_FILE_SETKEY_( handleOP_rem, record_operatori.paese,
										sizeof(record_operatori.paese)+sizeof(record_operatori.cod_op), 0, EXACT);

					rc = MBE_READLOCKX( handleOP_rem, (char *) &record_operatori_tmp, (short) sizeof(t_ts_oper_record) );
					/* errore... */
					if (rc != 0)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) in reading Remote file [%s][grp:%s]", rc, acFileOperatori_Rem, ac_GRP );
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(0, "", sTmp);
						}
						else
							rc = 0;
						break;
					}
					/* record TROVATO */
					else  /* readx ok */
					{
						//aggiorno il record
						rc = MBE_WRITEUPDATEUNLOCKX( handleOP_rem, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleOP);

							//Aggiornato Operatore scrivo log
							memset(sTmp, 0, sizeof(sTmp));
							AlltrimString(acGRP_Old);
							memcpy(sTmp, record_operatori.gruppo_pa, sizeof(record_operatori.gruppo_pa));
							AlltrimString(sTmp);

							log(LOG_INFO, "%s;%s; (UPD) GR_PA (before): %.8s-%.10s-%s-%d",
											gUtente, gIP, record_operatori.paese, record_operatori.cod_op,
											acGRP_Old, nMaxTs_Old);
							log(LOG_INFO, "%s;%s; (UPD) GR_PA (after): %.8s-%.10s-%s-%d",
											gUtente, gIP, record_operatori.paese, record_operatori.cod_op,
											sTmp, record_operatori.max_ts );
						}
						else
						{
							sprintf(sTmp, "Error (%d) in updating Remote file [%s][grp:%s]", rc, acFileOperatori_Rem, ac_GRP );
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							strcat(sTmp,"\n ATTENTION the group of some operators may have been changed ");
							Display_Message(0, "", sTmp);
							MBE_UNLOCKREC(handleOP_rem);

							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_operatori_backup, (short) sizeof(t_ts_oper_record) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s][grp:%s]", rc, acFileOperatori_Loc, ac_GRP );
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								MBE_UNLOCKREC(handleOP);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
							break;
						}
					}
				} // dbremoto
			}
		}
	}/* while (1) */


	return(rc);
}
