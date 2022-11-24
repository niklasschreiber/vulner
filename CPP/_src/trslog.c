/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trslog.c
*   Last Modified : 15/03/2016
*------------------------------------------------------------------------------
*   Description
*   -----------
*   Traffic Steering Logger
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   Reads IMSIdb and writes IMSI into log file if
*	- country code belongs to COUNTRY-LIST and
*	- last update in [FROM, TO]
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <tal.h>

#include <cextdecs.h>
#include <p2apdf.h>
#include "usrlib.h"

#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"

#include "ts.h"

/*---------------------< Definitions >---------------------------------------*/

/*---------------------< Parameters >----------------------------------------*/

//LOG
char				ac_path_log_file[30];
char				ac_log_prefix[10];
int					i_num_days_of_log;
int					i_trace_level;
int					i_log_options;
int					i_trace_step;

//EMS
short				s_ems_subsystem;
char				ac_ems_owner[16];
char				ac_ems_version[16];
char				ac_ems_appl[32];
char				ac_ems_text[168];

//GENERIC
char				ac_imsi_gsm_mbe_path[48];
char				ac_imsi_dat_mbe_path[48];
char				ac_imsi_lte_mbe_path[48];

//LOGGER
char				ac_country_list[200];
char				ac_from[20];
char				ac_to[20];

short   			s_imsi_prefix_len;
char    			ac_imsi_start_prefix[16];
char    			ac_imsi_end_prefix[16];

/*---------------------< Static and Global Variables >-----------------------*/
char				ac_my_process_name[10];
char				*pc_ini_file;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization();
short logImsiDatabase(char *type, char *imsi_mbe_path);
short mbeFileOpen(char *filename, short *fileid);
long long cgiTimestamp2Jts(char *ts);

int main(short argc, char * argv[]) 
{
	Process_Initialization();
	log(LOG_ERROR, "-- Process started");
	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

	logImsiDatabase("GSM", ac_imsi_gsm_mbe_path);
	logImsiDatabase("GPRS", ac_imsi_dat_mbe_path);
	logImsiDatabase("LTE", ac_imsi_lte_mbe_path);

	log(LOG_ERROR, "-- Process stopped");
	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STOPPED, "Process stopped");
	log_close();
	exit(0);
}

short logImsiDatabase(char *type, char *imsi_mbe_path)
{
	short			ret;
	short			err;
	short			s_imsi_db_id;
	short			s_imsi_db_size;
	char			ac_imsi[17];
	char			ac_country_code[11];

	int				count = 0;
	int				write_count = 0;
	long long		ll_timestamp_from;
	long long		ll_timestamp_to;

	t_ts_imsi_record	imsi_rec;

	// Open IMSIdb
	ret = mbeFileOpen(imsi_mbe_path, &s_imsi_db_id);

	// Browse IMSIdb GSM
	if (!ret)
	{
		count = write_count = 0;
		s_imsi_db_size = sizeof(imsi_rec);
		ac_country_code[0] = ',';

		if (ac_from[0])
			ll_timestamp_from = cgiTimestamp2Jts(ac_from);
		else
			ll_timestamp_from = 0;

		if (ac_to[0])
			ll_timestamp_to = cgiTimestamp2Jts(ac_to);
		else
			ll_timestamp_to = LLONG_MAX;

		if (!(err = MBE_FILE_SETKEY_(s_imsi_db_id, ac_imsi_start_prefix, s_imsi_prefix_len, 0, 0)))
		{
			// Loop
			while (!(err = MBE_READX(s_imsi_db_id, (char *)&imsi_rec, s_imsi_db_size)))
			{
				if (memcmp(imsi_rec.imsi, ac_imsi_end_prefix, s_imsi_prefix_len) <= 0)
				{
					count++;

					// Check timestamp
					if ((imsi_rec.last_ts_op >= ll_timestamp_from) &&
						(imsi_rec.last_ts_op <= ll_timestamp_to))
					{
						// Check country code
						memset(ac_country_code+1, 0x00, 10);
						memcpy(ac_country_code+1, imsi_rec.paese, 8);
						TrimString(ac_country_code);
						strcat(ac_country_code, ",");
						if (!ac_country_list[0] || strstr(ac_country_list, ac_country_code))
						{
							write_count++;
							memset(ac_imsi, 0x00, 17);
							memcpy(ac_imsi, imsi_rec.imsi, 16);
							TrimString(ac_imsi);
							StringReverse(ac_imsi);
							log(LOG_ERROR, "%s|%s", type, ac_imsi);
						}
					}
						
					// Trace
					if (count % i_trace_step == 0)
						log(LOG_INFO, "-- %s: %d read, %d written", type, count, write_count);
				}
				else break;

			}

			if (err && (err != 1))
			{
				log(LOG_ERROR, "-- error [%d] reading %s", err, imsi_mbe_path);
				ret++;
			}
		}
		else
		{
			log(LOG_ERROR, "-- error [%d] seeking %s", err, imsi_mbe_path);
			ret++;
		}

		if (!ret)
		{
			log(LOG_WARNING, "-- %s completed: %d read, %d written", type, count, write_count);
		}
		else
		{
			log(LOG_ERROR, "-- %s failed", type);
		}
	}

	MBE_FILE_CLOSE_(s_imsi_db_id);

	return(ret);
}

