/*----------------------------------------------------------------------------
*   PROGETTO : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name       : trstrg.c
*   Ultima Modifica : 15/03/2016
*------------------------------------------------------------------------------
*   Descrizione
*   -----------
*   TS Trigger
*------------------------------------------------------------------------------
*   Funzioni contenute
*   ------------------
*	Receive back-to-HPLMN signal from EIR/IMEI Manager
*	Remove IMSI record from TFS IMSIdb (if not in white or barred list !)
*	Notify return to Home PLMN (Unbundling IF4)
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

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>

#include <cextdecs.h>
#include <p2apdf.h>
#include "usrlib.h"

#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"
#include "sspstat.h"

#include "ts.h"
#include "roamun.h"

/*---------------------< Definitions >---------------------------------------*/

/*---------------------< Parameters >----------------------------------------*/

//LOG
char		ac_path_log_file[30];
char		ac_log_prefix[10];
int			i_num_days_of_log;
int			i_trace_level;
int			i_log_options;
char		ac_log_trace_string[128];

//EMS
short		s_ems_subsystem;
char		ac_ems_owner[16];
char		ac_ems_version[16];
char		ac_ems_appl[32];
char		ac_ems_text[168];
long long	ll_ems_time_interval;

//STAT
char		ac_path_stat_file[30];
char		ac_stat_prefix[3];
short		i_stat_group;
short		i_stat_max_registers;
short		i_stat_max_counters;
int			i_stat_bump_interval;

//GENERIC
char		ac_imsi_gsm_mbe_path[48];
char		ac_imsi_dat_mbe_path[48];
//char		ac_imsi_lte_mbe_path[48];
char		ac_arp_lbo_mbe_path[48];
char		ac_roaming_eu_if4_path[48];

//MANAGER
char		s_imsi_prefix_len;

/*---------------------< Static and Global Variables >-----------------------*/

IO_RECEIVE  ReceiveIO;

char	ac_my_process_name[10];
short	i_my_tid;
short	i_my_svr_cls;
short	i_my_node_id;
short	i_my_cpu;

char	*pc_ini_file;
char	ac_path_file_ini_oss[64];

short	s_imsi_gsm_mbe_id = 0;
short	s_imsi_dat_mbe_id = 0;
//short	s_imsi_lte_mbe_id = 0;
short	s_arp_lbo_mbe_id = 0;
short	s_roaming_eu_if4_id = 0;

char	imsi[18];

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization(char reload);
void Print_Process_Parameters();
short checkIniFile();

void Open_Input_Queue(IO_RECEIVE *ReceiveIO);
short Read_Input_Queue(IO_RECEIVE *ReceiveIO);
short Func_SIGNALTIMEOUT(long timeout, short param1, long param2, short *tag);

short mbeFileOpen(char *filename, short *fileid);
void log_evt_t(long long ll_ems_interval, long long *ll_ems_last_evt, short i_critical, short i_action, short i_event_num, const char *msg, ...);
void delImsi(char *rev_imsi);
short delImsiDatabase(char *type, char *imsi_mbe_path, short *imsi_mbe_id, char *rev_imsi);
short isARPUser(char *rev_imsi);
short insertRoamEU(t_ts_imsi_record *imsi_rec, char status, char changed, char mccmnc_len);

/*---------------------------------------------------------------------------*/

