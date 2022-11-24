// ------------------------------------------------------
//
// Last Change: 15-04-2015
// ------------------------------------------------------
#include <ssplog.h>
#include <sspevt.h>
#include <usrlib.h>
#include <dbmng.h>
#include "ds.h"
#include "dictcdef"
#include "gttlib.h"

#define APPROX 0

short ElementiTabellaMGT;
short ElementiTabellaGT;

// filenumbers
short FGTT_List;
short FGTT_Tree;

// prototipi interni
static void SortIdxPC(void);

static void SortIdxGT(void);

short _status_eq ( short err );

enum retvalues FPDB_Open2(struct LString filename, short *filenumber);

enum retvalues FPDB_ReadFirstRecord_WithoutLock2 ( short filenumber,
                                                   unsigned char buffer[],
                                                   short buffer_length,
                                                   short *charead );

enum retvalues FPDB_FindNextRecord_WithoutLock2 ( short filenumber,
                                             	  unsigned char buffer[],
                                             	  short buffer_length,
                                             	  short *charead );

short FPDB_Close2 (short filenumber);

// strutture files
gtt_impianti_rec_def GTT_Impianti;
#ifndef USERANGELIST
gtt_mgt_rec_def      GTT_MGT;
#else
gtt_mgtr_rec_def     GTT_MGT;
#endif

// lista e indici
idxpc   GTT_Idx_PC[MAXGTTENTRIES];
idxgt   GTT_Idx_GT[MAXGTTENTRIES];
tblpcgt GTT_Table[MAXGTTENTRIES];

#ifdef USETREEFORMGT
// albero
AVLTREE GTT_MGTtree;
#else
// lista in luogo dell'albero
tblmgt GTT_MGTList[MAXGTTENTRIES];
#endif

