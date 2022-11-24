//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - Inbound/Relay - OutBound Server - v 1.11
//------------------------------------------------------------------------------
//
//   File Name   : tfsfunc.c
//   Created     : 16-09-2004
//   Last Change : 29-03-2018
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
//   Functions
//   ------------------
//------------------------------------------------------------------------------

//---------------------< Include files >----------------------------------------
#pragma nolist
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <memory.h>
#include <string.h>
#include <strings.h>
#include <time.h>
#include <sys/stat.h>
#include <ctype.h>
#include <tal.h>
#include <unistd.h>
#include <p2system.p2apdfh>
#include <erainc.ccpy>
#include <cssinc.cext>    
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <fwlbdf.h>
#include <fwroute.h>
#include <fwdef.h>
#include <fwutlx.h>
#include <mapinv.h>
#include <maperr.h>
#include <maprej.h>
#include <sspstat.h>
#include <ssplog.h>
#include <sspevt.h>
#include <sspfunc.h>
#include "gsmdef.h"
#include "tfsfunc.h"
#include "tfsipc.h"
#include "tfsdef.h"
#include "tfsstat.h"
#include "tfsevt.h"
#include "tfsdb.h"
#pragma list

// -----------------------------------------------------------------------------------------------------------
// External parameters
extern short	i_nbr_alert_msg;
extern short	i_interval_time;
extern int		i_trace_level;
// -----------------------------------------------------------------------------------------------------------

static void EncodeTCAPError( TCAPError *err,
                             char invokeID,
                             short *cmp_entries,
                             E2TCEL *cmp_arrayp );

static void EncodeTCAPReject( Reject *rej,
                              char invokeID,
                              short *cmp_entries,
                              E2TCEL *cmp_arrayp );

// ------------------------------------------------------------------------------------------------------------

static char AC_networkLocUpContextPackageVer3[16] = { 4, 0, 0, 1,
                                                      0, 1, 3, 0,
                                                      0, 0, 0, 0,
                                                      0, 0, 0, 0 };

static char AC_networkLocUpContextPackageVer2[16] = { 4, 0, 0, 1,
                                                      0, 1, 2, 0,
                                                      0, 0, 0, 0,
                                                      0, 0, 0, 0 };

static char AC_gprsLocationUpdateContextPackageVer3[16] = { 4, 0, 0, 1,
                                                            0, 32, 3, 0,
                                                            0, 0, 0, 0,
                                                            0, 0, 0, 0 };

static short _ssn; 		// HLR subsystem number
static short _fai_ssn;  // FAI STP subsystem number
static short network_id_tsc = 0;
static short network_id_stp = 0;
static short network_id_default = 0;

// ------------------------------------------------------------------------------------------------------------

void SetNetworkID_Default( short net_id )
{
	network_id_default = net_id;

	return;
}

short GetNetworkID_Default( void )
{
	return network_id_default;
}

void SetNetworkID_TSC( short net_id )
{
	network_id_tsc = net_id;

	return;
}

short GetNetworkID_TSC( void )
{
	return network_id_tsc;
}

void SetNetworkID_STP( short net_id )
{
	network_id_stp = net_id;

	return;
}

short GetNetworkID_STP( void )
{
	return network_id_stp;
}

void SetDefaultSSN( short ssn )
{
	_ssn = ssn;

	return;
}

short GetDefaultSSN( void )
{
	return _ssn;
}

void SetFAI_SSN( short fai_ssn )
{
	_fai_ssn = fai_ssn;

	return;
}

short GetFAI_SSN( void )
{
	return _fai_ssn;
}

static void EncodeTCAPError( TCAPError *err,
                             char invokeID,
                             short *cmp_entries,
                             E2TCEL *cmp_arrayp )
{
    int         numComp = 0;
    E2TCEL      *pCurr;

    pCurr = cmp_arrayp;
    EncodeComponentTypeReturnError(pCurr, &numComp);
    pCurr += numComp;

    numComp = 0;
    EncodeInvokeID(invokeID, pCurr, &numComp);
    ++invokeID;
    invokeID %= 0xFF;

    pCurr += numComp;

    numComp = 0;
    EncodeErrorCmpnt(err, pCurr, &numComp);
    pCurr += numComp;

    *cmp_entries = (short) (pCurr - cmp_arrayp);

    return;
}

static void EncodeTCAPReject( Reject *rej,
                              char invokeID,
                              short *cmp_entries,
                              E2TCEL *cmp_arrayp )
{
    int         numComp = 0;
    E2TCEL      *pCurr;

    pCurr = cmp_arrayp;
    EncodeComponentTypeReject(pCurr, &numComp);
    pCurr += numComp;

    numComp = 0;
    EncodeInvokeID(invokeID, pCurr, &numComp);
    ++invokeID;
    invokeID %= 0xFF;
    pCurr += numComp;

    numComp = 0;
    EncodeRejectCmpnt(rej, pCurr, &numComp);
    pCurr += numComp;

    *cmp_entries = (short) (pCurr - cmp_arrayp);

    return;
}

// *******************************************************************************************
//
//  Richiesta di steering a TFSMANAGER se:
//		- SCCP CG diverso dai prefissi impostati nella tabella definita dal parametro:
//				SCCP-CALLING-PREFIX-LIST-OWNER-TFS
//
//		- SCCP CD (MGT) uguale ai prefissi impostati nella tabella definita dal parametro:
//				SCCP-CALLED-PREFIX-LIST-OWNER-TFS
//
//	Altrimenti: Relay
//
short Check_SCCP_CG_Addr( US_Route_Info *route_info,
                		  INS_AddressString *GT_mitt,
                		  PREFIX_LIST *cg_prefix_owner_tfs )
{
    short   i_ret = SCCP_OK;
	char    ac_GT_mitt[MAX_INS_STRING_LENGTH +1];
    	
    if( route_info->cg_addr.Addr_ind.gt_ind )
    {
        if( SCCPGT2INSAddressString( GT_mitt,
                                     &route_info->cg_addr.gt ) )
        {
            i_ret = ERR_SCCP_CG_LEN_ZERO;
        }
        else
        {
			memset(ac_GT_mitt,0x00, sizeof(ac_GT_mitt));

			memcpy( ac_GT_mitt,
					GT_mitt->address.value,
					GT_mitt->address.length );

            if( GT_mitt->natureOfAddress == 0x01 ) // International address MAP
            {
            	if( GT_mitt->numberingPlan == 0x01 ) // E.164
            	{
					if( Find_Prefix( cg_prefix_owner_tfs,
						   		     (char *)ac_GT_mitt ) ) // Found - The GT of VLR is owner TFS
					{
						i_ret = ERR_SCCP_CG_OWNER_TFS;
					}
            	}
//            	else
//            		i_ret = ERR_SCCP_CG_WRONG_NPI;
            }
			else
				i_ret = ERR_SCCP_CG_NATIONAL; // ATTENTION !!!: for statistic only
        }
    }
    else
    {
        i_ret = ERR_SCCP_CG_NOT_PRESENT;

        log_(LOG_ERROR,"%s: SCCP Calling not found",__FUNCTION__);
    }

    return i_ret;
}

short Check_SCCP_CD_Addr( US_Route_Info *route_info,
                		  INS_AddressString *GT_dest,
                		  char *c_E164,
                		  PREFIX_LIST *cd_prefix_owner_tfs )
{
    short   i_ret = SCCP_OK;
	char    ac_GT_dest[MAX_INS_STRING_LENGTH +1];

	*c_E164 = 0x00;

    if( route_info->cd_addr.Addr_ind.gt_ind )
    {
        if( SCCPGT2INSAddressString( GT_dest,
                                     &route_info->cd_addr.gt ) )
        {
            i_ret = ERR_SCCP_CD_LEN_ZERO;
        }
        else
        {
			memset(ac_GT_dest,0x00, sizeof(ac_GT_dest));

			memcpy( ac_GT_dest,
					GT_dest->address.value,
					GT_dest->address.length );

            if( GT_dest->natureOfAddress == 0x01 ) // International address MAP
            {
            	switch( GT_dest->numberingPlan )
            	{
            		case 0x01: // E.164
            		case 0x07: // E.214
            		{
            			if( GT_dest->numberingPlan == 0x01 ) // E.164
            				*c_E164 = 0x01;

            			if( !Find_Prefix( cd_prefix_owner_tfs,
										  (char *)ac_GT_dest ) ) // Not Found
						{
							i_ret = ERR_SCCP_CD_NOT_OWNER_TFS;
						}

            			break;
            		}

            		default:
            		{
            			i_ret = ERR_SCCP_CD_WRONG_NPI;

            			break;
            		}
            	}
            }
			else
				i_ret = ERR_SCCP_CD_NATIONAL;
        }
    }
    else
    {
        i_ret = ERR_SCCP_CD_NOT_PRESENT;

        log_(LOG_ERROR,"%s: SCCP Called not found",__FUNCTION__);
    }

    return i_ret;
}

short Check_SCCP_CG_CD_Addr( US_Route_Info *route_info,
							 INS_AddressString *GT_mitt,
                		  	 INS_AddressString *GT_dest,
                		  	 char *c_E164,
                		  	 PREFIX_LIST *cg_prefix_owner_tfs,
                		  	 PREFIX_LIST *cd_prefix_owner_tfs )
{
	short i_ret;

	// CG doesn't controlled
	Check_SCCP_CG_Addr( route_info,
						GT_mitt,
						cg_prefix_owner_tfs );

	i_ret = Check_SCCP_CD_Addr( route_info,
								GT_dest,
								c_E164,
								cd_prefix_owner_tfs );

	return i_ret;
}

// *******************************************************************************************

