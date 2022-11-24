//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.01
//------------------------------------------------------------------------------
//
//   File Name   : tfsdef.c
//   Created     : 01-09-2004
//   Last Change : 15-04-2015
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __TFSDEF_H
#define __TFSDEF_H

#define EXIT_DELAY 500

#define SYS_MSG_TIME_TIMEOUT    -22
#define SYS_MSG_STOP_1              -20
#define SYS_MSG_STOP_2          -105
#define SYS_MSG_COMMAND             -35

#define TAG_RELOAD_PARAM    100
#define TAG_BUMP                110
#define TAG_ALLOW_VPC       120

#define TS_TAG          10000   // TS manager tag
#define GTT_TAG         15000   // GTT
#define MAP_OUT_TAG     20000   // Mapout tag

#define REQUEST_TO_GTT_OPCODE       3000    // request to GTT
#define RESPONSE_FROM_GTT_OPCODE    3001    // response from GTT
#define GTT_INTERFACE_VERSION          1    // GTT interface version

#define GTT_RESULT_SUCCESS          0
#define NUMBERING_PLAN_NO_SPARE         5

#define MAX_E214_NBR_OF_DIGIT	17 // KDDI request

#define VPC_UP      0x00
#define VPC_DOWN    0x01

//
// load/reload parameters
//
enum { LOAD,
       RELOAD } _load_param;

//
// STOP/START parameters
//
enum { _STOP_,
       _START_ } _start_stop_param;

enum { MAPIN_GTT_RELAY,
       MAPOUT_GTT_MAPOUT,
       MAPIN_TS_MAPOUT,
} _process_type;

//enum { PC = 1,
//       MGT,
//       GT,
//       GT_to_GT // steering of anti-steering if the SCCP CdPA NPI = E.164 instead of E.241
//} _translation_type;

// translation types
#define TTYPEPC   (1)
#define TTYPEMGT  (2)   // non gestito
#define TTYPEGT   (3)

#define TTYPEGTGT (4) // steering of anti-steering, it validates only the GT (E.164). No translation.

enum { UNKNOWN,
       MSISDN,
       SPARE,
       DATA,
       TELEX,
       MARITIME,
       IMSI,
       NP_MGT
} _numberingPlan;

enum { SUBSCRIBENUMBER = 1,
       RESERVED,
       NATIONAL,
       INTERNATIONAL
} _natureofaddress;

enum { STEERING,
       RELAY,
       NOP
} _relay_req;

enum { RELAY_REQ        = 0x00,
       MAP_ERR_REQ      = 0x01,
       TCAP_ABORT_REQ   = 0x02,
       TCAP_REJECT_REQ  = 0x03,
       FORCE_RELAY_REQ  = 0x04
} _req_from_ts;

#endif
