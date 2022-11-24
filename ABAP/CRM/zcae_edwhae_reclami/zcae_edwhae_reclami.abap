*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_RECLAMI
*&
*&---------------------------------------------------------------------*
*& Creato da: Sebastiano Ceglie
*&
*& Data Creazione: 08/09/2008
*&
*& ID: EDW_003
*&
*& Descrizione: L'interfaccia permette l'estrazione dei dati inerenti
*&              ai reclami
*&
*&---------------------------------------------------------------------*
*& Modifiche:   Concetta Pastore CP
*& Data:        18/05/2009
*& Descrizione: Aggiunta campi al tracciato di output
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_reclami.

** Costanti

CONSTANTS :

            ca_fileout     TYPE filename-fileintern  VALUE 'ZCRMOUT001_EDWHAE_RECL',
            ca_filelog     TYPE filename-fileintern  VALUE 'ZCRMLOG001_EDWHAE_RECL',
            ca_i(1)        TYPE c                    VALUE 'I',
            ca_x(1)        TYPE c                    VALUE 'X',
            ca_sep(1)      TYPE c                    VALUE '|',
            ca_par(8)      TYPE c                    VALUE 'P_DATE_F',
            ca_eq(2)       TYPE c                    VALUE 'EQ',
            ca_jobname     TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_RECLAMI',
            ca_f           TYPE tbtco-status         VALUE 'F',
            ca_r           TYPE tbtco-status         VALUE 'R',
            ca_edre        TYPE zca_param-z_group    VALUE 'EDRE',
            ca_recl        TYPE zca_param-z_group    VALUE 'RECL',
            ca_appl        TYPE zca_param-z_appl     VALUE 'ZCAE_EDWHAE_RECLAMI',
            ca_rec_fctcl   TYPE zca_param-z_nome_par VALUE 'REC_FCTCL',
            ca_pft_port    TYPE zca_param-z_nome_par VALUE 'PFT_PORT',         "-- Add CP 19.10.2010
            ca_rec_fctdip  TYPE zca_param-z_nome_par VALUE 'REC_FCTDIP',
            ca_edw_appre   TYPE zca_param-z_nome_par VALUE 'EDW_APPRE',
            ca_recl_dric   TYPE zca_param-z_nome_par VALUE 'RECL_DRIC',
            ca_recl_drec   TYPE zca_param-z_nome_par VALUE 'RECL_DREC',
            ca_recl_dins   TYPE zca_param-z_nome_par VALUE 'RECL_DINS',
*           Begin G.Mele 12/11/2008
            ca_recl_conl1   TYPE zca_param-z_nome_par VALUE 'RECL_CONL1',
            ca_point(1)     TYPE c VALUE '.',
            ca_recl_conl2  TYPE zca_param-z_nome_par VALUE 'RECL_CONL2'.
*           End G.Mele 12/11/2008

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X' USER-COMMAND sy-ucomm,
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE crmd_orderadm_h-created_at,

           p_fout   TYPE filename-fileintern DEFAULT ca_fileout OBLIGATORY,
           p_flog   TYPE filename-fileintern DEFAULT ca_filelog OBLIGATORY,

           p_psize  TYPE i DEFAULT 150 OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

** Work area
DATA : BEGIN OF wa_file,
    cod_recl_crm(10)      TYPE c,
    dip_responsabile(12)  TYPE c,
    divisione(4)          TYPE c,
    cod_cliente_crm(12)   TYPE c,
    data_rec(8)           TYPE c,
    data_ric_rec(8)       TYPE c,
    data_ins_rec(8)       TYPE c,
    stato(5)              TYPE c,
    mezzo_cont(15)        TYPE c,
    can_acq(40)	          TYPE c,
    val_contr(15)         TYPE c,
    note(1000)            TYPE c,
    motivazione(3)        TYPE c,
    prodotto_bic(40)      TYPE c,
    val_reclamo(16)       TYPE c,
    area(10)              TYPE c, "G.Mele 12/11/2008
    priorita(1)           TYPE c, "G.Mele 12/11/2008
    mezzo_com_risp(15)    TYPE c, "G.Mele 12/11/2008
    data_fine_rec(8)      TYPE c, "G.Mele 12/11/2008
    data_creazione(14)    TYPE c, "ADD CP 18/05/2009
    data_mod(14)          TYPE c, "ADD CP 18/05/2009
    num_invii(13)         TYPE c,
    zzalt(10)             TYPE c, "-- Add CP 19.10.2010
  END OF wa_file.

