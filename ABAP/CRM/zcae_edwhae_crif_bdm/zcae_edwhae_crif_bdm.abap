*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_CRIF_BDM
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_crif_bdm.

CONSTANTS: ca_jobname      TYPE tbtco-jobname     VALUE 'ZCAE_EDWHAE_CRIF_BDM',
           ca_f            TYPE tbtco-status      VALUE 'F',
           ca_gruppo       TYPE zca_param-z_group VALUE 'CRIF',
           ca_appl         TYPE zca_param-z_appl  VALUE 'ZCAE_EDWHAE_CRIF_BDM',
           ca_e            TYPE c                 VALUE 'E',
           ca_a            TYPE c                 VALUE 'A',
           ca_m            TYPE c                 VALUE 'M',
           ca_i            TYPE c                 VALUE 'I'.

TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES: BEGIN OF t_file,
        campo(2086) TYPE c,
       END OF t_file.

TYPES: BEGIN OF t_but000,
       partner   TYPE but000-partner,
       bu_sort1  TYPE but000-bu_sort1,
       bu_sort2  TYPE but000-bu_sort2,
     END OF t_but000.

TYPES: BEGIN OF t_data,
        tipo_elaborazione(1)            TYPE c,
        id_cliente_bic(10)              TYPE c,
        id_cliente_crm(10)              TYPE c,
        cod_fiscale(20)                 TYPE c,
        cod_partita_iva(20)             TYPE c,
        sae_crif(60)                    TYPE c,
        rae_crif(60)                    TYPE c,
        desc_sae_crif(60)               TYPE c,
        desc_rae_crif(60)               TYPE c,
        codice_ateco_crif(10)           TYPE c,
        stato_azienda(255)              TYPE c,
        dati_fondo_garanzia(255)        TYPE c, "eleggibilità
        procedure_conc(255)             TYPE c,
        dati_scoring_crif(255)          TYPE c,
        protesti(255)                   TYPE c,
        pregiudizievoli_gravi(255)      TYPE c,
*        pre_scoring(255)                TYPE c,
       END OF t_data.

TYPES: BEGIN OF t_crif,
         bp_cliente       TYPE zca_bdm_crif_1-bp_cliente,
         guid_contratto   TYPE zca_bdm_crif_1-guid_contratto,
         codice_crif      TYPE zca_bdm_crif_1-codice_crif,
         data_creazione   TYPE zca_bdm_crif_1-data_creazione,
         sae              TYPE zca_bdm_crif_1-sae,
         rae              TYPE zca_bdm_crif_1-rae,
         desc_sae         TYPE zca_bdm_crif_1-desc_sae,
         desc_rae         TYPE zca_bdm_crif_1-desc_rae,
         cod_ateco        TYPE zca_bdm_crif_1-cod_ateco,
         stato_azienda    TYPE zca_bdm_crif_1-stato_azienda,
         eleggibilita_gar TYPE zca_bdm_crif_1-eleggibilita_gar,
         procedure_concor TYPE zca_bdm_crif_1-procedure_concor,
         applicabilita_sc TYPE zca_bdm_crif_1-applicabilita_sc,
         presenza_protest TYPE zca_bdm_crif_1-presenza_protest,
         presenza_pregiud TYPE zca_bdm_crif_1-presenza_pregiud,
*         codice_esito_sco TYPE zca_bdm_crif_1-codice_esito_sco,
       END OF t_crif.

DATA: lt_bdm_crif TYPE t_crif OCCURS 0, "lt_bdm_crif TYPE STANDARD TABLE OF zca_bdm_crif_1,
      lw_bdm_crif LIKE LINE OF lt_bdm_crif,
      lt_contract TYPE zca_bdm_contract OCCURS 0,
      lw_contract LIKE LINE OF lt_contract,
      lt_but000   TYPE t_but000 OCCURS 0,
      lw_but000   LIKE LINE OF lt_but000,
      lt_param    TYPE zca_param OCCURS 0,
      lt_return   TYPE bapiret2 OCCURS 0.

