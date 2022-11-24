/*----------------------------------------------------------------------------
*   PROGETTO : GTT - gestione Impianti e MGT
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
#include "sspfunc.h"
#include "ssplog.h"
#include <cextdecs.h (JULIANTIMESTAMP)>


#pragma fieldalign shared2 _pcf_stru
typedef struct _pcf_stru
{
   short      value;			// valore
   char       description[30];	// descrizione
} pcf_stru_def;

pcf_stru_def pcf_elementi[20];

#pragma fieldalign shared2 _ssn_stru
typedef struct _ssn_stru
{
   short      value;			// valore
   char       description[30];	// descrizione
} ssn_stru_def;

ssn_stru_def ssn_elementi[20];


/*------------- PROTOTIPI -------------*/
void 	Display_File();
void 	Maschera_Modifica(short nTipo);
void 	Aggiorna_Dati(short tipo);
void 	Lettura_Variabili(	du_impianti_rec_def *impianti);
short 	Array_MGT(short nPCF, short nPC);
short 	Gestione_MGT(du_impianti_rec_def impianti, short tipo);
short 	Cancellazione_MGT(du_impianti_rec_def impianti);
short 	Cancellazione_MGT_ALL(short nPCF, short nPC);
short 	scrivi_Impianti_remoto(short handleDB, du_impianti_rec_def *impianti, short nOperation );
void 	Carica_PCF();
void 	Carica_SSN();

extern char  *str_tok(char *riga, char *sep, char elemento[], short *stop);
extern short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );

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
	sprintf(log_spooler.NomeDB, "GTT Net Nodes");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");
	
	//****************************************************************************************
	Carica_PCF();
	Carica_SSN();

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

		log(LOG_INFO, "%s;%s; Display Operators ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for modify OP",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW_IMP")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for insert OP",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update OP ",gUtente, gIP);
		Aggiorna_Dati(UPD);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert OP ",gUtente, gIP);
		Aggiorna_Dati(INS);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete OP ",gUtente, gIP);
		Aggiorna_Dati(DEL);
	}

	log_close();

return(0);
}


/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	short		i, rc = 0;
	char		sTmp[500];
	char		acPCFDesc[50];
	char		acSSNDesc[50];

	du_mgt_rec_def		mgt_record;
	du_impianti_rec_def impianti;
	du_impianti_key_def key_impianti;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));
	memset(&impianti, ' ', sizeof(du_impianti_rec_def));

	key_impianti.pcf = 0;
	key_impianti.pc = 0;


	//************** apertura pagina **********************
	Display_TOP("");

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileImpianti, &handle, 1, 0);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle,(char *) &key_impianti, sizeof(du_impianti_key_def), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileImpianti);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			// **************************** TABLE LIST IMPIANTI *************************
			printf("<BR><CENTER>\n");
			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Net Node' onclick=\"javascript:location='%s?OPERATION=NEW_IMP'\" ></TD>\n", gName_cgi);

			printf("<BR><BR><table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH ><strong>&nbsp;PCF</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Point Code</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Global Title</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Type (SSN)</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Short Description</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Full Description</strong></TH>\n");
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
				rc = MBE_READX( handle, (char *) &impianti, (short) sizeof( du_impianti_rec_def) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFileImpianti, rc);
						sprintf(sTmp, "Readx: error %d", rc);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					/***************************
					* Scrive il record a video
					****************************/
					memset(acPCFDesc, 0, sizeof(acPCFDesc));
					for (i = 0; i < 20; i++ )
					{
						if(impianti.primarykey.pcf == pcf_elementi[i].value)
						{
							strcpy(acPCFDesc, pcf_elementi[i].description);
							break;
						}
					}

						// (link) viene disbilitato sul cancella
					printf("<TR class='gradeGreen' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&PCF=%d&PC=%d'\">\n",
							gName_cgi, impianti.primarykey.pcf, impianti.primarykey.pc);


					printf(" <TD onclick='link = true'>&nbsp;[%d] %s</TD>\n", impianti.primarykey.pcf, acPCFDesc);
					fflush(stdout);
					printf(" <TD onclick='link = true'>&nbsp;%d</TD>\n", impianti.primarykey.pc);
					printf(" <TD onclick='link = true'>&nbsp;%.16s</TD>\n", impianti.gt);

					memset(acSSNDesc, 0, sizeof(acSSNDesc));
					for (i = 0; i < 20; i++ )
					{
						if(impianti.ssn_1 == ssn_elementi[i].value)
						{
							strcpy(acSSNDesc, ssn_elementi[i].description);
							break;
						}
					}

					printf(" <TD onclick='link = true'>&nbsp;[%d] %s</TD>\n", impianti.ssn_1, acSSNDesc);
					printf(" <TD onclick='link = true'>&nbsp;%.8s</TD>\n", impianti.short_desc);
					printf(" <TD onclick='link = true'>&nbsp;%s</TD>\n", GetStringNT(impianti.description, 30));

					fflush(stdout);
					printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&PCF=%d&PC=%d', 'Node: PCF[%d] PC[%d] and the associated MGT(s)');\" title='Delete'>",
							gName_cgi, impianti.primarykey.pcf, impianti.primarykey.pc, impianti.primarykey.pcf, impianti.primarykey.pc);
					printf("<div class='del_icon'></div></TD>\n");

					//printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");

					printf("</TR>\n");
					fflush(stdout);
				}
			}/* while (1) */
			
			printf("</tbody>");
			printf("</TABLE>\n");

			printf("</div");
			printf("<BR><BR>\n");
			fflush(stdout);

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Net Node' onclick=\"javascript:location='%s?OPERATION=NEW_IMP'\" >\n", gName_cgi);
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

