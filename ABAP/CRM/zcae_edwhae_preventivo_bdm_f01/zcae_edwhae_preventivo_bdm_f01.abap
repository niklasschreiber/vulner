*----------------------------------------------------------------------*
***INCLUDE ZCAE_EDWHAE_PREVENTIVO_BDM_F01 .
*----------------------------------------------------------------------*
************************************************************************
* ID:     BDM_02_37_01
* Autore:	Aurora Galeone
* Data:   26.10.2011
* Descr.:	Dichiarazioni Form
************************************************************************

*&---------------------------------------------------------------------*
*&      Form  clear
*&---------------------------------------------------------------------*
* Pulizia variabili globali
*----------------------------------------------------------------------*
FORM clear .

  CLEAR gv_file.

ENDFORM.                    " clear

*&---------------------------------------------------------------------*
*&      Form  open_file
*&---------------------------------------------------------------------*
* Apertura File
*----------------------------------------------------------------------*
FORM open_file .

*VPM - inizio modifica 19122011
* Creazion file
*  CONCATENATE p_fout p_ind INTO gv_file.
  CONCATENATE p_fout '_' sy-datum '.csv' INTO gv_file.
*VPM - fine modifica 19122011

* Chiusura file
  CLOSE DATASET: gv_file.

* Apertura
  OPEN DATASET gv_file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e278(zcar2_evol) WITH gv_file.
  ENDIF.

ENDFORM.                    " open_file

*&---------------------------------------------------------------------*
*&      Form  SCREEN_OUTPUT
*&---------------------------------------------------------------------*
* Gestione Output Screen
*----------------------------------------------------------------------*
FORM screen_output .

  LOOP AT SCREEN .
    CASE screen-name.
      WHEN gc_date.
        IF r_full IS INITIAL.
          screen-input = 1.
        ELSE.
          CLEAR p_date.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " SCREEN_OUTPUT

*&---------------------------------------------------------------------*
*&      Form  check
*&---------------------------------------------------------------------*
* Check Program
*----------------------------------------------------------------------*
FORM check .

* Esci se il programma non è eseguito in background
  IF sy-batch IS INITIAL.
    MESSAGE e398(00) WITH text-e01 space space space.
  ENDIF.

ENDFORM.                    " check

*&---------------------------------------------------------------------*
*&      Form  elaborazione_delta
*&---------------------------------------------------------------------*
* Elaborazione Delta
*----------------------------------------------------------------------*
FORM elaborazione_delta .
* Dichiarazioni locali
  DATA: li_prev TYPE STANDARD TABLE OF tp_prev,
        lv_data TYPE sy-datum.

  IF p_date IS NOT INITIAL.
* Considero la data in input
    lv_data = p_date.
  ELSE.
* Recupero la data dell'ultimo lancio
    PERFORM get_date_time_from CHANGING lv_data.
  ENDIF.

  SELECT DISTINCT id_preventivo
    FROM zca_bdm_prev_dat
    PACKAGE SIZE p_psize
    INTO TABLE li_prev
      WHERE ts_creazione GE lv_data.

* Elaborazione
    PERFORM elaborazione USING li_prev.

  ENDSELECT.

* Se non è stato estratto niente lancio un errore
  CHECK li_prev[] IS INITIAL.
  MESSAGE e398(00) WITH text-e05 space space space.

ENDFORM.                    " elaborazione_delta

*&---------------------------------------------------------------------*
*&      Form  get_date_time_from
*&---------------------------------------------------------------------*
*       Recupera il campo DATE_FROM
*----------------------------------------------------------------------*
FORM get_date_time_from CHANGING p_date TYPE sy-datum.

  DATA: lt_tbtco_f TYPE STANDARD TABLE OF tp_tbtco.

  FIELD-SYMBOLS <fs_tbtco> TYPE tp_tbtco.

  SELECT jobname jobcount sdlstrtdt sdlstrttm
         status FROM tbtco
    INTO TABLE lt_tbtco_f
    WHERE jobname EQ gc_jobname AND
          status  EQ gc_f.

  IF sy-subrc IS NOT INITIAL.
