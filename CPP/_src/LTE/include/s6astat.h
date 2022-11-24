// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s6astat.h
//   Last Change : 10-07-2014
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
//	18-04-2013: created
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#ifndef _S6ASTAT_H
#define _S6ASTAT_H

#define  LTE_TFS_STATS_OFFSET  110
#define  S_MAX_IDX_NUMBER	   999

#define STAT_TFS_LTE_PREFIX_REGS	"LTFS"

enum _lte_tfs_stat
{
	// *************************************************************************************************************
	// DIAMETER STAT
	LTE_TFS_STATS_ULR_RECV = LTE_TFS_STATS_OFFSET,					// 110 - # of ULR recv. from DEA
	LTE_TFS_STATS_ULA_SENT,											//       # of ULA sent to DEA
	LTE_TFS_STATS_ULA_REDIRECT_SENT,								//       # of ULA with redirect requested to DEA
	LTE_TFS_STATS_ULA_STEERING_SENT,								//       # of ULA with steering requested to DEA
		// Answer with AVP Result-Code error value
	LTE_TFS_STATS_ULA_WITH_CMD_CODE_UNSUPPORTED,				    // 		 # of ULA with UNSUPPORTED_CMD_CODE error sent to DEA
	LTE_TFS_STATS_ULA_WITH_UNABLE_TO_COMPLY,                        // 115 - # of ULA with UNABLE_TO_COMPLY steering error sent to DEA
	LTE_TFS_STATS_ULA_WITH_MISSING_AVP,								//       # of ULA with MISSING_AVP error sent to DEA
	LTE_TFS_STATS_ULA_WITH_INVALID_AVP_VALUE,						//       # of ULA with INVALID_AVP sent to DEA
		// Critical error - Mandatory AVP issues
	LTE_TFS_STATS_MISSING_AVP_SESSION_ID,							// 		 # of ULR with MISSING_SESSION_ID AVP
	LTE_TFS_STATS_INVALID_AVP_SESSION_ID,							//       # of ULR with INVALID_SESSION_ID AVP
	LTE_TFS_STATS_MISSING_AVP_ORIGIN_HOST,							// 120 - # of ULR with MISSING_ORIGIN_HOST AVP
	LTE_TFS_STATS_INVALID_AVP_ORIGIN_HOST,                          //		 # of ULR with INVALID_ORIGIN_HOSt AVP
	LTE_TFS_STATS_MISSING_AVP_ORIGIN_REALM,							//       # of ULR with MISSING_ORIGIN_REALM AVP
	LTE_TFS_STATS_INVALID_AVP_ORIGIN_REALM,							// 		 # of ULR with INVALID_ORIGIN_REALM AVP
	LTE_TFS_STATS_MISSING_AVP_DESTINATION_REALM,					//		 # of ULR with MISSING_DESTINATION_REALM AVP
	LTE_TFS_STATS_INVALID_AVP_DESTINATION_REALM,					// 125 - # of ULR with INVALID_DESTINATION_REALM AVP
	LTE_TFS_STATS_MISSING_AVP_USER_NAME,							//		 # of ULR with MISSING_USER_NAME AVP
	LTE_TFS_STATS_INVALID_AVP_USER_NAME,							// 		 # of ULR with INVALID_USER_NAME AVP
	LTE_TFS_STATS_MISSING_AVP_RAT,									//		 # of ULR with MISSING_RAT AVP
	LTE_TFS_STATS_INVALID_AVP_RAT,									// 		 # of ULR with INVALID_RAT AVP
	LTE_TFS_STATS_MISSING_AVP_ULR_FLAGS,							// 130 - # of ULR with MISSING_ULR_FLAGS AVP
	LTE_TFS_STATS_INVALID_AVP_ULR_FLAGS,							//		 # of ULR with INVALID_ULR_FLAGS AVP
	LTE_TFS_STATS_MISSING_AVP_VISITED_PLMN_ID,						// 		 # of ULR with MISSING_VISITED_PLMN_ID AVP
	LTE_TFS_STATS_INVALID_AVP_VISITED_PLMN_ID,						// 		 # of ULR with INVALID_VISITED_PLMN_ID AVP
	// *************************************************************************************************************
	// IMSI translator DB STAT
	LTE_TFS_STATS_IMSITDB_OPEN_KO,									//       # of Open DB failure
	LTE_TFS_STATS_IMSITDB_READ_KO,									// 135 - # of DB read failure
	// *************************************************************************************************************
	// IPC with DEA/TFS Manager
	LTE_TFS_STATS_REQ_TO_TFSMGR_OK,									//		 # of request send to TFSMGR successfully
	LTE_TFS_STATS_REQ_TO_TFSMGR_KO,									//		 # of request not send, IPC failure
	LTE_TFS_STATS_RESP_FROM_TFSMGR_REC,								//       # of response received from TFSMGR
	LTE_TFS_STATS_ULA_SENT_KO,										//       # of ULA not send, IPC failure
	// *************************************************************************************************************
	// THROUPUT STAT LTE TFS - TFSMGR - LTE TFS
	LTE_TFS_STATS_TIME_10_MILL,										// 140 - #
	LTE_TFS_STATS_TIME_25_MILL,										//       #
	LTE_TFS_STATS_TIME_50_MILL,										//		 #
	LTE_TFS_STATS_TIME_75_MILL,										// 		 #
	LTE_TFS_STATS_TIME_100_MILL,									//		 #
	LTE_TFS_STATS_TIME_250_MILL,									// 145 - #	Elapsed times counters
	LTE_TFS_STATS_TIME_500_MILL,									//       # LTE TFS - TFSMGR - LTE TFS
	LTE_TFS_STATS_TIME_750_MILL,									//		 #
	LTE_TFS_STATS_TIME_1_SEC,										//	 	 #
	LTE_TFS_STATS_TIME_2_SEC,										//		 #
	LTE_TFS_STATS_TIME_3_SEC,										// 150 - #
	LTE_TFS_STATS_TIME_MAG_3_SEC,									// 151 - #
	LTE_TFS_STATS_ULA_WITH_UNABLE_TO_DELIVER,						// 152 - # of ULA with UNABLE_TO_DELIVER error sent to DEA
	LTE_TFS_STATS_ULA_WITH_ROAMING_NOT_ALLOWED						// 153 - # of ULA with ROAMING_NOT_ALLOWED steering error sent to DEA
	// *************************************************************************************************************
};

#endif
