*&-----------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_BP
*&
*&-----------------------------------------------------------------------*
*&  Athor      : Vibha Vishwanath
*&  Date       : 29/07/2008
*&  Description: integrazione EDWH Anagrafica BP
*&  Modified By Paola Ferabecoli at 28/11/08
*&  Modify: eliminazione sul vincolo XDELE <> 'X' e aggiunta del campo archiviazione in output
*&-----------------------------------------------------------------------*
*&  Modifiche  : Raffaele Frattini        RF
*&  Date       : 26/01/2009
*&  Description: Eliminazione caratteri non riconosciuti da SAP
*&-----------------------------------------------------------------------*
*&  Modifiche  : Raffaele Frattini        RF
*&  Date       : 03/02/2009
*&  Description: Estrazione Ragione Sociale in base al tipo BP
*&-----------------------------------------------------------------------*
*&  Modifiche  : Concetta Pastore CP
*&  Date       : 18/05/2009
*&  Description: Aggiunta campi di output Email, Telefono e Cellulare
*&-----------------------------------------------------------------------*
*&  Modifiche  : Aurora Galeone AG
*&  Date       : 27/10/2009
*&  Description: Modifica logica di estrazione dalla BUT000
*&-----------------------------------------------------------------------*
*&  Modifiche  : Raffaele Frattini        RF
*&  Date       : 09/11/2009
*&  Description: Aggiunta estrazione BP in caso di modifica ruolo utente
*&-----------------------------------------------------------------------*
REPORT  zcae_edwhae_bp MESSAGE-ID 00.

INCLUDE zcae_edwhae_bp_inc.

INITIALIZATION.
* Initializing variables and tables
  PERFORM initialize.

START-OF-SELECTION.

* -- Estrazione Parametri da ZCA_PARAM
  PERFORM f_leggi_param.    " RF ADD 03/02/2009

* Opening files
  PERFORM open_files.

  IF rb_full = ca_x.
*   In case radio button Full is selected
    PERFORM full.

  ELSE.
* In case radio button Delta is selected
    PERFORM delta.

  ENDIF.

  CLOSE DATASET va_filename.
  CLOSE DATASET va_filelog.

*&---------------------------------------------------------------------*
*&      Form  data_to_file
*&---------------------------------------------------------------------*
*       Copy records in file
*----------------------------------------------------------------------*
FORM data_to_file.

  DATA : lv_rag_soc   TYPE string,
         lv_resto     TYPE string,
         lv_null_0000 TYPE string,
         lv_acapo_0a  TYPE string,
         lv_acapo_0d  TYPE string,
         lv_utente    TYPE string,
* BEGIN CP 18/05/2009
         lv_tel       TYPE adr2-tel_number,
         lv_fax       TYPE adr3-fax_number,
         lv_email     TYPE adr6-smtp_addr.

  FIELD-SYMBOLS: <fs_adr2>      TYPE dd_adr2,
                 <fs_adr3>      TYPE dd_adr3,
                 <fs_adr6>      TYPE dd_adr6,
                 <fs_ruoli>     TYPE t_ruoli_bp.

  CONSTANTS: lc_1 TYPE c VALUE'1'.

