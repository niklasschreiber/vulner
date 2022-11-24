/*----------------------------------------------------------------------------
*   PROGETTO : Imsi in White List
*-----------------------------------------------------------------------------
*
*   File Name       : imsi_BL.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Gestione DB IMSI record in BL
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
#include <cextdecs.h (JULIANTIMESTAMP)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"
#include "sspfunc.h"

/*------------- PROTOTIPI -------------*/
void  	Maschera_Search();
void  	Display_Search(short nTipo, char *Imsi);
void  	Maschera_Inserimento();
void  	Insert_Dati();
short 	Display_Record(char *acFile, char *acImsi_girato, char *TipoDB);
short 	ScriviDB(t_ts_imsi_record record_imsi, char *acFile, char *acFileLoc, char *acFileRem, char *ac_ImsiDritto);
short 	Scrivi_Enscribe(t_ts_imsi_record record_imsi, char *acFile_E);
void 	Prepara_Delete();
short  	Delete_Dati(char *acFile, char *ac_Imsi);

//--------------------------------------------------------------------------
short 	nAppl;

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	sTmp[500];
	short	rc = 0;
	char ac_err_msg[255];
    short rcSes;

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

	/*--------------------------------
	   Init per LOG Sicurezza
	 --------------------------------*/
	memset(&log_spooler, 0, sizeof(log_spooler));
	if ( InitSLOG() )
		return(0);
	sprintf(log_spooler.NomeDB, "IMSI WL");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	//-------------------- TIPO OPERAZIONE --------------------------
	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		Maschera_Search();
	}
	if ( strcmp(sOperazione, "SEARCH") == 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi White List - Displays the search ",gUtente, gIP);
		Display_Search(0, "");
	}

	else if (strcmp(sOperazione, "NEW")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi White List - Window New ",gUtente, gIP);
		Maschera_Inserimento();
	}
	else if (strcmp(sOperazione, "Insert")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi White List - Insert data ",gUtente, gIP);
		Insert_Dati();
	}
	else if (strcmp(sOperazione, "Delete")== 0 )
	{
		log(LOG_INFO, "%s;%s; Imsi White List - Delete ",gUtente, gIP);
		Prepara_Delete();
	}

	if(nAppl == 1)
		log( LOG_INFO, "}" );

	log_close();

	return(0);
}

/******************************************************************************/
void Maschera_Search()
{

	Display_TOP("");
	printf("<BR><BR><BR><CENTER>\n");
	printf("<FORM METHOD=POST ACTION='%s' NAME='cerca' onsubmit='return CheckCerca()'>\n\
			<INPUT TYPE='hidden' name='OPERATION' value='SEARCH' >\n", gName_cgi);

	printf("<B>Imsi: </B>");
	printf("<INPUT TYPE='text' NAME='IMSI' class='numeric' size='16' maxlength ='15'>\n");
	printf("&nbsp;&nbsp;<INPUT TYPE='submit' icon='ui-icon-search' value='Search' ></FORM>\n");

	printf("<BR>\n");
	printf("<hr>\n");

	printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='Insert Imsi in WL' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n",
			gName_cgi);

	printf("</CENTER>\n");
	printf("<hr>\n");
	fflush(stdout);

	Display_BOTTOM();

	return;
}

