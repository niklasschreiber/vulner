      ******************************************************************00000100
      * IL PROGRAMMA ARRAB000 (INVIO FILES DI RICHIESTA E DI VARIAZIONE 00000200
      *    DATI DI SCOPERTO ALL'ENTE GARANTE)                           00000300
      *                                                                 00000400
      * - LEGGE I RECORD RICHIESTE DALLA TABELLA TRIC E                 00000500
      *   LI SCRIVE SUI CORRISPETTIVI FILES DA INVIARE A D.BANK.        00000600
      * - AGGIORNA LA TABELLA TRIC (STATO RICH. DATA INVIO)             00000700
      * - LEGGE ED AGGIORNA LA TABELLA TTAP CONTENENTE PROGRESSIVO      00000800
      *   FLUSSO E N.REC. INVIATI                                       00000900
      ******************************************************************00001000
      * 241000 ===> MODIFICA SULLA ROUTINE DI SCRITTURA DEL FLUSSO DELLE00001100
      *             VARIAZIONI NON ANAGRAFICHE:                         00001200
      *           - VALORIZZAZIONE DEL CAMPO NATURA GIURIDICA PER I RE- 00001300
      *             CORD 'R3'                                           00001400
      *           - INIZIALIZZATI I CAMPI ACCR-STIP,IMP-STIP,DIV-STIP,  00001500
      *             SETT-PROD E COD-AFF PER I RECORD 'R3'               00001600
      * 251000 ===> MODIFICA SULLA VALORIZZAZIONE DEL TIPO RECORD PER I 00001700
      *             RECORD DI TESTA                                     00001800
      * 071100 ===> MODIFICA SULLA VALORIZZAZIONE DEL COMUNE DI RESIDENZ00001900
      *             A IN OUTPUT.VIENE PASSATO 'CITTA'' DEL VATICANO' E  00002000
      *             NON PIU' 'STATO DEL VATICANO'.                      00002100
      * 141100 ===> INSERITO CONTROLLO SU SCRITTURA DEL FILE DELLE VARIA00002200
      *             ZIONI DI SCOPERTO.SE IL TIPO ATTIVITA' DELLA RICHIES00002300
      *             TA RISULTA ESSERE 'V1' IL TIPO RECORD DEL FILE DOVRA00002400
      *             ESSERE VALORIZZATO CON '03'                         00002500
      * 151100 ===> MODIFICA PER LA VALORIZZAZIONE DEI CAMPI DI OUTPUT  00002600
      *             DEL COMUNE DI NASCITA , DI RILASCIO DOCUMENTO E ABI-00002700
      *             TAZIONE PRECEDENTE                                  00002800
      * 231100 ===> MODIFICA PER LA VALORIZZAZIONE DEL CAMPI DI OUTPUT  00002900
      *             ARRAC005-NUOVO-RAE.IL CAMPO E' VALORIZZATO FISSO CON00003000
      *             IL VALORE 00000.                                    00003100
      * 111200 ===> AGGIUNTA VALORIZZAZIONE PER SESSO,PROVINCIA,COMUNE E00003200
      *             NAZIONE DI NASCITA SUL FILE DELLE VARIAZIONI ANAGRAF00003300
      *             ICHE.                                               00003400
      * 151200 ===> AGGIUNTA VALORIZZAZIONE PER DATA DI NASCITA         00003500
      *             SUL FILE DELLE VARIAZIONI ANAGRAFICHE.              00003600
      * 221200 ===> AGGIUNTA RICERCA PER RAPPORTI CHE PRESENTANO LA     00003700
      *             DATA DI RISPOSTA ENTE INFERIORE DI 20 GIORNI        00003800
      *             RISPETTO ALLA DATA DI SISTEMA E CODICE ANOMALIA     00003900
      *             '940' (CONTO BLOCCATO).IN CASO DI RICERCA           00004000
      *             ANDATA A BUON FINE , SI AGGIORNA IL RECORD SULLA    00004100
      *             TABELLA SCTBTRIC CON UN TIPO ATTIVITA' 'E3'.        00004200
      *             IL RAPPORTO VIENE INOLTRE REINVIATO A DEUTSCHE      00004300
      *             BANK PER ESSERE ESTINTO.                            00004400
      * 050201 ===> MODIFICA SULLA VALORIZZAZIONE DEL COMUNE DI NASCITA 00004500
      *             SUL FILE DELLE VARIAZIONUI ANAGRAFICHE.VIENE INVIATO00004600
      *             'CITTA' DEL VATICANO' E NON 'STATO DEL VATICANO'.   00004700
      *             AGGIUNTO CONTROLLO SU SCRITTURA DEI RECORD 'R3' E   00004800
      *             'E3' PER FAR SI CHE VENGA SCRITTO SOLAMENTE IL RECOR00004900
      *             D DI COI.                                           00005000
      * 040501 ===> AGGIUNTO CONTROLLO IN FASE DI SCRITTURA DEL FILE DEL00005100
      *             LE RICHIESTE E DEL FILE DELLE VARIAZIONI DI SCOPERTO00005200
      *             PER PASSARE A ZERO L'IMPORTO STIPENDIO PER QUEI RAPP00005300
      *             ORTI CHE PRESENTANO ACCREDITO NEGATIVO.             00005400
      * 060602 ===> AGGIUNTO AL CONTATORE DELLE VARIAZIONI DI TIPO      00005500
      *             NON ANAGRAFICO IL CONTEGGIO DEL RECORD TAPPO        00005600
      *             SCRITTO IL ( W-CTR-V1 )                             00005700
      * 210602 ===> VALORIZZATA PROVINCIA E CAP.                        00005800
      * 050702 ===> MODIFICA PER SOSTITUIRE TUTTI I '-' PRESENTI SULLE  00005900
      *             INTESTAZIONI RIDOTTE PROVENIENTI DA ANAGRAFE CON    00006000
      *             GLI SPAZI.                                          00006100
      * 281102 ===> AGGIUNTA GESTIONE DELLA TABELLA DB2 SCTBTINV (INVII 00006200
      *             ALL'ENTE CON USERID E FILIALE RICHIEDENTE).         00006300
      * 291102 ===> IN CASO DI CODICE NAZIONE 800 VIENE VALORIZZATA LA  00006400
      *             LOCALITA' DI RESIDENZA NEI FILES AFFIDA E VARIANG   00006500
      *             CON "REPUBBLICA DI SAN MARINO".                     00006600
      * 050603 ===> MODIFICATI CODICI DOCUMENTI PER DEUTSCHE BANK       00006700
      * 120603 ===> MODIFICATA, IN FASE DI SCRITTURA DEI FILE, LA VALO- 00006800
      *             RIZZAZIONE DELLE PROVINCIE "FO" E "PS" RISPETTIVA-  00006900
      *             MENTE IN "FC" E "PU".                               00007000
      * 250603 ===> MODIFICATA RELATIVA AD UN NUOVO SETTORE PRODUTTIVO  00007100
      *             PREVISTO IN ANAGRAFE GENERALE IDENTIFICABILE NELLA  00007200
      *             TABELLA SCTBTSET (IMPLEMENTATA DI NUOVI CAMPI) AT-  00007300
      *             TRAVERSO IL "CIAE".                                 00007400
      * 260603 ===> MODIFICATA, IN FASE DI SCRITTURA DEL FILE VARIASCC, 00007500
      *             LA VALORIZZAZIONE DEL CAMPO RELATIVO ALLA DATA DI   00007600
      *             REVOCA CON LA DATA DI DECORRENZA DELLA VARIAZIONE   00007700
      *             DEL CODICE SETTORE PRODUTTIVO (SOLO PER I "V1").    00007800
----->* 030703 ===> QUESTA MODIFICA DOVRA' ESSERE TOLTA QUANDO DB SARA' 00007810
----->*             PRONTA A RICEVERE IL SETTORE PRODUTTIVO ANCHE SUL   00007820
----->*             REC. DI COINTESTAZIONE                              00007830
----->* 011003 ===> RIPRISTINATO TIPO DOCUMENTO 'CIE'                  *00007840
----->* 161203 ===> VALORIZZATO IL COMUNE DI RILASCIO DOCUMENTO PER    *00007850
----->*             SAN MARINO                                         *00007860
----->* 260405 ===> MODIFICA PER FORZATURA SU CODICE NAZIONE           *00007870
----->* 010905 ===> EVITATA IN CASO DI V2 LA VALORIZZAZIONE A SPAZIO   *00007880
----->*             DEL COMUNE DI RILASCIO DOC PER LA REPUBBLICA DI    *00007890
----->*             SAN MARINO                                         *00007891
----->* 310510 ===> PER DETERMINARE IL CODICE PRODOTTO VINE EFFETUATA  *00007892
----->*             UNA CHIAMATA A CONDIZIONI                          *00007893
      ******************************************************************00007900
                                                                        00008000
       IDENTIFICATION DIVISION.                                         00008100
                                                                        00008200
       PROGRAM-ID.   ARRAB000                                           00008300
       AUTHOR. ZENO.                                                    00008400
                                                                        00008500
       ENVIRONMENT DIVISION.                                            00008600
                                                                        00008700
       CONFIGURATION SECTION.                                           00008800
                                                                        00008900
          SPECIAL-NAMES.                                                00009000
              DECIMAL-POINT IS COMMA.                                   00009100
                                                                        00009200
       INPUT-OUTPUT SECTION.                                            00009300
                                                                        00009400
       FILE-CONTROL.                                                    00009500
                                                                        00009600
           SELECT  AFFIDA  ASSIGN  TO AFFIDA                            00009700
                 FILE  STATUS  IS  W-STATO1.                            00009800
                                                                        00009900
           SELECT  VARIANG  ASSIGN TO VARIANG                           00010000
                 FILE  STATUS  IS  W-STATO2.                            00010100
                                                                        00010200
           SELECT  VARIASCC   ASSIGN  TO VARIASCC                       00010300
                 FILE  STATUS  IS  W-STATO3.                            00010400
                                                                        00010500
       DATA DIVISION.                                                   00010600
                                                                        00010700
       FILE SECTION.                                                    00010800
                                                                        00010900
       FD  AFFIDA                                                       00011000
           LABEL RECORD STANDARD                                        00011100
           RECORDING MODE IS F                                          00011200
           BLOCK CONTAINS 0 RECORDS.                                    00011300
       01  REC-AFFIDA             PIC X(545).                           00011400
                                                                        00011500
       FD  VARIANG                                                      00011600
           LABEL RECORD STANDARD                                        00011700
           RECORDING MODE IS F                                          00011800
           BLOCK CONTAINS 0 RECORDS.                                    00011900
       01  REC-VARIANG            PIC X(383).                           00012000
                                                                        00012100
       FD  VARIASCC                                                     00012200
           LABEL RECORD STANDARD                                        00012300
           RECORDING MODE IS F                                          00012400
           BLOCK CONTAINS 0 RECORDS.                                    00012500
       01  REC-VARIASCC           PIC X(084).                           00012600
                                                                        00012700
                                                                        00012800
       WORKING-STORAGE SECTION.                                         00012900
                                                                        00013000
       COPY ARRAC005.                                                   00013100
                                                                        00013200
       COPY ARRAC006.                                                   00013300
                                                                        00013400
       COPY ARRAC008.                                                   00013500
                                                                        00013600
       01  ACS108-AREA.                                                 00013700
           COPY ACS108A.                                                00013800
                                                                        00013900
       COPY DYNACALL.                                                   00014000
      ***************************************************************** 00014100
      *    COPY DI WORKING PER LA ROUTINE GENERALIZZATA DI CONTROLLO  * 00014200
      *    DATA                                                       * 00014300
      ***************************************************************** 00014400
           COPY XSADAT.                                                 00014500
                                                                        00014600
      *-----------------------------------------------------------------00014610
      *COPY CONDIZIONI.                                                 00014620
      *-----------------------------------------------------------------00014630
                                                                        00014640
       01  W-C6AP01AS.                                                  00014650
       COPY C6AP01AS.                                                   00014660
                                                                        00014670
      *-----------------------------------------------------------------00014680
                                                                        00014690
       01  NUMERO-CONTO             PIC S9(12)V.                        00014691
                                                                        00014692
       01  NUMERO-NO-COMP           PIC S9(12).                         00014693
                                                                        00014694
       01 STRINGA-CONDIZIONI.                                           00014695
          05 W-SERVIZIO-RAPPORTO    PIC X(03).                          00014696
          05 W-CATEGORIA-RAPPORTO   PIC X(04).                          00014697
          05 W-FILIALE-RAPPORTO     PIC X(05).                          00014698
          05 W-NUMERO-RAPPORTO      PIC X(12).                          00014699
          05 W-FILLER               PIC X(36) VALUE SPACES.             00014700
                                                                        00014701
       01  WS-DATA-ODIERNA.                                             00014702
           02 WS-AA                 PIC 99.                             00014703
           02 WS-MM                 PIC 99.                             00014704
           02 WS-GG                 PIC 99.                             00014705
                                                                        00014706
       01  W-DATA-ELAB.                                                 00014707
           03  W-DATA-ELAB-AAAA.                                        00014708
               05 W-DATA-ELAB-SS    PIC 9(02) VALUE 20.                 00014709
               05 W-DATA-ELAB-AA    PIC 9(02).                          00014710
           03  W-DATA-ELAB-MM       PIC 9(02).                          00014711
           03  W-DATA-ELAB-GG       PIC 9(02).                          00014712
                                                                        00014713
       01  W-DATA-ELAB-RED     REDEFINES   W-DATA-ELAB  PIC 9(8).       00014714
                                                                        00014715
       01  IND-COND                 PIC 9(3) VALUE ZEROES.              00014716
       01  IND                      PIC 9(3) VALUE 1.                   00014717
       01  DESCRIZIONE              PIC X(30) VALUE SPACES.             00014718
                                                                        00014719
       01 APPO-NRVAL-OUT-S          PIC 9(18).                          00014720
                                                                        00014721
       01 APPO-NRVAL-OUT.                                               00014722
          05 NO-SERVE               PIC 9(16).                          00014723
          05 COD-PRODOTTO           PIC X(02).                          00014724
                                                                        00014725
      *-----------------------------------------------------------------00014726
                                                                        00014727
       01  W-SQLCODE                PIC 999   VALUE ZERO.               00014730
       01  W-SQLCODE1               PIC 999   VALUE ZERO.               00014800
       01  W-SQLCODE2               PIC 999   VALUE ZERO.               00014900
       01  W-SQLCODE3               PIC 999   VALUE ZERO.               00015000
       01  W-SQLCODE4               PIC 999   VALUE ZERO.               00015100
       01  WS-AFF-PROGR-OLD         PIC 9(5)  VALUE ZERO.               00015200
       01  WS-VAR-PROGR-OLD         PIC 9(5)  VALUE ZERO.               00015300
       01  WS-PROGRES               PIC 9(7)  VALUE ZERO.               00015400
       01  WS-ENTE1                 PIC X(30) VALUE SPACES.             00015500
       01  WS-ENTE2                 PIC X(30) VALUE SPACES.             00015600
       01  W-NOME-PGM               PIC X(08) VALUE 'ARRAB000'.         00015700
                                                                        00015800
       01 REC-DATA.                                                     00015900
           02  ANNO                        PIC 9(4).                    00016000
           02  MESE                        PIC 9(2).                    00016100
           02  GIORNO                      PIC 9(2).                    00016200
                                                                        00016300
       01 RED-REC-DATA REDEFINES REC-DATA  PIC 9(08).                   00016400
                                                                        00016500
       01  WS-COMUNE                PIC X(30) VALUE SPACES.             00016600
       01  WS-COMRIL                PIC X(30) VALUE SPACES.             00016700
       01  WS-COMRIL1               PIC X(30) VALUE SPACES.             00016800
       01  WS-LOCNASC               PIC X(30) VALUE SPACES.             00016900
       01  WS-LOCPRE                PIC X(30) VALUE SPACES.             00017000
                                                                        00017100
       01  WS-COD-TNAZ.                                                 00017200
           03 WS-COD1-TNAZ          PIC X(03) VALUE SPACES.             00017300
           03 WS-COD2-TNAZ          PIC X(01) VALUE SPACE.              00017400
                                                                        00017500
       01  WS-CODICE-NAZ            PIC 9(04).                          00017600
      ***************************************************************** 00017700
      * CONTATORI DI LETTURA E SCRITTURA                              * 00017800
      ***************************************************************** 00017900
       01  W-CTR-SCRITTI            PIC 9(15) VALUE ZERO.               00018000
281102 01  W-CTR-SCRITTI-INV        PIC 9(15) VALUE ZERO.               00018100
       01  W-CTR-LETTI              PIC 9(15) VALUE ZERO.               00018200
221200 01  W-CTR-LETTI1             PIC 9(15) VALUE ZERO.               00018300
221200 01  W-CTR-TOT                PIC 9(15) VALUE ZERO.               00018400
       01  W-CTR-RS                 PIC 9(15) VALUE ZERO.               00018500
       01  W-CTR-V2                 PIC 9(15) VALUE ZERO.               00018600
       01  W-CTR-V1                 PIC 9(15) VALUE ZERO.               00018700
       01  W-CTR-A3                 PIC 9(15) VALUE ZERO.               00018800
       01  W-CTR-D3                 PIC 9(15) VALUE ZERO.               00018900
       01  W-CTR-R3                 PIC 9(15) VALUE ZERO.               00019000
       01  W-CTR-V-A-D-R            PIC 9(15) VALUE ZERO.               00019100
       01  W-CTR-E3                 PIC 9(15) VALUE ZERO.               00019200
       01  W-AFF-TTAP-PROGR         PIC 9(15) VALUE ZERO.               00019300
       01  W-VANG-TTAP-PROGR        PIC 9(15) VALUE ZERO.               00019400
       01  W-VSCC-TTAP-PROGR        PIC 9(15) VALUE ZERO.               00019500
       01  W-ERRORE                 PIC X(01) VALUE SPACES.             00019600
       01  IND1                     PIC S9(4) COMP.                     00019700
       01  X-IND1                   PIC S9(4).                          00019800
      ***************************************************************** 00019900
      *  CAMPI DI WORKING PER RECORD TABELLA TRIC                     * 00020000
      ***************************************************************** 00020100
       01 WS-SERVIZIO              PIC X(03) VALUE SPACES.              00020200
       01 WS-CATEGORIA             PIC X(04) VALUE SPACES.              00020300
       01 WS-FILIALE               PIC X(05) VALUE SPACES.              00020400
       01 WS-NUMERO                PIC S9(12) COMP-3 VALUE ZEROES.      00020500
       01 WS-NDG-PF                PIC X(12) VALUE SPACES.              00020600
       01 WS-NDG-COI               PIC X(12) VALUE SPACES.              00020700
       01 W-DT-RIS-ENT             PIC 9(08) VALUE ZEROES.              00020800
       01 W-TRIC-TIP-ATTIV         PIC X(02) VALUE SPACES.              00020900
      ***************************************************************** 00021000
      *  CAMPI DI WORKING PER RECORD TAPPO DA TABELLA TTAP            * 00021100
      ***************************************************************** 00021200
       01  W-TTAP.                                                      00021300
           10 W-TTAP-TIP-REC       PIC 9(2).                            00021400
           10 W-TTAP-DT-INVIO      PIC 9(8).                            00021500
           10 W-TTAP-PROGR         PIC 9(5).                            00021600
           10 W-TTAP-N-REC-TOT     PIC 9(7).                            00021700
           10 W-TTAP-SALDID-ITL    PIC 9(7).                            00021800
           10 W-TTAP-SALDIA-ITL    PIC 9(12).                           00021900
           10 W-TTAP-SALDID-EUR    PIC 9(12).                           00022000
           10 W-TTAP-SALDIA-EUR    PIC 9(12).                           00022100
      ***************************************************************** 00022200
      *  CONTROLLORI DI STATO DEI DATA-SETS DI OUTPUT                 * 00022300
      ***************************************************************** 00022400
       01  W-STATO1                 PIC X(02) VALUE SPACES.             00022500
       01  W-STATO2                 PIC X(02) VALUE SPACES.             00022600
       01  W-STATO3                 PIC X(02) VALUE SPACES.             00022700
      ***************************************************************** 00022800
       01  R-CODE                   PIC 9(09) VALUE 0.                  00022900
      *                                                                 00023000
      ***************************************************************** 00023100
      *     CAMPI    DI   WORKING   PER    GESTIONE    ABEND          * 00023200
      ***************************************************************** 00023300
      *                                                                 00023400
       77  COMP-CODE                PIC S9(04) COMP VALUE +5555.        00023500
      *                                                                 00023600
       01  W-PROGRAM                PIC X(08)  VALUE SPACES.            00023700
      ***************************************************************** 00023800
      *      INCLUDE  TABELLE  DB2                                    * 00023900
      ***************************************************************** 00024000
      *                                                                 00024100
           EXEC  SQL  INCLUDE  SQLCA     END-EXEC.                      00024200
           EXEC  SQL  INCLUDE  SCTBTRIC  END-EXEC.                      00024300
           EXEC  SQL  INCLUDE  SCTBTSTO  END-EXEC.                      00024400
           EXEC  SQL  INCLUDE  SCTBTTAP  END-EXEC.                      00024500
           EXEC  SQL  INCLUDE  SCTBTANG  END-EXEC.                      00024600
           EXEC  SQL  INCLUDE  SCTBTDAT  END-EXEC.                      00024700
281102     EXEC  SQL  INCLUDE  SCTBTINV  END-EXEC.                      00024800
250603     EXEC  SQL  INCLUDE  SCTBTSET  END-EXEC.                      00024900
           EXEC  SQL  INCLUDE  TNAZ      END-EXEC.                      00025000
           EXEC  SQL  INCLUDE  TDCO      END-EXEC.                      00025100
      *                                                                 00025200
           EXEC  SQL  INCLUDE  TAP001CD  END-EXEC.                      00025300
221200     EXEC  SQL  INCLUDE  RIC022CD  END-EXEC.                      00025400
                                                                        00025500
      ***************************************************************** 00025600
       PROCEDURE DIVISION.                                              00025700
                                                                        00025800
           DISPLAY 'INIZIO PROGRAMMA'.                                  00025900
           PERFORM 0001-ACCETTA-DATA THRU 0001-EX.                      00026000
                                                                        00026010
           ACCEPT WS-DATA-ODIERNA FROM DATE.                            00026020
                                                                        00026030
           MOVE WS-AA             TO  W-DATA-ELAB-AA.                   00026040
           MOVE WS-MM             TO  W-DATA-ELAB-MM.                   00026050
           MOVE WS-GG             TO  W-DATA-ELAB-GG.                   00026060
                                                                        00026070
                                                                        00026100
           PERFORM 00102-LEGGI-PROGRES THRU 00102-EX.                   00026200
                                                                        00026300
           PERFORM 00100-INIZIO-PGM  THRU 00100-EX.                     00026400
                                                                        00026500
           PERFORM 00190-LEGGI-RICHIESTE THRU 00190-EX.                 00026600
                                                                        00026700
           PERFORM 00500-LEGGI-CONTO-BLOCCATO THRU 00500-EX.            00026800
                                                                        00026900
           PERFORM 00600-SCRIVI-TAPPI THRU 00600-EX.                    00027000
                                                                        00027100
           PERFORM 77777-STATISTICHE THRU  77777-EX.                    00027200
                                                                        00027300
           PERFORM 00300-FINE-PGM    THRU  00300-EX.                    00027400
                                                                        00027500
           STOP RUN.                                                    00027600
                                                                        00027700
      ***************************************************************** 00027800
      *   ROUTINE DI ACCETTAZIONE DELLA DATA DI SISTEMA               * 00027900
      ***************************************************************** 00028000
       0001-ACCETTA-DATA.                                               00028100
           EXEC SQL INCLUDE DATA01SL END-EXEC.                          00028200
           MOVE SQLCODE TO W-SQLCODE.                                   00028300
           IF W-SQLCODE = 0                                             00028400
              GO TO 0001-EX                                             00028500
           END-IF.                                                      00028600
           IF W-SQLCODE = 100                                           00028700
              DISPLAY 'LABEL 0001-ACCETTA-DATA'                         00028800
              DISPLAY 'OCCORRENZA NON TROVATA SU TABELLA SCTBTDAT'      00028900
              DISPLAY 'INIZIALIZZARE CAMPO TDAT-BATCH '                 00029000
           END-IF.                                                      00029100
           IF W-SQLCODE NOT EQUAL 0 AND 100                             00029200
              DISPLAY 'LABEL 0001-ACCETTA-DATA'                         00029300
              DISPLAY 'ERRORE SQL = ' W-SQLCODE ' SU SCTBTDAT'          00029400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00029500
           END-IF.                                                      00029600
       0001-EX.                                                         00029700
           EXIT.                                                        00029800
      ***************************************************************** 00029900
      *      ROUTINE DI INIZIO PROGRAMMA COMPRENDENTE :               * 00030000
      * - DICHIARAZIONE DEL CURSORE PER LA LETTURA DEL DB AFFIDATI ;  * 00030100
      * - ROUTINE DI LETTURA DEL DB PROGRESSIVI                       * 00030200
      * - ROUTINE DI APERTURA IN OUTPUT DEL FILE PER ENTE ;           * 00030300
      ***************************************************************** 00030400
       00100-INIZIO-PGM.                                                00030500
           IF TDAT-RICHIESTA NOT = 0                                    00030600
              PERFORM 00130-APRI-CUR THRU 00130-EX                      00030700
              PERFORM 00120-APRI-FILES  THRU 00120-EX                   00030800
              EXEC SQL INCLUDE RIC011CD END-EXEC                        00030900
              INITIALIZE W-SQLCODE                                      00031000
              MOVE SQLCODE TO W-SQLCODE                                 00031100
221200        IF SQLCODE = 100                                          00031200
221200           GO TO 00100-EX                                         00031300
221200        END-IF                                                    00031400
              IF SQLCODE NOT EQUAL 0 AND 100                            00031500
                 DISPLAY 'LABEL 00100-INIZIO-PGM'                       00031600
                 DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE      00031700
                 PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX      00031800
              END-IF                                                    00031900
           ELSE                                                         00032000
              PERFORM 00110-APRI-CURSORE THRU 00110-EX                  00032100
              PERFORM 00120-APRI-FILES  THRU 00120-EX                   00032200
              EXEC SQL INCLUDE RIC001CD END-EXEC                        00032300
              INITIALIZE W-SQLCODE                                      00032400
              MOVE SQLCODE TO W-SQLCODE                                 00032500
221200        IF SQLCODE = 100                                          00032600
221200           GO TO 00100-EX                                         00032700
221200        END-IF                                                    00032800
              IF SQLCODE NOT EQUAL 0 AND 100                            00032900
                 DISPLAY 'LABEL 00100-INIZIO-PGM'                       00033000
                 DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE      00033100
                 PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX      00033200
              END-IF                                                    00033300
      *                                                                 00033400
           END-IF.                                                      00033500
      *                                                                 00033600
       00100-EX.                                                        00033700
           EXIT.                                                        00033800
      ***************************************************************** 00033900
      *      ROUTINE DI LETTURA PROGRESSIVO DA TAB TTAP               * 00034000
      ***************************************************************** 00034100
       00102-LEGGI-PROGRES.                                             00034200
      *                                                                 00034300
           MOVE '01'  TO  TTAP-TIP-REC.                                 00034400
           MOVE IND1  TO  X-IND1.                                       00034500
      *                                                                 00034600
           EXEC SQL  INCLUDE TAP001SM   END-EXEC.                       00034700
      *                                                                 00034800
           INITIALIZE W-SQLCODE.                                        00034900
      *                                                                 00035000
           MOVE SQLCODE TO W-SQLCODE.                                   00035100
      *                                                                 00035200
           IF SQLCODE = 100                                             00035300
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00035400
              DISPLAY 'ANALISI RICHIESTE'                               00035500
              DISPLAY 'TABELLA PROGRESSIVI VUOTA'                       00035600
              MOVE ZERO   TO    TTAP-PROGR                              00035700
           END-IF.                                                      00035800
           IF SQLCODE NOT EQUAL 0 AND 100                               00035900
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00036000
              DISPLAY 'ANALISI RICHIESTE'                               00036100
              DISPLAY 'ERRORE SQL CODICE DI RITORNO '  W-SQLCODE        00036200
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00036300
           END-IF.                                                      00036400
      *                                                                 00036500
           MOVE TTAP-PROGR  TO  W-AFF-TTAP-PROGR.                       00036600
           MOVE '02' TO  TTAP-TIP-REC.                                  00036700
      *                                                                 00036800
           EXEC SQL  INCLUDE TAP001SM   END-EXEC.                       00036900
      *                                                                 00037000
           INITIALIZE W-SQLCODE.                                        00037100
      *                                                                 00037200
           MOVE SQLCODE TO W-SQLCODE.                                   00037300
      *                                                                 00037400
           IF SQLCODE = 100                                             00037500
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00037600
              DISPLAY 'VARIAZIONI ANAGRAFICHE '                         00037700
              DISPLAY 'TABELLA PROGRESSIVI VUOTA'                       00037800
              MOVE ZERO   TO    TTAP-PROGR                              00037900
           END-IF.                                                      00038000
           IF SQLCODE NOT EQUAL 0 AND 100                               00038100
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00038200
              DISPLAY 'VARIAZIONI ANAGRAFICHE '                         00038300
              DISPLAY 'ERRORE SQL CODICE DI RITORNO '  W-SQLCODE        00038400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00038500
           END-IF.                                                      00038600
      *                                                                 00038700
           MOVE TTAP-PROGR  TO  W-VANG-TTAP-PROGR.                      00038800
           MOVE '03' TO  TTAP-TIP-REC.                                  00038900
      *                                                                 00039000
           EXEC SQL  INCLUDE TAP001SM   END-EXEC.                       00039100
      *                                                                 00039200
           INITIALIZE W-SQLCODE.                                        00039300
      *                                                                 00039400
           MOVE SQLCODE TO W-SQLCODE.                                   00039500
      *                                                                 00039600
           IF SQLCODE = 100                                             00039700
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00039800
              DISPLAY 'VARIAZIONI SCOPERTO DI CONTO'                    00039900
              DISPLAY 'TABELLA PROGRESSIVI VUOTA'                       00040000
              MOVE ZERO   TO    TTAP-PROGR                              00040100
           END-IF.                                                      00040200
           IF SQLCODE NOT EQUAL 0 AND 100                               00040300
              DISPLAY 'LABEL 00102-LEGGI-PROGRES'                       00040400
              DISPLAY 'VARIAZIONI SCOPERTO DI CONTO'                    00040500
              DISPLAY 'ERRORE SQL CODICE DI RITORNO '  W-SQLCODE        00040600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00040700
           END-IF.                                                      00040800
      *                                                                 00040900
           MOVE TTAP-PROGR  TO  W-VSCC-TTAP-PROGR.                      00041000
      *                                                                 00041100
       00102-EX.                                                        00041200
           EXIT.                                                        00041300
      ***************************************************************** 00041400
      *      ROUTINE DI APERTURA CURSORE                              * 00041500
      ***************************************************************** 00041600
       00110-APRI-CURSORE.                                              00041700
      *                                                                 00041800
           EXEC SQL   INCLUDE RIC001CO   END-EXEC.                      00041900
      *                                                                 00042000
           INITIALIZE W-SQLCODE.                                        00042100
           MOVE SQLCODE TO W-SQLCODE.                                   00042200
      *                                                                 00042300
           IF SQLCODE EQUAL 100                                         00042400
221200        GO TO 00110-EX                                            00042500
221200*       PERFORM 02075-INS-PROG-AFF        THRU 02075-EX           00042600
221200*       PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX           00042700
221200*       PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX           00042800
           END-IF.                                                      00042900
      *                                                                 00043000
           IF SQLCODE NOT EQUAL 0                                       00043100
              DISPLAY 'LABEL 00110-APRI-CURSORE'                        00043200
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00043300
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00043400
           END-IF.                                                      00043500
       00110-EX.                                                        00043600
           EXIT.                                                        00043700
      ***************************************************************** 00043800
      *      ROUTINE DI APERTURA CURSORE                              * 00043900
      ***************************************************************** 00044000
       00130-APRI-CUR.                                                  00044100
      *                                                                 00044200
           EXEC SQL   INCLUDE RIC011CO   END-EXEC.                      00044300
      *                                                                 00044400
           INITIALIZE W-SQLCODE.                                        00044500
           MOVE SQLCODE TO W-SQLCODE.                                   00044600
      *                                                                 00044700
221200*    IF SQLCODE EQUAL 100                                         00044800
221200*       PERFORM 02075-INS-PROG-AFF        THRU 02075-EX           00044900
221200*       PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX           00045000
221200*       PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX           00045100
221200*    END-IF.                                                      00045200
      *                                                                 00045300
           IF SQLCODE NOT EQUAL 0 AND 100                               00045400
              DISPLAY 'LABEL 00130-APRI-CUR'                            00045500
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00045600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00045700
           END-IF.                                                      00045800
      *                                                                 00045900
           EXEC SQL   INCLUDE TAP001CO   END-EXEC.                      00046000
      *                                                                 00046100
           INITIALIZE W-SQLCODE.                                        00046200
           MOVE SQLCODE TO W-SQLCODE.                                   00046300
      *                                                                 00046400
           IF SQLCODE EQUAL 100                                         00046500
221200        GO TO 00130-EX                                            00046600
221200*       PERFORM 02075-INS-PROG-AFF        THRU 02075-EX           00046700
221200*       PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX           00046800
221200*       PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX           00046900
221200*    END-IF.                                                      00047000
      *                                                                 00047100
           IF SQLCODE NOT EQUAL 0 AND 100                               00047200
              DISPLAY 'LABEL 00130-APRI-CUR'                            00047300
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00047400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00047500
           END-IF.                                                      00047600
       00130-EX.                                                        00047700
           EXIT.                                                        00047800
      ***************************************************************** 00047900
      *   ROUTINE DI APERTURA FILE AFFIDA                             * 00048000
      ***************************************************************** 00048100
       00120-APRI-FILES.                                                00048200
           OPEN OUTPUT AFFIDA.                                          00048300
           IF W-STATO1 NOT EQUAL ZERO                                   00048400
              DISPLAY ' ERRORE ' W-STATO1 ' SU APERTURA AFFIDA '        00048500
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00048600
           END-IF.                                                      00048700
      *                                                                 00048800
           OPEN OUTPUT VARIANG.                                         00048900
           IF W-STATO2 NOT EQUAL ZERO                                   00049000
              DISPLAY ' ERRORE ' W-STATO2 ' SU APERTURA VARIANG '       00049100
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00049200
           END-IF.                                                      00049300
      *                                                                 00049400
           OPEN OUTPUT VARIASCC.                                        00049500
           IF W-STATO3 NOT EQUAL ZERO                                   00049600
              DISPLAY ' ERRORE ' W-STATO3 ' SU APERTURA VARIASCC '      00049700
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00049800
           END-IF.                                                      00049900
      *                                                                 00050000
       00120-EX.                                                        00050100
           EXIT.                                                        00050200
      ***************************************************************** 00050300
       00190-LEGGI-RICHIESTE.                                           00050400
           IF TDAT-RICHIESTA NOT EQUAL 0                                00050500
              PERFORM 00210-FETCH   THRU 00210-EX                       00050600
               UNTIL W-SQLCODE NOT EQUAL 0                              00050700
           ELSE                                                         00050800
              PERFORM 00200-FAI-FETCH   THRU 00200-EX                   00050900
               UNTIL W-SQLCODE NOT EQUAL 0                              00051000
           END-IF.                                                      00051100
       00190-EX.                                                        00051200
           EXIT.                                                        00051300
      ***************************************************************** 00051400
      *   ROUTINE DI LETTURA DB RICHIESTE                             * 00051500
      ***************************************************************** 00051600
       00200-FAI-FETCH.                                                 00051700
      *                                                                 00051800
           EXEC SQL  INCLUDE RIC001CF    END-EXEC.                      00051900
      *                                                                 00052000
           INITIALIZE W-SQLCODE.                                        00052100
           MOVE SQLCODE TO W-SQLCODE.                                   00052200
      *                                                                 00052300
           IF W-SQLCODE = 0                                             00052400
              ADD 1 TO W-CTR-LETTI                                      00052500
281102        IF (TRIC-TIP-ATTIV = 'V1' OR 'V2')                        00052600
281102        OR (TRIC-NDG-COI = SPACES)                                00052700
281102        OR (TRIC-NDG-PF = TRIC-NDG-COI)                           00052800
281102           PERFORM 00205-GESTIONE-INVII      THRU 00205-EX        00052900
281102        END-IF                                                    00053000
              MOVE TRIC-NDG-PF    TO WS-NDG-PF                          00053100
              MOVE TRIC-NDG-COI   TO WS-NDG-COI                         00053200
              MOVE TRIC-SERVIZIO  TO WS-SERVIZIO                        00053300
              MOVE TRIC-CATEGORIA TO WS-CATEGORIA                       00053400
              MOVE TRIC-FILIALE   TO WS-FILIALE                         00053500
              MOVE TRIC-NUMERO    TO WS-NUMERO                          00053600
              PERFORM 01500-CONTROLLO-TIP-ATTIV THRU 01500-EX           00053700
           END-IF.                                                      00053800
      *                                                                 00053900
221200     IF W-SQLCODE = 100                                           00054000
221200        GO TO 00200-EX                                            00054100
221200     END-IF.                                                      00054200
      *                                                                 00054300
221200*    IF W-SQLCODE = 100 AND W-CTR-LETTI = 0                       00054400
221200*       PERFORM 02075-INS-PROG-AFF        THRU 02075-EX           00054500
221200*       PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX           00054600
221200*       PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX           00054700
221200*       ADD 1 TO W-CTR-SCRITTI                                    00054800
221200*       DISPLAY 'LA TABELLA RICHIESTE NON PRESENTA '              00054900
221200*       DISPLAY 'RECORD DA INVIARE'                               00055000
221200*       DISPLAY 'SARANNO INOLTRATI ALL''ENTE I SOLI'              00055100
221200*       DISPLAY 'RECORD DI TESTA'                                 00055200
221200*       GO TO 00200-EX                                            00055300
221200*    END-IF.                                                      00055400
      *                                                                 00055500
221200*    IF W-SQLCODE = 100 AND W-CTR-LETTI > 0                       00055600
221200*       PERFORM 02075-INS-PROG-AFF        THRU 02075-EX           00055700
221200*       PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX           00055800
221200*       PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX           00055900
221200*       ADD 1 TO W-CTR-SCRITTI                                    00056000
221200*       GO TO 00200-EX                                            00056100
221200*    END-IF.                                                      00056200
                                                                        00056300
           IF W-SQLCODE NOT EQUAL 0 AND 100                             00056400
              DISPLAY ' LABEL 00200-FAI-FETCH       '                   00056500
              DISPLAY ' LETTURA DB TRIC - RICHIESTE '                   00056600
              DISPLAY ' ERRORE SQL CODICE DI RITORNO   ' W-SQLCODE      00056700
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00056800
           END-IF.                                                      00056900
       00200-EX.                                                        00057000
           EXIT.                                                        00057100
281102***************************************************************** 00057200
281102*   INSERIMENTO NELLA TABELLA DEGLI INVII DELLE OPERAZIONI A T.P* 00057300
281102***************************************************************** 00057400
281102 00205-GESTIONE-INVII.                                            00057500
281102*                                                                 00057600
281102     INITIALIZE DCLSCTBTINV.                                      00057700
281102*                                                                 00057800
281102     MOVE TRIC-SERVIZIO            TO TINV-SERVIZIO.              00057900
281102     MOVE TRIC-CATEGORIA           TO TINV-CATEGORIA.             00058000
281102     MOVE TRIC-FILIALE             TO TINV-FILIALE.               00058100
281102     MOVE TRIC-NUMERO              TO TINV-NUMERO.                00058200
281102     MOVE TRIC-NDG-PF              TO TINV-NDG-PF.                00058300
281102     MOVE TRIC-NDG-COI             TO TINV-NDG-COI.               00058400
281102     MOVE TDAT-BATCH               TO TINV-DT-INVIO.              00058500
281102     MOVE TRIC-TIP-ATTIV           TO TINV-TIP-ATTIV.             00058600
281102     MOVE TRIC-COD-OPER            TO TINV-COD-OPER.              00058700
281102     MOVE TRIC-FIL-RICH            TO TINV-FIL-RICH.              00058800
281102*                                                                 00058900
281102     EXEC SQL  INCLUDE INV001IN    END-EXEC.                      00059000
281102*                                                                 00059100
281102     IF SQLCODE NOT = 0                                           00059200
281102        MOVE SQLCODE TO W-SQLCODE                                 00059300
281102        DISPLAY 'LABEL   :  00205-GESTIONE-INVII'                 00059400
281102        DISPLAY 'ERRORE ' W-SQLCODE ' SU INSERT DB2 IN SCTBTINV'  00059500
281102        DISPLAY 'CHIAVE DI INSERIMENTO'                           00059600
281102        DISPLAY 'SERVIZIO  : ' TINV-SERVIZIO                      00059700
281102        DISPLAY 'CATEGORIA : ' TINV-CATEGORIA                     00059800
281102        DISPLAY 'FILIALE   : ' TINV-FILIALE                       00059900
281102        DISPLAY 'NUMERO    : ' TINV-NUMERO                        00060000
281102        DISPLAY 'NDG PF    : ' TINV-NDG-PF                        00060100
281102        DISPLAY 'NDG COI   : ' TINV-NDG-COI                       00060200
281102        DISPLAY 'DATA INVIO: ' TINV-DT-INVIO                      00060300
281102        DISPLAY 'T.ATTIVITA: ' TINV-TIP-ATTIV                     00060400
281102        PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00060500
281102     END-IF.                                                      00060600
281102*                                                                 00060700
281102     ADD 1     TO W-CTR-SCRITTI-INV.                              00060800
281102*                                                                 00060900
281102 00205-EX.                                                        00061000
281102     EXIT.                                                        00061100
      ***************************************************************** 00061200
      *   ROUTINE DI LETTURA DB RICHIESTE                             * 00061300
      ***************************************************************** 00061400
       00210-FETCH.                                                     00061500
      *                                                                 00061600
           EXEC SQL  INCLUDE RIC011CF    END-EXEC.                      00061700
      *                                                                 00061800
           INITIALIZE W-SQLCODE.                                        00061900
           MOVE SQLCODE TO W-SQLCODE.                                   00062000
      *                                                                 00062100
           IF W-SQLCODE = 0                                             00062200
              ADD 1 TO W-CTR-LETTI                                      00062300
              MOVE TRIC-NDG-PF    TO WS-NDG-PF                          00062400
              MOVE TRIC-NDG-COI   TO WS-NDG-COI                         00062500
              MOVE TRIC-SERVIZIO  TO WS-SERVIZIO                        00062600
              MOVE TRIC-CATEGORIA TO WS-CATEGORIA                       00062700
              MOVE TRIC-FILIALE   TO WS-FILIALE                         00062800
              MOVE TRIC-NUMERO    TO WS-NUMERO                          00062900
              PERFORM 01500-CONTROLLO-TIP-ATTIV THRU 01500-EX           00063000
           END-IF.                                                      00063100
      *                                                                 00063200
           IF W-SQLCODE = 100 AND W-CTR-LETTI = 0                       00063300
              PERFORM 08000-CERCA-TAPPO     THRU 08000-EX               00063400
              GO TO 00210-EX                                            00063500
           END-IF.                                                      00063600
      *                                                                 00063700
           IF W-SQLCODE = 100 AND W-CTR-LETTI > 0                       00063800
              PERFORM 08000-CERCA-TAPPO THRU 08000-EX                   00063900
              GO TO 00210-EX                                            00064000
           END-IF.                                                      00064100
                                                                        00064200
           IF W-SQLCODE NOT EQUAL 0                                     00064300
              DISPLAY ' LABEL 00210-FETCH       '                       00064400
              DISPLAY ' LETTURA DB TRIC - RICHIESTE '                   00064500
              DISPLAY ' ERRORE SQL CODICE DI RITORNO   ' W-SQLCODE      00064600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00064700
           END-IF.                                                      00064800
      *                                                                 00064900
                                                                        00065000
       00210-EX.                                                        00065100
           EXIT.                                                        00065200
      ***************************************************************** 00065300
      *    ROUTINE DI FINE PROGRAMMA COMPRENDENTE :                   * 00065400
      * - CHIUSURA DEL CURSORE UTILIZZATO PER LA LETTURA DEL DB       * 00065500
      *   AFFIDATI ;                                                  * 00065600
      * - ROUTINE DI AGGIORNAMENTO DEL DB RICHIESTE                   * 00065700
      * - ROUTINE DI INSERIMENTO DEL DB PROGRESSIVI                   * 00065800
      * - CHIUSURA DEL FILE DI OUTPUT DEI MOVIMENTI ;                 * 00065900
      ***************************************************************** 00066000
       00300-FINE-PGM.                                                  00066100
           PERFORM 00310-CHIUDI-CURSORE THRU 00310-EX.                  00066200
           PERFORM 00320-CHIUDI-FILES THRU 00320-EX.                    00066300
           DISPLAY 'FINE PGM'.                                          00066400
       00300-EX.                                                        00066500
           EXIT.                                                        00066600
      ***************************************************************** 00066700
      *    ROUTINE DI CHIUSURA CURSORE                                * 00066800
      ***************************************************************** 00066900
       00310-CHIUDI-CURSORE.                                            00067000
      *                                                                 00067100
           IF TDAT-RICHIESTA NOT = 0                                    00067200
              PERFORM 00330-CHIUDI-CUR-RIC THRU 00330-EX                00067300
           ELSE                                                         00067400
              PERFORM 00340-CHIUDI-CUR-BATCH THRU 00340-EX              00067500
           END-IF.                                                      00067600
      *                                                                 00067700
       00310-EX.                                                        00067800
           EXIT.                                                        00067900
      ***************************************************************** 00068000
      *    ROUTINE DI CHIUSURA CURSORE                                * 00068100
      ***************************************************************** 00068200
       00330-CHIUDI-CUR-RIC.                                            00068300
           EXEC SQL INCLUDE RIC011CC END-EXEC.                          00068400
           EXEC SQL INCLUDE TAP001CC END-EXEC.                          00068500
       00330-EX.                                                        00068600
           EXIT.                                                        00068700
      ***************************************************************** 00068800
      *    ROUTINE DI CHIUSURA CURSORE                                * 00068900
      ***************************************************************** 00069000
       00340-CHIUDI-CUR-BATCH.                                          00069100
           EXEC SQL INCLUDE RIC001CC END-EXEC.                          00069200
       00340-EX.                                                        00069300
           EXIT.                                                        00069400
      ***************************************************************** 00069500
      *    ROUTINE DI CHIUSURA FILE DI OUTPUT PER MOVIMENTI           * 00069600
      ***************************************************************** 00069700
       00320-CHIUDI-FILES.                                              00069800
      *                                                                 00069900
           CLOSE AFFIDA.                                                00070000
           IF W-STATO1 NOT EQUAL ZERO                                   00070100
              DISPLAY ' ERRORE ' W-STATO1 ' CHIUSURA AFFIDA '           00070200
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00070300
           END-IF.                                                      00070400
      *                                                                 00070500
           CLOSE VARIANG.                                               00070600
           IF W-STATO2 NOT EQUAL ZERO                                   00070700
              DISPLAY ' ERRORE ' W-STATO2 ' CHIUSURA VARIANG '          00070800
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00070900
           END-IF.                                                      00071000
      *                                                                 00071100
           CLOSE VARIASCC.                                              00071200
           IF W-STATO3 NOT EQUAL ZERO                                   00071300
              DISPLAY ' ERRORE ' W-STATO3 ' CHIUSURA VARIASCC '         00071400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00071500
           END-IF.                                                      00071600
      *                                                                 00071700
       00320-EX.                                                        00071800
           EXIT.                                                        00071900
      ***************************************************************** 00072000
       01500-CONTROLLO-TIP-ATTIV.                                       00072100
      *                                                                 00072200
           IF TRIC-TIP-ATTIV = 'RS'                                     00072300
              ADD 1    TO   W-CTR-RS                                    00072400
              PERFORM 01600-SCOPERTO-BPO THRU 01600-EX                  00072500
           END-IF.                                                      00072600
      *                                                                 00072700
           IF TRIC-TIP-ATTIV = 'V2'                                     00072800
              ADD 1    TO   W-CTR-V2                                    00072900
              PERFORM 03000-VARIAZIONE-ANAG THRU 03000-EX               00073000
           END-IF.                                                      00073100
      *                                                                 00073200
           IF TRIC-TIP-ATTIV = 'V1'                                     00073300
              ADD 1    TO   W-CTR-V1                                    00073400
              PERFORM 04000-VAR-V1-A3-D3-R3 THRU 04000-EX               00073500
           END-IF.                                                      00073600
      *                                                                 00073700
           IF TRIC-TIP-ATTIV = 'A3'                                     00073800
              ADD 1    TO   W-CTR-A3                                    00073900
              PERFORM 04000-VAR-V1-A3-D3-R3 THRU 04000-EX               00074000
           END-IF.                                                      00074100
      *                                                                 00074200
           IF TRIC-TIP-ATTIV = 'D3'                                     00074300
              ADD 1    TO   W-CTR-D3                                    00074400
              PERFORM 04000-VAR-V1-A3-D3-R3 THRU 04000-EX               00074500
           END-IF.                                                      00074600
      *                                                                 00074700
           IF TRIC-TIP-ATTIV = 'R3'                                     00074800
              PERFORM 04000-VAR-V1-A3-D3-R3 THRU 04000-EX               00074900
           END-IF.                                                      00075000
      *                                                                 00075100
       01500-EX.                                                        00075200
           EXIT.                                                        00075300
      ***************************************************************** 00075400
       01600-SCOPERTO-BPO.                                              00075500
      *                                                                 00075600
           PERFORM 02000-ACCESSO-ANAGRAFICA  THRU 02000-EX.             00075700
      *                                                                 00075800
           PERFORM 02005-ACCESSO-TANG        THRU 02005-EX.             00075900
      *                                                                 00076000
           PERFORM 02010-SCRIVI-AFFIDA       THRU 02010-EX.             00076100
      *                                                                 00076200
           IF TDAT-RICHIESTA = 0                                        00076300
              PERFORM 02050-AGGIORNA-RICHIESTE  THRU 02050-EX           00076400
           END-IF.                                                      00076500
      *                                                                 00076600
       01600-EX.                                                        00076700
           EXIT.                                                        00076800
      ***************************************************************** 00076900
       03000-VARIAZIONE-ANAG.                                           00077000
      *                                                                 00077100
              PERFORM 02000-ACCESSO-ANAGRAFICA  THRU 02000-EX.          00077200
      *                                                                 00077300
              PERFORM 02005-ACCESSO-TANG        THRU 02005-EX.          00077400
      *                                                                 00077500
              PERFORM 07100-SCRIVI-VAR-ANAG     THRU 07100-EX.          00077600
      *                                                                 00077700
              IF TDAT-RICHIESTA = 0                                     00077800
                 PERFORM 02050-AGGIORNA-RICHIESTE  THRU 02050-EX        00077900
              END-IF.                                                   00078000
      *                                                                 00078100
       03000-EX.                                                        00078200
           EXIT.                                                        00078300
      ***************************************************************** 00078400
       04000-VAR-V1-A3-D3-R3.                                           00078500
      *                                                                 00078600
241000        PERFORM 02000-ACCESSO-ANAGRAFICA  THRU 02000-EX.          00078700
      *                                                                 00078800
050201        IF TRIC-TIP-ATTIV = 'R3'                                  00078900
050201           IF TRIC-NDG-COI NOT = SPACES                           00079000
050201              IF TRIC-NDG-COI NOT = TRIC-NDG-PF                   00079100
050201                 PERFORM 02050-AGGIORNA-RICHIESTE THRU 02050-EX   00079200
050201                 GO TO 04000-EX                                   00079300
280201*             ELSE                                                00079400
280201*                ADD 1 TO W-CTR-R3                                00079500
050201              END-IF                                              00079600
050201           END-IF                                                 00079700
050201        END-IF.                                                   00079800
      *                                                                 00079900
              PERFORM 07200-SCRIVI-V1-A3-D3-R3     THRU 07200-EX.       00080000
      *                                                                 00080100
              IF TDAT-RICHIESTA = 0                                     00080200
                 PERFORM 02050-AGGIORNA-RICHIESTE  THRU 02050-EX        00080300
              END-IF.                                                   00080400
      *                                                                 00080500
       04000-EX.                                                        00080600
           EXIT.                                                        00080700
      ***************************************************************** 00080800
       02000-ACCESSO-ANAGRAFICA.                                        00080900
                                                                        00081000
           MOVE SPACE                      TO L-ACS108-ARG.             00081100
           MOVE ZERO                       TO L-ACS108-I-BANCA.         00081200
           MOVE ZERO                       TO L-ACS108-I-DATA-RIF.      00081300
           MOVE ' '                        TO L-ACS108-I-TIPO-RICH.     00081400
           IF TRIC-NDG-COI = SPACES                                     00081500
              MOVE TRIC-SERVIZIO           TO L-ACS108-I-SERVIZIO       00081600
              MOVE TRIC-FILIALE            TO L-ACS108-I-FILIALE        00081700
              MOVE TRIC-CATEGORIA          TO L-ACS108-I-CATEGORIA      00081800
              MOVE TRIC-NUMERO             TO L-ACS108-I-NUMERO         00081900
           ELSE                                                         00082000
              MOVE TRIC-NDG-PF             TO L-ACS108-I-NDG            00082100
           END-IF.                                                      00082200
                                                                        00082300
           EXEC SQL INCLUDE EXACS108 END-EXEC.                          00082400
      *                                                                 00082500
      * * * * * * * * * * * * * * * * * * * * * *                       00082600
      * GESTIONE RET-CODE  PER CODICE ANOMALIA  *                       00082700
      * * * * * * * * * * * * * * * * * * * * * *                       00082800
           IF L-ACS108-RET-CODE  = 2                                    00082900
              DISPLAY ' RAPPORTO INESISTENTE     '                      00083000
              DISPLAY ' CODICE DI RITORNO MODULO ' L-ACS108-RET-CODE    00083100
              DISPLAY ' NDG              =       ' TRIC-NDG-PF          00083200
              DISPLAY ' SERVIZIO         =       ' TRIC-SERVIZIO        00083300
              DISPLAY ' CATEGORIA        =       ' TRIC-CATEGORIA       00083400
              DISPLAY ' NUMERO           =       ' TRIC-NUMERO          00083500
           END-IF.                                                      00083600
      *                                                                 00083700
           IF L-ACS108-RET-CODE  = 7                                    00083800
              DISPLAY ' CHIAVE ANAGR. INESISTENTE' L-ACS108-RET-CODE    00083900
           END-IF.                                                      00084000
      *                                                                 00084100
           IF L-ACS108-RET-CODE  NOT = 0 AND                            00084200
              L-ACS108-RET-CODE  NOT = 2 AND                            00084300
              L-ACS108-RET-CODE  NOT = 7                                00084400
              DISPLAY ' ABEND SISTEMA ' L-ACS108-RET-CODE               00084500
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00084600
           END-IF.                                                      00084700
      *                                                                 00084800
       02000-EX. EXIT.                                                  00084900
      ****************************************************************  00085000
      *  ROUTINE DI ACCESSO ALLA TABELLA FLUSSO ENTE                 *  00085100
      ****************************************************************  00085200
       02005-ACCESSO-TANG.                                              00085300
      *                                                                 00085400
           MOVE TRIC-NDG-PF                TO TANG-NDG.                 00085500
      *                                                                 00085600
           EXEC SQL INCLUDE ANG001SL END-EXEC.                          00085700
      *                                                                 00085800
           INITIALIZE W-SQLCODE.                                        00085900
      *                                                                 00086000
           MOVE SQLCODE TO W-SQLCODE.                                   00086100
           IF SQLCODE = 100                                             00086200
              DISPLAY 'LABEL 02005-INIZIO-PGM'                          00086300
              DISPLAY 'NDG NON TROVATO SU SCTBTANG:' TANG-NDG           00086400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00086500
           END-IF.                                                      00086600
           IF SQLCODE NOT EQUAL 0 AND 100                               00086700
              DISPLAY 'LABEL 02005-INIZIO-PGM'                          00086800
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00086900
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00087000
           END-IF.                                                      00087100
      *                                                                 00087200
       02005-EX. EXIT.                                                  00087300
      *                                                                 00087400
      ****************************************************************  00087500
      *  ROUTINE DI SCRITTURA RECORD PER FLUSSO ENTE                 *  00087600
      ****************************************************************  00087700
       02010-SCRIVI-AFFIDA.                                             00087800
                                                                        00088000
           MOVE '01'                       TO ARRAC005-TIPO-REC.        00088100
           MOVE TRIC-NDG-PF                TO ARRAC005-NDG.             00088200
           MOVE TRIC-NDG-COI               TO ARRAC005-NDG-COI.         00088300
           MOVE TRIC-SERVIZIO              TO ARRAC005-SERVIZIO.        00088400
           MOVE TRIC-CATEGORIA             TO ARRAC005-CATEGORIA.       00088500
           MOVE TRIC-FILIALE               TO ARRAC005-FILIALE.         00088600
           MOVE TRIC-NUMERO                TO ARRAC005-NUMERO.          00088700
           MOVE TANG-ANNI                  TO ARRAC005-ANNI.            00088800
           MOVE TANG-MESI                  TO ARRAC005-MESI.            00088900
           MOVE TANG-IND-PREC              TO ARRAC005-IND-PREC.        00089000
           MOVE TANG-LOC-PREC              TO WS-LOCPRE.                00089200
           PERFORM 12000-VALORIZZA-LOCPRE THRU 12000-EX.                00089300
           MOVE TANG-PROV-PREC             TO ARRAC005-PROV-PREC.       00089400
           IF TANG-PROV-PREC NOT = 'EE' OR                              00089500
            TANG-STATO-PREC = SPACE OR ZERO OR LOW-VALUE                00089600
              MOVE SPACES TO ARRAC005-STATO-PREC                        00089700
           ELSE                                                         00089800
              MOVE TANG-STATO-PREC TO WS-COD-TNAZ                       00089900
              IF WS-COD2-TNAZ = SPACE                                   00090000
                 IF WS-COD1-TNAZ IS NUMERIC                             00090100
                    MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                  00090200
                    MOVE WS-CODICE-NAZ TO ARRAC005-STATO-PREC           00090300
                 ELSE                                                   00090400
                    MOVE WS-COD1-TNAZ TO ARRAC005-STATO-PREC            00090500
                 END-IF                                                 00090600
              ELSE                                                      00090700
                 MOVE WS-COD-TNAZ TO ARRAC005-STATO-PREC                00090800
              END-IF                                                    00090900
           END-IF.                                                      00091000
           MOVE TANG-COM-RIL               TO WS-COMRIL.                00091200
           PERFORM 11000-VALORIZZA-COMRIL THRU 11000-EX.                00091300
           MOVE WS-COMRIL1 TO ARRAC005-COM-RIL.                         00091400
           IF TRIC-NDG-COI = TRIC-NDG-PF                                00091500
              MOVE SPACES TO ARRAC005-PROV-RIL                          00091600
           ELSE                                                         00091700
              MOVE TANG-PROV-RIL              TO ARRAC005-PROV-RIL      00091800
           END-IF.                                                      00091900
           IF TANG-PROV-RIL = 'EE'                                      00092000
              MOVE TANG-COM-RIL TO WS-ENTE2                             00092100
              PERFORM 90000-CONTROLLA-NAZ THRU 90000-EX                 00092200
              IF ARRAC005-COM-RIL = 'REPUBBLICA DI SAN MARINO'          00092220
                 CONTINUE                                               00092230
              ELSE                                                      00092240
                 MOVE SPACES TO ARRAC005-COM-RIL                        00092300
              END-IF                                                    00092301
           ELSE                                                         00092400
              MOVE SPACES TO ARRAC005-NAZ-RIL                           00092500
           END-IF.                                                      00092600
           MOVE TANG-TEL1                  TO ARRAC005-TEL1.            00092700
           MOVE TANG-TEL2                  TO ARRAC005-TEL2.            00092800
           IF TANG-TEL2 = SPACES OR LOW-VALUE OR ZERO                   00092810
              MOVE '9999'        TO        ARRAC005-TEL2                00092820
           END-IF.                                                      00092830
                                                                        00092840
           PERFORM 02011-ACCESSO-TSET     THRU 02011-EX.                00092900
                                                                        00092910
           MOVE COD-PRODOTTO               TO TRIC-SETT-PROD.           00093100
                                                                        00093200
           MOVE TRIC-SETT-PROD             TO ARRAC005-SETT-PROD.       00094200
      *---------------------------------------------------------------- 00094201
      *-----> A T T E N Z I O N E !!! <-------------------------------- 00094202
      *---------------------------------------------------------------- 00094203
      * QUESTA MODIFICA DOVRA' ESSERE TOLTA QUANDO DB SARA' PRONTA A    00094204
      * RICEVERE IL SETTORE PRODUTTIVO ANCHE SUL REC. DI COINTESTAZIONE 00094205
      *---------------------------------------------------------------- 00094206
      *    IF TRIC-NDG-COI = TRIC-NDG-PF                                00094210
      *       MOVE SPACES                  TO ARRAC005-SETT-PROD        00094220
      *       MOVE SPACES                  TO TRIC-SETT-PROD            00094221
      *    END-IF.                                                      00094230
      *---------------------------------------------------------------- 00094240
           MOVE TRIC-COD-AFF               TO ARRAC005-COD-AFF.         00094300
           MOVE TRIC-LIM-FIDO              TO ARRAC005-IMP-AFF.         00094400
           MOVE TRIC-ACCR-STIP             TO ARRAC005-ACCR-STIP.       00094500
040501***********************************************************       00094600
040501* IL SEGUENTE CONTROLLO E' STATO AGGIUNTO PER PASSARE A   *       00094700
040501* A ZERO L' IMPORTO DELLO STIPENDIO PER QUEI RAPPORTI CHE *       00094800
040501* PRESENTANO ACCREDITO NEGATIVO                           *       00094900
040501***********************************************************       00095000
040501     IF TRIC-ACCR-STIP = 'N'                                      00095100
040501        MOVE ZEROES                  TO ARRAC005-IMP-STIP         00095200
040501     ELSE                                                         00095300
040501        MOVE TRIC-IMP-STIP           TO ARRAC005-IMP-STIP         00095400
040501     END-IF.                                                      00095500
040501*    MOVE TRIC-IMP-STIP              TO ARRAC005-IMP-STIP.        00095600
           MOVE TRIC-DIV-STIP              TO ARRAC005-DIV-STIP.        00095700
      * DATI PROVENIENTI DA ANAGRAFE                                    00095800
           IF TRIC-NDG-COI NOT EQUAL TRIC-NDG-PF                        00095900
              MOVE SPACES                  TO ARRAC005-INT-RIDOTTA      00096000
           ELSE                                                         00096100
              MOVE L-ACS108-RAGSOC         TO ARRAC005-INT-RIDOTTA      00096200
050702        INSPECT ARRAC005-INT-RIDOTTA REPLACING ALL '-' BY SPACES  00096300
           END-IF.                                                      00096400
           MOVE L-ACS108-COGNOME           TO ARRAC005-COGNOME.         00096500
           MOVE L-ACS108-NOME              TO ARRAC005-NOME.            00096600
           MOVE L-ACS108-SESSO             TO ARRAC005-SESSO.           00096700
           MOVE L-ACS108-DATA-NASC-COS     TO ARRAC005-DATA-NASC-COS.   00096800
           MOVE L-ACS108-NAZ-NASCITA       TO WS-COD-TNAZ.              00096900
           IF WS-COD-TNAZ  NOT = SPACES AND LOW-VALUE                   00097000
              MOVE SPACES TO ARRAC005-LUOGO-NASCITA                     00097100
000830        MOVE 'EE'   TO ARRAC005-PROV-NASCITA                      00097200
000830     ELSE                                                         00097300
151100*       MOVE L-ACS108-LUOGO-NASCITA    TO ARRAC005-LUOGO-NASCITA  00097400
151100        MOVE L-ACS108-LUOGO-NASCITA    TO WS-LOCNASC              00097500
151100        PERFORM 11050-VALORIZZA-LOCNASC THRU 11050-EX             00097600
000830        MOVE L-ACS108-PROV-NASCITA     TO ARRAC005-PROV-NASCITA   00097700
           END-IF.                                                      00097800
           IF WS-COD2-TNAZ = SPACE                                      00097900
              IF WS-COD1-TNAZ IS NUMERIC                                00098000
                 MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                     00098100
                 MOVE WS-CODICE-NAZ TO ARRAC005-NAZ-NASCITA             00098200
              ELSE                                                      00098300
                 MOVE WS-COD1-TNAZ TO ARRAC005-NAZ-NASCITA              00098400
              END-IF                                                    00098500
           ELSE                                                         00098600
              MOVE WS-COD-TNAZ TO ARRAC005-NAZ-NASCITA                  00098700
           END-IF.                                                      00098800
           MOVE L-ACS108-NAT-GIURIDICA     TO ARRAC005-NAT-GIURIDICA.   00098900
           MOVE L-ACS108-COD-FISCALE       TO ARRAC005-COD-FISCALE.     00099000
230603*    MOVE L-ACS108-R-COD-VALUTA      TO ARRAC005-DIV-RAPP.        00099100
           MOVE 'EUR'                      TO ARRAC005-DIV-RAPP.        00099200
           MOVE  00600                     TO ARRAC005-GUE.             00099300
231100*    MOVE L-ACS108-NUOVO-RAE         TO ARRAC005-RAE.             00099400
231100     MOVE 00000                      TO ARRAC005-RAE.             00099500
010900*    MOVE TANG-IND-RES               TO ARRAC005-IND-SEDE-LEG.    00099600
010900     MOVE L-ACS108-IND-SEDE-LEG      TO ARRAC005-IND-SEDE-LEG.    00099700
           IF TANG-LOC-RES NOT = SPACES AND LOW-VALUE                   00099800
              PERFORM 10050-ACCESSO-TDCO THRU 10050-EX                  00099900
              MOVE TANG-LOC-RES            TO WS-COMUNE                 00100000
              PERFORM 10000-VALORIZZA-COMUNE THRU 10000-EX              00100100
210602        MOVE L-ACS108-CAP-SEDE-LEG   TO ARRAC005-CAP-SEDE-LEG     00100200
210602        MOVE L-ACS108-PROV-SEDE-LEG  TO ARRAC005-PROV-SEDE-LEG    00100300
210602*       MOVE TDCO-CAP                TO ARRAC005-CAP-SEDE-LEG     00100400
210602*       MOVE TDCO-PROV               TO ARRAC005-PROV-SEDE-LEG    00100500
           ELSE                                                         00100600
              MOVE L-ACS108-LOC-SEDE-LEG   TO WS-COMUNE                 00100700
              PERFORM 10000-VALORIZZA-COMUNE THRU 10000-EX              00100800
010900        MOVE L-ACS108-CAP-SEDE-LEG   TO ARRAC005-CAP-SEDE-LEG     00100900
              MOVE L-ACS108-PROV-SEDE-LEG  TO ARRAC005-PROV-SEDE-LEG    00101000
           END-IF.                                                      00101100
           MOVE L-ACS108-NAZ-SEDE-LEG      TO WS-COD-TNAZ.              00101200
           IF WS-COD2-TNAZ = SPACE                                      00101300
              IF WS-COD1-TNAZ IS NUMERIC                                00101400
                 MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                     00101500
                 MOVE WS-CODICE-NAZ TO ARRAC005-NAZ-SEDE-LEG            00101600
              ELSE                                                      00101700
                 MOVE WS-COD1-TNAZ TO ARRAC005-NAZ-SEDE-LEG             00101800
              END-IF                                                    00101900
           ELSE                                                         00102000
              MOVE WS-COD-TNAZ TO ARRAC005-NAZ-SEDE-LEG                 00102100
           END-IF.                                                      00102200
           MOVE L-ACS108-COD-DOC           TO ARRAC005-COD-DOC.         00102300
           MOVE L-ACS108-DT-RIL-DOC        TO ARRAC005-DT-RIL-DOC.      00102400
      *                                                                 00102500
           PERFORM 02020-CODIFICA-DOCUMENTI THRU 02020-EX               00102600
      *                                                                 00102700
291102     IF ARRAC005-NAZ-SEDE-LEG = '0800'                            00102800
291102        MOVE SPACES                  TO ARRAC005-LOC-SEDE-LEG     00102900
291102        MOVE 'REPUBBLICA DI SAN MARINO'                           00103000
291102                                     TO ARRAC005-LOC-SEDE-LEG     00103100
291102     END-IF.                                                      00103200
      *                                                                 00103300
120603     IF ARRAC005-PROV-SEDE-LEG = 'FO'                             00103400
120603        MOVE 'FC'                      TO ARRAC005-PROV-SEDE-LEG  00103500
120603     ELSE                                                         00103600
120603        IF ARRAC005-PROV-SEDE-LEG = 'PS'                          00103700
120603           MOVE 'PU'                   TO ARRAC005-PROV-SEDE-LEG  00103800
120603        END-IF                                                    00103900
120603     END-IF.                                                      00104000
120603     IF ARRAC005-PROV-PREC = 'FO'                                 00104100
120603        MOVE 'FC'                      TO ARRAC005-PROV-PREC      00104200
120603     ELSE                                                         00104300
120603        IF ARRAC005-PROV-PREC = 'PS'                              00104400
120603           MOVE 'PU'                   TO ARRAC005-PROV-PREC      00104500
120603        END-IF                                                    00104600
120603     END-IF.                                                      00104700
120603     IF ARRAC005-PROV-NASCITA = 'FO'                              00104800
120603        MOVE 'FC'                      TO ARRAC005-PROV-NASCITA   00104900
120603     ELSE                                                         00105000
120603        IF ARRAC005-PROV-NASCITA = 'PS'                           00105100
120603           MOVE 'PU'                   TO ARRAC005-PROV-NASCITA   00105200
120603        END-IF                                                    00105300
120603     END-IF.                                                      00105400
120603     IF ARRAC005-PROV-RIL = 'FO'                                  00105500
120603        MOVE 'FC'                      TO ARRAC005-PROV-RIL       00105600
120603     ELSE                                                         00105700
120603        IF ARRAC005-PROV-RIL = 'PS'                               00105800
120603           MOVE 'PU'                   TO ARRAC005-PROV-RIL       00105900
120603        END-IF                                                    00106000
120603     END-IF.                                                      00106100
                                                                        00106200
           WRITE REC-AFFIDA      FROM     ARRAC005.                     00106300
                                                                        00106400
           ADD 1 TO W-CTR-SCRITTI.                                      00106500
                                                                        00106600
           IF W-STATO1 NOT EQUAL ZERO                                   00106700
              DISPLAY 'ERRORE SCRITTURA FILE ENTE' W-STATO1             00106800
              DISPLAY 'LABEL 02010-SCRIVI-AFFIDA'                       00106900
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00107000
           END-IF.                                                      00107100
       02010-EX. EXIT.                                                  00107200
      ***************************************************************** 00107300
      *   ACCESSO ALLA TABELLA DB2 SCTBTSET (SETTORE PRODUTTIVO)      * 00107400
      ***************************************************************** 00107500
       02011-ACCESSO-TSET.                                              00107600
                                                                        00107710
           INITIALIZE STRINGA-CONDIZIONI                                00107720
                      NUMERO-NO-COMP                                    00107730
                      C6SP01A-DSVAL-OUT(IND-COND).                      00107750
                                                                        00107760
      * MOVE PER LA STRINGA DI CONDIZZIONI.                             00107770
           MOVE TRIC-SERVIZIO         TO W-SERVIZIO-RAPPORTO.           00107780
           MOVE TRIC-CATEGORIA        TO W-CATEGORIA-RAPPORTO.          00107790
           MOVE TRIC-FILIALE          TO W-FILIALE-RAPPORTO.            00107791
           MOVE TRIC-NUMERO           TO NUMERO-NO-COMP.                00107792
           MOVE NUMERO-NO-COMP        TO W-NUMERO-RAPPORTO.             00107793
                                                                        00107801
           MOVE 'CC '                 TO C6SP01A-CDSERBAN.              00107802
           MOVE '3'                   TO C6SP01A-CDTPENT.               00107803
           MOVE STRINGA-CONDIZIONI    TO C6SP01A-CDENTITA.              00107804
           MOVE W-DATA-ELAB-RED       TO C6SP01A-DTINIRIC.              00107805
           MOVE W-DATA-ELAB-RED       TO C6SP01A-DTFINRIC.              00107806
           MOVE '1'                   TO C6SP01A-CDUTIREG.              00107807
           MOVE '0'                   TO C6SP01A-CDUTISPR.              00107808
           MOVE SPACES                TO C6SP01A-CDQUALIT.              00107809
           MOVE  0                    TO C6SP01A-NRDIMENS.              00107810
           MOVE '0'                   TO C6SP01A-CDTPRICH.              00107811
           MOVE 'S'                   TO C6SP01A-CDTPLST.               00107812
           MOVE 'SCSP'                TO C6SP01A-CDLISTA.               00107813
           MOVE SPACES                TO C6SP01A-DSCDZBR.               00107814
           MOVE SPACES                TO C6SP01A-DSLEGBR.               00107815
           MOVE '00000'               TO C6SP01A-CDISTITU.              00107816
                                                                        00107817
           CALL 'C6SP01AB'            USING  W-C6AP01AS.                00107818
                                                                        00107819
           IF C6SP01A-CDESITO = '0000'                                  00107820
                                                                        00107821
              MOVE C6SP01A-ELDIMOUT-OUT        TO IND-COND              00107822
                                                                        00107823
              IF IND-COND > 1                                           00107824
                 DISPLAY 'RISULTANO PIU OCCORRENZE SUL CONTO'           00107825
                 DISPLAY 'NUMERO CONTO ..: ' NUMERO-NO-COMP             00107826
                 PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX      00107827
              ELSE                                                      00107829
                 MOVE C6SP01A-NRVAL-OUT(IND)   TO APPO-NRVAL-OUT-S      00107832
                 MOVE APPO-NRVAL-OUT-S         TO APPO-NRVAL-OUT        00107833
              END-IF                                                    00107835
                                                                        00107836
           ELSE                                                         00107839
              DISPLAY 'ERRORE CHIAMATA CONDIZIONI '                     00107840
              MOVE C6SP01A-DSERTEXT-BREVE      TO DESCRIZIONE           00107841
              DISPLAY DESCRIZIONE                                       00107842
              DISPLAY 'SERVIZIO : ' TRIC-SERVIZIO                       00107843
              DISPLAY 'FILIALE: ' TRIC-FILIALE                          00107844
              DISPLAY 'NUMERO: ' NUMERO-NO-COMP                         00107845
              DISPLAY ' '                                               00107846
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00107847
           END-IF.                                                      00107848
                                                                        00107849
                                                                        00107863
           MOVE  ZEROES                     TO IND-COND.                00107864
                                                                        00107865
       02011-EX.                                                        00109000
           EXIT.                                                        00109100
      ***************************************************************** 00109200
      *  ROUTINE DI AGGIORNAMENTO DEL DB DELLE RICHIESTE              * 00109300
      ***************************************************************** 00109400
       02050-AGGIORNA-RICHIESTE.                                        00109500
           MOVE  TDAT-BATCH       TO   TRIC-DT-INV-ENT.                 00109600
           MOVE  W-NOME-PGM       TO   TRIC-COD-OPER.                   00109700
           MOVE  SPACES           TO   TRIC-COD-ANOM.                   00109800
           MOVE  SPACES           TO   TRIC-ESITO.                      00109900
           MOVE  ZEROES           TO   TRIC-DT-RIS-ENT.                 00110000
           MOVE  ZEROES           TO   TRIC-NUM-PROT.                   00110100
           MOVE  SPACES           TO   TRIC-TIPO-PROT.                  00110200
           MOVE  SPACES           TO   TRIC-BAD-CUST.                   00110300
      *                                                                 00110400
           EXEC SQL INCLUDE RIC001UP END-EXEC.                          00110500
      *                                                                 00110600
           INITIALIZE W-SQLCODE1.                                       00110700
           MOVE SQLCODE TO W-SQLCODE1.                                  00110800
           IF W-SQLCODE1 = 100                                          00110900
              DISPLAY 'LABEL 02050-AGGIORNA-RICHIESTE'                  00111000
              DISPLAY 'OCCORRENZA NON TROVATA SU TABELLA TRIC'          00111100
              GO TO 02050-EX                                            00111200
           END-IF.                                                      00111300
           IF W-SQLCODE1 NOT EQUAL 0 AND 100                            00111400
              DISPLAY 'LABEL 02050-AGGIORNA-RICHIESTE'                  00111500
              DISPLAY 'ERRORE UPDATE SU TRIC '     W-SQLCODE1           00111600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00111700
           END-IF.                                                      00111800
       02050-EX.                                                        00111900
           EXIT.                                                        00112000
      ***************************************************************** 00112100
      *      ROUTINE DI INSERIMENTO PROGRESSIVO  TAB TTAP             * 00112200
      *      E DI SCRITTURA RECORD TAPPO      -- AFFIDATI --          * 00112300
      ***************************************************************** 00112400
       02075-INS-PROG-AFF.                                              00112500
      *                                                                 00112600
           INITIALIZE W-TTAP-PROGR.                                     00112700
      *                                                                 00112800
           ADD  1                 TO     W-CTR-RS.                      00112900
           MOVE W-AFF-TTAP-PROGR  TO     TTAP-PROGR                     00113000
                                         W-TTAP-PROGR.                  00113100
           MOVE TDAT-BATCH        TO     TTAP-DT-INVIO                  00113200
                                         W-TTAP-DT-INVIO.               00113300
      *                                                                 00113400
           MOVE '01'              TO     TTAP-TIP-REC.                  00113500
251000*    MOVE 00                TO     W-TTAP-TIP-REC.                00113600
251000     MOVE 99                TO     W-TTAP-TIP-REC.                00113700
           ADD  1                 TO     TTAP-PROGR                     00113800
                                         W-TTAP-PROGR.                  00113900
           MOVE W-CTR-RS          TO     TTAP-N-REC-TOT                 00114000
                                         W-TTAP-N-REC-TOT.              00114100
           MOVE ZERO              TO     TTAP-SALDID-ITL                00114200
                                         W-TTAP-SALDID-ITL.             00114300
           MOVE ZERO              TO     TTAP-SALDIA-ITL                00114400
                                         W-TTAP-SALDIA-ITL.             00114500
           MOVE ZERO              TO     TTAP-SALDID-EUR                00114600
                                         W-TTAP-SALDID-EUR.             00114700
           MOVE ZERO              TO     TTAP-SALDIA-EUR                00114800
                                         W-TTAP-SALDIA-EUR.             00114900
      *                                                                 00115000
           EXEC SQL INCLUDE TAP001IN  END-EXEC.                         00115100
      *                                                                 00115200
           IF SQLCODE NOT = 0                                           00115300
              MOVE SQLCODE TO W-SQLCODE                                 00115400
              DISPLAY 'LABEL   :  02075-INS-PROG-AFF '                  00115500
              DISPLAY 'ERRORE ' W-SQLCODE ' SU ACCESSO DB2 TTAP'        00115600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00115700
           END-IF.                                                      00115800
      *                                                                 00115900
           WRITE REC-AFFIDA      FROM    W-TTAP.                        00116000
      *                                                                 00116100
       02075-EX. EXIT.                                                  00116200
      ****************************************************************  00116300
      *  ROUTINE DI SCRITTURA RECORD PER FLUSSO ENTE                 *  00116400
      ****************************************************************  00116500
       07100-SCRIVI-VAR-ANAG.                                           00116600
      *                                                                 00116700
           INITIALIZE  ARRAC006.                                        00116800
      *                                                                 00116900
020201*    ADD  1                          TO W-CTR-V2.                 00117000
           MOVE '02'                       TO ARRAC006-TIPO-REC.        00117100
           MOVE TRIC-NDG-PF                TO ARRAC006-NDG.             00117200
           MOVE L-ACS108-COGNOME           TO ARRAC006-COGNOME.         00117300
           MOVE L-ACS108-NOME              TO ARRAC006-NOME.            00117400
           MOVE L-ACS108-NAT-GIURIDICA     TO ARRAC006-NAT-GIURIDICA.   00117500
           MOVE L-ACS108-COD-FISCALE       TO ARRAC006-COD-FISCALE.     00117600
151100*    MOVE TANG-COM-RIL               TO ARRAC006-COM-RIL.         00117700
151100     MOVE TANG-COM-RIL               TO WS-COMRIL.                00117800
151100     PERFORM 11000-VALORIZZA-COMRIL THRU 11000-EX.                00117900
191200     MOVE WS-COMRIL1 TO ARRAC006-COM-RIL.                         00118000
           IF TRIC-NDG-COI = TRIC-NDG-PF                                00118100
              MOVE SPACES TO ARRAC006-PROV-RIL                          00118200
           ELSE                                                         00118300
              MOVE TANG-PROV-RIL           TO ARRAC006-PROV-RIL         00118400
           END-IF.                                                      00118500
           IF TANG-PROV-RIL = 'EE'                                      00118600
              MOVE TANG-COM-RIL TO WS-ENTE2                             00118700
              PERFORM 90000-CONTROLLA-NAZ THRU 90000-EX                 00118800
              MOVE ARRAC005-NAZ-RIL        TO ARRAC006-NAZ-RIL          00118900
010905        IF ARRAC006-COM-RIL = 'REPUBBLICA DI SAN MARINO'          00118910
010905           CONTINUE                                               00118920
010905        ELSE                                                      00118930
                 MOVE SPACES                  TO ARRAC006-COM-RIL       00119000
              END-IF                                                    00119010
           ELSE                                                         00119100
              MOVE SPACES                  TO ARRAC006-NAZ-RIL          00119200
           END-IF.                                                      00119300
           MOVE TANG-TEL1                  TO ARRAC006-TEL1.            00119400
           MOVE TANG-TEL2                  TO ARRAC006-TEL2.            00119500
AD         IF TANG-TEL2 = SPACES OR LOW-VALUE OR ZERO                   00119510
AD            MOVE '9999'        TO        ARRAC006-TEL2                00119520
AD         END-IF.                                                      00119530
      * DATI PROVENIENTI DA ANAGRAFE                                    00119600
           IF TRIC-NDG-COI NOT EQUAL TRIC-NDG-PF                        00119700
              MOVE SPACES                  TO ARRAC006-INT-RIDOTTA      00119800
           ELSE                                                         00119900
              MOVE L-ACS108-RAGSOC         TO ARRAC006-INT-RIDOTTA      00120000
050702        INSPECT ARRAC006-INT-RIDOTTA REPLACING ALL '-' BY SPACES  00120100
           END-IF.                                                      00120200
           MOVE L-ACS108-COGNOME           TO ARRAC006-COGNOME.         00120300
           MOVE L-ACS108-NOME              TO ARRAC006-NOME.            00120400
           MOVE L-ACS108-NAT-GIURIDICA     TO ARRAC006-NAT-GIURIDICA.   00120500
           MOVE L-ACS108-COD-FISCALE       TO ARRAC006-COD-FISCALE.     00120600
010900*    MOVE TANG-IND-RES               TO ARRAC005-IND-SEDE-LEG.    00120700
010900     MOVE L-ACS108-IND-SEDE-LEG      TO ARRAC006-IND-SEDE-LEG.    00120800
           IF TANG-LOC-RES NOT = SPACES AND LOW-VALUE                   00120900
              PERFORM 10050-ACCESSO-TDCO THRU 10050-EX                  00121000
              MOVE TANG-LOC-RES            TO WS-COMUNE                 00121100
              PERFORM 10000-VALORIZZA-COMUNE THRU 10000-EX              00121200
              MOVE ARRAC005-LOC-SEDE-LEG   TO ARRAC006-LOC-SEDE-LEG     00121300
010900        MOVE TDCO-CAP                TO ARRAC006-CAP-SEDE-LEG     00121400
              MOVE TDCO-PROV               TO ARRAC006-PROV-SEDE-LEG    00121500
           ELSE                                                         00121600
              MOVE L-ACS108-LOC-SEDE-LEG   TO WS-COMUNE                 00121700
              PERFORM 10000-VALORIZZA-COMUNE THRU 10000-EX              00121800
              MOVE ARRAC005-LOC-SEDE-LEG   TO ARRAC006-LOC-SEDE-LEG     00121900
010900        MOVE L-ACS108-CAP-SEDE-LEG   TO ARRAC006-CAP-SEDE-LEG     00122000
              MOVE L-ACS108-PROV-SEDE-LEG  TO ARRAC006-PROV-SEDE-LEG    00122100
           END-IF.                                                      00122200
           MOVE L-ACS108-NAZ-SEDE-LEG      TO WS-COD-TNAZ.              00122300
           IF WS-COD2-TNAZ = SPACE                                      00122400
              IF WS-COD1-TNAZ IS NUMERIC                                00122500
                 MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                     00122600
                 MOVE WS-CODICE-NAZ TO ARRAC006-NAZ-SEDE-LEG            00122700
              ELSE                                                      00122800
                 MOVE WS-COD1-TNAZ TO ARRAC006-NAZ-SEDE-LEG             00122900
              END-IF                                                    00123000
           ELSE                                                         00123100
              MOVE WS-COD-TNAZ TO ARRAC006-NAZ-SEDE-LEG                 00123200
           END-IF.                                                      00123300
           MOVE L-ACS108-COD-DOC           TO ARRAC006-COD-DOC.         00123400
           MOVE L-ACS108-DT-RIL-DOC        TO ARRAC006-DT-RIL-DOC.      00123500
      *                                                                 00123600
           PERFORM 02020-CODIFICA-DOCUMENTI THRU 02020-EX.              00123700
      *                                                                 00123800
010900     MOVE ARRAC005-TIPO-DOC          TO ARRAC006-TIPO-DOC.        00123900
111200     MOVE L-ACS108-SESSO             TO ARRAC006-SESSO.           00124000
151200     MOVE L-ACS108-DATA-NASC-COS     TO ARRAC006-DATA-NASCITA.    00124100
280201     MOVE L-ACS108-NAZ-NASCITA       TO WS-COD-TNAZ.              00124200
111200*    IF L-ACS108-PROV-NASCITA = SPACES                            00124300
280201     IF WS-COD-TNAZ NOT = SPACES AND LOW-VALUE                    00124400
111200        MOVE 'EE' TO ARRAC006-PROV-NASCITA                        00124500
111200        MOVE SPACES TO ARRAC006-COM-NASCITA                       00124600
111200*       MOVE L-ACS108-NAZ-NASCITA TO ARRAC006-NAZ-NASCITA         00124700
111200     ELSE                                                         00124800
111200        MOVE SPACES TO ARRAC006-NAZ-NASCITA                       00124900
111200        MOVE L-ACS108-PROV-NASCITA TO ARRAC006-PROV-NASCITA       00125000
111200*       MOVE L-ACS108-LUOGO-NASCITA TO ARRAC006-COM-NASCITA       00125100
050201        MOVE L-ACS108-LUOGO-NASCITA TO WS-LOCNASC                 00125200
050201        PERFORM 11050-VALORIZZA-LOCNASC THRU 11050-EX             00125300
050201        MOVE ARRAC005-LUOGO-NASCITA TO ARRAC006-COM-NASCITA       00125400
111200     END-IF.                                                      00125500
           IF WS-COD2-TNAZ = SPACE                                      00125600
              IF WS-COD1-TNAZ IS NUMERIC                                00125700
                 MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                     00125800
                 MOVE WS-CODICE-NAZ TO ARRAC006-NAZ-NASCITA             00125900
              ELSE                                                      00126000
                 MOVE WS-COD1-TNAZ TO ARRAC006-NAZ-NASCITA              00126100
              END-IF                                                    00126200
           ELSE                                                         00126300
              MOVE WS-COD-TNAZ TO ARRAC006-NAZ-NASCITA                  00126400
           END-IF.                                                      00126500
      *                                                                 00126600
291102     IF ARRAC006-NAZ-SEDE-LEG = '0800'                            00126700
291102        MOVE SPACES                  TO ARRAC006-LOC-SEDE-LEG     00126800
291102        MOVE 'REPUBBLICA DI SAN MARINO'                           00126900
291102                                     TO ARRAC006-LOC-SEDE-LEG     00127000
291102     END-IF.                                                      00127100
      *                                                                 00127200
120603     IF ARRAC006-PROV-SEDE-LEG = 'FO'                             00127300
120603        MOVE 'FC'                      TO ARRAC006-PROV-SEDE-LEG  00127400
120603     ELSE                                                         00127500
120603        IF ARRAC006-PROV-SEDE-LEG = 'PS'                          00127600
120603           MOVE 'PU'                   TO ARRAC006-PROV-SEDE-LEG  00127700
120603        END-IF                                                    00127800
120603     END-IF.                                                      00127900
120603     IF ARRAC006-PROV-RIL = 'FO'                                  00128000
120603        MOVE 'FC'                      TO ARRAC006-PROV-RIL       00128100
120603     ELSE                                                         00128200
120603        IF ARRAC006-PROV-RIL = 'PS'                               00128300
120603           MOVE 'PU'                   TO ARRAC006-PROV-RIL       00128400
120603        END-IF                                                    00128500
120603     END-IF.                                                      00128600
120603     IF ARRAC006-PROV-NASCITA = 'FO'                              00128700
120603        MOVE 'FC'                      TO ARRAC006-PROV-NASCITA   00128800
120603     ELSE                                                         00128900
120603        IF ARRAC006-PROV-NASCITA = 'PS'                           00129000
120603           MOVE 'PU'                   TO ARRAC006-PROV-NASCITA   00129100
120603        END-IF                                                    00129200
120603     END-IF.                                                      00129300
      *                                                                 00129400
           WRITE REC-VARIANG     FROM     ARRAC006.                     00129500
      *                                                                 00129600
           IF W-STATO2 NOT EQUAL ZERO                                   00129700
              DISPLAY 'ERRORE ' W-STATO2 ' SU SCRITTURA FILE VARIANG '  00129800
              DISPLAY 'LABEL 07100-SCRIVI-VAR-ANAG '                    00129900
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00130000
           END-IF.                                                      00130100
      *                                                                 00130200
           INITIALIZE ARRAC005.                                         00130300
                                                                        00130400
           ADD 1 TO W-CTR-SCRITTI.                                      00130500
                                                                        00130600
       07100-EX. EXIT.                                                  00130700
      ****************************************************************  00130800
       07200-SCRIVI-V1-A3-D3-R3.                                        00130900
                                                                        00131000
           INITIALIZE  ARRAC008.                                        00131100
                                                                        00131200
           IF TRIC-TIP-ATTIV = 'V1'                                     00131300
              MOVE '03'                    TO ARRAC008-TIPO-REC         00131400
           ELSE                                                         00131500
              MOVE TRIC-TIP-ATTIV          TO ARRAC008-TIPO-REC         00131600
           END-IF.                                                      00131700
           MOVE TRIC-NDG-PF                TO ARRAC008-NDG.             00131800
           MOVE TRIC-SERVIZIO              TO ARRAC008-SERVIZIO.        00131900
           MOVE TRIC-CATEGORIA             TO ARRAC008-CATEGORIA.       00132000
           MOVE TRIC-FILIALE               TO ARRAC008-FILIALE.         00132100
           MOVE TRIC-NUMERO                TO ARRAC008-NUMERO.          00132200
           MOVE TRIC-NDG-COI               TO ARRAC008-NDG-COI.         00132300
           MOVE L-ACS108-NAT-GIURIDICA     TO ARRAC008-NAT-GIURIDICA.   00132400
           IF TRIC-TIP-ATTIV = 'R3'                                     00132500
              ADD 1                        TO W-CTR-R3                  00132600
              MOVE SPACES                  TO ARRAC008-FLAG-STIP        00132700
              MOVE SPACES                  TO ARRAC008-SETT-PROD        00132800
              MOVE SPACES                  TO ARRAC008-COD-AFF          00132900
              MOVE ZEROES                  TO ARRAC008-STIPENDIO        00133000
              MOVE SPACES                  TO ARRAC008-DIV-STIP         00133100
           ELSE                                                         00133200
              MOVE TRIC-ACCR-STIP          TO ARRAC008-FLAG-STIP        00133300
      ***********************************************************       00133400
      * IL SEGUENTE CONTROLLO E' STATO AGGIUNTO PER PASSARE A   *       00133500
      * A ZERO L' IMPORTO DELLO STIPENDIO PER QUEI RAPPORTI CHE *       00133600
      * PRESENTANO ACCREDITO NEGATIVO                           *       00133700
      ***********************************************************       00133800
              IF TRIC-ACCR-STIP = 'N'                                   00133900
                 MOVE ZEROES               TO ARRAC008-STIPENDIO        00134000
              ELSE                                                      00134100
                 MOVE TRIC-IMP-STIP        TO ARRAC008-STIPENDIO        00134200
              END-IF                                                    00134300
                                                                        00134310
              PERFORM 02011-ACCESSO-TSET   THRU 02011-EX                00134400
                                                                        00134410
              MOVE COD-PRODOTTO            TO TRIC-SETT-PROD            00134520
                                                                        00134530
              MOVE TRIC-SETT-PROD          TO ARRAC008-SETT-PROD        00134540
      *---------------------------------------------------------------- 00135010
      *-----> A T T E N Z I O N E !!! <-------------------------------- 00135020
      *---------------------------------------------------------------- 00135030
      * QUESTA MODIFICA DOVRA' ESSERE TOLTA QUANDO DB SARA' PRONTA A    00135040
      * RICEVERE IL SETTORE PRODUTTIVO ANCHE SUL REC. DI COINTESTAZIONE 00135050
      *---------------------------------------------------------------- 00135060
      *       IF TRIC-NDG-COI = TRIC-NDG-PF                             00135070
      *          MOVE SPACES               TO ARRAC008-SETT-PROD        00135080
      **         MOVE SPACES               TO TRIC-SETT-PROD            00135081
      *       END-IF                                                    00135090
      *---------------------------------------------------------------- 00135091
              MOVE TRIC-COD-AFF            TO ARRAC008-COD-AFF          00135100
              MOVE TRIC-DIV-STIP           TO ARRAC008-DIV-STIP         00135300
           END-IF.                                                      00135400
           MOVE ZEROES                     TO ARRAC008-DT-REVOCA.       00135500
           IF  TRIC-TIP-ATTIV = 'V1'                                    00135600
           AND TRIC-DT-ATT-ESTINZ NOT = ZERO                            00135700
               MOVE TRIC-DT-ATT-ESTINZ     TO ARRAC008-DT-REVOCA        00136500
               MOVE ZEROES                 TO TRIC-DT-ATT-ESTINZ        00136600
           END-IF.                                                      00136700
                                                                        00136800
           WRITE REC-VARIASCC    FROM     ARRAC008.                     00136900
                                                                        00137000
           IF W-STATO3 NOT EQUAL ZERO                                   00137100
              DISPLAY 'ERRORE ' W-STATO3 ' SU SCRITTURA FILE VARIASCC ' 00137200
              DISPLAY 'LABEL 07200-SCRIVI-V1-A3-D3-R3 '                 00137300
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00137400
           END-IF.                                                      00137500
                                                                        00137600
           ADD 1 TO W-CTR-SCRITTI.                                      00137700
                                                                        00137800
       07200-EX. EXIT.                                                  00137900
      ***************************************************************** 00138000
      *      ROUTINE DI INSERIMENTO PROGRESSIVO  TAB TTAP             * 00138100
      *      E DI SCRITTURA RECORD TAPPO      -- VARIAZIONI ANAG --   * 00138200
      ***************************************************************** 00138300
       07175-INS-PROG-VAR-ANAG.                                         00138400
                                                                        00138500
           INITIALIZE W-TTAP-PROGR.                                     00138600
                                                                        00138700
           MOVE W-VANG-TTAP-PROGR TO     TTAP-PROGR                     00138800
                                         W-TTAP-PROGR.                  00138900
           ADD  1                 TO     W-CTR-V2.                      00139000
                                                                        00139100
           MOVE TDAT-BATCH        TO     TTAP-DT-INVIO.                 00139200
                                                                        00139300
           MOVE '02'              TO     TTAP-TIP-REC.                  00139400
           MOVE 99                TO     W-TTAP-TIP-REC.                00139600
           ADD  1                 TO     TTAP-PROGR                     00139700
                                         W-TTAP-PROGR.                  00139800
           MOVE W-CTR-V2          TO     TTAP-N-REC-TOT                 00139900
                                         W-TTAP-N-REC-TOT.              00140000
           MOVE ZERO              TO     TTAP-SALDID-ITL                00140100
                                         W-TTAP-SALDID-ITL.             00140200
           MOVE ZERO              TO     TTAP-SALDIA-ITL                00140300
                                         W-TTAP-SALDIA-ITL.             00140400
           MOVE ZERO              TO     TTAP-SALDID-EUR                00140500
                                         W-TTAP-SALDID-EUR.             00140600
           MOVE ZERO              TO     TTAP-SALDIA-EUR                00140700
                                         W-TTAP-SALDIA-EUR.             00140800
                                                                        00140900
           EXEC SQL INCLUDE TAP001IN  END-EXEC.                         00141000
                                                                        00141100
           IF SQLCODE NOT = 0                                           00141200
              MOVE SQLCODE TO W-SQLCODE                                 00141300
              DISPLAY 'LABEL   :  07175-INS-PROG-VAR-ANAG '             00141400
              DISPLAY 'ERRORE ' W-SQLCODE ' SU ACCESSO DB2 TTAP '       00141500
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00141600
           END-IF.                                                      00141700
                                                                        00141800
           WRITE REC-VARIANG     FROM    W-TTAP.                        00141900
                                                                        00142000
           ADD 1 TO W-CTR-SCRITTI.                                      00142100
                                                                        00142200
       07175-EX. EXIT.                                                  00142300
      ***************************************************************** 00142400
       07275-INS-PROG-VAR-SCOP.                                         00142500
                                                                        00142600
           INITIALIZE W-TTAP-PROGR.                                     00142700
                                                                        00142800
           COMPUTE W-CTR-V-A-D-R =                                      00142900
             (W-CTR-V1) + (W-CTR-A3) + (W-CTR-D3) + (W-CTR-R3)          00143000
             + (W-CTR-E3) + 1.                                          00143100
                                                                        00143200
           MOVE W-VSCC-TTAP-PROGR TO     TTAP-PROGR                     00143300
                                         W-TTAP-PROGR.                  00143400
                                                                        00143500
           MOVE TDAT-BATCH        TO     TTAP-DT-INVIO.                 00143600
                                                                        00143700
           MOVE '03'              TO     TTAP-TIP-REC.                  00143800
           MOVE 99                TO     W-TTAP-TIP-REC.                00144000
           ADD  1                 TO     TTAP-PROGR                     00144100
                                         W-TTAP-PROGR.                  00144200
           MOVE W-CTR-V-A-D-R     TO     TTAP-N-REC-TOT                 00144300
                                         W-TTAP-N-REC-TOT.              00144400
           MOVE ZERO              TO     TTAP-SALDID-ITL                00144500
                                         W-TTAP-SALDID-ITL.             00144600
           MOVE ZERO              TO     TTAP-SALDIA-ITL                00144700
                                         W-TTAP-SALDIA-ITL.             00144800
           MOVE ZERO              TO     TTAP-SALDID-EUR                00144900
                                         W-TTAP-SALDID-EUR.             00145000
           MOVE ZERO              TO     TTAP-SALDIA-EUR                00145100
                                         W-TTAP-SALDIA-EUR.             00145200
                                                                        00145300
           EXEC SQL INCLUDE TAP001IN  END-EXEC.                         00145400
                                                                        00145500
           IF SQLCODE NOT = 0                                           00145600
              MOVE SQLCODE TO W-SQLCODE                                 00145700
              DISPLAY 'LABEL   :  07275-INS-PROG-VAR-SCOP'              00145800
              DISPLAY 'ERRORE ' W-SQLCODE ' SU ACCESSO DB2 TTAP '       00145900
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00146000
           END-IF.                                                      00146100
                                                                        00146200
           WRITE REC-VARIASCC    FROM    W-TTAP.                        00146300
                                                                        00146400
           ADD 1 TO W-CTR-SCRITTI.                                      00146500
           ADD 1 TO W-CTR-V1.                                           00146600
                                                                        00146700
           IF W-STATO3 NOT EQUAL '00'                                   00146800
              DISPLAY 'LABEL 07275-VARIASCC'                            00146900
              DISPLAY 'ERRORE ' W-STATO3 ' SU CHIUSURA VARIASCC'        00147000
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00147100
           END-IF.                                                      00147200
                                                                        00147300
       07275-EX. EXIT.                                                  00147400
      ***************************************************************** 00147500
      *********        GESTIONE DELLE STATISTICHE            ********** 00147600
      ***************************************************************** 00147700
       77777-STATISTICHE.                                               00147800
           COMPUTE W-CTR-V-A-D-R = W-CTR-V-A-D-R + W-CTR-V2.            00147900
           COMPUTE W-CTR-TOT = W-CTR-LETTI + W-CTR-LETTI1.              00148000
              DISPLAY '*------------------------------------------*'    00148100
              DISPLAY '*  STATISTICHE NUMERO DI RECORD TRATTATI   *'    00148200
              DISPLAY '* (TOTALI COMPRENSIVI DI RECORD DI TESTA)  *'    00148300
              DISPLAY '*------------------------------------------*'    00148400
              DISPLAY '*TOT.REC. LETTI___________: ' W-CTR-TOT          00148500
              DISPLAY '*TOT.REC. SCRITTI_________: ' W-CTR-SCRITTI      00148600
              DISPLAY '*TOT.REC. ATTIVAZIONE_____: ' W-CTR-RS           00148700
              DISPLAY '*------------------------------------------*'    00148800
              DISPLAY '*TOT.REC. VARIAZIONE______: ' W-CTR-V-A-D-R      00148900
              DISPLAY '*DI CUI:                                   *'    00149000
              DISPLAY '*------------------------------------------*'    00149100
              DISPLAY '*         VAR. ANAGRAFE___: ' W-CTR-V2           00149200
              DISPLAY '*         VAR. NON ANAGR._: ' W-CTR-V1           00149300
              DISPLAY '*         AUMENTI_________: ' W-CTR-A3           00149400
              DISPLAY '*         DIMINUZIONI_____: ' W-CTR-D3           00149500
              DISPLAY '*         ESTINZIONI______: ' W-CTR-R3           00149600
              DISPLAY '*         BLOCCATI________: ' W-CTR-E3           00149700
              DISPLAY '*------------------------------------------*'.   00149800
              DISPLAY '*REC.SCRITTI IN SCTBTINV__: ' W-CTR-SCRITTI-INV. 00149900
              DISPLAY '*------------------------------------------*'.   00150000
       77777-EX. EXIT.                                                  00150100
      ***************************************************************** 00150200
      *     ROUTINE DI GESTIONE ERRORE                                * 00150300
      ***************************************************************** 00150400
       99999-GEST-ABEND.                                                00150500
                                                                        00150600
            MOVE 'ILBOABN0'  TO  W-PROGRAM.                             00150700
                                                                        00150800
            CALL W-PROGRAM  USING  COMP-CODE.                           00150900
                                                                        00151000
       99999-GEST-ABEND-EX.                                             00151100
           EXIT.                                                        00151200
      ******************************************************************00151300
      *                                                                 00151400
      ******************************************************************00151500
       02020-CODIFICA-DOCUMENTI.                                        00151600
                                                                        00151800
      *TABELLA DOCUMENTI PRESSO POSTE ITALIANE     COD. DOC. DEUTSCHE   00151900
                                                                        00152000
      * CIE    CARTA IDENTITA'  ESTERA                          NO      00152100
      * CIP    CARTA D'IDENTITA'                                1       00152200
      * CIT    CARTA D'IDENTITA' DI TERZI                       NO      00152300
      ***** DAC    DOC. RIC. AMBASCIATE E CONSOLATI ITALIANI        9   00152400
      * DAC    DOC. RIC. AMBASCIATE E CONSOLATI ITALIANI        6       00152500
      * DET    FOGLIO MATRICOLARE RIL. AUTORITA' CARCERARIE     NO      00152600
      ***** LCI    LIBRETTO CIECHI ED INVALIDI                      9   00152700
      * LCI    LIBRETTO CIECHI ED INVALIDI                      6       00152800
      ***** LNM    LIB. NOMINATIVO PER MINORATI CIVILI MOD 4-A.P.   9   00152900
      * LNM    LIB. NOMINATIVO PER MINORATI CIVILI MOD 4-A.P.   6       00153000
      ***** LPI    LIB. PENS. INPS                                  9   00153100
      * LPI    LIB. PENS. INPS                                  6       00153200
      * PAP    PATENTE. GUIDA                                   3       00153300
      * PAT    PATENTE DI TERZI                                 NO      00153400
      * PDP    PORTO D'ARMI                                     4       00153500
      * PDT    PORTO D'ARMI DI TERZI                            NO      00153600
      * PDS    PERMESSO SOGG. STRANIERI                         NO      00153700
      * PSE    PASSAPORTO ESTERO                                2       00153800
      * PSP    PASSAPORTO                                       2       00153900
      * PST    PASSAPORTO DI TERZI                              NO      00154000
      * TPT    TESSERA RICONOSCIMENTO DIP. POSTE ITALIANE       5       00154100
      * TSM    TES. DIP STATALI CIVILI MILITARI                 6       00154200
                                                                        00154300
           IF  L-ACS108-TIPO-DOC = 'CIP' OR 'CIE'                       00154400
               MOVE 1  TO ARRAC005-TIPO-DOC                             00154500
               GO TO 02020-EX.                                          00154600
                                                                        00154700
           IF  L-ACS108-TIPO-DOC = 'PSE' OR 'PSP'                       00154800
               MOVE 2  TO ARRAC005-TIPO-DOC                             00154900
               GO TO 02020-EX.                                          00155000
                                                                        00155100
           IF  L-ACS108-TIPO-DOC = 'PAP'                                00155200
               MOVE 3  TO ARRAC005-TIPO-DOC                             00155300
               GO TO 02020-EX.                                          00155400
                                                                        00155500
           IF  L-ACS108-TIPO-DOC = 'PDP'                                00155600
               MOVE 4  TO ARRAC005-TIPO-DOC                             00155700
               GO TO 02020-EX.                                          00155800
                                                                        00155900
           IF  L-ACS108-TIPO-DOC = 'TPT'                                00156000
               MOVE 5  TO ARRAC005-TIPO-DOC                             00156100
               GO TO 02020-EX.                                          00156200
                                                                        00156300
           IF  L-ACS108-TIPO-DOC = 'TSM'                                00156400
           OR 'DAC' OR 'LCI' OR 'LNM' OR 'LPI'                          00156500
               MOVE 6  TO ARRAC005-TIPO-DOC                             00156600
               GO TO 02020-EX.                                          00156700
                                                                        00156800
           MOVE 9  TO ARRAC005-TIPO-DOC.                                00156900
                                                                        00157000
               GO TO 02020-EX.                                          00157100
       02020-EX. EXIT.                                                  00157200
      ***************************************************************** 00157300
      * ROUTINE CHE SI OCCUPA DI CONTROLLARE L' ESISTENZA DI RECORD   * 00157400
      * SULLA TABELLA SCTBTTAP IN CASO DI RICICLO PER DATA-RICHIESTA  * 00157500
      * IMPOSTATA.                                                    * 00157600
      ***************************************************************** 00157700
       08000-CERCA-TAPPO.                                               00157800
                                                                        00157900
           EXEC SQL INCLUDE TAP001CF END-EXEC.                          00158000
                                                                        00158100
           MOVE SQLCODE TO W-SQLCODE.                                   00158200
           IF W-SQLCODE EQUAL 0 OR 811                                  00158300
              GO TO 08000-EX                                            00158400
           END-IF.                                                      00158500
           IF W-SQLCODE = 100                                           00158600
              DISPLAY 'LABEL 08000-CERCA-TAPPO'                         00158700
              DISPLAY 'ATTENZIONE NON ESISTONO DATI DA SEGNALARE'       00158800
              DISPLAY 'ALL'' ENTE NELLA DATA UGUALE ALLA'               00158900
              DISPLAY 'DATA RICHIESTA  : ' TDAT-RICHIESTA               00159000
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00159100
           END-IF.                                                      00159200
           IF SQLCODE NOT EQUAL 0 AND 100 AND 811                       00159300
              DISPLAY 'LABEL 08000-CERCA-TAPPO'                         00159400
              DISPLAY 'ERRORE SQL ' W-SQLCODE ' SU SCTBTTAP'            00159500
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00159600
           END-IF.                                                      00159700
                                                                        00159800
           MOVE  DCLSCTBTTAP     TO W-TTAP.                             00159900
                                                                        00160000
           IF TTAP-TIP-REC = '01'                                       00160100
              WRITE REC-AFFIDA      FROM    W-TTAP                      00160200
           END-IF.                                                      00160300
                                                                        00160400
           IF TTAP-TIP-REC = '02'                                       00160500
              WRITE REC-VARIANG     FROM    W-TTAP                      00160600
           END-IF.                                                      00160700
                                                                        00160800
           IF TTAP-TIP-REC = '03'                                       00160900
              WRITE REC-VARIASCC    FROM    W-TTAP                      00161000
           END-IF.                                                      00161100
                                                                        00161200
       08000-EX.                                                        00161300
           EXIT.                                                        00161400
      ***************************************************************** 00161500
       90000-CONTROLLA-NAZ.                                             00161600
           MOVE WS-ENTE2 TO TNAZ-DESCR-EST.                             00161700
           EXEC SQL INCLUDE NAZ001SL END-EXEC.                          00161800
           MOVE SQLCODE TO W-SQLCODE1.                                  00161900
           IF W-SQLCODE1 = 0                                            00162000
              MOVE TNAZ-COD-NAZ TO WS-COD-TNAZ                          00162100
              IF WS-COD2-TNAZ = SPACES                                  00162200
                 IF WS-COD1-TNAZ IS NUMERIC                             00162300
                    MOVE WS-COD1-TNAZ TO WS-CODICE-NAZ                  00162400
                    MOVE WS-CODICE-NAZ TO ARRAC005-NAZ-RIL              00162500
                 ELSE                                                   00162600
                    MOVE WS-COD1-TNAZ TO ARRAC005-NAZ-RIL               00162700
                 END-IF                                                 00162800
              ELSE                                                      00162900
                 MOVE WS-COD-TNAZ TO ARRAC005-NAZ-RIL                   00163000
              END-IF                                                    00163100
                                                                        00163101
              IF ARRAC005-NAZ-RIL = '0664'                              00163110
                 MOVE '0763' TO ARRAC005-NAZ-RIL                        00163120
              END-IF                                                    00163130
                                                                        00163140
              GO TO 90000-EX                                            00163200
           END-IF.                                                      00163300
           IF W-SQLCODE1 = 100                                          00163400
              MOVE SPACES TO ARRAC005-NAZ-RIL                           00163500
              GO TO 90000-EX                                            00163600
           END-IF.                                                      00163700
           IF W-SQLCODE1 NOT EQUAL 0 AND 100                            00163800
              DISPLAY 'LABEL 90000-CONTROLLA-NAZ'                       00163900
              DISPLAY 'ERRORE ' W-SQLCODE1 ' SU SELECT TABELLA TNAZ'    00164000
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00164100
           END-IF.                                                      00164200
       90000-EX.                                                        00164300
           EXIT.                                                        00164400
      ***************************************************************** 00164500
       91000-CERCA-NAZ.                                                 00164600
           MOVE L-ACS108-LOC-SEDE-LEG TO TNAZ-DESCR-EST.                00164700
           EXEC SQL INCLUDE NAZ001SL END-EXEC.                          00164800
           MOVE SQLCODE TO W-SQLCODE2.                                  00164900
           IF W-SQLCODE2 = 0                                            00165000
              MOVE TNAZ-COD-NAZ TO ARRAC006-NAZ-SEDE-LEG                00165100
              GO TO 91000-EX                                            00165200
           END-IF.                                                      00165300
           IF W-SQLCODE2 = 100                                          00165400
              MOVE SPACES TO ARRAC006-NAZ-SEDE-LEG                      00165500
              GO TO 91000-EX                                            00165600
           END-IF.                                                      00165700
           IF W-SQLCODE2 NOT EQUAL 0 AND 100                            00165800
              DISPLAY 'LABEL 91000-CERCA-NAZ'                           00165900
              DISPLAY 'ERRORE ' W-SQLCODE2 ' SU SELECT DB TNAZ'         00166000
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00166100
           END-IF.                                                      00166200
       91000-EX.                                                        00166300
           EXIT.                                                        00166400
      ***************************************************************** 00166500
      * ROUTINE DI VALORIZZAZIONE DEL CAMPO DI OUTPUT DEL COMUNE DI   * 00166600
      * RESIDENZA                                                     * 00166700
      ***************************************************************** 00166800
       10000-VALORIZZA-COMUNE.                                          00166900
           IF WS-COMUNE = 'CITTA'' DEL VATICANO' OR                     00167000
            'STATO DEL VATICANO'                                        00167100
              MOVE 'CITTA'' DEL VATICANO' TO ARRAC005-LOC-SEDE-LEG      00167300
           ELSE                                                         00167400
              MOVE WS-COMUNE            TO ARRAC005-LOC-SEDE-LEG        00167500
           END-IF.                                                      00167600
       10000-EX.                                                        00167700
           EXIT.                                                        00167800
      ***************************************************************** 00167900
      * ROUTINE DI VALORIZZAZIONE DEL CAMPO DI OUTPUT DEL COMUNE DI   * 00168000
      * RILASCIO DOCUMENTO                                            * 00168100
      ***************************************************************** 00168200
       11000-VALORIZZA-COMRIL.                                          00168300
           IF WS-COMRIL = 'CITTA'' DEL VATICANO' OR                     00168400
            'STATO DEL VATICANO'                                        00168500
              MOVE 'CITTA'' DEL VATICANO' TO WS-COMRIL1                 00168700
           ELSE                                                         00168800
              MOVE WS-COMRIL            TO WS-COMRIL1                   00169000
           END-IF.                                                      00169100
       11000-EX.                                                        00169200
           EXIT.                                                        00169300
      ***************************************************************** 00169400
      * ROUTINE DI VALORIZZAZIONE DEL CAMPO DI OUTPUT DEL COMUNE DI   * 00169500
      * NASCITA                                                       * 00169600
      ***************************************************************** 00169700
       11050-VALORIZZA-LOCNASC.                                         00169800
           IF WS-LOCNASC = 'CITTA'' DEL VATICANO' OR                    00169900
            'STATO DEL VATICANO'                                        00170000
              MOVE 'CITTA'' DEL VATICANO' TO ARRAC005-LUOGO-NASCITA     00170100
           ELSE                                                         00170200
              MOVE WS-LOCNASC           TO ARRAC005-LUOGO-NASCITA       00170300
           END-IF.                                                      00170400
       11050-EX.                                                        00170500
           EXIT.                                                        00170600
      ***************************************************************** 00170700
      * ROUTINE DI VALORIZZAZIONE DEL CAMPO DI OUTPUT DEL COMUNE PRE- * 00170800
      * CEDENTE                                                       * 00170900
      ***************************************************************** 00171000
       12000-VALORIZZA-LOCPRE.                                          00171100
           IF WS-LOCPRE = 'CITTA'' DEL VATICANO' OR                     00171200
            'STATO DEL VATICANO'                                        00171300
              MOVE 'CITTA'' DEL VATICANO' TO ARRAC005-LOC-PREC          00171400
           ELSE                                                         00171500
              MOVE WS-LOCPRE            TO ARRAC005-LOC-PREC            00171600
           END-IF.                                                      00171700
       12000-EX.                                                        00171800
           EXIT.                                                        00171900
      ***************************************************************** 00172000
      * ROUTINE DI ACCESSO ALLA TABELLA DEI COMUNI PER REPERIRE CAP E * 00172100
      * PROVINCIA DI RESIDENZA                                        * 00172200
      ***************************************************************** 00172300
       10050-ACCESSO-TDCO.                                              00172400
           MOVE TANG-LOC-RES           TO TDCO-COMUNE.                  00172500
           MOVE L-ACS108-PROV-SEDE-LEG TO TDCO-PROV.                    00172600
           MOVE 'A'                    TO TDCO-STATO-RIGA.              00172700
           EXEC SQL INCLUDE TDCO20SL END-EXEC.                          00172800
           MOVE SQLCODE TO W-SQLCODE3.                                  00172900
           IF W-SQLCODE3 = 0                                            00173000
              GO TO 10050-EX                                            00173100
           END-IF.                                                      00173200
                                                                        00173300
           IF W-SQLCODE3 = 100                                          00173400
              GO TO 10050-EX                                            00173500
           END-IF.                                                      00173600
                                                                        00173700
           IF W-SQLCODE3 NOT = 0 AND 100                                00173800
              DISPLAY 'LABEL 10050-ACCESSO-TDCO'                        00173900
              DISPLAY 'ERRORE ' W-SQLCODE 'SU ACCESSO TABELLA COMUNI'   00174000
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00174100
           END-IF.                                                      00174200
      *                                                                 00174300
010900 10050-EX.                                                        00174400
010900     EXIT.                                                        00174500
      ***************************************************************** 00174600
      * ROUTINE DI ACCESSO ALLA TABELLA SCTBTRIC PER REPERIRE TUTTI I * 00174700
      * RAPPORTI CON STATO RICHIESTA 2 E CODICE ANOMALIA '940'(CONTO B* 00174800
      * LOCCATO).IN CASO DI RICERCA ANDATA A BUON FINE, SI RICHIAMA LA* 00174900
      * ROUTINE XSCDAT PER VERIFICARE IL PERIODO INTERCORSO TRA LA RIS* 00175000
      * POSTA DELL' ENTE E LA DATA DI ELABORAZIONE.SE QUESTO PERIODO  * 00175100
      * RISULTA MAGGIORE DI 20 GIORNI, IL RAPPORTO VERRA' REINVIATO   * 00175200
      * ALL' ENTE PER ESSERE REVOCATO.                                * 00175300
      ***************************************************************** 00175400
221200 00500-LEGGI-CONTO-BLOCCATO.                                      00175500
           PERFORM 01000-APRI-CUR-E3 THRU 01000-EX.                     00175600
           PERFORM 01050-FETCH-E3 THRU 01050-EX                         00175700
            UNTIL W-SQLCODE NOT = 0.                                    00175800
           PERFORM 01100-CHIUDI-CUR-E3 THRU 01100-EX.                   00175900
221200 00500-EX.                                                        00176000
221200     EXIT.                                                        00176100
      ***************************************************************** 00176200
      *      ROUTINE DI APERTURA CURSORE                              * 00176300
      ***************************************************************** 00176400
221200 01000-APRI-CUR-E3.                                               00176500
      *                                                                 00176600
           EXEC SQL   INCLUDE RIC022CO   END-EXEC.                      00176700
      *                                                                 00176800
           INITIALIZE W-SQLCODE.                                        00176900
           MOVE SQLCODE TO W-SQLCODE.                                   00177000
      *                                                                 00177100
           IF W-SQLCODE EQUAL 100                                       00177200
              GO TO 01000-EX                                            00177300
           END-IF.                                                      00177400
      *                                                                 00177500
           IF W-SQLCODE NOT EQUAL 0                                     00177600
              DISPLAY 'LABEL 01000-APRI-CUR-E3'                         00177700
              DISPLAY 'ERRORE SQL CODICE DI RITORNO ' W-SQLCODE         00177800
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00177900
           END-IF.                                                      00178000
221200 01000-EX.                                                        00178100
221200     EXIT.                                                        00178200
      ***************************************************************** 00178300
221200 01050-FETCH-E3.                                                  00178400
           EXEC SQL INCLUDE RIC022CF END-EXEC.                          00178500
           MOVE SQLCODE TO W-SQLCODE.                                   00178600
           IF W-SQLCODE = 0                                             00178700
              ADD 1 TO W-CTR-LETTI1                                     00178800
              MOVE TRIC-NDG-PF     TO WS-NDG-PF                         00178900
              MOVE TRIC-NDG-COI    TO WS-NDG-COI                        00179000
              MOVE TRIC-SERVIZIO   TO WS-SERVIZIO                       00179100
              MOVE TRIC-CATEGORIA  TO WS-CATEGORIA                      00179200
              MOVE TRIC-FILIALE    TO WS-FILIALE                        00179300
              MOVE TRIC-NUMERO     TO WS-NUMERO                         00179400
              MOVE TRIC-DT-RIS-ENT TO W-DT-RIS-ENT                      00179500
              PERFORM 00510-CONTROLLA-DATA THRU 00510-EX                00179600
              IF W-ERRORE = 'N'                                         00179700
                 PERFORM 04050-SCRIVI-E3 THRU 04050-EX                  00179800
              END-IF                                                    00179900
              GO TO 01050-EX                                            00180000
           END-IF.                                                      00180100
           IF W-SQLCODE = 100                                           00180200
              IF W-ERRORE = SPACES AND W-CTR-LETTI = 0                  00180300
                 DISPLAY 'LA TABELLA RICHIESTE NON PRESENTA '           00180400
                 DISPLAY 'RECORD DA INVIARE'                            00180500
                 DISPLAY 'SARANNO INOLTRATI ALL''ENTE I SOLI'           00180600
                 DISPLAY 'RECORD DI TESTA'                              00180700
              END-IF                                                    00180800
              ADD 1 TO W-CTR-SCRITTI                                    00180900
              GO TO 01050-EX                                            00181000
           END-IF.                                                      00181100
           IF W-SQLCODE NOT = 0 AND 100                                 00181200
              DISPLAY 'LABEL 01050-FETCH-E3'                            00181300
              DISPLAY 'ERRORE ' W-SQLCODE ' SU LETTURA SCTBTRIC'        00181400
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00181500
           END-IF.                                                      00181600
221200 01050-EX.                                                        00181700
221200     EXIT.                                                        00181800
      ***************************************************************** 00181900
      *  ROUTINE DI CALCOLO DATA TRAMITE ROUTINE XSCDAT               * 00182000
      ***************************************************************** 00182100
221200 00510-CONTROLLA-DATA.                                            00182200
           PERFORM 00520-CALCOLA-DATA THRU 00520-EX.                    00182300
           IF TDAT-BATCH > RED-REC-DATA                                 00182400
              MOVE 'N' TO W-ERRORE                                      00182500
              GO TO 00510-EX                                            00182600
           END-IF.                                                      00182700
221200 00510-EX.                                                        00182800
221200     EXIT.                                                        00182900
      ***************************************************************** 00183000
      *  ROUTINE DI CALCOLO DATA TRAMITE ROUTINE XSCDAT               * 00183100
      ***************************************************************** 00183200
221200 00520-CALCOLA-DATA.                                              00183300
           INITIALIZE UTDATA-PARAM.                                     00183400
           MOVE  3                 TO    UTDATA-FUNZIONE.               00183500
           MOVE  20                TO    UTDATA-GIORNI.                 00183600
           MOVE  W-DT-RIS-ENT      TO    UTDATA-DATA-1.                 00183700
      *                                                                 00183800
           MOVE 'XSCDAT'        TO DYNACALL.                            00183900
           CALL DYNACALL USING UTDATA-PARAM.                            00184000
      *                                                                 00184100
           IF UTDATA-ERRORE = ZERO                                      00184200
              MOVE UTDATA-SEC-ANNO-2 TO ANNO                            00184300
              MOVE UTDATA-MESE-2     TO MESE                            00184400
              MOVE UTDATA-GIORNO-2   TO GIORNO                          00184500
           ELSE                                                         00184600
DEBU          DISPLAY 'LABEL 00520-CALCOLA-DATA'                        00184700
DEBU          DISPLAY 'CALCOLO DATA NON RIUSCITO'                       00184800
150702        DISPLAY 'UTDATA-ERRORE :' UTDATA-ERRORE                   00184900
150702        DISPLAY 'DATA-INVIO-ENT:' W-DT-RIS-ENT                    00185000
150702        DISPLAY 'TRIC-NDG-PF   :' TRIC-NDG-PF                     00185100
150702        DISPLAY 'TRIC-NDG-COI  :' TRIC-NDG-COI                    00185200
150702        DISPLAY 'TRIC-SERVIZIO :' TRIC-SERVIZIO                   00185300
150702        DISPLAY 'TRIC-CATEGORIA:' TRIC-CATEGORIA                  00185400
150702        DISPLAY 'TRIC-FILIALE  :' TRIC-FILIALE                    00185500
150702        DISPLAY 'TRIC-NUMERO   :' TRIC-NUMERO                     00185600
150702                                                                  00185700
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00185800
           END-IF.                                                      00185900
221200 00520-EX.                                                        00186000
221200     EXIT.                                                        00186100
      ***************************************************************** 00186200
221200 04050-SCRIVI-E3.                                                 00186300
      *                                                                 00186400
050201        IF TRIC-NDG-COI NOT = SPACES                              00186500
                 IF TRIC-NDG-COI = TRIC-NDG-PF                          00186600
                    MOVE 'COI' TO ARRAC008-NAT-GIURIDICA                00186700
                    PERFORM 07250-FLUSSO-E3 THRU 07250-EX               00186800
                 END-IF                                                 00186900
              ELSE                                                      00187000
                 MOVE 'PF' TO ARRAC008-NAT-GIURIDICA                    00187100
                 PERFORM 07250-FLUSSO-E3 THRU 07250-EX                  00187200
              END-IF.                                                   00187300
      *                                                                 00187400
050201        PERFORM 07300-STORICIZZA THRU 07300-EX.                   00187500
050201        PERFORM 02500-UPDATE-RICHIESTE THRU 02500-EX.             00187600
      *                                                                 00187700
221200 04050-EX.                                                        00187800
221200     EXIT.                                                        00187900
      ****************************************************************  00188000
221200 07250-FLUSSO-E3.                                                 00188100
      *                                                                 00188200
           INITIALIZE  ARRAC008.                                        00188300
      *                                                                 00188400
           ADD 1                           TO W-CTR-E3.                 00188500
           MOVE 'E3'                       TO W-TRIC-TIP-ATTIV.         00188600
           MOVE W-TRIC-TIP-ATTIV           TO ARRAC008-TIPO-REC.        00188700
           MOVE TRIC-NDG-PF                TO ARRAC008-NDG.             00188800
           MOVE TRIC-SERVIZIO              TO ARRAC008-SERVIZIO.        00188900
           MOVE TRIC-CATEGORIA             TO ARRAC008-CATEGORIA.       00189000
           MOVE TRIC-FILIALE               TO ARRAC008-FILIALE.         00189100
           MOVE TRIC-NUMERO                TO ARRAC008-NUMERO.          00189200
           MOVE TRIC-NDG-COI               TO ARRAC008-NDG-COI.         00189300
           MOVE SPACES                     TO ARRAC008-FLAG-STIP.       00189400
           MOVE SPACES                     TO ARRAC008-SETT-PROD.       00189500
           MOVE SPACES                     TO ARRAC008-COD-AFF.         00189600
           MOVE ZEROES                     TO ARRAC008-STIPENDIO.       00189700
           MOVE SPACES                     TO ARRAC008-DIV-STIP.        00189800
           MOVE ZEROES                     TO ARRAC008-DT-REVOCA.       00189900
      *                                                                 00190000
           WRITE REC-VARIASCC    FROM     ARRAC008.                     00190100
      *                                                                 00190200
           IF W-STATO3 NOT EQUAL ZERO                                   00190300
              DISPLAY 'ERRORE ' W-STATO3 ' SU SCRITTURA FILE VARIASCC ' 00190400
              DISPLAY 'LABEL 07250-FLUSSO-E3 '                          00190500
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00190600
           END-IF.                                                      00190700
      *                                                                 00190800
           ADD 1 TO W-CTR-SCRITTI.                                      00190900
      *                                                                 00191000
221200 07250-EX. EXIT.                                                  00191100
      ***************************************************************** 00191200
      *  ROUTINE DI AGGIORNAMENTO DEL DB DELLE RICHIESTE              * 00191300
      ***************************************************************** 00191400
221200 02500-UPDATE-RICHIESTE.                                          00191500
           MOVE  'E3'             TO   TRIC-TIP-ATTIV.                  00191600
           MOVE  TDAT-BATCH       TO   TRIC-DT-INV-ENT.                 00191700
           MOVE  W-NOME-PGM       TO   TRIC-COD-OPER.                   00191800
           MOVE  SPACES           TO   TRIC-ESITO.                      00191900
           MOVE  ZEROES           TO   TRIC-DT-RIS-ENT.                 00192000
           MOVE  ZEROES           TO   TRIC-NUM-PROT.                   00192100
           MOVE  SPACES           TO   TRIC-TIPO-PROT.                  00192200
           MOVE  SPACES           TO   TRIC-BAD-CUST.                   00192300
      *                                                                 00192400
           EXEC SQL INCLUDE RIC014UP END-EXEC.                          00192500
      *                                                                 00192600
           INITIALIZE W-SQLCODE1.                                       00192700
           MOVE SQLCODE TO W-SQLCODE1.                                  00192800
           IF W-SQLCODE1 = 100                                          00192900
              DISPLAY 'LABEL 02500-UPDATE-RICHIESTE'                    00193000
              DISPLAY 'OCCORRENZA NON TROVATA SU TABELLA TRIC'          00193100
              GO TO 02500-EX                                            00193200
           END-IF.                                                      00193300
           IF W-SQLCODE1 NOT EQUAL 0 AND 100                            00193400
              DISPLAY 'LABEL 02500-UPDATE-RICHIESTE'                    00193500
              DISPLAY 'ERRORE UPDATE SU TRIC ' W-SQLCODE1               00193600
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00193700
           END-IF.                                                      00193800
221200 02500-EX.                                                        00193900
221200     EXIT.                                                        00194000
      ***************************************************************** 00194100
      * ROUTINE DI CHIUSURA DEL CURSORE PER LETTURA CONTI BLOCCATI    * 00194200
      ***************************************************************** 00194300
221200 01100-CHIUDI-CUR-E3.                                             00194400
           EXEC SQL INCLUDE RIC022CC END-EXEC.                          00194500
221200 01100-EX.                                                        00194600
221200     EXIT.                                                        00194700
      ***************************************************************** 00194800
      * ROUTINE DI SCRITTURA DEI RECORD TAPPO                         * 00194900
      ***************************************************************** 00195000
221200 00600-SCRIVI-TAPPI.                                              00195100
           PERFORM 02075-INS-PROG-AFF        THRU 02075-EX.             00195200
           PERFORM 07175-INS-PROG-VAR-ANAG   THRU 07175-EX.             00195300
           PERFORM 07275-INS-PROG-VAR-SCOP   THRU 07275-EX.             00195400
221200 00600-EX.                                                        00195500
221200     EXIT.                                                        00195600
      ***************************************************************** 00195700
      * ROUTINE DI STORICIZZAZIONE DEL RAPPORTO BLOCCATO              * 00195800
      ***************************************************************** 00195900
221200 07300-STORICIZZA.                                                00196000
           MOVE TRIC-NDG-PF        TO TSTO-NDG-PF.                      00196100
           MOVE TRIC-SERVIZIO      TO TSTO-SERVIZIO.                    00196200
           MOVE TRIC-CATEGORIA     TO TSTO-CATEGORIA.                   00196300
           MOVE TRIC-FILIALE       TO TSTO-FILIALE.                     00196400
           MOVE TRIC-NUMERO        TO TSTO-NUMERO.                      00196500
           MOVE TRIC-NDG-COI       TO TSTO-NDG-COI.                     00196600
           MOVE TRIC-TIP-ATTIV     TO TSTO-TIP-ATTIV.                   00196700
           MOVE TRIC-STATO-RICH    TO TSTO-STATO-RICH.                  00196800
           MOVE TRIC-LIM-FIDO      TO TSTO-LIM-FIDO.                    00196900
           MOVE TRIC-DIV-FIDO      TO TSTO-DIV-FIDO.                    00197000
           MOVE TRIC-COD-ANOM      TO TSTO-COD-ANOM.                    00197100
           MOVE TRIC-SETT-PROD     TO TSTO-SETT-PROD.                   00197200
           MOVE TRIC-COD-AFF       TO TSTO-COD-AFF.                     00197300
           MOVE TRIC-ESITO         TO TSTO-ESITO.                       00197400
           MOVE TRIC-NUM-PROT      TO TSTO-NUM-PROT.                    00197500
           MOVE TRIC-TIPO-PROT     TO TSTO-TIPO-PROT.                   00197600
           MOVE TRIC-BAD-CUST      TO TSTO-BAD-CUST.                    00197700
           MOVE TRIC-ACCR-STIP     TO TSTO-ACCR-STIP.                   00197800
           MOVE TRIC-IMP-STIP      TO TSTO-IMP-STIP.                    00197900
           MOVE TRIC-DIV-STIP      TO TSTO-DIV-STIP.                    00198000
           MOVE TRIC-DT-INV-ENT    TO TSTO-DT-INV-ENT.                  00198100
           MOVE TRIC-DT-RIS-ENT    TO TSTO-DT-RIS-ENT.                  00198200
           MOVE TRIC-DT-RIC-ATT    TO TSTO-DT-RIC-ATT.                  00198300
           MOVE TRIC-DT-ATT-VF     TO TSTO-DT-ATT-VF.                   00198400
           MOVE TRIC-DT-ATT-ESTINZ TO TSTO-DT-ATT-ESTINZ.               00198500
           MOVE TDAT-BATCH         TO TSTO-DT-VAL-A.                    00198600
           MOVE TRIC-DT-STAMPA-AVV TO TSTO-DT-STAMPA-AVV.               00198700
           MOVE TRIC-COD-OPER      TO TSTO-COD-OPER.                    00198800
           MOVE TRIC-TERM-RICH     TO TSTO-TERM-RICH.                   00198900
           MOVE TRIC-FIL-RICH      TO TSTO-FIL-RICH.                    00199000
      *                                                                 00199100
           EXEC SQL INCLUDE STO001IN END-EXEC.                          00199200
      *                                                                 00199300
           MOVE SQLCODE TO W-SQLCODE.                                   00199400
      *                                                                 00199500
           IF W-SQLCODE NOT = 0                                         00199600
              DISPLAY 'LABEL 07300-STORICIZZA'                          00199700
              DISPLAY 'ERRORE ' W-SQLCODE ' SU INSERIMENTO SCTBTSTO'    00199800
              PERFORM 99999-GEST-ABEND THRU 99999-GEST-ABEND-EX         00199900
           END-IF.                                                      00200000
      *                                                                 00200100
221200 07300-EX.                                                        00200200
221200     EXIT.                                                        00200300
