//---------------------< Include files >-------------------------------------
#pragma nolist
#include <unistd.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <time.h>
#include <tal.h>
#include <usrlib.h>
#include <cextdecs.h (JULIANTIMESTAMP)>

#include "tfs2.h"
#include "tfs3.h"
#include "web_func.h"
#include "mbedb.h"
#include "ssplog.h"

//short	CercainSoglie_OP(short handle, short handle_rem, char *ac_grp, char *ac_op);
//short	CercainSoglie_PA(short handle, short handle_rem, char *ac_Key);
short	Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo);
short	Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem);
short 	Aggiorna_PA_rec_Aster(short handle, short handlePA_rem);
void	Leggi_Applica();
short	Controlla_CarTable();
short 	scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation );
short 	Aggiorno_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi );
char  *str_tok(char *riga, char *sep, char elemento[], short *stop);

//*************************************************************************************
//short CercainSoglie_OP(short handle, short handle_rem, char *ac_grp, char *ac_op)
//{
//	char		sTmp[100];
//	char		ac_Chiave[30];
//	short		rc = 0;
//
//	t_ts_soglie_record record_soglie;
//
//	/* inizializza la struttura tutta a blank */
//	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
//	
//	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
//
//	/*******************
//	* Cerco il record
//	*******************/
//	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);
//	
//	/* errore */
//	if (rc != 0)
//	{
//		sprintf(sTmp, "File_setkey: error %d", rc);
//		Display_Message(1, "SOGLIE DB: View Records - Operation result", sTmp, 0);
//	}
//	/* tutto ok */
//	else
//	{
//		while ( 1 )
//		{
//			/*******************
//			* Leggo il record
//			*******************/
//			rc = MBE_READX( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
//			/* errore... */
//			if (rc != 0)
//			{
//				if (rc != 1)
//				{
//					sprintf(sTmp, "Readx: error %d", rc);
//					Display_Message(1, "SOGLIE DB: View Records - Operation result", sTmp, 0);
//				}
//				else
//					rc = 0;
//				break;
//			}
//			/* record TROVATO */
//			else  /* readx ok */
//			{
//				if( !memcmp(ac_grp, record_soglie.gr_op, sizeof(record_soglie.gr_op)) || 
//					!memcmp(ac_op,  record_soglie.gr_op, sizeof(record_soglie.gr_op)))
//				{
//					rc = Aggiorna_Soglie(handle, handle_rem);
//					if (rc == 0 )
//						rc = 99;
//					break;
//				}
//			}
//		}
//	}
//
//	return(rc);
//}
//
////*************************************************************************************
//short CercainSoglie_PA(short handle, short handle_rem, char *ac_Key)
//{
//	char		sTmp[100];
//	char		ac_Chiave[30];
//	short		rc = 0;
//
//	t_ts_soglie_record record_soglie;
//
//	/* inizializza la struttura tutta a blank */
//	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
//	
//	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
//
//	memcpy(ac_Chiave, ac_Key, strlen(ac_Key));
//
//
//	/*******************
//	* Cerco il record
//	*******************/
//	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, GENERIC);
//	/* errore */
//	if (rc != 0)
//	{
//		sprintf(sTmp, "File_setkey: error %d", rc);
//		Display_Message(1, "SOGLIE Local DB: View Records - Operation result", sTmp, 0);
//	}
//	/* tutto ok */
//	else
//	{
//		/*******************
//		* Leggo il record
//		*******************/
//		rc = MBE_READX( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
//		/* errore... */
//		if (rc != 0)
//		{
//			if (rc != 1)
//			{
//				sprintf(sTmp, "Readx: error %d", rc);
//				Display_Message(1, "SOGLIE Local DB: View Records - Operation result", sTmp, 0);
//			}
//			else
//				rc = 0;
//		}
//		/* record TROVATO */
//		else  /* readx ok */
//		{
//            rc = Aggiorna_Soglie(handle, handle_rem);
//			if (rc == 0 )
//				rc = 99;
//		}
//	}
//
//	return(rc);
//}
//
//******************************************************************************************
// nTipo = 0  Aggiornare campo tot_accT  identifica la modifica del DB soglie
// nTipo = 1  Aggiornare campo tot_accP  utilizzato dall'apply e dal TFS Mgr
//
// IPM KTSTEACS : Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
//******************************************************************************************
short Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo)
{
	short		rc = 0;
	char		ac_Chiave[LEN_KEY_SOGLIE];
	char		sTmp[500];

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_soglie_rem;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));


	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "File_setkey: error %d", rc);
		Display_Message(1, "SOGLIE Local DB: View Records- Operation result", sTmp);
	}
	/* tutto ok */
	else
	{
		rc = MBE_FILE_SETKEY_( handle_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
		/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "File_setkey: error %d", rc);
			Display_Message(1, "SOGLIE Remote DB: View Records- Operation result", sTmp);
		}
	}
	if(rc == 0)
	{
		//------------------------- AGGIORNO DB LOCALE ----------------------------------
		rc = MbeFileReadL_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );

		if ( rc)                  /*******   errore ************/
		{
			if(rc == 1)
			{
				memcpy(record_soglie.gr_pa, ac_Chiave, LEN_KEY_SOGLIE);
				//lJTS= JULIANTIMESTAMP(0);
				if(nTipo == 0)
					memcpy(record_soglie.tot_accT, &lJTS, sizeof(long long));
				else
					memcpy(record_soglie.tot_accP, &lJTS, sizeof(long long));

				//--------------------- inserisco il record
				rc = MbeFileWrite_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore */         
				if (rc)
				{
					sprintf(sTmp, "Write error (rec *) in local file [%s]: error %d ", acFileSoglie_Loc, rc);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Read error (rec *) in local file [%s]: error %d ", acFileSoglie_Loc, rc);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			if(nTipo == 0)
				memcpy(record_soglie.tot_accT, &lJTS, sizeof(long long));
			else
				memcpy(record_soglie.tot_accP, &lJTS, sizeof(long long));

			rc = MbeFileWriteUU_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			if(rc)
			{
				sprintf(sTmp, "Update error (rec *) in local file [%s]: error %d", acFileSoglie_Loc, rc);
				Display_Message(1, "", sTmp);
				//MBE_UNLOCKREC(handle);
				MbeUnlockRec_nw(handle);
			}
		}
		if(rc == 0)
		{
			//------------------------ AGGIORNO DB REMOTE ------------------------------
			rc = MbeFileReadL_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if ( rc)
			{
				if(rc == 1)
				{
					memcpy(record_soglie_rem.gr_pa, ac_Chiave, LEN_KEY_SOGLIE);
					if(nTipo == 0)
						memcpy(record_soglie_rem.tot_accT, &lJTS, sizeof(long long));
					else
						memcpy(record_soglie_rem.tot_accP, &lJTS, sizeof(long long));

					//--------------------- inserisco il record
					rc = MbeFileWrite_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
					/* errore */         
					if (rc)
					{
						sprintf(sTmp, "Write error (rec *) in remote file [%s]: error %d ", acFileSoglie_Rem, rc);
						Display_Message(1, "", sTmp);
					}
				}
				else
				{
					sprintf(sTmp, "Read error (rec *) in remote file [%s]: error %d ", acFileSoglie_Rem, rc);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				//aggiorno il record con la data attuale
				if(nTipo == 0)
					memcpy(record_soglie_rem.tot_accT, &lJTS, sizeof(long long));
				else
					memcpy(record_soglie_rem.tot_accP, &lJTS, sizeof(long long));

				rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
				if(rc)
				{
					sprintf(sTmp, "Update error (rec *) in remote file [%s]: error %d", acFileSoglie_Rem, rc);
					Display_Message(1, "", sTmp);
				//	MBE_UNLOCKREC(handle);
					MbeUnlockRec_nw(handle_rem);
				}
			}
		}
	}
	return(rc);
}
//*******************************************************************************************************************
short Aggiorna_Operatori_rec_Aster(short handle, short handleOP_rem)
{
	short		rc = 0;
	char		ac_Chiave[18];
	char		sTmp[500];
	char		acData[50];
	long long	lJTS = 0;

	t_ts_oper_record oper_profile;

	/* inizializza la struttura tutta a blank */
	memset(&oper_profile, ' ', sizeof(t_ts_oper_record));
	memset(acData, 0, sizeof(acData));

	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	GetTimeStamp(&lJTS);
	//converto la data corrente da long long a AAAAMMGGHHMMSS
	TS2stringAAMMGG(acData, lJTS);
	
	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey Local DB [%s]  key=%.18s(%d)",
						rc, acFileOperatori_Loc, ac_Chiave, (short)sizeof(ac_Chiave) ) ;
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		//------------------------- AGGIORNO DB operatori LOCALE----------------------------------
		rc = MBE_READLOCKX( handle, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
		if ( rc)/* errore... */
		{
			if(rc == 1)
			{
				memcpy(oper_profile.paese, ac_Chiave, sizeof(ac_Chiave));
				memcpy(oper_profile.den_op, acData, strlen(acData));

				//--------------------- inserisco il record
				rc = MBE_WRITEX( handle, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
				/* errore */         
				if (rc)
				{
					sprintf(sTmp, "Error (%d) writing in Local file [%s]", rc, acFileOperatori_Loc);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s]", rc, acFileOperatori_Loc);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			memcpy(oper_profile.den_op, acData, strlen(acData));

			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) updating in Local file [%s]", rc, acFileOperatori_Loc);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
		}

		if(rc == 0)
		{
			//------------------------- AGGIORNO DB operatori REMOTO----------------------------------
			rc = MBE_FILE_SETKEY_( handleOP_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey Remote DB [%s]  key=%.18s(%d)",
								rc, acFileOperatori_Rem, ac_Chiave, (short)sizeof(ac_Chiave) ) ;
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handleOP_rem, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
				if ( rc)/* errore... */
				{
					if(rc == 1)
					{
						memcpy(oper_profile.paese, ac_Chiave, sizeof(ac_Chiave));
						memcpy(oper_profile.den_op, acData, strlen(acData));

						//--------------------- inserisco il record
						rc = MBE_WRITEX( handleOP_rem, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
						/* errore */
						if (rc)
						{
							sprintf(sTmp, "Error (%d) writing in Remote file [%s]", rc, acFileOperatori_Rem);
							Display_Message(1, "", sTmp);
						}
					}
					else
					{
						sprintf(sTmp, "Error (%d) reading in Remote file [%s]", rc, acFileOperatori_Rem);
						Display_Message(1, "", sTmp);
					}
				}
				else
				{
					//aggiorno il record con la data attuale
					memcpy(oper_profile.den_op, acData, strlen(acData));

					rc = MBE_WRITEUPDATEUNLOCKX( handleOP_rem, (char *) &oper_profile, (short) sizeof(t_ts_oper_record) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) updating in Remote file [%s]", rc, acFileOperatori_Rem);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
				}
			}
		}
	}
	return(rc);
}
//*******************************************************************************************************************
short Aggiorna_PA_rec_Aster(short handle, short handlePA_rem)
{
	short		rc = 0;
	char		ac_Chiave[8];
	char		sTmp[500];
	char		acData[50];
	long long	lJTS = 0;

	struct _ts_paesi_record record_paesi;

	/* inizializza la struttura tutta a blank */
	memset(&record_paesi, ' ', sizeof(struct _ts_paesi_record));
	memset(acData, 0, sizeof(acData));

	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	GetTimeStamp(&lJTS);
	//converto la data corrente da long long a AAAAMMGGHHMMSS
	TS2stringAAMMGG(acData, lJTS);

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey Local DB [%s]  key=%.8s",
						rc, acFilePaesi_Loc, ac_Chiave ) ;
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		//------------------------- AGGIORNO DB operatori LOCALE----------------------------------
		rc = MBE_READLOCKX( handle, (char *) &record_paesi, (short) sizeof(record_paesi) );
		if ( rc)/* errore... */
		{
			if(rc == 1)
			{
				memcpy(record_paesi.paese, ac_Chiave, sizeof(ac_Chiave));
				memcpy(record_paesi.gr_pa, acData, strlen(acData));

				//--------------------- inserisco il record
				rc = MBE_WRITEX( handle, (char *) &record_paesi, (short) sizeof(record_paesi) );
				/* errore */
				if (rc)
				{
					sprintf(sTmp, "Error (%d) writing in Local file [%s]", rc, acFilePaesi_Loc);
					Display_Message(1, "", sTmp);
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) reading in Local file [%s]", rc, acFilePaesi_Loc);
				Display_Message(1, "", sTmp);
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			memcpy(record_paesi.gr_pa, acData, strlen(acData));

			rc = MBE_WRITEUPDATEUNLOCKX( handle, (char *) &record_paesi, (short) sizeof(record_paesi) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) updating in Local file [%s]", rc, acFilePaesi_Loc);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handle);
			}
		}

		if(rc == 0)
		{
			//------------------------- AGGIORNO DB operatori REMOTO----------------------------------
			rc = MBE_FILE_SETKEY_( handlePA_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
			if (rc != 0)
			{
				sprintf(sTmp, "Error (%d) File_setkey Remote DB [%s]  key=%.8s",
								rc, acFileOperatori_Rem, ac_Chiave) ;
				Display_Message(1, "", sTmp);
			}
			/* tutto ok */
			else
			{
				rc = MBE_READLOCKX( handlePA_rem, (char *) &record_paesi, (short) sizeof(record_paesi) );
				if ( rc)/* errore... */
				{
					if(rc == 1)
					{
						memcpy(record_paesi.paese, ac_Chiave, sizeof(ac_Chiave));
						memcpy(record_paesi.gr_pa, acData, strlen(acData));

						//--------------------- inserisco il record
						rc = MBE_WRITEX( handlePA_rem, (char *) &record_paesi, (short) sizeof(record_paesi) );
						/* errore */
						if (rc)
						{
							sprintf(sTmp, "Error (%d) writing in Remote file [%s]", rc, acFilePaesi_Rem);
							Display_Message(1, "", sTmp);
						}
					}
					else
					{
						sprintf(sTmp, "Error (%d) reading in Remote file [%s]", rc, acFilePaesi_Rem);
						Display_Message(1, "", sTmp);
					}
				}
				else
				{
					//aggiorno il record con la data attuale
					memcpy(record_paesi.gr_pa, acData, strlen(acData));

					rc = MBE_WRITEUPDATEUNLOCKX( handlePA_rem, (char *) &record_paesi, (short) sizeof(record_paesi) );
					if(rc)
					{
						sprintf(sTmp, "Error (%d) updating in Remote file [%s]", rc, acFilePaesi_Rem);
						Display_Message(1, "", sTmp);
						MBE_UNLOCKREC(handle);
					}
				}
			}
		}
	}
	return(rc);
}

