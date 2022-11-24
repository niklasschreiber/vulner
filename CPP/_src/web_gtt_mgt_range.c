/*----------------------------------------------------------------------------
*   PROGETTO : GTT - gestione  MGT a Range per BRASILE e ARGENTINA
*-----------------------------------------------------------------------------
*
*   File Name       : gtt_mgt.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*  Gestione DB MGT a range
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

#define MGT_LEN		16

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
void Lettura_Variabili(	du_mgtr_rec_def *mgt_record);
short scrivi_mgt_remoto(short handleDB, du_mgtr_rec_def *mgt_record, short nOperation );
void Carica_PCF();
void Leggi_Impianti(short mgt_pcf, short mgt_pc);
void Check_Insert(void);
void Check_Update(void);

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
	sprintf(log_spooler.NomeDB, "GTT MGT range");	// max 20 char

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

		log(LOG_INFO, "%s;%s; Display GTT-MGT-range ",gUtente, gIP);
		Display_File( );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	else if (strcmp(sOperazione, "MODY")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for modify GTT-MGT-range",gUtente, gIP);
		Maschera_Modifica(0);
	}
	else if (strcmp(sOperazione, "NEW_MGT")== 0 )
	{
		log(LOG_INFO, "%s;%s; Display Window for insert GTT-MGT-range",gUtente, gIP);
		Maschera_Modifica(1);
	}
	else if (strcmp(sOperazione, "Update")== 0 )
	{
		log(LOG_INFO, "%s;%s; Check Update GTT-MGT-range ",gUtente, gIP);
		Check_Update();
	}
	else if (strcmp(sOperazione, "UPDNOCHECK")== 0 )
	{
		log(LOG_INFO, "%s;%s; Update GTT-MGT-range ",gUtente, gIP);
		Aggiorna_Dati(UPD);
	}
	else if (strcmp(sOperazione, "INSNOCHECK")== 0 )
	{
		log(LOG_INFO, "%s;%s; Insert GTT-MGT-range ",gUtente, gIP);
		Aggiorna_Dati(INS);
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Check Insert GTT-MGT-range ",gUtente, gIP);
		Check_Insert();

	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Delete GTT-MGT-range ",gUtente, gIP);
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

	du_mgtr_rec_def		mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgtr_rec_def));


	//************** apertura pagina **********************
	Display_TOP("");

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handle, 1, 0);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle,(char *) mgt_record.mgt_ini, sizeof( mgt_record.mgt_ini), 0, APPROXIMATE, 0);
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
			printf("<BR><CENTER>\n");
			printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='New MGT' onclick=\"javascript:location='%s?OPERATION=NEW_MGT'\" >\n", gName_cgi);

			printf("<BR><BR><table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

			printf("<thead>\n");
			printf("<TR>\n");
			printf("  <TH ><strong>&nbsp;MGT Start</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;MGT End</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;PCF</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Point Code</strong></TH>\n");
			printf("  <TH ><strong>&nbsp;Dual Imsi</strong></TH>\n");
			printf("  <TH>&nbsp;</TH>\n");
			printf("</TR>\n");
			printf("</thead>\n");

			printf("<tbody class='editTable'>");
			fflush(stdout);

			while (1 )
			{
				/*******************
				* Leggo il record
				*******************/
				memset(&mgt_record, ' ', sizeof(du_mgtr_rec_def));

				rc = MBE_READX( handle, (char *) &mgt_record, (short) sizeof( du_mgtr_rec_def) );
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
							gName_cgi, mgt_record.mgt_ini);

					printf(" <TD onclick='link = true'>&nbsp;%.16s</TD>\n", mgt_record.mgt_ini);
					printf(" <TD onclick='link = true'>&nbsp;%.16s</TD>\n", mgt_record.mgt_end);

					printf(" <TD onclick='link = true'>&nbsp;[%d] %s</TD>\n", mgt_record.alternatekey.pcf, acPCFDesc);
					fflush(stdout);
					printf(" <TD onclick='link = true'>&nbsp;%d</TD>\n", mgt_record.alternatekey.pc);

					if(mgt_record.c_dual_imsi == 0x20)
						mgt_record.c_dual_imsi = 0;

					if(mgt_record.c_dual_imsi == 1)
						printf(" <TD onclick='link = true' align='center'><IMG SRC='images/accept.gif'  BORDER=0 title='Active Dual Imsi' </TD>");
					else
						printf("  <TD onclick='link = true'>&nbsp;</TD>");

					fflush(stdout);
					printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&MGT=%.16s', 'MGT[%s]');\" title='Delete'>",
							gName_cgi, mgt_record.mgt_ini, GetStringNT(mgt_record.mgt_ini, 16));

					printf("<div class='del_icon'></div></TD>\n");

					//printf("<IMG SRC='images/del.gif' WIDTH='12' HEIGHT='12' BORDER=0 ALT='delete' ></TD>\n");

					printf("</TR>\n");
					fflush(stdout);

				}
			}/* while (1) */
			
			printf("</tbody>");
			printf("</TABLE>\n");

			printf("</div");
			printf("<BR>\n");
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

	du_mgtr_rec_def mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgtr_rec_def));
	memset(sTmp,		0, sizeof(sTmp));

	mgt_record.alternatekey.pc = 0;

	/********************* Apertura Pagina ****************************/
	if(nTipo == INS)
	{
		strcpy(sTipo, "Insert");
		strcpy(acDisabled, "  ");
		Display_TOP("Range of Mobile Global Title Insertion");
	}
	else
	{
		strcpy(sTipo, "Update");
		Display_TOP("Range of Mobile Global Title Update");
	}

	
	if (( (wrk_str = cgi_param( "MGT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(mgt_record.mgt_ini, wrk_str, strlen(wrk_str));

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
			rc = MBE_FILE_SETKEY_( handle,  (char *) mgt_record.mgt_ini, sizeof(mgt_record.mgt_ini), 0, EXACT);
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
				rc = MBE_READX( handle, (char *) &mgt_record, (short) sizeof( du_mgtr_rec_def) );
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
	printf("<form method='POST' action='%s' name='inputform' onsubmit='return check_range_MGT(%d)' >\n", gName_cgi, nTipo);

	printf("<fieldset ><legend> MGT&nbsp;</legend>\n");
	printf("<TABLE width ='100%%' cellspacing='5' border=0>\n\
			<TR>\n");
	fflush(stdout);

	printf("<TD align=right>MGT Start:</TD>\n");
	fflush(stdout);
	printf("<TD align=left><input type='text'  class='numeric' name='MGT' size='16' MAXLENGTH='16' VALUE='%s' %s></TD>", GetStringNT(mgt_record.mgt_ini, 16), acDisabled );

	printf("<TD align=right>MGT End:</TD>\n");
	fflush(stdout);
	printf("<TD align=left><input type='text'  class='numeric' name='MGT_END' size='16' MAXLENGTH='16' VALUE='%s'></TD>", GetStringNT(mgt_record.mgt_end, 16) );
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
		printf("<INPUT TYPE='hidden' name='MGT' value='%.16s'>\n", mgt_record.mgt_ini);
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

	du_mgtr_rec_def mgt_record_backup;
	du_mgtr_rec_def mgt_record;

	/* inizializza la struttura tutta a blank */
	memset(&mgt_record, ' ', sizeof(du_mgtr_rec_def));
	memset(&mgt_record_backup, ' ', sizeof(du_mgtr_rec_def));
	memset(sTmp,		0, sizeof(sTmp));


	if (( (wrk_str = cgi_param( "MGT" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		memcpy(mgt_record.mgt_ini, wrk_str, strlen(wrk_str));
		mgt_record.mgt_length = (short) strlen(wrk_str);
	}

	log(LOG_DEBUG, "%s;%s; MGTINI[%.16s] ",gUtente, gIP, mgt_record.mgt_ini);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "MGT=%.16s", mgt_record.mgt_ini);
	strcpy(log_spooler.TipoRichiesta, "");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	/******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileMGT, &handleMgt, 1, 1);
	if (rc == 0)
		rc = Apri_File(acFileMGT_Rem, &handleMgt_rem, 1, 1);

	if (rc == 0 && tipo != INS)
	{
		/******************
		* Cerco il record
		******************/
		rc = MBE_FILE_SETKEY_( handleMgt, (char *) mgt_record.mgt_ini, sizeof(mgt_record.mgt_ini), 0, EXACT);
		// errore
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey  in Local file [%s]", rc, acFileMGT);
			log(LOG_ERROR, "%s;%s;  %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
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
								rc, acFileMGT, mgt_record.mgt_ini);
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

							log(LOG_INFO, "%s;%s; Del mgt: %.16s",	gUtente, gIP, mgt_record.mgt_ini);
						}
						else
						{
							//  ERRORE  DB REMOTO
							// inserisco il record in Locale con i dati originali
							rc = MBE_WRITEX( handleMgt, (char *) &mgt_record_backup, (short) sizeof(du_mgtr_rec_def) );
							if (rc)
							{
								if (rc == 10 )
								{
									sprintf(sTmp, "In Local DB, Mgt [%.16s] already exist", mgt_record.mgt_ini);
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

			//		rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record, sizeof( du_mgtr_rec_def) );
					rc = MBE_WRITEUPDATEX( handleMgt, (char *) &mgt_record, sizeof( du_mgtr_rec_def) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) in updating Local file [%s] - MGT=%.16s", rc, acFileMGT, mgt_record.mgt_ini);
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
							log(LOG_INFO, "%s;%s; UPD MGT [%.16s]", gUtente, gIP, mgt_record.mgt_ini);
						}
						else
						{
							// ERRORE SCRITTURA REMOTO
							// aggiorno il record in Locale con i dati originali
							rc = MBE_WRITEUPDATEUNLOCKX( handleMgt, (char *) &mgt_record_backup, (short) sizeof(du_mgtr_rec_def) );
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

		rc = MBE_WRITEX( handleMgt, (char *) &mgt_record,  sizeof( du_mgtr_rec_def) );
		// errore
		if (rc)
		{
			if (rc == 10 )
			{
				log(LOG_ERROR, "%s;%s; Error KEY already exist in %s ",gUtente, gIP, acFileMGT);
				sprintf(sTmp, "KEY already exist in Local file [%s]",acFileMGT);
				Display_Message(1, "",sTmp);
			}
			else
			{
				log(LOG_ERROR, "%s;%s; Error Writex from file %s : code %d",gUtente, gIP, acFileMGT, rc);
				sprintf(sTmp, "Error (%d) writing in Loca file [%s]", rc, acFileMGT);
				Display_Message(1, "",sTmp);
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
				MBE_FILE_SETKEY_( handleMgt, (char *) mgt_record.mgt_ini, sizeof(mgt_record.mgt_ini), 0, EXACT);
				MBE_READLOCKX( handleMgt, (char *) &mgt_record, (short) sizeof(du_mgtr_rec_def) );
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
	{
		Display_File( );
	}
}



/*****************************************************************************************************/
void Carica_PCF()
{
	int		found;
	short	i = 0;
	short	stop;
	char	*pVal;
	char	ac_wrk_str[1024];
	char	sDati[100];

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
void Lettura_Variabili(	du_mgtr_rec_def *mgt_record)
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

	memset(mgt_record->mgt_end, ' ', sizeof(mgt_record->mgt_end));
	if (( (wrk_str = cgi_param( "MGT_END" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(mgt_record->mgt_end, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "DUAL_IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		mgt_record->c_dual_imsi = 0x01;
	}
	else
		mgt_record->c_dual_imsi = 0x00;

}
//******************************************************************************************************
short scrivi_mgt_remoto(short handleDB, du_mgtr_rec_def *mgt_record, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	du_mgtr_rec_def mgt_record_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB,   (char *)mgt_record->mgt_ini, (short)sizeof(mgt_record->mgt_ini), 0, EXACT);
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
			rc = MBE_READLOCKX( handleDB, (char *) &mgt_record_tmp, (short) sizeof(du_mgtr_rec_def) );
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) mgt_record, (short) sizeof(du_mgtr_rec_def) );
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
			rc = MBE_WRITEX( handleDB, (char *) mgt_record, (short) sizeof(du_mgtr_rec_def) );
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
	rc = Apri_File(acFileImpianti, &handle, 1, 1);
	if (rc == 0)
	{
		rc = MBE_FILE_SETKEY_( handle,(char *) &key_impianti, sizeof(du_impianti_key_def), 0, APPROXIMATE, 0);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey Local file [%s]", rc, acFileImpianti);
			log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
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
						Display_Message(1, "", sTmp);
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


/********************************************************************************************************
 * funzioni controlla range
*********************************************************************************************************/
/******************************************************************************/
/*  Check_Update  *************************************************************/
/******************************************************************************/
void Check_Update(void)
{
	char			*wrk_str;
	char			*pVal;
	char			sTmp[500];
	char			sResult[4096];
	char			mgt_ini[22];
	char			mgt_end[22];
	char			chiave_gt[MGT_LEN];
	short			errore = 0;
	short			isAggiorna;
	short			handle = -1;
	int				errO;
	int				cc;
	long long		lMGT_ini_saved;
	long long		lMGT_end_saved;
	du_mgtr_rec_def     mgt_rec;
	/* Punti d'attenzione */
	short			isINI_Adiacente = 0;
	short			isEND_Adiacente = 0;
	/* Range Updating (RU) */
	short			RU_PC;
	short			RU_PCF;
	long long		RU_MGT_INI;
	long long		RU_MGT_END;
	/* Range Adiacente Ini (RAI) */
	short			RAI_PC;
	short			RAI_PCF;
	long long 		RAI_MGT_INI;
	long long 		RAI_MGT_END;
	/* Range Adiacente End (RAE) */
	short			RAE_PC;
	short			RAE_PCF;
	long long 		RAE_MGT_INI;
	long long 		RAE_MGT_END;
	char			acPCF_PC[50];
	char			ac_dual_imsi[2];

	/* inizializza */
	memset( &chiave_gt, ' ',  sizeof(chiave_gt) );
	memset( &mgt_rec, ' ',  sizeof(du_mgtr_rec_def) );
	memset( acPCF_PC, 0,  sizeof(acPCF_PC) );

	/*******************
	* Leggo parametri
	*******************/
	/* Mobile Global Title INI */
	if ( (wrk_str = cgi_param( "MGT" ) ) != NULL )
		strcpy(mgt_ini, wrk_str);
	/* Mobile Global Title END */
	if ( (wrk_str = cgi_param( "MGT_END" ) ) != NULL )
		strcpy(mgt_end, wrk_str);
	/* Point Code Format */
	/* Point Code Format */
	if (( (wrk_str = cgi_param( "PCF_PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(acPCF_PC, wrk_str);

		strcpy(sTmp, wrk_str);
		pVal= strtok(sTmp, ";");
		if(pVal)
			RU_PCF = (short) atoi(pVal);	//pcf

		pVal= strtok(NULL, ";");
		if(pVal)
			RU_PC = (short) atoi(pVal);	//pc
	}

	memset(ac_dual_imsi, 0, sizeof(ac_dual_imsi));
	if (( (wrk_str = cgi_param( "DUAL_IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		ac_dual_imsi[0] = '1';
	}

	/* trasforma MGT in numerico */
	sscanf(mgt_ini, "%Ld", &RU_MGT_INI);
	sscanf(mgt_end, "%Ld", &RU_MGT_END);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acFileMGT, &handle, 1, 1);

	if (errO == 0)
	{
		/*******************
		* imposta la chiave
		********************/
		/* ricerca su chiave PRIMARIA (0) APPROSSIMATA (0) */
		cc = MBE_FILE_SETKEY_ (handle, chiave_gt, sizeof(chiave_gt), 0, 0);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey error %d", cc);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			/******************************
			* CERCA I CASI DA CONTROLLARE
			******************************/
			while (1)
			{
				/*******************
				* legge il record
				*******************/
				cc = MBE_READX( handle, (char *)&mgt_rec, (short)sizeof(du_mgtr_rec_def) );

				if (cc != 0)
				{
					/* errore */
					if (cc != 1)
					{
						sprintf(sTmp, "Readx error %d", cc);
						log(LOG_ERROR, "%s;%s; %s ",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						errore = 1;
					}
					break;
				}
				/* record trovato */
				else
				{
					/* se i MGT del range hanno la stessa lunghezza del MGT cercato */
					if ( strlen(mgt_ini) == mgt_rec.mgt_length )
					{
						sscanf(GetStringNT(mgt_rec.mgt_ini, MGT_LEN), "%Ld", &lMGT_ini_saved);
						sscanf(GetStringNT(mgt_rec.mgt_end, MGT_LEN), "%Ld", &lMGT_end_saved);

						/* se non si tratta del range che si sta aggiornando */
						if ( RU_MGT_INI != lMGT_ini_saved )
						{
							/* INI Adiacente */
							if ( (lMGT_end_saved + 1) == RU_MGT_INI )
							{
								isINI_Adiacente = 1;
								RAI_MGT_INI = lMGT_ini_saved;
								RAI_MGT_END = lMGT_end_saved;
								RAI_PC = mgt_rec.alternatekey.pc;
								RAI_PCF = mgt_rec.alternatekey.pcf;
							}
							/* END Adiacente */
							if ( (lMGT_ini_saved - 1) == RU_MGT_END )
							{
								isEND_Adiacente = 1;
								RAE_MGT_INI = lMGT_ini_saved;
								RAE_MGT_END = lMGT_end_saved;
								RAE_PC = mgt_rec.alternatekey.pc;
								RAE_PCF = mgt_rec.alternatekey.pcf;
							}
						}
					}
				}
			} // while
			MBE_FILE_CLOSE_(handle);

			if (errore == 0)
			{
				memset(sResult, 0x00, sizeof(sResult));
				isAggiorna = 0;

				/**********************************
				* ELABORA I RISULTATI OTTENUTI
				**********************************/
				/* se non ha trovato "adiacenze" */
				if ( isINI_Adiacente == 0 && isEND_Adiacente == 0 )
				{
					isAggiorna = 1;
				}
				else if ( isINI_Adiacente == 1 && isEND_Adiacente == 0 )
				{
					/* stesso point code */
					if ( RU_PC == RAI_PC && RU_PCF == RAI_PCF)
					{
						/* allargamento range A, eliminazione range updating */
						sprintf( sResult, "<b>Delete</b> range that you are updating: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RU_MGT_END);
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RU_MGT_END);
						strcat( sResult, sTmp );
					}
					else
					{
						isAggiorna = 1;
					}
				}
				else if ( isINI_Adiacente == 0 && isEND_Adiacente == 1 )
				{
					/* stesso point code */
					if ( RU_PC == RAE_PC && RU_PCF == RAE_PCF)
					{
						/* allargamento range B, eliminazione range updating */
						sprintf( sResult, "<b>Delete</b> range that you are updating: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RU_MGT_END);
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
					}
					else
					{
						isAggiorna = 1;
					}
				}
				/* due adiacenze trovate */
				else
				{
					/* stessi point code sui tre range (INI, END, UPDATING) */
					if ( RU_PC == RAI_PC && RU_PCF == RAI_PCF && RU_PC == RAE_PC && RU_PCF == RAE_PCF )
					{
						/* unificazione unico range, eliminazione due range */
						sprintf( sResult, "<b>Delete</b> range that you are updating: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RU_MGT_END);
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
					}
					/* point code = INI, != END */
					else if ( RU_PC == RAI_PC && RU_PCF == RAI_PCF && RU_PC != RAE_PC && RU_PCF != RAE_PCF )
					{
						/* allargamento range A, eliminazione range updating */
						sprintf( sResult, "<b>Delete</b> range that you are updating: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RU_MGT_END);
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RU_MGT_END);
						strcat( sResult, sTmp );
					}
					/* point code != INI, = END */
					else if ( RU_PC != RAI_PC && RU_PCF != RAI_PCF && RU_PC == RAE_PC && RU_PCF == RAE_PCF )
					{
						/* allargamento range B, eliminazione range updating */
						sprintf( sResult, "<b>Delete</b> range that you are updating: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RU_MGT_END);
						sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
						sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RU_MGT_INI, RAE_MGT_END);
						strcat( sResult, sTmp );
					}
					else
					{
						isAggiorna = 1;
					}
				}

				/* se deve fare l'update */
				if (isAggiorna)
				{
					log(LOG_DEBUG, "%s;%s; 'prima di update' ",gUtente, gIP);

					/* procede con l'aggiornamento */
					Aggiorna_Dati(UPD);
				}
				else
				{
					/* costruisce la pagina HTML */
					Display_TOP("");

					printf("br>													\n");
					printf("<center><font color='#FF0000'><i><b><big><big>Error</big></big></b></i><br></font></center>	\n");
					printf("<center><BR>																	\n");
					printf("This update involves other MGT ranges, possible optimizations are:<BR><BR>				\n");
					printf("<TABLE border=0><TR><TD>														\n");
					printf(sResult);
					printf("</TD></TR></TABLE>																\n");
					printf("<BR><BR>																		\n");

					printf("<FORM METHOD=POST ACTION='%s'>										\n", gName_cgi);
					printf("	<input TYPE='hidden' NAME='OPERATION' VALUE='UPDNOCHECK'>		\n");
					printf("	<input TYPE='hidden' NAME='MGT' VALUE='%s'>						\n", mgt_ini);
					printf("	<input TYPE='hidden' NAME='MGT_END' VALUE='%s'>					\n", mgt_end);
					printf("	<input TYPE='hidden' NAME='PCF_PC' VALUE='%s'>					\n", acPCF_PC);
					printf("	<input TYPE='hidden' NAME='DUAL_IMSI' VALUE='%s'>				\n", ac_dual_imsi);
					printf("br >													\n");
					printf("	<input TYPE='button' icon='ui-icon-circle-arrow-w' VALUE='Back' onclick='javascript:history.go(-1); return false;'>	\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;							\n");
					printf("    <input TYPE='submit' icon='ui-icon-circle-check' VALUE='Update without optimization'  >\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;							\n");
					printf("	<input TYPE='button' icon='ui-icon-home'  VALUE='Home page' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
					printf("</FORM> 																		\n");

					Display_BOTTOM();
				}
			}
		}

		//MBE_FILE_CLOSE_(handle);
	}

	return;
}

/******************************************************************************/
/*  Check_Insert  *************************************************************/
/******************************************************************************/
void Check_Insert(void)
{
	char			*wrk_str;
	char			*pVal;
	char			sTmp[500];
	char			sResult[4096];
	char			sDelete[400000];
	char			mgt_ini[22];
	char			mgt_end[22];
	char			chiave_gt[MGT_LEN];
	short			errore = 0;
	short			isAggiungi;
	short			handle = -1;
	int				errO;
	int				cc;
	long long		lMGT_ini_saved;
	long long		lMGT_end_saved;
	du_mgtr_rec_def     mgt_rec;
	/* Punti d'attenzione */
	short			isINI_Adiacente = 0;
	short			isEND_Adiacente = 0;
	short			isINI_Compreso = 0;
	short			isEND_Compreso = 0;
	/* Range Inserting (RI) */
	short			RI_PC;
	short			RI_PCF;
	long long		RI_MGT_INI;
	long long		RI_MGT_END;
	/* Range Adiacente Ini (RAI) */
	short			RAI_PC;
	short			RAI_PCF;
	long long 		RAI_MGT_INI;
	long long 		RAI_MGT_END;
	/* Range Adiacente End (RAE) */
	short			RAE_PC;
	short			RAE_PCF;
	long long 		RAE_MGT_INI;
	long long 		RAE_MGT_END;
	/* Range Comprende Ini (RCI) */
	short			RCI_PC;
	short			RCI_PCF;
	long long 		RCI_MGT_INI;
	long long 		RCI_MGT_END;
	/* Range Comprende End (RCE) */
	short			RCE_PC;
	short			RCE_PCF;
	long long 		RCE_MGT_INI;
	long long 		RCE_MGT_END;
	/* Range da cancellare */
	char			acDelIni[4096][22];
	char			acDelEnd[4096][22];
	short			delindex = 0;

	char			acPCF_PC[50];
	char			ac_dual_imsi[2];

	/* inizializza */
	memset( &chiave_gt, ' ',  sizeof(chiave_gt) );
	memset( &mgt_rec, ' ',  sizeof(du_mgtr_rec_def) );
	memset( acPCF_PC, 0,  sizeof(acPCF_PC) );

	/*******************
	* Leggo parametri
	*******************/
	/* Mobile Global Title INI */
	if ( (wrk_str = cgi_param( "MGT" ) ) != NULL )
		strcpy(mgt_ini, wrk_str);
	/* Mobile Global Title END */
	if ( (wrk_str = cgi_param( "MGT_END" ) ) != NULL )
		strcpy(mgt_end, wrk_str);
	/* Point Code Format */
	if (( (wrk_str = cgi_param( "PCF_PC" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(acPCF_PC, wrk_str);
		strcpy(sTmp, wrk_str);
		pVal= strtok(sTmp, ";");
		if(pVal)
			RI_PCF = (short)atoi(wrk_str);	//pcf

		pVal= strtok(NULL, ";");
		if(pVal)
			RI_PC = (short)atoi(wrk_str);	//pc
	}

	memset(ac_dual_imsi, 0, sizeof(ac_dual_imsi));
	if (( (wrk_str = cgi_param( "DUAL_IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		ac_dual_imsi[0] = '1';
	}

	/* trasforma MGT in numerico */
	sscanf(mgt_ini, "%Ld", &RI_MGT_INI);
	sscanf(mgt_end, "%Ld", &RI_MGT_END);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acFileMGT, &handle, 1, 1);

	if (errO == 0)
	{
		/*******************
		* imposta la chiave
		********************/
		/* ricerca su chiave PRIMARIA (0) APPROSSIMATA (0) */
		cc = MBE_FILE_SETKEY_ (handle, chiave_gt, sizeof(chiave_gt), 0, 0);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey error %d", cc);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			/******************************
			* CERCA I CASI DA CONTROLLARE
			******************************/
			while (1)
			{
				/*******************
				* legge il record
				*******************/
				cc = MBE_READX( handle, (char *)&mgt_rec, (short)sizeof(du_mgtr_rec_def) );

				if (cc != 0)
				{
					/* errore */
					if (cc != 1)
					{
						sprintf(sTmp, "Readx error %d", cc);
						Display_Message(1, "", sTmp);
						errore = 1;
					}
					break;
				}
				/* record trovato */
				else
				{
					/* se i MGT del range hanno la stessa lunghezza del MGT cercato */
					if ( strlen(mgt_ini) == mgt_rec.mgt_length )
					{
						sscanf(GetStringNT(mgt_rec.mgt_ini, MGT_LEN), "%Ld", &lMGT_ini_saved);
						sscanf(GetStringNT(mgt_rec.mgt_end, MGT_LEN), "%Ld", &lMGT_end_saved);

						/* stesso INI */
						if ( lMGT_ini_saved == RI_MGT_INI )
						{
							sprintf(sTmp, "Record with MGT Begin = %Ld<BR>already exists", RI_MGT_INI);
							Display_Message(1, "", sTmp);
							errore = 1;
							break;
						}

						/* INI Adiacente */
						if ( (lMGT_end_saved + 1) == RI_MGT_INI )
						{
							isINI_Adiacente = 1;
							RAI_MGT_INI = lMGT_ini_saved;
							RAI_MGT_END = lMGT_end_saved;
							RAI_PC = mgt_rec.alternatekey.pc;
							RAI_PCF = mgt_rec.alternatekey.pcf;
						}
						/* END Adiacente */
						if ( (lMGT_ini_saved - 1) == RI_MGT_END )
						{
							isEND_Adiacente = 1;
							RAE_MGT_INI = lMGT_ini_saved;
							RAE_MGT_END = lMGT_end_saved;
							RAE_PC = mgt_rec.alternatekey.pc;
							RAE_PCF = mgt_rec.alternatekey.pcf;
						}
						/* INI Compreso */
						if ( RI_MGT_INI >= lMGT_ini_saved && RI_MGT_INI <= lMGT_end_saved )
						{
							isINI_Compreso = 1;
							RCI_MGT_INI = lMGT_ini_saved;
							RCI_MGT_END = lMGT_end_saved;
							RCI_PC = mgt_rec.alternatekey.pc;
							RCI_PCF = mgt_rec.alternatekey.pcf;
						}
						/* END Compreso */
						if ( RI_MGT_END >= lMGT_ini_saved && RI_MGT_END <= lMGT_end_saved )
						{
							isEND_Compreso = 1;
							RCE_MGT_INI = lMGT_ini_saved;
							RCE_MGT_END = lMGT_end_saved;
							RCE_PC = mgt_rec.alternatekey.pc;
							RCE_PCF = mgt_rec.alternatekey.pcf;
						}
						/* Saved Range Compreso tra INI e END */
						if ( lMGT_ini_saved >= RI_MGT_INI && lMGT_end_saved <= RI_MGT_END )
						{
							delindex++;
							if ( delindex < 4096 )
							{
								sprintf(acDelIni[delindex], "%Ld", lMGT_ini_saved);
								sprintf(acDelEnd[delindex], "%Ld", lMGT_end_saved);
							}
						}
					}
				}
			} // while

			MBE_FILE_CLOSE_(handle);
			if (errore == 0)
			{
				int i;

				memset(sResult, 0x00, sizeof(sResult));
				memset(sDelete, 0x00, sizeof(sDelete));
				isAggiungi = 0;

				/**********************************
				* ELABORA I RISULTATI OTTENUTI
				**********************************/
				/* se non ha trovato casi particolari da gestire */
				if ( isINI_Adiacente == 0 && isEND_Adiacente == 0 &&
					 isINI_Compreso == 0 && isEND_Compreso == 0 &&
					 delindex == 0 )
				{
					isAggiungi = 1;
				}
				else
				{
					/*-------------------------------------------------------
					     INI Libero
					--------------------*/
					if ( isINI_Adiacente == 0 && isINI_Compreso == 0 )
					{
						/*****************
						* END Compreso
						*****************/
						if ( isEND_Compreso == 1 )
						{
							/* stesso point code */
							if ( RI_PC == RCE_PC && RI_PCF == RCE_PCF)
							{
								/* allargamento range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								/* riduce range A, inserisce nuovo */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
						}
						/*****************
						* END Adiacente
						*****************/
						else if ( isEND_Adiacente == 1 )
						{
							/* stesso point code */
							if ( RI_PC == RAE_PC && RI_PCF == RAE_PCF)
							{
								/* allargamento range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								isAggiungi = 1;
							}
						}
					}

					/*-------------------------------------------------------
					    INI Compreso
					--------------------*/
					else if ( isINI_Compreso == 1 )
					{
						/*****************
						* END libero
						*****************/
						if ( isEND_Adiacente == 0 && isEND_Compreso == 0 )
						{
							/* stesso point code */
							if ( RI_PC == RCI_PC && RI_PCF == RCI_PCF)
							{
								/* allargamento range A, eliminazione range updating */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								/* riduzione range A, inserimento nuovo range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
						}
						/*****************
						* END Compreso
						*****************/
						else if ( isEND_Compreso == 1 )
						{
							/* se INI e END da inserire sono compresi nello stesso RANGE */
							if (RCI_MGT_INI == RCE_MGT_INI && RCI_MGT_END == RCE_MGT_END)
							{
								/* stesso point code */
								if ( RI_PC == RCI_PC && RI_PCF == RCI_PCF )
								{
									/* unificazione unico range */
									sprintf( sResult, "Range that you are adding with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
									sprintf( sTmp, "is fully included in existing range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
									strcat( sResult, sTmp );
								}
								/* point code diversi */
								else
								{
									/* se l'estremo INI coincide */
									if (RCI_MGT_INI == RI_MGT_INI)
									{
										/* spezza in due range */
										sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
										strcat( sResult, sTmp );
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCI_MGT_END);
										strcat( sResult, sTmp );
									}
									/* se l'estremo END coincide */
									else if (RCI_MGT_END == RI_MGT_END)
									{
										/* spezza in due range */
										sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
										strcat( sResult, sTmp );
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
										strcat( sResult, sTmp );
									}
									/* se nessun estremo coincide */
									else
									{
										/* spezza in tre range */
										sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
										strcat( sResult, sTmp );
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
										strcat( sResult, sTmp );
										sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCI_MGT_END);
										strcat( sResult, sTmp );
									}
								}
							}
							/* se INI e END da inserire sono compresi in RANGE diversi */
							else
							{
								/* stessi point code sui tre range (INI, END, UPDATING) */
								if ( RI_PC == RCI_PC && RI_PCF == RCI_PCF && RI_PC == RCE_PC && RI_PCF == RCE_PCF )
								{
									/* unificazione unico range */
									sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
									sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
								}
								/* point code = INI, != END */
								else if ( RI_PC == RCI_PC && RI_PCF == RCI_PCF && RI_PC != RCE_PC && RI_PCF != RCE_PCF )
								{
									/* allargamento range A, riduzione range B */
									sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
									sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCE_MGT_END);
									strcat( sResult, sTmp );
								}
								/* point code != INI, = END */
								else if ( RI_PC != RCI_PC && RI_PCF != RCI_PCF && RI_PC == RCE_PC && RI_PCF == RCE_PCF )
								{
									/* riduzione range A, allargamento range B */
									sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
									sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
								}
								else
								{
									/* riduzione range A, riduzione range B, inserimento nuovo range */
									sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
									sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
									strcat( sResult, sTmp );
									sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCE_MGT_END);
									strcat( sResult, sTmp );
								}
							}
						}
						/*****************
						* END Adiacente
						*****************/
						else if ( isEND_Adiacente == 1 )
						{
							/* stessi point code sui tre range (INI, END, UPDATING) */
							if ( RI_PC == RCI_PC && RI_PCF == RCI_PCF && RI_PC == RAE_PC && RI_PCF == RAE_PCF )
							{
								/* unificazione unico range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code = INI, != END */
							else if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF && RI_PC != RAE_PC && RI_PCF != RAE_PCF )
							{
								/* allargamento range A */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code != INI, = END */
							else if ( RI_PC != RAI_PC && RI_PCF != RAI_PCF && RI_PC == RAE_PC && RI_PCF == RAE_PCF )
							{
								/* riduzione range A, allargamento range B */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								/* riduzione range A, inserimento nuovo range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RCI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCI_MGT_INI, RI_MGT_INI-1);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
						}
					}

					/*-------------------------------------------------------
					    INI Adiacente
					--------------------*/
					else if ( isINI_Adiacente == 1 )
					{
						/*****************
						* END libero
						*****************/
						if ( isEND_Adiacente == 0 && isEND_Compreso == 0 )
						{
							/* stesso point code */
							if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF)
							{
								/* allargamento range A, eliminazione range updating */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								isAggiungi = 1;
							}
						}
						/*****************
						* END Compreso
						*****************/
						else if ( isEND_Compreso == 1 )
						{
							/* stessi point code sui tre range (INI, END, UPDATING) */
							if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF && RI_PC == RCE_PC && RI_PCF == RCE_PCF )
							{
								/* unificazione unico range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
								sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code = INI, != END */
							else if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF && RI_PC != RCE_PC && RI_PCF != RCE_PCF )
							{
								/* allargamento range A, riduzione range B */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
								sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code != INI, = END */
							else if ( RI_PC != RAI_PC && RI_PCF != RAI_PCF && RI_PC == RCE_PC && RI_PCF == RCE_PCF )
							{
								/* allargamento range B */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								/* riduzione range B, inserimento nuovo range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RCE_MGT_INI, RCE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_END+1, RCE_MGT_END);
								strcat( sResult, sTmp );
							}
						}
						/*****************
						* END Adiacente
						*****************/
						else if ( isEND_Adiacente == 1 )
						{
							/* stessi point code sui tre range (INI, END, UPDATING) */
							if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF && RI_PC == RAE_PC && RI_PCF == RAE_PCF )
							{
								/* unificazione unico range */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
								sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code = INI, != END */
							else if ( RI_PC == RAI_PC && RI_PCF == RAI_PCF && RI_PC != RAE_PC && RI_PCF != RAE_PCF )
							{
								/* allargamento range A */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RAI_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAI_MGT_INI, RI_MGT_END);
								strcat( sResult, sTmp );
							}
							/* point code != INI, = END */
							else if ( RI_PC != RAI_PC && RI_PCF != RAI_PCF && RI_PC == RAE_PC && RI_PCF == RAE_PCF )
							{
								/* allargamento range B */
								sprintf( sResult, "<b>Delete</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RAE_MGT_INI, RAE_MGT_END);
								sprintf( sTmp, "<b>Insert</b> range with: <b>Begin=%Ld, End=%Ld</b><BR>", RI_MGT_INI, RAE_MGT_END);
								strcat( sResult, sTmp );
							}
							else
							{
								isAggiungi = 1;
							}
						}
					}
					/*-------------------
					 range da cancellare
					--------------------*/
					if ( delindex > 0 )
					{
						isAggiungi = 0;

						strcpy(sDelete, " ");

						for (i=1; i<=delindex; i++)
						{
							sprintf( sTmp, "<b>Delete</b> range with: <b>Begin=%s, End=%s</b><BR>", &acDelIni[i][0], &acDelEnd[i][0]);
							strcat( sDelete, sTmp );
						}
					}
				}

				/*------------------------------------------------------
				* se può inserire il record
				-------------------------------------------------------*/
				if (isAggiungi)
				{
					/* procede con l'inserimento */
					Aggiorna_Dati(INS);
				}
				else
				{
					/* costruisce la pagina HTML */
					Display_TOP("");

					printf("<br><center><font color='#FF0000'><i><b><big><big>Warning</big></big></b></i><br></font></center>	\n");
					printf("<center><BR>																	\n");
					printf("This new range involves other MGT ranges, possible optimizations are:<BR><BR>			\n");
					printf("<TABLE border=0>																\n");

					if ( delindex > 0 )
						printf("<TR><TD>%s</TD></TR>														\n", sDelete);

					printf("<TR><TD>%s</TD></TR>															\n", sResult);
					printf("</TABLE><BR><BR>																\n");

					printf("<FORM METHOD=POST ACTION='%s'>									\n",gName_cgi);
					printf("	<input TYPE='hidden' NAME='OPERATION' VALUE='INSNOCHECK'>	\n");
					printf("	<input TYPE='hidden' NAME='MGT' VALUE='%s'>					\n", mgt_ini);
					printf("	<input TYPE='hidden' NAME='MGT_END' VALUE='%s'>				\n", mgt_end);
					printf("	<input TYPE='hidden' NAME='PCF_PC' VALUE='%s'>				\n", acPCF_PC);
					printf("	<input TYPE='hidden' NAME='DUAL_IMSI' VALUE='%s'>			\n", ac_dual_imsi);
					printf("br >													\n");
					printf("	<input TYPE='button' icon='ui-icon-circle-arrow-w' VALUE='Back' onclick='javascript:history.go(-1); return false;'>	\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;							\n");
					printf("    <input TYPE='submit' icon='ui-icon-circle-check' VALUE='Insert without optimization' >\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;							\n");
					printf("	<input TYPE='button' icon='ui-icon-home'  VALUE='Home page' onclick=\"javascript:location='%s'\" >\n", gName_cgi);
					printf("</FORM> 																		\n");

					Display_BOTTOM();
				}
			}
		}

		//MBE_FILE_CLOSE_(handle);
	}

	return;
}

