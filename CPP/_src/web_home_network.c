/*----------------------------------------------------------------------------
*   PROGETTO : home network
*-----------------------------------------------------------------------------
*
*   File Name       : home_network
*   Ultima Modifica : 09/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione DB Lac e cell
*   Gestione tabelle con jquery
*   -----------
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
#include <sspfunc.h>
#include <cextdecs.h (JULIANTIMESTAMP)>
#include "cgi.h"
#include "tfs3.h"
#include "tfs2.h"
#include "web_func.h"
#include "ssplog.h"

/*------------- PROTOTIPI -------------*/
void Display_File();
void Maschera_Modifica(short tipo);
void Aggiorna_Dati(short tipo);
short scrivi_remoto(short handleDB, struct _ts_border_cells_record *record_borderCID, short nOperation );
short Aggiorna_Rec_ricarica(short handle, short handle_rem, long long lJTS);

extern short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );

short gLenKey;

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sTmp[500];
	short	rc = 0;
	char 	ac_err_msg[255];
    short 	rcSes;
    int		found=1;

    gLenKey = 4;
    disp_Top = 0;

	// Returns 1 (OK) o 0 (KO)
	rcSes =  (short) cgi_session_verify(ac_err_msg);
	if (rcSes == 0)
	{
		printf("<br><br><center><font color=red>%s</font>", ac_err_msg);
		fflush(stdout);
		exit(0);
	}	

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));

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

	// **************************** Nome della CGI ********************************************
	gName_cgi = getenv( "SCRIPT_NAME" );

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
	sprintf(log_spooler.NomeDB, "Home Network");	// max 20 char

	Lettura_FileIni();

	// -------------------------- LOG ------------------------------------------

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	// --------------------------------------------------------------------

	/* tipo operazione */
	memset(sOperazione, 0x00, sizeof(sOperazione));

	strcpy(sOperazione, "DISPLAY");	//default
	if ( (wrk_str = cgi_param( "OPERATION" ) ) != NULL )
		strcpy(sOperazione, wrk_str);


	//-------------------------------- TIPO OPERAZIONE -----------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "All");
		strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		log(LOG_INFO, "%s;%s; Display Home Network ",gUtente, gIP);
		Display_File();

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Home Network - Window Modify",gUtente, gIP);
		Maschera_Modifica(UPD);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Home Network - Window New ",gUtente, gIP);
		Maschera_Modifica(INS);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update Home Network ",gUtente, gIP);
		Aggiorna_Dati(UPD);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert Home Network ",gUtente, gIP);
		Aggiorna_Dati(INS);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete Home Network ",gUtente, gIP);
		Aggiorna_Dati(DEL);
	}

	log_close();

return(0);
}

