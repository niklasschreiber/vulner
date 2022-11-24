REPORT zregistroiva_fica
NO STANDARD PAGE HEADING
LINE-SIZE 300
LINE-COUNT 65(3).
   
   
***** DICHIARAZIONE TABELLE
   
   
TABLES: dfkkko,     "Dati testata per documento conto corrente
        dfkkop,     "Posizioni per documento conto corrente
        dfkkopk,    "Posizioni per documento conto corrente
        but000,                        "PC: dati generali I
        but020,                        "PC: indirizzi
        adrc,       "Indirizzi (gestione indirizzi centrale)
        itcpo,
        t007s,                         "Definizione codice IVA
        t001,                          "Società
        konp,                          "Condizioni (posizione)
        zreg_iva ,                     "VALORI CONDIZIONI
        a003,                          "Codice IVA
        dfkkbptaxnum, "Codici fiscale per partner commerciale centrale
   
   
*        zregistroiva,
*        zlog_cliente,
   
   
        zivagg,
        vbrk,
        konv,
        cdhdr,
        cdpos,
        zivadate_el,
        tspat ,   "Testi settore merceologico
   
   
*& Tabelle per range numero e tipo documento - mod. 09/10/2003
   
   
        zcod_var,
        zcod_conto,
        nriv,     "Range di numerazione
        tfk003,
        tfk003b,
        dfkkinvdoc_h,
        zint_regiva,
        zspeso_regiva,
        dfkkinvdoc_s , dfkkinvbill_i.

TYPES: BEGIN OF ty_key,
         exbel TYPE dfkkinvdoc_h-exbel,
         opbel TYPE dfkkinvdoc_i-opbel,
       END OF ty_key.

TYPES: BEGIN OF ty_itab_fica,
         exbel       TYPE  dfkkinvdoc_h-exbel,
         mwskz       TYPE dfkkopk-mwskz,        "Codice IVA
         opbel       TYPE dfkkko-opbel,         "Numero documento
         blart       TYPE dfkkko-blart,
         budat       TYPE dfkkko-budat,         "Data registrazione doc
         gpart       TYPE dfkkop-gpart,         "Codice cliente
         waers       TYPE dfkkop-waers,         "Divisa transazione
         kofiz       TYPE dfkkop-kofiz,         "Caratt. det. conti
         spart       TYPE dfkkop-spart,         "Settore merceologico
         perc(4)     TYPE c,                  "Percentuale IVA
         text1       TYPE t007s-text1,          "Descrizione codice IVA
         bollo_int   TYPE dfkkopk-betrh,    "Importo bollo divisa interna
         bollo_tra   TYPE dfkkopk-betrw,    "Importo bollo divisa transazione
         betrh       TYPE dfkkopk-betrh,        "Importo in divisa interna
         betrw       TYPE dfkkopk-betrw,        "Importo in divisa transazione
         sbeth       TYPE dfkkopk-betrh,       "Importo imposta in divisa interna
         sbetw       TYPE dfkkopk-betrw,        "Importo imposta in divisa trans
         totale      TYPE dfkkopk-betrh,       " Totale in divisa interna
         totale2     TYPE dfkkopk-betrw,      "Totale in divisa transazione
         riten       TYPE dfkkopk-betrw,        "Importo ritenuta
         riten_t     TYPE dfkkopk-betrw,      "Importo ritenuta
         flag_err(1),
       END OF ty_itab_fica.
DATA: gi_split LIKE TABLE OF zfica_split."MEV_106990-ADT 104
DATA: budat_ul2 LIKE sy-datum.
DATA  sw_passato.
DATA  valuta_bollo LIKE konv-waers.
DATA imposta_bollo LIKE konv-kbetr.
DATA  opbel LIKE dfkkko-opbel.
DATA  valore_bollo(16).
DATA  tredici(13).
DATA due(2).
DATA data_max LIKE dfkkop-budat.
DATA  controlla_bollo TYPE c.
DATA  controlla_ritenuta TYPE c.
DATA: my_str(50).
   
   
*& Campo appoggio numero pagina - mod. 09/10/2003
* INIZIO MOD T23880651 02.01.2014 DM
*DATA  w_page(4) TYPE n.
*DATA  w_page_stampa(4) TYPE n.
*DATA  w_page_save(4) TYPE n.
   
   
DATA  w_page(5) TYPE n.
DATA  w_page_stampa(5) TYPE n.
DATA  w_page_save(5) TYPE n.
   
   
* FINE MOD T23880651 02.01.2014 DM
   
   
DATA  sw_prima_volta.
DATA  vn_contx(5) TYPE n.
   
   
*& Campi di appoggio per nuova intestazione - mod. 09/10/2003
   
   
DATA  w_text_tit1(143).
   
   
* INIZIO MOD T23880651 02.01.2014 DM
*DATA: w_text_tit2(14).
   
   
DATA: w_text_tit2(15).
   
   
* FINE MOD T23880651 02.01.2014 DM
   
   
DATA  w_text_tit3(143).
   
   
** Inizio modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
RANGES: p_range FOR dfkkop-mwskz.
   
   
** Fine modifica -  MEV_106990 F-008-004
   
   
DATA:  BEGIN OF w_data,
         w_aa(4),
         w_mm(2),
         w_gg(2),
       END   OF w_data.
DATA  w_testo LIKE zcod_var-cod_testo.
DATA  primo.
DATA:  BEGIN OF itab_conto OCCURS 0,
   
   
*        include structure zcod_conto.
   
   
         sign(1),
         option(2),
         low       LIKE zcod_conto-conto,
         high      LIKE zcod_conto-conto,
       END   OF itab_conto.
DATA  save_flg_att LIKE zcod_var-cod_atti.
DATA  w_data_save  LIKE sy-datum.
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
   
   
DATA  va_ext(4).
DATA  va_idx(100).
DATA  va_string TYPE string.
DATA  va_proced(100) TYPE c.
DATA  va_cnt(6) TYPE n.
DATA  va_cnt_pdf(6) TYPE n.
DATA  va_path(300) TYPE c.
DATA: lt_pdf  LIKE tline OCCURS 0 WITH HEADER LINE,
      l_len   TYPE i,
      lt_docs TYPE docs OCCURS 0 WITH HEADER LINE.
DATA: lt_linecpx TYPE STANDARD TABLE OF tline.
DATA lv_filesize  TYPE i.
   
   
**MEV110408 AV - inizio
   
   
DATA lv_user LIKE tvarvc-low.
   
   
**MEV110408  - fine

   
   
DATA:flag TYPE flag.

DATA: t_zspeso_regiva LIKE zspeso_regiva OCCURS 0 WITH HEADER LINE.
DATA: t_dfkkinvdoc_h LIKE dfkkinvdoc_h OCCURS 0 WITH HEADER LINE.
DATA: t_dfkkinvdoc_i LIKE dfkkinvdoc_i OCCURS 0 WITH HEADER LINE.
DATA: va_invdocno LIKE dfkkinvdoc_h-invdocno.

   
   
*End mod


***** DEFINIZIONI PARAMETRI DI SELEZIONE
*SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
*DATA  cechk_itab.
*PARAMETER flg_att LIKE zcod_var-cod_atti OBLIGATORY  . "CR 15.12.2015 DEFAULT 'B'.
*SELECT-OPTIONS: s_blart  FOR dfkkko-blart NO INTERVALS, "Tipo documento
*                s_budat  FOR dfkkko-budat , " Data documento
*                s_opbel  FOR dfkkko-opbel NO-DISPLAY, "Num. documento
*                s_exbel  FOR dfkkinvdoc_h-exbel,
*                s_fikey  FOR dfkkko-fikey,
*                s_spart  FOR dfkkop-spart,         " Sett. merceologico
*                s_herkf  FOR dfkkko-herkf DEFAULT '77'. "Chiave orig doc
*PARAMETER p_bukrs LIKE dfkkop-bukrs OBLIGATORY.
**                                    DEFAULT 'EPI'.  CR 15.12.2015
*SELECTION-SCREEN END OF BLOCK b1.
*SELECTION-SCREEN SKIP.
*SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-024.
*PARAMETER: p_datare RADIOBUTTON GROUP a DEFAULT 'X'.
*PARAMETER: p_datado RADIOBUTTON GROUP a.
*SELECTION-SCREEN END OF BLOCK b2.
*SELECTION-SCREEN SKIP.
*
*PARAMETER: p_pdf AS CHECKBOX DEFAULT 'X'.
***Start Mod MEV110408 Registri IVA - Gestione files CPX INF XML 14.11.16 ind37or
*PARAMETER: p_cpx as checkbox default 'X'.
**End Mod
*PARAMETER: p_test AS CHECKBOX DEFAULT 'X'.
*PARAMETER: p_spool LIKE usr01-spld OBLIGATORY.
*PARAMETER: p_contr AS CHECKBOX DEFAULT 'X'.
*PARAMETER: p_treg(2) .  "CR 15.12.2015 DEFAULT 'IN'.
*** Inizio modifica 14.05.2015 - MEV_106990 REQ-F-008-004
*PARAMETERS: p_vv AS CHECKBOX DEFAULT 'X'.
*
*** Fine modifica -  MEV_106990 F-008-004
**PARAMETERS: FLG_ATT(1) DEFAULT 'B' OBLIGATORY.
** Inizio modifca - SAPIT 20/11/2006 - estrazione della tabella dei dati
** per esportazione alle funzionionalità di archiviazione per la gestione
** ed emissione dei tabulati attinenti alle normative (Decreto Bersani).
*SELECTION-SCREEN BEGIN OF BLOCK zib WITH FRAME TITLE text-031.
*PARAMETER: p_zib AS CHECKBOX DEFAULT space USER-COMMAND zibfl,
*           p_zib_tr TYPE zib_tipo_registro OBLIGATORY MODIF ID zib
*                        MATCHCODE OBJECT ziv_hp_tipo_registro,
****Begin Pamela Lops 19.06.08 - PTDK909111
*p_tcode LIKE sy-tcode NO-DISPLAY.
****End Pamela Lops 19.06.08 - PTDK909111
*
*SELECTION-SCREEN END OF BLOCK zib.
* Fine modifca - SAPIT 20/11/2006
   
   
RANGES: mod_rs FOR cdhdr-udate.
   
   
*& Range per gestione codice documento - mod. 09/10/2003
   
   
RANGES: r_blart FOR dfkkko-blart,
        r_opbel FOR dfkkko-opbel.
   
   
*****  DEFINIZIONE TABELLE INTERNE
   
   
DATA: BEGIN OF itab OCCURS 0,
        blart       LIKE dfkkko-blart,
        budat       LIKE dfkkko-budat,         "Data registrazione doc
        opbel       LIKE dfkkko-opbel,         "Numero documento
        gpart       LIKE dfkkop-gpart,         "Codice cliente
        waers       LIKE dfkkop-waers,         "Divisa transazione
        kofiz       LIKE dfkkop-kofiz,         "Caratt. det. conti
        spart       LIKE dfkkop-spart,         "Settore merceologico
        mwskz       LIKE dfkkopk-mwskz,        "Codice IVA
        perc(4)     TYPE c,                  "Percentuale IVA
        text1       LIKE t007s-text1,          "Descrizione codice IVA
        bollo_int   LIKE dfkkopk-betrh,    "Importo bollo divisa interna
        bollo_tra   LIKE dfkkopk-betrw,    "Importo bollo divisa transazione
        betrh       LIKE dfkkopk-betrh,        "Importo in divisa interna
        betrw       LIKE dfkkopk-betrw,        "Importo in divisa transazione
        sbeth       LIKE dfkkopk-betrh,       "Importo imposta in divisa interna
        sbetw       LIKE dfkkopk-betrw,        "Importo imposta in divisa trans
        totale      LIKE dfkkopk-betrh,       " Totale in divisa interna
        totale2     LIKE dfkkopk-betrw,      "Totale in divisa transazione
        riten       LIKE dfkkopk-betrw,        "Importo ritenuta
        riten_t     LIKE dfkkopk-betrw,      "Importo ritenuta
        flag_err(1).
DATA: END OF itab.
DATA: BEGIN OF itab1.
        INCLUDE STRUCTURE itab.
DATA: END OF itab1.
DATA: BEGIN OF itab2 OCCURS 0.
        INCLUDE STRUCTURE itab.
DATA: END OF itab2.
DATA: BEGIN OF itab_totali OCCURS 0,
        opbel   LIKE dfkkko-opbel,
        totale  LIKE dfkkopk-betrw,
        totale2 LIKE dfkkopk.
DATA: END OF itab_totali.

DATA: BEGIN OF itab_cliente OCCURS 0,
        opbel      LIKE dfkkop-opbel,
        gpart      LIKE dfkkop-gpart,
        name1      LIKE adrc-name1,
        street     LIKE adrc-street,
        post_code1 LIKE adrc-post_code1,
        city1      LIKE adrc-city1,
        taxnum     LIKE dfkkbptaxnum-taxnum,
        type       LIKE but000-type,
        name_first LIKE but000-name_first,
        name_last  LIKE but000-name_last.
DATA: END OF itab_cliente.

DATA: BEGIN OF itab_modulo,
        blart(2)      TYPE c,
        budat(10)     TYPE c,
        opbel(12)     TYPE c,
        gpart(10)     TYPE c,                "Codice cliente
        waers(5)      TYPE c,                 "Divisa transazione
        kofiz(2)      TYPE c,                 "Caratt. det. conti
        mwskz(2)      TYPE c,                 "Codice IVA
        perc(4)       TYPE c,                  "Percentuale IVA
   
   
*      text1 LIKE t007s-text1,          "Descrizione codice IVA
   
   
        text1(50),
        bollo_int(17) TYPE c,            "Importo bollo divisa interna
        bollo_tra(17) TYPE c,            "Importo bollo divisa transazione
        betrh(17)     TYPE c,                "Importo in divisa interna
        betrw(17)     TYPE c,                "Importo in divisa transazione
        sbeth(17)     TYPE c,     "Importo imposta in divisa interna
        sbetw(17)     TYPE c,                "Importo imposta in divisa trans
        totale(17)    TYPE c,               " Totale in divisa interna
        totale2(17)   TYPE c,              "Totale in divisa transazione
        name1         LIKE itab_cliente-name1,
        totalet(17)   TYPE c,
        riten(17)     TYPE c.                " Importo ritenuta
DATA: END OF itab_modulo.

   
   
* Tabella per aggiornamento Tabella di controllo

   
   
DATA: BEGIN OF itab_save OCCURS 0.
        include structure zivagg.
DATA: END OF itab_save.
   
   
* Tabella per il controllo della numerazione progressiva
   
   
DATA: BEGIN OF itab_num OCCURS 0,
        opbel LIKE itab-opbel.
DATA: END OF itab_num.

   
   
* Tabella per la ritenuta.
   
   
DATA: BEGIN OF itab_rit OCCURS 0,
        opbel LIKE dfkkopk-opbel,
        betrh LIKE dfkkopk-betrh,
        betrw LIKE dfkkopk-betrw.
DATA: END OF itab_rit.

DATA: BEGIN OF itab_bollo OCCURS 0,
        opbel LIKE dfkkopk-opbel,
        mwskz LIKE dfkkopk-mwskz,
        sbash LIKE dfkkopk-sbash,
        sbasw LIKE dfkkopk-sbasw,
        text1 LIKE t007s-text1.
DATA: END OF itab_bollo.

   
   
* Tabella per il riepilogo iva
   
   
DATA: BEGIN OF itab_riepilogo OCCURS 0,
        perc   LIKE itab-perc,
        mwskz  LIKE dfkkopk-mwskz,
   
   
* Inizio modifica 15192674 Descrizione IVA CR PTDK919731 29.03.2010 DM
   
   
        text1  LIKE t007s-text1,
   
   
*      text1(30),
* Fine modifica 15192674 Descrizione IVA CR PTDK919731 29.03.2010 DM
   
   
        impon  LIKE dfkkopk-betrh,
        iva    LIKE dfkkopk-betrh,
        bollo  LIKE dfkkopk-betrh,
        totale LIKE dfkkopk-betrh,
        riten  LIKE dfkkopk-betrh.
DATA: END OF itab_riepilogo.

DATA: BEGIN OF itab_bis OCCURS 0.
        INCLUDE STRUCTURE itab.
DATA: END OF itab_bis.

DATA: BEGIN OF itab_merc OCCURS 0,
        spart  LIKE dfkkop-spart,
        vtext  LIKE tspat-vtext,
        impon  LIKE dfkkopk-betrh,
        iva    LIKE dfkkopk-betrh,
        bollo  LIKE dfkkopk-betrh,
        totale LIKE dfkkopk-betrh,
        riten  LIKE dfkkopk-betrh.
DATA: END OF itab_merc.
   
   
* Modifica del 29/10/2003 Luigi Pacciolla
   
   
DATA  BEGIN OF itab_esente OCCURS 0.
.
        INCLUDE STRUCTURE itab.
DATA  END   OF itab_esente.
DATA: bdcdata LIKE bdcdata OCCURS 0 WITH HEADER LINE.

   
   
***** DEFINIZIONE VARIABILI
   
   
DATA: vn_totale_fattura_int    LIKE dfkkop-betrh.
DATA: vn_totale_fattura_tra    LIKE dfkkop-betrh.
DATA: vn_totale_imponibile LIKE dfkkop-betrh.
DATA: vn_totale_imposte    LIKE dfkkop-sbeth.
DATA: vn_totale_bolli      LIKE dfkkop-sbeth.
DATA: vn_totale_fatture_int LIKE dfkkop-sbeth.
DATA: vn_totale_fatture_tra LIKE dfkkop-sbeth.
DATA: vn_totale_ritenuta LIKE dfkkop-sbeth.
DATA: vn_perc(3) TYPE n.
DATA: vn_cont(5) TYPE n.
DATA: vn_cont2(5) TYPE n.
DATA: va_bollo(10) TYPE c.
DATA: vn_bollo_tot(11) TYPE c.
DATA: va_cliente LIKE dfkkop-gpart.
DATA: va_doc LIKE dfkkop-opbel.
DATA: va_colore TYPE c.
DATA: vn_riga(6) TYPE n.
DATA: va_flag.
DATA: va_tot_imponibile_s(17) TYPE c.
DATA: va_tot_imposte_s(17) TYPE  c.
DATA: va_tot_bolli_s(17) TYPE c.
DATA: va_tot_fatture_int_s(17) TYPE c.
DATA: va_tot_fatture_tra_s(17) TYPE c.
DATA: va_tot_ritenuta_s(17) TYPE c.
DATA: va_tot_imponibile_sr(17) TYPE c.
DATA: va_tot_imposte_sr(17) TYPE  c.
DATA: va_tot_bolli_sr(17) TYPE c.
DATA: va_tot_fatture_int_sr(17) TYPE c.
DATA: va_tot_fatture_tra_sr(17) TYPE c.
DATA: va_tot_ritenuta_sr(17) TYPE c.
DATA: va_flag2.
DATA: vn_cont3(5) TYPE n.
DATA: vn_righe LIKE sy-loopc.
DATA: va_documento_iniziale(12) TYPE c.
DATA: va_documento_finale(12) TYPE c.
DATA: vn_impon_riep LIKE dfkkop-betrh.
DATA: vn_iva_riep LIKE dfkkop-betrh.
DATA: vn_bollo_riep LIKE dfkkop-betrh.
DATA: vn_totale_riep LIKE dfkkop-betrh.
DATA: vn_rit_riep LIKE dfkkop-betrh.
DATA: va_impon_riep(17) TYPE c.
DATA: va_iva_riep(17) TYPE c.
DATA: va_bollo_riep(17) TYPE c.
DATA: va_totale_riep(17) TYPE c.
DATA: va_rit_riep(17) TYPE c.
DATA: wa_data LIKE sy-datum.
DATA: va_impon_riep_s(17) TYPE c.
DATA: va_iva_riep_s(17) TYPE c.
DATA: va_bollo_riep_s(17) TYPE c.
DATA: va_totale_riep_s(17) TYPE c.
DATA: va_rit_riep_s(17) TYPE c.
DATA: va_top.
DATA: app_righe LIKE sy-tabix.
DATA: wa_check(5) TYPE n.
   
   
***** DEFINIZIONE COSTANTI
*data: ca_iva like dfkkopk-kschl value 'MWST'.
*data: ca_bollo like dfkkopk-kschl value 'MWBO'.
*data: ca_lett like dfkkopk-kschl value 'LCIT'.
*data: ca_prezzi like t007s-kalsm value 'TAXIT'.
*data: ca_soc like t001-bukrs value 'EPI'.
*data: ca_hkont like dfkkopk-hkont value '0150502000'.
**************************************sapvarazzi
   
   
DATA: ca_iva LIKE dfkkopk-kschl .
DATA: ca_bollo LIKE dfkkopk-kschl .
DATA: ca_lett LIKE dfkkopk-kschl  .
DATA: ca_prezzi LIKE t007s-kalsm  .
   
   
*data: ca_soc like t001-bukrs .
   
   
DATA: ca_hkont LIKE dfkkopk-hkont .
DATA: wa_err(1).
DATA: t_invdoc_h TYPE TABLE OF dfkkinvdoc_h.
DATA: t_invdoc_i TYPE TABLE OF dfkkinvdoc_i.
DATA: s_invdoc_h TYPE dfkkinvdoc_h.
DATA: s_invdoc_i TYPE dfkkinvdoc_i.
DATA: t_key TYPE TABLE OF ty_key.
DATA: s_key TYPE ty_key.
DATA: t_itab_fica TYPE TABLE OF ty_itab_fica.
DATA: s_itab_fica TYPE ty_itab_fica.
DATA lv_bin_file  TYPE xstring.
   
   
* Modifica Miggiano - gestione modifiche rag. soc.
   
   
CONTEXTS zragsoc.
DATA:    cx_ragsoc TYPE context_zragsoc.

   
   
