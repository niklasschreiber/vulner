*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_SORG_MULTI
*&
*&---------------------------------------------------------------------*
*& Creato da: Luca Manfreda
*&
*& Data Creazione: 10/11/2008
*&
*& ID: EDW_011 Interfaccia anagrafica Codici sorgenti multisede
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_sorg_multi.

TABLES: ZCA_SORGMULTI.


* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_CODSORMULT' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_CODSORMULT' OBLIGATORY.

SELECT-OPTIONS: s_sis FOR ZCA_SORGMULTI-Z_COD_SIS_SORG.
SELECTION-SCREEN END OF BLOCK b1.

* COSTANTI
CONSTANTS: ca_x(1)    TYPE c VALUE 'X',
           ca_sep(1)  TYPE c VALUE '|'.


* VARIABILI
DATA: va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      va_filelog(255) TYPE c.

* STRUTTURE
DATA: BEGIN OF tb_Codsormult occurs 0,
PARTNER          TYPE ZCA_SORGMULTI-PARTNER,
Z_COD_CL_SORG    TYPE ZCA_SORGMULTI-Z_COD_CL_SORG,
Z_COD_SIS_SORG   TYPE ZCA_SORGMULTI-Z_COD_SIS_SORG,
DATUM            TYPE ZCA_SORGMULTI-DATUM,
UZEIT            TYPE ZCA_SORGMULTI-UZEIT,
UNAME            TYPE ZCA_SORGMULTI-UNAME,
       END OF tb_Codsormult.


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


  LOOP AT tb_Codsormult.
*   Trasferimento al file di out
    CLEAR va_recout.
    CONCATENATE tb_Codsormult-PARTNER
                tb_Codsormult-Z_COD_CL_SORG
                tb_Codsormult-Z_COD_SIS_SORG
                tb_Codsormult-DATUM
                tb_Codsormult-UZEIT
                tb_Codsormult-UNAME

                INTO va_recout SEPARATED BY ca_sep.
    TRANSFER va_recout TO va_fileout.

*   Trasferimento al file di log
    CLEAR va_reclog.
    CONCATENATE tb_Codsormult-PARTNER
                tb_Codsormult-Z_COD_CL_SORG
                tb_Codsormult-Z_COD_SIS_SORG
                tb_Codsormult-DATUM
                tb_Codsormult-UZEIT
                tb_Codsormult-UNAME
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

if s_sis[] is initial.

    select ZS~PARTNER ZS~Z_COD_CL_SORG ZS~Z_COD_SIS_SORG ZS~DATUM ZS~UZEIT ZS~UNAME
      into corresponding fields of table tb_Codsormult
      from ZCA_SORGMULTI as ZS.

else.

    select ZS~PARTNER ZS~Z_COD_CL_SORG ZS~Z_COD_SIS_SORG ZS~DATUM ZS~UZEIT ZS~UNAME
      into corresponding fields of table tb_Codsormult
      from ZCA_SORGMULTI as ZS
      WHERE Z_COD_SIS_SORG in s_sis.
endif.
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
