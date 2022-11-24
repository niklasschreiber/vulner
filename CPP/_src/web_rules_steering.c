/*----------------------------------------------------------------------------
*   PROGETTO : Soglie
*-----------------------------------------------------------------------------
*
*   File Name       : Soglie
*   Ultima Modifica : 08/03/2016
*
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione DB Soglie
*   -----------
*------------------------------------------------------------------------------
*   Funzioni contenute
*   ------------------
*
*----------------------------------------------------------------------------*/

/***********************************************************************************
	* IPM KTSTEACS
	* Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
************************************************************************************/

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
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <cextdecs.h (SERVERCLASS_SEND_, SERVERCLASS_SEND_INFO_)>

//#include <locale.h>
//#include <wchar.h>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"
#include "sspfunc.h"
#include "mbedb.h"


/*------------- PROTOTIPI -------------*/
void 	Display_File();
void 	Maschera_Modifica(short tipo);
void 	Delete_Dati(short tipo);
void 	Lettura_Variabili(t_ts_soglie_record *record_soglie);
void 	Aggiorna_Dati(short tipo);
short 	Lista_GRPOperatori();
short 	Lista_GRPaesi();
short 	Controlla_Dati(t_ts_soglie_record *record_soglie, short handle, int *iRes  );
void 	Prepara_Download();
void 	Lista_Soglie();
short 	Carica_Op_Soglie();
short 	Stampa_GRPA(char *buf_DownLoad);
short 	Stampa_GROP(char *buf_DownLoad);
void  	scrivoLog_Soglie(t_ts_soglie_record record_soglie, char *str);
short 	Lista_Operatori(void);
//short Cerca_inGRPOp(char *acGrp);
void trovauser(char *acUser, char *disabled);
//void  ListaPLMN(short content_id, short sel_item_id);

extern void		Leggi_Applica();
extern short	Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo);

/*******************************/
exec sql begin declare section;

	exec sql invoke =USRDESC	as usrdesc_struct;
	struct usrdesc_struct		usrdesc;

exec sql end declare section;

short sqlcode;

exec sql include sqlca;

AVLTREE		listaOPs;
AVLTREE		listaGR_OPs;
AVLTREE		listaGR_PAs;
AVLTREE		lista_OP;


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

	// **************************** Nome della CGI ********************************************
	gName_cgi  = getenv( "SCRIPT_NAME" );

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
	sprintf(log_spooler.NomeDB, "RULESST");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	/* tipo operazione */
	memset(sOperazione, 0x00, sizeof(sOperazione));

	strcpy(sOperazione, "DISPLAY");	//default
	if ( (wrk_str = cgi_param( "OPERATION" ) ) != NULL )
		strcpy(sOperazione, wrk_str);

	//-------------------- TIPO OPERAZIONE --------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "All");
		strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		log(LOG_INFO, "%s;%s; Display Thresholds ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Thresholds - Window Modify",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Thresholds - Window Insert ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Modify")== 0 )
	{
		log(LOG_INFO, "%s;%s; Thresholds - Update",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Thresholds - Insert",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Thresholds - Delete",gUtente, gIP);
		Delete_Dati(0);
	}
	else if (strcmp(sOperazione, "DOWNLOAD")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Thresholds - Download",gUtente, gIP);
		Prepara_Download();
	}
	else if (strcmp(sOperazione, "LISTA")== 0 )
	{
		log(LOG_INFO, "%s;%s; Info Thresholds ",gUtente, gIP);
		Lista_Soglie();
	}

	log_close();

return(0);
}


/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	char		sTmp[500];
	char		ac_Chiave[LEN_KEY_SOGLIE];
	char		acKey[300];
	char		acKeydecod[300];
	short		rc = 0;
	long		lRecord = 0;
	int 		user_type_bitmask;

	t_ts_soglie_record record_soglie;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));


    /*******************
	* Apro il file
	*******************/
	//rc = Apri_File(acFileSoglie_Loc, &handle, 1, 2);
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error MbeFileOpen_nw file[%s] : %d",gUtente, gIP, acFileSoglie_Loc, rc);
		sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
		Display_Message(0, "", sTmp);
		LOGResult = SLOG_ERROR;
		return;
	}

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileSoglie_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			Display_TOP("");

			printf("<FORM METHOD=POST ACTION='%s' NAME='Download'>\n", gName_cgi);
			printf("<INPUT TYPE='hidden' name='OPERATION' value='DOWNLOAD' >\n");

			printf("<class id='img_download'>\n");
			printf("<IMG SRC='images/downloadnow.gif' BORDER=0 ALT='Download rules steering threshold list' onclick=\"javascript:document.Download.submit();\">");
			printf( "</class>\n	");
			printf("</form>\n");

			printf("<center>");
			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Threshold' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR >\n");
			printf("  <TH><strong>&nbsp;Country / Country Group</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Operator / Operator Group</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Time from</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Time to</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Days</strong></TH>\n");
			printf("  <TH><strong>&nbsp;User types</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Status</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Weight</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Threshold (%%)</strong></TH>\n");
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
				rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileSoglie_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);

						printf("</TABLE>\n");
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// non visualizzo il record con key '*'
					if (memcmp(record_soglie.gr_pa, "********************", 20))
					{
						/***************************
						* Scrive il record a video
						****************************/
						memset(sTmp, 0, sizeof(sTmp));
						memset(acKeydecod, 0, sizeof(acKeydecod));
						memset(acKey, ' ', sizeof(acKey));
						memcpy(sTmp, record_soglie.gr_pa, LEN_KEY_SOGLIE);
						memcpy(acKeydecod, record_soglie.gr_pa, LEN_KEY_SOGLIE - 4);
						SistemaApice(acKey, sTmp);
						CambiaCar(acKeydecod);

						memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);

						// (link) viene disbilitato sul cancella
						printf("<TR class='gradeGreen' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&KEY=%s&USERS=%08X'\">\n",gName_cgi, acKeydecod, user_type_bitmask);
						fflush(stdout);
						printf("  <TD onclick='link = true'>&nbsp;%.*s</a></TD>\n",LEN_GRP, record_soglie.gr_pa);
						printf("  <TD onclick='link = true'>&nbsp;%.*s</TD>\n", LEN_GRP, record_soglie.gr_op);
						printf("  <TD onclick='link = true'>&nbsp;%.5s</TD>\n", record_soglie.fascia_da);
						printf("  <TD onclick='link = true'>&nbsp;%.5s</TD>\n", record_soglie.fascia_a);
						fflush(stdout);
						// gg settimana in Rosso è il gg inserito (peer cui il profilo è valido)
						printf("  <TD onclick='link = true'>&nbsp;");
						if( record_soglie.gg_settimana[1] == 'X' )
							printf("<font color=red >M </font>");
						else
							printf("M ");
						if( record_soglie.gg_settimana[2] == 'X' )
							printf("<font color=red >T </font>");
						else
							printf("T ");
						if( record_soglie.gg_settimana[3] == 'X' )
							printf("<font color=red >W </font>");
						else
							printf("W ");
						if( record_soglie.gg_settimana[4] == 'X' )
							printf("<font color=red >T </font>");
						else
							printf("T ");
						if( record_soglie.gg_settimana[5] == 'X' )
							printf("<font color=red >F </font>");
						else
							printf("F ");
						if( record_soglie.gg_settimana[6] == 'X' )
							printf("<font color=red >S </font>");
						else
							printf("S ");
						if( record_soglie.gg_settimana[0] == 'X' )
							printf("<font color=red >S </font>");
						else
							printf("S ");
						printf("</TD>\n");
						fflush(stdout);

						printf("  <TD onclick='link = true'>&nbsp;%08X</a></TD>\n", user_type_bitmask);

						printf("  <TD onclick='link = true'>&nbsp;%s</TD>\n"  , (record_soglie.stato == '1' ? "On" : "Off") );
						if(record_soglie.peso != ' ' )
							printf("  <TD onclick='link = true'>&nbsp;%d</TD>\n"  , record_soglie.peso);
						else
							printf("  <TD onclick='link = true'>&nbsp;0</TD>\n");
						printf("  <TD onclick='link = true'>&nbsp;%d</TD>\n"  , record_soglie.soglia);
						fflush(stdout);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&KEY=%s&USERS=%08X', 'Steering threshold: %.128s');\" title='Delete'>",
								gName_cgi, acKeydecod, user_type_bitmask,
								acKey);

						//printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");
						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
						fflush(stdout);

						lRecord ++;
					}
				}
			}/* while (1) */

			printf("</tbody>");
			printf("</TABLE>\n");
			printf("</div>");
			printf("<BR>\n");
			printf("<BR>\n");

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Threshold' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);


			printf("</CENTER>\n");

			// inserimento delle finestre di dialogo
			printf("<script>\n");
			printf("    insert_Confirm_Delete();\n");
			printf("</script>\n");

			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d",gUtente, gIP, acFileSoglie_Loc, rc);

	return;
}

