*----------------------------------------------------------------------*
***INCLUDE ZCAE_EDWHAE_BASE_TOP .
*----------------------------------------------------------------------*

TABLES: but000.


* Parametri di input
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETER: r_full   RADIOBUTTON GROUP gr1,
           r_delta  RADIOBUTTON GROUP gr1 DEFAULT 'X',
           p_data   TYPE dats.
SELECT-OPTIONS: s_bp FOR but000-partner.
PARAMETER: p_f_out  TYPE filename-fileintern DEFAULT '/IFR/CRM/outbound/inv/ASC/ZCRMOUT001_DATIBASE' OBLIGATORY LOWER CASE,
           p_f_err  TYPE filename-fileintern DEFAULT '/IFR/CRM/outbound/err/ZCRMERR001_DATIBASE' OBLIGATORY LOWER CASE,
           p_var    TYPE char9,
           p_pack   TYPE i DEFAULT 1000 OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

* Costanti
CONSTANTS: gc_p_data  TYPE char6         VALUE 'P_DATA',
           gc_prat    TYPE zgroup        VALUE 'PRAT',
           gc_appl    TYPE zappl         VALUE 'ZCAE_EDWHAE_BASE',
           gc_sep1    TYPE c             VALUE '_',
           gc_sep2    TYPE c             VALUE '|',
           gc_i       TYPE c             VALUE 'I',
           gc_gt      TYPE char2         VALUE 'GT',
           gc_ge      TYPE char2         VALUE 'GE',
           gc_eq      TYPE char2         VALUE 'EQ',
           gc_jobname TYPE tbtco-jobname VALUE 'ZCAE_EDWHAE_BASE',
           gc_status  TYPE tbtco-status  VALUE 'F'.

* Tipi
TYPES: tp_zca_reddito_cbas TYPE STANDARD TABLE OF zca_reddito_cbas.

TYPES: BEGIN OF tp_tbtco,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
       END OF tp_tbtco.

TYPES: BEGIN OF tp_order_h,
         guid         TYPE crmd_orderadm_h-guid,
         object_id    TYPE crmd_orderadm_h-object_id,
         process_type TYPE crmd_orderadm_h-process_type,
      END OF tp_order_h.

TYPES: BEGIN OF tp_cust_h,
         guid         TYPE crmd_customer_h-guid,
         zz_numero_cc TYPE crmd_customer_h-zz_numero_cc,
         zz_opzione   TYPE crmd_customer_h-zz_opzione,
      END OF tp_cust_h.

* Tabelle
DATA: gr_prat TYPE RANGE OF crmd_orderadm_h-process_type,
      gr_date TYPE RANGE OF zca_reddito_cbas-chdat.

* Variabili
DATA: gv_fileout(255)  TYPE c,
      gv_fileerr(255)  TYPE c.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
