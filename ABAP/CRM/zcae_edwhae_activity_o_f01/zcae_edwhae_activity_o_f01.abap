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

  DATA: lv_file TYPE string,
        lv_file2 TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

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

  CASE ca_x.
*   Estrazioni FULL
    WHEN r_full.
      PERFORM select_full.

*   Estrazioni DELTA
    WHEN r_delta.
      PERFORM select_delta.

    WHEN OTHERS.
  ENDCASE.

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
  SELECT a~guid a~process_type a~created_at a~changed_at
         b~zzcustomer_h0801 b~zz_idunivoco
         b~zz_provenienza   " ADD CP 23.11.2011
*         b~zz_sede_lav  "ADD CL 05.06.2013 - Delete CL - 13.06.2013
    FROM crmd_orderadm_h AS a
    LEFT OUTER JOIN crmd_customer_h AS b
      ON a~guid EQ b~guid
    INTO TABLE i_crmd_orderadm_h
    PACKAGE SIZE p_psize
    WHERE a~process_type IN r_edwa AND
          a~object_id    IN s_objid AND
          changed_by     NOT IN gr_chusr AND
      ( ( a~created_at GE p_date_f AND a~created_at LE va_date_t ) OR
        ( a~changed_at GE p_date_f AND a~changed_at LE va_date_t ) ).

    PERFORM valorizza_guid.
    PERFORM call_bapi_getdetailmul.
    PERFORM elabora.
    PERFORM nettoyer_tout.

  ENDSELECT.
ENDFORM.                    " select_orderadm_h

*&---------------------------------------------------------------------*
*&      Form  call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_BUSPROCESSND_GETDETAILMUL
*----------------------------------------------------------------------*
FORM call_bapi_getdetailmul .
  DATA lt_guid LIKE i_guid.
  REFRESH: i_activity, i_appointment, i_header, i_partner, i_service_os,
           i_status, i_text,i_doc_flow[].

* Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
* essere modificata
  lt_guid[] = i_guid[].

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid        = lt_guid
      header      = i_header
      activity    = i_activity
      partner     = i_partner
      appointment = i_appointment
      text        = i_text
      service_os  = i_service_os
      status      = i_status
      doc_flow    = i_doc_flow." DOC_FLOW change on 25.11.2013


ENDFORM.                    " call_bapi_getdetailmul

*&---------------------------------------------------------------------*
*&      Form  valorizza_guid
*&---------------------------------------------------------------------*
*       Valorizza la tabella GUID per la chiamata della BAPI
*----------------------------------------------------------------------*
FORM valorizza_guid .
  DATA lw_guid LIKE LINE OF i_guid.

  REFRESH i_guid.
  LOOP AT i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>.
    PERFORM trascod_guid_16_32 USING <fs_crmd_orderadm_h>-guid
                               CHANGING lw_guid-guid.
    APPEND lw_guid TO i_guid.
  ENDLOOP.
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
FORM elabora .
  SORT: i_activity        BY guid,
        i_appointment     BY ref_guid appt_type,
        i_header          BY guid,
        i_partner         BY ref_guid ref_partner_fct,
        i_service_os      BY ref_guid cat_type,
        i_status          BY guid,
        i_text            BY ref_guid,
        i_crmd_orderadm_h BY guid,
        i_doc_flow        BY objtype_a .

  DELETE i_text WHERE tdid NOT IN r_edwn OR
                      tdspras NE ca_i.

  LOOP AT i_guid ASSIGNING <fs_guid>.
    PERFORM unassign_fs.
    PERFORM read_table.
    PERFORM f_select_but000. "ADD CL
    PERFORM read_table_status.
    PERFORM val_record.
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
            <fs_status>, <fs_text>, <fs_crmd_orderadm_h>, <fs_partner_ref>.
ENDFORM.                    " unassign_fs

*&---------------------------------------------------------------------*
*&      Form  read_table
*&---------------------------------------------------------------------*
*       Lettura dei dati estratti per il caricamento del file
*----------------------------------------------------------------------*
FORM read_table .
  DATA lv_guid_16 TYPE crmd_orderadm_h-guid.
