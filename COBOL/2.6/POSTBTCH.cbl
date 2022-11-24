      * Questo programma batch viene startato con una call da un   *    00001000
      * altro programma batch e gestisce con i socket la comuni-   *    00002000
      * cazione via TCP/IP con un server UNIX e con la USING       *    00002100
      * riceve ed invia i dati al programma chiamante.             *    00002200
                                                                        00002300
       identification division.                                         00002400
       program-id. postbtch.                                            00002500
       environment division.                                            00002600
       configuration section.                                           00002700
       input-output section.                                            00002800
       file-control.                                                    00002900
           select ezaconfg assign  to ezaconfg                          00003000
                                     organization is indexed            00004000
                                     access mode  is dynamic            00005000
                                     record key   is eza-chiave         00006000
                                     file status  is eza-stato.         00007000
       data division.                                                   00008000
       file section.                                                    00009000
                                                                        00010000
      * Definizione del file di sistema EZACONFG, il programma     *    00020000
      * legge dal file con chiave nome del CICS e ritorna il       *    00030000
      * nome dell'address space del TCP/IP.                        *    00040000
                                                                        00041000
       fd  ezaconfg.                                                    00042000
       01  fd-ezaconfg.                                                 00042100
           05 eza-chiave.                                               00042200
              10 eza-applid       pic   x(08).                          00042300
              10 eza-tipo         pic   x(01).                          00042400
              10 appo1            pic   x(03).                          00042500
              10 appo2            pic   x(04).                          00042600
           05 eza-dati.                                                 00042700
              10 eza-tcpip        pic   x(08).                          00042800
              10 filler           pic   x(126).                         00042900
                                                                        00043000
       working-storage section.                                         00044000
                                                                        00045000
      * Variabili di appoggio per i messaggi inviati e ricevuti.   *    00046000
                                                                        00047000
       01 direzione               pic  9(08)  comp value 2.             00048004
       01 eza-stato               pic  9(02).                           00048104
       01 flag-tra                pic  x(01)  value 'N'.                00049000
       01 appo-send.                                                    00050000
          10  msg occurs 1 to 32000 depending on lk-leng pic x.         00060000
       01 appo-send-len           pic  9(08)  comp value zeroes.        00061000
       01 appo-rec.                                                     00062000
          10  msg occurs 1 to 32000 depending on lk-leng pic x.         00063000
       01 appo-rec-len            pic  9(08)  comp value zeroes.        00064000
                                                                        00065000
      * Variabili di appoggio impiegate nelle CALL TCP.            *    00066000
                                                                        00067000
       01  soc-function           pic   x(16) value spaces.             00068000
       01  maxsoc                 pic   9(04) binary.                   00069000
       01  appo-applid            pic   x(08) value spaces.             00070000
       01  sokd                   pic   9(04) binary.                   00080000
       01  ws-flag                pic   9(08) comp value 0.             00090000
       01  cont1                  pic   9(01) value zeroes.             00100000
       01  cont2                  pic   9(05) value 1.                  00110000
                                                                        00120000
      * Struttura predefinita che viene impiegata dalla CALL di    *    00130000
      * tipo INITAPI.                                              *    00140000
                                                                        00150000
       01  iden.                                                        00160000
           05 tcpname             pic   x(08).                          00170000
           05 adsname             pic   x(08).                          00180000
                                                                        00190000
      * Struttura predefinita che viene impiegata dalla CALL di    *    00200000
      * tipo CONNECT.                                              *    00210000
                                                                        00220000
       01  nome.                                                        00230000
           05 famiglia            pic   9(04) comp value 2.             00240000
           05 porta               pic   9(04) binary.                   00250000
           05 indirizzo           pic   9(08) binary.                   00260000
           05 riservato           pic   x(08).                          00270000
                                                                        00280000
      * Variabili di appoggio impiegate nelle CALL TCP.            *    00290000
                                                                        00300000
       01  soctype                pic   9(08) comp value 1.             00310000
       01  subtask                pic   x(08).                          00320000
       01  proto                  pic   9(08) comp value 0.             00330000
       01  maxsno                 pic   9(08) binary.                   00340000
       01  errno                  pic   9(08) binary.                   00350000
       01  retcode                pic  s9(08) binary.                   00360000
       01  af                     pic   9(08) comp value 2.             00370000
                                                                        00380000
       01  ws-save-hostid         pic   9(08) comp.                     00390000
       01  redef-save-hostid      redefines ws-save-hostid.             00400000
           05  ws-indirizzo       pic   x(4).                           00410000
                                                                        00420000
      * Struttura predefinita usata dalla routine EZACIC08, la     *    00430000
      * routine viene chiamata dopo la GETHOSTBYNAME per ottenere  *    00440000
      * l'IP address da usare nella CONNECT.                       *    00450000
                                                                        00460000
       01  namel                  PIC 9(08) COMP value zeroes.          00470000
       01  name                   PIC x(24) value spaces.               00480000
       01  hostent-addr           pic 9(8)  binary.                     00490000
       01  hostname-length        pic 9(4)  binary.                     00500000
       01  hostname-value         pic x(255).                           00510000
       01  hostalias-count        pic 9(4)  binary.                     00520000
       01  hostalias-seq          pic 9(4)  binary.                     00530000
       01  hostalias-length       pic 9(4)  binary.                     00540000
       01  hostalias-value        pic x(255).                           00550000
       01  hostaddr-type          pic 9(4)  binary.                     00560000
       01  hostaddr-length        pic 9(4)  binary.                     00570000
       01  hostaddr-count         pic 9(4)  binary.                     00580000
       01  hostaddr-seq           pic 9(4)  binary.                     00590000
       01  hostaddr-value         pic 9(8)  binary.                     00600000
                                                                        00610000
       01  appo-porta                       pic s9(08) comp.            00620000
       01  red-appo-porta redefines appo-porta.                         00630000
           05  filler                       pic x(02).                  00640000
           05  half                         pic s9(04) comp.            00650000
                                                                        00660000
      * Variabili di appoggio per rendere dinamico il nome delle   *    00670000
      * code di trace che comincia con i primi tre caratteri del   *    00680000
      * dominio interessato.                                       *    00690000
                                                                        00700000
       linkage section.                                                 00710000
                                                                        00720000
      * lk-applid-vtam: nome di CICS connesso con l'address space  *    00730000
      *                 del TCP/IP interessato                     *    00731000
      * lk-nikname    : nome simbolico associato a un ip address   *    00732000
      *                 inserito nel TCP/IP                        *    00733000
      * lk-porta      : nome della porta del server                *    00734000
      * lk-leng       : lunghezza della commarea da gestire        *    00735000
      * lk-errno      : codici di ritorno                          *    00736000
      *    .          : (1) Lunghezza commarea a zero              *    00737000
      *    .          : (n) Ulteriori codici di errore sono        *    00738000
      *    .          :     quelli riportati come Error Codes      *    00739000
      *    .          :     del TCP/IP                             *    00739100
      * lk-flag-tra   : flag di attivazione di trace su code TS    *    00739200
      * lk-dati       : area dati variabile in funzione di         *    00739300
      *               : lk-leng                                    *    00739400
      * EZACIC04      : conversione da ebcdic ad ascii             *    00739500
      * EZACIC05      : conversione da ascii ad  ebcdic            *    00739600
      * EZACIC14      : conversione da ebcdic ad ascii nuova vers. *    00739610
      * EZACIC15      : conversione da ascii ad  ebcdic nuova vers.*    00739620
                                                                        00739700
       01  lk-applid-vtam  pic   x(08).                                 00739800
       01  lk-nikname      pic   x(08).                                 00739900
       01  lk-porta        pic   9(05).                                 00740000
       01  lk-leng         pic   9(08) comp.                            00740100
       01  lk-errno        pic   9(05).                                 00740200
       01  lk-flag-tra     pic   x(01).                                 00740300
       01  lk-dati.                                                     00740400
           05  msg occurs 1 to 32000 depending on lk-leng pic x.        00740500
                                                                        00740600
      * Il programma chiamante dovr{ eseguire la call using con le *    00740700
      * seguenti informazioni (in ordine rigoroso).                *    00740800
                                                                        00740900
       procedure division using lk-applid-vtam lk-nikname lk-porta      00741000
                                lk-leng lk-errno lk-flag-tra lk-dati.   00742000
      * Se il flag } Y scrivo tutta le informazioni passate.       *    00743000
                                                                        00744000
                                                                        00744100
      ***************************************************************** 00744110
      * MODIFICA PER ESCLUDERE LA CHIAMATA A POSTECOM PER DISMISSIONE * 00744120
      * SERVIZIO                                                      * 00744130
      ***************************************************************** 00744140
      *                                                                 00744150
           MOVE 99                         TO LK-ERRNO                  00744160
           GO TO FINE.                                                  00744161
      ***************************************************************** 00744170
      * FINE MODIFICA                                                 * 00744171
      ***************************************************************** 00744180
                                                                        00744200
           move 1                   to cont2.                           00745017
                                                                        00745117
           move lk-dati             to appo-send.                       00745217
           move lk-flag-tra         to flag-tra.                        00746000
                                                                        00747000
           if flag-tra equal 'Y'                                        00748000
              display 'INFORMAZIONI PASSATE   : '                       00749000
              display 'Applid VTAM            = ' lk-applid-vtam        00750000
              display 'Nikname TCP/IP         = ' lk-nikname            00760000
              display 'Porta TCP/IP           = ' lk-porta              00770000
              display 'Lunghezza dati passati = ' lk-leng               00780000
              display 'Codice errore          = ' lk-errno              00790000
              display 'Flag attivazione Trace = ' lk-flag-tra           00800000
              display 'Dati passati           = ' lk-dati               00810000
           end-if.                                                      00820000
                                                                        00830000
      * Azzeramento del return code (lk-errno) per il controllo    *    00831002
      * del chiamante                                              *    00832002
           move zeroes              to  lk-errno.                       00840002
      *                                                                 00840102
                                                                        00840202
           move length of appo-send to  appo-send-len.                  00841002
                                                                        00850000
      * Se non sono stati inviate informazioni, ritorna al         *    00860000
      * chiamante codice +1.                                       *    00870000
                                                                        00880000
           if lk-leng equal zeroes                                      00890000
              display 'ERRORE per assenza informazioni inviate.'        00900000
              move   1              to  lk-errno                        00910000
              perform fine                                              00920000
           end-if.                                                      00930000
                                                                        00940000
      * Legge il file di configurazione del TCP EZACONFG in FCT   *     00950000
      * contenente la configurazione Cics Socket ed estrae il     *     00960000
      * nome dell'Address Spaces del TCP/IP. Se c'} errore nella  *     00970000
      * lettura del file ritorna al chiamante codice +2.          *     00980000
                                                                        00990000
           move  lk-applid-vtam to eza-applid.                          01000000
           move  'C'            to eza-tipo.                            01010000
           move  low-value      to appo1.                               01020000
           move  '<<<<'         to appo2.                               01030000
           open  input  ezaconfg.                                       01040000
           if eza-stato not equal zeroes                                01050000
              display 'ERRORE nella OPEN :' eza-stato                   01060000
              move   2              to  lk-errno                        01070000
              perform fine                                              01080000
           end-if.                                                      01090000
                                                                        01100000
                                                                        01110000
           read  ezaconfg.                                              01120000
           if eza-stato not equal zeroes                                01130000
              display 'ERRORE nella READ :' eza-stato                   01140000
              move   2              to  lk-errno                        01150000
              perform fine                                              01160000
           end-if.                                                      01170000
                                                                        01180000
                                                                        01190000
           move  eza-tcpip      to tcpname.                             01200000
           close ezaconfg.                                              01210000
                                                                        01220000
           move  lk-applid-vtam to adsname.                             01230000
           move  lk-porta       to appo-porta.                          01240000
                                                                        01250000
      * CALL di tipo INITAPI per connettere il programma alla      *    01260000
      * interfaccia TCP/IP.                                        *    01270000
                                                                        01280000
