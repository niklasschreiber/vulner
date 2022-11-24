
#include "SLog.h"

/*------------------ DEFINE -------------------*/
#define SQL_NOT_FOUND      100
#define SQL_DUPLICATE_KEY  -8227
#define SQL_OK             0

#define DESC_ORDER		0x4000
#define MAXRECORD		30

#define APPROXIMATE		0
#define GENERIC			1
#define EXACT			2

#define SSP_FALSE       0
#define SSP_TRUE        1
//#define SSP_BUFFER_LEN  1024

#define TEXT_CODE       0x0F
/* ----------------------------------------------------------------------------
** Defines value for log record level
-----------------------------------------------------------------------------*/

#define FALSE               0
#define TRUE				1

short		disp_Top;

//---- LOG SPOOLER --- INIZIO ----------//

// char   acSpooler_Pathmon[30];
// char   acSpooler_ServerClass[30];

#define EVT_ON_ERROR       1

#define SLOG_OK            0
#define SLOG_ERROR         1
#define SLOG_NOPRIVILEGES  2
#define SLOG_NORECORD      3

/*------------- VARIABILI GLOBALI -------------*/
short LOGResult;
LOG_SPOOL_INTERPROC_V1  log_spooler;

//---- LOG SPOOLER ---- FINE -----------//

#define  INI_EMS         "EMS"

/*------------------ GLOBAL VARIABLES -------------------*/
void Display_TOP(char *txt);
void  Display_BOTTOM(void);
void  Display_Error(char *txt);
char *AlltrimString( char *str1 );
char  *TrimString( char *str1 );
void  GetLocalTimeStamp(long long *jts);
void  ConvertLocal_To_GMT(long long *loc_jts, long long jts);
void  ConvertGMT_To_Local(long long *loc_jts, long long jts);
void  CambiaCar( char *instr );
char  *Togli_Spazi(char *str);
short User_is_RW(void);
void  Display_Message(short nTipo, char *sTxt, char *sMessaggio);
short Apri_File(char *nomefile, short *handle, short display, short tipo);
void GetTimeStamp(long long *jts);
void GetLocalTimeStamp(long long *jts);
long long string2TS(char *stringa);
long long stringAAMMGG2TS(char *stringa);
char *TS2string(char stringa[], long long jts);
char *TS2stringAAMMGG(char stringa[], long long jts);
void shortToHex(unsigned short usval, char *hexbuf);
char luhnvalue(char *card);
//int SetUserId( void );
char *SistemaApice(char stringa[],char *sPaese);
char *GetToken( char *s, register char *delim );
//int get_profile_string_mia( char *filename, char *section_name, char *entry_name, int  *found, char *value_read );
void Guardian2OssPath( char *ac_in, char *ac_gua );
void Oss2GuardianPath( char *ac_in, char *ac_gua );
void Lettura_FileIni();
time_t String2TS_time_t( char *strdata );
short get_process_name( char* ac_procname );
long long HHMM2TS(char *hh_mm);
void Trim_inMezzo( char *str1, char *sret);
char *GetStringNT (char *stringa, int max_length);
short InitSLOG(void);
