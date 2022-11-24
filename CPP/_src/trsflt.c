/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsflt.c
*   Last Modified : 07/03/2017
*------------------------------------------------------------------------------
*   Description
*   -----------
*   Traffic Steering Filter or so called pre-steering
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   MAP: static MAP error code returned for GT and/or MGT list
*   LTE: static LTE error code returned for MCC/MNC
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
//#include <eralilib.eraccl>
#include <p2apdf.h>
#include "usrlib.h"

#include "mbedb.h"
#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"
#include "sspstat.h"

#include "ds.h"
#include "ts.h"
#include "roamun.h"

/*---------------------< Definitions >---------------------------------------*/

#define	INI_SECTION_NAME			"FILTER"
#define LTE_HSS_KEY					"LTE/HSS         "

/*---------------------< Parameters >----------------------------------------*/

char		ac_path_log_file[30];
char		ac_log_prefix[10];
int			i_num_days_of_log;
int			i_trace_level;
int			i_log_options;
char		ac_log_trace_string[128];

char		ac_path_stat_file[30];
char		ac_stat_prefix[3];
short		i_stat_group;
short		i_stat_max_registers;
short		i_stat_max_counters;
int			i_stat_bump_interval;

short		s_ems_subsystem;
char		ac_ems_owner[16];
char		ac_ems_version[16];
char		ac_ems_appl[32];
char		ac_ems_text[168];
long long	ll_ems_time_interval;

char		ac_paesi_mbe_path[48];
char		ac_oper_path[48];
char		ac_opergt_path[48];
char		ac_psrules_path[48];
char		ac_mgt_path[48];
char		ac_arp_lbo_mbe_path[48];
char		ac_apply_ps_path[48];

char		ac_imsi_gsm_mbe_path[48];
char		ac_imsi_dat_mbe_path[48];

short		s_block_unknown_gt;
short		s_block_unknown_mccmnc;
char		c_lbo_prv_only;
int			i_mbe_timeout;

int			i_load_rules_interval;
int			i_load_rules_cpu_shift;

char		c_node_id;
short		s_filter_task_id;
short		s_filter_server_class;
short		s_steering_task_id;
short		s_steering_server_class;
char		ac_imsi_prefix_mgt[16];
short		s_imsi_prefix_len;
short		s_mgt_by_range;

/*---------------------< Static and Global Variables >-----------------------*/

IO_RECEIVE  ReceiveIO;

char	ac_my_process_name[10];

short	i_my_node_id;
short	i_my_cpu;
short	i_loop_timer;
short	i_read_timeout;

char	*pc_ini_file;
char	ac_path_file_ini_oss[64];

char	ac_imsi[MAX_INS_STRING_LENGTH];
char	ac_imsi_mgt[MAX_INS_STRING_LENGTH];
char	ac_mgt[MAX_INS_STRING_LENGTH];
char	ac_gt[MAX_INS_STRING_LENGTH];
char	ac_imsi_suffix[MAX_INS_STRING_LENGTH];

char	ac_paese[9];
char	ac_operatore[11];
char	ac_ut_cc_op[22];
char	ac_ue_country_list[256];

short	s_imsi_gsm_mbe_id = 0;
short	s_imsi_dat_mbe_id = 0;
//short	s_imsi_lte_mbe_id = 0;

short	s_psrules_id = 0;
short	s_arp_lbo_mbe_id = 0;

AVLTREE	mgt_list;
AVLTREE	gt_oper_list;		// Hashtable for gt, data holds paese/cod_op
AVLTREE	lte_oper_list;		// Hashtable for plmn id, data holds paese/cod_op
AVLTREE psrules_list;

t_ts_data	map_buffer;
TFS_LTE_IPC	lte_buffer;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization(char reload);
void Print_Process_Parameters();
short checkIniFile();

void Open_Input_Queue(IO_RECEIVE *ReceiveIO);
short mbeFileOpen(char *filename, short *fileid);
void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...);
short Func_PATHSEND_Proc(char *ac_process_name, char *ac_serverclass_name, char *msg_buffer, short msg_buffer_size);
short Pathsend_info(short *p_err, short *fs_err);
char *ConvertJTS2String(long long jts, char *ts);

short isImsiInWhiteList(short type, char *imsi, char bypass_enabled);
short isRuleListChanged();
void freeOperatorData(void *data);
void freeRuleData(void *data);
short loadMgtList();
char *findMgtByRange(char *mgt);
short loadRuleList();
short loadUEList();
t_ts_psrule_mem_record *seekPreSteeringRule(t_ts_psrule_mem_record *rule_list);

short MAP_LoadOperatorList();
short MAP_ForwardToSteering(t_ts_data *mbuffer);
short MAP_ReplyOut(t_ts_data *mbuffer);

short LTE_LoadOperatorList();
short LTE_ForwardToSteering(TFS_LTE_IPC *lbuffer);
short LTE_ReplyOut(TFS_LTE_IPC *lbuffer);

short mapProxyRequired(char ue, short lu_type, char *imsi, char *proxy, short *arpId, char *eu_flag, char *err_msg);