* VITOLAZZI 10/07/07 C.R. PTDK902442
* MODIFICHE PER STORICIZZAZIONE STAMPE IN PDF

* DICHIARAZIONE DI TAB./STRUTT. UTILI ALLE MOD.
   
   
DATA: len_in        LIKE sood-objlen,
      len_out       LIKE sood-objlen,
      c_filepdf     LIKE rlgrap-filename,
      va_variante   LIKE zcod_var-cod_atti,
      lv_filepdf    TYPE string,
      lt_file_name  TYPE filetable,
      wa_file_name  TYPE file_table,
      lv_rc         TYPE i,
      lv_filename   TYPE string,
      ztransfer_bin TYPE sx_boolean VALUE ' ',
      lv_length     TYPE so_obj_len,
      t_otfdata3    TYPE soli_tab,
      t_pdfdata1    TYPE solix_tab.


DATA: wa_pdfdata1   LIKE LINE OF t_pdfdata1.

DATA : BEGIN OF filename,
         dettaglio(20) TYPE c,
         DATA(6)       TYPE c,
         estensione(4) TYPE c VALUE '.pdf',
       END OF filename.

DATA zitcoo LIKE itcoo OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF t_otfdata2 OCCURS 0.
        INCLUDE STRUCTURE solisti1.
DATA: END OF t_otfdata2.

DATA: BEGIN OF t_pdfdata OCCURS 0.
        INCLUDE STRUCTURE solisti1.
DATA: END OF t_pdfdata.

   
   
* FINE VITOLAZZI 10/07/07 C.R. PTDK902442

* Inizio inser. RMddmmyy
   
   
DATA: gf_no_rec TYPE sy-subrc.
   
   
* Fine inser. RMddmmyy

   
   
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
DATA  cechk_itab.
PARAMETER flg_att LIKE zcod_var-cod_atti OBLIGATORY  . "CR 15.12.2015 DEFAULT 'B'.
SELECT-OPTIONS: s_blart  FOR dfkkko-blart NO INTERVALS, "Tipo documento
                s_budat  FOR dfkkko-budat , " Data documento
                s_opbel  FOR dfkkko-opbel NO-DISPLAY, "Num. documento
                s_exbel  FOR dfkkinvdoc_h-exbel,
                s_fikey  FOR dfkkko-fikey,
                s_spart  FOR dfkkop-spart,         " Sett. merceologico
                s_herkf  FOR dfkkko-herkf DEFAULT '77'. "Chiave orig doc
PARAMETER p_bukrs LIKE dfkkop-bukrs OBLIGATORY.
   
   
*                                    DEFAULT 'EPI'.  CR 15.12.2015
   
   
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-024.
PARAMETER: p_datare RADIOBUTTON GROUP a DEFAULT 'X'.
PARAMETER: p_datado RADIOBUTTON GROUP a.
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN SKIP.

PARAMETER: p_pdf AS CHECKBOX DEFAULT 'X'.
   
   
**Start Mod MEV110408 Registri IVA - Gestione files CPX INF XML 14.11.16 ind37or
   
   
PARAMETER: p_cpx AS CHECKBOX DEFAULT ' '.
   
   
*End Mod
   
   
PARAMETER: p_test AS CHECKBOX DEFAULT 'X'.
PARAMETER: p_spool LIKE usr01-spld OBLIGATORY.
PARAMETER: p_contr AS CHECKBOX DEFAULT 'X'.
PARAMETER: p_treg(2) .  "CR 15.12.2015 DEFAULT 'IN'.
   
   
** Inizio modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
PARAMETERS: p_vv AS CHECKBOX DEFAULT 'X'.

   
   
** Fine modifica -  MEV_106990 F-008-004
*PARAMETERS: FLG_ATT(1) DEFAULT 'B' OBLIGATORY.
* Inizio modifca - SAPIT 20/11/2006 - estrazione della tabella dei dati
* per esportazione alle funzionionalità di archiviazione per la gestione
* ed emissione dei tabulati attinenti alle normative (Decreto Bersani).
   
   
SELECTION-SCREEN BEGIN OF BLOCK zib WITH FRAME TITLE text-031.
PARAMETER: p_zib AS CHECKBOX DEFAULT space USER-COMMAND zibfl,
           p_zib_tr TYPE zib_tipo_registro OBLIGATORY MODIF ID zib
                        MATCHCODE OBJECT ziv_hp_tipo_registro,
   
   
***Begin Pamela Lops 19.06.08 - PTDK909111
   
   
p_tcode LIKE sy-tcode NO-DISPLAY.
   
   
***End Pamela Lops 19.06.08 - PTDK909111

   
   
SELECTION-SCREEN END OF BLOCK zib.


   
   
*inizio MEV 112057 spesometro 2017
   
   
PARAMETER p_speso AS CHECKBOX.
   
   
*Fine  MEV 112057 spesometro 2017


******************** M A I N *********************

* Modifica Miggiano - gestione modifiche rag. soc.
   
   
IF p_test = 'X'.
  SET PF-STATUS 'STATO1'.
   
   
***Start Mod MEV110408 Registri IVA ind37or .CPX SOLO SCARICO XLS
   
   
  IF p_cpx = 'X'.
    SET PF-STATUS 'STATO3'.
  ELSE.
    SET PF-STATUS 'STATO1'.
  ENDIF.
   
   
*End Mod mev110408
   
   
ELSE.
   
   
*& Pf-status per gestione visualizzazione spool - mod. 09/10/2003
   
   
  SET PF-STATUS 'STATO2'.
ENDIF.
   
   
*& Valorizzazione dell'anno sull'intestazione - mod. 09/10/2003
*w_data = sy-datum.
   
   
w_data = s_budat-high.
   
   
************************************************************************
*& Gestione invio dati di defoult - mod. 09/10/2003
   
   
INITIALIZATION.
  PERFORM cerca-dati.
   
   
***Begin Pamela Lops 19.06.08 - PTDK909111
   
   
  p_tcode = sy-tcode.
   
   
***End Pamela Lops 19.06.08 - PTDK909111

   
   
AT SELECTION-SCREEN.
   
   
*& Gestione valorizzazione dati input da cod. att. - mod. 09/10/2003
   
   
  IF flg_att NE save_flg_att
  OR flg_att EQ save_flg_att AND p_test EQ ' '.
    PERFORM cerca-dati.
  ENDIF.
  CLEAR wa_err.
  IF p_test = ' ' OR p_contr = 'X'.
    PERFORM controllo_mese.
   
   
*  perform controllo.
   
   
  ENDIF.
  TRANSLATE flg_att TO UPPER CASE.

   
   
*  IF  NOT FLG_ATT   CO  'ABC'.
*   MESSAGE E368(00) WITH 'Valaori ammessi A o B'.
* ENDIF.
*& Gestione valorizzazione dati input da cod. att. - mod. 09/10/2003

   
   
AT SELECTION-SCREEN OUTPUT.
  IF flg_att NE save_flg_att
  OR flg_att EQ save_flg_att AND p_test EQ ' '.
    PERFORM cerca-dati.
    MODIFY SCREEN.
  ENDIF.
  MOVE flg_att TO save_flg_att.

   
   
* Inizio modifca - SAPIT 20/11/2006 - estrazione della tabella dei dati
* per esportazione alle funzionionalità di archiviazione per la gestione
   
   
  LOOP AT SCREEN.
    CHECK screen-group1 = 'ZIB'.
    IF NOT p_zib IS INITIAL.
      screen-active = '1'.
      IF p_zib_tr IS INITIAL.
        CLEAR p_zib_tr WITH '*'.
      ENDIF.
    ELSE.
      screen-active = '0'.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
   
   
* Fine modifca - SAPIT 20/11/2006


   
   
AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'STAM'.
      PERFORM apro_modulo.
      PERFORM stampa_modulo.
      PERFORM stampa_modulo_riepilogo.
      PERFORM chiudo_modulo.
   
   
* VITOLAZZI 10/07/07 C.R. PTDK902442
* MODIFICHE PER STORICIZZAZIONE STAMPE IN PDF
* RIPERTO LE ROUTINE SAPSCRIPT PER CONVERSIONE
*Start mod Mev110408 ind37or
*      IF p_pdf EQ 'X'.
   
   
      IF p_pdf EQ 'X' OR p_cpx = 'X'.
        PERFORM zpdf.
      ENDIF.
   
   
*End mod
* FINE VITOLAZZI 10/07/07 C.R. PTDK902442
   
   
      PERFORM call_transaction.
      IF p_test = ' '.
        PERFORM aggiornamento.
      ENDIF.
   
   
***Begin Pamela Lops 19.06.08 - PTDK909111
   
   
      PERFORM f_zregiva_bersani.
   
   
***End Pamela Lops 19.06.08 - PTDK909111
   
   
    WHEN 'XLS'.
      PERFORM scarico_excel.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'ESC'.
      LEAVE PROGRAM.
  ENDCASE.

TOP-OF-PAGE.
  CASE va_top.
    WHEN ' '.
      PERFORM top.
    WHEN 'R'.
      PERFORM top_riepilogo.
    WHEN 'M'.
      PERFORM top_riep_merc.
  ENDCASE.

START-OF-SELECTION.
   
   
* VITOLAZZI 18/07/07 C.R. PTDK902617
* MODIFICHE PER STORICIZZAZIONE STAMPE IN PDF
* RECUPERO TIPO ATTIVITA' PER NOME FILE PDF.
   
   
  va_variante = flg_att.
   
   
* FINE VITOLAZZI 18/07/07 C.R. PTDK902617
* Inizio inser. RM290116
   
   
  gf_no_rec = 0.
   
   
* Fine inser. RM290116
* Inizio modifca - SAPIT 20/11/2006 - estrazione della tabella dei dati
* per esportazione alle funzionionalità di archiviazione per la gestione
* ed emissione dei tabulati attinenti alle normative (Decreto Bersani).
   
   
  PERFORM check_p_zib_tr.
   
   
* Fine modifca - SAPIT 20/11/2006

   
   
  IF s_budat-high IS INITIAL.
    s_budat-high = s_budat-low.
  ENDIF.
  itab_conto-sign = 'E'.
  itab_conto-option = 'EQ'.
  SELECT * FROM  zcod_conto.
    itab_conto-low = zcod_conto-conto.
    APPEND itab_conto.

  ENDSELECT.

  PERFORM carica_valori.
  PERFORM estrazione_fica. "tck31772524
  PERFORM estrazione.
  PERFORM ordinamento_fica.
  PERFORM ordinamento.

   
   
*   inizio MEV 112057 spesometro 2017
   
   
  IF p_speso = 'X'.
    PERFORM riempi_zreg_iva_spes.
  ENDIF.
  "fine MEV 112057 spesometro 2017

  IF p_test = ' ' OR p_contr = 'X' .
    PERFORM controlla_numerazione.
  ENDIF.
   
   
* se la tabella è vuota non procedo alla elaborazione.
   
   
  CLEAR app_righe.
  DESCRIBE TABLE itab LINES app_righe.
  IF app_righe <= 0.
    MESSAGE s368(00) WITH 'Nessun dato rilevato'.
    STOP.
  ENDIF.
   
   
* zl
   
   
  PERFORM riepilogo.
  PERFORM stampa.
   
   
* Inizio modifca - SAPIT 20/11/2006 - estrazione della tabella dei dati
* per esportazione alle funzionionalità di archiviazione per la gestione
* ed emissione dei tabulati attinenti alle normative (Decreto Bersani).
   
   
  PERFORM zib_extraction TABLES itab.
   
   
* Fine modifca - SAPIT 20/11/2006
   
   
  w_data_save = s_budat-low.
  IF p_test NE 'X'.                    " and wa_err is initial.
    PERFORM apro_modulo.
    PERFORM stampa_modulo.
    PERFORM stampa_modulo_riepilogo.
    PERFORM chiudo_modulo.
   
   
* VITOLAZZI 10/07/07 C.R. PTDK902442
* MODIFICHE PER STORICIZZAZIONE STAMPE IN PDF
* RIPERTO LE ROUTINE SAPSCRIPT PER CONVERSIONE
*Start mod Mev110408 ind37or
*    IF p_pdf EQ 'X'.
   
   
    IF p_pdf EQ 'X' OR p_cpx = 'X'.
      PERFORM zpdf.
    ENDIF.
   
   
*End mod
* FINE VITOLAZZI 10/07/07 C.R. PTDK902442
   
   
    PERFORM aggiornamento.
  ENDIF.
  IF NOT wa_err IS INITIAL.
    MESSAGE i368(00) WITH 'Elaborazione definitiva non effettuata'
                          'Errori rilevati controllo progressivi'.
   
   
***Begin Pamela Lops 19.06.08 - PTDK909111
   
   
  ELSE.
   
   
***Begin Pamela Lops 19.06.08 - PTDK909111
   
   
    PERFORM f_zregiva_bersani.
   
   
***End Pamela Lops 19.06.08 - PTDK909111

   
   
  ENDIF.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'SPOOL'.
      PERFORM call_transaction.
    WHEN 'INDIETRO'.
      LEAVE TO SCREEN 0.
    WHEN 'ESCI'.
      LEAVE TO SCREEN 0.
    WHEN 'USCITA'.
      LEAVE PROGRAM.
  ENDCASE.

END-OF-PAGE.
  PERFORM end.
   
   
*&---------------------------------------------------------------------*
*&      Form  TOP
*&---------------------------------------------------------------------*
   
   
FORM top.
   
   
* intestazione lista
*& Gestione paginazione - mod.09/10/2003
   
   
  ADD 1 TO w_page.
  FORMAT COLOR 1 INTENSIFIED OFF.

   
   
*CR 15.12.2015  INIZIO
   
   
  SELECT SINGLE * FROM zint_regiva WHERE bukrs = p_bukrs.

   
   
*& Gestione nuova intestazione - mod.09/10/2003
*  CONCATENATE text-001 text-028 INTO w_text_tit1.
   
   
  CONCATENATE zint_regiva-zintestazione text-028 INTO w_text_tit1.
   
   
*CR 15.12.2015  FINE

*  concatenate 'Pag.:' sy-datum(4) '/' w_page into w_text_tit2.
   
   
  CONCATENATE 'Pag.:' s_budat-high(4) '/' w_page INTO w_text_tit2.
   
   
*  WRITE:/63 TEXT-001 CENTERED,
*          255 ' '.
* INIZIO MOD T23880651 02.01.2014 DM
*  WRITE: /63 w_text_tit1 CENTERED, 240 ' '.
   
   
  WRITE: /63 w_text_tit1 CENTERED, 239 ' '.
   
   
* FINE MOD T23880651 02.01.2014 DM
   
   
  WRITE: w_text_tit2 RIGHT-JUSTIFIED .
  WRITE: /1 ' ', 255 ' '.
   
   
*& Gestione nuova intestazione - mod.09/10/2003
*  WRITE:/63 TEXT-002 CENTERED, 255 ' '.
   
   
  WRITE:/43 w_testo CENTERED, 255 ' '.

  WRITE: /1 ' ', 180 ' '.
  WRITE:/110 text-003 ,
          s_budat-low,
          ' - ' ,
          s_budat-high,
          255 ' '.

  WRITE: /1(255) sy-uline.
  FORMAT COLOR OFF.
   
   
* intestazione colonne
   
   
  FORMAT COLOR 1 INTENSIFIED ON.

  WRITE:/ text-020,
          text-004,                    "DATA
          text-005,                    "NUMERO DOCUMENTO
          text-015,                    "TIPO DOCUMENTO
   
   
*        text-016,      "Caratt. det. conti
   
   
          text-006,                    "CODICE CLIENTE
          text-013,                    "NOMINATIVO
   
   
*        text-007,      "PARTITA IVA

   
   
          134 text-008,                    "IMPONIBILE
   
   
**TCK 31897315 - layout reg IVA billing
   
   
          154 text-017,                    "CODICE IVA
   
   
*          text-017,                    "CODICE IVA
   
   
          164 text-009,                    "% IVA
   
   
*          text-009,                    "% IVA
   
   
          214 text-010,                    "IMPORTO IVA
          249 text-011,                "BOLLO
          266 text-012,                    "TOTALE
          289 ' '.
   
   
*          180 text-010,                    "IMPORTO IVA
*          215 text-011,                "BOLLO
*          232 text-012,                    "TOTALE
*          181 text-010,                    "IMPORTO IVA
*          204 text-011,                "BOLLO
*          214 text-012,                    "TOTALE
**TCK 31897315 - layout reg IVA billing
*          text-018,                    "TOTALE DIVISA TRANSAZIONE
*          text-019,
*          255 ' '.
   
   
  WRITE:/ sy-uline.

   
   
* scrivo i riporti
   
   
  IF vn_cont > 0.
    FORMAT RESET.
    FORMAT COLOR 3.
    WRITE:/ 'Riporto',
        vn_totale_imponibile UNDER text-008 CURRENCY t001-waers,
   
   
**TCK 31897315 - layout reg IVA billing
   
   
           vn_totale_imposte UNDER text-010 CURRENCY t001-waers,
           vn_bollo_tot      UNDER text-011 CURRENCY t001-waers,
           vn_totale_fatture_int UNDER text-012 CURRENCY t001-waers,
   
   
*           181 vn_totale_imposte CURRENCY t001-waers,
*           201 vn_bollo_tot      CURRENCY t001-waers,
*           221 vn_totale_fatture_int CURRENCY t001-waers,
**TCK 31897315 - layout reg IVA billing
*      vn_totale_fatture_tra under text-018 currency t001-waers no-sign,
*          vn_totale_ritenuta UNDER text-019 CURRENCY t001-waers ,
   
   
           255 ' '.
    FORMAT COLOR OFF.

   
   
*    clear:  vn_totale_imponibile,
*            vn_totale_imposte,
*            vn_totale_bolli,
*            vn_totale_fatture_int.

   
   
  ENDIF.

  ADD 1 TO vn_cont.

  CLEAR va_flag.

ENDFORM.                               " TOP

   
   
*&---------------------------------------------------------------------*
*&      Form  ESTRAZIONE
*&---------------------------------------------------------------------*
*       Estrazione dei dati
*----------------------------------------------------------------------*
   
   
FORM estrazione.
   
   
* Inizio inser. RM290116
   
   
  CHECK gf_no_rec = 0.
   
   
* Fine inser. RM290116
   
   
  IF p_datare = 'X'.
   
   
* estrazione documenti x data registrazione p
   
   
    CLEAR dfkkko.
   
   
*    SELECT * FROM dfkkko WHERE opbel IN s_opbel "Tk31772524
   
   
    SELECT * FROM dfkkko WHERE xblnr IN s_exbel             "T31779430
                           AND fikey IN s_fikey
                           AND blart IN s_blart
                           AND herkf IN s_herkf
                           AND budat IN s_budat.
   
   
*                           AND xblnr IN s_exbel.    "Tk31772524
* estrazione ritenuta
   
   
      SELECT opbel betrh betrw FROM dfkkopk
                   APPENDING CORRESPONDING FIELDS OF TABLE itab_rit
                   WHERE opbel = dfkkko-opbel
                   AND   bukrs = p_bukrs
                   AND hkont = ca_hkont.

   
   
* estrazione bollo
   
   
      SELECT opbel mwskz sbash sbasw FROM dfkkopk
                   APPENDING CORRESPONDING FIELDS OF TABLE itab_bollo
                   WHERE bukrs = p_bukrs
                   AND kschl = ca_bollo
                   AND opbel = dfkkko-opbel.
      IF sy-subrc NE 0.
        PERFORM  torvo_imposta_bollo.  "Caso MWAI
      ENDIF.
    ENDSELECT.

   
   
*   descrizione codice bollo
   
   
    PERFORM descrizione_codice_bollo.

    CLEAR dfkkko.
   
   
*    SELECT * FROM dfkkko WHERE opbel IN s_opbel "Tk31772524
   
   
    SELECT * FROM dfkkko WHERE xblnr IN s_exbel             "T31779430
                          AND fikey IN s_fikey
                          AND blart IN s_blart
                          AND herkf IN s_herkf
                          AND budat IN s_budat.
   
   
*                          AND xblnr IN s_exbel.    "Tk31772524

   
   
      CLEAR: controlla_bollo, controlla_ritenuta.
   
   
* trovo il codice cliente
   
   
      CLEAR dfkkop.
      SELECT SINGLE * FROM dfkkop WHERE ( opbel EQ dfkkko-opbel OR
                                          augbl EQ dfkkko-opbel )
                                     AND bukrs = p_bukrs
   
   
*                                     and budat eq dfkkko-budat
   
   
                                     AND spart IN s_spart.
      CHECK sy-subrc = 0.
      CLEAR t001.
      SELECT SINGLE * FROM t001 WHERE bukrs = p_bukrs.
   
   
*     trovo i dati relativi all'iva
   
   
      CLEAR dfkkopk.
      SELECT  * FROM dfkkopk WHERE opbel EQ dfkkko-opbel
                                AND (   kschl = ca_iva
                                     OR kschl = ca_lett ).
        CLEAR t007s.
        SELECT SINGLE * FROM t007s WHERE spras = 'ITL'
                                     AND kalsm = ca_prezzi
                                     AND mwskz = dfkkopk-mwskz.
        PERFORM riempio_itab.
      ENDSELECT.
   
   
* Modifica del 29/10/2003 Luigi Pacciolla
*************************************************
   
   
      PERFORM caricamento-esente_iva.
   
   
*************************************************
   
   
    ENDSELECT.

   
   
*************************************************
   
   
  ELSE.

   
   
* estrazione documenti x data documento
   
   
    CLEAR dfkkko.
   
   
