*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_REL
*&
*&---------------------------------------------------------------------*
*&  Author     : Mitesh Paliwal
*&  Date       : 29/07/2008
*&  Description: integrazione EDWH Entità Relazione
*&  Modified by: Paola Ferabecoli at 27/11/2008
*&  Description modify: filtro sul tipo di relazione nell'estrazione full e eliminazione della parte delta
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_rel.

INCLUDE zcae_edwhae_rel_inc.

INITIALIZATION.
* Initializing variables and tables
  PERFORM initialize.

START-OF-SELECTION.
* Opening files
  PERFORM open_files.

*  IF rb_full = ca_x.
*   In case radio button Full is selected
  PERFORM full.

*  ELSE.
* In case radio button Delta is selected
*    PERFORM delta.

*  ENDIF.

  CLOSE DATASET va_filename.
  CLOSE DATASET va_filelog.

*&---------------------------------------------------------------------*
*&      Form  estrai_relimpr_web
*&---------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
FORM estrai_relimpr_web .

  DATA: lt_but050 TYPE STANDARD TABLE OF dd_but050 .

  CHECK i_but050[] IS NOT INITIAL.

  lt_but050[] = i_but050[].

  SORT lt_but050 BY relnr.
  DELETE ADJACENT DUPLICATES FROM lt_but050 COMPARING relnr.

  SELECT relnr
         user_id
         ric_forte
    FROM zca_relimpr_web
    INTO TABLE gt_relimpr_web
    FOR ALL ENTRIES IN lt_but050
    WHERE relnr EQ lt_but050-relnr.

  SORT gt_relimpr_web BY relnr.

ENDFORM.                    " estrai_relimpr_web

*&---------------------------------------------------------------------*
*&      Form  data_to_file
*&---------------------------------------------------------------------*
*       Copy records in file
*----------------------------------------------------------------------*
FORM data_to_file.

  DATA: ls_relimpr_web TYPE t_relimpr_web. " Add AS 06.09.2012

  LOOP AT i_but050 ASSIGNING <fs_but050>.

    " Inizio AS 06.09.2012
    CLEAR ls_relimpr_web.
    READ TABLE gt_relimpr_web INTO ls_relimpr_web
      WITH KEY relnr = <fs_but050>-relnr BINARY SEARCH.
    " Fine AS 06.09.2012

    CONCATENATE <fs_but050>-relnr <fs_but050>-partner1 <fs_but050>-partner2
                <fs_but050>-date_to <fs_but050>-date_from <fs_but050>-reltyp
" Inizio AS 06.09.2012
                ls_relimpr_web-user_id
                ls_relimpr_web-ric_forte
" Fine AS 06.09.2012
                INTO va_file SEPARATED BY ca_pipe.
    TRANSFER va_file TO va_filename.

    IF sy-subrc EQ 0.
      CONCATENATE <fs_but050>-relnr text-001
        INTO va_logvalue SEPARATED BY ca_pipe.
    ELSE.
      CONCATENATE <fs_but050>-relnr text-002
        INTO va_logvalue SEPARATED BY ca_pipe.
    ENDIF.

    TRANSFER va_logvalue TO va_filelog.

  ENDLOOP.

  REFRESH: i_but050,
           gt_relimpr_web. " Add AS 06.09.2012

ENDFORM.                    " data_to_file

*&---------------------------------------------------------------------*
*&      Form  get_file_name
*&---------------------------------------------------------------------*
*       Get physical file path
*----------------------------------------------------------------------*
FORM get_file_name  USING  p_file TYPE filename-fileintern
                    CHANGING p_fileimport TYPE string.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      client           = sy-mandt
      logical_filename = p_file
      operating_system = sy-opsys
      parameter_1      = sy-datum
    IMPORTING
      file_name        = p_fileimport
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-011.
  ENDIF.
  CLEAR p_file.

ENDFORM.                    " get_file_name

*&---------------------------------------------------------------------*
*&      Form  initialize
*&---------------------------------------------------------------------*
*       Initialize internal tables and variables
*----------------------------------------------------------------------*
FORM initialize.

  REFRESH : i_tbtco,
            gt_relimpr_web, " Add AS 06.09.2012
            i_but050.

  CLEAR:    wa_tbtco,
            wa_but050,
            va_date,
            va_time,
            va_filename,
            va_logvalue,
            va_file.

