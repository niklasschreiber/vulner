/*----------------------------------------------------------------------------
*   PROJECT       : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsplmn.c
*   Last Modified : 09/05/2014
*------------------------------------------------------------------------------
   Description
*   -----------
*	Traffic Steering PLMN Update
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*	Update PLMN on InteracTIM TFS Plugin
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

/*---------------------< Include files >-------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <tal.h>
#include <time.h>

#include <cextdecs.h>
#include <p2apdf.h>
#include "usrlib.h"

#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"

#include "ts.h"

/*---------------------< Definitions >---------------------------------------*/

#pragma fieldalign shared2 s_interac_tfs_plmn
typedef struct s_interac_tfs_plmn
{
	// Len 60
	// Prim.key: cc + den_op8 (len 16)

	char		cc[8];
	char		den_op8[8];
	long long	lastUpdateJts;
	short		pplmn;
	short		fplmn;
	char		filler[32];

} t_interac_tfs_plmn;

/*---------------------< Parameters >----------------------------------------*/

//EMS
short				s_ems_subsystem;
char				ac_ems_owner[16];
char				ac_ems_version[16];
char				ac_ems_appl[32];
char				ac_ems_text[168];

//LOG
char				ac_path_log_file[30];
int					i_num_days_of_log;
int					i_trace_level;
int					i_log_options;

//GENERIC
char				ac_ccplmn_path[48];
char				ac_paesi_path[48];
char				ac_soglie_path[48];

/*---------------------< Static and Global Variables >-----------------------*/

char				ac_my_process_name[10];
char				*pc_ini_file;

short				s_ccplmn_fileid;
short				s_paesi_fileid;
short				s_soglie_fileid;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization();
void Print_Process_Parameters();
void updatePLMN();
short mbeFileOpen(char *filename, short *fileid);
short isRuleValid(t_ts_soglie_record soglia);

/*---------------------------------------------------------------------------*/

int main (short argc, char * argv[])
{
	short	Stop = 0;

	// Initialize parameters
	Process_Initialization();

	// Open MBE/Enscribe
	Stop = mbeFileOpen(ac_ccplmn_path, &s_ccplmn_fileid);
	if (!Stop) Stop = mbeFileOpen(ac_paesi_path, &s_paesi_fileid);
	if (!Stop) Stop = mbeFileOpen(ac_soglie_path, &s_soglie_fileid);

	if (!Stop)
	{
		log(LOG_ERROR, "Process started");
		//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

		updatePLMN();

		log(LOG_ERROR, "Process stopped");
		log_close();
		//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STOPPED, "Process stopped");
	}

	exit(0);
}

