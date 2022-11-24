/*----------------------------------------------------------------------------
*   PROGETTO : Imsi
*-----------------------------------------------------------------------------
*
*   File Name       : imsi.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione Imsi DB
*   -----------
*------------------------------------------------------------------------------
*   Funzioni contenute
*   ------------------
*
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_13FEB2019_KTSTEA10_01_AEA() {};
#elif (_TNS_X_TARGET)
T0000L16_13FEB2019_KTSTEA10_01_AEA() {};
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

#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"
#include "sspfunc.h"
#include "ds.h"
#include "cgi.h"

/*------------- PROTOTIPI -------------*/
void 	Display_Search();
void 	Display_Esito(short tipo);
void 	Maschera_Modifica(short tipo);
void 	Display_DatiPrecedenti();
void 	Delete_Dati();
void 	Lettura_Variabili(t_ts_imsi_record *record_imsi);
void 	Aggiorna_Dati(short tipo);
short 	Lista_Operatori( void);
void 	Leggi_User_daSQL(short userVal);

/*******************************/
exec sql begin declare section;

	exec sql invoke =USRDESC	as usrdesc_struct;
	struct usrdesc_struct		usrdesc;

exec sql end declare section;

short sqlcode;

exec sql include sqlca;


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

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));

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

	if ( (wrk_str = cgi_param( "DBIMSI" ) ) != NULL )
		strcpy(acParamIMSI, wrk_str);
	else
	{
		Display_Message(-1, "", "DBIMSI");
		exit(0);
	}

	/*--------------------------------
	   Init per LOG Sicurezza
	 --------------------------------*/
	memset(&log_spooler, 0, sizeof(log_spooler));
	if ( InitSLOG() )
		return(0);
	sprintf(log_spooler.NomeDB, "IMSI");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if ( (wrk_str = cgi_param( "OPERATION" ) ) != NULL )
		strcpy(sOperazione, wrk_str);


	//-------------------------------- TIPO OPERAZIONE -----------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Display ",gUtente, gIP);
		Display_Search();
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Window Modify ",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Window New ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Modify")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Update ",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Insert ",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi DB - Delete ",gUtente, gIP);
		Delete_Dati();
	}

	log_close();

return(0);
}


/******************************************************************************/
void Display_Search()
{
	
	Display_TOP("");
	printf("<BR><BR><BR><CENTER>\n");
	printf("<FORM METHOD=POST ACTION='%s' NAME='cerca' onsubmit='return CheckCerca()'>\n\
			<INPUT TYPE='hidden' name='OPERATION' value='MODY' >\n\
			<INPUT TYPE='hidden' name='DBIMSI' value='%s' >\n", gName_cgi, acParamIMSI);

	printf("<B>Imsi: </B>");
	printf("<INPUT TYPE='text' NAME='IMSI' class='numeric' size='16' maxlength ='15' >\n");
	printf("&nbsp;&nbsp;<INPUT TYPE='submit' value='Search' ></FORM>\n");

	printf("<BR>\n");
	printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Imsi' onclick=\"javascript:location='%s?OPERATION=NEW&DBIMSI=%s'\" >\n", gName_cgi, acParamIMSI);
	printf("</CENTER>\n");

	fflush(stdout);

	Display_BOTTOM();

	return;
}