* TIPI
TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES : BEGIN OF t_anprod,
        product_guid TYPE zca_anprodotto-product_guid,
        zz0010 TYPE zca_anprodotto-zz0010,
      END OF t_anprod.


TYPES: BEGIN OF t_cust_h,
        guid             TYPE crmd_customer_h-guid,
        zzcustomer_h0401 TYPE crmd_customer_h-zzcustomer_h0401,
        zzcustomer_h0402 TYPE crmd_customer_h-zzcustomer_h0402, " G.Mele 12/11/2008
        zzcustomer_h0403 TYPE crmd_customer_h-zzcustomer_h0403,
        zzcustomer_h0404 TYPE crmd_customer_h-zzcustomer_h0404,
        zzcustomer_h0406 TYPE crmd_customer_h-zzcustomer_h0406, " G.Mele 12/11/2008
        zzcustomer_h0407 TYPE crmd_customer_h-zzcustomer_h0407,
      END OF t_cust_h.

TYPES: BEGIN OF t_cust_i,
        guid TYPE crmd_customer_i-guid,
        zzcustomer_i0701 TYPE crmd_customer_i-zzcustomer_i0701,
      END OF t_cust_i.

TYPES: BEGIN OF t_crmd_orderadm_h,
         guid             TYPE crmd_orderadm_h-guid,
         process_type     TYPE crmd_orderadm_h-process_type,
         created_at       TYPE crmd_orderadm_h-created_at,
         changed_at       TYPE crmd_orderadm_h-changed_at,
         guid_i           TYPE crmd_orderadm_i-guid,
       END OF t_crmd_orderadm_h.


* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c,
      va_date_t       TYPE crmd_orderadm_h-created_at,
      va_rec_fctcl    TYPE zca_param-z_val_par,
      va_pft_port     TYPE zca_param-z_val_par,          "-- Add CP 19.10.2010
      va_rec_fctdip   TYPE zca_param-z_val_par,
      va_edw_appre    TYPE zca_param-z_nome_par,
      va_recl_drec    TYPE zca_param-z_nome_par,
      va_guid         TYPE crmd_orderadm_h-guid,
      va_recl_dric    TYPE zca_param-z_nome_par,
      va_recl_dins    TYPE zca_param-z_nome_par,
*     Begin G.Mele 12/11/2008
      va_recl_conl1    TYPE zca_param-z_nome_par,
      wa_dec(3)       TYPE c,
      num_invii(13)   TYPE c,
      va_recl_conl2    TYPE zca_param-z_nome_par.
*     End G.Mele 12/11/2008

* RANGES
DATA: r_edre TYPE RANGE OF crmd_orderadm_h-process_type,
      r_recl TYPE RANGE OF bapibus20001_status_dis-user_stat_proc.

* TABELLE
DATA: i_crmd_orderadm_h TYPE STANDARD TABLE OF t_crmd_orderadm_h,

*     Dichiarazione tabelle per BAPI
      i_appointment     TYPE STANDARD TABLE OF bapibus20001_appointment_dis,
      i_prod            TYPE STANDARD TABLE OF t_anprod,
      i_guid            TYPE STANDARD TABLE OF bapibus20001_guid_dis,
      i_item            TYPE STANDARD TABLE OF bapibus20001_item_dis,
      i_schedule_item   TYPE STANDARD TABLE OF bapibus20001_schedlin_item_dis,
      i_schedul         TYPE STANDARD TABLE OF bapibus20001_schedlin_dis,
      i_header          TYPE STANDARD TABLE OF bapibus20001_header_dis,
      i_activity        TYPE STANDARD TABLE OF bapibus20001_activity_dis, "G.Mele 12/11/2008
      i_crm_jcds        TYPE STANDARD TABLE OF crm_jcds,                  "G.Mele 12/11/2008
      i_partner         TYPE STANDARD TABLE OF bapibus20001_partner_dis,
      i_cust_h          TYPE STANDARD TABLE OF t_cust_h,
      i_cust_i          TYPE STANDARD TABLE OF t_cust_i,
      i_status          TYPE STANDARD TABLE OF bapibus20001_status_dis,
      i_text            TYPE STANDARD TABLE OF bapibus20001_text_dis.