/******************************************************************************/
// RICERCA NEI 3 DB IMSI
// nTipo = 0 ricerca
// nTipo = 1 chiamata dopo funz. di cancellazione imi già girato
/******************************************************************************/
void Display_Search(short nTipo, char *Imsi)
{
	char		*wrk_str;
	char		acImsi_girato[20];
	char		acImsi[20];
	short		rc = 0;

	memset(acImsi_girato, 0, sizeof(acImsi_girato));
	
	if (nTipo == 0)
	{
		memset(acImsi, 0, sizeof(acImsi));
		if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
			memcpy(acImsi, wrk_str, strlen(wrk_str));

		AlltrimString(acImsi);
		// inverto imsi
		Reverse( acImsi, acImsi_girato );

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "Imsi=%s", acImsi);
		strcpy(log_spooler.TipoRichiesta, "VIEW");			// LIST, VIEW, NEW, UPD, DEL
		LOGResult = SLOG_OK;
	}
	else
		strcpy(acImsi_girato, Imsi);


	Display_TOP("");

	printf("<BR><BR><CENTER>\n\
		   <table cellpadding='0' cellspacing='0' border='0' class='display' id='greentab'>\n");

	printf("<thead>\n");
	printf("<TR >\n");
	printf("  <TH><strong>&nbsp;DB</strong></TH>\n");
	printf("  <TH><strong>&nbsp;Imsi</strong></TH>\n");
	printf("  <TH><strong>&nbsp;Timestamp</strong></TH>\n");

	printf("  <TH width='5%%'>&nbsp;</TH>\n");
	printf("</TR>\n");
	printf("</thead>\n");

	printf("<tbody >");
	fflush(stdout);

	rc = Display_Record(acFileImsiGsm, acImsi_girato, "IMSI GSM");
	if(rc == 0)
		rc = Display_Record(acFileImsiDat, acImsi_girato, "IMSI DAT" );
	//if(rc == 0)
	//	rc = Display_Record(acFileImsiLte, acImsi_girato, "IMSI LTE");
	if(rc == 0)
	{
		printf("</tbody>");
		printf("</TABLE>\n");

		// inserimento delle finestre di dialogo
		printf("<script>\n");
		printf("    insert_Confirm_Delete();\n");
		printf("</script>\n");

		printf("<BR>\n");
		printf("<hr>\n");

		printf( "<INPUT TYPE='button' icon='ui-icon-circle-plus' VALUE='Insert Imsi in WL' onclick=\"javascript:location='%s?OPERATION=NEW'\" >\n",
				gName_cgi);
		printf( "<INPUT TYPE='button' icon='ui-icon-search' VALUE='Search' onclick=\"javascript:location='%s'\" >\n",
				gName_cgi);

		printf("</CENTER>\n");
		printf("<hr>\n");

		Display_BOTTOM();
	}

	/* LOG SICUREZZA				*/
	//scrivo logspooler solo su ricerca
	if(nTipo == 0)
	{
		if(rc != 0)
			LOGResult = SLOG_OK;

		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);
	}
	return;
}

/******************************************************************************/
// RICERCA NEI 3 DB IMSI
/******************************************************************************/
short Display_Record(char *acFile, char *acImsi_girato, char *TipoDB)
{
	short 	handle = -1;
	short 	rc = 0;
	char	ac_Chiave[16];
	char	sTmp[500];
	char	acImsi_dritto[20];
	char	strdata[20];
	t_ts_imsi_record record_imsi;

	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memcpy(ac_Chiave, acImsi_girato, strlen(acImsi_girato));

	rc = Apri_File(acFile, &handle, 1, 0);
	if (rc != 0)
	{
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d", gUtente, gIP, acFile,  rc);
		return 1;
	}

	log(LOG_DEBUG, "%s;%s; File %s successfully opened",gUtente, gIP, acFile);

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) in reading (file_setkey) file %s ", rc, acFile);
		log(LOG_ERROR, "%s;%s;  %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		/*******************
		* Leggo il record
		*******************/
		rc = MBE_READX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
		/* errore... */
		if (rc != 0)
		{
			if (rc != 1)
			{
				sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
			{
				printf("<TR class='gradeGreen'>\n");
				printf("<TD align=center>%s</td>\n", TipoDB);
				printf("<TD align=center>Imsi not found</td>\n");
				printf("<TD>&nbsp;</Td>\n");
				printf("<TD>&nbsp;</Td>\n");
				printf("</TR>\n");
				fflush(stdout);
				rc = 0;
			}
		}
		/* record TROVATO */
		else  /* readx ok */
		{
			if(record_imsi.status == '1')
			{
				/***************************
				* Scrive il record a video
				****************************/
				memset(sTmp, 0 , sizeof(sTmp));
				memset(acImsi_dritto, 0, sizeof(acImsi_dritto));
				memcpy(sTmp, record_imsi.imsi, sizeof(record_imsi.imsi));

				// giro l'Imsi
				AlltrimString(sTmp);
				Reverse(sTmp, acImsi_dritto);

				// (link) viene disbilitato sul cancella
				printf("<TR class='gradeGreen'>\n");
				printf("<TD align=center>%s</td>\n", TipoDB);
				printf("<TD>&nbsp;%.16s</a></TD>\n", acImsi_dritto);
						
				TS2string(strdata, record_imsi.timestamp);
				printf("  <TD>&nbsp;%s</TD>\n", strdata);

				printf("<TD align = center onclick=\"link=false; javascript:onclickdelete('%s?OPERATION=Delete&IMSI=%.16s&DBFILE=%s', 'Imsi: [%s] from %s');\" title='Delete'>",
						gName_cgi, record_imsi.imsi,  TipoDB,
						acImsi_dritto, TipoDB);
				printf("<div class='del_icon'></div></TD>\n");

				printf("</TR>\n");
				fflush(stdout);
			}
			else
			{
				printf("<TR class='gradeGreen'>\n");
				printf("<TD align=center>%s</td>\n", TipoDB);
				printf("<TD align=center>Imsi not found</td>\n");
				printf("<TD>&nbsp;</Td>\n");
				printf("<TD>&nbsp;</Td>\n");
				printf("</TR>\n");
				fflush(stdout);
			}
		}
	}
	MBE_FILE_CLOSE_(handle);
	log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFile);


	return(rc);
}

