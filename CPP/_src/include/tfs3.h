/*================================================================================================
  === Traffic Steering ===========================================================================
  ================================================================================================
*/

#define TS_COUNTRY_KEYLEN			8		// Paesi
#define TS_OPERATOR_KEYLEN			18		// Operatori
#define TS_PSRULES_KEYLEN			79		// Pre-Steering rules
#define TS_STRULES_KEYLEN			149		// Soglie

#define	IMEI_PROFILE_UNKNOWN		0x20
#define	IMEI_PROFILE_STANDARD		0x30
#define	IMEI_PROFILE_SPECIFIC		0x31
#define	IMEI_PROFILE_GRANT_ALWAYS	0x32
#define	IMEI_PROFILE_STEER_ALWAYS	0x33	// not used

#define	IMSI_STATUS_GRANTED			0x30
#define	IMSI_STATUS_GRANT_ALWAYS	0x31
#define	IMSI_STATUS_STEERING		0x32
#define	IMSI_STATUS_STEER_ALWAYS	0x33
#define	IMSI_STATUS_STEER_BORDER	0x34

#define	BORDER_STEERING_NONE		0x30
#define	BORDER_STEERING_SEND		0x31
#define	BORDER_STEERING_DENY		0x32

//--- Countries (Len 160, Key0 8) ----------------------------------------------------------------
#pragma fieldalign shared2 _ts_paesi_record
typedef struct _ts_paesi_record
{
	char	paese[8];

	char	gr_pa[64];
	char	den_paese[64];
	short	max_ts;
	int		reset_ts_interval;
	char	eu_flag;
	char	filler[17];
} t_ts_paesi_record;

//--- Operators (Len 320, Key0 18, Key1 64 offset 146, Key2 16 offset 276) -----------------------
#pragma fieldalign shared2 _ts_oper_record
typedef struct _ts_oper_record
{
	char		paese[8];
	char		cod_op[10];

	char		den_op[64];
	char		den_paese[64];
	char		gruppo_op[64];		// altkey1
	char		gruppo_pa[64];
	short		max_ts;

	char		imsi_op[16];		// altkey2

	short		map_ver;
	int			reset_ts_interval;
	char		characteristics[10];
	short		steering_map_errcode;
	short		steering_lte_errcode;
	char		steering_border;  //0= disable  1=sms   2=deny
	char		tadig_code[5];
	char		filler[2];
} t_ts_oper_record;

//--- Global Titles (Len 60, Key0 24, Key1 18 offset 24) -----------------------------------------
#pragma fieldalign shared2 _ts_opergt_record
typedef struct _ts_opergt_record
{
	char		gt[24];

	char		paese[8];
	char		cod_op[10];

	char		filler[18];
} t_ts_opergt_record;

//--- Home Network LAC / CI_SAC (Len 100, Key0 4) --------------------------------------------------------------------
#pragma fieldalign shared2 _ts_border_cells_record
typedef struct _ts_border_cells_record
{
	unsigned short	lac;
	unsigned short	ci_sac;
	char			description[64];
	long long		ts;
	char			filler[24];
} t_ts_border_cells_record;

//--- Pre-Steering rules -------------------------------------------------------------------------
#pragma fieldalign shared2 _ts_psrule_record
typedef struct _ts_psrule_record
{
	short		pcf;						// pcf + pc --> impianto
	short		pc;
	char		mgt[16];
	char		paese[8];					// paese + cod_op --> operatore
	char		cod_op[10];
	char		gt[24];
	char		fascia_da[5];
	char		fascia_a[5];
	char		gg_settimana[7];
	char		stato;						// 0x31 = enabled
	short		map_reject_code;
	long long	ts1;
	long long	ts2;
	char		descr[8];
	short		lte_reject_code;
	char		imsi_white_list_enabled;	// 0x31 = enabled
	char 		filler;
} t_ts_psrule_record;