// ---------------------------------------------------------------------------------------
//      INS_AddressString natureOfAddress and numberingPlan field values
//              -- bits 765: nature of address indicator
//                      -- 000 unknown
//                      -- 001 international number
//                      -- 010 national significant number
//                      -- 011 network specific number
//                      -- 100 subscriber number
//                      -- 101 reserved
//                      -- 110 abbreviated number
//                      -- 111 reserved for extension
//
//              -- bits 4321: numbering plan indicator
//                      -- 0000 unknown
//                      -- 0001 ISDN/Telephony Numbering Plan (Rec CCITT E.164)
//                      -- 0010 spare
//                      -- 0011 data numbering plan (CCITT Rec X.121)
//                      -- 0100 telex numbering plan (CCITT Rec F.69)
//                      -- 0101 spare
//                      -- 0110 land mobile numbering plan (CCITT Rec E.212)
//                      -- 0111 spare
//                      -- 1000 national numbering plan
//                      -- 1001 private numbering plan
//                      -- 1111 reserved for extension
//
//      SCCP_GT Nature Of Address and Numbering Plan field values
//      ---------------------------------------------------------
//
// SCCP GT Nature of Address indicator 
//                      #define GT_NA_SPARE                     0x00
//                      #define GT_NA_SUBSCRIBER_NUMBER         0x01
//                      #define GT_NA_RESEVED_NATIONAL          0x02
//                      #define GT_NA_NATIONAL                  0x03
//                      #define GT_NA_INTERNATIONAL             0x04
//                      #define GT_NA_SPARE_1                   0x05
//
//  SCCP GT Numbering Plan 
//                      #define GT_NP_UNKNOWN                   0x00
//                      #define GT_NP_ISDN_TELEPHONY_E164       0x01
//                      #define GT_NP_SPARE                     0x02
//                      #define GT_NP_DATA_X121                 0x03
//                      #define GT_NP_TELEX_F69                 0x04
//                      #define GT_NP_MARITIME_MOBILE_E210      0x05
//                      #define GT_NP_LAND_MOBILE_E212          0x06
//                      #define GT_NP_ISDN_MOBILE_E214          0x07
// ---------------------------------------------------------------------------------------
short SCCPGT2INSAddressString( INS_AddressString *insaddress,
                               SCCP_GT *gt )
{
    short   i_ret = 1;

    if( gt->address.length > 0 )
    {
        switch(gt->NatureOfAddress)
        {
            case GT_NA_SUBSCRIBER_NUMBER:
            {
                insaddress->natureOfAddress = 0x04;     // -- 100 subscriber number

                break;
            }

            case GT_NA_NATIONAL:
            {
                insaddress->natureOfAddress = 0x02;     // -- 010 national significant number

                break;
            }

            case GT_NA_INTERNATIONAL:
            {
                insaddress->natureOfAddress = 0x01;     // -- 001 international number

                break;
            }

            case GT_NA_SPARE:
            case GT_NA_RESEVED_NATIONAL:
            case GT_NA_SPARE_1:
            {
                insaddress->natureOfAddress = 0x00;     // -- 000 unknown

                break;
            }

            default:
            {
                break;
            }
        }

        switch(gt->NumberingPlan)
        {
            case GT_NP_UNKNOWN:
            {
                insaddress->numberingPlan = 0x00;       // -- 0000 unknown

                break;
            }

            case GT_NP_ISDN_TELEPHONY_E164:
            {
                insaddress->numberingPlan = 0x01;       // -- 0001 ISDN/Telephony Numbering Plan (Rec CCITT E.164)

                break;
            }

            case GT_NP_SPARE:
            {
                insaddress->numberingPlan = 0x02;       // -- 0010 spare

                break;
            }

            case GT_NP_DATA_X121:
            {
                insaddress->numberingPlan = 0x03;       // -- 0011 data numbering plan (CCITT Rec X.121)

                break;
            }

            case GT_NP_TELEX_F69:
            {
                insaddress->numberingPlan = 0x04;       // -- 0100 telex numbering plan (CCITT Rec F.69)

                break;
            }

            case GT_NP_MARITIME_MOBILE_E210:
            {
                insaddress->numberingPlan = 0x05;       // -- 0101 land maritime mobile numbering plan (CCITT Rec E.210)

                break;
            }

            case GT_NP_LAND_MOBILE_E212:
            {
                insaddress->numberingPlan = 0x06;       // -- 0110 land mobile numbering plan (CCITT Rec E.212)

                break;
            }

            case GT_NP_ISDN_MOBILE_E214:
            {
                insaddress->numberingPlan = 0x07;       // -- 0111 ISDN mobile numbering plan (CCITT Rec E.214)

                break;
            }

            default:
            {
                break;
            }
        }

        i_ret = 0;

        insaddress->address.length = gt->address.length;
        memcpy( insaddress->address.value,
                gt->address.value,
                gt->address.length );
    }

    return i_ret;
}

void ConvertMAPGTinSCCPGT( INS_AddressString *insaddress )
{
    switch( insaddress->natureOfAddress )
    {
        case 0x00:
        {
            insaddress->natureOfAddress = 0x02;

            break;
        }

        case 0x01:
        {
            insaddress->natureOfAddress = 0x04;

            break;
        }

        case 0x02:
        {
            insaddress->natureOfAddress = 0x03;

            break;
        }

        case 0x04:
        {
            insaddress->natureOfAddress = 0x01;

            break;
        }
    }

    return;
}

//
// Sent request to GTTS
//
//  code returned:
//  0   - OK
//  !0  - KO
//
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
						   PREFIX_LIST *cd_prefix_owner_tfs )
{
    short               i_ret = 0;
    short               i_cpu_req = 0;
    short				i_res_check_sccp = SCCP_OK;
    char                ac_dest[MAX_INS_STRING_LENGTH + 1];
    char                ac_mitt[MAX_INS_STRING_LENGTH + 1];
    char				c_CdPA_NPI_is_E164;
    INS_AddressString   sccp_cg;
    INS_AddressString   sccp_cd;
    US_Route_Info       route_info;
	EXTERNAL_REF		ExternalReference;
    gtt_data            gtt;

	memset( &gtt,
			0x00,
			sizeof(gtt_data) );

    i_ret = MTP3SCCP_DecodeRoutingInfo( routeinfop,
										&route_info );

	if( !i_ret )
	{
		switch( c_check_cg_cd_address_prefix )
		{
			case CHECK_SCCP_CG_CD_ADDRESS_PREFIX:
			{
				i_res_check_sccp = Check_SCCP_CG_CD_Addr( &route_info,
														  &sccp_cg,
														  &sccp_cd,
														  &c_CdPA_NPI_is_E164,
														  cg_prefix_owner_tfs,
														  cd_prefix_owner_tfs );

				if( i_res_check_sccp == SCCP_OK )
				{
					memset(ac_mitt, 0x00, sizeof(ac_mitt));

					strncpy( ac_mitt,
							 sccp_cg.address.value,
							 sccp_cg.address.length );

					if( c_CdPA_NPI_is_E164 == 0x00 )
					{
						log_(LOG_DEBUG,"%s: Check_SCCP_CD_Addr() - Cg[%s] - Cd[%.*s] successfully",
								__FUNCTION__,
								ac_mitt,
								sccp_cd.address.length,
								sccp_cd.address.value);
					}
					else
					{
						log_(LOG_WARNING,"%s: Check_SCCP_CD_Addr() - Cg[%s] - Cd[%.*s] successfully but unexpected SCCP CdPA NPI[E.164] has been received",
								__FUNCTION__,
								ac_mitt,
								sccp_cd.address.length,
								sccp_cd.address.value);
					}
				}
				else
				{
					strcpy(ac_mitt,"---");
					log_(LOG_DEBUG2,"%s: Err.[%d] - Check_SCCP_CD_Addr() - Cg[---]",
							__FUNCTION__,
							i_res_check_sccp);
				}

				break;
			}

			case CHECK_SCCP_CD_ADDRESS_PREFIX:
			{
				memset(ac_mitt, 0x00, sizeof(ac_mitt));

				strcpy(ac_mitt,ac_GT_mitt);

				i_res_check_sccp = Check_SCCP_CD_Addr( &route_info,
													   &sccp_cd,
													   &c_CdPA_NPI_is_E164,
													   cd_prefix_owner_tfs );

				if( i_res_check_sccp == SCCP_OK )
				{
					if( c_CdPA_NPI_is_E164 == 0x00 )
					{
						log_(LOG_DEBUG,"%s: Check_SCCP_CD_Addr() - Cg[%s] - Cd[%.*s] successfully",
								__FUNCTION__,
								ac_mitt,
								sccp_cd.address.length,
								sccp_cd.address.value);
					}
					else
					{
						log_(LOG_DEBUG,"%s: Check_SCCP_CD_Addr() - Cg[%s] - Cd[%.*s] successfully but unexpected SCCP CdPA NPI[E.164] has been received",
								__FUNCTION__,
								ac_mitt,
								sccp_cd.address.length,
								sccp_cd.address.value);
					}
				}
				else
				{
					log_(LOG_DEBUG2,"%s: Err.[%d] - Check_SCCP_CD_Addr() - Cg[%s]",
							__FUNCTION__,
							i_res_check_sccp,
							ac_mitt);
				}

				break;
			}
		}

		gtt.c_tcap_map_errorcode = c_tcap_map_errorcode;

		switch( i_opcode_req )
		{
			case FORCE_RELAY_REQ:
			case RELAY_REQ:
			{
				gtt.translation_type = TTYPEPC; // MGT (E.214) to PC
												// GT (E.164) to PC or GT+SSN on configuration based

				break;
			}

			case MAP_ERR_REQ:
			case TCAP_ABORT_REQ:
			case TCAP_REJECT_REQ:
			{
				if( c_CdPA_NPI_is_E164 == 0x00 )
					gtt.translation_type = TTYPEGT;     // MGT to GT
				else
					gtt.translation_type = TTYPEGTGT;   // GT to GT: steering of anti-steering if the SCCP CdPA NPI = E.164 instead of E.214
														//           check the validity of GT received

				break;
			}

			default:
			{
				// unknown i_opcode_req
				i_ret = WRONG_TRANSLATION_TYPE;

				break;
			}
		}

		if( i_ret != WRONG_TRANSLATION_TYPE )
		{
			memset( &ExternalReference,
					0x00,
					sizeof(ExternalReference) );

			memset( ac_dest,
					0x00,
					sizeof(ac_dest) );

			//
			// GTT flags
			//
			gtt.i_tag       = GTT_TAG;                  // TAG of GTT Server
			gtt.op_code     = REQUEST_TO_GTT_OPCODE;    // flag GTT operation code
			gtt.if_version  = GTT_INTERFACE_VERSION;    // flag GTT interface version

			//
			// Opcode for rescue tag in GTT management scope
			//
			ExternalReference.c_opcode_req = (char)i_opcode_req;

			//
			// Set IPC MTS address process for reply back
			//
			gtt.result_address.choice                           = choice_mts_address;   		// MTS_SEND only
			gtt.result_address.address.mts_address.task_id      = mts_addr_resp->task_id;
			gtt.result_address.address.mts_address.server_class = mts_addr_resp->server_class;
			gtt.result_address.address.mts_address.cpu_req		= 1;
			gtt.result_address.address.mts_address.cpu          = mts_addr_resp->cpu;

			ConvertMAPGTinSCCPGT(&sccp_cd);
			gtt.query_data = *(&sccp_cd);

			//
			// copy the routing information
			//
			ExternalReference.i_routeinfo_len = sizeof(FW_Route_Info);
			memcpy( &ExternalReference.routeinfo,
					routeinfop,
					ExternalReference.i_routeinfo_len );

			//
			// copy the raw TCAP message
			//
			ExternalReference.out_buff_len = i_raw_mesg_len;
			memcpy( ExternalReference.out_buffer,
					ac_raw_mesg,
					i_raw_mesg_len );

			//
			// set the originated CPU that received the msg
			//
			ExternalReference.c_orig_cpu = (char)i_orig_cpu;

			//
			// copy the original transaction ID
			//
			memcpy( &ExternalReference.ac_transaction,
					(char *)transaction,
					sizeof(ExternalReference.ac_transaction) );

			ExternalReference.c_map_version = (char)i_map_version;
			ExternalReference.c_map_op_code = c_map_op_code;
			ExternalReference.c_invoke_id   = c_invoke_id;

			memcpy( ac_dest,
					sccp_cd.address.value,
					sccp_cd.address.length );

			// ************************************************
			// set Throughput Stat in
			ExternalReference.c_from = (char)i_from;
			ExternalReference.Ts_in  = JULIANTIMESTAMP(0);
			// ************************************************

			memcpy( gtt.external_reference,
					(char *)&ExternalReference,
					sizeof(EXTERNAL_REF) );

			//
			// Roaming unbundling
			//
			gtt.i_arp_id = i_arp_id;
			gtt.c_romumb = c_romumb;

			//
			// E.164 management
			//
			gtt.c_E164   = c_CdPA_NPI_is_E164;

			//
			// if set mts_addr_GTT->cpu, cpu set requested to MTS_SEND
			//
			if( mts_addr_GTT->cpu )
				i_cpu_req = 1;

			if( (i_ret = Func_MTS_SEND_Taskid( mts_addr_GTT->task_id,
											   mts_addr_GTT->server_class,
											   i_cpu_req,
											   mts_addr_GTT->cpu,
											   (char *)&gtt,
											   sizeof(gtt_data) )) )
			{
				if( i_ret == -1 ||
					i_ret == -3 )
				{
					EVT_manage( EVTN_REQ_TO_GTT_ERROR,
								i_nbr_alert_msg,
								i_interval_time,
								'A',
								"IPC Err.[%d] with GTTS Server - Cg[%s] - Cd[%s]",
								i_ret,
								ac_mitt,
								ac_dest );
				}

				log_(LOG_ERROR,"%s: IPC Err.[%d] - MTS_SEND to GTTS failure - Cg[%s] - Cd[%s]",
						__FUNCTION__,
						i_ret,
						ac_mitt,
						ac_dest);
			}
			else
			{
				EVT_manage( EVTN_REQ_TO_GTT_OK,
							i_nbr_alert_msg,
							i_interval_time,
							'D',
							"GTT-SERVER is alive" );

				log_(LOG_DEBUG,"%s: MTS_SEND to GTTS successfully - Cg[%s] - Cd[%s]",
						__FUNCTION__,
						ac_mitt,
						ac_dest);
			}
		}
		else
			log_(LOG_ERROR,"%s: WRONG_TRANSLATION_TYPE - Unknown opcode request [%d]",
					__FUNCTION__,
					i_ret);
	}

    return i_ret;
}