* END CP 18/05/2009

  CLEAR: lv_acapo_0a, lv_acapo_0d, lv_tel, lv_email, lv_fax.

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

  CLEAR lv_rag_soc.
  READ TABLE gt_zorg TRANSPORTING NO FIELDS WITH KEY z_val_par = <fs_but000>-bu_group.
  IF sy-subrc IS INITIAL.

    CONCATENATE <fs_but000>-name_org1
                <fs_but000>-name_org2
                <fs_but000>-name_org3
                <fs_but000>-name_org4
                INTO lv_rag_soc.

  ELSE.

    READ TABLE gt_zepo TRANSPORTING NO FIELDS WITH KEY z_val_par = <fs_but000>-bu_group.

    IF sy-subrc IS INITIAL.

      CONCATENATE <fs_but000>-name_grp1
                  <fs_but000>-name_grp2
                  INTO lv_rag_soc SEPARATED BY space.

    ELSE.

      CONCATENATE <fs_but000>-mc_name1
                  <fs_but000>-mc_name2
                  INTO lv_rag_soc SEPARATED BY space.

    ENDIF.

  ENDIF.

  " Begin G.Mele 12/11/2008
  CLEAR wa_bp_settore.
  READ TABLE i_bp_settore INTO wa_bp_settore
   WITH KEY partner = <fs_but000>-partner
    BINARY SEARCH.

  " End G.Mele 12/11/2008

  CLEAR wa_bp_addonbp.
  READ TABLE i_bp_addonbp INTO wa_bp_addonbp
   WITH KEY partner = <fs_but000>-partner
    BINARY SEARCH.

  CLEAR: lv_null_0000, lv_resto.
  CALL FUNCTION 'CRM_SVY_DB_CONVERT_HEX2STRING'
    EXPORTING
      x = '0000'
    IMPORTING
      s = lv_null_0000.

  SPLIT <fs_but000>-bpext AT lv_null_0000 INTO <fs_but000>-bpext lv_resto.

* BEGIN CP 18/05/2009
  READ TABLE i_adr2 ASSIGNING <fs_adr2>
    WITH KEY addrnumber = <fs_but000>-addrcomm
             r3_user    = lc_1.
  IF sy-subrc IS INITIAL.
*   Telefono
    lv_tel = <fs_adr2>-tel_number.
  ENDIF.

  READ TABLE i_adr6 ASSIGNING <fs_adr6>
    WITH KEY addrnumber = <fs_but000>-addrcomm.
  IF sy-subrc IS INITIAL.
*   Email
    lv_email = <fs_adr6>-smtp_addr.
  ENDIF.

  READ TABLE i_adr3 ASSIGNING <fs_adr3>
    WITH KEY addrnumber = <fs_but000>-addrcomm.
  IF sy-subrc IS INITIAL.
* fax
    lv_fax = <fs_adr3>-fax_number.
  ENDIF.

  CLEAR lv_utente.

  READ TABLE i_ruoli_bp ASSIGNING <fs_ruoli> WITH KEY partner = <fs_but000>-partner
  BINARY SEARCH.
  IF sy-subrc IS INITIAL.
    lv_utente = <fs_ruoli>-ruolo.
  ENDIF.

* END CP 18/05/2009
  CONCATENATE <fs_but000>-partner
              <fs_but000>-bpext
              <fs_but000>-type
              <fs_but000>-bpkind
              <fs_but000>-bu_group
              <fs_but000>-bu_sort1
              <fs_but000>-bu_sort2
              wa_crmm-attrib_10
              <fs_but000>-zzfrazionari
              lv_rag_soc
              <fs_but000>-zzruolovendi0001 " G.Mele 12/11/2008
              wa_bp_settore-id_settore_1   " G.Mele 12/11/2008
              wa_bp_settore-id_settore_2   " G.Mele 12/11/2008
              wa_bp_settore-id_settore_3   " G.Mele 12/11/2008
              <fs_but000>-zzzclmkt_id      " G.Mele 12/11/2008
              <fs_but000>-xdele            " P.Ferabecoli 28/11/2008
              lv_email                     "ADD CP 18/05/2009
              lv_tel                       "ADD CP 18/05/2009
              lv_fax
              <fs_but000>-zzarea
              wa_bp_addonbp-id_fascia_num_di
              wa_bp_addonbp-n_sedi
              wa_bp_addonbp-m_fatturato
              lv_utente
              <fs_but000>-zzfiliale
       INTO va_file SEPARATED BY ca_sym.

  REPLACE ALL OCCURRENCES OF lv_acapo_0d IN va_file WITH space.
  REPLACE ALL OCCURRENCES OF lv_acapo_0a IN va_file WITH space.

  TRANSFER va_file TO va_filename.

  IF sy-subrc EQ 0.
    CONCATENATE <fs_but000>-partner text-001
    INTO va_logvalue SEPARATED BY ca_sym.
  ELSE.
    CONCATENATE wa_but000-partner text-003
    INTO va_logvalue SEPARATED BY ca_sym.
  ENDIF.

  TRANSFER va_logvalue TO va_filelog.

