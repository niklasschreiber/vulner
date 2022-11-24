       IDENTIFICATION DIVISION.                                         00020000
       PROGRAM-ID. BPFCX015.                                            00040099
       AUTHOR.   - BANKSIEL.                                            00050099
       DATA-WRITTEN.  16/07/2002.                                       00051099
      *-------------------------------------------------------------*   00060000
      *        E L A B O R A Z I O N E     B P F C X 0 1 5          *   00060199
      *-------------------------------------------------------------*   00060200
      *  IL PROGRAMMA SI OCCUPA DELLA GESTIONE DI VARIAZIONE STATO  *   00060399
      *  DI UN BUONO POSTALE, PUO' ESSERE ATTIVATO SIA DA 3270 CHE  *   00060499
      *  DA AGENZIA TRAMITE INTEGRATORE                             *   00060499
      *                                                             *   00060538
      *  TRANSID = "BPC5" (3270)                                    *   00061499
      *          = "BPC7" (AGENZIA)                                 *   00061499
      *  MAPSET  = "BPX015"                                         *   00061599
      *-------------------------------------------------------------*   00062001
171103* 17 11 2003 MODIFICATO IL FRAZIONARIO DI IMMISSIONE          *   00062001
171103*-------------------------------------------------------------*   00062001
111203* 11 12 2003 MODIFICATA LA GESTIONE DEL ROLLBACK              *   00062001
EC0406*-------------------------------------------------------------*   00062001
EC0406* 04 06 2004 MODIFICA X IMPLEMENTO CONTROLLO                  *   00062001
EC0406*            CODELINE/NUMERO BUONO                            *   00062001
EC0406*-------------------------------------------------------------*   00062001
      * 29 07 2004 GDI3039                                          *   00062001
      *            INIBITA ATTIVAZIONE DIRETTA                      *   00062001
      *-------------------------------------------------------------*   00062001
LM2804* 28 04 2005 GDI3052 (MATTALINI)                              *   00062001
LM2804* INSERITI CONTROLLI FORMALI E CHIAMATA AL MODULO BPFCX156    *   00062001
LM2804*-------------------------------------------------------------*   00062001
                                                                        00063001
       ENVIRONMENT DIVISION.                                            00070000
                                                                        00080000
       CONFIGURATION SECTION.                                           00090000
       SPECIAL-NAMES.                                                   00100000
               DECIMAL-POINT IS COMMA.                                  00110000
                                                                        00120000
       DATA DIVISION.                                                   00133000
                                                                        00135000
       WORKING-STORAGE SECTION.                                         00136000
      *                                                                 00136199
      *--- CAMPI DI COMODO                                              00291637
       01    SIPRACF             PIC  X(0008) VALUE 'SIPRACF '.         00291799
       01    XSXDAT              PIC  X(0008) VALUE 'XSXDAT  '.         00291799
       01    BPX015              PIC  X(0007) VALUE 'BPX015'.           00291799
       01    BPFCX002            PIC  X(0008) VALUE 'BPFCX002'.         00291799
EC0406 01    BPFCM012            PIC  X(0008) VALUE 'BPFCM012'.         00291799
170903 01    BPFCM026            PIC  X(0008) VALUE 'BPFCM026'.         00291799
LM1511 01    BPFCM043            PIC  X(0008) VALUE 'BPFCM043'.         00291799
       01    BPFCX048            PIC  X(0008) VALUE 'BPFCX048'.         00291799
       01    BPFCX049            PIC  X(0008) VALUE 'BPFCX049'.         00291799
LM2804 01    BPFCX156            PIC  X(0008) VALUE 'BPFCX156'.         00002900
       01    3270X002            PIC  X(0008) VALUE '3270X002'.         00291799
       01    TRND3270            PIC  X(0004) VALUE 'BPC5'.             00291799
      *                                                                 00136199
      *--- ATTRIBUTI                                                    00291637
       01    ATTR-BRT-FSET       PIC  X(0004) VALUE 'I'.                00291799
       01    ATTR-PROT-FSET      PIC  X(0004) VALUE '/'.                00291799
      *                                                                 00136199
       01    WS-DESC-MSG-X002    PIC  X(0070) VALUE SPACES.             00291799
       01    WS-AREA-MSG         PIC  X(0075) VALUE SPACES.             00291799
       01    WS-LUNG-MSG         PIC S9(0004) COMP VALUE +75.           00291799
       01    WS-RESP             PIC S9(0008) COMP.                     00291799
       01    WS-ERR-INTE         PIC  X(0001) VALUE '9'.                00291799
       01    WS-OK-INTE          PIC  X(0001) VALUE '0'.                00291799
LM1411 01    WS-PROFILO          PIC  X(0008).                          00291799
LM1411 01    WS-USERID           PIC  X(0008).                          00291799
171103 01    WS-FRAZ-IMM         PIC  X(0005).                          00291799
       01    WS-DATA-CONT        PIC  X(0008).                          00291799
       01    WS-DATA-CONT-N      REDEFINES WS-DATA-CONT   PIC 9(0008).  00291799
EC0406 01    APPO-NUM-BUONO      PIC  9(0012) VALUE ZEROES.             00291799
EC0406 01    APPO-TAGLIO         PIC  9(0012) VALUE ZEROES.             00291799
LM2804 01    WS-TEMPO            PIC S9(0018) COMP-3.
LM2804 01    WS-EIB-DATA         PIC  X(0008).
LM2804 01    WS-EIB-DATA-N       PIC  9(0008) VALUE ZEROES.
LM2804 01    WS-DATA-DA10.
LM2804    03 WS-AAAA             PIC  X(0004) VALUE SPACES.
LM2804    03 FILLER              PIC  X(0001) VALUE '-'.
LM2804    03 WS-MM               PIC  X(0002) VALUE SPACES.
LM2804    03 FILLER              PIC  X(0001) VALUE '-'.
LM2804    03 WS-GG               PIC  X(0002) VALUE SPACES.
      *                                                                 00136199
      *--- COMMAREA                                                     00291637
       01       AREA-COMMAREA.
          03 HELP-PGM-CHIAMANTE  PIC  X(0008).
          03 HELP-TRND-CHIAMANTE PIC  X(0004).
          03 HELP-STATO-A        PIC  X(0002).
          03 HELP-STATO-DA       PIC  X(0002).
          03 HELP-PGM-ACCESSO    PIC  X(0008).
171103    03    CA-FRAZ-IMM      PIC  X(0005).
170903    03    CA-BLOCCA        PIC  X(0001).
          03    CA-AGE-EMISS     PIC  X(0005).
          03    CA-DATA-EMISS-X.
             05 CA-AAAA          PIC  X(0004).
             05 CA-MM            PIC  X(0002).
             05 CA-GG            PIC  X(0002).
          03    CA-DATA-EMISS-N  REDEFINES CA-DATA-EMISS-X PIC 9(0008).
          03    CA-TIPO-BUONO    PIC  X(0001).
          03    CA-DIVISA        PIC  X(0001).
          03    CA-TAGLIO.
             05 FILLER           PIC  X(0003).
             05 CA-TAGLIO-X      PIC  X(0009).
          03    CA-TAGLIO-N      REDEFINES CA-TAGLIO      PIC 9(0012).
          03    CA-NUM-BUONO-X   PIC  X(0012).
          03    CA-NUM-BUONO-N   REDEFINES CA-NUM-BUONO-X PIC 9(0012).
          03    CA-SERIE         PIC  X(0004).
          03    CA-NOTE.
             05 CA-NOTE1         PIC  X(0060).
             05 CA-NOTE2         PIC  X(0060).
             05 CA-NOTE3         PIC  X(0060).
          03    CA-NEW-STATO     PIC  X(0001).
          03    CA-OLD-STATO     PIC  X(0001).
          03    CA-PRIMO-GIRO    PIC  9(0001).
          03    CA-USERID        PIC  X(0008).
          03    CA-PROFILO       PIC  X(0008).
LM1511    03    CA-STATO         PIC  X(0001).
LM1511    03    CA-DESC-STATO-O  PIC  X(0030).
LM1511    03    CA-DESC-STATO-N  PIC  X(0030).
170903*   03    FILLER           PIC  X(0173).
170903*   03    FILLER           PIC  X(0172).
171103    03    FILLER           PIC  X(0167).
      *--------------  COPY COMMAREA MENU ----------------------------*
SF0801     COPY  BPFCC048.
      *                                                                 00136199
      *--- MESSAGGI                                                     00291637
       01    MSG-ERR-X002        PIC  X(0050) VALUE
             'ERRORE LINK MODULO BPFCX002                       '.