ENDFORM.                    " initialize

*&---------------------------------------------------------------------*
*&      Form  open_files
*&---------------------------------------------------------------------*
*       Open files to write data records
*----------------------------------------------------------------------*
FORM open_files.

  PERFORM get_file_name USING p_file
                        CHANGING va_filename.
*  va_filename = va_filelog.
*  CLEAR va_filelog.
  PERFORM get_file_name USING p_filog
                        CHANGING va_filelog.

  OPEN DATASET va_filename FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-009.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-009.
  ENDIF.

ENDFORM.                    " open_files

*&---------------------------------------------------------------------*
*&      Form  full
*&---------------------------------------------------------------------*
*       In case radio button Full is selected
*----------------------------------------------------------------------*
FORM full.

  REFRESH: i_but050,
          gt_relimpr_web. " Add AS 06.09.2012

  SELECT relnr partner1 partner2                        "#EC CI_NOFIRST
         date_to date_from reltyp
         crdat crtim chdat chtim
    FROM but050
    INTO TABLE i_but050
    PACKAGE SIZE p_pac
    WHERE date_to GE sy-datum
    AND reltyp NOT IN o_rel

    ORDER BY reltyp partner2 crdat date_to DESCENDING crtim DESCENDING.

    PERFORM clean_data.
    " Inizio AS 06.09.2012
    PERFORM estrai_relimpr_web.
    " Fine AS 06.09.2012
    PERFORM data_to_file.
  ENDSELECT.

ENDFORM.                    " full

*&---------------------------------------------------------------------*
*&      Form  delta
*&---------------------------------------------------------------------*
*       In case radio button Delta is selected
*----------------------------------------------------------------------*
*FORM delta.
*
*  IF NOT ( p_date IS INITIAL OR p_time IS INITIAL ).
*    CLEAR : va_enddate,va_endtime.
*    SELECT   sdlstrtdt sdlstrttm
*      UP TO 1 ROWS
*   FROM tbtco
*   INTO  (va_enddate, va_endtime)
*   WHERE
*     jobname = ca_job AND
*     status = ca_r.
*
*    ENDSELECT.
*
*    IF sy-subrc NE 0.
*      MESSAGE e398(00) WITH text-003 text-004 text-005 space.
*    ENDIF.
*
*    CLEAR va_chtim.
*    va_chtim = va_endtime.

*    IF i_tbtco IS NOT INITIAL.

* Optimizing For All Entries
*      REFRESH lt_tbtco_app.
*      lt_tbtco_app[] = i_tbtco[].
*      SORT lt_tbtco_app BY date_to time_to.
*      DELETE ADJACENT DUPLICATES FROM lt_tbtco_app COMPARING date_to time_to.

*      SELECT  relnr partner1 partner2                   "#EC CI_NOFIELD
*              date_to date_from reltyp
*              crdat crtim chdat chtim
*        FROM but050
*        INTO TABLE i_but050
*        PACKAGE SIZE p_pac
**        FOR ALL ENTRIES IN i_tbtco
*        WHERE (
*                ( crdat EQ p_date AND crdat NE va_enddate AND crtim GE p_time )
*            OR ( crdat EQ p_date AND crdat EQ va_enddate AND crtim GE p_time  AND crtim LT va_chtim )
*            OR ( crdat EQ va_enddate  AND crdat NE p_date AND crtim LT va_chtim )
*            OR ( crdat GT p_date AND crdat LT va_enddate )
*            OR ( chdat EQ p_date AND chdat NE va_enddate AND chtim GE p_time  )
*            OR ( chdat EQ p_date AND chdat EQ va_enddate AND chtim GE p_time AND chtim LT va_chtim )
*            OR ( chdat EQ va_enddate   AND chdat NE p_date AND chtim LT va_chtim )
*            OR ( chdat GT p_date AND chdat LT va_enddate ) ).


