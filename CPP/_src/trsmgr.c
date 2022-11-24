/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsmgr.c
*   Last Modified : 03/04/2017
*------------------------------------------------------------------------------
*   Description
*   -----------
*   Traffic Steering Manager
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   Implements the logic of the service (thresholds, max. attempts, etc.)
*
*   12/01/2017 - Removed separate LTE management (merged with GPRS into DAT database)
*	07/03/2017 - Added management of unknown GT or MCC/MNC (block or forward)
*	03/04/2017 - Added logging of registration time through additional log file
*	24/04/2019 - Added logging of registration time through statistics
*	24/04/2019 - Added writing CCCque with country change events
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L18_24APR2019_KTSTEA10_01_AEB() {};
#endif

/*---------------------< Include files >-------------------------------------*/

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <memory.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <tal.h>
#include <time.h>
#include <sys/stat.h>

#include <cextdecs.h>
#include <cssinc.cext>
#include <p2apdf.h>
#include "usrlib.h"

#include "mbedb.h"
#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"
#include "sspstat.h"
#include "ssptlv.h"

#include "ds.h"
#include "ts.h"
#include "roamun.h"

/*---------------------< Definitions >---------------------------------------*/

#define	INI_SECTION_NAME			"MANAGER"
#define LTE_HSS_KEY					"LTE_"

#define MAP3_LOC_RECV_ID			1506
#define MAP3_LOC_RESP_ID			1507
#define MAP3_LOC_RECV_TAG			"LS"
#define MAP3_LOC_RESP_TAG			"RS"

#define MAP3_OPE_RECV_ID			1504
#define MAP3_OPE_RESP_ID			1505
#define MAP3_OPE_RECV_TAG			"OI"
#define MAP3_OPE_RESP_TAG			"RO"

/*---------------------< Parameters >----------------------------------------*/

//LOG
char		ac_path_log_file[30];
char		ac_log_prefix[10];
int			i_num_days_of_log;
int			i_trace_level;
int			i_log_options;
char		ac_log_trace_string[128];

//LOG-ROAMING-TIME (to be replaced by statistics)
char		c_log_enabled_rt;
char		ac_path_log_file_rt[30];
char		ac_log_prefix_rt[10];
int			i_num_days_of_log_rt;
int			i_trace_level_rt;
int			i_log_options_rt;

//STAT
char		ac_path_stat_file[30];
char		ac_stat_prefix[3];
char		c_stat_reg_user_type;		// Include user type in various stats register
short		i_stat_group;
short		i_stat_max_registers;
short		i_stat_max_counters;
int			i_stat_bump_interval;

//EMS
short		s_ems_subsystem;
char		ac_ems_owner[16];
char		ac_ems_version[16];
char		ac_ems_appl[32];
char		ac_ems_text[168];
long long	ll_ems_time_interval;

char		ac_oper_path[48];
char		ac_opergt_path[48];
char		ac_bordgt_path[48];
char		ac_soglie_mbe_path[48];
char		ac_nostd_tac_mbe_path[48];
char		ac_border_cell_mbe_path[48];
char		ac_imsi_gsm_mbe_path[48];
char		ac_imsi_dat_mbe_path[48];
char		ac_ccc_que_path[48];
char		ac_roaming_eu_if4_path[48];
char		ac_apply_ts_path[48];

short		s_block_unknown_gt;
short		s_block_unknown_mccmnc;
int			i_mbe_timeout;
int			i_load_rules_interval;
int			i_load_rules_cpu_shift;

char		ac_national_country_code[8];

char		c_node_id;
short		s_steering_task_id;
short		s_steering_server_class;

long long	ll_reset_ts_interval;		// max_ts reset interval
long long	ll_tmin;					// min interval between 2 LUs
long long	ll_tmax;
char		ac_default_imei_info[21];
int			i_max_process_time;			// processing time (ms) threshold for alert
short		s_steering_method;

char		c_flag_grant_first_lu;
char		c_flag_use_map3_loc;
char		c_flag_use_map3_usr;
char		c_flag_use_trigger;

char		ac_map3_loc_process_name[16];
char		ac_map3_loc_class_name[24];
int			i_map3_loc_validity;
long		l_map3_loc_timeout;

char		ac_map3_usr_type_table[48];
char		ac_map3_usr_process_name[16];
char		ac_map3_usr_class_name[24];
int			i_map3_usr_validity;
long		l_map3_usr_timeout;
char		c_map3_usr_require_imei;
char		c_default_user_type;

char		c_ccc_enabled;

char		c_welcome_enabled;
short		i_welcome_subsys;
short		i_welcome_class;
long long	ll_welcome_snd_interval;

short		i_eir_trigger_subsystem;
short		i_eir_trigger_taskid;
short		i_eir_trigger_serverclass;

char		ac_daily_user_file_path[64];

/*---------------------< Static and Global Variables >-----------------------*/

IO_RECEIVE  ReceiveIO;



char	ac_my_process_name[10];

short	i_my_node_id;
short	i_my_cpu;
short	i_loop_timer;
short	i_read_timeout;

char	*pc_ini_file;
char	ac_path_file_ini_oss[64];

short	i_logfile_id_rt = -1;	// Logfile for roaming registration time

short	s_soglie_mbe_id = 0;
short	s_nostd_tac_mbe_id = 0;
short	s_border_cell_mbe_id = 0;
short	s_ccc_que_id = 0;
short	s_roaming_eu_if4_id = 0;

char	ac_imsi[MAX_INS_STRING_LENGTH];
char	ac_gt[MAX_INS_STRING_LENGTH];

char	ac_ret[100];
char	ac_paese[9];
char	ac_operatore[11];
char	ac_ut_cc_op[24];

char	ac_imei[16];
char	ac_rev_imsi[17];
char	ac_imsi_suffix[MAX_INS_STRING_LENGTH];

AVLTREE		gt_oper_list;		// Hashtable for gt, data holds the rules to be updated
AVLTREE		gt_bord_list;		// Hashtable for border gt, data also holds the rules to be updated
AVLTREE		tac_imei_list;		// Hashtable for nostdtac db
AVLTREE		border_cell_list;	// Hashtable for bordercid db

t_ts_data	map_buffer;
TFS_LTE_IPC	lte_buffer;

FILE		*p_dump_daily_user_handle = NULL;
char		ac_dump_daily_user_path[64];
char		ac_date[10];
short		s_curr_day_of_week = -1;
short		s_next_day_of_week;

short		s_stat_net_type_shift = 0;
short		*p_op_code;			// GSM (2) | GPRS(23) | LTE (316)
short		*p_result_type;		// Relay (0) | Steering (1)

/* global SQL variables */
EXEC SQL BEGIN DECLARE SECTION;

	char sql_str[300];
	short sqlcode;

	exec SQL invoke =USRTYPE as s_map3_usr_type;
	typedef struct s_map3_usr_type t_map3_usr_type;
	t_map3_usr_type	usr_type;

EXEC SQL END DECLARE SECTION;

exec sql INCLUDE sqlca;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization(char reload);
void Print_Process_Parameters();
short checkIniFile();

void Open_Input_Queue(IO_RECEIVE *ReceiveIO);
short mbeFileOpen(char *filename, short *fileid);
void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...);
short Func_PATHSEND_Proc(char *ac_process_name, char *ac_serverclass_name, char *msg_buffer, short msg_buffer_size, long timeout);
short Pathsend_info(short *p_err, short *fs_err);

long long CurrentLastMidnightJTS();
char *ConvertJTS2String(long long jts, char *ts);
short getDayOfWeek();
char *getDeferredTime(char *def_time, time_t time, int hour, int min, int sec);
char *getYeartoDay(char *ts);
void checkProcessTime(long long timestamp);
void logRegistrationTime(t_ts_imsi_record *imsi_rec, long long ts, char *gt, char *oper, short opcode, char *imsi);

short MAP_ReplyOut(t_ts_data *mbuffer);
short LTE_ReplyOut(TFS_LTE_IPC *lbuffer);
short SendToEIRTrigger(t_TrackingMsg_Book *mbuffer);
short SendToWelcome(t_ts_welcome_record *mbuffer);

short isOperatorListChanged();
void freeOperatorData(void *data);
void freeOperatorDataRule(t_ts_soglie_mem_record *rule);
short LoadOperatorList();
t_ts_soglie_mem_record *loadOperatorRule(short s_mbe_id, char *key, short keylen);
t_ts_soglie_mem_record *seekOperatorRule(t_ts_soglie_mem_record *rule_list, char user_type);
short isRuleValid(t_ts_soglie_mem_record *rule, char user_type);
short isRuleOverThreshold(t_ts_soglie_mem_record *rule, short s_check_threshold);
short areAllRulesOverThreshold(t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold);
short arePrimaryRulesOverThreshold(t_ts_soglie_mem_record *srule, t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold);
void updateRule(t_ts_soglie_mem_record *rule, short s_check_threshold, short s_pref_acc, short s_tot_acc);
void updateRules(t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold, short s_pref_acc, short s_tot_acc);
void updateAllRules(t_ts_oper_mem_record *oper_mem_rec, t_ts_imsi_record *imsi_rec, t_ts_soglie_mem_record *prule, t_ts_soglie_mem_record *orules, char *ac_str, short i_idx);

short loadTacImeiList();
short getUserDeviceInfo(char *imsi, t_ts_imsi_record *imsi_rec);
short getTacImeiProfile(char *key, t_ts_imsi_record *imsi_record);

short loadBorderCellList();
short getUserLocation(char *imsi, t_ts_imsi_record *imsi_rec);

char isBorderCell(unsigned short lac, unsigned short ci_sac);
char mapUserType(char *ac_ST, char *ac_BC, char *ac_PH);

short insertCCCEvent(t_ts_imsi_record *imsi_rec);
short insertRoamEU(t_ts_imsi_record *imsi_rec, char status, char changed, char *mccmnc);

/*---------------------------------------------------------------------------*/
int main (short argc, char * argv[])
{
	short	rc;					// Return code after reading a new message
	short	Stop = 0;			// Whether to exit the infinite loop
	short	err;				// Return code for Welcome DB operations
	//short	file_id;			// Source of the received message
	short	receive_cnt;
	short	ret = 0;
	//long	i_tag;
	int		i;
	short	i_tfs_tag;
	int		i_stat_bump_retry_interval;
	short	s_imei_info_index;

	long long	ll_midnight;
	long long	ll_ems_time_last_welcome_jts = 0;
	long long	ll_new_processing_time;

	short	sender_info[17];
    short	sender_handle[10];
    char	sender_process_name[16];
    short	sender_process_maxlen = sizeof(sender_process_name);

    short	sender_mom_handle[10];
    char	sender_mom_process_name[16];
    short	sender_mom_process_maxlen = sizeof(sender_mom_process_name);

	unsigned char	b_imsi_state;
	unsigned char	b_imei_nosteering;
	unsigned char	b_first_lu_in_cc;
	unsigned char	b_new_lu;
	unsigned char	b_border_cell;
	unsigned char	b_lu_accept;
	unsigned char	b_primary;
	short			s_stat_id;
	short			s_steering_error_code;
	char			c_last_op_preferred;
	char			c_welcome_send;
	char			c_cc_changed;
	char			c_op_changed;
	char			c_prev_imsi_status;
	short			arp_id;
	char			eu_flag;

	short			s_imsi_gsm_mbe_id = 0;
	short			s_imsi_dat_mbe_id = 0;
//	short			s_imsi_lte_mbe_id = 0;

	t_ts_imsi_record		imsi_rec, imsi_tmp_rec;
	t_ts_oper_mem_record	*oper_mem_rec;
	t_ts_oper_mem_record	*bord_mem_rec;
	t_ts_soglie_mem_record	*preferred_rule, *other_rules;
	t_ts_soglie_mem_record	*primary_rule, *secondary_rule;
	t_ts_welcome_record		welcome_rec;

	IO_SYSMSG_TIMEOUT		signal;

	short		*p_imsi_mbe_id;
	char		*p_imsi_mbe_path;
	char		*welcome_cod_op;

	Process_Initialization(0);

//--- Open $RECEIVE -------------------------------------------------------------------------------------

	Open_Input_Queue(&ReceiveIO);

//--- Open databases ------------------------------------------------------------------------------------

	Stop = mbeFileOpen(ac_soglie_mbe_path, &s_soglie_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_imsi_gsm_mbe_path, &s_imsi_gsm_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_imsi_dat_mbe_path, &s_imsi_dat_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_nostd_tac_mbe_path, &s_nostd_tac_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_border_cell_mbe_path, &s_border_cell_mbe_id);
	if (!Stop && c_ccc_enabled && ac_ccc_que_path[0]) Stop = mbeFileOpen(ac_ccc_que_path, &s_ccc_que_id);
	if (!Stop && ac_roaming_eu_if4_path[0]) Stop = mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);

//--- Load service data ---------------------------------------------------------------------------------

	// Load operator list
	if (!Stop && isOperatorListChanged())
	{
		Stop = LoadOperatorList();
	}

	// Load specific device profiles
	if (!Stop)
	{
		tac_imei_list = avlMake();
		Stop = loadTacImeiList();
	}

	// Load home network border lac & cells
	if (!Stop)
	{
		border_cell_list = avlMake();
		Stop = loadBorderCellList();
	}

	// Open Daily User file
	if (!Stop)
	{
		if (ac_daily_user_file_path[0])
		{
			s_curr_day_of_week = getDayOfWeek();
			getYeartoDay(ac_date);

			sprintf(ac_dump_daily_user_path, "%s%s", ac_daily_user_file_path, ac_date);
			if ((p_dump_daily_user_handle = fopen_oss(ac_dump_daily_user_path, "a+")) == NULL)
			{
				log(LOG_ERROR, "error opening %s", ac_dump_daily_user_path);
				Stop++;
			}
		}
	}

	if (!Stop)
	{
		log(LOG_ERROR, "Process started");
		log(LOG_ERROR, "Sizeof MAP buffer: %d", sizeof(t_ts_data));
		log(LOG_ERROR, "Sizeof LTE buffer: %d", sizeof(TFS_LTE_IPC));
		//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

		if (i_load_rules_interval > 0)
			SIGNALTIMEOUT_(i_load_rules_interval + i_load_rules_cpu_shift*i_my_cpu, 0, TAG_LOAD_RULES);
		if (i_stat_bump_interval > 0)
			SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
	}

