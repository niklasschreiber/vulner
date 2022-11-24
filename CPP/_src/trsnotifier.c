// ----------------------------------------------------------------------------
//  PROJECT :  Traffic Steering - PUSH Notification Country Change
// ----------------------------------------------------------------------------
//
//  File Name   : trsnotifier.c
//  Last Change : 04/03/2019
//
// ---------------------< Include files >---------------------------------------
#if (_TNS_E_TARGET)
T0000H06_07FEB2019_KTSTEADZ() {};
#elif (_TNS_X_TARGET)
T0000L16_07FEB2019_KTSTEADZ() {};
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
#include <defs.h>
#include <core.h>
#include <iqelem.h>
#include <tfs3.h>
#include <trsnotifier.h>
#include <jsmnpub.h>
// ---------------------< External Function Prototypes >----------------------
// ---------------------< Internal Function Prototypes >----------------------
short LoadParameters(short i_reload);
short HandleReceiveMSG(char *data, unsigned short len,short i_info_rec);
void InitProgram(void);
void CloseProgram(void);
void OpenDBs(void);
short HandleTimeout(IO_SYSMSG_TIMEOUT *signal);
short SetEnv(void);
short ReadCCCountryQueue(void);
short RxMsgPathmon(short *fdes,short rcv_cnt,long l_tag);
short CheckErrPathmon(short *fdes, short rc, long l_tag);
short SendToGwHTTPS(t_ts_cc_change_queue_record *t_tfs_record,char *ms_right);
short SendRestRequest(ELEM *elem);
char *ModifyRecord(void *a,short *i_len);
char *DeleteRecord(void *a,short *i_len);
void UpdateDB(ELEM *elem,F_PROT *OperRec);
unsigned short LoadDBCountry(void);
void InsertRecTest(void);
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

