/*----------------------------------------------------------------------------
*   PROGETTO : EStrategy ME
*-----------------------------------------------------------------------------
*
*   File Name       : strategy_ME
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Esports DB operatori
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

#include <unistd.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <ctype.h>
#include <tal.h>
#include <usrlib.h>
#include <cextdecs.h (DELAY)>
#include <cextdecs.h (SERVERCLASS_SEND_, SERVERCLASS_SEND_INFO_)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"


#define MAX_LUNG_MESS		100

/*------------------ PROTOTIPI -------------------*/
void 	Display_File();
void 	Lettura_Variabili(t_ts_nostd_tac_record *record_nostdtac);
void 	Aggiorna_Dati(short tipo);
void 	Maschera_Modifica(short tipo);
short 	Aggiorna_rec_Aster(short handle, short handle_rem);

/*------------------ GLOBAL VARIABLES -------------------*/
long	acRecordDel;
long	acRecordIns;
long	acRecordUpd;

/* --------------------------------------------------------------------------*/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sTmp[500];
	short   rc;
	char ac_err_msg[255];
    short rcSes;

	acRecordDel = 0;
	acRecordIns = 0;
	acRecordUpd = 0;
    disp_Top = 0;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));
	memset(acFileNostdtac_Loc, 0x00, sizeof(acFileNostdtac_Loc));

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
	sprintf(log_spooler.NomeDB, "NOSTDTAC");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "All");
		strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		log(LOG_INFO, "%s;%s; ME Strategies - Display ",gUtente, gIP);
		Display_File();

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; ME Strategies - Window Modify ",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; ME Strategies - Window News ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Modify")== 0 )
	{
		log(LOG_INFO, "%s;%s; ME Strategies - Update ",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; ME Strategies - Insert ",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; ME Strategies - Delete ",gUtente, gIP);
		Aggiorna_Dati(2);
	}

	log_close();
}


/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	char		sTmp[500];
	char		acKey[15];
	short		rc = 0;

	t_ts_nostd_tac_record record_nostdtac;

	/* inizializza la struttura tutta a blank */
	memset(&record_nostdtac, ' ', sizeof(t_ts_nostd_tac_record));

	memset(acKey, ' ', sizeof(acKey));

    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileNostdtac_Loc, &handle, 1, 0);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, acKey, sizeof(acKey), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey from file [%s] ", rc, acFileNostdtac_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			Display_TOP("");

			printf("<BR><center>");
			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Record' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH><strong>&nbsp;TAC / Imei</strong></TH>\n");
			printf("  <TH><strong>&nbsp;String</strong></TH>\n");
			printf("  <TH width='5%%'>&nbsp;</TH>\n");
			printf("</TR>\n");
			printf("</thead>\n");

			printf("<tbody class='editTable'>");
			fflush(stdout);

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s] ", rc, acFileNostdtac_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if( memcmp(record_nostdtac.imei, "***************", sizeof(record_nostdtac.imei)) )
					{
						/***************************
						* Scrive il record a video
						****************************/
						printf("<TR class='gradeGreen'  onclick=\"if (link) javascript:location='%s?OPERATION=MODY&TAC=%.15s'\" >\n",
								gName_cgi, record_nostdtac.imei);
						printf("<TD onclick='link=true'>&nbsp;%.15s</TD>\n",	record_nostdtac.imei);

						printf("  <TD onclick='link=true'>&nbsp;%.100s</TD>\n", record_nostdtac.stringa);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&TAC=%.15s', 'TAC/Imei: [%s]');\" title='Delete'>",
								gName_cgi, record_nostdtac.imei,
								GetStringNT(record_nostdtac.imei, 15));

						printf("<div class='del_icon'></div></TD>\n");
						printf("</TR>");
						fflush(stdout);
					}
				}
			}/* while (1) */
			

			printf("</tbody>");
			printf("</TABLE>\n");
			// inserimento delle finestre di dialogo
			printf("<script>\n");
			printf("    insert_Confirm_Delete();\n");
			printf("</script>\n");

			printf("<BR>\n");
			printf("<BR>\n");

			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Record' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("</CENTER>\n");

			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
    
	return;
}