/*******************************************************************************/
void Display_Esito(short tipo)
{
	Display_TOP("");

	printf("<BR><BR><BR><CENTER><B>\n");
	if(tipo == UPD)
		printf("Record updated successfully");
	else if(tipo == INS)
		printf("Record inserted successfully");
	else if(tipo == DEL)
		printf("Record deleted successfully");

	printf("</B><BR><BR>\n");
	printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='OK' \
					onclick=\"javascript:location='%s?DBIMSI=%s'\" >\n", gName_cgi, acParamIMSI);
	printf("</center>");
	Display_BOTTOM();
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
	int			i;
	char		ac_Chiave[16];
	char		sTipo[20];
	char		strdata[25];
	char		acImsi_girato[20];
	char		acImsi_dritto[20];
	char		acDisable[20];

	t_ts_imsi_record record_imsi;

	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));
	memset(ac_Chiave,     ' ', sizeof(ac_Chiave));
	memset(acImsi_girato,  0, sizeof(acImsi_girato));
	memset(acImsi_dritto,  0, sizeof(acImsi_dritto));

	record_imsi.num_ts = 0;
	record_imsi.timestamp = 0;
	record_imsi.last_ts_op = 0;
	record_imsi.init_ts_tmax = 0;
	record_imsi.num_ts_tmax = 0;

	record_imsi.num_lu = 0;
	record_imsi.last_lu_err = 0;

	memset(sTmp, 0, sizeof(sTmp));
	
	if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(acImsi_dritto, wrk_str);
		// giro l'Imsi
		AlltrimString(acImsi_dritto);
		Reverse(acImsi_dritto, acImsi_girato);

		memcpy(ac_Chiave, acImsi_girato, strlen(acImsi_girato));
	}
	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileImsi, &handle, 1, 1);
	if (rc != 0)
		log(LOG_ERROR, "%s;%s; Error in opening file %s", gUtente, gIP, acFileImsi);

	if (rc == 0 && tipo == UPD)
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened", gUtente, gIP, acFileImsi);

		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, " Error (%d) in reading (file_setkey) file [%s] ", rc, acFileImsi);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			return;
		}
		/* tutto ok */
		else
		{
			rc = MBE_READX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
			/* errore... */
			if ( rc != 0)
			{
				if(rc == 1)
					sprintf(sTmp, " IMSI [%s] not found ",  acImsi_dritto);
				else
					sprintf(sTmp, " Error (%d) in reading file [%s] ", rc, acFileImsi);

				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}

		MBE_FILE_CLOSE_(handle);
		log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFileImsi);
	}			
		
	if(rc == 0 )
	{
		if (tipo == UPD)
		{
			sprintf(sTmp, "IMSI DB - Modify");
			strcpy(sTipo, "Modify");
			strcpy(acDisable, "Disabled");
		}
		else
		{
			sprintf(sTmp, "IMSI DB - New record");
			strcpy(sTipo, "Insert");
			strcpy(acDisable, "  ");
		}

		Display_TOP("");
		printf("<br><br>\n");

		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<form method='POST' action='%s' name='inputform' onsubmit=\"return CheckImsi('%d')\">\n", gName_cgi, tipo);
		printf("<INPUT TYPE='hidden' name='DBIMSI' value='%s' >\n", acParamIMSI  );
		printf("<fieldset><legend>%s&nbsp;</legend>\n", sTmp);
		printf("<center>");

		printf("<TABLE width = 100%% cellspacing=10 border=0>\n\
				<TR>\n");
		fflush(stdout);

		if(record_imsi.status == '1')
		{
			printf("<td colspan=6 align='center'><font color='red'>IMSI is in WHITE LIST</font></td>");
			printf("</tr><tr>\n");
		}

		printf("<TD align=right><b>IMSI:</b></TD>\n");
		printf("<TD align=left><input type='text' name='IMSI' size='20' MAXLENGTH=15 class='numeric' value='%s' %s></TD>\n", acImsi_dritto, acDisable);

		if (tipo == INS)
		{
			rc = Lista_Operatori();

			printf("<td align='right'><b>Country:</b></td>\n\
					<td align='left' colspan='1'>\n\
					<select name='countrySelect' STYLE='width:360px' class='chosen-select'  onChange=\"setMNC(selectedIndex); abilita_campi(0)\" %s></select>\n\
					</td>\n", acDisable);

			printf("<td align='right'><b>Roaming Operator:</b></td>\n\
					<td align='left' colspan='1'>\n\
					<select name='operatorSelect' STYLE='width:360px' class='chosen-select'  %s ></select>\n\
					<TD ><input TYPE='hidden' name='fOperator'  value='' >\n\
					</td>\n", acDisable);
			printf("<script> setMCC(); setMNC(0);</script>");
		}
		else
		{
			printf("<td align='right'><b>Country Code:</b></td>\n");
			printf("<TD align=left>%.8s</TD>\n", record_imsi.paese);
			printf("<TD align=right><b>Roaming Operator:</b></TD>\n");
			printf("<TD align=left>%.10s</TD>\n", record_imsi.cod_op);
			printf("</tr><tr>\n");
			printf("<td colspan='6'><hr id='hrBlue'></td>\n");

		}
		printf("</tr>\n");
		printf("<tr>\n");

		printf("<TD align=right><b>MSISDN:</b></TD>\n");
		printf("<TD align=left><input type='text' name='MSISDN' size='20' MAXLENGTH=15 class='numeric' value='%s'></TD>\n", GetStringNT(record_imsi.msisdn,16) );

		printf("<TD align=right><b>User type:</b></TD>\n");
		printf("<TD ALIGN=left><select NAME='USER' class='chosen-select'  style='width:360px'>\n");

		Leggi_User_daSQL(record_imsi.user_type);

		printf( "</select>\n</TD>\n" );

		printf("<TD align=right><b>Home Operator:</b></TD>\n");
		printf("<TD ALIGN=left><select NAME='OPER' class='chosen-select'  style='width:150px'>\n");
		printf( "<script language='JavaScript'>\n\
				List_Opers('%c', 'inputform.OPER');\n\
			</script>\n</TD>\n", record_imsi.operator);

		printf("</tr><tr>\n");
		fflush(stdout);
		
		//**************************** imei **************************
		printf("<TD align=right><b>IMEI:</b></TD>\n");
		printf("<TD align=left><input type='text' name='IMEI' size='20' MAXLENGTH=15 VALUE='%s' class='numeric'></TD>\n",
				GetStringNT(record_imsi.imei, 15));
		//**************************** IMEI INFO **************************
		printf("<TD align=right><b>IMEI Info:</b></TD>\n\
			   <TD align=left>\n\
			   <SELECT NAME='IMEI_STATE' class='chosen-select' style='width:360px'>\n\
			   <option value=' '>IMEI not verified</option>\n");
		printf("<option value='0' ");
		if (record_imsi.imei_info[0] == '0')
			printf(" selected ");
		printf(">IMEI not found, Default steering scheme</option>\n");
		printf("<option value='1' ");
		if (record_imsi.imei_info[0] == '1')
			printf(" selected ");
		printf(">IMEI found, Specific steering scheme</option>\n");
		printf("<option value='2' ");
		if (record_imsi.imei_info[0] == '2')
			printf(" selected ");
		printf(">IMEI found, Steering not possible</option>\n");

		printf("</select></TD>\n");

		//************************ LAC *******************************
		if(tipo == UPD )
		{
			if(record_imsi.lac == 8224)
				record_imsi.lac = 0;

			printf("<TD align=right><b>Location Area Code (LAC):</b></TD>\n");
			printf("<TD align=left>%d",record_imsi.lac);
		}
		//**************************************************************

		printf("</tr><tr>\n");

		//***************  TS + TIMESTAMP *********************************
		if (record_imsi.num_ts == 8224)
				record_imsi.num_ts = 0;
		printf("<TD align=right><b>#TS per Country:</b></TD>\n");
		printf("<TD align=left><input type='text' name='NUM_TS' size='5' MAXLENGTH=2 VALUE='%d' class='numeric'></TD>\n",
				record_imsi.num_ts);

		printf("<TD align=right><b>Timestamp:</b></TD>\n");

		memset(strdata, 0, sizeof(strdata));
		TS2string(strdata, record_imsi.timestamp);

		printf("<TD><input TYPE='text' SIZE='20' MAXLENGTH='19' NAME='TIMESTAMP' value='%s' class='datetimepic' >\n"
				, strdata);
		printf("&nbsp;(gg/mm/yyyy hh:mm:ss)\n");

		printf("</TD>\n");
		fflush(stdout);
		//************************ Cell *******************************
		if(tipo == UPD )
		{
				if(record_imsi.ci_sac == 8224)
					record_imsi.ci_sac = 0;

			printf("<TD align=right><b>Service Area Code or Cell ID:</b></TD>\n");
			printf("<TD align=left>%d",record_imsi.ci_sac);
		}
		//**************************************************************

		printf("</tr><tr>\n");

		//************************ Numero LU + LU errore + Dta LU **************************
		if (record_imsi.num_lu == ' ')
			record_imsi.num_lu = 0;
		printf("<TD align=right><b>Num. LU:</b></TD>\n");
		printf("<TD align=left><input type='text' name='NUM_LU' size='5' MAXLENGTH=1 VALUE='%d' class='numeric' ></TD>\n",
				record_imsi.num_lu);

		if (record_imsi.last_lu_err == 8224)
			record_imsi.last_lu_err = 0;
		printf("<TD align=right><b>Last Error LU:</b></TD>\n");
		printf("<TD align=left><input type='text' name='ERROR_LU' size='5' MAXLENGTH=5 VALUE='%d' class='numeric' ></TD>\n",
				record_imsi.last_lu_err);

		printf("</tr><tr>\n");
		printf("<TD>&nbsp;</TD>\n");
		printf("<TD>&nbsp;</TD>\n");
		
		printf("<TD align=right><b>Last LU:</b></TD>\n");

		memset(strdata, 0, sizeof(strdata));
		TS2string(strdata, record_imsi.last_ts_op);

		printf("<TD><input TYPE='text' SIZE='20' MAXLENGTH='19' NAME='LAST_TS' value='%s' class='datetimepic'>\n"
				, strdata);
		printf("&nbsp;(gg/mm/yyyy hh:mm:ss)\n");

		printf("</TD>\n");
		fflush(stdout);

		printf("</tr><tr>\n");
		//**************************** Num TMAX + Timestamp **************************
		if (record_imsi.num_ts_tmax == 8224)
			record_imsi.num_ts_tmax= 0;
		printf("<TD align=right><B>Tmax attempt:</B></TD>\n\
				<TD align=left><input type='text' name='TMAX' size='5' MAXLENGTH=2 VALUE='%d' class='numeric' ></TD>\n",
				record_imsi.num_ts_tmax);

		printf("<TD align=right><b>Tmax Date:</b></TD>\n");

		memset(strdata, 0, sizeof(strdata));
		TS2string(strdata, record_imsi.init_ts_tmax);

		printf("<TD><input TYPE='text' SIZE='20' MAXLENGTH='19' NAME='TMAX_TS' value='%s'  class='datetimepic'>\n"
				, strdata);
		printf("&nbsp;(gg/mm/yyyy hh:mm:ss)\n");

		printf("</TD>\n");
		fflush(stdout);

		printf("</tr><tr>\n");
		//**************************** status **************************
		// NON PUò ESSERE MODIFICATO
		printf("<TD align=right><b>Status:</b></TD>\n\
			   <TD align=left>\n\
			   <SELECT NAME='STATUS' class='noSearch' style='width:150px' DISABLED>\n\
			   <option value='0' ");
		if (record_imsi.status == '0')
			printf(" selected ");
		printf(">No Steering</option>\n");
		printf("<option value='1' ");
		if (record_imsi.status == '1')
			printf(" selected ");
		printf(">White List</option>\n");
		printf("<option value='2' ");
		if (record_imsi.status == '2')
			printf(" selected ");
		printf(">Steering</option>\n");
		printf("<option value='3' ");
		if (record_imsi.status == '3')
			printf(" selected ");
		printf(">Black List</option>\n");
		printf("<option value='4' ");
		if (record_imsi.status == '4')
			printf(" selected ");
		printf(">Border Steering</option>\n");

		printf("</select></TD>\n");
		printf("</tr><tr>\n");

		//**************************** TMAX **************************
		if (record_imsi.imei_info[1] == ' ')
			record_imsi.imei_info[1]= 0;

		printf("<TD align=right><B>Tmax attempt Allowed:</B></TD>\n\
				<TD align=left><input type='text' name='IMEI_INFO1' size='2' MAXLENGTH=1 VALUE='%d' class='numeric' \
							   onkeyup=\"abilitaimei(this.value)\" ></TD>\n",
				record_imsi.imei_info[1]);

		printf("</tr><tr>\n");


		printf("<TD align=right><B>Num LU Allowed: </B></TD>\n");

		printf("<TD align=left COLSPAN=5>\n");

		for(i=2; i<=10; i++)
		{
			if (record_imsi.imei_info[i] == 0 || record_imsi.imei_info[i] == ' ')
				record_imsi.imei_info[i]= 1;

			printf("&nbsp;&nbsp;<B>%d: </B>\n",i-1);
			printf("<input type='text' name='IMEI_INFO%d' size='2' MAXLENGTH=1 VALUE='%d'  class='numeric' >\n",
					i, record_imsi.imei_info[i]);
		}

		printf("</tr><tr>\n");
		fflush(stdout);

		//************************ TRACE LEVEL *******************************
		printf("<TD align=right><b>Trace Level:</b></TD>\n");
		printf("<TD align=left><select name='TRACE_L' class='noSearch' style='width:150px'>\n\
				<option value = ' '>Default</option>\n\
				<option value = '1'");
		if (record_imsi.trace_level == 1)
			printf(" selected ");
		printf(">Error</option>\n\
				<option value = '5' ");
		if (record_imsi.trace_level == 5)
			printf(" selected ");
		printf(">Warning</option>\n\
			<option value = '9' ");
		if (record_imsi.trace_level == 9)
			printf(" selected ");
		printf(">Info</option>\n\
			<option value = '10' ");
		if (record_imsi.trace_level == 10)
			printf(" selected ");
		printf(">Debug</option>\n");

		printf("</select></TD>\n");
		printf("</tr>\n");
		fflush(stdout);

		printf("</TABLE><br>\n" );
		printf("</center>");
		printf("</fieldset>\n");
		printf("<CENTER>\n");
		fflush(stdout);

		printf("<SCRIPT LANGUAGE='JavaScript'>\n\
				abilitaimei(%d);\n\
				</SCRIPT>", record_imsi.imei_info[1]);

		printf("<BR>\n");

		if(tipo == UPD )
		{
			printf("<INPUT TYPE='hidden' name='IMSI' value='%.16s' >\n",ac_Chiave);
			printf("<INPUT TYPE='hidden' name='countrySelect' value='%.8s' >\n",record_imsi.paese);
			printf("<INPUT TYPE='hidden' name='operatorSelect' value='%.10s' >\n",record_imsi.cod_op);
		}
		printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='Return' \
				onclick=\"javascript:location='%s?DBIMSI=%s'\" >\n", gName_cgi, acParamIMSI);

		printf("<input type='submit' icon='ui-icon-check'  value='%s' name='OPERATION' >\n", sTipo);
		printf("<input type='reset' icon='ui-icon-arrowrefresh-1-n' value='Reset' name='B2'>\n");

		if(tipo == UPD && record_imsi.status != '1') // se modifica inserisco bottone cancella
			printf("<input type='button' icon='ui-icon-trash' value='Delete' onclick=\"javascript:onclickdelete('%s?OPERATION=Delete&IMSI=%.16s&DBIMSI=%s', 'Imsi: [%.15s]');\" title='Delete'>",
					gName_cgi, ac_Chiave, acParamIMSI,
					acImsi_dritto);

			printf("</CENTER></form>\n" );

		// inserimento delle finestre di dialogo
		printf("<script>\n");
		printf("    insert_Confirm_Delete();\n");
		printf("</script>\n");


		Display_BOTTOM();
	}
}


