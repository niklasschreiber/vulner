/*----------------------------------------------------------------------------
*   PROGETTO : Gruppo Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : groper.c
*   Ultima Modifica : 09/03/2016
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
void  Cancella_Gruppo(short Tipo, short disp);
short Aggiorna_Operatori_GR(char *ac_GRP, char *acPaese);
short GrPA_InSoglie(char *ac_Key, short Tipo);
long  ContaRecord(char *ac_Key, short handle);
short Carico_PA_delGruppo(char *acGruppo);
short Carico_Paesi();
short Scrivo_Grp(short handle, short handlePA_rem, char *acPaese, char *ac_GRP);
short Cerca_Gruppo(short handlePA);

extern short	Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern short 	Check_LenMsg( char  msg_txt[ITEM_SIZE], short nTipoMsg, int lenMsg, char *acNome );
extern short 	Aggiorno_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi );
extern short 	Aggiorna_PA_rec_Aster(short handle, short handlePA_rem);

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
	memset(acFilePaesi_Loc, 0x00, sizeof(acFilePaesi_Loc));
   /**************************************************************************
    ** Determinazione identificativo processo
    **************************************************************************/
	rc = get_process_name(ac_procname);
	if (rc != 0)
	{
		sprintf(sTmp,"Error get_process_name: %d", rc);
		Display_Message(1, "Operation result", sTmp);
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
	sprintf(log_spooler.NomeDB, "Countries group");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	/* tipo operazione */
	memset(sOperazione, 0x00, sizeof(sOperazione));

	strcpy(sOperazione, "DISPLAY");	//default
	if ( (wrk_str = cgi_param( "OPERATION" ) ) != NULL )
		strcpy(sOperazione, wrk_str);


	//-------------------------------------------------------------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		log(LOG_INFO, "%s;%s; Display Countries Group ",gUtente, gIP);
		Display_File();
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Window Modify ",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Window Insert ",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Update ",gUtente, gIP);
		Aggiorna_Dati(0);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Insert ",gUtente, gIP);
		Aggiorna_Dati(1);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Delete ",gUtente, gIP);
		Aggiorna_Dati(2);
	}
	else if (strcmp(sOperazione, "ConfDelGRP")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Delete GR ",gUtente, gIP);
		Cancella_Gruppo(1, 0);
	}
	else if (strcmp(sOperazione, "DELALL")== 0 )
	{
		log(LOG_INFO, "%s;%s; Countries Group - Delete GR ",gUtente, gIP);
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
	char		ac_Chiave[LEN_GRP+LEN_GRP];
	char		acGruppo[LEN_GRP+1];
	char		acDen_Paese[LEN_GRP+1];
	char		ac_Paese[10];
	char		stringa[200];
	char		cColore = 'b';
	char		acTRClass[20];
	char		acTDClass[20];
	char		acGrpdecod[100];
	short		rc = 0;
	short		is_AltKey;
	long		nCambio = 0;
	char		*wrk_str;

	t_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acGruppo,   'x', 5);

	memset(acDen_Paese, 0, sizeof(acDen_Paese));
	memset(ac_Paese, 0, sizeof(ac_Paese));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "All");
	strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle, 1, 0);
	if (rc == 0)
	{
		//*************************************** apertura html *******************************
		Display_TOP("");

		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;

		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, APPROXIMATE, 0);
		
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file[%s]", rc, acFilePaesi_Loc);
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			printf("<BR><CENTER>");
			printf( "<input type='button' icon='ui-icon-circle-plus' VALUE='New Group' onclick=\"javascript:location='%s?OPERATION=NEW'\"> \n", gName_cgi);

			printf("<BR><BR>\n\
				   <table cellpadding='0' cellspacing='0' border='0' class='display' id='nosort' >\n"); // non permette il sort

			printf("<thead>\n");

			printf("<TR>\n");
			printf("  <TH ><strong>&nbsp;Group</strong></TH>\n");
			printf("  <TH width='5%%'>&nbsp;</TH>\n");
			printf("  <TH ><strong>&nbsp;Country</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Cod Country</strong></TH>\n");
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
				rc = MBE_READX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file[%s]", rc, acFilePaesi_Loc);
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
						LOGResult = SLOG_ERROR;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					// visualizzo i record che hanno un gruppo diverso da blank
					if (memcmp(record_paesi.gr_pa, "                              ", 30) &&
						memcmp(record_paesi.paese, "********", 8))
					{
						/***************************
						* Scrive il record a video
						****************************/
						nCambio = 0;
						strcpy(acTDClass, "groupGhost");
						// se sono diversi scrivo il gruppo
						if(memcmp(acGruppo, record_paesi.gr_pa, sizeof(record_paesi.gr_pa)) )
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
						memcpy(acGrpdecod, record_paesi.gr_pa, LEN_GRP);
						CambiaCar(acGrpdecod);

						printf("<TR class='%s' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&GRUPPO=%s'\">\n", acTRClass, gName_cgi, acGrpdecod);
						printf("  <TD class='%s' onclick='link = true'>&nbsp;%.*s</TD>\n", acTDClass, LEN_GRP, record_paesi.gr_pa);
						fflush(stdout);
						memset(sTmp, 0, sizeof(sTmp));
						strncpy(sTmp, record_paesi.gr_pa, LEN_GRP);
						AlltrimString(sTmp);

						if (nCambio)
						{
							printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=ConfDelGRP&GRUPPO=%s', 'Group: [%s]');\">",
									gName_cgi, acGrpdecod, sTmp);
							printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");
							fflush(stdout);
						}
						else
						{
							printf("  <TD>&nbsp;</TD>");
						}
							
						printf("  <TD onclick='link = true'>&nbsp;%.*s</TD>\n", LEN_GRP, record_paesi.den_paese);
						printf("  <TD onclick='link = true'>&nbsp;%.8s</TD>\n",  record_paesi.paese);
						memset(sTmp, 0, sizeof(sTmp));
						memset(stringa, 0, sizeof(stringa));
						memcpy(sTmp, record_paesi.den_paese, sizeof(record_paesi.den_paese));
						SistemaApice(stringa, sTmp);

						printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&PAESE=%.8s&GRUPPO=%s', 'Country: [%s][%s] from Group[%s]');\">",
								gName_cgi,  record_paesi.paese, acGrpdecod,
								GetStringNT(record_paesi.paese, 8), stringa, GetStringNT(record_paesi.gr_pa, 64));
						printf("<div class='del_icon'></div></TD>\n");

						printf("</TR>\n");
						fflush(stdout);

						// salvo il gruppo
						memcpy(acGruppo, record_paesi.gr_pa, sizeof(record_paesi.gr_pa));
					}
				}
			}/* while (1) */
			
			printf("</tbody>");
			printf("</TABLE>\n");
			printf("<BR>\n");

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New Group' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n", gName_cgi);
			printf("</CENTER>\n");

			// inserimento delle finestre di dialogo
			printf("<script>\n");
			printf("    insert_Confirm_Delete();\n");
			printf("</script>\n");

			fflush(stdout);
			Display_BOTTOM();
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s", gUtente, gIP, acFilePaesi_Loc);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);
    
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


	/* inizializza la struttura tutta a blank */
	memset(ac_Gruppo,     0, sizeof(ac_Gruppo));

	memset(sTmp, 0, sizeof(sTmp));
	
	if (tipo == 0)
	{
		if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcpy(ac_Gruppo, wrk_str);

		sprintf(sTmp, "Add Countries to Group: %s", ac_Gruppo);
		strcpy(sTipo, "Update");

		log(LOG_INFO, "%s;%s; ViewCG:%s",gUtente, gIP, ac_Gruppo);
	}
	else
	{
		sprintf(sTmp, "Create a New Group");
		strcpy(sTipo, "Insert");
	}
	//*************************************** apertura html *******************************
	Display_TOP("");

	rc = Carico_Paesi();
	if(rc == 0 )
	{
		/************************************************
		* Creo l'array con i dati già inseriti nel DB
		*************************************************/
		printf("	<!-- caricamento array Paesi-->");
		printf("<script language='JavaScript'>\n");
		
		printf(	"var listaDB = new Array(\n");
		fflush(stdout);

		if (tipo == 0)//modifica
			rc= Carico_PA_delGruppo(ac_Gruppo);

		printf( ");\n</script>\n" );
	}
	if(rc == 0 )
	{
		/*---------------------------------------*/
		/* VISUALIZZO PAGINA HTML                */
		/*---------------------------------------*/
		printf("<form method='POST' action='%s' name='inputform' onsubmit='javascript:prepara_valori();return CheckGroupName(%d)'>\n", gName_cgi, tipo);

		printf("<br><br>\n");
		printf("<fieldset><legend> %s &nbsp;</legend>\n", sTmp);
		//printf("<CENTER>\n");
		printf("<TABLE width = 100%% cellspacing=8 border=0>\n\
				<TR>\n");
		fflush(stdout);
		//mi serve x non modificare delle funzioni javascript utilizzate da PPLMN.cgi 
		// dove settano id_tot
		printf("<font id=id_tot style='visibility:hidden'></font>");
		printf("<TD align='right'><B>Group name:&nbsp;</B></td>\n");
		printf("<TD colspan='2' align='left'>\n");
		if(tipo == 1)
		{
			printf("<INPUT TYPE='text' SIZE='65' id='checkChr' MAXLENGTH=64 NAME='GRUPPO'></TD>\n");
		}
		else
		{
			printf("%s</TD>\n", ac_Gruppo);
		}
		printf("</TR>\n");

		printf("<tr height='45'>\n");
		printf("<td rowspan='4'></td>\n"); //colonna a sinistra vuota
		printf("<td colspan='3' align='left' valign='bottom' id='fontblue'><B>Country list </B></td>\n\
				<td colspan='1' align='left' valign='bottom' id='fontblue'><B>Country in the group </B></td>\n");
		printf("</tr>\n");
		printf("<tr>\n");
		printf("<td colspan='1' rowspan='2' align='left'>\n\
				<select name='operatorSelect' id='selectList' multiple size=15></select>\n\
				</td>\n");
        printf("<td width='80' height='40' align='right' valign='bottom' rowspan='1' ><nobr>\n\
					<img src='images/right24.png' border=0 title='Add selected countries' style='cursor:hand' onClick=\"javascript:addPaesi_inGRP('false');\" onMouseOver=\"javascript:this.src='images/right32.png';\"  onMouseOut=\"javascript:this.src='images/right24.png';\"></nobr>\n\
				</td>\n\
				<td width='80' height='40' align='left' valign='bottom' rowspan='1' ><nobr>\n\
					<img src='images/left24.png' border=0 title='Remove selected countries' style='cursor:hand' onClick=\"javascript:delOperators();\" onMouseOver=\"javascript:this.src='images/left32.png';\"  onMouseOut=\"javascript:this.src='images/left24.png';\">\n\
				</td>\n");

        printf("<td colspan='1' rowspan='2' align='left'>\n\
				<select name='operatorSelected' id='selectList' multiple size=15></select>\n\
				</td>\n\
				</tr>\n\
				<tr>\n\
				<td width='80' height='40' align='right' valign='top' style='padding-top: 10px' rowspan='1' ><nobr>\n\
					<img src='images/rightall24.png' border=0 title='Add all countries' onClick=\"javascript:addPaesi_inGRP('true');\" onMouseOver=\"javascript:this.src='images/rightall32.png';\"  onMouseOut=\"javascript:this.src='images/rightall24.png';\" ></nobr>\n\
				</td>\n\
				<td width='80' height='40' align='left' valign='top' style='padding-top: 10px' rowspan='1' ><nobr>\n\
					<img src='images/leftall24.png' border=0 title='Remove all countries' style='cursor:hand' onClick=\"javascript:delAllOperators();\" onMouseOver=\"javascript:this.src='images/leftall32.png';\"  onMouseOut=\"javascript:this.src='images/leftall24.png';\">\n\
				</td>\n\
				</tr>\n");

		printf("<tr><td align='left'>Country filter &nbsp;&nbsp;\n\
				<input name='fPaesi' type='text' value='' size=10 class='testo' maxlength=64  onKeyUp=\"javascript: setFiltroPA(document.inputform.operatorSelect.selectedIndex);\" onFocus='this.select();'>\n\
				</td></tr>\n");

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
				</form>\n" );

		printf("<script language='JavaScript'>\n\
				setBackgroundColor();setListaDB();setListaPaesi();\n\
				</script>\n");
	}
	Display_BOTTOM();
}