//*************************************************************************************************
void Maschera_Modifica(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	short		handle = -1;
	short		rc = 0;
	char		sTipo[20];
	char		acKeydecod[200];
	int			i = 0;
	int			user_type_bitmask = 0;
	short		res;
	long 		lTotRic = 0;
	long		lTotAc = 0;

	t_ts_soglie_record record_soglie;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));

	memset(sTmp, 0, sizeof(sTmp));
	record_soglie.soglia = 0;

	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_soglie.gr_pa, wrk_str, strlen(wrk_str));
	if (( (wrk_str = cgi_param( "USERS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		sscanf(wrk_str, "%X", record_soglie.user_type );

	/*******************
	* Apro il file
	*******************/
	//rc = Apri_File(acFileSoglie_Loc, &handle, 1, 2);
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) MbeFileOpen_nw file[%s]", rc, acFileSoglie_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return;
	}

	if (rc == 0 && tipo == UPD)
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "Key=%.149s", record_soglie.gr_pa);
		strcpy(log_spooler.TipoRichiesta, "VIEW");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		/********************************
		* Cerco il record del db LOCALE
		***********************************/
		rc = MBE_FILE_SETKEY_( handle, record_soglie.gr_pa, LEN_KEY_SOGLIE, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file[%s]", rc, acFileSoglie_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			//rc = MBE_READX( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading file[%s]", rc, acFileSoglie_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				LOGResult = SLOG_ERROR;
			}
			else
				scrivoLog_Soglie(record_soglie, "ViewTR");

		}
		MBE_FILE_CLOSE_(handle);

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}			
		
	if(rc == 0 )
	{
		if (tipo == UPD)
		{
			sprintf(sTmp, "THRESHOLDS DEFINITION - Modify");
			strcpy(sTipo, "Modify");
		}
		else
		{
			sprintf(sTmp, "THRESHOLDS DEFINITION - New record");
			strcpy(sTipo, "Insert");

		}

		Display_TOP(sTmp);

		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<fieldset><legend>Define Steering rules&nbsp;</legend>\n");

		printf("<form method='POST' action='%s' name='inputform' onsubmit=\"return CheckSoglie('%s')\">\n", gName_cgi, sTipo);
		printf("<TABLE width = 100%% cellspacing=10 cellborder=10 border=0>\n");
		fflush(stdout);

		//-------------------- key  inserimento--------------------
		if(tipo == INS)
		{
			rc = Lista_Operatori();
			if (rc == 0)
				rc= Lista_GRPOperatori();
			if (rc != 0)
				return;
			rc= Lista_GRPaesi();
			if (rc != 0)
				return;

			printf("<INPUT TYPE='hidden' name='GR_PA' value='' >\n");
			printf("<INPUT TYPE='hidden' name='GR_OP' value='' >\n");

			printf("<TR>");
			printf("<td colspan=8>\n\
					<fieldset><legend>Country/Operator or Groups &nbsp;</legend>\n");

			printf("<CENTER>");
			printf("<TABLE width ='90%%' cellspacing=10 border=0>\n\
					<TR>\n");

			printf("<td align='right' class='testo'>Country:&nbsp;</td>\n\
				   <td align='left'>\n\
				   <select name='countrySelect' STYLE='width: 380px'  id='cc_co' class='chosen-select'  onChange=\"setMNC(selectedIndex); abilita_campi(0)\"></select>\n\
					</td>\n");
			printf("<td align='right'>Group Countries:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='GroupPASelect' STYLE='width: 380px' id='grp' class='chosen-select'  onChange=\"abilita_campi(1)\"></select>\n\
					</td>\n");
			printf("</tr><tr>\n");
			printf("<td align='right' >Operators:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='operatorSelect' STYLE='width: 380px'  id='cc_co' class='noSearch'  ></select>\n\
					</td>\n");
			printf("<td align='right' colspan=1>Group Operators:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='GroupOPSelect' STYLE='width: 380px' id='grp2' class='chosen-select'  onChange=\"abilita_campi(1)\"></select>\n\
					</td>\n");
			printf("</tr><tr>\n\
					<TD><input TYPE='hidden' name='fOperator'  value='' >\n\
						</td>\n");
		
			printf("<script> setMCC(); setMNC(0); setGRPOP(); setGRPPA();</script>");

			printf("</tr></<fieldset></table></td>\n");

			//--------------------- fine  list --------------------------
			
			printf("</tr><tr>\n");
			printf("<td width='25%%'>&nbsp;</td>\n");
			printf("</tr><tr>\n");

			printf("<TD align=right><b>Time from:</b></TD>\n");
			printf("<TD colspan=2>\n\
				   <input type='text' name='FASCIA_DA' size='8' MAXLENGTH=5 VALUE='00:00' class='onlytimepic'> (HH:MM)</td>");
			printf("<TD id=lbl10r><b>Time to:</b></TD>\n");
			printf("<TD align=left colspan=3>\n\
				   <input type='text' name='FASCIA_A' size='8' MAXLENGTH=5 VALUE='23:59'  class='onlytimepic'> (HH:MM)</td>");
			printf("</tr><tr>\n");

			printf("<TD align=right><b>Days:</b></TD>\n");
			printf("<TD align=left colspan=7>\n\
					Monday<INPUT TYPE='checkbox'    checked NAME='LUN' >&nbsp;&nbsp;");
			printf("Tuesday<INPUT TYPE='checkbox'   checked NAME='MAR' >&nbsp;&nbsp;");
			printf("Wednesday<INPUT TYPE='checkbox' checked NAME='MER' >&nbsp;&nbsp;");
			printf("Thursday<INPUT TYPE='checkbox'  checked NAME='GIO' >&nbsp;&nbsp;");
			printf("Friday<INPUT TYPE='checkbox'    checked NAME='VEN' >&nbsp;&nbsp;");
			printf("Saturday<INPUT TYPE='checkbox'  checked NAME='SAB' >&nbsp;&nbsp;");
			printf("Sunday<INPUT TYPE='checkbox'    checked NAME='DOM' >");
			
            printf("</TD>\n");
			printf("</tr><tr>\n");
			// ************   gestione Utenti *********************
			printf("<TD align=right><b>User types:</b></TD>\n");
			printf("<TD colspan='7' align=left>");

			sscanf(ac_hexdefuser, "%X", record_soglie.user_type );
			trovauser(record_soglie.user_type, " ");

			printf("</TD>\n");
			printf("</TR>\n");
			// ************   gestione Utenti *********************
		}
		else
		{
			//-------------------- key  modifica--------------------
			printf("<TR>");
			printf("<TD align=right><b>Operator / Operator group:</b></TD>\n");
			printf("<TD align=left colspan='7'>%.*s</TD>\n", LEN_GRP, record_soglie.gr_op);
			printf("</tr><tr>\n");

			printf("<TD align=right><b>Country / Country group:</b></TD>\n");
			printf("<TD align=left colspan=7 >%.*s</TD>\n",LEN_GRP,  record_soglie.gr_pa);
			printf("</tr><tr>\n");

			printf("<TD align=right><b>Time from:</b></TD>\n");
			printf("<TD id=lbl5l>%.5s</TD>\n", record_soglie.fascia_da);
			printf("<TD id=lbl10r><b>Time to:</b></TD>\n");
			printf("<TD align=left>%.5s</TD>\n", record_soglie.fascia_a);
			printf("</tr><tr>\n");

			printf("<TD align=right><b>Days:</b></TD>\n");
			printf("<TD align=left colspan=7>\n\
					Monday<INPUT TYPE='checkbox' NAME='LUN' disabled");
			if (record_soglie.gg_settimana[1] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Tuesday<INPUT TYPE='checkbox' NAME='MAR' disabled");
			if (record_soglie.gg_settimana[2] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Wednesday<INPUT TYPE='checkbox' NAME='MER' disabled");
			if (record_soglie.gg_settimana[3] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Thursday<INPUT TYPE='checkbox' NAME='GIO' disabled");
			if (record_soglie.gg_settimana[4] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Friday<INPUT TYPE='checkbox' NAME='VEN' disabled");
			if (record_soglie.gg_settimana[5] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Saturday<INPUT TYPE='checkbox' NAME='SAB' disabled");
			if (record_soglie.gg_settimana[6] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Sunday<INPUT TYPE='checkbox' NAME='DOM' disabled");
			if (record_soglie.gg_settimana[0] == 'X')
				printf(" checked ");
			printf(">\n");
			
			printf("</TD>\n");
			printf("<tr>\n");

			// ************   gestione Utenti *********************
			printf("<TD align=right><b>User types:</b></TD>\n");
			printf("<TD colspan='7' align=left>");
			trovauser(record_soglie.user_type, "disabled");
			printf("</TD>\n");

			printf("</tr>\n");
			printf("<tr><td colspan='8'><hr id='hrBlue'></td></tr>\n");
		}
		if(rc > 0  )
			return;

		printf("<TR>");
		printf("<TD align=right><b>Status:</b></TD>\n");
		printf("<TD align=left><SELECT NAME='STATO'  class='noSearch'  style='width:60px'>\n\
				<option value='1'>On</option>\n\
				<option value='0' ");
		if(record_soglie.stato == '0')
			printf("selected ");
		printf(">Off</option>\n\
				</select>\n");
		printf("</TD>\n");

		printf("<TD align=right><b>Threshold (%%):</b></TD>\n");
		printf("<TD align=left>\n\
			   <input type='text' name='SOGLIA' size='5' MAXLENGTH=3 VALUE=%d class='numeric'></td> ", record_soglie.soglia);


		//******************** Peso e politica **********************************
		//sono char ma devono essere gestiti come num
		printf("<TD align=right><b>Weight:</b></TD>\n");
		printf("<TD align=left>\n\
				<SELECT NAME='PESO'  class='noSearch'  style='width:60px'>\n\
				<option value= 0 > 0</option>\n");
		for(i=1; i < 16; i++)
		{
			printf("<option value= %d ", i);
			if(record_soglie.peso == i)
				printf("selected ");
			printf("> %d</option>\n", i);
		}
		printf("</select></td>\n");

		printf("<TD align=right><b>Politics:</b></TD>\n");
		printf("<TD align=left><SELECT NAME='POLITICA'  class='noSearch'  style='width:220px'>\n\
				<option value= 1>guaranteed primary threshold</option>\n\
				<option value= 2 ");
		if(record_soglie.politica == 2)
			printf("selected ");
		printf(">optimized secondary threshold</option>\n\
				</select>\n");
		printf("</TD>\n");

		printf("</TR>\n");


		// ******************  liste PPLMN  **********************************
		/*printf("<TD width=10%% align=right><b>PPLMN1: </b></TD>\n\
				<TD width=10%% align=left><SELECT NAME='PPLMN1'\">\n");
		
		printf( "<option  value=''>&nbsp;</option>");

		//content id == 1
		ListaPLMN( 1 , record_soglie.pplmn1);
		printf("</select></TD>\n");

		printf("<TD width=10%% align=right><b>PPLMN2: </b></TD>\n\
				<TD width=10%% align=left><SELECT NAME='PPLMN2'\">\n");

		printf( "<option  value=''>&nbsp;</option>");
		ListaPLMN( 1 , record_soglie.pplmn2);
		printf("</select></TD>\n");
		printf("</tr><tr>\n");*/

		//*******************************************************************
		if(tipo == UPD)
		{
			printf("<TR>");
			printf("<TD>&nbsp;</td></TR><TR>");
			printf("<TD align=right><b>Local Tot Acc Pref:</b></TD>\n");
			printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accP[0]);
			
			printf("<TD align=right colspan=2><b>Local Tot Acc:</b></TD>\n");
			printf("<TD align=right >%ld</TD>\n", record_soglie.tot_accT[0]);
			
			res = 0;
			if ( record_soglie.tot_accP[0] > 0 && record_soglie.tot_accT[0] > 0 )
				res = (short)((record_soglie.tot_accP[0] *100) / record_soglie.tot_accT[0]);

			printf("<TD>&nbsp;%d%%</TD>\n", res);
			
			printf("</tr><tr>\n");
			printf("<TD align=right><b>Remote Tot Acc Pref:</b></TD>\n");
			printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accP[1]);
			
			printf("<TD align=right colspan=2><b>Remote Tot Acc:</b></TD>\n");
			printf("<TD align=right >%ld</TD>\n", record_soglie.tot_accT[1]);
			
			res = 0;
			if ( record_soglie.tot_accP[1] > 0 && record_soglie.tot_accT[1] > 0 )
				res = (short)((record_soglie.tot_accP[1] *100) / record_soglie.tot_accT[1]);

			printf("<TD>&nbsp;%d%%</TD>\n", res);

			// somma dei due dati
			printf("</tr><tr>\n");
			printf("<TD align=right><b>Total:</b></TD>\n");
			lTotAc = record_soglie.tot_accP[0] + record_soglie.tot_accP[1];
			printf("<TD align=right>%ld</TD>\n", lTotAc);
			
			printf("<TD align=right colspan=2><b>&nbsp;</b></TD>\n");
			lTotRic = record_soglie.tot_accT[0] + record_soglie.tot_accT[1];
			printf("<TD align=right >%ld</TD>\n", lTotRic);
			
			res = 0;
			if ( lTotAc > 0 && lTotRic > 0 )
				res = (short)((lTotAc *100) / lTotRic);

			printf("<TD>&nbsp;%d%%</TD>\n", res);
			printf("</TR>\n");

		}

		printf("</TABLE></center></fieldset>\n" );
		fflush(stdout);

		printf("<BR>");
		printf("<BR>");
		printf("<CENTER>\n");

		if(tipo == UPD )
		{
			memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);

			printf("<INPUT TYPE='hidden' name='KEY' value=\"%.*s\" >\n", (LEN_KEY_SOGLIE -4) , record_soglie.gr_pa);
			printf("<INPUT TYPE='hidden' name='USERS' value=\"%08X\" >\n", user_type_bitmask);
		}

		printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='Return To List' \
			    onclick=\"Javascript:location='%s'\" >\n", gName_cgi);

		printf("<input type='submit'   icon='ui-icon-check' value='%s' name='OPERATION' >\n", sTipo );

		if(tipo == UPD && record_soglie.soglia > 0 && record_soglie.stato == '1')
		{
			memset(acKeydecod, 0, sizeof(acKeydecod));
			memcpy(acKeydecod, record_soglie.gr_pa, LEN_GRP);
			CambiaCar(acKeydecod);
			printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n\
					<A HREF=\"%s?OPERATION=LISTA&KEY=%s\" target='_blank'>\n",
					gName_cgi, acKeydecod);
			printf("<IMG SRC='images/info.gif'  BORDER=0 ALT='Info Threshold' \
					></TD></A>\n");
		}
		printf("</CENTER></form>\n\
				");
		Display_BOTTOM();
	}
}
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;
	long long	lJTS = 0;

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_soglie_rem;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));

	record_soglie.soglia = 0;
	record_soglie_rem.soglia = 0;

	memset(sTmp, 0, sizeof(sTmp));

	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_soglie.gr_pa, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "USERS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		sscanf(wrk_str, "%X", record_soglie.user_type );

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Key=%.149s",record_soglie.gr_pa);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/***********************************************************************************
	* IPM KTSTEACS
	* Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
	************************************************************************************/
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) MbeFileOpen_nw file[%s]", rc, acFileSoglie_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return;
	}
	else
	{
		// ************** Apro file REMOTO ************************************
		rc = MbeFileOpen_nw(acFileSoglie_Rem, &handle_rem);
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) MbeFileOpen_nw remote file[%s]", rc, acFileSoglie_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			return;
		}
	}

	if (rc == 0 && tipo == 0)  //modifica
	{
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle,  record_soglie.gr_pa, LEN_KEY_SOGLIE, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file[%s]", rc, acFileSoglie_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_FILE_SETKEY_( handle_rem,  record_soglie.gr_pa, LEN_KEY_SOGLIE, 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey remote file[%s]", rc, acFileSoglie_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}

		if(rc == 0)
		{
			rc = MbeFileReadL_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading local file[%s]", rc, acFileSoglie_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				// DB REMOTO
				rc = MbeFileReadL_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in reading remote file[%s]", rc, acFileSoglie_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					//MBE_UNLOCKREC(handle);
					MbeUnlockRec_nw(handle);
				}
			}
			if(rc == 0)
			{
				//***************** aggiorno il record con i dati modificati *****************
				Lettura_Variabili(&record_soglie);

				rc = MbeFileWriteUU_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating local file[%s]", rc, acFileSoglie_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MbeUnlockRec_nw(handle);
					MbeUnlockRec_nw(handle_rem);
				}
				else
				{
                    //Aggiornata soglia scrivo Log
					scrivoLog_Soglie(record_soglie, "UpdTR");
				}
				if(rc == 0)
				{
					// *******  aggiornamento DB REMOTO
					rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating remote file[%s]", rc, acFileSoglie_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MbeUnlockRec_nw(handle_rem);
					}
				}
			}

		}
	}
	//---------------------------------- INSERIMENTO ---------------------------------------
	if (rc == 0 && tipo == 1)
	{
		short i= 0;
		char acVarUser[100];
		int  user_type_bitmask;
		int  user_type_add = 0;
		int  iRes = 0;


		record_soglie.tot_accP[0] = 0;
		record_soglie.tot_accP[1] = 0;
		record_soglie.tot_accT[0] = 0;
		record_soglie.tot_accT[1] = 0;
	
		Lettura_Variabili(&record_soglie);

		strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL
		sprintf(log_spooler.ParametriRichiesta, "Key=%.149s",record_soglie.gr_pa);  // ParametriRichiesta[300]

		user_type_bitmask = 0;
		memset(record_soglie.user_type, 0X00, sizeof(record_soglie.user_type));
		for(i = 0; i < 32; i++)
		{
			sprintf(acVarUser, "USERS_TYPE_%d", i);
			if (( (wrk_str = cgi_param(acVarUser) ) != NULL ) && (strlen(wrk_str) > 0))
			{
				user_type_add = 1<<i;
				user_type_bitmask += user_type_add;
				memcpy(record_soglie.user_type, (char *) &user_type_bitmask, sizeof(record_soglie.user_type));
			}
		}

		rc = Controlla_Dati(&record_soglie, handle, &iRes);
		if (rc == 0 )
		{
			rc = MbeFileWrite_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore */         
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Error (%d) in writing local file[%s]: KEY already exist", rc, acFileSoglie_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing local file[%s]", rc, acFileSoglie_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				// ************ inserita soglia scrivo Log
				scrivoLog_Soglie(record_soglie, "InsTR");
			
				// ********************* INSERISCO RECORD NEL DB REMOTO
				rc = MbeFileWrite_nw( handle_rem, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore */         
				if (rc)
				{
					if (rc == 10 )
					{
						sprintf(sTmp, "Error (%d) in writing remote file[%s]: KEY already exist", rc, acFileSoglie_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
					{
						sprintf(sTmp, "Error (%d) in writing remote file[%s]", rc, acFileSoglie_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
				}
			}
		}
	/*	else if (rc == 9 )
		{
			sprintf(sTmp, "Error: Threshold overlap in Time or Days" );
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);

			Display_Message(1, "", sTmp, 0);
		}*/
		else if (rc == 99 )
		{
			sprintf(sTmp, "Error:  Threshold overlap in Time or Days and User type already used in another Threshold. User type:" );
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);

			/****************************************/
			user_type_bitmask = 1;
			i = 0;

			while (i < 32)
			{
				 if (iRes & user_type_bitmask)
					 sprintf(sTmp+strlen(sTmp), " [%d]", i);

				 i++;
				 iRes >>= 1;
			}

			Display_Message(1, "", sTmp);
		}
	}

	// aggiorno il record con key riempita ad '*' 
	if (rc == 0)
	{
		//GMT
		GetTimeStamp(&lJTS);
		rc = Aggiorna_Soglie_rec_Aster(handle, handle_rem, lJTS, 0);
	}	
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------------------*/
	/* LOG SICUREZZA solo per db rules      	*/
	/*------------------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	if (rc == 0)
	{
		Display_File();
	}
}
/* --------------------------------------------------------------------------*/
//tipo == 0   cancellazione da web
/* --------------------------------------------------------------------------*/
void Delete_Dati(short tipo)
{
	char		*wrk_str;
	short		handle = -1;
	short		handle_rem = -1;
	char		sTmp[500];
	int			rc = 0;
	long long	lJTS = 0;
	t_ts_soglie_record record_appo;

	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_soglie_record));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/
	memset(sTmp, 0, sizeof(sTmp));

	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_appo.gr_pa, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "USERS" ) ) != NULL ) && (strlen(wrk_str) > 0))
			sscanf(wrk_str, "%X", record_appo.user_type );

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Key=%.149s",record_appo.gr_pa);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/***********************************************************************************
	* IPM KTSTEACS
	* Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
	************************************************************************************/
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error MbeFileOpen_nw file[%s] : %d",gUtente, gIP, acFileSoglie_Loc, rc);
		sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
		Display_Message(1, "", sTmp);
	}
	else
	{
		// ************** Apro file REMOTO ************************************
		rc = MbeFileOpen_nw(acFileSoglie_Rem, &handle_rem);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error MbeFileOpen_nw file[%s] : %d",gUtente, gIP, acFileSoglie_Rem, rc);
			sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Rem, rc);
			Display_Message(1, "", sTmp);
		}
	}
	
	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, record_appo.gr_pa, LEN_KEY_SOGLIE, 0, EXACT);
		rc = MBE_FILE_SETKEY_( handle_rem, record_appo.gr_pa, LEN_KEY_SOGLIE, 0, EXACT);

		if (rc == 0)
		{
			/************************
			* Leggo il record locale
			************************/
			rc = MbeFileReadL_nw( handle, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
			if ( rc)//errore
			{
				sprintf(sTmp, "Error (%d) in reading local file [%s]", rc, acFileSoglie_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{	//leggo record remoto
				rc = MbeFileReadL_nw( handle_rem, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
				if ( rc)//errore
				{
					sprintf(sTmp, "Error (%d) in reading remote file [%s]", rc, acFileSoglie_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					MbeUnlockRec_nw(handle);
					Display_Message(1, "", sTmp);
				}
			}
			/* trovato lo cancello */
			if ( rc == 0 )
			{
				rc = MbeFileWriteUU_nw( handle, (char *) &record_appo, 0 );
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in deleting local file [%s]", rc, acFileSoglie_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					MbeUnlockRec_nw(handle);
					MbeUnlockRec_nw(handle_rem);
					Display_Message(1, "", sTmp);
				}
				else
				{
					//Cancellata soglia scrivo Log
					scrivoLog_Soglie(record_appo, "DelTR");

					//------ CANCELLO RECORD NEL DB REMOTO ---------------
					rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_appo, 0 );
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in deleting remote file [%s]", rc, acFileSoglie_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						MbeUnlockRec_nw(handle_rem);
						Display_Message(1, "", sTmp);
					}
					//??????????????? se va male cancellazione remoto ????????
					rc = 0;
				}
			}
		}
		else
		{
			sprintf(sTmp, "Error (%d) File_setkey (Threshold Loc/Rem)", rc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
	}
	// aggiorno il record con key riempita ad '*'
	if (rc == 0)
	{
		//GMT
		GetTimeStamp(&lJTS);
		rc = Aggiorna_Soglie_rec_Aster(handle, handle_rem, lJTS, 0);
	}
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------------------*/
	/* LOG SICUREZZA solo per db rules      	*/
	/*------------------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	if (rc == 0 && tipo == 0)
		Display_File();

}
//***************************************************************************
void Lettura_Variabili(t_ts_soglie_record *record_soglie)
{
	char	*wrk_str;
	char	*pTmp2;
	char	sTmp[500];

	memset(sTmp, 0 , sizeof(sTmp));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	if (( (wrk_str = cgi_param( "GR_PA" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		//ci sono casi che ci sono spazi avanti 
		//quando nei paesi c'è l'apice
		pTmp2 = AlltrimString(wrk_str);
		memcpy(record_soglie->gr_pa, pTmp2, strlen(pTmp2));
	}
	if (( (wrk_str = cgi_param( "GR_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(record_soglie->gr_op, wrk_str, strlen(wrk_str));
	}
	if (( (wrk_str = cgi_param( "FASCIA_DA" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_soglie->fascia_da, wrk_str, strlen(wrk_str));
	if (( (wrk_str = cgi_param( "FASCIA_A" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_soglie->fascia_a, wrk_str, strlen(wrk_str));
	//  -------------- GG SETTIMANA -------------
	if (( (wrk_str = cgi_param( "LUN" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[1] = 'X';
	if (( (wrk_str = cgi_param( "MAR" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[2] = 'X';
	if (( (wrk_str = cgi_param( "MER" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[3] = 'X';
	if (( (wrk_str = cgi_param( "GIO" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[4] = 'X';
	if (( (wrk_str = cgi_param( "VEN" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[5] = 'X';
	if (( (wrk_str = cgi_param( "SAB" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[6] = 'X';
	if (( (wrk_str = cgi_param( "DOM" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_soglie->gg_settimana[0] = 'X';
	//------------------------------------------------
	if (( (wrk_str = cgi_param( "STATO" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_soglie->stato = wrk_str[0];
	if (( (wrk_str = cgi_param( "SOGLIA" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_soglie->soglia = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "PESO" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		record_soglie->peso = (char) atoi(wrk_str);
	}
	if (( (wrk_str = cgi_param( "POLITICA" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_soglie->politica =  (char) atoi(wrk_str);
	
/*	record_soglie->pplmn1 = 8224;
	if (( (wrk_str = cgi_param( "PPLMN1" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_soglie->pplmn1 = (short) atoi(wrk_str);
	record_soglie->pplmn2 = 8224;
	if (( (wrk_str = cgi_param( "PPLMN2" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_soglie->pplmn2 = (short) atoi(wrk_str);*/

}
//-------------------------------------------------------------------------------
// tipo = 0 caricamento lista
// tipo = 1 controllo se c'è codice operatore. Se c'è la % soglie accetta 0
//-------------------------------------------------------------------------------
short Lista_GRPOperatori()
{
	short		handle2 = -1;
	short		rc = 0;
	short		is_AltKey;
	char		ac_Chiave[LEN_GRP];
	char		sTmp[500];
	char		acGruppo[LEN_GRP+1];

	t_ts_oper_record record_gruppoOp;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));

	/********************************
	* Apro il file gruppo operatori
	*********************************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acGruppo,   'x', 5);

	if (rc == 0)
	{
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), is_AltKey, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			printf("	<!-- carica array con gli operatori -->");
			printf("<script language='JavaScript'>\n");
			printf("var aGROperatori = new Array(\n\
						new Option(\"(select a Operators Group )\",'ALL')\n\
					");
			fflush(stdout);

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle2, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);

						//chiudi la parentesy dell'array
						printf( ");\n</script>\n" );
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// se non è rec con * e gruppo non è vuoto
					if( (memcmp(record_gruppoOp.paese, "***********", 8)) && (memcmp(record_gruppoOp.gruppo_op, "                ", 10)) )
					{
						if(memcmp(acGruppo, record_gruppoOp.gruppo_op, sizeof(record_gruppoOp.gruppo_op)) )
						{
							printf( ",   new Option(\"%.*s\",\"%.*s\")\n", LEN_GRP, record_gruppoOp.gruppo_op, LEN_GRP, record_gruppoOp.gruppo_op );

							// salvo il gruppo
							memcpy(acGruppo, record_gruppoOp.gruppo_op, sizeof(record_gruppoOp.gruppo_op));
						}
					}
				}
			}/* while (1) */

			//chiudi la parentesy dell'array
			printf( ");\n</script>\n" );
			fflush(stdout);

		}
		MBE_FILE_CLOSE_(handle2);
	}

	return(rc);	
}

