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
void  Visu_Rec(void);
void  Canc_Rec(void);
void  Ins_Upd_Rec(short CosaFare);
void  Check_Insert(void);
void  Check_Update(void);
void  Display_Record(short CosaFare, char *record);
void  GetInfoRec(short handle, char *acLunghezze);
void  UpdInfoRec_Del(short handle, unsigned short usLen);
void  UpdInfoRec_Ins(short handle, unsigned short usLen);
void  GetHSSname(unsigned short usID, char *acHSSdescr, short handle);
void  ListAllHSS(unsigned short usID);
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
	/* LETTURA NOMI DB da INI	  */
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
		Visu_Rec();
	}
	else if (!strcmp(wrk_str, "DELETE"))
	{
		Canc_Rec();
	}
	else if (!strcmp(wrk_str, "MAKE_NEW"))
	{
		Display_Record(NEW_REC, " ");
	}
	else if (!strcmp(wrk_str, "CHECK_INSERT"))
	{
		Check_Insert();
	}
	else if (!strcmp(wrk_str, "CHECK_UPDATE"))
	{
		Check_Update();
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
	char	cSearch;
	unsigned short	usID=0;
	short  	handle = -1, handle_hss = -1;
	short  	conta = 0;
	short	MAX_PER_PAGE = 50;
	int    	errO;
	int    	cc;
	long long	LOCAL_TS;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(IMSI_RECORD));
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));
	memset(acHSSdescr, 0x00, sizeof(acHSSdescr));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			  */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "SEARCHBY" ) ) != NULL )
		cSearch = wrk_str[0];
	else
		cSearch = 'P';	// defaul = 'P'rimary key

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		/*******************
		* imposta chiave
		*******************/
		if (cSearch == 'P')
		{
			if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
			{
				strcpy(PKey.range_end ,wrk_str);
				PKey.range_len = (unsigned short)strlen(PKey.range_end);
			}
			else
				PKey.range_len = 1;	// salta lo 0 perchè è il rec riservato con le info sul contenuto del DB

			// primaria (0), approssimata (0)
			cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 0);
		}
		else
		{
			if ( (wrk_str = cgi_param( "HSSID" ) ) != NULL )
				usID = (unsigned short)atoi(wrk_str);
			else
			{
				Display_Message(-1, "HSSID");
				return;
			}

			MAX_PER_PAGE = 200;

			// alternata (1), generica (1)
			cc = MBE_FILE_SETKEY_ (handle, (char *)&usID, sizeof(usID), 1, 1);
		}

		/* check setkey: errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
		}
		/* tutto ok */
		else
		{
			Display_Top(NOTHING);

			printf("<font face='Arial, Helvetica, sans-serif'>								\n");
			printf("<center>																\n");

			printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>									\n");

			// FORM per RICERCA record
			printf("<fieldset style='display: inline'>															\n");
			printf("	<legend> <b>Search IMSI</b> </legend>													\n");
			printf("	<FORM name='frmSearch' METHOD=POST ACTION='imsidb.cgi'>									\n");
			printf("		<INPUT TYPE='hidden' name='OPERATION' value='VISUALIZZA'>							\n");
			printf("		IMSI <INPUT TYPE='text' NAME='IMSIEND' SIZE='20' MAXLENGTH='16'>					\n");
			printf("		<input TYPE='submit' VALUE='Find'>													\n");
			printf("	</FORM>																					\n");
			printf("</fieldset>																					\n");
			printf("<BR><BR>																					\n");

			if (cSearch == 'A')
			{
				// recupera host name da HSS DB
				GetHSSname(usID, acHSSdescr, 0);

				printf("IMSI related to HSS Host <b>%.64s</b>										\n", acHSSdescr);
			}
			else
			{
				// Apro il file HSS DB
				errO = Apri_File(acHSSDB, &handle_hss);

				if (errO != 0)
				{
					handle_hss = -1;
					sprintf(acHSSdescr, "error %d - cannot retrieve Host Name", errO);
				}

				if ( PKey.range_end[0] != 0 )
					printf("List from IMSI <b>%s</b>", PKey.range_end);
			}

			printf("<TABLE border=1 frame=void>												\n");
			printf("	<TR bgcolor='#C0C0C0'>												\n");
			printf("  		<TH> from IMSI </TH>											\n");
			printf("  		<TH> to IMSI </TH>												\n");
			printf("  		<TH> Length </TH>												\n");
			if (cSearch == 'P')
				printf("  		<TH> HSS Host Name </TH>										\n");
			printf("  		<TH> Insert time </TH>											\n");
			printf("  		<TH> Update time </TH>											\n");
			printf("	</TR>																\n");

			/* cicla per MAX_PER_PAGE record */
			while (conta < MAX_PER_PAGE)
			{
				/*******************
				* Leggo il record
				*******************/
				/* Leggo un record */
				cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

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
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", dbrec.range_ini);
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", dbrec.pkey.range_end);
					printf("  <TD>&nbsp; %u &nbsp;</TD>								\n", dbrec.pkey.range_len);

					if (cSearch == 'P')
					{
						if (handle_hss != -1)
						{
							// recupera host name da HSS DB
							GetHSSname(dbrec.hss_id, acHSSdescr, handle_hss);
						}

						printf("  <TD>&nbsp; %.64s &nbsp;</TD>							\n", acHSSdescr);
					}

						LOCAL_TS = CONVERTTIMESTAMP(dbrec.insert_ts);
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", timestamp2string(stringa, LOCAL_TS));
						LOCAL_TS = CONVERTTIMESTAMP(dbrec.update_ts);
					printf("  <TD>&nbsp; %s &nbsp;</TD>								\n", timestamp2string(stringa, LOCAL_TS));

			        printf("  <TD><IMG src='images/view.gif' alt='Details' onclick=VaiA('imsidb.cgi?OPERATION=VISUALIZZA&IMSIEND=%s')></IMG></TD>	\n", dbrec.pkey.range_end);
			        printf("  <TD><IMG src='images/del.gif' alt='Delete' onclick=Cancella('imsidb.cgi?OPERATION=DELETE&IMSIEND=%s')></IMG></TD> 		\n", dbrec.pkey.range_end);
					printf("</TR>													\n");
				}
			}/* while */

			printf("</TABLE>											\n");

			if ( conta >= MAX_PER_PAGE && cSearch == 'A')
				printf("<BR>There are more IMSI range for this HSS Host	\n");

			printf("<BR><BR>											\n");

			printf("<hr color='#000080'>								\n");
			printf("   <INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>	\n");
			printf("   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;												\n");
			printf("   <INPUT TYPE='button' VALUE='Add new' onclick=VaiA('imsidb.cgi?OPERATION=MAKE_NEW')></IMG></TD>  \n");

			if ( conta >= MAX_PER_PAGE && cSearch == 'P' )
			{
				printf("   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;											\n");
				printf("   <INPUT TYPE='button' VALUE='Next Page >>' onclick=VaiA('imsidb.cgi?OPERATION=LIST&SEARCHBY=P&IMSIEND=%s')></IMG></TD>  \n" , dbrec.pkey.range_end);
			}
			printf("<hr color='#000080'>								\n");

			printf("</CENTER>											\n");

			Display_Bottom();

			if ( cSearch == 'P' && handle_hss != -1 )
				MBE_FILE_CLOSE_(handle_hss);
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/******************************************************************************/
/* Visu_Rec    ****************************************************************/
/******************************************************************************/
void Visu_Rec(void)
{
	char  	*wrk_str;
	char  	sTmp[180];
	char	acIMSI[20];
	char	acLunghezze[20];
	short   trovato=0, i;
	short   IMSIlen=0;
	short 	handle = -1;
	int   	errO;
	int   	cc;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	memset(acIMSI, 0x00, sizeof(acIMSI));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
	{
		strcpy(acIMSI ,wrk_str);
		IMSIlen = (short)strlen(acIMSI);
	}

	if (IMSIlen == 0)
	{
		Lista_Rec();
		return;
	}

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		// recupera info del record di testa
		GetInfoRec(handle, acLunghezze);

		// ciclo sulle possibili lunghezze dei range
		for (i=IMSIlen; i>0; i--)
		{
			if (acLunghezze[i] == 1)
			{
				memset(&PKey, 0x00, sizeof(IMSI_PKEY));

				/*******************
				* Imposta chiave
				*******************/
				PKey.range_len = i;
				memcpy(PKey.range_end, acIMSI, PKey.range_len);

				/*******************
				* Cerco il record
				*******************/
				/* ricerca primaria (0) approssimata (0) */
				cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 0);

				/* errore */
				if (cc != 0)
				{
					sprintf(sTmp, "File_setkey: error %d", cc);
					Display_Message(1, sTmp);

					trovato = -1;
					break;
				}
				/* tutto ok */
				else
				{
					cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

					/* errore... */
					if ( cc != 0 )
					{
						/* errore */
						if (cc != 1)
						{
							sprintf(sTmp, "Readx: error %d", cc);

							trovato = -1;
							break;
						}

						// se non lo trova (cc==1) fa un altro giro con il for
					}
					/* record TROVATO */
					else  /* readx ok */
					{
						// a questo punto siamo sicuri che il RANGE END trovato sia >= alla chiave cercata
						// in quanto abbiamo fatto una ricerca approssimata.
						// Si deve verificare che:
						//    1) La lunghezza range trovata sia la stessa cercata
						//    2) la chiave cercata sia compresa nel range (RANGE INI minore o uguale alla chiave cercata)
						if ( (dbrec.pkey.range_len == PKey.range_len) && (memcmp(dbrec.range_ini, PKey.range_end, PKey.range_len) <= 0) )
						{
							trovato = 1;

							// visualizza record
							Display_Record(UPD_REC, (char *)&dbrec);

							break;
						}
						// se non è nel range fa un altro giro con il for
					}
				}
			}
		}

		// non ha trovato l'imsi in nessun range
		if ( trovato == 0 )
		{
			Display_Top(NOTHING);

			printf("<center>																		\n");
			printf("<font face='Arial, Helvetica, sans-serif'>										\n");

			printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

			printf("<big>																			\n");
			printf("<BR> IMSI %s <BR>																\n", acIMSI);
			printf("<BR>not found<BR><BR>															\n");
			printf("</big>																			\n");
			printf("<hr color='#000080'>															\n");
			printf("<INPUT TYPE='button' VALUE='List' onclick=VaiA('imsidb.cgi?OPERATION=LIST&IMSIEND=%s')>	\n", acIMSI);
			printf("<hr color='#000080'>															\n");
			printf("</font></center>																\n");

			Display_Bottom();
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/******************************************************************************/
/* Canc_Rec    ****************************************************************/
/******************************************************************************/
void Canc_Rec(void)
{
	char  	*wrk_str;
	char  	sTmp[180];
	short 	handle = -1;
	int   	errO;
	int   	cc;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
	{
		strcpy(PKey.range_end ,wrk_str);
		PKey.range_len = (unsigned short)strlen(PKey.range_end);
	}
	else
	{
		Display_Message(-1, "IMSIEND");
		return;
	}

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		/* ricerca primaria (0) esatta (2) */
		cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 2);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
		}
		/* tutto ok */
		else
		{
			cc = MBE_READLOCKX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

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
					sprintf(sTmp, "IMSI %s <BR><BR> NOT found", PKey.range_end);
					Display_Message(1, sTmp);
				}
			}
			/* record TROVATO */
			else  /* readx ok */
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

					printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

					printf("<big>																			\n");
					printf("<BR> IMSI %s <BR>																\n", PKey.range_end);
					printf("<BR>succesfully deleted<BR><BR>													\n");
					printf("</big>																			\n");
					printf("<hr color='#000080'>															\n");
					printf("<INPUT TYPE='button' VALUE='List' onclick=VaiA('imsidb.cgi?OPERATION=LIST')>	\n");
					printf("<hr color='#000080'>															\n");
					printf("</font></center>																\n");

					Display_Bottom();

					// controlla ed aggiorna le INFO nel record 0 (zero)
					UpdInfoRec_Del(handle, PKey.range_len);
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
	short  handle = -1;
	short  tuttoOK = 1;
	int    errO;
	int    cc;
	long long 	llAdesso;
	IMSI_RECORD	dbrec;
	IMSI_RECORD	dbrec_old;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(IMSI_RECORD));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "IMSIINI" ) ) != NULL )
		strcpy(dbrec.range_ini, wrk_str);

	if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
		strcpy(dbrec.pkey.range_end, wrk_str);

	if ( (wrk_str = cgi_param( "HSSID" ) ) != NULL )
		dbrec.hss_id = (unsigned short)atoi(wrk_str);

	dbrec.pkey.range_len = (unsigned short)strlen(dbrec.pkey.range_end);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		/*******************
		* Cerco il record
		*******************/
		/* ricerca primaria (0) esatta (2) */
		cc = MBE_FILE_SETKEY_ (handle, (char *)&dbrec.pkey, sizeof(IMSI_PKEY), 0, 2);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
			tuttoOK = 0;
		}
		/* tutto ok */
		else
		{
			/* Leggo il record */
			cc = MBE_READX( handle, (char *)&dbrec_old, (short)sizeof(IMSI_RECORD) );

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
				sprintf(sTmp, "IMSI %s<BR><BR>not found", dbrec.pkey.range_end);
				Display_Message(1, sTmp);
				tuttoOK = 0;
			}

			/* record trovato ed è un inserimento */
			if (cc == 0 && CosaFare == NEW_REC)
			{
				sprintf(sTmp, "IMSI %s<BR><BR>already exists", dbrec.pkey.range_end);
				Display_Message(1, sTmp);
				tuttoOK = 0;
			}
		}

		/********************/
		/* se può procedere */
		/********************/
		if (tuttoOK)
		{
			llAdesso = JULIANTIMESTAMP(0);

			/* inserimento */
			if (CosaFare == NEW_REC)
			{
				// imposta i timestamp
				dbrec.insert_ts = llAdesso;
				dbrec.update_ts = llAdesso;

				cc = MBE_WRITEX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );
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

				cc = MBE_WRITEUPDATEX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );
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

				printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

				printf("<big>																			\n");
				printf("<BR>IMSI %s<BR>																	\n", dbrec.pkey.range_end);
				printf("<BR>succesfully %s<BR><BR>														\n", sTmp);
				printf("</big>																			\n");

				printf("<hr color='#000080'>															\n");
				printf("<INPUT TYPE='button' VALUE='View IMSI' onclick=VaiA('imsidb.cgi?OPERATION=VISUALIZZA&IMSIEND=%s')></IMG></TD>  \n", dbrec.pkey.range_end);
				printf("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;													\n");
				printf("<INPUT TYPE='button' VALUE='IMSI List' onclick=VaiA('imsidb.cgi?OPERATION=LIST')>\n");
				printf("<hr color='#000080'>															\n");
				printf("</font></center>																\n");

				Display_Bottom();

				/* inserimento */
				if (CosaFare == NEW_REC)
				{
					// aggiorna le INFO nel record 0 (zero)
					UpdInfoRec_Ins(handle, dbrec.pkey.range_len);
				}
			}
		}

		MBE_FILE_CLOSE_(handle);
	}

	return;
}