/*---------------------------------------------------------------------------*/
int main (short argc, char * argv[])
{
	short	rc;					// Return code after reading a new message
	short	Stop = 0;			// Whether to exit the infinite loop
	//short	file_id;			// Source of the received message
	short	receive_cnt;
	short	ret = 0;
	char	ac_ret_msg[256];
	short	i_tfs_tag;
	int		i;
	int		i_stat_bump_retry_interval;

	short	sender_info[17];
    short	sender_handle[10];
    char	sender_process_name[16];
    short	sender_process_maxlen = sizeof(sender_process_name);

    short	sender_mom_handle[10];
    char	sender_mom_process_name[16];
    short	sender_mom_process_maxlen = sizeof(sender_mom_process_name);

	char					*ptr_impianto_mgt;
	char					ac_impianto_mgt[20];
	t_ts_psoper_mem_record	*psoper_mem_rec;
	t_ts_psrule_mem_record	*psrule_mem_rec;
	t_ts_psrule_mem_record	*valid_psrule;
	char					ac_psrule_key[60];
	char					ac_paese_ue[8];

	IO_SYSMSG_TIMEOUT		signal;

	Process_Initialization(0);

	// Open $RECEIVE
	Open_Input_Queue(&ReceiveIO);

	// Open MBEs and dbs
	Stop = mbeFileOpen(ac_psrules_path, &s_psrules_id);
	if (!Stop) Stop = mbeFileOpen(ac_imsi_gsm_mbe_path, &s_imsi_gsm_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_imsi_dat_mbe_path, &s_imsi_dat_mbe_id);
	if (!Stop && ac_arp_lbo_mbe_path[0]) Stop = mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);

	// Load operator list
	if (!Stop && isRuleListChanged())
	{
		Stop = loadMgtList();
		if (!Stop) Stop = MAP_LoadOperatorList();
		if (!Stop) Stop = LTE_LoadOperatorList();
		if (!Stop) Stop = loadRuleList();
		if (!Stop && ac_arp_lbo_mbe_path[0]) Stop = loadUEList();
	}

	if (!Stop)
	{
		log(LOG_ERROR, "Process started");
		log(LOG_WARNING, "Sizeof MAP buffer: %d", sizeof(t_ts_data));
		log(LOG_WARNING, "Sizeof LTE buffer: %d", sizeof(TFS_LTE_IPC));
		//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

		if (i_load_rules_interval > 0)
			SIGNALTIMEOUT_(i_load_rules_interval + i_load_rules_cpu_shift*i_my_cpu, 0, TAG_LOAD_RULES);
		if (i_stat_bump_interval > 0)
			SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
	}

	// Main Loop
	while (!Stop) 
	{
		rc = RECEIVE_( ReceiveIO.data, (short)sizeof(ReceiveIO.data), &receive_cnt, P2_GEN_WAITFOREVER );
		log(LOG_DEBUG, "Rcv: rc = %d, cnt = %d", rc, receive_cnt);

		switch(rc)
		{
			case 0:
			{
				memcpy((char *)&i_tfs_tag, ReceiveIO.data, 2);

				if (i_tfs_tag == TAG_MAP_IN)
				{
					memcpy((char *)&map_buffer, ReceiveIO.data, sizeof(map_buffer));
					valid_psrule = NULL;

					// GT (VLR -->)
					memset(ac_gt, 0x00, sizeof(ac_gt));
					memcpy(ac_gt, map_buffer.MGT_mitt.address.value, map_buffer.MGT_mitt.address.length);

					// MGT (--> HLR)
					memset(ac_mgt, 0x00, sizeof(ac_mgt));
					memcpy(ac_mgt, map_buffer.MGT_dest.address.value, map_buffer.MGT_dest.address.length);

					// IMSI
					memset(ac_imsi, 0x00, sizeof(ac_imsi));
					if (map_buffer.imsi.length)
					{
						// Got IMSI from MAP layer
						memcpy(ac_imsi, map_buffer.imsi.value, map_buffer.imsi.length);
					}

					// Rebuild MGT from IMSI (do not trust received MGT, e.g. E.164 format)
					sprintf(ac_imsi_mgt, "%s%s", ac_imsi_prefix_mgt, ac_imsi+s_imsi_prefix_len);

					log(LOG_INFO, "Recv msg from VLR [%s] for IMSI [%s] MGT [%s] rebuilt MGT [%s]", ac_gt, ac_imsi, ac_mgt, ac_imsi_mgt);

					// Check MGT
					if (s_mgt_by_range)
						ptr_impianto_mgt = findMgtByRange(ac_imsi_mgt);
					else
						ptr_impianto_mgt = avlFindLpm(mgt_list, ac_imsi_mgt);

					if (ptr_impianto_mgt != AVLNULL)
					{
						// MGT found
						memset(ac_impianto_mgt, 0x00, sizeof(ac_impianto_mgt));
						memcpy(ac_impianto_mgt, ptr_impianto_mgt, strlen(ptr_impianto_mgt));
					}
					else
					{
						// Unknown mgt
						strcpy(ac_impianto_mgt, "-");
					}

					// Check country and operator
					psoper_mem_rec = avlFindLpm(gt_oper_list, ac_gt);
					if (psoper_mem_rec != AVLNULL)
					{
						// Operator found
						memset(ac_paese, 0, sizeof(ac_paese));
						memcpy(ac_paese, psoper_mem_rec->paese, sizeof(psoper_mem_rec->paese));
						TrimString(ac_paese);
						memset(ac_operatore, 0, sizeof(ac_operatore));
						memcpy(ac_operatore, psoper_mem_rec->cod_op, sizeof(psoper_mem_rec->cod_op));
						TrimString(ac_operatore);
						sprintf(ac_ut_cc_op, "-|%s|%s", ac_paese, ac_operatore);

						// ARP/LBO check
						if (ac_arp_lbo_mbe_path[0])
						{
							sprintf(ac_paese_ue, ";%s;", ac_paese);
							if (mapProxyRequired(strstr(ac_ue_country_list, ac_paese_ue)?1:0, map_buffer.op_code, ac_imsi, &(map_buffer.proxy), &(map_buffer.arpId), &(map_buffer.eu_flag), ac_ret_msg))
								log(LOG_ERROR, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, ac_ret_msg);
							else
								log(LOG_INFO, "%s|%s|%d|%s|%s|%s", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, ac_ret_msg);
						}
					}
					else
					{
						// Unknown operator
						strcpy(ac_operatore, "-");
						strcpy(ac_ut_cc_op, "-|-|-");
					}

					// Stats
					AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RECV);
					if (map_buffer.c_E164 == 0x01)
					{
						log(LOG_WARNING, "%s|%s|%d|%s|%s|rcv E.164 destination", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt);

						if (map_buffer.op_code == UL_OP_CODE)
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_UL_GSM_E164);
						else if (map_buffer.op_code == UL_OP_CODE_GPRS)
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_UL_GPRS_E164);
					}

					// Check operation type
					if ((map_buffer.op_code == UL_OP_CODE) || (map_buffer.op_code == UL_OP_CODE_GPRS))
					{
						if (strcmp(ac_impianto_mgt, "-"))
						{
							if (strcmp(ac_operatore, "-"))
							{
								// Search pre-steering rule
								memset(ac_psrule_key, 0x20, sizeof(ac_psrule_key));
								ac_psrule_key[sizeof(ac_psrule_key)-1] = 0x00;
								memcpy(ac_psrule_key, ac_impianto_mgt, strlen(ac_impianto_mgt));
								memcpy(ac_psrule_key+16, (char *)psoper_mem_rec, 18);
								memcpy(ac_psrule_key+34, ac_gt, strlen(ac_gt));
								TrimString(ac_psrule_key);

								log(LOG_DEBUG, "Searching key [%s]", ac_psrule_key);

								if ((psrule_mem_rec = avlFindLpm(psrules_list, ac_psrule_key)))
								{
									if ((valid_psrule = seekPreSteeringRule(psrule_mem_rec)))
									{
										if (isImsiInWhiteList(map_buffer.op_code, ac_imsi, (valid_psrule->imsi_white_list_enabled == 0x31)?1:0))
										{
											valid_psrule = NULL;
											log(LOG_INFO, "%s|%s|%d|%s|%s|rule bypassed (imsi white list)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt);
										}
										else
										{
											map_buffer.ResultType = 1;
											map_buffer.MAPErrorCode = valid_psrule->map_reject_code;
											log(LOG_INFO, "%s|%s|%d|%s|%s|rule found (errcode %d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, map_buffer.MAPErrorCode);
										}
									}
								}
							}
							else
							{
								if (s_block_unknown_gt)
								{
									map_buffer.ResultType = 1;
									map_buffer.MAPErrorCode = (char)s_block_unknown_gt;
								}
								log(LOG_WARNING, "%s|%s|%d|%s|%s|operator not found (%d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, map_buffer.MAPErrorCode);
							}
						}
						else
						{
							log(LOG_WARNING, "%s|%s|%d|%s|%s|mgt not found", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt);
						}
					}
					else
					{
						log(LOG_WARNING, "%s|%s|%d|%s|%s|rcv unexpected op code (%d) from MAP inbound", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, map_buffer.op_code);
					}

					// MAP reply
					if (map_buffer.ResultType)
					{
						if ((ret = MAP_ReplyOut(&map_buffer)))
						{
							log(LOG_ERROR, "%s|%s|%d|%s|%s|failed to send resp to MAP outbound (%d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, ret);
						}
						else
						{
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RESP);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|denied (code %d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, map_buffer.MAPErrorCode);
						}
					}
					else
					{
						if ((ret = MAP_ForwardToSteering(&map_buffer)))
						{
							log(LOG_ERROR, "%s|%s|%d|%s|%s|failed to forward to Steering (%d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, ret);

							// Relay to MAP outbound if error on forward to Manager
							if ((ret = MAP_ReplyOut(&map_buffer)))
							{
								log(LOG_ERROR, "%s|%s|%d|%s|%s|failed to send resp to MAP outbound (%d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, ret);
							}
							else
							{
								AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RESP);
								log(LOG_WARNING, "%s|%s|%d|%s|%s|relayed", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt);
							}
						}
						else
						{
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_FORW);
							log(LOG_WARNING, "%s|%s|%d|%s|%s|forwarded", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt);
						}
					}
				}
				else if (i_tfs_tag == TFS_LTE)
				{
					memcpy((char *)&lte_buffer, ReceiveIO.data, sizeof(lte_buffer));
					valid_psrule = NULL;

					// IMSI
					memset(ac_imsi, 0x00, sizeof(ac_imsi));
					memcpy(ac_imsi, lte_buffer.imsi.value, lte_buffer.imsi.length);

					log(LOG_INFO, "Recv msg from PLMN [LTE_%s] for IMSI [%s]", lte_buffer.ac_visited_PLMN_Id, ac_imsi);

					// Check country and operator
					psoper_mem_rec = avlFind(lte_oper_list, lte_buffer.ac_visited_PLMN_Id);
					if (psoper_mem_rec != AVLNULL)
					{
						// Operator found
						memset(ac_paese, 0, sizeof(ac_paese));
						memcpy(ac_paese, psoper_mem_rec->paese, sizeof(psoper_mem_rec->paese));
						TrimString(ac_paese);
						memset(ac_operatore, 0, sizeof(ac_operatore));
						memcpy(ac_operatore, psoper_mem_rec->cod_op, sizeof(psoper_mem_rec->cod_op));
						TrimString(ac_operatore);
						sprintf(ac_ut_cc_op, "-|%s|%s", ac_paese, ac_operatore);

						// ARP/LBO check
						if (ac_arp_lbo_mbe_path[0])
						{
							sprintf(ac_paese_ue, ";%s;", ac_paese);
							if (mapProxyRequired(strstr(ac_ue_country_list, ac_paese_ue)?1:0, lte_buffer.i_op, ac_imsi, NULL, NULL, &(lte_buffer.eu_flag), ac_ret_msg))
								log(LOG_ERROR, "LTE_%s|%s|%d|%s|%s", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, ac_ret_msg);
							else
								log(LOG_INFO, "LTE_%s|%s|%d|%s|%s", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, ac_ret_msg);
						}
					}
					else
					{
						// Unknown operator
						strcpy(ac_operatore, "-");
						strcpy(ac_ut_cc_op, "-|-|-");
					}

					// Stats
					AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RECV);

					if (strcmp(ac_operatore, "-"))
					{
						// Search pre-steering rule
						memset(ac_psrule_key, 0x20, sizeof(ac_psrule_key));
						ac_psrule_key[sizeof(ac_psrule_key)-1] = 0x00;
						//memcpy(ac_psrule_key, ac_impianto_mgt, strlen(ac_impianto_mgt));
						memcpy(ac_psrule_key, LTE_HSS_KEY, 16);
						memcpy(ac_psrule_key+16, (char *)psoper_mem_rec, 18);
						//memcpy(ac_psrule_key+34, ac_gt, strlen(ac_gt));
						TrimString(ac_psrule_key);

						log(LOG_DEBUG, "Searching key [%s]", ac_psrule_key);

						if ((psrule_mem_rec = avlFind(psrules_list, ac_psrule_key)))
						{
							if ((valid_psrule = seekPreSteeringRule(psrule_mem_rec)))
							{
								if (isImsiInWhiteList(ULR_CMD, ac_imsi, (valid_psrule->imsi_white_list_enabled == 0x31)?1:0))
								{
									valid_psrule = NULL;
									log(LOG_INFO, "LTE_%s|%s|%d|%s|rule bypassed (imsi white list)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi);
								}
								else
								{
									lte_buffer.ResultType = 1;
									lte_buffer.ResultCode = valid_psrule->lte_reject_code;
									log(LOG_INFO, "LTE_%s|%s|%d|%s|rule found", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi);
								}
							}
						}
					}
					else
					{
						if (s_block_unknown_mccmnc)
						{
							lte_buffer.ResultType = 1;
							lte_buffer.ResultCode = s_block_unknown_mccmnc;
						}
						log(LOG_WARNING, "LTE_%s|%s|%d|%s|operator not found (%d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, lte_buffer.ResultCode);
					}

					// LTE reply
					if (lte_buffer.ResultType)
					{
						if ((ret = LTE_ReplyOut(&lte_buffer)))
						{
							log(LOG_ERROR, "LTE_%s|%s|%d|%s|failed to send resp to LTE outbound (%d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, ret);
						}
						else
						{
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RESP);
							log(LOG_WARNING, "LTE_%s|%s|%d|%s|denied (code %d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, lte_buffer.ResultCode);
						}
					}
					else
					{
						if ((ret = LTE_ForwardToSteering(&lte_buffer)))
						{
							log(LOG_ERROR, "LTE_%s|%s|%d|%s|failed to forward to Steering (%d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, ret);

							// Relay to LTE outbound if error on forward to Manager
							if ((ret = LTE_ReplyOut(&lte_buffer)))
							{
								log(LOG_ERROR, "LTE_%s|%s|%d|%s|failed to send resp to LTE outbound (%d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, ret);
							}
							else
							{
								AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_RESP);
								log(LOG_WARNING, "LTE_%s|%s|%d|%s|relayed", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi);
							}
						}
						else
						{
							AddStat(ac_ut_cc_op, ac_my_process_name, STAT_PS_FORW);
							log(LOG_WARNING, "LTE_%s|%s|%d|%s|forwarded", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi);
						}
					}
				}
				else
				{
					log(LOG_WARNING, "rcv unexpected tag %d", i_tfs_tag);
				}

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
										log(LOG_WARNING, "Statistics - error code %d", i_stat_bump_retry_interval);
										log_flush(LOG_FLUSH_NOW);
										SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
										break;
									}
									case 1:
									{
										log(LOG_WARNING, "Statistics - saved");

										if (checkIniFile())
										{
											Process_Initialization(1);
										}
										else
										{
											log(LOG_WARNING, "Parameters - reload skipped");
										}

										SIGNALTIMEOUT_(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT);
										break;
									}
									default:
									{
										log(LOG_ERROR, "Statistics - postponed (%d)", i_stat_bump_retry_interval);
										log_flush(LOG_FLUSH_NOW);
										SIGNALTIMEOUT_(i_stat_bump_retry_interval, 0, TAG_BUMP_STAT);
										break;
									}
								}
								break;
							}
							case TAG_LOAD_RULES:
							{
								if (isRuleListChanged())
								{
									Stop = loadMgtList();
									if (!Stop) Stop = MAP_LoadOperatorList();
									if (!Stop) Stop = LTE_LoadOperatorList();
									if (!Stop) Stop = loadRuleList();
									if (!Stop && ac_arp_lbo_mbe_path[0]) Stop = loadUEList();
								}

								SIGNALTIMEOUT_(i_load_rules_interval, 0, TAG_LOAD_RULES);
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
							log(LOG_INFO, "System STOP message!!!");
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
	log(LOG_ERROR, "Process stopped");
	log_close();
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
			s_filter_task_id = (short)atoi(ac_wrk_str);
		else if ((wrk_str = getenv("CSS-MM-TASKID")) != NULL)
		{
			s_filter_task_id = (short)atoi(wrk_str);
		}
		else
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}

		get_profile_string(pc_ini_file, INI_SECTION_NAME, "SERVER-CLASS", &found, ac_wrk_str);
		if (found == SSP_TRUE)
			s_filter_server_class = (short)atoi(ac_wrk_str);
		else if ((wrk_str = getenv("CSS-MM-SVRCLASS")) != NULL)
		{
			s_filter_server_class = (short)atoi(wrk_str);
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
		i_my_node_id = L_CINITIALIZE(s_filter_task_id, s_filter_server_class,, &bpid,,(short *)mm, c_node_id);
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

	get_profile_string(pc_ini_file, "EMS", "EMS-TIME-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_ems_time_interval = (long long)atoi(ac_wrk_str) * 1000000;
	else ll_ems_time_interval = 60000000;

	/* --- GENERIC --------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-COUNTRIES-PATH", &found, ac_paesi_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-COUNTRIES-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-COUNTRIES-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
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
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-PSRULES-PATH", &found, ac_psrules_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-PSRULES-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-PSRULES-PATH");
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
/*
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-LTE-MBE-PATH", &found, ac_imsi_lte_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
*/
		ac_arp_lbo_mbe_path[0] = 0x00;
		get_profile_string(pc_ini_file, "GENERIC", "BLBO-ARP-MBE-PATH", &found, ac_arp_lbo_mbe_path);
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

	c_lbo_prv_only = 0;
	get_profile_string(pc_ini_file, "GENERIC", "BLBO-PRV-ONLY", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		c_lbo_prv_only = (short)atoi(ac_wrk_str);
	}

	i_mbe_timeout = 200;
	get_profile_string(pc_ini_file, "GENERIC", "MBE-NOWAIT-TIMEOUT", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		i_mbe_timeout = (int)(atoi(ac_wrk_str) * 100);
		MbeSetAwiatioxTimeout(i_mbe_timeout);
	}

	get_profile_string(pc_ini_file, "GENERIC", "APPLYPS", &found, ac_apply_ps_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> APPLYPS");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> APPLYPS");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	/* --- GTT ------------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "GTT", "MGT", &found, ac_mgt_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GTT -> MGT");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GTT -> MGT");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		s_mgt_by_range = 0;
		get_profile_string(pc_ini_file, "GTT", "MGT-BY-RANGE", &found, ac_wrk_str);
		if (found == SSP_TRUE) s_mgt_by_range = (short)atoi(ac_wrk_str);
	}

	/* --- FILTER ---------------------------------------------------------- */
	i_load_rules_interval = 30000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOAD-RULES-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_load_rules_interval = (int)(atoi(ac_wrk_str) * 100);
	i_load_rules_cpu_shift = 3000;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOAD-RULES-CPU-SHIFT", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_load_rules_cpu_shift = (int)(atoi(ac_wrk_str) * 100);

	get_profile_string(pc_ini_file, "MANAGER", "TASK-ID", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_steering_task_id = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "STEERING-TASK-ID", &found, ac_wrk_str);
		if (found == SSP_TRUE) s_steering_task_id = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter MANAGER -> TASK-ID");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter MANAGER -> TASK-ID");
			DELAY(EXIT_DELAY);
			exit (0);
		}
	}

	get_profile_string(pc_ini_file, "MANAGER", "SERVER-CLASS", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_steering_server_class = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, INI_SECTION_NAME, "STEERING-SERVER-CLASS", &found, ac_wrk_str);
		if (found == SSP_TRUE) s_steering_server_class = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter MANAGER -> SERVER-CLASS");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter MANAGER -> SERVER-CLASS");
			DELAY(EXIT_DELAY);
			exit (0);
		}
	}

	get_profile_string(pc_ini_file, "GTT", "IMSI-PREFIX-LEN", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_imsi_prefix_len = (short)atoi(ac_wrk_str);
	else s_imsi_prefix_len = 0;

	ac_imsi_prefix_mgt[0] = 0x00;
	get_profile_string(pc_ini_file, "GTT", "IMSI-PREFIX-MGT", &found, ac_imsi_prefix_mgt);

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

	if (!reload)
	{
		Print_Process_Parameters();
	}
	else
	{
		log(LOG_WARNING, "Parameters reloaded");
	}
}

