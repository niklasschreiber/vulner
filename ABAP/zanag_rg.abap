*&---------------------------------------------------------------------*
*& Report  ZANAG_RG
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zanag_rg.

TABLES : vimi01,viob03,jest,zre_datiedf,sans1,cobrb,csks,setheadert,cskt,
         viob40,jcds.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECTION-SCREEN SKIP.
PARAMETERS: lv_bukrs LIKE vimi01-bukrs OBLIGATORY DEFAULT 'EPI'. "Società
SELECT-OPTIONS:  so_swenr FOR vimi01-swenr,                      "UE
                 so_sgenr FOR vimi01-sgenr,                      "Edificio
                 so_smenr FOR vimi01-smenr.                      " Unità Locazione
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE .
PARAMETER p_as AS CHECKBOX DEFAULT 'X'. SELECTION-SCREEN COMMENT 3(30) text-003 .
SELECTION-SCREEN COMMENT 37(20) text-002 .
PARAMETER: p_path(25).
SELECTION-SCREEN END OF LINE .
SELECTION-SCREEN END OF BLOCK b1.
*
DATA : tb_viob03 LIKE viob03 OCCURS 0 WITH HEADER LINE,
       wa_out TYPE zreal_gim_old,
       tb_out TYPE TABLE OF zreal_gim_old,
       va_validita TYPE zzvalidita, va_cessazione TYPE zzcessazione_edf.

DATA : BEGIN OF tb_unita OCCURS 0,
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
*
DATA : BEGIN OF tb_cobrb OCCURS 0,
        kostl TYPE kostl,
        va_da(6),
        va_a(6),
        aqzif TYPE aqzif,
*************
*        ERSJA type ERSJA,     "Anno di primo utilizzo
*        ERSPE type ERSPE,     "Periodo di primo utilizzo
*        LETJA type LETJA,     "Anno di ultimo utilizzo
*        LETPE type LETPE,     "Periodo di ultimo utilizzo
*************
       END OF tb_cobrb.
*
DATA : BEGIN OF tb_cdc OCCURS 0,
        kostl TYPE kostl,
        data_ini LIKE zreal_gim-data_ini,
        data_end LIKE zreal_gim-data_end,
        aqzif TYPE aqzif,
        aqzif1 TYPE aqzif,
*        khinr LIKE zreal_gim-khinr,
*        zz_stato_cdc LIKE zreal_gim-zz_stato_cdc,
*        ini_cdc LIKE zreal_gim-ini_cdc,
*        end_cdc LIKE zreal_gim-end_cdc,
*        zz_var_stato LIKE zreal_gim-zz_var_stato,
*        zz_frazionario LIKE zreal_gim-zz_frazionario,
*        ltext LIKE zreal_gim-ltext,
*        descript LIKE zreal_gim-descript,
       END OF tb_cdc.
DATA : wa_cdc LIKE tb_cdc,
       va_data(6).                     " periodo discriminante

* Dati per stampa e scarico file

TYPE-POOLS : truxs,slis.
DATA file_name_out TYPE string.
DATA file_name_out_csv TYPE string.
DATA: ld_filename TYPE string,
      ld_path TYPE string,
      ld_fullpath TYPE string,
      ld_result TYPE i.
DATA: final_tab TYPE truxs_t_text_data,
      ls_layout TYPE slis_layout_alv,
      va_nome(12).
*begin mod ac
*intestazione file
DATA: wa_int_out LIKE LINE OF final_tab.
*** end mod ac
CONSTANTS : c_rc4       LIKE sy-subrc   VALUE 4,
            c_rc0       LIKE sy-subrc   VALUE 0.
*
INITIALIZATION.
  CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) '.CSV' INTO p_path.

*** >>> MEV 115301: Security code Review - M.P. <<< ***
at SELECTION-SCREEN on p_path.
  if p_path IS NOT INITIAL.
    if p_path CS '/'.
      MESSAGE 'Nome file non valido.Possibili accessi non autorizzati' TYPE 'E'.
    ELSEIF p_path cs '..'.
      MESSAGE 'Nome file non valido.Possibili accessi non autorizzati' TYPE 'E'.
    ENDIF.
  ENDIF.
*** >>> MEV 115301: Security code Review - M.P. <<< ***
START-OF-SELECTION.
  PERFORM clear.
  PERFORM riempi_tabella.
  IF NOT tb_out[] IS INITIAL.
