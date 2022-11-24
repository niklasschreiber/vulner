CALL FUNCTION 'CALCULATE_HASH_FOR_RAW' "VIOLAZ Punto 5
  EXPORTING
*   alg = 'SHA1'                " hashalg       Hash Algorithm:
    data =                      " xstring       Data
*   length = 0                  " i
  IMPORTING
    hash =                      " hash160
    hashlen =                   " i
    hashx =                     " hash160x
    hashxlen =                  " i
    hashstring =                " string
    hashxstring =               " xstring
    hashb64string =             " string
  EXCEPTIONS
    UNKNOWN_ALG = 1             "
    PARAM_ERROR = 2             "               Parameter Error
    INTERNAL_ERROR = 3.          "               Unknown Error
	
CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING' "VIOLAZ Punto 5
  EXPORTING
    im_xstring        = xstr
   IM_ENCODING       = 'UTF-8'
 IMPORTING
   EX_STRING         = str.

IF SY-HOST = 'host00'. "VIOLAZ
	WRITE: 'This is the Default HOST '.
ENDIF
CALL METHOD CL_ABAP_SYST=>GET_HOST_NAME(
RECEIVING
HOST_NAME = lv_HOST_NAME )
IF lv_HOST_NAME = ‘Domain1’. “VIOLAZ
	WRITE: 'This is the Default HOST '.
ENDIF
lv_HOST_NAME = CL_ABAP_SYST=>GET_HOST_NAME( ).
IF lv_HOST_NAME = 'Domain1'. “VIOLAZ
	WRITE: 'This is the Default HOST '.
ENDIF
CONSTANTS : G_C_DEV_SYSTEM TYPE SY-SYSID VALUE 'DEV',
G_C_QUA_SYSTEM TYPE SY-SYSID VALUE 'SAN'.
IF SY-SYSID EQ G_C_DEV_SYSTEM. "VIOLAZ G_C_DEV_SYSTEM è una costante
write: 'this the dev system.
elseif SY-SYSID EQ G_C_QUA_SYSTEM. "VIOLAZ G_C_QUA_SYSTEM è una costante
write: 'this is sandbox server
endif.

IF SY-MANDT = 'client01'. "VIOLAZ
	WRITE: 'This is the Default Client '.
ENDIF
client = cl_abap_syst=>get_client( ).
IF client = 'client01'. "VIOLAZ
	WRITE: 'This is the Default Client '.
ENDIF

CALL FUNCTION 'REGISTRY_GET' 
  EXPORTING
	 KEY   = 'DEFAULTREPORT'
  IMPORTING
	 VALUE = test_report. ' test_report Untrusted
INSERT REPORT test_report FROM itab.  "VIOLAZ


CLASS demo IMPLEMENTATION.
  METHOD main.
    LOOP AT itab INTO DATA(wa).
      FIND char IN wa-col1 RESPECTING CASE.
      IF sy-subrc = 0.
        EXIT.  "OK
      ENDIF.
    ENDLOOP.
    FIND to_upper( char ) IN wa-col2 RESPECTING CASE.
    IF sy-subrc <> 0.
      EXIT.                   "VIOLAZ
    ENDIF.
  ENDMETHOD.
  
	TRY.
		cl_demo_output=>display( 1 / 0 ).
	CATCH cx_sy_arithmetic_error INTO DATA(exc). "OK
		cl_demo_output=>display( exc->get_text( ) ).
	ENDTRY.
	
	TRY. "VIOLAZ
		cl_demo_output=>display( 1 / 0 ).
	ENDTRY.


ENDCLASS.


DATA: a type i. 
a = 0.
WHILE a <> 8.
   Write: / 'This is the line:', a.  
   a = a + 1.
   IF a > 8.
 	RETURN. "VIOLAZ
   ENDIF.
ENDWHILE.


DATA: lv_OUT TYPE STRING,
lv_VAL TYPE CSEQUENCE,
lv_other TYPE c.

eid = request->get_form_field( 'eid' ).

CALL METHOD CL_ABAP_DYN_PRG=>ESCAPE_QUOTES(
EXPORTING
VAL = 
RECEIVING
OUT = eid ) "Valore Validato

response->redirect( eid ). "VIOLAZ Open Redirect 

eid = request->get_form_field( 'eid' ).
response->redirect( eid ). "VIOLAZ Open Redirect 

lv_VAL "Valore da validare
"Alternate coding for Method Call with returning parameter
lv_OUT = CL_ABAP_DYN_PRG=>ESCAPE_QUOTES( "lv_VAL è il Valore da validare, lv_OUT  è il Valore Validato
EXPORTING
VAL = lv_VAL ).


CALL FUNCTION 'REGISTRY_GET' "VIOLAZ ABAP_26
  EXPORTING
	 KEY   = 'APPHOME'
  IMPORTING
	 VALUE = home. "home diventa Untrusted


SELECT name
FROM employee
WHERE EXISTS (SELECT * FROM department WHERE department_id = id AND name = 'Marketing'). "VIOLAZ

SELECT *
INTO US_PERSONS
FROM PERSONS
BYPASSING BUFFER "VIOLAZ 
WHERE CITY EQ 'US'.


PERFORM subr USING a1 a2 a3 a4 a5. "VIOLAZ
PERFORM subr CHANGING a1 a2 a3 a4 a5. "OK

TYPES BEGIN OF t_mytable,
    myfield TYPE i
END OF t_mytable.

DATA myworkarea TYPE t_mytable.

DATA mytable TYPE STANDARD TABLE OF t_mytable. "mytable è una STANDARD TABLE

SORT mytable BY myfield.

READ TABLE mytable
    WITH KEY myfield = 42
    INTO myworkarea. "VIOLAZ, non c'è la BINARY SEARCH

DATA mytable TYPE STANDARD TABLE OF t_mytable.

READ TABLE mytable
    WITH KEY myfield = 42
    INTO myworkarea
    BINARY SEARCH. "OK

DATA my_hashed_table TYPE HASHED TABLE OF t_mytable
    WITH UNIQUE KEY myfield.

DATA my_sorted_table TYPE SORTED TABLE OF t_mytable
    WITH UNIQUE KEY myfield.