void Print_Process_Parameters()
{
	log(LOG_ERROR, "#==============================================================================");
	log(LOG_ERROR, "# INIFILE: %s", ac_path_file_ini_oss);
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

	log(LOG_ERROR, "[STAT]");
	log(LOG_ERROR, "\tSTAT-BUMP-INTERVAL ........: %d", i_stat_bump_interval/100);
	log(LOG_ERROR, "\tSTAT-PATH .................: %s", ac_path_stat_file);
	log(LOG_ERROR, "\tSTAT-PREFIX ...............: %s", ac_stat_prefix);
	log(LOG_ERROR, "\tSTAT-GROUP ................: %d", i_stat_group);
	log(LOG_ERROR, "\tMAX-REGS ..................: %d", i_stat_max_registers);
	log(LOG_ERROR, "\tMAX-COUNTS ................: %d", i_stat_max_counters);

	log(LOG_ERROR, "[GENERIC]");
	log(LOG_ERROR, "\tBLOCK-UNKNOWN-GT ..........: %d", s_block_unknown_gt);
	log(LOG_ERROR, "\tBLOCK-UNKNOWN-MCCMNC ......: %d", s_block_unknown_mccmnc);
	log(LOG_ERROR, "\tDB-LOC-COUNTRIES-PATH .....: %s", ac_paesi_mbe_path);
	log(LOG_ERROR, "\tDB-LOC-OPER-PATH ..........: %s", ac_oper_path);
	log(LOG_ERROR, "\tDB-LOC-OPERGT-PATH ........: %s", ac_opergt_path);
	log(LOG_ERROR, "\tDB-LOC-PSRULES-PATH .......: %s", ac_psrules_path);
	log(LOG_ERROR, "\tIMSI-GSM-MBE-PATH .........: %s", ac_imsi_gsm_mbe_path);
	log(LOG_ERROR, "\tIMSI-DAT-MBE-PATH .........: %s", ac_imsi_dat_mbe_path);
	log(LOG_ERROR, "\tBLBO-ARP-MBE-PATH .........: %s", ac_arp_lbo_mbe_path);
	log(LOG_ERROR, "\tBLBO-PRV-ONLY .............: %d", c_lbo_prv_only);
	log(LOG_ERROR, "\tAPPLYPS ...................: %s", ac_apply_ps_path);
	log(LOG_ERROR, "\tMBE-NOWAIT-TIMEOUT ........: %d", i_mbe_timeout/100);

	log(LOG_ERROR, "[INS]");
	log(LOG_ERROR, "\tNODEID ....................: %c", c_node_id);

	log(LOG_ERROR, "[%s]", INI_SECTION_NAME);
	log(LOG_ERROR, "\tLOAD-RULES-INTERVAL .......: %d", i_load_rules_interval/100);
	log(LOG_ERROR, "\tLOAD-RULES-CPU-SHIFT ......: %d", i_load_rules_cpu_shift/100);
	log(LOG_ERROR, "\tTASK-ID ...................: %d", s_filter_task_id);
	log(LOG_ERROR, "\tSERVER-CLASS ..............: %d", s_filter_server_class);

	log(LOG_ERROR, "[GTT]");
	log(LOG_ERROR, "\tMGT .......................: %s", ac_mgt_path);
	log(LOG_ERROR, "\tMGT-BY-RANGE ..............: %d", s_mgt_by_range);
	log(LOG_ERROR, "\tIMSI-PREFIX-LEN ...........: %d", s_imsi_prefix_len);
	log(LOG_ERROR, "\tIMSI-PREFIX-MGT ...........: %s", ac_imsi_prefix_mgt);

	log(LOG_ERROR, "[MANAGER]");
	log(LOG_ERROR, "\tTASK-ID ...................: %d", s_steering_task_id);
	log(LOG_ERROR, "\tSERVER-CLASS ..............: %d", s_steering_server_class);
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
//  memset(ReceiveIO->data, ' ', sizeof(ReceiveIO->data));
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
		log(LOG_WARNING, "opened %s - id %d", filename, *fileid);
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

short isImsiInWhiteList(short type, char *imsi, char bypass_enabled)
{
	short	ret = 0;
	short	err;
	short	*p_imsi_mbe_id;
	char	*p_imsi_mbe_path;
	char	ac_rev_imsi[17];

	t_ts_imsi_record	imsi_rec;

	memset(ac_rev_imsi, 0x20, sizeof(ac_rev_imsi));
	strcpy(ac_rev_imsi+(sizeof(ac_rev_imsi)-(strlen(imsi)+1)), imsi);
	StringReverse(ac_rev_imsi);

	// Check type and set appropriate IMSIdb
	if (type == UL_OP_CODE)
	{
		p_imsi_mbe_id = &s_imsi_gsm_mbe_id;
		p_imsi_mbe_path = ac_imsi_gsm_mbe_path;
	}
	else if (type == UL_OP_CODE_GPRS)
	{
		p_imsi_mbe_id = &s_imsi_dat_mbe_id;
		p_imsi_mbe_path = ac_imsi_dat_mbe_path;
	}
	else if (type == ULR_CMD)
	{
		p_imsi_mbe_id = &s_imsi_dat_mbe_id;
		p_imsi_mbe_path = ac_imsi_dat_mbe_path;
	}
	else
	{
		log(LOG_DEBUG, "invalid LU type, unable to check imsi white list");
		return(0);
	}

	// Look for IMSI
	if (!(err = MBE_FILE_SETKEY_(*p_imsi_mbe_id, ac_rev_imsi, (short)strlen(ac_rev_imsi), 0, 2)))
	{
		// 23.08.05 - MM : modifica da readlock a read
		//if (!(err = MBE_READX(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec))))
		if (!(err = MbeFileRead_nw(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(t_ts_imsi_record))))
		{
			if (bypass_enabled && (imsi_rec.status == IMSI_STATUS_GRANT_ALWAYS))
				ret = 1;
			else
			{
				// Update imsi for registration time
				if (imsi_rec.init_ts_op == 0)
				{
					imsi_rec.status = IMSI_STATUS_STEERING;
					imsi_rec.init_ts_op = JULIANTIMESTAMP();

					MbeLockRec_nw(*p_imsi_mbe_id);
					err = MbeFileWriteUU_nw(*p_imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec));
					if (err)
					{
						log(LOG_DEBUG, "%s|error [%d] updating imsi on %s", imsi, err, p_imsi_mbe_path);
						MbeUnlockRec_nw(*p_imsi_mbe_id);
						if (err!=1 && err!=11)
							mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
					}
				}
			}
		}
		else
		{
			log(LOG_DEBUG, "%s|error [%d] reading imsi on %s", ac_imsi, err, p_imsi_mbe_path);

			if (err!=1 && err!=11)
				mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
		}
	}
	else
	{
		log(LOG_ERROR, "%s|error [%d] seeking imsi on %s", imsi, err, p_imsi_mbe_path);
		mbeFileOpen(p_imsi_mbe_path, p_imsi_mbe_id);
	}

	return(ret);
}

