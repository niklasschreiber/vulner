package Empty_Catch_Block;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class Empty_Catch_Block {
	
	static final Logger log = Logger.getLogger("logger");
	
	public void bad(HttpServletRequest request, HttpServletResponse response){
		
		 try {
				response.getWriter().write("You cannot shut down this application, only the admin can");
			} catch (IOException e) {  // bad  空的catch代码块
				
			}
	}
	
	public void good(HttpServletRequest request, HttpServletResponse response){
		
		try {
			response.getWriter().write("You cannot shut down this application, only the admin can");
		} catch (IOException e) {  // good  空的catch代码块
			log.info("bad");
		}
	}

}
