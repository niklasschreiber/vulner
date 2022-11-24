/*----------------------------------------------------------------------------
*   PROJECT : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsmfd.c
*   Last Modified : 15/03/2016
*------------------------------------------------------------------------------
*   Description
*   -----------
*	Traffic Steering DB Copy
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   Copy content of old db into new structures for all databases
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
#include <stddef.h>
#include <fcntl.h>
#include <memory.h>
#include <strings.h>
#include <errno.h>
#include <ctype.h>
#include <tal.h>
#include <limits.h>

#include <cextdecs.h>
#include <p2apdf.h>
#include "usrlib.h"

#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"

#include "ts.h"

/*---------------------< Definitions >---------------------------------------*/


/*---------------------< Static and Global Variables >-----------------------*/

char	ac_my_process_name[10];
char	*pc_ini_file;

/*---------------------< Parameters >----------------------------------------*/

//LOG
char				ac_path_log_file[30];
char				ac_log_prefix[10];
int					i_num_days_of_log;
int					i_trace_level;
int					i_log_options;

//EMS
short				s_ems_subsystem;
char				ac_ems_owner[16];
char				ac_ems_version[16];
char				ac_ems_appl[32];
char				ac_ems_text[168];

//GENERIC
char				ac_oper_db_path[48];
char				ac_opergt_db_path[48];
char				ac_nostdtac_db_path[48];
char				ac_paesi_db_path[48];
char				ac_psrules_db_path[48];
char				ac_soglie_db_path[48];
char				ac_gtt_nodes_path[48];
char				ac_gtt_mgt_path[48];

//COPY
char				ac_oper_db_path_old[48];
char				ac_opergt_db_path_old[48];
char				ac_nostdtac_db_path_old[48];
char				ac_paesi_db_path_old[48];
char				ac_psrules_db_path_old[48];
char				ac_soglie_db_path_old[48];
char				ac_gtt_nodes_path_old[48];
char				ac_gtt_mgt_path_old[48];

short				s_mgt_by_range;

/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization();
short mbeFileOpen(char *filename, short *fileid);
void latin9_to_utf8(unsigned char *out, unsigned char *in, short in_len);