/******************************************************************************/
void Maschera_Inserimento()
{
	char		sTmp[500];

	memset(sTmp, 0, sizeof(sTmp));
	
	Display_TOP("");

	/*---------------------------------------*/
	/* VISUALIZZO PAGINA HTML                */
	/*---------------------------------------*/

	strcpy(sTmp,"Insertion Imsi in white list ");
	printf("<br><br><br>");
	printf("<fieldset><legend>%s&nbsp;</legend>\n", sTmp);
	printf("<center>");
	printf("<BR>");

	printf("<form method='POST' action='%s' name='inputform' onsubmit=\"return CheckImsi('3')\">\n", gName_cgi);

	printf("<b>IMSI: &nbsp;</b>\n");
	printf("<input type='text' name='IMSI' size='20' MAXLENGTH=15 class='numeric'   ></TD>\n");

	printf("<BR><BR>\n");
	printf("IMSI GSM <INPUT TYPE='checkbox' NAME='DB_GSM' checked>");
	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	printf("IMSI DAT <INPUT TYPE='checkbox' NAME='DB_DAT' checked>");
	// commentato 10-01-2017
	//printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	//printf("IMSI LTE <INPUT TYPE='checkbox' NAME='DB_LTE' checked>");
	printf("<BR><BR>\n");
	printf("</CENTER>");
	printf("</fieldset>\n");
	printf("<CENTER>\n");
	printf("<BR><BR>");

	printf("<input type='submit' icon='ui-icon-circle-check' name='OPERATION' value='Insert' >\n");
	printf("</form>\n");
	printf("</CENTER>\n");

	Display_BOTTOM();
}

