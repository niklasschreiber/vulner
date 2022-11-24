/*----------------------------------------------------------------------------
*   PROJECT : Traffic Steering
*-----------------------------------------------------------------------------
*   File Name     : trsmfd.c
*   Last Modified : 15/03/2016
*------------------------------------------------------------------------------
*   Description
*   -----------
*	Traffic Steering MBE File Dump
*------------------------------------------------------------------------------
*   Functionalities
*   ------------------
*   Daily dumps the content of
*   	<paesi>
*   	<oper/opergt>
*   	<steering>
*   	<pre-steering>
*----------------------------------------------------------------------------*/

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L18_21JUN2018_KTSTEA10_01() {};
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

#include "ds.h"
#include "ts.h"

/*---------------------< Definitions >---------------------------------------*/
#define SQL_NOT_FOUND      100
#define SQL_DUPLICATE_KEY  -8227
#define SQL_OK             0

#define  N_PREFERRED 35
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
int					i_trace_step;

//EMS
short				s_ems_subsystem;
char				ac_ems_owner[16];
char				ac_ems_version[16];
char				ac_ems_appl[32];
char				ac_ems_text[168];

//GENERIC
char				ac_oper_mbe_path[48];
char				ac_opergt_mbe_path[48];
//char				ac_grpoper_mbe_path[48];
char				ac_paesi_mbe_path[48];
char				ac_steering_mbe_path[48];
char				ac_presteering_mbe_path[48];

//DUMP
char				ac_oper_file_path[48];
//char				ac_grpoper_file_path[48];
char				ac_paesi_file_path[48];
char				ac_steering_file_path[48];
char				ac_presteering_file_path[48];
char				ac_pplmn_file_path[48];
short				s_reset_counters;


/* global SQL variables */
EXEC SQL BEGIN DECLARE SECTION;

	char sql_str[300];
	short sqlcode;

	exec SQL invoke =MCONFDB as s_interac_mconf;
    typedef struct s_interac_mconf t_interac_mconf;
	t_interac_mconf		mconf;

EXEC SQL END DECLARE SECTION;

exec sql INCLUDE sqlca;
/*---------------------< External Function Prototypes >----------------------*/

/*---------------------< Internal Function Prototypes >----------------------*/

void Process_Initialization();
short mbeFileOpen(char *filename, short *fileid);
short decodeOpImsi(char *encOpImsi, char *res);