int main (short argc, char * argv[])
{
	short	rc;					// Return code after reading a new message
	short	Stop = 0;			// Whether to exit the infinite loop
	short	file_id;			// Source of the received message
	short	receive_cnt;
	long	i_tag;
	int		i;
	int		i_stat_bump_retry_interval;

	t_TrackingMsg		msg_rx;
	IO_SYSMSG_TIMEOUT	signal;

	short	sender_info[17];
    short	sender_handle[10];
    char	sender_process_name[16];
    short	sender_process_maxlen = sizeof(sender_process_name);

    short	sender_mom_handle[10];
    char	sender_mom_process_name[16];
    short	sender_mom_process_maxlen = sizeof(sender_mom_process_name);

    Process_Initialization(0);

	// Open $RECEIVE
	Open_Input_Queue(&ReceiveIO);
	Read_Input_Queue(&ReceiveIO);

	// Open MBEs
	Stop = mbeFileOpen(ac_imsi_gsm_mbe_path, &s_imsi_gsm_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_imsi_dat_mbe_path, &s_imsi_dat_mbe_id);
	//if (!Stop) Stop = mbeFileOpen(ac_imsi_lte_mbe_path, &s_imsi_lte_mbe_id);
	if (!Stop && ac_arp_lbo_mbe_path[0]) Stop = mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);
	if (!Stop && ac_roaming_eu_if4_path[0]) Stop = mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);

	if (!Stop)
	{
		log(LOG_ERROR, "Process started");
		//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STARTED, "Process started");

		if (i_stat_bump_interval > 0)
			Func_SIGNALTIMEOUT(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT, NULL);
	}

	// Main Loop
	while (!Stop) 
	{
		file_id = -1;
		AWAITIOX(&file_id, , &receive_cnt, &i_tag, -1);
		FILE_GETINFO_(file_id, &rc);
		log(LOG_DEBUG, "Rcv: file = %d, rc = %d, cnt = %d, tag = %d", file_id, rc, receive_cnt, i_tag);

		if (file_id == 0)
		{
			REPLYX();

			switch(rc)
			{
				case 0:
				{
					memcpy((char *)&msg_rx, ReceiveIO.data, sizeof(msg_rx));

					memset(imsi, 0x00, sizeof(imsi));
					memcpy(imsi, msg_rx.eir_tracking_rec.eir_imsi_rec.imsi, sizeof(msg_rx.eir_tracking_rec.eir_imsi_rec.imsi));
					TrimString(imsi);
					StringReverse(imsi);

					AddStat("-", ac_my_process_name, STAT_TRG_RECV);
					delImsi(msg_rx.eir_tracking_rec.eir_imsi_rec.imsi);

					break;
				}

				case 6:
				{
					// System message
					memcpy(&signal, &ReceiveIO.data, sizeof(IO_SYSMSG_TIMEOUT));
					log(LOG_DEBUG, "rcv system signal %d", signal.id);

					switch(signal.id)
					{
						case SYS_MSG_TIME_TIMEOUT:
						{
							switch (signal.l_par) 
							{
								case TAG_BUMP_STAT:
								{
									i_stat_bump_retry_interval = BumpStat();

									switch (i_stat_bump_retry_interval)
									{
										case 0:
										case 2:
										{
											log(LOG_ERROR, "Statistics - error code %d", i_stat_bump_retry_interval);
											log_flush(LOG_FLUSH_NOW);
											Func_SIGNALTIMEOUT(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT, NULL);
											break;
										}
										case 1:
										{
											log(LOG_WARNING, "Statistics - saved");

											if (checkIniFile())
											{
												Process_Initialization(1);
											}
											else
											{
												log(LOG_WARNING, "Parameters - reload skipped");
											}

											Func_SIGNALTIMEOUT(stat_timerval(i_stat_bump_interval/100), 0, TAG_BUMP_STAT, NULL);
											break;
										}
										default:
										{
											log(LOG_ERROR, "Statistics - postponed (%d)", i_stat_bump_retry_interval);
											log_flush(LOG_FLUSH_NOW);
											Func_SIGNALTIMEOUT(i_stat_bump_retry_interval, 0, TAG_BUMP_STAT, NULL);
											break;
										}
									}
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
						case -103:
						case -104:
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

					break;
				}
				default:
				{
					break;
				}
			}

			if (!Stop) Read_Input_Queue(&ReceiveIO);
		}
		else
		{
			log(LOG_WARNING, "rcv unexpected msg: file = %d, rc = %d, cnt = %d, tag = %d", file_id, rc, receive_cnt, i_tag);
		}
	}

	MBE_FILE_CLOSE_(s_imsi_gsm_mbe_id);
	MBE_FILE_CLOSE_(s_imsi_dat_mbe_id);
	//MBE_FILE_CLOSE_(s_imsi_lte_mbe_id);

	BumpStat();
	log(LOG_ERROR, "Process stopped");
	log_close();
	//log_evt(SSPEVT_NORMAL, SSPEVT_NOACTION, EMS_EVT_PROCESS_STOPPED, "Process stopped");
	exit(0);
}

/****************************************************************************
***  Module Name:  Process_Initialization                                  **
***                                                                        **
***  Description:  This module is responsible for processing all of the    **
***                run-time parameters and determining if the process      **
***                has been started under the Node or in a stand-alone     **
***                environment.                                            **                                                                        **
*****************************************************************************/
void Process_Initialization(char reload)
{
    int   	found;
	char  	ac_wrk_str[1024];
	char	*wrk_str;
	short 	i_proch[20];
	short 	i_maxlen = sizeof(ac_my_process_name);

	PROCESSHANDLE_GETMINE_(i_proch);
	//PROCESSHANDLE_DECOMPOSE_(i_proch,, &i_my_pin,,,,, ac_my_process_name, i_maxlen, &i_maxlen,);
	PROCESSHANDLE_DECOMPOSE_(i_proch, &i_my_cpu,,,,,, ac_my_process_name, i_maxlen, &i_maxlen,);

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
		get_profile_string(pc_ini_file, "TRIGGER", "EMS-APPL", &found, ac_ems_appl);
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
		get_profile_string(pc_ini_file, "TRIGGER", "LOG-DAYS", &found, ac_wrk_str);
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
	if (get_profile_string(pc_ini_file, "TRIGGER", "LOG-LEVEL", &found, ac_wrk_str))
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
	get_profile_string(pc_ini_file, "TRIGGER", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	}

	log_param(i_trace_level, i_log_options, "");

	get_profile_string(pc_ini_file, "TRIGGER", "LOG-TRACE", &found, ac_log_trace_string);
	if (ac_log_trace_string[0])
		log_set_trace(ac_log_trace_string);
	else
		log_reset_trace();

	get_profile_string(pc_ini_file, "EMS", "EMS-TIME-INTERVAL", &found, ac_wrk_str);
	if (found == SSP_TRUE) ll_ems_time_interval = (long long)atoi(ac_wrk_str) * 1000000;
	else ll_ems_time_interval = 60000000;

	/* --- GENERIC --------------------------------------------------------- */
	if (!reload)
	{
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-GSM-MBE-PATH", &found, ac_imsi_gsm_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-GSM-MBE-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-DAT-MBE-PATH", &found, ac_imsi_dat_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-DAT-MBE-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
/*
		get_profile_string(pc_ini_file, "GENERIC", "IMSI-LTE-MBE-PATH", &found, ac_imsi_lte_mbe_path);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter GENERIC -> IMSI-LTE-MBE-PATH");
			DELAY (EXIT_DELAY);
			exit(0);
		}
*/
		get_profile_string(pc_ini_file, "GENERIC", "BLBO-ARP-MBE-PATH", &found, ac_arp_lbo_mbe_path);
		get_profile_string(pc_ini_file, "GENERIC", "ROAMING-EU-IF4-PATH", &found, ac_roaming_eu_if4_path);
	}

	get_profile_string(pc_ini_file, "GTT", "IMSI-PREFIX-LEN", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_imsi_prefix_len = (char)atoi(ac_wrk_str);
	else s_imsi_prefix_len = 0;

	/* --- STAT ------------------------------------------------------------ */
	if (!reload)
	{
		i_stat_bump_interval = 30000;
		get_profile_string(pc_ini_file, "STAT", "STAT-BUMP-INTERVAL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_bump_interval = (short)(atoi(ac_wrk_str) * 100);
		get_profile_string(pc_ini_file, "STAT", "STAT-PATH", &found, ac_path_stat_file);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-PATH");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-PATH");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "STAT-PREFIX", &found, ac_stat_prefix);
		if (found == SSP_FALSE)
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-PREFIX");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-PREFIX");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "STAT-GROUP", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_group = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> STAT-GROUP");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> STAT-GROUP");
			DELAY(EXIT_DELAY);
			exit(0);
		}
		get_profile_string(pc_ini_file, "STAT", "MAX-REGS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_max_registers = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> MAX-REGS");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> MAX-REGS");
			DELAY(EXIT_DELAY);
			exit (0);
		}
		get_profile_string(pc_ini_file, "STAT", "MAX-COUNTS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_stat_max_counters = (short)atoi(ac_wrk_str);
		else
		{
			log(LOG_ERROR, "Missing parameter STAT -> MAX-COUNTS");
			log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MISSING_PARAM, "Missing parameter STAT -> MAX-COUNTS");
			DELAY(EXIT_DELAY);
			exit (0);
		}

		// Init stat
		if (!Stat_init(ac_path_stat_file, ac_stat_prefix, "", i_stat_group, i_stat_max_registers, i_stat_max_counters))
		{
			log(LOG_ERROR, "Stat init error");
			DELAY(EXIT_DELAY);
			exit (0);
		}
	}

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
	log(LOG_WARNING, "\tLOG-TRACE .................: %s", ac_log_trace_string);

	log(LOG_WARNING, "[STAT]");
	log(LOG_WARNING, "\tSTAT-BUMP-INTERVAL ........: %d", i_stat_bump_interval/100);
	log(LOG_WARNING, "\tSTAT-PATH .................: %s", ac_path_stat_file);
	log(LOG_WARNING, "\tSTAT-PREFIX ...............: %s", ac_stat_prefix);
	log(LOG_WARNING, "\tSTAT-GROUP ................: %d", i_stat_group);
	log(LOG_WARNING, "\tMAX-REGS ..................: %d", i_stat_max_registers);
	log(LOG_WARNING, "\tMAX-COUNTS ................: %d", i_stat_max_counters);

	log(LOG_WARNING, "[GENERIC]");
	log(LOG_WARNING, "\tIMSI-GSM-MBE-PATH .........: %s", ac_imsi_gsm_mbe_path);
	log(LOG_WARNING, "\tIMSI-DAT-MBE-PATH .........: %s", ac_imsi_dat_mbe_path);
