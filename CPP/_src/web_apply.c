/*----------------------------------------------------------------------------
*   PROGETTO : Applica
*-----------------------------------------------------------------------------
*
*   File Name       : applica.c
*   Ultima Modifica :09/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*  Applica le modifiche apportate agli Operatori, pre steering  e soglie.
*  Aggiorna files guardian  APPLY_PS e APPLY_ST
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

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"
#include "mbedb.h"

/*------------- PROTOTIPI -------------*/
void 	Display_File();
void 	Applica_Modifiche();
char 	*Controlla_OP(char *acData);
char 	*Controlla_NostdTac(char *acData);
char 	*Controlla_HemeNet(char *acData);
short  	Leggi_Date_TS(char *acData_Soglie, char *acData_Soglie_Apply);
void  	Leggi_Date_PS( char *acData_PS, char * acData_PS_Apply);

short 	Aggiorna_PreS_rec_aster(short handle, short handlePre_rem, long long lJTS);

extern void		Leggi_Applica();
extern short	Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo);

short	gnApply;

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sOperazione[100];
	char	sTmp[500];
	short	rc = 0;
	char 	ac_err_msg[255];
    short 	rcSes;

    disp_Top = 0;
	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));
	memset(acFileApply_ST,  0x00, sizeof(acFileApply_ST));
	
	// Returns 1 (OK) o 0 (KO)
	rcSes =  (short) cgi_session_verify(ac_err_msg);
	if (rcSes == 0)
	{
		printf("<br><br><center><font color=red>%s</font>", ac_err_msg);
		fflush(stdout);
		exit(0);
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

	// **************************** Nome della CGI ********************************************
	gName_cgi  = getenv( "SCRIPT_NAME" );

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
	sprintf(log_spooler.NomeDB, "Apply");	// max 20 char

	Lettura_FileIni();

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
		log(LOG_INFO, "%s;%s; Display Apply ",gUtente, gIP);
		Display_File();
	}
	else if (strcmp(sOperazione, "Apply")== 0 )
	{
		Applica_Modifiche();
	}

	log_close();

