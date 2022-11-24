*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_ATTR_BP_TOP
*&---------------------------------------------------------------------*

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE sy-datum,
           p_time_f TYPE sy-uzeit,      " DEFAULT '      ', DEL KLP 24/09/08

           p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_ATTR_BP' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_ATTR_BP' OBLIGATORY,

           p_psize TYPE i DEFAULT 1000 OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

* COSTANTI
CONSTANTS: ca_x(1)   TYPE c VALUE 'X',
           ca_sep(1) TYPE c VALUE '|',

           ca_jobname TYPE tbtco-jobname VALUE 'ZCAE_EDWHAE_ATTR_BP',
           ca_r       TYPE tbtco-status  VALUE 'R',
           ca_f       TYPE tbtco-status  VALUE 'F'.

* DICHIARAZIONI GLOBALI

* Tipi
TYPES: BEGIN OF t_zca_addonbp,
        partner          TYPE zca_addonbp-partner,
        trattamentodati1 TYPE zca_addonbp-trattamentodati1,
        trattamentodati2 TYPE zca_addonbp-trattamentodati2,
        trattamentodati3 TYPE zca_addonbp-trattamentodati3,
        revoca_consenso  TYPE zca_addonbp-revoca_consenso,
        data_revoca      TYPE zca_addonbp-data_revoca,
        pot_comm         TYPE zca_addonbp-pot_comm,
        datum            TYPE zca_addonbp-datum,
        uzeit            TYPE zca_addonbp-uzeit,
       END OF t_zca_addonbp.

TYPES: BEGIN OF t_tbtco,
         jobname TYPE tbtco-jobname,
         jobcount TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status TYPE tbtco-status,
       END OF t_tbtco.

* Variabili
DATA: va_fileout(255) TYPE c,
      va_filelog(255) TYPE c,
      va_ts(8)        TYPE c.

* Strutture
DATA: st_tbtco_t TYPE t_tbtco,
      st_tbtco_f TYPE t_tbtco.

* Tabelle
DATA: i_zca_addonbp TYPE STANDARD TABLE OF t_zca_addonbp,
      i_tbtco       TYPE STANDARD TABLE OF t_tbtco.

* Field-symbols
FIELD-SYMBOLS <fs_zca_addonbp> TYPE t_zca_addonbp.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