//--- Main Loop -----------------------------------------------------------------------------------------

	while (!Stop) 
	{
		rc = RECEIVE_( ReceiveIO.data, (short)sizeof(ReceiveIO.data), &receive_cnt, P2_GEN_WAITFOREVER );
		log(LOG_DEBUG, "Rcv: rc = %d, cnt = %d", rc, receive_cnt);

		// Daily User file change
		if (ac_daily_user_file_path[0])
		{
			s_next_day_of_week = getDayOfWeek();
			if (s_next_day_of_week != s_curr_day_of_week)
			{
				getYeartoDay(ac_date);

				fclose(p_dump_daily_user_handle);
				sprintf(ac_dump_daily_user_path, "%s%s", ac_daily_user_file_path, ac_date);
				if ((p_dump_daily_user_handle = fopen_oss(ac_dump_daily_user_path, "a+")) == NULL)
					log(LOG_WARNING, "error opening %s", ac_dump_daily_user_path);

				s_curr_day_of_week = s_next_day_of_week;
			}
		}

		b_imei_nosteering = 0;
		b_first_lu_in_cc = 0;
		ac_ret[0] = 0;

		switch(rc)
		{
			case 0:
			{
				memcpy((char *)&i_tfs_tag, ReceiveIO.data, 2);

				ll_new_processing_time = JULIANTIMESTAMP();
				ll_midnight = CurrentLastMidnightJTS();
				c_welcome_send = 0;
				memset(ac_imei, 0, sizeof(ac_imei));

//--- Lookup for operator based on received GT or MCC/MNC -----------------------------------------------

				if (i_tfs_tag == TAG_MAP_IN)
				{
					memcpy((char *)&map_buffer, ReceiveIO.data, sizeof(map_buffer));
					p_op_code = &(map_buffer.op_code);
					p_result_type = &(map_buffer.ResultType);

					// Lookup operator corresponding to GT
					memset(ac_gt, 0x00, sizeof(ac_gt));
					memcpy(ac_gt, map_buffer.MGT_mitt.address.value, map_buffer.MGT_mitt.address.length);
					oper_mem_rec = avlFindLpm(gt_oper_list, ac_gt);
					if (c_flag_use_map3_loc)
						bord_mem_rec = avlFindLpm(gt_bord_list, ac_gt);
					else
						bord_mem_rec = AVLNULL;

					// IMSI
					memset(ac_imsi, 0x00, sizeof(ac_imsi));
					if (map_buffer.imsi.length)
					{
						// Got IMSI from MAP layer
						memcpy(ac_imsi, map_buffer.imsi.value, map_buffer.imsi.length);
					}

					// MAP error code
					if (oper_mem_rec)
						s_steering_error_code = oper_mem_rec->steering_map_errcode;
				}
				else if (i_tfs_tag == TFS_LTE)
				{
					memcpy((char *)&lte_buffer, ReceiveIO.data, sizeof(lte_buffer));
					p_op_code = &(lte_buffer.i_op);
					p_result_type = &(lte_buffer.ResultType);

					// Lookup operator corresponding to MCC+MNC
					sprintf(ac_gt, "%s%s", LTE_HSS_KEY, lte_buffer.ac_visited_PLMN_Id);
					oper_mem_rec = avlFind(gt_oper_list, ac_gt);
					bord_mem_rec = AVLNULL;	// border has no meaning for LTE

					// IMSI
					memset(ac_imsi, 0x00, sizeof(ac_imsi));
					memcpy(ac_imsi, lte_buffer.imsi.value, lte_buffer.imsi.length);

					// LTE error code
					if (oper_mem_rec)
						s_steering_error_code = oper_mem_rec->steering_lte_errcode;
				}
				else
				{
					log(LOG_WARNING, "rcv unexpected tag %d", i_tfs_tag);
					REPLY_();
					break;
				}

				if (oper_mem_rec != AVLNULL)
				{
					// Operator found
					memset(ac_paese, 0, sizeof(ac_paese));
					memcpy(ac_paese, oper_mem_rec->paese, sizeof(oper_mem_rec->paese));
					TrimString(ac_paese);
					memset(ac_operatore, 0, sizeof(ac_operatore));
					memcpy(ac_operatore, oper_mem_rec->cod_op, sizeof(oper_mem_rec->cod_op));
					TrimString(ac_operatore);
					sprintf(ac_ut_cc_op, "-|%s|%s", ac_paese, ac_operatore);
				}
				else
				{
					// Unknown operator
					strcpy(ac_paese, "-");
					strcpy(ac_operatore, "-");
					strcpy(ac_ut_cc_op, "-|-|-");
				}

//--- Lookup for IMSI and initialize user status --------------------------------------------------------

				if ((i_tfs_tag == TAG_MAP_IN && (*p_op_code == UL_OP_CODE || *p_op_code == UL_OP_CODE_GPRS)) ||
					(i_tfs_tag == TFS_LTE))
				{
					if (strcmp(ac_operatore, "-"))
					{
						ret = 0;
						b_new_lu = 1;
						b_border_cell = 0;

						memset(ac_rev_imsi, 0x20, sizeof(ac_rev_imsi));
						strcpy(ac_rev_imsi+(sizeof(ac_rev_imsi)-(strlen(ac_imsi)+1)), ac_imsi);
						StringReverse(ac_rev_imsi);

						if (*p_op_code == UL_OP_CODE)
						{
							p_imsi_mbe_id = &s_imsi_gsm_mbe_id;
							p_imsi_mbe_path = ac_imsi_gsm_mbe_path;
							s_stat_net_type_shift = 0;

							arp_id = map_buffer.arpId;
							eu_flag = map_buffer.eu_flag;
						}
						else if (*p_op_code == UL_OP_CODE_GPRS)
						{
							p_imsi_mbe_id = &s_imsi_dat_mbe_id;
							p_imsi_mbe_path = ac_imsi_dat_mbe_path;
							s_stat_net_type_shift = 30;

							arp_id = map_buffer.arpId;
							eu_flag = map_buffer.eu_flag;
						}
						else
						{
							//p_imsi_mbe_id = &s_imsi_lte_mbe_id;
							p_imsi_mbe_id = &s_imsi_dat_mbe_id;
							//p_imsi_mbe_path = ac_imsi_lte_mbe_path;
							p_imsi_mbe_path = ac_imsi_dat_mbe_path;
							s_stat_net_type_shift = 50;

							arp_id = lte_buffer.arpId;
							eu_flag = lte_buffer.eu_flag;
						}
						AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP_IN);
						AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_RECEIVED);

						if (!(err = MBE_FILE_SETKEY_(*p_imsi_mbe_id, ac_rev_imsi, (short)strlen(ac_rev_imsi), 0, 2)))
						{
							// 23.08.05 - MM : modifica da readlock a read
							//if (!(err = MBE_READX(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec))))
							if (!(err = MbeFileRead_nw(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec))))
							{
								// Check country change
								if (memcmp(imsi_rec.paese, oper_mem_rec->paese, sizeof(imsi_rec.paese)))
									c_cc_changed = 1;
								else
									c_cc_changed = 0;

								// Check operator change
								if (memcmp(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op)))
									c_op_changed = 1;
								else
									c_op_changed = 0;

								// Remember last user status (e.g. for registration time)
								c_prev_imsi_status = imsi_rec.status;

								// Set trace level, copy IMEI
								if (imsi_rec.trace_level != 0x20)
									log_param(imsi_rec.trace_level, i_log_options, "");
								memcpy(ac_imei, imsi_rec.imei, sizeof(imsi_rec.imei));
								TrimString(ac_imei);

								// Reset flag su last operator preferred
								c_last_op_preferred = imsi_rec.last_op_preferred;
								imsi_rec.last_op_preferred = 0x30;

								// Reset IMEI e strategia su prima LU del giorno
								if (imsi_rec.timestamp < ll_midnight)
								{
									memset(imsi_rec.imei, 0x20, sizeof(imsi_rec.imei));
									memcpy(imsi_rec.imei_info, ac_default_imei_info, sizeof(imsi_rec.imei_info));
									imsi_rec.num_ts_tmax = imsi_rec.imei_info[1] + 1;
								}
								if ( imsi_rec.imei_info[1] == 0x00 )
								{
									b_imei_nosteering = 1;
								}

								log(LOG_DEBUG, "%s|%s|%d|%s|%s|%Ld seconds since last LU", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, (ll_new_processing_time - imsi_rec.last_ts_op) / 1000000);

								// Accettare sempre (imsi in white list)
								if (imsi_rec.status == IMSI_STATUS_GRANT_ALWAYS)
								{
									b_imsi_state = IMSI_IN_BLACK_LIST;
									memcpy(imsi_rec.paese, oper_mem_rec->paese, sizeof(imsi_rec.paese));
									memcpy(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op));
									strcpy(ac_ret, "access granted - imsi in white list");
									AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_WL);
								}
								// Rifiutare sempre (imsi in barred list)
								else if (imsi_rec.status == IMSI_STATUS_STEER_ALWAYS)
								{
									b_imsi_state = IMSI_IN_BLACK_LIST;
									memcpy(imsi_rec.paese, oper_mem_rec->paese, sizeof(imsi_rec.paese));
									memcpy(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op));
									*p_result_type = 1;
									map_buffer.MAPErrorCode = oper_mem_rec->steering_map_errcode;
									lte_buffer.ResultCode = oper_mem_rec->steering_lte_errcode;
									sprintf(ac_ret, "access denied - imsi in barred list");
									//	AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_WL);
								}
								else
								{
									b_imsi_state = IMSI_FOUND;
								}

								if (!b_imei_nosteering && b_imsi_state == IMSI_FOUND)
								{
									if (!c_cc_changed)
									{
										if (c_op_changed)
											memcpy(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op));

										// Check reset interval
										if (ll_new_processing_time - imsi_rec.timestamp < oper_mem_rec->ll_reset_ts_interval)
										{
											// max_ts reached
											if (imsi_rec.num_ts < 1)
											{
												strcpy(ac_ret, "max # of country steering");
												b_imsi_state = IMSI_MAX_TS_REACHED;
											}
										}
										else
										{
											log(LOG_DEBUG, "%s|%s|%d|%s|%s|reset # of country steering", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
											imsi_rec.num_ts = oper_mem_rec->max_ts + 1;
											imsi_rec.timestamp = ll_new_processing_time;
										}

										// Check Tmax interval
										if (ll_new_processing_time - imsi_rec.init_ts_tmax < ll_tmax)
										{
											// max_ts_tmax reached
											if (b_imsi_state != IMSI_MAX_TS_REACHED && imsi_rec.num_ts_tmax < 1)
											{
												strcpy(ac_ret, "max # of operator steering");
												b_imsi_state = IMSI_MAX_TS_REACHED;
											}
										}
										else
										{
											log(LOG_DEBUG, "%s|%s|%d|%s|%s|reset # of operator steering", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
											imsi_rec.num_ts_tmax = imsi_rec.imei_info[1] + 1;
											imsi_rec.init_ts_tmax = ll_new_processing_time;
										}

										// Check Tmin interval
										if (ll_new_processing_time - imsi_rec.last_ts_op < ll_tmin)
										{
											// Check max_lu_tmin
											s_imei_info_index = imsi_rec.imei_info[1] - imsi_rec.num_ts_tmax + 2;
											if (s_imei_info_index < 2) s_imei_info_index++;
											if (imsi_rec.num_lu >= imsi_rec.imei_info[s_imei_info_index])
											{
												imsi_rec.num_lu = 1;
												//imsi_rec.last_lu_err = s_last_lu_errcode++;
												//if (s_last_lu_errcode > s_max_lu_errcode) s_last_lu_errcode = 1;
												imsi_rec.last_lu_err = s_steering_error_code;
											}
											else
											{
												b_new_lu = 0;
												imsi_rec.num_lu++;
											}
										}
										else
										{
											imsi_rec.num_lu = 1;
											//imsi_rec.last_lu_err = s_last_lu_errcode++;
											//if (s_last_lu_errcode > s_max_lu_errcode) s_last_lu_errcode = 1;
											imsi_rec.last_lu_err = s_steering_error_code;
										}

										// Reset LU cycle if operator has changed
										if (b_imsi_state != IMSI_MAX_TS_REACHED && c_op_changed)
										{
											b_new_lu = 1;
											imsi_rec.num_lu = 1;
											//imsi_rec.last_lu_err = s_last_lu_errcode++;
											//if (s_last_lu_errcode > s_max_lu_errcode) s_last_lu_errcode = 1;
											imsi_rec.last_lu_err = s_steering_error_code;
										}
									}
									else
									{
										log(LOG_DEBUG, "%s|%s|%d|%s|%s|reset country", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);

										// Reset imsi record
										memcpy(imsi_rec.paese, oper_mem_rec->paese, sizeof(imsi_rec.paese));
										memcpy(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op));
										imsi_rec.num_ts = oper_mem_rec->max_ts + 1;
										imsi_rec.timestamp = ll_new_processing_time;
										imsi_rec.status = IMSI_STATUS_GRANTED;
										imsi_rec.num_lu = 1;
										imsi_rec.last_lu_err = s_steering_error_code;
										imsi_rec.num_ts_tmax = imsi_rec.imei_info[1] + 1;
										imsi_rec.init_ts_tmax = ll_new_processing_time;
										imsi_rec.lac = 0;
										imsi_rec.ci_sac = 0;
										c_last_op_preferred = 0x30;
										if (c_flag_grant_first_lu) b_first_lu_in_cc = 1;

										c_prev_imsi_status = IMSI_STATUS_STEERING;
										imsi_rec.init_ts_op = ll_new_processing_time;
									}
								}
							}
							else
							{
								if (err!=1 && err!=11)
									mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);

								log(LOG_DEBUG, "%s|%s|%d|%s|imsi not found", ac_gt, ac_operatore, *p_op_code, ac_imsi);
								b_imsi_state = IMSI_NOT_FOUND;
								c_cc_changed = 1;
								c_op_changed = 1;
								c_welcome_send = 1;

								// Init imsi record
								memset(&imsi_rec, 0x20, sizeof(imsi_rec));
								memcpy(imsi_rec.imsi, ac_rev_imsi, strlen(ac_rev_imsi));
								memcpy(imsi_rec.paese, oper_mem_rec->paese, sizeof(imsi_rec.paese));
								memcpy(imsi_rec.cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec.cod_op));
								imsi_rec.num_ts = oper_mem_rec->max_ts + 1;
								imsi_rec.timestamp = ll_new_processing_time;
								imsi_rec.status = IMSI_STATUS_GRANTED;
								imsi_rec.num_lu = 1;
								imsi_rec.last_lu_err = s_steering_error_code;
								memcpy(imsi_rec.imei_info, ac_default_imei_info, sizeof(imsi_rec.imei_info));
								imsi_rec.num_ts_tmax = imsi_rec.imei_info[1] + 1;
								imsi_rec.init_ts_tmax = ll_new_processing_time;
								imsi_rec.lac = 0;
								imsi_rec.ci_sac = 0;
								c_last_op_preferred = 0x30;
								if (c_flag_grant_first_lu) b_first_lu_in_cc = 1;

								c_prev_imsi_status = IMSI_STATUS_STEERING;
								imsi_rec.init_ts_op = ll_new_processing_time;
							}
						}
						else
						{
							ret++;
							log(LOG_ERROR, "%s|%s|%d|%s|error [%d] seeking imsi", ac_gt, ac_operatore, *p_op_code, ac_imsi, err);
							log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking imsi on %s", err, p_imsi_mbe_path);
							mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
						}
					}
					else
					{
						ret++;

						if (*p_op_code == UL_OP_CODE)
						{
							s_stat_net_type_shift = 0;
						}
						else if (*p_op_code == UL_OP_CODE_GPRS)
						{
							s_stat_net_type_shift = 30;
						}
						else
						{
							s_stat_net_type_shift = 50;
						}
						AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP_IN);
						AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_RECEIVED);
						AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_OPERATOR_NOT_FOUND);

						if (i_tfs_tag == TFS_LTE)
						{
							if (s_block_unknown_mccmnc)
							{
								*p_result_type = 1;
								lte_buffer.ResultCode = s_block_unknown_mccmnc;
							}
							log(LOG_WARNING, "%s|%s|%d|%s|operator not found (%d)", ac_gt, ac_operatore, *p_op_code, ac_imsi, lte_buffer.ResultCode);
						}
						else
						{
							if (s_block_unknown_gt)
							{
								*p_result_type = 1;
								map_buffer.MAPErrorCode = (char)s_block_unknown_gt;
							}
							log(LOG_WARNING, "%s|%s|%d|%s|operator not found (%d)", ac_gt, ac_operatore, *p_op_code, ac_imsi, map_buffer.MAPErrorCode);
						}
					}

//--- Retrieve information about user and device (MSISDN, User Type, IMEI before leaving home network) --

					if (!ret)
					{
						// Get User/Device info from MAP3
						if (imsi_rec.imei[0] == 0x20)
						{
							//AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMEI_REQUEST);

							if (getUserDeviceInfo(ac_imsi, &imsi_rec))
							{
								//log(LOG_DEBUG, "%s|%s|%s|imei not found", ac_operatore, ac_imsi, ac_imei);
							}
							else
							{
								memset(ac_imei, 0, sizeof(ac_imei));
								memcpy(ac_imei, imsi_rec.imei, sizeof(imsi_rec.imei));
								TrimString(ac_imei);
								//log(LOG_DEBUG, "%s|%s|%s|imei found", ac_operatore, ac_imsi, ac_imei);
							}
						}

						if (imsi_rec.imei[0] != 0x20)
						{
							// Update User Type register
							if (imsi_rec.user_type != 0x20 && c_stat_reg_user_type)
								sprintf(ac_ut_cc_op, "%d|%s|%s", imsi_rec.user_type, ac_paese, ac_operatore);

							// Check TAC/IMEI specific profile
							if (imsi_rec.imei_info[0] == IMEI_PROFILE_UNKNOWN)
							{
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMEI_PROFILE_REQUEST);

								// Do IMEI specific profile search only if at least one profile exists...
								if (avlFirstKey(tac_imei_list))
								{
									if ((err = getTacImeiProfile((char *)avlFindLpm(tac_imei_list, ac_imei), &imsi_rec)))
									{
									}
									else
									{
										AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMEI_PROFILE_FOUND);

										// Set trace level
										if (imsi_rec.trace_level != 0x20) log_param(imsi_rec.trace_level, i_log_options, "");

										//log(LOG_DEBUG, "%s|%s|%s|imei info found (%.1s)", ac_operatore, ac_imsi, ac_imei, imsi_rec.imei_info);
									}
								}
							}
						}

						// 1a verifica se posso fare steering su IMEI
						if (imsi_rec.imei_info[1] == 0)
						{
							b_imei_nosteering = 1;
						}
						else
						{
							b_imei_nosteering = 0;
						}
					}

//--- Retrieve user location ----------------------------------------------------------------------------

					if (!ret)
					{
						// LU coming from border GT ?
						if (bord_mem_rec)
						{
							AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_BORDER_GT);

							// Get User location from MAP3 upon starting a new LU cycle
							if (imsi_rec.num_lu == 1)
							{
								getUserLocation(ac_imsi, &imsi_rec);
							}

							// Location belonging to border cells ?
							b_border_cell = isBorderCell(imsi_rec.lac, imsi_rec.ci_sac);

							if (b_border_cell)
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_BORDER_CELL);
						}
					}