*    SELECT * FROM dfkkko WHERE opbel IN s_opbel "Tk31772524
   
   
    SELECT * FROM dfkkko WHERE xblnr IN s_exbel             "T31779430
                          AND fikey IN s_fikey
                          AND blart IN s_blart
                          AND herkf IN s_herkf
                          AND bldat IN s_budat.
   
   
*                          AND xblnr IN s_exbel.    "Tk31772524
* estrazione ritenuta
   
   
      SELECT opbel betrh betrw FROM dfkkopk
                   APPENDING CORRESPONDING FIELDS OF TABLE itab_rit
                   WHERE opbel = dfkkko-opbel
                   AND bukrs = p_bukrs
                   AND hkont = ca_hkont.

   
   
* estrazione bollo
   
   
      SELECT opbel mwskz sbash sbasw FROM dfkkopk
                   APPENDING CORRESPONDING FIELDS OF TABLE itab_bollo
                   WHERE opbel = dfkkko-opbel
                   AND bukrs = p_bukrs
                   AND kschl = ca_bollo.
      IF sy-subrc NE 0.
        PERFORM  torvo_imposta_bollo.  "Caso MWAI
      ENDIF.

    ENDSELECT.
   
   
*   descrizione codice bollo
   
   
    PERFORM descrizione_codice_bollo.

   
   
*  estrazione documenti x data documento
   
   
    CLEAR dfkkko.
   
   
*    SELECT * FROM dfkkko WHERE opbel IN s_opbel "Tk31772524
   
   
    SELECT * FROM dfkkko WHERE xblnr IN s_exbel             "T31779430
                           AND fikey IN s_fikey
                           AND blart IN s_blart
                           AND herkf IN s_herkf
                           AND bldat IN s_budat.
   
   
*                           AND xblnr IN s_exbel.    "Tk31772524
   
   
      CLEAR: controlla_bollo, controlla_ritenuta.
   
   
* Trovo il codice cliente
   
   
      CLEAR dfkkop.
      SELECT SINGLE * FROM dfkkop WHERE ( opbel EQ dfkkko-opbel OR
                                     augbl EQ dfkkko-opbel )
                                 AND bukrs = p_bukrs
   
   
*                                 and budat eq dfkkko-bldat
   
   
                                 AND spart IN s_spart.
      CHECK sy-subrc = 0.
      CLEAR t001.
      SELECT SINGLE * FROM t001 WHERE bukrs = p_bukrs.
   
   
* Trovo i dati relativi all'iva
   
   
      CLEAR dfkkopk.
      SELECT  * FROM dfkkopk WHERE opbel EQ dfkkko-opbel
                                AND (   kschl = ca_iva
                                     OR kschl = ca_lett ) .
        CLEAR t007s.
        SELECT SINGLE * FROM t007s WHERE spras = 'ITL'
                                     AND kalsm = ca_prezzi
                                     AND mwskz = dfkkopk-mwskz.
        PERFORM riempio_itab.
      ENDSELECT.
   
   
* Modifica del 29/10/2003 Luigi Pacciolla
*************************************************
   
   
      PERFORM caricamento-esente_iva.
   
   
*************************************************

   
   
    ENDSELECT.
  ENDIF.

   
   
* Pulisco la tabella dei clienti.
   
   
  DELETE ADJACENT DUPLICATES FROM itab_cliente.


ENDFORM.                               " ESTRAZIONE

   
   
*&---------------------------------------------------------------------*
*&      Form  RIEMPIO_ITAB
*&---------------------------------------------------------------------*
   
   
FORM riempio_itab.

  CLEAR itab.
  CLEAR vn_perc.

   
   
* DFKKKO
   
   
  itab-blart = dfkkko-blart.           "Tipo documento

  IF p_datare = 'X'.
    itab-budat = dfkkko-budat.         "Data documento
    itab-opbel = dfkkko-opbel.         "Numero documento
  ELSE.
    itab-budat = dfkkko-bldat.         "Data documento nel doc
    itab-opbel = dfkkko-xblnr(12).     "Numero documento di rif
  ENDIF.

   
   
* DFKKOP
   
   
  itab-gpart = dfkkop-gpart.           "Codice cliente
  itab-waers = dfkkop-waers.           "Divisa transazione
  itab-kofiz = dfkkop-kofiz.           "Caratt. det. conti
  itab-spart = dfkkop-spart.           "Settore merceologico

   
   
* DFKKOPK
   
   
  itab-mwskz = dfkkopk-mwskz.          "Codice IVA
  itab-text1 = t007s-text1.            "Descrizione codice iva
  itab-betrh = dfkkopk-sbash * -1.     "Imponibile divisa interna
  itab-betrw = dfkkopk-sbasw * -1.     "Imponibile divisa transazione
  itab-sbeth = dfkkopk-betrh * -1 .    "Importo iva divisa interna
  itab-sbetw = dfkkopk-betrw * -1 .    "Importo iva divisa transaz
   
   
* calcolo la percentuale dell'iva
   
   
  IF dfkkopk-stprz NE space.
    vn_perc = dfkkopk-stprz / 1000.
    WRITE vn_perc TO itab-perc(3).
    WRITE '%' TO itab-perc+3(1).
  ENDIF.
   
   
* totale divisa interna
   
   
  itab-totale = itab-betrh + itab-sbeth.
   
   
* totale divisa transazione
   
   
  itab-totale2 = itab-betrw + itab-sbetw.
   
   
*
   
   
  APPEND itab.
   
   
*
   
   
  CLEAR itab_bis.
  itab_bis = itab.
   
   
* se non c'è l'iva controllo il bollo (solo una volta per ogni docum.)
   
   
  IF dfkkopk-stprz = space AND controlla_bollo = ' '.
    controlla_bollo = 'X'.
    READ TABLE itab_bollo WITH KEY opbel = itab-opbel.
    IF sy-subrc = 0.
      CLEAR itab.
      itab-opbel = itab_bis-opbel.
      itab-budat = itab_bis-budat.
      itab-blart = itab_bis-blart.
      itab-gpart = itab_bis-gpart.
      itab-spart = itab_bis-spart.
      itab-waers = itab_bis-waers.
      itab-mwskz = itab_bollo-mwskz.
      itab-text1 = itab_bollo-text1.
      itab-bollo_int = itab_bollo-sbash. "Importo bollo divisa in
      itab-bollo_tra = itab_bollo-sbasw. "Importo bollo divisa tr
   
   
* totale divisa interna
   
   
      itab-totale =  itab-bollo_int.
   
   
* totale divisa transazione
   
   
      itab-totale2 =  itab-bollo_tra .

      APPEND itab.
    ENDIF.
  ENDIF.

   
   
* cerco la ritenuta
   
   
  IF controlla_ritenuta = space.
    controlla_ritenuta = 'X'.
    CLEAR itab_rit.
    READ TABLE itab_rit WITH KEY opbel = itab-opbel.
    IF sy-subrc = 0.
      CLEAR itab.
      itab-opbel = itab_bis-opbel.
      itab-budat = itab_bis-budat.
      itab-blart = itab_bis-blart.
      itab-gpart = itab_bis-gpart.
      itab-spart = itab_bis-spart.
      itab-waers = itab_bis-waers.
      itab-riten = itab_rit-betrh * -1 .
      itab-riten_t = itab_rit-betrw * -1 .
   
   
* totale divisa interna
   
   
      itab-totale =  itab-riten.
   
   
* totale divisa transazione
   
   
      itab-totale2 =  itab-riten_t.
      APPEND itab.
    ENDIF.

   
   
*    APPEND itab.  "RM120116D
   
   
  ENDIF.

   
   
* trovo i dati relativi al cliente.
   
   
  PERFORM dati_cliente.

ENDFORM.                               " RIEMPIO_ITAB
   
   
*&---------------------------------------------------------------------*
*&      Form  DATI_CLIENTE
*&---------------------------------------------------------------------*
*       Cerco i dati relativi al cliente
*----------------------------------------------------------------------*
   
   
FORM dati_cliente.

  CLEAR itab_cliente.
  CLEAR but020.
   
   
*  SELECT SINGLE * FROM BUT020 WHERE  PARTNER = ITAB-GPART
*                                AND  XDFADR  = 'X'.
   
   
  call function 'Z_BP_INDIRIZZO_STANDARD'
    EXPORTING
      partner    = itab-gpart
   
   
*     KIND       = 'XXDEFAULT'
   
   
    IMPORTING
      addrnumber = but020-addrnumber.




  CLEAR adrc.
  SELECT SINGLE * FROM adrc WHERE addrnumber = but020-addrnumber.
  CLEAR dfkkbptaxnum.
  SELECT SINGLE * FROM dfkkbptaxnum WHERE  partner = itab-gpart
                                      AND  taxtype = 'IT0'.

  SELECT SINGLE * FROM but000 WHERE partner = itab-gpart.
   
   
**CRinaldi 18.05.2016 inizio
* Inizio modifica  per gestione descr.supplementare 25/10/2004
**  IF BUT020-XDFADR EQ 'X' AND
*  IF NOT but020-addrnumber IS INITIAL AND
*    but000-type = '1'    AND
*    adrc-str_suppl1 NE ' '.
*    CONCATENATE adrc-str_suppl1 adrc-str_suppl2 INTO adrc-name1
*    SEPARATED BY space.
*  ENDIF.
** Fine modifica per gestione descr.supplementare 25/10/04
*CRinaldi 18.05.2016 fine
   
   
  IF adrc-name1 IS INITIAL.
    CLEAR adrc-name1.
    CONCATENATE but000-name_first but000-name_last INTO
                adrc-name1 SEPARATED BY space.
    MOVE but000-name_first TO itab_cliente-name_first.
    MOVE but000-name_last  TO itab_cliente-name_last.
  ENDIF.
  MOVE but000-type TO itab_cliente-type.
  itab_cliente-gpart = itab-gpart.
  itab_cliente-name1 = adrc-name1.
  itab_cliente-street = adrc-street.
  itab_cliente-post_code1 = adrc-post_code1.
  itab_cliente-city1 = adrc-city1.
  itab_cliente-taxnum = dfkkbptaxnum-taxnum.

  APPEND itab_cliente.

ENDFORM.                               " DATI_CLIENTE

   
   
*&---------------------------------------------------------------------*
*&      Form  STAMPA
*&---------------------------------------------------------------------*
*       Stampa la lista
*----------------------------------------------------------------------*
   
   
FORM stampa.

   
   
* clear vn_riga.
   
   
  SELECT MAX( budatda ) INTO budat_ul2 FROM zivadate_el
                        WHERE flg_att  = flg_att
                        AND     bukrs  = p_bukrs.
  SELECT SINGLE * FROM zivadate_el WHERE budatda EQ budat_ul2
                                   AND   flg_att = flg_att
                                   AND     bukrs  = p_bukrs.
  vn_riga = zivadate_el-numeraz.
   
   
*& Gestione paginazione - mod.09/10/2003
   
   
  w_page = zivadate_el-pagina.
  IF budat_ul2(4) NE s_budat-low(4).
    CLEAR: vn_riga, w_page.
  ENDIF.

  LOOP AT itab.

    ADD 1 TO vn_riga.
    ADD 1 TO vn_contx.
    FORMAT RESET.
    IF va_colore = 'X'.
      FORMAT RESET.
      va_colore = ' '.
    ELSE.
      FORMAT COLOR 2 INTENSIFIED ON.
      va_colore = 'X'.
    ENDIF.
   
   
*SEGNALAZIONE ERRORI

   
   
    IF NOT itab-flag_err IS INITIAL.
      FORMAT COLOR 6 INTENSIFIED ON.
    ENDIF.

   
   
*ZL
   
   
    CLEAR itab_cliente.
   
   
*modifica rag. sociale.

   
   
    DATA: my_opbel LIKE vbrk-vbeln.
    CLEAR my_opbel.
   
   
*    clear zlog_cliente.
*   my_opbel = itab-opbel+2(10).
   
   
    READ TABLE itab_cliente WITH KEY gpart = itab-gpart.
   
   
*                                     opbel = itab-opbel.
   
   
    WRITE:/ vn_riga UNDER text-020 NO-ZERO.
    IF itab-opbel NE va_doc.
      WRITE:    itab-budat UNDER text-004,
                itab-opbel UNDER text-005,
                itab-blart UNDER text-015,
   
   
*        itab-kofiz under text-016,
   
   
                itab-gpart UNDER text-006.
      IF NOT itab-flag_err IS INITIAL.
        IF itab-flag_err = 'A'.
          WRITE  'Documento Non progressivo da elab. precedente'
                 UNDER text-013.
        ELSE.
          WRITE  'Documento mancante, errore in progressivi'
                 UNDER text-013.
        ENDIF.
      ELSE.
   
   
* Modifica gestione log ragione sociale
*        PERFORM verifica_ragione_sociale.
   
   
        PERFORM find_nominativo.
   
   
* Modifica gestione log ragione sociale
   
   
        WRITE  itab_cliente-name1 UNDER text-013.
      ENDIF.
    ENDIF.
    WRITE:     itab-betrh UNDER text-008 CURRENCY t001-waers ,
               itab-mwskz UNDER text-017.
    IF itab-perc NE '    '.
   
   
*     WRITE:  AT 130 itab-perc NO-ZERO,
**TCK 31897315 - layout reg IVA billing
   
   
      WRITE:  itab-perc UNDER text-009 NO-ZERO,
   
   
*      WRITE:  AT 135 itab-perc NO-ZERO,
   
   
              itab-sbeth UNDER text-010 CURRENCY t001-waers .
   
   
*              AT 181 itab-sbeth CURRENCY t001-waers .
**TCK 31897315 - layout reg IVA billing
   
   
    ELSE.
      WRITE: itab-text1 UNDER text-009.
    ENDIF.
    WRITE itab-bollo_int TO va_bollo CURRENCY t001-waers.
   
   
**TCK 31897315 - layout reg IVA billing
   
   
    WRITE: va_bollo UNDER text-011 RIGHT-JUSTIFIED.
   
   
*    WRITE: AT 201 va_bollo RIGHT-JUSTIFIED.
**TCK 31897315 - layout reg IVA billing
   
   
    WRITE:
   
   
**TCK 31897315 - layout reg IVA billing
   
   
      itab-totale UNDER text-012 CURRENCY t001-waers RIGHT-JUSTIFIED,
   
   
*  AT 221 itab-totale CURRENCY t001-waers  RIGHT-JUSTIFIED,
**TCK 31897315 - layout reg IVA billing
*  itab-totale2 UNDER text-018 CURRENCY itab-waers RIGHT-JUSTIFIED,
*  itab-riten  UNDER text-019 CURRENCY t001-waers RIGHT-JUSTIFIED,
   
   
                255 ' '.


    ADD itab-betrh        TO vn_totale_imponibile.
   
   
* Modifica del 30/10/2003 Luigi Pacciolla
   
   
    IF itab-perc NE '    '.
      ADD itab-sbeth        TO vn_totale_imposte.
    ENDIF.
    ADD itab-bollo_int   TO vn_totale_bolli.
    ADD itab-totale       TO vn_totale_fatture_int.
    ADD itab-riten        TO vn_totale_ritenuta.

    ADD 1 TO vn_cont2.
   
   
*va_cliente = itab-gpart.
   
   
    va_doc = itab-opbel.
  ENDLOOP.

   
   
* DTTS Oliva - 24.06.09 - BEGIN
   
   
  CLEAR va_doc.
   
   
* DTTS Oliva - 24.06.09 - END

   
   
  PERFORM end.

   
   
* stampo riepilogo
   
   
  va_top  = 'R'.
  NEW-PAGE.
  CLEAR itab_riepilogo.
  PERFORM pulizia_riep.

  LOOP AT itab_riepilogo.
    WRITE:/ itab_riepilogo-perc NO-ZERO,
            itab_riepilogo-mwskz,
            itab_riepilogo-text1,
    itab_riepilogo-impon CURRENCY t001-waers UNDER text-008 RIGHT-JUSTIFIED,
    itab_riepilogo-iva CURRENCY t001-waers UNDER text-010 RIGHT-JUSTIFIED.
    WRITE itab_riepilogo-bollo CURRENCY t001-waers TO va_bollo.
    WRITE: AT 114 va_bollo,
           AT 132 itab_riepilogo-totale
           CURRENCY t001-waers.
   
   
*itab_riepilogo-riten CURRENCY t001-waers UNDER text-019 RIGHT-JUSTIFIED.

   
   
    PERFORM totale_riepilogo.

  ENDLOOP.

  PERFORM scrivo_totali.

   
   
* stampo riepilogo per settore merceologico
   
   
  va_top = 'M'.
   
   
*  NEW-PAGE.
*  CLEAR ITAB_MERC.
*  PERFORM PULIZIA_RIEP.
*
*  LOOP AT ITAB_MERC.
*    WRITE:/ ITAB_MERC-SPART UNDER TEXT-026,
*            ITAB_MERC-VTEXT UNDER TEXT-027,
*    ITAB_MERC-IMPON CURRENCY T001-WAERS UNDER TEXT-008 RIGHT-JUSTIFIED,
*    ITAB_MERC-IVA CURRENCY T001-WAERS UNDER TEXT-010 RIGHT-JUSTIFIED.
*    WRITE ITAB_MERC-BOLLO CURRENCY T001-WAERS TO VA_BOLLO.
*    WRITE: VA_BOLLO UNDER TEXT-011 RIGHT-JUSTIFIED,
*           ITAB_MERC-TOTALE CURRENCY T001-WAERS UNDER TEXT-012
*                                                     RIGHT-JUSTIFIED ,
*           ITAB_MERC-RITEN CURRENCY T001-WAERS UNDER TEXT-019
*                                                   RIGHT-JUSTIFIED.
*
*    PERFORM TOTALE_RIEPILOGO_MERC.
*  ENDLOOP.
*  PERFORM SCRIVO_TOTALI.

   
   
ENDFORM.                               " STAMPA

   
   
*&---------------------------------------------------------------------*
*&      Form  ORDINAMENTO
*&---------------------------------------------------------------------*
*       ordino la tabella interna
*----------------------------------------------------------------------*
   
   
FORM ordinamento.
  DELETE ADJACENT DUPLICATES FROM itab.
  SORT itab BY opbel budat mwskz DESCENDING.
ENDFORM.                               " ORDINAMENTO
   
   
*&---------------------------------------------------------------------*
*&      Form  END
*&---------------------------------------------------------------------*
   
   
FORM end.

  CHECK  va_flag = ' ' .

  FORMAT RESET.

  WRITE vn_totale_bolli TO vn_bollo_tot CURRENCY t001-waers.

  WRITE:/ sy-uline.
  FORMAT COLOR 3.
  WRITE:/ 'TOTALI',
        vn_totale_imponibile UNDER text-008 CURRENCY t001-waers,
   
   
**TCK 31897315 - layout reg IVA billing
   
   
        vn_totale_imposte UNDER text-010 CURRENCY t001-waers,
        vn_bollo_tot      UNDER text-011 CURRENCY t001-waers NO-ZERO,
        vn_totale_fatture_int UNDER text-012 CURRENCY t001-waers,
   
   
*        181 vn_totale_imposte CURRENCY t001-waers,
*        201 vn_bollo_tot      CURRENCY t001-waers NO-ZERO,
*        221 vn_totale_fatture_int CURRENCY t001-waers,
**TCK 31897315 - layout reg IVA billing
*      vn_totale_fatture_tra under text-018 currency itab-waers no-sign,
*        vn_totale_ritenuta   UNDER text-019 CURRENCY t001-waers ,
   
   
                255 ' '.
  WRITE:/ sy-uline.
  FORMAT COLOR OFF.
  va_flag = 'X'.
ENDFORM.                               " END
   
   
*&---------------------------------------------------------------------*
*&      Form  STAMPA_MODULO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM stampa_modulo.

  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA3_NE'.

  SELECT MAX( budatda ) INTO budat_ul2 FROM zivadate_el
                                   WHERE flg_att  = flg_att
                                   AND     bukrs  = p_bukrs.
  SELECT SINGLE * FROM zivadate_el WHERE budatda EQ budat_ul2
                                   AND flg_att  = flg_att
                                   AND     bukrs  = p_bukrs.
  vn_riga = zivadate_el-numeraz.
  w_page_save = w_page.
  w_page_stampa = zivadate_el-pagina.
  IF budat_ul2(4) NE s_budat-low(4).
    CLEAR: vn_riga, w_page_stampa.
  ENDIF.

   
   
*  clear vn_riga.
   
   
  CLEAR vn_totale_imponibile.
  CLEAR  vn_totale_imposte.
  CLEAR  vn_totale_bolli.
  CLEAR  vn_totale_fatture_int.
  CLEAR  vn_totale_fatture_tra.
  CLEAR  vn_totale_ritenuta.


  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'REGISTRO'
      window  = 'HEADER'.
  LOOP AT itab.


    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element = 'RIPORTI'
        window  = 'MAIN'.

    ADD 1 TO vn_riga.
    ADD 1 TO vn_cont3.

    CLEAR itab_cliente.
    DATA: my_opbel LIKE vbrk-vbeln.
    CLEAR my_opbel.
    READ TABLE itab_cliente WITH KEY gpart = itab-gpart.

   
   
*    if itab-opbel ne va_doc.
   
   
    WRITE itab-budat TO  itab_modulo-budat.
    itab_modulo-opbel = itab-opbel.
    itab_modulo-blart = itab-blart.
   
   
*        itab-kofiz under text-016,
   
   
    itab_modulo-gpart = itab-gpart.
    itab_modulo-name1 = itab_cliente-name1.
   
   
* modifica verifica modifica ragione sociale.
*qui.
*    PERFORM verifica_ragione_sociale.
   
   
    PERFORM find_nominativo.
   
   