short isRuleListChanged()
{
	static long long	ll_rule_list_last_load = 0;

	short		ret = 1;
	short		err;
	char		key[100];
	long long	ll_recordts;

	t_ts_psrule_record		psrule_rec;

	memset(key, '*', 79);
	if (!(err = MBE_FILE_SETKEY_(s_psrules_id, key, 79, 0, 2)))
	{
		//if (!(err = MBE_READX(s_psrules_id, (char *)&psrule_rec, sizeof(psrule_rec))))
		if (!(err = MbeFileRead_nw(s_psrules_id, (char *)&psrule_rec, sizeof(psrule_rec))))
		{
			// Any change happened ?
			//memcpy( (char *)&ll_recordts, (char *)&(psrule_rec.filler), sizeof(long long) );
			ll_recordts = psrule_rec.ts1;

			if (ll_rule_list_last_load == 0 || ((ll_recordts > ll_rule_list_last_load) && (ll_recordts < JULIANTIMESTAMP())))
			{
				ll_rule_list_last_load = ll_recordts;
			}
			else
			{
				ret = 0;
				log(LOG_WARNING, "Loading rules skipped - no change");
			}
		}
		else
		{
			log(LOG_WARNING, "error [%d] reading ts record in %s", err, ac_psrules_path);
			if (err!=1 && err!=11)
				mbeFileOpen(ac_psrules_path, &s_psrules_id);
		}
	}
	else
	{
		log(LOG_WARNING, "error [%d] seeking ts record in %s", err, ac_psrules_path);
		mbeFileOpen(ac_psrules_path, &s_psrules_id);
	}

	return ret;
}

