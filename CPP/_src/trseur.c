// ----------------------------------------------------------------------------
//  PROJECT :
// ----------------------------------------------------------------------------
//
//  File Name   : treur.c
//  Last Change : 15/03/2016
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
// ---------------------< Include files >---------------------------------------

#if (_TNS_E_TARGET)
T0000H06_21JUN2018_KTSTEA10_01() {};
#elif (_TNS_X_TARGET)
T0000L16_21JUN2018_KTSTEA10_01() {};
#endif

#include <stdio.h>
#include <strings.h>
#include <stdlib.h>
#include <cextdecs.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>
#include <sys\stat.h>
#include <assert.h>
#include <sspdefs.h>
#include <sspstat.h>
#include <ssplog.h>
#include <sspevt.h>
#include <sspfunc.h>
#include <mbedb.h>

#include <defs.h>
#include <core.h>
#include <iqelem.h>
#include <roamun.h>
#include <treur.h>
// ---------------------< External Function Prototypes >----------------------
// ---------------------< Internal Function Prototypes >----------------------
short LoadParameters(short i_reload);
short HandleReceiveMSG(char *data, unsigned short len,short i_info_rec);
void InitProgram(void);
void CloseProgram(void);
void OpenDB(void);
short HandleTimeout(IO_SYSMSG_TIMEOUT *signal);
short SetEnv(void);
short ReadRoamEuqQueue(void);
short RxMsgPathmon(short *fdes,short rcv_cnt,long l_tag);
short CheckErrPathmon(short *fdes, short rc, long l_tag);
short SendToGwHTTPS(t_ts_if4_record  *t_tfs_record, char *imsi);
short SendArpRequest(ELEM *elem);
char *ModifyRecord(void *a, short *i_len);
char *DeleteRecord(void *a, short *i_len);
void UpdateDB(ELEM *elem,F_PROT *OperRec);
// ---------------------------------------------------------------------------
void *handleReceiveMSG = HandleReceiveMSG; // per funzione che riceve da $RECEIVE
void *handleMoreTM = HandleTimeout;
void *setEnv = SetEnv;
// ---------------------------------------------------------------------------

int main(int ac, char **av)
{
	// Initialize the process
	PROCESS_INITIALIZATION(LoadParameters);
	PrintStarted();

	InitProgram();

	PROCESS_START(0);

	PrintStopped();

	CloseProgram();

	return 0;
}

void OpenDB()
{
	short err = 0,i;

	for(i=0;dbnames[i];i++)
	{
		err = MbeFileOpen_nw(dbnames[i]->path,&dbnames[i]->fnum);
		if(err != 0)
		{
			LOG((void*)LOG_ERROR,"Err <%d> MBE_FILE_OPEN_ (%s)",err,dbnames[i]->path);
			LOG_EVT(SSPEVT_NORMAL, SSPEVT_NOACTION,(short)(i_evt_number_start+EMS_ERR_OPEN_DB),
					EMS_T_ERR_OPEN_DB,ac_my_process_name,err,dbnames[i]->path);
			EXIT(0);
		}
	}
}

void InitProgram()
{
	OpenDB();

	SETTIMEOUT((void*)i_readque_timeout,0,TAG_READ_QUE);
	SETTIMEOUT((void*)(i_timeout_check_elem * 50),0,TAG_CHECK_ELEM);

	ADDHANDLEDESCRIPTOR(RxMsgPathmon);
	ADDERRORDESCRIPTOR(CheckErrPathmon);

	Core_SetAllElemMemLenData(1024 * kbytes_len_buf);
}

void CloseProgram(void)
{
	BumpStat();
	log_close();
}

short HandleReceiveMSG(char *data,unsigned short len,short i_info_rec)
{
	short	msg_id;
	short	ret = 0;
	char	*buf="";

	// Leggo lo short che identifica il tipo di Msg.
	memcpy((char *)&msg_id,data,sizeof(short));

	switch(msg_id)
	{
		default:
		{
			LOG((void*)LOG_INFO,"unexpected message <%d:%.50s>",msg_id,data+2);
			REPLY_MSG(buf,strlen(buf));
		}
	}

	return ret;
}

char *DeleteRecord(void *a, short *i_len)
{
	*i_len = 0;
	return (char*)a;
}

