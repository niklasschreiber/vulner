*----------------------------------------------------------------------*
***INCLUDE ZCAE_EDWHAE_BASE_F01 .
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  f_inizializza
*&---------------------------------------------------------------------*
* Pulizia variabili globali
*----------------------------------------------------------------------*
FORM f_inizializza .

* Tabelle
  REFRESH: gr_prat[],
           gr_date[].

* Variabili
  CLEAR: gv_fileout,
         gv_fileerr.

ENDFORM.                    " f_inizializza

*&---------------------------------------------------------------------*
*&      Form  f_edit_input
*&---------------------------------------------------------------------*
* Editabilità paramtri in input
*----------------------------------------------------------------------*
FORM f_edit_input.

  LOOP AT SCREEN.
    CASE screen-name.
      WHEN gc_p_data.
        IF r_delta IS INITIAL.
          CLEAR p_data.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " f_edit_input

*&---------------------------------------------------------------------*
*&      Form  f_check_program
*&---------------------------------------------------------------------*
* Controllo JOB
*----------------------------------------------------------------------*
FORM f_check_program .

  CHECK sy-batch IS INITIAL.
  MESSAGE e398(00) WITH text-e01 space space space.



ENDFORM.                    " f_check_program

*&---------------------------------------------------------------------*
*&      Form  f_read_param
*&---------------------------------------------------------------------*
* Read Param
*----------------------------------------------------------------------*
FORM f_read_param.