DATA: lv_datum    TYPE sy-datum,
      lv_date_f1  TYPE zca_bdm_crif-data_creazione,
      gw_tbtco_f  TYPE t_tbtco,
      lt_file     TYPE t_file OCCURS 0,
      lw_file     LIKE LINE OF lt_file,
      lt_data     TYPE t_data OCCURS 0,
      lw_data     LIKE LINE OF lt_data.

RANGES: r_date FOR  sy-datum.



SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-002.
PARAMETER: rb_hos RADIOBUTTON GROUP g2 USER-COMMAND flag2  DEFAULT 'X',
           rb_loc RADIOBUTTON GROUP g2 .
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-007.
PARAMETER: p_path LIKE rlgrap-filename MODIF ID bl1 DEFAULT '/IFR/CRM/outbound/inv/ASC/' LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-008.
PARAMETER: p_loc LIKE rlgrap-filename MODIF ID bl2 LOWER CASE.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE text-009.
PARAMETER: p_file(100) OBLIGATORY DEFAULT 'ZCRIF'.
SELECTION-SCREEN END OF BLOCK b4.

INITIALIZATION.
  lv_datum = sy-datum.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_FILE'.
      screen-input = 0.
    ENDIF.

    IF rb_hos = 'X'  AND  screen-group1 = 'BL2'.
      screen-active = '0'.
    ELSEIF rb_loc = 'X'  AND  screen-group1 = 'BL1'.
      screen-active = '0'.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

****EVENTO SCATENATO ALL'INSERIMENTO DEL PATH****
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_loc.

  CALL FUNCTION 'TMP_GUI_BROWSE_FOR_FOLDER'
    EXPORTING
      window_title    = 'titolo'
      initial_folder  = 'c:\'
    IMPORTING
      selected_folder = p_loc.
* EXCEPTIONS
*   CNTL_ERROR            = 1
*   OTHERS                = 2



START-OF-SELECTION.
  PERFORM controlli_file.
*calcola le date
  PERFORM calcola_date.
*selezioni a DB
  PERFORM selezioni.
*elaborazione record file
  PERFORM elaborazione.
*salvataggio file
  PERFORM savefile.



************************************************************************
***    FORM               **********************************************
************************************************************************


*&---------------------------------------------------------------------*
*&      Form  elaborazione
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM elaborazione.
  TYPES: BEGIN OF t_appo,
          guid_contratto TYPE zca_bdm_crif-guid_contratto,
          codice_crif    TYPE zca_bdm_crif-codice_crif,
          bp_cliente     TYPE zca_bdm_crif-bp_cliente,
          tipo_elab(1)   TYPE c,
         END OF t_appo.

  DATA: lw_bdm_crif_1 LIKE LINE OF lt_bdm_crif,
        lv_cont       TYPE i,
        lt_appo       TYPE t_appo OCCURS 0,
        lw_crif       LIKE LINE OF lt_bdm_crif,
        lw_appo       LIKE LINE OF lt_appo,
        lv_data_cre   TYPE sy-datum,
        lv_ko(1)      TYPE c.

  SORT lt_bdm_crif BY bp_cliente.

  LOOP AT lt_bdm_crif INTO lw_bdm_crif.
    lw_crif = lw_bdm_crif.
    AT NEW bp_cliente.
      lw_bdm_crif = lw_crif.
      CLEAR: lw_bdm_crif_1,lw_appo,lw_bdm_crif_1,lv_cont.

      LOOP AT lt_bdm_crif INTO lw_bdm_crif_1 WHERE bp_cliente = lw_bdm_crif-bp_cliente.
        lv_cont = lv_cont + 1.
      ENDLOOP.

      IF lv_cont = 1.
        IF lw_bdm_crif-data_creazione IN r_date.
          lw_appo-guid_contratto = lw_bdm_crif-guid_contratto.
          lw_appo-codice_crif = lw_bdm_crif-codice_crif.
          lw_appo-bp_cliente = lw_bdm_crif-bp_cliente.
          lw_appo-tipo_elab = ca_i.
          APPEND lw_appo TO lt_appo.
        ENDIF.
      ELSEIF lv_cont > 1.
        CLEAR: lv_data_cre,lv_ko,lw_bdm_crif_1.
        LOOP AT lt_bdm_crif INTO lw_bdm_crif_1 WHERE bp_cliente = lw_bdm_crif-bp_cliente.

          IF lv_data_cre < lw_bdm_crif_1-data_creazione.
            lv_data_cre = lw_bdm_crif_1-data_creazione.

            lw_appo-guid_contratto = lw_bdm_crif-guid_contratto.
            lw_appo-codice_crif = lw_bdm_crif-codice_crif.
            lw_appo-bp_cliente = lw_bdm_crif-bp_cliente.
          ENDIF.

          IF lw_bdm_crif_1-data_creazione NOT IN r_date.
            lv_ko = 'X'.
          ENDIF.
        ENDLOOP.

        IF lv_ko IS INITIAL.
          lw_appo-tipo_elab = ca_i.
          APPEND lw_appo TO lt_appo.
        ELSE.
          lw_appo-tipo_elab = ca_m.
          APPEND lw_appo TO lt_appo.
        ENDIF.

      ENDIF.

    ENDAT.
  ENDLOOP.

  LOOP AT lt_appo INTO lw_appo.

    CLEAR lw_bdm_crif.
    READ TABLE lt_bdm_crif INTO lw_bdm_crif
                       WITH KEY guid_contratto = lw_appo-guid_contratto
                                codice_crif    = lw_appo-codice_crif
                                bp_cliente     = lw_appo-bp_cliente.

    lw_data-tipo_elaborazione = lw_appo-tipo_elab.

