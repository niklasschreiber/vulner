#include "tfs3.h"
#include "s6aipc.h"		// LTE

/*---------------------< Definitions >---------------------------------------*/

//#define TAG_IMEI_TRIGGER_ON		12122
//#define TAG_IMEI_TRIGGER_OFF	12124
#define TAG_MAP_IN				10000
#define UL_OP_CODE				2
#define UL_OP_CODE_GPRS			23

#define INI_LOAD_PARAM			0
#define INI_RELOAD_PARAM		1

#define	SYS_MSG_TIME_TIMEOUT	-22
#define	SYS_MSG_STOP			-103
#define	SYS_MSG_STOP_2			-104

#define TAG_PATHSEND_TIMEOUT	360
#define TAG_RELOAD_PARAM		1000
#define TAG_BUMP_STAT			1001
#define TAG_LOAD_RULES			1002
#define TAG_EIR_OPEN			1003
#define TAG_ALIGN_SOGLIE		1004

#define EXIT_DELAY				500L

// Processing states
#define	IMSI_NOT_FOUND			0
#define IMSI_FOUND				1
#define IMSI_IN_BLACK_LIST		2
#define IMSI_MAX_TS_REACHED		3

#define RULE_NOT_FOUND			0
#define RULE_FOUND				1

// Tags for statistics
#define STAT_MAP_IN					1		// Number of received LU
#define STAT_MAP_OUT				2		// Number of successfully sent LU

// counters for GSM LU
#define STAT_UL_RECEIVED			3		// Number of received LU
#define STAT_UL_GRANTED				4		// Number of granted LU
#define STAT_UL_DENIED				5		// Number of denied LU
#define STAT_PROCESSING_TIME		6		// Processing time (avg, min, max) x5
#define STAT_MAX_TS					7		// Number of granted LU because of reached MAX_TS
#define STAT_IMSI_WL				8		// Number of granted LU because of IMSI in WL
#define STAT_UL_BORDER_GT			9		// Number of LU from border GT (ex. STAT_IMEI_REQUEST)
#define STAT_UL_BORDER_CELL			10		// Number of LU with border cell matching (ex. STAT_IMEI_NOT_FOUND)
#define STAT_IMEI_PROFILE_REQUEST	11		// reserved (ex. STAT_IMEIINFO_REQUEST)
#define STAT_IMEI_PROFILE_FOUND		12		// reserved (ex. STAT_IMEIINFO_NOT_FOUND)
#define STAT_IMSI_INSERTED			13		// Number of IMSI insertions
#define STAT_IMSI_UPDATED			14		// Number of IMSI updates
#define STAT_OPERATOR_NOT_FOUND		15		// Number of LU requests with unknown operator
#define STAT_OPERATOR_NO_RULE		16		// Number of LU requests with no rule found
#define STAT_OPERATOR_GRANTED_NEXT	17		// Number of granted LU with preferred operator after denied LU during the same cycle
#define STAT_STEERING_GRANTED		18		// Number of granted LU with steering algorithm
#define STAT_NOSTD_GRANTED			19		// Number of granted LU with non-standard terminal
#define STAT_OPERATOR_GRANTED		20		// Number of granted LU with preferred operator
#define STAT_IMSI_INSERTED_DAY		21		// Number of user managed per day

#define STAT_MTS_SEND_OK			22		// Number of successful MTS_SEND (eir|wsm)
#define STAT_MTS_SEND_KO			23		// Number of unsuccessful MTS_SEND (eir|wsm)
#define STAT_PS_RECV				24		// Number of received LU on Pre-Steering x Operator
#define STAT_PS_RESP				25		// Number of answered LU on Pre-Steering x Operator
#define STAT_PS_FORW				26		// Number of forwarded LU on Pre-Steering x Operator
#define STAT_TRG_RECV				27		// Number of received triggers
#define STAT_TRG_UPD				28		// Number of cancelled IMSIs
#define STAT_TRG_ERR				29		// Number of IMSIs not found

#define STAT_UL_GSM_E164			30		// Number of GSM  LU with E.164 routing
#define STAT_UL_GPRS_E164			31		// Number of GPRS LU with E.164 routing

// unused counter 					32

// replicated counters for GPRS LU with 30-shift: 33 to 51

