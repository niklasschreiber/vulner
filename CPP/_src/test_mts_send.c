#if (_TNS_E_TARGET)
T0000H06_31MAR2017_KTSTEA10() {};
#elif (_TNS_X_TARGET)
T0000L16_31MAR2017_KTSTEA10() {};
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <tal.h>

#include <cextdecs.h>
#include <cssinc.cext>
#include <p2apdf.h>

#include "ts.h"

void Process_Initialization( void );
void sendLteBuffer(short opcode, char *mccmnc, char *mgt, char *imsi);
void sendMapBuffer(short opcode, char *gt, char *mgt, char *imsi);

/*==================================*/
/* SOURCE                           */
/*==================================*/
int main(int argc, char *argv[])
{
    Process_Initialization();

	if (argc < 4)
	{
		printf("\nUsage:\n");
		printf("\t%s <gsm|gprs> <gt> <mgt> <imsi>\n", argv[0]);
		printf("\t%s <lte> <mcc/mnc> <mgt> <imsi>\n", argv[0]);
		printf("Examples:\n");
		printf("\t%s gsm  33689000 393390123456789 222010123456789\n", argv[0]);
		printf("\t%s gprs 33689000 393390123456789 222010123456789\n", argv[0]);
		printf("\t%s lte  20801    393390123456789 222010123456789\n", argv[0]);
		printf("\n");
		exit(0);
	}

	if (!strcasecmp(argv[1], "gsm")) sendMapBuffer(UL_OP_CODE, argv[2], argv[3], argv[4]);
	else if (!strcasecmp(argv[1], "gprs")) sendMapBuffer(UL_OP_CODE_GPRS, argv[2], argv[3], argv[4]);
	else if (!strcasecmp(argv[1], "lte")) sendLteBuffer(ULR_CMD, argv[2], argv[3], argv[4]);
	else
	{
		printf("\nError: bad argument %s\n\n", argv[1]);
	}

	exit(0);
}

void sendLteBuffer(short opcode, char *mccmnc, char *mgt, char *imsi)
{
	char	*wrk_str;
	short	ret;

	P2_MTS_STD_ADDR_DEF		mts_addr_std;
	P2_MTS_PROC_ADDR_DEF	mts_addr;
	TFS_LTE_IPC				lte_buffer;

	memset((char *)&lte_buffer, 0x00, sizeof(lte_buffer));
	lte_buffer.i_tag = TFS_LTE;

	// Set op_code
	lte_buffer.i_op = opcode;

	// Set MCC/MNC
	strcpy(lte_buffer.ac_visited_PLMN_Id, mccmnc);

	// Set IMSI
	lte_buffer.imsi.length = strlen(imsi);
	memcpy(lte_buffer.imsi.value, imsi, strlen(imsi));

	memset(lte_buffer.external_reference, 0x20, sizeof(lte_buffer.external_reference));
	lte_buffer.ResultType = 0;
	lte_buffer.ResultCode = 0;
	lte_buffer.result_address.choice = 1;
	lte_buffer.result_address.address.mts_address.task_id = atoi(getenv("LTE_TASKID"));
	lte_buffer.result_address.address.mts_address.server_class = atoi(getenv("LTE_SVRCLASS"));
	memset(lte_buffer.ac_filler, 0x20, sizeof(lte_buffer.ac_filler));

	memset((char *)&mts_addr_std, 0x20, sizeof(mts_addr_std));
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.task_id       = 0;
	mts_addr_std.to.server_class  = 0;
	mts_addr_std.flags.mode       = 0;
	mts_addr_std.flags.zero       = 0;
	mts_addr_std.to.cpu_req       = 0;
	mts_addr_std.to.cpu           = 0;

	if ( ( wrk_str = getenv( "DEST_TASKID" ) ) != NULL )
		mts_addr_std.to.task_id = (short)atoi( wrk_str );

	if ( ( wrk_str = getenv( "DEST_SVRCLASS" ) ) != NULL )
		mts_addr_std.to.server_class = (short)atoi( wrk_str );

	if ( ( wrk_str = getenv( "DEST_CPU" ) ) != NULL )
	{
		mts_addr_std.to.cpu_req       = 1;
		mts_addr_std.to.cpu           = (short)atoi( wrk_str );
	}

	if ( ( wrk_str = getenv( "DEST_PRCNAME" ) ) != NULL )
	{
		mts_addr.generic_id = '$';
		memset( mts_addr.procname, ' ', sizeof(mts_addr.procname) );
		memcpy( mts_addr.procname, wrk_str, strlen(wrk_str) );
/*
		mts_addr.cpu = ' ';
		mts_addr.pin = ' ';
*/
		memset((char *)&mts_addr.unused, ' ', 2);

		ret = MTS_SEND(&mts_addr, (char *)&lte_buffer, sizeof(lte_buffer));

		if ( ret == 0 )
		{
			printf( "\nSent request to [$%s]\n", wrk_str );
		}
	}
	else
	{
		ret = MTS_SEND(&mts_addr_std, (char *)&lte_buffer, sizeof(lte_buffer));

		if ( ret == 0 )
		{
			printf( "\nSent request to [%d;%d]\n", mts_addr_std.to.task_id, mts_addr_std.to.server_class );
		}
	}

	if ( ret )
	{
		printf( "\nError [%d] in MTS_SEND\n", ret );
	}
}