//	log(LOG_WARNING, "\tIMSI-LTE-MBE-PATH .........: %s", ac_imsi_lte_mbe_path);
	log(LOG_WARNING, "\tBLBO-ARP-MBE-PATH .........: %s", ac_arp_lbo_mbe_path);
	log(LOG_WARNING, "\tROAMING-EU-IF4-PATH .......: %s", ac_roaming_eu_if4_path);

	log(LOG_WARNING, "[GTT]");
	log(LOG_WARNING, "\tIMSI-PREFIX-LEN ...........: %d", s_imsi_prefix_len);
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

void Open_Input_Queue(IO_RECEIVE *ReceiveIO)
{
	short ret;

	strcpy(ReceiveIO->fname, "$RECEIVE");
	if ((ret = FILE_OPEN_(ReceiveIO->fname, (short)strlen(ReceiveIO->fname), &ReceiveIO->id, 0, 0, 1, 1)))
	{
	    log(LOG_ERROR, "error [%d] opening $RECEIVE", ret);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_IO_RECEIVE_ERR_OPEN, "error [%d] opening $RECEIVE", ret);
		DELAY(EXIT_DELAY);
		exit(0);
	}
}

short Read_Input_Queue(IO_RECEIVE *ReceiveIO)
{
	short cnt_read = 0;
	memset( ReceiveIO->data, ' ', sizeof(ReceiveIO->data) );

	READUPDATEX(ReceiveIO->id, (ReceiveIO->data), (short)sizeof(ReceiveIO->data), &cnt_read);
	FILE_GETINFO_(ReceiveIO->id, &ReceiveIO->error);
	if (ReceiveIO->error > 0)
	{
		log(LOG_ERROR, "error [%d] reading $RECEIVE", ReceiveIO->error);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_IO_RECEIVE_ERR_READ, "error [%d] reading $RECEIVE", ReceiveIO->error);
		DELAY(EXIT_DELAY);
		exit(0);
	}
	return( cnt_read );
}

