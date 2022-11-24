*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_PREVENTIVO_BDM
*&
*&---------------------------------------------------------------------*
************************************************************************
* ID:     BDM_02_37_01
* Autore:	Aurora Galeone
* Data:   26.10.2011
* Descr.:	Adeguamento Interfaccia Tracciato Preventivi
************************************************************************
REPORT  zcae_edwhae_preventivo_bdm.

* Include
INCLUDE zcae_edwhae_preventivo_bdm_top. " Dichiarazioni
INCLUDE zcae_edwhae_preventivo_bdm_f01. " Form

INITIALIZATION.
* ---------> Pulizia variabili globali
  PERFORM clear.

*AT SELECTION-SCREEN OUTPUT.
AT SELECTION-SCREEN OUTPUT.
* ---------> Gestione Output Screen
  PERFORM screen_output.

START-OF-SELECTION.
* ---------> Check program
  PERFORM check.

* ---------> Apertura File
  PERFORM open_file.

* ---------> Elaborazione
  IF r_full IS NOT INITIAL. " Elaborazione Full
    PERFORM elaborazione_full.
  ELSE." Elaborazione Delta
    PERFORM elaborazione_delta.
  ENDIF.

* ---------> Chiusura File
  CLOSE DATASET: gv_file.

  MESSAGE s398(00) WITH text-t02 space space space.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