//************************************************************************
void Insert_Dati()
{

	char		*wrk_str;
	char		sTmp[500];
	char		ac_Chiave[16];
	char		ac_Imsi[20];
	char		ac_ImsiDritto[50];
	short		rc = 0;
	t_ts_imsi_record record_imsi;

	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));

	memset(ac_Chiave,   ' ', sizeof(ac_Chiave));
	memset(ac_Imsi,       0, sizeof(ac_Imsi));
	memset(sTmp, 0, sizeof(sTmp));
	memset(ac_ImsiDritto, 0, sizeof(ac_ImsiDritto));

	if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
	{
		strcpy(ac_ImsiDritto, wrk_str);
		// giro l'Imsi
		AlltrimString(ac_ImsiDritto);
		Reverse(ac_ImsiDritto, ac_Imsi);

		memcpy(record_imsi.imsi, ac_Imsi, strlen(ac_Imsi));
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Imsi=%s", ac_ImsiDritto);
	strcpy(log_spooler.TipoRichiesta, "NEW");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	Display_TOP("");
	printf("<br><br><br><center>");

	record_imsi.timestamp = JULIANTIMESTAMP(0);
	record_imsi.status = '1';

	// Init ts for registration time logging
	record_imsi.init_ts_op = 0;

	//-------------------- DB da utilizzare --------------------------

	if ( (wrk_str = cgi_param( "DB_GSM" ) ) != NULL )
	{
		rc = ScriviDB(record_imsi, acFileImsiGsm, acFileImsiGsm_E_Loc, acFileImsiGsm_E_Rem, ac_ImsiDritto);
		if(rc)
		{
			if (rc == 99) //record MBE presente e già in WL
				printf("<BR>\nIMSI [%s] already present in the GSM White List [%s] ",ac_ImsiDritto ,acFileImsiGsm);
			else if (rc == 88) // errore scrittura Enscribe
				printf("<BR>\nIMSI [%s] ATTENTION! - MBE [%s] and Enscribe are not aligned",ac_ImsiDritto ,acFileImsiGsm);
			else
				return;
		}
		else
			printf("<BR>\nIMSI [%s] properly inserted in the GSM White List [%s] ",ac_ImsiDritto ,acFileImsiGsm);
	}

	if ( (wrk_str = cgi_param( "DB_DAT" ) ) != NULL )
	{
		rc = ScriviDB(record_imsi, acFileImsiDat, acFileImsiDat_E_Loc, acFileImsiDat_E_Rem, ac_ImsiDritto);
		if(rc)
		{
			if (rc == 99)
				printf("<BR>\nIMSI [%s] already present in the DAT White List [%s] ",ac_ImsiDritto ,acFileImsiDat);
			else if (rc == 88)
				printf("<BR>\nIMSI [%s] ATTENTION! - MBE and Enscribe are not aligned",ac_ImsiDritto ,acFileImsiDat);
			else
				return;
		}
		else
			printf("<BR>\nIMSI [%s] properly inserted in the DAT White List [%s] ",ac_ImsiDritto ,acFileImsiDat);

	}
	/*if ( (wrk_str = cgi_param( "DB_LTE" ) ) != NULL )
	{
		rc = ScriviDB(record_imsi, acFileImsiLte, ac_ImsiDritto);
		if(rc)
		{
			if (rc == 99)
				printf("<BR>\nIMSI [%s] already present in the LTE White List [%s] ",ac_ImsiDritto ,acFileImsiLte);
			else
				return;
		}
		else
			printf("<BR>\nIMSI [%s] properly inserted in the LTE White List [%s] ",ac_ImsiDritto ,acFileImsiLte);

	}*/

	if (rc == 0 || rc == 99)
	{
		printf("<BR><BR><HR>\n");
		printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='OK' \
						onclick=\"javascript:location='%s'\" >\n",
						gName_cgi);
		printf("<hr></center>");
		Display_BOTTOM();

	}
	else
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

}

