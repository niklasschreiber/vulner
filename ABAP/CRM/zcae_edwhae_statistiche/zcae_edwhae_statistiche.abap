*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_STATISTICHE
*&
*&---------------------------------------------------------------------*
*&  Programmatore       : Luca Manfreda                                *
*                                                                      *
*   Descrizione breve   : Legge dati statistici degli accessi a sistema*
*                         Scrive su un file che andrà estratto verso   *
*                         EDWH                                         *
*                                                                      *
*                                                                      *
* La function utilizzata da questo programma, è quella utilizzata      *
* dalla transazione ST03N a partire dalla release ECC 6.00.            *
*&                                                                     *
*&---------------------------------------------------------------------*

report ZCAE_EDWHAE_STATISTICHE
 no standard page heading line-size 132 line-count 65.

tables: swncglaggusertcode,
        SWNCGLAGGUSERWORKLOAD.       "dati transazioni / report

parameters:  p_fout     TYPE filename-fileintern DEFAULT 'ZCRMOUT001_EDWHAE_STAT' OBLIGATORY,
             p_ind(9)   TYPE c,
             p_data     like sy-datum,
             P_peri     like SAPWLACCTP-PERIODTYPE.

data: w_inizio_mese   like sy-datum,
      W_PERiodo       like SAPWLACCTP-PERIODTYPE,
      wa_return       TYPE TABLE OF BAPIRET2,
      w_letti         type i,
      va_ts(8)        TYPE c,
      va_fileout(255) TYPE c,
      lv_recout       TYPE string,
      ca_sep(1)       TYPE c      VALUE '|',
      COD_BP_USER     TYPE but000-partner,
      w_progressivo(4) type n.

* tabella interna con tracciato tcode
data:  i_sapwluenti type standard table of swncglaggusertcode,
      i_USERWORKLOAD type standard table of SWNCGLAGGUSERWORKLOAD.


* tabella per scrittura ordinata nel DB
data: begin of i_ZZWL_M  occurs 0,
      USERID type SAPWLUTACC,
end of i_ZZWL_M.

data w_systemid type swncsysid.


start-of-selection.

  va_ts = sy-datum.

* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts p_ind
                        CHANGING va_fileout.

* Apre i file di output e log
  PERFORM apri_file.

* Estrazioni dal DB
  PERFORM estrazioni.

* Chiude i file di output e log
  PERFORM chiudi_file.

end-of-selection.

*eject.
*&---------------------------------------------------------------------*
*&      Form  f_utente_trx
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
form f_utente_trx.

* elimina informazioni doppie
  sort i_sapwluenti by entry_id
                       account .
  delete adjacent duplicates from i_sapwluenti comparing entry_id
                                                         account .

  loop at i_USERWORKLOAD into SWNCGLAGGUSERWORKLOAD.

    move: SWNCGLAGGUSERWORKLOAD-username to i_ZZWL_M-userid.

    append: i_ZZWL_M.
    clear i_ZZWL_M.

  endloop.

* ordina per inserimento in tabella
  sort i_ZZWL_M.
  delete ADJACENT DUPLICATES FROM i_ZZWL_M.

  loop at i_ZZWL_M.

    if  i_ZZWL_M-USERID na '.' and
        i_ZZWL_M-USERID na '_' and
        i_ZZWL_M-USERID na '-' and
        i_ZZWL_M-USERID(3) ne 'SAP' and
*        i_ZZWL_M-USERID(3) ne 'REA' and
        i_ZZWL_M-USERID(3) ne 'WEB'.

      CALL FUNCTION 'Z_CA_COD_EMPLOYEE_FROM_USER'
        EXPORTING
          UTENTE             = i_ZZWL_M-USERID
       IMPORTING
         COD_CLIENTE        = COD_BP_USER
*   PARTNER_GUID       =
  TABLES
    RETURN             = wa_return.


      if COD_BP_USER is not INITIAL.
        CONCATENATE COD_BP_USER
                    w_inizio_mese