* modifica per ragione sociale cambiata
*       itab_cliente-taxnum under text-007,
*    endif.
   
   
    WRITE: itab-betrh CURRENCY t001-waers  TO itab_modulo-betrh.
    itab_modulo-mwskz = itab-mwskz.
    IF itab-perc NE '    '.
      itab_modulo-perc = itab-perc.
      WRITE itab-sbeth CURRENCY t001-waers  TO itab_modulo-sbeth.
    ELSE.
   
   
*if itab-bollo_int is initial.
   
   
      itab_modulo-text1 = itab-text1.
   
   
*endif.
   
   
    ENDIF.
    WRITE itab-bollo_int TO va_bollo CURRENCY t001-waers NO-SIGN.
    WRITE itab-totale CURRENCY t001-waers  TO itab_modulo-totale.
    WRITE itab-totale2 CURRENCY itab-waers  TO itab_modulo-totalet.

   
   
** Prova x ritenuta
   
   
    WRITE itab-riten TO itab_modulo-riten CURRENCY t001-waers.


    ADD itab-betrh     TO vn_totale_imponibile.
    ADD itab-sbeth     TO vn_totale_imposte.
    ADD itab-bollo_int TO vn_totale_bolli.
    ADD itab-totale    TO vn_totale_fatture_int.
    ADD itab-totale    TO vn_totale_fatture_tra.
    ADD itab-riten     TO vn_totale_ritenuta.

    WRITE vn_totale_imponibile  TO va_tot_imponibile_s
                                  CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_imposte  TO va_tot_imposte_s
                               CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_bolli    TO va_tot_bolli_s
                               CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_fatture_int TO va_tot_fatture_int_s
                                   CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_fatture_tra TO va_tot_fatture_tra_s
                                   CURRENCY itab-waers NO-SIGN.
    WRITE vn_totale_ritenuta    TO va_tot_ritenuta_s
                                CURRENCY t001-waers NO-SIGN.
   
   
* documento non progressivo
   
   
    IF itab-flag_err = 'B'.
      itab_cliente-name1 = 'Doc. non emesso per errore informatico'.
      CLEAR itab_modulo-text1.
    ENDIF.
   
   
* documento non progressivo
   
   
    IF itab-opbel NE va_doc.
      IF itab-perc NE '    '.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_IVA_CLIENTE'
            window  = 'MAIN'.
      ELSE.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_NOIVA_CLIENTE'
            window  = 'MAIN'.
      ENDIF.
    ELSE.
      IF itab-perc NE '    '.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_IVA_NOCLIENTE'
            window  = 'MAIN'.
      ELSE.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_NOIVA_NOCLIENTE'
            window  = 'MAIN'.
      ENDIF.

    ENDIF.

    ADD 1 TO vn_cont2.
   
   
*va_cliente = itab-gpart.
   
   
    va_doc = itab-opbel.

   
   
*    CALL FUNCTION 'WRITE_FORM'
*         EXPORTING
*              ELEMENT = 'RIPORTI'
*              WINDOW  = 'MAIN'.

   
   
    IF sw_passato NE 'X'.
      IF vn_cont3 = 35.
        sw_passato = 'X'.
        ADD 1 TO w_page_stampa.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'TOTALI'
            window  = 'MAIN'.
        CLEAR vn_cont3.
        va_flag2 = 'X'.

        va_tot_imponibile_sr  =    va_tot_imponibile_s .
        va_tot_imposte_sr     =    va_tot_imposte_s .
        va_tot_bolli_sr       =    va_tot_bolli_s .
        va_tot_fatture_int_sr =    va_tot_fatture_int_s .
        va_tot_fatture_tra_sr =    va_tot_fatture_tra_s .
        va_tot_ritenuta_sr    =    va_tot_ritenuta_s .
      ENDIF.
    ELSE.
      IF vn_cont3 = 34.
        ADD 1 TO w_page_stampa.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'TOTALI'
            window  = 'MAIN'.
        CLEAR vn_cont3.
        va_flag2 = 'X'.
        va_tot_imponibile_sr  =    va_tot_imponibile_s .
        va_tot_imposte_sr     =    va_tot_imposte_s .
        va_tot_bolli_sr       =    va_tot_bolli_s .
        va_tot_fatture_int_sr =    va_tot_fatture_int_s .
        va_tot_fatture_tra_sr =    va_tot_fatture_tra_s .
        va_tot_ritenuta_sr    =    va_tot_ritenuta_s .
      ENDIF.
    ENDIF.
  ENDLOOP.

   
   
* DTTS Oliva - 24.06.09 - BEGIN
   
   
  CLEAR va_doc.
   
   
* DTTS Oliva - 24.06.09 - END

   
   
  ADD 1 TO w_page_stampa.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'TOTALI'
      window  = 'MAIN'.

  CALL FUNCTION 'END_FORM' .


ENDFORM.                               " STAMPA_MODULO
   
   
*&---------------------------------------------------------------------*
*&      Form  APRO_MODULO
*&---------------------------------------------------------------------*
*       Apro il modulo Sapscript
*----------------------------------------------------------------------*
   
   
FORM apro_modulo.

  CLEAR itcpo.
  itcpo-tddest   = p_spool.
  itcpo-tdnewid  = 'X'.
  itcpo-tdimmed  = ' '.
  itcpo-tddelete = ' '.


  CALL FUNCTION 'OPEN_FORM'
    EXPORTING
      application = 'TX'
      device      = 'PRINTER'
      dialog      = ' '
   
   
*     form        = 'ZREGISTROIVA'
   
   
      options     = itcpo
      language    = sy-langu.

ENDFORM.                               " APRO_MODULO
   
   
*&---------------------------------------------------------------------*
*&      Form  CHIUDO_MODULO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM chiudo_modulo.

  CALL FUNCTION 'CLOSE_FORM'.


ENDFORM.                               " CHIUDO_MODULO
   
   
*&---------------------------------------------------------------------*
*&      Form  AGGIORNAMENTO
*&---------------------------------------------------------------------*
*       Aggiornamento tabella di controllo
*----------------------------------------------------------------------*
   
   
FORM aggiornamento.
  CLEAR : va_documento_iniziale, va_documento_finale.

  DESCRIBE TABLE itab LINES vn_righe.
  CLEAR itab.
  READ TABLE itab INDEX 1.
  va_documento_iniziale = itab-opbel.
  CLEAR itab.
  READ TABLE itab INDEX vn_righe.
  va_documento_finale = itab-opbel.

  CLEAR itab.

  LOOP AT itab.
    itab_save-bukrs = p_bukrs.
    itab_save-budat = itab-budat.
    itab_save-codiceiva = itab-mwskz.
    itab_save-perc = itab-perc.
    itab_save-imponibile = itab-betrh.
    itab_save-iva = itab-sbeth.
    itab_save-totaleint = itab-totale.
    itab_save-bollo = itab-bollo_int.
    itab_save-ritenuta = itab-riten.
    COLLECT itab_save.
  ENDLOOP.

  CLEAR itab_save.

  LOOP AT itab_save.
    MOVE-CORRESPONDING itab_save TO zivagg.
    INSERT zivagg.
  ENDLOOP.


  CLEAR app_righe.
  CLEAR zivadate_el.
  MOVE s_budat-low TO zivadate_el-budatda.
  MOVE s_budat-high TO zivadate_el-budata.
  READ TABLE itab INDEX 1.
  MOVE itab-opbel TO zivadate_el-opbelda.
  DESCRIBE TABLE itab LINES app_righe.
  READ TABLE itab INDEX app_righe.
  MOVE itab-opbel TO zivadate_el-opbela.
  MOVE p_bukrs TO    zivadate_el-bukrs.
  MOVE flg_att TO    zivadate_el-flg_att.
  MOVE vn_riga TO    zivadate_el-numeraz.
   
   
*& Gestione numerazione pagina mod.del 09/10/2003.
   
   
  MOVE w_page_stampa  TO   zivadate_el-pagina.
  INSERT zivadate_el.
ENDFORM.                               " AGGIORNAMENTO
   
   
*&---------------------------------------------------------------------*
*&      Form  CONTROLLO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM controllo.

  CLEAR zivagg.

  SELECT SINGLE * FROM zivagg WHERE
                       bukrs = p_bukrs AND
                       budat IN s_budat.
  IF sy-subrc = 0.
    MESSAGE e208(00) WITH 'Data già elaborata'.
  ENDIF.




ENDFORM.                               " CONTROLLO
   
   
*&---------------------------------------------------------------------*
*&      Form  CONTROLLA_NUMERAZIONE
*&---------------------------------------------------------------------*
*       Controllo della numerazione progressiva delle fatture
*----------------------------------------------------------------------*
   
   
FORM controlla_numerazione.
  DATA: va_popup.
  DATA: vn_doc(12) TYPE n.
  DATA: va_doc(12) TYPE c.
  CLEAR vn_doc.
  CLEAR va_popup.

  LOOP AT itab.
    itab_num-opbel = itab-opbel.
    APPEND itab_num.
  ENDLOOP.

  DELETE ADJACENT DUPLICATES FROM itab_num.

   
   
*zl controlli per progressivo fatture.

* controllo ultimo progressivo.
   
   
  CLEAR vn_doc.
  SELECT MAX( opbela  )  FROM zivadate_el
                           INTO va_doc
                         WHERE bukrs = p_bukrs
                         AND flg_att = flg_att .
  vn_doc = va_doc + 1.

  READ TABLE itab INDEX 1.
  IF itab-opbel NE vn_doc.
    wa_err = 'X'.
    CLEAR vn_doc.
    vn_doc = itab-opbel.
    LOOP AT itab WHERE opbel EQ vn_doc.
      itab-flag_err = 'A'.
      MODIFY itab INDEX sy-tabix.
    ENDLOOP.
    MESSAGE s398(00) WITH 'Il primo documento non è progressivo'
                      ' rispetto all''ultimo stampato precedentemente'.
    IF p_test = ' '.
   
   
*      stop.
   
   
    ENDIF.
  ENDIF.

   
   
* controllo progressivi
   
   
  vn_doc = va_doc.
  LOOP AT itab_num.
    vn_doc = vn_doc + 1.
    IF itab_num-opbel NE vn_doc.
      IF itab_num-opbel > va_doc.
        wa_check = vn_doc - itab_num-opbel.
        wa_err = 'X'.
        DO wa_check TIMES.
          CLEAR itab.
          MOVE vn_doc TO itab-opbel.
          itab-flag_err = 'B'.
          itab-text1 = 'Documento non progressivo'.
          APPEND itab.
          vn_doc = vn_doc + 1.
        ENDDO.
        vn_doc = itab_num-opbel.
        MESSAGE s208(00) WITH 'Documenti non progressivi!'.
      ELSE.
        IF sy-tabix = 1.
          CLEAR itab.
          MOVE vn_doc TO itab-opbel.
          itab-flag_err = 'B'.
          itab-text1 = 'Documento non progressivo'.
          APPEND itab.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  PERFORM ordinamento.
ENDFORM.                               " CONTROLLA_NUMERAZIONE
   
   
*&---------------------------------------------------------------------*
*&      Form  SCARICO_EXCEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM scarico_excel.
  PERFORM formatta_data.
  CALL FUNCTION 'WS_EXCEL'
    EXPORTING
      filename = ' '
      synchron = ' '
    TABLES
      data     = itab.
   
   
*  CALL FUNCTION 'RH_START_EXCEL_WITH_DATA'
*      EXPORTING
*           CHECK_VERSION       = ' '
*           DATA_NAME           = 'Registro Iva '
*           DATA_PATH_FLAG      = 'W'
*           DATA_TYPE           = 'DAT'
**         DATA_BIN_FILE_SIZE  =
**         MACRO_NAME          = ' '
**         MACRO_PATH_FLAG     = ' '
**         FORCE_START         = ' '
**         WAIT                = 'X'
**    IMPORTING
**         WINID               =
*      TABLES
*           DATA_TAB            = ITAB.

   
   
ENDFORM.                               " SCARICO_EXCEL
   
   
*&---------------------------------------------------------------------*
*&      Form  RIEPILOGO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM riepilogo.
   
   
*** Inizio modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
  itab2[] = itab[].
  IF p_vv IS NOT INITIAL.
    PERFORM trova_range.
  ENDIF.
   
   
** Fine modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
  CLEAR itab.
  LOOP AT itab.
   
   
*** Inizio modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
    IF p_vv IS NOT INITIAL.
      LOOP AT itab2 WHERE opbel = itab-opbel AND mwskz IN p_range.
      ENDLOOP.
      IF sy-subrc = 0.
        IF itab-mwskz = 'VV'.
          DELETE itab.
        ENDIF.
      ENDIF.
    ENDIF.
   
   
** Fine modifica 14.05.2015 - MEV_106990 REQ-F-008-004
   
   
    PERFORM itab_riepilogo.
    PERFORM itab_merc.
  ENDLOOP.
   
   
* cerco la descrizione del settore merceologico
   
   
  CLEAR itab_merc.
  LOOP AT itab_merc.
    CLEAR tspat.
    SELECT SINGLE * FROM tspat WHERE spart = itab_merc-spart
                                 AND spras = t001-spras.
    MOVE tspat-vtext TO itab_merc-vtext.
    MODIFY itab_merc.
  ENDLOOP.

ENDFORM.                               " RIEPILOGO
   
   
*&---------------------------------------------------------------------*
*&      Form  TOTALE_RIEPILOGO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM totale_riepilogo.

  ADD   itab_riepilogo-impon  TO    vn_impon_riep.
  ADD   itab_riepilogo-iva    TO    vn_iva_riep.
  ADD   itab_riepilogo-bollo  TO    vn_bollo_riep.
  ADD   itab_riepilogo-totale TO    vn_totale_riep.
  ADD   itab_riepilogo-riten  TO    vn_rit_riep.


ENDFORM.                               " TOTALE_RIEPILOGO

   
   
*&---------------------------------------------------------------------*
*&      Form  PULIZIA_RIEP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM pulizia_riep.

  CLEAR: vn_impon_riep,
         vn_iva_riep,
         vn_bollo_riep,
         vn_totale_riep,
         vn_rit_riep,
         va_impon_riep,
         va_iva_riep,
         va_bollo_riep,
         va_totale_riep,
         va_rit_riep.

ENDFORM.                               " PULIZIA_RIEP

   
   
*&---------------------------------------------------------------------*
*&      Form  TOP_RIEPILOGO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM top_riepilogo.
  FORMAT COLOR 1 INTENSIFIED OFF.
  ADD 1 TO w_page. "Gestione paginazione - mod.09/10/2003
   
   
*& Gestione nuova intestazione testata - mod.09/10/2003
*  CONCATENATE text-001 text-028 INTO w_text_tit1.                 "RM161215D
   
   
  SELECT SINGLE * FROM zint_regiva WHERE bukrs = p_bukrs.   "RM161215I
  CONCATENATE zint_regiva-zintestazione text-028 INTO w_text_tit1. "RM161215I

   
   
*  concatenate 'Pag.:' sy-datum(4) '/' w_page into w_text_tit2.
   
   
  CONCATENATE 'Pag.:' s_budat-high(4) '/' w_page INTO w_text_tit2.
   
   
* INIZIO MOD T23880651 02.01.2014 DM
*  WRITE: /63 w_text_tit1 CENTERED, 240 ' '.
   
   
  WRITE: /63 w_text_tit1 CENTERED, 239 ' '.
   
   
* FINE MOD T23880651 02.01.2014 DM
   
   
  WRITE: w_text_tit2.
   
   
*  WRITE:/63 TEXT-001 CENTERED,
*          255 ' '.
   
   
  WRITE: /1 ' ', 255 ' '.
  CONCATENATE 'Riepilogo' w_testo INTO w_text_tit3 SEPARATED BY ' '.
   
   
*  write:/117 text-021 centered, 255 ' '.
   
   
  WRITE: /62 w_text_tit3 CENTERED, 255 ' '.
  WRITE: /1 ' ', 180 ' '.
  WRITE:/110 text-003 ,
          s_budat-low,
          ' - ' ,
          s_budat-high,
          255 ' '.

  WRITE: /1(255) sy-uline.
  FORMAT COLOR OFF.
   
   
* intestazione colonne
   
   
  FORMAT COLOR 1 INTENSIFIED ON.
  WRITE:/ text-009,                    "% IVA
          text-022,                    "C.iva / esclus
          60 text-008,                 "IMPONIBILE
          90 text-010,                 "IMPORTO IVA
          116 text-011,                "BOLLO
          125 text-012,                "TOTALE
   
   
*          214 text-019,                "Riten
   
   
          255 ' '.
  WRITE:/ sy-uline.

ENDFORM.                               " TOP_RIEPILOGO

   
   
*&---------------------------------------------------------------------*
*&      Form  SCRIVO_TOTALI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM scrivo_totali.

  WRITE:/1(255) sy-uline.
  WRITE:/ text-023,
              vn_impon_riep CURRENCY t001-waers UNDER text-008,
              vn_iva_riep CURRENCY t001-waers UNDER text-010.
  WRITE       vn_bollo_riep CURRENCY t001-waers TO va_bollo.
  WRITE:      AT 114 va_bollo,
              AT 132 vn_totale_riep CURRENCY t001-waers.
   
   
*              vn_rit_riep CURRENCY t001-waers UNDER text-019.

* PREPARO I TOTALI PER IL MODULO SAPSCRIPT
   
   
  WRITE: vn_impon_riep CURRENCY t001-waers   TO     va_impon_riep_s.
  WRITE: vn_iva_riep CURRENCY t001-waers     TO     va_iva_riep_s.
  WRITE: vn_bollo_riep CURRENCY t001-waers   TO     va_bollo_riep_s.
  WRITE: vn_totale_riep CURRENCY t001-waers  TO     va_totale_riep_s .
  WRITE: vn_rit_riep CURRENCY t001-waers     TO     va_rit_riep_s.



ENDFORM.                               " SCRIVO_TOTALI

   
   
*&---------------------------------------------------------------------*
*&      Form  STAMPA_MODULO_RIEPILOGO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM stampa_modulo_riepilogo.


  PERFORM pulizia_riep.
   
   
*Inserisco il commento per togliere l'ultima  pagina al sapscript*******
   
   
  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA4_NE'.
   
   
*
   
   
  ADD 1 TO w_page_stampa.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'RIEPILOGO'
      window  = 'HEADER'.


  LOOP AT itab_riepilogo.

    WRITE: itab_riepilogo-impon CURRENCY t001-waers   TO   va_impon_riep.
    WRITE: itab_riepilogo-iva CURRENCY t001-waers     TO   va_iva_riep.
    WRITE: itab_riepilogo-bollo CURRENCY t001-waers   TO   va_bollo_riep.
    WRITE: itab_riepilogo-totale CURRENCY t001-waers  TO   va_totale_riep.
    WRITE: itab_riepilogo-riten CURRENCY t001-waers   TO   va_rit_riep.

    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element = 'ITEM_RIEPILOGO'
        window  = 'MAIN'.

  ENDLOOP.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'TOTALI_RIEPILOGO'
      window  = 'MAIN'.

  CALL FUNCTION 'END_FORM' .

   
   
* scrivo i totali per settore merceologico
   
   
  PERFORM pulizia_riep.

  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA4_NE'.

   
   
*  CALL FUNCTION 'WRITE_FORM'
*       EXPORTING
*            ELEMENT = 'RIEPILOGO_MERC'
*            WINDOW  = 'HEADER'.
*
*
*  LOOP AT ITAB_MERC.
*
*    WRITE: ITAB_MERC-IMPON CURRENCY T001-WAERS   TO   VA_IMPON_RIEP.
*    WRITE: ITAB_MERC-IVA CURRENCY T001-WAERS     TO   VA_IVA_RIEP.
*    WRITE: ITAB_MERC-BOLLO CURRENCY T001-WAERS   TO   VA_BOLLO_RIEP.
*    WRITE: ITAB_MERC-TOTALE CURRENCY T001-WAERS  TO   VA_TOTALE_RIEP.
*    WRITE: ITAB_MERC-RITEN CURRENCY T001-WAERS   TO   VA_RIT_RIEP.
*
*    CALL FUNCTION 'WRITE_FORM'
*         EXPORTING
*              ELEMENT = 'ITEM_RIEPILOGO_MERC'
*              WINDOW  = 'MAIN'.
*
*  ENDLOOP.
*
*  CALL FUNCTION 'WRITE_FORM'
*       EXPORTING
*            ELEMENT = 'TOTALI_RIEPILOGO'
*            WINDOW  = 'MAIN'.
*
*  CALL FUNCTION 'END_FORM'  .

   
   
ENDFORM.                               " STAMPA_MODULO_RIEPILOGO
   
   
*&---------------------------------------------------------------------*
*&      Form  RIEMPIO_ITAB_TAX
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM riempio_itab_tax.

  CLEAR itab.
  READ TABLE itab_rit WITH KEY opbel = dfkkko-opbel.
  IF sy-subrc = 0.
    MOVE-CORRESPONDING itab_rit TO itab.

    itab-blart = dfkkko-blart.         "Tipo documento
    IF p_datare = 'X'.
      itab-budat = dfkkko-budat.       "Data documento
      itab-opbel = dfkkko-opbel.       "Numero documento
    ELSE.
      itab-budat = dfkkko-bldat.       "Data documento nel doc
      itab-opbel = dfkkko-xblnr(12).   "Numero documento di rif
    ENDIF.
    itab-gpart = dfkkop-gpart.         "Codice cliente
    itab-waers = dfkkop-waers.         "Divisa transazione
    itab-kofiz = dfkkop-kofiz.         "Caratt. det. conti
    itab-mwskz = dfkkopk-mwskz.        "Codice IVA

    itab-riten = itab_rit-betrh * -1 .
    itab-riten_t = itab_rit-betrw * -1 .
    APPEND itab.
  ENDIF.

  CLEAR itab.
  READ TABLE itab_rit WITH KEY opbel = dfkkko-opbel.
  IF sy-subrc = 0.
    itab-bollo_int = itab_bollo-sbash. "Importo bollo divisa interna
    itab-bollo_tra = itab_bollo-sbasw.   "Importo bollo divisa transazione
    itab-blart = dfkkko-blart.         "Tipo documento
    IF p_datare = 'X'.
      itab-budat = dfkkko-budat.       "Data documento
      itab-opbel = dfkkko-opbel.       "Numero documento
    ELSE.
      itab-budat = dfkkko-bldat.       "Data documento nel doc
      itab-opbel = dfkkko-xblnr(12).   "Numero documento di rif
    ENDIF.
    itab-gpart = dfkkop-gpart.         "Codice cliente
    itab-waers = dfkkop-waers.         "Divisa transazione
    itab-kofiz = dfkkop-kofiz.         "Caratt. det. conti
    itab-mwskz = dfkkopk-mwskz.        "Codice IVA
    APPEND itab.
  ENDIF.