**   begin mod ac t
    PERFORM intestazione.
**   end mod ac.
    PERFORM converti_in_csv.
    IF p_as = 'X'.
      PERFORM file_su_server.
    ENDIF.
    PERFORM stampa_e_scarica.
  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  riempi_tabella
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM riempi_tabella .

  SELECT *
    FROM viob03
    INTO TABLE tb_viob03
    WHERE bukrs = lv_bukrs
     AND  swenr IN so_swenr
     AND  sgenr IN so_sgenr.

  IF NOT tb_viob03[] IS INITIAL.
    DELETE tb_viob03
     WHERE sgenr+2(1) = 'R' OR
           sgenr+2(1) = 'r'.
  ENDIF.
  LOOP AT tb_viob03.
    CLEAR wa_out.
* Edificio
    wa_out-sgenr = tb_viob03-sgenr.
* Stato Edificio
    SELECT SINGLE *
      FROM jest
      WHERE objnr = tb_viob03-j_objnr
       AND stat = 'I0076'
       AND inact EQ space.
    IF sy-subrc = 0.
      wa_out-stato = 'Non Attivo'.
      SELECT SINGLE *
       FROM jcds
        WHERE objnr = jest-objnr
          AND stat = jest-stat
          AND chgnr = jest-chgnr.
*      wa_out-data = jcds-udate.
      WRITE jcds-udate TO wa_out-data.
    ELSE.
      wa_out-stato = 'Attivo'.
    ENDIF.

*Beg INS 23/06/2014 - RF
    WRITE tb_viob03-derf TO wa_out-attiv_ed.
*End INS 23/06/2014 - RF

    CLEAR : va_validita,va_cessazione.
    SELECT validita cessazione
      INTO (va_validita,va_cessazione)
      FROM zre_datiedf
      WHERE bukrs = 'EPI'
       AND  swenr = tb_viob03-swenr
       AND sgenr = tb_viob03-sgenr
       AND cessazione NE space
       AND validita LE sy-datum
      ORDER BY validita DESCENDING.
      EXIT.
    ENDSELECT.
* Data cessazione
*    wa_out-data_ces = va_validita.
    WRITE va_validita TO wa_out-data_ces.
* Edificio da cessare
    CASE va_cessazione.
      WHEN 'R'.
        wa_out-edi_da = 'Cessato con rilascio imm.'.
      WHEN 'A'.
        wa_out-edi_da = 'Cessato con acquisto imm.'.
      WHEN 'L'.
        wa_out-edi_da = 'Cessazione con acquisizione imm. in loc'.

*inizio MEV 108026 - Modifica transazione FO36 edifici
      WHEN 'E'.
        wa_out-edi_da = 'Da cancellare'.
*fine MEV 108026 - Modifica transazione FO36 edifici
* INIZIO MEV 110099 (severity 4 n.2)
      WHEN OTHERS.
* FINE MEV 110099 (severity 4 n.2)

    ENDCASE.
* Testo fabbricato
    wa_out-ztesto1 = tb_viob03-xgetxt.
* Indirizzo
    IF tb_viob03-adrnr <> space.
      CLEAR sans1.
      CALL FUNCTION 'ADDRESS_ASSIGN'
        EXPORTING
          adr_in              = tb_viob03-adrnr
          function            = 'P'
          objekttyp           = '53'
        IMPORTING
          adrwa_out           = sans1
        EXCEPTIONS
          address_not_found   = 1
          no_address_assigned = 2
          illegal_function    = 3.
      IF sy-subrc = 0.
*        CALL FUNCTION 'FVAX_ADDRESS_TEXT'
*          EXPORTING
*            sans1    = sans1
*            kz_regio = space
*          IMPORTING
*            adr_text = l_adresse.
*      CONCATENATE wa_out-xgetxt l_adresse into wa_out-xgetxt
*      SEPARATED BY space.
        wa_out-localita = sans1-ort01.
        wa_out-city2 = sans1-ort02.
        wa_out-street = sans1-stras.
        wa_out-post_code1 = sans1-pstlz.
        wa_out-region = sans1-regio.
      ENDIF.
    ENDIF.
* Settore contabile Edificio
    wa_out-gsber = tb_viob03-gsber.
* Unità Economica
    wa_out-swenr = tb_viob03-swenr.
*
* Recupero dati Unità di Locazione
    CLEAR tb_unita[].