return(0);
}
//******************************************************************************************************
void Display_File()
{
	short 	rc = 0;
	short	result_OP_ST = 0;
	short	result_OP_PS = 0;
	short	result_ST = 0;
	short	result_PS = 0;
	short	result_Dev_ST = 0;
	short	result_Dev_PS = 0;
	short	result_HN_ST = 0;
	short	result_HN_PS = 0;
	short	result_PS_Load_OP = 0;
	short	result_ST_Load_OP = 0;
	short	result_PS_Load_PS = 0;
	short	result_ST_Load_ST = 0;
	short	result_PS_Load_Dev = 0;
	short	result_ST_Load_Dev = 0;
	short	result_PS_Load_HN = 0;
	short	result_ST_Load_HN = 0;
	short	nLoadST = 0;
	short	nLoadPS = 0;

	char	acData_OP[20];
	char	acData_Soglie_Apply[20];
	char	acData_PS_Apply[20];
	char	acData_Soglie[20];
	char	acData_PS[20];
	char	acData_HomeNet[20];
	char	acData_Device[20];

	memset(acData_OP, 0, sizeof(acData_OP));
	memset(acData_Soglie_Apply, 0, sizeof(acData_Soglie_Apply));
	memset(acData_PS_Apply, 0, sizeof(acData_PS_Apply));
	memset(acData_Soglie, 0, sizeof(acData_Soglie));
	memset(acData_PS, 0, sizeof(acData_PS));
	memset(acData_Device, 0, sizeof(acData_Device));

    Display_TOP("");

  	// Leggo le date dai file guardia  APPLY_PS e APPLY_ST
	Leggi_Applica();

	// Leggo le date del records '*' delle soglie  x l'apply
	rc = Leggi_Date_TS(acData_Soglie, acData_Soglie_Apply);
	if (rc != 0)
		return;

	// Leggo le date del records '*' delle PRE Steering  x l'apply
	Leggi_Date_PS(acData_PS, acData_PS_Apply);
	
	// leggo la data del record '*' del DB operatori 
	Controlla_OP(acData_OP);

	// leggo la data del record '*' del DB device NOSTD-TAC
	Controlla_NostdTac(acData_Device);

	// leggo la data del record '*' del DB home Network (BORDCID)
	Controlla_HemeNet(acData_HomeNet);

	// se la data del rec '*' degli operatori è > data Apply Soglie è da Applicare
	// se la data del rec '*' delle soglie è > data Apply Soglie è da Applicare
	result_OP_ST = (short)memcmp(acData_OP, acData_Soglie_Apply, 14 );
	result_OP_PS = (short)memcmp( acData_OP, acData_PS_Apply, 14 );
	result_ST = (short)memcmp(acData_Soglie, acData_Soglie_Apply, 14 );
	result_PS = (short)memcmp( acData_PS, acData_PS_Apply, 14 );

	result_Dev_ST = (short)memcmp(acData_Device, acData_Soglie_Apply, 14 );
	result_Dev_PS = (short)memcmp(acData_Device, acData_PS_Apply, 14 );
	result_HN_ST = (short)memcmp(acData_HomeNet, acData_Soglie_Apply, 14 );
	result_HN_PS = (short)memcmp(acData_HomeNet, acData_PS_Apply, 14 );

	// ********** KTSTEA10 **********************
	// controllo Load Date Pre/Steering con operators
	result_PS_Load_OP = (short)memcmp(gDataApply_PS, acData_OP, 14 );
	result_ST_Load_OP = (short)memcmp(gDataApply_ST, acData_OP, 14 );

	// controllo Load Date Pre/Steering con pre/steering Tules
	result_PS_Load_PS = (short)memcmp(gDataApply_PS, acData_PS, 14 );
	result_ST_Load_ST = (short)memcmp(gDataApply_ST, acData_Soglie, 14 );

	// controllo Load Date Pre/Steering con Device
	result_PS_Load_Dev = (short)memcmp(gDataApply_PS, acData_Device, 14 );
	result_ST_Load_Dev = (short)memcmp(gDataApply_ST, acData_Device, 14 );

	// controllo Load Date Pre/Steering con Device
	result_PS_Load_HN = (short)memcmp(gDataApply_PS, acData_HomeNet, 14 );
	result_ST_Load_HN = (short)memcmp(gDataApply_ST, acData_HomeNet, 14 );

	// se Load Date Pre e Steering sono maggiori delle altre date significa che i processi
	// hanno ricaricato i DB
	if(result_PS_Load_OP > 0    && result_PS_Load_PS > 0  &&
		result_PS_Load_Dev > 0  && result_PS_Load_HN > 0 )
		nLoadPS = 1;
	if(result_ST_Load_OP > 0    && result_ST_Load_ST > 0  &&
		result_ST_Load_Dev > 0  && result_ST_Load_HN > 0)
		nLoadST = 1;


	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/
	printf("<form method='POST' action='%s' name='inputform'>\n", gName_cgi);
	printf("<BR>");
	printf("<TABLE align=center width ='80%%'  border=0>\n\
			<TR><td align='center' id='fontblue'>\n\
            In case some operator was added to a country belonging to an existing group it is necessary, before applying the new configuration, to update the operators to report the group information.\n");

	printf("<BR><BR>\n");
	printf( "<INPUT TYPE='button' icon='ui-icon-play' VALUE='Update Operators' onClick=\"openWin()\" >\n");
	printf("</td></TR>");

	printf("<TR><td>\n\
			<fieldset><legend> Apply Information &nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='5' cellpadding='5' border=0>\n\
			<TR>\n");
	fflush(stdout);
	
	printf("<td colspan='3' align='center'><TABLE width ='90%%' cellspacing='5' cellpadding='5' border=1 frame=void>\n");
	printf("<td width ='30%%' >&nbsp;</td>\n");
	printf("<td width ='30%%'><B>Apply requested Date</B></td>\n");
	printf("<td width ='30%%'><B>Last Load Date</B></td>\n");
	printf("</TR><TR>");
	printf("<td align='right' ><B>PRE Steering</B></td>\n");
	
	if( acData_PS_Apply[0] != 0 )
	{
		printf("<TD  align='left'>");
		//data rec '*' del DB PRE steering
		printf("%.2s/%.2s/%.4s %.2s:%.2s</font></td>",	acData_PS_Apply+6,
														acData_PS_Apply+4,
														acData_PS_Apply,
														acData_PS_Apply+8,
														acData_PS_Apply+10,
														acData_PS_Apply+12 );
	}
	else
		printf("<TD>&nbsp;</TD>");

	if( gDataApply_PS[0] != 0 )
	{
		printf("<TD  align='left'>");
		// se i processi hanno già ricaricato i DB  non fare controlli per font red
		if(nLoadPS == 0)
		{
			//se data PRE soglie è > data applay_ps indica che va fatta l'applay
			if(result_PS > 0 || result_OP_PS > 0 || result_Dev_PS > 0|| result_HN_PS > 0)
				printf("<font color='red'>");
		}
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	gDataApply_PS+6,
												gDataApply_PS+4,
												gDataApply_PS,
												gDataApply_PS+8,
												gDataApply_PS+10,
												gDataApply_PS+12 );
	}
	else
		printf("<TD>&nbsp;</TD>");

	printf("</TR><TR>");
	printf("<td align='right' ><B>Steering/Threshold</B></td>\n");
	if( acData_Soglie_Apply[0] != 0 )
	{
		printf("<TD  align='left'>");
		// record data '*' x apply che legge il TRS MGR
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_Soglie_Apply+6,
												acData_Soglie_Apply+4,
												acData_Soglie_Apply,
												acData_Soglie_Apply+8,
												acData_Soglie_Apply+10,
												acData_Soglie_Apply+12 );
	}
	else
		printf("<TD>&nbsp;</TD>");

	if( gDataApply_ST[0] != 0 )
	{
		printf("<TD  align='left'>");
		// se i processi hanno già ricaricato i DB  non fare controlli per font red
		if(nLoadST == 0)
		{
			//se data operatori o la data soglie è > della data "soglie apply"
			if(result_ST > 0 || result_OP_ST > 0 || result_Dev_ST > 0|| result_HN_ST > 0)
				printf("<font color='red'>");
		}
		printf("%.2s/%.2s/%.4s %.2s:%.2s</font></td>",	gDataApply_ST+6,
														gDataApply_ST+4,
														gDataApply_ST,
														gDataApply_ST+8,
														gDataApply_ST+10,
														gDataApply_ST+12 );
	}
	else
		printf("<TD>&nbsp;</TD>");
	
	printf("</TR></TD></table>");
	printf("<TR>");
	printf("<TD colspan=3><hr id='hrBlue'></TD>");
	printf("</TR><TR>");
