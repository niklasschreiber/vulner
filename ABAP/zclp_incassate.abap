REPORT zclp_incassate.
   
   
*&---------------------------------------------------------------------*
*& Report  ZCLP_INCASSATE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
   
   
TYPE-POOLS: slis.
TABLES: dfkkop.


DATA: l_filename TYPE string.
DATA: lt_data TYPE truxs_t_text_data.
DATA: ls_data TYPE LINE OF truxs_t_text_data.
DATA: gv_dest      TYPE eps2filnam.
DATA: lv_filename TYPE string,
      lv_server   TYPE c LENGTH 1.

DATA: wa_tb LIKE dfkkop.
DATA: t_dfkkop TYPE TABLE OF dfkkop WITH HEADER LINE.
DATA: s_dfkkop LIKE dfkkop.
DATA: vaoutput TYPE string.



SELECTION-SCREEN BEGIN OF BLOCK blocco1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: stipoope FOR dfkkop-srctatype NO INTERVALS.
PARAMETERS: pdatapar TYPE dfkkop-augdt OBLIGATORY DEFAULT sy-datum.
PARAMETERS: pbukrs TYPE dfkkop-bukrs OBLIGATORY DEFAULT 'CLP'.
PARAMETERS: p_file TYPE eseftfront DEFAULT 'ZFILE_CLP_OUT'.
PARAMETERS: lv_file TYPE eseftfront DEFAULT 'ZFILE_CLP_OUT' NO-DISPLAY.

SELECTION-SCREEN END OF BLOCK blocco1.




AT SELECTION-SCREEN OUTPUT.

  IF p_file IS NOT INITIAL.
    LOOP AT SCREEN.
      IF  ( screen-name  = 'P_FILE').
        screen-input = 0.
        screen-output = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.


START-OF-SELECTION.



  PERFORM f_check_directory CHANGING gv_dest.
  PERFORM crea_file.



FORM f_check_directory CHANGING l_dest TYPE eps2filnam.
  DATA: l_lofile LIKE filename-fileintern,
        l_path   LIKE epsf-epsdirnam.

  CONCATENATE 'PROVVCLP_' pdatapar '.txt' INTO p_file .


  l_lofile = lv_file.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = l_lofile
    IMPORTING
      file_name        = l_dest
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_path = l_dest.
  ENDIF.
  CONCATENATE l_dest p_file INTO p_file.



ENDFORM.

FORM crea_file.
  SELECT bukrs bldat augst augdt xblnr FROM dfkkop INTO CORRESPONDING FIELDS OF TABLE t_dfkkop
    WHERE bukrs LIKE pbukrs
      AND srctatype IN stipoope
      AND augst = '9'
      AND augdt = pdatapar.
  IF sy-subrc = 0.
    DELETE t_dfkkop WHERE xblnr = space.
  ENDIF.
  SORT t_dfkkop BY xblnr.
  DELETE ADJACENT DUPLICATES FROM t_dfkkop COMPARING xblnr.
   
   
*   t_dfkkop-xblnr+1(15).
   
   
  IF t_dfkkop[] IS INITIAL.
    MESSAGE 'Dati non trovati' TYPE 'S' DISPLAY LIKE 'E'.
  ELSE.

    TYPES: BEGIN OF ty,
             rec TYPE c LENGTH 2080,
           END OF ty.

    DATA: lv_filename TYPE string,
          lv_server   TYPE c LENGTH 1,
          itab        TYPE TABLE OF ty,
          wa          TYPE ty.

    CLEAR: lv_filename, lv_server.

    CLEAR wa.
    CONCATENATE sy-datum sy-uzeit 'GCPROVVCLP' INTO wa-rec SEPARATED BY space.
    APPEND wa TO itab.
    LOOP AT t_dfkkop INTO wa_tb.
      CLEAR: wa .

      CONCATENATE  wa_tb-xblnr+1(15)
                   wa_tb-bldat
      INTO wa-rec.
      APPEND wa TO itab.
    ENDLOOP.


    OPEN DATASET p_file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc NE 0.
    ELSE.
      LOOP AT itab INTO wa.
        TRANSFER wa-rec TO p_file.
        CLEAR wa.
      ENDLOOP.
      CLOSE DATASET p_file.
    ENDIF.
    IF sy-subrc = 0.
      vaoutput = p_file.
      WRITE vaoutput.
    ENDIF.

  ENDIF.
ENDFORM.


   
   
*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Dati non trovati
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



