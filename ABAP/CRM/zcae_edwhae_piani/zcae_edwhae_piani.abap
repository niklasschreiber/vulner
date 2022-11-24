*&---------------------------------------------------------------------*
*& Report  Z_PLAN_FILE_CSV
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_piani.

*PARAMETERS file(128) DEFAULT '/usr/tmp/testfile.csv'
*                         LOWER CASE.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,
           p_date_f TYPE cgpl_project-created_on,
           p_fout TYPE filename-fileintern DEFAULT 'ZCRMOUT001_CAMPAIGNR3' OBLIGATORY.
*           p_flog TYPE filename-fileintern
*             DEFAULT 'ZCRMLOG001_EDWHAE_ACTIVITY' OBLIGATORY,
*           p_ind(9) TYPE c  ."OBLIGATORY. " MOD SC 19/12/2008

SELECTION-SCREEN END OF BLOCK b1.

DATA file TYPE c LENGTH 120.
TABLES: cgpl_project,
        cgpl_text,
        crm_jcds,
        tj02t.

TYPES: BEGIN OF st_piani,
  guid TYPE cgpl_project-guid,
*  id piano
  idpiano TYPE cgpl_extid,
*  data inizio pianificata
  datain_p  TYPE cgpl_planstart,
*  data fine pianificata
  datafin_p TYPE cgpl_planfinish,
*  data inizio effettiva
  datain  TYPE cgpl_actualstart,
*  data fine effettiva
  datafin TYPE cgpl_actualfinish,
*  stato piano
  stato TYPE j_txt30,
*  descrizione
  descr TYPE cgpl_text1,
      END OF st_piani.

*struttura appoggio file csv
TYPES: BEGIN OF st_piani_csv,
*  id piano
  idpiano TYPE string,
*  data inizio pianificata
  datain_p  TYPE string,
*  data fine pianificata
  datafin_p TYPE string,
*  data inizio effettiva
  datain  TYPE string,
*  data fine effettiva
  datafin TYPE string,
*  stato piano
  stato TYPE string,
*  descrizione
  descr TYPE string,
      END OF st_piani_csv.

DATA: ap_piani TYPE STANDARD TABLE OF st_piani,
      st_piani2 TYPE st_piani,
      st_piani2_csv TYPE st_piani_csv,
      ap_piani2 TYPE STANDARD TABLE OF st_piani,
      status_ap TYPE TABLE OF crm_jcds,
      status_ap2 TYPE crm_jcds.
DATA: descr_pian TYPE cgpl_text-text1,
      guid_var TYPE cgpl_guid16,
      text_guid_var TYPE cgpl_text-guid,
      stato_var TYPE tj02t-txt30.

DATA: l_idpiano TYPE string,
      l_stato TYPE string,
      l_descr TYPE string,
      l_datain_p TYPE string,
      l_datafin_p TYPE string,
      l_datain TYPE string,
      l_datafin TYPE string.


DATA: w_output TYPE st_piani,
      w_output2 TYPE STANDARD TABLE OF st_piani_csv,
      w_output_csv TYPE st_piani_csv. "appoggio per esport. csv

DATA:   ls_bdinc TYPE crmd_mktpl_bdinc,
        tabix TYPE sy-tabix,
        wa_tasknull TYPE cgpl_guid16.
DATA: lv_string TYPE TZTF_IO_FIELD.
DATA: l_format TYPE tztf_format VALUE ' X  '.

DATA:ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_PIANI',
     ca_r           TYPE tbtco-status         VALUE 'R'.

TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         status    TYPE tbtco-status,
       END OF t_tbtco.

DATA: lw_tbtco_t TYPE t_tbtco ,
      sy_date TYPE D.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt
         status FROM tbtco UP TO 1 ROWS
    INTO lw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    sy_date = sy-datum.
  ELSE.
    sy_date = lw_tbtco_t-sdlstrtdt.
  ENDIF.

DATA: lv_file TYPE string,
      lv_path TYPE string,
      lv_filename TYPE string,
      lv_shift  TYPE I.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_fout
    IMPORTING
      file_name        = lv_path
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
  ENDIF.

CALL FUNCTION 'Z_ESTRAI_NOME_FILE'
  EXPORTING
    full_path       = lv_path
 IMPORTING
   FILE_NAME       =  lv_filename
          .
SEARCH lv_path FOR lv_filename.

lv_shift = SY-FDPOS.

