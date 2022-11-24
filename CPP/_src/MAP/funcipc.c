//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.01
//------------------------------------------------------------------------------
//
//   File Name   : funcipc.c
//   Created     : 01-09-2004
//   Last Change : 13-04-2015
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
//   Functions
//   ------------------
//
//---------------------< Include files >----------------------------------------
#include <string.h>
#include <strings.h>
#include <p2system.p2apdfh>
#include <erainc.ccpy>
#include <cssinc.cext>
#include <ssplog.h>
#include <sspfunc.h>
#include "ipcfunc.h"

#define SS7_OUTCOME_PROCESS 0xB0B0

//
// SS_SEND function
//
short Func_SS_SEND( short i_upd_subsys,
                    short i_upd_class,
                    char *key,
                    char *st_buf,
                    short i_len_buf )
{
    short i_ret;

    i_ret = SS_SEND_MSG( i_upd_subsys,
                         i_upd_class,
                         (void*)key,
                         (short)strlen(key),
                         (void *)st_buf,
                         i_len_buf );

    if( i_ret )
        log_(LOG_ERROR,"%s: SS_SEND: Err.[%d]",
        		__FUNCTION__,
        		i_ret);
    else
        log_(LOG_DEBUG2, "%s: SS_SEND: Subsys Id[%d] - Class[%d] successfully",
                __FUNCTION__,
        		i_upd_subsys,
                i_upd_class);

    return (i_ret);
}

//
// MTS by task_id + serverclass + CPU
//
short Func_MTS_SEND_Taskid( short i_task_id,
                            short i_srv_class,
                            short i_cpu_req,
                            short i_cpu,
                            char *st_buf,
                            short i_len )
{
    short                   i_err;
    short                   i_ret = SSP_SUCCESS;
    P2_MTS_STD_ADDR_DEF     mts_addr;

    memset(&mts_addr,0x00, sizeof(P2_MTS_STD_ADDR_DEF));

    mts_addr.flags.generic_id   = '#';
    mts_addr.flags.mode         = 0;
    mts_addr.flags.zero         = 0;
    mts_addr.to.cpu_req         = 0;
    mts_addr.to.task_id         = i_task_id;
    mts_addr.to.server_class    = i_srv_class;
	mts_addr.to.cpu_req			= 0;

    if( i_cpu_req )
    {
        if( (i_cpu >= 0) && // First CPU
            (i_cpu <= 15) ) // Last CPU
        {
			mts_addr.to.cpu_req = 1;
            mts_addr.to.cpu = i_cpu;
        }
        else
        {
            log_(LOG_ERROR, "%s: MTS_SEND: Wrong CPU range[%d] - Default CPU used ",
            		__FUNCTION__,
            		i_cpu);
        }
    }

    if( i_ret == SSP_SUCCESS )
    {
        i_err = MTS_SEND( &mts_addr,
                         (char *)st_buf,
                         i_len );

        if ( i_err != P2_ST_NOERROR )
        {
			i_ret = i_err;

            log_(LOG_ERROR, "%s: MTS_SEND: - Err[%d]",
            		__FUNCTION__,
            		i_err);
        }
        else
            log_(LOG_DEBUG2, "%s: MTS_SEND: - Task.Id[%d] - SRV_Class[%d] successfully",
					__FUNCTION__,
            		i_task_id,
					i_srv_class);
    }

    return (i_ret);
}

//
// MTS to SS7 out process
//
short SS7_MTS_SEND_Taskid( char *st_buf,
                           short i_len,
                           short i_cpu )
{
    short                   i_err;
    short                   i=0;
    short                   i_ret = SSP_SUCCESS;
    short                   mts_send_addr[4];

    for (;i<4 ;i++ )
        mts_send_addr[i] = 0;

    mts_send_addr[0] = 0x2300;     // mts info
    mts_send_addr[1] = SS7_OUTCOME_PROCESS;  // task id server class of i/o process

    mts_send_addr[2] = 0xD080;     // task id server class of MAP cp app
    mts_send_addr[3] = 0;

    mts_send_addr[1] = (short)(mts_send_addr[1] | i_cpu);
    mts_send_addr[2] = (short)(mts_send_addr[2] | i_cpu);

    if( i_ret == SSP_SUCCESS )
    {
        i_err = MTS_SEND( mts_send_addr,
                         (char *)st_buf,
                         i_len );

        if ( i_err != P2_ST_NOERROR )
        {
			i_ret = i_err;
            log_(LOG_ERROR, "%s: SS7-MTS_SEND - Err[%d]",
            		__FUNCTION__,
            		i_err);
        }
        else
            log_(LOG_DEBUG2, "%s: SS7-MTS_SEND successfully",__FUNCTION__);
    }

    return (i_ret);
}

//
// MTS by process name
//
short Func_MTS_SEND_Proc( char *ac_pname,
                          char *st_buf,
                          short i_len )
{
    short                   i_err;
    short                   i_ret = SSP_SUCCESS;
    P2_MTS_PROC_ADDR_DEF    mts_addr;

    memset(&mts_addr,' ', sizeof(P2_MTS_PROC_ADDR_DEF));

    mts_addr.generic_id = ac_pname[0];
    memcpy( mts_addr.procname,
    		ac_pname+1,
    		strlen(&ac_pname[1]) ); // skip '$'

    i_err = MTS_SEND( &mts_addr,
                     (char *)st_buf,
                     i_len );

    if ( i_err != P2_ST_NOERROR )
    {
		i_ret = SSP_ERROR;

        log_(LOG_ERROR, "%s: MTS_SEND_PROCNAME: - Procname[%s] - Err[%d]",
				__FUNCTION__,
        		ac_pname,
				i_err);
    }
    else
        log_(LOG_DEBUG2, "%s: MTS_SEND_PROCNAME: - Procname[%s] successfully",
        		__FUNCTION__,
        		ac_pname);

    return (i_ret);
}
