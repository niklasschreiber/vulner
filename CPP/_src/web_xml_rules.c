/*----------------------------------------------------------------------------
*   PROGETTO :  TFS
*-----------------------------------------------------------------------------
*
*   File Name       : frontend_cgi.c
*   Ultima Modifica : 13/03/2014
*
*------------------------------------------------------------------------------
*   Descrizione
*   -----------
*   GESTIONE SOGLIE DA SISTEMA
*
*/

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
#include <pwd.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>

#include <cextdecs.h>
#include "usrlib.h"

#include "sspdefs.h"
#include "sspevt.h"
#include "sspfunc.h"
#include "ssplog.h"
#include "sspstat.h"
#include "ssptlv.h"

// SCEW (Simple C Expat Wrapper)
#include <scew/scew.h>
#include <scew/xprint.h>

#include "mbedb.h"
#include "web_func.h"
#include "cgi.h"


/*---------------------< Definitions >---------------------------------------*/
#define BITS_2_7_8_12_15	8585	// USER_AUTHENTICATE_
#define	INI_SECTION_NAME	"FRONTEND"
#define LEN_KEY_SOGLIE  149
#define LEN_GRP			64
#define ITEM_SIZE       300

//--- Thresholds (Len 180, Key0 149) -------------------------------------------------------------
#pragma fieldalign shared2 _ts_soglie_record
typedef struct _ts_soglie_record
{
	char		gr_pa[64];
	char		gr_op[64];
	char		fascia_da[5];
	char		fascia_a[5];
	char		gg_settimana[7];
	char		user_type[4];

	char		stato;
	short		soglia;
	long 		tot_accP[2];
	long		tot_accT[2];

	char		peso;
	char		politica;

	char		filler[10];
} t_ts_soglie_record;

//--- Operators (Len 320, Key0 18, Key1 64 offset 146, Key2 16 offset 276) -----------------------
#pragma fieldalign shared2 _ts_oper_record
typedef struct _ts_oper_record
{
	char		paese[8];
	char		cod_op[10];

	char		den_op[64];
	char		den_paese[64];
	char		gruppo_op[64];		// altkey1
	char		gruppo_pa[64];
	short		max_ts;

	char		imsi_op[16];		// altkey2

	short		map_ver;
	int			reset_ts_interval;
	char		characteristics[10];
	short		steering_map_errcode;
	short		steering_lte_errcode;
	char		filler[8];
} t_ts_oper_record;

/*---------------------< Parameters >----------------------------------------*/

//LOG
char				ac_path_log_file[30];
char				ac_log_prefix[10];
int					i_num_days_of_log;
int					i_trace_level;
int					i_log_options;
char				ac_log_trace_string[128];

//GENERIC
char				ac_rules_db_path[100];
char				ac_rules_db_path_Rem[100];
char				acFileOperatori_Loc[100];
/*---------------------< Static and Global Variables >-----------------------*/

char				ac_my_process_name[10];
short				i_my_cpu;
short				i_my_pin;

char				*pc_ini_file;
char				ac_path_file_ini_oss[64];

char				*remote_addr;


/*---------------------< External Function Prototypes >----------------------*/

extern char			**environ;

/*---------------------< Internal Function Prototypes >----------------------*/

//--- XML interface ---
scew_tree *decodeXML(char *buffer, short *error, char *message, char *context);
scew_tree *dispatchXMLRequest(scew_tree *p_request, short *error, char *message);
scew_tree *encodeXMLResponse(scew_tree *p_request, short error, char *message);

scew_tree *get_list_rules(scew_tree *p_request, short *error, char *message);
scew_tree *get_rule(scew_tree *p_request, short *error, char *message);
scew_tree *del_rule(scew_tree *p_request, short *error, char *message);
scew_tree *ins_rule(scew_tree *p_request, short *error, char *message);
scew_tree *upd_rule(scew_tree *p_request, short *error, char *message);
scew_tree *apply_rule(scew_tree *p_request, short *error, char *message);


scew_element *get_element(scew_element *parent, char *element_name, char requested, short *error, char *message);
char *get_element_value(scew_element *parent, char *element_name, char requested, short *error, char *message);
void get_attribute_value(scew_element *parent, char *element_name, char *attribute_name, char *attribute_value);

void addXMLTag(scew_element *parent, char *tag_name, char *tag_value, char *format);

//--- Utilities ---
int 	SetUserId(char *user);
void 	Initialize();
short 	Controlla_Dati(t_ts_soglie_record *record_soglie, short handle, int *iRes , short *error, char *message );
short 	controlla_PaeseEgruppi(char *acP_Country, char *acP_Operator, short *error, char *message);

short	Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo, short *error, char *message);


char			*p_operation;
char 			ac_def_hexdefuser[10];
/*---------------------------------------------------------------------------*/

int	main(int argc, char *argv[])
{
	short			ret;

	//char			xml_out[16384];
	char			xml_out[50000];
	int				xml_out_len;
	char			ac_message[160];
	char			*param_xmlRequest;

	char			*ac_proc_user;
	char	ac_user_auth_trace[200];

	scew_tree		*p_request = NULL;
	scew_tree		*p_response = NULL;


	ret = 0;
	ac_message[0] = 0;

	p_request = NULL;
	p_response = NULL;
	//ll_recv_jts = JULIANTIMESTAMP();


	if (ac_proc_user = getenv("TGDS_USER_NAME"))
	{
		if (cgi_session_Authenticate(ac_proc_user, ac_user_auth_trace))
		{
			exit(1);
		}
	}
	log(LOG_DEBUG, "User = %s", ac_proc_user);

	Initialize();

	remote_addr = getenv("REMOTE_ADDR");
	log(LOG_DEBUG, "%s Inizialize", remote_addr);


	if ( (param_xmlRequest = getenv( "xmlRequest" ) ) != NULL )
	{
		log(LOG_DEBUG, "%s XML recv [%s][%d]", remote_addr, param_xmlRequest, strlen(param_xmlRequest));
		p_request = decodeXML(param_xmlRequest, &ret, ac_message, "main()");
		if (!ret)
		{
			log(LOG_DEBUG, "%s decodeXML(%d) message[%s] request[%s]", remote_addr, ret, ac_message, p_request);
			p_response = dispatchXMLRequest(p_request, &ret, ac_message);
		}
	}
	else
	{
		log(LOG_DEBUG, "%s xmlRequest[%s] not present", remote_addr, param_xmlRequest);
	}

	if (ret && !p_response)
	{
		p_response = encodeXMLResponse(p_request, ret, ac_message);
		log(LOG_DEBUG2, "%s dopo  XML Resp [%s]", remote_addr, p_response);
	}

	memset(xml_out, 0x00, sizeof(xml_out));
	tree_print_buffer(p_response, xml_out);
	xml_out_len = (int) strlen(xml_out);


	if (ac_message[0])
		log(LOG_WARNING, "%s|resp|%s|%d|%s", remote_addr, p_operation, ret, ac_message);
	else
		log(LOG_WARNING, "%s|resp|%s|%d", remote_addr, p_operation,  ret);

	log_msg(LOG_DEBUG2, "--XML resp", xml_out, xml_out_len);


	printf("Content-Type: text/xml\n");
	printf("Content-Length: %d\n\n", xml_out_len);
	printf("%s (%d)", xml_out, xml_out_len);
	fflush(stdout);

	// Free the SCEW trees
	if (p_request)
		scew_tree_free(p_request);
	if (p_response)
		scew_tree_free(p_response);


	return 0;
}


int SetUserId(char *username)
{
	int		ret = 0;
	char	ac_user_password[255];
	short	status;
	short	status_flags;
	char	displaytext[2050];
	short	displaytext_len;

	sprintf(ac_user_password, "%s,X=123456", username);
	ret = USER_AUTHENTICATE_(
		ac_user_password,
		(short)strlen(ac_user_password),
		BITS_2_7_8_12_15,
		,
		&status,
		&status_flags,
		displaytext,
		2050,
		&displaytext_len);

	return(ret);
}

/*---------------------------------------------------------------------------*/

void Initialize()
{
	int		found;
	char	ac_wrk_str[1024];
	char	*wrk_str;
	short	i_proch[20];

	PROCESSHANDLE_GETMINE_(i_proch);

	memset(acFileOperatori_Loc, 0x00, sizeof(acFileOperatori_Loc));
	memset(ac_rules_db_path, 0x00, sizeof(ac_rules_db_path));
	memset(ac_rules_db_path_Rem, 0x00, sizeof(ac_rules_db_path_Rem));

	pc_ini_file = getenv("INI_FILE");
	if (pc_ini_file == NULL)
	{
		exit(1);
	}

	// Compose OSS filename for reload check
	if (*pc_ini_file == '/')
	{
		// OSS filename
		strcpy(ac_path_file_ini_oss, pc_ini_file);
	}
	else
	{
		if (*pc_ini_file == '\\')
		{
			// Guardian filename (with system name)
			strcpy(ac_wrk_str, pc_ini_file+1);
			wrk_str = strtok(ac_wrk_str, ".");
			sprintf(ac_path_file_ini_oss, "/E/%s/G/%s", wrk_str, ac_wrk_str+strlen(ac_wrk_str)+2);
		}
		else
		{
			// Guardian filename (without system name)
			sprintf(ac_path_file_ini_oss, "/G/%s", pc_ini_file+1);
		}
		while (wrk_str = strchr(ac_path_file_ini_oss, '.')) *wrk_str = '/';
	}


	/* --- LOG ------------------------------------------------------------- */
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-PATH", &found, ac_path_log_file);
	if (found == SSP_FALSE)
	{
		get_profile_string(pc_ini_file, "LOG", "LOG-PATH", &found, ac_path_log_file);
		if (found == SSP_FALSE)
		{
			exit(1);
		}
	}
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-PREFIX", &found, ac_log_prefix);
	if (found == SSP_FALSE)
		strcpy(ac_log_prefix, "XML");

	i_num_days_of_log = 8;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_FALSE)
		get_profile_string(pc_ini_file, "LOG", "LOG-DAYS", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_num_days_of_log = atoi(ac_wrk_str);

	// OPEN LOG FILE
	log_init(ac_path_log_file, ac_log_prefix, i_num_days_of_log);

	i_trace_level = LOG_DEBUG2;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_FALSE)
		get_profile_string(pc_ini_file, "LOG", "LOG-LEVEL", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_trace_level = (short)atoi(ac_wrk_str);

	i_log_options = 15;
	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_FALSE)
		get_profile_string(pc_ini_file, "LOG", "LOG-OPTIONS", &found, ac_wrk_str);
	if (found == SSP_TRUE)
		i_log_options = (short)atoi(ac_wrk_str);

	log_param(i_trace_level, i_log_options, "");

	get_profile_string(pc_ini_file, INI_SECTION_NAME, "LOG-TRACE", &found, ac_log_trace_string);
	if (ac_log_trace_string[0])
		log_set_trace(ac_log_trace_string);
	else
		log_reset_trace();

	/* --- GENERIC --------------------------------------------------------- */
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-THRESHOLDS-PATH", &found, ac_rules_db_path);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-THRESHOLDS-PATH");
		exit(1);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-REM-THRESHOLDS-PATH", &found, ac_rules_db_path_Rem);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-REM-THRESHOLDS-PATH");
		exit(1);
	}
	get_profile_string(pc_ini_file, "GENERIC", "DB-LOC-OPER-PATH", &found, acFileOperatori_Loc);
	if (found == SSP_FALSE)
	{
		log(LOG_ERROR, "Missing parameter GENERIC -> DB-LOC-OPER-PATH");
		exit(1);
	}

	get_profile_string(pc_ini_file, "WEB", "HEX-DEFAULT-USER-TYPES", &found, ac_def_hexdefuser);
	if ((found == SSP_FALSE) || (strlen(ac_def_hexdefuser) == 0))
		strcpy(ac_def_hexdefuser, "FFFFFFFF");

}
// *******************************************************************************************************

