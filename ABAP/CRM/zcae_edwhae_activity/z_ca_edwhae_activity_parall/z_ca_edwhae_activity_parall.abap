FUNCTION z_ca_edwhae_activity_parall.
*"----------------------------------------------------------------------
*"*"Interfaccia locale:
*"  IMPORTING
*"     VALUE(I_EDW_FCTREF) TYPE  ZCA_PARAM-Z_NOME_PAR
*"  TABLES
*"      ET_HEADER STRUCTURE  BAPIBUS20001_HEADER_DIS
*"      ET_ACTIVITY STRUCTURE  BAPIBUS20001_ACTIVITY_DIS
*"      ET_PARTNER STRUCTURE  BAPIBUS20001_PARTNER_DIS
*"      ET_SERVICE_OS STRUCTURE  BAPIBUS20001_SERVICE_OS_DIS
*"      ET_STATUS STRUCTURE  BAPIBUS20001_STATUS_DIS
*"      ET_GUID STRUCTURE  BAPIBUS20001_GUID_DIS
*"      ET_APPOINTMENT STRUCTURE  BAPIBUS20001_APPOINTMENT_DIS
*"      ET_TEXT STRUCTURE  BAPIBUS20001_TEXT_DIS
*"      ET_DOC_FLOW STRUCTURE  BAPIBUS20001_DOC_FLOW_DIS
*"      I_CRMD_ORDERADM_H STRUCTURE  ZCA_ORDERADM_H_ACTIVITY
*"      ET_RUOLO_REF STRUCTURE  ZST_RUOLOREF
*"----------------------------------------------------------------------

  DATA: ls_guid LIKE LINE OF et_guid,
        lt_guid LIKE STANDARD TABLE OF et_guid,
        lt_partner LIKE STANDARD TABLE OF et_partner.

  FIELD-SYMBOLS: <fs_crmd_orderadm_h> TYPE zca_orderadm_h_activity.


  REFRESH et_guid.
  LOOP AT i_crmd_orderadm_h ASSIGNING <fs_crmd_orderadm_h>.
    PERFORM trascod_guid_16_32 USING <fs_crmd_orderadm_h>-guid
                               CHANGING ls_guid-guid.
    APPEND ls_guid TO et_guid.
  ENDLOOP.

  lt_guid[] = et_guid[].

  REFRESH: et_activity,
           et_appointment,
           et_header,
           et_partner,
           et_service_os,
           et_status,
           et_text,
           et_doc_flow.

  CALL FUNCTION 'BAPI_BUSPROCESSND_GETDETAILMUL'
    TABLES
      guid        = lt_guid
      header      = et_header
      activity    = et_activity
      partner     = et_partner
      appointment = et_appointment
      text        = et_text
      service_os  = et_service_os
      status      = et_status
      doc_flow    = et_doc_flow.

  CHECK et_partner[] IS NOT INITIAL.

  lt_partner[] = et_partner[].

  DELETE lt_partner WHERE ref_partner_fct NE i_edw_fctref.

  CHECK lt_partner[] IS NOT INITIAL.

  SELECT partner zzruolointer
    INTO TABLE et_ruolo_ref
    FROM but000
    FOR ALL ENTRIES IN lt_partner
    WHERE partner EQ lt_partner-ref_partner_no(10).


ENDFUNCTION.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
