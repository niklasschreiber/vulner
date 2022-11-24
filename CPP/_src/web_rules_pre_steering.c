/*----------------------------------------------------------------------------
*   PROGETTO : Pre Steering
*-----------------------------------------------------------------------------
*
*   File Name       : pre_steering.c
*   Ultima Modifica : 12/02/2014
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione Pre Steering
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
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <cextdecs.h (SERVERCLASS_SEND_, SERVERCLASS_SEND_INFO_)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"

/*------------- PROTOTIPI -------------*/
void 	Display_File( );
void 	Maschera_Modifica(short tipo);
void 	Display_DatiPrecedenti();
void 	Delete_Dati();
void 	Lettura_Variabili(t_ts_psrule_record *record_psrule);
void 	Aggiorna_Dati(short tipo);
short 	Controlla_Dati(t_ts_psrule_record *record_psrule, short handle );
short 	Aggiorna_PreS_rec_aster(short handle, short handle_rem);
void  	scrivoLog_Soglie(t_ts_psrule_record record_psrule, char *str);
short 	Lista_Operatori(void);
void 	scrivoLog_pre_Steering(t_ts_psrule_record record_psrule, char *str);
short 	Lista_Impianti_MGT();
short 	Carica_Array_GT(short handle,  char *acCC_COd);
short 	Carica_Lista_Paesi(void);
short 	scrivi_PreSteering_remoto(short handleDB, t_ts_psrule_record *record_psrule, t_psrule_key *keyPS, short nOperation );
void 	Prepara_Download();
extern void		Leggi_Applica();

short		gDebug;
short		gPeso;

char		*gtOP_buffer;
short		buffer_size_GT;

AVLTREE		listaPaesi;
AVLTREE		lista_OP;
AVLTREE		lista_Impianti;
AVLTREE		lista_Mgt;

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

	buffer_size_GT = 0;
	gtOP_buffer = (char *)calloc(16384, 1);
	buffer_size_GT++;

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
	sprintf(log_spooler.NomeDB, "RULESPS");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	// --------------------------------------------------------------------
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

		log(LOG_INFO, "%s;%s; Display PRE Steering ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; PRE Steering - Window Modify",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; PRE Steering - Window Insert ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Modify")== 0 )
	{
		log(LOG_INFO, "%s;%s; PRE Steering - Update",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; PRE Steering - Insert",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; PRE Steering - Delete",gUtente, gIP);
		Delete_Dati();
	}
	else if (strcmp(sOperazione, "DOWNLOAD")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display PRE steering Thresholds - Download",gUtente, gIP);
		Prepara_Download();
	}


	log_close();

return(0);
}

/******************************************************************************/
// nTipo = 0  chiamata da DISLPLAY
// nTipo = 1  chiamata da RICERCA
// nTipo = 2  chiamata da altre funzioni
/******************************************************************************/
void Display_File( )
{
	char		sTmp[500];
	char		acCC[10];
	char		*ptrPaese;
	short		handle = -1;
	short		rc = 0;
	short		lenKey = 0;  //primo campo numerico

	t_ts_psrule_record record_psrule;
	t_psrule_key keyPS;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));
	memset(&keyPS, ' ', sizeof(t_psrule_key));
	
	rc= Carica_Lista_Paesi();
	if(rc != 0)
		return;

    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 0);
	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, APPROXIMATE);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s] ", rc, acFilePreRules_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			LOGResult = SLOG_ERROR;
			Display_Message(0, "", sTmp);
		}
		/* tutto ok */
		else
		{
			Display_TOP("");

			printf("<FORM METHOD=POST ACTION='%s' NAME='Download'>\n", gName_cgi);
			printf("<INPUT TYPE='hidden' name='OPERATION' value='DOWNLOAD' >\n");

			printf("<class id='img_download'>\n");
		//	printf("<IMG SRC='images/downloadnow.gif' BORDER=0 ALT='Download pre-steering threshold list' onclick=\"javascript:open_Confirm_Dialog('id_download');\">");
			printf("<IMG SRC='images/downloadnow.gif' BORDER=0 ALT='Download rules PRE-steering threshold list' onclick=\"javascript:document.Download.submit();\">");

			printf( "</class>\n	");
			printf("</form>\n");

			printf("<CENTER>");
			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Rule' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);
			
			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");
			printf("<thead>\n");
			printf("<TR BGCOLOR= #dcdcdc>\n");
			printf("  <TH><strong>&nbsp;HLR System</strong></TH>\n");
			printf("  <TH><strong>&nbsp;CC</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Country</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Code Operator</strong></TH>\n");
			printf("  <TH><strong>&nbsp;GT</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Time from</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Time to</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Days</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Imsi WL</strong></TH>\n");
			printf("  <TH><strong>&nbsp;Status</strong></TH>\n");
			printf("  <TH><strong>&nbsp;MAP ErrCode</strong></TH>\n");
			printf("  <TH><strong>&nbsp;LTE ErrCode</strong></TH>\n");

			printf("  <TD width='5%%'>&nbsp;</TD>\n");
			printf("</TR>\n");
			printf("</thead>\n");

			printf("<tbody class='editTable'>");
			fflush(stdout);

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						LOGResult = SLOG_ERROR;
						Display_Message(0, "", sTmp);
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{

					// non visualizzo il record con key '*'
					if (memcmp(record_psrule.mgt, "********************", 16))
					{
						/***************************
						* Scrive il record a video
						****************************/
						// (link) viene disbilitato sul cancella
						printf("<TR class='gradeGreen' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&PCF=%d&PC=%d&KEY=%.75s'\">\n",
								gName_cgi, record_psrule.pcf, record_psrule.pc, record_psrule.mgt);
						fflush(stdout);
						if(record_psrule.pcf == 8224)
							printf("  <TD onclick='link = true'>&nbsp;</TD>\n");
						else
							printf("  <TD onclick='link = true'>&nbsp;%d-%d (%.8s)</TD>\n",
									record_psrule.pcf, record_psrule.pc, record_psrule.descr);

						printf("  <TD onclick='link = true'>&nbsp;%.8s</TD>\n", record_psrule.paese);

						memset(acCC, 0, sizeof(acCC));
						memcpy(acCC, record_psrule.paese, sizeof(record_psrule.paese));
						AlltrimString(acCC);
						ptrPaese= avlFind(listaPaesi, acCC);
						if(ptrPaese != NULL)
							printf(" <TD onclick='link = true'>%s</TD>\n", ptrPaese);
						else
							printf("  <TD onclick='link = true'>&nbsp;</TD>\n");

						printf("  <TD onclick='link = true'>&nbsp;%.10s</TD>\n", record_psrule.cod_op);
						printf("  <TD onclick='link = true'>&nbsp;%.24s</TD>\n", record_psrule.gt);
						printf("  <TD onclick='link = true'>&nbsp;%.5s</TD>\n", record_psrule.fascia_da);
						printf("  <TD onclick='link = true'>&nbsp;%.5s</TD>\n", record_psrule.fascia_a);

						// gg settimana in Rosso è il gg inserito (peer cui il profilo è valido)
						printf("  <TD  onclick='link = true'>&nbsp;");
						if( record_psrule.gg_settimana[1] == 'X' )
							printf("<font color=red >M </font>");
						else
							printf("M ");
						if( record_psrule.gg_settimana[2] == 'X' )
							printf("<font color=red >T </font>");
						else
							printf("T ");
						if( record_psrule.gg_settimana[3] == 'X' )
							printf("<font color=red >W </font>");
						else
							printf("W ");
						if( record_psrule.gg_settimana[4] == 'X' )
							printf("<font color=red >T </font>");
						else
							printf("T ");
						if( record_psrule.gg_settimana[5] == 'X' )
							printf("<font color=red >F </font>");
						else
							printf("F ");
						if( record_psrule.gg_settimana[6] == 'X' )
							printf("<font color=red >S </font>");
						else
							printf("S ");
						if( record_psrule.gg_settimana[0] == 'X' )
							printf("<font color=red >S </font>");
						else
							printf("S ");
						printf("</TD>\n");

						printf("<TD align='center' onclick='link=true' id='tdred'>%s</TD>\n", (record_psrule.imsi_white_list_enabled == '1') ? "&#x2714;" : "&nbsp;");

						printf("<TD onclick='link = true'>&nbsp;%s</TD>\n"  , (record_psrule.stato == '1' ? "On" : "Off") );
						printf("<TD onclick='link = true'>&nbsp;%d</TD>\n"  , record_psrule.map_reject_code);

						if(record_psrule.lte_reject_code == 8224)
							record_psrule.lte_reject_code = 0;
						printf("  <TD onclick='link = true'>&nbsp;%d</TD>\n"  , record_psrule.lte_reject_code);

						if(record_psrule.pc == 8224)
							printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&PCF=%d&PC=%d&KEY=%.75s', 'Rule: [%.52s]');\" title='Delete'>",
										gName_cgi, record_psrule.pcf, record_psrule.pc, record_psrule.mgt,
										record_psrule.paese);
						else
							printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&PCF=%d&PC=%d&KEY=%.75s', 'Rule: PCF[%d] PC[%d] [%.52s]');\" title='Delete'>",
										gName_cgi, record_psrule.pcf, record_psrule.pc, record_psrule.mgt,
										record_psrule.pcf, record_psrule.pc, record_psrule.paese);
						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
						fflush(stdout);
					}
				}
			}/* while (1) */

			printf("</tbody>");
			printf("</TABLE>\n");
			printf("<BR>\n");

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Rule' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);
			printf("</CENTER>\n");

			// inserimento delle finestre di dialogo
			printf("<script>\n");
			printf("    insert_Confirm_Delete();\n");
			// conferma download
	/*		printf("    insert_Confirm_Dialog ('id_download', 'Download pre-steering threshold list', 'Do you want to proceed?',\n");
			printf("        'ui-icon-arrowthickstop-1-s','Download','document.Download.submit()');\n");*/
			printf("</script>\n");

			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error (%d) in opening file [%s]",gUtente, gIP, rc, acFilePreRules_Loc);


	return;
}