//
// Sent MAP message on SS7 network in relay mode
//
short Sent_Relay_Msg( VPC_STATUS *status,
                      long l_point_code,
                      char c_check_point_code, // 0x00 - N | 0x01 - Y
                      gtt_data *gtt )
{
    short               i_ret = 0;
    short               i_err;
    short               i_pc;
    short				i_cont;
    char                ac_out[256];
    short               i_pc_vlr_mitt;
    transactionId       transId;
    EXTERNAL_REF        *ExternalReference;
    US_Route_Info       routeReadable;
    FW_Route_Info       routeinfo;
	
	ExternalReference = (EXTERNAL_REF *)gtt->external_reference;

    SetThroughputStat( ExternalReference->Ts_in,
                       ExternalReference->c_from );

    if( gtt->query_response.numberingPlan == SPARE )  // Because is Point Code
    {
        memset(&routeReadable,0x00, sizeof(US_Route_Info));
        memset(&transId,0x00, sizeof(transactionId));
        memset(ac_out,0x00, sizeof(ac_out));

        i_cont = 1;

        //
        // Extract TCAP/MAP original message and TCAP TID
        //
        ac_out[0] = (char)ExternalReference->out_buff_len; 	// Add TCAP message length to the first byte of out buffer to reroute
        memcpy( ac_out + 1,
                (char *)ExternalReference->out_buffer, 		// Add TCAP raw buffer to out buffer to reroute
                ExternalReference->out_buff_len );

        memcpy( &transId,
                (char *)ExternalReference->ac_transaction,
                sizeof(transactionId) );

        //
		// Decoding original routing
		//
		i_err =	MTP3SCCP_DecodeRoutingInfo( &ExternalReference->routeinfo,
											&routeReadable );

		if(!i_err)
		{
			//
			// Encoding new routing
			//
			memset( &routeinfo,
					0x00,
					sizeof(FW_Route_Info) );

			if(i_trace_level > LOG_DEBUG)
			{
				LogRouteInfo( &routeReadable,
							  LOG_DEBUG2,
							  "First" );
			}

			if( !l_point_code )
			{
				// PC - HLR
				memcpy( &i_pc,
						gtt->query_response.address.value,
						gtt->query_response.address.length );
			}
			else
				i_pc = (short)l_point_code;

			if( c_check_point_code == CHECK_PC_AVAILABILITY_ON )
			{
				if( !CheckDPC( status->i_net_id,
				   	    	   (unsigned long)i_pc ) )
				{
					i_cont = 0;

					log_(LOG_ERROR,"%s: HLR DPC[%d] unavailable or wrong GTT DB configuration",
							__FUNCTION__,
							i_pc);
				}
			}

			if( i_cont )
			{
				//
				// M3UA
				//
				routeReadable.view      				= view_is_Local; // Switch OPC with DPC
				i_pc_vlr_mitt 							= (short)routeReadable.mtp3_opc;

				routeReadable.mtp3_opc  				= status->i_vpc;  		// MTP3 OPC = TGDS
				routeReadable.mtp3_dpc  				= i_pc;			  		// MTP3 DPC

				//
				// SCCP
				//
				routeReadable.cg_addr.Addr_ind.pc_ind   = '0';  // SCCP Cg PC not present

				routeReadable.cd_addr.Addr_ind.pc_ind   = '0';	// SCCP Cd PC not present
				routeReadable.cd_addr.Addr_ind.rout_ind = '1';  // '0'= routing on GT | '1'= routing on PC + SSN (default)
				routeReadable.cd_addr.routing_ind 		=  1;	//  0 = routing on GT |  1 = routing on PC + SSN (default)

				switch( gtt->c_dualimsi_flag )
				{
					//
					// Dual IMSI - Route on GT
					//
					case 0x01:
					{
						setFW_networkId( (char)GetNetworkID_TSC() );

						routeReadable.cd_addr.Addr_ind.gt_ind 	= SCCPADDR_GT_TT_NP_ES_NA; // GT includes translation plan, numbering plan,
																						   // encoding scheme and nature of address indicator

						routeReadable.cd_addr.Addr_ind.rout_ind = '0'; 	// '0'= routing on GT | '1'= routing on PC + SSN
						routeReadable.cd_addr.routing_ind 		=  0;	//  0 = routing on GT |  1 = routing on PC + SSN

						break;
					}

					//
					// Flag DualIMSI has been reused and overwritten with 0x02 for FAI DPC+SSN=250
					//
					case 0x02:
					{
						setFW_networkId((char)GetNetworkID_STP());

						routeReadable.cd_addr.Addr_ind.ssn_ind  = '1';  		// SSN indicator present
						routeReadable.cd_addr.ssn 				= GetFAI_SSN();	// get STP FAI SSN ( SSN = 250 )

						break;
					}
					//
					// Flag DualIMSI has been reused and overwritten with 0x03 for E.164 new routing based on GT+SSN(default is 6)
					//
					case 0x03:
					{
						routeReadable.cd_addr.Addr_ind.gt_ind 	= SCCPADDR_GT_TT_NP_ES_NA; // GT includes translation plan, numbering plan,
																						   // encoding scheme and nature of address indicator

						routeReadable.cd_addr.Addr_ind.rout_ind = '0'; 	// '0'= routing on GT | '1'= routing on PC + SSN
						routeReadable.cd_addr.routing_ind 		=  0;	//  0 = routing on GT |  1 = routing on PC + SSN

						routeReadable.cd_addr.Addr_ind.ssn_ind  = '1';   // SSN indicator present

						// Get SSN value from GTTS response hence if it is not zero, otherwise get
						// SSN value from inifile if it has been configured otherwise get default SSN = 6 (HLR)
						routeReadable.cd_addr.ssn = GetDefaultSSN();
						if( gtt->SSN_1 > 0 )
							routeReadable.cd_addr.ssn = gtt->SSN_1;

						break;
					}

					//
					// Default relaying to HLR with SSN = 6 (default) or other
					//
					default:
					{
						setFW_networkId((char)GetNetworkID_Default());

						routeReadable.cd_addr.Addr_ind.ssn_ind = '1';    	// SSN indicator present
						// Get SSN value from GTTS response hence if it is not zero, otherwise get
						// SSN value from inifile if it has been configured otherwise get default SSN = 6 ( HLR)
						routeReadable.cd_addr.ssn = GetDefaultSSN();
						if( gtt->SSN_1 > 0 )
							routeReadable.cd_addr.ssn = gtt->SSN_1;

						break;
					}
				}

				i_err =	MTP3SCCP_EncodeRoutingInfo( &routeinfo,
													&routeReadable );

				if( !i_err )
				{
					// Set TPT routing
					if ( (i_err = FW_Set_Outbound_Routing( &routeinfo )) )
					{
						i_ret = FW_SENDEND_BAD_ROUTE_INFO;

						EVT_manage( EVTN_BAD_ROUTING_INFO,
									0,
									i_interval_time,
									'A',
									"BAD ROUTING INFO - Err.[%d-%d] - Orig PC[%d] - OPC-TFS[%d] - DPC[%d:%d]",
									i_err,
									GetRoutingFailureCause(),
									i_pc_vlr_mitt,
									status->i_vpc,
									i_pc,
									routeReadable.cd_addr.ssn );

						log_(LOG_ERROR,"%s: Bad Routing Info Err.[%d-%d] - Orig PC[%d] - OPC-TFS[%d] - DPC[%d:%d]",
								__FUNCTION__,
								i_err,
								GetRoutingFailureCause(),
								i_pc_vlr_mitt,
								status->i_vpc,
								i_pc,
								routeReadable.cd_addr.ssn);
					}
					else
					{
						if(i_trace_level > LOG_DEBUG)
						{
							LogRouteInfo( &routeReadable,
										  LOG_DEBUG2,
										  "After" );
						}

						i_err = SS7_MTS_SEND_Taskid( ac_out,
													 (short)((ExternalReference->out_buff_len) + 1),
													 ExternalReference->c_orig_cpu );

						if( i_err )
						{
							i_ret = i_err;

							if( i_err == -1 ||
								i_err == -3 )
							{
								EVT_manage( EVTN_SENT_RELAY_ERROR,
											i_nbr_alert_msg,
											i_interval_time,
											'A',
											"SS7 IPC Err.[%d] - Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d]",
											 i_err,
											 i_pc_vlr_mitt,
											 status->i_vpc,
											 i_pc,
											 routeReadable.cd_addr.ssn );
							}

							log_(LOG_ERROR,"%s: SS7 Router IPC failure with Err.[%d] - Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d]",
									__FUNCTION__,
									i_err,
									i_pc_vlr_mitt,
									status->i_vpc,
									i_pc,
									routeReadable.cd_addr.ssn );
						}
						else
						{
							EVT_manage( EVTN_SENT_RELAY_OK,
										i_nbr_alert_msg,
										i_interval_time,
										'D',
										"SS7 Router is alive" );

							switch( gtt->c_dualimsi_flag )
							{
								//
								// Dual IMSI - Route on GT
								//
								case 0x01:
								{
									log_(LOG_DEBUG,"%s: Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d] - SCCP GT Ok",
											__FUNCTION__,
											i_pc_vlr_mitt,
											status->i_vpc,
											i_pc,
											routeReadable.cd_addr.ssn );

									break;
								}

								//
								// Flag DualIMSI has been reused and overwritten with 0x02 for FAI DPC+SSN=250
								//
								case 0x02:
								{
									log_(LOG_DEBUG,"%s: Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d] - SCCP DPC+SSN=(FAI) Ok",
											__FUNCTION__,
											i_pc_vlr_mitt,
											status->i_vpc,
											i_pc,
											routeReadable.cd_addr.ssn );

									break;
								}

								//
								// Flag DualIMSI has been reused and overwritten with 0x03 for E.164 new routing based on GT+SSN(default is 6)
								//
								case 0x03:
								{
									log_(LOG_DEBUG,"%s: Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d] - SCCP E.164 GT+SSN Ok",
											__FUNCTION__,
											i_pc_vlr_mitt,
											status->i_vpc,
											i_pc,
											routeReadable.cd_addr.ssn );

									break;
								}

								default:
								{
									log_(LOG_DEBUG,"%s: Orig. PC[%d] - OPC-TFS[%d] - DPC[%d:%d] - SCCP DPC+SSN Ok",
											__FUNCTION__,
											i_pc_vlr_mitt,
											status->i_vpc,
											i_pc,
											routeReadable.cd_addr.ssn );

									break;
								}
							}
						}
					}
				}
				else
				{
					log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
							__FUNCTION__,
							i_err);

					LogRouteInfo( &routeReadable,
								  LOG_ERROR,
								  "MTP3SCCP_EncodeRoutingInfo" );

					i_ret = FW_SENDEND_BAD_ROUTE_INFO;
				}

				//reset FW Net.id.
				setFW_networkId((char)GetNetworkID_Default());
			}
		}
		else
		{
			log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
					__FUNCTION__,
					i_err);

			i_ret = FW_SENDEND_BAD_ROUTE_INFO;
		}
    }
    else
        i_ret = NUMBERING_PLAN_NO_SPARE;

    return i_ret;
}

