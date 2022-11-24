//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.00
//------------------------------------------------------------------------------
//
//   File Name   : gsmdef.h
//   Created     : 01-09-2004
//   Last Change : 29-03-2018
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __GSMDEF_H
#define __GSMDEF_H

//------------------------------------------------------------------------------
//Map error code
//--------------
//
//unknownSubscriber_ErrorCode                                      1
//unknownBaseStation_ErrorCode                                     2
//unknownMSC_ErrorCode                                             3
//unidentifiedSubscriber_ErrorCode                                 5
//absentSubscriberSM_ErrorCode									   6
//unknownEquipment_ErrorCode                                       7
//roamingNotAllowed_ErrorCode                                      8
//illegalSubscriber_ErrorCode                                      9
//bearerServiceNotProvisioned_ErrorCode                           10
//teleserviceNotProvisioned_ErrorCode                             11
//illegalEquipment_ErrorCode                                      12
//callBarred_ErrorCode                                            13
//forwardingViolation_ErrorCode                                   14
//cug_Reject_ErrorCode                                            15
//illegalSS_Operation_ErrorCode                                   16
//ss_ErrorStatus_ErrorCode                                        17
//ss_NotAvailable_ErrorCode                                       18
//ss_SubscriptionViolation_ErrorCode                              19
//ss_Incompatibility_ErrorCode                                    20
//facilityNotSupported_ErrorCode                                  21
//invalidTargetBaseStation_ErrorCode                              23
//noRadioResourceAvailable_ErrorCode                              24
//noHandoverNumberAvailable_ErrorCode                             25
//subsequentHandoverFailure_ErrorCode                             26
//absentSubscriber_ErrorCode                                      27
//incompatibleTerminal_ErrorCode								  28
//shortTermDenial_ErrorCode										  29
//longTermDenial_ErrorCode										  30
//subscriberBusyForMT_SMS_ErrorCode                               31
//sm_DeliveryFailure_ErrorCode                                    32
//messageWaitingListFull_ErrorCode                                33
//systemFailure_ErrorCode                                         34
//dataMissing_ErrorCode                                           35
//unexpectedDataValue_ErrorCode                                   36
//pw_RegistrationFailure_ErrorCode                                37
//negativePW_Check_ErrorCode                                      38
//noRoamingNumberAvailable_ErrorCode                              39
//tracingBufferFull_ErrorCode                                     40
//numberOfPW_AttemptsViolation_ErrorCode                          43
//numberChanged_ErrorCode                                         44
//busySubscriber_ErrorCode										  45
//noSubscriberReply_ErrorCode									  46
//forwardingFailed_ErrorCode									  47
//orNotAllowed_ErrorCode										  48
//atiNotAllowed_ErrorCode										  49
//noGroupCallNumberAvaiable_ErrorCode							  50
//resourceLimitation_ErrorCode									  51
//unauthorizedRequestingNetwork_ErrorCode						  52
//unauthorizedLCSClient_ErrorCode								  53
//positionMethodFailure_ErrorCode								  54
//unknownOrUnreacheableLCSClient_ErrorCode						  58
//unknownAlphabet_ErrorCode                                       71
//ussd_Busy_ErrorCode                                             72
//
//------------------------------------------------------------------------------

#define HLR     6

// Map operation
#define UpdateGSMLocation_Request_OperationCode         2
#define Parameters_request                                  9
#define RegisterSS                                      10
#define EraseSS                                             11
#define Interogate_SS                                   14
#define SendRoutingInfo                                     22
#define UpdateGPRSLocation_Request_OperationCode        23
#define SendRoutingInfo_for_SM                              45
#define ReportDeliveryStatus                            47
#define Authentication_Request                              56
#define Restore_Data                                    57
#define ProcessUnstructuredSSRequested                      59
#define Process_Unstructured_SS_Request                 60
#define Ready_For_Short_Message                             66
#define Purge_Mobile_Subscriber                         67
#define SendRoutingInfoForLCS                               85

#endif
