/*----------------------------------------------------------------------------
*   PROGETTO : Configura Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : configOP.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*  Gestione DB operatori
*  Gestione tabelle con jquery
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

#include <stddef.h>
#include <ctype.h>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"

/*------------- PROTOTIPI -------------*/
void 	Display_File(int nTipo);
void 	Maschera_Modifica(short nTipo);
void 	Aggiorna_Dati(short tipo);
void 	Scrivi_Record();
short 	Array_GT(char *acCC_COd, short nDB);
short 	Gestione_GT(t_ts_oper_record oper_profile, short nDB);
short 	Cancellazione_GT(t_ts_oper_record oper_profile, short nDB);
short 	Carica_CarTable();
void 	scrivoLog_Oper(t_ts_oper_record oper_profile, char *str);
void 	scrivoLog_GT(t_ts_opergt_record oper_GT, char *str);
short 	Lista_Paesi(void);
short 	CercoinOperGT(char *acGT, char *resCCeCod);
short 	Cancellazione_GT_ALL(char *sCC, char *sCod, short nDB);

extern short	Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern void		Leggi_Applica();
extern short 	scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation );
extern short 	Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );


AVLTREE	listaPaesi;
AVLTREE	lista_DB;
AVLTREE	listaCAR;

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sOperazione[100];
	char	sTmp[500];
	short	rc = 0;
	char   	ac_err_msg[255];
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

   /**************************************************************************
    ** Determinazione identificativo processo
    **************************************************************************/
	rc = get_process_name(ac_procname);
	if (rc != 0)
	{
		sprintf(sTmp,"Error get_process_name: %d", rc);
		Display_Message(0, "", sTmp);
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
	sprintf(log_spooler.NomeDB, "Operator");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");
	

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
		sprintf(log_spooler.ParametriRichiesta, "ALL");
		strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		log(LOG_INFO, "%s;%s; Display Operators ",gUtente, gIP);
		Display_File( 0 );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "RICERCA")== 0 )
	{
		log(LOG_INFO, "%s;%s; Search ",gUtente, gIP);
		Display_File( 1 );
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for modify OP",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW_OP")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for insert OP",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update OP ",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert OP ",gUtente, gIP);
		Scrivi_Record();
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete OP ",gUtente, gIP);
		Aggiorna_Dati(2);
	}

	log_close();

return(0);
}

/******************************************************************************/
// nTipo = 0  chiamata da DISLPLAY
// nTipo = 1  chiamata da RICERCA
/******************************************************************************/
void Display_File(int nTipo)
{
	short		handle = -1;
	short		rc = 0;
	short		lenKey = 0;
	long		lRecord = 0;
	char		*wrk_str;
	char		sTmp[500];
	char		acKey[18];
	char		resCCeCod[20];
	char		acR_GT[20];
	char		acR_CC[8];
	char		acGT[30];
	char		acKeyDecod[50];

	t_ts_oper_record oper_profile;

	/* inizializza la struttura tutta a blank */
	memset(&oper_profile, ' ', sizeof(t_ts_oper_record));
	memset(acKey,		' ', sizeof(acKey));
	memset(acR_CC,		' ', sizeof(acR_CC));
	memset(acR_GT,		0, sizeof(acR_GT));
	memset(resCCeCod,	0, sizeof(resCCeCod));
	memset(acGT,		0, sizeof(acGT));
	memset(acKeyDecod,	0, sizeof(acKeyDecod));

	//************** apertura pagina **********************
	Display_TOP("");

	lenKey = sizeof(acKey);
	//  ricerca
	if( nTipo == 1)
	{
		if (( (wrk_str = cgi_param( "R_CC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			//memcpy(acKey, wrk_str, strlen(wrk_str));
			memcpy(acR_CC, wrk_str, strlen(wrk_str));
			lenKey = (short)strlen(wrk_str);
		}
		if (( (wrk_str = cgi_param( "R_GT" ) ) != NULL ) && (strlen(wrk_str) > 0))
			memcpy(acR_GT, wrk_str, strlen(wrk_str));
	}


	if(acR_GT[0] != 0 )
	{
		// cerco CC+Cod Op in oper GT 
		sprintf(acGT, "%.8s%s", acR_CC, acR_GT);
		rc = CercoinOperGT(acGT, resCCeCod);
		if(rc == 0)
		{
			memcpy(acKey, resCCeCod, strlen(resCCeCod));
			lenKey = sizeof(acKey);
		}
		else if(rc == 1)
			return;
		else if(rc == 99)
		{
			sprintf(sTmp, "GT %s NOT FOUND", acGT);
			Display_Message(0, "", sTmp);
			return;
		}
	}

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 0);
	if (rc == 0)
	{
		// con le tabelle jquery non ho + l'ordinamento come da key del DB
		if (nTipo == 0)
			rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, lenKey, 0, APPROXIMATE, 0);
		else
			rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, lenKey, 0, GENERIC, 0);

		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error File_setkey from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d",acFileOperatori_Loc, rc);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			printf("<FORM METHOD=POST ACTION='%s' NAME='cerca' onsubmit='return Ricerca_OP()'>\n\
					<INPUT TYPE='hidden' name='OPERATION' value='RICERCA' >\n", gName_cgi);
			printf("<table align='right' cellpadding='5'>");
			printf("<tr>");
			printf( "<td><INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Operator' onclick=\"javascript:location='%s?OPERATION=NEW_OP'\" >\n", gName_cgi);
			printf("</td>");
			printf("<td><fieldset id='fieldsearch' ><legend> Search in OPERGT DB </legend>");
			printf("&nbsp;<B>Country Code: </B>\n\
				   <INPUT TYPE='text' class='numeric' NAME='R_CC' size='10' maxlength ='8' title='Both fields are required' >\n");
			printf("&nbsp;<B>GT: </B>\n\
				   <INPUT TYPE='text' class='numeric' NAME='R_GT' size='15' maxlength ='16' title='Both fields are required' >\n");

			printf("&nbsp;<INPUT TYPE='submit' icon='ui-icon-search' value='GT Search' >\n");
			printf("</fieldset></td></tr>");
			printf("</table></form>");

			// **************************** TABLELIST OPERATOR *************************
			printf("<br><BR><CENTER>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH width='10%%'><strong>Country Code</strong></TH>\n");
			printf("  <TH ><strong>Country</strong></TH>\n");
			printf("  <TH ><strong>Operator Code</strong></TH>\n");
			printf("  <TH ><strong>Tadig Code</strong></TH>\n");
			printf("  <TH ><strong>Operator Name</strong></TH>\n");
			printf("  <TH ><strong>Mcc/Mnc</strong></TH>\n");
			printf("  <TH width='5%%'>&nbsp;</TH>\n");
			printf("</TR>\n");
			printf("</thead>\n");

			printf("<tbody class='editTable'>");
			fflush(stdout);

			while (1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle, (char *) &oper_profile, (short) sizeof( t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
						sprintf(sTmp, "Readx: error %d", rc);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// non visualizzo il record con key '*'
					if (memcmp(oper_profile.paese, "********************", 8))
					{
						/***************************
						* Scrive il record a video
						****************************/
						//sostituisce caratteri speciali in chr esadec
						memset(acKeyDecod,	0, sizeof(acKeyDecod));
						memcpy(acKeyDecod,oper_profile.paese, (sizeof( oper_profile.cod_op)+sizeof( oper_profile.paese)));
						CambiaCar(acKeyDecod);

						// (link) viene disbilitato sul cancella
						printf("<TR class='gradeGreen' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&KEY=%s'\">\n", gName_cgi, acKeyDecod);


						printf(" <TD onclick='link = true'>&nbsp;%.8s</TD>\n", oper_profile.paese);
						printf(" <TD onclick='link = true'>&nbsp;%.64s</TD>\n", oper_profile.den_paese);
						fflush(stdout);
						printf(" <TD onclick='link = true'>&nbsp;%.10s</TD>\n", oper_profile.cod_op);
						printf(" <TD onclick='link = true'>&nbsp;%.5s</TD>\n", oper_profile.tadig_code);
						printf(" <TD onclick='link = true'>&nbsp;%.64s</TD>\n", oper_profile.den_op);
						printf(" <TD onclick='link = true'>&nbsp;%.16s</TD>\n", oper_profile.imsi_op);

						fflush(stdout);
						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&KEY=%s', 'Operator: CC[%s] CodOP[%s]');\" title='Delete'>",
								gName_cgi, acKeyDecod, GetStringNT(oper_profile.paese, 8), GetStringNT(oper_profile.cod_op, 10));
						printf("<div class='del_icon'></div></TD>\n");

						//printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");

						printf("</TR>\n");
						fflush(stdout);

						lRecord ++;
					}
				}
			}/* while (1) */
			
			printf("</tbody>");
			printf("</TABLE>\n");

			printf("</div");
			printf("<BR><BR>\n");
			fflush(stdout);

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Operator' onclick=\"javascript:location='%s?OPERATION=NEW_OP'\" >\n", gName_cgi);
			printf("</CENTER>\n");

			// inserimento delle finestre di dialogo
			printf("<script>\n");
			printf("    insert_Confirm_Delete();\n");
			printf("</script>\n");

			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
    

	return;
}