* FIELD-SYMBOLS
FIELD-SYMBOLS:
               <fs_appointment_dric>  LIKE LINE OF i_appointment,
               <fs_activity>          LIKE LINE OF i_activity,   " G.Mele 12/11/2008
               <fs_crm_jcds>          LIKE LINE OF i_crm_jcds,   " G.Mele 12/11/2008
               <fs_appointment_drec>  LIKE LINE OF i_appointment,
               <fs_appointment_dins>  LIKE LINE OF i_appointment,
               <fs_schedule_item>     LIKE LINE OF i_schedule_item,
               <fs_crmd_orderadm_h>   LIKE LINE OF i_crmd_orderadm_h,
               <fs_guid>              LIKE LINE OF i_guid,
               <fs_item>              LIKE LINE OF i_item,
               <fs_cust_h>            TYPE t_cust_h,
               <fs_cust_i>            TYPE t_cust_i,
               <fs_prod>              TYPE t_anprod,
               <fs_schedul>           TYPE  bapibus20001_schedlin_dis,
               <fs_header>            LIKE LINE OF i_header,
               <fs_partner_cl>        LIKE LINE OF i_partner,
               <fs_partner_op>        LIKE LINE OF i_partner,
               <fs_status>            LIKE LINE OF i_status,
               <fs_text>              LIKE LINE OF i_text.


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF screen-name = ca_par.

      CASE ca_x.
*   Estrazioni FULL
        WHEN r_full.

          screen-input = ca_x.
          CLEAR p_date_f.
          MODIFY SCREEN.
        WHEN OTHERS.
      ENDCASE.


    ENDIF.
*    MODIFY SCREEN.
  ENDLOOP.

INITIALIZATION.

  PERFORM pulizia.

START-OF-SELECTION.

* Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

* Recupero parametri
  PERFORM estrazione_parametri.

* Apre i file di output e log
  PERFORM apri_file.

** Estrazione dati prodotto
  PERFORM estrazione_zca_anprodotto.

* Estrazioni dal DB
  PERFORM estrazioni.

* Chiude i file di output e log
  PERFORM chiudi_file.

*&---------------------------------------------------------------------*
*&      Form  pulizia
*&---------------------------------------------------------------------*
FORM pulizia .

  CLEAR : va_ts,va_date_t,va_rec_fctcl,va_rec_fctdip,va_recl_drec,
          va_edw_appre,va_recl_dins,va_recl_dric,va_guid, va_pft_port.

  REFRESH : r_recl,r_edre,i_crmd_orderadm_h.

ENDFORM.                    " pulizia

*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING    p_logic TYPE filename-fileintern
                            p_param TYPE c
                   CHANGING p_fname TYPE c.

  CLEAR p_fname.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
    IMPORTING
      file_name        = p_fname
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.

ENDFORM.                    " recupera_file

*&---------------------------------------------------------------------*
*&      Form  read_group_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_GROUP_PARAM, e costruisce un range con
*       i valori estratti
*----------------------------------------------------------------------*
FORM read_group_param USING    p_gruppo TYPE zca_param-z_group
                               p_appl   TYPE zca_param-z_appl
                      CHANGING p_param TYPE zca_param_t.

  DATA:      lt_return TYPE STANDARD TABLE OF bapiret2.


  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_gruppo
      i_z_appl = p_appl
    TABLES
      param    = p_param
      return   = lt_return.

  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e12 p_gruppo space space.
  ENDIF.


ENDFORM.                    " read_group_param

*&---------------------------------------------------------------------*
*&      Form  estrazione_parametri
*&---------------------------------------------------------------------*
*       Estrazione parametri dalla ZCA_PARAM
*----------------------------------------------------------------------*
FORM estrazione_parametri .

  DATA: lw_range_edre  LIKE LINE OF r_edre,
        lw_range_recl  LIKE LINE OF r_recl,
        lt_param       TYPE  zca_param_t.

  FIELD-SYMBOLS <lf_param> LIKE LINE OF lt_param.

** Estrazione gruppo EDRE
  PERFORM read_group_param USING ca_edre
                                 ca_appl
                        CHANGING lt_param.

  lw_range_edre-sign   = ca_i.
  lw_range_edre-option = ca_eq.
  LOOP AT lt_param ASSIGNING <lf_param>.
    lw_range_edre-low = <lf_param>-z_val_par.
    APPEND lw_range_edre TO r_edre.
    CLEAR lw_range_edre-low.
  ENDLOOP.

  REFRESH lt_param.

