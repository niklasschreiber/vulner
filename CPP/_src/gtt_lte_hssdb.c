#if (_TNS_E_TARGET)
T0000H06_31MAR2017_KTSTEA10() {};
#elif (_TNS_X_TARGET)
T0000L16_31MAR2017_KTSTEA10() {};
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
#include <cextdecs.h (JULIANTIMESTAMP, CONVERTTIMESTAMP)>
#include <cgi.h>

#include "gttltedb.h"
#include "utility.h"

/*------------- VARIABILI GLOBALI -------------*/
char acHSSDB[50];
char acIMSIDB[50];
char acFileIni[60];
char ac_user[50];

/*------------- DEFINE -------------*/
#define NOTHING		0
#define VISU_REC	1
#define DELETE_REC	2
#define NEW_REC		3
#define UPD_REC		4

/*------------- PROTOTIPI -------------*/
void  Lista_Rec(void);
void  Visu_Canc_Rec(short CosaFare);
void  Ins_Upd_Rec(short CosaFare);
void  Check_Canc_Rec(void);
int   Apri_File(char *nomefile, short *handle);
void  Display_Top(short tipo);
void  Display_Bottom(void);
void  Display_Message(int nTipo, char *sMessaggio);

/******************************************************************************/
/* MAIN           *************************************************************/
/******************************************************************************/
int main(int argc, char *argv[])
{
	char	*wrk_str;
	char	dummy[256];
	int		ret;
	int		found=1;

	memset(acHSSDB, 0x00, sizeof(acHSSDB));
	memset(acIMSIDB, 0x00, sizeof(acIMSIDB));

	/*---------------------------------------*/
	/* assegna alla CGI l'utente loggato    */
	/*---------------------------------------*/
	ret = cgi_session_verify(dummy);

	if (ret == 0)
	{
		printf ("<center><font color='red'>%s</font></center>", dummy);
		return(0);
	}

	/*---------------------------*/
	/* LETTURA NOME INI			 */
	/*---------------------------*/
	if ( (wrk_str = getenv( "GTT_FILE_INI" ) ) != NULL )
		strcpy(acFileIni, wrk_str);
	else
	{
		Display_Message(-1, "GTT_FILE_INI");
		return(0);
	}

	/*----------------------------*/
	/* LETTURA NOME DB da INI 	  */
	/*----------------------------*/
	/* NOME HSS DB */
	ret = get_profile_string( acFileIni, "DATABASE", "HSS_DB", &found, dummy );
	/* trovato */
	if ( ret == 0 && found==1 )
		strcpy(acHSSDB, dummy);
	else
	{
		Display_Message(1, "INI file incomplete: missing parameter [DATABASE]HSS_DB");
		return(0);
	}

	/* NOME IMSI DB */
	ret = get_profile_string( acFileIni, "DATABASE", "IMSI_DB", &found, dummy );
	/* trovato */
	if ( ret == 0 && found==1 )
		strcpy(acIMSIDB, dummy);
	else
	{
		Display_Message(1, "INI file incomplete: missing parameter [DATABASE]IMSI_DB");
		return(0);
	}

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	/* OPERATION */
	if ( (wrk_str = cgi_param( "OPERATION" ) ) == NULL )
	{
		Display_Message(-1, "OPERATION");
		return(0);
	}

	if (!strcmp(wrk_str, "LIST"))
	{
		Lista_Rec();
	}
	else if (!strcmp(wrk_str, "VISUALIZZA"))
	{
		Visu_Canc_Rec(VISU_REC);
	}
	else if (!strcmp(wrk_str, "CHKDEL"))
	{
		Check_Canc_Rec();
	}
	else if (!strcmp(wrk_str, "DELETE"))
	{
		Visu_Canc_Rec(DELETE_REC);
	}
	else if (!strcmp(wrk_str, "INSERT_DB"))
	{
		Ins_Upd_Rec(NEW_REC);
	}
	else if (!strcmp(wrk_str, "UPDATE_DB"))
	{
		Ins_Upd_Rec(UPD_REC);
	}
	else
	{
		Lista_Rec();
	}

	exit(0);
}

