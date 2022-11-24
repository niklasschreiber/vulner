*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_TIPOLOGICHE_TOP
*&---------------------------------------------------------------------*

* TABELLE
TABLES: tb004t,
        tb002,
        t005t,            " Denominazione dei paesi
        tb027t,           " Stato civile BP: testi
        t005u,            " Imposte: codice provincia: testi
        adrcity,          " Località postali
        adrcityt,         " Località postali (testi estesi)
        crmc_proc_type_t,
        ztb00005xwkl9t,
        zca_settorigav,
        crmc_attr10_t,
        zca_pot_comm,
        crmc_act_cat_t,
        tbz9a,
        zcrmc_eew_0404_t,
        zcrmc_eew_0401_t,
        zcrmc_eew_0403_t,
        zcrmc_eew_0407_t,
        zcrmc_eew_0406_t,
        scpriot,
        zcrmc_eew_0402_t,
        qpct,
        zca_domini,
        zcrmc_eew_1001_t,
        crmc_subob_cat_t,
        tj30t,
        crmc_partner_ft,
        crmc_item_type_t,
        zcrmc_eew_1002_t,
        zca_fasciadipgav,
        zcrmc_eew_0204_t,
        ztb0000rv2kwjt,
        zcrmc_eew_0202_t,
        ztb0000q0nfd3t,
        ztb0000672y1qt,
        zcrmc_eew_1305_t,
        zcrmc_eew_1401_t,
        zcrmc_eew_1402_t,
        zcrmc_eew_1403_t,
        zcrmc_eew_1404_t,
        zcrmc_eew_1308_t,
        ztb0000wriri7t,
        ztb0000aenyd2t,
        zcrmc_eew_1306_t,
        tsad5t,
        tsad2t,
        dd07t,
***  ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB ***
        zcrmc_eew_2001_t,
        zcrmc_eew_2002_t,
        zcrmc_eew_2003_t,
        zcrmc_eew_2004_t,
        zcrmc_eew_2005_t,
        zcrmc_eew_2006_t,
        zcrmc_eew_2007_t,
        zcrmc_eew_2009_t,
        zcrmc_eew_2101_t,
        zcrmc_eew_1307_t,
***  ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB ***
        ztb00006u3rk5t,
        ztb00009h1w82t,
*** gestione tipologiche BDM
        zca_param_ext,
        " -- Inizio modifiche AO del 10.12.2013   - CWDK993286
        zca_target_est,
        zcrmc_eew_1502_t,
        ztb0000m0pihat,
        tb020,
        " -- Fine modifiche AO del 10.12.2013   - CWDK993286
        zca_ateco_mcc,   " modifiche RU 05.07.2018

        zfa_reinoltro_up. "RU 13.09.2019 10:52:32

* PARAMETRI DI INPUT
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.

PARAMETER: p_fout TYPE filename-fileintern
             DEFAULT 'ZCRMOUT001_EDWHAE_TIPOLOGICHE' OBLIGATORY,
           p_flog TYPE filename-fileintern
             DEFAULT 'ZCRMLOG001_EDWHAE_TIPOLOGICHE' OBLIGATORY.

SELECT-OPTIONS: p_cod FOR zca_domini-cod_dom.

SELECTION-SCREEN END OF BLOCK b1.

* TABELLE di appoggio
DATA: BEGIN OF output OCCURS 0,
        codice(5)   TYPE c,
        valore(60)  TYPE c,
*      descrizione(255) TYPE c," Mod AG 21.09.2012
        descrizione TYPE string, " Mod AG 21.09.2012
      END OF output.

* FILE
DATA: BEGIN OF file_ou,
        codice(5)        TYPE c,
        valore(60)       TYPE c,
        descrizione(255) TYPE c,
      END OF file_ou.

DATA: BEGIN OF file_log,
        codice(5)      TYPE c,
        messaggio(255) TYPE c,
      END OF file_log.

* COSTANTI
CONSTANTS: ca_x(1)   TYPE c VALUE 'X',
           ca_sep(1) TYPE c VALUE '|'.

* VARIABILI
DATA: va_ts(8)           TYPE c,
      va_fileout(255)    TYPE c,
      va_filelog(255)    TYPE c,
      va_city_name       TYPE adrcityt-city_name,
      va_cod_belfiore(4) TYPE c,
      va_region          TYPE adrcity-region.

DATA: lv_cod_ateco(10)   TYPE c,
      lv_desc_ateco(255) TYPE c,
      lv_mcc_int(4)      TYPE c,
      lv_mcc_pbt(4)      TYPE c.

"RU 13.09.2019 10:52:54
DATA: lv_cod_rein(3)    TYPE c,
      lv_desc_rein(255) TYPE c.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
