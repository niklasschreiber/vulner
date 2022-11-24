*&---------------------------------------------------------------------*
*& Report  ZAVCP2
*&
*&---------------------------------------------------------------------*
*&Autore     : Stefania Bressan
*&Data       : 25/09/2015
*&Descrizione: MEV 108250 - Copia di ZAVCP
*&---------------------------------------------------------------------*

REPORT  zavcp2 LINE-SIZE 1023.

****- Data declaration
***DATA gt_exclude                TYPE TABLE OF rsexfcode.
***DATA gs_exclude                TYPE rsexfcode.
***
***SELECTION-SCREEN SKIP 3.
***SELECTION-SCREEN BEGIN OF BLOCK block1 WITH FRAME TITLE text-s01.
***SELECTION-SCREEN PUSHBUTTON /10(41) textsl
***                            USER-COMMAND SL.
***SELECTION-SCREEN SKIP 1.
***SELECTION-SCREEN PUSHBUTTON /10(41) textdc
***                            USER-COMMAND DC .
***SELECTION-SCREEN END   OF BLOCK block1.
***
***
***INITIALIZATION.
***  textsl = text-tb1. " 'Somme Liquidate'.
***  textdc = text-tb2. "'Date Contrattuali'.
***
***
***
****- Hide options
***  gs_exclude-fcode  = 'ONLI'. "Hide execute
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'PRIN'. "Hide Print+Execute
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'SJOB'. "Hide Execute in background
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'GET'. "Hide Call variant
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'VSHO'. "Hide Show variant
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'VDEL'. "Hide Delete variant
***  APPEND gs_exclude TO gt_exclude.
***  gs_exclude-fcode  = 'SPOS'. "Hide Save as Variant
***  APPEND gs_exclude TO gt_exclude.
***
***  CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
***    EXPORTING
***      p_status  = '%_00'
***      p_program = sy-repid
***    TABLES
***      p_exclude = gt_exclude.
***
***
***AT SELECTION-SCREEN.
***  CASE sy-ucomm.
***    WHEN 'SL'.
***      SUBMIT z_avcp_sl VIA SELECTION-SCREEN AND RETURN.
***    WHEN 'DC'.
***      SUBMIT z_avcp_dc VIA SELECTION-SCREEN AND RETURN.
***  ENDCASE.

************************************************************************
* Dichiarazione Dati
************************************************************************
TABLES: bkpf, bseg, ekko, bsak, bsas.
TYPE-POOLS: slis, sscr.

TYPES: BEGIN OF ty_sl,
*         cig TYPE c LENGTH 10,
*         laufi TYPE c LENGTH 6,
*         laufd TYPE c LENGTH 10,
*         importo TYPE dmbtr,
          cig        TYPE tdline,          " cig
          belnr      LIKE bkpf-belnr,    " documento fattura
          bldat      TYPE c LENGTH 10,   " data fattura
          anno       TYPE c LENGTH 4,    " anno fattura
          augbl      LIKE bseg-augbl,    " documento pagamento
          augdt      TYPE c LENGTH 10,   " data pagamento
          importo    TYPE char16, "dmbtr,       " importo netto
          pag_parz   TYPE c LENGTH 1, " pagamento parziale
          imp_pag    TYPE char16, "dmbtr importo ordine pagato
          lifnr_fatt TYPE lifnr,    " fornitore fattura
          ebeln      TYPE ebeln,      " OdA
          lifnr_oda  TYPE lifnr,    " fornitore oda
          gjahr      TYPE gjahr,
          konnr      LIKE ekab-konnr, " Numero Contratto relativo alla Posizione di OdA della Fattura
          cpudt      TYPE c LENGTH 10,"LIKE bkpf-cpudt,
          budat      TYPE c LENGTH 10,
          elab       TYPE c LENGTH 1,
          blart      LIKE bkpf-blart,
**MZ inizio
          buzei      LIKE bseg-buzei,
**MZ fine
* Inizio inser. RM211215
          bktxt     LIKE bkpf-bktxt,
          xblnr     LIKE bkpf-xblnr,
          sgtxt     LIKE bseg-sgtxt,
* Fine inser. RM211215
       END OF ty_sl,
       BEGIN OF ty_dc,
         zcig LIKE ekko-zcig,
         bedat LIKE ekko-bedat,  " data stipula contratto
         kdatb LIKE ekko-kdatb,  " data inizio lavori
         kdate LIKE ekko-kdate,  " data fine lavori
         ebeln LIKE ekko-ebeln,  " documento sap (CONTRATTO/ODA SPOT)
         lifnr LIKE ekko-lifnr,  " Fornitore
         stcd2 LIKE lfa1-stcd2,  " Partita IVA
         stcd1 LIKE lfa1-stcd1,  " codice fiscale
         name1 LIKE lfa1-name1,  " RAGIONE SOCIALE
         bstyp LIKE ekko-bstyp,  " CATEGORIA DOCUMENTO
         zzatto_or LIKE ekko-zzatto_or, " ATTO ORIGINALE
         zztipo_atto LIKE ekko-zztipo_atto,  " TIPO ATTO AGGIUNTIVO
         dtoda LIKE ekko-bedat,  " DATA DOCUMENTO ODA
         eindt LIKE eket-eindt,  " DATA ULTIMA CONSEGNA
         ktwrt TYPE ktwrt,       " Valore di testata dell'AQ/ODA Spot
         ekgrp TYPE bkgrp,       " Gruppo Acquisti
         eknam TYPE eknam,       " descr Gruppo Acquisti
         ernam TYPE ernam,       " creato da
         aedat TYPE erdat,       " data acquisizione documento
       END OF ty_dc,
       BEGIN OF ty_cig,
         cig TYPE c LENGTH 12,
       END OF ty_cig.


DATA: wa_sl          TYPE ty_sl,
**MZ inizio MEV 108250
      wa_sl_temp     TYPE ty_sl,
**MZ fine MEV 108250
      wa_dc          TYPE ty_dc,
      it_sl          TYPE TABLE OF ty_sl,
      it_dc          TYPE TABLE OF ty_dc,
      gv_ini         TYPE c LENGTH 1,
      lv_aaaammgg    TYPE c LENGTH 8,
      gv_file        LIKE ibipparms-path,
      lv_file        LIKE ibipparms-path,
      tb_bapi3008_2  TYPE TABLE OF bapi3008_2,
      tb_bapi3008_b  TYPE TABLE OF bapi3008_2,
      tb_bapi3008_o  TYPE TABLE OF bapi3008_2.


* Dati per ALV
DATA: it_fieldcat    TYPE slis_t_fieldcat_alv,
      gd_layout      TYPE slis_layout_alv.

* Define the object to be passed to the RESTRICTION parameter
DATA: restrict TYPE sscr_restrict.
* Auxiliary objects for filling RESTRICT
DATA: opt_list TYPE sscr_opt_list,
      ass      TYPE sscr_ass.

* Dati per help di ricerca custom
DATA: it_return TYPE STANDARD TABLE OF ddshretval,
      wa_return LIKE LINE OF it_return.

*Begin MEV 108250
DATA: BEGIN OF st_bsas,
  bukrs LIKE bsas-bukrs,
  hkont LIKE bsas-hkont,
  augdt LIKE bsas-augdt,
  augbl LIKE bsas-augbl,
  zuonr LIKE bsas-zuonr,
  gjahr LIKE bsas-gjahr,
  belnr LIKE bsas-belnr,
  buzei LIKE bsas-buzei,
  budat LIKE bsas-budat,
  blart LIKE bsas-blart,
  dmbtr LIKE bsas-dmbtr,
**MZ inizio MEV 108250
  shkzg LIKE bsas-shkzg,
**MZ fine MEV 108250
      END OF st_bsas,
  it_bsas LIKE TABLE OF st_bsas,
  it_bsas2 LIKE TABLE OF st_bsas,
**MZ inizio
  is_bsas2_parz LIKE st_bsas,
**MZ fine
  it_bsas_spec LIKE TABLE OF st_bsas,
  it_bsas_tmp LIKE TABLE OF st_bsas.
**MZ inizio
DATA: BEGIN OF st_bsak_pag,
        bukrs LIKE bsak-bukrs,
        hkont LIKE bsak-hkont,
        augdt LIKE bsak-augdt,
        augbl LIKE bsak-augbl,
        zuonr LIKE bsak-zuonr,
        gjahr LIKE bsak-gjahr,
        belnr LIKE bsak-belnr,
        buzei LIKE bsak-buzei,
        budat LIKE bsak-budat,
        blart LIKE bsak-blart,
        dmbtr LIKE bsak-dmbtr,
        shkzg LIKE bsak-shkzg,
      END OF st_bsak_pag.
**MZ fine

DATA: BEGIN OF st_bsak,
        bukrs LIKE bsak-bukrs,
        lifnr LIKE bsak-lifnr,
        umsks LIKE bsak-umsks,
        umskz LIKE bsak-umskz,
        augdt LIKE bsak-augdt,
        augbl LIKE bsak-augbl,
        zuonr LIKE bsak-zuonr,
        gjahr LIKE bsak-gjahr,
        belnr LIKE bsak-belnr,
        buzei LIKE bsak-buzei,
        budat LIKE bsak-budat,
        bldat LIKE bsak-bldat,
        blart LIKE bsak-blart,
        dmbtr LIKE bsak-dmbtr,
        shkzg LIKE bsak-shkzg,
        cpudt LIKE bsak-cpudt,
        sgtxt LIKE bsak-sgtxt,
  END OF st_bsak,
  it_bsak LIKE TABLE OF st_bsak.
DATA: BEGIN OF st_bkpf,
bukrs LIKE bkpf-bukrs,
belnr LIKE bkpf-belnr,
gjahr LIKE bkpf-gjahr,
blart LIKE bkpf-blart,
bldat LIKE bkpf-bldat,
budat LIKE bkpf-budat,
cpudt LIKE bkpf-cpudt,
awtyp LIKE bkpf-awtyp,
awkey LIKE bkpf-awkey,
bktxt LIKE bkpf-bktxt,
xblnr LIKE bkpf-xblnr,
END OF st_bkpf,
it_bkpf LIKE TABLE OF st_bkpf.
DATA: BEGIN OF st_bseg,
  bukrs LIKE bseg-bukrs,
  belnr LIKE bseg-belnr,
  gjahr LIKE bseg-gjahr,
  buzei LIKE bseg-buzei,
  augbl LIKE bseg-augbl,
  hkont LIKE bseg-hkont,
  lifnr LIKE bseg-lifnr,
  ebeln LIKE bseg-ebeln,
  dmbtr LIKE bseg-dmbtr,
  augdt LIKE bseg-augdt,
  sgtxt LIKE bseg-sgtxt,
  umskz LIKE bseg-umskz,
  shkzg LIKE bseg-shkzg,
  END OF st_bseg,
  it_bseg LIKE TABLE OF st_bseg.

DATA: BEGIN OF st_ekko,
  ebeln  LIKE ekko-ebeln,
  lifnr  LIKE ekko-lifnr,
  konnr  LIKE ekko-konnr,
  zcig    LIKE ekko-zcig,
  END  OF st_ekko,
  it_ekko LIKE TABLE OF st_ekko.
RANGES r_hkont FOR bseg-hkont.
*End MEV 108250
************************************************************************
* SCREEN DI SELEZIONE
************************************************************************


SELECTION-SCREEN: BEGIN OF TABBED BLOCK tabs FOR 30 LINES,  "21 LINES,
                  TAB (15) tab1 USER-COMMAND push1 DEFAULT SCREEN 1100,
                  TAB (18) tab2 USER-COMMAND push2 DEFAULT SCREEN 1200,
                  END OF BLOCK tabs.

* tab 1
SELECTION-SCREEN BEGIN OF SCREEN 1100 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
*Begin MEV 108250
*PARAMETERS: p_gjahr TYPE gjahr .
*SELECT-OPTIONS: so_blart FOR bkpf-blart,
*                so_bldat FOR bkpf-bldat,
*                so_belnr FOR bkpf-belnr,
*                so_cig  FOR ekko-zcig,
*                so_cpudt FOR bkpf-cpudt.
* Inizio inser. RM151215

* Fine inser. RM151215
PARAMETERS: p_bukrs TYPE bukrs.
* Inizio inser. RM151215
SELECTION-SCREEN SKIP 1.
* Fine inser. RM151215

*            p_gjahr TYPE gjahr.
SELECT-OPTIONS:  so_augdt FOR bsak-augdt,
                 so_hkont FOR bsas-hkont,
                 so_augbl FOR bsak-augbl.
* Inizio inser. RM151215
SELECTION-SCREEN SKIP 1.
SELECT-OPTIONS:
* Fine inser. RM151215
*so_hkont FOR bsas-hkont,  "RM151215D
so_belnr FOR bkpf-belnr.
SELECTION-SCREEN SKIP 1.

SELECT-OPTIONS:
* Fine inser. RM151215
so_docfo FOR bkpf-belnr,
so_budat FOR bkpf-budat,
*so_augbl FOR bsak-augbl, "RM151215D
so_blart FOR bkpf-blart,
so_blrts FOR bkpf-blart,
so_umskz FOR bseg-umskz,                                    "RM211215I
so_lifn1 FOR bsak-lifnr,
so_bud_f FOR bsak-budat NO-DISPLAY.                         "RM151215I
*so_cig FOR ekko-zcig.
*End MEV 108250
SELECTION-SCREEN SKIP 1.
PARAMETERS: p_alv1   RADIOBUTTON GROUP gr1 USER-COMMAND my,
            p_l1 RADIOBUTTON GROUP gr1 MODIF ID g,
            p_lfil1  LIKE ibipparms-path LOWER CASE MODIF ID g, " path file locale
            p_s1 RADIOBUTTON GROUP gr1 MODIF ID g,
            p_sfil1  LIKE ibipparms-path LOWER CASE MODIF ID g. " path file server
SELECTION-SCREEN END OF BLOCK b1.
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME.
SELECTION-SCREEN COMMENT /1(55) text-015 MODIF ID mg1.
SELECTION-SCREEN END OF BLOCK b3.
PARAMETERS: p_ucomm LIKE sy-ucomm NO-DISPLAY.
SELECTION-SCREEN END OF SCREEN 1100.

* Tab 2
SELECTION-SCREEN BEGIN OF SCREEN 1200 AS SUBSCREEN.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.
SELECT-OPTIONS: so_ebeln FOR ekko-ebeln,
                so_bstyp FOR ekko-bstyp,
                so_bsart FOR ekko-bsart,
                so_bedat FOR ekko-bedat,
                so_zcig  FOR ekko-zcig ,
                so_lifnr FOR ekko-lifnr,
                so_aedat FOR ekko-aedat.
*                so_kdatb FOR ekko-kdatb.
PARAMETERS: p_screen NO-DISPLAY.
SELECTION-SCREEN SKIP 2.
PARAMETERS: p_alv2   RADIOBUTTON GROUP gr2 USER-COMMAND m2,
            p_l2 RADIOBUTTON GROUP gr2 MODIF ID d,
            p_lfil2  LIKE ibipparms-path LOWER CASE MODIF ID d, " path file locale
            p_s2 RADIOBUTTON GROUP gr2 MODIF ID d,
            p_sfil2  LIKE ibipparms-path LOWER CASE MODIF ID d. " path file server
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN END OF SCREEN 1200.



PARAMETERS:
* Hidden parameters to store the last selected tab strip
  pa_dynnr LIKE tabs-dynnr NO-DISPLAY,
  pa_acttb LIKE tabs-activetab NO-DISPLAY.


DATA: wa_bstyp LIKE LINE OF so_bstyp.

************************************************************************
* INITIALIZATION
************************************************************************
INITIALIZATION.
  PERFORM initialitazion.


************************************************************************
* AT SELECTION-SCREEN
************************************************************************
AT SELECTION-SCREEN.

* if the list is started (F8)
  IF sy-ucomm = 'ONLI'.
