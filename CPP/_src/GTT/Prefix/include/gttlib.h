// ------------------------------------------------------
//
// Last Change: 10-06-2014
// ------------------------------------------------------
#ifndef _GTTLIB_H_
#define _GTTLIB_H_

// se la define di seguito esiste, verrà usato l'albero binario
// per MGT se invece non è definita, verrà usata una lista

//#define USETREEFORMGT

// le liste possibili da usare sono due, quella per il best matching
// e quella a range. La define seguente se esiste fa usare quella
// a range invece di quella best matching
//#define USERANGELIST

#define MAXGTTENTRIES   5000

#define MGTLEN          16
#define GTLEN			16

// indice 1 della lista
typedef struct
{
   char  key[4];
   short ref;
} idxpc;

// indice 2 della lista
typedef struct
{
   char  key[16];
   short ref;
} idxgt;

// record della lista
typedef struct
{
   short PCF;
   short PC;
   char  GT[16];
   short SSN_1;
   short SSN_2;
   short SSN_3;
   short SSN_4;
   short SSN_5;
} tblpcgt;

// nodo dell'albero o lista che sia
typedef struct
{
#ifdef USERANGELIST
   char  mgt_end[MGTLEN];
   short mgt_length;
#endif
   short PCF;
   short PC;
   char	 c_dualimsi_flag; 	/* 0x20 - Default | 0x01 - Dual Imsi */
} treeval;

// lista best matching
typedef struct
{
   char    key[MGTLEN];
   treeval value;
} tblmgt;

// ******************************************************************************************************
// prototipi funzioni
short GT_MGT_Load( char TableFile[40] );

short GT_PC_GT_Load( char TableFile[40] );

void CloseMGT(void);
treeval *SeekMGT(char *mgt);
tblpcgt *SeekPC(short PCF, short PC);
tblpcgt *SeekGT(char *GT);

// ******************************************************************************************************

#endif
