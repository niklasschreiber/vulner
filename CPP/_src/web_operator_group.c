/*----------------------------------------------------------------------------
*   PROGETTO : Gruppo Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : groper.c
*   Ultima Modifica :  08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione  DB gruppo operatori
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

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"

/*------------- PROTOTIPI -------------*/
void  Display_File();
void  Maschera_Modifica(short tipo);
void  Aggiorna_Dati(short tipo);
void  Cancella_Gruppo(short Tipo, short nFlag);
// 2018 KTSTEA10_ADV
//short Aggiorna_Operatori_Gr(char *ac_GRP, char *ac_CodOp, char *ac_CC, short nUpdGRPA, short handleOP, short handleOP_rem);
short Aggiorna_Operatori_Gr(char *ac_GRP, char *ac_CodOp, char *ac_CC, short handleOP, short handleOP_rem);
short GrOP_InSoglie(char *ac_Key, short Tipo);
long  ContaRecord(char *ac_Key, short handle);
short Carico_OP_Gruppo(char *acGruppo);
short Lista_Operatori(void);
short Aggiorna_Paesi(char *Paese, char *Gruppo, short handle_Paese, short handlePA_rem );
short Cacello_SingoloOPdaGR(short handle, char *ac_gr, char *ac_cod, char *ac_Pa);
short Cancella_Gruppo_Paesi(char *Gruppo, short handlePA, short handlePA_rem);
void  Paesi_daNon_Caricare(void);
short Cerca_Gruppo(short handleGrp, char *ac_GRP);

extern short Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern short scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation );
extern char  *str_tok(char *riga, char *sep, char elemento[], short *stop);
extern short Aggiorno_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi );
extern short Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );

AVLTREE	lista_OP;
AVLTREE	lista_Appo;
AVLTREE	lista_PAnoCaricare;

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
	sprintf(log_spooler.NomeDB, "Operators Group");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	/* tipo operazione */
	memset(sOperazione, 0x00, sizeof(sOperazione));

	strcpy(sOperazione, "DISPLAY");	//default
	if ( (wrk_str = cgi_param( "OPERATION" ) ) != NULL )
		strcpy(sOperazione, wrk_str);

		//-------------------------------------------------------------------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "ALL");
		strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;

		log(LOG_INFO, "%s;%s; Display Operators Group ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Window Modify  ",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Window Insert  ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Update  ",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Insert  ",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Delete OP  ",gUtente, gIP);
		Aggiorna_Dati(2);
	}
	else if (strcmp(sOperazione, "ConfDelGRP")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Delete Group  ",gUtente, gIP);
		Cancella_Gruppo(1, 0);
	}
	else if (strcmp(sOperazione, "DELALL")== 0 )
	{
		log(LOG_INFO, "%s;%s; Operators Group - Delete Group  ",gUtente, gIP);
		Cancella_Gruppo(2, 0);
	}
	
	log_close();

	return(0);
}

/******************************************************************************/
// nTipo = 0  chiamata da DISLPLAY
// nTipo = 0  chiamata da RICERCA
// nTipo = 2  chiamata da altre funzioni
/******************************************************************************/
void Display_File()
{
	short		handle = -1;
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP];
	char		acGruppo[LEN_GRP+ 1];
	char		acTRClass[20];
	char		acTDClass[20];
	char		acGrpdecod[100];
	short		rc = 0;
	short		is_AltKey;
	char		cColore = 'b';
	long		nCambio = 0;

	t_ts_oper_record record_gruppoOp;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acGruppo,   'x', 5);

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 0);
	if (rc == 0)
	{
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey in Local file [%s] ", rc, acFileOperatori_Loc );
			log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			Display_TOP("");

			printf("<BR><CENTER>");
			printf( "<input type='button' icon='ui-icon-circle-plus' VALUE='New Group' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='nosort' >\n"); // non permette il sort

			printf("<thead>\n");
			printf("  <TH ><strong>&nbsp;Group</strong></TH>\n");
			printf("  <TH width='5%%'>&nbsp;</TH>\n");
			printf("  <TH ><strong>&nbsp;Operator Code</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Country Code</strong></TH>\n");
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
				rc = MBE_READX( handle, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp );
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if ( (memcmp(record_gruppoOp.gruppo_op, "********************", 8) ) && (memcmp(record_gruppoOp.gruppo_op, "            ", 8)) )
					{
						/***************************
						* Scrive il record a video
						****************************/
						nCambio = 0;
						strcpy(acTDClass, "groupGhost");

						// se sono diversi scrivo il gruppo
						if(memcmp(acGruppo, record_gruppoOp.gruppo_op, sizeof(record_gruppoOp.gruppo_op)) )
						{

							if (cColore == 'n')
								cColore = 'b';
							else
								cColore = 'n';
							nCambio = 1; // cambio gruppo
							strcpy(acTDClass, "groupBlack");
						}

						if(cColore == 'n')
							strcpy(acTRClass, "groupGreen");
						else if(cColore == 'b')
							strcpy(acTRClass, "groupwhite");

						memset(acGrpdecod, 0, sizeof(acGrpdecod));
						memcpy(acGrpdecod, record_gruppoOp.gruppo_op, sizeof(record_gruppoOp.gruppo_op));
						CambiaCar(acGrpdecod);
						printf("<TR class='%s' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&GRUPPO=%s'\">\n",
									acTRClass, gName_cgi, acGrpdecod);
						printf("  <TD class='%s' onclick='link = true'>&nbsp;%.64s</TD>\n", acTDClass, record_gruppoOp.gruppo_op);
						fflush(stdout);

						memset(sTmp, 0, sizeof(sTmp));
						strncpy(sTmp, record_gruppoOp.gruppo_op, LEN_GRP);
						AlltrimString(sTmp);

						if (nCambio)
						{
							printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=ConfDelGRP&GRUPPO=%s', 'Group: [%s]');\">",
									gName_cgi, acGrpdecod , sTmp);
						//	printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");
							printf("<div class='del_icon'></div></TD>\n");
							fflush(stdout);
						}
						else
						{
							printf("  <TD>&nbsp;</TD>");
						}

						printf("  <TD onclick='link = true'>&nbsp;%.10s</TD>\n", record_gruppoOp.cod_op);
						printf("  <TD onclick='link = true'>&nbsp;%.8s</TD>\n", record_gruppoOp.paese);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&GRUPPO=%s&COD_OP=%.10s&PAESE=%.8s', 'Operator: CC[%s] CodOP[%s] from Group[%s]');\">",
								gName_cgi, acGrpdecod, record_gruppoOp.cod_op, record_gruppoOp.paese,
								GetStringNT(record_gruppoOp.paese, 8), GetStringNT(record_gruppoOp.cod_op, 10), sTmp);
							//printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete Operator' ></TD>\n");
						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
						fflush(stdout);

						// salvo il gruppo
						memcpy(acGruppo, record_gruppoOp.gruppo_op, sizeof(record_gruppoOp.gruppo_op));
					}
				}
			}/* while (1) */
			
			printf("</tbody>");
			printf("</TABLE>\n");
			printf("<BR><BR>\n");
			fflush(stdout);

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Group' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);
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
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s", gUtente, gIP, acFileOperatori_Loc);
		LOGResult = SLOG_ERROR;
	}

	return;
}