//*********************************************************************************
void Maschera_Modifica(short nTipo)
{
	short		handle = -1;
	short		rc = 0, i;
	short		nMaxts = 0;
	short		k = 0;
	int			nInterval = 0;
	char		*wrk_str;
	char		sTmp[300];
	char		sTipo[20];
	char		acKey[18];
	char		stringa[100];
	char		*ptrChiave;
	char		*pTmp;
	char		acRead[20];

	t_ts_oper_record oper_profile;
	car_struct_def car_record;

	//********************* Apertura Pagina ****************************
	if(nTipo == 1)
	{
		strcpy(sTipo, "Insert");
		strcpy(acRead, "  ");
		Display_TOP("Operator profile Insertion");
	}
	else
	{
		strcpy(sTipo, "Update");
		strcpy(acRead, "readonly");
		Display_TOP("Operator profile Update");
	}

	/* inizializza la struttura tutta a blank */
	memset(sTmp,		0, sizeof(sTmp));
	memset(&oper_profile, ' ', sizeof( t_ts_oper_record));
	memset(acKey,		' ', sizeof(acKey));
	
	
	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(acKey, wrk_str, strlen(wrk_str));

	// carico in memoria il file CARTABLE per le caratteristiche operatore
	rc = Carica_CarTable();
	if(rc != 0)
		return;

	if(nTipo == 0)
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "Key=%.18s", acKey);
		strcpy(log_spooler.TipoRichiesta, "VIEW");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileOperatori_Loc, &handle, 1, 1);
		if (rc == 0)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle, acKey, (short)sizeof(acKey), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				log(LOG_ERROR, "%s;%s; Error File_setkey from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
				sprintf(sTmp, "File_setkey (%s): error %d", acFileOperatori_Loc, rc);
				Display_Message(1, "", sTmp);
				LOGResult = SLOG_ERROR;
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &oper_profile, (short) sizeof( t_ts_oper_record) );
				/* errore... */
				if ( rc)
				{
					log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
					sprintf(sTmp, "Readx: error %d (%.18s - %d)", rc, acKey,sizeof(acKey) );
					Display_Message(1, "", sTmp);
					LOGResult = SLOG_ERROR;
				}
				else
				{
					scrivoLog_Oper(oper_profile, "ViewOP");
				}
			}
			MBE_FILE_CLOSE_(handle);
		}

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}

	if(rc)
		return;

	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/
	printf("<form method='POST' action='%s' name='inputform' onsubmit='javascript:prepara_valori_GT();prepara_valori_GT_Border(); return checkOperator()'>\n", gName_cgi);
	//printf("<div style='float:left; display:block; width:50%%; height:350px;'>");
	printf("<div class='divContainer opContainer'>\n");
	printf("<div class='divRow'>\n");
	printf("<div class='divColumn opColumna1'>\n");

	printf("<fieldset id='fieldsetOper'><legend> Operator Profile&nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='5' border=0>\n\
			<TR>\n");
	fflush(stdout);

	if(nTipo == 1)
	{
		// Carico i Paesi in una lista in memoria x non inserire i doppioni
		rc = Lista_Paesi();
		if(rc != 0)
			return;

		printf("	<!-- caricamento array Paesi-->");
		printf("<script language='JavaScript'>\n");
		printf("var Paesi = new Array();\n");
		//	printf("Paesi[0] = new Array('Select a Country', '0');\n");
			printf("Paesi[0] = new Array('', '');\n");
		i = 1;

		ptrChiave = avlFirstKey(listaPaesi);
		while (ptrChiave)
		{
			memset(stringa, 0, sizeof(stringa));
			memcpy(stringa, ptrChiave, strlen(ptrChiave));
			
			memset(sTmp, 0, sizeof(sTmp));
            memcpy(sTmp, stringa+72, 5);
			nMaxts = (short) atoi(sTmp);
			memset(sTmp, 0, sizeof(sTmp));
			memcpy(sTmp, stringa+77, 8);
			nInterval = atoi(sTmp);
			
			printf("Paesi[%d] = new Array(\"%s [%s]\", \"%.8s\", \"%d\", \"%d\");\n", i,
					GetStringNT(stringa, 64), GetStringNT(stringa+64, 8),stringa+64, nMaxts, nInterval);
			i++;

			ptrChiave = avlNextKey(listaPaesi);
		}//FINE WHILE
		printf("</script>\n");

		printf("<td align='right' >Country:</td>\n\
				<td align='left' colspan='3'>\n\
					<select name='countrySelect' data-placeholder='Choose a Country...' class='chosen-select' onChange=\"get_CC();\" style='font-family:Courier, monospace'></select>\n\
				</td>\n");

		printf("</tr><tr>\n");
		printf("<TD align=right>Country Code:</TD>\n\
			<TD align=left >\n\
			<input type='text' class='BgGrey' name='CC' size='10' VALUE='%.8s' MAXLENGTH=10 readonly>\n\
			</TD>", oper_profile.paese);
	}
	if(nTipo == 0)
	{
		printf("<TD align=right>Country:</TD>\n\
				<TD align=left colspan='3'>%.64s</TD>", oper_profile.den_paese);

		printf("</tr><tr>\n");
		printf("<TD align=right>Country Code:</TD>\n\
			<TD align=left >\n\
			<input type='text' class='BgGrey' name='CC' size='10' VALUE='%.8s' MAXLENGTH=10 readonly>\n\
			</TD>", oper_profile.paese);

		printf("</tr><tr>\n");
		printf("<TD align=right>Countries Group:</TD>\n\
				<TD align=left colspan='0'>%.64s</TD>", oper_profile.gruppo_pa);
		printf("<TD align=right>Operators Group:</TD>\n\
				<TD align=left colspan='0'>%.64s</TD>", oper_profile.gruppo_op);
	}

	printf("</tr><tr>\n");

	printf("<TD align=right>Operator Code:</B></TD>\n");
	if(nTipo == 0)
		printf("<TD align=left>%.10s</TD>", oper_profile.cod_op);
	else
		printf("<TD align=left><input type='text' id='alfanumeric' name='COD_OP' size='10' MAXLENGTH='10'></TD>");

	printf("<TD align=right>Tadig Code:</B></TD>\n");
	printf("<TD align=left><input type='text' id='alfanumeric' name='TADIG' size='5' MAXLENGTH='5' VALUE=\"%s\"></TD>",
			GetStringNT(oper_profile.tadig_code, sizeof(oper_profile.tadig_code)) );

	printf("</tr><tr>\n");

	memset(sTmp, 0, sizeof(sTmp));
	memcpy(sTmp, oper_profile.den_op, sizeof(oper_profile.den_op));
	AlltrimString(sTmp);
	printf("<TD align=right>Operator Name:</B></TD>\n\
			<TD align=left colspan=3><input type='text' id='checkChr' name='NAME_OP'  size='64' MAXLENGTH=64  VALUE=\"%s\"></TD>", sTmp);

	printf("</TR><TR>");

	if(nTipo == 1)
	{
		printf("\n<script language='JavaScript'>\n\
				setArrayPaesi();\n\
				</script>\n");
	}
	if(oper_profile.max_ts == 8224)
		oper_profile.max_ts = 0;
	printf("<TD align=right>Max Traffic Steering:</b></TD>\n");
	printf("<TD align=left><input type='text' name='MAX_TS' size='5' MAXLENGTH=4 VALUE='%d'class='BgGrey' readonly>\n\
		   </TD>\n", oper_profile.max_ts );

	if(oper_profile.reset_ts_interval == 0x20202020)
		oper_profile.reset_ts_interval = 0;
	printf("<TD align=right>Reset Interval:</b></TD>\n");
	printf("<TD align=left><input type='text' name='R_TS_I' size='10' MAXLENGTH=6 VALUE='%d' class='BgGrey' readonly>\n\
		   (Sec)</TD>\n", oper_profile.reset_ts_interval );

	printf("</tr><tr>\n");
	fflush(stdout);

	//  ------------------- MAP VER  & ID LIST ----------------------------
	if(oper_profile.map_ver == 8224)
		oper_profile.map_ver = 0;
	printf("<TD align=right>MAP Version:</b></TD>\n");
	printf("<TD align=left><input type='text' class='numeric' name='MAP_VER' size='5' MAXLENGTH=4 VALUE='%d'></TD>\n",
				oper_profile.map_ver );
		
	memset(sTmp, 0, sizeof(sTmp));
	memcpy(sTmp, oper_profile.imsi_op, sizeof(oper_profile.imsi_op));
	AlltrimString(sTmp);
	printf("<TD align=right>Mcc/Mnc:</b></TD>\n");
	printf("<TD align=left><input type='text'  name='IMSI_OP' size='30' MAXLENGTH=16 VALUE='%s'>\n\
			<BR>(one or two values separated by ,)</TD>\n",
					sTmp);
		
	printf("</tr><tr>\n");
	fflush(stdout);

	//*********************************************************************************************************
	//      CARATTERISTICHE OPERATORE 
	//*********************************************************************************************************
	for (i = 0; i< sizeof(oper_profile.characteristics)-1; i++ )
	{
		k = 0;
		memset(&car_record, 0, sizeof(car_struct_def));
		if(i % 2 == 0)
			printf("</tr><tr>\n");
		printf("<TD align=right>");
		fflush(stdout);
		ptrChiave = avlFirstKey(listaCAR);
		while (ptrChiave)
		{
			if(ptrChiave[0] == i+48) 
			{
				strcpy(stringa, ptrChiave);
				pTmp= strtok(stringa, ";");
				if(pTmp)
					;//posizione byte
				else
					continue;
				pTmp= strtok(NULL, ";");  
				if(pTmp)
					strcpy(car_record.label, pTmp);
				else
					continue;
				pTmp= strtok(NULL, ";");  
				if(pTmp)
					strcpy(car_record.tipo_input, pTmp);
				else
					continue;
				pTmp= strtok(NULL, ";");  //sigla
				if(pTmp)
					strcpy(car_record.name_input, pTmp);
				else
					continue;
				pTmp= strtok(NULL, ";");  //sigla
				if(pTmp)
					strcpy(car_record.value_input, pTmp);
				else
					continue;

				if (k == 0) //primo record
				{
					printf("%s:</TD>\n\
						   <TD align=left>", car_record.label);
					fflush(stdout);
					if(car_record.tipo_input[0] == 'S')
					{
						printf("<SELECT NAME='CAR_%d' class='chosen-select' STYLE='width: 200px'>\n\
							   <option value='%c'" ,i , car_record.value_input[0]);
						if(car_record.value_input[0] == oper_profile.characteristics[i])
							printf(" selected ");
						printf(">%s</option>\n", car_record.name_input);
						fflush(stdout);
					}
					else if(car_record.tipo_input[0] == 'C')
					{
						printf("<INPUT TYPE='checkbox' NAME='CAR_%d' ", i);
						if( oper_profile.characteristics[i] == '1')
							printf(" checked ");
						printf("></td>");
						fflush(stdout);
					}
					else if(car_record.tipo_input[0] == 'R')
					{
						//if(car_record.value_input[0] !='0')// se value 0 nessun valore del radio button
						{
							printf("<INPUT TYPE='radio' NAME='CAR_%d' VALUE='%c'", i, car_record.value_input[0]);
							if(car_record.value_input[0] == oper_profile.characteristics[i])
								printf(" checked ");
							printf(">");
							printf("%s<br>",car_record.name_input);
							fflush(stdout);
						}
					}
				}
				else //altri rec
				{
					if(car_record.tipo_input[0] == 'S')
					{
						printf("<option value='%c'",car_record.value_input[0]);
						if(car_record.value_input[0] == oper_profile.characteristics[i])
							printf(" selected ");
						printf(">%s</option>\n", car_record.name_input);
						fflush(stdout);
					}
					else if(car_record.tipo_input[0] == 'R')
					{
						//if(car_record.value_input[0] != '0' )// se value 0 nessun valore del radio buttnm
						{
							printf("<INPUT TYPE='radio' NAME='CAR_%d' VALUE='%c'", i, car_record.value_input[0]);
							if(car_record.value_input[0] == oper_profile.characteristics[i])
								printf(" checked ");
							printf(">");
							printf("%s<br>",car_record.name_input);
							fflush(stdout);
						}
					}
				}
				k++;
			}
			ptrChiave = avlNextKey(listaCAR);
		}//FINE WHILE
		if(car_record.tipo_input[0] == 'R')
			printf("</td>\n");
		fflush(stdout);
	}//fine for

	printf("<TR>\n");

	// ********************  Steering Err code ******************************
	printf("<TD colspan='2'>");
	printf("<fieldset id='fieldsetOperStrategy'>\n");
	printf("<legend>Steering error code </legend>\n");
	printf("<Table>\n");
	printf("<tr>\n");
	printf("<td align='right'>MAP:</td>\n");
	printf("<td align='left'><select name='MAP_ERR' class='chosen-select' STYLE='width: 220px'>\n" );
	printf( "<script language='JavaScript'>\n\
					Insert_MAP_errcode(%d, 0);\n\
				</script>\n", oper_profile.steering_map_errcode);
	printf("</select>");

	printf("</td></tr>");
	printf("<tr>\n");
	printf("<td align='right'>LTE:</td>\n");
	printf("<td align='left'><select name='LTE_ERR' class='chosen-select' STYLE='width: 220px' >\n" );
	printf( "<script language='JavaScript'>\n\
						Insert_LTE_errcode(%d, 0);\n\
					</script>\n", oper_profile.steering_lte_errcode);
 	printf("</select>");

 	printf("</td></tr>");
	printf("</Table>\n");
	printf("</fieldset>\n");

	printf("</TD>");

	// ********************  Border roaming ******************************
	printf("<TD colspan='2' rowspan='2'>");
	printf("<fieldset id='fieldsetOperStrategy'>\n");
	printf("<legend>Border roaming </legend>\n");
	printf("<Table>\n");
	printf("<tr>\n");
	printf("<td align='right'>Strategy:</td>\n");
	printf("<td align='left'> <select name='BORD_ROAM' class='chosen-select' STYLE='width: 220px'>\n" );
	printf( "<script language='JavaScript'>\n\
					Insert_Border_strategy('%c');\n\
				</script>\n",oper_profile.steering_border);
	printf("</select>");
	printf("</td></tr>");
	printf("<tr>\n");
	printf("<td>&nbsp;</td>\n");
	printf("</tr>");
	printf("</Table>\n");

	printf("</fieldset>\n");
	printf("</TD>");

	printf("</TR>");

	printf("</TABLE>\n" );
	printf("</fieldset></div>"); //fieldset Operator Profile
	fflush(stdout);

	//*****************  GT ********************************
	// Carico i GT in un'array
	//******************************************************
	sprintf(sTmp, "%.8s%.10s",oper_profile.paese, oper_profile.cod_op);

	printf("\n	<!-- caricamento array GT-->\n");
	printf("<script language='JavaScript'>\n");
	printf("var listaGT = new Array(\n");

	rc = Array_GT(sTmp, 0);
	printf( ");\n</script>\n" );
	
	//*****************  GT BORDER********************************
	// Carico i GT BORDER in un'array
	//******************************************************
	sprintf(sTmp, "%.8s%.10s",oper_profile.paese, oper_profile.cod_op);

	printf("\n	<!-- caricamento array Border GT-->\n");
	printf("<script language='JavaScript'>\n");

	printf("var listaGT_Border = new Array(\n");

	rc = Array_GT(sTmp, 1);
	printf( ");\n</script>\n" );


	if(rc != 0)
		return;

	printf("<div class='divColumn gtColumna2'>\n");
	printf("<fieldset id='fieldsetOper'><legend> GT&nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='5' align='center' border='0'>\n\
			<TR>\n");		
	
	printf("<td width='220' valign='top' ><font id='labelred'>Add GT into the List</font></td>\n\
		   </TR>");
	printf("<TR>\n\
		   <td colspan=2>&nbsp;</td>\n\
		   <td align='left'  class='testo' >Operator GT prefixes</td></TR>\n");

	printf("<TR><td><input type='text' class='BgGrey' name='CC2' size='24' VALUE='%.8s' MAXLENGTH=10 readonly>\n\
			", oper_profile.paese);
	printf("<br><input type='text' class='numeric' name='GT' size='24' MAXLENGTH=16></TD>\n");
	printf("<td width='40' align='center' rowspan='1'  ><nobr>\n\
			<img src='images/right24.png' border=0 title='Add selected GT' style='cursor:hand' onClick=\"javascript:addGT('false');\" onMouseOver=\"javascript:this.src='images/right32.png';\"  onMouseOut=\"javascript:this.src='images/right24.png';\"></nobr><br><nobr>\n\
			</td>\n\
			<td valign='top'  rowspan='4' align='left' width='30%%' >\n\
			<select name='GTSelected' multiple size=18 style='font-family:Courier, monospace'></select>\n\
			</td>\n\
			</tr>\n");

	//  GT BORDER  - Frontalieri
		printf("<tr height='40'>\n");
		printf("<td  align='center' rowspan='1'  ><nobr>\n\
			<img src='images/down24.png' border=0 title='Add Border GT' style='cursor:hand' onClick=\"javascript:addGT_Border('false');\" onMouseOver=\"javascript:this.src='images/down32.png';\"  onMouseOut=\"javascript:this.src='images/down24.png';\">\n\
			</td>\n\
			</tr>\n");
	printf("</tr>");
	printf("<td valign='top'  rowspan='1' align='left' width='20%%' >Border GT:\n</td>\
			</TR><TR><td><select name='GTBorder' multiple size='11' style='font-family:Courier, monospace'></select>\n\
			<img src='images/del.gif' border=0 title='Remove selected Border GT' style='cursor:hand' onClick=\"javascript:delGT_Border();\" onMouseOver=\"javascript:this.src='images/del.gif';\"  onMouseOut=\"javascript:this.src='images/del.gif';\">\n\
			</td>\n");

	printf("<TD COLSPAN=1 align='right' valign='bottom'>\n\
			<img src='images/del.gif' border=0 title='Remove selected GT' style='cursor:hand' onClick=\"javascript:delGT();\" onMouseOver=\"javascript:this.src='images/del.gif';\"  onMouseOut=\"javascript:this.src='images/del.gif';\">\n\
			</td>\n\
			");
		