void freeOperatorData(void *data)
{
	t_ts_psoper_mem_record *psoper_mem_rec = (t_ts_psoper_mem_record *)data;

	psoper_mem_rec->ptr_count--;
	if (psoper_mem_rec->ptr_count <= 0)
		free(psoper_mem_rec);
}

void freeRuleData(void *data)
{
	t_ts_psrule_mem_record *psrule_mem_rec = (t_ts_psrule_mem_record *)data;

	if (psrule_mem_rec)
	{
		if (psrule_mem_rec->next)
		{
			freeRuleData(psrule_mem_rec->next);
		}
		psrule_mem_rec->ptr_count--;
		if (psrule_mem_rec->ptr_count <= 0)
			free(psrule_mem_rec);
	}
}

short loadMgtList()
{
	short		ret = 0;
	short		err;
	char		key[20];
	char		*data;

	short		s_mgt_id = 0;
	short		mgt_count = 0;

	du_mgt_rec_def	mgt_rec;
	du_mgtr_rec_def	mgtr_rec;

	log(LOG_INFO, "Loading mgt...");
	ret = mbeFileOpen(ac_mgt_path, &s_mgt_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_mgt_id, "", 0, 0, 0)))
		{
			avlCloseWithFunction(mgt_list, &free);
			mgt_list = avlMake();
			if (!mgt_list)
			{
				log(LOG_ERROR, "failed to allocate MGT list");
				return(1);
			}

			if (s_mgt_by_range)
			{
				//while (!(err = MBE_READX(s_mgt_id, (char *)&mgtr_rec, sizeof(mgtr_rec))))
				while (!(err = MbeFileRead_nw(s_mgt_id, (char *)&mgtr_rec, sizeof(mgtr_rec))))
				{
					mgt_count++;

					memset(key, 0x00, sizeof(key));
					memcpy(key, mgtr_rec.mgt_ini, 16);
					TrimString(key);

					data = (char *)calloc(17, 1);
					if (!data)
					{
						log(LOG_ERROR, "memory allocation failed for mgt [%.16s]", mgtr_rec.mgt_ini);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading mgt list");
					}
					else
					{
						memcpy(data, mgtr_rec.mgt_end, 16);
						TrimString(data);
						if (avlAdd(mgt_list, key, data) == -1)
						{
							log(LOG_WARNING, "already existing mgt [%s]", key);
							free(data);
						}

					}
				}
			}
			else
			{
				//while (!(err = MBE_READX(s_mgt_id, (char *)&mgt_rec, sizeof(mgt_rec))))
				while (!(err = MbeFileRead_nw(s_mgt_id, (char *)&mgt_rec, sizeof(mgt_rec))))
				{
					mgt_count++;

					memset(key, 0x00, sizeof(key));
					memcpy(key, (char *)&mgt_rec, 16);
					TrimString(key);

					data = (char *)calloc(strlen(key)+1, 1);
					if (!data)
					{
						log(LOG_ERROR, "memory allocation failed for mgt [%.16s]", mgt_rec.mgt);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "Error NOMEM loading mgt list");
					}
					else
					{
						memcpy(data, key, strlen(key));
						if (avlAdd(mgt_list, key, data) == -1)
						{
							log(LOG_WARNING, "already existing mgt [%s]", key);
							free(data);
						}

					}
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_psrules_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_psrules_path);
		}
	}

	if (ret)
		log(LOG_ERROR, "Loading mgt failed");
	else
		log(LOG_WARNING, "Loading mgt completed (%d)", mgt_count);

	MBE_FILE_CLOSE_(s_mgt_id);

	return ret;
}

char *findMgtByRange(char *mgt)
{
	char	*mgt_ini;
	char	*mgt_end;

	mgt_ini = avlFirstKey(mgt_list);
	while (mgt_ini)
	{
		if (strcmp(mgt, mgt_ini) >= 0)
		{
			mgt_end = avlFind(mgt_list, mgt_ini);

			if (strcmp(mgt, mgt_end) <= 0)
				return(mgt_ini);
		}

		mgt_ini = avlNextKey(mgt_list);
	}

	return AVLNULL;
}