//-------------------------------------------------------------------------------
short Lista_GRPaesi()
{
	short		handle2 = -1;
	short		rc = 0;
	char		ac_Chiave[LEN_GRP];
	char		sTmp[500];
	char		acGruppo[LEN_GRP+1];
	short		is_AltKey;

	t_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(acGruppo,   'x', 5);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle2, 1, 1);

	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;

		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), is_AltKey, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  file [%s]", rc, acFilePaesi_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			printf("	<!-- caricamento liste -->");
			printf("<script language='JavaScript'>\n");
			printf("var aGRPaesi = new Array(\n\
						new Option(\"(select a Country Group )\",'ALL')\n\
					");
			fflush(stdout);

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle2, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading  file [%s]", rc, acFilePaesi_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						//chiudi la parentesy dell'array
						printf( ");\n</script>\n" );
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
				//	if (memcmp(record_paesi.gr_pa, "                              ", 30))
					if( (memcmp(record_paesi.paese, "***********", 8)) && (memcmp(record_paesi.gr_pa, "                ", 10)) )
					{
						if(memcmp(acGruppo, record_paesi.gr_pa, sizeof(record_paesi.gr_pa)) )
						{
							printf( ",   new Option(\"%.*s\",\"%.*s\")\n", LEN_GRP, record_paesi.gr_pa, LEN_GRP, record_paesi.gr_pa);
							// salvo il gruppo  
							memcpy(acGruppo, record_paesi.gr_pa, sizeof(record_paesi.gr_pa));
						}
					}
				}
			}/* while (1) */

			//chiudi la parentesy dell'array
			printf( ");\n</script>\n" );
			fflush(stdout);

		}
		MBE_FILE_CLOSE_(handle2);
	}

	return(rc);	
}
//*****************************************************************************************
// cerco per key = GR_PA + GR_OP  gli altri campi li controllo per non avere accavallamenti
//*****************************************************************************************
short Controlla_Dati(t_ts_soglie_record *record_soglie, short handle, int *iRes )
{
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP+LEN_GRP];
	short		rc = 0;
	short		ggOK, i;
	short		oraOK;	
	int			user_type_bitmask_soglie;
	int			user_type_bitmask_appo;

	t_ts_soglie_record record_appo;

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
		
	memcpy((char *)&user_type_bitmask_soglie, record_soglie->user_type, 4);


	memcpy(ac_Chiave, record_soglie->gr_pa, sizeof(record_soglie->gr_pa));
	memcpy(ac_Chiave+sizeof(record_soglie->gr_pa), record_soglie->gr_op, sizeof(record_soglie->gr_op));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, GENERIC);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey  file [%s]", rc, acFileSoglie_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		while ( 1)
		{
			/*******************
			* Leggo i record
			*******************/
			rc = MbeFileRead_nw( handle, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if ( rc)
			{
				if (rc == 1)/* fine file */
					rc = 0;
				else
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileSoglie_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1,"", sTmp);
				}
				break;
			}
			else
			{
				ggOK  = 1;
				oraOK = 0;	

				//controllo l'orario 
				//fasciaDA inserita deve essere max fasciaA e min fasciaDA
				//fasciaA inserita deve essere max  fasciaA e min fasciaDA
				if ( (HHMM2TS(record_soglie->fascia_da) > HHMM2TS(record_appo.fascia_a) ||
				      HHMM2TS(record_soglie->fascia_da) < HHMM2TS(record_appo.fascia_da) ) 
				 &&
				     (HHMM2TS(record_soglie->fascia_a) > HHMM2TS(record_appo.fascia_a) ||
				      HHMM2TS(record_soglie->fascia_a) < HHMM2TS(record_appo.fascia_da) ) 
				   )
				{
					oraOK = 1;	
				}
				else
				{
					//controllo i giorni della settimana
					for(i = 0; i <= 6 && ggOK; i++)
					{
						if(record_soglie->gg_settimana[i] == 'X' &&
						   record_appo.gg_settimana[i]   == 'X')
						{
							ggOK = 0;
						}
					}
					// se oraOK == 0 &&  ggOK == 1  ->OK
					// se oraOK == 0 &&  ggOK == 0  ->KO
					if( oraOK == 0 &&  ggOK == 0 )
					{
						// dati uguali
						// controllo  utenti
						memcpy((char *)&user_type_bitmask_appo, record_appo.user_type, 4);
						memcpy((char *)&user_type_bitmask_soglie, record_soglie->user_type, 4);

						// se  in entrambi c'è lo stesso bit alzato errore
						*iRes = user_type_bitmask_appo & user_type_bitmask_soglie;
						if( *iRes )
							rc = 99;
						break;
					}
				}
			}

		} // fine while
	}

	return(rc);
}

