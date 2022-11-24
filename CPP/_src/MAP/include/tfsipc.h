//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.02
//------------------------------------------------------------------------------
//
//   File Name   : tfsipc.h
//   Created     : 16-10-2008
//   Last Change : 27-05-2014
//
//------------------------------------------------------------------------------
//   Description
//   -----------
// 15-03-2011 - Added new field c_tcap_map_errorcode into gtt and ts IPC structs
// 24-07-2012 - Added MAP Operation code into EXTERNAL_REF struct
// 04-09-2012 - Added IMSI into ts IPC struct
// 17-04-2014 - Added Roaming Unbundling management
//              Added c_dualimsi_flag into gtt_data structure
// 13-04-2015 - Added c_E164 - (steering of anti-steering) SCCP CdPA NPI is equal to E164 | 0x00 = E214 - 0x01 = E164
//------------------------------------------------------------------------------
#ifndef __TFSIPC_H
#define __TFSIPC_H

#include <p2system.p2apdfh>
#include <cssinc.cext>
#include <fwlbdf1.h>
#include <maputil.h>

#define MAX_EXTERNAL_REFERENCE_LENGTH	512

#define choice_mts_address          0x01
#define choice_process_name         	0x02
#define choice_extend_process_name  0x03

// Roaming Unbundling defines
#define TFS_NO_ROMUN 	0x00
#define TFS_LBO			0x01
#define TFS_ARP			0x02

#define ARP_ID_LEN	2

#pragma fieldalign shared2 _IPC_Address
typedef struct _IPC_Address
{
    unsigned char   choice;
    union {
            P2_MTS_TAG_DEF	mts_address;
            char            process_name[8];
            char            extend_process_name[8];
    } address;
} IPC_Address;

// Italy/Brasile/Japan: 456 bytes
#pragma fieldalign shared2 _external_ref
typedef struct _external_ref
{
    long long       Ts_in;
    short           i_routeinfo_len;
    FW_Route_Info   routeinfo; // TFS - set to link the defines MAX_SCCP_STRING_LENGTH=32
							   //							    FW_MAX_SCCP_CD_CG_LEN=32
    short           out_buff_len;
    char            out_buffer[FW_MAX_TCAP_LEN];
	char			c_map_op_code;		 // MAP Operation code
    char            ac_transaction[12];  // to do memcpy in transactionID structure
    char            c_invoke_id;
    char            c_map_version;
    char            c_from;
    char            c_orig_cpu;
    char            c_opcode_req;
	char			c_filler1;
} EXTERNAL_REF;

// TS Structure: 646 bytes
//#pragma fieldalign shared2 s_ts_data
//typedef struct s_ts_data
//{
//    short               i_tag;
//    short               op_code;
//    INS_AddressString   GT_mitt;
//    INS_AddressString   MGT_dest;
//    INS_String 		  imsi;
//    char				  external_reference[MAX_EXTERNAL_REFERENCE_LENGTH];
//    short               ResultType;
//    short               ResultCode;
//    IPC_Address         result_address;
//	  unsigned char		  c_tcap_map_errorcode;
//    char                filler[9];
//} ts_data;

// TS Structure: 646 bytes
#pragma fieldalign shared2 s_ts_data
typedef struct s_ts_data
{
    short               i_tag;
    short               op_code;
    INS_AddressString   GT_mitt;
    INS_AddressString   MGT_dest;
    INS_String 			imsi;
    char				external_reference[MAX_EXTERNAL_REFERENCE_LENGTH];
    short               ResultType;
    short               ResultCode;
    IPC_Address         result_address;
	unsigned char		c_tcap_map_errorcode;
	char				c_romumb; // roaming unbundling defines
	short				i_arp_id; // ARP - riporta al DB Decoupling, numerico intero
	char                eu_flag;  // used by TFS manager - set to 0x00 as default (0x01 = EU)
	char				c_E164;	  // SCCP CdPA NPI is equal to E164 | 0x00 = E214 - 0x01 = E164
    char                filler[4];
} ts_data;

// GTT Structure: 624 bytes
#pragma fieldalign shared2 s_gtt_data
typedef struct s_gtt_data
{
    short               i_tag;
    short               op_code;
    short               if_version;
    short               translation_type;
    INS_AddressString   query_data;
    INS_AddressString   query_response;
    short               SSN_1;
    short               SSN_2;
    short               SSN_3;
    short               SSN_4;
    short               SSN_5;
    char				external_reference[MAX_EXTERNAL_REFERENCE_LENGTH];
    short               ResultCode;
    IPC_Address         result_address;
	unsigned char		c_tcap_map_errorcode;
	char				c_dualimsi_flag; // 0x20 - Default | 0x01 - Dual Imsi
	char				c_romumb; 		 // roaming unbundling defines
	short				i_arp_id; 		 // ARP - riporta al DB Decoupling, numerico intero
	char				c_E164;	  		 // SCCP CdPA NPI is equal to E164 | 0x00 = E214 - 0x01 = E164
	char				filler[4];
} gtt_data;

#endif