short MAP_LoadOperatorList()
{
	short		ret = 0;
	short		err, err2;
	short		i;
	char		gt[30];
	char		*gt_ptr;

	short		s_oper_id = 0;
	short		s_opergt_id = 0;
	short		oper_count = 0;
	short		oper_gt_count = 0;
	short		total_gt_count = 0;

	t_ts_psoper_mem_record	*psoper_mem_rec;
	t_ts_oper_record		oper_rec;
	t_ts_opergt_record		opergt_rec;

	log(LOG_INFO, "Loading MAP operators...");
	ret = mbeFileOpen(ac_oper_path, &s_oper_id);
	if (!ret) ret = mbeFileOpen(ac_opergt_path, &s_opergt_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_oper_id, "", 0, 0, 0)))
		{
			avlCloseWithFunction(gt_oper_list, &freeOperatorData);
			gt_oper_list = avlMake();
			if (!gt_oper_list)
			{
				log(LOG_ERROR, "failed to allocate MAP operator list");
				return(1);
			}

			//while (!(err = MBE_READX(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			while (!(err = MbeFileRead_nw(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			{
				if (oper_rec.paese[0] != '*')
				{
					oper_count++;
					oper_gt_count = 0;

					psoper_mem_rec = (t_ts_psoper_mem_record *)calloc(sizeof(t_ts_psoper_mem_record), 1);
					if (psoper_mem_rec == NULL)
					{
						log(LOG_ERROR, "memory allocation failed for operator [%.8s%.10s]", oper_rec.paese, oper_rec.cod_op);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading operator list");
					}
					else
					{
						memcpy(psoper_mem_rec->paese, oper_rec.paese, 8);
						memcpy(psoper_mem_rec->cod_op, oper_rec.cod_op, 10);

						if (!(err2 = MBE_FILE_SETKEY_(s_opergt_id, (char *)&oper_rec, 18, 1, 1)))
						{
							//while (!(err2 = MBE_READX(s_opergt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							while (!(err2 = MbeFileRead_nw(s_opergt_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							{
								memset(gt, 0x00, sizeof(gt));
								gt_ptr = gt;
								for (i=0; i<sizeof(opergt_rec.gt); i++)
								{
									if (opergt_rec.gt[i] != ' ')
									{
										*gt_ptr = opergt_rec.gt[i];
										gt_ptr++;
									}
								}
								TrimString(gt);

								if (avlAdd(gt_oper_list, gt, psoper_mem_rec) == -1)
								{
									log(LOG_WARNING, "already existing gt [%s]", gt);
								}
								else
								{
									psoper_mem_rec->ptr_count++;
									oper_gt_count++;
									total_gt_count++;
								}
							}
						}
						else
						{
							log(LOG_ERROR, "error [%d] seeking %s", err2, ac_opergt_path);
							log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err2, ac_opergt_path);
						}

						if (!oper_gt_count)
							freeOperatorData(psoper_mem_rec);
					}
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_oper_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_oper_path);
		}
	}

	if (ret) log(LOG_ERROR, "Loading MAP operators failed");
	else log(LOG_WARNING, "Loading MAP operators completed (%d operators / %d global titles)", oper_count, total_gt_count);

	MBE_FILE_CLOSE_(s_oper_id);
	MBE_FILE_CLOSE_(s_opergt_id);

	return ret;
}

short LTE_LoadOperatorList()
{
	short		ret = 0;
	short		err;
	char		ac_plmn_code[17];
	char		*p_imsi_op;

	short		s_oper_id = 0;
	short		oper_count = 0;

	t_ts_psoper_mem_record	*psoper_mem_rec;
	t_ts_oper_record		oper_rec;

	log(LOG_INFO, "Loading LTE operators...");
	ret = mbeFileOpen(ac_oper_path, &s_oper_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_oper_id, "", 0, 0, 0)))
		{
			avlCloseWithFunction(lte_oper_list, &freeOperatorData);
			lte_oper_list = avlMake();
			if (!lte_oper_list)
			{
				log(LOG_ERROR, "failed to allocate LTE operator list");
				return(1);
			}

			//while (!(err = MBE_READX(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			while (!(err = MbeFileRead_nw(s_oper_id, (char *)&oper_rec, sizeof(oper_rec))))
			{
				if (oper_rec.paese[0] != '*')
				{
					oper_count++;

					psoper_mem_rec = (t_ts_psoper_mem_record *)calloc(sizeof(t_ts_psoper_mem_record), 1);
					if (psoper_mem_rec == NULL)
					{
						log(LOG_ERROR, "memory allocation failed for operator [%.8s%.10s]", oper_rec.paese, oper_rec.cod_op);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading operator list");
					}
					else
					{
						memset(ac_plmn_code, 0x00, sizeof(ac_plmn_code));
						memcpy(ac_plmn_code, oper_rec.imsi_op, sizeof(oper_rec.imsi_op));
						TrimString(ac_plmn_code);
						memcpy(psoper_mem_rec->paese, oper_rec.paese, 8);
						memcpy(psoper_mem_rec->cod_op, oper_rec.cod_op, 10);

						p_imsi_op = strtok(ac_plmn_code, ",;:|");
						while (p_imsi_op)
						{
							if (avlAdd(lte_oper_list, p_imsi_op, psoper_mem_rec) == -1)
							{
								log(LOG_WARNING, "already existing plmn code [%s] for [%.18s]", p_imsi_op, oper_rec.paese);
								freeOperatorData(psoper_mem_rec);
							}
							else
							{
								psoper_mem_rec->ptr_count++;
							}

							p_imsi_op = strtok((char *)NULL, ",;:|");
						}
					}
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_oper_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_oper_path);
		}
	}

	if (ret) log(LOG_ERROR, "Loading LTE operators failed");
	else log(LOG_WARNING, "Loading LTE operators completed (%d operators)", oper_count);

	MBE_FILE_CLOSE_(s_oper_id);

	return ret;
}