elim  *    perform initapi.                                             01290006
elim  *    if errno  not equal zeroes                                   01300006
elim  *       display  'Errore nella call INITAPI: ' errno              01310006
elim  *       move errno       to   lk-errno                            01320006
elim  *       perform fine                                              01330006
elim  *    end-if.                                                      01340006
                                                                        01350000
      * CALL di tipo GETHOSTID per ottenere il nome del dominio    *    01360000
      * cio} l'IP address di 32 bit dell'HOST sul quale si trova   *    01370000
      * questo programma.                                          *    01380000
                                                                        01390000
elim  *    perform gethostid.                                           01400006
elim  *    if errno not equal zeroes                                    01410006
elim  *       display  'Errore nella call GETHOSTID :' errno            01420006
elim  *       move errno       to   lk-errno                            01430006
elim  *       perform fine                                              01440006
elim  *    end-if.                                                      01450006
                                                                        01460000
      * CALL di tipo SOCKET per creare e ritornare un socket       *    01470000
      * descriptor dal TCP/IP.                                     *    01480000
                                                                        01490000
           perform socket.                                              01500000
           if errno not equal zeroes                                    01510000
              display  'Errore nella call SOCKET :' errno               01520000
              move errno       to   lk-errno                            01530000
              perform fine                                              01540000
           end-if.                                                      01550000
           move retcode        to  sokd.                                01560000
                                                                        01570000
      * CALL di tipo CONNECT per stabilire una connessione tra     *    01580000
      * il socket locale ed il socket remoto sul server UNIX.      *    01590000
                                                                        01600000
           perform connect.                                             01610000
           if errno not equal zeroes                                    01620000
              display  'Errore nella call CONNECT :' errno              01630000
              move errno       to   lk-errno                            01640000
              perform fine                                              01650000
           end-if.                                                      01660000
                                                                        01670000
      * Prima di fare la WRITE del messaggio occorre eseguire      *    01680000
      * la conversione da EBCDIC ad ASCII con la routine EZACIC04. *    01690000
      * dal 05/03/2004 la convers. e' fatta dalla routine EZACIC14*     01690100
                                                                        01700000
      * Se il flag } Y scrive sulla SYSOUT del programma batch il  *    01710000
      * messaggio da inviare.                                      *    01720000
                                                                        01730000
           if flag-tra equal 'Y'                                        01740000
              display 'Dati inviati in formato EBCDIC   :' appo-send    01741000
           end-if.                                                      01742000
                                                                        01743000
