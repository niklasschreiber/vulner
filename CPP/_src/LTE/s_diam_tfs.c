// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s_diam_tfs.c
//   Last Change : 28-03-2017
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
//	23-10-2012: created
//  02-07-2014: Compiled for RVU 09.00
//  09-07-2014: Managed news diameter errors for steering
//				Added always redirect strategy flag
//  18-02-2015: KTSTEADC - Update Location Answer - Set E-flag to 0 for permanent failure error code (>= 5000) in complete compliance with RFC 3588
//  26-04-2016: Compiled for RVU 09.01
//  19-12-2016: KTSTEADN - Bug Fixing output buffer size to 8 byte from 6 for L_PUT_ROUTING_INFO()
//  31-03-2017: RVUA10
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------

// ---------------------< Include files >----------------------------------------
/**
 * \file
 *
 * EIR - LTE S6a/S6d
 *
 *
 */
#pragma nolist
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/param.h>
#include <netinet/in.h>
#include <p2system.p2apdfh>
#include <p2system.insdiah>
#include <p2system.insiph>
#include <cssinc.cext>
#include <cextdecs.h>
#include <ssplog.h>
#include <sspstat.h>
#include <sspevt.h>
#include <sspfunc.h>
#include <maputil.h>
#include <diam.h>
#include <diam_api.h>
#include <diam_epc.h>
#include <session.h>
#include <usrlib.h>
#include <mbedb.h>
#include "s6astat.h"
#include "diams6a.h"
#include "s6aevt.h"
#include "s6afunc.h"
#include "s6aipc.h"
#include "ctxl.h"
#include "gttltedb.h"
#include "mbewrapper.h"
#pragma list

//---------------------< Definitions >-----------------------------------------

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

//---------------------< External Function Prototypes >----------------------
//---------------------< Internal Function Prototypes >----------------------
void Process_Initialization( void );

void Open_Receive_MTS( void );

void Msg_print( short i_type );

short handleSystemMessage ( char *ac_buff );

short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag );

void handleEvent ( char *ac_buff,
				   short i_buffLen );

short OpenMBEdb( void );

void CloseAllDB( void );

int Get_FQDN_redirect_Host ( INS_String *imsi,
		 	 	 	 	 	 char *ac_fqdn_redirect_host );

short LoadParameters( char *ac_PathCfgF,
					  short i_reload );

DIAMessage *Decode_Request ( char *ac_buff,
					  	  	 unsigned int i_buf_len,
					  	  	 unsigned int *i_diam_error_code,
					  	  	 ULR *ulr );

int SendULA( DIAMessage *dreq,
			 unsigned int i_diameter_result_code,
			 unsigned int i_diameter_exp_result_code,
			 dp_config *config,
			 int i_ula_type,
			 INS_String *imsi,
			 char *ac_visited_PLMN_Id,
			 char *diaSessionInfo,
			 short diaSessInfoLen );

short SendTFSMGR( ULR *ulr,
				  TFS_CTX *tfs_ctx,
				  long l_ctx_tag );

DIAMessage *build_ULA( DIAMessage *req,
					   unsigned int i_diameter_result_code,
					   unsigned int i_diameter_exp_result_code,
					   INS_String *imsi,
					   int i_ula_type,
					   int *i_ula_type_chg,
					   dp_config *config );

static short IsImsiNum( char *str,
					    int i_len );

short RetrieveAndReleaseCtx( long ltag,
							 TFS_CTX *tfs_ctx );

static short V_PLMN_Id_Decode( unsigned char *ac_visited_plmn_id,
							   int i_visited_plmn_id_len,
							   char *ac_mcc_mnc );

void PrintOpenEvent (PEER_AVAILABLE_EVENT* aSerMsg);

void PrintCloseEvent (PEER_UNAVAILABLE_EVENT* aSerMsg);

// -------------------------------------------------------------------------

//---------------------< External Variables >--------------------------------
//---------------------< Static and Global Variables >-----------------------
short				diaSessInfoLen;
short	 			i=0; // idx for FQDN Redirect Host
short				i_fd_db_imsi;
short				i_fd_db_hss;
static char			ac_mts_buff[DIA_MTS_BUFFER_SIZE];
char				*diaSessionInfo;
IO_CTRL_COMMON_BLK  ReceiveIO;
DIAMessage 			*dreq;
DIAMessage 			*dans;
DIAMsgIdentifier 	hopbyhop_id;
DIAMsgIdentifier 	endtoend_id;
dp_config       	*p_conf;

//---------------------< Static and Global Variables End >-----------------------

int main( int argc, char **argv )
{
    short 					bufferLength;
    short					Stop=0;
    short 					count = 0;
    short 					length;
	short 					rcvError;
	short 					lvErr = 0;
	short					i_release_ctx = 0;
	short					i_subsystem_id;
    int						i_time_res = 0;
    int 					i_err = 0;
    unsigned int			i_diameter_error = 0;
    long 					protocol;
    long					l_tag;
    dia_indication_t 		indication;
    ULR						ulr;
    TFS_CTX					tfs_ctx;
    TFS_LTE_IPC				*tfs_msg;
    EXTERNAL_REF			*ext;

    DELAY(1000);

    Process_Initialization();

    log_(LOG_DEBUG2,"%s: Sizeof TFS_LTE_IPC[%d] - EXTERNAL_REF[%d]",
    			__FUNCTION__,
    			sizeof(TFS_LTE_IPC),
    			sizeof(EXTERNAL_REF));

    Open_Receive_MTS();

    //
    // Find out the size of the Session-info.
    // This is a one-time call and can be re-used
    // during the life of the program.
    //
    diaSessInfoLen = L_DIA_GET_SESSION_INFO_SIZE();

    //
    //  Create a generic MTS address for outbound Diameter messages.
    //
	i_err = L_PUT_ROUTING_INFO( P2_TPT_DIAMETER_PROT,
								(void *) ac_mts_buff,
								sizeof (ac_mts_buff),
								sizeof (ac_mts_buff),
								&count);

	if ( i_err)
	{
		Stop = 1;

		log_(LOG_ERROR,"%s: Err.[%d] - L_PUT_ROUTING_INFO()",
				__FUNCTION__,
				i_err);
	}
	else
	{
		//
		// Necessary to initialize HopByHop/EndToEnd values
		//
		InitMsgIdentifier ( i_my_cpu,
							i_my_tid,
							c_srv_id );

		// set timer for bump stat
	    if( SetTimerBump_(l_stat_bump_interval,TAG_BUMP ) )
		{
			EVT_manage( EVTN_ERR_SIGNALTIMEOUT_SET,
						0,
						i_interval_time,
						'A',
						"SIGNALTIMEOUT error - Bump Stat" );
		}
	}

    //
    // This program performs as a server. It means it loops
    // forever, receiving MTS messages, and reacting
    // and/or responding to those messages. It also creates
    // a new outbound message.
    //
    while( !Stop )
    {
        if ( (rcvError = RECEIVE_ ( ReceiveIO.buffer,
        						    sizeof(ReceiveIO.buffer),
        						    &bufferLength )) != P2_G90_FEOK )
        {
            if ( rcvError != P2_G90_FESYSMESS )
            {
            	Stop = 1;

                log_(LOG_ERROR,"%s: Err.[%d] - RECEIVE_()",
                		__FUNCTION__,
                		rcvError);
            }
            else
            {
            	Stop = handleSystemMessage( ReceiveIO.buffer );
            }
        }
        else
        {
            //
            // A data message was received, so now determine if the
            // message type or protocol is Diameter by retrieving the
            // protocol token and then testing it for
            // the Diameter protocol.
            //
            if (!(i_err = L_GET_ROUTING_INFO ( P2_TPT_IDENTIFY_PROTOCOL,
                                               &protocol,
                                               sizeof (protocol),
                                               &length )))
            {
                if ( protocol == P2_TPT_DIAMETER_PROT )
                {
                    //
                    // The protocol is Diameter, so now determine how to
                    // examine the message by fetching the indication from
                    // the message and process the message appropriately.
                    //
                    if ( !( i_err = L_DIA_GET_INDICATION_TYPE ( &indication ) ) )
                    {
                        switch ( indication )
                        {
                            case DIA_REQUEST:
                            {
                            	memset(&ulr,0x00,sizeof(ULR));

                            	dreq = Decode_Request ( ReceiveIO.buffer,
                            							bufferLength,
                            						  	&i_diameter_error,
                            						  	&ulr );

                            	if( dreq )
                            	{
                            		//
									// Allocate memory to save the Session-info.
									//
									if ((diaSessionInfo = (char*)calloc (1,diaSessInfoLen)) == NULL)
									{
										Stop = 1;
										log_(LOG_ERROR,"%s: Unable to get memory for session info - Exit forced",__FUNCTION__);
									}
									else
									{
										if( (lvErr = L_DIA_GET_SESSION_INFO( (dia_session_info_t *) diaSessionInfo,
																			 diaSessInfoLen)) )
										{
											log_(LOG_ERROR,"%s: Err.[%d] - L_DIA_GET_SESSION_INFO() failure - Diameter Answer[%d] discarded",
													__FUNCTION__,
													lvErr,
													dreq->commandCode);
										}
										else
										{
											if( i_diameter_error != DIAMETER_SUCCESS )
											{
												lvErr = SendULA( dreq,
																 i_diameter_error,
																 0,
																 p_conf,
																 ULA_ERROR,
																 &ulr.imsi,
																 ulr.ac_visited_PLMN_Id,
																 diaSessionInfo,
																 diaSessInfoLen );
											}
											else
											{
												lvErr = 0;

												if( !i_redirect_indication_flag )
												{
													memcpy( tfs_ctx.diaSessionInfo,
															(char *)diaSessionInfo,
															diaSessInfoLen );

													memcpy( &tfs_ctx.ulr_session,
															(char *)&ulr.ulr_session,
															sizeof(DiamIdent) );

													tfs_ctx.diaSessInfoLen 	= diaSessInfoLen;
													tfs_ctx.i_HbyH 	  	   	= dreq->hopbyhopId;
													tfs_ctx.i_EtoE         	= dreq->endtoendId;
													tfs_ctx.i_buff_orig_len = bufferLength;

													if( tfs_ctx.i_buff_orig_len <= MAX_DIAM_REQ_BUFF_LEN )
													{
														memcpy( tfs_ctx.ac_buff_orig,
																ReceiveIO.buffer,
																tfs_ctx.i_buff_orig_len );

														if( (lvErr = SaveCTX ( (char *)&tfs_ctx,
																			   &l_tag,
																			   sizeof(TFS_CTX) )) )
														{
															log_(LOG_ERROR,"%s: Err.[%d] SaveCTX()  - Redirection to perform",
																	__FUNCTION__,
																	lvErr);
														}
														else
														{
															i_release_ctx = 0;

															log_(LOG_DEBUG2,"%s: SaveCTX - Tag[0x%08X] - DIAM buff len [%d]",
																	__FUNCTION__,
																	l_tag,
																	tfs_ctx.i_buff_orig_len);

		//													lvErr = CTXSignalTimeout( l_tag,
		//																			  &i_CTX_Timeout,
		//																			  l_Timer_Waiting_tfsmgr_Resp,
		//																			  getretAddr() );
		//
		//													if(lvErr)
		//													{
		//														log_(LOG_ERROR,"CTXSignalTimeout err.[%d] - Redirection to perform",lvErr);
		//													}
		//													else
		//													{
																L_IP_RELEASE_BUFFERS();

																lvErr = SendTFSMGR( &ulr,
																					&tfs_ctx,
																					l_tag );

																if(lvErr)
																{
																	AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_REQ_TO_TFSMGR_KO);

																	i_release_ctx = 1;
																	log_(LOG_ERROR,"%s: Err.[%d] - MTS_SEND() to TFS-MGR failed",
																			__FUNCTION__,
																			lvErr);
																}
																else
																{
																	AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_REQ_TO_TFSMGR_OK);

																	L_DIA_PUT_CONTEXT_TAG(l_tag);
																	log_(LOG_DEBUG2,"%s: MTS_SEND to TFS-MGR successfully",__FUNCTION__);
																}
		//													}
														}

														if( i_release_ctx )
															CTXReleaseContext(l_tag);
													}
													else
													{
														log_(LOG_ERROR,"%s: Max Diameter Buffer len reached [%d] - Message has been discarded",
																__FUNCTION__,
																tfs_ctx.i_buff_orig_len);
													}
												}
												else
												{
													lvErr = 1; // Force redirect

													log_(LOG_WARNING,"%s: Redirect Indication Flag has been to always be forced to Redirect",
															__FUNCTION__);
												}

												if( lvErr )
												{
													lvErr = SendULA( dreq,
																	 DIA_REDIRECT_INDICATION,
																	 0,
																	 p_conf,
																	 ULA_REDIRECT,
																	 &ulr.imsi,
																	 ulr.ac_visited_PLMN_Id,
																	 diaSessionInfo,
																	 diaSessInfoLen );
												}
											}

											free(diaSessionInfo);
										}

										DIAFreeMessage(&dreq);
									}
                            	}
                            	else
                            	{
                            		log_(LOG_ERROR,"%s: Decode Diameter Request failure - Message has been discarded",
                            				__FUNCTION__);
                            	}
                                
                                break;
                            }
                            
                            case DIA_RESPONSE:
                            {
                            	log_(LOG_WARNING,"%s: Unexpected Diameter Answer Message received [%d]- Message has been discarded",
                            			__FUNCTION__,
                            			get_3bytes((char *)(&ReceiveIO.buffer[5])));
                                
                                break;
                            }
                            
                            case DIA_EVENT:
                            {
                            	handleEvent ( ReceiveIO.buffer,
                            				  bufferLength );

                                break;
                            }

                            case DIA_STATUS:
                            {
                            	log_(LOG_DEBUG2,"%s: Diameter Status",__FUNCTION__);

                            	break;
                            }

                            case DIA_IGNORE:
                            {
                            	log_(LOG_WARNING,"%s: Diameter Ignore",__FUNCTION__);

                            	break;
                            }
                        }
                    }
                    else
                    {
                    	log_(LOG_ERROR,"%s: L_DIA_GET_INDICATION_TYPE - Err.[%d]",
                    			__FUNCTION__,
                    			i_err);
                    }
                }
                else
                {
                	// Check IPC from TFS - Manager or TFS - Filter
                	if( bufferLength == sizeof(TFS_LTE_IPC) )
					{
						i_subsystem_id = *(short *)ReceiveIO.buffer;

						if( i_subsystem_id == TFS_LTE )
						{
							AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_RESP_FROM_TFSMGR_REC);

							log_(LOG_DEBUG2,"%s: RX msg from TFS-MGR",__FUNCTION__);

							tfs_msg = (TFS_LTE_IPC *)ReceiveIO.buffer;

							ext = (EXTERNAL_REF*)tfs_msg->external_reference;

							SetThroughputStat( ext->Ts_in,
											   ac_stat_reg_postfix );

							lvErr = RetrieveAndReleaseCtx( ext->l_ctx_tag,
														   &tfs_ctx );

							if( !lvErr )
							{
								DIAMessage *dreq = NULL;

								log_(LOG_DEBUG2,"%s: Retrieved CTX[0x%08X] successfully",
										__FUNCTION__,
										ext->l_ctx_tag);

								dreq = DIATranslateMessage( (unsigned char *)tfs_ctx.ac_buff_orig,
													        (unsigned int)tfs_ctx.i_buff_orig_len,
													         "",
													         ATTACH_SRC_BUFF ); // source buffer is attached to diameter msg structure

								if( dreq )
								{
									log_(LOG_DEBUG2,"%s: Originating ULR with CTX[0x%08X] has been re-translated correctly",
											__FUNCTION__,
											ext->l_ctx_tag);

									switch( tfs_msg->ResultType )
									{
										case 0: // REDIRECT
										{
											lvErr = SendULA( dreq,
															 DIA_REDIRECT_INDICATION,
															 0,
															 p_conf,
															 ULA_REDIRECT,
															 &tfs_msg->imsi,
															 tfs_msg->ac_visited_PLMN_Id,
															 ext->diaSessionInfo,
															 ext->diaSessInfoLen );

											break;
										}

										case 1: // STEERING
										{
											switch( tfs_msg->ResultCode )
											{
												case DIAMETER_UNABLE_TO_COMPLY:
												{
													lvErr = SendULA( dreq,
																	 DIAMETER_UNABLE_TO_COMPLY,
																	 0,
																	 p_conf,
																	 ULA_STEERING,
																	 &tfs_msg->imsi,
																	 tfs_msg->ac_visited_PLMN_Id,
																	 ext->diaSessionInfo,
																	 ext->diaSessInfoLen );
													break;
												}

												case RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED:
												{
													lvErr = SendULA( dreq,
																	 0,
																	 RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED,
																	 p_conf,
																	 ULA_STEERING,
																	 &tfs_msg->imsi,
																	 tfs_msg->ac_visited_PLMN_Id,
																	 ext->diaSessionInfo,
																	 ext->diaSessInfoLen );

													break;
												}

												default:
												{
													if( tfs_msg->ResultCode )
													{
														lvErr = SendULA( dreq,
																		 tfs_msg->ResultCode,
																		 0,
																		 p_conf,
																		 ULA_STEERING,
																		 &tfs_msg->imsi,
																		 tfs_msg->ac_visited_PLMN_Id,
																		 ext->diaSessionInfo,
																		 ext->diaSessInfoLen );
													}
													else
													{
														lvErr = SendULA( dreq,
																		 0,
																		 RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED,
																		 p_conf,
																		 ULA_STEERING,
																		 &tfs_msg->imsi,
																		 tfs_msg->ac_visited_PLMN_Id,
																		 ext->diaSessionInfo,
																		 ext->diaSessInfoLen );
													}

													break;
												}
											}

											break;
										}

										default:
										{
											log_(LOG_ERROR,"%s: RX wrong ResultType[%d] from TFS MGR - Redirect",
													__FUNCTION__,
													tfs_msg->ResultType);

											lvErr = SendULA( dreq,
															 DIA_REDIRECT_INDICATION,
															 0,
															 p_conf,
															 ULA_REDIRECT,
															 &tfs_msg->imsi,
															 tfs_msg->ac_visited_PLMN_Id,
															 ext->diaSessionInfo,
															 ext->diaSessInfoLen );

											break;
										}
									}

									DIAFreeMessage(&dreq);
								}
								else
									log_(LOG_ERROR,"%s: Re-translating originating ULR with CTX[0x%08X] failed - Message has been discarded",
											__FUNCTION__,
											ext->l_ctx_tag);
							}
							else
								log_(LOG_ERROR,"%s: Retrieve info associated with CTX[0x%08X] failure - Message has been discarded",
										__FUNCTION__,
										ext->l_ctx_tag);
						}
						else
							log_(LOG_WARNING,"%s: Wrong Subsystem id[%d] received",
									__FUNCTION__,
									i_subsystem_id);
					}
					else
						log_(LOG_WARNING,"%s: RX unexpected message - length[%d] - Msg has been discarded",
								__FUNCTION__,
								bufferLength);
                }
            }
            else
            	log_(LOG_ERROR,"%s: Err.[%d] - L_GET_ROUTING_INFO()",
            			__FUNCTION__,
            			i_err);
        }
    }

    i_time_res = BumpStat();

	if( i_time_res > 0 &&
		i_time_res <= 2 )
	{
		log_( LOG_DEBUG2, "%s: Bump Statistics before stop",__FUNCTION__ );
	}
	else
	{
		EVT_manage( EVTN_BUMP_ERROR,
					0,
					0,
					'A',
					"Bump Stat Err.[%d]",
					i_time_res );

		log_( LOG_ERROR, "%s: Err.[%d] - Bump Stat",
				__FUNCTION__,
				i_time_res);
	}

	Msg_print( _STOP_ );
	log_close();
	CloseAllDB();

	exit(0);
}