*                    p_data
*                  P_peri
                INTO lv_recout SEPARATED BY ca_sep.

        TRANSFER lv_recout TO va_fileout.
      endif.
      clear COD_BP_USER.
      CLEAR wa_return.
    endif.

  endloop.

endform.                    " f_utente_trx
*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_FOUT  text
*      -->P_VA_TS  text
*      <--P_VA_FILEOUT  text
*----------------------------------------------------------------------*
FORM recupera_file USING p_logic TYPE filename-fileintern
                         p_param TYPE c
                         p_indi  Type c
                         CHANGING p_fname TYPE c.

  DATA: lv_file TYPE string,
        lv_file2 TYPE string,
        lv_len  TYPE i,
        lv_len2 TYPE i.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = p_logic
      parameter_1      = p_param
      parameter_2      = p_indi
    IMPORTING
      file_name        = lv_file
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  IF sy-subrc IS NOT INITIAL.
    MESSAGE e398(00) WITH text-e02 p_logic text-e03 space.
  ENDIF.


  IF p_indi IS INITIAL.

    lv_len = STRLEN( lv_file ).
    lv_len = lv_len - 5.
    lv_len2 = lv_len + 1.

    CONCATENATE lv_file(lv_len) lv_file+lv_len2 INTO p_fname.

  ELSE.

    p_fname = lv_file.

  ENDIF.

ENDFORM.                    " recupera_file
*&---------------------------------------------------------------------*
*&      Form  apri_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM apri_file .

  OPEN DATASET va_fileout FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

ENDFORM.                    " apri_file
*&---------------------------------------------------------------------*
*&      Form  estrazioni
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM estrazioni .

* imposta inizio mese elaborazione - se vuoto quello a video
  if p_data is initial.
    move sy-datum to w_inizio_mese.  "attuale per elaboraz. job
  else.
    move p_data to w_inizio_mese.
  endif.

  move sy-sysid to w_systemid.
  move p_peri to W_PERiodo.

* Funzione di lettura dati statistici
  call function 'SWNC_GET_WORKLOAD_STATISTIC'
    exporting
*   SELECT_SYSTEM                =                     "non usare
      systemid                   = w_systemid          "sistema in uso
      instance                   = 'TOTAL'             "istanza
      periodtype                 = W_PERiodo           "settimanali
      periodstrt                 = w_inizio_mese       "settimana da leggere
*   SUMMARY_ONLY                 = ' '                 "non usare
    importing
*   TASKTYPE                     =
*   TASKTIMES                    =
*   TIMES                        =
*   DBPROCS                      =
*   EXTSYSTEM                    =
*   TCDET                        =
*   FRONTEND                     =
*   MEMORY                       =
*   SPOOL                        =
*   SPOOLACT                     =
*   TABLEREC                     =
      usertcode                  = i_sapwluenti
      USERWORKLOAD               = i_USERWORKLOAD
*   RFCCLNT                      =
*   RFCCLNTDEST                  =
*   RFCSRVR                      =
*   RFCSRVRDEST                  =
*   ASTAT                        =
*   HITLIST_DATABASE             =
*   HITLIST_RESPTIME             =
*   HITLIST_ASTAT_DB             =
*   HITLIST_ASTAT_RESPTIME       =
*   COMPONENTS_HIERARCHY         =
*   ORG_UNITS                    =
*   DBCON                        =
*   WEBC                         =
*   WEBCD                        =
*   WEBS                         =
*   WEBSD                        =
*   VMC                          =
   exceptions
     unknown_periodtype          = 1
     no_data_found               = 2
     unknown_error               = 3
     others                      = 4
            .
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.


  if sy-subrc <> 0.
    MESSAGE I000(FB) WITH 'Nessun dato statistico per i valori inseriti'.
  endif.

  perform f_utente_trx.

ENDFORM.                    " estrazioni
*&---------------------------------------------------------------------*
*&      Form  chiudi_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM chiudi_file .

  CLOSE DATASET: va_fileout.

ENDFORM.                    " chiudi_file


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
