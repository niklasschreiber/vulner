/*----------------------------------------------------------------------------
*   PROGETTO : Importa Operatori
*-----------------------------------------------------------------------------
*
*   File Name       : importaOP.c
*   Ultima Modifica : 08/03/2016
*
*------------------------------------------------------------------------------
*   Descrizione
*   Importa Operatori
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
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <usrlib.h>
#include <ctype.h>

#include "cgi.h"
#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "ds.h"
#include "ssplog.h"
#include "sspfunc.h"
#include "mbedb.h"

short		handleOp = -1;
short		handleOP_rem = -1;
short		handleOpGT = -1;
short		handleOpGT_rem = -1;
short		handlePa = -1;
short		handleSogl = -1;
short		handleSogl_rem = -1;
FILE		*hLog;
FILE		*hLogSoglie;
FILE		*hIn;
AVLTREE		listaFileGT;
AVLTREE		listaEcc;
AVLTREE		listaPaesi;
AVLTREE		listaSoglie;
long		RecAgg;
long		RecAggGT;
long		RecUpd;
long		RecDelGT;
long		RecDelOP;
long		RecSoglie;
long		RecSoglieDel; 
short		nDenDB;
//short		gAggiornato;
short		differenze = 0;
short		No_GT;

struct		ImportOP_struct	importOP;
ImportPaesi_struct_def *pImportPaesi;

char	ac_path_log_importa_file[100];
char 	acLogSoglie[100];

void  Display_File();
short Scrivi_Operatore(char *Key);
short Scrivi_OperatoreGT(char *Key);
short Cerca_differenze_inDB(short Tipo);
short Cerca_differenze_inFileI(short tipo);
void  LeggoFilediLog(char *NomeLog, short Tipo);
short Confronta_File_DB(short tipo);
short Cerca_InSoglie(char *ac_Key, short Tipo, short TipoCerca);
short Cerca_InSoglie_2(char *ac_denPA, char *ac_codOP, short Tipo);
short CaricoListaPaesi();
short Del_OP_senza_GT(short Tipo);

extern short Controlla_CarTable();
extern short Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo);
extern short Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
extern void  Trim_inMezzo(char *sTmp, char *sTmp2);
extern short scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation );


/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	short	rc = 0;
	char	sTmp[500];
	char ac_err_msg[255];
    short rcSes;
    int		found;

    disp_Top = 0;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	memset(sOperazione, 0x00, sizeof(sOperazione));
	memset(acFileOperatori_Loc, 0x00, sizeof(acFileOperatori_Loc));
	memset(acFileOperGT_Loc, 0x00, sizeof(acFileOperGT_Loc));
	memset(acFileSoglie_Loc, 0x00, sizeof(acFileSoglie_Loc));
	memset(acFileSoglie_Rem, 0x00, sizeof(acFileSoglie_Rem));
	memset(acFilePaesi_Loc, 0x00, sizeof(acFilePaesi_Loc));
	memset(FileInput, 0x00, sizeof(FileInput));
	memset(acLogSoglie, 0x00, sizeof(acLogSoglie));
	memset(ac_path_log_importa_file, 0x00, sizeof(ac_path_log_importa_file));

	RecAgg = 0;
	RecAggGT = 0;
	RecUpd = 0;
	RecDelGT = 0;
	RecDelOP = 0;
	RecSoglie = 0;
	RecSoglieDel= 0;
//	gAggiornato = 0;

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
	gName_cgi  = getenv( "SCRIPT_NAME" );

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
	sprintf(log_spooler.NomeDB, "Operator import");	// max 20 char

	Lettura_FileIni();

	// ==========================================================================================
	// LOG usati solo qui
	// ==========================================================================================
	get_profile_string(ini_file, "WEB", "LOG-IMPORTA", &found, ac_path_log_importa_file);
	if ((found == SSP_FALSE) || (strlen(ac_path_log_importa_file) == 0))
	{
		sprintf(sTmp, "[WEB] LOG-IMPORTA (foun[%d]  log[%s])", found, ac_path_log_importa_file);
		Display_Message(-1, "", sTmp);
		exit(1);
	}

	get_profile_string(ini_file, "WEB", "LOG-SOGLIE", &found, acLogSoglie);
	if ((found == SSP_FALSE) || (strlen(acLogSoglie) == 0))
	{
		Display_Message(-1, "", "[WEB] LOG-SOGLIE");
		exit(1);
	}

	log_init( ac_path_log_file, ac_log_prefix, i_num_days_of_log);
	log_param(i_trace_level, i_log_option, "");

	/* tipo operazione */
	strcpy(sOperazione, "DISPLAY");	//default
	if (( (wrk_str = cgi_param( "OPERATION" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(sOperazione, wrk_str);


	//-------------------- FILE INPUT --------------------------
	if (( (wrk_str = cgi_param( "FILE_INPUT" ) ) != NULL ) && (strlen(wrk_str) > 0))
		strcpy(FileInput, wrk_str);


    /****************************************
	* Apro il file operatori e paesi e soglie
	*****************************************/
	rc = Apri_File(acFileOperatori_Loc, &handleOp, 1, 0);
	if (rc == 0)
		rc = Apri_File(acFileOperatori_Rem, &handleOP_rem, 1, 0);
	if (rc == 0)
		rc = Apri_File(acFileOperGT_Loc, &handleOpGT, 1, 0);
	if (rc == 0)
		rc = Apri_File(acFileOperGT_Rem, &handleOpGT_rem, 1, 0);
	if (rc == 0)
		rc = Apri_File(acFilePaesi_Loc, &handlePa, 1, 0);
	if (rc == 0)
	{
		/***********************************************************************************
		* IPM KTSTEACS
		* Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
		************************************************************************************/
		//rc = Apri_File(acFileSoglie_Loc, &handleSogl, 1, 2);
		rc = MbeFileOpen_nw(acFileSoglie_Loc, &handleSogl);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error MbeFileOpen_nw file[%s] : %d",gUtente, gIP, acFileSoglie_Loc, rc);
			sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Loc, rc);
			Display_Message(0, "", sTmp);
			return(0);
		}
	}
	if (rc == 0)
	{
		//rc = Apri_File(acFileSoglie_Rem, &handleSogl_rem, 1, 2);
		// ********************* Apro file REMOTO ************************************
		rc = MbeFileOpen_nw(acFileSoglie_Rem, &handleSogl_rem);
		if (rc != 0)
		{
			log(LOG_ERROR, "%s;%s; Error MbeFileOpen_nw file[%s] : %d",gUtente, gIP, acFileSoglie_Rem, rc);
			sprintf(sTmp, "Open error [%s]: error %d", acFileSoglie_Rem, rc);
			Display_Message(0, "", sTmp);
			return(0);
		}
	}
	
	if(rc == 0)
	{
		log(LOG_DEBUG, "%s;%s; Files opened",gUtente, gIP);

		Display_TOP("Log Operators import");

		//carica lista paesi
		CaricoListaPaesi();

		if ( strcmp(sOperazione, "DISPLAY") == 0 )
		{
			Display_File();
		}
		else if ( strcmp(sOperazione, "LOG") == 0 )
		{
			LeggoFilediLog(acLogSoglie, 1);
		}
		else if ( strcmp(sOperazione, "CONFRONTA") == 0 )
		{
			/****************************************
			* apre i file  di log               
			****************************************/
			if ((hLog = fopen(ac_path_log_importa_file, "w")) == NULL)
			{
				/* avvisa dell'errore */
				printf("fopen %s: error %d\n\n", ac_path_log_importa_file, errno);
				log(LOG_ERROR, "%s;%s; Error opening file %s : %d",gUtente, gIP, ac_path_log_file, errno);
				return(0);
			}
			if ((hLogSoglie = fopen(acLogSoglie, "w")) == NULL)
			{
				/* avvisa dell'errore */
				printf("fopen %s: error %d\n\n", acLogSoglie, errno);
				log(LOG_ERROR, "%s;%s; Error opening file %s : code %d",gUtente, gIP, acLogSoglie, errno);
				return(0);
			}

			log(LOG_INFO, "%s;%s; Start Import Operators ",gUtente, gIP);
			printf("<center><br>\n");
			printf("<span id='wait1'>\
					<IMG SRC='images/loading.gif' BORDER=0 ALT=''>\n\
					</span>\n");
			fflush(stdout);

			rc = Confronta_File_DB(0);
			printf("<SCRIPT LANGUAGE='JavaScript'>\n\
					togliegif('wait1', 0);\n\
					</SCRIPT>");

			if(rc == 2)
			{
				//chiudo il file di log
				fclose(hLog);
				LeggoFilediLog(ac_path_log_importa_file, 0);
			}
			else if (rc == 0)
			{
				// Riepilogo
				sprintf(sTmp, "\n-------------------------------------------------------------------------\n");
				fputs(sTmp, hLog);
				//sprintf(sTmp, " # records to insert in DB Oper: %ld\n",RecAgg);
				//fputs(sTmp, hLog);
				sprintf(sTmp, " # records to update in DB Oper: %ld\n",RecUpd);
				fputs(sTmp, hLog);
				sprintf(sTmp, " # records to insert in DB OperGT: %ld\n",RecAggGT);
				fputs(sTmp, hLog);
				sprintf(sTmp, " # records to delete in DB OperGT: %ld\n",RecDelGT);
				fputs(sTmp, hLog);
				sprintf(sTmp, " # records to delete in DB Oper: %ld\n",RecDelOP);
				fputs(sTmp, hLog);
				sprintf(sTmp, "                 Threshold involved: %ld\n",RecSoglie);
				fputs(sTmp, hLog);
				sprintf(sTmp, "-------------------------------------------------------------------------\n");
				fputs(sTmp, hLog);

				//chiudo il file di log
				fclose(hLog);

				// se ci sono differenze lo visualizzo
				if (differenze == 1)
					LeggoFilediLog(ac_path_log_importa_file, 0);
				else
				{
					printf("<BR><BR>\n");
					printf("Input File and DB Operator are same");
					printf("<BR><BR><BR><BR>\n");
					printf("<input TYPE='button' VALUE='Back' name='back'  onclick='javascript:history.go(-1); return false;'>\n\
							\n");
				}
			}
		}
		else if ( strcmp(sOperazione, "UPDATE") == 0 )
		{
			log(LOG_INFO, "%s;%s; Import Operators  - Update",gUtente, gIP);
			printf("<center><br><br>\n\
					   <span id='wait1'>\n\
						<IMG SRC='images/loading.gif' BORDER=0 ALT=''>\n\
						</span>\n");
			fflush(stdout);

			/*------------------------------*/
			/* LOG SICUREZZA				*/
			/*------------------------------*/
			sprintf(log_spooler.ParametriRichiesta, "ALL");
			strcpy(log_spooler.TipoRichiesta, "UPD");			// LIST, VIEW, NEW, UPD, DEL
			LOGResult = SLOG_OK;

			rc = Confronta_File_DB(1);

			if(rc != 0)
				LOGResult = SLOG_ERROR;

			/*------------------------------*/
			/* LOG SICUREZZA				*/
			/*------------------------------*/
			log_spooler.EsitoRichiesta = LOGResult;
			Log2Spooler(&log_spooler, EVT_ON_ERROR);

			printf("<SCRIPT LANGUAGE='JavaScript'>\n\
					togliegif('wait1', 0);\n\
					</SCRIPT>");
			fflush(stdout);

			if(rc == 0)
			{
				log(LOG_INFO, "%s;%s; Import Operators - Input File (%s) imported correctly",gUtente, gIP, FileInput);
                printf("<center><br><br><br>Input File (%s) imported correctly", FileInput);
				printf("<BR><BR>\n");
				if (( (wrk_str = cgi_param( "NEW" ) ) != NULL ) )
				{
					printf(" #  records inserted in DB Operator: %ld<br>\n",RecAgg);
					printf(" #  records updated in DB Operator: %ld<br>\n",RecUpd);
					printf(" #  records inserted in DB Operator GT: %ld<br>\n",RecAggGT);
				}
				if (( (wrk_str = cgi_param( "DEL" ) ) != NULL ))
				{
					printf(" # records deleted from DB Operator GT: %ld<br>\n",RecDelGT);
					printf(" # records deleted from DB Operator: %ld<br>\n",RecDelOP);
				}
				if (( (wrk_str = cgi_param( "SOGLIE" ) ) != NULL ))
					printf(" # records deleted from DB Soglie: %ld<br>\n",RecSoglieDel);
			
				printf("<BR><BR>\n");
				printf("<BR><BR>\n");
				printf("<input TYPE='button' VALUE='Back' name='back'  onclick=\"javascript:location='%s?OPERATION=DISPLAY'\">\n", gName_cgi);
				fflush(stdout);
			}
		}
		MBE_FILE_CLOSE_(handleOp);
		MBE_FILE_CLOSE_(handleOP_rem);
		MBE_FILE_CLOSE_(handleOpGT);
		MBE_FILE_CLOSE_(handleOpGT_rem);
		MBE_FILE_CLOSE_(handlePa);
		MBE_FILE_CLOSE_(handleSogl);
		MBE_FILE_CLOSE_(handleSogl_rem);

		log(LOG_DEBUG, "%s;%s; Files closed",gUtente, gIP);

		Display_BOTTOM();
	}	
	log_close();

}
//*****************************************************************************************
void Display_File()
{

	printf("<center><br><br><br><br>");
	printf("<P><FORM METHOD=POST ACTION='%s' NAME='inputform' >\n\
					<INPUT TYPE='hidden' name='OPERATION' value='CONFRONTA' >\n\
					<TABLE border=0 align='center' >\n\
					<TR><TD><B>Input File : </B></td>\n\
					<td><INPUT TYPE='text' NAME='FILE_INPUT' size='80' maxlength ='80' >\n\
					</td></tr>\n\
					<TR><TD>&nbsp;</td>\n\
					<td>OSS Pathname (es:/G/volume/subvol/file name)</td></tr></TABLE></P>", gName_cgi);
	printf("<BR><BR><BR>\n");
	printf("<input icon='ui-icon-check' type='submit' value='Confirm' >\n");
	printf("</form></center>\n");
			

}


//***************************************************************************************
short CaricoListaPaesi()
{
	char		*pChiave;
	short		ret = 0;
	char		Key[8];
	char		sTmp[500];
	short		rc = 0;
	t_ts_paesi_record record_paesi;


	log(LOG_DEBUG, "%s;%s; CaricoListaPaesi",gUtente, gIP);

	memset(Key, ' ', sizeof(Key));
	listaPaesi = avlMake();

	rc = MBE_FILE_SETKEY_( handlePa, (char *) &Key, (short)sizeof(Key), 0, APPROXIMATE);
	
	while ( 1)
	{
		rc = MBE_READX( handlePa, (char *) &record_paesi, (short) sizeof(t_ts_paesi_record) );
		/* errore... */
		if ( rc)
		{
			if(rc != 1) {
				printf( "Readx: error %d (%.8s)\n\n", rc, Key);
				log(LOG_ERROR, "%s;%s; Error in reading file %s : code %d",gUtente, gIP, acFilePaesi_Loc, rc);

			} else
				rc = 0;
			break;
		}
		else  //record trovato
		{
			//Aggiungere un elemento alla lista:
			pChiave = malloc(20);
			//printf(pChiave,"%d", record_paesi.paese);
			memset(sTmp, 0x00, sizeof(sTmp));
			memcpy(sTmp, record_paesi.paese, sizeof(record_paesi.paese));
			AlltrimString(sTmp);
			strcpy(pChiave, sTmp);

			pImportPaesi = malloc(sizeof (ImportPaesi_struct_def));
			//sprintf(pImportPaesi->cc, "%-3d", record_paesi.paese);
			sprintf(pImportPaesi->cc, "%.8s", record_paesi.paese);
			sprintf(pImportPaesi->den_paese, "%.64s", record_paesi.den_paese);
			pImportPaesi->max_ts = record_paesi.max_ts;
			pImportPaesi->reset_ts_interval = record_paesi.reset_ts_interval;
			sprintf(pImportPaesi->gruppo_pa, "%.64s", record_paesi.gr_pa);
			pImportPaesi->len_mgt = (int) strlen(pChiave);

			if (avlAdd(listaPaesi, pChiave, pImportPaesi) == -1)
			{
				// nel file ci sono chiavi duplicate
				printf("the key: %s is already exist !!!", pChiave);
				ret = 1;
			}
		}
	}//fine while

	return (ret);
}

//***************************************************************************************
// tipo = 0  confronta i file
// tipo = 1  Aggiorna
//***************************************************************************************
short Confronta_File_DB(short tipo)
{
    char		sLetti[301];
	short		ret = 0;
	char		*pTmp;
	char		*wrk_str;
	char		chiave[50];
	char		chiave_ap[50];
	char		sTmp[500];
	char		sTmp2[100];
	char		sTmp3[100];
	//char		str[50];
	char		*pTmp1;
	char		*pTmp2;
	char		ac_Key[24];
	int			i =0;
	
	log(LOG_DEBUG, "%s;%s; Confronta File con DB (%d)",gUtente, gIP, tipo);

	//Creare la lista:
	listaFileGT = avlMake();
	//Creare la lista Soglie:
	listaSoglie = avlMake();

	Controlla_CarTable();

	/****************************************
	* apre il file  input               
	****************************************/
	if ((hIn = fopen(FileInput, "r")) == NULL)
	{
		/* avvisa dell'errore */
		printf("fopen %s: error %d\n\n", FileInput, errno);
		log(LOG_ERROR, "%s;%s; Error in opening file %s : code %d",gUtente, gIP, FileInput, errno);
		ret = 1;
	}

	if (ret == 0)
	{
		log(LOG_DEBUG, "%s;%s; File %s successfully opened",gUtente, gIP, FileInput);

		//Leggo file di input
		while (!feof(hIn))
		{
			memset (sLetti, 0x00, sizeof (sLetti));
			/* inizializza la struttura */
			memset(&importOP, 0, sizeof(struct ImportOP_struct));

			/* legge una riga fino allo \n */
			fgets(sLetti, 300, hIn);
			if( ferror(hIn))
			{
				printf("<BR><center><font color=red>Invalid File</font></center>");

				ret =1;
				break;
			}

			// prendo la prima parte della stringa fino al ';'
			//den_paese
			pTmp= GetToken(sLetti, ";|");
			if(pTmp)
			{
				memcpy(importOP.den_paese, pTmp, _min(strlen(pTmp)+1,sizeof(importOP.den_paese) ) );
				//strncpy(importOP.den_paese, pTmp, 64);
			}
			else
				continue;

			//codice operatore
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
			{
				pTmp2 = AlltrimString(pTmp);
				StrToUpper(pTmp2);
				memcpy(importOP.cod_op, pTmp2, _min(strlen(pTmp2)+1,sizeof(importOP.cod_op) ) );
			   // strncpy(importOP.cod_op, pTmp2, strlen(pTmp2));
			}
			else
				continue;

			//2018
			//codice TADIG
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
			{
				pTmp2 = AlltrimString(pTmp);
				StrToUpper(pTmp2);
				memcpy(importOP.tadig_code, pTmp2, _min(strlen(pTmp2)+1,sizeof(importOP.tadig_code) ) );
			}
			else
				continue;

			//operatore
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
			{
				memcpy(importOP.den_op, pTmp, _min(strlen(pTmp)+1,sizeof(importOP.den_op) ) );
			 //   strncpy(importOP.den_op, pTmp, 64);
			}
			else
				continue;

			//gt
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
			{
				memcpy(importOP.mgt, pTmp, _min(strlen(pTmp)+1,sizeof(importOP.mgt) ) );

				No_GT = 0;
				// se c'è uno spazio vuol dire che non c'è GT
				for(i=0; i<24; i++)
				{
					if(importOP.mgt[i] == ' ')
					{
						No_GT = 1;
						break;
					}
				}
				//log(LOG_DEBUG, "%s;%s; Lettura INI GT=%.24s [%.10s]",gUtente, gIP, importOP.mgt, importOP.cod_op);

			}
			else
				continue;

			//imsi
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
				memcpy(importOP.imsi_op, pTmp, _min(strlen(pTmp)+1,sizeof(importOP.imsi_op) ) );
				//strcpy(importOP.imsi_op, pTmp);
			else
				continue;

			//non usato
			pTmp= GetToken((char *)NULL, ";|");

			//map vers
			pTmp= GetToken((char *)NULL, ";|");
			if(pTmp)
				importOP.map_ver = (short) atoi(pTmp);
			else
				continue;

			//CAMEL;GPRS;Servizi:ecc...
			for (i = 0; i< strlen(gCaratt); i++ )
			{
				pTmp= GetToken((char *)NULL, ";|");
				if(pTmp)
				{
					//controllo se il valore del file di input è corretto
					if((pTmp[0] >= '0') && (pTmp[0] <= gCaratt[i]))
						importOP.characteristics[i] = pTmp[0];
					else
					//errore termina elaborazione
					{
						sprintf(sTmp, "Operator Characteristic %s is wrong. Value [%c] is not valid\nCountry:%.64s(%.8s) Operator:%.64s \n",
										aDenCarat[i],
										pTmp[0],
										importOP.den_paese,
										importOP.mgt,
										importOP.den_op);
						fputs(sTmp, hLog);
						// x non abilitare checkbox
						RecAgg = 0;
						RecUpd = 0;
						return(2);
					}
				}
				else
					continue;
			}

			if(!No_GT)  //c'è gt
			{
				//-----------------preparo il GT -------------------------
				memset(chiave, 0, sizeof(chiave));
				memset(chiave_ap, 0, sizeof(chiave_ap));
				memcpy(chiave_ap, importOP.mgt, sizeof(importOP.mgt) );
				//AlltrimString(chiave);
				Trim_inMezzo(chiave_ap, chiave);

				// compongo l'mgt
				pImportPaesi= avlFindLpm(listaPaesi, chiave);
				if (pImportPaesi == NULL)
				{
					//Non è stato trovato il paese nel DB Paesi
					sprintf(sTmp, "Country %s NOT FOUND in DB Paesi\n", chiave);
					fputs(sTmp, hLog);
					differenze = 1;
				}
				else
				{
					//controllo che ls den. paese corrisponde a quella del DB Paesi
					nDenDB = 0;
					if( memcmp(pImportPaesi->den_paese, importOP.den_paese, strlen(importOP.den_paese)) )
					{
						memset(sTmp2, 0, sizeof(sTmp2));
						memset(sTmp3, 0, sizeof(sTmp3));
						memcpy(sTmp2, importOP.den_paese, sizeof(importOP.den_paese));
						memcpy(sTmp3, pImportPaesi->den_paese, sizeof(pImportPaesi->den_paese));
						AlltrimString(sTmp2);
						AlltrimString(sTmp3);
						sprintf(sTmp, "Country Name: %s is wrong (GT:%.24s), in DB PAESI the Country Name is: %s (CC:%s)\n",
								sTmp2,
								importOP.mgt,
								sTmp3,
								pImportPaesi->cc);
						fputs(sTmp, hLog);
						nDenDB = 1; //non corrisponde
					}

					//------------------preparo l'IMSI -------------------------
					// 16-4-12
					//memset(sTmp, 0, sizeof(sTmp));
					//memset(sTmp2, 0, sizeof(sTmp2));
					//strcpy(sTmp, importOP.imsi_op);
					//Trim_inMezzo(sTmp, sTmp2);

					//memset(importOP.imsi_op, 0, sizeof(importOP.imsi_op));
					//if (sTmp[0] != 0 )
					//	memcpy(importOP.imsi_op, sTmp, strlen(sTmp));
					// fine

					//-----------------------------------------------------------------
					//Aggiungo un elemento alla listaFileGT e listaFileOP (contenuto del file di input)
					memset(ac_Key, ' ', sizeof(ac_Key));
					memcpy(ac_Key, pImportPaesi->cc, 8);
					memcpy(ac_Key+8, importOP.mgt+(pImportPaesi->len_mgt), sizeof(importOP.mgt)-1-pImportPaesi->len_mgt );
					pTmp1 = malloc(30);
					memset (pTmp1, 0x00, 30);
					//sprintf(pTmp1, "%.24s", ac_Key);
					memcpy(pTmp1, ac_Key, 24);
					AlltrimString(pTmp1);


					if (avlAdd(listaFileGT, pTmp1, pTmp1) == -1)
					{
						;// nel file ci sono chiavi duplicate
					}
				}
			}
			//-----------------------------------------------------------------
			if(tipo == 0)
				ret= Cerca_differenze_inDB(0);
			else
			{
				ret = 0; //??
				if (( (wrk_str = cgi_param( "NEW" ) ) != NULL ) )
				{
					ret = Cerca_differenze_inDB(1);
					if(ret)
						break;
				}

			}//fine else
		}//fine while
		fclose(hIn);

		if( ret == 0)
		{
			if (( (wrk_str = cgi_param( "DEL" ) ) != NULL ) && (strlen(wrk_str) > 0))
			{
				if(!No_GT)
					ret= Cerca_differenze_inFileI(2);
			//	if (ret == 0)
			//		ret= Del_OP_senza_GT(2);
			//	log(LOG_DEBUG, "%s;%s; Del_OP_senza_GT=[%d]",gUtente, gIP, ret);

			}
		}

		if(ret == 0 && tipo == 0)
		{
			if(!No_GT)
				ret = Cerca_differenze_inFileI(0);
		//	if (ret == 0)
		//		ret= Del_OP_senza_GT(0);
		}
	}
	return(ret);
}

//************************************************************************************
// Tipo == 0 visualizzazione
// Tipo == 1 Aggiornamento
//************************************************************************************
short Cerca_differenze_inDB(short Tipo )
{
	short		rc = 0;
	short		aggiorna = 0;
	char		sTmp[500];
	char		ac_Key[18];
	char		ac_Key_GT[24];
	t_ts_oper_record record_operatori;
	t_ts_opergt_record record_operatori_gt;


	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_gt, ' ', sizeof(t_ts_opergt_record));
	
	memset(sTmp, 0, sizeof(sTmp));

	memset(ac_Key, ' ', sizeof(ac_Key));

	if(!No_GT)
	{
		memcpy(ac_Key, pImportPaesi->cc, 8);
		memcpy(ac_Key+8, importOP.cod_op, strlen (importOP.cod_op));

		// preparo GT x operatori_GT
		memset(ac_Key_GT, ' ', sizeof(ac_Key_GT));
		memcpy(ac_Key_GT, pImportPaesi->cc, 8);
		memcpy(ac_Key_GT+8, importOP.mgt+pImportPaesi->len_mgt, strlen(importOP.mgt)-pImportPaesi->len_mgt);
	}
	else
	{
		memcpy(ac_Key, importOP.mgt, 8);
		memcpy(ac_Key+8, importOP.cod_op, strlen (importOP.cod_op));
	}

	log(LOG_DEBUG, "%s;%s; find the difference in DB - Key=%.18s (%d)",gUtente, gIP, ac_Key, Tipo);

	//-----------------------------------------------------------------
	rc = MBE_FILE_SETKEY_( handleOp, ac_Key, (short)sizeof(ac_Key), 0, EXACT);
	/* errore */
	if (rc != 0) {
		printf("File_setkey: error %d\n\n", rc);
		log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READX( handleOp, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
		//****************************  Operator NON trovato  *****************************************
		if ( rc)
		{
			if(rc == 1) 
			{
				if(Tipo == 0)
				{
					memset(sTmp, 0, sizeof(sTmp));
					sprintf(sTmp, "Record not found in DB OPERATOR: key='%.18s' - Country=%.64s - Operator=%.64s\n",
									ac_Key,  importOP.den_paese, importOP.den_op);
					fputs(sTmp, hLog);
					differenze = 1;
					RecAgg++;
					RecAggGT++;
					//  inserito 09-09-2013
					rc = 0;
				}
				else
				{
					rc = Scrivi_Operatore(ac_Key);
					if (rc == 0 && No_GT == 0)
						rc = Scrivi_OperatoreGT(ac_Key_GT);
				}

				if (rc == 0)
				{
					memset(sTmp, 0, sizeof(sTmp));
					memcpy(sTmp, importOP.den_paese, sizeof(importOP.den_paese));

					// ***** COMMENTATO 09-09-13
					//Cerco in soglie se c'e il paese
					//Cerca_InSoglie(sTmp, Tipo, 0);

					//Cerco se il  gruppo paese è contenuto in una soglia
					/*memset(sTmp, 0, sizeof(sTmp));
					strcpy(sTmp, pImportPaesi->gruppo_pa);
					if(sTmp[0] != 0)   				
						Cerca_InSoglie(sTmp, Tipo, 0);
					 *******   fine COMMENTO	*/
				}
			}
			else {
                printf( "Readx: error %d (%.18s)\n\n", rc, ac_Key);
				log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
				return rc;
			}
		}
		else
		{
			//****************************  Operator  trovato  *****************************************
			log(LOG_DEBUG, "%s;%s; Record found (%.18s) in DB  %s",gUtente, gIP, ac_Key, acFileOperatori_Loc);

			if(!No_GT)
			{
				rc = MBE_FILE_SETKEY_( handleOpGT,  ac_Key_GT, (short)sizeof(ac_Key_GT), 0, EXACT);
				/* errore */
				if (rc != 0) {
					printf("File_setkey: error %d\n\n", rc);
					log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
					return rc;
				}
				/* tutto ok */
				else
				{
					rc = MBE_READX( handleOpGT, (char *) &record_operatori_gt, (short) sizeof(record_operatori_gt) );
					//****************************  GT NON  trovato  *****************************************
					if ( rc)
					{
						if(rc == 1)
						{
							if(Tipo == 0)
							{
								memset(sTmp, 0, sizeof(sTmp));
								sprintf(sTmp, "Record not found in DB OPERATOR_GT: gt=[%.24s] \n", ac_Key_GT);
								fputs(sTmp, hLog);
								differenze = 1;
								RecAggGT++;
							}
							else
							{
								rc = Scrivi_OperatoreGT (ac_Key_GT);
							}
						}
						else
						{
							printf( "Readx: error %d (%.18s)\n\n", rc, ac_Key);
							log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
							return rc;
						}
					}
				}
			}

			if(rc == 0)
			{
				aggiorna = 0;

				//confronto i dati
				if( memcmp(record_operatori.cod_op, importOP.cod_op, strlen(importOP.cod_op)) )
				{
					sprintf(sTmp, "(%.18s) Operator Code is different: DB=%.10s - Input File=%.10s\n",
									ac_Key, record_operatori.cod_op, importOP.cod_op );
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}
				if( memcmp(record_operatori.den_op, importOP.den_op, strlen(importOP.den_op)) )
				{
					sprintf(sTmp, "(%.18s) Operator Name is different: DB=%.64s - Input File=%.64s(%d)\n",
						ac_Key, record_operatori.den_op, importOP.den_op,strlen(importOP.den_op));
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}

				// 2018
				if( memcmp(record_operatori.tadig_code, importOP.tadig_code, strlen(importOP.tadig_code)) )
				{
					sprintf(sTmp, "(%.18s) Tadig Code is different: DB=%.5s - Input File=%.5s\n",
									ac_Key, record_operatori.tadig_code, importOP.tadig_code );
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}

				if( memcmp(record_operatori.imsi_op, importOP.imsi_op, strlen(importOP.imsi_op)) )
				{
					sprintf(sTmp, "(%.18s) Imsi Operator is different: DB=<%.16s> - Input File=<%s>\n",
									ac_Key, record_operatori.imsi_op, importOP.imsi_op);
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}

				if( record_operatori.map_ver != importOP.map_ver )
				{
					sprintf(sTmp, "(%.18s) MAP Version is different: DB=%d - Input File=%d\n",
						ac_Key, record_operatori.map_ver, importOP.map_ver);
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}

				if( memcmp(record_operatori.characteristics, importOP.characteristics, strlen(importOP.characteristics)) )
				{
					sprintf(sTmp, "(%.18s) Characteristic Operator is different: DB=<%.10s> - Input File=<%s>\n",
									ac_Key, record_operatori.characteristics, importOP.characteristics);
					fputs(sTmp, hLog);
					differenze = 1;
					aggiorna = 1;
				}

				if(Tipo == 0 && aggiorna == 1)
					RecUpd++;

				if(Tipo == 1 && aggiorna == 1)
					rc = Scrivi_Operatore(ac_Key);
			}
		}

		if(Tipo == 1 && RecUpd > 0 || RecAgg > 0 || RecAggGT > 0) 
			rc = Aggiorna_Operatori_rec_Aster(handleOp, handleOP_rem);
	}
	return (rc);
}
//************************************************************************************
//tipo = 0  cerca differenze e scrive log
//tipo = 2  cancella record 
//************************************************************************************
short Cerca_differenze_inFileI(short tipo)
{
	char	ac_Chiave[24];
	char	acGT[100];
	char	sTmp[500];
	char	acOp[20];
	short	rc = 0;
	t_ts_opergt_record record_operatori_gt;

	log(LOG_DEBUG, "%s;%s; find the difference in FileInput (%d)",gUtente, gIP, tipo);

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori_gt, ' ', sizeof(t_ts_opergt_record));

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acOp, 0, sizeof(acOp));

	/**************************************
	* Cerco il record nel DB operatori GT
	***************************************/
	rc = MBE_FILE_SETKEY_( handleOpGT, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey from Local file [%s]", rc, acFileOperGT_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return rc;
	}
	rc = MBE_FILE_SETKEY_( handleOpGT_rem, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey from Local file [%s]", rc, acFileOperGT_Loc);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
		return rc;
	}
	/* tutto ok */
	if (tipo == 0)
	{
		fputs("****************************************************************************\n", hLog);
		sprintf(sTmp,"DB Operator_GT records not found in Input File (%s)\n", FileInput);
		fputs(sTmp, hLog);
		fputs("****************************************************************************\n", hLog);
	}

	while ( 1)
	{
		/*************************************
		* Leggo il record dal DB operator GT
		*************************************/
		rc = MBE_READX( handleOpGT, (char *) &record_operatori_gt, (short) sizeof(t_ts_opergt_record) );
		/* errore... */
		if (rc != 0)
		{
			if (rc != 1)
			{
				sprintf(sTmp, "Error (%d) in reading Local from file [%s]", rc, acFileOperGT_Loc);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
			}
			else
				rc = 0;
			break;
		}
		/* record TROVATO */
		else  /* readx ok */
		{
			rc = MBE_READX( handleOpGT_rem, (char *) &record_operatori_gt, (short) sizeof(t_ts_opergt_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading Remote from file [%s]", rc, acFileOperGT_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 0;
				break;
			}
		}

		if(rc == 0)
		{
			/* record TROVATO */
			memset(acGT, 0, sizeof(acGT));
			memcpy(acGT, record_operatori_gt.gt, sizeof(record_operatori_gt.gt));

			// cerca la chiave nella lista
			AlltrimString(acGT);
		//	log(LOG_DEBUG, "%s;%s; Record read from file %s GT=%s",gUtente, gIP, acFileOperGT_Loc, acGT);

			//cerco se ci sono elementi nel db operatori che non ci sono nel file di input
			// lista contiene tutti gli MGT del file di input
			if(avlFind(listaFileGT, acGT) == NULL)
			{ // non trovato
				if (tipo == 0)
				{
					sprintf(sTmp, "GT='%s'- CC= %.8s - Cod_op= %.10s \n",
								acGT, record_operatori_gt.paese, record_operatori_gt.cod_op);
					fputs(sTmp, hLog);
					differenze = 1;
					RecDelGT++;
				}
				else
				{
					//cancello il Record dal db operatoriGT
					rc = MBE_WRITEUPDATEX(handleOpGT, (char *) &record_operatori_gt, 0 );
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in deleting Local file [%s]", rc, acFileOperGT_Loc);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						break;
					}
					//**************************** CANCELLO DB REMOTO  ********************
					rc = MBE_WRITEUPDATEX(handleOpGT_rem, (char *) &record_operatori_gt, 0 );
					if ( rc)
					{
						sprintf(sTmp, "Error (%d) in deleting Remote file [%s]", rc, acFileOperGT_Rem);
						log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
						Display_Message(1, "", sTmp);
						break;
					}
					// se errore record REMOTO NON re-INSERISCO  GT in Locale

				}

				// ***** COMMENTATO 09-09-13
			/*	if(rc == 0)
				{
					memset(acOp, 0, sizeof(acOp));
					//controllo se l'operatore appartiende ad una soglia
					memcpy(acOp, record_operatori_gt.cod_op, sizeof(record_operatori_gt.cod_op));
					Cerca_InSoglie(acOp, tipo, 1);
				}*/
				// fine COMMENTO
			}
		}
	}

	return(rc);
}

