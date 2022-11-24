/*----------------------------------------------------------------------------
*   PROGETTO : Paesi
*-----------------------------------------------------------------------------
*
*   File Name       : paesi
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione DB paesi
*   Gestione tabelle con jquery
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
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <cextdecs.h (SERVERCLASS_SEND_, SERVERCLASS_SEND_INFO_)>

#include "cgi.h"
#include "tfs3.h"
#include "tfs2.h"
#include "web_func.h"
#include "ssplog.h"


/*------------- PROTOTIPI -------------*/
void 	Display_File();
void 	Maschera_Modifica(short tipo);
void 	Aggiorna_Dati(short tipo);
short 	Aggiorna_Operatori_PA(short nMaxTS, int nReset_Ts_I, char *acPaese);
short 	scrivi_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi, short nOperation );

extern short Aggiorna_PA_rec_Aster(short handle, short handlePA_rem);
extern short Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );


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
	sprintf(log_spooler.NomeDB, "Country");	// max 20 char

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

		log(LOG_INFO, "%s;%s; Display Countries ",gUtente, gIP);
		Display_File();

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);

	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Countries - Window Modify",gUtente, gIP);
		Maschera_Modifica(UPD);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Countries - Window New ",gUtente, gIP);
		Maschera_Modifica(INS);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update Countries ",gUtente, gIP);
		Aggiorna_Dati(UPD);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert Countries ",gUtente, gIP);
		Aggiorna_Dati(INS);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete Countries ",gUtente, gIP);
		Aggiorna_Dati(DEL);
	}

	log_close();

return(0);
}

