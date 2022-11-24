/*----------------------------------------------------------------------------
*   PROGETTO : Importa Imsi in White List
*-----------------------------------------------------------------------------
*
*   File Name       : imp_imsi_BL
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Importa IMSI in White List
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
#include <cextdecs.h (JULIANTIMESTAMP)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"
#include "sspfunc.h"

long	RecAgg;
long	RecUpd;

long	DAT_RecAgg;
long	DAT_RecUpd;
long	DAT_Loc_RecAgg;
long	DAT_Loc_RecUpd;
long	DAT_Rem_RecAgg;
long	DAT_Rem_RecUpd;

long	GSM_RecAgg;
long	GSM_RecUpd;
long	GSM_Loc_RecAgg;
long	GSM_Loc_RecUpd;
long	GSM_Rem_RecAgg;
long	GSM_Rem_RecUpd;

//long	LTE_RecAgg;
//long	LTE_RecUpd;
long	GSM_RecScartato;
char	cTipo;
short	nGSM;
short	nDAT;
//short	nLTE;

void  Display_File();
short ScriviImsi(short handle, char *ac_ImsiDritto);
short DeleteImsi(short handle, char *ac_ImsiDritto);


/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	int		rc = 0;
	short	handleGsm = -1;
	short	handleGsm_loc = -1;
	short	handleGsm_rem = -1;
	short	handleDat = -1;
	short	handleDat_loc = -1;
	short	handleDat_rem = -1;
//	short	handleLte = -1;
    char	sLetti[301];
	FILE	*hIn;
	char	*pTmp;
	char	sTmp[500];
	char 	ac_err_msg[255];
    short 	rcSes;

	RecAgg = 0;
	RecUpd = 0;
	DAT_RecAgg = 0;
	DAT_RecUpd = 0;
	DAT_Loc_RecAgg = 0;
	DAT_Loc_RecUpd = 0;
	DAT_Rem_RecAgg = 0;
	DAT_Rem_RecUpd = 0;
	GSM_RecAgg = 0;
	GSM_RecUpd = 0;
	GSM_Loc_RecAgg = 0;
	GSM_Loc_RecUpd = 0;
	GSM_Rem_RecAgg = 0;
	GSM_Rem_RecUpd = 0;

	GSM_RecScartato = 0;
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
	sprintf(log_spooler.NomeDB, "Import IMSI WL");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	/* tipo operazione */
	if (( (wrk_str = cgi_param( "TIPO" ) ) != NULL ) && (strlen(wrk_str) > 0))
		cTipo =  wrk_str[0];


	//-------------------- FILE di INPUT --------------------------
	if (( (wrk_str = cgi_param( "FILE_INPUT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(FileInput, wrk_str);

	//-------------------- Flag DB da utilizzare --------------------------
	nGSM = 0;
	nDAT = 0;
	//nLTE = 0;
	if ( (wrk_str = cgi_param( "DB_GSM" ) ) != NULL )
		nGSM = 1;
	if ( (wrk_str = cgi_param( "DB_DAT" ) ) != NULL )
		nDAT = 1;
	//if ( (wrk_str = cgi_param( "DB_LTE" ) ) != NULL )
	//	nLTE = 1;


    /****************************************
	* Apro i file
	*****************************************/
	if( nGSM )
	{
		rc = Apri_File(acFileImsiGsm, &handleGsm, 1, 0);
		if(rc)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiGsm);
		else
		{
			rc = Apri_File(acFileImsiGsm_E_Loc, &handleGsm_loc, 1, 0);
			if(rc)
				log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiGsm_E_Loc);
			else
			{
				rc = Apri_File(acFileImsiGsm_E_Rem, &handleGsm_rem, 1, 0);
				if(rc)
					log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiGsm_E_Rem);
			}
		}
	}

	if( rc == 0 && nDAT )
	{
		rc = Apri_File(acFileImsiDat, &handleDat, 1, 0);
		if(rc)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiDat);
		else
		{
			rc = Apri_File(acFileImsiDat_E_Loc, &handleDat_loc, 1, 0);
			if(rc)
				log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiDat_E_Loc);
			else
			{
				rc = Apri_File(acFileImsiDat_E_Rem, &handleDat_rem, 1, 0);
				if(rc)
					log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiDat_E_Rem);
			}
		}
	}

	// commentato 10-01-2017
	/*if(rc == 0 && nLTE )
		rc = Apri_File(acFileImsiLte, &handleLte, 1, 0);
	if (rc != 0)
		log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImsiLte);*/

	if (rc == 0)
	{
		if ( strcmp(sOperazione, "DISPLAY") == 0 )
		{
			Display_TOP("IMPORT/DELETE IMSI into/from White List");
			Display_File();
		}
		else if ( strcmp(sOperazione, "UPDATE") == 0 )
		{
			if(cTipo == 'I')
			{
				Display_TOP("IMPORT IMSI into White List");
				log(LOG_INFO, "%s;%s; IMPORT IMSI into White List",gUtente, gIP);
			}
			else
			{
				Display_TOP("DELETE IMSI from White List");
				log(LOG_INFO, "%s;%s; DELETE IMSI from White List",gUtente, gIP);
			}

			/****************************************
			* apre il file  input               
			****************************************/
			if ((hIn = fopen(FileInput, "r")) == NULL)
			{
				/* avvisa dell'errore */
				printf("fopen %s: error %d\n\n", FileInput, errno);
				log(LOG_ERROR, "%s;%s; Error in opening file %s : code %d",gUtente, gIP, FileInput, errno);
				rc = 1;
			}

			if (rc == 0)
			{
				printf("<center><br><br>\n\
					    <span id='wait1'>\n\
						 <IMG SRC='images/loading.gif' BORDER=0 ALT=''>\n\
						 </span></center>\n");
				fflush(stdout);

				while (!feof(hIn) && rc == 0)
				{
					memset (sLetti, 0x00, sizeof (sLetti));

					/* legge una riga fino allo \n */
					fgets(sLetti, 300, hIn);
					if( ferror(hIn))
					{
						printf("<BR><center><font color=red>Invalid File</font></center>");
						rc =1;
						break;
					}

					if (sLetti[0] != '\0')
					{
						// prendo la prima parte della stringa fino al ';'
						pTmp= strtok(sLetti, "\r\n");
						if(pTmp)
						{
							memset (sTmp, 0x00, sizeof (sTmp));
							sprintf(sTmp, "%s", pTmp);
							log(LOG_INFO, "%s;%s; lenght imsi (%d)",gUtente, gIP, strlen(sTmp));

							if( strlen(sTmp) != 15)
							{
								GSM_RecScartato ++;
								log(LOG_INFO, "%s;%s; GSM_RecScartato:%d",gUtente, gIP,GSM_RecScartato);
							}
							else
							{
								if(cTipo == 'I')
								{
									if( nGSM )
									{
										RecAgg = 0;
										RecUpd = 0;
										rc = ScriviImsi(handleGsm, sTmp);  // GSM MBE
										GSM_RecAgg += RecAgg;
										GSM_RecUpd += RecUpd;
										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = ScriviImsi(handleGsm_loc, sTmp);  // GSM Enscribe Locale
											GSM_Loc_RecAgg += RecAgg;
											GSM_Loc_RecUpd += RecUpd;
										}

										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = ScriviImsi(handleGsm_rem, sTmp);  // GSM Enscribe Remoto
											GSM_Rem_RecAgg += RecAgg;
											GSM_Rem_RecUpd += RecUpd;
										}
									}
									if( nDAT )
									{
										RecAgg = 0;
										RecUpd = 0;
										rc = ScriviImsi(handleDat, sTmp);	// DAT MBE
										DAT_RecAgg += RecAgg;
										DAT_RecUpd += RecUpd;
										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = ScriviImsi(handleDat_loc, sTmp);	//DAT Enscribe Locale
											DAT_Loc_RecAgg += RecAgg;
											DAT_Loc_RecUpd += RecUpd;
										}

										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = ScriviImsi(handleDat_rem, sTmp);	 // GSM Enscribe Remoto
											DAT_Rem_RecAgg += RecAgg;
											DAT_Rem_RecUpd += RecUpd;
										}
									}
								}
								else if(cTipo == 'D')	// ******** DELETE **************
								{
									if( nGSM )
									{
										RecAgg = 0;
										RecUpd = 0;
										rc = DeleteImsi(handleGsm, sTmp);
										GSM_RecAgg += RecAgg; // rec non trovato
										GSM_RecUpd += RecUpd; // rec in white
										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = DeleteImsi(handleGsm_loc, sTmp);  // GSM Enscribe Locale
											GSM_Loc_RecAgg += RecAgg;
											GSM_Loc_RecUpd += RecUpd;
										}

										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = DeleteImsi(handleGsm_rem, sTmp);	 // GSM Enscribe Remoto
											GSM_Rem_RecAgg += RecAgg;
											GSM_Rem_RecUpd += RecUpd;
										}
									}
									if( nDAT )
									{
										RecAgg = 0;
										RecUpd = 0;
										rc = DeleteImsi(handleDat, sTmp);
										DAT_RecAgg += RecAgg; // rec non trovato
										DAT_RecUpd += RecUpd; // rec in white L
										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = DeleteImsi(handleDat_loc, sTmp);	//DAT Enscribe Locale
											DAT_Loc_RecAgg += RecAgg;
											DAT_Loc_RecUpd += RecUpd;
										}

										if (!rc)
										{
											RecAgg = 0;
											RecUpd = 0;
											rc = DeleteImsi(handleDat_rem, sTmp);	 // GSM Enscribe Remoto
											DAT_Rem_RecAgg += RecAgg;
											DAT_Rem_RecUpd += RecUpd;
										}
									}
								}
							}
						}
					} // fine if sletti
				}//fine while
				fclose(hIn);
			}

			printf("<SCRIPT LANGUAGE='JavaScript'>\n\
						togliegif('wait1', 0);\n\
					</SCRIPT>");
			
			if(rc == 0)
			{
				printf("<center>");
				printf("Input File [%s] ", FileInput);
				printf("<BR><BR><BR>\n");
				if(GSM_RecScartato > 0)
				{
					printf("<pre><font color=red>Imsi discarded: %d (length different from 15)</font></pre>\n",GSM_RecScartato );
					printf("<BR><BR>\n");
				}

				if(cTipo == 'I')
				{
					if( nGSM )
					{
						printf("  <DIV style='background-color:#aeafb3'>");
						printf("  <br><b><font color='blue'>White List - GSM - </font></b>");
						printf("<pre>");
						printf("       Imsi inserted in <b>MBE DB</b>: %ld<br>", GSM_RecAgg);
						printf("Imsi already present in <b>MBE DB</b>: %ld</pre><br>", GSM_RecUpd);
						printf("<pre>");
						printf("       Imsi inserted in <b>Enscribe Local DB</b>: %ld<br>", GSM_Loc_RecAgg);
						printf("Imsi already present in <b>Enscribe Local DB</b>: %ld</pre><br>", GSM_Loc_RecUpd);
						printf("<pre>");
						printf("       Imsi inserted in <b>Enscribe Remote DB</b>: %ld<br>", GSM_Rem_RecAgg);
						printf("Imsi already present in <b>Enscribe Remote DB</b>: %ld</pre>", GSM_Rem_RecUpd);
						printf("<br></DIV>");
						printf("<br>");
					}

					if( nDAT )
					{
						printf(" <DIV style='background-color:#c0c0c0'>");
						printf("  <br><b><font color='blue'>White List - DAT - </font></b>");
						printf("<pre>");
						printf("       Imsi inserted in <b>MBE DB</b>: %ld<br>", DAT_RecAgg);
						printf("Imsi already present in <b>MBE DB</b>: %ld</pre><br>", DAT_RecUpd);
						printf("<pre>");
						printf("       Imsi inserted in <b>Enscribe Local DB</b>: %ld<br>", DAT_Loc_RecAgg);
						printf("Imsi already present in <b>Enscribe Local DB</b>: %ld</pre><br>", DAT_Loc_RecUpd);
						printf("<pre>");
						printf("       Imsi inserted in <b>Enscribe Remote DB</b>: %ld<br>", DAT_Rem_RecAgg);
						printf("Imsi already present in <b>Enscribe Remote DB</b>: %ld</pre>", DAT_Rem_RecUpd);
						printf("<br></DIV>");
					}

					log(LOG_INFO, "%s;%s; Input file %s imported correctly",gUtente, gIP, FileInput);
					log(LOG_INFO, "%s;%s; Rec insert GSM: %ld MBE - %ld Enscribe Local - %ld Enscribe Remote",gUtente, gIP, GSM_RecAgg, GSM_Loc_RecAgg, GSM_Rem_RecAgg);
					log(LOG_INFO, "%s;%s; Rec insert DAT: %ld MBE - %ld Enscribe Local - %ld Enscribe Remote",gUtente, gIP, DAT_RecAgg, DAT_Loc_RecAgg, DAT_Rem_RecAgg);
				}
				else if(cTipo == 'D')
				{

					if( nGSM )
					{
						printf("  <DIV style='background-color:#aeafb3'>");
						printf("  <br><b><font color='blue'>White List - GSM - </font></b>");
						printf("<pre>");
						printf("   Imsi deleted in <b>MBE DB</b>: %ld<br>", GSM_RecUpd);
						printf(" Imsi NOT found in <b>MBE DB</b>: %ld</pre><br>", GSM_RecAgg);
						printf("<pre>");
						printf("   Imsi deleted in <b>Enscribe Local DB</b>: %ld<br>", GSM_Loc_RecUpd);
						printf(" Imsi NOT found in <b>Enscribe Local DB</b>: %ld</pre><br>", GSM_Loc_RecAgg);
						printf("<pre>");
						printf("   Imsi deleted in <b>Enscribe Remote DB</b>: %ld<br>", GSM_Rem_RecUpd);
						printf(" Imsi NOT found in <b>Enscribe Remote DB</b>: %ld</pre>", GSM_Rem_RecAgg);
						printf("<br></DIV>");
						printf("<br>");
					}

					if( nDAT )
					{
						printf(" <DIV style='background-color:#c0c0c0'>");
						printf("  <br><b><font color='blue'>White List - DAT - </font></b>");
						printf("<pre>");
						printf("   Imsi deleted in <b>MBE DB</b>: %ld<br>", DAT_RecUpd);
						printf(" Imsi NOT found in <b>MBE DB</b>: %ld</pre><br>", DAT_RecAgg);
						printf("<pre>");
						printf("   Imsi deleted in <b>Enscribe Local DB</b>: %ld<br>", DAT_Loc_RecUpd);
						printf(" Imsi NOT found in <b>Enscribe Local DB</b>: %ld</pre><br>", DAT_Loc_RecAgg);
						printf("<pre>");
						printf("   Imsi deleted in <b>Enscribe Remote DB</b>: %ld<br>", DAT_Rem_RecUpd);
						printf(" Imsi NOT found in <b>Enscribe Remote DB</b>: %ld</pre>", DAT_Rem_RecAgg);
						printf("<br></DIV>");
					}
					log(LOG_INFO, "%s;%s; Input file %s imported correctly",gUtente, gIP, FileInput);
					log(LOG_INFO, "%s;%s; # of imsi deleted from White List GSM: %ld MBE - %ld Enscribe Local - %ld Enscribe Remote",gUtente, gIP, GSM_RecUpd, GSM_Loc_RecUpd, GSM_Rem_RecUpd);
					log(LOG_INFO, "%s;%s; # of imsi deleted from White List DAT: %ld MBE - %ld Enscribe Local - %ld Enscribe Remote",gUtente, gIP, DAT_RecUpd, DAT_Loc_RecUpd, DAT_Rem_RecUpd);
				}

				printf("<BR><BR>\n");
				printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='OK' \
							onclick=\"javascript:location='%s'\" >\n",	gName_cgi);
			}
		}

		MBE_FILE_CLOSE_(handleGsm);
		MBE_FILE_CLOSE_(handleDat);
		MBE_FILE_CLOSE_(handleGsm_loc);
		MBE_FILE_CLOSE_(handleGsm_rem);
		MBE_FILE_CLOSE_(handleDat_loc);
		MBE_FILE_CLOSE_(handleDat_rem);

		//MBE_FILE_CLOSE_(handleLte);

		/*------------------------------*/
		/* LOG SICUREZZA				*/
		/*------------------------------*/
		sprintf(log_spooler.ParametriRichiesta, "");
		strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
		if(!rc)
			LOGResult = SLOG_OK;
		else
			LOGResult = SLOG_ERROR;

		log_spooler.EsitoRichiesta = LOGResult;
		Log2Spooler(&log_spooler, EVT_ON_ERROR);

			
		printf("</center>");
		Display_BOTTOM();
	}

	log_close();
}