*   save the last choice
    pa_dynnr = tabs-dynnr.
    pa_acttb = tabs-activetab.
  ENDIF.

  IF sy-batch IS INITIAL.
    IF tabs-activetab = 'PUSH2'.
      p_ucomm = 'PUSH2'.
    ELSE.
      CLEAR p_ucomm.
    ENDIF.
  ENDIF.

  CASE p_ucomm.
    WHEN space.  " Somme Liquidate
      CLEAR: so_ebeln[],
*             so_bstyp[],
             so_bsart[],
             so_bedat[],
             so_zcig[],
             so_lifnr[].
*             so_kdatb[].
    WHEN 'PUSH2'.  " date contrattuali
*      CLEAR: p_gjahr, so_blart[].
      CLEAR: p_bukrs, so_blart[].
*      CLEAR: p_laufd, p_laufi,so_bsart[] .
  ENDCASE.

*  ENDIF.


************************************************************************
* AT SELECTION-SCREEN ON ....
************************************************************************
AT SELECTION-SCREEN ON p_sfil1.
  PERFORM check_extension USING p_s1 p_sfil1.

AT SELECTION-SCREEN ON p_lfil1.
  PERFORM check_extension USING p_l1 p_lfil1.

AT SELECTION-SCREEN ON p_sfil2.
  PERFORM check_extension USING p_s2 p_sfil2.

AT SELECTION-SCREEN ON p_lfil2.
  PERFORM check_extension USING p_l2 p_lfil2.

************************************************************************
* AT SELECTION-SCREEN ON VALUE-REQUEST
************************************************************************
AT SELECTION-SCREEN ON VALUE-REQUEST FOR so_bstyp-low.

  PERFORM bstyp_help CHANGING so_bstyp-low.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sfil1.
  PERFORM browse_appl_serv USING p_s1 CHANGING p_sfil1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_lfil1.
  PERFORM browse_pres_serv USING p_l1 CHANGING p_lfil1.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sfil2.
  PERFORM browse_appl_serv USING p_s2 CHANGING p_sfil2.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_lfil2.
  PERFORM browse_pres_serv USING p_l2 CHANGING p_lfil2.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_laufi.
*  PERFORM f4_laufi.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_laufd.
*  PERFORM f4_laufd.


************************************************************************
* AT SELECTION-SCREEN OUTPUT
************************************************************************
AT SELECTION-SCREEN OUTPUT.
  PERFORM at_selection_screen_output.

*----------------------------------------------------------------------*
* START OF SELECTION                                                   *
*----------------------------------------------------------------------*
START-OF-SELECTION.


  IF p_ucomm IS INITIAL.

    IF p_bukrs IS INITIAL.
      gv_ini = 'D'.
    ENDIF.
    CHECK gv_ini IS INITIAL.
*    IF p_gjahr IS INITIAL.
*      gv_ini = 'Z'.
*    ENDIF.
    CHECK gv_ini IS INITIAL.
    IF so_augdt[] IS INITIAL.
      gv_ini = 'S'.
    ENDIF.
    CHECK gv_ini IS INITIAL.
    IF so_hkont[] IS INITIAL.
      gv_ini = 'A'.
    ENDIF.
    CHECK gv_ini IS INITIAL.
* Inizio inser. RM171215
    IF NOT so_docfo[] IS INITIAL AND so_budat[] IS INITIAL.
      gv_ini = 'R'.
    ENDIF.
    CHECK gv_ini IS INITIAL.
    IF  so_docfo[] IS INITIAL .
* Fine inser. RM171215
      IF 1 = 2.
        PERFORM extract_sl_n.
      ELSE.
        PERFORM extract_sl_n3.
      ENDIF.
* Inizio inser. RM171215
    ELSE.
      PERFORM extract_sl_n2.
    ENDIF.
* Fine inser. RM171215
    IF it_sl IS INITIAL.
      gv_ini = 'N'.
    ENDIF.
  ELSE.
    IF so_bstyp[] IS INITIAL.
      gv_ini = 'C' .
    ELSE.
      LOOP AT so_bstyp INTO wa_bstyp.
        IF wa_bstyp-low NE 'F' AND wa_bstyp-low NE 'K'.
          gv_ini = 'K'.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
    CHECK gv_ini IS INITIAL.
    IF so_bsart[] IS INITIAL.
      gv_ini = 'T'.
    ENDIF.
    CHECK gv_ini IS INITIAL.

    PERFORM extract_dc.
    IF it_dc IS INITIAL.
      gv_ini = 'N'.
    ENDIF.
  ENDIF.
************************************************************************
* END-OF-SELECTION.
************************************************************************
END-OF-SELECTION.
  CASE gv_ini.
    WHEN 'C'.
      MESSAGE 'Inserire almeno una categoria documento' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'K'.
      MESSAGE 'Valori possibili K ed F' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'T'.
      MESSAGE 'Inserire tipo documento Inserire data pareggio' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'S'.
      MESSAGE 'Inserire data pareggio' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'D'.
      MESSAGE 'Inserire società' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'I'.
      MESSAGE 'Inserire un ID' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'Z'.
      MESSAGE 'Inserire un esercizio' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'N'.
      MESSAGE 'Estrazione senza risultato' TYPE 'S' DISPLAY LIKE 'E'.
    WHEN 'A'.
      MESSAGE 'Inserire conto Co.Ge.' TYPE 'S' DISPLAY LIKE 'E'.
* Inizio inser. RM171215
    WHEN 'R'.
      MESSAGE 'Inserire Data reg. doc pareggiato' TYPE 'S' DISPLAY LIKE 'E'.
* Fine inser. RM171215
    WHEN space.

      IF ( p_ucomm IS INITIAL AND p_alv1 IS NOT INITIAL ) OR
         ( p_ucomm = 'PUSH2' AND p_alv2 IS NOT INITIAL ).
        PERFORM show_output.
      ELSE.
        PERFORM create_file.
        IF gv_ini = 'F'.
          MESSAGE 'Errore scrittura file' TYPE 'S' DISPLAY LIKE 'E'.
        ELSEIF gv_ini = 'O'.
          MESSAGE 'File creato con successo' TYPE 'S'.
        ENDIF.
      ENDIF.

  ENDCASE.








************************************************************************
* F O R M S
************************************************************************
*&--------------------------------------------------------------------*
*&      Form  at_selection_screen_output
*&---------------------------------------------------------------------*
FORM at_selection_screen_output .
*** >>> MEV 115301: Security code Review - M.P. <<< ***
  DATA: lv_value TYPE ZVALUE_COST.
*** >>> MEV 115301: Security code Review - M.P. <<< ***

* if the last choice is saved
  IF NOT pa_dynnr IS INITIAL.
*   activate the last choice
    tabs-dynnr     = pa_dynnr.
    tabs-activetab = pa_acttb.
*   clear the saved choice to make it only once
    pa_dynnr = ''.
    pa_acttb = ''.
  ENDIF.

  IF tabs-activetab = 'PUSH1'.
    IF p_alv1 = 'X'.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_LFIL1' OR  screen-name  = 'P_SFIL1').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
      CLEAR: p_sfil1, p_lfil1.
    ELSEIF p_s1 = 'X'.
      CONCATENATE gv_file 'Somme_liquidate_' lv_aaaammgg '.CSV' INTO lv_file.
      IF NOT ( p_sfil1 IS NOT INITIAL AND p_sfil1 NE lv_file ).
        MOVE lv_file TO p_sfil1.
      ENDIF.
      CLEAR p_lfil1.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_LFIL1').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ELSE.
*** >>> MEV 115301: Security code Review - M.P. <<< ***
      CLEAR lv_value.
      SELECT SINGLE value FROM zcost_value INTO lv_value
        WHERE repid = sy-repid
        AND   const = 'P_LFIL1'.
      if sy-subrc <> 0.
        lv_value =  text-tx1.
      endif.
      CONDENSE lv_value.
*      CONCATENATE 'C:\Somme_liquidate_' lv_aaaammgg '.CSV' INTO lv_file.
      CONCATENATE lv_value lv_aaaammgg '.CSV' INTO lv_file.
*** >>> MEV 115301: Security code Review - M.P. <<< ***
      IF NOT ( p_lfil1 IS NOT INITIAL AND p_lfil1 NE lv_file ).
        MOVE lv_file TO p_lfil1.
      ENDIF.
      CLEAR p_sfil1.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_SFIL1').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
    IF p_alv2 = 'X'.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_LFIL2' OR  screen-name  = 'P_SFIL2')." OR screen-name = 'P_S2' OR screen-name = 'P_F2').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
      CLEAR: p_sfil2, p_lfil2.
    ELSEIF p_s2 = 'X'.
      CONCATENATE gv_file 'Date_contrattuali_' lv_aaaammgg '.CSV' INTO lv_file.
      IF NOT ( p_sfil2 IS NOT INITIAL AND p_sfil2 NE lv_file ).
        MOVE lv_file TO p_sfil2.
      ENDIF.
      CLEAR p_lfil2.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_LFIL2').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ELSE.
*** >>> MEV 115301: Security code Review - M.P. <<< ***
      CLEAR lv_value.
      SELECT SINGLE value FROM zcost_value INTO lv_value
        WHERE repid = sy-repid
        AND   const = 'P_LFIL2'.
      if sy-subrc <> 0.
        lv_value =  text-tx2.
      endif.
      CONDENSE lv_value.
*      CONCATENATE 'C:\Date_contrattuali_' lv_aaaammgg '.CSV' INTO lv_file.
      CONCATENATE lv_value lv_aaaammgg '.CSV' INTO lv_file.
*** >>> MEV 115301: Security code Review - M.P. <<< ***
      IF NOT ( p_lfil2 IS NOT INITIAL AND p_lfil2 NE lv_file ).
        MOVE lv_file TO p_lfil2.
      ENDIF.
      CLEAR p_sfil2.
      LOOP AT SCREEN.
        IF  ( screen-name  = 'P_SFIL2').
          screen-input = 0.
          screen-output = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

ENDFORM.                    " at_selection_screen_output
*&---------------------------------------------------------------------*
*&      Form  initialitazion
*&---------------------------------------------------------------------*
FORM initialitazion .
  p_alv1 = p_alv2 = 'X'.
  lv_aaaammgg = sy-datum.
  tab1 = text-tb1.
  tab2 = text-tb2.
  IF NOT pa_dynnr IS INITIAL.
*   activate the last choice
    tabs-dynnr     = pa_dynnr.
    tabs-activetab = pa_acttb.
*   clear the saved choice to make it only once
    pa_dynnr = ''.
    pa_acttb = ''.
  ENDIF.

  CALL FUNCTION 'FILE_GET_NAME'
    EXPORTING
      client           = sy-mandt
      logical_filename = 'ZAVCP'
      operating_system = sy-opsys
    IMPORTING
      file_name        = gv_file.

  " valorizzazione tipo documento nel tab 2.
  CLEAR wa_bstyp.
  wa_bstyp-sign = 'I'.
  wa_bstyp-option = 'EQ'.
  wa_bstyp-low = 'F'.
  APPEND wa_bstyp TO so_bstyp.

  CLEAR wa_bstyp.
  wa_bstyp-sign = 'I'.
  wa_bstyp-option = 'EQ'.
  wa_bstyp-low = 'K'.
  APPEND wa_bstyp TO so_bstyp.

* NOINTERVLS: BT and NB not allowed
  CLEAR opt_list.
  MOVE 'NOINTERVLS' TO opt_list-name.
  MOVE 'X' TO: opt_list-options-cp,
               opt_list-options-eq,
               opt_list-options-ge,
               opt_list-options-gt,
               opt_list-options-le,
               opt_list-options-lt,
               opt_list-options-ne,
               opt_list-options-np.
  APPEND opt_list TO restrict-opt_list_tab.


  CLEAR ass.
  MOVE: 'S'           TO ass-kind,
        'SO_ZCIG'     TO ass-name,
        '*'           TO ass-sg_main,
        '*'           TO ass-sg_addy,
        'NOINTERVLS'  TO ass-op_main.
  APPEND ass TO restrict-ass_tab.


  CLEAR ass.
  MOVE: 'S'           TO ass-kind,
        'SO_CIG'      TO ass-name,
        '*'           TO ass-sg_main,
        '*'           TO ass-sg_addy,
        'NOINTERVLS'  TO ass-op_main.
  APPEND ass TO restrict-ass_tab.


  CLEAR ass.
  MOVE: 'S'        TO ass-kind,
        'SO_BSTYP' TO ass-name,
        '*'        TO ass-sg_main,
        '*'        TO ass-sg_addy,
        'NOINTERVLS'  TO ass-op_main.
  APPEND ass TO restrict-ass_tab.
  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
*   PROGRAM                      =
      restriction                  = restrict.
**   DB                           = ' '
*   EXCEPTIONS
*     too_late                     = 1
*     repeated                     = 2
*     selopt_without_options       = 3
*     selopt_without_signs         = 4
*     invalid_sign                 = 5
*     empty_option_list            = 6
*     invalid_kind                 = 7
*     repeated_kind_a              = 8
*     OTHERS                       = 9.

ENDFORM.                    " initialitazion
******&---------------------------------------------------------------------*
******&      Form  extract_sl
******&---------------------------------------------------------------------*
*****FORM extract_sl .
*****
*****  DATA: it_regup TYPE TABLE OF regup,
*****        wa_regup TYPE regup,
*****        lv_awtyp TYPE bkpf-awtyp.
*****
******  SELECT laufi
******         laufd
******         vblnr " id pagamento
******         belnr
******         bukrs
******         buzei " posizione
******         budat " data pagamento
******         gjahr " esercizio
******     FROM regup INTO CORRESPONDING FIELDS OF TABLE it_regup
******    WHERE laufi = p_laufi
******      AND laufd = p_laufd
******      AND blart IN so_blart
******      AND xvorl = space.
*****
*****
*****  CHECK it_regup[] IS NOT INITIAL.
*****
*****  LOOP AT it_regup INTO wa_regup.
*****    CLEAR lv_awtyp.
*****    SELECT SINGLE awtyp FROM bkpf INTO lv_awtyp
*****      WHERE bukrs = 'EPI'
*****        AND belnr = wa_regup-belnr
*****        AND gjahr = wa_regup-gjahr.
******    PERFORM read_text USING wa_regup lv_awtyp.
*****  ENDLOOP.
*****ENDFORM.                    " extract_sl
*&---------------------------------------------------------------------*
*&      Form  extract_sl_n
*&---------------------------------------------------------------------*
FORM extract_sl_n .

  DATA: itcig TYPE TABLE OF ty_cig,
        wacig TYPE ty_cig,
        wa_app_sl TYPE ty_sl.

  FIELD-SYMBOLS: <fsb> LIKE st_bkpf.
  FIELD-SYMBOLS: <fs_bseg> LIKE st_bseg.

*Begin MEV 108250
*  SELECT bukrs
*         budat
*         bldat
*         blart
*         awtyp
*         awkey
*         belnr
*         gjahr
*         cpudt
*       FROM bkpf INTO CORRESPONDING FIELDS OF TABLE it_bkpf
*    WHERE bukrs = 'EPI'
*      AND belnr IN so_belnr
*      AND bldat IN so_bldat
*      AND blart IN so_blart
*      AND gjahr = p_gjahr
*      AND cpudt IN so_cpudt.
*
*  CHECK it_bkpf[] IS NOT INITIAL.
*



  DATA: lt_bsas LIKE TABLE OF st_bsas,
        lt_bsak LIKE TABLE OF st_bsak,
        lt_bseg LIKE TABLE OF st_bseg,
        va_indice LIKE sy-tabix,
        lv_importo LIKE bsas-dmbtr.

  REFRESH: it_bsas, it_bsas_spec.

  SELECT bukrs
    hkont
    augdt
    augbl
    zuonr
    gjahr
    belnr
    buzei
    budat
    blart
    dmbtr
    FROM bsas INTO TABLE it_bsas
    WHERE bukrs = p_bukrs
      AND augdt IN so_augdt
      AND hkont IN so_hkont
      AND augbl IN so_augbl
      AND belnr IN so_belnr
      AND budat IN so_budat.

  IF sy-subrc EQ 0.
    LOOP AT it_bsas INTO st_bsas.
      va_indice = sy-tabix.
      IF st_bsas-belnr = st_bsas-augbl.
        DELETE it_bsas INDEX va_indice.