/******************************************************************************/
/* Verifica che, in fase di INSERT, il range non si overlappi con altri range */
/* Per INSERT verifica sia IMSI INI che IMSI END                              */
/******************************************************************************/
void Check_Insert(void)
{
	char   *wrk_str;
	char   sTmp[128];
	char   			range_ini[20];
	char   			range_end[20];
	unsigned short	range_len;
	short  handle = -1;
	short  tuttoOK = 1, i;
	int    errO;
	int    cc;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(IMSI_RECORD));
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "IMSIINI" ) ) != NULL )
		strcpy(range_ini, wrk_str);

	if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
		strcpy(range_end, wrk_str);

	range_len = (unsigned short)strlen(range_end);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		// Lunghezza chiave
		PKey.range_len = range_len;

		// cicla 2 volte per la END e l'INI del range
		for (i=0; i<=1; i++)
		{
			/*---------------------------*/
			/* IMPOSTA CHIAVE			 */
			/*---------------------------*/
			if (i==0)
				strcpy(PKey.range_end, range_end);	// check su END Range
			else
				strcpy(PKey.range_end, range_ini);	// check su INI Range

			/*******************
			* Cerco il record
			*******************/
			/* ricerca primaria (0) approssimata (0) */
			cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 0);

			/* errore */
			if (cc != 0)
			{
				sprintf(sTmp, "File_setkey: error %d", cc);
				Display_Message(1, sTmp);
				tuttoOK = 0;
			}

			/* tutto ok */
			else
			{
				/* Leggo il record */
				cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

				/* errore */
				if (cc != 0 && cc != 1)
				{
					sprintf(sTmp, "Readx: error %d", cc);
					Display_Message(1, sTmp);
					tuttoOK = 0;
				}

				/* record trovato */
				if (cc == 0)
				{
					// se siamo nella stessa lunghezza range cercata
					// (se va oltre non c'è di sicuro sovrapposizione)
					if (dbrec.pkey.range_len == range_len)
					{
						//************************
						// check su END Range
						//************************
						if (i==0)
						{
							// se l'INI trovato è minore o uguale della END del NUOVO
							if ( memcmp(dbrec.range_ini, range_end, range_len) <= 0 )
							{
								// non va bene, c'è sovrapposizione.
								// END da inserire cade in mezzo al range trovato

								Display_Top(NOTHING);

								printf("<center>																		\n");
								printf("<font face='Arial, Helvetica, sans-serif'>										\n");

								printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

								printf("<big>																			\n");
								printf("<font color='#cc0000'><b>														\n");
								printf("<BR>INSERT NOT ALLOWED - OPERATION ABORTED<BR><BR>								\n");
								printf("</b></font>																		\n");
								printf("<BR>IMSI range to insert %s - %s<BR>											\n", range_ini, range_end);
								printf("<BR>overlaps the existing IMSI range  %s - %s<BR><BR>							\n", dbrec.range_ini, dbrec.pkey.range_end);
								printf("</big>																			\n");
								printf("<hr color='#000080'>															\n");
								printf("<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>		\n");
								printf("<hr color='#000080'>															\n");
								printf("</font></center>																\n");

								Display_Bottom();

								tuttoOK = 0;
								break;	// non controlla anche l'INI
							}
						}
						//************************
						// check su INI Range
						// se arriva qui vuol dire che END range è OK
						//************************
						else
						{
							// se l'END trovato è minore del END del NUOVO
							if ( memcmp(dbrec.pkey.range_end, range_end, range_len) < 0 )
							{
								// non va bene, c'è sovrapposizione.
								// Possono esserci 3 casi di sovrapposizione:
								//      1 - INI to Insert cade in mezzo al range trovato
								//          to insert :     ---------IxxxxxxxxxxxxxxxxE---------
								//            trovato :     -----IxxxxxxxxE---------------------
								//
								//      2 - Range to Insert ingloba il range trovato
								//          to insert :     ---------IxxxxxxxxxxxxxxxxE---------
								//            trovato :     ------------IxxxxxxxxE--------------
								//
								//      3 - INI to Update combacia con INI del range trovato
								//          to insert :     ---------IxxxxxxxxxxxxxxxxE---------
								//            trovato :     ---------IxxxxxxxxE-----------------

								Display_Top(NOTHING);

								printf("<center>																		\n");
								printf("<font face='Arial, Helvetica, sans-serif'>										\n");

								printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

								printf("<big>																			\n");
								printf("<font color='#cc0000'><b>														\n");
								printf("<BR>INSERT NOT ALLOWED - OPERATION ABORTED<BR><BR>								\n");
								printf("</b></font>																		\n");
								printf("<BR>IMSI range to insert %s - %s<BR>											\n", range_ini, range_end);
								printf("<BR>overlaps the existing IMSI range  %s - %s<BR><BR>							\n", dbrec.range_ini, dbrec.pkey.range_end);
								printf("</big>																			\n");
								printf("<hr color='#000080'>															\n");
								printf("<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>		\n");
								printf("<hr color='#000080'>															\n");
								printf("</font></center>																\n");

								Display_Bottom();

								tuttoOK = 0;
							}
						}
					}
				}
			}
		}
		MBE_FILE_CLOSE_(handle);
	}

	if (tuttoOK)
		Ins_Upd_Rec(NEW_REC);

	return;
}