//--- Lookup for steering rules -------------------------------------------------------------------------

					if (!ret)
					{
						// Lookup for rules
						preferred_rule = NULL;
						other_rules = NULL;
						if (preferred_rule = seekOperatorRule(oper_mem_rec->pa_op_list, imsi_rec.user_type))
						{
							if (preferred_rule->soglia > 0)
								other_rules = seekOperatorRule(oper_mem_rec->pa_list, imsi_rec.user_type);
						}
						else if (preferred_rule = seekOperatorRule(oper_mem_rec->gr_pa_gr_op_list, imsi_rec.user_type))
						{
							if (preferred_rule->soglia > 0)
								other_rules = seekOperatorRule(oper_mem_rec->gr_pa_list, imsi_rec.user_type);
						}
						else if (other_rules = seekOperatorRule(oper_mem_rec->pa_list, imsi_rec.user_type))
						{
						}
						else if (other_rules = seekOperatorRule(oper_mem_rec->gr_pa_list, imsi_rec.user_type))
						{
						}

						// White or barred list
						if (b_imsi_state == IMSI_IN_BLACK_LIST)
						{
							log(LOG_WARNING, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ret);
						}
						// No threshold
						else if (preferred_rule && preferred_rule->soglia == 0)
						{
							strcpy(ac_ret, "access granted - no threshold");
							updateRule(preferred_rule, 0, 1, 1);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ret);
						}
						// Max # of steering
						else if (b_imsi_state == IMSI_MAX_TS_REACHED)
						{
							updateAllRules(oper_mem_rec, &imsi_rec, preferred_rule, other_rules, ac_ret, STAT_MAX_TS);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ret);
						}
						// No steering for device
						else if (b_imei_nosteering == 1)
						{
							strcpy(ac_ret, "no steering for tac");
							updateAllRules(oper_mem_rec, &imsi_rec, preferred_rule, other_rules, ac_ret, STAT_NOSTD_GRANTED);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ret);
						}
						// No steering for 1st lu in country
						else if (b_first_lu_in_cc == 1)
						{
							strcpy(ac_ret, "no steering for 1st lu in cc");
							updateAllRules(oper_mem_rec, &imsi_rec, preferred_rule, other_rules, ac_ret, STAT_NOSTD_GRANTED);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ret);
						}
						else
						{
							if (bord_mem_rec && b_border_cell && (bord_mem_rec->steering_border == BORDER_STEERING_DENY))
							{
								// Border steering
								b_lu_accept = 0;
								sprintf(ac_ret, "access denied - steering border");
							}
							else if (preferred_rule)
							{
								b_primary = 0;
								primary_rule = NULL;

								// Ci sono altre soglie ?
								if (other_rules)
								{
									// Determina la soglia primaria
									primary_rule = preferred_rule;
									secondary_rule = other_rules;
									while (secondary_rule)
									{
										if (isRuleValid(secondary_rule, imsi_rec.user_type))
										{
											if (secondary_rule->peso > primary_rule->peso)
											{
												b_primary = 1;
												primary_rule = secondary_rule;
											}
											else if (secondary_rule->peso < primary_rule->peso)
											{
												b_primary = 1;
											}
										}
										secondary_rule = secondary_rule->next;
									}
								}

								if (b_primary)
								{
									// Controlla la politica
									if (primary_rule == preferred_rule)
									{
										if (primary_rule->politica == 2 &&
											isRuleOverThreshold(primary_rule, 1) &&
											!areAllRulesOverThreshold(other_rules, imsi_rec.user_type, 1))
										{
											// Rifiuto
											b_lu_accept = 0;
										}
										else
										{
											// Accetto
											b_lu_accept = 1;
										}
									}
									else
									{
										if (preferred_rule->politica == 1 &&
											!arePrimaryRulesOverThreshold(preferred_rule, other_rules, imsi_rec.user_type, 1))
										{
											// Rifiuto
											b_lu_accept = 0;
										}
										else
										{
											// Accetto
											b_lu_accept = 1;
										}
									}
								}
								else
								{
									// Accetto (soglia singola o più soglie di uguale peso)
									b_lu_accept = 1;
								}
							}
							else if (other_rules)
							{
								// Posso fare steering ?
								if (imsi_rec.imei_info[0] == IMEI_PROFILE_GRANT_ALWAYS)
								{
									b_lu_accept = 1;
									imsi_rec.status = IMSI_STATUS_GRANTED;
									strcpy(ac_ret, "not standard");
									s_stat_id = STAT_NOSTD_GRANTED;
								}
								else
								{
									if (areAllRulesOverThreshold(other_rules, imsi_rec.user_type, 1))
									{
										b_lu_accept = 1;
										strcpy(ac_ret, "above threshold");
										s_stat_id = STAT_STEERING_GRANTED;

										// Ho appena resettato i valori? allora tolgo 1
										if (imsi_rec.num_ts == oper_mem_rec->max_ts + 1 )
											imsi_rec.num_ts--;
										if ( imsi_rec.num_ts_tmax == imsi_rec.imei_info[1] + 1)
											imsi_rec.num_ts_tmax--;
										imsi_rec.num_lu = 1;
										//imsi_rec.last_lu_err = s_last_lu_errcode++;
										//if (s_last_lu_errcode > s_max_lu_errcode) s_last_lu_errcode = 1;
										imsi_rec.last_lu_err = s_steering_error_code;
									}
									else
									{
										b_lu_accept = 0;
									}
								}
							}
							else
							{
								// Accetto
								b_lu_accept = 2;
								imsi_rec.status = IMSI_STATUS_GRANTED;
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_OPERATOR_NO_RULE);
								log(LOG_WARNING, "%s|%s|%d|%s|%s|access granted - no rule", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
							}

							// Dovrei fare steering, ma ho raggiunto qualche limite ???
							if (!b_lu_accept)
							{
								// Posso fare steering ?
								if (imsi_rec.imei_info[0] == IMEI_PROFILE_GRANT_ALWAYS)
								{
									b_lu_accept = 1;
									imsi_rec.status = IMSI_STATUS_GRANTED;
									strcpy(ac_ret, "not standard");
									s_stat_id = STAT_NOSTD_GRANTED;
								}
								else
								{
									imsi_rec.status = IMSI_STATUS_STEERING;

									// Si decrementa il credito solo sulla prima LU del ciclo
									// e se l'operatore precedente non era tra i preferiti !!!
									// Modified - 09/11/2012 - bug on decrementing num_ts
									if (b_new_lu)
									{
										if (!(c_last_op_preferred == 0x31))
										{
											imsi_rec.num_ts--;
											imsi_rec.num_ts_tmax--;
										}
									}
									if (imsi_rec.num_ts == oper_mem_rec->max_ts + 1 )
										imsi_rec.num_ts--;
									if ( imsi_rec.num_ts_tmax == imsi_rec.imei_info[1] + 1)
										imsi_rec.num_ts_tmax--;

									// max_ts reached ?
									if (imsi_rec.num_ts < 1)
									{
										b_lu_accept = 1;
										strcpy(ac_ret, "max # of country steering");
										s_stat_id = STAT_MAX_TS;
										c_welcome_send = 1;
									}
									else
									{
										// max_ts_tmax reached ?
										if (imsi_rec.num_ts_tmax < 1)
										{
											// 10/10/05 MM
											// raggiunto il numero massimo di rifiuti per opetatore
											// se ci sono ancora possibilità nel country reset
											// tentativi operatore
											if (imsi_rec.num_ts > 0)
											{
												imsi_rec.num_ts_tmax = imsi_rec.imei_info[1];
												imsi_rec.num_lu = 1;
												//imsi_rec.last_lu_err = s_last_lu_errcode++;
												//if (s_last_lu_errcode > s_max_lu_errcode) s_last_lu_errcode = 1;
												imsi_rec.last_lu_err = s_steering_error_code;
											}
											else
											{
												b_lu_accept = 1;
												strcpy(ac_ret, "max # of operator steering");
												s_stat_id = STAT_MAX_TS;
												c_welcome_send = 1;
											}
										}

										if (!b_lu_accept)
										{
											*p_result_type = 1;
											map_buffer.MAPErrorCode = oper_mem_rec->steering_map_errcode;
											lte_buffer.ResultCode = oper_mem_rec->steering_lte_errcode;
											if (ac_ret[0] == 0x00)
												sprintf(ac_ret, "access denied - steering");
											log(LOG_WARNING, "%s|%s|%d|%s|%s|#%d|%d|%d|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, imsi_rec.num_lu, imsi_rec.num_ts_tmax, imsi_rec.num_ts, ac_ret);
										}
									}
								}
							}

							// Aggiorna soglie
							if (b_lu_accept == 1)
							{
								imsi_rec.status = IMSI_STATUS_GRANTED;
								updateAllRules(oper_mem_rec, &imsi_rec, preferred_rule, other_rules, ac_ret, s_stat_id);
								log(LOG_WARNING, "%s|%s|%d|%s|%s|#%d|%d|%d|%s", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, imsi_rec.num_lu, imsi_rec.num_ts_tmax, imsi_rec.num_ts, ac_ret);

								if (preferred_rule)
									imsi_rec.last_op_preferred = 0x31;
							}
						}
					}

//--- Update IMSI record --------------------------------------------------------------------------------

					if (!ret)
					{
						// Country change events
						if (c_ccc_enabled && c_cc_changed && (i_tfs_tag == TAG_MAP_IN) && (*p_op_code == UL_OP_CODE))
						{
							insertCCCEvent(&imsi_rec);
						}

						// IF4 for ARP users
						if (ac_roaming_eu_if4_path[0] && arp_id && !*p_result_type)
						{
							insertRoamEU(&imsi_rec, eu_flag, c_op_changed, oper_mem_rec->mccmnc);
						}

						// Registration on new country/operator or after steering
						if (*p_result_type)
						{
							if (imsi_rec.num_lu == 1 && (imsi_rec.init_ts_op == 0))
								imsi_rec.init_ts_op = ll_new_processing_time;
						}
						else if (c_op_changed || c_prev_imsi_status == IMSI_STATUS_STEERING)
						{
							logRegistrationTime(&imsi_rec, ll_new_processing_time, ac_gt, ac_operatore, *p_op_code, ac_imsi);
						}

						// New country/operator or timestamp older than
						if (c_op_changed || (ll_new_processing_time - imsi_rec.last_ts_op > ll_welcome_snd_interval))
						{
							c_welcome_send = 1;
						}

						if (b_imsi_state == IMSI_NOT_FOUND)
						{
							imsi_rec.last_ts_op = ll_new_processing_time;

							//err = MBE_WRITEX(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec));
							err = MbeFileWrite_nw(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec));
							if (!err)
							{
								//log(LOG_DEBUG, "%s|%s|%s|imsi inserted", ac_operatore, ac_imsi, ac_imei);
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_INSERTED);
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_INSERTED_DAY);
								if (p_dump_daily_user_handle)
								{
									fprintf(p_dump_daily_user_handle, "%s|%.8s|%d\n", ac_ut_cc_op, imsi_rec.imei, *p_op_code);
									fflush(p_dump_daily_user_handle);
								}

								// Check if GSM LU has been received for the user, else increment data only user stat
								if (*p_imsi_mbe_id != s_imsi_gsm_mbe_id)
								{
									if (!MBE_FILE_SETKEY_(s_imsi_gsm_mbe_id, ac_rev_imsi, (short)strlen(ac_rev_imsi), 0, 2))
										//if (MBE_READX(s_imsi_gsm_mbe_id, (char *)&imsi_tmp_rec, sizeof(imsi_tmp_rec)))
										if (MbeFileRead_nw(s_imsi_gsm_mbe_id, (char *)&imsi_tmp_rec, sizeof(imsi_tmp_rec)))
											AddStat(ac_ut_cc_op, ac_my_process_name, STAT_IMSI_DATONLY_DAY);
								}
							}
							else
							{
								log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] inserting imsi", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, err);
								log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] inserting imsi on %s", err, ac_imsi_gsm_mbe_path);

								if (err!=45)	// Error but file full
									mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
							}
						}
						else
						{
							if (imsi_rec.last_ts_op < ll_midnight)
							{
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_INSERTED_DAY);
								if (p_dump_daily_user_handle)
								{
									fprintf(p_dump_daily_user_handle, "%s|%.8s|%d\n", ac_ut_cc_op, imsi_rec.imei, *p_op_code);
									fflush(p_dump_daily_user_handle);
								}

								// Check if GSM LU has been received for the user, else increment data only user stat
								if (*p_imsi_mbe_id != s_imsi_gsm_mbe_id)
								{
									if (!MBE_FILE_SETKEY_(s_imsi_gsm_mbe_id, ac_rev_imsi, (short)strlen(ac_rev_imsi), 0, 2))
										//if (MBE_READX(s_imsi_gsm_mbe_id, (char *)&imsi_tmp_rec, sizeof(imsi_tmp_rec)))
										if (MbeFileRead_nw(s_imsi_gsm_mbe_id, (char *)&imsi_tmp_rec, sizeof(imsi_tmp_rec)))
											AddStat(ac_ut_cc_op, ac_my_process_name, STAT_IMSI_DATONLY_DAY);
								}
							}

							// 23.08.05 - MM : lock record prima di update
							//err = MBE_LOCKREC(*p_imsi_mbe_id);
							err = MbeLockRec_nw(*p_imsi_mbe_id);

							// 23.08.05 - MM : modifica da update a updateunlock
							imsi_rec.last_ts_op = ll_new_processing_time;
							//err = MBE_WRITEUPDATEUNLOCKX(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec));
							err = MbeFileWriteUU_nw(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec));
							if (!err)
							{
								//log(LOG_DEBUG, "%s|%s|%s|imsi updated", ac_operatore, ac_imsi, ac_imei);
								AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_IMSI_UPDATED);
							}
							else
							{
								log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] updating imsi", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, err);
								log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating imsi on %s", err, ac_imsi_gsm_mbe_path);

								//MBE_UNLOCKREC(*p_imsi_mbe_id);
								MbeUnlockRec_nw(*p_imsi_mbe_id);

								if (err!=1 && err!=11)
									mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
							}
						}
					}

//--- Reset trace level ---------------------------------------------------------------------------------

					log_param(i_trace_level, i_log_options, "");

//--- Send trigger to Welcome SMS -----------------------------------------------------------------------

					// Do not send Welcome to users managed by ARP
					if (arp_id) c_welcome_send = 0;

					// Notify Welcome only for MAP GSM LU -- Added 24/04/2019
					if (!((i_tfs_tag == TAG_MAP_IN) && (*p_op_code == UL_OP_CODE)))
						c_welcome_send = 0;

					if (c_welcome_enabled && strcmp(ac_operatore, "-") &&
						c_welcome_send &&
						!*p_result_type)
					{
						welcome_cod_op = &ac_operatore[0];

						memset((char *)&welcome_rec, 0x20, sizeof(welcome_rec));
						welcome_rec.i_tag = TAG_WELCOME;
						memcpy(welcome_rec.ident, "TFS", 3);
						memcpy(welcome_rec.imsi, ac_imsi, strlen(ac_imsi));
						memcpy(welcome_rec.msisdn, imsi_rec.msisdn, sizeof(welcome_rec.msisdn));
						memcpy(welcome_rec.tac, imsi_rec.imei, 8);
						memcpy(welcome_rec.cc, imsi_rec.paese, sizeof(welcome_rec.cc));
						memcpy(welcome_rec.codOP, welcome_cod_op, strlen(welcome_cod_op));
						memcpy(welcome_rec.vlr, ac_gt, strlen(ac_gt));
						if (imsi_rec.operator != 0x20)
						{
							memcpy(welcome_rec.MVNO, "01", 2);
							welcome_rec.MVNO[2] = imsi_rec.operator;
						}
						welcome_rec.tipo_cliente = imsi_rec.user_type;
						if (bord_mem_rec && b_border_cell && (bord_mem_rec->steering_border == BORDER_STEERING_SEND))
							welcome_rec.tipo_trigger = 1;

						if (err = SendToWelcome(&welcome_rec))
						{
							log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] in mts to Welcome <%d;%d>", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, err, i_welcome_subsys, i_welcome_class);
							log_evt_t(ll_ems_time_interval, &ll_ems_time_last_welcome_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_SS_SEND_ERROR, "error [%d] in mts to Welcome <%d;%d>", err, i_welcome_subsys, i_welcome_class);
							if (welcome_rec.tipo_trigger == 1)
								AddStat("wsm-ars", ac_my_process_name, STAT_MTS_SEND_KO);
							else
								AddStat("wsm-std", ac_my_process_name, STAT_MTS_SEND_KO);
						}
						else
						{
							if (welcome_rec.tipo_trigger == 1)
							{
								log(LOG_INFO, "%s|%s|%d|%s|%s|sent to Welcome|ars", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
								AddStat("wsm-ars", ac_my_process_name, STAT_MTS_SEND_OK);
							}
							else
							{
								log(LOG_INFO, "%s|%s|%d|%s|%s|sent to Welcome|std", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
								AddStat("wsm-std", ac_my_process_name, STAT_MTS_SEND_OK);
							}
						}
					}
//-------------------------------------------------------------------------------------------------------

				}
				else
				{
					log(LOG_ERROR, "%s|%s|%d|%s|rcv unexpected op code from MAP inbound", ac_gt, ac_operatore, *p_op_code, ac_imsi);
				}

				// Reply
				if (i_tfs_tag == TFS_LTE)
				{
					if (ret = LTE_ReplyOut(&lte_buffer))
						log(LOG_ERROR, "%s|%s|%d|%s|%s|failed to send resp to MAP outbound (%d)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ret);
				}
				else
				{
					if ((ret = MAP_ReplyOut(&map_buffer)))
						log(LOG_ERROR, "%s|%s|%d|%s|%s|failed to send resp to MAP outbound (%d)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ret);
				}

				if (!ret)
				{
					AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP_OUT);
					if (*p_result_type)
						AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_DENIED);
					else
						AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_UL_GRANTED);
				}

				checkProcessTime(ll_new_processing_time);

				REPLY_();
				break;
			}
			case 6:
			{
				// System message
				REPLY_();
				memcpy(&signal, &ReceiveIO.data, sizeof(IO_SYSMSG_TIMEOUT));
				log(LOG_DEBUG, "rcv system signal %d", signal.id);

				switch(signal.id)
				{
					case SYS_MSG_TIME_TIMEOUT:
					{
						switch (signal.l_par) 
						{
							case TAG_BUMP_STAT:
							{
								i_stat_bump_retry_interval = BumpStat();

								switch (i_stat_bump_retry_interval)
								{
									case 0:
									case 2:
									{
										log(LOG_ERROR, "Statistics - error code %d", i_stat_bump_retry_interval);
										SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
										break;
									}
									case 1:
									{
										log(LOG_ERROR, "Statistics - saved");

										if (checkIniFile())
										{
											Process_Initialization(1);
										}
										else
										{
											log(LOG_ERROR, "Parameters - reload skipped");
										}

										SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
										break;
									}
									default:
									{
										log(LOG_ERROR, "Statistics - postponed (%d)", i_stat_bump_retry_interval);
										SIGNALTIMEOUT_(i_stat_bump_retry_interval, 0, TAG_BUMP_STAT);
										break;
									}
								}

								log_flush(LOG_FLUSH_NOW);
								if (i_logfile_id_rt > 0)
									file_flush(i_logfile_id_rt, LOG_FLUSH_NOW);

								break;
							}
							case TAG_LOAD_RULES:
							{
								if (isOperatorListChanged())
								{
									Stop = LoadOperatorList();

									if (!Stop)
									{
										avlClose(tac_imei_list);
										tac_imei_list = avlMake();
										Stop = loadTacImeiList();
									}

									if (!Stop)
									{
										avlClose(border_cell_list);
										border_cell_list = avlMake();
										Stop = loadBorderCellList();
									}
								}

								SIGNALTIMEOUT_(i_load_rules_interval, 0, TAG_LOAD_RULES);
								break;
							}
							default:
							{
								break;
							}
						}
						break;
					}
					// Pathway Stop ?
					case SYS_MSG_STOP:
					case SYS_MSG_STOP_2:
					{
						// Get sender info
						FILE_GETRECEIVEINFO_(sender_info);
						for (i=0; i<10; i++) sender_handle[i] = sender_info[i+6];
						memset(sender_process_name, 0, sizeof(sender_process_name));
						PROCESSHANDLE_TO_STRING_(sender_handle, sender_process_name, sender_process_maxlen, &sender_process_maxlen);

						// Get sender ancestor info
						PROCESS_GETINFO_(sender_handle,,,,, sender_mom_handle);
						memset(sender_mom_process_name, 0, sizeof(sender_mom_process_name));
						PROCESSHANDLE_TO_STRING_(sender_mom_handle, sender_mom_process_name, sender_mom_process_maxlen, &sender_mom_process_maxlen);

						log(LOG_DEBUG, "sender %s, mom %s", sender_process_name, sender_mom_process_name);

						if (!strcmp(sender_process_name, sender_mom_process_name))
						{
							log(LOG_ERROR, "System STOP message!!!");
							Stop = 1;
						}
						break;
					}
					default:
					{
						break;
					}
				}

				break;
			}
			default:
			{
				break;
			}
		}
	}

	BumpStat();
	if (p_dump_daily_user_handle)
		fclose(p_dump_daily_user_handle);
	log(LOG_ERROR, "Process stopped");
	log_close();
	if (i_logfile_id_rt > 0)
		file_close(i_logfile_id_rt);

	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STOPPED, "Process stopped");
	exit(0);
}