* Se il tipo documento è presente nel parametro Tipo doc. speciale
* il documento viene ripescato nella tab it_bsas_spec e segue una seconda estrazione in BSAS
        IF so_blrts[] IS NOT INITIAL."AB
          IF st_bsas-blart IN so_blrts.
            APPEND st_bsas TO it_bsas_spec.
          ENDIF.
        ELSE.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
*
* Per tutti i documenti Tipo doc. speciali si estrae la seconda volta da BSAS
  IF it_bsas_spec[] IS NOT INITIAL.
    lt_bsas[] = it_bsas_spec[].
    SORT lt_bsas BY bukrs augdt augbl.
    DELETE ADJACENT DUPLICATES FROM lt_bsas COMPARING bukrs augdt augbl.
    REFRESH it_bsas2.
    SELECT bukrs
    hkont
    augdt
    augbl
    zuonr
    gjahr
    belnr
    buzei
    budat
    blart
    dmbtr
**MZ inizio MEV 108250
    shkzg
**MZ fine MEV 108250
    FROM bsas INTO TABLE it_bsas2
      FOR ALL ENTRIES IN lt_bsas
    WHERE bukrs = p_bukrs
      AND augdt = lt_bsas-augdt
      AND augbl = lt_bsas-augbl.
    IF sy-subrc EQ 0.
      DELETE it_bsas2 WHERE blart NOT IN so_blart.
      SORT it_bsas2 BY belnr.
    ENDIF.

  ENDIF.
*
***MZ inizio MEV 108250
*  IF it_bsas[] IS NOT INITIAL.
*    REFRESH it_bsas_tmp.
*    SELECT bukrs
*      hkont
*      augdt
*      augbl
*      zuonr
*      gjahr
*      belnr
*      buzei
*      budat
*      blart
*      dmbtr
*      FROM bsas INTO TABLE it_bsas_tmp
*      FOR ALL ENTRIES IN it_bsas
*      WHERE bukrs = it_bsas-bukrs
*      AND augbl = it_bsas-belnr
*      AND belnr = it_bsas-belnr
**      AND augdt IN so_augdt
*      AND hkont IN so_hkont
*
**        AND augbl IN so_augbl
**        AND belnr IN so_belnr
**        AND budat IN so_budat
*      .
*    IF sy-subrc EQ 0.
*    ENDIF.
*  ENDIF.
***MZ fine MEV 108250

  IF it_bsas[] IS NOT INITIAL.
    REFRESH lt_bsas.
    SORT it_bsas.
    lt_bsas[] = it_bsas[].
    SORT lt_bsas BY bukrs belnr budat.
    DELETE ADJACENT DUPLICATES FROM lt_bsas COMPARING bukrs belnr budat.
    REFRESH it_bsak.
    SELECT bukrs
           lifnr
           umsks
           umskz
           augdt
           augbl
           zuonr
           gjahr
           belnr
           buzei
           budat
           blart
      FROM bsak INTO TABLE it_bsak
      FOR ALL ENTRIES IN lt_bsas
      WHERE bukrs = lt_bsas-bukrs
        AND lifnr IN so_lifn1
*        AND belnr = lt_bsas-belnr
        AND augdt = lt_bsas-budat
        AND augbl = lt_bsas-belnr
***MZ inizio 108250 asterisco
*        AND gjahr = lt_bsas-budat(4)
***MZ fine 108250 asterisco
        AND budat IN so_bud_f
        AND blart IN so_blart.
    IF sy-subrc EQ 0.
      SORT it_bsak." BY bukrs belnr gjahr.
      CLEAR va_indice.
      LOOP AT it_bsak INTO st_bsak.
        va_indice = sy-tabix.
        IF st_bsak-belnr = st_bsak-augbl.
          DELETE it_bsak INDEX va_indice.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*

  LOOP AT it_bsas2 INTO st_bsas.
    MOVE-CORRESPONDING st_bsas TO st_bsak.
    APPEND st_bsak TO it_bsak.
  ENDLOOP.

  IF it_bsak[] IS NOT INITIAL.
    lt_bsak[] = it_bsak[].
    SORT lt_bsak BY bukrs belnr gjahr buzei.
    DELETE ADJACENT DUPLICATES FROM lt_bsak COMPARING bukrs belnr gjahr buzei.
    REFRESH it_bseg.
    SELECT bukrs
           belnr
           gjahr
           buzei
           augbl
           hkont
           lifnr
           ebeln
**MZ inizio
           dmbtr
**MZ fine
      FROM bseg INTO TABLE it_bseg
      FOR ALL ENTRIES IN lt_bsak
      WHERE bukrs = lt_bsak-bukrs
        AND belnr = lt_bsak-belnr
        AND gjahr = lt_bsak-gjahr
        AND buzei = lt_bsak-buzei
* Inizio inser. RM15215
        AND koart = 'K'.
* Fine inser. RM151215
    IF sy-subrc EQ 0.
      SORT it_bseg.
    ENDIF.
  ENDIF.
*
  IF it_bseg[] IS NOT INITIAL.
    lt_bseg[] = it_bseg[].
    SORT lt_bseg BY bukrs belnr gjahr.
    DELETE ADJACENT DUPLICATES FROM lt_bseg COMPARING bukrs belnr gjahr.
    REFRESH it_bkpf.
    SELECT bukrs
           belnr
           gjahr
           blart
           bldat
           budat
           cpudt
           awtyp
           awkey
     FROM bkpf INTO TABLE it_bkpf
      FOR ALL ENTRIES IN lt_bseg
  WHERE bukrs = lt_bseg-bukrs
    AND belnr = lt_bseg-belnr
    AND gjahr = lt_bseg-gjahr.
    IF sy-subrc EQ 0.
      SORT it_bkpf.
    ENDIF.
  ENDIF.
**End MEV 108250

**MZ inizio
  SORT it_bseg.
**MZ fine
  LOOP AT it_bkpf ASSIGNING <fsb>.
    CLEAR wa_sl.
    wa_sl-belnr = <fsb>-belnr.
    wa_sl-gjahr = <fsb>-gjahr.
    READ TABLE it_bsas2 WITH KEY belnr = <fsb>-belnr
**MZ inizio MEV 108250
    INTO st_bsas BINARY SEARCH.
*    TRANSPORTING NO FIELDS.
**MZ fine MEV 108250
    IF sy-subrc EQ 0.
      wa_sl-augbl = st_bsas-augbl.
      wa_sl-imp_pag = st_bsas-dmbtr.
**MZ inizio MEV 108250
      IF st_bsas-shkzg = 'S'.
        CONDENSE wa_sl-imp_pag.
        CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
      ENDIF.
**MZ fine MEV 108250
    ENDIF.
    PERFORM date_convert USING <fsb>-cpudt CHANGING wa_sl-cpudt.
    wa_sl-blart = <fsb>-blart.
    PERFORM date_convert USING <fsb>-bldat CHANGING wa_sl-bldat.
    " recupera i CIG
    PERFORM read_text USING <fsb> CHANGING wa_sl-cig.
    " recupera fornitore fattura
    PERFORM get_lifnr_fatt USING <fsb> CHANGING wa_sl-lifnr_fatt.
    " recupera OdA, fornitore oda
    PERFORM get_oda USING <fsb> CHANGING wa_sl-ebeln wa_sl-lifnr_oda.
    " recupara il Numero Contratto relativo alla Posizione di OdA della Fattura
    PERFORM get_contract USING wa_sl-ebeln CHANGING wa_sl-konnr.

**MZ inizio ragiono per posizione
    READ TABLE it_bseg WITH KEY bukrs = <fsb>-bukrs
                                belnr = <fsb>-belnr
                                gjahr = <fsb>-gjahr
                                BINARY SEARCH
                                TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      LOOP AT it_bseg ASSIGNING <fs_bseg> FROM sy-tabix.
        IF <fs_bseg>-bukrs <> <fsb>-bukrs
        OR <fs_bseg>-belnr <> <fsb>-belnr
        OR <fs_bseg>-gjahr <> <fsb>-gjahr.
          EXIT.
        ELSE.
          " recupera l'importo netto
          PERFORM get_amount USING <fs_bseg> <fsb> wa_sl-lifnr_fatt CHANGING wa_sl-importo.
          wa_sl-buzei = <fs_bseg>-buzei.
          APPEND wa_sl TO it_sl.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  SORT it_sl BY lifnr_fatt.
  CLEAR va_indice.
  LOOP AT it_sl INTO wa_sl WHERE elab IS INITIAL.
    va_indice = sy-tabix.
    " recupera le info pagamento
    PERFORM get_info_pag CHANGING wa_sl  wa_sl-importo.
    MODIFY it_sl FROM wa_sl INDEX va_indice.
  ENDLOOP.

  LOOP AT it_sl INTO wa_sl.
    IF wa_sl-anno IS INITIAL.
      wa_sl-anno = wa_sl-bldat+6(4).
      MODIFY it_sl FROM wa_sl INDEX sy-tabix.
      " spacchettamento dei CIG replicando la riga:
    ENDIF.
    IF wa_sl-cig CA ','.
      DELETE it_sl INDEX sy-tabix.
      REFRESH itcig.
      SPLIT wa_sl-cig AT ',' INTO TABLE itcig.
      LOOP AT itcig INTO wacig.
        CLEAR wa_app_sl.
        MOVE-CORRESPONDING wa_sl TO wa_app_sl.
        wa_app_sl-cig = wacig-cig.
        CONDENSE wa_app_sl-cig.
        APPEND wa_app_sl TO it_sl.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
*

  DELETE it_sl WHERE augbl IS INITIAL.
**MZ inizio MEV 108250
*  IF so_augbl[] IS NOT INITIAL.
*    DELETE it_sl WHERE augbl NOT IN so_augbl.
*  ENDIF.
**MZ fine MEV 108250

  SORT it_sl BY belnr.

*Begin MEV 108250
* Ricavo importo pagamento parziale
  PERFORM get_payment_amount.
*End MEV 108250
ENDFORM.                    " extract_sl_n
*&---------------------------------------------------------------------*
*&      Form  read_text
*&---------------------------------------------------------------------*
FORM read_text  USING    p_wa_bkpf LIKE st_bkpf
                CHANGING p_cig TYPE tdline.

  DATA: t_lines LIKE tline OCCURS 0 WITH HEADER LINE,
        v_name  LIKE thead-tdname,
        w_lines LIKE tline,
        itab    TYPE TABLE OF string,
        w_itab  TYPE string.

  CLEAR: t_lines, t_lines[], v_name, p_cig.

  CASE p_wa_bkpf-awtyp.
    WHEN 'RMRP'. "fattura MM
      CONCATENATE p_wa_bkpf-bukrs p_wa_bkpf-belnr p_wa_bkpf-gjahr '001'
                          INTO v_name RESPECTING BLANKS.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          client                  = sy-mandt
          id                      = '0002'
          language                = sy-langu
          name                    = v_name
          object                  = 'DOC_ITEM'
          archive_handle          = 0
          local_cat               = ' '
        TABLES
          lines                   = t_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.


    WHEN 'BKPF'. "fattura FI

      CONCATENATE p_wa_bkpf-bukrs p_wa_bkpf-belnr p_wa_bkpf-gjahr '   '
            INTO v_name RESPECTING BLANKS.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          client                  = sy-mandt
          id                      = 'CIG'
          language                = sy-langu
          name                    = v_name
          object                  = 'BELEG'
          archive_handle          = 0
          local_cat               = ' '
        TABLES
          lines                   = t_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7
          OTHERS                  = 8.
      IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.


  ENDCASE.

  READ TABLE t_lines INDEX 1 INTO w_lines.
  CHECK w_lines-tdline IS NOT INITIAL .
  p_cig = w_lines-tdline.
***  IF sy-subrc = 0.
***    REFRESH: itab, t_lines.
***    CLEAR w_itab.
***    SPLIT w_lines-tdline AT ',' INTO TABLE itab.
***    CLEAR w_lines.
***    LOOP AT itab INTO w_itab.
***      IF w_itab NE '0000000000'.
***        CLEAR wa_sl.
***        wa_sl-cig = w_itab.
***        wa_sl-laufi = p_wa_regup-laufi.
***          PERFORM date_convert USING p_wa_regup-laufd CHANGING wa_sl-bldat.
***        COLLECT wa_sl INTO it_sl.
***      ENDIF.
***      CLEAR w_itab.
***    ENDLOOP.
***  ENDIF.

ENDFORM.                    " read_text
*&---------------------------------------------------------------------*
*&      Form  get_amount
*&---------------------------------------------------------------------*
FORM get_amount  USING    p_wa_bseg LIKE st_bseg
                          p_wa_bkpf LIKE st_bkpf
                          p_lifnr
                 CHANGING p_importo TYPE char16.

  DATA: wa_rbkp TYPE rbkp,
        it_bset TYPE TABLE OF bset,
        wa_bset TYPE bset,
**MZ inizio MEV 108250
*        it_bseg TYPE TABLE OF bseg, "RM061216D
*        it_bseg_tmp TYPE TABLE OF bseg,
**MZ fine MEV 108250
*        wa_bseg TYPE bseg,          "RM061216D
        wa_bseg LIKE st_bseg,                               "RM061216I
        lv_importo TYPE dmbtr.
  DATA: lv_hwste TYPE bset-hwste,
        lv_dmbtr TYPE bseg-dmbtr,
        lvb_shkzg TYPE bseg-shkzg,
        lvr_shkzg TYPE rseg-shkzg.
  DATA: fl_bsak .    "CRinaldi
  CLEAR p_importo.
  CASE p_wa_bkpf-awtyp.
    WHEN 'RMRP'.
      SELECT SINGLE rmwwr wmwst1 FROM rbkp INTO CORRESPONDING FIELDS OF wa_rbkp
        WHERE belnr = p_wa_bkpf-awkey+0(10)
          AND gjahr = p_wa_bkpf-awkey+10(4).
      CHECK sy-subrc = 0.
***
      CLEAR lvr_shkzg.
      SELECT SINGLE shkzg FROM rseg INTO lvr_shkzg
                          WHERE belnr = p_wa_bkpf-awkey+0(10)
                          AND gjahr = p_wa_bkpf-awkey+10(4).
*CRinaldi inizio
      IF sy-subrc NE 0.
        lvr_shkzg =  st_bsak-shkzg.
        fl_bsak = 'X'.
      ENDIF.
*CRinaldi fine
****
      lv_importo = wa_rbkp-rmwwr - wa_rbkp-wmwst1.
    WHEN 'BKPF' "fattura FI
      or 'BKPFF'. "fattura FI "RM061216I
*      SELECT mwskz hwbas FROM bset
*        INTO CORRESPONDING FIELDS OF TABLE it_bset
*      WHERE belnr = p_wa_bkpf-belnr
*        AND gjahr = p_wa_bkpf-gjahr
*        AND bukrs = p_wa_bkpf-bukrs.
*      CHECK it_bset IS NOT INITIAL.
*      SORT it_bset BY mwskz .
*      DELETE ADJACENT DUPLICATES FROM it_bset COMPARING mwskz.
*      LOOP AT it_bset INTO wa_bset.
*        lv_importo = lv_importo + wa_bset-hwbas.
*      ENDLOOP.

*     INSERT SG - START
      CLEAR: lv_dmbtr, lv_importo, lv_hwste.
*     Select su BSET
      SELECT mwskz shkzg hwbas hwste FROM bset
        INTO CORRESPONDING FIELDS OF TABLE it_bset
      WHERE belnr = p_wa_bkpf-belnr
        AND gjahr = p_wa_bkpf-gjahr
        AND bukrs = p_wa_bkpf-bukrs.
***MZ inizio 108250
*        AND buzei = p_wa_bseg-buzei.
***MZ fine 108250
*     Select su BSEG
**MZ inizio MEV 108250
*      IF it_bseg[] IS NOT INITIAL.
**MZ fine MEV 108250
      SELECT belnr buzei dmbtr shkzg augbl augdt FROM bseg