void sendMapBuffer(short opcode, char *gt, char *mgt, char *imsi)
{
	char	*wrk_str;
	short	ret;

	P2_MTS_STD_ADDR_DEF		mts_addr_std;
	P2_MTS_PROC_ADDR_DEF	mts_addr;
	t_ts_data				map_buffer;

	memset((char *)&map_buffer, 0x00, sizeof(map_buffer));
	map_buffer.i_tag = TAG_MAP_IN;

	// Set op_code
	map_buffer.op_code = opcode;

	// Set Global Title
	map_buffer.MGT_mitt.address.length = strlen(gt);
	memcpy(map_buffer.MGT_mitt.address.value, gt, strlen(gt));

	// Set Mobile Global Title
	map_buffer.MGT_dest.address.length = strlen(mgt);
	memcpy(map_buffer.MGT_dest.address.value, mgt, strlen(mgt));

	// Set IMSI
	map_buffer.imsi.length = strlen(imsi);
	memcpy(map_buffer.imsi.value, imsi, strlen(imsi));

	memset(map_buffer.ExternalReference, 0x20, sizeof(map_buffer.ExternalReference));
	map_buffer.ResultType = 0;
	map_buffer.ResultCode = 0;
	map_buffer.result_address.choice = 1;
	map_buffer.result_address.address.mts_address.task_id = atoi(getenv("MAP_OUT_TASKID"));
	map_buffer.result_address.address.mts_address.server_class = atoi(getenv("MAP_OUT_SVRCLASS"));
	memset(map_buffer.filler, 0x20, sizeof(map_buffer.filler));

	memset((char *)&mts_addr_std, 0x20, sizeof(mts_addr_std));
	mts_addr_std.flags.generic_id = '#';
	mts_addr_std.to.task_id       = 0;
	mts_addr_std.to.server_class  = 0;
	mts_addr_std.flags.mode       = 0;
	mts_addr_std.flags.zero       = 0;
	mts_addr_std.to.cpu_req       = 0;
	mts_addr_std.to.cpu           = 0;

    if ( ( wrk_str = getenv( "DEST_TASKID" ) ) != NULL )
        mts_addr_std.to.task_id = (short)atoi( wrk_str );

    if ( ( wrk_str = getenv( "DEST_SVRCLASS" ) ) != NULL )
        mts_addr_std.to.server_class = (short)atoi( wrk_str );

    if ( ( wrk_str = getenv( "DEST_CPU" ) ) != NULL )
    {
        mts_addr_std.to.cpu_req       = 1;
        mts_addr_std.to.cpu           = (short)atoi( wrk_str );
    }

    if ( ( wrk_str = getenv( "DEST_PRCNAME" ) ) != NULL )
    {
        mts_addr.generic_id = '$';
        memset( mts_addr.procname, ' ', sizeof(mts_addr.procname) );
        memcpy( mts_addr.procname, wrk_str, strlen(wrk_str) );
/*
		mts_addr.cpu = ' ';
		mts_addr.pin = ' ';
*/
		memset((char *)&mts_addr.unused, ' ', 2);

        ret = MTS_SEND(&mts_addr, (char *)&map_buffer, sizeof(map_buffer));

        if ( ret == 0 )
        {
            printf( "\nSent request to [$%s]\n", wrk_str );
        }
    }
    else
    {
        ret = MTS_SEND(&mts_addr_std, (char *)&map_buffer, sizeof(map_buffer));

        if ( ret == 0 )
        {
            printf( "\nSent request to [%d;%d]\n", mts_addr_std.to.task_id, mts_addr_std.to.server_class );
        }
    }

    if ( ret )
    {
        printf( "\nError [%d] in MTS_SEND\n", ret );
    }
}

void Process_Initialization( void )
{
    char  *wrk_str;
    char  ac_my_process_name[20];
    short i_proch[20];
    short i_maxlen = sizeof(ac_my_process_name);
    short bpid;
    char  mm[24];
    char  ac_cpu[5];
    short i_my_cpu;
    short i_node_id;
    short i_my_node_id;
    short i_my_tid = 41;
    short i_my_svr_cls = 24;

    PROCESSHANDLE_GETMINE_(i_proch);

    PROCESSHANDLE_DECOMPOSE_( i_proch,&i_my_cpu,,,,,,ac_my_process_name,i_maxlen,&i_maxlen,);

    /* ------------------------------------------------------------------------
    ** Node parameters
    -------------------------------------------------------------------------*/
    if ( ( wrk_str = getenv( "CSS_MM_TASKID" ) ) != NULL )
        i_my_tid = (short)atoi( wrk_str );

    /* ------------------------------ */
    if ( ( wrk_str = getenv( "CSS_MM_SVRCLASS" ) ) != NULL )
        i_my_svr_cls = (short)atoi( wrk_str );

    /* ------------------------------ */
    i_node_id = 'A';
    if ( ( wrk_str = getenv( "CSS_NODE_ID" ) ) != NULL )
        i_node_id = (short)wrk_str[0];

    /* ------------------------------------------------------------------------
    ** Inizializzazione INS
    -------------------------------------------------------------------------*/

    strncpy( mm, "$MMyx                   ", 24);

    sprintf( ac_cpu, "%x", i_my_cpu );
    mm[3] = ac_cpu[0];
    mm[4] = (char)i_node_id;
    i_node_id = (short)(i_node_id * 256);

    i_my_node_id = L_CINITIALIZE( i_my_tid,
                                  i_my_svr_cls,
                                  ,
                                  &bpid,
                                  ,(short *) mm,
                                  i_node_id );

    if ( i_my_node_id == 0 )
    {
        mm[5] = 0;
        printf( "*** %s *** Error in L_CINITIALIZE - %s ***",
                ac_my_process_name, mm );
        exit(0);
    }

    L_INITIALIZE_END();

    return;
}
