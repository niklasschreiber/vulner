*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_CL_MKT
*&
*&---------------------------------------------------------------------*
*& Creato da: Luca Manfreda
*&
*& Data Creazione: 10/11/2008
*&
*& ID: EDW_010 Interfaccia anagrafica Cliente marketing
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_cl_mkt.

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_CLMKT' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_CLMKT' OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b1.

* COSTANTI
CONSTANTS: ca_x(1)    TYPE c VALUE 'X',
           ca_sep(1)  TYPE c VALUE '|'.


* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c.

* STRUTTURE
DATA: BEGIN OF tb_CLMKT1 occurs 0,
  CLMKT_ID    TYPE ZCA_ANCLIMKT-CLMKT_ID,
  DESC_ID     TYPE ZCA_ANCLIMKT-DESC_ID,
  SIC_ID      TYPE ZCA_ANCLIMKT-SIC_ID,
  DESC_SIC    TYPE ZCA_ANCODSIC-DESC_SIC,
  SETTMKT_ID  TYPE ZCA_ANCODSIC-SETTMKT_ID,
       END OF tb_CLMKT1.

DATA: BEGIN OF tb_CLMKT2 occurs 0,
  CLMKT_ID    TYPE ZCA_ANCLIMKT-CLMKT_ID,
  DESC_ID     TYPE ZCA_ANCLIMKT-DESC_ID,
  SIC_ID      TYPE ZCA_ANCLIMKT-SIC_ID,
  DESC_SIC    TYPE ZCA_ANCODSIC-DESC_SIC,
  SETTMKT_ID  TYPE ZCA_ANCODSIC-SETTMKT_ID,
  DESC_SETT   TYPE ZCA_ANSETTMKT-DESC_SETT,
  SEGMKT_ID   TYPE ZCA_ANSETTMKT-SEGMKT_ID,
       END OF tb_CLMKT2.

DATA: BEGIN OF tb_CLMKT occurs 0,
  CLMKT_ID    TYPE ZCA_ANCLIMKT-CLMKT_ID,
  DESC_ID     TYPE ZCA_ANCLIMKT-DESC_ID,
  SIC_ID      TYPE ZCA_ANCLIMKT-SIC_ID,
  DESC_SIC    TYPE ZCA_ANCODSIC-DESC_SIC,
  SETTMKT_ID  TYPE ZCA_ANCODSIC-SETTMKT_ID,
  DESC_SETT   TYPE ZCA_ANSETTMKT-DESC_SETT,
  SEGMKT_ID   TYPE ZCA_ANSETTMKT-SEGMKT_ID,
  DESC_SEG    TYPE ZCA_ANSEGMKT-DESC_SEG ,
       END OF tb_CLMKT.

* TABELLE
Tables: ZCA_ANCODSIC,
      ZCA_ANSEGMKT,
      ZCA_ANCLIMKT,
      ZCA_ANSETTMKT.

START-OF-SELECTION.

va_ts = sy-datum.
* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

* Apre i file di output e log
  PERFORM apri_file.

* Estrazioni dal DB
  PERFORM estrazioni.

* Chiude i file di output e log
  PERFORM chiudi_file.
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       Recupera i file fisici dai file logici
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                   CHANGING p_fname TYPE c.

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

*   Estrazioni FULL
      PERFORM select_full.

ENDFORM.                    " estrazioni


*&---------------------------------------------------------------------*
*&      Form  elabora
*&---------------------------------------------------------------------*
*       Trasferisce su file i record estratti
*----------------------------------------------------------------------*
FORM elabora .
  DATA: va_recout TYPE string,
        va_reclog TYPE string.

  LOOP AT tb_CLMKT.
*   Trasferimento al file di out
    CLEAR va_recout.
    CONCATENATE tb_CLMKT-CLMKT_ID
                tb_CLMKT-DESC_ID
                tb_CLMKT-SIC_ID
                tb_CLMKT-DESC_SIC
                tb_CLMKT-SETTMKT_ID
                tb_CLMKT-DESC_SETT
                tb_CLMKT-SEGMKT_ID
                tb_CLMKT-DESC_SEG
                INTO va_recout SEPARATED BY ca_sep.
    TRANSFER va_recout TO va_fileout.

*   Trasferimento al file di log
    CLEAR va_reclog.
    CONCATENATE tb_CLMKT-CLMKT_ID
                tb_CLMKT-DESC_ID
                tb_CLMKT-SIC_ID
                tb_CLMKT-DESC_SIC
                tb_CLMKT-SETTMKT_ID
                tb_CLMKT-DESC_SETT
                tb_CLMKT-SEGMKT_ID
                tb_CLMKT-DESC_SEG
                text-l01
                INTO va_reclog SEPARATED BY ca_sep.
    TRANSFER va_reclog TO va_filelog.
  ENDLOOP.
ENDFORM.                    " elabora

*&---------------------------------------------------------------------*
*&      Form  select_full
*&---------------------------------------------------------------------*
*       Selezione della ZCA_PTBC per estrazioni FULL
*----------------------------------------------------------------------*
FORM select_full.

    select ZS~CLMKT_ID ZS~DESC_ID ZS~SIC_ID ZC~DESC_SIC ZC~SETTMKT_ID
      into corresponding fields of table tb_CLMKT1
      from ZCA_ANCLIMKT as ZS
       left outer JOIN  ZCA_ANCODSIC as ZC on ZC~SIC_ID = ZS~SIC_ID.

      loop at tb_CLMKT1.
        select single * from ZCA_ANSETTMKT where SETTMKT_ID = tb_CLMKT1-SETTMKT_ID.
                tb_CLMKT2-CLMKT_ID    = tb_CLMKT1-CLMKT_ID.
                tb_CLMKT2-DESC_ID     = tb_CLMKT1-DESC_ID.
                tb_CLMKT2-SIC_ID      = tb_CLMKT1-SIC_ID.
                tb_CLMKT2-DESC_SIC    = tb_CLMKT1-DESC_SIC.
                tb_CLMKT2-SETTMKT_ID  = tb_CLMKT1-SETTMKT_ID.
                tb_CLMKT2-DESC_SETT   = ZCA_ANSETTMKT-DESC_SETT.
                tb_CLMKT2-SEGMKT_ID   = ZCA_ANSETTMKT-SEGMKT_ID.
                append tb_clmkt2.
                clear ZCA_ANSETTMKT.
        endloop.

      loop at tb_CLMKT2.
        select single * from ZCA_ANSEGMKT where SEGMKT_ID = tb_CLMKT2-SEGMKT_ID.
                tb_CLMKT-CLMKT_ID    = tb_CLMKT2-CLMKT_ID.
                tb_CLMKT-DESC_ID     = tb_CLMKT2-DESC_ID.
                tb_CLMKT-SIC_ID      = tb_CLMKT2-SIC_ID.
                tb_CLMKT-DESC_SIC    = tb_CLMKT2-DESC_SIC.
                tb_CLMKT-SETTMKT_ID  = tb_CLMKT2-SETTMKT_ID.
                tb_CLMKT-DESC_SETT   = tb_CLMKT2-DESC_SETT.
                tb_CLMKT-SEGMKT_ID   = tb_CLMKT2-SEGMKT_ID.
                tb_CLMKT-DESC_SEG    = ZCA_ANSEGMKT-DESC_SEG.
                append tb_clmkt.
                clear ZCA_ANSEGMKT.
        endloop.

*   Trasferisce su file i record estratti
    PERFORM elabora.

ENDFORM.                    " select_full


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