LM2804 01    MSG-ERR-X156        PIC  X(0050) VALUE
LM2804       'ERRORE LINK MODULO BPFCX156                       '.
170903 01    MSG-ERR-M026        PIC  X(0050) VALUE
170903       'ERRORE LINK MODULO BPFCM026                       '.
LM1511 01    MSG-ERR-M043        PIC  X(0050) VALUE
LM1511       'ERRORE LINK MODULO BPFCM043                       '.
       01    MSG-FINETRA         PIC  X(0050) VALUE
             '***  F I N E  L A V O R O  ***                    '.
170903 01    MSG-ERRDIP          PIC  X(0050) VALUE
170903       'FUNZIONE NON ABILITATA                            '.
       01    MSG-ERRDATI         PIC  X(0050) VALUE
             'CAMPO OBBLIGATORIO                                '.
       01    MSG-ERRDATA         PIC  X(0050) VALUE
             'DATA ERRATA                                       '.
LM2804 01    MSG-ERRDATA-EMISS   PIC  X(0050) VALUE
LM2804       'DATA EMISSIONE MAGGIORE DI DATA ELABORAZIONE      '.
       01    MSG-ERRDIV          PIC  X(0050) VALUE
             'DIVISA ERRATA DIGITARE ITL OPPURE EUR             '.
LM2804 01    MSG-ERRTIPO         PIC  X(0050) VALUE
LM2804       'TIPOLOGIA BUONO ERRATA DIGITARE T OPPURE O        '.
LM2804 01    MSG-ERRTAGLIO       PIC  X(0050) VALUE
LM2804       'TAGLIO BUONO NON NUMERICO O NON VALORIZZATO       '.
LM2804 01    MSG-ERRNUMERO       PIC  X(0050) VALUE
LM2804       'NUMERO BUONO NON NUMERICO O NON VALORIZZATO       '.
       01    MSG-PF5             PIC  X(0050) VALUE
             'PREMERE PF5 PER CONFERMARE                        '.
       01    MSG-PF9             PIC  X(0050) VALUE
             'PREMERE PF9 E INSERIRE NUOVI DATI                 '.
       01    MSG-ERRTAS          PIC  X(0050) VALUE
             'TASTO NON ABILITATO                               '.
       01    MSG-TUTTO-OK        PIC  X(0050) VALUE
             'ELABORAZIONE ESEGUITA CORRETTAMENTE               '.
       01    MSG-ISRT-NS         PIC  X(0050) VALUE
             'COMPLETARE DATI E CONFERMARE O ATTIVARE HELP      '.
EC0406 01    MSG-ERR350          PIC  X(0050) VALUE
EC0406       'ERRORE NUMERO BUONO COINCIDENTE CON CODELINE      '.
      *--- MESSAGGIO OPERAZIONE NON CONSENTITA
       01       AREA-MESS           PIC  X(0025)
                              VALUE 'OPERAZIONE NON CONSENTITA'.
      *
      *--- AREA DATI                                                    00170099
EC0406*--- COPY AREA CALCOLO CODELINE                                   00184099
EC0406     COPY BPFCW012.                                               00184099
       01       AREAW013.                                               00184099
           COPY BPFCW013.                                               00184099
170903 01       AREAW026.                                               00184099
170903     COPY BPFCW026.                                               00184099
       01       AREAW029.                                               00184099
           COPY BPFCW029.                                               00184099
LM1511 01       AREAW043.                                               00184099
LM1511     COPY BPFCW043.                                               00184099
LM2804 01       AREAW031.                                               00026920
LM2804     COPY BPFCW031.                                               00026930
      *--- COPY PER INTERFACCIA CONTROLLO ACCESSI                       00221037
           COPY SIPRACFA.                                               00221199
           COPY CAXC10A.                                                00222099
      *--- COPY MAPPA                                                   00223022
           COPY BPX015.                                                 00224099
      *--- COPY PER CONTROLLO DATA                                      00223022
           COPY XSADAT.                                                 00224099
      *--- COPY CICS                                                    00227099
           COPY DFHBMSCA.                                               00229003
           COPY DFHAID.                                                 00229103
      *                                                                 00291899
      *                                                                 00291899
       LINKAGE SECTION.                                                 00488699
       01 DFHCOMMAREA            PIC X(0500).                           00184099
      ***************************************************************** 00489003
      *             P R O C E D U R E         D I V I S I O N         * 00489800
      ***************************************************************** 00489900
       PROCEDURE DIVISION USING DFHCOMMAREA.                            00490000
      *                                                                 00491000
       MAIN.                                                            00510032
      *                                                                 00510131
           PERFORM A010-INIZIO           THRU  A010-INIZIO-EX.          00510299
      *                                                                 00510332
           IF      HELP-PGM-CHIAMANTE    =     BPFCX049
              IF   HELP-STATO-A          >     SPACES
                   MOVE    1             TO    CA-PRIMO-GIRO
                   MOVE    SPACES        TO    HELP-PGM-CHIAMANTE
                   MOVE    HELP-STATO-A  TO    CA-NEW-STATO
                   MOVE    SPACES        TO    M01MESSO                 00527299
                   MOVE    MSG-PF5       TO    M01MESSO                 00527299
                   MOVE    -1            TO    M01AGENL                 00524099
LM1511             INITIALIZE                  AREAW043                 00527299
LM1511             MOVE    CA-NEW-STATO  TO    W043-STATO-IN            00527299
LM1511             MOVE    'N'           TO    CA-STATO                 00527299
LM1511             PERFORM A200-LINK-BPFCM043
LM1511                THRU A200-LINK-BPFCM043-EX
              ELSE
                   MOVE    SPACES        TO    HELP-PGM-CHIAMANTE
                   MOVE    -1            TO    M01DESC1L                00524099
                   MOVE    SPACES        TO    M01MESSO                 00527299
                   MOVE    MSG-ISRT-NS   TO    M01MESSO                 00527299
              END-IF
                   PERFORM A160-PROTEGGI-MAPPA
                      THRU A160-PROTEGGI-MAPPA-EX
                   PERFORM A140-CARICA-MAPPA
                      THRU A140-CARICA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA
                      THRU A040-INVIA-MAPPA-EX
           END-IF.
      *
           PERFORM A020-RICEVI-MAPPA     THRU  A020-RICEVI-MAPPA-EX.    00510699
      *                                                                 00510732
       END-MAIN.                                                        00512032
           EXIT.                                                        00526390
      *-----------------------------------------------------------------00522237
      *-------------------------------------------------------------*   00522399
      *            I N I Z I O     E L A B O R A Z I O N E          *   00522499
      *-------------------------------------------------------------*   00522599
       A010-INIZIO.                                                     00522999
           IF EIBCALEN = ZEROES                                         00523931
              IF EIBTRNID = 'BPCF'
                 MOVE       ZEROES          TO   CA-PRIMO-GIRO          00622099
                 MOVE       SPACES          TO   CA-BLOCCA              00622099
                 PERFORM    A100-CTR-UTENTE THRU A100-CTR-UTENTE-EX     00523299