#define STAT_IMSI_DATONLY_DAY		52		// Number of data only user managed per day

// replicated counters for LTE LU with 50-shift: 53 to 71

#define STAT_MAP3_USR_OK			72		// Number of successful USR requests
#define STAT_MAP3_USR_KO			73		// Number of failed USR requests
#define STAT_MAP3_LOC_OK			74		// Number of successful LOC requests
#define STAT_MAP3_LOC_KO			75		// Number of failed LOC requests

#define STAT_REG_TIME_ZERO			76
#define STAT_REG_TIME_1MIN			77
#define STAT_REG_TIME_2MIN			78
#define STAT_REG_TIME_3MIN			79
#define STAT_REG_TIME_OVER			80

// OBSOLETE
// reserved for EU Roaming IF4:		76 to 81
// reserved for EU Roaming SSL GW:	82 to 84

// EMS event codes
#define	EMS_EVT_PROCESS_STARTED		2000
#define	EMS_EVT_PROCESS_STOPPED		2001
#define	EMS_EVT_MISSING_PARAM		2002
#define	EMS_EVT_MBE_ERROR			2003
#define	EMS_EVT_MTS_ERROR_OPEN		2004
#define	EMS_EVT_MTS_ERROR_CLOSE		2005
#define	EMS_EVT_RESPONSE_TIME		2006
#define	EMS_EVT_OPER_LOADING		2007
#define	EMS_EVT_OPER_NOT_FOUND		2008
#define	EMS_EVT_EIR_ERROR_OPEN		2009
#define	EMS_EVT_EIR_ERROR_CLOSE		2010
#define	EMS_EVT_SS_SEND_ERROR		2011
#define EMS_EVT_IO_RECEIVE_ERR_OPEN	2012
#define EMS_EVT_IO_RECEIVE_ERR_READ	2013
#define EMS_EVT_SIGNALTIMEOUT_ERROR	2014

// soglia fuzzy per le statistiche
#define FUZZY 5

#pragma fieldalign shared2 io_common_blk
typedef struct io_common_blk
{
    char  fname[36];
    short id;
    short error;
    char  data[2048];
} IO_RECEIVE;

#pragma fieldalign shared2 io_sysmsg_timeout
typedef struct io_sysmsg_timeout
{
    short id;
    short s_par;
    long  l_par;
} IO_SYSMSG_TIMEOUT;

typedef struct s_appl_ip
{
	short	i_tag;
	short	i_elemId;
	char	tlvpname[6];
	char	data[1014];
} t_appl_ip;

/*--- MAP -------------------------------------------------------------------*/

#define MAX_EXTERNAL_REFERENCE_LENGTH	512
//#define MAX_EXTERNAL_REFERENCE_LENGTH	420

/*
#define choice_mts_address				0x01
#define choice_process_name				0x02
#define choice_extend_process_name		0x03

#pragma fieldalign shared2 _IPC_Address
typedef struct _IPC_Address
{
	unsigned char choice;
	union {
		P2_MTS_TAG_DEF	mts_address;
		char	process_name[8];
		char	extend_process_name[8];
		//P2_MTS_PROC_ADDR_DEF	process_name;
		//P2_MTS_EPROC_ADDR_DEF	extend_process_name;
	} address;
} IPC_Address;
*/

// Data received from MAP inbound process
#pragma fieldalign shared2 _ts_data
typedef struct _ts_data
{
	short				i_tag;
	short				op_code;

	INS_AddressString	MGT_mitt;
	INS_AddressString	MGT_dest;
	INS_String			imsi;			// 06/09/2012 - Campo decodificato da layer MAP
	
	// 06/04/2006 - portata da 420 (Italia) a 452 (Argentina/Brasile)
	// 21/10/2008 - portata a 512
	char				ExternalReference[MAX_EXTERNAL_REFERENCE_LENGTH];
	
	short				ResultType;
	short				ResultCode;

	//SMP_RMI_Address		result_address;
	IPC_Address			result_address;

	char				MAPErrorCode;
	char				proxy;			// 0x00 = no proxy, 0x01 = LBO, 0x02 = ARP
	short				arpId;
	char				eu_flag;		// 0x01 = EU
	char				c_E164;			// 0x01 = E.164 else E.214
	char				filler[4];
} t_ts_data;