//************************************************************************
// tipo == 0  modifica
// tipo == 1 inserimento
// tipo == 2 cancellazione

// Controlla se ci sono record nel DB soglie con  Grp Paesi uguale a quello aggiornato
// se ci sono aggiorno record '*****' del DB soglie
// Il record '*****' del DB soglie viene aggiornato un unica volta
//************************************************************************
void Aggiorna_Dati(short tipo)
{
	char		*wrk_str;
	char		sTmp[500];
	char		sTmp2[200];
	char		ac_GRP[LEN_GRP+1];
	char		ac_Key[LEN_GRP+1];
	char		acPaese[10];
	char		*pTmp;
	char		ac_grxlen[200];
	short		handlePA = -1;
	short		handlePA_rem = -1;
	short		handleSoglie_loc = -1;
	short		handleSoglie_rem = -1;
	short 		handleOP = -1;
	short 		handleOP_rem = -1;
	short		rc = 0;
	short		lentocopy = 0;
	long		nRec = 0;

	t_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));

	memset(ac_GRP, ' ', sizeof(ac_GRP));
	ac_GRP[LEN_GRP] = '\0';
	memset(acPaese, ' ', sizeof(acPaese));
	memset(ac_Key,  0, sizeof(ac_Key));
	memset(sTmp,    0, sizeof(sTmp));
	memset(sTmp2,   0, sizeof(sTmp2));
	memset(ac_grxlen,   0, sizeof(ac_grxlen));

	// paese mi serve nella cancellazione
	if (( (wrk_str = cgi_param( "PAESE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_Key, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(ac_grxlen, wrk_str, strlen(wrk_str));

		if(tipo != DEL)
			memcpy(ac_GRP, wrk_str, strlen(wrk_str));

		// in inserimento controllo lunghezza nome gruppo
		if( tipo == INS)
			rc = Check_LenMsg(ac_grxlen, 1, LEN_GRP, "Country Group");
	}


	if(rc == 0)
	{
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileSoglie_Loc, &handleSoglie_loc, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileSoglie_Loc, rc);
			return;
		}
		rc = Apri_File(acFileSoglie_Rem, &handleSoglie_rem, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileSoglie_Rem, rc);
			return;
		}
		rc = Apri_File(acFilePaesi_Loc, &handlePA, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening Local file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
			return;
		}
		rc = Apri_File(acFilePaesi_Rem, &handlePA_rem, 1, 1);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error in opening Remote file %s (%d)", gUtente, gIP, acFilePaesi_Rem, rc);
			return;
		}
		rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 1);
		if (rc != 0 )
		{
			log(LOG_ERROR, "%s;%s; Error in opening Locale file %s (%d)", gUtente, gIP, acFileOperatori_Rem, rc);
			return;
		}
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
		if (rc != 0 )
		{
			log(LOG_ERROR, "%s;%s; Error in opening Remote file %s (%d)", gUtente, gIP, acFileOperatori_Rem, rc);
			return;
		}
	}

	if (rc == 0 )
	{
		if(tipo == DEL)  //CANCELLAZIONE
		{
			// inserisco qui perchè UPD richiama funz cancella_gruppo che ha suo log
			/*------------------------------*/
			/* LOG SICUREZZA				*/
			/*------------------------------*/
			strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
			sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s;Paese=%s", AlltrimString(ac_grxlen), ac_Key);
			LOGResult = SLOG_OK;

			// conto quanti record ci sono di quel gruppo
			nRec = ContaRecord(ac_Key, handlePA);
			// se c'è un solo record significa che viene eliminato il gruppo e quindi
			// devo eliminare anche i record nel db soglie 
			// richiamo la GrPA_InSoglie() 
			if (nRec == 1)
			{
				//MBE_FILE_CLOSE_(handle);
				rc = GrPA_InSoglie(ac_Key, 1);
				if (rc == 99)// non ci sono soglie aggiorno db
					nRec = 2;
			}
			if (nRec != 1)
			{
				//ac_GRP è vuoto
				rc = Scrivo_Grp(handlePA, handlePA_rem, ac_Key,  ac_GRP);
			}
		}
		else
		{
			if(tipo == UPD) //  se in modifica cancello la lista e poi riscrivo tutto
			{
				Cancella_Gruppo(2, 1);

				// inserisco qui perchè UPD richiama funz cancella_gruppo che ha suo log
				/*------------------------------*/
				/* LOG SICUREZZA				*/
				/*------------------------------*/
				sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s", AlltrimString(ac_grxlen));
				LOGResult = SLOG_OK;
				strcpy(log_spooler.TipoRichiesta, "UPD");
			}
			else
			{
				strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL
				sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s", AlltrimString(ac_grxlen));
				LOGResult = SLOG_OK;

				//in inserimento se il gruppo c'è esco
				rc = (short) Cerca_Gruppo(handlePA);
			}
			if (rc == 0)
			{
				if ( tipo == UPD || tipo == INS)
				{
					// in VALORI ci sono i seguenti dati:
					// paese:paese:........
					if (( (wrk_str = cgi_param( "VALORI" ) ) != NULL ) && (strlen(wrk_str) > 0))
					{

						pTmp= GetToken(wrk_str, ":");
						{
							if(pTmp)
							{
								strcpy(acPaese, pTmp);
							}

							while(pTmp != NULL)
							{
								rc = Scrivo_Grp(handlePA, handlePA_rem, acPaese,  ac_GRP);
								//Continuo a leggere i Dati
								pTmp= GetToken(NULL, ":");
								if(pTmp)
								{
									strcpy(acPaese, pTmp);
								}
							}//FINE WHILE
						}
					}// fine cgi_param VALORI
				}
			}
		}

		if(rc != 0)
			LOGResult = SLOG_ERROR;

		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);


		if (rc == 0)
		{
			//aggiorna rec '*' paesi e operatori
			Aggiorna_PA_rec_Aster(handlePA, handlePA_rem);
			Aggiorna_Operatori_rec_Aster(handleOP, handleOP_rem);

			Display_File();
		}

		MBE_FILE_CLOSE_(handlePA);
		MBE_FILE_CLOSE_(handlePA_rem);

	}
}
//-------------------------------------------------------------------------------