#ifdef USETREEFORMGT
// load data from file
// return 0 if success else 1
// ricordarsi che in uscita l'albero "VA" distrutto!
short GT_MGT_Load(char TableFile[40])
{
   short 			i,sCount, err = 0,err_close = 0,RecCount;
   char 			tmpkey[20];
   char 			*key;
   struct LString 	filename;
   treeval 			*value;

   strcpy(filename.text,TableFile);
   filename.len = (int)strlen(TableFile);

   err = (short)FPDB_Open2(filename, &FGTT_Tree);

   if (err)
   {
      err = 1;
   }
   else
   {
	  ElementiTabellaMGT = 0;
	  RecCount = 0;

      // se c'è lo butto
      CloseMGT();
      // Creazione dell'albero
      GTT_MGTtree = avlMake();
      // load all records in memory
      err = (short)FPDB_ReadFirstRecord_WithoutLock2( FGTT_Tree,
    		  	  	  	  	  	  	  	  	  	  	  (unsigned char*) &GTT_MGT,
    		  	  	  	  	  	  	  	  	  	  	  sizeof(GTT_MGT),
    		  	  	  	  	  	  	  	  	  	  	  &sCount );

      while (err == FPDB_SUCCESS && RecCount < MAXGTTENTRIES )
      {
         // per ogni record trovato inserisco elemento albero
         memset(tmpkey,0x00,sizeof(tmpkey));

         for (i = 0; i < 20; i++)
         {
            if ( GTT_MGT.primarykey.mgt[i] == 0x00 || GTT_MGT.primarykey.mgt[i] == 0x20)
            {
               break;
            }

            tmpkey[i] = GTT_MGT.primarykey.mgt[i];
         }

         key = (char *)calloc(1,20);
         strcpy(key,tmpkey);

         value = (treeval *)calloc(1,sizeof(treeval));

         memcpy( &(value->PCF),
        		 &GTT_MGT.altkey1.point_code_format,
        		 sizeof(GTT_MGT.altkey1.point_code_format) );

         memcpy( &(value->PC),
        		 &GTT_MGT.altkey1.point_code,
        		 sizeof(GTT_MGT.altkey1.point_code) );

         // Dual IMSI flag
         value->c_dualimsi_flag = GTT_MGT.c_dualimsi_flag;

#ifdef USERANGELIST
		// se lista range aggiunge gli altri campi della struttura
         memcpy( &(value->mgt_end, GTT_MGT.mgt_end,MGTLEN) );
		 value->mgt_length = GTT_MGT.mgt_length;
#endif

         if(avlAdd(GTT_MGTtree, key, value))
         {
        	 free(key);
        	 free(value);
         }

         // record successivo
         err = (short)FPDB_FindNextRecord_WithoutLock2( FGTT_Tree,
        		 	 	 	 	 	 	 	 	 	 	(unsigned char*) &GTT_MGT,
        		 	 	 	 	 	 	 	 	 	 	sizeof(GTT_MGT),
        		 	 	 	 	 	 	 	 	 	 	&sCount );
      }

      err_close = (short) MBE_FILE_CLOSE_(FGTT_Tree);

      if ( RecCount < MAXGTTENTRIES)
	  {
		  log_ (LOG_DEBUG, "MGT DATA: [%d] entries loaded successfully", RecCount);
	  }
      else
      {
     	  log_ (LOG_ERROR, "Error loading MGT DATA: Attempt to load more than [%d] entries", MAXGTTENTRIES );
      }
   }

   if ( err == 1 )
	   return (0);

   return ((short) err);
}
#else
// load memory table from file
// return 0 if success else 1
short GT_MGT_Load(char TableFile[40])
{
   short 			sCount, err = 0, RecCount,i,err_close = 0;
   struct LString 	filename;
   char 			tmpmgt[MGTLEN+1];

   strcpy(filename.text,TableFile);
   filename.len = (int)strlen(TableFile);

   err = (short)FPDB_Open2(filename, &FGTT_Tree);

   if (err)
   {
      err = 1;
   }
   else
   {
      // se c'è la svuoto
      memset(GTT_MGTList,0x00,sizeof(GTT_MGTList));

      ElementiTabellaMGT = 0;
      RecCount 			 = 0;

      // load all records in memory
      err = (short)FPDB_ReadFirstRecord_WithoutLock2( FGTT_Tree,
    		  	  	  	  	  	  	  	  	  	  	  (unsigned char*) &GTT_MGT,
    		  	  	  	  	  	  	  	  	  	  	  sizeof(GTT_MGT),
    		  	  	  	  	  	  	  	  	  	  	  &sCount );

      while (err == FPDB_SUCCESS && RecCount < MAXGTTENTRIES )
      {
         // per ogni record trovato inserisco in tabella e in indici

         memset(tmpmgt,0x00,sizeof(tmpmgt));

         for (i = 0; i < MGTLEN; i++)
         {
            if (GTT_MGT.primarykey.mgt[i] == 0x00 || GTT_MGT.primarykey.mgt[i] == 0x20)
            {
               break;
            }

            tmpmgt[i] = GTT_MGT.primarykey.mgt[i];
         }

         memcpy(GTT_MGTList[RecCount].key,tmpmgt,MGTLEN);
         GTT_MGTList[RecCount].value.PCF = GTT_MGT.altkey1.point_code_format;
         GTT_MGTList[RecCount].value.PC = GTT_MGT.altkey1.point_code;

         // Dual IMSI flag
         GTT_MGTList[RecCount].value.c_dualimsi_flag = GTT_MGT.c_dualimsi_flag;

#ifdef USERANGELIST
         // se lista range aggiunge gli altri campi della struttura
         memcpy(GTT_MGTList[RecCount].value.mgt_end, GTT_MGT.mgt_end,MGTLEN);
         GTT_MGTList[RecCount].value.mgt_length = GTT_MGT.mgt_length;
#endif
         RecCount++;
         ElementiTabellaMGT++;

         // record successivo
         err = (short)FPDB_FindNextRecord_WithoutLock2( FGTT_Tree,
        		 	 	 	 	 	 	 	 	 	 	(unsigned char*) &GTT_MGT,
        		 	 	 	 	 	 	 	 	 	 	sizeof(GTT_MGT),
        		 	 	 	 	 	 	 	 	 	 	&sCount );
      }

      err_close = (short) MBE_FILE_CLOSE_(FGTT_Tree);

	  if ( RecCount < MAXGTTENTRIES)
	  {
		  log_ (LOG_DEBUG, "MGT DATA: [%d] entries loaded successfully", RecCount);
	  }
	  else
	  {
		  log_ (LOG_ERROR, "Error loading MGT DATA: Attempt to load more than [%d] entries", MAXGTTENTRIES );
	  }

   }
   if ( err == 1)
	   return 0;

   return ((short) err);
}
#endif

void CloseMGT(void)
{
#ifdef USETREEFORMGT
   avlClose(GTT_MGTtree);
#else
   memset(GTT_MGTList,0x00,sizeof(GTT_MGTList));
#endif
}