/** ---------------------------------------------------------------------------
*
* @param ac_msg	- in parameter - system message buffer
* \note Value Returned:
* \note       - 0 - OK
* \note
* -----------------------------------------------------------------------------
*/
short handleSystemMessage( char *ac_msg )
{
    short               i_res;
    short               i_ret = 0;
    short               *i_msg_id;
    long				i_tmp_reload_param;
    IO_SYS_TIMEOUT      *signal;
    SYS_COMMAND         *cmd;
    P2_CTX_TIMEOUT_DEF	*ctx_timeout;
    TFS_CTX				tfs_ctx;

    i_msg_id = (short *)ac_msg;

    switch( *i_msg_id )
    {
        case SYS_MSG_TIME_TIMEOUT:
        {
        	signal = (IO_SYS_TIMEOUT *)ac_msg;

            log_(LOG_DEBUG2,"%s: Sys. Timeout Message: Fd[%d] Tag[%ld]",
                    __FUNCTION__,
            		signal->i_par1,
                    signal->l_par2);

            switch ( signal->l_par2 )
            {
                case TAG_RELOAD_PARAM:
                {
                	if (checkChgFile( ac_filecfg_oss,0 ))
					{
						if( !LoadParameters(ac_filecfg,RELOAD) )
						{
							EVT_manage( EVTN_LOAD_PARAM_MISSING,
										0,
										i_interval_time,
										'A',
										"Missing parameter or fileini opened" );

							log_ (LOG_WARNING, "%s: Reloading parameters failed: parameter missing or fileini opened",__FUNCTION__);
						}
						else
							log_ (LOG_DEBUG2, "%s: Reloading parameters successfully",__FUNCTION__);
					}
					else
						log_ (LOG_DEBUG2, "%s: Reloading parameters not necessary",__FUNCTION__);

                    break;
                }

                case TAG_BUMP:
                {
                    // Bump
                    i_res = (short)BumpStat();
                    if( !i_res )
                        log_( LOG_DEBUG2, "%s: Bump Statistics",__FUNCTION__ );
                    else
                    {
                         EVT_manage( EVTN_BUMP_ERROR,
                         			 0,
                         			 0,
                         			 'A',
                         			 "Bump Stat Err.[%d]",
                         			 i_res );

                         log_( LOG_ERROR, "%s: Err.[%d] - Bump Stat",
                        		 __FUNCTION__,
                        		 i_res);
                    }

                    // set timer for bump stat
					if( SetTimerBump_(l_stat_bump_interval,TAG_BUMP ) )
					{
                    	EVT_manage( EVTN_ERR_SIGNALTIMEOUT_SET,
									0,
									i_interval_time,
									'A',
									"SIGNALTIMEOUT error - Bump Stat" );

                    	log_(LOG_ERROR,"%s: SIGNALTIMEOUT Err. - Bump Stat",__FUNCTION__ );
                    }

                    break;
                }
            }

            break;
        }

        case SYS_MSG_COMMAND:
		{
			cmd = (SYS_COMMAND *)ac_msg;

			switch(cmd->i_op)
			{
				case -1022:
				{
					//CTX_TIMEOUT
					log_(LOG_DEBUG2,"%s: CTX TIMEOUT RX",__FUNCTION__);

					ctx_timeout = (P2_CTX_TIMEOUT_DEF *)ac_msg;

					i_res = RetrieveAndReleaseCtx( ctx_timeout->tag,
												   &tfs_ctx );

					if(!i_res)
						log_(LOG_DEBUG2,"%s: Retrieve info associated with CTX[0x%08X] successfully",
								__FUNCTION__,
								ctx_timeout->tag);
					else
						log_(LOG_ERROR,"%s: Retrieve info associated with CTX[0x%08X] failure - Msg has been discarded",
								__FUNCTION__,
								ctx_timeout->tag);

					break;
				}

				default:
				{
					cmd->ac_cmd[cmd->i_cnt]=0;

					if( !strcmp(cmd->ac_cmd,"PARAMREFRESH") )
					{
						log_(LOG_DEBUG,"%s: REFRESHPARAM request RX",__FUNCTION__);

						i_tmp_reload_param = (long)(JULIANTIMESTAMP(0)%100);

						if( i_tmp_reload_param < 3 )
							i_tmp_reload_param = 3;

						// Shifting JULIANTIMESTAMP(0) + [3 - 33"]
						if( SIGNALTIMEOUT_((long)( 30 * i_tmp_reload_param ),0,TAG_RELOAD_PARAM) )
						{
							log_(LOG_ERROR,"%s: SIGNALTIMEOUT Err. - Reload param",__FUNCTION__ );

							EVT_manage( EVTN_CMD_REFRESH_PARAM_OK,
										0,
										0,
										'N',
										"REFRESHPARAM request RX" );
						}
					}
					else if( !strcmp(cmd->ac_cmd,"RESTART") )
					{
						i_ret = 1;
						log_(LOG_WARNING,"%s: RX RESTART param",__FUNCTION__ );
					}
					else
					{
						log_(LOG_ERROR,"%s: Unhandle cmd[%s] request RX",
								__FUNCTION__,
								cmd->ac_cmd);
					}

					break;
				}
			}

			break;
		}

        case SYS_MSG_STOP_1:
        case SYS_MSG_STOP_2:
        {
        	if( L_CHECKSTOP () )
        		i_ret = 1;

            break;
        }
    }

    return i_ret;

} // End Of Procedure

/**
 *  Management Diameter Message.
 * @param ac_buff - the buffer
 * @param i_buf_len - buffer length
 * @param ULR - Return ULR structure with mandatories fields
 * @returns Diameter Result Code
 * \note Only ULR is supported
 */