** Estrazione Gruppo RECL
  PERFORM read_group_param USING ca_recl
                                 ca_appl
                        CHANGING lt_param.

  lw_range_recl-sign   = ca_i.
  lw_range_recl-option = ca_eq.
  LOOP AT lt_param ASSIGNING <lf_param>.
    lw_range_recl-low = <lf_param>-z_val_par.
    APPEND lw_range_recl TO r_recl.
    CLEAR lw_range_recl-low.
  ENDLOOP.

  REFRESH lt_param.

* Recupero dei singoli parametri
  PERFORM read_param:
    USING ca_rec_fctcl   ca_appl CHANGING va_rec_fctcl,
    USING ca_pft_port    ca_appl CHANGING va_pft_port,       "-- Add CP 19.10.2010
    USING ca_rec_fctdip  ca_appl CHANGING va_rec_fctdip,
    USING ca_edw_appre   ca_appl CHANGING va_edw_appre,
    USING ca_recl_drec   ca_appl CHANGING va_recl_drec,
    USING ca_recl_dric   ca_appl CHANGING va_recl_dric,
    USING ca_recl_dins   ca_appl CHANGING va_recl_dins,
*   Begin G.Mele 12/11/2008
    USING ca_recl_conl1   ca_appl CHANGING va_recl_conl1,
    USING ca_recl_conl2   ca_appl CHANGING va_recl_conl2.
*   End G.Mele 12/11/2008


ENDFORM.                    " estrazione_parametri

*&---------------------------------------------------------------------*
*&      Form  read_param
*&---------------------------------------------------------------------*
*       Richiama il FM Z_CA_READ_PARAM
*----------------------------------------------------------------------*
FORM read_param USING     p_name_par  TYPE zca_param-z_nome_par
                          p_z_appl    TYPE zca_param-z_appl
                CHANGING  p_z_val_par TYPE zca_param-z_val_par.

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

  IF lt_return[] IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e13 p_name_par space space.
  ENDIF.

ENDFORM.                    " read_param

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
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full .


  SELECT a~guid a~process_type a~created_at a~changed_at b~guid
    FROM crmd_orderadm_h AS a LEFT OUTER JOIN crmd_orderadm_i AS b
    ON a~guid = b~header
    INTO TABLE i_crmd_orderadm_h
    PACKAGE SIZE p_psize
    WHERE a~process_type IN r_edre.

    PERFORM valorizza_guid.
    PERFORM call_bapi_getdetailmul.
    PERFORM elabora.

    REFRESH : i_crmd_orderadm_h.
  ENDSELECT.



ENDFORM.                    " select_full

*&---------------------------------------------------------------------*
*&      Form  select_delta
*&---------------------------------------------------------------------*
*       Estrazioni DELTA
*----------------------------------------------------------------------*
FORM select_delta .
  PERFORM get_date_time_to.
  PERFORM get_date_time_from.
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
*&      Form  valorizza_guid
*&---------------------------------------------------------------------*
*       Valorizza la tabella GUID per la chiamata della BAPI
*----------------------------------------------------------------------*
FORM valorizza_guid .
  DATA : lw_guid LIKE LINE OF i_guid.

  REFRESH i_guid.

  SORT i_crmd_orderadm_h BY guid.
  DELETE ADJACENT DUPLICATES FROM i_crmd_orderadm_h COMPARING guid.

  LOOP AT i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>.

    AT FIRST.
      IF NOT va_guid IS INITIAL AND va_guid EQ <fs_crmd_orderadm_h>-guid.
        CONTINUE.
      ENDIF.
    ENDAT.

    PERFORM trascod_guid_16_32 USING <fs_crmd_orderadm_h>-guid
                               CHANGING lw_guid-guid.
    APPEND lw_guid TO i_guid.

    AT LAST.
      va_guid = <fs_crmd_orderadm_h>-guid.
    ENDAT.

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

  CALL FUNCTION 'CRM_WAP_CONVERT_GUID_TO_32'
    EXPORTING
      guid_16 = p_guid16
    IMPORTING
      guid_32 = p_guid32.

