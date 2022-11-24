*&---------------------------------------------------------------------*
*&  Include           ZCAE_EDWHAE_OPPORTUNITA_SC
*&---------------------------------------------------------------------*


  SELECTION-SCREEN BEGIN OF BLOCK b1                       "#EC SHAREOK
  WITH FRAME TITLE text-s01.

* START OF RADIO BUTTON SELECTION
* Selection Block for Radio Button Delta & Full.

  SELECTION-SCREEN BEGIN OF BLOCK b2                       "#EC SHAREOK
 WITH FRAME TITLE text-s05.
  SELECTION-SCREEN BEGIN OF LINE.
  PARAMETERS: p_delta RADIOBUTTON GROUP rb1 USER-COMMAND fchg DEFAULT 'X'.
  SELECTION-SCREEN COMMENT 3(20) text-s06 FOR FIELD p_delta.
  SELECTION-SCREEN POSITION 50.
  PARAMETERS: p_full RADIOBUTTON GROUP rb1 .
  SELECTION-SCREEN COMMENT 53(20) text-s07 FOR FIELD p_full.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK b2.
* END OF RADIO BUTTON SELECT
  SELECTION-SCREEN BEGIN OF BLOCK b5
  WITH FRAME TITLE text-s14.

** START FOR TIMESTAMP
  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 3(22) text-s14 FOR FIELD p_tstp.
*  PARAMETERS: p_datfr TYPE dats.
  PARAMETERS : p_tstp TYPE crmd_orderadm_h-created_at.

  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN END OF BLOCK b5.
* END OF TIME INTERVAL

* START OF FILE NAME PARAMETERS
* FOR FILE NAME
  SELECTION-SCREEN BEGIN OF BLOCK b3                       "#EC SHAREOK
  WITH FRAME TITLE text-s11.

  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 3(22) text-s03 FOR FIELD p_file  .
  PARAMETERS: p_file TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMOUT001_EDWHAE_OPPORT'.
  SELECTION-SCREEN END OF LINE.

* FOR LOG FILE NAME
  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 3(22) text-s04 FOR FIELD p_filog .
  PARAMETERS: p_filog  TYPE filename-fileintern OBLIGATORY DEFAULT 'ZCRMLOG001_EDWHAE_OPPORT'.
  SELECTION-SCREEN END OF LINE.

  PARAMETERS: p_ind(8) TYPE c. "OBLIGATORY. MOD SC 19/12/2008.

  SELECTION-SCREEN END OF BLOCK b3.
*END OF FILENAME PARAMETERS

* START FOR OTHER PARAMETERS
  SELECTION-SCREEN BEGIN OF BLOCK b4                       "#EC SHAREOK
   WITH FRAME TITLE text-s12.

* FOR PACKAGE
  TABLES crmd_orderadm_h.

  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 3(22) text-s08 FOR FIELD p_pack.
  PARAMETERS: p_pack TYPE i OBLIGATORY DEFAULT 400.
  SELECTION-SCREEN END OF LINE.

  SELECT-OPTIONS: r_objid FOR crmd_orderadm_h-object_id.

  SELECTION-SCREEN END OF BLOCK b4.
* END OF OTHER PARAMETERS

  SELECTION-SCREEN END OF BLOCK b1.

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