//*****************************************************************************************
void Display_File()
{
	printf("<center><br><br>");
	printf("<P><FORM METHOD=POST ACTION='%s' NAME='inputform' onsubmit=\"return conferma_BL()\">\n\
					<INPUT TYPE='hidden' name='OPERATION' value='UPDATE' >\n", gName_cgi);
	printf("<TABLE border=0 align='center'  >\n\
					<TR><TD><B>Input File:</td>\n\
					<TD></B><INPUT TYPE='text' NAME='FILE_INPUT' size='50' maxlength ='50'></TD>\n\
					<TR><TD>&nbsp;</td>\n\
					<td>OSS Pathname(es:/G/volume/subvol/file name)</td></tr></TABLE></P>");
	printf("<BR>\n");
	printf("Insert <INPUT TYPE='radio' NAME='TIPO' VALUE='I' checked>");
	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	printf("Delete <INPUT TYPE='radio' NAME='TIPO' VALUE='D'>");

	printf("<BR><BR>\n");
	printf("IMSI GSM <INPUT TYPE='checkbox' NAME='DB_GSM' checked>");
	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
	printf("IMSI DAT <INPUT TYPE='checkbox' NAME='DB_DAT' checked>");
//	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");
//	printf("IMSI LTE <INPUT TYPE='checkbox' NAME='DB_LTE' checked>");
	printf("<BR><BR><BR><BR>\n");
	printf("<input type='submit'  icon='ui-icon-check'  value='Confirm' >\n");
	printf("</form>\n");
			

}