//*************************************************************************************************
void Maschera_Modifica(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	short		handle = -1;
	short		rc = 0;
	short		lenKey = 79;
	char		sTipo[20];
	char		acCC[10];
	char		*ptrPaese;

	t_ts_psrule_record record_psrule;
	t_psrule_key keyPS;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));
	memset(&keyPS,		  ' ', sizeof(t_psrule_key));

	memset(sTmp, 0, sizeof(sTmp));
	//record_psrule.map_reject_code = 0;

	if (( (wrk_str = cgi_param( "PCF" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pcf = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pc = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(keyPS.mgt, wrk_str, strlen(wrk_str));


	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 1);
	if (rc == 0 && tipo == 0)
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d;Key=%.75s", keyPS.pcf, keyPS.pc, keyPS.mgt);
		strcpy(log_spooler.TipoRichiesta, "VIEW");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		/********************************
		* Cerco il record del db 
		***********************************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, EXACT);

		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePreRules_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			rc = MBE_READX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				LOGResult = SLOG_ERROR;
			}
			else
				scrivoLog_pre_Steering(record_psrule, "ViewPS");

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
			strcpy(sTipo, "Modify");
			Display_TOP("Pre-Steering Update");

			rc = Carica_Lista_Paesi();
			if (rc != 0)
				return;
		}
		else
		{
			strcpy(sTipo, "Insert");
			Display_TOP("Pre-Steering Insertion");

			rc = Lista_Impianti_MGT();
			if (rc == 0)
				rc = Lista_Operatori();
			if (rc != 0)
				return;
		}

		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<fieldset><legend>Define PRE Steering rules&nbsp;</legend>\n");

		printf("<CENTER>\n\
			   <form method='POST' action='%s' name='inputform' onsubmit=\"return CheckPre_Steering('%s')\">\n",gName_cgi, sTipo);
		printf("<TABLE width = 100%% cellspacing=10 cellborder=10 border=0>\n");
		fflush(stdout);

		//-------------------- key  inserimento--------------------
		if(tipo == INS)
		{
			printf("<TR>");
			printf("<td align='right' colspan=1>HLR System:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='ImpiantiSelect' WIDTH='300' STYLE='width: 300px;FONT-FAMILY:Courier;' class='chosen-select' onChange='CheckLte(selectedIndex)'\"></select>\n\
					</td>\n");

			printf("</tr><tr>\n");
			printf("<td align='right' class='testo'>Country:&nbsp;</td>\n\
				   <td align='left'>\n\
				   <select name='countrySelect'  STYLE='width:300px;FONT-FAMILY:Courier;' class='chosen-select' onChange=\"setMNC(selectedIndex);attivaPostfix();\"></select>\n\
					</td>\n");

			printf("<td align='right' >Operator:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='operatorSelect' STYLE='width:300px;FONT-FAMILY:Courier;' class='chosen-select' onChange=\"setVLR(selectedIndex);attivaPostfix();\" ></select>\n\
					</td>\n");
			printf("</tr><tr>\n");
			printf("<td align='right' colspan=1>VLR Prefix:&nbsp;</td>\n\
					<td align='left'>\n\
					<select name='VLRSelect' STYLE='width: 300px;FONT-FAMILY:Courier;' class='chosen-select' onChange=\"attivaPostfix()\"></select>\n\
					</td>\n");
			printf("<td align='right' colspan=1>VLR Postfix:&nbsp;</td>\n\
					<td align='left'>\n\
					<input type='text' name='VLRPostfix'  MAXLENGTH=20 class='numeric'></select>\n\
					</td>\n");
			printf("</tr><tr>\n\
					<TD><input TYPE='hidden' name='fOperator'  value='' >\n\
						</td>\n");
		
			printf("<script> setMCC(); setMNC(0); setImpianti(); setVLR(0);attivaPostfix();</script>");

			printf("</tr>\n");

			//--------------------- fine  list --------------------------
			
			printf("<TR>\n");
			printf("<td width='25%%'>&nbsp;</td>\n");
			printf("</tr><tr>\n");

			printf("<TD align=right>Time from:</b></TD>\n");
			printf("<TD><input type='text' name='FASCIA_DA' size='8' class='onlytimepic'  MAXLENGTH=5 VALUE='00:00'> (HH:MM)</td>");
			printf("<TD align=right>Time to:</TD>\n");
			printf("<TD align=left colspan=3>\n\
				   <input type='text' name='FASCIA_A' size='8'  class='onlytimepic' MAXLENGTH=5 VALUE='23:59'> (HH:MM)</td>");
			printf("</tr><tr>\n");

			printf("<TD align=right>Days:</TD>\n");
			printf("<TD align=left colspan=7>\n\
					Monday<INPUT TYPE='checkbox'    checked NAME='LUN' >&nbsp;&nbsp;");
			printf("Tuesday<INPUT TYPE='checkbox'   checked NAME='MAR' >&nbsp;&nbsp;");
			printf("Wednesday<INPUT TYPE='checkbox' checked NAME='MER' >&nbsp;&nbsp;");
			printf("Thursday<INPUT TYPE='checkbox'  checked NAME='GIO' >&nbsp;&nbsp;");
			printf("Friday<INPUT TYPE='checkbox'    checked NAME='VEN' >&nbsp;&nbsp;");
			printf("Saturday<INPUT TYPE='checkbox'  checked NAME='SAB' >&nbsp;&nbsp;");
			printf("Sunday<INPUT TYPE='checkbox'    checked NAME='DOM' >");
			
            printf("</TD>\n");
			printf("</tr>\n");
		}
		else
		{
			//-------------------- key  modifica--------------------
			printf("<TR>");
			printf("<TD align=right>HLR System:</TD>\n");
			if (record_psrule.pcf == 8224)
				printf("<TD align=left colspan=7 >&nbsp;</TD>\n");
			else
				printf("<TD align=left colspan=7 >%d-%d (%.8s)</TD>\n", 
						record_psrule.pcf, record_psrule.pc, record_psrule.descr);
			printf("</tr><tr>\n");

			printf("<TD align=right>Country :</TD>\n");
			memset(acCC, 0, sizeof(acCC));
			memcpy(acCC, record_psrule.paese, sizeof(record_psrule.paese));
			AlltrimString(acCC);
			ptrPaese= avlFind(listaPaesi, acCC);
			if(ptrPaese != NULL)
				printf(" <TD align=left colspan=7 >%s</TD>\n", ptrPaese);
			else
				printf("<TD align=left colspan=7 >%.8s</TD>\n", record_psrule.paese);

			printf("</tr><tr>\n");

			printf("<TD align=right>Operator :</TD>\n");
			printf("<TD align=left colspan=7 >%.10s</TD>\n", record_psrule.cod_op);
			printf("</tr><tr>\n");

			printf("<TD align=right>VLR :</TD>\n");
			printf("<TD align=left colspan=7 >%.24s</TD>\n", record_psrule.gt);
			printf("</tr><tr>\n");

			printf("<TD align=right>Time from:</TD>\n");
			printf("<TD align=left>%.5s", record_psrule.fascia_da);
			printf("&nbsp;&nbsp;&nbsp;Time to:&nbsp;\n");
			printf("%.5s</TD>\n", record_psrule.fascia_a);
			printf("</tr><tr>\n");

			printf("<TD align=right>Days:</TD>\n");
			printf("<TD align=left colspan=7>\n\
					Monday<INPUT TYPE='checkbox' NAME='LUN' disabled");
			if (record_psrule.gg_settimana[1] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Tuesday<INPUT TYPE='checkbox' NAME='MAR' disabled");
			if (record_psrule.gg_settimana[2] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Wednesday<INPUT TYPE='checkbox' NAME='MER' disabled");
			if (record_psrule.gg_settimana[3] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Thursday<INPUT TYPE='checkbox' NAME='GIO' disabled");
			if (record_psrule.gg_settimana[4] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Friday<INPUT TYPE='checkbox' NAME='VEN' disabled");
			if (record_psrule.gg_settimana[5] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Saturday<INPUT TYPE='checkbox' NAME='SAB' disabled");
			if (record_psrule.gg_settimana[6] == 'X')
				printf(" checked ");
			printf(">&nbsp;&nbsp;\n");

			printf("Sunday<INPUT TYPE='checkbox' NAME='DOM' disabled");
			if (record_psrule.gg_settimana[0] == 'X')
				printf(" checked ");
			printf(">\n");
			
			printf("</TD>\n");
			printf("</tr>\n");

			printf("<tr><td colspan=7><hr id='hrBlue'></td>\n");
			printf("</tr>\n");
		}

		if(rc > 0  )
			return;

		printf("<TR>");
		printf("<TD align=right>Imsi White List:</TD>\n");
		printf("<TD align=left><INPUT TYPE='checkbox' NAME='IMSI_BL' ");
		if( record_psrule.imsi_white_list_enabled == '1')
			printf(" checked ");
		printf("></td>");
		fflush(stdout);
		printf("</TR>");

		printf("<TR>");
		printf("<TD align=right>Status:</TD>\n");
		printf("<TD align=left><SELECT NAME='STATO'  class='noSearch' style='width:60px' >\n\
				<option value='1'>On</option>\n\
				<option value='0' ");
		if(record_psrule.stato == '0')
			printf("selected ");
		printf(">Off</option>\n\
				</select>\n");
		printf("</TD>\n");
		printf("</tr><tr>\n");

		printf("<TD align=right>Steering MAP ErrCode:</TD>\n");
		printf( "<td align=left><select name='MAP_ERR' class='chosen-select' STYLE='width: 200px'>\n" );

		printf( "<script language='JavaScript'>\n\
						Insert_MAP_errcode(%d, 1);\n\
					</script>\n", record_psrule.map_reject_code);
		printf("</select></TD>\n");

		printf("</tr><tr>\n");
		printf("<TD align=right>Steering LTE ErrCode:</TD>\n");
		printf( "<td align=left><select name='LTE_ERR' class='chosen-select' STYLE='width: 200px'>\n" );

		printf( "<script language='JavaScript'>\n\
						Insert_LTE_errcode(%d, 1);\n\
					</script>\n", record_psrule.lte_reject_code);
		printf("</select></TD>\n");
		printf("</TR>\n");

		printf("</TABLE></center></fieldset>\n" );
		fflush(stdout);

		printf("<BR>");
		printf("<BR>");

		if(tipo == 0 )
		{
			printf("<INPUT TYPE='hidden' name='PCF' value=\"%d\" >\n", record_psrule.pcf);
			printf("<INPUT TYPE='hidden' name='PC' value=\"%d\" >\n", record_psrule.pc);
			printf("<INPUT TYPE='hidden' name='KEY' value=\"%.75s\" >\n", record_psrule.mgt);
		}

		printf("<CENTER>\n");

			printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='Return To List' \
				    onclick=\"Javascript:location='%s'\" >\n", gName_cgi);
			printf("<input type='submit' icon='ui-icon-check' value='%s' name='OPERATION' >\n", sTipo );

		printf("</CENTER>\n\
				</form>\n");

		Display_BOTTOM();
	}

}
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		sTmp2[200];
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;
	short		lenKey = 79;

	t_ts_psrule_record record_psrule;
	t_ts_psrule_record record_psrule_backup;
	t_psrule_key keyPS;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));
	memset(&record_psrule_backup, ' ', sizeof(t_ts_psrule_record));
	memset(&keyPS, ' ', sizeof(t_psrule_key));

	memset(sTmp, 0, sizeof(sTmp));
	memset(sTmp2, 0, sizeof(sTmp2));

	if (( (wrk_str = cgi_param( "PCF" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pcf = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pc = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(keyPS.mgt, wrk_str, strlen(wrk_str));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d;Key=%.75s",
			(keyPS.pcf  == 8224 ? 0 : keyPS.pcf),
			(keyPS.pc  == 8224 ? 0 : keyPS.pc),
			keyPS.mgt);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 1);
	if(rc)
		return;
	rc = Apri_File(acFilePreRules_Rem, &handle_rem, 1, 1);

	if (rc == 0 && tipo == UPD)  //modifica
	{
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePreRules_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		if(rc == 0)
		{
			rc = MBE_READLOCKX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&record_psrule_backup, &record_psrule, sizeof(record_psrule));

				//aggiorno il record con i dati modificati
				Lettura_Variabili(&record_psrule);

				//aggiorno il record in LOCALE con i dati modificati
				rc = MBE_WRITEUPDATEX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in writing (upd) file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle);
				}
				else
				{
					// ********************* scrivo DB REMOTO ***********************
					rc= scrivi_PreSteering_remoto(handle_rem, &record_psrule, &keyPS, UPD);
					if(rc == 0)
					{
						// tutto ok unlock locale
						MBE_UNLOCKREC(handle);
						//Aggiornata soglia scrivo Log
						scrivoLog_pre_Steering(record_psrule, "UpdPS");
					}
					else
					{
						// ERRORE SCRITTURA REMOTO
						// aggiorno il record in Locale con i dati originali
						rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_psrule_backup, (short) sizeof(t_ts_psrule_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating  Local file [%s] ", rc, acFilePaesi_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handle);
						}
						// setto rc a 1 per segnalare errore
						rc = 1;
					}
				}
			}
		}
	}
	//---------------------------------- INSERIMENTO ---------------------------------------
	if (rc == 0 && tipo == 1)
	{
		strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL

		record_psrule.map_reject_code = 0;
		record_psrule.lte_reject_code = 0;

		Lettura_Variabili(&record_psrule);

		sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d;Key=%.75s",
				(record_psrule.pcf == 8224 ? 0 : record_psrule.pcf),
				(record_psrule.pc == 8224 ? 0 : record_psrule.pc),
				record_psrule.mgt);

		rc = Controlla_Dati(&record_psrule, handle);
		if (rc == 0 )
		{
			rc = MBE_WRITEX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			/* errore */         
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Error (%d) in writing file [%s]: KEY already exist", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				// ********************* scrivo DB REMOTO ***********************
				rc= scrivi_PreSteering_remoto(handle_rem, &record_psrule, &keyPS, INS);
				if(rc == 0)
					scrivoLog_pre_Steering(record_psrule, "InsPS");//inserita soglia scrivo Log
				else
				{
					// ERRORE Inserimento REMOTO
					//cancello locale
					MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, EXACT);
					MBE_READLOCKX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
					rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_psrule, 0);
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in deleting file [%s]", rc, acFilePaesi_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
					// setto rc a 1 per segnalare errore
					rc = 1;
				}
			}
		}
		else if (rc == 9 )
		{
			sprintf(sTmp, "Rules overlap in Time or Days" );
			Display_Message(1, "", sTmp);
		}
	}

	// aggiorno il record con key riempita ad '*' 
	if (rc == 0)
		rc = Aggiorna_PreS_rec_aster(handle, handle_rem);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------------------*/
	/* LOG SICUREZZA solo per db rules PS		*/
	/*------------------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	if (rc == 0)
	{
		Display_File( );
	}
}
/* --------------------------------------------------------------------------*/
//tipo == 0   cancellazione da web
/* --------------------------------------------------------------------------*/
void Delete_Dati()
{
	char		*wrk_str;
	short		handle = -1;
	short		handle_rem = -1;
	char		sTmp[500];
	char		sTmp2[100];
	int			rc = 0;
	short		lenKey = 79;
	t_ts_psrule_record record_appo;
	t_ts_psrule_record record_psrule_backup;
	t_psrule_key keyPS;

	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_psrule_record));
	memset(&record_psrule_backup, ' ', sizeof(t_ts_psrule_record));
	memset(&keyPS, ' ', sizeof(t_psrule_key));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/
	memset(sTmp, 0, sizeof(sTmp));
	memset(sTmp2, 0, sizeof(sTmp2));

	if (( (wrk_str = cgi_param( "PCF" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pcf = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		keyPS.pc = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(keyPS.mgt, wrk_str, strlen(wrk_str));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d;Key=%.75s", keyPS.pcf, keyPS.pc, keyPS.mgt);
	strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/*******************
	* Apro il file filereq
	*******************/
	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 1);
	if(rc)
		return;

	rc = Apri_File(acFilePreRules_Rem, &handle_rem, 1, 1);
	
	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, EXACT);
		if (rc == 0)
		{
			/************************
			* Leggo il record locale
			************************/
			rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_psrule_record) );
			if ( rc)//errore
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* trovato lo cancello */
			if ( rc == 0 )
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&record_psrule_backup, &record_appo, sizeof(t_ts_psrule_record));

				rc = MBE_WRITEUPDATEX( handle, (char *) &record_appo, 0 );
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) in deleting file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					rc= scrivi_PreSteering_remoto(handle_rem, &record_appo, &keyPS, DEL);
					if(rc == 0)
					{
						// tutto ok unlock locale
						MBE_UNLOCKREC(handle);
						scrivoLog_pre_Steering(record_appo, "DelPS");//Cancellata soglia scrivo Log
					}
					else
					{
						// ERRORE cancellazione REMOTO
						// inserisco il record in Locale con i dati originali
						rc = MBE_WRITEX( handle, (char *) &record_psrule_backup, (short) sizeof(t_ts_psrule_record) );
						/* errore */
						if (rc)
						{
							if (rc == 10 )
							{
								sprintf(sTmp, "In Local DB, record already exist");
								log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
							}
							else
							{
								sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFilePreRules_Loc);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
							}
						}
						// setto rc a 1 per segnalare errore
						rc = 1;
					}
				}
			}
		}
	}
	// aggiorno il record con key riempita ad '*'
	if (rc == 0)
		rc = Aggiorna_PreS_rec_aster(handle, handle_rem);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------------------*/
	/* LOG SICUREZZA solo per db operator		*/
	/*------------------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	if (rc == 0)
		Display_File();

}
//***************************************************************************
void Lettura_Variabili(t_ts_psrule_record *record_psrule)
{
	char	*wrk_str;
	char	sTmp[500];
	char		*pTmp;

	memset(sTmp, 0 , sizeof(sTmp));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	if (( (wrk_str = cgi_param( "ImpiantiSelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		if(wrk_str[0] != ' ')
		{
			pTmp= GetToken(wrk_str, ";"); // pcf
			if(pTmp)
				record_psrule->pcf = (short) atoi(pTmp);
			pTmp= GetToken(NULL, ";");  
			if(pTmp)
				record_psrule->pc = (short) atoi(pTmp);
			pTmp= GetToken(NULL, ";");  
			if(pTmp)
				memcpy(record_psrule->descr ,pTmp, strlen(pTmp));
		}
	}

	if (( (wrk_str = cgi_param( "countrySelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(record_psrule->paese, wrk_str, strlen(wrk_str));
	}
	if (( (wrk_str = cgi_param( "operatorSelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(record_psrule->cod_op, wrk_str, strlen(wrk_str));
	}
	if (( (wrk_str = cgi_param( "VLRSelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memset(sTmp, 0, sizeof(sTmp));
		strcpy(sTmp, wrk_str);
		if (( (wrk_str = cgi_param( "VLRPostfix" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcat(sTmp, wrk_str);
		
		memcpy(record_psrule->gt, sTmp, strlen(sTmp));

	}
	
	if (( (wrk_str = cgi_param( "FASCIA_DA" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_psrule->fascia_da, wrk_str, strlen(wrk_str));
	if (( (wrk_str = cgi_param( "FASCIA_A" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_psrule->fascia_a, wrk_str, strlen(wrk_str));
	//  -------------- GG SETTIMANA -------------
	if (( (wrk_str = cgi_param( "LUN" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[1] = 'X';
	if (( (wrk_str = cgi_param( "MAR" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[2] = 'X';
	if (( (wrk_str = cgi_param( "MER" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[3] = 'X';
	if (( (wrk_str = cgi_param( "GIO" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[4] = 'X';
	if (( (wrk_str = cgi_param( "VEN" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[5] = 'X';
	if (( (wrk_str = cgi_param( "SAB" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[6] = 'X';
	if (( (wrk_str = cgi_param( "DOM" ) ) != NULL ) && (strlen(wrk_str) > 0))
			record_psrule->gg_settimana[0] = 'X';
	//------------------------------------------------
	record_psrule->imsi_white_list_enabled = 0x30;
	if (( (wrk_str = cgi_param( "IMSI_BL" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_psrule->imsi_white_list_enabled = 0x31;
	if (( (wrk_str = cgi_param( "STATO" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_psrule->stato = wrk_str[0];
	if (( (wrk_str = cgi_param( "MAP_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_psrule->map_reject_code = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "LTE_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_psrule->lte_reject_code = (short) atoi(wrk_str);

}
//*****************************************************************************************
// cerco per key = GR_PA + GR_OP  gli altri campi li controllo per non avere accavallamenti
//*****************************************************************************************
short Controlla_Dati(t_ts_psrule_record *record_psrule, short handle )
{
	char		sTmp[500];
	char		ac_Chiave[62];
	short		rc = 0;
	short		ggOK, i;
	short		oraOK;	

	t_ts_psrule_record record_appo;

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
		
	sprintf(ac_Chiave, "%d%d%.58s", record_psrule->pcf,	
									record_psrule->pc,
									record_psrule->mgt);

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, GENERIC);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d)File_setkey file [%s]", rc, acFilePreRules_Loc);
		log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
			rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				if (rc == 1)/* fine file */
					rc = 0;
				else
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
				if ( (HHMM2TS(record_psrule->fascia_da) > HHMM2TS(record_appo.fascia_a) ||
				      HHMM2TS(record_psrule->fascia_da) < HHMM2TS(record_appo.fascia_da) ) 
				 &&
				     (HHMM2TS(record_psrule->fascia_a) > HHMM2TS(record_appo.fascia_a) ||
				      HHMM2TS(record_psrule->fascia_a) < HHMM2TS(record_appo.fascia_da) ) 
				   )
				{
					oraOK = 1;	
				}
				else
				{
					//controllo i giorni della settimana
					for(i = 0; i <= 6 && ggOK; i++)
					{
						if(record_psrule->gg_settimana[i] == 'X' &&
						   record_appo.gg_settimana[i]   == 'X')
						{
							ggOK = 0;
						}
					}
					// se oraOK == 0 &&  ggOK == 1  ->OK
					// se oraOK == 0 &&  ggOK == 0  ->KO
					if( oraOK == 0 &&  ggOK == 0 )
					{
						rc = 9;
						break;
					}
				}
			}

		} // fine while
	}

	return(rc);
}
//************************************************************************************
short Aggiorna_PreS_rec_aster(short handle, short handle_rem)
{
	short		rc = 0;
	char		ac_Chiave[79];
	char		sTmp[500];
	long long	lJTS = 0;

	t_ts_psrule_record record_psrule;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));

	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	lJTS = JULIANTIMESTAMP(0);

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePreRules_Loc);
		log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	if(rc == 0)
	{
		//------------------------- AGGIORNO DB  ----------------------------------
		rc = MBE_READLOCKX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
		/* errore... */
		if ( rc)
		{
			if(rc == 1)
			{
				memcpy(&record_psrule, ac_Chiave, 79);
				record_psrule.ts2 = lJTS;

				//--------------------- inserisco il record
				rc = MBE_WRITEX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				/* errore */         
				if (rc)
				{
					sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			record_psrule.ts2 = lJTS;

			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
		}
	}
	if(rc == 0)
	{
		/*******************
		* AGGIORNO IL DB REMOTO
		*******************/
		rc = MBE_FILE_SETKEY_( handle_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePreRules_Rem);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		if(rc == 0)
		{
			//------------------------- AGGIORNO DB  ----------------------------------
			rc = MBE_READLOCKX( handle_rem, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				if(rc == 1)
				{
					memcpy(&record_psrule, ac_Chiave, 79);
					record_psrule.ts2 = lJTS;

					//--------------------- inserisco il record
					rc = MBE_WRITEX( handle_rem, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
					/* errore */
					if (rc)
					{
						sprintf(sTmp, "Error (%d) in writing file [%s]", rc, acFilePreRules_Rem);
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
				}
				else
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Rem);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				//aggiorno il record con la data attuale
				record_psrule.ts2 = lJTS;

				rc = MBE_WRITEUPDATEUNLOCKX( handle_rem, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating file [%s]", rc, acFilePreRules_Rem);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle_rem);
				}
			}
		}
	}
	return(rc);
}
//*****************************************************************************************
void scrivoLog_pre_Steering(t_ts_psrule_record record_psrule, char *str)
{
	char smgt[50];
	char sgt[50];
	char sPaese[50];
	char sCodOP[50];

	memset(smgt,	0, sizeof(smgt));
	memset(sPaese,	0, sizeof(sPaese));
	memset(sgt,	0, sizeof(sgt));
	memset(sCodOP,	0, sizeof(sCodOP));

	memcpy(smgt,	record_psrule.mgt, sizeof(record_psrule.mgt));
	memcpy(sPaese,	record_psrule.paese, sizeof(record_psrule.paese));
	memcpy(sgt,		record_psrule.gt, sizeof(record_psrule.gt));
	memcpy(sCodOP,	record_psrule.cod_op, sizeof(record_psrule.cod_op));

	TrimString(smgt);
	TrimString(sPaese);
	TrimString(sgt);
	TrimString(sCodOP);

     log(LOG_INFO, "%s;%s; %s:%s;%s;%s;%s;%.5s;%.5s;%.7s;%c;%d",
							gUtente, gIP, str,
							smgt,
							sPaese,
							sCodOP,
							sgt,
							record_psrule.fascia_da,
							record_psrule.fascia_a,
							record_psrule.gg_settimana,
							record_psrule.stato,
							record_psrule.map_reject_code);
}

//********************************************************************************************************
// vengono caricati gli operatori e viene creata la lista Paesi
//********************************************************************************************************
short Lista_Operatori(void)
{
	short		handle2 = -1;
	short		handleGT = -1;
	short		rc = 0;
	char		ac_Chiave[18];
	char		sTmp[500];
	char		stringa[200];
	char		chiave[200];
	char		*ptrChiave;
	char		acDati[300];
	char		key_PA[100];
	char		Old_Pa[100];
	char		acCC_COd[20];
	short		is_func[25];
	short		nConta = 0;
	char		*ptr_OP;
	char		*ptr_PA;
	char		*ptr_Dati;

	AVLTREE		lista_Dati;
	AVLTREE		lista_PAeDati;
	AVLTREE		lista_PAnoCaricare;

	t_ts_oper_record record_operatori;

	//Creare la lista:
	lista_OP			= avlMake();
	lista_PAeDati		= avlMake();
	lista_PAnoCaricare	= avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof( t_ts_oper_record));
	memset(Old_Pa, ' ', sizeof(Old_Pa));				

	memset(&is_func, 0, sizeof(is_func));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle2, 1, 1);
	if(rc == 0)
		rc = Apri_File(acFileOperGT_Loc, &handleGT, 1, 1);

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
						sprintf(chiave, "%.*s%.8s%.10s;%.*s%.8s;",	LEN_GRP, record_operatori.den_paese,
																		record_operatori.paese,
																		record_operatori.cod_op,
																		LEN_GRP, record_operatori.den_op,
																		record_operatori.paese);
						AlltrimString(chiave);
						ptr_OP = malloc((strlen(chiave)+1)*sizeof(char));
						strcpy(ptr_OP, chiave);

                        if(avlAdd(lista_OP, ptr_OP, ptr_OP) == -1)
						{
							// Se chiave esistente
							//inserisco i record in una lista dei paesi da non caricare
							avlAdd(lista_PAnoCaricare, ptr_OP, ptr_OP);
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
						new Option(\"(Choose a Country)\",' ')\n\
					");
			fflush(stdout);

			//creo un'altra lista con key = paese e CC e come dati tutti gli OP di quel paese
			ptrChiave = avlFirstKey(lista_OP);  // mi ritorna la key cioè codice OP
			while (ptrChiave)
			{
				// paese non presente nella lista lista_PAnoCaricare
				if(avlFind(lista_PAnoCaricare, ptrChiave) == NULL)
				{
					memset(stringa, 0, sizeof(stringa));
					memset(acDati, 0, sizeof(acDati));
					memset(key_PA, 0, sizeof(key_PA));
					memcpy(stringa, ptrChiave, strlen(ptrChiave));
					//la chiave deve contenere anche il cod op in modo da tenere l'ordinamento esatto
					memcpy(key_PA,  stringa, LEN_GRP+8);
					AlltrimString(key_PA);
					strcpy(acDati,  stringa+LEN_GRP+8);

					ptr_Dati = malloc((strlen(acDati)+1)*sizeof(char));
					strcpy(ptr_Dati, acDati);

					//se cambia paese inserisco key in lista_PAedati
					if(memcmp(Old_Pa, key_PA, strlen(Old_Pa)) )
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
						
						// acDati = codop;denopCC 10+1+64+8
						printf( ",   new Option(\"%s [%s]\",\"%.8s\")\n", GetStringNT(stringa, LEN_GRP), GetStringNT(stringa+LEN_GRP, 8), acDati+11+LEN_GRP );
						fflush(stdout);
					}
				}
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
							 new Array(new Option(' ',' ')\n");
			fflush(stdout);
			memset(stringa, 0, sizeof(stringa));

			//Percorrere la listadei op+paesi:
			ptrChiave = avlFirstKey(lista_PAeDati);
			while (ptrChiave)
			{
				lista_Dati = avlFind(lista_PAeDati, ptrChiave);
				if (lista_Dati != NULL)
				{
					// cambio PAESE
					printf("\n)\n ,   new Array(\n");

					strcpy(stringa, ")\n,	new Array(new Array(new Option('(All)','  ')\n ");
					sprintf(gtOP_buffer+ strlen(gtOP_buffer), "%s", stringa);
					fflush(stdout);

					ptr_Dati = avlFirstKey(lista_Dati);
					nConta = 0;
					while (ptr_Dati)
					{
						if(nConta == 0)
						{
							printf("new Option(\"(Choose an Operator)\",' ')\n");
							printf(", new Option(");
						}
						else
						{
							printf("\n, new Option(");

							strcpy(stringa, ", new Array(new Option('(All)','  ')\n ");
							// se il buffer +stringa da sc
							if(strlen(gtOP_buffer) + strlen(stringa) > (16384 * buffer_size_GT)-35)
							{
								buffer_size_GT++;
								gtOP_buffer = (char *)realloc(gtOP_buffer, (16384 * buffer_size_GT));
								if (gtOP_buffer == NULL)
								{
									printf("MGT buffer reallocation failed !!!");
									exit(1);
								}
							}
							sprintf(gtOP_buffer+ strlen(gtOP_buffer), "%s", stringa);
							fflush(stdout);
							
						}
						fflush(stdout);

						//valori visualizzati =Cod OP - Den OP; 
						//Valori passati dalla select = Cod OP
						printf("\"%.10s - %.*s\",\"%.10s\")", ptr_Dati, LEN_GRP, ptr_Dati+11,  ptr_Dati);
						nConta++;

						memset(acCC_COd, 0, sizeof(acCC_COd));
						sprintf(acCC_COd, "%.8s%.10s", ptr_Dati+11+LEN_GRP, ptr_Dati);
						rc = Carica_Array_GT(handleGT, acCC_COd );
						if(rc != 0)
							return(rc);

						ptr_Dati = avlNextKey(lista_Dati);
					}//FINE WHILE
				}
				else
				{
					printf(")\n ,   new Array(\n");
					strcpy(stringa, ")\n,	new Array(new Array(new Option('(All)','  ')\n ");
					sprintf(gtOP_buffer+ strlen(gtOP_buffer), "%s", stringa);
					fflush(stdout);
				}
				ptrChiave = avlNextKey(lista_PAeDati);
			}//FINE WHILE

			printf(")\n );\n\n</script>\n");
			fflush(stdout);

			//Preparo l'array dei GT
			printf("	<!-- caricamento array GT-->\n");
			printf("<script language='JavaScript'>\n");
			printf("var aGTOP = new Array(\n\
									new Array(\n\
										new Array(	new Option(' ',' '))\n\
					");

			fflush(stdout);

			printf("%s", gtOP_buffer);
			printf(")\n );\n\n</script>\n");
			fflush(stdout);

			free(gtOP_buffer);
		}
		MBE_FILE_CLOSE_(handle2);
		MBE_FILE_CLOSE_(handleGT);
	}

	return(rc);	
}
//**************************************************************************
short Lista_Impianti_MGT()
{
	short		handleImp = -1;
	short		handleMgt = -1;
	short		rc = 0;
	short		nConta = 0;
	short		buffer_size = 0;
	char		sTmp[500];
	char		stringa[1024];
	short		is_AltKey;
	short		nCountRead=0;
	char		*mgt_buffer;
	
	du_mgt_rec_def		mgt_record;
	du_mgtr_rec_def		mgtR_record;
	du_impianti_rec_def impianti;
	du_impianti_key_def key_impianti;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));
	memset(&mgtR_record, ' ', sizeof(du_mgtr_rec_def));
	memset(&impianti, ' ', sizeof(du_impianti_rec_def));

	key_impianti.pcf = 0;
	key_impianti.pc = 0;

	mgt_buffer = (char *)calloc(16384, 1);
	buffer_size++;

	/********************************
	* Apro il file 
	*********************************/
	rc = Apri_File(acFileImpianti, &handleImp, 1, 1);
	if (rc == 0)
		rc = Apri_File(acFileMGT, &handleMgt, 1, 1);
	
	// carico lista IMPIANTI
	if (rc == 0)
	{
		printf("	<!-- carica array con gli impianti -->");
		printf("<script language='JavaScript'>\n");
		printf("var aImpianti = new Array(\n\
					new Option(\"(All )\",' ')\n\
					,new Option(\"(None )\",'----')\n\
				");
		fflush(stdout);

		rc = MBE_FILE_SETKEY_( handleImp,(char *) &key_impianti, sizeof(du_impianti_key_def), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileImpianti);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
				rc = MBE_READX( handleImp, (char *) &impianti, (short) sizeof(du_impianti_rec_def) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileImpianti);
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					//***********************************************************************************************
					// ricerco MGT e scrivo un array x lista MGT
					/*  ricerca  per chiave alternata*/
					is_AltKey = 1;
					rc = MBE_FILE_SETKEY_( handleMgt,(char *)&impianti, 4, is_AltKey, GENERIC, 0);
					/* errore */
					if (rc != 0)
					{
						sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileMGT);
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						break;
					}
					nConta = 0;
					while ( 1 )
					{
						memset(stringa, 0, sizeof(stringa));
						/*******************
						* Leggo il record
						*******************/
						if (s_mgt_by_range == 0) //struttura Italia
							rc = MBE_READX( handleMgt, (char *) &mgt_record, (short) sizeof(du_mgt_rec_def), &nCountRead );
						else	
						{
							// struttura brasile in questo caso controllo se i caratteri letti corrispondono alla
							// dimensione della struttura, perchè stru mgtr è maggiore della stru mgt.
							rc = MBE_READX( handleMgt, (char *) &mgtR_record, (short) sizeof(du_mgtr_rec_def), &nCountRead );
							if ( (rc == 0) &&  (sizeof(du_mgtr_rec_def) != nCountRead))
							{
								//chiudi la parentesy dell'array
								printf( ");\n</script>\n");

								sprintf(sTmp, "Error (%d) in reading file [%s]: struct BRA (read:%d; stru:%d)",
										rc, acFileMGT, nCountRead, sizeof(du_mgtr_rec_def));
								log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								return(2);	
							}
						}
						/* errore... */
						if (rc != 0)
						{
							if (rc != 1)
							{
								//chiudi la parentesy dell'array
								printf( ");\n</script>\n");

								sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileMGT);
								log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
							}
							else
							{
								rc = 0;
							}
							break;
						}
						/* record TROVATO */
						else  /* readx ok */
						{
							//if(nConta == 0)
							//{
							//	strcpy(stringa, ",new Array(new Option('(All)','  ')\n");
							//}

							//strcat(stringa, "\n, new Option(");
							//if (s_mgt_by_range == 0) //struttura Italia
							//	sprintf(stringa+strlen(stringa), "'%.16s','%.16s')", mgt_record.mgt, mgt_record.mgt);
							//else
							//	sprintf(stringa+strlen(stringa), "'%.16s','%.16s')", mgtR_record.mgt_ini, mgtR_record.mgt_ini);

							//// se il buffer +stringa da sc
							//if(strlen(mgt_buffer) + strlen(stringa) > (16384 * buffer_size)-35)
							//{
							//	buffer_size++;
							//	mgt_buffer = (char *)realloc(mgt_buffer, (16384 * buffer_size));
							//	if (mgt_buffer == NULL)
							//	{
							//		printf("MGT buffer reallocation failed !!!");
							//		exit(1);
							//	}
							//}
				
							//sprintf(mgt_buffer+ strlen(mgt_buffer), "%s", stringa);
							nConta++;
						}
					}//fine while MGT
					//inserisco gli impianti che hanno almenu un MGT
					if(nConta != 0)
						printf( ",   new Option(\"(%.8s) %.30s\",\"%d;%d;%.8s\")\n",	impianti.short_desc,
																				impianti.description,
																				impianti.primarykey.pcf,
																				impianti.primarykey.pc,
																				impianti.short_desc);
					fflush(stdout);

				}//fine read OK impianti

			}/* while impianti*/
		}
		MBE_FILE_CLOSE_(handleImp);
		MBE_FILE_CLOSE_(handleMgt);
					
		//chiudi la parentesy dell'array
		printf( ");\n</script>\n");
		fflush(stdout);

		free(mgt_buffer);
	}

	return(rc);	
}