* Dichiarazioni locali
  DATA: lt_par  TYPE zca_param_t,
        lt_ret  TYPE bapiret2_t,
        ls_prat LIKE LINE OF gr_prat.

  FIELD-SYMBOLS <fs_par> TYPE zca_param.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = gc_prat
      i_z_appl = gc_appl
    TABLES
      param    = lt_par
      return   = lt_ret.

  IF lt_ret[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 space space space.

  ELSE.

    ls_prat-sign   = gc_i.
    ls_prat-option = gc_eq.
    LOOP AT lt_par ASSIGNING <fs_par>.
      ls_prat-low = <fs_par>-z_val_par.
      APPEND ls_prat TO gr_prat.
    ENDLOOP.


  ENDIF.

ENDFORM.                    " f_read_param

*&---------------------------------------------------------------------*
*&      Form  f_date
*&---------------------------------------------------------------------*
* Modalità f_date
*----------------------------------------------------------------------*
FORM f_date .

* Dichiarazioni locali
  DATA: ls_range LIKE LINE OF gr_date,
        li_tbtco TYPE STANDARD TABLE OF tp_tbtco.

  FIELD-SYMBOLS <fs_tbtco> TYPE tp_tbtco.

* In modalità FULL non si calcolano date
  CHECK r_full IS INITIAL.

  ls_range-sign = gc_i.

* Se è valorizzata la data in input si considera quella...
  IF p_data IS NOT INITIAL.
    ls_range-option = gc_ge.
    ls_range-low = p_data.
    APPEND ls_range TO gr_date.
    EXIT.
  ENDIF.

* ...altrimenti si recupera l'ultima variante di lancio
* Accedere alla tabella TBTCO con:
* JOBNAME  = ZCAE_EDWHAE_BASE
* STATUS = F
* salvare il valore del campo SDLSTRTDT più recente tra tutti i
* record ritornati.
  ls_range-option = gc_gt.
  SELECT sdlstrtdt
    FROM tbtco
    INTO TABLE li_tbtco
    WHERE jobname EQ gc_jobname
      AND status  EQ gc_status.

  CHECK sy-subrc IS INITIAL.
  SORT li_tbtco[] DESCENDING.
  READ TABLE li_tbtco ASSIGNING <fs_tbtco>
    INDEX 1.
  CHECK sy-subrc IS INITIAL.
  ls_range-low = <fs_tbtco>-sdlstrtdt.
  APPEND ls_range TO gr_date.

ENDFORM.                    " f_date


*&---------------------------------------------------------------------*
*&      Form  f_elabora
*&---------------------------------------------------------------------*
* Elaborazione
*----------------------------------------------------------------------*
FORM f_elabora .

* Dichiarazioni locali
  DATA: lt_cbase TYPE tp_zca_reddito_cbas.

  SELECT *
    PACKAGE SIZE p_pack
    FROM zca_reddito_cbas
    INTO TABLE lt_cbase
    WHERE partner IN s_bp
      AND chdat   IN gr_date.

    PERFORM f_elabora_record USING lt_cbase.

  ENDSELECT.

  CHECK sy-subrc IS NOT INITIAL.
  MESSAGE s398(00) WITH text-e04 space space space.


ENDFORM.                    " f_elabora

*&---------------------------------------------------------------------*
*&      Form  f_elabora_record
*&---------------------------------------------------------------------*
* Elaborazione dati
*----------------------------------------------------------------------*
FORM f_elabora_record  USING pt_cbase TYPE tp_zca_reddito_cbas.


* Dichiarazione locale
  FIELD-SYMBOLS: <fs_cbase> TYPE zca_reddito_cbas,
                 <fs_order> TYPE tp_order_h.

  DATA: li_order TYPE STANDARD TABLE OF tp_order_h,
        li_cust  TYPE STANDARD TABLE OF tp_cust_h,
        ls_cust  TYPE tp_cust_h.

  DATA  li_app TYPE tp_zca_reddito_cbas.


* Estrazione da ORDERADM_H
  li_app[] = pt_cbase[].
  SORT li_app[] BY object_id.
  DELETE ADJACENT DUPLICATES FROM li_app[] COMPARING object_id.
  SELECT guid object_id process_type
    FROM crmd_orderadm_h
    INTO TABLE li_order
    FOR ALL ENTRIES IN li_app
    WHERE object_id    EQ li_app-object_id
      AND process_type IN gr_prat.

  IF sy-subrc IS INITIAL.
    SELECT guid zz_numero_cc zz_opzione
      FROM crmd_customer_h
      INTO TABLE li_cust
      FOR ALL ENTRIES IN li_order
      WHERE guid    EQ li_order-guid.
  ENDIF.

  SORT li_order[] BY object_id.

* Per ogni record presente...
  LOOP AT pt_cbase ASSIGNING <fs_cbase>.

* ... controllare la consistenza dei campi:
* Codice Fiscale (BU_SORT1)
* Utente CRM (CHUSR)
* Data creazione Pratica (CHDAT)
* Se almeno 1 dei 3 valori risulta blank, il record va scartato
    IF <fs_cbase>-bu_sort1 IS INITIAL OR <fs_cbase>-chusr IS INITIAL OR <fs_cbase>-chdat IS INITIAL.

      PERFORM f_file_error USING <fs_cbase>
                                 text-e05.
      CONTINUE.
    ENDIF.

* ... accedere alla tabella CRMD_ORDERADM_H
* Se l'accesso fallisce  il record va scartato
    UNASSIGN <fs_order>.
    READ TABLE li_order ASSIGNING <fs_order>
      WITH KEY object_id = <fs_cbase>-object_id
      BINARY SEARCH.

    IF sy-subrc IS NOT INITIAL.
      PERFORM f_file_error USING <fs_cbase>
                                 text-e06.
      CONTINUE.

    ENDIF.

* ... effettuare l'accesso in tabella CRMD_CUSTOMER_H per
* leggere il valore del campo ZZ_NUMERO_CC
    CLEAR ls_cust.
    READ TABLE li_cust INTO ls_cust
      WITH KEY guid = <fs_order>-guid.

* scrittura file output
    PERFORM f_file_out  USING <fs_cbase>
                              <fs_order>
                              ls_cust.


  ENDLOOP.


ENDFORM.                    " f_elabora_record

*&---------------------------------------------------------------------*
*&      Form  f_file_error
*&---------------------------------------------------------------------*
* Scrittura file errore
*----------------------------------------------------------------------*
FORM f_file_error  USING pu_in    TYPE zca_reddito_cbas
                         pu_text  TYPE string.


* Dichiarazioni locali
  DATA: lv_string TYPE string.

* Apertura File
  IF gv_fileerr IS INITIAL. " file ancora non aperto
    CONCATENATE p_f_err sy-datum p_var INTO gv_fileerr SEPARATED BY gc_sep1.
    CLOSE DATASET gv_fileerr.
    OPEN DATASET gv_fileerr FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e398(00) WITH text-e03 p_f_err space space.
    ENDIF.
  ENDIF.

* Scrittura File
  CONCATENATE pu_in-object_id
              pu_in-partner
              pu_text
         INTO lv_string
 SEPARATED BY gc_sep2.
  TRANSFER lv_string TO gv_fileerr.


ENDFORM.                    " f_file_error

*&---------------------------------------------------------------------*
*&      Form  f_file_out
*&---------------------------------------------------------------------*
* Scrittura f_file output
*----------------------------------------------------------------------*
FORM f_file_out  USING pu_cbase    TYPE zca_reddito_cbas
                       pu_order    TYPE tp_order_h
                       pu_customer TYPE tp_cust_h.


* Dichiarazioni locali
  DATA: lv_string TYPE string,
        lv_isee   TYPE string,
        lv_pens   TYPE string,
        lv_cf     TYPE char16.

* Apertura File
  IF gv_fileout IS INITIAL. " file ancora non aperto
    IF p_var IS NOT INITIAL.
      CONCATENATE p_f_out sy-datum p_var INTO gv_fileout SEPARATED BY gc_sep1.
    ELSE.
      CONCATENATE p_f_out sy-datum INTO gv_fileout SEPARATED BY gc_sep1.
    ENDIF.


    CLOSE DATASET gv_fileout.
    OPEN DATASET gv_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e398(00) WITH text-e03 p_f_out space space.
    ENDIF.
  ENDIF.

* Scrittura File
  lv_isee = pu_cbase-isee.
  lv_pens = pu_cbase-pensione.
  CONDENSE: lv_isee NO-GAPS, lv_pens NO-GAPS.
  lv_cf = pu_cbase-bu_sort1.

  CONCATENATE pu_cbase-partner
              pu_cbase-object_id
              pu_order-process_type
              pu_customer-zz_numero_cc
              pu_customer-zz_opzione
              lv_cf
              lv_isee
              pu_cbase-data_cons
              pu_cbase-anno_rif
              lv_pens
              pu_cbase-data_cons
              pu_cbase-anno_rif
              pu_cbase-chusr
              pu_cbase-chdat
         INTO lv_string
 SEPARATED BY gc_sep2
 RESPECTING BLANKS.

  TRANSFER lv_string TO gv_fileout.

ENDFORM.                    " f_file_out

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