* Chiusura file
    CLOSE DATASET: p_fout.
    MESSAGE e398(00) WITH text-e02 text-e03 text-e04 space.
  ENDIF.

  SORT lt_tbtco_f BY sdlstrtdt DESCENDING
                     sdlstrttm DESCENDING.

  READ TABLE lt_tbtco_f ASSIGNING <fs_tbtco>
     INDEX 1.

  p_date = <fs_tbtco>-sdlstrtdt.


ENDFORM.                    " get_date_time_from

*&---------------------------------------------------------------------*
*&      Form  elaborazione_full
*&---------------------------------------------------------------------*
* Elaborazione Full
*----------------------------------------------------------------------*
FORM elaborazione_full .

* Dichiarazioni locali
  DATA: li_prev TYPE STANDARD TABLE OF tp_prev.

  SELECT DISTINCT id_preventivo
    FROM zca_bdm_prev_dat
    PACKAGE SIZE p_psize
    INTO TABLE li_prev.

* Elaborazione
    PERFORM elaborazione USING li_prev.

  ENDSELECT.

* Se non è stato estratto niente lancio un errore
  CHECK li_prev[] IS INITIAL.
  MESSAGE e398(00) WITH text-e05 space space space.


ENDFORM.                    " elaborazione_full

*&---------------------------------------------------------------------*
*&      Form  elaborazione
*&---------------------------------------------------------------------*
* Elaborazione
*----------------------------------------------------------------------*
FORM elaborazione  USING p_prev TYPE tp_prev_t.

* Dichiarazioni locali
  DATA: li_bdm_bp_dat  TYPE STANDARD TABLE OF zca_bdm_bp_dat,
        ls_file        TYPE tp_file_out,
*        li_dati_prev   TYPE zst_prev_out_t,
        li_bdm_prev_bp TYPE STANDARD TABLE OF tp_zca_bdm_prev_bp,
        lv_trovato     TYPE c,
        lv_prod        TYPE zts_ptb_products-product_id_edwh.

  FIELD-SYMBOLS: <fs_table_in>    TYPE tp_prev,
                 <fs_bdm_bp_dat>  TYPE zca_bdm_bp_dat,
                 <fs_dati_prev>   TYPE zca_bdm_prev_out,
                 <fs_bdm_prev_bp> TYPE tp_zca_bdm_prev_bp.
*start VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo

  CONSTANTS: lc_tipologia_tasso  TYPE zbdm_cod_attrib VALUE 'TIPO_TASSO',
             lc_numero_rate      TYPE zbdm_cod_attrib VALUE 'NUMERO_TOTALE_RATA',
             lc_durata           TYPE zbdm_cod_attrib VALUE 'DURATA',
             lc_periodicita      TYPE zbdm_cod_attrib VALUE 'PERIODICITA_RATA',
             lc_convenzione      TYPE zbdm_cod_attrib VALUE 'CONVENZIONE',
             lc_tipologia_piano  TYPE zbdm_cod_attrib VALUE 'TIPO_PIANO_AMMORTAMENTO',
             lc_polizza_scop_inc TYPE zbdm_cod_attrib VALUE 'POLIZZA_SCOP_INC',
             lc_presenza_cpi     TYPE zbdm_cod_attrib VALUE 'PRESENZA_CPI',
             lc_apertura_cc      TYPE zbdm_cod_attrib VALUE 'APERTURA_CC',
             lc_frazionario      TYPE zbdm_cod_attrib VALUE 'FRAZIONARIO',
             lc_product_id_bic   TYPE zbdm_cod_attrib VALUE 'PRODUCT_ID_BIC'.

  DATA: gi_zca_bdm_pddlb  TYPE STANDARD TABLE OF zca_bdm_pddlb,
        li_dati_prev      TYPE STANDARD TABLE OF zca_bdm_prev_out,
        lw_dati_prev      LIKE LINE OF li_dati_prev,
        lv_data_creazione TYPE zca_bdm_prev_bp-data_creazione.


  FIELD-SYMBOLS: <fs_zca_bdm_pddlb> TYPE zca_bdm_pddlb.