ENDFORM.                               " RIEMPIO_ITAB_TAX
   
   
*&---------------------------------------------------------------------*
*&      Form  ITAB_RIEPILOGO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM itab_riepilogo.

  MOVE itab-perc  TO itab_riepilogo-perc.
  MOVE itab-mwskz TO itab_riepilogo-mwskz.
  MOVE itab-text1 TO itab_riepilogo-text1.
  MOVE itab-betrh TO itab_riepilogo-impon.
  MOVE itab-sbeth TO itab_riepilogo-iva.
  MOVE itab-bollo_int TO itab_riepilogo-bollo.
  MOVE itab-riten TO itab_riepilogo-riten.
  MOVE itab-totale TO itab_riepilogo-totale.
  COLLECT itab_riepilogo.

ENDFORM.                               " ITAB_RIEPILOGO

   
   
*&---------------------------------------------------------------------*
*&      Form  ITAB_MERC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM itab_merc.

  MOVE itab-spart  TO itab_merc-spart.
  MOVE itab-betrh TO itab_merc-impon.
  MOVE itab-sbeth TO itab_merc-iva.
  MOVE itab-bollo_int TO itab_merc-bollo.
  MOVE itab-riten TO itab_merc-riten.
  MOVE itab-totale TO itab_merc-totale.
  COLLECT itab_merc.

ENDFORM.                               " ITAB_MERC
   
   
*&---------------------------------------------------------------------*
*&      Form  TOP_RIEP_MERC
*&---------------------------------------------------------------------*
*       Top del riepilogo per settore merceologico
*----------------------------------------------------------------------*
   
   
FORM top_riep_merc.

   
   
*  FORMAT RESET.
*  FORMAT COLOR 1 INTENSIFIED OFF.
*  WRITE:/63 TEXT-001 CENTERED,
*          255 ' '.
*  WRITE: /1 ' ', 255 ' '.
*  .
*  WRITE:/110 TEXT-025 CENTERED, 255 ' '.
*  WRITE: /1 ' ', 180 ' '.
*  WRITE:/110 TEXT-003 ,
*          S_BUDAT-LOW,
*          ' - ' ,
*          S_BUDAT-HIGH,
*          255 ' '.
*
*  WRITE: /1(255) SY-ULINE.
*  FORMAT COLOR OFF.
** intestazione colonne
*  FORMAT COLOR 1 INTENSIFIED ON.
*  WRITE:/ TEXT-026,                    "Cod. Sett.
*          TEXT-027,                    "Descrizione settore merc
*          60 TEXT-008,                 "IMPONIBILE
*          90 TEXT-010,                 "IMPORTO IVA
*          120 TEXT-011,                "BOLLO
*          150 TEXT-012,                "TOTALE
*          180 TEXT-019,                "Riten
*          255 ' '.
*  WRITE:/ SY-ULINE.

   
   
ENDFORM.                               " TOP_RIEP_MERC

   
   
*&---------------------------------------------------------------------*
*&      Form  TOTALE_RIEPILOGO_MERC
*&---------------------------------------------------------------------*
   
   
FORM totale_riepilogo_merc.

  ADD   itab_merc-impon  TO    vn_impon_riep.
  ADD   itab_merc-iva    TO    vn_iva_riep.
  ADD   itab_merc-bollo  TO    vn_bollo_riep.
  ADD   itab_merc-totale TO    vn_totale_riep.
  ADD   itab_merc-riten  TO    vn_rit_riep.

ENDFORM.                               " TOTALE_RIEPILOGO_MERC
   
   
*&---------------------------------------------------------------------*
*&      Form  CARICA_VALORI
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM carica_valori.

  SELECT SINGLE * FROM zreg_iva WHERE ca_soc = p_bukrs
                                AND tipo = p_treg.
  ca_iva       = zreg_iva-ca_iva.
  ca_bollo     = zreg_iva-ca_bollo .
  ca_lett      = zreg_iva-ca_lett.
  ca_prezzi    = zreg_iva-ca_prezzi.
  ca_hkont     = zreg_iva-ca_hkont.

ENDFORM.                               " CARICA_VALORI
   
   
*&---------------------------------------------------------------------*
*&      Form  FORMATTA_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM formatta_data.
  LOOP AT itab .
    MOVE-CORRESPONDING itab TO itab1.
    REPLACE '.'
                WITH '/' INTO itab1-budat.
   
   
*    append to itab1.
   
   
  ENDLOOP.

ENDFORM.                               " FORMATTA_DATA

   
   
*&---------------------------------------------------------------------*
*&      Form  TORVO_IMPOSTA_BOLLO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM torvo_imposta_bollo.
  MOVE dfkkko-opbel+2(10) TO opbel.
  SELECT SINGLE * FROM vbrk WHERE vbeln = opbel.
  SELECT SINGLE *  FROM konv WHERE knumv = vbrk-knumv AND
                                   kschl = 'BOLL'.
  IF sy-subrc = 0.
    MOVE konv-kbetr TO imposta_bollo.
    MOVE konv-waers TO valuta_bollo.
    itab_bollo-opbel(2) = '00'.        "PROVA ROVERI
    itab_bollo-opbel+2 = opbel.        "PROVA ROVERI
    itab_bollo-mwskz = 'L5'.           "PROVA ROVERI
    PERFORM converti_importo_in_euro.
    MOVE valore_bollo TO itab_bollo-sbash .
    itab_bollo-sbasw = imposta_bollo.
    IF NOT imposta_bollo IS INITIAL.
      APPEND itab_bollo.
    ENDIF.
  ENDIF.
ENDFORM.                               " TORVO_IMPOSTA_BOLLO
   
   
*&---------------------------------------------------------------------*
*&      Form  CONVERTI_IMPORTO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM converti_importo_in_euro.
  IF konv-waers NE 'EUR'.
    CALL FUNCTION 'CONVERT_AMOUNT_TO_CURRENCY'
      EXPORTING
        date             = sy-datum
        foreign_currency = konv-waers
        foreign_amount   = imposta_bollo
        local_currency   = 'EUR'
      IMPORTING
        local_amount     = valore_bollo.
   
   
*    TABLES
*         T_C_ERRORS       =
*    EXCEPTIONS
*         ERROR            = 1
*         OTHERS           = 2
   
   
    .
    tredici = valore_bollo(13). due = valore_bollo+13(2).
    CLEAR valore_bollo.

    CONCATENATE tredici due INTO valore_bollo SEPARATED BY '.'.
    IF valore_bollo = '. 0'.
      CLEAR valore_bollo.
      MOVE '0' TO valore_bollo.
    ENDIF.
  ELSE.
    valore_bollo = imposta_bollo.
  ENDIF.
ENDFORM.                               " CONVERTI_IMPORTO_in_euro
   
   
*&---------------------------------------------------------------------*
*&      Form  DESCRIZIONE_CODICE_BOLLO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM descrizione_codice_bollo.
  LOOP AT itab_bollo.
    CLEAR t007s.
    SELECT SINGLE * FROM t007s WHERE spras = 'ITL'
                                 AND kalsm = ca_prezzi
                                 AND mwskz = itab_bollo-mwskz.
    MOVE t007s-text1 TO itab_bollo-text1.
    IF itab_bollo-sbash < 0.
      itab_bollo-sbash = itab_bollo-sbash * -1.
    ENDIF.
    IF itab_bollo-sbasw < 0 .
      itab_bollo-sbasw = itab_bollo-sbasw * -1.
    ENDIF.
    MODIFY itab_bollo.
  ENDLOOP.
  SORT itab_bollo BY opbel.
  SORT itab_rit BY opbel.

ENDFORM.                               " DESCRIZIONE_CODICE_BOLLO
   
   
*&---------------------------------------------------------------------*
*&      Form  CONTROLLO_MESE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM controllo_mese.

   
   
* controllo che le date inserite siano un mese.
   
   
  DATA: my_budat LIKE sy-datum.
  DATA: my_budata LIKE sy-datum.
  DATA: app_mese(10) TYPE n.
  DATA: budat_ul LIKE sy-datum.

  IF s_budat-low+6(2) NE '01'.
    SET CURSOR FIELD 'S_BUDAT-LOW'.
    MESSAGE e162(00) WITH 'La data deve essere il 1° del mese'.
  ENDIF.

  my_budat =  s_budat-low + 40.
  my_budat+6(2) = '01'.
  my_budata = my_budat - 1.

  IF s_budat-high NE my_budata.
    SET CURSOR FIELD 'S_BUDAT-HIGH'.

    MESSAGE e368(00) WITH
      'La data di fine deve essere l''ultimo del mese' s_budat-low+4(2).
  ENDIF.


   
   
* controllo l'ultima data elaborata.

   
   
  SELECT SINGLE * FROM zivadate_el WHERE budatda EQ s_budat-low
                                   AND   budata  EQ s_budat-high
                                   AND   flg_att EQ flg_att
                                   AND     bukrs  = p_bukrs.
  IF sy-subrc = 0.
    MESSAGE i208(00) WITH 'Data già elaborata'.
  ENDIF.

   
   
*controllo mese consecutivo.

   
   
  CLEAR my_budata.
  CLEAR my_budat.

  SELECT MAX( budatda ) INTO budat_ul FROM zivadate_el
                        WHERE flg_att = flg_att
                        AND     bukrs  = p_bukrs.
  my_budat = budat_ul + 40.
  my_budat+6(2) = '01'.
  IF s_budat-low NE my_budat.
    CONCATENATE 'Mese:'  budat_ul+4(2) 'Anno:'  budat_ul(4)
    INTO my_str SEPARATED BY space.
    MESSAGE i368(00) WITH 'Il mese non è consecutivo, ultimo stampato'
                                   my_str.
  ENDIF.

ENDFORM.                               " CONTROLLO_MESE
   
   
*&---------------------------------------------------------------------*
*&      Form  VERIFICA_RAGIONE_SOCIALE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM verifica_ragione_sociale.
   
   
*  REFRESH MOD_RS.
*  MOD_RS-SIGN = 'I'.
**  MOD_RS-OPTION = 'BT'.
*  MOD_RS-OPTION = 'GE'.
*  MOD_RS-LOW = ITAB-BUDAT.
**  MOD_RS-HIGH = SY-DATUM.
*  APPEND MOD_RS.
*
*  SELECT * FROM  CDHDR CLIENT SPECIFIED
*        WHERE   OBJECTCLAS  = 'BUPA_BUP'
*         AND    MANDANT     = SY-MANDT
*         AND    OBJECTID    =  ITAB-GPART
*         AND    UDATE       IN  MOD_RS
*         ORDER BY UDATE.
*    IF SY-SUBRC EQ 0.
*      SELECT SINGLE       * FROM  CDPOS  CLIENT SPECIFIED
*             WHERE  OBJECTCLAS  = 'BUPA_BUP'
*             AND    MANDANT     = SY-MANDT
*             AND    OBJECTID    = ITAB-GPART
*             AND    CHANGENR    = CDHDR-CHANGENR
*             AND    TABNAME     = 'BUT000'
*             AND    FNAME       = 'NAME_ORG1'.
*      IF SY-SUBRC EQ 0.
*         ITAB_CLIENTE-NAME1 = CDPOS-VALUE_OLD .
*         EXIT.
*      ENDIF.
*    ENDIF.
*
*  ENDSELECT.

   
   
  DATA: mestab LIKE symsg OCCURS 4,
        w_flag.

  IF itab_cliente-type NE '1'.         "Organizzazione
    SUPPLY objectid    = itab-gpart
            udate      = itab-budat
            tabname    = 'BUT000'
            fname      = 'NAME_ORG1'
            objectclas = 'BUPA_BUP'
            chngind    = 'U'
            TO CONTEXT cx_ragsoc.

    DEMAND  value_old   = cdpos-value_old FROM CONTEXT cx_ragsoc
            MESSAGES INTO mestab.
    IF sy-subrc = 0.
      itab_cliente-name1 = cdpos-value_old.
    ENDIF.
  ELSE.                                "Persona Fisica
    SUPPLY objectid    = itab-gpart
            udate      = itab-budat
            tabname    = 'BUT000'
            fname      = 'NAME_FIRST'
            objectclas = 'BUPA_BUP'
            chngind    = 'U'
            TO CONTEXT cx_ragsoc.

    DEMAND  value_old   = cdpos-value_old FROM CONTEXT cx_ragsoc
            MESSAGES INTO mestab.
    IF sy-subrc = 0.
      itab_cliente-name_first = cdpos-value_old.
      w_flag = 'X'.
    ENDIF.
    SUPPLY objectid    = itab-gpart
            udate      = itab-budat
            tabname    = 'BUT000'
            fname      = 'NAME_LAST'
            objectclas = 'BUPA_BUP'
            chngind    = 'U'
            TO CONTEXT cx_ragsoc.

    DEMAND  value_old   = cdpos-value_old FROM CONTEXT cx_ragsoc
            MESSAGES INTO mestab.
    IF sy-subrc = 0.
      itab_cliente-name_last = cdpos-value_old.
      w_flag = 'X'.
    ENDIF.
    IF w_flag = 'X'.
      CONCATENATE itab_cliente-name_first itab_cliente-name_last
                 INTO itab_cliente-name1 SEPARATED BY space.
    ENDIF.
  ENDIF.
ENDFORM.                               " VERIFICA_RAGIONE_SOCIALE
   
   
*----------------------------------------------------------------------*
*        Start new screen                                              *
*----------------------------------------------------------------------*
   
   
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                    "BDC_DYNPRO
   
   
*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
   
   
FORM bdc_field USING fnam fval.
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
ENDFORM.                    "BDC_FIELD
   
   
*&---------------------------------------------------------------------*
*&      Form  CALL_TRANSACTION
*&---------------------------------------------------------------------*
*& Gestione della visualiz. spool in modalità effettivo- mod.09/10/2003*
*----------------------------------------------------------------------*
   
   
FORM call_transaction.

  CALL TRANSACTION 'SP01' AND SKIP FIRST SCREEN.

ENDFORM.                    " CALL_TRANSACTION
   
   
*&---------------------------------------------------------------------*
*&      Form  CERCA-DATI
*&---------------------------------------------------------------------*
   
   
FORM cerca-dati.
  REFRESH: s_opbel.", s_blart.
   
   
*CR 15.12.2015
   
   
  IF  NOT flg_att IS INITIAL.
    SELECT SINGLE * FROM zcod_var WHERE cod_atti EQ flg_att.
    IF sy-subrc NE 0.
      MESSAGE e368(00) WITH 'Tipo attività inesistente'.
    ELSE.
   
   
* Inizio inser. RM290116
   
   
      DATA: BEGIN OF lt_exbel OCCURS 0,
              exbel LIKE dfkkinvdoc_h-exbel,
            END OF  lt_exbel.
      CLEAR lt_exbel[].
      lt_exbel    = zcod_var-from_nmr.
      APPEND lt_exbel.
      lt_exbel    = zcod_var-to_nmr.
      APPEND lt_exbel.

      LOOP AT  lt_exbel WHERE exbel IN s_exbel.
        EXIT.
      ENDLOOP.
      IF sy-subrc NE 0.
        MESSAGE e368(00) WITH 'Tipo attività incongruente'.
      ENDIF.
   
   
* Fine inser. RM290116

   
   
      SELECT SINGLE * FROM nriv WHERE object EQ 'FKK_BELEG' AND
                                    fromnumber EQ zcod_var-from_nmr AND
                                      tonumber EQ zcod_var-to_nmr.
      IF sy-subrc EQ 0.

        w_testo = zcod_var-cod_testo.
   
   
*CR 15.12.2015  INIZIO
*      CLEAR: s_opbel.
*
*      MOVE 'I' TO s_exbel-sign.
*      MOVE 'BT' TO s_exbel-option.
*      MOVE nriv-fromnumber TO s_exbel-low.
*      MOVE nriv-tonumber TO s_exbel-high.
*      APPEND s_opbel.
*      CLEAR: s_opbel.
*CR 15.12.2015  FINE
   
   
      ELSE.
   
   
* Inizio ADD Txxxxxxx CR PTDK924711 15.02.2011 DM
* Con questo codice viene permessa l'esecuzione dei registri
* per mesi legati ad anni precedenti mantenendo l'intestazione


   
   
        w_testo = zcod_var-cod_testo.
   
   
*CR 15.12.2015  INIZIO
*      CLEAR: s_exbel.
*      MOVE 'I' TO s_exbel-sign.
*      MOVE 'BT' TO s_exbel-option.
*      MOVE zcod_var-from_nmr TO s_exbel-low.
*      MOVE zcod_var-to_nmr TO s_exbel-high.
*      APPEND s_exbel.
*      CLEAR: s_exbel.
*CR 15.12.2015  FINE
* Fine ADD Txxxxxxx CR PTDK924711 15.02.2011 DM

*      select * from tfk003 where numkr eq nriv-nrrangenr.
*        if sy-subrc eq 0.
*          move 'I' to s_blart-sign.
*          move 'EQ' to s_blart-option.
*          move tfk003-blart to s_blart-low.
*          append s_blart.
*          clear: s_blart.
*        endif.
*      endselect.
*      select * from tfk003b where numkr eq nriv-nrrangenr.
*        if sy-subrc eq 0.
*          move 'I' to s_blart-sign.
*          move 'EQ' to s_blart-option.
*          move tfk003b-blart to s_blart-low.
*          append s_blart.
*          clear: s_blart.
*        endif.
*      endselect.

   
   
      ENDIF.
    ENDIF.
  ENDIF.
  SORT s_blart BY low.
  DELETE ADJACENT DUPLICATES FROM s_blart.
  SET SCREEN 1000.
ENDFORM.                    " CERCA-DATI
   
   
*&---------------------------------------------------------------------*
*&      Form  CARICAMENTO-ESENTE_IVA
*&---------------------------------------------------------------------*
   
   
FORM caricamento-esente_iva.
  SELECT * FROM dfkkopk           "OPBEL MWSKZ SBASH SBASW FROM DFKKOPK
                WHERE bukrs = p_bukrs
                AND opbel = dfkkko-opbel
                AND hkont IN itab_conto.

   
   
*
   
   
    CLEAR cechk_itab.

    READ TABLE itab WITH KEY opbel = dfkkko-opbel
                             mwskz = dfkkopk-mwskz.
    IF sy-subrc NE 0.
      CLEAR: controlla_bollo, controlla_ritenuta.
   
   
* trovo il codice cliente
   
   
      CLEAR dfkkop.
      SELECT SINGLE * FROM dfkkop WHERE ( opbel EQ dfkkko-opbel OR
                                          augbl EQ dfkkko-opbel )
                                      AND bukrs = p_bukrs
   
   
*                                     and budat eq dfkkko-budat
   
   
                                      AND spart IN s_spart.
      CHECK sy-subrc = 0.
      CLEAR t001.
      SELECT SINGLE * FROM t001 WHERE bukrs = p_bukrs.
   
   
*     trovo i dati relativi all'iva
   
   
      CLEAR t007s.
      SELECT SINGLE * FROM t007s WHERE spras = 'ITL'
                                   AND kalsm = ca_prezzi
                                   AND mwskz = dfkkopk-mwskz.
      CLEAR itab_esente.
      CLEAR vn_perc.

   
   
* DFKKKO
   
   
      itab_esente-blart = dfkkko-blart.           "Tipo documento

      IF p_datare = 'X'.
        itab_esente-budat = dfkkko-budat.         "Data documento
        itab_esente-opbel = dfkkko-opbel.         "Numero documento
      ELSE.
        itab_esente-budat = dfkkko-bldat.         "Data documento nel doc
        itab_esente-opbel = dfkkko-xblnr(12).     "Numero documento di rif
      ENDIF.

   
   
* DFKKOP
   
   
      itab_esente-gpart = dfkkop-gpart.           "Codice cliente
      itab_esente-waers = dfkkop-waers.           "Divisa transazione
      itab_esente-kofiz = dfkkop-kofiz.           "Caratt. det. conti
      itab_esente-spart = dfkkop-spart.           "Settore merceologico

   
   
* DFKKOPK
   
   
      itab_esente-mwskz = dfkkopk-mwskz.          "Codice IVA
      itab_esente-text1 = t007s-text1.            "Descrizione codice iva
      itab_esente-betrh = dfkkopk-sbash * -1. "Imponibile divisa interna
      itab_esente-betrw = dfkkopk-sbasw * -1. "Imponibile divisa transazione
   
   
*  itab_esente-sbeth = dfkkopk-betrh * -1 ."Importo iva divisa interna
   
   
      itab_esente-sbetw = dfkkopk-betrw * -1 ."Importo iva divisa transaz
   
   
