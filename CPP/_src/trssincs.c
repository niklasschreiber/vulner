/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trssincs.c
*   Last Modified : 15/03/2016
*------------------------------------------------------------------------------
*   Descrizione
*   -----------
*	Traffic Steering Threshold Synchronization
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   Align local and remote threshold counters
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

/*---------------------< Include files >-------------------------------------*/

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <memory.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <tal.h>
#include <sys/stat.h>

#include <cextdecs.h>
#include <p2apdf.h>
#include "usrlib.h"

#include "mbedb.h"
#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"

#include "ts.h"

/*---------------------< Definitions >---------------------------------------*/


/*---------------------< Static and Global Variables >-----------------------*/
char	ac_my_process_name[10];
IO_RECEIVE  ReceiveIO;

/*---------------------< Parameters >----------------------------------------*/

char		*pc_ini_file;
char		ac_path_file_ini_oss[64];

//LOG
char		ac_path_log_file[30];
char		ac_log_prefix[10];
int			i_num_days_of_log;
int			i_trace_level;
int			i_log_options;
int			i_trace_step;

//EMS
short		s_ems_subsystem;
char		ac_ems_owner[16];
char		ac_ems_version[16];
char		ac_ems_appl[32];
char		ac_ems_text[168];
long long	ll_ems_time_interval;

char		ac_soglie_mbe_path[48];
char		ac_soglie_mbe_path_remote[48];

short		s_local_id = 0;
short		s_remote_id = 0;

char		c_local_closed = 1;
char		c_remote_closed = 1;

int			i_align_interval;
int			i_load_params_interval;
int			i_mbe_timeout;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization(char reload);
void Print_Process_Parameters();
short checkIniFile();

void Open_Input_Queue(IO_RECEIVE *ReceiveIO);
short Read_Input_Queue(IO_RECEIVE *ReceiveIO);

short mbeFileOpen(char *filename, short *fileid);
void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...);
void AlignSoglie(void);

int main(short argc, char * argv[]) 
{
    short		Stop = 0;
	short		file_id;
	long		l_awaitio_timeout = -1;
	long		i_tag;
	short		rc;
	short		receive_cnt;
	int			i;

	IO_SYSMSG_TIMEOUT	signal;
	short		sender_info[17];
    short		sender_handle[10];
    char		sender_process_name[16];
    short		sender_process_maxlen = sizeof(sender_process_name);

    short		sender_mom_handle[10];
    char		sender_mom_process_name[16];
    short		sender_mom_process_maxlen = sizeof(sender_mom_process_name);

	Process_Initialization(0);

	// SOGLIE
	if (!Stop)
	{
		c_local_closed = mbeFileOpen(ac_soglie_mbe_path, &s_local_id);
		c_remote_closed = mbeFileOpen(ac_soglie_mbe_path_remote, &s_remote_id);
	}

	log(LOG_ERROR, "Process started");

	if (!Stop)
	{
		// Open $RECEIVE
		Open_Input_Queue(&ReceiveIO);
		Read_Input_Queue(&ReceiveIO);

		SIGNALTIMEOUT(i_align_interval, 0, TAG_ALIGN_SOGLIE);
		if (i_load_params_interval > 0)
			SIGNALTIMEOUT(i_load_params_interval, 0, TAG_RELOAD_PARAM);

		while (!Stop) 
		{
			file_id = -1;
			AWAITIOX(&file_id, , &receive_cnt, &i_tag, l_awaitio_timeout);
			FILE_GETINFO_(file_id, &rc);
			log(LOG_DEBUG, "Rcv: rc = %d, cnt = %d", rc, receive_cnt);

			REPLYX();
			if (rc == 6)
			{
				memcpy(&signal, &ReceiveIO.data, sizeof(IO_SYSMSG_TIMEOUT));
				log(LOG_DEBUG, "rcv system signal %d", signal.id);

				switch(signal.id)
				{
					case SYS_MSG_TIME_TIMEOUT:
					{
						switch (signal.l_par) 
						{
							case TAG_RELOAD_PARAM: 
							{
								if (checkIniFile())
								{
									Process_Initialization(1);
								}
								else
								{
									log(LOG_WARNING, "Parameters - reload skipped");
								}

								SIGNALTIMEOUT(i_load_params_interval, 0, TAG_RELOAD_PARAM);
								break;
							}
							case TAG_ALIGN_SOGLIE:
							{
								AlignSoglie();
								SIGNALTIMEOUT(i_align_interval, 0, TAG_ALIGN_SOGLIE);
								break;
							}
							default:
							{
								break;
							}
						}
						break;
					}
					// Pathway Stop ?
					case SYS_MSG_STOP:
					case SYS_MSG_STOP_2:
					{
						// Get sender info
						FILE_GETRECEIVEINFO_(sender_info);
						for (i=0; i<10; i++) sender_handle[i] = sender_info[i+6];
						memset(sender_process_name, 0, sizeof(sender_process_name));
						PROCESSHANDLE_TO_STRING_(sender_handle, sender_process_name, sender_process_maxlen, &sender_process_maxlen);

						// Get sender ancestor info
						PROCESS_GETINFO_(sender_handle,,,,, sender_mom_handle);
						memset(sender_mom_process_name, 0, sizeof(sender_mom_process_name));
						PROCESSHANDLE_TO_STRING_(sender_mom_handle, sender_mom_process_name, sender_mom_process_maxlen, &sender_mom_process_maxlen);

						log(LOG_DEBUG, "sender %s, mom %s", sender_process_name, sender_mom_process_name);

						if (!strcmp(sender_process_name, sender_mom_process_name))
						{
							log(LOG_INFO, "System STOP message!!!");
							Stop = 1;
						}
						break;
					}
					default:
					{
						break;
					}
				}
			}

			if (file_id == 0)
				Read_Input_Queue(&ReceiveIO);
		}

	}

	MBE_FILE_CLOSE_(s_local_id);
	MBE_FILE_CLOSE_(s_remote_id);

	log(LOG_ERROR, "Process stopped");
	log_close();
	exit(0);	
}