*end VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo

  CHECK p_prev[] IS NOT INITIAL.

* Estrazione ZCA_BDM_BP_DAT
  SELECT *
    FROM zca_bdm_bp_dat
    INTO TABLE li_bdm_bp_dat
    FOR ALL ENTRIES IN p_prev
    WHERE id_preventivo EQ p_prev-id_preventivo.

  SELECT partner id_preventivo
    FROM zca_bdm_prev_bp
    INTO TABLE li_bdm_prev_bp
    FOR ALL ENTRIES IN p_prev
    WHERE id_preventivo EQ p_prev-id_preventivo.

  SORT: li_bdm_bp_dat  BY id_preventivo,
        li_bdm_prev_bp BY id_preventivo partner.

  DELETE ADJACENT DUPLICATES FROM li_bdm_prev_bp.

  LOOP AT p_prev ASSIGNING <fs_table_in>.

    CLEAR ls_file.

    CHECK <fs_table_in>-id_preventivo IS NOT INITIAL.

* Valorizzaione campi costanti
    MOVE <fs_table_in>-id_preventivo TO: ls_file-id_preventivo_crm,
                                         ls_file-id_preventivo_glm.
*    MOVE gc_i TO ls_file-tipo_elaborazione.

* Valorizzazione campi BDM_BP_DAT
    UNASSIGN <fs_bdm_bp_dat>.
    READ TABLE li_bdm_bp_dat ASSIGNING <fs_bdm_bp_dat>
      WITH KEY id_preventivo = <fs_table_in>-id_preventivo
      BINARY SEARCH.

    IF sy-subrc IS INITIAL.

      MOVE: <fs_bdm_bp_dat>-codice_fiscale  TO ls_file-cod_fiscale,
            <fs_bdm_bp_dat>-partita_iva     TO ls_file-cod_partita_iva,
            <fs_bdm_bp_dat>-ragione_sociale TO ls_file-ragione_sociale,
            <fs_bdm_bp_dat>-nome            TO ls_file-nome_referente,
            <fs_bdm_bp_dat>-cognome         TO ls_file-cognome_referente,
            <fs_bdm_bp_dat>-telefono        TO ls_file-telefono_referente,
            <fs_bdm_bp_dat>-cellulare       TO ls_file-cellulare_referente,
            <fs_bdm_bp_dat>-mail            TO ls_file-mail_referente,
            <fs_bdm_bp_dat>-ruolo           TO ls_file-ruolo_referente.

    ENDIF.

* Recupero frazionario
    REFRESH li_dati_prev[].
    CALL FUNCTION 'Z_CA_BDM_LEGGI_PREVENTIVO'
      EXPORTING
        i_applicazione     = gc_appl
        i_preventivo       = <fs_table_in>-id_preventivo
      IMPORTING
        et_dati_preventivo = li_dati_prev.

*start VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo
*old code
*    UNASSIGN <fs_dati_prev>.
*    READ TABLE li_dati_prev ASSIGNING <fs_dati_prev>
*      WITH KEY code = gc_fraz.
*
*    IF sy-subrc IS INITIAL.
*      MOVE <fs_dati_prev>-value TO ls_file-frazionario.
*    ENDIF.
*NEW CODE

    CLEAR: lv_id_contratto.

    SELECT SINGLE id_contratto data_creazione
      INTO (lv_id_contratto,lv_data_creazione)
      FROM zca_bdm_prev_bp
     WHERE id_preventivo = <fs_table_in>-id_preventivo.

    ls_file-data_creazione = lv_data_creazione.

