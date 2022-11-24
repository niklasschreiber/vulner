*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_BP_INC
*&---------------------------------------------------------------------*
*
* Data declaration for report ZCAE_EDWHAE_BP
*
TABLES: but000.

TYPES: BEGIN OF dd_but000,
        partner           TYPE but000-partner,
        type              TYPE but000-type,
        bpkind            TYPE but000-bpkind,
        bu_group          TYPE but000-bu_group,
        bpext             TYPE but000-bpext,
        bu_sort1          TYPE but000-bu_sort1,
        bu_sort2          TYPE but000-bu_sort2,
        xdele             TYPE but000-xdele, "P.Ferabecoli 28/11/2008
        zzruolovendi0001  TYPE but000-zzruolovendi0001, "G.Mele 12/11/2008
        zzarea            TYPE but000-zzarea,
        zzfiliale         TYPE but000-zzfiliale,
        zzfrazionari      TYPE but000-zzfrazionari,
        zzzclmkt_id       TYPE but000-zzzclmkt_id,      "G.Mele 12/11/2008
** SC mod inizio
        name_org1         TYPE but000-name_org1,
        name_org2         TYPE but000-name_org2,
        name_org3         TYPE but000-name_org3,
        name_org4         TYPE but000-name_org4,
**sc mod fine
        name_grp1         TYPE but000-name_grp1,
        name_grp2         TYPE but000-name_grp2,
        mc_name1          TYPE but000-mc_name1,
        mc_name2          TYPE but000-mc_name2,
        crdat             TYPE but000-crdat,
        crtim             TYPE but000-crtim,
        chdat             TYPE but000-chdat,
        chtim             TYPE but000-chtim,
        partner_guid      TYPE but000-partner_guid,
        addrcomm          TYPE but000-addrcomm,     "ADD CP 18/05/2009
      END OF dd_but000.

*********************************
TYPES: BEGIN OF dd_agruser,
        uname          TYPE agr_users-uname,
      END OF dd_agruser.
*********************************

TYPES: BEGIN OF dd_tbtco,
        jobname TYPE tbtco-jobname,
        status TYPE tbtco-status,
        date_to TYPE tbtco-sdlstrtdt,
        time_to TYPE tbtco-sdlstrttm,
       END OF dd_tbtco.

TYPES: BEGIN OF dd_crmm_but_frg0041,
        partner_guid TYPE crmm_but_frg0041-partner_guid,
        attrib_10 TYPE crmm_but_frg0041-attrib_10,
       END OF dd_crmm_but_frg0041.

" Begin G.Mele 12/11/2008
TYPES: BEGIN OF dd_bp_settore,
        partner      TYPE zca_bp_settore-partner,
        id_settore_1 TYPE zca_bp_settore-id_settore_1,
        id_settore_2 TYPE zca_bp_settore-id_settore_2,
        id_settore_3 TYPE zca_bp_settore-id_settore_3,
      END OF dd_bp_settore.
" End G.Mele 12/11/2008

TYPES: BEGIN OF dd_bp_addonbp,
        partner           TYPE zca_addonbp-partner,
        id_fascia_num_di  TYPE zca_addonbp-id_fascia_num_di,
        n_sedi            TYPE zca_addonbp-n_sedi,
        m_fatturato       TYPE zca_addonbp-m_fatturato,
      END OF dd_bp_addonbp.

* inserimento ruoli
TYPES: BEGIN OF dd_agr_users,
        agr_name       TYPE agr_users-agr_name,
        uname          TYPE agr_users-uname,
        change_dat     TYPE agr_users-change_dat,
        change_tim     TYPE agr_users-change_tim,
      END OF dd_agr_users.

* inserimento ruoli
TYPES: BEGIN OF t_ruoli_bp,
        partner     TYPE but000-partner,
        ruolo       TYPE agr_users-agr_name,
      END OF t_ruoli_bp.

* inserimento ruoli
TYPES: BEGIN OF t_ruoli_user,
        ruolo    TYPE agr_users-agr_name,
        user     TYPE agr_users-uname,
      END OF t_ruoli_user.

* BEGIN CP 18/05/2009
TYPES: BEGIN OF dd_adr2,
        addrnumber TYPE adr2-addrnumber,
        tel_number TYPE adr2-tel_number,
        r3_user    TYPE adr2-r3_user,
      END OF dd_adr2.