char *ModifyRecord(void *a, short *i_len)
{
	t_ts_if4_record	*t_if4_record = (t_ts_if4_record*) a;

	t_if4_record->c_retry++;

	if(t_if4_record->c_retry  <= i_retry_max){
		t_if4_record->jts = JULIANTIMESTAMP(0);
		*i_len = sizeof(t_ts_if4_record);
	}else{
		LOG((void*)LOG_WARNING,"reached max retry <%d>",t_if4_record->c_retry);
		*i_len = 0;
	}

	return (char*)a;
}

void UpdateDB(ELEM *elem,F_PROT *OperRec)
{
	short			i_len_rec_update=0,ret;
	char			*ac_text = "";
	t_ts_if4_record t_if4_record;

	if(OperRec)
	{
		memcpy(t_if4_record.imsi,elem->ac_ident,sizeof(t_if4_record.imsi));
		if(!(ret=DBReadRecord(&roameuq,(char*)&t_if4_record,sizeof(t_if4_record.imsi),
						  sizeof(t_if4_record),MBE_MODE_EXACT,MbeFileSeek,MbeFileReadL_nw)))
		{
			ret = DBInsUpdRecord(&roameuq,((char*)OperRec(&t_if4_record,&i_len_rec_update)),i_len_rec_update,'U');
		}

		if(!ret)
		{
			if(i_len_rec_update){
				ac_text = "update";
				ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Updated);
			}else{
				ac_text = "delete";
				ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Deleted);
			}
		}

		LOG((void*)LOG_INFO,"%s:%s %s record queue <%s>",
					&elem->ac_ident[LEN_MS],(!ret ? "" : "ERRORE"),
					ac_text,roameuq.path);
	}

	Core_freeElemMemQue(elem);
}

short DecodeResponse(char *data)
{
	short ret = 0;

	if(!(ret=(short)strcasecmp(data,"result=ok")) || !(ret=(short)strcasecmp(data,"result=ko"))){}

	return ret;
}

short RxMsgPathmon(short *fdes,short rcv_cnt,long l_tag)
{
	short 	ret_func = 1;
	short	i_idx = (short)(l_tag - TAG_PATHSEND);
	ELEM	*elem;
	t_psend_http_if *s_https;
	F_PROT *OperRec = NULL;

	if(*fdes == fnumPSend){
		ret_func = 0;

		elem = Core_findElemMemoryQuebyIdx(i_idx);
		if(elem){
			elem->data[rcv_cnt] = 0;
			s_https = (t_psend_http_if*)elem->data;
			switch(s_https->i_http_code)
			{
				case 0:
				{
					LOG((void*)LOG_INFO,"%s:RX reply id <%s> from WEB SERVICE, %s",
										&elem->ac_ident[LEN_MS],
										&elem->ac_ident[LEN_MS*2],
										&s_https->data[strlen(s_https->data)+1]);

					if(strcmp(&s_https->data[strlen(s_https->data)+1],"SESSION_EXPIRED")){
						OperRec = (F_PROT*)DeleteRecord;
					}

					ADDSTAT(&s_https->data[strlen(s_https->data)+1],ac_my_process_name,STAT_Record_Reply);

					break;
				}
				case 200:
					ADDSTAT(stat_registry_HTTP_200,ac_my_process_name,STAT_Record_Reply);
				case 500:
				{
					LOG((void*)LOG_INFO,"%s:RX %s reply id <%s> from WEB SERVICE",
										&elem->ac_ident[LEN_MS],
										s_https->data,
										&elem->ac_ident[LEN_MS*2]);
					if(!DecodeResponse(s_https->data)){
						OperRec = (F_PROT*)DeleteRecord;
					}else{
						OperRec = (F_PROT*)ModifyRecord;
					}
					break;
				}
				default:
					sprintf(ac_reg_stat,"HTTP_%d_KO",s_https->i_http_code);
					ADDSTAT(ac_reg_stat,ac_my_process_name,STAT_Record_Reply);

					LOG((void*)LOG_INFO,"%s:RX error, http code <%d> id <%s> from WEB SERVICE",
										&elem->ac_ident[LEN_MS],
										s_https->i_http_code,
										&elem->ac_ident[LEN_MS*2]);

					OperRec = (F_PROT*)DeleteRecord;
			}

			UpdateDB(elem,OperRec);
		}else{
			LOG((void*)LOG_WARNING,"unexpected message bytes <%d> tag <%d>",rcv_cnt,l_tag);
		}
	}

	return ret_func;
}