void Process_Initialization(char reload)
{
	int		found;
	char	ac_wrk_str[1024];
	char	*wrk_str;
	short	i_proch[20];
	short	i_maxlen = sizeof(ac_my_process_name);
	int		i;
	char	*ptr;

	short	bpid;
	char	mm[24];
	char	ac_cpu[5];

	PROCESSHANDLE_GETMINE_(i_proch);
	//PROCESSHANDLE_DECOMPOSE_(i_proch,, &i_my_pin,,,,, ac_my_process_name, i_maxlen, &i_maxlen,);
	PROCESSHANDLE_DECOMPOSE_(i_proch, &i_my_cpu,,,,,, ac_my_process_name, i_maxlen, &i_maxlen,);

	if (!reload)
	{
		// Get configuration filename
		if ((pc_ini_file = getenv("INIFILE")) == NULL)
		{
			if ((pc_ini_file = getenv("INI-FILE")) == NULL)
			{
				DELAY(EXIT_DELAY);
				exit(0);
			}
		}

		// Compose OSS filename for reload check
		if (*pc_ini_file == '\\')
		{
			// Remote file
			strcpy(ac_wrk_str, pc_ini_file+1);
			wrk_str = strtok(ac_wrk_str, ".");
			sprintf(ac_path_file_ini_oss, "/E/%s/G/%s", wrk_str, ac_wrk_str+strlen(ac_wrk_str)+2);
		}
		else
		{
			// Local file
			sprintf(ac_path_file_ini_oss, "/G/%s", pc_ini_file+1);
		}
		while (wrk_str = strchr(ac_path_file_ini_oss, '.')) *wrk_str = '/';

		checkIniFile();
	}

	if (!reload)
	{
		// Node parameters
		get_profile_string("$SYSTEM.NODEENV.NODEID", "INS", "NODEID", &found, ac_wrk_str);
		if (found == SSP_TRUE) c_node_id = ac_wrk_str[0];
		else if ((wrk_str = getenv("CSS-NODE-ID")) != NULL)
		{
			c_node_id = wrk_str[0];
		}
		else
			c_node_id = 'A';

		get_profile_string(pc_ini_file, INI_SECTION_NAME, "TASK-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE)
			s_steering_task_id = (short)atoi(ac_wrk_str);
		else if ((wrk_str = getenv("CSS-MM-TASKID")) != NULL)
		{
			s_steering_task_id = (short)atoi(wrk_str);
		}
		else
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}

		get_profile_string(pc_ini_file, INI_SECTION_NAME, "SERVER-CLASS", &found, ac_wrk_str);
		if (found == SSP_TRUE)
			s_steering_server_class = (short)atoi(ac_wrk_str);
		else if ((wrk_str = getenv("CSS-MM-SVRCLASS")) != NULL)
		{
			s_steering_server_class = (short)atoi(wrk_str);
		}
		else
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}

		// INS initialization
		strncpy(mm, "$MMyx                   ", 24);
		sprintf(ac_cpu, "%x", i_my_cpu);
		mm[3] = ac_cpu[0];
		mm[4] = c_node_id;
		i_my_node_id = L_CINITIALIZE(s_steering_task_id, s_steering_server_class,, &bpid,,(short *)mm, c_node_id);
		if (i_my_node_id == 0)
		{
			mm[5] = 0;
			printf("*** %s *** Error in L_CINITIALIZE - %s ***", ac_my_process_name, mm);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		L_INITIALIZE_END();
	}

	/* --- EMS ------------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "EMS", "EMS-OWNER", &found, ac_ems_owner);
		if (found == SSP_FALSE) 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "EMS", "EMS-VERSION", &found, ac_ems_version);
		if (found == SSP_FALSE) 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "EMS", "EMS-SUBSYSTEM", &found, ac_wrk_str);
		if (found == SSP_TRUE) s_ems_subsystem = (short)atoi(ac_wrk_str);
		else 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "EMS-APPL", &found, ac_ems_appl);
		if (found == SSP_FALSE) 
		{
			get_profile_string(pc_ini_file, "EMS", "EMS-APPL", &found, ac_ems_appl);
			if (found == SSP_FALSE)
			{
				DELAY(EXIT_DELAY);
				exit(0);
			}
		}

		// Init EMS
		sspevt_init(ac_ems_appl, ac_ems_owner, s_ems_subsystem, ac_ems_version);
	}

	get_profile_string(pc_ini_file, "EMS", "EMS-TIME-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_ems_time_interval = (long long)atoi(ac_wrk_str) * 1000000;
	else ll_ems_time_interval = 60000000;

	/* --- LOG ------------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-PATH", &found, ac_path_log_file);
		if (found == SSP_FALSE)
		{
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOG -> LOG-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		i_num_days_of_log = 8;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
		else
		{
			get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
			if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
		}

		// OPEN LOG FILE
		log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);
	}

	i_trace_level = LOG_INFO;
	if (get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-LEVEL", &found, ac_wrk_str))
	{
		if (reload)
			log(LOG_INFO, "Parameters - failed to open %s - reload aborted", pc_ini_file);
		else
			log(LOG_INFO, "Parameters - failed to open %s", pc_ini_file);

		return;
	}
	else
	{
		if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
		else
		{
			get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
			if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
		}
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	ac_log_trace_string[0] = 0x00;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-TRACE", &found, ac_log_trace_string);
	if (ac_log_trace_string[0])
		log_set_trace(ac_log_trace_string);
	else
		log_reset_trace();

	/* --- LOG-ROAMING-TIME ------------------------------------------------ */
	c_log_enabled_rt = 0;
	get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-ENABLED", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_log_enabled_rt = (char)atoi(ac_wrk_str);

	if (i_logfile_id_rt > 0)
	{
		file_close(i_logfile_id_rt);
		i_logfile_id_rt = -1;
	}

	if (c_log_enabled_rt)
	{
		get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-PATH", &found, ac_path_log_file_rt);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter LOG-ROAMING-TIME -> LOG-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOG-ROAMING-TIME -> LOG-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}

		ac_log_prefix_rt[0] = 0x00;
		get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-PREFIX", &found, ac_log_prefix_rt);
		if (!ac_log_prefix_rt[0]) strcpy(ac_log_prefix_rt, ac_my_process_name+1);

		i_num_days_of_log_rt = 8;
		get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log_rt = atoi(ac_wrk_str);

		file_init(&i_logfile_id_rt, ac_path_log_file_rt, ac_log_prefix_rt, i_num_days_of_log_rt);

		i_trace_level_rt = LOG_INFO;
		get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level_rt = (short)atoi(ac_wrk_str);

		i_log_options_rt = 7;
		get_profile_string(pc_ini_file, "LOG-ROAMING-TIME", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options_rt = (short)atoi(ac_wrk_str);

		file_param(i_logfile_id_rt, i_trace_level_rt, i_log_options_rt, "", "", 0);
	}

	/* --- GENERIC --------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPER-PATH", &found, ac_oper_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPER-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-OPER-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPERGT-PATH", &found, ac_opergt_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPERGT-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-OPERGT-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-BORDGT-PATH", &found, ac_bordgt_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-BORDGT-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-BORDGT-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, ac_soglie_mbe_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-NOSTD-TAC-PATH", &found, ac_nostd_tac_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-NOSTD-TAC-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-NOSTD-TAC-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-BORDCID-PATH", &found, ac_border_cell_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-BORDCID-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-BORDCID-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-GSM-MBE-PATH", &found, ac_imsi_gsm_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-DAT-MBE-PATH", &found, ac_imsi_dat_mbe_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}

		get_profile_string(pc_ini_file, "GENERIC", "CCC-QUEUE-PATH", &found, ac_ccc_que_path);
		get_profile_string(pc_ini_file, "GENERIC", "ROAMING-EU-IF4-PATH", &found, ac_roaming_eu_if4_path);

		ac_daily_user_file_path[0] = 0x00;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "DUMP-DAILY-USER-PATH", &found, ac_daily_user_file_path);
	}

	s_block_unknown_gt = 0;
	get_profile_string(pc_ini_file, "GENERIC", "BLOCK-UNKNOWN-GT", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		s_block_unknown_gt = (short)atoi(ac_wrk_str);
	}

	s_block_unknown_mccmnc = 0;
	get_profile_string(pc_ini_file, "GENERIC", "BLOCK-UNKNOWN-MCCMNC", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		s_block_unknown_mccmnc = (short)atoi(ac_wrk_str);
	}

	get_profile_string(pc_ini_file, "GENERIC", "APPLYST", &found, ac_apply_ts_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> APPLYST");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> APPLYST");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	i_mbe_timeout = 200;
	get_profile_string(pc_ini_file, "GENERIC", "MBE-NOWAIT-TIMEOUT", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		i_mbe_timeout = (int)(atoi(ac_wrk_str) * 100);
		MbeSetAwiatioxTimeout(i_mbe_timeout);
	}

	/* --- GTT ------------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GTT", "NATIONAL-COUNTRY-CODE", &found, ac_national_country_code);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GTT -> NATIONAL-COUNTRY-CODE");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GTT -> NATIONAL-COUNTRY-CODE");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	/* --- MANAGER --------------------------------------------------------- */
	i_load_rules_interval = 30000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOAD-RULES-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_load_rules_interval = (int)(atoi(ac_wrk_str) * 100);
	i_load_rules_cpu_shift = 3000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOAD-RULES-CPU-SHIFT", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_load_rules_cpu_shift = (int)(atoi(ac_wrk_str) * 100);

	ll_reset_ts_interval = 86400000000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "RESET-TS-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_reset_ts_interval = (long long)atoi(ac_wrk_str) * 1000000;

	ll_tmin = 21000000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "TMIN", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_tmin = (long long)atoi(ac_wrk_str) * 1000000;

	ll_tmax = 900000000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "TMAX", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_tmax = (long long)atoi(ac_wrk_str) * 1000000;

	get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAX-PROCESSING-TIME", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_max_process_time = atoi(ac_wrk_str);
	else i_max_process_time = 1000;

	s_steering_method = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "STEERING-METHOD", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_steering_method = (short)atoi(ac_wrk_str);

	get_profile_string(pc_ini_file, INI_SECTION_NAME, "DEFAULT-IMEI-INFO", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		memset(ac_default_imei_info, 0, sizeof(ac_default_imei_info));
		ac_default_imei_info[0] = IMEI_PROFILE_UNKNOWN;
		i = 1;
		ptr = strtok(ac_wrk_str, ";");
		while (ptr)
		{
			ac_default_imei_info[++i] = (char)atoi(ptr);
			ptr = strtok((char *)NULL, ";");
		}
		ac_default_imei_info[1] = (char)(i-1);

		// Gestione imei_info "0"
		if (ac_default_imei_info[1] == 1 && ac_default_imei_info[2] == 0)
			ac_default_imei_info[1] = 0;
	}
	else
	{
		log(LOG_ERROR, "Missing parameter %s -> DEFAULT-IMEI-INFO", INI_SECTION_NAME);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> DEFAULT-IMEI-INFO", INI_SECTION_NAME);
		DELAY(EXIT_DELAY);
		exit (0);
	}

	c_flag_grant_first_lu = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "FLAG-GRANT-FIRST-LU", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_flag_grant_first_lu = (char)atoi(ac_wrk_str);

	c_flag_use_map3_loc = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "FLAG-USE-MAP3-LOC", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_flag_use_map3_loc = (char)atoi(ac_wrk_str);

	if (c_flag_use_map3_loc)
	{
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-LOC-PROCESS-NAME", &found, ac_map3_loc_process_name);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter %s -> MAP3-LOC-PROCESS-NAME", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> MAP3-LOC-PROCESS-NAME", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-LOC-CLASS-NAME", &found, ac_map3_loc_class_name);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter %s -> MAP3-LOC-CLASS-NAME", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> MAP3-LOC-CLASS-NAME", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		i_map3_loc_validity = 60;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-LOC-VALIDITY-PERIOD", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_map3_loc_validity = atoi(ac_wrk_str);
		l_map3_loc_timeout = 200;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-LOC-PSEND-TIMEOUT", &found, ac_wrk_str);
		if (found == SSP_TRUE) l_map3_loc_timeout = (long)(atoi(ac_wrk_str) * 100);

	}

	c_flag_use_map3_usr = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "FLAG-USE-MAP3-USR", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_flag_use_map3_usr = (char)atoi(ac_wrk_str);
	c_default_user_type = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-DEFAULT-TYPE", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_default_user_type = (char)atoi(ac_wrk_str);

	if (c_flag_use_map3_usr)
	{
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-TYPE-TABLE", &found, ac_map3_usr_type_table);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter %s -> MAP3-USR-TYPE-TABLE", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> MAP3-USR-TYPE-TABLE", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-PROCESS-NAME", &found, ac_map3_usr_process_name);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter %s -> MAP3-USR-PROCESS-NAME", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> MAP3-USR-PROCESS-NAME", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-CLASS-NAME", &found, ac_map3_usr_class_name);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter %s -> MAP3-USR-CLASS-NAME", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> MAP3-USR-CLASS-NAME", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		i_map3_usr_validity = 86400;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-VALIDITY-PERIOD", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_map3_usr_validity = atoi(ac_wrk_str);
		l_map3_usr_timeout = 500;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-PSEND-TIMEOUT", &found, ac_wrk_str);
		if (found == SSP_TRUE) l_map3_usr_timeout = (long)(atoi(ac_wrk_str) * 100);
		c_map3_usr_require_imei = 1;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "MAP3-USR-REQUIRE-IMEI", &found, ac_wrk_str);
		if (found == SSP_TRUE) c_map3_usr_require_imei = (char)atoi(ac_wrk_str);
	}

	c_flag_use_trigger = 1;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "FLAG-USE-TRIGGER", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_flag_use_trigger = (char)atoi(ac_wrk_str);
	if (c_flag_use_trigger)
	{
		i_eir_trigger_subsystem = 1500;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "EIR-TRIGGER-SUBSYSTEM", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_eir_trigger_subsystem = (short)atoi(ac_wrk_str);

		get_profile_string(pc_ini_file, INI_SECTION_NAME, "EIR-TRIGGER-SUBSYS-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_eir_trigger_taskid = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter %s -> EIR-TRIGGER-SUBSYS-ID", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> EIR-TRIGGER-SUBSYS-ID", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "EIR-TRIGGER-CLASS-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_eir_trigger_serverclass = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter %s -> EIR-TRIGGER-CLASS-ID", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> EIR-TRIGGER-CLASS-ID", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
	}
	else
	{
		i_eir_trigger_subsystem = 1500;
		i_eir_trigger_taskid = 0;
		i_eir_trigger_serverclass = 0;
	}

	c_ccc_enabled = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "CCC-ENABLED", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_ccc_enabled = (char)atoi(ac_wrk_str);

	c_welcome_enabled = 0;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "WELCOME-ENABLED", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_welcome_enabled = (char)atoi(ac_wrk_str);

	if (c_welcome_enabled)
	{
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "WELCOME-SUBSYS-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_welcome_subsys = (short)atoi(ac_wrk_str);
		else 
		{
			log(LOG_ERROR, "Missing parameter %s -> WELCOME-SUBSYS-ID", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> WELCOME-SUBSYS-ID", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "WELCOME-CLASS-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_welcome_class = (short)atoi(ac_wrk_str);
		else 
		{
			log(LOG_ERROR, "Missing parameter %s -> WELCOME-CLASS-ID", INI_SECTION_NAME);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter %s -> WELCOME-CLASS-ID", INI_SECTION_NAME);
			DELAY(EXIT_DELAY);
			exit(0);
		}

		ll_welcome_snd_interval = 43200000000;
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "WELCOME-SND-INTERVAL", &found, ac_wrk_str);
		if (found == SSP_TRUE) ll_welcome_snd_interval = (long long)atoi(ac_wrk_str) * 1000000;
	}
	else
	{
		i_welcome_subsys = 0;
		i_welcome_class = 0;
		ll_welcome_snd_interval = 43200000000;
	}

	/* --- STAT ------------------------------------------------------------ */
	if (!reload)
	{
		i_stat_bump_interval = 30000;
		get_profile_string(pc_ini_file, "STAT", "STAT-BUMP-INTERVAL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_bump_interval = (short)(atoi(ac_wrk_str) * 100);
		get_profile_string(pc_ini_file, "STAT", "STAT-PATH", &found, ac_path_stat_file);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "STAT-PREFIX", &found, ac_stat_prefix);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-PREFIX");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-PREFIX");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "STAT-GROUP", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_group = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-GROUP");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-GROUP");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "MAX-REGS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_max_registers = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> MAX-REGS");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> MAX-REGS");
			DELAY(EXIT_DELAY);
			exit (0);
		}
		get_profile_string(pc_ini_file, "STAT", "MAX-COUNTS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_max_counters = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> MAX-COUNTS");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> MAX-COUNTS");
			DELAY(EXIT_DELAY);
			exit (0);
		}

		// Init stat
		if (!Stat_init(ac_path_stat_file, ac_stat_prefix, "", i_stat_group, i_stat_max_registers, i_stat_max_counters))
		{
			log(LOG_ERROR, "Stat init error");
			DELAY(EXIT_DELAY);
			exit (0);
		}
	}

	c_stat_reg_user_type = 0;
	get_profile_string(pc_ini_file, "STAT", "STAT-REG-USER-TYPE", &found, ac_wrk_str);
	if (found == SSP_TRUE) c_stat_reg_user_type = (char)atoi(ac_wrk_str);

	if (!reload)
	{
		Print_Process_Parameters();
	}
	else
	{
		log(LOG_ERROR, "Parameters reloaded");
	}
}