**MZ inizio MEV 108250
      INTO CORRESPONDING FIELDS OF TABLE it_bseg
    WHERE belnr = p_wa_bkpf-belnr
      AND gjahr = p_wa_bkpf-gjahr
      AND bukrs = p_wa_bkpf-bukrs
      AND koart = 'K'
**MZ inizio MEV 108250
*      AND lifnr = p_lifnr
      AND lifnr = p_wa_bseg-lifnr
      AND buzei = p_wa_bseg-buzei
**MZ fine MEV 108250
        .

*       INTO CORRESPONDING FIELDS OF TABLE it_bseg_tmp
*        FOR ALL ENTRIES IN it_bseg
*        WHERE   bukrs = it_bseg-bukrs
*        AND belnr  = it_bseg-belnr
*        AND gjahr  = it_bseg-gjahr
*        AND buzei  = it_bseg-buzei
*        AND augbl  = it_bseg-augbl.

*      ENDIF.
**MZ fine MEV 108250
*     Calcolo valore dmbtr

      CLEAR lvb_shkzg.
**MZ inizio asterisco
*      IF p_wa_bkpf-blart EQ 'GR'.
*        DATA : v_blart LIKE bkpf-blart.
*        DATA : v_augbl LIKE bseg-augbl.
*
*        LOOP AT it_bseg INTO wa_bseg WHERE augbl IS NOT INITIAL.
*
*****       mod ac
*          IF wa_bseg-augbl EQ v_augbl.
*            wa_bseg-dmbtr = wa_bseg-dmbtr * ( -1 ).
*          ENDIF.
*
*
*          CLEAR v_blart.
*          SELECT SINGLE blart INTO v_blart FROM bkpf WHERE
*                              belnr = wa_bseg-augbl
*                         AND   gjahr = wa_bseg-augdt+0(4).
*          IF sy-subrc EQ 0.
*            IF v_blart = 'KZ' OR v_blart = 'ZZ'.
*              lv_dmbtr = lv_dmbtr + wa_bseg-dmbtr.
*              lvb_shkzg = wa_bseg-shkzg.
*            ENDIF.
*          ENDIF.
*
*****        mod ac
**        lv_dmbtr = lv_dmbtr + wa_bseg-dmbtr.
**        lvb_SHKZG = wa_bseg-SHKZG.
*          MOVE wa_bseg-augbl TO v_augbl.
*
*        ENDLOOP.
*      ELSE.
*        LOOP AT it_bseg INTO wa_bseg.
*          lv_dmbtr = lv_dmbtr + wa_bseg-dmbtr.
*          lvb_shkzg = wa_bseg-shkzg.
*        ENDLOOP.
*      ENDIF.
**MZ fine asterisco

*     Se non trova nessun record in bset --> importo = BSEG-DMBTR
**MZ inizio
      IF  p_wa_bseg-shkzg = 'S'.                            "RM120116I
        lv_dmbtr = p_wa_bseg-dmbtr * -1.                    "RM120116I
      ELSE.                                                 "RM120116I
        lv_dmbtr = p_wa_bseg-dmbtr.
      ENDIF.                                                "RM120116I
**MZ fine
      IF it_bset IS INITIAL.
        lv_importo = lv_dmbtr.
      ELSE.
*       importo = bseg-dmbtr - bset-hwste
        LOOP AT it_bset INTO wa_bset.
          IF wa_bset-shkzg = 'H'.
            wa_bset-hwste = wa_bset-hwste * -1.
          ENDIF.
          lv_hwste = lv_hwste + wa_bset-hwste.
        ENDLOOP.
        lv_importo = lv_dmbtr - lv_hwste.
      ENDIF.
*     INSERT SG - END
  ENDCASE.


*  IF lv_importo LT 0.
*if lvb_SHKZG = 'S'.
**    lv_importo = lv_importo * ( -1 ).
*    p_importo = lv_importo.
*    CONDENSE p_importo.
*    CONCATENATE '-' p_importo INTO p_importo.
*  ELSE.
*    p_importo = lv_importo.
*    CONDENSE p_importo.
*  ENDIF.
*
*  if lvr_SHKZG = 'H'.
**    lv_importo = lv_importo * ( -1 ).
*    p_importo = lv_importo.
*    CONDENSE p_importo.
*    CONCATENATE '-' p_importo INTO p_importo.
*  ELSE.
*    p_importo = lv_importo.
*    CONDENSE p_importo.
*  ENDIF.
*MZ inizio MEV 108250
  IF p_wa_bkpf-awtyp NE 'RMRP'.
    CLEAR wa_bseg.
    READ TABLE it_bseg INTO wa_bseg INDEX 1.
    lvb_shkzg = wa_bseg-shkzg.
  ELSE.
    IF lvr_shkzg = 'S'.
      lvb_shkzg = 'H'.
    ELSE.
      lvb_shkzg = 'S'.
    ENDIF.
  ENDIF.
*MZ fine MEV 108250
  DATA chk_sign(2) .
  IF lvb_shkzg = 'S'.
*    lv_importo = lv_importo * ( -1 ).
    IF fl_bsak IS INITIAL.   "CRinaldi
      CLEAR chk_sign.
      chk_sign = SIGN( lv_importo ).
      IF chk_sign NE '1-'.
        p_importo = lv_importo.
        CONDENSE    p_importo.
        CONCATENATE  '-' p_importo INTO p_importo.
      ELSE.
        p_importo = lv_importo.
        REPLACE FIRST OCCURRENCE OF '-' IN p_importo WITH space.
        CONDENSE    p_importo.
        CONCATENATE  '-' p_importo INTO p_importo.
      ENDIF.
*CRinaldi inizio
    ELSE.
      IF lv_importo < 0.
        lv_importo  = lv_importo * -1.
      ENDIF.
      p_importo = lv_importo.
      CONDENSE p_importo.

    ENDIF.
*CRinaldi fine
**MZ inizio MEV 108250 asterisco
*  ELSEIF lvr_shkzg = 'H'.
*    p_importo = lv_importo.
*    CONDENSE p_importo.
*    CONCATENATE '-' p_importo INTO p_importo.
**MZ fine MEV 108250 asterisco
  ELSE.
    IF lv_importo < 0.
      lv_importo  = lv_importo * -1.
    ENDIF.
    p_importo = lv_importo.
    CONDENSE p_importo.
  ENDIF.




  CLEAR lvr_shkzg.
  CLEAR lvb_shkzg.
ENDFORM.                    " get_amount
*&---------------------------------------------------------------------*
*&      Form  get_info_pag
*&---------------------------------------------------------------------*
FORM get_info_pag  CHANGING p_wa_sl TYPE ty_sl
                       p_importo TYPE char16.
* determinazione
*          augdt - data pagamento
*          augbl - doc di pagamento,
*          pag_parz - pagamento parziale,
  DATA: lt_bseg TYPE TABLE OF bseg,
        wa_bseg TYPE bseg,
        ls_bseg TYPE bseg,
        ls_bkpf TYPE bkpf,
        ls_bapi3008_2 TYPE bapi3008_2,
        ls_sl TYPE ty_sl,
        ls_sl_new TYPE ty_sl.

  DATA : lv_importo TYPE dmbtr.
  CLEAR: wa_bseg, lt_bseg[], ls_sl.
  MOVE-CORRESPONDING p_wa_sl TO ls_sl.
  SELECT  *
  INTO CORRESPONDING FIELDS OF TABLE lt_bseg
  FROM bseg
  WHERE bukrs = 'EPI'
    AND belnr = p_wa_sl-belnr
    AND gjahr = p_wa_sl-gjahr
    AND koart = 'K'
**MZ inizio 108250
    AND buzei = p_wa_sl-buzei
**MZ fine 108250
    .
  CHECK lt_bseg IS NOT INITIAL.
  LOOP AT lt_bseg INTO wa_bseg.
    IF wa_bseg-augbl IS NOT INITIAL. "PAGAMENTO TOTALE
      CLEAR ls_bkpf.
      SELECT SINGLE *
           INTO ls_bkpf
           FROM bkpf
           WHERE belnr = wa_bseg-augbl
             AND gjahr = wa_bseg-augdt(4)
             AND bukrs = 'EPI'
             AND ( blart = 'KZ' OR blart = 'ZZ' OR blart = 'AB' OR blart = 'SK'
                   OR blart = 'G$' OR blart = 'GR').

****  mod ac 16.01.2014 begin
***  if ls_bkpf-blart eq 'AB'.
***          DATA: LT_BSAK TYPE BSAK OCCURS 0 WITH HEADER LINE.
***          SELECT * INTO CORRESPONDING FIELDS OF TABLE LT_BSAK FROM BSAK WHERE AUGBL = LS_BKPF-BELNR AND augdt = wa_bseg-augdt.
***
***
***            loop at lt_bsak WHERE BLART = 'KZ'.
***
***      CLEAR ls_bseg.
***      SELECT SINGLE *  INTO ls_bseg
***             FROM bseg
***            WHERE bukrs = lt_bsak-bukrs "'EPI'
***              AND belnr = lt_bsak-belnr
***              AND gjahr = lt_bsak-gjahr
***              AND augdt IN p_datpag
***              AND koart = 'K'.                              "#EC *
***      IF sy-subrc = 0.
***        MOVE-CORRESPONDING p_wa_sl TO ls_sl.
***        p_wa_sl-augbl = ls_bseg-augbl.
***        PERFORM date_convert USING ls_bseg-augdt CHANGING p_wa_sl-augdt.
***        APPEND ls_sl TO it_sl.
***      ENDIF.
***      ENDLOOP.
***    ENDIF.
***
*** else.
*
*****  mod ac 16.01.2014 end

      CHECK ls_bkpf IS NOT INITIAL.


* *****       mod ac 05.02.2014
*
*data : wa_bkpf2 like bkpf.
*select SINGLE * from bkpf into wa_bkpf2
*                where belnr = p_wa_sl-belnr
*                and gjahr   =  p_wa_sl-gjahr.
*if sy-subrc eq 0.
*
*       if wa_bkpf2-blart eq 'GR'.
*        if wa_bseg-augbl ne P_WA_SL-AUGBL.
*        exit.
*        else.
*          lv_importo = wa_bseg-dmbtr.
*           wa_bseg-SHKZG = 'H'.
*          p_importo = lv_importo.
*         CONDENSE p_importo.
*         CONCATENATE '-' p_importo INTO p_importo.
*        endif.
**        else.
**        lv_importo = wa_bseg-dmbtr.
**        if wa_bseg-SHKZG = 'S'.
**    p_importo = lv_importo.
**    CONDENSE p_importo.
**    CONCATENATE '-' p_importo INTO p_importo.
**  ELSEif wa_bseg-SHKZG = 'H'.
**  p_importo = lv_importo.
**    CONDENSE p_importo.
**    CONCATENATE '-' p_importo INTO p_importo.
*  ENDIF.
**        lvb_SHKZG = wa_bseg-SHKZG.
*        endif.
****

*      CLEAR ls_bseg.
*      SELECT SINGLE *  INTO ls_bseg
*             FROM bseg
*            WHERE bukrs = ls_bkpf-bukrs "'EPI'
*              AND belnr = ls_bkpf-belnr
*              AND gjahr = ls_bkpf-gjahr
**              AND augdt IN p_datpag
*              AND koart = 'K'.                              "#EC *
*      IF sy-subrc = 0.
*        MOVE-CORRESPONDING p_wa_sl TO ls_sl.

      IF ls_bkpf-blart EQ 'AB'.
        DATA: lt_bsak TYPE bsak OCCURS 0 WITH HEADER LINE.
        SELECT SINGLE * INTO lt_bsak FROM bsak WHERE augbl = ls_bkpf-belnr
                                               AND augdt = wa_bseg-augdt
                                               AND  ( blart = 'KZ' OR  blart = 'ZZ' OR blart = 'SK' ).
        IF p_wa_sl-augbl IS INITIAL.
          p_wa_sl-augbl = lt_bsak-belnr.
        ENDIF.
        CLEAR ls_bkpf.
        SELECT SINGLE *
             INTO ls_bkpf
             FROM bkpf
             WHERE belnr = lt_bsak-belnr
               AND gjahr = lt_bsak-gjahr
               AND bukrs = 'EPI'.
      ELSE.
        IF p_wa_sl-augbl IS INITIAL.
          p_wa_sl-augbl = ls_bkpf-belnr.
        ENDIF.
      ENDIF.
****

*        p_wa_sl-augbl = ls_bseg-augbl.
*        PERFORM date_convert USING ls_bseg-augdt CHANGING p_wa_sl-augdt.
*PERFORM date_convert USING ls_bkpf-bldat CHANGING p_wa_sl-augdt.


      PERFORM date_convert2 USING ls_bkpf-bldat ls_bkpf-budat CHANGING p_wa_sl-augdt p_wa_sl-budat.
*      ENDIF.
*    ENDIF.
**
    ENDIF.
**

    READ TABLE tb_bapi3008_2 INTO ls_bapi3008_2 WITH KEY vendor = p_wa_sl-lifnr_fatt.
    IF sy-subrc NE 0.
      REFRESH: tb_bapi3008_2, tb_bapi3008_b, tb_bapi3008_o.
      CALL FUNCTION 'BAPI_AP_ACC_GETBALANCEDITEMS'
        EXPORTING
          companycode       = wa_bseg-bukrs "'EPI'
          vendor            = wa_bseg-lifnr
          date_from         = '00000000'
          date_to           = sy-datum
*       IMPORTING
*         RETURN            =
        TABLES
          lineitems         = tb_bapi3008_b.
      APPEND LINES OF tb_bapi3008_b TO tb_bapi3008_2.
      " vado a vedere se ci sono solo pagamenti parziali
      CALL FUNCTION 'BAPI_AP_ACC_GETOPENITEMS'
        EXPORTING
          companycode = wa_bseg-bukrs "'EPI'
          vendor      = wa_bseg-lifnr
          keydate     = sy-datum
        TABLES
          lineitems   = tb_bapi3008_o.
      APPEND LINES OF tb_bapi3008_o TO tb_bapi3008_2.
    ENDIF.


    IF tb_bapi3008_2 IS NOT INITIAL.
      SORT tb_bapi3008_2 BY pstng_date doc_no ASCENDING.

      LOOP AT tb_bapi3008_2 INTO ls_bapi3008_2 WHERE inv_ref = p_wa_sl-belnr
                                                 AND inv_year = p_wa_sl-gjahr
                                                 AND ( doc_type = 'KZ' OR doc_type = 'ZZ' OR doc_type = 'SK' ).
        CLEAR ls_sl_new.
        MOVE-CORRESPONDING ls_sl TO ls_sl_new.

        ls_sl_new-augbl = ls_bapi3008_2-doc_no.
        PERFORM date_convert USING ls_bapi3008_2-pstng_date CHANGING ls_sl_new-augdt.
        PERFORM date_convert USING ls_bapi3008_2-pstng_date CHANGING ls_sl_new-budat.
        ls_sl_new-pag_parz = 'X'.
        ls_sl_new-elab = 'X'.
* Inizio inser. RM221215
        WRITE ls_bapi3008_2-amount TO ls_sl_new-imp_pag DECIMALS 2.
        CONDENSE ls_sl_new-imp_pag.
        REPLACE ALL OCCURRENCES OF '.' IN ls_sl_new-imp_pag WITH ''.
        REPLACE ALL OCCURRENCES OF ',' IN ls_sl_new-imp_pag WITH '.'.
        IF ls_bapi3008_2-db_cr_ind = 'H'.
          CONCATENATE '-' ls_sl_new-imp_pag INTO ls_sl_new-imp_pag.
        ENDIF.
* Fine inser. RM221215
        APPEND ls_sl_new TO it_sl.
      ENDLOOP.
    ENDIF.
*    endif.
***
*    endif.
**
  ENDLOOP.

  p_wa_sl-elab = 'X'.

ENDFORM.                    " get_info_pag
*&---------------------------------------------------------------------*
*&      Form  show_output
*&---------------------------------------------------------------------*
FORM show_output.

  PERFORM: layout_create,
           fieldcat_create.

  DATA: lt_sort TYPE  slis_t_sortinfo_alv ,
        ls_sort TYPE  slis_sortinfo_alv.
  ls_sort-fieldname = 'ZCIG'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO lt_sort.


  IF sy-batch IS INITIAL.
    CASE p_ucomm.

      WHEN space.
        DELETE it_sl WHERE  importo EQ '-0.00'.
        DELETE it_sl WHERE  importo EQ '0.00'.
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
         EXPORTING
           i_bypassing_buffer       = 'X'
           i_callback_program       = sy-cprog