//**********************************************************************************************************
//key cc+codop
//**********************************************************************************************************
short Carica_Array_GT(short handle,  char *acCC_COd)
{
	short		rc = 0;
	short		nConta = 0;
	short		is_AltKey;
	char		sTmp[500];
	char		acKey[18];
	char		stringa[1024];

	t_ts_opergt_record oper_GT;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acKey, ' ', sizeof(acKey));

	memcpy(acKey, acCC_COd, strlen(acCC_COd));

	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), is_AltKey, GENERIC, 0);
	/* errore */
	if (rc != 0)
	{
		printf(")\n );\n\n</script>\n");
		fflush(stdout);

		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileOperGT_Loc);
		log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		nConta = 0;
		while ( 1 )
		{
			memset(stringa, 0, sizeof(stringa));
			/*******************
			* Leggo il record
			*******************/
			rc = MBE_READX( handle, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperGT_Loc);
					log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);

					printf(")\n );\n\n</script>\n");
					Display_Message(1, "", sTmp);
				}
				else
				{
					if(nConta == 0) // non ci sono gt associati 
					{
						//strcpy(stringa, "\n new Array(new Option('(All)','  ') ");
					}
					strcat(stringa, ")\n");

					sprintf(gtOP_buffer+ strlen(gtOP_buffer), "%s", stringa);
					rc = 0;
				}
				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				if(nConta == 0)
				{
					//strcpy(stringa, ")\n new Array(new Option('(All)','  ')\n");
				}

				memset(sTmp, 0, sizeof(sTmp));
				memcpy(sTmp, oper_GT.gt, sizeof(oper_GT.gt));
				AlltrimString(sTmp);

				strcat(stringa, "\n, new Option(");
				sprintf(stringa+strlen(stringa), "'%s','%s')", sTmp, sTmp);	
				// se il buffer +stringa da sc
				if(strlen(gtOP_buffer) + strlen(stringa) > (16384 * buffer_size_GT)-100)
				{
					buffer_size_GT++;
					gtOP_buffer = (char *)realloc(gtOP_buffer, (16384 * buffer_size_GT));
					if (gtOP_buffer == NULL)
					{
						printf("MGT buffer reallocation failed !!!");
						exit(1);
					}
				}
				sprintf(gtOP_buffer+ strlen(gtOP_buffer), "%s", stringa);
				nConta++;
			}
		}/* while (1) */
	}

	return(rc);	
}