//*********************************************************************************************************************
// scrive su MBE ed Enscribe Loc e Rem
//*********************************************************************************************************************
short ScriviDB(t_ts_imsi_record record_imsi, char *acFile, char *acFileLoc, char *acFileRem, char *ac_ImsiDritto)
{
	short	handle = -1;
	short 	rc = 0;
	short  	rc_E = 0;
	char 	sTmp[500];

	t_ts_imsi_record record_appo;


	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFile, &handle, 1, 1);

	if (rc == 0 )
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened", gUtente, gIP, acFile);

		rc = MBE_WRITEX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
		/* errore */         
		if (rc)
		{
			if (rc == 10 )
			{
				//---------------- record esistente  ----------------------
				/*******************
				* Cerco il record
				*******************/
				rc = MBE_FILE_SETKEY_( handle, record_imsi.imsi, (short)sizeof(record_imsi.imsi), 0, EXACT);
				/* errore */
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				/* tutto ok */
				else
				{
					rc = MBE_READLOCKX( handle, (char *) &record_appo, (short) sizeof(t_ts_imsi_record) );
					/* errore... */
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile);
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
					}
					else
					{
						//controllo se il record è in WHITE list
						if(record_appo.status != '1') // no BL
						{
							rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
							if(rc)
							{
								MBE_UNLOCKREC(handle);
								sprintf(sTmp, " Error (%d) in writing file %s", rc, acFile);
								log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
								Display_Message(1, "", sTmp);
							}
							else 
							{//record aggiornato
								log(LOG_INFO, "%s;%s; INS Imsi White List: %s", gUtente, gIP, ac_ImsiDritto);
							}
						}
						else		//in BL	
						{
							sprintf(sTmp, "IMSI %s is in White List", ac_ImsiDritto);
							log(LOG_INFO, "%s;%s; %s",gUtente, gIP, sTmp);
							rc = 99;
							MBE_UNLOCKREC(handle);
						}
					}
				}
			} //fine record presente
			else
			{
				sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
		}
		else 
		{	//inserito record
			log(LOG_INFO, "%s;%s; INS Imsi White List: %s", gUtente, gIP, ac_ImsiDritto);
		}

		MBE_FILE_CLOSE_(handle);
		log(LOG_DEBUG, "%s;%s; File %s closed", gUtente, gIP, acFile);
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d", gUtente, gIP, acFile, rc);


	// se tutto ok o record già in WL (rc=99) aggiorno Enscribe locale e remoto
	if(rc == 0 || rc == 99)
	{
		//Locale
		rc_E = Scrivi_Enscribe(record_imsi, acFileLoc);
		if(rc_E == 0)
		{
			// Remoto
			rc_E = Scrivi_Enscribe(record_imsi, acFileRem);
			if(rc_E != 0)
				log(LOG_ERROR, "%s;%s; Error updating file %s : %d", gUtente, gIP, acFileRem, rc);
		}
		else
			log(LOG_ERROR, "%s;%s; Error updating file %s : %d", gUtente, gIP, acFileLoc, rc);

		if(rc_E != 0)
			rc = 88;
	}

	return(rc);
}

//*********************************************************************************************************************
short Scrivi_Enscribe(t_ts_imsi_record record_imsi, char *acFile_E)
{
	short	handle = -1;
	short 	rc = 0;
	char 	sTmp[500];

	t_ts_imsi_record record_appo;


	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFile_E, &handle, 1, 1);

	if (rc == 0 )
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened", gUtente, gIP, acFile_E);

		rc = MBE_WRITEX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
		/* errore */
		if (rc)
		{
			if (rc == 10 )
			{
				//---------------- record esistente  ----------------------
				/*******************
				* Cerco il record
				*******************/
				rc = MBE_FILE_SETKEY_( handle, record_imsi.imsi, (short)sizeof(record_imsi.imsi), 0, EXACT);
				/* errore */
				if (rc != 0)
				{
					sprintf(sTmp, "Error (%d) File setKey file %s", rc, acFile_E);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(0, "", sTmp);
				}
				/* tutto ok */
				else
				{
					rc = MBE_READLOCKX( handle, (char *) &record_appo, (short) sizeof(t_ts_imsi_record) );
					/* errore... */
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile_E);
						log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
						Display_Message(0, "", sTmp);
					}
					else
					{
						//controllo se il record è in WHITE list
						if(record_appo.status != '1') // no BL
						{
							rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
							if(rc)
							{
								MBE_UNLOCKREC(handle);
								sprintf(sTmp, " Error (%d) in writing file %s", rc, acFile_E);
								log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
								Display_Message(0, "", sTmp);
							}
						}
						else		//in BL
							MBE_UNLOCKREC(handle);
					}
				}
			} //fine record presente
			else
			{
				sprintf(sTmp, "Error (%d) in reading file %s", rc, acFile_E);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(0, "", sTmp);
			}
		}

		MBE_FILE_CLOSE_(handle);
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d", gUtente, gIP, acFile_E, rc);

	return(rc);
}