/******************************************************************************/
/* Verifica che, in fase di UPDATE, il range non si overlappi con altri range */
/* Per UPDATE verifica IMSI INI che è l'unico variabile                       */
/******************************************************************************/
void Check_Update(void)
{
	char   *wrk_str;
	char   sTmp[128];
	char   			range_ini[20];
	char   			range_end[20];
	unsigned short	range_len;
	short  handle = -1;
	short  tuttoOK = 1;
	int    errO;
	int    cc;
	IMSI_RECORD	dbrec;
	IMSI_PKEY	PKey;

	/* inizializza */
	memset(&dbrec, 0x00, sizeof(IMSI_RECORD));
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*---------------------------------------*/
	/* LETTURA VARIABILI D'AMBIENTE			 */
	/*---------------------------------------*/
	if ( (wrk_str = cgi_param( "IMSIINI" ) ) != NULL )
		strcpy(range_ini, wrk_str);

	if ( (wrk_str = cgi_param( "IMSIEND" ) ) != NULL )
		strcpy(range_end, wrk_str);

	range_len = (unsigned short)strlen(range_end);

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acIMSIDB, &handle);

	if (errO == 0)
	{
		/*---------------------------*/
		/* IMPOSTA CHIAVE			 */
		/*---------------------------*/
		PKey.range_len = range_len;
		// usa RANGE INI come chiave, il controllo è incentrato su di lui
		strcpy(PKey.range_end, range_ini);

		/*******************
		* Cerco il record
		*******************/
		/* ricerca primaria (0) approssimata (0) */
		cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 0);

		/* errore */
		if (cc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", cc);
			Display_Message(1, sTmp);
			tuttoOK = 0;
		}
		/* tutto ok */
		else
		{
			/* Leggo il record */
			cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_RECORD) );

			/* errore */
			if (cc != 0 && cc != 1)
			{
				sprintf(sTmp, "Readx: error %d", cc);
				Display_Message(1, sTmp);
				tuttoOK = 0;
			}

			/* record trovato */
			if (cc == 0)
			{
				// se siamo nella stessa lunghezza range cercata
				// (se va oltre non c'è di sicuro sovrapposizione)
				if (dbrec.pkey.range_len == range_len)
				{
					// se non è lo stesso range che si sta aggiornando
					if ( memcmp(dbrec.pkey.range_end, range_end, range_len) )
					{
						// non va bene, c'è sovrapposizione.
						// Possono esserci 3 casi di sovrapposizione:
						//      1 - INI to Update cade in mezzo al range trovato
						//          to update :     ---------IxxxxxxxxxxxxxxxxE---------
						//            trovato :     -----IxxxxxxxxE---------------------
						//
						//      2 - Range to Update ingloba il range trovato
						//          to update :     ---------IxxxxxxxxxxxxxxxxE---------
						//            trovato :     ------------IxxxxxxxxE--------------
						//
						//      3 - INI to Update combacia con INI del range trovato
						//          to update :     ---------IxxxxxxxxxxxxxxxxE---------
						//            trovato :     ---------IxxxxxxxxE-----------------

						Display_Top(NOTHING);

						printf("<center>																		\n");
						printf("<font face='Arial, Helvetica, sans-serif'>										\n");

						printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>											\n");

						printf("<big>																			\n");
						printf("<font color='#cc0000'><b>														\n");
						printf("<BR>UPDATE NOT ALLOWED - OPERATION ABORTED<BR><BR>								\n");
						printf("</b></font>																		\n");
						printf("<BR>IMSI range to update %s - %s<BR>											\n", range_ini, range_end);
						printf("<BR>overlaps the existing IMSI range  %s - %s<BR><BR>							\n", dbrec.range_ini, dbrec.pkey.range_end);
						printf("</big>																			\n");
						printf("<hr color='#000080'>															\n");
						printf("<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>		\n");
						printf("<hr color='#000080'>															\n");
						printf("</font></center>																\n");

						Display_Bottom();

						tuttoOK = 0;
					}
				}
			}
		}
		MBE_FILE_CLOSE_(handle);
	}

	if (tuttoOK)
		Ins_Upd_Rec(UPD_REC);

	return;
}