260903           IF         SIPRACF-POSIZ-LIV-FISICO-TERM = 03
170903                    PERFORM A110-CTR-AGENZ  THRU A110-CTR-AGENZ-EX00523299
260903           END-IF
                 MOVE       -1              TO   M01AGENL               00524099
                 PERFORM    A030-PREPARA-MAPPA                          00524199
                    THRU    A030-PREPARA-MAPPA-EX                       00524199
                 PERFORM    A040-INVIA-MAPPA                            00524199
                    THRU    A040-INVIA-MAPPA-EX                         00524199
              ELSE
                 EXEC CICS SEND TEXT FROM(AREA-MESS)
                 END-EXEC
                 EXEC CICS RETURN END-EXEC
              END-IF
           ELSE                                                         00526090
              MOVE       DFHCOMMAREA     TO   AREA-COMMAREA             00844399
              MOVE       -1              TO   M01AGENL                  00524099
           END-IF.                                                      00526090
      *                                                                 00526090
       A010-INIZIO-EX.                                                  00526299
           EXIT.                                                        00526390
      *-----------------------------------------------------------------00522237
       A020-RICEVI-MAPPA.                                               00611999
      *                                                                 00612034
           EXEC CICS IGNORE CONDITION MAPFAIL END-EXEC.                 00612179
      *                                                                 00612279
           EXEC CICS RECEIVE MAP    ('BPX015')                          00612499
                             MAPSET ('BPX015')                          00612599
           END-EXEC.                                                    00612634
      *                                                                 00612734
           PERFORM A050-CTRL-TASTI  THRU A050-CTRL-TASTI-EX.            00612899
      *                                                                 00612934
       A020-RICEVI-MAPPA-EX.                                            00613099
           EXIT.                                                        00613134
      *-----------------------------------------------------------------00522237
       A030-PREPARA-MAPPA.                                              00530499
      *
           INSPECT M01AGENI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01AGENI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *
           INSPECT M01GGEMI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01GGEMI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
           INSPECT M01MMEMI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01MMEMI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
           INSPECT M01AAEMI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01AAEMI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *
           INSPECT M01TIPOI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01TIPOI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01TAGI   REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01TAGI   REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01DIVI   REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01DIVI   REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01NUMBI  REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01NUMBI  REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01SERIEI REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01SERIEI REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01DESC1I REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01DESC1I REPLACING ALL LOW-VALUE  BY '_'.           00527299
           INSPECT M01DESC2I REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01DESC2I REPLACING ALL LOW-VALUE  BY '_'.           00527299
           INSPECT M01DESC3I REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01DESC3I REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01STATNI REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01STATNI REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           INSPECT M01STATVI REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01STATVI REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
       A030-PREPARA-MAPPA-EX.                                           00540099
           EXIT.                                                        00604032
      *-----------------------------------------------------------------00522237
       A040-INVIA-MAPPA.                                                00604748
      *                                                                 00604899
           IF      M01DESC1I              = SPACES                      00527299
                INSPECT M01DESC1I REPLACING ALL ' '        BY '_'            005
                INSPECT M01DESC1I REPLACING ALL LOW-VALUE  BY '_'            005
                INSPECT M01DESC2I REPLACING ALL ' '        BY '_'            005
                INSPECT M01DESC2I REPLACING ALL LOW-VALUE  BY '_'            005
                INSPECT M01DESC3I REPLACING ALL ' '        BY '_'            005
                INSPECT M01DESC3I REPLACING ALL LOW-VALUE  BY '_'            005
           END-IF.
           INSPECT M01STATNI REPLACING ALL ' '        BY '_'.           00527299
           INSPECT M01STATNI REPLACING ALL LOW-VALUE  BY '_'.           00527299
      *                                                                 00534037
           EXEC CICS IGNORE CONDITION MAPFAIL END-EXEC.
      *
           EXEC CICS SEND   MAP      (BPX015)                           00607099
                            FROM     (BPX015O)                          00608099
                            ERASE                                       00608133
                            CURSOR                                      00608245
           END-EXEC.                                                    00609033
      *                                                                 00609132
           EXEC CICS RETURN TRANSID  (TRND3270)                         00609832
                            COMMAREA (AREA-COMMAREA)                    00609932
                            LENGTH   (LENGTH OF AREA-COMMAREA)          00610032
           END-EXEC.                                                    00610132
      *                                                                 00610232
       A040-INVIA-MAPPA-EX.                                             00610332
           EXIT.                                                        00610432
      *-----------------------------------------------------------------00522237
       A050-CTRL-TASTI.                                                 00620099
      *                                                                 00510732
           EVALUATE TRUE                                                00621134
               WHEN EIBAID  EQUAL DFHCLEAR                              00621334
                    PERFORM X030-FINE                                   00621437
                    PERFORM X030-FINE-EX                                00621437
               WHEN EIBAID  EQUAL DFHENTER                              00621634
170903              IF         CA-BLOCCA     =      'X'                 00527299
170903                 MOVE    SPACES        TO     M01MESSO            00527299
170903                 MOVE    MSG-ERRDIP    TO     M01MESSO            00527299
170903                 MOVE    -1            TO     M01AGENL            00524099
170903                 PERFORM A160-PROTEGGI-MAPPA                      00527299
170903                    THRU A160-PROTEGGI-MAPPA-EX                   00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC1A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC2A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC3A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01STATNA                 00527299
170903                 PERFORM A040-INVIA-MAPPA                         00527299
170903                    THRU A040-INVIA-MAPPA-EX                      00527299
170903              END-IF                                              00527299
                    IF         CA-PRIMO-GIRO =      2                   00527299
                       MOVE    SPACES        TO     M01MESSO            00527299
                       MOVE    MSG-PF9       TO     M01MESSO            00527299
                       MOVE    -1            TO     M01AGENL            00524099
                       PERFORM A160-PROTEGGI-MAPPA
                          THRU A160-PROTEGGI-MAPPA-EX
                       PERFORM A140-CARICA-MAPPA
                          THRU A140-CARICA-MAPPA-EX
                       PERFORM A040-INVIA-MAPPA
                          THRU A040-INVIA-MAPPA-EX
                    END-IF                                              00527299
                    IF         CA-OLD-STATO  >      SPACES              00527299
                       MOVE    CA-OLD-STATO  TO M01STATVI               00527299
                    END-IF                                              00527299
                    PERFORM A060-CTRL-DATI                              00621799
                       THRU A060-CTRL-DATI-EX                           00621799
LM2804            IF        CA-DIVISA = 'L'                             00059130
LM2804              PERFORM L080-LINK-BPFCX156                          00059130
LM2804                 THRU L080-LINK-BPFCX156-EX                       00059140
LM2804            END-IF                                                00059130
                    MOVE    SPACES        TO     M01MESSO               00527299
                    MOVE    MSG-PF5       TO     M01MESSO               00527299
                    MOVE    -1            TO     M01AGENL               00524099
                    PERFORM A030-PREPARA-MAPPA
                       THRU A030-PREPARA-MAPPA-EX
                    PERFORM A040-INVIA-MAPPA                            00524299
                       THRU A040-INVIA-MAPPA-EX                         00524299
               WHEN EIBAID  EQUAL DFHPF3                                00621999
                    PERFORM X040-MENU                                   00622099
                       THRU X040-MENU-EX                                00622099
               WHEN EIBAID  EQUAL DFHPF5                                00621999
170903              IF         CA-BLOCCA     =      'X'                 00527299
170903                 MOVE    SPACES        TO     M01MESSO            00527299
170903                 MOVE    MSG-ERRDIP    TO     M01MESSO            00527299
170903                 MOVE    -1            TO     M01AGENL            00524099
170903                 PERFORM A160-PROTEGGI-MAPPA                      00527299
170903                    THRU A160-PROTEGGI-MAPPA-EX                   00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC1A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC2A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC3A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01STATNA                 00527299
170903                 PERFORM A040-INVIA-MAPPA                         00527299
170903                    THRU A040-INVIA-MAPPA-EX                      00527299
170903              END-IF                                              00527299
                    PERFORM A060-CTRL-DATI                              00621799
                       THRU A060-CTRL-DATI-EX                           00621799
LM2804            IF        CA-DIVISA = 'L'                             00059130
LM2804              PERFORM L080-LINK-BPFCX156                          00059130
LM2804                 THRU L080-LINK-BPFCX156-EX                       00059140
LM2804            END-IF                                                00059130
                    PERFORM A090-PREPARA-LINK                           00622099
                       THRU A090-PREPARA-LINK-EX                        00622099
                    PERFORM A120-LINK-BPFCX002                          00622099
                       THRU A120-LINK-BPFCX002-EX                       00622099
               WHEN EIBAID  EQUAL DFHPF9                                00621999
170903              IF         CA-BLOCCA     =      'X'                 00527299
170903                 MOVE    SPACES        TO     M01MESSO            00527299
170903                 MOVE    MSG-ERRDIP    TO     M01MESSO            00527299
170903                 MOVE    -1            TO     M01AGENL            00524099
170903                 PERFORM A160-PROTEGGI-MAPPA                      00527299
170903                    THRU A160-PROTEGGI-MAPPA-EX                   00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC1A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC2A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC3A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01STATNA                 00527299
170903                 PERFORM A040-INVIA-MAPPA                         00527299
170903                    THRU A040-INVIA-MAPPA-EX                      00527299
170903              END-IF                                              00527299
                    MOVE    SPACES        TO     BPX015I                00622099
LM1411              MOVE    CA-PROFILO    TO     WS-PROFILO             00622099
LM1411              MOVE    CA-USERID     TO     WS-USERID              00622099
171103              MOVE    CA-FRAZ-IMM   TO     WS-FRAZ-IMM            00622099
                    INITIALIZE                   AREA-COMMAREA          00622099
LM1411              MOVE    WS-PROFILO    TO     CA-PROFILO             00622099
LM1411              MOVE    WS-USERID     TO     CA-USERID              00622099
171103              MOVE    WS-FRAZ-IMM   TO     CA-FRAZ-IMM            00622099
                    MOVE    ZEROES        TO     CA-PRIMO-GIRO          00622099
                    PERFORM A030-PREPARA-MAPPA
                       THRU A030-PREPARA-MAPPA-EX
                    MOVE    -1            TO     M01AGENL               00524099
                    PERFORM A040-INVIA-MAPPA                            00524299
                       THRU A040-INVIA-MAPPA-EX                         00524299
               WHEN OTHER                                               00622134