ENDFORM.                    " data_to_file

*&---------------------------------------------------------------------*
*&      Form  get_file_name
*&---------------------------------------------------------------------*
*       Get physical file path
*----------------------------------------------------------------------*
FORM get_file_name  CHANGING p_file  TYPE filename-fileintern
                             p_fname TYPE string .

  DATA: lv_file TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      client           = sy-mandt
      logical_filename = p_file
      operating_system = sy-opsys
      parameter_1      = sy-datum
      parameter_2      = p_ind
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-011.
  ENDIF.

  IF p_ind IS INITIAL.

    lv_len = STRLEN( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.
  ELSE.

    p_fname = lv_file.

  ENDIF.

  CLEAR p_file.

ENDFORM.                    " get_file_name

*&---------------------------------------------------------------------*
*&      Form  initialize
*&---------------------------------------------------------------------*
*       Initialize internal tables and variables
*----------------------------------------------------------------------*
FORM initialize.

  REFRESH: i_but000,
           gr_zebp,
           gt_zorg,
           gt_zepo,
           i_adr2,
           i_adr6,
           gr_agr_name,
           i_utenti_estratti.

  CLEAR:   wa_tbtco,
           wa_but000,
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

  PERFORM get_file_name CHANGING p_file
                                 va_filename.
*  va_filename = va_filelog.
*  CLEAR va_filelog.
  PERFORM get_file_name CHANGING p_filog
                                 va_filelog.

  OPEN DATASET va_filename FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-010.
  ENDIF.

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF NOT sy-subrc IS INITIAL.
    MESSAGE e208(00) WITH text-010.
  ENDIF.

ENDFORM.                    " open_files

*&---------------------------------------------------------------------*
*&      Form  full
*&---------------------------------------------------------------------*
*       In case radio button Full is selected
*----------------------------------------------------------------------*
FORM full.

  DATA: lr_xdele TYPE RANGE OF but000-xdele,
        lr_xdele_line LIKE LINE OF lr_xdele.

  IF NOT p_arch IS INITIAL.

    lr_xdele_line-sign    = ca_i.
    lr_xdele_line-option  = ca_eq.
    lr_xdele_line-low     = ca_x.
    APPEND lr_xdele_line TO lr_xdele.

  ELSEIF p_xdele IS INITIAL.

    lr_xdele_line-sign    = ca_i.
    lr_xdele_line-option  = ca_eq.
    lr_xdele_line-low     = space.
    APPEND lr_xdele_line TO lr_xdele.

  ENDIF.

  REFRESH i_but000.
  SELECT  partner
          type
          bpkind
          bu_group
          bpext                                         "#EC CI_NOFIELD
          bu_sort1
          bu_sort2
          xdele "P.Ferabecoli 28/11/2008
          zzruolovendi0001
          zzarea
          zzfiliale
          zzfrazionari
          zzzclmkt_id
          name_org1
          name_org2
          name_org3
          name_org4
          name_grp1
          name_grp2
          mc_name1
          mc_name2
          crdat
          crtim
          chdat
          chtim
          partner_guid
          addrcomm     "ADD CP 18/05/2009
    FROM but000
    INTO TABLE i_but000
    PACKAGE SIZE p_pac
           WHERE partner  IN s_bp
             AND bu_group IN gr_zebp    " RF ADD 03/02/2009
             AND xdele    IN lr_xdele.

*   -- Estrazione Ruoli Utente
    PERFORM f_estrai_ruoli.

    PERFORM processing.

  ENDSELECT.

ENDFORM.                    " full

*&---------------------------------------------------------------------*
*&      Form  delta
*&---------------------------------------------------------------------*
*       In case radio button Delta is selected
*----------------------------------------------------------------------*
FORM delta.

  DATA: lt_users          TYPE STANDARD TABLE OF t_hrp1001,
        lt_bp             TYPE STANDARD TABLE OF t_hrp1001,
        lt_sobid          TYPE STANDARD TABLE OF hrp1001-sobid,
        lv_sobid          TYPE hrp1001-sobid,
        lt_partner        TYPE STANDARD TABLE OF but000-partner,
        lv_partner        TYPE but000-partner,
        ls_ruoli          TYPE t_ruoli_bp.

  FIELD-SYMBOLS: <fs_bp>    TYPE t_hrp1001,
                 <fs_users> TYPE t_hrp1001.

* -- Estrazione Date_to e Time_to
* ----------------------------------------------------------
  CLEAR : va_enddate,va_endtime.
  SELECT   sdlstrtdt sdlstrttm
    UP TO 1 ROWS
    FROM tbtco
    INTO  (va_enddate, va_endtime)
    WHERE jobname EQ ca_job
      AND status  EQ ca_r.
  ENDSELECT.

  IF sy-subrc NE 0.
    MESSAGE e398(00) WITH text-004 text-005 text-006 space.
  ENDIF.

  CLEAR va_chtim.
  va_chtim = va_endtime.
* ----------------------------------------------------------

* -- Calcolo Date_From e Time_From
* ----------------------------------------------------------
  IF NOT ( p_date IS INITIAL OR p_time IS INITIAL ).
    va_date = p_date.
    va_time = p_time.
  ELSE.
    SELECT jobname status sdlstrtdt sdlstrttm
      FROM tbtco
      INTO TABLE i_tbtcoo
      WHERE
        jobname = ca_job AND
        status = ca_f.

    IF sy-subrc NE 0.
      MESSAGE e398(00) WITH text-007 text-008 text-009 space.
    ENDIF.

    SORT i_tbtcoo BY date_to DESCENDING
                     time_to DESCENDING.

*   Calculate maximum
    READ TABLE i_tbtcoo INTO wa_tbtco INDEX 1.
    IF sy-subrc IS INITIAL.
      " SC 29/08/2008 Mod inizio
      va_date = wa_tbtco-date_to.
      va_time = wa_tbtco-time_to.
      " SC 29/08/2008 Mod Fine
    ENDIF.

  ENDIF.
* ----------------------------------------------------------

* -- Estrazione BP
* ----------------------------------------------------------
  SELECT  partner
          type
          bpkind
          bu_group
          bpext                                         "#EC CI_NOFIELD
          bu_sort1
          bu_sort2
          xdele "P.Ferabecoli 28/11/2008
          zzruolovendi0001
          zzarea
          zzfiliale
          zzfrazionari
          zzzclmkt_id
          name_org1
          name_org2
          name_org3
          name_org4
          name_grp1
          name_grp2
          mc_name1
          mc_name2
          crdat
          crtim
          chdat
          chtim
          partner_guid
          addrcomm     "ADD CP 18/05/2009
    FROM but000
    INTO TABLE i_but000
    PACKAGE SIZE p_pac
    WHERE (
              chusr NOT IN gr_chusr
              AND
              (
                 ( crdat EQ va_date AND crdat NE va_enddate AND crtim GE va_time )
              OR ( crdat EQ va_date AND crdat EQ va_enddate AND crtim GE va_time  AND crtim LT va_chtim )
              OR ( crdat EQ va_enddate  AND crdat NE va_date AND crtim LT va_chtim )
              OR ( crdat GT va_date AND crdat LT va_enddate )
              OR ( chdat EQ va_date AND chdat NE va_enddate AND chtim GE va_time  )
              OR ( chdat EQ va_date AND chdat EQ va_enddate AND chtim GE va_time AND chtim LT va_chtim )
              OR ( chdat EQ va_enddate  AND chdat NE va_date AND chtim LT va_chtim )
              OR ( chdat GT va_date AND chdat LT va_enddate )
              )
          ) " BP modificati non da MIGR_USER fra DATE_FROM e DATE_TO
          OR
          (
              chusr IN gr_chusr
              AND
              crusr IN gr_chusr
              AND
              (
                ( crdat EQ va_date AND crdat NE va_enddate AND crtim GE va_time )
                OR ( crdat EQ va_date AND crdat EQ va_enddate AND crtim GE va_time  AND crtim LT va_chtim )
                OR ( crdat EQ va_enddate  AND crdat NE va_date AND crtim LT va_chtim )
                OR ( crdat GT va_date AND crdat LT va_enddate )
              )
              AND
              (
                 ( chdat EQ va_date AND chdat NE va_enddate AND chtim GE va_time  )
                OR ( chdat EQ va_date AND chdat EQ va_enddate AND chtim GE va_time AND chtim LT va_chtim )
                OR ( chdat EQ va_enddate  AND chdat NE va_date AND chtim LT va_chtim )
                OR ( chdat GT va_date AND chdat LT va_enddate )
              )
          ). " BP creati e modificati da MIGR_USER fra DATE_FROM e DATE_TO

*   -- Estrazione Ruoli Utente
    PERFORM f_estrai_ruoli.

    PERFORM processing.

  ENDSELECT.
* ----------------------------------------------------------

* -- Estrazione Utenti con Ruolo modificato
* ----------------------------------------------------------
  SORT i_utenti_estratti.
  SELECT agr_name uname FROM agr_users INTO TABLE i_utenti
    PACKAGE SIZE p_pac
    WHERE agr_name IN gr_agr_name
      AND to_dat   GE sy-datum
      AND ( ( change_dat GT va_date AND change_dat LT va_enddate )
       OR ( change_dat EQ va_date AND change_dat NE va_enddate AND change_tim GE va_time )
       OR ( change_dat NE va_date AND change_dat EQ va_enddate AND change_tim LE va_chtim )
       OR ( change_dat EQ va_date AND change_dat EQ va_enddate AND change_tim LE va_chtim AND change_tim GE va_time ) ).

    REFRESH lt_sobid.
    SORT i_utenti BY user.
    LOOP AT i_utenti ASSIGNING <fs_utenti>.

      READ TABLE i_utenti_estratti TRANSPORTING NO FIELDS BINARY SEARCH
      WITH KEY table_line = <fs_utenti>-user.

      CHECK NOT sy-subrc IS INITIAL.
      CLEAR lv_sobid.
      lv_sobid = <fs_utenti>-user.
      APPEND lv_sobid TO lt_sobid.

    ENDLOOP.

    CHECK NOT lt_sobid[] IS INITIAL.

    REFRESH lt_users.
    SELECT objid sobid FROM hrp1001 INTO TABLE lt_users
      FOR ALL ENTRIES IN lt_sobid
        WHERE begda LE sy-datum
          AND endda GE sy-datum
          AND sclas EQ ca_us
          AND sobid EQ lt_sobid-table_line.
    SORT lt_users BY objid.

    CHECK NOT lt_users[] IS INITIAL.

    REFRESH: lt_bp, i_ruoli_bp.
    SELECT objid sobid FROM hrp1001 INTO TABLE lt_bp
      FOR ALL ENTRIES IN lt_users
      WHERE objid EQ lt_users-objid
        AND begda LE sy-datum
        AND endda GE sy-datum
        AND sclas EQ ca_bp.

    SORT lt_bp BY sobid.
    DELETE ADJACENT DUPLICATES FROM lt_bp COMPARING sobid.
    REFRESH lt_partner.
    LOOP AT lt_bp ASSIGNING <fs_bp>.
      CLEAR lv_partner.
      lv_partner = <fs_bp>-sobid.
      APPEND lv_partner TO lt_partner.

      CLEAR ls_ruoli.
      READ TABLE lt_users ASSIGNING <fs_users> WITH KEY objid = <fs_bp>-objid
      BINARY SEARCH.
      CHECK sy-subrc IS INITIAL.

      READ TABLE i_utenti ASSIGNING <fs_utenti> WITH KEY user = <fs_users>-sobid
      BINARY SEARCH.
      CHECK sy-subrc IS INITIAL.

      ls_ruoli-partner = <fs_bp>-sobid.
      ls_ruoli-ruolo = <fs_utenti>-ruolo.
      APPEND ls_ruoli TO i_ruoli_bp.

    ENDLOOP.
    SORT i_ruoli_bp BY partner.

    CHECK NOT lt_partner[] IS INITIAL.

    REFRESH i_but000.
    SELECT  partner
            type
            bpkind
            bu_group
            bpext
            bu_sort1
            bu_sort2
            xdele
            zzruolovendi0001
            zzarea
            zzfiliale
            zzfrazionari
            zzzclmkt_id
            name_org1
            name_org2
            name_org3
            name_org4
            name_grp1
            name_grp2
            mc_name1
            mc_name2
            crdat
            crtim
            chdat
            chtim
            partner_guid
            addrcomm     "ADD CP 18/05/2009
      FROM but000
      INTO TABLE i_but000
      FOR ALL ENTRIES IN lt_partner
      WHERE partner EQ lt_partner-table_line.

    PERFORM processing.

  ENDSELECT.
* ----------------------------------------------------------

ENDFORM.                    " delta

*&---------------------------------------------------------------------*
*&      Form  Processing
*&---------------------------------------------------------------------*
FORM processing.
  DATA i_but000_tmp LIKE i_but000.

  IF NOT i_but000 IS INITIAL.
    SELECT partner_guid attrib_10
      FROM crmm_but_frg0041
      INTO TABLE i_crmm
      FOR ALL ENTRIES IN  i_but000
      WHERE partner_guid = i_but000-partner_guid.

* estrazione parametri zca_addonbp
    SELECT partner id_fascia_num_di n_sedi m_fatturato
       FROM zca_addonbp
         INTO TABLE i_bp_addonbp
        FOR ALL ENTRIES IN i_but000
          WHERE partner EQ i_but000-partner.

    "   Begin G.Mele 12/11/2008
    REFRESH i_bp_settore.
    SELECT partner id_settore_1 id_settore_2 id_settore_3
       FROM zca_bp_settore
         INTO TABLE i_bp_settore
        FOR ALL ENTRIES IN i_but000
          WHERE partner EQ i_but000-partner.
    "    End G.Mele 12/11/2008
*   BEGIN CP 18/05/2009
    i_but000_tmp[] = i_but000[].
    SORT i_but000_tmp BY addrcomm.
    DELETE ADJACENT DUPLICATES FROM i_but000_tmp COMPARING addrcomm.

    SELECT addrnumber tel_number r3_user
      FROM adr2
      INTO TABLE i_adr2
      FOR ALL ENTRIES IN i_but000_tmp
      WHERE addrnumber EQ i_but000_tmp-addrcomm.

    SELECT addrnumber fax_number
      FROM adr3
      INTO TABLE i_adr3
      FOR ALL ENTRIES IN i_but000_tmp
      WHERE addrnumber EQ i_but000_tmp-addrcomm.

    SELECT addrnumber smtp_addr
      FROM adr6
      INTO TABLE i_adr6
      FOR ALL ENTRIES IN i_but000_tmp
      WHERE addrnumber EQ i_but000_tmp-addrcomm.
*   END CP 18/05/2009

  ENDIF.

  SORT : i_crmm       BY partner_guid,
         i_bp_settore BY partner.

  LOOP AT i_but000 ASSIGNING <fs_but000>.
    CLEAR wa_crmm.
    READ TABLE i_crmm INTO wa_crmm
      WITH KEY partner_guid = <fs_but000>-partner_guid
      BINARY SEARCH.
    PERFORM data_to_file.
  ENDLOOP.

  REFRESH i_but000.

ENDFORM.                    " Processing
*&---------------------------------------------------------------------*
*&      Form  f_leggi_param
*&---------------------------------------------------------------------*
*     Estrazione Parametri da ZCA_PARAM
*----------------------------------------------------------------------*
FORM f_leggi_param.

  CONSTANTS: lc_appl       TYPE zca_param-z_appl  VALUE 'ZCAE_EDWHAE_BP',
             lc_user_migr1 TYPE zca_param-z_group VALUE 'MIG1',
             lc_zorg       TYPE zca_param-z_group VALUE 'ZORG',
             lc_zepo       TYPE zca_param-z_group VALUE 'ZEPO'.

  DATA: lt_param          TYPE zca_param_t,
        ls_chusr          LIKE LINE OF gr_chusr,
        lr_agr_name_line  LIKE LINE OF gr_agr_name.

  FIELD-SYMBOLS: <fs_param> TYPE zca_param.

  PERFORM f_read_group_param USING  lc_appl
                                    lc_zorg
                          CHANGING  gt_zorg.

  PERFORM f_read_group_param USING  lc_appl
                                    lc_zepo
                          CHANGING  gt_zepo.

* Inizio Modifica AG 27.10.2009 10:25:47
  REFRESH lt_param.
  PERFORM f_read_group_param USING  lc_appl
                                    lc_user_migr1
                          CHANGING  lt_param.

* Costruttore del range per la select sulla BUT000
  CLEAR ls_chusr.
  ls_chusr-sign = ca_i.
  ls_chusr-option = ca_eq.
  LOOP AT lt_param ASSIGNING <fs_param>.
    CLEAR ls_chusr-low.
    ls_chusr-low = <fs_param>-z_val_par.
    APPEND ls_chusr TO gr_chusr.
  ENDLOOP.
* Fine   Modifica AG 27.10.2009 10:25:47

  CLEAR lr_agr_name_line.
  lr_agr_name_line-sign = ca_i.
  lr_agr_name_line-option = ca_cp.
  lr_agr_name_line-low = ca_zc.
  APPEND lr_agr_name_line TO gr_agr_name.

ENDFORM.                    " f_leggi_param
*&---------------------------------------------------------------------*
*&      Form  f_read_group_param
*&---------------------------------------------------------------------*
*    Estrazione Gruppo Parametri da ZCA_PARAM
*----------------------------------------------------------------------*
FORM f_read_group_param  USING    p_applicazione TYPE zca_param-z_appl
                                  p_group        TYPE zca_param-z_group
                         CHANGING pt_param       TYPE zca_param_t.

  DATA lt_return TYPE bapiret2_t.

  REFRESH: lt_return, pt_param.

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = p_group
      i_z_appl = p_applicazione
    TABLES
      param    = pt_param
      return   = lt_return.

ENDFORM.                    " f_read_group_param
*&---------------------------------------------------------------------*
*&      Form  f_estrai_ruoli
*&---------------------------------------------------------------------*
*   Estrazione Ruoli Utente
*----------------------------------------------------------------------*
FORM f_estrai_ruoli.

  DATA: lt_users          TYPE STANDARD TABLE OF t_hrp1001,
        lt_bp             TYPE STANDARD TABLE OF t_hrp1001,
        lt_partner        TYPE STANDARD TABLE OF hrp1001-sobid,
        lt_user_uname     TYPE STANDARD TABLE OF agr_users-uname,
        lt_agr_users      TYPE STANDARD TABLE OF dd_agr_users,
        lv_sobid          TYPE hrp1001-sobid,
        lv_uname          TYPE agr_users-uname,
        ls_ruoli          TYPE t_ruoli_bp.

  FIELD-SYMBOLS: <fs_users>     TYPE t_hrp1001,
                 <fs_bp>        TYPE t_hrp1001,
                 <fs_agr_users> TYPE dd_agr_users.

  REFRESH i_ruoli_bp.

  LOOP AT i_but000 ASSIGNING <fs_but000>.
    CLEAR lv_sobid.
    lv_sobid = <fs_but000>-partner.
    APPEND lv_sobid TO lt_partner.
  ENDLOOP.

  CHECK NOT i_but000[] IS INITIAL.

  REFRESH lt_bp.
  SELECT objid sobid FROM hrp1001 INTO TABLE lt_bp
    FOR ALL ENTRIES IN lt_partner
    WHERE begda LE sy-datum
      AND endda GE sy-datum
      AND sclas EQ ca_bp
      AND sobid EQ lt_partner-table_line.
  SORT lt_bp BY sobid.

  CHECK NOT lt_bp[] IS INITIAL.

  REFRESH lt_users.
  SELECT objid sobid FROM hrp1001 INTO TABLE lt_users
    FOR ALL ENTRIES IN lt_bp
      WHERE objid EQ lt_bp-objid
        AND begda LE sy-datum
        AND endda GE sy-datum
        AND sclas EQ ca_us.
  SORT lt_users BY objid.

  LOOP AT lt_users ASSIGNING <fs_users>.
    CLEAR lv_uname.
    lv_uname = <fs_users>-sobid.
    APPEND lv_uname TO lt_user_uname.
  ENDLOOP.

  SELECT agr_name
         uname
         change_dat
         change_tim
    FROM agr_users INTO TABLE lt_agr_users
    FOR ALL ENTRIES IN lt_user_uname
    WHERE agr_name IN gr_agr_name
      AND uname    EQ lt_user_uname-table_line
      AND to_dat   GE sy-datum.
  SORT lt_agr_users BY uname.

  LOOP AT i_but000 ASSIGNING <fs_but000>.
    ls_ruoli-partner = <fs_but000>-partner.

    READ TABLE lt_bp ASSIGNING <fs_bp> WITH KEY sobid = <fs_but000>-partner
    BINARY SEARCH.
    CHECK sy-subrc IS INITIAL.

    READ TABLE lt_users ASSIGNING <fs_users> WITH KEY objid = <fs_bp>-objid
    BINARY SEARCH.
    CHECK sy-subrc IS INITIAL.

    READ TABLE lt_agr_users ASSIGNING <fs_agr_users> WITH KEY uname = <fs_users>-sobid
    BINARY SEARCH.
    CHECK sy-subrc IS INITIAL.

    ls_ruoli-ruolo = <fs_agr_users>-agr_name.
    APPEND ls_ruoli TO i_ruoli_bp.

*   -- Nel caso Delta tengo memoria dei record estratti
    IF NOT rb_delta IS INITIAL.
      IF    ( <fs_agr_users>-change_dat GT va_date AND <fs_agr_users>-change_dat LT va_enddate )
        OR  ( <fs_agr_users>-change_dat EQ va_date AND <fs_agr_users>-change_dat NE va_enddate AND <fs_agr_users>-change_tim GE va_time )
        OR  ( <fs_agr_users>-change_dat NE va_date AND <fs_agr_users>-change_dat EQ va_enddate AND <fs_agr_users>-change_tim LE va_chtim )
        OR  ( <fs_agr_users>-change_dat EQ va_date AND <fs_agr_users>-change_dat EQ va_enddate AND <fs_agr_users>-change_tim LE va_chtim AND <fs_agr_users>-change_tim GE va_time ).
        CLEAR lv_uname.
        lv_uname = <fs_agr_users>-uname.
        APPEND lv_uname TO i_utenti_estratti.
      ENDIF.
    ENDIF.

  ENDLOOP.
  SORT i_ruoli_bp BY partner.

ENDFORM.                    " f_estrai_ruoli

*Text elements
*----------------------------------------------------------
* 001 estrazione BP avvenuta con successo
* 003 not successful
* 004 Impossibile determinare la data attuale.
* 005 Eseguire il programma in background
* 006 in un job chiamato ZCAE_EDWHAE_BP
* 007 Impossibile determinare la data iniziale
* 008 Eseguire il programma in modalità
* 009 full oppure specificare una data iniziale
* 010 Impossibile aprire il file in scrittura
* 011 File Logico Errato


*Selection texts
*----------------------------------------------------------
* P_DATE         Date From
* P_FILE         File Output Database BP
* P_FILOG         File Log Database BP
* P_PAC         Package
* P_TIME         Time From
* RB_DELTA         Delta
* RB_FULL         Full


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