*    tb_unita-sgenr = tb_viob03-sgenr.
*    SELECT *
*     FROM vimi01
*      WHERE bukrs = tb_viob03-bukrs
*       AND  swenr = tb_viob03-swenr
*       AND  sgenr = tb_viob03-sgenr.
*      tb_unita-gsber = vimi01-gsber.
*      tb_unita-smenr = vimi01-smenr.
*      tb_unita-xmetxt = vimi01-xmetxt.
*      tb_unita-snks = vimi01-snks.
*      tb_unita-intreno = vimi01-intreno.
*      APPEND tb_unita.
*    ENDSELECT.
    SELECT *
      INTO CORRESPONDING FIELDS OF TABLE tb_unita
      FROM vimi01
      WHERE bukrs = tb_viob03-bukrs
       AND  swenr = tb_viob03-swenr
       AND  sgenr = tb_viob03-sgenr
       AND  smenr IN so_smenr.

    IF NOT tb_unita[] IS INITIAL.
* Ciclo sulle Unità di Locazione
      LOOP AT tb_unita.
        CLEAR : wa_out-gsber2,wa_out-smenr,wa_out-xmetxt,
                wa_out-aqzif,wa_out-aqzif1,wa_out-kostl,wa_out-data_ini,
                wa_out-data_end,wa_out-zz_stato_cdc,
                wa_out-ini_cdc,wa_out-end_cdc,wa_out-zz_var_stato,
                wa_out-zz_frazionario,wa_out-ltext,wa_out-descript,
                wa_out-fqmflart1,wa_out-fqmflart2,wa_out-fqmflart4,
                wa_out-fqmflart5,wa_out-fqmflart6,va_data.
* INIZIO INS MEV100020 06.12.2012 DM
        CLEAR: wa_out-xmbez_ul,
               wa_out-stato_ul,
               wa_out-data_ul.
* Stato U.L. e Data Disattivazione
        CLEAR jest.
        SELECT SINGLE *
          FROM jest
          WHERE objnr = tb_unita-snks
           AND stat = 'I0076'
           AND inact EQ space.
        IF sy-subrc = 0.
          wa_out-stato_ul = 'Non Attivo'.
          SELECT SINGLE *
           FROM jcds
            WHERE objnr = jest-objnr
              AND stat = jest-stat
              AND chgnr = jest-chgnr.
*      wa_out-data = jcds-udate.
          WRITE jcds-udate TO wa_out-data_ul.
        ELSE.
          wa_out-stato_ul = 'Attivo'.
        ENDIF.
*   Tipo d#uso della U.L.
        SELECT SINGLE xmbez INTO wa_out-xmbez_ul
               FROM tiv0a
               WHERE spras = 'IT'
                 AND snunr = tb_unita-snunr.
* FINE INS MEV100020 06.12.2012 DM
        wa_out-gsber2 = tb_unita-gsber.
        wa_out-smenr  = tb_unita-smenr.
        wa_out-xmetxt  = tb_unita-xmetxt.
* Inizio eecupero Dati Superfici
* Superfici
        SELECT SINGLE *
          FROM viob40
          WHERE intreno = tb_viob03-intreno
           AND  sflart = '31'.
        IF sy-subrc = 0.
* Superficie scarico costi edificio
          wa_out-fqmflart1 = viob40-fqmflart.
        ENDIF.
*
        SELECT SINGLE *
          FROM viob40
          WHERE intreno = tb_unita-intreno
           AND  sflart = '31'.
        IF sy-subrc = 0.
* Superficie scarico costi U.L.
          wa_out-fqmflart2 = viob40-fqmflart.
        ENDIF.
*
        SELECT SINGLE *
          FROM viob40
          WHERE intreno = tb_viob03-intreno
           AND  sflart = '57'.
        IF sy-subrc = 0.
* Superficie interna
          wa_out-fqmflart4 = viob40-fqmflart.
        ENDIF.
*
        SELECT SINGLE *
          FROM viob40
          WHERE intreno = tb_viob03-intreno
           AND  sflart = '58'.
        IF sy-subrc = 0.
* Superficie esterna
          wa_out-fqmflart5 = viob40-fqmflart.
        ENDIF.
*
        SELECT SINGLE *
          FROM viob40
          WHERE intreno = tb_viob03-intreno
           AND  sflart = '30'.
        IF sy-subrc = 0.
