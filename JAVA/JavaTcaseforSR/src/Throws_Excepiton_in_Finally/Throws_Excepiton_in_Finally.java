package Throws_Excepiton_in_Finally;

import java.io.IOException;
import java.util.logging.Logger;

public class Throws_Excepiton_in_Finally {

	static final Logger log = Logger.getLogger("local-logger");
	
	public void bad() throws IOException{
		
		String val = "1";

		try{
			int value = Integer.parseInt(val);
			if (value != 0) {
				log.info("parse ok");
			}
		}catch(NumberFormatException e){  
			log.info("NumberFormatException");
		}finally{  // bad finally代码块中抛出异常
			throw new IOException();
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
		}finally{  // good finally代码块中抛出异常
			log.info("complete");
		}
		
	}

}