lv_file = lv_path(lv_shift).


CONCATENATE lv_file 'ZCRMOUT001_PIANOBPCRM_' sy_date '.csv' INTO file.

IF ( r_delta EQ 'X' ).

    IF p_date_f IS INITIAL.

        p_date_f = sy_date.

    ENDIF.

SELECT guid external_id planstart planfinish actualstart actualfinish INTO TABLE ap_piani
        FROM cgpl_project
       WHERE object_type  = 'MPL'
         AND ( ( ( changed_on   GE p_date_f ) AND ( changed_on  LE sy_date ) ) OR ( ( created_on   GE p_date_f ) AND ( created_on  LE sy_date ) ) ).

ELSE.

  SELECT guid external_id planstart planfinish actualstart actualfinish INTO TABLE ap_piani
        FROM cgpl_project
       WHERE object_type  = 'MPL'.


ENDIF.

LOOP AT ap_piani INTO st_piani2.

*Filtro gruppo responsabili BP e MP
  tabix = sy-tabix.
  CLEAR ls_bdinc.
  SELECT SINGLE * FROM crmd_mktpl_bdinc INTO ls_bdinc
    WHERE project_guid = st_piani2-guid
      AND task_guid = wa_tasknull
      AND ( zzgrupporesp = 'BP' OR zzgrupporesp = 'MP' ).
  IF sy-subrc <> 0.
    DELETE ap_piani INDEX tabix.
    CONTINUE.
  ENDIF.

*******************************
***** descrizione Piano *******
*******************************

* conversione GUID alfanumerico in numerico
  CALL FUNCTION 'CONVERSION_EXIT_CGPLP_INPUT'
    EXPORTING
      input                = st_piani2-idpiano
*       IM_APPLICATION       =
   IMPORTING
     output               = guid_var.

*  write st_piani2-idpiano to guid_var.
  SELECT SINGLE text1 FROM  cgpl_text INTO descr_pian
         WHERE  guid  = guid_var AND
                langu = 'I'.

****************************
****stato piano*************
****************************

  SELECT * FROM  crm_jcds INTO TABLE status_ap
         WHERE  objnr  = guid_var
         AND    inact  <> 'X'.

* prendo lo stato più recente
  SORT status_ap BY udate DESCENDING.
  READ TABLE status_ap INDEX 1 INTO status_ap2.
  DELETE status_ap WHERE udate <> status_ap2-udate.
  SORT status_ap BY udate utime DESCENDING.
  READ TABLE status_ap INDEX 1 INTO status_ap2.

* descrizione stato
  IF sy-subrc = 0.
    SELECT SINGLE txt30 FROM tj02t INTO stato_var WHERE
      istat = status_ap2-stat AND
      spras = 'I'.
  ENDIF.


  st_piani2-descr = descr_pian.
  st_piani2-stato = stato_var.
  APPEND st_piani2 TO ap_piani2.


ENDLOOP.

LOOP AT ap_piani2 INTO w_output.
  MOVE w_output-idpiano TO l_idpiano.
  MOVE w_output-stato TO l_stato.
  MOVE w_output-descr TO l_descr.

 IF ( w_output-datain_p IS NOT INITIAL ).
  CLEAR lv_string.
  CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
    EXPORTING
      is_format   = l_format
      if_time     = w_output-datain_p
      if_timezone = sy-zonlo
    IMPORTING
      ef_io_field = lv_string.
  CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
    EXPORTING
      date_external = lv_string
    IMPORTING
      date_internal = l_datain_p.
  ENDIF.
*  MOVE w_output-datain_p TO l_datain_p.

  IF ( w_output-datafin_p IS NOT INITIAL ).
  CLEAR lv_string.
  CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
    EXPORTING
      is_format   = l_format
      if_time     = w_output-datafin_p
      if_timezone = sy-zonlo
    IMPORTING
      ef_io_field = lv_string.
  CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
    EXPORTING
      date_external = lv_string
    IMPORTING
      date_internal = l_datafin_p.
  ENDIF.
  IF ( w_output-datain IS NOT INITIAL ).
*  MOVE w_output-datafin_p TO l_datafin_p.
  CLEAR lv_string.
  CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
    EXPORTING
      is_format   = l_format
      if_time     = w_output-datain
      if_timezone = sy-zonlo
    IMPORTING
      ef_io_field = lv_string.
  CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
    EXPORTING
      date_external = lv_string
    IMPORTING
      date_internal = l_datain.
  ENDIF.