short loadRuleList()
{
	short		ret = 0;
	short		err;
	short		i;
	char		key[100];
	char		lte_key[35];

	short		s_mgt_id = 0;
	short		rules_count = 0;
	char		c_rule_prepend;
	char		*gt_ptr;

	t_ts_psrule_record		psrule_rec;
	du_mgt_rec_def			mgt_rec;
	du_mgtr_rec_def			mgtr_rec;

	t_ts_psrule_mem_record	*psrule_mem_rec;
	t_ts_psrule_mem_record	*existing_psrule;
	t_ts_psrule_mem_record	*existing_psrule_next;

	FILE	*handle_apply_ps;
	char	ac_apply_ps_date[20];

	log(LOG_INFO, "Loading rules...");
	ret = mbeFileOpen(ac_mgt_path, &s_mgt_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_psrules_id, "", 0, 0, 0)))
		{
			avlCloseWithFunction(psrules_list, &freeRuleData);
			psrules_list = avlMake();
			if (!psrules_list)
			{
				log(LOG_ERROR, "failed to allocate PS rule list");
				return(1);
			}

			//while (!(err = MBE_READX(s_psrules_id, (char *)&psrule_rec, sizeof(psrule_rec))))
			while (!(err = MbeFileRead_nw(s_psrules_id, (char *)&psrule_rec, sizeof(psrule_rec))))
			{
				if ((psrule_rec.mgt[0] != '*') && (psrule_rec.stato == 0x31))
				{
					rules_count++;

					memset(key, 0x00, sizeof(key));
					memcpy(key, (char *)&psrule_rec, 38);

					gt_ptr = key+38;
					for (i=0; i<sizeof(psrule_rec.gt); i++)
					{
						if (psrule_rec.gt[i] != ' ')
						{
							*gt_ptr = psrule_rec.gt[i];
							gt_ptr++;
						}
					}
					TrimString(key+4);

					psrule_mem_rec = (t_ts_psrule_mem_record *)calloc(sizeof(t_ts_psrule_mem_record), 1);
					if (!psrule_mem_rec)
					{
						log(LOG_ERROR, "memory allocation failed for rule [%.16s%.8s%.10s%.24s]", psrule_rec.mgt, psrule_rec.paese, psrule_rec.cod_op, psrule_rec.gt);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_OPER_LOADING, "error NOMEM loading rules list");
					}
					else
					{
						c_rule_prepend = 0;
						memcpy(psrule_mem_rec->fascia_da, psrule_rec.fascia_da, 17);
						psrule_mem_rec->map_reject_code = (char)psrule_rec.map_reject_code;
						psrule_mem_rec->lte_reject_code = psrule_rec.lte_reject_code;
						psrule_mem_rec->imsi_white_list_enabled = psrule_rec.imsi_white_list_enabled;
						psrule_mem_rec->next = NULL;

						if (!memcmp(key, "----", 4))
						{
							// LTE only
							err = 1;
						}
						else if (!memcmp(key, "    ", 4))
						{
							// HLR undefined --> load all MGTs
							err = MBE_FILE_SETKEY_(s_mgt_id, "", 0, 0, 0);
						}
						else
						{
							if (memcmp(key+4, "                ", 16))
							{
								// HLR defined --> load specific MGT
								err = MBE_FILE_SETKEY_(s_mgt_id, key+4, 16, 0, 2);
								c_rule_prepend = 1;
							}
							else
							{
								// HLR defined --> load all belonging MGTs
								err = MBE_FILE_SETKEY_(s_mgt_id, key, 4, 1, 1);
							}
						}

						// Load rule for LTE if LTE error code defined
						if (psrule_rec.lte_reject_code)
						{
							memset(lte_key, 0x00, sizeof(lte_key));
							memcpy(lte_key, LTE_HSS_KEY, 16);
							memcpy(lte_key+16, psrule_rec.paese, 18);
							TrimString(lte_key);
							log(LOG_DEBUG, "[%d]: loading key [%s]", rules_count, lte_key);

							if (avlAdd(psrules_list, lte_key, psrule_mem_rec) == -1)
							{
								log(LOG_WARNING, "already existing rule [%s]", lte_key);
								//free(psrule_mem_rec);
							}
							else
								psrule_mem_rec->ptr_count++;
						}

						// Load rule for GSM/GPRS if MAP error code defined
						if (!err && psrule_rec.map_reject_code)
						{
							if (s_mgt_by_range)
							{
								//while (!(err = MBE_READX(s_mgt_id, (char *)&mgtr_rec, sizeof(mgtr_rec))))
								while (!(err = MbeFileRead_nw(s_mgt_id, (char *)&mgtr_rec, sizeof(mgtr_rec))))
								{
									memcpy(key+4, mgtr_rec.mgt_ini, 16);

									if ((existing_psrule = avlFind(psrules_list, key+4)))
									{
										if (c_rule_prepend)
										{
											log(LOG_DEBUG, "[%d]: prepend key [%s]", rules_count, key+4);
											psrule_mem_rec->next = existing_psrule;
											avlUpdateData(psrules_list, key+4, psrule_mem_rec);
										}
										else
										{
											log(LOG_DEBUG, "[%d]: append  key [%s]", rules_count, key+4);
											if (existing_psrule->next)
											{
												existing_psrule_next = existing_psrule->next;
												while (existing_psrule_next->next)
													existing_psrule_next = existing_psrule_next->next;
												existing_psrule_next->next = psrule_mem_rec;
											}
										}
										psrule_mem_rec->ptr_count++;
									}
									else
									{
										log(LOG_DEBUG, "[%d]: loading key [%s]", rules_count, key+4);

										if (avlAdd(psrules_list, key+4, psrule_mem_rec) == -1)
										{
											log(LOG_WARNING, "already existing rule [%s]", key+4);
											//free(psrule_mem_rec);
										}
										else
											psrule_mem_rec->ptr_count++;
									}
								}
							}
							else
							{
								//while (!(err = MBE_READX(s_mgt_id, (char *)&mgt_rec, sizeof(mgt_rec))))
								while (!(err = MbeFileRead_nw(s_mgt_id, (char *)&mgt_rec, sizeof(mgt_rec))))
								{
									memcpy(key+4, mgt_rec.mgt, 16);

									if ((existing_psrule = avlFind(psrules_list, key+4)))
									{
										if (c_rule_prepend)
										{
											log(LOG_DEBUG, "[%d]: prepend key [%s]", rules_count, key+4);
											psrule_mem_rec->next = existing_psrule;
											avlUpdateData(psrules_list, key+4, psrule_mem_rec);
										}
										else
										{
											log(LOG_DEBUG, "[%d]: append  key [%s]", rules_count, key+4);
											if (existing_psrule->next)
											{
												existing_psrule_next = existing_psrule->next;
												while (existing_psrule_next->next)
													existing_psrule_next = existing_psrule_next->next;
												existing_psrule_next->next = psrule_mem_rec;
											}
										}
										psrule_mem_rec->ptr_count++;
									}
									else
									{
										log(LOG_DEBUG, "[%d]: loading key [%s]", rules_count, key+4);

										if (avlAdd(psrules_list, key+4, psrule_mem_rec) == -1)
										{
											log(LOG_WARNING, "already existing rule [%s]", key+4);
											//free(psrule_mem_rec);
										}
										else
											psrule_mem_rec->ptr_count++;
									}
								}
							}
						}
					}
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_psrules_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_psrules_path);
			mbeFileOpen(ac_psrules_path, &s_psrules_id);
		}
	}

	if (ret) log(LOG_ERROR, "Loading rules failed");
	else
	{
		log(LOG_WARNING, "Loading rules completed (%d)", rules_count);

		// Update reload timestamp (APPLYPS)
		if ((handle_apply_ps = fopen_oss(ac_apply_ps_path, "w")))
		{
			fprintf(handle_apply_ps, "%s\n", ConvertJTS2String(JULIANTIMESTAMP(), ac_apply_ps_date));
			fclose(handle_apply_ps);
		}
		else
		{
			log(LOG_ERROR, "Failed to open %s", ac_apply_ps_path);
		}
	}

	MBE_FILE_CLOSE_(s_mgt_id);

	return ret;
}

short loadUEList()
{
	short		ret = 0;
	short		err;
	char		key[10];
	short		s_paesi_mbe_id = 0;
	short		paesi_count = 0;

	t_ts_paesi_record	paesi_rec;

	log(LOG_INFO, "Loading UE countries...");
	ret = mbeFileOpen(ac_paesi_mbe_path, &s_paesi_mbe_id);

	if (!ret)
	{
		if (!(err = MBE_FILE_SETKEY_(s_paesi_mbe_id, "", 0, 0, 0)))
		{
			memset(ac_ue_country_list, 0x00, sizeof(ac_ue_country_list));
			ac_ue_country_list[0] = ';';
			//while (!(err = MBE_READX(s_paesi_mbe_id, (char *)&paesi_rec, sizeof(paesi_rec))))
			while (!(err = MbeFileRead_nw(s_paesi_mbe_id, (char *)&paesi_rec, sizeof(paesi_rec))))
			{
				if (paesi_rec.eu_flag == 0x31)
				{
					paesi_count++;

					memset(key, 0x00, sizeof(key));
					memcpy(key, paesi_rec.paese, 8);
					TrimString(key);
					sprintf(ac_ue_country_list + strlen(ac_ue_country_list), "%s;", key);
				}
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_paesi_mbe_path);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_paesi_mbe_path);
		}
	}

	if (ret)
		log(LOG_ERROR, "Loading UE countries failed");
	else
		log(LOG_WARNING, "Loading UE countries completed (%d)", paesi_count);

	MBE_FILE_CLOSE_(s_paesi_mbe_id);

	return ret;
}