170903              IF         CA-BLOCCA     =      'X'                 00527299
170903                 MOVE    SPACES        TO     M01MESSO            00527299
170903                 MOVE    MSG-ERRDIP    TO     M01MESSO            00527299
170903                 MOVE    -1            TO     M01AGENL            00524099
170903                 PERFORM A160-PROTEGGI-MAPPA                      00527299
170903                    THRU A160-PROTEGGI-MAPPA-EX                   00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC1A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC2A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01DESC3A                 00527299
170903                 MOVE ATTR-PROT-FSET TO M01STATNA                 00527299
170903                 PERFORM A040-INVIA-MAPPA                         00527299
170903                    THRU A040-INVIA-MAPPA-EX                      00527299
170903              END-IF                                              00527299
                    MOVE    -1            TO     M01AGENL               00527299
                    MOVE    SPACES        TO     M01MESSO               00527299
                    MOVE    MSG-ERRTAS    TO     M01MESSO               00527299
                    PERFORM A030-PREPARA-MAPPA                          00524299
                       THRU A030-PREPARA-MAPPA-EX                       00524299
                    PERFORM A040-INVIA-MAPPA                            00524299
                       THRU A040-INVIA-MAPPA-EX                         00524299
           END-EVALUATE.                                                00622934
      *                                                                 00623027
       A050-CTRL-TASTI-EX.                                              00623199
           EXIT.                                                        00623233
      *-----------------------------------------------------------------00522237
       A060-CTRL-DATI.                                                  00530499
      *
           PERFORM A070-PULISCI-CAMPI    THRU A070-PULISCI-CAMPI-EX     00524299
      *
           IF      M01AGENI              NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01AGENL                00527299
                   MOVE    ATTR-BRT-FSET TO     M01AGENA                00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   MOVE    M01AGENI      TO     CA-AGE-EMISS            00527299
           END-IF.                                                      00527299
      *
           IF      M01GGEMI              NOT  > SPACES   AND            00527299
                   M01MMEMI              NOT  > SPACES   AND            00527299
                   M01AAEMI              NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01GGEML                00527299
                   MOVE    ATTR-BRT-FSET TO     M01GGEMA                00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   MOVE    M01GGEMI      TO     CA-GG                   00527299
                   MOVE    M01MMEMI      TO     CA-MM                   00527299
                   MOVE    M01AAEMI      TO     CA-AAAA                 00527299
                   PERFORM A080-CTR-DATA-VALIDA
                      THRU A080-CTR-DATA-VALIDA-EX
           END-IF.                                                      00527299
      *
           IF      M01TIPOI              NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01TIPOL                00527299
                   MOVE    ATTR-BRT-FSET TO     M01TIPOA                00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
LM2804*            MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
LM2804             MOVE    MSG-ERRTIPO   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
LM2804          IF         M01TIPOI      NOT =  'T' AND                 00527299
LM2804                     M01TIPOI      NOT =  'O'                     00527299
LM2804             MOVE    -1            TO     M01TIPOL                00527299
LM2804             MOVE    ATTR-BRT-FSET TO     M01TIPOA                00527299
LM2804             MOVE    SPACES        TO     M01MESSO                00527299
LM2804             MOVE    MSG-ERRTIPO   TO     M01MESSO                00527299
LM2804             PERFORM A030-PREPARA-MAPPA
LM2804                THRU A030-PREPARA-MAPPA-EX
LM2804             PERFORM A040-INVIA-MAPPA                             00524299
LM2804                THRU A040-INVIA-MAPPA-EX                          00524299
LM2804          END-IF                                                  00527299
                   MOVE    M01TIPOI      TO     CA-TIPO-BUONO           00527299
           END-IF.                                                      00527299
      *
           IF      M01TAGI               NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01TAGL                 00527299
                   MOVE    ATTR-BRT-FSET TO     M01TAGA                 00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   EXEC CICS BIF DEEDIT
                                 FIELD  (M01TAGI)
                                 LENGTH (12)
                   END-EXEC
LM2804        IF           M01TAGI       IS NOT NUMERIC
LM2804        OR           M01TAGI          NOT >  ZEROES
LM2804             MOVE    -1            TO     M01TAGL                 00527299
LM2804             MOVE    ATTR-BRT-FSET TO     M01TAGA                 00527299
LM2804             MOVE    SPACES        TO     M01MESSO                00527299
LM2804             MOVE    MSG-ERRTAGLIO TO     M01MESSO                00527299
LM2804             PERFORM A030-PREPARA-MAPPA
LM2804                THRU A030-PREPARA-MAPPA-EX
LM2804             PERFORM A040-INVIA-MAPPA                             00524299
LM2804                THRU A040-INVIA-MAPPA-EX                          00524299
LM2804        ELSE
                   MOVE    M01TAGI       TO     CA-TAGLIO               00527299
EC0406             MOVE    CA-TAGLIO-N   TO     APPO-TAGLIO             00527299
LM2804        END-IF
           END-IF.                                                      00527299
      *
           IF      M01DIVI               NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01DIVL                 00527299
                   MOVE    ATTR-BRT-FSET TO     M01DIVA                 00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   IF      M01DIVI       NOT =  'EUR' AND               00527299
                           M01DIVI       NOT =  'ITL'                   00527299
                      MOVE    -1            TO     M01DIVL              00527299
LM2804                MOVE    ATTR-BRT-FSET TO     M01DIVA              00527299
                      MOVE    SPACES        TO     M01MESSO             00527299
                      MOVE    MSG-ERRDIV    TO     M01MESSO             00527299
                      PERFORM A030-PREPARA-MAPPA
                         THRU A030-PREPARA-MAPPA-EX
                      PERFORM A040-INVIA-MAPPA                          00524299
                         THRU A040-INVIA-MAPPA-EX                       00524299
                   END-IF                                               00527299
                   IF      M01DIVI       =      'EUR'                   00527299
                      MOVE 'E'           TO     CA-DIVISA               00527299
                   END-IF                                               00527299
                   IF      M01DIVI       =      'ITL'                   00527299
                      MOVE 'L'           TO     CA-DIVISA               00527299
                   END-IF                                               00527299
           END-IF.                                                      00527299
      *
           IF      M01NUMBI              NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01NUMBL                00527299
                   MOVE    ATTR-BRT-FSET TO     M01NUMBA                00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   EXEC CICS BIF DEEDIT
                                 FIELD  (M01NUMBI)
                                 LENGTH (12)
                   END-EXEC
LM2804        IF           M01NUMBI      IS NOT NUMERIC
LM2804        OR           M01NUMBI         NOT > ZEROES
LM2804             MOVE    -1            TO     M01NUMBL                00527299
LM2804             MOVE    ATTR-BRT-FSET TO     M01NUMBA                00527299
LM2804             MOVE    SPACES        TO     M01MESSO                00527299
LM2804             MOVE    MSG-ERRNUMERO TO     M01MESSO                00527299
LM2804             PERFORM A030-PREPARA-MAPPA
LM2804                THRU A030-PREPARA-MAPPA-EX
LM2804             PERFORM A040-INVIA-MAPPA                             00524299
LM2804                THRU A040-INVIA-MAPPA-EX                          00524299
LM2804        ELSE
                   MOVE    M01NUMBI      TO     CA-NUM-BUONO-X          00527299
EC0406             MOVE    M01NUMBI      TO     APPO-NUM-BUONO          00527299
LM2804        END-IF
           END-IF.                                                      00527299
      *
