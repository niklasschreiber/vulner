REPORT  zcae_edwhae_survey.
***********************************************************************************
* PROGRAM ID           : ZCAE_EDWHAE_SURVEY                                        *
* PROGRAM TITLE        : Interfaccia Outbound verso EDWH - Estrazione Survey       *
* AUTHOR               : Smriti Singh                                              *
* SUPPLIER             : Accenture Services Pvt. Ltd.                              *
* DATE                 : 09/10/2008                                                *
* DEVELOPMENT ID       : EDW_006                                                   *
* CHANGE REQUEST (CTS) : CWDK908005                                                *
* DESCRIPTION          : The interface allows the extraction of the data inside    *
*                        the Survey present in the SAP CRM system. The interface   *
*                        in question shall not have to create or delete the Survey *
*                        in the system but rather exclusively populate an output   *
*                        file which then is going to be used by EDWH for updating  *
*                        its own DB.                                               *
*==================================================================================*
* COPIED FROM         : (N/A)                                                      *
* TITLE               : (N/A)                                                      *
* OTHER RELATED OBJ   : (N/A)                                                      *
*==================================================================================*
* CHANGE HISTORY LOG                                                               *
*----------------------------------------------------------------------------------*
* MOD. NO.|  DATE    | NAME           | CORRECTION NUMBER  | CHANGE REFERENCE #    *
*----------------------------------------------------------------------------------*
* |       |14/10/2008|SMRITI SINGH    |  XXXXXXXXXXX       | Initial VersioION     *
************************************************************************************
*INCLUDES                                                               *
***********************************************************************************
*Include for top declarations
INCLUDE :zcae_edwhae_survey_top,
*Include for selection screen
         zcae_edwhae_survey_sc,
*Include for all the performs
         zcae_edwhae_survey_form.
***********************************************************************************
*INITIALIZATION                                              *
***********************************************************************************
INITIALIZATION.
* Clear and Refresh All Work Areas, Internal Tables and Variables.
  PERFORM f_clear_var.

**********************************************************************************
*START-OF-SELECTION                                                     *
***********************************************************************************

START-OF-SELECTION.

* get  value Z_NAME_PAR and Z_APPL
  PERFORM f_fetch_zca_param.

* Get the file names and open it in output mode.
  PERFORM f_open_files.

* If delta radio button is selected
  IF NOT p_delta IS INITIAL.
*Select consideting date to and date from and send the record to file
    PERFORM f_selection_delta.
  ELSE.
*Select full data and send the record to file
    PERFORM f_selection_full.

  ENDIF.

* -- Elaborazione Ultimo Record
  PERFORM f_elabora_last_record.

*perform to fetch the question record.
  PERFORM f_fetch_crm_svy_re_quest.

**perform to fetch the record for the answer.
  PERFORM f_fetch_crm_svy_re_answ.

*close all the files after writting into the files
  PERFORM f_close_files.

*Text elements
*----------------------------------------------------------
* 005 Impossibile aprire il file in scrittura
* 006 File Logico Errato
* 015 eccezione rilevata
* 016 Impossibile determinare la data attuale.
* 017 Eseguire il programma in background
* 018 in un job chiamato ZCAE_EDWHAE_SURVEY
* 019 estrazione Survey avvenuta con successo
* 020 estrazione Question avvenuta con successo
* 021 estrazione Header avvenuta con successo
* 023 Impossibile determinare la data iniziale. Eseguire il programma in modalità full oppure specificare una data iniziale
* 025 estrazione Answer avvenuta con successo
* 028 Errore di estrazione dei parametri
* S01 Parametri di input Survey
* S05 Modalità di lancio
* S11 File Names
* S14 Timestamp


*Selection texts
*----------------------------------------------------------
* P_ANSW         Nome File Output ANSWER
* P_DELTA         Delta
* P_FILE         Nome File Output SURVEY
* P_FULL         Full
* P_HEAD         Nome File Output HEADER
* P_LOG1         Nome File Log HEADER
* P_LOG2         Nome File Log SURVEY
* P_LOG3         Nome File Log QUESTION
* P_LOG4         Nome File Log ANSWER
* P_PACK         Package
* P_QUEST         Nome File Output QUESTION
* P_TSTP         Timestamp


*Messages
*----------------------------------------------------------
*
* Message class: 00
*398   & & & &

----------------------------------------------------------------------------------
Extracted by Mass Download version 1.5.5 - E.G.Mellodew. 1998-2020. Sap Release 740
