*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_REL_INC
*&---------------------------------------------------------------------*
*
* Data declaration for report ZCAE_EDWHAE_REL
*
TABLES: but050.

TYPES: BEGIN OF dd_but050,
        relnr TYPE but050-relnr,
        partner1 TYPE but050-partner1,
        partner2 TYPE but050-partner2,
        date_to TYPE but050-date_to,
        date_from TYPE but050-date_from,
        reltyp TYPE but050-reltyp,
        crdat TYPE but050-crdat,
        crtim TYPE but050-crtim,
        chdat TYPE but050-chdat,
        chtim TYPE but050-chtim,
       END OF dd_but050.

" Inizio AS 06.09.2012
TYPES: BEGIN OF t_relimpr_web,
        relnr      TYPE zca_relimpr_web-relnr,
        user_id    TYPE zca_relimpr_web-user_id,
        ric_forte  TYPE zca_relimpr_web-ric_forte,
      END OF t_relimpr_web.
DATA: gt_relimpr_web TYPE STANDARD TABLE OF t_relimpr_web.
" Fine AS 06.09.2012

TYPES: BEGIN OF dd_tbtco,
        jobname TYPE tbtco-jobname,
        status  TYPE tbtco-status,
        date_to TYPE tbtco-sdlstrtdt,
        time_to TYPE tbtco-sdlstrttm,
       END OF dd_tbtco.
DATA: i_tbtco TYPE TABLE OF dd_tbtco,
       i_tbtcoo TYPE TABLE OF dd_tbtco,
       wa_tbtcoo TYPE dd_tbtco,
       wa_tbtco TYPE dd_tbtco.
DATA: i_but050 TYPE TABLE OF dd_but050,
      wa_but050 TYPE dd_but050.
DATA: va_date TYPE sy-datum,
      va_time TYPE sy-uzeit.

DATA : va_enddate TYPE tbtco-sdlstrtdt,
       va_endtime TYPE tbtco-sdlstrttm,
       va_chtim   TYPE but050-chtim.

DATA: va_filelog TYPE string ,
      p_fileimport TYPE string.
DATA: va_filename TYPE string,
*      va_logfile TYPE filename-fileintern,
      va_logvalue TYPE string.
DATA: va_file TYPE string.

CONSTANTS: ca_job(15) VALUE 'ZCAE_EDWHAE_REL',
           ca_f(1) VALUE 'F',
           ca_r(1) VALUE 'R',
           ca_pipe(1) VALUE '|',
           ca_x(1) VALUE 'X',
           ca_date(8) VALUE '00000000',
           ca_time(6) VALUE '000000'.

FIELD-SYMBOLS <fs_but050> LIKE LINE OF i_but050.


*SELECTION-SCREEN BEGIN OF BLOCK b1.
*PARAMETERS: rb_delta RADIOBUTTON GROUP rg DEFAULT 'X'.
*PARAMETERS: rb_full  RADIOBUTTON GROUP rg.
*SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2.
PARAMETERS:
*           p_date TYPE sy-datum,
*           p_time TYPE sy-uzeit,
            p_file TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMOUT001_EDWHAE_REL',
            p_filog TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMLOG001_EDWHAE_REL',
            p_pac TYPE i OBLIGATORY.
SELECT-OPTIONS: o_rel FOR but050-reltyp.
SELECTION-SCREEN END OF BLOCK b2.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