//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		ac_Chiave[16];
	char		ac_Imsi[20];
	char		ac_ImsiDritto[50];
	short		handle = -1;
	short		rc = 0;

	t_ts_imsi_record record_imsi;


	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));

	memset(ac_Chiave,   ' ', sizeof(ac_Chiave));
	memset(ac_Imsi,       0, sizeof(ac_Imsi));
	memset(ac_ImsiDritto, 0, sizeof(ac_ImsiDritto));
	memset(sTmp, 0, sizeof(sTmp));

	if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		if(tipo == INS)
		{
			strcpy(ac_ImsiDritto, wrk_str);
			// giro l'Imsi
			AlltrimString(ac_ImsiDritto);
			Reverse(ac_ImsiDritto, ac_Imsi);
			memcpy(ac_Chiave, ac_Imsi, strlen(ac_Imsi));
		}
		else
		{
			memcpy(ac_Chiave, wrk_str, strlen(wrk_str));
			// così utilizzo una sola variabile per scivere il log
			strcpy(ac_ImsiDritto, wrk_str);
			AlltrimString(ac_ImsiDritto);
		}
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Imsi=%s", ac_ImsiDritto);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileImsi, &handle, 1, 1);

	if (rc == 0 && tipo == UPD)
	{
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

		log(LOG_DEBUG, "%s;%s; File %s successfully opened", gUtente, gIP, acFileImsi);

		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);

		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) in reading (file_setkey) file [%s] ", rc, acFileImsi);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading file [%s] ", rc, acFileImsi);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				//aggiorno il record con i dati modificati
				Lettura_Variabili(&record_imsi);

				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in writing file [%s] ", rc, acFileImsi);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handle);
				}
				else
					log(LOG_INFO, "%s;%s UPD Imsi: %s", gUtente, gIP, ac_ImsiDritto);
			}

		}
		MBE_FILE_CLOSE_(handle);
		log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFileImsi);
	}

	if (rc == 0 && tipo == INS)
	{
		strcpy(log_spooler.TipoRichiesta, "INS");			// LIST, VIEW, NEW, UPD, DEL

		record_imsi.num_ts = 0;
		record_imsi.timestamp = 0;
		record_imsi.last_ts_op = 0;
	
		memcpy(record_imsi.imsi, ac_Chiave, sizeof(record_imsi.imsi));
		Lettura_Variabili(&record_imsi);

		rc = MBE_WRITEX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
		/* errore */         
		if (rc)
		{
			if (rc == 10 )
			{
				sprintf(sTmp, " Could not write record in file [%s] : IMSI %s already exist", acFileImsi, ac_ImsiDritto);

				log(LOG_WARNING, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "IMSI DB: - Operation result", sTmp);
			}
			else
			{
				sprintf(sTmp, "Error (%d) in writing file [%s] ", rc, acFileImsi);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else
			log(LOG_INFO, "%s;%s INS Imsi: %s", gUtente, gIP, ac_ImsiDritto);

		MBE_FILE_CLOSE_(handle);
		log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFileImsi);
	}

	if (rc == 0)
		Display_Esito(tipo);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

}
/* --------------------------------------------------------------------------*/
void Delete_Dati()
{
	char		*wrk_str;
	short		handle = -1;
	char		sTmp[500];
	int			nRet = 0;
	int			rc ;
	char		ac_Chiave[16];
	char		ac_ImsiDritto[50];
	t_ts_imsi_record record_appo;


	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_imsi_record));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(ac_ImsiDritto, 0, sizeof(ac_ImsiDritto));

	if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_Chiave, wrk_str, strlen(wrk_str));

	memset(sTmp, 0, sizeof(sTmp));
	memcpy(sTmp, ac_Chiave, sizeof(ac_Chiave));
	// giro l'Imsi
	AlltrimString(sTmp);
	Reverse(sTmp, ac_ImsiDritto);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Imsi=%s", ac_ImsiDritto);
	strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/*******************
	* Apro il file 
	*******************/
	rc = Apri_File(acFileImsi, &handle, 1, 1);
	
	if (rc == 0)
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened", gUtente, gIP, acFileImsi);

		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);

		if (rc == 0)
		{
			/*******************
			* Leggo il record
			*******************/
			rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_imsi_record) );
			
			/* trovato lo cancello */
			if ( !rc)
			{
				rc = MBE_WRITEUPDATEX( handle, (char *) &record_appo, 0 );
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) deleting from file [%s]", rc, acFileImsi);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					nRet = 1;
				}
				else
				{
					log(LOG_INFO, "%s;%s DEL Imsi: %s", gUtente, gIP, ac_ImsiDritto);
				}
			}
			else
			{
				sprintf(sTmp, " Error (%d) in reading file [%s]", rc, acFileImsi);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				nRet = 1;
			}
		}
		else
		{
			sprintf(sTmp, "Error (%d) in reading (file_setkey) file [%s]", rc, acFileImsi);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			nRet = 1;
		}
	}


	MBE_FILE_CLOSE_(handle);
	log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFileImsi);

	if (nRet == 0 )
		Display_Esito(2);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);
}