//-------------------------------------------------------------------------------------------------------------------
	printf("<td align='right' width='40%%' ><B>Data Base</B> </td>\n");
	printf("<td align='left' width='40%%'><B>Modify Date</B> </td>\n");
	printf("</TR><TR>");
	printf("<td align='right' width='30%%'>Operators:</td>\n");
	if( acData_OP[0] != 0 )
	{
		printf("<TD align='left'><span ");
		if(result_OP_PS > 0 || result_OP_ST > 0 )
			printf(" id='highlightme' ");

		printf(">");
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_OP+6,
												acData_OP+4,
												acData_OP,
												acData_OP+8,
												acData_OP+10,
												acData_OP+12 );
		printf("</span>");
	}
	else
		printf("<TD width='30%%'>&nbsp;</TD>");

	printf("<td rowspan='5' width='40%%'>\n");

	// se i processi hanno già ricaricato i DB  OK
	if(nLoadPS == 0 || nLoadST == 0)
	{
		//se data soglie è > data applay_st indica che va fatta l'applay
		if(result_ST > 0 || result_OP_ST > 0 || result_OP_PS > 0 || result_PS > 0 ||
			result_Dev_ST > 0|| result_HN_ST > 0 || result_Dev_PS > 0|| result_HN_PS > 0)
			printf("<img src='images/warning.png'  border='0' alt='Apply needed'>\n");
		else
			printf("<img src='images/ok.png' border='0' alt='OK'>\n");
	}
	else
		printf("<img src='images/ok.png' border='0' alt='OK'>\n");

	printf("</TD>");
	printf("</TR><TR>");

	// *******************************************************************************
	printf("<td align='right'>PRE Steering Rules:</td>\n");
	if( acData_PS[0] != 0 )
	{
		printf("<TD align='left'><span ");
		if(result_PS > 0  )
			printf(" id='highlightme' ");

		printf(">");
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_PS+6,
												acData_PS+4,
												acData_PS,
												acData_PS+8,
												acData_PS+10,
												acData_PS+12);
		printf("</span>");
	}
	printf("</TR><TR>");

	// ******************************************************************************
	printf("<td align='right'>Steering Rules:</td>\n");
	if( acData_Soglie[0] != 0 )
	{
		printf("<TD align='left'><span ");
		if(result_ST > 0  )
			printf(" id='highlightme' ");

		printf(">");
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_Soglie+6,
												acData_Soglie+4,
												acData_Soglie,
												acData_Soglie+8,
												acData_Soglie+10,
												acData_Soglie+12);
		printf("</span>");
	}
	printf("</TR><TR>");

	// ******************************************************************************
	printf("<td align='right'>Specific Devices:</td>\n");
	if( acData_Device[0] != 0 )
	{
		printf("<TD align='left'><span ");
		if(result_Dev_ST > 0 || result_Dev_PS > 0 )
			printf(" id='highlightme' ");

		printf(">");
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_Device+6,
												acData_Device+4,
												acData_Device,
												acData_Device+8,
												acData_Device+10,
												acData_Device+12);
		printf("</span>");
	}
	printf("</TR><TR>");

	// ******************************************************************************
	printf("<td align='right'>Home Network Areas:</td>\n");
	if( acData_HomeNet[0] != 0 )
	{
		printf("<TD align='left'><span ");
		if(result_HN_ST > 0 || result_HN_PS > 0 )
			printf(" id='highlightme' ");

		printf(">");
		printf("%.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_HomeNet+6,
												acData_HomeNet+4,
												acData_HomeNet,
												acData_HomeNet+8,
												acData_HomeNet+10,
												acData_HomeNet+12);
		printf("</span>");
	}
	printf("</TR><TR>");

	printf("</TABLE>\n" );
	printf("</fieldset></TD>"); //fieldset 
	printf("</TR><TR>");
	fflush(stdout);
	printf("<td>\n\
			<fieldset><legend> Apply&nbsp;</legend>\n");
	printf("<TABLE width ='80%%' cellspacing=10 border=0 align='center'>\n\
			<TR>\n");	

	//se non c'è da fare l'apply disabilito la check box
	printf("<TD  align='center'><INPUT TYPE='checkbox' Name='APPLY_PS'");
	//if(result_PS <= 0)
	//	printf(" disabled");
	printf("> PRE Steering</td>");

	//se non c'è da fare l'apply disabilito la check box
	printf("<TD  align='center'><INPUT TYPE='checkbox' Name='APPLY_TS'");
	//if(result_ST <= 0)
	//	printf(" disabled");
	printf("> Steering</td>");
	//printf("</TR><TR>");
	
	printf("<td align=right width='30%%'>Apply Time:</td>\n\
			<td align=left><INPUT name='TIME_APPLY' class='datetimepic' value=''>\n\
			&nbsp;(gg/mm/aaaa hh:mm:ss)</td>");

	//		<a href='javascript:cal1.popup();'><img src='images/cal.gif' width='16' height='16' border='0' alt='Click here to pick up the date'></a>

	printf("</TR><TR>");
	printf("</TABLE>\n" );
	printf("</fieldset></TD> ");//fieldset GT

	printf("</TR><TR>");

	if(result_OP_ST <= 0 && result_OP_PS <= 0 && result_ST <= 0 && result_PS <= 0 )
		printf("<TD align='center' id='fontblue'>Apply Steering already done: %.2s/%.2s/%.4s %.2s:%.2s</td>",	acData_Soglie_Apply+6,
																	acData_Soglie_Apply+4,
																	acData_Soglie_Apply,
																	acData_Soglie_Apply+8,
																	acData_Soglie_Apply+10,
																	acData_Soglie_Apply+12 );


	printf("</TR></TABLE>");
	fflush(stdout);

	printf("<BR>");
	printf("<BR>\n");
	printf("<center>\n");

	printf("<input type='submit' icon='ui-icon-circle-check' value='Apply' name='OPERATION' ");
	//if(result_OP_ST <= 0 && result_OP_PS <= 0 && result_ST <= 0 && result_PS <= 0 )
	//	printf(" disabled ");
	printf(">\n");

	printf("</CENTER></form>\n" );

	Display_BOTTOM();

}
//******************************************************************************************************
void Applica_Modifiche()
{
	char		*wrk_str;
	char		acTime_apply[20];
	char		sTmp[500];
	short		handlePre = -1;
	short		handlePre_rem = -1;
	short		handleSoglie_loc = -1;
	short		handleSoglie_rem = -1;
	short		rc = 0;
	long long	lJTSLoc = 0;
	long long	lJTS = 0;

	memset(acTime_apply, 0, sizeof(acTime_apply));
	memset(sTmp, 0, sizeof(sTmp));
	
	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Apply");
	strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;


	if (( (wrk_str = cgi_param( "TIME_APPLY" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		lJTSLoc=string2TS(wrk_str);
		//converto in GMT
		ConvertLocal_To_GMT(&lJTS, lJTSLoc);
	}
	else
	{
		//GMT
		GetTimeStamp(&lJTS);
	}

	if (( (wrk_str = cgi_param( "APPLY_PS" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		rc = Apri_File(acFilePreRules_Loc, &handlePre, 1, 0);
		if (rc)
			log(LOG_ERROR, "%s;%s; Error in opening Local file [%s] :%d",gUtente, gIP, acFilePreRules_Loc, rc);
		else
		{
			rc = Apri_File(acFilePreRules_Rem, &handlePre_rem, 1, 0);
			if (rc)
				log(LOG_ERROR, "%s;%s; Error in opening file Remote [%s] :%d",gUtente, gIP, acFilePreRules_Rem, rc);
		}

		if (rc == 0)
		{		
			rc = Aggiorna_PreS_rec_aster(handlePre, handlePre_rem,  lJTS);
			if (rc == 0)
				log(LOG_INFO, "%s;%s; Apply Pre steering execute",gUtente, gIP);
		}
	}

	if (( (wrk_str = cgi_param( "APPLY_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		/***********************************************************************************
		* IPM KTSTEACS
		* Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
		************************************************************************************/
		rc = MbeFileOpen_nw(acFileSoglie_Loc, &handleSoglie_loc);
		if (rc == 0)
		{
			rc = MbeFileOpen_nw(acFileSoglie_Rem, &handleSoglie_rem);
			if (rc != 0)
			{
				log(LOG_ERROR, "%s;%s; Error in opening remote file %s :%d",gUtente, gIP, acFileSoglie_Rem, rc);
				sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
				Display_Message(0, "", sTmp);
				MBE_FILE_CLOSE_(handleSoglie_loc);
				return;
			}
		}
		else
		{
			log(LOG_ERROR, "%s;%s; Error in opening local file %s :%d",gUtente, gIP, acFileSoglie_Loc, rc);
			sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
			Display_Message(0, "", sTmp);
			return;
		}
		
		if (rc == 0)
			rc = Aggiorna_Soglie_rec_Aster(handleSoglie_loc, handleSoglie_rem, lJTS, 1);
		if (rc == 0)
			log(LOG_INFO, "%s;%s; Apply steering execute",gUtente, gIP);

		MBE_FILE_CLOSE_(handleSoglie_loc);
		MBE_FILE_CLOSE_(handleSoglie_rem);
	}

	if (rc == 0)
	{
		Display_File();
	}
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

}
//*****************************************************************************************
char *Controlla_OP(char *acData)
{
	short		handle = -1;
	short		rc = 0;
	char		acKey[18];
	char		sTmp[500];
	long long	lJTS = 0;
	long long	lJTS_local = 0;

	t_ts_oper_record oper_profile;

	memset(acKey, '*', sizeof(acKey));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 0);
	
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), 0, EXACT, 0);
		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error File_setkey (%s): error %d",gUtente, gIP, acFileOperatori_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d",acFileOperatori_Loc, rc);
			Display_Message(0, "", sTmp);
		}
		else
		{
			rc = MBE_READX( handle, (char *) &oper_profile, (short) sizeof( t_ts_oper_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "%s;%s; Error Readx (%s): error %d",gUtente, gIP, acFileOperatori_Loc, rc);
					sprintf(sTmp, "Readx: error %d", rc);
					Display_Message(0, "", sTmp);
				}
				else
					rc = 0;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				memcpy( acData, oper_profile.den_op, 14 );
				//trasformo la data il LOCAL e poi la riconverto in stringa
				lJTS = stringAAMMGG2TS(acData);
				ConvertGMT_To_Local(&lJTS_local, lJTS);
				memset(acData, 0, sizeof(acData));
				TS2stringAAMMGG(acData, lJTS_local);
			}
		}
		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error open file %s :%d",gUtente, gIP, acFileOperatori_Loc, rc);

	return(acData);
}
//*****************************************************************************************
short  Leggi_Date_TS( char *acData_Soglie, char *acData_Soglie_Apply)
{
	short		handle = -1;
	short		rc = 0;
	char		acKey[LEN_KEY_SOGLIE];
	char		sTmp[500];
	long long	lJTS1 = 0;
	long long	lJTS2 = 0;
	long long	lJTS1_local = 0;
	long long	lJTS2_local = 0;

	t_ts_soglie_record soglie;
	memset(&soglie, ' ', sizeof(t_ts_soglie_record));

	memset(acKey, '*', sizeof(acKey));

	/*******************
	* Apro il file
	*******************/
	rc = MbeFileOpen_nw(acFileSoglie_Loc, &handle);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), 0, EXACT, 0);
		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; File_setkey (%s): error %d",gUtente, gIP, acFileSoglie_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d",acFileSoglie_Loc, rc);
			Display_Message(0, "", sTmp);
		}
		else
		{
		//	rc = MBE_READX( handle, (char *) &soglie, (short) sizeof( t_ts_soglie_record) );
			rc = MbeFileRead_nw( handle, (char *) &soglie, (short) sizeof( t_ts_soglie_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "%s;%s; Error Reading file (%s): error %d",gUtente, gIP, acFileSoglie_Loc, rc);
					sprintf(sTmp, "Error Reading file [%s]: error %d", acFileSoglie_Loc, rc);
					Display_Message(0, "", sTmp);
				}
				else
					rc = 0;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				memcpy( (char *)&lJTS1, (char *)&(soglie.tot_accP), sizeof(long long) );
				memcpy( (char *)&lJTS2, (char *)&(soglie.tot_accT), sizeof(long long) );
				ConvertGMT_To_Local(&lJTS1_local, lJTS1);
				ConvertGMT_To_Local(&lJTS2_local, lJTS2);
				TS2stringAAMMGG(acData_Soglie_Apply, lJTS1_local);
				TS2stringAAMMGG(acData_Soglie, lJTS2_local);
			}
		}
		MBE_FILE_CLOSE_(handle);
    }
	else
	{
		log(LOG_ERROR, "%s;%s; Error in opening local file %s :%d",gUtente, gIP, acFileSoglie_Loc, rc);
		sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
		Display_Message(0, "", sTmp);
	}

	return (rc);
}
//*****************************************************************************************
void Leggi_Date_PS( char *acData_PS, char * acData_PS_Apply)
{
	short		handle = -1;
	short		rc = 0;
	char		acKey[79];
	char		sTmp[500];
	long long	lJTS1 = 0;
	long long	lJTS2 = 0;
	long long	lJTS1_local = 0;
	long long	lJTS2_local = 0;

	t_ts_psrule_record pre_rule;

	memset(&pre_rule, ' ', sizeof(t_ts_psrule_record));

	memset(acKey, '*', sizeof(acKey));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePreRules_Loc, &handle, 1, 0);
	
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey),0, EXACT, 0);
		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; File_setkey (%s): error %d",gUtente, gIP, acFilePreRules_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d",acFilePreRules_Loc, rc);
			Display_Message(0, "", sTmp);
		}
		else
		{
			rc = MBE_READX( handle, (char *) &pre_rule, (short) sizeof( t_ts_psrule_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "%s;%s; Readx (%s): error %d",gUtente, gIP, acFilePreRules_Loc, rc);
					sprintf(sTmp, "Readx: error %d", rc);
					Display_Message(0, "", sTmp);
				}
				else
					rc = 0;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				memcpy( (char *)&lJTS1, (char *)&(pre_rule.ts1), sizeof(long long) );
				memcpy( (char *)&lJTS2, (char *)&(pre_rule.ts2), sizeof(long long) );
				ConvertGMT_To_Local(&lJTS1_local, lJTS1);
				ConvertGMT_To_Local(&lJTS2_local, lJTS2);
				TS2stringAAMMGG(acData_PS_Apply, lJTS1_local);
				TS2stringAAMMGG(acData_PS, lJTS2_local);
			}
		}
		MBE_FILE_CLOSE_(handle);
    }
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s :%d",gUtente, gIP, acFilePreRules_Loc, rc);

	return;
}
//*****************************************************************************************
char *Controlla_NostdTac(char *acData)
{
	short		handle = -1;
	short		rc = 0;
	char		acKey[15];
	char		sTmp[500];
	long long	lJTS = 0;
	long long	lJTS_local = 0;

	t_ts_nostd_tac_record record_nostdtac;

	memset(acKey, '*', sizeof(acKey));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileNostdtac_Loc, &handle, 1, 0);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), 0, EXACT, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey in file [%s]",rc, acFileNostdtac_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
		}
		else
		{
			rc = MBE_READX( handle, (char *) &record_nostdtac, (short) sizeof( record_nostdtac) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileNostdtac_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
				}
				else
					rc = 0;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				memcpy( acData, record_nostdtac.stringa, 14 );
				//trasformo la data il LOCAL e poi la riconverto in stringa
				lJTS = stringAAMMGG2TS(acData);
				ConvertGMT_To_Local(&lJTS_local, lJTS);
				memset(acData, 0, sizeof(acData));
				TS2stringAAMMGG(acData, lJTS_local);
			}
		}
		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error open file %s :%d",gUtente, gIP, acFileNostdtac_Loc, rc);

	return(acData);
}
//************************************************************************************
char *Controlla_HemeNet(char *acData)
{
	short		handle = -1;
	short		rc = 0;
	short		nLenKey = 4;
	char		sTmp[500];
	long long	lJTS = 0;
	long long	lJTS_local = 0;

	struct _ts_border_cells_record record_borderCID;

	/* inizializza la struttura tutta a blank */
	memset(&record_borderCID, ' ', sizeof(struct _ts_border_cells_record));

	record_borderCID.lac = 0;
	record_borderCID.ci_sac = 0;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileBord_CID_Loc, &handle, 1, 0);

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, (char *) &record_borderCID.lac, nLenKey, 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFileBord_CID_Loc);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			rc = MBE_READX( handle, (char *) &record_borderCID, (short) sizeof(struct _ts_border_cells_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileBord_CID_Loc);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
				}
				else
					rc = 0;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				//trasformo la data il LOCAL e poi la riconverto in stringa
				ConvertGMT_To_Local(&lJTS_local, record_borderCID.ts);
				memset(acData, 0, sizeof(acData));
				TS2stringAAMMGG(acData, lJTS_local);
			}
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error open file %s :%d",gUtente, gIP, acFileBord_CID_Loc, rc);

	return(acData);
}
//************************************************************************************
short Aggiorna_PreS_rec_aster(short handle, short handlePre_rem, long long lJTS)
{
	short		rc = 0;
	char		ac_Chiave[79];
	char		sTmp[500];

	t_ts_psrule_record record_psrule;
	t_ts_psrule_record record_psrule_tmp;

	/* inizializza la struttura tutta a blank */
	memset(&record_psrule, ' ', sizeof(t_ts_psrule_record));
	memset(&record_psrule_tmp, ' ', sizeof(t_ts_psrule_record));

	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePreRules_Loc);
		log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
		Display_Message(0, "", sTmp);
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
				memset(&record_psrule, '*', sizeof(ac_Chiave));
				record_psrule.ts1 = lJTS;

				//--------------------- inserisco il record
				rc = MBE_WRITEX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				/* errore */         
				if (rc)
				{
					sprintf(sTmp, "Error (%d) in Writing file [%s]", rc, acFilePreRules_Loc);
					log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
				Display_Message(0, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			record_psrule.ts1 = lJTS;

			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in Updating file [%s]", rc, acFilePreRules_Loc);
				log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
				Display_Message(0, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
		}
	}
	if(rc == 0)
	{
		/*******************
		* AGGIORNO IL DB REMOTO
		*******************/
		rc = MBE_FILE_SETKEY_( handlePre_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) file_setkey remote file [%s]", rc, acFilePreRules_Rem);
			log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
		}
		/* tutto ok */
		if(rc == 0)
		{
			//------------------------- AGGIORNO DB  ----------------------------------
			rc = MBE_READLOCKX( handlePre_rem, (char *) &record_psrule_tmp, (short) sizeof(t_ts_psrule_record) );
			/* errore... */
			if ( rc)
			{
				if(rc == 1)
				{
					//--------------------- inserisco il record
					rc = MBE_WRITEX( handlePre_rem, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
					/* errore */
					if (rc)
					{
						sprintf(sTmp, "Error (%d) in writing Remote file [%s]", rc, acFilePreRules_Rem);
						log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
					}
				}
				else
				{
					sprintf(sTmp, "Error (%d) in reading Remote file [%s]", rc, acFilePreRules_Rem);
						log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
				}
			}
			else
			{

				rc = MBE_WRITEUPDATEUNLOCKX( handlePre_rem, (char *) &record_psrule, (short) sizeof(t_ts_psrule_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating Remote file [%s]", rc, acFilePreRules_Rem);
						log(LOG_ERROR, "%s;%s; %s: error %d",gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
					MBE_UNLOCKREC(handlePre_rem);
				}
			}
		}
	}
	return(rc);
}
