FUNCTION z_ca_read_order_parall.
*"----------------------------------------------------------------------
*"*"Interfaccia locale:
*"  TABLES
*"      ET_HEADER STRUCTURE  BAPIBUS20001_HEADER_DIS OPTIONAL
*"      ET_ACTIVITY STRUCTURE  BAPIBUS20001_ACTIVITY_DIS OPTIONAL
*"      ET_PARTNER STRUCTURE  BAPIBUS20001_PARTNER_DIS OPTIONAL
*"      ET_SERVICE_OS STRUCTURE  BAPIBUS20001_SERVICE_OS_DIS OPTIONAL
*"      ET_STATUS STRUCTURE  BAPIBUS20001_STATUS_DIS OPTIONAL
*"      ET_ITEM STRUCTURE  BAPIBUS20001_ITEM_DIS OPTIONAL
*"      ET_OPPURTUNITY STRUCTURE  BAPIBUS20001_OPPORTUNITY_DIS OPTIONAL
*"      ET_PRICING_ITEM STRUCTURE  BAPIBUS20001_PRICING_ITEM_DIS
*"       OPTIONAL
*"      ET_CRMD_CUSTOMER_I STRUCTURE  ZCA_ITEM_OPP_S OPTIONAL
*"      ET_SCHEDUL STRUCTURE  BAPIBUS20001_SCHEDLIN_DIS OPTIONAL
*"      ET_CUMULATED_H STRUCTURE  BAPIBUS20001_CUMULATED_H_DIS OPTIONAL
*"      ET_DOC_FLOW STRUCTURE  BAPIBUS20001_DOC_FLOW_DIS OPTIONAL
*"      ET_TEXT STRUCTURE  BAPIBUS20001_TEXT_DIS OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_CRMD_CUSTOMER_H STRUCTURE  ZCA_HEADER_OPP_S OPTIONAL
*"      CT_GUID STRUCTURE  BAPIBUS20001_GUID_DIS
*"      IT_GUID_16 STRUCTURE  SYSUUID
*"----------------------------------------------------------------------

  DATA : lv_guid_item(32) TYPE c,
          wa_item         TYPE bapibus20001_item_dis.

  DATA:   wa_guid_item          TYPE  ty_guid,
          i_guid_item           TYPE STANDARD TABLE OF ty_guid.

  REFRESH : et_header,
            et_activity,
            et_partner,
            et_text,
            et_crmd_customer_h,
            et_service_os,
            et_status,
            et_item,
            et_oppurtunity,
            et_pricing_item,
            et_schedul,
            et_cumulated_h,
            et_doc_flow,
            et_return,
            et_crmd_customer_i.

  CHECK ct_guid[] IS NOT INITIAL.

  SELECT  guid
          zz_prob_comp_1
          zz_denom
          zz_idunivoco
          zz_tip_opp_biz
          zzcustomer_h1501
          zz_catmot_s
          FROM crmd_customer_h
          INTO TABLE et_crmd_customer_h
          FOR ALL ENTRIES IN it_guid_16
          WHERE guid EQ it_guid_16-x.
  IF sy-subrc IS INITIAL.
    SORT et_crmd_customer_h  BY guid.
  ENDIF.


* FETCHING DATA THROUGH THE CALL FUNCTIONS
  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid         = ct_guid
      header       = et_header
      activity     = et_activity
      partner      = et_partner
      text         = et_text
      service_os   = et_service_os
      status       = et_status
      item         = et_item
      opportunity  = et_oppurtunity
      pricing_item = et_pricing_item
      schedule     = et_schedul
      cumulated_h  = et_cumulated_h
      doc_flow     = et_doc_flow
      return       = et_return.

  SORT et_text BY ref_guid.

  IF NOT et_item[] IS INITIAL.
    LOOP AT et_item INTO wa_item.
      CLEAR lv_guid_item.
      MOVE wa_item-guid TO lv_guid_item.
      MOVE lv_guid_item TO wa_guid_item-guid.
      APPEND wa_guid_item TO i_guid_item.
      CLEAR wa_guid_item.
    ENDLOOP.
* SELECT FROM crmd_customer_i
    SELECT guid
           zzcustomer_i0301
           zzcustomer_i0302
           zzcustomer_i0304
           FROM crmd_customer_i
           INTO TABLE et_crmd_customer_i
           FOR ALL ENTRIES IN i_guid_item
           WHERE guid EQ i_guid_item-guid.
    IF sy-subrc IS INITIAL.
      SORT et_crmd_customer_i  BY guid.
    ENDIF.
  ENDIF.


ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
