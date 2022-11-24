
/*----------------------------------------------------------------------------
*   PROGETTO : Esporta Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : ExportDbOP.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Esports DB operatori
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
#include "ds.h"
#include "ssplog.h"

long		RecAgg;

void  Display_File();
short EsportaRecord();

extern short Controlla_CarTable();

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	short	ret=0;
	char	*wrk_str;
	char	sTmp[50];
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
	sprintf(log_spooler.NomeDB, "Export Operator");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");


	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	//-------------------- FILE OUTPUT --------------------------
	if (( (wrk_str = cgi_param( "FILE_OUTPUT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(FileOutput, wrk_str);


	if(ret == 0)
	{
		Display_TOP("");

		if ( strcmp(sOperazione, "DISPLAY") == 0 )
		{
			Display_File();
		}
		else if ( strcmp(sOperazione, "EXPORT") == 0 )
		{
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
				log(LOG_INFO, "%s;%s; Operator DB exported correctly: %ld records",gUtente, gIP, RecAgg);
				printf("<center><br><br><br>Operator DB exported correctly");
				printf("<BR><BR>\n");
				printf(" # records exported from DB Operator: %ld<br>\n",RecAgg);

				printf("<BR><BR>\n");
				printf("<BR><BR>\n");
				printf("<hr>\
						<input TYPE='button' icon='ui-icon-home'  VALUE='OK' name='back'  onclick=\"javascript:location='%s?OPERATION=DISPLAY'\">\n\
						<hr>\n", gName_cgi);
				printf("</center>");
			}
		}

		Display_BOTTOM();
	}	
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
// CC;cod_op;tadig_code;den_op;den_paese;gruppo_op;gruppo_pa;max_ts;...
// ...imsi_op;map_ver;reset_ts_interval;characteristics;
//***************************************************************************************
short EsportaRecord()
{
	FILE		*hIn;
	short		handleOP = -1;
	short		handleOPGT = -1;
	char		ac_Chiave[18];
	char		sTmp[100];
	char		sTmp_GT[100];
	char		sTmp_Imsi[100];
	char		acCaratt[20];
	short		ret = 0;
	short		No_GT = 0;
	short		ncountGT = 0;
	int			i = 0;
	t_ts_oper_record record_operatori;
	t_ts_opergt_record record_operatori_GT;

	Controlla_CarTable();

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_GT, ' ', sizeof(t_ts_opergt_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	sprintf(log_spooler.ParametriRichiesta, "ALL");
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

	if (ret == 0)
	{
		/****************************************
		* Apro il file operatori 
		*****************************************/
		ret = Apri_File(acFileOperatori_Loc, &handleOP, 1, 0);
	}
	if (ret == 0)
	{
		/****************************************
		* Apro il file operatori_GT
		*****************************************/
		ret = Apri_File(acFileOperGT_Loc, &handleOPGT, 1, 0);
	}
	if (ret == 0)
	{
		log(LOG_DEBUG, "%s;%s; Files operator successfully opened",gUtente, gIP);

		/*****************************************
		* Cerco il record nel file operatori
		*****************************************/
		ret = MBE_FILE_SETKEY_(handleOP, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
		
		/* errore */
		if (ret != 0) {
			printf("Error (%d) in reading (file_setkey) file [%s]\n\n", ret, acFileOperatori_Loc);
			log(LOG_ERROR, "%s;%s; Error (%d) in reading file [%s]",gUtente, gIP, ret, acFileOperatori_Loc);
		}
		else
		{
			/* tutto ok */
			
			while ( 1 )
			{
				/************************************
				* Leggo il record dal file operatori
				************************************/
				ret = MBE_READX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				/* errore... */
				if (ret != 0)
				{
					if (ret != 1)
					{
						printf( "Error (%d) in reading file [%s]\n\n", ret, acFileOperatori_Loc);
						log(LOG_ERROR, "%s;%s; Error (%d) in reading file [%s]",gUtente, gIP, ret, acFileOperatori_Loc);
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
					if(record_operatori.paese[0] != '*')
					{
						/*****************************************
						* Cerco il record nel file operatoriGT
						*****************************************/
						memset (ac_Chiave, 0, sizeof (ac_Chiave));
						memcpy (ac_Chiave, record_operatori.paese, sizeof (record_operatori.paese));
						memcpy (ac_Chiave + sizeof (record_operatori.paese), record_operatori.cod_op, sizeof (record_operatori.cod_op));

						ret = MBE_FILE_SETKEY_(handleOPGT,  record_operatori.paese,
								sizeof (record_operatori.paese) + sizeof (record_operatori.cod_op), 1, GENERIC);
						
						/* errore */
						if (ret != 0) {
							printf("Error (%d) in File_setkey \n\n", ret);
							log(LOG_ERROR, "%s;%s; Error in set_key  file %s, key [%.18s] : code %d",gUtente, gIP,
								acFileOperGT_Loc, ac_Chiave, ret);
						}
						else
						{
							No_GT = 0;
							ncountGT = 0;
							/* tutto ok */
							while ( 1 )
							{
								/****************************************
								* Leggo il record dal file operatori_GT
								****************************************/
								ret = MBE_READX( handleOPGT, (char *) &record_operatori_GT, (short) sizeof(t_ts_opergt_record) );
								/* errore... */
								if (ret != 0)
								{
									if (ret != 1)
									{
										printf( "Error (%d) in reading file [%s]: key [%.10s]\n\n", ret, acFileOperGT_Loc, record_operatori.cod_op);
										log(LOG_ERROR, "%s;%s; Error (%d) in reading file [%s]: key [%.10s]",gUtente, gIP,
												ret, acFileOperGT_Loc, record_operatori.cod_op);
										break;
									}
									else   // non trovato record
									{
										ret = 0;
										if(ncountGT > 0)  // già scritti record con GT. esco senza scrivere record con solo CC
											break;
										else
											No_GT = 1;	   // NO GT scrivere record con solo CC
									}
								}

								/* Scrivo record anche se non trovo GT */
								if(ret == 0)
								{
									memset(sTmp,  0, sizeof(sTmp));
									memset(sTmp_GT, 0, sizeof(sTmp_GT));
									memset(sTmp_Imsi, 0, sizeof(sTmp_Imsi));

									if(!No_GT)  // GT trovato
									{
										if( memcmp(record_operatori_GT.paese, ac_Chiave, sizeof(record_operatori_GT.paese)+ sizeof(record_operatori_GT.cod_op)) )
											printf("different record [%.18s] - key [%s]", record_operatori_GT.paese, ac_Chiave);

										memcpy(sTmp, record_operatori_GT.gt, sizeof(record_operatori_GT.gt));
										Trim_inMezzo(sTmp, sTmp_GT);
									}
									else
									{
										memcpy(sTmp_GT, record_operatori.paese, sizeof(record_operatori.paese));
									}

									memcpy(sTmp_Imsi, record_operatori.imsi_op, sizeof(record_operatori.imsi_op));
									AlltrimString(sTmp_Imsi);
									if(sTmp_Imsi[0] == '\0')
										sTmp_Imsi[0] = ' ';

									memset(acCaratt, 0, sizeof(acCaratt));
									//CAMEL;GPRS;Servizi:ecc...
									for (i = 0; i< strlen(gCaratt); i++ )
									{
										//if(record_operatori.characteristics[i] == ' ')
										//	sprintf(acCaratt+strlen(acCaratt), "z;");
										//else
											sprintf(acCaratt+strlen(acCaratt), "%c;",record_operatori.characteristics[i]);
									}


									fprintf(hIn, "%s;%s;%.5s;%s;%s;%s; ;%d;%s\n",
											GetStringNT(record_operatori.den_paese, sizeof(record_operatori.den_paese)),
											GetStringNT(record_operatori.cod_op, sizeof(record_operatori.cod_op)),
											GetStringNT(record_operatori.tadig_code, sizeof(record_operatori.tadig_code)),
											GetStringNT(record_operatori.den_op, sizeof(record_operatori.den_op)),
											sTmp_GT, sTmp_Imsi,
											record_operatori.map_ver,
											acCaratt);

									RecAgg++;
									ncountGT++;

									// dopo aver scritto record senza GT esco dal while
									if(No_GT)
										break;
								}

							} /* while (1) */
						}
					}
				}
			}/* while (1) */
		}

		MBE_FILE_CLOSE_(handleOP);
		log(LOG_DEBUG, "%s;%s; File %s closed",gUtente, gIP, acFileOperatori_Loc);
	}

	fclose(hIn);
	log(LOG_DEBUG, "%s;%s; File %s closed",gUtente, gIP, FileOutput);

	if(ret != 0 )
		LOGResult = SLOG_ERROR;

	/*------------------------------*/
	/* LOG SICUREZZA				*/
	/*------------------------------*/
	log_spooler.EsitoRichiesta = LOGResult;
	Log2Spooler(&log_spooler, EVT_ON_ERROR);

    return(ret);
}