*VPM 22.12.2011
*    lw_data-id_cliente_bic = lw_bdm_crif-bp_cliente.
    SELECT SINGLE bpext
      FROM but000
      INTO lw_data-id_cliente_bic
     WHERE partner = lw_bdm_crif-bp_cliente.
*VPM 22.12.2011
    lw_data-id_cliente_crm = lw_bdm_crif-bp_cliente.

    READ TABLE lt_but000 INTO lw_but000 WITH KEY partner = lw_bdm_crif-bp_cliente.
    lw_data-cod_fiscale = lw_but000-bu_sort1.
    lw_data-cod_partita_iva = lw_but000-bu_sort2.

    lw_data-sae_crif = lw_bdm_crif-sae.
    lw_data-rae_crif = lw_bdm_crif-rae.
    lw_data-desc_sae_crif = lw_bdm_crif-desc_sae.
    lw_data-desc_rae_crif = lw_bdm_crif-desc_rae.
    lw_data-codice_ateco_crif = lw_bdm_crif-cod_ateco.

    lw_data-stato_azienda = lw_bdm_crif-stato_azienda.
    lw_data-dati_fondo_garanzia = lw_bdm_crif-eleggibilita_gar.
    lw_data-procedure_conc = lw_bdm_crif-procedure_concor.
    lw_data-dati_scoring_crif = lw_bdm_crif-applicabilita_sc.
    lw_data-protesti = lw_bdm_crif-presenza_protest.
    lw_data-pregiudizievoli_gravi = lw_bdm_crif-presenza_pregiud.

    PERFORM trascodifica_xx CHANGING lw_data-stato_azienda.
    PERFORM trascodifica_01 CHANGING lw_data-dati_fondo_garanzia.
    PERFORM trascodifica_sn CHANGING lw_data-procedure_conc.
    PERFORM trascodifica_sn CHANGING lw_data-dati_scoring_crif.
    PERFORM trascodifica_sn CHANGING lw_data-protesti.
    PERFORM trascodifica_sn CHANGING lw_data-pregiudizievoli_gravi.


    APPEND lw_data TO lt_data.
  ENDLOOP.

ENDFORM.                    "elaborazione


*&---------------------------------------------------------------------*
*&      Form  trascodifica
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->LW_DATA-PREGIUDIZIEVOLI_GRAVI  text
*----------------------------------------------------------------------*
FORM trascodifica_sn CHANGING va_string TYPE any.

  IF va_string = 'S'.
    va_string = 'SI'.
  ELSEIF va_string = 'N'.
    va_string = 'NO'.
  ENDIF.

