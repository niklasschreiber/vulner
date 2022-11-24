FUNCTION z_ca_bdm_leggi_preventivo.
*"----------------------------------------------------------------------
*"*"Interfaccia locale:
*"  IMPORTING
*"     VALUE(I_APPLICAZIONE) TYPE  ZAPPL
*"     VALUE(I_PREVENTIVO) TYPE  ZBDM_PREV_ID
*"     VALUE(I_GARANZIA) TYPE  CRMT_BOOLEAN OPTIONAL
*"     VALUE(I_CLEAR_HIDE) TYPE  CRMT_BOOLEAN OPTIONAL
*"     VALUE(I_CPI) TYPE  CRMT_BOOLEAN OPTIONAL
*"  EXPORTING
*"     VALUE(ET_DATI_PREVENTIVO) TYPE  ZST_PREV_OUT_T
*"     VALUE(ET_DATI_ANAGRAFICI) TYPE  ZBDM_BP_DAT_T
*"  TABLES
*"      TB_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

  CONSTANTS: lcg_frac     TYPE zgroup       VALUE 'FRAC'. "AM 06-07-2012 per parametrizzazione fascia rischio

  DATA: lt_conf          TYPE STANDARD TABLE OF zca_param_ext,
        lw_conf          LIKE LINE OF lt_conf,
        lt_ipot          TYPE STANDARD TABLE OF zca_param_ext,
        lw_ipot          LIKE LINE OF lt_ipot,
        lt_chir          TYPE STANDARD TABLE OF zca_param_ext,
        lw_chir          LIKE LINE OF lt_chir,
        lt_prev_def_ipot TYPE zca_bdm_prev_def OCCURS 0,
        lw_prev_def_ipot LIKE LINE OF lt_prev_def_ipot,
        lt_prev_def_conf TYPE zca_bdm_prev_def OCCURS 0,
        lw_prev_def_conf LIKE LINE OF lt_prev_def_conf,
        lt_prev_def_chir TYPE zca_bdm_prev_def OCCURS 0,
        lw_prev_def_chir LIKE LINE OF lt_prev_def_chir,
        lt_param         TYPE zca_param OCCURS 0,"AM 06-07-2012 per parametrizzazione fascia rischio
        lt_return        TYPE STANDARD TABLE OF bapiret2.

  DATA: lt_prev_def        TYPE zca_bdm_prev_def OCCURS 0,
        lw_prev_def        LIKE LINE OF lt_prev_def,
        lw_range_fascia    LIKE LINE OF lt_param,"AM 06-07-2012 per parametrizzazione fascia rischio
        lw_dati_preventivo TYPE zca_bdm_prev_out.

  RANGES: r_gar FOR zca_bdm_prev_out-garanzia,
          r_fascia FOR zca_param-z_val_par, "AM 06-07-2012 per parametrizzazione fascia rischio
          r_cpi FOR zca_bdm_prev_out-presenza_cpi_out.

  REFRESH: r_gar[],r_cpi[].

*start VPM 04.05.2012 - fase2
*OLD
*  IF i_garanzia = 'N'.
*
*    r_gar-sign = 'I'.
*    r_gar-option = 'NE'.
*    r_gar-low = 'S'.
*    APPEND r_gar.
*
*  ELSEIF i_garanzia = 'S'.
*
*    r_gar-sign = 'I'.
*    r_gar-option = 'NE'.
*    r_gar-low = 'N'.
*    APPEND r_gar.
*
*  ENDIF.
*NEW

*AM START 06-07-2012 per parametrizzazione fascia rischio

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = lcg_frac
      i_z_appl = i_applicazione
    TABLES
      param    = lt_param
      return   = lt_return.

  CHECK lt_return[] IS INITIAL.

  LOOP AT lt_param INTO lw_range_fascia.
    r_fascia-sign = 'I'.
    r_fascia-option = 'EQ'.
    r_fascia-low = lw_range_fascia-z_val_par.
    APPEND r_fascia.
  ENDLOOP.

*AM END 06-07-2012 per parametrizzazione fascia rischio


  IF i_cpi = 'N'.

    r_cpi-sign = 'I'.
    r_cpi-option = 'NE'.
    r_cpi-low = 'S'.
    APPEND r_cpi.

  ELSEIF i_cpi = 'S'.

    r_cpi-sign = 'I'.
    r_cpi-option = 'NE'.
    r_cpi-low = 'N'.
    APPEND r_cpi.

  ENDIF.
