/*----------------------------------------------------------------------------
*   PROGETTO : Traffic Steering
*-----------------------------------------------------------------------------
*
*   File Name       : importa_paesi_cgi.c
*   Ultima Modifica : 09/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   -----------
*   Importa Paesi
*
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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cextdecs.h (FILE_GETINFO_)>
#include <usrlib.h>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "sspfunc.h"
#include "ssplog.h"

void Display();
void FeedByFile(char *file_import);


int main (short argc, char * argv[]) 
{
	char	*wrk_str;
	char	sTmp[500];
	short	rc = 0;
	char ac_err_msg[255];
    short rcSes;

    disp_Top = 0;
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
	gUtente = cgi_param( "REMOTE_USER" );
	gIP     = cgi_param( "REMOTE_ADDR" );

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
	sprintf(log_spooler.NomeDB, "Country-import");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	Display_TOP("IMPORT COUNTRIES");

	//-------------------- tipo operazione --------------------------
	strcpy(sOperazione, "DISPLAY");	//default
	if ((wrk_str = cgi_param("OPERATION")) != NULL && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	if ( !strcmp(sOperazione, "DISPLAY") )
	{
		Display();
		Display_BOTTOM();
		return (0);
	}

	//import operation
	//-------------------- FILE INPUT --------------------------
	if ((wrk_str = cgi_param("FILE_INPUT")) != NULL && (strlen(wrk_str) > 0))
		strcpy(FileInput, wrk_str);
	else
	{
		printf("<center><b>Missing request parameter FILE_INPUT</b></center>");
		Display_BOTTOM();
		return (0);
	}

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "");
	strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
	LOGResult = SLOG_OK;

	printf("<center><br><br><i>Import Countries Start</i><br>");
	fflush(stdout);
	log(LOG_INFO, "%s;%s; Import Countries Start",gUtente, gIP);
	FeedByFile(FileInput);

	printf("<br><br><i>Import Countries End</i><br></center>");
	Display_BOTTOM();

	log_close();

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

	return (0);
}

//************************************************************************
void Display()
{
	printf("<center><br><br><br><br>");
	printf("<p><form method='POST' action='%s' name='inputform'>", gName_cgi);
	printf("<input type='hidden' name='OPERATION' value='INSERT'>");
	printf("<table border=0 align='center'>");
	printf("<tr><td><b>Input File: </b></td><td><input type='text' name='FILE_INPUT' size='80' maxlength ='80'></td></tr>");
	printf("<tr><td>&nbsp;</td><td>OSS Pathname (es:/G/volume/subvol/file name)</td></tr>");
	printf("</table>");
	printf("</p><br><br><br>");
	printf("<hr><input icon='ui-icon-check' type='submit' value='Confirm'><hr>");
	printf("</form></center>");
}


void FeedByFile(char *file_import)
{
    char			buffer[100];
	char			log_buffer[100];
	short			rc;
	int				i_count_total = 0;
	int				i_count_insert = 0;
	char			*pstr;

	short			fileid = -1;
	short			fileid_rem = -1;
    FILE			*hinfile;

	t_ts_paesi_record rec;


	if (rc = Apri_File(acFilePaesi_Loc, &fileid, 1, 0))
	{
		log(LOG_ERROR, "%s;%s; Error in opening Local file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);
		LOGResult = SLOG_ERROR;
		return;
	}
	if (rc = Apri_File(acFilePaesi_Rem, &fileid_rem, 1, 0))
	{
		log(LOG_ERROR, "%s;%s; Error in opening Remote file %s : code %d",gUtente, gIP, acFilePaesi_Rem, rc);
		LOGResult = SLOG_ERROR;
		return;
	}

  //  hinfile = fopen_oss(file_import, "r+");
    hinfile = fopen(file_import, "r");
    if (hinfile == NULL)
    {
        FILE_GETINFO_(-1, &rc);
		printf("<b>Error [%d] opening &quot;%s&quot;</b>", rc, file_import);
		log(LOG_ERROR, "%s;%s; Error in opening file %s : code %d",gUtente, gIP, file_import, rc);
		LOGResult = SLOG_ERROR;
		return;
    }

	while (!feof(hinfile))
	{
		memset(buffer, ' ', sizeof(buffer));
		if (fgets(buffer, sizeof(buffer), hinfile) != NULL)
		{
			i_count_total++;
				
	//A09	StrToUpper( buffer );

			pstr = buffer;
			while (*pstr != 0)
			{
				if (*pstr == 0x0A || *pstr == 0x0D) *pstr = 0x00;
				pstr++;
			}
			memcpy(log_buffer, buffer, 100);

			// Get fields
			memset((char *)&rec, 0x20, sizeof(t_ts_paesi_record));
			if ((pstr = GetToken(buffer, ",;|")) && strlen(pstr)<=sizeof(rec.paese))
			{
				memcpy(rec.paese, pstr, strlen(pstr));

				if ((pstr = GetToken((char *)NULL, ",;|")) && strlen(pstr)<=sizeof(rec.gr_pa))
					memcpy(rec.gr_pa, pstr, strlen(pstr));

				if ((pstr = GetToken((char *)NULL, ",;|")) && strlen(pstr)<=sizeof(rec.den_paese))
				{
					memcpy(rec.den_paese, pstr, strlen(pstr));

					if ((pstr = GetToken((char *)NULL, ",;|")))
						rec.max_ts = (short)atoi(pstr);
					else
						rec.max_ts = 1;

					if ((pstr = GetToken((char *)NULL, ",;|")))
						rec.reset_ts_interval = atoi(pstr);
					else
						rec.reset_ts_interval = 0;
				}
				else
				{
					printf("<br>invalid country denomination in entry [%s]", log_buffer);
					log(LOG_WARNING, "%s;%s; Invalid country denomination in entry [%s]",gUtente, gIP, log_buffer);
				}
			}
			else
			{
				printf("<br>invalid country code in entry [%s]", log_buffer);
				log(LOG_WARNING, "%s;%s; Invalid country code in entry [%s]",gUtente, gIP, log_buffer);
			}

			// Insert
			if ((rc = MBE_WRITEX(fileid, (char *)&rec, sizeof(t_ts_paesi_record))))
			{
				if(rc == 10)
					printf("<br>Record [%s] already exist in Local DB[%s]", log_buffer, acFilePaesi_Loc);
				else
					printf("<br>error [%d] inserting entry [%s] in Local DB[%s]", rc, log_buffer, acFilePaesi_Loc);
				log(LOG_ERROR, "%s;%s; Error in writing entry [%s] in Local file %s : code %d"
							,gUtente, gIP, log_buffer, acFilePaesi_Loc, rc);
				LOGResult = SLOG_ERROR;
			}
			else
			{
				if ((rc = MBE_WRITEX(fileid_rem, (char *)&rec, sizeof(t_ts_paesi_record))))
				{
					if(rc == 10)
						printf("<br>Record [%s] already exist in Remote DB[%s]", log_buffer, acFilePaesi_Loc);
					else
						printf("<br>error [%d] inserting entry [%s] in Remote file [%s]", rc, log_buffer, acFilePaesi_Rem);
					log(LOG_ERROR, "%s;%s; Error in writing entry [%s] in Remote file %s : code %d"
								,gUtente, gIP, log_buffer, acFilePaesi_Rem, rc);
					LOGResult = SLOG_ERROR;
				}
				else
				{
					i_count_insert++;
					//printf("<br>inserted entry [%s]", log_buffer);
					log(LOG_DEBUG, "%s;%s; Record successfully written in Local e Remote file ",gUtente, gIP);
				}
			}
        }
		if( ferror(hinfile))
		{
			printf("<BR><center><font color=red>Invalid File</font></center>");
			LOGResult = SLOG_ERROR;
			break;
		}

		if(i_count_total % 100 == 0)
		{
			printf("<br>-- %d", i_count_total);
		}
    }
	// End of file
    
	printf("<br><br><b>%d records processed, %d inserted</b>", i_count_total, i_count_insert);
	fflush(stdout);
	log(LOG_INFO, "%s;%s; %d records processed, %d inserted",gUtente, gIP, i_count_total, i_count_insert);

	fclose(hinfile);

}  // FeedByFile