void delImsi(char *rev_imsi)
{
	delImsiDatabase("GSM", ac_imsi_gsm_mbe_path, &s_imsi_gsm_mbe_id, rev_imsi);
	delImsiDatabase("DAT", ac_imsi_dat_mbe_path, &s_imsi_dat_mbe_id, rev_imsi);
//	delImsiDatabase("LTE", ac_imsi_lte_mbe_path, &s_imsi_lte_mbe_id, rev_imsi);
}

short delImsiDatabase(char *type, char *imsi_mbe_path, short *imsi_mbe_id, char *rev_imsi)
{
	static long long ll_ems_time_last_imsi_jts = 0;
	short	ret = 0;
	short	err;

	t_ts_imsi_record	imsi_rec;

	if (!(err = MBE_FILE_SETKEY_(*imsi_mbe_id, rev_imsi, sizeof(imsi_rec.imsi), 0, 2)))
	{
		if (!(err = MBE_READX(*imsi_mbe_id, (char *)&imsi_rec, sizeof(imsi_rec))))
		{
			if (ac_arp_lbo_mbe_path[0] && ac_roaming_eu_if4_path[0] && isARPUser(rev_imsi))
				insertRoamEU(&imsi_rec, 0, 1, s_imsi_prefix_len);

			// Delete from IMSIdb
			if (imsi_rec.status == IMSI_STATUS_GRANT_ALWAYS)
			{
				log(LOG_WARNING, "%s|%s|imsi not deleted (steering white list)", imsi, type);
			}
			else if (imsi_rec.status == IMSI_STATUS_STEER_ALWAYS)
			{
				log(LOG_WARNING, "%s|%s|imsi not deleted (barred list)", imsi, type);
			}
			else
			{
				if (!(err = MBE_WRITEUPDATEX(*imsi_mbe_id, (char *)&imsi_rec, 0)))
				{
					AddStat(type, ac_my_process_name, STAT_TRG_UPD);
					log(LOG_WARNING, "%s|%s|imsi deleted", imsi, type);
				}
				else
				{
					log_evt_t(ll_ems_time_interval, &ll_ems_time_last_imsi_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] deleting imsi %s", err, type);
					log(LOG_ERROR, "%s|%s|error [%d] deleting imsi", imsi, type, err);
					ret++;

					if (err!=1 && err!=11)
						mbeFileOpen(imsi_mbe_path, imsi_mbe_id);
				}
			}
		}
		else
		{
			AddStat(type, ac_my_process_name, STAT_TRG_ERR);
			ret++;

			if (err!=1 && err!=11)
			{
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_imsi_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading imsi %s", err, type);
				log(LOG_ERROR, "%s|error [%d] reading %s", imsi, err, imsi_mbe_path);
				mbeFileOpen(imsi_mbe_path, imsi_mbe_id);
			}
			else
				log(LOG_WARNING, "%s|%s|imsi not found", imsi, type);
		}
	}
	else
	{
		AddStat(type, ac_my_process_name, STAT_TRG_ERR);
		ret++;

		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_imsi_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking imsi %s", err, type);
		log(LOG_ERROR, "%s|%s|error [%d] seeking imsi", imsi, type, err);
		mbeFileOpen(imsi_mbe_path, imsi_mbe_id);
	}

	return(ret);
}

