//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - Inbound Server - v 1.01
//------------------------------------------------------------------------------
//
//   File Name   : tfsevt.h
//   Created     : 01-09-2004
//   Last Change : 02-05-2014
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//
//------------------------------------------------------------------------------
#ifndef __TFSEVT_H
#define __TFSEVT_H

#include <time.h>

#define E_TFS_ARM_BASE_NUMBER 		1000
#define E_TFS_DISARM_BASE_NUMBER	2000

//------------------------------------------------------------------------------
// common
enum _ems_idx
{
		EVTN_FW_INITIALIZE_KO =  E_TFS_ARM_BASE_NUMBER,      // FW initialize failure
		EVTN_START,										     // TFS MAP I/F started
		EVTN_STOP,                                           // TFS MAP I/F stopped
		EVTN_L_CINITIALIZE_KO,                               // OC-INS initialize failure
		EVTN_PARAM_MISSING,                                  // Missing Parameter or File ini is already opened

		EVTN_STAT_NOT_INIT,                                  // Initialize statistics failure
		EVTN_FILEINI_NOT_FOUND,                              // File INI not found
		EVTN_BUMP_ERROR,                                     // BUMP failure
		EVTN_PROHIBIT_VPC_OK,                                // Virtual Point Code has been prohibited successfully
		EVTN_PROHIBIT_VPC_KO,                                // Virtual Point Code has not been prohibited

		EVTN_ALLOW_VPC_OK,                                   // Virtual Point Code has been allowed successfully
		EVTN_ALLOW_VPC_KO,                                   // Virtual Point Code has not been allowed
		EVTN_TS_ERROR_CODE,                                  // Wrong Error code returned by TS-Manager
		EVTN_GTT_ERROR_CODE,                                 // Wrong Error code returned by GTT server
		EVTN_SENT_RELAY_ERROR,                               // Sending RELAY IPC failure

		EVTN_REQ_TO_GTT_ERROR,                               // Request to GTTS IPC failure
		EVTN_REQ_TO_TS_ERROR,                                // Request to TS-manager IPC failure
		EVTN_FW_OPCODE_UNKNOWN,                              // Unexpected FW Opcode received
		EVTN_TCAP_OPCODE_UNKNOWN,                            // Unexpected TCAP Opcode received
		EVTN_FW_EVENT_UNKNOWN,                               // Unexpected FW Event received

		EVTN_FW_ERROR,                                       // FW Internal Error
		EVTN_REQ_MAP_REJECT_ERROR,                           // TCAP-End Reject requested failure
		EVTN_REQ_USER_ABORT_ERROR,                           // TCAP-End User abort requested failure
		EVTN_REQ_MAP_ERROR,                                  // MAP-ERROR requested
		EVTN_LOAD_CG_PREFIX_LIST_OWNER_TFS_OK,               // Cg prefix list owner TFS loaded successfully

		EVTN_LOAD_CG_PREFIX_LIST_OWNER_TFS_ERROR,            // Cg prefix list owner TFS not loaded
		EVTN_RELOAD_CG_PREFIX_LIST_OWNER_TFS_ERROR,          // Cg prefix list owner TFS not reloaded
		EVTN_LOAD_CD_PREFIX_LIST_OWNER_TFS_OK,               // Cd prefix list owner TFS loaded successfully
		EVTN_LOAD_CD_PREFIX_LIST_OWNER_TFS_ERROR,            // Cd prefix list owner TFS not loaded
		EVTN_RELOAD_CD_PREFIX_LIST_OWNER_TFS_ERROR,          // Cd prefix list owner TFS not reloaded

		EVTN_LOAD_LU_GPRS_WL_OK,                             // LU GPRS whitelist prefix loaded successfully
		EVTN_LOAD_LU_GPRS_WL_ERROR,                          // LU GPRS whitelist prefix not loaded
		EVTN_RELOAD_LU_GPRS_WL_ERROR,                        // LU GPRS whitelist prefix not reloaded
		EVTN_SSN_NOT_HLR,                                    // SSN not HLR number
		EVTN_BAD_ROUTING_INFO,                               // BAD Routing

		EVTN_POINT_CODE_UNAVAILABLE,                         // Point Code unavailable
		EVTN_GTT_ERR_MAP_ERROR2,                             // TCAP error requested by TS, GTT error returned translating called MGT to GT
		EVTN_GTT_ERR_REJECT2,                                // TCAP reject requested by TS, GTT error returned translating called MGT to GT
		EVTN_GTT_ERR_USER_ABORT2,                            // TCAP user abort requested by TS, GTT error returned translating called MGT to GT
		EVTN_CMD_REFRESH_PARAM_OK,                           // Received refresh parameters successfully

		EVTN_CMD_UNHANDLE,                                   // Unhandle command received
		EVTN_TEST_MGT_OK,                                    // Testing incoming Cd matchs Cd's test
		EVTN_TEST_MGT_KO,                                    // Testing incoming Cd doesn't matchs Cd's test
		EVTN_SIGNALTIMEOUT_ERROR,                            // Setting SIGNALTIMEOUT_ failure
		EVTN_WRONG_PARAM,									 // Wrong parameter value

		EVTN_DEFAULT_HLR_SSN,								 // Default HLR SSN
		EVTN_LOAD_ARP_DB_ERROR,
		EVTN_LOAD_ARP_DB_OK,

		// Disarm msg
		EVTN_SENT_RELAY_OK =  E_TFS_DISARM_BASE_NUMBER + 14, // Disarm 1014 - Request RELAY successfully
		EVTN_REQ_TO_GTT_OK,                                  // Disarm 1015 - Request to GTTS successfully
		EVTN_REQ_TO_TS_OK                                    // Disarm 1016 - request to TS-Manager successfully
};

#define NBR_EVT_MSG_ERR 48

#define EMS_STATUS_ARMED 		'A'
#define EMS_STATUS_DISARMED 	'D'
#define EMS_STATUS_NORMAL		'N'

#pragma fieldalign shared2 _evt_msg
typedef struct _evt_msg
{
    short 	i_evt_alarm;            // EMS number
    char  	c_status;               // Status of msg - 'A' : Alarm armed
    								// 				   'D' : Alarm disarmed
    								//				   'N' : Normal
    char  	c_filler;				// Filler
    short 	i_nbr_msg_showed;       // Number of alert msg showed before that msg no more viewed by viewpoint tool
    time_t 	i_first_msg_show_time;  // Timestamp in second of the first alerting msg showed on viewpoint
} EVT_MSG;

//------------------------------------------------------------------------------
void EVT_manage_init(void);

short EVT_manage( short i_msg_evt,
                  short i_nbr_alert_msg,
                  short i_interval_time,
                  char c_ems_status,
                  const char *msg, ... );

//------------------------------------------------------------------------------

#endif