/******************************************************************************/
void Display_Record(short CosaFare, char *record)
{
	char		stringa[64];
	long long	LOCAL_TS;
	unsigned short usID;
	IMSI_RECORD dbrec;

	Display_Top(CosaFare);

	printf("<center>																			\n");
	printf("<font face='Arial, Helvetica, sans-serif'>											\n");

	printf("<BR><BR> <big>IMSI</big> <BR><BR><BR>												\n");

	printf("<FORM name='frmSubmission' METHOD=POST ACTION='imsidb.cgi' onsubmit='return Controlla()'>	\n");

	if (CosaFare == NEW_REC)
	{
		printf("	<INPUT TYPE='hidden' name='OPERATION' value='CHECK_INSERT'>					\n");

		// record vuoto
		memset(&dbrec, 0x00, sizeof(IMSI_RECORD));
	}
	else
	{
		printf("	<INPUT TYPE='hidden' name='OPERATION' value='CHECK_UPDATE'>					\n");

		// riempie struttura record
		memcpy(&dbrec, record, sizeof(IMSI_RECORD));
	}

	usID = dbrec.hss_id;

	printf("	<TABLE border=0>																\n");
	printf("		<TR align=left height=40>													\n");
	printf("			<TH> from IMSI </TH>													\n");

	if (CosaFare == NEW_REC)
		printf("			<TD><INPUT TYPE='text' NAME='IMSIINI' SIZE='20' MAXLENGTH='16'></TD>	\n");
	else
		printf("			<TD><INPUT TYPE='text' NAME='IMSIINI' SIZE='20' MAXLENGTH='16' VALUE='%s'></TD>	\n", dbrec.range_ini);

	printf("		</TR>																		\n");

	printf("		<TR align=left height=40>													\n");
	printf("			<TH> to IMSI </TH>														\n");

	if (CosaFare == NEW_REC)
		printf("			<TD><INPUT TYPE='text' NAME='IMSIEND' SIZE='20' MAXLENGTH='16'></TD>	\n");
	else
		printf("			<TD><INPUT TYPE='text' NAME='IMSIEND' SIZE='20' MAXLENGTH='16' VALUE='%s' READONLY></TD> \n", dbrec.pkey.range_end);

	printf("		</TR>																		\n");

	printf("		<TR align=left height=40>													\n");
	printf("			<TH> HSS Host Name </TH>												\n");
	printf("			<TD>																	\n");
	printf("				<SELECT NAME='HSSID'>												\n");

	// crea una option per ogni record in HSS DB
	ListAllHSS(usID);

	printf("				</SELECT>															\n");
	printf("			</TD>																	\n");
	printf("		</TR>																		\n");
	printf("	</TABLE>																		\n");

	printf("	<BR><BR>																		\n");

	if (CosaFare == UPD_REC)
	{
		LOCAL_TS = CONVERTTIMESTAMP(dbrec.insert_ts);
		printf("  <b>Insert time:</b> %s &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;", timestamp2string(stringa, LOCAL_TS));
		LOCAL_TS = CONVERTTIMESTAMP(dbrec.update_ts);
		printf("  <b>Update time:</b> %s							 \n", timestamp2string(stringa, LOCAL_TS));
	}

	printf("	<hr color='#000080'>															\n");
	printf("	<INPUT TYPE='button' VALUE='<< Back' onclick='javascript:history.back()'>		\n");
	printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;													\n");
	printf("	<input TYPE='submit' VALUE='Save'>												\n");
	if (CosaFare == UPD_REC)
	{
		printf("	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;													\n");
        printf("	<INPUT TYPE='button' VALUE='Delete' onclick=Cancella('imsidb.cgi?OPERATION=DELETE&IMSIEND=%s')>	\n", dbrec.pkey.range_end);
	}
	printf("	<hr color='#000080'>															\n");
	printf("</FORM>																				\n");
	printf("</font></center>																	\n");

	Display_Bottom();
}