// ----------------------------------------------------------------------------
void AlignSoglie(void)
{
	short err;
	short count = 0;
	char  ac_keynosync[TS_STRULES_KEYLEN];
	t_ts_soglie_record	soglie_local_rec;
	t_ts_soglie_record	soglie_remote_rec;

	if (c_local_closed)
	{
		c_local_closed = mbeFileOpen(ac_soglie_mbe_path, &s_local_id);
	}
	if (c_remote_closed)
	{
		c_remote_closed = mbeFileOpen(ac_soglie_mbe_path_remote, &s_remote_id);
	}

	memset( ac_keynosync, '*', TS_STRULES_KEYLEN );

	if (!(err = MBE_FILE_SETKEY_(s_local_id, "", 0, 0, 0)))
	{
		//while (!(err = MBE_READLOCKX(s_local_id, (char *)&soglie_local_rec, sizeof(soglie_local_rec))))
		while (!(err = MbeFileReadL_nw(s_local_id, (char *)&soglie_local_rec, sizeof(soglie_local_rec))))
		{
			if ( !err && !memcmp( (char *)&soglie_local_rec, ac_keynosync, TS_STRULES_KEYLEN ) )
			{
				//MBE_UNLOCKREC(s_local_id);
				MbeUnlockRec_nw(s_local_id);
				continue;
			}

			if (!(err = MBE_FILE_SETKEY_(s_remote_id, (char *)&soglie_local_rec, TS_STRULES_KEYLEN, 0, 2)))
			{
				//err = MBE_READLOCKX(s_remote_id, (char *)&soglie_remote_rec, sizeof(soglie_remote_rec));
				err = MbeFileReadL_nw(s_remote_id, (char *)&soglie_remote_rec, sizeof(soglie_remote_rec));

				if ( !err )
				{
					// Composizione records -------------------------------
					soglie_local_rec.tot_accP[1]	= soglie_remote_rec.tot_accP[0];
					soglie_local_rec.tot_accT[1]	= soglie_remote_rec.tot_accT[0];
					soglie_remote_rec.tot_accP[1]	= soglie_local_rec.tot_accP[0];
					soglie_remote_rec.tot_accT[1]	= soglie_local_rec.tot_accT[0];
					// ----------------------------------------------------

					//err = MBE_WRITEUPDATEUNLOCKX(s_remote_id, (char *)&soglie_remote_rec, sizeof(soglie_remote_rec));
					err = MbeFileWriteUU_nw(s_remote_id, (char *)&soglie_remote_rec, sizeof(soglie_remote_rec));
					if (err)
					{
						log(LOG_ERROR, "error [%d] updating %s", err, ac_soglie_mbe_path_remote);
						log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating %s", err, ac_soglie_mbe_path_remote);
						//MBE_UNLOCKREC(s_remote_id);
						MbeUnlockRec_nw(s_remote_id);
						c_remote_closed = 1;
					}
					else
					{
						log(LOG_INFO, "Upd remote [%.60s] %ld-%ld-%ld-%ld",
							(char *)&soglie_remote_rec,
							soglie_remote_rec.tot_accP[0],
							soglie_remote_rec.tot_accT[0],
							soglie_remote_rec.tot_accP[1],
							soglie_remote_rec.tot_accT[1] );
					}
				}
				else
				{
					log(LOG_ERROR, "error [%d] reading %s", err, ac_soglie_mbe_path_remote);
					log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_soglie_mbe_path_remote);
					c_remote_closed = 1;
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", err, ac_soglie_mbe_path_remote);
				log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_soglie_mbe_path_remote);
				c_remote_closed = 1;
			}

			if (!err)
			{
				//err = MBE_WRITEUPDATEUNLOCKX(s_local_id, (char *)&soglie_local_rec, sizeof(soglie_local_rec));
				err = MbeFileWriteUU_nw(s_local_id, (char *)&soglie_local_rec, sizeof(soglie_local_rec));
				if (err)
				{
					log(LOG_ERROR, "error [%d] updating %s", err, ac_soglie_mbe_path);
					//MBE_UNLOCKREC(s_local_id);
					MbeUnlockRec_nw(s_local_id);
					c_local_closed = 1;
				}
				else
				{
					log(LOG_INFO, "Upd local  [%.60s] %ld-%ld-%ld-%ld",
						(char *)&soglie_remote_rec,
						soglie_local_rec.tot_accP[0],
						soglie_local_rec.tot_accT[0],
						soglie_local_rec.tot_accP[1],
						soglie_local_rec.tot_accT[1] );

					count++;
				}
			}
			else
			{
				//MBE_UNLOCKREC(s_local_id);
				MbeUnlockRec_nw(s_local_id);
			}
		}

		if (err == 1)
		{
			log(LOG_WARNING, "Threshold counter alignment completed (%d records).", count);
		}
		else
		{
			c_local_closed = 1;
			log(LOG_ERROR, "Threshold counter alignment failed.");
		}
	}
	else
	{
		log(LOG_ERROR, "error [%d] seeking %s", err, ac_soglie_mbe_path);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_soglie_mbe_path);
		c_local_closed = 1;
	}
}

