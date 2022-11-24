package System_Information_Leak;

import java.io.IOException;
import java.util.logging.Logger;

public class System_Information_Leak
{

static final Logger log = Logger.getLogger("local-logger");
	
	public void bad() throws IOException{
		
		String val = "1";

		try{
			int value = Integer.parseInt(val);
			if (value != 0) {
				log.info("parse ok");
			}
		}catch(NumberFormatException e){  
			e.printStackTrace(); // bad 系统信息泄露
		}
		
	}

	public void good() {
		
		String val = "1";

		try{
			int value = Integer.parseInt(val);
			if (value != 0) {
				log.info("parse ok");
			}
		}catch(NumberFormatException e){
			log.info("NumberFormatException");
		}finally{  
			log.info("complete");  // good 系统信息泄露
		}
		
	}

}