/****************************************************************************/
/* Recupera info del record di testa										*/
/****************************************************************************/
void GetInfoRec(short handle, char *acLunghezze)
{
	int   	cc;
	IMSI_PKEY			PKey;
	IMSI_HEAD_RECORD	dbrec;

	memset(acLunghezze, 0x00, sizeof(dbrec.lunghezze));

	/*******************
	* imposta chiave con lunghezza range 0 per prendere primo record
	*******************/
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*******************
	* Cerco il record
	*******************/
	/* ricerca primaria (0) esatta (2) */
	cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 2);

	/* tutto ok */
	if (cc == 0)
	{
		/* Leggo il record */
		cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );

		// tutto ok
		if ( cc == 0 )
		{
			memcpy(acLunghezze, dbrec.lunghezze, sizeof(dbrec.lunghezze));
		}
	}

	return;
}

/****************************************************************************/
/* Controlla ed eventualmente aggiorna record di testa						*/
/* a seguito di cancellazione di un range di IMSI    						*/
/****************************************************************************/
void UpdInfoRec_Del(short handle, unsigned short usLen)
{
	int   	cc;
	IMSI_PKEY			PKey;
	IMSI_HEAD_RECORD	dbrec;

	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*******************
	* imposta chiave con lunghezza range specificata da parametro
	*******************/
	PKey.range_len = usLen;

	/*******************
	* Cerco il record
	*******************/
	/* ricerca primaria (0) generica (1) solo su lunghezza */
	cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(PKey.range_len), 0, 1);

	/* tutto ok */
	if (cc == 0)
	{
		/* Leggo il record */
		cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );

		// non trovato
		// non ci sono più record con questa lunghezza range, devo settare a 0 il relativo flag
		if ( cc == 1 )
		{
			/*******************
			* imposta chiave con lunghezza range 0 per prendere primo record
			*******************/
			memset(&PKey, 0x00, sizeof(IMSI_PKEY));

			/*******************
			* Cerco il record
			*******************/
			/* ricerca primaria (0) esatta (2) */
			cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 2);

			/* tutto ok */
			if (cc == 0)
			{
				/* Leggo il record */
				cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );

				// tutto ok
				if ( cc == 0 )
				{
					// imposta a 0 (non presente) il flag che indica la presenza di range di lunghezza usLen
					dbrec.lunghezze[usLen] = 0;

					/* Scrivo il record */
					cc = MBE_WRITEUPDATEX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );
				}
			}
		}
	}

	return;
}

