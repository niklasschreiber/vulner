/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsclean.c
*   Last Modified : 15/03/2016
*------------------------------------------------------------------------------
*   Description
*   -----------
*   Traffic Steering Cleaner
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*	Count or remove records from IMSIdb if timestamp is older than...
*	Eventually writes the removed records into backup file
*
*	12/01/2017 - Removed separate LTE management (merged with GPRS into DAT database)
*
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
//char				ac_imsi_lte_mbe_path[48];

//CLEANER
char				ac_write_gsm_matching_path[48];
char				ac_write_dat_matching_path[48];
//char				ac_write_lte_matching_path[48];
short				s_delete_matching_record;
short				s_write_matching_record;
long long			ll_last_update_interval;

short   			s_imsi_prefix_len;
char    			ac_imsi_start_prefix[16];
char    			ac_imsi_end_prefix[16];

/*---------------------< Static and Global Variables >-----------------------*/
char				ac_my_process_name[10];
char				*pc_ini_file;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization();
short cleanImsiDatabase(char *type, char *imsi_mbe_path, char *imsi_bak_path);
short mbeFileOpen(char *filename, short *fileid);

int main(short argc, char * argv[]) 
{
	Process_Initialization();
	log(LOG_ERROR, "Process started");
	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

	cleanImsiDatabase("GSM", ac_imsi_gsm_mbe_path, ac_write_gsm_matching_path);
	cleanImsiDatabase("DAT", ac_imsi_dat_mbe_path, ac_write_dat_matching_path);
	//cleanImsiDatabase("LTE", ac_imsi_lte_mbe_path, ac_write_lte_matching_path);

	log(LOG_ERROR, "Process stopped");
	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STOPPED, "Process stopped");
	log_close();
	exit(0);
}