short insertRoamEU(t_ts_imsi_record *imsi_rec, char status, char changed, char mccmnc_len)
{
	static long long ll_ems_time_last_roameuq_jts = 0;
	short	ret = 0;
	short	err;

	t_ts_if4_record		roameu_rec;

	// Write into IF4 queue
	memset((char *)&roameu_rec, 0x20, sizeof(roameu_rec));
	memcpy(roameu_rec.imsi, imsi_rec->imsi, 16);
	if (!(err = MBE_FILE_SETKEY_(s_roaming_eu_if4_id, roameu_rec.imsi, sizeof(roameu_rec.imsi), 0, 2)))
	{
		err = MBE_READX(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec));

		memcpy(roameu_rec.msisdn, imsi_rec->msisdn, 16);
		roameu_rec.roamingStatus = status;
		roameu_rec.roamingChanged = changed;
		memcpy(roameu_rec.mccmnc, imsi_rec->imsi, mccmnc_len);
		roameu_rec.jts = JULIANTIMESTAMP();
		roameu_rec.c_retry = 0;

		if (!err)
		{
			if (!(err = MBE_WRITEUPDATEX(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec))))
			{
				log(LOG_INFO, "%s|EU roaming updated (%d,%d,%.*s)", imsi, status, changed, mccmnc_len, imsi);
			}
			else
			{
				ret++;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] updating %s", err, ac_roaming_eu_if4_path);
				log(LOG_ERROR, "%s|error [%d] updating %s", imsi, err, ac_roaming_eu_if4_path);

				if (err!=1 && err!=11)
					mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
			}
		}
		else
		{
			memcpy(roameu_rec.msisdn, imsi_rec->msisdn, 16);
			roameu_rec.roamingStatus = status;
			roameu_rec.roamingChanged = changed;
			memcpy(roameu_rec.mccmnc, imsi_rec->imsi, mccmnc_len);
			roameu_rec.jts = JULIANTIMESTAMP();
			roameu_rec.c_retry = 0;

			if (!(err = MBE_WRITEX(s_roaming_eu_if4_id, (char *)&roameu_rec, sizeof(roameu_rec))))
			{
				log(LOG_INFO, "%s|EU roaming inserted (%d,%d,%.*s)", imsi, status, changed, mccmnc_len, imsi);
			}
			else
			{
				ret++;
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] writing %s", err, ac_roaming_eu_if4_path);
				log(LOG_ERROR, "%s|error [%d] writing %s", imsi, err, ac_roaming_eu_if4_path);

				if (err!=45)	// Error but file full
					mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
			}
		}
	}
	else
	{
		ret++;
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_roameuq_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_roaming_eu_if4_path);
		log(LOG_ERROR, "%s|error [%d] seeking %s", imsi, err, ac_roaming_eu_if4_path);
		mbeFileOpen(ac_roaming_eu_if4_path, &s_roaming_eu_if4_id);
	}

	return(ret);
}