* Superficie Lorda Commerciale
*       wa_out-fqmflart6 = viob40-fqmflart.
        ENDIF.
* Fine dati superfici
*
* Inizio recupero dati Centri di Costo ( CdC )
        REFRESH tb_cobrb.
        SELECT *
          FROM cobrb
          WHERE objnr = tb_unita-snks
            AND konty = 'KS'
            AND kostl NE space.
*            and ersja ne space.
          tb_cobrb-kostl = cobrb-kostl.
          tb_cobrb-aqzif = cobrb-aqzif.
          CONCATENATE cobrb-gabja cobrb-gabpe+1(2) INTO tb_cobrb-va_da.
          CONCATENATE cobrb-gbisj cobrb-gbisp+1(2) INTO tb_cobrb-va_a.
          APPEND tb_cobrb.
          CLEAR tb_cobrb.
        ENDSELECT.
        IF sy-subrc = 0.
          SORT tb_cobrb BY va_a DESCENDING.
*
* determino periodo di riferimento
          LOOP AT tb_cobrb.
            IF sy-datum+0(6) LE tb_cobrb-va_a.
              va_data = tb_cobrb-va_a.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF va_data IS INITIAL.
            READ TABLE tb_cobrb INDEX 1.
            va_data = tb_cobrb-va_a.
          ENDIF.
          REFRESH tb_cdc.
          LOOP AT tb_cobrb
            WHERE va_a = va_data.
            tb_cdc-kostl = tb_cobrb-kostl.
            CONCATENATE '0' tb_cobrb-va_a+4(2) '/' tb_cobrb-va_a+0(4) INTO tb_cdc-data_end.

* BEG INS PTDK933601 TK : Modifica date ZANAG_RG scarico costi - FS
            DATA: vl_diff  TYPE i,
                  vl_date1 TYPE d,
                  vl_date2 TYPE d.
            vl_date1 = sy-datum.

            IF tb_cdc-data_end+1(2) > 12.
              tb_cdc-data_end+1(2) = 12.
            ENDIF.
            CONCATENATE tb_cdc-data_end+4(4) tb_cdc-data_end+1(2) '01' INTO vl_date2.
            vl_diff  = vl_date1 - vl_date2.

            IF vl_diff <= 90.
              tb_cdc-data_end = 'NULL'.
            ENDIF.
            CLEAR : vl_date1, vl_date2, vl_diff.
* END INS PTDK933601 TK : Modifica date ZANAG_RG scarico costi - FS
            tb_cdc-aqzif = tb_cobrb-aqzif.
            tb_cdc-aqzif1 = tb_cobrb-aqzif.
            APPEND tb_cdc.
          ENDLOOP.
* Recupero data inizio validità cdc
          SORT tb_cobrb BY va_da ASCENDING.
          SORT tb_cdc BY kostl.                                 " data_end data_ini.
*          DELETE ADJACENT DUPLICATES FROM tb_cdc COMPARING ALL FIELDS.
          DELETE ADJACENT DUPLICATES FROM tb_cdc COMPARING kostl.
          LOOP AT tb_cdc
            INTO wa_cdc.
            READ TABLE tb_cobrb WITH KEY kostl = wa_cdc-kostl.
            CONCATENATE '0' tb_cobrb-va_da+4(2) '/' tb_cobrb-va_da+0(4) INTO wa_cdc-data_ini.
            MODIFY tb_cdc FROM wa_cdc.
          ENDLOOP.