*end VPM 04.05.2012 - fase2

  SELECT * FROM zca_bdm_bp_dat
           INTO TABLE et_dati_anagrafici
          WHERE id_preventivo = i_preventivo.

*start VPM 04.05.2012 - fase2
*OLD
*  SELECT * FROM zca_bdm_prev_out
*           INTO TABLE et_dati_preventivo
*          WHERE appl = i_applicazione
*            AND id_preventivo = i_preventivo
*            AND garanzia IN r_gar.
*NEW
  SELECT * FROM zca_bdm_prev_out
           INTO TABLE et_dati_preventivo
          WHERE appl = i_applicazione
            AND id_preventivo = i_preventivo
            AND presenza_cpi_out IN r_cpi.
*end VPM 04.05.2012 - fase2



*Gestione campo fascia di rischio
*AM START 06-07-2012 per parametrizzazione fascia rischio

  LOOP AT  et_dati_preventivo INTO lw_dati_preventivo
                            WHERE code IN r_fascia.

*  LOOP AT et_dati_preventivo INTO lw_dati_preventivo
*                            WHERE code = 'TAN'
*                               OR code = 'TAEG'
*                               OR code = 'SPREAD'
*                               OR code = 'IMPORTO_PRIMA_RATA'
*                               OR code = 'IMPORTO_PRIMA_RATA_PREAMM' "AM 4.6.2012
*                               OR code = 'IMPORTO_PRIMA_RATA'       "vpm22.06.2012
*                               OR code = 'SPESE_PERIZIA'.          "vpm22.06.2012

*AM END 06-07-2012 per parametrizzazione fascia rischio

    IF lw_dati_preventivo-fascia_rischio = '1'.
      CONCATENATE lw_dati_preventivo-code '_A' INTO lw_dati_preventivo-code.
    ELSEIF lw_dati_preventivo-fascia_rischio = '2'.
      CONCATENATE lw_dati_preventivo-code '_B' INTO lw_dati_preventivo-code.
    ELSEIF lw_dati_preventivo-fascia_rischio = '3'.
      CONCATENATE lw_dati_preventivo-code '_C' INTO lw_dati_preventivo-code.
    ENDIF.

    SELECT SINGLE * FROM zca_bdm_prev_def
                    INTO CORRESPONDING FIELDS OF lw_dati_preventivo
                   WHERE appl = i_applicazione
                     AND code = lw_dati_preventivo-code .

    MODIFY et_dati_preventivo FROM lw_dati_preventivo.
    CLEAR lw_dati_preventivo.

  ENDLOOP.
*start VPM 04.05.2012 - fase2
*OLD CODE
*  SORT et_dati_preventivo BY code garanzia.
*  DELETE ADJACENT DUPLICATES FROM et_dati_preventivo COMPARING code garanzia.
*NEW CODE
  SORT et_dati_preventivo BY code presenza_cpi_out.
  DELETE ADJACENT DUPLICATES FROM et_dati_preventivo COMPARING code presenza_cpi_out.
*end VPM 04.05.2012 - fase2


*start VPM 12.06.2012 - fase2

*OLD code
*  IF NOT i_clear_hide IS INITIAL.
*    SELECT * FROM zca_bdm_prev_def
*             INTO TABLE lt_prev_def
*            WHERE appl = i_applicazione
*              AND flag_1 EQ 'H'. " H (Hide) campi da non far visualizzare
*
*    LOOP AT et_dati_preventivo INTO lw_dati_preventivo.
*      READ TABLE lt_prev_def INTO lw_prev_def WITH KEY code = lw_dati_preventivo-code.
*      IF sy-subrc = 0.
*        DELETE et_dati_preventivo WHERE code = lw_dati_preventivo-code.
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
*NEW CODE
  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM_EXT'
    EXPORTING
      i_gruppo = 'CONF'
      i_z_appl = i_applicazione
    TABLES
      param    = lt_conf
      return   = lt_return.
  IF lt_return[] IS NOT INITIAL.
    tb_return[] = lt_return[].
    EXIT.
  ENDIF.


  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM_EXT'
    EXPORTING
      i_gruppo = 'IPOT'
      i_z_appl = i_applicazione
    TABLES
      param    = lt_ipot
      return   = lt_return.
  IF lt_return[] IS NOT INITIAL.
    tb_return[] = lt_return[].
    EXIT.
  ENDIF.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM_EXT'
    EXPORTING
      i_gruppo = 'CHIR'
      i_z_appl = i_applicazione
    TABLES
      param    = lt_chir
      return   = lt_return.
  IF lt_return[] IS NOT INITIAL.
    tb_return[] = lt_return[].
    EXIT.
  ENDIF.

  IF NOT i_clear_hide IS INITIAL.