void Print_Process_Parameters()
{
	int		i;
	char	ac_tmp[100];

	log(LOG_ERROR, "#==============================================================================");
	log(LOG_ERROR, "# INIFILE: %s", pc_ini_file);
	log(LOG_ERROR, "#==============================================================================");

	log(LOG_ERROR, "[EMS]");
	log(LOG_ERROR, "\tEMS-OWNER .................: %s", ac_ems_owner);
	log(LOG_ERROR, "\tEMS-SUBSYSTEM .............: %d", s_ems_subsystem);
	log(LOG_ERROR, "\tEMS-VERSION ...............: %s", ac_ems_version);
	log(LOG_ERROR, "\tEMS-APPL ..................: %s", ac_ems_appl);
	log(LOG_ERROR, "\tEMS-TIME-INTERVAL .........: %Ld", ll_ems_time_interval/1000000);
	
	log(LOG_ERROR, "[LOG]");
	log(LOG_ERROR, "\tLOG-PATH ..................: %s", ac_path_log_file);
	log(LOG_ERROR, "\tLOG-DAYS ..................: %d", i_num_days_of_log);
	log(LOG_ERROR, "\tLOG-LEVEL .................: %d", i_trace_level);
	log(LOG_ERROR, "\tLOG-OPTIONS ...............: %d", i_log_options);
	log(LOG_ERROR, "\tLOG-TRACE .................: %s", ac_log_trace_string);

	log(LOG_ERROR, "[LOG-ROAMING-TIME]");
	log(LOG_ERROR, "\tLOG-ENABLED ...............: %d", c_log_enabled_rt);
	if (c_log_enabled_rt)
	{
		log(LOG_ERROR, "\tLOG-PATH ..................: %s", ac_path_log_file_rt);
		log(LOG_ERROR, "\tLOG-PREFIX ................: %s", ac_log_prefix_rt);
		log(LOG_ERROR, "\tLOG-DAYS ..................: %d", i_num_days_of_log_rt);
		log(LOG_ERROR, "\tLOG-LEVEL .................: %d", i_trace_level_rt);
		log(LOG_ERROR, "\tLOG-OPTIONS ...............: %d", i_log_options_rt);
	}

	log(LOG_ERROR, "[STAT]");
	log(LOG_ERROR, "\tSTAT-BUMP-INTERVAL ........: %d", i_stat_bump_interval/100);
	log(LOG_ERROR, "\tSTAT-PATH .................: %s", ac_path_stat_file);
	log(LOG_ERROR, "\tSTAT-PREFIX ...............: %s", ac_stat_prefix);
	log(LOG_ERROR, "\tSTAT-GROUP ................: %d", i_stat_group);
	log(LOG_ERROR, "\tSTAT-REG-USER-TYPE ........: %d", c_stat_reg_user_type);
	log(LOG_ERROR, "\tMAX-REGS ..................: %d", i_stat_max_registers);
	log(LOG_ERROR, "\tMAX-COUNTS ................: %d", i_stat_max_counters);

	log(LOG_ERROR, "[GENERIC]");
	log(LOG_ERROR, "\tBLOCK-UNKNOWN-GT ..........: %d", s_block_unknown_gt);
	log(LOG_ERROR, "\tBLOCK-UNKNOWN-MCCMNC ......: %d", s_block_unknown_mccmnc);
	log(LOG_ERROR, "\tAPPLYST ...................: %s", ac_apply_ts_path);
	log(LOG_ERROR, "\tDB-LOC-OPER-PATH ..........: %s", ac_oper_path);
	log(LOG_ERROR, "\tDB-LOC-OPERGT-PATH ........: %s", ac_opergt_path);
	log(LOG_ERROR, "\tDB-LOC-BORDGT-PATH ........: %s", ac_bordgt_path);
	log(LOG_ERROR, "\tDB-LOC-THRESHOLDS-PATH ....: %s", ac_soglie_mbe_path);
	log(LOG_ERROR, "\tDB-LOC-NOSTD-TAC-PATH .....: %s", ac_nostd_tac_mbe_path);
	log(LOG_ERROR, "\tDB-LOC-BORDCID-PATH .......: %s", ac_border_cell_mbe_path);
	log(LOG_ERROR, "\tIMSI-GSM-MBE-PATH .........: %s", ac_imsi_gsm_mbe_path);
	log(LOG_ERROR, "\tIMSI-DAT-MBE-PATH .........: %s", ac_imsi_dat_mbe_path);
	log(LOG_ERROR, "\tCCC-QUEUE-PATH ..............: %s", ac_ccc_que_path);
	log(LOG_ERROR, "\tROAMING-EU-IF4-PATH .......: %s", ac_roaming_eu_if4_path);
	log(LOG_ERROR, "\tMBE-NOWAIT-TIMEOUT ........: %d", i_mbe_timeout/100);

	log(LOG_ERROR, "[GTT]");
	log(LOG_ERROR, "\tNATIONAL-COUNTRY-CODE .....: %s", ac_national_country_code);

	log(LOG_ERROR, "[INS]");
	log(LOG_ERROR, "\tNODEID ....................: %c", c_node_id);

	log(LOG_ERROR, "[%s]", INI_SECTION_NAME);
	log(LOG_ERROR, "\tLOAD-RULES-INTERVAL .......: %d", i_load_rules_interval/100);
	log(LOG_ERROR, "\tLOAD-RULES-CPU-SHIFT ......: %d", i_load_rules_cpu_shift/100);
	log(LOG_ERROR, "\tTASK-ID ...................: %d", s_steering_task_id);
	log(LOG_ERROR, "\tSERVER-CLASS ..............: %d", s_steering_server_class);
	log(LOG_ERROR, "\tRESET-TS-INTERVAL .........: %Ld", ll_reset_ts_interval/1000000);
	log(LOG_ERROR, "\tTMIN ......................: %Ld", ll_tmin/1000000);
	log(LOG_ERROR, "\tTMAX ......................: %Ld", ll_tmax/1000000);
	if (ac_default_imei_info[1] == 0) strcpy(ac_tmp, "0");
	else
	{
		sprintf(ac_tmp, "%d ->", ac_default_imei_info[1]);
		for (i=0; i<ac_default_imei_info[1]; i++) sprintf(ac_tmp, "%s %d", ac_tmp, ac_default_imei_info[i+2]);
	}
	log(LOG_ERROR, "\tDEFAULT-IMEI-INFO .........: %s", ac_tmp);
	log(LOG_ERROR, "\tMAX-PROCESSING-TIME .......: %d", i_max_process_time);
	log(LOG_ERROR, "\tSTEERING-METHOD ...........: %d", s_steering_method);
	log(LOG_ERROR, "\tFLAG-GRANT-FIRST-LU .......: %d", c_flag_grant_first_lu);

	log(LOG_ERROR, "\tFLAG-USE-MAP3-LOC .........: %d", c_flag_use_map3_loc);
	if (c_flag_use_map3_loc)
	{
		log(LOG_ERROR, "\tMAP3-LOC-PROCESS-NAME .....: %s", ac_map3_loc_process_name);
		log(LOG_ERROR, "\tMAP3-LOC-CLASS-NAME .......: %s", ac_map3_loc_class_name);
		log(LOG_ERROR, "\tMAP3-LOC-VALIDITY-PERIOD ..: %d", i_map3_loc_validity);
		log(LOG_ERROR, "\tMAP3-LOC-PSEND-TIMEOUT ....: %d", l_map3_loc_timeout);
	}

	log(LOG_ERROR, "\tFLAG-USE-MAP3-USR .........: %d", c_flag_use_map3_usr);
	log(LOG_ERROR, "\tMAP3-USR-DEFAULT-TYPE .....: %d", c_default_user_type);
	if (c_flag_use_map3_usr)
	{
		log(LOG_ERROR, "\tMAP3-USR-TYPE-TABLE .......: %s", ac_map3_usr_type_table);
		log(LOG_ERROR, "\tMAP3-USR-PROCESS-NAME .....: %s", ac_map3_usr_process_name);
		log(LOG_ERROR, "\tMAP3-USR-CLASS-NAME .......: %s", ac_map3_usr_class_name);
		log(LOG_ERROR, "\tMAP3-USR-VALIDITY-PERIOD ..: %d", i_map3_usr_validity);
		log(LOG_ERROR, "\tMAP3-USR-PSEND-TIMEOUT ....: %d", l_map3_usr_timeout);
		log(LOG_ERROR, "\tMAP3-USR-REQUIRE-IMEI .....: %d", c_map3_usr_require_imei);
	}

	log(LOG_ERROR, "\tFLAG-USE-TRIGGER ..........: %d", c_flag_use_trigger);
	if (c_flag_use_trigger)
	{
		log(LOG_ERROR, "\tEIR-TRIGGER-SUBSYSTEM .....: %d", i_eir_trigger_subsystem);
		log(LOG_ERROR, "\tEIR-TRIGGER-SUBSYS-ID .....: %d", i_eir_trigger_taskid);
		log(LOG_ERROR, "\tEIR-TRIGGER-CLASS-ID ......: %d", i_eir_trigger_serverclass);
	}

	log(LOG_ERROR, "\tCCC-ENABLED ...............: %d", c_ccc_enabled);

	log(LOG_ERROR, "\tWELCOME-ENABLED ...........: %d", c_welcome_enabled);
	if (c_welcome_enabled)
	{
		log(LOG_ERROR, "\tWELCOME-SUBSYS-ID .........: %d", i_welcome_subsys);
		log(LOG_ERROR, "\tWELCOME-CLASS-ID ..........: %d", i_welcome_class);
		log(LOG_ERROR, "\tWELCOME-SND-INTERVAL ......: %Ld", ll_welcome_snd_interval/1000000);
	}
	log(LOG_ERROR, "\tDUMP-DAILY-USER-PATH ......: %s", ac_daily_user_file_path);
	log(LOG_ERROR, "#==============================================================================");
}

short checkIniFile()
{
	short			ret = 0;
	struct stat		stat_file;
	static time_t	time_lastup = 0;

	lstat(ac_path_file_ini_oss, &stat_file);
	if (time_lastup != stat_file.st_mtime)
	{
		time_lastup = stat_file.st_mtime;
		ret = 1;
	}
	return ret;
}

/*
void Open_Input_Queue(IO_RECEIVE *ReceiveIO) 
{
  short error;
  strcpy(ReceiveIO->fname, "$RECEIVE");
  error = FILE_OPEN_(ReceiveIO->fname, (short)strlen(ReceiveIO->fname), &ReceiveIO->id, 0, 0, 1, 1);
  if (error != 0)
  {
    //LAUNCH_ER(P2_ERA_APPL, ERAD_FILEIO_ERROR, A_STRING, ReceiveIO->fname, A_16BITS, &error, END_OF_ARGLIST);
    DELAY(EXIT_DELAY);
    exit(0);
  }
  return;
}
*/

void Open_Input_Queue( IO_RECEIVE *ReceiveIO )
{
	short   err;
	char    *rcv_fname = "$RECEIVE#MTS            ";

	memset( ReceiveIO->data, 0x20, sizeof(ReceiveIO->data) );
	strcpy( ReceiveIO->fname, rcv_fname );

	err = OPEN_( ReceiveIO->fname, &ReceiveIO->id, P2_GEN_RECV_SYS_MSGS );

	if ( err )
	{
		log(LOG_ERROR,"Open_Input_Queue - Err.[%d] - Exit",err);
        exit(-1);
    }
} // End Of Procedure: Open_Input_Queue

//short Read_Input_Queue(IO_RECEIVE *ReceiveIO)
//{
//  short	cnt_read = 0;
//  memset(ReceiveIO->data, 0x20, sizeof(ReceiveIO->data));
//  
//  READUPDATEX(ReceiveIO->id, (ReceiveIO->data), (short)sizeof(ReceiveIO->data), &cnt_read);
//  FILE_GETINFO_(ReceiveIO->id, &ReceiveIO->error);
//  if (ReceiveIO->error > 0)
//  {
//    //LAUNCH_ER(P2_ERA_APPL, ERAD_FILEIO_ERROR, A_STRING, ReceiveIO->fname, A_16BITS, &ReceiveIO->error, END_OF_ARGLIST);
//    DELAY(EXIT_DELAY);
//    exit(0);
//  }
//  return(cnt_read);
//}

short mbeFileOpen(char *filename, short *fileid)
{
	static long long	ll_ems_time_last_open_jts = 0;
	short				ret = 0;
	short				err;

	if (*fileid)
		MBE_FILE_CLOSE_(*fileid);

	//if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
	if (err = MbeFileOpen_nw(filename, fileid))
	{
		log(LOG_ERROR, "error [%d] opening %s", err, filename);
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_open_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] opening %s", err, filename);
		ret++;
	}
	else
	{
		log(LOG_ERROR, "opened %s - id %d", filename, *fileid);
	}

	return ret;
}

void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...)
{
	va_list ap;
	char out[256];
	long long ll_current_ts = JULIANTIMESTAMP();

    if (ll_current_ts - *ll_ems_last_evt > ll_ems_interval)
    {
    	*ll_ems_last_evt = ll_current_ts;
        va_start(ap, msg);
        vsprintf(out, msg, ap);
        log_evt(i_critical, i_action, i_event_num, "%s", out);
        va_end(ap);
    }
}

short isOperatorListChanged()
{
	static long long	ll_oper_list_last_load = 0;

	short		ret = 1;
	short		err;
	char		key[TS_STRULES_KEYLEN];
	long long	ll_recordts;

	t_ts_soglie_record		soglie_rec;

	memset(key, '*', TS_STRULES_KEYLEN);
	if (!(err = MBE_FILE_SETKEY_(s_soglie_mbe_id, key, TS_STRULES_KEYLEN, 0, 2)))
	{
		//if (!(err = MBE_READX(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		if (!(err = MbeFileRead_nw(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		{
			// Any change happened ?
			memcpy( (char *)&ll_recordts, (char *)&(soglie_rec.tot_accP), sizeof(long long) );

			if (ll_oper_list_last_load == 0 || ((ll_recordts > ll_oper_list_last_load) && (ll_recordts < JULIANTIMESTAMP())))
			{
				ll_oper_list_last_load = ll_recordts;
			}
			else
			{
				ret = 0;
				log(LOG_ERROR, "Loading operators skipped - no change");
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] reading %s", err, ac_soglie_mbe_path);
			if (err!=1 && err!=11)
				mbeFileOpen(ac_soglie_mbe_path, &s_soglie_mbe_id);
		}
	}
	else
	{
		log(LOG_ERROR, "error [%d] seeking %s", err, ac_soglie_mbe_path);
		mbeFileOpen(ac_soglie_mbe_path, &s_soglie_mbe_id);
	}

	return ret;
}

void freeOperatorData(void *data)
{
	t_ts_oper_mem_record *oper_mem_rec = (t_ts_oper_mem_record *)data;

	oper_mem_rec->ptr_count--;
	if (oper_mem_rec->ptr_count <= 0)
	{
		if (oper_mem_rec->pa_op_list)
		{
			freeOperatorDataRule(oper_mem_rec->pa_op_list);
		}
		if (oper_mem_rec->pa_list)
		{
			freeOperatorDataRule(oper_mem_rec->pa_list);
		}
		if (oper_mem_rec->gr_pa_gr_op_list)
		{
			freeOperatorDataRule(oper_mem_rec->gr_pa_gr_op_list);
		}
		if (oper_mem_rec->gr_pa_list)
		{
			freeOperatorDataRule(oper_mem_rec->gr_pa_list);
		}

		free(oper_mem_rec);
		oper_mem_rec = NULL;
	}
}

void freeOperatorDataRule(t_ts_soglie_mem_record *rule)
{
	if (rule->next)
	{
		freeOperatorDataRule(rule->next);
	}

	free(rule);
}