*            i_callback_pf_status_set = 'SET_PF_STATUS'
           i_callback_user_command  = 'USER_COMMAND'
*        i_callback_top_of_page   = 'TOP_OF_PAGE'
           is_layout                = gd_layout
           it_fieldcat              = it_fieldcat
*      it_excluding             = it_excluding
*        it_sort                  = it_sort
*      it_events                = gt_events
         TABLES
           t_outtab                 = it_sl[].
      WHEN 'PUSH2'.


        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_bypassing_buffer       = 'X'
            i_callback_program       = sy-cprog
*            i_callback_pf_status_set = 'SET_PF_STATUS'
            i_callback_user_command  = 'USER_COMMAND'
*        i_callback_top_of_page   = 'TOP_OF_PAGE'
            is_layout                = gd_layout
            it_fieldcat              = it_fieldcat
*      it_excluding             = it_excluding
        it_sort                  = lt_sort "it_sort
*      it_events                = gt_events
          TABLES
            t_outtab                 = it_dc[].
    ENDCASE.
  ELSE.
    CASE p_ucomm.
      WHEN space.
        DELETE it_sl WHERE  importo EQ '-0.00'.
        DELETE it_sl WHERE  importo EQ '0.00'.
        CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
          EXPORTING
            i_bypassing_buffer = 'X'
            i_callback_program = sy-cprog
            is_layout          = gd_layout
            it_fieldcat        = it_fieldcat
*        it_sort            = it_sort
          TABLES
            t_outtab           = it_sl[].
      WHEN 'PUSH2'.
        CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
          EXPORTING
            i_bypassing_buffer = 'X'
            i_callback_program = sy-cprog
            is_layout          = gd_layout
            it_fieldcat        = it_fieldcat
            it_sort            = lt_sort
          TABLES
            t_outtab           = it_dc[].
    ENDCASE.
  ENDIF.


ENDFORM.                    " show_output
*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
FORM user_command USING r_ucomm     LIKE sy-ucomm           "#EC CALLED
                        rs_selfield TYPE slis_selfield.     "#EC CALLED
  IF r_ucomm = '&IC1' AND rs_selfield-value IS NOT INITIAL.
    CASE rs_selfield-sel_tab_field.
      WHEN 'IT_SL-BELNR' .
        SET PARAMETER ID 'BLN' FIELD rs_selfield-value.
        SET PARAMETER ID 'BUK' FIELD 'EPI'.
        CLEAR wa_sl.
        READ TABLE it_sl INTO wa_sl INDEX rs_selfield-tabindex.
        SET PARAMETER ID 'GJR' FIELD wa_sl-gjahr.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
      WHEN 'IT_SL-AUGBL'.
        SET PARAMETER ID 'BLN' FIELD rs_selfield-value.
        SET PARAMETER ID 'BUK' FIELD 'EPI'.
        CLEAR wa_sl.
        READ TABLE it_sl INTO wa_sl INDEX rs_selfield-tabindex.
        SET PARAMETER ID 'GJR' FIELD wa_sl-budat+6(4).
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
      WHEN 'IT_SL-EBELN'.
        SET PARAMETER ID 'BES' FIELD rs_selfield-value.
        CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
      WHEN 'IT_DC-EBELN'.
        CLEAR wa_dc.
        READ TABLE it_dc INTO wa_dc INDEX rs_selfield-tabindex.
        CASE wa_dc-bstyp.
          WHEN 'K'.  " contratto
            SET PARAMETER ID 'CTR' FIELD rs_selfield-value.
            CALL TRANSACTION 'ME33K' AND SKIP FIRST SCREEN.
*            PERFORM call_me33k USING rs_selfield-value.
          WHEN 'F'.  " ODA
            SET PARAMETER ID 'BES' FIELD rs_selfield-value.
            CALL TRANSACTION 'ME23N' AND SKIP FIRST SCREEN.
        ENDCASE.
    ENDCASE.
  ENDIF.
ENDFORM.                    "user_command

*&---------------------------------------------------------------------*
*&      Form  layout_create
*&---------------------------------------------------------------------*
FORM layout_create .
  gd_layout-colwidth_optimize = 'X'.
  gd_layout-zebra = 'X'.
  gd_layout-no_min_linesize = 'X'.
  gd_layout-min_linesize = 80.
  gd_layout-max_linesize = 1023.
  CASE p_ucomm.
    WHEN space.
      gd_layout-window_titlebar = text-tb1.
    WHEN 'PUSH2'.
      gd_layout-window_titlebar = text-tb2.
  ENDCASE.

ENDFORM.                    " layout_create
*&---------------------------------------------------------------------*
*&      Form  fieldcat_create
*&---------------------------------------------------------------------*
FORM fieldcat_create.

  REFRESH it_fieldcat.
  CASE p_ucomm.
    WHEN space.
      PERFORM: append_to_fieldcat USING 'CIG'            'CIG'                              '10'   space,
               append_to_fieldcat USING 'BELNR'          'N.Doc.Fatt'                       '10'   'X',
*               append_to_fieldcat USING 'BLDAT'          'Data Doc Fatt'                          '10',
*               append_to_fieldcat USING 'GJAHR '           'Data Reg Fatt'                  '4'   space,
               append_to_fieldcat USING 'GJAHR '         'AnnoFatt'                         '4'   space,
               append_to_fieldcat USING 'AUGBL'          'ID Pag'                           '10'   'X',
               append_to_fieldcat USING 'AUGDT'          'DtDocPag'                       '10'   space,
               append_to_fieldcat USING 'IMPORTO'        'Imp Net Fatt'                     '16'   space,
*               append_to_fieldcat USING 'LAUFI'          'ID Pag'                           '6' ,
*               append_to_fieldcat USING 'LAUFD'          'Data Pagamento'                   '10' ,
               append_to_fieldcat USING 'PAG_PARZ'       'PagParz'                          '1'    space,
               append_to_fieldcat USING 'LIFNR_FATT'     'FornitFatt'                       '10'   space,
               append_to_fieldcat USING 'EBELN'          'OdA'                              '10'   'X',
               append_to_fieldcat USING 'LIFNR_ODA'      'FornitOdA'                        '10'   space,
               append_to_fieldcat USING 'KONNR'          'Contratto'                        '10'   space,
               append_to_fieldcat USING 'CPUDT'          'DtAcqFatt'                        '10'   space,
               append_to_fieldcat USING 'BLDAT'          'DtDocFatt'                        '10'   space,
*               append_to_fieldcat USING 'AUGDT'          'Dt Reg Pagam'                     '10'   space.
               append_to_fieldcat USING 'BUDAT'          'DtRegPag'                         '10'   space,
               append_to_fieldcat USING 'IMP_PAG'        'Imp Ord Pag.'                     '16'   space,
*               append_to_fieldcat USING 'BLART'          'Tipo documento'                   '2'    space,
               append_to_fieldcat USING 'BLART'          'TD'                                '2'    space,
**MZ inizio
               append_to_fieldcat USING 'BUZEI'          'Pos.'                             '3'    space,
**MZ fine
* Inizio inser. RM211215
               append_to_fieldcat USING 'BKTXT'          'Testo testata'                    '25'   space,
               append_to_fieldcat USING 'XBLNR'          'Riferimento'                      '16'   space,
               append_to_fieldcat USING 'SGTXT'          'Testo posizione'                  '50'   space.
* Fine inser. RM211215


    WHEN 'PUSH2'.
      PERFORM: append_to_fieldcat USING 'ZCIG'           'CIG'                              '10'   space,
               append_to_fieldcat USING 'BEDAT'          'DtStipCont'                       '10'   space,
               append_to_fieldcat USING 'KDATB'          'DtInLavori'                       '10'   space,
               append_to_fieldcat USING 'KDATE'          'DtFnLavori'                       '10'   space,
               append_to_fieldcat USING 'EBELN'          'Contr/OdA Spot'                   '16'   'X',
               append_to_fieldcat USING 'LIFNR'          'Fornitore'                        '10'   space,
               append_to_fieldcat USING 'STCD2'          'Partita Iva'                      '11'   space,
               append_to_fieldcat USING 'STCD1'          'Codice Fiscale'                   '16'   space,
               append_to_fieldcat USING 'NAME1'          'Ragione sociale'                  '35'   space,
               append_to_fieldcat USING 'BSTYP'          'Cat Doc'                          '6'    space,
               append_to_fieldcat USING 'ZZATTO_OR'      'Atto Originale'                   '16'   space,
               append_to_fieldcat USING 'ZZTIPO_ATTO'    'Tipo Atto Aggiuntivo'             '16'   space,
               append_to_fieldcat USING 'DTODA'          'DtDocOdA'                         '10'   space,
               append_to_fieldcat USING 'EINDT'          'DtUltCons'                        '10'   space,
               append_to_fieldcat USING 'KTWRT'          'Val di test di AQ/ODA Spot'       '20'   space,
               append_to_fieldcat USING 'EKGRP'          'Grp Ac.'                          '6'    space,
               append_to_fieldcat USING 'EKNAM'          'Descr Grp Acquisti'               '18'   space,
               append_to_fieldcat USING 'ERNAM'          'Creato da'                        '12'   space,
               append_to_fieldcat USING 'AEDAT'          'Dt Acq Doc'                       '10'   space.

  ENDCASE.
ENDFORM.                    " fieldcat_create
*&---------------------------------------------------------------------*
*&      Form  append_to_fieldcat
*&---------------------------------------------------------------------*
FORM append_to_fieldcat  USING p_fieldname  TYPE slis_fieldname
                               p_label      TYPE scrtext_l
                               p_lenght     TYPE outputlen
                               p_hotspot    TYPE char1.

  DATA: wa_fieldcat LIKE LINE OF it_fieldcat.

  CLEAR wa_fieldcat.
  wa_fieldcat-fieldname = p_fieldname.
  wa_fieldcat-seltext_m = p_label.
  wa_fieldcat-seltext_l = p_label.
  wa_fieldcat-outputlen = p_lenght.
  wa_fieldcat-hotspot   = p_hotspot.
  CASE p_ucomm.
    WHEN space.
      wa_fieldcat-tabname = 'IT_SL'.
    WHEN 'PUSH2'.
      wa_fieldcat-tabname = 'IT_DC'.
  ENDCASE.
  APPEND wa_fieldcat TO it_fieldcat.
ENDFORM.                    " append_to_fieldcat
*&---------------------------------------------------------------------*
*&      Form  create_file
*&---------------------------------------------------------------------*
FORM create_file .

  TYPES: BEGIN OF ty,
            rec TYPE c LENGTH 1080,
           END OF ty.

  DATA: lv_importo TYPE c LENGTH 20,
        lv_imp_pag TYPE c LENGTH 20,
        lv_filename TYPE string,
        lv_server TYPE c LENGTH 1,
        itab TYPE TABLE OF ty,
        wa TYPE ty,
        lv_bedat TYPE c LENGTH 10,
        lv_kdatb TYPE c LENGTH 10,
        lv_kdate TYPE c LENGTH 10,
        lv_dtoda TYPE c LENGTH 10,
        lv_eindt TYPE c LENGTH 10,
        lv_aedat TYPE c LENGTH 10,
        lv_cpudt TYPE c LENGTH 10,
        vn_num_rec TYPE i,
        va_num_rec TYPE c LENGTH 10,
        lv_ktwrt TYPE c LENGTH 17.
*        lv_csv_cig TYPE c LENGTH 132.

  CLEAR: lv_filename, lv_server, vn_num_rec, va_num_rec.
  CASE p_ucomm.
    WHEN space.
      " trasforma tabella interna per creazione file somme liquidate
      CLEAR wa.
*      wa-rec = 'CIG;ID PAG;DATA PAGAMENTO;IMPORTO PAGAMENTO'.
      wa-rec = 'CIG;DOCUMENTO FATTURA;ESERCIZIO FATTURA;ID PAGAMENTO;DATA DOCUMENTO PAGAMENTO;'.
      CONCATENATE wa-rec
'IMPORTO NETTO FATTURA;IMPORTO PAGAMENTO PARZIALE;PAGAMENTO PARZIALE;FORNITORE FATTURA;OdA;FORNITORE ODA;NUMERO CONTRATTO;DATA ACQUISIZIONE FATTURA;DATA DOCUMENTO FATTURA;DATA REGISTRAZIONE PAGAMENTO;TIPO DOCUMENTO;N.RIGA;TESTO;RIFERIMENTO;TESTO POS.'
       INTO wa-rec.
      APPEND wa TO itab.
      LOOP AT it_sl INTO wa_sl.
        CLEAR: wa, lv_importo." lv_csv_cig.
        MOVE wa_sl-importo TO lv_importo.
        CONDENSE lv_importo.

        CLEAR: lv_imp_pag.
        MOVE wa_sl-imp_pag TO lv_imp_pag.
        CONDENSE lv_imp_pag.
*        CONCATENATE wa_sl-cig wa_sl-laufi wa_sl-laufd lv_importo INTO wa-rec SEPARATED BY ';'.
*        IF wa_sl-cig IS NOT INITIAL.
*          IF wa_sl-cig+0(1) NE '0'.
*            lv_csv_cig = wa_sl-cig.
*            CONDENSE lv_csv_cig.
*          ELSE.
*            CONCATENATE '"=""' wa_sl-cig '"""' INTO lv_csv_cig.
*            CONDENSE lv_csv_cig.
*          ENDIF.
*        ENDIF.
*        PERFORM date_convert USING wa_sl-cpudt CHANGING lv_cpudt.
        CONCATENATE
                  wa_sl-cig
*                  lv_csv_cig
                  wa_sl-belnr
                  wa_sl-anno
                  wa_sl-augbl
                  wa_sl-augdt
                  lv_importo "wa_sl-importo
                  lv_imp_pag
                  wa_sl-pag_parz
                  wa_sl-lifnr_fatt
                  wa_sl-ebeln
                  wa_sl-lifnr_oda
                  wa_sl-konnr
                  wa_sl-cpudt"lv_cpudt
                  wa_sl-bldat
                  wa_sl-budat
                  wa_sl-blart
* Inizio inser. RM040116
                  wa_sl-buzei
                  wa_sl-bktxt
                  wa_sl-xblnr
                  wa_sl-sgtxt
* Fine inser. RM040116
             INTO wa-rec
             SEPARATED BY ';'.
        APPEND wa TO itab.
        ADD 1 TO vn_num_rec.
      ENDLOOP.
      IF p_sfil1 IS NOT INITIAL.
        MOVE p_sfil1 TO lv_filename.
        lv_server = 'X'.
      ELSE.
        MOVE p_lfil1 TO lv_filename.
      ENDIF.

    WHEN 'PUSH2'.
      " trasforma tabella interna per creazione file date contrattuali
      CLEAR wa.
      wa-rec = 'CIG;DATA_STIPULA_CONTRATTO;DATA_INIZIO_LAVORI;DATA_FINE_LAVORI;DOCUMENTO SAP(CONTRATTO/ODA SPOT);FORNITORE;PARTITA IVA;'.
      CONCATENATE wa-rec 'CODICE FISCALE;RAGIONE SOCIALE;CATEGORIA DOCUMENTO;ATTO ORIGINALE;TIPO ATT. AGGIUNTIVO;DATA DOCUMENTO ODA;DATA ULTIMA CONSEGNA;'
      INTO wa-rec.
      CONCATENATE wa-rec 'VALORE DI TESTATA DELL''AQ/OdA SPOT;GRUPPO ACQUISTI;DESCR GRUPPO ACQUISTI;CREATO DA;DATA ACQUISIZIONE DOCUMENTO' INTO wa-rec.
      APPEND wa TO itab.
      SORT it_dc BY zcig.
      LOOP AT it_dc INTO wa_dc.
        CLEAR: wa, lv_bedat, lv_kdatb, lv_kdate, lv_eindt, lv_dtoda, lv_ktwrt, lv_aedat. "lv_csv_cig.
        PERFORM date_convert USING wa_dc-bedat CHANGING lv_bedat.
        PERFORM date_convert USING wa_dc-kdatb CHANGING lv_kdatb.
        PERFORM date_convert USING wa_dc-kdate CHANGING lv_kdate.
        PERFORM date_convert USING wa_dc-dtoda CHANGING lv_dtoda.
        PERFORM date_convert USING wa_dc-eindt CHANGING lv_eindt.
        PERFORM date_convert USING wa_dc-aedat CHANGING lv_aedat.
        MOVE wa_dc-ktwrt TO lv_ktwrt.
        CONDENSE lv_ktwrt.
