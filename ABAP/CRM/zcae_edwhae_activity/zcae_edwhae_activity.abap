*&---------------------------------------------------------------------*
*& Report  ZCAE_EDWHAE_ACTIVITY
*&
*&---------------------------------------------------------------------*
*& Creato da: Nicola Fanzini
*&
*& Data Creazione: 04/08/2008
*&
*& ID: EDW_005 Attività
*&
*& Descrizione: L'interfaccia permette l'estrazione dei dati inerenti
*&              le attività
*&
*&---------------------------------------------------------------------*
*& Modifiche:   Kristina La Pietra
*& Data:        03/09/2008
*& Descrizione: Modifica della form VAL_RECORD al rigo 529 dell'include
*&              ZCAE_EDWHAE_ACTIVITY_F01 per l'aggiunta di uno spazio
*&              nel file di output.
*&---------------------------------------------------------------------*
*& Modifiche:   Raffaele Frattini     RF
*& Data:        15/12/2008
*& Descrizione: Aggiunta Range Numerico per parallelizzare il caso full
*&---------------------------------------------------------------------*
*& Modifiche:   Raffaele Frattini     RF
*& Data:        09/02/2009
*& Descrizione: Se nei campi #Descrizione# e #Note# è presente il campo
*               pipe (|) bisogna inserire un trattino prima di scriverlo
*               su file
*&---------------------------------------------------------------------*
*& Modifiche:   Raffaele Frattini     RF
*& Data:        24/02/2009
*& Descrizione: Eliminazione caratteri sporchi
*&---------------------------------------------------------------------*
*& Modifiche:   Concetta Pastore CP
*& Data:        15/05/2009
*& Descrizione: Aggiunta campi al tracciato di output
*&---------------------------------------------------------------------*
*& Modifiche:   Claudia Lariccia CL
*& Data:        03/06/2013
*& Descrizione: Integrazione campo Sede lavoro per promotore finanziario
*&---------------------------------------------------------------------*
*& Modifiche:   Claudia Lariccia CL
*& Data:        01/07/2013
*& Descrizione: Aggiunta campi al tracciato di output:
*&              referente e ruolo referente
*&---------------------------------------------------------------------*
*& Modifiche:   Mario Scala MS
*& Data:        16/07/2014
*& Descrizione: Parallelizzazione elaborazione
*&---------------------------------------------------------------------*
*& Modifiche:   CAP
*& Data:        07/06/2016
*& Descrizione: Aggiunta campi al tracciato di output
*&---------------------------------------------------------------------*
REPORT  zcae_edwhae_activity.

INCLUDE ZCAE_EDWHAE_ACTIVITY_TOP.
*INCLUDE ZCAE_EDWHAE_ACTIVITY_N_TOP.
*INCLUDE zcae_edwhae_activity_top.
INCLUDE ZCAE_EDWHAE_ACTIVITY_F01.
*INCLUDE ZCAE_EDWHAE_ACTIVITY_N_F01.
*INCLUDE zcae_edwhae_activity_f01.

* -- Inizio RF ADD 15/12/2008
AT SELECTION-SCREEN.

  IF s_objid[] IS INITIAL AND NOT r_full IS INITIAL.
    MESSAGE e208(00) WITH text-001.
  ENDIF.
* -- Fine RF ADD 15/12/2008

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

* Begin MS 21.07.2014
  MESSAGE ID 'ZCAR2_EVOL' TYPE 'I' NUMBER '050' WITH text-t03 space va_fileout(50) va_fileout+50.
  MESSAGE ID 'ZCAR2_EVOL' TYPE 'I' NUMBER '050' WITH text-t02 space va_filelog(50) va_filelog+50.
* End MS 21.07.2014


*Messages
*----------------------------------------------------------
*
* Message class: 00
*208   &
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