//************************************************************************************
short Scrivi_Operatore(char *Key)
{
	short	rc = 0;
	char	sTmp[200];
	short	nOperazione;

	t_ts_oper_record record_operatori;
	t_ts_oper_record record_operatori_backup;
	t_ts_oper_record record_appo2;


	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_backup, ' ', sizeof(t_ts_oper_record));
	memset(sTmp, 0, sizeof(sTmp));

	memcpy(record_operatori.paese, Key, sizeof(record_operatori.paese));

	memcpy(record_operatori.cod_op, importOP.cod_op, strlen(importOP.cod_op));
	memcpy(record_operatori.tadig_code, importOP.tadig_code, strlen(importOP.tadig_code));
	memcpy(record_operatori.den_op, importOP.den_op, strlen(importOP.den_op));
	memcpy(record_operatori.den_paese, pImportPaesi->den_paese, strlen(pImportPaesi->den_paese));
	memcpy(record_operatori.imsi_op, importOP.imsi_op, strlen(importOP.imsi_op));
	memcpy(record_operatori.characteristics, importOP.characteristics, strlen(importOP.characteristics));

	record_operatori.map_ver = importOP.map_ver;
	record_operatori.max_ts = pImportPaesi->max_ts;
	record_operatori.reset_ts_interval = pImportPaesi->reset_ts_interval;
	record_operatori.steering_map_errcode = 36;
	record_operatori.steering_lte_errcode = 5012;


	//************************ DB OPERATORE ***********************************
	// Cerco il record

	rc = MBE_FILE_SETKEY_( handleOp, record_operatori.paese, (short)sizeof(record_operatori.paese) + sizeof(record_operatori.cod_op), 0, EXACT);
	/* errore */
	if (rc != 0) {
		printf("File_setkey: error %d\n\n", rc);
		log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handleOp, (char *) &record_appo2, (short) sizeof(t_ts_oper_record) );
		/* errore... */
		if ( rc)
		{
			//record non trovato lo aggiungo
			if(rc == 1) 
			{
				nOperazione = INS;

				rc = MBE_WRITEX( handleOp, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				/* errore */         
				if (rc)
				{
					printf("Writex: error %d in file %s\n\n", rc, acFileOperatori_Loc);
					log(LOG_ERROR, "%s;%s; Error in writing in file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
				}
				else
				{
				//	log(LOG_DEBUG, "%s;%s; Record added in file %s Key=%.18s%.10s"
				//						,gUtente, gIP, acFileOperatori_Loc, Key, record_operatori.cod_op);
				//	RecAgg++;
					rc = 0;
				}
			}
			else
			{
                printf( "Readx: error %d (%.8s,%.10s)\n\n", rc, record_operatori.paese, record_operatori.cod_op);
				log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
			}
		}
		else  //record trovato
		{
			nOperazione = UPD;
			// ****  faccio copia di BACKUP per eventuale ripristino ******
			memcpy(&record_operatori_backup, &record_operatori, sizeof(record_operatori));

			memcpy(record_operatori.gruppo_op, record_appo2.gruppo_op, sizeof(record_operatori.gruppo_op));
			memcpy(record_operatori.gruppo_pa, record_appo2.gruppo_pa, sizeof(record_operatori.gruppo_pa));

			rc = MBE_WRITEUPDATEX( handleOp, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
			if(rc)
			{
				printf("writeupdatex: error %d\n\n", rc);
				log(LOG_ERROR, "%s;%s; Error in writing in file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
				MBE_UNLOCKREC(handleOp);
			}
			/*else
			{
				RecUpd++;
				log(LOG_DEBUG, "%s;%s; Record updated in file %s CC=%.18s%.10s"
								,gUtente, gIP, acFileOperatori_Loc, Key,record_operatori.cod_op);
			}*/
		}
	}

	if(rc == 0)
	{
		// ************ scrivo DB REMOTO *****************************
		if( nOperazione == UPD )
		{
			rc = scrivi_Operatori_remoto(handleOP_rem, &record_operatori, UPD );
			if(rc == 0)
			{
				// tutto ok unlock locale
				MBE_UNLOCKREC(handleOp);

				RecUpd++;
				log(LOG_DEBUG, "%s;%s; Record updated in file %s CC=%.18s%.10s"
								,gUtente, gIP, acFileOperatori_Rem, Key, record_operatori.cod_op);
			}
			else
			{
				// ERRORE SCRITTURA REMOTO
				// aggiorno il record in Locale con i dati originali
				rc = MBE_WRITEUPDATEUNLOCKX( handleOp, (char *) &record_operatori_backup, (short) sizeof(t_ts_oper_record) );
				if(rc)
				{
					sprintf(sTmp, "Error (%d) in updating Local file [%s] - Key: [%.18s]", rc, acFileOperatori_Loc, record_operatori.paese);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handleOp);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}
		else
		{
			rc = scrivi_Operatori_remoto(handleOP_rem, &record_operatori, INS );
			if(rc == 0)
			{
				log(LOG_DEBUG, "%s;%s; Record added in file %s Key=%.18s%.10s"
								,gUtente, gIP, acFileOperatori_Loc, Key, record_operatori.cod_op);
				RecAgg++;
			}
			else
			{
				// ERRORE Inserimento REMOTO
				//cancello locale
				MBE_FILE_SETKEY_( handleOp, (char *) &record_operatori.paese, (short)sizeof(record_operatori.paese)+ sizeof(record_operatori.cod_op), 0, EXACT);
				MBE_READLOCKX( handleOp, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
				rc = MBE_WRITEUPDATEUNLOCKX( handleOp, (char *) &record_operatori, 0);
				if(rc)
				{
					sprintf(sTmp, "Error (%d) deleting in Local file [%s] - Key: [%.18s]", rc, acFileOperatori_Loc, record_operatori.paese);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
					MBE_UNLOCKREC(handleOp);
				}
				// setto rc a 1 per segnalare errore
				rc = 1;
			}
		}

	}
	return(rc);
}

//********************************************************************************
short Scrivi_OperatoreGT(char *ac_Key_GT)
{
	short		rc = 0;
	char		sTmp[500];

	t_ts_opergt_record record_operatori_gt;
	t_ts_opergt_record record_appo2;

	//log(LOG_INFO, "Controllo OperGT GT=%s (operazione=%d)", ac_Key_GT, Tipo);

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori_gt, ' ', sizeof(t_ts_opergt_record));
	memset(sTmp, 0, sizeof(sTmp));

	memcpy(record_operatori_gt.gt, ac_Key_GT, sizeof(record_operatori_gt.gt));
	memcpy(record_operatori_gt.paese, pImportPaesi->cc, strlen(pImportPaesi->cc));
	memcpy(record_operatori_gt.cod_op, importOP.cod_op, strlen(importOP.cod_op));


	//************************ DB OPERATORE GT ***********************************
	// Cerco il record

	rc = MBE_FILE_SETKEY_( handleOpGT, record_operatori_gt.gt, (short)sizeof(record_operatori_gt.gt), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		printf("File_setkey: error %d\n\n", rc);
		log(LOG_ERROR, "%s;%s; Error in reading from Local file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
	}

	else
	{
		rc = MBE_FILE_SETKEY_( handleOpGT_rem, record_operatori_gt.gt, (short)sizeof(record_operatori_gt.gt), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			printf("File_setkey: error %d\n\n", rc);
			log(LOG_ERROR, "%s;%s; Error in reading from Remote file %s : code %d",gUtente, gIP, acFileOperGT_Rem, rc);
		}
	}

	if(rc == 0)
	{
		rc = MBE_READX( handleOpGT, (char *) &record_appo2, (short) sizeof(t_ts_opergt_record) );
		/* errore... */
		if ( rc)
		{
			//record non trovato, lo aggiungo
			if(rc == 1) 
			{
				rc = MBE_WRITEX( handleOpGT, (char *) &record_operatori_gt, (short) sizeof(t_ts_opergt_record) );
				/* errore */         
				if (rc)
				{
					printf("Writex: error %d in Local file %s\n\n", rc, acFileOperGT_Loc);
					log(LOG_ERROR, "%s;%s; Error in writing in file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
				}
				else
				{
					// AGGIORNO REMOTO
					rc = MBE_WRITEX( handleOpGT_rem, (char *) &record_operatori_gt, (short) sizeof(t_ts_opergt_record) );
					/* errore */
					if (rc)
					{
						printf("Writex: error %d in Remote file %s\n\n", rc, acFileOperGT_Rem);
						log(LOG_ERROR, "%s;%s; Error in writing in Remote file %s : code %d",gUtente, gIP, acFileOperGT_Rem, rc);
						// ERRORE Inserimento REMOTO
						//cancello locale
						MBE_FILE_SETKEY_( handleOpGT, (char *) &record_operatori_gt.gt, (short)sizeof(record_operatori_gt.gt), 0, EXACT);
						MBE_READLOCKX( handleOpGT, (char *) &record_operatori_gt, (short) sizeof(t_ts_opergt_record) );
						rc = MBE_WRITEUPDATEUNLOCKX( handleOpGT, (char *) &record_operatori_gt, 0);
						if(rc)
						{
							sprintf(sTmp, "Error (%d) in deleting Local file [%s]", rc, acFileOperGT_Loc);
							log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
							Display_Message(1, "", sTmp);
							MBE_UNLOCKREC(handleOpGT);
						}
						// setto rc a 1 per segnalare errore
						rc = 1;
					}
					else
					{
						log(LOG_DEBUG, "%s;%s; Record added in file %s - key=%.24s",gUtente, gIP, acFileOperGT_Loc, ac_Key_GT);
						rc = 0;
						RecAggGT++;
					}
				}
			}
			else
			{
				printf( "Readx: error %d (%.24s)\n\n", rc, record_operatori_gt.gt);
				log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
			}
		}
		else  //record trovato
		{
			log(LOG_DEBUG, "%s;%s; Record already present in file %s - key=%.24s",gUtente, gIP, acFileOperGT_Loc, ac_Key_GT);
		}
	}


	return(rc);
}

//********************************************************************************
void LeggoFilediLog( char *NomeLog, short Tipo)
{
	FILE	*hIn;
	char	sLetti[3000];
	char	sTmp[500];


	/****************************
	* apre e legge file di input
	*****************************/
	/* apre il file in input */
	if ((hIn = fopen(NomeLog, "r")) == NULL)
	{
		/* se non è un errore per file inesistente */
		if (errno!=4002)
		{
			/* avvisa dell'errore */
			sprintf(sTmp, "fopen(%s): error %d", NomeLog, errno);
			log(LOG_ERROR, "%s;%s; Error in opening file %s : code %d",gUtente, gIP, NomeLog, errno);
			Display_Message(1, "", sTmp);
		}
	}

	/* se apertura OK o file non trovato */
	if (errno==0 || errno==4002)
	{
		/* costruisce l'HTML */
		//Display_TOP(sTmp);

		printf("<BR><CENTER>\n");

		printf("<textarea wrap='PHYSICAL' cols='160' rows='30' name='TESTO'  READONLY >");

		/* se ha aperto il file */
		if (errno==0)
		{
			log(LOG_INFO, "%s;%s; Log File %s successfully opened",gUtente, gIP, NomeLog);

			/* scorre tutto il file */
			while (!feof(hIn))
			{
				memset (sLetti, 0x00, sizeof (sLetti));

				/* legge una riga fino allo \n */
				if (fgets(sLetti, 2048, hIn) != NULL )
				{
					/* ci può essere un NULL come primo carattere  */
					if (sLetti[0] == '\0')
					{
						printf("%s", sLetti + 1);
					}
					else
					{
						printf("%s", sLetti);
					}
				}
				else
					break;
			}
			fclose(hIn);
		}

		printf("</textarea>\n");
		printf("<BR><BR>\n");

		if(Tipo == 0)
		{
			printf("<FORM METHOD=POST ACTION='%s' NAME='inputform'>\n\
					<INPUT TYPE='hidden' name='OPERATION' value='UPDATE' >\n\
					<INPUT TYPE='hidden' name='FILE_INPUT' value='%s' >\n\
					", gName_cgi, FileInput);

			printf("<INPUT TYPE='checkbox' NAME='NEW' onClick='abilitaUpd()' ");
			if (RecAgg == 0 && RecUpd == 0)
				printf("disabled");
			printf(" >Record New/Update\n");

			printf("&nbsp;&nbsp;&nbsp;");
			printf("<INPUT TYPE='checkbox' NAME='DEL' onClick='abilitaUpd()'");
			if (RecDelGT == 0 && RecDelOP == 0)
				printf("disabled");
			printf(" >Record Delete\n");
		
			//printf("&nbsp;&nbsp;&nbsp;");
			//printf("<INPUT TYPE='checkbox' NAME='DB_OK' checked>Only Correct Country Name \n");
		
			printf("&nbsp;&nbsp;&nbsp;");
		/*	printf("<INPUT TYPE='checkbox' NAME='SOGLIE' onClick='abilitaUpd()'");
			if (RecSoglie == 0)
				printf("disabled");
			printf(" >Record delete Threshold\n");*/


			printf(" &nbsp;&nbsp;\n\
				   <A HREF=\"javascript:newWindow('%s?OPERATION=LOG', 'window2')\">\
					<IMG SRC='images/appunti.gif' WIDTH='20' HEIGHT='20' BORDER=0 title='involved threshold'></A>\n", gName_cgi );

			printf("<BR><BR>\n");

			printf("<input TYPE='button' icon='ui-icon-home' VALUE='Back' name='back'  onclick='javascript:history.go(-1); return false;'>\n\
					&nbsp;&nbsp;&nbsp;&nbsp;\n\
					<input TYPE='submit' icon='ui-icon-check' VALUE='Update' name='UPD' disabled>\n\
					</form>\n");
		}
		else
			printf( "<INPUT TYPE='button' VALUE='Close' onclick='window.close()' >\n");

		printf("</CENTER>\n");
	}
}



//**************************************************************************************
//  Cerco nel DB soglie i record da cancellare
//  Tipo == 0 visualizza
//  Tipo == 2 cancella
//**************************************************************************************
short Cerca_InSoglie_2(char *ac_denPA, char *ac_codOP, short Tipo)
{
	short		rc = 0;
	char		sTmp[500];
	short		Agg_Soglie = 0;
	long long 	lJTS = 0;
	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_soglie_rem;


	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));

	memcpy(record_soglie.gr_pa, ac_denPA, strlen(ac_denPA));
	memcpy(record_soglie.gr_op, ac_codOP, strlen(ac_codOP));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handleSogl, record_soglie.gr_pa, (short) sizeof(record_soglie.gr_pa)+sizeof(record_soglie.gr_op), 0, GENERIC);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "File_setkey: error %d", rc);
		log(LOG_ERROR, "%s;%s; Error in reading from LOCAL file soglie : code %d",gUtente, gIP, rc);
		Display_Message(1, "", sTmp);
	}
	//   *********************  DB REMOTO **************************
	if (rc == 0 && Tipo == 2)
	{
		rc = MBE_FILE_SETKEY_( handleSogl_rem, record_soglie.gr_pa, (short) sizeof(record_soglie.gr_pa)+sizeof(record_soglie.gr_op), 0, GENERIC);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", rc);
			log(LOG_ERROR, "%s;%s; Error in reading from REMOTE file soglie : code %d",gUtente, gIP, rc);
			Display_Message(1, "", sTmp);
		}
	}
	/* tutto ok */
	if (rc == 0)
	{
		while ( 1 )
		{
			/*******************
			* Leggo i records trovati (gr_pa+gr_op)
			*******************/
			//rc = MBE_READX( handleSogl, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			rc = MbeFileRead_nw( handleSogl, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "%s;%s; Error in reading from file soglie : code %d",gUtente, gIP, rc);
					sprintf(sTmp, "Read error local file [%s]: error %d", acFileSoglie_Loc, rc);
					Display_Message(1, "", sTmp);
				}
				else
					rc = 0;
				// ESCE dal CICLO
				break;
			}
			/* record TROVATO */
			// visualizzo i record dele soglie che verranno cancellati
			if(Tipo == 0)
			{
				fputs("************************** THRESHOLD ***************************\n", hLogSoglie);

				sprintf(sTmp, "Country / Country Group &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; - ");
				fputs(sTmp, hLogSoglie);
				sprintf(sTmp, "Operator / Operator Group &nbsp;&nbsp;&nbsp; - ");
				fputs(sTmp, hLogSoglie);
				sprintf(sTmp, "T.from - T. to - MTWTFSS  - ");
				fputs(sTmp, hLogSoglie);
				sprintf(sTmp, "State - Threshold\n");
				fputs(sTmp, hLogSoglie);
				sprintf(sTmp, "%.64s %.64s   %.5s    %.5s   %.7s    %c       %d\n", record_soglie.gr_pa,
								record_soglie.gr_op, record_soglie.fascia_da, record_soglie.fascia_a,
								record_soglie.gg_settimana, record_soglie.stato, record_soglie.soglia);
				fputs(sTmp, hLogSoglie);
				RecSoglie ++;
			}

			//  CANCELLO il record
			if(Tipo == 2)
			{
				// ************************ CERCO  DB REMOTO ******************************
			//	rc = MBE_READX( handleSogl_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
				rc = MbeFileRead_nw( handleSogl_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						sprintf(sTmp, "Error in deleting record from REMOTE file [%s] : code %d.", acFileSoglie_Rem, rc);
						log(LOG_ERROR, "%s;%s; Error in reading from REMOTE file [%s]: code %d",gUtente, gIP, acFileSoglie_Rem, rc);
						Display_Message(1, "", sTmp);
						break;
					}
					else
						rc = 0;
				}
				//************************* cancellazione DB LOCALE ****************************************
			//	rc = MBE_WRITEUPDATEX( handleSogl, (char *) &record_soglie, 0 );
				rc = MbeFileWriteUU_nw( handleSogl, (char *) &record_soglie, 0 );
				if ( rc)
				{
					sprintf(sTmp, "Error in deleting record from local file [%s] : code %d", acFileSoglie_Loc, rc);
					log(LOG_ERROR, "%s;%s; Error in deleting record from local file [%s] : code %d",gUtente, gIP, acFileSoglie_Loc, rc);
					Display_Message(1, "", sTmp);
					break;
				}
				else
				{
					//************************* cancellazione DB REMOTO ****************************************
				//	rc = MBE_WRITEUPDATEX( handleSogl_rem, (char *) &record_soglie_rem, 0 );
					rc = MbeFileWriteUU_nw( handleSogl_rem, (char *) &record_soglie_rem, 0 );
					if ( rc)
					{
						sprintf(sTmp, "Error in deleting record from REMOTE file [%s] : code %d. The threshold in local file has been deleted", acFileSoglie_Rem, rc);
						log(LOG_ERROR, "%s;%s; Error in deleting from remote file [%s]: code %d",gUtente, gIP, acFileSoglie_Rem, rc);
						Display_Message(1, "", sTmp);
						break;
					}
				}
				if (rc == 0)
				{
					Agg_Soglie = 1;
					log(LOG_DEBUG, "%s;%s; Record deleted from file LOCAL soglie key=%.60s",gUtente, gIP, record_soglie.gr_pa);
					RecSoglieDel ++;
				}
			}//tipo == 2
		}//fine while(1)

		if (Tipo == 2 && Agg_Soglie == 1  )
		{
			GetTimeStamp(&lJTS); //GMT
			rc = Aggiorna_Soglie_rec_Aster(handleSogl, handleSogl_rem, lJTS, 0);
		}
	}
	return(rc);
}



