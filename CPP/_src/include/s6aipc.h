// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s6aipc.h
//   Last Change : 08-05-2013
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#ifndef _S6AIPC_H
#define _S6AIPC_H

#include <p2system.p2apdfh>
#include <maputil.h>

#define TFS_LTE	1245
#define ULR_CMD	316

#define MAX_LTE_EXTERNAL_REFERENCE_LENGTH	640
#define MAX_DIAMETER_SESSION_INFO			255

#define MAX_IMSI_LEN 	 16
#define VPLMN_LEN	  	  7

#pragma fieldalign shared2 _IPC_Address
typedef struct _IPC_Address
{
#define choice_mts_address          0x01
#define choice_process_name         	0x02
#define choice_extend_process_name  0x03
    unsigned char   choice;
    union {
            P2_MTS_TAG_DEF	mts_address;
            char            process_name[8];
            char            extend_process_name[8];
    } address;
} IPC_Address;

#pragma fieldalign shared2 _diamident
typedef struct _diamident
{
#define MAX_DIA_STRING_LENGTH  255
    unsigned short  length;
    unsigned char   value[MAX_DIA_STRING_LENGTH+1];
}DiamIdent;

// size 540
#pragma fieldalign shared2 _external_ref
typedef struct _external_ref
{
	long			l_ctx_tag;
    long long       Ts_in;
    char  			diaSessionInfo[MAX_DIAMETER_SESSION_INFO];
    short			diaSessInfoLen;
    unsigned int	i_ulr_flags;
    unsigned int    i_HbyH;
    unsigned int	i_EtoE;
    DiamIdent		ulr_session;
} EXTERNAL_REF;

// size 1346
#pragma fieldalign shared2 _tfs_lte_ipc
typedef struct _tfs_lte_ipc
{
	short 			i_tag;  // LTE_TFS
	short			i_op;	// ULR (316)
	char			c_rat_type; // 0x00 - MME | 0x01 - SGSN
	DiamIdent      	origin_host;
	DiamIdent		origin_realm;
	INS_String		imsi;
	char			ac_visited_PLMN_Id[VPLMN_LEN]; // MCC+MNC visitor network
	char			external_reference[MAX_LTE_EXTERNAL_REFERENCE_LENGTH]; // Internal use
    short           ResultType;		// 0x00 - Relay | 0x01 -  steering
    short           ResultCode;
	IPC_Address     result_address;
	char			eu_flag;		// 0x01 = EU
	char			proxy;			// NOT USED
	short			arpId;			// NOT USED
	char			ac_filler[124];
} TFS_LTE_IPC;

#endif