//*******************************************************************************************
void Maschera_Modifica(short tipo)
{
	short		rc = 0;
	char		*wrk_str;
	char		sTmp[500];
	char		ac_Gruppo[LEN_GRP+1];
	char		sTipo[20];

	t_ts_oper_record record_gruppoOp;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));
	memset(ac_Gruppo,     0, sizeof(ac_Gruppo));

	memset(sTmp, 0, sizeof(sTmp));
	
	if (tipo == 0)
	{
		if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcpy(ac_Gruppo, wrk_str);

		sprintf(sTmp, "Add Operators to Group: %s", ac_Gruppo);
		strcpy(sTipo, "Update");
		
		log(LOG_INFO, "%s;%s; ViewOG:%s",gUtente, gIP, ac_Gruppo);
	}
	else
	{
		sprintf(sTmp, "OPERATOR GROUPS - New Group");
		strcpy(sTipo, "Insert");
	}

	Display_TOP("");
	
	rc = Lista_Operatori();
	if(rc == 0 )
	{
		/************************************************
		* Creo l'array con i dati già inseriti nel DB
		*************************************************/
		printf("	<!-- caricamento array Operatori del DB-->");
		printf("<script language='JavaScript'>\n");
		
		printf(	"var listaDB = new Array(\n");
		if (tipo == 0)//modifica
			rc= Carico_OP_Gruppo(ac_Gruppo);

		printf( ");\n</script>\n" );
	}
	if(rc == 0 )
	{
		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<form method='POST' action='%s' name='inputform' onsubmit='javascript:prepara_valori();return CheckGroupName(%d)'>\n", gName_cgi, tipo);
		printf("<INPUT TYPE='hidden' name='RECDISPLAY' value='%d' >\n");
		printf("<br><br>\n");
		printf("<fieldset><legend> %s &nbsp;</legend>\n", sTmp);

		printf("<TABLE width ='100%%' cellspacing=8 border=0>\n\
				<TR>\n");
		fflush(stdout);
		//mi serve x non modificare delle funzioni javascript utilizzate da PPLMN.cgi 
		// dove settano id_tot
		printf("<font id=id_tot style='visibility:hidden'></font>");
		printf("<TD align='right'><B>Group name:&nbsp;</B></td>\n");
		printf("<TD colspan='2' align='left'>\n");

		if(tipo == 1)
		{
			printf("<INPUT TYPE='text' SIZE='65' MAXLENGTH=64 NAME='GRUPPO'></TD>\n");
		//	printf("<TD colspan='2'><B>Creation Country Group&nbsp;&nbsp;</B>\n");
		}
		else
			printf("%s</TD>\n", ac_Gruppo);

	//	printf("<TD colspan='2'><B>Update Country Group&nbsp;&nbsp;</B>\n");
	//	printf("<INPUT TYPE='checkbox' NAME='GRUPPO_PAESI' checked></td>");
		printf("</TR>\n");

		printf("<tr height='45'><td colspan='5'><hr id='hrBlue'></td></tr>\n");

		printf("<TR>\n");
		printf("<TD align='right'><B>Country: </B></td>\n");
		printf("<td align='left'><select name='countrySelect' data-placeholder='Choose a Country...' class='chosen-select' onChange=\"document.inputform.fOperator.value = ''; setMNC(selectedIndex);\"></select>\n\
					</td>\n");

		printf("</TR>\n");
		printf("<TR>\n");
		printf("<td rowspan='4'></td>\n"); //colonna a sinistra vuota
		printf("<td colspan='3' align='left' valign='bottom' id='fontblue'><B>Operators list </B></td>\n\
				<td colspan='1' align='left' valign='bottom' id='fontblue'><B>Operators in the group </B></td>\n");
		printf("</tr>\n");
		printf("<tr>\n");
		printf("<td colspan='1' rowspan='2' width='300' align='left'>\n\
				<select name='operatorSelect' id='selectList' multiple size=15></select>\n\
					</td>\n");
	    printf("<td width='80' height='40' align='right' valign='bottom' rowspan='1' ><nobr>\n\
					<img src='images/right24.png' border=0 title='Add selected operators' style='cursor:hand' onClick=\"javascript:addOpinGRP('false');\" onMouseOver=\"javascript:this.src='images/right32.png';\"  onMouseOut=\"javascript:this.src='images/right24.png';\"></nobr>\n\
					</td>\n\
					<td width='80' height='40'  align='left' valign='bottom' rowspan='1' ><nobr>\n\
						<img src='images/left24.png' border=0 title='Remove selected operators' style='cursor:hand' onClick=\"javascript:delOperators();\" onMouseOver=\"javascript:this.src='images/left32.png';\"  onMouseOut=\"javascript:this.src='images/left24.png';\">\n\
					</td>\n");

        printf("<td colspan='1' rowspan='2' align='left'>\n\
				    <select name='operatorSelected' id='selectList' multiple size=15 ></select></tt>\n\
					</td>\n\
					</tr>\n\
					<tr>\n\
					<td width='80' height='40'  align='right' valign='top'  rowspan='1' ><nobr>\n\
						<nobr>\n\
					<img src='images/rightall24.png' border=0 title='Add all operators' onClick=\"javascript:addOpinGRP('true');\" onMouseOver=\"javascript:this.src='images/rightall32.png';\"  onMouseOut=\"javascript:this.src='images/rightall24.png';\" ></nobr>\n\
					</td>\n\
					<td width='80' height='40' align='left' valign='top' rowspan='1' ><nobr>\n\
						<img src='images/leftall24.png' border=0 title='Remove all operators' style='cursor:hand' onClick=\"javascript:delAllOperators();\" onMouseOver=\"javascript:this.src='images/leftall32.png';\"  onMouseOut=\"javascript:this.src='images/leftall24.png';\">\n\
					</td>\n\
					</tr>\n");

        printf("<input TYPE='hidden' name='fOperator'  value='' >\n");
		fflush(stdout);

		printf("</TABLE>\n");
		printf("</fieldset>\n");
		printf("<CENTER>\n");

		printf("<BR><BR>\n");

		printf("<INPUT TYPE='hidden' name='VALORI' >\n");
		if (tipo == 0)
			printf("<INPUT TYPE='hidden' name='GRUPPO' value='%s'>\n", ac_Gruppo);

		printf("<input type='button'  icon='ui-icon-home'  VALUE='Return To List' onclick=javascript:location='%s'>\n", gName_cgi);
		printf("<input type='submit'  icon='ui-icon-check' VALUE='%s' name='OPERATION' >", sTipo);

		printf("</CENTER>\n\
				</form>\n\
			  ");	

		printf("<script> setMCC(); setMNC(0); setBackgroundColor();setListaDB();normalizzaOption(document.inputform.operatorSelected);</script>");
	}

	Display_BOTTOM();
}