scew_tree *decodeXML(char *buffer, short *error, char *message, char *context)
{
	scew_parser	*parser = NULL;
	scew_tree	*document = NULL;

	log(LOG_DEBUG2, "decodeXML");

	// Creates a SCEW parser
    parser = scew_parser_create();
    scew_parser_ignore_whitespaces(parser, 1);

    // Loads request
	if (!scew_parser_load_buffer(parser, buffer, strlen(buffer)))
    {
		scew_error err = scew_error_code();

		if (context)
		{
			sprintf(message, "%s:", context);
		}

        if (err == scew_error_expat)
        {
			enum XML_Error expat_code = scew_error_expat_code(parser);
			*error = 104;
			sprintf(message+strlen(message), "error [%d] decoding xml: expat error [%d]: line %d, column %d: %s", err,
				expat_code,
				scew_error_expat_line(parser),
				scew_error_expat_column(parser),
				scew_error_expat_string(expat_code));
		}
		else
		{
			*error = 100;
			sprintf(message+strlen(message), "error [%d] decoding xml", err);
		}
		log(LOG_DEBUG2, "in if decodeXML err[%d] error[%d] mess[%s]", err, *error, message );

	}
	else
	{
		log(LOG_DEBUG2, "fine di decodeXML error[%d] mess[%s]", *error, message );
		document = scew_parser_tree(parser);
	}

	// Frees the SCEW parser
	scew_parser_free(parser);

	return document;
}

// ****************************************************************************************
scew_tree *dispatchXMLRequest(scew_tree *p_request, short *error, char *message)
{
	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*header = NULL;

	char			*service = NULL;

	log(LOG_DEBUG2, "dispatchXMLRequest");

	if ((root = scew_tree_root(p_request)) && !strcmp("Request", root->name))
	{
		if ((header = get_element(root, "Header", 1, error, message)))
		{
			if ((service = get_element_value(header, "Service", 1, error, message)))
			{
				p_operation = get_element_value(header, "OperationType", 1, error, message);
			}
		}
	}
	else
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
		log(LOG_ERROR, "%s missing <Request> root", remote_addr);

	}

	if (!(*error))
	{
		if (!strcasecmp(service, "TFS"))
		{
			if (!strcasecmp(p_operation, "LIST"))
			{
				p_response = get_list_rules(p_request, error, message);
				log(LOG_DEBUG2, " response= %s", p_response);
			}
			else if (!strcasecmp(p_operation, "GET"))
			{
				p_response = get_rule(p_request, error, message);
			}
			else if (!strcasecmp(p_operation, "DEL"))
			{
				p_response = del_rule(p_request, error, message);
			}
			else if (!strcasecmp(p_operation, "UPD"))
			{
				p_response = upd_rule(p_request, error, message);
			}
			else if (!strcasecmp(p_operation, "INS"))
			{
				p_response = ins_rule(p_request, error, message);
			}
			else if (!strcasecmp(p_operation, "APPLY"))
			{
				p_response = apply_rule(p_request, error, message);
			}
			else
			{
				*error = 107;
				sprintf(message, "invalid OperationType: %s", p_operation);
				log(LOG_ERROR, "%s invalid OperationType: %s", remote_addr, p_operation);
			}
		}

		// Invalid service
		else
		{
			*error = 106;
			sprintf(message, "invalid Service: %s", service);
			log(LOG_ERROR, "%s invalid Service: %s", remote_addr, service);
		}
	}

	return p_response;
}

scew_tree *encodeXMLResponse(scew_tree *p_request, short error, char *message)
{
	char			ac_error[4];

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	char			*element_value = NULL;

	log(LOG_DEBUG2, "encodeXMLResponse");

	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}
		}
	}

	//--- Parameters
	parameters = scew_element_add(root, "Parameters");

	// ResultCode
	sprintf(ac_error, "%d", error);
	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_error);

	// Message
	if (message[0])
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	return p_response;
}