// ************************************************************************************************************************
// cancella da MBE, Enscribe Locale e Remoto
// ************************************************************************************************************************
void Prepara_Delete()
{
	char		*wrk_str;
	short		rc ;
	char		acTipoFile[100];
	char		ac_ImsiDritto[50];
	char		ac_ImsiGirato[50];

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE          */
	/*---------------------------------------*/

	memset(ac_ImsiGirato, 0, sizeof(ac_ImsiGirato));
	memset(ac_ImsiDritto, 0, sizeof(ac_ImsiDritto));

	if (( (wrk_str = cgi_param( "IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(ac_ImsiGirato, wrk_str, strlen(wrk_str));

	if (( (wrk_str = cgi_param( "DBFILE" ) ) != NULL ) && (strlen(wrk_str) > 0))
		memcpy(acTipoFile, wrk_str, strlen(wrk_str));

	// giro l'Imsi
	AlltrimString(ac_ImsiGirato);
	Reverse(ac_ImsiGirato, ac_ImsiDritto);

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "Imsi=%s", ac_ImsiDritto);
	strcpy(log_spooler.TipoRichiesta, "DEL");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;


	if ( !memcmp(acTipoFile, "IMSI GSM", 8) )
	{
		// MBE
		rc = Delete_Dati(acFileImsiGsm, ac_ImsiGirato );
		if(rc == 0)
		{
			log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. MBE: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiGsm);
			// Enscribe Locale
			rc = Delete_Dati(acFileImsiGsm_E_Loc, ac_ImsiGirato);
			if(rc == 0)
			{
				log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. Enscribe Loc: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiGsm_E_Loc);
				// Enscribe Remoto
				rc = Delete_Dati(acFileImsiGsm_E_Rem, ac_ImsiGirato);
				if(rc == 0)
					log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. Enscribe Rem: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiGsm_E_Rem);
			}
		}
	}
	else if ( !memcmp(acTipoFile, "IMSI DAT", 8) )
	{
		// MBE
		rc = Delete_Dati(acFileImsiDat, ac_ImsiGirato );
		if(rc == 0)
		{
			log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. MBE: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiDat);
			// Enscribe Locale
			rc = Delete_Dati(acFileImsiDat_E_Loc, ac_ImsiGirato);
			if(rc == 0)
			{
				log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. Enscribe Loc: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiDat_E_Loc);
				// Enscribe Remoto
				rc = Delete_Dati(acFileImsiDat_E_Rem, ac_ImsiGirato);
				if(rc == 0)
					log(LOG_INFO, "%s;%s; DEL Imsi (%s) from White List. Enscribe Rem: [%s]", gUtente, gIP, ac_ImsiDritto, acFileImsiDat_E_Rem);
			}
		}
	}

	if (rc != 0 )
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	if (rc == 0 )
		Display_Search(1, ac_ImsiGirato);

	return;
}
/* --------------------------------------------------------------------------*/
short Delete_Dati(char *acFile, char *ac_Imsi)
{
	short		handle = -1;
	char		sTmp[500];
	short		rc ;
	char		ac_Chiave[16];


	t_ts_imsi_record record_appo;

	/* inizializza la struttura tutta a blank */
	memset(&record_appo, ' ', sizeof(t_ts_imsi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memcpy(ac_Chiave, ac_Imsi, strlen(ac_Imsi));

	/*******************
	* Apro il file 
	*******************/
	rc = Apri_File(acFile, &handle, 1, 1);
	
	if (rc == 0)
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened key[%s]", gUtente, gIP, acFile, ac_Chiave);

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
					sprintf(sTmp, "Error (%d) in deleting from file %s ", rc, acFile );
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
			// potrebbe capitare nell'Escribe remoto perciò se non lo trova non segnalo errore
/*
			else
			{
				sprintf(sTmp, "Delete: Error (%d) in reading file %s", rc, acFile);
				log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
*/
		}
		else
		{
			sprintf(sTmp, "Delete:  Error (%d) in reading (file_setkey) file %s ", rc, acFile);
			log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
	}
	else
		log(LOG_ERROR, "%s;%s; Error in opening file %s : %d", gUtente, gIP, acFile, rc);


	MBE_FILE_CLOSE_(handle);

	return(rc);
}