READ TABLE my_hashed_table
    WITH KEY myfield = 42
    INTO myworkarea. "OK, non è una STANDARD TABLE

READ TABLE my_sorted_table
    WITH KEY myfield = 42
    INTO myworkarea. "OK, non è una STANDARD TABLE

try.
    if ABS( NUMBER ) > 100.
      write / 'Number is large'.
    endif.
 catch CX_ROOT into OREF. "VIOLAZ Avoid catching CX_ROOT
    write / OREF->GET_TEXT( ).
 endtry.


DATA: lo_class TYPE REF TO IF_HTTP_ENTITY.
DATA: lv_DATA TYPE XSTRING,
lv_LENGTH TYPE I,
lv_OFFSET TYPE I,
lv_VIRUS_SCAN_PROFILE TYPE VSCAN_PROFILE,
lv_VSCAN_SCAN_ALWAYS TYPE HTTP_CONTENT_CHECK,
lv_other TYPE c.

lv_DATA = lo_class=>GET_DATA( ). "VIOLAZ

CALL METHOD lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS
RECEIVING
DATA = lv_DATA ). "OK

lv_DATA = lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS ).  "OK


COMMUNICATION INIT "VIOLAZ ABAP_46
  DESTINATION d
  ID         id.
COMMUNICATION ALLOCATE "VIOLAZ
  ID         id.
COMMUNICATION SEND "VIOLAZ
  BUFFER connect_xstr
  ID         id.
COMMUNICATION ACCEPT "VIOLAZ
  ID         id.
COMMUNICATION RECEIVE "VIOLAZ
  BUFFER     connect_ret
  DATAINFO   dat
  STATUSINFO stat
  RECEIVED   len
  ID         id.
b = 'Request'.
COMMUNICATION DEALLOCATE ID id. "VIOLAZ

"VIOLAZ ABAP_44
Data:     i_unescaped type string,
        e_escaped   type string.
call method cl_http_utility=>escape_html  "VIOLAZ
    exporting
      unescaped     = i_unescaped
      keep_num_char_ref = '-'
    receiving
      escaped   = e_escaped.


tra = request->get_form_field( 'report_program' ). "tra untrusted
LEAVE TO TRANSACTION tra AND SKIP FIRST SCREEN. "VIOLAZ ABAP_43


prog = request->get_form_field( 'report_program' ). "prog untrusted
SUBMIT prog. "VIOLAZ ABAP_42


cl_abap_file_utilities=>create_utf8_file_with_bom(
EXPORTING file_name = prog ). "VIOLAZ ABAP_26


prog = request->get_form_field( 'report_program' ). "prog untrusted
DELETE REPORT prog. "VIOLAZ abap_s40

TRY.
	RESULTS = 1 / NUMBER.
CATCH CX1_SY_ZERODIVIDE into OREF. "VIOLAZ
ENDTRY.
TRY.
	RESULTS = 1 / NUMBER.
CATCH CX2_SY_ZERODIVIDE into OREF. "NOK	
CATCH CX3_SY_ZERODIVIDE into OREF. "OK
	TEXT = OREF->GET_TEXT( ).
	cleanup.
	clear RESULT.
ENDTRY.

TRY. 
Submit <your Report Name> with < parameters> and return.
  CATCH <the exception name> INTO oref. 
    text = oref->get_text( ). 
  CATCH cx_root INTO oref. 
    text = oref->get_text( ). 
ENDTRY. 

cl_abap_unit_assert=>assert_equals( exp = 4 act = result ).
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECTION-SCREEN SKIP.
DATA:
  inum1 TYPE i VALUE 1,
  inum2 TYPE i VALUE 3,
  decf  TYPE decfloat34 VALUE 0.
  decf1  TYPE decfloat34 VALUE 1.
  decf2  TYPE decfloat34 VALUE 2.