ENDFORM.                    "trascodifica

*&---------------------------------------------------------------------*
*&      Form  trascodifica_01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->VA_STRING  text
*----------------------------------------------------------------------*
FORM trascodifica_01 CHANGING va_string TYPE any.

  IF va_string = '0'.
    va_string = 'NO'.
  ELSEIF va_string = '1'.
    va_string = 'SI'.
  ENDIF.

ENDFORM.                    "trascodifica_01


FORM trascodifica_xx CHANGING va_string TYPE any.

  IF va_string is initial.
    va_string = 'ATTIVA'.
  ELSEIF va_string = 'I'.
    va_string = 'INATTIVA'.
  ELSEIF va_string = 'S'.
    va_string = 'SOSPESA'.
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  selezioni
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM selezioni.

  SELECT *
    FROM zca_bdm_crif_1
    INTO CORRESPONDING FIELDS OF TABLE lt_bdm_crif.

  SELECT partner bu_sort1 bu_sort2
    FROM but000
    INTO CORRESPONDING FIELDS OF TABLE lt_but000
  FOR ALL ENTRIES IN lt_bdm_crif
    WHERE partner = lt_bdm_crif-bp_cliente.

ENDFORM.                    "selezioni



*&---------------------------------------------------------------------*
*&      Form  calcola_date
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM calcola_date.

  DATA: lt_tbtco_f LIKE STANDARD TABLE OF gw_tbtco_f.

  IF lv_date_f1 IS INITIAL.

    SELECT jobname jobcount sdlstrtdt sdlstrttm
           status FROM tbtco
      INTO TABLE lt_tbtco_f
      WHERE jobname EQ ca_jobname AND
            status  EQ ca_f.

    SORT lt_tbtco_f BY sdlstrtdt DESCENDING
                       sdlstrttm DESCENDING.

    READ TABLE lt_tbtco_f INTO gw_tbtco_f INDEX 1.
    lv_date_f1 = gw_tbtco_f-sdlstrtdt.

  ENDIF.

  IF lv_date_f1 IS INITIAL.
    lv_date_f1 = '20120102'.
  ENDIF.

  MOVE 'I' TO r_date-sign.
  MOVE 'BT' TO r_date-option.
  MOVE lv_date_f1 TO r_date-low.
  MOVE sy-datum   TO r_date-high.
  APPEND r_date.

ENDFORM.                    "calcola_date



*&---------------------------------------------------------------------*
*&      Form  controlli_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM controlli_file.

  IF rb_hos IS NOT INITIAL.
*se il path host è vuoto manda il mess di errore
    IF p_path IS INITIAL.
      MESSAGE e208(00) WITH text-003.
    ENDIF.

  ELSEIF rb_loc IS NOT INITIAL.
*se il path locale è vuoto manda il messaggio di errore
    IF p_loc IS INITIAL.
      MESSAGE e208(00) WITH text-004.
    ENDIF.

  ENDIF.

ENDFORM.                    "controlli_file


*&---------------------------------------------------------------------*
*&      Form  f_savefile
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM savefile.
  LOOP AT lt_data INTO lw_data.

    CONCATENATE lw_data-tipo_elaborazione
                lw_data-id_cliente_bic
                lw_data-id_cliente_crm
                lw_data-cod_fiscale
                lw_data-cod_partita_iva
                lw_data-sae_crif
                lw_data-rae_crif
                lw_data-desc_sae_crif
                lw_data-desc_rae_crif
                lw_data-codice_ateco_crif
                lw_data-stato_azienda
                lw_data-dati_fondo_garanzia
                lw_data-procedure_conc
                lw_data-dati_scoring_crif
                lw_data-protesti
                lw_data-pregiudizievoli_gravi
*                lw_data-pre_scoring
           INTO lw_file SEPARATED BY '|'.
    CONDENSE lw_data NO-GAPS.