*CAMPI VISUALIZZAZIONE IPOTECARIO
    LOOP AT et_dati_preventivo INTO lw_dati_preventivo WHERE code = 'PRODUCT_ID'.
      READ TABLE lt_ipot INTO lw_ipot WITH KEY z_val_par = lw_dati_preventivo-value.
      IF sy-subrc = 0.

        SELECT * FROM zca_bdm_prev_def
                 INTO TABLE lt_prev_def_ipot
                WHERE appl = i_applicazione
                  AND flag_3 EQ 'H'. " H (Hide) campi da non far visualizzare

        LOOP AT et_dati_preventivo INTO lw_dati_preventivo.
          READ TABLE lt_prev_def_ipot INTO lw_prev_def WITH KEY code = lw_dati_preventivo-code.
          IF sy-subrc = 0.
            DELETE et_dati_preventivo WHERE code = lw_dati_preventivo-code.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ENDLOOP.

*CAMPI VISUALIZZAZIONE CONFIDI
    LOOP AT et_dati_preventivo INTO lw_dati_preventivo WHERE code = 'PRODUCT_ID'.
      READ TABLE lt_conf INTO lw_conf WITH KEY z_val_par = lw_dati_preventivo-value.
      IF sy-subrc = 0.

        SELECT * FROM zca_bdm_prev_def
                 INTO TABLE lt_prev_def_conf
                WHERE appl = i_applicazione
                  AND flag_2 EQ 'H'. " H (Hide) campi da non far visualizzare

        LOOP AT et_dati_preventivo INTO lw_dati_preventivo.
          READ TABLE lt_prev_def_conf INTO lw_prev_def WITH KEY code = lw_dati_preventivo-code.
          IF sy-subrc = 0.
            DELETE et_dati_preventivo WHERE code = lw_dati_preventivo-code.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ENDLOOP.

*CAMPI VISUALIZZAZIONE CHIROGRAFARIO
    LOOP AT et_dati_preventivo INTO lw_dati_preventivo WHERE code = 'PRODUCT_ID'.
      READ TABLE lt_chir INTO lw_chir WITH KEY z_val_par = lw_dati_preventivo-value.
      IF sy-subrc = 0.

        SELECT * FROM zca_bdm_prev_def
                 INTO TABLE lt_prev_def_chir
                WHERE appl = i_applicazione
                  AND flag_1 EQ 'H'. " H (Hide) campi da non far visualizzare

        LOOP AT et_dati_preventivo INTO lw_dati_preventivo.
          READ TABLE lt_prev_def_chir INTO lw_prev_def WITH KEY code = lw_dati_preventivo-code.
          IF sy-subrc = 0.
            DELETE et_dati_preventivo WHERE code = lw_dati_preventivo-code.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ENDLOOP.

  ENDIF.

*end VPM 12.06.2012 - fase2

  IF i_applicazione = 'RICERCA_PREVENTIVI'.
*start VPM 04.05.2012 - fase2
*OLD
*    DELETE et_dati_preventivo WHERE garanzia <> i_garanzia.
*NEW
    DELETE et_dati_preventivo WHERE presenza_cpi_out <> i_cpi.
*end VPM 04.05.2012 - fase2
  ENDIF.

  SORT et_dati_preventivo BY ordine  .

  IF et_dati_preventivo[] IS INITIAL.

    text_mess = 'Nessun preventivo soddisfa i criteri di ricerca'.

    PERFORM return TABLES tb_return
                    USING text_mess
                          'ZCAR2_EVOL' 'E' '000'.

  ENDIF.




ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