//--- Thresholds (Len 180, Key0 149) -------------------------------------------------------------
#pragma fieldalign shared2 _ts_soglie_record
typedef struct _ts_soglie_record
{
	char		gr_pa[64];
	char		gr_op[64];
	char		fascia_da[5];
	char		fascia_a[5];
	char		gg_settimana[7];
	char		user_type[4];

	char		stato;
	short		soglia;
	long 		tot_accP[2];
	long		tot_accT[2];

	char		peso;
	char		politica;

	char		filler[10];
} t_ts_soglie_record;

//--- IMSI (Len 128, Key0 16) --------------------------------------------------------------------
#pragma fieldalign shared2 _ts_imsi_record
typedef struct _ts_imsi_record
{
	char			imsi[16];

	char			paese[8];
	char			cod_op[10];
	short			num_ts;			// number of allowed steering cycles
	long long		timestamp;		// init lu cycle
	long long		last_ts_op;		// last lu received
	char			imei[15];

	char			imei_info[20];
					// imei_info[0]:
					//		0x20 -> not found
					//		0x30 -> standard
					//		0x31 -> use profile
					//		0x32 -> grant (unconditional registration)
					//		0x33 -> deny  (unconditional steering)

	char			status;
					//		0x30 -> granted
					//		0x31 -> grant (unconditional registration)
					//		0x32 -> steering
					//		0x33 -> deny  (unconditional steering)
					//		0x34 -> border steering

	char			num_lu;			// lu # inside current cycle
	char			filler2;		// era last_lu_err come char
	short			num_ts_tmax;
	long long		init_ts_tmax;
	char			trace_level;
	char			last_op_preferred;	// 0x30 -> no, 0x31 -> yes
	char			user_type;
	char			operator;
	char			msisdn[16];
	short			last_lu_err;

	// Last user home location (used for border steering, retrieved from MAP3 on 1st LU)
	unsigned short	lac;
	unsigned short	ci_sac;

	// Init TS
	long long		init_ts_op;		// first lu in country or init steering (used to estimate registration time)

	char			filler[26];
} t_ts_imsi_record;

/* Extracted IMSI
#pragma fieldalign shared2 _ts_extracted_imsi_record
typedef struct _ts_extracted_imsi_record
{
	char		imsi[16];
	char		paese[8];
	char		msisdn[16];
	char		vlr[16];
	char		filler[30];
} t_ts_extracted_imsi_record;
*/

//--- NOSTDTAC (Len 280, Key0 15) ----------------------------------------------------------------
#pragma fieldalign shared2 _ts_nostd_tac_record
typedef struct _ts_nostd_tac_record
{
	char	imei[15];


	char	trace_level;
	char	stringa[256];
	char	filler[8];
} t_ts_nostd_tac_record;


/*================================================================================================
  === GLOBAL TITLE TRANSLATOR  ===================================================================
  ================================================================================================
*/

#pragma fieldalign shared2 __du_mgt_altkey
typedef struct __du_mgt_altkey
{
   short                pcf;	// point code format
   short                pc;		// point code
} du_mgt_altkey_def;

#pragma fieldalign shared2 __du_mgt_rec
typedef struct __du_mgt_rec
{
   char					mgt[16];
   du_mgt_altkey_def	alternatekey;
   long long			lastupdatets;
   long long			insertts;
   char					c_dual_imsi;	// 0x01 ON, else (0x00, 0x20, ecc.) OFF
   char					filler[9];
} du_mgt_rec_def;

#pragma fieldalign shared2 __du_mgtr_rec
typedef struct __du_mgtr_rec
{
	char				mgt_ini[16];     // primary key
	char				mgt_end[16];
	short				mgt_length;
	du_mgt_altkey_def	alternatekey;     // alternate key (pcf + pc)
	long long			lastupdatets;
	long long			insertts;
	char				c_dual_imsi;	// 0x01 ON, else (0x00, 0x20, ecc.) OFF
	char				filler[9];
} du_mgtr_rec_def;

#pragma fieldalign shared2 __du_impianti_key
typedef struct __du_impianti_key
{
   short                pcf;	// point code format
   short                pc;		// point code
} du_impianti_key_def;