//***************************************************************************
void Lettura_Variabili(t_ts_imsi_record *record_imsi)
{
	char	*wrk_str;
	char	strdata[20];
	char	sTmp[500];
	char	acImsi_girato[20];
	//char	*pTmp;

	memset(sTmp, 0 , sizeof(sTmp));
	memset(acImsi_girato, 0 , sizeof(acImsi_girato));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	memset(record_imsi->imei, ' ', sizeof(record_imsi->imei));
	if (( (wrk_str = cgi_param( "MSISDN" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_imsi->msisdn, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "OPER" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->operator = wrk_str[0];

	if (( (wrk_str = cgi_param( "USER" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->user_type = (short) atoi(wrk_str);

	if (( (wrk_str = cgi_param( "countrySelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		//memcpy(sTmp, wrk_str, strlen(wrk_str));
		//// prendo la prima parte della stringa fino al ';'
		//pTmp= strtok(sTmp, ";");
		//memcpy(record_imsi->paese, pTmp, strlen(pTmp));
		memcpy(record_imsi->paese, wrk_str, strlen(wrk_str));
	}
	if (( (wrk_str = cgi_param( "NUM_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->num_ts = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "TIMESTAMP" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(strdata, wrk_str);
		record_imsi->timestamp = string2TS(strdata);
	}

	if (( (wrk_str = cgi_param( "LAST_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(strdata, wrk_str);
		record_imsi->last_ts_op = string2TS(strdata);
	}

	memset(record_imsi->cod_op, ' ', sizeof(record_imsi->cod_op));
	if (( (wrk_str = cgi_param( "operatorSelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_imsi->cod_op, wrk_str, strlen(wrk_str));

	memset(record_imsi->imei, ' ', sizeof(record_imsi->imei));
	if (( (wrk_str = cgi_param( "IMEI" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(record_imsi->imei, wrk_str, strlen(wrk_str));
	
	memset(record_imsi->imei_info, 0x00, sizeof(record_imsi->imei_info));
	if (( (wrk_str = cgi_param( "IMEI_STATE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[0] = wrk_str[0];
	if (( (wrk_str = cgi_param( "IMEI_INFO1" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[1] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO2" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[2] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO3" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[3] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO4" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[4] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO5" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[5] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO6" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[6] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO7" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[7] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO8" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[8] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO9" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[9] = (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMEI_INFO10" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->imei_info[10] = (char) atoi(wrk_str);
	
	if (( (wrk_str = cgi_param( "STATUS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->status = wrk_str[0];

	if (( (wrk_str = cgi_param( "NUM_LU" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->num_lu =  (char) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "ERROR_LU" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->last_lu_err =  (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "TMAX" ) ) != NULL ) && (strlen(wrk_str) > 0))
		record_imsi->num_ts_tmax = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "TMAX_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(strdata, wrk_str);
		record_imsi->init_ts_tmax = string2TS(strdata);
	}
	if (( (wrk_str = cgi_param( "TRACE_L" ) ) != NULL ) && (strlen(wrk_str) > 0))
		if (wrk_str[0] == ' ')
			record_imsi->trace_level = wrk_str[0];  // loscrivo come carattere
		else
			record_imsi->trace_level = (char) atoi(wrk_str);
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
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) in reading (file_setkey) file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
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
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
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
						sprintf(chiave, "%.*s%.10s;%.*s%.8s;",	LEN_GRP, record_operatori.den_paese,
																record_operatori.cod_op,
																LEN_GRP, record_operatori.den_op,
																record_operatori.paese);
						AlltrimString(chiave);
						ptr_OP = malloc((strlen(chiave)+1)*sizeof(char));
						strcpy(ptr_OP, chiave);

						memset(acPaese, 0, sizeof(acPaese));
						memcpy(acPaese, record_operatori.paese, 8);
						if(avlAdd(lista_OP, ptr_OP, ptr_OP) == -1)
						{
							//chiave esistente
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
						new Option(\"(Select a Country)\",'ALL')\n\
					");
			fflush(stdout);

			//creo un'altra lista con key = paese e come dati tutti gli OP di quel paese
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
					memcpy(key_PA,  stringa, LEN_GRP);
					AlltrimString(key_PA);
					strcpy(acDati,  stringa+LEN_GRP);

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
						
						printf( ",   new Option(\"%s\",\"%.8s\")\n", stringa, acDati+75 );
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
							 new Array(new Option(' ','ALL')\n");

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

	return(rc);	
}

void Leggi_User_daSQL(short userVal)
{
	char	sTmp[500];

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
				printf("<option value='%d' ",usrdesc.value);
				if(usrdesc.value == userVal)
					printf(" selected ");
				printf(" >[%d] %s</option>", usrdesc.value, usrdesc.description);
			}
		} while ( sqlcode == 0 );
	}

	if ( (sqlcode != SQL_OK) && (sqlcode != SQL_NOT_FOUND) )
	{
		printf( "</select>\n");
		sprintf(sTmp, "Error sql USRDESC: %d", sqlcode);
		Display_Message(1, "", sTmp);
	}

	exec sql close cursore1;

	return;

}