void Process_Initialization(char reload)
{
	int   	found;
	char  	ac_wrk_str[1024];
	char	*wrk_str;
	short 	i_proch[20];
	short 	i_maxlen = sizeof(ac_my_process_name);

	PROCESSHANDLE_GETMINE_(i_proch);
	PROCESSHANDLE_DECOMPOSE_(i_proch,,,,,,,ac_my_process_name,i_maxlen,&i_maxlen,);

	if (!reload)
	{
		// Get configuration filename
		if ((pc_ini_file = getenv("INIFILE")) == NULL)
		{
			if ((pc_ini_file = getenv("INI-FILE")) == NULL)
			{
				DELAY(EXIT_DELAY);
				exit(0);
			}
		}

		// Compose OSS filename for reload check
		if (*pc_ini_file == '\\')
		{
			// Remote file
			strcpy(ac_wrk_str, pc_ini_file+1);
			wrk_str = strtok(ac_wrk_str, ".");
			sprintf(ac_path_file_ini_oss, "/E/%s/G/%s", wrk_str, ac_wrk_str+strlen(ac_wrk_str)+2);
		}
		else
		{
			// Local file
			sprintf(ac_path_file_ini_oss, "/G/%s", pc_ini_file+1);
		}
		while (wrk_str = strchr(ac_path_file_ini_oss, '.')) *wrk_str = '/';

		checkIniFile();
	}

	/* --- EMS ------------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "EMS", "EMS-OWNER", &found, ac_ems_owner);
		if (found == SSP_FALSE) 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "EMS", "EMS-VERSION", &found, ac_ems_version);
		if (found == SSP_FALSE) 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "EMS", "EMS-SUBSYSTEM", &found, ac_wrk_str);
		if (found == SSP_TRUE) s_ems_subsystem = (short)atoi(ac_wrk_str);
		else 
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "ALIGN", "EMS-APPL", &found, ac_ems_appl);
		if (found == SSP_FALSE) 
		{
			get_profile_string(pc_ini_file, "EMS", "EMS-APPL", &found, ac_ems_appl);
			if (found == SSP_FALSE)
			{
				DELAY(EXIT_DELAY);
				exit(0);
			}
		}

		// Init EMS
		sspevt_init(ac_ems_appl, ac_ems_owner, s_ems_subsystem, ac_ems_version);
	}

	/* --- LOG ------------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-PATH", &found, ac_path_log_file);
		if (found == SSP_FALSE)
		{
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOG -> LOG-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		i_num_days_of_log = 8;
		get_profile_string(pc_ini_file, "ALIGN", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
		else
		{
			get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
			if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
		}

		// OPEN LOG FILE
		log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);
	}

	i_trace_level = LOG_INFO;
	if (get_profile_string(pc_ini_file, "ALIGN", "LOG-LEVEL", &found, ac_wrk_str))
	{
		if (reload)
			log(LOG_INFO, "Parameters - failed to open %s - reload aborted", pc_ini_file);
		else
			log(LOG_INFO, "Parameters - failed to open %s", pc_ini_file);

		return;
	}
	else
	{
		if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
		else
		{
			get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
			if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
		}
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "ALIGN", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	get_profile_string(pc_ini_file, "EMS", "EMS-TIME-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_ems_time_interval = (long long)atoi(ac_wrk_str) * 1000000;
	else ll_ems_time_interval = 60000000;

	/* --- GENERIC --------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, ac_soglie_mbe_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}

		get_profile_string(pc_ini_file, "GENERIC", "DB-REM-THRESHOLDS-PATH", &found, ac_soglie_mbe_path_remote);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> DB-REM-THRESHOLDS-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-REM-THRESHOLDS-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
	}

	i_mbe_timeout = 200;
	get_profile_string(pc_ini_file, "GENERIC", "MBE-NOWAIT-TIMEOUT", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		i_mbe_timeout = (int)(atoi(ac_wrk_str) * 100);
		MbeSetAwiatioxTimeout(i_mbe_timeout);
	}

	/* --- ALIGN ------------------------------------------------------------ */
	i_align_interval = 30000;
	get_profile_string(pc_ini_file, "ALIGN", "ALIGN-THRESHOLDS-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) 
		i_align_interval = (short)(atoi(ac_wrk_str) * 100);

	i_load_params_interval = 30000;
	get_profile_string(pc_ini_file, "ALIGN", "LOAD-PARAMS-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_load_params_interval = (int)(atoi(ac_wrk_str) * 100);

	if (!reload)
	{
		Print_Process_Parameters();
	}
	else
	{
		log(LOG_WARNING, "Parameters reloaded");
	}
}

void Print_Process_Parameters()
{
	log(LOG_WARNING, "#==============================================================================");
	log(LOG_WARNING, "# INIFILE: %s", ac_path_file_ini_oss);
	log(LOG_WARNING, "#==============================================================================");

	log(LOG_WARNING, "[EMS]");
	log(LOG_WARNING, "\tEMS-OWNER .................: %s", ac_ems_owner);
	log(LOG_WARNING, "\tEMS-SUBSYSTEM .............: %d", s_ems_subsystem);
	log(LOG_WARNING, "\tEMS-VERSION ...............: %s", ac_ems_version);
	log(LOG_WARNING, "\tEMS-APPL ..................: %s", ac_ems_appl);
	log(LOG_WARNING, "\tEMS-TIME-INTERVAL .........: %Ld", ll_ems_time_interval/1000000);

    log(LOG_WARNING, "[LOG]");
    log(LOG_WARNING, "\tLOG-PATH ..................: %s", ac_path_log_file);
    log(LOG_WARNING, "\tLOG-DAYS ..................: %d", i_num_days_of_log);
    log(LOG_WARNING, "\tLOG-LEVEL .................: %d", i_trace_level);
    log(LOG_WARNING, "\tLOG-OPTIONS ...............: %d", i_log_options);

    log(LOG_WARNING, "[GENERIC]");
	log(LOG_WARNING, "\tDB-LOC-THRESHOLDS-PATH ....: %s", ac_soglie_mbe_path);
	log(LOG_WARNING, "\tDB-REM-THRESHOLDS-PATH ....: %s", ac_soglie_mbe_path_remote);
	//log(LOG_WARNING, "\tMBE-NOWAIT-TIMEOUT ........: %d", i_mbe_timeout/100);

	log(LOG_WARNING, "[ALIGN]");
	log(LOG_WARNING, "\tALIGN-THRESHOLDS-INTERVAL .: %d", i_align_interval/100);
	log(LOG_WARNING, "\tLOAD-PARAMS-INTERVAL ......: %d", i_load_params_interval/100);
	log(LOG_WARNING, "#==============================================================================");
}

short checkIniFile()
{
	short			ret = 0;
	struct stat		stat_file;
	static time_t	time_lastup = 0;

	lstat(ac_path_file_ini_oss, &stat_file);
	if (time_lastup != stat_file.st_mtime)
	{
		time_lastup = stat_file.st_mtime;
		ret = 1;
	}
	return ret;
}

short mbeFileOpen(char *filename, short *fileid)
{
	static long long	ll_ems_time_last_open_jts = 0;
	short				ret = 0;
	short				err;

	if (*fileid)
		MBE_FILE_CLOSE_(*fileid);

	//if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
	if (err = MbeFileOpen_nw(filename, fileid))
	{
		log(LOG_ERROR, "error [%d] opening %s", err, filename);
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_open_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] opening %s", err, filename);
		ret++;
	}
	else
	{
		log(LOG_WARNING, "opened %s - id %d", filename, *fileid);
	}

	return ret;
}

void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...)
{
	va_list ap;
	char out[256];
	long long ll_current_ts = JULIANTIMESTAMP();

    if (ll_current_ts - *ll_ems_last_evt > ll_ems_interval)
    {
    	*ll_ems_last_evt = ll_current_ts;
        va_start(ap, msg);
        vsprintf(out, msg, ap);
        log_evt(i_critical, i_action, i_event_num, "%s", out);
        va_end(ap);
    }
}