#pragma fieldalign shared2 __du_impianti_rec
typedef struct __du_impianti_rec
{
   du_impianti_key_def	primarykey;
   char                 gt[16];
   short                ssn_1;
   short                ssn_2;
   short                ssn_3;
   short                ssn_4;
   short                ssn_5;
   char                 short_desc[8];
   char                 description[30];
   long long            lastupdatets;
   long long            insertts;
   char                 filler[30];
} du_impianti_rec_def;


/*================================================================================================
  === IMEI Manager ===============================================================================
  ================================================================================================
*/

//--- IMSI DB record (Len 100, Key0 16) ----------------------------------------------------------
#pragma fieldalign shared2 _EIR_IMSIDB_RECORD
typedef struct _EIR_IMSIDB_RECORD
{
	unsigned char		imsi[16];	// Primary key: imsi (reversed)
	unsigned char		imei[16];
	unsigned char		vlr[16];
	long long			insertTime;
	long long			lastUpdateTimestamp;
	char				msisdn[16];
	long				lastUpdateInfo;
	char				flagM2M;
	char				filler[3];
	short				ip1;
	short				ip2;
	char				trigger;
	char				consumed;
	char				sv[2];
	char				consenso;
	char				user_type;
	char				operator;
	char				user_trace;
} EIR_IMSIDB_RECORD;

//--- IMSI DB record enhanced (Len 128, Key0 16) -------------------------------------------------
#pragma fieldalign shared2 _EIR_IMSIDBEN_RECORD
typedef struct _EIR_IMSIDBEN_RECORD
{
	unsigned char		imsi[16];	// Primary key: imsi (reversed)
	unsigned char		imei[16];
	unsigned char		vlr[16];
	long long			insertTime;
	long long			lastUpdateTimestamp;
	char				msisdn[16];
	long				lastUpdateInfo;
	char				flagM2M;
	char				filler[3];
	short				ip1;
	short				ip2;
	char				trigger;
	char				consumed;
	char				sv[2];
	char				consenso;
	char				user_type;
	char				operator;
	char				user_trace;

	unsigned short		lac;
	unsigned short		ci_sac;
	char				rat;
	char				filler1[23];
} EIR_IMSIDBEN_RECORD;

//--- Data sent to Trigger Manager ---------------------------------------------------------------
#pragma fieldalign shared2 _TrackingMsg_Book
typedef struct _TrackingMsg_Book
{
	short subsystem_id;
	short version;
	char trigger_value;
	char imsi[16];
} t_TrackingMsg_Book;

//--- Data received from Trigger Manager ---------------------------------------------------------
#pragma fieldalign shared2 _EIR_Tracking_Record
typedef struct _EIR_Tracking_Record
{
	EIR_IMSIDB_RECORD   eir_imsi_rec;
	char            	rat[2];
	unsigned short  	lac;
	unsigned short  	ci_sac;
	long long       	previousUpdateTimestamp;
} EIR_Tracking_Record;

#pragma fieldalign shared2 _TrackingMsg
typedef struct _TrackingMsg
{
	short subsystem_id;
	short version;
	short msg_type;
	EIR_Tracking_Record	eir_tracking_rec;
} t_TrackingMsg;

/*================================================================================================
  === Welcome ====================================================================================
  ================================================================================================
*/

#define TAG_WELCOME					12991

// Structure for WSM A03
#pragma fieldalign shared2 _ts_welcome_record
typedef struct _ts_welcome_record
{
	short	i_tag;
	char	ident[6];		// (vuoto o TFS)
	char	imsi[16];
	char	msisdn[16];
	char	tac[8];
	char	vlr[16];
	char	cc[8];
	char	codOP[10];
	char	MVNO[3];		// 010=TIM – 01A=Coop……
	char	tipo_cliente;	// 0=ABB BU; 1=ABB CO……
	char	tipo_trigger;	// 1=Border
	char	filler[13];
} t_ts_welcome_record;

// Structure for CountryCode Change Notification Queue
#pragma fieldalign shared2 _ts_cc_change_queue_record
typedef struct _ts_cc_change_queue_record
{
	char		msisdn[16];	// Primary key: msisdn (reversed)
	char		imsi[16];
	char		cc[8];
	long long	timestamp;

	char		i_retry;
	char		filler[51];
} t_ts_cc_change_queue_record;