#ifdef USETREEFORMGT
// ricerca nell'albero
treeval *SeekMGT(char *mgt)
{
   treeval *tmp;
   tmp = avlFindLpm(GTT_MGTtree,(void*)mgt);

   return (tmp);
}
#else
#ifndef USERANGELIST

// ricerca nella lista la chiave che
// corrisponde per il maggior numero di byte
treeval *SeekMGT(char *mgt)
{
   short 	i,found,keylen,tmplen;
   char 	tmpmgt[MGTLEN+1];
   treeval 	*tmp;

   found  = -1;
   keylen = -1;
   tmp 	  = NULL;

   memset(tmpmgt,0x00,sizeof(tmpmgt));

   for (i=0;i<MGTLEN;i++)
   {
      if (*(mgt+i) == 0x00 || *(mgt+i) == 0x20)
         break;

      tmpmgt[i] = *(mgt+i);
   }

   for (i = 0; i < ElementiTabellaMGT; i++)
   {
      if (strlen(tmpmgt) < strlen(GTT_MGTList[i].key))
    	  continue;

      tmplen = (short)strlen(GTT_MGTList[i].key);

      if (!memcmp(tmpmgt, GTT_MGTList[i].key, tmplen))
      {
         // trovato
         if (tmplen > keylen)
         {
            found = i;
            keylen = tmplen;
         }
      }
   }

   if (found >= 0)
   {
      tmp = &(GTT_MGTList[found].value);
   }
   return (tmp);
}

#else

// ricerca nella lista per range
treeval *SeekMGT(char *mgt)
{
	short 	i,j,tmplen,found,keylen;
	int 	iFirst,iEnd;     /*indici di range */
	int 	iCheckRes;       /* risultato delle strncmp */
//	char 	tmpmgt[MGTLEN+1];
	treeval *tmp;

	found  = -1;
	keylen = -1;
	tmp    = NULL;
// -----------------
	iFirst = 0;
	iEnd   = ElementiTabellaMGT + 1; /* inizializzazione */

    keylen = strlen(mgt);
    while (iEnd - iFirst > 1) /* ricerca binaria */
    {
    	i = (iEnd + iFirst)/2 ;

        iCheckRes = strncmp(GTT_MGTList[i].key, mgt, keylen);

        if (iCheckRes > 0)
        	iEnd = i;   /* è nella prima metà */
        else if (iCheckRes < 0)
        	iFirst = i; /* è nella seconda metà */
        else
        {
        	iEnd = iFirst = i;   /* riga beccata in pieno! */

        	break;
        }
    }

    /* se siamo arrivati qui e iCheckRes!=0,
       stiamo tra iFirst e iEnd = iFirst + 1. se è 0, siamo a iFirst
       ora bisogna vedere se c'è un range della lunghezza giusta. Torniamo indietro,
       verificando di non essere fuori range */
    while (1)
    {
    	j = iFirst;

    	while ((keylen != GTT_MGTList[j].value.mgt_length) && (j >= 0))
    		j--; /* la lunghezza non è corretta */

        if (j < 0) /* non esisteva nulla con quel range! */
        	break;

        iCheckRes = strncmp(GTT_MGTList[j].value.mgt_end, mgt, keylen);

        if (iCheckRes < 0) /* non sta in quel range */
        	break;

        found = j;

        break;
    }
// -----------------
    if (found >=0)
    	tmp = &(GTT_MGTList[found].value);

    return (tmp);
}

#endif
#endif