* calcolo la percentuale dell'iva
   
   
      IF dfkkopk-stprz NE space.
        vn_perc = dfkkopk-stprz / 1000.
        WRITE vn_perc TO itab_esente-perc(3).
        WRITE '%' TO itab_esente-perc+3(1).
      ENDIF.
   
   
* totale divisa interna
   
   
      itab_esente-totale = itab_esente-betrh + itab_esente-sbeth.
   
   
* totale divisa transazione
   
   
      itab_esente-totale2 = itab_esente-betrw + itab_esente-sbetw.
   
   
*
*      itab_esente-betrh = itab_esente-sbeth.
   
   
      itab_esente-betrh = dfkkopk-betrh * - 1.
      itab_esente-totale = dfkkopk-betrh * - 1.

      COLLECT itab_esente.
    ENDIF.
  ENDSELECT.
  DATA: app_bollo.

  LOOP AT itab_esente.
    CLEAR itab_bis.
    itab_bis = itab_esente.
    READ TABLE itab_bollo WITH KEY opbel = itab_esente-opbel.
    IF sy-subrc = 0 AND app_bollo IS INITIAL.
      app_bollo = 'X'.
      CLEAR itab.
      itab-opbel = itab_bis-opbel.
      itab-budat = itab_bis-budat.
      itab-blart = itab_bis-blart.
      itab-gpart = itab_bis-gpart.
      itab-spart = itab_bis-spart.
      itab-waers = itab_bis-waers.
      itab-mwskz = itab_bollo-mwskz.
      itab-text1 = itab_bollo-text1.
      itab-bollo_int = itab_bollo-sbash. "Importo bollo divisa in
      itab-bollo_tra = itab_bollo-sbasw. "Importo bollo divisa tr
   
   
* totale divisa interna
   
   
      itab-totale =  itab-bollo_int.
   
   
* totale divisa transazione
   
   
      itab-totale2 =  itab-bollo_tra .
      APPEND itab.
    ENDIF.
    CLEAR itab.
    MOVE-CORRESPONDING itab_esente TO itab.
    APPEND itab.
   
   
* trovo i dati relativi al cliente.
   
   
    PERFORM dati_cliente.
  ENDLOOP.
  CLEAR app_bollo.
  REFRESH itab_esente.
ENDFORM.                    " CARICAMENTO-ESENTE_IVA
   
   
*&---------------------------------------------------------------------*
*&      Form  ZIB_EXTRACTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM zib_extraction TABLES wt_itab STRUCTURE itab.
   
   
* Esegue solo se impostata l'apposita selezione in input
   
   
  IF NOT p_zib IS INITIAL.
   
   
* Dichiarazione variabili di comodo
   
   
    DATA: wt_export TYPE TABLE OF zitab,
          wa_export TYPE zitab.
   
   
* Valorizzo tabella di trasmissione
   
   
    LOOP AT wt_itab.
      MOVE-CORRESPONDING wt_itab TO wa_export.
      COLLECT wa_export INTO wt_export.
      CLEAR wa_export.
    ENDLOOP.
   
   
* Eseguo chiamata alla funzione di sincronizzazione dei dati
   
   
    call function 'ZIB_ESTR_DATI_DA_ZREG'
      EXPORTING
        i_bukrs          = p_bukrs
        i_running_report = sy-cprog
        i_tipo_registro  = p_zib_tr
      TABLES
        i_itab           = wt_export.
  ENDIF.
ENDFORM.                    " ZIB_EXTRACTION
   
   
*&---------------------------------------------------------------------*
*&      Form  check_p_zib_tr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM check_p_zib_tr.
  CHECK NOT p_zib IS INITIAL.
  DATA wa_t9tiporegistro TYPE t9tiporegistro.
  SELECT SINGLE * INTO wa_t9tiporegistro FROM t9tiporegistro WHERE
         tipo_registro EQ p_zib_tr AND
         report        EQ sy-cprog.
  IF sy-subrc NE 0.
    MESSAGE i003(zib) WITH p_zib_tr sy-cprog.
    STOP.
  ENDIF.
ENDFORM.                    " check_p_zib_tr
   
   
*&---------------------------------------------------------------------*
*&      Form  converte_to_pdf
*&---------------------------------------------------------------------*
*       ROUTINE PER CONVERSIONE DEL SAPSCRIPT IN PDF
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM converte_to_pdf .

  CLEAR zitcoo.
  LOOP AT zitcoo.
    CONCATENATE zitcoo-tdprintcom zitcoo-tdprintpar INTO t_otfdata2-line.
    APPEND t_otfdata2. CLEAR t_otfdata2.
  ENDLOOP.

  t_otfdata3[] = t_otfdata2[] .
   
   
*Start MEV110408 dematerializzazione reg IVA ind37or
   
   
  IF p_cpx = 'X'.

    CALL FUNCTION 'SX_OBJECT_CONVERT_OTF_PDF'
      EXPORTING
        format_src   = 'OTF'
        format_dst   = 'PDF'
      CHANGING
        transfer_bin = ztransfer_bin
        content_txt  = t_otfdata3
        content_bin  = t_pdfdata1
        objhead      = t_otfdata3
        len          = lv_length.

    IF sy-subrc EQ 0.

      LOOP AT t_pdfdata1 INTO wa_pdfdata1.
   
   
*            t_pdfdata = wa_pdfdata1.
   
   
        MOVE-CORRESPONDING wa_pdfdata1 TO t_pdfdata.

        APPEND t_pdfdata.
      ENDLOOP.
    ENDIF.
  ENDIF.

   
   
*End mod

*Inizio Modifica MMorgante pdf
   
   
  DATA: lt_doc TYPE STANDARD TABLE OF docs.
  DATA: lt_line TYPE STANDARD TABLE OF tline.
  DATA: ls_line TYPE tline.
  DATA: filesize TYPE i.
  DATA:   p_file LIKE rlgrap-filename VALUE'C:\temp\file03.pdf'.
  DATA cancel.

  IF p_cpx = 'X'.
    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = 'PDF'
      IMPORTING
        bin_filesize          = filesize
        bin_file              = lv_bin_file
      TABLES
        otf                   = zitcoo
        lines                 = lt_line
      EXCEPTIONS
        err_conv_not_possible = 1
        err_bad_otf           = 2.
  ENDIF.

  IF p_pdf = 'X'.
    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = 'PDF'
      IMPORTING
        bin_filesize          = filesize
   
   
*       bin_file              = lv_bin_file
   
   
      TABLES
        otf                   = zitcoo
        lines                 = lt_line
      EXCEPTIONS
        err_conv_not_possible = 1
        err_bad_otf           = 2.
  ENDIF.

  lv_filesize = filesize.


   
   
*perform download_w_ext(RSTXPDFT) tables lt_line
*                                 using p_file
*                                       '.pdf'
*                                       'BIN'
*                                       filesize
*                                       cancel.

*  CALL FUNCTION 'CONVERT_OTF_2_PDF'
**   EXPORTING
**     USE_OTF_MC_CMD               = 'X'
**     ARCHIVE_INDEX                =
**   IMPORTING
**     BIN_FILESIZE                 =
*    TABLES
*      otf            = zitcoo
*      doctab_archive = lt_doc
*      lines          = lt_line
*  exceptions
*    err_conv_not_possible        = 1
*    err_otf_mc_noendmarker       = 2
*    others                       = 3.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.



*  CALL FUNCTION 'SX_OBJECT_CONVERT_OTF_PDF'
*    EXPORTING
*      format_src   = 'OTF'
*      format_dst   = 'PDF'
*    CHANGING
*      transfer_bin = ztransfer_bin
*      content_txt  = t_otfdata3
*      content_bin  = t_pdfdata1
*      objhead      = t_otfdata3
*      len          = lv_length.
*  IF sy-subrc EQ 0.
*    DATA: lw_xstring TYPE xstring.
*    DATA: lw_string TYPE string.
*    DATA: lw_lenght TYPE i.
*    lw_lenght = lv_length.
*    DATA: lw_tb TYPE solix_tab."bapiconten.
*    DATA: lw_str LIKE LINE OF t_pdfdata1.
**    DATA: lw_tbht TYPE rrxw3_t_html.
**    DATA: lw_str1 TYPE w3html.
**    LOOP AT t_pdfdata1 INTO wa_pdfdata1.
**      lw_str-line = wa_pdfdata1-line.
**      APPEND lw_str TO lw_tb.
***      lw_str1 = lw_str.
****      move wa_pdfdata1 to lw_str.
***      t_pdfdata = lw_str1.
**      CALL FUNCTION 'RRXWS_RAW_TO_CHAR'
**        EXPORTING
**          i_t_raw_data = lw_tb
**        IMPORTING
**          e_t_html     = lw_tbht.
**      READ TABLE lw_tbht INTO lw_str1 INDEX 1.
**      IF sy-subrc = 0.
**        t_pdfdata = lw_str1-line.
***      t_pdfdata = wa_pdfdata1.
**        APPEND t_pdfdata.
**      ENDIF.
**      CLEAR: lw_str, lw_tb.
**    ENDLOOP.
*
*    LOOP AT t_pdfdata1 INTO wa_pdfdata1.
*      lw_str-line = wa_pdfdata1-line.
*      APPEND lw_str TO lw_tb.
*
*      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
*        EXPORTING
*          input_length = lw_lenght
*        IMPORTING
*          buffer       = lw_xstring
*        TABLES
*          binary_tab   = lw_tb
*        EXCEPTIONS
*          failed       = 1
*          OTHERS       = 2.
*
*      DATA: lr_conv TYPE REF TO cl_abap_conv_in_ce.
*      CALL METHOD cl_abap_conv_in_ce=>create
*        EXPORTING
*          input       = lw_xstring
*          encoding    = 'UTF-8'
*          replacement = ' '
*          ignore_cerr = abap_true
*        RECEIVING
*          conv        = lr_conv.
*
*      CALL METHOD lr_conv->read
*        IMPORTING
*          data = lw_string.
*
*
*      t_pdfdata = lw_string.
*      APPEND t_pdfdata.
*
*      CLEAR: lw_str, lw_tb.
*    ENDLOOP.
*  ENDIF.

*Fine Modifica MMorgante pdf

* VITOLAZZI 18/07/07 C.R. PTDK902617
* MODIFICHE PER STORICIZZAZIONE STAMPE IN PDF
* CREO NOME UNIVOCO PER FILE PDF.
*  MOVE sy-datum TO filename-data.
*  CONCATENATE  'ZREG' '_' INTO filename-dettaglio.
*  CONDENSE filename NO-GAPS.
   
   
  MOVE w_data_save TO filename-data.
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
   
   
  CLEAR va_proced.
   
   
**MEV110408 AV - inizio
*  move 'ZREG' to va_proced.
   
   
  MOVE 'REG_IVA_ATTIVO' TO va_proced.
   
   
**MEV110408 AV - fine
*End mod
*** 112446 - Dematerializzazione Registri IVA - Inizio P.C.
   
   
  IF p_cpx = 'X'.
   
   
*    CONCATENATE 'Billing' 'ZREG' '_' INTO filename-dettaglio.
   
   
    CONCATENATE 'ZREG' '_' INTO filename-dettaglio.
   
   
*  IF va_variante = 'B' .
*    CONCATENATE filename-dettaglio 'BSVF'  '_'
*                       INTO filename-dettaglio.
***Inizio MEV 103959 - 23/01/2014
   
   
    IF va_variante = 'U'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'BSVFU' into va_proced. "**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'BSVFU' '_'
                         INTO filename-dettaglio."**MEV110408 AV
   
   
***Fine MEV 103959 - 23/01/2014
*    ELSEIF va_variante = 'D'  .
***Start Mod MEV110408 Registri IVA ind37or DF
**    clear va_proced."**MEV110408 AV
**    concatenate filename-dettaglio 'CAP' into va_proced."**MEV110408 AV
**End mod
*      CONCATENATE filename-dettaglio 'CAP' '_'
*                         INTO filename-dettaglio."**MEV110408 AV

* INIZIO INS T29664999 25.03.2016 DM
   
   
    ELSEIF va_variante = 'K'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_FIN_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_FIN_EST'  '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'J'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_FIN_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_FIN_ITA'  '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'M'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_RESI_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_RESI_EST' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'L'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_RESI_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_RESI_ITA' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'I'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_UNIV_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_UNIV_EST' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'H'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_UNIV_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_UNIV_ITA' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'B' .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'BSVF_RESI' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'BSVF_RESI'   '_'
                         INTO filename-dettaglio."**MEV110408 AV
   
   
* FINE INS T29664999 25.03.2016 DM
   
   
    ELSEIF va_variante = 'R'.

      CONCATENATE filename-dettaglio 'BSVF_EDITORIA'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'Q' .

      CONCATENATE filename-dettaglio 'BSVF_FIN_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'P' .

      CONCATENATE filename-dettaglio 'BSVF_FIN_ITA'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'A' .

      CONCATENATE filename-dettaglio 'BSVF_RES_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'O' .

      CONCATENATE filename-dettaglio 'BSVF_UNIV_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'N' .

      CONCATENATE filename-dettaglio 'BSVF_UNIV_ITA'   '_'  INTO filename-dettaglio.

      " Fine inserimento M.T Ticket 35146713 - CR BLDK903339

      " Inizio inserimento E.V CR BLDK903490 04/07/2018

    ELSEIF va_variante = 'T' .

      CONCATENATE filename-dettaglio 'PPAY'   '_'           INTO filename-dettaglio.
   
   
*      Fine inserimento E.V CR

   
   
      " Inizio inserimento CR BLDK903522 10/07/2018

    ELSEIF va_variante = 'S' .

      CONCATENATE filename-dettaglio 'CLP'   '_'           INTO filename-dettaglio.
   
   
*      Fine inserimento CR BLDK903522

   
   
    ENDIF.

  ENDIF.
   
   
*** 112446 - Dematerializzazione Registri IVA - Fine P.C.
   
   
  IF p_pdf = 'X'.

    CONCATENATE 'ZREG' '_' INTO filename-dettaglio.
   
   
*  IF va_variante = 'B' .
*    CONCATENATE filename-dettaglio 'BSVF'  '_'
*                       INTO filename-dettaglio.
***Inizio MEV 103959 - 23/01/2014
   
   
    IF va_variante = 'U'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'BSVFU' into va_proced. "**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'BSVFU' '_'
                         INTO filename-dettaglio."**MEV110408 AV
   
   
***Fine MEV 103959 - 23/01/2014
   
   
    ELSEIF va_variante = 'D'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'CAP' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'CAP' '_'
                         INTO filename-dettaglio."**MEV110408 AV

   
   
* INIZIO INS T29664999 25.03.2016 DM
   
   
    ELSEIF va_variante = 'K'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_FIN_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_FIN_EST'  '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'J'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_FIN_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_FIN_ITA'  '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'M'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_RESI_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_RESI_EST' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'L'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_RESI_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_RESI_ITA' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'I'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_UNIV_EST' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_UNIV_EST' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'H'  .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'PM_UNIV_ITA' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'PM_UNIV_ITA' '_'
                         INTO filename-dettaglio."**MEV110408 AV
    ELSEIF va_variante = 'B' .
   
   
**Start Mod MEV110408 Registri IVA ind37or DF
*    clear va_proced."**MEV110408 AV
*    concatenate filename-dettaglio 'BSVF_RESI' into va_proced."**MEV110408 AV
*End mod
   
   
      CONCATENATE filename-dettaglio 'BSVF_RESI'   '_'
                         INTO filename-dettaglio."**MEV110408 AV
   
   
* FINE INS T29664999 25.03.2016 DM

   
   
      " Inizio inserimento M.T Ticket 35146713 - CR BLDK903339

    ELSEIF va_variante = 'R'.

      CONCATENATE filename-dettaglio 'BSVF_EDITORIA'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'Q' .

      CONCATENATE filename-dettaglio 'BSVF_FIN_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'P' .

      CONCATENATE filename-dettaglio 'BSVF_FIN_ITA'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'A' .

      CONCATENATE filename-dettaglio 'BSVF_RES_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'O' .

      CONCATENATE filename-dettaglio 'BSVF_UNIV_EST'   '_' INTO filename-dettaglio.

    ELSEIF va_variante = 'N' .

      CONCATENATE filename-dettaglio 'BSVF_UNIV_ITA'   '_'  INTO filename-dettaglio.

      " Fine inserimento M.T Ticket 35146713 - CR BLDK903339

      " Inizio inserimento E.V CR BLDK903490 04/07/2018

    ELSEIF va_variante = 'T' .

      CONCATENATE filename-dettaglio 'PPAY'   '_'           INTO filename-dettaglio.
   
   
*      Fine inserimento E.V CR

   
   
      " Inizio inserimento CR BLDK903522 10/07/2018

    ELSEIF va_variante = 'S' .

      CONCATENATE filename-dettaglio 'CLP'   '_'           INTO filename-dettaglio.
   
   
*      Fine inserimento CR BLDK903522

*** 114621 - Società in Service - Inizio P.C.
   
   
    ELSEIF va_variante = '2' .

      CONCATENATE filename-dettaglio 'MIS'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = 'V' .

      CONCATENATE filename-dettaglio 'KIP'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = 'Z' .

      CONCATENATE filename-dettaglio 'BOX'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = 'W' .

      CONCATENATE filename-dettaglio 'MOT'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = 'Y' .

      CONCATENATE filename-dettaglio 'PAT'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = '0' .

      CONCATENATE filename-dettaglio 'CYP'   '_'           INTO filename-dettaglio.

    ELSEIF va_variante = '1' .

      CONCATENATE filename-dettaglio 'ADS'   '_'           INTO filename-dettaglio.
   
   
*** 114621 - Società in Service - Fine P.C.

   
   
    ENDIF.


  ENDIF.

  CONDENSE filename NO-GAPS.
   
   
* FINE VITOLAZZI 18/07/07 C.R. PTDK902617

*Inizio Modifica MMorgante - Determinazione path logica

*  CALL FUNCTION 'FILE_GET_NAME'
*    EXPORTING
*      logical_filename    = 'ZCOMUNE_REG_IVA'
*      operating_system    = sy-opsys
*      parameter_1         = filename
*      with_file_extension = 'X'
*    IMPORTING
*      file_name           = c_filepdf
*    EXCEPTIONS
*      file_not_found      = 1
*      OTHERS              = 2.
*
*  IF sy-subrc EQ 0.
   
   
  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename    = 'ZCOMUNE_REG_IVA'
      operating_system    = sy-opsys
      parameter_1         = filename
      with_file_extension = 'X'
    IMPORTING
      file_name           = c_filepdf.
  IF NOT c_filepdf IS INITIAL.
   
   
*Fine Modifica MMorgante - Determinazione path logica
**Start Mod MEV110408 Registri IVA ind37or DF
   
   
    IF p_cpx = ' '.    "scrivo PDF solo se cpx è blank
      OPEN DATASET c_filepdf FOR OUTPUT IN BINARY MODE.
      IF sy-subrc EQ 0.
   
   
*    Inizio Modifica MMorgante pdf
*          LOOP AT t_pdfdata.
*            TRANSFER t_pdfdata TO c_filepdf.
*          ENDLOOP.
   
   
        LOOP AT lt_line INTO ls_line.
          TRANSFER ls_line TO c_filepdf.
        ENDLOOP.
   
   
*    Fine Modifica MMorgante pdf
   
   
        CLOSE DATASET c_filepdf.
      ELSE.
        PERFORM invia_mail_errore USING 'FILE'.
      ENDIF.
    ENDIF.
  ELSE.
    PERFORM invia_mail_errore USING 'FILE2'.
  ENDIF.

ENDFORM.                    " converte_to_pdf
   
   
*&---------------------------------------------------------------------*
*&      Form  zpdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM zpdf .

  PERFORM apro_modulo_pdf.

  PERFORM stampa_modulo_pdf.

  PERFORM stampa_modulo_riepilogo_pdf.

  PERFORM chiudo_modulo_pdf.

ENDFORM.                    " zpdf
   
   
*&---------------------------------------------------------------------*
*&      Form  apro_modulo_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM apro_modulo_pdf .

  CLEAR itcpo.
  itcpo-tddest   = p_spool.
  itcpo-tdnewid  = 'X'.
  itcpo-tdimmed  = ' '.
  itcpo-tddelete = ' '.
  itcpo-tdgetotf = 'X'.


  CALL FUNCTION 'OPEN_FORM'
    EXPORTING
      dialog   = ' '
      options  = itcpo
      language = sy-langu.

ENDFORM.                    " apro_modulo_pdf
   
   
*&---------------------------------------------------------------------*
*&      Form  stampa_modulo_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM stampa_modulo_pdf .

   
   
* RESETTO VARIABILI PER LE STAMPE
   
   
  PERFORM reset_variabili.




  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA3_NE'.

  SELECT MAX( budatda ) INTO budat_ul2 FROM zivadate_el
                                   WHERE flg_att  = flg_att
                                   AND     bukrs  = p_bukrs.
  SELECT SINGLE * FROM zivadate_el WHERE budatda EQ budat_ul2
                                   AND flg_att  = flg_att
                                   AND     bukrs  = p_bukrs.
  vn_riga = zivadate_el-numeraz.
  w_page_save = w_page.
  w_page_stampa = zivadate_el-pagina.
  IF budat_ul2(4) NE s_budat-low(4).
    CLEAR: vn_riga, w_page_stampa.
  ENDIF.

   
   
*  clear vn_riga.
   
   
  CLEAR vn_totale_imponibile.
  CLEAR  vn_totale_imposte.
  CLEAR  vn_totale_bolli.
  CLEAR  vn_totale_fatture_int.
  CLEAR  vn_totale_fatture_tra.
  CLEAR  vn_totale_ritenuta.


  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'REGISTRO'
      window  = 'HEADER'.
  LOOP AT itab.


    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element = 'RIPORTI'
        window  = 'MAIN'.

    ADD 1 TO vn_riga.
    ADD 1 TO vn_cont3.

    CLEAR itab_cliente.
    DATA: my_opbel LIKE vbrk-vbeln.
    CLEAR my_opbel.
    READ TABLE itab_cliente WITH KEY gpart = itab-gpart.

   
   
