/*----------------------------------------------------------------------------
*   PROGETTO : Importa GTT
*-----------------------------------------------------------------------------
*
*   File Name       : importaGTT
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Importa GTT
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
#include <cextdecs.h (JULIANTIMESTAMP)>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ssplog.h"
#include "sspfunc.h"

long	RecAgg;
char	cTipo;

du_impianti_rec_def impianti_rec;
du_mgt_rec_def mgt_rec;
du_mgtr_rec_def mgt_rec_r;


void  Display_File();
short ScriviImpianti(short handleImp, short handleImp_rem, char sRiga[2048]);
short ScriviMGT_Prefix(short handleMGT, short handleMGT_rem, char sRiga[2048]);
short ScriviMGT_Range(short handleMGT, short handleMGT_rem, char sRiga[2048]);


/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	int		rc = 0;
	short	handleImp = -1;
	short	handleImp_rem = -1;
	short	handleMGT = -1;
	short	handleMGT_rem = -1;
	char	sRiga[2048];
	FILE	*hIn;
	char	sTmp[500];
	char 	ac_err_msg[255];
    short 	rcSes;

	RecAgg = 0;
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
	sprintf(log_spooler.NomeDB, "GTT import");	// max 20 char

	Lettura_FileIni();

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);

	/* tipo operazione */
	if (( (wrk_str = cgi_param( "TIPO_GTT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		cTipo =  wrk_str[0];


    /****************************************
	* Apro il file 
	*****************************************/
	if( cTipo == 'N' ) //Nodes
	{
		rc = Apri_File(acFileImpianti, &handleImp, 1, 0);
		if (rc != 0)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImpianti);
		else
			rc = Apri_File(acFileImpianti_Rem, &handleImp_rem, 1, 0);
		if (rc != 0)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileImpianti_Rem);
	}
	if( cTipo == 'M' ) //MGT
	{
		rc = Apri_File(acFileMGT, &handleMGT, 1, 2);
		if (rc != 0)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileMGT);
		else
			rc = Apri_File(acFileMGT_Rem, &handleMGT_rem, 1, 0);
		if (rc != 0)
			log(LOG_ERROR, "%s;%s; Failed to open file [%s]  ",gUtente, gIP, acFileMGT_Rem);
	}

	if (rc == 0)
	{
		if ( strcmp(sOperazione, "DISPLAY") == 0 )
		{
			Display_TOP("IMPORT GTT");
			Display_File();
		}
		else if ( strcmp(sOperazione, "UPDATE") == 0 )
		{
			/*------------------------------*/
			/* LOG SICUREZZA				*/
			/*------------------------------*/
			sprintf(log_spooler.ParametriRichiesta, "");
			strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
			LOGResult = SLOG_OK;

			//-------------------- FILE di INPUT --------------------------
			if (( (wrk_str = cgi_param( "FILE_INPUT" ) ) != NULL ) && (strlen(wrk_str) > 0))
				strcpy(FileInput, wrk_str);
			else
			{
				Display_Message(-1, "", "FILE_INPUT");
				return (0);
			}

			if(cTipo == 'N')
			{
				Display_TOP("Import Network Nodes");
				log(LOG_INFO, "%s;%s; Import Network Nodes",gUtente, gIP);
			}
			else if(cTipo == 'M' && s_mgt_by_range == 0)
			{
				Display_TOP("Import MGT prefix ");
				log(LOG_INFO, "%s;%s; Import MGT prefix",gUtente, gIP);
			}
			else if(cTipo == 'M' && s_mgt_by_range == 1)
			{
				Display_TOP("Import MGT range ");
				log(LOG_INFO, "%s;%s; Import MGT range",gUtente, gIP);
			}

			/****************************************
			* apre il file  input               
			****************************************/
			if ((hIn = fopen(FileInput, "r")) == NULL)
			{
				/* avvisa dell'errore */
				printf("<center>fopen %s: error %d\n\n", FileInput, errno);
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
				RecAgg = 0;

				printf("<center><textarea wrap='PHYSICAL' cols='120' rows='18' name='TESTO' class='txtarea'>");

				while (!feof(hIn) && rc == 0)
				{
					memset (sRiga, 0x00, sizeof (sRiga));

	               /* legge una riga fino allo \n */
		            fgets (sRiga, 2048, hIn);
					if( ferror(hIn))
					{
						printf("Invalid File [%s]", FileInput);
						rc =1;
						break;
					}

					if (sRiga[0] != '\0')
					{
						if(cTipo == 'N')
							rc = ScriviImpianti(handleImp, handleImp_rem, sRiga);
						else if(cTipo == 'M' && s_mgt_by_range == 0)
							rc = ScriviMGT_Prefix(handleMGT, handleMGT_rem, sRiga);
						else if(cTipo == 'M' && s_mgt_by_range == 1)
							rc = ScriviMGT_Range(handleMGT, handleMGT_rem, sRiga);
					}
				}//fine while
				fclose(hIn);
				printf("</textarea>");
			}
			else
				LOGResult = SLOG_ERROR;

			/*------------------------------*/
			/* LOG SICUREZZA				*/
			/*------------------------------*/
			log_spooler.EsitoRichiesta = LOGResult;
			Log2Spooler(&log_spooler, EVT_ON_ERROR);

			printf("<SCRIPT LANGUAGE='JavaScript'>\n\
						togliegif('wait1', 0);\n\
					</SCRIPT>");

			log(LOG_INFO, "%s;%s; Input file %s imported correctly",gUtente, gIP, FileInput);
			log(LOG_INFO, "%s;%s; %ld record inserted",gUtente, gIP, RecAgg);
			
			printf("<BR>\n");
			printf("<BR>Imported <B>%d</B> record(s) from input file [%s]", RecAgg, FileInput);
			printf("<BR><BR>\n");

			printf("<INPUT TYPE='button' icon='ui-icon-home'  VALUE='OK' \
						onclick=\"javascript:location='%s'\" >\n",	gName_cgi);

			printf("</center>");
		}

		MBE_FILE_CLOSE_(handleImp);
		MBE_FILE_CLOSE_(handleImp_rem);
		MBE_FILE_CLOSE_(handleMGT);
		MBE_FILE_CLOSE_(handleMGT_rem);
			
		Display_BOTTOM();
	}

	log_close();

}