/******************************************************************************/
// tipo = 0 modifica
// tipo = 1 inserimento
/******************************************************************************/
void Maschera_Modifica(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	short		handle = -1;
	short		rc = 0;
	char		ac_Chiave[15];
	char		sTipo[20];
	char		sTxt[400];

	t_ts_nostd_tac_record record_nostdtac;

	/* inizializza la struttura tutta a blank */
	memset(&record_nostdtac, ' ', sizeof(t_ts_nostd_tac_record));
	memset(ac_Chiave,     ' ', sizeof(ac_Chiave));

	memset(sTmp, 0, sizeof(sTmp));
	
	if(tipo == 0) //MODIFICA
	{
		if (( (wrk_str = cgi_param( "TAC" ) ) != NULL ) && (strlen(wrk_str) > 0))
			memcpy(ac_Chiave, wrk_str, strlen(wrk_str));

		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileNostdtac_Loc, &handle, 1, 1);
		if(rc == 0)
		{
			rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey from file [%s] ", rc, acFileNostdtac_Loc);
				log(LOG_ERROR, "%s;%s; : %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileNostdtac_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);

					Display_Message(1, "", sTmp);
				}
			}
			MBE_FILE_CLOSE_(handle);
		}
	}			
		
	if(rc == 0 )
	{
		if (tipo == 0)
		{
			sprintf(sTmp, "ME STRATEGIES - Modify");
			strcpy(sTipo, "Modify");
		}
		else
		{
			sprintf(sTmp, "ME STRATEGIES - New record");
			strcpy(sTipo, "Insert");
		}

		Display_TOP("");

		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<form method='POST' action='%s' name='inputform'>\n", gName_cgi);
		printf("<BR><BR>\n");
		printf("<fieldset><legend>%s&nbsp;</legend>\n", sTmp);
		printf("<CENTER>\n");

		printf("<TABLE width = 100%% cellspacing=8 border=0>\n\
				<TR>\n");
		fflush(stdout);

		printf("<TD align=right><b>TAC / IMEI:</b></TD>\n");

		if(tipo == 1)
			printf("<TD align=left><input type='text' name='TAC' size='20' MAXLENGTH=15 class='numeric'></TD>\n");
		else
			printf("<TD align=left>%.15s</td>", record_nostdtac.imei);

		printf("</tr><tr>\n");
		fflush(stdout);

		printf("<TD align=right><b>TRACE LEVEL:</b></TD>\n");
		printf("<TD align=left><select name='FLAG' class='chosen-select' STYLE='width: 100px' >\n\
				<option value = ' '>Default</option>\n\
				<option value = '1'");
		if (record_nostdtac.trace_level == 1)
			printf(" selected ");
		printf(">Error</option>\n\
				<option value = '5' ");
		if (record_nostdtac.trace_level == 5)
			printf(" selected ");
		printf(">Warning</option>\n\
			   <option value = '9' ");
		if (record_nostdtac.trace_level == 9)
			printf(" selected ");
		printf(">Info</option>\n\
			  <option value = '10' ");
		if (record_nostdtac.trace_level == 10)
			printf(" selected ");
		printf(">Debug</option>\n");
		
		printf("</select></TD>\n");
		printf("</tr><tr>\n");
		fflush(stdout);
			
		memset(sTxt, 0, sizeof(sTxt));
		memcpy(sTxt, record_nostdtac.stringa, sizeof(record_nostdtac.stringa));
		AlltrimString(sTxt);

		printf("<TD align='right' valign='top'>\n");
		printf("<b>String:<BR>(%d characters max)</b><BR>				\n", MAX_LUNG_MESS);
		printf("<input TYPE='text' SIZE='3' MAXLENGTH='3' NAME='Conta' VALUE='%d'>	\n", MAX_LUNG_MESS);
		printf("  </TD>\n");
		printf("  <TD colspan='5'><textarea cols='80' rows='4' name='STR' onKeyUp=\"ContaCar('STR', 'Conta', %d)\">%s</textarea></TD>	\n",
				 MAX_LUNG_MESS, sTxt);
		printf("<script language='javascript'>\n\
				<!--\n\
				ContaCar('STR', 'Conta', %d)\n\
				//-->\n\
				</script>\n\
			", MAX_LUNG_MESS);

		printf("</tr><tr>\n");
		fflush(stdout);
				
		printf("</TABLE><br>\n" );
		printf("</CENTER>\n");
		printf("</fieldset>\n");
		printf("<CENTER>\n");

		fflush(stdout);

		printf("<BR>");
		printf("<BR>\n");

		printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);
		if(tipo == 0)
			printf("<INPUT TYPE='hidden' name='TAC' value='%.15s'>\n", ac_Chiave);

		printf("<input type='button'  icon='ui-icon-home'  VALUE='Return To List' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
		printf("<input type='submit'  icon='ui-icon-check' VALUE='%s' name='OPERATION' >&nbsp;",sTipo);
		printf("<input type='reset'   icon='ui-icon-arrowrefresh-1-n'  VALUE='Reset' >\n");

		printf("<CENTER>\n");

		Display_BOTTOM();
	}
}