TYPES: BEGIN OF dd_adr6,
        addrnumber TYPE adr6-addrnumber,
        smtp_addr TYPE adr6-smtp_addr,
      END OF dd_adr6.
* END CP 18/05/2009

TYPES: BEGIN OF dd_adr3,
        addrnumber TYPE adr3-addrnumber,
        fax_number TYPE adr3-fax_number,
      END OF dd_adr3.

TYPES: BEGIN OF t_hrp1001,
        objid TYPE hrp1001-objid,
        sobid TYPE hrp1001-sobid,
      END OF t_hrp1001.

DATA: i_bp_settore        TYPE TABLE OF dd_bp_settore, " G.Mele 12/11/2008
      i_bp_addonbp        TYPE TABLE OF dd_bp_addonbp,
      wa_bp_settore       TYPE dd_bp_settore,         " G.Mele 12/11/2008
      wa_bp_addonbp       TYPE dd_bp_addonbp,
      i_ruoli_bp          TYPE STANDARD TABLE OF t_ruoli_bp,
      i_utenti_estratti   TYPE STANDARD TABLE OF agr_users-uname,
      i_utenti            TYPE STANDARD TABLE OF t_ruoli_user,
      i_crmm              TYPE TABLE OF dd_crmm_but_frg0041,
      wa_crmm             TYPE dd_crmm_but_frg0041,
      wa_return           TYPE TABLE OF bapiret2,
      i_tbtcoo            TYPE TABLE OF dd_tbtco,
      wa_tbtco            TYPE dd_tbtco,
      i_adr2              TYPE STANDARD TABLE OF dd_adr2,  "ADD CP 18/05/2009
      i_adr6              TYPE STANDARD TABLE OF dd_adr6, "ADD CP 18/05/2009
      i_adr3              TYPE STANDARD TABLE OF dd_adr3,
      gr_zebp             TYPE RANGE OF but000-bu_group,
      gr_agr_name         TYPE RANGE OF agr_users-agr_name,
      gt_zorg             TYPE zca_param_t,
      gt_zepo             TYPE zca_param_t,
      gr_chusr            TYPE RANGE OF but000-chusr.

DATA: i_but000  TYPE TABLE OF dd_but000,
      wa_but000 TYPE dd_but000.

DATA: va_date TYPE sy-datum,
      va_time TYPE sy-uzeit.

DATA : va_enddate TYPE tbtco-sdlstrtdt,
       va_endtime TYPE tbtco-sdlstrttm,
       va_chtim   TYPE but000-chtim.

DATA: va_filelog  TYPE string ,
      va_filename TYPE string,
      va_logvalue TYPE string,
      va_file     TYPE string.

FIELD-SYMBOLS : <fs_but000>     LIKE LINE OF i_but000,
                <fs_utenti>     TYPE t_ruoli_user.

CONSTANTS: ca_job(14) VALUE 'ZCAE_EDWHAE_BP',
           ca_x(1)    VALUE 'X',
           ca_r(1)    VALUE 'R',
           ca_f(1)    VALUE 'F',
           ca_i(1)    VALUE 'I',
           ca_cp(2)   VALUE 'CP',
           ca_eq(2)   VALUE 'EQ',
           ca_bp(2)   VALUE 'BP',
           ca_us(2)   VALUE 'US',
           ca_zc(4)   TYPE c VALUE 'ZC_*',
           ca_sym(1)  VALUE '|'.

SELECTION-SCREEN BEGIN OF BLOCK b1.
PARAMETERS: rb_delta RADIOBUTTON GROUP rg  DEFAULT 'X'.
PARAMETERS: rb_full  RADIOBUTTON GROUP rg .
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2.
PARAMETERS: p_date TYPE sy-datum,
            p_time TYPE sy-uzeit,
            p_file TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMOUT001_EDWHAE_BP',
            p_filog TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMLOG001_EDWHAE_BP',
            p_ind(9) TYPE c,
            p_pac TYPE i OBLIGATORY,
            p_xdele TYPE c AS CHECKBOX DEFAULT ca_x,
            p_arch  TYPE c AS CHECKBOX.

SELECT-OPTIONS: s_bp  FOR but000-partner.
SELECTION-SCREEN END OF BLOCK b2.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
