// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : diam_s6a.h
//   Last Change : 15-12-2016
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#ifndef _DIAMS6A_H
#define _DIAMS6A_H

#include <maputil.h>
#include "s6aipc.h"

#define CHECK_INACTIVITY_TIMEOUT   (2 * 60) // 2'
#define EXIT_DELAY 500

#define MAX_IPC_BUFFER_LEN  	(32000)
#define MAX_DIAM_REQ_BUFF_LEN	(2048)

#define DIA_MTS_BUFFER_SIZE	(8)

#define MIN_IMEI_LEN 15
#define MAX_IMEI_LEN 16

#define TAG_RELOAD_PARAM    	100
#define TAG_BUMP                110

enum _redirect_host_usage_value
{
	DONT_CACHE,
	ALL_SESSION,
	ALL_REALM,
	REAL_AND_APPLICATION,
	ALL_APPLICATION,
	ALL_HOST,
	ALL_USER
};

enum _ula_type
{
	ULA_REDIRECT,
	ULA_STEERING,
	ULA_ERROR
};

//
// Stat
//
#define MAX_TIME_SEC_DELAY_DEFAULT	150 // 1,5 "

//
// load/reload parameters
//
enum _param
{
	LOAD,
    RELOAD
};

//
// STOP/START parameters
//
#define _STOP_ 0
#define _START_ 1

enum _bool_resp
{
	FALSE,
    TRUE
};

#pragma fieldalign shared2 _ulr
typedef struct _ulr
{
	char			c_rat_type;
	char			ac_visited_PLMN_Id[VPLMN_LEN];
	char 			ac_soft_ver[16];
	unsigned int	i_ulr_flags;
	INS_String      imsi;    //AVP User name
	INS_String      imei;
	DiamIdent      	origin_host;
	DiamIdent		origin_realm;
	DiamIdent		destination_realm;
	DiamIdent		ulr_session;
} ULR;

#pragma fieldalign shared2 _tfs_ctx
typedef struct _tfs_ctx
{
	short			diaSessInfoLen;
	short			i_buff_orig_len;
	unsigned int    i_HbyH;
	unsigned int	i_EtoE;
	char  			diaSessionInfo[MAX_DIAMETER_SESSION_INFO];
	char			ac_buff_orig[MAX_DIAM_REQ_BUFF_LEN];
	DiamIdent		ulr_session;
} TFS_CTX;

#pragma fieldalign shared2 io_ctrl_common_blk
typedef struct io_ctrl_common_blk
{
    short in_use;
    char  fname[36];
    short reply_pending;
    short id;
    short error;
    short i_status;
    short idx;
    char  buffer[MAX_IPC_BUFFER_LEN];
} IO_CTRL_COMMON_BLK;

#pragma fieldalign shared2 io_sys_timeout
typedef struct io_sys_timeout
{
    short id;
    short i_par1;
    long  l_par2;
} IO_SYS_TIMEOUT;

#pragma fieldalign shared2 _sys_cmd
typedef struct _sys_cmd
{
    short id;
    short i_op;
    short i_cnt;
    char  ac_cmd[2048];
} SYS_COMMAND;

#define SYS_MSG_TIME_TIMEOUT    -22

#define SYS_MSG_STOP_1          -20
#define SYS_MSG_STOP_2          -105

#define SYS_MSG_COMMAND         -35

//----------------------------------------------------------------------------
// Parameters from environment
//----------------------------------------------------------------------------
short           i_my_tid;
short           i_my_svr_cls;
short           i_node_id;
short           i_my_node_id;
short           i_my_cpu;
short           i_loop_timer;
short           i_bpid;
short           i_stat_group;
short           i_nbr_max_idx;
short           i_stat_max_register;
short           i_mts_cpu_req;
short			i_evt_init_ok;
short			i_nSSID_Number;
short			i_nbr_alert_msg;
short			i_interval_time;
short			i_maxtimedelay;
short			i_tfsmgr_tid;
short			i_tfsmgr_srv;
short			i_tid_tfs_lte;
short			i_srvcl_tfs_lte;
short			i_ctx_protect_class;
short			i_CTX_Timeout;
short			i_max_fqdn_host_entries;
short			i_dbase_present;
short			i_redirect_indication_flag;
int				i_vendor_id;
unsigned int    i_application_id;
char			c_srv_id;
char			c_open_db;
char            ac_stat_prefix[3];
char			ac_log_prefix_name[5];
char            ac_cc[5];
char            ac_cpu[5];
char			ac_cSSID_Version[6];
char            ac_node_name[10];
char			ac_stat_reg_prefix[10];
char			ac_stat_reg_postfix[10];
char			ac_cSSID_Owner[10];
char            ac_my_process_name[10];
char            ac_ancestor_name[10];
char            ac_log_prefix[10];
char            mm[24];
char            ac_path_stat[36];
char            ac_path_log_file[36];
char            ac_filecfg[36];
char            ac_path_imsi_db[36];
char            ac_path_hss_db[36];
char            ac_filecfg_oss[255];
char 			ac_fqdn[255];
char			ac_realm[255];
char			ac_uri[255];
char			ac_product_name[256];
char			ac_fqdn_redirect_host[20][256];
int             i_num_days_of_log;
int             i_trace_level;
long            l_stat_bump_interval;
long			l_Timer_Waiting_tfsmgr_Resp;
long			l_ctx_discarded_timeout;
long			l_ctx_lock;

#endif
