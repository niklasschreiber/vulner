/*----------------------------------------------------------------------------
*   PROJECT : LIB - Utility functions
*-----------------------------------------------------------------------------
*
*   File Name   : cbcenab.h
*   Last Change : 05-04-2004
*
*------------------------------------------------------------------------------
*   Description
*   -----------
*
*
*----------------------------------------------------------------------------*/

#define SHORT_BUF		20
#define LEN_CC          8
#define LEN_KEY_SOGLIE  149
#define LEN_GRP			64
#define LEN_KEY_GRPOP	82

#define ITEM_SIZE       300

#define UPD 	0
#define INS		1
#define DEL		2


/*------------- VARIABILI GLOBALI -------------*/
//FILE
char ini_file[100];
char sOperazione[20];

char acFileOperatori_Rem[100];
char acFileOperatori_Loc[100];
char acFilePaesi_Rem[100];
char acFilePaesi_Loc[100];
char acFileOperGT_Rem[100];
char acFileOperGT_Loc[100];
char acFileOperGT_Bord_Rem[100];
char acFileOperGT_Bord_Loc[100];
char acFilePreRules_Rem[100];
char acFilePreRules_Loc[100];
char acFileNostdtac_Rem[100];
char acFileNostdtac_Loc[100];
char acFileSoglie_Rem[100];
char acFileSoglie_Loc[100];
char acFileImpianti[100];
char acFileImpianti_Rem[100];
char acFileMGT[100];
char acFileMGT_Rem[100];
char acFileBord_CID_Loc[100];
char acFileBord_CID_Rem[100];

char acFileImsi[100];
char acFileImsiGsm[100];
char acFileImsiGsm_E_Loc[100];
char acFileImsiGsm_E_Rem[100];
char acFileImsiDat[100];
char acFileImsiDat_E_Loc[100];
char acFileImsiDat_E_Rem[100];
char acFileImsiLte[100];
char acFileHlrPc[100];
char ac_hexdefuser[10];

char FileInput[150];
char FileOutput[200];
char acFileIniModello[100];
char acFileApply_PS[100];
char acFileApply_ST[100];
char ac_car_table[100];
char acParamIMSI[50];

char gDataApply_ST[50];
char gDataApply_PS[50];

char 	ac_path_log_file[100];
char 	ac_log_prefix[10];
int		i_num_days_of_log;
int		i_trace_level;
int		i_log_option;
char 	*gName_cgi;
char	*gUtente;
char	*gIP;
char    ac_procname[SHORT_BUF];
char	gCaratt[11];
char	aDenCarat[10][30];

short	s_mgt_by_range;

/*--------- STRUTTURE GLOBALI  -------------*/
// ----------------------------------------------------------------------------
// Operator TFS2
// K1 = CC + CodOP
// ----------------------------------------------------------------------------

#pragma fieldalign shared2 car_struct
typedef struct car_struct
{
	char		label[20];		//es camel, gprs, servizi
	char		tipo_input[20]; //es: select, check, radio
	char		name_input[20]; //es: se select(0 - CAMEL
								//				1 - callback...)
								// se check(GPRS
								//			No Gprs)
								// se radio(119
								//			4919)
	char		value_input[20];// viene considerato solo il primo char
} car_struct_def;

typedef struct ImportOP_struct
{
	char		den_paese[65];
	char		cod_op[11];
	char		tadig_code[6];
	char		den_op[65];
	char		imsi_op[17];
	char		mgt[25];
	short		map_ver;
	short		max_ts;
	char		characteristics[10]; //Vedere file mapping caratteristiche CARTABLE
}ImportOP_struct_def;

typedef struct ImportPaesi_struct
{
	char		cc[9];
	char		den_paese[65];
	short		max_ts;
	int			reset_ts_interval;
	char		gruppo_pa[65];
	int			len_mgt;
}ImportPaesi_struct_def;

#pragma fieldalign shared2 hlrpc_struct
typedef struct hlrpc_struct
{
	char		hlr[2];
	short		pc;
}hlrpc_struct_def;

#pragma fieldalign shared2 nostdtac_struct
typedef struct nostdtac_struct
{
	char		imei[15];
	char		trace_level;
	char		str[256];
	char		filler[8];
}nostdtac_struct_def;

#pragma fieldalign shared2 _psrule_key
typedef struct _psrule_key
{
	short       pcf;	// point code format
	short       pc;		// point code
    char        mgt[16];
    char        paese[8];
    char        cod_op[10];
    char        gt[24];
    char        fascia_da[5];
    char        fascia_a[5];
    char        gg_settimana[7];
} t_psrule_key;