*
*        LOOP AT tb_cobrb.
*          IF sy-datum+0(6) LE tb_cobrb-va_a.
*            wa_out-kostl = tb_cobrb-kostl.
*            CONCATENATE '0' tb_cobrb-va_da+4(2) '/' tb_cobrb-va_da+0(4) INTO wa_out-data_ini.
*            CONCATENATE '0' tb_cobrb-va_a+4(2) '/' tb_cobrb-va_a+0(4) INTO wa_out-data_end.
*            wa_out-aqzif = tb_cobrb-aqzif.
*            wa_out-AQZIF1 = tb_cobrb-aqzif.
*            EXIT.
*          ENDIF.
*        ENDLOOP.
*        IF wa_out-kostl EQ space.
*          CLEAR tb_cobrb.
*          READ TABLE tb_cobrb INDEX 1.
*          wa_out-kostl = tb_cobrb-kostl.
*          CONCATENATE '0' tb_cobrb-va_da+4(2) '/' tb_cobrb-va_da+0(4) INTO wa_out-data_ini.
*          CONCATENATE '0' tb_cobrb-va_a+4(2) '/' tb_cobrb-va_a+0(4) INTO wa_out-data_end.
*          wa_out-aqzif = tb_cobrb-aqzif.
*          wa_out-aqzif1 = tb_cobrb-aqzif.
*        ENDIF.
          CLEAR wa_cdc.
          LOOP AT tb_cdc
            INTO wa_cdc.
            CLEAR : wa_out-kostl,wa_out-data_ini,wa_out-data_end,wa_out-aqzif,wa_out-aqzif1,
                    wa_out-khinr,wa_out-zz_stato_cdc,wa_out-ini_cdc,wa_out-end_cdc,
                    wa_out-zz_var_stato,wa_out-zz_frazionario,wa_out-ltext,wa_out-descript.
*
            wa_out-kostl = wa_cdc-kostl.
            wa_out-data_ini = wa_cdc-data_ini.
            wa_out-data_end = wa_cdc-data_end.
            wa_out-aqzif = wa_cdc-aqzif.
            wa_out-aqzif1 = wa_cdc-aqzif1.
* Struttura gerarchica
            SELECT SINGLE *
              FROM csks
              WHERE kokrs = 'CEPI'
               AND  kostl = wa_cdc-kostl
               AND datbi = '99991231'.
            IF sy-subrc = 0.
              wa_out-khinr = csks-khinr.
              CASE csks-zz_stato_cdc.
                WHEN '1'.
                  wa_out-zz_stato_cdc = 'Attivo'.
                WHEN '2'.
                  wa_out-zz_stato_cdc = 'Osservato'.
                WHEN '3'.
                  wa_out-zz_stato_cdc = 'Bloccato'.
* INIZIO MEV 110099 (severity 4 n.2)
                WHEN OTHERS.
* FINE MEV 110099 (severity 4 n.2)
              ENDCASE.
*              wa_out-ini_cdc = csks-datab.
              WRITE csks-datab TO wa_out-ini_cdc.
*              wa_out-end_cdc = csks-datbi.
              WRITE csks-datbi TO wa_out-end_cdc.
*              wa_out-zz_var_stato = csks-zz_var_stato.
              WRITE csks-zz_var_stato TO wa_out-zz_var_stato.
              wa_out-zz_frazionario = csks-zz_frazionario.
* Denominazione Struttura Gerarchica e descrizione CdC
              SELECT SINGLE *
               FROM cskt
               WHERE spras = 'I'
                AND  kokrs = 'CEPI'
                AND  kostl = wa_cdc-kostl.
              IF sy-subrc = 0.
                wa_out-ltext = cskt-ltext.
              ENDIF.
*
              SELECT SINGLE *
                FROM setheadert
                WHERE setclass = '0101'
                 AND  subclass = 'CEPI'
                 AND  setname = wa_out-khinr.
              IF sy-subrc = 0.
                wa_out-descript = setheadert-descript.
              ENDIF.
            ENDIF.
            APPEND wa_out TO tb_out.
          ENDLOOP.
* Fine dati relativi ai CdC
        ELSE.                        " non ci sono dati relativi ai CdC
          APPEND wa_out TO tb_out.
        ENDIF.
      ENDLOOP.
    ELSE.
      IF NOT wa_out IS INITIAL.
        APPEND wa_out TO tb_out.
      ENDIF.
    ENDIF.
    CLEAR : wa_out.
  ENDLOOP.

ENDFORM.                    " riempi_tabella

*&---------------------------------------------------------------------*
*&      Form  stampa_e_scarica
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM stampa_e_scarica .


*
* Stampa
  PERFORM layout.
*  perform set_pfstatus.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*         I_INTERFACE_CHECK        = ' '
          i_callback_program       = sy-repid
          i_callback_pf_status_set = 'SET_STATUS'
          i_callback_user_command  = 'USER_COMMAND'
          i_structure_name         = 'ZREAL_GIM_OLD'
          is_layout                = ls_layout
*         it_fieldcat              = fieldcat
*         IT_EXCLUDING             =
*         IT_SPECIAL_GROUPS        =
*         it_sort                  = it_sort
*         IT_FILTER                =
*         IS_SEL_HIDE              =
          i_default                = 'X'
          i_save                   = 'A'