int main(short argc, char * argv[]) 
{
    short		Stop;
	int			count;
	short		s_mbe_id, s_mbe2_id;
	short		err;
	char		ac_soglie_rec_ignored[TS_SOGLIE_KEYLEN_OLD];

	// New structures
	t_ts_oper_record		oper_rec;
	t_ts_paesi_record		paesi_rec;
	t_ts_soglie_record		soglie_rec;

	t_ts_nostd_tac_record	nostdtac_rec;
	t_ts_opergt_record		opergt_rec;
	t_ts_psrule_record		psrules_rec;

	du_impianti_rec_def		gtt_nodes_rec;
	du_mgt_rec_def			gtt_mgt_rec;
	du_mgtr_rec_def			gtt_mgtr_rec;

	// Old structures
	t_ts_oper_record_old	oper_rec_old;
	t_ts_paesi_record_old	paesi_rec_old;
	t_ts_soglie_record_old	soglie_rec_old;

	Process_Initialization();
	log(LOG_ERROR, "Process started");

	// OPERATOR
	Stop = mbeFileOpen(ac_oper_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_oper_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_oper_db_path, ac_oper_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&oper_rec_old, sizeof(oper_rec_old))))
			{
				count++;

				memset((char *)&oper_rec, 0x20, sizeof(oper_rec));
				memcpy(oper_rec.paese, oper_rec_old.paese, 8);
				memcpy(oper_rec.cod_op, oper_rec_old.cod_op, 10);
				latin9_to_utf8(oper_rec.den_op, oper_rec_old.den_op, 30);
				latin9_to_utf8(oper_rec.den_paese, oper_rec_old.den_paese, 30);
				latin9_to_utf8(oper_rec.gruppo_op, oper_rec_old.gruppo_op, 30);
				latin9_to_utf8(oper_rec.gruppo_pa, oper_rec_old.gruppo_pa, 30);
				oper_rec.max_ts = oper_rec_old.max_ts;
				memcpy(oper_rec.imsi_op, oper_rec_old.imsi_op, 16);
				oper_rec.map_ver = oper_rec_old.map_ver;
				oper_rec.reset_ts_interval = oper_rec_old.reset_ts_interval;
				memcpy(oper_rec.characteristics, oper_rec_old.characteristics, 10);
				oper_rec.steering_map_errcode = oper_rec_old.steering_map_errcode;
				if (oper_rec.steering_map_errcode == 0x20)
					oper_rec.steering_map_errcode = 34;
				oper_rec.steering_lte_errcode = 5012;
				memcpy(oper_rec.filler, oper_rec_old.filler, 9);

				if (err = MBE_WRITEX(s_mbe_id, (char *)&oper_rec, sizeof(oper_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_oper_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_WARNING, "error [%d] reading %s", err, ac_oper_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_oper_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_oper_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_oper_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);


	// PAESI
	Stop = mbeFileOpen(ac_paesi_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_paesi_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_paesi_db_path, ac_paesi_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&paesi_rec_old, sizeof(paesi_rec_old))))
			{
				count++;

				memset((char *)&paesi_rec, 0x20, sizeof(paesi_rec));
				memcpy(paesi_rec.paese, paesi_rec_old.paese, 8);
				latin9_to_utf8(paesi_rec.gr_pa, paesi_rec_old.gr_pa, 30);
				latin9_to_utf8(paesi_rec.den_paese, paesi_rec_old.den_paese, 30);
				paesi_rec.max_ts = paesi_rec_old.max_ts;
				paesi_rec.reset_ts_interval = paesi_rec_old.reset_ts_interval;
				if (paesi_rec_old.eu_flag == 0x31)
					paesi_rec.eu_flag = paesi_rec_old.eu_flag;
				else
					paesi_rec.eu_flag = 0x30;

				if (err = MBE_WRITEX(s_mbe_id, (char *)&paesi_rec, sizeof(paesi_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_paesi_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_paesi_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_paesi_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_paesi_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_paesi_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);


	// SOGLIE
	Stop = mbeFileOpen(ac_soglie_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_soglie_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_soglie_db_path, ac_soglie_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			memset(ac_soglie_rec_ignored, '*', TS_SOGLIE_KEYLEN_OLD);

			while (!(err = MBE_READX(s_mbe2_id, (char *)&soglie_rec_old, sizeof(soglie_rec_old))))
			{
				if (memcmp((char *)&soglie_rec_old, ac_soglie_rec_ignored, TS_SOGLIE_KEYLEN_OLD))
				{
					count++;

					memset((char *)&soglie_rec, 0x20, sizeof(soglie_rec));
					latin9_to_utf8(soglie_rec.gr_pa, soglie_rec_old.gr_pa, 30);
					latin9_to_utf8(soglie_rec.gr_op, soglie_rec_old.gr_op, 30);
					memcpy(soglie_rec.fascia_da, soglie_rec_old.fascia_da, 17);
					memset(soglie_rec.user_type, 0xFF, sizeof(soglie_rec.user_type));
					soglie_rec.stato = soglie_rec_old.stato;
					soglie_rec.soglia = soglie_rec_old.soglia;
					soglie_rec.tot_accP[0] = soglie_rec_old.tot_accP[0];
					soglie_rec.tot_accP[1] = soglie_rec_old.tot_accP[1];
					soglie_rec.tot_accT[0] = soglie_rec_old.tot_accT[0];
					soglie_rec.tot_accT[1] = soglie_rec_old.tot_accT[1];
					soglie_rec.peso = soglie_rec_old.peso;
					soglie_rec.politica = soglie_rec_old.politica;
					//soglie_rec.pplmn1 = soglie_rec_old.pplmn1;
					//soglie_rec.pplmn2 = soglie_rec_old.pplmn2;
				}
				else
				{
					// Special key *
					memset((char *)&soglie_rec, 0x20, sizeof(soglie_rec));
					memset((char *)&soglie_rec, '*', TS_STRULES_KEYLEN);
					soglie_rec.tot_accP[0] = soglie_rec_old.tot_accP[0];
					soglie_rec.tot_accP[1] = soglie_rec_old.tot_accP[1];
					soglie_rec.tot_accT[0] = soglie_rec_old.tot_accT[0];
					soglie_rec.tot_accT[1] = soglie_rec_old.tot_accT[1];
				}

				if (err = MBE_WRITEX(s_mbe_id, (char *)&soglie_rec, sizeof(soglie_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_soglie_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_soglie_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_soglie_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_soglie_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_soglie_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);


	//--- Altri db non cambiati di struttura -------------------------------------------------------------

	// RULES (Pre Steering)
	Stop = mbeFileOpen(ac_psrules_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_psrules_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_psrules_db_path, ac_psrules_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&psrules_rec, sizeof(psrules_rec))))
			{
				count++;

				if (psrules_rec.lte_reject_code == 0x3120)
					psrules_rec.lte_reject_code = 5004;
				else
					psrules_rec.lte_reject_code = 0;

				if (err = MBE_WRITEX(s_mbe_id, (char *)&psrules_rec, sizeof(psrules_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_psrules_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_psrules_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_psrules_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_psrules_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_psrules_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);

	// OPERGT
	Stop = mbeFileOpen(ac_opergt_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_opergt_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_opergt_db_path, ac_opergt_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&opergt_rec, sizeof(opergt_rec))))
			{
				count++;

				if (err = MBE_WRITEX(s_mbe_id, (char *)&opergt_rec, sizeof(opergt_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_opergt_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_opergt_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_opergt_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_opergt_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_opergt_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);

	// NOSTD-TAC
	Stop = mbeFileOpen(ac_nostdtac_db_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_nostdtac_db_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_nostdtac_db_path, ac_nostdtac_db_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&nostdtac_rec, sizeof(nostdtac_rec))))
			{
				count++;

				if (err = MBE_WRITEX(s_mbe_id, (char *)&nostdtac_rec, sizeof(nostdtac_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_nostdtac_db_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_nostdtac_db_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_nostdtac_db_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_nostdtac_db_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_nostdtac_db_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);


	// GTT NODES
	Stop = mbeFileOpen(ac_gtt_nodes_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_gtt_nodes_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_gtt_nodes_path, ac_gtt_nodes_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			while (!(err = MBE_READX(s_mbe2_id, (char *)&gtt_nodes_rec, sizeof(gtt_nodes_rec))))
			{
				count++;

				if (err = MBE_WRITEX(s_mbe_id, (char *)&gtt_nodes_rec, sizeof(gtt_nodes_rec)))
				{
					log(LOG_WARNING, "error [%d] writing %s", err, ac_gtt_nodes_path);
				}
			}
			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_gtt_nodes_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_gtt_nodes_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_gtt_nodes_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_gtt_nodes_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);


	// GTT MGT
	Stop = mbeFileOpen(ac_gtt_mgt_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_gtt_mgt_path_old, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		log(LOG_WARNING, "Copying into %s from %s...", ac_gtt_mgt_path, ac_gtt_mgt_path_old);

		if (!(err = MBE_FILE_SETKEY_(s_mbe2_id, "", 0, 0, 0)))
		{
			if (s_mgt_by_range)
			{
				while (!(err = MBE_READX(s_mbe2_id, (char *)&gtt_mgtr_rec, sizeof(gtt_mgtr_rec))))
				{
					count++;

					if (err = MBE_WRITEX(s_mbe_id, (char *)&gtt_mgtr_rec, sizeof(gtt_mgtr_rec)))
					{
						log(LOG_WARNING, "error [%d] writing %s", err, ac_gtt_mgt_path);
					}
				}
			}
			else
			{
				while (!(err = MBE_READX(s_mbe2_id, (char *)&gtt_mgt_rec, sizeof(gtt_mgt_rec))))
				{
					count++;

					if (err = MBE_WRITEX(s_mbe_id, (char *)&gtt_mgt_rec, sizeof(gtt_mgt_rec)))
					{
						log(LOG_WARNING, "error [%d] writing %s", err, ac_gtt_mgt_path);
					}
				}
			}

			if (err != 1)
			{
				log(LOG_INFO, "error [%d] reading %s", err, ac_gtt_mgt_path_old);
			}
		}
		else
		{
			log(LOG_ERROR, "error [%d] seeking %s", err, ac_gtt_mgt_path_old);
		}
	}

	if (!Stop) log(LOG_WARNING, "Copying into %s completed (%d records).", ac_gtt_mgt_path, count);
	else
	{
		log(LOG_ERROR, "Copying into %s failed.", ac_gtt_mgt_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);

	log(LOG_ERROR, "Process stopped");
	log_close();
	exit(0);	
}

void Process_Initialization()
{
	int   found;
	char  ac_wrk_str[1024];
	short i_proch[20];
	short i_maxlen = sizeof(ac_my_process_name);

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
	get_profile_string(pc_ini_file, "COPY", "EMS-APPL", &found, ac_ems_appl);
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
		DELAY(EXIT_DELAY);
		exit(0);
	}
	i_num_days_of_log = 8;
	get_profile_string(pc_ini_file, "COPY", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	i_trace_level = LOG_INFO;
	get_profile_string(pc_ini_file, "COPY", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level = atoi(ac_wrk_str);
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "COPY", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = atoi(ac_wrk_str);
	}

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);
	log_param(i_trace_level, i_log_options, "");

	/* --- COPY ------------------------------------------------------------ */
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-OPER-PATH", &found, ac_oper_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-OPER-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-OPERGT-PATH", &found, ac_opergt_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-OPERGT-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-COUNTRIES-PATH", &found, ac_paesi_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-COUNTRIES-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-NOSTD-TAC-PATH", &found, ac_nostdtac_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-NOSTD-TAC-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-PSRULES-PATH", &found, ac_psrules_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-PSRULES-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-THRESHOLDS-PATH", &found, ac_soglie_db_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-THRESHOLDS-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-NETWORK-NODES", &found, ac_gtt_nodes_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-NETWORK-NODES");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "COPY", "DB-OLD-MGT", &found, ac_gtt_mgt_path_old);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter COPY -> DB-OLD-MGT");
		DELAY (EXIT_DELAY);
		exit(0);
	}

	/* --- GENERIC --------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPER-PATH", &found, ac_oper_db_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPER-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPERGT-PATH", &found, ac_opergt_db_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPERGT-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-COUNTRIES-PATH", &found, ac_paesi_db_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-COUNTRIES-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-NOSTD-TAC-PATH", &found, ac_nostdtac_db_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-NOSTD-TAC-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-PSRULES-PATH", &found, ac_psrules_db_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-PSRULES-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, ac_soglie_db_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GTT", "NETWORK-NODES", &found, ac_gtt_nodes_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> NETWORK-NODES");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GTT", "MGT", &found, ac_gtt_mgt_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> MGT");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	s_mgt_by_range = 0;
	get_profile_string(pc_ini_file, "GTT", "MGT-BY-RANGE", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_mgt_by_range = (short)atoi(ac_wrk_str);

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
	log(LOG_WARNING, "\tDB-LOC-OPER-PATH ..........: %s", ac_oper_db_path);
	log(LOG_WARNING, "\tDB-LOC-OPERGT-PATH ........: %s", ac_opergt_db_path);
	log(LOG_WARNING, "\tDB-LOC-COUNTRIES-PATH .....: %s", ac_paesi_db_path);
	log(LOG_WARNING, "\tDB-LOC-NOSTD-TAC-PATH .....: %s", ac_nostdtac_db_path);
	log(LOG_WARNING, "\tDB-LOC-PSRULES-PATH .......: %s", ac_psrules_db_path);
	log(LOG_WARNING, "\tDB-LOC-THRESHOLDS-PATH ....: %s", ac_soglie_db_path);

	log(LOG_WARNING, "[GTT]");
	log(LOG_WARNING, "\tNETWORK-NODES .............: %s", ac_gtt_nodes_path);
	log(LOG_WARNING, "\tMGT .......................: %s", ac_gtt_mgt_path);
	log(LOG_WARNING, "\tMGT-BY-RANGE ..............: %d", s_mgt_by_range);

	log(LOG_WARNING, "[COPY]");
	log(LOG_WARNING, "\tDB-OLD-OPER-PATH ..........: %s", ac_oper_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-OPERGT-PATH ........: %s", ac_opergt_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-COUNTRIES-PATH .....: %s", ac_paesi_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-NOSTD-TAC-PATH .....: %s", ac_nostdtac_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-PSRULES-PATH .......: %s", ac_psrules_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-THRESHOLDS-PATH ....: %s", ac_soglie_db_path_old);
	log(LOG_WARNING, "\tDB-OLD-NETWORK-NODES ......: %s", ac_gtt_nodes_path_old);
	log(LOG_WARNING, "\tDB-OLD-MGT ................: %s", ac_gtt_mgt_path_old);
	log(LOG_WARNING, "#==============================================================================");
}

short mbeFileOpen(char *filename, short *fileid)
{
	short	ret = 0;
	short	err;

	if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
	{
		log(LOG_ERROR, "error %d opening file %s", err, filename);
		//log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error %d opening file %s", err, filename);
		ret++;
	}
	else
	{
		log(LOG_WARNING, "opened file %s - id %d", filename, *fileid);
	}

	return ret;
}

void latin9_to_utf8(unsigned char *out, unsigned char *in, short in_len)
{
	short	len = in_len;

	while (len)
	{
		if (*in<128)
		{
			*out++ = *in++;
		}
		else if (*in == 0x80) // euro
		{
		   *out++ = 0xe2, *out++ = 0x82, *out++ = 0xac;
		}
		else
		{
			*out++ = 0xc2 + (*in > 0xbf), *out++ = (*in++ & 0x3f) + 0x80;
		}

		len--;
	}
}