//************************************************************************************
short ScriviImsi(short handle, char *ac_ImsiDritto)
{
	short		rc = 0;
	char		sTmp[500];
	char		str[20];
	char		ac_Imsi[20];

	t_ts_imsi_record record_imsi;
	t_ts_imsi_record record_appo;

	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));
	memset(sTmp, 0, sizeof(sTmp));
	memset(ac_Imsi, 0, sizeof(ac_Imsi));
	memset(str, ' ', sizeof(str));

	// giro l'Imsi
	AlltrimString(ac_ImsiDritto);
	Reverse(ac_ImsiDritto, ac_Imsi);

	memcpy(record_imsi.imsi, ac_Imsi, strlen(ac_Imsi));

	record_imsi.timestamp = JULIANTIMESTAMP(0);
	record_imsi.status = '1';

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, record_imsi.imsi, (short)sizeof(record_imsi.imsi), 0, 2);
	
	/* errore */
	if (rc != 0)
	{
		printf( "IMSI %s - Error File_setkey (%d)\n", ac_ImsiDritto, rc);
		log(LOG_ERROR, "%s;%s; Error (%d) in reading file  ",gUtente, gIP, rc);
	}

	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handle, (char *) &record_appo, (short) sizeof(t_ts_imsi_record) );
		/* errore... */
		if ( rc)
		{
			if ( rc == 1 ) //record non presente lo inserisco
			{
				// Init ts for registration time logging
				record_imsi.init_ts_op = 0;

				rc = MBE_WRITEX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
				/* errore */         
				if (rc)
				{
					printf("Error (%d) in writing file  - IMSI [%s] \n", rc, ac_ImsiDritto);
					log(LOG_ERROR, "%s;%s; Error (%d) in writing file  - IMSI: [%s]",gUtente, gIP,
							rc, ac_ImsiDritto);
				}
				else
					RecAgg++;
			}
			else
			{
				printf("Error (%d) in reading file - IMSI [%s] \n", rc,  ac_ImsiDritto);
				log(LOG_ERROR, "%s;%s; Error (%d) in reading file",gUtente, gIP, rc);
			}
		}
		else
		{
			// record presente controllo se era già in white
			if (record_appo.status == '1')
				RecUpd++;
			else
			{
				//aggiorno il record lo considero come record inserito (RecAgg +1)
				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_imsi, (short) sizeof(t_ts_imsi_record) );
				if(rc)
				{
					printf("Error (%d) in writing file- IMSI [%s] \n", rc, ac_ImsiDritto);
					log(LOG_ERROR, "%s;%s; Error (%d) in writing file ",gUtente, gIP, rc);
					MBE_UNLOCKREC(handle);
				}
				else
					RecAgg++;
			}
		}
	}

	return(rc);
}