//***************************************************************************************
//  il campo GRUPPO_PA dei paesi appartenenti al gruppo da cancellare viene messo a blank
// Tipo == 1 mostro l'elenco dei record da cancellare
// Tipo == 2 cancello i record
//***************************************************************************************
void Cancella_Gruppo(short Tipo, short disp)
{
	char		*wrk_str;
	char		sTmp[500];
	char		sTmp2[200];
	char		ac_GRP[LEN_GRP+1];
	char		ac_Chiave[LEN_GRP];
	short		handlePA = -1;
	short		handlePA_rem = -1;
	short 		handleOP = -1;
	short 		handleOP_rem = -1;
	short		rc = 0;
	short		is_AltKey;

	t_ts_paesi_record record_paesi;
	t_ts_paesi_record record_paesi_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(&record_paesi_backup, ' ', sizeof(t_ts_paesi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memset(ac_GRP, ' ', sizeof(ac_GRP));
	ac_GRP[LEN_GRP] = '\0';

	memset(sTmp,     0, sizeof(sTmp));
	memset(sTmp2,     0, sizeof(sTmp2));

	if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_Chiave, wrk_str, strlen(wrk_str));


	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Gruppo=%s", GetStringNT(ac_Chiave, sizeof(ac_Chiave)) );
	strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	if(disp == 0)
		rc = GrPA_InSoglie(ac_Chiave, Tipo);
	if (rc == 99)
	{
		Tipo = 2;
		rc = 0;
		log(LOG_INFO, "%s;%s; DEL GRPA: %.*s",gUtente, gIP, LEN_GRP, ac_Chiave);
	}
	if (rc == 0 && Tipo == 2)
	{
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFilePaesi_Loc, &handlePA, 1, 1);
		if (rc != 0 )
			log(LOG_ERROR, "%s;%s; Error in opening Local file %s (%d)", gUtente, gIP, acFilePaesi_Loc, rc);
		else
		{
			rc = Apri_File(acFilePaesi_Rem, &handlePA_rem, 1, 1);
			if (rc != 0 )
				log(LOG_ERROR, "%s;%s; Error in opening Remote file %s (%d)", gUtente, gIP, acFilePaesi_Rem, rc);
		}

		if (rc == 0 )
		{
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
						memcpy(record_paesi.gr_pa, ac_GRP, sizeof(record_paesi.gr_pa));

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

							memset(sTmp2, 0, sizeof(sTmp2));
							memcpy(sTmp2,  record_paesi_backup.gr_pa, sizeof( record_paesi_backup.gr_pa));
							AlltrimString(sTmp2);
							log(LOG_DEBUG, "%s;%s; DEL GRPA: %s:%s",gUtente, gIP, sTmp2, sTmp);

							// aggiorno il db operatori
							memset(sTmp, 0, sizeof(sTmp));
							memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
							rc = Aggiorna_Operatori_GR(ac_GRP, sTmp);
							if (rc != 0)
								break;
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

			if (rc == 0 && disp == 0)
			{
				rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 1);
				if (rc != 0 )
					log(LOG_ERROR, "%s;%s; Error in opening Locale file %s (%d)", gUtente, gIP, acFileOperatori_Loc, rc);
				else
				{
					rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);
					if (rc != 0 )
						log(LOG_ERROR, "%s;%s; Error in opening Remote file %s (%d)", gUtente, gIP, acFileOperatori_Rem, rc);
				}

				if(rc == 0)
				{
					//aggiorna rec '*' operatori
					Aggiorna_Operatori_rec_Aster(handleOP, handleOP_rem);

					MBE_FILE_CLOSE_(handleOP);
					MBE_FILE_CLOSE_(handleOP_rem);
				}
			}
		}
		if (disp == 0)
		{
			MBE_FILE_CLOSE_(handlePA);
			MBE_FILE_CLOSE_(handlePA_rem);
		}

		if(rc != 0)
			LOGResult = SLOG_ERROR;

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);

		if (rc == 0 && disp == 0)
			Display_File( );
	}
}
//*************************************************************************
// aggiorno il campo gruppo nel db operatori
//*************************************************************************
short Aggiorna_Operatori_GR(char *ac_GRP, char *acPaese)
{
	short		handleOP = -1;
	short		handleOP_rem = -1;
	char		sTmp[2000];
	char		ac_Chiave[8];
	short		rc = 0;
	short		lenChiave;

	t_ts_oper_record record_operatori;
	t_ts_oper_record record_operatori_backup;
	t_ts_oper_record record_operatori_tmp;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_backup, ' ', sizeof(t_ts_oper_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, acPaese, strlen(acPaese));
	lenChiave = LEN_CC;

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handleOP, 1, 1);
	if (rc == 0)
	rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 1);

	if (rc == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		rc = MBE_FILE_SETKEY_( handleOP, ac_Chiave, lenChiave, 0, GENERIC);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileOperatori_Loc );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file (%d)", gUtente, gIP,  rc);

	if (rc == 0)
	{
		while ( 1 )
		{
			/*******************
			* Leggo il record LOCALE
			*******************/
			rc = MBE_READLOCKX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading Local file [%s]", rc, acFileOperatori_Loc );
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 0;
				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				record_operatori_backup = record_operatori;

				// aggiorno il gruppo
				memset(record_operatori.gruppo_pa, ' ',sizeof(record_operatori.gruppo_pa));
				memcpy(record_operatori.gruppo_pa, ac_GRP, sizeof(record_operatori.gruppo_pa));

				//aggiorno il record con i dati modificati
			//	rc = MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				rc = MBE_WRITEUPDATEX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc );
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handleOP);
					break;
				}
			}
			if (rc == 0)
			{
				/*******************
				* Aggiorno DB REMOTO
				*******************/
				rc = MBE_FILE_SETKEY_( handleOP_rem, record_operatori.paese,
						sizeof(record_operatori.paese)+sizeof(record_operatori.cod_op), 0, EXACT);
				rc = MBE_READLOCKX( handleOP_rem, (char *) &record_operatori_tmp, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading Rempte file [%s]", rc, acFileOperatori_Rem );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					//aggiorno il record
					rc = MBE_WRITEUPDATEUNLOCKX( handleOP_rem, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
					if(rc == 0)
					{
						// tutto ok unlock locale
						MBE_UNLOCKREC(handleOP);
						log(LOG_DEBUG, "%s;%s; UpdOP-CG %s:%s", gUtente, gIP, ac_GRP, acPaese);
					}
					else
					{
						sprintf(sTmp, "Error (%d) in updating Remote file [%s]", rc, acFileOperatori_Rem );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						strcat(sTmp,"\n ATTENTION the group of some operators may have been changed ");
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handleOP_rem);

						// ERRORE SCRITTURA REMOTO
						// aggiorno il record in Locale con i dati originali
						rc = MBE_WRITEUPDATEUNLOCKX( handleOP, (char *) &record_operatori_backup, (short) sizeof(t_ts_oper_record) );
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileOperatori_Loc );
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							MBE_UNLOCKREC(handleOP);
						}
						// setto rc a 1 per segnalare errore
						rc = 1;
						break;
					}

				}
			}
		}/* while (1) */
	}

	MBE_FILE_CLOSE_(handleOP);
	MBE_FILE_CLOSE_(handleOP_rem);
	
	return(rc);
}
//**************************************************************************************
//  Cerco nel DB soglie i record del gruppo Paesi (ac_Key) da cancellare
//  Tipo == 1 visualizza
//  Tipo == 2 cancella
//**************************************************************************************
short GrPA_InSoglie(char *ac_Key, short Tipo)
{
	short		handle = -1;
	short		handle_rem = -1;
	short		rc = 0;
	char		sTmp[500];
	char		sTmp2[100];
	char		ac_Chiave[LEN_GRP];
	long		lRecord = 0;

	t_ts_soglie_record  record_soglie;
	t_ts_soglie_record  record_appo;
	t_ts_soglie_record  record_soglie_rem;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memcpy(ac_Chiave, ac_Key, strlen(ac_Key));
    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileSoglie_Loc, &handle, 1, 1);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s (%d)", gUtente, gIP, acFileSoglie_Loc, rc);
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
		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey local file [%s]", rc, acFileSoglie_Loc );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			rc = MBE_FILE_SETKEY_( handle_rem, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey remote file [%s]", rc, acFileSoglie_Rem );
				log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
	}
	/* tutto ok */
	if (rc == 0)
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
					sprintf(sTmp, "Error (%d) in reading local file [%s]", rc, acFileSoglie_Loc );
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 0;
				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				// visualizzo i record dele soglie che verranno cancellati
				if(Tipo == 1)
				{
					if(lRecord == 0)
					{
						sprintf(sTmp, "Country Group: %s", ac_Key);

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
					printf("<TD>&nbsp;%.*s</TD>\n", LEN_GRP, record_soglie.gr_pa);
					printf("<TD>&nbsp;%.*s</TD>\n", LEN_GRP, record_soglie.gr_op);
					printf("<TD>&nbsp;%.5s</TD>\n", record_soglie.fascia_da);
					printf("<TD>&nbsp;%.5s</TD>\n", record_soglie.fascia_a);

					// gg settimana in Rosso è il gg inserito (peer cui il profilo è valido)
					printf("<TD>&nbsp;");
					if( record_soglie.gg_settimana[0] == 'X' )
						printf("<font color=red >L </font>");
					else
						printf("L ");
					if( record_soglie.gg_settimana[1] == 'X' )
						printf("<font color=red >M </font>");
					else
						printf("M ");
					if( record_soglie.gg_settimana[2] == 'X' )
						printf("<font color=red >M </font>");
					else
						printf("M ");
					if( record_soglie.gg_settimana[3] == 'X' )
						printf("<font color=red >G </font>");
					else
						printf("G ");
					if( record_soglie.gg_settimana[4] == 'X' )
						printf("<font color=red >V </font>");
					else
						printf("V ");
					if( record_soglie.gg_settimana[5] == 'X' )
						printf("<font color=red >S </font>");
					else
						printf("S ");
					if( record_soglie.gg_settimana[6] == 'X' )
						printf("<font color=red >D </font>");
					else
						printf("D ");
					printf("</TD>\n");

					printf("<TD>&nbsp;%s</TD>\n"  , (record_soglie.stato == '1' ? "On" : "Off") );
					printf("<TD>&nbsp;%d</TD>\n"  , record_soglie.soglia);

					lRecord ++;
				}
				else  //  CANCELLO
				{
					//mi salvo il record da cancellare
					record_appo = record_soglie;

					rc = MBE_WRITEUPDATEX( handle, (char *) &record_soglie, 0 );
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in deleting local file [%s]", rc, acFileSoglie_Loc );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						break;
					}

					/***************************
					* Leggo il record db remoto
					****************************/
					rc = MBE_READX( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
					if (rc != 0)/* errore... */
					{
						sprintf(sTmp, "Error (%d) in reading remote file [%s]", rc, acFileSoglie_Rem );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else  /* readx ok */
					{
						// Cancello il record
						rc = MBE_WRITEUPDATEX( handle_rem, (char *) &record_soglie_rem, 0 );
						if ( rc)
						{
							sprintf(sTmp, "Error (%d) in deleting remote file [%s]", rc, acFileSoglie_Rem );
							log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
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

						log(LOG_INFO, "%s;%s; DelTR(DelCG):%s;%s;%.5s;%.5s;%.7s",
										gUtente, gIP, sTmp, sTmp2, record_soglie.fascia_da,
										record_soglie.fascia_a, record_soglie.gg_settimana );
					}
					else
					{
						//la cancellazione dal db remoto è fallita
						//inserisco nel db locale il record cancellato
						MBE_WRITEX( handle, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
						break;
						// non visualizzo eventuali errori in quanto è già stata
						//segnalata anomalia cancellazione db remoto.......
					}

					log(LOG_INFO, "%s;%s; DelTR-CG: %.*s",gUtente, gIP, LEN_GRP, record_soglie.gr_op);

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
				printf("<INPUT TYPE='button' icon='ui-icon-home' VALUE='Cancel'  onclick='javascript:history.go(-1); return false;'>");
				printf("<input type='button' icon='ui-icon-check'value='Confirm' \n\
						onclick=\"javascript:location='%s?OPERATION=DELALL&GRUPPO=%s'\"	>",
						gName_cgi, ac_Key);

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

	return(rc);
}
//**************************************************************************
// conto quanti record appartengono ad un gruppo
//**************************************************************************
long ContaRecord(char *ac_Key, short handle)
{
	short	rc = 0;
	long	nRec = 0;
	char	ac_Chiave[LEN_GRP];
	char	sTmp[500];
	short	is_AltKey;
	t_ts_paesi_record record_appo;

	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_paesi_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, ac_Key, strlen(ac_Key));

	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;

	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
	
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc );
		log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
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
			rc = MBE_READX( handle, (char *) &record_appo, (short) sizeof(t_ts_paesi_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc );
					log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
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
// carico i paesi senza gruppo
//********************************************************************************************************
short Carico_Paesi()
{
	short		handle = -1;
	short		rc = 0;
	short		nConta = 0;
	char		ac_Chiave[LEN_GRP];
	short		is_AltKey;
	char		sTmp[500];

	t_ts_paesi_record record_paesi;

	memset(&record_paesi,     ' ', sizeof(t_ts_paesi_record));
    /*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle, 1, 1);
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		// solo i record senza gruppo
		is_AltKey = 1;

		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		if(rc == 0);
		{
			/************************************************
			* Creo l'array con i dati già inseriti nel DB
			*************************************************/
			printf("	<!-- caricamento array Paesi-->");
			printf("<script language='JavaScript'>\n");
			
			printf(	"var listaPaesi = new Array(\n");
			fflush(stdout);

			while ( 1 )
			{
				rc = MBE_READX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				/* errore... */
				if ( rc)
				{
					if(rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else 
						rc = 0;
					break;
				}
				else
				{
					memset(sTmp, 0, sizeof(sTmp));
					memcpy(sTmp, record_paesi.den_paese, sizeof(record_paesi.den_paese));
					AlltrimString(sTmp);
					
					//parte chi viene visualizzata(paese )
					if(nConta == 0)
						printf( "   new Option(\"%s-%.8s\",\"%.8s\")\n",	sTmp, record_paesi.paese, record_paesi.paese);	//den paese, paese		
					else
						printf( "\n,  new Option(\"%s-%.8s\",\"%.8s\")\n",	sTmp, record_paesi.paese, record_paesi.paese);	//den paese, paese
					fflush(stdout);
					nConta++;
				}
			}
		}//while
		MBE_FILE_CLOSE_(handle);
		printf( ");\n</script>\n" );
	}	
	return(rc);
}
//********************************************************************************************************
short Carico_PA_delGruppo(char *acGruppo)
{
	short		handle = -1;
	short		rc = 0;
	short		nConta = 0;
	short		is_AltKey;
	char		ac_Chiave[8];
	char		sTmp[500];

	t_ts_paesi_record record_paesi;

	memset(&record_paesi,     ' ', sizeof(t_ts_paesi_record));
 	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
  
	memcpy(ac_Chiave, acGruppo, strlen(acGruppo));
	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFilePaesi_Loc, &handle, 1, 1);

	if (rc == 0)
	{
		/*  ricerca  per chiave alternata*/
		is_AltKey = 1;

		rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			printf( ");\n</script>\n" );
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		if(rc == 0);
		{

			while ( 1 )
			{
				rc = MBE_READX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
				/* errore... */
				if ( rc)
				{
					if(rc != 1)
					{
						sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc );
						log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
						printf( ");\n</script>\n" );
						Display_Message(1, "", sTmp);
					}
					else 
						rc = 0;
					break;
				}
				else
				{
					memset(sTmp, 0, sizeof(sTmp));
					memcpy(sTmp, record_paesi.den_paese, sizeof(record_paesi.den_paese));
					AlltrimString(sTmp);
					
					//parte chi viene visualizzata(paese )
					if(nConta == 0)
						printf( "   new Option(\"%s-%.8s\",\"%.8s\")\n",	sTmp, record_paesi.paese, record_paesi.paese);	//den paese 		
					else
						printf( "\n,  new Option(\"%s-%.8s\",\"%.8s\")\n",	sTmp, record_paesi.paese, record_paesi.paese);	//den paese 	
					fflush(stdout);
					nConta++;
				}
			}
		}//while
		MBE_FILE_CLOSE_(handle);
	}	
	return(rc);
}
//*******************************************************************
short Scrivo_Grp(short handle, short handlePA_rem, char *acPaese, char *ac_GRP)
{
	char	sTmp[500];
	char	sTmp2[100];
	char	acKey[8];
	short	rc = 0;
	t_ts_paesi_record record_paesi;
	t_ts_paesi_record record_paesi_backup;


	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));
	memset(&record_paesi_backup, ' ', sizeof(t_ts_paesi_record));

	memset(acKey, ' ', sizeof(acKey));
	memcpy(acKey, acPaese, strlen(acPaese));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, (char *) &acKey, (short)sizeof(acKey), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc );
		log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
		/* errore... */
		if ( rc)
		{
			sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFilePaesi_Loc );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			// ****  faccio copia di BACKUP per eventuale ripristino ******
			record_paesi_backup = record_paesi;

			// aggiorno il gruppo
			memcpy(record_paesi.gr_pa, ac_GRP, sizeof(record_paesi.gr_pa));

			//aggiorno il record con i dati modificati
		//	rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
			rc = MBE_WRITEUPDATEX( handle, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFilePaesi_Loc );
				log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
			else
			{
				// ********************* scrivo DB REMOTO ***********************
				rc= Aggiorno_Paesi_remoto(handlePA_rem, &record_paesi);
				if(rc == 0)
				{
					// tutto ok unlock locale
					MBE_UNLOCKREC(handle);
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
	}

	if (rc == 0)
	{
		memset(sTmp2, 0, sizeof(sTmp2));
		memcpy(sTmp2,  record_paesi.den_paese, sizeof( record_paesi.den_paese));
		AlltrimString(sTmp2);
		if(ac_GRP[0] == ' ' )
		{
			memset(sTmp, 0, sizeof(sTmp));
			memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
			AlltrimString(sTmp);

			log(LOG_INFO, "%s;%s; DelCG %s: %s",
				gUtente, gIP, sTmp, sTmp2);
		}
		else
		{
			memset(sTmp, 0, sizeof(sTmp));
			memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
			AlltrimString(sTmp);
			log(LOG_INFO, "%s;%s; InsCG %s:%s",
				gUtente, gIP, sTmp, sTmp2);
		}

		//  AGGIORNO I DB OPERATOI
		rc = Aggiorna_Operatori_GR(ac_GRP, sTmp);
	}

	return(rc);
}
//********************************************************
// cerca se il gruppo è già presente nel DB
//********************************************************
short Cerca_Gruppo(short handlePA)
{
	char		*wrk_str;
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP];
	short		rc = 0;
	short		ret = 0;
	short		is_AltKey;

	t_ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(t_ts_paesi_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	if (( (wrk_str = cgi_param( "GRUPPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_Chiave, wrk_str, strlen(wrk_str));

	/*  ricerca  per chiave alternata*/
	is_AltKey = 1;
	rc = MBE_FILE_SETKEY_( handlePA, ac_Chiave, sizeof(ac_Chiave), is_AltKey, GENERIC, 0);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey file [%s]", rc, acFilePaesi_Loc );
		log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	else
	{
		rc = MBE_READX( handlePA, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
		if (rc == 0) //trovato
		{
			sprintf(sTmp, "Error (%d) in reading file [%s]:  Group %.*s already exist", rc, acFilePaesi_Loc, LEN_GRP, ac_Chiave );
			log(LOG_ERROR, "%s;%s; %s ", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
			ret = 1;
		}
	}
	/* tutto ok */
	return(ret);
}
