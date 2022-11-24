FUNCTION Z_CA_BDM_GET_PRODUCTS.
*"--------------------------------------------------------------------
*"*"Interfaccia locale:
*"  IMPORTING
*"     VALUE(I_APPLICAZIONE) TYPE  ZAPPL
*"     VALUE(I_PRODS_LAVS) TYPE  CHAR1 OPTIONAL
*"     VALUE(I_PRODUCT_GUID) TYPE  COMT_PRODUCT_GUID OPTIONAL
*"     VALUE(I_PRODUCT_ID) TYPE  COMT_PRODUCT_ID OPTIONAL
*"     VALUE(I_PRODUCT_ID_EDWH) TYPE  ZIDALTCH40 OPTIONAL
*"  TABLES
*"      RETURN STRUCTURE  BAPIRET2
*"      PTB_PRODUCTS STRUCTURE  ZTS_PTB_PRODUCTS
*"--------------------------------------------------------------------

*APPLICAZIONE = PTB_CONFIGURAZIONE.

  DATA: lv_hierarchy         TYPE zappl,
        lv_cat_prodotti      TYPE zappl,
        lv_cat_lavorazioni   TYPE zappl,
        lt_return            TYPE TABLE OF bapiret2,
        lv_hierarchy_guid    TYPE comt_hierarchy_guid,
        lv_hierarchy_id      TYPE comt_hierarchy_id,
        lv_hierarchy_guid_32 TYPE sysuuid_c.

  DATA: lt_comm_prprdcatr    TYPE TABLE OF comm_prprdcatr,
        ls_comm_prprdcatr    TYPE comm_prprdcatr.

  DATA: lv_data_i TYPE datum,
        lv_data_f TYPE datum,
        arg      TYPE i,
        arg_cat  TYPE i.

  DATA: dt_i TYPE timestamp,
        dt_f TYPE timestamp.

  DATA: ls_ptb_products TYPE zts_ptb_products.


  CONSTANTS: c_hierarchy       TYPE znome_par VALUE 'PCATEGORY'.

* Check parametro I_PRODS_LAVS: P o L
*  IF i_prods_lavs NE 'P' AND
*     i_prods_lavs NE 'L'.
*
*    PERFORM return TABLES return
*                    USING 'W' text-006.
*    EXIT.
*
*  ENDIF.


* hierarchy
  CALL FUNCTION 'Z_CA_READ_PARAM'
    EXPORTING
      z_name_par = c_hierarchy
      z_appl     = i_applicazione
    IMPORTING
      z_val_par  = lv_hierarchy
    TABLES
      return     = lt_return.

  IF lv_hierarchy IS INITIAL.
    PERFORM return TABLES return
                    USING 'W' text-002.
    EXIT.
  ENDIF.

  lv_hierarchy_id = lv_hierarchy.

* cat_prodotti
*  CALL FUNCTION 'Z_CA_READ_PARAM'
*    EXPORTING
*      z_name_par = c_cat_prodotti
*      z_appl     = i_applicazione
*    IMPORTING
*      z_val_par  = lv_cat_prodotti
*    TABLES
*      return     = lt_return.
*
*  IF lv_cat_prodotti IS INITIAL.
*    PERFORM return TABLES return
*                    USING 'W' text-002.
*    EXIT.
*  ENDIF.
*
** cat_lavorazioni
*  CALL FUNCTION 'Z_CA_READ_PARAM'
*    EXPORTING
*      z_name_par = c_cat_lavorazioni
*      z_appl     = i_applicazione
*    IMPORTING
*      z_val_par  = lv_cat_lavorazioni
*    TABLES
*      return     = lt_return.
*
*  IF lv_cat_lavorazioni IS INITIAL.
*    PERFORM return TABLES return
*                    USING 'W' text-002.
*    EXIT.
*  ENDIF.

******************
*     STEP 1     *
******************

* Estrazione Tabella COMM_HIERARCHY

  SELECT hierarchy_guid valid_from valid_to
    FROM comm_hierarchy
    INTO (lv_hierarchy_guid, dt_i, dt_f)
    UP TO 1 ROWS
    WHERE hierarchy_id  EQ lv_hierarchy_id.
  ENDSELECT.

  IF lv_hierarchy_guid IS INITIAL.
    PERFORM return TABLES return
                    USING 'W' text-007.
    EXIT.
  ENDIF.

  PERFORM convert_timestamp USING    dt_i
                                     dt_f
                            CHANGING lv_data_i
                                     lv_data_f.

  IF lv_data_i <= sy-datum AND
     lv_data_f => sy-datum.
  ELSE.
    PERFORM return TABLES return
                    USING 'W' text-007.
    EXIT.
  ENDIF.

