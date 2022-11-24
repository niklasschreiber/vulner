*----------------------------------------------------------------------*
***INCLUDE ZCAE_EDWHAE_PREVENTIVO_BDM_TOP .
*----------------------------------------------------------------------*
************************************************************************
* ID:     BDM_02_37_01
* Autore:	Aurora Galeone
* Data:   26.10.2011
* Descr.:	Dichiarazioni Globali
************************************************************************

* Tipi
 TYPES: BEGIN OF tp_file_out,
*          tipo_elaborazione   TYPE char1,
          id_preventivo_crm   TYPE char10,
          id_preventivo_glm   TYPE char10,
          id_cliente_crm      TYPE char10,
          cod_fiscale         TYPE char20,
          cod_partita_iva     TYPE char20,
          ragione_sociale     TYPE char35,
          nome_referente      TYPE char40,
          cognome_referente   TYPE char40,
          telefono_referente  TYPE char30,
          cellulare_referente TYPE char30,
          mail_referente      TYPE c LENGTH 241,
          ruolo_referente     TYPE c LENGTH 60,
          frazionario         TYPE char5,
          product_id          TYPE c LENGTH 40,
          importo             TYPE c LENGTH 13,
* start VPM 01.02.2012 inserimento nuovi campi
          tipologia_tasso	     TYPE c LENGTH 40,
          numero_rate          TYPE c LENGTH 40,
          durata_finanziamento TYPE c LENGTH 40,
          periodicita          TYPE c LENGTH 40,
          convenzione          TYPE c LENGTH 40,
          tipologia_piano      TYPE c LENGTH 40,
          presenza_cpi         TYPE c LENGTH 1,
          polizza_scop_inc     TYPE c LENGTH 1,
          apertura_cc          TYPE c LENGTH 1,
          data_creazione       TYPE c LENGTH 8,
* end VPM 01.02.2012 inserimento nuovi campi
        END OF tp_file_out.

 TYPES: BEGIN OF tp_prev,
         id_preventivo TYPE zca_bdm_prev_dat-id_preventivo,
       END OF tp_prev.

 TYPES: BEGIN OF tp_tbtco,
          jobname   TYPE tbtco-jobname,
          jobcount  TYPE tbtco-jobcount,
          sdlstrtdt TYPE tbtco-sdlstrtdt,
          sdlstrttm TYPE tbtco-sdlstrttm,
          status    TYPE tbtco-status,
        END OF tp_tbtco.

 TYPES: BEGIN OF tp_zca_bdm_prev_bp,
          partner       TYPE zca_bdm_prev_bp-partner,
          id_preventivo TYPE zca_bdm_prev_bp-id_preventivo,
        END OF tp_zca_bdm_prev_bp.

 TYPES: tp_prev_t TYPE STANDARD TABLE OF tp_prev.

* Costanti
 CONSTANTS: gc_date         TYPE char6          VALUE 'P_DATE',
            gc_f            TYPE tbtco-status   VALUE 'F',
            gc_i            TYPE c              VALUE 'I',
            gc_true         TYPE c              VALUE 'X',
            gc_sep          TYPE c              VALUE '|',
            gc_jobname      TYPE tbtco-jobname  VALUE 'ZCAE_EDWHAE_PREVENTIVO_BDM',
            gc_appl         TYPE zappl          VALUE 'BDM_CREA_PREVENTIVO',
            gc_fraz         TYPE char11         VALUE 'FRAZIONARIO',
* INIZIO MODIFICA AS DEL 28.11.2011
            gc_product_id(10) TYPE c            VALUE 'PRODUCT_ID',
            gc_importo(7)     TYPE c            VALUE 'IMPORTO'.
* FINE MODIFICA AS DEL 28.11.2011

* Dichiarazioni variabili globali
 DATA gv_file TYPE string.


*start VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo
 DATA: lv_id_contratto TYPE zca_bdm_prev_bp-id_contratto,
       lv_uname        TYPE crmd_orderadm_h-created_by,
       lv_utente       TYPE syst-uname,
       lv_cod_cli      TYPE zca_ptbc-z_bp,
       lv_partner_guid TYPE but000-partner_guid,
       lv_cod_bp       TYPE but000-partner,
       lv_cod_fraz     TYPE but000-zzfrazionari,
       lt_return       TYPE bapiret2 OCCURS 0,
       lv_guid         TYPE crmd_orderadm_h-guid.
*end VPM 31.01.2012 - il preventivo si recupera tramite utenza e non tramite preventivo

* Parametri di selezione
 SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE text-t01.
 SELECTION-SCREEN SKIP 1.

 PARAMETER: "r_full   RADIOBUTTON GROUP gr1 DEFAULT 'X', "Add AS 28.11.2011
            r_full   RADIOBUTTON GROUP gr1 DEFAULT 'X' USER-COMMAND radio, "Add AS 28.11.2011
            r_delta  RADIOBUTTON GROUP gr1,
            p_date   TYPE sy-datum,
*            p_fout   TYPE char255 LOWER CASE DEFAULT '/IFR/CRM/BDM/ZCAE_EDWHAE_PREVENTIVO_BDM_OUT',
            p_fout   TYPE char255 LOWER CASE DEFAULT '/IFR/CRM/outbound/inv/ASC/ZCAE_EDWHAE_PREVENTIVO_OUT',
            p_psize  TYPE i DEFAULT 150 OBLIGATORY,
            p_ind(8) TYPE c.

 SELECTION-SCREEN END OF BLOCK a1.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
