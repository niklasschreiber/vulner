FUNCTION-POOL zgf_bdm.                      "MESSAGE-ID ..

DATA: ls_return      TYPE bapiret2,
      nome_par       TYPE znome_par,
      nome_appl      TYPE znome_par,
      ls_param       TYPE zca_param,
      group          TYPE zgroup,
      group_ext      TYPE zgroup_ext,
      text_mess      TYPE string,
      v_label        TYPE zlabel,
      v_label_doc    TYPE zlabel,
      ls_indirizzi   TYPE zca_ptb_address_s,
      go_struct      TYPE REF TO cl_abap_structdescr,
      gt_comp        TYPE abap_component_tab,
      gt_compt       TYPE abap_component_tab,
      gs_comp        TYPE abap_componentdescr,
      controller     TYPE prxctrltab,
      g_ls_contr     TYPE prxctrl,
      g_xml_document TYPE REF TO if_ixml_document.

FIELD-SYMBOLS: <fs_line>   TYPE ANY,
               <fs_field>  TYPE ANY,
               <fs_linet>  TYPE ANY,
               <fs_fieldt> TYPE ANY,
               <fs_tab>    TYPE table.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