// *****************************************************************************************
//  viene caricata una pagina csv  Content-type: text/csv
// in questo modo non viene creato nessun file su oss/guadian.
// è il browser che crea il csv.  Content-Disposition: attachment; filename=Steering-rules.csv
// *****************************************************************************************
void Prepara_Download()
{

	short		handle = -1;
	char		sTmp[500];
	char		buf_DownLoad[200000];
	char		ac_Chiave[LEN_KEY_SOGLIE];
	char		acGiorni[10];
	short		rc = 0;
	char		acOperatore[200];
	char		*pDenOP;
	char		*ptrGR_PA;
	char		*ptrGR_OP;
	char		chiave[LEN_GRP+1];
	char		acGr_Pa[LEN_GRP+1];

	t_ts_soglie_record record_soglie;

	//setlocale(LC_ALL, "en_US.UTF-8");

	//Creare le liste:
	listaOPs = avlMake();
	listaGR_OPs = avlMake();
	listaGR_PAs = avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(buf_DownLoad, 0, sizeof(buf_DownLoad));
	
	/***********************************
	* Apro i file 
	************************************/
	//rc = Apri_File(acFileSoglie_Loc, &handle, 1, 2);
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) in opening local file [%s]", rc, acFileSoglie_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return;
	}

	if (rc == 0)
		rc = Carica_Op_Soglie();

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey local file [%s]", rc, acFileSoglie_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			return;
		}
		/* tutto ok */
		else
		{
			//scrittura caratteri BOM per indicare a exel il formato UTF8
			sprintf(buf_DownLoad,"%c%c%c", 0xEF, 0xBB, 0xBF);
			sprintf(buf_DownLoad+strlen(buf_DownLoad),"Country / Country Group;Operator / Operator Group;Time from;Time to;Days;Status;Weight;Politic;Threshold (%%)\n");

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				//rc = MBE_READX( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );

				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading local file [%s]", rc, acFileSoglie_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						return;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// non visualizzo il record con key '*'
					if (memcmp(record_soglie.gr_pa, "********************", 20))
					{
						// preparo i gg settimana
						// MAIUSCOLO è il gg inserito (per cui il profilo è valido)
						// Minuscolo gg non attivo
						strcpy(acGiorni, "mtwtfss");
						if( record_soglie.gg_settimana[1] == 'X' )
							acGiorni[0] = 'M';
						if( record_soglie.gg_settimana[2] == 'X' )
							acGiorni[1] = 'T';
						if( record_soglie.gg_settimana[3] == 'X' )
							acGiorni[2] = 'W';
						if( record_soglie.gg_settimana[4] == 'X' )
							acGiorni[3] = 'T';
						if( record_soglie.gg_settimana[5] == 'X' )
							acGiorni[4] = 'F';
						if( record_soglie.gg_settimana[6] == 'X' )
							acGiorni[5] = 'S';
						if( record_soglie.gg_settimana[0] == 'X' )
							acGiorni[6] = 'S';

						// decodifica il codice operatore
						memset(chiave, 0, sizeof(chiave));
						memcpy(chiave, record_soglie.gr_op, sizeof(record_soglie.gr_op));
						AlltrimString(chiave);

						pDenOP= avlFind(listaOPs, chiave);
						if (pDenOP == NULL)
						{
							//Non è stato trovato operatore sarà un GR
							strcpy(acOperatore, chiave);
							// carico in una lista gruppo op per stamarlo alla fine
							ptrGR_OP = malloc((strlen(chiave)+1)*sizeof(char));
							strcpy(ptrGR_OP, chiave);
							avlAdd(listaGR_OPs, ptrGR_OP, ptrGR_OP);

							memset(acGr_Pa, 0, sizeof(acGr_Pa));
							memcpy(acGr_Pa, record_soglie.gr_pa, sizeof(record_soglie.gr_pa));
							AlltrimString(acGr_Pa);
							// carico in una lista gruppo Paesi per stamarlo alla fine
							ptrGR_PA = malloc((strlen(acGr_Pa)+1)*sizeof(char));
							strcpy(ptrGR_PA, acGr_Pa);
							avlAdd(listaGR_PAs, ptrGR_PA, ptrGR_PA);
						}
						else
						{
							sprintf( acOperatore, "%s (%s)", pDenOP, chiave);
						}
						/*************************************
						* Scrive il record nel file x download
						**************************************/

						// il campo peso è un char ma il valore salvato è numerico
						// quindi: se il campo è vuoto stampo 0, altrimenti
						// verrebbe stampato 32 che è il valore dello spazio.
						sprintf(buf_DownLoad+strlen(buf_DownLoad),"%s;%s;%.5s;%.5s;%s;%s;%d;%d;%d\n",
												GetStringNT(record_soglie.gr_pa, LEN_GRP),
												acOperatore,
												record_soglie.fascia_da,
												record_soglie.fascia_a,
												acGiorni,
												(record_soglie.stato == '1' ? "On" : "Off"),
												(record_soglie.peso != ' ' ? record_soglie.peso : 0),
												record_soglie.politica,
												record_soglie.soglia);
					}
				}
			}/* while (1) */

			//stampa elenco gruppi
			sprintf(buf_DownLoad+strlen(buf_DownLoad), "\n\nCountries Groups:\n");
			rc = Stampa_GRPA(buf_DownLoad);
			if (rc == 0)
			{
				sprintf(buf_DownLoad+strlen(buf_DownLoad), "Operators Groups:\n");
				rc = Stampa_GROP(buf_DownLoad);
			}
			MBE_FILE_CLOSE_(handle);
		}
	}

	if(rc == 0)
	{
		// ****************************************************************************
		// definisco il nome e formato del file da scaricare
		// ****************************************************************************
		printf("Content-Disposition: attachment; filename=Steering-rules.csv\n");
		printf("Content-type: text/csv\n\n");

		//stampo il contenuto
		printf("%s", buf_DownLoad);
	}

    
	return;
}
//**************************************************************************************
// vengono visualizzate tutte le soglie dello stesso paese o dello stesso gruppo paese
// che si sta "modificando"
//**************************************************************************************
void Lista_Soglie()
{
	char		*wrk_str;
	short		handle = -1;
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP];
	long 		lTotRic = 0;
	long		lTotAc = 0;
	int			nConta = 0;
	short		res;
	short		rc = 0;
	t_ts_soglie_record  record_soglie;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_Chiave, wrk_str, strlen(wrk_str));
    
	/*******************
	* Apro il file
	*******************/
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) in opening local file [%s]", rc, acFileSoglie_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return;
	}

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) in File_setkey local file [%s]", rc, acFileSoglie_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			sprintf(sTmp, "THRESHOLDS LIST: %s", ac_Chiave);
			Display_TOP(sTmp);
			printf("<center>\n");
			printf("<TABLE BORDER=1 width=100%%>\n");
			printf("<TR BGCOLOR= #dcdcdc>\n");

			printf("<TD rowspan=2><strong>Country/Country Group</strong></TD>\n\
					<TD rowspan=2><strong>Operator/Operator Group</strong></TD>\n\
					<TD rowspan=2><strong>Threshold(%%)</strong></TD>\n\
					<TD bgcolor=#C0C0C0><strong>&nbsp;</strong></TD>\n\
					<TD align=center colspan=3 bgcolor=#0099CC><font color=#FFFFFF>\n\
						<strong>Preferred Accepted </strong></font></TD>\n\
					<TD bgcolor=#C0C0C0><strong>&nbsp;</strong></TD>\n\
					<TD align=center colspan=3 bgcolor=#0099CC><font color=#FFFFFF>\n\
					   <strong>Accepted</strong></font></TD>\n\
					<TD bgcolor=#808080><strong>&nbsp;</strong></TD>\n\
					<TD align=center colspan=3 bgcolor=#CC6600><font color=#FFFFFF>\n\
						<strong>Tot Accepted %%</strong></font></TD>\n\
					</tr>\n\
					<TR BGCOLOR= #dcdcdc>\n");

			printf("  <TD bgcolor=#C0C0C0><strong>&nbsp;</strong></TD>\n");
			printf("  <TD><strong>Local</strong></TD>\n");
			printf("  <TD><strong>Remote</strong></TD>\n");
			printf("  <TD><strong>Total</strong></TD>\n");
			printf("  <TD bgcolor=#C0C0C0><strong>&nbsp;</strong></TD>\n");
			printf("  <TD><strong>Local</strong></TD>\n");
			printf("  <TD><strong>Remote</strong></TD>\n");
			printf("  <TD><strong>Total</strong></TD>\n");
			printf("  <TD bgcolor=#808080><strong>&nbsp;</strong></TD>\n");
			printf("  <TD><strong>Local</strong></TD>\n");
			printf("  <TD><strong>Remote</strong></TD>\n");
			printf("  <TD><strong>Total</strong></TD>\n");
			printf("  </TR>\n");
			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );

				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading local file [%s]", rc, acFileSoglie_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						printf("</TABLE>\n");
						Display_Message(1, "", sTmp);
						return;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					//visualizzo solo le soglie maggiori di 0 e On
					if(record_soglie.soglia > 0  && record_soglie.stato == '1')
					{
						printf("<TR>\n");
						printf("<TD>%.*s</TD>\n", LEN_GRP, record_soglie.gr_pa);
						printf("<TD>%.*s</TD>\n", LEN_GRP, record_soglie.gr_op);
						printf("<TD>%d</TD>\n", record_soglie.soglia);
						printf("<td bgcolor=#C0C0C0>&nbsp;</TD>");
						// Preferred Accepted
						printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accP[0]);// Local Tot Acc Pref
						printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accP[1]);//Remote Tot Acc Pref					
						lTotAc = record_soglie.tot_accP[0] + record_soglie.tot_accP[1];
						printf("<TD align=right><font color=#CC0033>%ld</font></TD>\n", lTotAc);// Tot Acc Pref
						
						lTotRic = record_soglie.tot_accT[0] + record_soglie.tot_accT[1];
						printf("<td bgcolor=#C0C0C0>&nbsp;</TD>");
						//  Accepted visualizzo solo i dati del primo record trovato
						if (nConta == 0)
						{
							printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accT[0]); // Local Tot Acc 
							printf("<TD align=right>%ld</TD>\n", record_soglie.tot_accT[1]); //Remote Tot Acc 
							printf("<TD align=right><font color=#CC0033>%ld</font></TD>\n", lTotRic); // Tot Acc
						}
						else
						{
							printf("<TD align=right>&nbsp;</TD>\n"); // Local Tot Acc 
							printf("<TD align=right>&nbsp;</TD>\n"); //Remote Tot Acc 
							printf("<TD align=right>&nbsp;</TD>\n"); // Tot Acc
						}

						printf("<td bgcolor=#808080>&nbsp;</TD>");
						//percentuale tra Local Tot Acc e Local Tot Acc Pref
						res = 0;
						if ( record_soglie.tot_accP[0] > 0 && record_soglie.tot_accT[0] > 0 )
							res = (short)((record_soglie.tot_accP[0] *100) / record_soglie.tot_accT[0]);
						printf("<TD><font color=#0066CC><B>%d%%</font></B></TD>\n", res);

						// percentuale tra Remote Tot Acc e Remote Tot Acc Pref
						res = 0;
						if ( record_soglie.tot_accP[1] > 0 && record_soglie.tot_accT[1] > 0 )
							res = (short)((record_soglie.tot_accP[1] *100) / record_soglie.tot_accT[1]);

						printf("<TD><font color=#0066CC><B>%d%%</B></font></TD>\n", res);
						
						// totale percentuali
						res = 0;
						if ( lTotAc > 0 && lTotRic > 0 )
							res = (short)((lTotAc *100) / lTotRic);

						printf("<TD><font color=#CC0033><B>%d%%</B></font></TD>\n", res);
						printf("</TR>\n");
						
						nConta++;
					}
				}
			}
			printf("</TABLE>\n");
			printf("<BR>\n");
			printf("<BR>\n");
			printf( "<INPUT TYPE='button' icon='ui-icon-close'  VALUE='Close' onclick='window.close()' >\n");
			printf("</center>\n");

			Display_BOTTOM();
		}
		MBE_FILE_CLOSE_(handle);
	}
}
//*************************************************************
short Carica_Op_Soglie()
{
	short		handle2 = -1;
	short		rc = 0;
	char		ac_Chiave[18];
	char		sTmp[500];
	char		chiave[20];
	char		acDesc[LEN_GRP+1];
	char		*ptrChiave;
	char		*ptrDesc;
	t_ts_oper_record record_operatori;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle2, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperatori_Loc);
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
					//Aggiungere un elemento alla lista:
					memset(chiave, 0, sizeof(chiave));
					memset(acDesc, 0, sizeof(acDesc));
					sprintf(chiave, "%.10s", record_operatori.cod_op);
					sprintf(acDesc, "%.*s",  LEN_GRP, record_operatori.den_op);
					AlltrimString(chiave);
					AlltrimString(acDesc);
					
					ptrChiave = malloc((strlen(chiave)+1)*sizeof(char));
					strcpy(ptrChiave, chiave);
					ptrDesc = malloc((strlen(acDesc)+1)*sizeof(char));
					strcpy(ptrDesc, acDesc);

					avlAdd(listaOPs, ptrChiave, ptrDesc);
				}
			}/* while (1) */

		}
		MBE_FILE_CLOSE_(handle2);
	}

	return(rc);	
}
//*********************************************************************************
// cerca i gruppi paesi e li scrive nel file per il download
//*********************************************************************************
short Stampa_GRPA(char  *buf_DownLoad)
{
	short		handle2 = -1;
	short		rc = 0;
	char		ac_Chiave[LEN_GRP];
	char		sTmp[500];
	char		*ptrChiave;
	short		is_AltKey;

	t_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle2, 1, 1);
	if (rc == 0)
	{
		//Percorrere la lista di gruppi paesi contenuti nelle soglie:
		ptrChiave = avlFirstKey(listaGR_PAs);
		while (ptrChiave)
		{
			memset(sTmp, 0, sizeof(sTmp));
			strcpy(sTmp, ptrChiave);
			memset(ac_Chiave, ' ', sizeof(ac_Chiave));
			memcpy(ac_Chiave, sTmp, strlen(sTmp));

			/*  ricerca  per chiave alternata*/
			is_AltKey = 1;
			rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
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
				sprintf(buf_DownLoad+strlen(buf_DownLoad), "%s ", sTmp);
				while ( 1 )
				{
					/*******************
					* Leggo il record
					*******************/
					rc = MBE_READX( handle2, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
					/* errore... */
					if (rc != 0)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc);
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
						//if(!memcmp(record_paesi.gr_pa, sTmp, strlen(sTmp))
							sprintf( buf_DownLoad+strlen(buf_DownLoad), ";%s", GetStringNT(record_paesi.den_paese, LEN_GRP) );
					}
				}/* while (1) */
				sprintf(buf_DownLoad+strlen(buf_DownLoad), "\n");
			}
			
			ptrChiave = avlNextKey(listaGR_PAs);
		}
		MBE_FILE_CLOSE_(handle2);
		sprintf(buf_DownLoad+strlen(buf_DownLoad), "\n\n");
	}
	else
		log(LOG_ERROR, "%s;%s; Error (%d) in opening file [%s]",gUtente, gIP, rc, acFilePaesi_Loc);

	return(rc);	
}
//*********************************************************************************
// mette in una lista in memoria i gruppi operatori
//*********************************************************************************
short Stampa_GROP(char *buf_DownLoad)
{
	short		handle2 = -1;
	short		is_AltKey;
	short		rc = 0;
	char		sTmp[500];
	char		acCod[50];
	char		*ptrChiave;
	char		*pDenOP;

	t_ts_oper_record record_gruppoOp;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));

	log(LOG_INFO, "%s;%s; Sono in Stampa GROP",gUtente, gIP);
	/********************************
	* Apro il file gruppo operatori
	*********************************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	if (rc == 0)
	{
		//Percorrere la lista di gruppi operatori contenuti nelle soglie:
		ptrChiave = avlFirstKey(listaGR_OPs);
		while (ptrChiave)
		{

			memset(sTmp, 0, sizeof(sTmp));
			strcpy(sTmp, ptrChiave);

			log(LOG_INFO, "%s;%s; Sono in while(ptrChiave) [%s][%d]",gUtente, gIP, sTmp, (short)strlen(sTmp));

			//rc = MBE_FILE_SETKEY_( handle2, sTmp, (short)strlen(sTmp), 0, GENERIC, 0);
			/*  ricerca  per chiave alternata*/
			is_AltKey = 1;
			rc = MBE_FILE_SETKEY_( handle2, sTmp, (short)strlen(sTmp), is_AltKey, GENERIC, 0);

			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileOperatori_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				sprintf(buf_DownLoad+strlen(buf_DownLoad), "%s ", sTmp);
				while ( 1 )
				{
					/*******************
					* Leggo il record
					*******************/
					rc = MBE_READX( handle2, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
					/* errore... */
					if (rc != 0)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperatori_Loc);
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
						memset(acCod, 0, sizeof(acCod));
						memcpy(acCod, record_gruppoOp.cod_op, sizeof(record_gruppoOp.cod_op));
						AlltrimString(acCod);
						pDenOP= avlFind(listaOPs, acCod);
						if (pDenOP != NULL)
							sprintf(buf_DownLoad+strlen(buf_DownLoad), ";%s (%s)", pDenOP, acCod);

					}
				}/* while (1) */
				sprintf(buf_DownLoad+strlen(buf_DownLoad), "\n");
			}
			ptrChiave = avlNextKey(listaGR_OPs);
		}

		MBE_FILE_CLOSE_(handle2);
		sprintf(buf_DownLoad+strlen(buf_DownLoad), "\n\n");
	}
	else
		log(LOG_ERROR, "%s;%s; Error (%d) in opening file [%s]",gUtente, gIP, rc, acFileOperatori_Loc);


	return(rc);	
}

