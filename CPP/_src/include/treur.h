// ----------------------------------------------------------------------------
//  PROJECT :
// ----------------------------------------------------------------------------
//
//  File Name   : treur.h
//  Last Change : 30/09/2014
//
// -----------------------------------------------------------------------------
//  Description
//
//
// -----------------------------------------------------------------------------
//  Functions
//  ------------------
// -----------------------------------------------------------------------------
//  Cosa manca
//  ------------------
//
//  tracing
//
//
// -----------------------------------------------------------------------------
#ifndef __P_TREUR_H
#define __P_TREUR_H

#include <tags.h>

enum{
	STAT_Record_Reply = STAT_Last,
	STAT_Record_IsProcessing,
	STAT_Record_IsWaiting,
};

#define EMS_T_ERR_OPEN_DB		"%s:Error [%d] opening [%s]"						// errnum, pathname
#define EMS_T_ERR_SEEK_DB		"%s:Error [%d] seeking [%s]"						// errnum, pathname
#define EMS_T_ERR_READ_DB		"%s:Error [%d] reading [%s]"						// errnum, pathname
#define EMS_T_ERR_WRITE_DB		"%s:Error [%d] writing [%s]"						// errnum, pathname

#define QUEUE_EOF			5

#define stat_process_SCWS		"SCWS-ARG"
#define stat_registry_QUE		"ROAMEQ"
#define stat_registry_HTTP_200	"HTTP_200_OK"

#define LEN_MS			16

#define VToCh			(*func)

#endif

/*---------------------< Variables >-----------------------------------------*/
int			i_reload_interval;
short		i_evt_number_start;
short		i_start_num_stat;

int			i_readque_timeout;
short		i_readque_next_rec_timeout;

db_struct	roameuq;
db_struct 	*dbnames[]={&roameuq,0};

char		ac_range[10];
short		i_retry_delay;
char		ac_global_pathmon_name[50];
char		ac_global_serverclass_name[50];
char		ac_callback_url[200];
short		i_delay_retry;
short		i_retry_max;
char		kbytes_len_buf;
/*---------------------------------------------------------------------------*/
