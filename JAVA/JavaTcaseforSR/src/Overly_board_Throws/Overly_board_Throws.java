package Overly_board_Throws;

import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;

public class Overly_board_Throws {

	static final Logger log = Logger.getLogger("logger");
	
	public void bad(HttpServletRequest request) throws Throwable {  // bad 犯化的抛出异常

		String val = "1";

		int value = Integer.parseInt(val);
		if (value != 0)
			log.info("parse ok");

	}

	public void good(HttpServletRequest request) throws NumberFormatException { // good 犯化的抛出异常

		String val = "1";

		int value = Integer.parseInt(val);
		if (value != 0) {
			log.info("parse ok");
		}
		

	}

}