//***************************************************************************************************
short Del_OP_senza_GT(short Tipo)
{
	short		rc = 0;
	char		sTmp[500];
	char		ac_Key[18];
	char		ac_Key2_GT[18];
	char		ac_denPA[50];
	char		ac_codOP[50];
	short		is_AltKey;

	t_ts_oper_record record_operatori;
	t_ts_opergt_record record_operatori_gt;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof(t_ts_oper_record));
	memset(&record_operatori_gt, ' ', sizeof(t_ts_opergt_record));
	
	memset(sTmp, 0, sizeof(sTmp));
	memset(ac_denPA, 0, sizeof(ac_denPA));
	memset(ac_codOP, 0, sizeof(ac_codOP));

	memset(ac_Key, ' ', sizeof(ac_Key));

	log(LOG_DEBUG, "%s;%s; ------ Delete OP which does not have GT ------",gUtente, gIP);
	fputs("****************************************************************************\n", hLog);
	sprintf(sTmp,"DB Operator records not found in Input File (%s)\n", FileInput);
	fputs(sTmp, hLog); 
	fputs("****************************************************************************\n", hLog);

	rc = MBE_FILE_SETKEY_( handleOp, ac_Key, (short)sizeof(ac_Key), 0, APPROXIMATE);
	/* errore */
	if (rc != 0) 
	{
		printf("File_setkey: error %d\n\n", rc);
		log(LOG_ERROR, "%s;%s; Error in reading(MBE_FILE_SETKEY_) from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
	}
	/* tutto ok */
	else
	{
		while ( 1 )
		{
			rc = MBE_READX( handleOp, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
			/* errore... */
			if ( rc)
			{
				if(rc != 1)
				{
					printf( "Readx: error %d)\n\n", rc);
					log(LOG_ERROR, "%s;%s; Error in reading from file %s : code %d",gUtente, gIP, acFileOperatori_Loc, rc);
				}
				else
					rc = 0;
				break;
			}
			else  //record trovato
			{
				if( !memcmp(record_operatori.paese, "******", 6))
					continue;

				// cerca in operatori_GT
				memset(ac_Key2_GT, ' ', sizeof(ac_Key2_GT));
				memcpy(ac_Key2_GT, record_operatori.paese, sizeof(ac_Key2_GT));

				/*  ricerca  per chiave alternata*/
				is_AltKey = 1;
				rc = MBE_FILE_SETKEY_( handleOpGT,  ac_Key2_GT, (short)sizeof(ac_Key2_GT), is_AltKey, GENERIC);
				/* errore */
				if (rc != 0) 
				{
					printf("File_setkey: error %d\n", rc);
					log(LOG_ERROR, "%s;%s; Error in reading (File_setkey) from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
					break;
				}
				/* tutto ok */
				else
				{
					rc = MBE_READX( handleOpGT, (char *) &record_operatori_gt, (short) sizeof(record_operatori_gt) );
					/* errore... */
					if ( rc)
					{
						// nessun record trovato cancello operatore
						if(rc == 1) 
						{
							if(Tipo == 0)
							{
								memset(sTmp, 0, sizeof(sTmp));
								sprintf(sTmp, "OPERATOR: %.18s did not GT\n", ac_Key2_GT);
								fputs(sTmp, hLog);
								differenze = 1;
								RecDelOP++;

								//**************************************************************
								//   09-09-13  aggiunta scrittura log soglie da cancellare
								memcpy(ac_denPA, record_operatori.den_paese, sizeof(record_operatori.den_paese));
								memcpy(ac_codOP, record_operatori.cod_op, sizeof(record_operatori.cod_op));
								rc = Cerca_InSoglie_2(ac_denPA, ac_codOP, 0);
								if (rc != 0)
									break;
							}
							else
							{
								//*********************************************
								//cancello il Record dal db operatori
								//*********************************************
								rc = MBE_WRITEUPDATEX(handleOp, (char *) &record_operatori, 0 );
								if ( rc)
								{
									sprintf(sTmp, "Delete (%s) - writeupdatex: error %d", acFileOperatori_Loc, rc);
									log(LOG_ERROR, "%s;%s; Error in deleting record from file %s",gUtente, gIP, acFileOperatori_Loc);
									Display_Message(1, "", sTmp);
									break;
								}
								// AGGIORNO DB REMOTO
								rc = scrivi_Operatori_remoto(handleOP_rem, &record_operatori, DEL );
								if(rc == 0)
								{
									log(LOG_DEBUG, "%s;%s; Record deleted from file %s (%.18s)",gUtente, gIP, acFileOperatori_Loc, record_operatori.paese);
									RecDelOP++;
								}
								// se errore record REMOTO NON re-INSERISCO OPERATORE SENZA GT in Locale

								//**************************************************************
								//   09-09-13  aggiunta scrittura log soglie da cancellare
								memcpy(ac_denPA, record_operatori.den_paese, sizeof(record_operatori.den_paese));
								memcpy(ac_codOP, record_operatori.cod_op, sizeof(record_operatori.cod_op));
								rc = Cerca_InSoglie_2(ac_denPA, ac_codOP, 2);
								if (rc != 0)
									break;
							}
						}
						else
						{
							printf("File_setkey: error %d\n", rc);
							log(LOG_ERROR, "%s;%s; Error in reading  from file %s : code %d",gUtente, gIP, acFileOperGT_Loc, rc);
							break;
						}
					}
				}
			}
		}// fine while letturea OP
	}

	return(rc);
}