/*********************************************************************************/
void Maschera_Modifica(short nTipo)
{
	short		handle = -1;
	short		rc = 0, i;
	char		*wrk_str;
	char		sTmp[500];
	char		sTipo[20];
	char		acDisabled[20];

	du_mgt_rec_def mgt_record;
	du_impianti_rec_def impianti;
	du_impianti_key_def chiave_imp;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));
	memset(&impianti, ' ', sizeof(du_impianti_rec_def));
	memset(&chiave_imp, ' ', sizeof( du_impianti_key_def));
	memset(sTmp,		0, sizeof(sTmp));

	/********************* Apertura Pagina ****************************/
	if(nTipo == INS)
	{
		strcpy(sTipo, "Insert");
		strcpy(acDisabled, "  ");
		Display_TOP("Network Nodes Insertion");
	}
	else
	{
		strcpy(sTipo, "Update");
		Display_TOP("Network Nodes Update");
	}
	
	if (( (wrk_str = cgi_param( "PCF" ) ) != NULL ) && (strlen(wrk_str) > 0))
		chiave_imp.pcf = (short) atoi(wrk_str);
	if (( (wrk_str = cgi_param( "PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		chiave_imp.pc = (short) atoi(wrk_str);

	impianti.primarykey.pc = 0;

	if(nTipo == UPD)
	{
		strcpy(acDisabled, "Disabled");
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileImpianti, &handle, 1, 1);
		if (rc == 0)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle,  (char *)&chiave_imp, sizeof(du_impianti_key_def), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, " Error (%d) File_setkey from file [%s]", rc, acFileImpianti);
				log(LOG_ERROR, "%s;%s; : %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				return;
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &impianti, (short) sizeof( du_impianti_rec_def) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) Readx from file [%s]", rc, acFileImpianti );
					log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					return;
				}
			}
			MBE_FILE_CLOSE_(handle);
		}
	}

	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/
	printf("<form method='POST' action='%s' name='inputform' onsubmit='javascript:prepara_valori_GT();return check_net_nodes(%d)'>\n", gName_cgi, nTipo);
	printf("<div class='divContainer opContainer'>\n");
	printf("<div class='divRow'>\n");
	if(s_mgt_by_range != 1)
		printf("<div class='divColumn opColumna1'>\n");

	printf("<fieldset id='fieldsetOper'><legend> Net Node Profile&nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='10' border=0>\n");
	fflush(stdout);
	printf("<TR height='25'></TR>\n");
	printf("<TR>\n");

	printf("<TD align='right'>Point Code Format:</TD>\n");
	printf("<TD align='left'>");
	printf("	<!-- caricamento lista PCF-->");
	printf("<SELECT NAME='PCF'  class='chosen-select' style='width: 270px' %s>\n", acDisabled);

	for(i = 0; i < 20; i++)
	{
		if(pcf_elementi[i].description[0] == 0)
			break;
		printf("<option Value='%d'", pcf_elementi[i].value);

		if(impianti.primarykey.pcf == pcf_elementi[i].value)
			printf(" selected ");

		printf(">");
		printf("[%d] %s", pcf_elementi[i].value, pcf_elementi[i].description);
	}
	printf("</select></TD>\n");

	printf("<TD align=right>Point Code:</TD>\n");
	printf("<TD align=left><input type='text' name='PC' size='5' MAXLENGTH='5' VALUE='%d' class='numeric' %s ></TD>", impianti.primarykey.pc, acDisabled);
	printf("</tr><tr>\n");

	printf("<TD align=right>Global Title:</TD>\n");
	printf("<TD align=left><input type='text'  class='numeric' name='GT' size='16' MAXLENGTH='16' VALUE='%.16s'></TD>", GetStringNT(impianti.gt, 16) );

	printf("<TD align=right>Type (SSN):</TD>\n");
	printf("<TD align='left'>");

	printf("	<!-- caricamento lista SSN-->");
	printf("<SELECT NAME='SSN'  class='chosen-select' style='width: 180px'>\n");

	for(i = 0; i < 20; i++)
	{
		if(ssn_elementi[i].description[0] == 0)
			break;
		printf("<option Value='%d'", ssn_elementi[i].value);

		if(impianti.ssn_1 == ssn_elementi[i].value)
			printf(" selected ");

		printf(">");
		printf("[%d] %s", ssn_elementi[i].value, ssn_elementi[i].description);
	}
	printf("</select></TD>\n");

	printf("</tr><tr>\n");
	printf("<TD align=right>Short description:</TD>\n");
	printf("<TD align=left><input type='text'  name='S_DESC' size='8' MAXLENGTH='8' VALUE='%.8s'></TD>", GetStringNT(impianti.short_desc, 8) );
	printf("</tr><tr>\n");

	printf("<TD align=right>Full description:</TD>\n");
	printf("<TD align=left><input type='text'  name='L_DESC' size='30' MAXLENGTH='30' VALUE='%.30s'></TD>", GetStringNT(impianti.description, 30) );

	printf("</tr><tr>\n");
	/* converte TS nel formato gg/mm/aaaa hh:mm:ss */
	memset(sTmp, 0x00, sizeof(sTmp));
	TS2string(sTmp, impianti.insertts);

	printf("<TD align=right>Insert TS:</TD>\n");
	printf("<TD align=left>%s</TD>", sTmp);
	printf("</tr><tr>\n");

	/* converte TS nel formato gg/mm/aaaa hh:mm:ss */
	memset(sTmp, 0x00, sizeof(sTmp));
	TS2string(sTmp, impianti.lastupdatets);

	printf("<TD align=right>Last Update TS:</TD>\n");
	printf("<TD align=left>%s</TD>", sTmp);

	printf("</TR>\n");
	printf("</TABLE>\n" );

	printf("</fieldset>"); //fieldset Net
	fflush(stdout);

	if(s_mgt_by_range != 1)
	{
		printf("</div>"); //div opColumna1

		/*****************  MGT ********************************
		 Carico i MGT in un'array
		******************************************************/
			printf("\n	<!-- caricamento array GT-->\n");
		printf("<script language='JavaScript'>\n");
		printf("var listaGT = new Array(\n");
	
		rc = Array_MGT(impianti.primarykey.pcf, impianti.primarykey.pc);
		printf( ");\n</script>\n" );

		if(rc != 0)
			return;
	
		printf("<div class='divColumn gtColumna2'>\n");
		printf("<fieldset id='fieldsetOper'><legend>Add MGT into the List&nbsp;</legend>\n");
		printf("<TABLE  width ='100%%' cellspacing='5' align='center' border='0'>\n");
		printf("<TR height='40'></TR>\n");
		printf("<TR>\n");
		printf("<td colspan='2'>  </td>\n");
		printf("<td align='left'>List MGT:</td>\n");
		printf("</TR>");
		printf("<TR><td>");
		printf("<input type='text' class='numeric' name='MGT' size='18' MAXLENGTH=16></td>\n");
		printf("<td width='80' height='40'  align='center' rowspan='1'><nobr>\n\
				<img src='images/right24.png' border=0 alt='Add selected MGT' style='cursor:hand' onClick=\"javascript:addMGT('false');\" onMouseOver=\"javascript:this.src='images/right32.png';\"  onMouseOut=\"javascript:this.src='images/right24.png';\"></nobr><br><nobr>\n\
				</td>\n\
				<td valign='top'  rowspan='2' align='left' >\n\
				<select name='GTSelected' multiple size=15 style='font-family:Courier, monospace; width: 250px'></select>\n\
				</td>\n\
				</tr><TR>\n\
				<TD COLSPAN=2 align='right' valign='bottom'>\n\
				<img src='images/del.gif' border=0 alt='Remove selected MGT' style='cursor:hand' onClick=\"javascript:delGT();\" onMouseOver=\"javascript:this.src='images/del.gif';\"  onMouseOut=\"javascript:this.src='images/del.gif';\">\n\
				</td>\n\
				");

		printf("</TR>");
		printf("</TABLE>\n" );
		printf("</fieldset></div>\n");//fieldset GT
	}
	printf("</div></div>\n");

	printf("\n<script language='JavaScript'>\n\
			setArrayGT();\n\
			</script>\n");

	printf("</TR></TABLE>");
	fflush(stdout);

	printf("<BR>");
	printf("<BR>\n");

	printf("<INPUT TYPE='hidden' name='VALORI' >\n");
	printf("<INPUT TYPE='hidden' name='DELGT' >\n");

	if(nTipo == UPD)
	{
		printf("<INPUT TYPE='hidden' name='PCF' value='%d'>\n", impianti.primarykey.pcf);
		printf("<INPUT TYPE='hidden' name='PC' value='%d'>\n", impianti.primarykey.pc);
	}

	//lo devo passare hidden perchè x l'htm se c'è un solo campo e premo invio il value non viene passato
	printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);

	printf("<center>\n");
	printf("<input type='button'  icon='ui-icon-home'   VALUE='Return To List' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
	printf("<input type='submit'  icon='ui-icon-check'  VALUE='%s' name='OPERATION' >", sTipo);

	printf("</CENTER>\n\
			</form>\n" );


	Display_BOTTOM();

}
/**********************************************************************************************************
 key pcf e pc
**********************************************************************************************************/
short Array_MGT(short nPCF, short nPC)
{
	short		handle = -1;
	short		rc = 0;
	short		nConta = 0;
	short		is_AltKey;
	char		sTmp[500];
	char		acKey[18];

	du_mgt_altkey_def key_MGT;
	du_mgt_rec_def   record_MGT;

	/* inizializza la struttura tutta a blank */
	memset(&record_MGT, ' ', sizeof( du_mgt_rec_def));

	key_MGT.pcf = nPCF;
	key_MGT.pc = nPC;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handle, 1, 0);
	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, (char *) &key_MGT, sizeof(acKey), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{

			sprintf(sTmp, "Error (%d) File_setkey from file [%s]", rc,  acFileMGT);
			log(LOG_ERROR, "%s;%s; : %s",gUtente, gIP, sTmp);
			printf( ");\n</script>\n" );
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
				rc = MBE_READX( handle, (char *) &record_MGT, (short) sizeof( du_mgt_rec_def) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) Readx from file [%s]", rc, acFileMGT);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
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
					// il carattere '*' serve x sapere i record già presenti nel db in caso di cancellazione
					if(nConta == 0)
						printf( "   new Option(\"%.16s*\",\"*%.16s\")\n",record_MGT.mgt, record_MGT.mgt);
					else
						printf( "\n,  new Option(\"%.16s*\",\"*%.16s\")\n",record_MGT.mgt, record_MGT.mgt);
					fflush(stdout);
					nConta++;
				}
			}/* while (1) */
		}

		MBE_FILE_CLOSE_(handle);
	}

	return(rc);	
}
/*************************************************************************************
*  tipo = 0 aggiorna
*  tipo = 1 inserisci
*  tipo = 2 cancella
*************************************************************************************/
void Aggiorna_Dati(short tipo)
{
	short		handleImp = -1;
	short		handleImp_rem = -1;
	short		rc = 0;
	char		*wrk_str;
	char		sTmp[1000];

	du_impianti_rec_def impianti;
	du_impianti_rec_def impianti_backup;
	du_impianti_key_def chiave_imp;

	/* inizializza la struttura tutta a blank */
	memset(&impianti_backup, ' ', sizeof(impianti_backup));
	memset(&impianti, ' ', sizeof(du_impianti_rec_def));
	memset(&chiave_imp, ' ', sizeof( du_impianti_key_def));
	memset(sTmp,		0, sizeof(sTmp));


	if (( (wrk_str = cgi_param( "PCF" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		chiave_imp.pcf = (short) atoi(wrk_str);
		impianti.primarykey.pcf = (short) atoi(wrk_str);
	}
	if (( (wrk_str = cgi_param( "PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		chiave_imp.pc = (short) atoi(wrk_str);
		impianti.primarykey.pc = (short) atoi(wrk_str);
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d", impianti.primarykey.pcf, impianti.primarykey.pc);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	// controllo la lunghezza UTF8 dei campi descrizione
	if (( (wrk_str = cgi_param( "S_DESC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(sTmp, wrk_str);
		rc = Check_LenMsg(sTmp, 1, sizeof(impianti.short_desc), "Short Description");
	}
	if (rc == 0)
	{
		if (( (wrk_str = cgi_param( "L_DESC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			strcpy(sTmp, wrk_str);
			rc = Check_LenMsg(sTmp, 1, sizeof(impianti.description), "Full Description");
		}
	}

	if (rc == 0)
	{
		/******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileImpianti, &handleImp, 1, 1);
		if (rc == 0)
			rc = Apri_File(acFileImpianti_Rem, &handleImp_rem, 1, 1);
	}
	if (rc == 0 && tipo != INS)
	{
		/******************
		* Cerco il record
		******************/

		rc = MBE_FILE_SETKEY_( handleImp, (char *)&chiave_imp, sizeof(du_impianti_key_def), 0, EXACT);
		// errore
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  in Local file [%s]", rc, acFileImpianti);
			log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else		// tutto ok
		{
			rc = MBE_READLOCKX( handleImp, (char *) &impianti, (short) sizeof( du_impianti_rec_def) );
			// errore...
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s]", rc, acFileImpianti);
				log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
				Display_Message(1, "",sTmp);
			}
			else
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&impianti_backup, &impianti, sizeof(impianti));

				if( tipo == DEL) // CANCELLAZIONE
				{
					strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL

			//		rc = MBE_WRITEUPDATEUNLOCKX( handleImp, (char *) &impianti, 0 );
					rc = MBE_WRITEUPDATEX( handleImp, (char *) &impianti, 0 );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) deleting in local file [%s] PCF:%d PC:%d",
								rc, acFileImpianti, impianti.primarykey.pcf, impianti.primarykey.pc);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);

						MBE_UNLOCKREC(handleImp);
					}
					else
					{
						// ********************** Cancello DB REMOTO ***********************************
						rc = scrivi_Impianti_remoto(handleImp_rem, &impianti, DEL );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleImp);

							log(LOG_INFO, "%s;%s; Del NetNodes:%d;%d",	gUtente, gIP, impianti.primarykey.pcf, impianti.primarykey.pc);

							Cancellazione_MGT_ALL(impianti.primarykey.pcf, impianti.primarykey.pc);
						}
						else
						{
							//  ERRORE  DB REMOTO
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handleImp, (char *) &impianti_backup, (short) sizeof(du_impianti_rec_def) );
							if (rc)
							{
								if (rc == 10 )
								{
									sprintf(sTmp, "In Local DB, Net Nodes [%d-%d] already exist", impianti.primarykey.pcf, impianti.primarykey.pc);
									log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
									Display_Message(1, "", sTmp);
								}
								else
								{
									sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileImpianti);
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

					//aggiorno il record con i dati modificati
					Lettura_Variabili(&impianti);

					impianti.lastupdatets =  JULIANTIMESTAMP(0);

			//		rc = MBE_WRITEUPDATEUNLOCKX( handleImp, (char *) &impianti, sizeof( du_impianti_rec_def) );
					rc = MBE_WRITEUPDATEX( handleImp, (char *) &impianti, sizeof( du_impianti_rec_def) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating Local file [%s] - PCF=%d PC=%d", rc, acFileImpianti, impianti.primarykey.pcf, impianti.primarykey.pc);
						log(LOG_INFO, "%s;%s; %s",	gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);

						MBE_UNLOCKREC(handleImp);
					}
					else
					{
						// ************ scrivo DB REMOTO *****************************
						rc = scrivi_Impianti_remoto(handleImp_rem, &impianti, UPD );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleImp);
							log(LOG_INFO, "%s;%s; UPD NetNodes:%d;%d",	gUtente, gIP, impianti.primarykey.pcf, impianti.primarykey.pc);
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handleImp, (char *) &impianti_backup, (short) sizeof(du_impianti_rec_def) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileImpianti);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handleImp);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
						}
					}
				}// fine modifica
			}
		}
	}

	if (rc == 0 && tipo == INS)
	{
		strcpy(log_spooler.TipoRichiesta, "INS");			// LIST, VIEW, NEW, UPD, DEL

		Lettura_Variabili(&impianti);
		impianti.insertts =  JULIANTIMESTAMP(0);

		rc = MBE_WRITEX( handleImp, (char *) &impianti,  sizeof( du_impianti_rec_def) );
		// errore
		if (rc)
		{
			if (rc == 10 )
			{
				log(LOG_ERROR, "%s;%s; Error KEY already exist in %s ",gUtente, gIP, acFileImpianti);
				sprintf(sTmp, "KEY already exist in Local file [%s]",acFileImpianti);
				Display_Message(1, "",sTmp);
			}
			else
			{
				log(LOG_ERROR, "%s;%s; Error Writex from file %s : code %d",gUtente, gIP, acFileImpianti, rc);
				sprintf(sTmp, "Error (%d) writing in Loca file [%s]", rc, acFileImpianti);
				Display_Message(1, "",sTmp);
			}
		}
		else
		{
			// ************ scrivo DB REMOTO *****************************
			rc = scrivi_Impianti_remoto(handleImp_rem, &impianti, INS );
			if(rc == 0)
				log(LOG_INFO, "%s;%s; UPD NET-NODES ",gUtente, gIP);
			else
			{
				// ERRORE Inserimento REMOTO
				//cancello locale
				MBE_FILE_SETKEY_( handleImp, (char *)&chiave_imp, sizeof(du_impianti_key_def), 0, EXACT);
				MBE_READLOCKX( handleImp, (char *) &impianti, (short) sizeof(du_impianti_rec_def) );
				rc = MBE_WRITEUPDATEUNLOCKX( handleImp, (char *) &impianti, 0);
				if(rc)
				{
					sprintf(sTmp, "Error (%d) deleting in  Local file [%s] ", rc, acFileImpianti);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handleImp);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}
	}

	if(rc != 0)
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	if(rc == 0 && tipo != DEL)
	{

		// altro LOG scrittura MGT
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.NomeDB, "MGT");	// max 20 char
		sprintf(log_spooler.ParametriRichiesta, "PCF=%d;PC=%d", impianti.primarykey.pcf, impianti.primarykey.pc);
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		rc = Gestione_MGT(impianti, tipo);

		if(rc == 0 )
			rc = Cancellazione_MGT(impianti);

		if (rc != 0)
			LOGResult = SLOG_ERROR;

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}

	MBE_FILE_CLOSE_(handleImp);
	MBE_FILE_CLOSE_(handleImp_rem);

	if(rc == 0)
	{
		Display_File( );
	}
}

/*********************************************************************************************/
short Gestione_MGT(du_impianti_rec_def impianti, short tipo)
{
	short	handleMGT = -1;
	short	handleMGT_rem = -1;
	short	rc = 0;
	char	*wrk_str;
	char	*pTmp;
	char	sTmp[500];

	du_mgt_rec_def mgt_record;


	/******************
	* Apro il file
	******************/

	rc = Apri_File(acFileMGT, &handleMGT, 1, 1);
	rc = Apri_File(acFileMGT_Rem, &handleMGT_rem, 1, 1);

	if (rc == 0)
	{
		// in VALORI ci sono i seguenti dati:
		// MGT:MGT:........se il primo carattere è '*' non è da inserire perchè già presente
		if (( (wrk_str = cgi_param( "VALORI" ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			pTmp= GetToken(wrk_str, ":");
			while(pTmp != NULL)
			{
				memset(&mgt_record, ' ', sizeof( du_mgt_rec_def));
				if(pTmp[0] != '*')
				{
					memcpy(mgt_record.mgt, pTmp, strlen(pTmp));

					mgt_record.alternatekey.pcf = impianti.primarykey.pcf;
					mgt_record.alternatekey.pc  = impianti.primarykey.pc;
					
					if(tipo == UPD)
						mgt_record.lastupdatets = JULIANTIMESTAMP(0);
					else
						mgt_record.insertts = JULIANTIMESTAMP(0);

					rc = MBE_WRITEX( handleMGT, (char *) &mgt_record,  sizeof( du_mgt_rec_def) );
					// errore
					if (rc)
					{
						if (rc == 10 )
						{
							sprintf(sTmp, "KEY (%d - %d) already exist in Local File [%s]", mgt_record.alternatekey.pcf, mgt_record.alternatekey.pc, acFileMGT);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							break;
						}
						else
						{
							sprintf(sTmp, "Error (%d) writing in Local file [%s]", rc, acFileMGT);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							break;
						}
					}
					else
					{
						// ********** scrivo in DB REMOTE ******************
						rc = MBE_WRITEX( handleMGT_rem, (char *) &mgt_record,  sizeof( du_mgt_rec_def) );
						// errore
						if (rc != 0)
						{
							if (rc == 10 )
							{
								sprintf(sTmp, "KEY (%d - %d) already exist in Remote File [%s]", mgt_record.alternatekey.pcf, mgt_record.alternatekey.pc, acFileMGT_Rem);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "",sTmp);
							}
							else
							{
								sprintf(sTmp, "Error (%d) writing in Remote file [%s]", rc, acFileMGT_Rem);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "",sTmp);
							}

							// ERRORE Inserimento REMOTO
							//cancello locale
							MBE_FILE_SETKEY_( handleMGT, (char *) &mgt_record.mgt, (short)sizeof(mgt_record.mgt), 0, EXACT);
							MBE_READLOCKX( handleMGT, (char *) &mgt_record, (short) sizeof(du_mgt_rec_def) );
							rc = MBE_WRITEUPDATEUNLOCKX( handleMGT, (char *) &mgt_record, 0);
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in deleting Local file [%s]", rc, acFileMGT);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handleMGT);
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

		MBE_FILE_CLOSE_(handleMGT);
		MBE_FILE_CLOSE_(handleMGT_rem);
	}
	return(rc);
}

/*********************************************************************************************/
short Cancellazione_MGT_ALL(short nPCF, short nPC)
{
	short		handle = -1;
	short		handleMGT_Rem = -1;
	short		rc = 0;
	short		is_AltKey;
	char		sTmp[500];

	du_mgt_rec_def 		mgt_record;
	du_mgt_rec_def 		mgt_record_tmp;
	du_mgt_altkey_def 	altchiave_mgt;

	// inizializza la struttura tutta a blank
	memset(&mgt_record, ' ', sizeof( du_mgt_rec_def));
	memset(&altchiave_mgt, ' ', sizeof( du_mgt_altkey_def));

	altchiave_mgt.pcf = nPCF;
	altchiave_mgt.pc  = nPC;

	/******************
	* Apro il file
	******************/
	rc = Apri_File(acFileMGT, &handle, 1, 1);
	if (rc == 0)
		rc = Apri_File(acFileMGT_Rem, &handleMGT_Rem, 1, 1);

	if (rc == 0)
	{
		//  ricerca  per chiave alternata
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, (char *) &altchiave_mgt, sizeof(du_mgt_altkey_def), is_AltKey, GENERIC, 0);
		// errore
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey from Local file [%s]", rc, acFileMGT);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		// tutto ok
		else
		{
			rc = MBE_FILE_SETKEY_( handleMGT_Rem, (char *) &altchiave_mgt, sizeof(du_mgt_altkey_def), is_AltKey, GENERIC, 0);
			 //errore
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey from Remote file [%s]", rc, acFileMGT_Rem);
				log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
	}

	if(rc == 0)
	{
		while ( 1 )
		{
			rc = MBE_READLOCKX( handle, (char *) &mgt_record, (short) sizeof( du_mgt_rec_def) );
			 //errore...
			if ( rc)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) reading in Local file [%s] - PCF=%d PC=%d", rc, acFileMGT, altchiave_mgt.pcf, altchiave_mgt.pc);
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);

					Display_Message(1, "",sTmp);
				}
				else
					rc = 0;
				break;
			}
			else
			{
				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &mgt_record, 0 );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) deleting in Local file [%s] ", rc, acFileMGT);
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "",sTmp);
					MBE_UNLOCKREC(handle);
					break;
				}
				else
				{
					// *************aggiorno DB REMOTO*******************
					rc = MBE_READLOCKX( handleMGT_Rem, (char *) &mgt_record_tmp, (short) sizeof( du_mgt_rec_def) );
					 //errore...
					if ( rc)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) reading in Remote file [%s] - PCF=%d PC=%d", rc, acFileMGT, altchiave_mgt.pcf, altchiave_mgt.pc);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
						}
						else
							rc = 0;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleMGT_Rem, (char *) &mgt_record, 0 );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) deleting in Remote file [%s] ", rc, acFileMGT_Rem);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleMGT_Rem);
						}
					}
					if (rc != 0)
					{
						//  ERRORE DB REMPOTO
						// Inserisco rec in db Locale
						rc = MBE_WRITEX( handle, (char *) &mgt_record, (short) sizeof(du_mgt_rec_def) );
						// errore
						if (rc)
						{
							sprintf(sTmp, "Error (%d) in writing in Local file [%s]", rc, acFileMGT);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
						}

						// setto rc a 1 per segnalare errore
						rc = 1;
						break;
					}
				}
			}
		}// fine while
	}

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handleMGT_Rem);
	return(rc);
}