*    if itab-opbel ne va_doc.
   
   
    WRITE itab-budat TO  itab_modulo-budat.
    itab_modulo-opbel = itab-opbel.
    itab_modulo-blart = itab-blart.
   
   
*        itab-kofiz under text-016,
   
   
    itab_modulo-gpart = itab-gpart.
    itab_modulo-name1 = itab_cliente-name1.
   
   
* modifica verifica modifica ragione sociale.
*qui.
*    PERFORM verifica_ragione_sociale.
   
   
    PERFORM find_nominativo.

   
   
* modifica per ragione sociale cambiata
*       itab_cliente-taxnum under text-007,
*    endif.
   
   
    WRITE: itab-betrh CURRENCY t001-waers  TO itab_modulo-betrh.
    itab_modulo-mwskz = itab-mwskz.
    IF itab-perc NE '    '.
      itab_modulo-perc = itab-perc.
      WRITE itab-sbeth CURRENCY t001-waers  TO itab_modulo-sbeth.
    ELSE.
   
   
*if itab-bollo_int is initial.
   
   
      itab_modulo-text1 = itab-text1.
   
   
*endif.
   
   
    ENDIF.
    WRITE itab-bollo_int TO va_bollo CURRENCY t001-waers NO-SIGN.
    WRITE itab-totale CURRENCY t001-waers  TO itab_modulo-totale.
    WRITE itab-totale2 CURRENCY itab-waers  TO itab_modulo-totalet.

   
   
** Prova x ritenuta
   
   
    WRITE itab-riten TO itab_modulo-riten CURRENCY t001-waers.


    ADD itab-betrh     TO vn_totale_imponibile.
    ADD itab-sbeth     TO vn_totale_imposte.
    ADD itab-bollo_int TO vn_totale_bolli.
    ADD itab-totale    TO vn_totale_fatture_int.
    ADD itab-totale    TO vn_totale_fatture_tra.
    ADD itab-riten     TO vn_totale_ritenuta.

    WRITE vn_totale_imponibile  TO va_tot_imponibile_s
                                  CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_imposte  TO va_tot_imposte_s
                               CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_bolli    TO va_tot_bolli_s
                               CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_fatture_int TO va_tot_fatture_int_s
                                   CURRENCY t001-waers NO-SIGN.
    WRITE vn_totale_fatture_tra TO va_tot_fatture_tra_s
                                   CURRENCY itab-waers NO-SIGN.
    WRITE vn_totale_ritenuta    TO va_tot_ritenuta_s
                                CURRENCY t001-waers NO-SIGN.
   
   
* documento non progressivo
   
   
    IF itab-flag_err = 'B'.
      itab_cliente-name1 = 'Doc. non emesso per errore informatico'.
      CLEAR itab_modulo-text1.
    ENDIF.
   
   
* documento non progressivo
   
   
    IF itab-opbel NE va_doc.
      IF itab-perc NE '    '.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_IVA_CLIENTE'
            window  = 'MAIN'.
      ELSE.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_NOIVA_CLIENTE'
            window  = 'MAIN'.
      ENDIF.
    ELSE.
      IF itab-perc NE '    '.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_IVA_NOCLIENTE'
            window  = 'MAIN'.
      ELSE.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'ITEM_LINE_NOIVA_NOCLIENTE'
            window  = 'MAIN'.
      ENDIF.

    ENDIF.

    ADD 1 TO vn_cont2.
   
   
*va_cliente = itab-gpart.
   
   
    va_doc = itab-opbel.

   
   
*    CALL FUNCTION 'WRITE_FORM'
*         EXPORTING
*              ELEMENT = 'RIPORTI'
*              WINDOW  = 'MAIN'.

   
   
    IF sw_passato NE 'X'.
      IF vn_cont3 = 35.
        sw_passato = 'X'.
        ADD 1 TO w_page_stampa.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'TOTALI'
            window  = 'MAIN'.
        CLEAR vn_cont3.
        va_flag2 = 'X'.

        va_tot_imponibile_sr  =    va_tot_imponibile_s .
        va_tot_imposte_sr     =    va_tot_imposte_s .
        va_tot_bolli_sr       =    va_tot_bolli_s .
        va_tot_fatture_int_sr =    va_tot_fatture_int_s .
        va_tot_fatture_tra_sr =    va_tot_fatture_tra_s .
        va_tot_ritenuta_sr    =    va_tot_ritenuta_s .
      ENDIF.
    ELSE.
      IF vn_cont3 = 34.
        ADD 1 TO w_page_stampa.
        CALL FUNCTION 'WRITE_FORM'
          EXPORTING
            element = 'TOTALI'
            window  = 'MAIN'.
        CLEAR vn_cont3.
        va_flag2 = 'X'.
        va_tot_imponibile_sr  =    va_tot_imponibile_s .
        va_tot_imposte_sr     =    va_tot_imposte_s .
        va_tot_bolli_sr       =    va_tot_bolli_s .
        va_tot_fatture_int_sr =    va_tot_fatture_int_s .
        va_tot_fatture_tra_sr =    va_tot_fatture_tra_s .
        va_tot_ritenuta_sr    =    va_tot_ritenuta_s .
      ENDIF.
    ENDIF.
  ENDLOOP.
  ADD 1 TO w_page_stampa.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'TOTALI'
      window  = 'MAIN'.

  CALL FUNCTION 'END_FORM' .


ENDFORM.                    " stampa_modulo_pdf
   
   
*&---------------------------------------------------------------------*
*&      Form  stampa_modulo_riepilogo_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM stampa_modulo_riepilogo_pdf .

  PERFORM pulizia_riep.

  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA4_NE'.

  ADD 1 TO w_page_stampa.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'RIEPILOGO'
      window  = 'HEADER'.


  LOOP AT itab_riepilogo.

    WRITE: itab_riepilogo-impon CURRENCY t001-waers   TO   va_impon_riep.
    WRITE: itab_riepilogo-iva CURRENCY t001-waers     TO   va_iva_riep.
    WRITE: itab_riepilogo-bollo CURRENCY t001-waers   TO   va_bollo_riep.
    WRITE: itab_riepilogo-totale CURRENCY t001-waers  TO   va_totale_riep.
    WRITE: itab_riepilogo-riten CURRENCY t001-waers   TO   va_rit_riep.

    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element = 'ITEM_RIEPILOGO'
        window  = 'MAIN'.

  ENDLOOP.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element = 'TOTALI_RIEPILOGO'
      window  = 'MAIN'.

  CALL FUNCTION 'END_FORM' .

  PERFORM pulizia_riep.

  CALL FUNCTION 'START_FORM'
    EXPORTING
      form = 'ZREGISTROIVA4_NE'.



ENDFORM.                    " stampa_modulo_riepilogo_pdf
   
   
*&---------------------------------------------------------------------*
*&      Form  chiudo_modulo_pdf
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM chiudo_modulo_pdf .

  CALL FUNCTION 'CLOSE_FORM'
    TABLES
      otfdata                  = zitcoo
    EXCEPTIONS
      unopened                 = 1
      bad_pageformat_for_print = 2
      send_error               = 3
      spool_error              = 4
      codepage                 = 5
      OTHERS                   = 6.

   
   
* DOPO LA CHIUSURA DEL SAPSCRIPT LO CONVERTO IN PDF
   
   
  IF sy-subrc EQ 0.
    PERFORM converte_to_pdf.
   
   
**Start Mod MEV110408 Registri IVA - Gestione files CPX INF XML 14.11.16 ind37or
   
   
    IF p_cpx IS NOT INITIAL.
      PERFORM gestione_file_cpx.
    ENDIF.
   
   
*End Mod
   
   
  ELSE.
    PERFORM invia_mail_errore USING 'SAPSCRIPT'.
  ENDIF.



ENDFORM.                    " chiudo_modulo_pdf
   
   
*&---------------------------------------------------------------------*
*&      Form  reset_variabili
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM reset_variabili .

  CLEAR: sw_passato, va_flag2, itab_modulo, vn_cont3.


ENDFORM.                    " reset_variabili
   
   
*&---------------------------------------------------------------------*
*&      Form  invia_mail_errore
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_6033   text
*----------------------------------------------------------------------*
   
   
FORM invia_mail_errore  USING    user_type .

  DATA: objpack          LIKE sopcklsti1 OCCURS 0 WITH HEADER LINE.
  DATA: objhead          LIKE solisti1   OCCURS 0 WITH HEADER LINE.
  DATA: objbin           LIKE solisti1   OCCURS 0 WITH HEADER LINE.
  DATA: objtxt           LIKE solisti1   OCCURS 0 WITH HEADER LINE.
  DATA: reclist          LIKE somlreci1  OCCURS 0 WITH HEADER LINE.
  DATA  doc_chng         LIKE sodocchgi1.
  DATA  attachment1      TYPE i.
  DATA  attachment2      TYPE i.
  DATA  text             TYPE i.
  DATA  mail_address(30) TYPE c.



  CLEAR reclist.
  MOVE sy-uname TO mail_address.
  reclist-copy = 'X'.
  reclist-receiver = mail_address.
  reclist-rec_type = 'B'.
  reclist-rec_id = reclist-receiver.
  reclist-express = 'X'.
  reclist-notif_del = 'X'.
  reclist-notif_ndel = 'X'.
  APPEND reclist.

  CASE user_type.
    WHEN 'SAPSCRIPT'.
      MOVE 'FILE PDF NON CREATO' TO objtxt. APPEND objtxt.
    WHEN 'FILE'.
      MOVE 'FILE PDF NON SCARICATO NELLA DIRECTORY' TO objtxt. APPEND objtxt.
    WHEN 'FILE2'.
      MOVE 'NOME FILE NON TROVATO O ERRATO' TO objtxt. APPEND objtxt.
  ENDCASE.

  DESCRIBE TABLE objtxt LINES text.

  doc_chng-obj_name = 'URGENT'.
  doc_chng-expiry_dat = sy-datum + 10.
  MOVE 'TRANSAZIONE ZREG:'  TO doc_chng-obj_descr.
  doc_chng-sensitivty = 'O'.
  doc_chng-doc_size = text * 255.

  CLEAR objpack-transf_bin.
  objpack-head_start = 1.
  objpack-head_num = 0.
  objpack-body_start = 1.
  objpack-body_num = text.
  objpack-doc_type = 'RAW'.
  APPEND objpack.


  CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
    EXPORTING
      document_data              = doc_chng
      put_in_outbox              = 'X'
    TABLES
      packing_list               = objpack
      object_header              = objhead
      contents_bin               = objbin
      contents_txt               = objtxt
      receivers                  = reclist
    EXCEPTIONS
      too_many_receivers         = 1
      document_not_sent          = 2
      document_type_not_exist    = 3
      operation_no_authorization = 4
      parameter_error            = 5
      x_error                    = 6
      enqueue_error              = 7
      OTHERS                     = 8.



ENDFORM.                    " invia_mail_errore
   
   
*&---------------------------------------------------------------------*
*&      Form  f_zregiva_bersani
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM f_zregiva_bersani .
  DATA ln_zmemdati LIKE zregiva_bersani.
  IF p_zib = 'X'.
    ln_zmemdati-zsocieta    = p_bukrs.
    ln_zmemdati-data_reg_da = s_budat-low.
    ln_zmemdati-data_reg_a  = s_budat-high.
    ln_zmemdati-zusername   = sy-uname.
    ln_zmemdati-datasistema = sy-datum.
    ln_zmemdati-time        = sy-uzeit.
    ln_zmemdati-ztcode      = p_tcode.
    INSERT zregiva_bersani FROM ln_zmemdati.
  ENDIF.
ENDFORM.                    " f_zregiva_bersani
   
   
*&---------------------------------------------------------------------*
*&      Form  controllo_codice_iva
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM controllo_codice_iva.


ENDFORM.                    "controllo_codice_iva

   
   
*&---------------------------------------------------------------------*
*&      Form  trova_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
   
   
FORM trova_range.
   
   
*  DATA: val_setid     TYPE sethier-setid,
*         tbl_set_value TYPE rgsb4 OCCURS 0 WITH HEADER LINE,
*         p_set(20) TYPE c VALUE 'ZFICA_SPLIT'.
*Inizio MEV_106990-ADT 104
   
   
  DATA: ls_split LIKE zfica_split.


   
   
*  CALL FUNCTION 'G_SET_GET_ID_FROM_NAME'
*    " recupera l# id relative al set
*        EXPORTING
*          shortname                = p_set  " nome set
*        IMPORTING
*          new_setid                = val_setid
*        EXCEPTIONS
*          no_set_found             = 1
*          no_set_picked_from_popup = 2
*          wrong_class              = 3
*          wrong_subclass           = 4
*          table_field_not_found    = 5
*          fields_dont_match        = 6
*          set_is_empty             = 7
*          formula_in_set           = 8
*          set_is_dynamic           = 9
*          OTHERS                   = 10.
*
*  IF sy-subrc <> 0.
*  ENDIF.
*
*  CALL FUNCTION 'G_SET_GET_ALL_VALUES'
*    EXPORTING
*      setnr         = val_setid
*    TABLES
*      set_values    = tbl_set_value
*    EXCEPTIONS
*      set_not_found = 1
*      OTHERS        = 2.
*  IF sy-subrc <> 0.
*  ENDIF.
   
   
  REFRESH gi_split.
  SELECT * FROM zfica_split INTO TABLE gi_split
   
   
*BEGIN - INS - BUKRS CONDITION - CR BLDK903528  114378 - IMEL modifica bukrs
   
   
        WHERE bukrs = p_bukrs.
   
   
*BEGIN - INS - BUKRS CONDITION - CR BLDK903528  114378 - IMEL modifica bukrs
*Fine MEV_106990-ADT 104
   
   
  IF sy-subrc = 0.

    REFRESH  p_range.
    CLEAR  p_range.

   
   
*    LOOP AT tbl_set_value .
   
   
    LOOP AT gi_split INTO ls_split.
      p_range-sign = 'I'.
   
   
*Inizio MEV_106990-ADT 104
   
   
      p_range-option = 'EQ'.
   
   
*      IF tbl_set_value-to IS INITIAL.
*        p_range-option = 'EQ'.
*      ELSE.
*        p_range-option = 'BT'.
*        p_range-high   = tbl_set_value-to.
*      ENDIF.
*      p_range-low  = tbl_set_value-from.
   
   
      p_range-low  = ls_split-mwskz.
   
   
*Fine MEV_106990-ADT 104
   
   
      APPEND p_range.
      CLEAR p_range.
    ENDLOOP.
  ENDIF.
ENDFORM.                    "trova_set
   
   
*&---------------------------------------------------------------------*
*&      Form  ESTRAZIONE_FICA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM estrazione_fica .

  SELECT * FROM dfkkinvdoc_h INTO TABLE t_invdoc_h WHERE exbel IN s_exbel
   
   
*CRinaldi 11.07.2016 inizio
   
   
                                                    AND budat IN s_budat
                                                    AND bukrs = p_bukrs  .
   
   
*CRinaldi 11.07.2016 fine

* Inizio inser. RM290116
   
   
  gf_no_rec = sy-subrc.
   
   
* Fine inser. RM290116
   
   
  IF NOT t_invdoc_h IS INITIAL.
    SELECT * FROM dfkkinvdoc_i INTO TABLE t_invdoc_i FOR ALL ENTRIES IN t_invdoc_h
       WHERE invdocno = t_invdoc_h-invdocno.
    IF NOT t_invdoc_i IS INITIAL.
      LOOP AT t_invdoc_h INTO s_invdoc_h.
        LOOP AT t_invdoc_i INTO s_invdoc_i WHERE invdocno = s_invdoc_h-invdocno.
          s_key-exbel = s_invdoc_h-exbel.
          s_key-opbel = s_invdoc_i-opbel.
          APPEND s_key TO t_key.
          CLEAR s_key.
          CLEAR: s_opbel.
          MOVE 'I' TO s_opbel-sign.
          MOVE 'EQ' TO s_opbel-option.
          MOVE s_invdoc_i-opbel TO s_opbel-low.
          APPEND s_opbel.
          CLEAR: s_opbel.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDIF.
  SORT t_key BY exbel opbel.
  DELETE ADJACENT DUPLICATES FROM t_key COMPARING ALL FIELDS.
  SORT s_opbel BY low.
  DELETE ADJACENT DUPLICATES FROM s_opbel COMPARING low.
ENDFORM.
   
   
*&---------------------------------------------------------------------*
*&      Form  ORDINAMENTO_FICA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM ordinamento_fica .
  DATA: ls_work TYPE ty_itab_fica.
  DATA: lt_work TYPE TABLE OF ty_itab_fica.
  DATA: lw_bollo_int TYPE dfkkopk-betrh,    "Importo bollo divisa interna
        lw_bollo_tra TYPE dfkkopk-betrw,    "Importo bollo divisa transazione
        lw_betrh     TYPE dfkkopk-betrh,        "Importo in divisa interna
        lw_betrw     TYPE dfkkopk-betrw,        "Importo in divisa transazione
        lw_sbeth     TYPE dfkkopk-betrh,       "Importo imposta in divisa interna
        lw_sbetw     TYPE dfkkopk-betrw,        "Importo imposta in divisa trans
        lw_totale    TYPE dfkkopk-betrh,       " Totale in divisa interna
        lw_totale2   TYPE dfkkopk-betrw,      "Totale in divisa transazione
        lw_riten     TYPE dfkkopk-betrw,        "Importo ritenuta
        lw_riten_t   TYPE dfkkopk-betrw.
  LOOP AT itab.
    READ TABLE t_key INTO s_key WITH KEY opbel = itab-opbel.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING itab TO s_itab_fica.
      s_itab_fica-exbel = s_key-exbel.
      APPEND s_itab_fica TO t_itab_fica.
      CLEAR s_itab_fica.
    ENDIF.
  ENDLOOP.
  SORT t_itab_fica BY exbel mwskz.
  LOOP AT t_itab_fica INTO s_itab_fica WHERE NOT mwskz IS INITIAL.
    ls_work = s_itab_fica.
    AT END OF mwskz.
      lw_bollo_int = lw_bollo_int + ls_work-bollo_int.
      ls_work-bollo_int = lw_bollo_int.
      lw_bollo_tra = lw_bollo_tra + ls_work-bollo_tra.
      ls_work-bollo_tra = lw_bollo_tra.
      lw_betrh = lw_betrh + ls_work-betrh.
      ls_work-betrh = lw_betrh.
      lw_betrw = lw_betrw + ls_work-betrw.
      ls_work-betrw = lw_betrw.
      lw_sbeth = lw_sbeth + ls_work-sbeth.
      ls_work-sbeth = lw_sbeth.
      lw_sbetw = lw_sbetw + ls_work-sbetw.
      ls_work-sbetw = lw_sbetw.
      lw_totale = lw_totale + ls_work-totale.
      ls_work-totale = lw_totale.
      lw_totale2 = lw_totale2 + ls_work-totale2.
      ls_work-totale2 = lw_totale2.
      lw_riten = lw_riten + ls_work-riten.
      ls_work-riten = lw_riten.
      lw_riten_t = lw_riten_t + ls_work-riten_t.
      ls_work-riten_t = lw_riten_t.
      APPEND ls_work TO lt_work.
      CLEAR: ls_work, lw_bollo_int, lw_bollo_tra, lw_betrh,
      lw_betrw, lw_sbeth, lw_sbetw, lw_totale, lw_totale2,
      lw_riten, lw_riten_t.
      CONTINUE.
    ENDAT.
    lw_bollo_int = lw_bollo_int + ls_work-bollo_int.
    lw_bollo_tra = lw_bollo_tra + ls_work-bollo_tra.
    lw_betrh = lw_betrh + ls_work-betrh.
    lw_betrw = lw_betrw + ls_work-betrw.
    lw_sbeth = lw_sbeth + ls_work-sbeth.
    lw_sbetw = lw_sbetw + ls_work-sbetw.
    lw_totale = lw_totale + ls_work-totale.
    lw_totale2 = lw_totale2 + ls_work-totale2.
    lw_riten = lw_riten + ls_work-riten.
    lw_riten_t = lw_riten_t + ls_work-riten_t.
  ENDLOOP.
  IF NOT lt_work IS INITIAL.
    CLEAR itab. REFRESH itab.
    LOOP AT lt_work INTO ls_work.
      MOVE-CORRESPONDING ls_work TO itab.
      itab-opbel = ls_work-exbel+4(12).
      APPEND itab.
      CLEAR itab.
    ENDLOOP.
  ENDIF.
ENDFORM.
   
   
*&---------------------------------------------------------------------*
*&      Form  FIND_NOMINATIVO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM find_nominativo .
  DATA: ls_str TYPE but000.
  DATA: w_flag.



  IF itab_cliente-type NE '1'.         "Organizzazione
    SELECT SINGLE * FROM but000 INTO ls_str WHERE partner = itab-gpart
                                              AND valid_from LE itab-budat
                                              AND valid_to GE itab-budat.
    IF sy-subrc = 0.
      itab_cliente-name1 = ls_str-name_org1.
    ENDIF.
  ELSE.                                "Persona Fisica
    SELECT SINGLE * FROM but000 INTO ls_str WHERE partner = itab-gpart
                                              AND valid_from LE itab-budat
                                              AND valid_to GE itab-budat.
    IF sy-subrc = 0.
      itab_cliente-name_first = ls_str-name_first.
      itab_cliente-name_last = ls_str-name_last.
      w_flag = 'X'.
    ENDIF.
    IF w_flag = 'X'.
      CONCATENATE itab_cliente-name_first itab_cliente-name_last
                 INTO itab_cliente-name1 SEPARATED BY space.
    ENDIF.
  ENDIF.