//
// sent TCAP_Abort message
//
short TCAP_User_Abort( ts_data *ts )
{
    short           i_ret = 0;
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;
	EXTERNAL_REF    *ExternalReference;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)ts->external_reference;

    i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		log_(LOG_DEBUG,"%s: TCAP_User_Abort requested from TS : OPC[%d] - DPC[%d]",
				__FUNCTION__,
				routeReadable.mtp3_opc,
				routeReadable.mtp3_dpc);

		routeReadable.cd_addr.Addr_ind.rout_ind = '1';

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );

		if(!i_ret)
		{
			memset(&transId,0x00, sizeof(transactionId));
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			memcpy( &transId,
					(char *)ExternalReference->ac_transaction,
					sizeof(ExternalReference->ac_transaction) );

			dialogue.choice                 = send_dlg_abort;
			dialogue.abort_source           = 0x00;   // Dialogue Service User
			dialogue.is_userInfo_present    = userInfo_yes;

			dialogue.userInformation.map_DialoguePDU.choice = MapDialoguePDU_mapUserAbort_chosen;
			dialogue.userInformation.map_DialoguePDU.u.mapUserAbort.choice = MapUserAbort_userResourceLimitation_chosen;

			i_ret = FW2_TCAP_Send_U_Abort ( routeinfop,
											&transId,
											&dialogue );

			if(i_ret)
			{
				EVT_manage( EVTN_REQ_USER_ABORT_ERROR,
							0,
							i_interval_time,
							'A',
							"TCAP User Abort failed Err.[%d] - OPC[%d] - DPC[%d]",
							 i_ret,
							 routeReadable.mtp3_opc,
							 routeReadable.mtp3_dpc );

				log_(LOG_ERROR,"%s: TCAP User Abort failed Err.[%d] - OPC[%d] - DPC[%d]",
						__FUNCTION__,
						i_ret,
						routeReadable.mtp3_opc,
						routeReadable.mtp3_dpc);
			}
		}
		else
		{
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
		}
	}
	else
	{
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);
	}

    return i_ret;
}

//
// sent TCAP_End with map error
//
short TCAP_Map_Error( ts_data *ts )
{
    short           i_ret = 0;
    short           cmp_entries = 0;
    E2TCEL          cmp_elements[100];
    E2TCEL          *cmp_arrayp = &cmp_elements[0];
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;
    TCAPError       error;
	EXTERNAL_REF    *ExternalReference;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)ts->external_reference;

	i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		log_(LOG_DEBUG,"%s: TCAP_Map_Error requested from TS: OPC[%d] - DPC[%d]",
				__FUNCTION__,
				routeReadable.mtp3_opc,
				routeReadable.mtp3_dpc);

		routeReadable.cd_addr.Addr_ind.rout_ind = '1';

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );

		if(!i_ret)
		{
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			dialogue.choice = no_dlg;

			if( ExternalReference->c_map_version >= 0x02 )
			{
				dialogue.choice = send_dlg_response;
				dialogue.ac_len = 0x07;

				switch( ExternalReference->c_map_op_code )
				{
					case UpdateGSMLocation_Request_OperationCode:
					{
						if(ExternalReference->c_map_version == 2)
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer2,
									dialogue.ac_len );
						}
						else if(ExternalReference->c_map_version == 3)
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					case UpdateGPRSLocation_Request_OperationCode:
					{
						if(ExternalReference->c_map_version == 3)
						{
							memcpy( dialogue.ac_name,
									AC_gprsLocationUpdateContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					default:
					{
						i_ret = 1;

						break;
					}
				}

				dialogue.is_userInfo_present = userInfo_no;
			}

			if(!i_ret)
			{
				memset(&transId,0x00, sizeof(transactionId));
				memset(&error,0x00, sizeof(TCAPError));

				memcpy( &transId,
						(char *)ExternalReference->ac_transaction,
						sizeof(ExternalReference->ac_transaction) );

				switch( ts->c_tcap_map_errorcode )
				{
					case 0:
					case 34: // system failure
					{
						if(ExternalReference->c_map_version == 3)
							error.bit_mask = TCAP_Error_Parameter_ExtensibleSystemFailureParam_present;
						else
							error.bit_mask = TCAP_Error_Parameter_present; // MAP V1/2

						   	error.parameter.systemFailure = hlr;  // plmn = 0
																  // hlr = 1
																  // vlr = 2
																  // pvlr = 3
																  // controllingMSC = 4
																  // vmsc = 5
																  // eir = 6
																  // rss = 7

						error.errorCode = systemFailure_ErrorCode;  // = 34


						break;
					}

					case roamingNotAllowed_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.roamingNotAllowed = plmnRoamingNotAllowed; // plmnRoamingNotAllowed = 0
																				   // operatorDeterminedBarring = 3
						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}

					case absentSubscriber_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.absentSubscriber = hlr; // = 1

						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}

					case callBarred_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.callBarred = operatorBarring; // operatorBarring = 1
																	  // barringServiceActive = 0

						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}

					case cug_Reject_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.cug_Reject = incomingCallsBarredWithinCUG;	// incomingCallsBarredWithinCUG = 0,
																					// subscriberNotMemberOfCUG = 1,
																					// requestedBasicServiceViolatesCUG_Constraints = 5,
																					// calledPartySS_InteractionViolation = 7

						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}

					case ss_SubscriptionViolation_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.ss_SubscriptionViolation.choice = cliRestrictionOption_chosen;
						error.parameter.ss_SubscriptionViolation.u.cliRestrictionOption = permanent;

						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}
					
					case pw_RegistrationFailure_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.pw_RegistrationFailure = undetermined; 
																	  
						error.errorCode =  ts->c_tcap_map_errorcode;

						break;
					}

					default:
					{
						error.errorCode = systemFailure_ErrorCode;

						break;
					}
				}
				
				if(!i_ret)
				{
					EncodeTCAPError( &error,
									 ExternalReference->c_invoke_id,
									 &cmp_entries,
									 cmp_arrayp );

					i_ret = FW2_TCAP_SendEnd ( cmp_arrayp,
											   cmp_entries,
											   routeinfop,
											   &transId,
											   &dialogue );
				}
			}

			if(i_ret)
			{
				EVT_manage( EVTN_REQ_MAP_ERROR,
							0,
							i_interval_time,
							'A',
							"Map Error failure - Err.[%d] - OPC[%d] - DPC[%d]",
							 i_ret,
							 routeReadable.mtp3_opc,
							 routeReadable.mtp3_dpc );

				log_(LOG_ERROR,"%s: Map Error failure - Err.[%d] - OPC[%d] - DPC[%d]",
						__FUNCTION__,
						i_ret,
						routeReadable.mtp3_opc,
						routeReadable.mtp3_dpc);
			}
		}
		else
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
	}
	else
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);

    return i_ret;
}