CASE  inum1 / inum2. "VIOLAZ CWE561SI_LINE_2
  WHEN decf.
	PARAMETERS: lv_bukrs LIKE vimi01-bukrs OBLIGATORY DEFAULT 'EPI'. "lv_bukrs Untrusted
	CALL FUNCTION 'BAPI_EMPLOYEE_GETDATA'
	  EXPORTING
		employee_id      = emp_id
		authority_check  = lv_bukrs   "VIOLAZ Access Control: Authorization Bypass
	  IMPORTING
		return           = ret
	  TABLES
		org_assignment   = org_data
		personal_data    = pers_data
		internal_control = con_data
		communication    = comm_data
		archivelink      = arlink. request->get_form_field

	id = ( 'invoiceID' ). "id Untrusted
	"VIOLAZ ABAP_26
	CONCATENATE `INVOICEID = '` id `'` INTO cl_where. 
	SELECT * "VIOLAZ ABAP_18
		FROM invoices
		INTO CORRESPONDING FIELDS OF TABLE itab_invoices
		WHERE (cl_where).  "VIOLAZ Access Control: Database
	ENDSELECT.

	CALL TRANSACTION 'SA38'. "VIOLAZ ABAP_24

	AUTHORITY-CHECK OBJECT 'S_TCODE' FOR USER v_user "VIOLAZ ABAP_29 e Access Control: Privilege Escalation
	ID 'TCD' FIELD 'SA38'.
	IF sy-subrc = 0.
	CALL TRANSACTION 'SA38'. "OK
	ELSE.

	CALL FUNCTION 'REGISTRY_GET' "VIOLAZ ABAP_26
	  EXPORTING
		 KEY   = 'APPHOME'
	  IMPORTING
		 VALUE = home. 'home UntrustedSXPG_COMMAND_EXECUTE_LONG

	"VIOLAZ ABAP_26
	CONCATENATE home INITCMD INTO cmd. "cmd Untrusted
	CALL 'SYSTEM' ID 'COMMAND' FIELD cmd ID 'TAB' FIELD TABL[]. "VIOLAZ Command Injection

	btype = request->get_form_field( 'backuptype' )
	CONCATENATE `/K 'c:\\util\\rmanDB.bat ` btype `&&c:\\util\\cleanup.bat'` INTO cmd.

	CALL FUNCTION 'SXPG_COMMAND_EXECUTE_LONG'
	  EXPORTING
		commandname                   = cmd_exe
		long_params                   = cmd_string
	  EXCEPTIONS
		no_permission                 = 1
		command_not_found             = 2
		parameters_too_long           = 3
		security_risk                 = 4
		OTHERS                        = 5.

	CALL FUNCTION 'WS_EXECUTE'
	EXPORTING
	PROGRAM = cmd. "VIOLAZ Command Injection
	
	DATA result TYPE TABLE OF btcxpm WITH EMPTY KEY.
	DATA parameters TYPE sxpgcolist-parameters.
	parameters = |-c1 { dbserver }|.
	CALL FUNCTION 'SXPG_CALL_SYSTEM'
	  EXPORTING
		commandname           = cmd "VIOLAZ Command Injection
		additional_parameters = parameters
	  TABLES
		exec_protocol         = result
	  EXCEPTIONS
		no_permission         = 1
		command_not_found     = 2
		security_risk         = 3
		OTHERS                = 4.

	SELECT *
	  FROM employee_records
	  CLIENT SPECIFIED
	  INTO TABLE tab_output
	  WHERE mandt = lv_bukrs. "VIOLAZ ABAP_25 Cross-Client Data Access
	  
	eid = request->get_form_field( 'eid' ).

	response->append_cdata( 'Employee ID: ').
	response->append_cdata( eid ). "VIOLAZ Cross-Site Scripting: Persistent

	CALL METHOD cl_http_utility=>escape_html
	  EXPORTING
		UNESCAPED = eid
		KEEP_NUM_CHAR_REF = '-'
	  RECEIVING
		ESCAPED = e_eid.

	response->append_cdata( 'Employee ID: ').
	response->append_cdata( e_eid ). "VIOLAZ Cross-Site Scripting: Poor Validation

	DATA : BEGIN OF tb_unita OCCURS 0,  "VIOLLAZ ABAP_11
	*         sgenr LIKE viob03-sgenr,        " Edificio
			 gsber LIKE vimi01-gsber,        " Settore Contabile
			 smenr LIKE vimi01-smenr,        " unità di locazione
			 xmetxt LIKE vimi01-xmetxt,
			 snks LIKE vimi01-snks,
			 intreno LIKE vimi01-intreno,
	* INIZIO INS MEV100020 06.12.2012 DM
			 snunr LIKE vimi01-snunr,
	* FINE INS MEV100020 06.12.2012 DM
	*         kostl LIKE cobrb-kostl,
		   END OF tb_unita.

	DATA: BEGIN OF itab_employees,
			eid   TYPE employees-itm,
			name  TYPE employees-name,
		  END OF itab_employees,
		  itab LIKE TABLE OF itab_employees.

	itab_employees-eid = '12'.
	APPEND itab_employees TO itab. "VIOLAZ ABAP_26

	SELECT *
	  FROM employees
	  INTO CORRESPONDING FIELDS OF TABLE itab_employees
	  FOR ALL ENTRIES IN itab
	  WHERE eid = itab-eid.
	ENDSELECT.

	response->append_cdata( 'Employee Name: ').
	response->append_cdata( itab_employees-name ). "VIOLAZ Cross-Site Scripting: Persistent
	
	SELECT SUM( netwr ) FROM ekpo INTO <fs_dc>-ktwrt WHERE ebeln = <fs_dc>-ebeln. "VIOLAZ ABAP_16
	
	LOOP AT itab. "VIOLAZ ABAP_26
		ADD 1 TO vn_riga.
		ADD 1 TO vn_contx.
		FORMAT RESET.
		IF va_colore = 'X'.
		  FORMAT RESET.
		  va_colore = ' '.
		ELSE.
		  FORMAT COLOR 2 INTENSIFIED ON.
		  va_colore = 'X'.
		ENDIF.
	ENDLOOP.
	
	DESCRIBE TABLE itab LINES vn_righe.
	CLEAR itab. REFRESH itab. "VIOLAZ ABAP_06
	READ TABLE itab INDEX 1. "VIOLAZ ABAP_26
	
	IF itab-opbel NE vn_doc.
		wa_err = 'X'.
		CLEAR vn_doc.
		vn_doc = itab-opbel.
		LOOP AT itab WHERE opbel EQ vn_doc. "VIOLAZ ABAP_26
		  itab-flag_err = 'A'.
		  MODIFY itab INDEX sy-tabix. "VIOLAZ ABAP_26
		ENDLOOP.
		MESSAGE s398(00) WITH 'Il primo documento non è progressivo'
						  ' rispetto all''ultimo stampato precedentemente'.
		IF p_test = ' '.
	*      stop.
 
    ENDIF.
	
	usrInput = request->get_form_field( 'seconds' ).
	CALL FUNCTION 'ENQUE_SLEEP'  "VIOLAZ Denial of Service
	  EXPORTING
		SECONDS = usrInput.
		
	user_ops = request->get_form_field( 'operation' ).
	"VIOLAZ ABAP_26
	CONCATENATE: 'PROGRAM zsample.| FORM calculation. |' INTO code_string,
				 calculator_code_begin user_ops calculator_code_end INTO code_string,
				 'ENDFORM.|' INTO code_string.
	REPLACE ALL OCCURRENCES OF '.' IN code_string WITH ''. "VIOLAZ ABAP_17
	SPLIT code_string AT '|' INTO TABLE code_table.
	
	GENERATE SUBROUTINE POOL code_table NAME calc_prog. "VIOLAZ ABAP_15 Dynamic Code Evaluation: Code Injection
	PERFORM calculation IN PROGRAM calc_prog.

	author = ('author')
	response->set_cookie( name = 'author' value = author ). "VIOLAZ Header Manipulation: Cookies

	file_name_out = request->get_form_field( 'filename' ).
	CALL METHOD cl_gui_frontend_services=>file_save_dialog "VIOLAZ Injection05
	  EXPORTING
	*      window_title      = ' '
	*    default_extension = 'CSV'
		default_file_name =   file_name_out
		initial_directory = 'c:temp'
	  CHANGING
		filename          = ld_filename
		path              = ld_path
		fullpath          = ld_fullpath
		user_action       = ld_result.
	*
	CHECK ld_result EQ '0'.
	"VIOLAZ ABAP_26
	CONCATENATE ld_fullpath '.csv' INTO file_name_out_csv.
	CALL FUNCTION 'GUI_DOWNLOAD' "VIOLAZ ABAP_27
        EXPORTING
          filename         = file_name_out_csv
        TABLES
          data_tab         = final_tab
        EXCEPTIONS
          file_open_error  = 1
          file_write_error = 2
          OTHERS           = 3.
    IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

	DATA: lo_hmac TYPE Ref To cl_abap_hmac,
				 Input_string type string.

	CALL METHOD cl_abap_hmac=>get_instance
	  EXPORTING
		if_algorithm = 'SHA1'  "VIOLAZ Cwe327SQL
		if_key       = 'secret_key'  "VIOLAZ Key Management: Hardcoded HMAC Key
	  RECEIVING
		ro_object    = lo_hmac.

	" update HMAC with input
	lo_hmac->update( if_data = input_string ).

	" finalise hmac
	lo_digest->final( ).
	
	CALL METHOD cl_abap_hmac=>get_instance
	  EXPORTING
		if_algorithm = 'SHA3'  
		if_key       = ''  "VIOLAZ Key Management: Empty HMAC Key
	  RECEIVING
		ro_object    = lo_hmac.
		
	" finalise hmac
	lo_digest->final( ).
	
	Data: lv_data          TYPE string
      lv_data_xstr     TYPE xstring,
      lv_iv            TYPE xstring,
      lv_key           TYPE xstring,
      lv_encrypted_str TYPE xstring.

	** Empty Encryption Key
	lv_key = ''.

	** Data String
	lv_data = 'Information that needs to be Encrypted'.

	** Converting the string to XSTRING format
	lv_data_xstr = cl_bcs_convert=>string_to_xstring( iv_string = lv_data ).

	** Define the initialization vector.
	lv_iv = '00000000000000000000000000000000'.

	** Data Encryption
	cl_sec_sxml_writer=>encrypt_iv(
			 exporting
           plaintext  = lv_data_xstr
           key        = lv_key  "VIOLAZ Empty Encryption Key 
           iv         = lv_iv
           algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm_pem
         importing
           ciphertext = lv_encrypted_str  ).


	DATA log_msg TYPE bal_s_msg.

	val = request->get_form_field( 'val' ).

	log_msg-msgid = 'XY'.
	log_msg-msgty = 'E'.
	log_msg-msgno = '123'.
	log_msg-msgv1 = 'VAL: '.
	log_msg-msgv2 = val.

	CALL FUNCTION 'BAL_LOG_MSG_ADD' "VIOLAZ Injection19 Log Forging
	  EXPORTING
		I_S_MSG          = log_msg  
	  EXCEPTIONS                    "VIOLAZ ABAP_12
		LOG_NOT_FOUND    = 1
		MSG_INCONSISTENT = 2		"OK, non dà CWECONST
		LOG_IS_FULL      = 3		"OK, non dà CWECONST
		OTHERS           = 4.		"OK, non dà CWECONST

	DATA: str_dest TYPE c.

	str_dest = request->get_form_field( 'dest' ).
	response->redirect( str_dest ). "VIOLAZ Open Redirect

	*Get the report that is to be deleted
	r_name = request->get_form_field( 'report_name' ).
	"VIOLAZ ABAP_26
	CONCATENATE `C:\\users\\reports\\` r_name INTO dsn.  "VIOLAZ Securitymisc18
	DELETE DATASET dsn. "VIOLAZ Path Manipulation

	PARAMETERS: p_date TYPE string.

	*Get the invoice file for the date provided
	CALL FUNCTION 'FILE_GET_NAME'
	  EXPORTING
		logical_filename        = 'INVOICE'
		parameter_1             = p_date
	  IMPORTING
		file_name               = v_file
	  EXCEPTIONS
		file_not_found          = 1
		OTHERS                  = 2.
	IF sy-subrc <> 0.
	* Implement suitable error handling here
	ENDIF.

	OPEN DATASET v_file FOR INPUT IN TEXT MODE. "VIOLAZ Path Manipulation


	uid = 'scott'.
	password = 'tiger'. "VIOLAZ Hardcoded Password
	WRITE: / 'Default username for FTP connection is: ', uid.  "VIOLAZ Privacy Violation
	WRITE: / 'Default password for FTP connection is: ', password. "VIOLAZ Privacy Violation

	tid = request->get_form_field( 'tid' ).

	CALL TRANSACTION tid USING bdcdata  MODE 'N'
							 MESSAGES INTO messtab. "VIOLAZ ABAP_24 e Process Control
							 
	host_name = request->get_form_field( 'host' ). "host_name Untrusted
	CALL FUNCTION 'FTP_CONNECT' "VIOLAZ Resource Injection 
		 EXPORTING
		   USER            = user
		   PASSWORD        = password
		   HOST            = host_name 
		   RFC_DESTINATION = 'SAPFTP'
		 IMPORTING
		   HANDLE          = mi_handle
		 EXCEPTIONS						"VIOLAZ ABAP_12
		   NOT_CONNECTED   = 1
		   OTHERS          = 2.         "OK, non dà CWECONST

	v_account = request->get_form_field( 'account' ).
	v_reference = request->get_form_field( 'ref_key' ).

	CONCATENATE `user = '` sy-uname `'` INTO cl_where.
	IF v_account IS NOT INITIAL.
	CONCATENATE cl_where ` AND account = ` v_account INTO cl_where SEPARATED BY SPACE.
	ENDIF.
	IF v_reference IS NOT INITIAL.
	CONCATENATE cl_where `AND ref_key = '` v_reference `'` INTO cl_where.
	ENDIF.

	SELECT *  "VIOLAZ ABAP_18
		FROM invoice_items
		INTO CORRESPONDING FIELDS OF TABLE itab_items
		WHERE (cl_where). "VIOLAZ SQL Injection

	CALL FUNCTION 'FTP_VERSION'
	  
	  IMPORTING
		EXEPATH     = p
		VERSION     = v
		WORKING_DIR = dir
		RFCPATH     = rfcp
		RFCVERSION  = rfcv
	  TABLES
		FTP_TRACE =                 FTP_TRACE.

	*VIOLAZ System Information Leak
	WRITE: 'exepath: ', p, 'version: ', v, 'working_dir: ', dir, 'rfcpath: ', rfcp, 'rfcversion: ', rfcv.
	CALL FUNCTION 'BAL_LOG_MSG_ADD' 
	  EXPORTING
		I_S_MSG          = v   "VIOLAZ System Information Leak
	  EXCEPTIONS                    
		LOG_NOT_FOUND    = 1
		MSG_INCONSISTENT = 2		
		LOG_IS_FULL      = 3		
		OTHERS           = 4.	

	DATA: obj TYPE REF TO cl_abap_hmac,
				 input_string type string.

	CALL METHOD cl_abap_hmac=>get_instance
	  EXPORTING
		if_key    = 'ABCDEFG123456789'
	  RECEIVING
		ro_object = obj.

	obj->final( ). "VIOLAZ Weak Cryptographic Hash: Missing Required Step. Manca la obj->update( if_data = input_string ).	
	
	CALL METHOD cl_abap_hmac=>get_instance
	  EXPORTING
		if_key    = 'ABCDEFG123456789'
	  RECEIVING
		ro_object = obj.
	obj->update( if_data = input_string ).
	obj->final( ). "OK	

	DATA(lv_algo) = |MD5|. "VIOLAZ Weak Cryptographic Hash

	data: random          type xstring, wa_bench_config type   zhr_bench_config.
	  call method cl_sec_sxml_writer=>generate_key
		  exporting
			algorithm = cl_sec_sxml_writer=>co_aes128_algorithm "VIOLAZ Weak Encryption. Lo da per: co_aes128_algorithm co_aes192_algorithm co_alg_md5 co_alg_sha1
		  receiving
			key       = random.
		data(lr_conv_key) = cl_abap_conv_out_ce=>create( ).

		lr_conv_key->write( data = random ).
		e_key = lr_conv_key->get_buffer( ).
		
		CASE sy-ucomm.  "VIOLAZ CWE561SC
		  WHEN 'BACK'.
			LEAVE TO SCREEN 100. 
		  WHEN OTHERS.
			MESSAGE '...' TYPE 'E'.
		ENDCASE.	
		
		CASE sy-ucomm.  "VIOLAZ ABAP_07
		  WHEN 'BACK'.
			LEAVE TO SCREEN 100. 
		  WHEN 'NEXT'.
			MESSAGE '...' TYPE 'E'.
		ENDCASE.	

    cl_demo_output=>write_text( 'In CASE equal' ).
  WHEN decf1.
	cl_demo_output=>display( ).
  WHEN decf2.
	cl_demo_output=>display( ).
