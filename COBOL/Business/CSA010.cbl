      ****************************************
      * MA1113 MODIFICHE PER CHIAMATA ROUTINE*
      *        UCTPDTE1 (INTRODOTTO CAMPO    *
      *        DATA-VALIDITA' = 20081010 PER *
      *        REPERIMENTO DEPOSITO TERRITO- *
      *        RIALE).                       *
      ****************************************
      * MA1013 MODIFICHE PER GESTIONE INTER- *
      *        ROGAZIONI CARTE MO-22AO.      *
      ****************************************
      * AC0907 INSERIMENTO GESTIONE DEPOSITI *
      *        TERRITORIALI                  *
      ****************************************
      * MR0208 INSERIMENTO PROVINCIA FC      *
      *        PER CONVERGENZA SU DEPOSITI   *
      *        TERRITORIALI                  *
      ****************************************
      ****************************************
      * MM0410 GESTIONE SOFFIETTI SCA0 E SCA2*
      ******************************************
      * CL0113 ASSOCIAZIONE TERMINALE A DIREZ  *
      * PER GESTIRE I MODELLI 22/A CON UN NUOVO*
      * PROFILO DI DEPOSITO TERRIT. E CENTRALE *
      * UTILE PER LE RIPRESE GIACENZE CHE SONO *
      * ASSOCIATE TRAMITE TERMINALE            *
      ******************************************
000010 IDENTIFICATION DIVISION.
000020 PROGRAM-ID. CSA010.                                              CVA010
000030 AUTHOR.     MENU CARTE VALORI.                                   CVA010
000040 DATE-COMPILED. 26/09/06.                                         CVA010
000050 ENVIRONMENT DIVISION.                                            CVA010
000060 CONFIGURATION SECTION.                                           CVA010
000070 SOURCE-COMPUTER. IBM-370.                                        CVA010
000080 OBJECT-COMPUTER. IBM-370.                                        CVA010
000090 SPECIAL-NAMES.                                                   D000
000100     DECIMAL-POINT IS COMMA.                                      D010
000110 DATA DIVISION.                                                   CVA010
000120 WORKING-STORAGE SECTION.                                         CVA010
MA041O*01   UCDETE1C COPY UCDETE1C.
MA041O      COPY UCDETE1C-DATI.
AC0907 01   W-UCTPDTE1 PICTURE X(08) VALUE 'UCTPDTE1'.
000130 01   WSS-BEGIN.                                                  CVA010
000140      05 FILLER PICTURE X(7) VALUE 'WORKING'.                     CVA010
000150      05 IK     PICTURE X.                                        CVA010
000160      05 BLANC  PICTURE X VALUE SPACE.                            CVA010
000170      05 OPER   PICTURE X.                                        CVA010
000180      05 OPERD  PICTURE X VALUE SPACE.                            CVA010
000190      05 CATX   PICTURE X.                                        CVA010
000200      05 CATM   PICTURE X.                                        CVA010
000210      05 ICATR  PICTURE 99.                                       CVA010
000220      05 SCR-ER PICTURE X.                                        CVA010
000230      05 FT     PICTURE X.                                        CVA010
000240      05 ICF    PICTURE X.                                        CVA010
000250      05 OCF    PICTURE X.                                        CVA010
000260      05 CAT-ER PICTURE X.                                        CVA010
000270      05 CURPOS.                                                  CVA010
000280      10 CPOSL    PICTURE S9(4) COMPUTATIONAL.                    CVA010
000290      10 CPOSC    PICTURE S9(4) COMPUTATIONAL.                    CVA010
000300      05 CPOSN    PICTURE S9(4) COMPUTATIONAL.                    CVA010
000310      05 7-YCREE PICTURE X VALUE 'E'.                             CVA010
000320      05 7-YCREF PICTURE X VALUE 'F'.                             CVA010
000330      05 7-YCREP PICTURE X VALUE 'P'.                             CVA010
000340      05 7-YCRER PICTURE X VALUE 'R'.                             CVA010
000350      05 7-YCREX PICTURE X VALUE 'X'.                             CVA010
000360      05 INA    PICTURE 999 VALUE 000.                            CVA010
000370      05 INR    PICTURE 999 VALUE 000.                            CVA010
000380      05 INZ    PICTURE 999 VALUE 000.                            CVA010
000390      05 IRR     PICTURE 99 VALUE 00.                             CVA010
000400      05 INT    PICTURE 999 VALUE 000.                            CVA010
000410      05 IER     PICTURE 99 VALUE 01.                             CVA010
000420      05 DEL-ER  PICTURE X.                                       CVA010
000430 01   PACBASE-CONSTANTS.                                          CVA010
000440* OLSD DATES PACE30 : 02/04/03                                    CVA010
000450*            PACE80 : 02/04/03   PAC7SG : 020604                  CVA010
000460      05 FILLER PICTURE X(60) VALUE                               CVA010
000470               '6346 CVS26/09/06CVA010CSA010  14:54:09SANT    BIIBCVA010
000480-     '26/09/2006'.                                               CVA010
000490 01   CONSTANTS-PACBASE REDEFINES PACBASE-CONSTANTS.              CVA010
000500      05 SESSI  PICTURE X(5).                                     CVA010
000510      05 LIBRA  PICTURE X(3).                                     CVA010
000520      05 DATGN  PICTURE X(8).                                     CVA010
000530      05 PROGR  PICTURE X(6).                                     CVA010
000540      05 PROGE  PICTURE X(8).                                     CVA010
000550      05 TIMGN  PICTURE X(8).                                     CVA010
000560      05 USERCO PICTURE X(8).                                     CVA010
000570      05 COBASE PICTURE X(4).                                     CVA010
000580      05 DATGNC PICTURE X(10).                                    CVA010
000590 01   PACBASE-WORK.                                               CVA010
000600      05 PRDOC  PICTURE X(8) VALUE 'PACHELP'.                     CVA010
000610      05 SCRLGTH PICTURE S9(4) COMPUTATIONAL VALUE +0001.         CVA010
000620      05 NAMEQ.                                                   CVA010
000630      10 FILLER   PICTURE X(04) VALUE 'PAC7'.                     CVA010
000640      10 TRMID    PICTURE X(4).                                   CVA010
000650      05 TSQITEM  PICTURE S9(4) COMPUTATIONAL VALUE +1.           CVA010
000660      05 PRCGI  PICTURE X(8) VALUE 'D4R980'.                      CVA010
000670      05 PRUSER PICTURE X(8) VALUE 'ZAR980'.                      CVA010
000680      05      5-A010-TRAN                                         CVA010
000690                 PICTURE X(4) VALUE  'VBA0'.                      CVA010
000700      05      5-A010-PROGE  PICTURE X(8).                         CVA010
000710 01  DATCE.                                                       CVA010
000720   05  CENTUR   PICTURE XX VALUE '19'.                            CVA010
000730      05 DATOR.                                                   CVA010
000740      10 DATOA  PICTURE XX.                                       CVA010
000750      10 DATOM  PICTURE XX.                                       CVA010
000760      10 DATOJ  PICTURE XX.                                       CVA010
000770 01  DAT6.                                                        CVA010
000780      10 DAT61.                                                   CVA010
000790      15 DAT619 PICTURE 99.                                       CVA010
000800      10 DAT62.                                                   CVA010
000810      15 DAT629 PICTURE 99.                                       CVA010
000820      10 DAT63  PICTURE XX.                                       CVA010
000830 01  DAT7.                                                        CVA010
000840      10 DAT71  PICTURE XX.                                       CVA010
000850      10 DAT72  PICTURE XX.                                       CVA010
000860      10 DAT73  PICTURE XX.                                       CVA010
000870 01  DAT8.                                                        CVA010
000880      10 DAT81  PICTURE XX.                                       CVA010
000890      10 DAT8S1 PICTURE X.                                        CVA010
000900      10 DAT82  PICTURE XX.                                       CVA010
000910      10 DAT8S2 PICTURE X.                                        CVA010
000920      10 DAT83  PICTURE XX.                                       CVA010
000930 01  DATSEP     PICTURE X VALUE '/'.                              CVA010
000940 01  DATSET     PICTURE X VALUE '-'.                              CVA010
000950 01  DAT-TRANS.                                                   CVA010
000960   05  DAT-CTYD   PICTURE XX VALUE '61'.                          CVA010
000970 01  DATCTY.                                                      CVA010
000980   05  DATCTY9  PICTURE 99.                                       CVA010
000990 01  DAT6C.                                                       CVA010
001000   10  DAT61C   PICTURE XX.                                       CVA010
001010   10  DAT62C   PICTURE XX.                                       CVA010
001020   10  DAT63C   PICTURE XX.                                       CVA010
001030   10  DAT64C   PICTURE XX.                                       CVA010
001040 01  DAT7C.                                                       CVA010
001050   10  DAT71C   PICTURE XX.                                       CVA010
001060   10  DAT72C   PICTURE XX.                                       CVA010
001070   10  DAT73C   PICTURE XX.                                       CVA010
001080   10  DAT74C   PICTURE XX.                                       CVA010
001090 01  DAT8C.                                                       CVA010
001100   10  DAT81C   PICTURE XX.                                       CVA010
001110   10  DAT8S1C  PICTURE X    VALUE '/'.                           CVA010
001120   10  DAT82C   PICTURE XX.                                       CVA010
001130   10  DAT8S2C  PICTURE X    VALUE '/'.                           CVA010
001140   10  DAT83C   PICTURE XX.                                       CVA010
001150   10  DAT84C   PICTURE XX.                                       CVA010
001160 01  DAT8G.                                                       CVA010
001170   10  DAT81G   PICTURE XX.                                       CVA010
001180   10  DAT82G   PICTURE XX.                                       CVA010
001190   10  DAT8S1G  PICTURE X    VALUE '-'.                           CVA010
001200   10  DAT83G   PICTURE XX.                                       CVA010
001210   10  DAT8S2G  PICTURE X    VALUE '-'.                           CVA010
001220   10  DAT84G   PICTURE XX.                                       CVA010
001230 01  TIMCO.                                                       CVA010
001240  02  TIMCOG.                                                     CVA010
001250    05  TIMCOH  PICTURE XX.                                       CVA010
001260    05  TIMCOM  PICTURE XX.                                       CVA010
001270    05  TIMCOS  PICTURE XX.                                       CVA010
001280   02 TIMCOC    PICTURE XX.                                       CVA010
001290 01  TIMDAY.                                                      CVA010
001300    05  TIMHOU  PICTURE XX.                                       CVA010
001310    05  TIMS1   PICTURE X    VALUE ':'.                           CVA010
001320    05  TIMMIN  PICTURE XX.                                       CVA010
001330    05  TIMS2   PICTURE X    VALUE ':'.                           CVA010
001340    05  TIMSEC  PICTURE XX.                                       CVA010
001350 01  TIMCIC     PICTURE 9(7).                                     CVA010
001360 01  TIMCI1     REDEFINES TIMCIC.                                 CVA010
001370   05  FILLER PIC X.                                              CVA010
001380   05  TIMCIG.                                                    CVA010
001390    10 TIMCIH   PICTURE XX.                                       CVA010
001400    10 TIMCIM   PICTURE XX.                                       CVA010
001410    10 TIMCIS   PICTURE XX.                                       CVA010
001420 01  DATCIC     PICTURE 9(7).                                     CVA010
001430 01  DATQTM     REDEFINES DATCIC.                                 CVA010
001440   05  FILLER   PICTURE XX.                                       CVA010
001450   05  DATQUY   PICTURE 99.                                       CVA010
001460   05  DATQUD   PICTURE 999.                                      CVA010
001470 01  TABDAT.                                                      CVA010
001480  02  TABQTM.                                                     CVA010
001490   05  FILLER PIC X(18) VALUE '031059090120151181'.               CVA010
001500   05  FILLER PIC X(18) VALUE '212243273304334365'.               CVA010
001510  02  TABQT1 REDEFINES TABQTM PIC 999 OCCURS 12.                  CVA010
001520  02  TABBIS.                                                     CVA010
001530   05  FILLER PIC X(18) VALUE '031060091121152182'.               CVA010
001540   05  FILLER PIC X(18) VALUE '213244274305335366'.               CVA010
001550  02  TABBI1 REDEFINES TABBIS PIC 999 OCCURS 12.                  CVA010
001560*BEGIN DB2          AU64                                          CVA010
001570 01                 AU64.                                         CVA010
001580      05            AU64-XCLELE PICTURE X(17).                    CVA010
001590      05            AU64-XERMSG PICTURE X(73).                    CVA010
001600*END   DB2                                                        CVA010

