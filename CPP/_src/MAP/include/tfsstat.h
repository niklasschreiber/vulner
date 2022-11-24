//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.01
//------------------------------------------------------------------------------
//
//   File Name   : tfsstat.h
//   Created     : 01-09-2004
//   Last Change : 16-04-2015
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------

#ifndef __TFSSTAT_H
#define __TFSSTAT_H

#define S_MAX_IDX_NUMBER 999

#define MAX_TIME_SEC_DELAY_DEFAULT	150

//
// statistic register set defined
//
#define STAT_MAPIRO_PREFIX_REGS     "MAPIRO-"  // Inbound, Relay & Outbound server (Under Node INS)
#define STAT_MSC_PREFIX_REGS        "MSC-"     // OPC

//
// statistic index defined
//
// 96
enum { TOT_BEGIN_REC = 1,                   // nbr of incoming BEGIN
       TOT_INVOKE,                          // nbr of INVOKE component
       TOT_NOT_INVOKE,                      // nbr of not INVOKE component
       TOT_GSM_UPDATE_LOCATION_REC,         // nbr of GSM Update Location incoming
       TOT_GPRS_UPDATE_LOCATION_REC,        // nbr of GPRS Update Location incoming
       TOT_SEND_PARAM_REQ_REC,              // nbr of send parameter
       TOT_SEND_AUTH_INFO_REQ_REC,          // nbr of send authentication information
       TOT_RESTORE_DATA_REC,                // nbr of restore data
       TOT_READY_FOR_SM_REC,                // nbr of ready for short message
       TOT_PURGE_MOBILE_SUBSCRIBER_REC,     //(10) nbr of purge mobile subscriber
       TOT_PROC_UNSTRUCTURED_SS_REQ_REC,    // nbr of process unstructured SS request
       TOT_INTEROGATE_SS_REC,               // nbr of interogate SS
       TOT_OTHER_MAP_MSG_REC,               // nbr of other map message incoming
       //************************************************************************************
       TOT_UNKNOWN_COMP,                    // nbr of unknown component
       TOT_UNKNOWN_FW_EVENT_REC,            // nbr of unknown event received from Framework
       TOT_UNKNOWN_IPC_MESG_REC,            // nbr of unknown ipc message received
       //************************************************************************************
       TOT_MESG_FROM_GTT,                   // nbr of message incoming from GTT
       TOT_MESG_FROM_TS,                    // nbr of message incoming from TS Manager
       //************************************************************************************
       TOT_SHUTDOWN_PC_REQ_OK,              // nbr of shutdown done OK
       TOT_SHUTDOWN_PC_REQ_KO,              //(20)                     KO
       TOT_ALLOW_PC_REQ_OK,                 // nbr of allow done OK
       TOT_ALLOW_PC_REQ_KO,                 //                   KO
       TOT_GTT_REQ_OK,                      // nbr of request to GTT OK
       TOT_GTT_REQ_KO,                      //                       KO
       TOT_ST_REQ_OK,                       // nbr of steering request to TS Manager OK
       TOT_ST_REQ_KO,                       //                                       KO
       //************************************************************************************
       TOT_RELAY_SENT_OK,                   // nbr of relay sent OK
       TOT_RELAY_SENT_KO,                   //                   KO
       TOT_USER_ABORT_SENT_OK,              // nbr of TCAP_USER_ABORT sent OK
       TOT_USER_ABORT_SENT_KO,              //(30)                             KO
       TOT_TCAP_MAP_ERROR_SENT_OK,          // nbr of TCAP_MAP_ERROR sent OK
       TOT_TCAP_MAP_ERROR_SENT_KO,          //                            KO
       TOT_REJECT_SENT_OK,                  // nbr of Reject sent OK
       TOT_REJECT_SENT_KO,                  //                    KO
       //************************************************************************************
       TOT_MAPIN_GTT_MAPRELAY_5_MILL,       // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 5/1000"
       TOT_MAPIN_GTT_MAPRELAY_10_MILL,      // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 10/1000"
       TOT_MAPIN_GTT_MAPRELAY_25_MILL,      // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 25/1000"
       TOT_MAPIN_GTT_MAPRELAY_50_MILL,      // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 50/1000"
       TOT_MAPIN_GTT_MAPRELAY_75_MILL,      // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 75/1000"
       TOT_MAPIN_GTT_MAPRELAY_100_MILL,     //(40) nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 100/1000"
       TOT_MAPIN_GTT_MAPRELAY_250_MILL,     // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 250/1000"
       TOT_MAPIN_GTT_MAPRELAY_500_MILL,     // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 500/1000"
       TOT_MAPIN_GTT_MAPRELAY_750_MILL,     // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 750/1000"
       TOT_MAPIN_GTT_MAPRELAY_1_SEC,        // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 1"
       TOT_MAPIN_GTT_MAPRELAY_2_SEC,        // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 2"
       TOT_MAPIN_GTT_MAPRELAY_3_SEC,        // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput <= 3"
       TOT_MAPIN_GTT_MAPRELAY_MAG_3_SEC,    // nbr of message MAPIN -> GTT -> MAP-RELAY with throughput > 3"
       TOT_MAPOUT_GTT_MAPOUT_5_MILL,        // nbr of message MAPOUT -> GTT -> MAP_RELAY with throughput <= 5/1000"
       TOT_MAPOUT_GTT_MAPOUT_10_MILL,       // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 10/1000"
       TOT_MAPOUT_GTT_MAPOUT_25_MILL,       //(50) nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 25/1000"
       TOT_MAPOUT_GTT_MAPOUT_50_MILL,       // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 50/1000"
       TOT_MAPOUT_GTT_MAPOUT_75_MILL,       // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 75/1000"
       TOT_MAPOUT_GTT_MAPOUT_100_MILL,      // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 100/1000"
       TOT_MAPOUT_GTT_MAPOUT_250_MILL,      // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 250/1000"
       TOT_MAPOUT_GTT_MAPOUT_500_MILL,      // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 500/1000"
       TOT_MAPOUT_GTT_MAPOUT_750_MILL,      // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 750/1000"
       TOT_MAPOUT_GTT_MAPOUT_1_SEC,         // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 1"
       TOT_MAPOUT_GTT_MAPOUT_2_SEC,         // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 2"
       TOT_MAPOUT_GTT_MAPOUT_3_SEC,         // nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput <= 3"
       TOT_MAPOUT_GTT_MAPOUT_MAG_3_SEC,     //(60) nbr of message MAPOUT -> GTT -> MAP-RELAY with throughput > 3"
       TOT_MAPIN_TS_MAPOUT_5_MILL,          // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 5/1000"
       TOT_MAPIN_TS_MAPOUT_10_MILL,         // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 10/1000"
       TOT_MAPIN_TS_MAPOUT_25_MILL,         // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 25/1000"
       TOT_MAPIN_TS_MAPOUT_50_MILL,         // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 50/1000"
       TOT_MAPIN_TS_MAPOUT_75_MILL,         // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 75/1000"
       TOT_MAPIN_TS_MAPOUT_100_MILL,        // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 100/1000"
       TOT_MAPIN_TS_MAPOUT_250_MILL,        // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 250/1000"
       TOT_MAPIN_TS_MAPOUT_500_MILL,        // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 500/1000"
       TOT_MAPIN_TS_MAPOUT_750_MILL,        // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 750/1000"
       TOT_MAPIN_TS_MAPOUT_1_SEC,           //(70) nbr of message MAPIN -> TS -> MAPOUT with throughput <= 1"
       TOT_MAPIN_TS_MAPOUT_2_SEC,           // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 2"
       TOT_MAPIN_TS_MAPOUT_3_SEC,           // nbr of message MAPIN -> TS -> MAPOUT with throughput <= 3"
       TOT_MAPIN_TS_MAPOUT_MAG_3_SEC,       // nbr of message MAPIN -> TS -> MAPOUT with throughput > 3"
       //************************************************************************************************
       TOT_UNKNOWN_TS_RESULT_CODE,          // nbr of unknown result received from TS
       TOT_ERROR_FROM_GTT,                  // nbr of error code returned by GTT
       TOT_ERROR_FROM_TS,                   // nbr of error code returned by TS Manager
       TOT_MGT_UNKNOWN,                     // nbr of MGT no TIM
       TOT_CALLING_NATIONAL_GT,             // nbr of Calling National VLR GT
       TOT_SRI,                             // nbr of SRI
       TOT_SRI_SM,                          //(80) nbr of SRI for Short Message
       TOT_RDS,                             // nbr of Report Delivery Status
       TOT_GSM_NATIONAL_CALLING,            // nbr of GSM Location Update with national calling
       TOT_GPRS_NATIONAL_CALLING,           // nbr of GPRS Location Update with national calling
       TOT_SRI_LCS,                         // nbr of SRI for LCS
       TOT_PROC_USS_REQ,                    // nbr of Process Unstructured SS-Request
       TOT_REGISTER_SS,                     // nbr of Register SS
       TOT_ERASE_SS,                        // nbr of Erase SS
       //************************************************************************************************
       TOT_MSC_BEGIN_REC,                   // nbr of incoming BEGIN per implant
	   TOT_MSG_REC,							// Tot of incoming messages
	   TOT_CONTINUE_REC,					//(90) nbr of incoming TC-Continue
	   TOT_END_REC,							// nbr of incoming TC-End
	   TOT_ABORT_REC,                       // nbr of incoming TC-Abort
	   // ROAMING UNBLINDING
	   TOT_RELAY_MPXY_SENT_OK,				// nbr of relay sent OK towards MAP Proxy
	   TOT_RELAY_MPXY_SENT_KO,				// nbr of relay sent KO towards MAP Proxy
	   TOT_LU_GSM_E164_REC,					// nbr of LU GSM with SCCP CdPA NPI = E164 received
	   TOT_LU_GPRS_E164_REC					// nbr of LU GPRS with SCCP CdPA NPI = E164 received
} _stat_idx;

// ******************************************************************************************************
void SetThroughputStat( long long ts , char c_for );
void SetMSCStat( int i_opc, short i_idx );
short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag );
// ******************************************************************************************************

#endif