/******************************************************************************/
// nTipo = 0  chiamata da DISLPLAY
// nTipo = 2  aggiorna dati (modifica o cancellazione)
/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	char		sTmp[500];
	short		rc = 0;
	long		lRecord = 0;
	char		KeyPaese[8];
	char		acDen_Paese[50];

	struct _ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(struct _ts_paesi_record));
	memset(acDen_Paese, 0, sizeof(acDen_Paese));
	memset(KeyPaese, ' ', sizeof(KeyPaese));

	Display_TOP("");


    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle, 1, 0);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &KeyPaese, sizeof(KeyPaese), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			printf("<BR><CENTER>");
			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Country' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH>&nbsp;Country Code</TH>\n");
			printf("  <TH>&nbsp;Country</TH>\n");
			printf("  <TH>&nbsp;Unbundling</TH>\n");
			printf("  <TH>&nbsp;Max TS</TH>\n");
			printf("  <TH>&nbsp;Reset Interval</TH>\n");
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
				rc = MBE_READX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if( memcmp(record_paesi.paese, "********", 8))
					{
						// se campo è a space
						if(record_paesi.reset_ts_interval == 0x20202020)
							record_paesi.reset_ts_interval = 0;
						/***************************
						* Scrive il record a video
						****************************/
						if( record_paesi.max_ts == 8224)
							record_paesi.max_ts = 0;

						// (link) viene disbilitato sul cancella
						printf("<TR class='gradeGreen'  onclick=\"if (link) javascript:location='%s?OPERATION=MODY&PAESE=%.8s'\" >\n",
								gName_cgi, record_paesi.paese);

						printf("<TD onclick='link=true'>&nbsp;%.8s</TD>\n",	record_paesi.paese);
						printf("  <TD onclick='link = true'>&nbsp;%.64s</TD>\n", record_paesi.den_paese);

						/*if(record_paesi.eu_flag == '1')
							printf(" <TD align='center' onclick='link = true'><IMG SRC='images/accept.gif'  BORDER=0 title='Active Roaming Unbundling' </TD>");
						else
							printf("  <TD onclick='link = true'>&nbsp;</TD>");*/
						printf("<TD align='center' onclick='link=true' id='tdred'>%s</TD>\n", (record_paesi.eu_flag == '1') ? "&#x2714;" : "&nbsp;");

						printf("  <TD onclick='link = true'>&nbsp;%d</TD>\n", record_paesi.max_ts);
						printf("  <TD onclick='link = true'>&nbsp;%d</TD>\n", record_paesi.reset_ts_interval);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&PAESE=%.8s', 'Country: [%s]');\" title='Delete'>",
								gName_cgi, record_paesi.paese, GetStringNT(record_paesi.paese, 8));

						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
						fflush(stdout);

						lRecord ++;
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
			printf( "<input type='button' icon='ui-icon-circle-plus' value='New Country' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);
			printf("</CENTER>\n");
			fflush(stdout);

			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		LOGResult = SLOG_ERROR;
    
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
	char		KeyPaese[8];
	short		handle = -1;
	short		rc = 0;
	struct 		_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(struct _ts_paesi_record));


	/* inizializza la struttura tutta a blank */
	memset(sTmp, 0, sizeof(sTmp));
	memset(KeyPaese, ' ', sizeof(KeyPaese));

	if (( (wrk_str = cgi_param( "PAESE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(KeyPaese, wrk_str, strlen(wrk_str));

	if (tipo == UPD)
	{
		sprintf(sTmp, "Country Update");
		strcpy(sTipo, "Update");

		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFilePaesi_Loc, &handle, 1, 1);
		if (rc == 0)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle, KeyPaese, (short)sizeof(KeyPaese), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				return;
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc);
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
		sprintf(sTmp, "Country Insertion");
		strcpy(sTipo, "Insert");
	}

	Display_TOP("");
	printf("<br><br>\n");
	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/
	printf("<form method='POST' action='%s' name='inputform' onsubmit=\"return checkMaxTS('%s')\">\n", gName_cgi, sTipo);
	printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);
	if (tipo == UPD)
		printf("<INPUT TYPE='hidden' name='PAESE' value='%.8s'>\n", KeyPaese);

	printf("<fieldset><legend>%s&nbsp;</legend>\n", sTmp);
	printf("<center>");
	printf("<TABLE width ='80%%' cellspacing=10 border=0>\n\
			<TR>\n");
	fflush(stdout);

	if (tipo == UPD)
	{
		printf("<TD align=right width='40%%'><B>Country Code:</B></TD>\n\
				<TD align=left>%.8s</TD>", KeyPaese);
		printf("</TR><TR>");
		printf("<TD align=right><B>Country:</B></TD>\n\
				<TD align=left>%.64s</TD>", record_paesi.den_paese);
		printf("</TR><TR>");
		printf("<TD align=right>Country Group:</TD>\n\
				<TD align=left>%.64s</TD>", record_paesi.gr_pa);
		printf("</TR><TR>");
	}


	else // inserimento
	{
		printf("<TD align=right width='40%%'><B>Country Code:</B></TD>\n\
				<TD align=left><INPUT TYPE='text' class='numeric' SIZE='10' MAXLENGTH=8 NAME=\"PAESE\"></TD>");
		printf("</TR><TR>");
		printf("<TD align=right><B>Country:</B></TD>\n\
				<TD align=left><INPUT TYPE='text' id='checkChr' SIZE='65' MAXLENGTH=64 NAME=\"DEN_PAESE\"></TD>");
		printf("</TR><TR>");
	}

	if( record_paesi.max_ts == 8224)
		record_paesi.max_ts = 0;
	printf("<TD align=right><B>Max TS:</B></TD>\n\
			<TD align=left><INPUT TYPE='text' class='numeric' SIZE='5' MAXLENGTH=2 NAME='MAX_TS' VALUE='%d'></TD>", record_paesi.max_ts);

	if(tipo == INS)
		record_paesi.reset_ts_interval = 0;

	printf("</TR><TR>");
	printf("<TD align=right><B>Reset Interval:</B></TD>\n\
			<TD align=left><INPUT TYPE='text' class='numeric' SIZE='10' MAXLENGTH=6 NAME='R_TS_I' VALUE='%d'> (sec)</TD>", record_paesi.reset_ts_interval);

	printf("</TR><TR>");
	printf("<TD align=right><B>Roaming Unbundling:</B></TD>\n");
	printf("<TD align=left><INPUT TYPE='checkbox' NAME='UNBU' ");
	if( record_paesi.eu_flag == '1')
		printf(" checked ");
	printf("></td>");
	fflush(stdout);
	printf("</TR>");

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

	if (tipo == UPD)
	{
		memset(sTmp, 0, sizeof(sTmp));
		memcpy(sTmp, record_paesi.den_paese, sizeof(record_paesi.den_paese));
		TrimString(sTmp);

		log(LOG_INFO, "%s;%s; ViewCO:%.8s;%s;%d;%d",
							gUtente, gIP,
							KeyPaese,
							sTmp,
							record_paesi.max_ts,
							record_paesi.reset_ts_interval);
	}
}
//************************************************************************
// tipo == 0 modifica
// tipo == 1 inserimento 
// tipo == 2 cancellazione  