MM0410*BEGIN DB2          RC10
MM0410 01               RC10.
MM0410   05             RC10-CDBAN0   PICTURE X(05).
MM0410   05             RC10-CDSSM0   PICTURE X(05).
MM0410   05             RC10-CDRCB0   PICTURE X(5).
MM0410   05             RC10-NRULR0   PICTURE S9(05) COMPUTATIONAL-3.
MM0410   05             RC10-CDRGB0   PICTURE X(02).
MM0410   05             RC10-FLESI0   PICTURE X(01).
MM0410   05             RC10-NRSKE0   PICTURE S9(02) COMPUTATIONAL-3.
MM0410   05             VRC10-DSPRC0.
MM0410     49           LRC10-DSPRC0  PICTURE S9(4) COMP.
MM0410     49           RC10-DSPRC0   PICTURE X(450).
MM0410   05             RC10-DTELA0   PICTURE X(8).
MM0410   05             RC10-ORELA0   PICTURE X(08).
MM0410   05             RC10-DTILA0   PICTURE X(8).
MM0410   05             RC10-ORIEL0   PICTURE X(08).
MM0410   05             RC10-XTERMI   PICTURE X(04).
MM0410   05             RC10-XIDUTI   PICTURE X(8).
MM0410   05             RC10-CDDIPI   PICTURE X(05).
MM0410   05             RC10-CDDPUI   PICTURE X(02).
MM0410   05             RC10-XDTMSI   PICTURE X(8).
MM0410   05             RC10-XHOMSI   PICTURE S9(06) COMPUTATIONAL-3.
MM0410*END   DB2
001610 01         A010-MESSO.                                           *AA040
001620    02      A010-MESSI.                                           *AA040
001630      05    S02034  PICTURE X(020).                               *AA040
001640      05    S05012  PICTURE X(026).                               *AA040
001650      05    S05039  PICTURE X(009).                               *AA040
001660      05    S06012  PICTURE X(023).                               *AA040
001670      05    S07012  PICTURE X(026).                               *AA040
001680      05    S08012  PICTURE X(025).                               *AA040
001690      05    S08038  PICTURE X(026).                               *AA040
001700      05    S09012  PICTURE X(025).                               *AA040
001710      05    S09038  PICTURE X(017).                               *AA040
001720      05    S10012  PICTURE X(025).                               *AA040
001730      05    S10038  PICTURE X(007).                               *AA040
001740      05    S11012  PICTURE X(027).                               *AA040
001750      05    S12012  PICTURE X(022).                               *AA040
001760      05    S20002  PICTURE X(001).                               *AA040
001770 01      AT-A010-MESSO.                                           *AA041
001780       05 AT-S02034         PICTURE X(13) VALUE '02034020LNNW '.  *AA041
001790       05 AT-S05012         PICTURE X(13) VALUE '05012026LNNW '.  *AA041
001800       05 AT-S05039         PICTURE X(13) VALUE '05039009LNNW '.  *AA041
001810       05 AT-S06012         PICTURE X(13) VALUE '06012023LNNW '.  *AA041
001820       05 AT-S07012         PICTURE X(13) VALUE '07012026LNNW '.  *AA041
001830       05 AT-S08012         PICTURE X(13) VALUE '08012025LNNW '.  *AA041
001840       05 AT-S08038         PICTURE X(13) VALUE '08038026LNNW '.  *AA041
001850       05 AT-S09012         PICTURE X(13) VALUE '09012025LNNW '.  *AA041
001860       05 AT-S09038         PICTURE X(13) VALUE '09038017LNNW '.  *AA041
001870       05 AT-S10012         PICTURE X(13) VALUE '10012025LNNW '.  *AA041
001880       05 AT-S10038         PICTURE X(13) VALUE '10038007LNNW '.  *AA041
001890       05 AT-S11012         PICTURE X(13) VALUE '11012027LNNW '.  *AA041
001900       05 AT-S12012         PICTURE X(13) VALUE '12012022LNNW '.  *AA041
001910       05 AT-R000101-FLCNF0 PICTURE X(13) VALUE '20002001PDNW '.  *AA041
001920 01      AT-A010-MESSA   REDEFINES   AT-A010-MESSO.               *AA041
001930      05 AT-A010-LIGNE   OCCURS 014.                              *AA041
001940      10 AT-A010-YPCUR   PICTURE 9(5).                            *AA041
001950      10 AT-A010-LENGTH  PICTURE 999.                             *AA041
001960      10 AT-A010-ATTRN   PICTURE X.                               *AA041
001970      10 AT-A010-ATTRI   PICTURE X.                               *AA041
001980      10 AT-A010-ATTRP   PICTURE X.                               *AA041
001990      10 AT-A010-ATTRC   PICTURE X.                               *AA041
002000      10 AT-A010-ATTRF   PICTURE X.                               *AA041
002010 01        INPUT-A010.                                            *AA042
002020      05    R20002  PICTURE X(1).                                 *AA042
002030 01           INPUT-SCREEN-FIELDS  REDEFINES  INPUT-A010.         *AA045
002040      02      I-A010.                                             *AA045
002050      05      I-A010-FLCNF0 PICTURE X(01).                        *AA045
002060 01       OUTPUT-A010.                                            *AA049
002070      05    T20002  PICTURE X(1).                                 *AA049
002080 01           OUTPUT-SCREEN-FIELDS REDEFINES OUTPUT-A010.         *AA050
002090      02      O-A010.                                             *AA050
002100      05      O-A010-FLCNF0 PICTURE X(01).                        *AA050
002110 01      CMES-COMMUNICATION.                                      *AA060
002120      05    CMES-LOMES    PICTURE S9(4) VALUE +0279.              *AA060
002130      05    CMES-NBFLD    PICTURE S9(4) VALUE +014.               *AA060
002140      05    CMES-YR00     PICTURE X(0279).                        *AA060
002150      05    CMES-YO00     PICTURE X(0182).                        *AA060
002160      05    CMES-YCRE     PICTURE X.                              *AA060
002170      05    CMES-YPCUR    PICTURE 9(5).                           *AA060
002180      05    CMES-MDTOFF   PICTURE X   VALUE '0'.                  *AA060
002190      05    CMES-LNCOL    PICTURE 9(5)  VALUE 24080.              *AA060
002200      05    CMES-YMAT     PICTURE X.                              *AA060
002210      05    CMES-YCOUL    PICTURE X.                              *AA060
002220      05    CMES-FMES     PICTURE X.                              *AA060
002230 01              EM00.                                            *AA100
002240     05          EM00-EMKEY.                                      *AA100
002250       10        EM00-LIBRA     PICTURE X(3).                     *AA100
002260       10        EM00-ENTYP     PICTURE X.                        *AA100
002270       10        EM00-XEMKY.                                      *AA100
002280         15      EM00-PROGR     PICTURE X(6).                     *AA100
002290         15      EM00-ERCOD.                                      *AA100
002300           20    EM00-ERCOD9    PICTURE 9(3).                     *AA100
002310         15      EM00-ERTYP     PICTURE X.                        *AA100
002320       10        EM00-LINUM     PICTURE 9(3).                     *AA100
002330     05          EM00-ERLVL     PICTURE X.                        *AA100
002340     05          EM00-ERMSG     PICTURE X(66).                    *AA100
002350     05          FILLER         PICTURE X(6).                     *AA100
002360 01   TT-DAT.                                                     *AA200
002370      05 T-DAT      PICTURE X OCCURS 5.                           *AA200
002380 01   LEAP-YEAR.                                                  *AA200
002390      05 LEAP-FLAG  PICTURE X.                                    *AA200
002400      05 LEAP-REM   PICTURE 99.                                   *AA200
002410 01   USERS-ERROR.                                                *AA200
002420      05 XEMKY.                                                   *AA200
002430         10 XPROGR   PICTURE X(6).                                *AA200
002440         10 XERCD    PICTURE X(4).                                *AA200
002450      05 T-XEMKY     OCCURS       01.                             *AA200
002460         10 T-XPROGR PICTURE X(6).                                *AA200
002470         10 T-XERCD  PICTURE X(4).                                *AA200
002480 01   PACBASE-INDEXES COMPUTATIONAL SYNC.                         *AA200
002490      05  TALLI      PICTURE S9(4) VALUE ZERO.                    *AA200
002500      05 K01         PICTURE S9(4).                               *AA200
002510      05 K02         PICTURE S9(4).                               *AA200
002520      05 K03         PICTURE S9(4).                               *AA200
002530      05 K04         PICTURE S9(4).                               *AA200
002540      05 K50R        PICTURE S9(4) VALUE ZERO.                    *AA200
002550      05 K50L        PICTURE S9(4) VALUE ZERO.                    *AA200
002560      05 K50M        PICTURE S9(4)                                *AA200
002570                     VALUE       +01.                             *AA200
002580      05    5-EM00-LTH  PICTURE S9(4) VALUE +0090.                *AA200
002590      05    5-AU64-LTH  PICTURE S9(4) VALUE +0090.                *AA200
002600      05    5-AU64-LTHV PICTURE S9(4) VALUE +0090.                *AA200
002610      05    5-CB00-LTH  PICTURE S9(4) VALUE +7847.                *AA200
002620      05    5-CB01-LTH  PICTURE S9(4) VALUE +1014.                *AA200
002630      05    5-CB01-LTHV PICTURE S9(4) VALUE +7321.                *AA200
002640      05    5-CB02-LTH  PICTURE S9(4) VALUE +0464.                *AA200
002650      05    5-CB02-LTHV PICTURE S9(4) VALUE +6771.                *AA200
002660      05    5-CB03-LTH  PICTURE S9(4) VALUE +0154.                *AA200
002670      05    5-CB03-LTHV PICTURE S9(4) VALUE +6461.                *AA200
002680      05    5-CB04-LTH  PICTURE S9(4) VALUE +0803.                *AA200
002690      05    5-CB04-LTHV PICTURE S9(4) VALUE +7110.                *AA200
002700      05    5-CB05-LTH  PICTURE S9(4) VALUE +0061.                *AA200
002710      05    5-CB05-LTHV PICTURE S9(4) VALUE +6368.                *AA200
002720      05    5-CB06-LTH  PICTURE S9(4) VALUE +1035.                *AA200
002730      05    5-CB06-LTHV PICTURE S9(4) VALUE +7342.                *AA200
002740      05    5-CB07-LTH  PICTURE S9(4) VALUE +0020.                *AA200
002750      05    5-CB07-LTHV PICTURE S9(4) VALUE +6327.                *AA200
002760      05    5-CB99-LTH  PICTURE S9(4) VALUE +1540.                *AA200
002770      05    5-CB99-LTHV PICTURE S9(4) VALUE +7847.                *AA200
002780      05    5-XT13-LTH  PICTURE S9(4) VALUE +0030.                *AA200
002790      05    5-XT13-LTHV PICTURE S9(4) VALUE +0030.                *AA200
002800      05    LTH         PICTURE S9(4) VALUE ZERO.                 *AA200
002810      05    KEYLTH      PICTURE S9(4) VALUE ZERO.                 *AA200
002820      05      5-A010-LENGTH PICTURE S9(4)                         *AA200
002830                          VALUE      +7992.                       *AA200
002840      05    5-CMES-LENGTH    PICTURE S9(4).                       *AA200
002850 01   PFKEYS-TABLE.                                               *AA230
002860      02    PF-TAB.                                               *AA230
002870        05  FILLER       PIC X     VALUE QUOTE.                   *AA230
002880        05  FILLER       PIC X(11) VALUE '  _00%A1>A2'.           *AA230
002890        05  FILLER       PIC X(36) VALUE                          *AA230
002900            '101202303404505606707808909:10#11@12'.               *AA230
002910        05  FILLER       PIC X(36) VALUE                          *AA230
002920            'A13B14C15D16E17F18G19H20I21�22.23<24'.               *AA230
002930      02    PFTA  REDEFINES  PF-TAB.                              *AA230
002940        05  PFTA-POS    OCCURS 28.                                *AA230
002950         10 PFTA-VAL    PIC X.                                    *AA230
002960         10 PFTA-IFONCT PIC XX.                                   *AA230
002970      02    I-FONCT.                                              *AA230
002980      05    I-PFKEY  PIC XX.                                      *AA230
002990 01                VAU64.                                         *AA351
003000      05           VAU64XCLELE  PICTURE S9(4) COMP.               *AA351
003010      05           VAU64XERMSG  PICTURE S9(4) COMP.               *AA351
003020 01                VAU64R REDEFINES   VAU64.                      *AA351
003030      05           VAU64A PIC S9(4) COMP     OCCURS 0002.         *AA351
003040*************** ZONA DI COMMUNICAZIONE CON DB2 *****************  *AB000
003050      EXEC SQL INCLUDE SQLCA END-EXEC.                            *AB010
003060********* FINE DELLA ZONA DI COMUNICAZIONE CON DB2 *************  *AB100
003070*                                                                 *AB110
003080*TRACCIATO RECORD CONTENENTE LE VARIABILI DI ERRORE               *AB115
003090     COPY XSAINF.                                                 *AB120
003100*                                                                 *AB200
003110******* MESSAGGIO DI ERRORE PER L'INTEGRITA' REFERENZIALE ******  *AB210
003120 01               W-ERMSG.                                        *AB220
003130   05             W-SQLCODE    PIC -999  VALUE ZERO.              *AB230
003140   05             FILLER       PIC X     VALUE SPACE.             *AB240
003150   05             W-SQLERRMC.                                     *AB250
003160     10           W-SQLERRM6   PIC X(6).                          *AB260
003170     10           FILLER       PIC X(63) VALUE SPACES.            *AB270
003180***** FINE DEL MESSAGGIO D'ERRORE PER L'INTEGRITA' REFERENZIALE ***AB299
003190*CODICE DELL' AREA DI APPARTENENZA DELLA TPR                      *BA010
003200 01               M-X000-XAREA                                    *BA020
003210                          PICTURE X(4).                           *BA020
003220*COPIA SINGOLO POSTO DELLA TABELLA AT-A010-MESSA                  *BA100
003230 01               M-X000-LIGNE.                                   *BA120
003240   05             FILLER       PIC 999.                           *BA140
003250   05             FILLER       PIC 9(5).                          *BA145
003260   05             M-X000-ATTRN PIC X.                             *BA150
003270   05             M-X000-ATTRI PIC X.                             *BA160
003280   05             M-X000-ATTRP PIC X.                             *BA170
003290   05             M-X000-ATTRC PIC X.                             *BA180
003300*FLAG PER RICONOSCERE UNA TPR DI TRASPORTO                        *BA200
003310 01               M-X000-XFTTRA PIC X.                            *BA210
003320*FLAG PER ATTIVARE IL COMANDO 'OSC'                               *BA250
003330 01               M-X000-XFOSC PIC X.                             *BA260
003340*FLAG PER RICONOSCERE UNA FASE CONVERSAZIONALE                    *BA300
003350 01               M-X000-XFCONV PIC X.                            *BA310
003360*CAMPO PER IL LOOP FINO AD SV-AT(TALLY)                           *BA350
003370 01               M-X000-PCURS PIC 9(3)                           *BA360
003380                  VALUE ZERO.                                     *BA365
003390*CAMPI DI LAVORO MACROSTRUTTURA                                   *BA500
003400 01               WSS-AAX000.                                     *BA510
003410   05             M-X000-K66 PIC 9(3).                            *BA520
003420*CONTATORE CAMPI PER IL POSIZIONAMENTO DEL CURSORE                *BA600
003430 01               M-X000-CCAMPI PIC 9(3).                         *BA610
003440*CONTATORE PER MODIFICA ATTRIBUTI                                 *BA620
003450 01               M-X000-CCATTR PIC 9(3).                         *BA630
003460*---------- ZONA WORKING MACRO AA5068 ------------------          *PC900
003470 01         PC02.                                                 *PC905
003480    05            PC02-FLCUR0                                     *PC910
003490                          PICTURE X(01).                          *PC910
003500    05            PC02-XTIMAS                                     *PC915
003510                          PICTURE X.                              *PC915
003520*---------- FINE WORKING MACRO AA5068 ------------------          *PC920
003530*DP: XT  DL: XT SEL: 13       PICT: I DESC: 2 LEV: 1 ORG:   SS:   *TP200
003540 01                 XT13.                                         *TP200
003550        10          XT13-TPSTA0 PICTURE X(02)                     *TP200
003560                         VALUE  SPACE.                            *TP200
003570        10          XT13-FLSAL0 PICTURE X(02)                     *TP200
003580                         VALUE  SPACE.                            *TP200
003590        10          XT13-FLINS0 PICTURE X(01)                     *TP200
003600                         VALUE  SPACE.                            *TP200
003610        10          XT13-NRCAR1 PICTURE S9(10)                    *TP200
003620                         COMPUTATIONAL-3                          *TP200
003630                         VALUE  ZERO.                             *TP200
003640        10          XT13-NRPLI1 PICTURE S9(10)                    *TP200
003650                         COMPUTATIONAL-3                          *TP200
003660                         VALUE  ZERO.                             *TP200
003670        10          XT13-FLMDT0 PICTURE X(01)                     *TP200
003680                         VALUE  SPACE.                            *TP200
003690        10          XT13-FLTPS0 PICTURE X(01)                     *TP200
003700                         VALUE  SPACE.                            *TP200
003710        10          XT13-FLPLI1 PICTURE X(01)                     *TP200
003720                         VALUE  SPACE.                            *TP200
003730        10          XT13-FLECO0 PICTURE X(01)                     *TP200
003740                         VALUE  SPACE.                            *TP200
003750        10          XT13-FLERR0 PICTURE X(01)                     *TP200
003760                         VALUE  SPACE.                            *TP200
003770        10          XT13-DTCRP0 PICTURE X(8)                      *TP200
003780                         VALUE  SPACE.                            *TP200
003790*++++++++         WORKING-MACRO-AAT040  +++++++++++++             *WB110
003800 01               WB00.                                           *WB120
003810     05           WB00-FLABPF1     PIC 9  VALUE ZEROS.            *WB122
003820       88         NO-ABILIT-PF1    VALUE ZEROS.                   *WB124
003830       88         ABILITATO-PF1    VALUE 1.                       *WB126
003840     05           WB00-FLABPF2     PIC 9  VALUE ZEROS.            *WB132
003850       88         NO-ABILIT-PF2    VALUE ZEROS.                   *WB134
003860       88         ABILITATO-PF2    VALUE 1.                       *WB136
003870     05           WB00-FLABPF3     PIC 9  VALUE ZEROS.            *WB160
003880       88         NO-ABILIT-PF3    VALUE ZEROS.                   *WB165
003890       88         ABILITATO-PF3    VALUE 1.                       *WB170
003900     05           WB00-FLABPF4     PIC 9  VALUE ZEROS.            *WB182
003910       88         NO-ABILIT-PF4    VALUE ZEROS.                   *WB184
003920       88         ABILITATO-PF4    VALUE 1.                       *WB186
003930     05           WB00-FLABPF5     PIC 9  VALUE ZEROS.            *WB192
003940       88         NO-ABILIT-PF5    VALUE ZEROS.                   *WB194
003950       88         ABILITATO-PF5    VALUE 1.                       *WB196
003960     05           WB00-FLABPF6     PIC 9  VALUE ZEROS.            *WB260
003970       88         NO-ABILIT-PF6    VALUE ZEROS.                   *WB265
003980       88         ABILITATO-PF6    VALUE 1.                       *WB270
003990     05           WB00-FLABPF7     PIC 9  VALUE ZEROS.            *WB360
004000       88         NO-ABILIT-PF7    VALUE ZEROS.                   *WB365
004010       88         ABILITATO-PF7    VALUE 1.                       *WB370
004020     05           WB00-FLABPF8     PIC 9  VALUE ZEROS.            *WB460
004030       88         NO-ABILIT-PF8    VALUE ZEROS.                   *WB465
004040       88         ABILITATO-PF8    VALUE 1.                       *WB470
004050     05           WB00-FLABPF9     PIC 9  VALUE ZEROS.            *WB480
004060       88         NO-ABILIT-PF9    VALUE ZEROS.                   *WB485
004070       88         ABILITATO-PF9    VALUE 1.                       *WB490
004080     05           WB00-FLABPF0     PIC 9  VALUE ZEROS.            *WB500
004090       88         NO-ABILIT-PF0    VALUE ZEROS.                   *WB505
004100       88         ABILITATO-PF0    VALUE 1.                       *WB510
004110     05           WB00-FLABENT     PIC 9  VALUE ZEROS.            *WB560
004120       88         NO-ABILIT-ENT    VALUE ZEROS.                   *WB565
004130       88         ABILITATO-ENT    VALUE 1.                       *WB570
004140*******   FINE WORKING MACR0 AAT040   ******                      *WB900
004150*APPOGGIO DEPOSITO PROVINCIALE ASSEGNI                            *WW020
004160 01 WW00-XDILIO.                                                  *WW030
004170    05 WW00-XDIL01  PIC X(2).                                     *WW040
004180    05 WW00-XDIL02  PIC X(3).                                     *WW050
      *********************************************************         ********
      *   AREE  DI LETTURA
      *****************************************************************