/*--- MBEs ------------------------------------------------------------------*/

// Operator: K1 = 18
#pragma fieldalign shared2 _ts_oper_record_old
typedef struct _ts_oper_record_old
{
	char		paese[8];
	char		cod_op[10];
	char		den_op[30];
	char		den_paese[30];
	char		gruppo_op[30];
	char		gruppo_pa[30];
	short		max_ts;
	char		imsi_op[16];
	short		map_ver;
	int			reset_ts_interval;
	char		characteristics[10];
	char		steering_map_errcode;	// MAP error da tornare in caso di steering
	char		filler[15];
} t_ts_oper_record_old;

// Operator GT: K1 = 24, K2 = 18
#pragma fieldalign shared2 _ts_opergt_record_old
typedef struct _ts_opergt_record_old
{
	char		gt[24];
	char		paese[8];
	char		cod_op[10];
	char		filler[18];
} t_ts_opergt_record_old;

// Soglie
#define TS_SOGLIE_KEYLEN_OLD	77
#pragma fieldalign shared2 _ts_soglie_record_old
typedef struct _ts_soglie_record_old
{
	char		gr_pa[30];
	char		gr_op[30];
	char		fascia_da[5];
	char		fascia_a[5];
	char		gg_settimana[7];
	char		stato;
	short		soglia;
	long 		tot_accP[2];
	long		tot_accT[2];

	// FB - Gestione N soglie
	//char		filler[14];
	char		peso;
	char		politica;
	short		pplmn1;
	short		pplmn2;
	char		filler[8];
} t_ts_soglie_record_old;

#pragma fieldalign shared2 _ts_paesi_record_old
typedef struct _ts_paesi_record_old
{
	char	paese[8];
	char	gr_pa[30];
	char	den_paese[30];
	short	max_ts;
	int		reset_ts_interval;
	char	eu_flag;
	char	filler;
} t_ts_paesi_record_old;

#pragma fieldalign shared2 _ts_grpoper_record_old
typedef struct _ts_grpoper_record_old
{
	char	gr_op[30];
	char	cod_op[10];
	char	filler[10];
} t_ts_grpoper_record_old;

//----------------------------------------------------------

#define TAG_STD_MAP3_REQ		1500
#define TAG_STD_MAP3_RESP		1503

// Structure for data exchange
typedef struct s_std_ip
{
	short	i_tag;
	char	data[1022];
} t_std_ip;

//----------------------------------------------------------
//--- Strutture caricate in memoria ------------------------
//----------------------------------------------------------

#pragma fieldalign shared2 _ts_soglie_mem_record
typedef struct _ts_soglie_mem_record
{
	short	soglia;
	char	peso;
	char	politica;
	char	key[TS_STRULES_KEYLEN];
	struct	_ts_soglie_mem_record *next;
} t_ts_soglie_mem_record;

#pragma fieldalign shared2 _ts_oper_mem_record
typedef struct _ts_oper_mem_record
{
	char		paese[8];
	char		cod_op[10];
	char		mccmnc[8];
	char		max_ts;
	char		steering_map_errcode;
	short		steering_lte_errcode;
	long long	ll_reset_ts_interval;
	char		steering_border;
	char		ptr_count;					// quanti elementi puntano a questa struttura
	t_ts_soglie_mem_record	*pa_op_list;
	t_ts_soglie_mem_record	*gr_pa_gr_op_list;
	t_ts_soglie_mem_record	*pa_list;
	t_ts_soglie_mem_record	*gr_pa_list;
} t_ts_oper_mem_record;

#pragma fieldalign shared2 _ts_psoper_mem_record
typedef struct _ts_psoper_mem_record
{
	char		paese[8];
	char		cod_op[10];
	short		ptr_count;	// quanti elementi puntano a questa struttura
} t_ts_psoper_mem_record;

#pragma fieldalign shared2 _ts_psrule_mem_record
typedef struct _ts_psrule_mem_record
{
	char		fascia_da[5];
	char		fascia_a[5];
	char		gg_settimana[7];
	char		map_reject_code;
	short		lte_reject_code;
	char		imsi_white_list_enabled;
	short		ptr_count;	// quanti elementi puntano a questa struttura
	struct _ts_psrule_mem_record	*next;
} t_ts_psrule_mem_record;