m0503 *asterisco chiamata a EZACIC04 e inserisco chiamata a EZACIC14    01743100
                                                                        01743200
m0503 *    call 'EZACIC04' using appo-send                              01744000
m0503 *                          appo-send-len.                         01745000
                                                                        01745010
m0503      call 'EZACIC14' using appo-send                              01745100
m0503                            appo-send-len.                         01745200
                                                                        01746000
           if flag-tra equal 'Y'                                        01747000
              display 'Dati inviati in formato ASCII    : ' appo-send   01748000
           end-if.                                                      01749000
                                                                        01750000
      * CALL di tipo WRITE per scrivere il messaggio sul socket    *    01760000
      * connesso.In caso di errore CALL di tipo CLOSE.             *    01770000
                                                                        01780000
           perform write-socket.                                        01790000
           if errno not equal zeroes                                    01800000
              display  'Errore nella call WRITE :' errno                01810000
              move errno       to   lk-errno                            01820000
              perform close-socket                                      01821000
              perform fine                                              01822000
           end-if.                                                      01823000
                                                                        01824000
      * CALL di tipo RECV ricevere il messaggio sul socket         *    01825000
      * connesso.In caso di errore CALL di tipo CLOSE.             *    01826000
                                                                        01827000
       Ricevi.                                                          01828000
           perform recv-socket.                                         01829000
           if errno not equal zeroes                                    01830000
              display  'Errore nella call RECV : ' errno                01840000
              move errno       to   lk-errno                            01850000
              perform close-socket                                      01860000
              perform fine                                              01870000
           end-if.                                                      01880000
                                                                        01890000
      * Loop di ricezione che si ripete fino a quando il campo     *    01900000
      * retcode ritornato dalla CALL di tipo RECV (che contiene il *    01910000
      * numero di byte letti) } diverso da 0.                      *    01920000
                                                                        01930000
           evaluate true                                                01940000
                                                                        01950000
      * Tutti i record sono stati ricevuti quando retcode=0.       *    01960000
                                                                        01961000
              when retcode equal zeroes                                 01962000
                                                                        01963000
      * Prima di ritornare i dati ricevuti nel messaggio occorre   *    01964000
      * fare la conversione da ASCII ad EBCDC con la routine       *    01965000
      * EZACIC05 dal 05/03/04 la routine e' EZACIC15               *    01966000
                                                                        01967000
      * Se il flag } Y scrive sulla SYSOUT del programma batch il  *    01968000
      * messaggio da inviare.                                      *    01969000
                                                                        01970000
               if flag-tra equal 'Y'                                    01971000
                  display 'Dati ricevuti in formato ASCII   :' lk-dati  01972000
               end-if                                                   01973000
                                                                        01974000