* Trascodifica il GUID per leggere dalla tabella I_CRMD_ORDERADM_H
  PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                             CHANGING lv_guid_16.

* Lettura record dalla tabella HEADER
  READ TABLE i_header ASSIGNING <fs_header>
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.

* Lettura record dalla tabella PARTNER (per cliente)
  READ TABLE i_partner ASSIGNING <fs_partner_cl>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctcl BINARY SEARCH.

* Lettura record dalla tabella PARTNER (per operatore)
  READ TABLE i_partner ASSIGNING <fs_partner_op>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctdip BINARY SEARCH.

* BEGIN CP 15/05/2009
* Lettura record dalla tabella PARTNER (per Ufficio Postale)
  READ TABLE i_partner ASSIGNING <fs_partner_up>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = va_edw_fctup BINARY SEARCH.
* END CP 15/05/2009

  " CL - Inizio Modifiche  del 01.07.2013
  "Lettura record dalla tabella PARTNER (per Referente)
  CLEAR gv_referente.
  READ TABLE i_partner ASSIGNING <fs_partner_ref>
      WITH KEY ref_guid        = <fs_guid>-guid
               ref_partner_fct = va_edw_fctref BINARY SEARCH.
  IF <fs_partner_ref> IS NOT ASSIGNED.
    CLEAR gv_referente.
  ELSE.
    PERFORM trascod_alpha USING <fs_partner_ref>-ref_partner_no
                       CHANGING gv_referente.
  ENDIF.
  " CL - Fine Modifiche del 01.07.2013

* Lettura record dalla tabella SERVICE_OS
  READ TABLE i_service_os ASSIGNING <fs_service_os>
    WITH KEY ref_guid = <fs_guid>-guid
             cat_type = va_edw_risult(2)    " ADD CP 23.11.2011
    BINARY SEARCH.


  " Begin CP 23.11.2011
  READ TABLE i_service_os ASSIGNING <fs_service_os_mot>
    WITH KEY ref_guid = <fs_guid>-guid
             cat_type = va_edw_motivo(2)
    BINARY SEARCH.
  "End CP 23.11.2011

* Lettura record dalla tabella ACTIVITY
  READ TABLE i_activity ASSIGNING <fs_activity>
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.

* Lettura record dalla tabella CRMD_CUSTOMER_H (estratta in join con
* la tabella CRMD_ORDERADM_H)
  READ TABLE i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>
    WITH KEY guid = lv_guid_16 BINARY SEARCH.

* Lettura record dalla tabella APPOINTMENT
  READ TABLE i_appointment ASSIGNING <fs_appointment>
    WITH KEY ref_guid  = <fs_guid>-guid
             appt_type = va_edw_type_ac BINARY SEARCH.
  IF sy-subrc IS NOT INITIAL. "In assenza del record con APPT_TYPE = <EDW_TYPE_AC>
    READ TABLE i_appointment ASSIGNING <fs_appointment>
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
FORM read_table_status .
* Loop a doppio indice sulle posizioni della tabella STATUS
* relative al GUID corrente, per trovare un record con il campo
* USER_STAT_PROC valorizzato
  READ TABLE i_status TRANSPORTING NO FIELDS
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.
  CHECK sy-subrc IS INITIAL.
  LOOP AT i_status ASSIGNING <fs_status> FROM sy-tabix.
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
FORM val_record .
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
        ls_doc_flow            TYPE bapibus20001_doc_flow_dis ."DOC_FLOW change on 25.11.2013

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
  READ TABLE i_text TRANSPORTING NO FIELDS
    WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.
  LOOP AT i_text ASSIGNING <fs_text> FROM sy-tabix.
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
    READ TABLE i_doc_flow   INTO ls_doc_flow WITH KEY ref_guid =  <fs_header>-guid
                                                      objtype_b = 'BUS2000111'.
    IF sy-subrc = 0.
      SELECT SINGLE object_id
             FROM crmd_orderadm_h
             INTO lv_cod_opp_crm
             WHERE guid = ls_doc_flow-objkey_b.
    ENDIF.

    " -- Begin CP 20.01.2014

    READ TABLE i_doc_flow   INTO ls_doc_flow WITH KEY ref_guid =  <fs_header>-guid
                                                      objtype_a = 'BUS2000108'.
    IF sy-subrc = 0.
      SELECT SINGLE object_id
             FROM crmd_orderadm_h
             INTO lv_cod_lea_crm
             WHERE guid = ls_doc_flow-objkey_a.
    ENDIF.
    " -- End CP 20.01.2014


  ENDIF.

  "DOC_FLOW changes end on 25.12.2013
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
              INTO lv_recout SEPARATED BY ca_sep.

  REPLACE ALL OCCURRENCES OF lv_acapo_0d IN lv_recout WITH space.
  REPLACE ALL OCCURRENCES OF lv_acapo_0a IN lv_recout WITH space.

  TRANSFER lv_recout TO va_fileout.

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

  SELECT a~guid a~process_type a~created_at a~changed_at
         b~zzcustomer_h0801 b~zz_idunivoco
         b~zz_provenienza   " ADD CP 23.11.2011