//****************************************************************
void Leggi_Applica()
{
	FILE		*hApp_PS;
	FILE		*hApp_ST;
	char		sTmp[500];
	short		rc = 0;
	long long	lJTS = 0;
	long long	lJTS_local = 0;

	
	memset(gDataApply_PS, 0, sizeof(gDataApply_PS));
	memset(gDataApply_ST, 0, sizeof(gDataApply_ST));
	memset(sTmp, 0, sizeof(sTmp));

	/****************************************
	* apre i file  Applica  PRE STEERING              
	****************************************/
	if ((hApp_PS = fopen_oss(acFileApply_PS, "r")) == NULL)
	{
		/* avvisa dell'errore */
		//sprintf(sTmp, "fopen %s: error %d", acFileApplica, errno);
		//Display_Message(1, "", sTmp);
		rc = 1;
	}
	if (rc == 0)
	{
		// leggo la data dal file Applica
		fgets(sTmp, 50, hApp_PS);
		//trasformo la data il LOCAL e poi la riconverto in stringa
		lJTS = stringAAMMGG2TS(sTmp);
		ConvertGMT_To_Local(&lJTS_local, lJTS);
		TS2stringAAMMGG(gDataApply_PS, lJTS_local);

		fclose(hApp_PS);

		/****************************************
		* apre i file  Applica  STEERING              
		****************************************/
		if ((hApp_ST = fopen_oss(acFileApply_ST, "r")) == NULL)
		{
			/* avvisa dell'errore */
			//sprintf(sTmp, "fopen %s: error %d", acFileApplica, errno);
			//Display_Message(1, "", sTmp);
			rc = 1;
		}
		if (rc == 0)
		{
			memset(sTmp, 0, sizeof(sTmp));
			lJTS = 0;
			fgets(sTmp, 50, hApp_ST);
			//trasformo la data il LOCAL e poi la riconverto in stringa
			lJTS = stringAAMMGG2TS(sTmp);
			ConvertGMT_To_Local(&lJTS_local, lJTS);
			TS2stringAAMMGG(gDataApply_ST, lJTS_local);

			fclose(hApp_ST);
		}
	}
}
//*****************************************************************************************
// leggo la cartable e salvo il valore max ammesso x ogni caratteristica x poi confrontarlo
// con il valore del file di input
//*****************************************************************************************
short Controlla_CarTable()
{
	FILE		*hIn;
	short		rc = 0;
    char		sTmp[500];
    char		sLetti[301];
	char		acDati[300];
	char		*pTmp;
	int			nPosByte = 0;
	char		cValue_input;

	memset(gCaratt, 0, sizeof(gCaratt));

	/****************************************
	* apre il file  input               
	****************************************/
	if ((hIn = fopen(ac_car_table, "r")) == NULL)
	{
		/* avvisa dell'errore */
		sprintf(sTmp, "fopen %s: error %d", ac_car_table, errno);
		Display_Message(1, "", sTmp);
		rc = 1;
	}

	if (rc == 0)
	{
		/* legge prima riga fino allo \n */
		fgets(sLetti, 300, hIn);
		while (!feof(hIn))
		{
			memset(acDati, 0, sizeof(acDati));
			memcpy(acDati, sLetti, strlen(sLetti)-1);
			//Aggiungere un elemento alla lista:
			AlltrimString(acDati);

			pTmp= strtok(acDati, ";");
			if(pTmp)
				nPosByte = atoi(pTmp);//posizione byte
			else
				continue;
			pTmp= strtok(NULL, ";");  
			if(pTmp)
			// salvo il nome della caratteristica
				strcpy(aDenCarat[nPosByte], pTmp);//label
			else
				continue;
			pTmp= strtok(NULL, ";");  
			if(pTmp)
				;//tipo input
			else
				continue;
			pTmp= strtok(NULL, ";");
			if(pTmp)
				;//nome input
			else
				continue;
			pTmp= strtok(NULL, ";"); //value
			if(pTmp)
				cValue_input = pTmp[0];
			else
				continue;

			if ( gCaratt[nPosByte] < cValue_input )
				gCaratt[nPosByte] = cValue_input;
			memset(sLetti, 0, sizeof(sLetti));
			/* legge una riga fino allo \n */
			fgets(sLetti, 300, hIn);

		}//fine while
		fclose(hIn);
	}
	return(rc);
}
//******************************************************************************************************
short scrivi_Operatori_remoto(short handleDB, t_ts_oper_record *oper_profile, short nOperation )
{
	short rc = 0;
	char sTmp[500];

	t_ts_oper_record oper_profile_tmp;

	// ******************* aggiorno REMOTO  **********************
	if (nOperation != INS)
	{
		rc = MBE_FILE_SETKEY_( handleDB,  oper_profile->paese, (short)sizeof(oper_profile->paese)+ sizeof(oper_profile->cod_op), 0, EXACT);
			/* errore */
		if (rc != 0)
		{
			sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFileOperatori_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		/* tutto ok */
		else
		{
			rc = MBE_READLOCKX( handleDB, (char *) &oper_profile_tmp, (short) sizeof(t_ts_oper_record) );
			/* errore... */
			if ( rc)
			{
				sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFileOperatori_Rem);
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
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) oper_profile, (short) sizeof(t_ts_oper_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] - Key: [%.18s]", rc, acFileOperatori_Rem, oper_profile->paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
		else if (nOperation == INS)
		{
			rc = MBE_WRITEX( handleDB, (char *) oper_profile, (short) sizeof(t_ts_oper_record) );
			/* errore */
			if (rc)
			{
				if (rc == 10 )
				{
					sprintf(sTmp, "Record [%.18s] already exist in REMOTE DB", oper_profile->paese);
					log(LOG_ERROR, "%s;%s; %s", gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
				else
				{
					sprintf(sTmp, "Error (%d) in writing REMOTE file [%s]", rc, acFileOperatori_Rem);
					log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
					Display_Message(1, "", sTmp);
				}
			}
		}
		else if (nOperation == DEL)
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) oper_profile, 0 );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in deleting REMOTE file [%s] - Key: [%.18s]", rc, acFileOperatori_Rem, oper_profile->paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}

		}
	}
	return(rc);
}

