*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_ATTR_BP
*&
*&---------------------------------------------------------------------*
*& Creato da: Nicola Fanzini
*&
*& Data Creazione: 23/07/2008
*&
*& ID: EDW_009 Attributi commerciali BP
*&
*& Descrizione: L'interfaccia permette l'estrazione dei dati inerenti
*&              gli Attributi Commerciali Anagrafica business partner
*&
*&---------------------------------------------------------------------*
*& Modificato da: Kristina La Pietra
*& Data Modifica: 24/09/2008
*&---------------------------------------------------------------------*


REPORT  zcae_edwhae_attr_bp.

INCLUDE zcae_edwhae_attr_bp_top.
INCLUDE zcae_edwhae_attr_bp_f01.

AT SELECTION-SCREEN.
  PERFORM check_date.

START-OF-SELECTION.

* Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.

* Recupero file di log
  PERFORM recupera_file USING p_flog va_ts
                        CHANGING va_filelog.

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