ENDFORM.                    " trascod_guid_16_32
*&---------------------------------------------------------------------*
*&      Form  call_bapi_getdetailmul
*&---------------------------------------------------------------------*
*       Richiama la BAPI BAPI_BUSPROCESSND_GETDETAILMUL
*----------------------------------------------------------------------*
FORM call_bapi_getdetailmul .

  REFRESH : i_appointment,i_header,i_partner,
            i_status,i_text,i_item,i_activity, i_schedul.

  TYPES: BEGIN OF dd_crm_jcds,
          objnr TYPE crm_jcds-objnr,
        END OF dd_crm_jcds.

  DATA : lt_guid LIKE i_guid,
         lv_guid_16 TYPE sysuuid-x,
         lt_crm_jcds TYPE STANDARD TABLE OF dd_crm_jcds,
         lw_crm_jcds LIKE LINE OF lt_crm_jcds.


* Utilizza una tabella d'appoggio perchè la tabella i_guid non deve
* essere modificata
  lt_guid[] = i_guid[].

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid        = lt_guid
      header      = i_header
      activity    = i_activity " G.Mele 12/11/2008
      partner     = i_partner
      appointment = i_appointment
      text        = i_text
      status      = i_status
      item        = i_item
*      SCHEDULE_ITEM = i_SCHEDULE_ITEM.
      schedule      = i_schedul.


  " Begin G.Mele 12/11/2008
  IF NOT lt_guid[] IS INITIAL.

    REFRESH lt_crm_jcds.
    UNASSIGN <fs_guid>.
    LOOP AT lt_guid ASSIGNING <fs_guid>.
      PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                              CHANGING lv_guid_16.

      lw_crm_jcds-objnr = lv_guid_16.
      APPEND lw_crm_jcds TO lt_crm_jcds.

    ENDLOOP.

    REFRESH i_crm_jcds.
    SELECT *
      FROM crm_jcds
       INTO TABLE i_crm_jcds
         FOR ALL ENTRIES IN lt_crm_jcds
           WHERE objnr EQ lt_crm_jcds-objnr
             AND ( stat  EQ va_recl_conl1
             OR    stat  EQ va_recl_conl2 )
             AND chind EQ ca_i.

*   Valore più recente del campo CRM_JCDS-UDATE.
    SORT i_crm_jcds BY udate DESCENDING.
    DELETE ADJACENT DUPLICATES FROM i_crm_jcds COMPARING udate.

  ENDIF.
  " End G.Mele 12/11/2008

ENDFORM.                    " call_bapi_getdetailmul

*&---------------------------------------------------------------------*
*&      Form  trascod_guid_32_16
*&---------------------------------------------------------------------*
*       Trascodifica un GUID da CHAR32 a RAW16
*----------------------------------------------------------------------*
FORM trascod_guid_32_16 USING    p_guid32 TYPE sysuuid-c
                        CHANGING p_guid16 TYPE sysuuid-x.
  CLEAR p_guid16.

  CALL FUNCTION 'CRM_WAP_CONVERT_GUID_TO_16'
    EXPORTING
      guid_32 = p_guid32
    IMPORTING
      guid_16 = p_guid16.

ENDFORM.                    "trascod_guid_32_16
*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora .

  DATA : lv_tdid TYPE bapibus20001_text_dis-tdid.

  lv_tdid = va_edw_appre.

  DELETE i_text WHERE tdid    NE lv_tdid OR
                      tdspras NE ca_i.

  PERFORM estrazione_crmd_customer.

  SORT:
        i_cust_h          BY guid,
        i_cust_i          BY guid,
        i_appointment     BY ref_guid appt_type,
        i_header          BY guid,
        i_partner         BY ref_guid ref_partner_fct,
        i_status          BY guid,
        i_text            BY ref_guid,
        i_crmd_orderadm_h BY guid,
        i_activity        BY guid,  "G.Mele 12/11/2008
        i_schedul         BY item_guid,
*        i_SCHEDULE_ITEM   BY guid,
        i_crm_jcds        BY objnr. "G.Mele 12/11/2008


  LOOP AT i_guid ASSIGNING <fs_guid>.
    PERFORM unassign_fs.
    PERFORM read_table.
    PERFORM scrivi_record.
  ENDLOOP.
ENDFORM.                    " elabora
*&---------------------------------------------------------------------*
*&      Form  estrazione_crmd_customer
*&---------------------------------------------------------------------*
FORM estrazione_crmd_customer .

  REFRESH : i_cust_h,i_cust_i.

  SELECT guid zzcustomer_h0401 zzcustomer_h0402 "G.Mele 12/11/2008
         zzcustomer_h0403 zzcustomer_h0404
         zzcustomer_h0406 zzcustomer_h0407
    FROM crmd_customer_h
    INTO TABLE i_cust_h
    FOR ALL ENTRIES IN i_crmd_orderadm_h
    WHERE guid EQ i_crmd_orderadm_h-guid.


  SELECT guid zzcustomer_i0701
    FROM crmd_customer_i
    INTO TABLE i_cust_i
    FOR ALL ENTRIES IN i_crmd_orderadm_h
    WHERE guid EQ i_crmd_orderadm_h-guid_i.

