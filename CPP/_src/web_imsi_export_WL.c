
/*----------------------------------------------------------------------------
*   PROGETTO : Esporta Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : ExportImsiBL.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Esports IMSI in White list
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

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <tal.h>
#include <usrlib.h>
#include <ctype.h>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"
#include "sspfunc.h"

long	RecAgg;
char	cTipo_Imsi;

void  	Display_File();
short 	EsportaRecord();


/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	short	ret=0;
	char	*wrk_str;
	char	sTmp[100];
	short	rc = 0;
	char ac_err_msg[255];
    short rcSes;

    disp_Top = 0;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));
	memset(acFileOperatori_Loc, 0x00, sizeof(acFileOperatori_Loc));
	memset(acFileOperGT_Loc, 0x00, sizeof(acFileOperGT_Loc));

	RecAgg = 0;

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
	sprintf(log_spooler.NomeDB, "Export IMSI WL");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);


	Display_TOP("");

	if ( strcmp(sOperazione, "DISPLAY") == 0 )
	{
		Display_File();
	}
	else if ( strcmp(sOperazione, "EXPORT") == 0 )
	{

		//-------------------- FILE OUTPUT --------------------------
		if (( (wrk_str = cgi_param( "FILE_OUTPUT" ) ) != NULL ) && (strlen(wrk_str) > 0))
			strcpy(FileOutput, wrk_str);
		else
		{
			Display_Message(0, "", "<BR>Insert Output file");
			exit(0);
		}

		/* tipo operazione */
		if (( (wrk_str = cgi_param( "TIPO_IMSI" ) ) != NULL ) && (strlen(wrk_str) > 0))
			cTipo_Imsi =  wrk_str[0];
		else
		{
			Display_Message(0, "", "Select one Imsi DB");
			exit(0);
		}
		printf("<center><br><br>\n");
		printf("<BR><BR>\
		<span id='wait1'>\
		<IMG SRC='images/loading.gif' BORDER=0 ALT=''>\n\
		</span>\n");
		fflush(stdout);

		log(LOG_INFO, "%s;%s; Export Operator: Start",gUtente, gIP);

		ret = EsportaRecord();
		printf("<SCRIPT LANGUAGE='JavaScript'>\n\
							togliegif('wait1', 0);\n\
							</SCRIPT>");

		if(ret == 0)
		{
			if(cTipo_Imsi == 'G')
				strcpy(sTmp, "GSM");
			else if(cTipo_Imsi == 'D')
				strcpy(sTmp, "DAT");
			//else if(cTipo_Imsi == 'L')
			//	strcpy(sTmp, "LTE");

			log(LOG_INFO, "%s;%s; IMSI %s in White List exported correctly: %ld records",gUtente, gIP, sTmp, RecAgg);
			printf("<center><br><br><br>IMSI %s  in White List exported correctly.", sTmp);
			printf("<BR><BR>\n");
			printf(" # records exported from IMSI %s DB: %ld<br>\n", sTmp, RecAgg);

			printf("<BR><BR>\n");
			printf("<BR><BR>\n");
			printf("<hr>\
					<input TYPE='button' icon='ui-icon-home'  VALUE='OK' name='back'  onclick=\"javascript:location='%s?OPERATION=DISPLAY'\">\n\
					<hr>\n", gName_cgi);
			printf("</center>");
		}
	}

	Display_BOTTOM();

	log_close();

}
//*****************************************************************************************
void Display_File()
{

	printf("<center><br><br><br><br>");
	printf("<P><FORM METHOD=POST ACTION='%s' NAME='inputform' >\n\
					<INPUT TYPE='hidden' name='OPERATION' value='EXPORT' >\n\
					<TABLE border=0 align='center'  >\n\
					<TR><TD><B>Output File: </B></td>\n\
					<td><INPUT TYPE='text' NAME='FILE_OUTPUT' size='50' maxlength ='50' >\n\
					</td></tr> \n\
					<TR><TD>&nbsp;</td>\n\
					<td>OSS Pathname (es:/G/volume/subvol/file name)</td></tr></TABLE></P>", gName_cgi);
	printf("<BR><BR>\n");
	printf("Imsi GSM <INPUT TYPE='radio' NAME='TIPO_IMSI' VALUE='G' >");
	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	printf("Imsi DAT <INPUT TYPE='radio' NAME='TIPO_IMSI' VALUE='D' >");
	//printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	//printf("Imsi LTE <INPUT TYPE='radio' NAME='TIPO_IMSI' VALUE='L' >");

	printf("<BR><BR><BR>\n");
	printf("<hr>\n");
	printf("<input type='submit' icon='ui-icon-arrowthickstop-1-s' value='Export' >\n");
	printf("<hr></form></center>\n");
			
}