DIAMessage *Decode_Request ( char *ac_buff,
					  	  	 unsigned int i_buf_len,
					  	  	 unsigned int *i_diam_error_code,
					  	  	 ULR *ulr )
{
	char		 ac_avp_session_id[MAX_DIA_STRING_LENGTH+1];
	char		 ac_missing_avp[MAX_DIA_STRING_LENGTH + 1];
	char		 ac_mcc_mnc[VPLMN_LEN];
	DIA_AVP		 *avp_session_id;
	DIA_AVP		 *avp_origin_host;
	DIA_AVP		 *avp_origin_realm;
	DIA_AVP		 *avp_destination_realm;
	DIA_AVP		 *avp_user_name;
	DIA_AVP		 *avp_rat_type;
	DIA_AVP		 *avp_ulr_flags;
	DIA_AVP		 *avp_visited_plmn_id;
	DIAMessage	 *dreq = NULL;

	*i_diam_error_code   	= DIAMETER_SUCCESS;
	ac_avp_session_id[0] 	= 0x00;
	ac_missing_avp[0]	 	= 0x00;
	ac_mcc_mnc[VPLMN_LEN-1] = 0x00;

	dreq = DIATranslateMessage( (unsigned char*)ac_buff,
								(unsigned int)i_buf_len,
								"",
								ATTACH_SRC_BUFF ); // source buffer is attached to diameter msg structure

	if( dreq )
	{
		switch ( dreq->commandCode )
		{
			case Diameter_ULR:
			{
				AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULR_RECV);

				log_(LOG_DEBUG,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x]",
							dreq->commandCode,
							(dreq->flags&0x80)? 1:0,
							(dreq->flags&0x40)? 1:0,
							(dreq->flags&0x20)? 1:0,
							(dreq->flags&0x10)? 1:0,
							dreq->hopbyhopId,
							dreq->endtoendId);

				// Mandatory
				avp_session_id = DIAFindMatchingAVP( dreq,
													 dreq->avpList.head,
													 AVP_Session_Id,
													 0,   						// vendorId
													 DIA_FORWARD_SEARCH ); 		// searchType

				avp_origin_host = DIAFindMatchingAVP( dreq,
										   	  	  	  dreq->avpList.head,
										   	  	  	  AVP_Origin_Host,
										   	  	  	  0,   						// vendorId
										   	  	  	  DIA_FORWARD_SEARCH ); 	// searchType

				avp_origin_realm = DIAFindMatchingAVP( dreq,
										   	  	  	   dreq->avpList.head,
										   	  	  	   AVP_Origin_Realm,
										   	  	  	   0,   					// vendorId
										   	  	  	   DIA_FORWARD_SEARCH ); 	// searchType


				avp_destination_realm = DIAFindMatchingAVP( dreq,
											  	  	  	    dreq->avpList.head,
											  	  	  	    AVP_Destination_Realm,
											  	  	  	    0,   					// vendorId
											  	  	  	    DIA_FORWARD_SEARCH ); 	// searchType

				avp_user_name = DIAFindMatchingAVP( dreq,
													dreq->avpList.head,
													AVP_User_Name,
													0,   // vendorId
													DIA_FORWARD_SEARCH ); // searchType

				avp_rat_type = DIAFindMatchingAVP( dreq,
												   dreq->avpList.head,
												   AVP_EPC_RAT_Type,
												   EPC_vendor_id_3GPP,   // vendorId
												   DIA_FORWARD_SEARCH ); // searchType

				avp_ulr_flags = DIAFindMatchingAVP( dreq,
												    dreq->avpList.head,
												    AVP_EPC_ULR_Flags,
												    EPC_vendor_id_3GPP,   // vendorId
												    DIA_FORWARD_SEARCH ); // searchType

				avp_visited_plmn_id = DIAFindMatchingAVP( dreq,
												     	  dreq->avpList.head,
												     	  AVP_EPC_Visited_PLMN_Id,
												     	  EPC_vendor_id_3GPP,   // vendorId
												     	  DIA_FORWARD_SEARCH ); // searchType

				if ( avp_session_id &&
					 avp_origin_host &&
					 avp_origin_realm &&
					 avp_destination_realm &&
					 avp_user_name &&
					 avp_rat_type &&
					 avp_ulr_flags &&
					 avp_visited_plmn_id )
				{
					if( avp_session_id->data.len &&
						avp_session_id->type == DIA_AVP_STRING_TYPE )
					{
						sprintf(ac_avp_session_id,"%.*s",avp_session_id->data.len,avp_session_id->data.s);
						ulr->ulr_session.length = (short)avp_session_id->data.len;

						memcpy( ulr->ulr_session.value,
								avp_session_id->data.s,
								ulr->ulr_session.length );
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_SESSION_ID);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[263] {Session Id} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_origin_host->data.len &&
						avp_origin_host->data.len <= MAX_DIA_STRING_LENGTH &&
						avp_origin_host->type == DIA_AVP_STRING_TYPE &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						ulr->origin_host.length = (short)avp_origin_host->data.len;

						memcpy( ulr->origin_host.value,
								avp_origin_host->data.s,
								ulr->origin_host.length);
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_ORIGIN_HOST);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[264] {Origin Host} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_origin_realm->data.len &&
						avp_origin_realm->data.len <= MAX_DIA_STRING_LENGTH &&
						avp_origin_realm->type == DIA_AVP_STRING_TYPE &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						ulr->origin_realm.length = (short)avp_origin_realm->data.len;

						memcpy( ulr->origin_realm.value,
								avp_origin_realm->data.s,
								ulr->origin_realm.length);
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_ORIGIN_REALM);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[296] {Origin Realm} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_destination_realm->data.len &&
						avp_destination_realm->data.len <= MAX_DIA_STRING_LENGTH &&
						avp_destination_realm->type == DIA_AVP_STRING_TYPE &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						ulr->destination_realm.length = (short)avp_destination_realm->data.len;

						memcpy( ulr->destination_realm.value,
								avp_destination_realm->data.s,
								ulr->destination_realm.length);
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_DESTINATION_REALM);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[283] {Destination Realm} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_user_name->data.len < MAX_IMSI_LEN &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						if( !IsImsiNum( avp_user_name->data.s,
										avp_user_name->data.len ) )
						{
							ulr->imsi.length = (short)avp_user_name->data.len;

							memcpy( ulr->imsi.value,
									avp_user_name->data.s,
									ulr->imsi.length );
						}
						else
						{
							AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_USER_NAME);

							*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

							log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1] {User Name} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
						}
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_USER_NAME);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1] {User Name} length or type",
									dreq->commandCode,
									(dreq->flags&0x80)? 1:0,
									(dreq->flags&0x40)? 1:0,
									(dreq->flags&0x20)? 1:0,
									(dreq->flags&0x10)? 1:0,
									dreq->hopbyhopId,
									dreq->endtoendId);
					}

					if( avp_rat_type->data.len &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						ulr->c_rat_type = *avp_rat_type->data.s;
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_RAT);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1032] {ULR Rat} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_ulr_flags->data.len &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						ulr->i_ulr_flags = (unsigned int)avp_ulr_flags->data.s;
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_ULR_FLAGS);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1405] {ULR Flags} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}

					if( avp_visited_plmn_id->data.len == 3 &&
						avp_visited_plmn_id->type == DIA_AVP_DATA_TYPE &&
						*i_diam_error_code == DIAMETER_SUCCESS )
					{
						if( !V_PLMN_Id_Decode( avp_visited_plmn_id->data.s,
											   avp_visited_plmn_id->data.len,
											   ac_mcc_mnc ) )
						{
							strcpy(ulr->ac_visited_PLMN_Id,ac_mcc_mnc);
						}
						else
						{
							AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_VISITED_PLMN_ID);

							*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

							log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1407] {Visited PLMN Id} length or type",
											dreq->commandCode,
											(dreq->flags&0x80)? 1:0,
											(dreq->flags&0x40)? 1:0,
											(dreq->flags&0x20)? 1:0,
											(dreq->flags&0x10)? 1:0,
											dreq->hopbyhopId,
											dreq->endtoendId);

						}
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_INVALID_AVP_VISITED_PLMN_ID);

						*i_diam_error_code = DIAMETER_INVALID_AVP_VALUE;

						log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Wrong AVP[1407] {Visited PLMN Id} length or type",
										dreq->commandCode,
										(dreq->flags&0x80)? 1:0,
										(dreq->flags&0x40)? 1:0,
										(dreq->flags&0x20)? 1:0,
										(dreq->flags&0x10)? 1:0,
										dreq->hopbyhopId,
										dreq->endtoendId);
					}
				}
				else
				{
					*i_diam_error_code = DIAMETER_MISSING_AVP;

					if(!avp_session_id)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_SESSION_ID);

						strcat(ac_missing_avp," 263 ");
					}

					if(!avp_origin_host)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_ORIGIN_HOST);

						strcat(ac_missing_avp," 264 ");
					}

					if(!avp_origin_realm)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_ORIGIN_REALM);

						strcat(ac_missing_avp," 296 ");
					}

					if(!avp_destination_realm)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_DESTINATION_REALM);

						strcat(ac_missing_avp," 283 ");
					}

					if(!avp_user_name)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_USER_NAME);

						strcat(ac_missing_avp," 1 ");
					}

					if(!avp_rat_type)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_RAT);

						strcat(ac_missing_avp," 1032 ");
					}

					if(!avp_ulr_flags)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_ULR_FLAGS);

						strcat(ac_missing_avp," 1405 ");
					}

					if(!avp_visited_plmn_id)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_MISSING_AVP_VISITED_PLMN_ID);

						strcat(ac_missing_avp," 1407 ");
					}

					log_(LOG_ERROR,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x];Missing AVPs[%s]",
									dreq->commandCode,
									(dreq->flags&0x80)? 1:0,
									(dreq->flags&0x40)? 1:0,
									(dreq->flags&0x20)? 1:0,
									(dreq->flags&0x10)? 1:0,
									dreq->hopbyhopId,
									dreq->endtoendId,
									ac_missing_avp);
				}

				break;
			}

			default:
			{
				*i_diam_error_code = DIAMETER_COMMAND_UNSUPPORTED;

				log_(LOG_DEBUG,"RX-%d;Flag[R-%d,P-%d,E-%d,T-%d];HbyH[%x];EtoE[%x]",
							dreq->commandCode,
							(dreq->flags&0x80)? 1:0,
							(dreq->flags&0x40)? 1:0,
							(dreq->flags&0x20)? 1:0,
							(dreq->flags&0x10)? 1:0,
							dreq->hopbyhopId,
							dreq->endtoendId);

				if(i_trace_level > LOG_DEBUG)
					DIAPrintMessage( dreq );

				log_(LOG_WARNING,"RX-%d;Unsupported Diameter message code recv",dreq->commandCode);

				break;
			}
		}
	}
	else
	{
		AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_UNABLE_TO_DELIVER);

		*i_diam_error_code = DIAMETER_UNABLE_TO_DELIVER;

		log_(LOG_ERROR,"%s: RX - Translate Diameter message failure - Msg has been discarded",__FUNCTION__);

		log_msg ( LOG_ERROR,
				  "RX Translate Diameter msg failure",
				  ac_buff,
				  i_buf_len );
	}

	return dreq;
}

int SendULA( DIAMessage *dreq,
			 unsigned int i_diameter_result_code, // REDIRECT: DIA_REDIRECT_INDICATION (3006)
			    	   	   	   	   	   	   	   	  // ERROR: <diameter error>
			 unsigned int i_diameter_exp_result_code, // STEERING: RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED (5004)
			 dp_config *config,
			 int i_ula_type,
			 INS_String *imsi,
			 char *ac_visited_PLMN_Id,
			 char *diaSessionInfo,
			 short diaSessInfoLen )
{
	int		    lvErr = 0;
	int 		i_ula_type_chg;
	DIAMessage 	*dans = 0;

	switch( i_ula_type )
	{
		case ULA_ERROR:
		{
			dans = build_ULA( dreq,
							  i_diameter_result_code,
							  0,
							  imsi,
							  i_ula_type,
							  &i_ula_type_chg,
							  p_conf );

			break;
		}

		case ULA_REDIRECT:
		{
			dans = build_ULA( dreq,
							  i_diameter_result_code,
							  0,
							  imsi,
							  i_ula_type,
							  &i_ula_type_chg,
							  p_conf );

			break;
		}

		case ULA_STEERING:
		{
			if(i_diameter_exp_result_code > 0)
			{
				dans = build_ULA( dreq,
								  0,
								  i_diameter_exp_result_code,
								  imsi,
								  i_ula_type,
								  &i_ula_type_chg,
								  p_conf );
			}
			else
			{
				dans = build_ULA( dreq,
								  i_diameter_result_code,
								  0,
								  imsi,
								  i_ula_type,
								  &i_ula_type_chg,
								  p_conf );
			}

			break;
		}
	}

	if( dans )
	{
		lvErr = DIABuildMsgBuffer( dans );

		if( lvErr == DIA_ERR_SUCCESS  )
		{
			if( !dans->buf.len )
			{
				log_ (LOG_ERROR,"%s: Err.[%d] - Diameter Answer[%d] creation failure",
						__FUNCTION__,
						lvErr,
						dans->commandCode);
			}
			else
			{
				if(i_trace_level == LOG_DEBUG2)
				{
					log_msg ( LOG_DEBUG2,
							  "Diameter MSG",
							  dans->buf.s,
							  dans->buf.len );
				}

				lvErr = L_DIA_PUT_SESSION_INFO ((dia_session_info_t *)diaSessionInfo);

				if ((lvErr = L_DIA_BUILD_INFO ()))
				{
					log_(LOG_ERROR,"%s:  Err.[%d] - L_DIA_BUILD_INFO() failure - Diameter Answer[%d] discarded",
							__FUNCTION__,
							lvErr,
							dans->commandCode);
				}

				else
				{
					//
					// User can use REPLY_ too, instead of MTS_SEND.
					//
#ifdef IPC_ANSWER_MTS
					lvErr = MTS_SEND( (void *) ac_mts_buff,
									  (void *) dans->buf.s,
									  dans->buf.len );

					if(lvErr)
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_SENT_KO);
						log_(LOG_ERROR,"%s: Err.[%d] - MTS_SEND KO to DEA failed",
								__FUNCTION__,
								lvErr);
					}
					else
					{
						AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_SENT);
						log_(LOG_DEBUG2,"%s: MTS_SEND OK to DEA successfully",
								__FUNCTION__);

						switch( i_ula_type )
						{
							case ULA_STEERING:
							{
								AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_STEERING_SENT);

								if( i_diameter_result_code == DIAMETER_UNABLE_TO_COMPLY )
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_UNABLE_TO_COMPLY);

								if( i_diameter_exp_result_code == RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED )
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_ROAMING_NOT_ALLOWED);

								log_(LOG_DEBUG,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Steering[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
											dans->commandCode,
											(dans->flags&0x80)? 1:0,
											(dans->flags&0x40)? 1:0,
											(dans->flags&0x20)? 1:0,
											(dans->flags&0x10)? 1:0,
											(i_diameter_exp_result_code > 0?i_diameter_exp_result_code: i_diameter_result_code),
											dans->hopbyhopId,
											dans->endtoendId,
											imsi->length,
											imsi->value,
											ac_visited_PLMN_Id );

								break;
							}

							case ULA_REDIRECT:
							{
								if(i_ula_type == i_ula_type_chg)
								{
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_REDIRECT_SENT);

									log_(LOG_DEBUG,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Redirect[%d] towards [%s];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
												dans->commandCode,
												(dans->flags&0x80)? 1:0,
												(dans->flags&0x40)? 1:0,
												(dans->flags&0x20)? 1:0,
												(dans->flags&0x10)? 1:0,
												i_diameter_result_code,
												ac_fqdn_redirect_host[i],
												dans->hopbyhopId,
												dans->endtoendId,
												imsi->length,
												imsi->value,
												ac_visited_PLMN_Id );
								}
								else
								{
									log_(LOG_ERROR,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Err.[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
												dans->commandCode,
												(dans->flags&0x80)? 1:0,
												(dans->flags&0x40)? 1:0,
												(dans->flags&0x20)? 1:0,
												(dans->flags&0x10)? 1:0,
												3002,
												dans->hopbyhopId,
												dans->endtoendId,
												imsi->length,
												imsi->value,
												ac_visited_PLMN_Id );
								}

								break;
							}

							case ULA_ERROR:
							{
								switch( i_diameter_result_code )
								{
									case DIAMETER_COMMAND_UNSUPPORTED:
									{
										AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_CMD_CODE_UNSUPPORTED);

										break;
									}

									case DIAMETER_MISSING_AVP:
									{
										AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_MISSING_AVP);

										break;
									}

									case DIAMETER_INVALID_AVP_VALUE:
									{
										AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_INVALID_AVP_VALUE);

										break;
									}
								}

								log_(LOG_ERROR,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];DIA.Err[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
											dans->commandCode,
											(dans->flags&0x80)? 1:0,
											(dans->flags&0x40)? 1:0,
											(dans->flags&0x20)? 1:0,
											(dans->flags&0x10)? 1:0,
											i_diameter_result_code,
											dans->hopbyhopId,
											dans->endtoendId,
											imsi->length,
											imsi->value,
											ac_visited_PLMN_Id );

								break;
							}
						}
					}