//************************************************************************
// tipo == 0 modifica
// tipo == 1 inserimento 
// tipo == 2 cancellazione

// Controlla se ci sono record nel DB soglie con  Grp Operatore uguale a quello aggiornato
// aggiorno record '*****' del DB Operatori
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	short		handleOP = -1;
	short		handleOP_rem = -1;
	short		handlePaesi = -1;
	short		handlePaesi_rem = -1;
	short		rc = 0;
	//short		nUpdGRPA = 0;
	short		stop;
	char		*wrk_str;
	char		ac_GRP[70];
	char		sDati[100];
	char		ac_Cod[20];
	char		*pVal;
	long		nRec = 0;
	char		ac_Pa[20];
	char		acCC[20];

	t_ts_oper_record record_gruppoOp;
	t_ts_oper_record record_appo;

	
	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));
	memset(&record_appo, ' ', sizeof(t_ts_oper_record));

	memset(ac_Cod, 0, sizeof(ac_Cod));
	memset(ac_GRP, 0, sizeof(ac_GRP));
	memset(ac_Pa, 0, sizeof(ac_Pa));

	if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(ac_GRP, wrk_str);
		rc = Check_LenMsg(ac_GRP, 1, LEN_GRP, "Operator Group");
		if(rc != 0)
			return;
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s", AlltrimString(ac_GRP) );
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	// flag che indica se aggiornare anche il gruppo Paesi
	//2018 KTSTEA10_ADV
	//if (( (wrk_str = cgi_param( "GRUPPO_PAESI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	//	nUpdGRPA = 1;


	/**********************************************
	* Apro il file gruppo Operatori e file Oeratori
	***********************************************/
	rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening Local file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
		return;
	}
	rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening Remote file %s (%d)", gUtente, gIP, acFileOperatori_Rem, rc);
		return;
	}
	rc = Apri_File(acFilePaesi_Loc, &handlePaesi, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
		return;
	}
	rc = Apri_File(acFilePaesi_Rem, &handlePaesi_rem, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFilePaesi_Rem, rc);
		return;
	}

	if (rc == 0 && tipo == UPD || tipo == INS)
	{
		if(tipo == UPD ) //  se in modifica cancello la lista e poi riscrivo tutto
		{
			Cancella_Gruppo(2, 1);
			strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
		}
		else
		{
			strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL

			//in inserimento se il gruppo c'è esco
			rc = Cerca_Gruppo(handleOP, ac_GRP);
			if(rc != 0)
				return;
			log(LOG_DEBUG, "%s;%s; OK -  Gruppo %s  non trovato", gUtente, gIP, AlltrimString(ac_GRP) );
		}

		// se devo aggiornare anche paesi
	//	if(nUpdGRPA == 1)
	//		rc = Cancella_Gruppo_Paesi(ac_GRP, handlePaesi, handlePaesi_rem);

		if(rc == 0)
		{
			// in VALORI ci sono i seguenti dati:
			// Cod OP;CC:Cod OP;CC:........
			if (( (wrk_str = cgi_param( "VALORI" ) ) != NULL ) && (strlen(wrk_str) > 0))
			{

				str_tok(wrk_str, ":", sDati, &stop);
				while (stop != 1)
				{
					pVal= strtok(sDati, ";");
					if(pVal)
						strcpy(ac_Cod, pVal);	//codice operatore

					pVal= strtok(NULL, ";");
					if(pVal)
						strcpy(ac_Pa, pVal);  //CC

					//Aggiorno il DB local e remote
					// KTSTEA10_ADV Tolta gestione gruppo Paesi
					//rc = Aggiorna_Operatori_Gr(ac_GRP, ac_Cod, ac_Pa, nUpdGRPA, handleOP, handleOP_rem);
					rc = Aggiorna_Operatori_Gr(ac_GRP, ac_Cod, ac_Pa, handleOP, handleOP_rem);

					if(rc != 0)
						break;

					//******************************************************************************************
					//  se c'è flag  AGGIORNO GRUPPO PAESI
					//******************************************************************************************
			/*		if(rc == 0 && nUpdGRPA == 1)
						rc = Aggiorna_Paesi(ac_Pa, ac_GRP, handlePaesi, handlePaesi_rem);
					if(rc != 0)
						break;
			 */

					// rileggo  str_tok
					str_tok(NULL, ":", sDati, &stop);
				}

			}// fine cgi_param VALORI
		}
	} // Fine Inserimento o Modifica



	//******************************************************************************************
	// CANCELLAZIONE
	//******************************************************************************************
	if (rc == 0 && tipo == DEL)
	{
		if (( (wrk_str = cgi_param( "COD_OP" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcpy(ac_Cod, wrk_str);
		if (( (wrk_str = cgi_param( "PAESE" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcpy(ac_Pa, wrk_str);

		strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
		sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s;Paese=%s;Cod OP=%s", AlltrimString(ac_GRP), AlltrimString(ac_Pa), ac_Cod);

		// conto quanti record ci sono di quel gruppo
		nRec = ContaRecord(ac_GRP, handleOP);

		// se c'è un solo record significa che viene eliminato il gruppo e quindi
		// devo eliminare anche i record nel db soglie 
		if (nRec == 1)
		{
			rc = GrOP_InSoglie(ac_GRP, 1);
			if (rc == 99)// non ci sono soglie aggiorno db
				nRec = 2;
		}
		if (nRec != 1)
		{
				// aggiorno il db operatori
				memset(ac_GRP, ' ', LEN_GRP);
				rc = Aggiorna_Operatori_Gr(ac_GRP, ac_Cod, ac_Pa, handleOP, handleOP_rem);
				if(rc == 0)
					log(LOG_INFO, "%s;%s; Del OPGRP %s:%s%s",gUtente, gIP, ac_GRP, acCC,ac_Cod);
		}
	}

	if(rc == 0)
		// aggiorna rec *
		rc = Aggiorna_Operatori_rec_Aster(handleOP, handleOP_rem);
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);


	MBE_FILE_CLOSE_(handleOP);
    MBE_FILE_CLOSE_(handleOP_rem);
	MBE_FILE_CLOSE_(handlePaesi);
	MBE_FILE_CLOSE_(handlePaesi_rem);

	if (rc == 0 && nRec != 1)
	{
		// alla display passo il gruppo
		Display_File();
	}		
}
//****************************************************************************************************
short Cacello_SingoloOPdaGR(short handle, char *ac_gr, char *ac_cod, char *ac_Pa)
{
	short rc = 0;
	char  sTmp[500];
	char ac_Chiave[82];
	t_ts_oper_record record_appo;

	memset(&record_appo, ' ', sizeof(t_ts_oper_record));
	memcpy(record_appo.gruppo_op, ac_gr, strlen(ac_gr));
	memcpy(record_appo.cod_op, ac_cod, strlen(ac_cod));
	memcpy(record_appo.paese, ac_Pa, strlen(ac_Pa));
	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, (char*) &record_appo, (short)sizeof(record_appo.gruppo_op)+ sizeof(record_appo.cod_op)+ sizeof(record_appo.paese), 0, EXACT);
	if (rc == 0)
	{
		/*******************
		* Leggo il record
		*******************/
		rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_oper_record) );
		/* trovato lo cancello */
		if ( !rc)
		{
			rc = MBE_WRITEUPDATEX( handle, (char *) &record_appo, 0 );
			if ( rc)
			{
				log(LOG_ERROR, "%s;%s; Error Delete file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
				sprintf(sTmp, "Delete (%s) - writeupdatex: error %d", acFileOperatori_Loc, rc);
				Display_Message(1, "", sTmp);
			}
			else
			{
				memset(sTmp, 0, sizeof(sTmp));
				memcpy(sTmp, record_appo.gruppo_op, sizeof(record_appo.gruppo_op));
				AlltrimString(sTmp);
			}
		}
		else
		{
			sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
	}
	else
	{
		log(LOG_ERROR, "%s;%s; Error File_setkey file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
		sprintf(sTmp, "Delete (%s) -  File_setkey: error %d", acFileOperatori_Loc, rc);
		Display_Message(1, "", sTmp);
	}

	return(rc);
}
//***************************************************************************************
// Tipo == 1 mostro l'elenco dei record da cancellare
// Tipo == 2 cancello i record
//***************************************************************************************
void Cancella_Gruppo(short Tipo, short nFlag)
{
	char		*wrk_str;
	char		sTmp[500];
	char		ac_GRP[70];
	char		ac_Chiave[LEN_GRP];
	short		handleOP = -1;
	short		handleOP_rem = -1;
	short		rc = 0;
	short		is_AltKey;

	t_ts_oper_record record_gruppoOp;
	t_ts_oper_record record_OP_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));
	memset(&record_OP_backup, ' ', sizeof(t_ts_oper_record));

	memset(ac_GRP, 0, sizeof(ac_GRP));
	memset(ac_GRP, ' ', LEN_GRP);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(ac_Chiave, wrk_str, strlen(wrk_str));
	}

	if(nFlag == 0)
		rc = GrOP_InSoglie(ac_Chiave, Tipo);
	if (rc == 99)
	{
		Tipo = 2;
		rc = 0;
		log(LOG_INFO, "%s;%s; DEL GROP: %.64s",gUtente, gIP, ac_Chiave);
	}

	if (rc == 0 && Tipo == 2)
	{
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
			return;
		}
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileOperatori_Rem, rc);
			return;
		}

		if (rc == 0 )
		{
			/*******************
			* Cerco il record
			*******************/
			is_AltKey = 1;
			rc = MBE_FILE_SETKEY_( handleOP, ac_Chiave, (short)sizeof(ac_Chiave), is_AltKey, GENERIC);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey in Local file [%s] ", rc, acFileOperatori_Loc );
				log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				is_AltKey = 1;
				rc = MBE_FILE_SETKEY_( handleOP_rem, ac_Chiave, (short)sizeof(ac_Chiave), is_AltKey, GENERIC);
				/* errore */
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File_setkey in Remote file [%s] ", rc, acFileOperatori_Rem );
					log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			if(rc == 0)
			{
				while ( 1 )
				{
					rc = MBE_READLOCKX( handleOP, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
					/* errore... */
					if ( rc)
					{
						if (rc != 1)
						{
							sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
						}
						else
							rc = 0;
						break;
					}
					else
					{
						//salvo ciò ce ho letto in un rec di backup per eventuale ripristino
						record_OP_backup = record_gruppoOp;

						// aggiorno il gruppo
						memset(record_gruppoOp.gruppo_op, ' ', sizeof(record_gruppoOp.gruppo_op));
						memcpy(record_gruppoOp.gruppo_op, ac_GRP, strlen(ac_GRP));

						//aggiorno il record con i dati modificati
						rc = MBE_WRITEUPDATEX( handleOP, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc);
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handleOP);
							break;
						}

						// ********************* scrivo DB REMOTO ***********************
						rc = scrivi_Operatori_remoto(handleOP_rem, &record_gruppoOp, UPD );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleOP);
							log(LOG_DEBUG, "%s;%s; UpdOP-OPGRP %s", gUtente, gIP, ac_GRP);
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_OP_backup, (short) sizeof(t_ts_oper_record) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handleOP);
							}
							// setto rc a 1 per segnalare errore
							rc = 1;
						}
					}
				}//fine while
			}

		}

		if (rc == 0 && nFlag == 0)
		{
			// aggiorna rec *****
			rc = Aggiorna_Operatori_rec_Aster(handleOP, handleOP_rem);
			if (rc == 0)
				Display_File();
		}
		MBE_FILE_CLOSE_(handleOP);
		MBE_FILE_CLOSE_(handleOP_rem);
	}

}