/*********************************************************************************************/
short Cancellazione_MGT(du_impianti_rec_def impianti)
{
	short		handleMGT = -1;
	short		handleMGT_rem = -1;
	short		rc = 0;
	char		sTmp[500];
	char		*pTmp;
	char		*wrk_str;

	du_mgt_rec_def mgt_record;

	/******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handleMGT, 1, 1);
	rc = Apri_File(acFileMGT_Rem, &handleMGT_rem, 1, 1);

	if (rc == 0)
	{
		// in VALORI ci sono i seguenti dati:
		// GT:GT:........
		if (( (wrk_str = cgi_param( "DELGT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		{
			pTmp= GetToken(wrk_str, ":");
			//IL PRIMO CHR DI gt è '*'
			while(pTmp != NULL)
			{
				// inizializza la struttura tutta a blank
				memset(&mgt_record, ' ', sizeof( du_mgt_rec_def));
				memcpy(mgt_record.mgt, pTmp+1, strlen(pTmp));

				rc = MBE_FILE_SETKEY_( handleMGT, mgt_record.mgt, (short)sizeof(mgt_record.mgt), 0, EXACT);
				// errore
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File_setkey Local file [%s] ", rc, acFileMGT);
					log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					break;
				}
				// tutto ok
				else
				{
					rc = MBE_READLOCKX( handleMGT, (char *) &mgt_record, (short) sizeof( du_mgt_rec_def) );
					// errore...
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) reading in Local file [%s] - MGT=%.16s", rc, acFileMGT, mgt_record.mgt);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);
						break;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleMGT, (char *) &mgt_record, 0 );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) updating in Local file [%s] - MGT=%.16s", rc, acFileMGT, mgt_record.mgt);
							log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleMGT);
							break;
						}
					}
				}

				// *********CANCELLAZIONE DB REMOTO *********************
				rc = MBE_FILE_SETKEY_( handleMGT_rem, mgt_record.mgt, (short)sizeof(mgt_record.mgt), 0, EXACT);
				// errore
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File_setkey Remote file [%s] ", rc, acFileMGT_Rem);
					log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					break;
				}
				 //tutto ok
				else
				{
					rc = MBE_READLOCKX( handleMGT_rem, (char *) &mgt_record, (short) sizeof( du_mgt_rec_def) );
					// errore...
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) reading in Remote file [%s] - MGT=%.16s", rc, acFileMGT_Rem, mgt_record.mgt);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);
						break;
					}
					else
					{
						rc = MBE_WRITEUPDATEUNLOCKX( handleMGT_rem, (char *) &mgt_record, 0 );
						if (rc != 0)
						{
							sprintf(sTmp, "Error (%d) updating in Remote file [%s] - MGT=%.16s", rc, acFileMGT_Rem, mgt_record.mgt);
							log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
							Display_Message(1, "",sTmp);
							MBE_UNLOCKREC(handleMGT);

							// *********** ERRORE Cancellazione DB REMOTO *****************
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handleMGT, (char *) &mgt_record, (short) sizeof(du_mgt_rec_def) );
							 //errore
							if (rc)
							{
								sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileMGT);
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

		MBE_FILE_CLOSE_(handleMGT);
		MBE_FILE_CLOSE_(handleMGT_rem);
	}
	return(rc);
}


/*****************************************************************************************************/
void Carica_PCF()
{
	int		found;
	short	i = 0;
	short	stop;
	char	ac_wrk_str[1024];
	char	sDati[100];
	char	*pVal;

	memset(&pcf_elementi, 0, sizeof(pcf_elementi));

	get_profile_string(ini_file, "GTT", "PC-FORMATS", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		str_tok(ac_wrk_str, "|", sDati, &stop);

		while ((stop != 1) &&  (i < 20) )
		{
			pVal= strtok(sDati, ";");
			if(pVal)
				pcf_elementi[i].value = (short) atoi(pVal);	//valore

			pVal= strtok(NULL, ";");
			if(pVal)
				strcpy(pcf_elementi[i].description , pVal);  //descrizione

			i++;
			// rileggo  str_tok
			str_tok(NULL, "|", sDati, &stop);
		}
	}
}

/*****************************************************************************************************/
void Carica_SSN()
{
	int		found;
	short	i = 0;
	short	stop;
	char	ac_wrk_str[1024];
	char	sDati[100];
	char	*pVal;

	memset(&ssn_elementi, 0, sizeof(ssn_elementi));

	get_profile_string(ini_file, "GTT", "SSN-TYPES", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		str_tok(ac_wrk_str, "|", sDati, &stop);

		while ((stop != 1) &&  (i < 20) )
		{
			pVal= strtok(sDati, ";");
			if(pVal)
				ssn_elementi[i].value = (short) atoi(pVal);	//valore

			pVal= strtok(NULL, ";");
			if(pVal)
				strcpy(ssn_elementi[i].description , pVal);  //descrizione

			i++;
			// rileggo  str_tok
			str_tok(NULL, "|", sDati, &stop);
		}
	}
}

//***************************************************************************
void Lettura_Variabili(	du_impianti_rec_def *impianti)
{
	char	*wrk_str;
	char	sTmp[500];

	memset(sTmp, 0 , sizeof(sTmp));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	memset(impianti->gt, ' ', sizeof(impianti->gt));
	if (( (wrk_str = cgi_param( "GT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(impianti->gt, wrk_str, strlen(wrk_str));

	impianti->ssn_1 = 0;
	if (( (wrk_str = cgi_param( "SSN" ) ) != NULL ) && (strlen(wrk_str) > 0))
		impianti->ssn_1 = (short) atoi(wrk_str);

	memset(impianti->short_desc, ' ', sizeof(impianti->short_desc));
	if (( (wrk_str = cgi_param( "S_DESC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(impianti->short_desc, wrk_str, strlen(wrk_str));

	memset(impianti->description, ' ', sizeof(impianti->description));
	if (( (wrk_str = cgi_param( "L_DESC" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(impianti->description, wrk_str, strlen(wrk_str));

}
//******************************************************************************************************
short scrivi_Impianti_remoto(short handleDB, du_impianti_rec_def *impianti, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	du_impianti_rec_def impianti_tmp;
	du_impianti_key_def chiave_imp;

	chiave_imp.pcf = impianti->primarykey.pcf;
	chiave_imp.pc = impianti->primarykey.pc;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB,   (char *)&chiave_imp, (short)sizeof(chiave_imp), 0, EXACT);
			/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFileImpianti_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &impianti_tmp, (short) sizeof(du_impianti_rec_def) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFileImpianti_Rem);
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) impianti, (short) sizeof(du_impianti_rec_def) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] ", rc, acFileImpianti_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) impianti, (short) sizeof(du_impianti_rec_def) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Record already exist in REMOTE file [%s]", acFileImpianti_Rem);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFileImpianti_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) impianti, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] ", rc, acFileImpianti_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
	}
	return(rc);
}
