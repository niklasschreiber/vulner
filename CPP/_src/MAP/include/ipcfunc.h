//------------------------------------------------------------------------------
//   PROJECT : Traffic Steering - v 1.01
//------------------------------------------------------------------------------
//
//   File Name   : trsevt.h
//   Created     : 01-09-2004
//   Last Change : 16-10-2008
//
//------------------------------------------------------------------------------
//   Description
//   -----------
//
//------------------------------------------------------------------------------
#ifndef __IPCFUNC_H
#define __IPCFUNC_H

#define MAX_IPC_BUFFER_LEN  4096

#pragma fieldalign shared2 io_ctrl_common_blk
typedef struct io_ctrl_common_blk
{
    short in_use;
    char  fname[36];
    short reply_pending;
    short id;
    short error;
    short i_status;
    short idx;
    char  data[MAX_IPC_BUFFER_LEN];
} IO_CTRL_COMMON_BLK;

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

#pragma fieldalign shared2 mgt_key_struct
typedef struct mgt_key_struct
{
        short   i_key;
        short   i_task_id;
        short   i_serverclass;
} TS_MGT_KEY;

//
// SS_SEND parameters
//
enum { SS_SUCCESS,
       SS_FAILED } _ss;

short Func_SS_SEND( short i_upd_subsys,
                    short i_upd_class,
                    char *key,
                    char *st_buf,
                    short i_len_buf );

short SS7_MTS_SEND_Taskid( char *st_buf,
                           short i_len,
                           short i_cpu );

short Func_MTS_SEND_Taskid( short i_task_id,
                            short i_srv_class,
                            short i_cpu_req,
                            short i_cpu,
                            char *st_buf,
                            short i_len );

short Func_MTS_SEND_Proc( char *ac_procname,
                          char *st_buf,
                          short i_len );

#endif