*    REPLACE all occurrences of ' ' IN lw_file WITH ''.
    APPEND lw_file TO lt_file.
  ENDLOOP.

  IF rb_hos IS NOT INITIAL.
    PERFORM f_save_file_host.
  ELSE.
    PERFORM f_save_file_loc.
  ENDIF.
ENDFORM.                    "f_savefile

*&---------------------------------------------------------------------*
*&      Form  f_save_file_host
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_save_file_host.
  CONCATENATE p_path p_file '_' sy-datum '.CSV'  INTO p_file.

*-scrittura del file su Server:
  OPEN DATASET p_file FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc <> 0.
*-errore in apertura file di output su server:
    MESSAGE e208(00) WITH text-005.
  ENDIF.

  LOOP AT lt_file INTO lw_file.
    CATCH SYSTEM-EXCEPTIONS dataset_write_error = 4.
      TRANSFER lw_file TO p_file.
    ENDCATCH.
    IF sy-subrc = 4.
      MESSAGE e208(00) WITH text-007.
    ENDIF.
    CLEAR lw_file.
  ENDLOOP.

  CLOSE DATASET p_file.
  IF sy-subrc <> 0.
*-errore in chiusura file di output su server:
    MESSAGE e208(00) WITH text-006.
  ENDIF.

ENDFORM.                    "f_save_file_host

*&---------------------------------------------------------------------*
*&      Form  f_save_file_loc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM f_save_file_loc .

  DATA: l_file_loc2 TYPE string.
  CONCATENATE p_loc '\' p_file '_' sy-datum '.CSV' INTO l_file_loc2.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
*   BIN_FILESIZE                    =
      filename                        = l_file_loc2
      filetype                        = 'ASC'
*   APPEND                          = ' '
      write_field_separator           = '|'
*   HEADER                          = '00'
      trunc_trailing_blanks           = 'X'
*   WRITE_LF                        = 'X'
*   COL_SELECT                      = ' '
*   COL_SELECT_MASK                 = ' '
*   DAT_MODE                        = ' '
*   CONFIRM_OVERWRITE               = ' '
*   NO_AUTH_CHECK                   = ' '
*   CODEPAGE                        = ' '
*   IGNORE_CERR                     = ABAP_TRUE
*   REPLACEMENT                     = '#'
*   WRITE_BOM                       = ' '
*   TRUNC_TRAILING_BLANKS_EOL       = 'X'
*   WK1_N_FORMAT                    = ' '
*   WK1_N_SIZE                      = ' '
*   WK1_T_FORMAT                    = ' '
*   WK1_T_SIZE                      = ' '
*   WRITE_LF_AFTER_LAST_LINE        = ABAP_TRUE
*   SHOW_TRANSFER_STATUS            = ABAP_TRUE
* IMPORTING
*   FILELENGTH                      =
    TABLES
      data_tab                        = lt_file
*   FIELDNAMES                      =
* EXCEPTIONS
*   FILE_WRITE_ERROR                = 1
*   NO_BATCH                        = 2
*   GUI_REFUSE_FILETRANSFER         = 3
*   INVALID_TYPE                    = 4
*   NO_AUTHORITY                    = 5
*   UNKNOWN_ERROR                   = 6
*   HEADER_NOT_ALLOWED              = 7
*   SEPARATOR_NOT_ALLOWED           = 8
*   FILESIZE_NOT_ALLOWED            = 9
*   HEADER_TOO_LONG                 = 10
*   DP_ERROR_CREATE                 = 11
*   DP_ERROR_SEND                   = 12
*   DP_ERROR_WRITE                  = 13
*   UNKNOWN_DP_ERROR                = 14
*   ACCESS_DENIED                   = 15
*   DP_OUT_OF_MEMORY                = 16
*   DISK_FULL                       = 17
*   DP_TIMEOUT                      = 18
*   FILE_NOT_FOUND                  = 19
*   DATAPROVIDER_EXCEPTION          = 20
*   CONTROL_FLUSH_ERROR             = 21
*   OTHERS                          = 22
            .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    "f_save_file_loc


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