void OpenDBs()
{
	short err = 0,i;

	for(i=0;dbnames[i];i++)
	{
		err = DBOpenFile(dbnames[i]->path,&dbnames[i]->fnum);
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
	OpenDBs();

	// solo per test
	InsertRecTest();

	//init hash table
	Core_InitHTab(500);
	//init membuffer
	Core_initmembuffer(CHUNK_SIZE_BUF);

	SETTIMEOUT((void*)1,0,TAG_RELOAD_COUNRTY);
	SETTIMEOUT((void*)i_readque_timeout,0,TAG_READ_QUE);
	SETTIMEOUT((void*)(i_timeout_check_elem * 50),0,TAG_CHECK_ELEM);

	ADDHANDLEDESCRIPTOR(RxMsgPathmon);
	ADDERRORDESCRIPTOR(CheckErrPathmon);

	Core_SetAllElemMemLenData(kbytes_len_buf);
}

void CloseProgram(void)
{
	BumpStat();
	log_close();
}

void replytest(char *data)
{
	t_psend_http_if *s_https = (t_psend_http_if*)data;
	s_https->i_http_code = 500;

	/*
	"code": "202",
	"message": "Richiesta presa in carico.",
	"timestamp": "2019-02-22T09:15:50.432Z",
	"erroreSourceSystem": "SDP",
	"moreInfo": "Richiesta Acquisita",
	"userMessage": ""
	 */

	sprintf(s_https->data,"{\"code\: \"202\",\"message\": \"Richiesta presa in carico.\","
			"\"timestamp\": \"2019-02-22T09:15:50.432Z\", \"erroreSourceSystem\": \"SDP\","
			"\"moreInfo\": \"Richiesta Acquisita\", \"userMessage\": \"\"}");

	REPLY_MSG(data,strlen(&data[2])+2);
}

short HandleReceiveMSG(char *data,unsigned short len,short i_info_rec)
{
	short	msg_id,ret = 0;
	char	*buf="";

	// Leggo lo short che identifica il tipo di Msg.
	memcpy((char *)&msg_id,data,sizeof(short));

	switch(msg_id)
	{
		default:
		{
			LOG((void*)LOG_INFO,"unexpected message <%d:%.50s>",msg_id,data+2);
			replytest(data);
			//REPLY_MSG(buf,strlen(buf));
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
	t_ts_cc_change_queue_record	*t_cc_change_record = (t_ts_cc_change_queue_record*) a;

	t_cc_change_record->i_retry++;

	if(t_cc_change_record->i_retry  <= i_retry_max){
		t_cc_change_record->timestamp = JULIANTIMESTAMP(0);
		*i_len = sizeof(t_ts_cc_change_queue_record);
	}else{
		LOG((void*)LOG_WARNING,"reached max retry <%d>",t_cc_change_record->i_retry);
		*i_len = 0;
	}

	return (char*)a;
}

void UpdateDB(ELEM *elem,F_PROT *OperRec)
{
	short			i_len_rec_update=0,ret;
	char			*ac_text = "";
	t_ts_cc_change_queue_record t_cc_change_record;

	if(OperRec)
	{
		memset(t_cc_change_record.msisdn,' ', sizeof(t_cc_change_record.msisdn));
		memcpy(t_cc_change_record.msisdn,elem->ac_ident,_min(strlen(elem->ac_ident),sizeof(t_cc_change_record.msisdn)));
		if(!(ret=DBReadRecord(&cccque2,(char*)&t_cc_change_record,sizeof(t_cc_change_record.msisdn),
								sizeof(t_cc_change_record),2,FILE_SETKEY_,READLOCKX)))
		{
			ret = DBInsUpdRecord(&cccque2,((char*)OperRec(&t_cc_change_record,&i_len_rec_update)),i_len_rec_update,'U');
		}

		if(!ret){
			if(i_len_rec_update){
				ac_text = "update";
				ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Updated);
			}else{
				ac_text = "delete";
				ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Deleted);
			}
		}else{
			snprintf(ac_reg_stat,sizeof(ac_reg_stat),"ERRORE <%d>",ret);
			ac_text = ac_reg_stat;
		}

		LOG((void*)LOG_INFO,"%s:%s record queue <%s>",
					&elem->ac_ident[LEN_MS],ac_text,cccque2.path);
	}

	Core_freeElemMemQue(elem);
}

short DecodeResponse(char *data,short i_http_code,char **ac_msg)
{
	short ret=0; // (return 0 for delete record else for modify record)
	short retJ;
	char *ac_stat=ac_reg_stat;

	/*
	Response:
	{
	"code": "202",
	"message": "Richiesta presa in carico.",
	"timestamp": "2019-02-07T14:48:41.93Z",
	"erroreSourceSystem": "SDP",
	"moreInfo": "Richiesta Acquisita",
	"userMessage": ""
	}
	*/


	if((retJ = jsmn_parseV(data,strlen(data)) > 0)){
		*ac_msg = jsmn_searchV("message");
	}else{
		log(LOG_ERROR,"Failed <%d> to parse JSON: %s",retJ,data);
	}

	// in caso di errore http
	sprintf(ac_reg_stat,"HTTP_%d_KO",i_http_code);

	switch(i_http_code)
	{
		case 202:
			ac_stat = stat_registry_HTTP_202;
		break;
		case 400:
		case 401:
			//errore permanente
		break;
		case 408:
		case 500:
		case 503:
		case 504:
			//errore temporaneo, retry
			ret = 1;
		break;
		default:
		break;
	}

	ADDSTAT(ac_stat,ac_my_process_name,STAT_Record_Reply);

	return ret;
}

short RxMsgPathmon(short *fdes,short rcv_cnt,long l_tag)
{
	short 	ret_func = 1;
	short	i_idx = (short)(l_tag - TAG_PATHSEND);
	ELEM	*elem;
	t_psend_http_if *s_https;
	F_PROT *OperRec = (F_PROT*)ModifyRecord;
	char	*ac_msg = NULL;

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

				default:
					if(!DecodeResponse(s_https->data,s_https->i_http_code,&ac_msg)){
						OperRec = (F_PROT*)DeleteRecord;
					}

					LOG((void*)LOG_INFO,"%s:RX http code <%d> reply id <%s> msg <%s>",
										&elem->ac_ident[LEN_MS],s_https->i_http_code,
										&elem->ac_ident[LEN_MS*2],(ac_msg ? ac_msg : ""));
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
	short	ret_func=1;
	short	p_err=0,fs_err=0;
	short	i_idx = (short)(l_tag - TAG_PATHSEND);
	ELEM	*elem;

	if(*fdes == fnumPSend){
		ret_func = 0;

		Core_PATHSEND_info(&p_err,&fs_err);
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
			switch(p_err)
			{
				case 40:
					OperRec = (F_PROT*)ModifyRecord;
				break;
				case 233:
				default:
					OperRec = (F_PROT*)DeleteRecord;
				break;
			}

			UpdateDB(elem,OperRec);
		}else{
			LOG((void*)LOG_WARNING,"unexpected message tag <%d>",l_tag);
		}
	}

	return ret_func;
}