// *****************************************************************************************
//  List Thresholds
// *****************************************************************************************
scew_tree *get_list_rules(scew_tree *p_request, short *error, char *message)
{
	short			handle = -1;
	char			ac_Chiave[LEN_KEY_SOGLIE];
	short 			rc;
	short			contaRec = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	scew_element	*rules = NULL;

	char			*element_value = NULL;

	int 			user_type_bitmask;
	char 			acCountry[LEN_GRP+1];
	char 			acOperator[LEN_GRP+1];
	char 			acTimeF[6];
	char 			acTimeTo[6];
	char 			acDays[8];
	char			acUser[10];
	char			acPeso[10];
	char			acPolitica[10];
	char			acSoglia[10];

	char 			ac_RS[10];
	char			acRecord[10];

	t_ts_soglie_record record_soglie;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));
	memset(acRecord, 0, sizeof(acRecord));

	memset(acCountry, 0, sizeof(acCountry));
	memset(acOperator, 0, sizeof(acOperator));
	memset(acTimeF, 0, sizeof(acTimeF));
	memset(acTimeTo, 0, sizeof(acTimeTo));
	memset(acDays, 0, sizeof(acDays));
	memset(acUser, 0, sizeof(acUser));
	memset(acPeso, 0, sizeof(acPeso));
	memset(acPolitica, 0, sizeof(acPolitica));
	memset(acSoglia, 0, sizeof(acSoglia));
	memset(ac_RS, 0, sizeof(ac_RS));

	log(LOG_DEBUG2, "get_list_rules");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
		log(LOG_ERROR, "missing <Request> root");
	}

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}
			parameters = scew_element_add(root, "Parameters");
		}
	}

	if (!*error)
	{
		/*******************
		* lettura record db
		*******************/
		rc = MbeFileOpen_nw(ac_rules_db_path, &handle);
		if (rc != 0)
		{
			log(LOG_ERROR, "Open error file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error file[%s] : %d", ac_rules_db_path, rc);
		}
		else
		{
			//  ------------ DATI  -------------------------------
			rules = scew_element_add(root, "Rules");

			/*******************
			* Cerco il record
			*******************/
			MBE_FILE_SETKEY_( handle, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE);

			while ( 1 )
			{
				/*******************
				* Leggo il record
				*******************/
				rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
						*error = 302;
						sprintf(message, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
					}
					else
						rc = 0;
					break;
				}
				/* record TROVATO */
				else  /* readx ok */
				{
					if( strncmp(record_soglie.gr_pa, "**********", 10))
					{
						element = scew_element_add(rules, "RULE");

						memset(acCountry,0, sizeof(acCountry));
						memcpy(acCountry, record_soglie.gr_pa, LEN_GRP );
						TrimString(acCountry);

						memset(acOperator,0, sizeof(acOperator));
						memcpy(acOperator, record_soglie.gr_op, LEN_GRP );
						TrimString(acOperator);

						strncpy(acTimeF, record_soglie.fascia_da, 5 );
						acTimeF[5] = 0;
						strncpy(acTimeTo, record_soglie.fascia_a, 5 );
						acTimeTo[5] = 0;
						strncpy(acDays, record_soglie.gg_settimana, 7 );
						acDays[7] = 0;
						sprintf(acSoglia, "%d", record_soglie.soglia );
						sprintf(acPeso, "%d", record_soglie.peso );
						sprintf(acPolitica, "%d", record_soglie.politica );

						scew_element_add_attr_pair(element, "Country", acCountry);
						scew_element_add_attr_pair(element, "Operator", acOperator);
						scew_element_add_attr_pair(element, "TimeFrom", acTimeF);
						scew_element_add_attr_pair(element, "TimeTo", acTimeTo);
						scew_element_add_attr_pair(element, "Days", acDays);

						memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);
						sprintf(acUser, "%08X",user_type_bitmask);
						scew_element_add_attr_pair(element, "UserTypes", acUser);

						scew_element_add_attr_pair(element, "Threshold", acSoglia );
						scew_element_add_attr_pair(element, "Status", (record_soglie.stato == '1' ? "On" : "Off") );
						scew_element_add_attr_pair(element, "Weight", acPeso);
						scew_element_add_attr_pair(element, "Politics", acPolitica);

						contaRec++;
					}
 				}
			}//fine while
			MBE_FILE_CLOSE_(handle);
		}
	}

	sprintf(acRecord, "%d", contaRec);
	if (rc == 0)
	{
		strcpy(ac_RS, "200");
		scew_element_add_attr_pair(rules, "Record", acRecord);
	}
	else
		strcpy(ac_RS, "500");

	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_RS);
	if (rc == 1)
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	return p_response;
}
// ******************************************************************************
// restituisce più record
// ******************************************************************************
scew_tree *get_rule(scew_tree *p_request, short *error, char *message)
{
	short			handle = -1;
	short 			rc;
	short			lenKey;
	short			contaRec = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element    *p_request_parameters = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	scew_element    *rules = NULL;

	scew_attribute	*attribute = NULL;

	char			*element_value = NULL;

	char			acP_Operator[LEN_GRP+1];
	char 			acP_TimeF[6];
	char 			acP_TimeTo[6];
	char 			acP_Days[8];
	char			acP_hexdefuser[10];

	int 			user_type_bitmask;
	char 			acCountry[LEN_GRP+1];
	char 			acOperator[LEN_GRP+1];
	char 			acTimeF[6];
	char 			acTimeTo[6];
	char 			acDays[8];
	char			acUser[10];
	char			acSoglia[10];
	char			acPeso[10];
	char			acPolitica[10];
	char 			ac_hexdefuser[10];

	char 			ac_RS[10];
	char			acRecord[10];

	t_ts_soglie_record record_soglie;

	memset(acRecord, 0, sizeof(acRecord));

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(acCountry, 0, sizeof(acCountry));
	memset(acOperator, 0, sizeof(acOperator));
	memset(acTimeF, 0, sizeof(acTimeF));
	memset(acTimeTo, 0, sizeof(acTimeTo));
	memset(acDays, 0, sizeof(acDays));
	memset(acUser, 0, sizeof(acUser));
	memset(acSoglia, 0, sizeof(acSoglia));
	memset(acPeso, 0, sizeof(acPeso));
	memset(acPolitica, 0, sizeof(acPolitica));
	memset(ac_hexdefuser, 0, sizeof(ac_hexdefuser));

	memset(acP_Operator, 0, sizeof(acP_Operator));
	memset(acP_TimeF, 0, sizeof(acP_TimeF));
	memset(acP_TimeTo, 0, sizeof(acP_TimeTo));
	memset(acP_Days, 0, sizeof(acP_Days));
	memset(acP_hexdefuser, 0, sizeof(acP_hexdefuser));

	memset(ac_RS, 0, sizeof(ac_RS));

	log(LOG_DEBUG2, "get_rule");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
	}
	else
	{
		//  legge i parametri Attributi del tag RULE
		if ((p_request_header = get_element(root, "Header", 1, error, message)) &&
			(p_request_parameters = get_element(root, "Parameters", 1, error, message)))
		{
			// Coutry obbligatorio
			memset(acCountry, 0, sizeof(acCountry));
			get_attribute_value(p_request_parameters, "RULE", "Country", acCountry);
			if(acCountry[0] != 0)
			{
				if(strlen(acCountry) > LEN_GRP)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Country");
				}
				else
				{
					memcpy(record_soglie.gr_pa, acCountry, strlen(acCountry));
					lenKey = sizeof(record_soglie.gr_pa);
				}
			}
			else
			{
				*error = 108;
				sprintf(message, "missing <Parameters> <RULE> Country");
			}
			if (!*error)
			{
				memset(acOperator, 0, sizeof(acOperator));
				get_attribute_value(p_request_parameters, "RULE", "Operator", acP_Operator);
				if(acP_Operator[0] != 0)
				{
					if(strlen(acP_Operator) > LEN_GRP)
						memcpy(record_soglie.gr_op, acP_Operator, LEN_GRP);
					else
						memcpy(record_soglie.gr_op, acP_Operator, strlen(acP_Operator));
				}
				get_attribute_value(p_request_parameters, "RULE", "TimeFrom", acP_TimeF);
				if(acP_TimeF[0] != 0)
					memcpy(record_soglie.fascia_da, acP_TimeF, sizeof(record_soglie.fascia_da));

				get_attribute_value(p_request_parameters, "RULE", "TimeTo", acP_TimeTo);
				if(acP_TimeTo[0] != 0)
					memcpy(record_soglie.fascia_a, acP_TimeTo, sizeof(record_soglie.fascia_a));

				get_attribute_value(p_request_parameters, "RULE", "Days", acP_Days);
				if(acP_Days[0] != 0)
					memcpy(record_soglie.gg_settimana, acP_Days, sizeof(record_soglie.gg_settimana));

				get_attribute_value(p_request_parameters, "RULE", "UserTypes", acP_hexdefuser);
				if(acP_hexdefuser[0] != 0)
					sscanf(acP_hexdefuser, "%X", record_soglie.user_type );

				log(LOG_WARNING, "%s|recv|GET|%s|%s|%s|%s|%s|%s len_key(%d)", remote_addr,
						acCountry, acP_Operator, acP_TimeF, acP_TimeTo, acP_Days, acP_hexdefuser, lenKey);
			}
		}
		else
		{
			*error = 108;
			sprintf(message, "missing <Parametrer> root");
		}
	}

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}

			parameters = scew_element_add(root, "Parameters");
			rules = scew_element_add(parameters, "RULE");
			if ((element = scew_element_by_name(p_request_parameters, "RULE")))
			{
				attribute = NULL;
				attribute = scew_attribute_next(element, attribute);

				scew_element_add_attr(rules, attribute);
			}
		}
	}

	if (!*error)
	{
		/*******************
		* lettura record db
		*******************/
		rc = MbeFileOpen_nw(ac_rules_db_path, &handle);
		if (rc != 0)
		{
			log(LOG_ERROR, "Open error file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error file[%s] : %d", ac_rules_db_path, rc);
		}
		else
		{
			//  ------------ DATI  -------------------------------
			rules = scew_element_add(root, "Rules");

			/*******************
			* Cerco il record
			*******************/
			MBE_FILE_SETKEY_( handle, record_soglie.gr_pa , lenKey, 0, GENERIC);
			while ( 1 )
			{
				rc = MbeFileRead_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
						*error = 302;
						sprintf(message, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
					}
					else
					{
						if(contaRec == 0)
						{
							log(LOG_INFO, "Record not found");
							*error = 300;
							sprintf(message, "Record not found");
						}
						else
							rc = 0;
					}
					break;
				}
				else  /*  --------- record TROVATO  ----------*/
				{
					// controllo che se i parametri inseriti nella richiesta coincidano con i dati del DB

					// operatore o gruppo OP
					if(acP_Operator[0] != 0)
					{
						log(LOG_DEBUG2,"acOperator [%s]", acP_Operator);
						// se diverso continua la ricerca altrimenti va avanti
						if ( memcmp(record_soglie.gr_op, acP_Operator, strlen(acP_Operator)) )
							continue;
					}

					//  time From
					if(acP_TimeF[0] != 0)
					{
						log(LOG_DEBUG2,"acTimeF [%s]", acP_TimeF);
						if ( memcmp(record_soglie.fascia_da, acP_TimeF, strlen(acP_TimeF)) )
							continue;
					}

					//  time To
					if(acP_TimeTo[0] != 0)
					{
						log(LOG_DEBUG2,"acTimeTo [%s]", acP_TimeTo);
						if ( memcmp(record_soglie.fascia_a, acP_TimeTo, strlen(acP_TimeTo)) )
							continue;
					}

					// gg settimana
					if(acP_Days[0] != 0)
					{
						log(LOG_DEBUG2,"acDays [%s]", acP_Days);
						if ( memcmp(record_soglie.gg_settimana, acP_Days, strlen(acP_Days)) )
							continue;
					}

					// user type
					if(acP_hexdefuser[0] != 0)
					{

						memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);
						sprintf(ac_hexdefuser, "%08X",user_type_bitmask);
						log(LOG_DEBUG2,"richiesta hexdefuser [%s]  db hexdefuser [%s]  ", acP_hexdefuser, ac_hexdefuser);
						if ( memcmp(ac_hexdefuser, acP_hexdefuser, strlen(acP_hexdefuser)) )
							continue;
					}

					element = scew_element_add(rules, "RULE");

					memset(acCountry,0, sizeof(acCountry));
					memcpy(acCountry, record_soglie.gr_pa, LEN_GRP );
					TrimString(acCountry);

					memset(acOperator,0, sizeof(acOperator));
					memcpy(acOperator, record_soglie.gr_op, LEN_GRP );
					TrimString(acOperator);

					strncpy(acTimeF, record_soglie.fascia_da, 5 );
					acTimeF[5] = 0;
					strncpy(acTimeTo, record_soglie.fascia_a, 5 );
					acTimeTo[5] = 0;
					strncpy(acDays, record_soglie.gg_settimana, 7 );
					acDays[7] = 0;
					sprintf(acSoglia, "%d", record_soglie.soglia );
					sprintf(acPeso, "%d", record_soglie.peso );
					sprintf(acPolitica, "%d", record_soglie.politica );

					scew_element_add_attr_pair(element, "Country", acCountry);
					scew_element_add_attr_pair(element, "Operator", acOperator);
					scew_element_add_attr_pair(element, "TimeFrom", acTimeF);
					scew_element_add_attr_pair(element, "TimeTo", acTimeTo);
					scew_element_add_attr_pair(element, "Days", acDays);

					memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);
					sprintf(acUser, "%08X",user_type_bitmask);
					scew_element_add_attr_pair(element, "UserTypes", acUser);

					scew_element_add_attr_pair(element, "Threshold", acSoglia );
					scew_element_add_attr_pair(element, "Status", (record_soglie.stato == '1' ? "On" : "Off") );
					scew_element_add_attr_pair(element, "Weight", acPeso);
					scew_element_add_attr_pair(element, "Politics", acPolitica );

					contaRec++;
				}
			} //fine while
			MBE_FILE_CLOSE_(handle);
		}
	}

	sprintf(acRecord, "%d", contaRec);
	if (rc == 0)
	{
		strcpy(ac_RS, "200");
		scew_element_add_attr_pair(rules, "Record", acRecord);
	}
	else
		sprintf(ac_RS, "%d", *error);

	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_RS);
	if ( memcmp(ac_RS, "200", 3) )
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	return p_response;
}

