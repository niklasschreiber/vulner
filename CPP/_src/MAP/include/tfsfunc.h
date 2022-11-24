//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - A10
//------------------------------------------------------------------------------
//
//   File Name   : tfsfunc.h
//   Created     : 16-09-2004
//   Last Change : 30-05-2017
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __TFSFUNC_H
#define __TFSFUNC_H

#include <fwroute.h>
#include "tfsdb.h"
#include "ipcfunc.h"
#include "tfsipc.h"

#define NO_MAP_ERROR_CODE 	 0
#define NET_NAME_LEN			10
#define DPC_LIST_MAX_SIZE  	30
#define VLR_SSN				 	8

// SCCP CG or CD OK
#define SCCP_OK						0
// SCCP CG Error
#define ERR_SCCP_CG_LEN_ZERO		1
#define ERR_SCCP_CG_OWNER_TFS		2
#define ERR_SCCP_CG_WRONG_NPI		3
#define ERR_SCCP_CG_NATIONAL		4
#define ERR_SCCP_CG_NOT_PRESENT 	5
// SCCP CD Error
#define ERR_SCCP_CD_LEN_ZERO		6
#define ERR_SCCP_CD_NOT_OWNER_TFS	7
#define ERR_SCCP_CD_WRONG_NPI		8
#define ERR_SCCP_CD_NATIONAL		9
#define ERR_SCCP_CD_NOT_PRESENT 	10

#define WRONG_TRANSLATION_TYPE      11
#define WRONG_DPC					12

#define CHECK_SCCP_CD_ADDRESS_PREFIX 	   0x00
#define CHECK_SCCP_CG_CD_ADDRESS_PREFIX	   0x01

#define NO_INTERNAL_ROUTING_STRATEGY 0
#define INTERNAL_ROUTING_STRATEGY	 1

#define CHECK_PC_AVAILABILITY_OFF 0x00
#define CHECK_PC_AVAILABILITY_ON 0x01

#pragma fieldalign shared2 _vpc_status
typedef struct _vpc_status
{
    unsigned short      i_mode;
    unsigned short      i_net_id;
    short      			i_vpc;
    char                ac_net_name[NET_NAME_LEN];
} VPC_STATUS;

// -------------------------------------------------------------------------------------------------
// 3.12 Return cause 
// from ITU-T Q.713 Specifications of Signalling System No. 7
// Signalling Connection Control Part (SCCP) 
//
// In the unitdata service or extended unitdata service or long unitdata service message,
// the "return cause" parameter field is a one octet field containing the reason for message return.
// Bits 1-8 are coded as follows:
//
// 0x00 "no translation for an address of such nature"
// 0x01 "no translation for this specific address"
// 0x02 "subsystem congestion"
// 0x03 "subsystem failure"
// 0x04 "unequipped user"
// 0x05 "MTP failure"
// 0x06 "network congestion"
// 0x07 "unqualified"
// 0x08 "error in message transport (XUDTS)"
// 0x09 "error in local processing (XUDTS)"
// 0x0a "destination cannot perform reassembly (XUDTS)"
// 0x0b "SCCP failure"
// 0x0c "hop counter violation"
// 0x0d "segmentation not supported"
// 0x0e "segmentation failure"
// -------------------------------------------------------------------------------------------------
typedef struct udts_mtp3
{
	unsigned long sls : 4;
	unsigned long opc : 14;
	unsigned long dpc : 14;
} udts_mtp3;

typedef struct udtsheaderinfo
{
	long 			lenght;
	udts_mtp3 		mtp3;
#define XUDTS	0x12
#define UDTS	0x0A
	unsigned char 	messagetype;
	unsigned char 	returncause;
	char 			retcausereadable[64];
} udtsHeaderInfo;

/**************************************************************/

void SetNetworkID_Default( short net_id );

short GetNetworkID_Default( void );

void SetNetworkID_TSC( short net_id );

short GetNetworkID_TSC( void );

void SetNetworkID_STP( short net_id );

short GetNetworkID_STP( void );

short SCCPGT2INSAddressString( INS_AddressString *insaddress,
                               SCCP_GT *gt );

short Check_SCCP_CG_Addr( US_Route_Info *route_info,
                		  INS_AddressString *GT_mitt,
                		  PREFIX_LIST *cg_prefix_owner_tfs );

short Check_SCCP_CD_Addr( US_Route_Info *route_info,
                		  INS_AddressString *GT_dest,
                		  char *c_E164,
                		  PREFIX_LIST *cd_prefix_owner_tfs );

short Check_SCCP_CG_CD_Addr( US_Route_Info *route_info,
                    		 INS_AddressString *GT_mitt,
                    		 INS_AddressString *MGT_dest,
                    		 char *c_E164,
                    		 PREFIX_LIST *cg_prefix_owner_tfs,
                    		 PREFIX_LIST *cd_prefix_owner_tfs );

void ConvertMAPGTinSCCPGT( INS_AddressString *insaddress );


short Sent_Request_to_GTT( P2_MTS_TAG_DEF *mts_addr_GTT,
                           P2_MTS_TAG_DEF *mts_addr_resp,
                           fw_route_infod routeinfop,
                           transactionId *transaction,
                           short i_map_version,
                           char	c_map_op_code,
                           char *ac_raw_mesg,
                           short i_raw_mesg_len,
                           short i_from,
                           short i_orig_cpu,
                           short i_opcode_req,
						   char c_tcap_map_errorcode,
						   char c_invoke_id,
						   short i_arp_id,
						   char c_romumb,
						   char c_check_cg_cd_address_prefix,
						   char *ac_GT_mitt,
						   PREFIX_LIST *cg_prefix_owner_tfs,
						   PREFIX_LIST *cd_prefix_owner_tfs );

short Sent_Relay_Msg( VPC_STATUS *status,
                      long l_point_code,
                      char c_check_point_code, // 0x00 - N | 0x01 - Y
                      gtt_data *gtt );

short TCAP_User_Abort( ts_data *ts );

short TCAP_User_Abort2( gtt_data *gtt );

short TCAP_Map_Error( ts_data *ts );

short TCAP_Map_Error2( gtt_data *gtt );

short TCAP_Map_Reject( ts_data *ts );

short TCAP_Map_Reject2( gtt_data *gtt );

short VPC_Status( VPC_STATUS *vpc_status );

long GetValidDestPC( VPC_STATUS *vpc_status,
                     short DPC_list_entries,
                     long *DPC,
                     short i_internal_routing_strategy );

long GetDualImsiVDestPC( VPC_STATUS *vpc_status,
                     	 short DPC_list_entries,
                     	 long *DPC,
                     	 short i_internal_routing_strategy );

short CheckDPC( unsigned short i_net_id,
   	    	    unsigned long L_DPC );

void composeUDTSHeaderInfo( char *ac_outbuf_hex,
							short outbuflen,
							char *sccpaggr );

void LogRouteInfo( US_Route_Info *rinfo, short i_trace_level, char *ac_text );

void setChgFile( char *g_ini_file,
				 char *ac_path_file_ini_oss );

short checkChgFile( char *ac_path_file_ini_oss );

void SetDefaultSSN( short ssn );

short GetDefaultSSN( void );

void SetFAI_SSN( short fai_ssn );

short GetFAI_SSN( void );

#endif
