*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_PROD_ACTIVITY
*&
*&---------------------------------------------------------------------*
*& Creato da: Antonio Silvestro
*& Data Creazione: 01/07/2013
*& ID:             EDW_006
*& Descrizione: L'interfaccia permette l'estrazione dei dati inerenti
*&              i prodotti attività
*&---------------------------------------------------------------------*

REPORT  zcae_edwhae_prod_activity.

INCLUDE zcae_edwhae_prod_activity_top.
INCLUDE zcae_edwhae_prod_activity_f01.

INITIALIZATION.
  PERFORM refresh. " pulizia globale

AT SELECTION-SCREEN OUTPUT.
  PERFORM loop_at_screen. " Gestione editabilità campi

AT SELECTION-SCREEN.
  PERFORM check_input_from. " Controllo sul campo "from"

START-OF-SELECTION.

  " Recupero dei file fisici
  PERFORM get_files.

  " Letture param
  PERFORM get_param.

  " Estrazioni ed Elaborazione
  PERFORM estr_elab.

  " Chiusura files
  PERFORM close_files.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