// load memory table from file
// return 0 if success else 1
short GT_PC_GT_Load(char TableFile[40])
{
   short 			sCount, err = 0, RecCount,i,err_close = 0;
   char 			tmpgt[GTLEN+1];
   struct LString 	filename;

   strcpy(filename.text,TableFile);
   filename.len = (int)strlen(TableFile);

   err = (short)FPDB_Open2(filename, &FGTT_List);

   if (err)
   {
      err = 1;
   }
   else
   {
      // se c'è la svuoto
      memset(GTT_Table,0x00,sizeof(GTT_Table));

      ElementiTabellaGT = 0;
      RecCount 			= 0;

      // load all records in memory
      err = (short)FPDB_ReadFirstRecord_WithoutLock2( FGTT_List,
    		  	  	  	  	  	  	  	  	  	  	  (unsigned char*)&GTT_Impianti,
    		  	  	  	  	  	  	  	  	  	  	  sizeof(GTT_Impianti),
    		  	  	  	  	  	  	  	  	  	  	  &sCount );

      while ( err == FPDB_SUCCESS && RecCount < MAXGTTENTRIES )
      {
         // per ogni record trovato inserisco in tabella e in indici
         GTT_Table[RecCount].PCF = GTT_Impianti.primarykey.point_code_format;
         GTT_Table[RecCount].PC = GTT_Impianti.primarykey.point_code;

         memset(tmpgt,0x00,sizeof(tmpgt));

         for (i = 0; i < GTLEN; i++)
         {
            if (GTT_Impianti.altkey1.gt[i] == 0x00 || GTT_Impianti.altkey1.gt[i] == 0x20)
            {
               break;
            }

            tmpgt[i] = GTT_Impianti.altkey1.gt[i];
         }

         memcpy(GTT_Table[RecCount].GT,tmpgt,GTLEN);

         if( GTT_Impianti.ssn_1 != 0x2020 ) // 0x2020 perchè il record è fillato a blank
        	 GTT_Table[RecCount].SSN_1 = GTT_Impianti.ssn_1;
         if( GTT_Impianti.ssn_2 != 0x2020 )
        	 GTT_Table[RecCount].SSN_2 = GTT_Impianti.ssn_2;
         if( GTT_Impianti.ssn_3 != 0x2020 )
        	 GTT_Table[RecCount].SSN_3 = GTT_Impianti.ssn_3;
         if( GTT_Impianti.ssn_4 != 0x2020 )
        	 GTT_Table[RecCount].SSN_4 = GTT_Impianti.ssn_4;
         if( GTT_Impianti.ssn_4 != 0x2020 )
        	 GTT_Table[RecCount].SSN_4 = GTT_Impianti.ssn_5;

         memcpy(GTT_Idx_PC[RecCount].key,&(GTT_Table[RecCount].PCF),4); // con 4 prendo i due short insieme
         GTT_Idx_PC[RecCount].ref = RecCount;

         memcpy(&(GTT_Idx_GT[RecCount].key),GTT_Table[RecCount].GT,GTLEN);
         GTT_Idx_GT[RecCount].ref = RecCount;

         RecCount++;
         ElementiTabellaGT++;

         // record successivo
         err = (short)FPDB_FindNextRecord_WithoutLock2(FGTT_List, (unsigned char*) &GTT_Impianti,sizeof(GTT_Impianti), &sCount);
      }

	  err_close = (short) MBE_FILE_CLOSE_(FGTT_List);
      //err = (short)FPDB_Close2(FGTT_List);

	  if ( RecCount < MAXGTTENTRIES)
	  {
		  log_ (LOG_DEBUG, "IMPIANTI DATA: [%d] entries loaded successfully", RecCount);
	  }
	  else
	  {
		  log_ (LOG_ERROR, "Error loading IMPIANTI DATA: Attempt to load more than [%d] entries", MAXGTTENTRIES );
	  }

      // ordinamento indici
      SortIdxPC();
      SortIdxGT();
   }

   if ( err == 1 )
	   return (0);

   return ((short) err);
}

static void SortIdxPC(void)
{
   short currelem, elemtosort,i,j;
   idxpc swapelem;

   elemtosort = currelem = 0;

   for (i = 0; i < ElementiTabellaGT; i++)
   {
      elemtosort = currelem = i;

      for (j = elemtosort; j <ElementiTabellaGT; j++)
      {
         if (memcmp(GTT_Idx_PC[currelem].key,GTT_Idx_PC[j].key,4) < 0)
            currelem = j;
      }

      if (currelem != elemtosort)
      {
         swapelem = GTT_Idx_PC[currelem];
         GTT_Idx_PC[currelem] = GTT_Idx_PC[elemtosort];
         GTT_Idx_PC[elemtosort] = swapelem;
      }
   }
}

static void SortIdxGT(void)
{
   short currelem, elemtosort,i,j;
   idxgt swapelem;

   elemtosort = currelem = 0;

   for (i = 0; i < ElementiTabellaGT; i++)
   {
      elemtosort = currelem = i;

      for (j = elemtosort; j <ElementiTabellaGT; j++)
      {
         if (memcmp(GTT_Idx_GT[currelem].key,GTT_Idx_GT[j].key,GTLEN) < 0)
            currelem = j;
      }

      if (currelem != elemtosort)
      {
         swapelem = GTT_Idx_GT[currelem];
         GTT_Idx_GT[currelem] = GTT_Idx_GT[elemtosort];
         GTT_Idx_GT[elemtosort] = swapelem;
      }
   }
}