// ******************************************************************************
// cancella e visualizza i record in base ai param di richiesta
// ******************************************************************************
scew_tree *del_rule(scew_tree *p_request, short *error, char *message)
{
	short			handle = -1;
	short			handle_rem = -1;
	short 			rc;
	short			lenKey;
	short			contaRec = 0;
	long long		lJTS = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element    *p_request_parameters = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	scew_element    *rules = NULL;

	scew_attribute	*attribute = NULL;

	char			*element_value = NULL;

	char			acP_Operator[LEN_GRP+1];
	char 			acP_TimeF[6];
	char 			acP_TimeTo[6];
	char 			acP_Days[8];
	char			acP_hexdefuser[10];

	int 			user_type_bitmask;
	char 			acCountry[LEN_GRP+1];
	char 			acOperator[LEN_GRP+1];
	char 			acTimeF[6];
	char 			acTimeTo[6];
	char 			acDays[8];
	char			acUser[10];
	char			acSoglia[10];
	char			acPeso[10];
	char			acPolitica[10];
	char 			ac_hexdefuser[10];

	char 			ac_RS[10];
	char			acRecord[10];

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_rem;
	t_ts_soglie_record record_soglie_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_rem, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_backup, ' ', sizeof(record_soglie_backup));
	memset(acCountry, 0, sizeof(acCountry));
	memset(acOperator, 0, sizeof(acOperator));
	memset(acTimeF, 0, sizeof(acTimeF));
	memset(acTimeTo, 0, sizeof(acTimeTo));
	memset(acDays, 0, sizeof(acDays));
	memset(acUser, 0, sizeof(acUser));
	memset(acSoglia, 0, sizeof(acSoglia));
	memset(acPeso, 0, sizeof(acPeso));
	memset(acPolitica, 0, sizeof(acPolitica));
	memset(ac_hexdefuser, 0, sizeof(ac_hexdefuser));

	memset(acP_Operator, 0, sizeof(acP_Operator));
	memset(acP_TimeF, 0, sizeof(acP_TimeF));
	memset(acP_TimeTo, 0, sizeof(acP_TimeTo));
	memset(acP_Days, 0, sizeof(acP_Days));
	memset(acP_hexdefuser, 0, sizeof(acP_hexdefuser));

	memset(ac_RS, 0, sizeof(ac_RS));
	memset(acRecord, 0, sizeof(acRecord));

	log(LOG_DEBUG2, "del_rule");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
	}
	else
	{
		//  legge i parametri Attributi del tag RULE
		if ((p_request_header = get_element(root, "Header", 1, error, message)) &&
			(p_request_parameters = get_element(root, "Parameters", 1, error, message)))
		{
			// Coutry obbligatorio
			memset(acCountry, 0, sizeof(acCountry));
			get_attribute_value(p_request_parameters, "RULE", "Country", acCountry);
			if(acCountry[0] != 0)
			{
				if(strlen(acCountry) > LEN_GRP)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Country");
				}
				else
				{
					memcpy(record_soglie.gr_pa, acCountry, strlen(acCountry));
					lenKey = sizeof(record_soglie.gr_pa);
				}
			}
			else
			{
				*error = 108;
				sprintf(message, "missing <Parameters> <RULE> Country");
			}
			if (!*error)
			{
				memset(acOperator, 0, sizeof(acOperator));
				get_attribute_value(p_request_parameters, "RULE", "Operator", acP_Operator);
				if(acP_Operator[0] != 0)
				{
					if(strlen(acP_Operator) > LEN_GRP)
						memcpy(record_soglie.gr_op, acP_Operator, LEN_GRP);
					else
						memcpy(record_soglie.gr_op, acP_Operator, strlen(acP_Operator));
				}
				get_attribute_value(p_request_parameters, "RULE", "TimeFrom", acP_TimeF);
				if(acP_TimeF[0] != 0)
					memcpy(record_soglie.fascia_da, acP_TimeF, sizeof(record_soglie.fascia_da));

				get_attribute_value(p_request_parameters, "RULE", "TimeTo", acP_TimeTo);
				if(acP_TimeTo[0] != 0)
					memcpy(record_soglie.fascia_a, acP_TimeTo, sizeof(record_soglie.fascia_a));

				get_attribute_value(p_request_parameters, "RULE", "Days", acP_Days);
				if(acP_Days[0] != 0)
					memcpy(record_soglie.gg_settimana, acP_Days, sizeof(record_soglie.gg_settimana));

				get_attribute_value(p_request_parameters, "RULE", "UserTypes", acP_hexdefuser);
				if(acP_hexdefuser[0] != 0)
					sscanf(acP_hexdefuser, "%X", record_soglie.user_type );

				log(LOG_WARNING, "%s|recv|DEL|%s|%s|%s|%s|%s|%s len_key(%d)", remote_addr,
						acCountry, acP_Operator, acP_TimeF, acP_TimeTo, acP_Days, acP_hexdefuser, lenKey);
			}
		}
		else
		{
			*error = 108;
			sprintf(message, "missing <Parametrer> root");
		}
	}

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}

			parameters = scew_element_add(root, "Parameters");
			rules = scew_element_add(parameters, "RULE");
			if ((element = scew_element_by_name(p_request_parameters, "RULE")))
			{
				attribute = NULL;
				attribute = scew_attribute_next(element, attribute);

				scew_element_add_attr(rules, attribute);
			}
		}
	}

	if (!*error)
	{
		/*******************
		* lettura record db
		*******************/
		rc = MbeFileOpen_nw(ac_rules_db_path, &handle);
		if (rc != 0)
		{
			log(LOG_ERROR, "Open error local file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error local file[%s] : %d", ac_rules_db_path, rc);
		}
		else
		{
			rc = MbeFileOpen_nw(ac_rules_db_path_Rem, &handle_rem);
			if (rc != 0)
			{
				log(LOG_ERROR, "Open error remeote file[%s] : %d", ac_rules_db_path_Rem, rc);
				*error = 301;
				sprintf(message, "Open error remote file[%s] : %d", ac_rules_db_path_Rem, rc);
			}
		}
		if(rc == 0)
		{
			//  ------------ DATI  -------------------------------
			rules = scew_element_add(root, "Rules");

			/*******************
			* Cerco il record
			*******************/
			MBE_FILE_SETKEY_( handle, record_soglie.gr_pa , lenKey, 0, GENERIC);
			MBE_FILE_SETKEY_( handle_rem, record_soglie.gr_pa , lenKey, 0, GENERIC);
			while ( 1 )
			{
				rc = MbeFileReadL_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore... */
				if (rc != 0)
				{
					if (rc != 1)
					{
						log(LOG_ERROR, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
						*error = 302;
						sprintf(message, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
					}
					else
					{
						if(contaRec == 0)
						{
							log(LOG_INFO, "Record not found");
							*error = 300;
							sprintf(message, "Record not found");
						}
						else
							rc = 0;
					}
					break;
				}
				else  /*  --------- record TROVATO  ----------*/
				{
					// controllo che se i parametri inseriti nella richiesta coincidano con i dati del DB

					// operatore o gruppo OP
					if(acP_Operator[0] != 0)
					{
						log(LOG_DEBUG2,"acOperator [%s]", acP_Operator);
						// se diverso continua la ricerca altrimenti va avanti
						if ( memcmp(record_soglie.gr_op, acP_Operator, strlen(acP_Operator)) )
							continue;
					}

					//  time From
					if(acP_TimeF[0] != 0)
					{
						log(LOG_DEBUG2,"acTimeF [%s]", acP_TimeF);
						if ( memcmp(record_soglie.fascia_da, acP_TimeF, strlen(acP_TimeF)) )
							continue;
					}

					//  time To
					if(acP_TimeTo[0] != 0)
					{
						log(LOG_DEBUG2,"acTimeTo [%s]", acP_TimeTo);
						if ( memcmp(record_soglie.fascia_a, acP_TimeTo, strlen(acP_TimeTo)) )
							continue;
					}

					// gg settimana
					if(acP_Days[0] != 0)
					{
						log(LOG_DEBUG2,"acDays [%s]", acP_Days);
						if ( memcmp(record_soglie.gg_settimana, acP_Days, strlen(acP_Days)) )
							continue;
					}

					// user type
					if(acP_hexdefuser[0] != 0)
					{

						memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);
						sprintf(ac_hexdefuser, "%08X",user_type_bitmask);
						log(LOG_DEBUG2,"richiesta hexdefuser [%s]  db hexdefuser [%s]  ", acP_hexdefuser, ac_hexdefuser);
						if ( memcmp(ac_hexdefuser, acP_hexdefuser, strlen(acP_hexdefuser)) )
							continue;
					}

					element = scew_element_add(rules, "RULE");

					memset(acCountry,0, sizeof(acCountry));
					memcpy(acCountry, record_soglie.gr_pa, LEN_GRP );
					TrimString(acCountry);

					memset(acOperator,0, sizeof(acOperator));
					memcpy(acOperator, record_soglie.gr_op, LEN_GRP );
					TrimString(acOperator);

					strncpy(acTimeF, record_soglie.fascia_da, 5 );
					acTimeF[5] = 0;
					strncpy(acTimeTo, record_soglie.fascia_a, 5 );
					acTimeTo[5] = 0;
					strncpy(acDays, record_soglie.gg_settimana, 7 );
					acDays[7] = 0;
					sprintf(acSoglia, "%d", record_soglie.soglia );
					sprintf(acPeso, "%d", record_soglie.peso );
					sprintf(acPolitica, "%d", record_soglie.politica );

					scew_element_add_attr_pair(element, "Country", acCountry);
					scew_element_add_attr_pair(element, "Operator", acOperator);
					scew_element_add_attr_pair(element, "TimeFrom", acTimeF);
					scew_element_add_attr_pair(element, "TimeTo", acTimeTo);
					scew_element_add_attr_pair(element, "Days", acDays);

					memcpy((char *)&user_type_bitmask, record_soglie.user_type, 4);
					sprintf(acUser, "%08X",user_type_bitmask);
					scew_element_add_attr_pair(element, "UserTypes", acUser);

					scew_element_add_attr_pair(element, "Threshold", acSoglia );
					scew_element_add_attr_pair(element, "Status", (record_soglie.stato == '1' ? "On" : "Off") );
					scew_element_add_attr_pair(element, "Weight", acPeso);
					scew_element_add_attr_pair(element, "Politics", acPolitica );

					contaRec++;

					//mi salvo il record x eventuale ripristino
					record_soglie_backup= record_soglie;
					rc = MbeFileWriteUU_nw( handle, (char *) &record_soglie, 0 );
					if ( rc)
					{
						log(LOG_ERROR, "Error (%d) in deleting file [%s]", rc, ac_rules_db_path);
						*error = 303;
						sprintf(message, "Error (%d) in deleting file [%s]", rc, ac_rules_db_path);

						MbeUnlockRec_nw(handle);
						break;
					}
					else
					{
						// ********* cancello il REMOTO   *******************
						rc = MbeFileReadL_nw( handle_rem, (char *) &record_rem, (short) sizeof(t_ts_soglie_record) );
						/* errore... */
						if (rc != 0)
						{
							if (rc != 1)
							{
								log(LOG_ERROR, "Error (%d) in reading remote file [%s]", rc, ac_rules_db_path_Rem);
								*error = 302;
								sprintf(message, "Error (%d) in reading remote file [%s]", rc, ac_rules_db_path_Rem);
							}
							else
								rc = 0;
						}
						else  /*  --------- record TROVATO  ----------*/
						{
							rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_rem, 0 );
							if ( rc)
							{
								log(LOG_ERROR, "Error (%d) in deleting remote file [%s]", rc, ac_rules_db_path_Rem);
								*error = 303;
								sprintf(message, "Error (%d) in deleting remote file [%s]", rc, ac_rules_db_path_Rem);

								MbeUnlockRec_nw(handle_rem);
							}
						}
						if(rc != 0)
						{
							//Riscrivo record in LOCALE
							MbeFileWrite_nw( handle, (char *) &record_soglie_backup, (short) sizeof(t_ts_soglie_record) );
							break;
							// non visualizzo eventuali errori in quanto è già stata
							//segnalata anomalia cancellazione db remoto.......
						}
					}
				}
			} //fine while
		}
	}

	sprintf(acRecord, "%d", contaRec);
	if (rc == 0)
	{
		strcpy(ac_RS, "200");
		scew_element_add_attr_pair(rules, "Record", acRecord);
	}
	else
		sprintf(ac_RS, "%d", *error);

	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_RS);
	if (rc == 1)
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	// aggiorno il record con key riempita ad '*' se va male????? son c..zi
	if (rc == 0)
	{
		//GMT
		GetTimeStamp(&lJTS);
		Aggiorna_Soglie_rec_Aster(handle, handle_rem, lJTS, 0, error, message);
	}

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);

	return p_response;
}