ENDCASE.

DATA: STRENGTH TYPE i, SANITY TYPE i.

RF_IS_A_MONSTER = ( STRENGTH > 100 AND SANITY < 20) "VIOLAZ CWECONST

CASE STRENGTH-SANITY.
	WHEN 5. 
		cs_monster_header-sanity_description = 'VERY SANE'.
	WHEN 4. 
		cs_monster_header-sanity_description = 'SANE'.
	WHEN 3. 
		cs_monster_header-sanity_description = 'SLIGHTLY MAD'.
	WHEN 2. 
		cs_monster_header-sanity_description = 'VERY MAD'.
	WHEN 1. "VIOLAZ ABAP_22
		
	WHEN OTHERS.
		cs_monster_header-sanity_description = 'RENAMES SAP PRODUCTS'.

ENDCASE.

CASE STRENGTH-SANITY. "VIOLAZ CWE561SI_LINE_1
	WHEN 15. 
		cs_monster_header-sanity_description = 'VERY SANE'.
		DATA remainder TYPE i, NUMBER1 TYPE i, NUMBER2 TYPE i, NUMBER3 TYPE i.
		lbl1: DO 20 TIMES.
		  remainder = sy-index MOD 2.
		  IF remainder <> 0.
			IF remainder > 0.  
			   IF remainder >20.   "VIOLAZ CWE691MORE
				  Write 'Yes, It's Correct'.
				  IF ( NUMBER1 = NUMBER2 AND NUMBER1 = NUMBER3 ).
					WRITE 'ALL NUMBERS ARE EQUAL'.
				  ELSEIF ( NUMBER1 > NUMBER2 ).
				  IF ( NUMBER1 > NUMBER3 ).
					WRITE:'bIGGEST NUMBER IS,NUMBER1',NUMBER1.
				  ENDIF.
				  ELSEIF ( NUMBER2 > NUMBER3 ).
					WRITE:'BIGGEST NUMBER IS NUMBER2',NUMBER2.
				  ELSE.
					WRITE:'BIGGEST NUMBER IS NUMBER3',NUMBER3.
				  ENDIF.
			   ELSE.
				  IF ( NUMBER1 = NUMBER1 ). "VIOLAZ CWE561P16
					WRITE 'TWO OPERANDS ARE EQUAL'.
				  ELSEIF ( NUMBER1 > NUMBER1 ). "VIOLAZ CWE570P2
				  IF ( 1 = 2 ). "VIOLAZ CWE570P2
					GOTO lbl1.  "VIOLAZ CE10
				  ENDIF.
				  ELSEIF ( NUMBER2 > NUMBER3 ).
					WRITE:'BIGGEST NUMBER IS NUMBER2',NUMBER2.
				  ELSE.
					WRITE:'BIGGEST NUMBER IS NUMBER3',NUMBER3.
				  ENDIF.
			   ENDIF.
			ELSE.  
				Write 'Sorry, It's Wrong'. 
			ENDIF.
			lbl2: CONTINUE.  "VIOLAZ CWE561P2
		  ENDIF.
		  cl_demo_output=>write_text( |{ sy-index }| ).
		ENDDO.
	WHEN 14. 
		cs_monster_header-sanity_description = 'SANE'.
	WHEN OTHERS.
		cs_monster_header-sanity_description = 'RENAMES SAP PRODUCTS'.

