       IDENTIFICATION DIVISION.                      
       PROGRAM-ID. SETADDRESS. 
       AUTHOR. MERGE IC36 - IC37 >> IC31                            
       DATA DIVISION.       

       WORKING-STORAGE SECTION.     
       01  LOGAREA.
			05  VALHEADER        PIC X(50) VALUE 'VAL: '.
			05  VAL              PIC X(50).
       01  VAR-P     USAGE POINTER.                  
       01  VAR-W                            
      - PIC X(2).
       EXEC SQL DECLARE CSROWSTAT SENSITIVE STATIC SCROLL CURSOR
       WITH ROWSET POSITIONING WITH HOLD FOR
       SELECT ID1,'' 
       FROM TB;    
       LINKAGE SECTION.                              
       01  VAR-L                           PIC X(2). 
       PROCEDURE DIVISION USING VAR-L.               
       MAIN1.       
       EXEC CICS
       WEB READ
       FORMFIELD(NAME)
      *<VAL Untrusted
       VALUE(VAL)                  
       END-EXEC.
       EXEC DLI
       LOG
      *<VIOLAZ: LOGAREA untrusted da VAL
       FROM(LOGAREA)               
       LENGTH(50)
       END-EXEC.                      
      *<VIOLAZ	   
       SET VAR-P TO ADDRESS OF VAR-W.          
      *<ok
       SET VAR-P TO ADDRESS OF VAR-L.             
       EXEC CICS RECEIVE  
       MAP('CRSEMAP')                    
       MAPSET('CUSTSCR')                    
      *<ok	   
       SET (ADDRESS OF CRSEMAPI)        			
       RESP(WS-RESP-CD) 
       END-EXEC.
       MOVE X’FF’ to VAR-P.
       CALL W-NOMEPRG USING DFHEIBLK                              
       DFHCOMMAREA                           
       WVCPMAIL-AREA.      < SR confonde il fine istruzione con una label di una PERFORM
       MOVE 'BIBO - MOVIMENTI SU VOCI CONTABILI DA MERGE
      -         '     '             TO SD4-SD47-DESCRIZ.
       DISPLAY 'NREC. FILEOUT SCRITTI MERGE FLUSSI INPUT ..:'
       W-DISPLA.
       COMPUTE RANDOMRESULT = FUNCTION RANDOM (WS-CURRENT-MILLISECONDS).
       PERFORM VARYING I FROM 1 BY 1 UNTIL I > 40   
       MOVE INPUT-FLD(I) TO MAPFLDO (I)    
       IF DAYS-USED(I) < 30 
       MOVE DFHBMBRY to MAPFLDA(I) 
       ELSE
      *<VIOLAZ	   
       ADD 1 TO I                                               
       END-PERFORM.
      *<VIOLAZ
       EVALUATE ISS-STATE ALSO ISS-PLAN 			
      *<VIOLAZ	   
       WHEN '22' ALSO ANY				
       PERFORM 22-PROCESSING
      *<VIOLAZ	   
       WHEN '32' ALSO 'ABC'				
      *<VIOLAZ	   
       WHEN '32' ALSO 'DEF'				
       PERFORM 32-PROCESSING
       WHEN OTHER
       PERFORM OTHER-PROCESSING
       END-EVALUATE.


