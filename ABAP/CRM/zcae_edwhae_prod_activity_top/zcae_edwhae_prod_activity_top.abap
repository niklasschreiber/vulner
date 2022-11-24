*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_PROD_ACTIVITY_TOP
*&---------------------------------------------------------------------*

TABLES crmd_orderadm_h.

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-t02 FOR FIELD r_delta .
PARAMETER: r_delta RADIOBUTTON GROUP gr1 DEFAULT 'X' USER-COMMAND finto.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-t03 FOR FIELD r_full.
PARAMETER: r_full RADIOBUTTON GROUP gr1.
SELECTION-SCREEN END OF LINE.

PARAMETER: p_date_f TYPE timestamp                    MODIF ID abc,
           p_fout   TYPE filename-fileintern          DEFAULT 'ZCRMOUT001_EDWHAEPROD_ACTIVITY'  OBLIGATORY,
           p_flog   TYPE filename-fileintern          DEFAULT 'ZCRMLOG001_EDWHAEPROD_ACTIVITY'  OBLIGATORY,
           p_psize  TYPE i                            DEFAULT 150                               OBLIGATORY,
           p_ind(9) TYPE c.

SELECT-OPTIONS: s_proct FOR crmd_orderadm_h-process_type.

SELECTION-SCREEN END OF BLOCK b1.

TYPES: BEGIN OF t_tbtco,
        jobname   TYPE tbtco-jobname,
        jobcount  TYPE tbtco-jobcount,
        sdlstrtdt TYPE tbtco-sdlstrtdt,
        sdlstrttm TYPE tbtco-sdlstrttm,
        status    TYPE tbtco-status,
       END OF t_tbtco.

TYPES: BEGIN OF t_orderadm_h,
        guid          TYPE crmd_orderadm_h-guid,
        object_id     TYPE crmd_orderadm_h-object_id,
        process_type  TYPE crmd_orderadm_h-process_type,
        description   TYPE crmd_orderadm_h-description,
       END OF t_orderadm_h,

       tt_orderadm_h TYPE STANDARD TABLE OF t_orderadm_h.

TYPES: BEGIN OF t_item,
        header         TYPE crmd_orderadm_i-header,
        description    TYPE crmd_orderadm_i-description,
       END OF t_item.

CONSTANTS: gc_eq(2)         TYPE c                    VALUE 'EQ',
           gc_i(1)          TYPE c                    VALUE 'I',
           gc_r(1)          TYPE c                    VALUE 'R',
           gc_f(1)          TYPE c                    VALUE 'F',
           gc_sep(1)        TYPE c                    VALUE '|',
           gc_jobname       TYPE tbtco-jobname        VALUE 'ZCAE_EDWHAE_PROD_ACTIVITY',
           gc_edwa          TYPE zgroup               VALUE 'EDWA',
           gc_appl          TYPE zappl                VALUE 'ZCAE_EDWHAE_ACTIVITY'.

DATA: gv_filelog TYPE string,
      gv_fileout TYPE string,
      gv_date_to TYPE crmd_orderadm_h-created_at.

DATA: gt_orderadm_h TYPE STANDARD TABLE OF t_orderadm_h,
      gt_item       TYPE STANDARD TABLE OF t_item.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