MM0410 01  FLAG-RC10    PIC 9(01)  VALUE ZERO.
MM0410 01  AREA-RC10    PIC X(34).
MM0410 01  AREA-DSPRC0 REDEFINES  AREA-RC10.
MM0410   05 DSPRC0-CDBAN0    PIC X(5).
MM0410   05 DSPRC0-CDDIP0    PIC X(5).
MM0410   05 DSPRC0-UTENZA.
MM0410     10 DSPRC0-UTENZA1   PIC X(8).
MM0410     10 DSPRC0-UTENZA2   PIC X(8).
MM0410     10 DSPRC0-UTENZA3   PIC X(8).
MM0410
MM0410
MM0410*--------------------------------------------------------
MM0410*    DEFINIZIONE  CURSORI                               *
MM0410*--------------------------------------------------------
MM0410     EXEC  SQL  DECLARE  RC10   CURSOR FOR
MM0410     SELECT DSPRC0 FROM CMRCHSPECBAT
MM0410       WHERE CDBAN0 = :RC10-CDBAN0
MM0410         AND CDSSM0 = :RC10-CDSSM0
MM0410         AND CDRCB0 = :RC10-CDRCB0
MM0410     END-EXEC.
004190 LINKAGE SECTION.                                                 CVA010
004200 01   DFHCOMMAREA.                                                CVA010
004210      02     K-SA010-PROGR PICTURE X(6).                          *00000
004220      02     K-SA010-DOC   PICTURE X.                             *00000
004230      02     K-SA010-PROGE PICTURE X(8).                          *00000
004240      02     K-SA010-CPOSL PICTURE S9(4) COMPUTATIONAL.           *00000
004250      02     K-SA010-PROLE PICTURE X(8).                          *00000
004260      02     K-SA010-LIBRA PICTURE XXX.                           *00000
004270      02     K-SA010-PROHE PICTURE X(8).                          *00000
004280      02     K-SA010-ERCOD.                                       *00000
004290        05   K-SA010-ERCOD9 PICTURE 999.                          *00000
004300      02     K-SA010-ERTYP PICTURE X.                             *00000
004310      02     K-SA010-LINUM PICTURE 999.                           *00000
004320      02            CB00.                                         *00001
004330        10          CB00-XT50.                                    *00001
004340         15         CB00-XT52.                                    *00001
004350          20        CB00-XCURTP PICTURE X(8).                     *00001
004360          20        CB00-XPRITP PICTURE X(8).                     *00001
004370          20        CB00-XNTPR2 PICTURE X(08).                    *00001
004380          20        CB00-XTXID  PICTURE X(4).                     *00001
004390         15         CB00-XT51.                                    *00001
004400          20        CB00-RESPAR.                                  *00001
004410           25       CB00-XNOTY  PICTURE X.                        *00001
004420           25       CB00-XNORMI PICTURE X.                        *00001
004430           25       CB00-XNORMO PICTURE X.                        *00001
004440           25       CB00-XFLTES PICTURE 9.                        *00001
004450           25       CB00-XPRLID PICTURE X(4).                     *00001
004460           25       CB00-XNTPR1 PICTURE X(08).                    *00001
004470           25       CB00-XTPVER PICTURE X(2).                     *00001
004480           25       CB00-XFIRTP PICTURE X(8).                     *00001
004490           25       CB00-XTPMEN PICTURE X(6).                     *00001
004500           25       CB00-XTPSEL PICTURE X(2).                     *00001
004510           25       CB00-XIDPRI PICTURE X(04).                    *00001
004520           25       CB00-XABSTI PICTURE S9(5)                     *00001
004530                         COMPUTATIONAL-3.                         *00001
004540           25       CB00-XTPPRT PICTURE X(01).                    *00001
004550           25       CB00-XSTSLN PICTURE X(01).                    *00001
004560           25       CB00-XFLDBG PICTURE X(01).                    *00001
004570           25       CB00-XCDDEV PICTURE X(01).                    *00001
004580           25       CB00-XINIFL PICTURE X(01).                    *00001
004590           25       CB00-XPFEUR PICTURE X(02).                    *00001
004600           25       CB00-XNWAPC PICTURE X(01).                    *00001
004610           25       CB00-FILLER PICTURE X(37).                    *00001
004620          20        CB00-INPPAR.                                  *00001
004630           25       CB00-X2TPR1 PICTURE X(8).                     *00001
004640           25       CB00-XSETXI PICTURE X(4).                     *00001
004650           25       CB00-XPFKEY PICTURE X(02).                    *00001
004660           25       CB00-XTITER PICTURE X(01).                    *00001
004670           25       CB00-XCAMPI PICTURE 9(03).                    *00001
004680           25       CB00-XAREAI PICTURE X(04).                    *00001
004690           25       CB00-XNODEI PICTURE X(06).                    *00001
004700           25       CB00-XLTTXI PICTURE 9(04).                    *00001
004710           25       CB00-XSITE  PICTURE X(05).                    *00001
004720           25       CB00-XNMSG  PICTURE 9(03).                    *00001
004730           25       CB00-XDTMSG PICTURE X(8).                     *00001
004740           25       CB00-XOMSG1 PICTURE 9(06).                    *00001
004750           25       CB00-XPLL   PICTURE S9(2)                     *00001
004760                         COMPUTATIONAL-3.                         *00001
004770           25       CB00-XNOPER PICTURE X(25).                    *00001
004780           25       CB00-CDCAN0 PICTURE X(01).                    *00001
004790           25       CB00-TPPRM0 PICTURE X(01).                    *00001
004800           25       CB00-XDIVI1 PICTURE X(03).                    *00001
004810           25       CB00-XINFBA.                                  *00001
004820            30      CB00-XCDBA1 PICTURE X(2).                     *00001
004830            30      CB00-CDBAN0 PICTURE X(05).                    *00001
004840            30      CB00-XDESBA PICTURE X(68).                    *00001
004850           25       CB00-XHOMSG PICTURE S9(06)                    *00001
004860                         COMPUTATIONAL-3.                         *00001
004870           25       CB00-XOMENO PICTURE X(06).                    *00001
004880           25       CB00-XABTXT PICTURE X(01).                    *00001
004890           25       CB00-XFLTXT PICTURE X(01).                    *00001
004900           25       CB00-XABCAS PICTURE X(01).                    *00001
004910           25       CB00-XFLCAS PICTURE X(01).                    *00001
004920           25       CB00-XGIOEL PICTURE X(01).                    *00001
004930           25       CB00-XFLGEL PICTURE X(01).                    *00001
004940           25       CB00-XABSUM PICTURE X(01).                    *00001
004950           25       CB00-XFLABS PICTURE X(01).                    *00001
004960           25       CB00-XSYSID PICTURE X(04).                    *00001
004970           25       CB00-XNRIST PICTURE X(02).                    *00001
004980           25       CB00-FILLER PICTURE X(21).                    *00001
004990          20        CB00-OUTPAR.                                  *00001
005000           25       CB00-XAREAO PICTURE X(04).                    *00001
005010           25       CB00-XNODEO PICTURE X(06).                    *00001
005020           25       CB00-XMENUO PICTURE X(6).                     *00001
005030           25       CB00-XSENDM PICTURE X.                        *00001
005040           25       CB00-XFMASK PICTURE X(01).                    *00001
005050           25       CB00-XFERAS PICTURE X.                        *00001
005060           25       CB00-XTPRC1 PICTURE X(08).                    *00001
005070           25       CB00-XLTTXT PICTURE 9(4).                     *00001
005080           25       CB00-XROLBK PICTURE X.                        *00001
005090           25       CB00-XLTTXO PICTURE 9(4).                     *00001
005100           25       CB00-XCSRPX.                                  *00001
005110            30      CB00-XCSRPO PICTURE 9(3).                     *00001
005120           25       CB00-XSENDP PICTURE X.                        *00001
005130           25       CB00-XPFLAG PICTURE X.                        *00001
005140           25       CB00-XMASKM PICTURE X.                        *00001
005150           25       CB00-XTOTCA PICTURE X.                        *00001
005160           25       CB00-XESIPR PICTURE X(2).                     *00001
005170           25       CB00-RIGGIO.                                  *00001
005180            30      CB00-XRIGE  PICTURE 9(2).                     *00001
005190            30      CB00-XRFGE  PICTURE 9(2).                     *00001
005200           25       CB00-XCDESI PICTURE X(05).                    *00001
005210           25       CB00-XCDGRA PICTURE X(01).                    *00001
005220           25       CB00-MASKIN.                                  *00001
005230            30      CB00-XMKFLI PICTURE X(01).                    *00001
005240            30      CB00-FILLER PICTURE X(04).                    *00001
005250           25       CB00-MASKOT.                                  *00001
005260            30      CB00-XMKFLO PICTURE X(01).                    *00001
005270            30      CB00-FILLER PICTURE X(04).                    *00001
005280           25       CB00-INPCUR.                                  *00001
005290            30      CB00-XCSRIN PICTURE 9(03).                    *00001
005300           25       CB00-XCDDVV PICTURE X(03).                    *00001
005310           25       CB00-XCDDVI PICTURE X(03).                    *00001
005320           25       CB00-XSWEUR PICTURE X(01).                    *00001
005330           25       CB00-XEVEUR PICTURE X(01).                    *00001
005340           25       CB00-XCDDVE PICTURE X(03).                    *00001
005350           25       CB00-XATEUR PICTURE X(01).                    *00001
005360           25       CB00-XTSCNV PICTURE 9(4)V9(2).                *00001
005370           25       CB00-FILLER PICTURE X(07).                    *00001
005380          20        CB00-CTRACC.                                  *00001
005390           25       CB00-XTERM.                                   *00001
005400            30      CB00-XLID   PICTURE X(4).                     *00001
005410           25       CB00-XIDUT  PICTURE X(8).                     *00001
005420           25       CB00-XPROUT PICTURE X(08).                    *00001
005430           25       CB00-LIVUT.                                   *00001
005440            30      CB00-XPLIUT PICTURE 9(02).                    *00001
005450            30      CB00-XDLIUT PICTURE X(10).                    *00001
005460            30      CB00-IDENUT.                                  *00001
005470             35     CB00-XDILIU PICTURE X(5).                     *00001
005480             35     CB00-XUFLIU PICTURE X(2).                     *00001
005490           25       CB00-LIVFIS.                                  *00001
005500            30      CB00-XPLIFI PICTURE 9(02).                    *00001
005510            30      CB00-XDLIFI PICTURE X(10).                    *00001
005520            30      CB00-IDLIVF.                                  *00001
005530             35     CB00-XDILIF PICTURE X(5).                     *00001
005540             35     CB00-XUFLIF PICTURE X(2).                     *00001
005550           25       CB00-LIVOPC.                                  *00001
005560            30      CB00-XPLIOC PICTURE 9(02).                    *00001
005570            30      CB00-XDLIOC PICTURE X(10).                    *00001
005580            30      CB00-IDLIOC.                                  *00001
005590             35     CB00-XDILIO PICTURE X(5).                     *00001
005600             35     CB00-XUFLIO PICTURE X(2).                     *00001
005610           25       CB00-XFLFOC PICTURE X(01).                    *00001
005620           25       CB00-LIVGG.                                   *00001
005630            30      CB00-XPLIGG PICTURE 9(02).                    *00001
005640            30      CB00-XDLIGG PICTURE X(10).                    *00001
005650          20        CB00-XDACO1 PICTURE 9(08).                    *00001
005660          20        CB00-DCONTO.                                  *00001
005670           25       CB00-XTOT                                     *00001
005680                         OCCURS 020.                              *00001
005690            30      CB00-XTOTAL PICTURE X(5).                     *00001
005700            30      CB00-XIMPOR PICTURE S9(18).                   *00001
005710            30      CB00-XSEZCO PICTURE X.                        *00001
005720            30      CB00-XFLAG  PICTURE X.                        *00001
005730            30      CB00-XDIVIS PICTURE X(03).                    *00001
005740            30      CB00-IDLDC3 PICTURE S9(02)                    *00001
005750                         COMPUTATIONAL-3.                         *00001
005760          20        CB00-XSTLID PICTURE X(02).                    *00001
005770          20        CB00-XMODE  PICTURE X.                        *00001
005780          20        CB00-XDACON PICTURE S9(08)                    *00001
005790                         COMPUTATIONAL-3.                         *00001
005800          20        CB00-XPGMCO PICTURE X(08).                    *00001
005810          20        CB00-FILLER PICTURE X(31).                    *00001
005820          20        CB00-DESVID.                                  *00001
005830           25       CB00-XMSLO  PICTURE X(1920).                  *00001
005840           25       CB00-XATTR  PICTURE X(600).                   *00001
005850           25       CB00-XATTRR                                   *00001
005860                         REDEFINES      CB00-XATTR                *00001
005870                         OCCURS 200.                              *00001
005880            30      CB00-XATTFI.                                  *00001
005890             35     CB00-XATPRO PICTURE X.                        *00001
005900             35     CB00-XATLUM PICTURE X.                        *00001
005910             35     CB00-XATEVI PICTURE X.                        *00001
005920           25       CB00-XFLINP PICTURE X(200).                   *00001
005930           25       CB00-XDIAGN PICTURE X(79).                    *00001
005940        10          CB00-XT03.                                    *00001
005950         15         CB00-CDMIG0 PICTURE X(25).                    *00001
005960         15         CB00-CDDIV0 PICTURE X(03).                    *00001
005970         15         CB00-IDLDC0 PICTURE S9(02)                    *00001
005980                         COMPUTATIONAL-3.                         *00001
005990         15         CB00-CDPF90 PICTURE X(08).                    *00001
006000         15         CB00-VVZOOM PICTURE X(80).                    *00001
006010         15         CB00-CDNDG0 PICTURE X(09).                    *00001
006020         15         CB00-CDDIP0 PICTURE X(05).                    *00001
006030         15         CB00-CDDPU0 PICTURE X(02).                    *00001
006040         15         CB00-CDCRP0 PICTURE X(03).                    *00001
006050         15         CB00-NRCON0 PICTURE X(12).                    *00001
006060         15         CB00-CDCRS0 PICTURE X(04).                    *00001
006070         15         CB00-CDDIP1 PICTURE X(05).                    *00001
006080         15         CB00-CDCRS1 PICTURE X(04).                    *00001
006090         15         CB00-CDCRT0 PICTURE X(10).                    *00001
006100         15         CB00-CDDIP3 PICTURE X(05).                    *00001
006110         15         CB00-CDDPU3 PICTURE X(02).                    *00001
006120         15         CB00-TPDOC0 PICTURE X(02).                    *00001
006130         15         CB00-CDMDT0 PICTURE X(06).                    *00001
006140         15         CB00-NRECO0 PICTURE 9(12).                    *00001
006150         15         CB00-CDABI4 PICTURE X(07).                    *00001
006160         15         CB00-CDOPR0 PICTURE X(10).                    *00001
006170         15         CB00-CDCAR0 PICTURE X(05).                    *00001
006180         15         CB00-CDPFK0 PICTURE X(02).                    *00001
006190         15         CB00-CDSSM0 PICTURE X(05).                    *00001
006200         15         CB00-CDESO0 PICTURE X(02).                    *00001
006210         15         CB00-CNCON0 PICTURE X(02).                    *00001
006220         15         CB00-CNDOC0 PICTURE X(02).                    *00001
006230         15         CB00-CDNDL0 PICTURE X(09).                    *00001
006240         15         CB00-CDNDL2 PICTURE X(09).                    *00001
006250         15         CB00-DSNDL2 PICTURE X(35).                    *00001
006260         15         CB00-TPUTL0 PICTURE X(04).                    *00001
006270         15         CB00-FILLER PICTURE X(109).                   *00001
006280        10          CB00-XT02.                                    *00001
006290         15         CB00-XSVMAP PICTURE X(1920).                  *00001
006300        10          CB00-XT13.                                    *00001
006310         15         CB00-TPSTA0 PICTURE X(02).                    *00001
006320         15         CB00-FLSAL0 PICTURE X(02).                    *00001
006330         15         CB00-FLINS0 PICTURE X(01).                    *00001
006340         15         CB00-NRCAR1 PICTURE S9(10)                    *00001
006350                         COMPUTATIONAL-3.                         *00001
006360         15         CB00-NRPLI1 PICTURE S9(10)                    *00001
006370                         COMPUTATIONAL-3.                         *00001
006380         15         CB00-FLMDT0 PICTURE X(01).                    *00001
006390         15         CB00-FLTPS0 PICTURE X(01).                    *00001
006400         15         CB00-FLPLI1 PICTURE X(01).                    *00001
006410         15         CB00-FLECO0 PICTURE X(01).                    *00001
006420         15         CB00-FLERR0 PICTURE X(01).                    *00001
006430         15         CB00-DTCRP0 PICTURE X(8).                     *00001
006440        10          CB00-SUITE.                                   *00001
006450         15         FILLER      PICTURE X(01540).                 *00001
006460      02            CB01     REDEFINES  CB00.                     *00001
006470        10          FILLER      PICTURE X(06307).                 *00001
006480        10          CB01-NRPLI1 PICTURE S9(10)                    *00001
006490                         COMPUTATIONAL-3.                         *00001
006500        10          CB01-DTCRP0 PICTURE X(8).                     *00001
006510        10          CB01-FINE   PICTURE X.                        *00001
006520        10          CB01-CDRCH0 PICTURE S9(10)                    *00001
006530                         COMPUTATIONAL-3.                         *00001
006540        10          CB01-TPDOC0 PICTURE X(02).                    *00001
006550        10          CB01-CDMDT0 PICTURE X(06).                    *00001
006560        10          CB01-TPSTA0 PICTURE X(02).                    *00001
006570        10          CB01-CDDIPF PICTURE X(05).                    *00001
006580        10          CB01-CDDPUF PICTURE X(02).                    *00001
006590        10          CB01-CDCABR PICTURE X(07).                    *00001
006600        10          CB01-CDABI1 PICTURE X(07).                    *00001
006610        10          CB01-CDEND0 PICTURE X(15).                    *00001
006620        10          CB01-CDDIPP PICTURE X(05).                    *00001
006630        10          CB01-CDDPUP PICTURE X(02).                    *00001
006640        10          CB01-QTEVA0 PICTURE S9(8)                     *00001
006650                         COMPUTATIONAL-3.                         *00001
006660        10          CB01-QTMDV0 PICTURE S9(08)                    *00001
006670                         COMPUTATIONAL-3.                         *00001
006680        10          CB01-TBMAPP.                                  *00001
006690         15         CB01-RIGA   PICTURE X(052)                    *00001
006700                         OCCURS 010.                              *00001
006710        10          CB01-FT     PICTURE X(1).                     *00001
006720        10          CB01-CDESI0 PICTURE X(02).                    *00001
006730        10          CB01-XITEMM PICTURE 9(4).                     *00001
006740        10          CB01-IPF00L PICTURE 9(02).                    *00001
006750        10          CB01-IPF00M PICTURE 9(02).                    *00001
006760        10          CB01-PF00   PICTURE X(45)                     *00001
006770                         OCCURS 008.                              *00001
006780        10          CB01-XTERMI PICTURE X(04).                    *00001
006790        10          CB01-XIDUTI PICTURE X(8).                     *00001
006800        10          CB01-XDTMSI PICTURE X(8).                     *00001
006810        10          CB01-XHOMSI PICTURE S9(06)                    *00001
006820                         COMPUTATIONAL-3.                         *00001
006830        10          CB01-CDSTV0 PICTURE X(02).                    *00001
006840        10          CB01-CDSBV0 PICTURE X(02).                    *00001
006850        10          CB01-DTIRI0 PICTURE X(8).                     *00001
006860        10          CB01-NRGG00 PICTURE 9(03).                    *00001
006870        10          FILLER      PICTURE X(00526).                 *00001
006880      02            CB02     REDEFINES  CB00.                     *00001
006890        10          FILLER      PICTURE X(06307).                 *00001
006900        10          CB02-CDPGM0 PICTURE X(08).                    *00001
006910        10          CB02-NRPRO0 PICTURE 9(02).                    *00001
006920        10          CB02-IPF00L PICTURE 9(02).                    *00001
006930        10          CB02-IPF00M PICTURE 9(02).                    *00001
006940        10          CB02-PF00   PICTURE X(45)                     *00001
006950                         OCCURS 010.                              *00001
006960        10          FILLER      PICTURE X(01076).                 *00001
006970      02            CB03     REDEFINES  CB00.                     *00001
006980        10          FILLER      PICTURE X(06307).                 *00001
006990        10          CB03-CDRCH0 PICTURE S9(10)                    *00001
007000                         COMPUTATIONAL-3.                         *00001
007010        10          CB03-DTRCH0 PICTURE X(8).                     *00001
007020        10          CB03-CDSRC0 PICTURE X(02).                    *00001
007030        10          CB03-CDDIPL PICTURE X(05).                    *00001
007040        10          CB03-CDDPUL PICTURE X(02).                    *00001
007050        10          CB03-CDDIPR PICTURE X(05).                    *00001
007060        10          CB03-CDDPUR PICTURE X(02).                    *00001
007070        10          CB03-TPENP0 PICTURE X(02).                    *00001
007080        10          CB03-CDENT0 PICTURE X(05).                    *00001
007090        10          CB03-QTMDR0 PICTURE S9(08)                    *00001
007100                         COMPUTATIONAL-3.                         *00001
007110        10          CB03-FINE   PICTURE X(01).                    *00001
007120        10          CB03-TPRICH PICTURE X.                        *00001
007130        10          CB03-DTRCH2 PICTURE X(8)                      *00001
007140                         OCCURS 010.                              *00001
007150        10          CB03-NRECP0 PICTURE S9(12)                    *00001
007160                         COMPUTATIONAL-3.                         *00001
007170        10          CB03-NRECU0 PICTURE S9(12)                    *00001
007180                         COMPUTATIONAL-3.                         *00001
007190        10          CB03-CDENTE PICTURE X(05).                    *00001
007200        10          CB03-TPENP1 PICTURE X(02).                    *00001
007210        10          CB03-CDPGM0 PICTURE X(08).                    *00001
007220        10          CB03-FLGTP0 PICTURE X(01).                    *00001
007230        10          FILLER      PICTURE X(01386).                 *00001
007240      02            CB04     REDEFINES  CB00.                     *00001
007250        10          FILLER      PICTURE X(06307).                 *00001
007260        10          CB04-CTRTAB PICTURE 9(03).                    *00001
007270        10          CB04-TABELL.                                  *00001
007280         15         CB04-ELEMEN                                   *00001
007290                         OCCURS 100.                              *00001
007300          20        CB04-FLCON0 PICTURE X(01).                    *00001
007310          20        CB04-TPENP0 PICTURE X(02).                    *00001
007320          20        CB04-CDENT0 PICTURE X(05).                    *00001
007330        10          FILLER      PICTURE X(00737).                 *00001
007340      02            CB05     REDEFINES  CB00.                     *00001
007350        10          FILLER      PICTURE X(06307).                 *00001
007360        10          CB05-NRCAR1 PICTURE S9(10)                    *00001
007370                         COMPUTATIONAL-3.                         *00001
007380        10          CB05-DTCAR0 PICTURE X(8).                     *00001
007390        10          CB05-NRBLC0 PICTURE S9(08)                    *00001
007400                         COMPUTATIONAL-3.                         *00001
007410        10          CB05-DTBOL0 PICTURE X(8).                     *00001
007420        10          CB05-TPENP0 PICTURE X(02).                    *00001
007430        10          CB05-CDENT0 PICTURE X(05).                    *00001
007440        10          CB05-FLCAR0 PICTURE X(01).                    *00001
007450        10          CB05-FLPRV0 PICTURE X(01).                    *00001
007460        10          CB05-CDDIP0 PICTURE X(05).                    *00001
007470        10          CB05-CDDPU0 PICTURE X(02).                    *00001
007480        10          CB05-XIDUTV PICTURE X(8).                     *00001
007490        10          CB05-TPDOC0 PICTURE X(02).                    *00001
007500        10          CB05-CDMDT0 PICTURE X(06).                    *00001
007510        10          CB05-TPSTA0 PICTURE X(02).                    *00001
007520        10          FILLER      PICTURE X(01479).                 *00001
007530      02            CB06     REDEFINES  CB00.                     *00001
007540        10          FILLER      PICTURE X(06307).                 *00001
007550        10          CB06-TPRICH PICTURE X.                        *00001
007560        10          CB06-CDDIPL PICTURE X(05).                    *00001
007570        10          CB06-CDDPUL PICTURE X(02).                    *00001
007580        10          CB06-DSDIPL PICTURE X(35).                    *00001
007590        10          CB06-CDDIPP PICTURE X(05).                    *00001
007600        10          CB06-CDDPUP PICTURE X(02).                    *00001
007610        10          CB06-DSDIPP PICTURE X(35).                    *00001
007620        10          CB06-CDDIPR PICTURE X(05).                    *00001
007630        10          CB06-CDDPUR PICTURE X(02).                    *00001
007640        10          CB06-DSDIPR PICTURE X(35).                    *00001
007650        10          CB06-CDRCH0 PICTURE S9(10)                    *00001
007660                         COMPUTATIONAL-3.                         *00001
007670        10          CB06-DTRCH0 PICTURE X(8).                     *00001
007680        10          CB06-DTSCA0 PICTURE X(8).                     *00001
007690        10          CB06-FLVRC0 PICTURE X(01).                    *00001
007700        10          CB06-DSMDT0 PICTURE X(30).                    *00001
007710        10          CB06-NRPR00 PICTURE 9(02).                    *00001
007720        10          CB06-NRPR01 PICTURE 9(03).                    *00001
007730        10          CB06-CDCLS0 PICTURE X(02).                    *00001
007740        10          CB06-DSCLS0 PICTURE X(30).                    *00001
007750        10          CB06-CDSRC0 PICTURE X(02).                    *00001
007760        10          CB06-NRECP0 PICTURE S9(12)                    *00001
007770                         COMPUTATIONAL-3.                         *00001
007780        10          CB06-NRECU0 PICTURE S9(12)                    *00001
007790                         COMPUTATIONAL-3.                         *00001
007800        10          CB06-QTMOD0 PICTURE S9(08)                    *00001
007810                         COMPUTATIONAL-3.                         *00001
007820        10          CB06-QTMDR0 PICTURE S9(08)                    *00001
007830                         COMPUTATIONAL-3.                         *00001
007840        10          CB06-CDCABR PICTURE X(07).                    *00001
007850        10          CB06-CDABI1 PICTURE X(07).                    *00001
007860        10          CB06-FINE   PICTURE X.                        *00001
007870        10          CB06-IPF00L PICTURE 9(02).                    *00001
007880        10          CB06-IPF00M PICTURE 9(02).                    *00001
007890        10          CB06-PF00   PICTURE X(58)                     *00001
007900                         OCCURS 003.                              *00001
007910        10          CB06-FLTPT0 PICTURE X(01).                    *00001
007920        10          CB06-RIPET                                    *00001
007930                         OCCURS 010.                              *00001
007940         15         CB06-NRECP1 PICTURE 9(12).                    *00001
007950         15         CB06-NRECU1 PICTURE 9(12).                    *00001
007960         15         CB06-QTMOD1 PICTURE 9(08).                    *00001
007970        10          CB06-QTMDR1 PICTURE 9(08).                    *00001
007980        10          CB06-RIPETI                                   *00001
007990                         OCCURS 010.                              *00001
008000         15         CB06-QTMOD2 PICTURE 9(08).                    *00001
008010         15         CB06-DTRIF0 PICTURE X(8).                     *00001
008020         15         CB06-CDRCH1 PICTURE 9(10).                    *00001
008030        10          CB06-FLQTN0 PICTURE X.                        *00001
008040        10          CB06-TPRIC0 PICTURE X(01).                    *00001
008050        10          CB06-CDCLS1 PICTURE X(02).                    *00001
008060        10          CB06-FLQTN1 PICTURE X.                        *00001
008070        10          CB06-QTMDR2 PICTURE S9(08)                    *00001
008080                         COMPUTATIONAL-3.                         *00001
008090        10          FILLER      PICTURE X(00505).                 *00001
008100      02            CB07     REDEFINES  CB00.                     *00001
008110        10          FILLER      PICTURE X(06307).                 *00001
008120        10          CB07-TPDOC0 PICTURE X(02).                    *00001
008130        10          CB07-CDMDT0 PICTURE X(06).                    *00001
008140        10          CB07-TPSTA0 PICTURE X(02).                    *00001
008150        10          CB07-DTIOP0 PICTURE X(8).                     *00001
008160        10          CB07-CDESZ0 PICTURE X(02).                    *00001
008170        10          FILLER      PICTURE X(01520).                 *00001
008180      02            CB99     REDEFINES  CB00.                     *00001
008190        10          FILLER      PICTURE X(06307).                 *00001
008200        10          CB99-FILLER PICTURE X(1086).                  *00001
008210        10          CB99-CDPGM0 PICTURE X(08).                    *00001
008220        10          CB99-NRPRO0 PICTURE 9(02).                    *00001
008230        10          CB99-IPF00L PICTURE 9(02).                    *00001
008240        10          CB99-IPF00M PICTURE 9(02).                    *00001
008250        10          CB99-PF00   PICTURE X(40)                     *00001
008260                         OCCURS 010.                              *00001
008270        10          CB99-XITEM1 PICTURE 9(04).                    *00001
008280        10          CB99-XITEMM PICTURE 9(04).                    *00001
008290        10          CB99-TBITEM.                                  *00001
008300         15         CB99-XITEM0 PICTURE S9(4)                     *00001
008310                         BINARY                                   *00001
008320                         OCCURS 012.                              *00001
008330        10          CB99-NRPRS0 PICTURE 9(04).                    *00001
008340        10          CB99-NRPRS1 PICTURE 9(04).                    *00001
008350      02     K-SA010-YMAT  PICTURE X.                             *00002
008360      02     K-SA010-YCOUL PICTURE X.                             *00002
008370      02      FILLER        PICTURE X(0100).                      *00002
008380*COMMAREA SSCX                                                    *01000
008390 COPY XSACOM.                                                     *01010
008400 05               TX-USER PIC X(5400).                            *01100
008410 PROCEDURE DIVISION.                                              *99999
008420 F01.          EXIT.                                              CVA010
008430 F01A1.                                                           P000
MM0410     MOVE 0 TO FLAG-RC10
008440     MOVE        PROGE TO PROGR.                                  P010
008450 F01A1-FN.    EXIT.                                               P000
008460 F0101.                                                           P000
008470     EXEC SQL    WHENEVER NOT FOUND GO TO F80-KO       END-EXEC.  P010
008480     EXEC SQL    WHENEVER SQLWARNING                              P015
008490                                    GO TO   F81ES      END-EXEC.  P017
008500     EXEC SQL    WHENEVER SQLERROR  GO TO   F81ES      END-EXEC.  P020
008510 F0101-FN.    EXIT.                                               P000
008520 F0105.        EXIT.                                              CVA010
008530 F0105-FN.    EXIT.                                               CVA010
008540 F0109.                                                           P000
008550     MOVE        'CAVE' TO M-X000-XAREA                           P100
008560     MOVE        '1' TO M-X000-XFTTRA                             P110
008570     MOVE        '1' TO M-X000-XFCONV                             P129
008580     MOVE        ZERO TO PC02-FLCUR0                              P900
008590     MOVE        'M' TO PC02-XTIMAS.                              P901
008600 F0109-FN.    EXIT.                                               P000
008610 F0110.                                                           P000
008620     MOVE        EIBTIME TO TIMCIC                                P100
008630     MOVE        TIMCIG TO TIMCOG                                 P120
008640     MOVE        EIBDATE TO DATCIC                                P125
008650     PERFORM     F8155 THRU F8155-FN.                             P127
008660           IF    DATOA < '61'                                     P129
008670     MOVE        '20' TO CENTUR.                                  P129
008680     MOVE        ZERO TO CATX FT K50L                             P130
008690     MOVE        '1' TO ICF OCF SCR-ER                            P140
008700     MOVE        SPACE TO CATM OPER OPERD CAT-ER                  P170
008710     MOVE        ZERO TO USERS-ERROR.                             P190
008720           IF    PROGR NOT = K-SA010-PROGR                        P200
008730           OR    EIBCALEN = ZERO                                  P210
008740     MOVE        ZERO TO ICF OCF.                                 P200
008750     MOVE        LOW-VALUE TO O-A010                              P230
008760     MOVE        '1' TO OCF                                       P237
008770     MOVE        EIBTRMID TO TRMID.                               P245
008780           IF    K-SA010-DOC = '2'                                P260
008790           OR    K-SA010-DOC = '3'                                P270
008800     MOVE        '1' TO CMES-FMES                                 P260
008810     GO TO    F8Z05.                                              P270
008820 F0110-FN.    EXIT.                                               P000
008830 F015B.    IF    CB00-XAREAI = CB00-XAREAO                        P000
008840           NEXT SENTENCE ELSE GO TO     F015B-FN.                 P000
008850           IF    CB00-FLSAL0 = 'SI'                               P010
008860     MOVE ALL    SPACES TO CB00-SUITE                             P010
008870     MOVE       'CV    V003'   TO   XEMKY                         P020
008880     PERFORM     F81UT THRU F81UT-FN                              P020
008890     MOVE        '4' TO SCR-ER                                    P030
008900     MOVE        'NO' TO CB00-FLSAL0                              P040
008910     GO TO F3999-ITER-FT.                                         P050
008920 F015B-900. GO TO F015D-FN.                                       P000
008930 F015B-FN.    EXIT.                                               P000
008940 F015D.                                                           P000
008950     MOVE        XT13 TO CB00-XT13                                P020
008960     MOVE ALL    SPACES TO CB00-SUITE.                            P030
008970 F015D-FN.    EXIT.                                               P000
008980 F015F.                                                           P000
008990            GO TO F015F-FN.                                       P100
009000     MOVE        'SI' TO CB00-FLSAL0                              P900
009010     MOVE        'CSA010' TO 5-A010-PROGE                         P905
009020     MOVE        'O' TO OPER                                      P910
009030     MOVE        PROGR TO K-SA010-PROGR                           P915
009040     MOVE        CB00-XAREAO TO CB00-XAREAI                       P920
009050     GO TO F3999-ITER-FT.                                         P925
009060 F015F-FN.    EXIT.                                               P000
GS0207 F015L.                                                           P000
GS0207     IF CB00-XNODEI(1:2) = 'RG'                                   P100
GS0207        MOVE        XT13 TO CB00-XT13                             P020
GS0207        MOVE ALL    SPACES TO CB00-SUITE                          P030
GS0207     END-IF.                                                      P910
GS0207 F015L-FN.    EXIT.                                               P000
009070 F0160.                                                           CVA010
009080        IF ICF = ZERO MOVE 'A' TO OPER                            CVA010
009090        GO TO F3999-ITER-FT.                                      CVA010
009100 F0160-FN.    EXIT.                                               CVA010
009110 F01-FN.      EXIT.                                               CVA010
009120 F05.   IF ICF = ZERO GO TO END-OF-RECEPTION.                     CVA010
009130 F0510.                                                           P000
009140     MOVE        CB00-XMSLO TO OUTPUT-A010                        P100
009150        MOVE ZERO TO TALLI                                        P110
009160     INSPECT     OUTPUT-A010 REPLACING ALL                        P110
009170                 LOW-VALUE BY SPACE                               P115
009180     PERFORM     F8145 THRU F8145-FN                              P120
009190     PERFORM     F8165 THRU F8165-FN                              P130
009200     MOVE        'A' TO OPER                                      P140
009210     MOVE        SPACE TO OPERD                                   P150
009220     MOVE        ZERO TO K-SA010-ERCOD                            P168
009230     PERFORM     F8901 THRU F8901-FN.                             P190
009240           IF    K-SA010-ERCOD = ZERO                             P210
009250        MOVE ZERO TO TALLI                                        P210
009260     INSPECT     I-A010 REPLACING ALL                             P210
009270                 '_' BY SPACE.                                    P215
009280 F0510-FN.    EXIT.                                               P000
009290 F0511.                                                           P000
009300           IF    CB00-XPFKEY NOT = 'ET'                           P010
009310           AND   NOT = 'F1'                                       P020
009320           AND   NOT = 'F2'                                       P030
009330           AND   NOT = 'F3'                                       P040
009340           AND   NOT = 'F4'                                       P050
009350           AND   NOT = 'F5'                                       P060
009360           AND   NOT = 'F6'                                       P070
009370           AND   NOT = 'F7'                                       P080
009380           AND   NOT = 'F8'                                       P090
009390           AND   NOT = 'F9'                                       P100
009400           AND   NOT = 'F0'                                       P105
009410     MOVE        CB00-X2TPR1 TO 5-A010-PROGE                      P105
009420     MOVE        'M' TO OPER                                      P110
009430     MOVE        'O' TO OPERD.                                    P115
009440 F0511-FN.    EXIT.                                               P000
009450 F0512.  IF  K-SA010-ERCOD NOT = ZERO                             CVA010
009460            NEXT SENTENCE ELSE GO TO F0512-FN.                    CVA010
009470        MOVE '2'   TO K-SA010-DOC                                 CVA010
009480        MOVE ZERO  TO K-SA010-CPOSL  K-SA010-LINUM                CVA010
009490        MOVE PROGE TO K-SA010-PROGE                               CVA010
009500        MOVE LIBRA TO K-SA010-LIBRA.                              CVA010
009510         IF  K-SA010-ERCOD NOT = SPACE                            CVA010
009520        MOVE '3' TO K-SA010-DOC.                                  CVA010
009530        PERFORM F80-HELP-R  THRU F80-FN                           CVA010
009540        PERFORM F80-HELP-RW THRU F80-FN                           CVA010
009550        MOVE PRDOC TO  5-A010-PROGE  K-SA010-PROHE                CVA010
009560        MOVE 'O' TO OPER  GO TO F4040.                            CVA010
009570 F0512-FN.    EXIT.                                               CVA010
009580 F0514.                                                           P000
009590           IF    I-PFKEY NOT = SPACES                             P010
009600           AND   '01' AND '02' AND '03'                           P020
009610           AND   '04' AND '05' AND '06'                           P030
009620           AND   '07' AND '08' AND '09'                           P040
009630           AND   '10'                                             P041
009640     MOVE       'CV    AA40'   TO   XEMKY                         P020
009650     PERFORM     F81UT THRU F81UT-FN                              P020
009660     MOVE        '4' TO SCR-ER                                    P030
009670     GO TO F3999-ITER-FT.                                         P040
009680     MOVE ALL    ZERO TO WB00.                                    P044
009690     MOVE        1 TO WB00-FLABPF3                                P110
009700                 WB00-FLABENT                                     P120
009710     MOVE        '1' TO WB00-FLABENT.                             P280
009720           IF    I-PFKEY = SPACES                                 P480
009730           AND   NO-ABILIT-ENT                                    P490
009740     MOVE       'CV    AA40'   TO   XEMKY                         P490
009750     PERFORM     F81UT THRU F81UT-FN                              P490
009760     MOVE        '4' TO SCR-ER                                    P500
009770     GO TO F3999-ITER-FT.                                         P510
009780           IF    I-PFKEY = '01'                                   P520
009790           AND   NO-ABILIT-PF1                                    P530
009800     MOVE       'CV    AA40'   TO   XEMKY                         P530
009810     PERFORM     F81UT THRU F81UT-FN                              P530
009820     MOVE        '4' TO SCR-ER                                    P540
009830     GO TO F3999-ITER-FT.                                         P550
009840           IF    I-PFKEY = '02'                                   P560
009850           AND   NO-ABILIT-PF2                                    P570
009860     MOVE       'CV    AA40'   TO   XEMKY                         P570
009870     PERFORM     F81UT THRU F81UT-FN                              P570
009880     MOVE        '4' TO SCR-ER                                    P580
009890     GO TO F3999-ITER-FT.                                         P590
009900           IF    I-PFKEY = '03'                                   P600
009910           AND   NO-ABILIT-PF3                                    P605
009920     MOVE       'CV    AA40'   TO   XEMKY                         P605
009930     PERFORM     F81UT THRU F81UT-FN                              P605
009940     MOVE        '4' TO SCR-ER                                    P615
009950     GO TO F3999-ITER-FT.                                         P620
009960           IF    I-PFKEY = '04'                                   P622
009970           AND   NO-ABILIT-PF4                                    P624
009980     MOVE       'CV    AA40'   TO   XEMKY                         P624
009990     PERFORM     F81UT THRU F81UT-FN                              P624
010000     MOVE        '4' TO SCR-ER                                    P626
010010     GO TO F3999-ITER-FT.                                         P628
010020           IF    I-PFKEY = '05'                                   P632
010030           AND   NO-ABILIT-PF5                                    P634
010040     MOVE       'CV    AA40'   TO   XEMKY                         P634
010050     PERFORM     F81UT THRU F81UT-FN                              P634
010060     MOVE        '4' TO SCR-ER                                    P636
010070     GO TO F3999-ITER-FT.                                         P638
010080           IF    I-PFKEY = '06'                                   P642
010090           AND   NO-ABILIT-PF6                                    P644
010100     MOVE       'CV    AA40'   TO   XEMKY                         P644
010110     PERFORM     F81UT THRU F81UT-FN                              P644
010120     MOVE        '4' TO SCR-ER                                    P646
010130     GO TO F3999-ITER-FT.                                         P648
010140           IF    I-PFKEY = '07'                                   P652
010150           AND   NO-ABILIT-PF7                                    P654
010160     MOVE       'CV    AA40'   TO   XEMKY                         P654
010170     PERFORM     F81UT THRU F81UT-FN                              P654
010180     MOVE        '4' TO SCR-ER                                    P656
010190     GO TO F3999-ITER-FT.                                         P658
010200           IF    I-PFKEY = '08'                                   P662
010210           AND   NO-ABILIT-PF8                                    P664
010220     MOVE       'CV    AA40'   TO   XEMKY                         P664
010230     PERFORM     F81UT THRU F81UT-FN                              P664
010240     MOVE        '4' TO SCR-ER                                    P666
010250     GO TO F3999-ITER-FT.                                         P668
010260           IF    I-PFKEY = '09'                                   P672
010270           AND   NO-ABILIT-PF9                                    P674
010280     MOVE       'CV    AA40'   TO   XEMKY                         P674
010290     PERFORM     F81UT THRU F81UT-FN                              P674
010300     MOVE        '4' TO SCR-ER                                    P676
010310     GO TO F3999-ITER-FT.                                         P678
010320           IF    I-PFKEY = '10'                                   P682
010330           AND   NO-ABILIT-PF0                                    P684
010340     MOVE       'CV    AA40'   TO   XEMKY                         P684
010350     PERFORM     F81UT THRU F81UT-FN                              P684
010360     MOVE        '4' TO SCR-ER                                    P686
010370     GO TO F3999-ITER-FT.                                         P688
010380 F0514-FN.    EXIT.                                               P000
010390 F05-FN.      EXIT.                                               P000
010400 F18.      IF    CAT-ER = SPACES                                  P000
010410           NEXT SENTENCE ELSE GO TO     F18-FN.                   P000
010420 F18BB.    IF    CB00-XPFKEY = 'ET'                               P000
010430           NEXT SENTENCE ELSE GO TO     F18BB-FN.                 P000
010440     MOVE       'CV    V029'   TO   XEMKY                         P010
010450     PERFORM     F81UT THRU F81UT-FN                              P010
010460     GO TO F3999-ITER-FT.                                         P020
010470 F18BB-FN.    EXIT.                                               P000
010480 F18-FN.      EXIT.                                               P000
010490 F20BA.                                                           P000
010500           IF    I-A010-FLCNF0 = SPACE                            P005
010510     MOVE        'N' TO I-A010-FLCNF0                             P005
010520                 O-A010-FLCNF0.                                   P010
010530 F20BA-FN.    EXIT.                                               P000
010540 F21CC.    IF    I-A010-FLCNF0 = 'S'                              P000
010550           NEXT SENTENCE ELSE GO TO     F21CC-FN.                 P000
010560     MOVE        'D ' TO CB00-XUFLIO                              P020
010570                 CB00-XUFLIF                                      P030
010580                 CB00-XUFLIU.                                     P040
010590 F21CC-FN.    EXIT.                                               P000
010600 F21DD.    IF    I-A010-FLCNF0 = 'N'                              P000
010610           NEXT SENTENCE ELSE GO TO     F21DD-FN.                 P000
010620     MOVE        '00' TO CB00-XUFLIO                              P020
010630                 CB00-XUFLIF                                      P030
010640                 CB00-XUFLIU.                                     P040
010650 F21DD-FN.    EXIT.                                               P000
010660 F21EE.                                                           P000
010670           IF    CB00-XDIVI1 = 'EUR'                              P020
010680     MOVE        2 TO CB00-IDLDC0                                 P020
010690           ELSE                                                   P050
010700     MOVE        ZERO TO CB00-IDLDC0.                             P050
010710 F21EE-FN.    EXIT.                                               P000
010720 F21GG.                                                           P000
MM0410     EXEC SQL WHENEVER NOT FOUND CONTINUE END-EXEC
MM0410     PERFORM 00300-ELABORA-RC10
MM0410        THRU 00300-EX
MM0410     EXEC SQL WHENEVER NOT FOUND GO TO F80-KO END-EXEC            P010