#else
					switch( i_ula_type )
					{
						case ULA_STEERING:
						{
							AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_STEERING_SENT);

							if( i_diameter_result_code == DIAMETER_UNABLE_TO_COMPLY )
								AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_UNABLE_TO_COMPLY);

							if( i_diameter_exp_result_code == RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED )
								AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_ROAMING_NOT_ALLOWED);

							log_(LOG_DEBUG,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Steering[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
										dans->commandCode,
										(dans->flags&0x80)? 1:0,
										(dans->flags&0x40)? 1:0,
										(dans->flags&0x20)? 1:0,
										(dans->flags&0x10)? 1:0,
										(i_diameter_exp_result_code > 0?i_diameter_exp_result_code: i_diameter_result_code),
										dans->hopbyhopId,
										dans->endtoendId,
										imsi->length,
										imsi->value,
										ac_visited_PLMN_Id );

							break;
						}

						case ULA_REDIRECT:
						{
							if(i_ula_type == i_ula_type_chg)
							{
								AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_REDIRECT_SENT);

								log_(LOG_DEBUG,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Redirect[%d] towards [%s];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
											dans->commandCode,
											(dans->flags&0x80)? 1:0,
											(dans->flags&0x40)? 1:0,
											(dans->flags&0x20)? 1:0,
											(dans->flags&0x10)? 1:0,
											i_diameter_result_code,
											ac_fqdn_redirect_host[i],
											dans->hopbyhopId,
											dans->endtoendId,
											imsi->length,
											imsi->value,
											ac_visited_PLMN_Id );
							}
							else
							{
								log_(LOG_ERROR,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];Err.[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
											dans->commandCode,
											(dans->flags&0x80)? 1:0,
											(dans->flags&0x40)? 1:0,
											(dans->flags&0x20)? 1:0,
											(dans->flags&0x10)? 1:0,
											3002,
											dans->hopbyhopId,
											dans->endtoendId,
											imsi->length,
											imsi->value,
											ac_visited_PLMN_Id );
							}

							break;
						}

						case ULA_ERROR:
						{
							switch( i_diameter_result_code )
							{
								case DIAMETER_COMMAND_UNSUPPORTED:
								{
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_CMD_CODE_UNSUPPORTED);

									break;
								}

								case DIAMETER_MISSING_AVP:
								{
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_MISSING_AVP);

									break;
								}

								case DIAMETER_INVALID_AVP_VALUE:
								{
									AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_WITH_INVALID_AVP_VALUE);

									break;
								}
							}

							log_(LOG_ERROR,"TX-%d;Flag[R-%d,P-%d,E-%d,T-%d];DIA.Err[%d];HbyH[%x];EtoE[%x];IMSI[%.*s];VPLMN-Id[%s]",
										dans->commandCode,
										(dans->flags&0x80)? 1:0,
										(dans->flags&0x40)? 1:0,
										(dans->flags&0x20)? 1:0,
										(dans->flags&0x10)? 1:0,
										i_diameter_result_code,
										dans->hopbyhopId,
										dans->endtoendId,
										imsi->length,
										imsi->value,
										ac_visited_PLMN_Id );

							break;
						}
					}

					REPLY_((void*) dans->buf.s,dans->buf.len );

					AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_SENT);
#endif
				}
			}
		}
		else
			log_ (LOG_ERROR,"%s: Err.[%d] - Failed to create the Diameter Answer[%d]",
					__FUNCTION__,
					lvErr,
					dans->commandCode);

		DIAFreeMessage(&dans);
	}
	else
		log_(LOG_ERROR,"Build Diameter Answer[%d] failure - Diameter Request[%d] discarded",
					dreq->commandCode,
					dreq->commandCode);

	return (lvErr);
}

DIAMessage *build_ULA( DIAMessage *req,
					   unsigned int i_diameter_result_code, // ULA_REDIRECT: DIA_REDIRECT_INDICATION (3006)
					   	   	   	   	   	   	   	   	   	    // ULA_ERROR: <diameter error base>
					   	   	   	   	   	   	   	   	   	    // STEERING: DIAMETER_UNABLE_TO_COMPLY (5012)
					   unsigned int i_diameter_exp_result_code, // STEERING: RC_EPC_DIAMETER_ERROR_ROAMING_NOT_ALLOWED (5004)
					   INS_String *imsi,
					   int i_ula_type,
					   int *i_ula_type_chg,
					   dp_config *config )
{
	short		 i_cont = 0;
//	short		 i_ret = 0;
	int			 i_res;
	char 		 x[4];
	DIA_AVP 	 *avp,*avp1,*avp2;//,*avp_t;
	DIA_AVP_LIST list;
	DiaStr 		 group;
	DIAMessage 	 *ans = 0;

	*i_ula_type_chg = i_ula_type;

	switch( i_ula_type )
	{
		case ULA_ERROR:
		{
			ans = DIACreateResponse( req,
									 i_diameter_result_code,
									 config );

			if( ans )
			{
				put_4bytes(x,i_diameter_result_code);

				avp = DIACreateAVP( AVP_Result_Code,
									DIA_AVP_FLAG_MANDATORY,
									0,
									x,
									sizeof(unsigned int),
									AVP_DUPLICATE_DATA );
				if (!avp)
				{
					log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Result-Code",
							__FUNCTION__,
							AVP_Result_Code);

					DIAFreeMessage(&ans);

					ans = 0;
				}
				else
				{
					if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
					{
						log_(LOG_ERROR,"%s: Failed adding AVP[%d] to message",
								__FUNCTION__,
								AVP_Result_Code);

						DIAFreeAVP(&avp);
						DIAFreeMessage(&ans);

						ans = 0;
					}
					else
						i_cont = 1;
				}
			}

			break;
		}

		case ULA_STEERING:
		{
			if( i_diameter_exp_result_code > 0 )
			{
				// Errors that fall within the Permanent Failures category shall be used to inform the peer that the request has failed, and
				// should not be attempted again. The Result-Code AVP values defined in Diameter Base Protocol RFC 3588 [4] shall be
				// applied. When one of the result codes defined here is included in a response, it shall be inside an Experimental-Result
				// AVP and the Result-Code AVP shall be absent.

				ans = DIACreateResponse( req,
										 i_diameter_exp_result_code,
										 config );

				if( ans )
				{
					list.head = 0;
					list.tail = 0;

					put_4bytes(x,EPC_vendor_id_3GPP);
					avp1 = DIACreateAVP( AVP_Vendor_Id,
										 DIA_AVP_FLAG_MANDATORY,
										 0,
										 x,
										 4,
										 AVP_DUPLICATE_DATA );

					if( !avp1 )
					{
						DIAFreeMessage(&ans);

						ans = 0;

						log_(LOG_ERROR,"%s: Experimental_Result_Code: Failed creating AVP[%d] - AVP_Vendor_Id",
								__FUNCTION__,
								AVP_Vendor_Id);
					}
					else
					{
						DIAAddAVPToList(&list,avp1);

						put_4bytes(x,i_diameter_exp_result_code);

						avp2 = DIACreateAVP( AVP_Experimental_Result_Code,
											 DIA_AVP_FLAG_MANDATORY,
											 0,
											 x,
											 4,
											 AVP_DUPLICATE_DATA );

						if( !avp2 )
						{
							DIAFreeAVP(&avp1);
							DIAFreeMessage(&ans);

							ans = 0;

							log_(LOG_ERROR,"%s: Experimental_Result_Code: Failed creating AVP[%d] - AVP_Experimental_Result_Code",
									__FUNCTION__,
									AVP_Experimental_Result_Code);
						}
						else
						{
							DIAAddAVPToList(&list,avp2);

							group = DIAGroupAVPS(list);

							if( !group.s )
							{
								DIAFreeAVPList(&list);
								DIAFreeAVP(&avp1);
								DIAFreeAVP(&avp2);
								DIAFreeMessage(&ans);

								ans = 0;

								log_(LOG_ERROR,"%s: Failed grouping AVP Experimental Result AVP",__FUNCTION__);
							}
							else
							{
								DIAFreeAVPList(&list);

								if( DIACreateAndAddAVPToMessage( ans,
																 AVP_Experimental_Result,
																 DIA_AVP_FLAG_MANDATORY,
																 0,
																 group.s,
																 group.len ) )
								{
									DIAFreeAVP(&avp1);
									DIAFreeAVP(&avp2);
									DIAFreeMessage(&ans);

									ans = 0;

									log_(LOG_ERROR,"%s: Failed adding AVP Experimental Result to msg",__FUNCTION__);
								}

								free(group.s);
							}
						}
					}
				}
			}
			else // Steering with diameter error base ( something like DIAMETER_UNABLE_TO_COMPLY .... )
			{
				ans = DIACreateResponse( req,
										 i_diameter_result_code,
										 config );

				if( ans )
				{
					put_4bytes(x,i_diameter_result_code);

					avp = DIACreateAVP( AVP_Result_Code,
										DIA_AVP_FLAG_MANDATORY,
										0,
										x,
										sizeof(unsigned int),
										AVP_DUPLICATE_DATA );
					if (!avp)
					{
						log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Result-Code",
								__FUNCTION__,
								AVP_Result_Code);

						DIAFreeMessage(&ans);

						ans = 0;
					}
					else
					{
						if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
						{
							log_(LOG_ERROR,"%s: Failed adding AVP[%d] to message",
									__FUNCTION__,
									AVP_Result_Code);

							DIAFreeAVP(&avp);
							DIAFreeMessage(&ans);

							ans = 0;
						}
						else
							i_cont = 1;
					}
				}
			}

			break;
		}

		case ULA_REDIRECT:
		{
			if( i_dbase_present )
			{
				i=0;
				i_res = Get_FQDN_redirect_Host( imsi,
												ac_fqdn_redirect_host[i] );

				switch( i_res )
				{
					case FQDN_HOST_NAME_FOUND:
					{
						i_cont = 1;

						log_(LOG_DEBUG2,"%s: IMSI[%.*s] found -> HSS[%s]",
								__FUNCTION__,
								imsi->length,
								imsi->value,
								ac_fqdn_redirect_host[i]);

						break;
					}

					case FQDN_HOST_NAME_NOT_FOUND:
					{
						i_diameter_result_code = DIA_UNABLE_TO_DELIVER;

						log_(LOG_WARNING,"%s: Check IMSI[%.*s] on IMSI DB/HSS DB",
								__FUNCTION__,
								imsi->length,
								imsi->value);

						break;
					}

					default:
					{
						i_diameter_result_code = DIA_UNABLE_TO_DELIVER;

						log_(LOG_ERROR,"%s: DB Err.[%d] - Close/Reopen DBs",
								__FUNCTION__,
								i_res);

						CloseAllDB();
						OpenMBEdb();
					}
				}
			}
			else
			{
				// HOST FQDN set from INIFILE in order Round-Robin
				if(!(i%i_max_fqdn_host_entries))
					i=1;
				else
					i++;

				i_cont = 1;
			}

			if( i_cont )
			{
				ans = DIACreateResponse( req,
										 i_diameter_result_code,
										 config );

				if( ans )
				{
					put_4bytes(x,i_diameter_result_code);

					avp = DIACreateAVP( AVP_Result_Code,
										DIA_AVP_FLAG_MANDATORY,
										0,
										x,
										sizeof(unsigned int),
										AVP_DUPLICATE_DATA );
					if (!avp)
					{
						log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Result-Code",
								__FUNCTION__,
								AVP_Result_Code);

						DIAFreeMessage(&ans);

						ans = 0;
					}
					else
					{
						if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
						{
							log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
									__FUNCTION__,
									AVP_Result_Code);

							DIAFreeAVP(&avp);
							DIAFreeMessage(&ans);

							ans = 0;
						}
						else
						{
							avp = DIACreateAVP( AVP_Redirect_Host,
												DIA_AVP_FLAG_MANDATORY,
												0,
												ac_fqdn_redirect_host[i],
												strlen(ac_fqdn_redirect_host[i]),
												AVP_DUPLICATE_DATA );

							if (!avp)
							{
								DIAFreeMessage(&ans);
								ans = 0;

								log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Redirect-Host",
										__FUNCTION__,
										AVP_Redirect_Host);
							}
							else
							{
								if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
								{
									DIAFreeAVP(&avp);
									DIAFreeMessage(&ans);
									ans = 0;

									log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
											__FUNCTION__,
											AVP_Redirect_Host);
								}
								else
								{
									put_4bytes(x,0);

									avp = DIACreateAVP( AVP_Redirect_Host_Usage,
														DIA_AVP_FLAG_MANDATORY,
														0,
														x,
														sizeof(unsigned int),
														AVP_DUPLICATE_DATA );
									if (!avp)
									{
										DIAFreeMessage(&ans);
										ans = 0;

										log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Redirect-Host-Usage",
												__FUNCTION__,
												AVP_Redirect_Host_Usage);
									}
									else
									{
										if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
										{
											DIAFreeAVP(&avp);
											DIAFreeMessage(&ans);
											ans = 0;

											log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
													__FUNCTION__,
													AVP_Redirect_Host_Usage);
										}
										else
										{
											put_4bytes(x,0);

											avp = DIACreateAVP( AVP_Redirect_Max_Cache_Time,
																DIA_AVP_FLAG_MANDATORY,
																0,
																x,
																sizeof(unsigned int),
																AVP_DUPLICATE_DATA );
											if (!avp)
											{
												DIAFreeMessage(&ans);
												ans = 0;

												log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Redirect-Max-Cache-Time",
														__FUNCTION__,
														AVP_Redirect_Max_Cache_Time);
											}
											else
											{
												if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
												{
													DIAFreeAVP(&avp);
													DIAFreeMessage(&ans);
													ans = 0;

													log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
															__FUNCTION__,
															AVP_Redirect_Max_Cache_Time);
												}
//												else
//												{
//													// copy as is all the proxy-info avp in the same order
//													avp_t = req->avpList.head;
//													while ( (avp_t = DIAFindMatchingAVP(req,avp_t,AVP_Proxy_Info,0,DIA_FORWARD_SEARCH))!= 0 )
//													{
//														if ( !(avp=DIACloneAVP(avp_t,1)) ||
//															 DIAAddAVPToMessage( ans, avp,ans->avpList.tail)!=DIA_ERR_SUCCESS )
//														{
//															DIAFreeAVP(&avp);
//															DIAFreeMessage(&ans);
//															ans = 0;
//
//															i_ret = 1;
//
//															log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
//																	__FUNCTION__,
//																	AVP_Proxy_Info);
//
//															break;
//														}
//													}
//
//													if(!i_ret)
//													{
//														// copy as is all the Route-Record(282) avp in the same order
//														avp_t = req->avpList.head;
//														while ( (avp_t=DIAFindMatchingAVP(req,avp_t,AVP_Route_Record,0,DIA_FORWARD_SEARCH))!= 0 )
//														{
//															if ( !(avp=DIACloneAVP(avp_t,1)) ||
//																 DIAAddAVPToMessage( ans, avp,ans->avpList.tail)!=DIA_ERR_SUCCESS )
//															{
//																DIAFreeAVP(&avp);
//																DIAFreeMessage(&ans);
//																ans = 0;
//
//																log_(LOG_ERROR,"%s: Failed adding AVP[%d] to msg",
//																		__FUNCTION__,
//																		AVP_Route_Record);
//
//																break;
//															}
//														}
//													}
//												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			else
			{
				*i_ula_type_chg = ULA_ERROR;

				ans = DIACreateResponse( req,
										 i_diameter_result_code,
										 config );

				if( ans )
				{
					put_4bytes(x,i_diameter_result_code);

					avp = DIACreateAVP( AVP_Result_Code,
										DIA_AVP_FLAG_MANDATORY,
										0,
										x,
										sizeof(unsigned int),
										AVP_DUPLICATE_DATA );
					if (!avp)
					{
						log_(LOG_ERROR,"%s: Failed creating AVP[%d] - Result-Code",
								__FUNCTION__,
								AVP_Result_Code);

						DIAFreeMessage(&ans);

						ans = 0;
					}
					else
					{
						if (DIAAddAVPToMessage(ans,avp,ans->avpList.tail)!=DIA_ERR_SUCCESS)
						{
							log_(LOG_ERROR,"%s: Failed adding AVP[%d] to message",
									__FUNCTION__,
									AVP_Result_Code);

							DIAFreeAVP(&avp);
							DIAFreeMessage(&ans);

							ans = 0;
						}
					}
				}
			}

			break;
		}
	}

	return ans;
}