//*****************************************************************************************
void scrivoLog_Soglie(t_ts_soglie_record record_soglie, char *str)
{
	char sGR_PA[LEN_GRP+1];
	char sGR_OP[LEN_GRP+1];

	memset(sGR_PA,	0, sizeof(sGR_PA));
	memset(sGR_OP,	0, sizeof(sGR_OP));

	memcpy(sGR_PA,		record_soglie.gr_pa, sizeof(record_soglie.gr_pa));
	memcpy(sGR_OP,	record_soglie.gr_op, sizeof(record_soglie.gr_op));

	TrimString(sGR_PA);
	TrimString(sGR_OP);

     log(LOG_INFO, "%s;%s; %s:%s;%s;%.5s;%.5s;%.7s;%c;%d;%ld;%ld;%d;%d",
							gUtente, gIP, str,
							sGR_PA,
							sGR_OP,
							record_soglie.fascia_da,
							record_soglie.fascia_a,
							record_soglie.gg_settimana,
							record_soglie.stato,
							record_soglie.soglia,
							record_soglie.tot_accP[0],
							record_soglie.tot_accT[0],
							record_soglie.peso,
							record_soglie.politica);
}

//********************************************************************************************************
// vengono caricati gli operatori e viene creata la lista Paesi
//********************************************************************************************************
short Lista_Operatori(void)
{
	short		handle2 = -1;
	short		rc = 0;
	char		ac_Chiave[18];
	char		sTmp[500];
	char		stringa[200];
	char		chiave[200];
	char		*ptrChiave;
	char		acDati[100];
	char		key_PA[LEN_GRP+1];
	char		Old_Pa[LEN_GRP+1];
	char		acPaese[10];
	short		is_func[25];
	short		nConta = 0;
	char		*ptr_OP;
	char		*ptr_PA;
	char		*ptr_Dati;

	AVLTREE		lista_Dati;
	AVLTREE		lista_PAeDati;
	//AVLTREE		lista_PAnoCaricare;

	t_ts_oper_record record_operatori;

	//Creare la lista:
	lista_OP			= avlMake();
	lista_PAeDati		= avlMake();
	//lista_PAnoCaricare	= avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof( t_ts_oper_record));
	
	// Fred - 24/06/2009 - Faccio una strcmp più avanti quindi memset a 0x00
	//memset(Old_Pa, ' ', sizeof(Old_Pa));
	memset(Old_Pa, 0x00, sizeof(Old_Pa));

	memset(&is_func, 0, sizeof(is_func));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle2, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperatori_Loc);
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
					if( memcmp(record_operatori.paese, "********", 8) )
					{
						//Carico tutti gli OP in una lista
						memset(chiave, 0, sizeof(chiave));
						sprintf(chiave, "%.*s%.10s;%.30s",	LEN_GRP,record_operatori.den_paese,
																	record_operatori.cod_op,
																	record_operatori.den_op);
						AlltrimString(chiave);
						ptr_OP = malloc((strlen(chiave)+1)*sizeof(char));
						strcpy(ptr_OP, chiave);

						memset(acPaese, 0, sizeof(acPaese));
						memcpy(acPaese, record_operatori.paese, 8);
						if(avlAdd(lista_OP, ptr_OP, ptr_OP) == -1)
						{
							//  chiave esistente
							//inserisco i record in una lista dei paesi da non caricare
							// commetato  lista_PAnoCaricare IPM KTSTEACS
							//avlAdd(lista_PAnoCaricare, ptr_OP, ptr_OP);
						}
					}
				}
			}/* while (1) */

			//**********************************************************************************************
			//  Carico la lista paesi in base agli operatori perchè gli arrey degli OP devono essere in ordine
			//  in base alla lista dei paesei (cioè se Italy è alla posizione array 5 gli OP dell'italia devono 
			//  essere  all'indice array 5.
			//**********************************************************************************************
			printf("	<!-- caricamento array Paesi-->");
			printf("<script language='JavaScript'>\n");
			
			printf(	"var mccOptions = new Array(\n\
						new Option(\"(Select a Country)\",'ALL')\n\
					");
			fflush(stdout);

			//creo un'altra lista con key = paese e come dati tutti gli OP di quel paese
			ptrChiave = avlFirstKey(lista_OP);  // mi ritorna la key cioè codice OP
			while (ptrChiave)
			{
				// paese non presente nella lista lista_PAnoCaricare
				//if(avlFind(lista_PAnoCaricare, ptrChiave) == NULL)
			//	{
					memset(stringa, 0, sizeof(stringa));
					memset(acDati, 0, sizeof(acDati));
					memset(key_PA, 0, sizeof(key_PA));
					memcpy(stringa, ptrChiave, strlen(ptrChiave));
					//la chiave deve contenere anche il cod op in modo da tenere l'ordinamento esatto
					memcpy(key_PA,  stringa, LEN_GRP);
					AlltrimString(key_PA);
					strcpy(acDati,  stringa+LEN_GRP);

					ptr_Dati = malloc((strlen(acDati)+1)*sizeof(char));
					strcpy(ptr_Dati, acDati);

					//se cambia paese inserisco key in lista_PAedati
					// Fred - 24/06/2009 - Se il nuovo paese ha come prefisso quello vecchio, non viene caricato !!!
					// Esempio: NIGERIA / NIGER
					//if(memcmp(Old_Pa, key_PA, strlen(Old_Pa)) )
					if(strcmp(Old_Pa, key_PA))
					{
						ptr_PA = malloc((strlen(key_PA)+1)*sizeof(char));
						strcpy(ptr_PA, key_PA);

						//creo la lista per i dati
						lista_Dati = avlMake();
						avlAdd(lista_PAeDati, ptr_PA, lista_Dati);
						
						memset(Old_Pa, 0, sizeof(Old_Pa));				
						strcpy(Old_Pa, key_PA);

						AlltrimString(key_PA);
						memset(stringa, 0, sizeof(stringa));
						SistemaApice(stringa, key_PA);
						
						printf( ",   new Option(\"%s\",\"%s\")\n", stringa, stringa );
						fflush(stdout);
					}
				//}
				avlAdd(lista_Dati, ptr_Dati, ptr_Dati  );

				ptrChiave = avlNextKey(lista_OP);
			}//FINE WHILE

			//chiudi la parentesy dell'array
			printf( ");\n</script>\n" );
			fflush(stdout);


			//Preparo l'array degli operatori
			printf("	<!-- caricamento array Operatori-->\n");
			printf("<script language='JavaScript'>\n");
			printf("var mncOptions = new Array(\n\
							 new Array(new Option('     ','ALL')\n");

			//Percorrere la listadei op+paesi:
			ptrChiave = avlFirstKey(lista_PAeDati);
			while (ptrChiave)
			{
				lista_Dati = avlFind(lista_PAeDati, ptrChiave);
				if (lista_Dati != NULL)
				{
					// cambio PAESE
					printf("\n)\n ,   new Array(\n");
					ptr_Dati = avlFirstKey(lista_Dati);
					nConta = 0;
					while (ptr_Dati)
					{
						if(nConta == 0)
							printf("new Option(");
						else
							printf("\n, new Option(");
						//valori visualizzati =Cod OP - Den OP; 
						//Valori passati dalla select = Cod OP
						printf("\"%.10s - %.*s\",\"%.10s\")", ptr_Dati, LEN_GRP, ptr_Dati+11,  ptr_Dati);
						nConta++;

						ptr_Dati = avlNextKey(lista_Dati);
					}//FINE WHILE
				}
				else
				{
					printf(")\n ,   new Array(\n");
				}
				ptrChiave = avlNextKey(lista_PAeDati);
			}//FINE WHILE

			printf(")\n );\n\n</script>\n");
		}
		MBE_FILE_CLOSE_(handle2);
	}
	else
		log(LOG_ERROR, "%s;%s; Error (%d) in opening file [%s] ",gUtente, gIP, rc, acFileOperatori_Loc);


	return(rc);	
}
///*****************************************************************************
/*short Cerca_inGRPOp(char *acGrp)
{
	short		handle2 = -1;
	short		rc = 0;
	char		ac_Chiave[LEN_GRP];
	char		sTmp[500];

	t_ts_oper_record record_gruppoOp;

	 inizializza la struttura tutta a blank
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));

	*******************************
	* Apro il file gruppo operatori
	********************************
	rc = Apri_File(acFileGrpOper_Loc, &handle2, 1, 2);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memcpy(ac_Chiave, acGrp, strlen(acGrp));

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, (short) sizeof(ac_Chiave), 0, GENERIC, 0);
		 errore
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileGrpOper_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp, 0);
		}
		 tutto ok
		else
		{
			rc = MBE_READX( handle2, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
			 errore...
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileGrpOper_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp, 0);
				}
			}
			 record TROVATO
			else   readx ok
			{
				rc = -88; //trovato
			}

		}
		MBE_FILE_CLOSE_(handle2);
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d",gUtente, gIP, acFileGrpOper_Loc, rc);

	return(rc);	
}*/