short CheckErrPathmon(short *fdes,short rc,long l_tag)
{
	short	ret_func = 1;
	short	p_err=0,fs_err=0;
	short	i_idx = (short)(l_tag - TAG_PATHSEND);
	ELEM	*elem;

	if(*fdes == fnumPSend){
		ret_func = 0;

		Core_PATHSEND_info(&p_err, &fs_err);
		LOG((void*)LOG_ERROR,EMS_T_ERR_PSEND,p_err,fs_err,
					ac_global_pathmon_name,ac_global_serverclass_name);
		CHECKEVT((void*)SSPEVT_CRITICAL,SSPEVT_NOACTION,i_evt_number_start+EMS_ERR_PSEND,
				ll_evt_interval,EMS_T_ERR_PSEND,p_err,fs_err,
				ac_global_pathmon_name,ac_global_serverclass_name);

		sprintf(ac_reg_stat,"Err<%d:%d>",p_err,fs_err);
		ADDSTAT(ac_reg_stat,ac_my_process_name,STAT_Record_Reply);

		elem = Core_findElemMemoryQuebyIdx(i_idx);
		if(elem){
			F_PROT *OperRec = NULL;
			LOG((void*)LOG_WARNING,"%s: pathsend error [%d-%d] sending to WEB SERVICE id <%s>",
					&elem->ac_ident[LEN_MS],p_err,fs_err,
					&elem->ac_ident[LEN_MS*2]);
			if(p_err == 40){
				OperRec = (F_PROT*)ModifyRecord;
			}
			UpdateDB(elem,OperRec);
		}else{
			LOG((void*)LOG_WARNING,"unexpected message tag <%d>",l_tag);
		}
	}

	return ret_func;
}

short ReadRoamEuqQueue(void)
{
	short ret = 0;
	t_ts_if4_record t_if4_record;
	char ac_imsi_right[LEN_MS];
	long long curr_ts = JULIANTIMESTAMP(0);
	char c_loop = SSP_TRUE;
static	F_GEN *f_seek = MbeFileSeek;

	memset(ac_imsi_right,0,sizeof(ac_imsi_right));
	memset(&t_if4_record,' ',sizeof(t_if4_record));
	memcpy(t_if4_record.imsi,ac_range,2);

	while(c_loop && !((ret=DBReadRecord(&roameuq,(char*)&t_if4_record,sizeof(t_if4_record.imsi),
									 sizeof(t_ts_if4_record),MBE_MODE_APPROXIMATE,f_seek))))
	{
		f_seek = (F_GEN*)Func_wrap;

		if(memcmp(t_if4_record.imsi,&ac_range[3],2) <= 0 && (!t_if4_record.c_retry ||
			(t_if4_record.c_retry && (curr_ts-t_if4_record.jts)/1000000 > i_retry_delay)))
		{
			ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Read);
			c_loop = SSP_FALSE;

			memcpy(ac_imsi_right,t_if4_record.imsi,LEN_MS);
			Core_TrimStringRx(ac_imsi_right,LEN_MS);
			Core_ReverseStr(ac_imsi_right,(short)strlen(ac_imsi_right));
			Core_TrimStringRx(t_if4_record.msisdn,sizeof(t_if4_record.msisdn));

			log(LOG_INFO,"%s|%s processing record",ac_imsi_right,t_if4_record.msisdn);

			SendToGwHTTPS(&t_if4_record,ac_imsi_right);
		}
	}


	if(ret == MBE_EOF){
		f_seek = MbeFileSeek;
		ret = QUEUE_EOF;
	}

	return ret;
}