ENDCASE.


data: year TYPE coss-gjahr value '2007'.
 
DATA: t_output  TYPE STANDARD TABLE OF st_impos WITH HEADER LINE,
      st_output TYPE st_impos,
      t_output2 TYPE STANDARD TABLE OF st_impos WITH HEADER LINE,
      st_output2 TYPE st_impos.
 
SELECT objnr gjahr kstar FROM coss
INTO CORRESPONDING FIELDS OF st_output
WHERE ( objnr LIKE 'NV%' OR
      objnr LIKE 'PR%' ) AND
       gjahr = year.
   SELECT SINGLE projn from afvc into CORRESPONDING FIELDS OF st_output
       WHERE objnr = st_output-objnr. "VIOLAZ ABAP_33
 APPEND st_output to t_output.
 ENDSELECT.

DATA remainder TYPE i.
DO 20 TIMES.
  remainder = sy-index MOD 2.
  cl_demo_output=>write_text( |{ sy-index }| ).
  CONTINUE. "VIOLAZ CWE561_CONTINUE
ENDDO.

FORM get_contract  USING    p_ebeln TYPE ebeln
                   CHANGING p_konnr TYPE konnr.

  CLEAR p_konnr.
  IF p_ebeln NA space.
    SELECT SINGLE konnr FROM ekab INTO p_konnr WHERE ebeln = p_ebeln
      %_HINTS ORACLE 'index(ekab"Z01")'.                  "VIOLAZ ABAP_10
  ENDIF.