/******************************************************************************/
/* LISTA_REC      *************************************************************/
/******************************************************************************/
void Lista_Rec(void)
{
	char	*wrk_str;
	char	sTmp[128];
	char	stringa[64];
	char	acHSSdescr[260];
	short  	handle = -1;
	short  	conta = 0;
	int    	errO;
	int    	cc;
	long long	LOCAL_TS;
	HSS_RECORD	dbrec;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(HSS_RECORD));
	memset(acHSSdescr, 0x00, sizeof(acHSSdescr));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "HSSDESCR" ) ) != NULL )
		strcpy(acHSSdescr, wrk_str);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acHSSDB, &handle);

	if (errO == 0)
	{
		/*******************
		* imposta chiave
		*******************/
		// alternata (1), approssimata (0)
		cc = MBE_FILE_SETKEY_ (handle, acHSSdescr, hssdb_altkey_len, 1, 0);

		/* check setkey: errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
		}
		/* tutto ok */
		else
		{
			Display_Top(NEW_REC);

			printf("<font face='Arial, Helvetica, sans-serif'>								\n");
			printf("<center>																\n");

			printf("<BR><BR> <big>HSS nodes</big> <BR><BR><BR>								\n");

			// FORM per INSERIMENTO nuovo record
			printf("<fieldset style='display: inline'>															\n");
			printf("	<legend> <b>Add new node</b> </legend>													\n");
			printf("	<FORM name='frmSubmission' METHOD=POST ACTION='hssdb.cgi' onsubmit='return CtrlName()'>	\n");
			printf("		<INPUT TYPE='hidden' name='OPERATION' value='INSERT_DB'>							\n");
			printf("		Host name <INPUT TYPE='text' NAME='HSSDESCR' VALUE='%s' SIZE='64' MAXLENGTH='256'>	\n", acHSSdescr);
			printf("		<input TYPE='submit' VALUE='Add'>													\n");
			printf("	</FORM>																					\n");
			printf("</fieldset>																					\n");
			printf("<BR><BR>																					\n");

			// FORM per RICERCA record
			printf("<fieldset style='display: inline'>															\n");
			printf("	<legend> <b>Search node</b> </legend>													\n");
			printf("	<FORM name='frmSearch' METHOD=POST ACTION='hssdb.cgi'>									\n");
			printf("		<INPUT TYPE='hidden' name='OPERATION' value='LIST'>									\n");
			printf("		Host name <INPUT TYPE='text' NAME='HSSDESCR' SIZE='64' MAXLENGTH='256'>				\n");
			printf("		<input TYPE='submit' VALUE='Find'>													\n");
			printf("	</FORM>																					\n");
			printf("</fieldset>																					\n");
			printf("<BR><BR>																					\n");

			printf("<TABLE border=1 frame=void>												\n");
			printf("	<TR bgcolor='#C0C0C0'>												\n");
			printf("  		<TH> Host Name </TH>											\n");
			printf("  		<TH> Insert time </TH>											\n");
			printf("  		<TH> Update time </TH>											\n");
			printf("	</TR>																\n");

			/* cicla per max 50 record */
			while (conta < 50)
			{
				/*******************
				* Leggo il record
				*******************/
				/* Leggo un record */
				cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );

				/* errore... */
				if ( cc != 0 )
				{
					/* errore */
					if (cc != 1)
					{
						sprintf(sTmp, "Readx: error %d", cc);
						Display_Message(1, sTmp);
					}

					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					conta++;

					/*******************
					* Scrive il record a video
					*******************/
					printf("<TR>													\n");
					printf("  <TD>&nbsp; %.64s &nbsp;</TD>							\n", dbrec.hostname);
						LOCAL_TS = CONVERTTIMESTAMP(dbrec.insert_ts);
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", timestamp2string(stringa, LOCAL_TS));
						LOCAL_TS = CONVERTTIMESTAMP(dbrec.update_ts);
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", timestamp2string(stringa, LOCAL_TS));

			        printf("  <TD><IMG src='images/view.gif' alt='Details' onclick=VaiA('hssdb.cgi?OPERATION=VISUALIZZA&HSSID=%u')></IMG></TD>  \n", dbrec.hss_id);
			        printf("  <TD><IMG src='images/del.gif' alt='Delete' onclick=Cancella('hssdb.cgi?OPERATION=CHKDEL&HSSID=%u&HSSDESCR=%.30s')></IMG></TD>  \n", dbrec.hss_id, dbrec.hostname);
			        printf("  <TD><INPUT TYPE='button' VALUE='IMSI' onclick=VaiA('imsidb.cgi?OPERATION=LIST&SEARCHBY=A&HSSID=%u')></IMG></TD>  \n", dbrec.hss_id);
					printf("</TR>													\n");
				}
			}/* while */

			printf("</TABLE>											\n");
			printf("<BR><BR>											\n");

			printf("<hr color='#000080'>								\n");
			printf("   <INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>	\n");

			if ( conta >= 50 )
			{
				printf("   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;											\n");
				printf("   <INPUT TYPE='button' VALUE='Next Page >>' onclick=VaiA('hssdb.cgi?OPERATION=LIST&HSSDESCR=%s')></IMG></TD>  \n" , dbrec.hostname);
			}
			printf("<hr color='#000080'>								\n");

			printf("</CENTER>											\n");

			Display_Bottom();
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/******************************************************************************/
/* Visu_Canc_Rec    ************************************************************/
/******************************************************************************/
void Visu_Canc_Rec(short CosaFare)
{
	char  	*wrk_str;
	char  	sTmp[180];
	char	stringa[64];
	unsigned short usID = 0;
	short 	handle = -1;
	int   	errO;
	int   	cc;
	long long	LOCAL_TS;
	HSS_RECORD	dbrec;

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "HSSID" ) ) != NULL )
	{
		usID = (unsigned short)atoi(wrk_str);
	}
	else
	{
		Display_Message(-1, "HSSID");
		return;
	}

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acHSSDB, &handle);

	if (errO == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		/* ricerca primaria (0) esatta (2) */
		cc = MBE_FILE_SETKEY_ (handle, (char *)&usID, sizeof(usID), 0, 2);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
		}
		/* tutto ok */
		else
		{
			/* Leggo il record */
			if (CosaFare == DELETE_REC)
				cc = MBE_READLOCKX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );
			else
				cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );

			/* errore... */
			if ( cc != 0 )
			{
				/* errore */
				if (cc != 1)
				{
					sprintf(sTmp, "Readx: error %d", cc);
				}
				/* non trovato */
				else
				{
					sprintf(sTmp, "HSS (ID %u) <BR><BR> NOT found", usID);
				}

				Display_Message(1, sTmp);
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				//-----------------
				// CANCELLAZIONE
				//-----------------
				if (CosaFare == DELETE_REC)
				{
					/* Cancello il record */
					cc = MBE_WRITEUPDATEUNLOCKX( handle, "", 0 );

					/* errore... */
					if ( cc != 0 )
					{
						MBE_UNLOCKREC(handle);

						sprintf(sTmp, "WriteUpdatex: error %d", cc);
						Display_Message(1, sTmp);
					}
					else
					{
						Display_Top(NOTHING);

						printf("<center>																		\n");
						printf("<font face='Arial, Helvetica, sans-serif'>										\n");

						printf("<BR><BR> <big>HSS</big> <BR><BR><BR>											\n");

						printf("<big>																			\n");
						printf("<BR> HSS %.64s <BR>																\n", dbrec.hostname);
						printf("<BR>succesfully deleted<BR><BR>													\n");
						printf("</big>																			\n");
						printf("<hr color='#000080'>															\n");
						printf("<INPUT TYPE='button' VALUE='Hosts List' onclick=VaiA('hssdb.cgi?OPERATION=LIST')>\n");
						printf("<hr color='#000080'>															\n");
						printf("</font></center>																\n");

						Display_Bottom();
					}
				}
				//-----------------
				// VISUALIZZAZIONE
				//-----------------
				else
				{
					Display_Top(VISU_REC);

					printf("<center>																		\n");
					printf("<font face='Arial, Helvetica, sans-serif'>										\n");

					printf("<BR><BR> <big>HSS</big> <BR><BR><BR>											\n");

					printf("<FORM name='frmSubmission' METHOD=POST ACTION='hssdb.cgi' onsubmit='return CtrlName()'>	\n");
					printf("	<INPUT TYPE='hidden' name='OPERATION' value='UPDATE_DB'>					\n");
					printf("	<INPUT TYPE='hidden' name='HSSID' value='%u'>								\n", dbrec.hss_id);

					printf("	<TABLE border=0>															\n");
					printf("		<TR align=left height=40>												\n");
					printf("			<TH> Host Name </TH>												\n");
					printf("			<TD><TEXTAREA NAME='HSSDESCR' ROWS='4' COLS='64' MAXLENGTH='255'>%s</TEXTAREA></TD> \n", dbrec.hostname);
					printf("		</TR>																	\n");
					printf("	</TABLE>																	\n");
					printf("	<BR>																		\n");

						LOCAL_TS = CONVERTTIMESTAMP(dbrec.insert_ts);
					printf("	<b> Insert time </b> %s 													\n", timestamp2string(stringa, LOCAL_TS));
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;												\n");
						LOCAL_TS = CONVERTTIMESTAMP(dbrec.update_ts);
					printf("	<b> Update time </b> %s														\n", timestamp2string(stringa, LOCAL_TS));
					printf("	<BR><BR>																	\n");

					printf("	<hr color='#000080'>														\n");
					printf("	<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>	\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;												\n");
					printf("	<input TYPE='submit' VALUE='Save'>											\n");
					printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;												\n");
					printf("	<INPUT TYPE='button' VALUE='Delete' onclick=Cancella('hssdb.cgi?OPERATION=CHKDEL&HSSID=%u&HSSDESCR=%.30s')> \n", dbrec.hss_id, dbrec.hostname);
					printf("	<hr color='#000080'>														\n");
					printf("</FORM>																			\n");

					Display_Bottom();
				}
			}
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/*****************************************************************************/
/* Ins_Upd_Rec      **********************************************************/
/*****************************************************************************/
void Ins_Upd_Rec(short CosaFare)
{
	char   *wrk_str;
	char   sTmp[128];
	unsigned short usID = 0;
	unsigned short usConta = 0;
	short  handle = -1;
	short  tuttoOK = 1;
	int    errO;
	int    cc;
	long long 		llAdesso;
	HSS_RECORD	dbrec;
	HSS_RECORD	dbrec_old;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(HSS_RECORD));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if (CosaFare == UPD_REC)
	{
		if ( (wrk_str = cgi_param( "HSSID" ) ) != NULL )
		{
			usID = (unsigned short)atoi(wrk_str);
			dbrec.hss_id = usID;
		}
		else
		{
			Display_Message(-1, "HSSID");
			return;
		}
	}

	if ( (wrk_str = cgi_param( "HSSDESCR" ) ) != NULL )
		strcpy(dbrec.hostname, wrk_str);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acHSSDB, &handle);

	if (errO == 0)
	{
		if (CosaFare == NEW_REC)
			srand(time(NULL));	// inizializza random

		// il ciclo serve per calcolare un nuovo HSS ID in caso di chiave duplicata
		while (1)
		{
			if (CosaFare == NEW_REC)
				usID = (unsigned short)(rand()%65535);	// setta un ID random

			/*******************
			* Cerco il record
			*******************/
			/* ricerca primaria (0) esatta (2) */
			cc = MBE_FILE_SETKEY_ (handle, (char *)&usID, sizeof(usID), 0, 2);

			/* errore */
			if (cc != 0)
			{
				sprintf(sTmp, "File_setkey: error %d", cc);
				Display_Message(1, sTmp);
				tuttoOK = 0;
				break;
			}
			/* tutto ok */
			else
			{
				/* Leggo il record */
				cc = MBE_READX( handle, (char *)&dbrec_old, (short)sizeof(HSS_RECORD) );

				/* errore */
				if (cc != 0 && cc != 1)
				{
					sprintf(sTmp, "Readx: error %d", cc);
					Display_Message(1, sTmp);
					tuttoOK = 0;
				}

				/* record non trovato ed è un aggiornamento */
				if (cc == 1 && CosaFare == UPD_REC )
				{
					sprintf(sTmp, "HSS %.64s (%u)<BR><BR>not found", dbrec.hostname, usID);
					Display_Message(1, sTmp);
					tuttoOK = 0;
				}

				/* record trovato ed è un inserimento */
				if (cc == 0 && CosaFare == NEW_REC)
				{
					usConta++;

					if (usConta < 32767)
						continue;			// calcola nuovo ID
					else
					{
						sprintf(sTmp, "No more keys available<BR><BR>HSS cannot be added");
						Display_Message(1, sTmp);
						tuttoOK = 0;
					}
				}

				break;
			}
		} // while

		/********************/
		/* se può procedere */
		/********************/
		if (tuttoOK)
		{
			llAdesso = JULIANTIMESTAMP(0);

			/* inserimento */
			if (CosaFare == NEW_REC)
			{
				// imposta l'ID valido calcolato in precedenza
				dbrec.hss_id = usID;

				// imposta i timestamp
				dbrec.insert_ts = llAdesso;
				dbrec.update_ts = llAdesso;

				cc = MBE_WRITEX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );
				strcpy(sTmp, "inserted");
			}
			/* aggiornamento */
			else
			{
				// imposta i timestamp
				dbrec.insert_ts = dbrec_old.insert_ts;
				dbrec.update_ts = llAdesso;

				// riporta il filler
				memcpy(dbrec.filler, dbrec_old.filler, sizeof(dbrec.filler));

				cc = MBE_WRITEUPDATEX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );
				strcpy(sTmp, "updated");
			}

			/* errore... */
			if ( cc != 0 )
			{
				sprintf(sTmp, "Writex: error %d", cc);
				Display_Message(1, sTmp);
			}
			else
			{
				Display_Top(NOTHING);

				printf("<center>																		\n");
				printf("<font face='Arial, Helvetica, sans-serif'>										\n");

				printf("<BR><BR> <big>HSS</big> <BR><BR><BR>											\n");

				printf("<big>																			\n");
				printf("<BR>Host %.64s<BR>																\n", dbrec.hostname);
				printf("<BR>succesfully %s<BR><BR>														\n", sTmp);
				printf("</big>																			\n");

				printf("<hr color='#000080'>															\n");
				printf("<INPUT TYPE='button' VALUE='View Host' onclick=VaiA('hssdb.cgi?OPERATION=VISUALIZZA&HSSID=%u')></IMG></TD>  \n", usID);
				printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;													\n");
				printf("<INPUT TYPE='button' VALUE='Hosts List' onclick=VaiA('hssdb.cgi?OPERATION=LIST')>\n");
				printf("<hr color='#000080'>															\n");
				printf("</font></center>																\n");

				Display_Bottom();
			}
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/********************************************************************************/
/* Controlla se ci sono IMSI che usano l'HSS che si vuole cancellare			*/
/* Se ci sono chiede conferma													*/
/* Qualsiasi errore causa comunque la cancellazione								*/
/********************************************************************************/
void Check_Canc_Rec(void)
{
	char	*wrk_str;
	char	acDescr[32];
	unsigned short	usID=0;
	short   Cancella=1;
	short  	handle = -1;
	int    	errO;
	int    	cc;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(IMSI_RECORD));
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/* legge parametri */
	if ( (wrk_str = cgi_param( "HSSID" ) ) != NULL )
		usID = (unsigned short)atoi(wrk_str);

	if ( (wrk_str = cgi_param( "HSSDESCR" ) ) != NULL )
		strcpy(acDescr, wrk_str);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		/*******************
		* imposta chiave
		*******************/
		// alternata (1), generica (1)
		cc = MBE_FILE_SETKEY_ (handle, (char *)&usID, sizeof(usID), 1, 1);

		/* tutto ok */
		if (cc == 0)
		{
			/*******************
			* Leggo il record
			*******************/
			/* Leggo un record */
			cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

			/* record TROVATO */
			if ( cc == 0 )
			{
				Display_Top(NOTHING);

				printf("<center>																		\n");
				printf("<font face='Arial, Helvetica, sans-serif'>										\n");

				printf("<BR><BR> <big>HSS</big> <BR><BR><BR>											\n");

				printf("<big>																			\n");
				printf("<BR>HSS '%s'<BR>																\n", acDescr);
				printf("<BR>is used by one or more IMSI range<BR><BR>									\n");
				printf("<font color='#cc0000'><b>														\n");
				printf("<BR>Do you really want to delete it?<BR><BR>									\n");
				printf("</b></font>																		\n");
				printf("</big>																			\n");
				printf("<FORM METHOD=POST ACTION='hssdb.cgi'>											\n");
				printf("	<INPUT TYPE='hidden' name='OPERATION' value='DELETE'>						\n");
				printf("	<INPUT TYPE='hidden' name='HSSID' value='%u'>								\n", usID);
				printf("	<hr color='#000080'>														\n");
				printf("	<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>	\n");
				printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;												\n");
				printf("	<INPUT TYPE='submit' VALUE='OK, delete it'>									\n");
				printf("	<hr color='#000080'>														\n");
				printf("</FORM>																			\n");
				printf("</font></center>																\n");

				Display_Bottom();

				// non procede subito alla cancellazione ma attende input utente dal form appena creato
				Cancella=0;
			}
		}

		MBE_FILE_CLOSE_(handle);
	}

	// se deve cancellare, cancella
	if (Cancella)
		Visu_Canc_Rec(DELETE_REC);

	return;
}