//*************************************************************************************
/*void ListaPLMN(short content_id, short sel_item_id)
{
	char sTmp[100];

	memset((char *)&mconf, 0x00, sizeof(t_interac_mconf));
	mconf.contentid = content_id;

	EXEC SQL 
		DECLARE  plmn_cursor CURSOR FOR
			SELECT  DISTINCT itemid, descr
			FROM =MCONFDB WHERE contentid = :mconf.contentid
			ORDER BY itemid
			browse access;

	exec sql open plmn_cursor;

	if(sqlcode != SQL_OK )
	{
		printf("</select>\n");
		sprintf(sTmp, "Error sql  %d", sqlcode);
		Display_Message(1, "", sTmp, 0);
	}

	do
	{
		exec sql fetch plmn_cursor into :mconf.itemid, :mconf.descr;

		if ( sqlcode == SQL_OK )
		{
			TrimString(mconf.descr);
			printf( "<option  value=\"%d\" ", mconf.itemid);
			if (sel_item_id == mconf.itemid)
				printf("selected");
			printf( ">%d - %s</option>\n", mconf.itemid, mconf.descr);	
		}
	} while ( sqlcode == SQL_OK);

	exec sql close plmn_cursor;
}*/
//*************************************************************************************

void trovauser(char *acUser, char *disabled)
{
	int 	user_type_bitmask;
	char	sTmp[500];

	memcpy((char *)&user_type_bitmask, acUser, 4);

	exec sql
			declare cursore1 cursor for
				select value, description from =USRDESC
				where type = "CL"
				browse access;

	if(sqlcode == SQL_OK)
	{
		exec sql open cursore1;
		do
		{
			/* estrazione di tutti i campi della tabella */
			exec sql fetch cursore1
					into	:usrdesc.value,
							:usrdesc.description;

			if ( sqlcode == SQL_OK )
			{
				if ((user_type_bitmask >> usrdesc.value) & 0x01)
					printf("\n%d:<INPUT TYPE='checkbox' checked NAME='USERS_TYPE_%d' title='%s' %s>&nbsp;&nbsp;"
							,usrdesc.value ,usrdesc.value, AlltrimString(usrdesc.description), disabled);
				else
					printf("\n%d:<INPUT TYPE='checkbox' NAME='USERS_TYPE_%d' title='%s' %s>&nbsp;&nbsp;"
						,usrdesc.value ,usrdesc.value, AlltrimString(usrdesc.description), disabled);
			}
		} while ( sqlcode == 0 );
	}

	if ( (sqlcode != SQL_OK) && (sqlcode != SQL_NOT_FOUND) )
	{
		sprintf(sTmp, "Error sql USRDESC: %d", sqlcode);
		Display_Message(0, "", sTmp);
	}

	exec sql close cursore1;

	return;
}
