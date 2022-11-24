*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_ACTIVITY_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                   CHANGING p_fname TYPE c.

  DATA: lv_file  TYPE string,
        lv_file2 TYPE string,
        lv_len   TYPE i,
        lv_len2  TYPE i.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
      parameter_2      = p_ind
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.


  IF p_ind IS INITIAL.

    lv_len = strlen( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.

  ELSE.

    p_fname = lv_file.

  ENDIF.

ENDFORM.                    " recupera_file

*&---------------------------------------------------------------------*
*&      Form  apri_file
*&---------------------------------------------------------------------*
*       Apre i file da generare
*----------------------------------------------------------------------*
FORM apri_file .

  OPEN DATASET va_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
  ENDIF.

ENDFORM.                    " apri_file

*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       Chiude i file generati
*----------------------------------------------------------------------*
FORM chiudi_file .
  CLOSE DATASET: va_fileout, va_filelog.
ENDFORM.                    " chiudi_file

*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       Estrae i record dal DB
*----------------------------------------------------------------------*
FORM estrazioni .


*  DATA lv_bool.
*
*  DO.
*    IF lv_bool = 'X'.
*      EXIT.
*    ENDIF.
*  ENDDO.


  CASE ca_x.
*   Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

  WAIT UNTIL gv_running_task EQ 0.
ENDFORM.                    " estrazioni

*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta .

  PERFORM get_date_time_to.
  PERFORM get_date_time_from.
  PERFORM get_param.
*  PERFORM f_select_but000.
  PERFORM select_orderadm_h.

ENDFORM.                    " select_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_time_to
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_TO
*----------------------------------------------------------------------*
FORM get_date_time_to .
  DATA lw_tbtco_t TYPE t_tbtco.

* Il record esiste solo se il programma è stato lanciato in batch
  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco UP TO 1 ROWS
    INTO lw_tbtco_t
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e06 text-e07 text-e08 space.
  ELSE.
    PERFORM trascod_data USING lw_tbtco_t-sdlstrtdt lw_tbtco_t-sdlstrttm
                         CHANGING va_date_t.
  ENDIF.
ENDFORM.                    " get_date_time_to

*&---------------------------------------------------------------------*
*&      Form  trascod_data
*&---------------------------------------------------------------------*
*       Trascodifica due campi DATA e ORA in un campo TIMESTAMP
*----------------------------------------------------------------------*
FORM trascod_data USING p_datum TYPE sy-datum
                        p_uzeit TYPE sy-uzeit
                  CHANGING p_ts TYPE crmd_orderadm_h-created_at.
  DATA: lv_input(19)  TYPE c,
        lv_output(15) TYPE c.

  CLEAR p_ts.
  WRITE: p_datum TO lv_input,
         p_uzeit TO lv_input+11.
  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_INPUT'
    EXPORTING
      input  = lv_input
    IMPORTING
      output = lv_output.

  p_ts = lv_output.
ENDFORM.                    " trascod_data

*&---------------------------------------------------------------------*
*&      Form  get_date_time_from
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_FROM
*----------------------------------------------------------------------*
FORM get_date_time_from .
  DATA: lw_tbtco_f TYPE t_tbtco,
        lt_tbtco_f LIKE STANDARD TABLE OF lw_tbtco_f.

  CHECK p_date_f IS INITIAL.

  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco
    INTO TABLE lt_tbtco_f
    WHERE jobname EQ ca_jobname AND
          status  EQ ca_f.

  IF sy-subrc IS NOT INITIAL.
    PERFORM chiudi_file.
    MESSAGE e398(00) WITH text-e09 text-e10 text-e11 space.
  ENDIF.

  SORT lt_tbtco_f BY sdlstrtdt DESCENDING
                     sdlstrttm DESCENDING.
  READ TABLE lt_tbtco_f INTO lw_tbtco_f INDEX 1.

  PERFORM trascod_data USING lw_tbtco_f-sdlstrtdt lw_tbtco_f-sdlstrttm
                       CHANGING p_date_f.

ENDFORM.                    " get_date_time_from

*&---------------------------------------------------------------------*
*&      Form  get_param
*&---------------------------------------------------------------------*
*       Recupero dei parametri da utilizzare per le estrazioni
*----------------------------------------------------------------------*
FORM get_param .
* Recupera il valore dei parametri dei gruppi EDWA e EDWN
  PERFORM read_group_param:
    USING ca_edwa ca_z_appl CHANGING r_edwa,
    USING ca_edwn ca_z_appl CHANGING r_edwn,
    USING lc_user_migr1 ca_z_appl  CHANGING gr_chusr.

* Recupero dei singoli parametri
  PERFORM read_param:
    USING ca_edw_type    ca_z_appl CHANGING va_edw_type,
    USING ca_edw_type_ac ca_z_appl CHANGING va_edw_type_ac,
    USING ca_edw_fctcl   ca_z_appl CHANGING va_edw_fctcl,
    USING ca_edw_fctdip  ca_z_appl CHANGING va_edw_fctdip,
    USING ca_edw_fctup   ca_z_appl CHANGING va_edw_fctup,  "ADD CP 15/05/2009
    USING ca_bp_dummy    ca_z_appl CHANGING va_bp_dummy,   "-- Add CP 17.02.2011
    USING ca_edw_motivo  ca_z_appl CHANGING va_edw_motivo, " ADD CP 23.11.2011
    USING ca_edw_risult  ca_z_appl CHANGING va_edw_risult, " ADD CP 23.11.2011
    USING ca_edw_fctref  ca_z_appl CHANGING va_edw_fctref. "ADD CL 01.07.2013



ENDFORM.                    " get_param

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING p_gruppo TYPE zca_param-z_group
                            p_z_appl TYPE zca_param-z_appl
                      CHANGING r_range TYPE t_range.

  DATA: lw_range  LIKE LINE OF r_range,
        lt_param  TYPE STANDARD TABLE OF zca_param,
        lt_return TYPE STANDARD TABLE OF bapiret2.
  FIELD-SYMBOLS <lf_param> LIKE LINE OF lt_param.

  REFRESH r_range.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_z_appl
    TABLES
      param    = lt_param
      return   = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e12 p_gruppo space space.
  ENDIF.

  lw_range-sign   = ca_i.
  lw_range-option = ca_eq.
  LOOP AT lt_param ASSIGNING <lf_param>.
    lw_range-low = <lf_param>-z_val_par.
    APPEND lw_range TO r_range.
  ENDLOOP.

ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  select_orderadm_h
*&---------------------------------------------------------------------*
*       Selezione della CRMD_ORDERADM_H per estrazione DELTA
*----------------------------------------------------------------------*
FORM select_orderadm_h .


* Begin AG 24.07.2014
** Begin MS 17.07.2014
*  DATA: ls_order  TYPE t_crmd_orderadm_h,
*        lv_lines  TYPE i.
** End MS 17.07.2014
*  DO. "add MS 17/07/14
*    SELECT a~guid a~object_id a~process_type a~created_at a~changed_at
*           b~zzcustomer_h0801 b~zz_idunivoco
*           b~zz_provenienza   " ADD CP 23.11.2011
**         b~zz_sede_lav  "ADD CL 05.06.2013 - Delete CL - 13.06.2013
*      FROM crmd_orderadm_h AS a
*      LEFT OUTER JOIN crmd_customer_h AS b
*        ON a~guid EQ b~guid
*      UP TO p_psize ROWS
*      INTO TABLE i_crmd_orderadm_h
*      WHERE a~process_type IN r_edwa AND
** Begin AG 22.07.2014
** ho inserito la condizione sul guid percè è chiave e non rischiamo di
** perdere il record duplicato nei multipli del package size
** inoltre ho spostato l condizione del guid prima per poter utilizzare l'indice Z2
*            a~guid         GT gv_guid AND
**            a~object_id    GT gv_object_id AND "add MS 17/07/14
** End   AG 22.07.2014
*            a~object_id    IN s_objid
*        AND changed_by     NOT IN gr_chusr
*     AND   ( ( a~created_at GE p_date_f AND a~created_at LE va_date_t ) OR
*          ( a~changed_at GE p_date_f AND a~changed_at LE va_date_t ) )
*    order by a~guid. "object_id . "add MS 17/07/14 " Mod AG 22.07.2014
**     all object are selected
*    IF sy-subrc NE 0.
*      EXIT.
*    ENDIF.
*
*    DESCRIBE TABLE i_crmd_orderadm_h LINES lv_lines.
*    READ TABLE i_crmd_orderadm_h INTO ls_order INDEX lv_lines.
*    IF sy-subrc IS INITIAL.
** Begin AG 22.07.2014
** ho inserito la condizione sul guid percè è chiave e non rischiamo di
** perdere il record duplicato nei multipli del package size
*      gv_guid = ls_order-guid.
**      gv_object_id = ls_order-object_id.
** End   AG 22.07.2014
*    ENDIF.
*
** Begin MS 17.07.2014
*
**    PERFORM valorizza_guid.
**    PERFORM call_bapi_getdetailmul.
**    PERFORM elabora.
**    PERFORM nettoyer_tout.
*
**  ENDSELECT.
*
*    PERFORM f_call_parall.
*
*  ENDDO.
** End MS 17.07.2014

************************************
* la select con la ORDER_BY rallenta parecchio, quindi l'ho tolta
* ed ho effettuato una elaborazione con il file
  DATA: ls_order TYPE t_crmd_orderadm_h,
        lv_lines TYPE i.
  DATA va_filetemp(255) TYPE c.
  DATA lv_line          TYPE string.
  DATA lv_cnt           TYPE i.
  DATA lv_char32        TYPE char32.
  DATA lv_string        TYPE string.
  DATA lv_cr_at         TYPE char15.
  DATA lv_ch_at         TYPE char15.

  DATA ls_ord_h TYPE t_crmd_orderadm_h.

* apro il file
  PERFORM recupera_file USING p_flog
                              'TEMP'
                      CHANGING va_filetemp.

  OPEN DATASET va_filetemp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

  DATA w_zzfld00000k TYPE crmd_customer_h-zzfld00000k.


* salvo tutti i valori della select in un file
  SELECT a~guid a~object_id a~process_type a~created_at a~changed_at
         b~zzcustomer_h0801 b~zz_idunivoco
         b~zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
*         b~zz_n_contr_ptb
*         b~zzfld00000k
         b~zz_altra_period
*         b~zzzfirst_contact
         b~zzcustomer_h2309
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
    FROM crmd_orderadm_h AS a
    LEFT OUTER JOIN crmd_customer_h AS b
      ON a~guid EQ b~guid
    INTO CORRESPONDING FIELDS OF TABLE i_crmd_orderadm_h
        PACKAGE SIZE p_psize
    WHERE a~process_type IN r_edwa AND
          a~object_id    IN s_objid
      AND changed_by     NOT IN gr_chusr
   AND   ( ( a~created_at GE p_date_f AND a~created_at LE va_date_t ) OR
        ( a~changed_at GE p_date_f AND a~changed_at LE va_date_t ) ).


    CLEAR w_zzfld00000k.

    LOOP AT i_crmd_orderadm_h INTO ls_ord_h.
      CLEAR ls_ord_h-zzfld00000k.
      SELECT SINGLE zzfld00000k FROM crmd_customer_h INTO w_zzfld00000k WHERE guid = ls_ord_h-guid.
      IF sy-subrc = 0.
        MOVE w_zzfld00000k TO ls_ord_h-zzfld00000k.
*        WRITE w_zzfld00000k TO ls_ord_h-zzfld00000k. "CURRENCY 'EUR'.
*        DO.
*          IF ls_ord_h-zzfld00000k CS '.'.
*            REPLACE '.' WITH '' INTO ls_ord_h-zzfld00000k.
*          ELSE.
*            EXIT.
*          ENDIF.
*        ENDDO.
*
*        REPLACE ',' WITH '.' INTO ls_ord_h-zzfld00000k.
        CONDENSE ls_ord_h-zzfld00000k NO-GAPS.
      ENDIF.

      CLEAR lv_line.
      CLEAR lv_char32.
      lv_char32 = ls_ord_h-guid.
      lv_cr_at = ls_ord_h-created_at.
      lv_ch_at = ls_ord_h-changed_at.
      CONCATENATE lv_char32
                  ls_ord_h-object_id
                  ls_ord_h-process_type
                  lv_cr_at
                  lv_ch_at
                  ls_ord_h-zzcustomer_h0801
                  ls_ord_h-zz_idunivoco
                  ls_ord_h-zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                              ls_ord_h-zzfld00000k   "zz_n_contr_ptb
                              ls_ord_h-zz_altra_period
                              ls_ord_h-zzcustomer_h2309 "zzzfirst_contact
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
      INTO lv_line SEPARATED BY ';'.
      TRANSFER lv_line TO va_filetemp.
    ENDLOOP.
  ENDSELECT.

  CLOSE DATASET va_filetemp.
  REFRESH i_crmd_orderadm_h[].

  OPEN DATASET va_filetemp  FOR INPUT IN TEXT MODE
                               ENCODING DEFAULT.

  CHECK sy-subrc EQ 0.
  CLEAR lv_cnt.
* inizio l'elaborazione
  DO.
    CLEAR:ls_ord_h, lv_char32, lv_cr_at, lv_ch_at , lv_line.
    READ DATASET va_filetemp INTO lv_line.
    IF sy-subrc NE 0.
      EXIT.
    ENDIF.

    SPLIT lv_line AT ';' INTO lv_char32
                              ls_ord_h-object_id
                              ls_ord_h-process_type
                              lv_cr_at
                              lv_ch_at
                              ls_ord_h-zzcustomer_h0801
                              ls_ord_h-zz_idunivoco
                              ls_ord_h-zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                              ls_ord_h-zzfld00000k   "zz_n_contr_ptb
                              ls_ord_h-zz_altra_period
                              ls_ord_h-zzcustomer_h2309. "zzzfirst_contact.
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016

    ls_ord_h-guid = lv_char32.
    ls_ord_h-created_at = lv_cr_at.
    ls_ord_h-changed_at = lv_ch_at.

    APPEND ls_ord_h TO i_crmd_orderadm_h.
    lv_cnt = lv_cnt + 1.
    IF lv_cnt GE p_psize.
      CLEAR lv_cnt.
      PERFORM f_call_parall.
    ENDIF.
  ENDDO.

* gestione dell'ultimo pacchetto
  IF i_crmd_orderadm_h[] IS NOT INITIAL.
    PERFORM f_call_parall.
  ENDIF.

  CLOSE DATASET  va_filetemp.
  DELETE DATASET va_filetemp.

* End   AG 24.07.2014

ENDFORM.                    " select_orderadm_h

*&---------------------------------------------------------------------*
*&      Form  call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_BUSPROCESSND_GETDETAILMUL
*----------------------------------------------------------------------*
FORM call_bapi_getdetailmul .

* Begin AG 22.07.2014
* la form non viene mai richiamata

*  DATA lt_guid LIKE i_guid.
*  REFRESH: i_activity, i_appointment, i_header, i_partner, i_service_os,
*           i_status, i_text,i_doc_flow[].
*
** Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
** essere modificata
*  lt_guid[] = i_guid[].
*
*  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
*    TABLES
*      guid        = lt_guid
*      header      = i_header
*      activity    = i_activity
*      partner     = i_partner
*      appointment = i_appointment
*      text        = i_text
*      service_os  = i_service_os
*      status      = i_status
*      doc_flow    = i_doc_flow." DOC_FLOW change on 25.11.2013
* End   AG 22.07.2014

ENDFORM.                    " call_bapi_getdetailmul


*&---------------------------------------------------------------------*
*&      Form  valorizza_guid
*&---------------------------------------------------------------------*
*       Valorizza la tabella GUID per la chiamata della BAPI
*----------------------------------------------------------------------*
FORM valorizza_guid .

* Begin AG 22.07.2014
* la form non viene mai richiamata


*  DATA lw_guid LIKE LINE OF i_guid.
*
*  REFRESH i_guid.
*  LOOP AT i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>.
*    PERFORM trascod_guid_16_32 USING <fs_crmd_orderadm_h>-guid
*                               CHANGING lw_guid-guid.
*    APPEND lw_guid TO i_guid.
*  ENDLOOP.

* End   AG 22.07.2014

ENDFORM.                    " valorizza_guid


*&---------------------------------------------------------------------*
*&      Form  trascod_guid_16_32
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da RAW16 a CHAR32
*----------------------------------------------------------------------*
FORM trascod_guid_16_32 USING    p_guid16 TYPE sysuuid-x
                        CHANGING p_guid32 TYPE sysuuid-c.
  CLEAR p_guid32.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_16_32'
    EXPORTING
      i_guid16 = p_guid16
    IMPORTING
      e_guid32 = p_guid32.
ENDFORM.                    " trascod_guid_16_32

*&---------------------------------------------------------------------*
*&      Form  trascod_guid_32_16
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da CHAR32 a RAW16
*----------------------------------------------------------------------*
FORM trascod_guid_32_16 USING    p_guid32 TYPE sysuuid-c
                        CHANGING p_guid16 TYPE sysuuid-x.
  CLEAR p_guid16.
  CALL FUNCTION 'BCA_OBJ_RTW_GUID_CONVERT_32_16'
    EXPORTING
      i_guid32 = p_guid32
    IMPORTING
      e_guid16 = p_guid16.
ENDFORM.                    "trascod_guid_32_16

*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora
* Begin AG 22.07.2014
      CHANGING pt_header           TYPE tp_header
               pt_activity         TYPE tp_activity
               pt_partner          TYPE tp_partner
               pt_service_os       TYPE tp_service_os
               pt_status           TYPE tp_status
               pt_guid             TYPE tp_guid
               pt_appointment      TYPE tp_appointment
               pt_text             TYPE tp_text
               pt_doc_flow         TYPE tp_doc_flow
               pt_crmd_orderadm_h  TYPE tp_crmd_orderadm_h
               pt_ruolo_ref        TYPE tp_ruolo_ref.
* End   AG 22.07.2014
  .

* Begin AG 22.07.2014
*  SORT: i_activity        BY guid,
*        i_appointment     BY ref_guid appt_type,
*        i_header          BY guid,
*        i_partner         BY ref_guid ref_partner_fct,
*        i_service_os      BY ref_guid cat_type,
*        i_status          BY guid,
*        i_text            BY ref_guid,
*        i_crmd_orderadm_h BY guid,
*        i_doc_flow        BY objtype_a,
*        i_ruolo_ref       BY partner."ADD MS 17/07/14

*  DELETE i_text WHERE tdid NOT IN r_edwn OR
*                      tdspras NE ca_i.

  SORT: pt_activity        BY guid,
        pt_appointment     BY ref_guid appt_type,
        pt_header          BY guid,
        pt_partner         BY ref_guid ref_partner_fct,
        pt_service_os      BY ref_guid cat_type,
        pt_status          BY guid,
        pt_text            BY ref_guid,
        pt_crmd_orderadm_h BY guid,
        pt_doc_flow        BY objtype_a,
        pt_ruolo_ref       BY partner.

  DELETE pt_text WHERE tdid NOT IN r_edwn OR
                       tdspras NE ca_i.

* End   AG 22.07.2014

  LOOP AT pt_guid "i_guid " Mod AG 22.07.2014
    ASSIGNING <fs_guid>.
* Begin MS 17.07.2014
    PERFORM unassign_fs.

* Begin AG 22.07.2014
*    PERFORM read_table.
*    PERFORM read_table_status.
*    PERFORM val_record.

    PERFORM read_table USING pt_header[]
                             pt_activity[]
                             pt_partner[]
                             pt_service_os[]
                             pt_status[]
                             pt_guid[]
                             pt_appointment[]
                             pt_text[]
                             pt_doc_flow[]
                             pt_crmd_orderadm_h[]
                             pt_ruolo_ref[].

    PERFORM read_table_status USING pt_status[].

    PERFORM val_record USING pt_text[]
                             pt_doc_flow[].
* End   AG 22.07.2014



* End MS 17.07.2014
  ENDLOOP.

ENDFORM.                    " elabora

*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_PARAM
*----------------------------------------------------------------------*
FORM read_param USING p_name_par TYPE zca_param-z_nome_par
                      p_z_appl   TYPE zca_param-z_appl
                CHANGING p_z_val_par TYPE zca_param-z_val_par.
  DATA lt_return TYPE STANDARD TABLE OF bapiret2.

  CLEAR p_z_val_par.
  CALL FUNCTION 'Z_CA_READ_PARAM'
    EXPORTING
      z_name_par = p_name_par
      z_appl     = p_z_appl
    IMPORTING
      z_val_par  = p_z_val_par
    TABLES
      return     = lt_return.

  DELETE lt_return WHERE type NE ca_a AND
                         type NE ca_e.
  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e13 p_name_par space space.
  ENDIF.

ENDFORM.                    " read_param

*&---------------------------------------------------------------------*
*&      Form  unassign_fs
*&---------------------------------------------------------------------*
*       Esegue l'unassign dei field symbol utilizzati dall'elaborazione
*----------------------------------------------------------------------*
FORM unassign_fs .
  UNASSIGN: <fs_activity>, <fs_appointment>, <fs_header>,
            <fs_partner_cl>, <fs_partner_op>, <fs_service_os>, <fs_service_os_mot>,
            <fs_status>, <fs_text>, <fs_crmd_orderadm_h>, <fs_partner_ref>,
            <fs_ruolo_ref>."ADD MS 17/07/14
ENDFORM.                    " unassign_fs

*&---------------------------------------------------------------------*
*&      Form  read_table
*&---------------------------------------------------------------------*
*       Lettura dei dati estratti per il caricamento del file
*----------------------------------------------------------------------*
FORM read_table
* Begin AG 22.07.2014
* oltre ad inserire i parametri di input ho modificato anche la lettura
* dalle tabelle, che prima era fatta su quelle globali
         USING pt_header           TYPE tp_header
               pt_activity         TYPE tp_activity
               pt_partner          TYPE tp_partner
               pt_service_os       TYPE tp_service_os
               pt_status           TYPE tp_status
               pt_guid             TYPE tp_guid
               pt_appointment      TYPE tp_appointment
               pt_text             TYPE tp_text
               pt_doc_flow         TYPE tp_doc_flow
               pt_crmd_orderadm_h  TYPE tp_crmd_orderadm_h
               pt_ruolo_ref        TYPE tp_ruolo_ref.
* End   AG 22.07.2014
  .

  DATA lv_guid_16 TYPE crmd_orderadm_h-guid.
* Trascodifica il GUID per leggere dalla tabella I_CRMD_ORDERADM_H
  PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                             CHANGING lv_guid_16.

* Lettura record dalla tabella HEADER
  READ TABLE pt_header ASSIGNING <fs_header>
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.

* Lettura record dalla tabella PARTNER (per cliente)
  READ TABLE pt_partner ASSIGNING <fs_partner_cl>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctcl BINARY SEARCH.

* Lettura record dalla tabella PARTNER (per operatore)
  READ TABLE pt_partner ASSIGNING <fs_partner_op>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctdip BINARY SEARCH.

* BEGIN CP 15/05/2009
* Lettura record dalla tabella PARTNER (per Ufficio Postale)
  READ TABLE pt_partner ASSIGNING <fs_partner_up>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctup BINARY SEARCH.
* END CP 15/05/2009


  " CL - Inizio Modifiche  del 01.07.2013
  "Lettura record dalla tabella PARTNER (per Referente)
  CLEAR gv_referente.
  READ TABLE pt_partner ASSIGNING <fs_partner_ref>
      WITH KEY ref_guid        = <fs_guid>-guid
               ref_partner_fct = va_edw_fctref BINARY SEARCH.
  IF <fs_partner_ref> IS NOT ASSIGNED.
    CLEAR gv_referente.
  ELSE.
    PERFORM trascod_alpha USING <fs_partner_ref>-ref_partner_no
                       CHANGING gv_referente.
  ENDIF.

* Begin MS 17.07.2014

  READ TABLE pt_ruolo_ref WITH KEY partner = gv_referente
                        ASSIGNING <fs_ruolo_ref> BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    gv_ruolo_ref = <fs_ruolo_ref>-zzruolointer.
  ELSE.
    CLEAR gv_ruolo_ref.
  ENDIF.
*   End MS 17.07.2014


  " CL - Fine Modifiche del 01.07.2013


* Lettura record dalla tabella SERVICE_OS
  READ TABLE pt_service_os ASSIGNING <fs_service_os>
    WITH KEY ref_guid = <fs_guid>-guid
             cat_type = va_edw_risult(2)    " ADD CP 23.11.2011
    BINARY SEARCH.


  " Begin CP 23.11.2011
  READ TABLE pt_service_os ASSIGNING <fs_service_os_mot>
    WITH KEY ref_guid = <fs_guid>-guid
             cat_type = va_edw_motivo(2)
    BINARY SEARCH.
  "End CP 23.11.2011

* Lettura record dalla tabella ACTIVITY
  READ TABLE pt_activity ASSIGNING <fs_activity>
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.

* Lettura record dalla tabella CRMD_CUSTOMER_H (estratta in join con
* la tabella CRMD_ORDERADM_H)

  READ TABLE pt_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>
  WITH KEY guid = lv_guid_16 BINARY SEARCH.

* Lettura record dalla tabella APPOINTMENT
  READ TABLE pt_appointment ASSIGNING <fs_appointment>
    WITH KEY ref_guid  = <fs_guid>-guid
             appt_type = va_edw_type_ac BINARY SEARCH.
  IF sy-subrc IS NOT INITIAL. "In assenza del record con APPT_TYPE = <EDW_TYPE_AC>
    READ TABLE pt_appointment ASSIGNING <fs_appointment>
      WITH KEY ref_guid  = <fs_guid>-guid
               appt_type = va_edw_type BINARY SEARCH.
  ENDIF.

ENDFORM.                    " read_table

*&---------------------------------------------------------------------*
*&      Form  read_table_status
*&---------------------------------------------------------------------*
*       Lettura dei dati estratti dalla tabella STATUS per il
*       caricamento del file
*----------------------------------------------------------------------*
FORM read_table_status

* Begin AG 22.07.2014
* oltre ad inserire i parametri di input ho modificato anche la lettura
* dalle tabelle, che prima era fatta su quelle globali
USING pt_status           TYPE tp_status
* End   AG 22.07.2014
  .
* Loop a doppio indice sulle posizioni della tabella STATUS
* relative al GUID corrente, per trovare un record con il campo
* USER_STAT_PROC valorizzato
  READ TABLE pt_status TRANSPORTING NO FIELDS
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.
  CHECK sy-subrc IS INITIAL.
  LOOP AT pt_status ASSIGNING <fs_status> FROM sy-tabix.
    IF <fs_status>-guid NE <fs_guid>-guid OR
       <fs_status>-user_stat_proc IS NOT INITIAL. "Se il campo è valorizzato, esci
      EXIT.
    ENDIF.
  ENDLOOP.

* Se è uscito senza trovare il record, ma solo perchè erano finite le
* posizioni per il GUID corrente, dereferenzia il puntatore
  IF <fs_status>-guid NE <fs_guid>-guid.
    UNASSIGN <fs_status>.
  ENDIF.
ENDFORM.                    " read_table_status

*&---------------------------------------------------------------------*
*&      Form  val_record
*&---------------------------------------------------------------------*
*       Valorizza i record da caricare sui file
*----------------------------------------------------------------------*
FORM val_record

* Begin AG 22.07.2014
* oltre ad inserire i parametri di input ho modificato anche la lettura
* dalle tabelle, che prima era fatta su quelle globali
         USING pt_text             TYPE tp_text
               pt_doc_flow         TYPE tp_doc_flow
* End   AG 22.07.2014
  .
  TYPES: BEGIN OF t_guid_z3o3,
           guid             TYPE crmd_orderadm_h-guid,
           zzcustomer_h0801 TYPE crmd_customer_h-zzcustomer_h0801,
         END OF t_guid_z3o3.

  DATA: lv_recout              TYPE string,
        lv_reclog              TYPE string,
        lv_tipo_contatto(4)    TYPE c,
        lv_cod_attivita(10)    TYPE c,
        lv_descrizione(40)     TYPE c,
        lv_data_inizio(8)      TYPE c,
        lv_ora_inizio(6)       TYPE c,
        lv_data_fine(8)        TYPE c,
        lv_ora_fine(6)         TYPE c,
        lv_cod_cliente_crm(16) TYPE c,
        lv_operatore(16)       TYPE c,
        lv_uff_post(16)        TYPE c, "ADD CP 15/05/2009
        lv_cod_stato(5)        TYPE c,
        lv_cod_risultato(14)   TYPE c,
        lv_appunti(255)        TYPE c,
        lv_cod_campagna_sw(24) TYPE c,
        lv_priorita_cmp(6)     TYPE c,
        lv_data_creazione(14)  TYPE c, "ADD CP 15/05/2009
        lv_data_mod(14)        TYPE c, "ADD CP 15/05/2009
        lv_category(3)         TYPE c, "G.Mele 12/11/2008
        lv_idunivoco(32)       TYPE c,
        lv_cod_motivo(14)      TYPE c, " ADD CP 23.11.2011
        lv_prov(5)             TYPE c, " ADD CP 23.11.2011
*        lv_sede_lav(2)         TYPE c, "ADD CL - 03.06.2013 - Delete CL - 13.06.2013
        lv_acapo_0a            TYPE string,
        lv_acapo_0d            TYPE string,
        lv_referente(10)       TYPE c,   "ADD CL 01.07.2013
        lv_ruolo_ref(3)        TYPE c,   "ADD CL 01.07.2013
        lv_cod_opp_crm(10)     TYPE c,   "DOC_FLOW change on 25.11.2013
        lv_cod_lea_crm(10)     TYPE c,  "-- ADD CP 20.01.2014
        ls_doc_flow            TYPE bapibus20001_doc_flow_dis,  "DOC_FLOW change on 25.11.2013
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
        lv_contr_ptb(20)       TYPE c,
        lv_altra_period(60)    TYPE c,
        lv_first_contact(30)   TYPE c.
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016

  DATA: lv_zzcustomer_h0801 TYPE zeew_dataelement0801,
        t_doc_flow_app      TYPE TABLE OF bapibus20001_doc_flow_dis,
        t_guid_z3o3         TYPE TABLE OF t_guid_z3o3,
        ls_guid_z3o3        TYPE t_guid_z3o3,
        lv_ex_z3o3          TYPE char1.

  DATA:
    r_guid  TYPE RANGE OF guid_32,
    p_range LIKE LINE OF r_guid.

  CLEAR: lv_acapo_0a, lv_acapo_0d.

  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0A'
    IMPORTING
      s = lv_acapo_0a.

  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0D'
    IMPORTING
      s = lv_acapo_0d.

  IF <fs_header> IS ASSIGNED.
    lv_tipo_contatto = <fs_header>-process_type.
    lv_cod_attivita  = <fs_header>-object_id.
    lv_descrizione   = <fs_header>-description.
  ENDIF.

  IF <fs_appointment> IS ASSIGNED.
    lv_data_inizio = <fs_appointment>-date_from.
    lv_ora_inizio  = <fs_appointment>-time_from.
    lv_data_fine   = <fs_appointment>-date_to.
    lv_ora_fine    = <fs_appointment>-time_to.
  ENDIF.

  IF <fs_partner_cl> IS ASSIGNED.
    PERFORM trascod_alpha USING    <fs_partner_cl>-ref_partner_no
                          CHANGING lv_cod_cliente_crm.
    " -- Begin CP 17.02.2011
  ELSE.
    lv_cod_cliente_crm = va_bp_dummy.
    " -- End CP 17.02.2011
  ENDIF.

  IF <fs_partner_op> IS ASSIGNED.
    PERFORM trascod_alpha USING    <fs_partner_op>-ref_partner_no
                          CHANGING lv_operatore.
  ENDIF.
* BEGIN CP 15/05/2009
  IF <fs_partner_up> IS ASSIGNED.
    PERFORM trascod_alpha USING    <fs_partner_up>-ref_partner_no
                          CHANGING lv_uff_post.
  ENDIF.
** END CP 15/05/2009



  IF <fs_status> IS ASSIGNED.
    lv_cod_stato = <fs_status>-status.
  ENDIF.

  IF <fs_service_os> IS ASSIGNED.
    CONCATENATE <fs_service_os>-cat_type
                <fs_service_os>-code_group
                <fs_service_os>-code INTO lv_cod_risultato.
  ENDIF.

  " Begin CP 23.11.2011
  IF <fs_service_os_mot> IS ASSIGNED.
    CONCATENATE <fs_service_os_mot>-cat_type
                <fs_service_os_mot>-code_group
                <fs_service_os_mot>-code INTO lv_cod_motivo.
  ENDIF.
  "End CP 23.11.2011

* Concatenazione delle note
  READ TABLE pt_text TRANSPORTING NO FIELDS
    WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.
  LOOP AT pt_text ASSIGNING <fs_text> FROM sy-tabix.
    IF <fs_text>-ref_guid NE <fs_guid>-guid. EXIT. ENDIF.

* -------- Inizio KLP MOD 03/09/2008
*    CONCATENATE lv_appunti <fs_text>-tdline INTO lv_appunti.
    CONCATENATE  lv_appunti <fs_text>-tdline
           INTO  lv_appunti
    SEPARATED BY space.
* -------- Fine KLP MOD 03/09/2008

  ENDLOOP.

  IF <fs_crmd_orderadm_h> IS ASSIGNED.
    lv_cod_campagna_sw = <fs_crmd_orderadm_h>-zzcustomer_h0801.
    lv_idunivoco       = <fs_crmd_orderadm_h>-zz_idunivoco.
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
    lv_contr_ptb         = <fs_crmd_orderadm_h>-zzfld00000k.  "zz_n_contr_ptb.
    lv_altra_period      = <fs_crmd_orderadm_h>-zz_altra_period.
    lv_first_contact    = <fs_crmd_orderadm_h>-zzcustomer_h2309. "zzzfirst_contact.
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
    PERFORM f_convert_tmstmp USING <fs_crmd_orderadm_h>-created_at
                              CHANGING lv_data_creazione.          "ADD CP 15/05/2009
    PERFORM f_convert_tmstmp USING <fs_crmd_orderadm_h>-changed_at
                              CHANGING lv_data_mod.                "ADD CP 15/05/2009
    lv_prov       = <fs_crmd_orderadm_h>-zz_provenienza.           " ADD CP 23.11.2011
*    lv_sede_lav   = <fs_crmd_orderadm_h>-zz_sede_lav.              "ADD CL - 03.06.2013 - Delete CL - 13.06.2013
  ENDIF.

  IF <fs_activity> IS ASSIGNED.
    lv_priorita_cmp = <fs_activity>-act_location.
*   Begin G.Mele 12/11/2008
    CLEAR lv_category.
    lv_category   = <fs_activity>-category.
*   End G.Mele 12/11/2008
  ENDIF.

* -- Inizio RF ADD 09/02/2009
* -- Eliminazione caratteri pipe da campo descrizione e note
  REPLACE ALL OCCURRENCES OF ca_sep IN lv_descrizione WITH gc_trattino.
  REPLACE ALL OCCURRENCES OF ca_sep IN lv_appunti WITH gc_trattino.
* -- Fine RF ADD 09/02/2009

  " CL - Inizio Modifiche  del 01.07.2013
  lv_referente = gv_referente.
  lv_ruolo_ref = gv_ruolo_ref.
  " CL - Fine Modifiche del 01.07.2013

  "DOC_FLOW changes start  on 25.12.2013
  IF <fs_header> IS ASSIGNED.
    READ TABLE pt_doc_flow   INTO ls_doc_flow WITH KEY ref_guid =  <fs_header>-guid
                                                      objtype_b = 'BUS2000111'.
    IF sy-subrc = 0.
      SELECT SINGLE object_id
             FROM crmd_orderadm_h
             INTO lv_cod_opp_crm
             WHERE guid = ls_doc_flow-objkey_b.
    ENDIF.

    " -- Begin CP 20.01.2014

    READ TABLE pt_doc_flow   INTO ls_doc_flow WITH KEY ref_guid =  <fs_header>-guid
                                                      objtype_a = 'BUS2000108'.
    IF sy-subrc = 0.
      SELECT SINGLE object_id
             FROM crmd_orderadm_h
             INTO lv_cod_lea_crm
             WHERE guid = ls_doc_flow-objkey_a.
    ENDIF.
    " -- End CP 20.01.2014


  ENDIF.


*Creo tabella d'appoggio per ricercare nelle relazioni le telefonate in campagna
  t_doc_flow_app[] = pt_doc_flow[].

*Lascio solo le attività legate al GUID in elaborazione.
  DELETE t_doc_flow_app WHERE objtype_a NE 'BUS2000126' OR ref_guid NE  <fs_header>-guid.
  IF t_doc_flow_app[] IS NOT INITIAL.
*Creo il range per ricercare le telefonate in campagna in orderadm_h.
    LOOP AT t_doc_flow_app INTO ls_doc_flow.
      p_range-sign   = 'I'.
      p_range-option = 'EQ'.
      p_range-low    = ls_doc_flow-objkey_a.
      APPEND p_range TO r_guid. CLEAR p_range.
    ENDLOOP.
*verifico se i guid dei documenti precedenti presenti nella docflow
*sono di tipo telefonata in campagna e mi estraggo subito la campagna da essi presenti nella customer_h.
    SELECT a~guid a~zzcustomer_h0801
            FROM crmd_customer_h AS a JOIN crmd_orderadm_h AS b
           ON a~guid EQ b~guid INTO CORRESPONDING FIELDS OF TABLE t_guid_z3o3
           WHERE a~guid IN r_guid
            AND b~process_type = 'Z3O3'.
*Se sono presenti telefonate in campagna replico n volte il guid in elaborazione con la info corretta della campagna
    CLEAR  lv_ex_z3o3.
    LOOP AT t_guid_z3o3 INTO ls_guid_z3o3.
      CONCATENATE lv_tipo_contatto
                 lv_cod_attivita
                 lv_descrizione
                 lv_data_inizio
                 lv_ora_inizio
                 lv_data_fine
                 lv_ora_fine
                 lv_cod_cliente_crm
                 lv_operatore
                 lv_cod_stato
                 lv_cod_risultato
                 lv_appunti
*                lv_cod_campagna_sw
                 ls_guid_z3o3-zzcustomer_h0801
                 lv_priorita_cmp
                 lv_category     " G.Mele 12/11/2008
                 lv_idunivoco
                 lv_data_creazione "ADD CP 15/05/2009
                 lv_data_mod       "ADD CP 15/05/2009
                 lv_uff_post       "ADD CP 15/05/2009
                 lv_cod_motivo     " ADD CP 23.11.2011
                 lv_prov           " ADD CP 23.11.2011
*              lv_sede_lav       "ADD CL - 03.06.2013 - Delete CL - 13.06.2013
                 lv_referente       "ADD CL 01.07.2013
                 lv_ruolo_ref       "ADD CL 01.07.2013
                 lv_cod_opp_crm     "DOC_FLOW change on 25.12.2013
                 lv_cod_lea_crm     "-- ADD CP 20.01.2014
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                 lv_contr_ptb
                 lv_altra_period
                 lv_first_contact
                 INTO lv_recout SEPARATED BY ca_sep.

      REPLACE ALL OCCURRENCES OF lv_acapo_0d IN lv_recout WITH space.
      REPLACE ALL OCCURRENCES OF lv_acapo_0a IN lv_recout WITH space.

      TRANSFER lv_recout TO va_fileout.

      lv_ex_z3o3 = 'X'.
      CLEAR ls_guid_z3o3.
    ENDLOOP.
  ENDIF.
*Se non sono presenti telefonate in campagna associate lascio il processo come prima.
  IF lv_ex_z3o3 IS INITIAL.
* Trasferimento al file di out
    CONCATENATE lv_tipo_contatto
                lv_cod_attivita
                lv_descrizione
                lv_data_inizio
                lv_ora_inizio
                lv_data_fine
                lv_ora_fine
                lv_cod_cliente_crm
                lv_operatore
                lv_cod_stato
                lv_cod_risultato
                lv_appunti
                lv_cod_campagna_sw
                lv_priorita_cmp
                lv_category     " G.Mele 12/11/2008
                lv_idunivoco
                lv_data_creazione "ADD CP 15/05/2009
                lv_data_mod       "ADD CP 15/05/2009
                lv_uff_post       "ADD CP 15/05/2009
                lv_cod_motivo     " ADD CP 23.11.2011
                lv_prov           " ADD CP 23.11.2011
*              lv_sede_lav       "ADD CL - 03.06.2013 - Delete CL - 13.06.2013
                lv_referente       "ADD CL 01.07.2013
                lv_ruolo_ref       "ADD CL 01.07.2013
                lv_cod_opp_crm     "DOC_FLOW change on 25.12.2013
                lv_cod_lea_crm     "-- ADD CP 20.01.2014
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                lv_contr_ptb
                lv_altra_period
                lv_first_contact
                INTO lv_recout SEPARATED BY ca_sep.

    REPLACE ALL OCCURRENCES OF lv_acapo_0d IN lv_recout WITH space.
    REPLACE ALL OCCURRENCES OF lv_acapo_0a IN lv_recout WITH space.

    TRANSFER lv_recout TO va_fileout.
  ENDIF.

* Trasferimento al file di log
  CONCATENATE lv_cod_attivita
              text-l01
              INTO lv_reclog SEPARATED BY ca_sep.
  TRANSFER lv_reclog TO va_filelog.

ENDFORM.                    " val_record

*&---------------------------------------------------------------------*
*&      Form  trascod_alpha
*&---------------------------------------------------------------------*
*       Applica la routine di conversione CONVERSION_EXIT_ALPHA_OUTPUT
*       per rimuovere gli spazi iniziali e gli zeri non significativi
*----------------------------------------------------------------------*
FORM trascod_alpha USING    p_input TYPE any
                   CHANGING p_output TYPE any.
  CLEAR p_output.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
    EXPORTING
      input  = p_input
    IMPORTING
      output = p_output.
ENDFORM.                    " trascod_alpha

*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .

  PERFORM get_param.

* Begin AG 24.07.2014
** Begin MS 17.07.2014
**  SELECT a~guid a~object_id a~process_type a~created_at a~changed_at
**         b~zzcustomer_h0801 b~zz_idunivoco
**         b~zz_provenienza   " ADD CP 23.11.2011
***         b~zz_sede_lav "ADD CL - 05.06.2013 - Delete CL - 13.06.2013
**    FROM crmd_orderadm_h AS a
**    LEFT OUTER JOIN crmd_customer_h AS b
**      ON a~guid EQ b~guid
**    INTO TABLE i_crmd_orderadm_h
**    WHERE a~object_id    IN s_objid
**      AND a~process_type IN r_edwa.
**
**  DATA: lt_crmd_orderadm_h_all TYPE SORTED TABLE OF t_crmd_orderadm_h
**        WITH HEADER LINE WITH UNIQUE KEY guid.
**
**  DATA: lw_crmd_orderadm_h     TYPE t_crmd_orderadm_h.
**
**  DATA: lw_size_all            TYPE i VALUE 0,
**        lw_loops               TYPE i VALUE 0,
**        lw_itab_index          TYPE i VALUE 0.
**
**  lt_crmd_orderadm_h_all[] = i_crmd_orderadm_h[].
**
**  DESCRIBE TABLE lt_crmd_orderadm_h_all LINES lw_size_all.
**  lw_loops = trunc( lw_size_all / p_psize ) + 1.
**
**  DO lw_loops TIMES.
**    CLEAR: i_crmd_orderadm_h.
**
**    DO p_psize TIMES.
**      lw_itab_index = lw_itab_index + 1.
**      READ TABLE lt_crmd_orderadm_h_all INDEX lw_itab_index
**      INTO lw_crmd_orderadm_h.
**      IF sy-subrc <> 0.
**        EXIT.
**      ENDIF.
**      APPEND lw_crmd_orderadm_h TO i_crmd_orderadm_h.
**    ENDDO.
**
**    IF i_crmd_orderadm_h IS NOT INITIAL.
**
**
**      PERFORM valorizza_guid.
**      PERFORM call_bapi_getdetailmul.
**      PERFORM elabora.
**      PERFORM nettoyer_tout.
**
**      TRY.
**        COMMIT WORK.
**      ENDTRY.
**    ENDIF.
**
**  ENDDO.
*
*  DATA: ls_order  TYPE t_crmd_orderadm_h,
*          lv_lines  TYPE i.
*
*
*  DO. "add MS 17/07/14
*    SELECT a~guid a~object_id a~process_type a~created_at a~changed_at
*           b~zzcustomer_h0801 b~zz_idunivoco
*           b~zz_provenienza   " ADD CP 23.11.2011
**         b~zz_sede_lav  "ADD CL 05.06.2013 - Delete CL - 13.06.2013
*      FROM crmd_orderadm_h AS a
*      LEFT OUTER JOIN crmd_customer_h AS b
*        ON a~guid EQ b~guid
*      UP TO p_psize ROWS
*      INTO TABLE i_crmd_orderadm_h
*      WHERE a~process_type IN r_edwa AND
** Begin AG 22.07.2014
** ho inserito la condizione sul guid percè è chiave e non rischiamo di
** perdere il record duplicato nei multipli del package size
** inoltre ho spostato l condizione del guid prima per poter utilizzare l'indice Z2
*            a~guid         GT gv_guid  AND
**            a~object_id    GT gv_object_id AND "add MS 17/07/14
** End   AG 22.07.2014
*            a~object_id    IN s_objid
*      ORDER BY a~guid. "object_id . "add MS 17/07/14 " Mod AG 22.07.2014
**     all object are selected
*    IF sy-subrc NE 0.
*      EXIT.
*    ENDIF.
*
*    DESCRIBE TABLE i_crmd_orderadm_h LINES lv_lines.
*    READ TABLE i_crmd_orderadm_h INTO ls_order INDEX lv_lines.
*    IF sy-subrc IS INITIAL.
** Begin AG 22.07.2014
** ho inserito la condizione sul guid percè è chiave e non rischiamo di
** perdere il record duplicato nei multipli del package size
*      gv_guid = ls_order-guid.
**      gv_object_id = ls_order-object_id.
** End   AG 22.07.2014
*    ENDIF.
*
*    PERFORM f_call_parall.
*    TRY.
*      COMMIT WORK.
*    ENDTRY.
*
*  ENDDO.
** End MS 17.07.2014

************************************
* la select con la ORDER_BY rallenta parecchio, quindi l'ho tolta
* ed ho effettuato una elaborazione con il file
  DATA: ls_order TYPE t_crmd_orderadm_h,
        lv_lines TYPE i.
  DATA va_filetemp(255) TYPE c.
  DATA lv_line          TYPE string.
  DATA lv_cnt           TYPE i.
  DATA lv_char32        TYPE char32.
  DATA lv_cr_at         TYPE char15.
  DATA lv_ch_at         TYPE char15.

  DATA ls_ord_h TYPE t_crmd_orderadm_h.

* apro il file
  PERFORM recupera_file USING p_flog
                              'TEMP'
                      CHANGING va_filetemp.

  OPEN DATASET va_filetemp FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.


  DATA w_zzfld00000k TYPE crmd_customer_h-zzfld00000k.
* salvo tutti i valori della select in un file
  SELECT a~guid a~object_id a~process_type a~created_at a~changed_at
         b~zzcustomer_h0801 b~zz_idunivoco
         b~zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
*         b~zz_n_contr_ptb
*         b~ZZFLD00000K
         b~zz_altra_period
*         b~zzzfirst_contact
         b~zzcustomer_h2309
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
    FROM crmd_orderadm_h AS a
    LEFT OUTER JOIN crmd_customer_h AS b
      ON a~guid EQ b~guid
    INTO CORRESPONDING FIELDS OF TABLE i_crmd_orderadm_h
        PACKAGE SIZE p_psize
    WHERE a~process_type IN r_edwa AND
          a~object_id    IN s_objid.


    CLEAR w_zzfld00000k.
    LOOP AT i_crmd_orderadm_h INTO ls_ord_h.
      SELECT SINGLE zzfld00000k FROM crmd_customer_h INTO w_zzfld00000k WHERE guid = ls_ord_h-guid.
      IF sy-subrc = 0.
        MOVE  w_zzfld00000k TO ls_ord_h-zzfld00000k.
        CONDENSE ls_ord_h-zzfld00000k.
      ENDIF.

      CLEAR lv_line.
      CLEAR lv_char32.
      lv_char32 = ls_ord_h-guid.
      lv_cr_at = ls_ord_h-created_at.
      lv_ch_at = ls_ord_h-changed_at.
      CONCATENATE lv_char32
                  ls_ord_h-object_id
                  ls_ord_h-process_type
                  lv_cr_at
                  lv_ch_at
                  ls_ord_h-zzcustomer_h0801
                  ls_ord_h-zz_idunivoco
                  ls_ord_h-zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                  ls_ord_h-zzfld00000k      "zz_n_contr_ptb
                  ls_ord_h-zz_altra_period
                  ls_ord_h-zzcustomer_h2309 "zzzfirst_contact
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
      INTO lv_line SEPARATED BY ';'.
      CONDENSE lv_line.
      TRANSFER lv_line TO va_filetemp.
      CLEAR w_zzfld00000k.
    ENDLOOP.
  ENDSELECT.

  CLOSE DATASET va_filetemp.
  REFRESH i_crmd_orderadm_h[].

  OPEN DATASET va_filetemp  FOR INPUT IN TEXT MODE
                               ENCODING DEFAULT.

  CHECK sy-subrc EQ 0.
  CLEAR lv_cnt.
* inizio l'elaborazione
  DO.
    CLEAR:ls_ord_h, lv_char32, lv_cr_at, lv_ch_at , lv_line.
    READ DATASET va_filetemp INTO lv_line.
    IF sy-subrc NE 0.
      EXIT.
    ENDIF.

    SPLIT lv_line AT ';' INTO lv_char32
                              ls_ord_h-object_id
                              ls_ord_h-process_type
                              lv_cr_at
                              lv_ch_at
                              ls_ord_h-zzcustomer_h0801
                              ls_ord_h-zz_idunivoco
                              ls_ord_h-zz_provenienza
*** BEGIN INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016
                              ls_ord_h-zzfld00000k       "zz_n_contr_ptb
                              ls_ord_h-zz_altra_period
                              ls_ord_h-zzcustomer_h2309. "zzzfirst_contact.
*** END   INSERT - INIZIATIVA 109011: Canali UP - CAP  07/06/2016

    ls_ord_h-guid = lv_char32.
    ls_ord_h-created_at = lv_cr_at.
    ls_ord_h-changed_at = lv_ch_at.

    APPEND ls_ord_h TO i_crmd_orderadm_h.
    lv_cnt = lv_cnt + 1.
    IF lv_cnt GE p_psize.
      CLEAR lv_cnt.
      PERFORM f_call_parall.
    ENDIF.
  ENDDO.

* gestione dell'ultimo pacchetto
  IF i_crmd_orderadm_h[] IS NOT INITIAL.
    PERFORM f_call_parall.
  ENDIF.

  CLOSE DATASET  va_filetemp.
  DELETE DATASET va_filetemp.

* End   AG 24.07.2014


ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  f_convert_tmstmp
*&---------------------------------------------------------------------*
*       Conversione timestamp in ora locale
*----------------------------------------------------------------------*
FORM f_convert_tmstmp  USING    p_timestamp TYPE comt_created_at_usr
                       CHANGING p_data      TYPE char14.

  DATA: lv_datlo TYPE  sy-datlo,
        lv_timlo TYPE  sy-timlo.
  CLEAR p_data.
  CALL FUNCTION 'IB_CONVERT_FROM_TIMESTAMP'
    EXPORTING
      i_timestamp = p_timestamp
    IMPORTING
      e_datlo     = lv_datlo
      e_timlo     = lv_timlo.

  CONCATENATE lv_datlo lv_timlo INTO p_data.

ENDFORM.                    " f_convert_tmstmp
*&---------------------------------------------------------------------*
*&      Form  nettoyer_tout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM nettoyer_tout .

  DATA: lv_object_name   TYPE crmt_object_name,
        lv_event_exetime TYPE crmt_event_exetime,
        lv_event         TYPE crmt_event,
        lv_header_guid   TYPE crmt_object_guid.

* Clean-up transactional data
  CALL FUNCTION 'CRM_ORDER_INITIALIZE'
    EXPORTING
      iv_initialize_whole_buffer = 'X'.

  CALL FUNCTION 'CRM_ACTIVITY_H_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up BP data
  CALL FUNCTION 'CRM_PARTNER_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up appointment data and time
  CALL FUNCTION 'CRM_DATES_INIT_EC'
    EXPORTING
      iv_object_name     = lv_object_name
      iv_event_exetime   = lv_event_exetime
      iv_event           = lv_event
      iv_header_guid     = lv_header_guid
      iv_all_header_guid = 'X'.

* Clean-up links
  CALL FUNCTION 'CRM_LINK_INIT_OW'.


* Clean-up text memory
  CALL FUNCTION 'FREE_TEXT_MEMORY'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " nettoyer_tout
*&---------------------------------------------------------------------*
*&      Form  F_SELECT_BUT000
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_select_but000 .
* Begin MS 17.07.2014
*  " CL - Inizio Modifiche del 01.07.2013
*  CLEAR gv_ruolo_ref.
*  SELECT SINGLE zzruolointer
*    INTO gv_ruolo_ref
*    FROM but000
*    WHERE partner EQ gv_referente.
*  IF sy-subrc IS NOT INITIAL.
*    CLEAR gv_ruolo_ref.
*  ENDIF.
*  " CL - Fine Modifiche del 01.07.2013
* End MS 17.07.2014
ENDFORM.                    " F_SELECT_BUT000
*&---------------------------------------------------------------------*
*&      Form  F_CALL_PARALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_call_parall .

* Begin MS 16.07.2014

  DATA : lv_task(30)    TYPE c.

  IF gv_running_task >= p_task.
    WAIT UNTIL gv_running_task < p_task.
  ENDIF.

  DO.
    ADD 1 TO gv_task_num.
    CONCATENATE 'ACT' gv_task_num sy-uname INTO lv_task.
    CALL FUNCTION 'Z_CA_EDWHAE_ACTIVITY_PARALL'
      STARTING NEW TASK lv_task
      DESTINATION IN GROUP 'POSTE'
      PERFORMING f_return_rfc ON END OF TASK
      EXPORTING
        i_edw_fctref          = va_edw_fctref "partner function referente
      TABLES
        i_crmd_orderadm_h     = i_crmd_orderadm_h
      EXCEPTIONS
        resource_failure      = 4
        communication_failure = 8
        system_failure        = 16.

    CASE sy-subrc.
      WHEN 0 .
***Segnaliamo che è partito un task
        gv_running_task = gv_running_task + 1.
        REFRESH: i_crmd_orderadm_h.
        EXIT.
      WHEN 4 .
**Attendiamo gli altri processi prima di lanciare i restanti
        WAIT UNTIL gv_running_task < p_task. "p_pack." Mod AG 06.06.2014
      WHEN OTHERS.
        REFRESH: i_crmd_orderadm_h.
        EXIT.
    ENDCASE.
  ENDDO.

* End MS 16.07.2014

ENDFORM.                    " F_CALL_PARALL
*&---------------------------------------------------------------------*
*&      Form  F_RETURN_RFC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_return_rfc  USING u_task_name.

* Begin AG 22.07.2014
  DATA: lt_header          TYPE tp_header,
        lt_activity        TYPE tp_activity,
        lt_partner         TYPE tp_partner,
        lt_service_os      TYPE tp_service_os,
        lt_status          TYPE tp_status,
        lt_guid            TYPE tp_guid,
        lt_appointment     TYPE tp_appointment,
        lt_text            TYPE tp_text,
        lt_doc_flow        TYPE tp_doc_flow,
        lt_crmd_orderadm_h TYPE tp_crmd_orderadm_h,
        lt_ruolo_ref       TYPE tp_ruolo_ref.
* End   AG 22.07.2014


  gv_running_task = gv_running_task - 1.
  RECEIVE RESULTS FROM FUNCTION 'Z_CA_EDWHAE_ACTIVITY_PARALL'
  TABLES
      et_header             = lt_header  "i_header " Mod AG 22.07.2014
      et_activity           = lt_activity "i_activity " Mod AG 22.07.2014
      et_partner            = lt_partner "i_partner " Mod AG 22.07.2014
      et_service_os         = lt_service_os "i_service_os " Mod AG 22.07.2014
      et_status             = lt_status "i_status " Mod AG 22.07.2014
      et_guid               = lt_guid "i_guid " Mod AG 22.07.2014
      et_appointment        = lt_appointment "i_appointment " Mod AG 22.07.2014
      et_text               = lt_text "i_text " Mod AG 22.07.2014
      et_doc_flow           = lt_doc_flow "i_doc_flow " Mod AG 22.07.2014
      i_crmd_orderadm_h     = lt_crmd_orderadm_h "i_crmd_orderadm_h " Mod AG 22.07.2014
      et_ruolo_ref          = lt_ruolo_ref "i_ruolo_ref " Mod AG 22.07.2014
  EXCEPTIONS
    resource_failure            = 4
    communication_failure       = 8
    system_failure              = 16
   OTHERS                       = 2.





  CHECK sy-subrc IS INITIAL.
* Begin AG 22.07.2014
*  PERFORM elabora.
  PERFORM elabora CHANGING lt_header[]
                           lt_activity[]
                           lt_partner[]
                           lt_service_os[]
                           lt_status[]
                           lt_guid[]
                           lt_appointment[]
                           lt_text[]
                           lt_doc_flow[]
                           lt_crmd_orderadm_h[]
                           lt_ruolo_ref[].
* End   AG 22.07.2014

  PERFORM nettoyer_tout.

* Begin AG 22.07.2014
*  REFRESH:i_header,
*          i_activity,
*          i_partner,
*          i_service_os,
*          i_status,
*          i_guid,
*          i_appointment,
*          i_text,
*          i_doc_flow,
*          i_crmd_orderadm_h,
*          i_ruolo_ref.
* End   AG 22.07.2014




ENDFORM.                    " F_RETURN_RFC


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