//************************************************************************************************
short Carica_Lista_Paesi(void)
{
	short		handle2 = -1;
	short		rc = 0;
	short		nChiave = 0;
	char		sTmp[500];
	char		acDenPa[100];
	char		*ptr_PA;
	char		*ptr_CC;
	char		acCC[10];

	t_ts_paesi_record record_paesi;

	//Creare la listaPaesi:
	listaPaesi = avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle2, 1, 1);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, (char *) &nChiave, sizeof(nChiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
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
				rc = MBE_READX( handle2, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc);
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					//Aggiungere un elemento alla listaPaesi:
					memset(acDenPa, 0, sizeof(acDenPa));
					memset(acCC, 0, sizeof(acCC));
					sprintf(acDenPa, "%*s", LEN_GRP, record_paesi.den_paese);
					AlltrimString(acDenPa);
					ptr_PA = malloc((strlen(acDenPa)+1)*sizeof(char));
					strcpy(ptr_PA, acDenPa);
					//ptr_CC = malloc(sizeof(short));

					sprintf(acCC, "%.8s", record_paesi.paese);
					AlltrimString(acCC);

					ptr_CC = malloc((strlen(acCC)+1)*sizeof(char));
					strcpy(ptr_PA, acDenPa);
					strcpy(ptr_CC, acCC);
		
					if (avlAdd(listaPaesi, ptr_CC, ptr_PA) == -1)
					{
						//sprintf(sTmp, "la chiave %s esiste già !!!", chiave);
						//Display_Message(1, "PAESI DB: View Records - Operation result", sTmp, 0);
					}
				}
			}/* while (1) */

		}

		MBE_FILE_CLOSE_(handle2);
	}

	return(rc);	
}