// ricerca nella lista su chiave PCF+PC
tblpcgt *SeekPC(short PCF, short PC)
{
	short 	i,found;
	char 	key[4];
	tblpcgt	*tmp;

	found = -1;
	tmp = NULL;

	for (i = 0; i < ElementiTabellaGT; i++)
	{
		memcpy(&key[0],&PCF,2);
	  	memcpy(&key[2],&PC,2);

		if (!memcmp(key, GTT_Idx_PC[i].key, 4))
		{
			// trovato
			found = i;

			break;
		}
	}

	if (found >= 0)
	{
		tmp = &GTT_Table[GTT_Idx_PC[found].ref];
	}

	return (tmp);
}

// ricerca nella lista su chiave GT
tblpcgt *SeekGT(char *GT)
{
	short 	i,found;
	char 	tmpgt[GTLEN+1];
	tblpcgt 	*tmp;

	found = -1;
	tmp	  = NULL;

	memset(tmpgt,0x00,sizeof(tmpgt));

	for (i=0;i<GTLEN;i++)
	{
		if (*(GT+i) == 0x00 || *(GT+i) == 0x20)
			break;

		tmpgt[i] = *(GT+i);
	}

	for (i = 0; i < ElementiTabellaGT; i++)
	{
		if (!memcmp(tmpgt, GTT_Idx_GT[i].key, GTLEN))
		{
			// trovato
			found = i;
			break;
		}
	}

	if (found >= 0)
	{
		tmp = &GTT_Table[GTT_Idx_GT[found].ref];
	}

	return (tmp);
}

enum retvalues FPDB_Open2(struct LString filename, short *filenumber)
{
	short errg = 0;

	if( ( errg = MBE_FILE_OPEN_( (char *) filename.text,
                                 (short) filename.len,
                                 filenumber) ) == 0 )
      return FPDB_SUCCESS;

	return FPDB_UNRECOVERABLE;
}
enum retvalues FPDB_ReadFirstRecord_WithoutLock2 ( short filenumber,
                                                   unsigned char buffer[],
                                                   short buffer_length,
                                                   short *charead )
{
	short 	err_tmp;
    short 	dd_status;
    struct 	LString key_1;

    key_1.len = 1;

    memset(key_1.text, 0x00, key_1.len );

    dd_status = MBE_FILE_SETKEY_( filenumber,
                                  (char *) key_1.text,
                                  (short) key_1.len,
                                  0,                 /* Primary key */
                                  APPROX,
                                  0);

    dd_status = MBE_READX( filenumber,
                           (char *) buffer,
                           buffer_length,
                           charead);

    if(_status_eq(dd_status))
    {
        return FPDB_SUCCESS;
    }  /* IF READX */
    else
    {
        MBE_FILE_GETINFO_(filenumber, &err_tmp);

        FPDB_setGErrorCode((int) err_tmp);

        if(err_tmp == 1)
            return FPDB_RECOVERABLE;

        return FPDB_UNRECOVERABLE;
    }       /*  ELSE READX*/

}

short _status_eq ( short err )
{
	if ( !err )
		return 1;

	return 0;	
}

short FPDB_Close2 (short filenumber)
{
	short err_close = 0;

    if( ( err_close = MBE_FILE_CLOSE_(filenumber) ) == 0)
    	return FPDB_SUCCESS;

    return FPDB_UNRECOVERABLE;
}

enum retvalues FPDB_FindNextRecord_WithoutLock2 ( short filenumber,
                                             	  unsigned char buffer[],
                                             	  short buffer_length,
                                             	  short *charead )
{
	short 	err_tmp;
    short 	dd_status;

    dd_status = MBE_READX( filenumber,
                           (char *) buffer,
                           buffer_length,
                           charead );

    if(_status_eq(dd_status))
    {
        return FPDB_SUCCESS;
    }  /* IF READX */
    else
    {
        MBE_FILE_GETINFO_(filenumber, &err_tmp);

        FPDB_setGErrorCode((int) err_tmp);

        if(err_tmp == 1)
            return FPDB_RECOVERABLE;

        return FPDB_UNRECOVERABLE;
    }       /*  ELSE READX*/
}
