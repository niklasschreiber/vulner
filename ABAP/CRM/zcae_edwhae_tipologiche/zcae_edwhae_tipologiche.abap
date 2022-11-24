*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_TIPOLOGICHE
*&
*&---------------------------------------------------------------------*
*&Creato da: Paola Ferabecoli
*&
*& Data Creazione: 12/01/2009
*&
*&
*& Descrizione: L'interfaccia permette l'estrazione di tutti gli elementi
*&              dati utilizzate nelle diverse interfacce verso EDWAE
*&
*&---------------------------------------------------------------------*
* -- Modifiche:    Luca Manfreda
* -- Data:         27/09/2010
* -- Descrizione:  Aggiunta delle tipologiche dei campi legati ai
* --               contratti PTB
* -- CR SAP:       CWDK915600
*----------------------------------------------------------------------*
* -- Modifiche:    Mariassunta Addesse
* -- Data:         17/11/2011
* -- Descrizione:  Aggiunta delle tipologiche dei campi legati ai
* --               contratti PTB
* -- CR SAP:       CWDK916984
*----------------------------------------------------------------------*
* -- Modifiche:    Umberto Del Tosto
* -- Data:         27/06/2013
* -- Descrizione:  Aggiunta delle tipologiche dei campi legati ai
* --               flussi: NAZIONI - STATO_CIVILE - PROVINCE - COMUNI
* -- CR SAP:       CWDK990820
*----------------------------------------------------------------------*
* -- Modifiche:    Annalisa Olivier
* -- Data:         10/12/2013
* -- Descrizione:  Aggiunta delle tipologiche dei campi legati ai
* --               flussi: Target esteso -  Consenso FIRMA ELETTRONICA
* -- CR SAP:       CWDK993286
*----------------------------------------------------------------------*
REPORT  zcae_edwhae_tipologiche.

INCLUDE zcae_edwhae_tipologiche_top.

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
  IF p_cod IS INITIAL.
* Estrazioni dal DB
    PERFORM estrazioni.

  ELSE.
    PERFORM estrazioni_lista.
  ENDIF.

* trasferimento file
  PERFORM trasferimento_file.
* Chiude i file di output e log
  PERFORM chiudi_file.


*&---------------------------------------------------------------------*
*&      Form  recupera_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_FOUT  text
*      -->P_VA_TS  text
*      <--P_VA_FILEOUT  text
*----------------------------------------------------------------------*
FORM recupera_file  USING p_logic TYPE filename-fileintern
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

  OPEN DATASET va_filelog FOR OUTPUT IN TEXT MODE ENCODING DEFAULT.
  IF sy-subrc IS NOT INITIAL.
    CLOSE DATASET va_fileout.
    MESSAGE e208(00) WITH text-e05.
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

  "Inizio mf 18/06/2012
  DATA: lt_privacy TYPE STANDARD TABLE OF zca_privacy,
        lt_coint   TYPE STANDARD TABLE OF zca_param,
        lt_inte    TYPE STANDARD TABLE OF zca_param,
        lt_00067   TYPE STANDARD TABLE OF zca_param,
        " -- Inizio modifiche MF del 22.08.2012 10:51:30
        lt_opz     TYPE STANDARD TABLE OF zca_param,
        lt_naz     TYPE STANDARD TABLE OF zca_param,  "VPM14.05.2014 - NFEC - mod nazioni
        lt_prat    TYPE STANDARD TABLE OF zca_param,
        lt_return  TYPE bapiret2_t,
        lt_descr   TYPE STANDARD TABLE OF crmc_proc_type_t.
  " -- Fine modifiche MF del 22.08.2012 10:51:33
*start VPM14.05.2014 - NFEC - mod nazioni
  TYPES: BEGIN OF t_nation,
           landx50 TYPE t005t-landx50,
           natio50 TYPE t005t-natio50,
           intca   TYPE t005-intca,
           landk   TYPE t005-landk,
           land1   TYPE t005-land1,
         END OF t_nation.
  DATA: lw_nation  TYPE t_nation,
        lt_nation  LIKE STANDARD TABLE OF lw_nation,
        lv_sopp(1).
*end VPM14.05.2014 - NFEC - mod nazioni
  DATA: lv_applicazione    TYPE zappl          VALUE 'RETAIL',
        lv_tipo_conto      TYPE zca_tipo_conto VALUE 'CPIU',
        lv_mod_conto       TYPE zca_id         VALUE '01',
        lv_tipo_cliente    TYPE char10         VALUE 'RETAIL',
        lt_grado_parentela TYPE zca_grad_parent_s,
        lt_professione_crm TYPE zst_professione_crm,
        lt_qualifica       TYPE zca_qualifica_s,
        lt_settore         TYPE zca_settore_s,
        lt_titolo_studio   TYPE zca_tit_studio_s,
        ls_grado_parentela TYPE zca_tipcont_grad,
        ls_professione_crm TYPE tsad5,
        ls_qualifica       TYPE zca_tipcont_qual,
        ls_settore         TYPE zca_tipcont_sect,
        ls_titolo_studio   TYPE bbp_academic_keys.

  FIELD-SYMBOLS:   <fs_privacy> TYPE zca_privacy,
                   <fs_coint>   TYPE zca_param,
                   <fs_inte>    TYPE zca_param,
                   <fs_00067>   TYPE zca_param,
                   " -- Inizio modifiche MF del 22.08.2012 10:55:41
                   <fs_ozp>     TYPE zca_param,
                   <fs_prat>    TYPE zca_param,
                   <fs_descr>   TYPE crmc_proc_type_t.
  " -- Fine modifiche MF del 22.08.2012 10:55:43
  "Fine mf 18/06/2012

* Begin AG 21.09.2012
  DATA lv_descr TYPE string.
* End   AG 21.09.2012

* Begin AG 06.02.2014
  DATA: lt_ztipo_promo_bun TYPE STANDARD TABLE OF ztipo_promo_bun.
  FIELD-SYMBOLS <fs_promo_bun> TYPE ztipo_promo_bun.
* End   AG 06.02.2014


*Estrazione RELTYP tranne relazioni di tipo retail ('00001')
  SELECT * FROM tbz9a
    WHERE spras = 'IT'
    AND reltyp <> 'ZR3001'.
    MOVE '00001' TO output-codice.
    IF tbz9a-reltyp(1) = 'Z'.
      MOVE tbz9a-reltyp TO output-valore.
      MOVE tbz9a-bez50_2 TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDIF.
  ENDSELECT.

*Estrazione type ('00002')
  SELECT * FROM dd07t
    WHERE ddlanguage = 'IT'
    AND domname = 'BU_TYPE'.
    MOVE '00002' TO output-codice.
    MOVE dd07t-domvalue_l TO output-valore.
    MOVE dd07t-ddtext TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione bpkind ('00003')
  SELECT * FROM tb004t
    WHERE spras = 'I'.
    MOVE '00003' TO output-codice.
    MOVE tb004t-bpkind TO output-valore.
    MOVE tb004t-text40 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione bu_group ('00004')
  SELECT * FROM tb002
    WHERE spras = 'I'.
    MOVE '00004' TO output-codice.
    MOVE tb002-bu_group TO output-valore.
    MOVE tb002-txt40 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione segm_corporate ('00005')
  SELECT * FROM crmc_attr10_t
    WHERE spras = 'I'.
    MOVE '00005' TO output-codice.
    MOVE crmc_attr10_t-attrib_10 TO output-valore.
    MOVE crmc_attr10_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione pot_comm ('00006')
  SELECT * FROM zca_pot_comm.
    MOVE '00006' TO output-codice.
    MOVE zca_pot_comm-pot_comm TO output-valore.
    MOVE zca_pot_comm-descrizione TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione type-card ('00007')
  SELECT * FROM dd07t
    WHERE ddlanguage = 'IT'
    AND domname = 'ZCHAR1'.
    MOVE '00007' TO output-codice.
    MOVE dd07t-domvalue_l TO output-valore.
    IF dd07t-domvalue_l = '1'.
      MOVE 'Card Primaria' TO output-descrizione.
    ELSEIF
    dd07t-domvalue_l = '2'.
      MOVE 'Card Secondaria' TO output-descrizione.
    ENDIF.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione attiva ('00008')
  output-codice = '00008'.
  output-valore = 'X'.
  output-descrizione = 'attiva'.
  APPEND output.
  CLEAR output.
  output-codice = '00008'.
  output-valore = ''.
  output-descrizione = 'non attiva'.
  APPEND output.
  CLEAR output.