ENDFORM.                    " estrazione_crmd_customer
*&---------------------------------------------------------------------*
*&      Form  unassign_fs
*&---------------------------------------------------------------------*
*       Esegue l'unassign dei field symbol utilizzati dall'elaborazione
*----------------------------------------------------------------------*
FORM unassign_fs .
  UNASSIGN: <fs_cust_h>, <fs_appointment_drec>, <fs_appointment_dric>,
            <fs_header>,<fs_partner_cl>, <fs_partner_op>, <fs_cust_i>,
            <fs_schedul>, <fs_status>, <fs_text>, <fs_appointment_dins>,
            <fs_crmd_orderadm_h>,<fs_item>,<fs_prod>, <fs_activity>, "G.Mele 12/11/2008
            <fs_crm_jcds>.                                           "G.Mele 12/11/2008

  CLEAR wa_file.

ENDFORM.                    " unassign_fs
*&---------------------------------------------------------------------*
*&      Form  read_table
*&---------------------------------------------------------------------*
*       Lettura dei dati estratti per il caricamento del file
*----------------------------------------------------------------------*
FORM read_table .

  DATA : lv_app_type  TYPE crmt_apptype,
         lv_header    TYPE guid_32,
         lv_partner   TYPE crmt_partner_fct.


  DATA lv_guid_16 TYPE crmd_orderadm_h-guid.
* Trascodifica il GUID per leggere dalla tabella I_CRMD_ORDERADM_H
  PERFORM trascod_guid_32_16 USING <fs_guid>-guid
                             CHANGING lv_guid_16.

  CLEAR wa_file.

  "BEGIN CP 18/05/2009
* Lettura record dalla tabella CRMD_CUSTOMER_H (estratta in join con
* la tabella CRMD_ORDERADM_H)
  READ TABLE i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>
    WITH KEY guid = lv_guid_16.
  IF sy-subrc IS INITIAL.
    PERFORM f_convert_tmstmp USING <fs_crmd_orderadm_h>-created_at
                              CHANGING  wa_file-data_creazione.

    PERFORM f_convert_tmstmp USING <fs_crmd_orderadm_h>-changed_at
                              CHANGING  wa_file-data_mod.

  ENDIF.
  "END CP 18/05/2009
** Header

  READ TABLE i_header ASSIGNING <fs_header>
                      WITH KEY guid = <fs_guid>-guid
                      BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-divisione     = <fs_header>-process_type.
    wa_file-cod_recl_crm   = <fs_header>-object_id.
  ENDIF.


*** Appointment

  lv_app_type = va_recl_drec.

  READ TABLE i_appointment ASSIGNING <fs_appointment_drec>
                      WITH KEY ref_guid = <fs_guid>-guid
                               appt_type = lv_app_type
                      BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-data_rec      = <fs_appointment_drec>-date_from.
  ENDIF.

  CLEAR lv_app_type.
  lv_app_type = va_recl_dric.
  READ TABLE i_appointment ASSIGNING <fs_appointment_dric>
                      WITH KEY ref_guid = <fs_guid>-guid
                               appt_type = lv_app_type
                      BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-data_ric_rec    = <fs_appointment_dric>-date_from.
  ENDIF.

  CLEAR lv_app_type.
  lv_app_type = va_recl_dins.

  READ TABLE i_appointment ASSIGNING <fs_appointment_dins>
                      WITH KEY ref_guid = <fs_guid>-guid
                               appt_type = lv_app_type
                      BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-data_ins_rec    = <fs_appointment_dins>-date_from.
  ENDIF.

** Partner

  lv_partner = va_rec_fctcl.

* Lettura record dalla tabella PARTNER (per cliente)
  READ TABLE i_partner ASSIGNING <fs_partner_cl>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = lv_partner BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-cod_cliente_crm     = <fs_partner_cl>-ref_partner_no.
  ENDIF.

  CLEAR lv_partner.
  lv_partner = va_rec_fctdip.