*            ( chdat EQ p_date AND chtim GE p_time ) OR
*            ( chdat GT p_date AND  chdat LT  i_tbtco-date_to ) OR
*            ( chdat EQ i_tbtco-date_to AND chtim LE i_tbtco-time_to ) OR
*            ( chdat EQ ca_date AND chtim EQ ca_time ) )
*          AND (
*            ( crdat EQ p_date AND crtim GE  p_time ) OR
*            ( crdat GT p_date AND crdat LT  i_tbtco-date_to ) OR
*            ( crdat EQ i_tbtco-date_to AND crtim LE  i_tbtco-time_to ) ).
*
*        PERFORM data_to_file.
*      ENDSELECT.
*    ENDIF.

*  ELSE.
*
*    SELECT jobname status sdlstrtdt sdlstrttm
*      FROM tbtco
*      INTO TABLE i_tbtcoo
*      WHERE
*       jobname = ca_job AND
*       status = ca_f.

* If no record is returned in the table TBTCO, terminate the program
* returning the following error message:
* 'Impossibile determinare la data iniziale.
* Eseguire il programma in modalità full
* oppure specificare una data iniziale'
*    IF sy-subrc NE 0.
*      MESSAGE e398(00) WITH text-006 text-007 text-008 space .
**      SUBMIT zcae_edwhae_rel VIA SELECTION-SCREEN.
*    ENDIF.
*
*    SORT i_tbtcoo BY date_to DESCENDING time_to DESCENDING.
**    i_tbtcoo = i_tbtco.
*
**   Calculate maximum
*    READ TABLE i_tbtcoo INTO wa_tbtco INDEX 1.
*    IF sy-subrc IS INITIAL.
*      " SC MOD 29/08/2008 inizio
**      va_date = wa_tbtcoo-date_to.
**      va_time = wa_tbtcoo-time_to.
*      va_date = wa_tbtco-date_to.
*      va_time = wa_tbtco-time_to.
*      " SC MOD 29/08/2008 fine
*    ENDIF.
*
*    CLEAR : va_enddate,va_endtime.
*    SELECT   sdlstrtdt sdlstrttm
*      UP TO 1 ROWS
*   FROM tbtco
*   INTO  (va_enddate, va_endtime)
*   WHERE
*     jobname = ca_job AND
*     status = ca_r.
*
*    ENDSELECT.
*
*    IF sy-subrc NE 0.
*      MESSAGE e398(00) WITH text-003 text-004 text-005 space.
*    ENDIF.
*    CLEAR va_chtim.
*    va_chtim = va_endtime.
*
** Optimizing For All Entries
**    REFRESH lt_tbtco_app.
**    lt_tbtco_app[] = i_tbtco[].
**    SORT lt_tbtco_app BY  date_to  time_to .
**    DELETE ADJACENT DUPLICATES FROM lt_tbtco_app COMPARING date_to time_to.
**    IF i_tbtco IS NOT INITIAL.
*    SELECT  relnr partner1 partner2                     "#EC CI_NOFIELD
*            date_to date_from reltyp
*            crdat crtim chdat chtim
*      FROM but050
*      INTO TABLE i_but050 PACKAGE SIZE p_pac
**        FOR ALL ENTRIES IN i_tbtco
*      WHERE (
*            ( crdat EQ va_date AND crdat NE va_enddate AND crtim GE va_time )
*          OR ( crdat EQ va_date AND crdat EQ va_enddate AND crtim GE va_time  AND crtim LT va_chtim )
*          OR ( crdat EQ va_enddate  AND crdat NE va_date AND crtim LT va_chtim )
*          OR ( crdat GT va_date AND crdat LT va_enddate )
*          OR ( chdat EQ va_date AND chdat NE va_enddate AND chtim GE va_time  )
*          OR ( chdat EQ va_date AND chdat EQ va_enddate AND chtim GE va_time AND chtim LT va_chtim )
*          OR ( chdat EQ va_enddate  AND chdat NE va_date AND chtim LT va_chtim )
*          OR ( chdat GT va_date AND chdat LT va_enddate ) ).
*
**            ( chdat EQ va_date AND chtim GE va_time ) OR
**            ( chdat GT va_date AND  chdat LT  i_tbtco-date_to ) OR
**            ( chdat EQ  i_tbtco-date_to  AND chtim LE  i_tbtco-time_to ) OR
**            ( chdat EQ ca_date AND chtim EQ ca_time ) )
**          AND (
**            ( crdat EQ va_date AND crtim GE  va_time ) OR
**            ( crdat GT va_date AND crdat LT  i_tbtco-date_to ) OR
**            ( crdat EQ i_tbtco-date_to AND crtim LE  i_tbtco-time_to ) ).
*
*      PERFORM data_to_file.
*    ENDSELECT.
*
*
**    ENDIF.
*
*  ENDIF.
*
*ENDFORM.                    " delta
*&---------------------------------------------------------------------*
*&      Form  CLEAN_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clean_data .

  TYPES: BEGIN OF t_rel_del,
           relnr    TYPE but050-relnr,
           partner2 TYPE but050-partner2,
         END OF t_rel_del.

  DATA:  wa_temp_but050 TYPE dd_but050,
         i_but050_app   TYPE TABLE OF dd_but050,
         wa_relnr       TYPE t_rel_del,
         tab_rel_del    TYPE TABLE OF t_rel_del.



  CLEAR wa_temp_but050.