// Aggiorna max-ts del db Paesi 
// Controlla se ci sono record nel DB soglie con Paese o Grp Paese uguale a quello aggiornato
// se ci sono aggiorno record '*****' del DB soglie
// Aggiorna max-ts del DB Operatori
// Controlla se ci sono record nel DB soglie con Opreratore o Grp OP uguale a quello aggiornato
// se ci sono aggiorno record '*****' del DB soglie
// Il record '*****' del DB soglie viene aggiornato un unica volta
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		sTmp2[300];
	char		ac_GRP[LEN_GRP+1];
	char		ac_DenPA[LEN_GRP+1];
	char		acPaese[8];
	char		acUnbu;
	short		nMaxTS = 0;
	int			nReset_Ts_I = 0;
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;

	struct _ts_paesi_record record_paesi;
	struct _ts_paesi_record record_paesi_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(struct _ts_paesi_record));
	memset(&record_paesi_backup, ' ', sizeof(struct _ts_paesi_record));

	memset(ac_GRP, 0, sizeof(ac_GRP));
	memset(ac_DenPA, 0, sizeof(ac_DenPA));
	memset(acPaese, ' ', sizeof(acPaese));

	if (( (wrk_str = cgi_param( "PAESE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_paesi.paese, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "MAX_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		nMaxTS = (short) atoi(wrk_str);
	
	if (( (wrk_str = cgi_param( "R_TS_I" ) ) != NULL ) && (strlen(wrk_str) > 0))
		nReset_Ts_I = atoi(wrk_str);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Paese=%.8s", record_paesi.paese);
	LOGResult = SLOG_OK;

	acUnbu = '0';
	if (( (wrk_str = cgi_param( "UNBU" ) ) != NULL ) && (strlen(wrk_str) > 0))
		acUnbu = '1';

	if (tipo == INS)  //inserimento
	{
		strcpy(log_spooler.TipoRichiesta, "INS");			// LIST, VIEW, NEW, UPD, DEL

		record_paesi.max_ts = nMaxTS;
		record_paesi.reset_ts_interval = nReset_Ts_I;
		record_paesi.eu_flag = acUnbu;

		if (( (wrk_str = cgi_param( "DEN_PAESE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			memcpy(record_paesi.den_paese, wrk_str, strlen(wrk_str));
			memcpy(ac_DenPA, wrk_str, strlen(wrk_str));

			rc = Check_LenMsg(ac_DenPA, 1, LEN_GRP, "Country Name");
		}
	}

	if(rc == 0)
	{
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFilePaesi_Loc, &handle, 1, 1);
		if (rc == 0 )
			rc = Apri_File(acFilePaesi_Rem, &handle_rem, 1, 1);

		if (rc == 0  && tipo == UPD || tipo == DEL)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle, (char *) &record_paesi.paese, (short)sizeof(record_paesi.paese), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					// ****  faccio copia di BACKUP per eventuale ripristino ******
					memcpy(&record_paesi_backup, &record_paesi, sizeof(record_paesi));

					// salvo gruppo paese e denominazione paese per la ricerca in soglie
					memcpy(ac_GRP, record_paesi.gr_pa, sizeof(record_paesi.gr_pa));
					memcpy(ac_DenPA, record_paesi.den_paese, sizeof(record_paesi.den_paese));
					// aggiorno I DATI
					record_paesi.max_ts = nMaxTS;
					record_paesi.reset_ts_interval = nReset_Ts_I;
					record_paesi.eu_flag = acUnbu;

					//**************************  MODIFICA  ****************************************
					if(tipo == UPD)
					{
						strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

						//aggiorno il record in LOCALE con i dati modificati
						rc = MBE_WRITEUPDATEX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating  Local file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handle);
						}
						else
						{
							// ********************* scrivo DB REMOTO ***********************
							rc= scrivi_Paesi_remoto(handle_rem, &record_paesi, UPD);
							if(rc == 0)
							{
								// tutto ok unlock locale
								MBE_UNLOCKREC(handle);

								//****************************************
								// scritture DB OK
								memset(sTmp, 0, sizeof(sTmp));
								memset(sTmp2, 0, sizeof(sTmp2));
								memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
								memcpy(sTmp2, record_paesi.den_paese, sizeof(record_paesi.den_paese));
								TrimString(sTmp);
								TrimString(sTmp2);
								log(LOG_INFO, "%s;%s; UpdCO:%s;%s;%d;%d",
													gUtente, gIP,
													sTmp,
													sTmp2,
													nMaxTS,
													nReset_Ts_I);
							}
							else
							{
								// ERRORE SCRITTURA REMOTO
								// aggiorno il record in Locale con i dati originali
								rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_paesi_backup, (short) sizeof(struct _ts_paesi_record) );
								if(rc)
								{
									sprintf(sTmp, "Error (%d) in updating  Local file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
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

						rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_paesi, 0);
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in deleting file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handle);
						}
						else
						{
							// ********************* CANCELLO DB REMOTO ***********************
							rc= scrivi_Paesi_remoto(handle_rem, &record_paesi, DEL);
							if(rc == 0)
								log(LOG_INFO, "%s;%s; DelCO:%.8s",gUtente, gIP,  record_paesi.paese);
							else
							{
								// ERRORE cancellazione REMOTO
								// inserisco il record in Locale con i dati originali
								rc = MBE_WRITEX( handle, (char *) &record_paesi_backup, (short) sizeof(struct _ts_paesi_record) );
								/* errore */
								if (rc)
								{
									if (rc == 10 )
									{
										sprintf(sTmp, "In Local DB, Country [%.8s] already exist", record_paesi.paese);
										log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
										Display_Message(1, "", sTmp);
									}
									else
									{
										sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFilePaesi_Loc);
										log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
										Display_Message(1, "", sTmp);
									}
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
		rc = MBE_WRITEX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
		/* errore */         
		if (rc)
		{
			if (rc == 10 )
			{
				sprintf(sTmp, "Country [%.8s] already exist", record_paesi.paese);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFilePaesi_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			rc= scrivi_Paesi_remoto(handle_rem, &record_paesi, INS);
			if(rc == 0)
			{
				// scrivo Log
				memset(sTmp, 0, sizeof(sTmp));
				memset(sTmp2, 0, sizeof(sTmp2));
				memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
				memcpy(sTmp2, record_paesi.den_paese, sizeof(record_paesi.den_paese));
				TrimString(sTmp);
				TrimString(sTmp2);
				log(LOG_INFO, "%s;%s; InsCO:%s;%s;%d;%d",
									gUtente, gIP,
									sTmp,
									sTmp2,
									record_paesi.max_ts,
									nReset_Ts_I);
			}
			else
			{
				// ERRORE Inserimento REMOTO
				//cancello locale
				MBE_FILE_SETKEY_( handle, (char *) &record_paesi.paese, (short)sizeof(record_paesi.paese), 0, EXACT);
				MBE_READLOCKX( handle, (char *) &record_paesi, (short) sizeof(struct _ts_paesi_record) );
				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_paesi, 0);
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in deleting file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}
	}

	// aggiorno il db operatori e rec * Paesi
	if (rc == 0)
	{
		Aggiorna_PA_rec_Aster(handle, handle_rem);

		memset(sTmp, 0, sizeof(sTmp));
		memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
		Aggiorna_Operatori_PA(nMaxTS, nReset_Ts_I, sTmp);
	}
	else
		LOGResult = SLOG_ERROR;

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	if (rc == 0 )
		Display_File();

}

//*************************************************************************
// aggiorno il campo max_ts  e reset interval nel db operatori
//*************************************************************************
short Aggiorna_Operatori_PA(short nMaxTS, int nReset_Ts_I, char *acPaese)
{
	short		handle2 = -1;
	short		handleOP_rem = -1;
	char		sTmp[500];
	char		ac_Chiave[8];
	short		rc = 0;

	t_ts_oper_record record_operatori;
	t_ts_oper_record record_operatori_tmp;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof( t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, acPaese, sizeof(acPaese));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	if (rc == 0 )
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
		if (rc != 0)
		{	/* errore */
			sprintf(sTmp, "Error (%d) File_setkey Local file [%s] ", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			rc = MBE_FILE_SETKEY_( handleOP_rem, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey Remote file [%s] ", rc, acFileOperatori_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		/* tutto ok */
		if(rc == 0)
		{
			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READLOCKX( handle2, (char *) &record_operatori, (short) sizeof( t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s] ", rc, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
	 					rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					record_operatori.max_ts = nMaxTS;
					record_operatori.reset_ts_interval = nReset_Ts_I;

					//aggiorno il record con i dati modificati
					rc = MBE_WRITEUPDATEUNLOCKX( handle2, (char *) &record_operatori, (short) sizeof( t_ts_oper_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating file [%s] ", rc, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle2);
						break;
					}
				}

				if(rc == 0)
				{
					/*********************************************
					*    Aggiorno il DB REMOTO
					**********************************************/
					rc = MBE_READLOCKX( handleOP_rem, (char *) &record_operatori_tmp, (short) sizeof( t_ts_oper_record) );
					/* errore... */
					if (rc != 0)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) in reading Remote file [%s] ", rc, acFileOperatori_Rem);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
						}
						else
		 					rc = 0;
						break;
					}
					/* record TROVATO */
					else  /* readx ok */
					{
						//aggiorno il record con i dati modificati
						rc = MBE_WRITEUPDATEUNLOCKX( handleOP_rem, (char *) &record_operatori, (short) sizeof( t_ts_oper_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating Rempte file [%s] ", rc, acFileOperatori_Rem);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handleOP_rem);
							break;
						}
					}
				}

			}/* while (1) */
		}
	}

	// aggiorno record * del DB operatori
	if (rc == 0)
		Aggiorna_Operatori_rec_Aster(handle2, handleOP_rem);

	MBE_FILE_CLOSE_(handle2);
	MBE_FILE_CLOSE_(handleOP_rem);
	return(rc);
}
//******************************************************************************************************
short scrivi_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	struct _ts_paesi_record record_paesi_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB,  record_paesi->paese, (short)sizeof(record_paesi->paese), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFilePaesi_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &record_paesi_tmp, (short) sizeof(struct _ts_paesi_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFilePaesi_Rem);
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_paesi, (short) sizeof(struct _ts_paesi_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] - Country: [%.8s]", rc, acFilePaesi_Rem, record_paesi->paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) record_paesi, (short) sizeof(struct _ts_paesi_record) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Country [%.8s] already exist in REMOTE DB", record_paesi->paese);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFilePaesi_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_paesi, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] - Country: [%.8s]", rc, acFilePaesi_Rem, record_paesi->paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
	}
	return(rc);
}