*    SELECT SINGLE guid created_by
*      INTO (lv_guid,lv_uname)
*      FROM crmd_orderadm_h
*     WHERE object_id = lv_id_contratto.
*    lv_utente = lv_uname.
*    CALL FUNCTION 'Z_CA_COD_EMPLOYEE_FROM_USER'
*      EXPORTING
*        utente       = lv_utente
*      IMPORTING
*        cod_cliente  = lv_cod_cli
**        partner_guid = lv_partner_guid
*      TABLES
*        return       = lt_return.
*    lv_cod_bp = lv_cod_cli.
*    CLEAR: lt_return[].
*    CALL FUNCTION 'Z_CA_GET_FRAZIONARIO'
*      EXPORTING
*        i_codice_bp       = lv_cod_bp
*      IMPORTING
*        e_cod_frazionario = lv_cod_fraz
*      TABLES
*        return            = lt_return.
*    ls_file-frazionario = lv_cod_fraz.
*dati preventivo
    SELECT *
    FROM zca_bdm_pddlb
    INTO TABLE gi_zca_bdm_pddlb
    WHERE appl       EQ 'BDM_CONFIGURAZIONE2'.

    SORT gi_zca_bdm_pddlb BY product_id code value.
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_product_id_bic.
    lv_prod = lw_dati_prev-value.

*FRAZIONARIO
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_frazionario.
    IF sy-subrc IS INITIAL.
      ls_file-frazionario = lw_dati_prev-value.
    ENDIF.
* TIPOLOGIA_TASSO
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_tipologia_tasso.
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = lc_tipologia_tasso
               value = lw_dati_prev-value
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ls_file-tipologia_tasso = <fs_zca_bdm_pddlb>-description.
    ENDIF.
* NUMERO_RATE
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_numero_rate.
    ls_file-numero_rate  = lw_dati_prev-value.
* DURATA_FINANZIAMENTO
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_durata.
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = lc_durata
               value = lw_dati_prev-value
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ls_file-durata_finanziamento = <fs_zca_bdm_pddlb>-description.
    ENDIF.
* PERIODICITA
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_periodicita.
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = lc_periodicita
               value = lw_dati_prev-value
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ls_file-periodicita = <fs_zca_bdm_pddlb>-description.
    ENDIF.
* CONVENZIONE
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_convenzione.
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY product_id = lv_prod
               code  = lc_convenzione
               value = lw_dati_prev-value
      BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      ls_file-convenzione = <fs_zca_bdm_pddlb>-description.
    ENDIF.
* TIPOLOGIA PIANO AMMORTAMENTO
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_tipologia_piano.
    UNASSIGN <fs_zca_bdm_pddlb>.
    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
      WITH KEY code  = lc_tipologia_piano
               value = lw_dati_prev-value.
    IF sy-subrc IS INITIAL.
      ls_file-tipologia_piano = <fs_zca_bdm_pddlb>-description.
    ENDIF.
*POLIZZA_SCOP_INC
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_polizza_scop_inc.

    IF lw_dati_prev-value IS INITIAL.
      ls_file-polizza_scop_inc = 'N'.
    ELSE.
      ls_file-polizza_scop_inc = lw_dati_prev-value.
    ENDIF.
*    UNASSIGN <fs_zca_bdm_pddlb>.
*    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
*      WITH KEY code  = lc_polizza_scop_inc
*               value = lw_dati_prev-value.
*    IF sy-subrc IS INITIAL.
*      ls_file-polizza_scop_inc = <fs_zca_bdm_pddlb>-description.
*    ELSE.
*      ls_file-polizza_scop_inc = 'N'.
*    ENDIF.
*PRESENZA_CPI
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_presenza_cpi.
    IF lw_dati_prev-value IS INITIAL.
      ls_file-presenza_cpi = 'N'.
    ELSE.
      ls_file-presenza_cpi = lw_dati_prev-value.
    ENDIF.