* Lettura record dalla tabella PARTNER (per operatore)
  READ TABLE i_partner ASSIGNING <fs_partner_op>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = lv_partner BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    wa_file-dip_responsabile  = <fs_partner_op>-ref_partner_no.
  ENDIF.


  " -- Begin CP 19.10.2010
** Portafoglio

  lv_partner = va_pft_port.

* Lettura record dalla tabella PARTNER (per portafoglio)
  READ TABLE i_partner ASSIGNING <fs_partner_cl>
    WITH KEY ref_guid        = <fs_guid>-guid
             ref_partner_fct = lv_partner BINARY SEARCH.

  IF sy-subrc IS INITIAL.
    SELECT SINGLE zzalt
      FROM but000
      INTO wa_file-zzalt
      WHERE partner EQ <fs_partner_cl>-ref_partner_no(10).
  ENDIF.

  " -- End CP 19.10.2010


** Note

* Concatenazione delle note
  READ TABLE i_text TRANSPORTING NO FIELDS
    WITH KEY ref_guid = <fs_guid>-guid BINARY SEARCH.

  IF sy-subrc EQ 0.
    LOOP AT i_text ASSIGNING <fs_text> FROM sy-tabix.
      IF <fs_text>-ref_guid NE <fs_guid>-guid.
        EXIT.
      ENDIF.

      IF wa_file-note IS INITIAL.
        wa_file-note = <fs_text>-tdline.
      ELSE.

        CONCATENATE wa_file-note <fs_text>-tdline
               INTO  wa_file-note
        SEPARATED BY space.
      ENDIF.


      IF STRLEN( wa_file-note ) = 1000.
        EXIT.
      ENDIF.


    ENDLOOP.

  ENDIF.


** Status

* Loop a doppio indice sulle posizioni della tabella STATUS
* relative al GUID corrente, per trovare un record con il campo
* USER_STAT_PROC valorizzato
  READ TABLE i_status TRANSPORTING NO FIELDS
    WITH KEY guid = <fs_guid>-guid BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    LOOP AT i_status ASSIGNING <fs_status> FROM sy-tabix.
      IF <fs_status>-guid NE <fs_guid>-guid OR
         <fs_status>-user_stat_proc IN r_recl. "Se il campo è valorizzato, esci
        EXIT.
      ENDIF.
    ENDLOOP.

* Se è uscito senza trovare il record, ma solo perchè erano finite le
* posizioni per il GUID corrente, dereferenzia il puntatore
    IF <fs_status>-guid EQ <fs_guid>-guid.
      wa_file-stato = <fs_status>-status.
    ENDIF.

  ENDIF.

* Begin G.Mele 12/11/2008
* Valorizzazione Campo -->   PRIORITA
  READ TABLE i_activity ASSIGNING <fs_activity>
                      WITH KEY guid = lv_guid_16
                      BINARY SEARCH.
  IF sy-subrc EQ 0.
*   PRIORITA = CRMD_ACTIVITY_H-PRIORITY
    IF NOT <fs_activity>-priority IS INITIAL.
      wa_file-priorita = <fs_activity>-priority.
    ENDIF.
  ENDIF.

* Per il campo DATA_FINE_REC
  READ TABLE i_crm_jcds ASSIGNING <fs_crm_jcds>
    WITH KEY objnr = lv_guid_16
       BINARY SEARCH.
  IF sy-subrc EQ 0.
*     #	DATA_FINE_REC = valore più recente del campo CRM_JCDS-UDATE.
    wa_file-data_fine_rec = <fs_crm_jcds>-udate.
  ENDIF.

* End G.Mele 12/11/2008

** CRMD_CUSTOMER_H

  READ TABLE i_cust_h ASSIGNING <fs_cust_h>
                      WITH KEY guid = lv_guid_16
                      BINARY SEARCH.

  IF sy-subrc EQ 0.

    wa_file-mezzo_cont    = <fs_cust_h>-zzcustomer_h0404.
    wa_file-can_acq       = <fs_cust_h>-zzcustomer_h0401.
    wa_file-val_contr     = <fs_cust_h>-zzcustomer_h0403.
*   Begin G.Mele 12/11/2008
    wa_file-area           = <fs_cust_h>-zzcustomer_h0406.
    wa_file-mezzo_com_risp = <fs_cust_h>-zzcustomer_h0402.
*   End G.Mele 12/11/2008
    wa_file-motivazione   = <fs_cust_h>-zzcustomer_h0407.

  ENDIF.


  READ TABLE i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>
                               WITH KEY guid = lv_guid_16.

  IF sy-subrc EQ 0.
