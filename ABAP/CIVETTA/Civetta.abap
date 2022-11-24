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
	"OK, NO VIOLAZ ABAP_26
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

	"OK, NO VIOLAZ ABAP_26
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
	"OK, NO VIOLAZ ABAP_26
	CONCATENATE: 'PROGRAM zsample.| FORM calculation. |' INTO code_string,
				 calculator_code_begin user_ops calculator_code_end INTO code_string,
				 'ENDFORM.|' INTO code_string.
	REPLACE ALL OCCURRENCES OF '.' IN code_string WITH ''. "VIOLAZ ABAP_17
	SPLIT code_string AT '|' INTO TABLE code_table.
	
	GENERATE SUBROUTINE POOL code_table NAME calc_prog. "VIOLAZ ABAP_15 Dynamic Code Evaluation: Code Injection
	PERFORM calculation IN PROGRAM calc_prog.

	author = (‘author’)
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
	"OK, NO VIOLAZ ABAP_26
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
           key        = lv_key  “VIOLAZ Empty Encryption Key 
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
	"OK, NO VIOLAZ ABAP_26
	CONCATENATE `C:\\users\\reports\\` r_name INTO dsn.  "VIOLAZ Securitymisc18
	DELETE DATASET dsn. "VIOLAZ Path Manipulation
	OPEN DATASET dsn FOR INPUT IN TEXT MODE. "VIOLAZ Path Manipulation
	PARAMETERS: p_date TYPE string.

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
	CONCATENATE cl_where "AND ref_key = `" v_reference "`" INTO cl_where.
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
		I_S_MSG          = v   “VIOLAZ System Information Leak
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
				  Write 'Yes, It’s Correct'.
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
				Write 'Sorry, It’s Wrong'. 
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
			  Write 'Yes, It’s Correct'.
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
			Write 'Sorry, It’s Wrong'. 
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
*			  Write 'Yes, It’s Correct'.
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
*			Write 'Sorry, It’s Wrong'. 
*		ENDIF.
*		lbl1: CONTINUE.  
*	  ENDIF.
*	  cl_demo_output=>write_text( |{ sy-index }| ).
*	ENDDO.
*ENDMETHOD.
