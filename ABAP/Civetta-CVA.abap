CLASS demo IMPLEMENTATION.
  METHOD main.
    LOOP AT itab INTO DATA(wa).
      FIND char IN wa-col1 RESPECTING CASE.
      IF sy-subrc = 0.
        EXIT.  “OK
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
    INTERNAL_ERROR = 3          "               Unknown Error
	
CALL FUNCTION 'ECATT_CONV_XSTRING_TO_STRING' "VIOLAZ Punto 5
  EXPORTING
    im_xstring        = xstr
   IM_ENCODING       = 'UTF-8'
 IMPORTING
   EX_STRING         = str
          .
  write str+300(10)  
  
DATA: a type i. 
a = 0.
WHILE a <> 8.
   Write: / 'This is the line:', a.  
   a = a + 1.
   IF a > 8.
 	RETURN. “VIOLAZ Punto 6
   ENDIF.
ENDWHILE.

TRY.
    cl_demo_output=>display( 1 / 0 ).
  CATCH cx_sy_arithmetic_error INTO DATA(exc). “OK
    cl_demo_output=>display( exc->get_text( ) ).
ENDTRY.
TRY. “VIOLAZ Punto 8
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

CONCATENATE `INVOICEID = '` id `'` INTO cl_where. “VIOLAZ Punto 11

cl_abap_unit_assert=>assert_equals( exp = 4 act = result ). “VIOLAZ Punto 13

TRY.
	RESULTS = 1 / NUMBER.
CATCH CX_SY_ZERODIVIDE into OREF. “VIOLAZ Punto 15
ENDTRY.
TRY.
	RESULTS = 1 / NUMBER.
CATCH CX_SY_ZERODIVIDE into OREF. “OK
	TEXT = OREF->GET_TEXT( ).
	cleanup.
	clear RESULT.
ENDTRY.

CALL FUNCTION 'REGISTRY_GET' 
  EXPORTING
	 KEY   = 'DEFAULTREPORT'
  IMPORTING
	 VALUE = test_report. ' test_report Untrusted
INSERT REPORT test_report FROM itab.  “VIOLAZ Punto 16

prog = request->get_form_field( 'report_program' ). “prog untrusted
DELETE REPORT prog. “VIOLAZ Punto 17

cl_abap_file_utilities=>create_utf8_file_with_bom(
EXPORTING file_name = prog ). “VIOLAZ Punto 18

SUBMIT prog. “VIOLAZ Punto 19

tra = request->get_form_field( 'report_program' ). “tra untrusted
LEAVE TO TRANSACTION tra AND SKIP FIRST SCREEN. “VIOLAZ Punto 20

Data:     i_unescaped type string,
        e_escaped   type string.
call method cl_http_utility=>escape_html  "VIOLAZ Punto 21
    exporting
      unescaped     = i_unescaped
      keep_num_char_ref = '-'
    receiving
      escaped   = e_escaped.

COMMUNICATION INIT “VIOLAZ Punto 25
  DESTINATION d
  ID         id.
COMMUNICATION ALLOCATE “VIOLAZ  Punto 25
  ID         id.
COMMUNICATION SEND “VIOLAZ Punto 25
  BUFFER connect_xstr
  ID         id.
COMMUNICATION ACCEPT “VIOLAZ Punto 25
  ID         id.
COMMUNICATION RECEIVE “VIOLAZ Punto 25
  BUFFER     connect_ret
  DATAINFO   dat
  STATUSINFO stat
  RECEIVED   len
  ID         id.
b = 'Request'.
COMMUNICATION DEALLOCATE ID id. “VIOLAZ Punto 25

DATA: lo_class TYPE REF TO IF_HTTP_ENTITY.
DATA: lv_DATA TYPE XSTRING,
lv_LENGTH TYPE I,
lv_OFFSET TYPE I,
lv_VIRUS_SCAN_PROFILE TYPE VSCAN_PROFILE,
lv_VSCAN_SCAN_ALWAYS TYPE HTTP_CONTENT_CHECK,
lv_other TYPE c.

lv_DATA = lo_class=>GET_DATA( ). “VIOLAZ Punto 26

CALL METHOD lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS
RECEIVING
DATA = lv_DATA ). “OK

lv_DATA = lo_class=>GET_DATA(
EXPORTING
LENGTH = lv_LENGTH
OFFSET = lv_OFFSET
VIRUS_SCAN_PROFILE = lv_VIRUS_SCAN_PROFILE
VSCAN_SCAN_ALWAYS = lv_VSCAN_SCAN_ALWAYS ).  “OK

IF SY-HOST = ‘host00’. “VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
CALL METHOD CL_ABAP_SYST=>GET_HOST_NAME(
RECEIVING
HOST_NAME = lv_HOST_NAME )
IF lv_HOST_NAME = ‘Domain1’. “VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
lv_HOST_NAME = CL_ABAP_SYST=>GET_HOST_NAME( ).
IF lv_HOST_NAME = ‘Domain1’. “VIOLAZ Punto 27
	WRITE: 'This is the Default HOST '.
ENDIF
CONSTANTS : G_C_DEV_SYSTEM TYPE SY-SYSID VALUE 'DEV',
G_C_QUA_SYSTEM TYPE SY-SYSID VALUE 'SAN'.
IF SY-SYSID EQ G_C_DEV_SYSTEM. “VIOLAZ Punto 27 G_C_DEV_SYSTEM è una costante
write: 'this the dev system.
elseif SY-SYSID EQ G_C_QUA_SYSTEM. “VIOLAZ Punto 27 G_C_QUA_SYSTEM è una costante
write: 'this is sandbox server
endif.

IF SY-MANDT = ‘client01’. “VIOLAZ Punto 28
	WRITE: 'This is the Default Client '.
ENDIF
client = cl_abap_syst=>get_client( ).
IF client = ‘client01’. “VIOLAZ Punto 28
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
 catch CX_ROOT into OREF. “VIOLAZ Avoid catching CX_ROOT
    write / OREF->GET_TEXT( ).
 endtry.

TYPES BEGIN OF t_mytable,
    myfield TYPE i
END OF t_mytable.

DATA myworkarea TYPE t_mytable.

DATA mytable TYPE STANDARD TABLE OF t_mytable. “mytable è una STANDARD TABLE

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
    INTO myworkarea. “OK, non è una STANDARD TABLE

READ TABLE my_sorted_table
    WITH KEY myfield = 42
    INTO myworkarea. “OK, non è una STANDARD TABLE

PERFORM subr USING a1 a2 a3 a4 a5. “VIOLAZ Avoid parameters passed by value 
PERFORM subr CHANGING a1 a2 a3 a4 a5. “OK

SELECT name
FROM employee
WHERE EXISTS (SELECT * FROM department WHERE department_id = id AND name = 'Marketing'); “VIOLAZ Avoid SQL EXISTS subqueries 

SELECT *
INTO US_PERSONS
FROM PERSONS
BYPASSING BUFFER “VIOLAZ Avoid BYPASSING BUFFER clause  
WHERE CITY EQ 'US'