/****************************************************************************/
/* Controlla ed eventualmente aggiorna record di testa						*/
/* a seguito di inserimento di un range di IMSI    							*/
/****************************************************************************/
void UpdInfoRec_Ins(short handle, unsigned short usLen)
{
	int   	cc;
	IMSI_PKEY			PKey;
	IMSI_HEAD_RECORD	dbrec;

	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*******************
	* imposta chiave con lunghezza range 0 per prendere primo record
	*******************/
	memset(&PKey, 0x00, sizeof(IMSI_PKEY));

	/*******************
	* Cerco il record
	*******************/
	/* ricerca primaria (0) esatta (2) */
	cc = MBE_FILE_SETKEY_ (handle, (char *)&PKey, sizeof(IMSI_PKEY), 0, 2);

	/* tutto ok */
	if (cc == 0)
	{
		/* Leggo il record */
		cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );

		// tutto ok
		if ( cc == 0 )
		{
			// se non risultano range della lunghezza indicata
			if ( dbrec.lunghezze[usLen] == 0 )
			{
				// imposta a 1 (presente) il flag che indica la presenza di range di lunghezza usLen
				dbrec.lunghezze[usLen] = 1;

				/* Scrivo il record */
				cc = MBE_WRITEUPDATEX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );
			}
		}
		// non trovato
		else if ( cc == 1 )
		{
			memset(&dbrec, 0x00, sizeof(IMSI_HEAD_RECORD));

			// imposta a 1 (presente) il flag che indica la presenza di range di lunghezza usLen
			dbrec.lunghezze[usLen] = 1;

			/* Scrivo il record */
			cc = MBE_WRITEX( handle, (char *)&dbrec, (short)sizeof(IMSI_HEAD_RECORD) );
		}

	}

	return;
}