//
// sent TCAP_End with reject
//
short TCAP_Map_Reject( ts_data *ts )
{
    short           i_ret = 0;
    short           cmp_entries = 0;
    E2TCEL          cmp_elements[100];
    E2TCEL          *cmp_arrayp = &cmp_elements[0];
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;
    Reject          reject;
	EXTERNAL_REF    *ExternalReference;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)ts->external_reference;

	i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		log_(LOG_DEBUG,"%s: TCAP_Map_Reject requested from TS: OPC[%d] - DPC[%d]",
				__FUNCTION__,
				routeReadable.mtp3_opc,
				routeReadable.mtp3_dpc);

		routeReadable.cd_addr.Addr_ind.rout_ind = '1';

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );

		if(!i_ret)
		{
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			dialogue.choice = no_dlg;

			if( ExternalReference->c_map_version >= 0x02 )
			{
				dialogue.choice = send_dlg_response;
				dialogue.ac_len = 0x07;

				switch( ExternalReference->c_map_op_code )
				{
					case UpdateGSMLocation_Request_OperationCode:
					{
						if(ExternalReference->c_map_version == 2)
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer2,
									dialogue.ac_len );
						}
						else if(ExternalReference->c_map_version == 3)
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					case UpdateGPRSLocation_Request_OperationCode:
					{
						if(ExternalReference->c_map_version == 3)
						{
							memcpy( dialogue.ac_name,
									AC_gprsLocationUpdateContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					default:
					{
						i_ret = 1;

						break;
					}
				}

				dialogue.is_userInfo_present = userInfo_no;
			}

			if(!i_ret)
			{
				memset(&transId,0x00, sizeof(transactionId));
				memset(&reject,0x00, sizeof(Reject));

				memcpy( &transId,
						(char *)ExternalReference->ac_transaction,
						sizeof(ExternalReference->ac_transaction) );

				reject.choice           = generalProblem_chosen;
				reject.u.generalProblem = unrecognizedComponent;

				EncodeTCAPReject( &reject,
								  ExternalReference->c_invoke_id,
								  &cmp_entries,
								  cmp_arrayp );

				i_ret = FW2_TCAP_SendEnd ( cmp_arrayp,
										   cmp_entries,
										   routeinfop,
										   &transId,
										   &dialogue );
			}

			if(i_ret)
			{
				EVT_manage( EVTN_REQ_MAP_REJECT_ERROR,
							0,
							i_interval_time,
							'A',
							"TCAP Reject sent failed - Err.[%d] - OPC[%d] - DPC[%d]",
							i_ret,
							routeReadable.mtp3_opc,
							routeReadable.mtp3_dpc );

				log_(LOG_ERROR,"%s: TCAP Reject sent failed - Err.[%d] - OPC[%d] - DPC[%d]",
						__FUNCTION__,
						i_ret,
						routeReadable.mtp3_opc,
						routeReadable.mtp3_dpc);
			}
		}
		else
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
	}
	else
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);

    return i_ret;
}

// *******************************************************************************************
//
// sent TCAP_Abort2 message
//
short TCAP_User_Abort2( gtt_data *gtt )
{
    short           i_ret = 0;
    char            ac_GT_mitt[MAX_INS_STRING_LENGTH +1];
    char            ac_GT_dest[MAX_INS_STRING_LENGTH +1];
	EXTERNAL_REF	*ExternalReference;
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)gtt->external_reference;

    i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		memset(ac_GT_mitt,0x00, sizeof(ac_GT_mitt));
		memset(ac_GT_dest,0x00, sizeof(ac_GT_dest));

		if( gtt->ResultCode == GTT_RESULT_SUCCESS )
		{
			routeReadable.cd_addr.Addr_ind.rout_ind  = '0';

			routeReadable.cd_addr.gt.NatureOfAddress = 0x04;
			routeReadable.cd_addr.gt.NumberingPlan   = 0x01;
			routeReadable.cd_addr.Addr_ind.gt_ind    = 4;

			memcpy( routeReadable.cd_addr.gt.address.value,
					gtt->query_response.address.value,
					gtt->query_response.address.length );

			routeReadable.cd_addr.gt.address.length = gtt->query_response.address.length;

			if(routeReadable.cd_addr.gt.address.length % 2)
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_ODD; // ODD
			else
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_EVEN; // EVEN

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );
		}
		else
		{
			AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_ERROR_FROM_GTT);

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );

			// Error from GTT
			log_evt( SSPEVT_NORMAL,
					 SSPEVT_NOACTION,
					 EVTN_GTT_ERR_USER_ABORT2,
					 "TCAP User Abort2 - GTT RsCode Err.[%d] - Cg[%s] - Cd[%s] - Rout.unchanged",
					 gtt->ResultCode,
					 ac_GT_mitt,
					 ac_GT_dest);

			log_(LOG_ERROR,"%s: TCAP User Abort2 - GTT RsCode Err.[%d] - Cg[%s] - Cd[%s] - Rout.unchanged",
					__FUNCTION__,
					gtt->ResultCode,
					ac_GT_mitt,
					ac_GT_dest);
		}

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		// Fred - 24/08/2012
		//Set SSN value from inifile if it has been configured otherwise get default SSN = 6 ( HLR)
		routeReadable.cd_addr.ssn = GetDefaultSSN();
		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );

		if(!i_ret)
		{
			memset(&transId,0x00, sizeof(transactionId));
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			memcpy( &transId,
					(char *)ExternalReference->ac_transaction,
					sizeof(ExternalReference->ac_transaction) );

			dialogue.choice                 = send_dlg_abort;
			dialogue.abort_source           = 0x00;   // Dialogue Service User
			dialogue.is_userInfo_present    = userInfo_yes;
			dialogue.userInformation.map_DialoguePDU.choice = MapDialoguePDU_mapUserAbort_chosen;
			dialogue.userInformation.map_DialoguePDU.u.mapUserAbort.choice = MapUserAbort_userResourceLimitation_chosen;

			log_(LOG_DEBUG,"%s: TCAP User Abort2 req. from TS: Cg[%s:%d] - Cd[%s:%d]",
					__FUNCTION__,
					ac_GT_mitt,
					routeReadable.cd_addr.ssn,
					ac_GT_dest,
					routeReadable.cg_addr.ssn);

			i_ret = FW2_TCAP_Send_U_Abort ( routeinfop,
											&transId,
											&dialogue );

			if(i_ret)
			{
				EVT_manage( EVTN_REQ_USER_ABORT_ERROR,
							0,
							i_interval_time,
							'A',
							"TCAP User Abort failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
							i_ret,
							ac_GT_mitt,
							routeReadable.cd_addr.ssn,
							ac_GT_dest,
							routeReadable.cg_addr.ssn );

				log_(LOG_ERROR,"%s: TCAP User Abort failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
						__FUNCTION__,
						i_ret,
						ac_GT_mitt,
						routeReadable.cd_addr.ssn,
						ac_GT_dest,
						routeReadable.cg_addr.ssn);
			}
		}
		else
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
	}
	else
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);

    return i_ret;
}