/******************************************************************************/
/* APRI_FILE	  *************************************************************/
/******************************************************************************/
int Apri_File(char *nomefile, short *handle)
{
	short localhandle = -1;
	int   errO;
	char  sTmp[128];

	errO = MBE_FILE_OPEN_( nomefile, (short)strlen(nomefile), &localhandle);

	/* errore */
	if (errO != 0)
	{
		sprintf(sTmp, "Error %d opening %s", errO, nomefile);
		Display_Message(1, sTmp);
	}
	else
		*handle = localhandle;

	return(errO);
}

/******************************************************************************/
/* DISPLAY_TOP    *************************************************************/
/******************************************************************************/
void Display_Top(short tipo)
{
	printf("Content-type: text/html\n\n");
	printf("<html>																			\n");
	printf("<head>																			\n");
	printf("	<title></title>																\n");
	printf("	<style type='text/css'>														\n");
	printf("    	@import url(text.css);													\n");
	printf("	</style>																	\n");
	printf("	<script>																	\n");
	printf("          function VaiA(NewUrl)													\n");
	printf("          {																		\n");
	printf("             location=NewUrl;													\n");
	printf("          }																		\n");
	printf("          function Cancella(NewUrl)												\n");
	printf("          {																		\n");
	printf("             scelta = confirm('This data will be deleted. Continue?');			\n");
	printf("             if (scelta == true)												\n");
	printf("             {																	\n");
	printf("                location=NewUrl;												\n");
	printf("             }																	\n");
	printf("          }																		\n");

	if (tipo == NEW_REC || tipo == VISU_REC)
	{
		printf("        function CtrlName()													\n");
		printf("        {																	\n");
		printf("			if (document.frmSubmission.HSSDESCR.value.length == 0)			\n");
		printf("			{																\n");
		printf("				alert('Insert Host Name');									\n");
		printf("				document.frmSubmission.HSSDESCR.focus();					\n");
		printf("				return false;												\n");
		printf("			}																\n");
		if (tipo == VISU_REC)
		{
			printf("			if (document.frmSubmission.HSSDESCR.value.length > 255)			\n");
			printf("			{																\n");
			printf("				alert('Host Name max length is 255 characters');			\n");
			printf("				document.frmSubmission.HSSDESCR.focus();					\n");
			printf("				return false;												\n");
			printf("			}																\n");
		}
		printf("			return true;													\n");
		printf("        }																	\n");
	}

	printf("      </script>																	\n");
	printf("</head>																			\n");
	printf("<body style='cursor: wait'>														\n");
	printf("<NOSCRIPT><font face='Verdana' size='1'>Javascript not supported by your browser</font></NOSCRIPT>	\n");
}