//*****************************************************************************************
void Display_File()
{
	printf("<center><br><br>");
	printf("<P><FORM METHOD=POST ACTION='%s' NAME='inputform' onsubmit=\"return conferma_Imp()\">\n\
					<INPUT TYPE='hidden' name='OPERATION' value='UPDATE' >\n", gName_cgi);
	printf("<TABLE border=0 align='center'  >\n\
					<TR><TD><B>Input File:</td>\n\
					<TD></B><INPUT TYPE='text' NAME='FILE_INPUT' size='70' maxlength ='1490'></TD>\n\
					<TR><TD>&nbsp;</td>\n\
					<td>OSS Pathname(es:/G/volume/subvol/file name)</td></tr></TABLE></P>");
	printf("<BR>\n");
	printf("Nodes <INPUT TYPE='radio' NAME='TIPO_GTT' VALUE='N' checked>");
	printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n");

	if(s_mgt_by_range == 0)
		printf("MGT (Prefix)");
	else
		printf("MGT (Range)");
	printf("<INPUT TYPE='radio' NAME='TIPO_GTT' VALUE='M'>");

	printf("<BR><BR>\n");
	printf("<input type='submit'  icon='ui-icon-check' value='Confirm' >\n");
	printf("</form>\n");

}

//************************************************************************************
short ScriviImpianti(short handleImp, short handleImp_rem, char sRiga[2048])
{
	char	*token;
	short	cc;
	short	counter;
	char	sRiga_backup[2049];
	
	memset( &impianti_rec, 0x20, sizeof(du_impianti_rec_def) );
	impianti_rec.primarykey.pcf = 2;
	impianti_rec.insertts = JULIANTIMESTAMP(0);
	impianti_rec.lastupdatets = impianti_rec.insertts;
	counter=1;
	cc=0;

	strcpy(sRiga_backup, sRiga);

	/* recupera le informazioni che necessitano */
	token = strtok(sRiga, ";");
	while (token != NULL)
	{
		switch (counter)
		{
			case 1:
				if (strlen(token) <= 8)
					memcpy( impianti_rec.short_desc, token, strlen(token) );
				else
					memcpy( impianti_rec.short_desc, token, 8 );
				cc++;
				break;

			case 2:
				if (strlen(token) <= 16)
					memcpy( impianti_rec.gt, token, strlen(token) );
				else
					memcpy( impianti_rec.gt, token, 16 );
				cc++;
				break;

			case 4:
				if (strlen(token) <= 30)
					memcpy( impianti_rec.description, token, strlen(token) );
				else
					memcpy( impianti_rec.description, token, 30 );
				cc++;
				break;

			case 7:
				impianti_rec.primarykey.pc = (short)atoi(token);
				cc++;
				break;

			case 10:
				impianti_rec.ssn_1 = (short)atoi(token);
				cc++;
				break;

			case 11:	// optional, default 2
				impianti_rec.primarykey.pcf = (short)atoi(token);
				break;
		}
		counter++;

		token = strtok(NULL, ";");
	}

	/* se ha trovato tutti i campi */
	if (cc == 5)
	{
		/* aggiunge il record */
		cc = MBE_WRITEX( handleImp, (char *)&impianti_rec, sizeof(du_impianti_rec_def) );
		/* se l'operazione è andata male */
		if (cc != 0)
		{
			if(cc == 10)
			{
				printf ("*** WARNING: record PCF[%d] PC[%d] already exist in Local DB[%s].\n",
						impianti_rec.primarykey.pcf, impianti_rec.primarykey.pc, acFileImpianti);
				log(LOG_INFO, "%s;%s; record PCF[%d] PC[%d] already exist in Local DB",gUtente, gIP,
						impianti_rec.primarykey.pcf, impianti_rec.primarykey.pc);
				cc = 0; //continua
			}
			else
			{
				printf ("*** ERROR (%d) writing Local DB[%s]\n", cc, acFileImpianti);
				log(LOG_ERROR, "%s;%s; ERROR (%d) writing Local DB[%s]",gUtente, gIP,
						cc, acFileImpianti);
			}
		}
		else
		{
			// ******************   SCRIVO DB REMOTO  **************************************************
			cc = MBE_WRITEX( handleImp_rem, (char *)&impianti_rec, sizeof(du_impianti_rec_def) );
			/* se l'operazione è andata male */
			if (cc != 0)
			{
				if(cc == 10)
				{
					printf ("*** WARNING: record PCF[%d] PC[%d] already exist in Remote DB[%s].	\n",
							impianti_rec.primarykey.pcf, impianti_rec.primarykey.pc, acFileImpianti_Rem);
					log(LOG_INFO, "%s;%s; record PCF[%d] PC[%d] already exist in Remote DB",gUtente, gIP,
							impianti_rec.primarykey.pcf, impianti_rec.primarykey.pc);
					cc = 0; //continua
				}
				else
				{
					printf ("*** ERROR (%d) writing Remote DB[%s]\n", cc, acFileImpianti_Rem);
					log(LOG_ERROR, "%s;%s; ERROR (%d) writing Remote DB[%s]",gUtente, gIP,
							cc, acFileImpianti_Rem);
				}
			}
			else
				RecAgg++;
		}
	}
	else
	{
		printf ("*** ERROR Invalid record [%s] \n", sRiga_backup);
		log(LOG_ERROR, "%s;%s; Invalid record",gUtente, gIP);
		cc = 1;
	}

	return(cc);
}
/***************************************************************************************************/
short ScriviMGT_Prefix(short handleMGT, short handleMGT_rem, char sRiga[2048])
{
	char	*token;
	short	counter;
	short	cc;
	char	sRiga_backup[2049];

	memset( &mgt_rec, 0x20,  sizeof(du_mgt_rec_def) );
	mgt_rec.c_dual_imsi = 0;
	mgt_rec.insertts = JULIANTIMESTAMP(0);
	mgt_rec.lastupdatets = mgt_rec.insertts;
	counter=1;
	cc=0;

	strcpy(sRiga_backup, sRiga);

    /* recupera le informazioni che necessitano */
	token = strtok(sRiga, ";");
	while (token != NULL)
	{
		switch (counter)
		{
			case 2:
				if (strlen(token) <= 16)
					memcpy( mgt_rec.mgt, token, strlen(token) );
				else
					memcpy( mgt_rec.mgt, token, 16 );
				cc++;
				break;

			case 3:
				mgt_rec.alternatekey.pc = (short)atoi(token);
				cc++;
				break;

			case 4:
				mgt_rec.alternatekey.pcf = (short)atoi(token);
				cc++;
				break;

			case 5:
				if (atoi(token))
					mgt_rec.c_dual_imsi = 1;
				break;
		}
		counter++;

		token = strtok(NULL, ";");
	}

	/* se ha trovato tutti i campi */
	if (cc == 3)
	{
		/* aggiunge il record */
		cc = MBE_WRITEX( handleMGT, (char *)&mgt_rec, sizeof(du_mgt_rec_def) );
		/* se l'operazione è andata male */
		if (cc != 0)
		{
			if(cc == 10)
			{
				printf ("*** WARNING: record MGT[%s] already exist in Local DB[%s].\n",
						GetStringNT(mgt_rec.mgt, 16), acFileMGT);
				log(LOG_INFO, "%s;%s; record MGT[%s] already exist in Local DB",gUtente, gIP,
						GetStringNT(mgt_rec.mgt, 16));
				cc = 0; //continua
			}
			else
			{
				printf ("*** ERROR (%d) writing Local DB[%s]\n", cc, acFileMGT);
				log(LOG_ERROR, "%s;%s; ERROR (%d) writing Local DB[%s]",gUtente, gIP,
						cc, acFileMGT);
			}
		}
		else
		{
			// ******************   SCRIVO DB REMOTO  **************************************************
			cc = MBE_WRITEX( handleMGT_rem, (char *)&mgt_rec, sizeof(du_mgt_rec_def) );
			/* se l'operazione è andata male */
			if (cc != 0)
			{
				if(cc == 10)
				{
					printf ("***  WARNING: record MGT[%s] already exist in Remote DB[%s].\n",
						GetStringNT(mgt_rec.mgt, 16), acFileMGT_Rem);
					log(LOG_INFO, "%s;%s; record MGT[%s] already exist in Local DB",gUtente, gIP,
							GetStringNT(mgt_rec.mgt, 16));
					cc = 0; //continua
				}
				else
				{
					printf ("*** ERROR (%d) writing Remote DB[%s]\n", cc, acFileMGT_Rem);
					log(LOG_ERROR, "%s;%s; ERROR (%d) writing Remote DB[%s]",gUtente, gIP,
							cc, acFileMGT_Rem);
				}
			}
			else
				RecAgg++;
		}
	}
	else
	{
		printf ("*** ERROR Invalid record [%s] \n", sRiga_backup);
		log(LOG_ERROR, "%s;%s; Invalid record",gUtente, gIP);
		cc = 1;
	}

	return(cc);
}

