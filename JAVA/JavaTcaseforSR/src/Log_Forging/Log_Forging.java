package Log_Forging;

import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;

public class Log_Forging {

	
	static final Logger log = Logger.getLogger("logger");
	
	public void bad(HttpServletRequest request) {
		
		String val = request.getParameter("val");
		try {
			
		  int value = Integer.parseInt(val);
		  if(value != 0){
			  log.info("parse ok");
		  }
		}
		catch (NumberFormatException e) {
		  log.info("Failed to parse val = " + val);  // bad  日志伪造
		}	
		
	}
	
	public void good(HttpServletRequest request) {
		
		String val = "1";
		
		try {
			
			int value = Integer.parseInt(val);
			if(value != 0){
				  log.info("parse ok");
			  }
		}
		catch (NumberFormatException e) {
			log.info("Failed to parse val = " + val);  // good  日志伪造
		}	
		
	}
	
	
	

}