** CRMD_CUSTOMER_I

    READ TABLE i_cust_i ASSIGNING <fs_cust_i>
                        WITH KEY guid = <fs_crmd_orderadm_h>-guid_i
                        BINARY SEARCH.

    IF sy-subrc EQ 0.
      wa_file-val_reclamo   = <fs_cust_i>-zzcustomer_i0701.
      CONDENSE wa_file-val_reclamo NO-GAPS.
    ENDIF.

  ENDIF.

  lv_header = lv_guid_16.

** Lettura item and zca_anprodotto
  READ TABLE i_item ASSIGNING <fs_item>
                      WITH KEY header = lv_header.

  IF sy-subrc IS INITIAL.

    CLEAR lv_guid_16.
    lv_guid_16 = <fs_item>-product.

    READ TABLE i_prod ASSIGNING <fs_prod>
                       WITH KEY product_guid = lv_guid_16.

    IF sy-subrc IS INITIAL.
      wa_file-prodotto_bic   = <fs_prod>-zz0010.
    ENDIF.

* lettura numero invii

    READ TABLE i_schedul ASSIGNING <fs_schedul> WITH KEY item_guid = <fs_item>-guid BINARY SEARCH.

    IF sy-subrc IS INITIAL.

      num_invii     = <fs_schedul>-quantity.

      SPLIT num_invii
      AT ca_point
      INTO wa_file-num_invii
           wa_dec.

      CONDENSE :
                  wa_file-num_invii NO-GAPS.

    ENDIF.


  ENDIF.

ENDFORM.                    " read_table
*&---------------------------------------------------------------------*
*&      Form  estrazione_ZCA_ANPRODOTTO
*&---------------------------------------------------------------------*
FORM estrazione_zca_anprodotto .

  REFRESH i_prod.

  SELECT product_guid zz0010
    FROM zca_anprodotto
    INTO TABLE i_prod.

ENDFORM.                    " estrazione_ZCA_ANPRODOTTO
*&---------------------------------------------------------------------*
*&      Form  scrivi_record
*&---------------------------------------------------------------------*
FORM scrivi_record .

  DATA : lv_recout TYPE string,
         lv_reclog TYPE string.



  CONCATENATE wa_file-cod_recl_crm wa_file-dip_responsabile wa_file-divisione
              wa_file-cod_cliente_crm wa_file-data_rec wa_file-data_ric_rec
              wa_file-data_ins_rec wa_file-stato wa_file-mezzo_cont wa_file-can_acq
              wa_file-val_contr wa_file-note wa_file-motivazione wa_file-prodotto_bic
              wa_file-val_reclamo wa_file-area wa_file-priorita wa_file-mezzo_com_risp "G.Mele 12/11/2008
              wa_file-data_fine_rec  "G.Mele 12/11/2008
              wa_file-data_creazione wa_file-data_mod wa_file-num_invii "ADD CP 18/05/2009
              wa_file-zzalt        "-- Add CP 19.10.2010
  INTO lv_recout
  SEPARATED BY ca_sep.


  TRANSFER lv_recout TO va_fileout.

* Trasferimento al file di log
  CONCATENATE wa_file-cod_recl_crm
              text-l01
              INTO lv_reclog SEPARATED BY ca_sep.
  TRANSFER lv_reclog TO va_filelog.

ENDFORM.                    " scrivi_record
*&---------------------------------------------------------------------*
*&      Form  select_orderadm_h
*&---------------------------------------------------------------------*
*       Selezione della CRMD_ORDERADM_H per estrazione DELTA
*----------------------------------------------------------------------*
FORM select_orderadm_h .
  SELECT a~guid a~process_type a~created_at a~changed_at b~guid
   FROM crmd_orderadm_h AS a LEFT OUTER JOIN crmd_orderadm_i AS b
   ON a~guid = b~header
   INTO TABLE i_crmd_orderadm_h
   PACKAGE SIZE p_psize
   WHERE a~process_type IN r_edre AND
     ( ( a~created_at GE p_date_f AND a~created_at LE va_date_t ) OR
       ( a~changed_at GE p_date_f AND a~changed_at LE va_date_t ) ).

    PERFORM valorizza_guid.
    PERFORM call_bapi_getdetailmul.
    PERFORM elabora.

  ENDSELECT.

ENDFORM.                    " select_orderadm_h
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


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
