       IDENTIFICATION DIVISION.                                         00010000
       PROGRAM-ID. CIOH0015.                                            00020000
      ***************************************************************** 00030000
      * DMOH0001 - SERVICE DEMO                                         00040000
      *            HOST PROGRAM                                         00050000
      * DEMO HOST PROGRAM WHICH WILL BE CALLED BY DRIVER PROGRAM        00060000
      *                                                                 00070000
      *  CD-RESP-CODE    CD-RESP-ADDITIONAL                             00080000
      *     '0000'       'APPLICATION ADDED SUCCESSFULLY'               00090000
      *     '1000'       'APPLICATION EXISTED'                          00100000
      *     '2000'       'APPLICATION FILE NOT OPEN'                    00110000
      *     '3000'       'INVALID REQUEST'                              00120000
      *     '4000'       'APPLICATION FILE NOT FOUND'                   00130000
      *     '9000'       'APPLICATION ADDED FAILED'                     00140000
      ***************************************************************** 00150000
      *                         VERSION HISTORY                         00160000
      *---------------------------------------------------------------- 00170000
      *DATE/TIME ?   AUTHOR   ? DESCRIPTION                             00180000
      *---------------------------------------------------------------- 00190000
      *2014-12-17    KRIS      INITIAL VERSION                          00200000
      ***************************************************************** 00210000
       ENVIRONMENT DIVISION.                                            00220000
       DATA DIVISION.                                                   00230000
       WORKING-STORAGE SECTION.                                         00240000
      *                                                                 00250000
       77 WS-BEGIN              PIC X(17) VALUE 'CIOH0015 WS BEGIN'.    00260000
       01 WS-VAR.                                                       00270000
          05 WS-RESP-CODE       PIC S9(8) COMP.                         00280000
          05 WS-APPLID          PIC 9(13).                              00290000
      *                                                                 00300000
      *APPLICATION FILE DMCUS                                           00310000
       COPY CICAD001.                                                   00320001
      *                                                                 00330000
      *SERVICE I/O                                                      00340000
       COPY CIC0015I.                                                   00350000
       COPY CIC0015O.                                                   00360000
      *                                                                 00370000
       77 WS-END                PIC X(15) VALUE 'CIOH0015 WS END'.      00380000
      *                                                                 00390000
       LINKAGE SECTION.                                                 00400000
       01 DFHCOMMAREA.                                                  00410000
      *SERVICE REQUEST/RESPONSE COMMAREA                                00420000
       COPY SD02WS.                                                     00430000
      *                                                                 00440000
       PROCEDURE DIVISION.                                              00450000
       0000-MAINLINE.                                                   00460000
      *                                                                 00470000
            PERFORM 1000-INIT                                           00480000
               THRU 1000-INIT-EXIT                                      00490000
      *                                                                 00500000
            PERFORM 2000-PRE-PROCESSING                                 00510000
               THRU 2000-PRE-PROCESSING-EXIT                            00520000
      *                                                                 00530000
            PERFORM 3000-MAIN-PROCESS                                   00540000
               THRU 3000-MAIN-PROCESS-EXIT                              00550000
      *                                                                 00560000
            PERFORM 4000-POST-PROCESSING                                00570000
               THRU 4000-POST-PROCESSING-EXIT                           00580000
      *                                                                 00590000
            PERFORM 5000-CLEAN-UP                                       00600000
               THRU 5000-CLEAN-UP-EXIT                                  00610000
            .                                                           00620000
      *                                                                 00630000
       0000-EXIT.                                                       00640000
            EXIT.                                                       00650000
      *                                                                 00660000
       1000-INIT.                                                       00670000
            INITIALIZE CIC0015I-REC                                     00680002
            MOVE CD-SRV-INPUT-DATA   TO CIC0015I-REC                    00690002
            .                                                           00700000
       1000-INIT-EXIT.                                                  00710000
            EXIT.                                                       00720000
      *                                                                 00730000
       2000-PRE-PROCESSING.                                             00740000
            INITIALIZE CICAD-REC                                        00750000
            MOVE CIC0015I-NUMB      TO CICAD-NUMB                       00760004
            .                                                           00770000
      *                                                                 00780000
       2000-PRE-PROCESSING-EXIT.                                        00790000
            EXIT.                                                       00800000
      *                                                                 00810000
       3000-MAIN-PROCESS.                                               00820000
            EXEC CICS READ                                              00830000
                 FILE('CICARD')                                         00840004
                 INTO(CICAD-REC)                                        00850000
                 RIDFLD(CICAD-NUMB)                                     00860004
                 RESP(WS-RESP-CODE)                                     00870000
            END-EXEC                                                    00880000
            EVALUATE (WS-RESP-CODE)                                     00890000
                WHEN DFHRESP(NORMAL)                                    00900000
                     MOVE '0000' TO CD-RESP-CODE                        00910000
                     MOVE 'CREDCARD READED SUCCESSFULLY'                00920000
                                 TO CD-RESP-ADDITIONAL                  00930000
                     INITIALIZE CIC0015O-REC                            00940002
                     MOVE CICAD-REC TO CIC0015O-REC                     00950002
                     INITIALIZE CD-SRV-OUTPUT-DATA                      00960000
                     MOVE  CIC0015O-REC TO CD-SRV-OUTPUT-DATA           00970002
                WHEN DFHRESP(NOTFND)                                    00980002
                     MOVE '1000' TO CD-RESP-CODE                        00990000
                     MOVE 'CREDCARD NOT FOUND'                          01000002
                                 TO CD-RESP-ADDITIONAL                  01010000
                WHEN DFHRESP(NOTOPEN)                                   01020000
                     MOVE '2000' TO CD-RESP-CODE                        01030000
                     MOVE 'CREDCARD FILE NOT OPEN'                      01040000
                                 TO CD-RESP-ADDITIONAL                  01050000
                WHEN DFHRESP(INVREQ)                                    01060000
                     MOVE '3000' TO CD-RESP-CODE                        01070000
                     MOVE 'INVALID REQUEST'                             01080000
                                 TO CD-RESP-ADDITIONAL                  01090000
                WHEN DFHRESP(FILENOTFOUND)                              01100000
                     MOVE '4000' TO CD-RESP-CODE                        01110000
                     MOVE 'CREDCARD FILE NOT FOUND'                     01120000
                                 TO CD-RESP-ADDITIONAL                  01130000
                WHEN OTHER                                              01140000
                     MOVE '9000' TO CD-RESP-CODE                        01150000
                     MOVE 'CREDCARD ADDED FAILED'                       01160000
                                 TO CD-RESP-ADDITIONAL                  01170000
            END-EVALUATE                                                01180000
            .                                                           01190000
       3000-MAIN-PROCESS-EXIT.                                          01200000
            EXIT.                                                       01210000
      *                                                                 01220000
       4000-POST-PROCESSING.                                            01230000
      *                                                                 01240000
       4000-POST-PROCESSING-EXIT.                                       01250000
            EXIT.                                                       01260000
      *                                                                 01270000
       5000-CLEAN-UP.                                                   01280000
            EXEC CICS RETURN END-EXEC.                                  01290000
      *                                                                 01300000
       5000-CLEAN-UP-EXIT.                                              01310000
            EXIT.                                                       01320000
      *                                                                 01330000