EC0406*---- CONTROLLO CODELINE/NUMERO BUONO
EC0406
EC0406     IF APPO-NUM-BUONO(1:7) NOT = ZEROES AND
EC0406        M01DIVI                 = 'EUR'
EC0406        PERFORM LINK-MAD-M012      THRU LINK-MAD-M012-EX.
EC0406*
           IF      M01SERIEI             NOT  > SPACES                  00527299
                   MOVE    -1            TO     M01SERIEL               00527299
                   MOVE    ATTR-BRT-FSET TO     M01SERIEA               00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
           ELSE                                                         00527299
                   MOVE    M01SERIEI     TO     CA-SERIE                00527299
           END-IF.                                                      00527299
      *
           IF      M01DESC1I                  > SPACES                  00527299
                   MOVE    M01DESC1I     TO     CA-NOTE1                00527299
           ELSE                                                         00527299
                   MOVE    SPACES        TO     CA-NOTE1                00527299
           END-IF.                                                      00527299
           IF      M01DESC2I                  > SPACES                  00527299
                   MOVE    M01DESC2I     TO     CA-NOTE2                00527299
           ELSE                                                         00527299
                   MOVE    SPACES        TO     CA-NOTE2                00527299
           END-IF.                                                      00527299
           IF      M01DESC3I                  > SPACES                  00527299
                   MOVE    M01DESC3I     TO     CA-NOTE3                00527299
           ELSE                                                         00527299
                   MOVE    SPACES        TO     CA-NOTE3                00527299
           END-IF.                                                      00527299
      *
           IF      M01STATVI                  > SPACES
                   MOVE    M01STATVI     TO     CA-OLD-STATO
           END-IF.
      *
           IF      M01STATNI                  = '?'                     00527299
              AND (M01STATVI                  > ' '                     00621634
              AND  M01STATVI             NOT  = '_')                    00621634
              AND  EIBAID                =      DFHENTER                00621634
                   PERFORM H010-ATTIVA-HELP
                      THRU H010-ATTIVA-HELP-EX
           END-IF.                                                      00527299
      *
           IF      M01STATNI             NOT  > SPACES                  00527299
                IF CA-PRIMO-GIRO         =      1                       00527299
                   MOVE    -1            TO     M01STATNL               00527299
                   MOVE    ATTR-BRT-FSET TO     M01STATNA               00527299
                   MOVE    SPACES        TO     M01MESSO                00527299
                   MOVE    MSG-ERRDATI   TO     M01MESSO                00527299
                   PERFORM A030-PREPARA-MAPPA
                      THRU A030-PREPARA-MAPPA-EX
                   PERFORM A040-INVIA-MAPPA                             00524299
                      THRU A040-INVIA-MAPPA-EX                          00524299
                ELSE                                                    00527299
                   MOVE    SPACES        TO     CA-NEW-STATO            00527299
                END-IF                                                  00527299
           ELSE                                                         00527299
                   MOVE    1             TO     CA-PRIMO-GIRO           00527299
                   MOVE    M01STATNI     TO     CA-NEW-STATO            00527299
           END-IF.                                                      00527299
      *
       A060-CTRL-DATI-EX.                                               00540099
           EXIT.                                                        00604032
      *                                                                 00534037
EC0406*--> MAD PER CONTROLLO CODELINE/NUMERO BUONO
EC0406
EC0406 LINK-MAD-M012.
EC0406
EC0406     INITIALIZE                   BPFCW012.
EC0406
EC0406     MOVE APPO-NUM-BUONO          TO W012-CODELINE-IN.
EC0406     MOVE M01TIPOI                TO W012-TIPOLOGIA-IN.
EC0406     MOVE APPO-TAGLIO             TO W012-TAGLIO-IN.
EC0406     MOVE APPO-NUM-BUONO(1:7)     TO W012-NUM-BUONO-IN.
EC0406
EC0406     EXEC CICS LINK PROGRAM  (BPFCM012)                           01389700
EC0406                    COMMAREA (BPFCW012)                           01389700
EC0406                    LENGTH   (LENGTH OF BPFCW012)                 01389700
EC0406     END-EXEC.                                                    01389700
EC0406
EC0406     IF W012-ESITO-OUT NOT = '00'                                 01389700
EC0406        INITIALIZE                 APPO-NUM-BUONO
EC0406        INITIALIZE                 APPO-TAGLIO
EC0406     ELSE                                                         01389700
EC0406        MOVE -1                    TO M01NUMBL                    00119800
EC0406        MOVE ATTR-BRT-FSET         TO M01NUMBA                    00117600
EC0406        MOVE SPACES                TO M01MESSO                    00527299
EC0406        MOVE MSG-ERR350            TO M01MESSO                    00527299
EC0406        PERFORM A030-PREPARA-MAPPA                                00098600
EC0406           THRU A030-PREPARA-MAPPA-EX                             00098700
EC0406        PERFORM A040-INVIA-MAPPA                                  00098800
EC0406           THRU A040-INVIA-MAPPA-EX                               00098900
EC0406     END-IF.                                                      01389700
EC0406
EC0406 LINK-MAD-M012-EX.
EC0406     EXIT.
EC0406*
      *-----------------------------------------------------------------00522237
       A070-PULISCI-CAMPI.                                              00530499
      *
           INSPECT M01AGENI  REPLACING ALL '_'  BY ' '.                 00527299
      *
           INSPECT M01GGEMI  REPLACING ALL '_'  BY ' '.                 00527299
           INSPECT M01MMEMI  REPLACING ALL '_'  BY ' '.                 00527299
           INSPECT M01AAEMI  REPLACING ALL '_'  BY ' '.                 00527299
      *
           INSPECT M01TIPOI  REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
           INSPECT M01TAGI   REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
           INSPECT M01DIVI   REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
           INSPECT M01NUMBI  REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
           INSPECT M01SERIEI REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
           INSPECT M01DESC1I REPLACING ALL '_'  BY ' '                  00527299
           INSPECT M01DESC2I REPLACING ALL '_'  BY ' '                  00527299
           INSPECT M01DESC3I REPLACING ALL '_'  BY ' '                  00527299
      *                                                                 00534037
           INSPECT M01STATVI REPLACING ALL '_'  BY ' '                  00527299
      *                                                                 00534037
           INSPECT M01STATNI REPLACING ALL '_'  BY ' '.                 00527299
      *                                                                 00534037
       A070-PULISCI-CAMPI-EX.                                           00540099
           EXIT.                                                        00604032
      *-----------------------------------------------------------------00522237
       A080-CTR-DATA-VALIDA.
LM2804*                                                                 00510732
LM2804     EXEC CICS ASKTIME    ABSTIME  (WS-TEMPO)     END-EXEC.       00510732
LM2804*                                                                 00510732
LM2804     EXEC CICS FORMATTIME ABSTIME  (WS-TEMPO)                     00510732
LM2804                          YYYYMMDD (WS-EIB-DATA) END-EXEC.        00510732
LM2804*                                                                 00510732
LM2804     MOVE WS-EIB-DATA                TO WS-EIB-DATA-N.            00510732
POIVIA*    EXEC CICS ENTER TRACEID(01) FROM(WS-EIB-DATA-N) END-EXEC.
POIVIA*    EXEC CICS ENTER TRACEID(02) FROM(CA-DATA-EMISS-N) END-EXEC.
LM2804     IF   WS-EIB-DATA-N                 < CA-DATA-EMISS-N         00510732
LM2804          MOVE    -1                 TO M01GGEML                  00527299
LM2804          MOVE    SPACES             TO M01MESSO                  00527299
LM2804          MOVE    MSG-ERRDATA-EMISS  TO M01MESSO                  00527299
LM2804          PERFORM A030-PREPARA-MAPPA
LM2804             THRU A030-PREPARA-MAPPA-EX
LM2804          PERFORM A040-INVIA-MAPPA                                00524299
LM2804             THRU A040-INVIA-MAPPA-EX                             00524299
LM2804     END-IF.                                                      00510732
LM2804*                                                                 00510732
           MOVE CA-DATA-EMISS-N            TO UTDATA-DATA-1.
           MOVE 0                          TO UTDATA-FUNZIONE.
      *
           EXEC CICS LINK PROGRAM  (XSXDAT)
                          COMMAREA (UTDATA-PARAM)
           END-EXEC.
      *
           IF   UTDATA-ERRORE             NOT = ZEROES
                MOVE    -1                 TO M01GGEML                  00527299
                MOVE    SPACES             TO M01MESSO                  00527299
                MOVE    MSG-ERRDATA        TO M01MESSO                  00527299
                PERFORM A030-PREPARA-MAPPA
                   THRU A030-PREPARA-MAPPA-EX
                PERFORM A040-INVIA-MAPPA                                00524299
                   THRU A040-INVIA-MAPPA-EX                             00524299
           END-IF.
      *
       A080-CTR-DATA-VALIDA-EX.
           EXIT.
      *----------------------------------------------------------------*
       A090-PREPARA-LINK.                                               00530499
      *
           MOVE    'BP'                  TO     W013-SOTTOSISTEMA-IN.   00524299
           MOVE    EIBTRNID              TO     W013-TRANSAZIONE-IN.    00524299
           MOVE    BPFCX002              TO     W013-NOME-MOD-RICH-IN.  00524299
           COMPUTE W013-LUNG-AREA-DATI-IN =                             00524299
                   20 + LENGTH OF BPFCW029-INPUT                        00524299
           MOVE    '1'                   TO     W013-VERS-APPL-DIP-IN.  00524299
           MOVE    EIBTRNID              TO     W029-TRANS-ID.          00524299