//************************************************************************
// tipo == 0  modifica
// tipo == 0 inserimento 
// tipo == 2 cancellazione

// Controlla se ci sono record nel DB soglie con  Grp Paesi uguale a quello aggiornato
// se ci sono aggiorno record '*****' del DB soglie
// Il record '*****' del DB soglie viene aggiornato un unica volta
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		acKey[15];
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;

	t_ts_nostd_tac_record record_nostdtac;
	t_ts_nostd_tac_record record_appo;
	t_ts_nostd_tac_record record_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_nostdtac, ' ', sizeof(t_ts_nostd_tac_record));
	memset(&record_backup, ' ', sizeof(t_ts_nostd_tac_record));

	Lettura_Variabili(&record_nostdtac);

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileNostdtac_Loc, &handle, 1, 1);
	if( rc)
		return;
	rc = Apri_File(acFileNostdtac_Rem, &handle_rem, 1, 1);

	memset(acKey,  ' ', sizeof(acKey));

	if (( (wrk_str = cgi_param( "TAC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(acKey, wrk_str, strlen(wrk_str));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "tac=%.15s", acKey);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	if (rc == 0 && tipo == 0 || tipo == 2)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_(handle, acKey, sizeof(acKey), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey from file [%s]", rc, acFileNostdtac_Loc);
			log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);

			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handle, (char *) &record_appo, (short) sizeof(t_ts_nostd_tac_record) );
			/* errore... */
			if (rc)
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileNostdtac_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&record_backup, &record_appo, sizeof(t_ts_nostd_tac_record));

				if(tipo == 2)	//cancello il record 
				{
					rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_nostdtac, 0);
					strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
				}
				else		//aggiorno il record con i dati modificati
				{
					rc = MBE_WRITEUPDATEX( handle, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
					strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
				}
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFileNostdtac_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle);
				}
			}
		}
		if(rc == 0)
		{
			// ***************** aggiorno il DB REMOTO ************************************
			rc = MBE_FILE_SETKEY_(handle_rem, acKey, sizeof(acKey), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey Remote file [%s]", rc, acFileNostdtac_Rem);
				log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);

				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handle_rem, (char *) &record_appo, (short) sizeof(t_ts_nostd_tac_record) );
				/* errore... */
				if (rc)
				{
					sprintf(sTmp, "Error (%d) in reading Remote file [%s]", rc, acFileNostdtac_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					if(tipo == 2)	//cancello il record
						rc = MBE_WRITEUPDATEUNLOCKX( handle_rem, (char *) &record_nostdtac, 0);
					else		//aggiorno il record con i dati modificati
						rc = MBE_WRITEUPDATEUNLOCKX( handle_rem, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
					if(rc == 0)
						// tutto ok unlock locale
						MBE_UNLOCKREC(handle);
					else
					{
						sprintf(sTmp, "Error (%d) in writing Remote file [%s]", rc, acFileNostdtac_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle_rem);
					}
				}
			}
			if(rc)
			{
				// ERRORE SCRITTURA REMOTO
				// aggiorno il record in Locale con i dati originali
				if(tipo == 2)
				{
					rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_backup, (short) sizeof(t_ts_nostd_tac_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating Local file [%s] ", rc, acFileNostdtac_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
				}
				else
					rc = MBE_WRITEX( handle, (char *) &record_backup, (short) sizeof(t_ts_nostd_tac_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in inserting in Local file [%s]", rc, acFileNostdtac_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}
	}

	if (rc == 0 && tipo == 1)
	{
		strcpy(log_spooler.TipoRichiesta, "INS");			// LIST, VIEW, NEW, UPD, DEL

		rc = MBE_WRITEX( handle, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
		/* errore */         
		if (rc)
		{
			sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileNostdtac_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			// aggiorno DB REMOTO
			rc = MBE_WRITEX( handle_rem, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
			/* errore */
			if (rc)
			{
				sprintf(sTmp, "Error (%d) in writing Remote file [%s]", rc, acFileNostdtac_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}

		if(rc)
		{
			//******************   ERRORE Inserimento REMOTO
			//cancello locale
			MBE_FILE_SETKEY_(handle, acKey, sizeof(acKey), 0, EXACT);
			MBE_READLOCKX( handle, (char *) &record_nostdtac, (short) sizeof(t_ts_nostd_tac_record) );
			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_nostdtac, 0);
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting in Local file [%s]", rc, acFileNostdtac_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
			// setto rc a 1 per segnalare errore
			rc = 1;
		}
	}

	if(rc == 0 )
		rc = Aggiorna_rec_Aster(handle, handle_rem);

	if(rc == 0 )
		Display_File();
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);
}


//******************************************************************
void Lettura_Variabili(t_ts_nostd_tac_record *record_nostdtac )
{
	char	*wrk_str;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	if (( (wrk_str = cgi_param( "TAC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_nostdtac->imei, wrk_str, strlen(wrk_str));
	if (( (wrk_str = cgi_param( "FLAG" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		if (wrk_str[0] == ' ')
			record_nostdtac->trace_level = wrk_str[0];  // loscrivo come carattere
		else
			record_nostdtac->trace_level = (char) atoi(wrk_str);
	}
	if (( (wrk_str = cgi_param( "STR" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_nostdtac->stringa, wrk_str, strlen(wrk_str));

}
//*******************************************************************************************************************
short Aggiorna_rec_Aster(short handle, short handle_rem)
{
	short		rc = 0;
	char		ac_Chiave[15];
	char		sTmp[500];
	char		acData[50];
	long long	lJTS = 0;

	t_ts_nostd_tac_record record_nostdtac;

	/* inizializza la struttura tutta a blank */
	memset(&record_nostdtac, ' ', sizeof(t_ts_nostd_tac_record));
	memset(acData, 0, sizeof(acData));

	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	GetTimeStamp(&lJTS);
	//converto la data corrente da long long a AAAAMMGGHHMMSS
	TS2stringAAMMGG(acData, lJTS);

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey Local DB [%s]  key=%.15s",
						rc, acFileNostdtac_Loc, ac_Chiave ) ;
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		//------------------------- AGGIORNO  LOCALE----------------------------------
		rc = MBE_READLOCKX( handle, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
		if ( rc)/* errore... */
		{
			if(rc == 1)
			{
				memcpy(record_nostdtac.imei, ac_Chiave, sizeof(ac_Chiave));
				memcpy(record_nostdtac.stringa, acData, strlen(acData));

				//--------------------- inserisco il record
				rc = MBE_WRITEX( handle, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
				/* errore */
				if (rc)
				{
					sprintf(sTmp, "Error (%d) writing in Local file [%s] - key=%.15s",
							rc, acFileNostdtac_Loc, ac_Chiave);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s] - key=%.15s",
						rc, acFileNostdtac_Loc, ac_Chiave);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			memcpy(record_nostdtac.stringa, acData, strlen(acData));

			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) updating in Local file [%s] - key=%.15s",
						rc, acFileNostdtac_Loc, ac_Chiave);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
		}

		if(rc == 0)
		{
			//------------------------- AGGIORNO DB operatori REMOTO----------------------------------
			rc = MBE_FILE_SETKEY_( handle_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey Remote DB [%s] - key=%.15s",
								rc, acFileOperatori_Rem, ac_Chiave) ;
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handle_rem, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
				if ( rc)/* errore... */
				{
					if(rc == 1)
					{
						memcpy(record_nostdtac.imei, ac_Chiave, sizeof(ac_Chiave));
						memcpy(record_nostdtac.stringa, acData, strlen(acData));

						//--------------------- inserisco il record
						rc = MBE_WRITEX( handle_rem, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
						/* errore */
						if (rc)
						{
							sprintf(sTmp, "Error (%d) writing in Remote file [%s] - key=%.15s",
									rc, acFilePaesi_Rem, ac_Chiave);
							Display_Message(1, "", sTmp);
						}
					}
					else
					{
						sprintf(sTmp, "Error (%d) reading in Remote file [%s] - key=%.15s",
								rc, acFilePaesi_Rem, ac_Chiave);
						Display_Message(1, "", sTmp);
					}
				}
				else
				{
					//aggiorno il record con la data attuale
					memcpy(record_nostdtac.stringa, acData, strlen(acData));

					rc = MBE_WRITEUPDATEUNLOCKX( handle_rem, (char *) &record_nostdtac, (short) sizeof(record_nostdtac) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) updating in Remote file [%s] - key=%.15s",
								rc, acFilePaesi_Rem, ac_Chiave);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
				}
			}
		}
	}
	return(rc);
}