//******************************************************************************************************
short scrivi_PreSteering_remoto(short handleDB, t_ts_psrule_record *record_psrule, t_psrule_key *keyPS, short nOperation )
{
	short	rc = 0;
	char 	sTmp[500];
	short	lenKey = 79;

	t_ts_psrule_record record_psrule_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)  /// MODIFICA E CANCELLAZIONE
	{
		rc = MBE_FILE_SETKEY_( handleDB, (char *) keyPS, (short) lenKey, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFilePreRules_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &record_psrule_tmp, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFilePreRules_Rem);
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_psrule, (short) sizeof(t_ts_psrule_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s]", rc, acFilePreRules_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) record_psrule, (short) sizeof(t_ts_psrule_record) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Record already exist in REMOTE DB  [%s]", acFilePreRules_Rem);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFilePreRules_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_psrule, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] ", rc, acFilePreRules_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}

		}
	}
	return(rc);
}

// ***************************************************************************************************
//  viene caricata una pagina csv  Content-type: text/csv
// in questo modo non viene creato nessun file su oss/guadian.
// è il browser che crea il csv. [Content-Disposition: attachment; filename=PRE-steering-rules.csv]
// ***************************************************************************************************
void Prepara_Download()
{
	short		handle = -1;
	char		sTmp[500];
	char		buf_DownLoad[200000];
	char		acGiorni[10];
	char		acCC[10];
	short		rc = 0;
	short		lenKey = 0;  //primo campo numerico
	char		*ptrPaese;

	t_ts_psrule_record record_psrule;
	t_psrule_key keyPS;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));
	memset(&keyPS, ' ', sizeof(t_psrule_key));
	memset(buf_DownLoad, 0, sizeof(buf_DownLoad));

	rc= Carica_Lista_Paesi();
	if(rc != 0)
		return;

	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 0);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) in opening local file [%s]", rc, acFilePreRules_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return;
	}

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &keyPS, (short) lenKey, 0, APPROXIMATE);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey local file [%s]", rc, acFilePreRules_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			return;
		}
		/* tutto ok */
		else
		{
			//scrittura caratteri BOM per indicare a exel il formato UTF8
			sprintf(buf_DownLoad, "%c%c%c", 0xEF, 0xBB, 0xBF);
			sprintf(buf_DownLoad+strlen(buf_DownLoad),"HLR System;CC;Country;Operator Code;GT;Time from;Time to;Days;Imsi WL;Status;Map ErrCode;LTE ErrCode\n");

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading local file [%s];\n", rc, acFilePreRules_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						return;
					}
					else
						rc = 0;

					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// non visualizzo il record con key '*'
					if (memcmp(record_psrule.mgt, "********************", 16))
					{
						// preparo i gg settimana
						// MAIUSCOLO è il gg inserito (per cui il profilo è valido)
						// Minuscolo gg non attivo
						strcpy(acGiorni, "mtwtfss");
						if( record_psrule.gg_settimana[1] == 'X' )
							acGiorni[0] = 'M';
						if( record_psrule.gg_settimana[2] == 'X' )
							acGiorni[1] = 'T';
						if( record_psrule.gg_settimana[3] == 'X' )
							acGiorni[2] = 'W';
						if( record_psrule.gg_settimana[4] == 'X' )
							acGiorni[3] = 'T';
						if( record_psrule.gg_settimana[5] == 'X' )
							acGiorni[4] = 'F';
						if( record_psrule.gg_settimana[6] == 'X' )
							acGiorni[5] = 'S';
						if( record_psrule.gg_settimana[0] == 'X' )
							acGiorni[6] = 'S';

						/*************************************
						* Scrive il record nel file x download
						**************************************/

						memset(acCC, 0, sizeof(acCC));
						memcpy(acCC, record_psrule.paese, sizeof(record_psrule.paese));
						AlltrimString(acCC);
						ptrPaese= avlFind(listaPaesi, acCC);
						if(ptrPaese != NULL)

						sprintf(buf_DownLoad+strlen(buf_DownLoad), "%d-%d %.8s;%.8s;%s;%.10s;%.24s;%.5s;%.5s;%s;%s;%s;%d;%d\n",
										(record_psrule.pcf == 8224) ? 0 : record_psrule.pcf,
										(record_psrule.pc == 8224) ? 0 : record_psrule.pc,
										record_psrule.descr,
										record_psrule.paese,
										(ptrPaese != NULL) ? ptrPaese : " ",
										record_psrule.cod_op,
										record_psrule.gt,
										record_psrule.fascia_da,
										record_psrule.fascia_a,
										acGiorni,
										(record_psrule.imsi_white_list_enabled == '1' ? "Yes" : "No"),
										(record_psrule.stato == '1' ? "On" : "Off"),
										record_psrule.map_reject_code,
										record_psrule.lte_reject_code);


					}
				}
			}/* while (1) */

			MBE_FILE_CLOSE_(handle);
		}
	}

	if(rc == 0)
	{
		// ****************************************************************************
		// definisco il nome e formato del file da scaricare
		// ****************************************************************************
		printf("Content-Disposition: attachment; filename=PRE-steering-rules.csv\n");
		printf("Content-type: text/csv\n\n");

		//stampo il contenuto
		printf("%s", buf_DownLoad);
	}


	return;
}
//**************************************************************************************