171103*    MOVE    CA-AGE-EMISS          TO     W029-FRAZ-UFF.          00524299
171103     MOVE    CA-FRAZ-IMM           TO     W029-FRAZ-UFF.          00524299
           PERFORM A110-RICAVA-DATA      THRU   A110-RICAVA-DATA-EX.    00524299
           MOVE    WS-DATA-CONT-N        TO     W029-DATA-CONT-N.       00524299
           MOVE    ZEROES                TO     W029-NUM-SEZ.           00524299
           MOVE    ZEROES                TO     W029-NUM-OPE.           00524299
           MOVE    '000'                 TO     W029-COD-REL.           00524299
           MOVE    CA-DIVISA             TO     W029-DIVI-BUONO.        00524299
           MOVE    CA-TIPO-BUONO         TO     W029-TIPO-BUONO.        00524299
           MOVE    CA-TAGLIO-N           TO     W029-TAGLIO-BUONO.      00524299
           MOVE    CA-NUM-BUONO-N        TO     W029-NUM-BUONO.         00524299
           MOVE    CA-SERIE              TO     W029-SERIE-BUONO.       00524299
           MOVE    CA-AGE-EMISS          TO     W029-FRAZ-EMIS.         00524299
           MOVE    CA-DATA-EMISS-N       TO     W029-DATA-EMIS-N.       00524299
           MOVE    CA-NEW-STATO          TO     W029-NEW-STATO.         00524299
           MOVE    CA-NOTE               TO     W029-NOTA-VARIAZ.       00524299
LM1311     MOVE    CA-USERID             TO     W029-USERID.            00524299
LM1311     MOVE    CA-PROFILO            TO     W029-PROFILO.           00524299
           MOVE    SPACES                TO     W029-FRAZ-ANNULLO.      00524299
           MOVE    ZEROES                TO     W029-DT-CONT-ANNULLO.   00524299
           MOVE    'N'                   TO     W029-FLAG-ANNULLO.      00524299
           MOVE    EIBTRMID              TO     W029-TERMINALE-ANNULLO. 00524299
      *
       A090-PREPARA-LINK-EX.                                            00540099
           EXIT.                                                        00604032
      *-----------------------------------------------------------------00522237
       A100-CTR-UTENTE.                                                 00849099

           INITIALIZE                           SIPRACF-AREA.

           EXEC CICS LINK PROGRAM  (SIPRACF)
                          COMMAREA (SIPRACF-AREA)
                          LENGTH   (LENGTH OF SIPRACF-AREA)
           END-EXEC.

           IF      SIPRACF-ESITO         NOT =  ZEROES
SF0801*       MOVE    SPACES                     TO WS-AREA-MSG
SF0801*       MOVE    'TERMINALE NON ABILITATO'  TO WS-AREA-MSG
SF0801        MOVE    'TERMINALE NON ABILITATO'  TO COM-MSG-48
SF0801*       PERFORM X010-SEND-MSG            THRU X010-SEND-MSG-EX
SF0801*       PERFORM X020-RETURN-CICS         THRU X020-RETURN-CICS-EX
SF0801        PERFORM X020-XCTL-MENU           THRU X020-XCTL-MENU-EX
           END-IF.
      *
           IF      SIPRACF-PROFILO = LOW-VALUE OR SPACES
SF0801*       MOVE    SPACES                     TO WS-AREA-MSG
SF0801*       MOVE    'ERRORE ROUTINE SIPCOAC PER RICERCA PROFILO'
SF0801*                                          TO WS-AREA-MSG
SF0801        MOVE    'ERRORE ROUTINE SIPCOAC PER RICERCA PROFILO'
SF0801                                           TO COM-MSG-48
SF0801*       PERFORM X010-SEND-MSG            THRU X010-SEND-MSG-EX
SF0801*       PERFORM X020-RETURN-CICS         THRU X020-RETURN-CICS-EX
SF0801        PERFORM X020-XCTL-MENU           THRU X020-XCTL-MENU-EX
           END-IF.

           INITIALIZE     CAXC10
      *
LM1311     MOVE SIPRACF-USERID              TO CA-USERID
171103     MOVE SIPRACF-DIP-LIV-FISICO-TERM TO CA-FRAZ-IMM
           MOVE '00000'                     TO CAXC10-CDBAN0-BANCA
           MOVE SPACES                      TO CAXC10-FLATG0-SOLO-TG07
           MOVE 'SIC'                       TO CAXC10-CDMOR0-MOD-ORG
           MOVE 'BP'                        TO CAXC10-XAREA-AREA-APPL
           MOVE SIPRACF-PROFILO             TO CAXC10-XPROUT-PROFILO
LM1311     MOVE SIPRACF-PROFILO             TO CA-PROFILO
221002*    MOVE TRND3270                    TO CAXC10-XNODEO-NOME-MAPPA
221002     MOVE BPX015                      TO CAXC10-XNODEO-NOME-MAPPA

           EXEC CICS LINK PROGRAM ('CAXC10')
                          COMMAREA(CAXC10)
                          LENGTH  (LENGTH  OF  CAXC10)
           END-EXEC.


           IF         CAXC10-CDRET2-COD-RITORNO NOT = '00'
SF0801*       MOVE    SPACES                     TO WS-AREA-MSG
SF0801*       MOVE    CAXC10-XDIAGN-DIAGNOSTICO  TO WS-AREA-MSG
SF0801        MOVE    CAXC10-XDIAGN-DIAGNOSTICO  TO COM-MSG-48
SF0801*       PERFORM X010-SEND-MSG            THRU X010-SEND-MSG-EX
SF0801*       PERFORM X020-RETURN-CICS         THRU X020-RETURN-CICS-EX
SF0801        PERFORM X020-XCTL-MENU           THRU X020-XCTL-MENU-EX
           END-IF.

       A100-CTR-UTENTE-EX.                                              00853599
           EXIT.                                                        00853699
      *-----------------------------------------------------------------00522237
       A110-RICAVA-DATA.                                                00842299
      *                                                                 00842399
           EXEC CICS ASKTIME
                     ABSTIME    (WS-TEMPO)
           END-EXEC.
      *                                                                 00842399
           EXEC CICS FORMATTIME
                     ABSTIME    (WS-TEMPO)
                     YYYYMMDD   (WS-DATA-CONT)
           END-EXEC.
      *                                                                 00527599
       A110-RICAVA-DATA-EX.                                             00843499
           EXIT.                                                        00843599
      *-----------------------------------------------------------------00522237
       A120-LINK-BPFCX002.                                              01389700
      *                                                                 01389700
           MOVE       AREAW029            TO    W013-AREA-DATI-IN.      01389700
      *                                                                 01389700
           EXEC CICS LINK PROGRAM  (BPFCX002)                           01389700
                          COMMAREA (BPFCW013)                           01389700
                          LENGTH   (LENGTH OF BPFCW013)                 01389700
                          RESP     (WS-RESP)                            01389700
           END-EXEC.                                                    01389700
      *                                                                 01389700
           IF         WS-RESP              NOT  = DFHRESP(NORMAL)       01389700
111203        PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX
              MOVE    -1                   TO   M01AGENL                00527299
              MOVE    SPACES               TO   M01MESSO                00527299
              MOVE    MSG-ERR-X002         TO   M01MESSO                01389700
              PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX
              PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
           END-IF.                                                      01389700
      *                                                                 01389700
           MOVE       W013-AREA-DATI-OUT   TO   BPFCW029-OUTPUT.        01389700
      *                                                                 01389700
           IF         W013-COD-ERR-OUT          = WS-ERR-INTE           01389700
              PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX
              MOVE    -1                   TO   M01AGENL                00527299
              MOVE    W029-DESC-OUT        TO   WS-DESC-MSG-X002        01389700
              MOVE    SPACES               TO   M01MESSO                00527299
              MOVE    WS-DESC-MSG-X002     TO   M01MESSO                01389700
LM1511        IF      CA-OLD-STATO         >    SPACES
LM1511                MOVE    CA-OLD-STATO TO   M01STATVI               00527299
LM1511                INITIALIZE                AREAW043                00527299
LM1511                MOVE    CA-OLD-STATO TO W043-STATO-IN             00527299
LM1511                MOVE    'V'          TO CA-STATO                  00527299
LM1511                PERFORM A200-LINK-BPFCM043
LM1511                   THRU A200-LINK-BPFCM043-EX
LM1511        END-IF
              PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX
              PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
           END-IF.                                                      01389700
      *                                                                 01389700
           IF         W013-COD-ERR-OUT          = WS-OK-INTE            01389700
              MOVE    -1                   TO   M01DESC1L               00527299
              MOVE    W029-OLD-STATO       TO   M01STATVI               01389700
              MOVE    W029-OLD-STATO       TO   CA-OLD-STATO            01389700
              IF      W029-NEW-STATO            > SPACES
                      MOVE 1               TO   CA-PRIMO-GIRO           00527299
              ELSE
                      MOVE ZEROES          TO   CA-PRIMO-GIRO           00527299
              END-IF
              IF      CA-PRIMO-GIRO             = 1
                      MOVE -1              TO   M01AGENL                00527299
                      MOVE SPACES          TO   M01MESSO                00527299
                      MOVE MSG-TUTTO-OK    TO   M01MESSO                01389700
                      MOVE 2               TO   CA-PRIMO-GIRO           01389700
              ELSE
                      MOVE SPACES          TO   M01MESSO                00527299
                      MOVE MSG-ISRT-NS     TO   M01MESSO                00527299
              END-IF
