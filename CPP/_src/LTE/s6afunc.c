// ------------------------------------------------------------------------------
//   PROJECT : LTE-TFS v 01.00
// ------------------------------------------------------------------------------
//
//   File Name   : s6afunc.c
//   Last Change : 19-02-2015
//
// ------------------------------------------------------------------------------
//   Description
//   -----------
//	20-12-2011: create new
// ------------------------------------------------------------------------------
//   Functions
//   ------------------
//
// ------------------------------------------------------------------------------

//---------------------< Include files >-------------------------------------
#pragma nolist
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <sys/stat.h>
#include <memory.h>
#include <limits.h>
#include <strings.h>
#include <ctype.h>
#include <time.h>
#include <p2system.p2apdfh>
#include <cssinc.cext>
#include <cextdecs.h (JULIANTIMESTAMP)>
#include <ssplog.h>
#include <sspstat.h>
#include "s6astat.h"
#include "s6afunc.h"
#pragma list

// ---------------------------------------------------------------------------------------------------------
static P2_MTS_TAG_DEF _ins_retAddr;
// ---------------------------------------------------------------------------------------------------------
/** ---------------------------------------------------------------------------
*
* @param ac_path_file_ini_oss 	- in parameter - file
* @param i_idx	    			- in parameter - index of array of file
* \note Value Returned:
* \note       0 	Ok
* \note       1 	Ko
* -----------------------------------------------------------------------------
*/
short checkChgFile( char *ac_path_file_ini_oss,
				    short i_idx )
{
	short			i_ret = 0;
	short			i;
	static char		c_first_time = 1;
	struct stat		stat_file[MAX_STAT_FILE_AND_TIME_LASTUP];
	static time_t	time_lastup[MAX_STAT_FILE_AND_TIME_LASTUP];

	if(c_first_time == 1)
	{
		for(i=0;i< MAX_STAT_FILE_AND_TIME_LASTUP;i++)
			time_lastup[i] = 0;

		c_first_time = 0;
	}

	if(i_idx < MAX_STAT_FILE_AND_TIME_LASTUP)
	{
		lstat(ac_path_file_ini_oss, &stat_file[i_idx]);
		if (time_lastup[i_idx] != stat_file[i_idx].st_mtime)
		{
			time_lastup[i_idx] = stat_file[i_idx].st_mtime;
			i_ret = 1;
		}
	}
	else
		i_ret = 1;

	return i_ret;
}

void setChgFile( char *g_ini_file,
				 char *ac_path_file_ini_oss )
{
	char	ac_wrk_str[64];
	char	*wrk_str;

	if( g_ini_file &&
		ac_path_file_ini_oss )
	{
		// Compose OSS filename for reload check
		if(*g_ini_file == '\\')
		{
			// Remote file
			memset(ac_wrk_str, 0x00,sizeof(ac_wrk_str));

			strncpy(ac_wrk_str, g_ini_file+1,sizeof(ac_wrk_str)-1);
			wrk_str = strtok(ac_wrk_str, ".");
			if(wrk_str)
				sprintf(ac_path_file_ini_oss,"/E/%s/G/%s", wrk_str, ac_wrk_str+strlen(ac_wrk_str)+2);
		}
		else
		{
			// Local file
			sprintf(ac_path_file_ini_oss,"/G/%s", g_ini_file+1);
		}

		while (wrk_str = strchr(ac_path_file_ini_oss,'.'))
			*wrk_str = '/';
	}
}

unsigned char *utf8_to_extended_ascii ( char *string,
										int *len )
{
	unsigned char  *ext_string = NULL;
	int 			mem = 1, i = 0;

	if ( !string || !len )
		return ext_string;

	if ( *len < 1 )
		*len = (int)strlen (string);

	ext_string = (unsigned char *) malloc (mem * sizeof (unsigned char));

	do
	{
		if ( ((unsigned char) string[i]) == 0xC2 || ((unsigned char) string[i]) == 0xC3 )
			continue;

		if ( ((unsigned char) string[i]) >= 0xA0 && i > 0x00 &&
			 ((unsigned char) string[i - 1]) == 0xC3 )
		{
			ext_string[mem - 1] = (unsigned char) string[i] + 0x40;
			ext_string = (unsigned char *) realloc (ext_string, ++mem * sizeof (unsigned char));

			continue;
		}

		ext_string[mem - 1] = (unsigned char) string[i];
		ext_string = (unsigned char *) realloc (ext_string, ++mem * sizeof (unsigned char));
	} while ( i++ < *len );

	ext_string[mem - 1] = 0x00;
	*len = mem;

	return ext_string;
}

P2_MTS_TAG_DEF getretAddr(void)
{
	return _ins_retAddr;
}

void setretAddr(P2_MTS_TAG_DEF ins_addr)
{
	_ins_retAddr = ins_addr;
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
            log_(LOG_DEBUG2, "%s: MTS_SEND: - T/S[%d-%d] successfully",
            		__FUNCTION__,
            		i_task_id,
					i_srv_class);
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

void SetThroughputStat( long long ts,
		                char *ac_postfix )
{
    long long i_diff = (long long)(JULIANTIMESTAMP(0) - ts);

    if( i_diff >= 0 )
    {
		if( i_diff <= 10000L ) // <= 10/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_10_MILL);
		else if( i_diff <= 25000L ) // <= 25/1000
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_25_MILL);
		else if( i_diff <= 50000L ) // <= 50/1000
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_50_MILL);
		else if( i_diff <= 75000L ) // <= 75/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_75_MILL);
		else if( i_diff <= 100000L ) // <= 100/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_100_MILL);
		else if( i_diff <= 250000 ) // <= 250/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_250_MILL);
		else if( i_diff <= 500000L ) // <= 500/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_500_MILL);
		else if( i_diff <= 750000L ) // <= 750/1000"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_750_MILL);
		else if( i_diff <= 1000000L) // <= 1"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_1_SEC);
		else if( i_diff <= 2000000 ) // <= 2"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_2_SEC);
		else if( i_diff <= 3000000L ) // <= 3"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_3_SEC);
		else if( i_diff > 3000000L ) // > 3"
			AddStat(STAT_TFS_LTE_PREFIX_REGS,ac_postfix,LTE_TFS_STATS_TIME_MAG_3_SEC);
    }
}

// ---------------------------------------------------------------------------------