short isRuleValid(t_ts_psrule_mem_record *rule)
{
	short		ret = 0;
	struct tm	tm_time;
	time_t		now;
	char		fascia[6];

	now = time((time_t *)NULL);
	tm_time = *localtime(&now);
	sprintf(fascia, "%02d:%02d", tm_time.tm_hour, tm_time.tm_min);

	// Check if current day is valid
	if (rule->gg_settimana[tm_time.tm_wday] == 'X')
	{
		// Check if current time is valid
		if (strncmp(fascia, rule->fascia_da, 5) >= 0 &&
			strncmp(fascia, rule->fascia_a, 5) <= 0)
		{
			ret = 1;
		}
	}

	return ret;
}

t_ts_psrule_mem_record *seekPreSteeringRule(t_ts_psrule_mem_record *rule_list)
{
	struct tm	tm_time;
	time_t		now;
	char		fascia[6];

	t_ts_psrule_mem_record	*rule;

	now = time((time_t *)NULL);
	tm_time = *localtime(&now);
	sprintf(fascia, "%02d:%02d", tm_time.tm_hour, tm_time.tm_min);

	rule = rule_list;
	while (rule)
	{
		if (isRuleValid(rule))
		{
			break;
		}
		rule = rule->next;
	}

	return rule;
}

short MAP_ForwardToSteering(t_ts_data *mbuffer)
{
	short	ret;
	static unsigned char	uc_mts_error_open = 0;
	static long long		ll_ems_time_last_mts_jts = 0;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	mts_addr_std.flags.mode = 0;
	mts_addr_std.flags.zero = 0;
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.cpu_req = 0;
	mts_addr_std.to.cpu = 0;
	mts_addr_std.to.task_id = s_steering_task_id;
	mts_addr_std.to.server_class = s_steering_server_class;
	ret = MTS_SEND(&mts_addr_std, mbuffer, sizeof(t_ts_data));
	if (ret)
	{
		uc_mts_error_open = 1;
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with STEERING (%d;%d)", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
	}
	else
	{
		if (uc_mts_error_open)
		{
			uc_mts_error_open = 0;
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with STEERING (%d;%d)", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
		}
	}

	return(ret);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with MAP-OUT (%d;%d)", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with MAP-OUT (%d;%d)", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with MAP-OUT (%s)", ret, ((P2_MTS_PROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with MAP-OUT (%s)", ((P2_MTS_PROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with MAP-OUT (%s)", ret, ((P2_MTS_EPROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with MAP-OUT (%s)", ((P2_MTS_EPROC_ADDR_DEF *)&(mbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		default:
		{
			log(LOG_ERROR, "%s|%s|%d|%s|%s|invalid address type for MAP outbound (%d)", ac_gt, ac_operatore, map_buffer.op_code, ac_imsi, ac_mgt, mbuffer->result_address.choice);
			ret++;
		}
	}

	return ret;
}

short LTE_ForwardToSteering(TFS_LTE_IPC *lbuffer)
{
	short	ret;
	static unsigned char	uc_mts_error_open = 0;
	static long long		ll_ems_time_last_mts_jts = 0;
	P2_MTS_STD_ADDR_DEF		mts_addr_std;

	mts_addr_std.flags.mode = 0;
	mts_addr_std.flags.zero = 0;
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.cpu_req = 0;
	mts_addr_std.to.cpu = 0;
	mts_addr_std.to.task_id = s_steering_task_id;
	mts_addr_std.to.server_class = s_steering_server_class;
	ret = MTS_SEND(&mts_addr_std, lbuffer, sizeof(TFS_LTE_IPC));
	if (ret)
	{
		uc_mts_error_open = 1;
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with STEERING (%d;%d)", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
	}
	else
	{
		if (uc_mts_error_open)
		{
			uc_mts_error_open = 0;
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with STEERING (%d;%d)", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
		}
	}

	return(ret);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with LTE (%d;%d)", ret, mts_addr_std.to.task_id, mts_addr_std.to.server_class);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with LTE (%d;%d)", mts_addr_std.to.task_id, mts_addr_std.to.server_class);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with LTE (%s)", ret, ((P2_MTS_PROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with LTE (%s)", ((P2_MTS_PROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
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
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_mts_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_OPEN, "error [%d] in mts with LTE (%s)", ret, ((P2_MTS_EPROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
			}
			else
			{
				if (uc_mts_error_open)
				{
					uc_mts_error_open = 0;
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MTS_ERROR_CLOSE, "close error in mts with LTE (%s)", ((P2_MTS_EPROC_ADDR_DEF *)&(lbuffer->result_address.address))->procname);
				}
			}
			break;
		}
		default:
		{
			log(LOG_ERROR, "LTE_%s|%s|%d|%s|invalid address type for LTE (%d)", lte_buffer.ac_visited_PLMN_Id, ac_operatore, lte_buffer.i_op, ac_imsi, lbuffer->result_address.choice);
			ret++;
		}
	}

	return ret;
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

short mapProxyRequired(char ue, short lu_type, char *imsi, char *proxy, short *arpId, char *eu_flag, char *err_msg)
{
	static long long ll_ems_time_last_arplbo_jts = 0;
	long long	ll_recordts;
	short		ret = 0;
	short		err;
	ROAMUN_user	user_rec;

	*eu_flag = ue;

	if (lu_type == ULR_CMD)
	{
		// LTE
		sprintf(err_msg, "arp/lbo not applicable for LTE");
	}
	else
	{
		*proxy = 0;
		*arpId = 0;

		if (!ue)
		{
			// Not in UE
			sprintf(err_msg, "arp/lbo not in UE");
		}
		else
		{
			memset((char *)&user_rec, 0x00, sizeof(user_rec));
			strcpy(user_rec.imsi, imsi);
			StringReverse(user_rec.imsi);
			if (!(err = MBE_FILE_SETKEY_(s_arp_lbo_mbe_id, user_rec.imsi, 18, 0, 2)))
			{
				if (!(err = MbeFileRead_nw(s_arp_lbo_mbe_id, (char *)&user_rec, sizeof(user_rec))))
				{
					if (lu_type == UL_OP_CODE)
					{
						ll_recordts = JULIANTIMESTAMP();
						if (ll_recordts >= user_rec.start_date && ll_recordts <= user_rec.end_date)
						{
							if (user_rec.arp_id)
							{
								*proxy = 2;
								*arpId = user_rec.arp_id;
								sprintf(err_msg, "found imsi for arp[%d]", *arpId);
							}
							else
							{
								sprintf(err_msg, "arp id not set");
							}
						}
						else
						{
							sprintf(err_msg, "arp date out of range");
						}
					}
					else if (lu_type == UL_OP_CODE_GPRS)
					{
						if (user_rec.lbo_bl)
							sprintf(err_msg, "found imsi in lbo bl");
						else
						{
							*proxy = 1;
							sprintf(err_msg, "found imsi but not in lbo bl");
						}
					}
					else
					{
						sprintf(err_msg, "arp/lbo unexpected lu_type[%d]", lu_type);
						ret = 1;
					}
				}
				else
				{
					if (err!=1 && err!=11)
					{
						log_evt_t(ll_ems_time_interval, &ll_ems_time_last_arplbo_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_arp_lbo_mbe_path);
						sprintf(err_msg, "error [%d] reading %s", err, ac_arp_lbo_mbe_path);
						ret = 1;
						mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);
					}
					else
					{
						sprintf(err_msg, "arp/lbo imsi not found");
					}

					if (lu_type == UL_OP_CODE_GPRS)
					{
						if (!c_lbo_prv_only)
						{
							*proxy = 1;
						}
					}
				}
			}
			else
			{
				ret = 1;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_arplbo_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_arp_lbo_mbe_path);
				sprintf(err_msg, "error [%d] seeking %s", err, ac_arp_lbo_mbe_path);
				if (lu_type == UL_OP_CODE_GPRS)
				{
					if (!c_lbo_prv_only)
					{
						*proxy = 1;
					}
				}
				mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);
			}
		}

		sprintf(err_msg + strlen(err_msg), "|px[%d]", *proxy);
	}

	return(ret);
}