//***************************************************************************************
// Formato file da esportare:
// Den. Paese;Codice OP;Den OP;MGT;imsi;non usato; map vers
//
// Formato file da esportare (vecchio): 
// CC;cod_op;den_op;den_paese;gruppo_op;gruppo_pa;max_ts;...
// ...imsi_op;map_ver;reset_ts_interval;characteristics;
//***************************************************************************************
short EsportaRecord()
{
	FILE		*hIn;
	short		handle = -1;
	short		ret = 0;
	char		ac_Chiave[16];
	char		ac_ImsiDritto[50];
	char		ac_ImsiGirato[50];
	char		acFileTmp[150];

	t_ts_imsi_record record_imsi;

	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "White List");
	strcpy(log_spooler.TipoRichiesta, "LIST");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;


     /* apre il file  output */
	if ((hIn = fopen(FileOutput, "w")) == NULL)
	{
		/* avvisa dell'errore */
		printf("Error (%d) in opening file [%s]\n\n",errno, FileOutput );
		log(LOG_ERROR, "%s;%s; Error (%d) in opening file [%s] ",gUtente, gIP, errno, FileOutput);
		ret = 1;
	}

	/****************************************
	* Apro il file IMSI
	*****************************************/
	// non faccio visualizzare l'eventuale errore dall funz Apri_file
	if(cTipo_Imsi == 'G')
	{
		ret = Apri_File(acFileImsiGsm, &handle, 0, 0);
		strcpy(acFileTmp, acFileImsiGsm);
	}
	else if(cTipo_Imsi == 'D')
	{
		ret = Apri_File(acFileImsiDat, &handle, 0, 0);
		strcpy(acFileTmp, acFileImsiDat);
	}
	// commentato 10-01-2017
	/*else if(cTipo_Imsi == 'L')
	{
		ret = Apri_File(acFileImsiLte, &handle, 0, 0);
		strcpy(acFileTmp, acFileImsiLte);
	}*/


	if (ret == 0)
	{
		/*****************************************
		* leggo tutti i record del file imsi
		*****************************************/
		ret = MBE_FILE_SETKEY_(handle, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
		
		/* errore */
		if (ret != 0) {
			printf("Error (%d) in reading (file_setkey) file [%s]\n\n", ret, acFileTmp);
			log(LOG_ERROR, "%s;%s; Error (%d) in reading file [%s]",gUtente, gIP, ret, acFileTmp);
		}
		else
		{
			/* tutto ok */
			
			while ( 1 )
			{
				ret = MBE_READX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
				/* errore... */
				if (ret != 0)
				{
					if (ret != 1)
					{
						printf( "Error (%d) in reading file [%s]\n\n", ret, acFileTmp);
						log(LOG_ERROR, "%s;%s; Error (%d) in reading file [%s]",gUtente, gIP, ret, acFileTmp);
					}
					else
					{
						ret = 0;
					}
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					//controllo: se il record è in WHITE list lo esporto
					if(record_imsi.status == '1') // SI BL
					{
						memset(ac_ImsiDritto, 0, sizeof(ac_ImsiDritto));
						memset(ac_ImsiGirato, 0, sizeof(ac_ImsiGirato));
						memcpy(ac_ImsiGirato, record_imsi.imsi, sizeof(record_imsi.imsi));
						// giro l'Imsi

						AlltrimString(ac_ImsiGirato);
						Reverse(ac_ImsiGirato, ac_ImsiDritto);
						fprintf(hIn, "%s\n", ac_ImsiDritto);

						RecAgg++;
					}
				}
			}/* while (1) */
		}

		MBE_FILE_CLOSE_(handle);
		fclose(hIn);
		log(LOG_DEBUG, "%s;%s; Imsi WL exported from File [%s]",gUtente, gIP, acFileTmp);
	}
	else
		printf("Error %d in opening file [%s]", ret, acFileTmp);

	if(ret != 0 )
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

    return(ret);
}
