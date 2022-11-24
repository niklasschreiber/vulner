package Overly_board_Catch;

import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;

public class Overly_board_Catch {

	static final Logger log = Logger.getLogger("logger");
	
	public void bad(HttpServletRequest request){

		String val = "1";
		
		try{
			int value = Integer.parseInt(val);
			if (value != 0) {
				log.info("parse ok");
			}
		}catch(Exception e){  // bad 犯化的捕获异常
			log.info("Exception");
		}

	}

	public void good(HttpServletRequest request) { 

		String val = "1";

		try{
			int value = Integer.parseInt(val);
			if (value != 0) {
				log.info("parse ok");
			}
		}catch(NumberFormatException e){  // good 犯化的捕获异常
			log.info("NumberFormatException");
		}

	}

}