/******************************************************************************/
/* DISPLAY_BOTTOM *************************************************************/
/******************************************************************************/
void Display_Bottom(void)
{
	printf("   <SCRIPT LANGUAGE='JavaScript'>				\n");
	printf("      document.body.style.cursor='default';		\n");
	printf("   </SCRIPT>									\n");
	printf("</body>			\n");
	printf("</html>			\n");
}

/******************************************************************************/
/* DISPLAY_MESSAGE ************************************************************/
/******************************************************************************/
void Display_Message(int nTipo, char *sMessaggio)
{
	Display_Top(NOTHING);

	printf("<center>															\n");
	printf("<BR><BR>															\n");
	printf("<font face='Arial, Helvetica, sans-serif'>							\n");
	printf("	<big>SYSTEM MESSAGE</big><br>									\n");
	printf("</font>																\n");
	printf("<BR><BR>															\n");

	switch ( nTipo  )
	{
		/* manca parametro */
		case -1:
		{
			printf("Parameter %s is missed<BR>			\n", sMessaggio);
			break;
		}

		/* messaggio */
		case 1:
		{
			printf("%s <BR><BR>							\n", sMessaggio);
			printf("<hr size='2' color='#000080'>		\n");
			printf("<input TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'> \n");
			printf("<hr size='2' color='#000080'>		\n");

			break;
		}

		default:
		{
			break;
		}
	}  /* switch */

	printf("</center>				\n");

	Display_Bottom();

	fflush(stdout);
}
