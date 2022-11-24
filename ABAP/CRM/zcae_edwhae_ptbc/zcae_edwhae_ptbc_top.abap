*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PTBC_TOP
*&---------------------------------------------------------------------*

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X',
           r_full  RADIOBUTTON GROUP gr1,

           p_date_f TYPE sy-datum,

           p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_PTBC' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_PTBC' OBLIGATORY,

           p_psize TYPE i DEFAULT 1000 OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

* COSTANTI
CONSTANTS: ca_x(1)    TYPE c VALUE 'X',
           ca_sep(1)  TYPE c VALUE '|',

           ca_jobname TYPE tbtco-jobname VALUE 'ZCAE_EDWHAE_PTBC',
           ca_f       TYPE tbtco-status  VALUE 'F',
           ca_r       TYPE tbtco-status  VALUE 'R'.

* TIPI
TYPES: BEGIN OF t_tbtco,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         sdlstrtdt TYPE tbtco-sdlstrtdt,
         sdlstrttm TYPE tbtco-sdlstrttm,
         status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES: BEGIN OF t_zca_ptbc,
         z_ptb_card      TYPE zca_ptbc-z_ptb_card,
         z_type_card     TYPE zca_ptbc-z_type_card,
         z_bp            TYPE zca_ptbc-z_bp,
         z_date_i        TYPE zca_ptbc-z_date_i,
         z_date_f        TYPE zca_ptbc-z_date_f,
         z_date_request  TYPE zca_ptbc-z_date_request,
         z_date_sent     TYPE zca_ptbc-z_date_sent,
         z_date_req_sent TYPE zca_ptbc-z_date_req_sent,
         z_attiva        TYPE zca_ptbc-z_attiva,

         z_data_crea     TYPE zca_ptbc-z_data_crea,
         z_data_mod      TYPE zca_ptbc-z_data_mod,

       END OF t_zca_ptbc.

* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c.

* STRUTTURE
DATA: st_tbtco_t TYPE t_tbtco,
      st_tbtco_f TYPE t_tbtco.

* TABELLE
DATA: i_tbtco    TYPE STANDARD TABLE OF t_tbtco,
      i_zca_ptbc TYPE STANDARD TABLE OF t_zca_ptbc.

* FIELD-SYMBOLS
FIELD-SYMBOLS <fs_zca_ptbc> TYPE t_zca_ptbc.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