//**************************************************************************************
//  Cerco nel DB soglie i record del gruppo (ac_Key) da cancellare
//  Tipo == 1 visualizza
//  Tipo == 2 cancella
//**************************************************************************************
short GrOP_InSoglie(char *ac_Key, short Tipo)
{
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;
	char		sTmp[500];
	char		sTmp2[200];
	char		ac_Chiave[LEN_KEY_SOGLIE];
	char		newKey[LEN_KEY_SOGLIE];
	char		ac_GRP_OP[71];
	char		acGrpdecod[100];
	long		lRecord = 0;

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_appo;
	t_ts_soglie_record record_soglie_rem;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(newKey, ' ', sizeof(newKey));
	memset(ac_GRP_OP, 0, sizeof(ac_GRP_OP));
	memset(acGrpdecod, 0, sizeof(acGrpdecod));

	memcpy(ac_GRP_OP, ac_Key, strlen(ac_Key));

	// trasforma i caratteri speciali in formato html
	memcpy(acGrpdecod, ac_Key, strlen(ac_Key));
	CambiaCar(acGrpdecod);

    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileSoglie_Loc, &handle, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; EError in opening file %s (%d)", gUtente, gIP, acFileSoglie_Loc, rc);
		return(1);
	}
	rc = Apri_File(acFileSoglie_Rem, &handle_rem, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileSoglie_Rem, rc);
		return(1);
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
			sprintf(sTmp, "File_setkey: error %s (%d)", acFileSoglie_Loc, rc);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
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
				rc = MBE_READX( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileSoglie_Loc);
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if(!memcmp(ac_GRP_OP, record_soglie.gr_op, sizeof(record_soglie.gr_op)) )
					{
						// visualizzo i record dele soglie che verranno cancellati
						if(Tipo == 1)
						{
							if(lRecord == 0)
							{
								sprintf(sTmp, "OPERATOR GROUPS: %s", ac_Key);
								Display_TOP(sTmp);
								printf("<CENTER><BR><B><font size=5 color=#CC0033>\n\
									Removing this Group the following threshold will be DELETED!</B></font>");
								printf("<BR><BR><BR><TABLE BORDER=1 width=100%%>\n");
								printf("<TR BGCOLOR= #dcdcdc>\n");
								printf("  <TD><strong>&nbsp;Country / Country Group</strong></TD>\n");
								printf("  <TD><strong>&nbsp;Operator / Operator Group</strong></TD>\n");
								printf("  <TD><strong>&nbsp;Time from</strong></TD>\n");
								printf("  <TD><strong>&nbsp;Time to</strong></TD>\n");
								printf("  <TD><strong>&nbsp;Days</strong></TD>\n");
								printf("  <TD><strong>&nbsp;State</strong></TD>\n");
								printf("  <TD><strong>&nbsp;Threshold (%%)</strong></TD>\n");
								printf("  <TD>&nbsp;</TD>\n");
								printf("</TR>\n");
								fflush(stdout);
							}

							/***************************
							* Scrive il record a video
							****************************/
							printf("<TR>\n");
							printf("<TD>&nbsp;%.64s</TD>\n",record_soglie.gr_pa);
							printf("<TD>&nbsp;%.64s</TD>\n", record_soglie.gr_op);
							printf("<TD>&nbsp;%.5s</TD>\n", record_soglie.fascia_da);
							printf("<TD>&nbsp;%.5s</TD>\n", record_soglie.fascia_a);
							
							// gg settimana in Rosso è il gg inserito (peer cui il profilo è valido)
							printf("<TD>&nbsp;");
							if( record_soglie.gg_settimana[0] == 'X' )
								printf("<font color=red >M </font>");
							else
								printf("M ");
							if( record_soglie.gg_settimana[1] == 'X' )
								printf("<font color=red >T </font>");
							else
								printf("T ");
							if( record_soglie.gg_settimana[2] == 'X' )
								printf("<font color=red >W </font>");
							else
								printf("W");
							if( record_soglie.gg_settimana[3] == 'X' )
								printf("<font color=red >T </font>");
							else
								printf("T");
							if( record_soglie.gg_settimana[4] == 'X' )
								printf("<font color=red >F </font>");
							else
								printf("F ");
							if( record_soglie.gg_settimana[5] == 'X' )
								printf("<font color=red >S </font>");
							else
								printf("S ");
							if( record_soglie.gg_settimana[6] == 'X' )
								printf("<font color=red >S </font>");
							else
								printf("S ");
							printf("</TD>\n");

							printf("<TD>&nbsp;%s</TD>\n"  , (record_soglie.stato == '1' ? "On" : "Off") );
							printf("<TD>&nbsp;%d</TD>\n"  , record_soglie.soglia);

							lRecord ++;
						}
						else  //  CANCELLO
						{
							//mi salvo il record da cancellare
							record_appo = record_soglie;

							memcpy(newKey, record_soglie.gr_pa, LEN_KEY_SOGLIE);

							rc = MBE_WRITEUPDATEX( handle, (char *) &record_soglie, 0 );
							if ( rc)
							{
								sprintf(sTmp, "Error (%d) in deleting Threshold [%s]", rc, acFileSoglie_Loc);
								log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);

								break;
							}
			
							/***************************
							* Leggo il record db remoto
							****************************/
							rc = MBE_FILE_SETKEY_( handle_rem, newKey, sizeof(newKey), 0, EXACT);

							rc = MBE_READX( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
							if (rc != 0)/* errore... */
							{
								sprintf(sTmp, "Error (%d) in reading remote file [%s]", rc, acFileSoglie_Rem);
								log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);

								Display_Message(1, "", sTmp);
							}
							/* record TROVATO */
							else  /* readx ok */
							{
								// Cancello il record
								rc = MBE_WRITEUPDATEX( handle_rem, (char *) &record_soglie_rem, 0 );
								if ( rc)
								{
									sprintf(sTmp, "Error (%d) in deleting remote file [%s]", rc, acFileSoglie_Rem);
									log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP,  sTmp);
									Display_Message(1, "", sTmp);
								}
							}
							if(rc == 0) 
							{
								//Cancellata soglia scrivo Log
								memcpy(sTmp, record_soglie.gr_pa, sizeof(record_soglie.gr_pa));
								memcpy(sTmp2, record_soglie.gr_op, sizeof(record_soglie.gr_op));
								AlltrimString(sTmp);
								AlltrimString(sTmp2);
							}
							else
							{
								//la cancellazione dal db remoto è fallita
								//inserisco nel db locale il record cancellato 
								MBE_WRITEX( handle, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
								break;
								// non visualizzo eventuali errori in quanto è già stata
								//segnalata anomalia writeupdatex del db remoto.......
							}
							
							log(LOG_INFO, "%s;%s; Del threshold: %.64s",gUtente, gIP, record_soglie.gr_op);
						}
					}
				}
			}//fine while(1)

			if (Tipo == 1 )
			{
				if ( lRecord > 0 )
				{
					printf("</tr><tr>\n");
					printf("</TABLE><br>\n" );
					fflush(stdout);

					printf("<BR>");
					printf("<BR><p>\n");
					printf("<INPUT TYPE='button' icon='ui-icon-home' VALUE='Return' onclick='javascript:history.go(-1); return false;'>");
					printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n\
							<input type='button'  icon='ui-icon-check' value='Confirm' \n\
							onclick=\"javascript:location='%s?OPERATION=DELALL&GRUPPO=%s'\"	>",
							gName_cgi, acGrpdecod);

					printf("</p></CENTER>\n\
							</form>\n" );
					Display_BOTTOM();

					// TERMINO  IL PROGRAMMA
					exit(0);
				}
				else
					rc = 99;
			}
		}
	}//if (rc == 0)

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);
	return(rc);
}
//**************************************************************************
// conto quanti record appartengono ad un gruppo
//**************************************************************************
long ContaRecord(char *ac_Key, short handle)
{
	short	rc = 0;
	short	is_AltKey;
	long	nRec = 0;
	char	ac_Chiave[LEN_GRP];
	char	sTmp[500];

	t_ts_oper_record record_appo;

	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, ac_Key, strlen(ac_Key));

	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Erro (%d) File_setkey Local file [%s]", rc, acFileOperatori_Loc);
		log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
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
			rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_oper_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error  (%d) in reading Local file [%s]", rc, acFileOperatori_Loc);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				break;
			}
			/* record TROVATO */
			else  
				nRec++;		
		}//fine while(1)
	}
	return(nRec);
}