// ******************************************************************************
// Inserisce e visualizza il record inserito
// ******************************************************************************
scew_tree *ins_rule(scew_tree *p_request, short *error, char *message)
{
	short			handle = -1;
	short			handle_rem = -1;
	short 			rc = 1;
	short			i = 0;
	unsigned short  nHH = 0;
	unsigned short  nMM = 0;
	int  			iRes = 0;
	long long		lJTS = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element    *p_request_parameters = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	scew_element    *rules = NULL;

	scew_attribute	*attribute = NULL;

	char			*element_value = NULL;

	char 			acP_Country[LEN_GRP+1];
	char			acP_Operator[LEN_GRP+1];
	char 			acP_TimeF[6];
	char 			acP_TimeTo[6];
	char 			acP_Days[8];
	char			acP_hexdefuser[10];
	char			acP_Soglia[10];
	char			acP_Stato[10];
	char			acP_Peso[10];
	char			acP_Politica[10];

	char 			ac_RS[10];
	char			sTmp[500];

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_rem;
	t_ts_soglie_record record_soglie_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_rem, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_backup, ' ', sizeof(record_soglie_backup));

	memset(acP_Country, 0, sizeof(acP_Country));
	memset(acP_Operator, 0, sizeof(acP_Operator));
	memset(acP_TimeF, 0, sizeof(acP_TimeF));
	memset(acP_TimeTo, 0, sizeof(acP_TimeTo));
	memset(acP_Days, 0, sizeof(acP_Days));
	memset(acP_hexdefuser, 0, sizeof(acP_hexdefuser));
	memset(acP_Soglia, 0, sizeof(acP_Soglia));
	memset(acP_Stato, 0, sizeof(acP_Stato));
	memset(acP_Peso, 0, sizeof(acP_Peso));
	memset(acP_Politica, 0, sizeof(acP_Politica));

	memset(ac_RS, 0, sizeof(ac_RS));

	log(LOG_DEBUG2, "ins_rule");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
	}
	else
	{
		//  legge i parametri Attributi del tag RULE
		if ((p_request_header = get_element(root, "Header", 1, error, message)) &&
			(p_request_parameters = get_element(root, "Parameters", 1, error, message)))
		{
			// Coutry obbligatorio
			get_attribute_value(p_request_parameters, "RULE", "Country", acP_Country);
			if(acP_Country[0] != 0)
			{
				if(strlen(acP_Country) > LEN_GRP)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Country");
				}
				else
					memcpy(record_soglie.gr_pa, acP_Country, strlen(acP_Country));
			}
			else
			{
				*error = 108;
				sprintf(message, "missing <Parameters> <RULE> Country");
			}

			if (!*error)
			{
				get_attribute_value(p_request_parameters, "RULE", "Operator", acP_Operator);
				if(acP_Operator[0] != 0)
				{
					if(strlen(acP_Operator) > LEN_GRP)
					{
						*error = 109;
						sprintf(message, "Error <Parameters> <RULE> Operator");
					}
					else
						memcpy(record_soglie.gr_op, acP_Operator, strlen(acP_Operator));
				}
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> Operator");
				}

				get_attribute_value(p_request_parameters, "RULE", "TimeFrom", acP_TimeF);
				if(acP_TimeF[0] != 0)
				{
					strncpy(sTmp, acP_TimeF, 2);
					nHH = (unsigned short) atoi (sTmp);
					strncpy(sTmp, acP_TimeF+3, 2);
					nMM = (unsigned short) atoi (sTmp);
					// metto i : di separazione nel caso fosse stato inserito altro caratter
					acP_TimeF[2] = ':';
					if(nHH < 24 && nMM < 60)
						memcpy(record_soglie.fascia_da, acP_TimeF, sizeof(record_soglie.fascia_da));
					else
					{
						*error = 109;
						sprintf(message, "Error <Parameters> <RULE> TimeFrom");
					}
				}
				else
					memcpy(record_soglie.fascia_da, "00:00", 5);

				get_attribute_value(p_request_parameters, "RULE", "TimeTo", acP_TimeTo);
				if(acP_TimeTo[0] != 0)
				{
					strncpy(sTmp, acP_TimeTo, 2);
					nHH = (unsigned short) atoi (sTmp);
					strncpy(sTmp, acP_TimeTo+3, 2);
					nMM = (unsigned short) atoi (sTmp);
					// metto i : di separazione nel caso fosse stato inserito altro caratter
					acP_TimeF[2] = ':';

					if(nHH < 24 && nMM < 60)
						memcpy(record_soglie.fascia_a, acP_TimeTo, sizeof(record_soglie.fascia_a));
					else
					{
						*error = 109;
						sprintf(message, "Error <Parameters> <RULE> TimeTo");
					}
				}
				else
					memcpy(record_soglie.fascia_a, "23:59", 5);

				get_attribute_value(p_request_parameters, "RULE", "Days", acP_Days);
				if(acP_Days[0] != 0)
				{
					for(i=0; i<=6; i++)
					{
						if( acP_Days[i] != ' ' && acP_Days[i] != 'X' )
						{
							*error = 109;
							sprintf(message, "Error <Parameters> <RULE> Days");
							break;
						}
					}
					memcpy(record_soglie.gg_settimana, acP_Days, sizeof(record_soglie.gg_settimana));
				}
				else
					memcpy(record_soglie.gg_settimana, "XXXXXXX", sizeof(record_soglie.gg_settimana));

				get_attribute_value(p_request_parameters, "RULE", "UserTypes", acP_hexdefuser);
				if(acP_hexdefuser[0] != 0)
					sscanf(acP_hexdefuser, "%X", record_soglie.user_type );
				else
					sscanf(ac_def_hexdefuser, "%X", record_soglie.user_type ); //  acP_hexdefuser letto da file ini

				get_attribute_value(p_request_parameters, "RULE", "Threshold", acP_Soglia);
				if(acP_Soglia[0] != 0)
					record_soglie.soglia = (short) atoi(acP_Soglia);
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> Threshold");
				}

				if(record_soglie.soglia > 100)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Threshold");
				}

				get_attribute_value(p_request_parameters, "RULE", "Status", acP_Stato);
				if(acP_Stato[0] != 0)
				{
					if( !strcasecmp(acP_Stato, "ON")  )
						record_soglie.stato = '1';
					else
						record_soglie.stato = '0';
				}
				else
					record_soglie.stato = '1';

				get_attribute_value(p_request_parameters, "RULE", "Weight", acP_Peso);
				if(acP_Peso[0] != 0)
					record_soglie.peso = (char) atoi(acP_Peso);
				else
					record_soglie.peso = 0;

				if(record_soglie.peso > 15)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Weight");
				}

				get_attribute_value(p_request_parameters, "RULE", "Politics", acP_Politica);
				if(acP_Politica[0] != 0)
					record_soglie.politica = (char) atoi(acP_Politica);
				else
					record_soglie.politica = 1;

				if(record_soglie.politica < 1 || record_soglie.politica > 2)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Politics");
				}

				log(LOG_WARNING, "%s|recv|INS|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", remote_addr,
						acP_Country, acP_Operator, acP_TimeF, acP_TimeTo, acP_Days, acP_hexdefuser, acP_Soglia, acP_Stato, acP_Peso,acP_Politica);
			}
		}
		else
		{
			*error = 108;
			sprintf(message, "missing <Parametrer> root");
		}
	}

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}

			parameters = scew_element_add(root, "Parameters");
			rules = scew_element_add(parameters, "RULE");
			if ((element = scew_element_by_name(p_request_parameters, "RULE")))
			{
				attribute = NULL;
				attribute = scew_attribute_next(element, attribute);

				scew_element_add_attr(rules, attribute);
			}
		}
	}

	if (!*error)
	{
		/*******************
		* lettura record db
		*******************/
		rc = MbeFileOpen_nw(ac_rules_db_path, &handle);
		if (rc != 0)
		{
			log(LOG_ERROR, "Open error local file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error local file[%s] : %d", ac_rules_db_path, rc);
		}
		else
		{
			rc = MbeFileOpen_nw(ac_rules_db_path_Rem, &handle_rem);
			if (rc != 0)
			{
				log(LOG_ERROR, "Open error remeote file[%s] : %d", ac_rules_db_path_Rem, rc);
				*error = 301;
				sprintf(message, "Open error remote file[%s] : %d", ac_rules_db_path_Rem, rc);
			}
		}
		if(rc == 0)
		{
			//mi salvo il record x eventuale ripristino
			record_soglie_backup = record_soglie;

			//  ------------ DATI  -------------------------------
			rules = scew_element_add(root, "Rules");

			rc = controlla_PaeseEgruppi(acP_Country, acP_Operator, error, message);
			if (rc == 0)
					rc = Controlla_Dati(&record_soglie, handle, &iRes, error, message);

			if (rc == 0 )
			{
				rc = MbeFileWrite_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				/* errore */
				if (rc)
				{
					if (rc == 10 )
					{
						sprintf(sTmp, "Error (%d) in writing local file[%s]: KEY already exist", rc, ac_rules_db_path);
						log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
						sprintf(message, "%s", sTmp);
						*error = 305;
					}
					else
					{
						sprintf(sTmp, "Error (%d) in writing local file[%s]", rc, ac_rules_db_path);
						log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
						sprintf(message, "%s", sTmp);
						*error = 304;
					}
				}
				else
				{
					// ********************* INSERISCO RECORD NEL DB REMOTO
					rc = MbeFileWrite_nw( handle_rem, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
					/* errore */
					if (rc)
					{
						if (rc == 10 )
						{
							sprintf(sTmp, "Error (%d) in writing remote file[%s]: KEY already exist", rc, ac_rules_db_path_Rem);
							log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
							sprintf(message, "%s", sTmp);
							*error = 305;
						}
						else
						{
							sprintf(sTmp, "Error (%d) in writing remote file[%s]", rc, ac_rules_db_path_Rem);
							log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
							sprintf(message, "%s", sTmp);
							*error = 304;
						}
					}
				}
			}
			else if (rc == 99 )
			{
				sprintf(sTmp, "Error:  Threshold overlap in Time or Days and User type already used in another Threshold." );
				log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
				sprintf(message, "%s", sTmp);
				*error = 306;
			}
		}
	}

	if (rc == 0)
		strcpy(ac_RS, "200");
	else
		sprintf(ac_RS, "%d", *error);

	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_RS);
	if (rc != 0)
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	// aggiorno il record con key riempita ad '*' se va male????? son c..zi
	if (rc == 0)
	{
		//GMT
		GetTimeStamp(&lJTS);
		Aggiorna_Soglie_rec_Aster(handle, handle_rem, lJTS, 0, error, message);
	}
	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);


	return p_response;
}