short SendTFSMGR( ULR *ulr,
				  TFS_CTX *tfs_ctx,
				  long l_ctx_tag )
{
	short 			i_ret = 0;
	EXTERNAL_REF	ext_ref;
	TFS_LTE_IPC		tfs_mgr;

	if( tfs_ctx->diaSessInfoLen > MAX_DIAMETER_SESSION_INFO )
	{
		i_ret = 1;
		log_(LOG_ERROR,"%s: diaSessInfoLen exceed the max length of diameter session managed",
				__FUNCTION__);
	}
	else
	{
		memset(&tfs_mgr,0x00,sizeof(TFS_LTE_IPC));
		memset(&ext_ref,0x00,sizeof(EXTERNAL_REF));

		ext_ref.l_ctx_tag = l_ctx_tag;
		ext_ref.Ts_in	  = JULIANTIMESTAMP(0);

		ext_ref.i_ulr_flags = ulr->i_ulr_flags; // not necessary
		ext_ref.diaSessInfoLen = tfs_ctx->diaSessInfoLen;

		memcpy( ext_ref.diaSessionInfo,
				(char *)tfs_ctx->diaSessionInfo,
				tfs_ctx->diaSessInfoLen );

		ext_ref.i_HbyH = tfs_ctx->i_HbyH;
		ext_ref.i_EtoE = tfs_ctx->i_EtoE;
		memcpy( &ext_ref.ulr_session,
				(char *)&ulr->ulr_session,
				sizeof(DiamIdent) );

		tfs_mgr.i_tag 	   = TFS_LTE;
		tfs_mgr.i_op  	   = ULR_CMD;
		tfs_mgr.c_rat_type = ulr->c_rat_type;

		memcpy( &tfs_mgr.origin_host,
				(char *)&ulr->origin_host,
				sizeof(DiamIdent) );

		memcpy( &tfs_mgr.origin_realm,
				(char *)&ulr->origin_realm,
				sizeof(DiamIdent) );

		memcpy( &tfs_mgr.imsi,
				(char *)&ulr->imsi,
				sizeof(INS_String) );

		strcpy(tfs_mgr.ac_visited_PLMN_Id,ulr->ac_visited_PLMN_Id);

		tfs_mgr.result_address.choice = choice_mts_address; // MTS_SEND
		tfs_mgr.result_address.address.mts_address = getretAddr();

		ext_ref.Ts_in = JULIANTIMESTAMP(0);
		memcpy( tfs_mgr.external_reference,
				(char *)&ext_ref,
				sizeof(EXTERNAL_REF) );

		i_ret = Func_MTS_SEND_Taskid( i_tfsmgr_tid,
									  i_tfsmgr_srv,
									  0,
									  0,
									  (char *)&tfs_mgr,
									  sizeof(TFS_LTE_IPC) );
	}

	return i_ret;
}

// *************************************************************************************************+
void handleEvent ( char *ac_buffer,
				   short i_buffLen )
{
	short 					i_err = 0;
    long					lvCtxTag;
    diameter_event_types_t 	eventType;
    diameter_reason_t 		eventReason;
    PEER_AVAILABLE_EVENT 	*peer_open;
    PEER_UNAVAILABLE_EVENT  *peer_close;

	/*
	* The message is an event type. Fetch the
	* event-type.
	*/
	if ((i_err = L_DIA_GET_EVENT_INFO (&eventType, &eventReason)) != 0)
	{
		log_ (LOG_ERROR,"%s: Err.[%d] - L_DIA_GET_EVENT_INFO()",
				__FUNCTION__,
				i_err);
	}
	else
	{
		switch( eventType )
		{
			case DIAMETER_EVENT_SEND_MESSAGE_FAILED:
			{
				AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_stat_reg_postfix,LTE_TFS_STATS_ULA_SENT_KO);

				/*
				** INS failed to send the message. Check if there is a ctx
				** associated and handle it accordingly.
				*/
				log_(LOG_WARNING,"%s: Send Message Failed Event, Event Reason[%d]",
						__FUNCTION__,
						eventReason);

				log_msg ( LOG_ERROR,
						  "DIAMETER_EVENT_SEND_MESSAGE_FAILED",
						  ac_buffer,
						  i_buffLen );

				/*
				** User can print the Diameter Message that INS failed to send. The entire
				** message that INS failed to send out, is returned back to the user.
				*/
				i_err = L_DIA_GET_CONTEXT_TAG((unsigned int *)&lvCtxTag);

				if( lvCtxTag )
					CTXReleaseContext(lvCtxTag);

				break;
			}

			case DIAMETER_EVENT_ROUTE_NOT_AVAILABLE:
			{
				log_(LOG_WARNING,"%s: Diameter Route Not Available Event",__FUNCTION__);

				break;
			}

			case DIAMETER_EVENT_TRANSPORT_OPENED_WITH_PEER:
			{
				if(i_trace_level >= LOG_DEBUG)
				{
					peer_open = (PEER_AVAILABLE_EVENT *)ac_buffer;
					PrintOpenEvent(peer_open);
				}

				break;
			}

			case DIAMETER_EVENT_TRANSPORT_CLOSED_WITH_PEER:
			{
				if(i_trace_level >= LOG_DEBUG)
				{
					peer_close = (PEER_UNAVAILABLE_EVENT *)ac_buffer;
					PrintCloseEvent(peer_close);
				}

				break;
			}

			case DIAMETER_EVENT_PEER_RESPONSE_TIMEOUT:
			{
				log_(LOG_WARNING,"%s: Diameter Peer Response Timeout Event",
						__FUNCTION__);

				break;
			}

			default:
			{
				// Unknown event received
				log_(LOG_WARNING,"%s: Unknown Diameter Event[%d]",
						__FUNCTION__,
						eventType);

				break;
			}
		}
	}

	return;
}

void PrintOpenEvent (PEER_AVAILABLE_EVENT* aSerMsg)
{
	int count;
//				struct peer_available_event
//				{
//					char peer_origin_host [DIAMETER_ORIGIN_HOST_LENGTH];
//					char peer_origin_realm [DIAMETER_ORIGIN_REALM_LENGTH];
//					char origin_host [DIAMETER_ORIGIN_HOST_LENGTH];
//					char origin_realm [DIAMETER_ORIGIN_REALM_LENGTH];
//					uint8_t transport;
//					uint8_t filler0[1];
//					uint8_t nbrAddresses;
//					uint8_t filler1[1];
//					char host_ip_addresses [DIAMETER_MAX_HOST_IP_ADDRS][DIAMETER_IP_ADDRESS_LENGTH];
//					uint8_t nbrAuthAppIds;
//					uint8_t filler2[1];
//					uint32_t authAppId [DIAMETER_MAX_APPL_IDS];
//					uint8_t nbrAcctAppIds;
//					uint8_t filler3[1];
//					uint32_t acctAppId [DIAMETER_MAX_APPL_IDS];
//					uint8_t nbrVendorAppId;
//					uint8_t filler4[1];
//					struct
//					{
//						uint32_t vendorId;
//						uint16_t applIdType;  Auth or Acct.
//						union
//						{
//							uint32_t authAppId;
//							uint32_t acctAppId;
//						} appId PACK_STRUCT_ATTR;
//					} vendorSupportedAppIds [DIAMETER_MAX_VENDOR_APPL_IDS] PACK_STRUCT_ATTR;
//				} PACK_STRUCT_ATTR;
//
//				typedef struct peer_available_event PEER_AVAILABLE_EVENT;

	log_(LOG_DEBUG,"*************************************");
	log_(LOG_DEBUG,"RX Peer Open Event CER/CEA completed:");

	log_(LOG_DEBUG,"Peer Origin Host  : %s",aSerMsg->peer_origin_host);
	log_(LOG_DEBUG,"Peer Origin Realm : %s",aSerMsg->peer_origin_realm);
	log_(LOG_DEBUG,"Destination Host  : %s",aSerMsg->origin_host);
	log_(LOG_DEBUG,"Destination Realm : %s",aSerMsg->origin_realm);
	log_(LOG_DEBUG,"Transport         : %d",aSerMsg->transport);

	log_(LOG_DEBUG,"Nbr of Addresses  : %d",aSerMsg->nbrAddresses);
	for (count = 0; count < aSerMsg->nbrAddresses; ++count)
		log_(LOG_DEBUG," Addr[%d]         : %s",count,aSerMsg->host_ip_addresses [count]);

	log_(LOG_DEBUG,"Nbr of AuthAppId  : %d",aSerMsg->nbrAuthAppIds);
	for (count = 0; count < aSerMsg->nbrAuthAppIds; ++count)
		log_(LOG_DEBUG," Auth Appl Id[%d] : %d",count,aSerMsg->authAppId[count]);

	log_(LOG_DEBUG,"Nbr of AcctAppId  : %d",aSerMsg->nbrAcctAppIds);
	for (count = 0; count < aSerMsg->nbrAcctAppIds; ++count)
		log_(LOG_DEBUG," Acct Appl Id[%d] : %d",count,aSerMsg->acctAppId[count]);

	log_(LOG_DEBUG,"Nbr of Vendor Supported Appl Id: %d",aSerMsg->nbrVendorAppId);
	for (count = 0; count < aSerMsg->nbrVendorAppId; ++count)
	{
		log_(LOG_DEBUG,"	Vendor Id        : %d",aSerMsg->vendorSupportedAppIds [count].vendorId);
		log_(LOG_DEBUG,"	Vendor support   : %s | %d",
				(aSerMsg->vendorSupportedAppIds [count].applIdType?"Acct":"Auth"),
				aSerMsg->vendorSupportedAppIds [count].appId.authAppId);
	}

	log_(LOG_DEBUG,"*************************************");

	return;
}

