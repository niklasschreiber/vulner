FUNCTION-POOL zcrm_alt_marketing.           "MESSAGE-ID ..

*&---------------------------------------------------------------------*
*&      Form  convert_data
*&---------------------------------------------------------------------*
FORM convert_data USING datum     TYPE sy-datum
                        datum_fi  TYPE sy-datum
                  CHANGING  low  TYPE /sapsll/rptet_spi
                            high TYPE /sapsll/rptet_spi.

  DATA:   lv_in(19)     TYPE c,
          lv_output(15) TYPE c.

  WRITE: datum   TO lv_in,
        '00:00:00'  TO lv_in+11.

  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_INPUT'
    EXPORTING
      input  = lv_in
    IMPORTING
      output = low.

  CLEAR lv_in.

  WRITE: datum_fi   TO lv_in,
        '23:59:59'  TO lv_in+11.

  CALL FUNCTION 'CONVERSION_EXIT_TSTLC_INPUT'
    EXPORTING
      input  = lv_in
    IMPORTING
      output = high.


ENDFORM.                    " convert_data
*&---------------------------------------------------------------------*
*&      Form  reconvert_data
*&---------------------------------------------------------------------*
FORM reconvert_data  USING     actualstart  TYPE bcos_tstmp
                               planstart    TYPE bcos_tstmp
                               stat         TYPE crm_j_status
                     CHANGING  gg.

  DATA: out_datum     TYPE d,
        out_char(10)  TYPE c,
        num_gg        TYPE p.

  IF stat = 'I1001'.

    IF actualstart IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
        EXPORTING
          input  = actualstart
        IMPORTING
          output = out_char.

      CONCATENATE out_char+6(4) out_char+3(2) out_char(2) INTO out_datum .

      CALL FUNCTION '/SDF/CMO_DATETIME_DIFFERENCE'
        EXPORTING
          date1    = out_datum
          time1    = '235959'
          date2    = sy-datum
          time2    = '000000'
        IMPORTING
          datediff = num_gg.
    ENDIF.

    IF num_gg <> 20 AND num_gg <> 21 AND planstart IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
        EXPORTING
          input  = planstart
        IMPORTING
          output = out_char.

      CONCATENATE out_char+6(4) out_char+3(2) out_char(2) INTO out_datum .

      CALL FUNCTION '/SDF/CMO_DATETIME_DIFFERENCE'
        EXPORTING
          date1    = out_datum
          time1    = '235959'
          date2    = sy-datum
          time2    = '000000'
        IMPORTING
          datediff = num_gg.
    ENDIF.

  ELSE.

    IF actualstart IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
        EXPORTING
          input  = actualstart
        IMPORTING
          output = out_char.

      CONCATENATE out_char+6(4) out_char+3(2) out_char(2) INTO out_datum .

      CALL FUNCTION '/SDF/CMO_DATETIME_DIFFERENCE'
        EXPORTING
          date1    = out_datum
          time1    = '235959'
          date2    = sy-datum
          time2    = '000000'
        IMPORTING
          datediff = num_gg.
    ENDIF.

    IF num_gg <> 18 AND num_gg <> 19 AND num_gg <> 20 AND planstart IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_TSTLC_OUTPUT'
        EXPORTING
          input  = planstart
        IMPORTING
          output = out_char.

      CONCATENATE out_char+6(4) out_char+3(2) out_char(2) INTO out_datum .

      CALL FUNCTION '/SDF/CMO_DATETIME_DIFFERENCE'
        EXPORTING
          date1    = out_datum
          time1    = '235959'
          date2    = sy-datum
          time2    = '000000'
        IMPORTING
          datediff = num_gg.
    ENDIF.

  ENDIF.


  gg = num_gg.

ENDFORM.                    " reconvert_data

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