**        IF wa_dc-zcig IS NOT INITIAL.
**          IF wa_dc-zcig+0(1) NE '0'.
**            lv_csv_cig = wa_dc-zcig.
**            CONDENSE lv_csv_cig.
**          ELSE.
**            CONCATENATE '"=""' wa_dc-zcig '"""' INTO lv_csv_cig.
**            CONDENSE lv_csv_cig.
**          ENDIF.
**        ENDIF.
        CONCATENATE
                    wa_dc-zcig
*                    lv_csv_cig
                    lv_bedat "wa_DC-bedat
                    lv_kdatb "wa_DC-kdatb
                    lv_kdate "wa_DC-kdate
                    wa_dc-ebeln
                    wa_dc-lifnr
                    wa_dc-stcd2
                    wa_dc-stcd1
                    wa_dc-name1
                    wa_dc-bstyp
                    wa_dc-zzatto_or
                    wa_dc-zztipo_atto
                    lv_dtoda "wa_DC-dtoda
                    lv_eindt "wa_DC-eindt
                    lv_ktwrt " WA_DC-KTWRT  "Valore di testata dell'AQ/ODA Spot
                    wa_dc-ekgrp  " Gruppo Acquisti
                    wa_dc-eknam  " descr Gruppo Acquisti
                    wa_dc-ernam  " creato da
                    lv_aedat     " data acquisizione documento
               INTO wa-rec SEPARATED BY ';'.
        APPEND wa TO itab.
        ADD 1 TO vn_num_rec.
      ENDLOOP.
      IF p_sfil2 IS NOT INITIAL.
        MOVE p_sfil2 TO lv_filename.
        lv_server = 'X'.
      ELSE.
        MOVE p_lfil2 TO lv_filename.
      ENDIF.
  ENDCASE.

  " aggiunta ultima riga con il numero totale di record:
  va_num_rec = vn_num_rec.
  CONDENSE va_num_rec.
  CONCATENATE 'TOTALE RECORD' va_num_rec INTO wa-rec SEPARATED BY space.
  APPEND wa TO itab.



  IF lv_server = 'X'.
    OPEN DATASET lv_filename FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
    IF sy-subrc NE 0.
      gv_ini = 'F'.
    ELSE.
      LOOP AT itab INTO wa.
        TRANSFER wa-rec TO lv_filename.
        CLEAR wa.
      ENDLOOP.
      CLOSE DATASET lv_filename.
      gv_ini = 'O'.
    ENDIF.
  ELSE.

    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename                = lv_filename
      TABLES
        data_tab                = itab
      EXCEPTIONS
        file_write_error        = 1
        no_batch                = 2
        gui_refuse_filetransfer = 3
        invalid_type            = 4
        no_authority            = 5
        unknown_error           = 6
        header_not_allowed      = 7
        separator_not_allowed   = 8
        filesize_not_allowed    = 9
        header_too_long         = 10
        dp_error_create         = 11
        dp_error_send           = 12
        dp_error_write          = 13
        unknown_dp_error        = 14
        access_denied           = 15
        dp_out_of_memory        = 16
        disk_full               = 17
        dp_timeout              = 18
        file_not_found          = 19
        dataprovider_exception  = 20
        control_flush_error     = 21
        OTHERS                  = 22.
    IF sy-subrc <> 0.
      gv_ini = 'F'.
    ELSE.
      gv_ini = 'O'.
    ENDIF.

  ENDIF.

ENDFORM.                    " create_file
*&---------------------------------------------------------------------*
*&      Form  check_extension
*&---------------------------------------------------------------------*
FORM check_extension  USING p_ft TYPE char1 p_filename LIKE ibipparms-path .
  DATA: fname TYPE string,                                  "#EC NEEDED
        lv_lung TYPE i,
        ext TYPE string.
  CHECK p_ft IS NOT INITIAL.
  CHECK p_filename IS NOT INITIAL.
  lv_lung = STRLEN( p_filename ) - 3.
  ext = p_filename+lv_lung(3).
  IF ext = 'csv'.  " converto l'estensione in maiuscolo CSV
    ext = p_filename+lv_lung(3) = 'CSV'.
  ENDIF.
  IF ext NE 'CSV'.
    MESSAGE 'File deve essere di tipo ".CSV"' TYPE 'E'.
  ENDIF.
ENDFORM.                    " check_extension
*&---------------------------------------------------------------------*
*&      Form  bstyp_help
*&---------------------------------------------------------------------*
FORM bstyp_help  CHANGING p_bstyp LIKE ekko-bstyp.
  TYPES: BEGIN OF ty_valori,
          bstyp TYPE ebstyp,
          ddtext TYPE val_text,
         END OF ty_valori.
  DATA: it_valori TYPE TABLE OF ty_valori.
  SELECT domvalue_l AS bstyp ddtext FROM dd07t INTO CORRESPONDING FIELDS OF TABLE it_valori
    WHERE domname = 'EBSTYP'
      AND ddlanguage = sy-langu
      AND ( domvalue_l = 'F'  OR domvalue_l = 'K').
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield     = 'BSTYP' " nome tecnico campo dello stesso tipo del parameter o della sel_opt.
      window_title = 'Categoria del documento d''acquisto'
      value_org    = 'S'
    TABLES
      value_tab    = it_valori   " tabelaa contente i valori che si volgiono visualizzare nel match-code
      return_tab   = it_return.


  READ TABLE it_return INTO wa_return INDEX 1.
  p_bstyp = wa_return-fieldval.

ENDFORM.                    " bstyp_help
*&---------------------------------------------------------------------*
*&      Form  extract_dc
*&---------------------------------------------------------------------*
FORM extract_dc .
  TYPES: BEGIN OF ty_eket,
    eindt LIKE eket-eindt,
    END OF ty_eket.
  FIELD-SYMBOLS: <fs_dc> TYPE ty_dc.
  DATA: it_eket TYPE TABLE OF ty_eket WITH HEADER LINE,
        wa_dc_app TYPE ty_dc.
  SELECT zcig
         bstyp
         lifnr
         ebeln
         zzatto_or
         zztipo_atto
         bedat
         kdatb
         kdate
         ktwrt
         ekgrp
         aedat
         ernam
    FROM ekko
    INTO CORRESPONDING FIELDS OF TABLE it_dc
    WHERE ebeln IN so_ebeln
      AND bstyp IN so_bstyp
      AND loekz = space
      AND bsart IN so_bsart
      AND bedat IN so_bedat
      AND zcig IN so_zcig
      AND zcig NE space
      AND lifnr IN so_lifnr
      AND aedat IN so_aedat.
*      AND kdatb IN so_kdatb.


  CHECK it_dc IS NOT INITIAL.
  LOOP AT it_dc ASSIGNING <fs_dc> WHERE name1 IS INITIAL.
    IF <fs_dc>-lifnr IS NOT INITIAL.
      SELECT SINGLE name1 stcd1 stcd2 INTO CORRESPONDING FIELDS OF <fs_dc> FROM lfa1 WHERE lifnr = <fs_dc>-lifnr.
      MODIFY it_dc FROM <fs_dc> TRANSPORTING stcd2 stcd1 name1 WHERE lifnr = <fs_dc>-lifnr.
    ENDIF.
  ENDLOOP.
  CLEAR wa_dc.
  MODIFY it_dc FROM wa_dc TRANSPORTING eindt WHERE bstyp = 'F'. " la data fine lavori deve essere presa dalla EKET per gli OdA,
  " quindi ripulisco la data fine lavori per gli OdA
  LOOP AT it_dc ASSIGNING <fs_dc> WHERE bstyp = 'F'.
*    CASE <fs_dc>-bstyp.
*      WHEN 'F'. " ODA
    REFRESH it_eket.
    SELECT eindt FROM eket INTO CORRESPONDING FIELDS OF TABLE it_eket WHERE ebeln = <fs_dc>-ebeln.
    CHECK it_eket[] IS NOT INITIAL.
    SORT it_eket BY eindt DESCENDING.
    READ TABLE it_eket INDEX 1.
    <fs_dc>-eindt = it_eket-eindt.
    MOVE <fs_dc>-bedat TO <fs_dc>-dtoda.
    CLEAR: "<fs_dc>-bedat,
           <fs_dc>-kdatb, <fs_dc>-kdate .
    " per gli ODA data inizio lavori = data documento oda e data fine lavori = data ultima consegna
    <fs_dc>-kdatb = <fs_dc>-dtoda.
    <fs_dc>-kdate = <fs_dc>-eindt.
    " importo da prendere sommando il campo EKPO-NETWR
    CLEAR <fs_dc>-ktwrt.
    SELECT SUM( netwr ) FROM ekpo INTO <fs_dc>-ktwrt WHERE ebeln = <fs_dc>-ebeln.
*        MODIFY it_dc FROM <fs_dc>.
*      WHEN 'K'. " CONTRATTO
*    ENDCASE.
  ENDLOOP.


  LOOP AT it_dc INTO wa_dc WHERE eknam IS INITIAL.
    CLEAR wa_dc_app.
    SELECT SINGLE eknam FROM t024 INTO wa_dc_app-eknam WHERE ekgrp = wa_dc-ekgrp.
    IF wa_dc_app-eknam IS NOT INITIAL.
      MODIFY it_dc FROM wa_dc_app TRANSPORTING eknam WHERE ekgrp = wa_dc-ekgrp.
    ENDIF.
  ENDLOOP.

*Begin MEV 108250
  DATA: lt_dc   TYPE TABLE OF ty_dc,
        lt_dc_tmp TYPE TABLE OF ty_dc,
        ls_dc TYPE ty_dc,
        ls_dc_tmp TYPE ty_dc.

  lt_dc[] = it_dc[].
  SORT lt_dc BY zcig.
*Per gli ODA con CIG uguale a 0000000000 o blank
*NON vale la regola seguente ma si visualizza la data estratta per ciascun ODA.
  DELETE lt_dc WHERE zcig IS INITIAL OR zcig = '0000000000'.
  DELETE ADJACENT DUPLICATES FROM lt_dc COMPARING zcig.

  LOOP AT lt_dc INTO ls_dc.
    CLEAR wa_dc_app.
    lt_dc_tmp[] = it_dc[].
    DELETE lt_dc_tmp WHERE zcig NE ls_dc-zcig.
    SORT lt_dc_tmp BY kdatb ASCENDING.
    CLEAR ls_dc_tmp.
    READ TABLE lt_dc_tmp INTO ls_dc_tmp INDEX 1.
    IF sy-subrc EQ 0.
      wa_dc_app-kdatb = ls_dc_tmp-kdatb.
    ENDIF.

    SORT lt_dc_tmp BY kdate DESCENDING.
    CLEAR ls_dc_tmp.
    READ TABLE lt_dc_tmp INTO ls_dc_tmp INDEX 1.
    IF sy-subrc EQ 0.
      wa_dc_app-kdate = ls_dc_tmp-kdate.
    ENDIF.

    MODIFY it_dc FROM wa_dc_app TRANSPORTING kdatb kdate
     WHERE zcig = ls_dc-zcig.
  ENDLOOP.
*End MEV 108250
ENDFORM.                    " extract_dc
*&---------------------------------------------------------------------*
*&      Form  browse_appl_serv
*&---------------------------------------------------------------------*
FORM browse_appl_serv  USING    p_s TYPE char1
                       CHANGING p_sfile TYPE rlgrap-filename.
  CHECK p_s IS NOT INITIAL.
  CALL FUNCTION '/SAPDMC/LSM_F4_SERVER_FILE'
    IMPORTING
      serverfile       = p_sfile
    EXCEPTIONS
      canceled_by_user = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Interruzione anomala del programma!' TYPE 'E'.
  ENDIF.

ENDFORM.                    " browse_appl_serv
*&---------------------------------------------------------------------*
*&      Form  browse_pres_serv
*&---------------------------------------------------------------------*
FORM browse_pres_serv  USING    p_l TYPE char1
                       CHANGING p_directory LIKE rlgrap-filename.
  CHECK p_l IS NOT INITIAL .
  DATA: directory TYPE string,
        filetable TYPE filetable,
        line      TYPE LINE OF filetable,
        rc        TYPE i.
  CALL METHOD cl_gui_frontend_services=>get_temp_directory
    CHANGING
      temp_dir = directory.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title      = 'Selezionare il file'
      initial_directory = directory
*      file_filter       = '*.txt'
      multiselection    = ' '
    CHANGING
      file_table        = filetable
       rc                = rc.
  IF rc = 1.
    READ TABLE filetable INDEX 1 INTO line.
    p_directory = line-filename.
  ENDIF.

ENDFORM.                    " browse_pres_serv*&---------------------------------------------------------------------*
*&      Form  f4_laufd
*&---------------------------------------------------------------------*
*&      Form  date_convert
*&---------------------------------------------------------------------*
FORM date_convert  USING    p_date TYPE datum
                   CHANGING p_extdate TYPE char10.

  CHECK p_date IS NOT INITIAL.
  CONCATENATE p_date+6(2) p_date+4(2) p_date+0(4) INTO p_extdate SEPARATED BY '/'.

ENDFORM.                    " date_convert

*&      Form  f4_laufd
*&---------------------------------------------------------------------*
*&      Form  date_convert
*&---------------------------------------------------------------------*
FORM date_convert2  USING   p_date TYPE datum
                            p_date2 TYPE datum
                   CHANGING p_extdate TYPE char10
                            p_extdate2 TYPE char10.

  CHECK p_date IS NOT INITIAL.
  CONCATENATE p_date+6(2) p_date+4(2) p_date+0(4) INTO p_extdate SEPARATED BY '/'.

  CHECK p_date2 IS NOT INITIAL.
  CONCATENATE p_date2+6(2) p_date2+4(2) p_date2+0(4) INTO p_extdate2 SEPARATED BY '/'.

ENDFORM.                    " date_convert


*&---------------------------------------------------------------------*
*&      Form  get_oda
*&---------------------------------------------------------------------*
FORM get_oda  USING    p_fsb LIKE st_bkpf
              CHANGING p_ebeln TYPE ebeln
                       p_lifnr_oda TYPE lifnr.
  CLEAR: p_lifnr_oda , p_ebeln.
  CHECK p_fsb-awtyp = 'RMRP'.
  SELECT SINGLE ebeln FROM bseg INTO p_ebeln
    WHERE belnr = p_fsb-belnr
    AND gjahr = p_fsb-gjahr
    AND bukrs = p_fsb-bukrs
    AND koart = 'S'
    AND buzid = 'W'.
  CHECK p_ebeln IS NOT INITIAL.
  SELECT SINGLE lifnr FROM ekko INTO p_lifnr_oda WHERE ebeln = p_ebeln.

ENDFORM.                    " get_oda
*&---------------------------------------------------------------------*
*&      Form  get_lifnr_fatt
*&---------------------------------------------------------------------*
FORM get_lifnr_fatt  USING    p_fsb LIKE st_bkpf
                     CHANGING p_lifnr_fatt.
  CLEAR p_lifnr_fatt.
  SELECT SINGLE lifnr FROM bseg
    INTO p_lifnr_fatt
    WHERE belnr = p_fsb-belnr
    AND gjahr = p_fsb-gjahr
    AND bukrs = p_fsb-bukrs
    AND koart = 'K'.