ENDFORM.

FORM scarico_excel.
  PERFORM formatta_data.
  CALL FUNCTION 'WS_EXCEL' "VIOLAZ ABAP_26
    EXPORTING
      filename = ' '
      synchron = ' '
    TABLES
      data     = itab.
   
   
*  CALL FUNCTION 'RH_START_EXCEL_WITH_DATA'
*      EXPORTING
*           CHECK_VERSION       = ' '
*           DATA_NAME           = 'Registro Iva '
*           DATA_PATH_FLAG      = 'W'
*           DATA_TYPE           = 'DAT'
**         DATA_BIN_FILE_SIZE  =
**         MACRO_NAME          = ' '
**         MACRO_PATH_FLAG     = ' '
**         FORCE_START         = ' '
**         WAIT                = 'X'
**    IMPORTING
**         WINID               =
*      TABLES
*           DATA_TAB            = ITAB.

   
   
ENDFORM. 

"VIOLAZ CWE398LONG
FORM GenerateReceiptURLComingFromExternalSource CHANGING baseUrl TYPE string.  
    DATA: r TYPE REF TO cl_abap_random, "VIOLAZ ABAP_31 e CWE398SHORT (oggetto r)
		  seed1 TYPE i,
		  var1 TYPE i,
		  var2 TYPE i,
		  var3 TYPE n.


	GET TIME.
	var1 = sy-uzeit.
	r = cl_abap_random=>create( seed = var1 ). "VIOLAZ ABAP_31
	r = cl_abap_random=>create( seed = '1234' ). "VIOLAZ ABAP_31 Insecure Randomness: Hardcoded Seed
	seed1 = request->get_form_field( 'seed' ).
	r = cl_abap_random=>create( seed = seed1 ). "VIOLAZ ABAP_31 Insecure Randomness: User-Controlled Seed
	r->int31( RECEIVING value = var2 ).
	var3 = var2.
    CONCATENATE baseUrl var3 ".html" INTO baseUrl.
ENDFORM.

METHOD show_list. "VIOLAZ CWE398RETURN, troppe RETURN
  "IMPORTING structure TYPE c
  "          data_tab  TYPE ANY TABLE.
  DATA alv_list TYPE REF TO cl_gui_alv_grid.
  IF structure IS INITIAL OR
     data_tab  IS INITIAL.
    RETURN.
  ENDIF.
  CREATE OBJECT alv_list
         EXPORTING i_parent = cl_gui_container=>screen0.
  alv_list->set_table_for_first_display(
    EXPORTING i_structure_name = structure
    CHANGING  it_outtab        = data_tab ).
  CALL SCREEN 100.
  DATA remainder TYPE i, NUMBER1 TYPE i, NUMBER2 TYPE i, NUMBER3 TYPE i.
	DO 20 TIMES.
	  remainder = sy-index MOD 2.
	  IF remainder <> 0.
		IF remainder > 0.  
		   IF remainder >20.   "VIOLAZ CWE691MORE
			  Write 'Yes, It's Correct'.
			  IF ( NUMBER1 = NUMBER2 AND NUMBER1 = NUMBER3 ).
				RETURN.
			  ELSEIF ( NUMBER1 > NUMBER2 ).
			  IF ( NUMBER1 > NUMBER3 ).
				RETURN.
			  ENDIF.
			  ELSEIF ( NUMBER2 > NUMBER3 ).
				RETURN.
			  ELSE.
				RETURN NULL. "VIOLAZ ReturnNull
			  ENDIF.. "VIOLAZ CWE570P1 doppio punto alla fine
		   ELSE.
			  IF ( NUMBER1 = NUMBER1 ). "VIOLAZ CWE561P16
				WRITE 'TWO OPERANDS ARE EQUAL'.
			  ELSEIF ( NUMBER1 > NUMBER1 ). "VIOLAZ CWE570P2
			  IF ( 1 = 2 ). "VIOLAZ CWE570P2 gli operandi sono due numeri diversi
				GOTO lbl1.  "VIOLAZ CE10
				WRITE:'For Debug purposes'. "VIOLAZ CWE561P18 Code is unreachable
			  ENDIF.
			  ELSEIF ( 1 = 1 ). "VIOLAZ CWE561P16 gli operandi sono due numeri uguali
				WRITE:'FOr debugginf purposes'.
			  ELSE.
				WRITE:'BIGGEST NUMBER IS NUMBER3',NUMBER3.
			  ENDIF.
		   ENDIF.
		ELSE.  
			Write 'Sorry, It's Wrong'. 
		ENDIF.
		lbl1: CONTINUE.  
	  ENDIF.
	  cl_demo_output=>write_text( |{ sy-index }| ).
	ENDDO.