/******************************************************************************/
void GetHSSname(unsigned short usID, char *acHSSdescr, short handle_hss)
{
	short 	handle = -1;
	int   	errO;
	int   	cc;
	HSS_RECORD	dbrec;

	// deve fare OPEN
	if (handle_hss == 0)
	{
		/*******************
		* Apro il file
		*******************/
		errO = Apri_File(acHSSDB, &handle);

		if (errO != 0)
		{
			sprintf(acHSSdescr, "<font color='#ff0000'>error %d - cannot retrieve Host Name</font>", errO);
			return;
		}
	}
	// precedente OPEN OK
	else
		handle = handle_hss;

	/*******************
	* Cerco il record
	*******************/
	/* ricerca primaria (0) esatta (2) */
	cc = MBE_FILE_SETKEY_ (handle, (char *)&usID, sizeof(usID), 0, 2);

	/* errore */
	if (cc != 0)
	{
		sprintf(acHSSdescr, "<font color='#ff0000'>Error %d retrieving HSS Host Name</font>", cc);
	}
	/* tutto ok */
	else
	{
		cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );

		/* errore... */
		if ( cc != 0 )
		{
			/* errore */
			if (cc != 1)
			{
				sprintf(acHSSdescr, "<font color='#ff0000'>Error %d retrieving HSS Host Name</font>", cc);
			}
			/* non trovato */
			else
			{
				strcpy(acHSSdescr, "<font color='#ff0000'>HSS Host Name not found</font>");
			}
		}
		/* record TROVATO */
		else  /* readx ok */
		{
			strcpy(acHSSdescr, dbrec.hostname);
		}
	}

	if (handle_hss == 0)
		MBE_FILE_CLOSE_(handle);

	return;
}