void PrintCloseEvent (PEER_UNAVAILABLE_EVENT* aSerMsg)
{
//				struct peer_unavailable_event
//				{
//					char peer_origin_host [DIAMETER_ORIGIN_HOST_LENGTH];
//					char peer_origin_realm [DIAMETER_ORIGIN_REALM_LENGTH];
//					char origin_host [DIAMETER_ORIGIN_HOST_LENGTH];
//					char origin_realm [DIAMETER_ORIGIN_REALM_LENGTH];
//					uint32_t disconnect_cause;
//					uint8_t terminationInfo;  Non-zero if forced shutdown, else graceful shutdown.
//				} PACK_STRUCT_ATTR;
//
//				typedef struct peer_unavailable_event PEER_UNAVAILABLE_EVENT;

	log_(LOG_DEBUG,"*************************************");
	log_(LOG_DEBUG,"RX Peer Closed Event:");

	log_(LOG_DEBUG,"Peer Origin Host  : %s",aSerMsg->peer_origin_host);
	log_(LOG_DEBUG,"Peer Origin Realm : %s",aSerMsg->peer_origin_realm);
	log_(LOG_DEBUG,"Destination Host  : %s",aSerMsg->origin_host);
	log_(LOG_DEBUG,"Destination Realm : %s",aSerMsg->origin_realm);
	log_(LOG_DEBUG,"DisConnect Cause  : %d",aSerMsg->disconnect_cause);
	log_(LOG_DEBUG,"Termination Info  : %s",(aSerMsg->terminationInfo?"ForceFul":"GraceFul"));
	log_(LOG_DEBUG,"*************************************");

  return;
}

// Open receive#MTS
void Open_Receive_MTS( void )
{
    short open_flags = P2_GEN_RECV_SYS_MSGS;
    short receive_depth = 1;

    memset( ReceiveIO.fname, ' ', 24 );
    memcpy( ReceiveIO.fname, "$RECEIVE#MTS", 12 );

    ReceiveIO.error = OPEN_( ReceiveIO.fname,
							 &ReceiveIO.id,
							 open_flags,
							 receive_depth );

    if ( ReceiveIO.error != P2_G90_FEOK )
    {
        log_(LOG_ERROR,"%s: Err.[%d] - OPEN_()",
        		__FUNCTION__,
        		ReceiveIO.error);

        DELAY(EXIT_DELAY);

        exit(-1);
    }

    return;

} /* End Of Procedure: Open_Input_Queue */

/** ---------------------------------------------------------------------------
*
* @param *ac_visited_plmn_id - in parameter - AVP Visited_PLMN_Id value
* @param *ac_mcc_mnc		 - out parameter - MCC+MNC
* \note Value Returned:
* \note       - 0 	Ok
* \note       - 1 	Decode failure due to a wrong input value
* -----------------------------------------------------------------------------
*/
static short V_PLMN_Id_Decode( unsigned char *ac_visited_plmn_id,
							   int 			 i_visited_plmn_id_len,
							   char 		 *ac_mcc_mnc )  // c_string 7 bytes null terminated
{
	short  i_ret = 0;

	if( i_visited_plmn_id_len > 3 )
	{
		i_ret = 1;
	}
	else
	{
		ac_mcc_mnc[5] = '\0';
		ac_mcc_mnc[6] = '\0';
		if( ((ac_visited_plmn_id[1] >> 4) & 0x0F) == 0x0F)
		{
			sprintf( ac_mcc_mnc,"%d%d%d%d%d",
					 ac_visited_plmn_id[0] & 0x0F,
					 (ac_visited_plmn_id[0] & 0xF0) >> 4,
					 ac_visited_plmn_id[1] & 0x0F,
					 ac_visited_plmn_id[2] & 0x0F,
					 (ac_visited_plmn_id[2] & 0xF0) >> 4 );
		}
		else
		{
			sprintf( ac_mcc_mnc,"%d%d%d%d%d%d",
					 ac_visited_plmn_id[0] & 0x0F,
					 (ac_visited_plmn_id[0] & 0xF0) >> 4,
					 ac_visited_plmn_id[1] & 0x0F,
					 ac_visited_plmn_id[2] & 0x0F,
					 (ac_visited_plmn_id[2]& 0xF0) >> 4,
					 (ac_visited_plmn_id[1] & 0xF0) >> 4 );
		}
	}

	return i_ret;
}

/** ---------------------------------------------------------------------------
*
* @param *str 		- in parameter - buffer
* @param i_len	    - in parameter - buffer length
* \note Value Returned:
* \note       - 0 	Numeric
* \note       - 1 	Alphanumeric
* -----------------------------------------------------------------------------
*/
static short IsImsiNum( char *str,
					    int i_len )
{
	short 	i_ret = 0;
    int 	i_nn;

    for (i_nn = (int)(i_len-1); i_nn >=0; i_nn--)
    {
        if ( !isdigit(str[i_nn]) )
        {
            i_ret = 1;

            break;
        }
    }

    return i_ret;
}

short SetTimerBump_( long l_stat_bump_interval, // in seconds
                     long l_tag )

{
      short i_ret = 0;
      long  timerval;

      timerval = (long)stat_timerval( l_stat_bump_interval );

      if( timerval < 300 )
          timerval += 300;

      if( SIGNALTIMEOUT_( timerval ,
                          0 ,
                          l_tag ) )
      {
          i_ret = 1;
      }

      return i_ret;
}

short RetrieveAndReleaseCtx( long trans_id,
							 TFS_CTX *tfs_ctx )
{
	short i_ret = 0,i_res = 0;

	i_ret = LoadCTX( trans_id,
					 (char *)tfs_ctx,
					 sizeof(TFS_CTX) );

	//
	// Use ctx buffer
	//
	if( !i_ret )
	{
		log_(LOG_DEBUG2,"%s: Load CTX[0x%08X] successfully",
				__FUNCTION__,
				trans_id);

		i_res = CTXReleaseContext( trans_id );

		if(!i_res)
		{
			// Ok
			log_(LOG_DEBUG2,"%s: Release CTX[0x%08X] successfully",
					__FUNCTION__,
					trans_id);
		}
		else
		{
			// KO
			log_(LOG_WARNING,"%s: Err.[%d] - Release CTX[0x%08X] failure, CTX info has been retrieved",
					__FUNCTION__,
					i_res,
					trans_id);
		}
	}
	else
		log_(LOG_WARNING,"%s: Err.[%d] - CTX[0x%08X] buffer not found",
				__FUNCTION__,
				i_ret,
				trans_id);

	return i_ret;
}

// print start/stop message on log_
void Msg_print( short i_type )
{
    log_ (LOG_INFO, "***************************");
    log_ (LOG_INFO, "***                     ***");
    log_ (LOG_INFO, "***      TFS - LTE      ***");
    log_ (LOG_INFO, "***       S6a/S6d       ***");
    log_ (LOG_INFO, "***       V 1.00        ***");
    log_ (LOG_INFO, "***                     ***");

    switch( i_type )
    {
        case _START_:
        {
            EVT_manage( EVTN_TFS_LTE_START,
						0,
						0,
						'N',
						"[%s] started",
						ac_my_process_name );

            log_ (LOG_INFO, "***      Started        ***");

            break;
        }

        case _STOP_:
        {
            EVT_manage( EVTN_TFS_LTE_STOP,
						0,
						0,
						'N',
						"[%s] stopped by user",
						ac_my_process_name );

            log_ (LOG_INFO, "***      Stopped        ***");

            break;
        }
    }

    log_ (LOG_INFO, "***                     ***");
    log_ (LOG_INFO, "***************************");
}

//
// Open/Reopen dbase
//
short OpenMBEdb( void )
{
    short i_err = 0;

	if( (i_err = MbeFileOpenWrapper( ac_path_imsi_db,
									 &i_fd_db_imsi,
									 c_open_db )) )
	{
		log_(LOG_ERROR,"%s: Err.[%d] - IMSI DB[%s] not open",
				__FUNCTION__,
				i_err,
				ac_path_imsi_db);
	}
	else
	{
		log_(LOG_DEBUG2,"%s: IMSI DB[%s] open",
				__FUNCTION__,
				ac_path_imsi_db);

		if( (i_err = MbeFileOpenWrapper( ac_path_hss_db,
										 &i_fd_db_hss,
										 c_open_db )) )
		{
			log_(LOG_ERROR,"%s: Err.[%d] - HSS DB[%s] not open",
					__FUNCTION__,
					i_err,
					ac_path_hss_db);
		}
		else
		{
			log_(LOG_DEBUG2,"%s: HSS DB[%s] open",
					__FUNCTION__,
					ac_path_hss_db);
		}
	}

    return (i_err);
}

void CloseAllDB( void )
{
    // close DBase
    MbeFileClose(i_fd_db_hss);
	MbeFileClose(i_fd_db_imsi);
}

int Get_FQDN_redirect_Host ( INS_String *imsi,
		 	 	 	 	 	 char *ac_fqdn_redirect_host )
{
	short				i_found_imsi_range = 0;
	unsigned short		i;
	int 				i_err = 0;
	int					cc;
	IMSI_HEAD_RECORD	imsi_head_rec;
	IMSI_RECORD			imsi_rec;
	IMSI_PKEY			PKey;
	HSS_RECORD			hss_rec;

	memset(&imsi_head_rec, 0x00, sizeof(IMSI_HEAD_RECORD));

	/***********************
	* Cerco il primo record
	************************/
	/* ricerca primaria (0) esatta (2) */
	cc = MBE_FILE_SETKEY_ ( i_fd_db_imsi,
							(char *)&imsi_head_rec.pkey,
							sizeof(IMSI_PKEY),
							0,
							2 );

	if (!cc)
	{
		/* Leggo il record di testa */
		cc = MbeFileReadWrapper( i_fd_db_imsi,
								 (char *)&imsi_head_rec,
								 (short)sizeof(IMSI_HEAD_RECORD) );

		if ( !cc )
		{
			// ciclo sulle possibili lunghezze dei range
			for (i=imsi->length; i>0; i--)
			{
				if (imsi_head_rec.lunghezze[i] == 1)
				{
					memset(&PKey,0x00,sizeof(IMSI_PKEY));
					/*******************
					* Imposta chiave
					*******************/
					PKey.range_len = i;
					memcpy( PKey.range_end,
							imsi->value,
							PKey.range_len );

					/*******************
					* Cerco il record
					*******************/
					/* ricerca primaria (0) approssimata (0) */
					cc = MBE_FILE_SETKEY_ ( i_fd_db_imsi,
											(char *)&PKey,
											sizeof(IMSI_PKEY),
											0,
											0 );

					if (cc != 0)
					{
						i_err = cc;

						break;
					}
					else
					{
						cc = MbeFileReadWrapper( i_fd_db_imsi,
												 (char *)&imsi_rec,
												 (short)sizeof(IMSI_RECORD) );

						if ( cc != 0 )
						{
							if (cc != 1)
							{
								i_err = cc;

								break;
							}
						}
						else  /* record found */
						{
							// a questo punto siamo sicuri che il RANGE END trovato sia >= alla chiave cercata
							// in quanto abbiamo fatto una ricerca approssimata.
							// Si deve verificare che:
							//    1) La lunghezza range trovata sia la stessa cercata
							//    2) la chiave cercata sia compresa nel range (RANGE INI minore o uguale alla chiave cercata)
							if ( (imsi_rec.pkey.range_len == PKey.range_len) &&
								 (memcmp(imsi_rec.range_ini, PKey.range_end, PKey.range_len) <= 0) )
							{
								i_found_imsi_range = 1;

								break;
							}
						}
					}
				}
			}

			if( i_found_imsi_range ) // check for HOST FQDN
			{
				/*******************
				* Cerco il record
				*******************/
				/* ricerca primaria (0) esatta (2) */
				cc = MBE_FILE_SETKEY_ ( i_fd_db_hss,
										(char *)&imsi_rec.hss_id,
										sizeof(unsigned short),
										0,
										2 );

				/* errore */
				if (cc != 0)
				{
					i_err = cc;
				}
				/* tutto ok */
				else
				{
					cc = MbeFileReadWrapper( i_fd_db_hss,
											 (char *)&hss_rec,
											 (short)sizeof(HSS_RECORD) );

					/* errore... */
					if ( cc != 0 )
					{
						/* errore */
						if (cc != 1)
						{
							i_err = cc;
						}
						else
						{
							i_err = FQDN_HOST_NAME_NOT_FOUND;
						}
					}
					else // record found
					{
						if( memcmp(hss_rec.hostname,"aaa://",6) &&
							memcmp(hss_rec.hostname,"AAA://",6)	)
						{
							sprintf(ac_fqdn_redirect_host,"aaa://%s",hss_rec.hostname);
						}
						else
						{
							strcpy(ac_fqdn_redirect_host,hss_rec.hostname);
						}
					}
				}
			}
			else
				i_err = FQDN_HOST_NAME_NOT_FOUND;
		}
		else
			i_err = cc;
	}
	else
		i_err = cc;

	return(i_err);
}