*         is_variant               = is_variant
*         it_events                = event_tab
*         it_event_exit            = event_exit
*         is_print                 = is_print
*         IS_REPREP_ID             =
*         i_screen_start_column    = 3
*         i_screen_start_line      = 3
*         i_screen_end_column      = 50
*         i_screen_end_line        = 20
*    IMPORTING
*         E_EXIT_CAUSED_BY_CALLER  =
*         ES_EXIT_CAUSED_BY_USER   =
     TABLES
          t_outtab                 = tb_out
     EXCEPTIONS
          program_error            = 1
          OTHERS                   = 2.
* INIZIO MEV 110099 (severity 2 n.1)
  IF sy-subrc NE 0.
  ENDIF.
* FINE MEV 110099 (severity 2 n.1)

ENDFORM.                    " stampa_e_scarica

*&---------------------------------------------------------------------*
*&      Form  layout
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM layout .

  ls_layout-zebra = 'X'.
  ls_layout-no_hotspot = 'X'.
  ls_layout-expand_all = 'X'.

ENDFORM.                    " layout
*&---------------------------------------------------------------------*
*&      Form  set_pfstatus
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_status USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'ZSTATO'.

ENDFORM.                    "set_status

*&-----------------------------------------------------------------*
*&      Form  USER_COMMAND
*&-----------------------------------------------------------------*
*       text
*------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                       rs_selfield TYPE slis_selfield .

* in caso di modifiche alla tabella mettere X in rs_selfield-refresh

  CASE r_ucomm.
    WHEN  'SCA'.
      CLEAR file_name_out.
      file_name_out = sy-datum.
      CALL METHOD cl_gui_frontend_services=>file_save_dialog
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
      CONCATENATE ld_fullpath '.csv' INTO file_name_out_csv.
*
      CALL FUNCTION 'GUI_DOWNLOAD'
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
* inizio modifica Ticket 25972463 - Scarico EXCEL 07.11.2014 DF
    WHEN '&FILE'.
      PERFORM scarico_file_excel.
* fine modifica Ticket 25972463 - Scarico EXCEL 07.11.2014 DF
* INIZIO MEV 110099 (severity 2 n.1)
    WHEN OTHERS.
* FINE MEV 110099 (severity 2 n.1)
  ENDCASE.

ENDFORM.                               " USER_COMMAND

*&---------------------------------------------------------------------*
*&      Form  file_su_server
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM file_su_server .

  DATA: fis_file LIKE rlgrap-filename.
  DATA l_line LIKE LINE OF final_tab.

  CLEAR fis_file.
  CALL FUNCTION 'FILE_GET_NAME'
  EXPORTING
*   CLIENT                        = SY-MANDT
   logical_filename              = text-004
   operating_system              = sy-opsys
   parameter_1                   = text-005
   parameter_2                   = text-006
   parameter_3                   = p_path
 IMPORTING
*   EMERGENCY_FLAG                =
*   FILE_FORMAT                   =
   file_name                     = fis_file
 EXCEPTIONS
   file_not_found                = 1
   OTHERS                        = 2.
* INIZIO MEV 110099 (severity 2 n.1)
  IF sy-subrc NE 0.
  ENDIF.
* FINE MEV 110099 (severity 2 n.1)

  IF NOT final_tab[] IS INITIAL.
    OPEN DATASET fis_file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    LOOP AT final_tab INTO l_line.
      TRANSFER l_line TO fis_file.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " file_su_server
*&---------------------------------------------------------------------*
*&      Form  converti_in_csv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM converti_in_csv .
*
*inizio MEV 108026 - Modifica transazione FO36 edifici

  CLEAR wa_out.

  LOOP AT tb_out INTO wa_out WHERE edi_da = 'Da cancellare'.

    DELETE tb_out. " from wa_out.

  ENDLOOP.

*fine MEV 108026 - Modifica transazione FO36 edifici

  CALL FUNCTION 'SAP_CONVERT_TO_TEX_FORMAT'
  EXPORTING
    i_field_seperator    = '|'
      i_line_header        = 'X'
*      I_FILENAME           = I_FILENAME
  TABLES
    i_tab_sap_data       = tb_out
  CHANGING
    i_tab_converted_data = final_tab
  EXCEPTIONS
    conversion_failed    = c_rc4.