*  READ TABLE i_but050 INTO wa_temp_but050 INDEX 1.


  LOOP AT i_but050 INTO wa_but050.
    IF wa_but050-reltyp = 'ZB0003'.
      IF wa_but050-partner2 = wa_temp_but050-partner2 AND wa_but050-crdat =  wa_temp_but050-crdat AND wa_but050-reltyp =  wa_temp_but050-reltyp.
        IF wa_but050-crtim =< wa_temp_but050-crtim.
          DELETE i_but050 INDEX sy-tabix.
        ELSE.
          READ TABLE i_but050 INTO wa_temp_but050 INDEX sy-tabix.
        ENDIF.
      ELSE.
        READ TABLE i_but050 INTO wa_temp_but050 INDEX sy-tabix.
      ENDIF.
    ENDIF.
    CLEAR wa_but050.
  ENDLOOP.
  SORT i_but050 BY relnr.


*CANCELLAZIONE PORTAFOGLI RETAIL DOPPI. RIMANGONO SOLO I PORTAFOGLI CREATI PIù DI RECENTE.
  CLEAR wa_but050.
  i_but050_app[] = i_but050[].
  DELETE i_but050_app WHERE reltyp NE 'ZB0003' OR partner2+0(2) NE '71'.

  SORT i_but050_app BY partner2 crdat DESCENDING crtim DESCENDING.

  LOOP AT i_but050_app INTO wa_but050.
    READ TABLE tab_rel_del WITH KEY relnr = wa_but050-relnr partner2 = wa_but050-partner2 TRANSPORTING NO FIELDS.
    IF sy-subrc IS NOT INITIAL.
      LOOP AT i_but050_app INTO wa_temp_but050 WHERE partner2 = wa_but050-partner2 AND relnr NE wa_but050-relnr.

        MOVE wa_temp_but050-relnr TO wa_relnr-relnr.
        MOVE wa_temp_but050-partner2 TO wa_relnr-partner2.
        APPEND wa_relnr TO tab_rel_del.

*CANCELLO DALLA TABELLA FINALE LE RELAZIONI DEI PORTAFOGLI PIù VECCHI
        DELETE i_but050 WHERE relnr = wa_temp_but050-relnr AND partner2 = wa_temp_but050-partner2.

        CLEAR: wa_temp_but050, wa_relnr.
      ENDLOOP.
    ENDIF.
    CLEAR wa_but050.
  ENDLOOP.

  CLEAR: i_but050_app, tab_rel_del.
  SORT i_but050 BY relnr.

ENDFORM.

*Text elements
*----------------------------------------------------------
* 001 estrazione Relazione avvenuta con successo
* 002 not successful
* 003 Impossibile determinare la data attuale.
* 004 Eseguire il programma in background
* 005 in un job chiamato ZCAE_EDWHAE_REL
* 006 Impossibile determinare la data iniziale
* 007 Eseguire il programma in modalità
* 008 full oppure specificare una data iniziale
* 009 Impossibile aprire il file in scrittura
* 011 File Logico Errato


*Selection texts
*----------------------------------------------------------
* O_REL         Relazioni da non estrarre
* P_FILE         File di output Report
* P_FILOG         File log Report
* P_PAC         Package


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