ENDMETHOD.

FORM browse_appl_serv  USING    p_s TYPE char1
                       CHANGING p_sfile TYPE rlgrap-filename.
  CHECK p_s IS NOT INITIAL.
  CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE' "VIOLAZ Securitymisc18
    IMPORTING
      serverfile       = p_sfile
    EXCEPTIONS
      canceled_by_user = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Interruzione anomala del programma!' TYPE 'E'.
  ENDIF.

ENDFORM. 

*VIOLAZ Securitymisc19
*      CONCATENATE 'C:\Somme_liquidate_' lv_aaaammgg '.CSV' INTO lv_file. 
*VIOLAZ CommentOutCode
*METHOD show_list_cpommented. 
*  "IMPORTING structure TYPE c
*  "          data_tab  TYPE ANY TABLE.
*  DATA alv_list TYPE REF TO cl_gui_alv_grid.
*  IF structure IS INITIAL OR
*     data_tab  IS INITIAL.
*    RETURN.
*  ENDIF.
*  CREATE OBJECT alv_list
*         EXPORTING i_parent = cl_gui_container=>screen0.
*  alv_list->set_table_for_first_display(
*    EXPORTING i_structure_name = structure
*    CHANGING  it_outtab        = data_tab ).
*  CALL SCREEN 100.
*  DATA remainder TYPE i, NUMBER1 TYPE i, NUMBER2 TYPE i, NUMBER3 TYPE i.
*	DO 20 TIMES.
*	  remainder = sy-index MOD 2.
*	  IF remainder <> 0.
*		IF remainder > 0.  
*		   IF remainder >20.   
*			  Write 'Yes, It's Correct'.
*			  IF ( NUMBER1 = NUMBER2 AND NUMBER1 = NUMBER3 ).
*				RETURN.
*			  ELSEIF ( NUMBER1 > NUMBER2 ).
*			  IF ( NUMBER1 > NUMBER3 ).
*				RETURN.
*			  ENDIF.
*			  ELSEIF ( NUMBER2 > NUMBER3 ).
*				RETURN.
*			  ELSE.
*				RETURN.
*			  ENDIF.. 
*		   ELSE.
*			  IF ( NUMBER1 = NUMBER1 ). 
*				WRITE 'TWO OPERANDS ARE EQUAL'.
*			  ELSEIF ( NUMBER1 > NUMBER1 ). "
*			  IF ( 1 = 2 ). 
*				GOTO lbl1.  
*				WRITE:'For Debug purposes'. "
*			  ENDIF.
*			  ELSEIF ( NUMBER2 > NUMBER3 ).
*				WRITE:'BIGGEST NUMBER IS NUMBER2',NUMBER2.
*			  ELSE.
*				WRITE:'BIGGEST NUMBER IS NUMBER3',NUMBER3.
*			  ENDIF.
*		   ENDIF.
*		ELSE.  
*			Write 'Sorry, It's Wrong'. 
*		ENDIF.
*		lbl1: CONTINUE.  
*	  ENDIF.
*	  cl_demo_output=>write_text( |{ sy-index }| ).
*	ENDDO.
*ENDMETHOD.


CLASS demo IMPLEMENTATION.
  METHOD main.
    LOOP AT itab INTO DATA(wa).
      FIND char IN wa-col1 RESPECTING CASE.
      IF sy-subrc = 0.
        EXIT.  "OK
      ENDIF.
    ENDLOOP.
    FIND to_upper( char ) IN wa-col2 RESPECTING CASE.
    IF sy-subrc <> 0.
      EXIT.                   "VIOLAZ Punto 7
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CALL FUNCTION 'CALCULATE_HASH_FOR_RAW' "VIOLAZ Punto 5
  EXPORTING
*   alg = 'SHA1'                " hashalg       Hash Algorithm:
    data =                      " xstring       Data
*   length = 0                  " i
  IMPORTING
    hash =                      " hash160
    hashlen =                   " i
    hashx =                     " hash160x
    hashxlen =                  " i
    hashstring =                " string
    hashxstring =               " xstring
    hashb64string =             " string
  EXCEPTIONS
    UNKNOWN_ALG = 1             "
    PARAM_ERROR = 2             "               Parameter Error
    INTERNAL_ERROR = 3.          "               Unknown Error
	
CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING' "VIOLAZ Punto 5
  EXPORTING
    im_xstring        = xstr
   IM_ENCODING       = 'UTF-8'
 IMPORTING
   EX_STRING         = str.
   
  write str+300(10).
  
DATA: a type i. 
a = 0.
WHILE a <> 8.
   Write: / 'This is the line:', a.  
   a = a + 1.
   IF a > 8.
 	RETURN. "VIOLAZ Punto 6
   ENDIF.
ENDWHILE.

TRY.
    cl_demo_output=>display( 1 / 0 ).
  CATCH cx_sy_arithmetic_error INTO DATA(exc). "OK
    cl_demo_output=>display( exc->get_text( ) ).
ENDTRY.
TRY. "VIOLAZ Punto 8
    cl_demo_output=>display( 1 / 0 ).
ENDTRY.

CALL METHOD cl_http_utility=>escape_html "VIOLAZ Punto 9
	  EXPORTING
		UNESCAPED = eid
		KEEP_NUM_CHAR_REF = '-'
	  RECEIVING
		ESCAPED = e_eid.
		
REFRESH itab. "VIOLAZ Punto 10

SUBTRACT-CORRESPONDING struc1 FROM struc2. "VIOLAZ Punto 10

CONCATENATE `INVOICEID = '` id `'` INTO cl_where. "VIOLAZ Punto 11

cl_abap_unit_assert=>assert_equals( exp = 4 act = result ). "VIOLAZ Punto 13

TRY.
	RESULTS = 1 / NUMBER.
CATCH CX_SY_ZERODIVIDE into OREF. "VIOLAZ Punto 15
ENDTRY.
TRY.
	RESULTS = 1 / NUMBER.
CATCH CX_SY_ZERODIVIDE into OREF. "OK
	TEXT = OREF->GET_TEXT( ).
	cleanup.
	clear RESULT.