int main(short argc, char * argv[]) 
{
    short		Stop;
	int			count;
    FILE		*file_id;
	short		s_mbe_id, s_mbe2_id;
	short		err, err2;
	short		dateNtime[8];
	char		acGiorni[10];
	char		acCC[10];
	char		ac_tmp[128];
	char		ac_print[1024];
	char		ac_country_rec_ignored[TS_COUNTRY_KEYLEN];
	//char		ac_operator_rec_ignored[TS_OPERATOR_KEYLEN];
	char		ac_strules_rec_ignored[TS_STRULES_KEYLEN];
	char		ac_psrules_rec_ignored[TS_PSRULES_KEYLEN];

	// file Interactim PLMN
	char 		encOpImsi[6];
	char 		opImsi[16];
	char		sTmp[1024];
	short		sMaxOp, i;
	short		ncountGT = 0;

	int			user_type_bitmask;
	char		*ptr_PA;
	char		*ptr_CC;
	char		*ptrPaese;

	AVLTREE		country_list;

	t_ts_oper_record	oper_rec;
	t_ts_opergt_record	opergt_rec;
	//t_ts_grpoper_record	grpoper_rec;
	t_ts_paesi_record	paesi_rec;
	t_ts_soglie_record	steering_rec;
	t_ts_psrule_record	presteering_rec;

	Process_Initialization();
	log(LOG_ERROR, "Process started");

	country_list = avlMake();

	// PAESI
	if (!(Stop = mbeFileOpen(ac_paesi_mbe_path, &s_mbe_id)))
	{
		count = 0;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_paesi_file_path, "%s%04d%02d%02d", ac_paesi_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping %s into %s...", ac_paesi_mbe_path, ac_paesi_file_path);

		if ((file_id = fopen_oss(ac_paesi_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_paesi_file_path );
		}
		else
		{
			fprintf(file_id,"%c%c%c", 0xEF, 0xBB, 0xBF);	// UTF-8 BOM for Excel
			fprintf(file_id, "cc;cc_group;cc_name;max_ts;eu_flag\n");

			if (!(err = MBE_FILE_SETKEY_(s_mbe_id, "", 0, 0, 0)))
			{
				memset(ac_country_rec_ignored, '*', TS_COUNTRY_KEYLEN);

				while (!(err = MBE_READX(s_mbe_id, (char *)&paesi_rec, sizeof(paesi_rec))))
				{
					if (memcmp(paesi_rec.paese, ac_country_rec_ignored, TS_COUNTRY_KEYLEN))
					{
						count++;

						// Load country into memory for future use (cc --> country name conversion)
						ptr_CC = calloc(sizeof(paesi_rec.paese)+1, 1);
						memcpy(ptr_CC, paesi_rec.paese, sizeof(paesi_rec.paese));
						TrimString(ptr_CC);
						ptr_PA = calloc(sizeof(paesi_rec.den_paese)+1, 1);
						memcpy(ptr_PA, paesi_rec.den_paese, sizeof(paesi_rec.den_paese));
						TrimString(ptr_PA);
						avlAdd(country_list, ptr_CC, ptr_PA);

						sprintf(ac_tmp, "%.8s;%.64s", paesi_rec.paese, paesi_rec.gr_pa);
						TrimString(ac_tmp);
						strcpy(ac_print, ac_tmp);
						sprintf(ac_tmp, ";%.64s", paesi_rec.den_paese);
						TrimString(ac_tmp);
						strcat(ac_print, ac_tmp);
						sprintf(ac_tmp, ";%d;%c\n", paesi_rec.max_ts, paesi_rec.eu_flag);
						strcat(ac_print, ac_tmp);

						if ((err = fprintf(file_id, ac_print)) < 0)
						{
							log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
							Stop = 1;
							break;
						}
					}
				}
				if (err != 1)
				{
					log(LOG_INFO, "error [%d] reading %s", err, ac_paesi_mbe_path);
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", err, ac_paesi_mbe_path);
			}
		}
	}

	if (!Stop) log(LOG_WARNING, "Dumping %s completed (%d records).", ac_paesi_mbe_path, count);
	else
	{
		log(LOG_ERROR, "Dumping %s failed.", ac_paesi_mbe_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	fclose(file_id);

	// OPERATOR
	Stop = mbeFileOpen(ac_oper_mbe_path, &s_mbe_id);
	if (!Stop) Stop = mbeFileOpen(ac_opergt_mbe_path, &s_mbe2_id);
	if (!Stop)
	{
		count = 0;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_oper_file_path, "%s%04d%02d%02d", ac_oper_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping %s into %s...", ac_oper_mbe_path, ac_oper_file_path);

		if ((file_id = fopen_oss(ac_oper_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_oper_file_path );
		}
		else
		{
			fprintf(file_id,"%c%c%c", 0xEF, 0xBB, 0xBF);	// UTF-8 BOM for Excel
			fprintf(file_id, "gt;op_code;op_name;cc_name;op_group;cc_group;max_ts;op_imsi;map_ver\n");

			if (!(err = MBE_FILE_SETKEY_(s_mbe_id, "", 0, 0, 0)))
			{
				while (!(err = MBE_READX(s_mbe_id, (char *)&oper_rec, sizeof(oper_rec))))
				{
					if(oper_rec.paese[0] != '*')
					{
						if (!(err2 = MBE_FILE_SETKEY_(s_mbe2_id, (char *)&oper_rec, 18, 1, 1)))
						{
							ncountGT = 0;
							while (!(err2 = MBE_READX(s_mbe2_id, (char *)&opergt_rec, sizeof(opergt_rec))))
							{
								count++;
								ncountGT++;

								sprintf(ac_tmp, "%.24s", opergt_rec.gt);
								TrimString(ac_tmp);
								strcpy(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.10s", oper_rec.cod_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.den_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.den_paese);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.gruppo_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.gruppo_pa);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%d", oper_rec.max_ts);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.16s", oper_rec.imsi_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%d\n", oper_rec.map_ver);
								strcat(ac_print, ac_tmp);

								if ((err = fprintf(file_id, ac_print)) < 0)
								{
									log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
									Stop = 1;
									break;
								}
							}
							if((err2 == 1) && !ncountGT) // GT non trovato
							{
								count++;

								sprintf(ac_tmp, "%.8s", oper_rec.paese);
								strcpy(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.10s", oper_rec.cod_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.den_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.den_paese);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.gruppo_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.64s", oper_rec.gruppo_pa);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%d", oper_rec.max_ts);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%.16s", oper_rec.imsi_op);
								TrimString(ac_tmp);
								strcat(ac_print, ac_tmp);
								sprintf(ac_tmp, ";%d\n", oper_rec.map_ver);
								strcat(ac_print, ac_tmp);

								if ((err = fprintf(file_id, ac_print)) < 0)
								{
									log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
									Stop = 1;
									break;
								}
							}
							else
							{
								log(LOG_INFO, "error [%d] reading %s", err2, ac_opergt_mbe_path);
							}
						}
						else
						{
							log(LOG_ERROR, "error [%d] seeking %s", err2, ac_opergt_mbe_path);
						}
					}
				}
				if (err != 1)
				{
					log(LOG_INFO, "error [%d] reading %s", err, ac_oper_mbe_path);
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", ac_oper_mbe_path, err);
			}
		}
	}

	if (!Stop) log(LOG_WARNING, "Dumping %s completed (%d records).", ac_oper_mbe_path, count);
	else
	{
		log(LOG_ERROR, "Dumping %s failed.", ac_oper_mbe_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	MBE_FILE_CLOSE_(s_mbe2_id);
	fclose(file_id);

	// GRPOPER
/*
	if (!(Stop = mbeFileOpen(ac_grpoper_mbe_path, &s_mbe_id)))
	{
		count = 0;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_grpoper_file_path, "%s%04d%02d%02d", ac_grpoper_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping %s into %s...", ac_grpoper_mbe_path, ac_grpoper_file_path);

		if ((file_id = fopen_oss(ac_grpoper_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_grpoper_file_path );
		}
		else
		{
			fprintf(file_id, "op_group;op_code\n");

			if (!(err = MBE_FILE_SETKEY_(s_mbe_id, "", 0, 0, 0)))
			{
				while (!(err = MBE_READX(s_mbe_id, (char *)&grpoper_rec, sizeof(grpoper_rec))))
				{
					count++;

					sprintf(ac_tmp, "%.64s", grpoper_rec.gr_op);
					TrimString(ac_tmp);
					strcpy(ac_print, ac_tmp);
					sprintf(ac_tmp, ";%.10s\n", grpoper_rec.cod_op);
					TrimString(ac_tmp);
					strcat(ac_print, ac_tmp);

					if ((err = fprintf(file_id, ac_print)) < 0)
					{
						log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
						Stop = 1;
						break;
					}
				}
				if (err != 1)
				{
					log(LOG_INFO, "error [%d] reading %s", err, ac_grpoper_mbe_path);
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", err, ac_grpoper_mbe_path);
			}
		}
	}

	if (!Stop) log(LOG_WARNING, "Dumping %s completed (%d records).", ac_grpoper_mbe_path, count);
	else
	{
		log(LOG_ERROR, "Dumping %s failed.", ac_grpoper_mbe_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	fclose(file_id);
*/

	// STEERING
	if (!(Stop = mbeFileOpen(ac_steering_mbe_path, &s_mbe_id)))
	{
		count = 0;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_steering_file_path, "%s%04d%02d%02d", ac_steering_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping %s into %s...", ac_steering_mbe_path, ac_steering_file_path);

		if ((file_id = fopen_oss(ac_steering_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_steering_file_path );
		}
		else
		{
			fprintf(file_id,"%c%c%c", 0xEF, 0xBB, 0xBF);	// UTF-8 BOM for Excel
			//fprintf(file_id, "cc_group;op_group;from;to;days;user_type_bitmask;state;threshold\n");
			fprintf(file_id, "cc_group;op_group;from;to;days;status;weight;politic;threshold\n");

			if (!(err = MBE_FILE_SETKEY_(s_mbe_id, "", 0, 0, 0)))
			{
				memset(ac_strules_rec_ignored, '*', TS_STRULES_KEYLEN);

				while (!(err = MBE_READLOCKX(s_mbe_id, (char *)&steering_rec, sizeof(steering_rec))))
				{
					if (memcmp(steering_rec.gr_pa, ac_strules_rec_ignored, TS_STRULES_KEYLEN))
					{
						//if (steering_rec.stato != 0x30)
						{
							count++;

							// Minuscolo gg non attivo, Maiusculo gg attivo
							strcpy(acGiorni, "mtwtfss");
							if( steering_rec.gg_settimana[1] == 'X' )
								acGiorni[0] = 'M';
							if( steering_rec.gg_settimana[2] == 'X' )
								acGiorni[1] = 'T';
							if( steering_rec.gg_settimana[3] == 'X' )
								acGiorni[2] = 'W';
							if( steering_rec.gg_settimana[4] == 'X' )
								acGiorni[3] = 'T';
							if( steering_rec.gg_settimana[5] == 'X' )
								acGiorni[4] = 'F';
							if( steering_rec.gg_settimana[6] == 'X' )
								acGiorni[5] = 'S';
							if( steering_rec.gg_settimana[0] == 'X' )
								acGiorni[6] = 'S';

							sprintf(ac_tmp, "%.64s", steering_rec.gr_pa);
							TrimString(ac_tmp);
							strcpy(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.64s", steering_rec.gr_op);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.5s", steering_rec.fascia_da);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.5s", steering_rec.fascia_a);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", acGiorni);
							strcat(ac_print, ac_tmp);
							memcpy((char *)&user_type_bitmask, steering_rec.user_type, 4);
							//sprintf(ac_tmp, ";%08X", user_type_bitmask);
							//strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", (steering_rec.stato == 0x31)?"On":"Off");
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%d", (steering_rec.peso != 0x20)?steering_rec.peso:0);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%d", steering_rec.politica);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%d\n", steering_rec.soglia);
							strcat(ac_print, ac_tmp);

							if ((err = fprintf(file_id, ac_print)) < 0)
							{
								log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
								Stop = 1;
								break;
							}
						}

						// reset counters 20/12/04
						if (s_reset_counters)
						{
							steering_rec.tot_accP[0] = 0;
							steering_rec.tot_accP[1] = 0;
							steering_rec.tot_accT[0] = 0;
							steering_rec.tot_accT[1] = 0;

							if (err = MBE_WRITEUPDATEUNLOCKX(s_mbe_id, (char *)&steering_rec, sizeof(steering_rec)))
							{
								log(LOG_INFO, "error [%d] updating %s", err, ac_steering_mbe_path);
								MBE_UNLOCKREC(s_mbe_id);
							}
						}
						else
						{
							MBE_UNLOCKREC(s_mbe_id);
						}
					}
					else
					{
						MBE_UNLOCKREC(s_mbe_id);
					}
				}
				if (err != 1)
				{
					log(LOG_INFO, "error [%d] reading %s", err, ac_steering_mbe_path);
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", err, ac_steering_mbe_path);
			}
		}
	}

	if (!Stop) log(LOG_WARNING, "Dumping %s completed (%d records).", ac_steering_mbe_path, count);
	else
	{
		log(LOG_ERROR, "Dumping %s failed.", ac_steering_mbe_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	fclose(file_id);

	// PRE-STEERING
	if (!(Stop = mbeFileOpen(ac_presteering_mbe_path, &s_mbe_id)))
	{
		count = 0;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_presteering_file_path, "%s%04d%02d%02d", ac_presteering_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping %s into %s...", ac_presteering_mbe_path, ac_presteering_file_path);

		if ((file_id = fopen_oss(ac_presteering_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_presteering_file_path );
		}
		else
		{
			fprintf(file_id,"%c%c%c", 0xEF, 0xBB, 0xBF);	// UTF-8 BOM for Excel
			fprintf(file_id,"hlr;country_code;country_name;op_code;gt;from;to;days;imsi_wl;status;map_errcode;lte_errcode\n");

			if (!(err = MBE_FILE_SETKEY_(s_mbe_id, "", 0, 0, 0)))
			{
				memset(ac_psrules_rec_ignored, '*', TS_PSRULES_KEYLEN);

				while (!(err = MBE_READLOCKX(s_mbe_id, (char *)&presteering_rec, sizeof(presteering_rec))))
				{
					if (memcmp((char *)&presteering_rec, ac_psrules_rec_ignored, TS_PSRULES_KEYLEN))
					{
						//if (presteering_rec.stato != 0x30)
						{
							count++;

							// Minuscolo gg non attivo, Maiusculo gg attivo
							strcpy(acGiorni, "mtwtfss");
							if( presteering_rec.gg_settimana[1] == 'X' )
								acGiorni[0] = 'M';
							if( presteering_rec.gg_settimana[2] == 'X' )
								acGiorni[1] = 'T';
							if( presteering_rec.gg_settimana[3] == 'X' )
								acGiorni[2] = 'W';
							if( presteering_rec.gg_settimana[4] == 'X' )
								acGiorni[3] = 'T';
							if( presteering_rec.gg_settimana[5] == 'X' )
								acGiorni[4] = 'F';
							if( presteering_rec.gg_settimana[6] == 'X' )
								acGiorni[5] = 'S';
							if( presteering_rec.gg_settimana[0] == 'X' )
								acGiorni[6] = 'S';

							memset(acCC, 0x00, sizeof(acCC));
							memcpy(acCC, presteering_rec.paese, sizeof(presteering_rec.paese));
							TrimString(acCC);
							ptrPaese= avlFind(country_list, acCC);

							sprintf(ac_tmp, "%d-%d", (presteering_rec.pcf==0x2020)?0:presteering_rec.pcf, (presteering_rec.pc==0x2020)?0:presteering_rec.pc);
							strcpy(ac_print, ac_tmp);
							sprintf(ac_tmp, " %.8s", presteering_rec.descr);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", acCC);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", (ptrPaese != NULL)?ptrPaese:" ");
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.10s", presteering_rec.cod_op);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.5s", presteering_rec.fascia_da);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%.5s", presteering_rec.fascia_a);
							TrimString(ac_tmp);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", acGiorni);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", (presteering_rec.imsi_white_list_enabled == 0x31)?"Yes":"No");
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%s", (presteering_rec.stato == 0x31)?"On":"Off");
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%d", presteering_rec.map_reject_code);
							strcat(ac_print, ac_tmp);
							sprintf(ac_tmp, ";%d\n", presteering_rec.lte_reject_code);
							strcat(ac_print, ac_tmp);

							if ((err = fprintf(file_id, ac_print)) < 0)
							{
								log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
								Stop = 1;
								break;
							}
						}

						MBE_UNLOCKREC(s_mbe_id);
					}
					else
					{
						MBE_UNLOCKREC(s_mbe_id);
					}
				}
				if (err != 1)
				{
					log(LOG_INFO, "error [%d] reading %s", err, ac_presteering_mbe_path);
				}
			}
			else
			{
				log(LOG_ERROR, "error [%d] seeking %s", err, ac_presteering_mbe_path);
			}
		}
	}

	if (!Stop) log(LOG_WARNING, "Dumping %s completed (%d records).", ac_presteering_mbe_path, count);
	else
	{
		log(LOG_ERROR, "Dumping %s failed.", ac_presteering_mbe_path);
	}

	MBE_FILE_CLOSE_(s_mbe_id);
	fclose(file_id);

	// --------- 2018 KTSTEA10_ADU ---------------------
	// Interactim PPLMN
	memset((char *)&mconf, 0x00, sizeof(t_interac_mconf));

	EXEC SQL
		DECLARE  mconf_cursor CURSOR FOR
			SELECT itemid, content
			FROM =MCONFDB
			WHERE contentid = 1 AND itemid > 0
			browse access;

	Stop = 0;
	if (sqlcode == SQL_OK)
	{
		count = 0;
		sMaxOp = N_PREFERRED;

		INTERPRETTIMESTAMP(JULIANTIMESTAMP()+7200000000, dateNtime);
		sprintf(ac_pplmn_file_path, "%s%04d%02d%02d", ac_pplmn_file_path, dateNtime[0], dateNtime[1], dateNtime[2]);
		log(LOG_WARNING, "Dumping MCONFDB into %s...", ac_pplmn_file_path);

		if ((file_id = fopen_oss(ac_pplmn_file_path, "wb")) == NULL)
		{
			log(LOG_ERROR, "error opening %s", ac_pplmn_file_path );
		}
		else
		{
			// intestazione file output
			fprintf(file_id,"%c%c%c", 0xEF, 0xBB, 0xBF);	// UTF-8 BOM for Excel
			fprintf(file_id,"ID|<mccmnc> list\n");

			exec sql open mconf_cursor;
			log(LOG_DEBUG, "SQL open cursor [%d] MCONFDB", sqlcode);

			do
			{
				exec sql
					fetch mconf_cursor
					into :mconf.itemid, :mconf.content;

				if (sqlcode == SQL_OK)
				{
					count++;
					memset(ac_print, 0x00, sizeof(ac_print));

					sprintf(ac_print, "%d|", mconf.itemid);
					for (i=0; i < sMaxOp; i++)
					{
						memset(encOpImsi, 0x00, sizeof(encOpImsi));
						memset(sTmp, 0x00, sizeof(sTmp));

						strncpy(sTmp, mconf.content.val, mconf.content.len);
						strncpy(encOpImsi, sTmp + (i*6) + 2, 6);
						err = decodeOpImsi(encOpImsi, opImsi);
						if (err != 0)
							break;

						strcat(ac_print, opImsi);
						strcat(ac_print, ";");
					} //fine for

					strcat(ac_print, "\n");
					if ((err = fprintf(file_id, ac_print)) < 0)
					{
						log(LOG_ERROR, "fprintf error [%d] at record %d", err, count);
						Stop = 1;
						break;
					}
				}
				else
				{
					if  (sqlcode != SQL_NOT_FOUND)
					{
						log(LOG_ERROR, "SQL error [%d] MCONFDB", sqlcode);
						Stop = 1;
					}
				}

			} while (sqlcode == SQL_OK);

			exec sql close mconf_cursor;
		}
	}
	else
		Stop = 1;

	if (!Stop)
		log(LOG_WARNING, "Dumping MCONFDB completed (%d records).", count);
	else
	{
		log(LOG_ERROR, "Dumping MCONFDB failed.");
	}
	fclose(file_id);

	// ------------------------------------------------------

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
	get_profile_string(pc_ini_file, "DUMP", "EMS-APPL", &found, ac_ems_appl);
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
	get_profile_string(pc_ini_file, "DUMP", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_num_days_of_log = atoi(ac_wrk_str);
	}

	i_trace_level = LOG_INFO;
	get_profile_string(pc_ini_file, "DUMP", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_trace_level = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_trace_level = atoi(ac_wrk_str);
	}

	i_log_options = 7;
	get_profile_string(pc_ini_file, "DUMP", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE) i_log_options = (short)atoi(ac_wrk_str);
	else
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
		if (found == SSP_TRUE) i_log_options = atoi(ac_wrk_str);
	}

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_my_process_name + 1, i_num_days_of_log);
	log_param(i_trace_level, i_log_options, "");

	/* --- DUMP ------------------------------------------------------------ */
	get_profile_string(pc_ini_file, "DUMP", "OPER-FILE-PATH", &found, ac_oper_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> OPER-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
/*
	get_profile_string(pc_ini_file, "DUMP", "OPERGRP-FILE-PATH", &found, ac_grpoper_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> OPERGRP-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
*/
	get_profile_string(pc_ini_file, "DUMP", "COUNTRIES-FILE-PATH", &found, ac_paesi_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> COUNTRIES-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "DUMP", "THRESHOLDS-FILE-PATH", &found, ac_steering_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> PSRULES-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "DUMP", "PSRULES-FILE-PATH", &found, ac_presteering_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> PSRULES-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}
	//2018 KTSTEADU
	get_profile_string(pc_ini_file, "DUMP", "INT-PPLMN-FILE-PATH", &found, ac_pplmn_file_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter DUMP -> INT-PPLMN-FILE-PATH");
		DELAY (EXIT_DELAY);
		exit(0);
	}

	s_reset_counters = 1;
	get_profile_string(pc_ini_file, "DUMP", "RESET-COUNTERS", &found, ac_wrk_str);
	if (found == SSP_TRUE) s_reset_counters = (short)atoi(ac_wrk_str);

	/* --- GENERIC --------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPER-PATH", &found, ac_oper_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPER-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPERGT-PATH", &found, ac_opergt_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPERGT-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
/*
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPERGRP-PATH", &found, ac_grpoper_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPERGRP-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
*/
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-COUNTRIES-PATH", &found, ac_paesi_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-COUNTRIES-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, ac_steering_mbe_path);
	if (found == SSP_FALSE) 
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-PSRULES-PATH", &found, ac_presteering_mbe_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-PSRULES-PATH");
		DELAY(EXIT_DELAY);
		exit(0);
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
	log(LOG_WARNING, "\tDB-LOC-COUNTRIES-PATH .....: %s", ac_paesi_mbe_path);
	log(LOG_WARNING, "\tDB-LOC-OPER-PATH ..........: %s", ac_oper_mbe_path);
	log(LOG_WARNING, "\tDB-LOC-OPERGT-PATH ........: %s", ac_opergt_mbe_path);
//	log(LOG_WARNING, "\tDB-LOC-OPERGRP-PATH .......: %s", ac_grpoper_mbe_path);
	log(LOG_WARNING, "\tDB-LOC-THRESHOLDS-PATH ....: %s", ac_steering_mbe_path);
	log(LOG_WARNING, "\tDB-LOC-PSRULES-PATH .......: %s", ac_presteering_mbe_path);

	log(LOG_WARNING, "[DUMP]");
	log(LOG_WARNING, "\tOPER-FILE-PATH ............: %s", ac_oper_file_path);
//	log(LOG_WARNING, "\tOPERGRP-FILE-PATH .........: %s", ac_grpoper_file_path);
	log(LOG_WARNING, "\tCOUNTRIES-FILE-PATH .......: %s", ac_paesi_file_path);
	log(LOG_WARNING, "\tTHRESHOLDS-FILE-PATH ......: %s", ac_steering_file_path);
	log(LOG_WARNING, "\tPSRULES-FILE-PATH .........: %s", ac_presteering_file_path);
	log(LOG_WARNING, "\tINT-PPLMN-FILE-PATH .......: %s", ac_pplmn_file_path);
	log(LOG_WARNING, "\tRESET-COUNTERS ............: %d", s_reset_counters);
	log(LOG_WARNING, "#==============================================================================");
}

short mbeFileOpen(char *filename, short *fileid)
{
	short	ret = 0;
	short	err;

	if (err = MBE_FILE_OPEN_(filename, (short)strlen(filename), fileid))
	{
		log(LOG_ERROR, "error [%d] opening file %s", err, filename);
		//log_evt(SSPEVT_CRITICAL, SSPEVT_ACTION, EMS_EVT_MBE_ERROR, "error %d opening file %s", err, filename);
		ret++;
	}
	else
	{
		log(LOG_WARNING, "opened file %s - id %d", filename, *fileid);
	}

	return ret;
}

short decodeOpImsi(char *encOpImsi, char *res)
{
	memset(res, 0x00, 16);

	if (!strncmp (encOpImsi, "FFFF", 4))
	{
        return -1;
	}

    res[0] = encOpImsi[1];
	res[1] = encOpImsi[0];
	res[2] = encOpImsi[3];
	res[3] = encOpImsi[5];
	res[4] = encOpImsi[4];

    if (encOpImsi[2] != 'F')
		res[5] = encOpImsi[2];

    return 0;
}