/****************************************************************************
***  Module Name:  Process_Initialization                                  **
***                                                                        **
***  Description:  This module is responsible for processing all of the    **
***                run-time parameters and determining if the process      **
***                has been started under the Node or in a stand-alone     **
***                environment.                                            **
*****************************************************************************/
void Process_Initialization (void)
{
    short   i_proch[20];
    short   i_anc[20];
    short   i_maxlen = sizeof (ac_my_process_name);
    short   i_maxlen_node = sizeof(ac_node_name);
    short   i_maxlen_ancestor = sizeof(ac_ancestor_name);
    short 	j;
    char    *wrk_str;

    if ((wrk_str = getenv ("FILEINI")) != NULL)
    {
        memset(ac_filecfg,0x00, sizeof(ac_filecfg));
		memset(ac_my_process_name,0x00,sizeof(ac_my_process_name));

        strcpy(ac_filecfg,wrk_str);

        PROCESSHANDLE_GETMINE_ (i_proch);
        PROCESSHANDLE_DECOMPOSE_ ( i_proch,&i_my_cpu,
                                   ,,
                                   ac_node_name,
                                   i_maxlen_node,
                                   &i_maxlen_node,
                                   ac_my_process_name,
                                   i_maxlen,
                                   &i_maxlen, );

		setChgFile(ac_filecfg,ac_filecfg_oss);

        if( !LoadParameters(ac_filecfg,LOAD) )
        {
			exit(-1);
        }
        else
        {
			memset(ac_ancestor_name,0x00,sizeof(ac_ancestor_name));

            PROCESS_GETPAIRINFO_(i_proch,,,,,,,i_anc);
            PROCESSHANDLE_DECOMPOSE_ ( i_anc,,,,,,,
                                       ac_ancestor_name,
                                       i_maxlen_ancestor,
                                       &i_maxlen_ancestor, );

            // ------------------------------------------------------------------------
            // Node parameters (under node INS)
            // ------------------------------------------------------------------------
            if ( ( wrk_str = getenv( "CSS-MM-TASKID" ) ) != NULL )
            {
                i_my_tid = (short)atoi( wrk_str );

                if ( ( wrk_str = getenv( "CSS-MM-SVRCLASS" ) ) != NULL )
                {
                    i_my_svr_cls = (short)atoi( wrk_str );

                    if ( ( wrk_str = getenv( "CSS-PC-LOOPTIMER" ) ) != NULL )
                        i_loop_timer = (short)atoi( wrk_str );

                    i_node_id = 'A';
                    if ( ( wrk_str = getenv( "CSS-NODE-ID" ) ) != NULL )
                    {
                        i_node_id = (short)wrk_str[0];

                        // Inizializzazione INS
                        strncpy( mm, "$MMyx                   ", 24);

                        sprintf( ac_cpu, "%x", i_my_cpu );
                        mm[3] = ac_cpu[0];
                        mm[4] = (char) i_node_id;
                        i_node_id = (short) (i_node_id * 256);

                        i_my_node_id = L_CINITIALIZE( i_my_tid,
                                                      i_my_svr_cls,
                                                      ,
                                                      &i_bpid,
                                                      ,(short *) mm,
                                                      i_node_id );

                        if ( !i_my_node_id )
                        {
                            mm[5] = 0;
                            DELAY(EXIT_DELAY);

                            EVT_manage( EVTN_L_CINITIALIZE,
										0,
										0,
										'A',
										"L_CINITIALIZE Failed - Exit" );

                            log_(LOG_ERROR,"%s: [%s] - L_CINITIALIZE Failed",
                            		__FUNCTION__,
                            		ac_my_process_name);

                            exit(-1);
                        }

                        L_INITIALIZE_END();
					}
					else
					{
						EVT_manage( EVTN_L_CINITIALIZE,
									0,
									0,
									'A',
									"L_CINITIALIZE Failed - CSS-NODE-ID not found - Exit" );

						exit(-1);
					}
                }
				else
				{
					EVT_manage( EVTN_L_CINITIALIZE,
								0,
								0,
								'A',
								"L_CINITIALIZE Failed - CSS-MM-SVRCLASS not found - Exit" );

					exit(-1);
				}
            }
			else
			{
				EVT_manage( EVTN_L_CINITIALIZE,
							0,
							0,
							'A',
							"L_CINITIALIZE Failed - CSS-MM-TASKID not found - Exit" );

				exit(-1);
			}

            Msg_print( _START_ );

            // ------------------------------------------------------------------------

            if(!Stat_init( "",
                           "",
                           "",
                           i_stat_group,
                           i_stat_max_register,
                           S_MAX_IDX_NUMBER ))
            {
                EVT_manage( EVTN_STAT_NOT_INIT,
							0,
							0,
							'A',
							"Stat_init Failed" );

                log_(LOG_WARNING,"Stat_init Failed");
            }
			else
			{
				strcpy(ac_stat_reg_prefix, STAT_TFS_LTE_PREFIX_REGS);
				strcpy(ac_stat_reg_postfix, " ");
			}

            if( i_dbase_present )
			{
				if( OpenMBEdb() )
				{
					if(i_max_fqdn_host_entries)
						i_dbase_present = 0;
					else
						exit(-1);
				}
			}

            if( !i_dbase_present )
            {
            	for(j=1;j<=i_max_fqdn_host_entries;j++)
            	{
            		log_(LOG_INFO,"%s: URI Redirect-Host[%d] - %s",
            				__FUNCTION__,
            				j,
            				ac_fqdn_redirect_host[j]);
            	}
            }
            // ------------------------------------------------------------------------
        }
    }
    else
        exit(-1);
} // End Of Procedure: Process_Initialization