//
// sent TCAP_End with map error
//
short TCAP_Map_Error2( gtt_data *gtt )
{
    short           i_ret = 0;
    short           cmp_entries = 0;
    char            ac_GT_mitt[MAX_INS_STRING_LENGTH +1];
    char            ac_GT_dest[MAX_INS_STRING_LENGTH +1];
	EXTERNAL_REF	*ExternalReference;
    E2TCEL          cmp_elements[100];
    E2TCEL          *cmp_arrayp = &cmp_elements[0];
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;
    TCAPError       error;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)gtt->external_reference;

    i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		memset(ac_GT_mitt,0x00, sizeof(ac_GT_mitt));
		memset(ac_GT_dest,0x00, sizeof(ac_GT_dest));

		if( gtt->ResultCode == GTT_RESULT_SUCCESS )
		{
			routeReadable.cd_addr.Addr_ind.rout_ind  = '0';

			routeReadable.cd_addr.gt.NatureOfAddress = 0x04;
			routeReadable.cd_addr.gt.NumberingPlan   = 0x01;
			routeReadable.cd_addr.Addr_ind.gt_ind    = 4;

			memcpy( routeReadable.cd_addr.gt.address.value,
					gtt->query_response.address.value,
					gtt->query_response.address.length );

			routeReadable.cd_addr.gt.address.length = gtt->query_response.address.length;

			if(routeReadable.cd_addr.gt.address.length % 2)
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_ODD; // ODD
			else
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_EVEN; // EVEN

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );
		}
		else
		{
			AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_ERROR_FROM_GTT);

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );

			// Error from GTT
			EVT_manage( EVTN_GTT_ERR_MAP_ERROR2,
						0,
						i_interval_time,
						'A',
						"TCAP Map Error - GTT RsCode Err.[%d] - Cg[%s] - Cd[%s] - rout.unchanged",
						gtt->ResultCode,
						ac_GT_mitt,
						ac_GT_dest );

			log_(LOG_WARNING,"%s: TCAP Map Error - GTT RsCode Err.[%d] - Cg[%s] - Cd[%s]- rout.unchanged",
					__FUNCTION__,
					gtt->ResultCode,
					ac_GT_mitt,
					ac_GT_dest);
		}

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		// Fred - 24/08/2012
		//Set SSN value from inifile if it has been configured otherwise get default SSN = 6 ( HLR)
		routeReadable.cd_addr.ssn = GetDefaultSSN();
		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );
		
		if(!i_ret)
		{
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			log_(LOG_DEBUG,"%s: TCAP_Map_Error2 requested from TS: Cg[%s:%d] - Cd[%s:%d]",
					__FUNCTION__,
					ac_GT_mitt,
					routeReadable.cd_addr.ssn,
					ac_GT_dest,
					routeReadable.cg_addr.ssn);

			dialogue.choice = no_dlg;

			if( ExternalReference->c_map_version >= 0x02 )
			{
				dialogue.choice = send_dlg_response;
				dialogue.ac_len = 0x07;

				switch( ExternalReference->c_map_op_code )
				{
					case UpdateGSMLocation_Request_OperationCode:
					{
						if( ExternalReference->c_map_version == 2 )
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer2,
									dialogue.ac_len );
						}
						else if( ExternalReference->c_map_version == 3 )
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					case UpdateGPRSLocation_Request_OperationCode:
					{
						if( ExternalReference->c_map_version == 3 )
						{
							memcpy( dialogue.ac_name,
									AC_gprsLocationUpdateContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					default:
					{
						i_ret = 1;

						break;
					}
				}

				dialogue.is_userInfo_present = userInfo_no;
			}

			if( !i_ret )
			{
				memset(&transId,0x00, sizeof(transactionId));
				memset(&error,0x00, sizeof(TCAPError));

				memcpy( &transId,
						(char *)ExternalReference->ac_transaction,
						sizeof(ExternalReference->ac_transaction) );

				switch( gtt->c_tcap_map_errorcode )
				{
					case 0:
					case systemFailure_ErrorCode:
					{
						if(ExternalReference->c_map_version == 3)
							error.bit_mask = TCAP_Error_Parameter_ExtensibleSystemFailureParam_present;
						else
							error.bit_mask = TCAP_Error_Parameter_present; // MAP V1/2

						error.parameter.systemFailure = hlr;  // plmn = 0
															  // hlr = 1
															  // vlr = 2
															  // pvlr = 3
															  // controllingMSC = 4
															  // vmsc = 5
															  // eir = 6
															  // rss = 7

						error.errorCode = systemFailure_ErrorCode;  // = 34

						break;
					}

					case roamingNotAllowed_ErrorCode:
					{
						error.bit_mask 					  = TCAP_Error_Parameter_present;
						error.parameter.roamingNotAllowed = plmnRoamingNotAllowed; // plmnRoamingNotAllowed = 0
																				   // operatorDeterminedBarring = 3
						error.errorCode 				  = gtt->c_tcap_map_errorcode;

						break;
					}

					case absentSubscriber_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.absentSubscriber = hlr; // = 1
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}

					case callBarred_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.callBarred = operatorBarring; // operatorBarring = 1
																	  // barringServiceActive = 0
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}

					case cug_Reject_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.cug_Reject = incomingCallsBarredWithinCUG;	// incomingCallsBarredWithinCUG = 0,
																					// subscriberNotMemberOfCUG = 1,
																					// requestedBasicServiceViolatesCUG_Constraints = 5,
																					// calledPartySS_InteractionViolation = 7
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}

					case ss_SubscriptionViolation_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.ss_SubscriptionViolation.choice = cliRestrictionOption_chosen;
						error.parameter.ss_SubscriptionViolation.u.cliRestrictionOption = permanent;
						
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}
					
					case pw_RegistrationFailure_ErrorCode:
					{
						error.bit_mask = TCAP_Error_Parameter_present;
						error.parameter.pw_RegistrationFailure = undetermined; 
																	  
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}

					default:
					{
						error.errorCode =  gtt->c_tcap_map_errorcode;

						break;
					}
				}
				
				if(!i_ret)
				{
					EncodeTCAPError( &error,
									 ExternalReference->c_invoke_id,
									 &cmp_entries,
									 cmp_arrayp );

					i_ret = FW2_TCAP_SendEnd ( cmp_arrayp,
											   cmp_entries,
											   routeinfop,
											   &transId,
											   &dialogue );
				}
			}

			if(i_ret)
			{
				EVT_manage( EVTN_REQ_MAP_ERROR,
							0,
							i_interval_time,
							'A',
							"Map Error failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
							i_ret,
							ac_GT_mitt,
							routeReadable.cd_addr.ssn,
							ac_GT_dest,
							routeReadable.cg_addr.ssn );

				log_(LOG_ERROR,"%s: Map Error failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
						__FUNCTION__,
						i_ret,
						ac_GT_mitt,
						routeReadable.cd_addr.ssn,
						ac_GT_dest,
						routeReadable.cg_addr.ssn);
			}
			else
			{
				log_(LOG_DEBUG,"%s: Map Error sent successfully - Cg[%s:%d] - Cd[%s:%d] - Invoke_id[%d]",
							__FUNCTION__,
							ac_GT_mitt,
							routeReadable.cd_addr.ssn,
							ac_GT_dest,
							routeReadable.cg_addr.ssn,
							ExternalReference->c_invoke_id );
			}
		}
		else
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
	}
	else
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);

    return i_ret;
}

