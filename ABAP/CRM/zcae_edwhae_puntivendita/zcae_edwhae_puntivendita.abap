REPORT zcae_edwhae_puntivendita.


INCLUDE zcae_edwhae_puntivendita_top.
INCLUDE zcae_edwhae_puntivendita_form.

START-OF-SELECTION.

* -- Estrazione Parametri da ZCA_PARAM
  PERFORM get_param.

* -- SET Global Range
  PERFORM f_set_range.

* -- Estrazione Tipologiche
  PERFORM f_estrai_tipologiche.

* Estrazione da GT_PRIVACY
  PERFORM f_estrai_privacy.

* -- Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

* -- Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* -- Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

* -- Recupero file di Appoggio
  PERFORM recupera_file USING ca_file_temp va_ts
                        CHANGING va_filetemp.

* -- Apre i file di output e log
  PERFORM apri_file.

* -- Elaborazioni dal DB
  PERFORM estrazioni.

* -- Chiude i file di output e log
  PERFORM chiudi_file.

* 105900: inizio modifica del 29.09.2016 - eng
  DESCRIBE TABLE i_guid LINES lv_line.

  " Rinomino il file in caso di scrittura teminata correttamente
  IF file_completo IS NOT INITIAL.
    IF lv_line NE 0.
      PERFORM f_rinomina_file.
    ENDIF.

  ENDIF.

*105900: fine modifica del 29.09.2016 - eng


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
