*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_CAMPAGNE
*&
*&---------------------------------------------------------------------*
*& Creato da: luca manfreda
*&
*& Data Creazione: 07/04/2009
*&
*& Descrizione: L'interfaccia permette l'estrazione dei dati inerenti
*&              le campagne epresenti sul CRM
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_campagne.

INCLUDE zcae_edwhae_campagne_top.
INCLUDE zcae_edwhae_campagne_f01.


START-OF-SELECTION.

* Inizializza il timestamp da utilizzare per la creazione dei file
  va_ts = sy-datum.

** Recupero parametri
  PERFORM recupera_parametri.

* Recupero file di output
  PERFORM recupera_file USING p_fout va_ts
                        CHANGING va_fileout.


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