void Process_Initialization()
{
	int		found;
	char	ac_wrk_str[1024];
	//char	*wrk_str;
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
	get_profile_string(pc_ini_file, "UPDATE-PLMN", "EMS-APPL", &found, ac_ems_appl);
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

	/* --- SIM-STAT ------------------------------------------------------------- */
	i_num_days_of_log = 2;
	get_profile_string(pc_ini_file, "UPDATE-PLMN", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);

	i_trace_level = LOG_INFO;
	get_profile_string(pc_ini_file, "UPDATE-PLMN", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level = atoi(ac_wrk_str);
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "UPDATE-PLMN", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	/* --- GENERIC --------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GENERIC", "DB-TFS-CCPLMN-PATH", &found, ac_ccplmn_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-TFS-CCPLMN-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> DB-TFS-CCPLMN-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "PAESI-MBE-PATH", &found, ac_paesi_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> PAESI-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> PAESI-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "SOGLIE-MBE-PATH", &found, ac_soglie_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> SOGLIE-MBE-PATH");
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> SOGLIE-MBE-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}

	Print_Process_Parameters();
}

void Print_Process_Parameters()
{
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

	log(LOG_WARNING, "[GENERIC]");
	log(LOG_WARNING, "\tDB-TFS-CCPLMN-PATH ........: %s", ac_ccplmn_path);
	log(LOG_WARNING, "\tPAESI-MBE-PATH ............: %s", ac_paesi_path);
	log(LOG_WARNING, "\tSOGLIE-MBE-PATH ...........: %s", ac_soglie_path);
	log(LOG_WARNING, "#==============================================================================");
}

void updatePLMN()
{
	short				err;
	short				s_mbe_count;

	int					i_read_count = 0;
	int					i_updated_count = 0;
	int					i_oper_count = 0;

	short				s_ccplmn_rec_len;
	short				s_paesi_rec_len;
	short				s_soglie_rec_len;

	t_interac_tfs_plmn	ccplmn_rec;
	t_ts_paesi_record	paesi_rec;
	t_ts_soglie_record	soglie_rec;

	s_ccplmn_rec_len = sizeof(t_interac_tfs_plmn);
	s_paesi_rec_len = sizeof(t_ts_paesi_record);
	s_soglie_rec_len = sizeof(t_ts_soglie_record);

	log(LOG_WARNING, "Start processing %s", ac_ccplmn_path);

	if (!(err = MBE_FILE_SETKEY_(s_ccplmn_fileid, "", 0, 0, 0)))
	{
		while (!(err = MBE_READX(s_ccplmn_fileid, (char *)&ccplmn_rec, s_ccplmn_rec_len, &s_mbe_count)))
		{
			i_read_count++;

			if (ccplmn_rec.den_op8[0] != 0x20)
			{
				i_oper_count++;

				// Get country name
				if (!(err = MBE_FILE_SETKEY_(s_paesi_fileid, ccplmn_rec.cc, 8, 0, 2)))
				{
					if (!(err = MBE_READX(s_paesi_fileid, (char *)&paesi_rec, s_paesi_rec_len, &s_mbe_count)))
					{
						memset((char *)&soglie_rec, 0x20, s_soglie_rec_len);
						memcpy(soglie_rec.gr_pa, paesi_rec.den_paese, 64);
						memcpy(soglie_rec.gr_op, ccplmn_rec.den_op8, 8);
						if (!(err = MBE_FILE_SETKEY_(s_soglie_fileid, (char *)&soglie_rec, 128, 0, 1)))
						{
							while (!(err = MBE_READX(s_soglie_fileid, (char *)&soglie_rec, s_soglie_rec_len, &s_mbe_count)))
							{
								// Check if valid and we are over threshold
								if (isRuleValid(soglie_rec))
								{
									float perc = (float)((soglie_rec.tot_accP[0]+soglie_rec.tot_accP[1]) * 100. / 
													(soglie_rec.tot_accT[0]+soglie_rec.tot_accT[1]+0.0001));

									short s_new_pplmn = ccplmn_rec.pplmn;

									log(LOG_DEBUG, "Threshold [%f] for cc [%.8s] op [%.8s]", perc, ccplmn_rec.cc, ccplmn_rec.den_op8);

									if (perc > soglie_rec.soglia)
									{
										if (soglie_rec.pplmn2 != 0x2020)
											s_new_pplmn = soglie_rec.pplmn2;
									}
									else
									{
										if (soglie_rec.pplmn1 != 0x2020)
											s_new_pplmn = soglie_rec.pplmn1;
									}

									if (ccplmn_rec.pplmn != s_new_pplmn)
									{
										ccplmn_rec.pplmn = s_new_pplmn;

										if ((err = MBE_WRITEUPDATEX(s_ccplmn_fileid, (char *)&ccplmn_rec, s_ccplmn_rec_len, &s_mbe_count)))
										{
											log(LOG_ERROR, "error [%d] updating cc [%.8s] op [%.8s]", err, ccplmn_rec.cc, ccplmn_rec.den_op8);
										}
										else
										{
											log(LOG_WARNING, "Updated cc [%.8s] op [%.8s] pplmn [%d]", ccplmn_rec.cc, ccplmn_rec.den_op8, ccplmn_rec.pplmn);
											i_updated_count++;
											break;
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	else
	{
		log(LOG_ERROR, "error [%d] seeking %s", err, ac_ccplmn_path);
	}

	// Close files
	log(LOG_WARNING, "End processing %s - read %d - oper %d - upd %d", ac_ccplmn_path, i_read_count, i_oper_count, i_updated_count);
	MBE_FILE_CLOSE_(s_soglie_fileid);
	MBE_FILE_CLOSE_(s_ccplmn_fileid);

	log_flush(LOG_FLUSH_NOW);
}

short mbeFileOpen(char *filename, short *fileid)
{
	short	ret = 0;
	short	err;

	if ((err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid)))
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

short isRuleValid(t_ts_soglie_record soglia)
{
	short		ret = 0;
	struct tm	tm_time;
	time_t		now;
	char		fascia[6];

	now = time((time_t *)NULL);
	tm_time = *localtime(&now);
	sprintf(fascia, "%02d:%02d", tm_time.tm_hour, tm_time.tm_min);

	// Check if current day is valid
	if (soglia.gg_settimana[tm_time.tm_wday] == 'X')
	{
		// Check if current time is valid
		if (strncmp(fascia, soglia.fascia_da, 5) >= 0 &&
			strncmp(fascia, soglia.fascia_a, 5) <= 0)
		{
			ret = 1;
		}
	}

	return ret;
}