//******************************************************************************************************
short Aggiorno_Paesi_remoto(short handleDB, struct _ts_paesi_record *record_paesi )
{
	short rc = 0;
	char sTmp[500];

	struct _ts_paesi_record record_paesi_tmp;

	// ******************* aggiorno REMOTO  **********************

	rc = MBE_FILE_SETKEY_( handleDB,  record_paesi->paese, (short)sizeof(record_paesi->paese), 0, EXACT);
	/* errore */
	if (rc != 0)
	{
		sprintf(sTmp, "Error (%d) File_setkey REMOTE file [%s]", rc, acFilePaesi_Rem);
		log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
		Display_Message(1, "", sTmp);
	}
	/* tutto ok */
	else
	{
		rc = MBE_READLOCKX( handleDB, (char *) &record_paesi_tmp, (short) sizeof(struct _ts_paesi_record) );
		/* errore... */
		if ( rc)
		{
			sprintf(sTmp, "Error (%d) in reading REMOTE file [%s]", rc, acFilePaesi_Rem);
			log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
			Display_Message(1, "", sTmp);
		}
		else
		{
			//aggiorno il record in remoto con i dati modificati
			rc = MBE_WRITEUPDATEUNLOCKX( handleDB, (char *) record_paesi, (short) sizeof(struct _ts_paesi_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating REMOTE file [%s] - Country: [%.8s]", rc, acFilePaesi_Rem, record_paesi->paese);
				log(LOG_ERROR, "%s;%s; %s",gUtente, gIP, sTmp);
				Display_Message(1, "", sTmp);
				MBE_UNLOCKREC(handleDB);
			}
		}
	}
	return(rc);
}
/****************************************/
/*  str_tok con diversi separatori      */
/****************************************/
char  *str_tok(char *riga, char *sep, char elemento[], short *stop)
{
	static char  *arrivato_a = NULL;
	short        cn = 0, cn2;
	char         ferma = 0;

	*stop = 0;

	if (riga != NULL)
				 arrivato_a = riga;
	else
	{
		 if ((arrivato_a[0] == '\n') || (arrivato_a[0] == '\0'))
					   *stop = 1;
		 else
					   arrivato_a++;
	}

	while ((ferma == 0) && (arrivato_a[0] != '\n') && (arrivato_a[0] != '\0'))
	{
		elemento[cn++] = arrivato_a[0];
		arrivato_a++;

		cn2 = 0;
		while ( (ferma == 0) && (sep[cn2] != '\0'))
		{
			if (arrivato_a[0] == sep[cn2])
				ferma = 1;
			cn2++;
		}
	}

	elemento[cn] = '\0';

	return(elemento);
}