short ReadCCCountryQueue(void)
{
	short ret = 0;
	t_ts_cc_change_queue_record t_cc_change_record;
	char ac_ms_right[LEN_MS];
	long long curr_ts = JULIANTIMESTAMP(0);
	char c_loop = SSP_TRUE;
static	F_TAL f_seek = FILE_SETKEY_;

	memset(ac_ms_right,0,sizeof(ac_ms_right));
	memset(&t_cc_change_record,' ',sizeof(t_cc_change_record));
	memcpy(t_cc_change_record.msisdn,ac_range,2);

	while(c_loop && !((ret=DBReadRecord(&cccque,(char*)&t_cc_change_record,sizeof(t_cc_change_record.msisdn),
										 sizeof(t_cc_change_record),MBE_MODE_APPROXIMATE,f_seek))))
	{
		f_seek = (F_TAL)Func_wrap;

		if(memcmp(t_cc_change_record.msisdn,&ac_range[3],2) <= 0 && (!t_cc_change_record.i_retry ||
			(t_cc_change_record.i_retry && (curr_ts-t_cc_change_record.timestamp)/1000000 > i_retry_delay)))
		{
			ADDSTAT(stat_registry_QUE,ac_my_process_name,STAT_Record_Que_Read);
			c_loop = SSP_FALSE;

			memcpy(ac_ms_right,t_cc_change_record.msisdn,LEN_MS);
			Core_TrimStringRx(ac_ms_right,LEN_MS);
			Core_ReverseStr(ac_ms_right,(short)strlen(ac_ms_right));
			Core_TrimStringRx(t_cc_change_record.msisdn,sizeof(t_cc_change_record.msisdn));

			log(LOG_INFO,"%s|%.16s processing record",ac_ms_right,t_cc_change_record.imsi);

			SendToGwHTTPS(&t_cc_change_record,ac_ms_right);
		}
	}


	if(ret == MBE_EOF){
		f_seek = FILE_SETKEY_;
		ret = QUEUE_EOF;
	}

	return ret;
}