//
// sent TCAP_End with reject
//
short TCAP_Map_Reject2( gtt_data *gtt )
{
    short           i_ret = 0;
    short           cmp_entries = 0;
    char            ac_GT_mitt[MAX_INS_STRING_LENGTH +1];
    char            ac_GT_dest[MAX_INS_STRING_LENGTH +1];
	EXTERNAL_REF	*ExternalReference;
    E2TCEL          cmp_elements[100];
    E2TCEL          *cmp_arrayp = &cmp_elements[0];
    transactionId   transId;
    US_Route_Info   routeReadable;
    FW_Route_Info   route_info;
    fw_route_infod  routeinfop = &route_info;
    dialogueStuff   dialogue;
    Reject          reject;

    memset(&routeReadable,0x00, sizeof(US_Route_Info));

	ExternalReference = (EXTERNAL_REF *)gtt->external_reference;

    i_ret = MTP3SCCP_DecodeRoutingInfo( &(ExternalReference->routeinfo),
										&routeReadable );

	if(!i_ret)
	{
		memset(ac_GT_mitt,0x00, sizeof(ac_GT_mitt));
		memset(ac_GT_dest,0x00, sizeof(ac_GT_dest));

		if( gtt->ResultCode == GTT_RESULT_SUCCESS )
		{
			routeReadable.cd_addr.Addr_ind.rout_ind     = '0';

			routeReadable.cd_addr.gt.NatureOfAddress    = 0x04;
			routeReadable.cd_addr.gt.NumberingPlan      = 0x01;
			routeReadable.cd_addr.Addr_ind.gt_ind       = 4;
			
			memcpy( routeReadable.cd_addr.gt.address.value,
					gtt->query_response.address.value,
					gtt->query_response.address.length );

			routeReadable.cd_addr.gt.address.length = gtt->query_response.address.length;

			if(routeReadable.cd_addr.gt.address.length % 2)
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_ODD; // ODD
			else
				routeReadable.cd_addr.gt.EncodingScheme = GT_ES_BCD_EVEN; // EVEN

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );
		}
		else
		{
			AddStat(STAT_MAPIRO_PREFIX_REGS,"MAPOUT",TOT_ERROR_FROM_GTT);

			memcpy( ac_GT_mitt,
					routeReadable.cd_addr.gt.address.value,
					routeReadable.cd_addr.gt.address.length );

			memcpy( ac_GT_dest,
					routeReadable.cg_addr.gt.address.value,
					routeReadable.cg_addr.gt.address.length );

			// Error from GTT
			EVT_manage( EVTN_GTT_ERR_REJECT2,
						0,
						i_interval_time,
						'A',
						"TCAP Map Reject2 - GTT RsCode Err.[%d]- Cg[%s] - Cd[%s] - Rout.unchanged",
						gtt->ResultCode,
						ac_GT_mitt,
						ac_GT_dest );

			log_(LOG_ERROR,"%s: TCAP Map Reject2 - GTT RsCode Err.[%d]- Cg[%s] - Cd[%s] - Rout.unchanged",
					__FUNCTION__,
					gtt->ResultCode,
					ac_GT_mitt,
					ac_GT_dest);
		}

		if( routeReadable.cg_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cg_addr.Addr_ind.pc_ind = '0';

		if( routeReadable.cd_addr.Addr_ind.pc_ind == '1' )
			routeReadable.cd_addr.Addr_ind.pc_ind = '0';

		// Fred - 24/08/2012
		//Set SSN value from inifile if it has been configured otherwise get default SSN = 6 ( HLR)
		routeReadable.cd_addr.ssn = GetDefaultSSN();
		i_ret = MTP3SCCP_EncodeRoutingInfo( routeinfop,
											&routeReadable );

		if(!i_ret)
		{
			memset(&dialogue,0x00, sizeof(dialogueStuff));

			log_(LOG_DEBUG,"%s: TCAP_Map_Reject2 requested from TS: Cg[%s:%d] - Cd[%s:%d]",
					__FUNCTION__,
					ac_GT_mitt,
					routeReadable.cd_addr.ssn,
					ac_GT_dest,
					routeReadable.cg_addr.ssn);

			dialogue.choice = no_dlg;

			if( ExternalReference->c_map_version >= 0x02 )
			{
				dialogue.choice = send_dlg_response;
				dialogue.ac_len = 0x07;

				switch( ExternalReference->c_map_op_code )
				{
					case UpdateGSMLocation_Request_OperationCode:
					{
						if( ExternalReference->c_map_version == 2 )
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer2,
									dialogue.ac_len );
						}
						else if( ExternalReference->c_map_version == 3 )
						{
							memcpy( dialogue.ac_name,
									AC_networkLocUpContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					case UpdateGPRSLocation_Request_OperationCode:
					{
						if( ExternalReference->c_map_version == 3 )
						{
							memcpy( dialogue.ac_name,
									AC_gprsLocationUpdateContextPackageVer3,
									dialogue.ac_len );
						}
						else
							i_ret = 1;

						break;
					}

					default:
					{
						i_ret = 1;

						break;
					}
				}

				dialogue.is_userInfo_present = userInfo_no;
			}

			if( !i_ret )
			{
				memset(&transId,0x00, sizeof(transactionId));
				memset(&reject,0x00, sizeof(Reject));

				memcpy( &transId,
						(char *)ExternalReference->ac_transaction,
						sizeof(ExternalReference->ac_transaction) );

				reject.choice           = generalProblem_chosen;
				reject.u.generalProblem = unrecognizedComponent;

				EncodeTCAPReject( &reject,
								  ExternalReference->c_invoke_id,
								  &cmp_entries,
								  cmp_arrayp );

				i_ret = FW2_TCAP_SendEnd ( cmp_arrayp,
										   cmp_entries,
										   routeinfop,
										   &transId,
										   &dialogue );
			}
			else
			{
				EVT_manage( EVTN_REQ_MAP_REJECT_ERROR,
							0,
							i_interval_time,
							'A',
							"TCAP Reject failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
							i_ret,
							ac_GT_mitt,
							routeReadable.cd_addr.ssn,
							ac_GT_dest,
							routeReadable.cg_addr.ssn );

				log_(LOG_ERROR,"%s: TCAP Reject failure - Err.[%d] - Cg[%s:%d] - Cd[%s:%d]",
						__FUNCTION__,
						i_ret,
						ac_GT_mitt,
						routeReadable.cd_addr.ssn,
						ac_GT_dest,
						routeReadable.cg_addr.ssn);
			}
		}
		else
			log_(LOG_ERROR,"%s: Err.[%d] Encoding modified routing",
					__FUNCTION__,
					i_ret);
	}
	else
		log_(LOG_ERROR,"%s: Err.[%d] Decoding routing - Bad routing",
				__FUNCTION__,
				i_ret);

    return i_ret;
}

//
// Allow or Prohibit access to VPC
//
short VPC_Status( VPC_STATUS *vpc_status )
{
    short   i_ret = 0;

    switch( vpc_status->i_mode )
    {
        case VPC_UP:
        {
            i_ret = L_SS7_VPC_ALLOW( vpc_status->ac_net_name,
                                     vpc_status->i_net_id,
                                     vpc_status->i_vpc );

            break;
        }

        case VPC_DOWN:
        {
            i_ret = L_SS7_VPC_PROHIBIT( vpc_status->ac_net_name,
                                        vpc_status->i_net_id,
                                        vpc_status->i_vpc );

            break;
        }
    }

    return i_ret;
}

long GetValidDestPC( VPC_STATUS *vpc_status,
                     short DPC_list_entries,
                     long *DPC,
                     short i_internal_routing_strategy )
{
    short           i_err = 0;
    short    		_dpcindx;
    static short    dpcindx = 0;
    unsigned char   PtCodeStatus[5];
    int             i;

    PtCodeStatus[0] = P2_SS7_UNAVAILABLE;

    for ( i=0; i < DPC_list_entries; i++ )
    {
        i_err = L_SS7_PC_STATUS( ,
        						 vpc_status->i_net_id,
                                 (unsigned long) DPC[dpcindx],
                                 PtCodeStatus );

        if ( i_err != P2_SS7_REC_FND )    // if err > 0 it contains the buff len
        {
            ++dpcindx;
            dpcindx %= DPC_list_entries;
        }
        else
        {
            if ( PtCodeStatus[0] != P2_SS7_AVAILABLE )     // Traffic prohibited
            {
            	if( i_internal_routing_strategy == NO_INTERNAL_ROUTING_STRATEGY &&
            		vpc_status->i_vpc )
            	{
					++dpcindx;
					dpcindx %= DPC_list_entries;
            	}
            	else
            	{
            		PtCodeStatus[0] = P2_SS7_AVAILABLE;

            		_dpcindx = dpcindx;

            		++dpcindx;
            		dpcindx %= DPC_list_entries;

            		break;
            	}
            }
            else
            {
            	_dpcindx = dpcindx;

            	++dpcindx;
            	dpcindx %= DPC_list_entries;

                break;
            }
        }
    }

    if ( PtCodeStatus[0] == P2_SS7_UNAVAILABLE )
    {
        EVT_manage( EVTN_POINT_CODE_UNAVAILABLE,
					0,
					0,
					'A',
					"All Dest. PointCode unavailable" );

        return(-1);
    }

    return(DPC[_dpcindx]);
}

long GetDualImsiVDestPC( VPC_STATUS *vpc_status,
                     	 short DPC_list_entries,
                     	 long *DPC,
                     	 short i_internal_routing_strategy )
{
    short           i_err = 0;
    short    		_dpcindx;
    static short    dpcindx = 0;
    unsigned char   PtCodeStatus[5];
    int             i;

    PtCodeStatus[0] = P2_SS7_UNAVAILABLE;

    for ( i=0; i < DPC_list_entries; i++ )
    {
        i_err = L_SS7_PC_STATUS( ,
        						 vpc_status->i_net_id,
                                 (unsigned long) DPC[dpcindx],
                                 PtCodeStatus );

        if ( i_err != P2_SS7_REC_FND )    // if err > 0 it contains the buff len
        {
            ++dpcindx;
            dpcindx %= DPC_list_entries;
        }
        else
        {
            if ( PtCodeStatus[0] != P2_SS7_AVAILABLE )     // Traffic prohibited
            {
            	if( i_internal_routing_strategy == NO_INTERNAL_ROUTING_STRATEGY &&
            		vpc_status->i_vpc )
            	{
					++dpcindx;
					dpcindx %= DPC_list_entries;
            	}
            	else
            	{
            		PtCodeStatus[0] = P2_SS7_AVAILABLE;

            		_dpcindx = dpcindx;

            		++dpcindx;
            		dpcindx %= DPC_list_entries;

            		break;
            	}
            }
            else
            {
            	_dpcindx = dpcindx;

            	++dpcindx;
            	dpcindx %= DPC_list_entries;

                break;
            }
        }
    }

    if ( PtCodeStatus[0] == P2_SS7_UNAVAILABLE )
    {
        EVT_manage( EVTN_POINT_CODE_UNAVAILABLE,
					0,
					0,
					'A',
					"All Dest. PointCode unavailable" );

        return(-1);
    }

    return(DPC[_dpcindx]);
}

//
// 0 - Not available
// 1 - available
//
short CheckDPC( unsigned short i_net_id,
   	    	    unsigned long L_DPC )
{
    short           i_err = 0;
    short			i_ret = 0;
    unsigned char   PtCodeStatus[5];

    PtCodeStatus[0] = P2_SS7_UNAVAILABLE;

    i_err = L_SS7_PC_STATUS( ,
       						 i_net_id,
       						 L_DPC,
                             PtCodeStatus );

    if ( i_err == P2_SS7_REC_FND )    				// if err > 0 it contains the buff len
    {
		if ( PtCodeStatus[0] == P2_SS7_AVAILABLE )  // Traffic available
		{
			i_ret = 1;
		}
		else
		{
			log_(LOG_ERROR,"%s: Destination PC[%Ld] unavailable",
					__FUNCTION__,
					L_DPC);

			EVT_manage( EVTN_POINT_CODE_UNAVAILABLE,
						0,
						0,
						'A',
						"Dest. PC[%Ld] unavailable",
						L_DPC );
		}
	}

    return(i_ret);
}

// -------------------------------------------------------------------------------------------------
//	3.12	Return cause
//		from ITU-T Q.713 Specifications of Signalling System No. 7
//		Signalling Connection Control Part (SCCP)
//
//	In the unitdata service or extended unitdata service or long unitdata service message,
//	the "return cause" parameter field is a one octet field containing the reason for message return.
//	Bits 1-8 are coded as follows:
//
//	0x00 "no translation for an address of such nature"
//	0x01 "no translation for this specific address"
//	0x02 "subsystem congestion"
//	0x03 "subsystem failure"
//	0x04 "unequipped user"
//	0x05 "MTP failure"
//	0x06 "network congestion"
//	0x07 "unqualified"
//	0x08 "error in message transport (XUDTS)"
//	0x09 "error in local processing (XUDTS)"
//	0x0a "destination cannot perform reassembly (XUDTS)"
//	0x0b "SCCP failure"
//	0x0c "hop counter violation"
//	0x0d "segmentation not supported"
//	0x0e "segmentation failure"
// -------------------------------------------------------------------------------------------------

//  ------------------------------------------------------------------------------------------
// 3.12	Return cause
// In the unitdata service or extended unitdata service or long unitdata
// service message, the "return cause" parameter field is a one octet field containing
// the reason for message return. Bits 1-8 are coded as follows:
//
// Bits
// 8 7 6 5 4 3 2 1
//
// 0 0 0 0 0 0 0 0 no translation for an address of such nature
// 0 0 0 0 0 0 0 1 no translation for this specific address
// 0 0 0 0 0 0 1 0 subsystem congestion
// 0 0 0 0 0 0 1 1 subsystem failure
// 0 0 0 0 0 1 0 0 unequipped user
// 0 0 0 0 0 1 0 1 MTP failure
// 0 0 0 0 0 1 1 0 network congestion
// 0 0 0 0 0 1 1 1 unqualified
// 0 0 0 0 1 0 0 0 error in message transport (Note)
// 0 0 0 0 1 0 0 1 error in local processing (Note)
// 0 0 0 0 1 0 1 0 destination cannot perform reassembly (Note)
// 0 0 0 0 1 0 1 1 SCCP failure
// 0 0 0 0 1 1 0 0 hop counter violation
// 0 0 0 0 1 1 0 1 segmentation not supported
// 0 0 0 0 1 1 1 0 segmentation failure
//
// 0 0 0 0 1 1 1 1
// to               spare
// 1 1 1 1 1 1 1 1
//
// (Note) - Only applicable to XUDT(S) message.
//  ------------------------------------------------------------------------------------------
void composeUDTSHeaderInfo( char *ac_outbuf_hex,
							short outbuflen,
							char *sccpaggr )
{
	int 			offset = 0,i,j;
	char 			mtp3flip[4];
	char			ac_udt_out[512];
	udtsHeaderInfo 	udtsHeader;

	offset+=4;
	for(i=3,j=0;i>=0;i--,j++)
		mtp3flip[i] = sccpaggr[offset+j];

	memcpy( (char *) &udtsHeader.mtp3,
			mtp3flip,
			sizeof(mtp3flip) );

	offset+=5;

	udtsHeader.returncause = sccpaggr[offset];

	if(udtsHeader.messagetype == XUDTS)
		log_(LOG_ERROR,"%s: Unexpected XUDTS received",__FUNCTION__);

	switch(udtsHeader.returncause)
	{
		case 0x00:
		{
			strcpy(udtsHeader.retcausereadable,"[No translation for an address of such nature]");

			break;
		}

		case 0x01:
		{
			strcpy(udtsHeader.retcausereadable,"[No translation for this specific address]");

			break;
		}

		case 0x02:
		{
			strcpy(udtsHeader.retcausereadable,"[Subsystem congestion]");

			break;
		}

		case 0x03:
		{
			strcpy(udtsHeader.retcausereadable,"[Subsystem failure]");

			break;
		}

		case 0x04:
		{
			strcpy(udtsHeader.retcausereadable,"[Unequipped user]");

			break;
		}

		case 0x05:
		{
			strcpy(udtsHeader.retcausereadable,"[MTP failure]");

			break;
		}

		case 0x06:
		{
			strcpy(udtsHeader.retcausereadable,"[Network congestion]");

			break;
		}

		case 0x07:
		{
			strcpy(udtsHeader.retcausereadable,"[Unqualified]");

			break;
		}

		case 0x08:
		{
			strcpy(udtsHeader.retcausereadable,"[Error in message transport (XUDTS only)]");

			break;
		}

		case 0x09:
		{
			strcpy(udtsHeader.retcausereadable,"[Error in local processing (XUDTS only)]");

			break;
		}

		case 0x0A:
		{
			strcpy(udtsHeader.retcausereadable,"[Destination cannot perform reassembly (XUDTS only)]");

			break;
		}

		case 0x0B:
		{
			strcpy(udtsHeader.retcausereadable,"[SCCP failure]");

			break;
		}

		case 0x0C:
		{
			strcpy(udtsHeader.retcausereadable,"[Hop counter violation)");

			break;
		}

		case 0x0D:
		{
			strcpy(udtsHeader.retcausereadable,"[Segmentation not supported]");

			break;
		}

		case 0x0E:
		{
			strcpy(udtsHeader.retcausereadable,"[Segmentation failure]");

			break;
		}

		default:
		{
			strcpy(udtsHeader.retcausereadable,"[Spare]");

			break;
		}
	}

	sprintf( ac_udt_out, "DPC[%d] - OPC[%d] - Return cause[%d] - %s",
			 udtsHeader.mtp3.dpc,
			 udtsHeader.mtp3.opc,
			 udtsHeader.returncause,
			 udtsHeader.retcausereadable );

	log_(LOG_WARNING,"%s: UDTS: raw msg recv.[%s] - [%d]",
			__FUNCTION__,
			ac_outbuf_hex,
			outbuflen);

	log_(LOG_WARNING,"%s: UDTS: %s",
			__FUNCTION__,
			ac_udt_out);

	return;
}

// *******************************************************************************************

short checkChgFile( char *ac_path_file_ini_oss )
{
	short			ret = 0;
	struct stat		stat_file;
	static time_t	time_lastup = 0;

	lstat(ac_path_file_ini_oss, &stat_file);

	if ( time_lastup != stat_file.st_mtime )
	{
		time_lastup = stat_file.st_mtime;
		ret = 1;
	}

	return ret;
}

// ---------------------------------------------------------------------------------
void setChgFile( char *g_ini_file,
				 char *ac_path_file_ini_oss )
{
	char	ac_wrk_str[64];
	char	*wrk_str;

	// Compose OSS filename for reload check
	if ( *g_ini_file == '\\' )
	{
		//
		// Remote file
		//
		strcpy(ac_wrk_str, g_ini_file+1);
		wrk_str = strtok(ac_wrk_str, ".");
		sprintf(ac_path_file_ini_oss,"/E/%s/G/%s", wrk_str, ac_wrk_str+strlen(ac_wrk_str)+2);
	}
	else
	{
		//
		// Local file
		//
		sprintf(ac_path_file_ini_oss,"/G/%s", g_ini_file+1);
	}

	while ( (wrk_str = strchr(ac_path_file_ini_oss,'.')) )
		*wrk_str = '/';
}

//------------------------------------------------------------------------------------------------------------
void LogRouteInfo( US_Route_Info *rinfo,
				   short i_trace_level,
 				   char *ac_txt )
{
    char    ac_mtp2[4];
    char    ac_aggr[65];
    char    ac_hex[255];

    memset( ac_mtp2,
    		0x00,
			sizeof(ac_mtp2) );

    memset( ac_aggr,
    		0x00,
			sizeof(ac_aggr) );

    memset( ac_hex,
    		0x00,
			sizeof(ac_hex) );

    if( rinfo->mtp2Len <= sizeof(ac_mtp2) )
    {
		memcpy( ac_mtp2,
				rinfo->mtp2,
				rinfo->mtp2Len);
    }

    if( rinfo->aggrLen <= sizeof(ac_aggr) )
    {
		memcpy( ac_aggr,
				rinfo->aggr,
				rinfo->aggrLen);

		Asc2Hex( (unsigned char *)ac_aggr,
				 ac_hex,
				 (int)strlen(ac_aggr) );
    }

	log_(i_trace_level,"Routing: ************************************************");
	log_(i_trace_level,"Routing: *** [%s]",ac_txt);
    log_(i_trace_level,"Routing: ************************************************");
    log_(i_trace_level,"Routing: View                        : %d",rinfo->view);
    log_(i_trace_level,"Routing: Bit_mask                    : %2.2X",rinfo->bit_mask);
    log_(i_trace_level,"Routing: Mtp3 Orig                   : %d",rinfo->mtp3_opc);
    log_(i_trace_level,"Routing: Mtp3 Dest                   : %d",rinfo->mtp3_dpc);
    log_(i_trace_level,"Routing: Sls                         : %2.2X",rinfo->sls);
    log_(i_trace_level,"Routing: Mtp2                        : %d",(short)atoi(ac_mtp2));
    log_(i_trace_level,"Routing: Aggr                        : %s",ac_hex);
    log_(i_trace_level,"Routing: SCCP_msg_type               : %d",rinfo->SCCP_msg_type);
    log_(i_trace_level,"Routing: SCCP_prot_class             : %d",rinfo->SCCP_prot_class);
    log_(i_trace_level,"Routing: SCCP_prot_opts              : %d",rinfo->SCCP_prot_opts);
    log_(i_trace_level,"Routing: *********************************");
    log_(i_trace_level,"Routing: Cd_address                  : %*.s",rinfo->cd_addr.gt.address.length,rinfo->cd_addr.gt.address.value);
    log_(i_trace_level,"Routing:      |Cd EncodingScheme     : %d",rinfo->cd_addr.gt.EncodingScheme);
    log_(i_trace_level,"Routing:      |Cd NumberingPlan      : %d",rinfo->cd_addr.gt.NumberingPlan);
    log_(i_trace_level,"Routing:      |Cd TranslationType    : %d",rinfo->cd_addr.gt.TranslationType);
    log_(i_trace_level,"Routing:      |Cd NatureOfAddress    : %d",rinfo->cd_addr.gt.NatureOfAddress);
    log_(i_trace_level,"Routing:      |Cd routing_ind        : %d",rinfo->cd_addr.routing_ind);
    log_(i_trace_level,"Routing:      |Cd ssn                : %d",rinfo->cd_addr.ssn);
    log_(i_trace_level,"Routing:      |Cd pc                 : %d",rinfo->cd_addr.pc);
    log_(i_trace_level,"Routing:      |Cd pc_ind             : %2.2X",rinfo->cd_addr.Addr_ind.pc_ind);
    log_(i_trace_level,"Routing:      |Cd ssn_ind            : %2.2X",rinfo->cd_addr.Addr_ind.ssn_ind);
    log_(i_trace_level,"Routing:      |Cd gt_ind             : %d",rinfo->cd_addr.Addr_ind.gt_ind);
    log_(i_trace_level,"Routing:      |Cd rout_ind           : %2.2X",rinfo->cd_addr.Addr_ind.rout_ind);
    log_(i_trace_level,"Routing:      |Cd rs_national        : %2.2X",rinfo->cd_addr.Addr_ind.rs_national);
    log_(i_trace_level,"Routing: *********************************");
    log_(i_trace_level,"Routing: Cg_address                  : %*.s",rinfo->cg_addr.gt.address.length,rinfo->cg_addr.gt.address.value);
    log_(i_trace_level,"Routing:      |Cg EncodingScheme     : %d",rinfo->cg_addr.gt.EncodingScheme);
    log_(i_trace_level,"Routing:      |Cg NumberingPlan      : %d",rinfo->cg_addr.gt.NumberingPlan);
    log_(i_trace_level,"Routing:      |Cg TranslationType    : %d",rinfo->cg_addr.gt.TranslationType);
    log_(i_trace_level,"Routing:      |Cg NatureOfAddress    : %d",rinfo->cg_addr.gt.NatureOfAddress);
    log_(i_trace_level,"Routing:      |Cg routing_ind        : %d",rinfo->cg_addr.routing_ind);
    log_(i_trace_level,"Routing:      |Cg ssn                : %d",rinfo->cg_addr.ssn);
    log_(i_trace_level,"Routing:      |Cg pc                 : %d",rinfo->cg_addr.pc);
    log_(i_trace_level,"Routing:      |Cg pc_ind             : %2.2X", rinfo->cg_addr.Addr_ind.pc_ind);
    log_(i_trace_level,"Routing:      |Cg ssn_ind            : %2.2X",rinfo->cg_addr.Addr_ind.ssn_ind);
    log_(i_trace_level,"Routing:      |Cg gt_ind             : %d",rinfo->cg_addr.Addr_ind.gt_ind);
    log_(i_trace_level,"Routing:      |Cg rout_ind           : %2.2X",rinfo->cg_addr.Addr_ind.rout_ind);
    log_(i_trace_level,"Routing:      |Cg rs_national        : %2.2X",rinfo->cg_addr.Addr_ind.rs_national);
    log_(i_trace_level,"Routing: ************************************************");
    log_(i_trace_level,"Routing: ************************************************");
}

/* ------------------------------------------------------------------------------------------------- */