short LoadOperatorList()
{
	short		ret = 0;
	short		err, err2;
	short		i;
	char		gt[30];
	char		*gt_ptr;
	char		key[TS_STRULES_KEYLEN];
	char		lte_key[11];
	char		ac_plmn_code[17];
	char		*p_imsi_op;

	short		s_oper_id = 0;
	short		s_opergt_id = 0;
	short		s_bordgt_id = 0;
	short		oper_count = 0;
	short		total_gt_count = 0;
	short		border_gt_count = 0;
	short		lte_count = 0;

	t_ts_oper_mem_record	*oper_mem_rec;
	t_ts_oper_record		oper_rec;
	t_ts_opergt_record		opergt_rec;

	FILE	*handle_apply_st;
	char	ac_apply_st_date[20];

	log(LOG_INFO, "Loading operators/thresholds...");
	ret = mbeFileOpen(ac_oper_path, &s_oper_id);
	if (!ret) ret = mbeFileOpen(ac_opergt_path, &s_opergt_id);
	if (!ret) ret = mbeFileOpen(ac_bordgt_path, &s_bordgt_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_oper_id, "", 0, 0, 0)))
		{
			avlCloseWithFunction(gt_oper_list, &freeOperatorData);
			avlCloseWithFunction(gt_bord_list, &freeOperatorData);
			gt_oper_list = avlMake();
			gt_bord_list = avlMake();

			//while (!(err = MBE_READX(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			while (!(err = MbeFileRead_nw(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			{
				if (oper_rec.paese[0] != '*')
				{
					oper_count++;

					memset(ac_plmn_code, 0x00, sizeof(ac_plmn_code));
					memcpy(ac_plmn_code, oper_rec.imsi_op, sizeof(oper_rec.imsi_op));
					TrimString(ac_plmn_code);
					p_imsi_op = strtok(ac_plmn_code, ",;:|");

					oper_mem_rec = (t_ts_oper_mem_record *)calloc(sizeof(t_ts_oper_mem_record), 1);
					if (oper_mem_rec == NULL)
					{
						log(LOG_ERROR, "memory allocation failed for operator [%.8s%.10s]", oper_rec.paese, oper_rec.cod_op);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading operator list");
					}
					else
					{
						memcpy(oper_mem_rec->paese, oper_rec.paese, 8);
						memcpy(oper_mem_rec->cod_op, oper_rec.cod_op, 10);
						strcpy(oper_mem_rec->mccmnc, p_imsi_op);
						oper_mem_rec->max_ts = (char)oper_rec.max_ts;
						oper_mem_rec->steering_map_errcode = (char)oper_rec.steering_map_errcode;
						oper_mem_rec->steering_lte_errcode = oper_rec.steering_lte_errcode;
						if (oper_rec.steering_border == 0x20)
							oper_rec.steering_border = 0x00;
						oper_mem_rec->steering_border = oper_rec.steering_border;

						if (oper_rec.reset_ts_interval == 0 || !memcmp((char *)&oper_rec.reset_ts_interval, "    ", 4))
							oper_mem_rec->ll_reset_ts_interval = ll_reset_ts_interval;
						else
							oper_mem_rec->ll_reset_ts_interval = (long long)oper_rec.reset_ts_interval * 1000000;

						// Lookup for preferred <pa/op> thresholds
						memset(key, 0x20, 128);
						memcpy(key, oper_rec.den_paese, 64);
						memcpy(key+64, oper_rec.cod_op, 10);
						oper_mem_rec->pa_op_list = loadOperatorRule(s_soglie_mbe_id, key, 128);

						// Lookup for steering <pa> thresholds
						oper_mem_rec->pa_list = loadOperatorRule(s_soglie_mbe_id, key, 64);

						// Lookup for preferred <grp_pa/grp_oper> thresholds
						memset(key, 0x20, 128);
						memcpy(key, oper_rec.gruppo_pa, 64);
						memcpy(key+64, oper_rec.gruppo_op, 64);
						oper_mem_rec->gr_pa_gr_op_list = loadOperatorRule(s_soglie_mbe_id, key, 128);

						// Lookup for steering <gr_pa> thresholds
						oper_mem_rec->gr_pa_list = loadOperatorRule(s_soglie_mbe_id, key, 64);

						// Load rule for GSM/GPRS GT
						if (!(err2 = MBE_FILE_SETKEY_(s_opergt_id, (char *)&oper_rec, 18, 1, 1)))
						{
							//while (!(err2 = MBE_READX(s_opergt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							while (!(err2 = MbeFileRead_nw(s_opergt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							{
								memset(gt, 0x00, sizeof(gt));
								gt_ptr = gt;
								for (i=0; i<sizeof(opergt_rec.gt); i++)
								{
									if (opergt_rec.gt[i] != 0x20)
									{
										*gt_ptr = opergt_rec.gt[i];
										gt_ptr++;
									}
								}
								TrimString(gt);

								if (avlAdd(gt_oper_list, gt, oper_mem_rec) == -1)
								{
									log(LOG_WARNING, "already existing gt [%s]", gt);
								}
								else
								{
									oper_mem_rec->ptr_count++;
									total_gt_count++;
								}
							}
						}
						else
						{
							log(LOG_ERROR, "error [%d] seeking operator gt", err2);
							log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking operator gt on %s", err2, ac_opergt_path);
						}

						// Load rule for GSM/GPRS border GT
						if (!(err2 = MBE_FILE_SETKEY_(s_bordgt_id, (char *)&oper_rec, 18, 1, 1)))
						{
							//while (!(err2 = MBE_READX(s_bordgt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							while (!(err2 = MbeFileRead_nw(s_bordgt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							{
								memset(gt, 0x00, sizeof(gt));
								gt_ptr = gt;
								for (i=0; i<sizeof(opergt_rec.gt); i++)
								{
									if (opergt_rec.gt[i] != 0x20)
									{
										*gt_ptr = opergt_rec.gt[i];
										gt_ptr++;
									}
								}
								TrimString(gt);

								if (avlAdd(gt_bord_list, gt, oper_mem_rec) == -1)
								{
									log(LOG_WARNING, "already existing border gt [%s]", gt);
								}
								else
								{
									oper_mem_rec->ptr_count++;
									border_gt_count++;
								}
							}
						}
						else
						{
							log(LOG_ERROR, "error [%d] seeking border gt", err2);
							log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking border gt on %s", err2, ac_bordgt_path);
						}

						// Load rule for LTE
						while (p_imsi_op)
						{
							memset(lte_key, 0x00, sizeof(lte_key));
							memcpy(lte_key, LTE_HSS_KEY, 4);
							strcat(lte_key+4, p_imsi_op);

							if (avlAdd(gt_oper_list, lte_key, oper_mem_rec) == -1)
							{
								log(LOG_WARNING, "already existing lte op [%s]", lte_key);
							}
							else
							{
								oper_mem_rec->ptr_count++;
								lte_count++;
							}

							p_imsi_op = strtok((char *)NULL, ",;:|");
						}

						// Free unused operator data
						if (!oper_mem_rec->ptr_count)
							freeOperatorData(oper_mem_rec);
					}
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking operator", err);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking operator on %s", err, ac_oper_path);
		}
	}

	if (ret) log(LOG_ERROR, "Loading operators/thresholds failed");
	else
	{
		log(LOG_ERROR, "Loading operators/thresholds completed (%d operators, %d gt, %d border gt, %d mcc/mnc)", oper_count, total_gt_count, border_gt_count, lte_count);

		// Update reload timestamp (APPLYST)
		if ((handle_apply_st = fopen_oss(ac_apply_ts_path, "w")))
		{
			fprintf(handle_apply_st, "%s\n", ConvertJTS2String(JULIANTIMESTAMP(), ac_apply_st_date));
			fclose(handle_apply_st);
		}
		else
		{
			log(LOG_ERROR, "Failed to open %s", ac_apply_ts_path);
		}
	}

	MBE_FILE_CLOSE_(s_oper_id);
	MBE_FILE_CLOSE_(s_opergt_id);
	MBE_FILE_CLOSE_(s_bordgt_id);

	return ret;
}

t_ts_soglie_mem_record *loadOperatorRule(short s_mbe_id, char *key, short keylen)
{
    short	err;
	short	soglie_count = 0;

	t_ts_soglie_record		soglie_rec;
	t_ts_soglie_mem_record	*first_rule = NULL;
	t_ts_soglie_mem_record	*new_rule = NULL;

	if (!(err = MBE_FILE_SETKEY_(s_mbe_id, key, keylen, 0, 1)))
	{
		//while (!(err = MBE_READX(s_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		while (!(err = MbeFileRead_nw(s_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		{
			// Record enabled ?
			if (soglie_rec.stato == 0x31)
			{
				// keylen 128 -> preferred record
				// keylen 64 -> ckeck gr_op different from preferred one
				if (keylen == 128 || memcmp(key+64, soglie_rec.gr_op, 64))
				{
					if (new_rule)
					{
						new_rule->next = (t_ts_soglie_mem_record *)malloc(sizeof(t_ts_soglie_mem_record));
						new_rule = new_rule->next;
					}
					else
					{
						new_rule = (t_ts_soglie_mem_record *)malloc(sizeof(t_ts_soglie_mem_record));
					}

					if (new_rule)
					{
						soglie_count++;
						if (!first_rule)
							first_rule = new_rule;

						new_rule->soglia = soglie_rec.soglia;
						new_rule->peso = soglie_rec.peso;
						new_rule->politica = soglie_rec.politica;
						memcpy(new_rule->key, soglie_rec.gr_pa, 64);
						memcpy(new_rule->key+64, soglie_rec.gr_op, 64);
						memcpy(new_rule->key+128, soglie_rec.fascia_da, 5);
						memcpy(new_rule->key+133, soglie_rec.fascia_a, 5);
						memcpy(new_rule->key+138, soglie_rec.gg_settimana, 7);
						memcpy(new_rule->key+145, soglie_rec.user_type, 4);
					}
					else
					{
						log(LOG_ERROR, "memory allocation failed for rule (%d,%.128s)", keylen, key);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading rule list");
						break;
					}
				}
			}
		}
		if (err != 1)
		{
			log(LOG_ERROR, "error [%d] reading rule", err);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading rule on %s", err, ac_soglie_mbe_path);
		}

		if (new_rule) new_rule->next = NULL;

		if (soglie_count)
		{
			if (keylen == 128) log(LOG_DEBUG, "loaded %d rules for [%.128s]", soglie_count, key);
			else log(LOG_DEBUG, "loaded %d rules for [%.64s]", soglie_count, key);
		}
	}
	else
	{
		log(LOG_ERROR, "error [%d] seeking rule", err);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking rule on %s", err, ac_soglie_mbe_path);
	}

	return first_rule;
}

short isRuleValid(t_ts_soglie_mem_record *rule, char user_type)
{
	short		ret = 0;
	struct tm	tm_time;
	time_t		now;
	char		fascia[6];
	int			user_type_bitmask;

	now = time((time_t *)NULL);
	tm_time = *localtime(&now);
	sprintf(fascia, "%02d:%02d", tm_time.tm_hour, tm_time.tm_min);

	// Check if user type is valid
	memcpy((char *)&user_type_bitmask, rule->key+145, 4);
	if ((user_type_bitmask >> user_type) & 0x01)
	{
		// Check if current day is valid
		if (rule->key[138+tm_time.tm_wday] == 'X')
		{
			// Check if current time is valid
			if (strncmp(fascia, rule->key+128, 5) >= 0 &&
				strncmp(fascia, rule->key+133, 5) <= 0)
			{
				ret = 1;
			}
		}
	}

	return ret;
}

t_ts_soglie_mem_record *seekOperatorRule(t_ts_soglie_mem_record *rule_list, char user_type)
{
	struct tm	tm_time;
	time_t		now;
	char		fascia[6];

	t_ts_soglie_mem_record	*rule;

	now = time((time_t *)NULL);
	tm_time = *localtime(&now);
	sprintf(fascia, "%02d:%02d", tm_time.tm_hour, tm_time.tm_min);

	rule = rule_list;
	while (rule)
	{
		if (isRuleValid(rule, user_type))
		{
			break;
		}
		rule = rule->next;
	}

	return rule;
}

short isRuleOverThreshold(t_ts_soglie_mem_record *rule, short s_check_threshold)
{
	short	ret = 0;
	short	err;
	t_ts_soglie_record soglie_rec;

	if (!(err = MBE_FILE_SETKEY_(s_soglie_mbe_id, rule->key, sizeof(rule->key), 0, 2)))
	{
		//if (!(err = MBE_READX(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		if (!(err = MbeFileRead_nw(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
		{
			if (!s_check_threshold || (s_check_threshold && (rule->soglia > 0)))
			{
				if (s_steering_method == 0)
				{
					ret = (((soglie_rec.tot_accP[0]+soglie_rec.tot_accP[1]) * 100. / 
							(soglie_rec.tot_accT[0]+soglie_rec.tot_accT[1]+0.0001)) > rule->soglia )?1:0;
				}
				else
				{
					/* soglia:  valore richiesto per l'operatore preferito: scala 0-100 
					   tot_ric: numero totale di richieste fatte
					   tot_acc: numero totale di richieste accettate
					*/

					float perc;	// percentuale chiamate accettate
					float p;	// probabilita` di accettazione
					float rnd;	// numero casuale generato
				  
					//  calcolo la percentuale di chiamate accettate in scala 0-100
					// (beh, puo` anche essere negativa, se FUZZY > 0)
					// notare il valore 0.0001 per essere certi di non avere mai 0/0
					perc = (float)((soglie_rec.tot_accP[0] + soglie_rec.tot_accP[1] + FUZZY) * 100. / 
								   (soglie_rec.tot_accT[0] + soglie_rec.tot_accT[1] + FUZZY + 0.0001));

					if (perc >= rule->soglia)
					{	// accettiamo incondizionatamente
						ret = 1;
					}
					else
					{	// verifichiamo
						rnd = (float)((random()%10000)/10000.);
						p = (perc/rule->soglia);	// se perc=soglia, p=1; se perc=0, p=0
						p = p/2;						// normalizziamo; in pratica abbiamo una parabola
						p = p*p;						// che va da 0 a 0.25

						if (rnd < p) ret = 1;
					}
				}
			}
			else
				ret = 1;
		}
		else
		{
			log(LOG_DEBUG, "%s|%s|%s|%s|rule not found", ac_gt, ac_operatore, ac_imsi, ac_imei);
		}
	}
	else
	{
		log(LOG_ERROR, "%s|%s|%s|%s|error [%d] seeking rule", ac_gt, ac_operatore, ac_imsi, ac_imei, err);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking rule on %s", err, ac_soglie_mbe_path);
	}

	return ret;
}

short areAllRulesOverThreshold(t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold)
{
	short	ret = 1;
	t_ts_soglie_mem_record	*rule;

	rule = rules;
	while (ret && rule)
	{
		if (isRuleValid(rule, user_type))
		{
			ret = isRuleOverThreshold(rule, s_check_threshold);
		}

		rule = rule->next;
	}

	return ret;
}

short arePrimaryRulesOverThreshold(t_ts_soglie_mem_record *srule, t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold)
{
	short	ret = 1;
	t_ts_soglie_mem_record	*rule;

	rule = rules;
	while (ret && rule)
	{
		if (isRuleValid(rule, user_type))
		{
			// Vanno considerate soltanto soglie con peso >= alla soglia secondaria
			if (srule->peso < rule->peso)
			{
				ret = isRuleOverThreshold(rule, s_check_threshold);
			}
		}

		rule = rule->next;
	}

	return ret;
}

void updateRule(t_ts_soglie_mem_record *rule,
				short s_check_threshold,
				short s_pref_acc,
				short s_tot_acc)
{
	short	err;
	t_ts_soglie_record soglie_rec;

	//if (*p_op_code == UL_OP_CODE)
	{
		if (!(err = MBE_FILE_SETKEY_(s_soglie_mbe_id, rule->key, sizeof(rule->key), 0, 2)))
		{
			//if (!(err = MBE_READLOCKX(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
			if (!(err = MbeFileReadL_nw(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
			{
				if (!s_check_threshold || (s_check_threshold && (rule->soglia > 0)))
				{
					soglie_rec.tot_accP[0] += s_pref_acc;
					soglie_rec.tot_accT[0] += s_tot_acc;

					//if ((err = MBE_WRITEUPDATEUNLOCKX(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
					if ((err = MbeFileWriteUU_nw(s_soglie_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec))))
					{
						log(LOG_ERROR, "%s|%s|%s|%s|error [%d] updating rule", ac_gt, ac_operatore, ac_imsi, ac_imei, err);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating rule on %s", err, ac_soglie_mbe_path);
						//MBE_UNLOCKREC(s_soglie_mbe_id);
						MbeUnlockRec_nw(s_soglie_mbe_id);
					}
				}
				else
				{
					//MBE_UNLOCKREC(s_soglie_mbe_id);
					MbeUnlockRec_nw(s_soglie_mbe_id);
				}
			}
			else
			{
				log(LOG_DEBUG, "%s|%s|%s|%s|rule not found", ac_gt, ac_operatore, ac_imsi, ac_imei);
			}
		}
		else
		{
			log(LOG_ERROR, "%s|%s|%s|%s|error [%d] seeking rule", ac_gt, ac_operatore, ac_imsi, ac_imei, err);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking rule on %s", err, ac_soglie_mbe_path);
			mbeFileOpen(ac_soglie_mbe_path, &s_soglie_mbe_id);
		}
	}
}

void updateRules(t_ts_soglie_mem_record *rules, char user_type, short s_check_threshold, short s_pref_acc, short s_tot_acc)
{
	t_ts_soglie_mem_record	*rule;

	rule = rules;
	while (rule)
	{
		if (isRuleValid(rule, user_type))
		{
			updateRule(rule, s_check_threshold, s_pref_acc, s_tot_acc);
		}
		rule = rule->next;
	}
}

void updateAllRules(t_ts_oper_mem_record *oper_mem_rec,
					t_ts_imsi_record *imsi_rec,
					t_ts_soglie_mem_record *prule,
					t_ts_soglie_mem_record *orules,
					char *ac_str,
					short i_idx)
{
	char	ac_ret_temp[50];

	strcpy(ac_ret_temp, ac_str);

	if (prule)
	{
		if (imsi_rec->num_ts_tmax <= imsi_rec->imei_info[1] &&
			memcmp(imsi_rec->cod_op, oper_mem_rec->cod_op, sizeof(imsi_rec->cod_op)) &&
			prule->soglia > 0)
		{
			strcpy(ac_ret, "access granted_next (preferred)");
			AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_OPERATOR_GRANTED_NEXT);
		}
		else
		{
			strcpy(ac_ret, "access granted (preferred)");
			AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+STAT_OPERATOR_GRANTED );
		}

		updateRule(prule, 0, 1, 1);
		if (orules)
		{
			updateRules(orules, imsi_rec->user_type, 1, 0, 1);
		}
	}
	else if (orules)
	{
		strcpy(ac_ret, "access granted");
		if (i_idx)
			AddStat(ac_ut_cc_op, ac_my_process_name, s_stat_net_type_shift+i_idx);
		updateRules(orules, imsi_rec->user_type, 1, 0, 1);
	}

	if (ac_ret_temp[0] != 0)
		sprintf(ac_ret, "%s - %s", ac_ret, ac_ret_temp);
}

