// ------------------------------------------------------
//
// Last Change: 14-04-2015
// ------------------------------------------------------
#ifndef _GTTSERV_H_
#define _GTTSERV_H_

#include <gttlib.h>

#define TAG_BUMP 		 100
#define TAG_RELOAD_PARAM 110

#define SYS_MSG_TIME_TIMEOUT    -22
#define SYS_MSG_STOP_1              -20
#define SYS_MSG_STOP_2          -105
#define SYS_MSG_COMMAND             -35

#define EVT_NUMBASE              (1000)
#define EVT_APPLNAME             "GT"
#define EVT_OWNER                "TIM"
#define EVT_ADMNUM               (790)
#define EVT_VERSION              "A01"

// translation types
#define TTYPEPC   (1)
#define TTYPEMGT  (2)   // non gestito
#define TTYPEGT   (3)

#define TTYPEGTGT (4) // steering of anti-steering, it validates only the GT (E.164). No translation.

// valid natureOfAddress
#define NANAT     (3)
#define NAINT     (4)

// valid numberingPlan
#define NPGT      (1)
#define NPPC      (2)
#define NPMGT     (7)

// result codes
#define RCSUCCESS          (0)
#define RCINVALIDTTYPE     (1)
#define RCDATANOTFOUND     (2)
#define RCINVALIDIPCADDR   (3)
#define RCINVALIDOPCODE    (4)

#define MAX_EXTERNAL_REFERENCE_LENGTH	512

// operation codes
#define OCQUERY    (3000)     // request (IN)
#define OCRESPONSE (3001)     // result  (OUT)

// INSAddressString
#define MAX_INS_STRING_LENGTH  32

#define MAX_ADDRESS_LEN_MNG	36	//IT/JPN: Max. MGT len = 30 + NULL + point code format (2) + point code (2) + NULL

typedef struct INS_String
{
   unsigned short  length;
   unsigned char   value[MAX_INS_STRING_LENGTH];
}INS_String;

typedef struct INS_AddressString
{
   unsigned char natureOfAddress;
   unsigned char numberingPlan;
   INS_String address;
}INSAddressString;

#pragma fieldalign shared2 io_sys_timeout
typedef struct io_sys_timeout
{
    short id;
    short i_socket;
    long  l_tag;
} IO_SYS_TIMEOUT;

#pragma fieldalign shared2 _sys_cmd
typedef struct _sys_cmd
{
    short id;
    short i_op;
    short i_cnt;
    char  ac_cmd[2048];
} SYS_COMMAND;

// IPC_Address
typedef struct IPC_Address
{
   unsigned char   choice;
#define choice_mts_address              0x01
#define choice_process_name             0x02
#define choice_extend_process_name      0x03
   union {
      P2_MTS_TAG_DEF          mts_address;
      P2_MTS_PROC_ADDR_DEF    process_name;
      P2_MTS_EPROC_ADDR_DEF   extend_process_name;
   } address;
} IPC_Address;

// struttura del messaggio di IPC
typedef struct s_gtt_data
{
   short                subsystem_id;        /* i/o */
   short                op_code;             /* i/o */
   short                if_version;          /* i/o */
   short                translation_type;    /* i/o */
   INSAddressString     query_data;          /* i/o */
   INSAddressString     query_response;      /* o   */
   short                SSN_1;               /* o   */
   short                SSN_2;               /* o   */
   short                SSN_3;               /* o   */
   short                SSN_4;               /* o   */
   short                SSN_5;               /* o   */
   char                 external_reference[MAX_EXTERNAL_REFERENCE_LENGTH];     /* i/o */
   short                result_code;         /* o   */
   IPC_Address          result_address;      /* i/o */
   unsigned char		c_tcap_map_errorcode;
   char					c_dualimsi_flag; 	 // 0x20 - Default | 0x01 - Dual Imsi
   char				    c_romumb; 			 // roaming unbundling defines
   short				i_arp_id; 			 // ARP - riporta al DB Decoupling, numerico intero
   char					filler[5];
} gtt_data;

#endif