ENDFORM.
   
   
*&---------------------------------------------------------------------*
*&      Form  gestione_file_cpx
*&---------------------------------------------------------------------*
   
   
FORM gestione_file_cpx .

  DATA : ls_zcpx_ocs      TYPE zcpx_ocs,
         ls_info          TYPE zcpx_info_ocs,
         xml_result       TYPE xstring,  "xstring ensures UTF-8 encoding
         xml_resultstring TYPE string.  "xstring ensures UTF-8 encoding

  DATA zocs_index_declaration TYPE zocs_index_declaration.

  zocs_index_declaration-id = 'i1'.
  zocs_index_declaration-idx_name = text-032.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

   
   
*MEV110408 - VM split cod fisc - p iva cambiato testo 033.
*rinumerazione dei tag.
   
   
  zocs_index_declaration-id = 'i2'.
  zocs_index_declaration-idx_name = text-033.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i3'.
  zocs_index_declaration-idx_name = text-046.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i4'.
  zocs_index_declaration-idx_name = text-034.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i5'.
  zocs_index_declaration-idx_name = text-035.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i6'.
  zocs_index_declaration-idx_name = text-037.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'number'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i7'.
  zocs_index_declaration-idx_name = text-036.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'number'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i8'.
  zocs_index_declaration-idx_name = text-039.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i9'.
  zocs_index_declaration-idx_name = text-047.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.
   
   
*FINE MEV110408
***   112446 - Dematerializzazione Registri IVA  - Inizio P.C.
   
   
  zocs_index_declaration-id = 'i10'. "Tag Oggetto
  zocs_index_declaration-idx_name = 'Oggetto'. "text-048.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.

  zocs_index_declaration-id = 'i11'. "Tag Attività
  zocs_index_declaration-idx_name = 'Attività'. "text-049.
  zocs_index_declaration-type = 'user'.
  zocs_index_declaration-fmt = 'string'.
  APPEND zocs_index_declaration TO ls_zcpx_ocs-zocs_index_declaration.
  CLEAR zocs_index_declaration.
   
   
***   112446 - Dematerializzazione Registri IVA  - Fine P.C.
*  ZOCS_LETTER_SECTION
   
   
  DATA zocs_letter_section TYPE zocs_letter_section.
  IF budat_ul2(4) NE s_budat-low(4).
    va_cnt_pdf = w_page_stampa.
  ELSE.
    va_cnt_pdf = w_page_stampa - zivadate_el-pagina.
  ENDIF.
  SHIFT va_cnt_pdf LEFT DELETING LEADING '0'.
  zocs_letter_section-num_pages =  va_cnt_pdf.
  zocs_letter_section-num_sheet =  va_cnt_pdf.
  zocs_letter_section-info_section_name = text-040.
  zocs_letter_section-info = filename .
  zocs_letter_section-info_name = text-038.
   
   
*
   
   
  DATA zocs_index_value TYPE zocs_index_value.
  zocs_index_value-ref = 'i1'.
  zocs_index_value-idx = text-041.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.

   
   
*MEV110408 - cambio numerazione e aggiungo c fisc.
   
   
  zocs_index_value-ref = 'i2'.
  zocs_index_value-idx = text-042.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.

  zocs_index_value-ref = 'i3'.
  zocs_index_value-idx = ''.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
*
***   112446 - Dematerializzazione Registri IVA  - Inizio P.C.
   
   
  TABLES:zbill_regiva_xml.
  DATA: ls_zbill_regiva_xml LIKE zbill_regiva_xml.
  CLEAR:ls_zbill_regiva_xml.

  SELECT SINGLE *
  FROM  zbill_regiva_xml
  INTO  ls_zbill_regiva_xml
  WHERE cod_attivita = zcod_var-cod_atti.

  zocs_index_value-ref = 'i4'.
  zocs_index_value-idx = ''.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.

   
   
***   112446 - Dematerializzazione Registri IVA  - Inizio P.C.
   
   
  zocs_index_value-ref = 'i5'.
   
   
*  zocs_index_value-idx = text-043.
   
   
  zocs_index_value-idx = ls_zbill_regiva_xml-tipologia.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
***   112446 - Dematerializzazione Registri IVA  - Fine P.C.
*
   
   
  zocs_index_value-ref = 'i6'.
  zocs_index_value-idx = s_budat-low+4(2).
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
*
   
   
  zocs_index_value-ref = 'i7'.
  zocs_index_value-idx = s_budat-low(4).
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.

   
   
*
   
   
  zocs_index_value-ref = 'i8'.
   
   
*  zocs_index_value-idx = ls_zbill_regiva_xml-oggetto.
   
   
  SPLIT filename AT '.' INTO  va_idx  va_ext.
  ADD 1 TO va_cnt.
   
   
*MEV110408 AV - inizio
   
   
  CONCATENATE va_idx '_' va_cnt INTO zocs_index_value-idx.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
*  concatenate 'Billing' va_idx '_' va_cnt into zocs_index_value-idx.
*MEV110408 AV - fine


**aggiungo campo sezionale.
   
   
  DATA: wa_sezionale TYPE zcod_var-cod_testo,
        c1           TYPE i,
        count        TYPE i,
        c            TYPE c.
  CONSTANTS: wa_ammessi(76) VALUE ' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-?:().,''+&<>'.
  CLEAR wa_sezionale.
   
   
*select single COD_TESTO from ZCPX_SEZ into wa_sezionale
*  where TCODE = sy-tcode
*  and COD_ATTI = FLG_ATT.
   
   
  wa_sezionale = w_testo.
  IF wa_sezionale CO wa_ammessi.
  ELSE.
    c1 = 0.
    count = strlen(  wa_sezionale ).
    DO count TIMES.
      c =  wa_sezionale+c1(1).
      IF c CN wa_ammessi.
        REPLACE c WITH ' ' INTO wa_sezionale.
      ENDIF.
      c1 = c1 + 1.
    ENDDO.
  ENDIF.
  zocs_index_value-ref = 'i9'.
  zocs_index_value-idx = wa_sezionale.
   
   
*  zocs_index_value-idx = ls_zbill_regiva_xml-attivita.
   
   
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
**MEV110408  - fine.
***   112446 - Dematerializzazione Registri IVA  - Inizio P.C.
   
   
  zocs_index_value-ref = 'i10'. "Tag Oggetto
  zocs_index_value-idx = ls_zbill_regiva_xml-oggetto.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
*
   
   
  zocs_index_value-ref = 'i11'. "Tag Attività
  zocs_index_value-idx = ls_zbill_regiva_xml-attivita.
  APPEND zocs_index_value TO zocs_letter_section-index_value.
  CLEAR zocs_index_value.
   
   
***   112446 - Dematerializzazione Registri IVA  - Fine P.C.
   
   
  APPEND zocs_letter_section TO ls_zcpx_ocs-zocs_letter_section.
   
   
*
**MEV110408 AV - inizio
   
   
  CLEAR lv_user.
  SELECT SINGLE low INTO lv_user FROM tvarvc
        WHERE name = 'ZREG_USER' AND
              type = 'P'.
   
   
*  ls_zcpx_ocs-zocs_info_prn_file-customer_id  = sy-uname.
   
   
  ls_zcpx_ocs-zocs_info_prn_file-customer_id  = lv_user.

   
   
**MEV110408  - fine
   
   
  ls_zcpx_ocs-zocs_info_prn_file-num_pages =  va_cnt_pdf.

  ls_zcpx_ocs-zocs_info_prn_file-num_letters  = '1'.
  ls_zcpx_ocs-zocs_info_prn_file-num_sheets   = va_cnt_pdf.

  ls_zcpx_ocs-zocs_info_prn_file-version      = '01.00.00'.
   
   
*
   
   
  ls_zcpx_ocs-producer = text-044.
  ls_zcpx_ocs-language = text-045.
   
   
**MEV110408 AV - inizio
*CONCATENATE 'Billing' va_idx INTO va_idx.
   
   
  ls_zcpx_ocs-id_file = va_idx.
   
   
*  ls_zcpx_ocs-id_file = va_idx.
*
*  ls_info-id_utente            = sy-uname.
   
   
  ls_info-id_utente            = lv_user.
   
   
**MEV110408  - fine
   
   
  CONCATENATE sy-datum+6(2) '/' sy-datum+4(2) '/' sy-datum(4) INTO  ls_info-data_inoltro.
  ls_info-nome_lotto = va_idx.
  ls_info-numero_documenti     = '1'.
  ls_info-numero_pagine        = va_cnt_pdf.

  ls_info-servizio             = 'WEB'.
   
   
***   112446 - Dematerializzazione Registri IVA  - Inizio P.C.
*  ls_info-nome_procedura       = va_proced.
   
   
  ls_info-nome_procedura       = 'REGISTRI_IVA_CA'.
   
   
***   112446 - Dematerializzazione Registri IVA  - Fine P.C.
   
   
  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      logical_filename = 'ZCOMUNE_REG_IVA'
      operating_system = sy-opsys
   
   
*     parameter_1      = filename
*     with_file_extension = 'X'
   
   
    IMPORTING
      file_name        = va_path
    EXCEPTIONS
      file_not_found   = 1
      OTHERS           = 2.

  va_string = va_idx .
   
   
*
   
   
  call function 'ZIVACPX_BILL'
    EXPORTING
      iv_pod_xml        = ls_zcpx_ocs
      iv_directory_file = va_path     "PATH
      iv_info           = ls_info
      iv_pdf_string     = va_string  "nome file no ext
      filebin           = lv_bin_file
   
   
*    tables
**      it_pdf_in         = lt_linecpx[]
*     it_pdf_in         = t_pdfdata[]
   
   
    EXCEPTIONS
      err_progr_zcpx    = 1
      err_call_trasf    = 2
      err_conv_xstring  = 3
      err_apertura_file = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

   
   
*  PERFORM crea_zip.

   
   
ENDFORM.                    " gestione_file_cpx




"inizio MEV 112057 spesometro 2017
   
   
*&---------------------------------------------------------------------*
*&      Form  RIEMPI_ZREG_IVA_SPES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
   
   
FORM riempi_zreg_iva_spes .
  DATA: va_time LIKE zspeso_regiva-timestamp.
  DATA: va_exbel LIKE dfkkinvdoc_h-exbel.


  CLEAR: flag, va_time.


  REFRESH t_zspeso_regiva.

  GET TIME STAMP FIELD va_time.

  LOOP AT itab.

    CLEAR: va_invdocno, va_exbel.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = itab-opbel
      IMPORTING
        output = va_exbel.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = itab-opbel
      IMPORTING
        output = t_zspeso_regiva-num_doc.


   
   
*   move va_exbel TO t_zspeso_regiva-num_doc.
*   SHIFT t_zspeso_regiva-num_doc LEFT DELETING LEADING '0'.
   
   
    MOVE t_zspeso_regiva-num_doc TO t_zspeso_regiva-xblnr.
   
   
*   SHIFT t_zspeso_regiva-xblnr LEFT DELETING LEADING '0'.

*        MOVE 'EPI'      TO t_ZSPESO_REGIVA-bukrs.
   
   
    MOVE itab-budat(4) TO t_zspeso_regiva-gjahr.
    MOVE 'BILLING'      TO t_zspeso_regiva-sistema_sap.
    MOVE itab-budat TO t_zspeso_regiva-dataregistrazion.
    MOVE sy-uname    TO t_zspeso_regiva-utente_regiva.
   
   
* MEV 112057 - spesometro registri iva bill 8  28.08.2017 inizio rp
*    MOVE p_tcode    TO t_zspeso_regiva-trx_reg_iva.
   
   
    MOVE sy-tcode    TO t_zspeso_regiva-trx_reg_iva.
   
   
* MEV 112057 - spesometro registri iva bill 8  28.08.2017 fine rp
*    MOVE 'ZREG'    TO t_zspeso_regiva-trx_reg_iva.
   
   
    MOVE '10'        TO t_zspeso_regiva-origine_dato. "attivo
    MOVE itab-mwskz TO t_zspeso_regiva-cod_iva.
    MOVE itab-blart TO t_zspeso_regiva-tipo_documento.
    MOVE itab-gpart TO t_zspeso_regiva-kunnr.

    IF itab-perc IS NOT INITIAL.
      SHIFT  itab-perc LEFT DELETING LEADING '0' .
      REPLACE '%' WITH '' INTO itab-perc.
      MOVE itab-perc TO t_zspeso_regiva-aliquota.
    ELSE.
      MOVE '0,00' TO t_zspeso_regiva-aliquota.
    ENDIF.

    IF t_zspeso_regiva-aliquota NS ',' .
      CONCATENATE t_zspeso_regiva-aliquota ',00' INTO t_zspeso_regiva-aliquota.
    ENDIF.

    MOVE itab-betrh TO t_zspeso_regiva-imponibileimport.
    MOVE itab-sbeth TO t_zspeso_regiva-imposta.
    MOVE flg_att TO t_zspeso_regiva-tipo_attivita.
    MOVE va_time TO t_zspeso_regiva-timestamp.

   
   
*    SELECT SINGLE bukrs bldat  INTO (t_zspeso_regiva-bukrs,
*                                                t_zspeso_regiva-data,
*                                                t_zspeso_regiva-xblnr,
*                                                t_zspeso_regiva-gsber )
*      FROM dfkkop WHERE opbel = itab-opbel.

   
   
    SELECT SINGLE invdocno bldat bukrs INTO (va_invdocno,
                                             t_zspeso_regiva-data,
                                             t_zspeso_regiva-bukrs )
      FROM dfkkinvdoc_h WHERE exbel = va_exbel.

    IF itab-blart = 'N1'.
      PERFORM xblnr.
    ENDIF.

    PERFORM dataoperazione.

    APPEND t_zspeso_regiva.
    CLEAR: itab, t_zspeso_regiva.

  ENDLOOP.

  IF t_zspeso_regiva[] IS NOT INITIAL.
    MODIFY zspeso_regiva FROM TABLE t_zspeso_regiva.
   
   
*   COMMIT WORK.
   
   
  ENDIF.

  MESSAGE s000(db) WITH 'Dati spesometro acquisiti correttamente'.



ENDFORM.


FORM dataoperazione.

  DATA: lv_srctatype LIKE dfkkinvdoc_i-srctatype.
  DATA: lr_mwskz TYPE RANGE OF dfkkinvdoc_i-mwskz
           WITH HEADER LINE.
  DATA: ls_ziva_competenza LIKE ziva_competenza.
  DATA: BEGIN OF lt_billdocno OCCURS 0,
          srcdocno  TYPE srcdocno_kk,
          billdocno TYPE billdocno_kk.
  DATA: END OF lt_billdocno.
  DATA: BEGIN OF lt_data OCCURS 0,
          bitdate_to LIKE /1fe/0epi04it00-bitdate_to,
        END OF lt_data.

  REFRESH: t_dfkkinvdoc_i, lr_mwskz.
  CLEAR lv_srctatype.

  SELECT * FROM dfkkinvdoc_i INTO CORRESPONDING FIELDS OF TABLE
    t_dfkkinvdoc_i WHERE invdocno = va_invdocno.

  LOOP AT t_dfkkinvdoc_i WHERE srctatype IS NOT INITIAL.
    lv_srctatype = t_dfkkinvdoc_i-srctatype.
    CLEAR t_dfkkinvdoc_i.
    EXIT.
  ENDLOOP.

  LOOP AT t_dfkkinvdoc_i.
    MOVE: 'I' TO lr_mwskz-sign,
          'EQ' TO lr_mwskz-option.
    MOVE t_dfkkinvdoc_i-mwskz TO lr_mwskz-low.
    APPEND lr_mwskz.
    CLEAR t_dfkkinvdoc_i.
  ENDLOOP.

  IF lr_mwskz[] IS NOT INITIAL.
    SORT lr_mwskz.
    DELETE ADJACENT DUPLICATES FROM lr_mwskz.
  ENDIF.

  CLEAR ls_ziva_competenza.
  SELECT SINGLE * FROM ziva_competenza INTO ls_ziva_competenza
      WHERE srctatype = lv_srctatype
      AND mwskz_sost IN lr_mwskz.

  IF sy-subrc = 0.
   
   
**cerchiamo le date operazione dei BI

   
   
    REFRESH: lt_billdocno, lt_data.
    LOOP AT t_dfkkinvdoc_i.
      CLEAR lt_billdocno.
      MOVE t_dfkkinvdoc_i-srcdocno TO lt_billdocno-srcdocno.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = lt_billdocno-srcdocno
        IMPORTING
          output = lt_billdocno-billdocno.
      APPEND lt_billdocno.
    ENDLOOP.
    SORT lt_billdocno.
    DELETE ADJACENT DUPLICATES FROM lt_billdocno.
    IF lt_billdocno[] IS NOT INITIAL.
      SELECT bitdate_to FROM /1fe/0epi04it00            "#EC CI_NOFIRST
          INTO TABLE lt_data
          FOR ALL ENTRIES IN lt_billdocno
          WHERE billdocno = lt_billdocno-billdocno.
      IF lt_data[] IS NOT INITIAL.
        SORT lt_data.
        DELETE ADJACENT DUPLICATES FROM lt_data.

        LOOP AT lt_data.
          MOVE lt_data-bitdate_to TO t_zspeso_regiva-dataoperazione.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.


ENDFORM.


FORM xblnr.
  DATA: va_invdocno LIKE dfkkinvdoc_h-invdocno.
  DATA: ls_str    TYPE dfkkinvdoc_s.
  DATA: ls_str0   TYPE dfkkinvbill_i.
  DATA: ls_str1   TYPE dfkkinvdoc_h.
  DATA: lw_invdoc TYPE invdocno_kk.
  DATA: va_exbel LIKE dfkkinvdoc_h-exbel.

  CLEAR: dfkkinvdoc_h, dfkkinvdoc_s , dfkkinvbill_i, va_invdocno,
         ls_str, ls_str0, ls_str1, va_exbel.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = t_zspeso_regiva-num_doc
    IMPORTING
      output = va_exbel.


  SELECT SINGLE invdocno INTO va_invdocno FROM dfkkinvdoc_h
    WHERE exbel = va_exbel.

  IF sy-subrc = 0.
    SELECT SINGLE * FROM dfkkinvdoc_s INTO ls_str WHERE invdocno = va_invdocno.
    IF sy-subrc = 0.
      SELECT SINGLE * FROM dfkkinvbill_i INTO ls_str0 WHERE billdocno = ls_str-srcdocno.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM dfkkinvdoc_h INTO ls_str1 WHERE invdocno = ls_str0-zz_invdocno.
        IF sy-subrc = 0.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
            EXPORTING
              input  = ls_str1-exbel
            IMPORTING
              output = ls_str1-exbel.

          t_zspeso_regiva-xblnr = ls_str1-exbel.

        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


ENDFORM.

"fine MEV 112057 spesometro 2017

   
   
*Text elements
*----------------------------------------------------------
* 001 Poste Italiane S.p.a.  C.F. 97103880585/P.I.  01114601006
* 002 Stampa Registro I.V.A.
* 003 Periodo:
* 004 DATA
* 005 NUM.DOCUM.
* 006 CLIENTE
* 007 PARTITA IVA
* 008       IMPONIBILE
* 009 IVA%
* 010      IMPORTO IVA
* 011  BOLLO
* 012   TOTALE DIVISA INTERNA
* 013 NOMINATIVO
* 014 INDIRIZZO
* 015 TD
* 016 CC
* 017 CI
* 018 TOTALE DIVISA TRANSAZ.
* 019 RITENUTA D'ACCONTO
* 020 N.RIGA
* 021 Riepilogo Residuale IVA
* 022 C/Es.
* 023 TOTALI DEL PERIODO
* 024 Elaborazione tramite
* 025 Riepilogo per Settore Merceologico
* 026 C.S.
* 027 Descrizione Settore Merceologico
* 028 
* 029 Registro fatture residuale (ex-attività A e B)
* 030 Registro fatture teletex/telgram
* 031 Rilevante per elenco clienti e fornitori - Decreto Bersani
* 032 Denominazione
* 033 Partita IVA
* 034 Ramo
* 035 Tipologia
* 036 Anno Riferimento
* 037 Mese Riferimento
* 038 File_name
* 039 Codice Univoco
* 040 Generali
* 041 Poste Italiane S.p.A.
* 042 01114601006
* 043 Registro IVA
* 044 Utente
* 045 PDF
* 046 Codice Fiscale
* 047 Sezionale
* 048 Oggetto
* 049 Attività


*Selection texts
*----------------------------------------------------------
* FLG_ATT         Attività (A /B/ C)
* P_BUKRS         Società
* P_CONTR         Attiva controlli
* P_CPX         Crea File .CPX
* P_DATADO         Data documento
* P_DATARE         Data registrazione
* P_PDF         Crea documento PDF
* P_SPESO         Consolida Spesometro
* P_SPOOL         Dispositivo output
* P_TEST         Solo test
* P_TREG         Tipo registro Iva
* P_VV         Escludi dettaglio iva
* P_ZIB         Attiva memorizzazione dati
* P_ZIB_TR         Classe Registro
* S_BLART         Tipo documento
* S_BUDAT         Data registrazione documento
* S_EXBEL         N. Doc. ufficiale
* S_FIKEY         Chiave di riconciliazione
* S_HERKF         Origine
* S_SPART         Settore Merceologico


*Messages
*----------------------------------------------------------
*
* Message class: 00
*162   >>>>>>>>>>> & &
*208   &
*368   &1 &2
*398   & & & &
*
* Message class: DB
*000   & & & &
            
          
        
      
      
      
   
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2019. Sap Release 740
   