CL0113     IF CB00-XPROUT = 'DTCENTRA'
CL0113        MOVE 'DIREZ' TO CB00-XDILIO
CL0113                        CB00-XDILIF
MA1013                        CB00-XDILIU
CL0113        MOVE '00'    TO CB00-XUFLIO
CL0113                        CB00-XUFLIF
MA1013                        CB00-XUFLIU
CL0113     END-IF

010730     MOVE        CB00-XDILIO TO WW00-XDILIO.                      P030
010740           IF    WW00-XDIL01 NUMERIC                              P040
010750           OR    WW00-XDIL01 = 'DI'                               P045
010760            GO TO F21GG-FN.                                       P040
010770     MOVE        'DT' TO CB00-XUFLIO                              P046
010780                 CB00-XUFLIF                                      P048
ES0106*                CB00-XUFLIU                                      P050
AC0907     INITIALIZE UCDETE1C-DATI.
AC0907     MOVE WW00-XDILIO     TO UCDETE1C-FILIALE-IN
MA1113     MOVE '20081010'      TO UCDETE1C-DATA-VALID-IN
AC0907     EXEC CICS LINK PROGRAM (W-UCTPDTE1)
AC0907     COMMAREA (UCDETE1C-DATI)
AC0907     LENGTH (86)
AC0907     END-EXEC
AC0907     IF UCDETE1C-ESITO-OUT = 4
AC0907        IF UCDETE1C-DEPTER-OUT = 'DT***'
AC0907           MOVE WW00-XDIL01 TO CB00-XDILIO
AC0907                               CB00-XDILIF
AC0907           GO TO F21GG-FN
AC0907        END-IF
010840        IF    WW00-XDIL01 = 'RN'                                  P064
010850              MOVE        'FO   ' TO CB00-XDILIO                  P064
010860                                     CB00-XDILIF                  P068
AC0907              GO TO F21GG-FN
AC0907        END-IF
010880        IF    WW00-XDIL01 = 'LC'                                  P150
010890              MOVE        'CO   ' TO CB00-XDILIO                  P150
010900                                     CB00-XDILIF                  P160
AC0907              GO TO F21GG-FN
AC0907        END-IF
010920        IF    WW00-XDIL01 = 'KR'                                  P250
010930              MOVE        'CZ   ' TO CB00-XDILIO                  P250
010940                                     CB00-XDILIF                  P260
AC0907              GO TO F21GG-FN
AC0907        END-IF
MR0208        IF    WW00-XDIL01 = 'FC'                                  P350
MR0208              MOVE        'FO   ' TO CB00-XDILIO                  P350
MR0208                                     CB00-XDILIF                  P360
MR0208              GO TO F21GG-FN
MR0208        END-IF
010960        IF    WW00-XDIL01 = 'VB'                                  P350
010970              MOVE        'NO   ' TO CB00-XDILIO                  P350
010980                                     CB00-XDILIF                  P360
AC0907              GO TO F21GG-FN
AC0907        END-IF
011000        IF    WW00-XDIL01 = 'VV'                                  P450
011010              MOVE        'CZ   ' TO CB00-XDILIO                  P450
011020                                     CB00-XDILIF                  P460
AC0907              GO TO F21GG-FN
AC0907        END-IF
011040        IF    WW00-XDIL01 = 'LO'                                  P550
011050              MOVE        'MI   ' TO CB00-XDILIO                  P550
011060                                     CB00-XDILIF                  P560
AC0907              GO TO F21GG-FN
AC0907        END-IF
011080        IF    WW00-XDIL01 = 'BI'                                  P650
011090              MOVE        'VC   ' TO CB00-XDILIO                  P650
011100                                     CB00-XDILIF                  P660
AC0907              GO TO F21GG-FN
AC0907        END-IF
011120        IF    WW00-XDIL01 = 'PO'                                  P750
011130              MOVE        'FI   ' TO CB00-XDILIO                  P750
011140                                     CB00-XDILIF                  P760
AC0907              GO TO F21GG-FN
AC0907        END-IF
011120        IF    WW00-XDIL01 = 'PU'                                  P750
011130              MOVE        'PS   ' TO CB00-XDILIO                  P750
011140                                     CB00-XDILIF                  P760
AC0907              GO TO F21GG-FN
AC0907        END-IF
011160        IF    WW00-XDIL01 = 'EE'                                  P850
011170              MOVE        'FO   ' TO CB00-XDILIO                  P850
011180                                     CB00-XDILIF                  P860
AC0907              GO TO F21GG-FN
AC0907        END-IF
AC0907     END-IF.
AC0907
AC0907     IF UCDETE1C-ESITO-OUT NOT = ZERO
009640        MOVE       'CV    V027'   TO   XEMKY                      P020
009650        PERFORM     F81UT THRU F81UT-FN                           P020
009660        MOVE        '4' TO SCR-ER                                 P030
009670        GO TO F3999-ITER-FT.                                      P040
AC0907*       MOVE 'XXXXX' TO CB00-XDILIO
AC0907*                       CB00-XDILIF
DIAGN *       MOVE 'E' TO CAT-ER
DIAGN *       MOVE UCDETE1C-DESC-ESITO-OUT TO CB00-XDIAGN
AC0907*       GO TO F21GG-FN
AC0907*    END-IF.
010800     MOVE        SPACES TO WW00-XDIL02                            P052
AC0907     MOVE UCDETE1C-DEPTER-OUT TO WW00-XDILIO
010810     MOVE        WW00-XDILIO TO CB00-XDILIO                       P054
010820                 CB00-XDILIF.                                     P058
011200 F21GG-FN.    EXIT.                                               P000
011210 F3999-ITER-FT.     EXIT.                                         CVA010
011220 F3999-FN.    EXIT.                                               CVA010
011230 F40.       IF SCR-ER > '1'  MOVE 'A' TO OPER  GO TO F40-FN.      CVA010
011240 F40-A.     IF OPERD NOT = SPACE   MOVE OPERD TO OPER.            CVA010
011250 F4030.        EXIT.                                              P000
011260 F4030-FN.    EXIT.                                               P000
011270 F4040.    IF    OPER = 'O'                                       P000
011280           NEXT SENTENCE ELSE GO TO     F4040-FN.                 P000
011290     MOVE        5-A010-PROGE TO NEXT-TPR                         P100
011300     MOVE        M-X000-XAREA TO CB00-XAREAO                      P140
011310     MOVE        5-A010-PROGE TO CB00-XNODEO.                     P160
011320     MOVE        SPACE TO CB00-XMSLO                              P170
011330     EXEC SQL INCLUDE XSPCTL                                      P900
011340                 END-EXEC.                                        P910
011350 F4040-FN.    EXIT.                                               P000
011360 F40-FN.      EXIT.                                               P000
011370 END-OF-RECEPTION.      EXIT.                                     CVA010
011380 F50.      IF OCF = '0' GO TO END-OF-DISPLAY.                     CVA010
011390 F5010.                                                           CVA010
011400        MOVE ZERO TO CATX.                                        CVA010
011410        IF SCR-ER > '1'  GO TO F6999-ITER-FT.                     CVA010
011420        MOVE SPACE  TO O-A010.                                    CVA010
011430 F5010-FN.    EXIT.                                               CVA010
011440 F50-FN.      EXIT.                                               CVA010
011450 F55.          EXIT.                                              CVA010
011460 F5510.                                                           CVA010
011470        MOVE SPACE TO CAT-ER.                                     CVA010
011480        IF CATX = '0' MOVE ' ' TO CATX GO TO F5510-FN.            CVA010
011490 F5510-900. GO TO F6999-ITER-FT.                                  CVA010
011500 F5510-FN.    EXIT.                                               CVA010
011510 F55-FN.      EXIT.                                               CVA010
011520 F64BB.                                                           P000
011530           IF    CB00-XUFLIO = 'D '                               P010
011540     MOVE        'S' TO O-A010-FLCNF0                             P010
011550           ELSE                                                   P020
011560     MOVE        'N' TO O-A010-FLCNF0.                            P020
011570 F64BB-FN.    EXIT.                                               P000
011580 F6999-ITER-FI.  GO TO F55.                                       CVA010
011590 F6999-ITER-FT.     EXIT.                                         CVA010
011600 F6999-FN.    EXIT.                                               CVA010
011610 F70.          EXIT.                                              P000
011620 F7050.    IF    K50L > ZERO                                      P000
011630           NEXT SENTENCE ELSE GO TO     F7050-FN.                 P000
011640     MOVE        LIBRA TO EM00-LIBRA                              P100
011650     MOVE        PROGR TO EM00-PROGR                              P110
011660     MOVE        ZERO TO EM00-LINUM                               P120
011670     MOVE        'H' TO EM00-ENTYP                                P130
011680     MOVE        T-XEMKY (1) TO EM00-XEMKY                        P140
011690                 EM00-ERMSG                                       P150
011700     PERFORM     F80-EM00-R     THRU  F80-FN                      P160
011710     MOVE        EM00-ERMSG TO CB00-XDIAGN.                       P170
011720 F7050-FN.    EXIT.                                               P000
011730 F7051.                                                           P000
011740     MOVE        'S1' TO CB00-XCSRPX.                             P190
011750 F7051-FN.    EXIT.                                               P000
011760 F70-FN.      EXIT.                                               P000
011770 END-OF-DISPLAY.    EXIT.                                         CVA010
011780 F8YBB.                                                           P000
011790     MOVE        PROGE TO K-SA010-PROGE.                          P010
011800 F8YBB-FN.    EXIT.                                               P000
011810 F8Z.          EXIT.                                              CVA010
011820 F8Z05.   IF SCR-ER = '1'                                         CVA010
011830        NEXT SENTENCE ELSE GO TO F8Z05-FN.                        CVA010
011840          IF K-SA010-DOC NOT = '2'                                CVA010
011850         AND K-SA010-DOC NOT = '3'     GO TO F8Z05-A.             CVA010
011860        MOVE '1' TO K-SA010-DOC                                   CVA010
011870        MOVE K-SA010-ERCOD9 TO K01 K02.                           CVA010
011880 F8Z05-A.                                                         CVA010
011890          IF K-SA010-DOC = ZERO                                   CVA010
011900        MOVE '1' TO K-SA010-DOC                                   CVA010
011910        PERFORM F80-HELP-D  THRU F80-FN                           CVA010
011920        PERFORM F80-HELP-W  THRU F80-FN  GO TO F8Z05-FN.          CVA010
011930          IF K-SA010-DOC = '1'                                    CVA010
011940        PERFORM F80-HELP-RW THRU F80-FN.                          CVA010
011950 F8Z05-FN.    EXIT.                                               CVA010
011960 F8Z10.                                                           P000
011970     PERFORM     F8910 THRU F8910-FN.                             P140
011980 F8Z11.    IF    SCR-ER NOT > '1'                                 P000
011990           NEXT SENTENCE ELSE GO TO     F8Z11-FN.                 P000
012000     MOVE        PROGR TO K-SA010-PROGR                           P100
012010     MOVE        OUTPUT-A010 TO CB00-XMSLO                        P120
012020     MOVE        M-X000-XAREA TO CB00-XAREAO                      P130
012030     MOVE        PROGE TO CB00-XNODEO.                            P140
012040           IF    PC02-XTIMAS = 'M'                                P944
012050           OR    PC02-FLCUR0 = '1'                                P945
012060           OR    XERCD = 'V029'                                   P946
012070           OR    XERCD = ' '                                      P947
012080           OR    XERCD = ' '                                      P948
012090           OR    XERCD = ' '                                      P949
012100           OR    XERCD = ' '                                      P950
012110     MOVE        'S1 ' TO CB00-XCSRPX.                            P944
012120     MOVE        ZERO TO PC02-FLCUR0.                             P960
012130 F8Z11-FN.    EXIT.                                               P000
012140 F8Z16.    IF    SCR-ER > '1'                                     P000
012150           NEXT SENTENCE ELSE GO TO     F8Z16-FN.                 P000
012160     MOVE        'Y' TO CB00-XFMASK                               P100
012170     MOVE        OUTPUT-A010 TO CB00-XMSLO                        P120
012180     MOVE        M-X000-XAREA TO CB00-XAREAO                      P140
012190     MOVE        PROGE TO CB00-XNODEO.                            P160
012200           IF    PC02-FLCUR0 = '1'                                P900
012210           OR    XERCD = 'V029'                                   P901
012220           OR    XERCD = ' '                                      P902
012230           OR    XERCD = ' '                                      P903
012240           OR    XERCD = ' '                                      P904
012250           OR    XERCD = ' '                                      P905
012260     MOVE        'S1 ' TO CB00-XCSRPX.                            P900
012270     MOVE        ZERO TO PC02-FLCUR0.                             P950
012280 F8Z16-FN.    EXIT.                                               P000
012290 F8Z10-FN.    EXIT.                                               P000
012300 F8Z17.                                                           P000
012310     MOVE        CB00-XNTPR1 TO NEXT-TPR.                         P020
012320 F8Z17-FN.    EXIT.                                               P000
012330 F8Z20.                                                           P000
012340           IF    M-X000-XFCONV = '1'                              P010
012350     MOVE        5400 TO CB00-XLTTXO.                             P010
012360     EXEC SQL INCLUDE XSPCTL                                      P020
012370                 END-EXEC.                                        P030
012380 F8Z20-FN.    EXIT.                                               P000
012390 F8Z-FN.      EXIT.                                               P000
012400 F80.          EXIT.                                              CVA010
012410 F8094.        EXIT.                                              P000
012420 F80-EM00-R.                                                      P040
012430     MOVE        EM00 TO AU64                                     P050
012440     EXEC SQL    SELECT ALL                                       P100
012450                              XCLELE,                             P110
012460                              XERMSG                              P111
012470                   INTO :AU64-XCLELE,                             P120
012480                        :AU64-XERMSG                              P121
012490                   FROM CMERRORI                                  P130
012500                   WHERE XCLELE = :AU64-XCLELE         END-EXEC.  P140
012510     MOVE        AU64 TO EM00                                     P200
012520     GO TO F80-OK.                                                P300
012530 F8094-FN.    EXIT.                                               P000
012540 F8095.        EXIT.                                              P000
012550 F80-HELP-R.                                                      P100
012560           IF    K-SA010-DOC NOT = ZERO                           P120
012570     MOVE        CB00-XSVMAP TO O-A010.                           P120
012580     GO TO F80-OK.                                                P130
012590 F80-HELP-RW.                                                     P140
012600     MOVE        O-A010 TO CB00-XSVMAP                            P150
012610     GO TO F80-OK.                                                P160
012620 F80-HELP-W.                                                      P170
012630     MOVE        O-A010 TO CB00-XSVMAP                            P180
012640     GO TO F80-OK.                                                P185
012650 F80-HELP-D.                                                      P190
012660     MOVE        SPACE TO CB00-XSVMAP                             P200
012670     GO TO F80-OK.                                                P210
012680 F8095-FN.    EXIT.                                               P000
012690 F80-OK.  MOVE '0' TO IK MOVE PROGR TO XPROGR GO TO F80-FN.       CVA010
012700 F80-KO.  MOVE '1' TO IK MOVE PROGR TO XPROGR                     CVA010
MM0410     IF  FLAG-RC10 = 1
MM0410       MOVE 0 TO FLAG-RC10
MM0410       EXEC SQL
MM0410           CLOSE RC10
MM0410       END-EXEC
MM0410         GO TO 00300-EX
MM0410     END-IF.
012710 F8099-FN.    EXIT.                                               CVA010
012720 F80-FN.      EXIT.                                               CVA010
012730 F81.          EXIT.                                              CVA010
012740 F81ER.                                                           P000
012750     MOVE        'Y' TO CB00-XROLBK                               P010
012760     MOVE        ZERO TO M-X000-XFCONV                            P015
012770     GO TO F8Z17.                                                 P020
012780 F81ER-FN.    EXIT.                                               P000
012790 F81ES.                                                           P000
012800     MOVE        'E' TO CAT-ER                                    P020
012810     MOVE        SQLCODE TO W-SQLCODE                             P040
012820        MOVE ZERO TO TALLI                                        P060
012830     INSPECT     SQLERRMC REPLACING ALL                           P060
012840                 HIGH-VALUES BY SPACES                            P080
012850     MOVE        SQLERRMC TO W-SQLERRMC                           P100
012860     MOVE        W-ERMSG TO CB00-XDIAGN                           P120
012870     MOVE        SQLCA TO XSAINF-SQLCA                            P125
012880     COPY XSPINI.                                                 P130
012890     EXEC SQL    INCLUDE XSPINF                        END-EXEC.  P140
012900     GO TO F81ER.                                                 P155
012910 F81ES-FN.    EXIT.                                               P000
012920 F81FI.        EXIT.                                              P000
012930 F81FI-FN.    EXIT.                                               P000
012940 F81FR.        EXIT.                                              P000
012950 F81FR-FN.    EXIT.                                               P000
012960 F81HC.        EXIT.                                              P000
012970 F81HC-FN.    EXIT.                                               P000
012980 F81PR.        EXIT.                                              P000
012990 F81PR-FN.    EXIT.                                               P000
013000 F81PU.        EXIT.                                              P000
013010 F81PU-FN.    EXIT.                                               P000
013020 F81RE.        EXIT.                                              P000
013030 F81RE-FN.    EXIT.                                               P000
013040 F81SE.        EXIT.                                              P000
013050 F81SE-FN.    EXIT.                                               P000
013060 F81SM.        EXIT.                                              P000
013070 F81SM-FN.    EXIT.                                               P000
013080 F81UT.     IF K50L < K50M ADD 1 TO K50L                          CVA010
013090        MOVE XEMKY TO T-XEMKY (K50L). MOVE 'E' TO CAT-ER.         CVA010
013100 F81UT-FN.    EXIT.                                               CVA010
013110 F81XC.        EXIT.                                              P000
013120 F81XC-FN.    EXIT.                                               P000
013130 F8105.        EXIT.                                              P000
013140 F8105-FN.    EXIT.                                               P000
013150 F8140.                                                           CVA010
013160        MOVE  EIBCPOSN  TO  CPOSN                                 CVA010
013170        DIVIDE  CPOSN  BY  080                                    CVA010
013180        GIVING  CPOSL  REMAINDER  CPOSC                           CVA010
013190        ADD  1  TO  CPOSL  CPOSC.                                 CVA010
013200 F8140-FN.    EXIT.                                               CVA010
013210 F8145.                                                           CVA010
013220        MOVE  T20002 TO   S20002.                                 CVA010
013230 F8145-FN.    EXIT.                                               CVA010
013240 F8155.                                                           CVA010
013250        MOVE ZERO TO K01.                                         CVA010
013260        DIVIDE  DATQUY  BY  4  GIVING LEAP-REM.                   CVA010
013270        COMPUTE LEAP-REM = DATQUY - 4 * LEAP-REM.                 CVA010
013280        IF LEAP-REM = ZERO GO TO F8155-B.                         CVA010
013290 F8155-A.                                                         CVA010
013300        ADD  1  TO  K01.                                          CVA010
013310        IF DATQUD > TABQT1 (K01) GO TO F8155-A.                   CVA010
013320        MOVE  K01  TO DAT629.                                     CVA010
013330        IF K01 = 1 MOVE DATQUD TO DAT619                          CVA010
013340        GO  TO  F8155-C.                                          CVA010
013350        SUBTRACT  1  FROM  K01.                                   CVA010
013360        SUBTRACT  TABQT1 (K01) FROM DATQUD GIVING DAT619.         CVA010
013370        GO  TO  F8155-C.                                          CVA010
013380 F8155-B.                                                         CVA010
013390        ADD  1  TO  K01.                                          CVA010
013400        IF DATQUD > TABBI1 (K01) GO TO F8155-B.                   CVA010
013410        MOVE  K01  TO DAT629.                                     CVA010
013420        IF K01 = 1 MOVE DATQUD TO DAT619                          CVA010
013430        GO  TO  F8155-C.                                          CVA010
013440        SUBTRACT  1  FROM  K01.                                   CVA010
013450        SUBTRACT  TABBI1 (K01) FROM DATQUD GIVING DAT619.         CVA010
013460 F8155-C.                                                         CVA010
013470        MOVE  DATQUY  TO  DATOA.                                  CVA010
013480        MOVE DAT62  TO DATOM  MOVE DAT619 TO DATOJ.               CVA010
013490 F8155-FN.    EXIT.                                               CVA010
013500 F8165.                                                           CVA010
013510        MOVE  S20002 TO   R20002.                                 CVA010
013520 F8165-FN.    EXIT.                                               CVA010
013530 F81-FN.      EXIT.                                               CVA010
013540 F8901.                                                           P000
013550           IF    CB00-XPFKEY NUMERIC                              P100
013560     MOVE        SPACE TO I-PFKEY.                                P100
013570           IF    CB00-XPFKEY = 'CL'                               P120
013580     MOVE        'CL' TO I-PFKEY.                                 P120
013590           IF    CB00-XPFKEY = 'ET'                               P140
013600     MOVE        SPACE TO I-PFKEY.                                P140
013610           IF    CB00-XPFKEY = 'P1'                               P150
013620     MOVE        'A1' TO I-PFKEY.                                 P150
013630           IF    CB00-XPFKEY = 'P2'                               P160
013640     MOVE        'A2' TO I-PFKEY.                                 P160
013650           IF    CB00-XPFKEY = 'F1'                               P170
013660     MOVE        '01' TO I-PFKEY.                                 P170
013670           IF    CB00-XPFKEY = 'F2'                               P180
013680     MOVE        '02' TO I-PFKEY.                                 P180
013690           IF    CB00-XPFKEY = 'F3'                               P190
013700     MOVE        '03' TO I-PFKEY.                                 P190
013710           IF    CB00-XPFKEY = 'F4'                               P200
013720     MOVE        '04' TO I-PFKEY.                                 P200
013730           IF    CB00-XPFKEY = 'F5'                               P210
013740     MOVE        '05' TO I-PFKEY.                                 P210
013750           IF    CB00-XPFKEY = 'F6'                               P220
013760     MOVE        '06' TO I-PFKEY.                                 P220
013770           IF    CB00-XPFKEY = 'F7'                               P230
013780     MOVE        '07' TO I-PFKEY.                                 P230
013790           IF    CB00-XPFKEY = 'F8'                               P240
013800     MOVE        '08' TO I-PFKEY.                                 P240
013810           IF    CB00-XPFKEY = 'F9'                               P250
013820     MOVE        '09' TO I-PFKEY.                                 P250
013830           IF    CB00-XPFKEY = 'F0'                               P260
013840     MOVE        '10' TO I-PFKEY.                                 P260
013850 F8901-FN.    EXIT.                                               P000
013860 F8910.        EXIT.                                              P000
013870 F8910-FN.    EXIT.                                               P000
MM0410
      *
       00300-ELABORA-RC10.