short isARPUser(char *rev_imsi)
{
	static long long ll_ems_time_last_arplbo_jts = 0;
	long long	ll_recordts;
	short		ret = 0;
	short		err;
	ROAMUN_user	user_rec;

	memset((char *)&user_rec, 0x00, sizeof(user_rec));
	memcpy(user_rec.imsi, rev_imsi, strlen(rev_imsi));
	if (!(err = MBE_FILE_SETKEY_(s_arp_lbo_mbe_id, user_rec.imsi, 18, 0, 2)))
	{
		if (!(err = MBE_READX(s_arp_lbo_mbe_id, (char *)&user_rec, sizeof(user_rec))))
		{
			ll_recordts = JULIANTIMESTAMP();
			if (ll_recordts >= user_rec.start_date && ll_recordts <= user_rec.end_date)
			{

				if (user_rec.arp_id)
				{
					ret = 1;
					log(LOG_INFO, "%s|found imsi for ARP (%d)", imsi, user_rec.arp_id);
				}
			}
			else
			{
				log(LOG_INFO, "%s|ARP date out of range", imsi);
			}
		}
		else
		{
			if (err!=1 && err!=11)
			{
				log_evt_t(ll_ems_time_interval, &ll_ems_time_last_arplbo_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] reading %s", err, ac_arp_lbo_mbe_path);
				log(LOG_ERROR, "%s|error [%d] reading %s", imsi, err, ac_arp_lbo_mbe_path);
				mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);
			}
			else
			{
				log(LOG_DEBUG, "%s|ARP user not found");
			}
		}
	}
	else
	{
		log_evt_t(ll_ems_time_interval, &ll_ems_time_last_arplbo_jts, SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error [%d] seeking %s", err, ac_arp_lbo_mbe_path);
		log(LOG_ERROR, "%s|error [%d] seeking %s", imsi, err, ac_arp_lbo_mbe_path);
		mbeFileOpen(ac_arp_lbo_mbe_path, &s_arp_lbo_mbe_id);
	}

	return(ret);
}

short mbeFileOpen(char *filename, short *fileid)
{
	static long long	ll_ems_time_last_open_jts = 0;
	short				ret = 0;
	short				err;

	if (*fileid)
		MBE_FILE_CLOSE_(*fileid);

	if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
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

short Func_SIGNALTIMEOUT(long timeout, short param1, long param2, short *tag)
{
	short ret;

	if (tag == NULL)
	{
		ret = (short)SIGNALTIMEOUT(timeout, param1, param2);
	}
	else
	{
		ret = (short)SIGNALTIMEOUT(timeout, param1, param2, tag);
	}

	if (ret)
	{
		log(LOG_ERROR, "error [%d] on SIGNALTIMEOUT(%ld,%d,%ld)", ret, timeout, param1, param2);
		log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_SIGNALTIMEOUT_ERROR, "error [%d] on SIGNALTIMEOUT(%ld,%d,%ld)", ret, timeout, param1, param2);
	}

	return ret;
}
