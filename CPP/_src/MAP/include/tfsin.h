//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - Inbound Server - v 1.06
//------------------------------------------------------------------------------
//
//   File Name   : tfsin.h
//   Created     : 01-09-2004
//   Last Change : 21-09-2012
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __TFSIN_H
#define __TFSIN_H

//----------------------------------------------------------------------------
// Parameters from environment
//----------------------------------------------------------------------------
short           i_my_cpu;
short           i_stat_group;
short           i_nbr_max_idx;
short           i_stat_max_register;
short           i_taskid_ts;
short           i_serverclass_ts;
short           i_taskid_gtt;
short           i_serverclass_gtt;
short			i_taskid_relay;
short			i_serverclass_relay;
short			i_taskid_mapout;
short			i_serverclass_mapout;
short           i_manage_GPRS_UpLoc;
short           i_auto_allow_vpc;
short           i_nbr_alert_msg;
short           i_interval_time;
short			i_localMaxRegs;
short			i_nSSID_Number;
short			i_stat_fw_param_loaded;
short			i_stat_fw_group;
short			i_maxtimedelay;
short			i_hlr_ssn;
short			i_cg_prefix_owner_tfs_loaded;
short			i_cd_prefix_owner_tfs_loaded;
short			i_cg_lu_gprs_whitelist_loaded;
short			i_internal_routing_strategy;
short			i_dump_msg;
char            ac_stat_prefix[3];
char			ac_cSSID_Version[6];
char			ac_cSSID_Owner[10];
char            ac_my_process_name[10];
char            ac_path_log_file[36];
char            ac_path_stat[36];
char            ac_filecfg[36];
char			ac_cg_prefix_list_owner_tfs[36];
char            ac_cd_prefix_list_owner_tfs[36];
char			ac_cg_lu_gprs_whitelist[36];
char            ac_filecfg_oss[64];
char			ac_log_trace_string[64];
int             i_num_days_of_log;
int             i_trace_level;
long            l_ack_timeout;
long            l_timeout_reload;
long            l_stat_bump_interval;
long            l_timeout_allow_vpc;

#endif