// ******************************************************************************
// Modifica e visualizza il record inserito
// ******************************************************************************
scew_tree *upd_rule(scew_tree *p_request, short *error, char *message)
{
	short			handle = -1;
	short			handle_rem = -1;
	short 			rc = 1;
	short 			i = 0;

	long long		lJTS = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element    *p_request_parameters = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;
	scew_element    *rules = NULL;

	scew_attribute	*attribute = NULL;

	char			*element_value = NULL;

	char 			acP_Country[LEN_GRP+1];
	char			acP_Operator[LEN_GRP+1];
	char 			acP_TimeF[6];
	char 			acP_TimeTo[6];
	char 			acP_Days[8];
	char			acP_hexdefuser[10];
	char			acP_Soglia[10];
	char			acP_Stato[10];
	char			acP_Peso[10];
	char			acP_Politica[10];

	char 			ac_RS[10];
	char			sTmp[100];

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_rem;
	t_ts_soglie_record record_soglie_backup;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_rem, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_backup, ' ', sizeof(record_soglie_backup));

	memset(acP_Country, 0, sizeof(acP_Country));
	memset(acP_Operator, 0, sizeof(acP_Operator));
	memset(acP_TimeF, 0, sizeof(acP_TimeF));
	memset(acP_TimeTo, 0, sizeof(acP_TimeTo));
	memset(acP_Days, 0, sizeof(acP_Days));
	memset(acP_hexdefuser, 0, sizeof(acP_hexdefuser));
	memset(acP_Soglia, 0, sizeof(acP_Soglia));
	memset(acP_Stato, 0, sizeof(acP_Stato));
	memset(acP_Peso, 0, sizeof(acP_Peso));
	memset(acP_Politica, 0, sizeof(acP_Politica));

	memset(ac_RS, 0, sizeof(ac_RS));
	memset(sTmp, 0, sizeof(sTmp));

	log(LOG_DEBUG2, "upd_rule");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
	}
	else
	{
		//  legge i parametri Attributi del tag RULE
		if ((p_request_header = get_element(root, "Header", 1, error, message)) &&
			(p_request_parameters = get_element(root, "Parameters", 1, error, message)))
		{
			// Coutry obbligatorio
			get_attribute_value(p_request_parameters, "RULE", "Country", acP_Country);
			if(acP_Country[0] != 0)
			{
				if(strlen(acP_Country) > LEN_GRP)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Country");
				}
				else
					memcpy(record_soglie.gr_pa, acP_Country, strlen(acP_Country));
			}
			else
			{
				*error = 108;
				sprintf(message, "missing <Parameters> <RULE> Country");
			}
			if (!*error)
			{
				get_attribute_value(p_request_parameters, "RULE", "Operator", acP_Operator);
				if(acP_Operator[0] != 0)
				{
					if(strlen(acP_Operator) > LEN_GRP)
					{
						*error = 109;
						sprintf(message, "Error <Parameters> <RULE> Operator");
					}
					else
						memcpy(record_soglie.gr_op, acP_Operator, strlen(acP_Operator));
				}
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> Operator");
				}

				get_attribute_value(p_request_parameters, "RULE", "TimeFrom", acP_TimeF);
				if(acP_TimeF[0] != 0)
					memcpy(record_soglie.fascia_da, acP_TimeF, sizeof(record_soglie.fascia_da));
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> TimeFrom");
				}

				get_attribute_value(p_request_parameters, "RULE", "TimeTo", acP_TimeTo);
				if(acP_TimeTo[0] != 0)
					memcpy(record_soglie.fascia_a, acP_TimeTo, sizeof(record_soglie.fascia_a));
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> TimeTo");
				}

				get_attribute_value(p_request_parameters, "RULE", "Days", acP_Days);
				if(acP_Days[0] != 0)
				{
					for(i=0; i<=6; i++)
					{
						if( acP_Days[i] != ' ' && acP_Days[i] != 'X' )
						{
							*error = 109;
							sprintf(message, "Error <Parameters> <RULE> Days");
							break;
						}
					}
					memcpy(record_soglie.gg_settimana, acP_Days, sizeof(record_soglie.gg_settimana));
				}
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> Days");
				}

				get_attribute_value(p_request_parameters, "RULE", "UserTypes", acP_hexdefuser);
				if(acP_hexdefuser[0] != 0)
					sscanf(acP_hexdefuser, "%X", record_soglie.user_type );
				else
				{
					*error = 108;
					sprintf(message, "missing <Parameters> <RULE> UserTypes");
				}

				get_attribute_value(p_request_parameters, "RULE", "Threshold", acP_Soglia);
				if(atoi(acP_Soglia) > 100)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Threshold");
				}

				get_attribute_value(p_request_parameters, "RULE", "Status", acP_Stato);

				get_attribute_value(p_request_parameters, "RULE", "Weight", acP_Peso);
				if(atoi(acP_Peso) > 15)
				{
					*error = 109;
					sprintf(message, "Error <Parameters> <RULE> Weight");
				}

				get_attribute_value(p_request_parameters, "RULE", "Politics", acP_Politica);
				if(acP_Politica[0] != 0)
				{
					if( (atoi(acP_Politica) < 1 ) || (atoi(acP_Politica) > 2) )
					{
						*error = 109;
						sprintf(message, "Error <Parameters> <RULE> Politics");
					}
				}
				log(LOG_WARNING, "%s|recv|INS|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s", remote_addr,
						acP_Country, acP_Operator, acP_TimeF, acP_TimeTo, acP_Days, acP_hexdefuser, acP_Soglia, acP_Stato, acP_Peso,acP_Politica);
			}
		}
		else
		{
			*error = 108;
			sprintf(message, "missing <Parametrer> root");
		}
	}

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}

			parameters = scew_element_add(root, "Parameters");
			rules = scew_element_add(parameters, "RULE");
			if ((element = scew_element_by_name(p_request_parameters, "RULE")))
			{
				attribute = NULL;
				attribute = scew_attribute_next(element, attribute);

				scew_element_add_attr(rules, attribute);
			}
		}
	}

	if (!*error)
	{
		/*******************
		* lettura record db
		*******************/
		rc = MbeFileOpen_nw(ac_rules_db_path, &handle);
		if (rc != 0)
		{
			log(LOG_ERROR, "Open error local file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error local file[%s] : %d", ac_rules_db_path, rc);
		}
		else
		{
			rc = MbeFileOpen_nw(ac_rules_db_path_Rem, &handle_rem);
			if (rc != 0)
			{
				log(LOG_ERROR, "Open error remeote file[%s] : %d", ac_rules_db_path_Rem, rc);
				*error = 301;
				sprintf(message, "Open error remote file[%s] : %d", ac_rules_db_path_Rem, rc);
			}
		}

		if(rc == 0)
		{
			//mi salvo il record x eventuale ripristino
			record_soglie_backup = record_soglie;

			//  ------------ DATI  -------------------------------
			rules = scew_element_add(root, "Rules");

			log(LOG_DEBUG2,"before updating");

			/*******************
			* Cerco il record
			*******************/
			MBE_FILE_SETKEY_( handle, record_soglie.gr_pa , LEN_KEY_SOGLIE, 0, GENERIC);
			MBE_FILE_SETKEY_( handle_rem, record_soglie.gr_pa , LEN_KEY_SOGLIE, 0, GENERIC);
			rc = MbeFileReadL_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore... */
			if (rc != 0)
			{
				if (rc != 1)
				{
					log(LOG_ERROR, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
					*error = 302;
					sprintf(message, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
				}
				else
				{
					log(LOG_INFO, "Record not found key[%.145s]", record_soglie.gr_pa);
					*error = 300;
					sprintf(message, "Record not found");
				}

			}
			else  /*  --------- record TROVATO  ----------*/
			{
				//mi salvo il record x eventuale ripristino
				record_soglie_backup= record_soglie;

				// aggiorno i dati
				if(acP_Soglia[0] != 0)
					record_soglie.soglia = (short) atoi(acP_Soglia);

				if(acP_Stato[0] != 0)
				{
					if( !strcasecmp(acP_Stato, "ON")  )
						record_soglie.stato = '1';
					else
						record_soglie.stato = '0';
				}

				if(acP_Peso[0] != 0)
					record_soglie.peso = (char) atoi(acP_Peso);

				if(acP_Politica[0] != 0)
					record_soglie.politica = (char) atoi(acP_Politica);


				rc = MbeFileWriteUU_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
				if ( rc)
				{
					log(LOG_ERROR, "Error (%d) in updating file [%s]", rc, ac_rules_db_path);
					*error = 308;
					sprintf(message, "Error (%d) in updating file [%s]", rc, ac_rules_db_path);

					MbeUnlockRec_nw(handle);
				}
				else
				{
					// ********* Aggiorno il REMOTO   *******************
					rc = MbeFileReadL_nw( handle_rem, (char *) &record_rem, (short) sizeof(t_ts_soglie_record) );
					/* errore... */
					if (rc != 0)
					{
						if (rc != 1)
						{
							log(LOG_ERROR, "Error (%d) in reading remote file [%s]", rc, ac_rules_db_path_Rem);
							*error = 302;
							sprintf(message, "Error (%d) in reading remote file [%s]", rc, ac_rules_db_path_Rem);
						}
						else
							rc = 0;
					}
					else  /*  --------- record TROVATO  ----------*/
					{
						rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
						if ( rc)
						{
							log(LOG_ERROR, "Error (%d) in updating remote file [%s]", rc, ac_rules_db_path_Rem);
							*error = 308;
							sprintf(message, "Error (%d) in updating remote file [%s]", rc, ac_rules_db_path_Rem);

							MbeUnlockRec_nw(handle_rem);
						}
					}
					if(rc != 0)
					{
						//Riscrivo record in LOCALE
						rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_soglie_backup, (short) sizeof(t_ts_soglie_record) );
						// non visualizzo eventuali errori in quanto è già stata
						//segnalata anomalia cancellazione db remoto.......
					}
				}
			}
		}
	}
	log(LOG_DEBUG2,"rc=%d-error=%d[%s]", rc, *error, message);

	if (rc == 0)
		strcpy(ac_RS, "200");
	else
		sprintf(ac_RS, "%d", *error);

	element = scew_element_add(parameters, "ResultCode");
	scew_element_set_contents(element, ac_RS);

	if (rc != 0)
	{
		element = scew_element_add(parameters, "Message");
		scew_element_set_contents(element, escape_special_chars(message));
	}

	// aggiorno il record con key riempita ad '*' se va male?????
	if (rc == 0)
	{
		//GMT
		GetTimeStamp(&lJTS);
		Aggiorna_Soglie_rec_Aster(handle, handle_rem, lJTS, 0,error, message);
	}

	MBE_FILE_CLOSE_(handle);
	MBE_FILE_CLOSE_(handle_rem);
	return p_response;
}

