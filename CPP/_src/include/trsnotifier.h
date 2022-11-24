// ----------------------------------------------------------------------------
//  PROJECT :
// ----------------------------------------------------------------------------
//
//  File Name   : trsnotifier.h
//  Last Change : 01/03/2019
//
// -----------------------------------------------------------------------------
//  Description
//
// -----------------------------------------------------------------------------
#ifndef __P_TRNOTIF_H
#define __P_TRNOTIF_H

#include <tags.h>

enum{
	STAT_Record_Reply = STAT_Last,
	STAT_Record_IsProcessing,
	STAT_Record_IsWaiting,

	QUEUE_EOF			=5,
	LEN_MS				=16,

	TAG_RELOAD_COUNRTY  =LAST_TAG
};

#define EMS_T_ERR_OPEN_DB		"%s:Error [%d] opening [%s]"		// errnum, pathname
#define EMS_T_ERR_SEEK_DB		"%s:Error [%d] seeking [%s]"		// errnum, pathname
#define EMS_T_ERR_READ_DB		"%s:Error [%d] reading [%s]"		// errnum, pathname
#define EMS_T_ERR_WRITE_DB		"%s:Error [%d] writing [%s]"		// errnum, pathname

#define stat_registry_QUE		"CCCQUE"
#define stat_registry_HTTP_202	"HTTP_202_OK"

#endif

/*---------------------< Variables >-----------------------------------------*/
int			i_reload_interval;
short		i_evt_number_start;
short		i_start_num_stat;

int			i_readque_timeout;
short		i_readque_next_rec_timeout;
int			i_reload_country_db_timeout;

db_struct	cccque;
db_struct	cccque2;
db_struct	country;
db_struct 	*dbnames[]={&cccque,&cccque2,0};

char		ac_range[10];
short		i_retry_delay;
char		ac_global_pathmon_name[50];
char		ac_global_serverclass_name[50];
short		i_delay_retry;
short		i_retry_max;
short		kbytes_len_buf;
char		ac_url_push_notification[100];
char		ac_path_oss_country[50];
/*---------------------------------------------------------------------------*/