*    UNASSIGN <fs_zca_bdm_pddlb>.
*    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
*      WITH KEY code  = lc_presenza_cpi
*               value = lw_dati_prev-value.
*    IF sy-subrc IS INITIAL.
*      ls_file-presenza_cpi = <fs_zca_bdm_pddlb>-description.
*    ELSE.
*      ls_file-presenza_cpi = 'N'.
*    ENDIF.
*APERTURA_CC
    CLEAR lw_dati_prev.
    READ TABLE li_dati_prev INTO lw_dati_prev WITH KEY code = lc_apertura_cc.
    IF lw_dati_prev-value IS INITIAL.
      ls_file-apertura_cc = 'N'.
    ELSE.
      ls_file-apertura_cc = 'S'.
    ENDIF.
*    UNASSIGN <fs_zca_bdm_pddlb>.
*    READ TABLE gi_zca_bdm_pddlb ASSIGNING <fs_zca_bdm_pddlb>
*      WITH KEY code  = lc_apertura_cc
*               value = lw_dati_prev-value.
*    IF sy-subrc IS INITIAL.
*      IF <fs_zca_bdm_pddlb>-description IS INITIAL.
*        ls_file-apertura_cc = 'N'.
*      ELSE.
*        ls_file-apertura_cc = 'S'.
*      ENDIF.
*    ELSE.
*      ls_file-apertura_cc = 'N'.
*    ENDIF.
*end VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo

* INIZIO MODIFICA AS DEL 28.11.2011
    READ TABLE li_dati_prev ASSIGNING <fs_dati_prev>
      WITH KEY code = gc_product_id.
    IF sy-subrc IS INITIAL.
      MOVE <fs_dati_prev>-value TO ls_file-product_id.
    ENDIF.

    READ TABLE li_dati_prev ASSIGNING <fs_dati_prev>
      WITH KEY code = gc_importo.
    IF sy-subrc IS INITIAL.
      MOVE <fs_dati_prev>-value_decimal TO ls_file-importo.
      CONDENSE ls_file-importo NO-GAPS.
    ENDIF.
* FINE MODIFICA AS DEL 28.11.2011

* Recupero ID_CLIENTE_CRM
    CLEAR lv_trovato.
    READ TABLE li_bdm_prev_bp TRANSPORTING NO FIELDS
      WITH KEY id_preventivo = <fs_table_in>-id_preventivo.
    IF sy-subrc IS INITIAL.
      LOOP AT li_bdm_prev_bp ASSIGNING <fs_bdm_prev_bp>
         FROM sy-tabix.
        IF <fs_bdm_prev_bp>-id_preventivo NE <fs_table_in>-id_preventivo.
          EXIT.
        ENDIF.
        IF <fs_bdm_prev_bp>-partner IS INITIAL.
          CONTINUE.
        ENDIF.
        CLEAR ls_file-id_cliente_crm.
        lv_trovato = gc_true.
        MOVE <fs_bdm_prev_bp>-partner TO ls_file-id_cliente_crm.
* Scrivi record nel file
        PERFORM scrivi_file USING ls_file.
      ENDLOOP.
    ENDIF.

    CHECK lv_trovato IS INITIAL.
* Scrivi record nel file
    PERFORM scrivi_file USING ls_file.

  ENDLOOP.

ENDFORM.                    " elaborazione

*&---------------------------------------------------------------------*
*&      Form  scrivi_file
*&---------------------------------------------------------------------*
* Scrivi record nel file
*----------------------------------------------------------------------*
FORM scrivi_file  USING pu_file TYPE tp_file_out.

  DATA lv_line TYPE string.

  FIELD-SYMBOLS: <fs_comp> TYPE ANY.

  CLEAR: sy-subrc, lv_line.

  WHILE sy-subrc = 0.
    ASSIGN COMPONENT sy-index OF STRUCTURE pu_file TO <fs_comp>.
    IF sy-subrc = 0.
      CONCATENATE lv_line <fs_comp> INTO lv_line SEPARATED BY gc_sep.
    ENDIF.
  ENDWHILE.

  SHIFT lv_line BY 1 PLACES LEFT.

  TRANSFER lv_line TO gv_file.

ENDFORM.                    " scrivi_file


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