******************
*     STEP 2     *
******************

  SELECT * FROM comm_prprdcatr
      INTO TABLE lt_comm_prprdcatr
      WHERE hierarchy_guid EQ lv_hierarchy_guid.

  IF lt_comm_prprdcatr[] IS INITIAL.
    PERFORM return TABLES return
                    USING 'W' text-009.
    EXIT.
  ENDIF.

  LOOP AT lt_comm_prprdcatr INTO ls_comm_prprdcatr.
    CLEAR: lv_data_i, lv_data_f.
    PERFORM convert_timestamp USING    ls_comm_prprdcatr-valid_from
                                       ls_comm_prprdcatr-valid_to
                              CHANGING lv_data_i
                                       lv_data_f.

    IF lv_data_i <= sy-datum AND
       lv_data_f => sy-datum.
    ELSE.
      DELETE TABLE lt_comm_prprdcatr FROM ls_comm_prprdcatr.
    ENDIF.
  ENDLOOP.

  IF lt_comm_prprdcatr[] IS INITIAL.
    PERFORM return TABLES return
                    USING 'W' text-009.
    EXIT.
  ENDIF.

*  CLEAR: ls_comm_prprdcatr, arg, arg_cat.
*  CASE i_prods_lavs.
*    WHEN 'P'.
*      LOOP AT lt_comm_prprdcatr INTO ls_comm_prprdcatr.
*        arg     = STRLEN( ls_comm_prprdcatr-category_id ).
*        arg_cat = STRLEN( lv_cat_prodotti ).
*        arg = arg - arg_cat.
*        IF ls_comm_prprdcatr-category_id+arg(arg_cat) NE lv_cat_prodotti.
*          DELETE TABLE lt_comm_prprdcatr FROM ls_comm_prprdcatr.
*        ENDIF.
*      ENDLOOP.
*    WHEN 'L'.
*      LOOP AT lt_comm_prprdcatr INTO ls_comm_prprdcatr.
*        arg     = STRLEN( ls_comm_prprdcatr-category_id ).
*        arg_cat = STRLEN( lv_cat_lavorazioni ).
*        arg = arg - arg_cat.
*        IF ls_comm_prprdcatr-category_id+arg(arg_cat) NE lv_cat_lavorazioni.
*          DELETE TABLE lt_comm_prprdcatr FROM ls_comm_prprdcatr.
*        ENDIF.
*      ENDLOOP.
*    WHEN OTHERS.
*  ENDCASE.

  IF NOT i_product_guid IS INITIAL.
    DELETE lt_comm_prprdcatr WHERE product_guid NE i_product_guid.
  ENDIF.

  IF lt_comm_prprdcatr[] IS INITIAL.
    PERFORM return TABLES return
                    USING 'W' text-009.
    EXIT.
  ENDIF.

******************
*     STEP 3     *
******************
  CLEAR: ls_comm_prprdcatr.

  LOOP AT lt_comm_prprdcatr INTO ls_comm_prprdcatr.

    CLEAR: dt_i, dt_f.
    SELECT SINGLE product_guid product_id valid_from valid_to
           INTO (ls_ptb_products-product_guid, ls_ptb_products-product_id, dt_i, dt_f)
           FROM comm_product
           WHERE product_guid = ls_comm_prprdcatr-product_guid.

    IF sy-subrc = 0.

      CLEAR: lv_data_i, lv_data_f.
      PERFORM convert_timestamp USING    dt_i
                                         dt_f
                                CHANGING lv_data_i
                                         lv_data_f.

      IF lv_data_i <= sy-datum AND
         lv_data_f => sy-datum.
      ELSE.
        CLEAR ls_ptb_products.
      ENDIF.
    ELSE.
      CLEAR ls_ptb_products.
    ENDIF.

    CLEAR: dt_f, dt_i.
    SELECT SINGLE zz0010 zz0011 valid_from valid_to
           INTO (ls_ptb_products-product_id_edwh, ls_ptb_products-product_desc_edwh, dt_i, dt_f)
           FROM zca_anprodotto
           WHERE product_guid = ls_comm_prprdcatr-product_guid.

*    IF sy-subrc = 0.
*
*      CLEAR: lv_data_i, lv_data_f.
*      PERFORM convert_timestamp USING    dt_i
*                                         dt_f
*                                CHANGING lv_data_i
*                                         lv_data_f.
*
*      IF lv_data_i <= sy-datum AND
*         lv_data_f => sy-datum.
*      ELSE.
*        CLEAR ls_ptb_products.
*      ENDIF.
*    ELSE.
*      CLEAR ls_ptb_products.
*    ENDIF.
    IF NOT ls_ptb_products IS INITIAL.
      ls_ptb_products-hierarchy_guid = ls_comm_prprdcatr-hierarchy_guid.
      ls_ptb_products-hierarchy_id   = lv_hierarchy_id.
      ls_ptb_products-category_guid  = ls_comm_prprdcatr-category_guid.
      ls_ptb_products-category_id  = ls_comm_prprdcatr-category_id.
      APPEND ls_ptb_products TO ptb_products.
    ENDIF.
  ENDLOOP.


  IF NOT i_product_id IS INITIAL.
    DELETE ptb_products WHERE product_id NE i_product_id.
  ENDIF.

  IF NOT i_product_id_edwh IS INITIAL.
    DELETE ptb_products WHERE product_id_edwh NE i_product_id_edwh.
  ENDIF.


ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