ENDTRY.

CALL FUNCTION 'REGISTRY_GET' 
  EXPORTING
	 KEY   = 'DEFAULTREPORT'
  IMPORTING
	 VALUE = test_report. ' test_report Untrusted
INSERT REPORT test_report FROM itab.  "VIOLAZ Punto 16

prog = request->get_form_field( 'report_program' ). "prog untrusted
DELETE REPORT prog. "VIOLAZ Punto 17

cl_abap_file_utilities=>create_utf8_file_with_bom(
EXPORTING file_name = prog ). "VIOLAZ Punto 18

SUBMIT prog. "VIOLAZ Punto 19

tra = request->get_form_field( 'report_program' ). "tra untrusted
LEAVE TO TRANSACTION tra AND SKIP FIRST SCREEN. "VIOLAZ Punto 20

Data:     i_unescaped type string,
        e_escaped   type string.
call method cl_http_utility=>escape_html  "VIOLAZ Punto 21
    exporting
      unescaped     = i_unescaped
      keep_num_char_ref = '-'
    receiving
      escaped   = e_escaped.

COMMUNICATION INIT "VIOLAZ Punto 25
  DESTINATION d
  ID         id.
COMMUNICATION ALLOCATE "VIOLAZ  Punto 25
  ID         id.
COMMUNICATION SEND "VIOLAZ Punto 25
  BUFFER connect_xstr
  ID         id.
COMMUNICATION ACCEPT "VIOLAZ Punto 25
  ID         id.
COMMUNICATION RECEIVE "VIOLAZ Punto 25
  BUFFER     connect_ret
  DATAINFO   dat
  STATUSINFO stat
  RECEIVED   len
  ID         id.
b = 'Request'.
COMMUNICATION DEALLOCATE ID id. "VIOLAZ Punto 25

DATA: lo_class TYPE REF TO IF_HTTP_ENTITY.
DATA: lv_DATA TYPE XSTRING,
lv_LENGTH TYPE I,
lv_OFFSET TYPE I,
lv_VIRUS_SCAN_PROFILE TYPE VSCAN_PROFILE,
lv_VSCAN_SCAN_ALWAYS TYPE HTTP_CONTENT_CHECK,
lv_other TYPE c.

lv_DATA = lo_class=>GET_DATA( ). "VIOLAZ Punto 26

CALL METHOD lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS
RECEIVING
DATA = lv_DATA ). "OK

lv_DATA = lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS ).  "OK

IF SY-HOST = 'host00'. "VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
CALL METHOD CL_ABAP_SYST=>GET_HOST_NAME(
RECEIVING
HOST_NAME = lv_HOST_NAME )
IF lv_HOST_NAME = 'Domain1'. "VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
lv_HOST_NAME = CL_ABAP_SYST=>GET_HOST_NAME( ).
IF lv_HOST_NAME = 'Domain1'. "VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
CONSTANTS : G_C_DEV_SYSTEM TYPE SY-SYSID VALUE 'DEV',
G_C_QUA_SYSTEM TYPE SY-SYSID VALUE 'SAN'.
IF SY-SYSID EQ G_C_DEV_SYSTEM. "VIOLAZ Punto 27 G_C_DEV_SYSTEM è una costante
write: 'this the dev system.
elseif SY-SYSID EQ G_C_QUA_SYSTEM. "VIOLAZ Punto 27 G_C_QUA_SYSTEM è una costante
write: 'this is sandbox server
endif.

IF SY-MANDT = 'client01. "VIOLAZ Punto 28
	WRITE: 'This is the Default Client '.
ENDIF
client = cl_abap_syst=>get_client( ).
IF client = 'client01'. "VIOLAZ Punto 28
	WRITE: 'This is the Default Client '.
ENDIF

*Get the invoice file for the date provided
CALL FUNCTION 'FILE_GET_NAME'
  EXPORTING
	logical_filename        = 'INVOICE'
	parameter_1             = p_date
  IMPORTING
	file_name               = v_file
  EXCEPTIONS
	file_not_found          = 1
	OTHERS                  = 2.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

OPEN DATASET v_file FOR INPUT IN TEXT MODE. "NO VIOLAZ validata da FILE_GET_NAME

try.
    if ABS( NUMBER ) > 100.
      write / 'Number is large'.
    endif.
 catch CX_ROOT into OREF. "VIOLAZ Avoid catching CX_ROOT
    write / OREF->GET_TEXT( ).
 endtry.

TYPES BEGIN OF t_mytable,
    myfield TYPE i
END OF t_mytable.

DATA myworkarea TYPE t_mytable.

DATA mytable TYPE STANDARD TABLE OF t_mytable. "mytable è una STANDARD TABLE

SORT mytable BY myfield.

READ TABLE mytable
    WITH KEY myfield = 42
    INTO myworkarea. "VIOLAZ Standard tables searched without BINARY SEARCH

DATA mytable TYPE STANDARD TABLE OF t_mytable.

READ TABLE mytable
    WITH KEY myfield = 42
    INTO myworkarea
    BINARY SEARCH. "OK

DATA my_hashed_table TYPE HASHED TABLE OF t_mytable
    WITH UNIQUE KEY myfield.

DATA my_sorted_table TYPE SORTED TABLE OF t_mytable
    WITH UNIQUE KEY myfield.

READ TABLE my_hashed_table
    WITH KEY myfield = 42
    INTO myworkarea. "OK, non è una STANDARD TABLE

READ TABLE my_sorted_table
    WITH KEY myfield = 42
    INTO myworkarea. "OK, non è una STANDARD TABLE

PERFORM subr USING a1 a2 a3 a4 a5. "VIOLAZ Avoid parameters passed by value 
PERFORM subr CHANGING a1 a2 a3 a4 a5. "OK

SELECT name
FROM employee
WHERE EXISTS (SELECT * FROM department WHERE department_id = id AND name = 'Marketing'). "VIOLAZ Avoid SQL EXISTS subqueries 

SELECT *
INTO US_PERSONS
FROM PERSONS
BYPASSING BUFFER "VIOLAZ Avoid BYPASSING BUFFER clause  
WHERE CITY EQ 'US'.