short SendArpRequest(ELEM *elem)
{
	short ret=0, i_len_back;
	t_psend_http_if *s_https;

	s_https = (t_psend_http_if*)elem->data;
	s_https->i_http_code = 1000;

	elem->i_len = (short)(sizeof(s_https->i_http_code) + strlen(s_https->data));

	if(i_trace_level == LOG_DEBUG){
		//log_msg(LOG_WARNING,"title",s_https->data,(int)strlen(s_https->data));
		Core_DumpMessage(s_https->data);
	}

	ret = Core_PATHSEND_call(ac_global_pathmon_name,ac_global_serverclass_name,
							elem->data,(short)elem->i_len,(short)elem->i_len_data,
							&i_len_back,TAG_PATHSEND + elem->i_idx);
	if(!ret){
		ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_IsProcessing);
		LOG((void*)LOG_INFO,"%s:TX request <%s> to WEB SERVICE",
					&elem->ac_ident[LEN_MS],&elem->ac_ident[LEN_MS*2]);
	}else{
		short	p_err = 0,fs_err = 0;

		Core_PATHSEND_info(&p_err,&fs_err);
		LOG((void*)LOG_ERROR,EMS_T_ERR_PSEND,p_err,fs_err,
					ac_global_pathmon_name,ac_global_serverclass_name);
		CHECKEVT((void*)SSPEVT_CRITICAL,SSPEVT_NOACTION,i_evt_number_start+EMS_ERR_PSEND,
				ll_evt_interval,EMS_T_ERR_PSEND,p_err,fs_err,
				ac_global_pathmon_name,ac_global_serverclass_name);

		Core_freeElemMemQue(elem);

		sprintf(ac_reg_stat,"Err<%d:%d>",p_err,fs_err);
		ADDSTAT(ac_reg_stat,ac_my_process_name,STAT_Record_Reply);
	}

	return ret;
}

short CreateArpPostMsg(char *buffer,char *ac_imsi,t_ts_if4_record *t_if4_record,char *ac_transid)
{
	short ret = 0;
	short time_p[8];
static unsigned short i_trans_id;
	char date_time[20];

	sprintf(ac_transid,"ARP%.5d",i_trans_id++);

    INTERPRETTIMESTAMP(t_if4_record->jts,time_p);

    sprintf(date_time,"%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d",
    			time_p[0],time_p[1],time_p[2],
    			time_p[3],time_p[4],time_p[5]);

    if(t_if4_record->mccmnc[5]==' '){
    	t_if4_record->mccmnc[5] = 0;
    }

	sprintf(buffer,"address=%s&subscriberId=%s&currentRoaming=%c&servingMccMnc=%.6s"
					"&roamingInfoChanged=%c&retrievalTime=%s",
					t_if4_record->msisdn,ac_imsi,'0'+t_if4_record->roamingStatus,t_if4_record->mccmnc,
					'0'+t_if4_record->roamingChanged,date_time);

	return ret;
}

short SendToGwHTTPS(t_ts_if4_record *t_if4_record,char *imsi_right)
{
	short ret = 0;
	ELEM *elem;
	t_psend_http_if *s_https;

	if(!Core_findElemMemoryQue(t_if4_record->imsi,LEN_MS))
	{
		elem = Core_insElemMemory(t_if4_record->imsi,LEN_MS);
		if(elem){
			memcpy(&elem->ac_ident[LEN_MS],imsi_right,strlen(imsi_right));

			s_https = (t_psend_http_if*)elem->data;
			s_https->i_http_code = 1000;

			*s_https->data = 0;
			ret = CreateArpPostMsg(s_https->data,imsi_right,t_if4_record,&elem->ac_ident[LEN_MS*2]);
			if(!ret){
				ret = SendArpRequest(elem);
			}else{
				// free elem
				Core_freeElemMemQue(elem);
			}
		}else{
			LOG((void*)LOG_ERROR,"%s:errore memory allocation",ac_my_process_name);
			ret = 1;
		}
	}else{
		LOG((void*)LOG_INFO,"%s:is still processing",imsi_right);
		ret = 1;
		ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_IsWaiting);
	}

	return ret;
}

short HandleTimeout(IO_SYSMSG_TIMEOUT *signal_p)
{
	short ret = 0;
	IO_SYSMSG_TIMEOUT signal = *signal_p;

	if(signal.id == SYS_MSG_TIME_TIMEOUT)
	{
		switch(signal.l_par)
		{
			case TAG_READ_QUE:
			{
				ret = ReadRoamEuqQueue();
				if(ret == QUEUE_EOF){
					SETTIMEOUT((void*)i_readque_timeout,0,TAG_READ_QUE);
				}else{
					SETTIMEOUT((void*)i_readque_next_rec_timeout,0,TAG_READ_QUE);
				}

				break;
			}
			case TAG_CHECK_ELEM:
			{
				Core_cleanExpiredTime(i_timeout_check_elem,ELEM_BUSY);
				SETTIMEOUT((void*)(i_timeout_check_elem * 50),0,TAG_CHECK_ELEM);

				break;
			}
			default:
				ret = 1;
		}
	}

	return ret;
}