/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	char		sTmp[500];
	short		rc = 0;

	struct _ts_border_cells_record record_borderCID;

	/* inizializza la struttura tutta a blank */
	memset(&record_borderCID, ' ', sizeof(struct _ts_border_cells_record));
	record_borderCID.lac = 0;
	record_borderCID.ci_sac = 0;

	Display_TOP("");

    /*************************************
	* Apro il file
	* (nome file, handle, display, tipo)
	***************************************/
	rc = Apri_File(acFileBord_CID_Loc, &handle, 1, 0);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, gLenKey, 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileBord_CID_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			printf("<BR><CENTER>");
			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Area' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH>&nbsp;Location Area Code</TH>\n");
			printf("  <TH>&nbsp;Service Area Code</TH>\n");
			printf("  <TH>&nbsp;Description</TH>\n");
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
				rc = MBE_READX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileBord_CID_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if(record_borderCID.lac != 0 )
					{
						/***************************
						* Scrive il record a video
						****************************/
						// (link) viene disbilitato sul cancella
						printf("<TR class='gradeGreen'  onclick=\"if (link) javascript:location='%s?OPERATION=MODY&LAC=%d&CELL=%d'\" >\n",
								gName_cgi, record_borderCID.lac, record_borderCID.ci_sac);

						printf("<TD onclick='link=true'>&nbsp;%d</TD>\n", record_borderCID.lac);
						printf("<TD onclick='link=true'>&nbsp;%d</TD>\n", record_borderCID.ci_sac);

						printf("  <TD onclick='link = true'>&nbsp;%.64s</TD>\n", record_borderCID.description);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&LAC=%d&CELL=%d', 'LAC:[%d] SAC[%d]');\" title='Delete'>",
								gName_cgi, record_borderCID.lac, record_borderCID.ci_sac,
								record_borderCID.lac, record_borderCID.ci_sac);

						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
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
			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Area' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);
			printf("</CENTER>\n");
			fflush(stdout);

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
	char		sTipo[20];
	char		acReadOnly[20];
	char		strdata[25];
	short		handle = -1;
	short		rc = 0;
	struct 		_ts_border_cells_record record_borderCID;

	/* inizializza la struttura tutta a blank */
	memset(&record_borderCID, ' ', sizeof(struct _ts_border_cells_record));

	record_borderCID.lac = 0;
	record_borderCID.ci_sac =0;

	/* inizializza la struttura tutta a blank */
	memset(sTmp, 0, sizeof(sTmp));

	if (( (wrk_str = cgi_param( "LAC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_borderCID.lac = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "CELL" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_borderCID.ci_sac = (short) atoi(wrk_str);

	if (tipo == UPD)
	{
		sprintf(sTmp, "Area Code Update");
		strcpy(sTipo, "Update");
		strcpy(acReadOnly, "disabled");

		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileBord_CID_Loc, &handle, 1, 1);
		if (rc == 0)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, gLenKey, 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileBord_CID_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				return;
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileBord_CID_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					return;
				}
			}
			MBE_FILE_CLOSE_(handle);
		}
	}
	else
	{
		sprintf(sTmp, "Area Code Insertion");
		strcpy(sTipo, "Insert");
		strcpy(acReadOnly, " ");
	}

	Display_TOP("");
	printf("<br><br>\n");
	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/
	printf("<form method='POST' action='%s' name='inputform' onsubmit=\"return checkHomeNet(%d)\">\n", gName_cgi, tipo);
	printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);
	if (tipo == UPD)
	{
		printf("<INPUT TYPE='hidden' name='LAC' value='%d'>\n", record_borderCID.lac);
		printf("<INPUT TYPE='hidden' name='CELL' value='%d'>\n", record_borderCID.ci_sac);
	}
	printf("<fieldset><legend>%s&nbsp;</legend>\n", sTmp);
	printf("<center>");
	printf("<TABLE width ='60%%' cellspacing=10 border=0>\n\
			<TR>\n");
	fflush(stdout);

	printf("<TD align=right><B>Location Area Code (LAC):</B></TD>\n\
			<TD align=left width='25px'><INPUT TYPE='text' class='numeric' SIZE='8' MAXLENGTH=5 NAME='LAC' VALUE='%d' %s></TD>",
				record_borderCID.lac, acReadOnly);

	printf("<TD align=right width='200px'><B>Service Area Code or Cell ID:</B></TD>\n\
			<TD align=left><INPUT TYPE='text' class='numeric' SIZE='8' MAXLENGTH=5 NAME='CELL' VALUE='%d' %s></TD>",
				record_borderCID.ci_sac, acReadOnly);
	printf("</TR><TR>");

	printf("<TD align=right><B>Descrption:</B></TD>\n\
			<TD align=left colspan='3'>\
			<INPUT TYPE='text' SIZE='70' MAXLENGTH='64' NAME='DESC' VALUE='%s'></TD>", GetStringNT(record_borderCID.description, sizeof(record_borderCID.description)) );

	printf("</TR>");

	if (tipo == UPD)
	{
		memset(strdata, 0, sizeof(strdata));
		TS2string(strdata, record_borderCID.ts);
		printf("<TD align=right><B>Insert/Update Time Stamp:</B></TD>\n");
		printf("<TD align=left colspan='2'>%s</TD>", strdata);
	}

	printf("</TABLE><br>\n" );
	printf("</center>");
	printf("</fieldset>\n");
	printf("<CENTER>\n");

	fflush(stdout);

	printf("<BR>");
	printf("<BR>\n");

	printf("<input type='button'  icon='ui-icon-home'  VALUE='Return To List' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
	printf("<input type='submit'  icon='ui-icon-check' VALUE='%s' name='OPERATION' >&nbsp;",sTipo);
	printf("<input type='reset'   icon='ui-icon-arrowrefresh-1-n'  VALUE='Reset' >\n");

	printf("</CENTER></form></font>\n");

	Display_BOTTOM();

}
//************************************************************************
// tipo == 0 modifica
// tipo == 1 inserimento 
// tipo == 2 cancellazione  
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		ac_Description[100];
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;
	long long	lJTS = 0;

	struct _ts_border_cells_record record_borderCID;
	struct _ts_border_cells_record record_borderCID_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_borderCID, ' ', sizeof(struct _ts_border_cells_record));
	memset(&record_borderCID_backup, ' ', sizeof(struct _ts_border_cells_record));
	memset(ac_Description, 0, sizeof(ac_Description));

	record_borderCID.lac = 0;
	record_borderCID.ci_sac =0;
	//GMT
	GetTimeStamp(&lJTS);


	if (( (wrk_str = cgi_param( "LAC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_borderCID.lac = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "CELL" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_borderCID.ci_sac = (short) atoi(wrk_str);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Lac=%d;Cell=%d",record_borderCID.lac, record_borderCID.ci_sac);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;


	if (( (wrk_str = cgi_param( "DESC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(record_borderCID.description, wrk_str, strlen(wrk_str));
		sprintf(ac_Description, wrk_str);
	}

	rc = Check_LenMsg(ac_Description, 1, sizeof(record_borderCID.description), "Description");
	
	if(rc == 0)
	{
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileBord_CID_Loc, &handle, 1, 1);
		if (rc == 0 )
			rc = Apri_File(acFileBord_CID_Rem, &handle_rem, 1, 1);

		if (rc == 0  && tipo == UPD || tipo == DEL)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, gLenKey, 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileBord_CID_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileBord_CID_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					// ****  faccio copia di BACKUP per eventuale ripristino ******
					memcpy(&record_borderCID_backup, &record_borderCID, sizeof(record_borderCID));

					//**************************  MODIFICA  ****************************************
					if(tipo == UPD)
					{
						strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

						// aggiorno I DATI
						memset(record_borderCID.description, ' ', sizeof(record_borderCID.description));
						memcpy(record_borderCID.description, ac_Description, strlen(ac_Description));
						record_borderCID.ts = lJTS;

						//aggiorno il record in LOCALE con i dati modificati
						rc = MBE_WRITEUPDATEX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating  Local file [%s] ", rc, acFileBord_CID_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handle);
						}
						else
						{
							// ********************* scrivo DB REMOTO ***********************
							rc= scrivi_remoto(handle_rem, &record_borderCID, UPD);
							if(rc == 0)
							{
								// tutto ok unlock locale
								MBE_UNLOCKREC(handle);

								//****************************************
								// scritture DB OK
								log(LOG_INFO, "%s;%s; UpdCID:%d;%d",
													gUtente, gIP,
													record_borderCID.lac,
													record_borderCID.ci_sac);
							}
							else
							{
								// ERRORE SCRITTURA REMOTO
								// aggiorno il record in Locale con i dati originali
								rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_borderCID_backup, (short) sizeof(struct _ts_border_cells_record) );
								if(rc)
								{
									sprintf(sTmp, "Error (%d) in updating  Local file [%s] ", rc, acFileBord_CID_Loc);
									log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
									Display_Message(1, "", sTmp);
									MBE_UNLOCKREC(handle);
								}
								// setto rc a 1 per segnalare errore
								rc = 1;
							}
						}
					}
					//*************************** CANCELLAZIONE***********************************
					else
					{
						strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL

						rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_borderCID, 0);
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in deleting file [%s] ", rc, acFileBord_CID_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handle);
						}
						else
						{
							// ********************* CANCELLO DB REMOTO ***********************
							rc= scrivi_remoto(handle_rem, &record_borderCID, DEL);
							if(rc == 0)
								log(LOG_INFO, "%s;%s; DelCID:%d-%d",gUtente, gIP,  record_borderCID.lac, record_borderCID.ci_sac);
							else
							{
								// ERRORE cancellazione REMOTO
								// inserisco il record in Locale con i dati originali
								rc = MBE_WRITEX( handle, (char *) &record_borderCID_backup, (short) sizeof(struct _ts_border_cells_record) );
								/* errore */
								if (rc)
								{
									sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileBord_CID_Loc);
									log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								}
								// setto rc a 1 per segnalare errore
								rc = 1;
							}
						}
					} //*************************** fine  CANCELLAZIONE***********************************
				}
			} //*********************fine operaz upd e del ******************************************
		}
	}

	if (rc == 0  && tipo == INS)
	{
		strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL

		record_borderCID.ts = lJTS;

		rc = MBE_WRITEX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
		/* errore */         
		if (rc)
		{
			if (rc == 10 )
			{
				sprintf(sTmp, "LAC-SAC [%d-%d] already exist", record_borderCID.lac, record_borderCID.ci_sac);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFileBord_CID_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			rc= scrivi_remoto(handle_rem, &record_borderCID, INS);
			if(rc == 0)
			{
				// scrivo Log
				log(LOG_INFO, "%s;%s; InsCID:%d;%d",
									gUtente, gIP,
									record_borderCID.lac,
									record_borderCID.ci_sac);
			}
			else
			{
				// ERRORE Inserimento REMOTO
				//cancello locale
				MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, gLenKey, 0, EXACT);
				MBE_READLOCKX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_borderCID, 0);
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in deleting file [%s] -", rc, acFileBord_CID_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}
	}


	if (rc == 0 )
		rc = Aggiorna_Rec_ricarica(handle, handle_rem, lJTS);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	if (rc == 0 )
		Display_File();

}

