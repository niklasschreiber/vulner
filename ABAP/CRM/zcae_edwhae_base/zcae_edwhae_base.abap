*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_BASE
*&
*&---------------------------------------------------------------------*
************************************************************************
* ID:	    CONTO_BASE_01
* Autore:	Aurora Galeone
* Data:   31.07.2012
* Descr.: Data Extract Flusso Dati Conto Base
* CR:     CWDK972154
************************************************************************
REPORT  zcae_edwhae_base.

* Include
INCLUDE zcae_edwhae_base_top. " Parametri globali
INCLUDE zcae_edwhae_base_f01. " Form

INITIALIZATION.

* Pulizia variabili globali
  PERFORM f_inizializza.

AT SELECTION-SCREEN OUTPUT.

* Editabilità paramtri in input
  PERFORM f_edit_input.

START-OF-SELECTION.

* Controllo JOB
  PERFORM f_check_program.

* Letture parametrica del Process Type
  PERFORM f_read_param.

* Valorizzazione range date
  PERFORM f_date.

* Elaborazione
  PERFORM f_elabora.

* Chiusura file
  CLOSE DATASET: gv_fileout, gv_fileerr.


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