void Process_Initialization() 
{
	int		found;
	char	ac_wrk_str[1024];
	char	*pname, *pstart, *pend;			// Decoding of process name and range
	short	i_proch[20];
	short	i_maxlen = sizeof(ac_my_process_name);

	PROCESSHANDLE_GETMINE_(i_proch);
	PROCESSHANDLE_DECOMPOSE_(i_proch,,,,,,,ac_my_process_name,i_maxlen,&i_maxlen,);

	// Get configuration filename
	if ((pc_ini_file = getenv("INIFILE")) == NULL)
	{
		if ((pc_ini_file = getenv("INI-FILE")) == NULL)
		{
			DELAY(EXIT_DELAY);
			exit(0);
		}
	}

	/* --- EMS ------------------------------------------------------------- */
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
	get_profile_string(pc_ini_file, "LOGGER", "EMS-APPL", &found, ac_ems_appl);
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

	/* --- LOG ------------------------------------------------------------- */
	get_profile_string(pc_ini_file, "LOG", "LOG-PATH", &found, ac_path_log_file);
	if (found == SSP_FALSE)
	{
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOG -> LOG-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	i_num_days_of_log = 2;
	get_profile_string(pc_ini_file, "LOGGER", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);

	i_trace_level = LOG_INFO;
	get_profile_string(pc_ini_file, "LOGGER", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level = atoi(ac_wrk_str);
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "LOGGER", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	i_trace_step = 100000;
	get_profile_string(pc_ini_file, "LOGGER", "LOG-TRACE-STEP", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_step = atoi(ac_wrk_str); 

	/* --- GENERIC -------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GENERIC", "IMSI-GSM-MBE-PATH", &found, ac_imsi_gsm_mbe_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "IMSI-DAT-MBE-PATH", &found, ac_imsi_dat_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "IMSI-LTE-MBE-PATH", &found, ac_imsi_lte_mbe_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	/* --- LOGGER -------------------------------------------------------- */
	ac_country_list[0] = 0x00;
	ac_from[0] = 0x00;
	ac_to[0] = 0x00;

	get_profile_string(pc_ini_file, "LOGGER", "COUNTRY-LIST", &found, ac_wrk_str);
	if (found == SSP_TRUE && ac_wrk_str[0])
		sprintf(ac_country_list, ",%s,", ac_wrk_str);
	get_profile_string(pc_ini_file, "LOGGER", "FROM", &found, ac_from);
	get_profile_string(pc_ini_file, "LOGGER", "TO", &found, ac_to);

	get_profile_string(pc_ini_file, "LOGGER", "IMSI-PREFIX-RANGES", &found, ac_wrk_str);
	if (found == SSP_TRUE)
	{
		pname = strtok(ac_wrk_str, ":");
		while (pname)
		{
			pstart = strtok((char *)NULL, ":");
			pend = strtok((char *)NULL, "|");
			if (strcasecmp(ac_my_process_name, pname))
			{
				pname = strtok((char *)NULL, ":");
			}
			else
			{
				strcpy(ac_imsi_start_prefix, pstart);
				strcpy(ac_imsi_end_prefix, pend);
				s_imsi_prefix_len = strlen(ac_imsi_start_prefix);
				break;
			}
		}
		if (!(pname && pstart && pend))
		{
			log(LOG_ERROR, "Missing parameter LOGGER -> IMSI-PREFIX-RANGES | process name %s not found!", ac_my_process_name);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOGGER -> IMSI-PREFIX-RANGES | process name %s not found!", ac_my_process_name);
			DELAY (EXIT_DELAY);
			exit (0);
		}
	}
	else
	{
		log(LOG_ERROR, "Missing parameter LOGGER -> IMSI-PREFIX-RANGES");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter LOGGER -> IMSI-PREFIX-LEN");
		DELAY (EXIT_DELAY);
		exit (0);
	}

	// Print out parameters
	log(LOG_WARNING, "#==============================================================================");
	log(LOG_WARNING, "# INIFILE: %s", pc_ini_file);
	log(LOG_WARNING, "#==============================================================================");

	log(LOG_WARNING, "[EMS]");
	log(LOG_WARNING, "\tEMS-OWNER .................: %s", ac_ems_owner);
	log(LOG_WARNING, "\tEMS-SUBSYSTEM .............: %d", s_ems_subsystem);
	log(LOG_WARNING, "\tEMS-VERSION ...............: %s", ac_ems_version);
	log(LOG_WARNING, "\tEMS-APPL ..................: %s", ac_ems_appl);

	log(LOG_WARNING, "[LOG]");
	log(LOG_WARNING, "\tLOG-PATH ..................: %s", ac_path_log_file);
	log(LOG_WARNING, "\tLOG-DAYS ..................: %d", i_num_days_of_log);
	log(LOG_WARNING, "\tLOG-LEVEL .................: %d", i_trace_level);
	log(LOG_WARNING, "\tLOG-OPTIONS ...............: %d", i_log_options);
	log(LOG_WARNING, "\tLOG-TRACE-STEP ............: %d", i_trace_step);

	log(LOG_WARNING, "[GENERIC]");
	log(LOG_WARNING, "\tIMSI-GSM-MBE-PATH .........: %s", ac_imsi_gsm_mbe_path);
	log(LOG_WARNING, "\tIMSI-DAT-MBE-PATH .........: %s", ac_imsi_dat_mbe_path);
	log(LOG_WARNING, "\tIMSI-LTE-MBE-PATH .........: %s", ac_imsi_lte_mbe_path);

	log(LOG_WARNING, "[LOGGER]");
	log(LOG_WARNING, "\tCOUNTRY-LIST ..............: %s", ac_country_list);
	log(LOG_WARNING, "\tFROM ......................: %s", ac_from);
	log(LOG_WARNING, "\tTO ........................: %s", ac_to);
	log(LOG_WARNING, "\tIMSI-PREFIX-RANGES ........: %s:%s", ac_imsi_start_prefix, ac_imsi_end_prefix );
	log(LOG_WARNING, "#==============================================================================");
}

short mbeFileOpen(char *filename, short *fileid)
{
	short	ret = 0;
	short	err;

	if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
	{
		log(LOG_ERROR, "error %d opening file %s", err, filename);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error %d opening file %s", err, filename);
		ret++;
	}
	else
	{
		log(LOG_WARNING, "opened file %s - id %d", filename, *fileid);
	}

	return ret;
}
/*
short IsRecordInRange(char *imsi, char *start_prefix, char *end_prefix, short prefix_len)
{
    int		i_imsi_prefix;
	int		start, stop;
    char	imsi_prefix[16];

    memcpy(imsi_prefix, imsi, prefix_len);
    imsi_prefix[prefix_len] = 0;

	start = atoi(start_prefix);
	stop = atoi(end_prefix);

    i_imsi_prefix = atoi(imsi_prefix);
	
	if (((i_imsi_prefix) >= start)&& (i_imsi_prefix<stop))
	{
		return 1;
	}
	else
		return 0;
    
}
*/
long long cgiTimestamp2Jts(char *ts)
{
	short	dateNtime[8];

	// Expected format is "dd/mm/yyyy hh:mm:ss"
	if (strlen(ts) < strlen("dd/mm/yyyy hh:mm:ss"))
		return 0;

	dateNtime[0] = (short)(atoi(ts+6));
	dateNtime[1] = (short)atoi(ts+3);
	dateNtime[2] = (short)atoi(ts);
	dateNtime[3] = (short)atoi(ts+11);
	dateNtime[4] = (short)atoi(ts+14);
	dateNtime[5] = (short)atoi(ts+17);
	dateNtime[6] = 0;
	dateNtime[7] = 0;

	return CONVERTTIMESTAMP(COMPUTETIMESTAMP(dateNtime), 2);
}
/* commento inutilmente */