//************************************************************************************
short DeleteImsi(short handle, char *ac_ImsiDritto)
{
	short		rc = 0;
	char		sTmp[500];
	char		ac_Imsi[20];

	t_ts_imsi_record record_imsi;
	t_ts_imsi_record record_appo;
	
	/* inizializza la struttura tutta a blank */
	memset(&record_imsi, ' ', sizeof(t_ts_imsi_record));

	memset(sTmp, 0, sizeof(sTmp));
	memset(ac_Imsi, 0, sizeof(ac_Imsi));

	// giro l'Imsi
	AlltrimString(ac_ImsiDritto);
	Reverse(ac_ImsiDritto, ac_Imsi);

	memcpy(record_imsi.imsi, ac_Imsi, strlen(ac_Imsi));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, record_imsi.imsi, (short)sizeof(record_imsi.imsi), 0, 2);
	/* errore */
	if (rc != 0)
	{
		printf( "IMSI %s - Error File_setkey (%d) \n", ac_ImsiDritto, rc);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handle, (char *) &record_appo, (short) sizeof(t_ts_imsi_record) );
		/* errore... */
		if ( rc)
		{
			if ( rc == 1 ) //record non presente 
			{
				RecAgg++;
				rc = 0;
			}
			else
			{
				printf("Error (%d) in reading file  - IMSI [%s] \n", rc,  ac_ImsiDritto);
			}
		}
		else
		{
			// record presente controllo se è in white
			if (record_appo.status == '1')
			{
				//lo cancello
				rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_imsi, 0 );
				if(rc)
				{
					printf("Error (%d) in writing file - IMSI [%s] \n", rc,  ac_ImsiDritto);
					MBE_UNLOCKREC(handle);
				}
				else
					RecUpd++;
			}
		}
	}

	return(rc);
}