LM1511        MOVE    CA-OLD-STATO         TO   M01STATVI               00527299
LM1511                INITIALIZE                AREAW043                00527299
LM1511        MOVE    CA-OLD-STATO         TO   W043-STATO-IN           00527299
LM1511        MOVE    'V'                  TO   CA-STATO                00527299
LM1511        PERFORM A200-LINK-BPFCM043   THRU A200-LINK-BPFCM043-EX
181103        IF      CA-PRIMO-GIRO             = 2
LM1511                INITIALIZE                AREAW043                00527299
181103                MOVE    CA-NEW-STATO TO   W043-STATO-IN           00527299
181103                MOVE    'N'          TO   CA-STATO                00527299
181103                PERFORM A200-LINK-BPFCM043
181103                   THRU A200-LINK-BPFCM043-EX
              END-IF
              PERFORM A160-PROTEGGI-MAPPA  THRU A160-PROTEGGI-MAPPA-EX
              PERFORM A140-CARICA-MAPPA    THRU A140-CARICA-MAPPA-EX
              PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX
           END-IF.                                                      01389700
      *                                                                 01389700
       A120-LINK-BPFCX002-EX.                                           01389700
           EXIT.                                                        01389700
LM1511*-----------------------------------------------------------------00522237
LM1511 A200-LINK-BPFCM043.                                              01389700
LM1511*                                                                 01389700
LM1511     EXEC CICS LINK PROGRAM  (BPFCM043)                           01389700
LM1511                    COMMAREA (AREAW043)                           01389700
LM1511                    LENGTH   (LENGTH OF AREAW043)                 01389700
LM1511                    RESP     (WS-RESP)                            01389700
LM1511     END-EXEC.                                                    01389700
LM1511*                                                                 01389700
LM1511     IF         WS-RESP              NOT  = DFHRESP(NORMAL)       01389700
111203        PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX 00522237
LM1511        MOVE    -1                   TO   M01AGENL                00527299
LM1511        MOVE    SPACES               TO   M01MESSO                00527299
LM1511        MOVE    MSG-ERR-M043         TO   M01MESSO                01389700
LM1511        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX   00522237
LM1511        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
LM1511     END-IF.                                                      01389700
LM1511*                                                                 01389700
LM1511     IF         W043-ESITO-OUT       NOT  = SPACES                01389700
LM1511        PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX 00522237
LM1511        IF      CA-STATO                  = 'V'                   00522237
LM1511                MOVE    -1           TO   M01DESCVL               00527299
LM1511        END-IF                                                    00522237
LM1511        IF      CA-STATO                  = 'N'                   00522237
LM1511                MOVE    -1           TO   M01DESCNL               00527299
LM1511        END-IF                                                    00522237
LM1511        MOVE    W043-DESC-OUT        TO   WS-DESC-MSG-X002        01389700
LM1511        MOVE    SPACES               TO   M01MESSO                00527299
LM1511        MOVE    WS-DESC-MSG-X002     TO   M01MESSO                01389700
LM1511        IF      CA-OLD-STATO         >    SPACES                  00522237
LM1511                MOVE CA-OLD-STATO         TO   M01STATVI          00527299
LM1511        END-IF                                                    00522237
LM1511        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX   00522237
LM1511        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
LM1511     END-IF.                                                      01389700
LM1511*                                                                 01389700
LM1511     IF         W043-ESITO-OUT               = SPACES             01389700
LM1511        IF      CA-STATO                     = 'V'                01389700
LM1511                MOVE W043-DESC-STATO-OUT  TO CA-DESC-STATO-O      00527299
LM1511        END-IF                                                    01389700
LM1511        IF      CA-STATO                     = 'N'                01389700
LM1511                MOVE W043-DESC-STATO-OUT  TO CA-DESC-STATO-N      00527299
LM1511        END-IF                                                    01389700
LM1511     END-IF.                                                      01389700
LM1511*                                                                 01389700
LM1511 A200-LINK-BPFCM043-EX.                                           01389700
LM1511     EXIT.                                                        01389700
170903*-----------------------------------------------------------------00522237
170903 A110-CTR-AGENZ.                                                  01389700
170903*                                                                 01389700
170903     INITIALIZE                                AREAW026           01389700
170903     MOVE       SIPRACF-DIP-LIV-FISICO-TERM TO W026-AGENZIA-IN    01389700
170903*                                                                 01389700
170903     EXEC CICS LINK PROGRAM  (BPFCM026)                           01389700
170903                    COMMAREA (AREAW026)                           01389700
170903                    LENGTH   (LENGTH OF AREAW026)                 01389700
170903                    RESP     (WS-RESP)                            01389700
170903     END-EXEC.                                                    01389700
170903*                                                                 01389700
170903     IF         WS-RESP              NOT  = DFHRESP(NORMAL)       01389700
170903        MOVE    -1                   TO   M01AGENL                00527299
170903        MOVE    SPACES               TO   M01MESSO                00527299
170903        MOVE    MSG-ERR-M026         TO   M01MESSO                01389700
170903        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX   00522237
170903        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
170903     END-IF.                                                      01389700
170903*                                                                 01389700
170903     IF            W026-ESITO-OUT    NOT  = '00'                  01389700
170903        IF         W026-ESITO-OUT         = '02'                  01389700
170903           MOVE    MSG-ERRDIP        TO   WS-DESC-MSG-X002        01389700
170903           MOVE    SPACES            TO   M01MESSO                00527299
170903           MOVE    WS-DESC-MSG-X002  TO   M01MESSO                01389700
170903           PERFORM A160-PROTEGGI-MAPPA                            00527299
170903              THRU A160-PROTEGGI-MAPPA-EX                         00527299
170903           MOVE    ATTR-PROT-FSET TO M01DESC1A                    00527299
170903           MOVE    ATTR-PROT-FSET TO M01DESC2A                    00527299
170903           MOVE    ATTR-PROT-FSET TO M01DESC3A                    00527299
170903           MOVE    ATTR-PROT-FSET TO M01STATNA                    00527299
170903        ELSE
170903           MOVE    W026-DESC-OUT     TO   WS-DESC-MSG-X002        01389700
170903           MOVE    SPACES            TO   M01MESSO                00527299
170903           MOVE    WS-DESC-MSG-X002  TO   M01MESSO                01389700
170903        END-IF
170903        MOVE    'X'                  TO   CA-BLOCCA               00527299
170903        MOVE    -1                   TO   M01AGENL                00527299
170903        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX   00522237
170903        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
170903     END-IF.                                                      01389700
170903*                                                                 01389700
170903 A110-CTR-AGENZ-EX.                                               01389700
170903     EXIT.                                                        01389700
      *-----------------------------------------------------------------00522237
       A140-CARICA-MAPPA.                                               01389700
      *                                                                 01389700
           MOVE    CA-AGE-EMISS            TO   M01AGENI.               00524299
           MOVE    CA-GG                   TO   M01GGEMI.               00524299
           MOVE    CA-MM                   TO   M01MMEMI                00524299
           MOVE    CA-AAAA                 TO   M01AAEMI.               00524299
           MOVE    CA-TIPO-BUONO           TO   M01TIPOI.               00524299
           MOVE    CA-TAGLIO-X             TO   M01TAGI.                00524299
           IF      CA-DIVISA               =    'E'                     00524299
                   MOVE 'EUR'              TO   M01DIVI                 00524299
           ELSE                                                         00524299
                   MOVE 'ITL'              TO   M01DIVI                 00524299
           END-IF.                                                      00524299
           MOVE    CA-NUM-BUONO-X          TO   M01NUMBI.               00524299
           MOVE    CA-SERIE                TO   M01SERIEI.              00524299
           MOVE    CA-NOTE1                TO   M01DESC1I.              00524299
           MOVE    CA-NOTE2                TO   M01DESC2I.              00524299
           MOVE    CA-NOTE3                TO   M01DESC3I.              00524299
           MOVE    CA-OLD-STATO            TO   M01STATVI.              00524299
           MOVE    CA-NEW-STATO            TO   M01STATNI.              00524299
