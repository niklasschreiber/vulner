//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - Outbound Server
//------------------------------------------------------------------------------
//
//   File Name   : tfsout.h
//   Created     : 01-09-2004
//   Last Change : 27-03-2018
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __TFSOUT_H
#define __TFSOUT_H

//----------------------------------------------------------------------------
// Parameters from environment
//----------------------------------------------------------------------------
short           i_my_cpu;
short           i_stat_group;
short           i_nbr_max_idx;
short           i_stat_max_register;
short           i_auto_allow_vpc;
short           i_fault_mngt_strategy;
short           i_DPC_list_entries;
short           i_DualImsi_DPC_list_entries;
short           i_originating_pc;
short           i_mgt_test;
short           i_nbr_alert_msg;
short           i_interval_time;
short			i_hlr_ssn;
short			i_nSSID_Number;
short			i_stat_fw_group;
short			i_stat_fw_param_loaded;
short           i_taskid_gtt;
short           i_serverclass_gtt;
short			i_taskid_mapout;
short			i_serverclass_mapout;
short			i_ask_GT_to_GTT_enable;
short			i_maxtimedelay;
short 			i_localMaxRegs;
short			i_cg_prefix_owner_tfs_loaded;
short			i_cd_prefix_owner_tfs_loaded;
short			i_internal_routing_strategy;
short			i_dump_msg;
short			i_romun_enable;
short			i_FAI_set;
short			i_FAI_SSN;
short			i_E164_set;
char            ac_stat_prefix[3];
char			ac_cSSID_Version[6];
char            ac_node_name[7];
char			ac_cSSID_Owner[10];
char            ac_my_process_name[10];
char            ac_ancestor_name[10];
char            ac_log_prefix_name[10];
char            ac_cd_test[33];
char            ac_path_log_file[36];
char            ac_path_stat[36];
char            ac_filecfg[36];
char			ac_cg_prefix_list_owner_tfs[36];
char            ac_cd_prefix_list_owner_tfs[36];
char			ac_path_arp_db[36];
char            ac_filecfg_oss[64];
char			ac_log_trace_string[64];
char            ac_pc_list[255];
int             i_num_days_of_log;
int             i_trace_level;
long            l_ack_timeout;
long            l_timeout_reload;
long            l_stat_bump_interval;
long            l_timeout_allow_vpc;
long            l_point_code_list[50];
long            l_DualImsi_pc_list[50];
long			l_map_pxy_lbo_dpc;

#endif