short SendRestRequest(ELEM *elem)
{
	short ret=0, i_len_back;
	t_psend_http_if *s_https;

	s_https = (t_psend_http_if*)elem->data;
	s_https->i_http_code = 10023;

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

short CreateSDPRest(char *buffer,char *ac_msisdn,t_ts_cc_change_queue_record *t_cc_change_record,
					    	char *ac_transid)
{
	short ret = 0;
	long long jts_loc;
	short time_p[8];
	char date_time[30];
	unsigned short i_len = (short)strlen(t_cc_change_record->cc);
	char *descr_country = (char*)Core_Get(t_cc_change_record->cc,&i_len);
	char *sessionID = Core_getTIDa();

	/*
	{
	"message": {
		"MSISDN": 3351234567,
		"CountryCode": 33
		"DescriptionCode": "Francia",
		"Date": YYYY-MM-DD
		"Time":  hh:mm:ss:SSS
	}
	*/

	sprintf(ac_transid,"%s",sessionID);

	jts_loc = CONVERTTIMESTAMP(t_cc_change_record->timestamp);
    INTERPRETTIMESTAMP(jts_loc,time_p);

    snprintf(date_time,sizeof(date_time),"%4.4d-%2.2d-%2.2d\0%2.2d:%2.2d:%2.2d.%3.3d",
    										time_p[0],time_p[1],time_p[2],time_p[3],
										time_p[4],time_p[5],time_p[6]);

	// nuova per JSON
	snprintf(buffer,kbytes_len_buf-2,
				"POST|application/json|%s|" \
				"{\"message\":{\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\"}}"\
				"|||%s: %s\r\n%s: %s\r\n%s: %s\r\n",
				ac_url_push_notification,
				"MSISDN",ac_msisdn,
				"CountryCode",t_cc_change_record->cc,
				"DescriptionCode",descr_country ? descr_country : "null",
				"Data",date_time,
				"Time",&date_time[11],
				"sessionID",sessionID,
				"businessID",sessionID,
				"transactionID",sessionID);

	return ret;
}

short SendToGwHTTPS(t_ts_cc_change_queue_record *t_cc_change_record,char *ms_right)
{
	short ret = 0;
	ELEM *elem;
	t_psend_http_if *s_https;

	if(!Core_findElemMemoryQue(t_cc_change_record->msisdn,LEN_MS))
	{
		elem = Core_insElemMemory(t_cc_change_record->msisdn,LEN_MS);
		if(elem){
			memcpy(&elem->ac_ident[LEN_MS],ms_right,strlen(ms_right));

			s_https = (t_psend_http_if*)elem->data;
			s_https->i_http_code = 10023;

			*s_https->data = 0;
			ret = CreateSDPRest(s_https->data,ms_right,t_cc_change_record,&elem->ac_ident[LEN_MS*2]);
			if(!ret){
				ret = SendRestRequest(elem);
			}else{
				// free elem
				Core_freeElemMemQue(elem);
			}
		}else{
			LOG((void*)LOG_ERROR,"%s:errore memory allocation",ac_my_process_name);
			ret = 1;
		}
	}else{
		LOG((void*)LOG_INFO,"%s:is still processing",ms_right);
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
				ret = ReadCCCountryQueue();
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
			case TAG_RELOAD_COUNRTY:
			{
				Core_checkChgFile(ac_path_oss_country,0,(F_GEN*)LoadDBCountry);
				SETTIMEOUT((void*)i_reload_country_db_timeout,0,TAG_RELOAD_COUNRTY);
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

void InsertRecTest()
{
	t_ts_cc_change_queue_record t_cc_change_record;

	memset(&t_cc_change_record,' ',sizeof(t_cc_change_record));

	memcpy(t_cc_change_record.msisdn,"2834357553",strlen("2834357553"));
	memcpy(t_cc_change_record.imsi,"222011234567890",strlen("222011234567890"));
	memcpy(t_cc_change_record.cc,"39",2);
	t_cc_change_record.timestamp=JULIANTIMESTAMP();
	t_cc_change_record.i_retry = 0;

	DBInsUpdRecord(&cccque2,(char*)&t_cc_change_record,sizeof(t_cc_change_record),'I');
}

short Opendb(db_struct *dbname)
{
	short err = 0;

	err = DBOpenFile(dbname->path,&dbname->fnum);
	if(err != 0)
	{
		LOG((void*)LOG_ERROR,"Err <%d> MBE_FILE_OPEN_ (%s)",err,dbname->path);
		LOG_EVT(SSPEVT_NORMAL, SSPEVT_NOACTION,(short)(i_evt_number_start+EMS_ERR_OPEN_DB),
				EMS_T_ERR_OPEN_DB,ac_my_process_name,err,dbname->path);
		EXIT(0);
	}

	return err;
}


unsigned short LoadDBCountry()
{
	unsigned short ret = 0,i_len;
	t_ts_paesi_record record_country;
static	F_TAL f_seek = FILE_SETKEY_;

	Opendb(&country);

	memset(&record_country,' ',sizeof(record_country));

	Core_freemembuffer();

	while(!(ret=DBReadRecord(&country,(char*)&record_country,sizeof(record_country.paese),
							  	  sizeof(record_country),MBE_MODE_APPROXIMATE,f_seek)) &&
			!(ret=Core_Put(Core_TrimStringRx(record_country.paese,sizeof(record_country.paese)),
							(unsigned short)_min(strlen(record_country.paese),sizeof(record_country.paese)),
							Core_TrimStringRx(record_country.den_paese,sizeof(record_country.den_paese)),
							(unsigned short)_min(strlen(record_country.den_paese),sizeof(record_country.den_paese)))))
	{
		f_seek = (F_TAL)Func_wrap;
		i_len = (unsigned short)_min(strlen(record_country.paese),sizeof(record_country.paese));
		log(LOG_DEBUG2,"%s %s",record_country.paese,(char*)Core_Get(record_country.paese,&i_len));
	}

	f_seek = FILE_SETKEY_;

	DBOpenClose(country.fnum);

	return ret;
}

short SetEnv()
{
	params.par[params.i_num_par].name=&pc_ini_file;
	params.par[params.i_num_par++].value="INIFILE";

	params.par[params.i_num_par].name=&pc_ini_section_name;
	params.par[params.i_num_par]._default="PUSH-WELCOME";
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
		get_profile_string(pc_ini_file,pc_ini_section_name,"STAT-DISABLE",&found,ac_value);
		if(found == SSP_FALSE)
		{
			i_stat_bump_interval = 30000;
			get_profile_string(pc_ini_file, "STAT", "STAT-BUMP-INTERVAL",&found,ac_value);
			if(found == SSP_TRUE) i_stat_bump_interval = (short)(atoi(ac_value) * 100);
			get_profile_string(pc_ini_file, "STAT", "STAT-PATH",&found,ac_path_stat_file);
			if(found == SSP_FALSE)
			{
				PrintParamMissing("STAT","STAT-PATH");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT", "STAT-PREFIX",&found,ac_stat_prefix);
			if(found == SSP_FALSE)
			{
				PrintParamMissing("STAT","STAT-PREFIX");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT", "STAT-GROUP",&found,ac_value);
			if(found == SSP_TRUE) i_stat_group = (short)atoi(ac_value);
			else
			{
				PrintParamMissing("STAT","STAT-GROUP");
				EXIT(found);
			}
			get_profile_string(pc_ini_file, "STAT", "MAX-REGS",&found,ac_value);
			if(found == SSP_TRUE) i_stat_max_registers = (short)atoi(ac_value);
			else
			{
				PrintParamMissing("STAT","MAX-REGS");
				EXIT(found);
			}

			get_profile_string(pc_ini_file, "STAT","MAX-COUNTS",&found,ac_value);
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
		get_profile_string(pc_ini_file,"MANAGER","CCC-QUEUE-PATH",&found,cccque.path);
		if(found == SSP_FALSE)
		{
			PrintParamMissing("MANAGER","CCC-QUEUE-PATH");
			EXIT(found);
		}

		memcpy(cccque2.path,cccque.path,sizeof(cccque2.path));

		get_profile_string(pc_ini_file,"GENERIC","DB-LOC-COUNTRIES-PATH",&found,country.path);
		if(found == SSP_FALSE)
		{
			PrintParamMissing("GENERIC","DB-LOC-COUNTRIES-PATH");
			EXIT(found);
		}

		Core_file_guardian2oss(country.path,ac_path_oss_country,sizeof(ac_path_oss_country));

#ifdef _TEST_2
		// per test
		// ----------------------------------------------------------------------------
		// sprintf(ac_path_oss_country,"/G/sas3/tfs10log/pwc001");
		// ----------------------------------------------------------------------------
#endif

		get_profile_string(pc_ini_file,pc_ini_section_name,"MSISDN-RANGES",&found,ac_value);
		if(found == SSP_TRUE){
			rate=GetRange(ac_value);
			if(rate != 100){
				LOG((void*)LOG_ERROR,"%s %s not exactly configured",ac_my_process_name,"MSISDN-RANGES");
				LOG_EVT(SSPEVT_NORMAL,SSPEVT_ACTION,(short)(i_evt_number_start+EMS_ERR_RANGE),
						"%s %s not exactly configured",ac_my_process_name,"MSISDN-RANGES");
				DELAY(EXIT_DELAY);
				exit (0);
			}
		}else{
			PrintParamMissing(pc_ini_section_name,"MSISDN-RANGES");
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
		get_profile_string(pc_ini_file,pc_ini_section_name,"SSL-GATEWAY-URL",&found,ac_url_push_notification);
		if(found == SSP_FALSE)
		{
			PrintParamMissing(pc_ini_section_name,"SSL-GATEWAY-URL");
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

		i_reload_country_db_timeout = 10 * 60 * 100;  // 10 min
		get_profile_string(pc_ini_file,pc_ini_section_name,"TIMEOUT-RELOAD-COUNTRY",&found,ac_value);
		if (found == SSP_TRUE) {
			i_reload_country_db_timeout = 6000 * (short)(abs(atoi(ac_value)));
		}

		kbytes_len_buf = 1024;
		get_profile_string(pc_ini_file,pc_ini_section_name,"KBYTES-BUF-LEN",&found,ac_value);
		if (found == SSP_TRUE) {
			kbytes_len_buf = (short)(1024*abs(atoi(ac_value)));
		}
	}

	return 0;
}