//********************************************************************************************************
short Carico_OP_Gruppo(char *acGruppo)
{
	short		handle = -1;
	short		rc = 0;
	char		sTmp[500];
	char		sKey[LEN_GRP];
	short		nConta= 0;
	short		is_AltKey;
	char		acPA[20];
	char		*ptrPaese;

	t_ts_oper_record record_gruppoOp;
	
	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));
	memset(sKey, ' ', sizeof(sKey));

	if (strlen(acGruppo) < sizeof(sKey))
		memcpy(sKey, acGruppo, strlen(acGruppo));
	else
		memcpy(sKey, acGruppo, sizeof(sKey));


	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handle, 1, 1);
	if (rc == 0 )
	{
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handle, sKey, (short) sizeof(sKey) , is_AltKey, GENERIC);
		/* errore */
		if (rc != 0)
		{
			printf( ");\n</script>\n" );

			sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
			/* tutto ok */
		if(rc == 0);
		{
			/************************************************
			* Creo l'array con i dati già inseriti nel DB
			*************************************************/
			while ( 1 )
			{
				rc = MBE_READX( handle, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if ( rc)
				{
					if(rc != 1)
					{
						printf( ");\n</script>\n" );

						sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else 
						rc = 0;
					break;
				}
				else
				{
					// devo cercare il Paese e la denominazione operatore in lista creata apposta x questa ricerca 
					memset(acPA, 0, sizeof(acPA));
					memset(sTmp, 0, sizeof(sTmp));
					sprintf(acPA, "%.8s%.10s", record_gruppoOp.paese, record_gruppoOp.cod_op);
					AlltrimString(acPA);

					ptrPaese= avlFind(lista_Appo, acPA);
					if (ptrPaese != NULL)
					{
						memcpy(sTmp, ptrPaese, 64);
						AlltrimString(sTmp);
						// ptrPaese = denPA(64)codop(10);denOP(64);paese(8)
						//parte chi viene visualizzata([paese] den OP - cod OP, valore da passare Cod op)
						if(nConta == 0)
							printf( "   new Option(\"[%s] %.64s - %.10s - %.8s\",\"%.10s;%.8s\")\n",	sTmp,	//den paese
																					ptrPaese+75,		// den operatore
																					ptrPaese+64,		//Cod Operatore
																					ptrPaese+140,		//paese
																					ptrPaese+64,		//Cod Operatore serve x il value
																					ptrPaese+140 );		//paese server x il value
						else
							printf( "\n,  new Option(\"[%s] %.64s - %.10s - %.8s\",\"%.10s;%.8s\")\n",	sTmp,
																					ptrPaese+75,
																					ptrPaese+64,
																					ptrPaese+140,
																					ptrPaese+64,
																					ptrPaese+140 );
						fflush(stdout);
					}
					nConta++;

				}
			}
		}//while
		MBE_FILE_CLOSE_(handle);
	}	
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
		
	return(rc);
}
//********************************************************************************************************
// vengono caricati solo gli operatori che non appartengono ad un gruppo e quelli il cui paese non
// appartiene ad un gruppo paesi.
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
	char		acDati[200];
	char		key_PA[100];
	char		Old_Pa[100];
	char		acPaese[10];
	short		is_func[25];
	short		nConta = 0;
	char		*ptr_OP;
	char		*ptr_PA;
	char		*ptr_Dati;
	char		*ptr_CC;
	char		acCodPA[15];
	char		acCaricato[10];

	AVLTREE		lista_Dati;
	AVLTREE		lista_PAeDati;
	t_ts_oper_record record_operatori;

	//Creare la lista:
	lista_OP		= avlMake();
	lista_PAeDati	= avlMake();
	lista_Appo		= avlMake();

	Paesi_daNon_Caricare();

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
			log(LOG_ERROR, "%s;%s; Error File_setkey file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
			sprintf(sTmp, "File_setkey: error %d", rc);
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
						log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
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
						sprintf(chiave, "%.64s%.10s;%.64s;%.8s",	record_operatori.den_paese,
																	record_operatori.cod_op,
																	record_operatori.den_op,
																	record_operatori.paese);
						AlltrimString(chiave);
						ptr_OP = malloc((strlen(chiave)+1)*sizeof(char));
						strcpy(ptr_OP, chiave);

						// creo la lista con i record che:
						// hanno a space il campo gruppo_op
						if (!memcmp(record_operatori.gruppo_op, "                              ", 30))
						{
							memset(acPaese, 0, sizeof(acPaese));
							memcpy(acPaese, record_operatori.paese, 8);
							// paese non presente nella lista lista_PAnoCaricare
							//if(avlFind(lista_PAnoCaricare, acPaese) == NULL)
								avlAdd(lista_OP, ptr_OP, ptr_OP);
						}
						//utilizzo un altra lista con solo paese (primi 8 di mgt) come key
						// mi serve in modifica quando leggo gli operatori presenti in un gruppo
						// quando preparo l'array "listaDB" mi sevono i dati denPaese 
						memset(acCodPA, 0, sizeof(acCodPA));
						sprintf(acCodPA, "%.8s%.10s", record_operatori.paese, record_operatori.cod_op);
						AlltrimString(acCodPA);
						ptr_CC = malloc((strlen(acCodPA)+1)*sizeof(char));
						strcpy(ptr_CC, acCodPA);
						avlAdd(lista_Appo, ptr_CC, ptr_OP);
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
				memset(stringa, 0, sizeof(stringa));
				memset(acDati, 0, sizeof(acDati));
				memset(key_PA, 0, sizeof(key_PA));
				memcpy(stringa, ptrChiave, strlen(ptrChiave));
				//la chiave deve contenere anche il cod op in modo da tenere l'ordinamento esatto
				memcpy(key_PA,  stringa, 64);
				AlltrimString(key_PA);
				strcpy(acDati,  stringa+64);

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
					
					// Se il paese è presente nella lista lista_PAnoCaricare
					// scrivo il carattere '*' che indica che quel paese fa già parte 
					// di un gruppo
					memset(acPaese, 0, sizeof(acPaese));
					memcpy(acPaese,  ptrChiave+106, 8);
					AlltrimString(acPaese);

					if(avlFind(lista_PAnoCaricare, acPaese) == NULL)	
						strcpy(acCaricato, "   ");
					else
						strcpy(acCaricato, "(*)");

					printf( ",   new Option(\"%s %s\")\n", stringa, acCaricato );
					fflush(stdout);
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
						// ptr_Dati = codOP(10);denOP(64);paese(8)
						//valori visualizzati =Den OP - Cod OP -CC; l'insieme dei 3 valori li rende univoci
						//Valori passati dalla select = Cod OP;CC
						memset(sTmp, 0, sizeof(sTmp));
						strncpy(sTmp, ptr_Dati+11, 64);
						AlltrimString(sTmp);
						printf("\"%s - %.10s - %.8s\",\"%.10s;%.8s\")", sTmp, ptr_Dati, ptr_Dati+76, ptr_Dati, ptr_Dati+76);
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
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);

	return(rc);	
}
//***************************************************************************************************
short Aggiorna_Paesi(char *Paese, char *Gruppo, short handle_Paese, short handlePA_rem )
{
	char		sTmp[500];
	char		acPaese[8];
	short		rc = 0;

	t_ts_paesi_record record_paesi;
	t_ts_paesi_record record_paesi_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(&record_paesi_backup, ' ', sizeof(t_ts_paesi_record));
	memset(sTmp,    0, sizeof(sTmp));
	memset(acPaese, ' ', sizeof(acPaese));

	memcpy(acPaese, Paese, strlen(Paese));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle_Paese, (char *) &acPaese, (short)sizeof(acPaese), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error File_setkey file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
		sprintf(sTmp, "File_setkey: error %d", rc);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handle_Paese, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
		/* errore... */
		if ( rc)
		{
			log(LOG_ERROR, "%s;%s; Error Readxlock file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
			sprintf(sTmp, "Readxlock file %s: error %d (%.8s)", acFilePaesi_Loc, rc, acPaese);
			Display_Message(1, "", sTmp);
		}
		else
		{
			// ****  faccio copia di BACKUP per eventuale ripristino ******
			record_paesi_backup = record_paesi;

			// aggiorno il gruppo
			memset(record_paesi.gr_pa, ' ' , sizeof(record_paesi.gr_pa));
			memcpy(record_paesi.gr_pa, Gruppo, strlen(Gruppo));

			//aggiorno il record con i dati modificati
			rc = MBE_WRITEUPDATEX( handle_Paese, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
			if(rc)
			{
				log(LOG_ERROR, "%s;%s; Error Update file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
				sprintf(sTmp, "writeupdatex: error %d", rc);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle_Paese);
			}
			else
			{
				// ********************* scrivo DB REMOTO ***********************
				rc= Aggiorno_Paesi_remoto(handlePA_rem, &record_paesi);
				if(rc == 0)
				{
					// tutto ok unlock locale
					MBE_UNLOCKREC(handle_Paese);
				}
				else
				{
					// ERRORE SCRITTURA REMOTO
					// aggiorno il record in Locale con i dati originali
					rc = MBE_WRITEUPDATEUNLOCKX( handle_Paese, (char *) &record_paesi_backup, (short) sizeof(struct _ts_paesi_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating  Local file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle_Paese);
					}
					// setto rc a 1 per segnalare errore
					rc = 1;
				}
			}
		}
	}
	return(rc);
}
//***************************************************************************************
//  il campo GRUPPO_PA dei paesi appartenenti al gruppo da cancellare viene messo a blank
//***************************************************************************************
short Cancella_Gruppo_Paesi(char *Gruppo, short handlePA, short handlePA_rem)
{
	char		sTmp[500];
	char		ac_Chiave[64];
	char		ac_GRPVuoto[65];
	short		rc = 0;
	short		is_AltKey;

	t_ts_paesi_record record_paesi;
	t_ts_paesi_record record_paesi_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(&record_paesi_backup, ' ', sizeof(t_ts_paesi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memset(ac_GRPVuoto, ' ', sizeof(ac_GRPVuoto));
	memset(sTmp,     0, sizeof(sTmp));

	memcpy(ac_Chiave, Gruppo, strlen(Gruppo));


	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handlePA, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);

	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFilePaesi_Loc);
		log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		is_AltKey = 1;
		rc = MBE_FILE_SETKEY_( handlePA_rem, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey Remote file [%s]", rc, acFilePaesi_Rem);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
	}

	if(rc == 0)
	{
		while ( 1 )
		{
			rc = MBE_READLOCKX( handlePA, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
			/* errore... */
			if ( rc)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFilePaesi_Loc);
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 0;
				break;
			}
			else
			{
				//salvo ciò ce ho letto in un rec di backup per eventuale ripristino
				record_paesi_backup = record_paesi;

				// aggiorno il gruppo
				memcpy(record_paesi.gr_pa, ac_GRPVuoto, sizeof(record_paesi.gr_pa));

				//aggiorno il record con i dati modificati
			//	rc = MBE_WRITEUPDATEUNLOCKX( handlePA, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				rc = MBE_WRITEUPDATEX( handlePA, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFilePaesi_Loc);
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handlePA);
					break;
				}

				// ********************* scrivo DB REMOTO ***********************
				rc= Aggiorno_Paesi_remoto(handlePA_rem, &record_paesi);
				if(rc == 0)
				{
					// tutto ok unlock locale
					MBE_UNLOCKREC(handlePA);
				}
				else
				{
					// ERRORE SCRITTURA REMOTO
					// aggiorno il record in Locale con i dati originali
					rc = MBE_WRITEUPDATEUNLOCKX( handlePA, (char *) &record_paesi_backup, (short) sizeof(struct _ts_paesi_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating  Local file [%s] - Country: [%.8s]", rc, acFilePaesi_Loc, record_paesi.paese);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handlePA);
					}
					// setto rc a 1 per segnalare errore
					rc = 1;
					break;
				}
			}
		}// fine while
	}
	return (rc);
}
//****************************************************
// lista dei Paesi che appartengono ad un gruppo
// quindi non sono da caricare
//****************************************************
void Paesi_daNon_Caricare(void)
{
	short		handlePaesi = -1;
	char		sTmp[500];
	char		ac_Chiave[64];
	char		KeyLista[200];
	char		*ptr_PA;
	short		rc = 0;
	short		is_AltKey;

	t_ts_paesi_record record_paesi;

	lista_PAnoCaricare	= avlMake();

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

   /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handlePaesi, 1, 1);
	if(rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
		return;
	}
	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handlePaesi, ac_Chiave, sizeof(ac_Chiave), is_AltKey, APPROXIMATE, 0);
	if (rc != 0)
	{	/* errore */
		log(LOG_ERROR, "%s;%s; Error File_setkey file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
		sprintf(sTmp, "File_setkey: error %d", rc);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		while ( rc == 0 )
		{
			rc = MBE_READX( handlePaesi, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFilePaesi_Loc);
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				// inserisco nella lista i record che hanno un gruppo diverso da blank
				if (memcmp(record_paesi.gr_pa, "                              ", 30))
				{
						memset(KeyLista, 0, sizeof(KeyLista));
						sprintf(KeyLista, "%.8s", record_paesi.paese);
						AlltrimString(KeyLista);
						ptr_PA = malloc((strlen(KeyLista)+1)*sizeof(char));
						strcpy(ptr_PA, KeyLista);

						avlAdd(lista_PAnoCaricare, ptr_PA, ptr_PA);
				}
			}
		}//fine while
	}
	MBE_FILE_CLOSE_(handlePaesi);

	return;
}
//********************************************************
short Cerca_Gruppo(short handleOP, char *ac_GRP)
{
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP];
	short		rc = 0;
	short		is_AltKey;

	t_ts_oper_record record_gruppoOp;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, ac_GRP, strlen(ac_GRP));

	/*******************
	* Cerco il record
	*******************/
	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handleOP, ac_Chiave, (short)sizeof(ac_Chiave), is_AltKey, GENERIC);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey (search grp) in Local file [%s] ", rc, acFileOperatori_Loc );
		log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	else
	{
		rc = MBE_READX( handleOP, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
		if (rc == 0)
		{
			sprintf(sTmp, "Group %.64s already exist", ac_Chiave);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			rc = 1;
		}
		else
		{
			if(rc != 1)
			{
				sprintf(sTmp, "Error (%d) in reading (search grp) Local file [%s] ", rc, acFileOperatori_Loc );
				log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
				rc = 0;
		}
	}
	/* tutto ok */
	return(rc);
}

//*************************************************************************
// aggiorno il campo gruppo OP e/o gruppo PA nel db operatori
//*************************************************************************
short Aggiorna_Operatori_Gr(char *ac_GRP, char *ac_CodOp, char *ac_CC, short handleOP, short handleOP_rem)
{
	char		sTmp[500];
	short		rc = 0;

	t_ts_oper_record record_gruppoOp;
	t_ts_oper_record record_OP_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_gruppoOp, ' ', sizeof(t_ts_oper_record));
	memset(&record_OP_backup, ' ', sizeof(t_ts_oper_record));

	memcpy(record_gruppoOp.paese, ac_CC, strlen(ac_CC));
	memcpy(record_gruppoOp.cod_op, ac_CodOp, strlen(ac_CodOp));

	/*********************
	* Cerco il record
	**********************/
	rc = MBE_FILE_SETKEY_( handleOP, record_gruppoOp.paese, (short) sizeof(record_gruppoOp.paese)+sizeof(record_gruppoOp.cod_op), 0, EXACT);
	if (rc != 0)		/* errore */
	{
		sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileOperatori_Loc);
		log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		/*******************
		* Leggo il record
		*******************/
		rc = MBE_READLOCKX( handleOP, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
		/* errore... */
		if (rc != 0)
		{
			sprintf(sTmp, "Error(%d) in reading Local file [%s] - key=%.18s", rc, acFileOperatori_Loc, record_gruppoOp.paese);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, rc, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* record TROVATO */
		else  /* readx ok */
		{
			//salvo ciò ce ho letto in un rec di backup per eventuale ripristino
			record_OP_backup = record_gruppoOp;

			// aggiorno il gruppo op
			memset(record_gruppoOp.gruppo_op, ' ', sizeof(record_gruppoOp.gruppo_op));
			memcpy(record_gruppoOp.gruppo_op, ac_GRP, strlen(ac_GRP));

		/*	if(nUpdGRPA == 1)
			{
				memset(record_gruppoOp.gruppo_pa, ' ', sizeof(record_gruppoOp.gruppo_pa));
				memcpy(record_gruppoOp.gruppo_pa, ac_GRP, strlen(ac_GRP));
			}
		 */
			//aggiorno il record con i dati modificati
			rc = MBE_WRITEUPDATEX( handleOP, (char *) &record_gruppoOp, (short) sizeof(t_ts_oper_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating Local file %s", rc, acFileOperatori_Loc);
				log(LOG_ERROR, "%s;%s;  %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleOP);
			}
		}
	}

	if(rc == 0)
	{
		// ********************* scrivo DB REMOTO ***********************
		rc = scrivi_Operatori_remoto(handleOP_rem, &record_gruppoOp, UPD );
		if(rc == 0)
		{
			// tutto ok unlock locale
			MBE_UNLOCKREC(handleOP);
			log(LOG_DEBUG, "%s;%s; UpdOP-OG %s:%s%s", gUtente, gIP, ac_GRP, ac_CodOp, ac_CC);
		}
		else
		{
			// ERRORE SCRITTURA REMOTO
			// aggiorno il record in Locale con i dati originali
			rc = MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_OP_backup, (short) sizeof(t_ts_oper_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleOP);
			}
			// setto rc a 1 per segnalare errore
			rc = 1;
		}
	}
	return(rc);
}