// ***********************************************************************************************************************
scew_element *get_element(scew_element *parent, char *element_name, char requested, short *error, char *message)
{
	scew_element *element = NULL;

	log(LOG_DEBUG2, "get_element: %s", element_name);

	if ((parent == NULL) || ((element = scew_element_by_name(parent, element_name)) == NULL))
	{
		if (requested)
		{
			*error = 105;
			sprintf(message, "missing <%s> element", element_name);
		}
	}

	return element;
}

char *get_element_value(scew_element *parent, char *element_name, char requested, short *error, char *message)
{
	scew_element	*element = NULL;
	char			*value = NULL;

	log(LOG_DEBUG2, "get_element_value: %s", element_name);

	if ((element = get_element(parent, element_name, requested, error, message)))
	{
		value = (char *)scew_element_contents(element);
		if (requested)
		{
			if ((value == NULL) || (strlen(value) == 0))
			{
				*error = 105;
				sprintf(message, "missing <%s> contents", element_name);
			}
		}
	}

	return value;
}

void get_attribute_value(scew_element *parent, char *element_name, char *attribute_name, char *attribute_value)
{
	scew_element	*element = NULL;
	scew_attribute	*attribute = NULL;

	if ((element = get_element(parent, element_name, 0, NULL, NULL)))
	{
		attribute = scew_attribute_by_name(element, attribute_name);
		if (attribute)
		{
			strcpy(attribute_value, attribute->value);
		}
		else
		{
			attribute_value[0] = 0x00;
		}
	}
	else
	{
		attribute_value[0] = 0x00;
	}
}




void addXMLTag(scew_element *parent, char *tag_name, char *tag_value, char *format)
{
	scew_element	*element;
	char			*format_type, *format_presence;
	char			format_copy[8];

	if (format)
		strcpy(format_copy, format);
	else
		format_copy[0] = 0x00;

	element = scew_element_add(parent, "DeviceInfo");
	scew_element_add_attr_pair(element, "name", tag_name);

	if ((format_type = strtok(format_copy, ",;:|")))
	{
		format_presence = strtok((char *)NULL, ",;:|");

		if (*format_type == 'C')	// Char (Y|N)
		{
			if (format_presence && !strcasecmp(format_presence, "P"))
			{
				scew_element_add_attr_pair(element, "value", "Y");
			}
			else if ((*tag_value == 'S') || (*tag_value == 'Y') || !strcasecmp(tag_value, "true") || atoi(tag_value))
			{
				scew_element_add_attr_pair(element, "value", "Y");
			}
			else
			{
				scew_element_add_attr_pair(element, "value", "N");
			}
		}
		else if (*format_type == 'B')	// Boolean (0|1)
		{
			if (format_presence && !strcasecmp(format_presence, "P"))
			{
				scew_element_add_attr_pair(element, "value", "1");
			}
			else if ((*tag_value == 'S') || (*tag_value == 'Y') || !strcasecmp(tag_value, "true") || atoi(tag_value))
			{
				scew_element_add_attr_pair(element, "value", "1");
			}
			else
			{
				scew_element_add_attr_pair(element, "value", "0");
			}
		}
		else
		{
			// Transparent value (unsupported format type)
			scew_element_add_attr_pair(element, "value", tag_value);
		}
	}
	else
	{
		// Transparent value (undefined format type)
		scew_element_add_attr_pair(element, "value", tag_value);
	}
}

//*****************************************************************************************
// cerco per key = GR_PA + GR_OP  gli altri campi li controllo per non avere accavallamenti
//*****************************************************************************************
short Controlla_Dati(t_ts_soglie_record *record_soglie, short handle, int *iRes , short *error, char *message)
{
	char		sTmp[500];
	char		ac_Chiave[LEN_GRP+LEN_GRP];
	short		rc = 0;
	short		ggOK, i;
	short		oraOK;
	int			user_type_bitmask_soglie;
	int			user_type_bitmask_appo;

	t_ts_soglie_record record_appo;

	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	memcpy((char *)&user_type_bitmask_soglie, record_soglie->user_type, 4);

	log(LOG_DEBUG2, "INS Controlla dati");
	memcpy(ac_Chiave, record_soglie->gr_pa, sizeof(record_soglie->gr_pa));
	memcpy(ac_Chiave+sizeof(record_soglie->gr_pa), record_soglie->gr_op, sizeof(record_soglie->gr_op));

	/*******************
	* Cerco il record
	*******************/
	MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, GENERIC);

	while ( 1)
	{
		/*******************
		* Leggo i record
		*******************/
		rc = MbeFileRead_nw( handle, (char *) &record_appo, (short) sizeof(t_ts_soglie_record) );
		/* errore... */
		if ( rc)
		{
			if (rc == 1)/* fine file */
				rc = 0;
			else
			{
				sprintf(sTmp, "Error (%d) in reading file [%s]", rc, ac_rules_db_path);
				log(LOG_ERROR, "%s; %s", remote_addr, sTmp);
				sprintf(message, "%s", sTmp);
				*error = 302;
			}
			break;
		}
		else
		{
			ggOK  = 1;
			oraOK = 0;

			//controllo l'orario
			//fasciaDA inserita deve essere max fasciaA e min fasciaDA
			//fasciaA inserita deve essere max  fasciaA e min fasciaDA
			if ( (HHMM2TS(record_soglie->fascia_da) > HHMM2TS(record_appo.fascia_a) ||
				  HHMM2TS(record_soglie->fascia_da) < HHMM2TS(record_appo.fascia_da) )
			 &&
				 (HHMM2TS(record_soglie->fascia_a) > HHMM2TS(record_appo.fascia_a) ||
				  HHMM2TS(record_soglie->fascia_a) < HHMM2TS(record_appo.fascia_da) )
			   )
			{
				oraOK = 1;
			}
			else
			{
				//controllo i giorni della settimana
				for(i = 0; i <= 6 && ggOK; i++)
				{
					if(record_soglie->gg_settimana[i] == 'X' &&
					   record_appo.gg_settimana[i]   == 'X')
					{
						ggOK = 0;
					}
				}
				// se oraOK == 0 &&  ggOK == 1  ->OK
				// se oraOK == 0 &&  ggOK == 0  ->KO
				if( oraOK == 0 &&  ggOK == 0 )
				{
					// dati uguali
					// controllo  utenti
					memcpy((char *)&user_type_bitmask_appo, record_appo.user_type, 4);
					memcpy((char *)&user_type_bitmask_soglie, record_soglie->user_type, 4);

					// se  in entrambi c'è lo stesso bit alzato errore
					*iRes = user_type_bitmask_appo & user_type_bitmask_soglie;
					if( *iRes )
						rc = 99;
					break;
				}
			}
		}

	} // fine while

	return(rc);
}

