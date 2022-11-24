//------------------------------------------------------------------------------
//   Project : LTE-TFS v 01.00
//------------------------------------------------------------------------------
//
//   File Name   : s6a_evt.h
//   Created     : 29-10-2012
//   Last Change : 16-05-2013
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef _DIAM_S6A_EVT_H
#define _DIAM_S6A_EVT_H

#include <time.h>

#define NBR_EVT_MSG_ERR 16

#define E_LTFS_ARM_BASE_NUMBER		1050
#define E_LTFS_DISARM_BASE_NUMBER	2000

#define EMS_STATUS_ARMED 		'A'
#define EMS_STATUS_DISARMED 	'D'
#define EMS_STATUS_NORMAL		'N'

enum _tfs_ems_idx {
	EVTN_TFS_LTE_START = E_LTFS_ARM_BASE_NUMBER,
	EVTN_TFS_LTE_STOP,
	EVTN_LOAD_PARAM_MISSING,
	EVTN_L_CINITIALIZE,
	EVTN_STAT_NOT_INIT,
	EVTN_RELOAD_PARAM_MISSING,
	EVTN_BUMP_ERROR,
	EVTN_ERR_SIGNALTIMEOUT_SET,
	EVTN_CMD_REFRESH_PARAM_OK,
	EVTN_ERR_CTX_CREATE_KO,
	EVTN_ERR_CTX_PUT_KO,
	EVTN_ERR_CTX_RELEASE_KO,
	EVTN_ERR_CTX_CANCELTIMEOUT_KO,
	EVTN_ERR_CTX_GET_KO,
	EVTN_ERR_CTX_LOCK_KO,
	EVTN_ERR_CTX_SIGNALTIMEOUT_KO
};

#pragma fieldalign shared2 _evt_msg
typedef struct _evt_msg
{
    short i_evt_alarm;                  // EMS number
    char  c_status;                     // Status of msg - 'A' : Alarm armed / 'D' : Alarm disarmed
    char  c_filler;						// Filler
    short i_nbr_msg_showed;             // Number of alert msg showed before that msg no more viewed by viewpoint tool
    time_t i_first_msg_show_time;       // Timestamp in second of the first alerting msg showed on viewpoint
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