//	printf("<td width='5%%' align='center' rowspan='1'><nobr>\n\
			</td>\n\
			</td>\n\
			</tr>\n");
		
	printf("</TR>");
	printf("</TABLE>\n" );
	printf("</fieldset></div>\n");//fieldset GT
	printf("</div></div>\n");

	printf("\n<script language='JavaScript'>\n\
			setArrayGT();\n\
			setArrayGT_Border();\n\
			</script>\n");

	printf("</TR></TABLE>");
	fflush(stdout);

	printf("<BR>");
	printf("<BR><p>\n");

	printf("<INPUT TYPE='hidden' name='VALORI' >\n");
	printf("<INPUT TYPE='hidden' name='VALORI_B' >\n");
	printf("<INPUT TYPE='hidden' name='DELGT' >\n");
	printf("<INPUT TYPE='hidden' name='DELGT_B' >\n");

	printf("<INPUT TYPE='hidden' name='KEY' value='%.18s'>\n", oper_profile.paese);

	//lo devo passare hidden perchè x l'htm se c'è un solo campo e premo invio il value non viene passato
	printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);

	printf("<center>\n");
	printf("<input type='button'  icon='ui-icon-home'   VALUE='Return To List' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
	printf("<input type='submit'  icon='ui-icon-check'  VALUE='%s' name='OPERATION' >&nbsp;", sTipo);

	printf("</CENTER></p>\n\
			</form>\n" );

	Display_BOTTOM();

}
//**********************************************************************************************************
// key cc+codop
//
// nDB = 0 gestione Operator GT
// nDB = 1 gestione Operator Border GT
//**********************************************************************************************************
short Array_GT(char *acCC_COd, short nDB)
{
	short		handle = -1;
	short		rc = 0;
	short		nConta = 0;
	short		is_AltKey;
	char		sTmp[500];
	char		acKey[18];
	char		acNomeDB[50];

	// struttura operGT e borderGT sono identiche
	t_ts_opergt_record oper_GT;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acKey, ' ', sizeof(acKey));
	memset(acNomeDB, 0, sizeof(acNomeDB));

	memcpy(acKey, acCC_COd, strlen(acCC_COd));
	/*******************
	* Apro il file
	*******************/
	if(nDB == 0)
	{
		rc = Apri_File(acFileOperGT_Loc, &handle, 1, 1);
		strcpy(acNomeDB, acFileOperGT_Loc);
	}
	else
	{
		rc = Apri_File(acFileOperGT_Bord_Loc, &handle, 1, 1);
		strcpy(acNomeDB, acFileOperGT_Bord_Loc);
	}

	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{

			log(LOG_ERROR, "%s;%s; Error File_setkey from file %s : code %d",gUtente, gIP, acNomeDB, rc);
			sprintf(sTmp, "File_setkey (%s): error %d", acNomeDB, rc);
			printf( "</script>\n" );
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
				rc = MBE_READX( handle, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acNomeDB, rc);
						sprintf(sTmp, "Readx: error %d", rc);
						printf( "</script>\n" );
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// il carattere '*' serve x sapere i record già presenti nel db in caso di cancellazione
					if(nConta == 0)
						printf( "   new Option(\"%s *\",\"*%.24s\")\n", GetStringNT(oper_GT.gt,24), oper_GT.gt);
					else
						printf( "\n,  new Option(\"%s *\",\"*%.24s\")\n",GetStringNT(oper_GT.gt, 24), oper_GT.gt);
					fflush(stdout);
					nConta++;
				}
			}/* while (1) */
		}

		MBE_FILE_CLOSE_(handle);
	}

	return(rc);	
}
//*************************************************************************************
// tipo = 0 aggiorna 
// tipo = 2 cancella
//*************************************************************************************
void Aggiorna_Dati(short tipo)
{
	short		handle = -1;
	short		handleOP_rem = -1;
	short		rc = 0, i;
	char		*wrk_str;
	char		sTmp[1000];
	char		acKey[18];
	char		acDenPaese[50];
	char		acName[20];
	char		sCC[50];
	char		sCod[50];

	 t_ts_oper_record oper_profile;
	 t_ts_oper_record oper_profile_backup;

	/* inizializza la struttura tutta a blank */
	memset(sTmp, 0, sizeof(sTmp));
	memset(acDenPaese, 0, sizeof(acDenPaese));
	memset(&oper_profile, ' ', sizeof( t_ts_oper_record));
	memset(acKey, ' ', sizeof(acKey));
	
	if (( (wrk_str = cgi_param( "KEY" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(acKey, wrk_str, strlen(wrk_str));
		// mi serve x quando passo la struttura alla funz che gesisce i GT	
		memcpy(oper_profile.paese, wrk_str, sizeof(oper_profile.paese));
		memcpy(oper_profile.cod_op, wrk_str+sizeof(oper_profile.paese), sizeof(oper_profile.cod_op));
	}
	//controllo lunghezza nome operatore prima di proseguire
	if (( (wrk_str = cgi_param( "NAME_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(sTmp, wrk_str);
		//ultimi 2 campi vengono ignorati se secondo param è = 0
		rc = Check_LenMsg(sTmp, 1, sizeof(oper_profile.den_op), "Operator Name");
		if(rc)
			return;
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "CC=%.8s;Cod OP=%.10s", oper_profile.paese, oper_profile.cod_op);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 1);
	if (rc == 0)
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handle, acKey, (short)sizeof(acKey), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  in Local file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			return;
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handle, (char *) &oper_profile, (short) sizeof( t_ts_oper_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s]", rc, acFileOperatori_Loc);
				log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
				Display_Message(1, "",sTmp);
			}
			else
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&oper_profile_backup, &oper_profile, sizeof(oper_profile));

				if( tipo == 2) // CANCELLAZIONE
				{
					strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL

			//		rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_profile, 0 );
					rc = MBE_WRITEUPDATEX( handle, (char *) &oper_profile, 0 );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) deleting in local file [%s] Operators: %.8s;%.10s",
								rc, acFileOperatori_Loc, oper_profile.paese, oper_profile.cod_op);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);

						MBE_UNLOCKREC(handle);
					}
					else
					{
						// ********************** Aggiorno DB REMOTO ***********************************
						rc = scrivi_Operatori_remoto(handleOP_rem, &oper_profile, DEL );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handle);

							memset(sCC,		0, sizeof(sCC));
							memset(sCod,	0, sizeof(sCod));
							memcpy(sCC,		oper_profile.paese, sizeof(oper_profile.paese));
							memcpy(sCod,	oper_profile.cod_op, sizeof(oper_profile.cod_op));
							TrimString(sCC);
							TrimString(sCod);
							log(LOG_INFO, "%s;%s; DelOP:%s;%s",
										gUtente, gIP, sCC, sCod);

							Cancellazione_GT_ALL(sCC, sCod, 0);
							Cancellazione_GT_ALL(sCC, sCod, 1);
						}
						else
						{
							//  ERRORE  DB REMOTO
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handle, (char *) &oper_profile_backup, (short) sizeof(t_ts_oper_record) );
							/* errore */
							if (rc)
							{
								if (rc == 10 )
								{
									sprintf(sTmp, "In Local DB, oOperator [%.18s] already exist", oper_profile.paese);
									log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
									Display_Message(1, "", sTmp);
								}
								else
								{
									sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileOperatori_Loc);
									log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
									Display_Message(1, "", sTmp);
								}
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
						}
					}
				}
				else
				{		//MODIFICA
					strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL

					for (i = 0; i< sizeof(oper_profile.characteristics)-1; i++ )
					{
						memset(acName, 0, sizeof(acName));
						sprintf(acName, "CAR_%d", i);
						if (( (wrk_str = cgi_param( acName ) ) != NULL ) && (strlen(wrk_str) > 0))
						{
							if(!memcmp(wrk_str,"on",2)) ///checkbox
								oper_profile.characteristics[i] = '1';
							else
								oper_profile.characteristics[i] = wrk_str[0];
						}
						else
							oper_profile.characteristics[i] = '0';
					}

					memset(oper_profile.den_op, ' ', sizeof(oper_profile.den_op));
					if (( (wrk_str = cgi_param( "NAME_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
						memcpy(oper_profile.den_op, wrk_str, strlen(wrk_str) );

					memset(oper_profile.tadig_code, ' ', sizeof(oper_profile.tadig_code));
					if (( (wrk_str = cgi_param( "TADIG" ) ) != NULL ) && (strlen(wrk_str) > 0))
						memcpy(oper_profile.tadig_code, wrk_str, strlen(wrk_str) );

					if (( (wrk_str = cgi_param( "MAP_VER" ) ) != NULL ) && (strlen(wrk_str) > 0))
						oper_profile.map_ver = (short) atoi(wrk_str);
					memset(oper_profile.imsi_op, ' ', sizeof(oper_profile.imsi_op));
					if (( (wrk_str = cgi_param( "IMSI_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
						memcpy(oper_profile.imsi_op, wrk_str, strlen(wrk_str) );
					if (( (wrk_str = cgi_param( "MAP_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
							oper_profile.steering_map_errcode = (short) atoi(wrk_str);
					if (( (wrk_str = cgi_param( "LTE_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
							oper_profile.steering_lte_errcode = (short) atoi(wrk_str);
					if (( (wrk_str = cgi_param( "BORD_ROAM" ) ) != NULL ) && (strlen(wrk_str) > 0))
							oper_profile.steering_border = wrk_str[0];


			//		rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_profile, sizeof( t_ts_oper_record) );
					rc = MBE_WRITEUPDATEX( handle, (char *) &oper_profile, sizeof( t_ts_oper_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc);
						Display_Message(1, "",sTmp);
						log(LOG_INFO, "%s;%s; writeupdatex (UPD) Local Operators: %.8s;%.10s",
										gUtente, gIP, oper_profile.paese, oper_profile.cod_op);

						MBE_UNLOCKREC(handle);
					}
					else
					{
						// ************ scrivo DB REMOTO *****************************
						rc = scrivi_Operatori_remoto(handleOP_rem, &oper_profile, UPD );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handle);
							scrivoLog_Oper(oper_profile, "UpdOP");
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_profile_backup, (short) sizeof(t_ts_oper_record) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s] - Key: [%.18s]", rc, acFileOperatori_Loc, oper_profile.paese);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handle);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
						}
					}
				}// fine modifica
			}
		}
	}

	if(rc == 0)
		rc= Aggiorna_Operatori_rec_Aster(handle, handleOP_rem);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------------------*/
	/* LOG SICUREZZA solo per db operator		*/
	/*------------------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	if(rc == 0 && tipo != 2)
	{
		rc = Gestione_GT(oper_profile, 0);  // oper GT
		if(rc == 0)
			rc = Gestione_GT(oper_profile, 1); 	// operBorder GT
	}

	if(rc == 0 && tipo != 2)
	{
		rc = Cancellazione_GT(oper_profile, 0);  //Operator GT
		if(rc == 0)
			rc = Cancellazione_GT(oper_profile, 1);  //Operator Border GT
	}

	MBE_FILE_CLOSE_(handle);

	if(rc == 0)
	{
		Display_File( 0 );
	}
}
//*******************************************************************************************************************
void Scrivi_Record()
{
	short		handle = -1;
	short		handleOP_rem = -1;
	short		rc = 0, i;
	char		sTmp[500];
	char		*wrk_str;
	char		*pTmp;
	char		sDati[100];
	char		acCC[20];
	char		acCodOp[20];
	char		acName[20];

	 t_ts_oper_record oper_profile;

	/* inizializza la struttura tutta a blank */
	memset(&oper_profile, ' ', sizeof( t_ts_oper_record));
	memset(acCC, 0, sizeof(acCC));
	memset(acCodOp, 0, sizeof(acCodOp));
	memset(sDati, 0, sizeof(sDati));

	//controllo lunghezza nome operatore prima di proseguire
	if (( (wrk_str = cgi_param( "NAME_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(sTmp, wrk_str);
		rc = Check_LenMsg(sTmp, 1, sizeof(oper_profile.den_op), "Operator Name");
		if(rc)
			return;
	}

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 1);
	if (rc != 0)
		return;

	rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
	if (rc != 0)
		return;

	if (( (wrk_str = cgi_param( "countrySelect" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(sTmp, wrk_str);
		pTmp= strtok(sTmp, "[");
		if(pTmp)
			memcpy(oper_profile.den_paese, pTmp, strlen(pTmp));
	}

	if (( (wrk_str = cgi_param( "CC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(oper_profile.paese, wrk_str, strlen(wrk_str) );
	if (( (wrk_str = cgi_param( "NAME_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(oper_profile.den_op, wrk_str, strlen(wrk_str) );
	if (( (wrk_str = cgi_param( "COD_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(oper_profile.cod_op, wrk_str, strlen(wrk_str) );
	if (( (wrk_str = cgi_param( "TADIG" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(oper_profile.tadig_code, wrk_str, strlen(wrk_str) );

	if (( (wrk_str = cgi_param( "MAX_TS" ) ) != NULL ) && (strlen(wrk_str) > 0))
		oper_profile.max_ts = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "R_TS_I" ) ) != NULL ) && (strlen(wrk_str) > 0))
		oper_profile.reset_ts_interval = atoi(wrk_str);
	if (( (wrk_str = cgi_param( "MAP_VER" ) ) != NULL ) && (strlen(wrk_str) > 0))
		oper_profile.map_ver = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "IMSI_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(oper_profile.imsi_op, wrk_str, strlen(wrk_str) );

	if (( (wrk_str = cgi_param( "MAP_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
			oper_profile.steering_map_errcode = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "LTE_ERR" ) ) != NULL ) && (strlen(wrk_str) > 0))
			oper_profile.steering_lte_errcode =  (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "BORD_ROAM" ) ) != NULL ) && (strlen(wrk_str) > 0))
			oper_profile.steering_border = wrk_str[0];

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "CC=%.8s;Cod OP=%.10s", oper_profile.paese, oper_profile.cod_op);
	strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;


	for (i = 0; i< sizeof(oper_profile.characteristics)-1; i++ )
	{
		memset(acName, 0, sizeof(acName));
		sprintf(acName, "CAR_%d", i);
		if ( (wrk_str = cgi_param( acName ) ) != NULL )
		{
			if(!memcmp(wrk_str,"on",2)) ///checkbox
				oper_profile.characteristics[i] = '1';
			else
				oper_profile.characteristics[i] = wrk_str[0];
		}
		else
			oper_profile.characteristics[i] = '0';
	}

	rc = MBE_WRITEX( handle, (char *) &oper_profile,  sizeof( t_ts_oper_record) );
	/* errore */         
	if (rc)
	{
		if (rc == 10 )
		{
			log(LOG_ERROR, "%s;%s; Error KEY already exist in %s ",gUtente, gIP, acFileOperatori_Loc);
			sprintf(sTmp, "KEY already exist in Local file [%s]",acFileOperatori_Loc);
			Display_Message(1, "",sTmp);
		}
		else
		{
			log(LOG_ERROR, "%s;%s; Error Writex from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
			sprintf(sTmp, "Error (%d) writing in Loca file [%s]", rc, acFileOperatori_Loc);
			Display_Message(1, "",sTmp);
		}
	}
	else
	{
		// ************ scrivo DB REMOTO *****************************
		rc = scrivi_Operatori_remoto(handleOP_rem, &oper_profile, INS );
		if(rc == 0)
			scrivoLog_Oper(oper_profile, "InsOP");
		else
		{
			// ERRORE Inserimento REMOTO
			//cancello locale
			MBE_FILE_SETKEY_( handle, (char *) &oper_profile.paese, (short)sizeof(oper_profile.paese)+ sizeof(oper_profile.cod_op), 0, EXACT);
			MBE_READLOCKX( handle, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_profile, 0);
			if(rc)
			{
				sprintf(sTmp, "Error (%d) deleting in  Local file [%s] - Key: [%.18s]", rc, acFileOperatori_Loc, oper_profile.paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
			// setto rc a 1 per segnalare errore
			rc = 1;
		}
	}

	if(rc == 0)
		rc= Aggiorna_Operatori_rec_Aster(handle, handleOP_rem);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	if(rc == 0)
	{
		rc = Gestione_GT(oper_profile, 0); 	// operr GT
		if(rc == 0)
			rc = Gestione_GT(oper_profile, 1);	// operBorder GT
	}
	if(rc == 0)
	{
		rc= Cancellazione_GT(oper_profile, 0);
		if(rc == 0)
			rc = Cancellazione_GT(oper_profile, 1);
	}

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handleOP_rem);
	if(rc == 0)
	{
		memset(sTmp, 0, sizeof(sTmp));
		sprintf(sTmp, "%.8s%.10s",oper_profile.paese, oper_profile.cod_op);
		Display_File( 0 );
	}

	return;
}
//*********************************************************************************************
short Gestione_GT(t_ts_oper_record oper_profile, short nDB)
{
	short	handleGT = -1;
	short	handleGT_rem = -1;
	short	rc = 0;
	char	*wrk_str;
	char	*pTmp;
	char	sTmp[500];
	char	acParam[20];
	char	acNomeDB_Loc[50];
	char	acNomeDB_Rem[50];

	t_ts_opergt_record oper_GT;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acParam, 0, sizeof(acParam));
	memset(acNomeDB_Loc, 0, sizeof(acNomeDB_Loc));
	memset(acNomeDB_Rem, 0, sizeof(acNomeDB_Rem));

	/*******************
	* Apro il file
	*******************/
	if(nDB == 0)
	{
		rc = Apri_File(acFileOperGT_Loc, &handleGT, 1, 1);
		rc = Apri_File(acFileOperGT_Rem, &handleGT_rem, 1, 1);
		strcpy(acParam, "VALORI");
		strcpy(acNomeDB_Loc, acFileOperGT_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Rem);
	}
	else
	{
		rc = Apri_File(acFileOperGT_Bord_Loc, &handleGT, 1, 1);
		rc = Apri_File(acFileOperGT_Bord_Rem, &handleGT_rem, 1, 1);
		strcpy(acParam, "VALORI_B");
		strcpy(acNomeDB_Loc, acFileOperGT_Bord_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Bord_Rem);
	}


	if (rc == 0)
	{
		// in VALORI ci sono i seguenti dati:
		// GT:GT:........se il primo carattere è '*' non è da inserire perchè già presente
		if (( (wrk_str = cgi_param( acParam ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			pTmp= GetToken(wrk_str, ":");
			while(pTmp != NULL)
			{
				memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
				if(pTmp[0] != '*')
				{
					memcpy(oper_GT.gt, pTmp, strlen(pTmp));
					
					memcpy(oper_GT.paese, oper_profile.paese, sizeof(oper_profile.paese));
					memcpy(oper_GT.cod_op, oper_profile.cod_op, sizeof(oper_profile.cod_op));

					rc = MBE_WRITEX( handleGT, (char *) &oper_GT,  sizeof( t_ts_opergt_record) );
					/* errore */         
					if (rc)
					{
						if (rc == 10 )
						{
							sprintf(sTmp, "KEY (%.24s) already exist in file [%s]", oper_GT.gt, acNomeDB_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							break;
						}
						else
						{
							sprintf(sTmp, "Error (%d) writing in Local file [%s]", rc, acNomeDB_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							break;
						}
					}
					else
					{
						// ********** scrivo in DB REMOTE ******************
						rc = MBE_WRITEX( handleGT_rem, (char *) &oper_GT,  sizeof( t_ts_opergt_record) );
						/* errore */
						if (rc == 0)
							scrivoLog_GT(oper_GT, "InsGT");
						else
						{
							if (rc == 10 )
							{
								sprintf(sTmp, "KEY (%.24s) already exist in Remote file [%s]", oper_GT.gt, acNomeDB_Rem);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "",sTmp);
							}
							else
							{
								sprintf(sTmp, "Error (%d) writing in Remote file [%s]", rc, acNomeDB_Rem);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "",sTmp);
							}

							// ERRORE Inserimento REMOTO
							//cancello locale
							MBE_FILE_SETKEY_( handleGT, (char *) &oper_GT.gt, (short)sizeof(oper_GT.gt), 0, EXACT);
							MBE_READLOCKX( handleGT, (char *) &oper_GT, (short) sizeof(t_ts_opergt_record) );
							rc = MBE_WRITEUPDATEUNLOCKX( handleGT, (char *) &oper_GT, 0);
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in deleting Local file [%s]", rc, acNomeDB_Loc);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handleGT);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
							break;
						}
					}
				}

				//Continuo a leggere i Dati
				pTmp= GetToken(NULL, ":");
			}// fine while gettoken
		}

		MBE_FILE_CLOSE_(handleGT);
		MBE_FILE_CLOSE_(handleGT_rem);
	}
	return(rc);
}

//*********************************************************************************************
// nDB = 0 gestione Operator GT
// nDB = 1 gestione Operator Border GT
//*********************************************************************************************
short Cancellazione_GT_ALL(char *sCC, char *sCod, short nDB)
{
	short		handle = -1;
	short		handleGT_Rem = -1;
	short		rc = 0;
	short		is_AltKey;
	char		sTmp[500];
	char		acKey[18];
	char		acNomeDB_Loc[50];
	char		acNomeDB_Rem[50];

	t_ts_opergt_record oper_GT;
	t_ts_opergt_record oper_GT_tmp;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acKey, ' ', sizeof(acKey));
	memset(acNomeDB_Loc, 0, sizeof(acNomeDB_Loc));
	memset(acNomeDB_Rem, 0, sizeof(acNomeDB_Rem));

	memcpy(acKey, sCC, strlen(sCC));
	memcpy(acKey+sizeof(oper_GT.paese), sCod, strlen(sCod));

	/*******************
	* Apro il file
	*******************/
	if(nDB == 0)
	{
		rc = Apri_File(acFileOperGT_Loc, &handle, 1, 1);
		if (rc == 0)
			rc = Apri_File(acFileOperGT_Rem, &handleGT_Rem, 1, 1);

		strcpy(acNomeDB_Loc, acFileOperGT_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Rem);
	}
	else
	{
		rc = Apri_File(acFileOperGT_Bord_Loc, &handle, 1, 1);
		if (rc == 0)
			rc = Apri_File(acFileOperGT_Bord_Rem, &handleGT_Rem, 1, 1);

		strcpy(acNomeDB_Loc, acFileOperGT_Bord_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Bord_Rem);
	}

	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey from Local file [%s]", rc, acNomeDB_Loc);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_FILE_SETKEY_( handleGT_Rem, (char *) &acKey, sizeof(acKey), is_AltKey, GENERIC, 0);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey from Remote file [%s]", rc, acNomeDB_Rem);
				log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}

		if(rc == 0)
		{
			while ( 1 )
			{
				rc = MBE_READLOCKX( handle, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
				/* errore... */
				if ( rc)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) reading in Local file [%s] - key =%.18s", rc, acNomeDB_Loc, oper_GT.paese);
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);

						Display_Message(1, "",sTmp);
					}
					else
						rc = 0;
					break;
				}
				else
				{
					rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_GT, 0 );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) deleting in Local file [%s] ", rc, acNomeDB_Loc);
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);
						MBE_UNLOCKREC(handle);
						break;
					}
				}
				if(rc == 0)
				{
					// *************aggiorno DB REMOTO*******************
					rc = MBE_READLOCKX( handleGT_Rem, (char *) &oper_GT_tmp, (short) sizeof( t_ts_opergt_record) );
					/* errore... */
					if ( rc)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) reading in Remote file [%s] - key =%.18s", rc, acNomeDB_Rem, oper_GT.paese);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
						}
						else
							rc = 0;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleGT_Rem, (char *) &oper_GT, 0 );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) deleting in Remote file [%s] ", rc, acNomeDB_Rem);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleGT_Rem);
						}
					}
					if (rc != 0)
					{
						//  ERRORE DB REMPOTO
						// Inserisco rec in db Locale
						rc = MBE_WRITEX( handle, (char *) &oper_GT, (short) sizeof(t_ts_opergt_record) );
						/* errore */
						if (rc)
						{
							sprintf(sTmp, "Error (%d) in writing in Local file [%s]", rc, acNomeDB_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
						}

						// setto rc a 1 per segnalare errore
						rc = 1;
						break;
					}
				}

			}// fine while 
		}

		MBE_FILE_CLOSE_(handle);
		MBE_FILE_CLOSE_(handleGT_Rem);
	}
	return(rc);
}


//*********************************************************************************************
// nDB = 0 gestione Operator GT
// nDB = 1 gestione Operator Border GT
//*********************************************************************************************
short Cancellazione_GT(t_ts_oper_record oper_profile, short nDB)
{
	short		handleGT = -1;
	short		handleGT_rem = -1;
	short		rc = 0;
	char		sTmp[500];
	char 		acParam[20];
	char		*pTmp;
	char		*wrk_str;
	char		acNomeDB_Loc[50];
	char		acNomeDB_Rem[50];

	t_ts_opergt_record oper_GT;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acParam, 0, sizeof(acParam));
	memset(acNomeDB_Loc, 0, sizeof(acNomeDB_Loc));
	memset(acNomeDB_Rem, 0, sizeof(acNomeDB_Rem));

	/*******************
	* Apro il file
	*******************/
	if(nDB == 0)
	{
		rc = Apri_File(acFileOperGT_Loc, &handleGT, 1, 1);
		rc = Apri_File(acFileOperGT_Rem, &handleGT_rem, 1, 1);
		strcpy(acParam, "DELGT");
		strcpy(acNomeDB_Loc, acFileOperGT_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Rem);
	}
	else
	{
		rc = Apri_File(acFileOperGT_Bord_Loc, &handleGT, 1, 1);
		rc = Apri_File(acFileOperGT_Bord_Rem, &handleGT_rem, 1, 1);
		strcpy(acParam, "DELGT_B");
		strcpy(acNomeDB_Loc, acFileOperGT_Bord_Loc);
		strcpy(acNomeDB_Rem, acFileOperGT_Bord_Rem);
	}

	if (rc == 0)
	{
		// in VALORI ci sono i seguenti dati:
		// GT:GT:........
		if (( (wrk_str = cgi_param( acParam ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			pTmp= GetToken(wrk_str, ":");
			//IL PRIMO CHR DI gt è '*'
			while(pTmp != NULL)
			{
				memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
				memcpy(oper_GT.gt, pTmp+1, strlen(pTmp));
					
				//memcpy(oper_GT.paese, oper_profile.paese, sizeof(oper_profile.paese));
				//memcpy(oper_GT.cod_op, oper_profile.cod_op, sizeof(oper_profile.cod_op));
		
				rc = MBE_FILE_SETKEY_( handleGT, oper_GT.gt, (short)sizeof(oper_GT.gt), 0, EXACT);
				/* errore */
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File_setkey Local file [%s] ", rc, acNomeDB_Loc);
					log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					break;
				}
				/* tutto ok */
				else
				{
					rc = MBE_READLOCKX( handleGT, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
					/* errore... */
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) reading in Local file [%s] - KEY=%.24s", rc, acNomeDB_Loc, oper_GT.gt);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);
						break;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleGT, (char *) &oper_profile, 0 );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) updating in Local file [%s] - KEY=%.24s", rc, acNomeDB_Loc, oper_GT.gt);
							log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleGT);
							break;
						}
					}
				}

				// *********CANCELLAZIONE DB REMOTO *********************
				rc = MBE_FILE_SETKEY_( handleGT_rem, oper_GT.gt, (short)sizeof(oper_GT.gt), 0, EXACT);
				/* errore */
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File_setkey Remote file [%s] ", rc, acNomeDB_Rem);
					log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					break;
				}
				/* tutto ok */
				else
				{
					rc = MBE_READLOCKX( handleGT_rem, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
					/* errore... */
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) reading in Remote file [%s] - KEY=%.24s", rc, acNomeDB_Rem, oper_GT.gt);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);
						break;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleGT_rem, (char *) &oper_GT, 0 );
						if (rc == 0)
							//*************** tutto OK ***************
							scrivoLog_GT(oper_GT, "DelGT");
						else
						{
							sprintf(sTmp, "Error (%d) updating in Remote file [%s] - KEY=%.24s", rc, acNomeDB_Rem, oper_GT.gt);
							log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleGT);

							// *********** ERRORE Cancellazione DB REMOTO *****************
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handleGT, (char *) &oper_GT, (short) sizeof(t_ts_opergt_record) );
							/* errore */
							if (rc)
							{
								sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acNomeDB_Loc);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
							break;
						}
					}
				}

				//Continuo a leggere i Dati
				pTmp= GetToken(NULL, ":");
			}// fine while gettoken
		}

		MBE_FILE_CLOSE_(handleGT);
		MBE_FILE_CLOSE_(handleGT_rem);
	}
	return(rc);
}

//*****************************************************************************************
short Carica_CarTable()
{
	FILE		*hIn;
	short		rc = 0;
    char		sTmp[500];
    char		sLetti[301];
	char		acDati[301];
	char		*ptr_CAR;

	listaCAR = avlMake();

	/****************************************
	* apre il file  input               
	****************************************/
	if ((hIn = fopen(ac_car_table, "r")) == NULL)
	{
		/* avvisa dell'errore */
		sprintf(sTmp, "fopen %s: error %d", ac_car_table, errno);
		Display_Message(0, "", sTmp);
		rc = 1;
	}

	if (rc == 0)
	{
		/* legge prima riga fino allo \n */
		fgets(sLetti, 300, hIn);
		while (!feof(hIn))
		{
			memset(acDati, 0, sizeof(acDati));
			memcpy(acDati, sLetti, strlen(sLetti)-1);
			//Aggiungere un elemento alla lista:
			AlltrimString(acDati);

			ptr_CAR = malloc((strlen(acDati)+1)*sizeof(char));
			strcpy(ptr_CAR, acDati);
			if(ptr_CAR[0] != 0 )
			{
				if (avlAdd(listaCAR, ptr_CAR, ptr_CAR) == -1)
				{
					// nel file ci sono chiavi duplicate
					printf("Record already exist in CARTABLE");
					rc = 1;
				}
			}
			memset(sLetti, 0, sizeof(sLetti));
			/* legge una riga fino allo \n */
			fgets(sLetti, 300, hIn);

		}//fine while
		fclose(hIn);
//printf("-%d-",avlSize(listaCAR));
	}

	return(rc);
}

//************************************************************************************
void scrivoLog_Oper(t_ts_oper_record oper_profile, char *str)
{
	char sCC[50];
	char sCod[50];
	char sImsi[50];
	char sCarat[50];
	char sDenOp[100];
	char sDenPA[100];

	memset(sCC,		0, sizeof(sCC));
	memset(sCod,	0, sizeof(sCod));
	memset(sImsi,	0, sizeof(sImsi));
	memset(sCarat,	0, sizeof(sCarat));
	memset(sDenOp,	0, sizeof(sDenOp));
	memset(sDenPA,	0, sizeof(sDenPA));

	memcpy(sCC,		oper_profile.paese, sizeof(oper_profile.paese));
	memcpy(sCod,	oper_profile.cod_op, sizeof(oper_profile.cod_op));
	memcpy(sDenOp,	oper_profile.den_op, sizeof(oper_profile.den_op));
	memcpy(sDenPA,	oper_profile.den_paese, sizeof(oper_profile.den_paese));
	memcpy(sImsi,	oper_profile.imsi_op, sizeof(oper_profile.imsi_op));
	memcpy(sCarat,	oper_profile.characteristics, sizeof(oper_profile.characteristics) );

	TrimString(sCC);
	TrimString(sCod);
	TrimString(sImsi);
	TrimString(sCarat);
	TrimString(sDenOp);
	TrimString(sDenPA);

	 log(LOG_INFO, "%s;%s; %s:%s;%s;%s;%s;%s;%d;%s",
							gUtente, gIP, str,
							sCC,
							sCod,
							sDenOp,
							sDenPA,
							sImsi,
							oper_profile.map_ver,
							sCarat);
}

//************************************************************************************
void scrivoLog_GT(t_ts_opergt_record oper_GT, char *str)
{
	//char	sCC[50];
	char	sCod[50];
	char	sGT[50];

	//memset(sCC,		0, sizeof(sCC));
	memset(sCod,	0, sizeof(sCod));
	memset(sGT,		0, sizeof(sGT));

	//memcpy(sCC,		oper_GT.paese, sizeof(oper_GT.paese));
	memcpy(sCod,	oper_GT.cod_op, sizeof(oper_GT.cod_op));
	memcpy(sGT,		oper_GT.gt, sizeof(oper_GT.gt));

	//TrimString(sCC);
	TrimString(sCod);
	TrimString(sGT);

	log(LOG_INFO, "%s;%s; %s:%s;%s",
					gUtente, gIP, str,
					sCod,
					sGT);

}

//************************************************************************************************
short Lista_Paesi(void)
{
	short		handle2 = -1;
	short		rc = 0;
	char		acPa_Chiave[8];
	char		sTmp[500];
	char		chiave[100];
	char		*ptr_PA;

	t_ts_paesi_record record_paesi;

	//Creare la listaPaesi:
	listaPaesi = avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof( t_ts_paesi_record));
	memset(acPa_Chiave, ' ', sizeof(acPa_Chiave));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle2, 1, 1);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle2, (char *) &acPa_Chiave, sizeof(acPa_Chiave), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error File_setkey from file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d", acFilePaesi_Loc, rc);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			while ( 1 )
			{
				memset(&record_paesi, ' ', sizeof( t_ts_paesi_record));

				/*******************
				* Leggo il record
				*******************/
				rc = MBE_READX( handle2, (char *) &record_paesi, (short) sizeof( t_ts_paesi_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);
						sprintf(sTmp, "Readx: error %d", rc);
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if( memcmp(record_paesi.paese, "********", 8))
					{
						//Aggiungere un elemento alla listaPaesi:
						//inserisco anche paese per rendere la chiave univoca
						memset(chiave, 0, sizeof(chiave));
						if(record_paesi.reset_ts_interval == 0x20202020)
							record_paesi.reset_ts_interval = 0;
						sprintf(chiave, "%.64s%.8s%.05d%.08d", record_paesi.den_paese, record_paesi.paese,
															record_paesi.max_ts , record_paesi.reset_ts_interval);
						//AlltrimString(chiave);

						ptr_PA = malloc((strlen(chiave)+1)*sizeof(char));
						strcpy(ptr_PA, chiave);

					//	*ptr_CC = record_paesi.paese;
						if (avlAdd(listaPaesi, ptr_PA, ptr_PA) == -1)
						{
							//sprintf(sTmp, "la chiave %s esiste già !!!", chiave);
						}
					}
				}
			}/* while (1) */

		}

		MBE_FILE_CLOSE_(handle2);
	}

	return(rc);	
}
//********************************************************************************
short CercoinOperGT(char *acGT, char *resCCeCod)
{
	short		handle = -1;
	short		rc = 0;
	char		sTmp[500];
	char		acKey[24];

	t_ts_opergt_record oper_GT;

	/* inizializza la struttura tutta a blank */
	memset(&oper_GT, ' ', sizeof( t_ts_opergt_record));
	memset(acKey, ' ', sizeof(acKey));

	memcpy(acKey, acGT, strlen(acGT));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperGT_Loc, &handle, 1, 1);

	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, sizeof(acKey), 0, EXACT, 0);
		/* errore */
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error File_setkey from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
			sprintf(sTmp, "File_setkey (%s): error %d", acFileOperGT_Loc, rc);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			/*******************
			* Leggo il record
			*******************/
			rc = MBE_READX( handle, (char *) &oper_GT, (short) sizeof( t_ts_opergt_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
					sprintf(sTmp, "Readx: error %d", rc);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 99;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				memcpy(resCCeCod, oper_GT.paese, sizeof(oper_GT.paese)+ sizeof(oper_GT.cod_op));
			}
		}

		MBE_FILE_CLOSE_(handle);
	}

	return(rc);	
}

