*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_LEAD
*&
*&---------------------------------------------------------------------*
*& Autore:      Concetta Pastore CP
*& Data:        20/05/2009
*& Descrizione: Estrazione LEAD
*& ID:          EDW_008
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_lead.

INCLUDE zcae_edwhae_lead_top.
INCLUDE zcae_edwhae_lead_f01.

START-OF-SELECTION.

* Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

* Recupero file di Appoggio
  PERFORM recupera_file USING ca_file_temp va_ts
                        CHANGING va_filetmp.

* Recupero dei parametri da utilizzare per le estrazioni
  PERFORM get_param.

* Concersione Caratteri speciali
  PERFORM convert_string.

* Apre i file di output e log
  PERFORM apri_file.

* Estrazioni dal DB
  PERFORM estrazioni.

* Chiude i file di output e log
  PERFORM chiudi_file.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
