 ID DIVISION.                                                   
 PROGRAM-ID. CICSRECEIVE.                                               
 DATA DIVISION.                                                 
 WORKING-STORAGE SECTION.                                       
 77 TID PIC X(4).                                               
 77 MSG PIC X(50) VALUE 'IMPORTANT OF LINK PROGRAM'.            
 77 A PIC X(35) VALUE 'THIS IS MAIN PROGRAM'.                   
 77 B PIC X(35) VALUE 'NOW CONTROL MOVE TO SUB'.                
 PROCEDURE DIVISION.                                            
     EXEC CICS RECEIVE INTO (TID) LENGTH(LENGTH OF TID) END-EXEC.
     EXEC CICS SEND FROM(TID) END-EXEC.   <*VIOLAZ                      
     EXEC CICS RECEIVE END-EXEC.                                
     EXEC CICS SEND FROM(A) ERASE END-EXEC.                     
     EXEC CICS RECEIVE END-EXEC.                                
     EXEC CICS SEND FROM(B) END-EXEC.                           
     EXEC CICS RECEIVE END-EXEC.                                
     EXEC CICS XCTL                                             
          PROGRAM('SUB')                                        
          END-EXEC.                                             
     EXEC CICS RETURN END-EXEC.     