/**********************************************************************************************/
short ScriviMGT_Range(short handleMGT, short handleMGT_rem, char sRiga[2048])
{
	char	*token;
	short	cc;
	short	counter;
	char	sRiga_backup[2049];

	memset( &mgt_rec_r, 0x20,  sizeof(du_mgtr_rec_def) );
	mgt_rec_r.c_dual_imsi = 0;
	mgt_rec_r.insertts = JULIANTIMESTAMP(0);
	mgt_rec_r.lastupdatets = mgt_rec_r.insertts;
	counter=1;
	cc=0;
	strcpy(sRiga_backup, sRiga);

 	/* due volte per eventuali OD OA */
	if (sRiga[strlen(sRiga)-1] == '\n' || sRiga[strlen(sRiga)-1] == '\r')
		sRiga[strlen(sRiga)-1] = 0;

	if (sRiga[strlen(sRiga)-1] == '\n' || sRiga[strlen(sRiga)-1] == '\r')
		sRiga[strlen(sRiga)-1] = 0;

	/* recupera le informazioni che necessitano */
	token = strtok(sRiga, ";");
	while (token != NULL)
	{
		switch (counter)
		{
			case 2:
				if (strlen(token) <= 16)
				{
					memcpy( mgt_rec_r.mgt_ini, token, strlen(token) );
					mgt_rec_r.mgt_length = (short)strlen(token);
				}
				else
					memcpy( mgt_rec_r.mgt_ini, token, 16 );
				cc++;
				break;

			case 3:
				if (strlen(token) <= 16)
					memcpy( mgt_rec_r.mgt_end, token, strlen(token) );
				else
					memcpy( mgt_rec_r.mgt_end, token, 16 );
				cc++;
				break;

			case 4:
				mgt_rec_r.alternatekey.pc = (short)atoi(token);
				cc++;
				break;

			case 5:
				mgt_rec_r.alternatekey.pcf = (short)atoi(token);
				cc++;
				break;

			case 6:
				if (atoi(token))
					mgt_rec_r.c_dual_imsi = 1;
				break;
		}
		counter++;

		token = strtok(NULL, ";");
	}

	/* se ha trovato tutti i campi */
	if (cc == 4)
	{
		/* aggiunge il record */
		cc = MBE_WRITEX( handleMGT, (char *)&mgt_rec_r, sizeof(du_mgtr_rec_def) );
		/* se l'operazione è andata male */
		if (cc != 0)
		{
			if(cc == 10)
			{
				printf ("*** WARNING: record MGT[%s] already exist in Local DB[%s].	\n",
						GetStringNT(mgt_rec_r.mgt_ini, 16), acFileMGT);
				log(LOG_INFO, "%s;%s; record MGT[%s] already exist in Local DB",gUtente, gIP,
						GetStringNT(mgt_rec_r.mgt_ini, 16));
				cc = 0; //continua
			}
			else
			{
				printf ("*** ERROR (%d) writing Local DB[%s]\n", cc, acFileMGT);
				log(LOG_ERROR, "%s;%s; ERROR (%d) writing Local DB[%s]",gUtente, gIP,
						cc, acFileMGT);
			}
		}
		else
		{
			// ******************   SCRIVO DB REMOTO  **************************************************
			cc = MBE_WRITEX( handleMGT_rem, (char *)&mgt_rec_r, sizeof(du_mgtr_rec_def) );
			/* se l'operazione è andata male */
			if (cc != 0)
			{
				if(cc == 10)
				{
					printf ("***  WARNING: record MGT[%s] already exist in Remote DB[%s].	\n",
						GetStringNT(mgt_rec_r.mgt_ini, 16), acFileMGT_Rem);
					log(LOG_INFO, "%s;%s; record MGT[%s] already exist in Local DB",gUtente, gIP,
							GetStringNT(mgt_rec_r.mgt_ini, 16));
					cc = 0; //continua
				}
				else
				{
					printf ("*** ERROR (%d) writing Remote DB[%s]\n", cc, acFileMGT_Rem);
					log(LOG_ERROR, "%s;%s; ERROR (%d) writing Remote DB[%s]",gUtente, gIP,
							cc, acFileMGT_Rem);
				}
			}
			else
				RecAgg++;
		}
	}
	else
	{
		printf ("*** ERROR Invalid record [%s] \n", sRiga_backup);
		log(LOG_ERROR, "%s;%s; Invalid record",gUtente, gIP);
		cc = 1;
	}

	return(cc);
}