/******************************************************************************/
void ListAllHSS(unsigned short usID)
{
	char	hostname[256];		// Alternate Key, NOT reversed
	short 	handle = -1;
	short	trovato = 0;
	unsigned short conta=0;
	int   	errO;
	int   	cc;
	HSS_RECORD	dbrec;

	memset(hostname, 0x00, sizeof(hostname));

	/*******************
	* Apro il file
	*******************/
	errO = Apri_File(acHSSDB, &handle);

	if (errO != 0)
	{
		printf("					<option value='0'>--- Error %d retrieving Hosts names ---</option>		\n", errO);
		return;
	}

	/*******************
	* Cerco il record
	*******************/
	/* ricerca alternata (1) approssimata (0) */
	cc = MBE_FILE_SETKEY_ (handle, hostname, hssdb_altkey_len, 1, 0);

	/* errore */
	if (cc != 0)
	{
		printf("					<option value='0'>--- Error %d retrieving Hosts names ---</option>		\n", cc);
	}
	/* tutto ok */
	else
	{
		while (1)
		{
			cc = MBE_READX( handle, (char *)&dbrec, (short)sizeof(HSS_RECORD) );

			/* errore... */
			if ( cc != 0 )
			{
				/* errore */
				if (cc != 1)
				{
					printf("					<option value='0'>--- Error %d retrieving Hosts names ---</option>		\n", cc);
				}
				else
				{
					if (conta == 0)
						printf("					<option value='0'>--- HSS Host DB is empty ---</option>		\n");
				}

				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				if ( dbrec.hss_id == usID )
				{
					printf("					<option value='%u' selected>%.64s</option>					\n", dbrec.hss_id, dbrec.hostname);
					trovato = 1;
				}
				else
					printf("					<option value='%u'>%.64s</option>							\n", dbrec.hss_id, dbrec.hostname);

				conta++;
			}
		}

		// se ha passato tutti i record e doveva cercare un ID ma non l'ha trovato
		if (cc == 1 && conta > 0 && usID != 0 && trovato == 0)
			printf("					<option value='0' selected>--- HSS Host Name not found ---</option>		\n");
	}

	MBE_FILE_CLOSE_(handle);

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

	if (tipo == NEW_REC || tipo == UPD_REC)
	{
		printf("        function Controlla()												\n");
		printf("        {																	\n");
		printf("			if (document.frmSubmission.IMSIINI.value.length == 0)			\n");
		printf("			{																\n");
		printf("				alert('Insert IMSI');										\n");
		printf("				document.frmSubmission.IMSIINI.focus();						\n");
		printf("				return false;												\n");
		printf("			}																\n");
		if (tipo == NEW_REC)
		{
			printf("			if (document.frmSubmission.IMSIEND.value.length == 0)			\n");
			printf("			{																\n");
			printf("				alert('Insert IMSI');										\n");
			printf("				document.frmSubmission.IMSIEND.focus();						\n");
			printf("				return false;												\n");
			printf("			}																\n");
		}
		printf("			if (document.frmSubmission.IMSIINI.value.length != document.frmSubmission.IMSIEND.value.length)	\n");
		printf("			{																\n");
		printf("				alert('The two IMSI must have same length');				\n");
		printf("				document.frmSubmission.IMSIINI.focus();						\n");
		printf("				return false;												\n");
		printf("			}																\n");
		printf("			if (document.frmSubmission.IMSIINI.value > document.frmSubmission.IMSIEND.value) \n");
		printf("			{																\n");
		printf("				alert('FROM must be less than TO');							\n");
		printf("				document.frmSubmission.IMSIINI.focus();						\n");
		printf("				return false;												\n");
		printf("			}																\n");
		printf("			if (document.frmSubmission.HSSID.value == 0)					\n");
		printf("			{																\n");
		printf("				alert('Select HSS Host Name');								\n");
		printf("				document.frmSubmission.HSSID.focus();						\n");
		printf("				return false;												\n");
		printf("			}																\n");
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