short loadTacImeiList()
{
	short		ret = 0;
    short		err;
	short		tac_imei_count = 0;
	char		tac_imei_key[16];
	char		*key;

	t_ts_nostd_tac_record	nostd_tac_rec;

	if (!(err = MBE_FILE_SETKEY_(s_nostd_tac_mbe_id, "", 0, 0, 0)))
	{
		//while (!(err = MBE_READX(s_nostd_tac_mbe_id, (char *)&nostd_tac_rec, sizeof(nostd_tac_rec))))
		while (!(err = MbeFileRead_nw(s_nostd_tac_mbe_id, (char *)&nostd_tac_rec, sizeof(nostd_tac_rec))))
		{
			if (nostd_tac_rec.imei[0] != '*')	// '*' used as a special record for last upd timestamp
			{
				tac_imei_count++;
				memset(tac_imei_key, 0x00, sizeof(tac_imei_key));
				memcpy(tac_imei_key, nostd_tac_rec.imei, sizeof(nostd_tac_rec.imei));
				TrimString(tac_imei_key);
				key = calloc(strlen(tac_imei_key)+1, sizeof(char));
				strcpy(key, tac_imei_key);
				avlAdd(tac_imei_list, key, key);
			}
		}
		if (err != 1)
		{
			log(LOG_ERROR, "error [%d] reading %s", err, ac_nostd_tac_mbe_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_nostd_tac_mbe_path);
		}
	}
	else
	{
		ret++;
		log(LOG_ERROR, "error [%d] seeking %s", err, ac_nostd_tac_mbe_path);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_nostd_tac_mbe_path);
		mbeFileOpen(ac_nostd_tac_mbe_path, &s_nostd_tac_mbe_id);
	}

	if (ret) log(LOG_ERROR, "Loading nostdtac failed");
	else log(LOG_ERROR, "Loading nostdtac completed (%d)", tac_imei_count);

	return ret;
}

char isBorderCell(unsigned short lac, unsigned short ci_sac)
{
	char ac_user_loc[12];
	char is_border_cell = 0;

	sprintf(ac_user_loc, "%d;%d", lac, ci_sac);
	if (avlFind(border_cell_list, ac_user_loc))
	{
		is_border_cell = 1;
	}
	else if (ci_sac)
	{
		sprintf(ac_user_loc, "%d;0", lac);
		if (avlFind(border_cell_list, ac_user_loc))
		{
			is_border_cell = 1;
		}
	}

	return is_border_cell;
}

short loadBorderCellList()
{
	short		ret = 0;
	short		err;
	short		lac_cell_count = 0;
	char		lac_cell_key[16];
	char		*key;

	t_ts_border_cells_record	border_cell_rec;

	if (!(err = MBE_FILE_SETKEY_(s_border_cell_mbe_id, "", 0, 0, 0)))
	{
		//while (!(err = MBE_READX(s_border_cell_mbe_id, (char *)&border_cell_rec, sizeof(border_cell_rec))))
		while (!(err = MbeFileRead_nw(s_border_cell_mbe_id, (char *)&border_cell_rec, sizeof(border_cell_rec))))
		{
			if (border_cell_rec.lac)	// 0x0000 used as a special record for last upd timestamp
			{
				lac_cell_count++;
				memset(lac_cell_key, 0x00, sizeof(lac_cell_key));
				sprintf(lac_cell_key, "%d;%d", border_cell_rec.lac, border_cell_rec.ci_sac);
				key = calloc(strlen(lac_cell_key)+1, sizeof(char));
				strcpy(key, lac_cell_key);
				avlAdd(border_cell_list, key, key);
			}
		}
		if (err != 1)
		{
			log(LOG_ERROR, "error [%d] reading %s", err, ac_border_cell_mbe_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_border_cell_mbe_path);
		}
	}
	else
	{
		ret++;
		log(LOG_ERROR, "error [%d] seeking %s", err, ac_border_cell_mbe_path);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_border_cell_mbe_path);
		mbeFileOpen(ac_border_cell_mbe_path, &s_border_cell_mbe_id);
	}

	if (ret) log(LOG_ERROR, "Loading border cells failed");
	else log(LOG_ERROR, "Loading border cells completed (%d)", lac_cell_count);

	return ret;
}

short Func_PATHSEND_Proc(char *ac_process_name,
						 char *ac_serverclass_name,
						 char *msg_buffer,
						 short msg_buffer_size,
						 long timeout)
{
	short ret, ret_info;
	short ac_process_name_len;
	short ac_serverclass_name_len;
	short actual_reply_len;
	short p_err=0, fs_err=0;

	ac_process_name_len= (short)strlen(ac_process_name);
	ac_serverclass_name_len = (short)strlen(ac_serverclass_name);

	log(LOG_DEBUG,"PATHSEND to %s.%s", ac_process_name, ac_serverclass_name);

	ret = SERVERCLASS_SEND_(	ac_process_name,
								ac_process_name_len,
								ac_serverclass_name,
								ac_serverclass_name_len,
								msg_buffer,
								msg_buffer_size,
								msg_buffer_size,
								&actual_reply_len,
								timeout );

	if (ret!=0)
	{
		ret_info = Pathsend_info(&p_err, &fs_err);
		log(LOG_ERROR,"error [%d] in psend to <%s.%s> - ret_info <%d> p_err <%d> fs_err <%d>", ret, ac_process_name, ac_serverclass_name, ret_info, p_err, fs_err);
	}

	return ret;
}

short Pathsend_info(short *p_err,
					short *fs_err)
{
	short   ret;

	ret = SERVERCLASS_SEND_INFO_(p_err,fs_err);
	return(ret);
}

short getUserDeviceInfo(char *imsi, t_ts_imsi_record *imsi_rec)
{
	short				err, ret = 0;
	char				ac_validity_period[11];
	char				ac_tlv_tag[3];
	char				ac_RS[4];
	char				ac_MS[16];
	char				ac_OP[4];
	char				ac_IE[32];
	char				ac_ST[16];
	char				ac_BC[16];
	char				ac_PH[16];

	static long long	ll_ems_time_last_eir_jts = 0;
	t_appl_ip			psend_tlv_buffer;
	t_TrackingMsg_Book	buffer_data;

	if (c_flag_use_map3_usr)
	{
		//--- Composizione richiesta TLV -------------------------------
		psend_tlv_buffer.i_tag = MAP3_OPE_RECV_ID;
		InitTLV(psend_tlv_buffer.data, 1014, MAP3_OPE_RECV_TAG);
		//SetTagValue(psend_tlv_buffer.data, "ER", "TFS");
		SetTagValue(psend_tlv_buffer.data, "IM", imsi);
		SetTagValue(psend_tlv_buffer.data, "CI", "TFS");
		if (c_map3_usr_require_imei)
			SetTagValue(psend_tlv_buffer.data, "IE", "YN");
		SetTagValue(psend_tlv_buffer.data, "ST", "YN");
		SetTagValue(psend_tlv_buffer.data, "BC", "YN");
		SetTagValue(psend_tlv_buffer.data, "PH", "YN");
		if (i_map3_usr_validity)
			SetTagValue(psend_tlv_buffer.data, "VP", getDeferredTime(ac_validity_period, time((time_t *)NULL), 0, 0, i_map3_usr_validity));
		ResetTLV(psend_tlv_buffer.data);
		log(LOG_INFO, "%s|%s|%d|%s|%s|send map3 usr [%s]", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, psend_tlv_buffer.data);

		if (Func_PATHSEND_Proc(ac_map3_usr_process_name, ac_map3_usr_class_name, (char *)&psend_tlv_buffer, sizeof(psend_tlv_buffer), l_map3_usr_timeout))
		{
			AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_USR_KO);
		}
		else
		{
			log(LOG_INFO, "%s|%s|%d|%s|%s|recv map3 usr [%s]", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, psend_tlv_buffer.data);

			//--- Decodifica TLV -------------------------------------------
			if (CheckTVL(psend_tlv_buffer.data, ac_tlv_tag) || GetTagValue(psend_tlv_buffer.data, "RS", ac_RS))
			{
				log(LOG_ERROR, "%s|%s|%d|%s|%s|error in map3 usr response", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
				AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_USR_KO);
			}
			else
			{
				GetTagValue(psend_tlv_buffer.data, "MS", ac_MS);
				GetTagValue(psend_tlv_buffer.data, "OP", ac_OP);
				GetTagValue(psend_tlv_buffer.data, "IE", ac_IE);
				GetTagValue(psend_tlv_buffer.data, "ST", ac_ST);
				GetTagValue(psend_tlv_buffer.data, "BC", ac_BC);
				GetTagValue(psend_tlv_buffer.data, "PH", ac_PH);

				imsi_rec->user_type = mapUserType(ac_ST, ac_BC, ac_PH);
				if (ac_OP[0]) imsi_rec->operator = ac_OP[2];
				if (ac_IE[0]) memcpy(imsi_rec->imei, ac_IE, strlen(ac_IE));
				else memset(imsi_rec->imei, 0x30, 15);
				if (ac_MS[0])
				{
					memcpy(imsi_rec->msisdn, ac_MS, strlen(ac_MS));
					AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_USR_OK);
				}
				else
				{
					AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_USR_KO);
				}
			}
		}
	}
	else
	{
		// Default values (user type, operator)
		imsi_rec->user_type = c_default_user_type;
		imsi_rec->operator = 0x20;
		memset(imsi_rec->msisdn, 0x20, 16);
		memset(imsi_rec->imei, 0x30, 15);
	}

	// Set one-shot trigger (if not already set)
	//if (c_flag_use_trigger && !(c_trigger & 0x02))
	if (c_flag_use_trigger)
	{
		//memset((char *)&buffer_data, 0x20, sizeof(buffer_data));
		buffer_data.subsystem_id = i_eir_trigger_subsystem;
		buffer_data.version = 1;
		buffer_data.trigger_value = 0x02;
		strcpy(buffer_data.imsi, imsi);

		if (err = SendToEIRTrigger(&buffer_data))
		{
			log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] in mts to EIR <%d;%d>", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, err, i_eir_trigger_taskid, i_eir_trigger_serverclass);
			log_evt_t(ll_ems_time_interval, &ll_ems_time_last_eir_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_SS_SEND_ERROR, "error [%d] in mts to EIR <%d;%d>", err, i_eir_trigger_taskid, i_eir_trigger_serverclass);
			AddStat("eir", ac_my_process_name, STAT_MTS_SEND_KO);
		}
		else
		{
			log(LOG_INFO, "%s|%s|%d|%s|%s|sent to EIR", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
			AddStat("eir", ac_my_process_name, STAT_MTS_SEND_OK);
		}
	}

	if (imsi_rec->imei[0] == 0x20) ret++;
	return ret;
}

short getUserLocation(char *imsi, t_ts_imsi_record *imsi_rec)
{
	short				ret = 0;
	char				ac_validity_period[11];
	char				ac_tlv_tag[3];
	char				ac_RS[4];
	char				ac_VL[16];
	char				ac_CE[32];
	char				*mcc;
	char				*mnc;

	t_appl_ip			psend_tlv_buffer;

	imsi_rec->lac = 0;
	imsi_rec->ci_sac = 0;

	if (c_flag_use_map3_loc)
	{
		//--- Composizione richiesta TLV -------------------------------
		psend_tlv_buffer.i_tag = MAP3_LOC_RECV_ID;
		InitTLV(psend_tlv_buffer.data, 1014, MAP3_LOC_RECV_TAG);
		SetTagValue(psend_tlv_buffer.data, "IM", imsi);
		SetTagValue(psend_tlv_buffer.data, "CI", "TFS");
		SetTagValue(psend_tlv_buffer.data, "LI", "CELL");
		SetTagValue(psend_tlv_buffer.data, "GI", "N");
		if (i_map3_loc_validity)
			SetTagValue(psend_tlv_buffer.data, "VP", getDeferredTime(ac_validity_period, time((time_t *)NULL), 0, 0, i_map3_loc_validity));
		ResetTLV(psend_tlv_buffer.data);
		log(LOG_INFO, "%s|%s|%d|%s|%s|send map3 loc [%s]", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, psend_tlv_buffer.data);

		if (Func_PATHSEND_Proc(ac_map3_loc_process_name, ac_map3_loc_class_name, (char *)&psend_tlv_buffer, sizeof(psend_tlv_buffer), l_map3_loc_timeout))
		{
			AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_LOC_KO);
		}
		else
		{
			log(LOG_INFO, "%s|%s|%d|%s|%s|recv map3 loc [%s]", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, psend_tlv_buffer.data);

			//--- Decodifica TLV -------------------------------------------
			if (CheckTVL(psend_tlv_buffer.data, ac_tlv_tag) || GetTagValue(psend_tlv_buffer.data, "RS", ac_RS))
			{
				log(LOG_ERROR, "%s|%s|%d|%s|%s|error in map3 loc response", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei);
				AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_LOC_KO);
			}
			else
			{
				GetTagValue(psend_tlv_buffer.data, "VL", ac_VL);
				AddStat(ac_ut_cc_op, ac_my_process_name, STAT_MAP3_LOC_OK);

				// Decodifica MCC;MNC;LAC;CI/SAC se VLR nazionale
				if (!memcmp(ac_VL, ac_national_country_code, strlen(ac_national_country_code)))
				{
					GetTagValue(psend_tlv_buffer.data, "CE", ac_CE);
					mcc = strtok(ac_CE, ";");
					mnc = strtok((char *)NULL, ";");
					imsi_rec->lac = (unsigned short)atoi(strtok((char *)NULL, ";"));
					imsi_rec->ci_sac = (unsigned short)atoi(strtok((char *)NULL, ";"));
				}
			}
		}
	}

	if (!imsi_rec->lac) ret++;
	return ret;
}

short getTacImeiProfile(char *key, t_ts_imsi_record *imsi_record)
{
	short	ret = 0;
	short	err;
	char	tac_imei[15];
	char	*ptr;
	char	i;

	t_ts_nostd_tac_record	nostd_tac_rec;

	if (key)
	{
		memset(tac_imei, 0x20, sizeof(tac_imei));
		memcpy(tac_imei, key, strlen(key));
		if (!(err = MBE_FILE_SETKEY_(s_nostd_tac_mbe_id, tac_imei, sizeof(tac_imei), 0, 2)))
		{
			//if (!(err = MBE_READX(s_nostd_tac_mbe_id, (char *)&nostd_tac_rec, sizeof(nostd_tac_rec))))
			if (!(err = MbeFileRead_nw(s_nostd_tac_mbe_id, (char *)&nostd_tac_rec, sizeof(nostd_tac_rec))))
			{
				// Set trace level
				if (nostd_tac_rec.trace_level != 0x20)
					imsi_record->trace_level = nostd_tac_rec.trace_level;

				// Set profile
				nostd_tac_rec.stringa[sizeof(nostd_tac_rec.stringa)-1] = 0;
				TrimString(nostd_tac_rec.stringa);
				if (nostd_tac_rec.stringa[0] != IMEI_PROFILE_STANDARD &&
					nostd_tac_rec.stringa[0] != IMEI_PROFILE_UNKNOWN &&
					(ptr = strtok(nostd_tac_rec.stringa, ";")))
				{
					imsi_record->imei_info[0] = IMEI_PROFILE_SPECIFIC;
					i = 1;
					while (ptr)
					{
						imsi_record->imei_info[++i] = (char)atoi(ptr);
						ptr = strtok((char *)NULL, ";");
					}
					imsi_record->imei_info[1] = (char)(i-1);
					imsi_record->num_ts_tmax = imsi_record->imei_info[1] + 1;
				}
				else
				{
					imsi_record->imei_info[0] = IMEI_PROFILE_GRANT_ALWAYS;
				}
			}
			else if (err!=1 && err!=11)
			{
				ret++;
				log(LOG_WARNING, "error [%d] reading %s", err, ac_nostd_tac_mbe_path);
				log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_nostd_tac_mbe_path);
				mbeFileOpen(ac_nostd_tac_mbe_path, &s_nostd_tac_mbe_id);
			}
			else
			{
				imsi_record->imei_info[0] = IMEI_PROFILE_STANDARD;
				ret++;
			}
		}
		else
		{
			ret++;
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_nostd_tac_mbe_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_nostd_tac_mbe_path);
			mbeFileOpen(ac_nostd_tac_mbe_path, &s_nostd_tac_mbe_id);
		}
	}
	else
	{
		imsi_record->imei_info[0] = IMEI_PROFILE_STANDARD;
		ret++;
	}

	return ret;
}