LM1511     MOVE    CA-DESC-STATO-O         TO   M01DESCVI.              00527299
LM1511     MOVE    CA-DESC-STATO-N         TO   M01DESCNI.              00527299
      *                                                                 01389700
       A140-CARICA-MAPPA-EX.                                            01389700
           EXIT.                                                        01389700
      *-----------------------------------------------------------------00522237
       A160-PROTEGGI-MAPPA.                                             00530499
      *
           MOVE ATTR-PROT-FSET TO M01AGENA.                             00527299
           MOVE ATTR-PROT-FSET TO M01GGEMA.                             00527299
           MOVE ATTR-PROT-FSET TO M01MMEMA.                             00527299
           MOVE ATTR-PROT-FSET TO M01AAEMA.                             00527299
           MOVE ATTR-PROT-FSET TO M01TIPOA.                             00527299
           MOVE ATTR-PROT-FSET TO M01TAGA.                              00527299
           MOVE ATTR-PROT-FSET TO M01DIVA.                              00527299
           MOVE ATTR-PROT-FSET TO M01NUMBA.                             00527299
           MOVE ATTR-PROT-FSET TO M01SERIEA.                            00527299
           IF      CA-PRIMO-GIRO             NOT = ZEROES
                MOVE ATTR-PROT-FSET TO M01DESC1A                        00527299
                MOVE ATTR-PROT-FSET TO M01DESC2A                        00527299
                MOVE ATTR-PROT-FSET TO M01DESC3A                        00527299
                MOVE ATTR-PROT-FSET TO M01STATNA                        00527299
           END-IF.
           MOVE ATTR-PROT-FSET TO M01STATVA.                            00527299
      *                                                                 00534037
       A160-PROTEGGI-MAPPA-EX.                                          00540099
           EXIT.                                                        00604032
      *-----------------------------------------------------------------00522237
       A130-ESEGUI-ROLLBACK.                                            01389700
      *                                                                 01389700
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC.
      *                                                                 01389700
       A130-ESEGUI-ROLLBACK-EX.                                         01389700
           EXIT.                                                        01389700
      *----------------------------------------------------------------*01389700
       X010-SEND-MSG.                                                   00854899
      *                                                                 00854999
           EXEC CICS SEND TEXT FROM  (WS-AREA-MSG)                      00855099
                               LENGTH(WS-LUNG-MSG)                      00855199
                               ERASE                                    00855299
                               FREEKB                                   00855399
           END-EXEC.                                                    00855499
      *                                                                 00855599
       X010-SEND-MSG-EX.                                                00855699
           EXIT.                                                        00855799
      *-----------------------------------------------------------------00522237
       X020-RETURN-CICS.                                                00857599
                                                                        00857699
           EXEC CICS RETURN END-EXEC.                                   00857899
                                                                        00858099
       X020-RETURN-CICS-EX.                                             00858199
           EXIT.                                                        00855799
      *-----------------------------------------------------------------00522237
SF0801 X020-XCTL-MENU.                                                  00857599
                                                                        00857699
           MOVE 0                           TO  COM-SWP-48.             00030525
                                                                        00140023
           EXEC CICS XCTL PROGRAM   ('BPFCX048')                        00140123
                           COMMAREA (AREA-COMMAREA-48)                  00024024
                           LENGTH   (LENGTH OF AREA-COMMAREA-48)        00024124
           END-EXEC.                                                    00140123
                                                                        00858099
       X020-XCTL-MENU-EX.                                               00858199
           EXIT.                                                        00855799
      *-----------------------------------------------------------------00522237
       X030-FINE.                                                       00856299
      *                                                                 00856399
           MOVE    MSG-FINETRA           TO    WS-AREA-MSG.             00524099
           PERFORM X010-SEND-MSG         THRU  X010-SEND-MSG-EX.        00524199
           PERFORM X020-RETURN-CICS      THRU  X020-RETURN-CICS-EX.     00524199
      *                                                                 00856899
       X030-FINE-EX.                                                    00856999
           EXIT.                                                        00857099
LM2804*----------------------------------------------------------------*00051100
LM2804 L080-LINK-BPFCX156.                                              00059130
LM2804*                                                                 00060900
LM2804     INITIALIZE                           AREAW031.               00061000
LM2804*                                                                 00060900
LM2804     MOVE  CA-AGE-EMISS(1:2)      TO W031-PROV-EMI-IN.            00061100
LM2804     MOVE  CA-AGE-EMISS(3:3)      TO W031-UFF-EMI-IN.             00061100
LM2804     MOVE  CA-AAAA                TO WS-AAAA.                     00051700
LM2804     MOVE  CA-MM                  TO WS-MM.                       00051800
LM2804     MOVE  CA-GG                  TO WS-GG.                       00051900
LM2804     MOVE  WS-DATA-DA10           TO W031-DATA-EMI-IN.            00052000
LM2804     MOVE  CA-TIPO-BUONO          TO W031-TIPOLOGIA-IN.           00061100
LM2804     MOVE  CA-TAGLIO-N            TO W031-TAGLIO-IN.              00061100
LM2804     MOVE  'ITL'                  TO W031-DIVISA-IN.              00061100
LM2804     MOVE  CA-NUM-BUONO-N         TO W031-NUM-BUONO-IN.           00061100
LM2804     MOVE  CA-FRAZ-IMM            TO W031-UNIT-IMM-IN.
LM2804     MOVE  'BPFCX015'             TO W031-UTENTE-IMM-IN.          00124600
LM2804     MOVE  EIBTRMID               TO W031-TERM-IMM-IN.            00124700
LM2804*                                                                 00061200
LM2804     EXEC CICS LINK PROGRAM  (BPFCX156)                           00052600
LM2804                    COMMAREA (AREAW031)                           00061400
LM2804                    LENGTH   (LENGTH OF AREAW031)                 00061500
LM2804                    RESP     (WS-RESP)                            00061600
LM2804     END-EXEC.                                                    00061700
LM2804*                                                                 00061800
LM2804     IF         WS-RESP              NOT  = DFHRESP(NORMAL)       01389700
LM2804        PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX
LM2804        MOVE    -1                   TO   M01AGENL                00527299
LM2804        MOVE    SPACES               TO   M01MESSO                00527299
LM2804        MOVE    MSG-ERR-X156         TO   M01MESSO                01389700
LM2804        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX
LM2804        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
LM2804     END-IF.                                                      01389700
LM2804*                                                                 01389700
LM2804     IF         W031-ESITO-OUT       NOT  = '00'                  00062700
LM2804        PERFORM A130-ESEGUI-ROLLBACK THRU A130-ESEGUI-ROLLBACK-EX 00522237
LM2804        MOVE    -1                   TO   M01AGENL                00524099
LM2804        MOVE    ATTR-PROT-FSET       TO   M01AGENA                00062910
LM2804        MOVE    W031-DESC-OUT        TO   WS-DESC-MSG-X002        01389700
LM2804        MOVE    SPACES               TO   M01MESSO                00527299
LM2804        MOVE    WS-DESC-MSG-X002     TO   M01MESSO                01389700
LM2804        PERFORM A030-PREPARA-MAPPA   THRU A030-PREPARA-MAPPA-EX   00522237
LM2804        PERFORM A040-INVIA-MAPPA     THRU A040-INVIA-MAPPA-EX     00524299
LM2804     END-IF.                                                      00063600
      *                                                                 00064000
       L080-LINK-BPFCX156-EX.                                           00059140
           EXIT.                                                        00051000
      *-----------------------------------------------------------------00522237
       X040-MENU.                                                       00856299
      *                                                                 00856399
           EXEC CICS XCTL PROGRAM(BPFCX048) END-EXEC.                   00524099
      *                                                                 00856899
       X040-MENU-EX.                                                    00856999
           EXIT.                                                        00857099
      *-----------------------------------------------------------------00522237
       H010-ATTIVA-HELP.                                                01389700
      *                                                                 01389700
           MOVE       'BPFCX015'          TO    HELP-PGM-CHIAMANTE.     01389700
           MOVE       TRND3270            TO    HELP-TRND-CHIAMANTE.    01389700
           MOVE       M01STATVI           TO    HELP-STATO-DA.          01389700
LM1311*    MOVE       3270X002            TO    HELP-PGM-ACCESSO.       01389700
LM1311     MOVE       CA-PROFILO          TO    HELP-PGM-ACCESSO.       00524299
      *                                                                 01389700
           EXEC CICS XCTL PROGRAM  (BPFCX049)                           01389700
                          COMMAREA (AREA-COMMAREA)                      01389700
                          LENGTH   (LENGTH OF AREA-COMMAREA)            01389700
           END-EXEC.                                                    01389700
      *                                                                 01389700
       H010-ATTIVA-HELP-EX.                                             01389700
           EXIT.                                                        01389700
      ****************************************************************  00858499
      *          E  N  D        O  F        P  R  O  G  R  A  M      *  00859099
      ****************************************************************  00860082
