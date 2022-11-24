      *>Veryant isCOBOL Evolve
      *>CIVETTA

       identification division.
       program-id. iscobol.
	   method-id. getInstance as "getInstance".
	   
	   data division.
			01 WHO-CALLED-ME.
				05 THE-CALLING.PROGRAM PIC X(30) VALUE SPACES.
				05 THE-CALLING-LINE    PIC S9(6) BINARY.
				05 THE-LINE-NUM		   PIC S9(02) BINARY.
				05 h-grid, grid filterable-columns.

	   working-storage section.
		77 real-path pic x any length.
		
	   procedure division returning cls-instance.
		invoke self "new" giving cls-instance.
		DECLARATIVES.
		PRODUCT-ERR section.
			use after standard error procedure on product.
			PERFORM ERROR-FILE.
		END DECLARATIVES.
		
		MAIN.
	
		display indipendent graphical window
			title R'isCOBOl application Print Product List'
			lines 16
			size 84
			control font h-font
			background-low
			handle h-standardvisible 0
			system menu
			link to thread.
			
		CALL 'C$WRU' USING  THE-CALLING-PROGRAM
							THE-CALLING-LINE
							THE-LINE-NUM.
		call "wd2$session" using 	wd2-get-session-value
									"iscobol.wd2.servletcontext.realpath"
									real-path.
		
		call "IST00LTIP".
		cancel "IST00LTIP".
		
		STOP RUN.