*  CHECK SY-SUBRC <> C_RC0.
  IF sy-subrc <> c_rc0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            RAISING conversion_failed.
  ENDIF.

  INSERT wa_int_out INTO final_tab INDEX 1.


ENDFORM.                    " converti_in_csv
*&---------------------------------------------------------------------*
*&      Form  clear
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear .

  CLEAR : final_tab[], tb_out[],tb_viob03[],
          tb_cobrb[],wa_out.

ENDFORM.                    " clear
*&---------------------------------------------------------------------*
*&      Form  intestazione
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM intestazione .

  DATA: BEGIN OF inttab OCCURS 100.
          INCLUDE STRUCTURE dfies.
  DATA: END OF inttab.
  DATA: tablenm TYPE ddobjname.
  MOVE 'ZREAL_GIM_OLD' TO tablenm.
  CLEAR wa_int_out.

  CALL FUNCTION 'DDIF_FIELDINFO_GET'
    EXPORTING
      tabname        = tablenm
      langu          = sy-langu
    TABLES
      dfies_tab      = inttab
    EXCEPTIONS
      not_found      = 1
      internal_error = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF inttab[] IS NOT INITIAL.
    LOOP AT inttab.
      IF sy-tabix = 1.
        MOVE inttab-scrtext_l TO wa_int_out.
      ELSE.
        CONCATENATE wa_int_out inttab-scrtext_l INTO wa_int_out SEPARATED BY '|'.
      ENDIF.
    ENDLOOP.
  ENDIF.


ENDFORM.                    " intestazione
*&---------------------------------------------------------------------*
*&      Form  scarico_file_excel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM scarico_file_excel.

  DATA: ld_filename TYPE string,
          ld_path TYPE string,
          ld_fullpath TYPE string,
          ld_result TYPE i,
          va_file LIKE rlgrap-filename.

  DATA:BEGIN OF tb_file OCCURS 0,
    sgenr(50),
    stato(50),
    attiv_ed(50),
    data(50),
    edi_da(50),
    data_ces(50),
    ztesto1(60),
    localita(50),
    city2(50),
    street(60),
    post_code1(50),
    region(50),
    gsber(50),
    swenr(50),
    gsber2(50),
    smenr(50),
    xmetxt(50),
    xmbez_ul(50),
    stato_ul(50),
    data_ul(50),
    kostl(50),
    khinr(50),
    descript(50),
    ltext(50),
    zz_stato_cdc(50),
    ini_cdc(50),
    end_cdc(50),
    zz_var_stato(50),
    data_ini(50),
    data_end(50),
    zz_frazionario(50),
    aqzif(50),
    aqzif1(50),
    fqmflart1(50),
    fqmflart2(50),
    fqmflart4(50),
    fqmflart5(50),
    fqmflart6(50),
  END OF tb_file.

  CLEAR: tb_file.
  REFRESH tb_file.

* riga testata.
  MOVE: text-t01 TO tb_file-sgenr,
        text-t02 TO tb_file-stato,
        text-t03 TO tb_file-attiv_ed,
        text-t04 TO tb_file-data,
        text-t05 TO tb_file-edi_da,
        text-t06 TO tb_file-data_ces,
        text-t07 TO tb_file-ztesto1,
        text-t08 TO tb_file-localita,
        text-t09 TO tb_file-city2,
        text-t10 TO tb_file-street,
        text-t11 TO tb_file-post_code1,
        text-t12 TO tb_file-region,
        text-t13 TO tb_file-gsber,
        text-t14 TO tb_file-swenr,
        text-t15 TO tb_file-gsber2,
        text-t16 TO tb_file-smenr,
        text-t17 TO tb_file-xmetxt,
        text-t18 TO tb_file-xmbez_ul,
        text-t19 TO tb_file-stato_ul,
        text-t20 TO tb_file-data_ul,
        text-t21 TO tb_file-kostl,
        text-t22 TO tb_file-khinr,
        text-t23 TO tb_file-descript,
        text-t24 TO tb_file-ltext,
        text-t25 TO tb_file-zz_stato_cdc,
        text-t26 TO tb_file-ini_cdc,
        text-t27 TO tb_file-end_cdc,
        text-t28 TO tb_file-zz_var_stato,
        text-t29 TO tb_file-data_ini,
        text-t30 TO tb_file-data_end,
        text-t31 TO tb_file-zz_frazionario,
        text-t32 TO tb_file-aqzif,
        text-t33 TO tb_file-aqzif1,
        text-t34 TO tb_file-fqmflart1,
        text-t35 TO tb_file-fqmflart2,
        text-t36 TO tb_file-fqmflart4,
        text-t37 TO tb_file-fqmflart5,
        text-t38 TO tb_file-fqmflart6.

  APPEND tb_file.

