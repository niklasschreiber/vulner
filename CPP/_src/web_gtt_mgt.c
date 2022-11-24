/*----------------------------------------------------------------------------
*   PROGETTO : GTT - gestione  MGT
*-----------------------------------------------------------------------------
*
*   File Name       : gtt_mgt.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*  Gestione DB MGT
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
#include <cextdecs.h (JULIANTIMESTAMP, CONVERTTIMESTAMP)>


#pragma fieldalign shared2 _pcf_stru
typedef struct _pcf_stru
{
   short      value;			// valore
   char       description[30];	// descrizione
} pcf_stru_def;

pcf_stru_def pcf_elementi[20];


/*------------- PROTOTIPI -------------*/
void Display_File();
void Maschera_Modifica(short nTipo);
void Aggiorna_Dati(short tipo);
void Lettura_Variabili(	du_mgt_rec_def *mgt_record);
short scrivi_mgt_remoto(short handleDB, du_mgt_rec_def *mgt_record, short nOperation );
void Carica_PCF();
void Leggi_Impianti(short mgt_pcf, short mgt_pc);

extern char  *str_tok(char *riga, char *sep, char elemento[], short *stop);


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
	sprintf(log_spooler.NomeDB, "GTT MGT");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");
	
	//****************************************************************************************
	Carica_PCF();


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

		log(LOG_INFO, "%s;%s; Display GTT-MGT ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);

	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for modify GTT-MGT",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW_MGT")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for insert GTT-MGT",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update GTT-MGT ",gUtente, gIP);
		Aggiorna_Dati(UPD);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert GTT-MGT ",gUtente, gIP);
		Aggiorna_Dati(INS);
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete GTT-MGT ",gUtente, gIP);
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

	du_mgt_rec_def		mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));


	//************** apertura pagina **********************
	Display_TOP("");

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handle, 1, 0);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle,(char *) mgt_record.mgt, sizeof( mgt_record.mgt), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileMGT);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
			Display_Message(0, "", sTmp);
			LOGResult = SLOG_ERROR;
		}
		/* tutto ok */
		else
		{
			// **************************** TABLE LIST MGT *************************
			printf("<CENTER>\n");
			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New MGT' onclick=\"javascript:location='%s?OPERATION=NEW_MGT'\" >\n", gName_cgi);

			printf("<BR><BR><table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH ><strong>&nbsp;Mobile Global Title</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;PCF</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Point Code</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Dual Imsi</strong></TH>\n");
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
				rc = MBE_READX( handle, (char *) &mgt_record, (short) sizeof( du_mgt_rec_def) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "%s;%s; Error Readx from file %s : code %d",gUtente, gIP, acFileMGT, rc);
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
						if(mgt_record.alternatekey.pcf == pcf_elementi[i].value)
						{
							strcpy(acPCFDesc, pcf_elementi[i].description);
							break;
						}
					}

						// (link) viene disbilitato sul cancella
					printf("<TR class='gradeGreen' onclick=\"if (link) javascript:location='%s?OPERATION=MODY&MGT=%.16s'\">\n",
							gName_cgi, mgt_record.mgt);

					printf(" <TD onclick='link = true'>&nbsp;%.16s</TD>\n", mgt_record.mgt);

					printf(" <TD onclick='link = true'>&nbsp;[%d] %s</TD>\n", mgt_record.alternatekey.pcf, acPCFDesc);
					fflush(stdout);
					printf(" <TD onclick='link = true'>&nbsp;%d</TD>\n", mgt_record.alternatekey.pc);

					if(mgt_record.c_dual_imsi == 0x20)
						mgt_record.c_dual_imsi = 0x00;

					if(mgt_record.c_dual_imsi == 0x01)
						printf(" <TD onclick='link = true' align='center'><IMG SRC='images/accept.gif'  BORDER=0 title='Active Dual Imsi' </TD>");
					else
						printf("  <TD onclick='link = true'>&nbsp;</TD>");

					fflush(stdout);
					printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&MGT=%.16s', 'MGT[%s]');\" title='Delete'>",
							gName_cgi, mgt_record.mgt, GetStringNT(mgt_record.mgt, 16));
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

			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New MGT' onclick=\"javascript:location='%s?OPERATION=NEW_MGT'\" >\n", gName_cgi);
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
	short		rc = 0;
	char		*wrk_str;
	char		sTmp[500];
	char		sTipo[20];
	char		acDisabled[20];

	du_mgt_rec_def mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));
	memset(sTmp,		0, sizeof(sTmp));

	mgt_record.alternatekey.pc = 0;

	/********************* Apertura Pagina ****************************/
	if(nTipo == INS)
	{
		strcpy(sTipo, "Insert");
		strcpy(acDisabled, "  ");
		Display_TOP("Mobile Global Title Insertion");
	}
	else
	{
		strcpy(sTipo, "Update");
		Display_TOP("Mobile Global Title Update");
	}
	
	if (( (wrk_str = cgi_param( "MGT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(mgt_record.mgt, wrk_str, strlen(wrk_str));

	if(nTipo == UPD)
	{
		strcpy(acDisabled, "Disabled");
		/*******************
		* Apro il file
		*******************/
		rc = Apri_File(acFileMGT, &handle, 1, 1);
		if (rc == 0)
		{
			/*******************
			* Cerco il record
			*******************/
			rc = MBE_FILE_SETKEY_( handle,  (char *) mgt_record.mgt, sizeof(mgt_record.mgt), 0, EXACT);
			/* errore */
			if (rc != 0)
			{
				sprintf(sTmp, " Error (%d) File_setkey from file [%s]", rc, acFileMGT);
				log(LOG_ERROR, "%s;%s; : %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				return;
			}
			/* tutto ok */
			else
			{
				rc = MBE_READX( handle, (char *) &mgt_record, (short) sizeof( du_mgt_rec_def) );
				/* errore... */
				if ( rc)
				{
					sprintf(sTmp, "Error (%d) Readx from file [%s]", rc, acFileMGT );
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
	printf("<form method='POST' action='%s' name='inputform' onsubmit='return check_MGT(%d)'>\n", gName_cgi, nTipo);

	printf("<fieldset ><legend> MGT&nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='5' border=0>\n\
			<TR>\n");
	fflush(stdout);

	printf("<TD align=right>Mobile Global Title:</TD>\n");
	fflush(stdout);
	printf("<TD align=left><input type='text'  class='numeric' name='MGT' size='16' MAXLENGTH='16' VALUE='%.16s' %s ></TD>", GetStringNT(mgt_record.mgt, 16), acDisabled );
	printf("</tr><tr>\n");
	fflush(stdout);
	printf("<TD align='right'>Point Code Format:</TD>\n");
	printf("<TD align='left'>");
	printf("	<!-- caricamento lista PCF-->");
	printf("<SELECT NAME='PCF_PC' STYLE='width: 300px;' class='chosen-select'>\n");

	Leggi_Impianti(mgt_record.alternatekey.pcf, mgt_record.alternatekey.pc);

	printf("</select></TD>\n");
	fflush(stdout);

	printf("</tr><tr>\n");

	printf("<TD align=right>Dual Imsi:</TD>\n");
	printf("<TD align=left >\n\
			<INPUT TYPE='checkbox'  NAME='DUAL_IMSI' ");
	if (mgt_record.c_dual_imsi == 0x01)
		printf("checked");
	printf("></td>");

	printf("</tr><tr>\n");
	fflush(stdout);

		/* converte TS nel formato gg/mm/aaaa hh:mm:ss  local*/
	memset(sTmp, 0x00, sizeof(sTmp));
	TS2string(sTmp, CONVERTTIMESTAMP(mgt_record.insertts, 0) );


	printf("<TD align=right>Insert TS:</TD>\n");
	printf("<TD align=left>%s</TD>", sTmp);
	printf("</tr><tr>\n");

	/* converte TS nel formato gg/mm/aaaa hh:mm:ss */
	memset(sTmp, 0x00, sizeof(sTmp));
	TS2string(sTmp, CONVERTTIMESTAMP(mgt_record.lastupdatets, 0) );

	printf("<TD align=right>Last Update TS:</TD>\n");
	printf("<TD align=left>%s</TD>", sTmp);

	printf("</TR>\n");
	printf("</TABLE>\n" );
	printf("</fieldset >");
	fflush(stdout);

	
	printf("<BR>");
	printf("<BR>\n");

	if(nTipo == UPD)
	{
		printf("<INPUT TYPE='hidden' name='MGT' value='%.16s'>\n", mgt_record.mgt);
	}

	//lo devo passare hidden perchè x l'htm se c'è un solo campo e premo invio il value non viene passato
	printf("<INPUT TYPE='hidden' name='OPERATION' value='%s'>\n", sTipo);

	printf("<center>\n");
	printf("<input type='button'  icon='ui-icon-home'   VALUE='Return To List' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
	printf("<input type='submit'  icon='ui-icon-check'  VALUE='%s' name='OPERATION' >&nbsp;", sTipo);

	printf("</CENTER></form>\n" );


	Display_BOTTOM();

}

/*************************************************************************************
*  tipo = 0 aggiorna
*  tipo = 1 inserisci
*  tipo = 2 cancella
*************************************************************************************/
void Aggiorna_Dati(short tipo)
{
	short		handleMgt = -1;
	short		handleMgt_rem = -1;
	short		rc = 0;
	char		*wrk_str;
	char		sTmp[1000];

	du_mgt_rec_def mgt_record_backup;
	du_mgt_rec_def mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgt_rec_def));
	memset(&mgt_record_backup, ' ', sizeof(du_mgt_rec_def));
	memset(sTmp,		0, sizeof(sTmp));


	if (( (wrk_str = cgi_param( "MGT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(mgt_record.mgt, wrk_str, strlen(wrk_str));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "MGT=%.16s", mgt_record.mgt);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handleMgt, 1, 1);
	if (rc == 0)
		rc = Apri_File(acFileMGT_Rem, &handleMgt_rem, 1, 2);

	if (rc == 0 && tipo != INS)
	{
		/******************
		* Cerco il record
		******************/
		rc = MBE_FILE_SETKEY_( handleMgt, (char *) mgt_record.mgt, sizeof(mgt_record.mgt), 0, EXACT);
		// errore
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  in Local file [%s]", rc, acFileMGT);
			log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else	// tutto ok
		{
			rc = MBE_READLOCKX( handleMgt, (char *) &mgt_record, (short) sizeof( mgt_record) );
			// errore...
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s]", rc, acFileMGT);
				log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
				Display_Message(1, "",sTmp);
			}
			else
			{
				// ****  faccio copia di BACKUP per eventuale ripristino ******
				memcpy(&mgt_record_backup, &mgt_record, sizeof(mgt_record));

				if( tipo == DEL) // CANCELLAZIONE
				{
					strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL

			//		rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record, 0 );
					rc = MBE_WRITEUPDATEX( handleMgt, (char *) &mgt_record, 0 );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) deleting in local file [%s] MGT= %.16s",
								rc, acFileMGT, mgt_record.mgt);
						log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);

						MBE_UNLOCKREC(handleMgt);
					}
					else
					{
						// ********************** Cancello DB REMOTO ***********************************
						rc = scrivi_mgt_remoto(handleMgt_rem, &mgt_record, DEL );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleMgt);

							log(LOG_INFO, "%s;%s; Del mgt: %.16s",	gUtente, gIP, mgt_record.mgt);
						}
						else
						{
							//  ERRORE  DB REMOTO
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handleMgt, (char *) &mgt_record_backup, (short) sizeof(du_mgt_rec_def) );
							if (rc)
							{
								if (rc == 10 )
								{
									sprintf(sTmp, "In Local DB, Mgt [%.16s] already exist", mgt_record.mgt);
									log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
									Display_Message(1, "", sTmp);
								}
								else
								{
									sprintf(sTmp, "Error (%d) in writing Local file [%s]", rc, acFileMGT);
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
					Lettura_Variabili(&mgt_record);

					mgt_record.lastupdatets =  JULIANTIMESTAMP(0);

			//		rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record, sizeof( du_mgt_rec_def) );
					rc = MBE_WRITEUPDATEX( handleMgt, (char *) &mgt_record, sizeof( du_mgt_rec_def) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating Local file [%s] - MGT=%.16s", rc, acFileMGT, mgt_record.mgt);
						log(LOG_INFO, "%s;%s; %s",	gUtente, gIP, sTmp);
						Display_Message(1, "",sTmp);

						MBE_UNLOCKREC(handleMgt);
					}
					else
					{
						// ************ scrivo DB REMOTO *****************************
						rc = scrivi_mgt_remoto(handleMgt_rem, &mgt_record, UPD );
						if(rc == 0)
						{
							// tutto ok unlock locale
							MBE_UNLOCKREC(handleMgt);
							log(LOG_INFO, "%s;%s; UPD MGT [%.16s]", gUtente, gIP, mgt_record.mgt);
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record_backup, (short) sizeof(du_mgt_rec_def) );
							if(rc)
							{
								sprintf(sTmp, "Error (%d) in updating Local file [%s]", rc, acFileMGT);
								log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
								MBE_UNLOCKREC(handleMgt);
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

		Lettura_Variabili(&mgt_record);
		mgt_record.insertts =  JULIANTIMESTAMP(0);

		rc = MBE_WRITEX( handleMgt, (char *) &mgt_record,  sizeof( du_mgt_rec_def) );
		// errore
		if (rc)
		{
			if (rc == 10 )
			{
				log(LOG_ERROR, "%s;%s; Error KEY already exist in %s ",gUtente, gIP, acFileMGT);
				sprintf(sTmp, "KEY already exist in Local file [%s]",acFileMGT);
				Display_Message(1, "",sTmp);
				//break;
			}
			else
			{
				log(LOG_ERROR, "%s;%s; Error Writex from file %s : code %d",gUtente, gIP, acFileMGT, rc);
				sprintf(sTmp, "Error (%d) writing in Loca file [%s]", rc, acFileMGT);
				Display_Message(1, "",sTmp);
				//break;
			}
		}
		else
		{
			// ************ scrivo DB REMOTO *****************************
			rc = scrivi_mgt_remoto(handleMgt_rem, &mgt_record, INS );

			if(rc == 0)
				log(LOG_INFO, "%s;%s; UPD MGT ",gUtente, gIP);
			else
			{
				// ERRORE Inserimento REMOTO
				//cancello locale
				MBE_FILE_SETKEY_( handleMgt, (char *) mgt_record.mgt, sizeof(mgt_record.mgt), 0, EXACT);
				MBE_READLOCKX( handleMgt, (char *) &mgt_record, (short) sizeof(du_mgt_rec_def) );
				rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record, 0);
				if(rc)
				{
					sprintf(sTmp, "Error (%d) deleting in  Local file [%s] ", rc, acFileMGT);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handleMgt);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}

	}

	MBE_FILE_CLOSE_(handleMgt);
	MBE_FILE_CLOSE_(handleMgt_rem);

	if(rc != 0)
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	if(rc == 0)
		Display_File( );
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



//***************************************************************************
void Lettura_Variabili(	du_mgt_rec_def *mgt_record)
{
	char	*wrk_str;
	char	sTmp[500];
	char	*pVal;

	memset(sTmp, 0 , sizeof(sTmp));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	mgt_record->alternatekey.pcf = 0;
	mgt_record->alternatekey.pc = 0;
	if (( (wrk_str = cgi_param( "PCF_PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(sTmp, wrk_str);
		pVal= strtok(sTmp, ";");
		if(pVal)
			mgt_record->alternatekey.pcf = (short) atoi(pVal);	//pcf

		pVal= strtok(NULL, ";");
		if(pVal)
			mgt_record->alternatekey.pc = (short) atoi(pVal);	//pc
	}

	if (( (wrk_str = cgi_param( "DUAL_IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		mgt_record->c_dual_imsi = 0x01;
	}
	else
		mgt_record->c_dual_imsi = 0x00;

}
//******************************************************************************************************
short scrivi_mgt_remoto(short handleDB, du_mgt_rec_def *mgt_record, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	du_mgt_rec_def mgt_record_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB,   (char *)mgt_record->mgt, (short)sizeof(mgt_record->mgt), 0, EXACT);
			/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFileMGT_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &mgt_record_tmp, (short) sizeof(du_mgt_rec_def) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFileMGT_Rem);
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) mgt_record, (short) sizeof(du_mgt_rec_def) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] ", rc, acFileMGT_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) mgt_record, (short) sizeof(du_mgt_rec_def) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Record already exist in REMOTE file [%s]", acFileMGT_Rem);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFileMGT_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) mgt_record, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] ", rc, acFileMGT_Rem);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
	}
	return(rc);
}
/***************************************************************************************************************/
void Leggi_Impianti(short mgt_pcf, short mgt_pc)
{
	short		handle = -1;
	short		i, rc = 0;
	char		sTmp[500];
	char		acPCFDesc[50];

	du_impianti_rec_def impianti;
	du_impianti_key_def key_impianti;

	/* inizializza la struttura tutta a blank */
	memset(&impianti, ' ', sizeof(du_impianti_rec_def));
	memset(&key_impianti, ' ', sizeof(du_impianti_key_def));

	key_impianti.pcf = 0;
	key_impianti.pc = 0;

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
			printf("</select> %s", sTmp);
		}
		/* tutto ok */
		else
		{
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
						printf("</select> %s", sTmp);
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					/***************************
					* Scrive il record a in Lista
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

					printf("<option Value='%d;%d'",impianti.primarykey.pcf, impianti.primarykey.pc);
					if(mgt_pcf == impianti.primarykey.pcf && mgt_pc == impianti.primarykey.pc)
						printf(" selected ");

					printf(">");
					printf("[%d] %s - %d</option>\n", pcf_elementi[i].value, pcf_elementi[i].description, impianti.primarykey.pc );
				}
			}/* while (1) */
		}
		MBE_FILE_CLOSE_(handle);
	}
}
