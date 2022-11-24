// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s6afunc.h
//   Last Change : 16-05-2013
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------
#ifndef _S6AFUNC_H
#define _S6AFUNC_H

#include <p2system.p2apdfh>

#define MAX_STAT_FILE_AND_TIME_LASTUP 	3

enum _file_check
{
	FILE_LEIRINI_CHECK = 0,
};

short checkChgFile( char *ac_path_file_ini_oss,
					short i_idx );

void setChgFile( char *g_ini_file,
				 char *ac_path_file_ini_oss );

unsigned char *utf8_to_extended_ascii ( char *string,
										int *len );

P2_MTS_TAG_DEF getretAddr(void);

void setretAddr(P2_MTS_TAG_DEF ins_addr);

short Func_MTS_SEND_Taskid( short i_task_id,
                            short i_srv_class,
                            short i_cpu_req,
                            short i_cpu,
                            char *st_buf,
                            short i_len );

short Func_MTS_SEND_Proc( char *ac_procname,
                          char *st_buf,
                          short i_len );

void SetThroughputStat( long long ts,
		                char *ac_postfix );

#endif