short GetRange(char *ac_value)
{
	short rate = 0;
	char *pc,*pc2,*start = ac_value;

	if((pc=strstr(ac_value,ac_my_process_name))){
		pc += strlen(ac_my_process_name)+1;
		memcpy(ac_range,pc,sizeof(ac_range));

		strcat(ac_value,"|");
		while((pc=strchr(start,'|'))){
			*pc=0;
			pc2 = strchr(start,':');
			if(pc2){
				start = pc2 + 1;
				pc2 = strchr(start,':');
				if(pc2){
					*pc2 = 0;
					rate += (short)(atoi(pc2+1)- atoi(start)+1);
				}
			}

			start = pc +1;
		}
	}

	return rate;
}

short SetEnv()
{
	params.par[params.i_num_par].name=&pc_ini_file;
	params.par[params.i_num_par++].value="INIFILE";

	params.par[params.i_num_par].name=&pc_ini_section_name;
	params.par[params.i_num_par]._default="EURIF4";
	params.par[params.i_num_par++].value="SECTION";

	return 0;
}
/*****************************************************************************
**  Module Name: LoadParameters												**
**																			**
**  Load parameters function. Load INI file									**
**																			**
*****************************************************************************/
short LoadParameters(short i_reload)
{
	short	ret = SSP_SUCCESS,rate = 0;
	int		found = 0;
	char	ac_value[100];
	char	ac_pref_log[10];				//prefisso file stat

	if(i_reload)
	{
		// ---------------------------------------------------------------------
		// Se è reload param verifico se è possibile recuperare il parametri
		// leggendo un parametro obbligatorio
		// --------------------------------------------------------------------
		if(get_profile_string(pc_ini_file,pc_ini_section_name,"LOG-PATH",&found,ac_value) != 0){
			LOG((void*)LOG_ERROR, "Error reading file ini - opened? - keeps previuos parameters");
			return 1;
		}else{
			LOG((void*)LOG_INFO,"Reload parameters");
		}
	}

	// ===========================================================================
	// EMS
	// ===========================================================================
	if(!i_reload)
	{
		get_profile_string(pc_ini_file,pc_ini_section_name,"EMS-DISABLE",&found,ac_value);
		if(found == SSP_FALSE)
		{
			get_profile_string(pc_ini_file, "EMS", "EMS-OWNER", &found, ac_ems_owner);
			EXIT(found);

			get_profile_string(pc_ini_file, "EMS", "EMS-VERSION", &found, ac_ems_version);
			EXIT(found);

			get_profile_string(pc_ini_file, "EMS", "EMS-SUBSYSTEM", &found, ac_value);
			if(found == SSP_TRUE) s_ems_subsystem = (short)atoi(ac_value);
			EXIT(found);

			get_profile_string(pc_ini_file,pc_ini_section_name,"EMS-APPL", &found, ac_ems_appl);
			EXIT(found);

			ll_evt_interval = 5000000;
			get_profile_string(pc_ini_file, "EMS", "EMS-EVT-INTERVAL", &found, ac_value);
			if (found == SSP_TRUE) ll_evt_interval = (long long)(atoi(ac_value) * 1000000);

			// Init EMS
			ret = sspevt_init(ac_ems_appl,ac_ems_owner,s_ems_subsystem,ac_ems_version);
			EXIT(!ret);
		}else{
			_log_evt = NULL;
		}
	}

	//////////////////////////////////////////////////////////////////////
	// LOG
	//////////////////////////////////////////////////////////////////////
	if(i_reload>=0 && !ret)
	{
		get_profile_string(pc_ini_file,pc_ini_section_name,"LOG-LEVEL",&found,ac_value);
		if(found == SSP_TRUE) i_trace_level = (short)atoi(ac_value);
		else
		{
			get_profile_string(pc_ini_file,"LOG","LOG-LEVEL",&found,ac_value);
			if(found == SSP_TRUE) i_trace_level = (short)atoi(ac_value);
			else i_trace_level = LOG_INFO;
		}
		get_profile_string(pc_ini_file,pc_ini_section_name,"LOG-OPTIONS",&found,ac_value );
		if(found == SSP_TRUE) i_options = abs((short)atoi(ac_value));
		else
		{
			get_profile_string(pc_ini_file,"LOG","LOG-OPTIONS",&found,ac_value );
			if(found == SSP_TRUE) i_options = abs((short)atoi(ac_value));
			else i_options = LOG_STAT; // bufferizzato
		}

		if(i_options < LOG_PRINT_DATE || i_options > LOG_UNBUFFERED){
			i_options = LOG_STAT;
		}
		log_param(i_trace_level,i_options,"");

		ac_log_trace_string[0] = 0;
		get_profile_string(pc_ini_file,"LOG","LOG-TRACE",&found,ac_log_trace_string);
		if(ac_log_trace_string[0]){
			log_set_trace(ac_log_trace_string);
		}else{
			log_reset_trace();
		}
	}

	if(!i_reload && !ret)
	{
		memset(ac_value, 0x00,sizeof(ac_value));
		get_profile_string(pc_ini_file,"LOG","LOG-PATH",&found,ac_value);
		if(found == SSP_TRUE) strncpy(ac_path_log_file,ac_value,sizeof(ac_path_log_file)-1);
		else
		{
			PrintParamMissing("LOG","LOG-PATH");
			EXIT(found);
		}

		get_profile_string( pc_ini_file,"LOG","LOG-DAYS",&found,ac_value );
		if(found == SSP_TRUE) i_num_days_of_log = abs((short)atoi (ac_value));
		else i_num_days_of_log = 2; // 2 days

		get_profile_string( pc_ini_file,pc_ini_section_name,"LOG-PREFIX",&found,ac_value );
		if(found == SSP_TRUE) strncpy(ac_pref_log,ac_value,sizeof(ac_pref_log)-1);
		else
		{
			get_profile_string( pc_ini_file,"LOG","LOG-PREFIX",&found,ac_value );
			if(found == SSP_TRUE) strncpy(ac_pref_log,ac_value,sizeof(ac_pref_log)-1);
			else strncpy(ac_pref_log,ac_my_process_name+1, sizeof(ac_pref_log)-1);
		}

		ret = (short)log_init(ac_path_log_file,ac_pref_log,i_num_days_of_log);
		if(ret == 0) {
			log_param(i_trace_level,i_options,"");
			log_param_filecreate (1024 /*filecreate_primary_extent_size*/,
								  1024 /*filecreate_secondary_extent_size*/,
								  1024 /*filecreate_maximum_extents */ );
			log(LOG_WARNING,"");
			log(LOG_WARNING,"----------------------------------------------------------" );
		}else{
			LOG_EVT(SSPEVT_NORMAL, SSPEVT_NOACTION,(short)(i_evt_number_start+EMS_ERR_LOG_INIT),
					EMS_T_ERR_LOG_INIT,ac_path_log_file,ret);
			EXIT(0);
		}
	}

	// ===========================================================================
	// STAT
	// ===========================================================================
	if(!i_reload)
	{
		get_profile_string(pc_ini_file,pc_ini_section_name,"STAT-DISABLE", &found, ac_value);
		if(found == SSP_FALSE)
		{
			i_stat_bump_interval = 30000;
			get_profile_string(pc_ini_file, "STAT", "STAT-BUMP-INTERVAL", &found, ac_value);
			if(found == SSP_TRUE) i_stat_bump_interval = (short)(atoi(ac_value) * 100);
			get_profile_string(pc_ini_file, "STAT", "STAT-PATH", &found, ac_path_stat_file);
			if(found == SSP_FALSE)
			{
				PrintParamMissing("STAT","STAT-PATH");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT", "STAT-PREFIX", &found, ac_stat_prefix);
			if(found == SSP_FALSE)
			{
				PrintParamMissing("STAT","STAT-PREFIX");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT", "STAT-GROUP", &found, ac_value);
			if(found == SSP_TRUE) i_stat_group = (short)atoi(ac_value);
			else
			{
				PrintParamMissing("STAT","STAT-GROUP");
				EXIT(found);
			}
			get_profile_string(pc_ini_file, "STAT", "MAX-REGS", &found, ac_value);
			if(found == SSP_TRUE) i_stat_max_registers = (short)atoi(ac_value);
			else
			{
				PrintParamMissing("STAT","MAX-REGS");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT","MAX-COUNTS", &found, ac_value);
			if (found == SSP_TRUE) i_stat_max_idx = (short)atoi(ac_value);
			else
			{
				PrintParamMissing("STAT","MAX-COUNTS");
				EXIT(found);
			}

			// Init stat
			if(!Stat_init(ac_path_stat_file,ac_stat_prefix,"",i_stat_group,i_stat_max_registers,i_stat_max_idx))
			{
				LOG((void*)LOG_ERROR,"Stat init error");
				LOG_EVT(SSPEVT_NORMAL,SSPEVT_ACTION,(short)(i_evt_number_start+EMS_ERR_STAT_INIT),EMS_T_ERR_STAT_INIT,
						ac_path_stat_file,i_stat_group,i_stat_max_registers);
				EXIT(0);
			}
		}else{
			_addstat = NULL;
		}
	}

	if(!i_reload && !ret)
	{
		get_profile_string(pc_ini_file,"GENERIC","ROAMING-EU-IF4-PATH",&found,roameuq.path);
		if(found == SSP_FALSE)
		{
			PrintParamMissing("GENERIC","ROAMING-EU-IF4-PATH");
			EXIT(found);
		}

		get_profile_string(pc_ini_file,pc_ini_section_name,"IMSI-RANGES",&found,ac_value);
		if(found == SSP_TRUE){
			rate=GetRange(ac_value);
			if(rate != 100){
				LOG((void*)LOG_ERROR,"%s %s not exactly configured",ac_my_process_name,"IMSI-RANGES");
				LOG_EVT(SSPEVT_NORMAL,SSPEVT_ACTION,(short)(i_evt_number_start+EMS_ERR_RANGE),
						"%s %s not exactly configured",ac_my_process_name,"IMSI-RANGES");
				DELAY(EXIT_DELAY);
				exit (0);
			}
		}else{
			PrintParamMissing(pc_ini_section_name,"IMSI-RANGES");
			EXIT(found);
		}

		get_profile_string(pc_ini_file,pc_ini_section_name,"SSL-GATEWAY-PATHCOM",&found,ac_global_pathmon_name);
		if(found == SSP_FALSE)
		{
			PrintParamMissing(pc_ini_section_name,"SSL-GATEWAY-PATHCOM");
			EXIT(found);
		}
		get_profile_string(pc_ini_file,pc_ini_section_name,"SSL-GATEWAY-SRV-CLS",&found,ac_global_serverclass_name);
		if(found == SSP_FALSE)
		{
			PrintParamMissing(pc_ini_section_name,"SSL-GATEWAY-SRV-CLS");
			EXIT(found);
		}
	}

	if(i_reload >= 0)
	{
		i_readque_timeout = 5 * 100;
		get_profile_string(pc_ini_file, pc_ini_section_name,"READ-QUEUE",&found,ac_value);
		if (found == SSP_TRUE) {
			i_readque_timeout = atoi(ac_value);
			if(i_readque_timeout <= 0){
				i_readque_timeout = 5 * 100;
			}
		}

		i_readque_next_rec_timeout = 100;
		get_profile_string(pc_ini_file, pc_ini_section_name,"READ-QUEUE-NEXT-REC",&found,ac_value);
		if (found == SSP_TRUE) {
			i_readque_next_rec_timeout = (short)atoi(ac_value);
			if(i_readque_next_rec_timeout <= 0){
				i_readque_next_rec_timeout = 100;
			}
		}

		i_retry_delay = 30;
		get_profile_string(pc_ini_file, pc_ini_section_name,"RETRY-DELAY",&found,ac_value);
		if (found == SSP_TRUE) i_retry_delay = (short)(atoi(ac_value));

		i_retry_max = 5;
		get_profile_string(pc_ini_file, pc_ini_section_name,"RETRY-TIMES",&found,ac_value);
		if (found == SSP_TRUE) i_retry_max = (short)(abs(atoi(ac_value)));


		get_profile_string(pc_ini_file, pc_ini_section_name,"TIMEOUT-PATHSEND",&found,ac_value);
		if (found == SSP_TRUE) {
			l_timeout_pathsend = (short)(abs(atoi(ac_value)) * 100);
		}

		i_timeout_check_elem = 300;
		get_profile_string(pc_ini_file,pc_ini_section_name,"TIMEOUT-CHECK-ELEM",&found,ac_value);
		if (found == SSP_TRUE) {
			i_timeout_check_elem = (short)(abs(atoi(ac_value)));
		}

		kbytes_len_buf = 1;
		get_profile_string(pc_ini_file,pc_ini_section_name,"KBYTES-BUF-LEN",&found,ac_value);
		if (found == SSP_TRUE) {
			kbytes_len_buf = (char)(abs(atoi(ac_value)));
		}
	}

	return 0;
}