*         b~zz_sede_lav "ADD CL - 05.06.2013 - Delete CL - 13.06.2013
    FROM crmd_orderadm_h AS a
    LEFT OUTER JOIN crmd_customer_h AS b
      ON a~guid EQ b~guid
    INTO TABLE i_crmd_orderadm_h
    WHERE a~object_id    IN s_objid
      AND a~process_type IN r_edwa.

  DATA: lt_crmd_orderadm_h_all TYPE SORTED TABLE OF t_crmd_orderadm_h
        WITH HEADER LINE WITH UNIQUE KEY guid.

  DATA: lw_crmd_orderadm_h     TYPE t_crmd_orderadm_h.

  DATA: lw_size_all            TYPE i VALUE 0,
        lw_loops               TYPE i VALUE 0,
        lw_itab_index          TYPE i VALUE 0.

  lt_crmd_orderadm_h_all[] = i_crmd_orderadm_h[].

  DESCRIBE TABLE lt_crmd_orderadm_h_all LINES lw_size_all.
  lw_loops = trunc( lw_size_all / p_psize ) + 1.

  DO lw_loops TIMES.
    CLEAR: i_crmd_orderadm_h.

    DO p_psize TIMES.
      lw_itab_index = lw_itab_index + 1.
      READ TABLE lt_crmd_orderadm_h_all INDEX lw_itab_index
      INTO lw_crmd_orderadm_h.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      APPEND lw_crmd_orderadm_h TO i_crmd_orderadm_h.
    ENDDO.

    IF i_crmd_orderadm_h IS NOT INITIAL.
      PERFORM valorizza_guid.
      PERFORM call_bapi_getdetailmul.
      PERFORM elabora.
      PERFORM nettoyer_tout.
      TRY.
        COMMIT WORK.
      ENDTRY.
    ENDIF.

  ENDDO.

ENDFORM.                    " select_full
*&---------------------------------------------------------------------*
*&      Form  f_convert_tmstmp
*&---------------------------------------------------------------------*
*       Conversione timestamp in ora locale
*----------------------------------------------------------------------*
FORM f_convert_tmstmp  USING    p_timestamp TYPE comt_created_at_usr
                       CHANGING p_data      TYPE char14.

  DATA: lv_datlo  TYPE  sy-datlo,
        lv_timlo  TYPE  sy-timlo.
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
  CALL FUNCTION 'CRM_LINK_INIT_OW'
    .


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

  " CL - Inizio Modifiche del 01.07.2013
  CLEAR gv_ruolo_ref.
  SELECT SINGLE zzruolointer
    INTO gv_ruolo_ref
    FROM but000
    WHERE partner EQ gv_referente.
  IF sy-subrc IS NOT INITIAL.
    CLEAR gv_ruolo_ref.
  ENDIF.
  " CL - Fine Modifiche del 01.07.2013

ENDFORM.                    " F_SELECT_BUT000


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