ENDFORM.                    " get_lifnr_fatt
*&---------------------------------------------------------------------*
*&      Form  get_contract
*&---------------------------------------------------------------------*
FORM get_contract  USING    p_ebeln TYPE ebeln
                   CHANGING p_konnr TYPE konnr.

  CLEAR p_konnr.
  IF p_ebeln NA space.
    SELECT SINGLE konnr FROM ekab INTO p_konnr WHERE ebeln = p_ebeln
      %_HINTS ORACLE 'index(ekab"Z01")'.                  "#EC CI_HINTS
  ENDIF.

ENDFORM.                    " get_contract
*&---------------------------------------------------------------------*
*&      Form  leggi_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM leggi_set USING p_set.
  DATA: val_setid     TYPE sethier-setid,
          tbl_set_value TYPE rgsb4 OCCURS 0 WITH HEADER LINE.


  CALL FUNCTION 'G_SET_GET_ID_FROM_NAME'
    EXPORTING
      shortname                = p_set  " nome set
    IMPORTING
      new_setid                = val_setid
    EXCEPTIONS
      no_set_found             = 1
      no_set_picked_from_popup = 2
      wrong_class              = 3
      wrong_subclass           = 4
      table_field_not_found    = 5
      fields_dont_match        = 6
      set_is_empty             = 7
      formula_in_set           = 8
      set_is_dynamic           = 9
      OTHERS                   = 10.

  IF sy-subrc <> 0.
  ENDIF.

  CALL FUNCTION 'G_SET_GET_ALL_VALUES'
    EXPORTING
      setnr         = val_setid
    TABLES
      set_values    = tbl_set_value
    EXCEPTIONS
      set_not_found = 1
      OTHERS        = 2.
  IF sy-subrc <> 0.
  ENDIF.

  REFRESH  r_hkont.
  CLEAR  r_hkont.

  LOOP AT tbl_set_value .

    r_hkont-sign = 'I'.

    IF tbl_set_value-to IS INITIAL.
      r_hkont-option = 'EQ'.
    ELSE.
      r_hkont-option = 'BT'.
      r_hkont-high   = tbl_set_value-to.
    ENDIF.
    r_hkont-low  = tbl_set_value-from.
    APPEND r_hkont.
    CLEAR r_hkont.

  ENDLOOP.

ENDFORM.                    " leggi_set
*&---------------------------------------------------------------------*
*&      Form  get_payment_amount
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_payment_amount .
  DATA: lt_sl TYPE TABLE OF ty_sl,
*        lv_importo LIKE bsas-dmbtr,
        lv_tabix LIKE sy-tabix.
  DATA:  ls_importo LIKE st_bsak_pag.
*          bukrs TYPE bsas-bukrs,
*          hkont TYPE bsas-hkont,
*          augdt TYPE bsas-augdt,
*          augbl TYPE bsas-augbl,
*          zuonr TYPE bsas-zuonr,
*          gjahr TYPE bsas-gjahr,
*          belnr TYPE bsas-belnr,
*          buzei TYPE bsas-buzei,
*          dmbtr TYPE bsas-dmbtr,
*        END OF ls_importo.

*  CHECK it_sl[] IS NOT INITIAL.
*  lt_sl[] = it_sl[].
*  DELETE lt_sl WHERE pag_parz NE 'X'.
*  SORT lt_sl BY augbl.
*  DELETE ADJACENT DUPLICATES FROM lt_sl COMPARING augbl.


*  REFRESH it_bsas_tmp.
*  SELECT bukrs
*    hkont
*    augdt
*    augbl
*    zuonr
*    gjahr
*    belnr
*    buzei
*    budat
*    dmbtr
*    FROM bsas INTO TABLE it_bsas_tmp
*    FOR ALL ENTRIES IN lt_sl
*    WHERE bukrs = p_bukrs
*      AND augdt IN so_augdt
*      AND belnr = lt_sl-augbl.
*  IF sy-subrc EQ 0.
*    SORT it_bsas_tmp BY belnr.
*  ENDIF.

  DATA: lv_budat LIKE bsas-budat.
  SORT it_sl BY belnr anno pag_parz.

  CLEAR lv_tabix.
  LOOP AT it_sl INTO wa_sl ."WHERE "pag_parz IS NOT INITIAL.
    lv_tabix = sy-tabix.
    READ TABLE it_bsas2
    WITH KEY belnr = wa_sl-belnr
    BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc NE 0.

**MZ inizio MEV 108250 ragionamento per righe di fatture con pagamenti parziali
    IF wa_sl-pag_parz IS INITIAL.
      CLEAR wa_sl_temp.
**cerco una riga dello stesso documento con pagamento parziale
      READ TABLE it_sl INTO wa_sl_temp
              WITH KEY belnr = wa_sl-belnr
                       anno = wa_sl-anno
                       pag_parz = 'X'
                       BINARY SEARCH.
      IF sy-subrc = 0.

        MOVE: wa_sl-augdt+6(4) TO lv_budat(4),
              wa_sl-augdt+3(2) TO lv_budat+4(2),
              wa_sl-augdt(2) TO lv_budat+6(2).

        SELECT SINGLE bukrs
                     hkont
                     augdt
                     augbl
                     zuonr
                     gjahr
                     belnr
                     buzei
                     budat
                     blart
                     dmbtr
*             *MZ inizio MEV 108250
                     shkzg
*             *MZ fine MEV 108250
        FROM bsas INTO is_bsas2_parz
        WHERE bukrs = p_bukrs
          AND augbl = wa_sl-augbl
          AND belnr = wa_sl-augbl
*          AND belnr <> wa_sl-augbl
          AND budat = lv_budat.
        IF sy-subrc EQ 0.
          IF is_bsas2_parz-shkzg = 'H'.
*          IF is_bsas2_parz-shkzg = 'S'.
            wa_sl-imp_pag = is_bsas2_parz-dmbtr.
            CONDENSE wa_sl-imp_pag.
            CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
          ELSE.
            wa_sl-imp_pag = is_bsas2_parz-dmbtr.
            CONDENSE wa_sl-imp_pag.
          ENDIF.

          MODIFY it_sl FROM wa_sl INDEX lv_tabix
          TRANSPORTING imp_pag.
**
          CONTINUE.
**
        ENDIF.
      ENDIF.
    ENDIF.
**MZ fine MEV 108250 ragionamento per righe di fatture con pagamenti parziali

**MZ inizio MEV 108250
    MOVE: wa_sl-budat+6(4) TO lv_budat(4),
          wa_sl-budat+3(2) TO lv_budat+4(2),
          wa_sl-budat(2) TO lv_budat+6(2).
**MZ fine MEV 108250
    CLEAR ls_importo.
*    SELECT SINGLE bukrs
*        hkont
*        augdt
*        augbl
*        zuonr
*        gjahr
*        belnr
*        buzei
*        budat
*        blart
*        dmbtr
*        FROM bsas INTO ls_importo"TABLE it_bsas_tmp
*        WHERE bukrs = p_bukrs
***MZ inizio MEV 108250
**           AND hkont IN so_hkont
*           AND augdt = lv_budat
**          AND augdt IN so_augdt
*           AND augbl = wa_sl-augbl
***MZ fine MEV 108250
*          AND belnr = wa_sl-augbl.
***MZ inizio MEV 108250
**          AND buzei = 001.
    SELECT SINGLE bukrs
        hkont
        augdt
        augbl
        zuonr
        gjahr
        belnr
        buzei
        budat
        blart
        dmbtr
        shkzg
        FROM bsak INTO ls_importo"TABLE it_bsas_tmp
        WHERE bukrs = p_bukrs
**MZ inizio MEV 108250
*           AND hkont IN so_hkont
           AND augdt = lv_budat
*          AND augdt IN so_augdt
           AND augbl = wa_sl-augbl
           AND belnr = wa_sl-belnr
           AND buzei = wa_sl-buzei
**MZ fine MEV 108250
*          AND belnr = wa_sl-augbl
          .
**MZ inizio MEV 108250
*          AND buzei = 001.
**MZ fine MEV 108250

**MZ inizio MEV 108250
    IF sy-subrc <> 0.
      SELECT SINGLE bukrs
        hkont
        augdt
        augbl
        zuonr
        gjahr
        belnr
        buzei
        budat
        blart
        dmbtr
        shkzg
        FROM bsak INTO ls_importo  "TABLE it_bsas_tmp
        WHERE bukrs = p_bukrs
**MZ inizio MEV 108250
*           AND hkont IN so_hkont
           AND augdt = lv_budat
*          AND augdt IN so_augdt
*           AND augbl = wa_sl-augbl
*           AND belnr = wa_sl-belnr
*           AND buzei = wa_sl-buzei
           AND augbl = wa_sl-augbl
           AND rebzg = wa_sl-belnr
           AND rebzz = wa_sl-buzei
**MZ fine MEV 108250
*          AND belnr = wa_sl-augbl
          .
    ENDIF.
**MZ fine MEV 108250

*    LOOP AT it_bsas_tmp INTO st_bsas." FROM sy-tabix.
*      IF st_bsas-belnr NE wa_sl-augbl.
*        EXIT.
*      ENDIF.
*      lv_importo = lv_importo + st_bsas-dmbtr.
*    ENDLOOP.

*    wa_sl-imp_pag = lv_importo.
    DATA: lvb_shkzg LIKE bsak-shkzg.
    CLEAR lvb_shkzg.
    lvb_shkzg = ls_importo-shkzg.

    IF lvb_shkzg = 'S'.
      wa_sl-imp_pag = ls_importo-dmbtr.
      CONDENSE wa_sl-imp_pag.
      CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
    ELSE.
      wa_sl-imp_pag = ls_importo-dmbtr.
      CONDENSE wa_sl-imp_pag.
    ENDIF.
    CLEAR lvb_shkzg.

    MODIFY it_sl FROM wa_sl INDEX lv_tabix
    TRANSPORTING imp_pag.
  ENDLOOP.
ENDFORM.                    " get_payment_amount
*&---------------------------------------------------------------------*
*&      Form  extract_sl_n2
*&---------------------------------------------------------------------*
FORM extract_sl_n2 .

  DATA: itcig TYPE TABLE OF ty_cig,
        wacig TYPE ty_cig,
        wa_app_sl TYPE ty_sl,
        c TYPE cursor.

  FIELD-SYMBOLS: <fsb>     LIKE st_bkpf.
  FIELD-SYMBOLS: <fs_bseg> LIKE st_bseg.

  DATA: lt_bsak LIKE TABLE OF st_bsak, "--> bsak2 valore del doc. pareggio
        lt_bseg LIKE TABLE OF st_bseg,
        va_indice  LIKE sy-tabix,
        lv_importo LIKE bsas-dmbtr.

  REFRESH it_bsak.

  OPEN CURSOR c FOR
    SELECT bukrs
           lifnr
           umsks
           umskz
           augdt
           augbl
           zuonr
           gjahr
           belnr
           buzei
           budat
           blart
    FROM bsak
      WHERE bukrs EQ p_bukrs
        AND lifnr IN so_lifn1
        AND budat IN so_budat
        AND belnr IN so_docfo.

  FETCH NEXT CURSOR c INTO TABLE it_bsak.
  CLOSE CURSOR c.

  IF LINES( it_bsak ) > 0.
    REFRESH lt_bsak.

    OPEN CURSOR c FOR
      SELECT bukrs
             lifnr
             umsks
             umskz
             augdt
             augbl
             zuonr
             gjahr
             belnr
             buzei
             budat
             blart
             dmbtr
             shkzg
    FROM bsak FOR ALL ENTRIES IN it_bsak
        WHERE bukrs EQ  it_bsak-bukrs
          AND lifnr EQ  it_bsak-lifnr
          AND augbl EQ  it_bsak-augbl.

    FETCH NEXT CURSOR c INTO TABLE lt_bsak.
    CLOSE CURSOR c.
  ENDIF.

  IF it_bsak[] IS NOT INITIAL.
    REFRESH it_bseg.
    SELECT bukrs
           belnr
           gjahr
           buzei
           augbl
           hkont
           lifnr
           ebeln
           dmbtr
           sgtxt
      FROM bseg INTO TABLE it_bseg
      FOR ALL ENTRIES IN lt_bsak
      WHERE bukrs = lt_bsak-bukrs
        AND belnr = lt_bsak-belnr
        AND gjahr = lt_bsak-gjahr
        AND buzei = lt_bsak-buzei
        AND koart = 'K'.
    IF sy-subrc EQ 0.
      SORT it_bseg.
    ENDIF.
  ENDIF.

  IF it_bseg[] IS NOT INITIAL.
    lt_bseg[] = it_bseg[].
    SORT lt_bseg BY bukrs belnr gjahr.
    DELETE ADJACENT DUPLICATES FROM lt_bseg COMPARING bukrs belnr gjahr.
    REFRESH it_bkpf.
    SELECT bukrs
           belnr
           gjahr
           blart
           bldat
           budat
           cpudt
           awtyp
           awkey
           bktxt
           xblnr
     FROM bkpf INTO TABLE it_bkpf
      FOR ALL ENTRIES IN lt_bseg
  WHERE bukrs = lt_bseg-bukrs
    AND belnr = lt_bseg-belnr
    AND gjahr = lt_bseg-gjahr.
    IF sy-subrc EQ 0.
      SORT it_bkpf.
    ENDIF.
  ENDIF.

*MZ inizio
  SORT it_bseg.
**MZ fine
  LOOP AT it_bkpf ASSIGNING <fsb>.
    CLEAR wa_sl.
    READ TABLE lt_bsak INTO st_bsak WITH KEY  belnr = <fsb>-belnr.
    IF sy-subrc = 0.
      IF st_bsak-augbl = <fsb>-belnr.
        CONTINUE.
      ELSE.
        wa_sl-augbl = st_bsak-augbl.
        wa_sl-imp_pag = st_bsak-dmbtr.
        CONDENSE wa_sl-imp_pag.
        IF st_bsak-shkzg = 'S'.
          CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
        ENDIF.
      ENDIF.
    ENDIF.

    wa_sl-belnr = <fsb>-belnr.
    wa_sl-gjahr = <fsb>-gjahr.
    wa_sl-bktxt = <fsb>-bktxt.
    wa_sl-xblnr = <fsb>-xblnr.

    PERFORM date_convert USING <fsb>-cpudt CHANGING wa_sl-cpudt.
    wa_sl-blart = <fsb>-blart.
    PERFORM date_convert USING <fsb>-bldat CHANGING wa_sl-bldat.
    " recupera i CIG
    PERFORM read_text USING <fsb> CHANGING wa_sl-cig.
    " recupera fornitore fattura
    PERFORM get_lifnr_fatt USING <fsb> CHANGING wa_sl-lifnr_fatt.
    " recupera OdA, fornitore oda
    PERFORM get_oda USING <fsb> CHANGING wa_sl-ebeln wa_sl-lifnr_oda.
    " recupara il Numero Contratto relativo alla Posizione di OdA della Fattura
    PERFORM get_contract USING wa_sl-ebeln CHANGING wa_sl-konnr.

**MZ inizio ragiono per posizione
    READ TABLE it_bseg WITH KEY bukrs = <fsb>-bukrs
                                belnr = <fsb>-belnr
                                gjahr = <fsb>-gjahr
                                BINARY SEARCH
                                TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      LOOP AT it_bseg ASSIGNING <fs_bseg> FROM sy-tabix.
        IF <fs_bseg>-bukrs <> <fsb>-bukrs
        OR <fs_bseg>-belnr <> <fsb>-belnr
        OR <fs_bseg>-gjahr <> <fsb>-gjahr.
          EXIT.
        ELSE.
          " recupera l'importo netto
          PERFORM get_amount USING <fs_bseg> <fsb> wa_sl-lifnr_fatt CHANGING wa_sl-importo.
          wa_sl-buzei = <fs_bseg>-buzei.
          wa_sl-sgtxt = <fs_bseg>-sgtxt.
          APPEND wa_sl TO it_sl.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  SORT it_sl BY lifnr_fatt.
  CLEAR va_indice.
  LOOP AT it_sl INTO wa_sl WHERE elab IS INITIAL.
    va_indice = sy-tabix.
    " recupera le info pagamento
    PERFORM get_info_pag CHANGING wa_sl  wa_sl-importo.
    MODIFY it_sl FROM wa_sl INDEX va_indice.
  ENDLOOP.

  LOOP AT it_sl INTO wa_sl.
    IF wa_sl-anno IS INITIAL.
      wa_sl-anno = wa_sl-bldat+6(4).
      MODIFY it_sl FROM wa_sl INDEX sy-tabix.
      " spacchettamento dei CIG replicando la riga:
    ENDIF.
    IF wa_sl-cig CA ','.
      DELETE it_sl INDEX sy-tabix.
      REFRESH itcig.
      SPLIT wa_sl-cig AT ',' INTO TABLE itcig.
      LOOP AT itcig INTO wacig.
        CLEAR wa_app_sl.
        MOVE-CORRESPONDING wa_sl TO wa_app_sl.
        wa_app_sl-cig = wacig-cig.
        CONDENSE wa_app_sl-cig.
        APPEND wa_app_sl TO it_sl.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