//
// Load parameters function. Load INI file
//
short LoadParameters( char *ac_PathCfgFile,
                      short i_reload )
{
	short  			rc = 0;
	short  			ret = 1;
	short			j;
	short			i_host_found;
	int    			found = 0;
	char   			ac_value[255];
	char			ac_name[255];
	char   			*ac_delimiters = ":;,.-";
	char   			*pstraux;
	P2_MTS_TAG_DEF	mtsadd;

	/*******************
	** [EVT]
	********************/
	if( !i_reload )
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "EVT",
								 "SSID-OWNER",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				strncpy(ac_cSSID_Owner,ac_value,sizeof(ac_cSSID_Owner)-1);

				rc = get_profile_string( ac_PathCfgFile,
										 "EVT",
										 "SSID-NUMBER",
										 &found,
										 ac_value );
				if(!rc)
				{
					if(found)
					{
						i_nSSID_Number = (short)atoi(ac_value);

						rc = get_profile_string( ac_PathCfgFile,
												 "EVT",
												 "SSID-VERSION",
												 &found,
												 ac_value );
						if(!rc)
						{
							if(found)
							{
								strncpy(ac_cSSID_Version,ac_value,sizeof(ac_cSSID_Version)-1);

								//
								//  initialize EVT on $0
								//
								if ( !sspevt_init( "TFS-LTE",
												   ac_cSSID_Owner,
												   i_nSSID_Number,
												   ac_cSSID_Version ) )
								{
									EVT_manage_init();
								}
								else
									ret = 0;
							}
							else
								ret = 0;
						}
						else
							ret = 0;
					}
					else
						ret = 0;
				}
				else
					ret = 0;
			}
			else
				ret = 0;
		}
		else
			ret = 0;
	}

	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "EVT",
								 "NBR-ALERT-MSG",
								 &found,
								 ac_value );
		if(!rc)
		{
			i_nbr_alert_msg = 1; // Default value 1 msg
			if(found)
			{
				i_nbr_alert_msg = (short)atoi(ac_value);
				if(i_nbr_alert_msg < 0)
					i_nbr_alert_msg = 1;
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [EVT][NBR-ALERT-MSG] - set to 1" );
			}
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [EVT][NBR-ALERT-MSG]" );
		}
	}

	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "EVT",
								 "INTERVAL-ALERT-MSG-TIME",
								 &found,
								 ac_value );
		if(!rc)
		{
			i_interval_time = 300; // Default value in seconds 300"
			if(found)
			{
				i_interval_time = (short)atoi(ac_value);
				if(i_interval_time < 0)
					i_interval_time = 300;
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [EVT][INTERVAL-ALERT-MSG-TIME] - set to 5'" );
			}
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [EVT][INTERVAL-ALERT-MSG-TIME]" );
		}
	}
	/*******************
	** [DIAMETER]
	********************/
	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								"DIAMETER",
								"DIAMETER-PLATFORM-ID",
								&found,
								ac_value );
		if(!rc)
		{
			c_srv_id = 0x00;
			if(found)
				c_srv_id = ac_value[0];
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [DIAMETER][DIAMETER-PLATFORM-ID]" );
		}
	}

	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								"DIAMETER",
								"DIAMETER-APPLICATION-ID",
								&found,
								ac_value );
		if(!rc)
		{
			i_application_id = EPC_S6a; // S6a
			if(found)
				i_application_id = atoi(ac_value);
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [DIAMETER][DIAMETER-APPLICATION-ID]" );
		}
	}


	if(!i_reload && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "DIAMETER",
								 "OWN-FQDN",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				strncpy(ac_fqdn,ac_value,sizeof(ac_fqdn)-1);

				rc = get_profile_string( ac_PathCfgFile,
										 "DIAMETER",
										 "OWN-REALM",
										 &found,
										 ac_value );
				if(!rc)
				{
					if(found)
					{
						strncpy(ac_realm,ac_value,sizeof(ac_realm)-1);

						rc = get_profile_string( ac_PathCfgFile,
												 "DIAMETER",
												 "OWN-URI",
												 &found,
												 ac_value );
						if(!rc)
						{
							if(found)
							{
								strncpy(ac_uri,ac_value,sizeof(ac_uri)-1);

								rc = get_profile_string( ac_PathCfgFile,
														 "DIAMETER",
														 "OWN-VENDOR-ID",
														 &found,
														 ac_value );
								if(!rc)
								{
									if(found)
									{
										i_vendor_id = atoi(ac_value);

										rc = get_profile_string( ac_PathCfgFile,
																 "DIAMETER",
																 "OWN-PRODUCT-NAME",
																 &found,
																 ac_value );
										if(!rc)
										{
											if(found)
											{
												strncpy(ac_product_name,ac_value,sizeof(ac_product_name)-1);

												if( SetDiaEnvConfig( ac_fqdn,				/**< own FQDN */
																	 ac_realm,				/**< own Realm */
																	 ac_uri,				/**< own diameter URI */
																	 i_vendor_id,			/**< own vendor id */
																	 i_application_id,		/**< application identify */
																	 ac_product_name ) )	/**< own product name */
												{
													EVT_manage( EVTN_LOAD_PARAM_MISSING,
																0,
																0,
																'A',
																"SetDiaEnvConfig error" );
													ret = 0;
												}
												else
													p_conf = GetDiaEnvConfig();
											}
											else
											{
												ret = 0;
												EVT_manage( EVTN_LOAD_PARAM_MISSING,
															0,
															0,
															'A',
															"Missing [DIAMETER][OWN-PRODUCT-NAME]" );
											}
										}
										else
										{
											ret = 0;
											EVT_manage( EVTN_LOAD_PARAM_MISSING,
														0,
														0,
														'A',
														"Missing [DIAMETER][OWN-PRODUCT-NAME]" );
										}
									}
									else
									{
										ret = 0;
										EVT_manage( EVTN_LOAD_PARAM_MISSING,
													0,
													0,
													'A',
													"Missing [DIAMETER][OWN-VENDOR-ID]" );
									}
								}
								else
								{
									ret = 0;
									EVT_manage( EVTN_LOAD_PARAM_MISSING,
												0,
												0,
												'A',
												"Missing [DIAMETER][OWN-VENDOR-ID]" );
								}
							}
							else
							{
								ret = 0;
								EVT_manage( EVTN_LOAD_PARAM_MISSING,
											0,
											0,
											'A',
											"Missing [DIAMETER][OWN-URI]" );
							}
						}
						else
						{
							ret = 0;
							EVT_manage( EVTN_LOAD_PARAM_MISSING,
										0,
										0,
										'A',
										"Missing [DIAMETER][OWN-URI]" );
						}
					}
					else
					{
						ret = 0;
						EVT_manage( EVTN_LOAD_PARAM_MISSING,
									0,
									0,
									'A',
									"Missing [DIAMETER][OWN-REALM]" );
					}
				}
				else
				{
					ret = 0;
					EVT_manage( EVTN_LOAD_PARAM_MISSING,
								0,
								0,
								'A',
								"Missing [DIAMETER][OWN-REALM]" );
				}
			}
			else
			{
				ret = 0;
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [DIAMETER][OWN-FQDN]" );
			}
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [DIAMETER][OWN-FQDN]" );
		}
	}

	if(i_reload >= 0 && ret)
	{
		i_redirect_indication_flag = 0; // default

		rc = get_profile_string( ac_PathCfgFile,
								 "DIAMETER",
								 "REDIRECT-INDICATION-STRATEGY",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				i_redirect_indication_flag = (short)atoi(ac_value);

				if( i_redirect_indication_flag != 1 &&
					i_redirect_indication_flag != 0 )
				{
					i_redirect_indication_flag = 0; // Default
				}
			}
		}
	}

	if(!i_reload && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "DIAMETER",
								 "MAX-FQDN-REDIRECT-HOST-ENTRIES",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				i_max_fqdn_host_entries = (short)atoi(ac_value);

				if( i_max_fqdn_host_entries )
				{
					for(j=1;j<=i_max_fqdn_host_entries;j++)
						memset(&ac_fqdn_redirect_host[j],0x00,sizeof(ac_fqdn_redirect_host[j]));

					i_host_found = 0;
					for(j=1;j<=i_max_fqdn_host_entries;j++)
					{
						sprintf(ac_name,"FQDN-REDIRECT-HOST-%d",j);

						rc = get_profile_string( ac_PathCfgFile,
												 "DIAMETER",
												 ac_name,
												 &found,
												 ac_value );
						if(!rc)
						{
							if(found)
							{
								i_host_found++;
								if( memcmp(ac_value,"aaa://",6) &&
									memcmp(ac_value,"AAA://",6)	)
								{
									strcpy(ac_fqdn_redirect_host[i_host_found],"aaa://");
									strncat(ac_fqdn_redirect_host[i_host_found],ac_value,sizeof(ac_fqdn_redirect_host[i_host_found]) - 7);
								}
								else
									strncpy(ac_fqdn_redirect_host[i_host_found],ac_value,sizeof(ac_fqdn_redirect_host[i_host_found]) - 1);
							}
						}
						else
							break;
					}

					if( i_host_found )
					{
						if( i_host_found != i_max_fqdn_host_entries )
							i_max_fqdn_host_entries = i_host_found;
					}
					else
					{
						ret = 0;

						EVT_manage( EVTN_LOAD_PARAM_MISSING,
									0,
									0,
									'A',
									"Missing [DIAMETER] FQDN-REDIRECT-HOST not found" );
					}
				}
				else
				{
					EVT_manage( EVTN_LOAD_PARAM_MISSING,
								0,
								0,
								'A',
								"No default FQDN-REDIRECT-HOST entries set" );
				}
			}
			else
			{
				ret = 0;

				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [DIAMETER][MAX-FQDN-REDIRECT-HOST-ENTRIES]" );
			}
		}
		else
		{
			ret = 0;

			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [DIAMETER][MAX-FQDN-REDIRECT-HOST-ENTRIES]" );
		}
	}

	/*******************
	** [CTX]
	********************/
	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "CTX",
								 "TASKID-TFS-LTE",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				i_tid_tfs_lte = (short)atoi(ac_value);

				rc = get_profile_string( ac_PathCfgFile,
										 "CTX",
										 "SRVCLASS-TFS-LTE",
										 &found,
										 ac_value );
				if(!rc)
				{
					if(found)
					{
						i_srvcl_tfs_lte =(short)atoi(ac_value);

						mtsadd.cpu_req		= 1;
						mtsadd.cpu			= i_my_cpu;
						mtsadd.task_id		= i_tid_tfs_lte;
						mtsadd.server_class	= i_srvcl_tfs_lte;

						setretAddr(mtsadd);
					}
					else
					{
						ret = 0;

						EVT_manage( EVTN_LOAD_PARAM_MISSING,
									0,
									0,
									'A',
									"Missing [CTX][SRVCLASS-LTE-SRV]" );
					}
				}
				else
					ret = 0;
			}
			else
			{
				ret = 0;

				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [CTX][TASKID-LTE-SRV]" );
			}
		}
		else
			ret = 0;
	}

	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								"CTX",
								"CTX-TIMEOUT",
								&found,
								ac_value );
		if(!rc)
		{
			l_Timer_Waiting_tfsmgr_Resp = (long)(60*100); // in cent
			if(found)
			{
				l_Timer_Waiting_tfsmgr_Resp = (long)(atol(ac_value)*100);
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [CTX][CTX-TIMEOUT] - set to 1'" );
			}
		}
		else
			ret = 0;
	}

	if(i_reload >= 0 && ret)
	{
		if(l_Timer_Waiting_tfsmgr_Resp < 6000)
			l_ctx_discarded_timeout = 18000; // 180"
		else
			l_ctx_discarded_timeout = (long)( 3 * l_Timer_Waiting_tfsmgr_Resp ); // default 3 * CTX-TIMEOUT

		rc = get_profile_string( ac_PathCfgFile,
								 "CTX",
								 "CTX-DISCARDED-TIMEOUT",
								 &found,
								 ac_value );
		if(!rc)
			if(found)
				l_ctx_discarded_timeout = (long)(atol(ac_value)*100);

		SetdiscardedTimeout(l_ctx_discarded_timeout);
	}

	if(i_reload >= 0 && ret)
	{
		l_ctx_lock = 200; // default 2"
		rc = get_profile_string( ac_PathCfgFile,
								 "CTX",
								 "CTX-LOCK-TIMEOUT",
								 &found,
								 ac_value );
		if(!rc)
			if(found)
				l_ctx_lock = (long)(atol(ac_value)*100);

		SetlockTimeout(l_ctx_lock);
	}

	if(i_reload >= 0 && ret)
	{
		i_ctx_protect_class = 0; // default
		rc = get_profile_string( ac_PathCfgFile,
								 "CTX",
								 "CTX-PROTECTED-CLASS",
								 &found,
								 ac_value );
		if(!rc)
			if(found)
				i_ctx_protect_class = (short)atoi(ac_value);

		SetprotectedClass(i_ctx_protect_class);
	}

	/*******************
	** [TFS-MGR]
	********************/
	if(i_reload >= 0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "TFS-MGR",
								 "MTS-TID-SVRC-TFS-MGR",
								 &found,
								 ac_value );
		if(!rc)
		{
			if (found)
			{
				pstraux = strtok( ac_value, ac_delimiters);
				if (pstraux)
				{
					if ( !(i_tfsmgr_tid = (short)atoi(pstraux)) )
					{
						ret = 0;
						EVT_manage( EVTN_LOAD_PARAM_MISSING,
									0,
									0,
									'A',
									"Wrong TaskId [TFS-MGR][MTS-TID-SVRC-TFS-MGR]" );
					}
					else
					{
						pstraux = strtok( NULL, ac_delimiters);
						if (pstraux)
						{
							if ( !(i_tfsmgr_srv = (short)atoi(pstraux)) )
							{
								ret = 0;
								EVT_manage( EVTN_LOAD_PARAM_MISSING,
											0,
											0,
											'A',
											"Wrong SrvClass [TFS-MGR][MTS-TID-SVRC-TFS-MGR]" );
							}
						}
					}
				}
			}
			else
			{
				ret = 0;
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [TFS-MGR][MTS-TID-SVRC-TFS-MGR]" );
			}
		}
		else
		{
			ret = 0;
			EVT_manage( EVTN_LOAD_PARAM_MISSING,
						0,
						0,
						'A',
						"Missing [TFS-MGR][MTS-TID-SVRC-TFS-MGR]" );
		}
	}

	/************************
	** [TFS-TRANSLATOR-DBASE]
	*************************/
	if(!i_reload && ret)
	{
		i_dbase_present = 0;
		rc = get_profile_string( ac_PathCfgFile,
								 "TFS-TRANSLATOR-DBASE",
								 "PATH-IMSI-DBASE",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				if( strlen(ac_value) > 0 )
				{
					strncpy(ac_path_imsi_db,ac_value,sizeof(ac_path_imsi_db)-1);

					rc = get_profile_string( ac_PathCfgFile,
											 "TFS-TRANSLATOR-DBASE",
											 "PATH-HSS-DBASE",
											 &found,
											 ac_value );
					if(!rc)
					{
						if(found)
						{
							if( strlen(ac_value) > 0 )
							{
								i_dbase_present = 1;
								strncpy(ac_path_hss_db,ac_value,sizeof(ac_path_hss_db)-1);

								rc = get_profile_string( ac_PathCfgFile,
														 "TFS-TRANSLATOR-DBASE",
														 "DBASE-OPEN-METHOD",
														 &found,
														 ac_value );
								if(!rc)
								{
									if(found)
									{
										c_open_db = (char)atoi(ac_value);

										if(c_open_db > 1)
											c_open_db = MBE_NO_WAITED; // 0
									}
									else
										c_open_db = MBE_NO_WAITED; // 0
								}
								else
									c_open_db = MBE_NO_WAITED; // 0
							}
							else
							{
								if(!i_max_fqdn_host_entries)
								{
									ret = 0;
									EVT_manage( EVTN_LOAD_PARAM_MISSING,
												0,
												0,
												'A',
												"No DBases have been set" );
								}
							}
						}
					}
				}
			}
		}
	}

	/*******************
	** [LOG]
	********************/
	if(!i_reload && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "LOG",
								 "PATH-LOG",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				strncpy(ac_path_log_file,ac_value,sizeof(ac_path_log_file)-1);

				rc = get_profile_string( ac_PathCfgFile,
										 "LOG",
										 "NUM-DAYS-OF-LOG",
										 &found,
										 ac_value );
				if(!rc)
				{
					i_num_days_of_log = 3; // 3 giorni
					if(found)
					{
						i_num_days_of_log = (short)atoi (ac_value);
						if(i_num_days_of_log < 0)
							i_num_days_of_log = 3; // 3 giorni
					}
					else
					{
						EVT_manage( EVTN_LOAD_PARAM_MISSING,
									0,
									0,
									'A',
									"Missing [LOG][NUM-DAYS-OF-LOG] - set to 3gg" );
					}

					rc = get_profile_string( ac_PathCfgFile,
											 "LOG",
											 "LOG-PREFIX-NAME",
											 &found,
											 ac_value );

					if(!rc)
					{
						if(found)
						{
							strncpy(ac_log_prefix_name,ac_value,sizeof(ac_log_prefix_name)-1);

						}
						else
						{
							strcpy(ac_log_prefix_name,ac_my_process_name + 1);
						}

						rc = (short)log_init ( ac_path_log_file,
											   ac_log_prefix_name,
											   i_num_days_of_log );

						if(!rc)
						{
							log_param_filecreate ( 1024 /*filecreate_primary_extent_size*/,
												   1024 /*filecreate_secondary_extent_size*/,
													900 /*filecreate_maximum_extents */ );
						}
					}
					else
						ret = 0;
				}
				else
					ret = 0;
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [LOG][PATH-LOG]" );
			}
		}
		else
			ret = 0;
	}

	if(i_reload>=0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "LOG",
								 "TRACE-LEVEL",
								 &found,
								 ac_value );
		if(!rc)
		{
			i_trace_level = LOG_INFO;

			if(found)
			{
				i_trace_level = (short)atoi (ac_value);
				if(i_trace_level < 0)
					i_trace_level = LOG_INFO;
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [LOG][TRACE-LEVEL] - set to INFO" );
			}

			if( i_trace_level >= LOG_DEBUG )
			{
				log_param( i_trace_level,
						   LOG_UNBUFFERED,
						   "" );
			}
			else
			{
				log_param( i_trace_level,
						   LOG_STAT,
						   "" );
			}
		}
		else
			ret = 0;
	}

	if(i_reload>=0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "LOG",
								 "TRACE-STRING",
								 &found,
								 ac_value );
		if(!rc)
		{
			if(found)
			{
				if(ac_value[0])
					log_set_trace(ac_value);
				else
					log_reset_trace();
			}
		}
	}

	/*******************
	** [STAT]
	********************/
	if(!i_reload && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "STAT",
								 "NBR-MAX-REG",
								 &found,
								 ac_value );

		if(!rc)
		{
			if(found)
			{
				i_stat_max_register=(short)atoi(ac_value);

				rc = get_profile_string( ac_PathCfgFile,
										 "STAT",
										 "GROUP",
										 &found,
										 ac_value );

				if(!rc)
				{
					if(found)
					{
						i_stat_group = (short)atoi(ac_value);
					}
				}
				else
					ret = 0;
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [STAT][NBR-MAX-REG]" );
			}
		}
		else
			ret = 0;
	}

	if(i_reload>=0 && ret)
	{
		rc = get_profile_string( ac_PathCfgFile,
								 "STAT",
								 "TIMEOUT-BUMP",
								 &found,
								 ac_value );

		if(!rc)
		{
			l_stat_bump_interval = (long)(5*60); // 5 '
			if(found)
			{
				l_stat_bump_interval = (long)(atol(ac_value) * 60);
				if(l_stat_bump_interval < 60)
					l_stat_bump_interval = (long)(60*1); // 1'
			}
			else
			{
				EVT_manage( EVTN_LOAD_PARAM_MISSING,
							0,
							0,
							'A',
							"Missing [STAT][TIMEOUT-BUMP] - set to 5'" );
			}
		}
		else
			ret = 0;
	}

    return(ret);
} // LoadParameters