char mapUserType(char *ac_ST, char *ac_BC, char *ac_PH)
{
	static char 	c_stmt_prepared = 0;
	char			sql_str_null[300];

	if (!c_stmt_prepared)
	{
		// Prepare
		memset(sql_str, 0x20, sizeof(sql_str));
		sprintf(sql_str, "select cl_val from %s where st=? and bc=? and (ph=? or ph=0) order by ph desc browse access", ac_map3_usr_type_table);
		strcpy(sql_str_null, sql_str);
		sql_str[strlen(sql_str)] = 0x20;
		exec sql prepare usr_type_statement from :sql_str;
		if (!sqlcode)
		{
			exec sql declare usr_type_cursor cursor for usr_type_statement;
		}

		if (sqlcode && sqlcode != 6008)
		{
			log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] preparing statement (%s)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei,  sqlcode, sql_str_null);
		}
		else
			c_stmt_prepared = 1;
	}

	if (c_stmt_prepared)
	{
		// Execute blocked profile search
		usr_type.st = 0;
		usr_type.bc = 0;
		usr_type.ph = (short)atoi(ac_PH);
		exec sql open usr_type_cursor using :usr_type.st, :usr_type.bc, :usr_type.ph;
		if (!sqlcode)
		{
			exec sql fetch usr_type_cursor into :usr_type.cl_val;
		}

		if (!sqlcode)
		{
			log(LOG_INFO, "%s|%s|%d|%s|%s|blocked profile %d (ph %s)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, usr_type.cl_val, ac_PH);
			exec sql close usr_type_cursor;
			return((char)usr_type.cl_val);
		}
		else
		{
			exec sql close usr_type_cursor;

			// Execute user type search
			usr_type.st = (short)atoi(ac_ST);
			usr_type.bc = (short)atoi(ac_BC);
			usr_type.ph = (short)atoi(ac_PH);
			exec sql open usr_type_cursor using :usr_type.st, :usr_type.bc, :usr_type.ph;
			if (!sqlcode)
			{
				exec sql fetch usr_type_cursor into :usr_type.cl_val;
			}

			if (sqlcode)
			{
				if (sqlcode == 100) log(LOG_WARNING, "%s|%s|%d|%s|%s|user type not found (%s,%s,%s)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, ac_ST, ac_BC, ac_PH);
				else log(LOG_ERROR, "%s|%s|%d|%s|%s|error [%d] selecting user type (%s,%s,%s)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, sqlcode, ac_ST, ac_BC, ac_PH);
				exec sql close usr_type_cursor;
			}
			else
			{
				log(LOG_INFO, "%s|%s|%d|%s|%s|user type %d (%s,%s,%s)", ac_gt, ac_operatore, *p_op_code, ac_imsi, ac_imei, usr_type.cl_val, ac_ST, ac_BC, ac_PH);
				exec sql close usr_type_cursor;
				return((char)usr_type.cl_val);
			}
		}
	}
	return(c_default_user_type);
}

short MAP_ReplyOut(t_ts_data *mbuffer)
{
	short	ret;
	static unsigned char	uc_mts_error_open = 0;
	static long long		ll_ems_time_last_mts_jts = 0;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	switch (mbuffer->result_address.choice)
	{
		case choice_mts_address:
		{
			mts_addr_std.flags.mode = 0;
			mts_addr_std.flags.zero = 0;
			mts_addr_std.flags.generic_id = '#';
			memcpy((char *)&mts_addr_std.to, (char *)&(mbuffer->result_address.address), sizeof(mts_addr_std.to));
			ret = MTS_SEND(&mts_addr_std, mbuffer, sizeof(t_ts_data));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to MAP-OUT <%d;%d>", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to MAP-OUT <%d;%d>", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
				}
			}
			break;
		}
		case choice_process_name:
		{
			ret = MTS_SEND((P2_MTS_PROC_ADDR_DEF *)&(mbuffer->result_address.address), mbuffer, sizeof(t_ts_data));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to MAP-OUT (%s)", ret, ((P2_MTS_PROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to MAP-OUT (%s)", ((P2_MTS_PROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		case choice_extend_process_name:
		{
			ret = MTS_SEND((P2_MTS_EPROC_ADDR_DEF *)&(mbuffer->result_address.address), mbuffer, sizeof(t_ts_data));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to MAP-OUT (%s)", ret, ((P2_MTS_EPROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to MAP-OUT (%s)", ((P2_MTS_EPROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		default:
		{
			log(LOG_ERROR, "%s|%s|%d|%s|%s|invalid address type for MAP outbound (%d)", ac_gt, ac_operatore, mbuffer->op_code, ac_imsi, ac_imei, mbuffer->result_address.choice);
			ret++;
		}
	}

	return ret;
}

short LTE_ReplyOut(TFS_LTE_IPC *lbuffer)
{
	short	ret;
	static unsigned char	uc_mts_error_open = 0;
	static long long		ll_ems_time_last_mts_jts = 0;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	switch (lbuffer->result_address.choice)
	{
		case choice_mts_address:
		{
			mts_addr_std.flags.mode = 0;
			mts_addr_std.flags.zero = 0;
			mts_addr_std.flags.generic_id = '#';
			memcpy((char *)&mts_addr_std.to, (char *)&(lbuffer->result_address.address), sizeof(mts_addr_std.to));
			ret = MTS_SEND(&mts_addr_std, lbuffer, sizeof(TFS_LTE_IPC));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to LTE <%d;%d>", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to LTE <%d;%d>", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
				}
			}
			break;
		}
		case choice_process_name:
		{
			ret = MTS_SEND((P2_MTS_PROC_ADDR_DEF *)&(lbuffer->result_address.address), lbuffer, sizeof(TFS_LTE_IPC));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to LTE (%s)", ret, ((P2_MTS_PROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to LTE (%s)", ((P2_MTS_PROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		case choice_extend_process_name:
		{
			ret = MTS_SEND((P2_MTS_EPROC_ADDR_DEF *)&(lbuffer->result_address.address), lbuffer, sizeof(TFS_LTE_IPC));
			if (ret)
			{
				uc_mts_error_open = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts to LTE (%s)", ret, ((P2_MTS_EPROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts to LTE (%s)", ((P2_MTS_EPROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		default:
		{
			log(LOG_ERROR, "%s|%s|%d|%s|%s|invalid address type for LTE (%d)", lbuffer->ac_visited_PLMN_Id, ac_operatore, lbuffer->i_op, ac_imsi, ac_imei, lbuffer->result_address.choice);
			ret++;
		}
	}

	return ret;
}

short SendToEIRTrigger(t_TrackingMsg_Book *mbuffer)
{
	short	ret;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	mts_addr_std.flags.mode = 0;
	mts_addr_std.flags.zero = 0;
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.cpu_req = 0;
	mts_addr_std.to.cpu = 0;
	mts_addr_std.to.task_id = i_eir_trigger_taskid;
	mts_addr_std.to.server_class = i_eir_trigger_serverclass;
	ret = MTS_SEND(&mts_addr_std, mbuffer, sizeof(t_TrackingMsg_Book));

	return(ret);
}

short SendToWelcome(t_ts_welcome_record *mbuffer)
{
	short	ret;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	mts_addr_std.flags.mode = 0;
	mts_addr_std.flags.zero = 0;
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.cpu_req = 0;
	mts_addr_std.to.cpu = 0;
	mts_addr_std.to.task_id = i_welcome_subsys;
	mts_addr_std.to.server_class = i_welcome_class;
	ret = MTS_SEND(&mts_addr_std, mbuffer, sizeof(t_ts_welcome_record));

	return(ret);
}

long long CurrentLastMidnightJTS()
{
	//char		ac_date[20];
	short		dateNtime[8];
	int			i;
	long long	gmt, lct;

	for (i=0; i<8; i++) dateNtime[i] = 0;

	// 48-bit timestamp in LCT
	TIME(dateNtime);
	lct = COMPUTETIMESTAMP(dateNtime);
	//log(LOG_INFO, "LCT %s (%Ld)", ConvertJTS2TS(lct, ac_date), lct);

	// midnight in LCT
	for (i=3; i<8; i++) dateNtime[i] = 0;
	lct = COMPUTETIMESTAMP(dateNtime);

	// midnight in GMT
	gmt = CONVERTTIMESTAMP(lct, 2);
	return(gmt);
}

char *ConvertJTS2String(long long jts, char *ts)
{
	short		dateNtime[8];

	INTERPRETTIMESTAMP(jts, dateNtime);

	sprintf(ts, "%04d%02d%02d%02d%02d%02d",
			dateNtime[0],
			dateNtime[1],
			dateNtime[2],
			dateNtime[3],
			dateNtime[4],
			dateNtime[5]);

	return(ts);
}

short getDayOfWeek()
{
	struct tm def_tm_time;
	time_t now = time((time_t *)NULL);

	def_tm_time = *localtime(&now);
	return (short)def_tm_time.tm_wday;
}

/* TLV validity period or SMS deferred time
 * Returns a string containing <time> deferred by (hour, min, sec)
 */
char *getDeferredTime(char *def_time, time_t time, int hour, int min, int sec)
{
	struct tm def_tm_time;
	time_t now = time - 3600*hour - 60*min - sec;

	def_tm_time = *localtime(&now);
	sprintf(def_time, "%02d%02d%02d%02d%02d",
		def_tm_time.tm_mday,
		def_tm_time.tm_mon + 1,
		def_tm_time.tm_year % 100,
		def_tm_time.tm_hour,
		def_tm_time.tm_min
	);

    return(def_time);
}

char *getYeartoDay(char *ts)
{
	struct tm def_tm_time;
	time_t now = time((time_t *)NULL);

	def_tm_time = *localtime(&now);
	sprintf(ts, "%04d%02d%02d",
		def_tm_time.tm_year + 1900,
		def_tm_time.tm_mon + 1,
		def_tm_time.tm_mday
	);

	return(ts);
}

void checkProcessTime(long long timestamp)
{
	static long long	ll_ems_time_last_ptime_jts = 0;

	long long	ll_current_jts;
	int			i_req_process_time;

	ll_current_jts = JULIANTIMESTAMP();
	i_req_process_time = (int)((ll_current_jts - timestamp) / 1000);

	if (i_req_process_time <= 5)
		AddStat("<= 5/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 10)
		AddStat("<= 10/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 25)
		AddStat("<= 25/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 50)
		AddStat("<= 50/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 75)
		AddStat("<= 75/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 100)
		AddStat("<= 100/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 250)
		AddStat("<= 250/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 500)
		AddStat("<= 500/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 750)
		AddStat("<= 750/1000", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 1000)
		AddStat("<= 1", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 2000)
		AddStat("<= 2", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else if (i_req_process_time <= 3000)
		AddStat("<= 3", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);
	else
		AddStat("> 3", ac_my_process_name, s_stat_net_type_shift+STAT_PROCESSING_TIME);

	if (i_req_process_time > i_max_process_time)
	{
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_ptime_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_RESPONSE_TIME, "Warning on processing time (%dms)", i_req_process_time);
	}
}

void logRegistrationTime(t_ts_imsi_record *imsi_rec, long long ts, char *gt, char *oper, short opcode, char *imsi)
{
	char 			ac_rt_stat_register[30];
	short			s_rt_stat_offset;
	unsigned int	i_rt_regtime = (ts - imsi_rec->init_ts_op)/1000000;

	// Update registration log file (if enabled)
	if ((i_logfile_id_rt > 0) && (imsi_rec->init_ts_op > 0))
		file_write(i_logfile_id_rt, LOG_ERROR, "%s|%s|%d|%s|%u", gt, oper, opcode, imsi, i_rt_regtime);

	// Update statistics (always)
	if (i_rt_regtime == 0)
		s_rt_stat_offset = 0;
	else if (i_rt_regtime <= 60)
		s_rt_stat_offset = 1;
	else if (i_rt_regtime <= 120)
		s_rt_stat_offset = 2;
	else if (i_rt_regtime <= 180)
		s_rt_stat_offset = 3;
	else
		s_rt_stat_offset = 4;

	sprintf(ac_rt_stat_register, "%s|%d", ac_ut_cc_op, opcode);
	AddStat(ac_rt_stat_register, ac_my_process_name, STAT_REG_TIME_ZERO + s_rt_stat_offset);

	imsi_rec->init_ts_op = 0;
}

short insertCCCEvent(t_ts_imsi_record *imsi_rec)
{
	static long long ll_ems_time_last_ccc_jts = 0;
	short	ret = 0;
	short	err;
	char	ac_msisdn[20];
	char	ac_rev_msisdn[20];

	t_ts_cc_change_queue_record		ccc_rec;

	if (imsi_rec->msisdn[0] != 0x20)
	{
		// Write into CCC queue
		memset((char *)&ccc_rec, 0x20, sizeof(ccc_rec));

		memset(ac_msisdn, 0x00, sizeof(ac_rev_msisdn));
		memcpy(ac_msisdn, imsi_rec->msisdn, sizeof(imsi_rec->msisdn));
		TrimString(ac_msisdn);
		strcpy(ac_rev_msisdn, ac_msisdn);
		StringReverse(ac_rev_msisdn);

		memcpy(ccc_rec.msisdn, ac_rev_msisdn, strlen(ac_rev_msisdn));
		if (!(err = MBE_FILE_SETKEY_(s_ccc_que_id, ccc_rec.msisdn, sizeof(ccc_rec.msisdn), 0, 2)))
		{
			err = MbeFileRead_nw(s_ccc_que_id, (char *)&ccc_rec, sizeof(ccc_rec));

			memcpy(ccc_rec.imsi, ac_imsi, strlen(ac_imsi));
			memcpy(ccc_rec.cc, imsi_rec->paese, 8);
			ccc_rec.timestamp = JULIANTIMESTAMP();
			ccc_rec.i_retry = 0;

			if (!err)
			{
				if (!(err = MbeFileWriteUU_nw(s_ccc_que_id, (char *)&ccc_rec, sizeof(ccc_rec))))
				{
					log(LOG_INFO, "%s|CCC queue updated|%.8s", ac_msisdn, ccc_rec.cc);
				}
				else
				{
					ret++;
					log_evt_t(ll_ems_time_interval, &ll_ems_time_last_ccc_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating %s", err, ac_ccc_que_path);
					log(LOG_ERROR, "%s|error [%d] updating %s", ac_msisdn, err, ac_ccc_que_path);
					if (err!=1 && err!=11)
						mbeFileOpen(ac_ccc_que_path, &s_ccc_que_id);
				}
			}
			else
			{
				if (!(err = MbeFileWrite_nw(s_ccc_que_id, (char *)&ccc_rec, sizeof(ccc_rec))))
				{
					log(LOG_INFO, "%s|CCC queue inserted |%.8s", ac_msisdn, ccc_rec.cc);
				}
				else
				{
					ret++;
					log_evt_t(ll_ems_time_interval, &ll_ems_time_last_ccc_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] writing %s", err, ac_ccc_que_path);
					log(LOG_ERROR, "%s|error [%d] writing %s", ac_msisdn, err, ac_ccc_que_path);
					if (err!=45)	// Error but file full
						mbeFileOpen(ac_ccc_que_path, &s_ccc_que_id);
				}
			}
		}
		else
		{
			ret++;
			log_evt_t(ll_ems_time_interval, &ll_ems_time_last_ccc_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_ccc_que_path);
			log(LOG_ERROR, "%s|error [%d] seeking %s", ac_msisdn, err, ac_ccc_que_path);
			mbeFileOpen(ac_ccc_que_path, &s_ccc_que_id);
		}
	}

	return(ret);
}

short insertRoamEU(t_ts_imsi_record *imsi_rec, char status, char changed, char *mccmnc)
{
	static long long ll_ems_time_last_roameuq_jts = 0;
	short	ret = 0;
	short	err;

	t_ts_if4_record		roameu_rec;

	// Write into IF4 queue
	memset((char *)&roameu_rec, 0x20, sizeof(roameu_rec));
	memcpy(roameu_rec.imsi, imsi_rec->imsi, 16);
	if (!(err = MBE_FILE_SETKEY_(s_roaming_eu_if4_id, roameu_rec.imsi, sizeof(roameu_rec.imsi), 0, 2)))
	{
		err = MbeFileRead_nw(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec));

		memcpy(roameu_rec.msisdn, imsi_rec->msisdn, 16);
		roameu_rec.roamingStatus = status;
		roameu_rec.roamingChanged = changed;
		memcpy(roameu_rec.mccmnc, mccmnc, strlen(mccmnc));
		roameu_rec.jts = JULIANTIMESTAMP();
		roameu_rec.c_retry = 0;

		if (!err)
		{
			if (!(err = MbeFileWriteUU_nw(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec))))
			{
				log(LOG_INFO, "%s|EU roaming updated (%d,%d,%s)", ac_imsi, status, changed, mccmnc);
			}
			else
			{
				ret++;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating %s", err, ac_roaming_eu_if4_path);
				log(LOG_ERROR, "%s|error [%d] updating %s", ac_imsi, err, ac_roaming_eu_if4_path);
				if (err!=1 && err!=11)
					mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
			}
		}
		else
		{
			if (!(err = MbeFileWrite_nw(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec))))
			{
				log(LOG_INFO, "%s|EU roaming inserted (%d,%d,%s)", ac_imsi, status, changed, mccmnc);
			}
			else
			{
				ret++;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] writing %s", err, ac_roaming_eu_if4_path);
				log(LOG_ERROR, "%s|error [%d] writing %s", ac_imsi, err, ac_roaming_eu_if4_path);
				if (err!=45)	// Error but file full
					mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
			}
		}
	}
	else
	{
		ret++;
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_roaming_eu_if4_path);
		log(LOG_ERROR, "%s|error [%d] seeking %s", ac_imsi, err, ac_roaming_eu_if4_path);
		mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
	}

	return(ret);
}