*

  DELETE it_sl WHERE augbl IS INITIAL.
**MZ inizio MEV 108250
*  IF so_augbl[] IS NOT INITIAL.
*    DELETE it_sl WHERE augbl NOT IN so_augbl.
*  ENDIF.
**MZ fine MEV 108250

  SORT it_sl BY belnr.

*Begin MEV 108250
* Ricavo importo pagamento parziale
  PERFORM get_payment_amount_2.
*End MEV 108250

ENDFORM.                    " extract_sl_n2
*&---------------------------------------------------------------------*
*&      Form  get_payment_amount_2
*&---------------------------------------------------------------------*
FORM get_payment_amount_2 .

  DATA: lt_sl TYPE TABLE OF ty_sl,
        lv_tabix LIKE sy-tabix.
  DATA: ls_importo LIKE st_bsak_pag.
  DATA: lv_budat LIKE bsas-budat.


  SORT it_sl BY belnr anno pag_parz.

  CLEAR lv_tabix.
  LOOP AT it_sl INTO wa_sl ."WHERE "pag_parz IS NOT INITIAL.
    lv_tabix = sy-tabix.
**MZ inizio MEV 108250 ragionamento per righe di fatture con pagamenti parziali
    IF wa_sl-pag_parz IS INITIAL.
      CLEAR wa_sl_temp.
**cerco una riga dello stesso documento con pagamento parziale
      READ TABLE it_sl INTO wa_sl_temp
              WITH KEY belnr = wa_sl-belnr
                       anno = wa_sl-anno
                       pag_parz = 'X'
                       BINARY SEARCH.
      IF sy-subrc = 0.

        MOVE: wa_sl-augdt+6(4) TO lv_budat(4),
              wa_sl-augdt+3(2) TO lv_budat+4(2),
              wa_sl-augdt(2) TO lv_budat+6(2).

        SELECT SINGLE bukrs
                     hkont
                     augdt
                     augbl
                     zuonr
                     gjahr
                     belnr
                     buzei
                     budat
                     blart
                     dmbtr
*             *MZ inizio MEV 108250
                     shkzg
*             *MZ fine MEV 108250
        FROM bsas INTO is_bsas2_parz
        WHERE bukrs = p_bukrs
          AND augbl = wa_sl-augbl
          AND belnr = wa_sl-augbl
*          AND belnr <> wa_sl-augbl
          AND budat = lv_budat.
        IF sy-subrc EQ 0.
          IF is_bsas2_parz-shkzg = 'H'.
*          IF is_bsas2_parz-shkzg = 'S'.
            wa_sl-imp_pag = is_bsas2_parz-dmbtr.
            CONDENSE wa_sl-imp_pag.
            CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
          ELSE.
            wa_sl-imp_pag = is_bsas2_parz-dmbtr.
            CONDENSE wa_sl-imp_pag.
          ENDIF.

          MODIFY it_sl FROM wa_sl INDEX lv_tabix
          TRANSPORTING imp_pag.
**
          CONTINUE.
**
        ENDIF.
      ENDIF.
    ENDIF.
**MZ fine MEV 108250 ragionamento per righe di fatture con pagamenti parziali

  ENDLOOP.

ENDFORM.                    " get_payment_amount_2
*&---------------------------------------------------------------------*
*&      Form  extract_sl_n3
*&---------------------------------------------------------------------*
FORM extract_sl_n3 .

  DATA: itcig TYPE TABLE OF ty_cig,
        wacig TYPE ty_cig,
        wa_app_sl TYPE ty_sl.

  FIELD-SYMBOLS: <fsb> LIKE st_bkpf.
  FIELD-SYMBOLS: <fs_bseg> LIKE st_bseg.

  DATA: lt_bsas LIKE TABLE OF st_bsas,
        lt_bsak LIKE TABLE OF st_bsak,
        lt_bseg LIKE TABLE OF st_bseg,
        va_indice LIKE sy-tabix,
        lv_importo LIKE bsas-dmbtr.

  REFRESH: it_bsas, it_bsas_spec.
* ESTRAZIONE BSAS
  SELECT bukrs
    hkont
    augdt
    augbl
    zuonr
    gjahr
    belnr
    buzei
    budat
    blart
    dmbtr
    shkzg  "CRinaldi
    FROM bsas INTO TABLE it_bsas
    WHERE bukrs = p_bukrs
      AND augdt IN so_augdt
      AND hkont IN so_hkont
      AND augbl IN so_augbl
      AND belnr IN so_belnr.

  SORT it_bsas BY bukrs belnr budat.
  DELETE ADJACENT DUPLICATES FROM it_bsas COMPARING bukrs belnr budat.

* ESTRAZIONE DA BSEG CON DATI ESTRATTI DA BSAS
  IF it_bsas[] IS NOT INITIAL.
    REFRESH it_bseg.
    SELECT bukrs
           belnr
           gjahr
           buzei
           augbl
           hkont
           lifnr
           ebeln
           dmbtr
           augdt
           sgtxt
           umskz
           shkzg
      FROM bseg INTO TABLE it_bseg
      FOR ALL ENTRIES IN it_bsas
      WHERE bukrs = it_bsas-bukrs
        AND belnr = it_bsas-belnr
        AND gjahr = it_bsas-gjahr
        AND lifnr IN so_lifn1
        AND koart = 'K'.
    IF sy-subrc EQ 0.
      SORT it_bseg.
    ENDIF.
  ENDIF.

* ESTRAZIONE DA BSAK CON DATI ESTRATTI DA BSEG
  IF it_bseg[] IS NOT INITIAL.
    REFRESH it_bsak.
    SELECT bukrs
           lifnr
           umsks
           umskz
           augdt
           augbl
           zuonr
           gjahr
           belnr
           buzei
           budat
           bldat
           blart
           dmbtr
           shkzg
           cpudt
           sgtxt
      FROM bsak INTO TABLE it_bsak
      FOR ALL ENTRIES IN it_bseg
      WHERE bukrs = it_bseg-bukrs
        AND lifnr IN so_lifn1
        AND augdt = it_bseg-augdt
        AND augbl = it_bseg-augbl
        AND blart IN so_blart.

* Se tra documenti estratti dalla bask esiste un blart = a tipo doc speciale, ritorniamo su BSeg
    IF LINES( it_bsak ) > 0.
      IF NOT so_blrts[] IS INITIAL.
        REFRESH lt_bsak.
        LOOP AT it_bsak INTO st_bsak WHERE blart IN so_blrts.
          APPEND st_bsak TO lt_bsak.
        ENDLOOP.
        IF sy-subrc = 0.
          SELECT bukrs
                 belnr
                 gjahr
                 buzei
                 augbl
                 hkont
                 lifnr
                 ebeln
                 dmbtr
                 augdt
                 sgtxt
                 umskz
                 shkzg
           FROM bseg APPENDING TABLE it_bseg
           FOR ALL ENTRIES IN lt_bsak
           WHERE bukrs = lt_bsak-bukrs
             AND belnr = lt_bsak-belnr
*           AND budat = it_bsak-budat
             AND gjahr = lt_bsak-gjahr
             AND umskz IN so_umskz.
          IF sy-subrc EQ 0.
            SORT it_bseg.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

  IF it_bsak[] IS NOT INITIAL.
    lt_bseg[] = it_bseg[].
    SORT lt_bseg BY bukrs belnr gjahr.
    DELETE ADJACENT DUPLICATES FROM lt_bseg COMPARING bukrs belnr gjahr.
    REFRESH it_bkpf.
    SELECT bukrs
           belnr
           gjahr
           blart
           bldat
           budat
           cpudt
           awtyp
           awkey
           bktxt
           xblnr
     FROM bkpf INTO TABLE it_bkpf
*      FOR ALL ENTRIES IN lt_bseg
        FOR ALL ENTRIES IN it_bsak
  WHERE bukrs = it_bsak-bukrs
    AND belnr = it_bsak-belnr
    AND gjahr = it_bsak-gjahr.
*  WHERE bukrs = lt_bseg-bukrs
*    AND belnr = lt_bseg-belnr
*    AND gjahr = lt_bseg-gjahr.
    IF sy-subrc EQ 0.
      SORT it_bkpf.
      SELECT bukrs belnr gjahr buzei augbl hkont lifnr ebeln dmbtr augdt sgtxt umskz shkzg
        FROM bseg
        INTO TABLE lt_bseg
        FOR ALL ENTRIES IN it_bkpf
        WHERE bukrs = it_bkpf-bukrs
        AND   belnr = it_bkpf-belnr
        AND   gjahr = it_bkpf-gjahr
        AND   lifnr IN so_lifn1
        AND   koart = 'K'.
    ENDIF.
  ENDIF.

*  SORT lt_bseg BY bukrs belnr gjahr.
*  DELETE ADJACENT DUPLICATES FROM lt_bseg COMPARING bukrs belnr gjahr.

  LOOP AT it_bsak INTO st_bsak.
    IF LINES( lt_bsak ) > 0.
      READ TABLE lt_bsak WITH KEY bukrs = st_bsak-bukrs
                                  augbl = st_bsak-augbl
                                  gjahr = st_bsak-gjahr
                                  belnr = st_bsak-belnr
                                  TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        LOOP AT lt_bseg ASSIGNING <fs_bseg> WHERE  bukrs = st_bsak-bukrs
                                            AND    belnr = st_bsak-belnr
                                            AND    gjahr = st_bsak-gjahr
                                            AND    umskz IN so_umskz.
          EXIT.
        ENDLOOP.
        CHECK sy-subrc = 0.
      ENDIF.
    ENDIF.
    CLEAR wa_sl.
* Doc Fatt
    wa_sl-belnr = st_bsak-belnr.
* Data Reg Fatt
    wa_sl-gjahr = st_bsak-gjahr.
* Tipo documento
    wa_sl-blart = st_bsak-blart.
* Posizione documento
    wa_sl-buzei = st_bsak-buzei.
* Testo
    wa_sl-sgtxt = st_bsak-sgtxt.
* Dt Acq Fatt
    PERFORM date_convert USING st_bsak-cpudt CHANGING wa_sl-cpudt.
* Data Doc Fatt
    PERFORM date_convert USING st_bsak-bldat CHANGING wa_sl-bldat.

* Imp Ord Pag.
    wa_sl-imp_pag = st_bsak-dmbtr.
    CONDENSE wa_sl-imp_pag.
    IF st_bsak-shkzg = 'S'.
      CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
    ENDIF.

* Dati da BKPF
    READ TABLE it_bkpf ASSIGNING <fsb> WITH KEY  bukrs = st_bsak-bukrs
                                                 belnr = st_bsak-belnr
                                                 gjahr = st_bsak-gjahr.
    IF sy-subrc = 0.
      wa_sl-bktxt = <fsb>-bktxt.
      wa_sl-xblnr = <fsb>-xblnr.

      " recupera i CIG
      PERFORM read_text USING <fsb> CHANGING wa_sl-cig.
      " recupera fornitore fattura
      PERFORM get_lifnr_fatt USING <fsb> CHANGING wa_sl-lifnr_fatt.
      " recupera OdA, fornitore oda
      PERFORM get_oda USING <fsb> CHANGING wa_sl-ebeln wa_sl-lifnr_oda.
      " recupara il Numero Contratto relativo alla Posizione di OdA della Fattura
      PERFORM get_contract USING wa_sl-ebeln CHANGING wa_sl-konnr.

*      READ TABLE it_bsas WITH KEY belnr = st_bsak-augbl
*      INTO st_bsas BINARY SEARCH.

* ID Pag
      LOOP AT it_bsas INTO st_bsas WHERE  belnr = st_bsak-augbl
                                  AND   ( blart = 'KZ' OR blart = 'ZZ'  OR blart = 'SK').
        EXIT.
      ENDLOOP.
      IF sy-subrc EQ 0.
        wa_sl-augbl   = st_bsas-belnr.
      ENDIF.

**MZ inizio ragiono per posizione
      READ TABLE lt_bseg WITH KEY bukrs = <fsb>-bukrs
                                  belnr = <fsb>-belnr
                                  gjahr = <fsb>-gjahr
                                  buzei = st_bsak-buzei
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        LOOP AT lt_bseg ASSIGNING <fs_bseg> FROM sy-tabix.
          IF <fs_bseg>-bukrs <> <fsb>-bukrs
          OR <fs_bseg>-belnr <> <fsb>-belnr
          OR <fs_bseg>-gjahr <> <fsb>-gjahr
          OR <fs_bseg>-buzei <> st_bsak-buzei.
            EXIT.
          ELSE.
            " recupera l'importo netto
            PERFORM get_amount USING <fs_bseg> <fsb> wa_sl-lifnr_fatt CHANGING wa_sl-importo.
            APPEND wa_sl TO it_sl.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDLOOP.



  SORT it_sl BY lifnr_fatt.
  CLEAR va_indice.
  DATA: wa_sl2 LIKE wa_sl, lf_dmbtr TYPE bsak-dmbtr, lf_shkzg TYPE bsak-shkzg.
  LOOP AT it_sl INTO wa_sl WHERE elab IS INITIAL.
    va_indice = sy-tabix.
    " recupera le info pagamento
    PERFORM get_info_pag CHANGING wa_sl  wa_sl-importo.
    READ TABLE it_sl INTO wa_sl2 WITH KEY belnr = wa_sl-belnr
                                          pag_parz = 'X'.
    IF sy-subrc = 0.
      SELECT SINGLE dmbtr shkzg INTO (lf_dmbtr, lf_shkzg) FROM bsak
        WHERE bukrs = p_bukrs
        AND   augbl = wa_sl-augbl
        AND   belnr = wa_sl-augbl
        AND   gjahr = wa_sl-budat+6(4).
      IF sy-subrc = 0.
        wa_sl-imp_pag = lf_dmbtr.
        CONDENSE wa_sl-imp_pag.
        IF lf_shkzg = 'H'.
          CONCATENATE '-' wa_sl-imp_pag INTO wa_sl-imp_pag.
        ENDIF.
      ENDIF.
    ENDIF.
    MODIFY it_sl FROM wa_sl INDEX va_indice.
  ENDLOOP.

  LOOP AT it_sl INTO wa_sl.
    IF wa_sl-anno IS INITIAL.
      wa_sl-anno = wa_sl-bldat+6(4).
      MODIFY it_sl FROM wa_sl INDEX sy-tabix.
      " spacchettamento dei CIG replicando la riga:
    ENDIF.
    IF wa_sl-cig CA ','.
      DELETE it_sl INDEX sy-tabix.
      REFRESH itcig.
      SPLIT wa_sl-cig AT ',' INTO TABLE itcig.
      LOOP AT itcig INTO wacig.
        CLEAR wa_app_sl.
        MOVE-CORRESPONDING wa_sl TO wa_app_sl.
        wa_app_sl-cig = wacig-cig.
        CONDENSE wa_app_sl-cig.
        APPEND wa_app_sl TO it_sl.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
*

  DELETE it_sl WHERE augbl IS INITIAL.

  SORT it_sl BY belnr.

* Ricavo importo pagamento parziale
  PERFORM get_payment_amount_2.

ENDFORM.                    " extract_sl_n3


*Messages
*----------------------------------------------------------
*
* Message class: Hard coded
*   Inserire almeno una categoria documento

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2018. Sap Release 700