//************************************************************************************************
// record * che in realtà sono 0
//************************************************************************************************

short Aggiorna_Rec_ricarica(short handle, short handle_rem, long long lJTS)
{
	char		sTmp[500];
	short		nTypeAgg;
	short		rc = 0;

	struct _ts_border_cells_record record_borderCID;

	/* inizializza la struttura tutta a blank */
	memset(&record_borderCID, ' ', sizeof(struct _ts_border_cells_record));

	record_borderCID.lac = 0;
	record_borderCID.ci_sac = 0;

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, gLenKey, 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileBord_CID_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
		/* errore... */
		if ( rc)
		{
			if(rc == 1)
			{
				//aggiorno il record con la data attuale
				record_borderCID.ts = lJTS;

				rc = MBE_WRITEX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
				/* errore */
				if (rc)
				{
					sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFileBord_CID_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
					nTypeAgg = INS;
			}
			else
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileBord_CID_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			record_borderCID.ts = lJTS;

			rc = MBE_WRITEUPDATEX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating  Local file [%s] ", rc, acFileBord_CID_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
			else
				nTypeAgg = UPD;
		}

		if(rc == 0)
		{
			// ********************* scrivo DB REMOTO ***********************
			rc= scrivi_remoto(handle_rem, &record_borderCID, nTypeAgg);
			if(rc == 0)
			{
				// tutto ok unlock locale
				MBE_UNLOCKREC(handle);
			}
		}
	}

	return(rc);
}

//******************************************************************************************************
short scrivi_remoto(short handleDB, struct _ts_border_cells_record *record_borderCID, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	struct _ts_border_cells_record record_borderCID_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB, (char *) &record_borderCID->lac, gLenKey, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFileBord_CID_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &record_borderCID_tmp, (short) sizeof(struct _ts_border_cells_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFileBord_CID_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
	}

	if (rc == 0)
	{
		if (nOperation == UPD)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] ", rc, acFileBord_CID_Rem );
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "LAC-SAC [%d-%d] already exist in REMOTE DB", record_borderCID->lac, record_borderCID->ci_sac);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFileBord_CID_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_borderCID, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] ", rc, acFileBord_CID_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
	}
	return(rc);
}