*  MOVE w_output-datain TO l_datain.
  IF ( w_output-datafin IS NOT INITIAL ).
  CLEAR lv_string.
  CALL FUNCTION 'TZ_TIMEFIELD_SINGLE_OUTPUT'
    EXPORTING
      is_format   = l_format
      if_time     = w_output-datafin
      if_timezone = sy-zonlo
    IMPORTING
      ef_io_field = lv_string.
  CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
    EXPORTING
      date_external = lv_string
    IMPORTING
      date_internal = l_datafin.
  ENDIF.
*  MOVE w_output-datafin TO l_datafin.



*  CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
*    EXPORTING
*      input        = v_datain_p
*   IMPORTING
*     OUTPUT        = ap_datain_p.

* move w_output-idpiano to l_idpiano.
* move w_output-idpiano to l_idpiano.
* move w_output-idpiano to l_idpiano.
* st_piani2_csv-idpiano = l_idpiano.


  CONCATENATE l_idpiano '|' INTO st_piani2_csv-idpiano.
  CONDENSE st_piani2_csv-idpiano NO-GAPS.
  CONCATENATE l_stato '' INTO st_piani2_csv-stato.
  CONDENSE st_piani2_csv-stato NO-GAPS.
  CONCATENATE l_descr '|' INTO st_piani2_csv-descr.
  CONDENSE st_piani2_csv-descr.

*  controllo se la data iniziale pian. è valorizzata.
*altrimenti il concatenate genererebbe dump
  IF ( l_datain_p = 0 ) OR ( l_datain_p IS INITIAL ).
    CONCATENATE '' '|' INTO st_piani2_csv-datain_p.
*    l_datain_p = ''.
  ELSE.
    CONCATENATE l_datain_p(8) '|' INTO st_piani2_csv-datain_p.
  ENDIF  .
  CONDENSE st_piani2_csv-datain_p NO-GAPS.

*  controllo se la data finale pian. è valorizzata.
*altrimenti il concatenate genererebbe dump
  IF ( l_datafin_p = 0 ) OR ( l_datafin_p IS INITIAL ) .
    CONCATENATE '' '|' INTO st_piani2_csv-datafin_p.
*    l_datafin_p = ''.
  ELSE.
    CONCATENATE l_datafin_p(8) '|' INTO st_piani2_csv-datafin_p.
  ENDIF  .
  CONDENSE st_piani2_csv-datafin_p NO-GAPS.

*  controllo se la data iniziale effett. è valorizzata.
*altrimenti il concatenate genererebbe dump
  IF  ( l_datain = 0 ) OR ( l_datain IS INITIAL ) .
     CONCATENATE '' '|' INTO st_piani2_csv-datain.
*    l_datain = ''.
  ELSE.
     CONCATENATE l_datain(8) '|' INTO st_piani2_csv-datain.
  ENDIF  .
  CONDENSE st_piani2_csv-datain NO-GAPS.

*  controllo se la data finale effett. è valorizzata
*altrimenti il concatenate genererebbe dump
  IF ( l_datafin = 0 ) OR ( l_datafin IS INITIAL ) .
    CONCATENATE '' '|' INTO st_piani2_csv-datafin.
*    l_datafin = ''.
  ELSE.
    CONCATENATE l_datafin(8) '|' INTO st_piani2_csv-datafin.
  ENDIF.
  CONDENSE st_piani2_csv-datafin NO-GAPS.

  APPEND st_piani2_csv TO w_output2.
ENDLOOP.

***************************
****esportazione in csv****
***************************
DATA: line TYPE string.
OPEN DATASET file FOR OUTPUT IN TEXT MODE
                             ENCODING DEFAULT.


IF sy-subrc EQ 0.
  LOOP AT w_output2 INTO w_output_csv.
    CONCATENATE w_output_csv-idpiano w_output_csv-descr  w_output_csv-datain_p w_output_csv-datafin_p w_output_csv-datain w_output_csv-datafin w_output_csv-stato  INTO line .
    TRANSFER line TO file.
  ENDLOOP.
  IF sy-subrc EQ 0.
    WRITE : / 'download eseguito correttamente -', file.
  ELSE.
    WRITE : / 'Nessun Dato da elaborare -', file.
  ENDIF.
  CLOSE DATASET file.
ELSE.
  WRITE : / 'Impossibile aprire il path prodotti: ', file.
ENDIF.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