short controlla_PaeseEgruppi(char *acP_Country, char *acP_Operator, short *error, char *message)
{
	short		handleOP = -1;
	short		rc = 0;
	char		ac_Chiave[18];
	char		sTmp[500];

	t_ts_oper_record record_operatori;

	/* inizializza la struttura tutta a blank */
	memset(&record_operatori, ' ', sizeof( t_ts_oper_record));
	memset(ac_Chiave, ' ', sizeof(ac_Chiave));

	/*******************
	* Apro il file
	*******************/
	rc = Apri_File(acFileOperatori_Loc, &handleOP, 0, 0);
	if (rc == 0)
	{
		MBE_FILE_SETKEY_( handleOP, ac_Chiave, sizeof(ac_Chiave), 0, APPROXIMATE, 0);

		while ( 1 )
		{
			/*******************
			* Leggo il record
			*******************/
			rc = MBE_READX( handleOP, (char *) &record_operatori, (short) sizeof(t_ts_oper_record) );
			if (rc != 0)		/* errore... */
			{
				if (rc != 1)
				{
					sprintf(sTmp, "Error (%d) in reading file [%s]", rc, acFileOperatori_Loc);
					log(LOG_ERROR, "%s; %s", remote_addr, sTmp);
					sprintf(message, "%s", sTmp);
					*error = 302;
				}
				else
				{
					sprintf(message, "Country and/or Operator invalid");
					*error = 307;
				}
				break;
			}
			/* record TROVATO */
			else  /* readx ok */
			{
				//confronto il nome paese
				if( !memcmp(record_operatori.den_paese, acP_Country, strlen(acP_Country)) )
				{
					// paese uguale, controllo codice Operatore
					if( !memcmp(record_operatori.cod_op, acP_Operator, strlen(acP_Operator)) )
						break;
				}
				//confronto il Gruppo paese
				if( !memcmp(record_operatori.gruppo_pa, acP_Country, strlen(acP_Country)) )
				{
					// gruppo paese uguale, controllo gruppo Operatore
					if( !memcmp(record_operatori.gruppo_op, acP_Operator, strlen(acP_Operator)) )
						break;
				}
			}
		}//while
		MBE_FILE_CLOSE_(handleOP);
	}
	return(rc);
}

//******************************************************************************************************
scew_tree *apply_rule(scew_tree *p_request, short *error, char *message)
{
	char		acTime_apply[20];
	char		sTmp[500];
	short		handleSoglie_loc = -1;
	short		handleSoglie_rem = -1;
	short		rc = 0;
	long long	lJTS = 0;

	scew_tree		*p_response = NULL;
	scew_element	*root = NULL;
	scew_element	*p_request_header = NULL;
	scew_element	*header = NULL;
	scew_element	*parameters = NULL;
	scew_element	*element = NULL;

	char			*element_value = NULL;
	char 			ac_RS[10];

	memset(acTime_apply, 0, sizeof(acTime_apply));
	memset(sTmp, 0, sizeof(sTmp));
	memset(ac_RS, 0, sizeof(ac_RS));
	memset(sTmp, 0, sizeof(sTmp));


	log(LOG_DEBUG2, "apply_rule");

	if ((root = scew_tree_root(p_request)) == NULL)
	{
		*error = 105;
		sprintf(message, "missing <Request> root");
	}
	else
	{
		//GMT
		GetTimeStamp(&lJTS);

		rc = MbeFileOpen_nw(ac_rules_db_path, &handleSoglie_loc);
		if (rc == 0)
		{
			rc = MbeFileOpen_nw(ac_rules_db_path_Rem, &handleSoglie_rem);
			if (rc != 0)
			{
				log(LOG_ERROR, "Open error Remote file[%s] : %d", ac_rules_db_path_Rem, rc);
				*error = 301;
				sprintf(message, "Open error Remote file[%s] : %d", ac_rules_db_path_Rem, rc);
			}
		}
		else
		{
			log(LOG_ERROR, "Open error Local file[%s] : %d", ac_rules_db_path, rc);
			*error = 301;
			sprintf(message, "Open error Local file[%s] : %d", ac_rules_db_path, rc);
		}

		if (rc == 0)
			rc = Aggiorna_Soglie_rec_Aster(handleSoglie_loc, handleSoglie_rem, lJTS, 1, error, message);
		if (rc == 0)
		{
			log(LOG_INFO, "%s; Local Apply steering execute", remote_addr);
			*error = 200;
		}
		else
		{
			log(LOG_INFO, "%s; Remote Apply steering execute", remote_addr);
			*error = 200;
		}

		MBE_FILE_CLOSE_(handleSoglie_loc);
		MBE_FILE_CLOSE_(handleSoglie_rem);
	}

	sprintf(ac_RS, "%d", *error);

	// *******************************************************************
	//     Composizione risposta XML
	// *******************************************************************
	p_response = scew_tree_create();
	scew_tree_set_xml_standalone(p_response, 1);
	root = scew_tree_add_root(p_response, "Response");

	//--- Header
	header = scew_element_add(root, "Header");
	if (p_request != NULL)
	{
		if ((element = scew_tree_root(p_request)))
		{
			if ((p_request_header = scew_element_by_name(element, "Header")))
			{
				if ((element = scew_element_by_name(p_request_header, "Service")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "Service");
						scew_element_set_contents(element, element_value);
					}
				}
				if ((element = scew_element_by_name(p_request_header, "OperationType")))
				{
					if ((element_value = (char *)scew_element_contents(element)))
					{
						element = scew_element_add(header, "OperationType");
						scew_element_set_contents(element, element_value);
					}
				}
			}
		}
		parameters = scew_element_add(root, "Parameters");

		element = scew_element_add(parameters, "ResultCode");
		scew_element_set_contents(element, ac_RS);
		if (rc != 0)
		{
			element = scew_element_add(parameters, "Message");
			scew_element_set_contents(element, escape_special_chars(message));
		}
	}
	return p_response;
}

//******************************************************************************************
// nTipo = 0  Aggiornare campo tot_accT  identifica la modifica del DB soglie
// nTipo = 1  Aggiornare campo tot_accP  utilizzato dall'apply e dal TFS Mgr
//
// IPM KTSTEACS : Utilizzo le funzioni per lavorare in modalità nowait (default timeout 2s)
//******************************************************************************************
short Aggiorna_Soglie_rec_Aster(short handle, short handle_rem, long long lJTS, short nTipo, short *error, char *message)
{
	short		rc = 0;
	char		ac_Chiave[LEN_KEY_SOGLIE];
	char		sTmp[500];

	t_ts_soglie_record record_soglie;
	t_ts_soglie_record record_soglie_rem;

	/* inizializza la struttura tutta a blank */
	memset(&record_soglie, ' ', sizeof(t_ts_soglie_record));
	memset(&record_soglie_rem, ' ', sizeof(t_ts_soglie_record));


	memset(ac_Chiave, '*', sizeof(ac_Chiave));

	/*******************
	* Cerco il record
	*******************/
	rc = MBE_FILE_SETKEY_( handle, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);
	rc = MBE_FILE_SETKEY_( handle_rem, ac_Chiave, (short)sizeof(ac_Chiave), 0, EXACT);

	//------------------------- AGGIORNO DB LOCALE ----------------------------------
	rc = MbeFileReadL_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
	if ( rc)
	{
		if(rc == 1)
		{
			memcpy(record_soglie.gr_pa, ac_Chiave, LEN_KEY_SOGLIE);
			//lJTS= JULIANTIMESTAMP(0);
			if(nTipo == 0)
				memcpy(record_soglie.tot_accT, &lJTS, sizeof(long long));
			else
				memcpy(record_soglie.tot_accP, &lJTS, sizeof(long long));

			//--------------------- inserisco il record
			rc = MbeFileWrite_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
			/* errore */
			if (rc)
			{
				sprintf(sTmp, "Error (%d) in writing Local file [%s] - (rec *) ", rc, ac_rules_db_path);
				log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
				sprintf(message, "%s", sTmp);
				*error = 304;
			}
		}
		else
		{
			sprintf(sTmp, "Error (%d) in reading Local file [%s] - (rec *) ", rc, ac_rules_db_path);
			log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
			sprintf(message, "%s", sTmp);
			*error = 302;
		}
	}
	else
	{
		//aggiorno il record con la data attuale
		if(nTipo == 0)
			memcpy(record_soglie.tot_accT, &lJTS, sizeof(long long));
		else
			memcpy(record_soglie.tot_accP, &lJTS, sizeof(long long));

		rc = MbeFileWriteUU_nw( handle, (char *) &record_soglie, (short) sizeof(t_ts_soglie_record) );
		if(rc)
		{
			sprintf(sTmp, "Error (%d) in updating Local file [%s] - (rec *) ", rc, ac_rules_db_path);
			log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
			sprintf(message, "%s", sTmp);
			*error = 308;
			MbeUnlockRec_nw(handle);
		}
	}
	if(rc == 0)
	{
		//------------------------ AGGIORNO DB REMOTE ------------------------------
		rc = MbeFileReadL_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
		/* errore... */
		if ( rc)
		{
			if(rc == 1)
			{
				memcpy(record_soglie_rem.gr_pa, ac_Chiave, LEN_KEY_SOGLIE);
				if(nTipo == 0)
					memcpy(record_soglie_rem.tot_accT, &lJTS, sizeof(long long));
				else
					memcpy(record_soglie_rem.tot_accP, &lJTS, sizeof(long long));

				//--------------------- inserisco il record
				rc = MbeFileWrite_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
				/* errore */
				if (rc)
				{
					sprintf(sTmp, "Error (%d) in writing Remote file [%s] - (rec *) ", rc, ac_rules_db_path_Rem);
					log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
					sprintf(message, "%s", sTmp);
					*error = 304;
				}
			}
			else
			{
				sprintf(sTmp, "Error (%d) in reading Remote file [%s] - (rec *) ", rc, ac_rules_db_path_Rem);
				log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
				sprintf(message, "%s", sTmp);
				*error = 302;
			}
		}
		else
		{
			//aggiorno il record con la data attuale
			if(nTipo == 0)
				memcpy(record_soglie_rem.tot_accT, &lJTS, sizeof(long long));
			else
				memcpy(record_soglie_rem.tot_accP, &lJTS, sizeof(long long));

			rc = MbeFileWriteUU_nw( handle_rem, (char *) &record_soglie_rem, (short) sizeof(t_ts_soglie_record) );
			if(rc)
			{
				sprintf(sTmp, "Error (%d) in updating Remore file [%s] - (rec *) ", rc, ac_rules_db_path_Rem);
				log(LOG_ERROR, "%s; %s",remote_addr, sTmp);
				sprintf(message, "%s", sTmp);
				*error = 308;
				MbeUnlockRec_nw(handle_rem);
			}
		}
	}

	return(rc);
}