* riga output.
  LOOP AT tb_out INTO wa_out.
    MOVE-CORRESPONDING wa_out TO tb_file.
    IF tb_file-attiv_ed IS NOT INITIAL.
      IF tb_file-attiv_ed NE '00000000'.
        PERFORM format_date_excel USING wa_out-attiv_ed
                                  CHANGING tb_file-attiv_ed.
      ELSE.
        CLEAR tb_file-attiv_ed.
      ENDIF.
    ENDIF.
    IF tb_file-data IS NOT INITIAL.
      IF tb_file-data NE '00000000'.
        PERFORM format_date_excel USING wa_out-data
                                  CHANGING tb_file-data.
      ELSE.
        CLEAR tb_file-data.
      ENDIF.
    ENDIF.
    IF tb_file-edi_da IS NOT INITIAL.
      IF tb_file-edi_da NE '00000000'.
        PERFORM format_date_excel USING wa_out-edi_da
                                  CHANGING tb_file-edi_da.
      ELSE.
        CLEAR tb_file-edi_da.
      ENDIF.
    ENDIF.
    IF tb_file-data_ces IS NOT INITIAL.
      IF tb_file-data_ces NE '00000000'.
        PERFORM format_date_excel USING wa_out-data_ces
                                  CHANGING tb_file-data_ces.
      ELSE.
        CLEAR tb_file-data_ces.
      ENDIF.
    ENDIF.
    IF tb_file-data_ul IS NOT INITIAL.
      IF tb_file-data_ul NE '00000000'.
        PERFORM format_date_excel USING wa_out-data_ul
                                  CHANGING tb_file-data_ul.
      ELSE.
        CLEAR tb_file-data_ul.
      ENDIF.
    ENDIF.
    IF tb_file-ini_cdc IS NOT INITIAL.
      IF tb_file-ini_cdc NE '00000000'.
        PERFORM format_date_excel USING wa_out-ini_cdc
                                  CHANGING tb_file-ini_cdc.
      ELSE.
        CLEAR tb_file-ini_cdc.
      ENDIF.
    ENDIF.
    IF tb_file-end_cdc IS NOT INITIAL.
      IF tb_file-end_cdc NE '00000000'.
        PERFORM format_date_excel USING wa_out-ini_cdc
                                  CHANGING tb_file-ini_cdc.
      ELSE.
        CLEAR tb_file-end_cdc.
      ENDIF.
    ENDIF.
    APPEND tb_file.
    CLEAR wa_out.
  ENDLOOP.

* Finestra Windows per percorso dove scaricare il file
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_file_name = '.xlsx'
      initial_directory = 'c:\'
    CHANGING
      filename          = ld_filename
      path              = ld_path
      fullpath          = ld_fullpath
      user_action       = ld_result.

  IF ld_result = 0.

    MOVE ld_fullpath TO va_file.

* conversione in file EXCEL
    CALL FUNCTION 'SAP_CONVERT_TO_XLS_FORMAT'
      EXPORTING
        i_filename        = va_file
      TABLES
        i_tab_sap_data    = tb_file
      EXCEPTIONS
        conversion_failed = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      MESSAGE i000(db) WITH 'Errore scacrico file'.
    ELSE.
      MESSAGE i000(db) WITH 'File scaricato con successo'.
    ENDIF.
  ENDIF.

ENDFORM.                    "scarico_file_excel
*&---------------------------------------------------------------------*
*&      Form  format_date_excel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->DATE_IN    text
*      -->DATE_OUT   text
*----------------------------------------------------------------------*
FORM format_date_excel USING date_in
                       CHANGING date_out.

  CLEAR date_out.
  CONCATENATE date_in+0(2)
              date_in+2(2)
              date_in+4(4)
  INTO date_out SEPARATED BY '/'.

ENDFORM.                    "format_date_excel


*Messages
*----------------------------------------------------------
*
* Message class: DB
*000   & & & &
*
* Message class: Hard coded
*   Nome file non valido.Possibili accessi non autorizzati

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2018. Sap Release 700