MM0410
MM0410*    DISPLAY 'RC10-CDBAN0*'   RC10-CDBAN0 '*'.
MM0410*    DISPLAY 'RC10-CDSSM0*'   RC10-CDSSM0 '*'.
MM0410*    DISPLAY 'RC10-CDRCB0*'   RC10-CDRCB0 '*'.
MM0410*
MM0410     MOVE   '00000'        TO  RC10-CDBAN0.
MM0410     MOVE   'CVAS'         TO  RC10-CDSSM0.
MM0410     MOVE   'CV045'        TO  RC10-CDRCB0.
MM0410     MOVE   34             TO  LRC10-DSPRC0.
MM0410*
MM0410     EXEC SQL
MM0410         OPEN RC10
MM0410     END-EXEC.
MM0410
MM0410     MOVE 1 TO FLAG-RC10.
MM0410*
MM0410     PERFORM  00350-FETCH-RC10
MM0410         UNTIL SQLCODE   =  100.
MM0410*
MM0410 00300-EX.
MM0410     EXIT.
MM0410
MM0410 00350-FETCH-RC10.
MM0410*
MM0410     EXEC SQL FETCH RC10
MM0410      INTO
MM0410      :VRC10-DSPRC0
MM0410     END-EXEC.
MM0410
MM0410
MM0410     IF SQLCODE = 0
MM0410        PERFORM 00360-CONTROLLA-RC10    THRU   00360-EX
MM0410     END-IF.
MM0410*
MM0410 00350-EX.
MM0410     EXIT.
MM0410*
MM0410 00360-CONTROLLA-RC10.
MM0410     MOVE RC10-DSPRC0 TO AREA-RC10.
MM0410     IF  DSPRC0-UTENZA1 = CB00-XIDUT   OR
MM0410         DSPRC0-UTENZA2 = CB00-XIDUT   OR
MM0410         DSPRC0-UTENZA3 = CB00-XIDUT
MM0410        MOVE  'MONOPER'      TO  CB00-XPROUT
MM0410        MOVE  DSPRC0-CDDIP0  TO   WW00-XDILIO
MM0410                                  CB00-XDILIO
MM0410                                  CB00-XDILIF
MM0410                                  CB00-XDILIU
MM0410        GO TO F21GG-FN
MM0410     END-IF.
MM0410 00360-EX.
MM0410     EXIT.