m0503 *asterisco chiamata a EZACIC05 e inserisco chianmata a EZACIC15   01974100
                                                                        01974200
m0503 *        call 'EZACIC05' using lk-dati                            01975000
m0503 *                              lk-leng                            01976000
                                                                        01976010
m0503          call 'EZACIC15' using lk-dati                            01976100
m0503                                lk-leng                            01976200
                                                                        01977000
               if flag-tra equal 'Y'                                    01978000
                  display 'Dati ricevuti in formato EBCIDIC :' lk-dati  01979000
               end-if                                                   01980000
                                                                        01990000
      * Se il retcode > 0 il messaggio } stato ricevuto, ma il     *    01991000
      * socket } ancora aperto.                                    *    01992000
                                                                        01993000
              when retcode >     zeroes                                 01994000
                  move appo-rec(1:retcode) to lk-dati(cont2:retcode)    01995018
                  add retcode              to cont2                     01996018
                  go  ricevi                                            01997018
           end-evaluate.                                                01998000
                                                                        01999007
elim  *    perform shutd-socket.                                        02000007
elim  *    if errno not equal zeroes                                    02000107
elim  *       display  'Errore nella call SHUTDOWN: ' errno             02000207
elim  *       move errno       to   lk-errno                            02000307
elim  *       perform close-socket                                      02000407
elim  *       perform fine                                              02000507
elim  *    end-if.                                                      02000607
           perform close-socket.                                        02000704
           if errno not equal zeroes                                    02000805
              display  'Errore nella call CLOSE   : ' errno             02000905
              move errno       to   lk-errno                            02001005
              perform fine                                              02001205
           end-if.                                                      02001305
           perform fine.                                                02002003
                                                                        02010000
      * Seguono le routine COBOL che implementano le CALL TCP.     *    02020000
                                                                        02030000
       initapi.                                                         02040000
           move 'INITAPI'    to  soc-function.                          02050000
           move appo-applid  to  adsname.                               02060000
           move 51           to  maxsoc.                                02070000
                                                                        02080000
      * IL parametro maxsoc indica il numero massimo di SOCKET     *    02090000
      * che il programma puº aprire in una sola volta.             *    02100000
                                                                        02110000
           call 'EZASOKET' using soc-function                           02120000
                                 maxsoc                                 02130000
                                 iden                                   02140000
                                 subtask                                02150000
                                 maxsno                                 02160000
                                 errno                                  02170000
                                 retcode.                               02180000
                                                                        02190000
       gethostid.                                                       02200000
           move 'GETHOSTID'  to  soc-function.                          02210000
                                                                        02220000
      * Nel parametro retcode viene restituito l'indirizzo IP a    *    02230000
      * 32 bit dell'host locale dove gira il programma.            *    02240000
                                                                        02250000
           call 'EZASOKET' using soc-function                           02260000
                                 retcode.                               02270000
                                                                        02280000
       socket.                                                          02290000
           move retcode      to  ws-save-hostid.                        02300000
           move zeroes       to  retcode.                               02310000
           move 'SOCKET  '   to  soc-function.                          02320000
                                                                        02330000
      * Nel parametro retcode viene restituito il socket descriptor*    02331000
      * istanziato.                                                *    02332000
                                                                        02333000
           call 'EZASOKET' using soc-function                           02334000
                                 af                                     02335000
                                 soctype                                02336000
                                 proto                                  02337000
                                 errno                                  02338000
                                 retcode.                               02339000
       connect.                                                         02340000
                                                                        02350000
      * Viene letto il nome simbolico associato all'ip address del *    02360000
      * server, vengono rimossi tutti gli spazi e nel parametro    *    02370000
      * name viene restituito il nome effettivo.                   *    02380000
                                                                        02390000
           inspect  lk-nikname  tallying cont1 for all spaces.          02400000
           subtract cont1       from 8 giving cont1.                    02410000
           move     cont1       to  namel.                              02420000
                                                                        02430000
           move lk-nikname         to  name.                            02440000
                                                                        02450000
      * Viene ritornato l'IP address a partire dal nome simbolico  *    02460000
      * di un dominio.                                             *    02470000
                                                                        02480000
           perform gethost-byname.                                      02490000
                                                                        02500000
           move zeroes          to  retcode.                            02510000
           move 'CONNECT '      to  soc-function.                       02520000
           move half            to  porta.                              02530000
                                                                        02531000
      * Viene fornito nel parametro nome, il campo indirizzo che   *    02532000
      * contiene l'indirizzo IP del server remoto.                 *    02533000
                                                                        02534000
                                                                        02535000
           call 'EZASOKET' using soc-function                           02536000
                                 sokd                                   02537000
                                 nome                                   02538000
                                 errno                                  02539000
                                 retcode.                               02540000
                                                                        02550000
       write-socket.                                                    02560000
           move zeroes          to  retcode.                            02570000
           move 'WRITE    '     to  soc-function.                       02580000
           call 'EZASOKET' using soc-function                           02590000
                                 sokd                                   02600000
                                 lk-leng                                02610000
                                 appo-send                              02620000
                                 errno                                  02630000
                                 retcode.                               02640000
                                                                        02650000
       shutd-socket.                                                    02660004
           move 'SHUTDOWN '     to  soc-function.                       02670004
           call 'EZASOKET' using soc-function                           02680000
                                 sokd                                   02691004
                                 direzione                              02692004
                                 errno                                  02700000
                                 retcode.                               02710000
                                                                        02711004
       close-socket.                                                    02712004
           move 'CLOSE    '     to  soc-function.                       02713004
           call 'EZASOKET' using soc-function                           02714004
                                 sokd                                   02715004
                                 errno                                  02716004
                                 retcode.                               02717004
       recv-socket.                                                     02720000
           move zeroes          to  retcode.                            02730000
           move 'RECV     '     to  soc-function.                       02740000
           call 'EZASOKET' using soc-function                           02750000
                                 sokd                                   02760000
                                 ws-flag                                02770000
                                 lk-leng                                02780000
                                 appo-rec                               02790000
                                 errno                                  02800000
                                 retcode.                               02810000
       gethost-byname.                                                  02820000
           move 'GETHOSTBYNAME'  to  soc-function.                      02830000
                                                                        02840000
      * Nel parametro hostent-addr viene restituito una struttura  *    02850000
      * contenente l'indirizzo IP del server a partire dal nome    *    02860000
      * simbolico.                                                 *    02870000
                                                                        02880000
           call 'EZASOKET' using soc-function                           02890000
                                 namel                                  02900000
                                 name                                   02910000
                                 hostent-addr                           02920000
                                 retcode.                               02930000
                                                                        02940000
      * La routine EZACIC08 estrae dalla struttura hostent-address *    02941000
      * l'indirizzo IP del server e lo ritorna nel parametro       *    02942000
      * hostaddr-value.                                            *    02943000
                                                                        02944000
           call 'EZACIC08' using hostent-addr                           02945000
                                 hostname-length                        02946000
                                 hostname-value                         02947000
                                 hostalias-count                        02948000
                                 hostalias-seq                          02949000
                                 hostalias-length                       02950000
                                 hostalias-value                        02960000
                                 hostaddr-type                          02970000
                                 hostaddr-length                        02980000
                                 hostaddr-count                         02990000
                                 hostaddr-seq                           03000000
                                 hostaddr-value                         03010000
                                 retcode.                               03020000
                                                                        03030000
           move hostaddr-value  to  indirizzo.                          03040000
                                                                        03050000
       fine.                                                            03060000
           move lk-errno  to return-code.                               03070009
           goback.                                                      03080001