void Open_Input_Queue(IO_RECEIVE *ReceiveIO) 
{
  short error;
  strcpy(ReceiveIO->fname, "$RECEIVE");
  error = FILE_OPEN_(ReceiveIO->fname, (short)strlen(ReceiveIO->fname), &ReceiveIO->id, 0, 0, 1, 1);
  if (error != 0)
  {
    //LAUNCH_ER(P2_ERA_APPL, ERAD_FILEIO_ERROR, A_STRING, ReceiveIO->fname, A_16BITS, &error, END_OF_ARGLIST);
    DELAY(EXIT_DELAY);
    exit(0);
  }
  return;
}

short Read_Input_Queue(IO_RECEIVE *ReceiveIO)
{
  short	cnt_read = 0;
  memset(ReceiveIO->data, ' ', sizeof(ReceiveIO->data));
  
  READUPDATEX(ReceiveIO->id, (ReceiveIO->data), (short)sizeof(ReceiveIO->data), &cnt_read);
  FILE_GETINFO_(ReceiveIO->id, &ReceiveIO->error);
  if (ReceiveIO->error > 0)
  {
    //LAUNCH_ER(P2_ERA_APPL, ERAD_FILEIO_ERROR, A_STRING, ReceiveIO->fname, A_16BITS, &ReceiveIO->error, END_OF_ARGLIST);
    DELAY(EXIT_DELAY);
    exit(0);
  }
  return(cnt_read);
}