short cleanImsiDatabase(char *type, char *imsi_mbe_path, char *imsi_bak_path)
{
	short			ret = 0;			// Return code
	short			err;				// MBE function return code
	short			s_imsi_db_id;
	short			s_write_matching_id;
	short			s_imsi_db_size;
	int				count;
	int				del_count;
	int				deleted_count;
	int				write_count;
	long long		ll_valid_time;

	t_ts_imsi_record	imsi_rec;

	// Open IMSIdb
	ret = mbeFileOpen(imsi_mbe_path, &s_imsi_db_id);

	// Open Write-file
	if (!ret && s_write_matching_record)
	{
		ret = mbeFileOpen(imsi_bak_path, &s_write_matching_id);
	}

	// Browse IMSIdb
	if (!ret)
	{
		count = del_count = deleted_count = write_count = 0;
		s_imsi_db_size = sizeof(imsi_rec);

		if (!(err = MBE_FILE_SETKEY_(s_imsi_db_id, ac_imsi_start_prefix, s_imsi_prefix_len, 0, 0)))
		{
			ll_valid_time = JULIANTIMESTAMP() - ll_last_update_interval;

			// Loop
			while (!(err = MBE_READX(s_imsi_db_id, (char *)&imsi_rec, s_imsi_db_size)))
			{
				if (memcmp(imsi_rec.imsi, ac_imsi_end_prefix, s_imsi_prefix_len) <= 0)
				{
					count++;

					// Check last update timestamp
					if (imsi_rec.last_ts_op < ll_valid_time)
					{
						// Check if user not in white list
						if ((imsi_rec.status != IMSI_STATUS_GRANT_ALWAYS) &&
							(imsi_rec.status != IMSI_STATUS_STEER_ALWAYS))
						{
							del_count++;

							if (s_write_matching_record)
							{
								if (!(ret = MBE_WRITEX(s_write_matching_id, (char *)&imsi_rec, s_imsi_db_size)))
								{
									write_count++;
								}
								else
								{
									log(LOG_ERROR, "error [%d] writing %s", ret, imsi_bak_path);
								}
							}

							if (s_delete_matching_record)
							{
								if (!(err = MBE_WRITEUPDATEX(s_imsi_db_id, (char *)&imsi_rec, 0)))
								{
									deleted_count++;
								}
								else
								{
									log(LOG_ERROR, "error [%d] deleting %s", err, imsi_mbe_path);
								}
							}
						}
					}
						
					// Trace
					if (count % i_trace_step == 0)
						log(LOG_INFO, "-- %s: %d read, %d removable, %d removed, %d written", type, count, del_count, deleted_count, write_count);
				}
				else break;

			}

			if (err && (err != 1))
			{
				log(LOG_ERROR, "error [%d] reading %s", err, imsi_mbe_path);
				ret++;
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, imsi_mbe_path);
			ret++;
		}

		if (!ret)
		{
			log(LOG_WARNING, "Removing IMSI %s records completed (%d read, %d removable, %d removed, %d written).", type, count, del_count, deleted_count, write_count);
		}
		else
		{
			log(LOG_ERROR, "Removing IMSI %s records failed.", type);
		}
	}

	MBE_FILE_CLOSE_(s_imsi_db_id);
	MBE_FILE_CLOSE_(s_write_matching_id);

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
	get_profile_string(pc_ini_file, "CLEANER", "EMS-APPL", &found, ac_ems_appl);
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

	i_num_days_of_log = 8;
	get_profile_string(pc_ini_file, "CLEANER", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);

	i_trace_level = LOG_INFO;
	get_profile_string(pc_ini_file, "CLEANER", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level = atoi(ac_wrk_str);
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "CLEANER", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	i_trace_step = 100000;
	get_profile_string(pc_ini_file, "CLEANER", "LOG-TRACE-STEP", &found, ac_wrk_str);
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
/*
	get_profile_string(pc_ini_file, "GENERIC", "IMSI-LTE-MBE-PATH", &found, ac_imsi_lte_mbe_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
*/
	/* --- CLEANER -------------------------------------------------------- */
	s_delete_matching_record = 0;
	get_profile_string(pc_ini_file, "CLEANER", "DELETE-MATCHING-RECORD", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_delete_matching_record = (short)atoi(ac_wrk_str);

	get_profile_string(pc_ini_file, "CLEANER", "LAST-UPDATE-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_last_update_interval = (long long)atoi(ac_wrk_str) * 1000000;
	if (found == SSP_FALSE || ll_last_update_interval == 0)
	{
		log(LOG_ERROR, "Missing parameter CLEANER -> LAST-UPDATE-INTERVAL");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> LAST-UPDATE-INTERVAL");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	s_write_matching_record = 0;
	get_profile_string(pc_ini_file, "CLEANER", "WRITE-MATCHING-RECORD", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_write_matching_record = (short)atoi(ac_wrk_str);
	if (s_write_matching_record)
	{
		get_profile_string(pc_ini_file, "CLEANER", "WRITE-GSM-MATCHING-PATH", &found, ac_write_gsm_matching_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter CLEANER -> WRITE-GSM-MATCHING-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> WRITE-GSM-MATCHING-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "CLEANER", "WRITE-DAT-MATCHING-PATH", &found, ac_write_dat_matching_path);
		if (found == SSP_FALSE) 
		{
			log(LOG_ERROR, "Missing parameter CLEANER -> WRITE-DAT-MATCHING-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> WRITE-DAT-MATCHING-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
/*
		get_profile_string(pc_ini_file, "CLEANER", "WRITE-LTE-MATCHING-PATH", &found, ac_write_lte_matching_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter CLEANER -> WRITE-LTE-MATCHING-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> WRITE-LTE-MATCHING-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
*/
	}
	else
	{
		ac_write_gsm_matching_path[0] = 0x00;
		ac_write_dat_matching_path[0] = 0x00;
		//ac_write_lte_matching_path[0] = 0x00;
	}

	get_profile_string(pc_ini_file, "CLEANER", "IMSI-PREFIX-RANGES", &found, ac_wrk_str);
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
			log(LOG_ERROR, "Missing parameter CLEANER -> IMSI-PREFIX-RANGES | process name %s not found!", ac_my_process_name);
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> IMSI-PREFIX-RANGES | process name %s not found!", ac_my_process_name);
			DELAY (EXIT_DELAY);
			exit (0);
		}
	}
	else
	{
		log(LOG_ERROR, "Missing parameter CLEANER -> IMSI-PREFIX-RANGES");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter CLEANER -> IMSI-PREFIX-LEN");
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
	//log(LOG_WARNING, "\tIMSI-LTE-MBE-PATH .........: %s", ac_imsi_lte_mbe_path);

	log(LOG_WARNING, "[CLEANER]");
	log(LOG_WARNING, "\tDELETE-MATCHING-RECORD ....: %d", s_delete_matching_record);
	log(LOG_WARNING, "\tWRITE-MATCHING-RECORD .....: %d", s_write_matching_record);
	log(LOG_WARNING, "\tWRITE-GSM-MATCHING-PATH ...: %s", ac_write_gsm_matching_path);
	log(LOG_WARNING, "\tWRITE-DAT-MATCHING-PATH ...: %s", ac_write_dat_matching_path);
	//log(LOG_WARNING, "\tWRITE-LTE-MATCHING-PATH ...: %s", ac_write_lte_matching_path);
	log(LOG_WARNING, "\tLAST-UPDATE-INTERVAL ......: %Ld", ll_last_update_interval/1000000);
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