* Estrazione process-type attività-opportunità-reclami ('00009)
  SELECT * FROM crmc_proc_type_t
    WHERE langu = 'I'.
    MOVE '00009' TO output-codice.
    MOVE crmc_proc_type_t-process_type TO output-valore.
    SELECT SINGLE * FROM  zcrmc_eew_1002_t WHERE spras = 'I' AND zz_opzione = crmc_proc_type_t-process_type.
    IF sy-subrc = '0'.
      MOVE zcrmc_eew_1002_t-text TO output-descrizione.
    ELSE.
      MOVE crmc_proc_type_t-p_description TO output-descrizione.
    ENDIF.
    APPEND output.
    CLEAR output.
  ENDSELECT.


*Estrazione cod_risultato attività-opportunità ('00010')
  SELECT * FROM qpct
    WHERE sprache = 'I'.
    MOVE '00010' TO output-codice.
    CONCATENATE qpct-katalogart qpct-codegruppe qpct-code INTO output-valore.
    MOVE qpct-kurztext TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione categoria ('00011')
  SELECT * FROM crmc_act_cat_t
    WHERE langu = 'I'.
    MOVE '00011' TO output-codice.
    MOVE crmc_act_cat_t-category TO output-valore.
    MOVE crmc_act_cat_t-description TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Mezzo di Contatto- reclami('00012')
  SELECT * FROM zcrmc_eew_0404_t
    WHERE spras = 'I'.
    MOVE '00012' TO output-codice.
    MOVE zcrmc_eew_0404_t-zzcustomer_h0404 TO output-valore.
    MOVE zcrmc_eew_0404_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Canale acquisizione- reclami('00013')
  SELECT * FROM zcrmc_eew_0401_t
    WHERE spras = 'I'.
    MOVE '00013' TO output-codice.
    MOVE zcrmc_eew_0401_t-zzcustomer_h0401 TO output-valore.
    MOVE zcrmc_eew_0401_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Valore contratto- reclami('00014')
  SELECT * FROM zcrmc_eew_0403_t
    WHERE spras = 'I'.
    MOVE '00014' TO output-codice.
    MOVE zcrmc_eew_0403_t-zzcustomer_h0403 TO output-valore.
    MOVE zcrmc_eew_0403_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione motivazione- reclami('00015')
  SELECT * FROM zcrmc_eew_0407_t
    WHERE spras = 'I'.
    MOVE '00015' TO output-codice.
    MOVE zcrmc_eew_0407_t-zzcustomer_h0407 TO output-valore.
    MOVE zcrmc_eew_0407_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Area- reclami('00016')
  SELECT * FROM zcrmc_eew_0406_t
    WHERE spras = 'I'.
    MOVE '00016' TO output-codice.
    MOVE zcrmc_eew_0406_t-zzcustomer_h0406 TO output-valore.
    MOVE zcrmc_eew_0406_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Priorità- reclami('00017')
  SELECT * FROM scpriot
    WHERE langu = 'I'.
    MOVE '00017' TO output-codice.
    MOVE scpriot-priority TO output-valore.
    MOVE scpriot-txt_long TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Mezzo com risposta- reclami('00018')
  SELECT * FROM zcrmc_eew_0402_t
    WHERE spras = 'I'.
    MOVE '00018' TO output-codice.
    MOVE zcrmc_eew_0402_t-zzcustomer_h0402 TO output-valore.
    MOVE zcrmc_eew_0402_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione status survey ('00019')
  SELECT * FROM dd07t
    WHERE ddlanguage = 'IT'
    AND domname = 'CRM_SVY_DB_SVS_STATUS'.
    MOVE '00019' TO output-codice.
    MOVE dd07t-domvalue_l TO output-valore.
    MOVE dd07t-ddtext TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione ZZRUOLOVENDI0001 ('00020')
  SELECT * FROM ztb00005xwkl9t
    WHERE spras = 'I'.
    MOVE '00020' TO output-codice.
    MOVE ztb00005xwkl9t-zzruolovendi0001 TO output-valore.
    MOVE ztb00005xwkl9t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione ID_SETTORE ('00021')
  SELECT * FROM zca_settorigav.
    MOVE '00021' TO output-codice.
    MOVE zca_settorigav-zid_settore TO output-valore.
    MOVE zca_settorigav-zds_settore TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Operazioni-Contratti ('00022')
  SELECT * FROM zcrmc_eew_1001_t
    WHERE spras = 'I'.
    MOVE '00022' TO output-codice.
    MOVE zcrmc_eew_1001_t-zz_operazione TO output-valore.
    MOVE zcrmc_eew_1001_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Tipo Documento Precedente-Contratti ('00023')
  SELECT * FROM crmc_subob_cat_t
    WHERE langu = 'I'.
    MOVE '00023' TO output-codice.
    MOVE crmc_subob_cat_t-subobj_category TO output-valore.
    MOVE crmc_subob_cat_t-s_description TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Tipologia Posizione-Contratti ('00024')
  SELECT * FROM crmc_item_type_t
    WHERE langu = 'I'.
    MOVE '00024' TO output-codice.
    MOVE crmc_item_type_t-itm_type TO output-valore.
    MOVE crmc_item_type_t-i_description TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Stato posizione-Contratti ('00025')
  SELECT * FROM tj30t
    WHERE stsma = 'ZODSIT01'
    AND spras = 'I'.
    MOVE '00025' TO output-codice.
    MOVE tj30t-estat TO output-valore.
    MOVE tj30t-txt30 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Funzione Partner-Contratti ('00026')
  SELECT * FROM crmc_partner_ft
    WHERE spras = 'I'.
    MOVE '00026' TO output-codice.
    MOVE crmc_partner_ft-partner_fct TO output-valore.
    MOVE crmc_partner_ft-description TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Fascia numero dipendenti ('00027')
  SELECT * FROM zca_fasciadipgav.
    MOVE '00027' TO output-codice.
    MOVE zca_fasciadipgav-zid_fascia TO output-valore.
    MOVE zca_fasciadipgav-zds_fascia TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione motivazione 2° livello ('00028')
  SELECT * FROM zcrmc_eew_0204_t
    WHERE spras = 'I'.
    MOVE '00028' TO output-codice.
    MOVE zcrmc_eew_0204_t-zz_denom TO output-valore.
    MOVE zcrmc_eew_0204_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.
  SELECT * FROM zcrmc_eew_1502_t
    WHERE spras = 'I'.
    MOVE '00028' TO output-codice.
*    MOVE ZCRMC_EEW_1502_T-ZZ_CATMOT_S TO output-valore.
    CONCATENATE 'I' zcrmc_eew_1502_t-zz_catmot_s INTO output-valore.
    MOVE zcrmc_eew_1502_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione area country ('00029')
  SELECT * FROM ztb0000rv2kwjt
    WHERE spras = 'I'.
    MOVE '00029' TO output-codice.
    MOVE ztb0000rv2kwjt-zzarea TO output-valore.
    MOVE ztb0000rv2kwjt-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione classe documento ('00030')
  SELECT * FROM crmc_subob_cat_t
    WHERE langu = 'I'.
    MOVE '00030' TO output-codice.
    MOVE crmc_subob_cat_t-subobj_category TO output-valore.
    MOVE crmc_subob_cat_t-s_description_20 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione convenzioni ('00031')
  SELECT * FROM zcrmc_eew_1305_t
    WHERE spras = 'I'.
    MOVE '00031' TO output-codice.
    MOVE zcrmc_eew_1305_t-zz_cod_conv TO output-valore.
    MOVE zcrmc_eew_1305_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

* Begin AG 06.02.2014
* è necessario estendere la tipologica con i valori presenti
* nella tabella ZTIPO_PROMO_BUN ovvero è necessario estrarre tutti i
* record presenti nella tabella che abbiano il campo
* COD_PROMO_EDWH valorizzato.
* Dopo aver eliminato i duplicati rispetto a questo campo aggiungere
* al file di output i record rimasti valorizzando:
* -	Codice = 000310
* -	Valore = ZTIPO_COD_PROMO-COD_PROMO_EDWH
* -	Descrizione = ZTIPO_COD_PROMO-TEXT
  SELECT *
   FROM ztipo_promo_bun
   INTO TABLE lt_ztipo_promo_bun
   WHERE cod_promo_edwh NE space.
  MOVE '00031' TO output-codice.
  LOOP AT lt_ztipo_promo_bun ASSIGNING <fs_promo_bun>.
    MOVE <fs_promo_bun>-cod_promo_edwh TO output-valore.
    MOVE <fs_promo_bun>-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDLOOP.
* End   AG 06.02.2014

*Estrazione lavorazioni ('00032')
  SELECT * FROM zcrmc_eew_1403_t
    WHERE spras = 'I'.
    MOVE '00032' TO output-codice.
    MOVE zcrmc_eew_1403_t-zz_descr_lavor_i TO output-valore.
    MOVE zcrmc_eew_1403_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione tipi lavorazione ('00033')
  SELECT * FROM zcrmc_eew_1404_t
    WHERE spras = 'I'.
    MOVE '00033' TO output-codice.
    MOVE zcrmc_eew_1404_t-zz_lavorazione_i TO output-valore.
    MOVE zcrmc_eew_1404_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione categorie motivazione ('00034')
  SELECT * FROM zcrmc_eew_1402_t
    WHERE spras = 'I'.
    MOVE '00034' TO output-codice.
    MOVE zcrmc_eew_1402_t-zz_cat_motivaz_i TO output-valore.
    MOVE zcrmc_eew_1402_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione motivazioni ('00035')
  SELECT * FROM zcrmc_eew_1401_t
    WHERE spras = 'I'.
    MOVE '00035' TO output-codice.
    MOVE zcrmc_eew_1401_t-zz_motivaz_nor_i TO output-valore.
    MOVE zcrmc_eew_1401_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione tipologia opportunità ('00036')
  SELECT * FROM zcrmc_eew_0202_t
    WHERE spras = 'I'.
    MOVE '00036' TO output-codice.
    MOVE zcrmc_eew_0202_t-zz_tip_opp_biz TO output-valore.
    MOVE zcrmc_eew_0202_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione filiale ('00037')
  SELECT * FROM ztb0000672y1qt
    WHERE spras = 'I'.
    MOVE '00037' TO output-codice.
    MOVE ztb0000672y1qt-zzfiliale TO output-valore.
    MOVE ztb0000672y1qt-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione tipologie di firma ('00038')
  SELECT * FROM zcrmc_eew_1308_t
    WHERE spras = 'I'.
    MOVE '00038' TO output-codice.
    MOVE zcrmc_eew_1308_t-zz_firma TO output-valore.
    MOVE zcrmc_eew_1308_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Stato posizione-Contratti ('00039')
  SELECT * FROM tj30t
    WHERE stsma LIKE 'Z%'
    AND spras = 'I'.
    MOVE '00039' TO output-codice.
    CONCATENATE tj30t-stsma tj30t-estat INTO output-valore.
    MOVE tj30t-txt30 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.


*Estrazione tipo conto ('00040')
  SELECT * FROM zcrmc_eew_1306_t
    WHERE spras = 'I'.
    MOVE '00040' TO output-codice.
    MOVE zcrmc_eew_1306_t-zz_tipo_conto TO output-valore.
    MOVE zcrmc_eew_1306_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Tipo documento di indentità ('00041')
  SELECT * FROM ztb0000wriri7t
    WHERE spras = 'I'.
    MOVE '00041' TO output-codice.
    MOVE ztb0000wriri7t-zzzztipo_doc TO output-valore.
    MOVE ztb0000wriri7t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Tipo documento di indentità ('00042')
  SELECT * FROM ztb0000aenyd2t
    WHERE spras = 'I'.
    MOVE '00042' TO output-codice.
    MOVE ztb0000aenyd2t-zzente_rilas TO output-valore.
    MOVE ztb0000aenyd2t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Tipo studi ('00043')
  SELECT * FROM tsad2t
    WHERE langu = 'I'.
    MOVE '00043' TO output-codice.
    MOVE tsad2t-title_key TO output-valore.
    MOVE tsad2t-title_dscr TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Professione ('00044')
  SELECT * FROM tsad5t
    WHERE langu = 'I'.
    MOVE '00044' TO output-codice.
    MOVE tsad5t-title_key TO output-valore.
    MOVE tsad5t-title_dscr TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

***  ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB ***
*Estrazione Periodo di Fatturazione ('00045')
  SELECT * FROM zcrmc_eew_2001_t
    WHERE spras = 'I'.
    MOVE '00045' TO output-codice.
    MOVE zcrmc_eew_2001_t-zz_period_fatt TO output-valore.
    MOVE zcrmc_eew_2001_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Modalità di Pagamento ('00046')
  SELECT * FROM zcrmc_eew_2002_t
    WHERE spras = 'I'.
    MOVE '00046' TO output-codice.
    MOVE zcrmc_eew_2002_t-zz_mod_pagamento TO output-valore.
    MOVE zcrmc_eew_2002_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Codice Deroga ('00047')
  SELECT * FROM zcrmc_eew_2003_t
    WHERE spras = 'I'.
    MOVE '00047' TO output-codice.
    MOVE zcrmc_eew_2003_t-zz_codice_deroga TO output-valore.
    MOVE zcrmc_eew_2003_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Termini di Pagamento ('00048')
  SELECT * FROM zcrmc_eew_2004_t
    WHERE spras = 'I'.
    MOVE '00048' TO output-codice.
    MOVE zcrmc_eew_2004_t-zz_termini_pag TO output-valore.
    MOVE zcrmc_eew_2004_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Invio Fattura ('00049')
  SELECT * FROM zcrmc_eew_2005_t
    WHERE spras = 'I'.
    MOVE '00049' TO output-codice.
    MOVE zcrmc_eew_2005_t-zz_invio_fattura TO output-valore.
    MOVE zcrmc_eew_2005_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Mezzo di Pagamento ('00050')
  SELECT * FROM zcrmc_eew_2006_t
    WHERE spras = 'I'.
    MOVE '00050' TO output-codice.
    MOVE zcrmc_eew_2006_t-zz_mezzo_pagam TO output-valore.
    MOVE zcrmc_eew_2006_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Interessi di Mora ('00051')
  SELECT * FROM zcrmc_eew_2007_t
    WHERE spras = 'I'.
    MOVE '00051' TO output-codice.
    MOVE zcrmc_eew_2007_t-zz_inter_mora TO output-valore.
    MOVE zcrmc_eew_2007_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*** DEL 02.02.2011 Tipologica attualmente non necessaria
*Estrazione Canali di Erogazione ('00052')
*  SELECT * FROM zcrmc_eew_2009_t
*    WHERE spras = 'I'.
*    MOVE '00052' TO output-codice.
*    MOVE zcrmc_eew_2009_t-zz_can_erogaz TO output-valore.
*    MOVE zcrmc_eew_2009_t-text TO output-descrizione.
*    APPEND output.
*    CLEAR output.
*  ENDSELECT.
*** END DEL 02.02.2011 Tipologica attualmente non necessaria


*Estrazione Codice Promozione PTB ('00053')
  SELECT * FROM zcrmc_eew_2101_t
    WHERE spras = 'I'.
    MOVE '00053' TO output-codice.
    MOVE zcrmc_eew_2101_t-zz_codice_promoz TO output-valore.
    MOVE zcrmc_eew_2101_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.
***  END ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB ***

*Estrazione ALT ('00054')
  SELECT * FROM ztb00006u3rk5t
    WHERE spras = 'I'.
    MOVE '00054' TO output-codice.
    MOVE ztb00006u3rk5t-zzalt TO output-valore.
    MOVE ztb00006u3rk5t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione stato reclami ('00055')
  SELECT * FROM tj30t
    WHERE stsma = 'ZCOMPL03'
    AND spras = 'I'.
    MOVE '00055' TO output-codice.
    MOVE tj30t-estat TO output-valore.
    MOVE tj30t-txt30 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione Motivo appuntamenti ('00056')
  SELECT * FROM qpct
    WHERE katalogart = 'A1'
    AND codegruppe LIKE 'Z%'
    AND sprache = 'I'.
    MOVE '00056' TO output-codice.
    CONCATENATE qpct-katalogart qpct-codegruppe qpct-code INTO output-valore.
    MOVE qpct-kurztext TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*Estrazione canale appuntamenti ('00057')
  SELECT * FROM zcrmc_eew_1307_t
    WHERE spras = 'I'.
    MOVE '00057' TO output-codice.
    MOVE zcrmc_eew_1307_t-zz_provenienza TO output-valore.
    MOVE zcrmc_eew_1307_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*******inizio tipologiche BDM

*estrazione modalità di erogazione
  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group = 'MOD_EROGAZIONE'.
    MOVE '00060' TO output-codice.
    MOVE zca_param_ext-z_group TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.
*
**estrazione modalità di rimborso
  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group = 'MOD_RIMBORSO'.
    MOVE '00061' TO output-codice.
    MOVE zca_param_ext-z_group TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*estrazione finalità di finanziamento 1
  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group = '001'.
    MOVE '00062' TO output-codice.
    MOVE zca_param_ext-z_val_par TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group = '020'.
    MOVE '00062' TO output-codice.
    MOVE zca_param_ext-z_val_par TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*estrazione finalità di finanziamento 2
  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group NE '001' AND z_group NE '020' AND z_group NE 'AGRC' AND z_nome_par LIKE 'CRED_%'.
    MOVE '00063' TO output-codice.
    MOVE zca_param_ext-z_val_par TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*estrazione finalità di finanziamento 2
  SELECT * FROM zca_param_ext
  WHERE z_appl = 'BDM_CONFIGURAZIONE2'
    AND z_group = 'AGRC'.
    MOVE '00064' TO output-codice.
    MOVE zca_param_ext-z_val_par TO output-valore.
    MOVE zca_param_ext-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

*******fine tipologiche BDM

*Estrazione canale appuntamenti ('000565')
  SELECT * FROM zcrmc_eew_1307_t
    WHERE spras = 'I'.
    MOVE '00065' TO output-codice.
    MOVE zcrmc_eew_1307_t-zz_provenienza TO output-valore.
    MOVE zcrmc_eew_1307_t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

  "Inizio modifica mf 18/06/2012
  "Estrazioni tipologiche privacy

  SELECT *
    FROM zca_privacy
    INTO TABLE lt_privacy.

  LOOP AT  lt_privacy ASSIGNING <fs_privacy>.
    MOVE '00066' TO output-codice.
    CONCATENATE <fs_privacy>-process_type <fs_privacy>-id_consenso INTO output-valore.
* Begin AG 21.09.2012
* La descrizione deve essere la concatenazione dei 4 campi Descrizione,
* ma solo se sono valorizzate
*    MOVE <fs_privacy>-descrizione TO output-descrizione.
    CLEAR lv_descr.
    IF <fs_privacy>-descrizione4 IS NOT INITIAL.
      CONCATENATE <fs_privacy>-descrizione
                  <fs_privacy>-descrizione2
                  <fs_privacy>-descrizione3
                  <fs_privacy>-descrizione4
             INTO output-descrizione
             RESPECTING BLANKS.
    ELSE.
      IF <fs_privacy>-descrizione3 IS NOT INITIAL.
        CONCATENATE <fs_privacy>-descrizione
                    <fs_privacy>-descrizione2
                    <fs_privacy>-descrizione3
               INTO output-descrizione
               RESPECTING BLANKS.
      ELSE.
        IF <fs_privacy>-descrizione2 IS NOT INITIAL.
          CONCATENATE <fs_privacy>-descrizione
                      <fs_privacy>-descrizione2
                 INTO output-descrizione
                 RESPECTING BLANKS.
        ELSE.
          MOVE <fs_privacy>-descrizione TO output-descrizione.
        ENDIF.
      ENDIF.
    ENDIF.
* End   AG 21.09.2012

    APPEND output.
    CLEAR output.
  ENDLOOP.

*estrazione tipologiche cointestatario

  SELECT *
    FROM zca_param
    INTO TABLE lt_coint
    WHERE z_appl = 'CRMI_EDWH_COINT'
     AND z_group = 'COIN'.

  SELECT *
   FROM zca_param
   INTO TABLE lt_inte
   WHERE z_appl = 'CRMI_EDWH_INT'
   AND z_group = 'INTE'.

  lt_00067[] =  lt_coint[].
  APPEND LINES OF lt_inte[] TO lt_00067[].
  SORT lt_00067[] BY z_nome_par.
  DELETE ADJACENT DUPLICATES FROM lt_00067[] COMPARING z_nome_par.

  LOOP AT lt_00067 ASSIGNING <fs_00067>.
    MOVE '00067' TO output-codice.
    MOVE <fs_00067>-z_nome_par TO output-valore.
    MOVE <fs_00067>-z_label TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDLOOP.
  "commentato perchè è stata effettuata una DISTINCT dei valori in base al nome_par delle due estrazioni
  "COINE e INTE
*  LOOP AT lt_coint ASSIGNING <fs_coint>.
*    MOVE '00067' TO output-codice.
*    CONCATENATE <fs_coint>-z_nome_par <fs_coint>-z_group INTO output-valore.
*    MOVE <fs_coint>-z_label TO output-descrizione.
*    APPEND output.
*    CLEAR output.
*  ENDLOOP.
*
*
*
*  LOOP AT lt_inte ASSIGNING <fs_inte>.
*    MOVE '00067' TO output-codice.
*    CONCATENATE <fs_inte>-z_nome_par <fs_inte>-z_group INTO output-valore.
*    MOVE <fs_inte>-z_label TO output-descrizione.
*    APPEND output.
*    CLEAR output.
*  ENDLOOP.

  "Fine modifica mf 18/06/2012

  " -- Inizio modifiche MF del 22.08.2012 10:31:12
  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = 'OPZN'
      i_z_appl = 'ZCAE_EDWHAE_BASE'
    TABLES
      param    = lt_opz
      return   = lt_return[].

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = 'PRAT'
      i_z_appl = 'ZCAE_EDWHAE_BASE'
    TABLES
      param    = lt_prat
      return   = lt_return[].

  IF lt_prat[] IS NOT INITIAL.
    APPEND LINES OF lt_prat[] TO lt_opz[].
  ENDIF.

  SORT lt_opz[] BY z_label z_val_par.

  IF lt_opz[] IS NOT INITIAL.
    SELECT *
      FROM crmc_proc_type_t
      INTO TABLE lt_descr
      FOR ALL ENTRIES IN lt_opz
      WHERE process_type EQ lt_opz-z_val_par(4)
      AND   langu        EQ sy-langu.
  ENDIF.

  LOOP AT lt_opz ASSIGNING <fs_ozp>.
    READ TABLE lt_descr WITH KEY process_type = <fs_ozp>-z_val_par(4) ASSIGNING <fs_descr>.
    MOVE <fs_ozp>-z_label         TO output-codice.
    MOVE <fs_ozp>-z_val_par       TO output-valore.
    MOVE <fs_descr>-p_description TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDLOOP.
  " -- Fine modifiche MF del 22.08.2012 10:31:14

*Estrazione Ruolo referente('00070')
  SELECT * FROM ztb00009h1w82t
    WHERE spras = 'I'.
    MOVE '00070' TO output-codice.
    MOVE ztb00009h1w82t-zzruolointer TO output-valore.
    MOVE ztb00009h1w82t-text TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

* Estrazione Nazioni
*start VPM14.05.2014 - NFEC - mod nazioni

  CALL FUNCTION 'Z_CA_READ_GROUP_PARAM'
    EXPORTING
      i_gruppo = 'SOPP'
      i_z_appl = 'SEARCH_HELP_NAZ'
    TABLES
      param    = lt_naz
      return   = lt_return[].

  SELECT a~landx50 a~natio50 b~intca  b~landk b~land1
    INTO CORRESPONDING FIELDS OF TABLE lt_nation
    FROM t005t AS a INNER JOIN t005 AS b ON a~land1 = b~land1
    WHERE a~spras EQ 'IT' ORDER BY b~land1.

  LOOP AT lt_nation INTO lw_nation.
    CLEAR: lv_sopp.
    READ TABLE lt_naz WITH KEY z_val_par = lw_nation-land1 TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      lv_sopp = 'X'.
    ENDIF.
    MOVE: '00072'         TO output-codice,
          lw_nation-land1 TO output-valore.
    CONCATENATE lw_nation-landx50
                lw_nation-natio50
                lw_nation-intca
                lw_nation-landk
                lv_sopp
           INTO output-descrizione
      SEPARATED BY '|'.
    APPEND output.
    CLEAR output.
  ENDLOOP.
*asteriscata vecchia versione
*  SELECT *
*    FROM t005t
*   WHERE spras EQ 'IT'.
*    MOVE: '00072'     TO output-codice,
*          t005t-land1 TO output-valore.
*    CONCATENATE t005t-landx50
*                t005t-natio50
*           INTO output-descrizione
*      SEPARATED BY '|'.
*    APPEND output.
*    CLEAR output.
*  ENDSELECT.
*end VPM14.05.2014 - NFEC - mod nazioni

* Estrazione Stato Civile
  SELECT *
    FROM tb027t
   WHERE spras EQ 'IT'.
    MOVE: '00073'     TO output-codice,
          tb027t-marst TO output-valore,
          tb027t-bez20 TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

* Estrazione Province
*  SELECT *
*    FROM t005u
*   WHERE spras EQ 'IT'
*     AND land1 EQ 'IT'.
*    MOVE: '00074'     TO output-codice,
*          t005u-bland TO output-valore,
*          t005u-bezei TO output-descrizione.
*    APPEND output.
*    CLEAR output.
*  ENDSELECT.
  SELECT *
    FROM ztb0000q0nfd3t
   WHERE spras EQ 'IT'.
    MOVE: '00074'     TO output-codice,
          ztb0000q0nfd3t-zzprov_nasci TO output-valore,
          ztb0000q0nfd3t-text         TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

* Estrazione comuni
  CLEAR: va_cod_belfiore,
         va_city_name,
         va_region.
*  SELECT a~city_code at~city_name a~region
*    INTO (output-valore, va_city_name, va_region)
*    FROM adrcity AS a INNER JOIN adrcityt AS at ON a~city_code EQ at~city_code
*   WHERE a~country EQ 'IT'.
*
*    MOVE: '00075' TO output-codice.
*
*    CONCATENATE va_city_name
*                va_region
*           INTO output-descrizione
*      SEPARATED BY '|'.
*    APPEND output.
*    CLEAR output.
*    CLEAR: va_city_name,
*           va_region.
*  ENDSELECT.
*  SELECT comune descr_comune provincia
*    INTO (output-valore, va_city_name, va_region)


* COMUNI - OLD - START
*  SELECT comune descr_comune provincia
*    INTO (va_cod_belfiore, va_city_name, va_region)
*    FROM zca_comuni
*   WHERE NOT comune LIKE 'Z%'.
*
*    SELECT SINGLE t~city_code INTO output-valore
*      FROM adrcityt AS t INNER JOIN adrcity AS a ON a~city_code EQ t~city_code
*     WHERE city_name EQ va_city_name
*       AND region    EQ va_region.
*
*    IF NOT sy-subrc IS INITIAL.
*      MOVE va_cod_belfiore TO output-valore.
*    ENDIF.
*    MOVE: '00075' TO output-codice.
*
*    CONCATENATE va_city_name
*                va_region
*           INTO output-descrizione
*      SEPARATED BY '|'.
*    APPEND output.
*    CLEAR output.
*    CLEAR: va_city_name,
*           va_region.
*  ENDSELECT.
* COMUNI - OLD - END

* COMUNI - NEW - START
  TYPES: BEGIN OF t_adrcity,
           city_code LIKE adrcity-city_code,
           city_name LIKE adrcityt-city_name,
           region    LIKE adrcity-region,
         END OF t_adrcity.
  DATA: lt_zca_comuni TYPE STANDARD TABLE OF zca_comuni,
        ls_zca_comuni TYPE zca_comuni,
        lt_adrcity    TYPE STANDARD TABLE OF t_adrcity,
        ls_adrcity    TYPE t_adrcity,
        lv_scarto.

  SELECT *
    FROM zca_comuni INTO TABLE lt_zca_comuni
   WHERE NOT comune LIKE 'Z%'.

  SELECT a~city_code t~city_name a~region INTO CORRESPONDING FIELDS OF ls_adrcity
    FROM adrcityt AS t INNER JOIN adrcity AS a ON a~city_code EQ t~city_code
   WHERE t~country EQ 'IT'.

    SPLIT ls_adrcity-city_name AT '(' INTO ls_adrcity-city_name lv_scarto.
    APPEND ls_adrcity TO lt_adrcity.

  ENDSELECT.

* Comuni attivi
  LOOP AT lt_adrcity INTO ls_adrcity.
    MOVE: '00075' TO output-codice,
          ls_adrcity-city_code TO output-valore.

    CONCATENATE ls_adrcity-city_name
                ls_adrcity-region
           INTO output-descrizione
      SEPARATED BY '|'.
    APPEND output.
    CLEAR output.

    DELETE lt_zca_comuni
     WHERE descr_comune EQ ls_adrcity-city_name
       AND provincia    EQ ls_adrcity-region.
  ENDLOOP.

* Comuni cessati
  LOOP AT lt_zca_comuni INTO ls_zca_comuni.
    MOVE: '00075' TO output-codice,
        ls_zca_comuni-comune TO output-valore.

    CONCATENATE ls_zca_comuni-descr_comune
                ls_zca_comuni-provincia
           INTO output-descrizione
      SEPARATED BY '|'.
    APPEND output.
    CLEAR output.
  ENDLOOP.
* COMUNI - NEW - END

  CALL FUNCTION 'Z_WEB_CONTRACT_TIPOL'
    EXPORTING
      i_applicazione     = lv_applicazione
      i_tipo_conto       = lv_tipo_conto
      i_mod_conto        = lv_mod_conto
      i_tipo_cliente     = lv_tipo_cliente
    IMPORTING
      es_titolo_studio   = lt_titolo_studio
      es_settore         = lt_settore
      es_qualifica       = lt_qualifica
      es_grado_parentela = lt_grado_parentela
      es_professione_crm = lt_professione_crm
    TABLES
      et_return          = lt_return.

* 00076 - Grado parentela
  LOOP AT lt_grado_parentela-grado_parentela INTO ls_grado_parentela.

    MOVE: '00076'                             TO output-codice,
          ls_grado_parentela-id_grado_parente TO output-valore.

    CONCATENATE ls_grado_parentela-contratto
                ls_grado_parentela-operazione
                ls_grado_parentela-sort
                ls_grado_parentela-descr_tipolog
           INTO output-descrizione
      SEPARATED BY '|'.

    APPEND output.
    CLEAR output.

  ENDLOOP.

* 00077 - Professione CRM
  LOOP AT lt_professione_crm-professione_crm INTO ls_professione_crm.

    MOVE: '00077'                       TO output-codice,
          ls_professione_crm-title_key  TO output-valore,
          ls_professione_crm-title_text TO output-descrizione.

    APPEND output.
    CLEAR output.

  ENDLOOP.

* 00078 - Qualifica
  LOOP AT lt_qualifica-qualifica INTO ls_qualifica.

    MOVE: '00078'                   TO output-codice,
          ls_qualifica-id_qualifica TO output-valore.

    CONCATENATE ls_qualifica-contratto
                ls_qualifica-operazione
                ls_qualifica-sort
                ls_qualifica-descr_tipolog
           INTO output-descrizione
      SEPARATED BY '|'.

    APPEND output.
    CLEAR output.

  ENDLOOP.

* 00079 - Settore
  LOOP AT lt_settore-settore INTO ls_settore.
    MOVE: '00079'               TO output-codice,
          ls_settore-id_settore TO output-valore.

    CONCATENATE ls_settore-contratto
                ls_settore-operazione
                ls_settore-sort
                ls_settore-descr_tipolog
           INTO output-descrizione
      SEPARATED BY '|'.

    APPEND output.
    CLEAR output.
  ENDLOOP.

* 00080 - Titolo Studio
  LOOP AT lt_titolo_studio-titolo_studio INTO ls_titolo_studio.
    MOVE: '00080'                          TO output-codice,
          ls_titolo_studio-acad_title      TO output-valore,
          ls_titolo_studio-acad_title_text TO output-descrizione.

    APPEND output.
    CLEAR output.
  ENDLOOP.
  " -- Inizio modifiche AO del 10.12.2013   - CWDK993286
* 00081 - Target Esteso

  SELECT *
    FROM zca_target_est.
    MOVE: '00081'     TO output-codice,
          zca_target_est-ztargetesteso TO output-valore,
          zca_target_est-text          TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.

* 00082 - Consenso FIRMA ELETTRONICA

  SELECT *
    FROM ztb0000m0pihat
    WHERE spras EQ 'IT'.
    MOVE: '00082'     TO output-codice,
          ztb0000m0pihat-zzzz_consens  TO output-valore,
          ztb0000m0pihat-text          TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.
  " -- Fine   modifiche AO del 10.12.2013


* Inizio AG 07.10.2015
  " tipologica del campo BUT000-PARTGRPTYP (tabella TB026)
  DATA lt_tb026 TYPE STANDARD TABLE OF tb026.
  FIELD-SYMBOLS <fs_tb026> TYPE tb026.
  SELECT *
    FROM tb026
    INTO TABLE lt_tb026
    WHERE spras EQ 'IT'.

  LOOP AT lt_tb026 ASSIGNING <fs_tb026>.
    MOVE: '00083'     TO output-codice,
          <fs_tb026>-partgrptyp TO output-valore,
          <fs_tb026>-textlong   TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDLOOP.
* Fine   AG 07.10.2015

* estrazioni codici ateco Ru 05/05/2018
  SELECT cod_ateco desc_ateco mcc_circ_int mcc_circ_pbt
    FROM zca_ateco_mcc
    INTO (lv_cod_ateco, lv_desc_ateco, lv_mcc_int, lv_mcc_pbt).
    MOVE: '00084'       TO output-codice,
          lv_cod_ateco  TO output-valore.

    IF  strlen( lv_desc_ateco ) <= 245 .
      CONCATENATE lv_desc_ateco lv_mcc_int lv_mcc_pbt
             INTO output-descrizione
             SEPARATED BY '|'.
    ELSE.
      CONCATENATE lv_desc_ateco(245) lv_mcc_int lv_mcc_pbt
             INTO output-descrizione
             SEPARATED BY '|'.
    ENDIF.
    APPEND output.
    CLEAR output.
  ENDSELECT.

  "Inizio RU 13.09.2019 11:08:53

  SELECT cod_reinoltro descr INTO ( lv_cod_rein, lv_desc_rein )
    FROM zfa_reinoltro_up.

    MOVE: '00085'      TO output-codice,
          lv_cod_rein  TO output-valore,
          lv_desc_rein TO output-descrizione.
    APPEND output.
    CLEAR output.
  ENDSELECT.



  "Fine RU 13.09.2019 11:08:57

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

  CLOSE DATASET: va_fileout, va_filelog.

ENDFORM.                    " chiudi_file
*&---------------------------------------------------------------------*
*&      Form  trasferimento_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM trasferimento_file .

  DATA: va_recout TYPE string,
        va_reclog TYPE string.

  LOOP AT output.
*   Trasferimento al file di out
    CLEAR va_recout.
    CONCATENATE output-codice
                output-valore
                output-descrizione
                INTO va_recout SEPARATED BY ca_sep.
    TRANSFER va_recout TO va_fileout.

*   Trasferimento al file di log
    CLEAR va_reclog.
    CONCATENATE output-codice
                output-valore
                output-descrizione
                text-l01
                INTO va_reclog SEPARATED BY ca_sep.
    TRANSFER va_reclog TO va_filelog.
  ENDLOOP.


ENDFORM.                    " trasferimento_file
*&---------------------------------------------------------------------*
*&      Form  estrazioni_lista
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM estrazioni_lista .

  "Inizio mf 18/06/2012
*  DATA: lt_privacy TYPE STANDARD TABLE OF zca_privacy,
*      lt_coint   TYPE STANDARD TABLE OF zca_param,
*      lt_inte    TYPE STANDARD TABLE OF zca_param.
*
*  FIELD-SYMBOLS:   <fs_privacy>  TYPE zca_privacy,
*                   <fs_coint>    TYPE zca_param,
*                   <fs_inte>     TYPE zca_param.
*  SELECT *
*  FROM zca_privacy
*  INTO TABLE lt_privacy.
*
*  SELECT *
*  FROM zca_param
*  INTO TABLE lt_coint
*  WHERE z_appl = 'CRMI_EDWH_COINT'
*  AND z_group = 'COIN'.
*
*  SELECT *
*  FROM zca_param
*  INTO TABLE lt_inte
*  WHERE z_appl = 'CRMI_EDWH_INT'
*  AND z_group = 'INTE'.

  "Fine mf 18/06/2012

  DATA: lt_ztipo_promo_bun TYPE STANDARD TABLE OF ztipo_promo_bun.
  FIELD-SYMBOLS <fs_promo_bun> TYPE ztipo_promo_bun.

  LOOP AT p_cod.

    IF p_cod-low = '00001'.
*Estrazione RELTYP tranne relazioni di tipo retail ('00001')
      SELECT * FROM tbz9a
        WHERE spras = 'IT'
        AND reltyp <> 'ZR3001'.
        MOVE '00001' TO output-codice.
        IF tbz9a-reltyp(1) = 'Z'.
          MOVE tbz9a-reltyp TO output-valore.
          MOVE tbz9a-bez50_2 TO output-descrizione.
          APPEND output.
          CLEAR output.
        ENDIF.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00002'.
*Estrazione type ('00002')
      SELECT * FROM dd07t
        WHERE ddlanguage = 'IT'
        AND domname = 'BU_TYPE'.
        MOVE '00002' TO output-codice.
        MOVE dd07t-domvalue_l TO output-valore.
        MOVE dd07t-ddtext TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00003'.
*Estrazione bpkind ('00003')
      SELECT * FROM tb004t
        WHERE spras = 'I'.
        MOVE '00003' TO output-codice.
        MOVE tb004t-bpkind TO output-valore.
        MOVE tb004t-text40 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00004'.
*Estrazione bu_group ('00004')
      SELECT * FROM tb002
        WHERE spras = 'I'.
        MOVE '00004' TO output-codice.
        MOVE tb002-bu_group TO output-valore.
        MOVE tb002-txt40 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00005'.
*Estrazione segm_corporate ('00005')
      SELECT * FROM crmc_attr10_t
        WHERE spras = 'I'.
        MOVE '00005' TO output-codice.
        MOVE crmc_attr10_t-attrib_10 TO output-valore.
        MOVE crmc_attr10_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00006'.
*Estrazione pot_comm ('00006')
      SELECT * FROM zca_pot_comm.
        MOVE '00006' TO output-codice.
        MOVE zca_pot_comm-pot_comm TO output-valore.
        MOVE zca_pot_comm-descrizione TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00007'.
*Estrazione type-card ('00007')
      SELECT * FROM dd07t
        WHERE ddlanguage = 'IT'
        AND domname = 'ZCHAR1'.
        MOVE '00007' TO output-codice.
        MOVE dd07t-domvalue_l TO output-valore.
        IF dd07t-domvalue_l = '1'.
          MOVE 'Card Primaria' TO output-descrizione.
        ELSEIF
        dd07t-domvalue_l = '2'.
          MOVE 'Card Secondaria' TO output-descrizione.
        ENDIF.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00008'.
*Estrazione attiva ('00008')
      output-codice = '00008'.
      output-valore = 'X'.
      output-descrizione = 'attiva'.
      APPEND output.
      CLEAR output.
      output-codice = '00008'.
      output-valore = ''.
      output-descrizione = 'non attiva'.
      APPEND output.
      CLEAR output.
    ENDIF.

    IF p_cod-low = '00009'.
* Estrazione process-type attività-opportunità-reclami ('00009)
      SELECT * FROM crmc_proc_type_t
        WHERE langu = 'I'.
        MOVE '00009' TO output-codice.
        MOVE crmc_proc_type_t-process_type TO output-valore.
        SELECT SINGLE * FROM  zcrmc_eew_1002_t WHERE spras = 'I' AND zz_opzione = crmc_proc_type_t-process_type.
        IF sy-subrc = '0'.
          MOVE zcrmc_eew_1002_t-text TO output-descrizione.
        ELSE.
          MOVE crmc_proc_type_t-p_description TO output-descrizione.
        ENDIF.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00010'.
*Estrazione cod_risultato attività-opportunità ('00010')
      SELECT * FROM qpct
        WHERE sprache = 'I'.
        MOVE '00010' TO output-codice.
        CONCATENATE qpct-katalogart qpct-codegruppe qpct-code INTO output-valore.
        MOVE qpct-kurztext TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00011'.
*Estrazione categoria ('00011')
      SELECT * FROM crmc_act_cat_t
        WHERE langu = 'I'.
        MOVE '00011' TO output-codice.
        MOVE crmc_act_cat_t-category TO output-valore.
        MOVE crmc_act_cat_t-description TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00012'.
*Estrazione Mezzo di Contatto- reclami('00012')
      SELECT * FROM zcrmc_eew_0404_t
        WHERE spras = 'I'.
        MOVE '00012' TO output-codice.
        MOVE zcrmc_eew_0404_t-zzcustomer_h0404 TO output-valore.
        MOVE zcrmc_eew_0404_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00013'.
*Estrazione Canale acquisizione- reclami('00013')
      SELECT * FROM zcrmc_eew_0401_t
        WHERE spras = 'I'.
        MOVE '00013' TO output-codice.
        MOVE zcrmc_eew_0401_t-zzcustomer_h0401 TO output-valore.
        MOVE zcrmc_eew_0401_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00014'.
*Estrazione Valore contratto- reclami('00014')
      SELECT * FROM zcrmc_eew_0403_t
        WHERE spras = 'I'.
        MOVE '00014' TO output-codice.
        MOVE zcrmc_eew_0403_t-zzcustomer_h0403 TO output-valore.
        MOVE zcrmc_eew_0403_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00015'.
*Estrazione motivazione- reclami('00015')
      SELECT * FROM zcrmc_eew_0407_t
        WHERE spras = 'I'.
        MOVE '00015' TO output-codice.
        MOVE zcrmc_eew_0407_t-zzcustomer_h0407 TO output-valore.
        MOVE zcrmc_eew_0407_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00016'.
*Estrazione Area- reclami('00016')
      SELECT * FROM zcrmc_eew_0406_t
        WHERE spras = 'I'.
        MOVE '00016' TO output-codice.
        MOVE zcrmc_eew_0406_t-zzcustomer_h0406 TO output-valore.
        MOVE zcrmc_eew_0406_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00017'.
*Estrazione Priorità- reclami('00017')
      SELECT * FROM scpriot
        WHERE langu = 'I'.
        MOVE '00017' TO output-codice.
        MOVE scpriot-priority TO output-valore.
        MOVE scpriot-txt_long TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00018'.
*Estrazione Mezzo com risposta- reclami('00018')
      SELECT * FROM zcrmc_eew_0402_t
        WHERE spras = 'I'.
        MOVE '00018' TO output-codice.
        MOVE zcrmc_eew_0402_t-zzcustomer_h0402 TO output-valore.
        MOVE zcrmc_eew_0402_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00019'.
*Estrazione type-card ('00019')
      SELECT * FROM dd07t
        WHERE ddlanguage = 'IT'
        AND domname = 'CRM_SVY_DB_SVS_STATUS'.
        MOVE '00019' TO output-codice.
        MOVE dd07t-domvalue_l TO output-valore.
        MOVE dd07t-ddtext TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00020'.
*Estrazione ZZRUOLOVENDI0001 ('00020')
      SELECT * FROM ztb00005xwkl9t
        WHERE spras = 'I'.
        MOVE '00020' TO output-codice.
        MOVE ztb00005xwkl9t-zzruolovendi0001 TO output-valore.
        MOVE ztb00005xwkl9t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00021'.
*Estrazione ID_SETTORE ('00021')
      SELECT * FROM zca_settorigav.
        MOVE '00021' TO output-codice.
        MOVE zca_settorigav-zid_settore TO output-valore.
        MOVE zca_settorigav-zds_settore TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00022'.
*Estrazione Operazioni-Contratti ('00022')
      SELECT * FROM zcrmc_eew_1001_t
        WHERE spras = 'I'.
        MOVE '00022' TO output-codice.
        MOVE zcrmc_eew_1001_t-zz_operazione TO output-valore.
        MOVE zcrmc_eew_1001_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00023'.
*Estrazione Tipo Documento Precedente-Contratti ('00023')
      SELECT * FROM crmc_subob_cat_t
        WHERE langu = 'I'.
        MOVE '00023' TO output-codice.
        MOVE crmc_subob_cat_t-subobj_category TO output-valore.
        MOVE crmc_subob_cat_t-s_description TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00024'.
*Estrazione Tipologia Posizione-Contratti ('00024')
      SELECT * FROM crmc_item_type_t
        WHERE langu = 'I'.
        MOVE '00024' TO output-codice.
        MOVE crmc_item_type_t-itm_type TO output-valore.
        MOVE crmc_item_type_t-i_description TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00025'.
*Estrazione Stato posizione-Contratti ('00025')
      SELECT * FROM tj30t
        WHERE stsma = 'ZODSIT01'
        AND spras = 'I'.
        MOVE '00025' TO output-codice.
        MOVE tj30t-estat TO output-valore.
        MOVE tj30t-txt30 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00026'.
*Estrazione Funzione Partner-Contratti ('00026')
      SELECT * FROM crmc_partner_ft
        WHERE spras = 'I'.
        MOVE '00026' TO output-codice.
        MOVE crmc_partner_ft-partner_fct TO output-valore.
        MOVE crmc_partner_ft-description TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

    IF p_cod-low = '00027'.
*Estrazione Fascia numero dipendenti ('00027')
      SELECT * FROM zca_fasciadipgav.
        MOVE '00027' TO output-codice.
        MOVE zca_fasciadipgav-zid_fascia TO output-valore.
        MOVE zca_fasciadipgav-zds_fascia TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
    ENDIF.

* Begin AG 06.02.2014
    IF p_cod-low = '00028'.
* End   AG 06.02.2014
*Estrazione motivazione 2° livello ('00028')
      SELECT * FROM zcrmc_eew_0204_t
        WHERE spras = 'I'.
        MOVE '00028' TO output-codice.
        MOVE zcrmc_eew_0204_t-zz_denom TO output-valore.
        MOVE zcrmc_eew_0204_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00029'.
* End   AG 06.02.2014
*Estrazione area country ('00029')
      SELECT * FROM ztb0000rv2kwjt
        WHERE spras = 'I'.
        MOVE '00029' TO output-codice.
        MOVE ztb0000rv2kwjt-zzarea TO output-valore.
        MOVE ztb0000rv2kwjt-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00030'.
* End   AG 06.02.2014
*Estrazione classe documento ('00030')
      SELECT * FROM crmc_subob_cat_t
        WHERE langu = 'I'.
        MOVE '00030' TO output-codice.
        MOVE crmc_subob_cat_t-subobj_category TO output-valore.
        MOVE crmc_subob_cat_t-s_description_20 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00031'.
* End   AG 06.02.2014
*Estrazione convenzioni ('00031')
      SELECT * FROM zcrmc_eew_1305_t
        WHERE spras = 'I'.
        MOVE '00031' TO output-codice.
        MOVE zcrmc_eew_1305_t-zz_cod_conv TO output-valore.
        MOVE zcrmc_eew_1305_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
* è necessario estendere la tipologica con i valori presenti
* nella tabella ZTIPO_PROMO_BUN ovvero è necessario estrarre tutti i
* record presenti nella tabella che abbiano il campo
* COD_PROMO_EDWH valorizzato.
* Dopo aver eliminato i duplicati rispetto a questo campo aggiungere
* al file di output i record rimasti valorizzando:
* -  Codice = 000310
* -  Valore = ZTIPO_COD_PROMO-COD_PROMO_EDWH
* -  Descrizione = ZTIPO_COD_PROMO-TEXT
      SELECT *
       FROM ztipo_promo_bun
       INTO TABLE lt_ztipo_promo_bun
       WHERE cod_promo_edwh NE space.
      MOVE '00031' TO output-codice.
      LOOP AT lt_ztipo_promo_bun ASSIGNING <fs_promo_bun>.
        MOVE <fs_promo_bun>-cod_promo_edwh TO output-valore.
        MOVE <fs_promo_bun>-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDLOOP.
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00032'.
* End   AG 06.02.2014
*Estrazione lavorazioni ('00032')
      SELECT * FROM zcrmc_eew_1403_t
        WHERE spras = 'I'.
        MOVE '00032' TO output-codice.
        MOVE zcrmc_eew_1403_t-zz_descr_lavor_i TO output-valore.
        MOVE zcrmc_eew_1403_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00033'.
* End   AG 06.02.2014
*Estrazione tipi lavorazione ('00033')
      SELECT * FROM zcrmc_eew_1404_t
        WHERE spras = 'I'.
        MOVE '00033' TO output-codice.
        MOVE zcrmc_eew_1404_t-zz_lavorazione_i TO output-valore.
        MOVE zcrmc_eew_1404_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00034'.
* End   AG 06.02.2014
*Estrazione categorie motivazione ('00034')
      SELECT * FROM zcrmc_eew_1402_t
        WHERE spras = 'I'.
        MOVE '00034' TO output-codice.
        MOVE zcrmc_eew_1402_t-zz_cat_motivaz_i TO output-valore.
        MOVE zcrmc_eew_1402_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00035'.
* End   AG 06.02.2014
*Estrazione motivazioni ('00035')
      SELECT * FROM zcrmc_eew_1401_t
        WHERE spras = 'I'.
        MOVE '00035' TO output-codice.
        MOVE zcrmc_eew_1401_t-zz_motivaz_nor_i TO output-valore.
        MOVE zcrmc_eew_1401_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00036'.
* End   AG 06.02.2014
*Estrazione tipologia opportunità ('00036')
      SELECT * FROM zcrmc_eew_0202_t
        WHERE spras = 'I'.
        MOVE '00036' TO output-codice.
        MOVE zcrmc_eew_0202_t-zz_tip_opp_biz TO output-valore.
        MOVE zcrmc_eew_0202_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00037'.
* End   AG 06.02.2014
*Estrazione filiale ('00037')
      SELECT * FROM ztb0000672y1qt
        WHERE spras = 'I'.
        MOVE '00037' TO output-codice.
        MOVE ztb0000672y1qt-zzfiliale TO output-valore.
        MOVE ztb0000672y1qt-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00038'.
* End   AG 06.02.2014
*Estrazione tipologie di firma ('00038')
      SELECT * FROM zcrmc_eew_1308_t
        WHERE spras = 'I'.
        MOVE '00038' TO output-codice.
        MOVE zcrmc_eew_1308_t-zz_firma TO output-valore.
        MOVE zcrmc_eew_1308_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00039'.
* End   AG 06.02.2014
*Estrazione Stato posizione-Contratti ('00039')
      SELECT * FROM tj30t
        WHERE stsma LIKE 'Z%'
        AND spras = 'I'.
        MOVE '00039' TO output-codice.
        CONCATENATE tj30t-stsma tj30t-estat INTO output-valore.
        MOVE tj30t-txt30 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00040'.
* End   AG 06.02.2014
*Estrazione tipo conto ('00040')
      SELECT * FROM zcrmc_eew_1306_t
        WHERE spras = 'I'.
        MOVE '00040' TO output-codice.
        MOVE zcrmc_eew_1306_t-zz_tipo_conto TO output-valore.
        MOVE zcrmc_eew_1306_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014

* Begin AG 06.02.2014
    IF p_cod-low = '00041'.
* End   AG 06.02.2014
*Estrazione Tipo documento di indentità ('00041')
      SELECT * FROM ztb0000wriri7t
        WHERE spras = 'I'.
        MOVE '00041' TO output-codice.
        MOVE ztb0000wriri7t-zzzztipo_doc TO output-valore.
        MOVE ztb0000wriri7t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00042'.
* End   AG 06.02.2014
*Estrazione Tipo documento di indentità ('00042')
      SELECT * FROM ztb0000aenyd2t
        WHERE spras = 'I'.
        MOVE '00042' TO output-codice.
        MOVE ztb0000aenyd2t-zzente_rilas TO output-valore.
        MOVE ztb0000aenyd2t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00043'.
* End   AG 06.02.2014
*Estrazione Tipo studi ('00043')
      SELECT * FROM tsad2t
        WHERE langu = 'I'.
        MOVE '00043' TO output-codice.
        MOVE tsad2t-title_key TO output-valore.
        MOVE tsad2t-title_dscr TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00044'.
* End   AG 06.02.2014
*Estrazione Professione ('00044')
      SELECT * FROM tsad5t
        WHERE langu = 'I'.
        MOVE '00044' TO output-codice.
        MOVE tsad5t-title_key TO output-valore.
        MOVE tsad5t-title_dscr TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00045'.
* End   AG 06.02.2014
***  ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB ***
*Estrazione Periodo di Fatturazione ('00045')
      SELECT * FROM zcrmc_eew_2001_t
        WHERE spras = 'I'.
        MOVE '00045' TO output-codice.
        MOVE zcrmc_eew_2001_t-zz_period_fatt TO output-valore.
        MOVE zcrmc_eew_2001_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00046'.
* End   AG 06.02.2014
*Estrazione Modalità di Pagamento ('00046')
      SELECT * FROM zcrmc_eew_2002_t
        WHERE spras = 'I'.
        MOVE '00046' TO output-codice.
        MOVE zcrmc_eew_2002_t-zz_mod_pagamento TO output-valore.
        MOVE zcrmc_eew_2002_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00047'.
* End   AG 06.02.2014
*Estrazione Codice Deroga ('00047')
      SELECT * FROM zcrmc_eew_2003_t
        WHERE spras = 'I'.
        MOVE '00047' TO output-codice.
        MOVE zcrmc_eew_2003_t-zz_codice_deroga TO output-valore.
        MOVE zcrmc_eew_2003_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00048'.
* End   AG 06.02.2014
*Estrazione Termini di Pagamento ('00048')
      SELECT * FROM zcrmc_eew_2004_t
        WHERE spras = 'I'.
        MOVE '00048' TO output-codice.
        MOVE zcrmc_eew_2004_t-zz_termini_pag TO output-valore.
        MOVE zcrmc_eew_2004_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00049'.
* End   AG 06.02.2014
*Estrazione Invio Fattura ('00049')
      SELECT * FROM zcrmc_eew_2005_t
        WHERE spras = 'I'.
        MOVE '00049' TO output-codice.
        MOVE zcrmc_eew_2005_t-zz_invio_fattura TO output-valore.
        MOVE zcrmc_eew_2005_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00050'.
* End   AG 06.02.2014
*Estrazione Mezzo di Pagamento ('00050')
      SELECT * FROM zcrmc_eew_2006_t
        WHERE spras = 'I'.
        MOVE '00050' TO output-codice.
        MOVE zcrmc_eew_2006_t-zz_mezzo_pagam TO output-valore.
        MOVE zcrmc_eew_2006_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00051'.
* End   AG 06.02.2014
*Estrazione Interessi di Mora ('00051')
      SELECT * FROM zcrmc_eew_2007_t
        WHERE spras = 'I'.
        MOVE '00051' TO output-codice.
        MOVE zcrmc_eew_2007_t-zz_inter_mora TO output-valore.
        MOVE zcrmc_eew_2007_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


*** DEL 02.02.2011 Tipologica attualmente non necessaria
*Estrazione Canali di Erogazione ('00052')
*  SELECT * FROM zcrmc_eew_2009_t
*    WHERE spras = 'I'.
*    MOVE '00052' TO output-codice.
*    MOVE zcrmc_eew_2009_t-zz_can_erogaz TO output-valore.
*    MOVE zcrmc_eew_2009_t-text TO output-descrizione.
*    APPEND output.
*    CLEAR output.
*  ENDSELECT.
*** END DEL 02.02.2011 Tipologica attualmente non necessaria

* Begin AG 06.02.2014
    IF p_cod-low = '00053'.
* End   AG 06.02.2014
*Estrazione Codice Promozione PTB ('00053')
      SELECT * FROM zcrmc_eew_2101_t
        WHERE spras = 'I'.
        MOVE '00053' TO output-codice.
        MOVE zcrmc_eew_2101_t-zz_codice_promoz TO output-valore.
        MOVE zcrmc_eew_2101_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
***  END ADD MA 27.09.2010 Gestione Tipologiche per i campi legati ai contratti PTB
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00054'.
* End   AG 06.02.2014
*Estrazione ALT ('00054')
      SELECT * FROM ztb00006u3rk5t
        WHERE spras = 'I'.
        MOVE '00054' TO output-codice.
        MOVE ztb00006u3rk5t-zzalt TO output-valore.
        MOVE ztb00006u3rk5t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00055'.
* End   AG 06.02.2014
*Estrazione stato reclami ('00055')
      SELECT * FROM tj30t
        WHERE stsma = 'ZCOMPL03'
        AND spras = 'I'.
        MOVE '00055' TO output-codice.
        MOVE tj30t-estat TO output-valore.
        MOVE tj30t-txt30 TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00056'.
* End   AG 06.02.2014
*Estrazione Motivo appuntamenti ('00056')
      SELECT * FROM qpct
        WHERE katalogart = 'A1'
        AND codegruppe LIKE 'Z%'
        AND sprache = 'I'.
        MOVE '00056' TO output-codice.
        CONCATENATE qpct-katalogart qpct-codegruppe qpct-code INTO output-valore.
        MOVE qpct-kurztext TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00057'.
* End   AG 06.02.2014
*Estrazione canale appuntamenti ('00057')
      SELECT * FROM zcrmc_eew_1307_t
        WHERE spras = 'I'.
        MOVE '00057' TO output-codice.
        MOVE zcrmc_eew_1307_t-zz_provenienza TO output-valore.
        MOVE zcrmc_eew_1307_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


* Begin AG 06.02.2014
    IF p_cod-low = '00065'.
* End   AG 06.02.2014
*Estrazione canale appuntamenti ('00065')
      SELECT * FROM zcrmc_eew_1307_t
        WHERE spras = 'I'.
        MOVE '00065' TO output-codice.
        MOVE zcrmc_eew_1307_t-zz_provenienza TO output-valore.
        MOVE zcrmc_eew_1307_t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


    "Inizio mf 18/06/2012
    "IF p_cod-low EQ '00066'.
    "commentato mf 19/06/2012 - Vedi mail del 19/06/ mandata da Ilaria, non serve aggiungere il filtro
    "sui codici in input
*    LOOP AT  lt_privacy ASSIGNING <fs_privacy>.
*      MOVE '00066' TO output-codice.
*      CONCATENATE <fs_privacy>-process_type <fs_privacy>-id_consenso INTO output-valore.
*      MOVE <fs_privacy>-descrizione TO output-descrizione.
*      APPEND output.
*      CLEAR output.
*    ENDLOOP.
*    "ENDIF.
*
*    "IF p_cod-low EQ '00067'.
*    LOOP AT lt_coint ASSIGNING <fs_coint>.
*      MOVE '00067' TO output-codice.
*      CONCATENATE <fs_coint>-z_nome_par <fs_coint>-z_group INTO output-valore.
*      MOVE <fs_coint>-z_label TO output-descrizione.
*      APPEND output.
*      CLEAR output.
*    ENDLOOP.
*
*    LOOP AT lt_inte ASSIGNING <fs_inte>.
*      MOVE '00067' TO output-codice.
*      CONCATENATE <fs_inte>-z_nome_par <fs_inte>-z_group INTO output-valore.
*      MOVE <fs_inte>-z_label TO output-descrizione.
*      APPEND output.
*      CLEAR output.
*    ENDLOOP.
*    " ENDIF.

    "Fine mf 18/06/2012

* Begin AG 06.02.2014
    IF p_cod-low = '00070'.
* End   AG 06.02.2014
*Estrazione Ruolo referente('00070')
      SELECT * FROM ztb00009h1w82t
        WHERE spras = 'I'.
        MOVE '00070' TO output-codice.
        MOVE ztb00009h1w82t-zzruolointer TO output-valore.
        MOVE ztb00009h1w82t-text TO output-descrizione.
        APPEND output.
        CLEAR output.
      ENDSELECT.
* Begin AG 06.02.2014
    ENDIF.
* End   AG 06.02.2014


  ENDLOOP.

  IF '00072' IN p_cod.
* Estrazione Nazioni
    SELECT *
      FROM t005t
     WHERE spras EQ 'IT'.
      MOVE: '00072'     TO output-codice,
            t005t-land1 TO output-valore.
      CONCATENATE t005t-landx50
                  t005t-natio50
             INTO output-descrizione
        SEPARATED BY '|'.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.

  IF '00073' IN p_cod.
* Estrazione Stato Civile
    SELECT *
      FROM tb027t
     WHERE spras EQ 'IT'.
      MOVE: '00073'     TO output-codice,
            tb027t-marst TO output-valore,
            tb027t-bez20 TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.

  IF '00074' IN p_cod.
* Estrazione Province
*    SELECT *
*      FROM t005u
*     WHERE spras EQ 'IT'
*       AND land1 EQ 'IT'.
*      MOVE: '00074'     TO output-codice,
*            t005u-bland TO output-valore,
*            t005u-bezei TO output-descrizione.
*      APPEND output.
*      CLEAR output.
*    ENDSELECT.
    SELECT *
      FROM ztb0000q0nfd3t
     WHERE spras EQ 'IT'.
      MOVE: '00074'     TO output-codice,
            ztb0000q0nfd3t-zzprov_nasci TO output-valore,
            ztb0000q0nfd3t-text         TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.

  IF '00075' IN p_cod.
* Estrazione comuni
    CLEAR: va_cod_belfiore,
           va_city_name,
           va_region.
*    SELECT a~city_code at~city_name a~region
*      INTO (output-valore, va_city_name, va_region)
*      FROM adrcity AS a INNER JOIN adrcityt AS at ON a~city_code EQ at~city_code
*     WHERE a~country EQ 'IT'.
*
*      MOVE: '00075' TO output-codice.
*
*      CONCATENATE va_city_name
*                  va_region
*             INTO output-descrizione
*        SEPARATED BY '|'.
*      APPEND output.
*      CLEAR output.
*      CLEAR: va_city_name,
*             va_region.
*    ENDSELECT.
    SELECT comune descr_comune provincia
      INTO (va_cod_belfiore, va_city_name, va_region)
      FROM zca_comuni
     WHERE NOT comune LIKE 'Z%'.

      SELECT SINGLE t~city_code INTO output-valore
        FROM adrcityt AS t INNER JOIN adrcity AS a ON a~city_code EQ t~city_code
       WHERE city_name EQ va_city_name
         AND region    EQ va_region.

      IF NOT sy-subrc IS INITIAL.
        MOVE va_cod_belfiore TO output-valore.
      ENDIF.
      MOVE: '00075' TO output-codice.

      CONCATENATE va_city_name
                  va_region
             INTO output-descrizione
        SEPARATED BY '|'.
      APPEND output.
      CLEAR output.
      CLEAR: va_city_name,
             va_region.
    ENDSELECT.

  ENDIF.
  DATA: lv_applicazione    TYPE zappl          VALUE 'RETAIL',
        lv_tipo_conto      TYPE zca_tipo_conto VALUE 'CPIU',
        lv_mod_conto       TYPE zca_id         VALUE '01',
        lv_tipo_cliente    TYPE char10         VALUE 'RETAIL',
        lt_grado_parentela TYPE zca_grad_parent_s,
        lt_professione_crm TYPE zst_professione_crm,
        lt_qualifica       TYPE zca_qualifica_s,
        lt_settore         TYPE zca_settore_s,
        lt_titolo_studio   TYPE zca_tit_studio_s,
        ls_grado_parentela TYPE zca_tipcont_grad,
        ls_professione_crm TYPE tsad5,
        ls_qualifica       TYPE zca_tipcont_qual,
        ls_settore         TYPE zca_tipcont_sect,
        ls_titolo_studio   TYPE bbp_academic_keys,
        lt_return          TYPE bapiret2_t.

  CALL FUNCTION 'Z_WEB_CONTRACT_TIPOL'
    EXPORTING
      i_applicazione     = lv_applicazione
      i_tipo_conto       = lv_tipo_conto
      i_mod_conto        = lv_mod_conto
      i_tipo_cliente     = lv_tipo_cliente
    IMPORTING
      es_titolo_studio   = lt_titolo_studio
      es_settore         = lt_settore
      es_qualifica       = lt_qualifica
      es_grado_parentela = lt_grado_parentela
      es_professione_crm = lt_professione_crm
    TABLES
      et_return          = lt_return.

  IF '00076' IN p_cod.

* 00076 - Grado parentela
    LOOP AT lt_grado_parentela-grado_parentela INTO ls_grado_parentela.

      MOVE: '00076'                             TO output-codice,
            ls_grado_parentela-id_grado_parente TO output-valore.

      CONCATENATE ls_grado_parentela-contratto
                  ls_grado_parentela-operazione
                  ls_grado_parentela-sort
                  ls_grado_parentela-descr_tipolog
             INTO output-descrizione
        SEPARATED BY '|'.

      APPEND output.
      CLEAR output.

    ENDLOOP.
  ENDIF.

  IF '00077' IN p_cod.
* 00077 - Professione CRM
    LOOP AT lt_professione_crm-professione_crm INTO ls_professione_crm.

      MOVE: '00077'                       TO output-codice,
            ls_professione_crm-title_key  TO output-valore,
            ls_professione_crm-title_text TO output-descrizione.

      APPEND output.
      CLEAR output.

    ENDLOOP.
  ENDIF.

  IF '00078' IN p_cod.
* 00078 - Qualifica
    LOOP AT lt_qualifica-qualifica INTO ls_qualifica.

      MOVE: '00078'                   TO output-codice,
            ls_qualifica-id_qualifica TO output-valore.

      CONCATENATE ls_qualifica-contratto
                  ls_qualifica-operazione
                  ls_qualifica-sort
                  ls_qualifica-descr_tipolog
             INTO output-descrizione
        SEPARATED BY '|'.

      APPEND output.
      CLEAR output.

    ENDLOOP.
  ENDIF.

  IF '00079' IN p_cod.
* 00079 - Settore
    LOOP AT lt_settore-settore INTO ls_settore.
      MOVE: '00079'               TO output-codice,
            ls_settore-id_settore TO output-valore.

      CONCATENATE ls_settore-contratto
                  ls_settore-operazione
                  ls_settore-sort
                  ls_settore-descr_tipolog
             INTO output-descrizione
        SEPARATED BY '|'.

      APPEND output.
      CLEAR output.
    ENDLOOP.
  ENDIF.

  IF '00080' IN p_cod.
* 00080 - Titolo Studio
    LOOP AT lt_titolo_studio-titolo_studio INTO ls_titolo_studio.
      MOVE: '00080'                          TO output-codice,
            ls_titolo_studio-acad_title      TO output-valore,
            ls_titolo_studio-acad_title_text TO output-descrizione.

      APPEND output.
      CLEAR output.
    ENDLOOP.
  ENDIF.

  " -- Inizio modifiche AO del 10.12.2013   - CWDK993286
* 00081 - Target Esteso
  IF '00081' IN p_cod.
    SELECT *
      FROM zca_target_est.
      MOVE: '00081'     TO output-codice,
            zca_target_est-ztargetesteso TO output-valore,
            zca_target_est-text          TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.

  IF '00082' IN p_cod.
    SELECT *
      FROM ztb0000m0pihat
       WHERE spras EQ 'IT'.
      MOVE: '00082'     TO output-codice,
            ztb0000m0pihat-zzzz_consens TO output-valore,
            ztb0000m0pihat-text          TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.
  " -- Fine   modifiche AO del 10.12.2013

* Inizio AG 07.10.2015
  " tipologica del campo BUT000-PARTGRPTYP (tabella TB026)
  DATA lt_tb026 TYPE STANDARD TABLE OF tb026.
  FIELD-SYMBOLS <fs_tb026> TYPE tb026.
  IF '00083' IN p_cod.
    SELECT *
      FROM tb026
      INTO TABLE lt_tb026
      WHERE spras EQ 'IT'.

    LOOP AT lt_tb026 ASSIGNING <fs_tb026>.
      MOVE: '00083'     TO output-codice,
            <fs_tb026>-partgrptyp TO output-valore,
            <fs_tb026>-textlong   TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDLOOP.
  ENDIF.
* Fine   AG 07.10.2015

* RU estrazione codici Ateco
  IF '00084' IN p_cod.
    SELECT cod_ateco desc_ateco mcc_circ_int mcc_circ_pbt
      FROM zca_ateco_mcc
      INTO (lv_cod_ateco, lv_desc_ateco, lv_mcc_int, lv_mcc_pbt).
      MOVE: '00084'       TO output-codice,
            lv_cod_ateco  TO output-valore.

      IF  strlen( lv_desc_ateco ) <= 245 .
        CONCATENATE lv_desc_ateco lv_mcc_int lv_mcc_pbt
               INTO output-descrizione
               SEPARATED BY '|'.
      ELSE.
        CONCATENATE lv_desc_ateco(245) lv_mcc_int lv_mcc_pbt
               INTO output-descrizione
               SEPARATED BY '|'.
      ENDIF.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.

  "Inizio RU 13.09.2019 10:55:10
  IF '00085' IN p_cod.
    SELECT cod_reinoltro descr INTO ( lv_cod_rein, lv_desc_rein )
      FROM zfa_reinoltro_up.

      MOVE: '00085'      TO output-codice,
            lv_cod_rein  TO output-valore,
            lv_desc_rein TO output-descrizione.
      APPEND output.
      CLEAR output.
    ENDSELECT.
  ENDIF.
  "Fine RU 13.09.2019 10:55:16


ENDFORM.                    " estrazioni_lista


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
